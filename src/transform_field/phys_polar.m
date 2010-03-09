%transform image coordinates (px) to physical coordinates
% then transform to polar coordinates: 
%[DataOut,DataOut_1]=phys_polar(varargin)
%
% OUTPUT: 
% DataOut: structure of modified data field: .X=radius, .Y=azimuth angle, .U, .V are radial and azimuthal velocity components
% DataOut_1:  second data field (if two fields are in input)
%
%INPUT:
% Data:  structure of input data (like UvData)
% CalibData= structure containing the field .GeometryCalib with calibration parameters
% Data_1:  second input field (not mandatory)
% CalibData_1= calibration parameters for the second field

function [DataOut,DataOut_1]=phys_polar(varargin)
Calib{1}=[];
if nargin==2||nargin==4
    Data=varargin{1};
    DataOut=Data;%default
    DataOut_1=[];%default
    CalibData=varargin{2};
    if isfield(CalibData,'GeometryCalib')
        Calib{1}=CalibData.GeometryCalib;
    end
    Calib{2}=Calib{1};
else
    DataOut.Txt='wrong input: need two or four structures';
end
test_1=0;
if nargin==4
    test_1=1;
    Data_1=varargin{3};
    DataOut_1=Data_1;%default
    CalibData_1=varargin{4};
    if isfield(CalibData_1,'GeometryCalib')
        Calib{2}=CalibData_1.GeometryCalib;
    end
end

%parameters for polar coordinates (taken from the calibration data of the first field)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
origin_xy=[0 0];%center for the polar coordinates in the original x,y coordinates
if isfield(Calib{1},'PolarCentre') && isnumeric(Calib{1}.PolarCentre)
    if isequal(length(Calib{1}.PolarCentre),2);
        origin_xy= Calib{1}.PolarCentre;
    end
end
radius_offset=0;%reference radius used to offset the radial coordinate r 
angle_offset=0; %reference angle used as new origin of the polar angle (= axis Ox by default)
if isfield(Calib{1},'PolarReferenceRadius') && isnumeric(Calib{1}.PolarReferenceRadius)
    radius_offset=Calib{1}.PolarReferenceRadius;
end
if radius_offset > 0
    angle_scale=radius_offset; %the azimuth is rescale in terms of the length along the reference radius
else
    angle_scale=180/pi; %polar angle in degrees 
end
if isfield(Calib{1},'PolarReferenceAngle') && isnumeric(Calib{1}.PolarReferenceAngle)
    angle_offset=Calib{1}.PolarReferenceAngle; %offset angle (in unit of the final angle, degrees or arc length along the reference radius))
end
% new x coordinate = radius-radius_offset;
% new y coordinate = theta*angle_scale-angle_offset

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iscalar=0;
if  ~isempty(Calib{1})
    DataOut=phys_1(Data,Calib{1},origin_xy,radius_offset,angle_offset,angle_scale);
    %case of images or scalar
    if isfield(Data,'A')&isfield(Data,'AX')&~isempty(Data.AX) & isfield(Data,'AY')&...
                                           ~isempty(Data.AY)&length(Data.A)>1
        iscalar=1;
        A{1}=Data.A;
    end
    %transform of X,Y coordinates for vector fields
    if isfield(Data,'ZIndex')&~isempty(Data.ZIndex)
        ZIndex=Data.ZIndex;
    else
        ZIndex=0;
    end
end

if test_1
    DataOut_1=phys_1(Data_1,Calib{2},origin_xy,radius_offset,angle_offset,angle_scale);
    if isfield(Data_1,'A')&isfield(Data_1,'AX')&~isempty(Data_1.AX) & isfield(Data_1,'AY')&...
                                       ~isempty(Data_1.AY)&length(Data_1.A)>1
          iscalar=iscalar+1;
          Calib{iscalar}=Calib{2};
          A{iscalar}=Data_1.A;
          if isfield(Data_1,'ZIndex')&~isequal(Data_1.ZIndex,ZIndex)
              DataOut.Txt='inconsistent plane indexes in the two input fields';
          end
          if iscalar==1% case for which only the second field is a scalar
               [A,AX,AY]=phys_Ima(A,Calib,ZIndex,origin_xy,radius_offset,angle_offset,angle_scale);
               DataOut_1.A=A{1};
               DataOut_1.AX=AX; 
               DataOut_1.AY=AY;
               return
          end
    end
end
if iscalar~=0
    [A,AX,AY]=phys_Ima(A,Calib,ZIndex,origin_xy,radius_offset,angle_offset,angle_scale);%
    DataOut.A=A{1};
    DataOut.AX=AX; 
    DataOut.AY=AY;
    if iscalar==2
        DataOut_1.A=A{2};
        DataOut_1.AX=AX; 
        DataOut_1.AY=AY;
    end
end

%------------------------------------------------
function DataOut=phys_1(Data,Calib,origin_xy,radius_offset,angle_offset,angle_scale)

DataOut=Data;
DataOut.CoordType='phys'; %put flag for physical coordinates
if isfield(Calib,'CoordUnit')
    DataOut.CoordUnit=Calib.CoordUnit;
else
    DataOut.CoordUnit='cm'; %default
end
DataOut.TimeUnit='s';
%perform a geometry transform if Calib contains a field .GeometryCalib 
if isfield(Data,'CoordType') && isequal(Data.CoordType,'px') && ~isempty(Calib)
    if isfield(Data,'CoordUnit')
         DataOut=rmfield(DataOut,'CoordUnit');
    end
    %transform of X,Y coordinates for vector fields
    if isfield(Data,'ZIndex')&~isempty(Data.ZIndex)
        Z=Data.ZIndex;
    else
        Z=0;
    end
    if isfield(Data,'X') &isfield(Data,'Y')&~isempty(Data.X) & ~isempty(Data.Y)
        [DataOut.X,DataOut.Y,DataOut.Z]=phys_XYZ(Calib,Data.X,Data.Y,Z); %transform from pixels to physical
        DataOut.X=DataOut.X-origin_xy(1);%origin of coordinates at the tank center
        DataOut.Y=DataOut.Y-origin_xy(2);%origin of coordinates at the tank center
        [theta,DataOut.X] = cart2pol(DataOut.X,DataOut.Y);%theta  and X are the polar coordinates angle and radius
          %shift and renormalize the polar coordinates
        DataOut.X=DataOut.X-radius_offset;%
        DataOut.Y=theta*angle_scale-angle_offset;% normalized angle: distance along reference radius
        %transform velocity field if exists
        if isfield(Data,'U')&isfield(Data,'V')&~isempty(Data.U) & ~isempty(Data.V)& isfield(Data,'dt') 
            if ~isempty(Data.dt)
            [XOut_1,YOut_1]=phys_XYZ(Calib,Data.X-Data.U/2,Data.Y-Data.V/2,Z);
            [XOut_2,YOut_2]=phys_XYZ(Calib,Data.X+Data.U/2,Data.Y+Data.V/2,Z);
            UX=(XOut_2-XOut_1)/Data.dt;
            VY=(YOut_2-YOut_1)/Data.dt;      
            %transform u,v into polar coordiantes
            DataOut.U=UX.*cos(theta)+VY.*sin(theta);%radial velocity
            DataOut.V=(-UX.*sin(theta)+VY.*cos(theta));%./(DataOut.X)%+radius_ref);%angular velocity calculated 
            %shift and renormalize the angular velocity
            end
        end
    end
end

 
%%%%%%%%%%%%%%%%%%%%
function [A_out,Rangx,Rangy]=phys_Ima(A,CalibIn,ZIndex,origin_xy,radius_offset,angle_offset,angle_scale)
xcorner=[];
ycorner=[];
npx=[];
npy=[];

for icell=1:length(A)
    siz=size(A{icell});
    npx=[npx siz(2)];
    npy=[npy siz(1)];
    zphys=0; %default
    if isfield(CalibIn{icell},'SliceCoord') %.Z= index of plane
       SliceCoord=CalibIn{icell}.SliceCoord(ZIndex,:);
       zphys=SliceCoord(3); %to generalize for non-parallel planes
    end
    xima=[0.5 siz(2)-0.5 0.5 siz(2)-0.5];%image coordiantes of corners
    yima=[0.5 0.5 siz(1)-0.5 siz(1)-0.5];
    [xcorner_new,ycorner_new]=phys_XYZ(CalibIn{icell},xima,yima,ZIndex);%corresponding physical coordinates
    %transform the corner coordinates into polar ones    
    xcorner_new=xcorner_new-origin_xy(1);%shift to the origin of the polar coordinates 
    ycorner_new=ycorner_new-origin_xy(2);%shift to the origin of the polar coordinates       
    [theta,xcorner_new] = cart2pol(xcorner_new,ycorner_new);%theta  and X are the polar coordinates angle and radius
    if (max(theta)-min(theta))>pi   %if the polar origin is inside the image
        xcorner_new=[0 max(xcorner_new)];
        theta=[-pi pi];
    end
          %shift and renormalize the polar coordinates
    xcorner_new=xcorner_new-radius_offset;%
    ycorner_new=theta*angle_scale-angle_offset;% normalized angle: distance along reference radius
    xcorner=[xcorner xcorner_new];
    ycorner=[ycorner ycorner_new];
end
Rangx(1)=min(xcorner);
Rangx(2)=max(xcorner);
Rangy(2)=min(ycorner);
Rangy(1)=max(ycorner);
% test_multi=(max(npx)~=min(npx)) | (max(npy)~=min(npy)); 
npx=max(npx);
npy=max(npy);
x=linspace(Rangx(1),Rangx(2),npx);
y=linspace(Rangy(1),Rangy(2),npy);
[X,Y]=meshgrid(x,y);%grid in physical coordinates
%transform X, Y in cartesian
X=X+radius_offset;%
Y=(Y+angle_offset)/angle_scale;% normalized angle: distance along reference radius
[X,Y] = pol2cart(Y,X);
X=X+origin_xy(1);%shift to the origin of the polar coordinates 
Y=Y+origin_xy(2);%shift to the origin of the polar coordinates 
for icell=1:length(A) 
    [XIMA,YIMA]=px_XYZ(CalibIn{icell},X,Y,zphys);%corresponding image indices for each point in the real space grid
    XIMA=reshape(round(XIMA),1,npx*npy);%indices reorganized in 'line'
    YIMA=reshape(round(YIMA),1,npx*npy);
    flagin=XIMA>=1 & XIMA<=npx & YIMA >=1 & YIMA<=npy;%flagin=1 inside the original image
    vec_A=reshape(A{icell}(:,:,1),1,npx*npy);%put the original image in line
    ind_in=find(flagin);
    ind_out=find(~flagin);
    ICOMB=((XIMA-1)*npy+(npy+1-YIMA));
    ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
    vec_B(ind_in)=vec_A(ICOMB);
    vec_B(ind_out)=zeros(size(ind_out));
    A_out{icell}=reshape(vec_B,npy,npx);%new image in real coordinates
end
%Rangx=Rangx-radius_offset;

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


