% 'signal_band_filter': example of pass-band filter (using the signal toolbox fct fdesign)
% frequency and bandwidth need to be modified in the function
%
% OUTPUT: 
% DataOut: Matlab structure representing the output (filtered) field
%
%INPUT:
% DataIn: Matlab structure representing the output field

%=======================================================================
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function DataOut=signal_bandpass_filter(DataIn,Param)

%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    VarNbDim=cellfun('length',DataIn.VarDimName);
    [tild,rank]=sort(VarNbDim,2,'descend');% sort the list of input variables, putting the ones with higher dimensionality first
    ListVarName=DataIn.ListVarName(rank);
    VarDimName=DataIn.VarDimName(rank);
    InitialValue=1;%default choice
    if isfield(Param,'TransformInput') && isfield(Param.TransformInput,'VariableName')
        val=find(strcmp(Param.TransformInput.VariableName,ListVarName));
        if ~isempty(val);
            InitialValue=val;
        end
    end
    [s,OK] = listdlg('PromptString','Select the variable to process:',...
        'SelectionMode','single','InitialValue',InitialValue,...
        'ListString',ListVarName);
    if OK==1
        VarName=ListVarName{s};
        DataOut.TransformInput.VariableName=VarName;
        dlg_title = [mfilename ' filter signal along first dim ' VarDimName{s}{1}];% title of the input dialog fig
        prompt = {'central filtering frequency';'bandwith (relative to the central frequency) '};% titles of the edit boxes
        %default input:
        def={'';'0.1'};% filtering frequency and relative bandwidth

        if isfield(Param,'TransformInput')% if parameters have been memorised
            if isfield(Param.TransformInput,'CentralFrequency')
                def{1}=num2str(Param.TransformInput.CentralFrequency);
            end
            if isfield(Param.TransformInput,'BandWidth')
                 def{2}=num2str(Param.TransformInput.BandWidth);
            end
        end
        num_lines= 1;%numel(prompt);
        % open the dialog fig
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        DataOut.TransformInput.CentralFrequency=str2num(answer{1});
        DataOut.TransformInput.BandWidth=str2num(answer{2});
    end
    return
end



%% set GUI config
DataOut=[];
if strcmp(DataIn,'*')   
    DataOut.InputFieldType='1D';
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%
frequency=Param.TransformInput.CentralFrequency;% frequency at which the signal needs to be filetered
Bw=Param.TransformInput.BandWidth;
 DataOut=DataIn;
 %d=fdesign.bandpass(0.8*frequency, 0.95*frequency, 1.05*frequency, 1.2*frequency, 60, 1, 60);
 d=fdesign.bandpass((1-2*Bw)*frequency, (1-Bw)*frequency, (1+Bw)*frequency, (1+2*Bw)*frequency, 60, 1, 60);
 Hd=design(d);% command  fvtool(Hd) to visualize the filter frequency response

 if isfield(DataIn,'U')
 DataOut.U = filter(Hd,DataIn.U);
 end
  if isfield(DataIn,'V')
 DataOut.V = filter(Hd,DataIn.V);
 end

