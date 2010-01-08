%'px_XYZ': transform phys coordinates to image coordinates (px)
%
% OUPUT:
% X,Y: array of coordinates in the image cooresponding to the input physical positions 
%                    (origin at lower leftcorner, unit=pixel)

% INPUT:
% Calib: structure containing the calibration parameters (read from the ImaDoc .xml file)
% Xphys, Yphys: array of x,y physical coordinates
% [Zphys]: corresponding array of z physical coordinates (0 by default)


function [X,Y]=px_XYZ(Calib,Xphys,Yphys,Zphys)
X=[];%default
Y=[];
% if exist('Z','var')& isequal(Z,round(Z))& Z>0 & isfield(Calib,'PlanePos')&length(Calib.PlanePos)>=Z
%     Zindex=Z;
%     planepos=Calib.PlanePos{Zindex};
%     zphys=planepos(3);%A GENERALISER CAS AVEC ANGLE
% else
%     zphys=0;
% end
if ~exist('Zphys','var')
    Zphys=0;
end

%%%%%%%%%%%%%
if isfield(Calib,'R')
    R=(Calib.R)';
    xc=R(1)*Xphys+R(2)*Yphys+R(3)*Zphys+Calib.Tx;
    yc=R(4)*Xphys+R(5)*Yphys+R(6)*Zphys+Calib.Ty;
    zc=R(7)*Xphys+R(8)*Yphys+R(9)*Zphys+Calib.Tz;
%undistorted image coordinates
    Xu=Calib.f*xc./zc;
    Yu=Calib.f*yc./zc;
%distorted image coordinates
    distortion=(Calib.kappa1)*(Xu.*Xu+Yu.*Yu)+1; %A REVOIR
% distortion=1;
    Xd=Xu./distortion;
    Yd=Yu./distortion;
%pixel coordinates
    X=Xd*Calib.sx/Calib.dpx+Calib.Cx;
    Y=Yd/Calib.dpy+Calib.Cy;

elseif isfield(Calib,'Pxcmx')&isfield(Calib,'Pxcmy')%old calib  
        X=Xphys*Calib.Pxcmx;
        Y=Yphys*Calib.Pxcmy;
end


