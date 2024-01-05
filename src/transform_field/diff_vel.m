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
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function Field=diff_vel(Field,XmlData,Field_1)

%% request input parameters
if isfield(Field,'Action') && isfield(Field.Action,'RUN') && isequal(Field.Action.RUN,0)

        %default input:
        def={'1'};% multiplicative factor for the second velocity field 

        if isfield(XmlData,'TransformInput')% if parameters have been memorised
            if isfield(XmlData.TransformInput,'Factor')
                def{1}=num2str(XmlData.TransformInput.Factor);
            end
        end
        num_lines= 1;%numel(prompt);
        % open the dialog fig
        prompt='enter scale factor for the second field';
        answer = inputdlg(prompt,'',num_lines,def);
        Field.TransformInput.Factor=str2num(answer{1});
    return
end
Factor=1;
if isfield(XmlData,'TransformInput') && isfield(XmlData.TransformInput,'Factor') 
Factor=XmlData.TransformInput.Factor;
end
if exist('Field_1','var')
          F.U=scatteredInterpolant(Field_1.X,Field_1.Y,Field_1.U,'linear');
         Field.U=Field.U-Factor*F.U(Field.X,Field.Y);%substract the interpolated ref to U
          F.V=scatteredInterpolant(Field_1.X,Field_1.Y,Field_1.V,'linear');
          Field.V=Field.V-Factor*F.V(Field.X,Field.Y);%substract the interpolated ref to V
end
  