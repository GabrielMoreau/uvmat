%'copyfields' copy fields between two matlab structures
%------------------------------------------------------------------------
% OUTPUT:
% NewData: resulting structure
%
% INPUT:
% listfields: cell arrays representing the list of field names to be copied
% SourceData: structure containing the source data to copy in NewData
% OldData: (optional) preexisting data structure.

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
