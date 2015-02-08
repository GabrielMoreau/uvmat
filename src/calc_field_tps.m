
%'calc_field_tps': defines fields (velocity, vort, div...) from civ data and calculate them with tps interpolation
%---------------------------------------------------------------------
% [DataOut,VarAttribute,errormsg]=calc_field_tps(Coord_tps,NbCentre,SubRange,FieldVar,FieldName,Coord_interp)
%
% OUTPUT:
% DataOut: structure representing the output fields
% VarAttribute: cell array of structures coontaining the variable attributes 
% errormsg: error msg , = '' by default
%
% INPUT:
% Coord_tps: coordinates of the centres, of dimensions [nb_point,nb_coord,nb_subdomain], where 
%            nb_point is the max number of data point in a subdomain,
%            nb_coord the space dimension, 
%            nb_subdomain the nbre of subdomains used for tps
% NbCentre: nbre of tps centres for each subdomain, of dimension nb_subdomain
% SubRange: coordinate range for each subdomain, of dimensions [nb_coord,2,nb_subdomain]
% FieldVar: array representing the input fields as tps weights with dimension (nbvec_sub+3,NbSubDomain,nb_dim)
%              nbvec_sub= max nbre of vectors in a subdomain  
%             NbSubDomain =nbre of subdomains
%             nb_dim: nbre of dimensions for vector components (x-> 1, y->2)
% FieldName: cell array representing the list of operations (eg div(U,V), rot(U,V))
% Coord_interp: coordinates of sites on which the fields need to be calculated of dimensions 
%            [nb_site,nb_coord] for an array of interpolation sites
%            [nb_site_y,nb_site_x,nb_coord] for interpolation on a plane grid of size [nb_site_y,nb_site_x]

%=======================================================================
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function [DataOut,VarAttribute,errormsg]=calc_field_tps(Coord_tps,NbCentre,SubRange,FieldVar,FieldName,Coord_interp)

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
check_vec=0;
check_remove=false(size(FieldName));
VarAttribute={};
for ilist=1:length(FieldName)
    FieldNameType=regexprep(FieldName{ilist},'(.+','');% detect the char string before the parenthesis
    VarAttributeNew={};
    switch FieldNameType
        case 'vec'
            check_grid=1;
            DataOut.U=zeros(nb_sites,1);
            DataOut.V=zeros(nb_sites,1);
            VarAttributeNew{1}.Role='vector_x';
            VarAttributeNew{2}.Role='vector_y';
            check_vec=1;
        case {'U','V'}
            if check_vec% no new data needed 
                check_remove(ilist)=1;
            else
            check_grid=1;
            DataOut.(FieldNameType)=zeros(nb_sites,1);
            VarAttributeNew{1}.Role='scalar';
            end
        case 'norm'
            check_grid=1;
            DataOut.(FieldNameType)=zeros(nb_sites,1);
            VarAttributeNew{1}.Role='scalar';
        case {'curl','div','strain'}
            check_der=1;
            DataOut.(FieldNameType)=zeros(nb_sites,1);
            VarAttributeNew{1}.Role='scalar';
    end
    VarAttribute=[VarAttribute VarAttributeNew];
end
Attr_FF.Role='errorflag';
VarAttribute=[VarAttribute {Attr_FF}];
FieldName(check_remove)=[];

%% loop on subdomains
for isub=1:NbSubDomain
    nbvec_sub=NbCentre(isub);
    check_range=(Coord_interp >=ones(nb_sites,1)*SubRange(:,1,isub)' & Coord_interp<=ones(nb_sites,1)*SubRange(:,2,isub)');
    ind_sel=find(sum(check_range,2)==nb_coord);
    nbval(ind_sel)=nbval(ind_sel)+1;% records the number of values for eacn interpolation point (in case of subdomain overlap)
    if check_grid
        EM = tps_eval(Coord_interp(ind_sel,:),Coord_tps(1:nbvec_sub,:,isub));%kernels for calculating the velocity from tps 'sources'
    end
    if check_der
        [EMDX,EMDY] = tps_eval_dxy(Coord_interp(ind_sel,:),Coord_tps(1:nbvec_sub,:,isub));%kernels for calculating the spatial derivatives from tps 'sources'
    end
    for ilist=1:length(FieldName)
        %Operator{ilist}='';%default empty operator (vec, norm,...)
        %r=regexp(FieldName{ilist},'(?<Operator>(^vec|^norm|^curl|^div|^strain))\((?<UName>.+),(?<VName>.+)\)$','names');% TODO, replace U, V
        switch FieldName{ilist}
            case 'vec(U,V)'
%                 ListVar=[ListVar {'U', 'V'}];
%                 VarAttribute{var_count+1}.Role='vector_x';
%                 VarAttribute{var_count+2}.Role='vector_y';
                DataOut.U(ind_sel)=DataOut.U(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,1);
                DataOut.V(ind_sel)=DataOut.V(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,2);
            case 'U'
%                 ListVar=[ListVar {'U'}];
%                 VarAttribute{var_count+1}.Role='scalar';
                DataOut.U(ind_sel)=DataOut.U(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,1);
            case 'V'
%                 ListVar=[ListVar {'V'}];
%                 VarAttribute{var_count+1}.Role='scalar';
                DataOut.V(ind_sel)=DataOut.V(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,2);
            case 'norm(U,V)'
%                 ListVar=[ListVar {'norm'}];
%                 VarAttribute{var_count+1}.Role='scalar';
                U=DataOut.U(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,1);
                V=DataOut.V(ind_sel)+EM *FieldVar(1:nbvec_sub+3,isub,2);
                DataOut.norm(ind_sel)=sqrt(U.*U+V.*V);
            case 'curl(U,V)'
%                 ListVar=[ListVar {'curl'}];
%                 VarAttribute{var_count+1}.Role='scalar';
                DataOut.curl(ind_sel)=DataOut.curl(ind_sel)-EMDY *FieldVar(1:nbvec_sub+3,isub,1)+EMDX *FieldVar(1:nbvec_sub+3,isub,2);
            case 'div(U,V)'
%                 ListVar=[ListVar {'div'}];
%                 VarAttribute{var_count+1}.Role='scalar';
                DataOut.div(ind_sel)=DataOut.div(ind_sel)+EMDX*FieldVar(1:nbvec_sub+3,isub,1)+EMDY *FieldVar(1:nbvec_sub+3,isub,2);
            case 'strain(U,V)'
%                 ListVar=[ListVar {'strain'}];
%                 VarAttribute{var_count+1}.Role='scalar';
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




