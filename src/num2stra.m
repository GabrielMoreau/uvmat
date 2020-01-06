%'num2stra': transform number to the corresponding character string depending on the nomenclature
%--------------------------------------------
% function str=num2stra(num,nom_type,index)
%
% OUTPUT: 
% str: character string
%
% INPUT:
% num: input number (file index)
% nom_type: nomencalture type (see fct name_generator)
% index: 1 or 2 (first or secodn index in file naming)
% see also: stra2num, name_generator, name2display

%=======================================================================
% Copyright 2008-2020, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function str=num2stra(num,nom_type,index)
str='';
if ~exist('index','var')
    index=2; %index 1 or 2 of the file indices
end
switch index
    case 1
%         if length(nom_type)>=4 && isequal(nom_type(1:2),'%0') && isequal(nom_type(4),'d') 
%            str=num2str(num,nom_type(1:4)); 
%         else
           str=num2str(num); 
%         end
    case 2
        if ~isempty(nom_type) && (isequal(nom_type(end),'a')||isequal(nom_type(end),'b'))
            str=char(96+num);
        elseif ~isempty(nom_type) && (isequal(nom_type(end),'A')||isequal(nom_type(end),'B'))
            str=char(64+num);
        else
            str=num2str(num);
        end
end
