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
FigData=get(hObject,'UserData');
if ishandle(FigData)% case of a zoom plot, the handle of the parent rectangle is stored in UserData, its parent is the plotting axes of the rectangle
    CurrentFig=get(get(FigData,'parent'),'parent');
else
    CurrentFig=hObject;%usual plot
end
hhCurrentFig=guidata(CurrentFig);%handles of the elements in the GUI containing the current figure (uvmat or view_field)
test_zoom=get(hhCurrentFig.CheckZoom,'Value');%test for zoom activated on the current figure
test_draw=0;%test for mouse drawing of object, =0 by default
test_object=0; %test for object editing or creation 
test_edit_object=0;% edit test for mouse shap: an arrow
test_zoom_draw=0; % test for zoom drawing 
test_ruler=0;%test for active ruler 
huvmat=findobj(allchild(0),'tag','uvmat');%find the uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);%handles of the elements in uvma
    test_edit_object=get(hhuvmat.edit_object,'Value');
    test_ruler=isequal(get(hhuvmat.MenuRuler,'checked'),'on');
end
test_piv=0;
if isfield(FigData,'CivHandle')
    if ~ishandle(FigData.CivHandle)
        delete(hObject)
        return
    end
    hhciv=guidata(FigData.CivHandle);
    test_piv=1;
end

%find the current axe 'CurrentAxes' and display the current mouse position or uicontrol tag
text_displ_1='';
text_displ_2='';
text_displ_3='';
text_displ_4='';

AxeData=[];%default
mouse=[];
xy=[];%default

pointershape='arrow';% default pointer is an arrow 

xy_fig=get(hObject,'CurrentPoint');% current point of the current figure (gcbo)
hchild=get(hObject,'Children');%handles of all objects in the current figure

%% loop on all the objects in the current figure, detect whether the mouse is over a plot  axes
CurrentAxes=[];
for ichild=1:length(hchild)
    obj_pos=get(hchild(ichild),'Position');
    if numel(obj_pos)~=4% for some versions of matlab a uicontextmenu appears
        continue
    end%position of the object
    if xy_fig(1) >=obj_pos(1) && xy_fig(2) >= obj_pos(2)&& xy_fig(1) <=obj_pos(1)+obj_pos(3) && xy_fig(2) <= obj_pos(2)+obj_pos(4);
        htype=get(hchild(ichild),'Type');%type of the crrent child
        %if the mouse is over an axis, look at the data
        if strcmp(htype,'axes')
            CurrentAxes=hchild(ichild);
            xy=get(CurrentAxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
            AxeData=get(CurrentAxes,'UserData');% data attached to the axis
            if isfield(AxeData,'Drawing')&& ~isempty(AxeData.Drawing)
                test_draw=~isequal(AxeData.Drawing,'off');%=1 if mouse drawing of object is active
            end
            test_zoom_draw=test_draw && isequal(AxeData.Drawing,'zoom')&& isfield(AxeData,'CurrentOrigin') && isequal(get(gcf,'SelectionType'),'normal');
            test_object=test_draw && isfield(AxeData,'CurrentObject') && ~isempty(AxeData.CurrentObject) && ishandle(AxeData.CurrentObject);
            if ~test_edit_object && ~test_zoom_draw && ~test_ruler
                pointershape='crosshair';%set pointer with cross shape (default when mouse is over an axis)
            end
            FigData=get(CurrentFig,'UserData');
            tagaxes=get(CurrentAxes,'tag');
            if isfield(FigData,tagaxes)
                Field=FigData.(tagaxes);
                if isfield(Field,'ListVarName')
                    [CellVarIndex,NbDim,VarType]=find_field_cells(Field);%analyse the physical fields contained in Field
                    text_displ_1='';
                    text_displ_2='';
                    text_displ_3='';
                    text_displ_4='';
                    ivec=[];
                    xName='';
                    z=[];
                    for icell=1:numel(CellVarIndex)%look for all physical fields
                        if NbDim(icell)>=2 % select 2D field
                            if  isfield(Field,'Mesh') && ~isempty(Field.Mesh)&& ~isempty(VarType{icell}.coord_x) && ~isempty(VarType{icell}.coord_y)%case of unstructured data
                                eval(['X=Field.' Field.ListVarName{VarType{icell}.coord_x} ';'])
                                eval(['Y=Field.' Field.ListVarName{VarType{icell}.coord_y} ';'])
                                flag_vec=(X<(xy(1,1)+Field.Mesh/3) & X>(xy(1,1)-Field.Mesh/3)) & ...%flagx=1 for the vectors with x position selected by the mouse
                                    (Y<(xy(1,2)+Field.Mesh/3) & Y>(xy(1,2)-Field.Mesh/3));%f
                                ivec=find(flag_vec,1);% search the (first) selected vector index ivec
                                hhh=findobj(CurrentAxes,'Tag','vector_marker');
                                if ~isempty(ivec)
                                    % mark the vectors with a circle in the absence of other operations
                                    if ~test_object && ~test_edit_object && ~test_ruler
                                        pointershape='arrow'; %mouse indicates  the detection of a vector
                                        if isempty(hhh)
                                            set(0,'CurrentFigure',CurrentFig)
                                            set(CurrentFig,'CurrentAxes',CurrentAxes)
                                            rectangle('Curvature',[1 1],...
                                                'Position',[X(ivec)-Field.Mesh/2 Y(ivec)-Field.Mesh/2 Field.Mesh Field.Mesh],'EdgeColor','m',...
                                                'LineStyle','-','Tag','vector_marker');
                                        else
                                            set(hhh,'Visible','on')
                                            set(hhh,'Position',[X(ivec)-Field.Mesh/2 Y(ivec)-Field.Mesh/2 Field.Mesh Field.Mesh])
                                        end
                                    end
                                    %display the field values
                                    for ivar=1:numel(CellVarIndex{icell})
                                        VarName=Field.ListVarName{CellVarIndex{icell}(ivar)};
                                        eval(['VarVal=Field.' VarName '(ivec);'])
                                        var_text=[VarName '=' num2str(VarVal,3) ','];
                                        if isequal(ivar,VarType{icell}.coord_x)||isequal(ivar,VarType{icell}.coord_y)||isequal(ivar,VarType{icell}.coord_z)
                                            text_displ_1=[text_displ_1 var_text];
                                        elseif isequal(ivar,VarType{icell}.vector_x)||isequal(ivar,VarType{icell}.vector_y)||isequal(ivar,VarType{icell}.vector_z)
                                            text_displ_3=[text_displ_3 var_text];
                                        else
                                            text_displ_4=[text_displ_4 var_text];
                                        end
                                    end
                                else
                                    if ~isempty(hhh)
                                        set(hhh,'Visible','off')
                                    end
                                end
                            elseif numel(VarType{icell}.coord) >=2 & VarType{icell}.coord > 0 %structured coordinates
                                yName=Field.ListVarName{VarType{icell}.coord(1)};
                                xName=Field.ListVarName{VarType{icell}.coord(2)};
                                 eval(['y=Field.' yName ';'])
                                 eval(['x=Field.' xName ';'])
                                VarName=Field.ListVarName{CellVarIndex{icell}(1)};
                                eval(['nxy=size(Field.' VarName ');']);
                                MaxAY=max(y(1),y(end)); %#ok<COLND>
                                MinAY=min(y(1),y(end)); %#ok<COLND>
                                if (xy(1,1)>x(1))&(xy(1,1)<x(end))&(xy(1,2)<MaxAY)&(xy(1,2)>MinAY) %#ok<COLND>
                                    indx0=1+round((nxy(2)-1)*(xy(1,1)-x(1))/(x(end)-x(1)));%#ok<COLND> % index x of pixel
                                    indy0=1+round((nxy(1)-1)*(xy(1,2)-y(1))/(y(end)-y(1)));%#ok<COLND> % index y of pixel
                                    if indx0>=1 & indx0<=nxy(2) & indy0>=1 & indy0<=nxy(1)
                                        text_displ_2=['i='  num2str(indx0) ',j=' num2str(indy0) ','];
                                        for ivar=1:numel(CellVarIndex{icell})
                                            VarName=Field.ListVarName{CellVarIndex{icell}(ivar)};
                                            eval(['VarVal=Field.' VarName '(indy0,indx0,:);'])
                                            var_text=[VarName '=' num2str(VarVal) ','];
                                            text_displ_2=[text_displ_2 var_text];
                                        end
                                    end
                                end
                            end
                        end
                    end
              % display the current x,y coordinates in the absence of detected vector
                    if isempty(ivec)
                        if isempty(xName)
                            xName='x';
                            yName='y';
                        end
                        text_displ_1=[xName '=' num2str(xy(1,1),3) ', ' yName '=' num2str(xy(1,2),3) ','];
                    end
              %display the z coordinate if defined by the projection plane
                    if isfield(Field,'PlaneCoord') 
%                             ZIndex=Field.ZIndex;
                        if size(Field.PlaneCoord)>=[1 3]
                            z=Field.PlaneCoord(1,3);
                            if isfield(Field,'PlaneAngle')&&~isequal(Field.PlaneAngle,[0 0 0])
                                om=norm(Field.PlaneAngle);%norm of rotation angle in radians
                                OmAxis=Field.PlaneAngle/om; %unit vector marking the rotation axis
                                cos_om=cos(pi*om/180);
                                sin_om=sin(pi*om/180);
                                coeff=OmAxis(3)*(1-cos_om);
                                norm_plane(1)=OmAxis(1)*coeff+OmAxis(2)*sin_om;
                                norm_plane(2)=OmAxis(2)*coeff-OmAxis(1)*sin_om;
                                norm_plane(3)=OmAxis(3)*coeff+cos_om;
                                Z0=norm_plane*Field.PlaneCoord'/norm_plane(3);
                                z=Z0-norm_plane(1)*xy(1,1)/norm_plane(3)-norm_plane(2)*xy(1,2)/norm_plane(3);
                            end
                        end
                    end
                    if ~isempty(z)
                        text_displ_1=[text_displ_1 ' z=' num2str(z,3)];
                    end
               % case of PIV correlation display
                    if test_piv
                        par=read_GUI(hhciv.Civ1);
                        [dd,ind_pt]=min(abs(Field.X-xy(1,1))+abs(Field.Y-xy(1,2)));
                        xround=Field.X(ind_pt);
                        yround=Field.Y(ind_pt);
%                         par.Grid=[xround size(Field.A,1)-yround+1];
                        par.Grid=[xround yround];
                        % mark the correlation box with a rectangle
                        par.ImageA=Field.A;
                        par.ImageB=Field.B;
                        par.ImageHeight=size(par.ImageA,1);
                        par.ImageWidth=size(par.ImageA,2);
                        Param.Civ1=par;
                        ibx2=floor((par.CorrBoxSize(1)-1)/2);
                        iby2=floor((par.CorrBoxSize(2)-1)/2);
                        isx2=floor((par.SearchBoxSize(1)-1)/2);
                        isy2=floor((par.SearchBoxSize(2)-1)/2);
                        shiftx=par.SearchBoxShift(1);
                        shifty=par.SearchBoxShift(2);     
                        hhh=findobj(CurrentAxes,'Tag','PIV_box_marker');
                        hhhh=findobj(CurrentAxes,'Tag','PIV_search_marker');
                        if isempty(hhh)
                            set(0,'CurrentFigure',CurrentFig)
                            set(CurrentFig,'CurrentAxes',CurrentAxes)
                            rectangle('Curvature',[0 0],...
                                'Position',[xround-ibx2 yround-iby2 2*ibx2 2*iby2],'EdgeColor','m',...
                                'LineStyle','-','Tag','PIV_box_marker');
                            rectangle('Curvature',[0 0],...
                                'Position',[xround-isx2+shiftx yround-isy2+shifty 2*isx2 2*isy2],'EdgeColor','m',...
                                'LineStyle','- -','Tag','PIV_search_marker');
                        else
                            set(hhh,'Position',[xround-ibx2 yround-iby2 2*ibx2 2*iby2])
                            set(hhhh,'Position',[xround-isx2+shiftx yround-isy2+shifty 2*isx2 2*isy2])
                        end
                        [Data,errormsg,result_conv]= civ_matlab(Param);
                        if ~isempty(errormsg)
                            text_displ_4=errormsg;
                        else
                            rangx(1)=-(isx2-ibx2)+shiftx;
                            rangx(2)=isx2-ibx2+shiftx;
                            rangy(1)=-(isy2-iby2)-shifty;
                            rangy(2)=(isy2-iby2)-shifty;
                            hcorr=[];
                            if isfield(AxeData,'CurrentCorrImage')
                                hcorr=AxeData.CurrentCorrImage;
                                if ~ishandle(hcorr)
                                    hcorr=[];
                                end
                            end
                            if isempty(hcorr)
                                corrfig=findobj(allchild(0),'tag','corrfig');
                                if ~isempty(corrfig)
                                    set(0,'CurrentFigure',corrfig(1))         
                                    AxeData.CurrentCorrImage=imagesc(rangx,-rangy,result_conv,[0 1]);
                                    AxeData.CurrentVector=line([0 Data.Civ1_U],[0 Data.Civ1_V],'Tag','vector');
                                   AxeData.TitleHandle=title(num2str(par.Grid));
                                    colorbar
                                    set(CurrentAxes,'UserData',AxeData)
                                    set(get(AxeData.CurrentCorrImage,'parent'),'YDir','normal')
                                end
                            else
                                set(AxeData.CurrentCorrImage,'CData',result_conv)
                                set(AxeData.CurrentCorrImage,'XData',rangx)
                                set(AxeData.CurrentCorrImage,'YData',-rangy)
                                set(AxeData.CurrentVector,'XData',[0 Data.Civ1_U],'YData',[0 Data.Civ1_V])
                                set(AxeData.TitleHandle,'String',num2str(par.Grid))
                            end
                        end
                    end
                end
            end
        end
    end
end
if ~isempty(text_displ_1)
set(handles.text_display,'String',[{text_displ_1};{text_displ_2};{text_displ_3};{text_displ_4}])
else
   set(handles.text_display,'String',get(handles.text_display,'UserData'))
end

%%%%%%%%%%%%%
%% draw a zoom rectangle if no object creation is selected
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
                set(CurrentAxes,'UserData',AxeData)
            end
        end
   end
    pointershape='arrow';
end

%%%%%%%%%%%%%%%%%
%% create or modify an object
if ~isempty(huvmat) && test_object
    UvData=get(huvmat,'UserData');
    PlotData=get(AxeData.CurrentObject,'UserData');
    if ~isfield(PlotData,'IndexObj')
        return
    end
    ObjectData=UvData.Object{PlotData.IndexObj};
    ProjObject=[];% object (plane) whose projection is represented on the current axes
    if isequal(hObject,huvmat)% if the mouse ifs over the GUI uvmat
        ProjObject=UvData.Object{get(hhuvmat.ListObject_1,'Value')};
    else
        ProjObject=UvData.Object{get(hhuvmat.ListObject,'Value')};
    end
    XYData=AxeData.CurrentOrigin;
    if isequal(AxeData.Drawing,'create') && isfield(AxeData,'CurrentOrigin') && ~isempty(AxeData.CurrentOrigin)
        if strcmp(ObjectData.Type,'line')||strcmp(ObjectData.Type,'polyline')||strcmp(ObjectData.Type,'polygon')||strcmp(ObjectData.Type,'points')
            ObjectData.Coord=[ObjectData.Coord ;xy(1,1:2)];
            % ObjectData.Coord(end,:)=xy(1,:);
        elseif strcmp(ObjectData.Type,'rectangle')||strcmp(ObjectData.Type,'ellipse')||strcmp(ObjectData.Type,'volume')
            ObjectData.Coord(1,1)=(xy(1,1)+XYData(1))/2;%origin rectangle, x coordinate
            ObjectData.Coord(1,2)=(xy(1,2)+XYData(2))/2;
            ObjectData.RangeX=abs(xy(1,1)-XYData(1))/2;%rectangle width
            ObjectData.RangeY=abs(xy(1,2)-XYData(2))/2;%rectangle height
        elseif isequal(ObjectData.Type,'plane') %case of 'plane'
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
        plot_object(ObjectData,ProjObject,AxeData.CurrentObject,'m');
        pointershape='crosshair';
    elseif  isequal(AxeData.Drawing,'translate')
        DX=xy(1,1)-XYData(1);%translation from initial position
        DY=xy(1,2)-XYData(2);
        ObjectData.Coord(:,1)=ObjectData.Coord(:,1)+DX;
        ObjectData.Coord(:,2)=ObjectData.Coord(:,2)+DY;
        plot_object(ObjectData,ProjObject,AxeData.CurrentObject,'m');
        pointershape='fleur';
    elseif  isequal(AxeData.Drawing,'deform')
        ind_move=AxeData.CurrentIndex;
        ObjectData.Coord(ind_move,1)=xy(1,1);
        ObjectData.Coord(ind_move,2)=xy(1,2);
        plot_object(ObjectData,ProjObject,AxeData.CurrentObject,'m');
        pointershape='circle';
    end
end

%% detect calibration points if the GUI geometry_calib is opened
h_geometry_calib=findobj(allchild(0),'Name','geometry_calib'); %find the geomterty_calib GUI
if ~test_zoom && ~isempty(h_geometry_calib)
    pointershape='crosshair';%default for geometry_calib: ready to create new points
    hh_geometry_calib=guidata(h_geometry_calib);
    if  ~isempty(xy) && isfield(hh_geometry_calib,'ListCoord')
        h_ListCoord=hh_geometry_calib.ListCoord; %findobj(h_geometry_calib,'Tag','ListCoord');
        Coord=get(h_ListCoord,'String');
        data=read_geometry_calib(Coord);%transform char cell to numbers
        if size(data.Coord,2)>=5
            XCoord=(data.Coord(:,4));
            YCoord=(data.Coord(:,5));
            xy=get(CurrentAxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
            if ~isempty(xy)
                xlim=get(CurrentAxes,'XLim');
                ind_range_x=abs((xlim(2)-xlim(1))/50);
                ylim=get(CurrentAxes,'YLim');
                ind_range_y=abs((ylim(2)-ylim(1))/50);
                ind_range=sqrt(ind_range_x*ind_range_y);
                index_point=find((XCoord<xy(1,1)+ind_range) & (XCoord>xy(1,1)-ind_range) & ...%flagx=1 for the vectors with x position selected by the mouse
                              (YCoord<xy(1,2)+ind_range) & (YCoord>xy(1,2)-ind_range),1);%find the first calibration point in the neighborhood of the mouse
                if ~isempty(index_point)
                    pointershape='arrow';% default pointer is an arrow 
                end
                hh=findobj('Tag','calib_points');%look for handle of calibration points
               if ~isempty(hh) && ~isempty(get(hh,'UserData')) && get(hh_geometry_calib.edit_append,'Value') 
                    index_point=get(hh,'UserData');
                    XCoord(index_point)=xy(1,1);
                    YCoord(index_point)=xy(1,2);
                    set(hh,'XData',XCoord)
                    set(hh,'YData',YCoord)
               end
                if ~isempty(index_point)
                    set(h_ListCoord,'Value',index_point)%mrk the point on the GUI geometry_calib
                    hhh=findobj('Tag','calib_marker');%look for handle of point marker (circle)
                    if ~isempty(hhh)
                        set(hhh,'Position',[XCoord(index_point)-ind_range/2 YCoord(index_point)-ind_range/2 ind_range ind_range])
                    end
                end
            end
        end
    end
end

%% draw ruler
if test_ruler && isfield(AxeData,'Drawing') && isequal(AxeData.Drawing,'ruler')
    if isfield(AxeData,'RulerHandle')
        pointershape='crosshair'; %give  the mouse pointer a cross shape
        RulerCoord=[AxeData.RulerCoord ;xy(1,1:2)]; %coordinates defining the ruler segment
        set(AxeData.RulerHandle,'XData',RulerCoord(:,1));% updtate the x coordinates for the ruler graphic object
        set(AxeData.RulerHandle,'YData',RulerCoord(:,2));% updtate the y coordinates for the ruler graphic object
    end
end

%% update the mouse pointer
set(CurrentFig,'Pointer',pointershape);
