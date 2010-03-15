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
testzoom=0;%default
MouseAction='none'; %default
huvmat=findobj(allchild(0),'Name','uvmat');%find the uvmat interface handle which controls theoption of  mouse action
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);%handles of elements in uvmat
    UvData=get(huvmat,'UserData');
    testzoom=get(hhuvmat.zoom,'Value');% get the mouse action from the uvmat GUI: options:
    if isfield(UvData,'MouseAction')
        MouseAction=UvData.MouseAction;% get the mouse action from the uvmat GUI: options:
    end
end
test_create=~testzoom && (isequal(MouseAction,'create_object') || isequal(MouseAction,'create_mask'));
%test_cal=get(handles.cal,'Value');
test_cal=isequal(MouseAction,'calib');
menu_coord=get(hhuvmat.transform_fct,'String');
coord_choice=get(hhuvmat.transform_fct,'Value');
coord_type=menu_coord{coord_choice};
test_edit=isequal(MouseAction,'edit_object');
test_edit_vect=isequal(MouseAction,'edit_vect');
xdisplay=[];%default
ydisplay=[];%default
haxes=[];
AxeData=[];%default

%edit an existing point or line if found
hcurrentobject=gco;% current object handle (selected by the mouse)
hcurrentfig=gcbo;% current figure handle
tag_obj=get(gco,'Tag');
xy=[];%default
xy_fig=get(hcurrentfig,'CurrentPoint');% current point of the current figure (gcbo)
hchild=get(hcurrentfig,'Children');%handles of all objects in the current figure
% loop on all the objects in the current figure (selected by the last mouse click) 
for ichild=1:length(hchild)
    obj_pos=get(hchild(ichild),'Position');%position of the object
    if xy_fig(1) >=obj_pos(1) & xy_fig(2) >= obj_pos(2)& xy_fig(1) <=obj_pos(1)+obj_pos(3) & xy_fig(2) <= obj_pos(2)+obj_pos(4);
        htype=get(hchild(ichild),'Type');%type of object child of the current figure
        %if the mouse is over an axis, look at the data
        if isequal(htype,'axes')
            haxes=hchild(ichild);
            xy=get(haxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
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
                    ivec=find(flag_vec);% search the selected vector index ivec
                    if length(ivec)>0
                        ivec=ivec(1);%choice the first selected vector if several are selected                        
                    end
                end
            end
        elseif isequal(get(hchild(ichild),'Visible'),'on')& ~isequal(get(hchild(ichild),'Style'),'frame')
           %FAIRE UNE OPTION D'AIDE AVEC BOUTON SOURIS DROIT (ALT)??
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

if testzoom %&& ~test_create && ~test_edit && ~test_edit_vect && exist('xy','var')
     AxeData.Drawing='zoom'; %initiate drawing mode
     AxeData.CurrentObject=[];%unselect objects
elseif ~isempty(huvmat)
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
            if test_edit & isfield(ObjectData,'IndexObj')
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
                hlist_object=findobj(huvmat,'Tag','list_object');
                set(hlist_object,'Value',IndexObj);
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
            list_str=get(hhuvmat.list_object,'String');
            list_str{IndexObj}=[num2str(IndexObj) '-' ObjectData.Style];
            if ~isequal(list_str{end},'...')
                 list_str{end+1}='...';
            end
            set(hhuvmat.list_object,'String',list_str)
            set(hhuvmat.list_object,'Value',IndexObj)
            PlotData=get(AxeData.CurrentObject,'UserData');
            PlotData.IndexObj=IndexObj;
            set(AxeData.CurrentObject,'UserData',PlotData); %record the object index in the graph
            AxeData.Drawing='create';
    end

    % create calibration points if the GUI geometry_calib is opened
    if test_cal & ~isempty(xy)
        h_geometry_calib=findobj(allchild(0),'Name','geometry_calib'); %find the geomterty_calib GUI
        hh_geometry_calib=guidata(h_geometry_calib);
        h_ListCoord=hh_geometry_calib.ListCoord; %findobj(h_geometry_calib,'Tag','ListCoord');
        h_edit_append=hh_geometry_calib.edit_append;%findobj(h_geometry_calib,'Tag','edit_append');
        if isequal(get(h_edit_append,'Value'),1) 
            if ~isequal(coord_type,'')
                set(handles_coord,'Value',1)
                coord_type='';
                set(hhuvmat.FixedLimits,'Value',0)% put FixedLimits option to 'off'
                set(hhuvmat.FixedLimits,'BackgroundColor',[0.7 0.7 0.7])
                uvmat('run0_Callback',hObject,eventdata,hhuvmat); %file input with xml reading  in uvmat
            end
%             if isequal(coord_type,'px')|isequal(coord_type,'');%px cordinates
                strline=[ '    |    '  '    |    '  '    |    ' num2str(xy(1,1),4) '    |    ' num2str(xy(1,2),4)];
%             else %phys cordinates
%                 strline=[ num2str(xy(1,1),4) '    |    '  num2str(xy(1,2),4) '    |    0      |    '  '    |    ' ];
%             end
            Coord=get(h_ListCoord,'String');
            val=get(h_ListCoord,'Value');
            if isequal(Coord,{''})
                val=0;
            end
            if length(Coord)>val
                Coord(val+2:length(Coord)+1)=Coord(val+1:length(Coord));% push the list forward beyond the current point
            end
            Coord{val+1}=strline;
            set(h_ListCoord,'String',Coord)
            set(h_ListCoord,'Value',val+1)
            geometry_calib('ListCoord_Callback',hObject,eventdata,hh_geometry_calib)
            data=read_geometry_calib(Coord);
            if isequal(coord_type,'px')|isequal(coord_type,'');%px cordinates
                XCoord=data.Coord(:,4);
                YCoord=data.Coord(:,5);
            else %phys cordinates
                XCoord=data.Coord(:,1);
                YCoord=data.Coord(:,2);
            end
            hh=findobj('Tag','calib_points');           
            if isempty(hh)
                line(XCoord,YCoord,'Color','m','Tag','calib_points','LineStyle','.','Marker','+');
            else
                set(hh,'XData',XCoord)
                set(hh,'YData',YCoord)
            end
            hhh=findobj('Tag','calib_marker');
            if ~isempty(hhh)
                set(hhh,'XData',xy(1,1))
                set(hhh,'YData',xy(1,2))
            else
                line(xy(1,1),xy(1,2),'Color','m','Tag','calib_marker','LineStyle','.','Marker','o','MarkerSize',20);
            end
            %uistack(h_geometry_calib,'top')
        end
    end

    % edit vectors
    if test_edit_vect & ~isempty(ivec) 
    %     FF_100=FF-100*double(uint(abs(FF)/100); %value of FF without units and dizaines
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
end
set(haxes,'UserData',AxeData);

%------------------------------------------------------
function update_plot(AxeData,haxes)
%--------------------------------------------


% %determine the axes of action of the set_edit interface
% % haxes= findobj(huvmat,'Tag','axes3'); %main plotting axes as default
% % AxeData=get(haxes,'UserData')
% %For vector field representation
% PlotHandles.auto_xy=findobj(huvmat,'Tag','auto_xy');
% PlotHandles.VecScale=findobj(huvmat,'Tag','VecScale');
% PlotHandles.AutoVec=findobj(huvmat,'Tag','AutoVec');
% PlotHandles.checkyellow=findobj(huvmat,'Tag','checkyellow');
% PlotHandles.checkblack=findobj(huvmat,'Tag','checkblack');
% PlotHandles.col_vec=findobj(huvmat,'Tag','col_vec');
% PlotHandles.colcode1=findobj(huvmat,'Tag','colcode1');
% PlotHandles.colcode2=findobj(huvmat,'Tag','colcode2');
% PlotHandles.vec_col_bar=findobj(huvmat,'Tag','vec_col_bar');
% PlotHandles.slider1=findobj(huvmat,'Tag','slider1');
% PlotHandles.slider2=findobj(huvmat,'Tag','slider2');
% PlotHandles.max_vec=findobj(huvmat,'Tag','max_vec');
% PlotHandles.min_vec=findobj(huvmat,'Tag','min_vec');
% PlotHandles.AutoVecColor=findobj(huvmat,'Tag','AutoVecColor');
% PlotHandles.decimate4=findobj(huvmat,'Tag','decimate4');
% 
% %vectors
% Vectors.VecScale=str2num(get(PlotHandles.VecScale,'String'));
% Vectors.AutoVec=get(PlotHandles.AutoVec,'Value');%automatic vector length
% Vectors.checkyellow=get(PlotHandles.checkyellow,'Value');
% Vectors.checkblack=get(PlotHandles.checkblack,'Value');
% Vectors.decimate4=get(PlotHandles.decimate4,'Value');% =1; for reducing the nbre of vectors
% menu_col=get(PlotHandles.col_vec,'String');
% menu_val=get(PlotHandles.col_vec,'Value');
% Vectors.CName=menu_col{menu_val}; %'ima_cor','black','white',...
% Vectors.colcode1=str2num(get(PlotHandles.colcode1,'String'));% first threshold for rgb, first value for'continuous' 
% Vectors.colcode2=str2num(get(PlotHandles.colcode2,'String'));% second threshold for rgb, last value (saturation) for 'continuous' 
% Vectors.option=get(PlotHandles.vec_col_bar,'Value'); % =1 (64 colors), =0 (3 colors)
% Vectors.min=get(PlotHandles.slider1,'Min');
% Vectors.max=get(PlotHandles.slider1,'Max');
% Vectors.auto=get(PlotHandles.AutoVecColor,'Value');% =1; thresholds scaling relative to min and max, =0 fixed thresholds
% PlotParam.Vectors=Vectors;

