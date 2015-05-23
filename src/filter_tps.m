%'filter_tps': find the thin plate spline coefficients for interpolation-smoothing
%------------------------------------------------------------------------
% [SubRange,NbCentre,Coord_tps,U_tps,V_tps,W_tps,U_smooth,V_smooth,W_smooth,FF] =filter_tps(Coord,U,V,W,SubDomainSize,Rho,Threshold)
%
% OUTPUT:
% SubRange(NbCoord,NbSubdomain,2): range (min, max) of the coordiantes x and y respectively, for each subdomain
% NbCentre(NbSubdomain): number of source points for each subdomain
% FF: false flags
% U_smooth, V_smooth: filtered velocity components at the positions of the initial data
% Coord_tps(NbCentre,NbCoord,NbSubdomain): positions of the tps centres
% U_tps,V_tps: weight of the tps for each subdomain
% to get the interpolated field values, use the function calc_field.m
%
% INPUT:
% coord=[X Y]: matrix whose first column is the x coordinates of the initial data, the second column the y coordiantes
% U,V: set of velocity components of the initial data
% Rho: smoothing parameter
% Threshold: max diff accepted between smoothed and initial data 
% Subdomain: estimated number of data points in each subdomain

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

function [SubRange,NbCentre,Coord_tps,U_tps,V_tps,W_tps,U_smooth,V_smooth,W_smooth,FF] =filter_tps(Coord,U,V,W,SubDomainSize,Rho,Threshold)

%% adjust subdomain decomposition
warning off
NbVec=size(Coord,1);% nbre of vectors in the field to interpolate
NbCoord=size(Coord,2);% space dimension
MinCoord=min(Coord,[],1);%lower coordinate bounds
MaxCoord=max(Coord,[],1);%upper coordinate bounds
Range=MaxCoord-MinCoord;
AspectRatio=Range(2)/Range(1);
NbSubDomain=NbVec/SubDomainSize;% estimated number of subdomains
NbSubDomainX=max(floor(sqrt(NbSubDomain/AspectRatio)),1);% estimated number of subdomains in x 
NbSubDomainY=max(floor(sqrt(NbSubDomain*AspectRatio)),1);% estimated number of subdomains in y
NbSubDomain=NbSubDomainX*NbSubDomainY;% new estimated number of subdomains in a matrix shape partition in subdomains
Siz(1)=Range(1)/NbSubDomainX;%width of subdomains
Siz(2)=Range(2)/NbSubDomainY;%height of subdomains
CentreX=linspace(MinCoord(1)+Siz(1)/2,MaxCoord(1)-Siz(1)/2,NbSubDomainX);% X positions of subdomain centres
CentreY=linspace(MinCoord(2)+Siz(2)/2,MaxCoord(2)-Siz(2)/2,NbSubDomainY);% Y positions of subdomain centres
[CentreX,CentreY]=meshgrid(CentreX,CentreY);
CentreX=reshape(CentreX,1,[]);% X positions of subdomain centres
CentreY=reshape(CentreY,1,[]);% Y positions of subdomain centres

%% smoothing parameter
rho=Siz(1)*Siz(2)*Rho/1000;%optimum rho increase as the area of the subdomain (division by 1000 to reach good values with the default GUI input)

%% default output
SubRange=zeros(NbCoord,2,NbSubDomain);%initialise the boundaries of subdomains
Coord_tps=zeros(1,NbCoord,NbSubDomain);% initialize coordinates of interpolated data
U_tps=zeros(1,NbSubDomain);% initialize  interpolated u component
V_tps=zeros(1,NbSubDomain);% initialize interpolated v component
NbCentre=zeros(1,NbSubDomain);%number of interpolated field values per subdomain, =0 by default
W_tps=[];%default (2 component case)
U_smooth=zeros(NbVec,1); % smoothed velocity U at the initial positions
V_smooth=zeros(NbVec,1);% smoothed velocity V at the initial positions
W_smooth=[];%default (2 component case)
FF=zeros(NbVec,1);
nb_select=zeros(NbVec,1);
check_empty=zeros(1,NbSubDomain);


%% calculate tps coeff in each subdomain
for isub=1:NbSubDomain
    SubRange(1,:,isub)=[CentreX(isub)-0.55*Siz(1) CentreX(isub)+0.55*Siz(1)];%bounds of subdomain #isub in x coordinate
    SubRange(2,:,isub)=[CentreY(isub)-0.55*Siz(2) CentreY(isub)+0.55*Siz(2)];%bounds of subdomain #isub in y coordinate
    ind_sel_previous=[];
    ind_sel=0;%initialize set of vector indices in the subdomain
    %increase iteratively the subdomain if it contains less than SubDomainNbVec/4 source vectors
    while numel(ind_sel)>numel(ind_sel_previous)
        ind_sel_previous=ind_sel;% record the set of selected vector indices for next iteration
        ind_sel=find(Coord(:,1)>=SubRange(1,1,isub) & Coord(:,1)<=SubRange(1,2,isub) & Coord(:,2)>=SubRange(2,1,isub) & Coord(:,2)<=SubRange(2,2,isub));
        % if no vector in the subdomain  #isub, skip the subdomain
        if isempty(ind_sel)
            check_empty(isub)=1;
            break %  go to next subdomain
        % if too few selected vectors, increase the subrange for next iteration
        elseif numel(ind_sel)<SubDomainSize/4 && ~isequal( ind_sel,ind_sel_previous);
            SubRange(:,1,isub)=SubRange(:,1,isub)-Siz'/4;
            SubRange(:,2,isub)=SubRange(:,2,isub)+Siz'/4;
        % subdomain includes enough vectors, perform tps interpolation
        else
            [U_smooth_sub,U_tps_sub]=tps_coeff(Coord(ind_sel,:),U(ind_sel),rho);
            [V_smooth_sub,V_tps_sub]=tps_coeff(Coord(ind_sel,:),V(ind_sel),rho);
            UDiff=U_smooth_sub-U(ind_sel);% difference between interpolated U component and initial value
            VDiff=V_smooth_sub-V(ind_sel);% difference between interpolated V component and initial value
            NormDiff=UDiff.*UDiff+VDiff.*VDiff;% Square of difference norm
            ind_ind_sel=1:numel(ind_sel);%default
            if exist('Threshold','var')&&~isempty(Threshold)
                FF(ind_sel)=20*(NormDiff>Threshold);%put FF value to 20 to identify the criterium of elimmination
                ind_ind_sel=find(FF(ind_sel)==0); % select the indices of ind_sel corresponding to the remaining vectors
            end
            % if no value exceeds threshold, the result is recorded
            if isequal(numel(ind_ind_sel),numel(ind_sel))
                U_smooth(ind_sel)=U_smooth(ind_sel)+U_smooth_sub;
                V_smooth(ind_sel)=V_smooth(ind_sel)+V_smooth_sub;
                NbCentre(isub)=numel(ind_sel);
                Coord_tps(1:NbCentre(isub),:,isub)=Coord(ind_sel,:);
                U_tps(1:NbCentre(isub)+3,isub)=U_tps_sub;
                V_tps(1:NbCentre(isub)+3,isub)=V_tps_sub;
                nb_select(ind_sel)=nb_select(ind_sel)+1;
                display(['tps done in subdomain # ' num2str(isub)  ' among ' num2str(NbSubDomain)])
                break
            % if too few selected vectors, increase the subrange for next iteration
            elseif numel(ind_ind_sel)<SubDomainSize/4 && ~isequal( ind_sel,ind_sel_previous);
                SubRange(:,1,isub)=SubRange(:,1,isub)-Siz'/4;
                SubRange(:,2,isub)=SubRange(:,2,isub)+Siz'/4;
            % else interpolation-smoothing is done again with the selected vectors
            else
                [U_smooth_sub,U_tps_sub]=tps_coeff(Coord(ind_sel(ind_ind_sel),:),U(ind_sel(ind_ind_sel)),rho);
                [V_smooth_sub,V_tps_sub]=tps_coeff(Coord(ind_sel(ind_ind_sel),:),V(ind_sel(ind_ind_sel)),rho);
                U_smooth(ind_sel(ind_ind_sel))=U_smooth(ind_sel(ind_ind_sel))+U_smooth_sub;
                V_smooth(ind_sel(ind_ind_sel))=V_smooth(ind_sel(ind_ind_sel))+V_smooth_sub;
                NbCentre(isub)=numel(ind_ind_sel);
                Coord_tps(1:NbCentre(isub),:,isub)=Coord(ind_sel(ind_ind_sel),:);
                U_tps(1:NbCentre(isub)+3,isub)=U_tps_sub;
                V_tps(1:NbCentre(isub)+3,isub)=V_tps_sub;
                nb_select(ind_sel(ind_ind_sel))=nb_select(ind_sel(ind_ind_sel))+1;
                display(['tps redone after elimination of erratic vectors in subdomain # ' num2str(isub) ' among ' num2str(NbSubDomain)])
                break
            end
        end
    end
end

%% remove empty subdomains
ind_empty=find(check_empty);
if ~isempty(ind_empty)
    SubRange(:,:,ind_empty)=[];
    Coord_tps(:,:,ind_empty)=[];
    U_tps(:,ind_empty)=[];
    V_tps(:,ind_empty)=[];
    NbCentre(ind_empty)=[];
end

%% final adjustments
nb_select(nb_select==0)=1;
U_smooth=U_smooth./nb_select;% take the average at the intersection of several subdomains
V_smooth=V_smooth./nb_select;
fill=zeros(NbCoord+1,NbCoord,size(SubRange,3)); %matrix of zeros to complement the matrix Data.Civ1_Coord_tps (conveninent for file storage)
Coord_tps=cat(1,Coord_tps,fill);

