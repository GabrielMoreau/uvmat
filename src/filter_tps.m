%------------------------------------------------------------------------
% patch function
% OUTPUT:
% SubRange(NbCoord,NbSubdomain,2): range (min, max) of the coordiantes x and y respectively, for each subdomain
% NbSites(NbSubdomain): number of source points for each subdomain
% FF: false flags
% U_smooth, V_smooth: filtered velocity components at the positions of the initial data
% Coord_tps(NbSites,NbCoord,NbSubdomain): positions of the tps centres
% U_tps,V_tps: weight of the tps for each subdomain
%
% INPUT:
% X, Y: set of coordinates of the initial data
% U,V: set of velocity components of the initial data
% Rho: smoothing parameter
% Threshold: max diff accepted between smoothed and initial data 
% Subdomain: estimated number of data points in each subdomain

%function [SubRangx,SubRangy,nbpoints,FF,U_smooth,V_smooth,X_tps,Y_tps,U_tps,V_tps,Indices_tps] =filter_tps(Coord,U,V,W,SubDomain,Rho,Threshold)
function [SubRange,NbSites,Coord_tps,U_tps,V_tps,W_tps,U_smooth,V_smooth,W_smooth,FF] =filter_tps(Coord,U,V,W,SubDomain,Rho,Threshold)
%subdomain decomposition
warning off
% U=reshape(U,[],1);
% V=reshape(V,[],1);
% X=reshape(X,[],1);
% Y=reshape(Y,[],1);
nbvec=size(Coord,1);
W_tps=[];%default
W_smooth=[];
NbCoord=size(Coord,2);
NbSubDomain=ceil(nbvec/SubDomain);
MinCoord=min(Coord,[],1);
% MinY=min(Y,);
MaxCoord=max(Coord,[],1);
% MaxY=max(Y);
Range=MaxCoord-MinCoord;
% RangY=MaxY-MinY;
AspectRatio=Range(2)/Range(1);
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
rho=Siz(1)*Siz(2)*Rho/1000000;%optimum rho increase as the area of the subdomain (division by 10^6 to reach good values with the default GUI input)
U_tps_sub=zeros(nbvec,NbSubDomain);%default spline
V_tps_sub=zeros(nbvec,NbSubDomain);%default spline
Indices_tps=zeros(nbvec,NbSubDomain);%default indices
U_smooth=zeros(nbvec,1);
V_smooth=zeros(nbvec,1);
nb_select=zeros(nbvec,1);
FF=zeros(nbvec,1);
check_empty=zeros(1,NbSubDomain);
SubRange=zeros(NbCoord,2,NbSubDomain);%initialise the positions of subdomains
% SubRangy=zeros(NbSubDomain,2);
for isub=1:NbSubDomain
    SubRange(1,:,isub)=[CentreX(isub)-0.55*Siz(1) CentreX(isub)+0.55*Siz(1)];
    SubRange(2,:,isub)=[CentreY(isub)-0.55*Siz(2) CentreY(isub)+0.55*Siz(2)];
    ind_sel_previous=[];
    ind_sel=0;
    while numel(ind_sel)>numel(ind_sel_previous) %increase the subdomain during four iterations at most
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
            SubRange(:,1,isub)=SubRange(:,1,isub)-Siz/4;
            SubRange(:,2,isub)=SubRange(:,2,isub)+Siz/4;
%             SubRangy(isub,1)=SubRangy(isub,1)-Siz(2)/4;
%             SubRangy(isub,2)=SubRangy(isub,2)+Siz(2)/4;
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
            % no value exceeds threshold, the result is recorded
            if isequal(numel(ind_ind_sel),numel(ind_sel))
                U_smooth(ind_sel)=U_smooth(ind_sel)+U_smooth_sub;
                V_smooth(ind_sel)=V_smooth(ind_sel)+V_smooth_sub;
                NbSites(isub)=numel(ind_sel);
%                 Indices_tps(1:NbSites(isub),isub)=ind_sel;
                Coord_tps(1:NbSites(isub),:,isub)=Coord(ind_sel,:);
%                 Y_tps(1:NbSites(isub),:,isub)=Coord(ind_sel,2);
                U_tps(1:NbSites(isub)+3,isub)=U_tps_sub;
                V_tps(1:NbSites(isub)+3,isub)=V_tps_sub;         
                nb_select(ind_sel)=nb_select(ind_sel)+1;
                 display('good')
                break
                % too few selected vectors, increase the subrange for next iteration
            elseif numel(ind_ind_sel)<SubDomain/4 && ~isequal( ind_sel,ind_sel_previous);
                SubRange(:,1,isub)=SubRange(:,1,isub)-Siz/4;
                SubRange(:,2,isub)=SubRange(:,2,isub)+Siz/4;
%                 SubRange(2,isub,1)=SubRangy(2,isub,1)-Siz(2)/4;
%                 SubRange(2,isub,2)=SubRangy(2,isub,2)+Siz(2)/4;
%                 display('fewsmooth')
                % interpolation-smoothing is done again with the selected vectors
            else
                [U_smooth_sub,U_tps_sub]=tps_coeff(Coord(ind_sel(ind_ind_sel)),U(ind_sel(ind_ind_sel)),rho);
                [V_smooth_sub,V_tps_sub]=tps_coeff(Coord(ind_sel(ind_ind_sel)),V(ind_sel(ind_ind_sel)),rho);
                U_smooth(ind_sel(ind_ind_sel))=U_smooth(ind_sel(ind_ind_sel))+U_smooth_sub;
                V_smooth(ind_sel(ind_ind_sel))=V_smooth(ind_sel(ind_ind_sel))+V_smooth_sub;
                NbSites(isub)=numel(ind_ind_sel);
                %Indices_tps(1:NbSites(isub),isub)=ind_sel(ind_ind_sel);
                Coord_tps(1:NbSites(isub),:,isub)=Coord(ind_sel(ind_ind_sel),:);
%                 Y_tps(1:NbSites(isub),:,isub)=Coord(ind_sel(ind_ind_sel),2);
                U_tps(1:NbSites(isub)+3,isub)=U_tps_sub;
                V_tps(1:NbSites(isub)+3,isub)=V_tps_sub;
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
    SubRange(:,:,ind_empty)=[];
%     SubRangy(ind_empty,:)=[];
%     Indices_tps(:,ind_empty)=[];
    Coord_tps(:,:,ind_empty)=[];
%     Y_tps(:,ind_empty)=[];
    U_tps(:,ind_empty)=[];
    V_tps(:,ind_empty)=[];
end
nb_select(nb_select==0)=1;%ones(size(find(nb_select==0)));
U_smooth=U_smooth./nb_select;
V_smooth=V_smooth./nb_select;
