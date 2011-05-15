% To develop....
function [Data,errormsg]= civ_uvmat(Param,ncfile)
errormsg='';
Data.ListGlobalAttribute={'Conventions','Program','CivStage'};
Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
Data.Program='civ_uvmat';
Data.CivStage=0;%default
ListVarCiv1={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F'};
ListVarFix1={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F','Civ1_FF'};
mask='';
maskname='';%default
test_civx=0;%default

%% Civ1
if isfield (Param,'Civ1')
    par_civ1=Param.Civ1;
    image1=imread(par_civ1.filename_ima_a);
    image2=imread(par_civ1.filename_ima_b);
    stepx=str2num(par_civ1.dx);
    stepy=str2num(par_civ1.dy);
    ibx2=ceil(str2num(par_civ1.ibx)/2);
    iby2=ceil(str2num(par_civ1.iby)/2);
    isx2=ceil(str2num(par_civ1.isx)/2);
    isy2=ceil(str2num(par_civ1.isy)/2);
    shiftx=str2num(par_civ1.shiftx);
    shifty=str2num(par_civ1.shifty);
    miniy=max(1+isy2+shifty,1+iby2);
    minix=max(1+isx2-shiftx,1+ibx2);
    maxiy=min(size(image1,1)-isy2+shifty,size(image1,1)-iby2);
    maxix=min(size(image1,2)-isx2-shiftx,size(image1,2)-ibx2);
    [GridX,GridY]=meshgrid(minix:stepx:maxix,miniy:stepy:maxiy);
    PointCoord(:,1)=reshape(GridX,[],1);
    PointCoord(:,2)=reshape(GridY,[],1);
    if isfield(par_civ1,'maskname') && ~isempty(par_civ1.maskname)
        maskname=par_civ1.maskname;
        mask=imread(maskname);
    end
    % caluclate velocity data (y and v in indices, reverse to y component)
    [xtable ytable utable vtable ctable F] = pivlab (image1,image2,ibx2,iby2,isx2,isy2,shiftx,-shifty,PointCoord,str2num(par_civ1.rho), mask);
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
    Data.CivStage=1;
else
    Data=nc2struct(ncfile,'ListGlobalAttribute','absolut_time_T0');
    
    % read Civx data
    if ~isempty(Data.absolut_time_T0')%read civx file
%         var={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F','Civ1_FF';...
%             'vec_X','vec_Y','vec_U','vec_V','vec_C','vec_F','vec_FixFlag'};

        %var=varcivx_generator('velocity','Civ1');%determine the names of constants and variables to read
        test_civx=1;
        [Data,vardetect,ichoice]=nc2struct(ncfile);%read the variables in the netcdf file
%         Data.ListGlobalAttribute=[{'Conventions','Program','CivStage'} Data.ListGlobalAttribute {'Civ1_Time','Civ1_Dt'}];
%         Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
%         Data.Program='civ_uvmat';
%         Data.Civ1_Time=double(Data.absolut_time_T0);
%         Data.Civ1_Dt=double(Data.dt);
%         Data.VarDimName={'nbvec1','nbvec1','nbvec1','nbvec1','nbvec1','nbvec1','nbvec1'};
%         Data.VarAttribute{1}.Role='coord_x';
%         Data.VarAttribute{2}.Role='coord_y';
%         Data.VarAttribute{3}.Role='vector_x';
%         Data.VarAttribute{4}.Role='vector_y';
%         Data.VarAttribute{5}.Role='ancillary';
%         Data.VarAttribute{6}.Role='warnflag';
%         Data.VarAttribute{7}.Role='errorflag';
%         Data.CivStage=1;
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
        Data.vec_FixFlag=fix_uvmat(Param.Fix1,Data.vec_F,Data.vec_C,Data.vec_U,Data.vec_V,Data.vec_X,Data.vec_Y);
    else
        Data.ListVarName=[Data.ListVarName {'Civ1_FF'}];
        Data.VarDimName=[Data.VarDimName {'nbvec1'}];
        nbvar=length(Data.ListVarName);
        Data.VarAttribute{nbvar}.Role='errorflag';    
        Data.Civ1_FF=fix_uvmat(Param.Fix1,Data.Civ1_F,Data.Civ1_C,Data.Civ1_U,Data.Civ1_V);
        Data.CivStage=2;    
    end
end   
%% Patch1
if isfield (Param,'Patch1')
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
                            patch_uvmat(Data.Civ1_X(ind_good)',Data.Civ1_Y(ind_good)',Data.Civ1_U(ind_good)',Data.Civ1_V(ind_good)',Data.Patch1_Rho,Data.Patch1_Threshold,Data.Patch1_SubDomain); 
      Data.Civ1_U_Diff(ind_good)=Data.Civ1_U(ind_good)-Ures;
      Data.Civ1_V_Diff(ind_good)=Data.Civ1_V(ind_good)-Vres;
      Data.Civ1_FF(ind_good)=FFres;
      Data.CivStage=3;                             
end   

%% Civ2
if isfield (Param,'Civ2')
    par_civ2=Param.Civ2;
    image1=imread(par_civ2.filename_ima_a);
    image2=imread(par_civ2.filename_ima_b);
    stepx=str2num(par_civ2.dx);
    stepy=str2num(par_civ2.dy);
    ibx2=ceil(str2num(par_civ2.ibx)/2);
    iby2=ceil(str2num(par_civ2.iby)/2);
    isx2=4;
    isy2=4;
%     shiftx=str2num(par_civ1.shiftx);
%     shifty=str2num(par_civ1.shifty);
% TO GET shift from par_civ2.filename_nc1
    miniy=max(1+isy2+shifty,1+iby2);
    minix=max(1+isx2-shiftx,1+ibx2);
    maxiy=min(size(image1,1)-isy2+shifty,size(image1,1)-iby2);
    maxix=min(size(image1,2)-isx2-shiftx,size(image1,2)-ibx2);
    [GridX,GridY]=meshgrid(minix:stepx:maxix,miniy:stepy:maxiy);
    PointCoord(:,1)=reshape(GridX,[],1);
    PointCoord(:,2)=reshape(GridY,[],1);
    if ~isempty(par_civ2.maskname)&& ~strcmp(maskname,par_civ2.maskname)% mask exist, not already read in civ1
        mask=imread(par_civ2.maskname);
    end
    % caluclate velocity data (y and v in indices, reverse to y component)
    [xtable ytable utable vtable ctable F] = pivlab (image1,image2,ibx2,iby2,isx2,isy2,shiftx,-shifty,PointCoord,str2num(par_civ1.rho),mask);
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
        Data.vec_FixFlag=fix_uvmat(Param.Fix2,Data.vec2_F,Data.vec2_C,Data.vec2_U,Data.vec2_V,Data.vec2_X,Data.vec2_Y);
    else
        Data.ListVarName=[Data.ListVarName {'Civ2_FF'}];
        Data.VarDimName=[Data.VarDimName {'nbvec2'}];
        nbvar=length(Data.ListVarName);
        Data.VarAttribute{nbvar}.Role='errorflag';    
        Data.Civ2_FF=fix_uvmat(Param.Fix2,Data.Civ2_F,Data.Civ2_C,Data.Civ2_U,Data.Civ2_V);
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
                            patch_uvmat(Data.Civ2_X(ind_good)',Data.Civ2_Y(ind_good)',Data.Civ2_U(ind_good)',Data.Civ2_V(ind_good)',Data.Patch2_Rho,Data.Patch2_Threshold,Data.Patch2_SubDomain); 
      Data.Civ2_U_Diff(ind_good)=Data.Civ2_U(ind_good)-Ures;
      Data.Civ2_V_Diff(ind_good)=Data.Civ2_V(ind_good)-Vres;
      Data.Civ2_FF(ind_good)=FFres;
      Data.CivStage=3;                             
end   

%% write result
% 'TESTcalc'
% [DataOut,errormsg]=calc_field('velocity',Data)
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

function FF=fix_uvmat(Param,F,C,U,V,X,Y)
FF=zeros(size(F));%default

%criterium on warn flags
if isfield (Param,'WarnFlags')
    for iflag=1:numel(Param.WarnFlags)
        FF=(FF==1| F==Param.WarnFlags(iflag));
    end
end

%criterium on correlation values
if isfield (Param,'LowerBoundCorr')
    FF=FF==1 | C<Param.LowerBoundCorr;
end

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
function [SubRangx,SubRangy,nbpoints,FF,U_smooth,V_smooth,X_tps,Y_tps,U_tps,V_tps] =patch_uvmat(X,Y,U,V,Rho,Threshold,SubDomain)
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






% U_patch = EM * spline_coeff;
% U_patch=reshape(U_patch,npy,npx);
% PM = [ones(size(dsites,1),1) dsites]; 
% EM = [IM_sites PM];
% U(test_false)=[];
% U_nodes=EM * spline_coeff;

%exact = testfunctions(epoints);
%maxerr = norm(Pf-exact,inf);
% PlotSurf(xe,ye,Pf,neval,exact,maxerr,[160,20]);
% PlotError2D(xe,ye,Pf,exact,maxerr,neval,[160,20]);



  % DM = DistanceMatrix(dsites,ctrs)
% Forms the distance matrix of two sets of points in R^s,
% i.e., DM(i,j) = || datasite_i - center_j ||_2.
% Input
%   dsites: Mxs matrix representing a set of M data sites in R^s
%              (i.e., each row contains one s-dimensional point)
%   ctrs:   Nxs matrix representing a set of N centers in R^s
%              (one center per row)
% Output




