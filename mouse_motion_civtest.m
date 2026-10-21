%'mouse_motion': permanently called by mouse motion over a figure (Callback for 'WindowButtonMotionFcn' of the figure)
%-----------------------------------------------------------------------
%
% function mouse_motion(hObject,eventdata,handles)
% activated by the command:
% set(hObject,'WindowButtonMotionFcn',{'mouse_motion',handles})
% where hObject is the handle of the figure

%=======================================================================
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function mouse_motion_civtest(hfig,eventdata)

pos_pt=get(hfig,'CurrentPoint');
set(hfig,'Unit','pixel');
set(gca,'Unit','pixel');
pos_axis=get(gca,'Position');%position of the axis
if ~(pos_pt(1)>=pos_axis(1) && pos_pt(1)<=pos_axis(1)+pos_axis(3) && ...
        pos_pt(2)>=pos_axis(2) && pos_pt(2)<=pos_axis(2)+pos_axis(4))
    return
end
hchildren=get(hfig,'children');
htext_display=findobj(hchildren,'Tag','text_display');
CurrentAxes=gca;

xy=get(gca,'CurrentPoint');%xy(1,1),xy(1,2): current x,y positions in axes coordinates
FigData=get(hfig,'UserData'); % user data of the current figure
AxeData=get(gca,'UserData');
text_displ='';
% case of PIV correlation display
if isfield(FigData.PlotAxes,'par_civ')% look for handle of the civ_input GUI
    par_civ=FigData.PlotAxes.par_civ;%retrieve civ parameters
    [~,indpoint]=min(abs(par_civ.Grid(:,1)-xy(1,1))+abs(par_civ.Grid(:,2)-xy(1,2)));%find the civ grid point closest to the current point
    if size(par_civ.CorrBoxSize,1)==size(par_civ.Grid,1)% case of an input grid, take the box size at the current point
        par_civ.CorrBoxSize=par_civ.CorrBoxSize(indpoint,:);
    end
    par_civ.Grid=par_civ.Grid(indpoint,:);
    shiftx=par_civ.SearchBoxShift(1);
    shifty=par_civ.SearchBoxShift(2);
    xround=par_civ.Grid(1);
    yround=par_civ.Grid(2);
    text_displ=['x=' num2str(xround,4) ', y=' num2str(yround,4) ','];
    % mark the correlation box with a rectangle in view_field
    ibx2=floor((par_civ.CorrBoxSize(1)-1)/2);
    iby2=floor((par_civ.CorrBoxSize(2)-1)/2);
    isx2=par_civ.SearchRange(1);
    isy2=par_civ.SearchRange(2);
    hhh=findobj(CurrentAxes,'Tag','PIV_box_marker');
    hhhh=findobj(CurrentAxes,'Tag','PIV_search_marker');
    if isempty(hhh)
        set(0,'CurrentFigure',hfig)
        set(hfig,'CurrentAxes',CurrentAxes)
        rectangle('Curvature',[0 0],...
            'Position',[xround-ibx2 yround-iby2 2*ibx2 2*iby2],'EdgeColor','m',...
            'LineStyle','-','Tag','PIV_box_marker');
        rectangle('Curvature',[0 0],...
            'Position',[xround-isx2-ibx2+shiftx yround-isy2-iby2+shifty 2*isx2+2*ibx2 2*isy2+2*iby2],'EdgeColor','m',...
            'LineStyle','- -','Tag','PIV_search_marker');
    else
        set(hhh,'Position',[xround-ibx2 yround-iby2 2*ibx2 2*iby2])
        set(hhhh,'Position',[xround-isx2-ibx2+shiftx yround-isy2-iby2+shifty 2*isx2+2*ibx2 2*isy2+2*iby2])
    end
    [~,~,utable,vtable,~,~,result_conv,errormsg]= civ(par_civ);
    if ~isempty(errormsg)
        text_displ=errormsg;
    else
        rangx(1)=-isx2+shiftx;
        rangx(2)=isx2+shiftx;
        rangy(1)=-isy2-shifty;
        rangy(2)=isy2-shifty;
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
                AxeData.CurrentVector=line([0 utable],[0 vtable],'Tag','vector');
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
            set(AxeData.CurrentVector,'XData',[0 utable],'YData',[0 vtable]);
            set(AxeData.TitleHandle,'String',['[x,y]= ' num2str(par_civ.Grid) ' px'])
        end
    end
    set(htext_display,'String',text_displ)
end





