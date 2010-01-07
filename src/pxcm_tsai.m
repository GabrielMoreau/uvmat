%'pxcm_tsai': find differentials of the Tsai calibration
%
function [A11,A12,A13,A21,A22,A23]=pxcm_tsai(a,var_phys)
a_read=a;

R=(a.R)';

x=var_phys(:,1);
y=var_phys(:,2);

if isfield(a,'PlanePos')
    prompt={'Plane 1 Index','Plane 2 Index'};
    Rep=inputdlg(prompt,'Target displacement test');
    Z1=str2double(Rep(1));
    Z2=str2double(Rep(2));
    z=(a.PlanePos(Z2,3)+a.PlanePos(Z1,3))/2
else
    z=0;
end

%transform coeff for differentiels
a.C11=R(1)*R(8)-R(2)*R(7);
a.C12=R(2)*R(7)-R(1)*R(8);
a.C21=R(4)*R(8)-R(5)*R(7);
a.C22=R(5)*R(7)-R(4)*R(8);
a.C1x=R(3)*R(7)-R(9)*R(1);
a.C1y=R(3)*R(8)-R(9)*R(2);
a.C2x=R(6)*R(7)-R(9)*R(4);
a.C2y=R(6)*R(8)-R(9)*R(5);


%dependence in x,y
denom=(R(7)*x+R(8)*y+R(9)*z+a.Tz).*(R(7)*x+R(8)*y+R(9)*z+a.Tz);
A11=(a.f*a.sx*(a.C11*y-a.C1x*z+R(1)*a.Tz-R(7)*a.Tx)./denom)/a.dpx;
A12=(a.f*a.sx*(a.C12*x-a.C1y*z+R(2)*a.Tz-R(8)*a.Tx)./denom)/a.dpx;
A21=(a.f*a.sx*(a.C21*y-a.C2x*z+R(4)*a.Tz-R(7)*a.Ty)./denom)/a.dpy;
A22=(a.f*(a.C22*x-a.C2y*z+R(5)*a.Tz-R(8)*a.Ty)./denom)/a.dpy;
A13=(a.f*(a.C1x*x+a.C1y*y+R(3)*a.Tz-R(9)*a.Tx)./denom)/a.dpx;
A23=(a.f*(a.C2x*x+a.C2y*y+R(6)*a.Tz-R(9)*a.Ty)./denom)/a.dpy;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Old Version for z=0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %'camera' coordinates
% xc=R(1)*x+R(2)*y+a.Tx;
% yc=R(4)*x+R(5)*y+a.Ty;
% zc=R(7)*x+R(8)*y+a.Tz;
% %undistorted image coordinates
% Xu=a.f*xc./zc;
% Yu=a.f*yc./zc;
% %distorted image coordinates
% distortion=(a.kappa1)*(Xu.*Xu+Yu.*Yu)+1; %!! intégrer derivation kappa
% % distortion=1;
% Xd=Xu./distortion;
% Yd=Yu./distortion;
% %pixel coordinates
% X=Xd*a.sx/a.dpx+a.Cx;
% Y=Yd/a.dpy+a.Cy;
% 
% %transform coeff for differentiels
% a.C11=R(1)*R(8)-R(2)*R(7);
% a.C12=R(2)*R(7)-R(1)*R(8);
% a.C21=R(4)*R(8)-R(5)*R(7);
% a.C22=R(5)*R(7)-R(4)*R(8);
% a.C1x=R(3)*R(7)-R(9)*R(1);
% a.C1y=R(3)*R(8)-R(9)*R(2);
% a.C2x=R(6)*R(7)-R(9)*R(4);
% a.C2y=R(6)*R(8)-R(9)*R(5);
% 
% 
% %dependence in x,y
% denom=(R(7)*x+R(8)*y+a.Tz).*(R(7)*x+R(8)*y+a.Tz);
% A11=(a.f*a.sx*(a.C11*y+R(1)*a.Tz-R(7)*a.Tx)./denom)/a.dpx;
% A12=(a.f*a.sx*(a.C12*x+R(2)*a.Tz-R(8)*a.Tx)./denom)/a.dpx;
% A21=(a.f*a.sx*(a.C21*y+R(4)*a.Tz-R(7)*a.Ty)./denom)/a.dpy;
% A22=(a.f*(a.C22*x+R(5)*a.Tz-R(8)*a.Ty)./denom)/a.dpy;
% A13=(a.f*(a.C1x*x+a.C1y*y+R(3)*a.Tz-R(9)*a.Tx)./denom)/a.dpx;
% A23=(a.f*(a.C2x*x+a.C2y*y+R(6)*a.Tz-R(9)*a.Ty)./denom)/a.dpy;
% 
