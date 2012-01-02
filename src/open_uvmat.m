% 'open_uvmat': open with uvmat the  field selected in the list of 'civ/status' or 'series/check_data_files'
%------------------------------------------------------------------------
%function open_uvmat(hObject, eventdata)
%
% INPUT: 
% hObject: handle of uicontrol object containing the list 
% eventdata: not used
function open_uvmat(hObject, eventdata)
%------------------------------------------------------------------------
list=get(hObject,'String');
index=get(hObject,'Value');
rootroot=get(hObject,'UserData');
filename=list{index};
ind_dot=strfind(filename,'...');
if ~isempty(ind_dot)
filename=filename(1:ind_dot-1);
end
filename=fullfile(rootroot,filename);
if exist(filename,'file')%visualise the vel field if it exists
    uvmat(filename)
    set(gcbo,'Value',1)
    delete(get(hObject,'parent'))%delete the display figure to stop the check process
end