%---------------------------------------------------------
% --- Executes on button press in RUN.
function PLOT(hget_field)
%---------------------------------------------------------
[SubField,errormsg]=read_get_field(hget_field);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['error in read_get_field/PLOT input:' errormsg])
    return
end
handles=guidata(hget_field);
list_fig=get(handles.list_fig,'String');
val=get(handles.list_fig,'Value');
if strcmp(list_fig{val},'uvmat')
    uvmat(SubField)
else
    hfig=str2num(list_fig{val});% chosen figure number from tyhe GUI
    if isempty(hfig)
        hfig=figure;
        list_fig=[list_fig;num2str(hfig)];
        set(handles.list_fig,'String',list_fig);
        haxes=axes;
    else
        figure(hfig);
    end
    haxes=findobj(hfig,'Type','axes');
    plot_field(SubField,haxes) 
end
