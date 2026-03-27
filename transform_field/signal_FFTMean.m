% 'signal_spectrum': calculate and display spectrum of the current field 
%  operate on a 1D signal or the first dimension of a higher dimensional matrix (then average over other dimensions)
%  this function aplies the Welch method and call the function of the matlab signal processing toolbox
%
% OUTPUT: 
% DataOut: if DataIn.Action.RUN=0 (introducing parameters): Matlab structure containing the parameters
%          else transformed field, here not modified (the function just produces a plot on an independent fig)
%
% INPUT:
% DataIn: Matlab structure containing the input field from the GUI uvmat, DataIn.Action.RUN=0 to set input parameters. 
% Param: structure containing processing parameters, created when DataIn.Action.RUN=0 at the first use of the transform fct

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

function DataOut=signal_FFTMean(DataIn,Param)

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
        dlg_title = [mfilename ' calulates spectra along first dim ' VarDimName{s}{1}];% title of the input dialog fig
        prompt = {'not used'};% titles of the edit boxes
        %default input:
        def={'512'};% window length
        np=size(DataIn.(VarName));
        for idim=1:numel(np) % size restriction
            if idim==1
                prompt=[prompt;{['index range for spectral dim ' VarDimName{s}{idim}]}];% titles of the edit boxes
            else
            prompt=[prompt;{['index range for ' VarDimName{s}{idim}]}];% titles of the edit boxes
            end
            def=[def;{num2str([1 np(idim)])}];
        end
        if isfield(Param,'TransformInput')
            if isfield(Param.TransformInput,'WindowLength')
                def{1}=num2str(Param.TransformInput.WindowLength);
            end
            if isfield(Param.TransformInput,'IndexRange')
                for ilist=1:min(numel(np),size(Param.TransformInput.IndexRange,1))
                    def{ilist+1}=num2str(Param.TransformInput.IndexRange(ilist,:));
                end
            end
        end
        num_lines= 1;%numel(prompt);
        % open the dialog fig
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        DataOut.TransformInput.WindowLength=str2num(answer{1});
        for ilist=1:numel(answer)-1
            DataOut.TransformInput.IndexRange(ilist,1:2)=str2num(answer{ilist+1});
        end
    end
    return
end

%% retrieve parameters
DataOut=DataIn;
WindowLength=Param.TransformInput.WindowLength;

%% get the variable to process
Var= DataIn.(Param.TransformInput.VariableName);%variable to analyse
if isfield(Param.TransformInput,'IndexRange')
    IndexRange=Param.TransformInput.IndexRange;
    switch size(IndexRange,1)
        case 3
            Var=Var(IndexRange(1,1):IndexRange(1,2),IndexRange(2,1):IndexRange(2,2),IndexRange(3,1):IndexRange(3,2));
        case 2
            Var=Var(IndexRange(1,1):IndexRange(1,2),IndexRange(2,1):IndexRange(2,2));
        case 1
            Var=Var(IndexRange(1,1):IndexRange(1,2));
    end
end
np=size(Var);%dimensions of Var
if ~isvector(Var)
    Var=reshape(Var,np(1),prod(np(2:end)));% reshape in a 2D matrix with time as first index
end
Var=Var-ones(np(1),1)*nanmean(Var,1); %substract mean value (excluding NaN) 

%% look for 'time' coordinate
VarIndex=find(strcmp(Param.TransformInput.VariableName,DataIn.ListVarName));
TimeDimName=DataIn.VarDimName{VarIndex}{1};
TimeVarNameIndex=find(strcmp(TimeDimName,DataIn.ListVarName));
if isempty(TimeVarNameIndex)
    Time=1:np(1);
    TimeUnit='vector index';
else
    Time=DataIn.(DataIn.ListVarName{TimeVarNameIndex});
    TimeUnit=['Unit of ' TimeDimName];
end
% check time intervals
diff_x=diff(Time);
dx=min(diff_x);
freq_max=1/(2*dx);
check_interp=0;
if diff_x>1.001*dx % non constant time interval
    check_interp=1;
end

%% claculate the spectrum
specmean=0;% mean spectrum initialisation
cospecmean=0;
NbNan=0;
NbPos=0;
np_freq=floor(size(Var,1)/2);
for pos=1:size(Var,2)
    sample=Var(:,pos);%extract sample to analyse
    ind_bad=find(isnan(sample));
    ind_good=find(~isnan(sample));
%     if numel(ind_good)>WindowLength
        NbPos=NbPos+1;
        if ~isempty(ind_bad)
            sample=sample(ind_good); % keep only  non NaN data
            NbNan=NbNan+numel(ind_bad);
        end
        %interpolate if needed
        if ~isempty(ind_bad)||check_interp
            sample=interp1(Time(ind_good),sample,(Time(1):dx:Time(end))); %interpolated func
            sample(isnan(sample))=[];
        end
        
        fourier=fft(sample);%take fft (complex)
        spec=abs(fourier).*abs(fourier);% take square of the modulus
        spec=spec(1:np_freq,:);%keep only the first half (the other is symmetric)
        specmean=spec+specmean;
%     end
end
specmean=specmean/NbPos;

%plot spectrum in log log
hfig=findobj('Tag','fig_spectrum');
if isempty(hfig)% create spectruim figure if it does not exist
    hfig=figure;
    set(hfig,'Tag','fig_spectrum');
else
    figure(hfig)
end
loglog(freq_max*(1:length(specmean))/length(specmean),specmean)
set(gca,'YLim',[1.0000e-06*max(specmean) 1.1*max(specmean)])
title (['power spectrum of ' Param.TransformInput.VariableName ])
xlabel(['frequency (cycles per ' TimeUnit ')'])
ylabel('spectral intensity')
legend({'spectrum','cospectrum t t-1'})
get(gca,'Unit')
sum(specmean)
if NbPos~=size(Var,2)
    disp([ 'warning: ' num2str(size(Var,2)-NbPos) ' NaN sampled removed'])
end
if NbNan~=0
    disp([ 'warning: ' num2str(NbNan) ' NaN values replaced by linear interpolation'])
%text(0.9, 0.5,[ 'warning: ' num2str(NbNan) ' NaN values removed'])
end
grid on


