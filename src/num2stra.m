%'num2stra': transform number to the corresponding character string depending on the nomenclature
%--------------------------------------------
% function str=num2stra(num,nom_type)
%
% OUTPUT: 
% str: character string
%
% INPUT:
% num: input number (file index)
% nom_type: nomencalture type (see fct name_generator)
%
% see also: stra2num, name_generator, name2display

function str=num2stra(num,nom_type,index)
if ~exist('index','var')
    index=2; %index 1 or 2 of the file indices
end
switch index
    case 1
        if length(nom_type)>=4 && isequal(nom_type(1:2),'%0') && isequal(nom_type(4),'d') 
           str=num2str(num,nom_type(1:4)); 
        else
           str=num2str(num); 
        end
    case 2
        if isempty(nom_type)
            nom_type='none';
        end
        if isequal(nom_type,'png_old') || isequal(nom_type,'netc_old') || isequal(nom_type,'raw_SMD')||...
            isequal(nom_type(end),'a')||isequal(nom_type(end),'b')
            str=char(96+num);
        elseif isequal(nom_type(end),'A')|isequal(nom_type(end),'B')
            str=char(64+num);
        elseif isequal(nom_type,'series_i')|isequal(nom_type,'netc_series')...
                |isequal(nom_type,'ima_num')| isequal(nom_type,'avi')| isequal(nom_type,'none')...
                isequal(nom_type,'_i')|isequal(nom_type,'_i1-i2')
            str='';
        else
            str=num2str(num);
        end
end