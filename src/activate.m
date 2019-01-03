% 'activate': emulate the mouse selection of a GUI element, for demo
%-----------------------------------------------------------------------
% function activate(FigTag,PanelTag,ObjectTag,Value)
%
% INPUT:
% FigTag: tag name of the GUI figure (e.g; 'uvmat')
% PanelTag: tag name of a uipanel containing the element, =[] if no panel
% ObjectTag: tag name of the element
% Position=[x y] coordinates set for the mouse relative to the object (default =[] corresponds to the centre [0.5 0.5]
% Value: value set to the element, for instance string to select on a menu

%=======================================================================
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function activate(FigTag,PanelTag,ObjectTag,Position,Value)
hFig=findobj(allchild(0),'tag',FigTag);
set(0,'CurrentFigure',hFig)
% xx=double(get(hFig,'CurrentCharacter')); %get the keyboard character
% if isequal(xx,27) % key escape
%     pause
% end
handles=guidata(hFig);
unit_0=get(0,'Unit');
unit=get(hFig,'Unit');
set(hFig,'Unit',unit_0)
FramePos=get(hFig,'Position');% position of the figure
set(hFig,'Unit',unit)
if isempty(PanelTag)
    hPanel=hFig;
    hObject=handles.(ObjectTag);
else
    hPanel=findobj(hFig,'tag',PanelTag);
    unit=get(hPanel,'Unit');
    set(hPanel,'Unit',unit_0)
    FramePos=FramePos+get(hPanel,'Position');
    set(hPanel,'Unit',unit)
end
if ~exist('Position','var')
    Position=[];
end
if isempty(Position)
    Position=[0.5 0.5];
end
if ~exist('Value','var')
    Value=[];
end
hObject=handles.(ObjectTag);
if isempty(hObject)
    disp(['Object' ObjectTag ' not found'])
else
    if exist('Value','var')
        if isempty(PanelTag)
            Param.(ObjectTag)=Value;
        else
            Param.(PanelTag).(ObjectTag)=Value;
        end
        errormsg=fill_GUI(Param,hFig);
        if ~isempty(errormsg)
            disp(errormsg)
        end
%         if isequal(get(handles.(ObjectTag),'Style'),'pushbutton')
%             set(handles.(ObjectTag),'Value',Value)
%         end
    end
    unit=get(hObject,'Unit');
    set(hObject,'Unit',unit_0);
    Pos=get(hObject,'Position');
    set(hObject,'Unit',unit)
    CurrentPointerLoc=get(0,'PointerLocation');
    NewPointerLoc=FramePos(1:2)+Pos(1:2)+Position.*Pos(3:4);
    set(0,'PointerLocation',FramePos(1:2)+Pos(1:2)+Position.*Pos(3:4))  
    for ipos=1:10
        set(0,'PointerLocation',CurrentPointerLoc+0.1*ipos*(NewPointerLoc-CurrentPointerLoc))
        pause(0.2)
    end
    if strcmp(get(hObject,'Type'),'axes')
        mouse_down(hFig,[])
        pause(2)
        mouse_up(hFig,[])
        drawnow
    else
    BackgroundColor=get(hObject,'BackgroundColor');
    set(hObject,'BackgroundColor',[1 1 0])% mark activation of the object
    drawnow
    feval(FigTag,[ObjectTag '_Callback'],hObject,[],handles);
        pause(2)
    set(hObject,'BackgroundColor',BackgroundColor)
    end
end
%%%%text display
if isempty(Value)
disp(['mouse select ' ObjectTag ' in ' FigTag ' ' PanelTag])
else
    disp(['set ' Value ' in ' FigTag ' ' PanelTag ' ' ObjectTag])
end
