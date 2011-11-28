%'plot_object': draws a projection object (points, line, plane...)
%-------------------------------------------------------------------
% function [ObjectData_out,hh]=plot_object(ObjectData,hplot,col)
%
%OUTPUT
%             hh: handles of the graphic object (core part)
%
%INPUT:
%
% ObjectDataIn: structure representing the object properties:
%        .Style : style of projection object
%        .Coord: set of coordinates defining the object position;
%        .ProjMode=type of projection ;
%       .ProjAngle=angle of projection;
%       .DX,.DY,.DZ=increments;
%       .YMax,YMin: min and max Y
% ProjObject: projection object corresponding to the current plot (e. g. plane) 
% hplot: handle of the object plot to modify or if it is an axis, the axis
%            where the object must be plotted, or if it is a figure the plotting figure 
% col: color of the plot, e;g; 'm', 'b' ..;

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

function [hh]=plot_object(ObjectDataIn,ProjObject,hplot,col)
%% default output
hh=[];%default output
if ~isfield(ObjectDataIn,'Style')|| isequal(ProjObject,ObjectDataIn)% object representation does not appear in its own projection plot
    return
end
if ~isfield(ProjObject,'Style') 
    ObjectData=ObjectDataIn;
elseif isequal(ProjObject.Style,'plane')
    ObjectData=ObjectDataIn;% TODO: modify take into account rotation of axis
else
    return % object representation only  available in a plane
end
if ~isfield(ObjectData,'Style')||isempty(ObjectData.Style)||~ischar(ObjectData.Style)
    msgbox_uvmat('ERROR','undefined ObjectData.Style in plot_object.m')
    return
end
if ~isfield(ObjectData,'Style')||isempty(ObjectData.Style)||~ischar(ObjectData.Style)
    msgbox_uvmat('ERROR','undefined ObjectData.Style in plot_object.m')
    return
end
XMin=0;%default
XMax=0;
YMin=0;
YMax=0;
ZMin=0;
ZMax=0;

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
%         set(0,'CurrentFigure',currentfig)
      
%         set(currentfig,'CurrentAxes',haxes);
    elseif isequal(get(hplot,'Type'),'figure')% hplot is the handle of a figure 
        set(0,'CurrentFigure',hplot);%set the input figure as the current one
        haxes=findobj(hplot,'Type','axes');%look for axes in the figure
        haxes=haxes(1);
        currentfig=hplot;
       % set(hplot,'CurrentAxes',haxes);%set the first found axis as the current one
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
if ~isfield(ObjectData,'Phi')||isempty(ObjectData.Phi)
     ObjectData.Phi=0;%default
end
if ~isfield(ObjectData,'Range')
    ObjectData.Range(1,1)=0; %edfault
end
if size(ObjectData.Range,2)>=2
    YMax=ObjectData.Range(1,2);%default
end
if size(ObjectData.Range,2)>=2 & size(ObjectData.Range,1)>=2
    YMin=ObjectData.Range(2,2);
else
    YMin=0;
end
XMax=ObjectData.Range(1,1);
if size(ObjectData.Range,1)>=2 
    XMin=ObjectData.Range(2,1);
end
if isfield(ObjectData,'RangeX')
   XMax=max(ObjectData.RangeX);
   XMin=min(ObjectData.RangeX);
end
if isfield(ObjectData,'RangeY')
   YMax=max(ObjectData.RangeY);
   YMin=min(ObjectData.RangeY);
end
if isfield(ObjectData,'RangeZ')
   ZMax=max(ObjectData.RangeZ);
   ZMin=min(ObjectData.RangeZ);
end
if isequal(ObjectData.Style,'points')&isequal(ObjectData.ProjMode,'projection')
    YMax=max(XMax,YMax);
    YMax=max(YMax,ZMax);
elseif isequal(ObjectData.Style,'rectangle')||isequal(ObjectData.Style,'ellipse')||isequal(ObjectData.Style,'volume')
    if  isequal(YMax,0)
        ylim=get(haxes,'YLim');
        YMax=(ylim(2)-ylim(1))/100;
    end
    if isequal(XMax,0)
        XMax=YMax;%default
    end
elseif isequal(ObjectData.Style,'plane')
   if  isequal(XMax,0)
        xlim=get(haxes,'XLim');
        XMax=xlim(2);
   end
   if  isequal(YMax,0)
        ylim=get(haxes,'YLim');
        YMax=ylim(2);
   end
end
sizcoord=size(ObjectData.Coord);

%% determine the coordinates xline, yline,xsup,xinf, yinf,ysup determining the new object plot
test_line= isequal(ObjectData.Style,'points')|isequal(ObjectData.Style,'line')|isequal(ObjectData.Style,'polyline')|...
    isequal(ObjectData.Style,'polygon')| isequal(ObjectData.Style,'plane')| isequal(ObjectData.Style,'volume');
test_patch=isequal(ObjectData.ProjMode,'inside')||isequal(ObjectData.ProjMode,'outside')||isequal(ObjectData.Style,'volume')...
    ||isequal(ObjectData.ProjMode,'mask_inside')||isequal(ObjectData.ProjMode,'mask_outside');
if test_line
    xline=ObjectData.Coord(:,1);
    yline=ObjectData.Coord(:,2);
    nbpoints=numel(xline);
    if isequal(ObjectData.Style,'polygon')
        xline=[xline; ObjectData.Coord(1,1)];%closing the line
        yline=[yline; ObjectData.Coord(1,2)];
    elseif isequal(ObjectData.Style,'plane')|| isequal(ObjectData.Style,'volume') 
        phi=ObjectData.Phi*pi/180;%angle in radians
        Xend_x=xline(1)+XMax*cos(phi);
        Xend_y=yline(1)+XMax*sin(phi);
        Xbeg_x=xline(1)+XMin*cos(phi);
        Xbeg_y=yline(1)+XMin*sin(phi);
        Yend_x=xline(1)-YMax*sin(phi);
        Yend_y=yline(1)+YMax*cos(phi);
        Ybeg_x=xline(1)-YMin*sin(phi);
        Ybeg_y=yline(1)+YMin*cos(phi);
        xline=[Xbeg_x Xend_x NaN Ybeg_x Yend_x];
        yline=[Xbeg_y Xend_y NaN Ybeg_y Yend_y];
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
    if isequal(ObjectData.Style,'line')||isequal(ObjectData.Style,'polyline')||isequal(ObjectData.Style,'polygon')
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
end

%% shading image
if test_patch
    npMx=512;
    npMy=512;  
    flag=zeros(npMy,npMx);
    if isequal(ObjectData.Style,'ellipse')
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
    elseif isequal(ObjectData.Style,'rectangle')||isequal(ObjectData.Style,'volume')
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
    elseif isequal(ObjectData.Style,'polygon')
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
if test_newobj==0;
    hh=hplot;
    PlotData=get(hplot,'UserData');            
    if test_line
        set(hplot,'XData',xline)
        set(hplot,'YData',yline)
    %modify subobjects
        if isfield(PlotData,'SubObject') 
           if length(PlotData.SubObject)==2 && ~isequal(ObjectData.Style,'points')&& ~isequal(ObjectData.Style,'plane');
                set(PlotData.SubObject(1),'XData',xinf);
                set(PlotData.SubObject(1),'YData',yinf);
                set(PlotData.SubObject(2),'XData',xsup);
                set(PlotData.SubObject(2),'YData',ysup);
           elseif isequal(ObjectData.Style,'points')&& ~isequal(YMax,0)
               for ipt=1:min(length(PlotData.SubObject),size(ObjectData.Coord,1))
                    set(PlotData.SubObject(ipt),'Position',[ObjectData.Coord(ipt,1)-YMax ObjectData.Coord(ipt,2)-YMax 2*YMax 2*YMax])
               end
               %complement missing points
               if size(ObjectData.Coord,1)>length(PlotData.SubObject)
                   for ipt=length(PlotData.SubObject)+1:size(ObjectData.Coord,1)
                     PlotData.SubObject(ipt)=rectangle('Curvature',[1 1],...
                  'Position',[ObjectData.Coord(ipt,1)-YMax ObjectData.Coord(ipt,2)-YMax 2*YMax 2*YMax],'EdgeColor',col,...
                  'LineStyle',SubLineStyle,'Tag','proj_object');
                   end
               end                                         
           end
        end
        if isfield(PlotData,'DeformPoint')
           for ipt=1:length(PlotData.DeformPoint)
               if ishandle(PlotData.DeformPoint(ipt))
                   if nbpoints>=ipt  
                        set(PlotData.DeformPoint(ipt),'XData',xline(ipt),'YData',yline(ipt));
                    end
               end
           end
           if nbpoints>length(PlotData.DeformPoint)
               for ipt=length(PlotData.DeformPoint)+1:nbpoints
                    PlotData.DeformPoint(ipt)=line(xline(ipt),yline(ipt),'Color',col,'LineStyle','.','Tag','DeformPoint',...
                        'SelectionHighlight','off','UserData',hplot);
               end
               set(hplot,'UserData',PlotData)
           end
        end
    elseif isequal(ObjectData.Style,'rectangle')||isequal(ObjectData.Style,'ellipse')
        set(hplot,'Position',[ObjectData.Coord(1,1)-XMax ObjectData.Coord(1,2)-YMax 2*XMax 2*YMax])          
    end
    if test_patch 
        for iobj=1:length(PlotData.SubObject)
            objtype=get(PlotData.SubObject(iobj),'Type');
            if isequal(objtype,'image')
                set(PlotData.SubObject(iobj),'CData',imflag,'AlphaData',(flag)*0.2)
                set(PlotData.SubObject(iobj),'XData',[xlim(1)+dx/2 xlim(2)-dx/2])
                set(PlotData.SubObject(iobj),'YData',[ylim(1)+dy/2 ylim(2)-dy/2])
            end
        end
    end
end

%% create the object
if test_newobj
%     axes(haxes)
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
    if isequal(ObjectData.Style,'points')
        hh=line(ObjectData.Coord(:,1),ObjectData.Coord(:,2),'Color',col,'LineStyle','.','Marker','+');
        for ipt=1:length(xline)
              PlotData.DeformPoint(ipt)=line(ObjectData.Coord(ipt,1),ObjectData.Coord(ipt,2),'Color',...
                  col,'LineStyle','.','SelectionHighlight','off','UserData',hh,'Tag','DeformPoint');
              %create circle around each point
              if ~isequal(YMax,0)
                 PlotData.SubObject(ipt)=rectangle('Curvature',[1 1],...
                  'Position',[ObjectData.Coord(ipt,1)-YMax ObjectData.Coord(ipt,2)-YMax 2*YMax 2*YMax],'EdgeColor',col,...
                  'LineStyle',SubLineStyle,'Tag','proj_object');
              end
        end
    elseif  strcmp(ObjectData.Style,'line')||strcmp(ObjectData.Style,'polyline')||...        
          strcmp(ObjectData.Style,'polygon') ||strcmp(ObjectData.Style,'plane')||strcmp(ObjectData.Style,'volume')%  (isequal(ObjectData.Style,'polygon') & ~test_patch) |isequal(ObjectData.Style,'plane')
        hh=line(xline,yline,'Color',col);
        if ~strcmp(ObjectData.Style,'plane') && ~strcmp(ObjectData.Style,'volume')
            PlotData.SubObject(1)=line(xinf,yinf,'Color',col,'LineStyle',SubLineStyle,'Tag','proj_object');%draw sub-lines
            PlotData.SubObject(2)=line(xsup,ysup,'Color',col,'LineStyle',SubLineStyle,'Tag','proj_object');
            for ipt=1:sizcoord(1)
                PlotData.DeformPoint(ipt)=line(ObjectData.Coord(ipt,1),ObjectData.Coord(ipt,2),'Color',...
                      col,'LineStyle','none','Marker','.','Tag','DeformPoint','SelectionHighlight','off','UserData',hh);
            end
        end
    
    elseif strcmp(ObjectData.Style,'rectangle')
        hh=rectangle('Position',[ObjectData.Coord(1,1)-XMax ObjectData.Coord(1,2)-YMax 2*XMax 2*YMax],'EdgeColor',col);   
    elseif strcmp(ObjectData.Style,'ellipse')
        hh=rectangle('Curvature',[1 1],'Position',[ObjectData.Coord(1,1)-XMax ObjectData.Coord(1,2)-YMax 2*XMax 2*YMax],'EdgeColor',col);
    else
        msgbox_uvmat('ERROR','unknown ObjectData.Style in plot_object.m')
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
set(hh,'UserData',PlotData)
