%'mouse_up': function  activated when the mouse button is released
%------------------------------------------------------------------------
% function mouse_up(hObject,eventdata,handles)
% activated by the command:
% set(hObject,'WindowButtonUpFcn',{'mouse_up'}), 
% where hObject is the handle of the figure

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function mouse_up(hObject,eventdata,handles)

test_ruler=0;%default
hcurrentaxes=get(hObject,'CurrentAxes');
if isempty(hcurrentaxes)
    return % no axes in the current figure
end
AxeData=get(hcurrentaxes,'UserData');
if isfield(AxeData,'ParentAxes')% case of a zoom plot as current axis
    hcurrentaxes=AxeData.ParentAxes;
    AxeData=get(hcurrentaxes,'UserData');
    hcurrentfig=get(hcurrentaxes,'parent');%handles of the GUI parent of the zoom plot
    testsubplot=1;% mouse selection is on a zoom subplot
else
    hcurrentfig=hObject;
    testsubplot=0;
end
%set(get(hcurrentfig,'CurrentObject'),'Selected','off')

CurrentOrigin=[];
if isfield(AxeData,'CurrentOrigin')
    CurrentOrigin=AxeData.CurrentOrigin;
end
FigTag=get(hcurrentfig,'tag');
hhcurrentfig=guidata(hcurrentfig);%the current figure is a GUI (uvmat or view_field)
CheckZoom=get(hhcurrentfig.CheckZoom,'Value');
CheckZoomFig=get(hhcurrentfig.CheckZoomFig,'Value');%exclusive to CheckZoom
huvmat=findobj(allchild(0),'tag','uvmat');%find the uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
    UvData=get(huvmat,'UserData');
   test_ruler=~CheckZoom && isequal(get(hhuvmat.MenuRuler,'checked'),'on');%test for ruler  action, second priority
end
test_drawing=0;%default, =1 to allow drawing by further mouse action
if ~(isfield(AxeData,'Enable')&& strcmp(AxeData.Enable,'on'))
    return
end

xy=get(hcurrentaxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates


%% proceed with the creation or editing (translation/deformation) of an object
if ~isempty(huvmat) && isfield(AxeData,'Drawing') && ~isequal(AxeData.Drawing,'off') && isfield(AxeData,'CurrentObject')...
        && ~isempty(AxeData.CurrentObject) && ishandle(AxeData.CurrentObject)
    set(AxeData.CurrentObject,'Selected','off')
    PlotData=get(AxeData.CurrentObject,'UserData');%get data attached to the current projection object
    IndexObj=PlotData.IndexObj;
    ObjectData=UvData.ProjObject{IndexObj};
    check_multiple=0;
    
    h_set_object=findobj(allchild(0),'Tag','set_object');
    hh_set_object=guidata(h_set_object);
    ObjectData.Coord=get(hh_set_object.Coord,'Data');
    
    % ending translation
    if isequal(AxeData.Drawing,'translate')
        XYData=AxeData.CurrentOrigin;
        DX=xy(1,1)-XYData(1);%translation from initial position
        DY=xy(1,2)-XYData(2);
        ObjectData.Coord(:,1)=ObjectData.Coord(:,1)+DX;
        ObjectData.Coord(:,2)=ObjectData.Coord(:,2)+DY;
        set(hh_set_object.Coord,'Data',ObjectData.Coord);
        %ending object deformation
    elseif isequal(AxeData.Drawing,'deform')
        ind_move=AxeData.CurrentIndex;
        ObjectData.Coord(ind_move,1)=xy(1,1);
        ObjectData.Coord(ind_move,2)=xy(1,2);
        set(hh_set_object.Coord,'Data',ObjectData.Coord);
        %creating object
    else
        switch ObjectData.Type
            case {'line','plane'}
                if size(ObjectData.Coord,1)==1 % this is the mouse up for the first point, continue until next click
                    check_multiple=1;
                end
            case {'rectangle','ellipse','volume'}
                ObjectData.Coord=(CurrentOrigin+xy(1,1:2))/2;% keep only the first point coordinate
                ObjectData.RangeX=abs(ObjectData.Coord(1,1)-xy(1,1));%rectangle width
                ObjectData.RangeY=abs(ObjectData.Coord(1,2)-xy(1,2));%rectangle height
                if isequal(ObjectData.RangeX,0)||isequal(ObjectData.RangeY,0)
                    check_multiple=1;% pass to next mous up if width of height=0
                end
%             case 'plane' %case of 'plane', TODO: NOT ACTIVATED
%                 DX=(xy(1,1)-ObjectData.Coord(1,1));
%                 DY=(xy(1,2)-ObjectData.Coord(1,2));
%                 ObjectData.Phi=(angle(DX+i*DY))*180/pi;%rectangle width
%                 if isfield(ObjectData,'RangeX')
%                     XMax=sqrt(DX*DX+DY*DY);
%                     if XMax>max(ObjectData.RangeX)
%                         ObjectData.RangeX=[min(ObjectData.RangeX) XMax];
%                     end
%                 end
            otherwise
                check_multiple=1;
        end
    end
    
    %show object coordinates in the GUI set_object
    if strcmp(ObjectData.Type,'rectangle')||strcmp(ObjectData.Type,'ellipse')
        set(hh_set_object.Coord,'Data',ObjectData.Coord);
        set(hh_set_object.num_RangeX_2,'String',num2str(ObjectData.RangeX,4));
        set(hh_set_object.num_RangeY_2,'String',num2str(ObjectData.RangeY,4));
    end
    
    %% stop drawing and plot the projected field if the object manipulation is finished
    if check_multiple==0  || isequal(get(hcurrentfig,'SelectionType'),'alt')
        pointer=get(hcurrentfig,'Pointer');%memorize the current pointer shape
        set(hcurrentfig,'Pointer','watch')% set the pointer shape to watch to prevent further mouse action
        AxeData.CurrentOrigin=[]; %suppress the current origin
        hobject=UvData.ProjObject{IndexObj}.DisplayHandle.(FigTag);
        if ~isempty(hObject)
            ProjObject=UvData.ProjObject{get(hhuvmat.ListObject_1,'Value')};
            AxeData.CurrentObject=plot_object(ObjectData,ProjObject,hobject,'m');%draw the object and its handle becomes AxeData.CurrentObject
        end
        %%
        if  ~isempty(ObjectData)
            % plot the field projected on the object
            [ProjData,errormsg]= proj_field(UvData.Field,ObjectData);%project the current interface field on ObjectData
            if isempty(errormsg) && ~isempty(ProjData)
                if strcmp(FigTag,'uvmat')% uvmat plot selected, projection plot seen in view_field
                    hview_field=findobj(allchild(0),'tag','view_field');
                    if isempty(hview_field)
                        hview_field=view_field(ProjData); %open the view_field GUI for plot
                    else
                        hhview_field=guidata(hview_field);
                        [PlotType,PlotParam]=plot_field(ProjData,hhview_field.PlotAxes,read_GUI(hview_field));%update an existing  plot in view_field
                        errormsg=fill_GUI(PlotParam,hview_field);
                    end
                    ViewFieldData=get(hview_field,'UserData');
                    haxes=findobj(hview_field,'tag','axes3');
                    if strcmp(get(haxes,'Visible'),'off')%sempty(PlotParam.Coordinates)% case of no plot display (pure text table)
                        h_TableDisplay=findobj(hview_field,'tag','TableDisplay');
                        pos_table=get(h_TableDisplay,'Position');
                        pos=get(hview_field,'Position');
                        set(hview_field,'Position',[pos(1)+pos(3)-pos_table(3) pos(2)+pos(4)-pos_table(4) pos_table(3) pos_table(4)])
                        drawnow
                        set(hview_field,'UserData',ViewFieldData);% restore the previously stored GUI position after GUI resizing
                    elseif isfield(ViewFieldData,'GUISize')
                        set(hview_field,'Position',ViewFieldData.GUISize)
                    end
                else
                    UvData.PlotAxes=ProjData;
                    [PlotType,PlotParam]=plot_field(ProjData,hhuvmat.PlotAxes,read_GUI(huvmat));%update an existing field plot
                    errormsg=fill_GUI(PlotParam,huvmat);
                end
            end
            if ~isempty(errormsg)
                msgbox_uvmat('ERROR',errormsg)
                return
            end
            set(hhuvmat.CheckViewField,'Value',1);%
            set(hhuvmat.CheckEditObject,'Value',1);%   
            set(hhuvmat.MenuObject,'checked','off'); %desactivate object creation mode
            set(hhuvmat.CheckEditObject,'Enable','on');%
            set(get(h_set_object,'children'),'Enable','on')
        end
        UvData.ProjObject{IndexObj}=ObjectData;
        if isfield(UvData.ProjObject{IndexObj},'CreateMode')
            UvData.ProjObject{IndexObj}=rmfield(UvData.ProjObject{IndexObj},'CreateMode');%remove createMode to mark the object as finished
        end
        set(hcurrentfig,'Pointer',pointer)% % revert the pointer shape to allow further mouse action
    else
        test_drawing=1;%allow continuation of drawing object
        AxeData.CurrentOrigin=[xy(1,1) xy(1,2)]; %the current point becomes the next current origin
    end
    %     UvData.ProjObject{IndexObj}=ObjectData;
    hother=findobj('Tag','deformpoint');%find all the deformpoints
    set(hother,'Color','b');%reset all the deformpoints in 'blue'
end

%% creation or update of a  zoom sub-plot
if CheckZoomFig && isequal(get(hcurrentfig,'SelectionType'),'normal')&&...%if left button has been pressed
     ~isempty(CurrentOrigin) && ~isequal(CurrentOrigin(1),xy(1,1)) && ~isequal(CurrentOrigin(2),xy(1,2))%if mouse moved in x and y since presed down
    hparentfig=hcurrentfig;
    %open or update a new zoom figure if a rectangle has been drawn
    if ishandle(hcurrentaxes)
        if isfield(AxeData,'CurrentRectZoom') && ~isempty(AxeData.CurrentRectZoom) && ishandle(AxeData.CurrentRectZoom)
            %PosRect=get(AxeData.CurrentRectZoom,'Position');
            if isfield(AxeData,'CurrentVec') && ~isempty(AxeData.CurrentVec) && ishandle(AxeData.CurrentVec)
                delete(AxeData.CurrentVec)
            end
            if ~testsubplot% if we are not already on a zoom plot
                hfig2=findobj(allchild(0),'Tag','zoom_fig');
                if isempty(hfig2)% create zoom sub plot if absent
                    hfig2=figure('name',['zoom_' FigTag],'tag','zoom_fig');%create new figure (unit='pixels' by default)
                    set(0,'Unit','pixels')
                    FigPos=get(hfig2,'Position');%get the standard width and height of the fig
                    ScreenSize=get(0,'ScreenSize');% get the size of the screen, to put the fig on the upper right
                    Left=ScreenSize(3)- FigPos(3)-40; %right edge close to the right, with margin=40
                    Bottom=ScreenSize(4)-FigPos(4)-40; %put fig at top right
                    FigPos(1:2)=[Left Bottom];
                    set(hfig2,'Position',FigPos);% put the zoom fig close to the upper right of the screen
                    map=colormap(hcurrentaxes);
                    colormap(map);%transmit the current colormap to the zoom fig
                    set(hfig2,'KeyPressFcn',{@keyboard_callback,handles})%set keyboard action function
                    set(hfig2,'WindowButtonMotionFcn',{@mouse_motion,handles})%set mouse action function
                    set(hfig2,'WindowButtonDownFcn',{@mouse_down})%set mouse click action function
                    set(hfig2,'WindowButtonUpFcn',{@mouse_up,handles})
                else
                    zoom_axes=findobj(hfig2,'Type','axes');%delete existing axes
                    axes(zoom_axes);%make the zoom axes apparent
                    delete(zoom_axes)
                end
                set(hfig2,'DeleteFcn',{@close_fig,AxeData.CurrentRectZoom})
                set(hfig2,'UserData',AxeData.CurrentRectZoom)% record the parent object (zoom rectangle) in the new fig   
                AxeData.ZoomAxes=copyobj(hcurrentaxes,hfig2); %copy the current graph axes to the zoom figure
                hrect_zoom=findobj(AxeData.ZoomAxes,'Tag','rect_zoom');%find and delete the copy of the rect_zoom rectangle
                delete(hrect_zoom)
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
                ChildAxeData=get(AxeData.ZoomAxes,'UserData');
            end  
            ChildAxeData.CurrentOrigin=[];% forget the current origin
            ChildAxeData.CurrentRectZoom=[]; % no rect zoom in the new window
            ChildAxeData.Drawing='off';
            ChildAxeData.ParentAxes=hcurrentaxes;
            ChildAxeData.ParentRect=AxeData.CurrentRectZoom;%set the rectangle drawing as a 'parent' associated to the new axe
            if xy(1,1)>CurrentOrigin(1)
            set(AxeData.ZoomAxes,'Xlim',[CurrentOrigin(1) xy(1,1)])
            else
                set(AxeData.ZoomAxes,'Xlim',[xy(1,1) CurrentOrigin(1)])
            end
            if xy(1,2)>CurrentOrigin(2)
            set(AxeData.ZoomAxes,'Ylim',[CurrentOrigin(2) xy(1,2)])
            else
                set(AxeData.ZoomAxes,'Ylim',[xy(1,2) CurrentOrigin(2)])
            end
            set(AxeData.ZoomAxes,'UserData',ChildAxeData);%update the AxeData of the new axes
        end
    end
end

%% zoom in or out by a factor 2 if no new figure is created
if CheckZoom
    if testsubplot
        haxes=gca;% zoom on a zoom sub-plot
    else
        haxes=hcurrentaxes;% zoom on the main plot
    end
   % xy=get(haxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
    xlim=get(haxes,'XLim');
    ylim=get(haxes,'YLim');
    % if left mouse button has been pressed, zoom in by a factor of 2
    if  isequal(get(gcf,'SelectionType'),'normal');%if left button has been pressed, zoom in by a factor of 2
        PlotBoxAspectRatio=get(haxes,'PlotBoxAspectRatio');
        yoverx=PlotBoxAspectRatio(2)/PlotBoxAspectRatio(1);
        if yoverx <2
            xlim(1)=0.5*xy(1,1)+0.5*xlim(1);
            xlim(2)=0.5*xy(1,1)+0.5*xlim(2);%double the field whith the middle at the selected points
            set(haxes,'XLim',xlim)
        end
        if yoverx >0.5
            ylim(2)=0.5*xy(1,2)+0.5*ylim(2);
            ylim(1)=0.5*xy(1,2)+0.5*ylim(1);
            set(haxes,'YLim',ylim)
        end
        
        % if right mouse button has been pressed, zoom out by a factor of 2
    else
        xlim(1)=2*xlim(1)-xy(1,1);% reverse of the zoom on action
        xlim(2)=2*xlim(2)-xy(1,1);
        ylim(1)=2*ylim(1)-xy(1,2);
        ylim(2)=2*ylim(2)-xy(1,2);
        % adjust the zoom out to the available field
        if ~testsubplot && isfield(AxeData,'RangeX')&& isfield(AxeData,'RangeY')
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
               % set(hhuvmat.CheckZoom,'BackgroundColor',[0.7 0.7 0.7])
                set(hhuvmat.CheckFixLimits,'Value',0)
              %  set(hhuvmat.CheckFixLimits,'BackgroundColor',[0.7 0.7 0.7])
            end
        end
        set(haxes,'XLim',xlim)
        set(haxes,'YLim',ylim)
        %test whther zoom out is operating (to inactivate AxedAta
        if ~isfield(AxeData,'CurrentXLim')|| ~isequal(xlim,AxeData.CurrentXLim)
            AxeData.CurrentXLim=xlim;%
        end
    end
    %if isfield(AxeData,'LimEditBox')&& AxeData.LimEditBox% update display of the GUI containing the axis (uvmat or view_field)
    if testsubplot
        set(AxeData.CurrentRectZoom,'Position',[xlim(1) ylim(1) xlim(2)-xlim(1) ylim(2)-ylim(1)])
    else
        set(hhcurrentfig.num_MinX,'String',num2str(xlim(1)))
        set(hhcurrentfig.num_MaxX,'String',num2str(xlim(2)))
        set(hhcurrentfig.num_MinY,'String',num2str(ylim(1)))
        set(hhcurrentfig.num_MaxY,'String',num2str(ylim(2)))
    end
end

%% editing calibration point
if ~CheckZoom && isfield(AxeData,'Drawing') && isequal(AxeData.Drawing,'calibration')
    h_geometry_calib=findobj(allchild(0),'tag','geometry_calib'); %find the geomterty_calib GUI
    if ~isempty(h_geometry_calib)
        hh_geometry_calib=guidata(h_geometry_calib);
        edit_test=get(hh_geometry_calib.CheckEnableMouse,'Value');
        hh=findobj(hcurrentaxes,'tag','calib_points');%look for handle of calibration points
        if ~isempty(hh) && edit_test
            index_point=get(hh,'UserData');
            set(hh,'UserData',[])%remove edit mode
            h_ListCoord=hh_geometry_calib.ListCoord; %handles of the coordinate list
            Coord=get(h_ListCoord,'Data');
            Coord(index_point,4)=xy(1,1);
            Coord(index_point,5)=xy(1,2);
            set(h_ListCoord,'Data',Coord)
            set(hh,'XData',Coord(:,4))
            set(hh,'YData',Coord(:,5))
        end
    end
end

%% finalising ruler
if test_ruler && ~isempty(xy)
    %set(hhuvmat.MenuRuler,'checked','off')%desable the ruler option in uvmat
    xy=get(hcurrentaxes,'CurrentPoint');% get the current mouse coordinates
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


%% update 
if test_drawing==0
        AxeData.Drawing='off';%stop current drawing action
end
set(hcurrentaxes,'UserData',AxeData);
if ~isempty(huvmat)
    set(huvmat,'UserData',UvData);
end

%------------------------------------------------------------------------    
% --- 'close_fig': function  activated when a zoom figure is closed
%------------------------------------------------------------------------
function close_fig(ggg,eventdata,hparent)

hfig=get(get(hparent,'parent'),'parent');
hbutton=findobj(hfig,'Tag','CheckZoomFig');
if ~isempty(hbutton)
    set(hbutton,'Value',0)% desactivate the zoom fig option
end
delete(hparent)  % delete the rectangle showing the zoom graph in the parent fig

