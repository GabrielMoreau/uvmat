%'civ_series': PIV function activated by the general GUI series
% --- call the sub-functions:
%   civ: PIV function itself
%   detect_false: put a flag to false vectors after detection by various criteria
%   filter_tps: make interpolation-smoothing
%------------------------------------------------------------------------
% function [Data,errormsg,result_conv]= civ_series(Param)
%
%OUTPUT
% Data=structure containing the PIV results and information on the processing parameters
% errormsg=error message char string, decd ..fault=''
% resul_conv: image inter-correlation function for the last grid point (used for tests)
%
%INPUT:
% Param: Matlab structure of input  parameters
%     Param contains info of the GUI series using the fct read_GUI.
%     Param.Action.RUN = 0 (to set the status of the GUI series) or =1 to RUN the computation
%     Param.InputTable: sets the input file(s)
%           if absent, the fct looks for input data in Param.ActionInput     (test mode)
%     Param.OutputSubDir: sets the folder name of output file(s,
%           if absent no file is produced, result in the output structure Data (test mode)
%     Param.ActionInput: substructure with the parameters provided by the GUI civ_input
%                      .Civ1: parameters for civ1cc
%                      .Fix1: parameters for detect_false1
%                      .Patch1:
%                      .Civ2: for civ2
%                      .Fix2:
%                      .Patch2:

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

function [Data,errormsg,result_conv]= civ_series(Param)
errormsg='';

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)% function activated from the GUI series but not RUN
    if 0==1 %never satisfied but trigger compilation with the appropriate transform functions ('eval' inactive for compilation)
        ima_rescale
    end
    path_series=fileparts(which('series'));
    addpath(fullfile(path_series,'series'))
    Data=civ_input(Param);% introduce the civ parameters using the GUI civ_input
    % TODO: change from guide to App: modify the input procedure, adapt read_GUI function
    %App=civ_input_App
    %Data=civ_input_App(Param);% introduce the civ parameters using the GUI civ_input
    % if isempty(App)
    %     Data=Param;% if  civ_input has been cancelled, keep previous parameters
    % end
    Data.Program=mfilename;%gives the name of the current function
    Data.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    Data.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    Data.NbSlice='off'; %nbre of slices ('off' by default)
    Data.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    Data.FieldName='on';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    Data.FieldTransform = 'on';%can use a transform function
    Data.ProjObject='off';%can use projection object(option 'off'/'on',
    Data.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    Data.OutputDirExt='.civ';%set the output dir extension
    Data.OutputSubDirMode='last'; %select the last subDir in the input table as root of the output subdir name (option 'all'/'first'/'last', 'all' by default)
    Data.OutputFileMode='NbInput_i';% one output file expected per value of i index (used for waitbar)
    Data.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default=1)
    if isfield(Data,'ActionInput') && isfield(Data.ActionInput,'PairIndices') && isequal(Data.ActionInput.PairIndices.ListPairMode,'pair j1-j2')
        Data.IndexRange_j='off';%no j index display in series
    else
        Data.IndexRange_j='on';% j index display in series if relevant
    end
    return
end

%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end

%% test input
if ~isfield(Param,'ActionInput')
    disp_uvmat('ERROR','no parameter set for PIV',checkrun)
    return
end
%iview_A=0;%default values
NbField=1;
RUNHandle=[];
% CheckInputFile=isfield(Param,'InputTable');%= 1 in test use for TestCiv (no nc file involved)
% CheckOutputFile=isfield(Param,'OutputSubDir');%= 1 in test use for TestPatch (no nc file produced)

%% input files and indexing 
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
MaxIndex_i=Param.IndexRange.MaxIndex_i;
MinIndex_i=Param.IndexRange.MinIndex_i;
MaxIndex_j=ones(size(MaxIndex_i));MinIndex_j=ones(size(MinIndex_i));
if isfield(Param.IndexRange,'MaxIndex_j')&& isfield(Param.IndexRange,'MinIndex_j')
    MaxIndex_j=Param.IndexRange.MaxIndex_j;
    MinIndex_j=Param.IndexRange.MinIndex_j;
end
if isfield(Param,'InputTable')
    [filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
    iview_B=0;% series index (iview) for the second image series (only non zero for option 'shift' comparing two image series )
    if Param.ActionInput.CheckCiv1
        iview_A=1;% usual PIV, the image series is on the first line of the table
    else % Civ1 has been already stored in a netcdf file input
        iview_A=2;% the second line is used for the input images
    end
    RootPath_A=Param.InputTable{iview_A,1};
    RootFile_A=Param.InputTable{iview_A,3};
    SubDir_A=Param.InputTable{iview_A,2};
    NomType_A=Param.InputTable{iview_A,4};
    FileExt_A=Param.InputTable{iview_A,5};
    if iview_B==0
        iview_B=iview_A;% the second image series is the same as the first
    end
    RootPath_B=Param.InputTable{iview_B,1};
    RootFile_B=Param.InputTable{iview_B,3};
    SubDir_B=Param.InputTable{iview_B,2};
    NomType_B=Param.InputTable{iview_B,4};
    FileExt_B=Param.InputTable{iview_B,5};
    PairCiv2='';
    
    switch Param.ActionInput.ListCompareMode
        case 'PIV'
            PairCiv1=Param.ActionInput.PairIndices.ListPairCiv1;
            if isfield(Param.ActionInput.PairIndices,'ListPairCiv2')
                PairCiv2=Param.ActionInput.PairIndices.ListPairCiv2;%string which determines the civ2 pair
            end
            if iview_A==1% if Civ1 is performed
                [i1_series_Civ1,i2_series_Civ1,j1_series_Civ1,j2_series_Civ1,check_bounds,NomTypeNc]=...
                    find_pair_indices(PairCiv1,i1_series{1},j1_series{1},MinIndex_i,MaxIndex_i,MinIndex_j,MaxIndex_j);
                if ~isempty(PairCiv2)
                    [i1_series_Civ2,i2_series_Civ2,j1_series_Civ2,j2_series_Civ2,check_bounds_Civ2]=...
                        find_pair_indices(PairCiv2,i1_series{1},j1_series{1},MinIndex_i(1),MaxIndex_i(1),MinIndex_j(1),MaxIndex_j(1));
                    check_bounds=check_bounds | check_bounds_Civ2;
                end
            else% we start from an existing Civ1 file
                i1_series_Civ1=i1_series{1};
                i2_series_Civ1=i2_series{1};
                j1_series_Civ1=j1_series{1};
                j2_series_Civ1=j2_series{1};
                NomTypeNc=Param.InputTable{1,4};
                if ~isempty(PairCiv2)
                    [i1_series_Civ2,i2_series_Civ2,j1_series_Civ2,j2_series_Civ2,check_bounds,NomTypeNc]=...
                        find_pair_indices(PairCiv2,i1_series{2},j1_series{2},MinIndex_i(2),MaxIndex_i(2),MinIndex_j(2),MaxIndex_j(2));
                end
            end
        case 'displacement'
            if isfield(Param.ActionInput,'OriginIndex')
                i1_series_Civ1=Param.ActionInput.OriginIndex*ones(size(i1_series{1}));
            else
                i1_series_Civ1=ones(size(i1_series{1}));
            end
            i1_series_Civ2=i1_series_Civ1;
            i2_series_Civ1=i1_series{1};
            i2_series_Civ2=i1_series{1};
            j1_series_Civ1=[];% no j index variation for the ref image
            j1_series_Civ2=[];
            if isempty(j1_series{1})
                j2_series_Civ1=ones(size(i1_series_Civ1));
            else
                j2_series_Civ1=j1_series{1};% if j index exist
            end
            j2_series_Civ2=j2_series_Civ1;
            NomTypeNc='_1';
    end
    %determine frame indices for input with movie or other multiframe input file
    if isempty(j1_series_Civ1)% simple movie with index i
        FrameIndex_A_Civ1=i1_series_Civ1;
        FrameIndex_B_Civ1=i2_series_Civ1;
        j1_series_Civ1=ones(size(i1_series_Civ1));
        if strcmp(Param.ActionInput.ListCompareMode,'PIV')
            j2_series_Civ1=ones(size(i1_series_Civ1));
        end
    else % movie for each burst or volume (index j)
        FrameIndex_A_Civ1=j1_series_Civ1;
        FrameIndex_B_Civ1=j2_series_Civ1;
    end
    if isempty(PairCiv2)
        FrameIndex_A_Civ2=FrameIndex_A_Civ1;
        FrameIndex_B_Civ2=FrameIndex_B_Civ1;
    else
        if isempty(j1_series_Civ2)
            FrameIndex_A_Civ2=i1_series_Civ2;
            FrameIndex_B_Civ2=i2_series_Civ2;
            j1_series_Civ2=ones(size(i1_series_Civ2));
            if strcmp(Param.ActionInput.ListCompareMode,'PIV')
                j2_series_Civ2=ones(size(i1_series_Civ2));
            end
        else
            FrameIndex_A_Civ2=j1_series_Civ2;
            FrameIndex_B_Civ2=j2_series_Civ2;
        end
    end
    if isempty(i1_series_Civ1)||(~isempty(PairCiv2) && isempty(i1_series_Civ2))
        disp_uvmat('ERROR','no image pair for civ in the input file index range',checkrun)
        return
    end
end

%% check the first image pair
if Param.ActionInput.CheckCiv1% Civ1 is performed
    NbField=numel(i1_series_Civ1);
elseif Param.ActionInput.CheckCiv2 % Civ2 is performed without Civ1
    NbField=numel(i1_series_Civ2);
else
    NbField=numel(i1_series_Civ1);% no image used (only detect_false or patch) TO CHECK
end

%% prepare output Data
OutputDir=[Param.OutputSubDir Param.OutputDirExt];
ListGlobalAttribute={'Conventions','Program','CivStage'};
Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
Data.Program='civ_series';
if isfield(Param,'UvmatRevision')
    Data.Program=[Data.Program ', uvmat r' Param.UvmatRevision];
end
Data.CivStage=0;%default

%% get timing from the ImaDoc file or input video
% if iview_A~=0
XmlFileName=find_imadoc(RootPath_A,SubDir_A);
Time=[];
if ~isempty(XmlFileName)
    XmlData=imadoc2struct(XmlFileName);%read the time from XmlFileName
    if isfield(XmlData,'Time')
        Time=XmlData.Time;
    end
    if isfield(XmlData,'Camera')
        if isfield(XmlData.Camera,'NbSlice')&& ~isempty(XmlData.Camera.NbSlice)
            NbSlice_calib{iview}=XmlData.Camera.NbSlice;% Nbre of slices for Zindex in phys transform
            if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
                msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
            end
        end
        if isfield(XmlData.Camera,'TimeUnit')&& ~isempty(XmlData.Camera.TimeUnit)
            TimeUnit=XmlData.Camera.TimeUnit;
        end
    end
end

%% File relabeling documented by the xml file (e.g. PCO)
CheckRelabel=isfield(Param,'FileSeries' );%=true for index relabeling (PCO)

%% introduce input image transform
transform_fct=[];%default, no transform
if isfield(Param,'FieldTransform')&&~isempty(Param.FieldTransform.TransformName)
        currentdir=pwd;
    cd(Param.FieldTransform.TransformPath)
    transform_fct=str2func(Param.FieldTransform.TransformName);
    cd (currentdir)
end

%%%%% MAIN LOOP %%%%%%
maskoldname='';% initiate the mask name
backgroundoldname='';
FileType_A='';
FileType_B='';
CheckOverwrite=1;%default
if isfield(Param,'CheckOverwrite')
    CheckOverwrite=Param.CheckOverwrite;
end
for ifield=1:NbField
    tstart=tic;
    time_civ1=0;
    time_patch1=0;
    time_civ2=0;
    time_patch2=0;
    if ~isempty(RUNHandle)% update the waitbar in interactive mode with GUI series  (checkrun=1)
        update_waitbar(WaitbarHandle,ifield/NbField)
        if  checkrun && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
            disp('program stopped by user')
            break
        end
    end
    OutputPath=fullfile(Param.OutputPath,Param.Experiment,Param.Device);
    if CheckRelabel
         RootFileOut=index2filename(Param.FileSeries,1,1,MaxIndex_j);
    else
        RootFileOut=RootFile_A;
    end
    if strcmp(Param.ActionInput.ListCompareMode,'PIV')
        ncfile=fullfile_uvmat(OutputPath,OutputDir,RootFileOut,'.nc',NomTypeNc,i1_series_Civ1(ifield),i2_series_Civ1(ifield),...
            j1_series_Civ1(ifield),j2_series_Civ1(ifield));
    else
        ncfile=fullfile_uvmat(OutputPath,OutputDir,RootFileOut,'.nc',NomTypeNc,i2_series_Civ1(ifield),[],...
            j1_series_Civ1(ifield),j2_series_Civ1(ifield));
    end
    ncfile_out=ncfile;% by default
    
    if isfield (Param.ActionInput,'Civ2')
        i1_civ2=i1_series_Civ2(ifield);
        i2_civ2=i1_civ2;
        if ~isempty(i2_series_Civ2)
            i2_civ2=i2_series_Civ2(ifield);
        end
        j1_civ2=1;
        if ~isempty(j1_series_Civ2)
            j1_civ2=j1_series_Civ2(ifield);
        end
        j2_civ2=i1_civ2;
        if ~isempty(j2_series_Civ2)
            j2_civ2=j2_series_Civ2(ifield);
        end
        if strcmp(Param.ActionInput.ListCompareMode,'PIV')
            ncfile_out=fullfile_uvmat(OutputPath,OutputDir,RootFileOut,'.nc',NomTypeNc,i1_civ2,i2_civ2,j1_civ2,j2_civ2);
        else % displacement
            ncfile_out=fullfile_uvmat(OutputPath,OutputDir,RootFileOut,'.nc',NomTypeNc,i2_civ2,[],j2_civ2);
        end
    end
    if ~CheckOverwrite && exist(ncfile_out,'file')
        disp(['existing output file ' ncfile_out ' already exists, skip to next field'])
        continue% skip iteration if the mode overwrite is desactivated and the result file already exists
    end
    %     end
    ImageName_A='';ImageName_B='';%default
    VideoObject_A=[];VideoObject_B=[];
    
    %% Civ1
    % if Civ1 computation is requested
    if Param.ActionInput.CheckCiv1
        disp('civ1 started')
        par_civ1=Param.ActionInput.Civ1;% parameters for civ1
        %if CheckInputFile % read input images (except in mode Test where it is introduced directly in Param.ActionInput.Civ1.ImageNameA and B)
        try
            if strcmp(Param.ActionInput.ListCompareMode,'displacement')
                ImageName_A=Param.ActionInput.RefFile;
            elseif CheckRelabel
            [RootFile,FrameIndex_A]=index2filename(Param.FileSeries,i1_series_Civ1(ifield),j1_series_Civ1(ifield),MaxIndex_j);
            ImageName_A=fullfile(RootPath_A,SubDir_A,RootFile);
            else
                ImageName_A=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1_series_Civ1(ifield),[],j1_series_Civ1(ifield));
                FrameIndex_A=FrameIndex_A_Civ1(ifield);
            end
            if strcmp(FileExt_A,'.nc')% case of input images in format netcdf
                FieldName_A=Param.InputFields.FieldName;
                [DataIn,~,~,errormsg]=nc2struct(ImageName_A,{FieldName_A});
                par_civ1.ImageA=DataIn.(FieldName_A);
            else % usual image formats for image A
                if isempty(FileType_A)% open the image object if not already done in case of movie input
                    [FileInfo_A,VideoObject_A]=get_file_info(ImageName_A);
                    FileType_A=FileInfo_A.FileType;
                    if isempty(Time) && ~isempty(find(strcmp(FileType_A,{'mmreader','video','cine_phantom','telopsIR'}), 1))% case of video input
                        Time=zeros(FileInfo_A.NumberOfFrames+1,2);
                        Time(:,2)=(0:1/FileInfo_A.FrameRate:(FileInfo_A.NumberOfFrames)/FileInfo_A.FrameRate)';
                        if ~isempty(j1_series_Civ1) && j1_series_Civ1~=1
                            Time=Time';
                        end
                    end
                    if ~isempty(FileType_A) && isempty(Time)% Time = index i +0.001 index j by default
                        MaxIndex_i=max(i2_series_Civ1);
                        MaxIndex_j=max(j2_series_Civ1);
                        Time=(1:MaxIndex_i)'*ones(1,MaxIndex_j);
                        Time=Time+0.001*ones(MaxIndex_i,1)*(1:MaxIndex_j);
                        Time=[zeros(1,MaxIndex_j);Time];% insert a first line of zeros
                        Time=[zeros(MaxIndex_i+1,1) Time];% insert a first column of zeros
                    end
                end
                if isempty(regexp(ImageName_A,'(^http://)|(^https://)', 'once')) && ~exist(ImageName_A,'file')
                    disp([ImageName_A ' missing'])
                    continue
                end
                tsart_input=tic;
                [par_civ1.ImageA,VideoObject_A] = read_image(ImageName_A,FileType_A,VideoObject_A,FrameIndex_A);
                time_input=toc(tsart_input);
            end
            if CheckRelabel
                [RootFile,FrameIndex_B]=index2filename(Param.FileSeries,i2_series_Civ1(ifield),j2_series_Civ1(ifield),MaxIndex_j);
                ImageName_B=fullfile(RootPath_B,SubDir_B,RootFile);
            else
                ImageName_B=fullfile_uvmat(RootPath_B,SubDir_B,RootFile_B,FileExt_B,NomType_B,i2_series_Civ1(ifield),[],j2_series_Civ1(ifield));
                FrameIndex_B=FrameIndex_B_Civ1(ifield);
            end
            if isempty(FileType_B)% determine the image type for the first field
                [FileInfo_B,VideoObject_B]=get_file_info(ImageName_B);
                FileType_B=FileInfo_B.FileType;
            end
            if isempty(regexp(ImageName_B,'(^http://)|(^https://)', 'once')) && ~exist(ImageName_B,'file')
                disp([ImageName_B ' missing'])
                continue
            end
            [par_civ1.ImageB,VideoObject_B] = read_image(ImageName_B,FileType_B,VideoObject_B,FrameIndex_B);

        catch ME % display errors in reading input images
            if ~isempty(ME.message)
                disp_uvmat('ERROR', ['error reading input image: ' ME.message],checkrun)
                continue
            end
        end

 % case of background image to subtract
        if par_civ1.CheckBackground &&~isempty(par_civ1.Background)
            [RootPath_background,SubDir_background,RootFile_background,~,~,~,~,Ext_background]=fileparts_uvmat(Param.ActionInput.Civ1.Background);
            j1=1;
            if ~isempty(j1_series_Civ1)
                j1=j1_series_Civ1(ifield);
            end
            if ~isempty(i2_series_Civ1)% case of volume,backgrounds act on different j levels
                backgroundname=fullfile_uvmat(RootPath_background,SubDir_background,RootFile_background,Ext_background,'_1',j1);
            elseif isfield(par_civ1,'NbSlice')
                i1_background=mod(i1-1,par_civ1.NbSlice)+1;
                backgroundname=fullfile_uvmat(RootPath_background,SubDir_background,RootFile_background,Ext_background,'_1',i1_background);
                if strcmp(Param.ActionInput.PairIndices.ListPairMode,'series(Di)')% case of volume, background index refers to j index
                    par_civ1.NbSlice_j=par_civ1.NbSlice;
                end
            else
                backgroundname=Param.ActionInput.Civ1.Background;
            end
            if strcmp(backgroundoldname,backgroundname)% background exist, not already read in civ1
                par_civ1.Background=background; %use background already opened
            else
                if ~isempty(regexp(backgroundname,'(^http://)|(^https://)', 'once'))|| exist(backgroundname,'file')
                    try
                        par_civ1.Background=imread(backgroundname);%update the background, an store it for future use
                    catch ME
                        if ~isempty(ME.message)
                            errormsg=['error reading input image: ' ME.message];
                            disp_uvmat('ERROR',errormsg,checkrun)
                            return
                        end
                    end
                else
                    par_civ1.Background=[];
                end
                background=par_civ1.Background;
                backgroundoldname=backgroundname;
            end
            par_civ1.ImageA=par_civ1.ImageA-par_civ1.Background;
            par_civ1.ImageB=par_civ1.ImageB-par_civ1.Background;
        end


        %% user defined image transform
        if ~isempty(transform_fct)
               par_civ1 =transform_fct(par_civ1,Param);
        end
        
        % par_civ1.ImageWidth=size(par_civ1.ImageA,2);
        % par_civ1.ImageHeight=size(par_civ1.ImageA,1);
        list_param=(fieldnames(Param.ActionInput.Civ1))';
        list_param(strcmp('TestCiv1',list_param))=[];% remove the parameter TestCiv1 from the list
        Civ1_param=regexprep(list_param,'^.+','Civ1_$0');% insert 'Civ1_' before  each string in list_param
        Civ1_param=[{'Civ1_ImageA','Civ1_ImageB','Civ1_Time','Civ1_Dt'} Civ1_param]; %insert the names of the two input images
        %indicate the values of all the global attributes in the output data
        Data.Civ1_ImageA=ImageName_A;
        Data.Civ1_ImageB=ImageName_B;
        i1=i1_series_Civ1(ifield);
        i2=i1;
        if ~isempty(i2_series_Civ1)
            i2=i2_series_Civ1(ifield);
        end
        j1=1;
        if ~isempty(j1_series_Civ1)
            j1=j1_series_Civ1(ifield);
        end
        j2=j1;
        if ~isempty(j2_series_Civ1)
            j2=j2_series_Civ1(ifield);
        end
        if strcmp(Param.ActionInput.ListCompareMode,'displacement')
            Data.Civ1_Time=Time(i2+1,j2+1);% the Time is the Time of the second image
            Data.Civ1_Dt=1;% Time interval is 1, to yield displacement instead of velocity=displacement/Dt at reading
        else
            Data.Civ1_Time=(Time(i2+1,j2+1)+Time(i1+1,j1+1))/2;% the Time is the Time at the middle of the image pair
            Data.Civ1_Dt=Time(i2+1,j2+1)-Time(i1+1,j1+1);
        end
        for ilist=1:length(list_param)
            Data.(Civ1_param{4+ilist})=Param.ActionInput.Civ1.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[ListGlobalAttribute Civ1_param];
        Data.CivStage=1;
        
        % set the list of variables
        Data.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_FF'};%  cell array containing the names of the fields to record
        Data.VarDimName={'nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1'};
        Data.VarAttribute{1}.Role='coord_x';
        Data.VarAttribute{2}.Role='coord_y';
        Data.VarAttribute{3}.Role='vector_x';
        Data.VarAttribute{4}.Role='vector_y';
        Data.VarAttribute{5}.Role='ancillary';
        Data.VarAttribute{6}.Role='errorflag';
        
        % case of mask
        if par_civ1.CheckMask&&~isempty(par_civ1.Mask)
            [RootPath_mask,SubDir_mask,RootFile_mask,~,~,~,~,Ext_mask]=fileparts_uvmat(Param.ActionInput.Civ1.Mask);
            j1=1;
            if ~isempty(j1_series_Civ1)
                j1=j1_series_Civ1(ifield);
            end
            if ~isempty(i2_series_Civ1)% case of volume,masks act on different j levels
                maskname=fullfile_uvmat(RootPath_mask,SubDir_mask,RootFile_mask,Ext_mask,'_1',j1);
            elseif isfield(par_civ1,'NbSlice')
                i1_mask=mod(i1-1,par_civ1.NbSlice)+1;
                maskname=fullfile_uvmat(RootPath_mask,SubDir_mask,RootFile_mask,Ext_mask,'_1',i1_mask);
                if strcmp(Param.ActionInput.PairIndices.ListPairMode,'series(Di)')% case of volume, mask index refers to j index
                    par_civ1.NbSlice_j=par_civ1.NbSlice;
                end
            else
                maskname=Param.ActionInput.Civ1.Mask;
            end
            if strcmp(maskoldname,maskname)% mask exist, not already read in civ1
                par_civ1.Mask=mask; %use mask already opened
            else
                if ~isempty(regexp(maskname,'(^http://)|(^https://)', 'once'))|| exist(maskname,'file')
                    try
                        par_civ1.Mask=imread(maskname);%update the mask, an store it for future use
                    catch ME
                        if ~isempty(ME.message)
                            errormsg=['error reading input image: ' ME.message];
                            disp_uvmat('ERROR',errormsg,checkrun)
                            return
                        end
                    end
                else
                    par_civ1.Mask=[];
                end
                mask=par_civ1.Mask;
                maskoldname=maskname;
            end
        end

        % case of input grid
        if par_civ1.CheckGrid &&~isempty(par_civ1.Grid)
            GridData=nc2struct(Param.ActionInput.Civ1.Grid);
            par_civ1.Grid=GridData.Grid;
            par_civ1.CorrBoxSize=GridData.CorrBox;
        end
        
        % caluclate velocity data
        [Data.Civ1_X,Data.Civ1_Y,Data.Civ1_U,Data.Civ1_V,Data.Civ1_C,Data.Civ1_FF, result_conv, errormsg] = civ (par_civ1);
        if ~isempty(errormsg)
            disp_uvmat('ERROR',errormsg,checkrun)
            return
        end
    end
    
    
    %% Fix1
    if isfield (Param.ActionInput,'Fix1')
        disp('detect_false1 started')
        if ~isfield (Param.ActionInput,'Civ1')% if we use existing Civ1, remove previous data beyond Civ1
            Fix1_attr=find(strcmp('Fix1',Data.ListGlobalAttribute));
            Data.ListGlobalAttribute(Fix1_attr)=[];
            for ilist=1:numel(Fix1_attr)
                Data=rmfield(Data,Data.ListGlobalAttribute{Fix1_attr(ilist)});
            end
        end
        list_param=fieldnames(Param.ActionInput.Fix1)';
        Fix1_param=regexprep(list_param,'^.+','Fix1_$0');% insert 'Fix1_' before  each string in ListFixParam
        %indicate the values of all the global attributes in the output data
        for ilist=1:length(list_param)
            Data.(Fix1_param{ilist})=Param.ActionInput.Fix1.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Fix1_param];
        Data.Civ1_FF=uint8(detect_false(Param.ActionInput.Fix1,Data.Civ1_C,Data.Civ1_U,Data.Civ1_V,Data.Civ1_FF));
        Data.CivStage=2;
    end
    %% Patch1
    if Param.ActionInput.CheckPatch1 && isfield (Param.ActionInput,'Patch1')
        disp('patch1 started')
        tstart_patch1=tic;
        
        % record the processing parameters of Patch1 as global attributes in the result nc file
        list_param=fieldnames(Param.ActionInput.Patch1)';
        list_param(strcmp('TestPatch1',list_param))=[];% remove 'TestPatch1' from the list of parameters
        Patch1_param=regexprep(list_param,'^.+','Patch1_$0');% insert 'Patch1_' before  each parameter name
        for ilist=1:length(list_param)
            Data.(Patch1_param{ilist})=Param.ActionInput.Patch1.(list_param{ilist});
        end
        Data.CivStage=3;% record the new state of processing
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Patch1_param];
        
        % list the variables to record
        nbvar=length(Data.ListVarName);
        Data.ListVarName=[Data.ListVarName {'Civ1_U_smooth','Civ1_V_smooth','Civ1_SubRange','Civ1_NbCentres','Civ1_Coord_tps','Civ1_U_tps','Civ1_V_tps'}];
        Data.VarDimName=[Data.VarDimName {'nb_vec_1','nb_vec_1',{'nb_coord','nb_bounds','nb_subdomain_1'},'nb_subdomain_1',...
            {'nb_tps_1','nb_coord','nb_subdomain_1'},{'nb_tps_1','nb_subdomain_1'},{'nb_tps_1','nb_subdomain_1'}}];
        Data.VarAttribute{nbvar+1}.Role='vector_x';
        Data.VarAttribute{nbvar+2}.Role='vector_y';
        Data.VarAttribute{nbvar+5}.Role='coord_tps';
        Data.VarAttribute{nbvar+6}.Role='vector_x';
        Data.VarAttribute{nbvar+7}.Role='vector_y';
        Data.Civ1_U_smooth=Data.Civ1_U; % zeros(size(Data.Civ1_X));
        Data.Civ1_V_smooth=Data.Civ1_V; %zeros(size(Data.Civ1_X));
        if isfield(Data,'Civ1_FF')
            ind_good=find(Data.Civ1_FF==0);
        else
            ind_good=1:numel(Data.Civ1_X);
        end
        if isempty(ind_good)
            disp_uvmat('ERROR','all vectors of civ1 are bad, check input parameters' ,checkrun)
            return
        end
        
        % perform Patch calculation using the UVMAT fct 'filter_tps'
        [Data.Civ1_SubRange,Data.Civ1_NbCentres,Data.Civ1_Coord_tps,Data.Civ1_U_tps,Data.Civ1_V_tps,~,Ures, Vres,~,FFres]=...
            filter_tps([Data.Civ1_X(ind_good) Data.Civ1_Y(ind_good)],Data.Civ1_U(ind_good),Data.Civ1_V(ind_good),[],Data.Patch1_SubDomainSize,Data.Patch1_FieldSmooth,Data.Patch1_MaxDiff);
        Data.Civ1_U_smooth(ind_good)=Ures;% take the interpolated (smoothed) velocity values for good vectors, keep civ1 data for the other
        Data.Civ1_V_smooth(ind_good)=Vres;
        Data.Civ1_FF(ind_good)=uint8(4*FFres);%set FF to value =4 for vectors eliminated by filter_tps
        time_patch1=toc(tstart_patch1);
        disp('patch1 performed')
    end
    
    %% Civ2
    if isfield (Param.ActionInput,'Civ2')
        disp('civ2 started')
        tstart_civ2=tic;
        par_civ2=Param.ActionInput.Civ2;
        %         if CheckInputFile % read input images (except in mode Test where it is introduced directly in Param.ActionInput.Civ1.ImageNameA and B)
        par_civ2.ImageA=[];
        par_civ2.ImageB=[];
        if strcmp(Param.ActionInput.ListCompareMode,'displacement')
            ImageName_A_Civ2=Param.ActionInput.RefFile;
        elseif CheckRelabel
            [RootFile,FrameIndex_A_2]=index2filename(Param.FileSeries,i1_series_Civ2(ifield),j1_series_Civ2(ifield),MaxIndex_j);
            ImageName_A_Civ2=fullfile(RootPath_A,SubDir_A,RootFile);
        else
            ImageName_A_Civ2=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1_civ2,[],j1_civ2);
            FrameIndex_A_2=FrameIndex_A_Civ2(ifield);
        end
        if strcmp(ImageName_A_Civ2,ImageName_A) && isequal(FrameIndex_A,FrameIndex_A_2)
            par_civ2.ImageA=par_civ1.ImageA;
        else
            [par_civ2.ImageA,VideoObject_A] = read_image(ImageName_A_Civ2,FileType_A,VideoObject_A,FrameIndex_A_2);
        end
        if CheckRelabel
            [RootFile,FrameIndex_B_2]=index2filename(Param.FileSeries,i2_civ2,j2_civ2,MaxIndex_j);
            ImageName_B_Civ2=fullfile(RootPath_B,SubDir_B,RootFile);
        else
            ImageName_B_Civ2=fullfile_uvmat(RootPath_B,SubDir_B,RootFile_B,FileExt_B,NomType_B,i2_civ2,[],j2_civ2);
            FrameIndex_B_2=FrameIndex_B_Civ2(ifield);
        end
        if strcmp(ImageName_B_Civ2,ImageName_B) && isequal(FrameIndex_B_2,FrameIndex_B)
            par_civ2.ImageB=par_civ1.ImageB;
        else
            [par_civ2.ImageB,VideoObject_B] = read_image(ImageName_B_Civ2,FileType_B,VideoObject_B,FrameIndex_B_2);
        end
        %  [FileInfo_A,VideoObject_A]=get_file_info(ImageName_A_Civ2);
        npy_ima=size(par_civ2.ImageA,1);
        npx_ima=size(par_civ2.ImageA,2);
        if par_civ2.CheckGrid &&~isempty(par_civ2.Grid) % case of input grid
            GridData=nc2struct(Param.ActionInput.Civ2.Grid);
            par_civ2.Grid=GridData.Grid;
            par_civ2.CorrBoxSize=GridData.CorrBox;
        else% automatic grid
            nbinterv_x=floor((npx_ima-1)/par_civ2.Dx);
            gridlength_x=nbinterv_x*par_civ2.Dx;
            minix=ceil((npx_ima-gridlength_x)/2);
            nbinterv_y=floor((npy_ima-1)/par_civ2.Dy);
            gridlength_y=nbinterv_y*par_civ2.Dy;
            miniy=ceil((npy_ima-gridlength_y)/2);
            [GridX,GridY]=meshgrid(minix:par_civ2.Dx:npx_ima-1,miniy:par_civ2.Dy:npy_ima-1);
            par_civ2.Grid=zeros(numel(GridX),2);
            par_civ2.Grid(:,1)=reshape(GridX,[],1);
            par_civ2.Grid(:,2)=reshape(GridY,[],1);% increases with array index
        end
        
                %% user defined image transform
        if ~isempty(transform_fct)
               par_civ2 =transform_fct(par_civ2,Param);
        end
        
        
        % get the guess from patch1 or patch2 (case 'CheckCiv3')
        if iview_A==2 && isfield (par_civ2,'CheckCiv3') && strcmp(par_civ2.CheckCiv3,'iterate(civ3)') %get the guess from  patch2% Civ1 data read in a netcdf file
            [DataIn,~,~,errormsg]=nc2struct(filecell{1,ifield});
            if ~isempty(errormsg)
                disp(errormsg)
                return
            end
            SubRange= DataIn.Civ2_SubRange;
            NbCentres=DataIn.Civ2_NbCentres;
            Coord_tps=DataIn.Civ2_Coord_tps;
            U_tps=DataIn.Civ2_U_tps;
            V_tps=DataIn.Civ2_V_tps;
            %CivStage=DataIn.CivStage;%store the current CivStage
            Civ1_Dt=DataIn.Civ2_Dt;
            Data=[];%reinitialise the result structure Data
            Data.ListGlobalAttribute={'Conventions','Program','CivStage'};
            Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
            Data.Program='civ_series';
           % Data.CivStage=CivStage+1;%update the current civStage after reinitialisation of Data
            Data.ListVarName={};
            Data.VarDimName={};
        else % get the guess from patch1
            SubRange= Data.Civ1_SubRange;
            NbCentres=Data.Civ1_NbCentres;
            Coord_tps=Data.Civ1_Coord_tps;
            U_tps=Data.Civ1_U_tps;
            V_tps=Data.Civ1_V_tps;
            Civ1_Dt=Data.Civ1_Dt;
%             Data.CivStage=4;
        end
         Data.CivStage=4;
        %             SubRange= par_civ2.Civ1_SubRange;
        %             NbCentres=par_civ2.Civ1_NbCentres;
        %             Coord_tps=par_civ2.Civ1_Coord_tps;
        %             U_tps=par_civ2.Civ1_U_tps;
        %             V_tps=par_civ2.Civ1_V_tps;
        %             Civ1_Dt=par_civ2.Civ1_Dt;
        %             Civ2_Dt=par_civ2.Civ1_Dt;
        %             Data.ListVarName={};
        %             Data.VarDimName={};
        %         end
        Shiftx=zeros(size(par_civ2.Grid,1),1);% initialise the shift expected from civ1 data
        Shifty=zeros(size(par_civ2.Grid,1),1);
        nbval=zeros(size(par_civ2.Grid,1),1);% nbre of interpolated values at each grid point (from the different patch subdomains)
        if par_civ2.CheckDeformation
            DUDX=zeros(size(par_civ2.Grid,1),1);
            DUDY=zeros(size(par_civ2.Grid,1),1);
            DVDX=zeros(size(par_civ2.Grid,1),1);
            DVDY=zeros(size(par_civ2.Grid,1),1);
        end
        NbSubDomain=size(SubRange,3);
        for isub=1:NbSubDomain% for each sub-domain of Patch1
            nbvec_sub=NbCentres(isub);% nbre of Civ vectors in the subdomain
            ind_sel=find(par_civ2.Grid(:,1)>=SubRange(1,1,isub) & par_civ2.Grid(:,1)<=SubRange(1,2,isub) &...
                par_civ2.Grid(:,2)>=SubRange(2,1,isub) & par_civ2.Grid(:,2)<=SubRange(2,2,isub));% grid points in the subdomain
            if ~isempty(ind_sel)
                epoints = par_civ2.Grid(ind_sel,:);% coordinates of interpolation sites (measurement grids)
                ctrs=Coord_tps(1:nbvec_sub,:,isub) ;%(=initial points) ctrs
                EM = tps_eval(epoints,ctrs);% thin plate spline (tps) coefficient
                CentreX=(SubRange(1,1,isub)+SubRange(1,2,isub))/2; %x posiion of the subdomain center
                CentreY=(SubRange(2,1,isub)+SubRange(2,2,isub))/2; %y posiion of the subdomain center
                xwidth=(SubRange(1,2,isub)-SubRange(1,1,isub))/pi;
                ywidth=(SubRange(2,2,isub)-SubRange(2,1,isub))/pi;
                x_dist=(epoints(:,1)-CentreX)/xwidth;
                y_dist=(epoints(:,2)-CentreY)/ywidth;
                weight=cos(x_dist).*cos(y_dist);%weighting fct =1 at the rectangle center and 0 at edge
                nbval(ind_sel)=nbval(ind_sel)+weight;% records the number of values for each interpolation point (in case of subdomain overlap)
                Shiftx(ind_sel)=Shiftx(ind_sel)+weight.*(EM*U_tps(1:nbvec_sub+3,isub));%velocity shift estimated by tps from civ1
                Shifty(ind_sel)=Shifty(ind_sel)+weight.*(EM*V_tps(1:nbvec_sub+3,isub));
                if par_civ2.CheckDeformation
                    [EMDX,EMDY] = tps_eval_dxy(epoints,ctrs);%2D matrix of distances between extrapolation points epoints and spline centres (=site points) ctrs
                    DUDX(ind_sel)=DUDX(ind_sel)+weight.*(EMDX*U_tps(1:nbvec_sub+3,isub));
                    DUDY(ind_sel)=DUDY(ind_sel)+weight.*(EMDY*U_tps(1:nbvec_sub+3,isub));
                    DVDX(ind_sel)=DVDX(ind_sel)+weight.*(EMDX*V_tps(1:nbvec_sub+3,isub));
                    DVDY(ind_sel)=DVDY(ind_sel)+weight.*(EMDY*V_tps(1:nbvec_sub+3,isub));
                end
            end
        end
        Shiftx(nbval>0)=Shiftx(nbval>0)./nbval(nbval>0);
        Shifty(nbval>0)=Shifty(nbval>0)./nbval(nbval>0);
        
        % introduce mask
        if par_civ2.CheckMask && ~isempty(par_civ2.Mask)
            [RootPath_mask,SubDir_mask,RootFile_mask,~,~,~,~,Ext_mask]=fileparts_uvmat(Param.ActionInput.Civ2.Mask);
            if ~isempty(i2_series_Civ2) % we do PIV among indices i,  at given indices j (volume scan), mask depends on position j
                j1=1;
                if ~isempty(j1_series_Civ2)
                    j1=j1_series_Civ1(ifield);
                end
                maskname=fullfile_uvmat(RootPath_mask,SubDir_mask,RootFile_mask,Ext_mask,'_1',j1);
            elseif isfield(par_civ2,'NbSlice')
                i1=i1_series_Civ2(ifield);
                i1_mask=mod(i1-1,par_civ2.NbSlice)+1;
                maskname=fullfile_uvmat(RootPath_mask,SubDir_mask,RootFile_mask,Ext_mask,'_1',i1_mask);
                if strcmp(Param.ActionInput.PairIndices.ListPairMode,'series(Di)')% case of volume, mask index refers to j index
                    par_civ2.NbSlice_j=par_civ2.NbSlice;
                end
            else
                maskname=Param.ActionInput.Civ2.Mask;
            end
            if strcmp(maskoldname,maskname)% mask exist, not already read in civ1
                par_civ2.Mask=mask; %use mask already opened
            else
                if exist(maskname,'file')
                    try
                        par_civ2.Mask=imread(maskname);%update the mask, an store it for future use
                    catch ME
                        if ~isempty(ME.message)
                            errormsg=['error reading input image: ' ME.message];
                            disp_uvmat('ERROR',errormsg,checkrun)
                            return
                        end
                    end
                else
                    par_civ2.Mask=[];
                end
                mask=par_civ2.Mask;
                maskoldname=maskname;
            end
        end
        
        % case of background image to subtract
        if par_civ2.CheckBackground &&~isempty(par_civ2.Background)
            [RootPath_background,SubDir_background,RootFile_background,~,~,~,~,Ext_background]=fileparts_uvmat(Param.ActionInput.Civ1.Background);
            j1=1;
            if ~isempty(j1_series_Civ1)
                j1=j1_series_Civ1(ifield);
            end
            if ~isempty(i2_series_Civ1)% case of volume,backgrounds act on different j levels
                backgroundname=fullfile_uvmat(RootPath_background,SubDir_background,RootFile_background,Ext_background,'_1',j1);
            elseif isfield(par_civ2,'NbSlice')
                i1_background=mod(i1-1,par_civ2.NbSlice)+1;
                backgroundname=fullfile_uvmat(RootPath_background,SubDir_background,RootFile_background,Ext_background,'_1',i1_background);
                if strcmp(Param.ActionInput.PairIndices.ListPairMode,'series(Di)')% case of volume, background index refers to j index
                    par_civ2.NbSlice_j=par_civ2.NbSlice;
                end
            else
                backgroundname=Param.ActionInput.Civ1.Background;
            end
            if strcmp(backgroundoldname,backgroundname)% background exist, not already read in civ2
                par_civ2.Background=background; %use background already opened
            else
                if ~isempty(regexp(backgroundname,'(^http://)|(^https://)', 'once'))|| exist(backgroundname,'file')
                    try
                        par_civ2.Background=imread(backgroundname);%update the background, an store it for future use
                    catch ME
                        if ~isempty(ME.message)
                            errormsg=['error reading input image: ' ME.message];
                            disp_uvmat('ERROR',errormsg,checkrun)
                            return
                        end
                    end
                else
                    par_civ2.Background=[];
                end
                background=par_civ2.Background;
                backgroundoldname=backgroundname;
            end
            par_civ2.ImageA=par_civ2.ImageA-par_civ2.Background;
            par_civ2.ImageB=par_civ2.ImageB-par_civ2.Background;
        end
        
        if strcmp(Param.ActionInput.ListCompareMode,'displacement')
            Civ1_Dt=1;
            Civ2_Dt=1;
        else
            Civ2_Dt=Time(i2_civ2+1,j2_civ2+1)-Time(i1_civ2+1,j1_civ2+1);
        end
        par_civ2.SearchBoxShift=zeros(size(par_civ2.Grid));
        par_civ2.SearchBoxShift(:,1)=(Civ2_Dt/Civ1_Dt)*Shiftx;%rescale the shift in case of Dt different for Civ1 and Civ2
        par_civ2.SearchBoxShift(:,2)=(Civ2_Dt/Civ1_Dt)*Shifty;
        
        if par_civ2.CheckDeformation
            par_civ2.DUDX(nbval>0)=DUDX(nbval>0)./nbval(nbval>0);
            par_civ2.DUDY(nbval>0)=DUDY(nbval>0)./nbval(nbval>0);
            par_civ2.DVDX(nbval>0)=DVDX(nbval>0)./nbval(nbval>0);
            par_civ2.DVDY(nbval>0)=DVDY(nbval>0)./nbval(nbval>0);
        end
        
        % calculate velocity data (y and v in image indices, reverse to y component)
        
        [Data.Civ2_X,Data.Civ2_Y,Data.Civ2_U,Data.Civ2_V,Data.Civ2_C,Data.Civ2_FF,~, errormsg] = civ (par_civ2);
        
        list_param=(fieldnames(Param.ActionInput.Civ2))';
        list_param(strcmp('TestCiv2',list_param))=[];% remove the parameter TestCiv2 from the list
        Civ2_param=regexprep(list_param,'^.+','Civ2_$0');% insert 'Civ2_' before  each string in list_param
        Civ2_param=[{'Civ2_ImageA','Civ2_ImageB','Civ2_Time','Civ2_Dt'} Civ2_param]; %insert the names of the two input images
        %indicate the values of all the global attributes in the output data
        if exist('ImageName_A','var')
            Data.Civ2_ImageA=ImageName_A;
            Data.Civ2_ImageB=ImageName_B;
            if strcmp(Param.ActionInput.ListCompareMode,'displacement')
                Data.Civ2_Time=Time(i2_civ2+1,j2_civ2+1);% the Time is the Time of the secodn image
                Data.Civ2_Dt=1;% Time interval is 1, to yield displacement instead of velocity=displacement/Dt at reading
            else
                Data.Civ2_Time=(Time(i2_civ2+1,j2_civ2+1)+Time(i1_civ2+1,j1_civ2+1))/2;
                Data.Civ2_Dt=Civ2_Dt;
            end
        end
        for ilist=1:length(list_param)
            Data.(Civ2_param{4+ilist})=Param.ActionInput.Civ2.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ2_param];
        
        nbvar=numel(Data.ListVarName);
        % define the Civ2 variable (if Civ2 data are not replaced from previous calculation)
        if isempty(find(strcmp('Civ2_X',Data.ListVarName),1))
            Data.ListVarName=[Data.ListVarName {'Civ2_X','Civ2_Y','Civ2_U','Civ2_V','Civ2_C','Civ2_FF'}];%  cell array containing the names of the fields to record
            Data.VarDimName=[Data.VarDimName {'nb_vec_2','nb_vec_2','nb_vec_2','nb_vec_2','nb_vec_2','nb_vec_2'}];
            Data.VarAttribute{nbvar+1}.Role='coord_x';
            Data.VarAttribute{nbvar+2}.Role='coord_y';
            Data.VarAttribute{nbvar+3}.Role='vector_x';
            Data.VarAttribute{nbvar+4}.Role='vector_y';
            Data.VarAttribute{nbvar+5}.Role='ancillary';
            Data.VarAttribute{nbvar+6}.Role='errorflag';
        end
        disp('civ2 performed')
        time_civ2=toc(tstart_civ2);
    elseif ~isfield(Data,'ListVarName') % we start there, using existing Civ2 data
        if exist('ncfile','var')
            CivFile=ncfile;
            [Data,~,~,errormsg]=nc2struct(CivFile);%read civ1 and detect_false1 data in the existing netcdf file
            if ~isempty(errormsg)
                disp_uvmat('ERROR',errormsg,checkrun)
                return
            end
        end
    end
    
    %% Fix2
    if Param.ActionInput.CheckFix2 && isfield (Param.ActionInput,'Fix2')% if Fix2 computation is requested
        disp('detect_false2 started')
        list_param=fieldnames(Param.ActionInput.Fix2)';
        Fix2_param=regexprep(list_param,'^.+','Fix2_$0');% insert 'Fix1_' before  each string in ListFixParam
        %indicate the values of all the global attributes in the output data
        for ilist=1:length(list_param)
            Data.(Fix2_param{ilist})=Param.ActionInput.Fix2.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Fix2_param];
        Data.Civ2_FF=double(detect_false(Param.ActionInput.Fix2,Data.Civ2_C,Data.Civ2_U,Data.Civ2_V,Data.Civ2_FF));
        Data.CivStage=Data.CivStage+1;
    end
    
    %% Patch2
    if Param.ActionInput.CheckPatch2 && isfield (Param.ActionInput,'Patch2')% if Patch2 computation is requested
        
        disp('patch2 started')
        tstart_patch2=tic;
        list_param=fieldnames(Param.ActionInput.Patch2)';
        list_param(strcmp('TestPatch2',list_param))=[];% remove the parameter TestCiv1 from the list
        Patch2_param=regexprep(list_param,'^.+','Patch2_$0');% insert 'Fix1_' before  each string in ListFixParam
        %indicate the values of all the global attributes in the output data
        for ilist=1:length(list_param)
            Data.(Patch2_param{ilist})=Param.ActionInput.Patch2.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Patch2_param];
        
        nbvar=length(Data.ListVarName);
        Data.ListVarName=[Data.ListVarName {'Civ2_U_smooth','Civ2_V_smooth','Civ2_SubRange','Civ2_NbCentres','Civ2_Coord_tps','Civ2_U_tps','Civ2_V_tps'}];
        Data.VarDimName=[Data.VarDimName {'nb_vec_2','nb_vec_2',{'nb_coord','nb_bounds','nb_subdomain_2'},{'nb_subdomain_2'},...
            {'nb_tps_2','nb_coord','nb_subdomain_2'},{'nb_tps_2','nb_subdomain_2'},{'nb_tps_2','nb_subdomain_2'}}];
        
        Data.VarAttribute{nbvar+1}.Role='vector_x';
        Data.VarAttribute{nbvar+2}.Role='vector_y';
        Data.VarAttribute{nbvar+5}.Role='coord_tps';
        Data.VarAttribute{nbvar+6}.Role='vector_x';
        Data.VarAttribute{nbvar+7}.Role='vector_y';
        Data.Civ2_U_smooth=Data.Civ2_U;
        Data.Civ2_V_smooth=Data.Civ2_V;
        if isfield(Data,'Civ2_FF')
            ind_good=find(Data.Civ2_FF==0);
        else
            ind_good=1:numel(Data.Civ2_X);
        end
        if isempty(ind_good)
            disp_uvmat('ERROR','all vectors of civ2 are bad, check input parameters' ,checkrun)
            return
        end
        
        [Data.Civ2_SubRange,Data.Civ2_NbCentres,Data.Civ2_Coord_tps,Data.Civ2_U_tps,Data.Civ2_V_tps,tild,Ures,Vres,tild,FFres]=...
            filter_tps([Data.Civ2_X(ind_good) Data.Civ2_Y(ind_good)],Data.Civ2_U(ind_good),Data.Civ2_V(ind_good),[],Data.Patch2_SubDomainSize,Data.Patch2_FieldSmooth,Data.Patch2_MaxDiff);
        Data.Civ2_U_smooth(ind_good)=Ures;
        Data.Civ2_V_smooth(ind_good)=Vres;
        Data.Civ2_FF(ind_good)=uint8(4*FFres);
        Data.CivStage=Data.CivStage+1;
        time_patch2=toc(tstart_patch2);
        disp('patch2 performed')
    end
    
    %% write result in a netcdf file
    errormsg=struct2nc(ncfile_out,Data);
    if isempty(errormsg)
        disp([ncfile_out ' written'])
    else
        disp(errormsg)
    end
    time_total=toc(tstart);
    disp(['ellapsed time ' num2str(time_total/60,2) ' minutes'])
    disp(['time civ1 ' num2str(time_civ1,2) ' s'])
    disp(['time patch1 ' num2str(time_patch1,2) ' s'])
    disp(['time civ2 ' num2str(time_civ2,2) ' s'])
    disp(['time patch2 ' num2str(time_patch2,2) ' s'])
    if exist('time_input','var')
        disp(['time image reading ' num2str(time_input,2) ' s'])
        disp(['time other ' num2str((time_total-time_input-time_civ1-time_patch1-time_civ2-time_patch2),2) ' s'])
    end
end



%------------------------------------------------------------------------
% --- determine the list of index pairs of processing file
function [i1_series,i2_series,j1_series,j2_series,check_bounds,NomTypeNc]=...
    find_pair_indices(str_civ,i_series,j_series,MinIndex_i,MaxIndex_i,MinIndex_j,MaxIndex_j)
%------------------------------------------------------------------------
i1_series=i_series;% set of first image indexes
i2_series=i_series;
j1_series=j_series;%ones(size(i_series));% set of first image numbers
j2_series=j_series;%ones(size(i_series));
r=regexp(str_civ,'^\D(?<ind>[i|j])=( -| )(?<num1>\d+)\|(?<num2>\d+)','names');
if ~isempty(r)
    mode=['D' r.ind];
    ind1=str2num(r.num1);
    ind2=str2num(r.num2);
else
    mode='j1-j2';
    r=regexp(str_civ,'^j= (?<num1>[a-z])-(?<num2>[a-z])','names');
    if ~isempty(r)
        NomTypeNc='_1ab';
    else
        r=regexp(str_civ,'^j= (?<num1>[A-Z])-(?<num2>[A-Z])','names');
        if ~isempty(r)
            NomTypeNc='_1AB';
        else
            r=regexp(str_civ,'^j= (?<num1>\d+)-(?<num2>\d+)','names');
            if ~isempty(r)
                NomTypeNc='_1_1-2';
            end
        end
    end
    if isempty(r)
        display('wrong pair mode input option')
    else
        ind1=stra2num(r.num1);
        ind2=stra2num(r.num2);
    end
end
switch mode
    case 'Di'
        i1_series=i_series-ind1;% set of first image numbers
        i2_series=i_series+ind2;
        check_bounds=i1_series<MinIndex_i | i2_series>MaxIndex_i;
        if isempty(j_series)
            NomTypeNc='_1-2';
        else
            j1_series=j_series;
            j2_series=j_series;
            NomTypeNc='_1-2_1';
        end
    case 'Dj'
        j1_series=j_series-ind1;
        j2_series=j_series+ind2;
        check_bounds=j1_series<MinIndex_j | j2_series>MaxIndex_j;
        NomTypeNc='_1_1-2';
    otherwise %bursts
        i1_series=i_series(1,:);% do not sweep the j index
        i2_series=i_series(1,:);
        j1_series=ind1*ones(1,size(i_series,2));% j index is fixed by pair choice
        j2_series=ind2*ones(1,size(i_series,2));
        check_bounds=zeros(size(i1_series));% no limitations due to min-max indices
end

%------------------------------------------------------------------------
% --- set the flag for false vectors
function FF=detect_false(Param,C,U,V,FFIn)
FF=FFIn;%default, good vectors
% FF=1, for correlation max at edge, not set in this function
% FF=2, for too small correlation
% FF=3, for velocity outside bounds
% FF=4 for exclusion by difference with the smoothed field, set by call to function filter_tps

if isfield (Param,'MinCorr')
     FF(C<Param.MinCorr & FFIn==0)=2;
end
if (isfield(Param,'MinVel')&&~isempty(Param.MinVel))||(isfield (Param,'MaxVel')&&~isempty(Param.MaxVel))
    Umod= U.*U+V.*V;
    if isfield (Param,'MinVel')&&~isempty(Param.MinVel)
        U2Min=Param.MinVel*Param.MinVel;
        FF(Umod<U2Min & FFIn==0)=3;
    end
    if isfield (Param,'MaxVel')&&~isempty(Param.MaxVel)
         U2Max=Param.MaxVel*Param.MaxVel;
        FF(Umod>U2Max & FFIn==0)=3;
    end
end



