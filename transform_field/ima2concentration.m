%transform LIF images to concentration images

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

function [DataOut]=ima2concentration(DataIn,XmlData)

%% request input parameters
DataOut=[];
if (isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0))
    return
end
if ~isfield(XmlData,'LIFCalib')
        msgbox_uvmat('ERROR','no LIF calibration data available, first run LIFCalib in uvmat')
    return
end
cpath=which('uvmat');
addpath(fullfile(fileparts(cpath),'transform_field'))% define path for phys_polar.m

%% rescale the image
[nby,nbx]=size(DataIn.A);
x=linspace(DataIn.Coord_x(1),DataIn.Coord_x(2),nbx)-nbx/2;
y=linspace(DataIn.Coord_y(1),DataIn.Coord_y(2),nby)-nby/2;
[X,Y]=meshgrid(x,y);
coeff_quad=0.15*4/(nbx*nbx);% image luminosity reduced by 10% at the edge
DataIn.A=double(DataIn.A).*(1+coeff_quad*(X.*X+Y.*Y));

%% Transform images to polar coordinates with origin at the light source position 
XmlData.TransformInput.PolarCentre=XmlData.LIFCalib.LightOrigin; %position of the laser origin [x, y]
DataIn.Action.RUN=1;% avoid input menu in phys_polar
DataOut=phys_polar(DataIn,XmlData);
[npangle,npr]=size(DataOut.A);%size of the image in polar coordinates
dX=(DataOut.Coord_x(2)-DataOut.Coord_x(1))/(npr-1);% radial step

%% introduce the reference line where the laser enters the fluid region
r_edge=XmlData.LIFCalib.RefLineRadius'*ones(1,npr);% radial position of the reference line extended as a matrix (npx,npy)
A_ref=XmlData.LIFCalib.RefLineLum'*ones(1,npr);% luminosity on the reference line extended as a matrix (npx,npy)
R=ones(npangle,1)*linspace(DataOut.Coord_x(1), DataOut.Coord_x(2),npr);%radial coordinate extended as a matrix (npx,npy)

%gamma_coeff=XmlData.LIFCalib.DecayRate;
DataOut.A(R<r_edge)=0;
DataOut.A=double(DataOut.A)./A_ref;% renormalize the luminosity with the reference luminosity at the same azimuth on the reference line
I=(r_edge-dX*XmlData.LIFCalib.DecayRate.*cumsum(R.*DataOut.A,2))./R;% expected laser intensity along the line
DataOut.A=DataOut.A./I;%concentration normalized by the uniform concentration assumed in the ref image used for calibration
DataOut.A(I<=0)=0;% eliminate values obtained with I<=0

DataOut=polar2phys(DataOut);% back to phys cartesian coordinates with origin at the light source
DataOut.A=uint16(1000*DataOut.A);% concentration multiplied by 1000 to get an image
DataOut.Coord_x=DataOut.Coord_x+XmlData.LIFCalib.LightOrigin(1);%shift to original cartesian coordinates
DataOut.Coord_y=DataOut.Coord_y+XmlData.LIFCalib.LightOrigin(2);


function DataOut=polar2phys(DataIn)
%%%%%%%%%%%%%%%%%%%%
DataOut=DataIn; %default
[npy,npx]=size(DataIn.A);
dx=(DataIn.Coord_x(2)-DataIn.Coord_x(1))/(npx-1); %mesh along radius
dy=(DataIn.Coord_y(2)-DataIn.Coord_y(1))/(npy-1);%mesh along azimuth

%% create cartesian coordinates in the domain defined by the four image corners
rcorner=[DataIn.Coord_x(1) DataIn.Coord_x(2) DataIn.Coord_x(1) DataIn.Coord_x(2)];% radius of the corners
ycorner=[DataIn.Coord_y(2) DataIn.Coord_y(2) DataIn.Coord_y(1) DataIn.Coord_y(1)];% azimuth of the corners
thetacorner=pi*ycorner/180;% azimuth in radians
[Xcorner,Ycorner] = pol2cart(thetacorner,rcorner);% cartesian coordinates of the corners (with respect to lser source)
RangeX(1)=min(Xcorner);
RangeX(2)=max(Xcorner);
RangeY(2)=min(Ycorner);
RangeY(1)=max(Ycorner);
x=linspace(RangeX(1),RangeX(2),npx);%coordinates of the new pixels
y=linspace(RangeY(2),RangeY(1),npy);
[X,Y]=meshgrid(x,y);%grid for new pixels in cartesian coordinates

%% image indices corresponding to the cartesian grid
[Theta,R] = cart2pol(X,Y);%corresponding polar coordiantes
Theta=180*Theta/pi;%angles in degrees
Theta=1-round((Theta-DataIn.Coord_y(2))/dy); %angular index along y (dy negative)
R=1+round((R-DataIn.Coord_x(1))/dx); %angular index along x 
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
DataOut.Coord_x=RangeX;
DataOut.Coord_y=RangeY;  

