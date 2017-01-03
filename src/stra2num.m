%'stra2num': transform letters (a, b, c) or numerical strings ('1','2'..) to the corresponding numbers
%--------------------------------------------
%  function numres=stra2num(str)
%
% OUTPUT: 
% numres: number (double)
%
% INPUT:
% str: string corresponding to a number or a letter 'a' 'b',.., otherwise the output is empty
%
% see also num2stra, name_generator, name2display

%=======================================================================
% Copyright 2008-2017, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function numres=stra2num(str)
numres=[]; %default
if double(str) >= 48 & double(str) <= 57 % = test for number strings
    numres=str2double(str);
elseif double(str) >= 65 & double(str) <= 90 % test on ascii code for capital letters
    numres=double(str)-64; %change capital letters to corresponding number in the alphabet
elseif double(str) >= 97 & double(str) <= 122 % test on ascii code for small letters 
    numres=double(str)-96; %change small letters to corresponding number in the alphabet
end
