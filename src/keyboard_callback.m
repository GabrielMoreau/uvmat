%'keyboard_callback:' function activated when a key is pressed on the keyboard when a figure has been selected by the mouse  (callback `KeyPressFcn` of Matlab).
%-----------------------------------

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

function keyboard_callback(hObject,eventdata,handleshaxes)
cur_axes=get(hObject,'CurrentAxes');%current plotting axes of the figure with handle hObject
xx=double(get(hObject,'CurrentCharacter')); %get the keyboard character
if ~isempty(xx)
    switch xx
        case {29,28,30,31,8592,8593,8594,8595}  %arrows for displacement (linux or windows)
            hhh=get(hObject,'CurrentObject');
            AxeData=get(cur_axes,'UserData');
            if isfield(AxeData,'ZoomAxes')&&ishandle(AxeData.ZoomAxes)
                cur_axes=AxeData.ZoomAxes;% move the field of the zoom sub-plot instead of the main axes  if it exsits
                axes(cur_axes)
            end
            if ~isempty(cur_axes) && ~strcmp(get(hhh,'Type'),'uicontrol')
                xlimit=get(cur_axes,'XLim');
                ylimit=get(cur_axes,'Ylim');
                dx=(xlimit(2)-xlimit(1))/10;
                dy=(ylimit(2)-ylimit(1))/10;
                switch xx
                    case{29,8594}%move arrow right
                        xlimit=xlimit+dx;
                    case{28,8592}%move arrow left
                        xlimit=xlimit-dx;
                    case {30,8593}%move arrow up
                        ylimit=ylimit+dy;
                    case{31,8595}%move arrow down%move arrow down
                        ylimit=ylimit-dy;
                end
                set(cur_axes,'XLim',xlimit)
                set(cur_axes,'YLim',ylimit)
                hfig=hObject; %master figure
                AxeData=get(cur_axes,'UserData');
                if isfield(AxeData,'ParentRect')% update the position of the parent rectangle representing the field
                    hparentrect=AxeData.ParentRect;
                    rect([1 2])=[xlimit(1) ylimit(1)];
                    rect([3 4])=[xlimit(2)-xlimit(1) ylimit(2)-ylimit(1)];
                    set(hparentrect,'Position',rect)
                elseif isfield(AxeData,'LimEditBox')&& isequal(AxeData.LimEditBox,1)% update display of the GUI containing the axis (uvmat or view_field)
                    hh=guidata(hfig);
                    if isfield(hh,'num_MinX')
                        set(hh.num_MinX,'String',num2str(xlimit(1)))
                        set(hh.num_MaxX,'String',num2str(xlimit(2)))
                        set(hh.num_MinY,'String',num2str(ylimit(1)))
                        set(hh.num_MaxY,'String',num2str(ylimit(2)))
                    end
                end
            end
        case 112%  key 'p'
            huvmat=findobj(allchild(0),'Tag','uvmat');
            if ~isempty(huvmat)
            hhuvmat=guidata(huvmat);
            uvmat('runplus_Callback',hObject,eventdata,hhuvmat)
            end
        case 109%  key 'm'
                      huvmat=findobj(allchild(0),'Tag','uvmat');
                      if ~isempty(huvmat)
            hhuvmat=guidata(huvmat);
            uvmat('runmin_Callback',hObject,eventdata,handleshaxes)
                      end
        otherwise
            if ischar(get(gco,'Tag'))
                switch get(gco,'tag')% tag of the current edit box
                    case {'RootPath', 'SubDir','RootFile','FileExt','RootPath_1', 'SubDir_1','RootFile_1','FileExt_1'}
                        set(handleshaxes.InputFileREFRESH,'BackgroundColor',[1 0 1])%indicat that REFRESH must be activated (introduce the whole series)
                    case 'num_IndexIncrement'% no action
                    otherwise
                        if isfield(handleshaxes,'REFRESH')
                            set(handleshaxes.REFRESH,'BackgroundColor',[1 0 1])%indicat that run0 must be activated
                            if isfield(handleshaxes,'movie_pair')% stop movie pair in uvmat
                                set(handleshaxes.movie_pair,'value',0);
                                set(handleshaxes.movie_pair,'BusyAction','Cancel')%stop movie pair if button is 'off'
                                set(handleshaxes.num_i2,'String','')% the second i index display is suppressed
                                set(handleshaxes.num_j2,'String','')% the second j index display is suppressed
                                set(handleshaxes.Dt_txt,'String','')% the time interval indication is suppressed
                            end
                        elseif strcmp(get(gco,'Type'),'uicontrol')
                            set(gco,'BackgroundColor',[1 0 1])%indicate that the edition  must be validated by carriage return
                        end
                end
            end
    end
end
