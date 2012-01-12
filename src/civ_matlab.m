%'civ_matlab': Matlab version of the PIV programs CivX
% --- call the sub-functions:
%   civ: PIV function itself
%   fix: removes false vectors after detection by various criteria
%   patch: make interpolation-smoothing 
%------------------------------------------------------------------------
% function [Data,errormsg,result_conv]= civ_uvmat(Param,ncfile)
%
%OUTPUT
% Data=structure containing the PIV results and information on the processing parameters
% errormsg=error message char string, default=''
% resul_conv: image inter-correlation function for the last grid point (used for tests)
%
%INPUT:
% Param: input images and processing parameters
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

function [Data,errormsg,result_conv]= civ_matlab(Param,ncfile)
errormsg='';
Data.ListGlobalAttribute={'Conventions','Program','CivStage'};
Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
Data.Program='civ_matlab';
Data.CivStage=0;%default
ListVarCiv1={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F'}; %variables to read
ListVarFix1={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F','Civ1_FF'};
mask='';
maskname='';%default
check_civx=0;%default
check_civ1=0;%default
check_patch1=0;%default

if ischar(Param)
    Param=xml2struct(Param);
end

%% Civ1
if isfield (Param,'Civ1')
    check_civ1=1;% test for further use of civ1 results
    % %% prepare images
    par_civ1=Param.Civ1;
    if isfield(par_civ1,'reverse_pair')
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
        if ischar(par_civ1.ImageA)
            par_civ1.ImageA=imread(par_civ1.ImageA);
        end
        if ischar(par_civ1.ImageB)
            par_civ1.ImageB=imread(par_civ1.ImageB);
        end
    end
    
    % caluclate velocity data (y and v in indices, reverse to y component)
    [xtable ytable utable vtable ctable F result_conv errormsg] = civ (par_civ1);
    
    % to try the reverse_pair method, uncomment below
    %     [xtable1 ytable1 utable1 vtable1 ctable1 F1 result_conv1 errormsg1] = civ (Param.Civ1);
    %     Param.Civ1.reverse_pair=1;
    %     [xtable2 ytable2 utable2 vtable2 ctable2 F2 result_conv2 errormsg2] = civ (Param.Civ1);
    %     xtable=[xtable1; xtable2];
    %     ytable=[ytable1; ytable2];
    %     utable=[utable1; -utable2];
    %     vtable=[vtable1; -vtable2];
    %     ctable=[ctable1; ctable2];
    %     F=[F1; F2];
    %     result_conv=[result_conv1; result_conv2];
    %     errormsg=[errormsg1; errormsg2];
    if ~isempty(errormsg)
        return
    end
    list_param=(fieldnames(Param.Civ1))';
    Civ1_param=list_param;%default
    for ilist=1:length(list_param)
        Civ1_param{ilist}=['Civ1_' list_param{ilist}];
        Data.(['Civ1_' list_param{ilist}])=Param.Civ1.(list_param{ilist});
    end
    Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ1_param];% {'Civ1_Time','Civ1_Dt'}];
    Data.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_F','Civ1_C'};%  cell array containing the names of the fields to record
    Data.VarDimName={'NbVec1','NbVec1','NbVec1','NbVec1','NbVec1','NbVec1'};
    Data.VarAttribute{1}.Role='coord_x';
    Data.VarAttribute{2}.Role='coord_y';
    Data.VarAttribute{3}.Role='vector_x';
    Data.VarAttribute{4}.Role='vector_y';
    Data.VarAttribute{5}.Role='warnflag';
    Data.Civ1_X=reshape(xtable,[],1);
    Data.Civ1_Y=reshape(Param.Civ1.ImageHeight-ytable+1,[],1);
    Data.Civ1_U=reshape(utable,[],1);
    Data.Civ1_V=reshape(-vtable,[],1);
    Data.Civ1_C=reshape(ctable,[],1);
    Data.Civ1_F=reshape(F,[],1);
    Data.CivStage=1;  
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
if isfield (Param,'Fix1')
    ListFixParam=fieldnames(Param.Fix1);
    for ilist=1:length(ListFixParam)
        ParamName=ListFixParam{ilist};
        ListName=['Fix1_' ParamName];
        eval(['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];'])
        eval(['Data.' ListName '=Param.Fix1.' ParamName ';'])
    end
    if check_civx
        if ~isfield(Data,'fix')
            Data.ListGlobalAttribute=[Data.ListGlobalAttribute 'fix'];
            Data.fix=1;
            Data.ListVarName=[Data.ListVarName {'vec_FixFlag'}];
            Data.VarDimName=[Data.VarDimName {'nb_vectors'}];
        end
        Data.vec_FixFlag=fix(Param.Fix1,Data.vec_F,Data.vec_C,Data.vec_U,Data.vec_V,Data.vec_X,Data.vec_Y);
    else
        Data.ListVarName=[Data.ListVarName {'Civ1_FF'}];
        Data.VarDimName=[Data.VarDimName {'NbVec1'}];
        nbvar=length(Data.ListVarName);
        Data.VarAttribute{nbvar}.Role='errorflag';    
        Data.Civ1_FF=fix(Param.Fix1,Data.Civ1_F,Data.Civ1_C,Data.Civ1_U,Data.Civ1_V);
        Data.CivStage=2;    
    end
end   
%% Patch1
if isfield (Param,'Patch1')
    if check_civx
        errormsg='Civ Matlab input needed for patch';
        return
    end
    check_patch1=1;
    Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch1_Rho','Patch1_Threshold','Patch1_SubDomain'}];
    Data.Patch1_Rho=Param.Patch1.SmoothingParam;
    Data.Patch1_Threshold=Param.Patch1.MaxDiff;
    Data.Patch1_SubDomain=Param.Patch1.SubdomainSize;
    Data.ListVarName=[Data.ListVarName {'Civ1_U_Diff','Civ1_V_Diff','Civ1_X_SubRange','Civ1_Y_SubRange','Civ1_NbSites','Civ1_X_tps','Civ1_Y_tps','Civ1_U_tps','Civ1_V_tps'}];
    Data.VarDimName=[Data.VarDimName {'NbVec1','NbVec1',{'NbSubDomain1','Two'},{'NbSubDomain1','Two'},'NbSubDomain1',...
             {'NbVec1Sub','NbSubDomain1'},{'NbVec1Sub','NbSubDomain1'},{'Nbtps1','NbSubDomain1'},{'Nbtps1','NbSubDomain1'}}];
    nbvar=length(Data.ListVarName);
    Data.VarAttribute{nbvar-1}.Role='vector_x';
    Data.VarAttribute{nbvar}.Role='vector_y';
    Data.Civ1_U_Diff=zeros(size(Data.Civ1_X));
    Data.Civ1_V_Diff=zeros(size(Data.Civ1_X));
    if isfield(Data,'Civ1_FF')
        ind_good=find(Data.Civ1_FF==0);
    else 
        ind_good=1:numel(Data.Civ1_X);
    end
    [Data.Civ1_X_SubRange,Data.Civ1_Y_SubRange,Data.Civ1_NbSites,FFres,Ures, Vres,Data.Civ1_X_tps,Data.Civ1_Y_tps,Data.Civ1_U_tps,Data.Civ1_V_tps]=...
                            patch(Data.Civ1_X(ind_good)',Data.Civ1_Y(ind_good)',Data.Civ1_U(ind_good)',Data.Civ1_V(ind_good)',Data.Patch1_Rho,Data.Patch1_Threshold,Data.Patch1_SubDomain); 
      Data.Civ1_U_Diff(ind_good)=Data.Civ1_U(ind_good)-Ures;
      Data.Civ1_V_Diff(ind_good)=Data.Civ1_V(ind_good)-Vres;
      Data.Civ1_FF(ind_good)=FFres;
      Data.CivStage=3;                             
end   

%% Civ2
if isfield (Param,'Civ2')
    par_civ2=Param.Civ2;
    if ~isfield (Param,'Civ1') || ~strcmp(Param.Civ1.ImageA,par_civ2.ImageA)
        par_civ2.ImageA=imread(Param.Civ2.ImageA);%read first image if not already done for civ1
    else
        par_civ2.ImageA=par_civ1.ImageA;
    end
    if ~isfield (Param,'Civ1') || ~strcmp(Param.Civ1.ImageB,par_civ2.ImageB)
        par_civ2.ImageB=imread(Param.Civ2.ImageB);%read second image if not already done for civ1
         else
        par_civ2.ImageB=par_civ1.ImageB;
    end
    ibx2=ceil(par_civ2.Bx/2);
    iby2=ceil(par_civ2.By/2);
    isx2=ibx2+5;% search ara +-5 pixels around the guess
    isy2=iby2+5;
    % shift from par_civ2.filename_nc1
    % shiftx=velocity interpolated at position
    miniy=max(1+isy2,1+iby2);
    minix=max(1+isx2,1+ibx2);
    maxiy=min(size(par_civ2.ImageA,1)-isy2,size(par_civ2.ImageA,1)-iby2);
    maxix=min(size(par_civ2.ImageA,2)-isx2,size(par_civ2.ImageA,2)-ibx2);
    [GridX,GridY]=meshgrid(minix:par_civ2.Dx:maxix,miniy:par_civ2.Dy:maxiy);
    GridX=reshape(GridX,[],1);
    GridY=reshape(GridY,[],1);
    Shiftx=zeros(size(GridX));% shift expected from civ1 data
    Shifty=zeros(size(GridX));
    nbval=zeros(size(GridX));
    if par_civ2.CheckDeformation
        DUDX=zeros(size(GridX));
        DUDY=zeros(size(GridX));
        DVDX=zeros(size(GridX));
        DVDY=zeros(size(GridX));
    end
    [NbSubDomain,xx]=size(Data.Civ1_X_SubRange);
    % get the guess from patch1
    for isub=1:NbSubDomain
        nbvec_sub=Data.Civ1_NbSites(isub);
        ind_sel=find(GridX>=Data.Civ1_X_SubRange(isub,1) & GridX<=Data.Civ1_X_SubRange(isub,2) & GridY>=Data.Civ1_Y_SubRange(isub,1) & GridY<=Data.Civ1_Y_SubRange(isub,2));
        epoints = [GridX(ind_sel) GridY(ind_sel)];% coordinates of interpolation sites
        ctrs=[Data.Civ1_X_tps(1:nbvec_sub,isub) Data.Civ1_Y_tps(1:nbvec_sub,isub)];%(=initial points) ctrs
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
    if par_civ2.CheckMask&&~isempty(par_civ2.maskname)&& ~strcmp(maskname,par_civ2.maskname)% mask exist, not already read in civ1
        mask=imread(par_civ2.maskname);
    end
    par_civ2.Searchx=2*isx2+1;
    par_civ2.Searchy=2*isy2+1;
    par_civ2.Shiftx=Shiftx(nbval>=1)./nbval(nbval>=1);
    par_civ2.Shifty=Shifty(nbval>=1)./nbval(nbval>=1);
    par_civ2.Grid=[GridX(nbval>=1)-par_civ2.Shiftx/2 GridY(nbval>=1)-par_civ2.Shifty/2];% grid taken at the extrapolated origin of the displacement vectors   
    if par_civ2.CheckDeformation
        DUDX=DUDX./nbval;
        DUDY=DUDY./nbval;
        DVDX=DVDX./nbval;
        DVDY=DVDY./nbval;
    end
    % caluclate velocity data (y and v in indices, reverse to y component)
    [xtable ytable utable vtable ctable F] = civ (par_civ2);
%     diff_squared=(utable-par_civ2.Shiftx).*(utable-par_civ2.Shiftx)+(vtable+par_civ2.Shifty).*(vtable+par_civ2.Shifty);
%     F(diff_squared>=4)=4; %flag vectors whose distance to the guess exceeds 2 pixels
    list_param=(fieldnames(Param.Civ2))';
    list_remove={'pxcmx','pxcmy','npx','npy','gridflag','maskflag','term_a','term_b','T0'};
    for ilist=1:length(list_remove)
        index=strcmp(list_remove{ilist},list_param);
        if ~isempty(find(index,1))
            list_param(index)=[];
        end
    end
    for ilist=1:length(list_param)
        Civ2_param{ilist}=['Civ2_' list_param{ilist}];
        eval(['Data.Civ2_' list_param{ilist} '=Param.Civ2.' list_param{ilist} ';'])
    end
    if isfield(Data,'Civ2_gridname') && strcmp(Data.Civ1_gridname(1:6),'noFile')
        Data.Civ1_gridname='';
    end
    if isfield(Data,'Civ2_maskname') && strcmp(Data.Civ1_maskname(1:6),'noFile')
        Data.Civ2_maskname='';
    end
    Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ2_param {'Civ2_Time','Civ2_Dt'}];
    Data.Civ2_Time=str2double(par_civ2.Time);
    Data.Civ2_Dt=str2double(par_civ2.Dt);
    nbvar=numel(Data.ListVarName);
    Data.ListVarName=[Data.ListVarName {'Civ2_X','Civ2_Y','Civ2_U','Civ2_V','Civ2_F','Civ2_C'}];%  cell array containing the names of the fields to record
    Data.VarDimName=[Data.VarDimName {'NbVec2','NbVec2','NbVec2','NbVec2','NbVec2','NbVec2'}];
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
if isfield (Param,'Fix2')
    ListFixParam=fieldnames(Param.Fix2);
    for ilist=1:length(ListFixParam)
        ParamName=ListFixParam{ilist};
        ListName=['Fix2_' ParamName];
        eval(['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];'])
        eval(['Data.' ListName '=Param.Fix2.' ParamName ';'])
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
        Data.VarDimName=[Data.VarDimName {'nbvec2'}];
        nbvar=length(Data.ListVarName);
        Data.VarAttribute{nbvar}.Role='errorflag';    
        Data.Civ2_FF=fix(Param.Fix2,Data.Civ2_F,Data.Civ2_C,Data.Civ2_U,Data.Civ2_V);
        Data.CivStage=Data.CivStage+1;    
    end
    
end   

%% Patch2
if isfield (Param,'Patch2')
    Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch2_Rho','Patch2_Threshold','Patch2_SubDomain'}];
    Data.Patch2_Rho=Param.Patch2.SmoothingParam;
    Data.Patch2_Threshold=Param.Patch2.MaxDiff;
    Data.Patch2_SubDomain=Param.Patch2.SubdomainSize;
    Data.ListVarName=[Data.ListVarName {'Civ2_U_Diff','Civ2_V_Diff','Civ2_X_SubRange','Civ2_Y_SubRange','Civ2_NbSites','Civ2_X_tps','Civ2_Y_tps','Civ2_U_tps','Civ2_V_tps'}];
    Data.VarDimName=[Data.VarDimName {'NbVec2','NbVec2',{'NbSubDomain2','Two'},{'NbSubDomain2','Two'},'NbSubDomain2',...
             {'NbVec2Sub','NbSubDomain2'},{'NbVec2Sub','NbSubDomain2'},{'Nbtps2','NbSubDomain2'},{'Nbtps2','NbSubDomain2'}}];
    nbvar=length(Data.ListVarName);
    Data.VarAttribute{nbvar-1}.Role='vector_x';
    Data.VarAttribute{nbvar}.Role='vector_y';
    Data.Civ2_U_Diff=zeros(size(Data.Civ2_X));
    Data.Civ2_V_Diff=zeros(size(Data.Civ2_X));
    if isfield(Data,'Civ2_FF')
        ind_good=find(Data.Civ2_FF==0);
    else
        ind_good=1:numel(Data.Civ2_X);
    end
    [Data.Civ2_X_SubRange,Data.Civ2_Y_SubRange,Data.Civ2_NbSites,FFres,Ures, Vres,Data.Civ2_X_tps,Data.Civ2_Y_tps,Data.Civ2_U_tps,Data.Civ2_V_tps]=...
                            patch(Data.Civ2_X(ind_good)',Data.Civ2_Y(ind_good)',Data.Civ2_U(ind_good)',Data.Civ2_V(ind_good)',Data.Patch2_Rho,Data.Patch2_Threshold,Data.Patch2_SubDomain); 
      Data.Civ2_U_Diff(ind_good)=Data.Civ2_U(ind_good)-Ures;
      Data.Civ2_V_Diff(ind_good)=Data.Civ2_V(ind_good)-Vres;
      Data.Civ2_FF(ind_good)=FFres;
      Data.CivStage=Data.CivStage+1;                             
end  

%% write result in a netcdf file if requested
if exist('ncfile','var') 
    errormsg=struct2nc(ncfile,Data);
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
% image1:first image (matrix)
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

%% prepare grid
ibx2=ceil(par_civ.Bx/2);
iby2=ceil(par_civ.By/2);
isx2=ceil(par_civ.Searchx/2);
isy2=ceil(par_civ.Searchy/2);
shiftx=round(par_civ.Shiftx);
shifty=-round(par_civ.Shifty);% sign minus because image j index increases when y decreases
if isfield(par_civ,'Grid')
    if ischar(par_civ.Grid)%read the drid file if the input is a file name
        par_civ.Grid=dlmread(par_civ.Grid);
        par_civ.Grid(1,:)=[];%the first line must be removed (heading in the grid file)
    end
else% automatic measurement grid
    ibx2=ceil(par_civ.Bx/2);
    iby2=ceil(par_civ.By/2);
    isx2=ceil(par_civ.Searchx/2);
    isy2=ceil(par_civ.Searchy/2);
    miniy=max(1+isy2+shifty,1+iby2);
    minix=max(1+isx2-shiftx,1+ibx2);
    maxiy=min(par_civ.ImageHeight-isy2+shifty,par_civ.ImageHeight-iby2);
    maxix=min(par_civ.ImageWidth-isx2-shiftx,par_civ.ImageWidth-ibx2);
    [GridX,GridY]=meshgrid(minix:par_civ.Dx:maxix,miniy:par_civ.Dy:maxiy);
    par_civ.Grid(:,1)=reshape(GridX,[],1);
    par_civ.Grid(:,2)=reshape(GridY,[],1);
end
nbvec=size(par_civ.Grid,1);
if numel(shiftx)==1
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

[npy_ima npx_ima]=size(par_civ.ImageA);
if ~isequal(size(par_civ.ImageB),[npy_ima npx_ima])
    errormsg='image pair with unequal size';
    return
end
par_civ.ImageA=double(par_civ.ImageA);
par_civ.ImageB=double(par_civ.ImageB);


%% Apply mask
    % Convention for mask
    % mask >200 : velocity calculated
    %  200 >=mask>150;velocity not calculated, interpolation allowed (bad spots)
    % 150>=mask >100: velocity not calculated, nor interpolated
    %  100>=mask> 20: velocity not calculated, impermeable (no flux through mask boundaries) TO IMPLEMENT
    %  20>=mask: velocity=0
checkmask=0;
if isfield(par_civ,'Mask') && ~isempty(par_civ.Mask)
   checkmask=1;
   if ~isequal(size(par_civ.Mask),[npy_ima npx_ima])
        errormsg='mask must be an image with the same size as the images';
        return
   end
  %  check_noflux=(par_civ.Mask<100) ;%TODO: to implement
    check_undefined=(par_civ.Mask<200 & par_civ.Mask>=100 );
    par_civ.ImageA(check_undefined)=min(min(par_civ.ImageA));% put image A to zero (i.e. the min image value) in the undefined  area
    par_civ.ImageB(check_undefined)=min(min(par_civ.ImageB));% put image B to zero (i.e. the min image value) in the undefined  area
end

%% compute image correlations: MAINLOOP on velocity vectors
corrmax=0;
sum_square=1;% default
mesh=1;% default
CheckDecimal=isfield(par_civ,'CheckDecimal')&& par_civ.CheckDecimal==1;
if CheckDecimal
    mesh=0.2;%mesh in pixels for subpixel image interpolation
end
% vector=[0 0];%default
for ivec=1:nbvec
    iref=par_civ.Grid(ivec,1);% xindex on the image A for the middle of the correlation box
    jref=par_civ.Grid(ivec,2);% yindex on the image B for the middle of the correlation box
    if ~(checkmask && par_civ.Mask(jref,iref)<=20) %velocity not set to zero by the black mask
        if jref-iby2<1 || jref+iby2>par_civ.ImageHeight|| iref-ibx2<1 || iref+ibx2>par_civ.ImageWidth||...
              jref+shifty(ivec)-isy2<1||jref+shifty(ivec)+isy2>par_civ.ImageHeight|| iref+shiftx(ivec)-isx2<1 || iref+shiftx(ivec)+isx2>par_civ.ImageWidth  % we are outside the image
            F(ivec)=3;
        else
            image1_crop=par_civ.ImageA(jref-iby2:jref+iby2,iref-ibx2:iref+ibx2);%extract a subimage (correlation box) from image A
            image2_crop=par_civ.ImageB(jref+shifty(ivec)-isy2:jref+shifty(ivec)+isy2,iref+shiftx(ivec)-isx2:iref+shiftx(ivec)+isx2);%extract a larger subimage (search box) from image B
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
        end      
        if F(ivec)~=3
            image1_crop=image1_crop-image1_mean;%substract the mean
            image2_crop=image2_crop-image2_mean;
            if isfield(par_civ,'CheckDecimal')&& par_civ.CheckDecimal==1
                xi=(1:mesh:size(image1_crop,2));
                yi=(1:mesh:size(image1_crop,1))';
                image1_crop=interp2(image1_crop,xi,yi);
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
                    if par_civ.Rho==1
                        [vector,F(ivec)] = SUBPIXGAUSS (result_conv,x,y);
                    elseif par_civ.Rho==2
                        [vector,F(ivec)] = SUBPIX2DGAUSS (result_conv,x,y);
                    end
                    utable(ivec)=vector(1)*mesh+shiftx(ivec);
                    vtable(ivec)=vector(2)*mesh+shifty(ivec);                 
                    xtable(ivec)=iref+utable(ivec)/2;% convec flow (velocity taken at the point middle from imgae1 and 2)
                    ytable(ivec)=jref+vtable(ivec)/2;
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
    
    %Create the vector matrix x, y, u, v
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
% patch function
% OUTPUT:
% SubRangx,SubRangy(NbSubdomain,2): range (min, max) of the coordiantes x and y respectively, for each subdomain
% nbpoints(NbSubdomain): number of source points for each subdomain
% FF: false flags
% U_smooth, V_smooth: filtered velocity components at the positions of the initial data
% X_tps,Y_tps,U_tps,V_tps: positions and weight of the tps for each subdomain
%
% INPUT:
% X, Y: set of coordinates of the initial data
% U,V: set of velocity components of the initial data
% Rho: smoothing parameter
% Threshold: max diff accepted between smoothed and initial data 
% Subdomain: estimated number of data points in each subdomain

function [SubRangx,SubRangy,nbpoints,FF,U_smooth,V_smooth,X_tps,Y_tps,U_tps,V_tps] =patch(X,Y,U,V,Rho,Threshold,SubDomain)
%subdomain decomposition
warning off
U=reshape(U,[],1);
V=reshape(V,[],1);
X=reshape(X,[],1);
Y=reshape(Y,[],1);
nbvec=numel(X);
NbSubDomain=ceil(nbvec/SubDomain);
MinX=min(X);
MinY=min(Y);
MaxX=max(X);
MaxY=max(Y);
RangX=MaxX-MinX;
RangY=MaxY-MinY;
AspectRatio=RangY/RangX;
NbSubDomainX=max(floor(sqrt(NbSubDomain/AspectRatio)),1);
NbSubDomainY=max(floor(sqrt(NbSubDomain*AspectRatio)),1);
NbSubDomain=NbSubDomainX*NbSubDomainY;
SizX=RangX/NbSubDomainX;%width of subdomains
SizY=RangY/NbSubDomainY;%height of subdomains
CentreX=linspace(MinX+SizX/2,MaxX-SizX/2,NbSubDomainX);
CentreY=linspace(MinY+SizY/2,MaxY-SizY/2,NbSubDomainY);
[CentreX,CentreY]=meshgrid(CentreX,CentreY);
CentreY=reshape(CentreY,1,[]);% Y positions of subdomain centres
CentreX=reshape(CentreX,1,[]);% X positions of subdomain centres
rho=SizX*SizY*Rho/1000000;%optimum rho increase as the area of the subdomain (division by 10^6 to reach good values with the default GUI input)
U_tps_sub=zeros(length(X),NbSubDomain);%default spline
V_tps_sub=zeros(length(X),NbSubDomain);%default spline
U_smooth=zeros(length(X),1);
V_smooth=zeros(length(X),1);

nb_select=zeros(length(X),1);
FF=zeros(length(X),1);
check_empty=zeros(1,NbSubDomain);
SubRangx=zeros(NbSubDomain,2);%initialise the positions of subdomains
SubRangy=zeros(NbSubDomain,2);
for isub=1:NbSubDomain
    SubRangx(isub,:)=[CentreX(isub)-0.55*SizX CentreX(isub)+0.55*SizX];
    SubRangy(isub,:)=[CentreY(isub)-0.55*SizY CentreY(isub)+0.55*SizY];
    ind_sel_previous=[];
    ind_sel=0;
    while numel(ind_sel)>numel(ind_sel_previous) %increase the subdomain during four iterations at most
        ind_sel_previous=ind_sel;
        ind_sel=find(X>=SubRangx(isub,1) & X<=SubRangx(isub,2) & Y>=SubRangy(isub,1) & Y<=SubRangy(isub,2));
        % if no vector in the subdomain, skip the subdomain
        if isempty(ind_sel)
            check_empty(isub)=1;    
            U_tps(1,isub)=0;%define U_tps and V_tps by default
            V_tps(1,isub)=0;
            break
            % if too few selected vectors, increase the subrange for next iteration
        elseif numel(ind_sel)<SubDomain/4 && ~isequal( ind_sel,ind_sel_previous);
            SubRangx(isub,1)=SubRangx(isub,1)-SizX/4;
            SubRangx(isub,2)=SubRangx(isub,2)+SizX/4;
            SubRangy(isub,1)=SubRangy(isub,1)-SizY/4;
            SubRangy(isub,2)=SubRangy(isub,2)+SizY/4;
        else
            
            [U_smooth_sub,U_tps_sub]=tps_coeff([X(ind_sel) Y(ind_sel)],U(ind_sel),rho);
            [V_smooth_sub,V_tps_sub]=tps_coeff([X(ind_sel) Y(ind_sel)],V(ind_sel),rho);
            UDiff=U_smooth_sub-U(ind_sel);
            VDiff=V_smooth_sub-V(ind_sel);
            NormDiff=UDiff.*UDiff+VDiff.*VDiff;
            FF(ind_sel)=20*(NormDiff>Threshold);%put FF value to 20 to identify the criterium of elimmination
            ind_ind_sel=find(FF(ind_sel)==0); % select the indices of ind_sel corresponding to the remaining vectors
            % no value exceeds threshold, the result is recorded
            if isequal(numel(ind_ind_sel),numel(ind_sel))
                U_smooth(ind_sel)=U_smooth(ind_sel)+U_smooth_sub;
                V_smooth(ind_sel)=V_smooth(ind_sel)+V_smooth_sub;
                nbpoints(isub)=numel(ind_sel);
                X_tps(1:nbpoints(isub),isub)=X(ind_sel);
                Y_tps(1:nbpoints(isub),isub)=Y(ind_sel);
                U_tps(1:nbpoints(isub)+3,isub)=U_tps_sub;
                V_tps(1:nbpoints(isub)+3,isub)=V_tps_sub;         
                nb_select(ind_sel)=nb_select(ind_sel)+1;
                 display('good')
                break
                % too few selected vectors, increase the subrange for next iteration
            elseif numel(ind_ind_sel)<SubDomain/4 && ~isequal( ind_sel,ind_sel_previous);
                SubRangx(isub,1)=SubRangx(isub,1)-SizX/4;
                SubRangx(isub,2)=SubRangx(isub,2)+SizX/4;
                SubRangy(isub,1)=SubRangy(isub,1)-SizY/4;
                SubRangy(isub,2)=SubRangy(isub,2)+SizY/4;
%                 display('fewsmooth')
                % interpolation-smoothing is done again with the selected vectors
            else
                [U_smooth_sub,U_tps_sub]=tps_coeff([X(ind_sel(ind_ind_sel)) Y(ind_sel(ind_ind_sel))],U(ind_sel(ind_ind_sel)),rho);
                [V_smooth_sub,V_tps_sub]=tps_coeff([X(ind_sel(ind_ind_sel)) Y(ind_sel(ind_ind_sel))],V(ind_sel(ind_ind_sel)),rho);
                U_smooth(ind_sel(ind_ind_sel))=U_smooth(ind_sel(ind_ind_sel))+U_smooth_sub;
                V_smooth(ind_sel(ind_ind_sel))=V_smooth(ind_sel(ind_ind_sel))+V_smooth_sub;
                nbpoints(isub)=numel(ind_ind_sel);
                X_tps(1:nbpoints(isub),isub)=X(ind_sel(ind_ind_sel));
                Y_tps(1:nbpoints(isub),isub)=Y(ind_sel(ind_ind_sel));
                U_tps(1:nbpoints(isub)+3,isub)=U_tps_sub;
                V_tps(1:nbpoints(isub)+3,isub)=V_tps_sub;
                nb_select(ind_sel(ind_ind_sel))=nb_select(ind_sel(ind_ind_sel))+1;
                display('good2')
                break
            end
        end
    end
end
ind_empty=find(check_empty);
%remove empty subdomains
if ~isempty(ind_empty)
    SubRangx(ind_empty,:)=[];
    SubRangy(ind_empty,:)=[];
    X_tps(:,ind_empty)=[];
    Y_tps(:,ind_empty)=[];
    U_tps(:,ind_empty)=[];
    V_tps(:,ind_empty)=[];
end
nb_select(nb_select==0)=1;%ones(size(find(nb_select==0)));
U_smooth=U_smooth./nb_select;
V_smooth=V_smooth./nb_select;





