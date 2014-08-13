%=======================================================================
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function [i1,i2,j1,j2] = get_file_index(ref_i,ref_j,PairString)
%get the first file name set by the GUI series

if iscell(PairString)
    PairString=PairString{1};
end
i1=ref_i;
j1=ref_j;
i2=ref_i;
j2=ref_j;
% case of pairs
if ~isempty(PairString)
    r=regexp(PairString,'(?<mode>(Di=)|(Dj=)) -*(?<num1>\d+)\|(?<num2>\d+)','names');
    if isempty(r)
        r=regexp(PairString,'(?<num1>\d+)(?<mode>-)(?<num2>\d+)','names');
    end
    switch r.mode
        case 'Di='  %  case 'series(Di)')
            i1=ref_i-str2num(r.num1);
            i2=ref_i+str2num(r.num2);
        case 'Dj='  %  case 'series(Dj)'
            j1=ref_j-str2num(r.num1);
            j2=ref_j+str2num(r.num2);
        case '-'  % case 'bursts'
            j1=str2num(r.num1)*ones(size(ref_i));
            j2=str2num(r.num2)*ones(size(ref_i));
    end
end





