%------------------------------------------------------------------------
%'phys_XYZ':transforms image (px) to real world (phys) coordinates using geometric calibration parameters
% function [Xphys,Yphys,Zphys]=phys_XYZ(Calib,Slice,X,Y,Zindex)
%
%OUTPUT:
% Xphys,Yphys,Zphys: vector of phys coordinates corresponding to the input vector of image coordinates
%INPUT:
% Calib: Matlab structure containing the calibration parameters (pinhole camera model, see 
% http://servforge.legi.grenoble-inp.fr/projects/soft-uvmat/wiki/UvmatHelp#GeometryCalib) 
%    .Tx_Ty_Tz: translation (3 phys coordinates) defining the origine of the camera frame
%    .R : rotation matrix from phys to camera frame
%    .fx_fy: focal length along each direction of the image
% Slice: Matlab structure containing the parameters describing the position and inclination of the illumination plane
% X, Y: vectors of X and Y image coordinates
% ZIndex (if needed): index defining the current illumination plane in a volume scan,=1 by default

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

function [Xphys,Yphys,Zphys]=phys_XYZ(Calib,Slice,X,Y,Zindex)
%------------------------------------------------------------------------
testangle=0;% =1 if the illumination plane is tilted with respect to the horizontal plane Xphys Yphys
test_refraction=0;% =1 if the considered points are viewed through an horizontal interface (located at z=Calib.InterfaceCoord(3)') 
if ~exist('X','var')||~exist('Y','var')
    Xphys=[];
    Yphys=[];%default
    return
end
Zphys=0; %default output

% if isempty(Slice)
%     Slice=Calib;%old convention < 2022
% elseif ~isfield(Slice,'SliceCoord')% bad input
%     Xphys=[];
%     Yphys=[];% bad input
%     return
% end
if exist('Zindex','var')&& isequal(Zindex,round(Zindex))&& Zindex>0 && isfield(Slice,'SliceCoord')&&size(Slice.SliceCoord,1)>=Zindex
    if isfield(Slice, 'SliceAngle') && size(Slice.SliceAngle,1)>=Zindex && ~isequal(Slice.SliceAngle(Zindex,:),[0 0 0])
        testangle=1;
        norm_plane=angle2normal(Slice.SliceAngle(Zindex,:));% coordinates UVMAT-httpsof the unit vector normal to the current illumination plane
    end
    Z0=Slice.SliceCoord(Zindex,3);%horizontal plane z=cte
    Z0virt=Z0;
    if isfield(Slice,'InterfaceCoord') && isfield(Slice,'RefractionIndex')
        H=Slice.InterfaceCoord(3);% z position of the water surface
        if H>Z0
            Z0virt=H-(H-Z0)/Slice.RefractionIndex; %corrected z (virtual object)
            test_refraction=1;
        end
    end
else
    Z0=0;
    Z0virt=0;
end

%coordinate transform
if ~isfield(Calib,'fx_fy')
    Calib.fx_fy=[1 1];
end
if ~isfield(Calib,'Tx_Ty_Tz')
    Calib.Tx_Ty_Tz=[0 0 1];
end
if ~isfield(Calib,'Cx_Cy')
    Calib.Cx_Cy=[0 0];
end
kc=[0 0];
if isfield(Calib,'kc')
    kc(1:numel(Calib.kc))=Calib.kc;
end
% if ~isfield(Calib,'kc2')
%     Calib.kc2=0;
% end
if isfield(Calib,'R')
    R=(Calib.R)';
    c=Z0virt;
    cvirt=Z0virt;
    if testangle
        % equation of the illumination plane: z=ax+by+c
        a=-norm_plane(1)/norm_plane(3);
        b=-norm_plane(2)/norm_plane(3);
        if test_refraction
            avirt=a/Slice.RefractionIndex;
            bvirt=b/Slice.RefractionIndex;
        else
            avirt=a;
            bvirt=b;
        end
        cvirt=Z0virt-avirt*Slice.SliceCoord(Zindex,1)-bvirt*Slice.SliceCoord(Zindex,2);% Z0 = (virtual) z coordinate on the rotation axis (assumed horizontal)
                               % c=z coordinate at (x,y)=(0,0)
        c=Z0-a*Slice.SliceCoord(Zindex,1)-b*Slice.SliceCoord(Zindex,2);
        R(1)=R(1)+avirt*R(3);
        R(2)=R(2)+bvirt*R(3);
        R(4)=R(4)+avirt*R(6);
        R(5)=R(5)+bvirt*R(6);
        R(7)=R(7)+avirt*R(9);
        R(8)=R(8)+bvirt*R(9);          
    end
    Tx=Calib.Tx_Ty_Tz(1);
    Ty=Calib.Tx_Ty_Tz(2);
    Tz=Calib.Tx_Ty_Tz(3);
    Dx=R(5)*R(7)-R(4)*R(8);
    Dy=R(1)*R(8)-R(2)*R(7);
    D0=(R(2)*R(4)-R(1)*R(5));
    Z11=R(6)*R(8)-R(5)*R(9);
    Z12=R(2)*R(9)-R(3)*R(8);
    Z21=R(4)*R(9)-R(6)*R(7);
    Z22=R(3)*R(7)-R(1)*R(9);
     Zx0=R(3)*R(5)-R(2)*R(6);
     Zy0=R(1)*R(6)-R(3)*R(4);
    B11=R(8)*Ty-R(5)*Tz+Z11*cvirt;
    B12=R(2)*Tz-R(8)*Tx+Z12*cvirt;
    B21=-R(7)*Ty+R(4)*Tz+Z21*cvirt;
    B22=-R(1)*Tz+R(7)*Tx+Z22*cvirt;
    X0=R(5)*Tx-R(2)*Ty+Zx0*cvirt;
    Y0=-R(4)*Tx+R(1)*Ty+Zy0*cvirt;
    %px to camera:
    Xd=(X-Calib.Cx_Cy(1))/Calib.fx_fy(1); % sensor coordinates
    Yd=(Y-Calib.Cx_Cy(2))/Calib.fx_fy(2);
    dist_fact=1+kc(1)*(Xd.*Xd+Yd.*Yd);% distortion factor, first approximation Xu,Yu=Xd,Yd
    test=0;
    niter=0;
    while test==0 && niter<10
        dist_fact_old=dist_fact;     
        Xu=Xd./dist_fact;%undistorted sensor coordinates, second iteration
        Yu=Yd./dist_fact;
        R2=Xu.*Xu+Yu.*Yu;
        dist_fact=1+kc(1)*R2+kc(2)*R2.*R2;% distortion factor,next approximation
        test=max(max(abs(dist_fact-dist_fact_old)))<0.00001; % reducing the relative error to 10^-5 forthe inversion of the quadraticcorrection
        niter=niter+1;
    end
    denom=Dx*Xu+Dy*Yu+D0;
    Xphys=(B11.*Xu+B12.*Yu+X0)./denom;%world coordinates
    Yphys=(B21.*Xu+B22.*Yu+Y0)./denom;
    if testangle
        Zphys=c+a*Xphys+b*Yphys;
    else
        Zphys=Z0;
    end
else
    Xphys=-Calib.Tx_Ty_Tz(1)+X/Calib.fx_fy(1);
    Yphys=-Calib.Tx_Ty_Tz(2)+Y/Calib.fx_fy(2);
end

