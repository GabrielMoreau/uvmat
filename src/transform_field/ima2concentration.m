%transform LIF images to concentration images

%=======================================================================
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [DataOut]=ima2concentration(DataIn,XmlData)
%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    if ~isfield(XmlData,'LIFCalib')
        msgbox_uvmat('ERROR','no LIF calibration data available, first run LIFCalib in uvmat')
    return
    end
end
cpath=which('uvmat');
addpath(fullfile(fileparts(cpath),'transform_field'))% define path for phys_polar.m
DataOut_1=[];


%%  for use in uvmat
% num_level=Data.ZIndex;
% if ~exist('Ref','var')
%     huvmat=findobj(allchild(0),'tag','uvmat');
%     hhuvmat=guidata(huvmat);
%     RootPath=get(hhuvmat.RootPath,'String');
%     
%     %reference file
%     RootPath=fullfile(RootPath,'LIF_REF');
%     file_ref=fullfile(RootPath,['lif_ref_' num2str(num_level) '.nc']);
%     Ref=nc2struct(file_ref);
% end

%% Parameters
XmlData.TransformInput.PolarCentre=XmlData.LIFCalib.LightOrigin; %position of the laser origin [x, y]

%         if isfield(XmlData.TransformInput,'PolarReferenceRadius')
%             def{2}=num2str(XmlData.TransformInput.PolarReferenceRadius);
%         end
%         if isfield(XmlData.TransformInput,'PolarReferenceAngle')
%             def{3}=num2str(XmlData.TransformInput.PolarReferenceAngle);

%% concentration image
DataIn.Action.RUN=1;% avoid input menu in phys_polar
DataOut=phys_polar(DataIn,XmlData);
% A=Ref.Aref;%default
% ind_good=find(Ref.Aref~=0);
% ind_bad=find(Ref.Aref==0);
% A(ind_good)=double(DataOut.A(ind_good))-ImageOffset(1)
% %filtering and decimate
% Afilt=filter2(ones(nfilt,nfilt),A);
% Mask=filter2(ones(nfilt,nfilt),double(Ref.Aref~=0));
% B=Afilt./Mask;
% A(ind_bad)=B(ind_bad);
% [npy,npx]=size(A);
% DataMask=DataOut;
% DataMask.A=2*ones(npy,npx);%mask=2 for good data
% 
% DataMask.A(Ref.Aref==0)=1;%mask=0 for undefined data
% 
% C=filter2(ones(nfilt,nfilt),Ref.Aref);
% D=C./Mask;
% Ref.Aref(ind_bad)=D(ind_bad);
% DataOut_1=[];
% Coord_x=DataOut.Coord_x;
% Coord_y=DataOut.Coord_y;
% 
% dX=(Coord_x(2)-Coord_x(1))/(npx-1);
% dY=(Coord_y(1)-Coord_y(2))/(npy-1);%mesh of new pixels
% [R,Y]=meshgrid(linspace(Coord_x(1),Coord_x(2),npx),linspace(Coord_y(1),Coord_y(2),npy));
% r=Coord_x(1)+[0:npx-1]*dX;%distance from laser
% %A(ind_good)=(A(ind_good)>=0).*A(ind_good); %replaces negative values  by zeros
% A=A./Ref.Aref;% luminosity normalised by the reference (value at the edge of the box)

[npangle,npr]=size(DataOut.A);
dX=(DataOut.Coord_x(2)-DataOut.Coord_x(1))/(npr-1);
r_edge=XmlData.LIFCalib.RefLineRadius'*ones(1,npr);% radial position of the reference line extended as a matrix (npx,npy)
A_ref=XmlData.LIFCalib.RefLineLum'*ones(1,npr);% luminosity on the reference line at the edge of the box,extended as a matrix (npx,npy)
R=ones(npangle,1)*linspace(DataOut.Coord_x(1), DataOut.Coord_x(2),npr);%radial coordinate extended as a matrix (npx,npy)
%Edge_ind=find((abs(R-r_edge)/dX)<=1 & DataMask.A~=0);%indies of positions close to r_edge, values greater than 1 are not expected
%yedge=min(min(Y(Edge_ind)));
% jmax=round(-(yedge-Coord_y(1))/dY+1);
% DataMask.A(jmax:end,:)=0;
% 
% A(isnan(A)|isinf(A))=0;

% radius along the reference line
%Theta=(linspace(Coord_y(1),Coord_y(2),npy)*pi/180)'*ones(1,npx);%theta in radians

gamma_coeff=XmlData.LIFCalib.DecayRate;


DataOut.A(R<r_edge)=0;
DataOut.A=double(DataOut.A)./A_ref;
I=(r_edge-dX*gamma_coeff.*cumsum(R.*DataOut.A,2))./R;% expected laser intensity along the line
DataOut.A=DataOut.A./I;%concentration
DataOut.A(I<=0)=0;% eliminate values obtained with I<=0

RangeX=DataIn.Coord_x-XmlData.LIFCalib.LightOrigin(1);
RangeY=DataIn.Coord_y-XmlData.LIFCalib.LightOrigin(2);
% 
DataOut=polar2phys(DataOut,RangeX,RangeY);
DataOut.A=uint16(DataOut.A);
DataOut.Coord_x=DataOut.Coord_x+XmlData.LIFCalib.LightOrigin(1);
DataOut.Coord_y=DataOut.Coord_y+XmlData.LIFCalib.LightOrigin(2);



function DataOut=polar2phys(DataIn,RangeX,RangeY)
%%%%%%%%%%%%%%%%%%%%
DataOut=DataIn; %fdefault
[npy,npx]=size(DataIn.A);
dx=(DataIn.Coord_x(2)-DataIn.Coord_x(1))/(npx-1); 
dy=(DataIn.Coord_y(2)-DataIn.Coord_y(1))/(npy-1);%mesh
rcorner=[DataIn.Coord_x(1) DataIn.Coord_x(2) DataIn.Coord_x(1) DataIn.Coord_x(2)];% radius of the corners
ycorner=[DataIn.Coord_y(2) DataIn.Coord_y(2) DataIn.Coord_y(1) DataIn.Coord_y(1)];% azimuth of the corners
thetacorner=pi*ycorner/180;% azimuth in radians
[Xcorner,Ycorner] = pol2cart(thetacorner,rcorner);% cartesian coordinates of the corners (with respect to lser source)
if ~exist('RangeX','var')
RangeX(1)=min(Xcorner);
RangeX(2)=max(Xcorner);
end
if ~exist('RangeY','var')
RangeY(2)=min(Ycorner);
RangeY(1)=max(Ycorner);
end
%Rangx=[-100 100];%bounds of the initial box 
%Rangy=[75 -150];
% Rangy(1)=min(Ycorner);
% Rangy(2)=max(Ycorner);
x=linspace(RangeX(1),RangeX(2),npx);%coordinates of the new pixels
y=linspace(RangeY(2),RangeY(1),npy);
[X,Y]=meshgrid(x,y);%grid for new pixels in cartesian coordiantes

[Theta,R] = cart2pol(X,Y);%corresponding polar coordiantes
Theta=Theta*180/pi;
%Theta=1+round((Theta-DataIn.Coord_y(1))/dy); %index along y (dy negative)
Theta=1-round((Theta-DataIn.Coord_y(2))/dy); %index along y (dy negative)
R=1+round((R-DataIn.Coord_x(1))/dx); %index along x 
R=reshape(R,1,npx*npy);%indices reorganized in 'line'
Theta=reshape(Theta,1,npx*npy);
flagin=R>=1 & R<=npx & Theta >=1 & Theta<=npy;%flagin=1 inside the original image
vec_A=reshape(DataIn.A,1,npx*npy);%put the original image in line
ind_in=find(flagin);
ind_out=find(~flagin);
ICOMB=((R-1)*npy+(npy+1-Theta));
ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
vec_B(ind_in)=vec_A(ICOMB);
vec_B(ind_out)=zeros(size(ind_out));
DataOut.A=flipdim(reshape(vec_B,npy,npx),1);%new image in real coordinates

     %Rangx=Rangx-radius_ref;
DataOut.Coord_x=RangeX;
DataOut.Coord_y=RangeY;  

