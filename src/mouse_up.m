%'mouse_up': function  activated when the mouse button is released
%----------------------------------------------------------------
% function mouse_up(hObject,eventdata,handles)
% activated by the command:
% set(hObject,'WindowButtonUpFcn',{'mouse_up'}), 
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

function mouse_up(hObject,eventdata,handles)
MouseAction='none'; %default
zoomstate=0;%default
if ~exist('handles','var')
   handles=get(gcbo,'UserData');
end
huvmat=findobj(allchild(0),'Name','uvmat');%find the uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
    UvData=get(huvmat,'UserData');
    if isfield(UvData,'MouseAction')
        MouseAction=UvData.MouseAction;% set the mouse action (edit, create objects...)
    end
    zoomstate=get(hhuvmat.zoom,'Value');
end
currentfig=hObject;
currentaxes=gca; %store the current axes handle
AxeData=get(currentaxes,'UserData');

test_drawing=0;%default

%finalize the fabrication or the translation/deformation of an object and plot the corresponding projected field
if ~isempty(huvmat) & isfield(AxeData,'Drawing') & ~isequal(AxeData.Drawing,'off') & isfield(AxeData,'CurrentObject')...
           & ishandle(AxeData.CurrentObject)
    xy=get(currentaxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
    PlotData=get(AxeData.CurrentObject,'UserData');%get data attached to the current projection object  
    IndexObj=PlotData.IndexObj;
    ObjectData=UvData.Object{IndexObj};    
    ObjectData.enable_plot=1;
    if isequal(AxeData.Drawing,'translate')
        XYData=AxeData.CurrentOrigin;
        DX=xy(1,1)-XYData(1);%translation from initial position
        DY=xy(1,2)-XYData(2);
        ObjectData.Coord(:,1)=ObjectData.Coord(:,1)+DX;
        ObjectData.Coord(:,2)=ObjectData.Coord(:,2)+DY;
    elseif isequal(AxeData.Drawing,'deform')
        ind_move=AxeData.CurrentIndex;
        ObjectData.Coord(ind_move,1)=xy(1,1);
        ObjectData.Coord(ind_move,2)=xy(1,2);
    else   %creating object
        if isequal(ObjectData.Style,'line')||isequal(ObjectData.Style,'polyline')||...
                isequal(ObjectData.Style,'polygon')||isequal(ObjectData.Style,'points')
            if isfield(AxeData,'ObjectCoord') && size(AxeData.ObjectCoord,2)==3
              xy(1,3)=AxeData.ObjectCoord(1,3); % z coordinate of the mouse: to generalise ...
            else
                 xy(1,3)=0; % z coordinate set to 0 by default
            end
            if ~isequal(ObjectData.Coord,xy(1,:))
                ObjectData.Coord=[ObjectData.Coord ;xy(1,:)];% append the coordiantes marked by the mouse to the eobject
            end
        elseif isequal(ObjectData.Style,'rectangle')||isequal(ObjectData.Style,'ellipse')||isequal(ObjectData.Style,'volume')
            XYData=AxeData.CurrentOrigin;
            ObjectData.Coord(1,1)=(xy(1,1)+XYData(1))/2;%origin rectangle, x coordinate
            ObjectData.Coord(1,2)=(xy(1,2)+XYData(2))/2;
            ObjectData.RangeX=abs(xy(1,1)-XYData(1))/2;%rectangle width
            ObjectData.RangeY=abs(xy(1,2)-XYData(2))/2;%rectangle height
        elseif isequal(ObjectData.Style,'plane') %case of 'plane'
            DX=(xy(1,1)-ObjectData.Coord(1,1));
            DY=(xy(1,2)-ObjectData.Coord(1,2));
            ObjectData.Phi=(angle(DX+i*DY))*180/pi;%rectangle widt
            if isfield(ObjectData,'RangeX')
                XMax=sqrt(DX*DX+DY*DY);
                if XMax>max(ObjectData.RangeX)
                    ObjectData.RangeX=[min(ObjectData.RangeX) XMax];
                end
            end
        end
    end
    %set(AxeData.CurrentObject,'UserData',ObjectData); %update the object properties
    if isequal(ObjectData.Style,'rectangle')||isequal(ObjectData.Style,'ellipse')
        NbDefPoint=1;  
    elseif isequal(ObjectData.Style,'line')|| isequal(ObjectData.Style,'plane');
        NbDefPoint=2; 
    else
         NbDefPoint=3;
    end
    
    %show object coordinates in the GUI set_object
    h_set_object=findobj(allchild(0),'Name','set_object');
    h_XObject=findobj(h_set_object,'Tag','XObject');
    h_YObject=findobj(h_set_object,'Tag','YObject');
    h_ZObject=findobj(h_set_object,'Tag','ZObject');
    set(h_XObject,'String',num2str(ObjectData.Coord(:,1),4)); 
    set(h_YObject,'String',num2str(ObjectData.Coord(:,2),4)); 
    set(h_ZObject,'String',num2str(ObjectData.Coord(:,3),4));
    if NbDefPoint<=2 || isequal(get(currentfig,'SelectionType'),'alt') ||...
              isequal(AxeData.Drawing,'translate') || isequal(AxeData.Drawing,'deform');%stop drawing
        AxeData.CurrentOrigin=[]; %suppress the current origin
       if isequal(ObjectData.Style,'line') && size(ObjectData.Coord,1)<=1
           AxeData.Drawing='off';
           set(currentaxes,'UserData',AxeData);
            return % line needs at leqst two points
       end
       if  ~isempty(ObjectData)
             testmask=0;
             hmask=findobj(huvmat,'Tag','makemask');
             if ~isempty(hmask)
                testmask=get(hmask,'Value');
             end
             if testmask
                 PlotHandles=[];%do not project data on the object during mask creation
             else
                 PlotHandles=get_plot_handles(handles);%get the handles of the graphic objects setting the plotting parameters
             end
            AxeData.hset_object=set_object(ObjectData,PlotHandles);% call the set_object interface ,*
            UvData.Object{IndexObj}=update_obj(UvData,IndexObj,ObjectData,PlotHandles); 
            %ObjectData=update_obj(UvData,IndexObj,ObjectData,PlotHandles); 
            if  isfield(UvData.Object{IndexObj},'PlotParam')
                write_plot_param(PlotHandles,UvData.Object{IndexObj}.PlotParam); %update the display of plotting parameters for the current object
            end              
%             set(hhuvmat.create,'Value',0);% set to 'off' the button for object creation
%             set(hhuvmat.create,'BackgroundColor',[0 1 0]);% paint the creation button in green
            set(hhuvmat.edit,'BackgroundColor',[1 1 0]);% paint the edit text in yellow
            set(hhuvmat.edit,'Value',1);%
            set(hhuvmat.edit,'Enable','on');%
            set(hhuvmat.MenuEditObject,'Enable','on');%
            set(hhuvmat.MenuEdit,'Enable','on');%
%             set(hhuvmat.MenuObject,'Enable','on');%
            UvData.MouseAction='edit_object'; % set the edit button to 'on'
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

%creation of a new zoom plot
test_replot=0;
if isequal(get(currentfig,'SelectionType'),'normal');%if left button has been pressed
%         FigData=get(currentfig,'UserData');
        hparentfig=currentfig;
        %open or update a new zoom figure if a rectangle has been drawn
        if ishandle(currentaxes);
            if isfield(AxeData,'CurrentRectZoom') & ishandle(AxeData.CurrentRectZoom)
                PosRect=get(AxeData.CurrentRectZoom,'Position');
                if isfield(AxeData,'CurrentVec') & ishandle(AxeData.CurrentVec)
                    delete(AxeData.CurrentVec)
                end
                hfig2=figure;%create new figure
                set(hfig2,'name','zoom')
                set(hfig2,'Units','normalized')
                set(hfig2,'Position',[0.2 0.33 0.6 0.6]);
                map=colormap(currentaxes);
                colormap(map);%transmit the current colormap to the zoom fig
                get(handles.RootFile,'String')
                set(hfig2,'Position',[0.2 0.33 0.6 0.6]);
                if test_replot==0
                    set(hfig2,'Unit','normalized')
                    set(hfig2,'KeyPressFcn',{@keyboard_callback,handles})%set keyboard action function
                    set(hfig2,'WindowButtonMotionFcn',{@mouse_motion,handles})%set mouse action function
                    set(hfig2,'WindowButtonDownFcn',{@mouse_down})%set mouse click action function
                    set(hfig2,'WindowButtonUpFcn',{@mouse_up,handles})  
                    set(hfig2,'DeleteFcn',{@close_fig,AxeData.CurrentRectZoom,'zoom'})
                    set(hfig2,'UserData',AxeData.CurrentRectZoom)% record the parent object (zoom rectangle) in the new fig
                    AxeData.ZoomAxes=copyobj(currentaxes,hfig2); %copy the current graph axes to the zoom figure 
                    figure(hfig2)
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
                if ishandle(AxeData.ZoomAxes)
                    hnew_rect=findobj(AxeData.ZoomAxes,'Tag','rect_zoom');
                    if ~isempty(hnew_rect)
                        delete(hnew_rect);
                        ChildAxeData=get(AxeData.ZoomAxes,'UserData');
                        ChildAxeData.CurrentRectZoom=[]; % no rect zoom in the new window
                        ChildAxeData.Drawing='off';
                        ChildAxeData.ParentRect=AxeData.CurrentRectZoom;%set the rectangle as a 'parent' associated to the new axes
                        set(AxeData.ZoomAxes,'UserData',ChildAxeData);%update the AxeData of the new axes
                        set(AxeData.ZoomAxes,'Xlim',[PosRect(1) PosRect(1)+PosRect(3)])
                        set(AxeData.ZoomAxes,'Ylim',[PosRect(2) PosRect(2)+PosRect(4)])
                    end
                end
            end
        end
end
%zoom in if no new figure is created
if zoomstate
     if  isequal(get(currentfig,'SelectionType'),'normal');%if left button has been pressed
        %zoom(2)% zoom in by a factor of 2
        alpha=0.5; %zoom factor (zoom in by a factor 2)
        xlim=get(currentaxes,'XLim');
        xlim_new(1)=(1+alpha)*xlim(1)/2+(1-alpha)*xlim(2)/2;
        xlim_new(2)=(1-alpha)*xlim(1)/2+(1+alpha)*xlim(2)/2;
        set(currentaxes,'XLim',xlim_new)
        ylim=get(currentaxes,'YLim'); 
        ylim_new(1)=(1+alpha)*ylim(1)/2+(1-alpha)*ylim(2)/2;
        ylim_new(2)=(1-alpha)*ylim(1)/2+(1+alpha)*ylim(2)/2;
        set(currentaxes,'YLim',ylim_new)
        if isfield(AxeData,'ParentRect')% update the position of the parent rectangle represneting the field
            hparentrect=AxeData.ParentRect;
            xlim=get(currentaxes,'XLim');
            ylim=get(currentaxes,'YLim');
            rect([1 2])=[xlim(1) ylim(1)];
            rect([3 4])=[xlim(2)-xlim(1) ylim(2)-ylim(1)];
            set(hparentrect,'Position',rect)
        end

     elseif isequal(get(currentfig,'SelectionType'),'alt'); %if right button has been pressed
            %zoom(0.5)% zoom out by a factor of 2
            alpha=2; %zoom factor (zoom out by a factor 2)
            xlim=get(currentaxes,'XLim');
            xlim_new(1)=(1+alpha)*xlim(1)/2+(1-alpha)*xlim(2)/2;
            xlim_new(2)=(1-alpha)*xlim(1)/2+(1+alpha)*xlim(2)/2;
            ylim=get(currentaxes,'YLim');
            ylim_new(1)=(1+alpha)*ylim(1)/2+(1-alpha)*ylim(2)/2;
            ylim_new(2)=(1-alpha)*ylim(1)/2+(1+alpha)*ylim(2)/2;
            set(currentaxes,'XLim',xlim_new)
            set(currentaxes,'YLim',ylim_new)
            %test whther zoom out is operating (to inactivate AxedAta
            if ~isfield(AxeData,'CurrentXLim')| ~isequal(xlim,AxeData.CurrentXLim)
                AxeData.CurrentXLim=xlim;%
            end
            if isfield(AxeData,'ParentRect')% update the position of the parent rectangle represneting the field
                hparentrect=AxeData.ParentRect;
                xlim=get(currentaxes,'XLim');
                ylim=get(currentaxes,'YLim');
                rect([1 2])=[xlim(1) ylim(1)];
                rect([3 4])=[xlim(2)-xlim(1) ylim(2)-ylim(1)];
                set(hparentrect,'Position',rect)
            end
      end
end

% editing calibration point
if ~zoomstate && strcmp(MouseAction,'calib') 
    h_geometry_calib=findobj(allchild(0),'Name','geometry_calib'); %find the geomterty_calib GUI
    hh_geometry_calib=guidata(h_geometry_calib);
    edit_test=get(hh_geometry_calib.edit_append,'Value');
    hh=findobj(currentaxes,'Tag','calib_points');%look for handle of calibration points           
    if ~isempty(hh) && edit_test
        index_point=get(hh,'UserData');
        set(hh,'UserData',[])%remove edit mode
        h_ListCoord=hh_geometry_calib.ListCoord; %handles of the coordinate list
        Coord=get(h_ListCoord,'String');
%         val=get(h_ListCoord,'Value');
        coord_str=Coord{index_point}; %current line (string)
        k=findstr('|',coord_str);%find separator indices on the string
        xy=get(currentaxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates 
        if numel(k)>=3
            coord_str=[coord_str(1:k(3)-1) '|    ' num2str(xy(1,1),4) '    |    ' num2str(xy(1,2),4)]; %update the pixel information while preserving phys coord
        else
            coord_str=[ '    |    '  '    |    '  '    |    ' num2str(xy(1,1),4) '    |    ' num2str(xy(1,2),4)];
        end
        Coord{index_point}=coord_str;        
        set(h_ListCoord,'String',Coord)
        data=read_geometry_calib(Coord);%transform char cell to numbers
        set(hh,'XData',data.Coord(:,4))
        set(hh,'YData',data.Coord(:,5))
    end
end

% finalising ruler
if strcmp(MouseAction,'ruler')
    UvData.MouseAction='none';
    UvData=rmfield(UvData,'RulerHandle');
     xy=get(currentaxes,'CurrentPoint');
    RulerCoord=[UvData.RulerCoord ;xy(1,1:2)];
    set(huvmat,'UserData',UvData)
    RulerCoord=diff(RulerCoord,1);
    RulerCoord=RulerCoord(1)+i*RulerCoord(2);
    distance=abs(RulerCoord);
    azimuth=(180/pi)*angle(RulerCoord);
    msgbox_uvmat('RULER','',['length: ' num2str(distance,3) ',  angle(degrees): ' num2str(azimuth,3)])
    hruler=findobj(currentaxes,'Tag','ruler');
    delete(hruler)
    AxeData.Drawing='off';%stop current drawing a
end


%display the data of the current object selected with the mouse right click
if isequal(get(currentfig,'SelectionType'),'alt') && ~zoomstate && (~isfield(AxeData,'Drawing')||~isequal(AxeData.Drawing,'create'))
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
    if ((nbselect==0) && isequal(get(currentobj,'Type'),'axes')) || isequal(currentobj,huvmat)
        global CurData
        CurData=get(currentobj,'UserData');
        %plot_text(CurData)
        %get_field([],CurData);
        evalin('base','global CurData')%make CurData global in the workspace
        objtype=get(currentobj,'Type');
        display(['UserData of ' objtype ':'])
        evalin('base','CurData') %display CurData in the workspace
        commandwindow
    end
end
if test_drawing==0
        AxeData.Drawing='off';%stop current drawing action
end
set(currentaxes,'UserData',AxeData);
if ~isempty(huvmat)
    set(huvmat,'UserData',UvData);
end

    

