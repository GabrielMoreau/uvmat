%'keyboard_callback:' function activated when a key is pressed on the keyboard
%-----------------------------------
function keyboard_callback(hObject,eventdata,handleshaxes)
cur_axes=get(hObject,'CurrentAxes');%current plotting axes of the figure with handle hObject
xx=double(get(hObject,'CurrentCharacter')); %get the keyboard character
if ~isempty(xx)
    switch xx
        case {29,28,30,31}    %arrows for displacement
            AxeData=get(cur_axes,'UserData');
            if isfield(AxeData,'ZoomAxes')&&ishandle(AxeData.ZoomAxes)
                cur_axes=AxeData.ZoomAxes;% move the field of the zoom sub-plot instead of the main axes  if it exsits
                axes(cur_axes)
            end
            if ~isempty(cur_axes)
                xlimit=get(cur_axes,'XLim');
                ylimit=get(cur_axes,'Ylim');
                dx=(xlimit(2)-xlimit(1))/10;
                dy=(ylimit(2)-ylimit(1))/10;
                if isequal(xx,29)%move arrow right
                    xlimit=xlimit+dx;
                elseif isequal(xx,28)%move arrow left
                    xlimit=xlimit-dx;
                elseif isequal(xx,30)%move arrow up
                    ylimit=ylimit+dy;
                elseif isequal(xx,31)%move arrow down
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
            uvmat('runplus_Callback',hObject,eventdata,handleshaxes)
        case 109%  key 'm'
            uvmat('runmin_Callback',hObject,eventdata,handleshaxes)
        otherwise
            if ischar(get(gco,'Tag'))
            switch get(gco,'tag')% tag of the current edit box
                case {'RootPath', 'SubDir','RootFile','FileExt','RootPath_1', 'SubDir_1','RootFile_1','FileExt_1'}
                    set(handleshaxes.InputFileREFRESH,'BackgroundColor',[1 0 1])%indicat that REFRESH must be activated (introduce the whole series)
                case 'num_IndexIncrement'% no action
                otherwise
                    if isfield(handleshaxes,'REFRESH')
                    set(handleshaxes.REFRESH,'BackgroundColor',[1 0 1])%indicat that run0 must be activated
                    elseif strcmp(get(gco,'Type'),'uicontrol')
                       set(gco,'BackgroundColor',[1 0 1])%indicate that the edition  must be validated by carriage return
                    end
            end
            end
    end
end
