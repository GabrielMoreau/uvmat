%calculate the components of the unit vector norm_plane normal to the plane
%defined by the rotation vector PlaneAngle (in degree) 
% this gives the equation of the plane as norm_plane(1)x + norm_plane(2)y + norm_plane(2)z = 0

function norm_plane=rotate(PlaneAngle)

om=norm(PlaneAngle);%norm of rotation angle in degrees
OmAxis=PlaneAngle/om; %unit vector marking the rotation axis
cos_om=cos(pi*om/180);
sin_om=sin(pi*om/180);
coeff=OmAxis(3)*(1-cos_om);
norm_plane(1)=OmAxis(1)*coeff+OmAxis(2)*sin_om;
norm_plane(2)=OmAxis(2)*coeff-OmAxis(1)*sin_om;
norm_plane(3)=OmAxis(3)*coeff+cos_om;