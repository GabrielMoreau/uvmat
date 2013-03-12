%'filter_tps': find the thin plate spline coefficients for interpolation-smoothing
%------------------------------------------------------------------------
% [SubRange,NbCentres,Coord_tps,U_tps,V_tps,W_tps,U_smooth,V_smooth,W_smooth,FF] =filter_tps(Coord,U,V,W,SubDomain,Rho,Threshold)
%
% OUTPUT:
% SubRange(NbCoord,NbSubdomain,2): range (min, max) of the coordiantes x and y respectively, for each subdomain
% NbCentres(NbSubdomain): number of source points for each subdomain
% FF: false flags
% U_smooth, V_smooth: filtered velocity components at the positions of the initial data
% Coord_tps(NbCentres,NbCoord,NbSubdomain): positions of the tps centres
% U_tps,V_tps: weight of the tps for each subdomain
% to get the interpolated field values, use the function calc_field.m
%
% INPUT:
% coord=[X Y]: matrix whose first column is the x coordinates of the initial data, the second column the y coordiantes
% U,V: set of velocity components of the initial data
% Rho: smoothing parameter
% Threshold: max diff accepted between smoothed and initial data 
% Subdomain: estimated number of data points in each subdomain

function [SubRange,NbCentres,Coord_tps,U_tps,V_tps,W_tps,U_smooth,V_smooth,W_smooth,FF] =filter_tps(Coord,U,V,W,SubDomain,Rho,Threshold)

%% adjust subdomain decomposition
warning off
NbVec=size(Coord,1);
NbCoord=size(Coord,2);
MinCoord=min(Coord,[],1);%lower coordinate bounds
MaxCoord=max(Coord,[],1);%upper coordinate bounds
Range=MaxCoord-MinCoord;
AspectRatio=Range(2)/Range(1);
NbSubDomain=NbVec/SubDomain;
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

%% smoothing parameter
rho=Siz(1)*Siz(2)*Rho/1000;%optimum rho increase as the area of the subdomain (division by 1000 to reach good values with the default GUI input)

%% default output
SubRange=zeros(NbCoord,2,NbSubDomain);%initialise the positions of subdomains
NbCentres=zeros(1,NbSubDomain);%number of interpolated values per subdomain, =0 by default
%Coord_tps=zeros(NbVec,NbCoord,NbSubDomain);% default positions of the tps source= initial positions of the good vectors sorted by subdomain
%U_tps=zeros(NbVec,NbSubDomain);%default spline
%V_tps=zeros(NbVec,NbSubDomain);%default spline
W_tps=[];%default (2 component case)
U_smooth=zeros(NbVec,1); % smoothed velocity U at the initial positions
V_smooth=zeros(NbVec,1);% smoothed velocity V at the initial positions
W_smooth=[];%default (2 component case)
FF=zeros(NbVec,1);
nb_select=zeros(NbVec,1);
check_empty=zeros(1,NbSubDomain);

%% calculate tps coeff in each subdomain
for isub=1:NbSubDomain
    SubRange(1,:,isub)=[CentreX(isub)-0.55*Siz(1) CentreX(isub)+0.55*Siz(1)];
    SubRange(2,:,isub)=[CentreY(isub)-0.55*Siz(2) CentreY(isub)+0.55*Siz(2)];
    ind_sel_previous=[];
    ind_sel=0;
    %increase iteratively the subdomain if it contains less than SubDomainNbVec/4 source vectors
    while numel(ind_sel)>numel(ind_sel_previous)
        ind_sel_previous=ind_sel;
        ind_sel=find(Coord(:,1)>=SubRange(1,1,isub) & Coord(:,1)<=SubRange(1,2,isub) & Coord(:,2)>=SubRange(2,1,isub) & Coord(:,2)<=SubRange(2,2,isub));
        % if no vector in the subdomain, skip the subdomain
        if isempty(ind_sel)
            check_empty(isub)=1;
            U_tps(1,isub)=0;%define U_tps and V_tps by default
            V_tps(1,isub)=0;
            break
            % if too few selected vectors, increase the subrange for next iteration
        elseif numel(ind_sel)<SubDomain/4 && ~isequal( ind_sel,ind_sel_previous);
            SubRange(:,1,isub)=SubRange(:,1,isub)-Siz'/4;
            SubRange(:,2,isub)=SubRange(:,2,isub)+Siz'/4;
        else
            [U_smooth_sub,U_tps_sub]=tps_coeff(Coord(ind_sel,:),U(ind_sel),rho);
            [V_smooth_sub,V_tps_sub]=tps_coeff(Coord(ind_sel,:),V(ind_sel),rho);
            UDiff=U_smooth_sub-U(ind_sel);
            VDiff=V_smooth_sub-V(ind_sel);
            NormDiff=UDiff.*UDiff+VDiff.*VDiff;
            ind_ind_sel=1:numel(ind_sel);%default
            if exist('Threshold','var')
                FF(ind_sel)=20*(NormDiff>Threshold);%put FF value to 20 to identify the criterium of elimmination
                ind_ind_sel=find(FF(ind_sel)==0); % select the indices of ind_sel corresponding to the remaining vectors
            end
            % if no value exceeds threshold, the result is recorded
            if isequal(numel(ind_ind_sel),numel(ind_sel))
                U_smooth(ind_sel)=U_smooth(ind_sel)+U_smooth_sub;
                V_smooth(ind_sel)=V_smooth(ind_sel)+V_smooth_sub;
                NbCentres(isub)=numel(ind_sel);
                Coord_tps(1:NbCentres(isub),:,isub)=Coord(ind_sel,:);
                U_tps(1:NbCentres(isub)+3,isub)=U_tps_sub;
                V_tps(1:NbCentres(isub)+3,isub)=V_tps_sub;
                nb_select(ind_sel)=nb_select(ind_sel)+1;
                display('good')
                break
                % if too few selected vectors, increase the subrange for next iteration
            elseif numel(ind_ind_sel)<SubDomain/4 && ~isequal( ind_sel,ind_sel_previous);
                SubRange(:,1,isub)=SubRange(:,1,isub)-Siz'/4;
                SubRange(:,2,isub)=SubRange(:,2,isub)+Siz'/4;
                % else interpolation-smoothing is done again with the selected vectors
            else
                [U_smooth_sub,U_tps_sub]=tps_coeff(Coord(ind_sel(ind_ind_sel),:),U(ind_sel(ind_ind_sel)),rho);
                [V_smooth_sub,V_tps_sub]=tps_coeff(Coord(ind_sel(ind_ind_sel),:),V(ind_sel(ind_ind_sel)),rho);
                U_smooth(ind_sel(ind_ind_sel))=U_smooth(ind_sel(ind_ind_sel))+U_smooth_sub;
                V_smooth(ind_sel(ind_ind_sel))=V_smooth(ind_sel(ind_ind_sel))+V_smooth_sub;
                NbCentres(isub)=numel(ind_ind_sel);
                Coord_tps(1:NbCentres(isub),:,isub)=Coord(ind_sel(ind_ind_sel),:);
                U_tps(1:NbCentres(isub)+3,isub)=U_tps_sub;
                V_tps(1:NbCentres(isub)+3,isub)=V_tps_sub;
                nb_select(ind_sel(ind_ind_sel))=nb_select(ind_sel(ind_ind_sel))+1;
                display('good2')
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
end

%% final adjustments
nb_select(nb_select==0)=1;
U_smooth=U_smooth./nb_select;% take the average at the intersection of several subdomains
V_smooth=V_smooth./nb_select;
fill=zeros(NbCoord+1,NbCoord,size(SubRange,3)); %matrix of zeros to complement the matrix Data.Civ1_Coord_tps (conveninent for file storage)
Coord_tps=cat(1,Coord_tps,fill);

