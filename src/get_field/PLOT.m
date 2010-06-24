%---------------------------------------------------------
% --- Executes on button press in RUN.
function SubField=PLOT(hget_field)
%---------------------------------------------------------
SubField=[]; %default
if ~exist('hget_field','var')
    return
end
[SubField,errormsg]=read_get_field(hget_field);
% SubField.VarAttribute{1}
% SubField.VarAttribute{2}
% SubField.VarAttribute{3}
% 
% SubField.VarDimName{1}
% SubField.VarDimName{2}
% SubField.VarDimName{3}

if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['error in read_get_field/PLOT input:' errormsg])
end
