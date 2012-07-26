% 'FFT': calculate and display spectrum of the field selected in the GUI  get_field 
%  GUI_input=FFT(hget_field)
%
% OUTPUT: 
% GUI_input: option for display in the GUI get_field
%
%INPUT:
% hget_field: handles of the GUI get_field
%

function SubField=FFT2(hget_field)
%% set the input elements needed on the GUI get_field when the action is selected in the menu ActionName
if ~exist('hget_field','var') % case with no input parameter 
    SubField={'CheckPlot1D','off';...% enable simple x/y plot ('off'/'on')
        'CheckScalar','on';...%  enable scalar selection('off'/'on')
        'CheckVector','off'; ...%  enable vector selection('off'/'on')
               '',''};
        return
end
%%%%%%%%%%%%%%%%%%%%%%%%%

[SubField,errormsg]=read_get_field(hget_field);
SubField
for ilist=1:numel(SubField.ListVarName)
    if isfield(SubField.VarAttribute{ilist},'Role') && isequal(SubField.VarAttribute{ilist}.Role,'scalar')
        VarName=SubField.ListVarName{ilist};
        spec=abs(fft2(SubField.(VarName)-mean(mean(SubField.(VarName)))));
        SubField.(VarName)=log(spec);
    end
end
  
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['error in read_get_field input:' errormsg])
    return
end
SubField

