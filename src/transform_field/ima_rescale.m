% 'ima_green': take the gree component of a color image
%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input %%%%
% OUTPUT: 
% DataOut:   output field structure 
%
%INPUT:
% DataIn:  first input field structure

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

function DataOut=ima_rescale(DataIn,Param)

%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    prompt = {'SaturationValue'};
    dlg_title = 'get the maximum image value';
    num_lines= 1;
    def     = { '1024'};
    if isfield(Param,'TransformInput')&&isfield(Param.TransformInput,'SaturationValue')
        def={num2str(Param.TransformInput.SaturationValue)};
    end
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    DataOut.TransformInput.SaturationValue=str2num(answer{1}); %size of the filtering window
    return
end

Coeff=Param.TransformInput.SaturationValue;
DataOut=DataIn; %default
if isfield(DataOut,'A')
    DataOut.A=uint16(Coeff*tanh(double(DataOut.A)/Coeff));
end
if isfield(DataOut,'ImageA')
    DataOut.ImageA=uint16(Coeff*tanh(double(DataOut.ImageA)/Coeff));
end
if isfield(DataOut,'ImageB')
    DataOut.ImageB=uint16(Coeff*tanh(double(DataOut.ImageB)/Coeff));
end

 
