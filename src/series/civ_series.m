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
%  Copyright  2011, LEGI / CNRS-UJF-INPG, joel.sommeria@legi.grenoble-inp.fr.
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

function [Data,errormsg,result_conv]= civ_series(Param,ncfile)
errormsg='';
path_series=fileparts(which('series'));
addpath(fullfile(path_series,'series'))
%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    Data=civ_input(Param);% introduce the civ parameters using the GUI civ_input
    Data.Program=mfilename;%gives the name of the current function
    Data.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    Data.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    Data.NbSlice='off'; %nbre of slices ('off' by default)
    Data.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    Data.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    Data.FieldTransform = 'off';%can use a transform function
    Data.ProjObject='off';%can use projection object(option 'off'/'on',
    Data.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    Data.OutputDirExt='.civ';%set the output dir extension
    filecell=get_file_series(Param);%check existence of the first input file
    if ~exist(filecell{1,1},'file')
        msgbox_uvmat('WARNING','the first input file does not exist')
    end
    return
end

%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end

%% input files and indexing
NbField=1;
if isfield(Param,'InputTable')
    RootPath=Param.InputTable{1,1};
    RootFile=Param.InputTable{1,3};
    SubDir=Param.InputTable{1,2};
    NomType=Param.InputTable{1,4};
    FileExt=Param.InputTable{1,5};
    PairCiv1=Param.ActionInput.PairIndices.ListPairCiv1;
    PairCiv2='';
    if isfield(Param.ActionInput.PairIndices,'ListPairCiv2')
        PairCiv2=Param.ActionInput.PairIndices.ListPairCiv2;
    end
    MaxIndex=cell2mat(Param.IndexRange.MaxIndex);
    MinIndex=cell2mat(Param.IndexRange.MinIndex);
    [filecell,i_series,tild,j_series]=get_file_series(Param);
    [i1_series_Civ1,i2_series_Civ1,j1_series_Civ1,j2_series_Civ1,check_bounds,NomTypeNc]=...
        find_pair_indices(PairCiv1,i_series{1},j_series{1},MinIndex,MaxIndex);
    if ~isempty(PairCiv2)
        [i1_series_Civ2,i2_series_Civ2,j1_series_Civ2,j2_series_Civ2,check_bounds_Civ2]=...
            find_pair_indices(PairCiv2,i_series{1},j_series{1},MinIndex,MaxIndex);
        check_bounds=check_bounds | check_bounds_Civ2;
    end
    i1_series_Civ1=i1_series_Civ1(~check_bounds);
    i2_series_Civ1=i2_series_Civ1(~check_bounds);
    j1_series_Civ1=j1_series_Civ1(~check_bounds);
    j2_series_Civ1=j2_series_Civ1(~check_bounds);
    if ~isempty(j1_series_Civ1)
        FrameIndex_A_Civ1=j1_series_Civ1;
        FrameIndex_B_Civ1=j2_series_Civ1;
    else
        FrameIndex_A_Civ1=i1_series_Civ1;
        FrameIndex_B_Civ1=i2_series_Civ1;
    end
    if ~isempty(PairCiv2)
        i1_series_Civ2=i1_series_Civ2(~check_bounds);
        i2_series_Civ2=i2_series_Civ2(~check_bounds);
        j1_series_Civ2=j1_series_Civ2(~check_bounds);
        j2_series_Civ2=j2_series_Civ2(~check_bounds);
        if ~isempty(j1_series_Civ2)
            FrameIndex_A_Civ2=j1_series_Civ2;
            FrameIndex_B_Civ2=j2_series_Civ2;
        else
            FrameIndex_A_Civ2=i1_series_Civ2;
            FrameIndex_B_Civ2=i2_series_Civ2;
        end
    end
    
    NbField=numel(i1_series_Civ1);
    [FileType_A,FileInfo,MovieObject_A]=get_file_type(filecell{1,1});
    FileType_B=FileType_A;
    MovieObject_B=MovieObject_A;
    if size(filecell,1)>=2 && ~strcmp(filecell{1,1},filecell{2,1})
        [FileType_B,FileInfo,MovieObject_B]=get_file_type(filecell{2,1});
    end
end


%% Output directory
OutputDir=[Param.OutputSubDir Param.OutputDirExt];

Data.ListGlobalAttribute={'Conventions','Program','CivStage'};
Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
Data.Program='civ_series';
Data.CivStage=0;%default
ListVarCiv1={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F'}; %variables to read
ListVarFix1={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F','Civ1_FF'};
mask='';
maskname='';%default
check_civx=0;%default
check_civ1=0;%default
check_patch1=0;%default

%% get timing from the ImaDoc file or input video
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
%TODO: get time_A and time_B
% case of movies TODO TODO TODO
if isempty(time) && (strcmp(FileType,'video') || strcmp(FileType,'mmreader'))
    set(handles.ListPairMode,'Value',1);
    dt=1/get(MovieObject,'FrameRate');%time interval between successive frames
    if strcmp(NomTypeIma,'*')
        set(handles.ListPairMode,'String',{'series(Di)'})
        MaxIndex_i=get(MovieObject,'NumberOfFrames');
        time=(dt*(0:MaxIndex_i-1))';%list of image times
    else
        set(handles.ListPairMode,'String',[{'series(Dj)'};{'series(Di)'}])
        MaxIndex_i=max(i1_series(i1_series>0));
        MaxIndex_j=get(MovieObject,'NumberOfFrames');
        time=ones(MaxIndex_i,1)*(dt*(0:MaxIndex_j-1));%list of image times
        enable_j(handles,'on')
    end
    TimeUnit='s';
%%%%% MAIN LOOP %%%%%%

MovieObject_A=[];
for ifield=1:NbField
    
    %% Civ1
    if isfield (Param.ActionInput,'Civ1')
        par_civ1=Param.ActionInput.Civ1;
        if isfield(par_civ1,'reverse_pair')% A REVOIR
            if par_civ1.reverse_pair
                if ischar(par_civ1.ImageB)
                    temp=par_civ1.ImageA;
                    par_civ1.ImageA=imread(par_civ1.ImageB);
                end
                if ischar(temp)
                    par_civ1.ImageB=imread(temp);
                end
            end
        else
            ImageName_A=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i1_series_Civ1(ifield),[],j1_series_Civ1(ifield));
            [par_civ1.ImageA,MovieObject_A] = read_image(ImageName_A,FileType_A,MovieObject_A,FrameIndex_A_Civ1(ifield));
            ImageName_B=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i2_series_Civ1(ifield),[],j2_series_Civ1(ifield));
            [par_civ1.ImageB,MovieObject_B] = read_image(ImageName_B,FileType_B,MovieObject_B,FrameIndex_B_Civ1(ifield));
        end
        ncfile=fullfile_uvmat(RootPath,OutputDir,RootFile,'.nc',NomTypeNc,i1_series_Civ1(ifield),i2_series_Civ1(ifield),...
            j1_series_Civ1(ifield),j2_series_Civ1(ifield));
        par_civ1.ImageWidth=FileInfo.Width;
        par_civ1.ImageHeight=FileInfo.Height;
        list_param=(fieldnames(Param.ActionInput.Civ1))';
        Civ1_param=regexprep(list_param,'^.+','Civ1_$0');% insert 'Civ1_' before  each string in list_param
        Civ1_param=[{'Civ1_ImageA','Civ1_ImageB','Civ1_Time','Civ1_Dt'} Civ1_param]; %insert the names of the two input images
        %indicate the values of all the global attributes in the output data 
        Data.Civ1_ImageA=ImageName_A;
        Data.Civ1_ImageB=ImageName_B;
        Data.Civ1_Time=((time(i2_civ1(ifile)+1,j2_civ1(j)+1)+time(i1_civ1(ifile)+1,j1_civ1(j)+1))/2);
        Data.Civ1_Dt=(time(i2_civ1(ifile)+1,j2_civ1(j)+1)-time(i1_civ1(ifile)+1,j1_civ1(j)+1));
        for ilist=1:length(list_param)
            Data.(Civ1_param{4+ilist})=Param.ActionInput.Civ1.(list_param{ilist});
        end
        Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ1_param];
        Data.CivStage=1;
        
        % set the list of variables
        Data.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_F','Civ1_C'};%  cell array containing the names of the fields to record
        Data.VarDimName={'nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1','nb_vec_1'};
        Data.VarAttribute{1}.Role='coord_x';
        Data.VarAttribute{2}.Role='coord_y';
        Data.VarAttribute{3}.Role='vector_x';
        Data.VarAttribute{4}.Role='vector_y';
        Data.VarAttribute{5}.Role='warnflag';
        
        if strcmp(Param.ActionInput.ListCompareMode, 'PIV volume')
            Data.ListVarName=[Data.ListVarName 'Civ1_Z'];
            Data.Civ1_X=[];Data.Civ1_Y=[];Data.Civ1_Z=[];
            Data.Civ1_U=[];Data.Civ1_V=[];Data.Civ1_C=[];Data.Civ1_F=[];
            for ivol=1:NbSlice
                % caluclate velocity data (y and v in indices, reverse to y component)
                [xtable ytable utable vtable ctable F result_conv errormsg] = civ (par_civ1);
                if ~isempty(errormsg)
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
            [xtable ytable utable vtable ctable F result_conv errormsg] = civ (par_civ1);
            if ~isempty(errormsg)
                return
            end
            Data.Civ1_X=reshape(xtable,[],1);
            Data.Civ1_Y=reshape(par_civ1.ImageHeight-ytable+1,[],1);
            Data.Civ1_U=reshape(utable,[],1);
            Data.Civ1_V=reshape(-vtable,[],1);
            Data.Civ1_C=reshape(ctable,[],1);
            Data.Civ1_F=reshape(F,[],1);
        end
    else
        if exist('ncfile','var')
            CivFile=ncfile;
        elseif isfield(Param.Patch1,'CivFile')
            CivFile=Param.Patch1.CivFile;
        end
        Data=nc2struct(CivFile,'ListGlobalAttribute','absolut_time_T0'); %look for the constant 'absolut_time_T0' to detect old civx data format
        if isfield(Data,'Txt')
            errormsg=Data.Txt;
            return
        end
        if ~isempty(Data.absolut_time_T0')%read civx file
            check_civx=1;% test for old civx data format
            [Data,vardetect,ichoice]=nc2struct(CivFile);%read the variables in the netcdf file
        else
            Data=nc2struct(CivFile);%read civ1 and fix1 data in the existing netcdf file
        end
    end
    
    %% Fix1
    if isfield (Param.ActionInput,'Fix1')
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
        par_civ2.ImageA=[];
        par_civ2.ImageB=[];
        %         if ~isfield(Param.Civ1,'ImageA')
        ImageName_A_Civ2=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i1_series_Civ2(ifield),[],j1_series_Civ2(ifield));

        if strcmp(ImageName_A_Civ2,ImageName_A) && isequal(FrameIndex_A_Civ1(ifield),FrameIndex_A_Civ2)
            par_civ2.ImageA=par_civ1.ImageA;
        else
            [par_civ2.ImageA,MovieObject_A] = read_image(ImageName_A,FileType_A,MovieObject_A,FrameIndex_A_Civ2);
        end
        ImageName_B_Civ2=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i2_series_Civ2(ifield),[],j2_series_Civ2(ifield));
        if strcmp(ImageName_B_Civ2,ImageName_B) && isequal(FrameIndex_B_Civ1(ifield),FrameIndex_B_Civ2)
            par_civ2.ImageB=par_civ1.ImageB;
        else
            [par_civ2.ImageB,MovieObject_B] = read_image(ImageName_B,FileType_B,MovieObject_B,FrameIndex_B_Civ2);
        end     
        
        ncfile=fullfile_uvmat(RootPath,OutputDir,RootFile,'.nc',NomTypeNc,i1_series_Civ2(ifield),i2_series_Civ2(ifield),...
            j1_series_Civ2(ifield),j2_series_Civ2(ifield));
        par_civ2.ImageWidth=FileInfo.Width;
        par_civ2.ImageHeight=FileInfo.Height;
        
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
        for isub=1:NbSubDomain
            nbvec_sub=Data.Civ1_NbCentres(isub);
            ind_sel=find(GridX>=Data.Civ1_SubRange(1,1,isub) & GridX<=Data.Civ1_SubRange(1,2,isub) & GridY>=Data.Civ1_SubRange(2,1,isub) & GridY<=Data.Civ1_SubRange(2,2,isub));
            epoints = [GridX(ind_sel) GridY(ind_sel)];% coordinates of interpolation sites
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
        ibx2=ceil(par_civ2.CorrBoxSize(1)/2);
        iby2=ceil(par_civ2.CorrBoxSize(2)/2);
        par_civ2.SearchBoxSize(1)=2*ibx2+9;% search ara +-4 pixels around the guess
        par_civ2.SearchBoxSize(2)=2*iby2+9;
        par_civ2.SearchBoxShift=[Shiftx(nbval>=1)./nbval(nbval>=1) Shifty(nbval>=1)./nbval(nbval>=1)];
        par_civ2.Grid=[GridX(nbval>=1)-par_civ2.SearchBoxShift(:,1)/2 GridY(nbval>=1)-par_civ2.SearchBoxShift(:,2)/2];% grid taken at the extrapolated origin of the displacement vectors
        if par_civ2.CheckDeformation
            par_civ2.DUDX=DUDX./nbval;
            par_civ2.DUDY=DUDY./nbval;
            par_civ2.DVDX=DVDX./nbval;
            par_civ2.DVDY=DVDY./nbval;
        end
        % caluclate velocity data (y and v in indices, reverse to y component)
        [xtable ytable utable vtable ctable F] = civ (par_civ2);

        list_param=(fieldnames(Param.ActionInput.Civ2))';
        Civ2_param=regexprep(list_param,'^.+','Civ2_$0');% insert 'Civ2_' before  each string in list_param
        Civ2_param=[{'Civ2_ImageA','Civ2_ImageB','Civ2_Time','Civ2_Dt'} Civ2_param]; %insert the names of the two input images
        %indicate the values of all the global attributes in the output data 
        Data.Civ2_ImageA=ImageName_A;
        Data.Civ2_ImageB=ImageName_B;
        Data.Civ2_Time=1;
        Data.Civ2_Dt=1;
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
            Data.Civ2_FF=fix(Param.ActionInput.Fix2,Data.Civ2_F,Data.Civ2_C,Data.Civ2_U,Data.Civ2_V);
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
    
    %% write result in a netcdf file if requested
    if exist('ncfile','var')
        errormsg=struct2nc(ncfile,Data);
        if isempty(errormsg)
            disp([ncfile ' written'])
        else
            disp(errormsg)
        end
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
ibx2=ceil(par_civ.CorrBoxSize(1)/2);
iby2=ceil(par_civ.CorrBoxSize(2)/2);
isx2=ceil(par_civ.SearchBoxSize(1)/2);
isy2=ceil(par_civ.SearchBoxSize(2)/2);
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

% %% prepare images
% if isfield(par_civ,'reverse_pair')
%     if par_civ.reverse_pair
%         if ischar(par_civ.ImageB)
%             temp=par_civ.ImageA;
%             par_civ.ImageA=imread(par_civ.ImageB);
%         end
%         if ischar(temp)
%             par_civ.ImageB=imread(temp);
%         end
%     end
% else
%     if ischar(par_civ.ImageA)
%         par_civ.ImageA=imread(par_civ.ImageA);
%     end
%     if ischar(par_civ.ImageB)
%         par_civ.ImageB=imread(par_civ.ImageB);
%     end
% end
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
MinB=min(min(par_civ.ImageB));
if isfield(par_civ,'Mask') && ~isempty(par_civ.Mask)
   checkmask=1;
   if ~isequal(size(par_civ.Mask),[npy_ima npx_ima])
        errormsg='mask must be an image with the same size as the images';
        return
   end
  %  check_noflux=(par_civ.Mask<100) ;%TODO: to implement
    check_undefined=(par_civ.Mask<200 & par_civ.Mask>=20 );
    par_civ.ImageA(check_undefined)=MinA;% put image A to zero (i.e. the min image value) in the undefined  area
    par_civ.ImageB(check_undefined)=MinB;% put image B to zero (i.e. the min image value) in the undefined  area
end

%% compute image correlations: MAINLOOP on velocity vectors
corrmax=0;
sum_square=1;% default
mesh=1;% default
CheckDecimal=isfield(par_civ,'CheckDecimal')&& par_civ.CheckDecimal==1;
if CheckDecimal
    mesh=0.2;%mesh in pixels for subpixel image interpolation
    CheckDeformation=isfield(par_civ,'CheckDeformation')&& par_civ.CheckDeformation==1;
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
    check1_x=subrange1_x>=1 & subrange1_x<=par_civ.ImageWidth;% check which points in the subimage 1 are contained in the initial image 1
    check1_y=subrange1_y>=1 & subrange1_y<=par_civ.ImageHeight;
    check2_x=subrange2_x>=1 & subrange2_x<=par_civ.ImageWidth;% check which points in the subimage 2 are contained in the initial image 2
    check2_y=subrange2_y>=1 & subrange2_y<=par_civ.ImageHeight;
    
    image1_crop(check1_y,check1_x)=par_civ.ImageA(subrange1_y(check1_y),subrange1_x(check1_x));%extract a subimage (correlation box) from image A
    image2_crop(check2_y,check2_x)=par_civ.ImageB(subrange2_y(check2_y),subrange2_x(check2_x));%extract a larger subimage (search box) from image B
    image1_mean=mean(mean(image1_crop));
    image2_mean=mean(mean(image2_crop));
    %threshold on image minimum
    if check_MinIma && (image1_mean < par_civ.MinIma || image2_mean < par_civ.MinIma)
        F(ivec)=3;
    end
    %threshold on image maximum
    if check_MaxIma && (image1_mean > par_civ.MaxIma || image2_mean > par_civ.MaxIma)
        F(ivec)=3;
    end
    %         end
    if F(ivec)~=3
        image1_crop=image1_crop-image1_mean;%substract the mean
        image2_crop=image2_crop-image2_mean;
        if CheckDecimal
            xi=(1:mesh:size(image1_crop,2));
            yi=(1:mesh:size(image1_crop,1))';
            if CheckDeformation
                [XI,YI]=meshgrid(xi-ceil(size(image1_crop,2)/2),yi-ceil(size(image1_crop,1)/2));
                XIant=XI-par_civ.DUDX(ivec)*XI-par_civ.DUDY(ivec)*YI+ceil(size(image1_crop,2)/2);
                YIant=YI-par_civ.DVDX(ivec)*XI-par_civ.DVDY(ivec)*YI+ceil(size(image1_crop,1)/2);
                image1_crop=interp2(image1_crop,XIant,YIant);
            else
                image1_crop=interp2(image1_crop,xi,yi);
            end
            xi=(1:mesh:size(image2_crop,2));
            yi=(1:mesh:size(image2_crop,1))';
            image2_crop=interp2(image2_crop,xi,yi);
        end
        sum_square=sum(sum(image1_crop.*image1_crop));
        %reference: Oliver Pust, PIV: Direct Cross-Correlation
        result_conv= conv2(image2_crop,flipdim(flipdim(image1_crop,2),1),'valid');
        corrmax= max(max(result_conv));
        result_conv=(result_conv/corrmax)*255; %normalize, peak=always 255
        %Find the correlation max, at 255
        [y,x] = find(result_conv==255,1);
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

% if (x <= (size(result_conv,1)-1)) && (y <= (size(result_conv,1)-1)) && (x >= 1) && (y >= 1)
    %the following 8 lines are copyright (c) 1998, Uri Shavit, Roi Gurka, Alex Liberzon, Technion � Israel Institute of Technology
    %http://urapiv.wordpress.com
    peaky = y;
    if y <= npy-1 && y >= 1
        f0 = log(result_conv(y,x));
        f1 = real(log(result_conv(y-1,x)));
        f2 = real(log(result_conv(y+1,x)));
        peaky = peaky+ (f1-f2)/(2*f1-4*f0+2*f2);
    else
        F=-2; % warning flag for vector truncated by the limited search box
    end
    peakx=x;
    if x <= npx-1 && x >= 1
        f0 = log(result_conv(y,x));
        f1 = real(log(result_conv(y,x-1)));
        f2 = real(log(result_conv(y,x+1)));
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
[npy,npx]=size(result_conv);
if (x <= npx-1) && (y <= npy-1) && (x >= 1) && (y >= 1)
    F=0;
    for i=-1:1
        for j=-1:1
            %following 15 lines based on
            %H. Nobach � M. Honkanen (2005)
            %Two-dimensional Gaussian regression for sub-pixel displacement
            %estimation in particle image velocimetry or particle position
            %estimation in particle tracking velocimetry
            %Experiments in Fluids (2005) 38: 511�515
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
    find_pair_indices(str_civ,i_series,j_series,MinIndex,MaxIndex)
%------------------------------------------------------------------------
i1_series=i_series;% set of first image numbers
i2_series=i_series;
j1_series=ones(size(i_series));% set of first image numbers
j2_series=ones(size(i_series));
check_bounds=false(size(i_series));
r=regexp(str_civ,'^\D(?<ind>[i|j])= (?<num1>\d+)\|(?<num2>\d+)','names');
if ~isempty(r)
    mode=['D' r.ind];
    ind1=str2num(r.num1);
    ind2=str2num(r.num2);
else
    mode='burst';
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
if strcmp (mode,'Di')
    i1_series=i_series-ind1;% set of first image numbers
    i2_series=i_series+ind2;
    check_bounds=i1_series<MinIndex(1,1) | i2_series>MaxIndex(1,1);
    if isempty(j_series)
        NomTypeNc='_1-2';
    else
        j1_series=j_series;
        j2_series=j_series;
        NomTypeNc='_1-2_1';
    end
elseif strcmp (mode,'Dj')
    j1_series=j_series-ind1;
    j2_series=j_series+ind2;
    check_bounds=j1_series<MinIndex(1,2) | j2_series>MaxIndex(1,2);
    NomTypeNc='_1_1-2';
else  %bursts
    j1_series=ind1*ones(size(i_series));
    j2_series=ind2*ones(size(i_series));
end

%     if length(indsel)>=1
%         firstind=indsel(1);
%         lastind=indsel(end);
%         set(handles.first_j,'String',num2str(ref_j(firstind)))%update the display of first and last fields
%         set(handles.last_j,'String',num2str(ref_j(lastind)))
%         ref_j=ref_j(indsel);
%         j1_civ1=j1_civ1(indsel);
%         j2_civ1=j2_civ1(indsel);
%         j1_civ2=j1_civ2(indsel);
%         j2_civ2=j2_civ2(indsel);
%     end
% elseif isequal(mode,'pair j1-j2') %case of bursts (png_old or png_2D)
%     displ_num=get(handles.ListPairCiv1,'UserData');
%     i1_civ1=ref_i;
%     i2_civ1=ref_i;
%     j1_civ1=displ_num(1,index_civ1);
%     j2_civ1=displ_num(2,index_civ1);
%     i1_civ2=ref_i;
%     i2_civ2=ref_i;
%     j1_civ2=displ_num(1,index_civ2);
%     j2_civ2=displ_num(2,index_civ2);
% elseif isequal(mode,'displacement')
%     i1_civ1=ref_i;
%     i2_civ1=ref_i;
%     j1_civ1=ref_j;
%     j2_civ1=ref_j;
%     i1_civ2=ref_i;
%     i2_civ2=ref_i;
%     j1_civ2=ref_j;
%     j2_civ2=ref_j;
% end




