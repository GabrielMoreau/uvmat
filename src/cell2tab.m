%'cell2tab': transform a Matlab cell in a character array suitable for display in a table
% INPUT:
% Tabcell: (nx,ny) cell table, for nx lines
% separator: character used for separating displayed columns
function Tabchar=cell2tab(Tabcell,separator) 
Tabchar={};%default
[nx,ny]=size(Tabcell);
%determine width withcolumn(jtab) of each column
for jtab=1:ny 
    widthcolumn(jtab)=0;%default
    for itab=1:nx% read line
        if widthcolumn(jtab)<length(Tabcell{itab,jtab})
            widthcolumn(jtab)=length(Tabcell{itab,jtab});
        end
    end
end
%justify table
for itab=1:nx    
    charchain=[];         
    for jtab=1:ny% read line
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
    %Tabchar(itab)={charchain};
    Tabchar(itab,1)={charchain};
end