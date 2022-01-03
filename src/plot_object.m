%'plot_object': draws a projection object (points, line, plane...)
%-------------------------------------------------------------------
% function hh=plot_object(ObjectData,ProjObject,hplot,col)
%
%OUTPUT
%             hh: handles of the graphic object (core part)
%
%INPUT:
%
% ObjectData: structure representing the object properties:
%        .Type : style of projection object
%        .Coord: set of coordinates defining the object position;
%        .ProjMode=type of projection ;
%       .ProjAngle=angle of projection;
%       .DX,.DY,.DZ=increments;
%       .YMax,YMin: min and max Y
% ProjObject: projection object corresponding to the current plot (e. g. plane) 
% hplot: handle of the object plot to modify or if it is an axis, the axis
%            where the object must be plotted, or if it is a figure the plotting figure 
% col: color of the plot, e;g; 'm', 'b' ..;

%=======================================================================
% Copyright 2008-2022, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [hh]=plot_object(ObjectData,ProjObject,hplot,col)

%% default output
hh=[];%default output
% object representation is canceled if the field is not projected on a plane or is the same as the represented object 
if ~isfield(ObjectData,'Type')|| isequal(ProjObject,ObjectData)||~isfield(ProjObject,'Type')|| ~strcmp(ProjObject.Type,'plane')
    if ~isempty(hplot) && ishandle(hplot) && ~strcmp(get(hplot,'Type'),'axes')
        ObjectPlotData=get(hplot,'UserData');
        if isfield(ObjectPlotData,'SubObject') & ishandle(ObjectPlotData.SubObject)
            delete(ObjectPlotData.SubObject);
        end
        if isfield(ObjectPlotData,'DeformPoint') & ishandle(ObjectPlotData.DeformPoint)
            delete(ObjectPlotData.DeformPoint);
        end
        delete(hplot)
    end
    return 
end
XMin=0;%default range for the graph
XMax=0;
YMin=0;
YMax=0;
ZMin=0;
ZMax=0;
XMinRange=[];%default range set by input
XMaxRange=[];
YMinRange=[];
YMaxRange=[];
ZMinRange=[];
ZMaxRange=[];

%% determine the plotting axes (with handle 'haxes')
test_newobj=1;
if ishandle(hplot)
    if isequal(get(hplot,'Tag'),'proj_object')% hplot is the handle of an object representation  
        test_newobj=0;
        haxes=get(hplot,'parent');
        currentfig=get(haxes,'parent');
    elseif isequal(get(hplot,'Type'),'axes')% hplot is the handle of an axis 
        haxes=hplot;
        currentfig=get(hplot,'parent');
    elseif isequal(get(hplot,'Type'),'figure')% hplot is the handle of a figure 
        set(0,'CurrentFigure',hplot);%set the input figure as the current one
        haxes=findobj(hplot,'Type','axes');%look for axes in the figure
        haxes=haxes(1);
        currentfig=hplot;
    else
        currentfig=figure; %create new figure
        hplot=axes;%create new axes
        haxes=hplot;
    end
else
    currentfig=figure; %create new figure
    hplot=axes;%create new axes
    haxes=hplot;
end
set(0,'CurrentFigure',currentfig)%set the currentfigure as the current one
set(currentfig,'CurrentAxes',haxes);%set the current axes in the current figure

%% default input parameters
if ~isfield(ObjectData,'ProjMode')||isempty(ObjectData.ProjMode)
     ObjectData.ProjMode='projection';%default
end
if ~isfield(ObjectData,'Coord')||isempty(ObjectData.Coord)
     ObjectData.Coord=[0 0 0];%default
end
if isfield(ObjectData,'RangeX') && ~isempty(ObjectData.RangeX)
    XMax=max(ObjectData.RangeX);
    XMin=min(ObjectData.RangeX);
        XMaxRange=max(ObjectData.RangeX);
        if numel(ObjectData.RangeX)==2
    XMinRange=min(ObjectData.RangeX);
        end
end
if isfield(ObjectData,'RangeY')&&~isempty(ObjectData.RangeY)
    YMax=max(ObjectData.RangeY);
    YMin=min(ObjectData.RangeY);
        YMaxRange=max(ObjectData.RangeY);
        if numel(ObjectData.RangeY)==2
    YMinRange=min(ObjectData.RangeY);
        end
end
if isfield(ObjectData,'RangeInterp')&&~isempty(ObjectData.RangeInterp) 
    YMax=ObjectData.RangeInterp;
end
if isfield(ObjectData,'RangeZ')&&~isempty(ObjectData.RangeZ)
    ZMax=max(ObjectData.RangeZ);
    ZMin=min(ObjectData.RangeZ);
    ZMaxRange=max(ObjectData.RangeZ);
    ZMinRange=min(ObjectData.RangeZ);
end
if strcmp(ObjectData.Type,'points') && strcmp(ObjectData.ProjMode,'projection')
    YMax=max(XMax,YMax);
    YMax=max(YMax,ZMax);
end
sizcoord=size(ObjectData.Coord);

%% determine the coordinates xline, yline,xsup,xinf, yinf,ysup determining the new object plot
test_line=ismember(ObjectData.Type,{'points','line','polyline','polygon','plane','plane_z','volume'});
test_patch=ismember(ObjectData.ProjMode,{'inside','outside','mask_inside','mask_outside'});
if test_line
    xline=ObjectData.Coord(:,1);
    yline=ObjectData.Coord(:,2);
    nbpoints=numel(xline);
    switch ObjectData.Type
        case 'polygon'
            xline=[xline; ObjectData.Coord(1,1)];%closing the line
            yline=[yline; ObjectData.Coord(1,2)];
        case {'plane','volume'}
            if ~isfield(ObjectData,'Angle')
                ObjectData.Angle=[0 0 0];
            end
            cosphi=cos(ObjectData.Angle(3)*pi/180);%angle in radians
            sinphi=sin(ObjectData.Angle(3)*pi/180);%angle in radians
            x0=xline(1); y0=yline(1);
            xlim=get(haxes,'XLim');
            ylim=get(haxes,'YLim');
            graph_scale=max(abs(xlim(2)-xlim(1)),abs(ylim(2)-ylim(1)))/2;% estimate the length of axes plots
            XMax=graph_scale;
            YMax=graph_scale;
            XMin=-graph_scale;
            YMin=-graph_scale;
            if  ~isempty(XMaxRange)
                XMax=XMaxRange;
            end
            if  ~isempty(XMinRange)
                XMin=XMinRange;
            end
            if  ~isempty(YMaxRange)
                YMax=YMaxRange;
            end
            if  ~isempty(YMinRange)
                YMin=YMinRange;
            end
            % axes lines
            xline=NaN(1,13);
            xline(1)=x0+min(0,XMin)*cosphi; % min end of the x axes
            yline(1)=y0+min(0,XMin)*sinphi;
            xline(2)=x0+XMax*cosphi;% max end of the x axes
            yline(2)=y0+XMax*sinphi;
            xline(8)=x0-min(0,YMin)*sinphi;% min end of the y axes
            yline(8)=y0+min(0,YMin)*cosphi;
            xline(9)=x0-YMax*sinphi;% max end of the y axes
            yline(9)=y0+YMax*cosphi;
            
            %arrows on x axis
            arrow_scale=graph_scale/20;
            phi=acos(cosphi);
            xline(3)=xline(2)-arrow_scale*cos(phi-pi/8);
            yline(3)=yline(2)-arrow_scale*sin(phi-pi/8);
            xline(5)=xline(2);
            yline(5)=yline(2);
            xline(6)=xline(2)-arrow_scale*cos(phi+pi/8);
            yline(6)=yline(2)-arrow_scale*sin(phi+pi/8);
            
            %arrows on y axis
            xline(10)=xline(9)-arrow_scale*cos(phi+pi/2-pi/8);
            yline(10)=yline(9)-arrow_scale*sin(phi+pi/2-pi/8);
            xline(12)=xline(9);
            yline(12)=yline(9);
            xline(13)=xline(9)-arrow_scale*cos(phi+pi/2+pi/8);
            yline(13)=yline(9)-arrow_scale*sin(phi+pi/2+pi/8);
            %xline=[Xbeg_x Xend_x NaN Ybeg_x Yend_x];
            %yline=[Xbeg_y Xend_y NaN Ybeg_y Yend_y];
            %  dashed lines indicating bounds
            xsup=NaN(1,5);
            ysup=NaN(1,5);
            if ~isempty(XMaxRange)
                xsup(1)=xline(2)-YMin*sin(phi);
                ysup(1)=yline(2)+YMin*cos(phi);
                xsup(2)=xline(2)-YMax*sin(phi);
                ysup(2)=yline(2)+YMax*cos(phi);
            end
            if ~isempty(YMaxRange)
                xsup(2)=xline(2)-YMax*sin(phi);
                ysup(2)=yline(2)+YMax*cos(phi);
                xsup(3)=xline(9)+XMin*cos(phi);
                ysup(3)=yline(9)+XMin*sin(phi);
            end
            if ~isempty(XMinRange)
                xsup(3)=xline(9)+XMin*cos(phi);
                ysup(3)=yline(9)+XMin*sin(phi);
                xsup(4)=x0+XMin*cos(phi)-YMin*sin(phi);
                ysup(4)=y0+XMin*sin(phi)+YMin*cos(phi);
            end
            if ~isempty(YMinRange)
                xsup(4)=x0+XMin*cos(phi)-YMin*sin(phi);
                ysup(4)=y0+XMin*sin(phi)+YMin*cos(phi);
                xsup(5)=xline(8)-YMin*sin(phi);
                ysup(5)=yline(8)+YMin*cos(phi);
            end
    end
end
SubLineStyle='none';%default
if isfield(ObjectData,'ProjMode')
    if isequal(ObjectData.ProjMode,'projection')
        SubLineStyle='--'; %range of projection marked by dash
        if isfield (ObjectData,'DX')
            ObjectData=rmfield(ObjectData,'DX');
        end
        if isfield (ObjectData,'DY')
            ObjectData=rmfield(ObjectData,'DY');
        end
    elseif isequal(ObjectData.ProjMode,'filter')
        SubLineStyle=':';%range of projection not visible
    end
end
if ismember(ObjectData.Type,{'line','polyline','polygon'})&&...
        ismember(ObjectData.ProjMode,{'projection','interp_lin','interp_tps'})
    if length(xline)<2
        theta=0;
    else
        theta=angle(diff(xline)+1i*diff(yline));
        theta(length(xline))=theta(length(xline)-1);
    end
    xsup(1)=xline(1)+YMax*sin(theta(1));
    xinf(1)=xline(1)-YMax*sin(theta(1));
    ysup(1)=yline(1)-YMax*cos(theta(1));
    yinf(1)=yline(1)+YMax*cos(theta(1));
    for ip=2:length(xline)
        xsup(ip)=xline(ip)+YMax*sin((theta(ip)+theta(ip-1))/2)/cos((theta(ip-1)-theta(ip))/2);
        xinf(ip)=xline(ip)-YMax*sin((theta(ip)+theta(ip-1))/2)/cos((theta(ip-1)-theta(ip))/2);
        ysup(ip)=yline(ip)-YMax*cos((theta(ip)+theta(ip-1))/2)/cos((theta(ip-1)-theta(ip))/2);
        yinf(ip)=yline(ip)+YMax*cos((theta(ip)+theta(ip-1))/2)/cos((theta(ip-1)-theta(ip))/2);
    end
end

%% shading image
if test_patch
    npMx=512;
    npMy=512;  
    flag=zeros(npMy,npMx);
    if isequal(ObjectData.Type,'ellipse')
        XimaMin=ObjectData.Coord(1,1)-XMax;
        XimaMax=ObjectData.Coord(1,1)+XMax;
        YimaMin=ObjectData.Coord(1,2)-YMax;
        YimaMax=ObjectData.Coord(1,2)+YMax; 
        xlim=[1.2*XimaMin-0.2*XimaMax 1.2*XimaMax-0.2*XimaMin];%create an image around the ellipse
        ylim=[1.2*YimaMin-0.2*YimaMax 1.2*YimaMax-0.2*YimaMin];
        scale_x=2*1.4*XMax/npMx;
        scale_y=2*1.4*YMax/npMy;
        xi=(0.5:npMx-0.5)*scale_x+xlim(1);
        yi=(0.5:npMy-0.5)*scale_y+ylim(1);
        [Xi,Yi]=meshgrid(xi,yi);
        X2Max=XMax*XMax;
        Y2Max=YMax*YMax;
        distX=(Xi-ObjectData.Coord(1,1));
        distY=(Yi-ObjectData.Coord(1,2));
        flag=(distX.*distX/X2Max+distY.*distY/Y2Max)<1;
    elseif isequal(ObjectData.Type,'rectangle')||isequal(ObjectData.Type,'volume')
        XimaMin=ObjectData.Coord(1,1)-XMax;
        XimaMax=ObjectData.Coord(1,1)+XMax;
        YimaMin=ObjectData.Coord(1,2)-YMax;
        YimaMax=ObjectData.Coord(1,2)+YMax; 
        xlim=[1.2*XimaMin-0.2*XimaMax 1.2*XimaMax-0.2*XimaMin];%create an image around the ellipse
        ylim=[1.2*YimaMin-0.2*YimaMax 1.2*YimaMax-0.2*YimaMin];
        scale_x=2*1.4*XMax/npMx;
        scale_y=2*1.4*YMax/npMy;
        xi=(0.5:npMx-0.5)*scale_x+xlim(1);
        yi=(0.5:npMy-0.5)*scale_y+ylim(1);
        [Xi,Yi]=meshgrid(xi,yi);
        distX=abs(Xi-ObjectData.Coord(1,1));
        distY=abs(Yi-ObjectData.Coord(1,2));
        flag=distX<XMax & distY< YMax;
    elseif isequal(ObjectData.Type,'polygon')
        XimaMin=min(ObjectData.Coord(:,1));
        XimaMax=max(ObjectData.Coord(:,1));
        YimaMin=min(ObjectData.Coord(:,2));
        YimaMax=max(ObjectData.Coord(:,2)); 
        xlim=[1.2*XimaMin-0.2*XimaMax 1.2*XimaMax-0.2*XimaMin];
        ylim=[1.2*YimaMin-0.2*YimaMax 1.2*YimaMax-0.2*YimaMin];
        [Xlim,Ylim]=meshgrid(linspace(xlim(1),xlim(2),npMx),linspace(ylim(1),ylim(2),npMy));
        %flag=roipoly(xlim,ylim,flag,ObjectData.Coord(:,1),ObjectData.Coord(:,2));%=1 inside the polygon, 0 outsid
        flag=inpolygon(Xlim,Ylim,ObjectData.Coord(:,1),ObjectData.Coord(:,2));%=1 inside the polygon, 0 outsid
    end 
    if isequal(ObjectData.ProjMode,'outside')||isequal(ObjectData.ProjMode,'mask_outside')
        flag=~flag;
    end
    imflag=zeros(npMx,npMy,3);
    imflag(:,:,3)=flag; % blue color
    if isequal(col,'m')
         imflag(:,:,1)=flag; % magenta color
    end
    dx=(xlim(2)-xlim(1))/npMx;
    dy=(ylim(2)-ylim(1))/npMy;
end

PlotData=[];%default

%% MODIFY AN EXISTING OBJECT PLOT
if test_newobj==0
    hh=hplot;
    PlotData=get(hplot,'UserData');
    if test_line
        set(hplot,'XData',xline)
        set(hplot,'YData',yline)
        %modify subobjects
        if isfield(PlotData,'SubObject')
            if isequal(ObjectData.Type,'points')
                if ~isequal(YMax,0)
                    for ipt=1:min(length(PlotData.SubObject),size(ObjectData.Coord,1))
                        set(PlotData.SubObject(ipt),'Position',[ObjectData.Coord(ipt,1)-YMax ObjectData.Coord(ipt,2)-YMax 2*YMax 2*YMax])
                    end
                    %complement missing points
                    if length(PlotData.SubObject)>nbpoints% fpoints in excess on the graph
                        for ii=nbpoints+1: length(PlotData.SubObject)
                            if ishandle(PlotData.SubObject(ii))
                                delete(PlotData.SubObject(ii))
                            end
                        end
                    end
                    if nbpoints>length(PlotData.SubObject)
                        for ipt=length(PlotData.SubObject)+1:nbpoints
                            PlotData.SubObject(ipt)=rectangle('Curvature',[1 1],...
                                'Position',[ObjectData.Coord(ipt,1)-YMax ObjectData.Coord(ipt,2)-YMax 2*YMax 2*YMax],'EdgeColor',col,...
                                'LineStyle',SubLineStyle,'Tag','proj_object');
                        end
                    end
                end
            elseif length(PlotData.SubObject)==2
                if ismember(ObjectData.ProjMode,{'projection','interp_lin','interp_tps'})
                    set(PlotData.SubObject(1),'XData',xinf);
                    set(PlotData.SubObject(1),'YData',yinf);
                    set(PlotData.SubObject(2),'XData',xsup);
                    set(PlotData.SubObject(2),'YData',ysup);
                end
            elseif length(PlotData.SubObject)==1
                if ismember(ObjectData.ProjMode,{'projection','interp_lin','interp_tps'})
                    set(PlotData.SubObject(1),'XData',xsup);
                    set(PlotData.SubObject(1),'YData',ysup);
                end
            end
            if strcmp(ObjectData.ProjMode,'none')
                delete(PlotData.SubObject)
                PlotData=rmfield(PlotData,'SubObject');
            end
        end
        if isfield(PlotData,'DeformPoint')
            NbDeformPoint=length(PlotData.DeformPoint);
            % delete deformpoints in excess on the graph
            if NbDeformPoint>nbpoints
                for ii=nbpoints+1:NbDeformPoint
                    if ishandle(PlotData.DeformPoint(ii))
                        delete(PlotData.DeformPoint(ii))
                    end
                end
                NbDeformPoint=nbpoints;
            end
            % update the position of the existing deformpoints
            for ipt=1:NbDeformPoint
                if ishandle(PlotData.DeformPoint(ipt))
                    if nbpoints>=ipt
                        set(PlotData.DeformPoint(ipt),'XData',xline(ipt),'YData',yline(ipt));
                    end
                end
            end
            % add neww deform points if requested
            if nbpoints>length(PlotData.DeformPoint)
                for ipt=length(PlotData.DeformPoint)+1:nbpoints
                    PlotData.DeformPoint(ipt)=line(xline(ipt),yline(ipt),'Color',col,'LineStyle','-','Tag','DeformPoint',...
                        'Marker','.','MarkerSize',12,'SelectionHighlight','off','UserData',hplot);
                end
                set(hplot,'UserData',PlotData)
            end
        end
    elseif (isequal(ObjectData.Type,'rectangle')||isequal(ObjectData.Type,'ellipse'))&&XMax>0 && YMax>0
        set(hplot,'Position',[ObjectData.Coord(1,1)-XMax ObjectData.Coord(1,2)-YMax 2*XMax 2*YMax])
    end
    if test_patch
        createimage=1;
        if isfield(PlotData,'SubObject')
            for iobj=1:length(PlotData.SubObject)
                objtype=get(PlotData.SubObject(iobj),'Type');
                if isequal(objtype,'image')
                    set(PlotData.SubObject(iobj),'CData',imflag,'AlphaData',(flag)*0.2)
                    set(PlotData.SubObject(iobj),'XData',[xlim(1)+dx/2 xlim(2)-dx/2])
                    set(PlotData.SubObject(iobj),'YData',[ylim(1)+dy/2 ylim(2)-dy/2])
                    createimage=0;
                end
            end
        end
        if createimage
            hold on
            hhh=image([xlim(1)+dx/2 xlim(2)-dx/2],[ylim(1)+dy/2 ylim(2)-dy/2],imflag,'Tag','proj_object','HitTest','off');
            set(hhh,'AlphaData',(flag)*0.2)% set partial transparency to the filling color
            PlotData.SubObject(1)=hhh;
        end
    else% no patch image requested, erase existing ones
        if isfield(PlotData,'SubObject')
            for iobj=1:length(PlotData.SubObject)
                if ishandle(PlotData.SubObject(iobj)) && strcmp(get(PlotData.SubObject(iobj),'Type'),'image')
                    delete(PlotData.SubObject(iobj))
                    PlotData=rmfield(PlotData,SubObject(iobj));
                end
            end
        end
    end
end

%% create the object
if test_newobj
    hother=findobj('Tag','proj_object');%find all the proj objects
    for iobj=1:length(hother)
        if strcmp(get(hother(iobj),'Type'),'rectangle')|| strcmp(get(hother(iobj),'Type'),'patch')
            set(hother(iobj),'EdgeColor','b')
            if isequal(get(hother(iobj),'FaceColor'),'m')
                set(hother(iobj),'FaceColor','b')
            end
        elseif isequal(get(hother(iobj),'Type'),'image')
               Acolor=get(hother(iobj),'CData');
               Acolor(:,:,1)=zeros(size(Acolor,1),size(Acolor,2));
               set(hother(iobj),'CData',Acolor);
        else
             set(hother(iobj),'Color','b')
        end
        set(hother(iobj),'Selected','off')
    end
    hother=findobj('Tag','DeformPoint');
    set(hother,'Color','b');
    set(hother,'Selected','off')  
    switch ObjectData.Type
        case 'points'
            hh=line(ObjectData.Coord(:,1),ObjectData.Coord(:,2),'Color',col,'LineStyle','none','Marker','+');
            for ipt=1:length(xline)
                PlotData.DeformPoint(ipt)=line(ObjectData.Coord(ipt,1),ObjectData.Coord(ipt,2),'Color',...
                    col,'LineStyle','none','Marker','.','MarkerSize',12,'SelectionHighlight','off','UserData',hh,'Tag','DeformPoint');
                %create circle around each point
                if ~isequal(YMax,0)
                    PlotData.SubObject(ipt)=rectangle('Curvature',[1 1],...
                        'Position',[ObjectData.Coord(ipt,1)-YMax ObjectData.Coord(ipt,2)-YMax 2*YMax 2*YMax],'EdgeColor',col,...
                        'LineStyle',SubLineStyle,'Tag','proj_object');
                end
            end
        case {'line','polyline','polygon'}
            hh=line(xline,yline,'Color',col);
            if ismember(ObjectData.ProjMode,{'projection','interp_lin','interp_tps'})
                PlotData.SubObject(1)=line(xinf,yinf,'Color',col,'LineStyle',SubLineStyle,'Tag','proj_object');%draw sub-lines
                PlotData.SubObject(2)=line(xsup,ysup,'Color',col,'LineStyle',SubLineStyle,'Tag','proj_object');
            end
                for ipt=1:sizcoord(1)
                    PlotData.DeformPoint(ipt)=line(ObjectData.Coord(ipt,1),ObjectData.Coord(ipt,2),'Color',...
                        col,'LineStyle','none','Marker','.','MarkerSize',12,'Tag','DeformPoint','SelectionHighlight','off','UserData',hh);
                end
        case {'plane','volume'}
            hh=line(xline,yline,'Color',col);
            PlotData.SubObject(1)=line(xsup,ysup,'Color',col,'LineStyle',SubLineStyle,'Tag','proj_object');
        case 'rectangle'
            hh=rectangle('Position',[ObjectData.Coord(1,1)-XMax ObjectData.Coord(1,2)-YMax 2*XMax 2*YMax],'LineWidth',2,'EdgeColor',col);
        case 'ellipse'
            hh=rectangle('Curvature',[1 1],'Position',[ObjectData.Coord(1,1)-XMax ObjectData.Coord(1,2)-YMax 2*XMax 2*YMax],'EdgeColor',col,'LineWidth',2);
        otherwise
            msgbox_uvmat('ERROR','unknown ObjectData.Type in plot_object.m')
            return
    end
    set(hh,'Tag','proj_object')
     if test_patch
         hold on
        hhh=image([xlim(1)+dx/2 xlim(2)-dx/2],[ylim(1)+dy/2 ylim(2)-dy/2],imflag,'Tag','proj_object','HitTest','off');
       set(hhh,'AlphaData',(flag)*0.2)% set partial transparency to the filling color
         PlotData.SubObject=hhh;    
     end
    if isfield(PlotData,'SubObject')
        set(PlotData.SubObject,'UserData',hh)%record the parent handles in the SubObjects
    end
    if isfield(PlotData,'DeformPoint')
        for ipt=1:sizcoord(1)
            set(PlotData.DeformPoint(ipt),'UserData',hh);%record the parent handles in the SubObjects
        end
        set(PlotData.DeformPoint,'UserData',hh)%record the parent handles in the SubObjects
    end
end
%put the deformpoints to the front
            listc=get(gca,'children');
            checkdeform=strcmp(get(listc,'tag'),'DeformPoint');
            [nn,Index]=sort(checkdeform,'descend');
            set(gca,'children',listc(Index))
set(hh,'UserData',PlotData)
