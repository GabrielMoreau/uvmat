%'mouse_motion': permanently called by mouse motion over a figure (Callback for 'WindowButtonMotionFcn' of the figure)
%-----------------------------------------------------------------------
%
% function mouse_motion(hObject,eventdata,handles)
% activated by the command:
% set(hObject,'WindowButtonMotionFcn',{'mouse_motion',handles})
% where hObject is the handle of the figure

%=======================================================================
% Copyright 2008-2016, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function mouse_motion(hObject,eventdata,handles)

FigData=get(hObject,'UserData');
if ishandle(FigData)% case of a zoom plot, the handle of the parent rectangle is stored in UserData, its parent is the plotting axes of the rectangle
    hCurrentFig=get(get(FigData,'parent'),'parent');
else
    hCurrentFig=hObject;%usual plot
end
if strcmp(get(hCurrentFig,'Pointer'),'watch')
    return % no action if a calculation is running
end
hhCurrentFig=guidata(hCurrentFig);%handles of the elements in the GUI containing the current figure (uvmat or view_field)
CheckZoom=get(hhCurrentFig.CheckZoom,'Value');% check for zoom on mode
CheckZoomFig=get(hhCurrentFig.CheckZoomFig,'Value');% check for zoom sub fig creation mode
hPlotAxes=hhCurrentFig.PlotAxes';% handles of the main plot axes
AxeData=get(hPlotAxes,'UserData');% data attached to the axis
htext_display(1)=handles.text_display;
if isfield(AxeData,'htext_display')&&ishandle(AxeData.htext_display)
    htext_display(2)=AxeData.htext_display;
end
test_draw=0;%test for mouse drawing of object, =0 by default
if isfield(AxeData,'Drawing')&& ~isempty(AxeData.Drawing)
    test_draw=~isequal(AxeData.Drawing,'off');%=1 if mouse drawing of object is active
end
test_zoom_draw=0;
test_object=0; %test for object editing or creation 
test_create_object=0;
test_edit_object=0;% edit test for mouse shape: an arrow
test_ruler=0;%test for active ruler 
test_transform=0;
huvmat=findobj(allchild(0),'tag','uvmat');%find the uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);%handles of the elements in uvma
    test_create_object=strcmp(get(hhuvmat.MenuObject,'checked'),'on');
    test_edit_object=get(hhuvmat.CheckEditObject,'Value');
    test_ruler=isequal(get(hhuvmat.MenuRuler,'checked'),'on');
    test_transform=~isequal(get(hhuvmat.TransformName,'Value'),1);
end
test_piv=0;
if isfield(FigData,'CivHandle')% look for handle of the civ_input GUI
    if ~ishandle(FigData.CivHandle)
        delete(hObject)
        set(hCurrentFig,'Pointer','arrow');
        return
    end
    hhciv=guidata(FigData.CivHandle);% list of handles in the GUI civ_input
    test_piv=1;
end
%find the current axe 'CurrentAxes' and display the current mouse position or uicontrol tag
text_displ_1='';
text_displ_2='';
text_displ_3='';
text_displ_4='';

% AxeData=[];%default
xy=[];%default
set(hCurrentFig,'Units','normalized')
xy_fig=get(hObject,'CurrentPoint');% current point of the current figure (gcbo)
pointershape='arrow';% default pointer is an arrow 

%% loop on all the objects in the current figure, detect whether the mouse is over a plot  axes
hchildren=get(hObject,'Children');%handles of all objects in the current figure
check_visible=strcmp(get(hchildren,'Visible'),'on');% if visible='on', =0 otherwise
hchildren=hchildren(check_visible); %kkep only the visible children
PosChildren=get(hchildren,'Position');% set of object positions
if iscell(PosChildren)% only one child
    PosLength=cellfun('length',PosChildren);% set of vector lengths for object positions
    hchildren=hchildren(PosLength==4);% keep only objects with position defined by a 4 element vector
    PosChildren=cell2mat(PosChildren(PosLength==4));% convert cells to matrix of positions
end
if size(PosChildren,2)~=4
    set(hCurrentFig,'Pointer','arrow');
    return
end
xy_fig_mat=ones(size(PosChildren,1),1)*xy_fig;% mouse position set to a matrix
check_pos=xy_fig_mat >= PosChildren(:,1:2) & xy_fig_mat <= PosChildren(:,1:2)+PosChildren(:,3:4);% compare object to mouse position
ind_object=find(check_pos(:,1) & check_pos(:,2),1);% select the index of the (first) object under the mouse
hchild=hchildren(ind_object);% corresponding object handle
CurrentAxes=[];

%if the mouse is over an axis, look at the data
htype=get(hchild,'Type');
if strcmp(htype,'axes')
    CurrentAxes=hchild;
    xy=get(CurrentAxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
    test_zoom_draw=test_draw && isequal(AxeData.Drawing,'zoom')&& isfield(AxeData,'CurrentOrigin') && isequal(get(gcf,'SelectionType'),'normal');
    test_object=test_draw && isfield(AxeData,'CurrentObject') && ~isempty(AxeData.CurrentObject) && ishandle(AxeData.CurrentObject);
    if CheckZoom
           pointershape='zoom';
    elseif CheckZoomFig
            pointershape='zoomfig';
    elseif ~test_edit_object  && ~test_ruler 
        if CheckZoom
           pointershape='zoom';
        elseif test_draw|| test_create_object
            pointershape='crosshair';%set pointer with cross shape 
        else
        pointershape='crosshair';%set pointer with large cross (default when mouse is over an axis)
        end
    end
    FigData=get(hCurrentFig,'UserData'); % user data of the current figure
    tagaxes=get(CurrentAxes,'tag'); % tag name of the current axes, for instance PlotAxes
    if isfield(FigData,tagaxes)
        Field=FigData.(tagaxes); % the current field is sought as substructure of FigData with key tagaxes
        if isfield(Field,'ListVarName')
            [CellInfo,NbDimArray]=find_field_cells(Field);%analyse the physical fields contained in Field
            text_displ_1='';
            text_displ_2='';
            text_displ_3='';
            text_displ_4='';
            text_displ_5='';
            ivec=[];
            xName='';
            z=[];
            for icell=1:numel(CellInfo)%look for all physical fields
                if NbDimArray(icell)>=2 % select 2D field
                    if  isfield(Field,'CoordMesh') && ~isempty(Field.CoordMesh)&& strcmp(CellInfo{icell}.CoordType,'scattered')%case of unstructured data
                        X=Field.(Field.ListVarName{CellInfo{icell}.CoordIndex(end)});
                        Y=Field.(Field.ListVarName{CellInfo{icell}.CoordIndex(end-1)});
                        flag_vec=(X<(xy(1,1)+Field.CoordMesh/3) & X>(xy(1,1)-Field.CoordMesh/3)) & ...%flagx=1 for the vectors with x position selected by the mouse
                            (Y<(xy(1,2)+Field.CoordMesh/3) & Y>(xy(1,2)-Field.CoordMesh/3));%f
                        ivec=find(flag_vec,1);% search the (first) selected vector index ivec
                        hhh=findobj(CurrentAxes,'Tag','vector_marker');
                        if ~isempty(ivec)
                            % mark the vectors with a circle in the absence of other operations
                            if ~test_object && ~test_edit_object && ~test_ruler && ~CheckZoomFig
                                pointershape='arrow'; %mouse indicates  the detection of a vector
                                if isempty(hhh)
                                    set(0,'CurrentFigure',hCurrentFig)
                                    set(hCurrentFig,'CurrentAxes',CurrentAxes)
                                    rectangle('Curvature',[1 1],...
                                        'Position',[X(ivec)-Field.CoordMesh/2 Y(ivec)-Field.CoordMesh/2 Field.CoordMesh Field.CoordMesh],'EdgeColor','m',...
                                        'LineStyle','-','Tag','vector_marker');
                                else
                                    set(hhh,'Visible','on')
                                    set(hhh,'Position',[X(ivec)-Field.CoordMesh/2 Y(ivec)-Field.CoordMesh/2 Field.CoordMesh Field.CoordMesh])
                                end
                            end
                            %display the field values
                            for ivar=1:numel(CellInfo{icell}.VarIndex)
                                VarName=Field.ListVarName{CellInfo{icell}.VarIndex(ivar)};
                                VarVal=Field.(VarName)(ivec);
                                var_text=[VarName '=' num2str(VarVal,4) ','];
                                if isequal(ivar,CellInfo{icell}.CoordIndex(end))||isequal(ivar,CellInfo{icell}.CoordIndex(end-1))||isequal(ivar,CellInfo{icell}.CoordIndex(1))
                                    text_displ_1=[text_displ_1 var_text];
                                elseif (isfield(CellInfo{icell},'VarIndex_vector_x') && isequal(ivar,CellInfo{icell}.VarIndex_vector_x))||isequal(ivar,CellInfo{icell}.VarIndex_vector_y)||...
                                        (isfield(CellInfo{icell},'VarIndex_vector_z') && isequal(ivar,CellInfo{icell}.VarIndex_vector_z))
                                    text_displ_4=[text_displ_4 var_text];
                                else
                                    text_displ_5=[text_displ_5 var_text];
                                end
                            end
                        else
                            if ~isempty(hhh)
                                set(hhh,'Visible','off')
                            end
                        end
                    elseif strcmp(CellInfo{icell}.CoordType,'grid') %structured coordinates
                        yName=Field.ListVarName{CellInfo{icell}.CoordIndex(1)};
                        xName=Field.ListVarName{CellInfo{icell}.CoordIndex(2)};
                        y=Field.(yName);
                        x=Field.(xName);
                        VarName=Field.ListVarName{CellInfo{icell}.VarIndex(1)};
                        nxy=size(Field.(VarName));
                        MaxAY=max(y(1),y(end));
                        MinAY=min(y(1),y(end));
                        if (xy(1,1)>x(1))&(xy(1,1)<x(end))&(xy(1,2)<MaxAY)&(xy(1,2)>MinAY)
                            indx0=1+round((nxy(2)-1)*(xy(1,1)-x(1))/(x(end)-x(1))); % index x of pixel
                            indy0=1+round((nxy(1)-1)*(xy(1,2)-y(1))/(y(end)-y(1))); % index y of pixel
                            if indx0>=1 & indx0<=nxy(2) & indy0>=1 & indy0<=nxy(1)
                                text_displ_2=['i='  num2str(indx0) ',j=' num2str(indy0) ','];
                                for ivar=1:numel(CellInfo{icell}.VarIndex)
                                    VarName=Field.ListVarName{CellInfo{icell}.VarIndex(ivar)};
                                    VarVal=Field.(VarName)(indy0,indx0,:);
                                    var_text=[VarName '=' num2str(VarVal) ','];
                                    text_displ_4=[text_displ_4 var_text];
                                end
                            end
                        end
                    end
                end
            end
            % display the current x,y plot coordinates in the absence of detected vector
            if isempty(ivec)
                if isempty(xName)
                    xName='x';
                    yName='y';
                end
                text_displ_1=[xName '=' num2str(xy(1,1),4) ', ' yName '=' num2str(xy(1,2),4) ','];
            end
            %display the original phys x,y,z coordinates if defined by the projection plane
            if isfield(Field,'ProjObjectType') && strcmp(Field.ProjObjectType,'plane') && isfield(Field,'ProjObjectCoord') && length(Field.ProjObjectCoord)>=3
                pos=[xy(1,1) xy(1,2) 0];%coordinates on the graph
                if isfield(Field,'ProjObjectAngle')&&~isequal(Field.ProjObjectAngle,[0 0 0])
                    om=norm(Field.ProjObjectAngle);%norm of rotation angle in radians
                    OmAxis=Field.ProjObjectAngle/om; %unit vector marking the rotation axis
                    cos_om=cos(pi*om/180);
                    sin_om=sin(pi*om/180);
                    pos=[xy(1,1) xy(1,2) 0];
                    pos=cos_om*pos+sin_om*cross(OmAxis,pos)+(1-cos_om)*(OmAxis*pos')*OmAxis;
                end
               pos=pos+Field.ProjObjectCoord;
                text_displ_3=[text_displ_3 'x,y,z=' num2str(pos,4)];
            end
            % case of PIV correlation display
            if test_piv
               [dd,ind_pt]=min(abs(Field.X-xy(1,1))+abs(Field.Y-xy(1,2)));
               if isfield(hhciv,'TestCiv2') && strcmp(get(hhciv.Civ2,'Visible'),'on')&& ...
                                     strcmp(get(hhciv.TestCiv2,'Visible'),'on')&& get(hhciv.TestCiv2,'Value')% if TestCiv2 is activated
                   CivOption='Civ2';
                   Param.CheckCiv1=0;
                   par_civ=read_GUI(hhciv.Civ2);%read the Civ2 panel in civ_input
                   par_civ.Civ1_SubRange=Field.Civ1_SubRange;% get the subranges used for patch
                   par_civ.Civ1_NbCentres=Field.Civ1_NbCentres;% get the nbre of civ1 data points in each subrange
                   par_civ.Civ1_Coord_tps=Field.Civ1_Coord_tps;% get the positions of the centres (Civ1 data)
                   par_civ.Civ1_U_tps=Field.Civ1_U_tps;% get the tps coefficients for spline, U component
                   par_civ.Civ1_V_tps=Field.Civ1_V_tps;% get the tps coefficients for spline, V component
                   par_civ.Civ1_Dt=Field.Civ1_Dt;
                   par_civ.Civ2_Dt=Field.Civ2_Dt;
                   shiftx=Field.ShiftX(ind_pt);% get field info stored in the cuirrent figure
                   shifty=Field.ShiftY(ind_pt);
               else
                   CivOption='Civ1';
                   Param.CheckCiv2=0;
                   par_civ=read_GUI(hhciv.Civ1);%read the Civ1 panel in civ_input
                   shiftx=par_civ.SearchBoxShift(1);
                   shifty=par_civ.SearchBoxShift(2);
               end
                xround=Field.X(ind_pt);
                yround=Field.Y(ind_pt);
                
                % mark the correlation box with a rectangle in view_field
                ibx2=floor((par_civ.CorrBoxSize(1)-1)/2);
                iby2=floor((par_civ.CorrBoxSize(2)-1)/2);
                isx2=floor((par_civ.SearchBoxSize(1)-1)/2);
                isy2=floor((par_civ.SearchBoxSize(2)-1)/2);
                hhh=findobj(CurrentAxes,'Tag','PIV_box_marker');
                hhhh=findobj(CurrentAxes,'Tag','PIV_search_marker');
                if isempty(hhh)
                    set(0,'CurrentFigure',hCurrentFig)
                    set(hCurrentFig,'CurrentAxes',CurrentAxes)
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
                
                % perform the PIV calculation as the single point xround yround
                Param.CheckFix1=0;
                Param.CheckPatch1=0;%desactivate all calculations except Civ2 or Civ1
                Param.Action.RUN=1;
                Param.ActionInput.ListCompareMode='PIV';
                par_civ.ImageA=Field.A;
                par_civ.ImageB=Field.B;
                par_civ.ImageHeight=size(par_civ.ImageA,1);
                par_civ.ImageWidth=size(par_civ.ImageA,2);
                par_civ.Grid=[xround yround];% PIV calculation with a single point 
                Param.ActionInput.(CivOption)=par_civ;      
                [Data,errormsg,result_conv]= civ_series(Param);
                if ~isempty(errormsg)
                    text_displ_5=errormsg;
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
                            AxeData.CurrentCorrImage=imagesc(rangx,-rangy,result_conv,[0 1]);% plot the correlation map, with full colormap from 0 to 1
                            AxeData.CurrentVector=line([0 Data.([CivOption '_U'])],[0 Data.([CivOption '_V'])],'Tag','vector');
                            AxeData.TitleHandle=title(['[x,y]= ' num2str(par_civ.Grid) ' px']);
                            colorbar
                            set(CurrentAxes,'UserData',AxeData)
                            ParentAxe=get(AxeData.CurrentCorrImage,'parent');
                            set(ParentAxe,'YDir','normal')
                             set(ParentAxe,'DataAspectRatio',[1 1 1]); %equal axis scale
                        end
                    else
                        set(AxeData.CurrentCorrImage,'CData',result_conv)
                        set(AxeData.CurrentCorrImage,'XData',rangx)
                        set(AxeData.CurrentCorrImage,'YData',-rangy)
                        ParentAxe=get(AxeData.CurrentCorrImage,'parent');
                        rangx(1)=min(rangx(1),0);
                        rangx(2)=max(rangx(2),0);
                        rangy(2)=max(rangy(2),0);
                        rangy(1)=min(rangy(1),0);
                         set(ParentAxe,'XLim',rangx)
                         set(ParentAxe,'YLim',[-rangy(2) -rangy(1)])
                        set(AxeData.CurrentVector,'XData',[0 Data.([CivOption '_U'])],'YData',[0 Data.([CivOption '_V'])]);
                        set(AxeData.TitleHandle,'String',['[x,y]= ' num2str(par_civ.Grid) ' px'])
                    end
                end
            end
        end
    end
end
if ~isempty(text_displ_1)
    text_displ=[{text_displ_1};{text_displ_2};{text_displ_3};{text_displ_4};{text_displ_5}];
    ind_blank=find(strcmp('',text_displ));
    if ~isempty(ind_blank)
        text_displ(ind_blank)=[];
    end
    %set(handles.text_display,'String',text_displ)
    set(htext_display,'String',text_displ)
else
   %set(handles.text_display,'String',get(handles.text_display,'UserData'))
   set(htext_display,'String',get(handles.text_display,'UserData'))
end

%%%%%%%%%%%%%
%% draw a zoom rectangle if checkZoomFig has been selected
if test_zoom_draw 
   xy_rect=AxeData.CurrentOrigin;% mark the previous position from mouse down
   if ~isempty(xy_rect) 
        rect(1)=min(xy(1,1),xy_rect(1));%origin rectangle, x coordinate
        rect(2)=min(xy(1,2),xy_rect(2));%origin rectangle, y coordinate
        rect(3)=abs(xy(1,1)-xy_rect(1));%rectangle width
        rect(4)=abs(xy(1,2)-xy_rect(2));%rectangle height
        if rect(3)>0 && rect(4)>0
            if isfield(AxeData,'CurrentRectZoom')&& ~isempty(AxeData.CurrentRectZoom) && ishandle(AxeData.CurrentRectZoom)
                set(AxeData.CurrentRectZoom,'Position',rect);%update the rectangle position
            else
                AxeData.CurrentRectZoom=rectangle('Position',rect,'Tag','rect_zoom','EdgeColor','b');
                set(CurrentAxes,'UserData',AxeData)
            end
        end
   end
end

%%%%%%%%%%%%%%%%%
%% create or modify an object
if strcmp(htype,'axes') && ~isempty(huvmat) && test_object
    UvData=get(huvmat,'UserData');
    PlotData=get(AxeData.CurrentObject,'UserData');
    if ~isfield(PlotData,'IndexObj')
        set(hCurrentFig,'Pointer','arrow');
        return
    end
    if numel(UvData.ProjObject)<PlotData.IndexObj
        return
    end
    ObjectData=UvData.ProjObject{PlotData.IndexObj};
    if isequal(hObject,huvmat)% if the mouse ifs over the GUI uvmat
        if numel(UvData.ProjObject)<get(hhuvmat.ListObject_1,'Value')
            return
        end
        ProjObject=UvData.ProjObject{get(hhuvmat.ListObject_1,'Value')};
    else
        if numel(UvData.ProjObject)<get(hhuvmat.ListObject,'Value')
            return
        end
        ProjObject=UvData.ProjObject{get(hhuvmat.ListObject,'Value')};
    end
    XYData=AxeData.CurrentOrigin;
    if isequal(AxeData.Drawing,'create') && isfield(AxeData,'CurrentOrigin') && ~isempty(AxeData.CurrentOrigin)
        switch ObjectData.Type
            case {'line','polyline','polygon','points','plane_z'}
                ObjectData.Coord=[ObjectData.Coord ;xy(1,1:2)];
                % ObjectData.Coord(end,:)=xy(1,:);
            case {'rectangle','ellipse','volume'}
                ObjectData.Coord=(AxeData.CurrentOrigin+xy(1,1:2))/2;% keep only the first point coordinate
                ObjectData.RangeX=abs(ObjectData.Coord(1,1)-xy(1,1));%rectangle width
                ObjectData.RangeY=abs(ObjectData.Coord(1,2)-xy(1,2));%rectangle height
            case 'plane' %case of 'plane'
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
    elseif test_edit_object && isequal(AxeData.Drawing,'translate')
        DX=xy(1,1)-XYData(1);%translation from initial position
        DY=xy(1,2)-XYData(2);
        ObjectData.Coord(:,1)=ObjectData.Coord(:,1)+DX;
        ObjectData.Coord(:,2)=ObjectData.Coord(:,2)+DY;
        plot_object(ObjectData,ProjObject,AxeData.CurrentObject,'m');
        pointershape='fleur';
    elseif test_edit_object && isequal(AxeData.Drawing,'deform')
        ind_move=AxeData.CurrentIndex;
        ObjectData.Coord(ind_move,1)=xy(1,1);
        ObjectData.Coord(ind_move,2)=xy(1,2);
        plot_object(ObjectData,ProjObject,AxeData.CurrentObject,'m');
        pointershape='circle';
    end
end

%% detect calibration points if the GUI geometry_calib is opened
h_geometry_calib=findobj(allchild(0),'Name','geometry_calib'); %find the geomterty_calib GUI
if strcmp(htype,'axes') && ~CheckZoom && ~isempty(h_geometry_calib)
    pointershape='crosshair';%default for geometry_calib: ready to create new points
    hh_geometry_calib=guidata(h_geometry_calib);
    if  ~isempty(xy) && isfield(hh_geometry_calib,'ListCoord')
        h_ListCoord=hh_geometry_calib.ListCoord; %findobj(h_geometry_calib,'Tag','ListCoord');
        data.Coord=get(h_ListCoord,'Data');
        if isnumeric(data.Coord)&&~isempty(data.Coord)
            if test_transform
                XCoord=(data.Coord(:,1));
                YCoord=(data.Coord(:,2));
            else
                XCoord=(data.Coord(:,4));
                YCoord=(data.Coord(:,5));
            end
            xy=get(CurrentAxes,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
            if ~isempty(xy)
                xlim=get(CurrentAxes,'XLim');
%                 ind_range_x=abs((xlim(2)-xlim(1))/50);
                ylim=get(CurrentAxes,'YLim');
                ind_range=max(abs(xlim(2)-xlim(1)),abs(ylim(end)-ylim(1)))/25;%defines the size of the circle marker
%                 ind_range_y=abs((ylim(2)-ylim(1))/50);
%                 ind_range=sqrt(ind_range_x*ind_range_y);
                index_point=find((XCoord<xy(1,1)+ind_range/2) & (XCoord>xy(1,1)-ind_range/2) & ...%flagx=1 for the vectors with x position selected by the mouse
                    (YCoord<xy(1,2)+ind_range/2) & (YCoord>xy(1,2)-ind_range/2),1);%find the first calibration point in the neighborhood of the mouse
                if ~isempty(index_point)
                    pointershape='arrow';% default pointer is an arrow
                end
                hh=findobj('Tag','calib_points');%look for handle of calibration points
                if ~isempty(hh) && ~isempty(get(hh,'UserData')) %&& get(hh_geometry_calib.CheckEnableMouse,'Value')
                    %set(hh,'UserData',index_point)
                    index_point=get(hh,'UserData');
                    XCoord(index_point)=xy(1,1);
                    YCoord(index_point)=xy(1,2);
                    set(hh,'XData',XCoord)
                    set(hh,'YData',YCoord)
                end
                if ~isempty(index_point)
                    set(hh_geometry_calib.CoordLine,'String',num2str(index_point))
                   % Data=get(h_ListCoord,'Data');
%                     Data(:,6)=zeros(size(Data,1),1);
%                     Data(index_point,6)=-1;%mrk the point on the GUI geometry_calib
%                     set(h_ListCoord,'Data',Data);
                    hhh=findobj('Tag','calib_marker');%look for handle of point marker (circle)
                    if ~isempty(hhh)
                        set(hhh,'Position',[XCoord(index_point)-ind_range/2 YCoord(index_point)-ind_range/2 ind_range ind_range])
                    else
                        axes(hchild)
                        rectangle('Curvature',[1 1],...
                            'Position',[XCoord(index_point)-ind_range/2 YCoord(index_point)-ind_range/2 ind_range ind_range],'EdgeColor','m',...
                            'LineStyle','-','Tag','calib_marker');
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
if strcmp(pointershape,'zoom')||strcmp(pointershape,'zoomfig')
    CData=set_pointershape(pointershape);
    set(hCurrentFig,'Pointer','custom','PointerShapeCData',CData,'PointerShapeHotSpot',[9 9])
else
set(hCurrentFig,'Pointer',pointershape);
end

function CData=set_pointershape(pointershape)
        CData=ones(16,16);
        [ind_x,ind_y]=meshgrid([1:16],[1:16]);
        if strcmp(pointershape,'zoom')
        radius=(ind_x-9).*(ind_x-9)+(ind_y-8.5).*(ind_y-9);
        CData(radius<25 & radius>16)=2; %make white circle
        CData(radius<16 | radius>40)=NaN; %make the centre transparent
        CData(16,16)=1; CData(15,16)=2;
        CData(15,15)=1; CData(14,15)=2;
        CData(14,14)=1; CData(13,14)=2;
        CData(13,13)=1; CData(12,13)=2;
        elseif strcmp(pointershape,'zoomfig')
            CData(:,1:3)=2;
            CData(:,14:16)=2;
                        CData(1:3,:)=2;
            CData(14:16,:)=2;
            CData(CData==1)=NaN;
        end
