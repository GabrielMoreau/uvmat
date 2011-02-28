%'phys': transforms image (px) to real world (phys) coordinates using geometric calibration parameters
% DataOut=phys(Data,CalibData) , transform one input field
% [DataOut,DataOut_1]=phys(Data,CalibData,Data_1,CalibData_1), transform two input fields

% OUTPUT: 
% DataOut:   structure representing the modified field
% DataOut_1: structure representing the second modified field

%INPUT:
% Data:  structure of input data 
%       with fields .A (image or scalar matrix), AX, AY
%       .X,.Y,.U,.V, .DjUi
%       .ZIndex: index of plane in multilevel case 
%       .CoordType='phys' or 'px', The function ACTS ONLY IF .CoordType='px'
% CalibData: structure containing calibration parameters or a subtree Calib.GeometryCalib =calibration data (tsai parameters)

function [DataOut,DataOut_1]=phys(varargin)
% A FAIRE: 1- verifier si DataIn est une 'field structure'(.ListVarName'):
% chercher ListVarAttribute, for each field (cell of variables):
%   .CoordType: 'phys' or 'px'   (default==phys, no transform)
%   .scale_factor: =dt (to transform displacement into velocity) default=1
%   .covariance: 'scalar', 'coord', 'D_i': covariant (like velocity), 'D^i': contravariant (like gradient), 'D^jD_i' (like strain tensor)
%   (default='coord' if .Role='coord_x,_y..., 
%            'D_i' if '.Role='vector_x,...',
%              'scalar', else (thenno change except scale factor)
Calib{1}=[];
if nargin==2||nargin==4 % nargin =nbre of input variables
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
iscalar=0;
if  ~isempty(Calib{1})
    DataOut=phys_1(Data,Calib{1});
    %case of images or scalar: in case of two input fields, we need to project the transform of on the same regular grid
    if isfield(Data,'A') && isfield(Data,'AX') && ~isempty(Data.AX) && isfield(Data,'AY')&&...
                                           ~isempty(Data.AY) && length(Data.A)>1
        iscalar=1;
        A{1}=Data.A;
    end
end
%transform of X,Y coordinates for vector fields
if isfield(Data,'ZIndex')&&~isempty(Data.ZIndex)&&~isnan(Data.ZIndex)
    ZIndex=Data.ZIndex;
else
    ZIndex=1;
end
if test_1
    DataOut_1=phys_1(Data_1,Calib{2});
    if isfield(Data_1,'A')&&isfield(Data_1,'AX')&&~isempty(Data_1.AX) && isfield(Data_1,'AY')&&...
                                       ~isempty(Data_1.AY)&&length(Data_1.A)>1
          iscalar=iscalar+1;
          Calib{iscalar}=Calib{2};
          A{iscalar}=Data_1.A;
          if isfield(Data_1,'ZIndex') && ~isequal(Data_1.ZIndex,ZIndex)
              DataOut.Txt='inconsistent plane indexes in the two input fields';
          end
          if iscalar==1% case for which only the second field is a scalar
               [A,AX,AY]=phys_Ima(A,Calib,ZIndex);
               DataOut_1.A=A{1};
               DataOut_1.AX=AX; 
               DataOut_1.AY=AY;
               return
          end
    end
end
if iscalar~=0
    [A,AX,AY]=phys_Ima(A,Calib,ZIndex);%TODO : introduire interp2_uvmat ds phys_ima
    DataOut.A=A{1};
    DataOut.AX=AX; 
    DataOut.AY=AY;
    if iscalar==2
        DataOut_1.A=A{2};
        DataOut_1.AX=AX; 
        DataOut_1.AY=AY;
    end
end

% DataOut.VarDimName{2}
% DataOut.VarDimName{3}
% DataOut.VarDimName{4}
% DataOut.VarDimName{5}
% DataOut.VarDimName{6}
% DataOut.VarDimName{7}
% DataOut.VarAttribute{1}
% DataOut.VarAttribute{2}
% DataOut.VarAttribute{3}
% DataOut.VarAttribute{4}
% DataOut.VarAttribute{5}
% DataOut.VarAttribute{6}
% DataOut.VarAttribute{7}
%------------------------------------------------
function DataOut=phys_1(Data,Calib)
% for icell=1:length(Data)

DataOut=Data;%default
% DataOut.CoordUnit=Calib.CoordUnit; %put flag for physical coordinates
if isfield(Calib,'SliceCoord') && isfield(Data,'ZIndex')&&~isempty(Data.ZIndex)&&~isnan(Data.ZIndex)
    DataOut.PlaneCoord=Calib.SliceCoord(Data.ZIndex,:);% transfer the slice position
    if isfield(Calib,'SliceAngle') % transfer the slice rotation angles
        DataOut.PlaneAngle=Calib.SliceAngle(Data.ZIndex,:);
    end
end
% The transform ACTS ONLY IF .CoordType='px'and Calib defined
if isfield(Data,'CoordUnit')%&& isequal(Data.CoordType,'px')&& ~isempty(Calib)
    if isfield(Calib,'CoordUnit')
        DataOut.CoordUnit=Calib.CoordUnit;
    else
        DataOut.CoordUnit='cm'; %default
    end
    DataOut.TimeUnit='s';
    %transform of X,Y coordinates for vector fields
    test_z=0;
    if isfield(Data,'ZIndex') && ~isempty(Data.ZIndex)&&~isnan(Data.ZIndex)
        Z=Data.ZIndex;
        test_z=1;
    else
        Z=0;
    end
    if isfield(Data,'X') &&isfield(Data,'Y')&&~isempty(Data.X) && ~isempty(Data.Y)
        [DataOut.X,DataOut.Y,DataOut.Z]=phys_XYZ(Calib,Data.X,Data.Y,Z); 
        if test_z
             DataOut.ListVarName=[DataOut.ListVarName(1:2) {'Z'} DataOut.ListVarName(3:end)];
             DataOut.VarDimName=[DataOut.VarDimName(1:2) DataOut.VarDimName(1) DataOut.VarDimName(3:end)];
             ZAttribute{1}.Role='coord_z';
             DataOut.VarAttribute=[DataOut.VarAttribute(1:2) ZAttribute DataOut.VarAttribute(3:end)];
        end
        if isfield(Data,'U')&&isfield(Data,'V')&&~isempty(Data.U) && ~isempty(Data.V)&& isfield(Data,'dt') 
            if ~isempty(Data.dt)
            [XOut_1,YOut_1]=phys_XYZ(Calib,Data.X-Data.U/2,Data.Y-Data.V/2,Z);
            [XOut_2,YOut_2]=phys_XYZ(Calib,Data.X+Data.U/2,Data.Y+Data.V/2,Z);
            DataOut.U=(XOut_2-XOut_1)/Data.dt;
            DataOut.V=(YOut_2-YOut_1)/Data.dt;
            end
        end
    end
    %transform of an image or scalar: done in phys_ima
      
    %transform of spatial derivatives
    if isfield(Data,'X') && ~isempty(Data.X) && isfield(Data,'DjUi') && ~isempty(Data.DjUi)...
          && isfield(Data,'dt')    
        if ~isempty(Data.dt)
            % estimate the Jacobian matrix DXpx/DXphys 
            for ip=1:length(Data.X) 
                [Xp1,Yp1]=phys_XYZ(Calib,Data.X(ip)+0.5,Data.Y(ip),Z);
                [Xm1,Ym1]=phys_XYZ(Calib,Data.X(ip)-0.5,Data.Y(ip),Z);
                [Xp2,Yp2]=phys_XYZ(Calib,Data.X(ip),Data.Y(ip)+0.5,Z);
                [Xm2,Ym2]=phys_XYZ(Calib,Data.X(ip),Data.Y(ip)-0.5,Z); 
            %Jacobian matrix DXpphys/DXpx
               DjXi(1,1)=(Xp1-Xm1);
               DjXi(2,1)=(Yp1-Ym1);
               DjXi(1,2)=(Xp2-Xm2);
               DjXi(2,2)=(Yp2-Ym2);
               DjUi(:,:)=Data.DjUi(ip,:,:);
               DjUi=(DjXi*DjUi')/DjXi;% =J-1*M*J , curvature effects (derivatives of J) neglected
               DataOut.DjUi(ip,:,:)=DjUi';
            end
            DataOut.DjUi =  DataOut.DjUi/Data.dt;   %     min(Data.DjUi(:,1,1))=DUDX                          
        end
    end
end

%%%%%%%%%%%%%%%%%%%%
function [A_out,Rangx,Rangy]=phys_Ima(A,CalibIn,ZIndex)
xcorner=[];
ycorner=[];
npx=[];
npy=[];
dx=ones(1,length(A));
dy=ones(1,length(A));
for icell=1:length(A)
    siz=size(A{icell});
    npx=[npx siz(2)];
    npy=[npy siz(1)];
    Calib=CalibIn{icell};
    xima=[0.5 siz(2)-0.5 0.5 siz(2)-0.5];%image coordinates of corners
    yima=[0.5 0.5 siz(1)-0.5 siz(1)-0.5];
    [xcorner_new,ycorner_new]=phys_XYZ(Calib,xima,yima,ZIndex);%corresponding physical coordinates
    dx(icell)=(max(xcorner_new)-min(xcorner_new))/(siz(2)-1);
    dy(icell)=(max(ycorner_new)-min(ycorner_new))/(siz(1)-1);
    xcorner=[xcorner xcorner_new];
    ycorner=[ycorner ycorner_new];
end
Rangx(1)=min(xcorner);
Rangx(2)=max(xcorner);
Rangy(2)=min(ycorner);
Rangy(1)=max(ycorner);
test_multi=(max(npx)~=min(npx)) || (max(npy)~=min(npy)); %different image lengths
npX=1+round((Rangx(2)-Rangx(1))/min(dx));% nbre of pixels in the new image (use the finest resolution min(dx) in the set of images)
npY=1+round((Rangy(1)-Rangy(2))/min(dy));
x=linspace(Rangx(1),Rangx(2),npX);
y=linspace(Rangy(1),Rangy(2),npY);
[X,Y]=meshgrid(x,y);%grid in physical coordiantes
vec_B=[];
A_out={};
for icell=1:length(A) 
    Calib=CalibIn{icell};
    if isfield(Calib,'R') || isfield(Calib,'kc')|| test_multi ||~isequal(Calib,CalibIn{1})% the image needs to be interpolated to the new coordinates
        zphys=0; %default
        if isfield(Calib,'SliceCoord') %.Z= index of plane
           SliceCoord=Calib.SliceCoord(ZIndex,:);
           zphys=SliceCoord(3); %to generalize for non-parallel planes
           if isfield(Calib,'InterfaceCoord') && isfield(Calib,'RefractionIndex') 
                H=Calib.InterfaceCoord(3);
                if H>zphys
                    zphys=H-(H-zphys)/Calib.RefractionIndex; %corrected z (virtual object)
                end
           end
        end
        [XIMA,YIMA]=px_XYZ(CalibIn{icell},X,Y,zphys);% image coordinates for each point in the real space grid
        XIMA=reshape(round(XIMA),1,npX*npY);%indices reorganized in 'line'
        YIMA=reshape(round(YIMA),1,npX*npY);
        flagin=XIMA>=1 & XIMA<=npx(icell) & YIMA >=1 & YIMA<=npy(icell);%flagin=1 inside the original image
        testuint8=isa(A{icell},'uint8');
        testuint16=isa(A{icell},'uint16');
        if numel(siz)==2 %(B/W images)
            vec_A=reshape(A{icell},1,npx(icell)*npy(icell));%put the original image in line
            %ind_in=find(flagin);
            ind_out=find(~flagin);
            ICOMB=((XIMA-1)*npy(icell)+(npy(icell)+1-YIMA));
            ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
            %vec_B(ind_in)=vec_A(ICOMB);
            vec_B(flagin)=vec_A(ICOMB);
            vec_B(~flagin)=zeros(size(ind_out));
%             vec_B(ind_out)=zeros(size(ind_out));
            A_out{icell}=reshape(vec_B,npY,npX);%new image in real coordinates
        elseif numel(siz)==3     
            for icolor=1:siz(3)
                vec_A=reshape(A{icell}(:,:,icolor),1,npx*npy);%put the original image in line
               % ind_in=find(flagin);
                ind_out=find(~flagin);
                ICOMB=((XIMA-1)*npy+(npy+1-YIMA));
                ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
                vec_B(flagin)=vec_A(ICOMB);
                vec_B(~flagin)=zeros(size(ind_out));
                A_out{icell}(:,:,icolor)=reshape(vec_B,npy,npx);%new image in real coordinates
            end
        end
        if testuint8
            A_out{icell}=uint8(A_out{icell});
        end
        if testuint16
            A_out{icell}=uint16(A_out{icell});
        end
    else%      
        A_out{icell}=A{icell};%no transform
        Rangx=[0.5 npx-0.5];%image coordiantes of corners
        Rangy=[npy-0.5 0.5];
        [Rangx]=phys_XYZ(Calib,Rangx,[0.5 0.5],ZIndex);%case of translations without rotation and quadratic deformation
        [xx,Rangy]=phys_XYZ(Calib,[0.5 0.5],Rangy,ZIndex);
    end
end

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
    if isfield(Calib, 'SliceAngle') && ~isequal(Calib.SliceAngle,[0 0 0])
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
    dpx=Calib.fx_fy(2)/Calib.fx_fy(1);
    Dx=R(5)*R(7)-R(4)*R(8);
    Dy=R(1)*R(8)-R(2)*R(7);
    D0=f*(R(2)*R(4)-R(1)*R(5));
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
    X0=f*(R(5)*Tx-R(2)*Ty+Zx0*Z0virt);
    Y0=f*(-R(4)*Tx+R(1)*Ty+Zy0*Z0virt);
        %px to camera:
    Xd=dpx*(X-Calib.Cx_Cy(1)); % sensor coordinates
    Yd=(Y-Calib.Cx_Cy(2));
    dist_fact=1+Calib.kc*(Xd.*Xd+Yd.*Yd)/(f*f); %distortion factor
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




