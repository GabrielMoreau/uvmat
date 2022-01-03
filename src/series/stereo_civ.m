%'civ_series': PIV function activated by the general GUI series
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
% Copyright 2008-2022, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [Data,errormsg,result_conv]= stereo_civ(Param)
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
    Data=stereo_input(Param);% introduce the civ parameters using the GUI civ_input
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
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% input files and indexing
MaxIndex_i=Param.IndexRange.MaxIndex_i;
MinIndex_i=Param.IndexRange.MinIndex_i;
if ~isfield(Param,'InputTable')
    disp_uvmat('ERROR', 'no input field',checkrun)
    return
end
[tild,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
time=[];
for iview=1:size(Param.InputTable,1)
    XmlFileName=find_imadoc(Param.InputTable{iview,1},Param.InputTable{iview,2},Param.InputTable{iview,3},Param.InputTable{iview,5});
    if isempty(XmlFileName)
        disp_uvmat('ERROR', [XmlFileName ' not found'],checkrun)
        return
    end
    XmlData{iview}=imadoc2struct(XmlFileName);
    if isfield(XmlData{iview},'Time')
        time=XmlData{iview}.Time;
        TimeSource='xml';
    end
    if isfield(XmlData{iview},'Camera')
        if isfield(XmlData{iview}.Camera,'NbSlice')&& ~isempty(XmlData{iview}.Camera.NbSlice)
            NbSlice_calib{iview}=XmlData{iview}.Camera.NbSlice;% Nbre of slices for Zindex in phys transform
            if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
                msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
            end
        end
        if isfield(XmlData{iview}.Camera,'TimeUnit')&& ~isempty(XmlData{iview}.Camera.TimeUnit)
            TimeUnit=XmlData{iview}.Camera.TimeUnit;
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
i2_series_Civ1=i1_series{2};i2_series_Civ2=i1_series{2};
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
j1_series_Civ2=j1_series_Civ1;
j2_series_Civ2=j2_series_Civ1;

% if isempty(j1_series_Civ1)
%     FrameIndex_A_Civ1=i1_series_Civ1;
%     FrameIndex_B_Civ1=i2_series_Civ1;
%     j1_series_Civ1=ones(size(i1_series_Civ1));
%     j2_series_Civ1=ones(size(i1_series_Civ1));
% else
%     FrameIndex_A_Civ1=j1_series_Civ1;
%     FrameIndex_B_Civ1=j2_series_Civ1;
% end
if isempty(PairCiv2)
    FrameIndex_A_Civ2=FrameIndex_A_Civ1;
    FrameIndex_B_Civ2=FrameIndex_B_Civ1;
else
    if isempty(j1_series_Civ2)
        FrameIndex_A_Civ2=i1_series_Civ2;
        FrameIndex_B_Civ2=i2_series_Civ2;
        j1_series_Civ2=ones(size(i1_series_Civ2));
        j2_series_Civ2=ones(size(i1_series_Civ2));
    else
        FrameIndex_A_Civ2=j1_series_Civ2;
        FrameIndex_B_Civ2=j2_series_Civ2;
    end
end
if isempty(i1_series_Civ1)||(~isempty(PairCiv2) && isempty(i1_series_Civ2))
    disp_uvmat('ERROR','no image pair for civ in the input file index range',checkrun)
    return
end

%% check the first image pair
try
    if Param.ActionInput.CheckCiv1% Civ1 is performed
        ImageName_A=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1_series_Civ1(1),[],j1_series_Civ1(1));
        if ~exist(ImageName_A,'file')
            disp_uvmat('ERROR',['first input image ' ImageName_A ' does not exist'],checkrun)
            return
        end
        [FileInfo_A,VideoObject_A]=get_file_info(ImageName_A);
        FileType_A=FileInfo_A.FileType;
        if strcmp(FileInfo_A.FileType,'netcdf')
            FieldName_A=Param.InputFields.FieldName;
            [DataIn,tild,tild,errormsg]=nc2struct(ImageName_A,{FieldName_A});
            par_civ1.ImageA=DataIn.(FieldName_A);
        else
            [par_civ1.ImageA,VideoObject_A] = read_image(ImageName_A,FileType_A,VideoObject_A,FrameIndex_A_Civ1(1));
        end
        ImageName_B=fullfile_uvmat(RootPath_B,SubDir_B,RootFile_B,FileExt_B,NomType_B,i2_series_Civ1(1),[],j2_series_Civ1(1));
        if ~exist(ImageName_B,'file')
            disp_uvmat('ERROR',['first input image ' ImageName_B ' does not exist'],checkrun)
            return
        end
        [FileInfo_B,VideoObject_B]=get_file_info(ImageName_B);
        FileType_B=FileInfo_B.FileType;
        if strcmp(FileInfo_B.FileType,'netcdf')
            FieldName_B=Param.InputFields.FieldName;
            [DataIn,tild,tild,errormsg]=nc2struct(ImageName_B,{FieldName_B});
            par_civ1.ImageB=DataIn.(FieldName_B);
        else
            [par_civ1.ImageB,VideoObject_B] = read_image(ImageName_B,FileType_B,VideoObject_B,FrameIndex_B_Civ1(1));
        end
        NbField=numel(i1_series_Civ1);
    elseif Param.ActionInput.CheckCiv2 % Civ2 is performed without Civ1
        ImageName_A=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1_series_Civ2(1),[],j1_series_Civ2(1));
        if ~exist(ImageName_A,'file')
            disp_uvmat('ERROR',['first input image ' ImageName_A ' does not exist'],checkrun)
            return
        end
        [FileInfo_A,VideoObject_A]=get_file_info(ImageName_A);
        FileType_A=FileInfo_A.FileType;
        [par_civ1.ImageA,VideoObject_A] = read_image(ImageName_A,FileInfo_A.FileType,VideoObject_A,FrameIndex_A_Civ2(1));
        ImageName_B=fullfile_uvmat(RootPath_B,SubDir_B,RootFile_B,FileExt_B,NomType_B,i2_series_Civ2(1),[],j2_series_Civ2(1));
        if ~exist(ImageName_B,'file')
            disp_uvmat('ERROR',['first input image ' ImageName_B ' does not exist'],checkrun)
            return
        end
        [FileInfo_B,VideoObject_B]=get_file_info(ImageName_B);
        FileType_B=FileInfo_B.FileType;
        [par_civ1.ImageB,VideoObject_B] = read_image(ImageName_B,FileType_B,VideoObject_B,FrameIndex_B_Civ2(1));
        NbField=numel(i1_series_Civ2);
    else
        NbField=numel(i1_series_Civ1);% no image used (only fix or patch) TO CHECK
    end
catch ME
    if ~isempty(ME.message)
        disp_uvmat('ERROR', ['error reading input image: ' ME.message],checkrun)
        return
    end
end
if ismember(FileType_A,{'mmreader','video','cine_phantom'})
    NomTypeNc='_1';
else
    NomTypeNc=NomType_A;
end

%% Output directory
OutputDir=[Param.OutputSubDir Param.OutputDirExt];

ListGlobalAttribute={'Conventions','Program','CivStage'};
Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
Data.Program=mfilename;%gives the name of the current function;
Data.CivStage=0;%default
maskname='';%default
check_civx=0;%default

%% get timing from input video
if isempty(time) && ismember(FileType_A,{'mmreader','video','cine_phantom'})% case of video input
    time=zeros(FileInfo_A.NumberOfFrames+1,2);
    time(:,2)=(0:1/FileInfo_A.FrameRate:(FileInfo_A.NumberOfFrames)/FileInfo_A.FrameRate)';
    TimeSource='video';
    ColorType='truecolor';
end
if isempty(time)% time = index i  by default
    MaxIndex_i=max(i2_series_Civ1);
    MaxIndex_j=max(j2_series_Civ1);
    time=(1:MaxIndex_i)'*ones(1,MaxIndex_j);
    time=[zeros(1,MaxIndex_j);time];% insert a first line of zeros
    time=[zeros(MaxIndex_i+1,1) time];% insert a first column of zeros
end

if length(FileInfo_A) >1 %case of image with multiple frames
    nbfield=length(FileInfo_A);
    nbfield_j=1;
end

tic
%%%%% MAIN LOOP %%%%%%
CheckOverwrite=1;%default
if isfield(Param,'CheckOverwrite')
    CheckOverwrite=Param.CheckOverwrite;
end

for ifield=1:NbField
    update_waitbar(WaitbarHandle,ifield/NbField)
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break
    end
    % variable for light saving or not.
       LSM=Param.ActionInput.CheckLSM;
       
    Civ1Dir=OutputDir;

%         ncfile=fullfile_uvmat(RootPath_A,Civ1Dir,[RootFile_A,'_All'],'.nc',NomTypeNc,i2_series_Civ1(ifield),[],...
%             j1_series_Civ1(ifield),j2_series_Civ1(ifield));
        
        
        ncfile2=fullfile_uvmat(RootPath_A,Civ1Dir,RootFile_A,'.nc',NomTypeNc,i2_series_Civ1(ifield),[],...
            j1_series_Civ1(ifield),j2_series_Civ1(ifield));
        
     if (~CheckOverwrite && exist(ncfile,'file')) || (~CheckOverwrite && exist(ncfile2,'file')) 
            disp('existing output file already exists, skip to next field')
            result_conv=0;
            continue% skip iteration if the mode overwrite is desactivated and the result file already exists
     end   
    
       
    %% Civ1

    
    % if Civ1 computation is requested
    if isfield (Param.ActionInput,'Civ1')
        par_civ1=Param.ActionInput.Civ1;
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
        

        
        [A,Rangx,Rangy]=phys_ima(A,XmlData,1);
        [Npy,Npx]=size(A{1});
        PhysImageA=fullfile_uvmat(RootPath_A,Civ1Dir,RootFile_A,'.png','_1a',i1_series_Civ1(ifield),[],1);
        PhysImageB=fullfile_uvmat(RootPath_A,Civ1Dir,RootFile_A,'.png','_1a',i1_series_Civ1(ifield),[],2);
        if LSM ~= 1
        imwrite(A{1},PhysImageA)
        imwrite(A{2},PhysImageB)
        end
        
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
        Data.Civ1_Time=(time(i2+1,j2+1)+time(i1+1,j1+1))/2;
        Data.Civ1_Dt=time(i2+1,j2+1)-time(i1+1,j1+1);
        for ilist=1:length(list_param)
            Data.(Civ1_param{4+ilist})=Param.ActionInput.Civ1.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[ListGlobalAttribute Civ1_param];
        Data.CivStage=1;
        
        % set the list of variables
        Data.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_F','Civ1_C'};%  cell array containing the names of the fields to record
        Data.VarDimName={'nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1'};
        Data.VarAttribute{1}.Role='coord_x';
        Data.VarAttribute{2}.Role='coord_y';
        Data.VarAttribute{3}.Role='vector_x';
        Data.VarAttribute{4}.Role='vector_y';
        Data.VarAttribute{5}.Role='warnflag';
        
        
        % calculate velocity data (y and v in indices, reverse to y component)
        [xtable, ytable, utable, vtable, ctable, F, result_conv, errormsg] = civ (par_civ1);
        Data.Civ1_X=reshape(xtable,[],1);
        Data.Civ1_Y=reshape(par_civ1.ImageHeight-ytable+1,[],1);
        % get z from u and v (displacements)
        Data.Civ1_U=reshape(utable,[],1);
        Data.Civ1_V=reshape(-vtable,[],1);      
        Data.Civ1_C=reshape(ctable,[],1);
        Data.Civ1_F=reshape(F,[],1);

    end
    
    %% Fix1
    if isfield (Param.ActionInput,'Fix1')
        if ~isfield (Param.ActionInput,'Civ1')% if we use existing Civ1, remove previous data beyond Civ1
            Fix1_attr=find(strcmp('Fix1',Data.ListGlobalAttribute));
            Data.ListGlobalAttribute(Fix1_attr)=[];
            for ilist=1:numel(Fix1_attr)
                Data=rmfield(Data,Data.ListGlobalAttribute{Fix1_attr(ilist)});
            end
        end
        ListFixParam=fieldnames(Param.ActionInput.Fix1);
        for ilist=1:length(ListFixParam)
            ParamName=ListFixParam{ilist};
            ListName=['Fix1_' ParamName];
            eval(['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];'])
            eval(['Data.' ListName '=Param.ActionInput.Fix1.' ParamName ';'])
        end
        if check_civx
            if ~isfield(Data,'fix')
                Data.ListGlobalAttribute=[Data.ListGlobalAttribute 'fix'];
                Data.fix=1;
                Data.ListVarName=[Data.ListVarName {'vec_FixFlag'}];
                Data.VarDimName=[Data.VarDimName {'nb_vectors'}];
            end
            Data.vec_FixFlag=fix(Param.ActionInput.Fix1,Data.vec_F,Data.vec_C,Data.vec_U,Data.vec_V,Data.vec_X,Data.vec_Y);
        else
            Data.ListVarName=[Data.ListVarName {'Civ1_FF'}];
            Data.VarDimName=[Data.VarDimName {'nb_vec_1'}];
            nbvar=length(Data.ListVarName);
            Data.VarAttribute{nbvar}.Role='errorflag';
            Data.Civ1_FF=fix(Param.ActionInput.Fix1,Data.Civ1_F,Data.Civ1_C,Data.Civ1_U,Data.Civ1_V);
            Data.CivStage=2;
        end
    end
    %% Patch1
    if isfield (Param.ActionInput,'Patch1')
        if check_civx
            errormsg='Civ Matlab input needed for patch';
            disp_uvmat('ERROR',errormsg,checkrun)
            return
        end
        
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch1_Rho','Patch1_Threshold','Patch1_SubDomain'}];
        Data.Patch1_FieldSmooth=Param.ActionInput.Patch1.FieldSmooth;
        Data.Patch1_MaxDiff=Param.ActionInput.Patch1.MaxDiff;
        Data.Patch1_SubDomainSize=Param.ActionInput.Patch1.SubDomainSize;
        nbvar=length(Data.ListVarName);
        Data.ListVarName=[Data.ListVarName {'Civ1_U_smooth','Civ1_V_smooth','Civ1_SubRange','Civ1_NbCentres','Civ1_Coord_tps','Civ1_U_tps','Civ1_V_tps'}];
        Data.VarDimName=[Data.VarDimName {'nb_vec_1','nb_vec_1',{'nb_coord','nb_bounds','nb_subdomain_1'},'nb_subdomain_1',...
            {'nb_tps_1','nb_coord','nb_subdomain_1'},{'nb_tps_1','nb_subdomain_1'},{'nb_tps_1','nb_subdomain_1'}}];
        Data.VarAttribute{nbvar+1}.Role='vector_x';
        Data.VarAttribute{nbvar+2}.Role='vector_y';
        Data.VarAttribute{nbvar+5}.Role='coord_tps';
        Data.VarAttribute{nbvar+6}.Role='vector_x';
        Data.VarAttribute{nbvar+7}.Role='vector_y';
        Data.Civ1_U_smooth=zeros(size(Data.Civ1_X));
        Data.Civ1_V_smooth=zeros(size(Data.Civ1_X));
        if isfield(Data,'Civ1_FF')
            ind_good=find(Data.Civ1_FF==0);
        else
            ind_good=1:numel(Data.Civ1_X);
        end
        [Data.Civ1_SubRange,Data.Civ1_NbCentres,Data.Civ1_Coord_tps,Data.Civ1_U_tps,Data.Civ1_V_tps,tild,Ures, Vres,tild,FFres]=...
            filter_tps([Data.Civ1_X(ind_good) Data.Civ1_Y(ind_good)],Data.Civ1_U(ind_good),Data.Civ1_V(ind_good),[],Data.Patch1_SubDomainSize,Data.Patch1_FieldSmooth,Data.Patch1_MaxDiff);
        Data.Civ1_U_smooth(ind_good)=Ures;
        Data.Civ1_V_smooth(ind_good)=Vres;
        Data.Civ1_FF(ind_good)=FFres;
        Data.CivStage=3;
               
    end
    
    %% Civ2
    if isfield (Param.ActionInput,'Civ2')
        par_civ2=Param.ActionInput.Civ2;
        par_civ2.ImageA=par_civ1.ImageA;
        par_civ2.ImageB=par_civ1.ImageB;
        %         if ~isfield(Param.Civ1,'ImageA')
        i1=i1_series_Civ2(ifield);
        i2=i1;
        if ~isempty(i2_series_Civ2)
            i2=i2_series_Civ2(ifield);
        end
        j1=1;
        if ~isempty(j1_series_Civ2)
            j1=j1_series_Civ2(ifield);
        end
        j2=j1;
        if ~isempty(j2_series_Civ2)
            j2=j2_series_Civ2(ifield);
        end
        par_civ2.ImageWidth=size(par_civ2.ImageA,2);
        par_civ2.ImageHeight=size(par_civ2.ImageA,1);
        
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
        Shiftx=zeros(size(par_civ2.Grid,1),1);% shift expected from civ1 data
        Shifty=zeros(size(par_civ2.Grid,1),1);
        nbval=zeros(size(par_civ2.Grid,1),1);
        if par_civ2.CheckDeformation
            DUDX=zeros(size(par_civ2.Grid,1),1);
            DUDY=zeros(size(par_civ2.Grid,1),1);
            DVDX=zeros(size(par_civ2.Grid,1),1);
            DVDY=zeros(size(par_civ2.Grid,1),1);
        end
        NbSubDomain=size(Data.Civ1_SubRange,3);
        % get the guess from patch1
        for isub=1:NbSubDomain% for each sub-domain of Patch1
            nbvec_sub=Data.Civ1_NbCentres(isub);% nbre of Civ1 vectors in the subdomain
            ind_sel=find(par_civ2.Grid(:,1)>=Data.Civ1_SubRange(1,1,isub) & par_civ2.Grid(:,1)<=Data.Civ1_SubRange(1,2,isub) &...
                par_civ2.Grid(:,2)>=Data.Civ1_SubRange(2,1,isub) & par_civ2.Grid(:,2)<=Data.Civ1_SubRange(2,2,isub));
            epoints = par_civ2.Grid(ind_sel,:);% coordinates of interpolation sites
            ctrs=Data.Civ1_Coord_tps(1:nbvec_sub,:,isub) ;%(=initial points) ctrs
            nbval(ind_sel)=nbval(ind_sel)+1;% records the number of values for eacn interpolation point (in case of subdomain overlap)
            EM = tps_eval(epoints,ctrs);
            Shiftx(ind_sel)=Shiftx(ind_sel)+EM*Data.Civ1_U_tps(1:nbvec_sub+3,isub);
            Shifty(ind_sel)=Shifty(ind_sel)+EM*Data.Civ1_V_tps(1:nbvec_sub+3,isub);
            if par_civ2.CheckDeformation
                [EMDX,EMDY] = tps_eval_dxy(epoints,ctrs);%2D matrix of distances between extrapolation points epoints and spline centres (=site points) ctrs
                DUDX(ind_sel)=DUDX(ind_sel)+EMDX*Data.Civ1_U_tps(1:nbvec_sub+3,isub);
                DUDY(ind_sel)=DUDY(ind_sel)+EMDY*Data.Civ1_U_tps(1:nbvec_sub+3,isub);
                DVDX(ind_sel)=DVDX(ind_sel)+EMDX*Data.Civ1_V_tps(1:nbvec_sub+3,isub);
                DVDY(ind_sel)=DVDY(ind_sel)+EMDY*Data.Civ1_V_tps(1:nbvec_sub+3,isub);
            end
        end
        mask='';
        if par_civ2.CheckMask&&~isempty(par_civ2.Mask)&& ~strcmp(maskname,par_civ2.Mask)% mask exist, not already read in civ1
            mask=imread(par_civ2.Mask);
        end
%         ibx2=ceil(par_civ2.CorrBoxSize(1)/2);
%         iby2=ceil(par_civ2.CorrBoxSize(2)/2);
        par_civ2.SearchBoxShift=[Shiftx(nbval>=1)./nbval(nbval>=1) Shifty(nbval>=1)./nbval(nbval>=1)];
        par_civ2.Grid=[par_civ2.Grid(nbval>=1,1)-par_civ2.SearchBoxShift(:,1)/2 par_civ2.Grid(nbval>=1,2)-par_civ2.SearchBoxShift(:,2)/2];% grid taken at the extrapolated origin of the displacement vectors
        if par_civ2.CheckDeformation
            par_civ2.DUDX=DUDX(nbval>=1)./nbval(nbval>=1);
            par_civ2.DUDY=DUDY(nbval>=1)./nbval(nbval>=1);
            par_civ2.DVDX=DVDX(nbval>=1)./nbval(nbval>=1);
            par_civ2.DVDY=DVDY(nbval>=1)./nbval(nbval>=1);
        end
        % calculate velocity data (y and v in indices, reverse to y component)
        [xtable, ytable, utable, vtable, ctable, F] = civ (par_civ2);
        list_param=(fieldnames(Param.ActionInput.Civ2))';
        Civ2_param=regexprep(list_param,'^.+','Civ2_$0');% insert 'Civ2_' before  each string in list_param
        Civ2_param=[{'Civ2_ImageA','Civ2_ImageB','Civ2_Time','Civ2_Dt'} Civ2_param]; %insert the names of the two input images
        %indicate the values of all the global attributes in the output data
        Data.Civ2_ImageA=ImageName_A;
        Data.Civ2_ImageB=ImageName_B;
        Data.Civ2_Time=(time(i2+1,j2+1)+time(i1+1,j1+1))/2;
        Data.Civ2_Dt=0;
        for ilist=1:length(list_param)
            Data.(Civ2_param{4+ilist})=Param.ActionInput.Civ2.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ2_param];
        
        nbvar=numel(Data.ListVarName);
        Data.ListVarName=[Data.ListVarName {'Civ2_X','Civ2_Y','Civ2_U','Civ2_V','Civ2_F','Civ2_C'}];%  cell array containing the names of the fields to record
        Data.VarDimName=[Data.VarDimName {'nb_vec_2','nb_vec_2','nb_vec_2','nb_vec_2','nb_vec_2','nb_vec_2'}];
        Data.VarAttribute{nbvar+1}.Role='coord_x';
        Data.VarAttribute{nbvar+2}.Role='coord_y';
        Data.VarAttribute{nbvar+3}.Role='vector_x';
        Data.VarAttribute{nbvar+4}.Role='vector_y';
        Data.VarAttribute{nbvar+5}.Role='warnflag';
        Data.Civ2_X=reshape(xtable,[],1);
        Data.Civ2_Y=reshape(size(par_civ2.ImageA,1)-ytable+1,[],1);
        Data.Civ2_U=reshape(utable,[],1);
        Data.Civ2_V=reshape(-vtable,[],1);
        Data.Civ2_C=reshape(ctable,[],1);
        Data.Civ2_F=reshape(F,[],1);
        Data.CivStage=Data.CivStage+1;
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
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch2_Rho','Patch2_Threshold','Patch2_SubDomain'}];
        Data.Patch2_FieldSmooth=Param.ActionInput.Patch2.FieldSmooth;
        Data.Patch2_MaxDiff=Param.ActionInput.Patch2.MaxDiff;
        Data.Patch2_SubDomainSize=Param.ActionInput.Patch2.SubDomainSize;
        nbvar=length(Data.ListVarName);
        Data.ListVarName=[Data.ListVarName {'Civ2_U_smooth','Civ2_V_smooth','Civ2_SubRange','Civ2_NbCentres','Civ2_Coord_tps','Civ2_U_tps','Civ2_V_tps'}];
        Data.VarDimName=[Data.VarDimName {'nb_vec_2','nb_vec_2',{'nb_coord','nb_bounds','nb_subdomain_2'},{'nb_subdomain_2'},...
            {'nb_tps_2','nb_coord','nb_subdomain_2'},{'nb_tps_2','nb_subdomain_2'},{'nb_tps_2','nb_subdomain_2'}}];
        
        Data.VarAttribute{nbvar+1}.Role='vector_x';
        Data.VarAttribute{nbvar+2}.Role='vector_y';
        Data.VarAttribute{nbvar+5}.Role='coord_tps';
        Data.VarAttribute{nbvar+6}.Role='vector_x';
        Data.VarAttribute{nbvar+7}.Role='vector_y';
        Data.Civ2_U_smooth=zeros(size(Data.Civ2_X));
        Data.Civ2_V_smooth=zeros(size(Data.Civ2_X));
        if isfield(Data,'Civ2_FF')
            ind_good=find(Data.Civ2_FF==0);
        else
            ind_good=1:numel(Data.Civ2_X);
        end
        [Data.Civ2_SubRange,Data.Civ2_NbCentres,Data.Civ2_Coord_tps,Data.Civ2_U_tps,Data.Civ2_V_tps,tild,Ures, Vres,tild,FFres]=...
            filter_tps([Data.Civ2_X(ind_good) Data.Civ2_Y(ind_good)],Data.Civ2_U(ind_good),Data.Civ2_V(ind_good),[],Data.Patch2_SubDomainSize,Data.Patch2_FieldSmooth,Data.Patch2_MaxDiff);
        Data.Civ2_U_smooth(ind_good)=Ures;
        Data.Civ2_V_smooth(ind_good)=Vres;
        Data.Civ2_FF(ind_good)=FFres;
        Data.CivStage=Data.CivStage+1;
    end
    
        
    %% Civ3
    
    if isfield (Param.ActionInput,'Civ3')
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
%         ibx2=ceil(par_civ3.CorrBoxSize(1)/2);
%         iby2=ceil(par_civ3.CorrBoxSize(2)/2);
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
        Data.Civ3_ImageA=ImageName_A;
        Data.Civ3_ImageB=ImageName_B;
        Data.Civ3_Time=(time(i2+1,j2+1)+time(i1+1,j1+1))/2;
        Data.Civ3_Dt=0;
        for ilist=1:length(list_param)
            Data.(Civ3_param{4+ilist})=Param.ActionInput.Civ3.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ3_param];
        
        nbvar=numel(Data.ListVarName);
        Data.ListVarName=[Data.ListVarName {'Civ3_X','Civ3_Y','Civ3_U','Civ3_V','Civ3_F','Civ3_C','Xphys','Yphys','Zphys'}];%  cell array containing the names of the fields to record
        Data.VarDimName=[Data.VarDimName {'nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3'}];
        Data.VarAttribute{nbvar+1}.Role='coord_x';
        Data.VarAttribute{nbvar+2}.Role='coord_y';
        Data.VarAttribute{nbvar+3}.Role='vector_x';
        Data.VarAttribute{nbvar+4}.Role='vector_y';
        Data.VarAttribute{nbvar+5}.Role='warnflag';
        Data.Civ3_X=reshape(xtable,[],1);
        Data.Civ3_Y=reshape(size(par_civ3.ImageA,1)-ytable+1,[],1);
        Data.Civ3_U=reshape(utable,[],1);
        Data.Civ3_V=reshape(-vtable,[],1);
        Data.Civ3_C=reshape(ctable,[],1);
        Data.Civ3_F=reshape(F,[],1);
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
        if check_civx
            if ~isfield(Data,'fix3')
                Data.ListGlobalAttribute=[Data.ListGlobalAttribute 'fix3'];
                Data.fix3=1;
                Data.ListVarName=[Data.ListVarName {'vec3_FixFlag'}];
                Data.VarDimName=[Data.VarDimName {'nb_vectors3'}];
            end
            Data.vec_FixFlag=fix(Param.Fix3,Data.vec3_F,Data.vec3_C,Data.vec3_U,Data.vec3_V,Data.vec3_X,Data.vec3_Y);
        else
            Data.ListVarName=[Data.ListVarName {'Civ3_FF'}];
            Data.VarDimName=[Data.VarDimName {'nb_vec_3'}];
            nbvar=length(Data.ListVarName);
            Data.VarAttribute{nbvar}.Role='errorflag';
            Data.Civ3_FF=double(fix(Param.ActionInput.Fix3,Data.Civ3_F,Data.Civ3_C,Data.Civ3_U,Data.Civ3_V));
            Data.CivStage=Data.CivStage+1;
        end
        
    end

    
     %% Patch3
    if isfield (Param.ActionInput,'Patch3')
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch3_Rho','Patch3_Threshold','Patch3_SubDomain'}];
        Data.Patch3_FieldSmooth=Param.ActionInput.Patch3.FieldSmooth;
        Data.Patch3_MaxDiff=Param.ActionInput.Patch3.MaxDiff;
        Data.Patch3_SubDomainSize=Param.ActionInput.Patch3.SubDomainSize;
        nbvar=length(Data.ListVarName);
        Data.ListVarName=[Data.ListVarName {'Civ3_U_smooth','Civ3_V_smooth','Civ3_SubRange','Civ3_NbCentres','Civ3_Coord_tps','Civ3_U_tps','Civ3_V_tps','Xmid','Ymid','Uphys','Vphys','Error'}];
        Data.VarDimName=[Data.VarDimName {'nb_vec_3','nb_vec_3',{'nb_coord','nb_bounds','nb_subdomain_3'},{'nb_subdomain_3'},...
            {'nb_tps_3','nb_coord','nb_subdomain_3'},{'nb_tps_3','nb_subdomain_3'},{'nb_tps_3','nb_subdomain_3'},'nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3'}];
        
        Data.VarAttribute{nbvar+1}.Role='vector_x';
        Data.VarAttribute{nbvar+2}.Role='vector_y';
        Data.VarAttribute{nbvar+5}.Role='coord_tps';
        Data.VarAttribute{nbvar+6}.Role='vector_x';
        Data.VarAttribute{nbvar+7}.Role='vector_y';
        Data.Civ3_U_smooth=zeros(size(Data.Civ3_X));
        Data.Civ3_V_smooth=zeros(size(Data.Civ3_X));
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
        
            
         % get z from u and v (displacements)
       
        Data.Xmid=Rangx(1)+(Rangx(2)-Rangx(1))*(Data.Civ3_X-0.5)/(Npx-1);%temporary coordinate (velocity taken at the point middle from imgae 1 and 2)
        Data.Ymid=Rangy(2)+(Rangy(1)-Rangy(2))*(Data.Civ3_Y-0.5)/(Npy-1);%temporary coordinate (velocity taken at the point middle from imgae 1 and 2)
        Data.Uphys=Data.Civ3_U_smooth*(Rangx(2)-Rangx(1))/(Npx-1);
        Data.Vphys=Data.Civ3_V_smooth*(Rangy(1)-Rangy(2))/(Npy-1);
        [Data.Zphys,Data.Xphys,Data.Yphys,Data.Error]=shift2z(Data.Xmid,Data.Ymid,Data.Uphys,Data.Vphys,XmlData); %Data.Xphys and Data.Xphys are real coordinate (geometric correction more accurate than xtemp/ytemp)
        if ~isempty(errormsg)
            disp_uvmat('ERROR',errormsg,checkrun)
            return
        end
        
    end
      
    
    %% write result in a netcdf file if requested
%     if LSM ~= 1 % store all data
%         if exist('ncfile','var')
%             errormsg=struct2nc(ncfile,Data);
%             if isempty(errormsg)
%                 disp([ncfile ' written'])
%             else
%                 disp(errormsg)
%             end
%         end
%     else
       % store only phys data
       % Data_light.ListVarName={'Xphys','Yphys','Zphys','Civ3_C','Xmid','Ymid','Uphys','Vphys','Error'};
       % Data_light.VarDimName={'nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3'};
        Data_light.ListVarName={'Xphys','Yphys','Zphys','Civ3_C','DX','DY','Error'};
        Data_light.VarDimName={'nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3','nb_vec_3'};
        Data_light.VarAttribute{1}.Role='coord_x';
         Data_light.VarAttribute{2}.Role='coord_y';
         Data_light.VarAttribute{3}.Role='scalar';
         Data_light.VarAttribute{5}.Role='vector_x';
         Data_light.VarAttribute{6}.Role='vector_y';
        ind_good=find(Data.Civ3_FF==0);
        Data_light.Zphys=Data.Zphys(ind_good);
        Data_light.Yphys=Data.Yphys(ind_good);
        Data_light.Xphys=Data.Xphys(ind_good);
        Data_light.Civ3_C=Data.Civ3_C(ind_good);
%         Data_light.Xmid=Data.Xmid(ind_good);
%         Data_light.Ymid=Data.Ymid(ind_good);
        Data_light.DX=Data.Uphys(ind_good);
        Data_light.DY=Data.Vphys(ind_good);
        Data_light.Error=Data.Error(ind_good);
       if exist('ncfile2','var')
            errormsg=struct2nc(ncfile2,Data_light);
            if isempty(errormsg)
                disp([ncfile2 ' written'])
            else
                disp(errormsg)
            end
       end
       
%     end
end
disp(['ellapsed time for the loop ' num2str(toc) ' s'])
tic
while toc < rand(1)*10
    for i = 1:100000, sqrt(1237); end
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
%  .CorrBoxSize
%  .SearchBoxSize
%  .SearchBoxShift
%  .ImageHeight
%  .ImageWidth
%  .Dx, Dy
%  .Grid
%  .Mask
%  .MinIma
%  .MaxIma
%  .image1:first image (matrix)
% image2: second image (matrix)
% ibx2,iby2: half size of the correlation box along x and y, in px (size=(2*iby2+1,2*ibx2+1)
% isx2,isy2: half size of the search box along x and y, in px (size=(2*isy2+1,2*isx2+1)
% shiftx, shifty: shift of the search box (in pixel index, yshift reversed)
% step: mesh of the measurement points (in px)
% subpixfinder=1 or 2 controls the curve fitting of the image correlation
% mask: =[] for no mask
% roi: 4 element vector defining a region of interest: x position, y position, width, height, (in image indices), for the whole image, roi=[];
function [xtable ytable utable vtable ctable F result_conv errormsg] = civ (par_civ)
%this funtion performs the DCC PIV analysis. Recent window-deformation
%methods perform better and will maybe be implemented in the future.

%% prepare measurement grid
if isfield(par_civ,'Grid')% grid points set as input
    if ischar(par_civ.Grid)%read the drid file if the input is a file name
        par_civ.Grid=dlmread(par_civ.Grid);
        par_civ.Grid(1,:)=[];%the first line must be removed (heading in the grid file)
    end
else% automatic grid
    minix=floor(par_civ.Dx/2)-0.5;
    maxix=minix+par_civ.Dx*floor((par_civ.ImageWidth-1)/par_civ.Dx);
    miniy=floor(par_civ.Dy/2)-0.5;
    maxiy=minix+par_civ.Dy*floor((par_civ.ImageHeight-1)/par_civ.Dy);
    [GridX,GridY]=meshgrid(minix:par_civ.Dx:maxix,miniy:par_civ.Dy:maxiy);
    par_civ.Grid(:,1)=reshape(GridX,[],1);
    par_civ.Grid(:,2)=reshape(GridY,[],1);
end
nbvec=size(par_civ.Grid,1);

%% prepare correlation and search boxes
ibx2=floor(par_civ.CorrBoxSize(1)/2);
iby2=floor(par_civ.CorrBoxSize(2)/2);
isx2=floor(par_civ.SearchBoxSize(1)/2);
isy2=floor(par_civ.SearchBoxSize(2)/2);
shiftx=round(par_civ.SearchBoxShift(:,1));
shifty=-round(par_civ.SearchBoxShift(:,2));% sign minus because image j index increases when y decreases
if numel(shiftx)==1% case of a unique shift for the whole field( civ1)
    shiftx=shiftx*ones(nbvec,1);
    shifty=shifty*ones(nbvec,1);
end

%% Default output
xtable=par_civ.Grid(:,1);
ytable=par_civ.Grid(:,2);
utable=zeros(nbvec,1);
vtable=zeros(nbvec,1);
ctable=zeros(nbvec,1);
F=zeros(nbvec,1);
result_conv=[];
errormsg='';

%% prepare mask
if isfield(par_civ,'Mask') && ~isempty(par_civ.Mask)
    if strcmp(par_civ.Mask,'all')
        return    % get the grid only, no civ calculation
    elseif ischar(par_civ.Mask)
        par_civ.Mask=imread(par_civ.Mask);
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
    %  check_noflux=(par_civ.Mask<100) ;%TODO: to implement
    check_undefined=(par_civ.Mask<200 & par_civ.Mask>=20 );
    %     par_civ.ImageA(check_undefined)=MinA;% put image A to zero (i.e. the min image value) in the undefined  area
    %     par_civ.ImageB(check_undefined)=MinB;% put image B to zero (i.e. the min image value) in the undefined  area
end

%% compute image correlations: MAINLOOP on velocity vectors
corrmax=0;
sum_square=1;% default
mesh=1;% default
CheckDeformation=isfield(par_civ,'CheckDeformation')&& par_civ.CheckDeformation==1;
if CheckDeformation
    mesh=0.25;%mesh in pixels for subpixel image interpolation
end
% vector=[0 0];%default

for ivec=1:nbvec
    iref=round(par_civ.Grid(ivec,1)+0.5);% xindex on the image A for the middle of the correlation box
    jref=round(par_civ.ImageHeight-par_civ.Grid(ivec,2)+0.5);% yindex on the image B for the middle of the correlation box
    
    %if ~(checkmask && par_civ.Mask(jref,iref)<=20) %velocity not set to zero by the black mask
    %         if jref-iby2<1 || jref+iby2>par_civ.ImageHeight|| iref-ibx2<1 || iref+ibx2>par_civ.ImageWidth||...
    %               jref+shifty(ivec)-isy2<1||jref+shifty(ivec)+isy2>par_civ.ImageHeight|| iref+shiftx(ivec)-isx2<1 || iref+shiftx(ivec)+isx2>par_civ.ImageWidth  % we are outside the image
    %             F(ivec)=3;
    %         else
    F(ivec)=0;
    subrange1_x=iref-ibx2:iref+ibx2;% x indices defining the first subimage
    subrange1_y=jref-iby2:jref+iby2;% y indices defining the first subimage
    subrange2_x=iref+shiftx(ivec)-isx2:iref+shiftx(ivec)+isx2;%x indices defining the second subimage
    subrange2_y=jref+shifty(ivec)-isy2:jref+shifty(ivec)+isy2;%y indices defining the second subimage
    image1_crop=MinA*ones(numel(subrange1_y),numel(subrange1_x));% default value=min of image A
    image2_crop=MinA*ones(numel(subrange2_y),numel(subrange2_x));% default value=min of image A
    mask1_crop=ones(numel(subrange1_y),numel(subrange1_x));% default value=1 for mask
    mask2_crop=ones(numel(subrange2_y),numel(subrange2_x));% default value=1 for mask
    check1_x=subrange1_x>=1 & subrange1_x<=par_civ.ImageWidth;% check which points in the subimage 1 are contained in the initial image 1
    check1_y=subrange1_y>=1 & subrange1_y<=par_civ.ImageHeight;
    check2_x=subrange2_x>=1 & subrange2_x<=par_civ.ImageWidth;% check which points in the subimage 2 are contained in the initial image 2
    check2_y=subrange2_y>=1 & subrange2_y<=par_civ.ImageHeight;
    image1_crop(check1_y,check1_x)=par_civ.ImageA(subrange1_y(check1_y),subrange1_x(check1_x));%extract a subimage (correlation box) from image A
    image2_crop(check2_y,check2_x)=par_civ.ImageB(subrange2_y(check2_y),subrange2_x(check2_x));%extract a larger subimage (search box) from image B
    if checkmask
        mask1_crop(check1_y,check1_x)=check_undefined(subrange1_y(check1_y),subrange1_x(check1_x));%extract a mask subimage (correlation box) from image A
        mask2_crop(check2_y,check2_x)=check_undefined(subrange2_y(check2_y),subrange2_x(check2_x));%extract a mask subimage (search box) from imag
        sizemask=sum(sum(mask1_crop))/(numel(subrange1_y)*numel(subrange1_x));%size of the masked part relative to the correlation sub-image
        if sizemask > 1/2% eliminate point if more than half of the correlation box is masked
            F(ivec)=3; %
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
    if check_MinIma && (image1_mean < par_civ.MinIma || image2_mean < par_civ.MinIma)
        F(ivec)=3;
    end
    %threshold on image maximum
    if check_MaxIma && (image1_mean > par_civ.MaxIma || image2_mean > par_civ.MaxIma)
        F(ivec)=3;
    end
    if F(ivec)~=3
        image1_crop=(image1_crop-image1_mean);%substract the mean, put to zero the masked parts
        image2_crop=(image2_crop-image2_mean);
        if checkmask
            image1_crop=image1_crop.*~mask1_crop;% put to zero the masked parts
            image2_crop=image2_crop.*~mask2_crop;
        end
        if CheckDeformation
            xi=(1:mesh:size(image1_crop,2));
            yi=(1:mesh:size(image1_crop,1))';
            [XI,YI]=meshgrid(xi-ceil(size(image1_crop,2)/2),yi-ceil(size(image1_crop,1)/2));
            XIant=XI-par_civ.DUDX(ivec)*XI-par_civ.DUDY(ivec)*YI+ceil(size(image1_crop,2)/2);
            YIant=YI-par_civ.DVDX(ivec)*XI-par_civ.DVDY(ivec)*YI+ceil(size(image1_crop,1)/2);
            image1_crop=interp2(image1_crop,XIant,YIant);
            image1_crop(isnan(image1_crop))=0;
            xi=(1:mesh:size(image2_crop,2));
            yi=(1:mesh:size(image2_crop,1))';
            image2_crop=interp2(image2_crop,xi,yi,'*spline');
            image2_crop(isnan(image2_crop))=0;
        end
        sum_square=(sum(sum(image1_crop.*image1_crop)));%+sum(sum(image2_crop.*image2_crop)))/2;
        %reference: Oliver Pust, PIV: Direct Cross-Correlation
        result_conv= conv2(image2_crop,flipdim(flipdim(image1_crop,2),1),'valid');
        corrmax= max(max(result_conv));
        result_conv=(result_conv/corrmax)*255; %normalize, peak=always 255
        %Find the correlation max, at 255
        [y,x] = find(result_conv==255,1);
        subimage2_crop=image2_crop(y:y+2*iby2/mesh,x:x+2*ibx2/mesh);%subimage of image 2 corresponding to the optimum displacement of first image
        sum_square=sum_square*sum(sum(subimage2_crop.*subimage2_crop));% product of variances of image 1 and 2
        sum_square=sqrt(sum_square);% sqrt of the variance product to normalise correlation
        if ~isempty(y) && ~isempty(x)
            try
                if par_civ.CorrSmooth==1
                    [vector,F(ivec)] = SUBPIXGAUSS (result_conv,x,y);
                elseif par_civ.CorrSmooth==2
                    [vector,F(ivec)] = SUBPIX2DGAUSS (result_conv,x,y);
                end
                
                
                utable(ivec)=vector(1)*mesh+shiftx(ivec);
                vtable(ivec)=vector(2)*mesh+shifty(ivec);
                
                
                xtable(ivec)=iref+utable(ivec)/2-0.5;% convec flow (velocity taken at the point middle from imgae 1 and 2)
                ytable(ivec)=jref+vtable(ivec)/2-0.5;% and position of pixel 1=0.5 (convention for image coordinates=0 at the edge)
                
                iref=round(xtable(ivec));% image index for the middle of the vector
                jref=round(ytable(ivec));
                if checkmask && par_civ.Mask(jref,iref)<200 && par_civ.Mask(jref,iref)>=100
                    utable(ivec)=0;
                    vtable(ivec)=0;
                    F(ivec)=3;
                end
                ctable(ivec)=corrmax/sum_square;% correlation value
            catch ME
                F(ivec)=3;
            end
        else
            F(ivec)=3;
        end
    end
end
result_conv=result_conv*corrmax/(255*sum_square);% keep the last correlation matrix for output

%------------------------------------------------------------------------
% --- Find the maximum of the correlation function after interpolation
function [vector,F] = SUBPIXGAUSS (result_conv,x,y)
%------------------------------------------------------------------------
vector=[0 0]; %default
F=0;
[npy,npx]=size(result_conv);
result_conv(result_conv<1)=1; %set to 1 correlation values smaller than 1 (to avoid divergence in the log)
%the following 8 lines are copyright (c) 1998, Uri Shavit, Roi Gurka, Alex Liberzon, Technion ??? Israel Institute of Technology
%http://urapiv.wordpress.com
peaky = y;
if y <= npy-1 && y >= 1
    f0 = log(result_conv(y,x));
    f1 = log(result_conv(y-1,x));
    f2 = log(result_conv(y+1,x));
    peaky = peaky+ (f1-f2)/(2*f1-4*f0+2*f2);
else
    F=-2; % warning flag for vector truncated by the limited search box
end
peakx=x;
if x <= npx-1 && x >= 1
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
vector=[0 0]; %default
F=-2;
peaky=y;
peakx=x;
result_conv(result_conv<1)=1; %set to 1 correlation values smaller than 1 (to avoid divergence in the log)
[npy,npx]=size(result_conv);
if (x <= npx-1) && (y <= npy-1) && (x >= 1) && (y >= 1)
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

%INPUT:
% xmid- u/2: set of apparent phys x coordinates in the ref plane, image A
% ymid- v/2: set of apparent phys y coordinates in the ref plane, image A
% xmid+ u/2: set of apparent phys x coordinates in the ref plane, image B
% ymid+ v/2: set of apparent phys y coordinates in the ref plane, image B
% XmlData: content of the xml files containing geometric calibration parameters
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

Error=(sqrt(mfx^2+mfy^2)/(2*sqrt(2)*mtz)).*(((Dyb-Dya).*(-u)-(Dxb-Dxa).*(-v))./Den);

z=((Dxb-Dxa).*(-u)+(Dyb-Dya).*(-v))./Den;

xnew(1,:)=Dxa.*z+x_a;
xnew(2,:)=Dxb.*z+x_b;
ynew(1,:)=Dya.*z+y_a;
ynew(2,:)=Dyb.*z+y_b;
Xphy=mean(xnew,1);
Yphy=mean(ynew,1);





