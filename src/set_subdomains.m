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


