%'phys_XYZ':transforms image (px) to real world (phys) coordinates using geometric calibration parameters
% function [Xphys,Yphys]=phys_XYZ(Calib,X,Y,Z)
%
%OUTPUT:
%
%INPUT:
%Z: index of plane
function [Xphys,Yphys,Zphys]=phys_XYZ(Calib,X,Y,Z)
if exist('Z','var')& isequal(Z,round(Z))& Z>0 & isfield(Calib,'SliceCoord')&length(Calib.SliceCoord)>=Z
    Zindex=Z;
    Zphys=Calib.SliceCoord(Zindex,3);%GENERALISER AUX CAS AVEC ANGLE
else
%     if exist('Z','var')
%         Zphys=Z;
%     else
        Zphys=0;
%     end
end
if ~exist('X','var')||~exist('Y','var')
    Xphys=[];
    Yphys=[];%default
    return
end
Xphys=X;%default
Yphys=Y;
%image transform
if isfield(Calib,'R')
    R=(Calib.R)';
    Dx=R(5)*R(7)-R(4)*R(8);
    Dy=R(1)*R(8)-R(2)*R(7);
    D0=Calib.f*(R(2)*R(4)-R(1)*R(5));
    Z11=R(6)*R(8)-R(5)*R(9);
    Z12=R(2)*R(9)-R(3)*R(8);  
    Z21=R(4)*R(9)-R(6)*R(7);
    Z22=R(3)*R(7)-R(1)*R(9);
    Zx0=R(3)*R(5)-R(2)*R(6);
    Zy0=R(1)*R(6)-R(3)*R(4);
    A11=R(8)*Calib.Ty-R(5)*Calib.Tz+Z11*Zphys;
    A12=R(2)*Calib.Tz-R(8)*Calib.Tx+Z12*Zphys;
    A21=-R(7)*Calib.Ty+R(4)*Calib.Tz+Z21*Zphys;
    A22=-R(1)*Calib.Tz+R(7)*Calib.Tx+Z11*Zphys;
    X0=Calib.f*(R(5)*Calib.Tx-R(2)*Calib.Ty+Zx0*Zphys);
    Y0=Calib.f*(-R(4)*Calib.Tx+R(1)*Calib.Ty+Zy0*Zphys);
        %px to camera:
    Xd=(Calib.dpx/Calib.sx)*(X-Calib.Cx); % sensor coordinates
    Yd=Calib.dpy*(Y-Calib.Cy);
    dist_fact=1+Calib.kappa1*(Xd.*Xd+Yd.*Yd); %distortion factor
    Xu=dist_fact.*Xd;%undistorted sensor coordinates
    Yu=dist_fact.*Yd;
    denom=Dx*Xu+Dy*Yu+D0;
    % denom2=denom.*denom;
    Xphys=(A11.*Xu+A12.*Yu+X0)./denom;%world coordinates
    Yphys=(A21.*Xu+A22.*Yu+Y0)./denom;
end
