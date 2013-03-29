%'nomtype2pair': creates nomencalture for index pairs knowing the image nomenclature, used by series fct
%---------------------------------------------------------------------
% NomTypeOut=nomtype2pair(NomTypeIn)
%---------------------------------------------------------------------           
% OUTPUT:
% NomTypeOut: file index nomenclature for pairs
%---------------------------------------------------------------------
% INPUT:
% NomTypeIn: file index nomenclature for images 
% 
% for definitions of file index nomenclature, see fct fullfile_uvmat

function NomTypeOut=nomtype2pair(NomTypeIn)

if ~isempty(regexp(NomTypeIn,'a$'))
    NomTypeOut=[NomTypeIn 'b'];
elseif ~isempty(regexp(NomTypeIn,'A$'))
    NomTypeOut=[NomTypeIn 'B'];
else
    r=regexp(NomTypeIn,'(?<num1>\d+)_(?<num2>\d+)$','names');
    % case of a single input index (no j)
    if isempty(r)
        NomTypeOut='_1-2';
    else  % case of two indices i,j, separated by '_'
        NomTypeOut='_1-2_1-2';
    end
end
