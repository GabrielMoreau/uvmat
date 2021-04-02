%'civ_series': PIV function activated by the general GUI series
% --- call the sub-functions:
%   civ: PIV function itself
%   fix: removes false vectors after detection by various criteria
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
%                      .Civ1: parameters for civ1
%                      .Fix1: parameters for fix1
%                      .Patch1:
%                      .Civ2: for civ2
%                      .Fix2:
%                      .Patch2:

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

function [Data,errormsg,result_conv]= civ_series(Param)
errormsg='';

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)% function activated from the GUI series but not RUN
    path_series=fileparts(which('series'));
    addpath(fullfile(path_series,'series'))
    Data=civ_input(Param);% introduce the civ parameters using the GUI civ_input
    %Data=civ_input_App(Param);% introduce the civ parameters using the GUI civ_input
    if isempty(Data)
        Data=Param;% if  civ_input has been cancelled, keep previous parameters
    end
    Data.Program=mfilename;%gives the name of the current function
    Data.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    Data.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    Data.NbSlice='off'; %nbre of slices ('off' by default)
    Data.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    Data.FieldName='on';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    Data.FieldTransform = 'off';%can use a transform function
    Data.ProjObject='off';%can use projection object(option 'off'/'on',
    Data.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    Data.OutputDirExt='.civ';%set the output dir extension
    Data.OutputSubDirMode='last'; %select the last subDir in the input table as root of the output subdir name (option 'all'/'first'/'last', 'all' by default)
    Data.OutputFileMode='NbInput_i';% one output file expected per value of i index (used for waitbar)
    Data.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default=1)
    if isfield(Data.ActionInput,'PairIndices') && strcmp(Data.ActionInput.PairIndices.ListPairMode,'pair j1-j2')
        if isfield(Data.ActionInput.PairIndices,'ListPairCiv2')
            str_civ=Data.ActionInput.PairIndices.ListPairCiv2;
        else
            str_civ=Data.ActionInput.PairIndices.ListPairCiv1;
        end
        r=regexp(str_civ,'^j= (?<num1>[a-z])-(?<num2>[a-z])','names');
        if isempty(r)
            r=regexp(str_civ,'^j= (?<num1>[A-Z])-(?<num2>[A-Z])','names');
            if isempty(r)
                r=regexp(str_civ,'^j= (?<num1>\d+)-(?<num2>\d+)','names');
            end
        end
        if ~isempty(r)
            Data.j_index_1=stra2num(r.num1);
            Data.j_index_2=stra2num(r.num2);
        end
    end
    % estimated CPUTime
    CPUtime_unit=0.01;%estimated time for a multiplication (in microsecond)
    if isfield(Param.SeriesData,'FileInfo')&&isfield(Param.SeriesData.FileInfo{1},'Height')&&isfield(Param.SeriesData.FileInfo{1},'Width')
        pixnbre=Param.SeriesData.FileInfo{1}.Height*Param.SeriesData.FileInfo{1}.Width; % total number of pxels for input images  
        CPUtime=0;
        if isfield(Data.ActionInput,'Civ1')
            %BoxSize=Data.ActionInput.Civ1.CorrBoxSize(1)*Data.ActionInput.Civ1.CorrBoxSize(2);
            tic
            testboxa=rand(Data.ActionInput.Civ1.CorrBoxSize(1),Data.ActionInput.Civ1.CorrBoxSize(2));
            testboxb=rand(Data.ActionInput.Civ1.SearchBoxSize(1),Data.ActionInput.Civ1.SearchBoxSize(2));
            anss=conv2(testboxa,testboxb);
            CPUtime_unit=toc;
            nb_box=pixnbre/(Data.ActionInput.Civ1.Dx*Data.ActionInput.Civ1.Dy);    
            %nbpos=Data.ActionInput.Civ1.SearchBoxSize-Data.ActionInput.Civ1.CorrBoxSize;
            CPUtime=2*CPUtime_unit*nb_box%*BoxSize*nbpos(1)*nbpos(2);% adjustement factor 2 used
        end
        if isfield(Data.ActionInput,'Patch1')
            CPUtime=2*CPUtime;
        end
        if isfield(Data.ActionInput,'Civ2')
            tic
            testboxa=rand(Data.ActionInput.Civ2.CorrBoxSize(1),Data.ActionInput.Civ2.CorrBoxSize(2));
            testboxb=rand(Data.ActionInput.Civ2.SearchBoxSize(1),Data.ActionInput.Civ2.SearchBoxSize(2));
            anss=conv2(testboxa,testboxb);
            CPUtime_unit=toc;
            nb_box=pixnbre/(Data.ActionInput.Civ2.Dx*Data.ActionInput.Civ2.Dy);
            %BoxSize=Data.ActionInput.Civ2.CorrBoxSize(1)*Data.ActionInput.Civ2.CorrBoxSize(2);
            %nbpos=Data.ActionInput.Civ2.SearchBoxSize-Data.ActionInput.Civ2.CorrBoxSize;
            CPUtime=CPUtime+2*CPUtime_unit*nb_box;%*BoxSize*nbpos(1)*nbpos(2);
        end
        if isfield(Data.ActionInput,'Patch2')
            CPUtime=(4/3)*CPUtime;
        end
        Data.CPUTime=ceil(CPUtime/6); % estimated CPU time per field pair in minute
        Data.CPUTime=Data.CPUTime/10; % displqy CPU time with 1 digit beyond dot
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
iview_A=0;%default values
NbField=1;
RUNHandle=[];
CheckInputFile=isfield(Param,'InputTable');%= 1 in test use for TestCiv (no nc file involved)
CheckOutputFile=isfield(Param,'OutputSubDir');%= 1 in test use for TestPatch (no nc file produced)

%% input files and indexing (skipped in Test mode)
if CheckInputFile
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
        [tild,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
        iview_A=0;% series index (iview) for the first image series
        iview_B=0;% series index (iview) for the second image series (only non zero for option 'shift' comparing two image series )
        if Param.ActionInput.CheckCiv1
            iview_A=1;% usual PIV, the image series is on the first line of the table
        elseif Param.ActionInput.CheckCiv2 % civ2 is performed without Civ1, a netcdf file series is needed in the first table line
            iview_A=2;% the second line is used for the input images of Civ2
        end
%         if strcmp(Param.ActionInput.ListCompareMode,'shift')
%             iview_B=iview_A+1; % the second image series is on the next line of the input table
%         end
        if iview_A~=0
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
        end
        
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
            case 'PIV volume'
                % TODO, TODO
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
            NbField=numel(i1_series_Civ1);% no image used (only fix or patch) TO CHECK
        end

    %% Output directory
    OutputDir='';
    if CheckOutputFile
        OutputDir=[Param.OutputSubDir Param.OutputDirExt];
    end
end

%% prepare output Data
ListGlobalAttribute={'Conventions','Program','CivStage'};
Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
Data.Program='civ_series';
Data.CivStage=0;%default
check_civx=0;%default

%% get timing from the ImaDoc file or input video
if iview_A~=0
    XmlFileName=find_imadoc(RootPath_A,SubDir_A,RootFile_A,FileExt_A);
    Time=[];
    if ~isempty(XmlFileName)
        XmlData=imadoc2struct(XmlFileName);
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
end

%%%%% MAIN LOOP %%%%%%
maskoldname='';% initiate the mask name
FileType_A='';
FileType_B='';
CheckOverwrite=1;%default
if isfield(Param,'CheckOverwrite')
    CheckOverwrite=Param.CheckOverwrite;
end
for ifield=1:NbField
    tic
    if ~isempty(RUNHandle)% update the waitbar in interactive mode with GUI series  (checkrun=1)
        update_waitbar(WaitbarHandle,ifield/NbField)
        if  checkrun && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
            disp('program stopped by user')
            break
        end
    end
    if CheckInputFile
        OutputPath=fullfile(Param.OutputPath,num2str(Param.Experiment),num2str(Param.Device));
        if iview_A==0 % no nc file has been entered
            ncfile=fullfile_uvmat(OutputPath,Param.InputTable{1,2},Param.InputTable{1,3},Param.InputTable{1,5},...
                NomTypeNc,i1_series_Civ1(ifield),i2_series_Civ1(ifield),j1_series_Civ1(ifield),j2_series_Civ1(ifield));
        else% an existing nc file has been entered
            if iview_A==1% if Civ1 is performed
                Civ1Dir=OutputDir;
            else
                Civ1Dir=Param.InputTable{1,2};
            end
            if strcmp(Param.ActionInput.ListCompareMode,'PIV')
                ncfile=fullfile_uvmat(OutputPath,Civ1Dir,RootFile_A,'.nc',NomTypeNc,i1_series_Civ1(ifield),i2_series_Civ1(ifield),...
                    j1_series_Civ1(ifield),j2_series_Civ1(ifield));
            else
                ncfile=fullfile_uvmat(OutputPath,Civ1Dir,RootFile_A,'.nc',NomTypeNc,i2_series_Civ1(ifield),[],...
                    j1_series_Civ1(ifield),j2_series_Civ1(ifield));
            end
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
                ncfile_out=fullfile_uvmat(OutputPath,OutputDir,RootFile_A,'.nc',NomTypeNc,i1_civ2,i2_civ2,j1_civ2,j2_civ2);
%                 ncfile_out=fullfile_uvmat(RootPath_A,OutputDir,RootFile_A,'.nc',NomTypeNc,i1_civ2,i2_civ2,j1_civ2,j2_civ2);
            else % displacement
                ncfile_out=fullfile_uvmat(OutputPath,OutputDir,RootFile_A,'.nc',NomTypeNc,i2_civ2,[],j2_civ2);
            end
        end
        if ~CheckOverwrite && exist(ncfile_out,'file')
            disp(['existing output file ' ncfile_out ' already exists, skip to next field'])
            continue% skip iteration if the mode overwrite is desactivated and the result file already exists
        end
    end
    %% Civ1
    % if Civ1 computation is requested
    if isfield (Param.ActionInput,'Civ1')
        if CheckInputFile
            disp('civ1 started')
        end
        par_civ1=Param.ActionInput.Civ1;% parameters for civ1
        if CheckInputFile % read input images (except in mode Test where it is introduced directly in Param.ActionInput.Civ1.ImageNameA and B)
            try
                if strcmp(Param.ActionInput.ListCompareMode,'displacement')
                    ImageName_A=Param.ActionInput.RefFile;
                else
                ImageName_A=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1_series_Civ1(ifield),[],j1_series_Civ1(ifield));
                end
                if strcmp(FileExt_A,'.nc')% case of input images in format netcdf
                    FieldName_A=Param.InputFields.FieldName;
                    [DataIn,tild,tild,errormsg]=nc2struct(ImageName_A,{FieldName_A});
                    par_civ1.ImageA=DataIn.(FieldName_A);
                else % usual image formats for image A
                    if isempty(FileType_A)% open the image object if not already done in case of movie input
                        [FileInfo_A,VideoObject_A]=get_file_info(ImageName_A);
                        FileType_A=FileInfo_A.FileType;
                        if isempty(Time) && ~isempty(find(strcmp(FileType_A,{'mmreader','video','cine_phantom'})))% case of video input
                            Time=zeros(FileInfo_A.NumberOfFrames+1,2);
                            Time(:,2)=(0:1/FileInfo_A.FrameRate:(FileInfo_A.NumberOfFrames)/FileInfo_A.FrameRate)';
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
                    if isempty(regexp(ImageName_A,'(^http://)|(^https://)')) && ~exist(ImageName_A,'file')
                        disp([ImageName_A ' missing'])
                        continue
                    end
                    [par_civ1.ImageA,VideoObject_A] = read_image(ImageName_A,FileType_A,VideoObject_A,FrameIndex_A_Civ1(ifield));
                end
                ImageName_B=fullfile_uvmat(RootPath_B,SubDir_B,RootFile_B,FileExt_B,NomType_B,i2_series_Civ1(ifield),[],j2_series_Civ1(ifield));
                if strcmp(FileExt_B,'.nc') % case of input images in format netcdf
                    FieldName_B=Param.InputFields.FieldName;
                    [DataIn,tild,tild,errormsg]=nc2struct(ImageName_B,{FieldName_B});
                    par_civ1.ImageB=DataIn.(FieldName_B);
                else % usual image formats for image B
                    if isempty(FileType_B)
                        [FileInfo_B,VideoObject_B]=get_file_info(ImageName_B);
                        FileType_B=FileInfo_B.FileType;
                    end
                    if isempty(regexp(ImageName_B,'(^http://)|(^https://)')) && ~exist(ImageName_B,'file')
                        disp([ImageName_B ' missing'])
                        continue
                    end
                    [par_civ1.ImageB,VideoObject_B] = read_image(ImageName_B,FileType_B,VideoObject_B,FrameIndex_B_Civ1(ifield));
                end
            catch ME % display errors in reading input images
                if ~isempty(ME.message)
                    disp_uvmat('ERROR', ['error reading input image: ' ME.message],checkrun)
                    continue
                end
            end
            par_civ1.ImageWidth=size(par_civ1.ImageA,2);
            par_civ1.ImageHeight=size(par_civ1.ImageA,1);
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
                Data.Civ1_Time=Time(i2+1,j2+1);% the Time is the Time of the secodn image
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
        end
        % set the list of variables
        Data.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_F','Civ1_C'};%  cell array containing the names of the fields to record
        Data.VarDimName={'nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1'};
        Data.VarAttribute{1}.Role='coord_x';
        Data.VarAttribute{2}.Role='coord_y';
        Data.VarAttribute{3}.Role='vector_x';
        Data.VarAttribute{4}.Role='vector_y';
        Data.VarAttribute{5}.Role='warnflag';
        % case of mask
        if par_civ1.CheckMask&&~isempty(par_civ1.Mask)
            if isfield(par_civ1,'NbSlice')
                [RootPath_mask,SubDir_mask,RootFile_mask,i1_mask,i2_mask,j1_mask,j2_mask,Ext_mask]=fileparts_uvmat(Param.ActionInput.Civ1.Mask);
                i1_mask=mod(i1-1,par_civ1.NbSlice)+1;
                maskname=fullfile_uvmat(RootPath_mask,SubDir_mask,RootFile_mask,Ext_mask,'_1',i1_mask);
            else
                maskname=Param.ActionInput.Civ1.Mask;
            end
            if strcmp(maskoldname,maskname)% mask exist, not already read in civ1
                par_civ1.Mask=mask; %use mask already opened
            else
                if ~isempty(regexp(maskname,'(^http://)|(^https://)'))|| exist(maskname,'file')
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
        if strcmp(Param.ActionInput.ListCompareMode, 'PIV volume')
            Data.ListVarName=[Data.ListVarName 'Civ1_Z'];
            Data.Civ1_X=[];Data.Civ1_Y=[];Data.Civ1_Z=[];
            Data.Civ1_U=[];Data.Civ1_V=[];Data.Civ1_C=[];Data.Civ1_F=[];
            for ivol=1:NbSlice
                % caluclate velocity data (y and v in indices, reverse to y component)
                [xtable, ytable, utable, vtable, ctable, F, result_conv, errormsg] = civ (par_civ1);
                if ~isempty(errormsg)
                    disp_uvmat('ERROR',errormsg,checkrun)
                    return
                end
                Data.Civ1_X=[Data.Civ1_X reshape(xtable,[],1)];
                Data.Civ1_Y=[Data.Civ1_Y reshape(Param.Civ1.ImageHeight-ytable+1,[],1)];
                Data.Civ1_Z=[Data.Civ1_Z ivol*ones(numel(xtable),1)];% z=image index in image coordinates
                Data.Civ1_U=[Data.Civ1_U reshape(utable,[],1)];
                Data.Civ1_V=[Data.Civ1_V reshape(-vtable,[],1)];
                Data.Civ1_C=[Data.Civ1_C reshape(ctable,[],1)];
                Data.Civ1_F=[Data.Civ1_C reshape(F,[],1)];
            end
        else %usual PIV
            % caluclate velocity data (y and v in indices, reverse to y component)
            [xtable, ytable, utable, vtable, ctable, F, result_conv, errormsg] = civ (par_civ1);
            if ~isempty(errormsg)
                disp_uvmat('ERROR',errormsg,checkrun)
                return
            end
            Data.Civ1_X=reshape(xtable,[],1);
            Data.Civ1_Y=reshape(par_civ1.ImageHeight-ytable+1,[],1);
            Data.Civ1_U=reshape(utable,[],1);
            Data.Civ1_V=reshape(-vtable,[],1);
            Data.Civ1_C=reshape(ctable,[],1);
            Data.Civ1_F=reshape(F,[],1);
        end
    else% we use existing Civ1 data
        if exist('ncfile','var')
            CivFile=ncfile;
            [Data,tild,tild,errormsg]=nc2struct(CivFile,'ListGlobalAttribute','absolut_time_T0'); %look for the constant 'absolut_time_T0' to detect old civx data format
            if ~isempty(errormsg)
                disp_uvmat('ERROR',errormsg,checkrun)
                return
            end
            [Data,tild,tild,errormsg]=nc2struct(CivFile);%read civ1 and fix1 data in the existing netcdf file
        elseif isfield(Param,'Civ1_X')
            Data.ListGlobalAttribute={};
            Data.ListVarName={};
            Data.VarDimName={};
            Data.Civ1_X=Param.Civ1_X;
            Data.Civ1_Y=Param.Civ1_Y;
            Data.Civ1_U=Param.Civ1_U;
            Data.Civ1_V=Param.Civ1_V;
            Data.Civ1_FF=Param.Civ1_FF;
        end
    end
    
    %% Fix1
    if isfield (Param.ActionInput,'Fix1')
        disp('fix1 started')
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
        Data.ListVarName=[Data.ListVarName {'Civ1_FF'}];
        Data.VarDimName=[Data.VarDimName {'nb_vec_1'}];
        nbvar=length(Data.ListVarName);
        Data.VarAttribute{nbvar}.Role='errorflag';
        Data.Civ1_FF=int8(fix(Param.ActionInput.Fix1,Data.Civ1_F,Data.Civ1_C,Data.Civ1_U,Data.Civ1_V));
        Data.CivStage=2;
    end
    %% Patch1
    if isfield (Param.ActionInput,'Patch1')
        disp('patch1 started')
        if check_civx
            errormsg='Civ Matlab input needed for patch';
            disp_uvmat('ERROR',errormsg,checkrun)
            return
        end
        
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
        
        % perform Patch calculation using the UVMAT fct 'filter_tps'
        [Data.Civ1_SubRange,Data.Civ1_NbCentres,Data.Civ1_Coord_tps,Data.Civ1_U_tps,Data.Civ1_V_tps,tild,Ures, Vres,tild,FFres]=...
            filter_tps([Data.Civ1_X(ind_good) Data.Civ1_Y(ind_good)],Data.Civ1_U(ind_good),Data.Civ1_V(ind_good),[],Data.Patch1_SubDomainSize,Data.Patch1_FieldSmooth,Data.Patch1_MaxDiff);
        Data.Civ1_U_smooth(ind_good)=Ures;% take the interpolated (smoothed) velocity values for good vectors, keep civ1 data for the other
        Data.Civ1_V_smooth(ind_good)=Vres;
        Data.Civ1_FF(ind_good)=int8(FFres);
        disp('patch1 performed')
    end
    
    %% Civ2
    if isfield (Param.ActionInput,'Civ2')
        disp('civ2 started')
        par_civ2=Param.ActionInput.Civ2;
        if CheckInputFile % read input images (except in mode Test where it is introduced directly in Param.ActionInput.Civ1.ImageNameA and B)
            par_civ2.ImageA=[];
            par_civ2.ImageB=[];
            if strcmp(Param.ActionInput.ListCompareMode,'displacement')
                    ImageName_A_Civ2=Param.ActionInput.RefFile;
                else
            ImageName_A_Civ2=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1_civ2,[],j1_civ2);
            end
            if strcmp(ImageName_A_Civ2,ImageName_A) && isequal(FrameIndex_A_Civ1(ifield),FrameIndex_A_Civ2(ifield))
                par_civ2.ImageA=par_civ1.ImageA;
            else
                [par_civ2.ImageA,VideoObject_A] = read_image(ImageName_A_Civ2,FileType_A,VideoObject_A,FrameIndex_A_Civ2(ifield));
            end
            ImageName_B_Civ2=fullfile_uvmat(RootPath_B,SubDir_B,RootFile_B,FileExt_B,NomType_B,i2_civ2,[],j2_civ2);
            if strcmp(ImageName_B_Civ2,ImageName_B) && isequal(FrameIndex_B_Civ1(ifield),FrameIndex_B_Civ2)
                par_civ2.ImageB=par_civ1.ImageB;
            else
                [par_civ2.ImageB,VideoObject_B] = read_image(ImageName_B_Civ2,FileType_B,VideoObject_B,FrameIndex_B_Civ2(ifield));
            end
            par_civ2.ImageWidth=FileInfo_A.Width;
            par_civ2.ImageHeight=FileInfo_A.Height;
            if isfield(par_civ2,'Grid')% grid points set as input file
                if ischar(par_civ2.Grid)%read the grid file if the input is a file name
                    par_civ2.Grid=dlmread(par_civ2.Grid);
                    par_civ2.Grid(1,:)=[];%the first line must be removed (heading in the grid file)
                end
            else% automatic grid
                minix=floor(par_civ2.Dx/2)-0.5;
                maxix=minix+par_civ2.Dx*floor((par_civ2.ImageWidth-1)/par_civ2.Dx);
                miniy=floor(par_civ2.Dy/2)-0.5;
                maxiy=minix+par_civ2.Dy*floor((par_civ2.ImageHeight-1)/par_civ2.Dy);
                [GridX,GridY]=meshgrid(minix:par_civ2.Dx:maxix,miniy:par_civ2.Dy:maxiy);
                par_civ2.Grid(:,1)=reshape(GridX,[],1);
                par_civ2.Grid(:,2)=reshape(GridY,[],1);
            end
        end
        
        % get the guess from patch1 or patch2 (case 'CheckCiv3')
        if CheckInputFile % read input images (except in mode Test where it is introduced directly in Param.ActionInput.Civ1.ImageNameA and B)
            if isfield (par_civ2,'CheckCiv3') && par_civ2.CheckCiv3 %get the guess from  patch2
                SubRange= Data.Civ2_SubRange;
                NbCentres=Data.Civ2_NbCentres;
                Coord_tps=Data.Civ2_Coord_tps;
                U_tps=Data.Civ2_U_tps;
                V_tps=Data.Civ2_V_tps;
                CivStage=Data.CivStage;%store the current CivStage
                Civ1_Dt=Data.Civ2_Dt;
                Data=[];%reinitialise the result structure Data
                Data.ListGlobalAttribute={'Conventions','Program','CivStage'};
                Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
                Data.Program='civ_series';
                Data.CivStage=CivStage+1;%update the current civStage after reinitialisation of Data
                Data.ListVarName={};
                Data.VarDimName={};
            else % get the guess from patch1
                SubRange= Data.Civ1_SubRange;
                NbCentres=Data.Civ1_NbCentres;
                Coord_tps=Data.Civ1_Coord_tps;
                U_tps=Data.Civ1_U_tps;
                V_tps=Data.Civ1_V_tps;
                Civ1_Dt=Data.Civ1_Dt;
                Data.CivStage=4;
            end
        else
            SubRange= par_civ2.Civ1_SubRange;
            NbCentres=par_civ2.Civ1_NbCentres;
            Coord_tps=par_civ2.Civ1_Coord_tps;
            U_tps=par_civ2.Civ1_U_tps;
            V_tps=par_civ2.Civ1_V_tps;
            Civ1_Dt=par_civ2.Civ1_Dt;
            Civ2_Dt=par_civ2.Civ1_Dt;
            Data.ListVarName={};
            Data.VarDimName={};
        end
        Shiftx=zeros(size(par_civ2.Grid,1),1);% shift expected from civ1 data
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
                nbval(ind_sel)=nbval(ind_sel)+1;% records the number of values for each interpolation point (in case of subdomain overlap)
                EM = tps_eval(epoints,ctrs);% thin plate spline (tps) coefficient
                Shiftx(ind_sel)=Shiftx(ind_sel)+EM*U_tps(1:nbvec_sub+3,isub);%velocity shift estimated by tps from civ1
                Shifty(ind_sel)=Shifty(ind_sel)+EM*V_tps(1:nbvec_sub+3,isub);
                if par_civ2.CheckDeformation
                    [EMDX,EMDY] = tps_eval_dxy(epoints,ctrs);%2D matrix of distances between extrapolation points epoints and spline centres (=site points) ctrs
                    DUDX(ind_sel)=DUDX(ind_sel)+EMDX*U_tps(1:nbvec_sub+3,isub);
                    DUDY(ind_sel)=DUDY(ind_sel)+EMDY*U_tps(1:nbvec_sub+3,isub);
                    DVDX(ind_sel)=DVDX(ind_sel)+EMDX*V_tps(1:nbvec_sub+3,isub);
                    DVDY(ind_sel)=DVDY(ind_sel)+EMDY*V_tps(1:nbvec_sub+3,isub);
                end
            end
        end
        if par_civ2.CheckMask&&~isempty(par_civ2.Mask)        
            if isfield(par_civ2,'NbSlice')
                [RootPath_mask,SubDir_mask,RootFile_mask,i1_mask,i2_mask,j1_mask,j2_mask,Ext_mask]=fileparts_uvmat(Param.ActionInput.Civ2.Mask);
                i1_mask=mod(i1-1,par_civ2.NbSlice)+1;
                maskname=fullfile_uvmat(RootPath_mask,SubDir_mask,RootFile_mask,Ext_mask,'_1',i1_mask);
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

        if CheckInputFile % else Dt given by par_civ2
            if strcmp(Param.ActionInput.ListCompareMode,'displacement')
                Civ1_Dt=1;
                Civ2_Dt=1;
            else
                Civ2_Dt=Time(i2_civ2+1,j2_civ2+1)-Time(i1_civ2+1,j1_civ2+1);
            end
        end
        par_civ2.SearchBoxShift=(Civ2_Dt/Civ1_Dt)*[Shiftx(nbval>=1)./nbval(nbval>=1) Shifty(nbval>=1)./nbval(nbval>=1)];
        % shift the grid points by half the expected shift to provide the correlation box position in image A
        par_civ2.Grid=[par_civ2.Grid(nbval>=1,1)-par_civ2.SearchBoxShift(:,1)/2 par_civ2.Grid(nbval>=1,2)-par_civ2.SearchBoxShift(:,2)/2];
        if par_civ2.CheckDeformation
            par_civ2.DUDX=DUDX(nbval>=1)./nbval(nbval>=1);
            par_civ2.DUDY=DUDY(nbval>=1)./nbval(nbval>=1);
            par_civ2.DVDX=DVDX(nbval>=1)./nbval(nbval>=1);
            par_civ2.DVDY=DVDY(nbval>=1)./nbval(nbval>=1);
        end
        
        % calculate velocity data (y and v in image indices, reverse to y component)
        [xtable, ytable, utable, vtable, ctable, F,result_conv,errormsg] = civ (par_civ2);
        
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
            Data.ListVarName=[Data.ListVarName {'Civ2_X','Civ2_Y','Civ2_U','Civ2_V','Civ2_F','Civ2_C'}];%  cell array containing the names of the fields to record
            Data.VarDimName=[Data.VarDimName {'nb_vec_2','nb_vec_2','nb_vec_2','nb_vec_2','nb_vec_2','nb_vec_2'}];
            Data.VarAttribute{nbvar+1}.Role='coord_x';
            Data.VarAttribute{nbvar+2}.Role='coord_y';
            Data.VarAttribute{nbvar+3}.Role='vector_x';
            Data.VarAttribute{nbvar+4}.Role='vector_y';
            Data.VarAttribute{nbvar+5}.Role='warnflag';
        end
        Data.Civ2_X=reshape(xtable,[],1);
        Data.Civ2_Y=reshape(size(par_civ2.ImageA,1)-ytable+1,[],1);
        Data.Civ2_U=reshape(utable,[],1);
        Data.Civ2_V=reshape(-vtable,[],1);
        Data.Civ2_C=reshape(ctable,[],1);
        Data.Civ2_F=reshape(F,[],1);
        disp('civ2 performed')
    elseif ~isfield(Data,'ListVarName') % we start there, using existing Civ2 data
        if exist('ncfile','var')
            CivFile=ncfile;
            [Data,tild,tild,errormsg]=nc2struct(CivFile);%read civ1 and fix1 data in the existing netcdf file
            if ~isempty(errormsg)
                disp_uvmat('ERROR',errormsg,checkrun)
                return
            end
        elseif isfield(Param,'Civ2_X')% use Civ2 data as input in Param (test mode)
            Data.ListGlobalAttribute={};
            Data.ListVarName={};
            Data.VarDimName={};
            Data.Civ2_X=Param.Civ2_X;
            Data.Civ2_Y=Param.Civ2_Y;
            Data.Civ2_U=Param.Civ2_U;
            Data.Civ2_V=Param.Civ2_V;
            Data.Civ2_FF=Param.Civ2_FF;
        end
    end
    
    %% Fix2
    if isfield (Param.ActionInput,'Fix2')
        disp('fix2 started')
        list_param=fieldnames(Param.ActionInput.Fix2)';
        Fix2_param=regexprep(list_param,'^.+','Fix2_$0');% insert 'Fix1_' before  each string in ListFixParam
        %indicate the values of all the global attributes in the output data
        for ilist=1:length(list_param)
            Data.(Fix2_param{ilist})=Param.ActionInput.Fix2.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Fix2_param];
        %
        %         ListFixParam=fieldnames(Param.ActionInput.Fix2);
        %         for ilist=1:length(ListFixParam)
        %             ParamName=ListFixParam{ilist};
        %             ListName=['Fix2_' ParamName];
        %             eval(['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];'])
        %             eval(['Data.' ListName '=Param.ActionInput.Fix2.' ParamName ';'])
        %         end
        if check_civx
            if ~isfield(Data,'fix2')
                Data.ListGlobalAttribute=[Data.ListGlobalAttribute 'fix2'];
                Data.fix2=1;
                Data.ListVarName=[Data.ListVarName {'vec2_FixFlag'}];
                Data.VarDimName=[Data.VarDimName {'nb_vectors2'}];
            end
            Data.vec_FixFlag=fix(Param.Fix2,Data.vec2_F,Data.vec2_C,Data.vec2_U,Data.vec2_V,Data.vec2_X,Data.vec2_Y);
        else
            Data.ListVarName=[Data.ListVarName {'Civ2_FF'}];
            Data.VarDimName=[Data.VarDimName {'nb_vec_2'}];
            nbvar=length(Data.ListVarName);
            Data.VarAttribute{nbvar}.Role='errorflag';
            Data.Civ2_FF=double(fix(Param.ActionInput.Fix2,Data.Civ2_F,Data.Civ2_C,Data.Civ2_U,Data.Civ2_V));
            Data.CivStage=Data.CivStage+1;
        end
    end
    
    %% Patch2
    if isfield (Param.ActionInput,'Patch2')
        disp('patch2 started')
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
        [Data.Civ2_SubRange,Data.Civ2_NbCentres,Data.Civ2_Coord_tps,Data.Civ2_U_tps,Data.Civ2_V_tps,tild,Ures,Vres,tild,FFres]=...
            filter_tps([Data.Civ2_X(ind_good) Data.Civ2_Y(ind_good)],Data.Civ2_U(ind_good),Data.Civ2_V(ind_good),[],Data.Patch2_SubDomainSize,Data.Patch2_FieldSmooth,Data.Patch2_MaxDiff);
        Data.Civ2_U_smooth(ind_good)=Ures;
        Data.Civ2_V_smooth(ind_good)=Vres;
        Data.Civ2_FF(ind_good)=FFres;
        Data.CivStage=Data.CivStage+1;
        disp('patch2 performed')
    end
    
    %% write result in a netcdf file if requested
    if CheckOutputFile
        errormsg=struct2nc(ncfile_out,Data);
        if isempty(errormsg)
            disp([ncfile_out ' written'])
            %[success,msg] = fileattrib(ncfile_out ,'+w','g');% done in struct2nc
        else
            disp(errormsg)
        end
        disp(['ellapsed time ' num2str(toc/60,2) ' minutes'])
    end
end


% 'civ': function piv.m adapted from PIVlab http://pivlab.blogspot.com/
%--------------------------------------------------------------------------
% function [xtable ytable utable vtable typevector] = civ (image1,image2,ibx,iby step, subpixfinder, mask, roi)
%
% OUTPUT:
% xtable: set of x coordinates
% ytable: set of y coordiantes
% utable: set of u displacements (along x)
% vtable: set of v displacements (along y)
% ctable: max image correlation for each vector
% typevector: set of flags, =1 for good, =0 for NaN vectors
%
%INPUT:
% par_civ: structure of input parameters, with fields:
%  .ImageA: first image for correlation (matrix)
%  .ImageB: second image for correlation(matrix)
%  .CorrBoxSize: 1,2 vector giving the size of the correlation box in x and y
%  .SearchBoxSize:  1,2 vector giving the size of the search box in x and y
%  .SearchBoxShift: 1,2 vector or 2 column matrix (for civ2) giving the shift of the search box in x and y
%  .CorrSmooth: =1 or 2 determines the choice of the sub-pixel determination of the correlation max
%  .ImageWidth: nb of pixels of the image in x
%  .Dx, Dy: mesh for the PIV calculation
%  .Grid: grid giving the PIV calculation points (alternative to .Dx .Dy): centres of the correlation boxes in Image A
%  .Mask: name of a mask file or mask image matrix itself
%  .MinIma: thresholds for image luminosity
%  .MaxIma
%  .CheckDeformation=1 for subpixel interpolation and image deformation (linear transform)
%  .DUDX: matrix of deformation obtained from patch at each grid point
%  .DUDY
%  .DVDX:
%  .DVDY

function [xtable,ytable,utable,vtable,ctable,F,result_conv,errormsg] = civ (par_civ)

%% prepare measurement grid
if isfield(par_civ,'Grid')% grid points set as input, central positions of the sub-images in image A
    if ischar(par_civ.Grid)%read the grid file if the input is a file name (grid in x, y image coordinates)
        par_civ.Grid=dlmread(par_civ.Grid);
        par_civ.Grid(1,:)=[];%the first line must be removed (heading in the grid file)
    end
    % else par_civ.Grid is already an array, no action here
else% automatic grid in x, y image coordinates
    minix=floor(par_civ.Dx/2)-0.5;
    maxix=minix+par_civ.Dx*floor((par_civ.ImageWidth-1)/par_civ.Dx);
    miniy=floor(par_civ.Dy/2)-0.5;% first automatic grid point at half the mesh Dy
    maxiy=minix+par_civ.Dy*floor((par_civ.ImageHeight-1)/par_civ.Dy);
    [GridX,GridY]=meshgrid(minix:par_civ.Dx:maxix,miniy:par_civ.Dy:maxiy);
    par_civ.Grid(:,1)=reshape(GridX,[],1);
    par_civ.Grid(:,2)=reshape(GridY,[],1);% increases with array index
end
nbvec=size(par_civ.Grid,1);

%% prepare correlation and search boxes
ibx2=floor(par_civ.CorrBoxSize(1)/2);
iby2=floor(par_civ.CorrBoxSize(2)/2);
isx2=floor(par_civ.SearchBoxSize(1)/2);
isy2=floor(par_civ.SearchBoxSize(2)/2);
shiftx=round(par_civ.SearchBoxShift(:,1));%use the input shift estimate, rounded to the next integer value
shifty=-round(par_civ.SearchBoxShift(:,2));% sign minus because image j index increases when y decreases
if numel(shiftx)==1% case of a unique shift for the whole field( civ1)
    shiftx=shiftx*ones(nbvec,1);
    shifty=shifty*ones(nbvec,1);
end

%% Array initialisation and default output  if par_civ.CorrSmooth=0 (just the grid calculated, no civ computation)
xtable=round(par_civ.Grid(:,1)+0.5)-0.5;
ytable=round(par_civ.ImageHeight-par_civ.Grid(:,2)+0.5)-0.5;% y index corresponding to the position in image coordiantes
utable=shiftx;%zeros(nbvec,1);
vtable=shifty;%zeros(nbvec,1);
ctable=zeros(nbvec,1);
F=zeros(nbvec,1);
result_conv=[];
errormsg='';

%% prepare mask
if isfield(par_civ,'Mask') && ~isempty(par_civ.Mask)
    if strcmp(par_civ.Mask,'all')
        return    % get the grid only, no civ calculation
    elseif ischar(par_civ.Mask)
        par_civ.Mask=imread(par_civ.Mask);% read the mask if not allready done
    end
end
check_MinIma=isfield(par_civ,'MinIma');% test for image luminosity threshold
check_MaxIma=isfield(par_civ,'MaxIma') && ~isempty(par_civ.MaxIma);

par_civ.ImageA=sum(double(par_civ.ImageA),3);%sum over rgb component for color images
par_civ.ImageB=sum(double(par_civ.ImageB),3);
[npy_ima npx_ima]=size(par_civ.ImageA);
if ~isequal(size(par_civ.ImageB),[npy_ima npx_ima])
    errormsg='image pair with unequal size';
    return
end

%% Apply mask
% Convention for mask IDEAS TO IMPLEMENT ?
% mask >200 : velocity calculated
%  200 >=mask>150;velocity not calculated, interpolation allowed (bad spots)
% 150>=mask >100: velocity not calculated, nor interpolated
%  100>=mask> 20: velocity not calculated, impermeable (no flux through mask boundaries)
%  20>=mask: velocity=0
checkmask=0;
MinA=min(min(par_civ.ImageA));
%MinB=min(min(par_civ.ImageB));
%check_undefined=false(size(par_civ.ImageA));
if isfield(par_civ,'Mask') && ~isempty(par_civ.Mask)
    checkmask=1;
    if ~isequal(size(par_civ.Mask),[npy_ima npx_ima])
        errormsg='mask must be an image with the same size as the images';
        return
    end
    check_undefined=(par_civ.Mask<200 & par_civ.Mask>=20 );
    %     par_civ.ImageA(check_undefined)=0;% put image A to zero (i.e. the min image value) in the undefined  area
    %     par_civ.ImageB(check_undefined)=0;% put image B to zero (i.e. the min image value) in the undefined  area
end

%% compute image correlations: MAINLOOP on velocity vectors
corrmax=0;
sum_square=1;% default
mesh=1;% default
CheckDeformation=isfield(par_civ,'CheckDeformation')&& par_civ.CheckDeformation==1;
if CheckDeformation
    mesh=0.25;%mesh in pixels for subpixel image interpolation (x 4 in each direction)
    par_civ.CorrSmooth=2;% use SUBPIX2DGAUSS (take into account more points near the max)
end

if par_civ.CorrSmooth~=0 % par_civ.CorrSmooth=0 implies no civ computation (just input image and grid points given)
    for ivec=1:nbvec
        iref=round(par_civ.Grid(ivec,1)+0.5);% xindex on the image A for the middle of the correlation box
        jref=round(par_civ.ImageHeight-par_civ.Grid(ivec,2)+0.5);%  j index  for the middle of the correlation box in the image A
        F(ivec)=0;
        subrange1_x=iref-ibx2:iref+ibx2;% x indices defining the first subimage
        subrange1_y=jref-iby2:jref+iby2;% y indices defining the first subimage
        subrange2_x=iref+shiftx(ivec)-isx2:iref+shiftx(ivec)+isx2;%x indices defining the second subimage
        subrange2_y=jref+shifty(ivec)-isy2:jref+shifty(ivec)+isy2;%y indices defining the second subimage
        image1_crop=MinA*ones(numel(subrange1_y),numel(subrange1_x));% default value=min of image A
        image2_crop=MinA*ones(numel(subrange2_y),numel(subrange2_x));% default value=min of image A
        check1_x=subrange1_x>=1 & subrange1_x<=par_civ.ImageWidth;% check which points in the subimage 1 are contained in the initial image 1
        check1_y=subrange1_y>=1 & subrange1_y<=par_civ.ImageHeight;
        check2_x=subrange2_x>=1 & subrange2_x<=par_civ.ImageWidth;% check which points in the subimage 2 are contained in the initial image 2
        check2_y=subrange2_y>=1 & subrange2_y<=par_civ.ImageHeight;
        image1_crop(check1_y,check1_x)=par_civ.ImageA(subrange1_y(check1_y),subrange1_x(check1_x));%extract a subimage (correlation box) from image A
        image2_crop(check2_y,check2_x)=par_civ.ImageB(subrange2_y(check2_y),subrange2_x(check2_x));%extract a larger subimage (search box) from image B
        if checkmask
            mask1_crop=ones(numel(subrange1_y),numel(subrange1_x));% default value=1 for mask
            mask2_crop=ones(numel(subrange2_y),numel(subrange2_x));% default value=1 for mask
            mask1_crop(check1_y,check1_x)=check_undefined(subrange1_y(check1_y),subrange1_x(check1_x));%extract a mask subimage (correlation box) from image A
            mask2_crop(check2_y,check2_x)=check_undefined(subrange2_y(check2_y),subrange2_x(check2_x));%extract a mask subimage (search box) from image B
            sizemask=sum(sum(mask1_crop))/(numel(subrange1_y)*numel(subrange1_x));%size of the masked part relative to the correlation sub-image
            if sizemask > 1/2% eliminate point if more than half of the correlation box is masked
                F(ivec)=3; %
                utable(ivec)=0;
                vtable(ivec)=0;
            else
                image1_crop=image1_crop.*~mask1_crop;% put to zero the masked pixels (mask1_crop='true'=1)
                image2_crop=image2_crop.*~mask2_crop;
                image1_mean=mean(mean(image1_crop))/(1-sizemask);
                image2_mean=mean(mean(image2_crop))/(1-sizemask);
            end
        else
            image1_mean=mean(mean(image1_crop));
            image2_mean=mean(mean(image2_crop));
        end
        %threshold on image minimum
        if F(ivec)~=3
            if check_MinIma && (image1_mean < par_civ.MinIma || image2_mean < par_civ.MinIma)
                F(ivec)=3;
                %threshold on image maximum
            elseif check_MaxIma && (image1_mean > par_civ.MaxIma || image2_mean > par_civ.MaxIma)
                F(ivec)=3;
            end
            if F(ivec)==3
                utable(ivec)=0;
                vtable(ivec)=0;
            else
                %mask
                if checkmask
                    image1_crop=(image1_crop-image1_mean).*~mask1_crop;%substract the mean, put to zero the masked parts
                    image2_crop=(image2_crop-image2_mean).*~mask2_crop;
                else
                    image1_crop=(image1_crop-image1_mean);
                    image2_crop=(image2_crop-image2_mean);
                end
                %deformation
                if CheckDeformation
                    xi=(1:mesh:size(image1_crop,2));
                    yi=(1:mesh:size(image1_crop,1))';
                    [XI,YI]=meshgrid(xi-ceil(size(image1_crop,2)/2),yi-ceil(size(image1_crop,1)/2));
                    XIant=XI-par_civ.DUDX(ivec)*XI+par_civ.DUDY(ivec)*YI+ceil(size(image1_crop,2)/2);
                    YIant=YI+par_civ.DVDX(ivec)*XI-par_civ.DVDY(ivec)*YI+ceil(size(image1_crop,1)/2);
                    image1_crop=interp2(image1_crop,XIant,YIant);
                    image1_crop(isnan(image1_crop))=0;
                    xi=(1:mesh:size(image2_crop,2));
                    yi=(1:mesh:size(image2_crop,1))';
                    image2_crop=interp2(image2_crop,xi,yi,'*spline');
                    image2_crop(isnan(image2_crop))=0;
                end
                sum_square=sum(sum(image1_crop.*image1_crop));
                %reference: Oliver Pust, PIV: Direct Cross-Correlation
                result_conv= conv2(image2_crop,flipdim(flipdim(image1_crop,2),1),'valid');
                corrmax= max(max(result_conv));
                result_conv=(result_conv/corrmax)*255; %normalize, peak=always 255
                %Find the correlation max, at 255
                [y,x] = find(result_conv==255,1);
                subimage2_crop=image2_crop(y:y+2*iby2/mesh,x:x+2*ibx2/mesh);%subimage of image 2 corresponding to the optimum displacement of first image
                sum_square=sum_square*sum(sum(subimage2_crop.*subimage2_crop));% product of variances of image 1 and 2
                sum_square=sqrt(sum_square);% srt of the variance product to normalise correlation
                if ~isempty(y) && ~isempty(x)
                    try
                        if par_civ.CorrSmooth==1
                            [vector,F(ivec)] = SUBPIXGAUSS (result_conv,x,y);
                        elseif par_civ.CorrSmooth==2
                            [vector,F(ivec)] = SUBPIX2DGAUSS (result_conv,x,y);
                        else
                            [vector,F(ivec)] = quadr_fit(result_conv,x,y);
                        end
                        utable(ivec)=vector(1)*mesh+shiftx(ivec);
                        vtable(ivec)=vector(2)*mesh+shifty(ivec);
                        xtable(ivec)=iref+utable(ivec)/2-0.5;% convec flow (velocity taken at the point middle from imgae 1 and 2)
                        ytable(ivec)=jref+vtable(ivec)/2-0.5;% and position of pixel 1=0.5 (convention for image coordinates=0 at the edge)
                        iref=round(xtable(ivec)+0.5);% nearest image index for the middle of the vector
                        jref=round(ytable(ivec)+0.5);
                        % eliminate vectors located in the mask
                        if  checkmask && (iref<1 || jref<1 ||iref>npx_ima || jref>npy_ima ||( par_civ.Mask(jref,iref)<200 && par_civ.Mask(jref,iref)>=100))
                            utable(ivec)=0;
                            vtable(ivec)=0;
                            F(ivec)=3;
                        end
                        ctable(ivec)=corrmax/sum_square;% correlation value
                    catch ME
                        F(ivec)=3;
                        disp(ME.message)
                    end
                else
                    F(ivec)=3;
                end
            end
        end
    end
end
result_conv=result_conv*corrmax/(255*sum_square);% keep the last correlation matrix for output

%------------------------------------------------------------------------
% --- Find the maximum of the correlation function after interpolation
% OUPUT:
% vector = optimum displacement vector with subpixel correction
% F =flag: =0 OK
%           =-2 , warning: max too close to the edge of the search box (1 pixel margin)
% INPUT:
% x,y: position of the maximum correlation at integer values

function [vector,F] = SUBPIXGAUSS (result_conv,x,y)
%------------------------------------------------------------------------
% vector=[0 0]; %default
F=0;
[npy,npx]=size(result_conv);
result_conv(result_conv<1)=1; %set to 1 correlation values smaller than 1  (=0 by discretisation, to avoid divergence in the log)
%the following 8 lines are copyright (c) 1998, Uri Shavit, Roi Gurka, Alex Liberzon, Technion ??? Israel Institute of Technology
%http://urapiv.wordpress.com
peaky = y;
if y < npy && y > 1
    f0 = log(result_conv(y,x));
    f1 = log(result_conv(y-1,x));
    f2 = log(result_conv(y+1,x));
    peaky = peaky+ (f1-f2)/(2*f1-4*f0+2*f2);
else
    F=-2; % warning flag for vector truncated by the limited search box
end
peakx=x;
if x < npx-1 && x > 1
    f0 = log(result_conv(y,x));
    f1 = log(result_conv(y,x-1));
    f2 = log(result_conv(y,x+1));
    peakx = peakx+ (f1-f2)/(2*f1-4*f0+2*f2);
else
    F=-2; % warning flag for vector truncated by the limited search box
end
vector=[peakx-floor(npx/2)-1 peaky-floor(npy/2)-1];

%------------------------------------------------------------------------
% --- Find the maximum of the correlation function after interpolation
function [vector,F] = SUBPIX2DGAUSS (result_conv,x,y)
%------------------------------------------------------------------------
% vector=[0 0]; %default
F=-2;
peaky=y;
peakx=x;
result_conv(result_conv<1)=1; %set to 1 correlation values smaller than 1 (to avoid divergence in the log)
[npy,npx]=size(result_conv);
if (x < npx) && (y < npy) && (x > 1) && (y > 1)
    F=0;
    for i=-1:1
        for j=-1:1
            %following 15 lines based on
            %H. Nobach ??? M. Honkanen (2005)
            %Two-dimensional Gaussian regression for sub-pixel displacement
            %estimation in particle image velocimetry or particle position
            %estimation in particle tracking velocimetry
            %Experiments in Fluids (2005) 38: 511???515
            c10(j+2,i+2)=i*log(result_conv(y+j, x+i));
            c01(j+2,i+2)=j*log(result_conv(y+j, x+i));
            c11(j+2,i+2)=i*j*log(result_conv(y+j, x+i));
            c20(j+2,i+2)=(3*i^2-2)*log(result_conv(y+j, x+i));
            c02(j+2,i+2)=(3*j^2-2)*log(result_conv(y+j, x+i));
        end
    end
    c10=(1/6)*sum(sum(c10));
    c01=(1/6)*sum(sum(c01));
    c11=(1/4)*sum(sum(c11));
    c20=(1/6)*sum(sum(c20));
    c02=(1/6)*sum(sum(c02));
    deltax=(c11*c01-2*c10*c02)/(4*c20*c02-c11^2);
    deltay=(c11*c10-2*c01*c20)/(4*c20*c02-c11^2);
    if abs(deltax)<1
        peakx=x+deltax;
    end
    if abs(deltay)<1
        peaky=y+deltay;
    end
end
vector=[peakx-floor(npx/2)-1 peaky-floor(npy/2)-1];

%------------------------------------------------------------------------
% --- Find the maximum of the correlation function after quadratic interpolation
function [vector,F] = quadr_fit(result_conv,x,y)
[npy,npx]=size(result_conv);
if x<4 || y<4 || npx-x<4 ||npy-y <4
    F=-2;
    vector=[x y];
else
    F=0;
    x_ind=x-4:x+4;
    y_ind=y-4:y+4;
    x_vec=0.25*(x_ind-x);
    y_vec=0.25*(y_ind-y);
    [X,Y]=meshgrid(x_vec,y_vec);
    coord=[reshape(X,[],1) reshape(Y,[],1)];
    result_conv=reshape(result_conv(y_ind,x_ind),[],1);
    
    
    % n=numel(X);
    % x=[X Y];
    % X=X-0.5;
    % Y=Y+0.5;
    % y = (X.*X+2*Y.*Y+X.*Y+6) + 0.1*rand(n,1);
    p = polyfitn(coord,result_conv,2);
    A(1,1)=2*p.Coefficients(1);
    A(1,2)=p.Coefficients(2);
    A(2,1)=p.Coefficients(2);
    A(2,2)=2*p.Coefficients(4);
    vector=[x y]'-A\[p.Coefficients(3) p.Coefficients(5)]';
    vector=vector'-[floor(npx/2) floor(npy/2)]-1 ;
    % zg = polyvaln(p,coord);
    % figure
    % surf(x_vec,y_vec,reshape(zg,9,9))
    % hold on
    % plot3(X,Y,reshape(result_conv,9,9),'o')
    % hold off
end

%'RUN_FIX': function for fixing velocity fields:
%-----------------------------------------------
% RUN_FIX(filename,field,flagindex,thresh_vecC,thresh_vel,iter,flag_mask,maskname,fileref,fieldref)
%
%filename: name of the netcdf file (used as input and output)
%field: structure specifying the names of the fields to fix (depending on civ1 or civ2)
%.vel_type='civ1' or 'civ2';
%.nb=name of the dimension common to the field to fix ('nb_vectors' for civ1);
%.fixflag=name of fix flag variable ('vec_FixFlag' for civ1)
%flagindex: flag specifying which values of vec_f are removed:
% if flagindex(1)=1: vec_f=-2 vectors are removed
% if flagindex(2)=1: vec_f=3 vectors are removed
% if flagindex(3)=1: vec_f=2 vectors are removed (if iter=1) or vec_f=4 vectors are removed (if iter=2)
%iter=1 for civ1 fields and iter=2 for civ2 fields
%thresh_vecC: threshold in the image correlation vec_C
%flag_mask: =1 mask used to remove vectors (0 else)
%maskname: name of the mask image file for fix
%thresh_vel: threshold on velocity, or on the difference with the reference file fileref if exists
%inf_sup=1: remove values smaller than threshold thresh_vel, =2, larger than threshold
%fileref: .nc file name for a reference velocity (='': refrence 0 used)
%fieldref: 'civ1','filter1'...feld used in fileref

function FF=fix(Param,F,C,U,V,X,Y)
FF=zeros(size(F));%default

%criterium on warn flags
FlagName={'CheckFmin2','CheckF2','CheckF3','CheckF4'};
FlagVal=[-2 2 3 4];
for iflag=1:numel(FlagName)
    if isfield(Param,FlagName{iflag}) && Param.(FlagName{iflag})
        FF=(FF==1| F==FlagVal(iflag));
    end
end
%criterium on correlation values
if isfield (Param,'MinCorr')
    FF=FF==1 | C<Param.MinCorr;
end
if (isfield(Param,'MinVel')&&~isempty(Param.MinVel))||(isfield (Param,'MaxVel')&&~isempty(Param.MaxVel))
    Umod= U.*U+V.*V;
    if isfield (Param,'MinVel')&&~isempty(Param.MinVel)
        FF=FF==1 | Umod<(Param.MinVel*Param.MinVel);
    end
    if isfield (Param,'MaxVel')&&~isempty(Param.MaxVel)
        FF=FF==1 | Umod>(Param.MaxVel*Param.MaxVel);
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




