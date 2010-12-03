%'mouse_down': function activated when the mouse button is pressed on a figure (callback for 'WindowButtonDownFcn'
%-------------------------------------------------------------- 
% xy=mouse_down(hObject,eventdata) 
% activated by the command:
% set(hObject,'WindowButtonDownFcn',{'mouse_down'}), 
% where hObject is the handle of the figure
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This file is part of the toolbox UVMAT.
% 
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function xy=mouse_down(hObject,eventdata)

MouseAction='none'; %default
huvmat=findobj(allchild(0),'tag','uvmat');%find the uvmat interface handle which controls theoption of  mouse action
if isempty(huvmat)
    return
end
hhuvmat=guidata(huvmat);%handles of elements in uvmat
guihandles=guidata(hObject);
UvData=get(huvmat,'UserData');
MouseAction='none'; %default
currentfig=hObject;
hhcurrentfig=guidata(currentfig);
test_zoom=get(hhcurrentfig.zoom,'Value')
%test_zoom=get(guihandles.zoom,'Value');% get the mouse action from the uvmat GUI: options:
if isfield(UvData,'MouseAction')
    MouseAction=UvData.MouseAction;% get the mouse action from the uvmat GUI: options:
end

test_create=~test_zoom && (isequal(MouseAction,'create_object') || isequal(MouseAction,'create_mask'));
%test_cal=get(handles.cal,'Value');
test_cal=strcmp(MouseAction,'calib');
test_ruler=strcmp(MouseAction,'ruler');
test_edit=strcmp(MouseAction,'edit_object');
test_edit_vect=strcmp(MouseAction,'edit_vect');
xdisplay=[];%default
ydisplay=[];%default
AxeData=[];%default

%edit an existing point or line if found
hcurrentobject=gco;% current object handle (selected by the mouse)
hcurrentfig=hObject;% current figure handle
fig_tag=get(hcurrentfig,'Tag');
tag_obj=get(gco,'Tag');
xy=[];%default
xy_fig=get(hcurrentfig,'CurrentPoint');% current point of the current figure (gcbo)
hchild=get(hcurrentfig,'Children');%handles of all objects in the current figure
haxes=[];
% loop on all the objects in the current figure (selected by the last mouse click) 
for ichild=1:length(hchild)
    obj_pos=get(hchild(ichild),'Position');%position of the object
    if xy_fig(1) >=obj_pos(1) & xy_fig(2) >= obj_pos(2)& xy_fig(1) <=obj_pos(1)+obj_pos(3) & xy_fig(2) <= obj_pos(2)+obj_pos(4);
        htype=get(hchild(ichild),'Type');%type of object child of the current figure
        %if the mouse is over an axis, look at the data
        if isequal(htype,'axes')
            y_lim=get(hchild(ichild),'YLim');
            x_lim=get(hchild(ichild),'XLim');
            haxes=hchild(ichild);
            xy=get(haxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
            if xy(1,1)>x_lim(1) && xy(1,1)<x_lim(2) && xy(1,2)>y_lim(1) && xy(1,2)<y_lim(2)
                AxeData=get(haxes,'UserData');% data attached to the axis
                AxeData.CurrentOrigin=[xy(1,1) xy(1,2)];% The current point set by the mouse becomes the current origin
                if ~isequal(tag_obj,'proj_object') & ~test_create
                    x_mouse=xy(1,1);%default
                    y_mouse=xy(1,2);%default
                    u_mouse=[];
                    v_mouse=[];
                    w_mouse=[];
                    A_mouse=[];
                    c_text=[];
                    f_text=[];
                    ff_text=[];     
                    ivec=[];   
                    if isfield(AxeData,'X') & isfield(AxeData,'Y') & isfield(AxeData,'Mesh')% test on the existence of a vector field in the current axis
                        flag_vec=(AxeData.X<(xy(1,1)+AxeData.Mesh/4) & AxeData.X>(xy(1,1)-AxeData.Mesh/4)) & ...%flagx=1 for the vectors with x position selected by the mouse
                          (AxeData.Y<(xy(1,2)+AxeData.Mesh/4) & AxeData.Y>(xy(1,2)-AxeData.Mesh/4));%f
                        ivec=find(flag_vec,1);% search the (first) selected vector index ivec
                    end
                end
            else
                haxes=[];%mouse out of axes
            end
        end
    end
end
test2D=0;
if isfield(AxeData,'NbDim')
    if isequal(AxeData.NbDim,2)
        test2D=1;
    end
end
if ~test2D     %desable  object creation and vector editing if NbDim different from 2
    test_create=0;
    test_edit_vect=0;
end
%delete the current zoom rectangle
if isfield(AxeData,'CurrentRectZoom') & ishandle(AxeData.CurrentRectZoom)
    delete(AxeData.CurrentRectZoom)
    AxeData.CurrentRectZoom=[];
end    

% zoom has first priority 
if test_zoom %&& ~test_create && ~test_edit && ~test_edit_vect && exist('xy','var')
     AxeData.Drawing='zoom'; %initiate drawing mode
     AxeData.CurrentObject=[];%unselect objects
     set(haxes,'UserData',AxeData);
     return
end
if isempty(huvmat)
    return
end

%ruler has second priority 
if test_ruler
    UvData.RulerCoord(1,1)=xy(1,1);
    UvData.RulerCoord(1,2)=xy(1,2);
    UvData.RulerHandle=line([xy(1,1) xy(1,1)],[xy(1,2) xy(1,2)],'Color','m','Tag','ruler');
    set(huvmat,'UserData',UvData)
    AxeData.Drawing='ruler';
    set(haxes,'UserData',AxeData);
    return
end

%selection of an existing projection object
if  test_edit && (isequal(tag_obj,'proj_object')||isequal(tag_obj,'DeformPoint'))
    if ~(isfield(AxeData,'Drawing') && isequal(AxeData.Drawing,'create'))
        userdata=get(hcurrentobject,'UserData');
        if ishandle(userdata)%the selected line depends on a parent line
            AxeData.CurrentObject=userdata;% the parent object becomes the current one
        else
            AxeData.CurrentObject=hcurrentobject;% the selected object becomes the current one
        end
        ObjectData=get(AxeData.CurrentObject,'UserData');
        if test_edit && isfield(ObjectData,'IndexObj')
            hother=findobj('Tag','proj_object','Type','line');%find all the proj objects
            set(hother,'Color','b');%reset all the proj objects in 'blue' by default
            set(hother,'Selected','off')
            hother=findobj('Tag','proj_object','Type','rectangle');
            set(hother,'EdgeColor','b');
            set(hother,'Selected','off');
            hother=findobj('Tag','proj_object','Type','image');
            for iobj=1:length(hother)
                   Acolor=get(hother(iobj),'CData');
                   Acolor(:,:,1)=zeros(size(Acolor,1),size(Acolor,2));
                   set(hother(iobj),'CData',Acolor);
            end
            hother=findobj('Tag','DeformPoint');
            set(hother,'Color','b');
            set(hother,'Selected','off')    
            if isequal(get(AxeData.CurrentObject,'Type'),'line')
                set(AxeData.CurrentObject,'Color','m'); %set the selected object to magenta color
            elseif isequal(get(AxeData.CurrentObject,'Type'),'rectangle')
                 set(AxeData.CurrentObject,'EdgeColor','m'); %set the selected object to magenta color
            end
            if isfield(ObjectData,'SubObject')& ishandle(ObjectData.SubObject)
                for iobj=1:length(ObjectData.SubObject)
                    hsub=ObjectData.SubObject(iobj);
                    if isequal(get(hsub,'Type'),'rectangle')
                        set(hsub,'EdgeColor','m'); %set the selected object to magenta color
                    elseif isequal(get(hsub,'Type'),'image')
                       Acolor=get(hsub,'CData');
                       Acolor(:,:,1)=Acolor(:,:,3);
                       set(hsub,'CData',Acolor);
                    else
                        set(hsub,'Color','m')
                    end
                end
            end
            if isequal(tag_obj,'DeformPoint')
                 set(hcurrentobject,'Color','m'); %set the selected DeformPoint to magenta color
            end
            IndexObj=ObjectData.IndexObj;
                    %indicate on the list of the GUI uvmat which object has been selected
            if strcmp(get(hcurrentfig,'tag'),'uvmat') %if the uvmat graph has been selected, object projection is on the other frame view_field
                set(hhuvmat.list_object_2,'Value',IndexObj);
                list_str=get(hhuvmat.list_object_2,'String');
                UvData.Object{IndexObj}.Name=list_str{IndexObj};
            else
                set(hhuvmat.list_object_1,'Value',IndexObj);
                list_str=get(hhuvmat.list_object_1,'String');
                UvData.Object{IndexObj}.Name=list_str{IndexObj};
            end
            h_set_object=findobj(allchild(0),'Tag','set_object');
            if ~isempty(h_set_object)
                delete(h_set_object)
            end
            set_object(UvData.Object{IndexObj})
            axes(haxes);%set back the current axes haxes
            testdeform=0;
            set(gcbo,'Pointer','circle'); 
            AxeData.Drawing='deform';
            if isequal(tag_obj,'DeformPoint')       
               if isfield(ObjectData,'DeformPoint')
                   set(hcurrentobject,'Selected','on')
                   for ipt=1:length(ObjectData.DeformPoint)
                       if isequal(ObjectData.DeformPoint(ipt),hcurrentobject)
                            AxeData.CurrentIndex=ipt;
                            testdeform=1;
                       end
                   end
               end
            end
            if testdeform==0
                AxeData.Drawing='translate';
                set(AxeData.CurrentObject,'Selected','on')
                set(gcbo,'Pointer','fleur');
            end
        end
    end
end
%  create new projection  object
if  test_create && ~isempty(xy) && ~(isfield(AxeData,'Drawing')&& isequal(AxeData.Drawing,'create'))
        ObjectData=read_set_object(UvData.sethandles); 
        ObjectData.Coord=[]; %reset previous object coordinates
        ObjectData.Coord(1,1)=xy(1,1);
        ObjectData.Coord(1,2)=xy(1,2);
        ObjectData.Coord(1,3)=0;
        if isfield(AxeData,'ObjectCoord') & size(AxeData.ObjectCoord,2)==3
             ObjectData.Coord(1,3)=AxeData.ObjectCoord(1,3); %generaliser au cas avec angle
        end
        AxeData.CurrentObject=plot_object(ObjectData,[],haxes,'m');%draw the object and its handle becomes AxeData.CurrentObject
        if isfield(UvData,'Object')
            IndexObj=length(UvData.Object)+1;% add the object as index IndexObj on the list of the interface
        else
            IndexObj=2;
        end  
        UvData.Object{IndexObj}=ObjectData;
        UvData.Object{IndexObj}.HandlesDisplay(1)=AxeData.CurrentObject;
        set(huvmat,'UserData',UvData)
        list_str=get(hhuvmat.list_object_1,'String');
        object_name=get(UvData.sethandles.TITLE,'String')
        if isempty(object_name)|| strcmp(object_name,'')
            list_str{IndexObj}=[num2str(IndexObj) '-' ObjectData.Style]; 
            set(UvData.sethandles.TITLE,'String',list_str{IndexObj})
        else
           list_str{IndexObj}=object_name;
        end
        set(hhuvmat.list_object_1,'String',list_str)
        list_str{end+1}='...';
        set(hhuvmat.list_object_2,'String',list_str)
        if strcmp(fig_tag,'view_field')%we are in view_field plot
              set(hhuvmat.list_object_1,'Value',IndexObj)% the projection field will be plotted in uvmat frame
        else%we are in uvmat plot
            set(hhuvmat.list_object_2,'Value',IndexObj)
        end
        PlotData=get(AxeData.CurrentObject,'UserData');
        PlotData.IndexObj=IndexObj;
        set(AxeData.CurrentObject,'UserData',PlotData); %record the object index in the graph
        AxeData.Drawing='create';
end

% create calibration points if the GUI geometry_calib is opened, if the main axes axes3 of uvmat has ben selected
if ~test_zoom && test_cal && ~isempty(haxes) && strcmp(get(haxes,'tag'),'axes3') 
    h_geometry_calib=findobj(allchild(0),'Name','geometry_calib'); %find the geomterty_calib GUI
    hh_geometry_calib=guidata(h_geometry_calib);
    h_ListCoord=hh_geometry_calib.ListCoord; %findobj(h_geometry_calib,'Tag','ListCoord');
    h_edit_append=hh_geometry_calib.edit_append;%findobj(h_geometry_calib,'Tag','edit_append');
    if isequal(get(h_edit_append,'Value'),1) && ~isempty(haxes)
        coord_value=get(hhuvmat.transform_fct,'Value');% set uvmat to pixel coordinates, run it again if not
        if ~(isequal(coord_value,1)||isequal(coord_value,3)); %active only with no transform or px (no phys)
            set(hhuvmat.transform_fct,'Value',1)
            uvmat('transform_fct_Callback',hObject,eventdata,hhuvmat); %file input with xml reading  in uvmat
            set(hhuvmat.FixedLimits,'Value',0)% put FixedLimits option to 'off'
            set(hhuvmat.FixedLimits,'BackgroundColor',[0.7 0.7 0.7])
            return
        end
        Coord=get(h_ListCoord,'String');
        data=read_geometry_calib(Coord);%transform char cell to numbers
        xlim=get(haxes,'XLim');
        ind_range_x=abs((xlim(2)-xlim(1))/50);
        ylim=get(haxes,'YLim');
        ind_range_y=abs((ylim(2)-ylim(1))/50);
        ind_range=sqrt(ind_range_x*ind_range_y);
        test_newpoint=1;
        if size(data.Coord,2)>=5 %if calibration points already exist
            XCoord=(data.Coord(:,4));
            YCoord=(data.Coord(:,5));
            index_point=find((XCoord<xy(1,1)+ind_range) & (XCoord>xy(1,1)-ind_range) & ...%flagx=1 for the vectors with x position selected by the mouse
                          (YCoord<xy(1,2)+ind_range) & (YCoord>xy(1,2)-ind_range),1);%find the first calibration point in the neighborhood of the mouse
            test_newpoint=isempty(index_point);%test for no existing calibration point near the mouse position
        end
        val=get(h_ListCoord,'Value');
        %create a new calib point if we are not close to an existing one
        if test_newpoint                 
             strline=[ '    |    '  '    |    '  '    |    ' num2str(xy(1,1),4) '    |    ' num2str(xy(1,2),4)];
           
             if length(Coord)>=val
                 Coord(val+1:length(Coord)+1)=Coord(val:length(Coord));% push the list forward beyond the current point
             end
             Coord{val}=strline;
             set(h_ListCoord,'String',Coord)
            % set(h_ListCoord,'Value',val+1)
             data=read_geometry_calib(Coord);%transform char cell to numbers
             XCoord=data.Coord(:,4);
             YCoord=data.Coord(:,5);
        end
        hh=findobj('Tag','calib_points');%look for handle of calibration points           
        if isempty(hh)
            hh=line(XCoord,YCoord,'Color','m','Tag','calib_points','LineStyle','.','Marker','+');
        else
            set(hh,'XData',XCoord)
            set(hh,'YData',YCoord)
        end
        set(hh,'UserData',val)% flag the points to edit mode
        hhh=findobj('Tag','calib_marker');%look for handle of point marker (circle)
        if ~isempty(hhh)
            set(hhh,'Position',[xy(1,1)-ind_range/2 xy(1,2)-ind_range/2 ind_range ind_range])
        else
            rectangle('Curvature',[1 1],...
                  'Position',[xy(1,1)-ind_range/2 xy(1,2)-ind_range/2 ind_range ind_range],'EdgeColor','m',...
                  'LineStyle','-','Tag','calib_marker');
           % line([xy(1,1) xy(1,1)],[xy(1,2) xy(1,2)],'Color','m','Tag','calib_marker','LineStyle','.','Marker','o','MarkerSize',ind_range);
        end
        AxeData.Drawing='calibration';
    end
end

% edit vectors
if test_edit_vect & ~isempty(ivec) 
    if ~(isfield(AxeData,'FF')&& ~isempty(AxeData.FF))
        AxeData.FF=zeros(size(AxeData.X));
    end
    if isequal(AxeData.FF(ivec),0)
        AxeData.FF(ivec)=100; %mark vector #ivec as false
    else
        AxeData.FF(ivec)=0;
    end
    PlotParam=read_plot_param(hhuvmat);
    [PlotType,ScalOut]= plot_field(AxeData,haxes,PlotParam,1);
end   
set(haxes,'UserData',AxeData);

