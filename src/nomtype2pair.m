%'nomtype2pair': creates nomenclature for index pairs knowing the image nomenclature, used by series fct
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

%=======================================================================
% Copyright 2008-2018, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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
