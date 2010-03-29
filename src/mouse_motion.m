%'mouse_motion': permanently called by mouse motion over a figure (Callback for 'WindowButtonMotionFcn' of the figure)
%-----------------------------------------------------------------------
%
% function mouse_motion(hObject,eventdata,handles)
% activated by the command:
% set(hObject,'WindowButtonMotionFcn',{'mouse_motion',handles})
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

function mouse_motion(hObject,eventdata,handles)
if ~exist('handles','var')
    return
end
test_draw=0;
test_create=0;%default
test_object=0; %default
test_edit=isfield(handles,'edit') && get(handles.edit,'Value');% edit test for mouse shap: an arrow
test_zoom_draw=0; %default
test_ruler=0;
huvmat=findobj(allchild(0),'Name','uvmat');%find the uvmat interface handle
if ~isempty(huvmat)
    UvData=get(huvmat,'UserData');
    test_ruler=isfield(UvData,'MouseAction') && isequal(UvData.MouseAction,'ruler');
end


%find the current axe 'haxes' and display the current mouse position or uicontrol tag
text_displ_1='';
text_displ_2='';
text_displ_3='';
text_displ_4='';

AxeData=[];%default
mouse=[];
xy=[];%default

pointershape='arrow';% default pointer is an arrow 
currentfig=hObject;
xy_fig=get(currentfig,'CurrentPoint');% current point of the current figure (gcbo)
hchild=get(currentfig,'Children');%handles of all objects in the current figure

% loop on all the objects in the current figure and detect whether the mouse is over a plot  axes
haxes=[];
for ichild=1:length(hchild)
    obj_pos=get(hchild(ichild),'Position');%position of the object
    if xy_fig(1) >=obj_pos(1) & xy_fig(2) >= obj_pos(2)& xy_fig(1) <=obj_pos(1)+obj_pos(3) & xy_fig(2) <= obj_pos(2)+obj_pos(4);
        htype=get(hchild(ichild),'Type');%type of the crrent child
        %if the mouse is over an axis, look at the data
        if isequal(htype,'axes')
            haxes=hchild(ichild);
            xy=get(haxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
            mouse.X=xy(1,1);
            mouse.Y=xy(1,2);
            u_mouse=[];
            v_mouse=[];
            w_mouse=[];
            A_mouse=[];
            c_text=[];
            f_text=[];
            ff_text=[];     
            ivec=[];
            AxeData=get(haxes,'UserData');% data attached to the axis
            if isfield(AxeData,'Drawing')&& ~isempty(AxeData.Drawing) 
                test_draw=~isequal(AxeData.Drawing,'off');
            end
            test_zoom_draw=test_draw && isequal(AxeData.Drawing,'zoom')&& isfield(AxeData,'CurrentOrigin') && isequal(get(gcf,'SelectionType'),'normal');
            test_object=test_draw && isfield(AxeData,'CurrentObject') && ~isempty(AxeData.CurrentObject) && ishandle(AxeData.CurrentObject);       
             if ~test_edit && ~test_zoom_draw && ~test_ruler
                 pointershape='crosshair';%set pointer with cross shape (default when mouse is over an axis)
             end
            if isfield(AxeData,'X') && isfield(AxeData,'Y') && isfield(AxeData,'Mesh')% test on the existence of a vector field in the current axis
                if ~isempty(AxeData.Mesh)
                    flag_vec=(AxeData.X<(xy(1,1)+AxeData.Mesh/3) & AxeData.X>(xy(1,1)-AxeData.Mesh/3)) & ...%flagx=1 for the vectors with x position selected by the mouse
                          (AxeData.Y<(xy(1,2)+AxeData.Mesh/3) & AxeData.Y>(xy(1,2)-AxeData.Mesh/3));%f
                    ivec=find(flag_vec,1);% search the (first) selected vector index ivec
                    hhh=findobj(haxes,'Tag','vector_marker');
                    if ~isempty(ivec)
                        if ~test_object % mark the vectors with a circle in the absence of other operations
                            if  ~test_create && ~test_edit && ~test_ruler
                                pointershape='arrow'; %mouse indicates  the detection of a vector
                                if isempty(hhh)
                                     hstack=findobj(allchild(0),'Type','figure');%current stack order of figures in matlab
                                    axes(haxes)
                                    rectangle('Curvature',[1 1],...
                      'Position',[AxeData.X(ivec)-AxeData.Mesh/2 AxeData.Y(ivec)-AxeData.Mesh/2 AxeData.Mesh AxeData.Mesh],'EdgeColor','m',...
                      'LineStyle','-','Tag','vector_marker');
                                    set(0,'Children',hstack);%put back the initial figure stack after plot creation
                                else
                                    set(hhh,'Position',[AxeData.X(ivec)-AxeData.Mesh/2 AxeData.Y(ivec)-AxeData.Mesh/2 AxeData.Mesh AxeData.Mesh])
                                end
                            end
                        end
                        mouse.X=AxeData.X(ivec);
                        mouse.Y=AxeData.Y(ivec);
                        u_mouse=AxeData.U(ivec);%displacement
                        v_mouse=AxeData.V(ivec);
                        w_mouse=0; %default
                        if isfield(AxeData,'W') & length(AxeData.W)>=ivec
                            w_text=[',  w=' num2str(AxeData.W(ivec),3)];
                        else
                            w_text='';
                        end
                        if ~isfield(AxeData,'CName')
                            AxeData.CName='C';%REVOIR
                        end
                        c_text=[', ' AxeData.CName '=' num2str(AxeData.C(ivec),3)];
                        if isfield(AxeData,'F')&length(AxeData.F)>=ivec
                            f_text=[',  f=' num2str(AxeData.F(ivec),3)];
                        else
                            f_text='';
                        end
                        if isfield(AxeData,'FF')&length(AxeData.FF)>=ivec
                            ff_text=[',  ff=' num2str(AxeData.FF(ivec),3)];
                        else
                            ff_text='';
                        end
                    else
                        if ~isempty(hhh)
                            delete(hhh)
                        end
                    end
                end
            end
            if isfield(AxeData,'Z')
                mouse.Z=AxeData.Z; %generaliser au cas avec angle
            end
            if isfield(AxeData,'ObjectCoord') & size(AxeData.ObjectCoord,2)==3
                mouse.Z=AxeData.ObjectCoord(1,3); %generaliser au cas avec angle
            end
            testscal= isfield(AxeData,'A')& isfield(AxeData,'AX')& isfield(AxeData,'AY');%test the existence of an image (or scalar represented by an image)
               if testscal
                   testscal=~isempty(AxeData.A)&~isempty(AxeData.AX)& ~isempty(AxeData.AY);
               end
            if testscal%test the existence of an image (or scalar represented by an image)
                nxy=size(AxeData.A);
                MaxAY=max(AxeData.AY(1),AxeData.AY(end));
                MinAY=min(AxeData.AY(1),AxeData.AY(end));
                if (xy(1,1)>AxeData.AX(1))&(xy(1,1)<AxeData.AX(end))&(xy(1,2)<MaxAY)&(xy(1,2)>MinAY)
                    indx0=1+round((nxy(2)-1)*(xy(1,1)-AxeData.AX(1))/(AxeData.AX(end)-AxeData.AX(1)));% index x of pixel
                    indy0=1+round((nxy(1)-1)*(xy(1,2)-AxeData.AY(1))/(AxeData.AY(end)-AxeData.AY(1)));% index y of pixel
                    if indx0>=1 & indx0<=nxy(2) & indy0>=1 & indy0<=nxy(1)
                        A_mouse=AxeData.A(indy0,indx0,:);
                    end
                end
            end
            %coordinate transform if proj_coord differs from menu_coord 
            if isfield(AxeData,'CoordType')
                  mouse.CoordType=AxeData.CoordType;
            end
            if isfield(AxeData,'CoordUnit')
                  mouse.CoordUnit=AxeData.CoordUnit;
            end 
            if isfield(mouse,'CoordType') 
                if isequal(mouse.CoordType,'px')
                    mouse.CoordUnit='px';
                end
            else
                mouse.CoordUnit='';%default      
            end      
            text_displ_1=['x=' num2str(mouse.X,4) ',y=' num2str(mouse.Y,4)];
            if isfield(mouse,'Z')&~isempty(mouse.Z)
                text_displ_1=[text_displ_1 ',z=' num2str(mouse.Z,3)];
            end
            if isfield(mouse,'CoordUnit')
                 text_displ_1=[text_displ_1 ' ' mouse.CoordUnit];
            end
            if ~isempty(ivec)
                text_displ_4=['vec#=' num2str(ivec)];
            end
            if ~isempty(u_mouse)
                text_displ_3=['u=' num2str(u_mouse,3) ',v=' num2str(v_mouse,3) w_text ];
                if  isfield(mouse,'CoordUnit')
                    if isequal(mouse.CoordUnit,'px')
                        text_displ_3=[text_displ_3 '  ' mouse.CoordUnit];
                    elseif isfield(AxeData,'TimeUnit') 
                        text_displ_3=[text_displ_3 '  ' mouse.CoordUnit '/' AxeData.TimeUnit];
                    end
                end
                text_displ_4=[text_displ_4 c_text f_text ff_text];
            end
           
            if ~isempty(A_mouse)
                text_displ_2=['A=' num2str(double(A_mouse)) ',i='  num2str(indx0) ',j=' num2str(indy0)];
            end
        elseif isequal(htype,'uicontrol') && isequal(get(hchild(ichild),'Visible'),'on')&& ~isequal(get(hchild(ichild),'Style'),'frame')
            text_displ_1=get(hchild(ichild),'Tag');
        end
    end
end
set(handles.text_display_1,'String',text_displ_1);
set(handles.text_display_2,'String',text_displ_2);
set(handles.text_display_3,'String',text_displ_3);
set(handles.text_display_4,'String',text_displ_4);
if ~test_draw
    return 
end
% At this stage  if no drawing  operation is done


%%%%%%%%%%%%%
%draw a zoom rectangle if no object creation is selected
if test_zoom_draw 
   xy_rect=AxeData.CurrentOrigin;
   if ~isempty(xy_rect) 
        rect(1)=min(xy(1,1),xy_rect(1));%origin rectangle, x coordinate
        rect(2)=min(xy(1,2),xy_rect(2));%origin rectangle, y coordinate
        rect(3)=abs(xy(1,1)-xy_rect(1));%rectangle width
        rect(4)=abs(xy(1,2)-xy_rect(2));%rectangle height
        if rect(3)>0 & rect(4)>0
            if isfield(AxeData,'CurrentRectZoom')& ishandle(AxeData.CurrentRectZoom)
                set(AxeData.CurrentRectZoom,'Position',rect);%update the rectangle position
            else
                AxeData.CurrentRectZoom=rectangle('Position',rect,'LineStyle',':','Tag','rect_zoom');
                set(haxes,'UserData',AxeData)
            end
        end
   end
    pointershape='arrow';
end

%%%%%%%%%%%%%%%%%
%create or modify an object

if ~isempty(huvmat) && test_object
    PlotData=get(AxeData.CurrentObject,'UserData');
    huvmat=findobj(allchild(0),'Name','uvmat');%find the uvmat interface handle
    if ~isempty(huvmat)
        UvData=get(huvmat,'UserData');
        if ~isfield(PlotData,'IndexObj')
             return
        end
        ObjectData=UvData.Object{PlotData.IndexObj};
        XYData=AxeData.CurrentOrigin;
        if isequal(AxeData.Drawing,'create') && isfield(AxeData,'CurrentOrigin') && ~isempty(AxeData.CurrentOrigin)
           if isequal(ObjectData.Style,'line')|isequal(ObjectData.Style,'polyline')|isequal(ObjectData.Style,'polygon')|isequal(ObjectData.Style,'points')
              xy(1,3)=0;
              ObjectData.Coord=[ObjectData.Coord ;xy(1,:)];
             % ObjectData.Coord(end,:)=xy(1,:);
           elseif isequal(ObjectData.Style,'rectangle')|isequal(ObjectData.Style,'ellipse')|isequal(ObjectData.Style,'volume')
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
            plot_object(ObjectData,[],AxeData.CurrentObject,'m');
            pointershape='crosshair';
        elseif  isequal(AxeData.Drawing,'translate')
            DX=xy(1,1)-XYData(1);%translation from initial position
            DY=xy(1,2)-XYData(2);
            ObjectData.Coord(:,1)=ObjectData.Coord(:,1)+DX;
            ObjectData.Coord(:,2)=ObjectData.Coord(:,2)+DY;
            plot_object(ObjectData,[],AxeData.CurrentObject,'m');
            pointershape='fleur';
        elseif  isequal(AxeData.Drawing,'deform')
            ind_move=AxeData.CurrentIndex;
            ObjectData.Coord(ind_move,1)=xy(1,1);
            ObjectData.Coord(ind_move,2)=xy(1,2);
            plot_object(ObjectData,[],AxeData.CurrentObject,'m');
            pointershape='circle';
        end
    end
end    

% detect calibration points if the GUI geometry_calib is opened
h_geometry_calib=findobj(allchild(0),'Name','geometry_calib'); %find the geomterty_calib GUI
if ~test_zoom_draw && ~isempty(h_geometry_calib)
    pointershape='crosshair';%default for geometry_calib: ready to create new points
    hh_geometry_calib=guidata(h_geometry_calib);
    if get(hh_geometry_calib.edit_append,'Value')  && ~isempty(xy)
        h_ListCoord=hh_geometry_calib.ListCoord; %findobj(h_geometry_calib,'Tag','ListCoord');
        Coord=get(h_ListCoord,'String');
        data=read_geometry_calib(Coord);%transform char cell to numbers
        if size(data.Coord,2)>=5
            XCoord=(data.Coord(:,4));
            YCoord=(data.Coord(:,5));
            xy=get(haxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
            if ~isempty(xy)
                ind_range=10;
                index_point=find((XCoord<xy(1,1)+ind_range) & (XCoord>xy(1,1)-ind_range) & ...%flagx=1 for the vectors with x position selected by the mouse
                              (YCoord<xy(1,2)+ind_range) & (YCoord>xy(1,2)-ind_range),1);%find the first calibration point in the neighborhood of the mouse
                if ~isempty(index_point)
                    pointershape='arrow';% default pointer is an arrow 
                    set(h_ListCoord,'Value',index_point)%mrk the point on the GUI geometry_calib 
                    hh=findobj('Tag','calib_points');%look for handle of calibration points 
                    if ~isempty(hh) && strcmp(get(hh,'UserData'),'edit_mode')
                        XCoord(index_point)=xy(1,1);
                        YCoord(index_point)=xy(1,2);
                        set(hh,'XData',XCoord)
                        set(hh,'YData',YCoord)
                    end
                    hhh=findobj('Tag','calib_marker');%look for handle of point marker (circle)
                    if ~isempty(hhh)
                        set(hhh,'Position',[XCoord(index_point)-ind_range/2 YCoord(index_point)-ind_range/2 ind_range ind_range])
%                         set(hhh,'XData',XCoord(index_point))
%                         set(hhh,'YData',YCoord(index_point))
                    end
                end          
            end
        end
    end
end

%draw ruler
if test_ruler && isequal(AxeData.Drawing,'ruler')
           if isfield(UvData,'RulerHandle')
               pointershape='crosshair';
                RulerCoord=[UvData.RulerCoord ;xy(1,1:2)];
                set(UvData.RulerHandle,'XData',RulerCoord(:,1));
                set(UvData.RulerHandle,'YData',RulerCoord(:,2));
           end
end
set(currentfig,'Pointer',pointershape);
