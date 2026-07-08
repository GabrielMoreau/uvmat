%'stereo_series': PIV function activated by the general GUI series
% --- call the sub-functions:
%   civ: PIV function itself
%   fix: removes false vectors after detection by various criteria
%   filter_tps: make interpolation-smoothing
%------------------------------------------------------------------------
% function [Data,errormsg,result_conv]= civ_series(Param,ncfile)
%
%OUTPUT
% Data=structure containing the PIV results and information on the processing parameters
% errormsg=error message char string, default=''
% resul_conv: image inter-correlation function for the last grid point (used for tests)
%
%INPUT:
% Param: input images and processing parameters
%     .Civ1: for civ1
%     .Fix1:
%     .Patch1:
%     .Civ2: for civ2
%     .Fix2:
%     .Patch2:
% ncfile: name of a netcdf file to be created for the result (extension .nc)
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (open UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function [Data,errormsg,result_conv, XmlData]= stereo_civ(Param)
Data=[];
errormsg='';

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)% function activated from the GUI series but not RUN
    if size(Param.InputTable,1)<2
        msgbox_uvmat('WARNING','two input file series must be entered')
        return
    end
    path_series=fileparts(which('series'));
    addpath(fullfile(path_series,'series'))
    Data=stereo_input(Param);% introduce the civ parameters using the GUI stereo_input
    if isempty(Data)
        Data=Param;% if  civ_input has been cancelled, keep previous parameters
    end
    Data.Program=mfilename;%gives the name of the current function
    Data.AllowInputSort='on';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    Data.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    Data.NbSlice='off'; %nbre of slices ('off' by default)
    Data.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    Data.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    Data.FieldTransform = 'off';%can use a transform function (use it by force, no input option)
    Data.ProjObject='off';%can use projection object(option 'off'/'on',
    Data.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    Data.OutputDirExt='.stereo';%set the output dir extension
    Data.OutputSubDirMode='auto'; %select the last subDir in the input table as root of the output subdir name (option 'all'/'first'/'last', 'all' by default)
    Data.OutputFileMode='NbInput_i';% one output file expected per value of i index (used for waitbar)
    Data.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default=1)

    return
end

%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
if ~isfield(Param,'ActionInput')
    disp_uvmat('ERROR','no parameter set for PIV',checkrun)
    return
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series

inv_scale_factor=100; % scale factor of displacements for uin16 records in netcdf files (dx expressed in pixels)
%inv_scale_factor=[];% no scale factor, displacements written as single precision real

% %% input files and indexing
% MaxIndex_i=Param.IndexRange.MaxIndex_i;
% MinIndex_i=Param.IndexRange.MinIndex_i;
% if ~isfield(Param,'InputTable')
%     disp_uvmat('ERROR', 'no input field',checkrun)
%     return
% end
NbView=size(Param.InputTable,1);
% [tild,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% time=[];
XmlData=cell(1,NbView);
% for iview=1:NbView
%     XmlFileName=find_imadoc(Param.InputTable{iview,1},Param.InputTable{iview,2});
%     if isempty(XmlFileName)
%         disp_uvmat('ERROR', [XmlFileName ' not found'],checkrun)
%         return
%     end
%     XmlData{iview}=imadoc2struct(XmlFileName);
%     if isfield(XmlData{iview},'Time')
%         time=XmlData{iview}.Time;
%         TimeSource='xml';
%     end
%     if isfield(XmlData{iview},'Camera')
%         if isfield(XmlData{iview}.Camera,'NbSlice')&& ~isempty(XmlData{iview}.Camera.NbSlice)
%             NbSlice_calib{iview}=XmlData{iview}.Camera.NbSlice;% Nbre of slices for Zindex in phys transform
%             if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
%                 msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
%             end
%         end
%         if isfield(XmlData{iview}.Camera,'TimeUnit')&& ~isempty(XmlData{iview}.Camera.TimeUnit)
%             TimeUnit=XmlData{iview}.Camera.TimeUnit;
%         end
%     end
% end

%% File relabeling documented by the xml file
CheckRelabel=isfield(Param.IndexRange,'Relabel' )&& Param.IndexRange.Relabel;%=true for index relabeling (PCO);

%% Input file info
for iview=1:NbView
    RootPath=Param.InputTable{iview,1};
    RootFile=Param.InputTable{iview1,3};
    SubDir=Param.InputTable{iview,2};
    NomType=Param.InputTable{iview,4};
    FileExt=Param.InputTable{iview,5};
    if CheckRelabel
        XmlFileName=find_imadoc(RootPath,SubDir);
        if ~isempty(XmlFileName)
            XmlData{iview}=imadoc2struct(XmlFileName);%read the time from XmlFileName
            if isfield(XmlData{iview},'Time')
                time=XmlData{iview}.Time;
                TimeSource='xml';
            end
        end
        RootFileOut='frame';
        [RootFile,frame_index]=index2filename(XmlData.FileSeries,Param.IndexRange.first_i,j_indices(1),NbField_j);
        FirstFileName=fullfile(RootPath,SubDir,RootFile);
    else
        FirstFileName=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,Param.IndexRange.first_i,[],j_indices(1));%get first file name
        RootFileOut=RootFile;
    end
    [FileInfo,MovieObject]=get_file_info(FirstFileName);
    if isfield(FileInfo,'ColorType') && strcmp(FileInfo.ColorType,'truecolor')
        BitDepth=16;
    else
        BitDepth=FileInfo.BitDepth;
    end
    FileType=FileInfo.FileType;
    if ~CheckRelabel
        if isfield(FileInfo,'NumberOfFrames') && FileInfo.NumberOfFrames >1
            if isempty(regexp(NomType,'1$', 'once'))% no file indexing
                frame_index=i_indices;% the index i denotes the frame number in a movie, no index j
            else
                frame_index=j_indices;% the index j denotes the frame number in a movie
                MovieObject=[]; %not a single video object
            end
        else
            frame_index=ones(1,nbfield);
        end
    end
end






iview_A=1;% series index (iview) for the first image series
iview_B=2;% series index (iview) for the second image series (only non zero for option 'shift' comparing two image series )

RootPath_A=Param.InputTable{1,1};
RootFile_A=Param.InputTable{1,3};
SubDir_A=Param.InputTable{1,2};
NomType_A=Param.InputTable{1,4};
FileExt_A=Param.InputTable{1,5};
RootPath_B=Param.InputTable{2,1};
RootFile_B=Param.InputTable{2,3};
SubDir_B=Param.InputTable{2,2};
NomType_B=Param.InputTable{2,4};
FileExt_B=Param.InputTable{2,5};
PairCiv2='';

i1_series_Civ1=i1_series{1};i1_series_Civ2=i1_series{1};
if isempty(j1_series{1})
    FrameIndex_A_Civ1=i1_series_Civ1;
    FrameIndex_B_Civ1=i2_series_Civ1;
    j1_series_Civ1=ones(size(i1_series{1}));
    j2_series_Civ1=ones(size(i1_series{2}));
else
    j1_series_Civ1=j1_series{1};
    j2_series_Civ1=j1_series{2};
    FrameIndex_A_Civ1=j1_series_Civ1;
    FrameIndex_B_Civ1=j2_series_Civ1;
end

if isempty(i1_series_Civ1)
    disp_uvmat('ERROR','no image pair for civ in the input file index range',checkrun)
    return
end

%% check the first image pair


%% Output directory and data preparation
   
LSM=Param.ActionInput.CheckLSM; % variable for light saving or not.
OutputDir=[Param.OutputSubDir Param.OutputDirExt];

ListGlobalAttribute={'Conventions','Program','CivStage'};
Data.ListVarName={'X','Y','U','V','C','FF'};%  cell array containing the names of the fields to record
Data.VarDimName={'nb_vec','nb_vec','nb_vec','nb_vec','nb_vec','nb_vec'};
Data.VarAttribute{1}.Role='coord_x';
Data.VarAttribute{2}.Role='coord_y';
Data.VarAttribute{3}.Role='vector_x';
Data.VarAttribute{3}.scale_factor=1/inv_scale_factor;
Data.VarAttribute{4}.Role='vector_y';
Data.VarAttribute{4}.scale_factor=1/inv_scale_factor;
Data.VarAttribute{5}.Role='ancillary';
Data.VarAttribute{5}.scale_factor=1/100;%scla factor for correlation
Data.VarAttribute{6}.Role='errorflag';
Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
Data.Program=mfilename;%gives the name of the current function;
Data.CivStage=0;%default
maskname='';%default
if ~LSM
   Data.ListVarName=[Data.ListVarName {'Xphys','Yphys','Zphys'}];
   Data.VarDimName=[Data.VarDimName {'nb_vec','nb_vec','nb_vec'}];
end

%% get timing from input video
if isempty(time) && ismember(FileType_A,{'mmreader','video','cine_phantom'})% case of video input
    time=zeros(FileInfo_A.NumberOfFrames+1,2);
    time(:,2)=(0:1/FileInfo_A.FrameRate:(FileInfo_A.NumberOfFrames)/FileInfo_A.FrameRate)';
    TimeSource='video';
    ColorType='truecolor';
end
if isempty(time)% time = index i  by default
    MaxIndex_i=max(i2_series_Civ1, [], 'all');
    MaxIndex_j=max(j2_series_Civ1, [], 'all');
    time=(1:MaxIndex_i)'*ones(1,MaxIndex_j);
    time=[zeros(1,MaxIndex_j);time];% insert a first line of zeros
    time=[zeros(MaxIndex_i+1,1) time];% insert a first column of zeros
end

if length(FileInfo_A) >1 %case of image with multiple frames
    nbfield=length(FileInfo_A);
    nbfield_j=1;
end

CheckOverwrite=1;%default
if isfield(Param,'CheckOverwrite')
    CheckOverwrite=Param.CheckOverwrite;
end
Index_i_series=Param.IndexRange.first_i:Param.IndexRange.incr_i:Param.IndexRange.last_i;
if isfield(Param.IndexRange,'last_j')
    Index_j_series=Param.IndexRange.first_j:Param.IndexRange.incr_j:Param.IndexRange.last_j;
else
    Index_j_series=1;
end








%%%%% MAIN LOOP %%%%%%
for index_i=Index_i_series
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    for index_j=Index_j_series
        
        if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
            disp('program stopped by user')
            break
        end
% if index_j==Index_j_series(1) && 
% try
%     ImageName_A=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1_series_Civ1(1),[],j1_series_Civ1(1));
%     if ~exist(ImageName_A,'file')
%         disp_uvmat('ERROR',['first input image ' ImageName_A ' does not exist'],checkrun)
%         return
%     end
%     [FileInfo_A,VideoObject_A]=get_file_info(ImageName_A);
%     FileType_A=FileInfo_A.FileType;
%     if strcmp(FileInfo_A.FileType,'netcdf')
%         FieldName_A=Param.InputFields.FieldName;
%         [DataIn,tild,tild,errormsg]=nc2struct(ImageName_A,{FieldName_A});
%         par_civ1.ImageA=DataIn.(FieldName_A);
%     else
%         [par_civ1.ImageA,VideoObject_A] = read_image(ImageName_A,FileType_A,VideoObject_A,FrameIndex_A_Civ1(1));
%     end
%     ImageName_B=fullfile_uvmat(RootPath_B,SubDir_B,RootFile_B,FileExt_B,NomType_B,i2_series_Civ1(1),[],j2_series_Civ1(1));
%     if ~exist(ImageName_B,'file')
%         disp_uvmat('ERROR',['first input image ' ImageName_B ' does not exist'],checkrun)
%         return
%     end
%     [FileInfo_B,VideoObject_B]=get_file_info(ImageName_B);
%     FileType_B=FileInfo_B.FileType;
%     if strcmp(FileInfo_B.FileType,'netcdf')
%         FieldName_B=Param.InputFields.FieldName;
%         [DataIn,tild,tild,errormsg]=nc2struct(ImageName_B,{FieldName_B});
%         par_civ1.ImageB=DataIn.(FieldName_B);
%     else
%         [par_civ1.ImageB,VideoObject_B] = read_image(ImageName_B,FileType_B,VideoObject_B,FrameIndex_B_Civ1(1));
%     end
%     NbField=numel(i1_series_Civ1);
% 
% catch ME
%     if ~isempty(ME.message)
%         disp_uvmat('ERROR', ['error reading input image: ' ME.message],checkrun)
%         return
%     end
% end
% if ismember(FileType_A,{'mmreader','video','cine_phantom'})
%     NomTypeNc='_1';
% else
%     NomTypeNc=NomType_A;
% end



        tstart=tic;
        Civ1Dir=OutputDir;

        ncfile=fullfile_uvmat(RootPath_A,Civ1Dir,RootFile_A,'.nc',NomTypeNc,i2_series_Civ1(ifield),[],...
            j1_series_Civ1(ifield),j2_series_Civ1(ifield));

        if ~CheckOverwrite && exist(ncfile,'file')
            disp('existing output file already exists, skip to next field')
            result_conv=0;
            continue% skip iteration if the mode overwrite is desactivated and the result file already exists
        end

        try
            ImageName_A=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1_series_Civ1(ifield),[],j1_series_Civ1(ifield));
            [A{1},VideoObject_A] = read_image(ImageName_A,FileType_A,VideoObject_A,FrameIndex_A_Civ1(ifield));
            ImageName_B=fullfile_uvmat(RootPath_B,SubDir_B,RootFile_B,FileExt_B,NomType_B,i2_series_Civ1(ifield),[],j2_series_Civ1(ifield));
            [A{2},VideoObject_B] = read_image(ImageName_B,FileType_B,VideoObject_B,FrameIndex_B_Civ1(ifield));
        catch ME
            if ~isempty(ME.message)
                disp_uvmat('ERROR', ['error reading input image: ' ME.message],checkrun)
                return
            end
        end

        [A,Rangx,Rangy]=phys_ima(A,XmlData,1);%transform image A in phys coordinates
        [Npy,Npx]=size(A{1});

        if LSM ~= 1 % save images in phys coordinates for test mode
            PhysImageAName=fullfile_uvmat(RootPath_A,Civ1Dir,RootFile_A,'.png','_1a',i1_series_Civ1(ifield),[],1);
            PhysImageBName=fullfile_uvmat(RootPath_A,Civ1Dir,RootFile_A,'.png','_1a',i1_series_Civ1(ifield),[],2);
            imwrite(A{1},PhysImageAName)
            imwrite(A{2},PhysImageBName)
        end

        %% Civ1
        if isfield (Param.ActionInput,'Civ1')
            tstart_civ1=tic;
            par_civ1=Param.ActionInput.Civ1;

            par_civ1.ImageA=A{1};
            par_civ1.ImageB=A{2};
            par_civ1.ImageWidth=size(par_civ1.ImageA,2);%FileInfo_A.Width;
            par_civ1.ImageHeight=size(par_civ1.ImageA,1);%FileInfo_A.Height;
            list_param=(fieldnames(Param.ActionInput.Civ1))';
            Civ1_param=regexprep(list_param,'^.+','Civ1_$0');% insert 'Civ1_' before  each string in list_param
            Civ1_param=[{'Civ1_ImageA','Civ1_ImageB','Civ1_Time','Civ1_Dt'} Civ1_param]; %insert the names of the two input images
            %indicate the values of all the global attributes in the output data
            Data.Civ1_ImageA=ImageName_A;
            Data.Civ1_ImageB=ImageName_B;

            % case of image luminosity rescaling
            if Param.ActionInput.CheckRescale &&~isempty(Param.ActionInput.Maxtanh)
                par_civ1.ImageA =Param.ActionInput.Maxtanh*tanh(double(par_civ1.ImageA)/Param.ActionInput.Maxtanh);
                par_civ1.ImageB=Param.ActionInput.Maxtanh*tanh(double(par_civ1.ImageB)/Param.ActionInput.Maxtanh);
            end

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
            Data.Civ1_Time=(time(j2+1,i2+1)+time(j1+1,i1+1))/2;
            Data.Civ1_Dt=time(j2+1,i2+1)-time(j1+1,i1+1);
            if Data.Civ1_Dt~=0
                disp(['warning: the times of the two fields differ by ' num2str(Data.Civ1_Dt)])
            end
            for ilist=1:length(list_param)
                Data.(Civ1_param{4+ilist})=Param.ActionInput.Civ1.(list_param{ilist});
            end
            Data.ListGlobalAttribute=[ListGlobalAttribute Civ1_param];
            Data.CivStage=1;

            %         % set the list of variables
            %         Data.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_F','Civ1_C'};%  cell array containing the names of the fields to record
            %         Data.VarDimName={'nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1'};
            %         Data.VarAttribute{1}.Role='coord_x';
            %         Data.VarAttribute{2}.Role='coord_y';
            %         Data.VarAttribute{3}.Role='vector_x';
            %         Data.VarAttribute{4}.Role='vector_y';
            %         Data.VarAttribute{5}.Role='warnflag';


            % calculate velocity data (y and v in indices, reverse to y component)
            if strcmp(Param.RunMode,'cluster')
                [Civ_X,Civ_Y,Civ_U,Civ_V,Civ_C,Civ_FF,~, errormsg] = civ (par_civ1);% single processor used in cluster
            else
                [Civ_X,Civ_Y,Civ_U,Civ_V,Civ_C,Civ_FF,~,errormsg] = parciv (par_civ1);%use parfor loop
            end
            Civ_X_shifted=Civ_X-0.5+Civ_U/2;% get the exact positions
            Civ_Y_shifted=Civ_Y-0.5+Civ_V/2;
            if ~isempty(errormsg)
                disp_uvmat('ERROR',errormsg,checkrun)
                return
            end

            %%%%%%%%%%%%%%%% ajout fonction test %%%%%%%
            %         if ~isfield (Param.ActionInput,'Civ2') && ~isfield (Param.ActionInput,'Civ3') && ~isfield(Param.ActionInput,'Patch1')
            [Data.Xmid, Data.Ymid, Data.Uphys, Data.Vphys, Data.Zphys, ...
                Data.Yphys, Data.Xphys, Data.Error] = getPhysValues(Rangx, ...
                Rangy, Npx, Npy, Data.Civ1_X, Data.Civ1_Y, Data.Civ1_U, ...
                Data.Civ1_V, XmlData);

            if ~isempty(errormsg)
                disp_uvmat('ERROR',errormsg,checkrun)
                return
            end
            %         end
            time_civ1=toc(tstart_civ1);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
            % Data.Civ1_FF=uint8(detect_false(Param.ActionInput.Fix1,Data.Civ1_C,Data.Civ1_U,Data.Civ1_V,Data.Civ1_FF));
            Civ_FF=uint8(detect_false(Param.ActionInput.Fix1,Civ_C,Civ_U,Civ_V,Civ_FF));
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

            if isempty(Civ_FF)
                ind_good=1:numel(Civ_X);
            else
                ind_good=find(Civ_FF==0);
            end
            if isempty(ind_good)
                disp_uvmat('ERROR','all vectors of civ1 are bad, check input parameters' ,checkrun)
                return
            end

            % perform Patch calculation using the UVMAT fct 'filter_tps'
            [SubRange,NbCentres,Coord_tps,U_tps,V_tps,~,Ures, Vres,~,FFres]=...
                filter_tps([Civ_X_shifted(ind_good),Civ_Y_shifted(ind_good)],Civ_U(ind_good),Civ_V(ind_good),[],Data.Patch1_SubDomainSize,Data.Patch1_FieldSmooth,Data.Patch1_MaxDiff);
            Civ_U_smooth=Civ_U;% false vectors kept unchanged
            Civ_V_smooth=Civ_V;
            Civ_U_smooth(ind_good)=Ures;% take the interpolated (smoothed) velocity values for good vectors, keep civ1 data for the other
            Civ_V_smooth(ind_good)=Vres;
            Civ_FF(ind_good)=uint8(4*FFres);%set FF to value =4 for vectors eliminated by filter_tps
            time_patch1=toc(tstart_patch1);
            disp('patch1 performed')
        end

        %% Civ2
        if isfield (Param.ActionInput,'Civ2')
            disp('civ2 started')
            tstart_civ2=tic;
            par_civ2=Param.ActionInput.Civ2;
            par_civ2.ImageA=A{1};
            par_civ2.ImageB=A{2};
            par_civ2.ImageWidth=size(par_civ2.ImageA,2);%FileInfo_A.Width;
            par_civ2.ImageHeight=size(par_civ2.ImageA,1);%FileInfo_A.Height;
            list_param=(fieldnames(Param.ActionInput.Civ2))';
            Civ1_param=regexprep(list_param,'^.+','Civ1_$0');% insert 'Civ1_' before  each string in list_param
            Civ1_param=[{'Civ1_ImageA','Civ1_ImageB','Civ1_Time','Civ1_Dt'} Civ1_param]; %insert the names of the two input images
            %indicate the values of all the global attributes in the output data
            Data.ImageA=ImageName_A;
            Data.ImageB=ImageName_B;


            par_civ2.ImageA=[];
            par_civ2.ImageB=[];
            if CheckRelabel
                [RootFile,FrameIndex_A_2]=index2filename(XmlData.FileSeries,i1_series_Civ2(ifield),j1_series_Civ2(ifield),MaxIndex_j);
                ImageName_A_Civ2=fullfile(RootPath_A,SubDir_A,RootFile);
            else
                ImageName_A_Civ2=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1_civ2,[],j1_civ2);
                FrameIndex_A_2=FrameIndex_A_Civ2(ifield);
            end
            if strcmp(ImageName_A_Civ2,ImageName_A) && isequal(FrameIndex_A,FrameIndex_A_2)
                par_civ2.ImageA=par_civ1.ImageA;
                CheckDuplicate_1to2A=true;
            else
                [par_civ2.ImageA,VideoObject_A] = read_image(ImageName_A_Civ2,FileType_A,VideoObject_A,FrameIndex_A_2);
                CheckDuplicate_1to2A=false;
            end
            if CheckRelabel
                [RootFile,FrameIndex_B_2]=index2filename(XmlData.FileSeries,i2_civ2,j2_civ2,MaxIndex_j);
                ImageName_B_Civ2=fullfile(RootPath_B,SubDir_B,RootFile);
            else
                ImageName_B_Civ2=fullfile_uvmat(RootPath_B,SubDir_B,RootFile_B,FileExt_B,NomType_B,i2_civ2,[],j2_civ2);
                FrameIndex_B_2=FrameIndex_B_Civ2(ifield);
            end
            if strcmp(ImageName_B_Civ2,ImageName_B) && isequal(FrameIndex_B_2,FrameIndex_B)
                par_civ2.ImageB=par_civ1.ImageB;
                CheckDuplicate_1to2B=true;
            else
                [par_civ2.ImageB,VideoObject_B] = read_image(ImageName_B_Civ2,FileType_B,VideoObject_B,FrameIndex_B_2);
                CheckDuplicate_1to2B=false;
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
        end

        %% case of image luminosity rescaling
        if  par_civ2.CheckRescale && ~isempty(par_civ2.Maxtanh)
            if ~CheckDuplicate_1to2A %if the image A is different from civ1
                par_civ2.ImageA =par_civ2.Maxtanh*tanh(double(par_civ2.ImageA)/par_civ2.Maxtanh);
            end
            if ~CheckDuplicate_1to2B % if the image B is different from civ1
                par_civ2.ImageB=par_civ2.Maxtanh*tanh(double(par_civ2.ImageB)/par_civ2.Maxtanh);
            end
        end

        % get the guess from patch1 or patch2 (case 'CheckCiv3')
        if iview_A==2 && isfield (par_civ2,'CheckCiv3') && strcmp(par_civ2.CheckCiv3,'iterate(civ3)') %get the guess from  patch2% Civ1 data read in a netcdf file
            [DataIn,~,~,errormsg]=nc2struct(filecell{1,ifield});%TO UPDATE*******!!!
            if ~isempty(errormsg)
                disp(errormsg)
                return
            end
            SubRange= DataIn.Civ2_SubRange;
            NbCentres=DataIn.Civ2_NbCentres;
            Coord_tps=DataIn.Civ2_Coord_tps;
            U_tps=DataIn.Civ2_U_tps;
            V_tps=DataIn.Civ2_V_tps;
            Civ1_Dt=DataIn.Civ2_Dt;
            %         Data=[];%reinitialise the result structure Data
            %         Data.ListGlobalAttribute={'Conventions','Program','CivStage'};
            %         Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
            %         Data.Program='civ_series';
            %         Data.ListVarName={};
            %         Data.VarDimName={};
        else % get the guess from patch1
            %             SubRange= Data.Civ_SubRange;
            %             NbCentres=Data.Civ_NbCentres;
            %             Coord_tps=Data.Civ_Coord_tps;
            %             U_tps=Data.Civ_U_tps;
            %             V_tps=Data.Civ_V_tps;
            Civ1_Dt=Data.Civ1_Dt;
        end
        Data.CivStage=4;
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

            MaskRootName=Param.ActionInput.Civ2.Mask;
            NbSlice=[];
            if isfield(par_civ2,'NbSlice')
                NbSlice=par_civ2.NbSlice;
            end
            CheckVolumeScan=strcmp(NomTypeNc,'_1-2_1');
            maskname=get_mask_name(MaskRootName,i1_civ2,j1,NbSlice,CheckVolumeScan);

            if strcmp(maskoldname,maskname)% mask exist, not already read in civ1
                par_civ2.Mask=mask; %use mask already opened
            else
                if exist_file(maskname)
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
                    disp_uvmat('ERROR',[maskname ' does not exist'],checkrun);
                    return
                end
                mask=par_civ2.Mask;
                maskoldname=maskname;
            end
        end

        %% get civ2 correlation parameters
        if strcmp(Param.ActionInput.ListCompareMode,'displacement')
            Civ1_Dt=1;
            Civ2_Dt=1;
        else
            Civ2_Dt=Time(j2_civ2+1,i2_civ2+1)-Time(j1_civ2+1,i1_civ2+1);
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

        % calculate velocity data
        if strcmp(Param.RunMode,'cluster')
            [Civ_X,Civ_Y,Civ_U,Civ_V,Civ_C,Civ_FF,~, errormsg] = civ (par_civ2);% single processor used in cluster
        else
            [Civ_X,Civ_Y,Civ_U,Civ_V,Civ_C,Civ_FF,~, errormsg] = parciv (par_civ2);%use parfor loop
        end
        Civ_X_shifted=Civ_X-0.5+Civ_U/2;% get the exact positions
        Civ_Y_shifted=Civ_Y-0.5+Civ_V/2;
        list_param=(fieldnames(Param.ActionInput.Civ2))';
        list_param(strcmp('TestCiv2',list_param))=[];% remove the parameter TestCiv2 from the list
        Civ2_param1=regexprep(list_param,'^.+','Civ2_$0');% insert 'Civ2_' before  each string in list_param
        Civ2_param=[{'Civ2_ImageA','Civ2_ImageB','Civ2_FrameIndexA','Civ2_FrameIndexB','Civ2_Time','Civ2_Dt'} Civ2_param1]; %insert the names of the two input images
        %indicate the values of all the global attributes in the output data
        if exist('ImageName_A','var')
            Data.Civ2_ImageA=ImageName_A;
            Data.Civ2_ImageB=ImageName_B;
            Data.Civ2_FrameIndexA=FrameIndex_A_2;
            Data.Civ2_FrameIndexB=FrameIndex_B_2;
            if strcmp(Param.ActionInput.ListCompareMode,'displacement')
                Data.Civ2_Time=Time(j2_civ2+1,i2_civ2+1);% the Time is the Time of the secodn image
                Data.Civ2_Dt=1;% Time interval is 1, to yield displacement instead of velocity=displacement/Dt at reading
            else
                Data.Civ2_Time=(Time(j2_civ2+1,i2_civ2+1)+Time(j1_civ2+1,i1_civ2+1))/2;
                Data.Civ2_Dt=Civ2_Dt;
            end
        end
        for ilist=1:length(list_param)
            Data.(Civ2_param{6+ilist})=Param.ActionInput.Civ2.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ2_param];
        if isfield( Data,'Civ2_Background')
            Data.Civ2_Background=backgroundname;% update with the relevant background used
        end

        disp('civ2 performed')
        time_civ2=toc(tstart_civ2);

    end




    %% Fix2
    if isfield (Param.ActionInput,'Fix2')
        ListFixParam=fieldnames(Param.ActionInput.Fix2);
        for ilist=1:length(ListFixParam)
            ParamName=ListFixParam{ilist};
            ListName=['Fix2_' ParamName];
            eval(['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];'])
            eval(['Data.' ListName '=Param.ActionInput.Fix2.' ParamName ';'])
        end

        %     Data.ListVarName=[Data.ListVarName {'Civ2_FF'}];
        %     Data.VarDimName=[Data.VarDimName {'nb_vec_2'}];
        %     nbvar=length(Data.ListVarName);
        %     Data.VarAttribute{nbvar}.Role='errorflag';
        %     Data.Civ2_FF=double(fix(Param.ActionInput.Fix2,Data.Civ2_F,Data.Civ2_C,Data.Civ2_U,Data.Civ2_V));
        %     Data.CivStage=Data.CivStage+1;

    end

    %% Patch2
    if isfield (Param.ActionInput,'Patch2')
        %     Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch2_Rho','Patch2_Threshold','Patch2_SubDomain'}];
        %     Data.Patch2_FieldSmooth=Param.ActionInput.Patch2.FieldSmooth;
        %     Data.Patch2_MaxDiff=Param.ActionInput.Patch2.MaxDiff;
        %     Data.Patch2_SubDomainSize=Param.ActionInput.Patch2.SubDomainSize;
        %     nbvar=length(Data.ListVarName);
        %     Data.ListVarName=[Data.ListVarName {'Civ2_U_smooth','Civ2_V_smooth','Civ2_SubRange','Civ2_NbCentres','Civ2_Coord_tps','Civ2_U_tps','Civ2_V_tps'}];
        %     Data.VarDimName=[Data.VarDimName {'nb_vec_2','nb_vec_2',{'nb_coord','nb_bounds','nb_subdomain_2'},{'nb_subdomain_2'},...
        %         {'nb_tps_2','nb_coord','nb_subdomain_2'},{'nb_tps_2','nb_subdomain_2'},{'nb_tps_2','nb_subdomain_2'}}];
        %
        %     Data.VarAttribute{nbvar+1}.Role='vector_x';
        %     Data.VarAttribute{nbvar+2}.Role='vector_y';
        %     Data.VarAttribute{nbvar+5}.Role='coord_tps';
        %     Data.VarAttribute{nbvar+6}.Role='vector_x';
        %     Data.VarAttribute{nbvar+7}.Role='vector_y';
        %     Data.Civ2_U_smooth=zeros(size(Data.Civ2_X));
        %     Data.Civ2_V_smooth=zeros(size(Data.Civ2_X));
        %     if isfield(Data,'Civ2_FF')
        %         ind_good=find(Data.Civ2_FF==0);
        %     else
        %         ind_good=1:numel(Data.Civ2_X);
        %     end
        %     [Data.Civ2_SubRange,Data.Civ2_NbCentres,Data.Civ2_Coord_tps,Data.Civ2_U_tps,Data.Civ2_V_tps,tild,Ures, Vres,tild,FFres]=...
        %         filter_tps([Data.Civ2_X(ind_good) Data.Civ2_Y(ind_good)],Data.Civ2_U(ind_good),Data.Civ2_V(ind_good),[],Data.Patch2_SubDomainSize,Data.Patch2_FieldSmooth,Data.Patch2_MaxDiff);
        %     Data.Civ2_U_smooth(ind_good)=Ures;
        %     Data.Civ2_V_smooth(ind_good)=Vres;
        %     Data.Civ2_FF(ind_good)=FFres;
        Data.CivStage=Data.CivStage+1;


        if ~isfield (Param.ActionInput,'Civ3')
            [Data.Xmid, Data.Ymid, Data.Uphys, Data.Vphys, Data.Zphys, ...
                Data.Yphys, Data.Xphys, Data.Error] = getPhysValues(Rangx, ...
                Rangy, Npx, Npy, Data.Civ2_X, Data.Civ2_Y, Data.Civ2_U_smooth, ...
                Data.Civ2_V_smooth, XmlData);

            if ~isempty(errormsg)
                disp_uvmat('ERROR',errormsg,checkrun)
                return
            end
        end

    end


    %% Civ3

    if Param.ActionInput.CheckCiv3 && isfield (Param.ActionInput,'Civ3')
        par_civ3=Param.ActionInput.Civ3;
        par_civ3.ImageA=par_civ1.ImageA;
        par_civ3.ImageB=par_civ1.ImageB;
        par_civ3.ImageWidth=size(par_civ3.ImageA,2);
        par_civ3.ImageHeight=size(par_civ3.ImageA,1);

        if isfield(par_civ3,'Grid')% grid points set as input file
            if ischar(par_civ3.Grid)%read the grid file if the input is a file name
                par_civ3.Grid=dlmread(par_civ3.Grid);
                par_civ3.Grid(1,:)=[];%the first line must be removed (heading in the grid file)
            end
        else% automatic grid
            minix=floor(par_civ3.Dx/2)-0.5;
            maxix=minix+par_civ3.Dx*floor((par_civ3.ImageWidth-1)/par_civ3.Dx);
            miniy=floor(par_civ3.Dy/2)-0.5;
            maxiy=minix+par_civ3.Dy*floor((par_civ3.ImageHeight-1)/par_civ3.Dy);
            [GridX,GridY]=meshgrid(minix:par_civ3.Dx:maxix,miniy:par_civ3.Dy:maxiy);
            par_civ3.Grid(:,1)=reshape(GridX,[],1);
            par_civ3.Grid(:,2)=reshape(GridY,[],1);
        end
        Shiftx=zeros(size(par_civ3.Grid,1),1);% shift expected from civ2 data
        Shifty=zeros(size(par_civ3.Grid,1),1);
        nbval=zeros(size(par_civ3.Grid,1),1);
        if par_civ3.CheckDeformation
            DUDX=zeros(size(par_civ3.Grid,1),1);
            DUDY=zeros(size(par_civ3.Grid,1),1);
            DVDX=zeros(size(par_civ3.Grid,1),1);
            DVDY=zeros(size(par_civ3.Grid,1),1);
        end
        NbSubDomain=size(Data.Civ2_SubRange,3);
        % get the guess from patch2
        for isub=1:NbSubDomain% for each sub-domain of Patch2
            nbvec_sub=Data.Civ2_NbCentres(isub);% nbre of Civ2 vectors in the subdomain
            ind_sel=find(par_civ3.Grid(:,1)>=Data.Civ2_SubRange(1,1,isub) & par_civ3.Grid(:,1)<=Data.Civ2_SubRange(1,2,isub) &...
                par_civ3.Grid(:,2)>=Data.Civ2_SubRange(2,1,isub) & par_civ3.Grid(:,2)<=Data.Civ2_SubRange(2,2,isub));
            epoints = par_civ3.Grid(ind_sel,:);% coordinates of interpolation sites
            ctrs=Data.Civ2_Coord_tps(1:nbvec_sub,:,isub) ;%(=initial points) ctrs
            nbval(ind_sel)=nbval(ind_sel)+1;% records the number of values for eacn interpolation point (in case of subdomain overlap)
            EM = tps_eval(epoints,ctrs);
            Shiftx(ind_sel)=Shiftx(ind_sel)+EM*Data.Civ2_U_tps(1:nbvec_sub+3,isub);
            Shifty(ind_sel)=Shifty(ind_sel)+EM*Data.Civ2_V_tps(1:nbvec_sub+3,isub);
            if par_civ3.CheckDeformation
                [EMDX,EMDY] = tps_eval_dxy(epoints,ctrs);%2D matrix of distances between extrapolation points epoints and spline centres (=site points) ctrs
                DUDX(ind_sel)=DUDX(ind_sel)+EMDX*Data.Civ2_U_tps(1:nbvec_sub+3,isub);
                DUDY(ind_sel)=DUDY(ind_sel)+EMDY*Data.Civ2_U_tps(1:nbvec_sub+3,isub);
                DVDX(ind_sel)=DVDX(ind_sel)+EMDX*Data.Civ2_V_tps(1:nbvec_sub+3,isub);
                DVDY(ind_sel)=DVDY(ind_sel)+EMDY*Data.Civ2_V_tps(1:nbvec_sub+3,isub);
            end
        end
        mask='';
        if par_civ3.CheckMask&&~isempty(par_civ3.Mask)&& ~strcmp(maskname,par_civ3.Mask)% mask exist, not already read in Civ2
            mask=imread(par_civ3.Mask);
        end
        par_civ3.SearchBoxShift=[Shiftx(nbval>=1)./nbval(nbval>=1) Shifty(nbval>=1)./nbval(nbval>=1)];
        par_civ3.Grid=[par_civ3.Grid(nbval>=1,1)-par_civ3.SearchBoxShift(:,1)/2 par_civ3.Grid(nbval>=1,2)-par_civ3.SearchBoxShift(:,2)/2];% grid taken at the extrapolated origin of the displacement vectors
        if par_civ3.CheckDeformation
            par_civ3.DUDX=DUDX(nbval>=1)./nbval(nbval>=1);
            par_civ3.DUDY=DUDY(nbval>=1)./nbval(nbval>=1);
            par_civ3.DVDX=DVDX(nbval>=1)./nbval(nbval>=1);
            par_civ3.DVDY=DVDY(nbval>=1)./nbval(nbval>=1);
        end
        % calculate velocity data (y and v in indices, reverse to y component)
        [xtable, ytable, utable, vtable, ctable, F] = civ (par_civ3);
        list_param=(fieldnames(Param.ActionInput.Civ3))';
        Civ3_param=regexprep(list_param,'^.+','Civ3_$0');% insert 'Civ3_' before  each string in list_param
        Civ3_param=[{'Civ3_ImageA','Civ3_ImageB','Civ3_Time','Civ3_Dt'} Civ3_param]; %insert the names of the two input images
        %indicate the values of all the global attributes in the output data
        %     Data.Civ3_ImageA=ImageName_A;
        %     Data.Civ3_ImageB=ImageName_B;
        %     Data.Civ3_Time=(time(i2+1,j2+1)+time(i1+1,j1+1))/2;
        %     Data.Civ3_Dt=0;
        for ilist=1:length(list_param)
            Data.(Civ3_param{4+ilist})=Param.ActionInput.Civ3.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ3_param];

        %     nbvar=numel(Data.ListVarName);
        %     Data.ListVarName=[Data.ListVarName {'Civ3_X','Civ3_Y','Civ3_U','Civ3_V','Civ3_F','Civ3_C','Xphys','Yphys','Zphys'}];%  cell array containing the names of the fields to record
        %     Data.VarDimName=[Data.VarDimName {'nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3'}];
        %     Data.VarAttribute{nbvar+1}.Role='coord_x';
        %     Data.VarAttribute{nbvar+2}.Role='coord_y';
        %     Data.VarAttribute{nbvar+3}.Role='vector_x';
        %     Data.VarAttribute{nbvar+4}.Role='vector_y';
        %     Data.VarAttribute{nbvar+5}.Role='warnflag';
        %     Data.Civ3_X=reshape(xtable,[],1);
        %     Data.Civ3_Y=reshape(size(par_civ3.ImageA,1)-ytable+1,[],1);
        %     Data.Civ3_U=reshape(utable,[],1);
        %     Data.Civ3_V=reshape(-vtable,[],1);
        %     Data.Civ3_C=reshape(ctable,[],1);
        %     Data.Civ3_F=reshape(F,[],1);
        Data.CivStage=Data.CivStage+1;
    end

    %% Fix3
    if isfield (Param.ActionInput,'Fix3')
        ListFixParam=fieldnames(Param.ActionInput.Fix3);
        for ilist=1:length(ListFixParam)
            ParamName=ListFixParam{ilist};
            ListName=['Fix3_' ParamName];
            eval(['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];'])
            eval(['Data.' ListName '=Param.ActionInput.Fix3.' ParamName ';'])
        end

        Data.ListVarName=[Data.ListVarName {'Civ3_FF'}];
        Data.VarDimName=[Data.VarDimName {'nb_vec_3'}];
        nbvar=length(Data.ListVarName);
        Data.VarAttribute{nbvar}.Role='errorflag';
        Data.Civ3_FF=double(fix(Param.ActionInput.Fix3,Data.Civ3_F,Data.Civ3_C,Data.Civ3_U,Data.Civ3_V));
        Data.CivStage=Data.CivStage+1;
    end

    %% Patch3
    if isfield (Param.ActionInput,'Patch3')
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch3_Rho','Patch3_Threshold','Patch3_SubDomain'}];
        Data.Patch3_FieldSmooth=Param.ActionInput.Patch3.FieldSmooth;
        Data.Patch3_MaxDiff=Param.ActionInput.Patch3.MaxDiff;
        Data.Patch3_SubDomainSize=Param.ActionInput.Patch3.SubDomainSize;
        %     nbvar=length(Data.ListVarName);
        %     Data.ListVarName=[Data.ListVarName {'Civ3_U_smooth','Civ3_V_smooth','Civ3_SubRange','Civ3_NbCentres','Civ3_Coord_tps','Civ3_U_tps','Civ3_V_tps','Xmid','Ymid','Uphys','Vphys','Error'}];
        %     Data.VarDimName=[Data.VarDimName {'nb_vec_3','nb_vec_3',{'nb_coord','nb_bounds','nb_subdomain_3'},{'nb_subdomain_3'},...
        %         {'nb_tps_3','nb_coord','nb_subdomain_3'},{'nb_tps_3','nb_subdomain_3'},{'nb_tps_3','nb_subdomain_3'},'nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3'}];
        %
        %     Data.VarAttribute{nbvar+1}.Role='vector_x';
        %     Data.VarAttribute{nbvar+2}.Role='vector_y';
        %     Data.VarAttribute{nbvar+5}.Role='coord_tps';
        %     Data.VarAttribute{nbvar+6}.Role='vector_x';
        %     Data.VarAttribute{nbvar+7}.Role='vector_y';
        %     Data.Civ3_U_smooth=zeros(size(Data.Civ3_X));
        %     Data.Civ3_V_smooth=zeros(size(Data.Civ3_X));
        if isfield(Data,'Civ3_FF')
            ind_good=find(Data.Civ3_FF==0);
        else
            ind_good=1:numel(Data.Civ3_X);
        end
        [Data.Civ3_SubRange,Data.Civ3_NbCentres,Data.Civ3_Coord_tps,Data.Civ3_U_tps,Data.Civ3_V_tps,tild,Ures, Vres,tild,FFres]=...
            filter_tps([Data.Civ3_X(ind_good) Data.Civ3_Y(ind_good)],Data.Civ3_U(ind_good),Data.Civ3_V(ind_good),[],Data.Patch3_SubDomainSize,Data.Patch3_FieldSmooth,Data.Patch3_MaxDiff);
        Data.Civ3_U_smooth(ind_good)=Ures;
        Data.Civ3_V_smooth(ind_good)=Vres;
        Data.Civ3_FF(ind_good)=FFres;
        Data.CivStage=Data.CivStage+1;


        [Data.Xmid, Data.Ymid, Data.Uphys, Data.Vphys, Data.Zphys, ...
            Data.Yphys, Data.Xphys, Data.Error] = getPhysValues(Rangx, ...
            Rangy, Npx, Npy, Data.Civ3_X, Data.Civ3_Y, Data.Civ3_U_smooth, ...
            Data.Civ3_V_smooth, XmlData);

    end


    %%%%%%%%% modif fonction test %%%%%%%%%%%%%%%%%

    [Data.Xmid, Data.Ymid, Data.Uphys, Data.Vphys, Data.Zphys, ...
        Data.Yphys, Data.Xphys, Data.Error] = getPhysValues(Rangx, ...
        Rangy, Npx, Npy, Data.Civ1_X, Data.Civ1_Y, Data.Civ1_U_smooth, ...
        Data.Civ1_V_smooth, XmlData);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~isempty(errormsg)
        disp_uvmat('ERROR',errormsg,checkrun)
        return
    end


    %% write result in a netcdf file

    Data.X=uint16(Civ_X);
    Data.Y=uint16(Civ_Y);
    Data.U=int16(inv_scale_factor*Civ_U);
    Data.V=int16(inv_scale_factor*Civ_V);
    Data.C=uint8(100*Civ_C);
    Data.FF=uint8(Civ_FF);
    % add smoothed field if ptch is done
    %     if (Param.ActionInput.CheckPatch1 && ~Param.ActionInput.CheckCiv2) ||Param.ActionInput.CheckPatch2
    %         nbvar=6;
    %         Data.ListVarName=[Data.ListVarName {'U_smooth','V_smooth'}];
    %         Data.VarDimName=[Data.VarDimName {'nb_vec','nb_vec'}];
    %         Data.VarAttribute{nbvar+1}.Role='vector_x';
    %         Data.VarAttribute{nbvar+1}.scale_factor=1/inv_scale_factor;
    %         Data.VarAttribute{nbvar+2}.Role='vector_y';
    %         Data.VarAttribute{nbvar+2}.scale_factor=1/inv_scale_factor;
    %         Data.U_smooth=int16(inv_scale_factor*Civ_U_smooth);
    %         Data.V_smooth=int16(inv_scale_factor*Civ_V_smooth);
    %     end

    if LSM ~= 1 % store all data
        if exist('ncfile','var')
            errormsg=struct2nc(ncfile,Data);
            if isempty(errormsg)
                disp([ncfile ' written'])
            else
                disp(errormsg)
            end
        end
    else


        % store only phys data
        Data_light.ListVarName={'Xphys','Yphys','Zphys','Civ_C','DX','DY','Error'};
        Data_light.VarDimName={'nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3'};
        Data_light.VarAttribute{1}.Role='coord_x';
        Data_light.VarAttribute{2}.Role='coord_y';
        Data_light.VarAttribute{3}.Role='scalar';
        Data_light.VarAttribute{5}.Role='vector_x';
        Data_light.VarAttribute{6}.Role='vector_y';

        % vrifie la dernire passe effectue
        if isfield (Param.ActionInput,'Civ3')
            try
                ind_good=find(Data.Civ3_FF==0);
                Data_light.Civ_C=Data.Civ3_C(ind_good);
            catch
                Data_light.Civ_C=Data.Civ3_C;
            end
        elseif isfield (Param.ActionInput,'Civ2')
            try
                ind_good=find(Data.Civ2_FF==0);
                Data_light.Civ_C=Data.Civ2_C(ind_good);
            catch
                Data_light.Civ_C=Data.Civ2_C;
            end
        elseif isfield (Param.ActionInput,'Civ1')
            try
                ind_good=find(Data.Civ1_FF==0);
                Data_light.Civ_C=Data.Civ1_C(ind_good);
            catch
                Data_light.Civ_C=Data.Civ1_C;
            end
        end

        %         Data_light.Zphys=Data.Zphys(ind_good);
        %         Data_light.Yphys=Data.Yphys(ind_good);
        %         Data_light.Xphys=Data.Xphys(ind_good);
        %         Data_light.DX=Data.Uphys(ind_good);
        %         Data_light.DY=Data.Vphys(ind_good);
        %         Data_light.Error=Data.Error(ind_good);


        errormsg=struct2nc(ncfile,Data_light);
        if isempty(errormsg)
            disp([ncfile ' written'])
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
            disp(['time other ' num2str((time_total-time_civ1-time_patch1-time_civ2-time_patch2),2) ' s'])
        end
    end
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
        if isempty(j_series)||isequal(MinIndex_j,MaxIndex_j)
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [z,Xphy,Yphy,Error]=shift2z(xmid, ymid, u, v,XmlData)
z=0;
error=0;


%% first image
Calib_A=XmlData{1}.GeometryCalib;
R=(Calib_A.R)';
x_a=xmid- u/2;
y_a=ymid- v/2; 
z_a=R(7)*x_a+R(8)*y_a+Calib_A.Tx_Ty_Tz(1,3);
Xa=(R(1)*x_a+R(2)*y_a+Calib_A.Tx_Ty_Tz(1,1))./z_a;
Ya=(R(4)*x_a+R(5)*y_a+Calib_A.Tx_Ty_Tz(1,2))./z_a;

A_1_1=R(1)-R(7)*Xa;
A_1_2=R(2)-R(8)*Xa;
A_1_3=R(3)-R(9)*Xa;
A_2_1=R(4)-R(7)*Ya;
A_2_2=R(5)-R(8)*Ya;
A_2_3=R(6)-R(9)*Ya;
Det=A_1_1.*A_2_2-A_1_2.*A_2_1;
Dxa=(A_1_2.*A_2_3-A_2_2.*A_1_3)./Det;
Dya=(A_2_1.*A_1_3-A_1_1.*A_2_3)./Det;

%% second image
%loading shift angle

Calib_B=XmlData{2}.GeometryCalib;
R=(Calib_B.R)';

x_b=xmid+ u/2;
y_b=ymid+ v/2;
z_b=R(7)*x_b+R(8)*y_b+Calib_B.Tx_Ty_Tz(1,3);
Xb=(R(1)*x_b+R(2)*y_b+Calib_B.Tx_Ty_Tz(1,1))./z_b;
Yb=(R(4)*x_b+R(5)*y_b+Calib_B.Tx_Ty_Tz(1,2))./z_b;
B_1_1=R(1)-R(7)*Xb;
B_1_2=R(2)-R(8)*Xb;
B_1_3=R(3)-R(9)*Xb;
B_2_1=R(4)-R(7)*Yb;
B_2_2=R(5)-R(8)*Yb;
B_2_3=R(6)-R(9)*Yb;
Det=B_1_1.*B_2_2-B_1_2.*B_2_1;
Dxb=(B_1_2.*B_2_3-B_2_2.*B_1_3)./Det;
Dyb=(B_2_1.*B_1_3-B_1_1.*B_2_3)./Det;

%% result
Den=(Dxb-Dxa).*(Dxb-Dxa)+(Dyb-Dya).*(Dyb-Dya);
mfx=(XmlData{1}.GeometryCalib.fx_fy(1)+XmlData{2}.GeometryCalib.fx_fy(1))/2;
mfy=(XmlData{1}.GeometryCalib.fx_fy(2)+XmlData{2}.GeometryCalib.fx_fy(2))/2;
mtz=(XmlData{1}.GeometryCalib.Tx_Ty_Tz(1,3)+XmlData{2}.GeometryCalib.Tx_Ty_Tz(1,3))/2;

%Error=(sqrt(mfx^2+mfy^2)/(2*sqrt(2)*mtz)).*(((Dyb-Dya).*(-u)-(Dxb-Dxa).*(-v))./sqrt(Den));
Error=(((Dyb-Dya).*(-u)-(Dxb-Dxa).*(-v))./sqrt(Den));
z=((Dxb-Dxa).*(-u)+(Dyb-Dya).*(-v))./Den;

xnew(1,:)=Dxa.*z+x_a;
xnew(2,:)=Dxb.*z+x_b;
ynew(1,:)=Dya.*z+y_a;
ynew(2,:)=Dyb.*z+y_b;
Xphy=mean(xnew,1);
Yphy=mean(ynew,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Xmid, Ymid, Uphys, Vphys, Zphys, Yphys, Xphys, Error] ...
    = getPhysValues(Rangx, Rangy, Npx, Npy, Data_Civ_X, Data_Civ_Y, ...
    Data_Civ_U_smooth, Data_Civ_V_smooth, XmlData)
    
    % get z from u and v (displacements)     
    Xmid=Rangx(1)+(Rangx(2)-Rangx(1))*(Data_Civ_X-0.5)/(Npx-1);%temporary coordinate (velocity taken at the point middle from imgae 1 and 2)
    Ymid=Rangy(2)+(Rangy(1)-Rangy(2))*(Data_Civ_Y-0.5)/(Npy-1);%temporary coordinate (velocity taken at the point middle from imgae 1 and 2)
    Uphys=Data_Civ_U_smooth*(Rangx(2)-Rangx(1))/(Npx-1);
    Vphys=Data_Civ_V_smooth*(Rangy(1)-Rangy(2))/(Npy-1);
    [Zphys,Xphys,Yphys,Error]=shift2z(Xmid,Ymid,Uphys,Vphys,XmlData); %Data.Xphys and Data.Xphys are real coordinate (geometric correction more accurate than xtemp/ytempy

