%---------------------------------------------------------
% --- Executes on button press in RUN.
function SubField=PLOT(hget_field)
%---------------------------------------------------------
SubField=[]; %default
if ~exist('hget_field','var')
    return
end
[SubField,errormsg]=read_get_field(hget_field);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['error in read_get_field/PLOT input:' errormsg])
end
