%XmlData=xml2struct('/home/users/sommeria/UVMAT_DEMO_SOURCES/UVMAT_DEMO07_GeometryCalibration/multiple_planes/Dalsa1.xml');
GeometryCalib.CalibrationType='3D_quad';
GeometryCalib.fx_fy=[4.0839e+03 4.0839e+03];
GeometryCalib.Cx_Cy=[511.5000 512.5000];
GeometryCalib.kc=0.5;
GeometryCalib.CoordUnit='cm';
GeometryCalib.Tx_Ty_Tz=[-47.9957 -48.4644 476.6510];
GeometryCalib.R=[0.9713    0.0518   -0.2320; -0.0813    0.9895   -0.1198; -0.2233   -0.1352   -0.9653];
%GeometryCalib.R=[0.9983    0.0485   -0.0332;-0.0500    0.9976   -0.0470;-0.0308   -0.0485   -0.9983]
Slice.SliceCoord=[50 30 100];
Slice.SliceAngle=[10 20 0];
 
% Xpx=1000
% Ypx=1000
Xpx=1000
Ypx=1000
[Xphys,Yphys,Zphys]=phys_XYZ(GeometryCalib,Slice,Xpx,Ypx,1)
[NewXpx,NewYpx]=px_XYZ(GeometryCalib,[],Xphys,Yphys,Zphys);
disp(['error= '])
disp([NewXpx-Xpx NewYpx-Ypx])

% 
% 
% om=norm(GeometryCalib.SliceAngle);%norm of rotation angle in radians
%         OmAxis=GeometryCalib.SliceAngle/om; %unit vector marking the rotation axis
%         cos_om=cos(pi*om/180);
%         sin_om=sin(pi*om/180);
%         coeff=OmAxis(3)*(1-cos_om);
%         norm_plane(1)=OmAxis(1)*coeff+OmAxis(2)*sin_om;
%         norm_plane(2)=OmAxis(2)*coeff-OmAxis(1)*sin_om;
%         norm_plane(3)=OmAxis(3)*coeff+cos_om
%         
%         M=rodrigues(XmlData.GeometryCalib.SliceAngle*pi/180);
%         norm_plane=M*[0 0 1]'