% 'signal_band_filter': example of pass-band filter (using the signal toolbox fct fdesign)
% frequency and bandwidth need to be modified in the function
%
% OUTPUT: 
% DataOut: Matlab structure representing the output (filtered) field
%
%INPUT:
% DataIn: Matlab structure representing the output field

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

function DataOut=signal_bandpass_filter(DataIn)
%% set GUI config
DataOut=[];
if strcmp(DataIn,'*')   
    DataOut.InputFieldType='1D';
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%
frequency=2*5/54.5;% frequency at which the signal needs to be filetered
 %d=fdesign.bandpass(0.8*frequency, 0.95*frequency, 1.05*frequency, 1.2*frequency, 60, 1, 60);
 d=fdesign.bandpass(0.7*frequency, 0.9*frequency, 1.1*frequency, 1.3*frequency, 60, 1, 60);
 Hd=design(d);% command  fvtool(Hd) to visualize the filter frequency response
 DataOut=DataIn;
 if isfield(DataIn,'U')
 DataOut.U = filter(Hd,DataIn.U);
 end
  if isfield(DataIn,'V')
 DataOut.V = filter(Hd,DataIn.V);
 end

