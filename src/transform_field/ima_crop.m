% 'ima_crop': removes an upper and lower band to the image

%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input and parameters %%%%
% OUTPUT: 
% DataOut:   output field structure 
%
%INPUT:
% DataIn:  input field structure
% Param: matlab structure whose field Param.TransformInput contains the filter parameters
%-----------------------------------

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function DataOut=ima_crop(DataIn,Param)

%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    prompt = {'npy_upper';'npy_lower'};
    dlg_title = 'remove image lines above and below';
    num_lines= 2;
    def     = { '0';'0'};
    if isfield(Param,'TransformInput')&&isfield(Param.TransformInput,'CropUpper')&&...
            isfield(Param.TransformInput,'CropLower')
        def={num2str(Param.TransformInput.CropUpper);num2str(Param.TransformInput.CropLower)};
    end
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    DataOut.TransformInput.CropUpper=str2num(answer{1}); %size of the filtering window
    DataOut.TransformInput.CropLower=str2num(answer{2}); %size of the filtering window
    return
end

DataOut=DataIn; %default

DataOut.A(1:Param.TransformInput.CropUpper,:)=[];
DataOut.A(end-Param.TransformInput.CropLower+1:end,:)=[];
 
