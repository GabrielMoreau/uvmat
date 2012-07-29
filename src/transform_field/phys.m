%'phys': transforms image (px) to real world (phys) coordinates using geometric calibration parameters
% DataOut=phys(Data,CalibData) , transform one input field
% [DataOut,DataOut_1]=phys(Data,CalibData,Data_1,CalibData_1), transform two input fields

% OUTPUT: 
% DataOut:   structure representing the first field in phys coordinates
% DataOut_1: structure representing the second  field in phys coordinates

%INPUT:
% Data:  structure of input data 
%       with fields .A (image or scalar matrix), AX, AY
%       .X,.Y,.U,.V, .DjUi
%       .ZIndex: index of plane in multilevel case 
%       .CoordType='phys' or 'px', The function ACTS ONLY IF .CoordType='px'
% CalibData: structure containing calibration parameters or a subtree Calib.GeometryCalib =calibration data (tsai parameters)
% Data_1, CalibData_1: same as Data, CalibData for the second field.

function [DataOut,DataOut_1]=phys(DataIn,XmlData,DataIn_1,XmlData_1)
% A FAIRE: 1- verifier si DataIn est une 'field structure'(.ListVarName'):
% chercher ListVarAttribute, for each field (cell of variables):
%   .CoordType: 'phys' or 'px'   (default==phys, no transform)
%   .scale_factor: =dt (to transform displacement into velocity) default=1
%   .covariance: 'scalar', 'coord', 'D_i': covariant (like velocity), 'D^i': contravariant (like gradient), 'D^jD_i' (like strain tensor)
%   (default='coord' if .Role='coord_x,_y..., 
%            'D_i' if '.Role='vector_x,...',
%              'scalar', else (thenno change except scale factor)
%% set GUI config
DataOut=[];
DataOut_1=[]; %default second  output field
if strcmp(DataIn,'*')
    if isfield(XmlData,'GeometryCalib')&& isfield(XmlData.GeometryCalib,'CoordUnit')
        DataOut.CoordUnit=XmlData.GeometryCalib.CoordUnit;
    end
    return
end

%% analyse input and set default output
DataOut=DataIn;%default first output field
if nargin>=2 % nargin =nbre of input variables
    if isfield(XmlData,'GeometryCalib')
        Calib{1}=XmlData.GeometryCalib;
    else
        Calib{1}=[];
    end
    if nargin>=3  %two input fields
        DataOut_1=DataIn_1;%default second output field
        if nargin>=4 && isfield(XmlData_1,'GeometryCalib')
            Calib{2}=XmlData_1.GeometryCalib;
        else
            Calib{2}=Calib{1}; 
        end
    end
end

%% get the z index defining the section plane
if isfield(DataIn,'ZIndex')&&~isempty(DataIn.ZIndex)&&~isnan(DataIn.ZIndex)
    ZIndex=DataIn.ZIndex;
else
    ZIndex=1;
end

%% transform first field
iscalar=0;% counter of scalar fields
if  ~isempty(Calib{1})
    if ~isfield(Calib{1},'CalibrationType')||~isfield(Calib{1},'CoordUnit')
        return %bad calib parameter input
    end
    if ~(isfield(DataIn,'CoordUnit')&& strcmp(DataIn.CoordUnit,'pixel'))
        return % transform only fields in pixel coordinates
    end
    DataOut=phys_1(DataIn,Calib{1},ZIndex);% transform coordiantes and velocity components
    %case of images or scalar: in case of two input fields, we need to project the transform  on the same regular grid
    if isfield(DataIn,'A') && isfield(DataIn,'AX') && ~isempty(DataIn.AX) && isfield(DataIn,'AY')&&...
                                           ~isempty(DataIn.AY) && length(DataIn.A)>1
        iscalar=1;
        A{1}=DataIn.A;
    end
end

%% document the selected  plane position and angle if relevant
if isfield(Calib{1},'SliceCoord')&&size(Calib{1}.SliceCoord,1)>=ZIndex
    DataOut.PlaneCoord=Calib{1}.SliceCoord(ZIndex,:);% transfer the slice position corresponding to index ZIndex
    if isfield(Calib{1},'SliceAngle') % transfer the slice rotation angles
        if isequal(size(Calib{1}.SliceAngle,1),1)% case of a unique angle
            DataOut.PlaneAngle=Calib{1}.SliceAngle;
        else  % case of multiple planes with different angles: select the plane with index ZIndex
            DataOut.PlaneAngle=Calib{1}.SliceAngle(ZIndex,:);
        end
    end
end

%% transform second field if relevant
if ~isempty(DataOut_1)
    if isfield(DataIn_1,'ZIndex') && ~isequal(DataIn_1.ZIndex,ZIndex)
        DataOut_1.Txt='different plane indices for the two input fields';
        return
    end
    if ~isfield(Calib{2},'CalibrationType')||~isfield(Calib{2},'CoordUnit')
        return %bad calib parameter input
    end
    if ~(isfield(DataIn_1,'CoordUnit')&& strcmp(DataIn_1.CoordUnit,'pixel'))
        return % transform only fields in pixel coordinates
    end
    DataOut_1=phys_1(DataOut_1,Calib{2},ZIndex);
    if isfield(Calib{1},'SliceCoord')
        if ~(isfield(Calib{2},'SliceCoord') && isequal(Calib{2}.SliceCoord,Calib{1}.SliceCoord))
            DataOut_1.Txt='different plane positions for the two input fields';
            return
        end        
        DataOut_1.PlaneCoord=DataOut.PlaneCoord;% same plane position for the two input fields
        if isfield(Calib{1},'SliceAngle')
            if ~(isfield(Calib{2},'SliceAngle') && isequal(Calib{2}.SliceAngle,Calib{1}.SliceAngle))
                DataOut_1.Txt='different plane angles for the two input fields';
                return
            end
            DataOut_1.PlaneAngle=DataOut.PlaneAngle; % same plane angle for the two input fields
        end
    end
    if isfield(DataIn_1,'A')&&isfield(DataIn_1,'AX')&&~isempty(DataIn_1.AX) && isfield(DataIn_1,'AY')&&...
            ~isempty(DataIn_1.AY)&&length(DataIn_1.A)>1
        iscalar=iscalar+1;
        Calib{iscalar}=Calib{2};
        A{iscalar}=DataIn_1.A;
    end
end

%% transform the scalar(s) or image(s)
if iscalar~=0
    [A,AX,AY]=phys_Ima(A,Calib,ZIndex);%TODO : introduire interp2_uvmat ds phys_ima
    if iscalar==1 && ~isempty(DataOut_1) % case for which only the second field is a scalar
         DataOut_1.A=A{1};
         DataOut_1.AX=AX; 
         DataOut_1.AY=AY;
    else
        DataOut.A=A{1};
        DataOut.AX=AX; 
        DataOut.AY=AY;
    end
    if iscalar==2
        DataOut_1.A=A{2};
        DataOut_1.AX=AX; 
        DataOut_1.AY=AY;
    end
end

%------------------------------------------------
%--- transform a single field
function DataOut=phys_1(Data,Calib,ZIndex)
%------------------------------------------------
%% set default output
DataOut=Data;%default
DataOut.CoordUnit=Calib.CoordUnit;% the output coord unit is set by the calibration parameters

%% transform  X,Y coordinates for velocity fields (transform of an image or scalar done in phys_ima)
if isfield(Data,'X') &&isfield(Data,'Y')&&~isempty(Data.X) && ~isempty(Data.Y)
  [DataOut.X,DataOut.Y]=phys_XYZ(Calib,Data.X,Data.Y,ZIndex);
    Dt=1; %default
    if isfield(Data,'dt')&&~isempty(Data.dt)
        Dt=Data.dt;
    end
    if isfield(Data,'Dt')&&~isempty(Data.Dt)
        Dt=Data.Dt;
    end
    if isfield(Data,'U')&&isfield(Data,'V')&&~isempty(Data.U) && ~isempty(Data.V)
        [XOut_1,YOut_1]=phys_XYZ(Calib,Data.X-Data.U/2,Data.Y-Data.V/2,ZIndex);
        [XOut_2,YOut_2]=phys_XYZ(Calib,Data.X+Data.U/2,Data.Y+Data.V/2,ZIndex);
        DataOut.U=(XOut_2-XOut_1)/Dt;
        DataOut.V=(YOut_2-YOut_1)/Dt;
    end
%     if ~strcmp(Calib.CalibrationType,'rescale') && isfield(Data,'X_tps') && isfield(Data,'Y_tps') 
%         [DataOut.X_tps,DataOut.Y_tps]=phys_XYZ(Calib,Data.X,Data.Y,ZIndex);
%     end
end

%% suppress tps
list_tps={'Coord_tps'  'U_tps'  'V_tps'  'SubRange'  'NbSites'};
ind_remove=[];
for ilist=1:numel(list_tps)
    ind_tps=find(strcmp(list_tps{ilist},Data.ListVarName));
    if ~isempty(ind_tps)
        ind_remove=[ind_remove ind_tps];
        DataOut=rmfield(DataOut,list_tps{ilist});
    end
end
DataOut.ListVarName(ind_remove)=[];
DataOut.VarDimName(ind_remove)=[];
DataOut.VarAttribute(ind_remove)=[];
    
    

%% transform of spatial derivatives: TODO check the case with plane angles
if isfield(Data,'X') && ~isempty(Data.X) && isfield(Data,'DjUi') && ~isempty(Data.DjUi)...
      && isfield(Data,'dt')    
    if ~isempty(Data.dt)
        % estimate the Jacobian matrix DXpx/DXphys 
        for ip=1:length(Data.X) 
            [Xp1,Yp1]=phys_XYZ(Calib,Data.X(ip)+0.5,Data.Y(ip),ZIndex);
            [Xm1,Ym1]=phys_XYZ(Calib,Data.X(ip)-0.5,Data.Y(ip),ZIndex);
            [Xp2,Yp2]=phys_XYZ(Calib,Data.X(ip),Data.Y(ip)+0.5,ZIndex);
            [Xm2,Ym2]=phys_XYZ(Calib,Data.X(ip),Data.Y(ip)-0.5,ZIndex); 
        %Jacobian matrix DXpphys/DXpx
           DjXi(1,1)=(Xp1-Xm1);
           DjXi(2,1)=(Yp1-Ym1);
           DjXi(1,2)=(Xp2-Xm2);
           DjXi(2,2)=(Yp2-Ym2);
           DjUi(:,:)=Data.DjUi(ip,:,:);
           DjUi=(DjXi*DjUi')/DjXi;% =J-1*M*J , curvature effects (derivatives of J) neglected
           DataOut.DjUi(ip,:,:)=DjUi';
        end
        DataOut.DjUi =  DataOut.DjUi/Dt;   %     min(Data.DjUi(:,1,1))=DUDX                          
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
    % rescaling of the image coordinates without change of the image array
    if strcmp(Calib.CalibrationType,'rescale') && isequal(Calib,CalibIn{1})
        A_out{icell}=A{icell};%no transform
        Rangx=[0.5 npx-0.5];%image coordiantes of corners
        Rangy=[npy-0.5 0.5];
        [Rangx]=phys_XYZ(Calib,Rangx,[0.5 0.5],ZIndex);%case of translations without rotation and quadratic deformation
        [xx,Rangy]=phys_XYZ(Calib,[0.5 0.5],Rangy,ZIndex);
    else         
        % the image needs to be interpolated to the new coordinates
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
    end
end

