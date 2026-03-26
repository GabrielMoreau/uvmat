%'phys': transforms image (Unit='pixel') to real world (phys) coordinates using geometric calibration parameters.  It acts if the input field contains the tag 'CoordTUnit' with value 'pixel'
%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields %%%%
% OUTPUT: 
% DataOut:   output field structure 
%
%INPUT:
% DataIn:  first input field structure
% XmlData: first input parameter structure,
%        .GeometryCalib: substructure of the calibration parameters 
% DataIn_1: optional second input field structure
% XmlData_1: optional second input parameter structure
%         .GeometryCalib: substructure of the calibration parameters 

%=======================================================================
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function DataOut=phys(DataIn,XmlData,DataIn_1,XmlData_1)
%------------------------------------------------------------------------

% A FAIRE: 1- verifier si DataIn est une 'field structure'(.ListVarName'):
% chercher ListVarAttribute, for each field (cell of variables):
%   .CoordType: 'phys' or 'px'   (default==phys, no transform)
%   .scale_factor: =dt (to transform displacement into velocity) default=1
%   .covariance: 'scalar', 'coord', 'D_i': covariant (like velocity), 'D^i': contravariant (like gradient), 'D^jD_i' (like strain tensor)
%   (default='coord' if .Role='coord_x,_y..., 
%            'D_i' if '.Role='vector_x,...',
%              'scalar', else (thenno change except scale factor)

DataOut=[];
DataOut_1=[]; %default second  output field
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    if isfield(XmlData,'GeometryCalib')&& isfield(XmlData.GeometryCalib,'CoordUnit')
        DataOut.CoordUnit=XmlData.GeometryCalib.CoordUnit;% states that the output is in unit defined by GeometryCalib, then erased all projection objects with different units
    end
    return
end

%% analyse input and set default output
DataOut=DataIn;%default first output field
if nargin>=2 % nargin =nbre of input variables
     Calib{1}=[];
    if isfield(XmlData,'GeometryCalib')
        Calib{1}=XmlData.GeometryCalib;
    end
    Slice{1}=Calib{1};
    if isfield(XmlData,'Slice')
        Slice{1}=XmlData.Slice;
    end
    if nargin>=3  %two input fields
        DataOut_1=DataIn_1;%default second output field
        Calib{2}=Calib{1};
        if nargin>=4 
            if isfield(XmlData_1,'GeometryCalib')
                Calib{2}=XmlData_1.GeometryCalib;
            end
            Slice{2}=Calib{2};
            if isfield(XmlData_1,'Slice')
                Slice{2}=XmlData_1.Slice;
            end
        end
    end
end

%% get the z index defining the section plane
ZIndex=1;
if isfield(DataIn,'ZIndex')&&~isempty(DataIn.ZIndex)&&~isnan(DataIn.ZIndex)
    ZIndex=DataIn.ZIndex;
end

%% transform first field
iscalar=0;% counter of scalar fields
checktransform=0;
if  ~isempty(Calib{1})
    if isfield(Calib{1},'CalibrationType')&& isfield(Calib{1},'CoordUnit') && isfield(DataIn,'CoordUnit')&& strcmp(DataIn.CoordUnit,'pixel')   
        DataOut=phys_1(DataIn,Calib{1},Slice{1},ZIndex);% transform coordinates and velocity components
        %case of images or scalar: in case of two input fields, we need to project the transform  on the same regular grid
        if isfield(DataIn,'A') && isfield(DataIn,'Coord_x') && ~isempty(DataIn.Coord_x) && isfield(DataIn,'Coord_y')&&...
                ~isempty(DataIn.Coord_y) && length(DataIn.A)>1
            iscalar=1;
            A{1}=DataIn.A;
        end
        checktransform=1;
    end
end

%% document the selected  plane position and angle if relevant
if  checktransform && isfield(Slice{1},'SliceCoord')&&size(Slice{1}.SliceCoord,1)>=ZIndex
    DataOut.PlaneCoord=Slice{1}.SliceCoord(ZIndex,:);% transfer the slice position corresponding to index ZIndex
    if isfield(Slice{1},'SliceAngle') % transfer the slice rotation angles
        if isequal(size(Slice{1}.SliceAngle,1),1)% case of a unique angle
            DataOut.PlaneAngle=Slice{1}.SliceAngle;
        else  % case of multiple planes with different angles: select the plane with index ZIndex
            DataOut.PlaneAngle=Slice{1}.SliceAngle(ZIndex,:);
        end
    end
end

%% transform second field if relevant
checktransform_1=0;
if ~isempty(DataOut_1)
    if isfield(DataIn_1,'ZIndex') && ~isequal(DataIn_1.ZIndex,ZIndex)
        DataOut_1.Txt='different plane indices for the two input fields';
        return
    end
    if isfield(Calib{2},'CalibrationType')&&isfield(Calib{2},'CoordUnit') && isfield(DataIn_1,'CoordUnit')&& strcmp(DataIn_1.CoordUnit,'pixel')
        DataOut_1=phys_1(DataOut_1,Calib{2},Slice{2},ZIndex);
        if isfield(Slice{2},'SliceCoord')
            if ~(isfield(Slice{2},'SliceCoord') && isequal(Slice{2}.SliceCoord,Slice{1}.SliceCoord))
                DataOut_1.Txt='different plane positions for the two input fields';
                return
            end
            DataOut_1.PlaneCoord=DataOut.PlaneCoord;% same plane position for the two input fields
            if isfield(Slice{1},'SliceAngle')
                if ~(isfield(Slice{2},'SliceAngle') && isequal(Slice{2}.SliceAngle,Slice{1}.SliceAngle))
                    DataOut_1.Txt='different plane angles for the two input fields';
                    return
                end
                DataOut_1.PlaneAngle=DataOut.PlaneAngle; % same plane angle for the two input fields
            end
        end
        if isfield(DataIn_1,'A')&&isfield(DataIn_1,'Coord_x')&&~isempty(DataIn_1.Coord_x) && isfield(DataIn_1,'Coord_y')&&...
                ~isempty(DataIn_1.Coord_y)&&length(DataIn_1.A)>1
            iscalar=iscalar+1;
%             Calib{iscalar}=Calib{2};
            A{iscalar}=DataIn_1.A;
        end
        checktransform_1=1;
    end
end

%% transform the scalar(s) or image(s)
if checktransform && iscalar~=0
    [A,Coord_x,Coord_y]=phys_ima(A,XmlData,ZIndex);%TODO : introduire interp2_uvmat ds phys_ima
    if iscalar==1 && ~isempty(DataOut_1) % case for which only the second field is a scalar
         DataOut_1.A=A{1};
         DataOut_1.Coord_x=Coord_x; 
         DataOut_1.Coord_y=Coord_y;
    else
        DataOut.A=A{1};
        DataOut.Coord_x=Coord_x; 
        DataOut.Coord_y=Coord_y;
    end
    if iscalar==2
        DataOut_1.A=A{2};
        DataOut_1.Coord_x=Coord_x; 
        DataOut_1.Coord_y=Coord_y;
    end
end

% subtract fields
if ~isempty(DataOut_1)
    DataOut=sub_field(DataOut,[],DataOut_1);
end
%------------------------------------------------
%--- transform a single field
function DataOut=phys_1(Data,Calib,Slice,ZIndex)
%------------------------------------------------
%% set default output
DataOut=Data;%default
DataOut.CoordUnit=Calib.CoordUnit;% the output coord unit is set by the calibration parameters

%% transform  X,Y coordinates for velocity fields (transform of an image or scalar done in phys_ima)
if isfield(Data,'X') &&isfield(Data,'Y')&&~isempty(Data.X) && ~isempty(Data.Y)
  [DataOut.X,DataOut.Y]=phys_XYZ(Calib,Slice,Data.X,Data.Y,ZIndex);
    Dt=1; %default
    if isfield(Data,'dt')&&~isempty(Data.dt)
        Dt=Data.dt;
    end
    if isfield(Data,'Dt')&&~isempty(Data.Dt)
        Dt=Data.Dt;
    end
    if isfield(Data,'U')&&isfield(Data,'V')&&~isempty(Data.U) && ~isempty(Data.V)
        [XOut_1,YOut_1]=phys_XYZ(Calib,Slice,Data.X-Data.U/2,Data.Y-Data.V/2,ZIndex);
        [XOut_2,YOut_2]=phys_XYZ(Calib,Slice,Data.X+Data.U/2,Data.Y+Data.V/2,ZIndex);
        DataOut.U=(XOut_2-XOut_1)/Dt;
        DataOut.V=(YOut_2-YOut_1)/Dt;
    end
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
if isfield(DataOut,'VarAttribute') && numel(DataOut.VarAttribute)>=3 && isfield(DataOut.VarAttribute{3},'VarIndex_tps')
    DataOut.VarAttribute{3}=rmfield(DataOut.VarAttribute{3},'VarIndex_tps');
end
if isfield(DataOut,'VarAttribute')&& numel(DataOut.VarAttribute)>=4 && isfield(DataOut.VarAttribute{4},'VarIndex_tps')
    DataOut.VarAttribute{4}=rmfield(DataOut.VarAttribute{4},'VarIndex_tps');
end
if ~isempty(ind_remove)
    DataOut.ListVarName(ind_remove)=[];
    DataOut.VarDimName(ind_remove)=[];
    DataOut.VarAttribute(ind_remove)=[];
end
    
%% transform of spatial derivatives: TODO check the case with plane angles
if isfield(Data,'X') && ~isempty(Data.X) && isfield(Data,'DjUi') && ~isempty(Data.DjUi)
    % estimate the Jacobian matrix DXpx/DXphys
    for ip=1:length(Data.X)
        [Xp1,Yp1]=phys_XYZ(Calib,Slice,Data.X(ip)+0.5,Data.Y(ip),ZIndex);
        [Xm1,Ym1]=phys_XYZ(Calib,Slice,Data.X(ip)-0.5,Data.Y(ip),ZIndex);
        [Xp2,Yp2]=phys_XYZ(Calib,Slice,Data.X(ip),Data.Y(ip)+0.5,ZIndex);
        [Xm2,Ym2]=phys_XYZ(Calib,Slice,Data.X(ip),Data.Y(ip)-0.5,ZIndex);
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


%%%%%%%%%%%%%%%%%%%%

