%'tps_coeff_field': calculate the thin plate spline (tps) coefficients within subdomains for a field structure
%---------------------------------------------------------------------
% DataOut=tps_coeff_field(DataIn,checkall,Smoothing) 
%
% OUTPUT:
% DataOut: output field structure, reproducing the input field structure DataIn and adding the fields:
%         .Coord_tps
%         .[VarName '_tps'] for each eligible input variable VarName (scalar or vector components)
% errormsg: error message, = '' by default
%
% INPUT:
% DataIn: intput field structure
% checkall:=1 if tps is needed for all fields (a projection mode interp_tps has been chosen),
%          =0 otherwise (tps only needed to get spatial derivatives of scattered data)
% Smoothing parameter: =0 (no smoothing) by default

% called functions:
% 'find_field_cells': analyse the input field structure, grouping the variables  into 'fields' with common coordinates
% 'set_subdomains': sort a set of points defined by scattered coordinates in subdomains, as needed for tps interpolation
% 'tps_coeff': calculate the thin plate spline (tps) coefficients for a single domain.

%=======================================================================
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function [DataOut,errormsg]=tps_coeff_field(DataIn,checkall,Smoothing)     
DataOut=DataIn;%default
if ~exist('Smoothing','var')
Smoothing=0;
end
SubDomainNbPoint=250; %default, estimated nbre of data source points in a subdomain used for tps
if isfield(DataIn,'SubDomain')
    SubDomainNbPoint=DataIn.SubDomain;%old convention
end
if isfield(DataIn,'SubDomainNbPoint')
    SubDomainNbPoint=DataIn.SubDomainNbPoint;%
end
[CellInfo,NbDimArray,errormsg]=find_field_cells(DataIn);
if ~isempty(errormsg)
    errormsg=['tps_coeff_field/find_field_cells/' errormsg];
    return
end
nbtps=0;% indicate the number of tps coordinate sets in the field structure (in general =1)

for icell=1:numel(CellInfo)
    if NbDimArray(icell)>=2 && strcmp(CellInfo{icell}.CoordType,'scattered') %if the coordinates are scattered
        NbCoord=NbDimArray(icell);% dimension of space
        nbtps=nbtps+1;% indicate the number of tps coordinate sets in the field structure (in general =1)
        X=DataIn.(DataIn.ListVarName{CellInfo{icell}.CoordIndex(end)});% value of x coordinate
        Y=DataIn.(DataIn.ListVarName{CellInfo{icell}.CoordIndex(end-1)});% value of y coordinate
        check_interp_tps=false(numel(DataIn.ListVarName),1);
        Index_interp=[];% indices of variables to interpolate
        if isfield(CellInfo{icell},'VarIndex_scalar')%interpolate scalar
            Index_interp=[Index_interp CellInfo{icell}.VarIndex_scalar];
        end
        if isfield(CellInfo{icell},'VarIndex_vector_x')%interpolate vector x component
            Index_interp=[Index_interp CellInfo{icell}.VarIndex_vector_x];
        end
        if isfield(CellInfo{icell},'VarIndex_vector_y')%interpolate vector y component
            Index_interp=[Index_interp CellInfo{icell}.VarIndex_vector_y];
        end
        for iselect=1:numel(Index_interp)
            Attr=DataIn.VarAttribute{Index_interp(iselect)};
            if ~isfield(Attr,'VarIndex_tps')&& (checkall || (isfield(Attr,'ProjModeRequest')&&strcmp(Attr.ProjModeRequest,'interp_tps')))
                check_interp_tps(Index_interp(iselect))=1;
            end
        end
        ListVarInterp=DataIn.ListVarName(check_interp_tps);
        VarIndexInterp=find(check_interp_tps);
        if ~isempty(ListVarInterp)
            % exclude data points marked 'false' for interpolation
            if isfield(CellInfo{icell},'VarIndex_errorflag')
                FF=DataIn.(DataIn.ListVarName{CellInfo{icell}.VarIndex_errorflag});% error flag
                X=X(FF==0);
                Y=Y(FF==0);
                for ilist=1:numel(ListVarInterp)
                    DataIn.(ListVarInterp{ilist})=DataIn.(ListVarInterp{ilist})(FF==0);
                end
            end
            term='';
            if nbtps>1
                term=['_' num2str(nbtps-1)];
            end
            ListNewVar=cell(1,numel(ListVarInterp)+3);
            ListNewVar(1:3)={['SubRange' term],['NbCentre' term],['Coord_tps' term]};
            for ilist=1:numel(ListVarInterp)
                ListNewVar{ilist+3}=[ListVarInterp{ilist} '_tps' term];
            end
            nbvar=numel(DataIn.ListVarName);
            DataOut.ListVarName=[DataIn.ListVarName ListNewVar];
            DataOut.VarDimName=[DataIn.VarDimName {{'nb_coord','nb_bounds',['nb_subdomain' term]}} {['nb_subdomain' term]} ...
                {{['nb_tps' term],'nb_coord',['nb_subdomain' term]}}];
            DataOut.VarAttribute{nbvar+3}.Role='coord_tps';
            [SubRange,NbCentre,IndSelSubDomain] =set_subdomains([X Y],SubDomainNbPoint);% create subdomains for tps
            for isub=1:size(SubRange,3)
                ind_sel=IndSelSubDomain(1:NbCentre(isub),isub);% array indices selected for the subdomain
                DataOut.(['Coord_tps' term])(1:NbCentre(isub),1:2,isub)=[X(ind_sel) Y(ind_sel)];
                DataOut.(['Coord_tps' term])(NbCentre(isub)+1:NbCentre(isub)+3,1:2,isub)=0;%matrix of zeros to complement the matrix Coord_tps (conveninent for file storage)
            end
            for ivar=1:numel(ListVarInterp)
                DataOut.VarDimName{nbvar+3+ivar}={['nb_tps' term],['nb_subdomain' term]};
                DataOut.VarAttribute{nbvar+3+ivar}=DataIn.VarAttribute{CellInfo{icell}.VarIndex_vector_x};%reproduce attributes of velocity
                if ~isfield(DataIn.VarAttribute{VarIndexInterp(ivar)},'Role')
                    DataOut.VarAttribute{nbvar+3+ivar}.Role='scalar_tps';
                else
                    DataOut.VarAttribute{nbvar+3+ivar}.Role=[DataIn.VarAttribute{VarIndexInterp(ivar)}.Role '_tps'];
                end
                DataOut.VarAttribute{VarIndexInterp(ivar)}.VarIndex_tps=nbvar+3+ivar;% indicate the tps correspondance in the source data
            end
            if isfield(DataOut,'ListDimName')%cleaning'
                DataOut=rmfield(DataOut,'ListDimName');
            end
            if isfield(DataOut,'DimValue')%cleaning
                DataOut=rmfield(DataOut,'DimValue');
            end
            DataOut.(['SubRange' term])=SubRange;
            DataOut.(['NbCentre' term])=NbCentre;
            for ilist=1:numel(VarIndexInterp)
                for isub=1:size(SubRange,3)
                    ind_sel=IndSelSubDomain(1:NbCentre(isub),isub);% array indices selected for the subdomain
                    [tild,Var_tps(1:NbCentre(isub)+NbCoord+1,isub)]=tps_coeff([X(ind_sel) Y(ind_sel)],DataIn.(ListVarInterp{ilist})(ind_sel),Smoothing);%calculate the tps coeff in the subdomain
                end
                DataOut.(ListNewVar{ilist+3})=Var_tps;
            end
        end
    end
end

%'set_subdomains': sort a set of points defined by scattered coordinates in subdomains, as needed for tps interpolation
%------------------------------------------------------------------------
% [SubRange,NbCentre,IndSelSubDomain] =set_subdomains(Coord,SubDomainNbPoint)
%
% OUTPUT:
% SubRange(NbCoord,NbSubdomain,2): range (min, max) of the coordinates x and y respectively, for each subdomain
% NbCentre(NbSubdomain): number of source points for each subdomain
% IndSelSubDomain(SubDomainNbPointMax,NbSubdomain): set of indices of the input point array
% selected in each subdomain, =0 beyond NbCentre points
%
% INPUT:
% coord=[X Y]: matrix whose first column is the x coordinates of the input data points, the second column the y coordinates
% SubdomainNbPoint: estimated number of data points whished for each subdomain

%=======================================================================
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function [SubRange,NbCentre,IndSelSubDomain] =set_subdomains(Coord,SubDomainNbPoint)

%% adjust subdomain decomposition
NbVec=size(Coord,1);
NbCoord=size(Coord,2);
MinCoord=min(Coord,[],1);
MaxCoord=max(Coord,[],1);
Range=MaxCoord-MinCoord;
AspectRatio=Range(2)/Range(1);
NbSubDomain=NbVec/SubDomainNbPoint;
NbSubDomainX=max(floor(sqrt(NbSubDomain/AspectRatio)),1);
NbSubDomainY=max(floor(sqrt(NbSubDomain*AspectRatio)),1);
NbSubDomain=NbSubDomainX*NbSubDomainY;
Siz(1)=Range(1)/NbSubDomainX;%width of subdomains
Siz(2)=Range(2)/NbSubDomainY;%height of subdomains
CentreX=linspace(MinCoord(1)+Siz(1)/2,MaxCoord(1)-Siz(1)/2,NbSubDomainX);
CentreY=linspace(MinCoord(2)+Siz(2)/2,MaxCoord(2)-Siz(2)/2,NbSubDomainY);
[CentreX,CentreY]=meshgrid(CentreX,CentreY);
CentreY=reshape(CentreY,1,[]);% Y positions of subdomain centres
CentreX=reshape(CentreX,1,[]);% X positions of subdomain centres

%% default output
SubRange=zeros(NbCoord,2,NbSubDomain);%initialise the positions of subdomains
NbCentre=zeros(1,NbSubDomain);%number of interpolated values per subdomain, =0 by default
%Coord_tps=zeros(NbVec,NbCoord,NbSubDomain);% default positions of the tps source= initial positions of the good vectors sorted by subdomain
check_empty=zeros(1,NbSubDomain);

%% adjust subdomains
for isub=1:NbSubDomain
    SubRange(1,:,isub)=[CentreX(isub)-0.55*Siz(1) CentreX(isub)+0.55*Siz(1)];
    SubRange(2,:,isub)=[CentreY(isub)-0.55*Siz(2) CentreY(isub)+0.55*Siz(2)];
    IndSel_previous=[];
    IndSel=0;
    while numel(IndSel)>numel(IndSel_previous) %increase the subdomain if it contains less than SubDomainNbPoint/4 sources
        IndSel_previous=IndSel;
        IndSel=find(Coord(:,1)>=SubRange(1,1,isub) & Coord(:,1)<=SubRange(1,2,isub) & Coord(:,2)>=SubRange(2,1,isub) & Coord(:,2)<=SubRange(2,2,isub));
        % if no source in the subdomain, skip the subdomain
        if isempty(IndSel)
            check_empty(isub)=1;    
            break
        % if too few selected sources, increase the subrange for next iteration
        elseif numel(IndSel)<SubDomainNbPoint/4 && ~isequal( IndSel,IndSel_previous);
            SubRange(:,1,isub)=SubRange(:,1,isub)-Siz'/4;
            SubRange(:,2,isub)=SubRange(:,2,isub)+Siz'/4;
        else
            break
        end
    end
    NbCentre(isub)=numel(IndSel);
    IndSelSubDomain(1:numel(IndSel),isub)=IndSel;
end


%% remove empty subdomains
ind_empty=find(check_empty);
if ~isempty(ind_empty)
    SubRange(:,:,ind_empty)=[];
    NbCentre(ind_empty)=[];
    IndSelSubDomain(:,ind_empty)=[];
end



