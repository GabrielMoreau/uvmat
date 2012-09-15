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
AxeData=[];%default
FigData=get(hObject,'UserData');
if ishandle(FigData)% case of a zoom plot, the handle of the parent rectangle is stored in UserData, its parent is the plotting axes of the rectangle
    hcurrentfig=get(get(FigData,'parent'),'parent');
else
    hcurrentfig=hObject;%usual plot
end
set(hcurrentfig,'Units','pixels')
GUI_pos=get(hcurrentfig,'Position');%position of the GUI series (in pixels)
set(hcurrentfig,'Units','normalized')
hhcurrentfig=guidata(hcurrentfig);
if isfield(hhcurrentfig,'CheckZoom')
    test_zoom=get(hhcurrentfig.CheckZoom,'Value');%test for zoom action, first priority
else
    test_zoom=0;
end
test_piv=isfield(FigData,'CivHandle');

%% look for parameters set by the GUI uvmat
test_ruler=0;
test_edit=0;
test_create=0;
huvmat=findobj(allchild(0),'tag','uvmat');%find the uvmat interface handle which controls theoption of  mouse action
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);%handles of elements in uvmat
    UvData=get(huvmat,'UserData');
    test_ruler=isequal(get(hhuvmat.MenuRuler,'checked'),'on');%test for ruler  action, second priority;
    test_edit=get(hhuvmat.edit_object,'Value');%test for object editing, third priority
    test_edit_vect=get(hhuvmat.edit_vect,'Value');%test for vector editing,  priority 4
    %     test_create=isequal(get(hhuvmat.MenuObject,'checked'),'on');% test for object creation,  priority 5
    %     if test_create
    test_create=0;
    hset_object=findobj(allchild(0),'tag','set_object');

    if ~isempty(hset_object)
        hPLOT=findobj(hset_object,'tag','PLOT');
        test_create=strcmp(get(hPLOT,'enable'),'on') &&~test_edit;% create new object if set_object is in mode enable and uvmat not in mode 'edit_object'
    end
    
    test_cal=isequal(get(hhuvmat.MenuCalib,'checked'),'on');% test for calibration
    if test_cal% test for calibration popints,  priority 6
        h_calib=findobj(allchild(0),'tag','geometry_calib');
        if isempty(h_calib)
            test_cal=0;
            set(hhuvmat.MenuCalib,'checked','off');% test for calibration off
        else
            hh_calib=guidata(h_calib);
            test_cal=get(hh_calib.edit_append,'Value');
        end
    end
end

%% determine the currently selected items
hcurrentobject=gco;% current object handle (selected by the mouse)
%hcurrentfig=hObject;% current figure handle
fig_tag=get(hcurrentfig,'Tag');
tag_obj=get(gco,'Tag');%tag of the currently selected object
xy=[];%default
xy_fig=get(hObject,'CurrentPoint');% current point of the current figure (gcbo)
hchildren=get(hObject,'Children');%handles of all objects in the current figure
haxes=[];

%% loop on all the objects in the current figure (selected by the last mouse click) 
output_str='';
state_visible=get(hchildren,'Visible');
check_visible=strcmp('on',state_visible);%=1 if visible='on', =0 otherwise
hchildren=hchildren(find(check_visible)); %kkep only the visible children
for ichild=1:length(hchildren)
    hchild=hchildren(ichild); %handle of the current obj
    obj_pos=get(hchild,'Position');%position of the object
    if xy_fig(1) >=obj_pos(1) & xy_fig(2) >= obj_pos(2)& xy_fig(1) <=obj_pos(1)+obj_pos(3) & xy_fig(2) <= obj_pos(2)+obj_pos(4);
        htype=get(hchild,'Type');%type of object child of the current figure
        switch htype
            %if the mouse is over an axis, look at the data
            case 'axes'
                y_lim=get(hchild,'YLim');
                x_lim=get(hchild,'XLim');
                haxes=hchild;
                xy=get(hchild,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
%                 if xy(1,1)>x_lim(1) && xy(1,1)<x_lim(2) && xy(1,2)>y_lim(1) && xy(1,2)<y_lim(2)
                    AxeData=get(hchild,'UserData');% data attached to the axis
                    AxeData.CurrentOrigin=[xy(1,1) xy(1,2)];% The current point set by the mouse becomes the current origin
                    if test_edit_vect && ~isequal(tag_obj,'proj_object') & ~test_create
                        ivec=[];
                        FigData=get(hcurrentfig,'UserData');
                        tagaxes=get(hchild,'tag');
                        if isfield(FigData,tagaxes)
                            Field=FigData.(tagaxes);
                            [CellVarIndex,NbDim,VarType]=find_field_cells(Field);%analyse the physical fields contained in Field
                            for icell=1:numel(CellVarIndex)%look for all physical fields
                                if NbDim(icell)==2 % select 2D field
                                    if  isfield(Field,'Mesh') && ~isempty(Field.Mesh)&& ~isempty(VarType{icell}.coord_x) && ~isempty(VarType{icell}.coord_y)%case of unstructured data
                                        eval(['X=Field.' Field.ListVarName{VarType{icell}.coord_x} ';'])
                                        eval(['Y=Field.' Field.ListVarName{VarType{icell}.coord_y} ';'])
                                        flag_vec=(X<(xy(1,1)+Field.Mesh/4) & X>(xy(1,1)-Field.Mesh/4)) & ...%flagx=1 for the vectors with x position selected by the mouse
                                            (Y<(xy(1,2)+Field.Mesh/4) & Y>(xy(1,2)-Field.Mesh/4));%f
                                        ivec=find(flag_vec,1);% search the (first) selected vector index ivec
                                    end
                                end
                            end
                        end
                    end
%                 else
%                     hchild=[];%mouse out of axes
%                 end
                break
                
            %if the mouse is over a uicontrol, duplicate the display  in an editable  zoom window
            case 'uicontrol' 
                if isequal(get(hObject,'SelectionType'),'alt')  && isequal(get(hchild,'Visible'),'on') && ~isequal(get(hchild,'tag'),'frame_object')&&...
                        ~isequal(get(hchild,'tag'),'ListObject') 
                    if ~strcmp(get(hchild,'Style'),'frame')%do not visualisaze frames
                        msg_pos(1:2)=GUI_pos(1:2)+obj_pos(1:2).*GUI_pos(3:4);
                        display_str=get(hchild,'TooltipString');
                        output_str=msgbox_uvmat(['uicontrol: ' get(hchild,'Tag')],display_str,get(hchild,'String'),msg_pos);
                        break
                    end
                end
            case 'uipanel'
                panel_pos=obj_pos;%position of the panel
                hhchildren=get(hchild,'Children');%handles of all objects in the current GUI
                %% loop on all the objects in the current figure (selected by the last mouse click)
                for iichild=1:length(hhchildren)
                    hchild=hhchildren(iichild);
                    rel_pos=get(hchild,'Position');%position of the object relative to the uipanel
                    obj_pos(1:2)=panel_pos(1:2)+rel_pos(1:2).*panel_pos(3:4);
                    obj_pos(3:4)=panel_pos(3:4).*rel_pos(3:4);
                    if numel(obj_pos)>=4 && xy_fig(1) >=obj_pos(1) && xy_fig(2) >= obj_pos(2)&& xy_fig(1) <=obj_pos(1)+obj_pos(3) && xy_fig(2) <= obj_pos(2)+obj_pos(4);
                        htype=get(hchild,'Type');%type of object child of the current figure
                        %if the mouse is over a uicontrol, look at the data
                        if strcmp(htype,'uicontrol') && strcmp(get(hchild,'Visible'),'on')
                            msg_pos(1:2)=GUI_pos(1:2)+obj_pos(1:2).*GUI_pos(3:4);
                            display_str=get(hchild,'TooltipString');
                            output_str=msgbox_uvmat(['uicontrol: ' get(hchild,'Tag')],display_str,get(hchild,'String'),msg_pos);
                            break
                        end
                    end
                end
        end
        if ~isempty(output_str)
            break   %leave the current loop if a uicontrol has been selected
        end
    end
end
if ~isempty(output_str)               
    set(hObject,'Units','pixels')
    if strcmp(get(hchild,'enable'),'on')
    set(hchild,'String',output_str)% fill the parent uicontrol with the sttring edited in the msgbox
    end
end
    
%% desable  object creation and vector editing if NbDim different from 2
if ~(isfield(AxeData,'NbDim') && isequal(AxeData.NbDim,2))
    test_create=0;
    test_edit_vect=0;    
end

%% delete the current zoom rectangle
if isfield(AxeData,'CurrentRectZoom') && ~isempty(AxeData.CurrentRectZoom) && ishandle(AxeData.CurrentRectZoom)
    delete(AxeData.CurrentRectZoom)
    AxeData.CurrentRectZoom=[];
end    

%% zoom has first priority 
if test_zoom %&& ~test_create && ~test_edit && ~test_edit_vect && exist('xy','var')
     AxeData.Drawing='zoom'; %initiate drawing mode
     AxeData.CurrentObject=[];%unselect objects
     set(hchild,'UserData',AxeData);
     return
end
if isempty(huvmat)%further options require the uvmat GUI
    return 
end

%% ruler has second priority 
if test_ruler
    AxeData.RulerCoord(1,1)=xy(1,1);
    AxeData.RulerCoord(1,2)=xy(1,2);
    AxeData.RulerHandle=line([xy(1,1) xy(1,1)],[xy(1,2) xy(1,2)],'Color','m','Tag','ruler');
    AxeData.Drawing='ruler';
    set(hchild,'UserData',AxeData);
    return
end

%% PIV test
if test_piv
    figure
    newaxes=axes;
    copyobj(AxeData.CurrentCorrImage,newaxes);
    set(newaxes,'CLim',[0 1])
    copyobj(AxeData.CurrentVector,newaxes)
    copyobj(AxeData.TitleHandle,newaxes)
    colorbar
end

%% selection of an existing projection object (third priority)
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
%                 IndexObj=get(hhuvmat.ListObject,'Value');
%                 if IndexObj>IndexObj_old(1)
%                     IndexObj=[IndexObj_old(1) IndexObj];
%                 else
%                     IndexObj=[1 IndexObj];
%                 end
                set(hhuvmat.ListObject,'Value',IndexObj);
%                 set(hhuvmat.ListObject,'UserData',IndexObj);
            else
                set(hhuvmat.ListObject_1,'Value',IndexObj);
                list_str=get(hhuvmat.ListObject_1,'String');
                UvData.Object{IndexObj}.Name=list_str{IndexObj};
            end
%             h_set_object=findobj(allchild(0),'Tag','set_object');
%             if ~isempty(h_set_object)
%                 delete(h_set_object)
%             end
            set_object(UvData.Object{IndexObj})
            axes(hchild);%set back the current axes haxes
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

%%  create  projection  object
if  test_create && ~isempty(xy) %&& ~(isfield(AxeData,'Drawing')&& isequal(AxeData.Drawing,'create'))
    hset_object=findobj(allchild(0),'tag','set_object');
    % activate this option if the GUI set_object is opened
    if ~isempty(hset_object)
        sethandles=guidata(hset_object);% handles of the elements in the GUI set_object
        ObjectData=read_GUI(hset_object); %read object parameters in the GUI set_object
        IndexObj=length(UvData.Object);
        %initiate a new object (no data .Coord yet recorded)
        if ~isfield(UvData.Object{IndexObj},'Coord');
            ObjectData.Coord=[];
            ObjectNameNew=ObjectData.Name;
            if isempty(ObjectNameNew)
                ObjectNameNew=ObjectData.Type;
            end
            % add an index to the object name if the proposed name already exists          
            vers=0;% index of the name
            ListObject=get(hhuvmat.ListObject,'String');
            detectname=1;
            while ~isempty(detectname)
                detectname=find(strcmp(ObjectNameNew,ListObject),1);%test the existence of the proposed name in the list
                if detectname% if the object name already exists
                    indstr=regexp(ObjectNameNew,'\D');
                    if indstr(end)<length(ObjectNameNew) %object name ends by a number
                        vers=str2double(ObjectNameNew(indstr(end)+1:end))+1;
                        ObjectNameNew=[ObjectNameNew(1:indstr(end)) num2str(vers)];
                    else
                        vers=vers+1;
                        ObjectNameNew=[ObjectNameNew(1:indstr(end)) '_' num2str(vers)];
                    end
                end
            end
            ObjectName=ObjectNameNew;
            set(sethandles.Name,'String',ObjectName)% display the default name in set_object
            if isempty(ListObject)
                ListObject={ObjectName};
            else
            ListObject{end}=ObjectName;
            end
            set(hhuvmat.ListObject,'String',ListObject);%complement the object list
            set(hhuvmat.ListObject_1,'String',ListObject);%complement the object list
            set(hhuvmat.ListObject,'Value',IndexObj)
            set(hhuvmat.ViewObject,'Value',1)
        end
        ObjectData.Coord=[ObjectData.Coord ;xy(1,1:2)];% append the coordinates marked by the mouse to the object
        hobject=UvData.Object{IndexObj}.DisplayHandle.(fig_tag);
        if isempty(hobject)
            hobject=haxes;
        end
        ProjObject=UvData.Object{get(hhuvmat.ListObject_1,'Value')};
        AxeData.CurrentObject=plot_object(ObjectData,ProjObject,hobject,'m');%draw the object and its handle becomes AxeData.CurrentObject
        UvData.Object{IndexObj}=ObjectData;      
        UvData.Object{IndexObj}.DisplayHandle.(fig_tag)=AxeData.CurrentObject;% attribute the current plot object handle to the Object      
        %UvData.Object{IndexObj}.DisplayHandle_view_field=AxeData.CurrentObject;
        set(huvmat,'UserData',UvData)
        PlotData=get(AxeData.CurrentObject,'UserData');
        PlotData.IndexObj=IndexObj;
        set(AxeData.CurrentObject,'UserData',PlotData); %record the object index in the graph (memory used for mouse motion)
        AxeData.Drawing='create';% flag for mouse motion
        %show object coordinates in the GUI set_object
        h_set_object=findobj(allchild(0),'Tag','set_object');
        hh_set_object=guidata(h_set_object);
        set(hh_set_object.Coord,'Data',ObjectData.Coord);
    end
end

%% create calibration points if the GUI geometry_calib is opened, if the main axes PlotAxes of uvmat has ben selected
if ~test_zoom && test_cal && ~isempty(haxes) && strcmp(get(haxes,'tag'),'PlotAxes') 
    h_geometry_calib=findobj(allchild(0),'Name','geometry_calib'); %find the geomterty_calib GUI
    hh_geometry_calib=guidata(h_geometry_calib);
    h_edit_append=hh_geometry_calib.edit_append;%findobj(h_geometry_calib,'Tag','edit_append');
    if isequal(get(h_edit_append,'Value'),1) && ~isempty(haxes)
        h_ListCoord=hh_geometry_calib.ListCoord; %findobj(h_geometry_calib,'Tag','ListCoord');
        coord_value=get(hhuvmat.transform_fct,'Value');% set uvmat to pixel coordinates, run it again if not
        if ~(isequal(coord_value,1)||isequal(coord_value,3)); %active only with no transform or px (no phys)
            set(hhuvmat.transform_fct,'Value',1)
            uvmat('transform_fct_Callback',hObject,eventdata,hhuvmat); %file input with xml reading  in uvmat
            set(hhuvmat.CheckFixedLimits,'Value',0)% put FixedLimits option to 'off'
            set(hhuvmat.CheckFixedLimits,'BackgroundColor',[0.7 0.7 0.7])
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

%% edit vectors
if test_edit_vect && ~isempty(ivec) 
    %create the error flag FF if it does not exist
    if ~isfield(Field,'FF')
        Field.ListVarName=[Field.ListVarName 'FF'];
        Field.VarDimName=[Field.VarDimName Field.VarDimName{VarType{icell}.coord_x}];
        nbvar=length(Field.ListVarName);
        Field.VarAttribute{nbvar}.Role='errorflag';
        Field.FF=zeros(size(Field.X));
    end
    if isequal(Field.FF(ivec),0)
        Field.FF(ivec)=100; %mark vector #ivec as false
    else
        Field.FF(ivec)=0;
    end
    PlotParam=read_GUI(hcurrentfig);
    plot_field(Field,haxes,PlotParam);
    eval(['FigData.' tagaxes '=Field;'])%record the modified field in FigData
    set(hcurrentfig,'UserData',FigData);
end  
set(haxes,'UserData',AxeData);

