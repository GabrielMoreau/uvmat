%'mouse_alt_gui': function activated when the right mouse button is pressed on a GUI (callback for 'WindowButtonDownFcn')
% it displays a msg box with zoom of the current uicontrol display
%------------------------------------------------------------------------
function mouse_alt_gui(hObject,eventdata,handles)
%------------------------------------------------------------------------
if isequal(get(hObject,'SelectionType'),'alt')
    set(hObject,'Units','pixels')
    series_pos=get(hObject,'Position');%position of the current GUI  (in pixels), as selected by the mouse
    set(hObject,'Units','normalized')
    xy_fig=get(hObject,'CurrentPoint');% current point of the current GUI 
    hchild=get(hObject,'Children');%handles of all objects in the current GUI
    %% loop on all the objects in the current figure (selected by the last mouse click)
    for ichild=1:length(hchild)
        obj_pos=get(hchild(ichild),'Position');%position of the object        
        if numel(obj_pos)>=4 && xy_fig(1) >=obj_pos(1) && xy_fig(2) >= obj_pos(2)&& xy_fig(1) <=obj_pos(1)+obj_pos(3) && xy_fig(2) <= obj_pos(2)+obj_pos(4);         
            htype=get(hchild(ichild),'Type');%type of object child of the current figure
            %if the mouse is over a uicontrol, look at the data
            if isequal(htype,'uicontrol') && isequal(get(hchild(ichild),'Visible'),'on')
                msg_pos(1:2)=series_pos(1:2)+obj_pos(1:2).*series_pos(3:4);
                msgbox_uvmat(['uicontrol: ' get(hchild(ichild),'Tag')],'',get(hchild(ichild),'String'),msg_pos)
                break
            end
        end
    end
    set(hObject,'Units','pixels')
end