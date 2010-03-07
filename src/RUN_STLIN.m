%'RUN_STLIN': combine velocity fields for stereo PIV
% file_A,file_B: input velocity files
%vel_type: string ='civ1' or 'civ2'
function RUN_STLIN(file_A,file_B,vel_type,file_st,nx_patch,ny_patch,thresh_patch,fileAxml,fileBxml)
                
 [XmlDataA,error]=imadoc2struct(fileAxml); 
 [XmlDataB,error]=imadoc2struct(fileBxml);
 npxA=[]; npyA=[]; pxB=[]; npyB=[];
 if isfield(XmlDataA,'Camera') && isfield(XmlDataB,'Camera')
      if isfield(XmlDataA.Camera,'ImageSize')&& isfield(XmlDataB.Camera,'ImageSize')
          ImageSizeA=XmlDataA.Camera.ImageSize;
          ImageSizeB=XmlDataB.Camera.ImageSize;
          if ~isempty(ImageSizeA)&& ~isempty(ImageSizeB)
               xindex=findstr(ImageSizeA,'x');
               if length(xindex)>=2
                    npxA=str2num(ImageSizeA(1:xindex(1)-1));
                    npyA=str2num(ImageSizeA(xindex(1)+1:xindex(2)-1));
               end
               xindex=findstr(ImageSizeB,'x');
               if length(xindex)>=2
                    npxB=str2num(ImageSizeB(1:xindex(1)-1));
                    npyB=str2num(ImageSizeB(xindex(1)+1:xindex(2)-1));
               end
          end
     end
 end
 if isempty(npxA) ||isempty(npxB)
     msgbox_uvmat('ERROR','The size of image A needs to be defined in the xml file ImaDoc')
     return
 elseif isempty(npxB) || isempty(npyB)
      msgbox_uvmat('ERROR','The size of image B needs to be defined in the xml file ImaDoc')
     return
 end
 if isfield(XmlDataA,'GeometryCalib')
     tsaiA=XmlDataA.GeometryCalib;
 else
     msgbox_uvmat('ERROR','no geometric calibration available for image A')
     return
 end
 if isfield(XmlDataB,'GeometryCalib')
     tsaiB=XmlDataB.GeometryCalib;
 else
     msgbox_uvmat('ERROR','no geometric calibration available for image B')
     return
 end
 
 %corners of each image in real coordinates:
 cornerA(:,1)=[0 0 npxA npxA]';%x positions
 cornerA(:,2)=[0 npyA 0 npyA]';%y positions
 cornerB(:,1)=[0 0 npxB npxB]';%x positions
 cornerB(:,2)=[0 npyB 0 npyB]';%y positions
[xyA(:,1),xyA(:,2)]=phys_XYZ(tsaiA,cornerA(:,1),cornerA(:,2));
[xyB(:,1),xyB(:,2)]=phys_XYZ(tsaiB,cornerB(:,1),cornerB(:,2));
 max_x=max(max(xyA(:,1)),max(xyB(:,1)));%maximum on the 4 corners of the the images
 min_x=min(min(xyA(:,1)),min(xyB(:,1)));%minimum on the 4 corners of the the images
 max_y=max(max(xyA(:,2)),max(xyB(:,2)));
 min_y=min(min(xyA(:,2)),min(xyB(:,2)));
 array_realx=[min_x:(max_x-min_x)/(nx_patch-1):max_x];
 array_realy=[min_y:(max_y-min_y)/(ny_patch-1):max_y];
 [grid_realx,grid_realy]=meshgrid(array_realx,array_realy);
 grid_real(:,1)=reshape(grid_realx,nx_patch*ny_patch,1);
 grid_real(:,2)=reshape(grid_realy,nx_patch*ny_patch,1);
 grid_real(:,3)=zeros(nx_patch*ny_patch,1);
[grid_imaA(:,1),grid_imaA(:,2)]=px_XYZ(tsaiA,grid_real(:,1),grid_real(:,2));
[grid_imaB(:,1),grid_imaB(:,2)]=px_XYZ(tsaiB,grid_real(:,1),grid_real(:,2));

 flagA=grid_imaA(:,1)>0 & grid_imaA(:,1)<npxA & grid_imaA(:,2)>0 & grid_imaA(:,2)<npyA;
 flagB=grid_imaB(:,1)>0 & grid_imaB(:,1)<npxB & grid_imaB(:,2)>0 & grid_imaB(:,2)<npyB;
 ind_good=find(flagA==1&flagB==1);
 XimaA=grid_imaA(ind_good,1);
 YimaA=grid_imaA(ind_good,2);
 XimaB=grid_imaB(ind_good,1);
 YimaB=grid_imaB(ind_good,2);
 grid_real_x=grid_real(ind_good,1);
 grid_real_y=grid_real(ind_good,2);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %read the velocity fields
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% [dt,time1,pixcmx,pixcmy,vec_X,vec_Y,vec_Z,vec_U,vec_V,vec_W,vec_C,vec_F,fixflag,vel_type_out,error,nb_coord,nb_dim]...
%     =read_vel({filecell_ncA},{vel_type});
%read field A
[Field,VelTypeOut]=read_civxdata(file_A,[],vel_type);
%interpolate on XimaA
Field.X=Field.X(find(Field.FF==0));
Field.Y=Field.Y(find(Field.FF==0));
Field.U=Field.U(find(Field.FF==0));
Field.V=Field.V(find(Field.FF==0));
dXa= griddata_uvmat(Field.X,Field.Y,Field.U,XimaA,YimaA);
dYa= griddata_uvmat(Field.X,Field.Y,Field.V,XimaA,YimaA);
dt=Field.dt;
time=Field.Time;

%read field B
% [dt,time2,pixcmx,pixcmy,vec_X,vec_Y,vec_Z,vec_U,vec_V,vec_W,vec_C,vec_F,fixflag,vel_type_out,error,nb_coord,nb_dim]...
%     =read_vel({file_B},{vel_type});
[Field,VelTypeOut]=read_civxdata(file_B,FieldNames,vel_type);
if ~isequal(Field.dt,dt)
    msgbox_uvmat('ERROR','different time intervals for the two velocity fields ')
     return
end
if ~isequal(Field.Time,time)
    msgbox_uvmat('ERROR','different times for the two velocity fields ')
     return
end
%interpolate on XimaB
Field.X=Field.X(find(Field.FF==0));
Field.Y=Field.Y(find(Field.FF==0));
Field.U=Field.U(find(Field.FF==0));
Field.V=Field.V(find(Field.FF==0));
dXb=griddata_uvmat(Field.X,Field.Y,Field.U,XimaB,YimaB);
dYb=griddata_uvmat(Field.X,Field.Y,Field.V,XimaB,YimaB);
%eliminate Not-a-Number 
ind_Nan=find(and(~isnan(dXa),~isnan(dXb)));
dXa=dXa(ind_Nan);
dYa=dYa(ind_Nan);
dXb=dXb(ind_Nan);
dYb=dYb(ind_Nan); 
grid_phys1(:,1)=grid_real_x(ind_Nan);
grid_phys1(:,2)=grid_real_y(ind_Nan);
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%compute the coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[A11,A12,A13,A21,A22,A23]=pxcm_tsai(tsaiA,grid_phys1);
[B11,B12,B13,B21,B22,B23]=pxcm_tsai(tsaiB,grid_phys1);

C1=A11.*A22-A12.*A21;
C2=A13.*A22-A12.*A23;
C3=A13.*A21-A11.*A23;
D1=B11.*B22-B12.*B21;
D2=B13.*B22-B12.*B23;
D3=B13.*B21-B11.*B23;
A1=(A22.*D1.*(C1.*D3-C3.*D1)+A21.*D1.*(C2.*D1-C1.*D2));
A2=(A12.*D1.*(C3.*D1-C1.*D3)+A11.*D1.*(C1.*D2-C2.*D1));
B1=(B22.*C1.*(C3.*D1-C1.*D3)+B21.*C1.*(C1.*D2-C2.*D1));
B2=(B12.*C1.*(C1.*D3-C3.*D1)+B11.*C1.*(C2.*D1-C1.*D2));
Lambda=(A1.*dXa+A2.*dYa+B1.*dXb+B2.*dYb)./(A1.*A1+A2.*A2+B1.*B1+B2.*B2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Projection for compatible displacements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ua=dXa-Lambda.*A1;
Va=dYa-Lambda.*A2;
Ub=dXb-Lambda.*B1;
Vb=dYb-Lambda.*B2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculations of displacements and error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
U=(A22.*D2.*Ua-A12.*D2.*Va-B22.*C2.*Ub+B12.*C2.*Vb)./(C1.*D2-C2.*D1);
V=(A21.*D3.*Ua-A11.*D3.*Va-B21.*C3.*Ub+B11.*C3.*Vb)./(C3.*D1-C1.*D3);
W=(A22.*D1.*Ua-A12.*D1.*Va-B22.*C1.*Ub+B12.*C1.*Vb)./(C2.*D1-C1.*D2);
W1=(-A21.*D1.*Ua+A11.*D1.*Va+B21.*C1.*Ub-B11.*C1.*Vb)./(C1.*D3-C3.*D1);

error=sqrt((A1.*dXa+A2.*dYa+B1.*dXb+B2.*dYb).*(A1.*dXa+A2.*dYa+B1.*dXb+B2.*dYb)./(A1.*A1+A2.*A2+B1.*B1+B2.*B2));

ind_error=(find(error<thresh_patch));
U=U(ind_error);
V=V(ind_error);
W=W(ind_error);%correction for water interface
error=error(ind_error);

%create nc grid file
Result.ListGlobalAttribute={'nb_coord','nb_dim','constant_pixcm','absolut_time_T0','hart','dt','civ'};
Result.nb_coord=3;%grid file, no velocity
Result.nb_dim=2;
Result.constant_pixcm=0;%no linear correspondance with images
Result.absolut_time_T0=time;%absolute time of the field
Result.hart=0;
Result.dt=dt;%time interval for image correlation (put  by default)
% cte.title='grid';
Result.civ=0;%not a civ file (no direct correspondance with an image)
Result.ListDimName={'nb_vectors'}
Result.DimValue=length(U);
Result.ListVarName={'vec_X';'vec_Y';'vec_U';'vec_V';'vec_W';'vec_E'};
Result.VarDimIndex: {[1]  [1]  [1]  [1]  [1]  [1]}
Result.vec_X= grid_phys1(ind_error,1);
Result.vec_Y= grid_phys1(ind_error,2);
Result.vec_U=U/dt;
Result.vec_V=V/dt;
Result.vec_W=W/dt;
Result.vec_E=error; 
% error=write_netcdf(file_st,cte,fieldlabels,grid_phys);
error=struct2nc(file_st,Result);
display([file_st ' written'])



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










