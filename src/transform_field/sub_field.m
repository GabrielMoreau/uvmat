%'sub_field': combines two input fields, taking the difference if of the same nature
%
% the two fields are subtracted when of the same nature (scalar or
% vector),and defined at the same points
%
% when scalar and vectors are combined, the fields are just merged in a single matlab structure for common visualisation
%-----------------------------------------------------------------------
% function SubData=sub_field(Field,XmlData,Field_1)
%
% OUPUT: 
% SubData: structure representing the resulting field
%
% INPUT: 
% Field: matlab structure representing the first field
% Field_1:matlab structure representing the second field

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

function SubData=sub_field(Field,XmlData,Field_1)
if exist('Field_1','var')
SubData=sub_field(Field,XmlData,Field_1);
else
    SubData=[];
end
