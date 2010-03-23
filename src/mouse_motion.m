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
% if ~isfield(handles, 'mouse_coord')
%     'TEST'
%     return
% end
% if ~ishandle(handles.mouse_coord)
%     return
% end
% proj_coord=get(handles.mouse_coord,'String');
% choice=get(handles.mouse_coord,'Value');
% if ~isempty(proj_coord); proj_coord=proj_coord{choice};else;proj_coord=[];end;
test_create=0;%default
test_edit=0;%default
% if isfield(handles,'VOLUME') % mouse_motion not applied to the uvmat figure, no object creation
%     test_create=get(handles.create,'Value');   
% end
test_edit=isfield(handles,'edit') & get(handles.edit,'Value');% edit test for mouse shap: an arrow
test_zoom=isfield(handles,'zoom')& get(handles.zoom,'Value');% edit test for mouse shap: an arrow 

%find the current axe 'haxes' and display the current mouse position or uicontrol tag
text_displ_1='';
text_displ_2='';
text_displ_3='';
text_displ_4='';

haxes=[];
AxeData=[];%default
mouse=[];

pointershape='arrow';% default pointer is an arrow 

xy_fig=get(gcbo,'CurrentPoint');% current point of the current figure (gcbo)
hchild=get(gcbo,'Children');%handles of all objects in the current figure
currentfig=gcbo;%store gcbo as variable currentfig
% loop on all the objects in the current figure (selected by the last mouse click) 
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
             if ~test_edit && ~test_zoom
                 pointershape='crosshair';%set pointer with cross shape (default when mouse is over an axis)
%                % pointershape='crosshair';%set pointer with cross shape (default over axis)
             end
            if isfield(AxeData,'X') && isfield(AxeData,'Y') && isfield(AxeData,'Mesh')% test on the existence of a vector field in the current axis
                if ~isempty(AxeData.Mesh)
                    flag_vec=(AxeData.X<(xy(1,1)+AxeData.Mesh/3) & AxeData.X>(xy(1,1)-AxeData.Mesh/3)) & ...%flagx=1 for the vectors with x position selected by the mouse
                          (AxeData.Y<(xy(1,2)+AxeData.Mesh/3) & AxeData.Y>(xy(1,2)-AxeData.Mesh/3));%f
                    ivec=find(flag_vec);% search the selected vector index ivec
                    if length(ivec)>0 
                        if ~test_create
                            pointershape='arrow'; %mouse indicates  the detection of a vector
                            hhh=findobj(haxes,'Tag','vector_marker');
                            if isempty(hhh)
                                line(AxeData.X(ivec),AxeData.Y(ivec),'Color','m','Tag','vector_marker','LineStyle','.','Marker','o','MarkerSize',AxeData.Mesh);
                            else
                                set(hhh,'XData',AxeData.X(ivec))
                                set(hhh,'YData',AxeData.Y(ivec))
                            end
                        end
                        ivec=ivec(1);%choice the first selected vector if several are selected
                        mouse.X=AxeData.X(ivec);
                        mouse.Y=AxeData.Y(ivec);
                        u_mouse=AxeData.U(ivec);%displacement
                        v_mouse=AxeData.V(ivec);
                        w_mouse=0; %default
                        if isfield(AxeData,'W')&length(AxeData.W)>=ivec
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

%%%%%%%%%%%%%%%%%
%create or modify an object
huvmat=findobj(allchild(0),'Name','uvmat');%find the uvmat interface handle
if ~isempty(huvmat)
    UvData=get(huvmat,'UserData');
end
if ~isempty(huvmat) & isfield(AxeData,'CurrentObject') & ishandle(AxeData.CurrentObject) & isfield(AxeData,'Drawing') & ~isequal(AxeData.Drawing,'off')
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
%%%%%%%%%%%%%
%draw a rectangle if no object creation is selected
if ~isempty(haxes) & isfield(AxeData,'Drawing')& isequal(AxeData.Drawing,'zoom')& isfield(AxeData,'CurrentOrigin')...
        & isequal(get(gcf,'SelectionType'),'normal')% 
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
end
if test_zoom
    pointershape='arrow';
end

%draw ruler
if ~isempty(huvmat)
    UvData=get(huvmat,'UserData');
    if isfield(UvData,'MouseAction') && isequal(UvData.MouseAction,'ruler')
           if isfield(UvData,'RulerHandle')
                RulerCoord=[UvData.RulerCoord ;xy(1,1:2)];
                set(UvData.RulerHandle,'XData',RulerCoord(:,1));
                set(UvData.RulerHandle,'YData',RulerCoord(:,2));
           end
    end
end
set(currentfig,'Pointer',pointershape);
