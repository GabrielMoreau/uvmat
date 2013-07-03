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

%% look for parameters set by the current figure (handle=input parameter hObject)
AxeData=[];%default data stored on the current axes
FigData=get(hObject,'UserData'); %default data stored on the current object
if ishandle(FigData)% case of a zoom plot, the handle of the parent rectangle is stored in UserData, its parent is the plotting axes of the rectangle
    hCurrentGUI=get(get(FigData,'parent'),'parent');%handle of the current GUI: zoom plot
else
    hCurrentGUI=hObject; % handle of the current GUI: usual plot
end
hhCurrentGUI=guidata(hCurrentGUI);% tags of the children of the current GUI
CheckZoom=0;
if isfield(hhCurrentGUI,'CheckZoom') && get(hhCurrentGUI.CheckZoom,'Value');%test for zoom action, first priority
    CheckZoom=1;
end
test_piv=isfield(FigData,'CivHandle');
set(hCurrentGUI,'Units','pixels')
GUI_pos=get(hCurrentGUI,'Position');%position of the GUI series on the screen (in pixels), used to position message boxes
set(hCurrentGUI,'Units','normalized')% back to current unit for fig position

%% determine the currently selected items
hcurrentobject=gco;% current object handle (selected by the mouse)
CurrentGUI_tag=get(hCurrentGUI,'Tag');
obj_tag=get(gco,'Tag');%tag of the currently selected object
xy=[];%default
xy_fig=get(hObject,'CurrentPoint');% current point of the current figure (gcbo)
haxes=[];

%% look for parameters set by the GUI uvmat
test_ruler=0;
test_edit=0;
test_create=0;
huvmat=findobj(allchild(0),'tag','uvmat');%find the uvmat interface handle which controls the option of  mouse action
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);%handles of elements in uvmat
    UvData=get(huvmat,'UserData');
    test_ruler=isequal(get(hhuvmat.MenuRuler,'checked'),'on');%test for ruler  action, second priority;
    test_edit=get(hhuvmat.CheckEditObject,'Value')&& (isequal(obj_tag,'proj_object')||isequal(obj_tag,'DeformPoint'));%test for object editing, third priority
    hset_object=findobj(allchild(0),'tag','set_object');
    if ~isempty(hset_object)
        hPLOT=findobj(hset_object,'tag','PLOT');
        test_create=strcmp(get(hPLOT,'enable'),'on') &&~get(hhuvmat.CheckEditObject,'Value');% create new object if set_object is in mode enable and uvmat not in mode 'EditObject'
    end
    test_edit_vect=get(hhuvmat.edit_vect,'Value') && ~test_create && ~(isequal(obj_tag,'proj_object')||isequal(obj_tag,'DeformPoint')) ;%test for vector editing,  priority 4
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

%% loop on all the objects in the current figure (selected by the last mouse click)
hchildren=get(hObject,'Children');%handles of all objects in the current figure
check_visible=strcmp(get(hchildren,'Visible'),'on')& ~strcmp(get(hchildren,'Type'),'uimenu');% if visible='on', =0 otherwise
hchildren=hchildren(check_visible); %keep only the visible children
set(hchildren,'Units','normalized');
PosChildren=get(hchildren,'Position');% set of object positions
if iscell(PosChildren)% only one child
    PosLength=cellfun('length',PosChildren);% set of vector lengths for object positions
    hchildren=hchildren(PosLength==4);% keep only objects with position defined by a 4 element vector
    PosChildren=cell2mat(PosChildren(PosLength==4));% convert cells to matrix of positions
end
if size(PosChildren,2)~=4
    return
end
xy_fig_mat=ones(size(PosChildren,1),1)*xy_fig;% mouse position set to a matrix
check_pos=xy_fig_mat >= PosChildren(:,1:2) & xy_fig_mat <= PosChildren(:,1:2)+PosChildren(:,3:4);% compare object to mouse position
ind_object=find(check_pos(:,1) & check_pos(:,2),1);% select the index of the (first) object under the mouse
hchild=hchildren(ind_object);% corresponding object handle
if ~isempty(hchild)
    htype=get(hchild,'Type');%type of object child of the current figure
    switch htype
        %if the mouse is over an axis, look at the data
        case 'axes'
            haxes=hchild;
            xy=get(hchild,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
            AxeData=get(hchild,'UserData');% data attached to the axis
%             if isfield(AxeData,'ObjectCoord') && size(AxeData.ProjObjectCoord,2)==3
%                 xy(1,3)=AxeData.ProjObjectCoord(1,3); % z coordinate of the mouse: to generalise ...
%             else
%                 xy(1,3)=0; % z coordinate set to 0 by default
%             end
            AxeData.CurrentOrigin=xy(1,1:2);% The current point set by the mouse becomes the current origin
            
            if test_edit_vect 
                ivec=[];
                FigData=get(hCurrentGUI,'UserData');
                tagaxes=get(hchild,'tag');
                if isfield(FigData,tagaxes)
                    Field=FigData.(tagaxes);
                    [CellInfo,NbDim,errormsg]=find_field_cells(Field);%analyse the physical fields contained in Field
                    if isempty(errormsg)
                    for icell=1:numel(CellInfo)%look for all physical fields
                        if NbDim(icell)==2 % select 2D field
                            if  isfield(Field,'CoordMesh') && ~isempty(Field.CoordMesh)&&...
                                    ~isempty(CellInfo{icell}.VarIndex_coord_x) && ~isempty(CellInfo{icell}.VarIndex_coord_y)%case of unstructured data
                                X=Field.(Field.ListVarName{CellInfo{icell}.VarIndex_coord_x});
                                Y=Field.(Field.ListVarName{CellInfo{icell}.VarIndex_coord_y});
                                flag_vec=(X<(xy(1,1)+Field.CoordMesh/4) & X>(xy(1,1)-Field.CoordMesh/4)) & ...%flagx=1 for the vectors with x position selected by the mouse
                                    (Y<(xy(1,2)+Field.CoordMesh/4) & Y>(xy(1,2)-Field.CoordMesh/4));%f
                                ivec=find(flag_vec,1);% search the (first) selected vector index ivec
                            end
                        end
                    end
                    end
                end
            end
            %break% leave the loop once an axes has been selected
            
            %if the mouse is over a uicontrol, with right mouse button activated, duplicate the display in an editable  zoom window
        case 'uicontrol'
            if isequal(get(hObject,'SelectionType'),'alt') %% && ~isequal(get(hchild,'tag'),'frame_object')
                obj_pos=PosChildren(ind_object,:);
                msg_pos(1:2)=GUI_pos(1:2)+obj_pos(1:2).*GUI_pos(3:4);
                display_str=get(hchild,'TooltipString');
                msgbox_uvmat(['uicontrol: ' get(hchild,'Tag')],display_str,get(hchild,'String'),msg_pos);
                return %leave the function once a uicontrol has been selected
            end
            
            %if the mouse is over a uipanel, look at the children of the uipanel
        case 'uipanel'
            if isequal(get(hObject,'SelectionType'),'alt')
                panel_pos=PosChildren(ind_object,:);%position of the panel
                hhchildren=get(hchild,'Children');%handles of all objects in the selected panel
                check_visible=strcmp(get(hhchildren,'Visible'),'on');%=1 if visible='on', =0 otherwise
                hhchildren=hhchildren(check_visible); %keep only the visible children
                
                PosChildren=get(hhchildren,'Position');
                PosLength=cellfun('length',PosChildren);
                hhchildren=hhchildren(PosLength==4);% keep only object with position defined by a 4 element vector
                PosChildren=cell2mat(PosChildren(PosLength==4));% transform cell array to a matrix of positions
                xy_panel=(xy_fig-panel_pos(1:2))./panel_pos(3:4);% mouse position relative to the panel
                xy_panel_mat=ones(size(PosChildren,1),1)*xy_panel;% mouse position on the figure transformed to a matrix
                check_pos=xy_panel_mat >= PosChildren(:,1:2) & xy_panel_mat <= PosChildren(:,1:2)+PosChildren(:,3:4);% compare object to mouse position
                ind_object=find(check_pos(:,1) & check_pos(:,2),1);% select the index of the (first) object under the mouse
                if ~isempty(ind_object)
                    hhchild=hhchildren(ind_object);% corresponding object handle
                    if strcmp(get(hhchild,'Type'),'uicontrol')
                        msg_pos=GUI_pos(1:2)+panel_pos(1:2).*GUI_pos(3:4)+PosChildren(ind_object,1:2).*panel_pos(3:4).*GUI_pos(3:4);
                        display_str=get(hhchild,'TooltipString');
                        msgbox_uvmat(['uicontrol: ' get(hhchild,'Tag')],display_str,get(hhchild,'String'),msg_pos);
                    end
                end
            end
            %   return %leave the function once a uicontrol has been selected
    end
end

%% zoom has first priority, stop here
if CheckZoom 
    return
end

%% Creation of a display window zoom of text_display
if isequal(get(hObject,'SelectionType'),'alt') && strcmp(htype,'axes') && ~test_edit && ~test_create 
    set(0,'Unit','pixels')
    GUISize=get(0,'ScreenSize');% get the size of the screen, to put the fig on the upper right   
    Width=300;% fig width in points (1/72 inch)
    Height=200;
    Left=GUI_pos(1)+GUI_pos(3)-Width; %right edge close to the right, with margin=40
    Bottom=GUI_pos(2)+GUI_pos(4)-Height; %put fig at top right
    hfig_text=figure('Name','text_display','MenuBar','none','NumberTitle','off','Position',[Left,Bottom,Width,Height]);
    AxeData.htext_display=uicontrol('Style','edit','Units','normalized', 'Position', [0.05 0.05 0.9 0.9],'Max',2,'BackgroundColor',[1 1 1],...
        'FontUnits','points','FontSize',14);
    set(hchild,'UserData',AxeData);
    return %leave the function once a uicontrol has been selected
end

%% creation of a zoom subfig
if isfield(hhCurrentGUI,'CheckZoomFig') && get(hhCurrentGUI.CheckZoomFig,'Value')
    AxeData.Drawing='zoom'; %initiate drawing mode
    AxeData.CurrentObject=[];%unselect objects
    set(hchild,'UserData',AxeData);
    return
end

if isempty(huvmat)%further options require the uvmat GUI
    return 
end

%% ruler has second priority 
if test_ruler && ~isempty(xy)
    AxeData.RulerCoord(1,1:2)=xy(1,1:2);
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

%% desable  object creation and vector editing if NbDim different from 2
if ~(isfield(AxeData,'NbDim') && isequal(AxeData.NbDim,2))
    test_create=0;
    test_edit_vect=0;
end

%% selection of an existing projection object (third priority)
if  test_edit 
    if ~(isfield(AxeData,'Drawing') && isequal(AxeData.Drawing,'create'))
        userdata=get(hcurrentobject,'UserData');
        if ishandle(userdata)%the selected line depends on a parent line
            AxeData.CurrentObject=userdata;% the parent object becomes the current one
        else
            AxeData.CurrentObject=hcurrentobject;% the selected object becomes the current one
        end
        ObjectData=get(AxeData.CurrentObject,'UserData');
        if isfield(ObjectData,'IndexObj')
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
            if isequal(obj_tag,'DeformPoint')
                 set(hcurrentobject,'Color','m'); %set the selected DeformPoint to magenta color
            end
            IndexObj=ObjectData.IndexObj;
                    %indicate on the list of the GUI uvmat which object has been selected
            if strcmp(get(hCurrentGUI,'tag'),'uvmat') %if the uvmat graph has been selected, object projection is on the other frame view_field
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
                UvData.ProjObject{IndexObj}.Name=list_str{IndexObj};
            end
%             h_set_object=findobj(allchild(0),'Tag','set_object');
%             if ~isempty(h_set_object)
%                 delete(h_set_object)
%             end
            set_object(UvData.ProjObject{IndexObj})
            axes(hchild);%set back the current axes haxes
            testdeform=0;
            set(gcbo,'Pointer','circle'); 
            AxeData.Drawing='deform';
            if isequal(obj_tag,'DeformPoint')       
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
if  test_create && ~isempty(xy) && ~strcmp(get(hCurrentGUI,'SelectionType'),'alt')
    % activate this option if the GUI set_object is opened
    sethandles=guidata(hset_object);% handles of the elements in the GUI set_object
    ObjectData=read_GUI(hset_object); %read object parameters in the GUI set_object
    IndexObj=length(UvData.ProjObject);
    % if the currently selected object is already finished, a new object is initiated
    if ~isfield(UvData.ProjObject{IndexObj},'CreateMode')
        IndexObj=IndexObj+1;%start new object
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
        ListObject=[ListObject;{ObjectName}];
        set(hhuvmat.ListObject,'String',ListObject);%complement the object list
        set(hhuvmat.ListObject_1,'String',ListObject);%complement the object list
        if strcmp(CurrentGUI_tag,'uvmat')
            set(hhuvmat.ListObject,'Value',IndexObj)
        else
            set(hhuvmat.ListObject_1,'Value',IndexObj)
        end
        UvData.ProjObject{IndexObj}.DisplayHandle.uvmat=hhuvmat.PlotAxes; % axes for plot_object
        UvData.ProjObject{IndexObj}.DisplayHandle.view_field=[]; %no plot handle before plot_field operation
        set(hhuvmat.CheckViewObject,'Value',1)
    end
    ObjectData.Coord=[ObjectData.Coord ;xy(1,1:2)];% append the coordinates marked by the mouse to the object
    %TODO replace 0 by z coord for 3D
    hobject=UvData.ProjObject{IndexObj}.DisplayHandle.(CurrentGUI_tag);
    if isempty(hobject)
        hobject=haxes;
    end
    if strcmp(CurrentGUI_tag,'uvmat')
        ProjObject=UvData.ProjObject{get(hhuvmat.ListObject_1,'Value')};
    else
        ProjObject=UvData.ProjObject{get(hhuvmat.ListObject,'Value')};
    end
    AxeData.CurrentObject=plot_object(ObjectData,ProjObject,hobject,'m');%draw the object and its handle becomes AxeData.CurrentObject
    UvData.ProjObject{IndexObj}=ObjectData;
    UvData.ProjObject{IndexObj}.DisplayHandle.(CurrentGUI_tag)=AxeData.CurrentObject;% attribute the current plot object handle to the Object
    UvData.ProjObject{IndexObj}.CreateMode='on';% mark the object as in the course of creation
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

%% create calibration points if the GUI geometry_calib is opened, if the main axes PlotAxes of uvmat has ben selected
if  test_cal && ~isempty(haxes) && strcmp(get(haxes,'tag'),'PlotAxes')
    h_geometry_calib=findobj(allchild(0),'Name','geometry_calib'); %find the geomterty_calib GUI
    hh_geometry_calib=guidata(h_geometry_calib);
    h_edit_append=hh_geometry_calib.edit_append;%findobj(h_geometry_calib,'Tag','edit_append');
    if isequal(get(h_edit_append,'Value'),1) && ~isempty(haxes)
        if ~isequal(get(hhuvmat.TransformName,'Value'),1); %active only with no transform (px coordinates)
            set(hhuvmat.TransformName,'Value',1)
            uvmat('TransformName_Callback',hObject,eventdata,hhuvmat); %file input with xml reading  in uvmat
            set(hhuvmat.CheckFixLimits,'Value',0)% put FixedLimits option to 'off' (to sse the whole field)
            return
        end
        h_ListCoord=hh_geometry_calib.ListCoord; %findobj(h_geometry_calib,'Tag','ListCoord');
        Coord=get(h_ListCoord,'Data');
        %data=read_geometry_calib(Coord);%transform char cell to numbers
        xlim=get(haxes,'XLim');
        ind_range_x=abs((xlim(2)-xlim(1))/50);
        ylim=get(haxes,'YLim');
        ind_range_y=abs((ylim(2)-ylim(1))/50);
        ind_range=sqrt(ind_range_x*ind_range_y);
        test_newpoint=1;
        %if size(data.Coord,2)>=5 %if calibration points already exist
        if ~isempty(Coord)
        XCoord=(Coord(:,4));
        YCoord=(Coord(:,5));
        index_point=find((XCoord<xy(1,1)+ind_range) & (XCoord>xy(1,1)-ind_range) & ...%flagx=1 for the vectors with x position selected by the mouse
            (YCoord<xy(1,2)+ind_range) & (YCoord>xy(1,2)-ind_range),1);%find the first calibration point in the neighborhood of the mouse
        test_newpoint=isempty(index_point);%test for no existing calibration point near the mouse position
        end
        %end
        %val=find(Data.Coord(:,6));
        
        %create a new calib point if we are not close to an existing one
        hh=findobj('Tag','calib_points');%look for handle of calibration points
        if test_newpoint
            Coord=[Coord;[0 0 0 xy(1,1) xy(1,2) 0]];
            set(h_ListCoord,'Data',Coord)
        end
        if isempty(hh)
            hh=line(Coord(:,4),Coord(:,5),'Color','m','Tag','calib_points','LineStyle','.','Marker','+');
        else
            set(hh,'XData',Coord(:,4))
            set(hh,'YData',Coord(:,5))
        end
         if test_newpoint
             set(hh,'UserData',size(Coord,1))% flag the points to edit mode
         else
             set(hh,'UserData',index_point)% mark the selected point index for future mouse motion
         end
        hhh=findobj('Tag','calib_marker');%look for handle of point marker (circle)
        if ~isempty(hhh)
            set(hhh,'Position',[xy(1,1)-ind_range/2 xy(1,2)-ind_range/2 ind_range ind_range])
        else
            rectangle('Curvature',[1 1],...
                'Position',[xy(1,1)-ind_range/2 xy(1,2)-ind_range/2 ind_range ind_range],'EdgeColor','m',...
                'LineStyle','-','Tag','calib_marker');
        end
        AxeData.Drawing='calibration';
    end
end

%% edit vectors
if test_edit_vect && ~isempty(ivec) 
    %create the error flag FF if it does not exist
    if ~isfield(Field,'FF')
        Field.ListVarName=[Field.ListVarName 'FF'];
        Field.VarDimName=[Field.VarDimName Field.VarDimName{CellInfo{icell}.VarIndex_coord_x}];
        nbvar=length(Field.ListVarName);
        Field.VarAttribute{nbvar}.Role='errorflag';
        Field.FF=zeros(size(Field.X));
    end
    if isequal(Field.FF(ivec),0)
        Field.FF(ivec)=100; %mark vector #ivec as false
    else
        Field.FF(ivec)=0;
    end
    PlotParam=read_GUI(hCurrentGUI);
    plot_field(Field,haxes,PlotParam);
    eval(['FigData.' tagaxes '=Field;'])%record the modified field in FigData
    set(hCurrentGUI,'UserData',FigData);
end  
set(haxes,'UserData',AxeData);

