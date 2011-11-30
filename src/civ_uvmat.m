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

function [Data,errormsg,result_conv]= civ_uvmat(Param,ncfile)
errormsg='';
Data.ListGlobalAttribute={'Conventions','Program','CivStage'};
Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
Data.Program='civ_uvmat';
Data.CivStage=0;%default
ListVarCiv1={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F'}; %variables to read
ListVarFix1={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F','Civ1_FF'};
mask='';
maskname='';%default
test_civx=0;%default
test_civ1=0;%default
test_patch1=0;%default

%% Civ1
if isfield (Param,'Civ1')
    test_civ1=1;% test for further use of civ1 results
    par_civ1=Param.Civ1;
    image1=imread(par_civ1.filename_ima_a);
    image2=imread(par_civ1.filename_ima_b);
    ibx2=ceil(par_civ1.Bx/2);
    iby2=ceil(par_civ1.By/2);
    isx2=ceil(par_civ1.Searchx/2);
    isy2=ceil(par_civ1.Searchy/2);
    shiftx=par_civ1.Shiftx;
    shifty=par_civ1.Shifty;
    miniy=max(1+isy2+shifty,1+iby2);
    minix=max(1+isx2-shiftx,1+ibx2);
    maxiy=min(size(image1,1)-isy2+shifty,size(image1,1)-iby2);
    maxix=min(size(image1,2)-isx2-shiftx,size(image1,2)-ibx2);
    if ~isfield(par_civ1,'PointCoord')    
        [GridX,GridY]=meshgrid(minix:par_civ1.Dx:maxix,miniy:par_civ1.Dy:maxiy);
        par_civ1.PointCoord(:,1)=reshape(GridX,[],1);
        par_civ1.PointCoord(:,2)=reshape(GridY,[],1);
    end
    if par_civ1.CheckMask && isfield(par_civ1,'MaskName') && ~isempty(par_civ1.MaskName) 
        maskname=par_civ1.MaskName;
        mask=imread(maskname);
    end
    % caluclate velocity data (y and v in indices, reverse to y component)
    [xtable ytable utable vtable ctable F result_conv errormsg] = civ (image1,image2,ibx2,iby2,isx2,isy2,shiftx,-shifty,par_civ1.PointCoord,par_civ1.Rho, mask);
    list_param=(fieldnames(par_civ1))';
    list_remove={'pxcmx','pxcmy','npx','npy','gridflag','maskflag','term_a','term_b','T0'};
    index_remove=zeros(size(list_param));
    for name=list_remove %loop on the list of names
        index_remove=index_remove +strcmp(name{1},list_param);%index of the current name = name{1} 
    end
    list_param(find(index_remove,1))=[];
    Civ1_param=list_param;%initialisation
    for ilist=1:length(list_param)
        Civ1_param{ilist}=['Civ1_' list_param{ilist}];
        Data.(['Civ1_' list_param{ilist}])=par_civ1.(list_param{ilist});
    end
    if isfield(Data,'Civ1_gridname') && strcmp(Data.Civ1_gridname(1:6),'noFile')
        Data.Civ1_gridname='';
    end
    if isfield(Data,'Civ1_maskname') && strcmp(Data.Civ1_maskname(1:6),'noFile')
        Data.Civ1_maskname='';
    end
    Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ1_param {'Civ1_Time','Civ1_Dt'}];
    Data.Civ1_Time=str2double(par_civ1.T0);
    Data.Civ1_Dt=str2double(par_civ1.Dt);
    Data.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F'};%  cell array containing the names of the fields to record
    Data.VarDimName={'nbvec1','nbvec1','nbvec1','nbvec1','nbvec1','nbvec1'};
    Data.VarAttribute{1}.Role='coord_x';
    Data.VarAttribute{2}.Role='coord_y';
    Data.VarAttribute{3}.Role='vector_x';
    Data.VarAttribute{4}.Role='vector_y';
    Data.VarAttribute{5}.Role='warnflag';
    Data.Civ1_X=reshape(xtable,[],1);
    Data.Civ1_Y=reshape(size(image1,1)-ytable+1,[],1);
    Data.Civ1_U=reshape(utable,[],1);
    Data.Civ1_V=reshape(-vtable,[],1);
    Data.Civ1_C=reshape(ctable,[],1);
    Data.Civ1_F=reshape(F,[],1);
    Data.CivStage=1;
else
    Data=nc2struct(ncfile,'ListGlobalAttribute','absolut_time_T0'); %look for the constant 'absolut_time_T0' to detect old civx data format 
    if ~isempty(Data.absolut_time_T0')%read civx file
        test_civx=1;% test for old civx data format
        [Data,vardetect,ichoice]=nc2struct(ncfile);%read the variables in the netcdf file
    else
        if isfield(Param,'Fix1')
            Data=nc2struct(ncfile,ListVarCiv1);%read civ1 data in the existing netcdf file
        else
            Data=nc2struct(ncfile,ListVarFix1);%read civ1 and fix1 data in the existing netcdf file
        end
    end
    if isfield(Data,'Txt')
        msgbox_uvmat('ERROR',Data.Txt)
        return
    end
end

%% Fix1
%                 if Param.CheckCiv1==1
%                     Param.Civ1=Param.Civ1;
%                 end
%                 if Param.CheckFix1==1
%                     Param.Fix1=Param.Fix1;
%                     fix1.WarnFlags=[];
%                     if get(handles.CheckFmin2,'Value')
%                         fix1.WarnFlags=[fix1.WarnFlags -2];
%                     end
%                     if get(handles.CheckF3,'Value')
%                         fix1.WarnFlags=[fix1.WarnFlags 3];
%                     end
%                     fix1.LowerBoundCorr=thresh_vecC1;
%                     if get(handles.num_MinVel,'Value')
%                         fix1.UppperBoundVel=thresh_vel1;
%                     else
%                         fix1.LowerBoundVel=thresh_vel1;
%                     end
%                     if get(handles.CheckMask,'Value')
%                         fix1.MaskName=maskname;
%                     end
%                     Param.Fix1=fix1;
%                 end
%                 if Param.CheckPatch1==1
%                     if strcmp(compare,'stereo PIV')
%                         filebase_A=filecell.filebase;
%                         [pp,ff]=fileparts(filebase_A);
%                         filebase_B=fullfile(pp,get(handles.RootName_1,'String'));
%                         %TO CHECK: filecell.nc.civ1{ifile,j},filecell.ncA.civ1{ifile,j} have been switched according to Matias Duran
%                         RUN_STLIN(filecell.nc.civ1{ifile,j},filecell.ncA.civ1{ifile,j},'civ1',filecell.st{ifile,j},...
%                             str2num(nx_patch1),str2num(ny_patch1),str2num(thresh_patch1),[filebase_A '.xml'],[filebase_B '.xml'])
%                     else
%                         Param.Patch1.Rho=rho_patch1;
%                         Param.Patch1.Threshold=thresh_patch1;
%                         Param.Patch1.SubDomain=subdomain_patch1;
%                     end
%                 end
%                 if Param.CheckCiv2==1
%                     Param.Civ2=Param.Civ2;
%                 end
%                 if Param.CheckFix2==1
%                     fix2.WarnFlags=[];
%                     if get(handles.CheckFmin2,'Value')
%                         fix2.WarnFlags=[fix2.WarnFlags -2];
%                     end
%                     if get(handles.CheckF4,'Value')
%                         fix2.WarnFlags=[fix2.WarnFlags 4];
%                     end
%                     if get(handles.CheckF3,'Value')
%                         fix2.WarnFlags=[fix2.WarnFlags 3];
%                     end
%                     fix2.LowerBoundCorr=thresh_vec2C;
%                     if get(handles.num_MinVel,'Value')
%                         fix2.UppperBoundVel=thresh_vel2;
%                     else
%                         fix2.LowerBoundVel=thresh_vel2;
%                     end
%                     if get(handles.CheckMask,'Value')
%                         fix2.MaskName=maskname;
%                     end
%                     Param.Fix2=fix2;
%                 end
%                 if Param.CheckPatch2==1
%                     if strcmp(compare,'stereo PIV')
%                         filebase_A=filecell.filebase;
%                         [pp,ff]=fileparts(filebase_A);
%                         filebase_B=fullfile(pp,get(handles.RootName_1,'String'));
%                         RUN_STLIN(filecell.ncA.civ2{ifile,j},filecell.nc.civ2{ifile,j},'civ2',filecell.st{ifile,j},...
%                             str2num(nx_patch2),str2num(ny_patch2),str2num(thresh_patch2),[filebase_A '.xml'],[filebase_B '.xml'])
%                     else
%                         Param.Patch2.Rho=rho_patch2;
%                         Param.Patch2.Threshold=thresh_patch2;
%                         Param.Patch2.SubDomain=subdomain_patch2;
%                     end
%                 end

if isfield (Param,'Fix1')
    ListFixParam=fieldnames(Param.Fix1);
    for ilist=1:length(ListFixParam)
        ParamName=ListFixParam{ilist};
        ListName=['Fix1_' ParamName];
        eval(['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];'])
        eval(['Data.' ListName '=Param.Fix1.' ParamName ';'])
    end
%     Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Fix1_WarnFlags','Fix1_TreshCorr','Fix1_TreshVel','Fix1_UpperBoundTest'}];
%     Data.Fix1_WarnFlags=Param.Fix1.WarnFlags;
%     Data.Fix1_ThreshCorr=Param.Fix1.ThreshCorr;
%     Data.Fix1_ThreshVel=Param.Fix1.ThreshVel;
%     Data.Fix1_UpperBoundTest=Param.Fix1.UpperBoundTest;

    if test_civx
        if ~isfield(Data,'fix')
            Data.ListGlobalAttribute=[Data.ListGlobalAttribute 'fix'];
            Data.fix=1;
            Data.ListVarName=[Data.ListVarName {'vec_FixFlag'}];
            Data.VarDimName=[Data.VarDimName {'nb_vectors'}];
        end
        Data.vec_FixFlag=fix(Param.Fix1,Data.vec_F,Data.vec_C,Data.vec_U,Data.vec_V,Data.vec_X,Data.vec_Y);
    else
        Data.ListVarName=[Data.ListVarName {'Civ1_FF'}];
        Data.VarDimName=[Data.VarDimName {'nbvec1'}];
        nbvar=length(Data.ListVarName);
        Data.VarAttribute{nbvar}.Role='errorflag';    
        Data.Civ1_FF=fix(Param.Fix1,Data.Civ1_F,Data.Civ1_C,Data.Civ1_U,Data.Civ1_V);
        Data.CivStage=2;    
    end
end   
%% Patch1
if isfield (Param,'Patch1')
    test_patch1=1;
    Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch1_Rho','Patch1_Threshold','Patch1_SubDomain'}];
    Data.Patch1_Rho=str2double(Param.Patch1.Rho);
    Data.Patch1_Threshold=str2double(Param.Patch1.Threshold);
    Data.Patch1_SubDomain=str2double(Param.Patch1.SubDomain);
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
    if ~test_civ1 || ~strcmp(par_civ1.filename_ima_a,par_civ2.filename_ima_a)
            image1=imread(par_civ2.filename_ima_a);%read first image if not already done for civ1 
    end
    if ~test_civ1|| ~strcmp(par_civ1.filename_ima_b,par_civ2.filename_ima_b)
            image2=imread(par_civ2.filename_ima_b);%read second image if not already done for civ1 
    end
%     stepx=str2double(par_civ2.dx);
%     stepy=str2double(par_civ2.dy);
    ibx2=ceil(str2double(par_civ2.ibx)/2);
    iby2=ceil(str2double(par_civ2.iby)/2);
    isx2=ibx2+2;
    isy2=iby2+2;
    %get the previous guess for displacement
    if ~test_patch1
        [Guess,VelType]=read_civdata(ObjectName,InputField,ParamIn.VelType);%TO DEVELOP
    else
        Data.Civ1_U_Diff=zeros(size(Data.Civ1_X));
        Data.Civ1_V_Diff=zeros(size(Data.Civ1_X));
        if isfield(Data,'Civ1_FF')
            ind_good=find(Data.Civ1_FF==0);
        else
            ind_good=1:numel(Data.Civ1_X);
        end
            [Data.Civ1_X_SubRange,Data.Civ1_Y_SubRange,Data.Civ1_NbSites,FFres,Ures, Vres,Data.Civ1_X_tps,Data.Civ1_Y_tps,Data.Civ1_U_tps,Data.Civ1_V_tps]=...
                                patch(Data.Civ1_X(ind_good)',Data.Civ1_Y(ind_good)',Data.Civ1_U(ind_good)',Data.Civ1_V(ind_good)',Data.Patch1_Rho,Data.Patch1_Threshold,Data.Patch1_SubDomain);
        end 
%     shiftx=str2num(par_civ1.shiftx);
%     shifty=str2num(par_civ1.shifty);
% TO GET shift from par_civ2.filename_nc1
    % shiftx=velocity interpolated at position 
    miniy=max(1+isy2+shifty,1+iby2);
    minix=max(1+isx2-shiftx,1+ibx2);
    maxiy=min(size(image1,1)-isy2+shifty,size(image1,1)-iby2);
    maxix=min(size(image1,2)-isx2-shiftx,size(image1,2)-ibx2);
    [GridX,GridY]=meshgrid(minix:par_civ2.Dx:maxix,miniy:par_civ2.Dy:maxiy);
    PointCoord(:,1)=reshape(GridX,[],1);
    PointCoord(:,2)=reshape(GridY,[],1);
    if ~isempty(par_civ2.maskname)&& ~strcmp(maskname,par_civ2.maskname)% mask exist, not already read in civ1
        mask=imread(par_civ2.maskname);
    end
    % caluclate velocity data (y and v in indices, reverse to y component)
    [xtable ytable utable vtable ctable F] = civ (image1,image2,ibx2,iby2,isx2,isy2,shiftx,-shifty,PointCoord,str2num(par_civ1.rho),mask);
    list_param=(fieldnames(par_civ1))';
    list_remove={'pxcmx','pxcmy','npx','npy','gridflag','maskflag','term_a','term_b','T0'};
    index=zeros(size(list_param));
    for ilist=1:length(list_remove)
        index=strcmp(list_remove{ilist},list_param);
        if ~isempty(find(index,1))
            list_param(index)=[];
        end
    end
    for ilist=1:length(list_param)
        Civ1_param{ilist}=['Civ1_' list_param{ilist}];
        eval(['Data.Civ1_' list_param{ilist} '=Param.Civ1.' list_param{ilist} ';'])
    end
    if isfield(Data,'Civ1_gridname') && strcmp(Data.Civ1_gridname(1:6),'noFile')
        Data.Civ1_gridname='';
    end
    if isfield(Data,'Civ1_maskname') && strcmp(Data.Civ1_maskname(1:6),'noFile')
        Data.Civ1_maskname='';
    end
    Data.ListGlobalAttribute=[Data.ListGlobalAttribute Civ1_param {'Civ1_Time','Civ1_Dt'}];
    Data.Civ1_Time=str2double(par_civ1.T0);
    Data.Civ1_Dt=str2double(par_civ1.Dt);
    Data.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F'};%  cell array containing the names of the fields to record
    Data.VarDimName={'nbvec1','nbvec1','nbvec1','nbvec1','nbvec1','nbvec1'};
    Data.VarAttribute{1}.Role='coord_x';
    Data.VarAttribute{2}.Role='coord_y';
    Data.VarAttribute{3}.Role='vector_x';
    Data.VarAttribute{4}.Role='vector_y';
    Data.VarAttribute{5}.Role='warnflag';
    Data.Civ1_X=reshape(xtable,[],1);
    Data.Civ1_Y=reshape(size(image1,1)-ytable+1,[],1);
    Data.Civ1_U=reshape(utable,[],1);
    Data.Civ1_V=reshape(-vtable,[],1);
    Data.Civ1_C=reshape(ctable,[],1);
    Data.Civ1_F=reshape(F,[],1);
    Data.CivStage=Data.CivStage+1;
end

%% Fix2
if isfield (Param,'Fix2')
    ListFixParam=fieldnames(Param.Fix2);
    for ilist=1:length(ListFixParam)
        ParamName=ListFixParam{ilist};
        ListName=['Fix1_' ParamName];
        eval(['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];'])
        eval(['Data.' ListName '=Param.Fix2.' ParamName ';'])
    end
    if test_civx
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
        Data.CivStage=5;    
    end
    
end   

%% Patch2
if isfield (Param,'Patch2')
    Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch2_Rho','Patch2_Threshold','Patch2_SubDomain'}];
    Data.Patch2_Rho=str2double(Param.Patch2.Rho);
    Data.Patch2_Threshold=str2double(Param.Patch2.Threshold);
    Data.Patch2_SubDomain=str2double(Param.Patch2.SubDomain);
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
      Data.CivStage=6;                             
end   

%% write result in a netcdf file if requested
if exist('ncfile','var')
    errormsg=struct2nc(ncfile,Data);
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
Param

%criterium on warn flags
FlagName={'CheckFmin2','CheckF2','CheckF3','CheckF4'};
FlagVal=[-2 2 3 4];
for iflag=1:numel(FlagVal)
    if Param.(CheckFlag(iflag))
        FF=(FF==1| F==FlagVal(iflag));
% if isfield (Param,'WarnFlags')
%     for iflag=1:numel(Param.WarnFlags)
%         FF=(FF==1| F==Param.WarnFlags(iflag));
%     end
% end
    end
end
%criterium on correlation values
if isfield (Param,'MinCorr')
    FF=FF==1 | C<Param.MinCorr;
end
return


if isfield (Param,'LowerBoundVel')&& ~isequal(Param.LowerBoundVel,0)
    thresh=Param.LowerBoundVel*Param.LowerBoundVel;
    FF=FF==1 | (U.*U+V.*V)<thresh;
end
if isfield (Param,'UpperBoundVel')&& ~isequal(Param.UpperBoundVel,0)
    thresh=Param.UpperBoundVel*Param.UpperBoundVel;
    FF=FF==1 | (U.*U+V.*V)>thresh;
end
if isfield(Param,'MaskName')
   M=imread(Param.MaskName);
   nxy=size(M);
   M=reshape(M,1,[]);
   rangx0=[0.5 nxy(2)-0.5];
   rangy0=[0.5 nxy(1)-0.5];
   vec_x1=X-U/2;%beginning points
   vec_x2=X+U/2;%end points of vectors
   vec_y1=Y-V/2;%beginning points
   vec_y2=Y+V/2;%end points of vectors
   indx=1+round((nxy(2)-1)*(vec_x1-rangx0(1))/(rangx0(2)-rangx0(1)));% image index x at abcissa vec_x1
   indy=1+round((nxy(1)-1)*(vec_y1-rangy0(1))/(rangy0(2)-rangy0(1)));% image index y at ordinate vec_y1   
   test_in=~(indx < 1 |indy < 1 | indx > nxy(2) |indy > nxy(1)); %=0 out of the mask image, 1 inside
   indx=indx.*test_in+(1-test_in); %replace indx by 1 out of the mask range
   indy=indy.*test_in+(1-test_in); %replace indy by 1 out of the mask range
   ICOMB=((indx-1)*nxy(1)+(nxy(1)+1-indy));%determine the indices in the image reshaped in a Matlab vector
   Mvalues=M(ICOMB);
   flag7b=((20 < Mvalues) & (Mvalues < 200))| ~test_in';
   indx=1+round((nxy(2)-1)*(vec_x2-rangx0(1))/(rangx0(2)-rangx0(1)));% image index x at abcissa vec_x2
   indy=1+round((nxy(1)-1)*(vec_y2-rangy0(1))/(rangy0(2)-rangy0(1)));% image index y at ordinate vec_y2
   test_in=~(indx < 1 |indy < 1 | indx > nxy(2) |indy > nxy(1)); %=0 out of the mask image, 1 inside
   indx=indx.*test_in+(1-test_in); %replace indx by 1 out of the mask range
   indy=indy.*test_in+(1-test_in); %replace indy by 1 out of the mask range
   ICOMB=((indx-1)*nxy(1)+(nxy(1)+1-indy));%determine the indices in the image reshaped in a Matlab vector
   Mvalues=M(ICOMB);
   flag7e=((Mvalues > 20) & (Mvalues < 200))| ~test_in';
   FF=FF==1 |(flag7b|flag7e)';
end
%    flag7=0;
% end   


FF=double(FF);
% 
% % criterium on velocity values
% delta_u=Field.U;%default without ref file
% delta_v=Field.V;
% if exist('fileref','var') && ~isempty(fileref)
%     if ~exist(fileref,'file')
%         error='reference file not found in RUN_FIX.m';
%         display(error);
%         return
%     end
%     FieldRef=read_civxdata(fileref,[],fieldref);   
%     if isfield(FieldRef,'FF')
%         index_true=find(FieldRef.FF==0);
%         FieldRef.X=FieldRef.X(index_true);
%         FieldRef.Y=FieldRef.Y(index_true);
%         FieldRef.U=FieldRef.U(index_true);
%         FieldRef.V=FieldRef.V(index_true);
%     end
%     if ~isfield(FieldRef,'X') || ~isfield(FieldRef,'Y') || ~isfield(FieldRef,'U') || ~isfield(FieldRef,'V')
%         error='reference file is not a velocity field in RUN_FIX.m '; %bad input file
%         return
%     end
%     if length(FieldRef.X)<=1
%         errordlg('reference field with one vector or less in RUN_FIX.m')
%         return
%     end
%     vec_U_ref=griddata_uvmat(FieldRef.X,FieldRef.Y,FieldRef.U,Field.X,Field.Y);  %interpolate vectors in the ref field
%     vec_V_ref=griddata_uvmat(FieldRef.X,FieldRef.Y,FieldRef.V,Field.X,Field.Y);  %interpolate vectors in the ref field to the positions  of the main field     
%     delta_u=Field.U-vec_U_ref;%take the difference with the interpolated ref field
%     delta_v=Field.V-vec_V_ref;
% end
% thresh_vel_x=thresh_vel; 
% thresh_vel_y=thresh_vel; 
% if isequal(inf_sup,1)
%     flag5=abs(delta_u)<thresh_vel_x & abs(delta_v)<thresh_vel_y &(flag1~=1)&(flag2~=1)&(flag3~=1)&(flag4~=1);
% elseif isequal(inf_sup,2)
%     flag5=(abs(delta_u)>thresh_vel_x | abs(delta_v)>thresh_vel_y) &(flag1~=1)&(flag2~=1)&(flag3~=1)&(flag4~=1);
% end
% 
%             % flag7 introduce a grey mask, matrix M

% flagmagenta=flag1|flag2|flag3|flag4|flag5|flag7;
% fixflag_unit=Field.FF-10*floor(Field.FF/10); %unity term of fix_flag



%------------------------------------------------------------------------
% patch function
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
CentreY=reshape(CentreY,1,[]);
CentreX=reshape(CentreX,1,[]);
rho=SizX*SizY*Rho/1000000;%optimum rho increase as the area of the subdomain (division by 10^6 to reach good values with the default GUI input)
U_tps_sub=zeros(length(X),NbSubDomain);%default spline
V_tps_sub=zeros(length(X),NbSubDomain);%default spline
U_smooth=zeros(length(X),1);
V_smooth=zeros(length(X),1);

nb_select=zeros(length(X),1);
FF=zeros(length(X),1);
test_empty=zeros(1,NbSubDomain);
for isub=1:NbSubDomain
    SubRangx(isub,:)=[CentreX(isub)-SizX/2 CentreX(isub)+SizX/2];
    SubRangy(isub,:)=[CentreY(isub)-SizY/2 CentreY(isub)+SizY/2];
    ind_sel_previous=[];
    ind_sel=0;
    while numel(ind_sel)>numel(ind_sel_previous) %increase the subdomain during four iterations at most
        ind_sel_previous=ind_sel;
        ind_sel=find(X>SubRangx(isub,1) & X<SubRangx(isub,2) & Y>SubRangy(isub,1) & Y<SubRangy(isub,2));
        % if no vector in the subdomain, skip the subdomain
        if isempty(ind_sel)
            test_empty(isub)=1;    
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
            [U_smooth_sub,U_tps_sub]=tps_coeff(X(ind_sel),Y(ind_sel),U(ind_sel),rho);
            [V_smooth_sub,V_tps_sub]=tps_coeff(X(ind_sel),Y(ind_sel),V(ind_sel),rho);
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
                [U_smooth_sub,U_tps_sub]=tps_coeff(X(ind_sel(ind_ind_sel)),Y(ind_sel(ind_ind_sel)),U(ind_sel(ind_ind_sel)),rho);
                [V_smooth_sub,V_tps_sub]=tps_coeff(X(ind_sel(ind_ind_sel)),Y(ind_sel(ind_ind_sel)),V(ind_sel(ind_ind_sel)),rho);
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
ind_empty=find(test_empty);
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
function [xtable ytable utable vtable ctable F result_conv errormsg] = civ (image1,image2,ibx2,iby2,isx2,isy2,shiftx,shifty, GridIndices, subpixfinder,mask)
%this funtion performs the DCC PIV analysis. Recent window-deformation
%methods perform better and will maybe be implemented in the future.
nbvec=size(GridIndices,1);
xtable=zeros(nbvec,1);
ytable=xtable;
utable=xtable;
vtable=xtable;
ctable=xtable;
F=xtable;
result_conv=[];
errormsg='';
%warning off %MATLAB:log:logOfZero
[npy_ima npx_ima]=size(image1);
if ~isequal(size(image2),[npy_ima npx_ima])
    errormsg='image pair with unequal size';
    return
end

%% mask
testmask=0;
image1=double(image1);
image2=double(image2);
if exist('mask','var') && ~isempty(mask)
   testmask=1;
   if ~isequal(size(mask),[npy_ima npx_ima])
        errormsg='mask must be an image with the same size as the images';
        return
   end
    % Convention for mask
    % mask >200 : velocity calculated
    %  200 >=mask>150;velocity not calculated, interpolation allowed (bad spots)
    % 150>=mask >100: velocity not calculated, nor interpolated
    %  100>=mask> 20: velocity not calculated, impermeable (no flux through mask boundaries)
    %  20>=mask: velocity=0
    test_noflux=(mask<100) ;
    test_undefined=(mask<200 & mask>=100 );
    image1(test_undefined)=min(min(image1));% put image to zero in the undefined  area
    image2(test_undefined)=min(min(image2));% put image to zero in the undefined  area
end

%% calculate correlations: MAINLOOP on velocity vectors
corrmax=0;
sum_square=1;% default
for ivec=1:nbvec 
    iref=GridIndices(ivec,1);
    jref=GridIndices(ivec,2);
    testmask_ij=0;
    test0=0;
    if testmask
        if mask(jref,iref)<=20
           vector=[0 0];
           test0=1;
        else
            mask_crop1=mask(jref-iby2:jref+iby2,iref-ibx2:iref+ibx2);
            mask_crop2=mask(jref+shifty-isy2:jref+shifty+isy2,iref+shiftx-isx2:iref+shiftx+isx2);
            if ~isempty(find(mask_crop1<=200 & mask_crop1>100,1)) || ~isempty(find(mask_crop2<=200 & mask_crop2>100,1));
                testmask_ij=1;
            end
        end
    end
    if ~test0    
        image1_crop=image1(jref-iby2:jref+iby2,iref-ibx2:iref+ibx2);%extract a subimage (correlation box) from images 1  
        image2_crop=image2(jref+shifty-isy2:jref+shifty+isy2,iref+shiftx-isx2:iref+shiftx+isx2);%extract a larger subimage (search box) from image 2
        image1_crop=image1_crop-mean(mean(image1_crop));%substract the mean
        image2_crop=image2_crop-mean(mean(image2_crop));
        %reference: Oliver Pust, PIV: Direct Cross-Correlation
        result_conv= conv2(image2_crop,flipdim(flipdim(image1_crop,2),1),'valid');
        corrmax= max(max(result_conv));
        result_conv=(result_conv/corrmax)*255; %normalize, peak=always 255
        %Find the correlation max, at 255
        [y,x] = find(result_conv==255,1);
        if ~isempty(y) && ~isempty(x)
            try
                if subpixfinder==1
                    [vector,F(ivec)] = SUBPIXGAUSS (result_conv,x,y);
                elseif subpixfinder==2
                    [vector,F(ivec)] = SUBPIX2DGAUSS (result_conv,x,y);
                end
                sum_square=sum(sum(image1_crop.*image1_crop));
                ctable(ivec)=corrmax/sum_square;% correlation value
%                 if vector(1)>shiftx+isx2-ibx2+subpixfinder || vector(2)>shifty+isy2-iby2+subpixfinder
%                     F(ivec)=-2;%vector reaches the border of the search zone
%                 end
            catch ME
                vector=[0 0]; %if something goes wrong with cross correlation.....
                F(ivec)=3;
            end
        else
            vector=[0 0]; %if something goes wrong with cross correlation.....
            F(ivec)=3;
        end
        if testmask_ij
            F(ivec)=3;
        end
    end
    
    %Create the vector matrix x, y, u, v
    xtable(ivec)=iref+vector(1)/2;% convec flow (velocity taken at the point middle from imgae1 and 2)
    ytable(ivec)=jref+vector(2)/2;
    utable(ivec)=vector(1)+shiftx;
    vtable(ivec)=vector(2)+shifty;
end
result_conv=result_conv*corrmax/(255*sum_square);% keep the last correlation matrix for output


function [vector,F] = SUBPIXGAUSS (result_conv,x,y)
vector=[0 0]; %default
F=0;
[npy,npx]=size(result_conv);

% if (x <= (size(result_conv,1)-1)) && (y <= (size(result_conv,1)-1)) && (x >= 1) && (y >= 1)
    %the following 8 lines are copyright (c) 1998, Uri Shavit, Roi Gurka, Alex Liberzon, Technion – Israel Institute of Technology
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
% else
%     vector=[NaN NaN];
% end

function [vector,F] = SUBPIX2DGAUSS (result_conv,x,y)
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
            %H. Nobach Æ M. Honkanen (2005)
            %Two-dimensional Gaussian regression for sub-pixel displacement
            %estimation in particle image velocimetry or particle position
            %estimation in particle tracking velocimetry
            %Experiments in Fluids (2005) 38: 511–515
            c10(j+2,i+2)=i*log(result_conv(y+j, x+i));
            c01(j+2,i+2)=j*log(result_conv(y+j, x+i));
            c11(j+2,i+2)=i*j*log(result_conv(y+j, x+i));
            c20(j+2,i+2)=(3*i^2-2)*log(result_conv(y+j, x+i));
            c02(j+2,i+2)=(3*j^2-2)*log(result_conv(y+j, x+i));
            %c00(j+2,i+2)=(5-3*i^2-3*j^2)*log(result_conv_norm(maxY+j, maxX+i));
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


