%'px': transform fields from physical coordinates (phys) to image (px) coordinates 

% OUTPUT: 
% DataOut:   structure of modified data (transforms DataIn)
%       DataOut.CoordType='px': labels image coordinates
%       DataOut.CoordUnit= 'px' : units of output coordinates
%       DataOut.X and .Y arrays of image coordinates X, Y
%       DataOut.U, .V velocity in pixel displacement on the image (unit=px), if velocity exists as input 
%    
%INPUT:
% DataIn:  structure of possible input data (like UvData) or cell of structures (several fields):
%      DataIn.CoordType='phys': allows transform to px, else no transform   (DataOut=DataIn)
%      DataIn.X and .Y arrays of physical coordinates X, Y
%      DataIn.Z corresponding array of Z coordinates (=0 by default)
%      DataIn.U, V corresponding array of velocity components
%      DataIn.W corresponding array of the third velocity component in 3D case
%      DataIn.dt: time interval of the image pair used for velocity measurement (NEEDED TO GET OUTPUT RESULT))
%      DataIn.A, AX, AY : image or scalar input -> EMPTY  CORRESPONDING OUTPUT (A REVOIR)
%      Other fields in DataIn: copied to DataOut without modification
% Calib: structure containing the calibration parameters (Tsai) or containing a subtree Calib.GeometryCalib with these parameters
%
% call the function  px_XYZ (case of images) for pointwise coordinate transforms

function [DataOut,DataOut_1]=px(Data,CalibData,Data_1,CalibData_1)%DataIn,Calib)
% A FAIRE: 1- verifier si DataIn est une 'field structure'(.ListVarName'):
% chercher ListVarAttribute, for each field (cell of variables):
%   .CoordType: 'phys' or 'px'   (default==px, no transform)
%   .scale_factor: =dt (to transform displacement into velocity) default=1
%   .covariance: 'scalar', 'coord', 'D_i': covariant (like velocity), 'D^i': contravariant (like gradient), 'D^jD_i' (like strain tensor)
%   (default='coord' if .Role='coord_x,_y..., 
%            'D_i' if '.Role='vector_x,...',
%              'scalar', else (thenno change except scale factor)
if  ~(exist('CalibData','var') && isfield(CalibData,'GeometryCalib'))
    DataOut=Data;
else
    DataOut=px_1(Data,CalibData.GeometryCalib);
end
if exist('Data_1','var')
    if ~(exist('CalibData_1','var') && isfield(CalibData_1,'GeometryCalib'))
        DataOut_1=Data_1;
    else
        DataOut_1=px_1(Data_1,CalibData_1.GeometryCalib);
    end
else
    DataOut_1=[];
end


%------------------------------------------------
function DataOut=px_1(Data,Calib)
DataOut=Data;%default

%Act only if .CoordType=phys, and Calib defined
if isfield(Data,'CoordType')& isequal(Data.CoordType,'phys')& ~isempty(Calib)
    DataOut.CoordType='px'; %put flag for pixel coordinates
    DataOut.CoordUnit='px';
    %transform of X,Y coordinates
    if isfield(Data,'Z')&~isempty(Data.Z)
        Z=Data.Z;
    else
        Z=0;
    end
    if isfield(Data,'X') & isfield(Data,'Y')
        [DataOut.X,DataOut.Y]=px_XYZ(Calib,Data.X,Data.Y,Z);
        if isfield(Data,'U')&isfield(Data,'V')& isfield(Data,'dt')& ~isequal(Data.dt,0)
            Data.U=Data.U*Data.dt;
            Data.V=Data.V*Data.dt;
            if isfield(Data,'W')
                W=Data.W*Data.dt;
            else
                W=0;
            end
            [XOut_1,YOut_1]=px_XYZ(Calib,Data.X-Data.U/2,Data.Y-Data.V/2,Z-W/2);
            [XOut_2,YOut_2]=px_XYZ(Calib,Data.X+Data.U/2,Data.Y+Data.V/2,Z+W/2);
            DataOut.U=XOut_2-XOut_1;
            DataOut.V=YOut_2-YOut_1;
        end
    end
    %transform of an image
    if isfield(Data,'A')&isfield(Data,'AX')&~isempty(Data.AX) & isfield(Data,'AY')&...
                                   isfield(Data,'AY')&~isempty(Data.AY)&length(Data.A)>1
%         if isfield(Data,'Field')&isequal(Data.Field,'images')
          %NO TRANSFORM FROM phys to px for images
            DataOut.A=[];% 
    end
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


