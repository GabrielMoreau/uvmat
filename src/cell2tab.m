%'cell2tab': transform a Matlab cell in a character array suitable for display in a table
%------------------------------------------------------------------------
% function Tabchar=cell2tab(Tabcell,separator) 
%
% OUTPUT:
% Tabchar: character array suitable for table display
%
% INPUT:
% Tabcell: (ni,nj) cell table, for ni lines 
% separator: character used for separating displayed columns

function Tabchar=cell2tab(Tabcell,separator) 
Tabchar={};%default
[ni,nj]=size(Tabcell);

%determine width of each column
widthcolumn=max(cellfun(@length,Tabcell));

%justify table
for itab=1:ni    
    charchain=[];         
    for jtab=1:nj% read line
        textlu=Tabcell{itab,jtab};
        if widthcolumn(jtab)>length(textlu)
            blankstr=char(32*ones(1,widthcolumn(jtab)-length(textlu)));
            textlu=[textlu blankstr];
        end
        if ~isempty(charchain)
            textlu=[separator textlu];
        end
        charchain=[charchain textlu];
    end
    Tabchar(itab,1)={charchain};
end

%nb : char(Tabchar(:,jtab)) gives directly a column with the blanks filled