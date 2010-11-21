%'cell2tab': transform a Matlab cell in a character array suitable for display in a table
%------------------------------------------------------------------------
% function Tabchar=cell2tab(Tabcell,separator) 
%
% OUTPUT:
% Tabchar: column cell of char strings suitable for display (equal length)
%
% INPUT:
% Tabcell: (ni,nj) cell matrix of char strings to be displayed as  ni lines , nj column
% separator: char string used for separating displayed columns

function Tabchar=cell2tab(Tabcell,separator) 
[ni,nj]=size(Tabcell);

%determine width of each column
if isequal(ni,1)
    widthcolumn=cellfun('length',Tabcell);% case of a single line, no justification used
else
    widthcolumn=max(cellfun('length',Tabcell));
end
lsep=numel(separator); %nbre of characters of the separator
nbchar_line=(sum(widthcolumn)+(nj-1)*lsep); %total nbre of characters in each output line
default_line=blanks(nbchar_line); %default blank line
Tabmat=reshape(blanks(nbchar_line*ni),ni,nbchar_line);
Tabchar=mat2cell(Tabmat,ones(1,ni),nbchar_line); %default output

%justify table
for itab=1:ni    
    charchain=default_line;  
    for jtab=1:nj% read line
        textlu=Tabcell{itab,jtab};
        if jtab==1
            charchain(1:length(textlu))=textlu;%introduce separator chain string except for the first column
            ind_column=widthcolumn(1);%new current char index in the line
        else
            charchain(ind_column+1:ind_column+lsep)=separator;%introduce separator chain string except for the first column
            charchain(ind_column+lsep+1:ind_column+lsep+length(textlu))=textlu;%introduce separator chain string except for the first column
            ind_column=ind_column+widthcolumn(jtab)+lsep;
        end
    end
    Tabchar(itab,1)={charchain};
end
