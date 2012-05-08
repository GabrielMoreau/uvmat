%'mouse_up': function  activated when the mouse button is released
%------------------------------------------------------------------------
% function mouse_up(hObject,eventdata,handles)
% activated by the command:
% set(hObject,'WindowButtonUpFcn',{'mouse_up'}), 
% where hObject is the handle of the figure

%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function mouse_up(hObject,eventdata,handles)
%MouseAction='none'; %default
test_zoom=0;%default
test_ruler=0;%default
currentfig=hObject;
tagfig=get(currentfig,'tag');
currentaxes=gca; %store the current axes handle
AxeData=get(currentaxes,'UserData');
if isfield(AxeData,'CurrentOrigin')
    CurrentOrigin=AxeData.CurrentOrigin;
end
if isfield(AxeData,'ParentRect')% case of a zoom plot as current axis
    parentaxes=get(AxeData.ParentRect,'parent');
    AxeData=get(parentaxes,'UserData');
    controlGUI=get(parentaxes,'parent');%handles of the GUI parent of the zoom plot
    hhcurrentfig=guidata(controlGUI);
    testsubplot=1;
else
    hhcurrentfig=guidata(currentfig);%the current figure is a GUI (uvmat or view_field)
    testsubplot=0;
end
test_zoom=get(hhcurrentfig.CheckZoom,'Value');

huvmat=findobj(allchild(0),'tag','uvmat');%find the uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
    UvData=get(huvmat,'UserData');
   test_ruler=~test_zoom && isequal(get(hhuvmat.MenuRuler,'checked'),'on');%test for ruler  action, second priority
end
test_drawing=0;%default

%% finalize the fabrication or the translation/deformation of an object and plot the corresponding projected field
if ~isempty(huvmat) && isfield(AxeData,'Drawing') && ~isequal(AxeData.Drawing,'off') && isfield(AxeData,'CurrentObject')...
           && ~isempty(AxeData.CurrentObject) && ishandle(AxeData.CurrentObject)
    xy=get(currentaxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
    PlotData=get(AxeData.CurrentObject,'UserData');%get data attached to the current projection object  
    IndexObj=PlotData.IndexObj;
    ObjectData=UvData.Object{IndexObj};    
    ObjectData.enable_plot=1;
    
    % ending translation
    if isequal(AxeData.Drawing,'translate')
        XYData=AxeData.CurrentOrigin;
        DX=xy(1,1)-XYData(1);%translation from initial position
        DY=xy(1,2)-XYData(2);
        ObjectData.Coord(:,1)=ObjectData.Coord(:,1)+DX;
        ObjectData.Coord(:,2)=ObjectData.Coord(:,2)+DY;
        
    %ending object deformation
    elseif isequal(AxeData.Drawing,'deform')
        ind_move=AxeData.CurrentIndex;
        ObjectData.Coord(ind_move,1)=xy(1,1);
        ObjectData.Coord(ind_move,2)=xy(1,2);
        
    %creating object   
    else   
        if strcmp(ObjectData.Type,'line')||strcmp(ObjectData.Type,'polyline')||...
                strcmp(ObjectData.Type,'polygon')||strcmp(ObjectData.Type,'points')
            if isfield(AxeData,'ObjectCoord') && size(AxeData.ObjectCoord,2)==3
              xy(1,3)=AxeData.ObjectCoord(1,3); % z coordinate of the mouse: to generalise ...
            else
                 xy(1,3)=0; % z coordinate set to 0 by default
            end
            if ~isequal(ObjectData.Coord,xy(1,:))
                ObjectData.Coord=[ObjectData.Coord ;xy(1,1:2)];% append the coordiantes marked by the mouse to the eobject
            end
        elseif isequal(ObjectData.Type,'rectangle')||isequal(ObjectData.Type,'ellipse')||isequal(ObjectData.Type,'volume')
            XYData=AxeData.CurrentOrigin;
            ObjectData.Coord(1,1)=(xy(1,1)+XYData(1))/2;%origin rectangle, x coordinate
            ObjectData.Coord(1,2)=(xy(1,2)+XYData(2))/2;
            ObjectData.RangeX=abs(xy(1,1)-XYData(1))/2;%rectangle width
            ObjectData.RangeY=abs(xy(1,2)-XYData(2))/2;%rectangle height
        elseif isequal(ObjectData.Type,'plane') %case of 'plane'
            DX=(xy(1,1)-ObjectData.Coord(1,1));
            DY=(xy(1,2)-ObjectData.Coord(1,2));
            ObjectData.Phi=(angle(DX+i*DY))*180/pi;%rectangle width
            if isfield(ObjectData,'RangeX')
                XMax=sqrt(DX*DX+DY*DY);
                if XMax>max(ObjectData.RangeX)
                    ObjectData.RangeX=[min(ObjectData.RangeX) XMax];
                end
            end
        end
    end
    if strcmp(ObjectData.Type,'rectangle')||strcmp(ObjectData.Type,'ellipse')
        NbDefPoint=1;  
    elseif strcmp(ObjectData.Type,'line')|| strcmp(ObjectData.Type,'plane');
        NbDefPoint=2; 
    else
         NbDefPoint=3;
    end
    
    %show object coordinates in the GUI set_object
    h_set_object=findobj(allchild(0),'Tag','set_object');
    hh_set_object=guidata(h_set_object);
    set(hh_set_object.Coord,'Data',ObjectData.Coord);
%     set(hh_set_object.XObject,'String',num2str(ObjectData.Coord(:,1),4)); 
%     set(hh_set_object.YObject,'String',num2str(ObjectData.Coord(:,2),4)); 
%     set(hh_set_object.ZObject,'String',num2str(ObjectData.Coord(:,3),4));
    if strcmp(ObjectData.Type,'rectangle')||strcmp(ObjectData.Type,'ellipse')
        set(hh_set_object.num_RangeX_2,'String',num2str(ObjectData.RangeX,4));
        set(hh_set_object.num_RangeY_2,'String',num2str(ObjectData.RangeY,4));
    end
    if NbDefPoint<=2 || isequal(get(currentfig,'SelectionType'),'alt') ||...
              strcmp(AxeData.Drawing,'translate') || strcmp(AxeData.Drawing,'deform');%stop drawing
        AxeData.CurrentOrigin=[]; %suppress the current origin
       if isequal(ObjectData.Type,'line') && size(ObjectData.Coord,1)<=1
           AxeData.Drawing='off';
           set(currentaxes,'UserData',AxeData);
            return % line needs at leqst two points
       end
       if  ~isempty(ObjectData)
%              testmask=0;
%              hmask=findobj(huvmat,'Tag','makemask');
%              if ~isempty(hmask)
%                 testmask=get(hmask,'Value');
%              end

            %% update the object representation
            ObjectData.DisplayHandle_uvmat=UvData.Object{IndexObj}.DisplayHandle_uvmat;
            ObjectData.DisplayHandle_view_field=UvData.Object{IndexObj}.DisplayHandle_view_field;
            UvData.Object{IndexObj}=ObjectData;%update the current object properties
            hhuvmat=guidata(huvmat);
            IndexObj_1=get(hhuvmat.ListObject_1,'Value');
            IndexObj_2=get(hhuvmat.ListObject,'Value');
            UvData.Object=update_obj(UvData,IndexObj_1,IndexObj_2);

            %% plot the field projected on the object 
            ProjData= proj_field(UvData.Field,ObjectData);%project the current interface field on ObjectData
            if ~isempty(ProjData)
                if strcmp(tagfig,'uvmat')% uvmat plot selected, projection plot seen in view_field
                    hview_field=findobj(allchild(0),'tag','view_field');
                    if isempty(hview_field)
                        hview_field=view_field(ProjData);
                    else
                       hhview_field=guidata(hview_field);
                       [PlotType,PlotParam]=plot_field(ProjData,hhview_field.axes3,read_GUI(hview_field));%update an existing field plot
                        write_plot_param(hhview_field,PlotParam); %update the display of plotting parameters for the current object
                    end
                    ViewFieldData=get(hview_field,'UserData');
                    ViewFieldData.axes3=ProjData;
                    set(hview_field,'UserData',ViewFieldData)
 
                else
                    UvData.axes3=ProjData;
                    [PlotType,PlotParam]=plot_field(ProjData,hhuvmat.axes3,read_GUI(hhuvmat));%update an existing field plot
                    write_plot_param(hhuvmat,PlotParam); %update the display of plotting parameters for the current object
                end
                %[PlotType,PlotParam]=plot_field(ProjData,hh_plotfield.axes3,read_plot_param(hh_plotfield));%update an existing field plot

            end
            set(hhuvmat.edit_object,'BackgroundColor',[1 1 0]);% paint the edit text in yellow
            set(hhuvmat.edit_object,'Value',1);%
            set(hhuvmat.edit_object,'Enable','on');%
            set(hhuvmat.MenuEditObject,'Enable','on');%
            set(hhuvmat.MenuEdit,'Enable','on');%
        end
    else
       AxeData.CurrentOrigin=[xy(1,1) xy(1,2)]; %the current point becomes the new current origin
       test_drawing=1;%allow continuation of drawing object
       UvData.Object{IndexObj}=ObjectData;
    end
    hother=findobj('Tag','deformpoint');%find all the deformpoints
    set(hother,'Color','b');%reset all the deformpoints in 'blue' 
else
    test_drawing=0;
end

%% creation of a new zoom plot
if isequal(get(currentfig,'SelectionType'),'normal');%if left button has been pressed
    hparentfig=currentfig;
    %open or update a new zoom figure if a rectangle has been drawn
    if ishandle(currentaxes);
        if isfield(AxeData,'CurrentRectZoom') && ~isempty(AxeData.CurrentRectZoom) && ishandle(AxeData.CurrentRectZoom)
            PosRect=get(AxeData.CurrentRectZoom,'Position');
            if isfield(AxeData,'CurrentVec') && ~isempty(AxeData.CurrentVec) && ishandle(AxeData.CurrentVec)
                delete(AxeData.CurrentVec)
            end
            if ~testsubplot
                hfig2=figure;%create new figure
                set(hfig2,'name','zoom')
                set(hfig2,'Units','normalized')
                set(hfig2,'Position',[0.2 0.33 0.6 0.6]);
                map=colormap(currentaxes);
                colormap(map);%transmit the current colormap to the zoom fig
                set(hfig2,'Position',[0.2 0.33 0.6 0.6]);
                set(hfig2,'Unit','normalized')
                set(hfig2,'KeyPressFcn',{@keyboard_callback,handles})%set keyboard action function
                set(hfig2,'WindowButtonMotionFcn',{@mouse_motion,handles})%set mouse action function
                set(hfig2,'WindowButtonDownFcn',{@mouse_down})%set mouse click action function
                set(hfig2,'WindowButtonUpFcn',{@mouse_up,handles})
                set(hfig2,'DeleteFcn',{@close_fig,AxeData.CurrentRectZoom,'zoom'})
                set(hfig2,'UserData',AxeData.CurrentRectZoom)% record the parent object (zoom rectangle) in the new fig
                AxeData.ZoomAxes=copyobj(currentaxes,hfig2); %copy the current graph axes to the zoom figure
                ChildAxeData=get(AxeData.ZoomAxes,'UserData');
                if isfield(ChildAxeData,'ParentGUI')
                    ChildAxeData=rmfield(ChildAxeData,'ParentGUI');%no parent GUI, e.g. uvmat,  for the new plot
                end
                %figure(hfig2)
                %set(0,'CurrentFigure',hfig2)% the zoom figure becomes the current figure
                set(AxeData.ZoomAxes,'Position',[0.1300    0.1100    0.7750    0.8150])% standard axes position on a figure
                hcol=findobj(hparentfig,'Tag','Colorbar'); %look for colorbar axes
                if ~isempty(hcol)
                    hcol_new=colorbar;
                    YTick=get(hcol,'YTick');
                    YTicklabel=get(hcol,'Yticklabel');
                    colbarlim=get(hcol,'YLim');
                    newcolbarlim=get(hcol_new,'YLim');
                    scale_bar=(newcolbarlim(2)-newcolbarlim(1))/(colbarlim(2)-colbarlim(1));
                    YTick_rescaled=newcolbarlim(1)+scale_bar*(YTick-colbarlim(1));
                    set(hcol_new,'YTick',YTick_rescaled);
                    set(hcol_new,'Yticklabel',YTicklabel);
                end
            end          
            ChildAxeData.CurrentRectZoom=[]; % no rect zoom in the new window
            ChildAxeData.Drawing='off';
            ChildAxeData.ParentRect=AxeData.CurrentRectZoom;%set the rectangle as a 'parent' associated to the new axe
            PosRect=CurrentOrigin;
            xy=get(currentaxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
            set(AxeData.ZoomAxes,'Xlim',[PosRect(1) xy(1,1)])
            set(AxeData.ZoomAxes,'Ylim',[PosRect(2) xy(1,2)])
            set(AxeData.ZoomAxes,'UserData',ChildAxeData);%update the AxeData of the new axes
        end
    end
end

%% zoom in or out by a factor 2 if no new figure is created
if test_zoom
    xy=get(currentaxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
    xlim=get(currentaxes,'XLim');
    ylim=get(currentaxes,'YLim');
 % if left mouse button has been pressed, zoom in by a factor of 2
    if  isequal(get(currentfig,'SelectionType'),'normal');%if left button has been pressed, zoom in by a factor of 2
        xlim(1)=0.5*xy(1,1)+0.5*xlim(1);
        xlim(2)=0.5*xy(1,1)+0.5*xlim(2);%double the field whith the middle at the selected points
        set(currentaxes,'XLim',xlim)
        ylim(2)=0.5*xy(1,2)+0.5*ylim(2);
        ylim(1)=0.5*xy(1,2)+0.5*ylim(1);
        set(currentaxes,'YLim',ylim)
 % if right mouse button has been pressed, zoom out by a factor of 2
    else
        xlim(1)=2*xlim(1)-xy(1,1);% reverse of the zoom on action
        xlim(2)=2*xlim(2)-xy(1,1);
        ylim(1)=2*ylim(1)-xy(1,2);
        ylim(2)=2*ylim(2)-xy(1,2);
        if isfield(AxeData,'RangeX')&& isfield(AxeData,'RangeY')
            xlim(1)=max(AxeData.RangeX(1),xlim(1));
            xlim(2)=min(AxeData.RangeX(2),xlim(2));
            ylim(1)=max(AxeData.RangeY(1),ylim(1));
            ylim(2)=min(AxeData.RangeY(2),ylim(2));
            if ylim(1)>=ylim(2)|| xlim(1)>=xlim(2)
                xlim=AxeData.RangeX;
                ylim=AxeData.RangeY;
            end
         % desactivate the zoom if the full field is visible within the axes
            if isequal(xlim,AxeData.RangeX) && isequal(ylim,AxeData.RangeY)
                set(hhuvmat.CheckZoom,'Value',0)
                set(hhuvmat.CheckZoom,'BackgroundColor',[0.7 0.7 0.7])
                set(hhuvmat.CheckFixLimits,'Value',0)
                set(hhuvmat.CheckFixLimits,'BackgroundColor',[0.7 0.7 0.7])
            end
        end
        set(currentaxes,'XLim',xlim)
        set(currentaxes,'YLim',ylim)
        %test whther zoom out is operating (to inactivate AxedAta
        if ~isfield(AxeData,'CurrentXLim')|| ~isequal(xlim,AxeData.CurrentXLim)
            AxeData.CurrentXLim=xlim;%
        end
    end
    if isfield(AxeData,'LimEditBox')&& AxeData.LimEditBox% update display of the GUI containing the axis (uvmat or view_field)
        set(hhcurrentfig.num_MinX,'String',num2str(xlim(1)))
        set(hhcurrentfig.num_MaxX,'String',num2str(xlim(2)))
        set(hhcurrentfig.num_MinY,'String',num2str(ylim(1)))
        set(hhcurrentfig.num_MaxY,'String',num2str(ylim(2)))
    end
end

%% editing calibration point
if ~test_zoom && isfield(AxeData,'Drawing') && isequal(AxeData.Drawing,'calibration')
    h_geometry_calib=findobj(allchild(0),'tag','geometry_calib'); %find the geomterty_calib GUI
    if ~isempty(h_geometry_calib)
        hh_geometry_calib=guidata(h_geometry_calib);
        edit_test=get(hh_geometry_calib.edit_append,'Value');
        hh=findobj(currentaxes,'tag','calib_points');%look for handle of calibration points
        if ~isempty(hh) && edit_test
            index_point=get(hh,'UserData');
            set(hh,'UserData',[])%remove edit mode
            h_ListCoord=hh_geometry_calib.ListCoord; %handles of the coordinate list
            Coord=get(h_ListCoord,'String');
            data=read_geometry_calib(Coord);
            %         val=get(h_ListCoord,'Value');
            xy=get(currentaxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
            data.Coord(index_point,4)=xy(1,1);
            data.Coord(index_point,5)=xy(1,2);
            for ipoint=1:size(data.Coord,1)
                for jcoord=1:5
                    Coord_cell{ipoint,jcoord}=num2str(data.Coord(ipoint,jcoord),4);%display coordiantes with 4 digits
                end
            end
            Tabchar=cell2tab(Coord_cell,' | ');
            Tabchar=[Tabchar ;{'......'}];
            set(h_ListCoord,'String',Tabchar)
            set(hh,'XData',data.Coord(:,4))
            set(hh,'YData',data.Coord(:,5))
        end
    end
end

%% finalising ruler
if test_ruler
    set(hhuvmat.MenuRuler,'checked','off')%desable the ruler option in uvmat  
    xy=get(currentaxes,'CurrentPoint');% get the current mouse coordinates 
    RulerCoord=[AxeData.RulerCoord ;xy(1,1:2)];% append the recorded ruler origin to the current mouse coordinates 
    RulerCoord=diff(RulerCoord,1);% coordiante difference between segment end and beginning
    RulerCoord=RulerCoord(1)+i*RulerCoord(2);
    distance=abs(RulerCoord);
    azimuth=(180/pi)*angle(RulerCoord);
    msgbox_uvmat('RULER','',['length: ' num2str(distance,3) ',  angle(degrees): ' num2str(azimuth,3)])
    delete(AxeData.RulerHandle)%delete the ruler graphic object
    AxeData=rmfield(AxeData,'RulerHandle');%remove the ruler handle in AxeData
    AxeData.Drawing='off';%exit the ruler drawing mode
end

%% display the data of the current object selected with the mouse right click
if isequal(get(currentfig,'SelectionType'),'alt') && ~test_zoom && (~isfield(AxeData,'Drawing')||~isequal(AxeData.Drawing,'create'))
    hother=findobj('Tag','proj_object');%find all the proj objects
    nbselect=0;
    %test the existence of selected objects:
    for iproj=1:length(hother);
        iselect=isequal(get(hother(iproj),'Selected'),'on');%reset all the proj objects in 'blue' by default
        nbselect=nbselect+iselect;
    end
    hother=findobj('Tag','proj_object','Type','line');%find all the proj objects
    set(hother,'Color','b');%reset all the proj objects in 'blue' by default
    set(hother,'Selected','off')
    hother=findobj('Tag','proj_object','Type','rectangle');
    set(hother,'EdgeColor','b');
    set(hother,'Selected','off')
    hother=findobj('Tag','proj_object','Type','patch');
    set(hother,'FaceColor','b');   
    if isequal(get(gco,'Type'),'image')
        currentobj=get(gco,'parent');%parent axes of the image
    else 
        currentobj=gco;%default
    end
%     if ((nbselect==0) && isequal(get(currentobj,'Type'),'axes')) || isequal(currentobj,huvmat)
%         currentfig=get(currentobj,'parent');
%         figname=get(currentfig,'name');
%         eval(['global Data_' figname])
%         eval(['Data_' figname '=get(currentobj,''UserData'')']);
%         evalin('base',['global Data_' figname])%make CurData global in the workspace
%         objtype=get(currentobj,'Type');
%         display(['UserData of ' objtype ':'])
%         evalin('base',['Data_' figname]) %display CurData in the workspace
%         commandwindow %brings the Matlab command window to the front
%     end
end

%% update 
if test_drawing==0
        AxeData.Drawing='off';%stop current drawing action
end
set(currentaxes,'UserData',AxeData);
if ~isempty(huvmat)
    set(huvmat,'UserData',UvData);
end

    

