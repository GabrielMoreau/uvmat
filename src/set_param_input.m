% set_param_input: set input parameters for transform functions
%OUTPUT: 
% ParamOut: structure with parameter values
%INPUT:
% LisParam: list of parameter names (cell array)
% DefaultValue: default values of the parameters in the absence of other input 
% ParamIn: default values set by the structure ParamIn


function [ParamOut,errormsg] = set_param_input(ListParam,DefaultValue,ParamIn,Title)
ParamOut=[];
errormsg=[];
NbParam=numel(ListParam);
if numel(DefaultValue)~=NbParam
    errormsg='ERROR in set_param_input: the list of default values must have the same size as the list of parameters';
    return
end
if ~exist('Title','var')
    Title='get the input parameters';
end
prompt=cell(NbParam,1);
checknumeric=zeros(NbParam,1);
for ilist=1:numel(ListParam)
    if isfield(ParamIn,ListParam{ilist})
        prompt{ilist}=ParamIn.(ListParam{ilist});
    else
        prompt{ilist}=DefaultValue{ilist};
    end
    if isnumeric(prompt{ilist})
        checknumeric(ilist)=1;
        prompt{ilist}=num2str(prompt{ilist});
    end
end
options.Resize='on';
options.WindowStyle='normal';
answer = inputdlg(ListParam,Title,1,prompt,options);
if isempty(answer)
    return
end
for ilist=1:NbParam
    if checknumeric(ilist)
        answer{ilist}=str2num(answer{ilist});
    end
    ParamOut.(ListParam{ilist})=answer{ilist};
end
 