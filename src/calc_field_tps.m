
%'calc_field': defines fields (velocity, vort, div...) from civx data and calculate them
%---------------------------------------------------------------------
% [DataOut,VarAttribute,errormsg]=calc_field_tps(Coord_tps,NbSites,SubRange,FieldVar,Operation,Coord_interp)
%
% OUTPUT:
% DataOut: structure representing the output fields
%
% INPUT:
% Coord_tps:
% NbSites
% SubRange
% FieldVar
% Operation: cell array representing the list of operations (eg div, rot..)
% Coord_interp: coordiantes of sites on which the fields need to be calculated

function [DataOut,VarAttribute,errormsg]=calc_field_tps(Coord_tps,NbSites,SubRange,FieldVar,Operation,Coord_interp)

%list of defined scalars to display in menus (in addition to 'ima_cor').
% a type is associated to each scalar:
%              'discrete': related to the individual velocity vectors, not interpolated by patch
%              'vel': calculated from velocity components, continuous field (interpolated with velocity)
%              'der': needs spatial derivatives
%              'var': the scalar name corresponds to a field name in the netcdf files
% a specific variable name for civ1 and civ2 fields are also associated, if
% the scalar is calculated from other fields, as explicited below
errormsg='';
    
%% nbre of subdomains
if ndims(Coord_interp)==3
    nb_coord=size(Coord_interp,3);
    npx=size(Coord_interp,2);
    npy=size(Coord_interp,1);
    nb_sites=npx*npy;
    Coord_interp=reshape(Coord_interp,nb_sites,nb_coord);
else
    nb_coord=size(Coord_interp,2);
    nb_sites=size(Coord_interp,1);
end
NbSubDomain=size(Coord_tps,3);
nbval=zeros(nb_sites,1);

%% list of operations
check_grid=0;
check_der=0;
for ilist=1:length(Operation)
    OperationType=regexprep(Operation{ilist},'(.+','');
    switch OperationType
        case 'vec'
            check_grid=1;
            DataOut.U=zeros(nb_sites,1);
            DataOut.V=zeros(nb_sites,1);
            VarAttribute{1}.Role='vector_x';
            VarAttribute{2}.Role='vector_y';
        case {'U','V','norm'}
            check_grid=1;
            DataOut.(OperationType)=zeros(nb_sites,1);
            VarAttribute{1}.Role='scalar';
        case {'curl','div','strain'}
            check_der=1;
            DataOut.(OperationType)=zeros(nb_sites,1);
            VarAttribute{1}.Role='scalar';
    end
end
Attr_FF.Role='errorflag';
VarAttribute=[VarAttribute {Attr_FF}];

%% loop on subdomains
for isub=1:NbSubDomain
    nbvec_sub=NbSites(isub);
    check_range=(Coord_interp >=ones(nb_sites,1)*SubRange(:,1,isub)' & Coord_interp<=ones(nb_sites,1)*SubRange(:,2,isub)');
    ind_sel=find(sum(check_range,2)==nb_coord);
    nbval(ind_sel)=nbval(ind_sel)+1;% records the number of values for eacn interpolation point (in case of subdomain overlap)
    if check_grid
        EM = tps_eval(Coord_interp(ind_sel,:),Coord_tps(1:nbvec_sub,:,isub));%kernels for calculating the velocity from tps 'sources'
    end
    if check_der
        [EMDX,EMDY] = tps_eval_dxy(Coord_interp(ind_sel,:),Coord_tps(1:nbvec_sub,:,isub));%kernels for calculating the spatial derivatives from tps 'sources'
    end
    ListVar={};
    for ilist=1:length(Operation)
        var_count=numel(ListVar);
        switch Operation{ilist}
            case 'vec(U,V)'
                ListVar=[ListVar {'U', 'V'}];
                VarAttribute{var_count+1}.Role='vector_x';
                VarAttribute{var_count+2}.Role='vector_y';
                DataOut.U(ind_sel)=DataOut.U(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,1);
                DataOut.V(ind_sel)=DataOut.V(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,2);
            case 'U'
                ListVar=[ListVar {'U'}];
                VarAttribute{var_count+1}.Role='scalar';
                DataOut.U(ind_sel)=DataOut.U(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,1);
            case 'V'
                ListVar=[ListVar {'V'}];
                VarAttribute{var_count+1}.Role='scalar';
                DataOut.V(ind_sel)=DataOut.V(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,2);
            case 'norm(U,V)'
                ListVar=[ListVar {'norm'}];
                VarAttribute{var_count+1}.Role='scalar';
                U=DataOut.U(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,1);
                V=DataOut.V(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,2);
                DataOut.norm(ind_sel)=sqrt(U.*U+V.*V);
            case 'curl(U,V)'
                ListVar=[ListVar {'curl'}];
                VarAttribute{var_count+1}.Role='scalar';
                DataOut.curl(ind_sel)=DataOut.curl(ind_sel)-EMDY *FieldVar(1:nbvec_sub+3,isub,1)+EMDX *FieldVar(1:nbvec_sub+3,isub,2);
            case 'div(U,V)'
                ListVar=[ListVar {'div'}];
                VarAttribute{var_count+1}.Role='scalar';
                DataOut.div(ind_sel)=DataOut.div(ind_sel)+EMDX*FieldVar(1:nbvec_sub+3,isub,1)+EMDY *FieldVar(1:nbvec_sub+3,isub,2);
            case 'strain(U,V)'
                ListVar=[ListVar {'strain'}];
                VarAttribute{var_count+1}.Role='scalar';
                DataOut.strain(ind_sel)=DataOut.strain(ind_sel)+EMDY*FieldVar(1:nbvec_sub+3,isub,1)+EMDX *FieldVar(1:nbvec_sub+3,isub,2);
        end
    end
end
DataOut.FF=nbval==0; %put errorflag to 1 for points outside the interpolation rang
nbval(nbval==0)=1;% to avoid division by zero for averaging
ListFieldOut=fieldnames(DataOut);
for ifield=1:numel(ListFieldOut)
    DataOut.(ListFieldOut{ifield})=DataOut.(ListFieldOut{ifield})./nbval;
    DataOut.(ListFieldOut{ifield})=reshape(DataOut.(ListFieldOut{ifield}),npy,npx);
end




