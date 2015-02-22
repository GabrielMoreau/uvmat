%'diff_vel': calculate the difference of two input velocity fields. 
%
% the second velocity field is linearly interpolated 
% (after elimination of the vectors marked with an error flag) to the positions of
% the first one before subtraction. The ancilary data of the first field
% are preserved while those of the second one are lost. 

%-----------------------------------------------------------------------
% function SubData=diff_vel(Field,XmlData,Field_1)
%
% OUPUT: 
% SubData: structure representing the resulting field
%
% INPUT: 
% Field: matlab structure representing the first field
% XmlData: not used, needed for consistency with the call of transform fct.
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

function SubData=diff_vel(Field,XmlData,Field_1)

SubData=Field;
if exist('Field_1','var')
          F.U=scatteredInterpolant(Field_1.X,Field_1.Y,Field_1.U,'linear');
         SubData.U=Field.U-F.U(Field.X,Field.Y);%substract the interpolated ref to U
          F.V=scatteredInterpolant(Field_1.X,Field_1.Y,Field_1.V,'linear');
          SubData.V=Field.V-F.V(Field.X,Field.Y);%substract the interpolated ref to V
end
  