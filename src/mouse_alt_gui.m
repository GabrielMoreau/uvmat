%'mouse_alt_gui': function activated when the right mouse button is pressed on a GUI (callback for 'WindowButtonDownFcn')
% it displays an editable msg box with zoom of the current uicontrol display
%------------------------------------------------------------------------
function mouse_alt_gui(hObject,eventdata,handles)
%------------------------------------------------------------------------
if isequal(get(hObject,'SelectionType'),'alt')
    set(hObject,'Units','pixels')
    GUI_pos=get(hObject,'Position');%position on the screen  (in pixels)  of the GUI selected by the mouse
    set(hObject,'Units','normalized')
    xy_fig=get(hObject,'CurrentPoint');% current point of the current GUI
    hchildren=get(hObject,'Children');%handles of all objects in the current GUI
    %% loop on all the objects in the current figure (selected by the last mouse click)
    for ichild=1:length(hchildren)
        hchild=hchildren(ichild);
        obj_pos=get(hchild,'Position');%position of the object
        if numel(obj_pos)>=4 && xy_fig(1) >=obj_pos(1) && xy_fig(2) >= obj_pos(2)&& xy_fig(1) <=obj_pos(1)+obj_pos(3) && xy_fig(2) <= obj_pos(2)+obj_pos(4);
            htype=get(hchild,'Type');%type of object child of the current figure
            switch htype
                case 'uicontrol'
                    %if the mouse is over a uicontrol, look at the data
                    if strcmp(get(hchild,'Visible'),'on')
                        msg_pos(1:2)=GUI_pos(1:2)+obj_pos(1:2).*GUI_pos(3:4);
                        output_str=msgbox_uvmat(['uicontrol: ' get(hchild,'Tag')],'',get(hchild,'String'),msg_pos);
                        break
                    end
                case 'uipanel'
                    panel_pos=obj_pos;%position of the panel
                    hhchildren=get(hchild,'Children');%handles of all objects in the current GUI
                    %% loop on all the objects in the current figure (selected by the last mouse click)
                    for iichild=1:length(hhchildren)
                        hchild=hhchildren(iichild);
                        rel_pos=get(hchild,'Position');%position of the object relative to the uipanel
                        obj_pos(1:2)=panel_pos(1:2)+rel_pos(1:2).*panel_pos(3:4);
                        obj_pos(3:4)=panel_pos(3:4).*rel_pos(3:4);
                        if numel(obj_pos)>=4 && xy_fig(1) >=obj_pos(1) && xy_fig(2) >= obj_pos(2)&& xy_fig(1) <=obj_pos(1)+obj_pos(3) && xy_fig(2) <= obj_pos(2)+obj_pos(4);
                            htype=get(hchild,'Type');%type of object child of the current figure
                            %if the mouse is over a uicontrol, look at the data
                            if strcmp(htype,'uicontrol') && strcmp(get(hchild,'Visible'),'on')
                                msg_pos(1:2)=GUI_pos(1:2)+obj_pos(1:2).*GUI_pos(3:4);
                                output_str=msgbox_uvmat(['uicontrol: ' get(hchild,'Tag')],'',get(hchild,'String'),msg_pos);
                                break
                            end
                        end
                    end
            end
            
        end
    end
    set(hObject,'Units','pixels')
    set(hchild,'String',output_str)
end