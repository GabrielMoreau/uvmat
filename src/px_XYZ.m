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

function [X,Y]=px_XYZ(Calib,Xphys,Yphys,Zphys)
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
if ~isfield(Calib,'fx_fy')
     Calib.fx_fy=[1 1];
end
if ~isfield(Calib,'Tx_Ty_Tz')
     Calib.Tx_Ty_Tz=[0 0 1];
end
% if ~isfield(Calib,'kappa1')
%     Calib.kappa1=0;
% end
% if ~isfield(Calib,'sx')
%     Calib.sx=1;
% end
% if ~isfield(Calib,'dpx')
%     Calib.dpx=1;
% end
% if ~isfield(Calib,'dpy')
%     Calib.dpy=1;
% end

%%%%%%%%%%%%%
if isfield(Calib,'R')
    R=(Calib.R)';
    %camera coordinates
    xc=R(1)*Xphys+R(2)*Yphys+R(3)*Zphys+Calib.Tx_Ty_Tz(1);
    yc=R(4)*Xphys+R(5)*Yphys+R(6)*Zphys+Calib.Tx_Ty_Tz(2);
    zc=R(7)*Xphys+R(8)*Yphys+R(9)*Zphys+Calib.Tx_Ty_Tz(3);
%undistorted image coordinates
    Xu=xc./zc;
    Yu=yc./zc;
%radial quadratic correction factor
    if ~isfield(Calib,'kc')
        r2=1; %no quadratic distortion
    else
        r2=1+Calib.kc*(Xu.*Xu+Yu.*Yu);
    end
%pixel coordinates
    if ~isfield(Calib,'Cx_Cy')
        Calib.Cx_Cy=[0 0];%default value
    end
    X=Calib.fx_fy(1)*Xu.*r2+Calib.Cx_Cy(1);
    Y=Calib.fx_fy(2)*Yu.*r2+Calib.Cx_Cy(2);    
%OLD CONVENTION (Wilson)undistorted image coordinates
%     Xu=Calib.f*xc./zc;
%     Yu=Calib.f*yc./zc;    
% %distorted image coordinates 
%     distortion=(Calib.kappa1)*(Xu.*Xu+Yu.*Yu)+1; %A REVOIR
% % distortion=1;
%     Xd=Xu./distortion;
%     Yd=Yu./distortion;
% %pixel coordinates
%     X=Xd*Calib.sx/Calib.dpx+Calib.Cx;
%     Y=Yd/Calib.dpy+Calib.Cy;
else %case 'rescale'
    X=Calib.fx_fy(1)*(Xphys+Calib.Tx_Ty_Tz(1));
    Y=Calib.fx_fy(2)*(Yphys+Calib.Tx_Ty_Tz(2));  
end



