%'px_XYZ': transform physical to image coordinates. 
%------------------------------------------------------------------------
%[X,Y]=px_XYZ(Calib,Xphys,Yphys,Zphys)
%------------------------------------------------------------------------           
% OUTPUT:
% [X,Y]: image coordinates(in pixels)
%------------------------------------------------------------------------
% INPUT:
% Calib: structure containing calibration parameters
% Xphys,Yphys,Zphys; vectors of physical coordinates for a set of points

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [X,Y]=px_XYZ(Calib,Slice,Xphys,Yphys,Zphys)
if ~exist('Zphys','var')
    Zphys=0;
end
if ~isfield(Calib,'fx_fy')
     Calib.fx_fy=[1 1];
end
if ~isfield(Calib,'Tx_Ty_Tz')
     Calib.Tx_Ty_Tz=[0 0 1];
end

%%%%%%%%%%%%%
if isempty(Slice)
    Slice=Calib;
end
% general case
if isfield(Calib,'R')
    R=(Calib.R)';
    %correct z for refraction if needed
    if isfield(Slice,'InterfaceCoord') && isfield(Slice,'RefractionIndex')
        H=Slice.InterfaceCoord(3);
        if H>Zphys
            Zphys=H-(H-Zphys)/Slice.RefractionIndex; %corrected z (virtual object)Calib
            
          %  test_refraction=1;
        end
    end
    
    %camera coordinates
    Zphys=Zphys;%flip z coordinates
    xc=R(1)*Xphys+R(2)*Yphys+R(3)*Zphys+Calib.Tx_Ty_Tz(1);
    yc=R(4)*Xphys+R(5)*Yphys+R(6)*Zphys+Calib.Tx_Ty_Tz(2);
    zc=R(7)*Xphys+R(8)*Yphys+R(9)*Zphys+Calib.Tx_Ty_Tz(3);
    
    %undistorted image coordinates
    Xu=xc./zc;
    Yu=yc./zc;
    
    %radial quadratic correction factor
    if ~isfield(Calib,'kc')
        r2=1; %no quadratic distortion
    elseif numel(Calib.kc)==1
        r2=1+Calib.kc*(Xu.*Xu+Yu.*Yu);
    else
        R2=Xu.*Xu+Yu.*Yu;
        r2=1+Calib.kc(1)*R2+Calib.kc(2)*R2.*R2;
    end
    
    %pixel coordinates
    if ~isfield(Calib,'Cx_Cy')
        Calib.Cx_Cy=[0 0];%default value
    end
    X=Calib.fx_fy(1)*Xu.*r2+Calib.Cx_Cy(1);
    Y=Calib.fx_fy(2)*Yu.*r2+Calib.Cx_Cy(2);  
    
%case 'rescale'    
else 
    X=Calib.fx_fy(1)*(Xphys+Calib.Tx_Ty_Tz(1));
    Y=Calib.fx_fy(2)*(Yphys+Calib.Tx_Ty_Tz(2));  
end



