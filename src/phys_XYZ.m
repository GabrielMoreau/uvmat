%------------------------------------------------------------------------
%'phys_XYZ':transforms image (px) to real world (phys) coordinates using geometric calibration parameters
% function [Xphys,Yphys]=phys_XYZ(Calib,X,Y,Z)
%
%OUTPUT:
%
%INPUT:
%Z: index of plane
function [Xphys,Yphys,Zphys]=phys_XYZ(Calib,X,Y,Zindex)
%------------------------------------------------------------------------
testangle=0;
test_refraction=0;
if exist('Zindex','var')&& isequal(Zindex,round(Zindex))&& Zindex>0 && isfield(Calib,'SliceCoord')&&length(Calib.SliceCoord)>=Zindex
    if isfield(Calib, 'SliceAngle') && ~isequal(Calib.SliceAngle,[0 0 0]) && ~isequal(Calib.SliceAngle(Zindex,:),[0 0 0])
        testangle=1;
        om=norm(Calib.SliceAngle(Zindex,:));%norm of rotation angle in radians
        OmAxis=Calib.SliceAngle(Zindex,:)/om; %unit vector marking the rotation axis
        cos_om=cos(pi*om/180);
        sin_om=sin(pi*om/180);
        coeff=OmAxis(3)*(1-cos_om);
        norm_plane(1)=OmAxis(1)*coeff+OmAxis(2)*sin_om;
        norm_plane(2)=OmAxis(2)*coeff-OmAxis(1)*sin_om;
        norm_plane(3)=OmAxis(3)*coeff+cos_om;
        Z0=norm_plane*Calib.SliceCoord(Zindex,:)'/norm_plane(3);
    else
        Z0=Calib.SliceCoord(Zindex,3);%horizontal plane z=cte
    end
    Z0virt=Z0;
    if isfield(Calib,'InterfaceCoord') && isfield(Calib,'RefractionIndex')
        H=Calib.InterfaceCoord(3);
        if H>Z0
            Z0virt=H-(H-Z0)/Calib.RefractionIndex; %corrected z (virtual object)
            test_refraction=1;
        end
    end
else
    Z0=0;
    Z0virt=0;
end
if ~exist('X','var')||~exist('Y','var')
    Xphys=[];
    Yphys=[];%default
    return
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
if ~isfield(Calib,'kc')
    Calib.kc=0;
end
if isfield(Calib,'R')
    R=(Calib.R)';
    if testangle
        a=-norm_plane(1)/norm_plane(3);
        b=-norm_plane(2)/norm_plane(3);
        if test_refraction
            a=a/Calib.RefractionIndex;
            b=b/Calib.RefractionIndex;
        end
        R(1)=R(1)+a*R(3);
        R(2)=R(2)+b*R(3);
        R(4)=R(4)+a*R(6);
        R(5)=R(5)+b*R(6);
        R(7)=R(7)+a*R(9);
        R(8)=R(8)+b*R(9);
    end
    Tx=Calib.Tx_Ty_Tz(1);
    Ty=Calib.Tx_Ty_Tz(2);
    Tz=Calib.Tx_Ty_Tz(3);
    f=Calib.fx_fy(1);%dpy=1; sx=1
    %dpx=Calib.fx_fy(2)/Calib.fx_fy(1);
    Dx=R(5)*R(7)-R(4)*R(8);
    Dy=R(1)*R(8)-R(2)*R(7);
    D0=(R(2)*R(4)-R(1)*R(5));
    Z11=R(6)*R(8)-R(5)*R(9);
    Z12=R(2)*R(9)-R(3)*R(8);
    Z21=R(4)*R(9)-R(6)*R(7);
    Z22=R(3)*R(7)-R(1)*R(9);
    Zx0=R(3)*R(5)-R(2)*R(6);
    Zy0=R(1)*R(6)-R(3)*R(4);
    A11=R(8)*Ty-R(5)*Tz+Z11*Z0virt;
    A12=R(2)*Tz-R(8)*Tx+Z12*Z0virt;
    A21=-R(7)*Ty+R(4)*Tz+Z21*Z0virt;
    A22=-R(1)*Tz+R(7)*Tx+Z22*Z0virt;
    %     X0=Calib.fx_fy(1)*(R(5)*Tx-R(2)*Ty+Zx0*Z0virt);
    %     Y0=Calib.fx_fy(2)*(-R(4)*Tx+R(1)*Ty+Zy0*Z0virt);
    X0=(R(5)*Tx-R(2)*Ty+Zx0*Z0virt);
    Y0=(-R(4)*Tx+R(1)*Ty+Zy0*Z0virt);
    %px to camera:
    %     Xd=dpx*(X-Calib.Cx_Cy(1)); % sensor coordinates
    %     Yd=(Y-Calib.Cx_Cy(2));
    Xd=(X-Calib.Cx_Cy(1))/Calib.fx_fy(1); % sensor coordinates
    Yd=(Y-Calib.Cx_Cy(2))/Calib.fx_fy(2);
    dist_fact=1+Calib.kc*(Xd.*Xd+Yd.*Yd);%/(f*f); %distortion factor
    Xu=Xd./dist_fact;%undistorted sensor coordinates
    Yu=Yd./dist_fact;
    denom=Dx*Xu+Dy*Yu+D0;
    Xphys=(A11.*Xu+A12.*Yu+X0)./denom;%world coordinates
    Yphys=(A21.*Xu+A22.*Yu+Y0)./denom;
    if testangle
        Zphys=Z0+a*Xphys+b*Yphys;
    else
        Zphys=Z0;
    end
else
    Xphys=-Calib.Tx_Ty_Tz(1)+X/Calib.fx_fy(1);
    Yphys=-Calib.Tx_Ty_Tz(2)+Y/Calib.fx_fy(2);
end

%'px_XYZ': transform phys coordinates to image coordinates (px)
%
% OUPUT:
% X,Y: array of coordinates in the image cooresponding to the input physical positions 
%                    (origin at lower leftcorner, unit=pixel)

% INPUT:
% Calib: structure containing the calibration parameters (read from the ImaDoc .xml file)
% Xphys, Yphys: array of x,y physical coordinates
% [Z0]: corresponding array of z physical coordinates (0 by default)
