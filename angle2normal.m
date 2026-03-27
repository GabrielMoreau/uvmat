%angle2normal: calculate the components of the unit vector defined by a rotation vector 
% this gives the equation of the plane as norm_plane(1)x + norm_plane(2)y +norm_plane(3)z = cte

% OUTPUT:
%norm_plane: three components of the normal unit vector 
% INPUT:
%PlaneAngle: rotation vector, with three components in degree) 

function norm_plane=rotate(PlaneAngle)

om=norm(PlaneAngle);%norm of rotation angle in degrees
OmAxis=PlaneAngle/om; %unit vector marking the rotation axis
cos_om=cos(pi*om/180);
sin_om=sin(pi*om/180);
coeff=OmAxis(3)*(1-cos_om);
norm_plane(1)=OmAxis(1)*coeff+OmAxis(2)*sin_om;
norm_plane(2)=OmAxis(2)*coeff-OmAxis(1)*sin_om;
norm_plane(3)=OmAxis(3)*coeff+cos_om;