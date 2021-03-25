%'phys_polar': transforms image (Unit='pixel') to polar (phys) coordinates using geometric calibration parameters
%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields %%%%
% OUTPUT: 
% Data:   output field structure 
%      .X=radius, .Y=azimuth angle, .U, .V are radial and azimuthal velocity components
%
%INPUT:
% DataIn:  first input field structure
% XmlData: first input parameter structure,
%        .GeometryCalib: substructure of the calibration parameters 
% DataIn_1: optional second input field structure
% XmlData_1: optional second input parameter structure
%         .GeometryCalib: substructure of the calibration parameters 
% transform image coordinates (px) to polar physical coordinates 
%[Data,Data_1]=phys_polar(varargin)
%
% OUTPUT: 
% Data: structure of modified data field: .X=radius, .Y=azimuth angle, .U, .V are radial and azimuthal velocity components
% Data_1:  second data field (if two fields are in input)
%
%INPUT:
% Data:  structure of input data (like UvData)
% XmlData= structure containing the field .GeometryCalib with calibration parameters
% Data_1:  second input field (not mandatory)
% XmlData_1= calibration parameters for the second field

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
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

function Data=phys_polar(DataIn,XmlData,DataIn_1,XmlData_1)
%------------------------------------------------------------------------

%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    prompt = {'origin [x y] of polar coordinates';'reference radius';'reference angle(degrees)';'angle direction and switch x y(+/-)'};
    dlg_title = 'set the parameters for the polar coordinates';
    num_lines= 2;
    def     = { '[0 0]';'';'0';'+'};
    if isfield(XmlData,'TransformInput')
        if isfield(XmlData.TransformInput,'PolarCentre')
            def{1}=num2str(XmlData.TransformInput.PolarCentre);
        end
        if isfield(XmlData.TransformInput,'PolarReferenceRadius')
            def{2}=num2str(XmlData.TransformInput.PolarReferenceRadius);
        end
        if isfield(XmlData.TransformInput,'PolarReferenceAngle')
            def{3}=num2str(XmlData.TransformInput.PolarReferenceAngle);
        end
        if isfield(XmlData.TransformInput,'PolarAngleDirection')
            def{4}=XmlData.TransformInput.PolarAngleDirection;
        end
    end
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    Data.TransformInput.PolarCentre=str2num(answer{1}); 
    Data.TransformInput.PolarReferenceRadius=str2num(answer{2}); 
    Data.TransformInput.PolarReferenceAngle=str2num(answer{3}); 
    Data.TransformInput.PolarAngleDirection=answer{4};
    return
end

%% default outputs
Data=DataIn; %default output
if isfield(Data,'CoordUnit')
Data=rmfield(Data,'CoordUnit');
end
Data.ListVarName = {};
Data.VarDimName={};
Data.VarAttribute={};
DataCell{1}=DataIn;
Calib{1}=[];
DataCell{2}=[];%default
checkpixel(1)=0;
if isfield(DataCell{1},'CoordUnit')&& strcmp(DataCell{1}.CoordUnit,'pixel') 
    checkpixel(1)=1;
end
if nargin==2||nargin==4
    if isfield(XmlData,'GeometryCalib') && ~isempty(XmlData.GeometryCalib)&& checkpixel(1)
        Calib{1}=XmlData.GeometryCalib;
    end
    Calib{2}=Calib{1};
else
    Data.Txt='wrong input: need two or four structures';
end
nbinput=1;
if nargin==4% case of two input fields
    checkpixel(2)=0;
if isfield(DataCell{2},'CoordUnit')&& strcmp(DataCell{2}.CoordUnit,'pixel') 
    checkpixel(2)=1;
end
    DataCell{2}=DataIn_1;%default
    if isfield(XmlData_1,'GeometryCalib')&& ~isempty(XmlData_1.GeometryCalib) && checkpixel(2)
        Calib{2}=XmlData_1.GeometryCalib;
    end
    nbinput=2;
end

%% parameters for polar coordinates (taken from the calibration data of the first field)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
origin_xy=[0 0];%center for the polar coordinates in the original x,y coordinates
radius_offset=0;%reference radius used to offset the radial coordinate r
angle_offset=0; %reference angle used as new origin of the polar angle (= axis Ox by default)
angle_scale=180/pi;
check_degree=1;%angle expressed in degrees by default
if isfield(XmlData,'TransformInput')
    if isfield(XmlData.TransformInput,'PolarCentre') && isnumeric(XmlData.TransformInput.PolarCentre)
        if isequal(length(XmlData.TransformInput.PolarCentre),2)
            origin_xy= XmlData.TransformInput.PolarCentre;
        end
    end
    if isfield(XmlData.TransformInput,'PolarReferenceRadius') && ~isempty(XmlData.TransformInput.PolarReferenceRadius)
        radius_offset=XmlData.TransformInput.PolarReferenceRadius;
    end
    if radius_offset > 0
        angle_scale=radius_offset; %the azimuth is rescale in terms of the length along the reference radius
        check_degree=0; %the output has the same unit as the input
    else
        angle_scale=180/pi; %polar angle in degrees
        check_degree=1;%angle expressed in degrees
    end
    if isfield(XmlData.TransformInput,'PolarReferenceAngle') && isnumeric(XmlData.TransformInput.PolarReferenceAngle)
        angle_offset=(pi/180)*XmlData.TransformInput.PolarReferenceAngle; %offset angle (in unit of the final angle, degrees or arc length along the reference radius))
    end
    check_reverse=isfield(XmlData.TransformInput,'PolarAngleDirection')&& strcmp(XmlData.TransformInput.PolarAngleDirection,'-');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get fields

nbvar=0;%counter for the number of output variables
nbcoord=0;%counter for the number of variablecheck_degrees for radial coordiantes (case of multiple field inputs)
nbgrid=0;%counter for the number of gridded fields (all linearly interpolated on the same output polar grid)
nbscattered=0;%counter of scattered fields
radius_name='radius';
theta_name='theta';
U_r_name='U_r';
U_theta_name='U_theta';
for ifield=1:nbinput %1 or 2 input fields
    [CellInfo,NbDim,errormsg]=find_field_cells(DataCell{ifield});
    if ~isempty(errormsg)
        Data.Txt=['bad input to phys_polar: ' errormsg];
        return
    end
    %transform of X,Y coordinates for vector fields
    if isfield(DataCell{ifield},'ZIndex')&& ~isempty(DataCell{ifield}.ZIndex)
        ZIndex=DataCell{ifield}.ZIndex;
    else
        ZIndex=0;
    end
    check_scalar=zeros(1,numel(CellInfo));
    check_vector=zeros(1,numel(CellInfo));
    for icell=1:numel(CellInfo)
        if NbDim(icell)==2
            % case of input field with scattered coordinates
            if strcmp(CellInfo{icell}.CoordType,'scattered')
                nbscattered=nbscattered+1;
                nbcoord=nbcoord+1;
                radius_name = rename_indexing(radius_name,Data.ListVarName);
                theta_name = rename_indexing(theta_name,Data.ListVarName);
                Data.ListVarName = [Data.ListVarName {radius_name} {theta_name}];
                dim_name = rename_indexing('nb_point',Data.VarDimName);
                Data.VarDimName=[Data.VarDimName {dim_name} {dim_name}];
                nbvar=nbvar+2;
                Data.VarAttribute{nbvar-1}.Role='coord_x';
                check_unit=1;
                %unit of output field
                if isfield(XmlData,'GeometryCalib')&& isfield(XmlData.GeometryCalib,'CoordUnit')
                    radius_unit=XmlData.GeometryCalib.CoordUnit;% states that the output is in unit defined by GeometryCalib, then erased all projection objects with different units
                elseif isfield(DataCell{ifield},'CoordUnit')
                    radius_unit=DataCell{ifield}.CoordUnit;
                else
                    radius_unit='';
                end
                Data.VarAttribute{nbvar-1}.units=radius_unit;
                if check_degree
                     Data.VarAttribute{nbvar}.units='degree';
                else %case of a reference radius
                    Data.VarAttribute{nbvar}.units=radius_unit;
                    Data.CoordUnit=radius_unit;
                end
%                 if isfield(DataCell{ifield},'CoordUnit')
%                     Data=rmfield(Data,'CoordUnit');
%                     Data.VarAttribute{nbvar-1}.unit=DataCell{ifield}.CoordUnit;
%                 elseif isfield(XmlData,'GeometryCalib')&& isfield(XmlData.GeometryCalib,'CoordUnit')
%                     Data.VarAttribute{nbvar-1}.unit=XmlData.GeometryCalib.CoordUnit;% states that the output is in unit defined by GeometryCalib, then erased all projection objects with different units
%                 else
%                     check_unit=0;
%                 end
                Data.VarAttribute{nbvar}.Role='coord_y';
%                 if check_degree
%                 Data.VarAttribute{nbvar}.units='degree';
%                 elseif check_unit
%                     Data.VarAttribute{nbvar}.units=Data.VarAttribute{nbvar-1}.units;
%                 end
  
                %transform u,v into polar coordinates
                X=DataCell{ifield}.(CellInfo{icell}.XName);
                Y=DataCell{ifield}.(CellInfo{icell}.YName);
                if isfield(CellInfo{icell},'VarIndex_vector_x')&& isfield(CellInfo{icell},'VarIndex_vector_y')
                    UName=DataCell{ifield}.ListVarName{CellInfo{icell}.VarIndex_vector_x};
                    VName=DataCell{ifield}.ListVarName{CellInfo{icell}.VarIndex_vector_y};
                    if ~isempty(Calib{ifield})
                        [X,Y,Z,DataCell{ifield}.(UName),DataCell{ifield}.(VName)]=...
                            phys_XYUV(DataCell{ifield},Calib{ifield},ZIndex);
                    end
                end
                [Theta,Radius] = cart2pol(X-origin_xy(1),Y-origin_xy(2));
                Data.(radius_name)=Radius-radius_offset;
                Data.(theta_name)=Theta*angle_scale-angle_offset;
                if Z~=0
                    Data.Z=Z;
                    nbvar=nbvar+1;
                    Data.ListVarName = [Data.ListVarName {'Z'}];
                    Data.VarDimName=[Data.VarDimName {dim_name}];
                    Data.VarAttribute{nbvar}.Role='coord_z';
                end
                if isfield(CellInfo{icell},'VarIndex_scalar')
                    ScalarName=DataCell{ifield}.ListVarName{CellInfo{icell}.VarIndex_scalar};
                    ScalarName=rename_indexing(ScalarName,Data.ListVarName);
                    Data.(ScalarName)=DataCell{ifield}.(ScalarName);
                    nbvar=nbvar+1;
                    Data.ListVarName = [Data.ListVarName {ScalarName}];
                    Data.VarDimName=[Data.VarDimName {dim_name}];
                    Data.VarAttribute{nbvar}.Role='scalar';
                end
                if isfield(CellInfo{icell},'VarIndex_vector_x')&& isfield(CellInfo{icell},'VarIndex_vector_y')
                    U_r_name= rename_indexing(U_r_name,Data.ListVarName);
                    U_theta_name= rename_indexing(U_theta_name,Data.ListVarName);
                    Data.(U_r_name)=DataCell{ifield}.(UName).*cos(Theta)+DataCell{ifield}.(VName).*sin(Theta);%radial velocity
                    Data.(U_theta_name)=(-DataCell{ifield}.(UName).*sin(Theta)+DataCell{ifield}.(VName).*cos(Theta));%./(Data.X)%+radius_ref);% azimuthal velocity component
                    Data.ListVarName = [Data.ListVarName {U_r_name} {U_theta_name}];
                    Data.VarDimName=[Data.VarDimName {dim_name} {dim_name}];
                    Data.VarAttribute{nbvar+1}.Role='vector_x';
                    Data.VarAttribute{nbvar+2}.Role='vector_y';
                    nbvar=nbvar+2;
                end
                if isfield(CellInfo{icell},'VarIndex_errorflag')
                    error_flag_name=DataCell{ifield}.ListVarName{CellInfo{icell}.VarIndex_errorflag};
                    error_flag_newname= rename_indexing(error_flag_name,Data.ListVarName);
                    Data.(error_flag_newname)=DataCell{ifield}.(error_flag_name);
                    Data.ListVarName = [Data.ListVarName {error_flag_newname}];
                    Data.VarDimName=[Data.VarDimName {dim_name}];
                    nbvar=nbvar+1;
                    Data.VarAttribute{nbvar}.Role='errorflag';
                end
                
           %caseof input fields on gridded coordinates (matrix)
            elseif strcmp(CellInfo{icell}.CoordType,'grid')
                if nbgrid==0% no gridded data yet, introduce the coordinate variables common to all gridded data
                    nbcoord=nbcoord+1;%add new radial coordinates for the first gridded field
                    radius_name = rename_indexing(radius_name,Data.ListVarName);% add an index to the name, or increment an existing index,
                    theta_name = rename_indexing(theta_name,Data.ListVarName);% if the proposed Name already exists in the list
                    Data.ListVarName = [Data.ListVarName {radius_name} {theta_name}];%add polar coordinates to the list of variables
                    Data.VarDimName=[Data.VarDimName {radius_name} {theta_name}];
                    nbvar=nbvar+2;
                    if check_reverse
                        Data.VarAttribute{nbvar-1}.Role='coord_y';
                        Data.VarAttribute{nbvar}.Role='coord_x';
                    else
                        Data.VarAttribute{nbvar-1}.Role='coord_x';
                        Data.VarAttribute{nbvar}.Role='coord_y';
                    end
                    check_unit=1;

                    if isfield(XmlData,'GeometryCalib')&& isfield(XmlData.GeometryCalib,'CoordUnit')
                        Data.VarAttribute{nbvar-1}.units=XmlData.GeometryCalib.CoordUnit;% states that the output is in unit defined by GeometryCalib, then erased all projection objects with different units
                    elseif isfield(DataCell{ifield},'CoordUnit')
                        Data.VarAttribute{nbvar-1}.units=DataCell{ifield}.CoordUnit;%radius in coord units
                    else
                        check_unit=0;
                    end
                    if check_degree
                        Data.VarAttribute{nbvar}.units='degree';%angle in degree
                    elseif check_unit
                        Data.VarAttribute{nbvar}.units=Data.VarAttribute{nbvar-1}.units;% angle in coord unit (normalised by reference radiuss)
                    end
                end
                if isfield(CellInfo{icell},'VarIndex_scalar')
                    nbgrid=nbgrid+1;
                    nbvar=nbvar+1;
                    Data.VarAttribute{nbvar}.Role='scalar';
                    FieldName{nbgrid}=DataCell{ifield}.ListVarName{CellInfo{icell}.VarIndex_scalar};
                    A{nbgrid}=DataCell{ifield}.(FieldName{nbgrid});
                    nbpoint(nbgrid)=numel(A{nbgrid});
                    check_scalar(nbgrid)=1;
                    coord_x{nbgrid}=DataCell{ifield}.(DataCell{ifield}.ListVarName{CellInfo{icell}.XIndex});
                    coord_y{nbgrid}=DataCell{ifield}.(DataCell{ifield}.ListVarName{CellInfo{icell}.YIndex});
                    ZInd(nbgrid)=ZIndex;
                    Calib_new{nbgrid}=Calib{ifield};
                end
                if isfield(CellInfo{icell},'VarIndex_vector_x')&& isfield(CellInfo{icell},'VarIndex_vector_y')
                    FieldName{nbgrid+1}=DataCell{ifield}.ListVarName{CellInfo{icell}.VarIndex_vector_x};
                    FieldName{nbgrid+2}=DataCell{ifield}.ListVarName{CellInfo{icell}.VarIndex_vector_y};
                    A{nbgrid+1}=DataCell{ifield}.(FieldName{nbgrid+1});
                    A{nbgrid+2}=DataCell{ifield}.(FieldName{nbgrid+2});
                    % Data.ListVarName=[Data.ListVarName {'U_r','U_theta'}];
                    %Data.VarDimName=[Data.VarDimName {{theta_name,radius_name}} {{theta_name,radius_name}}];
                    Data.VarAttribute{nbvar+1}.Role='vector_x';
                    Data.VarAttribute{nbvar+2}.Role='vector_y';
                    nbpoint([nbgrid+1 nbgrid+2])=numel(A{nbgrid+1});
                    check_vector(nbgrid+1)=1;
                    check_vector(nbgrid+2)=1;
                    coord_x{nbgrid+1}=DataCell{ifield}.(DataCell{ifield}.ListVarName{CellInfo{icell}.XIndex});
                    coord_y{nbgrid+1}=DataCell{ifield}.(DataCell{ifield}.ListVarName{CellInfo{icell}.YIndex});
                    coord_x{nbgrid+2}=DataCell{ifield}.(DataCell{ifield}.ListVarName{CellInfo{icell}.XIndex});
                    coord_y{nbgrid+2}=DataCell{ifield}.(DataCell{ifield}.ListVarName{CellInfo{icell}.YIndex});
                    ZInd(nbgrid+1)=ZIndex;
                    ZInd(nbgrid+2)=ZIndex;
                    Calib_new{nbgrid+1}=Calib{ifield};
                    Calib_new{nbgrid+2}=Calib{ifield};
                    nbgrid=nbgrid+2;
                    nbvar=nbvar+2;
                end
            end
        end
    end
end

%% tranform cartesian to polar coordinates for gridded data
if nbgrid~=0
    [A,Data.radius,Data.theta]=phys_Ima_polar(A,coord_x,coord_y,Calib_new,ZInd,origin_xy,radius_offset,angle_offset,angle_scale);
    for icell=1:numel(A)
        if icell<=numel(A)-1 && check_vector(icell)==1 && check_vector(icell+1)==1   %transform u,v into polar coordinates
            theta=Data.theta/angle_scale-angle_offset;
            [~,Theta]=meshgrid(Data.radius,theta);%grid in physical coordinates
            U_r_name= rename_indexing(U_r_name,Data.ListVarName);
            U_theta_name= rename_indexing(U_theta_name,Data.ListVarName);       
                Data.(U_r_name)=A{icell}.*cos(Theta)+A{icell+1}.*sin(Theta);%radial velocity
                Data.(U_theta_name)=(-A{icell}.*sin(Theta)+A{icell+1}.*cos(Theta));% azimuthal velocity component
            if check_reverse
                Data.(U_theta_name)=(Data.(U_theta_name))';
                Data.(U_r_name)=Data.(U_r_name)';
                Data.ListVarName=[Data.ListVarName {U_theta_name,U_r_name}];
                Data.VarDimName=[Data.VarDimName {{radius_name,theta_name}} {{radius_name,theta_name}}];
            else
                Data.ListVarName=[Data.ListVarName {U_r_name,U_theta_name}];
                Data.VarDimName=[Data.VarDimName {{theta_name,radius_name}} {{theta_name,radius_name}}];
            end
        elseif ~check_vector(icell)% for scalar fields
            FieldName{icell}= rename_indexing(FieldName{icell},Data.ListVarName);
            Data.ListVarName=[Data.ListVarName FieldName(icell)];       
            if check_reverse
                Data.(FieldName{icell})=A{icell}';
                Data.VarDimName=[Data.VarDimName {{radius_name,theta_name}}];
            else
                Data.VarDimName=[Data.VarDimName {{theta_name,radius_name}}];
                Data.(FieldName{icell})=A{icell};
            end
        end
    end
end
if check_reverse
    Data.(theta_name)=-Data.(theta_name);
end


%------------------------------------------------
%--- transform a single field into phys coordiantes
function [X,Y,Z,U,V]=phys_XYUV(Data,Calib,ZIndex)
%------------------------------------------------
%% set default output
%DataOut=Data;%default
%DataOut.CoordUnit=Calib.CoordUnit;% the output coord unit is set by the calibration parameters
X=[];%default output
Y=[];
Z=0;
U=[];
V=[];
%% transform  X,Y coordinates for velocity fields (transform of an image or scalar done in phys_ima)
if isfield(Data,'X') &&isfield(Data,'Y')&&~isempty(Data.X) && ~isempty(Data.Y)
    [X,Y,Z]=phys_XYZ(Calib,Data.X,Data.Y,ZIndex);
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
        U=(XOut_2-XOut_1)/Dt;
        V=(YOut_2-YOut_1)/Dt;
    end
end

%%%%%%%%%%%%%%%%%%%%
% tranform gridded field into polar coordiantes on a regular polar grid,
% transform to phys coordiantes if requested by calibration input
function [A_out,radius,theta]=phys_Ima_polar(A,coord_x,coord_y,CalibIn,ZIndex,origin_xy,radius_offset,angle_offset,angle_scale)
rcorner=[];
thetacorner=[];
npx=[];
npy=[];
for icell=1:length(A)
    siz=size(A{icell});
    npx(icell)=siz(2);
    npy(icell)=siz(1);
    x_edge=[linspace(coord_x{icell}(1),coord_x{icell}(end),npx(icell)) coord_x{icell}(end)*ones(1,npy(icell))...
        linspace(coord_x{icell}(end),coord_x{icell}(1),npx(icell)) coord_x{icell}(1)*ones(1,npy(icell))];%x coordinates of the image edge(four sides)
    y_edge=[coord_y{icell}(1)*ones(1,npx(icell)) linspace(coord_y{icell}(1),coord_y{icell}(end),npy(icell))...
        coord_y{icell}(end)*ones(1,npx(icell)) linspace(coord_y{icell}(end),coord_y{icell}(1),npy(icell))];%y coordinates of the image edge(four sides)
    
    % transform edges into phys coordinates if requested
    if ~isempty(CalibIn{icell})
        [x_edge,y_edge]=phys_XYZ(CalibIn{icell},x_edge,y_edge,ZIndex(icell));% physical coordinates of the image edge
    end
    
    %transform the corner coordinates into polar ones
    x_edge=x_edge-origin_xy(1);%shift to the origin of the polar coordinates
    y_edge=y_edge-origin_xy(2);%shift to the origin of the polar coordinates
    [theta_edge,r_edge] = cart2pol(x_edge,y_edge);%theta  and X are the polar coordinates angle and radius
    if (max(theta_edge)-min(theta_edge))>pi   %if the polar origin is inside the image
        r_edge=[0 max(r_edge)];
        theta_edge=[-pi pi];
    end
    rcorner=[rcorner r_edge];
    thetacorner=[thetacorner theta_edge];
end
nbpoint=max(npx.*npy);
Min_r=min(rcorner);
Max_r=max(rcorner);
Min_theta=min(thetacorner)*angle_scale;
Max_theta=max(thetacorner)*angle_scale;
Dr=round_uvmat((Max_r-Min_r)/sqrt(nbpoint));
Dtheta=round_uvmat((Max_theta-Min_theta)/sqrt(nbpoint));% get a simple mesh for the rescaled angle
radius=Min_r:Dr:Max_r;% polar coordinates for projections
theta=Min_theta:Dtheta:Max_theta;
%theta=Max_theta:-Dtheta:Min_theta;
[Radius,Theta]=meshgrid(radius,theta/angle_scale);%grid in polar coordinates (angles in radians)
%transform X, Y in cartesian
[X,Y] = pol2cart(Theta,Radius);% cartesian coordinates associated to the grid in polar coordinates
X=X+origin_xy(1);%shift to the origin of the polar coordinates
Y=Y+origin_xy(2);%shift to the origin of the polar coordinates
radius=radius-radius_offset;
theta=theta-angle_offset*angle_scale;
[np_theta,np_r]=size(Radius);

for icell=1:length(A)
    XIMA=X;
    YIMA=Y;
    if ~isempty(CalibIn{icell})%transform back to pixel if calibration parameters are introduced
        Z=0; %default
        if isfield(CalibIn{icell},'SliceCoord') %.Z= index of plane
            if ZIndex(icell)==0
                ZIndex(icell)=1;
            end
            SliceCoord=CalibIn{icell}.SliceCoord(ZIndex(icell),:);
            Z=SliceCoord(3); %to generalize for non-parallel planes
            if isfield(CalibIn{icell},'SliceAngle')
            norm_plane=angle2normal(CalibIn{icell}.SliceAngle);
            Z=Z-(norm_plane(1)*(X-SliceCoord(1))+norm_plane(2)*(Y-SliceCoord(2)))/norm_plane(3); 
            end
        end
        [XIMA,YIMA]=px_XYZ(CalibIn{icell},X,Y,Z);%corresponding image indices for each point in the real space grid
    end
    Dx=(coord_x{icell}(end)-coord_x{icell}(1))/(npx(icell)-1);
    Dy=(coord_y{icell}(end)-coord_y{icell}(1))/(npy(icell)-1);
    indx_ima=1+round((XIMA-coord_x{icell}(1))/Dx);%indices of the initial matrix close to the points of the new grid
    %indy_ima=1+round((YIMA-coord_y{icell}(1))/Dy);
    indy_ima=1+round((coord_y{icell}(end)-YIMA)/Dy);
     Delta_x=1+(XIMA-coord_x{icell}(1))/Dx-indx_ima;%error in the index discretisation
     Delta_y=1+(coord_y{icell}(end)-YIMA)/Dy-indy_ima;
    XIMA=reshape(indx_ima,1,[]);%indices reorganized in 'line'
    YIMA=reshape(indy_ima,1,[]);%indices reorganized in 'line'
    flagin=XIMA>=1 & XIMA<=npx(icell) & YIMA >=1 & YIMA<=npy(icell);%flagin=1 inside the original image
    siz=size(A{icell});
    checkuint8=isa(A{icell},'uint8');%check for image input with 8 bits
    checkuint16=isa(A{icell},'uint16');%check for image input with 16 bits
    A{icell}=double(A{icell});
    if numel(siz)==2 %(B/W images)
        vec_A=reshape(A{icell}(:,:,1),1,[]);%put the original image in line
        ind_in=find(flagin);
        ind_out=find(~flagin);
        ICOMB=((XIMA-1)*npy(icell)+(npy(icell)+1-YIMA));% indices in vec_A
        ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
        vec_B(ind_in)=vec_A(ICOMB);
        vec_B(ind_out)=zeros(size(ind_out));
        A_out{icell}=reshape(vec_B,np_theta,np_r);%new image in real coordinates
        DA_y=circshift(A_out{icell},-1,1)-A_out{icell};% derivative
        DA_y(end,:)=0;
        DA_x=circshift(A_out{icell},-1,2)-A_out{icell};
        DA_x(:,end)=0;
        A_out{icell}=A_out{icell}+Delta_x.*DA_x+Delta_y.*DA_y;%linear interpolation
    else
        for icolor=1:siz(3)
            vec_A=reshape(A{icell}(:,:,icolor),1,[]);%put the original image in line
            ind_in=find(flagin);
            ind_out=find(~flagin);
            ICOMB=((XIMA-1)*npy(icell)+(npy(icell)+1-YIMA));
            ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
            vec_B(ind_in)=vec_A(ICOMB);
            vec_B(ind_out)=zeros(size(ind_out));
            A_out{icell}(:,:,icolor)=reshape(vec_B,np_theta,np_r);%new image in real coordinates
            DA_y=circshift(A_out{icell}(:,:,icolor),-1,1)-A_out{icell}(:,:,icolor);
            DA_y(end,:)=0;
            DA_x=circshift(A_out{icell}(:,:,icolor),-1,2)-A_out{icell}(:,:,icolor);
            DA_x(:,end)=0;
            A_out{icell}(:,:,icolor)=A_out{icell}(:,:,icolor)+Delta_x.*DA_x+Delta_y.*DA_y;%linear interpolation
        end
    end
    if checkuint8
        A_out{icell}=uint8(A_out{icell});
    elseif checkuint16
        A_out{icell}=uint16(A_out{icell});
    end
end

