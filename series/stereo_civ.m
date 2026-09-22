%'stereo_series': PIV function activated by the general GUI series
% --- call the sub-functions:
%   civ: PIV function itself
%   fix: removes false vectors after detection by various criteria
%   filter_tps: make interpolation-smoothing
%------------------------------------------------------------------------
% function [GUIParam,errormsg]= civ_series(Param,ncfile)
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

function [GUIParam,errormsg]= stereo_civ(Param)
GUIParam=[];
errormsg='';

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)% function activated from the GUI series but not RUN
    if size(Param.InputTable,1)<2
        msgbox_uvmat('WARNING','two input file series must be entered')
        return
    end
    path_series=fileparts(which('series'));
    addpath(fullfile(path_series,'series'))
    AppData=stereo_input(Param);% introduce the civ parameters using the GUI stereo_input
    GUIParam.ActionInput=read_app(AppData);
    %Data.num_SearchBoxSize_2
    delete(AppData)
    if isempty(GUIParam)
        GUIParam=Param;% if  civ_input has been cancelled, keep previous parameters
    end
    GUIParam.Program=mfilename;%gives the name of the current function
    GUIParam.AllowInputSort='on';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    GUIParam.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    GUIParam.NbSlice='off'; %nbre of slices ('off' by default)
    GUIParam.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    GUIParam.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    GUIParam.FieldTransform = 'off';%can use a transform function (use it by force, no input option)
    GUIParam.ProjObject='off';%can use projection object(option 'off'/'on',
    GUIParam.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    GUIParam.OutputDirExt='.stereo';%set the output dir extension
    GUIParam.OutputSubDirMode='auto'; %select the last subDir in the input table as root of the output subdir name (option 'all'/'first'/'last', 'all' by default)
    GUIParam.OutputFileMode='NbInput_i';% one output file expected per value of i index (used for waitbar)
    GUIParam.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default=1)
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
NbView=size(Param.InputTable,1);
XmlData=cell(1,NbView);

%% List of input indices i and j
i_indices=Param.IndexRange.first_i:Param.IndexRange.incr_i:Param.IndexRange.last_i;
if isfield(Param.IndexRange,'first_j')
    j_indices=Param.IndexRange.first_j:Param.IndexRange.incr_j:Param.IndexRange.last_j;
    NomTypeOut='_1_1'; %i and j indices for outdput
else
    j_indices=1;
    NomTypeOut='_1';% Only i indices for output
end

%% File relabeling documented by the xml file
CheckRelabel_GUI=isfield(Param.IndexRange,'Relabel' )&& Param.IndexRange.Relabel;%=true for index relabeling (PCO);

%% Input file info
for iview=1:2
    RootPath{iview}=Param.InputTable{iview,1};
    RootFile{iview}=Param.InputTable{iview,3};
    SubDir{iview}=Param.InputTable{iview,2};
    NomType{iview}=Param.InputTable{iview,4};
    FileExt{iview}=Param.InputTable{iview,5};
    Time{iview}=[];

    XmlFileName=find_imadoc(RootPath{iview},SubDir{iview});
    if ~isempty(XmlFileName)
        XmlData{iview}=imadoc2struct(XmlFileName);%read the time from XmlFileName
        if isfield(XmlData{iview},'Time')
            Time{iview}=XmlData{iview}.Time;
            TimeSource{iview}='xml';
        end
    end

    if CheckRelabel_GUI && isfield(XmlData{iview},'FileSeries')
        [FileName,frame_index{iview}]=index2filename(XmlData{iview}.FileSeries,Param.IndexRange.first_i,j_indices(1),Param.IndexRange.last_j);
        FirstFileName=fullfile(RootPath{iview},SubDir{iview},FileName);
        FileInfo=get_file_info(FirstFileName);
        FileType{iview}=FileInfo.FileType;
        CheckRelabel{iview}=true;
    else
        CheckRelabel{iview}=false;
        FirstFileName=fullfile_indices(fullfile(RootPath{iview},SubDir{iview},RootFile{iview}),FileExt{iview},NomType{iview},Param.IndexRange.first_i,[],j_indices(1));%get first file name
        [FileInfo,MovieObject{iview}]=get_file_info(FirstFileName);
        FileType{iview}=FileInfo.FileType;
        if isfield(FileInfo,'NumberOfFrames') && FileInfo.NumberOfFrames >1
            if isempty(regexp(NomType,'1$', 'once'))% no file indexing
                frame_index{iview}=ones(numel(j_indices),1)*i_indices;% the index i denotes the frame number in a movie, no index j
            else
                frame_index{iview}=j_indices'*ones(1,numel(i_indices));% the index j denotes the frame number in a movie
                MovieObject{iview}=[]; %not a single video object
            end
        else
            frame_index{iview}=ones(numel(j_indices),numel(i_indices));
        end
        % get time from video record if not defined by the xml file
        if isempty(Time{iview}) && ismember(FileType_A,{'video','cine_phantom','telopsIR'})% case of video inputFrameIndex_A
            Time{iview}=zeros(2,FileInfo.NumberOfFrames+1);
            Time{iview}(2,:)=(0:1/FileInfo.FrameRate:(FileInfo.NumberOfFrames)/FileInfo.FrameRate);
        end
    end
    if isfield(FileInfo,'ColorType') && strcmp(FileInfo.ColorType,'truecolor')
        BitDepth{iview}=16;
    else
        BitDepth{iview}=FileInfo.BitDepth;
    end
end
% reference Z position from calibration
if isfield(XmlData{1},'Slice')
    Zref=XmlData{1}.Slice.SliceCoord(3);
    if ~(isfield(XmlData{2},'Slice')&& isequal(XmlData{2}.Slice.SliceCoord(3),Zref))
        disp('ERROR: inconcistent Z position from ImaDoc xml files')
        return
    end
else
    disp('ERROR: Z position in ImaDoc xml file')
        return
end


%% Output directory and data preparation
OutputDir=[Param.OutputSubDir Param.OutputDirExt];

ListGlobalAttribute={'Conventions','Program','CivStage','Time','Xshift_mean','Yshift_mean','Zshift_mean'};
Data.ListVarName={'C','X','Y','U','V','FF','Xphys','Yphys','Zshift','Xshift','Yshift'};

% test for recording the smmoothed data
CheckSmooth=(Param.ActionInput.CheckPatch1 && ~Param.ActionInput.CheckCiv2) ||(Param.ActionInput.CheckPatch2 && ~Param.ActionInput.CheckCiv3) || Param.ActionInput.CheckPatch3;
Data.VarAttribute{1}.Role='scalar';
Data.VarAttribute{1}.scale_factor=1/100;%scla factor for correlation
Data.VarAttribute{2}.Role='coord_x';
Data.VarAttribute{3}.Role='coord_y';
Data.VarAttribute{4}.Role='vector_x';
Data.VarAttribute{5}.Role='vector_y';
Data.VarAttribute{6}.Role='errorflag';
Data.VarAttribute{7}.Role='vector_x';
Data.VarAttribute{8}.Role='vector_y';
Data.VarAttribute{9}.Role='scalar';
Data.VarAttribute{10}.Role='vector_x';
Data.VarAttribute{11}.Role='vector_y';
if CheckSmooth
    nbvar=numel(Data.ListVarName);
    Data.ListVarName=[Data.ListVarName {'U_smooth','V_smooth'}];
    Data.VarAttribute{nbvar+1}.Role='vector_x';
    Data.VarAttribute{nbvar+2}.Role='vector_y';
end
Data.VarDimName=repmat({'nb_vec'},1,numel(Data.ListVarName));

Data.Conventions='uvmat/civdata/compress';% states the conventions used for the description of field variables and attributes
Data.Program=mfilename;%gives the name of the current function;
Data.CivStage=0;%default
Data.Time=NaN; %default
par_civ1.MaskName_A='';%default
par_civ1.MaskName_B='';%default

%% overwrite or skip when the output file already exists
CheckOverwrite=1;%default
if isfield(Param,'CheckOverwrite')
    CheckOverwrite=Param.CheckOverwrite;
end

%%%%% MAIN LOOP %%%%%%
for index_i=1:numel(i_indices)
    for index_j=1:numel(j_indices)
        if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
            disp('program stopped by user')
            return
        end
        OutputFile=fullfile_indices(fullfile(RootPath{1},OutputDir,RootFile{1}),'.nc',NomTypeOut,i_indices(index_i),[],j_indices(index_j));
        if ~CheckOverwrite && exist(OutputFile,'file')
            disp('existing output file already exists, skip to next field')
            continue% skip iteration if the mode overwrite is desactivated and the result file already exists
        end
        tstart=tic;
        if CheckRelabel{1}
            [ImageName_A,FrameIndex_A]=index2filename(XmlData{1}.FileSeries,i_indices(index_i),j_indices(index_j),Param.IndexRange.last_j);
            ImageName_A=fullfile(RootPath{1},SubDir{1},ImageName_A);% include path
        else
            ImageName_A=fullfile_indices(fullfile(RootPath{1},SubDir{1},RootFile{1}),FileExt{1},NomType{1},i_indices(index_i),[],j_indices(index_j))
            FrameIndex_A=frame_index{1}(index_j,index_i); 
        end
        if CheckRelabel{2}  
              [ImageName_B,FrameIndex_B]=index2filename(XmlData{2}.FileSeries,i_indices(index_i),j_indices(index_j),Param.IndexRange.last_j);
            ImageName_B=fullfile(RootPath{1},SubDir{1},ImageName_B);% include path
        else
            ImageName_B=fullfile_indices(fullfile(RootPath{2},SubDir{2},RootFile{2}),FileExt{2},NomType{2},i_indices(index_i),[],j_indices(index_j))
            FrameIndex_B=frame_index{2}(index_j,index_i);
        end

        [A{1},MovieObject{1}] = read_image(ImageName_A,FileType{1},MovieObject{1},FrameIndex_A);
        [A{2},MovieObject{2}] =read_image(ImageName_B,FileType{2},MovieObject{2},FrameIndex_B);

        [A,Rangx,Rangy]=phys_ima(A,XmlData,Param.ActionInput.resolution);%transform images A{1} and A{2} in phys coordinates on a common pixel grid
        [Npy,Npx]=size(A{1});

        

        %%% record time
        Data.Time=Time{1}(j_indices(index_j)+1,i_indices(index_i)+1);
        Time2=Time{2}(j_indices(index_j)+1,i_indices(index_i)+1);
        Dt=Time2-Data.Time;
        if Time2 ~= Data.Time
            disp(['WARNING: the times of the two images differ by ' num2str(Dt)])
        end

        %% case of image luminosity rescaling
        if Param.ActionInput.CheckRescale &&~isempty(Param.ActionInput.Maxtanh)
            A{1} =Param.ActionInput.Maxtanh*tanh(double(A{1})/Param.ActionInput.Maxtanh);
            A{2}=Param.ActionInput.Maxtanh*tanh(double(A{2})/Param.ActionInput.Maxtanh);
        end

        %% smoothes the particle images to favor correlations
        A{1}=filter2(ones(3,3),A{1});
        A{2}=filter2(ones(3,3),A{2});

        %% get mask if relevant
        if Param.ActionInput.CheckMask
            MaskRootName_A=Param.ActionInput.Mask_A;
            MaskRootName_B=Param.ActionInput.Mask_B;
            NbSlice_i=[];
            if isfield(Param.ActionInput,'NbSlice')
                NbSlice_i=Param.ActionInput.num_NbSlice;
            end
            maskname_A=get_mask_name(MaskRootName_A,i_indices(index_i),j_indices(index_j),NbSlice_i,0);
            maskname_B=get_mask_name(MaskRootName_B,i_indices(index_i),j_indices(index_j),NbSlice_i,0);
            if ~strcmp(par_civ1.MaskName_A,maskname_A)||~strcmp(par_civ1.MaskName_B,maskname_B)%% mask image not already read
                Mask{1}=imread(maskname_A);%update the mask, an store it for future use
                Mask{2}=imread(maskname_B);%update the mask, an store it for future use
                [Mask,Rangx_mask,Rangy_mask]=phys_ima(Mask,XmlData,Param.ActionInput.resolution);
                if ~isequal(Rangx_mask,Rangx) || ~isequal(Rangy_mask,Rangy)
                    disp('mask bounds inconsitent with images')
                    return
                end
            end
           
        end
        
        %% save images in phys coordinates for test mode
        if Param.ActionInput.CheckTest % save images in phys coordinates for test mode
            PhysImageAName=[fullfile(RootPath{1},OutputDir,RootFile{1}) '_' num2str(i_indices(index_i)) '_' num2str(j_indices(index_j)) 'a.png'];
            PhysImageBName=[fullfile(RootPath{1},OutputDir,RootFile{1}) '_' num2str(i_indices(index_i)) '_' num2str(j_indices(index_j)) 'b.png'];
            imwrite(uint16(A{1}),PhysImageAName)
            imwrite(uint16(A{2}),PhysImageBName)
        end

        time_civ1=0;
        time_patch1=0;
        time_civ2=0;
        time_patch2=0;
        %%  Civ1  %%%%%%%%%%%%%%%%%
        if Param.ActionInput.CheckCiv1 && isfield (Param.ActionInput,'Civ1')
            tstart_civ1=tic;
            disp('civ1 started')
            par_civ1=Param.ActionInput.Civ1;
            if isfield(Param.ActionInput,'MinIma') && ~isnan(Param.ActionInput.MinIma)
                par_civ1.MinIma=Param.ActionInput.MinIma;
            end
            if isfield(Param.ActionInput,'MaxIma')&&~isnan(Param.ActionInput.MaxIma)
                par_civ1.MaxIma=Param.ActionInput.MaxIma;
            end
          
            par_civ1.ImageA=A{1};
            par_civ1.ImageB=A{2};
            par_civ1.ImageWidth=size(par_civ1.ImageA,2);%FileInfo_A.Width;
            par_civ1.ImageHeight=size(par_civ1.ImageA,1);%FileInfo_A.Height;
            list_param=(fieldnames(Param.ActionInput.Civ1))';
            Civ1_param=regexprep(list_param,'^.+','Civ1_$0');% insert 'Civ1_' before  each string in list_param
            Civ1_param=[{'Civ1_ImageA','Civ1_ImageB'} Civ1_param]; %insert the names of the two input images
            %indicate the values of all the global attributes in the output data
            Data.Civ1_ImageA=ImageName_A;
            Data.Civ1_ImageB=ImageName_B;
            if Param.ActionInput.CheckMask
                Civ1_param=[{'Civ1_MaskName_A','Civ1_MaskName_B'} Civ1_param]; %insert the names of the two input images
                par_civ1.MaskName_A=maskname_A;
                par_civ1.MaskName_B=maskname_B;
                par_civ1.Mask_A=Mask{1};
                par_civ1.Mask_B=Mask{2};
            end

            for ilist=1:length(list_param)
                Data.(Civ1_param{2+ilist})=Param.ActionInput.Civ1.(list_param{ilist});
            end
            Data.ListGlobalAttribute=[ListGlobalAttribute Civ1_param];
            Data.CivStage=1;

            % calculate velocity data (y and v in indices, reverse to y component)
            if strcmp(Param.RunMode,'cluster')
                [Data.X,Data.Y,Data.U,Data.V,Data.C,Data.FF,~, errormsg] = civ (par_civ1);% single processor used in cluster
            else
                [Data.X,Data.Y,Data.U,Data.V,Data.C,Data.FF,~,errormsg] = parciv (par_civ1);%use parfor loop
            end
            if ~isempty(errormsg)
                disp_uvmat('ERROR',errormsg,checkrun)
                return
            end

            time_civ1=toc(tstart_civ1);
        end

        %%%%%%%%%%%%%%%%%  Fix1  %%%%%%%%%%%%%%%%%
        if Param.ActionInput.CheckFix1 && isfield (Param.ActionInput,'Fix1')
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
            Data.FF=uint8(detect_false(Param.ActionInput.Fix1,Data.C,Data.U,Data.V,Data.FF));
            Data.CivStage=2;
        end

        %%%%%%%%%%%%%%%%%  Patch1  %%%%%%%%%%%%%%%%%
        if Param.ActionInput.CheckPatch1 && isfield (Param.ActionInput,'Patch1')
            disp('patch1 started')
            tstart_patch1=tic;

            % record the processing parameters of Patch1 as global attributes in the result nc file
            list_param=fieldnames(Param.ActionInput.Patch1)';
            %list_param(strcmp('TestPatch1',list_param))=[];% remove 'TestPatch1' from the list of parameters
            Patch1_param=regexprep(list_param,'^.+','Patch1_$0');% insert 'Patch1_' before  each parameter name
            for ilist=1:length(list_param)
                Data.(Patch1_param{ilist})=Param.ActionInput.Patch1.(list_param{ilist});
            end
            Data.CivStage=3;% record the new state of processing
            Data.ListGlobalAttribute=[Data.ListGlobalAttribute Patch1_param];

            if isempty(Data.FF)
                ind_good=1:numel(Data.FF);
            else
                ind_good=find(Data.FF==0);
            end
            if isempty(ind_good)
                disp_uvmat('ERROR','all vectors of civ1 are bad, check input parameters' ,checkrun)
                return
            end

            % perform Patch calculation using the UVMAT fct 'filter_tps'
            [SubRange,NbCentres,Coord_tps,U_tps,V_tps,~,Ures, Vres,~,FFres]=...
                filter_tps([Data.X(ind_good),Data.Y(ind_good)],Data.U(ind_good),Data.V(ind_good),[],Data.Patch1_SubDomainSize,Data.Patch1_FieldSmooth,Data.Patch1_MaxDiff);
            Data.U_smooth=Data.U;% false vectors kept unchanged
            Data.V_smooth=Data.V;
            Data.U_smooth(ind_good)=Ures;% take the interpolated (smoothed) velocity values for good vectors, keep civ1 data for the other
            Data.V_smooth(ind_good)=Vres;
            Data.FF(ind_good)=uint8(4*FFres);%set FF to value =4 for vectors eliminated by filter_tps
            time_patch1=toc(tstart_patch1);
            disp('patch1 performed')
        end

        %%%%%%%%%%%%%%%%%  Civ2  %%%%%%%%%%%%%%%%%
        if Param.ActionInput.CheckCiv2 && isfield (Param.ActionInput,'Civ2')
            disp('civ2 started')
            tstart_civ2=tic;
            par_civ2=Param.ActionInput.Civ2;
            par_civ2.ImageA=A{1};
            par_civ2.ImageB=A{2};
            par_civ2.ImageWidth=size(par_civ2.ImageA,2);%FileInfo_A.Width;
            par_civ2.ImageHeight=size(par_civ2.ImageA,1);%FileInfo_A.Height;
            % list_param=(fieldnames(Param.ActionInput.Civ2))';
            % Civ2_param=regexprep(list_param,'^.+','Civ2_$0');% insert 'Civ2_' before  each string in list_param
            %Civ1_param=[{'Civ1_ImageA','Civ1_ImageB','Civ1_Time','Civ1_Dt'} Civ1_param]; %insert the names of the two input images
            %indicate the values of all the global attributes in the output data

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


            %% get civ2 correlation parameters

            par_civ2.SearchBoxShift=zeros(size(par_civ2.Grid));
            par_civ2.SearchBoxShift(:,1)=Shiftx;%rescale the shift in case of Dt different for Civ1 and Civ2
            par_civ2.SearchBoxShift(:,2)=Shifty;

            if par_civ2.CheckDeformation
                par_civ2.DUDX(nbval>0)=DUDX(nbval>0)./nbval(nbval>0);
                par_civ2.DUDY(nbval>0)=DUDY(nbval>0)./nbval(nbval>0);
                par_civ2.DVDX(nbval>0)=DVDX(nbval>0)./nbval(nbval>0);
                par_civ2.DVDY(nbval>0)=DVDY(nbval>0)./nbval(nbval>0);
            end
            if Param.ActionInput.CheckMask
                Civ2_param=[{'Civ2_MaskName_A','Civ2_MaskName_B'} Civ1_param]; %insert the names of the two input images
                par_civ2.MaskName_A=maskname_A;
                par_civ2.MaskName_B=maskname_B;
                par_civ2.Mask_A=Mask{1};
                par_civ2.Mask_B=Mask{2};
            end

            % calculate velocity data
            if strcmp(Param.RunMode,'cluster')
                [Data.X,Data.Y,Data.U,Data.V,Data.C,Data.FF,~, errormsg] = civ (par_civ2);% single processor used in cluster
            else
                [Data.X,Data.Y,Data.U,Data.V,Data.C,Data.FF,~, errormsg] = parciv (par_civ2);%use parfor loop
            end
            list_param=(fieldnames(Param.ActionInput.Civ2))';
            %list_param(strcmp('TestCiv2',list_param))=[];% remove the parameter TestCiv2 from the list
            Civ2_param=regexprep(list_param,'^.+','Civ2_$0');% insert 'Civ2_' before  each string in list_param
            %Civ2_param=[{'Civ2_ImageA','Civ2_ImageB','Civ2_FrameIndexA','Civ2_FrameIndexB','Civ2_Time','Civ2_Dt'} Civ2_param1]; %insert the names of the two input images
            %indicate the values of all the global attributes in the output data
            % if exist('ImageName_A','var')
            %     Data.Civ2_ImageA=ImageName_A;
            %     Data.Civ2_ImageB=ImageName_B;
            %     Data.Civ2_FrameIndexA=FrameIndex_A;
            %     Data.Civ2_FrameIndexB=FrameIndex_B;
            %
            % end
            for ilist=1:length(list_param)
                Data.(Civ2_param{ilist})=Param.ActionInput.Civ2.(list_param{ilist});
            end
            Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ2_param];
            % if isfield( Data,'Civ2_Background')
            %     Data.Civ2_Background=backgroundname;% update with the relevant background used
            % end

            disp('civ2 performed')
            time_civ2=toc(tstart_civ2);
        end

        %% Fix2
        if isfield (Param.ActionInput,'Fix2')
            disp('detect_false2 started')
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
            Data.FF=uint8(detect_false(Param.ActionInput.Fix1,Data.C,Data.U,Data.V,Data.FF));
            Data.CivStage=4;

        end

        %% Patch2
        if isfield (Param.ActionInput,'Patch2')

            disp('patch2 started')
            tstart_patch2=tic;

            % record the processing parameters of Patch1 as global attributes in the result nc file
            list_param=fieldnames(Param.ActionInput.Patch2)';
            Patch2_param=regexprep(list_param,'^.+','Patch2_$0');% insert 'Patch2_' before  each parameter name
            for ilist=1:length(list_param)
                Data.(Patch2_param{ilist})=Param.ActionInput.Patch2.(list_param{ilist});
            end
            Data.CivStage=6;% record the new state of processing
            Data.ListGlobalAttribute=[Data.ListGlobalAttribute Patch2_param];

            if isempty(Data.FF)
                ind_good=1:numel(Data.FF);
            else
                ind_good=find(Data.FF==0);
            end
            if isempty(ind_good)
                disp_uvmat('ERROR','all vectors of civ1 are bad, check input parameters' ,checkrun)
                return
            end

            % perform Patch calculation using the UVMAT fct 'filter_tps'
            [SubRange,NbCentres,Coord_tps,U_tps,V_tps,~,Ures, Vres,~,FFres]=...
                filter_tps([Data.X(ind_good),Data.Y(ind_good)],Data.U(ind_good),Data.V(ind_good),[],Data.Patch2_SubDomainSize,Data.Patch2_FieldSmooth,Data.Patch2_MaxDiff);
            Data.U_smooth=Data.U;% false vectors kept unchanged
            Data.V_smooth=Data.V;
            Data.U_smooth(ind_good)=Ures;% take the interpolated (smoothed) velocity values for good vectors, keep civ1 data for the other
            Data.V_smooth(ind_good)=Vres;
            Data.FF(ind_good)=uint8(4*FFres);%set FF to value =4 for vectors eliminated by filter_tps
            time_patch2=toc(tstart_patch2);
            disp('patch2 performed')
        end

        %%%%%%%%%%%%%%%%%  Civ3  %%%%%%%%%%%%%%%%%

        if Param.ActionInput.CheckCiv3 && isfield (Param.ActionInput,'Civ3')
            par_civ3=Param.ActionInput.Civ3;
            par_civ3.ImageA=A{1};
            par_civ3.ImageB=A{2};
            par_civ3.ImageWidth=size(par_civ3.ImageA,2);
            par_civ3.ImageHeight=size(par_civ3.ImageA,1);

% 
%             else% automatic grid
%                 nbinterv_x=floor((npx_ima-1)/par_civ2.Dx);
%                 gridlength_x=nbinterv_x*par_civ2.Dx;
%                 minix=ceil((npx_ima-gridlength_x)/2);
%                 nbinterv_y=floor((npy_ima-1)/par_civ2.Dy);
%                 gridlength_y=nbinterv_y*par_civ2.Dy;
%                 miniy=ceil((npy_ima-gridlength_y)/2);
%                 [GridX,GridY]=meshgrid(minix:par_civ2.Dx:npx_ima-1,miniy:par_civ2.Dy:npy_ima-1);
%                 par_civ2.Grid=zeros(numel(GridX),2);
%                 par_civ2.Grid(:,1)=reshape(GridX,[],1);
%                 par_civ2.Grid(:,2)=reshape(GridY,[],1);% increases with array index
%             end
% 


            % automatic grid
                minix=floor(par_civ3.Dx/2)-0.5;
                maxix=minix+par_civ3.Dx*floor((par_civ3.ImageWidth-1)/par_civ3.Dx);
                miniy=floor(par_civ3.Dy/2)-0.5;
                maxiy=minix+par_civ3.Dy*floor((par_civ3.ImageHeight-1)/par_civ3.Dy);
                [GridX,GridY]=meshgrid(minix:par_civ3.Dx:maxix,miniy:par_civ3.Dy:maxiy);
                par_civ3.Grid(:,1)=reshape(GridX,[],1);
                par_civ3.Grid(:,2)=reshape(GridY,[],1);
        
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
            % calculate velocity data

            if strcmp(Param.RunMode,'cluster')
                [Data.X,Data.Y,Data.U,Data.V,Data.C,Data.FF,~, errormsg] = civ (par_civ3);% single processor used in cluster
            else
                [Data.X,Data.Y,Data.U,Data.V,Data.C,Data.FF,~, errormsg] = parciv (par_civ3);%use parfor loop
            end

            % calculate velocity data (y and v in indices, reverse to y component)
            %[xtable, ytable, utable, vtable, ctable, F] = civ (par_civ3);
            list_param=(fieldnames(Param.ActionInput.Civ3))';
            Civ3_param=regexprep(list_param,'^.+','Civ3_$0');% insert 'Civ3_' before  each string in list_param
            %Civ3_param=[{'Civ3_ImageA','Civ3_ImageB','Civ3_Time','Civ3_Dt'} Civ3_param]; %insert the names of the two input images
            %indicate the values of all the global attributes in the output data
            %     Data.Civ3_ImageA=ImageName_A;
            %     Data.Civ3_ImageB=ImageName_B;
            %     Data.Civ3_Time=(time(i2+1,j2+1)+time(i1+1,j1+1))/2;
            %     Data.Civ3_Dt=0;
            for ilist=1:length(list_param)
                Data.(Civ3_param{ilist})=Param.ActionInput.Civ3.(list_param{ilist});
            end
            Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ3_param];

            Data.CivStage=Data.CivStage+1;
        end

        %%%%%%%%%%%%%%%%%  Fix3  %%%%%%%%%%%%%%%%%
        if isfield (Param.ActionInput,'Fix3')
            ListFixParam=fieldnames(Param.ActionInput.Fix3);
            for ilist=1:length(ListFixParam)
                ParamName=ListFixParam{ilist};
                ListName=['Fix3_' ParamName];
                Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];
                Data.(ListName)=Param.ActionInput.Fix3.(ParamName);
            end

            Data.ListVarName=[Data.ListVarName {'Civ3_FF'}];
            Data.VarDimName=[Data.VarDimName {'nb_vec_3'}];
            nbvar=length(Data.ListVarName);
            Data.VarAttribute{nbvar}.Role='errorflag';
            Data.FF=double(fix(Param.ActionInput.Fix3,Data.Civ3_F,Data.Civ3_C,Data.Civ3_U,Data.Civ3_V));
            Data.CivStage=Data.CivStage+1;
        end

        %%%%%%%%%%%%%%%%%  Patch3  %%%%%%%%%%%%%%%%%
        if isfield (Param.ActionInput,'Patch3')
            disp('patch3 started')
            tstart_patch3=tic;

            % record the processing parameters of Patch1 as global attributes in the result nc file
            list_param=fieldnames(Param.ActionInput.Patch3)';
            Patch3_param=regexprep(list_param,'^.+','Patch3_$0');% insert 'Patch1_' before  each parameter name
            for ilist=1:length(list_param)
                Data.(Patch3_param{ilist})=Param.ActionInput.Patch3.(list_param{ilist});
            end
            Data.CivStage=Data.CivStage+1;% record the new state of processing
            Data.ListGlobalAttribute=[Data.ListGlobalAttribute Patch3_param];

            if isempty(Data.FF)
                ind_good=1:numel(Data.FF);
            else
                ind_good=find(Data.FF==0);
            end
            if isempty(ind_good)
                disp_uvmat('ERROR','all vectors of civ1 are bad, check input parameters' ,checkrun)
                return
            end

            % perform Patch calculation using the UVMAT fct 'filter_tps'
            [SubRange,NbCentres,Coord_tps,U_tps,V_tps,~,Ures, Vres,~,FFres]=...
                filter_tps([Civ_X(ind_good),Civ_Y(ind_good)],Data.U(ind_good),Data.V(ind_good),[],Data.Patch3_SubDomainSize,Data.Patch3_FieldSmooth,Data.Patch3_MaxDiff);
            Data.U_smooth=Data.U;% false vectors kept unchanged
            Data.V_smooth=Data.V;
            Data.U_smooth(ind_good)=Ures;% take the interpolated (smoothed) velocity values for good vectors, keep civ1 data for the other
            Data.V_smooth(ind_good)=Vres;
            Data.FF(ind_good)=uint8(4*FFres);%set FF to value =4 for vectors eliminated by filter_tps
            time_patch3=toc(tstart_patch3);
            disp('patch3 performed')
        end

          if CheckSmooth
         [Xmid, Ymid, Uphys, Vphys] =getPhysValues(Rangx,Rangy, Npx, Npy, Data.X, Data.Y, Data.U_smooth, Data.V_smooth);% transform from pixels to phys coordinates in the ref pla
           else
                [Xmid, Ymid,Uphys, Vphys] =getPhysValues(Rangx,Rangy, Npx, Npy, Data.X, Data.Y, Data.U, Data.V);
           end
         [Data.Zshift,Data.Xphys,Data.Yphys,Data.Xshift,Data.Yshift]=shift2z(Xmid,Ymid,Uphys,Vphys,XmlData); %Data.Xphys and Data.Xphys are real coordinate (geometric correction more accurate than xtemp/ytempy

        Data.C=uint8(100*Data.C);% rescale to store as integer
 indgood=find(Data.FF==0);
 indbad=find(Data.FF~=0);
 Data.Zshift(indbad)=NaN;Data.Xphys(indbad)=NaN;Data.Yphys(indbad)=NaN;Data.Xshift(indbad)=NaN;Data.Yshift(indbad)=NaN;
        % get the best linear fit

        Data.Xshift_mean=mean(Data.Xshift(indgood));
Data.Yshift_mean=mean(Data.Yshift(indgood));
Data.Zshift_mean=mean(Data.Zshift(indgood));
        

        %% write result in a netcdf file
        errormsg=struct2nc(OutputFile,Data);
        if isempty(errormsg)
            disp([OutputFile ' written'])
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
    if isfield (Param,'MinVel')&&~isempty(Param.MinVel)&&~isnan(Param.MinVel)
        U2Min=Param.MinVel*Param.MinVel;
        FF(Umod<U2Min & FFIn==0)=3;
    end
    if isfield (Param,'MaxVel')&&~isempty(Param.MaxVel)&&~isnan(Param.MinVel)
         U2Max=Param.MaxVel*Param.MaxVel;
        FF(Umod>U2Max & FFIn==0)=3;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -----------------------------------------------------------------------
% --- get phys coordinates in the reference plane from the coordinates in pixels
function [Xmid, Ymid, Uphys, Vphys] ...
    = getPhysValues(Rangx, Rangy, Npx, Npy, Data_Civ_X, Data_Civ_Y,Data_Civ_U, Data_Civ_V)
    
    % get z from u and v (displacements)     
    Xmid=Rangx(1)+(Rangx(2)-Rangx(1))*(Data_Civ_X-0.5)/(Npx-1);%temporary coordinate (velocity taken at the point middle from imgae 1 and 2)
    Ymid=Rangy(2)+(Rangy(1)-Rangy(2))*(Data_Civ_Y-0.5)/(Npy-1);%temporary coordinate (velocity taken at the point middle from imgae 1 and 2)
    Uphys=Data_Civ_U*(Rangx(2)-Rangx(1))/(Npx-1);
    Vphys=Data_Civ_V*(Rangy(1)-Rangy(2))/(Npy-1);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -----------------------------------------------------------------------
% --- gives the z coordinate and consitency error from the apparent phys coordinates in the reference plane
function [z,Xphy,Yphy,Xshift,Yshift]=shift2z(xmid, ymid, u, v,XmlData)
% -----------------------------------------------------------------------
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
% Error=(((Dyb-Dya).*(-u)-(Dxb-Dxa).*(-v))./sqrt(Den));
z=((Dxb-Dxa).*(-u)+(Dyb-Dya).*(-v))./Den;

xnew(1,:)=Dxa.*z+x_a;
xnew(2,:)=Dxb.*z+x_b;
ynew(1,:)=Dya.*z+y_a;
ynew(2,:)=Dyb.*z+y_b;
Xphy=mean(xnew,1);
Yphy=mean(ynew,1);
%%%%%%NEW
lambda=(((Dyb-Dya).*(-u)-(Dxb-Dxa).*(-v))./Den);
Xshift=-lambda.*(Dyb-Dya);
Yshift=lambda.*(Dxb-Dxa);
 
            

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iy=get_max(a)% get the max with sub pixel resolution
a_max=max(a);
[Nby,Nbx]=size(a);
iy=zeros(1,Nbx);
for ind_x=1:Nbx
    iy_range=find(a(:,ind_x)==a_max(ind_x));
    iy(ind_x)=0.5*(iy_range(1)+iy_range(end));
    iy_min=iy_range(1)-1;
    iy_plus=iy_range(end)+1;
    if iy_min>=1 && iy_plus<=Nby
        a_plus=a(iy_plus,ind_x);
        a_min=a(iy_min,ind_x);
        denom=2*a_max(ind_x)-a_plus-a_min;
        if denom >0
            iy(ind_x)=iy(ind_x)+0.5*(a_plus-a_min)/denom;%adjust the position of the max with a quadratic fit of the three points around the max
        end
    end
end


