% 'signal_low_pass_filter': low pass filter of input  signals

% OUTPUT: 
% DataOut: Matlab structure representing the output (filtered) field
%
%INPUT:
% DataIn: Matlab structure representing the input field

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

function DataOut=signal_bandpass_filter(DataIn,Param)

%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
        [DataOut.TransformInput,errormsg] = set_param_input({'WindowLength'},{11},Param)  
    return
end
DataOut=DataIn; 
WindowLength=Param.TransformInput.WindowLength;
HalfLength=floor(WindowLength/2);
WindowLength=2*HalfLength+1;
WindowLength=2*ceil(WindowLength/2);%set to the closes upper value
B=ones(1,WindowLength)/WindowLength;
for ivar=2:numel(DataIn.ListVarName)
    VarName=DataIn.ListVarName{ivar};
    DataOut.(VarName)=filter(B,1,DataIn.(VarName));%teke the sliding average on WindowLength values
end
CoordName=DataIn.ListVarName{1};
FirstX=DataIn.(CoordName)(1);
DataOut.(CoordName)=circshift(DataIn.(CoordName),HalfLength);% shift the x coordinate to compensate phase shift produced by the filter
DataOut.(CoordName)(1:HalfLength)=FirstX;



