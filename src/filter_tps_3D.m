%'filter_tps': find the thin plate spline coefficients for interpolation-smoothing
%------------------------------------------------------------------------
% [SubRange,NbCentre,Coord_tps,U_tps,V_tps,W_tps,U_smooth,V_smooth,W_smooth,FF] =filter_tps(Coord,U,V,W,SubDomainSize,FieldSmooth,Threshold)
%
% OUTPUT:
% SubRange(NbCoord,2,NbSubdomain): range (min, max) of the coordinates x and y respectively, for each subdomain
% NbCentre(NbSubdomain): number of source points for each subdomain
% FF: false flags preserved from the input, or equal to true for vectors excluded by the difference with the smoothed field
% U_smooth, V_smooth: filtered velocity components at the positions of the initial data
% Coord_tps(NbCentre,NbCoord,NbSubdomain): positions of the tps centres
% U_tps,V_tps: weight of the tps centers for each subdomain
% to get the interpolated field values, use the function calc_field.m
%
% INPUT:
% coord=[X Y]: matrix whose first column is the x coordinates of the initial data, the second column the y coordiantes
% U,V, possibly W: set of velocity components of the initial data
% SubdomainSize: estimated number of data points in each subdomain, choose a number > 125 (must be >= 12 for convergence of tps after division by 4)
% FieldSmooth: smoothing parameter
% Threshold: max diff accepted between smoothed and initial data


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

function [SubRange,NbCentre,Coord_tps,U_tps,V_tps,W_tps,U_smooth,V_smooth,W_smooth,FF] =filter_tps_3D(Coord,U,V,W,SubDomainSize,FieldSmooth,Threshold)

%% adjust subdomain decomposition
warning off
% [npz,npy,npx]=size(Coord_x);
% Coord=[Coord_x Coord_y Coord_z];
NbVec=size(Coord,1);% nbre of vectors in the field to interpolate
NbCoord=3;% space dimension,Coord(:,1)= x,Coord(:,2)=  y , Coord(:,3)=  z
MinCoord=min(Coord,[],1);%lower coordinate bounds
MaxCoord=max(Coord,[],1);%upper coordinate bounds
Range=MaxCoord-MinCoord;%along eacch coordiante x,y,z
Cellmesh=(10*prod(Range)*SubDomainSize/NbVec)^(1/3);
NbSubDomainX=ceil(Range(1)/Cellmesh);
NbSubDomainY=ceil(Range(2)/Cellmesh);
NbSubDomainZ=ceil(10*Range(3)/Cellmesh);

% NbSubDomain=NbVec/SubDomainSize;% estimated number of subdomains
% NbSubDomainX=max(floor(sqrt(NbSubDomain/(AspectRatio(1)*AspectRatio(2))),1);% estimated number of subdomains in x
% NbSubDomainY=max(floor(sqrt(NbSubDomain*AspectRatio)),1);% estimated number of subdomains in y
% NbSubDomainZ=max(floor(sqrt(NbSubDomain*AspectRatio)),1);% estimated number of subdomains in y
NbSubDomain=NbSubDomainX*NbSubDomainY*NbSubDomainZ;% new estimated number of subdomains in a matrix shape partition in subdomains
Siz(1)=Range(1)/NbSubDomainX;%width of subdomains
Siz(2)=Range(2)/NbSubDomainY;%height of subdomains
Siz(3)=Range(3)/NbSubDomainZ;%height of subdomains
CentreX=linspace(MinCoord(1)+Siz(1)/2,MaxCoord(1)-Siz(1)/2,NbSubDomainX);% X positions of subdomain centres
CentreY=linspace(MinCoord(2)+Siz(2)/2,MaxCoord(2)-Siz(2)/2,NbSubDomainY);% Y positions of subdomain centres
CentreZ=linspace(MinCoord(3)+Siz(3)/2,MaxCoord(3)-Siz(3)/2,NbSubDomainZ);% Y positions of subdomain centres
[CentreX,CentreY,CentreZ]=meshgrid(CentreX,CentreY,CentreZ);
CentreX=reshape(CentreX,1,[]);% X positions of subdomain centres
CentreY=reshape(CentreY,1,[]);% Y positions of subdomain centres
CentreZ=reshape(CentreZ,1,[]);% Z positions of subdomain centres

%% smoothing parameter: CHANGED 03 May 2024 TO GET RESULTS INDEPENDENT OF SUBDOMAINSIZE
%smoothing=Siz(1)*Siz(2)*FieldSmooth/1000%old calculation before 03 May < r1129
NbVecSub=NbVec/NbSubDomain;% refined estimation of the nbre of vectors per subdomain
smoothing=(Siz(1)*Siz(2)*Siz(3)/NbVecSub)^(1/3)*FieldSmooth;%optimum smoothing increase as the typical mesh size =sqrt(SizX*SizY/NbVecSub)^1/2
Threshold=Threshold*Threshold;% take the square of the threshold to work with the modulus squared (not done before r1154)

%% default output
SubRange=zeros(NbCoord,2,NbSubDomain);%initialise the boundaries of subdomains
Coord_tps=zeros(1,NbCoord,NbSubDomain);% initialize coordinates of interpolated data
U_tps=zeros(1,NbSubDomain);% initialize  interpolated u component
V_tps=zeros(1,NbSubDomain);% initialize interpolated v component
W_tps=zeros(1,NbSubDomain);% initialize interpolated v component
NbCentre=zeros(1,NbSubDomain);%number of interpolated field values per subdomain, =0 by default
U_smooth=zeros(NbVec,1); % smoothed velocity U at the initial positions
V_smooth=zeros(NbVec,1);% smoothed velocity V at the initial positions
W_smooth=zeros(NbVec,1);%default (2 component case)
FF=false(NbVec,1);%false flag=0 (false) by default
nb_select=zeros(NbVec,1);
check_empty=false(1,NbSubDomain);

%% calculate tps coeff in each subdomain
for isub=1:NbSubDomain
    SubRange(1,:,isub)=[CentreX(isub)-0.55*Siz(1) CentreX(isub)+0.55*Siz(1)];%bounds of subdomain #isub in x coordinate
    SubRange(2,:,isub)=[CentreY(isub)-0.55*Siz(2) CentreY(isub)+0.55*Siz(2)];%bounds of subdomain #isub in y coordinate
    SubRange(3,:,isub)=[CentreZ(isub)-0.55*Siz(3) CentreZ(isub)+0.55*Siz(3)];%bounds of subdomain #isub in y coordinate
    ind_sel=0;%initialize set of vector indices in the subdomain
    %increase iteratively the subdomain if it contains less than
    %SubDomainNbVec/4 source vectors, until possibly cover the whole domain:check_partial_domain=false
    check_partial_domain= true;
    while check_partial_domain
        %check_next=false;% test to go to next iteration with wider subdomain
        ind_sel_previous=ind_sel;% record the set of selected vector indices for next iteration
        ind_sel= find(~FF & Coord(:,1)>=SubRange(1,1,isub) & Coord(:,1)<=SubRange(1,2,isub)...
            & Coord(:,2)>=SubRange(2,1,isub) & Coord(:,2)<=SubRange(2,2,isub)&...
            Coord(:,3)>=SubRange(3,1,isub) & Coord(:,3)<=SubRange(3,2,isub));% indices of vectors in the subdomain #isub
         check_partial_domain=sum(SubRange(:,1,isub)> MinCoord' | SubRange(:,2,isub)< MaxCoord');
        % isub
        % numel(ind_sel)

        % if no vector in the subdomain  #isub, skip the subdomain
        if isempty(ind_sel)
            check_empty(isub)=true;
            break

            % if too few selected vectors, increase the subrange for next iteration by 50 % in each direction
        elseif numel(ind_sel)<SubDomainSize/4 && ~isequal( ind_sel,ind_sel_previous)&& check_partial_domain
            % SubRange(:,1,isub)=SubRange(:,1,isub)-Siz'/4;
            % SubRange(:,2,isub)=SubRange(:,2,isub)+Siz'/4;
            SubRange(:,1,isub)=1.25*SubRange(:,1,isub)-0.25*SubRange(:,2,isub);
            SubRange(:,2,isub)=-0.25*SubRange(:,1,isub)+1.25*SubRange(:,2,isub);

            % if subdomain includes enough vectors, perform tps interpolation
        else
            [U_smooth_sub,U_tps_sub]=tps_coeff(Coord(ind_sel,:),U(ind_sel),smoothing);
            [V_smooth_sub,V_tps_sub]=tps_coeff(Coord(ind_sel,:),V(ind_sel),smoothing);
            [W_smooth_sub,W_tps_sub]=tps_coeff(Coord(ind_sel,:),W(ind_sel),smoothing);
            UDiff=U_smooth_sub-U(ind_sel);% difference between interpolated U component and initial value
            VDiff=V_smooth_sub-V(ind_sel);% difference between interpolated V component and initial value
            WDiff=W_smooth_sub-W(ind_sel);% difference between interpolated V component and initial value
            NormDiff=UDiff.*UDiff+VDiff.*VDiff+WDiff.*WDiff;% Square of difference norm
            ind_ind_sel=1:numel(ind_sel);%default
            if exist('Threshold','var')&&~isempty(Threshold)
                FF(ind_sel)=(NormDiff>Threshold);%put FF value to 1 to identify the criterium of elimmination
                ind_ind_sel=find(~FF(ind_sel)); % select the indices of remaining vectors in the subset of ind_sel vectors
            end
            % if no value exceeds threshold, the result is recorded

            if isequal(numel(ind_ind_sel),numel(ind_sel))
                x_width=(SubRange(1,2,isub)-SubRange(1,1,isub))/pi;
                y_width=(SubRange(2,2,isub)-SubRange(2,1,isub))/pi;
                z_width=(SubRange(3,2,isub)-SubRange(3,1,isub))/pi;
                x_dist=(Coord(ind_sel,1)-CentreX(isub))/x_width;% relative x distance to the retangle centre
                y_dist=(Coord(ind_sel,2)-CentreY(isub))/y_width;% relative ydistance to the retangle centre
                z_dist=(Coord(ind_sel,3)-CentreZ(isub))/z_width;% relative ydistance to the retangle centre
                weight=cos(x_dist).*cos(y_dist).*cos(z_dist);%weighting fct =1 at the rectangle center and 0 at edge
                U_smooth(ind_sel)=U_smooth(ind_sel)+weight.*U_smooth_sub;
                V_smooth(ind_sel)=V_smooth(ind_sel)+weight.*V_smooth_sub;
                W_smooth(ind_sel)=W_smooth(ind_sel)+weight.*W_smooth_sub;
                NbCentre(isub)=numel(ind_sel);
                Coord_tps(1:NbCentre(isub),:,isub)=Coord(ind_sel,:);
                U_tps(1:NbCentre(isub)+4,isub)=U_tps_sub;
                V_tps(1:NbCentre(isub)+4,isub)=V_tps_sub;
                W_tps(1:NbCentre(isub)+4,isub)=W_tps_sub;
                nb_select(ind_sel)=nb_select(ind_sel)+weight;
                display(['tps done with ' num2str(numel(ind_sel)) ' vectors in subdomain # ' num2str(isub)  ' among ' num2str(NbSubDomain)])
                break
            % if too few selected vectors, increase the subrange for next iteration by 50% in each direction
            elseif numel(ind_ind_sel)<SubDomainSize/4 && ~isequal( ind_sel,ind_sel_previous)&& check_partial_domain
                % SubRange(:,1,isub)=SubRange(:,1,isub)-Siz'/4;
                % SubRange(:,2,isub)=SubRange(:,2,isub)+Siz'/4;
                SubRange(:,1,isub)=1.25*SubRange(:,1,isub)-0.25*SubRange(:,2,isub);
                SubRange(:,2,isub)=-0.25*SubRange(:,1,isub)+1.25*SubRange(:,2,isub);
            % else interpolation-smoothing is done again with the selected vectors
            else
                [U_smooth_sub,U_tps_sub]=tps_coeff(Coord(ind_sel(ind_ind_sel),:),U(ind_sel(ind_ind_sel)),smoothing);
                [V_smooth_sub,V_tps_sub]=tps_coeff(Coord(ind_sel(ind_ind_sel),:),V(ind_sel(ind_ind_sel)),smoothing);
                [W_smooth_sub,W_tps_sub]=tps_coeff(Coord(ind_sel(ind_ind_sel),:),W(ind_sel(ind_ind_sel)),smoothing);
                x_width=(SubRange(1,2,isub)-SubRange(1,1,isub))/pi;
                y_width=(SubRange(2,2,isub)-SubRange(2,1,isub))/pi;
                z_width=(SubRange(3,2,isub)-SubRange(3,1,isub))/pi;
                x_dist=(Coord(ind_sel(ind_ind_sel),1)-CentreX(isub))/x_width;% relative x distance to the retangle centre
                y_dist=(Coord(ind_sel(ind_ind_sel),2)-CentreY(isub))/y_width;% relative ydistance to the retangle centre
                  z_dist=(Coord(ind_sel(ind_ind_sel),3)-CentreZ(isub))/z_width;% relative ydistance to the retangle centre
                weight=cos(x_dist).*cos(y_dist).*cos(z_dist);%weighting fct =1 at the rectangle center and 0 at edge
                %weight=1;
                U_smooth(ind_sel(ind_ind_sel))=U_smooth(ind_sel(ind_ind_sel))+weight.*U_smooth_sub;
                V_smooth(ind_sel(ind_ind_sel))=V_smooth(ind_sel(ind_ind_sel))+weight.*V_smooth_sub;
                   W_smooth(ind_sel(ind_ind_sel))=W_smooth(ind_sel(ind_ind_sel))+weight.*W_smooth_sub;
                NbCentre(isub)=numel(ind_ind_sel);
                Coord_tps(1:NbCentre(isub),:,isub)=Coord(ind_sel(ind_ind_sel),:);
                U_tps(1:NbCentre(isub)+4,isub)=U_tps_sub;
                V_tps(1:NbCentre(isub)+4,isub)=V_tps_sub;
                W_tps(1:NbCentre(isub)+4,isub)=W_tps_sub;
                nb_select(ind_sel(ind_ind_sel))=nb_select(ind_sel(ind_ind_sel))+weight;
                display(['tps redone with ' num2str(numel(ind_sel)) ' vectors after elimination of ' num2str(numel(ind_sel)-numel(ind_ind_sel)) ' erratic vectors in subdomain # ' num2str(isub) ' among ' num2str(NbSubDomain)])
                break
            end
        end
         % check_next=true;% go to next iteration with wider subdomain
    end% end of while loop fo increasing subdomain size
    if ~check_partial_domain && isub<NbSubDomain% if the while loop proceed to the end, the whole domain size has been covered
        check_empty(isub+1:end)=true;
        break %the whole domain has been already covered, no need for new subdomains
    end
end

%% remove empty subdomains
ind_empty=find(check_empty);
if ~isempty(ind_empty)
    SubRange(:,:,ind_empty)=[];
    Coord_tps(:,:,ind_empty)=[];
    U_tps(:,ind_empty)=[];
    V_tps(:,ind_empty)=[];
    W_tps(:,ind_empty)=[];
    NbCentre(ind_empty)=[];
end

%% final adjustments
nb_select(nb_select==0)=1;
U_smooth=U_smooth./nb_select;% take the average at the intersection of several subdomains
V_smooth=V_smooth./nb_select;
W_smooth=W_smooth./nb_select;

%eliminate the vectors with diff>threshold not yet eliminated
if exist('Threshold','var')&&~isempty(Threshold)
UDiff=U_smooth-U;% difference between interpolated U component and initial value
VDiff=V_smooth-V;% difference between interpolated V component and initial value
WDiff=W_smooth-W;% difference between interpolated V component and initial value
NormDiff=UDiff.*UDiff+VDiff.*VDiff+WDiff.*WDiff;% Square of difference norm
FF(NormDiff>Threshold)=true;%put FF value to 1 to identify the criterium of elimmination
end

U_smooth(FF)=U(FF);% set to the initial values the eliminated vectors (flagged as false)
V_smooth(FF)=V(FF);
W_smooth(FF)=W(FF);
fill=zeros(NbCoord+1,NbCoord,size(SubRange,3)); %matrix of zeros to complement the matrix Data.Civ1_Coord_tps (conveninent for file storage)
Coord_tps=cat(1,Coord_tps,fill);


