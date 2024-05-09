%'test_patch_tps': test the optimum value for the spline smmoothing function used in civ_series
%------------------------------------------------------------------------
% Method: 
    %open a netcdf file with civ results. 
    
% function ParamOut=test_patch_tps (Param)
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%OUTPUT
% ParamOut: sets input parameters when the function is selected, not activated(input Param.Action.RUN=0),=[] when the function is running
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% when Param.Action.RUN=0 (as activated when the current Action is selected
% in series), the function ouput paramOut set the activation of the needed GUI elements
%
% Param contains the elements:(use the menu bar command 'export/GUI config' in series to 
% see the current structure Param)
%    .InputTable: cell of input file names, (several lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDirExt: directory extension for data outputs
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%             .ActionExt: fct extension ('.m', Matlab fct, '.sh', compiled   Matlab fct
%             .RUN =0 for GUI input, =1 for function activation
%             .RunMode='local','background', 'cluster': type of function  use
%             
%    .IndexRange: set the file or frame indices on which the action must be performed
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function ParamOut=test_patch_tps (Param)

%%%%%%%%%%%%%%%%%    INPUT PREPARATION MODE (no RUN)    %%%%%%%%%%%%%%%%%
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; % edit box nbre of slices made active
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%cannot use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.test_patch';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    
    %% root input file(s) and type
    % check the existence of the first file in the series
     first_j=[];% note that the function will propose to cover the whole range of indices
    if isfield(Param.IndexRange,'MinIndex_j'); first_j=Param.IndexRange.MinIndex_j; end
    last_j=[];
    if isfield(Param.IndexRange,'MaxIndex_j'); last_j=Param.IndexRange.MaxIndex_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('WARNING',['the first input file ' FirstFileName ' does not exist'])
        return
    else
        [i1,i2,j1,j2] = get_file_index(Param.IndexRange.last_i,last_j,PairString);
        LastFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
        if ~exist(FirstFileName,'file')
             msgbox_uvmat('WARNING',['the last input file ' LastFileName ' does not exist'])
        end
    end

    %% check the validity of  input file types
    Data=nc2struct(FirstFileName,[]);
    if isfield(Data,'CivStage')
        switch Data.CivStage
            case {1,2}
                CivStage='civ1';
                MaxDiff=1.5; SubDomainSize=250; FieldSmooth=10; %default
            case 3
                CivStage='civ1';
                MaxDiff=Data.Patch1_MaxDiff;
               SubDomainSize=Data.Patch1_SubDomainSize;
               FieldSmooth=Data.Patch1_FieldSmooth;
            case {4,5}
                CivStage='civ2';
                MaxDiff=1.5; SubDomainSize=250; FieldSmooth=5; %default
            case 6
                CivStage='civ2';
                 MaxDiff=Data.Patch2_MaxDiff;
               SubDomainSize=Data.Patch2_SubDomainSize;
               FieldSmooth=Data.Patch2_FieldSmooth;
        end
    else
        msgbox_uvmat('ERROR',['invalid file type input: ' FileType ' not a civ data'])
        return
    end

    %% numbers of fields
    incr_j=1;%default
    if isfield(Param.IndexRange,'incr_j')&&~isempty(Param.IndexRange.incr_j)
        incr_j=Param.IndexRange.incr_j;
    end
    if isempty(first_j)||isempty(last_j)
        nbfield_j=1;
    else
        nbfield_j=numel(first_j:incr_j:last_j);%nb of fields for the j index (bursts or volume slices)
    end
    first_i=1;last_i=1;incr_i=1;%default
    if isfield(Param.IndexRange,'MinIndex_i'); first_i=Param.IndexRange.MinIndex_i; end   
    if isfield(Param.IndexRange,'MaxIndex_i'); last_i=Param.IndexRange.MaxIndex_i; end
    if isfield(Param.IndexRange,'incr_i')&&~isempty(Param.IndexRange.incr_i)
        incr_i=Param.IndexRange.incr_i;
    end
    nbfield_i=numel(first_i:incr_i:last_i);%nb of fields for the i index (bursts or volume slices)
    nbfield=nbfield_j*nbfield_i; %total number of fields
    
    %% setting of intput parameters 
    ListParam={'CivStage';'FieldSmooth';'MaxDiff';'SubDomainSize'};
    DefaultValue={CivStage;FieldSmooth;MaxDiff;SubDomainSize};
    if isfield(Param,'ActionInput')
        ParamIn=Param.ActionInput;
    else
        ParamIn=[];
    end
        [ParamOut.ActionInput,errormsg] = set_param_input(ListParam,DefaultValue,ParamIn);
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',errormsg)
        end
    return
end
%%%%%%%%%%%%%%%%%    STOP HERE FOR PAMETER INPUT MODE   %%%%%%%%%%%%%%%%% 

%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
RUNHandle=[];
WaitbarHandle=[];
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
else
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
end

%% input preparation
RootPath=Param.InputTable{:,1};
RootFile=Param.InputTable{:,3};
NomType=Param.InputTable{:,4};
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% if ~isempty(hdisp),delete(hdisp),end;
%%%%%%%%%%%%
    % The cell array filecell is the list of input file names, while
    % filecell{iview,fileindex}:
    %        iview: line in the table corresponding to a given file series
    %        fileindex: file index within  the file series,
    % i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j
    % i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%%

%% output file naming
FileExtOut='.nc'; % write result as .png images for image inputsFileInfo.FileType='image'
NomTypeOut=NomType;
OutputDir=[Param.OutputSubDir Param.OutputDirExt];
OutputPath=fullfile(Param.OutputPath,Param.Experiment,Param.Device);
RootFileOut=RootFile;

%% file index parameters

Param.InputFields.VelType=Param.ActionInput.CivStage;
SubDomainSize=Param.ActionInput.SubDomainSize;
MaxDiff=Param.ActionInput.MaxDiff;
FieldSmooth=(Param.ActionInput.FieldSmooth)*[0.1 0.2 0.5 1 2 5 10];%scan the smoothing param from 1/10 to 10 current value
NbSmooth=numel(FieldSmooth);
for irho=1:NbSmooth
    str=num2str(FieldSmooth(irho));
    str=regexprep(str,'\.','p');
    Ustr{irho}=['U_' str];
    Vstr{irho}=['V_' str];
    Xstr{irho}=['X_' str];
    Ystr{irho}=['Y_' str];
    Dimstr{irho}='NbVec';
    str_i{irho}=str;
end

%% Prepare the structure of output netcdf file
DataOut.ListGlobalAttribute={'CivStage','SubDomainSize','MaxDiff','CoordUnit'};
DataOut.CivStage=Param.InputFields.VelType;
DataOut.SubDomainSize=SubDomainSize;
DataOut.MaxDiff=MaxDiff;
DataOut.CoordUnit='pixel';
DataOut.ListVarName=[{'FieldSmooth','Diff_rms','NbExclude','X','Y'} Ustr Vstr] ;
DataOut.VarDimName=[{'FieldSmooth','FieldSmooth','FieldSmooth','NbVec','NbVec'} Dimstr Dimstr]; 
DataOut.VarAttribute{4}.Role='falseflag';
DataOut.FieldSmooth=FieldSmooth;

%% MAIN LOOP
for index=1:1%numel(filecell)
    Data=read_field(filecell{1,index},'civdata',Param.InputFields);
            ind_good=find(Data.FF==0|Data.FF==20|Data.FF==2);%keep good civ data, and also the ones excluded by the criterium of discrepancy betwween smoothed and raw fields (FF=2 or 20 (old convention))
        NbGood=numel(ind_good);
        Xin=Data.X(ind_good);
        Yin=Data.Y(ind_good);
        Uin=Data.U(ind_good);
        Vin=Data.V(ind_good);
        tic
    for irho=1:NbSmooth
        [SubRange,NbCentres,Coord_tps,U_tps,V_tps,~,U_smooth, V_smooth,~,FFres]=...
            filter_tps([Xin Yin],Uin,Vin,[],SubDomainSize,FieldSmooth(irho),MaxDiff);
        if irho==1
            DataOut.FF=zeros(size(Xin));
            DataOut.X=Xin;
            DataOut.Y=Yin;
        figure(1)
            cla
            scatter(Xin,Yin,1)
            for irec=1:size(SubRange,3)
                rectangle('Position',[SubRange(:,1,irec)' SubRange(:,2,irec)'-SubRange(:,1,irec)'])
            end       
            title('subdomains for thin shell splines (tps)')
        end
        ind_good=find(FFres==0);
        ind_false=find(FFres~=0);
        U_Diff=Uin(ind_good)-U_smooth(ind_good);
        V_Diff=Vin(ind_good)-V_smooth(ind_good);
        DataOut.Diff_rms(irho)=sqrt(mean(U_Diff.*U_Diff+V_Diff.*V_Diff)/2);
        DataOut.NbExclude(irho)=(NbGood-numel(ind_good))/NbGood;
        U_smooth(ind_false)=NaN;
        V_smooth(ind_false)=NaN;
        DataOut.(['U_' str_i{irho}])=U_smooth;
        DataOut.(['V_' str_i{irho}])=V_smooth;
    end
    time=toc
    OutputFile=fullfile_uvmat(OutputPath,OutputDir,RootFileOut,FileExtOut,NomTypeOut,i1_series{1}(index),[],j1_series{1}(index),j2_series{1}(index))
    errormsg=struct2nc(OutputFile,DataOut)
end
figure
    semilogx(FieldSmooth,DataOut.Diff_rms,'b',FieldSmooth,DataOut.NbExclude,'r',FieldSmooth,0.1*ones(size(FieldSmooth)),'m')
    grid on
    title( [filecell{1,1} ':' Param.InputFields.VelType])
    legend({'rms vel. diff. ' ;' ratio excluded vectors';'recommended diff'},'Location','northwest')
    xlabel('smoothing parameter')
    ylabel('rms (pixels) and exclusion ratio')
    OutputFig=fullfile(OutputPath,OutputDir,'plot_rms_diff.png')
    saveas(2,OutputFig)




  

  
