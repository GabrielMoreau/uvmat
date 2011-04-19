% To develop....
function [Data,errormsg]= civ_uvmat(Param,ncfile)
Data.ListGlobalAttribute={'Conventions','Program','CivStage'};
Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
Data.Program='civ_uvmat';
Data.CivStage=0;%default

%% Civ1
if isfield (Param,'Civ1')
    par_civ1=Param.Civ1;
    str2num(par_civ1.rho)
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
    miniy=max(1+isy2-shifty,1+iby2);
    minix=max(1+isx2-shiftx,1+ibx2);
    maxiy=min(size(image1,1)-isy2-shifty,size(image1,1)-iby2);
    maxix=min(size(image1,2)-isx2-shiftx,size(image1,2)-ibx2);
    [GridX,GridY]=meshgrid(minix:stepx:maxix,miniy:stepy:maxiy);
    PointCoord(:,1)=reshape(GridX,[],1);
    PointCoord(:,2)=reshape(GridY,[],1);
    
    % caluclate velocity data (y and v in indices, reverse to y component)
    [xtable ytable utable vtable ctable F] = pivlab (image1,image2,ibx2,iby2,isx2,isy2,shiftx,shifty,PointCoord,str2num(par_civ1.rho), []);
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
    Data=nc2struct(ncfile)%read existing netcdf file
    if isfield(Data,'absolut_time_T0')%read civx file
        var={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F','Civ1_FF';'vec_X','vec_Y','vec_U','vec_V','vec_C','vec_F','vec_FixFlag'};
        %var=varcivx_generator('velocity','Civ1');%determine the names of constants and variables to read
        [Data,vardetect,ichoice]=nc2struct(ncfile,var);%read the variables in the netcdf file
        Data.ListGlobalAttribute=[{'Conventions','Program','CivStage'} Data.ListGlobalAttribute {'Civ1_Time','Civ1_Dt'}];
        Data.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
        Data.Program='civ_uvmat';
        Data.Civ1_Time=double(Data.absolut_time_T0);
        Data.Civ1_Dt=double(Data.dt);
        Data.VarDimName={'nbvec1','nbvec1','nbvec1','nbvec1','nbvec1','nbvec1','nbvec1'};
        Data.VarAttribute{1}.Role='coord_x';
        Data.VarAttribute{2}.Role='coord_y';
        Data.VarAttribute{3}.Role='vector_x';
        Data.VarAttribute{4}.Role='vector_y';
        Data.VarAttribute{5}.Role='ancillary';
        Data.VarAttribute{6}.Role='warnflag';
        Data.VarAttribute{7}.Role='errorflag';
        Data.CivStage=1;
    end 
end

%% Fix1
if isfield (Param,'Fix1')
    ListFixParam=fieldnames(Param.Fix1);
    for ilist=1:length(ListFixParam)
        ParamName=ListFixParam{ilist};
        ListName=['Fix1_' ParamName];
        ['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];']
        eval(['Data.ListGlobalAttribute=[Data.ListGlobalAttribute ''' ParamName '''];'])
        eval(['Data.' ListName '=Param.Fix1.' ParamName ';'])
    end
%     Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Fix1_WarnFlags','Fix1_TreshCorr','Fix1_TreshVel','Fix1_UpperBoundTest'}];
%     Data.Fix1_WarnFlags=Param.Fix1.WarnFlags;
%     Data.Fix1_ThreshCorr=Param.Fix1.ThreshCorr;
%     Data.Fix1_ThreshVel=Param.Fix1.ThreshVel;
%     Data.Fix1_UpperBoundTest=Param.Fix1.UpperBoundTest;
    Data.ListVarName=[Data.ListVarName {'Civ1_FF'}];
    Data.VarDimName=[Data.VarDimName {'nbvec1'}];
    nbvar=length(Data.ListVarName);
    Data.VarAttribute{nbvar}.Role='errorflag';
    [Data.Civ1_FF]=fix_uvmat(Param.Fix1,Data.Civ1_F,Data.Civ1_C,Data.Civ1_U,Data.Civ1_V);
    Data.CivStage=2;                               
end   
%% Patch1
if isfield (Param,'Patch1')
    Data.ListGlobalAttribute=[Data.ListGlobalAttribute {'Patch1_Rho','Patch1_Threshold','Patch1_SubDomain'}];
    Data.Patch1_Rho=str2double(Param.Patch1.Rho);
    Data.Patch1_Threshold=str2double(Param.Patch1.Threshold);
    Data.Patch1_SubDomain=str2double(Param.Patch1.SubDomain);
    Data.ListVarName=[Data.ListVarName {'Patch1_U','Patch1_V'}];
    Data.VarDimName=[Data.VarDimName {'nbvec1','nbvec1'}];
    nbvar=length(Data.ListVarName);
    Data.VarAttribute{nbvar-1}.Role='vector_x';
    Data.VarAttribute{nbvar}.Role='vector_y';
    Data.Patch1_U=zeros(size(Data.Civ1_X));
    Data.Patch1_V=zeros(size(Data.Civ1_X));
    if isfield(Data,'Civ1_FF')
        ind_good=find(Data.Civ1_FF==0);
    else
        ind_good=1:numel(Data.Civ1_X);
    end
    Data.Civ1_X
    [Ures, Vres,FFres]=...
                            patch_uvmat(Data.Civ1_X(ind_good)',Data.Civ1_Y(ind_good)',Data.Civ1_U(ind_good)',Data.Civ1_V(ind_good)',Data.Patch1_Rho,Data.Patch1_Threshold,Data.Patch1_SubDomain); 
                        size(Ures)
                        size(Vres)
                        size(FFres)
                        size(ind_good)
      Data.Patch1_U(ind_good)=Ures;
      Data.Patch1_V(ind_good)=Vres;
      Data.Civ1_FF(ind_good)=FFres
      Data.CivStage=3;                               
end   
%% write result
errormsg=struct2nc(ncfile,Data);



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

function FF=fix_uvmat(Param,F,C,U,V)
%error=[]; %default
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
% if isequal (flag_mask,1)
%    M=imread(maskname);
%    nxy=size(M);
%    M=reshape(M,1,nxy(1)*nxy(2));
%    rangx0=[0.5 nxy(2)-0.5];
%    rangy0=[0.5 nxy(1)-0.5];
%    vec_x1=Field.X-Field.U/2;%beginning points
%    vec_x2=Field.X+Field.U/2;%end points of vectors
%    vec_y1=Field.Y-Field.V/2;%beginning points
%    vec_y2=Field.Y+Field.V/2;%end points of vectors
%    indx=1+round((nxy(2)-1)*(vec_x1-rangx0(1))/(rangx0(2)-rangx0(1)));% image index x at abcissa vec_x
%    indy=1+round((nxy(1)-1)*(vec_y1-rangy0(1))/(rangy0(2)-rangy0(1)));% image index y at ordinate vec_y   
%    test_in=~(indx < 1 |indy < 1 | indx > nxy(2) |indy > nxy(1)); %=0 out of the mask image, 1 inside
%    indx=indx.*test_in+(1-test_in); %replace indx by 1 out of the mask range
%    indy=indy.*test_in+(1-test_in); %replace indy by 1 out of the mask range
%    ICOMB=((indx-1)*nxy(1)+(nxy(1)+1-indy));%determine the indices in the image reshaped in a Matlab vector
%    Mvalues=M(ICOMB);
%    flag7b=((20 < Mvalues) & (Mvalues < 200))| ~test_in';
%    indx=1+round((nxy(2)-1)*(vec_x2-rangx0(1))/(rangx0(2)-rangx0(1)));% image index x at abcissa Field.X
%    indy=1+round((nxy(1)-1)*(vec_y2-rangy0(1))/(rangy0(2)-rangy0(1)));% image index y at ordinate vec_y
%    test_in=~(indx < 1 |indy < 1 | indx > nxy(2) |indy > nxy(1)); %=0 out of the mask image, 1 inside
%    indx=indx.*test_in+(1-test_in); %replace indx by 1 out of the mask range
%    indy=indy.*test_in+(1-test_in); %replace indy by 1 out of the mask range
%    ICOMB=((indx-1)*nxy(1)+(nxy(1)+1-indy));%determine the indices in the image reshaped in a Matlab vector
%    Mvalues=M(ICOMB);
%    flag7e=((Mvalues > 20) & (Mvalues < 200))| ~test_in';
%    flag7=(flag7b|flag7e)';
% else
%    flag7=0;
% end   
% flagmagenta=flag1|flag2|flag3|flag4|flag5|flag7;
% fixflag_unit=Field.FF-10*floor(Field.FF/10); %unity term of fix_flag



%------------------------------------------------------------------------
% patch function
function [U_patch,V_patch,FF,SubRangx,SubRangy,X_ctrs,Y_ctrs] =patch_uvmat(X,Y,U,V,Rho,Threshold,SubDomain)
%subdomain decomposition
warning off
U=reshape(U,[],1);
V=reshape(V,[],1);
X=reshape(X,[],1);
Y=reshape(Y,[],1);
nbvec=numel(X);
NbSubDomain=ceil(nbvec/SubDomain)
MinX=min(X)
MinY=min(Y)
MaxX=max(X)
MaxY=max(Y)
RangX=MaxX-MinX;
RangY=MaxY-MinY;
AspectRatio=RangY/RangX
NbSubDomainX=ceil(sqrt(NbSubDomain/AspectRatio))
NbSubDomainY=ceil(sqrt(NbSubDomain*AspectRatio))

SizX=RangX/NbSubDomainX;%width of subdomains
SizY=RangY/NbSubDomainY;%height of subdomains
CentreX=linspace(MinX+SizX/2,MaxX-SizX/2,NbSubDomainX);
CentreY=linspace(MinY+SizY/2,MaxY-SizY/2,NbSubDomainY);
SubIndexX=ceil((X-MinX)/SizX);%subdomain index of vectors
SubIndexY=ceil((Y-MinY)/SizY);
rho=RangX*RangY*Rho;%optimum rho increase as teh area of the subdomain
U_tps=zeros(length(X),NbSubDomainY,NbSubDomainX);%default spline
V_tps=zeros(length(X),NbSubDomainY,NbSubDomainX);%default spline
X_dist=zeros(length(X),NbSubDomainY,NbSubDomainX);%default spline
Y_dist=zeros(length(X),NbSubDomainY,NbSubDomainX);%default spline
U_smooth=zeros(length(X),NbSubDomainY,NbSubDomainX);
V_smooth=zeros(length(X),NbSubDomainY,NbSubDomainX);
dist_ctre=zeros(length(X),NbSubDomainY,NbSubDomainX);
FF=zeros(length(X),1);
for isubx=1:NbSubDomainX
    for isuby=1:NbSubDomainY
        SubRangx(isuby,isubx,:)=[CentreX(isubx)-SizX/2 CentreX(isubx)+SizX/2];
        SubRangy(isuby,isubx,:)=[CentreY(isubx)-SizY/2 CentreY(isubx)+SizY/2];
        for iter=1:3 %increase the subdomain during three iterations at most
            ind_sel=find(X>SubRangx(isuby,isubx,1) & X<SubRangx(isuby,isubx,2) & Y>SubRangy(isuby,isubx,1) & Y<SubRangy(isuby,isubx,2));  
            size(ind_sel)
            if numel(ind_sel)<SubDomain/4;% too few selected vectors, increase the subrange for next iteration
                SubRangx(isuby,isubx,1)=SubRangx(isuby,isubx,1)-SizX/4;
                SubRangx(isuby,isubx,2)=SubRangx(isuby,isubx,2)+SizX/4;
                SubRangy(isuby,isubx,1)=SubRangy(isuby,isubx,1)-SizY/4;
                SubRangy(isuby,isubx,2)=SubRangy(isuby,isubx,2)+SizY/4;
            else
                [U_smooth_sub,U_tps_sub]=tps_uvmat(X(ind_sel),Y(ind_sel),U(ind_sel),rho);
                [V_smooth_sub,V_tps_sub]=tps_uvmat(X(ind_sel),Y(ind_sel),V(ind_sel),rho);
                size(U_smooth_sub)
                size(U(ind_sel))
                UDiff=U_smooth_sub-U(ind_sel);
                VDiff=V_smooth_sub-V(ind_sel);
                NormDiff=UDiff.*UDiff+VDiff.*VDiff;
                FF(ind_sel)=20*(NormDiff>Threshold);%put FF value to 20 to identify the criterium of elimmination
                ind_ind_sel=find(FF(ind_sel)==0); 
                if isequal(numel(ind_ind_sel),numel(ind_sel))
                    U_smooth(ind_sel,isuby,isubx)=U_smooth_sub;
                    V_smooth(ind_sel,isuby,isubx)=V_smooth_sub;
                    break 
                elseif numel(ind_ind_sel)<SubDomain/4;% too few selected vectors, increase the subrange for next iteration
                    SubRangx(isuby,isubx,1)=SubRangx(isuby,isubx,1)-SizX/4;
                    SubRangx(isuby,isubx,2)=SubRangx(isuby,isubx,2)+SizX/4;
                    SubRangy(isuby,isubx,1)=SubRangy(isuby,isubx,1)-SizY/4;
                    SubRangy(isuby,isubx,2)=SubRangy(isuby,isubx,2)+SizY/4;
                else
                    [U_smooth(ind_sel(ind_ind_sel),isuby,isubx),U_tps(ind_sel(ind_ind_sel),isuby,isubx),U_tps3(isuby,isubx)]=tps_uvmat(X(ind_sel(ind_ind_sel)),Y(ind_sel(ind_ind_sel)),U(ind_sel(ind_ind_sel)),rho);
                    [V_smooth(ind_sel(ind_ind_sel),isuby,isubx),V_tps(ind_sel(ind_ind_sel),isuby,isubx),V_tps3(isuby,isubx)]=tps_uvmat(X(ind_sel(ind_ind_sel)),Y(ind_sel(ind_ind_sel)),V(ind_sel(ind_ind_sel)),rho);
                     break                 
                end
            end        
        end       
        X_ctrs(isuby,isubx)=mean(X(ind_sel));%gravity centre of selected points
        Y_ctrs(isuby,isubx)=mean(Y(ind_sel));%positions of tps sources for the subdomain i,      
        dist_ctre(ind_sel,isuby,isubx)=sqrt(abs(((X(ind_sel)-X_ctrs(isuby,isubx)).*(X(ind_sel)-X_ctrs(isuby,isubx)))+((Y(ind_sel)-Y_ctrs(isuby,isubx)).*(Y(ind_sel)-Y_ctrs(isuby,isubx)))));
    end
end
U_patch=sum(sum(U_smooth.*dist_ctre,3),2)./sum(sum(dist_ctre,3),2);
V_patch=sum(sum(V_smooth.*dist_ctre,3),2)./sum(sum(dist_ctre,3),2);

%------------------------------------------------------------------------
%fasshauer@iit.edu MATH 590 ? Chapter 19 32
% X,Y initial coordiantes
% XI vector, YI column vector for the grid of interpolation points
function [U_smooth,U_tps,U_tps3]=tps_uvmat(X,Y,U,rho)
%------------------------------------------------------------------------
%rho smoothing parameter
ep = 1; 
X=reshape(X,[],1);
Y=reshape(Y,[],1);
rhs = reshape(U,[],1);
% if exist('FF','var')
% test_false=isnan(rhs)|FF~=0;
% else
%     test_false=isnan(rhs);
% end
% X(test_false)=[];
% Y(test_false)=[];
% rhs(test_false)=[];
%randn('state',3); rhs = rhs + 0.03*randn(size(rhs));
rhs = [rhs; zeros(3,1)];
dsites = [X Y];% coordinates of measurement sites
ctrs = dsites;%radial base functions are located at the measurement sites
DM_data = DistanceMatrix(dsites,ctrs);%2D matrix of distances between spline centres (=initial points) ctrs
% if size(XI,1)==1 && size(YI,2)==1 % XI vector, YI column vector
%      [XI,YI]=meshgrid(XI,YI);
% end
% [npy,npx]=size(XI);
% epoints = [reshape(XI,[],1) reshape(YI,[],1)];
IM_sites = tps(ep,DM_data);%values of thin plate at site points
IM = IM_sites + rho*eye(size(IM_sites));%  rho=1/(2*omega) , omega given by fasshauer;
PM=[ones(size(dsites,1),1) dsites];
IM=[IM PM; [PM' zeros(3,3)]];
%fprintf('Condition number estimate: %e\n',condest(IM))
%DM_eval = DistanceMatrix(epoints,ctrs);%2D matrix of distances between extrapolation points epoints and spline centres (=site points) ctrs
%EM = tps(ep,DM_eval);%values of thin plate 
%PM = [ones(size(epoints,1),1) epoints]; 
%EM = [EM PM];
U_tps=(IM\rhs);
PM = [ones(size(dsites,1),1) dsites]; 
EM = [IM_sites PM];
U_smooth=EM *U_tps;
U_tps3=U_tps(end-2:end);
U_tps=U_tps(1:end-3);


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


%   DM:     MxN matrix whose i,j position contains the Euclidean
%              distance between the i-th data site and j-th center
  function DM = DistanceMatrix(dsites,ctrs)
  [M,s] = size(dsites); [N,s] = size(ctrs);
  DM = zeros(M,N);
  % Accumulate sum of squares of coordinate differences
  % The ndgrid command produces two MxN matrices:
  %   dr, consisting of N identical columns (each containing
  %       the d-th coordinate of the M data sites)
  %   cc, consisting of M identical rows (each containing
  %       the d-th coordinate of the N centers)
  for d=1:s
     [dr,cc] = ndgrid(dsites(:,d),ctrs(:,d));
     DM = DM + (dr-cc).^2;
  end
  DM = sqrt(DM);


  % rbf = tps(e,r)
% Defines thin plate spline RBF
function rbf = tps(e,r) 
rbf = zeros(size(r));
nz = find(r~=0);   % to deal with singularity at origin
rbf(nz) = (e*r(nz)).^2.*log(e*r(nz));

