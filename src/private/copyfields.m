%'copyfields' copy fields between two matlab structures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUPUT:
% NewData: resulting structure
%
%INPUT:
% listfields: cell arrays representing the list of field names to be copied
% SourceData: structure containing the source data to copy in NewData
% OldData: (optional) preexisting data structure.

function NewData=copyfields(listfields,SourceData,OldData)
if ~exist('OldData','var')
    OldData=[];
end
NewData=OldData;%default
for ifield=1:length(listfields)
    if isfield(SourceData,listfields{ifield}) & ~isempty(eval(['SourceData.' listfields{ifield}]))
        eval(['NewData.' listfields{ifield} '=SourceData.' listfields{ifield} ';']); 
    elseif isfield(OldData,listfields{ifield})
        NewData=rmfield(NewData,listfields{ifield});
    end
end