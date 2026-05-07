%'ima_sub_color': subtract the second image to the sum of the color components of the first image
%
% the two fields are subtstracted when of the same nature (scalar or
% vector), if the coordinates do not coincide, the second field is
% interpolated on the cooridintes of the first one
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
% XmlData: input calibration parameter, not used
% Field_1:matlab structure representing the second field

%=======================================================================
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function DataOut=ima_sub_color(DataIn,XmlData,DataIn_1)

%% option to introduce input parameters when function is selected, skipped here
DataOut=DataIn;


%% actual calculation
if exist('DataIn_1','var')

    DataOut.A=sum(double(DataIn.A),3)-double(DataIn_1.A);
end
