%'proj_field': projects the field on a projection object
%--------------------------------------------------------------------------
%  function [ProjData,errormsg]=proj_field(FieldData,ObjectData,VarMesh)
%
% OUTPUT:
% ProjData structure containing the fields of the input field FieldData,
% transmitted or projected on the object, plus the additional fields
%    .UMax, .UMin, .VMax, .VMin: min and max of velocity components in a domain
%    .UMean,VMean: mean of the velocity components in a domain
%    .AMin, AMax: min and max of a scalar
%    .AMean: mean of a scalar in a domain  
%  .NbPix;
%  .DimName=  names of the matrix dimensions (matlab cell)
%  .VarName= names of the variables [ProjData.VarName {'A','AMean','AMin','AMax'}];
%  .VarDimNameIndex= dimensions of the variables, indicated by indices in the list .DimName;
%
%INPUT
% ObjectData: structure characterizing the projection object
%    .Type : type of projection object
%    .ProjMode=mode of projection ;
%    .CoordUnit: 'px', 'cm' units for the coordinates defining the object
%    .Angle (  angles of rotation (=[0 0 0] by default)
%    .ProjAngle=angle of projection;
%    .DX,.DY,.DZ=increments along each coordinate
%    .Coord(nbpoints,3): set of coordinates defining the object position;

%FieldData: data of the field to be projected on the projection object, with optional fields
%    .Txt: error message, transmitted to the projection
%    .FieldList: cell array of strings representing the fields to calculate
%    .CoordMesh: typical distance between data points (used for mouse action or display), transmitted
%    .CoordUnit, .TimeUnit, .dt: transmitted
% standardised description of fields, nc-formated Matlab structure with fields:
%         .ListGlobalAttribute: cell listing the names of the global attributes
%        .Att_1,Att_2... : values of the global attributes
%            .ListVarName: cell listing the names of the variables
%           .VarAttribute: cell of structures s containing names and values of variable attributes (s.name=value) for each variable of .ListVarName
%        .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName
% The variables are grouped in 'fields', made of a set of variables with common dimensions (using the function find_field_cells)
% The variable attribute 'Role' is used to define the role for plotting:
%       Role = 'scalar':  (default) represents a scalar field
%            = 'coord':  represents a set of unstructured coordinates, whose
%                     space dimension is given by the last array dimension (called 'NbDim').
%            = 'coord_x', 'coord_y',  'coord_z': represents a separate set of
%                        unstructured coordinate x, y  or z
%            = 'vector': represents a vector field whose number of components
%                is given by the last dimension (called 'NbDim')
%            = 'vector_x', 'vector_y', 'vector_z'  :represents the x, y or z  component of a vector  
%            = 'warnflag' : provides a warning flag about the quality of data in a 'Field', default=0, no warning
%            = 'errorflag': provides an error flag marking false data,
%                   default=0, no error. Different non zero values can represent different criteria of elimination.
%
% Default role of variables (by name)
%  vector field:
%    .X,.Y: position of the velocity vectors, projected on the object
%    .U, .V, .W: velocity components, projected on the object
%    .C, .CName: scalar associated to the vector
%    .F : equivalent to 'warnflag'
%    .FF: equivalent to 'errorflag'
%  scalar field or image:
%    .AName: name of a scalar (to be calculated from velocity fields after projection), transmitted 
%    .A: scalar, projected on the object
%    .AX, .AY: positions for the scalar
%     case of a structured grid: A is a dim 2 matrix and .AX=[first last] (length 2 vector) represents the first and last abscissa of the grid
%     case of an unstructured scalar: A is a vector, AX and AY the corresponding coordinates 

%=======================================================================
% Copyright 2008-2016, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [ProjData,errormsg]=proj_field(FieldData,ObjectData,VarMesh)
errormsg='';%default
ProjData=[];

%% check input projection object: type, projection mode and Coord:
if ~isfield(ObjectData,'Type')||~isfield(ObjectData,'ProjMode')
    return
end
ListProjMode={'projection','interp_lin','interp_tps','inside','outside'};%list of effective projection modes
if isempty(find(strcmp(ObjectData.ProjMode,ListProjMode), 1))% no projection in case 
    return
end
if ~isfield(ObjectData,'Coord')||isempty(ObjectData.Coord)
    if strcmp(ObjectData.Type,'plane')
        ObjectData.Coord=[0 0];%default
    else
        return
    end
end

%% apply projection depending on the object type
switch ObjectData.Type
    case 'points'
        [ProjData,errormsg]=proj_points(FieldData,ObjectData);
    case {'line','polyline'}
        [ProjData,errormsg] = proj_line(FieldData,ObjectData);
    case {'polygon','rectangle','ellipse'}
        if isequal(ObjectData.ProjMode,'inside')||isequal(ObjectData.ProjMode,'outside')
            if ~exist('VarMesh','var')
                VarMesh=[];
            end
            [ProjData,errormsg] = proj_patch(FieldData,ObjectData,VarMesh);
        else
            [ProjData,errormsg] = proj_line(FieldData,ObjectData);
        end
    case 'plane'
        [ProjData,errormsg] = proj_plane(FieldData,ObjectData);
    case 'volume'
        [ProjData,errormsg] = proj_volume(FieldData,ObjectData);
end

%-----------------------------------------------------------------
%project on a set of points
function  [ProjData,errormsg]=proj_points(FieldData,ObjectData)%%
%-------------------------------------------------------------------

siz=size(ObjectData.Coord);
width=0;
if isfield(ObjectData,'Range')
    width=ObjectData.Range(1,2);
end
if isfield(ObjectData,'RangeX')&&~isempty(ObjectData.RangeX)
    width=max(ObjectData.RangeX);
end
if isfield(ObjectData,'RangeY')&&~isempty(ObjectData.RangeY)
    width=max(width,max(ObjectData.RangeY));
end
if isfield(ObjectData,'RangeZ')&&~isempty(ObjectData.RangeZ)
    width=max(width,max(ObjectData.RangeZ));
end
if isequal(ObjectData.ProjMode,'projection') 
    if width==0
        errormsg='projection range around points needed';
        return
    end
elseif  ~isequal(ObjectData.ProjMode,'interp_lin')
    errormsg=(['ProjMode option ' ObjectData.ProjMode ' not available in proj_field']);
        return
end
[ProjData,errormsg]=proj_heading(FieldData,ObjectData);
if ~isempty(errormsg)
    return
end
ProjData.NbDim=0;
[CellInfo,NbDimArray,errormsg]=find_field_cells(FieldData);
if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_points:' errormsg];
    return
end
%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
for icell=1:length(CellInfo)
    if NbDimArray(icell)<=1
        continue %projection only for multidimensional fields
    end
    VarIndex=CellInfo{icell}.VarIndex;%  indices of the selected variables in the list FieldData.ListVarName
    ivar_X=CellInfo{icell}.CoordIndex(end);
    ivar_Y=CellInfo{icell}.CoordIndex(end-1);
    ivar_Z=[];
    if NbDimArray(icell)==3
        ivar_Z=CellInfo{icell}.CoordIndex(1);
    end
    ivar_FF=[];
    if isfield(CellInfo{icell},'VarIndex_errorflag')
        ivar_FF=CellInfo{icell}.VarIndex_errorflag;
        if numel(ivar_FF)>1
            errormsg='multiple error flag input';
            return
        end
    end    
    % select types of  variables to be projected
   ListProj={'VarIndex_scalar','VarIndex_image','VarIndex_color','VarIndex_vector_x','VarIndex_vector_y'};
      check_proj=false(size(FieldData.ListVarName));
   for ilist=1:numel(ListProj)
       if isfield(CellInfo{icell},ListProj{ilist})
           check_proj(CellInfo{icell}.(ListProj{ilist}))=1;
       end
   end
   VarIndex=find(check_proj);
    ProjData.ListVarName={'Y','X','NbVal'};
    ProjData.VarDimName={'nb_points','nb_points','nb_points'};
    ProjData.VarAttribute{1}.Role='ancillary';
    ProjData.VarAttribute{2}.Role='ancillary';
    ProjData.VarAttribute{3}.Role='ancillary';
    for ivar=VarIndex        
        VarName=FieldData.ListVarName{ivar};
        ProjData.ListVarName=[ProjData.ListVarName {VarName}];% add the current variable to the list of projected variables
        ProjData.VarDimName=[ProjData.VarDimName {'nb_points'}]; % projected VarName has a single dimension called 'nb_points' (set of projection points)

    end
    if strcmp( CellInfo{icell}.CoordType,'scattered')
        coord_x=FieldData.(FieldData.ListVarName{ivar_X});
        coord_y=FieldData.(FieldData.ListVarName{ivar_Y});
        test3D=0;% TEST 3D CASE : NOT COMPLETED ,  3D CASE : NOT COMPLETED 
        if length(ivar_Z)==1
            coord_z=FieldData.(FieldData.ListVarName{ivar_Z});
            test3D=1;
        end
   
        for ipoint=1:siz(1)
           Xpoint=ObjectData.Coord(ipoint,:);
           distX=coord_x-Xpoint(1);
           distY=coord_y-Xpoint(2);          
           dist=distX.*distX+distY.*distY;
           indsel=find(dist<width*width);
           ProjData.X(ipoint,1)=Xpoint(1);
           ProjData.Y(ipoint,1)=Xpoint(2);
           if isequal(length(ivar_FF),1)
               FFName=FieldData.ListVarName{ivar_FF};
               FF=FieldData.(FFName)(indsel);
               indsel=indsel(~FF);
           end
           ProjData.NbVal(ipoint,1)=length(indsel);
            for ivar=VarIndex 
               VarName=FieldData.ListVarName{ivar};
               if isempty(indsel)
                    ProjData.(VarName)(ipoint,1)=NaN;
               else
                    Var=FieldData.(VarName)(indsel);
                    ProjData.(VarName)(ipoint,1)=mean(Var);
                    if isequal(ObjectData.ProjMode,'interp_lin')
                         ProjData.(VarName)(ipoint,1)=griddata_uvmat(coord_x(indsel),coord_y(indsel),Var,Xpoint(1),Xpoint(2));
                    end
               end
            end
        end
    else    %case of structured coordinates
        if  strcmp( CellInfo{icell}.CoordType,'grid')
            AYName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(end-1)};
            AXName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(end)};
            eval(['AX=FieldData.' AXName ';']);% set of x positions
            eval(['AY=FieldData.' AYName ';']);% set of y positions  
            AName=FieldData.ListVarName{VarIndex(1)};% a single variable assumed in the current cell
            eval(['A=FieldData.' AName ';']);% scalar
            npxy=size(A);         
            %update VarDimName in case of components (non coordinate dimensions e;g. color components)
            if numel(npxy)>NbDimArray(icell)
                ProjData.VarDimName{end}={'nb_points','component'};
            end
            for idim=1:NbDimArray(icell) %loop on space dimensions
                test_interp(idim)=0;%test for coordiate interpolation (non regular grid), =0 by default
                test_coord(idim)=0;%test for defined coordinates, =0 by default
                ivar=CellInfo{icell}.CoordIndex(idim);
                Coord{idim}=FieldData.(FieldData.ListVarName{ivar}); % position for the first index
                if numel(Coord{idim})==2
                    DCoord_min(idim)= (Coord{idim}(2)-Coord{idim}(1))/(npxy(idim)-1);
                    test_direct(idim)=DCoord_min(idim)>0;% =1 for increasing values, 0 otherwise
                else
                    DCoord=diff(Coord{idim});
                    DCoord_min(idim)=min(DCoord);
                    DCoord_max=max(DCoord);
                    test_direct(idim)=DCoord_max>0;% =1 for increasing values, 0 otherwise
                    test_direct_min=DCoord_min(idim)>0;% =1 for increasing values, 0 otherwise
                    if ~isequal(test_direct(idim),test_direct_min)
                        errormsg=['non monotonic dimension variable # ' num2str(idim)  ' in proj_field.m'];
                        return
                    end
                    test_interp(idim)=(DCoord_max-DCoord_min(idim))> 0.0001*abs(DCoord_max);% test grid regularity
                    test_coord(idim)=1;
                end
            end
            DX=DCoord_min(2);
            DY=DCoord_min(1);
            for ipoint=1:siz(1)
                xwidth=width/(abs(DX));
                ywidth=width/(abs(DY));
                i_min=round((ObjectData.Coord(ipoint,1)-Coord{2}(1))/DX+0.5-xwidth); %minimum index of the selected region
                i_min=max(1,i_min);%restrict to field limit
                i_plus=round((ObjectData.Coord(ipoint,1)-Coord{2}(1))/DX+0.5+xwidth);
                i_plus=min(npxy(2),i_plus); %restrict to field limit
                j_min=round((ObjectData.Coord(ipoint,2)-Coord{1}(1))/DY-ywidth+0.5);
                j_min=max(1,j_min);
                j_plus=round((ObjectData.Coord(ipoint,2)-Coord{1}(1))/DY+ywidth+0.5);
                j_plus=min(npxy(1),j_plus);
                ProjData.X(ipoint,1)=ObjectData.Coord(ipoint,1);
                ProjData.Y(ipoint,1)=ObjectData.Coord(ipoint,2);
                i_int=(i_min:i_plus);
                j_int=(j_min:j_plus);
                ProjData.NbVal(ipoint,1)=length(j_int)*length(i_int);
                if isempty(i_int) || isempty(j_int)
                   for ivar=VarIndex   
                        eval(['ProjData.' FieldData.ListVarName{ivar} '(ipoint,:)=NaN;']);
                   end
                   errormsg=['no data points in the selected projection range ' num2str(width) ];
                else
                    %TODO: introduce circle in the selected subregion
                    %[I,J]=meshgrid([1:j_int],[1:i_int]);
                    for ivar=VarIndex   
                        Avalue=FieldData.(FieldData.ListVarName{ivar})(j_int,i_int,:);
                        ProjData.(FieldData.ListVarName{ivar})(ipoint,:)=mean(mean(Avalue));
                    end
                end
            end
        end
   end
end

%-----------------------------------------------------------------
%project in a patch
function  [ProjData,errormsg]=proj_patch(FieldData,ObjectData,VarMesh)%%
%-------------------------------------------------------------------
[ProjData,errormsg]=proj_heading(FieldData,ObjectData);
if ~isempty(errormsg)
    return
end
%objectfield=fieldnames(ObjectData);
widthx=0;
widthy=0;
if isfield(ObjectData,'RangeX') && ~isempty(ObjectData.RangeX)
    widthx=max(ObjectData.RangeX);
end
if isfield(ObjectData,'RangeY') && ~isempty(ObjectData.RangeY)
    widthy=max(ObjectData.RangeY);
end

%A REVOIR, GENERALISER: UTILISER proj_line
ProjData.NbDim=1;
ProjData.ListVarName={};
ProjData.VarDimName={};
ProjData.VarAttribute={};

CoordMesh=zeros(1,numel(FieldData.ListVarName));
if isfield (FieldData,'VarAttribute')
    for iattr=1:length(FieldData.VarAttribute)%initialization of variable attribute values
        if isfield(FieldData.VarAttribute{iattr},'Unit')
            unit{iattr}=FieldData.VarAttribute{iattr}.Unit;
        end
        if isfield(FieldData.VarAttribute{iattr},'CoordMesh')
            CoordMesh(iattr)=FieldData.VarAttribute{iattr}.CoordMesh;
        end
    end
end

%group the variables (fields of 'FieldData') in cells of variables with the same dimensions
[CellInfo,NbDim,errormsg]=find_field_cells(FieldData);
if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_patch:' errormsg];
    return
end

%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
for icell=1:length(CellInfo)
    CoordType=CellInfo{icell}.CoordType;
    test_Amat=0;
    if NbDim(icell)~=2% proj_patch acts only on fields of space dimension 2
        continue
    end
    ivar_FF=[];
    testfalse=isfield(CellInfo{icell},'VarIndex_errorflag');
    if testfalse
        ivar_FF=CellInfo{icell}.VarIndex_errorflag;
        FFName=FieldData.ListVarName{ivar_FF};
        errorflag=FieldData.(FFName);
    end
    % select types of  variables to be projected
    ListProj={'VarIndex_scalar','VarIndex_image','VarIndex_color','VarIndex_vector_x','VarIndex_vector_y'};
    check_proj=false(size(FieldData.ListVarName));
    for ilist=1:numel(ListProj)
        if isfield(CellInfo{icell},ListProj{ilist})
            check_proj(CellInfo{icell}.(ListProj{ilist}))=1;
        end
    end
    VarIndex=find(check_proj);
    
    ivar_X=CellInfo{icell}.CoordIndex(end);
    ivar_Y=CellInfo{icell}.CoordIndex(end-1);
    ivar_Z=[];
    if NbDim(icell)==3
        ivar_Z=CellInfo{icell}.CoordIndex(1);
    end
    switch CellInfo{icell}.CoordType
        case 'scattered' %case of unstructured coordinates
            for ivar=[VarIndex ivar_X ivar_Y ivar_FF]
                VarName=FieldData.ListVarName{ivar};
                FieldData.(VarName)=reshape(FieldData.(VarName),[],1);
            end
            XName=FieldData.ListVarName{ivar_X};
            YName=FieldData.ListVarName{ivar_Y};
            coord_x=FieldData.(FieldData.ListVarName{ivar_X});
            coord_y=FieldData.(FieldData.ListVarName{ivar_Y});
            % image or 2D matrix
        case 'grid' %case of structured coordinates
            test_Amat=1;% test for image or 2D matrix
            AYName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(end-1)};
            AXName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(end)};
            AX=FieldData.(AXName);% x coordinate
            AY=FieldData.(AYName);% y coordinate
            VarName=FieldData.ListVarName{VarIndex(1)};
            DimValue=size(FieldData.(VarName));
            if length(AX)==2
                AX=linspace(AX(1),AX(end),DimValue(2));
            end
            if length(AY)==2
                AY=linspace(AY(1),AY(end),DimValue(1));
            end
            if length(DimValue)==3
                testcolor=1;
                npxy(3)=3;
            else
                testcolor=0;
                npxy(3)=1;
            end
            [Xi,Yi]=meshgrid(AX,AY);
            npxy(1)=length(AY);
            npxy(2)=length(AX);
            Xi=reshape(Xi,npxy(1)*npxy(2),1);
            Yi=reshape(Yi,npxy(1)*npxy(2),1);
            for ivar=1:length(VarIndex)
                VarName=FieldData.ListVarName{VarIndex(ivar)};
                FieldData.(VarName)=reshape(FieldData.(VarName),npxy(1)*npxy(2),npxy(3)); % keep only non false vectors
            end
    end
    %select the indices in the range of action
    testin=[];%default
    if isequal(ObjectData.Type,'rectangle')
        if strcmp(CellInfo{icell}.CoordType,'scattered')
            distX=abs(coord_x-ObjectData.Coord(1,1));
            distY=abs(coord_y-ObjectData.Coord(1,2));
            testin=distX<widthx & distY<widthy;
        elseif test_Amat
            distX=abs(Xi-ObjectData.Coord(1,1));
            distY=abs(Yi-ObjectData.Coord(1,2));
            testin=distX<widthx & distY<widthy;
        end
    elseif isequal(ObjectData.Type,'polygon')
        if strcmp(CoordType,'scattered')
            testin=inpolygon(coord_x,coord_y,ObjectData.Coord(:,1),ObjectData.Coord(:,2));
        elseif strcmp(CoordType,'grid')
            testin=inpolygon(Xi,Yi,ObjectData.Coord(:,1),ObjectData.Coord(:,2));
        else%calculate the scalar
            testin=[]; %A REVOIR
        end
    elseif isequal(ObjectData.Type,'ellipse')
        X2Max=widthx*widthx;
        Y2Max=(widthy)*(widthy);
        if strcmp(CoordType,'scattered')
            distX=(coord_x-ObjectData.Coord(1,1));
            distY=(coord_y-ObjectData.Coord(1,2));
            testin=(distX.*distX/X2Max+distY.*distY/Y2Max)<1;
        elseif strcmp(CoordType,'grid') %case of usual 2x2 matrix
            distX=(Xi-ObjectData.Coord(1,1));
            distY=(Yi-ObjectData.Coord(1,2));
            testin=(distX.*distX/X2Max+distY.*distY/Y2Max)<1;
        end
    end
    %selected indices
    if isequal(ObjectData.ProjMode,'outside')
        testin=~testin;
    end
    if testfalse
        testin=testin & (errorflag==0); % keep only non false vectors
    end
    indsel=find(testin);
    nbvar=0;
    VarSize=zeros(size(VarIndex));
    for ivar=VarIndex
        VarName=FieldData.ListVarName{ivar};
        ProjData.([VarName 'Mean'])=mean(double(FieldData.(VarName)(indsel,:))); % take the mean in the selected region, for each co
        ProjData.([VarName 'Min'])=min(double(FieldData.(VarName)(indsel,:))); % take the min in the selected region , for each color component
        ProjData.([VarName 'Max'])=max(double(FieldData.(VarName)(indsel,:))); % take the max in the selected region , for each color co
        nbvar=nbvar+1;
        VarSize(nbvar)=mean((ProjData.([VarName 'Max'])-ProjData.([VarName 'Min']))/100);
    end
    if  isempty(VarMesh)% || isnan(VarMesh) % mesh not specified as input, estimate from the bounds
        VarMesh=mean(VarSize);
        ord=10^(floor(log10(VarMesh)));%order of magnitude
        if VarMesh/ord >=5
            VarMesh=5*ord;
        elseif VarMesh/ord >=2
            VarMesh=2*ord;
        else
            VarMesh=ord;
        end
    end
    for ivar=VarIndex
        VarName=FieldData.ListVarName{ivar};
        LowBound=VarMesh*ceil(ProjData.([VarName 'Min'])/VarMesh);
        UpperBound=VarMesh*floor(ProjData.([VarName 'Max'])/VarMesh);
        if numel(indsel)<=1
            errormsg='only one data point or less for histogram';
            return
        elseif isequal(LowBound,UpperBound)
            errormsg='attempt histogram of uniform field: low bound = high bound';
            return
        end       
        ProjData.(VarName)=LowBound:VarMesh:UpperBound; % list of bin values
        ProjData.([VarName 'Histo'])=hist(double(FieldData.(VarName)(indsel,:)),ProjData.(VarName)); % histogram at predefined bin positions
        ProjData.ListVarName=[ProjData.ListVarName {VarName} {[VarName 'Histo']} {[VarName 'Mean']} {[VarName 'Min']} {[VarName 'Max']}];
        if test_Amat && testcolor
            ProjData.VarDimName=[ProjData.VarDimName  {VarName} {{VarName,'rgb'}} {'rgb'} {'rgb'} {'rgb'}];%{{'nb_point','rgb'}};
        else
            ProjData.VarDimName=[ProjData.VarDimName {VarName} {VarName} {'one'} {'one'} {'one'}];
        end
        VarAttribute_var=[];
        if isfield(FieldData,'VarAttribute')&& numel(FieldData.VarAttribute)>=ivar
            VarAttribute_var=FieldData.VarAttribute{ivar};
        end
      %  VarAttribute_var.Role='coord_x';% the variable is now used as an absissa
        VarAttribute_histo.Role='histo';
        ProjData.VarAttribute=[ProjData.VarAttribute {VarAttribute_var} {VarAttribute_histo} {[]} {[]} {[]}];
    end
end

%-----------------------------------------------------------------
%project on a line
% AJOUTER flux,circul,error
% OUTPUT: 
% ProjData: projected field
% 
function  [ProjData,errormsg] = proj_line(FieldData, ObjectData)
%-----------------------------------------------------------------

%% prepare heading for the projected field
[ProjData,errormsg]=proj_heading(FieldData,ObjectData);%transfer global attributes
if ~isempty(errormsg)
    return
end
ProjData.NbDim=1;
%initialisation of the input parameters and defaultoutput
ProjMode=ObjectData.ProjMode; %rmq: ProjMode always defined from input={'projection','interp_lin','interp_tps'}
% ProjAngle=90; %90 degrees projection by default
width=0;
if isfield(ObjectData,'RangeY')
    width=max(ObjectData.RangeY);%Rangey needed bfor mode 'projection'
end
% default output
errormsg='';%default
Xline=[];
flux=0;
circul=0;
liny=ObjectData.Coord(:,2);
NbPoints=size(ObjectData.Coord,1);
testfalse=0;
ListIndex={};

%% group the variables (fields of 'FieldData') in cells of variables with the same dimensions
[CellInfo,NbDim,errormsg]=find_field_cells(FieldData);
if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_line:' errormsg];
    return
end
CellInfo=CellInfo(NbDim==2); %keep only the 2D cells
%%%%%% TODO: treat 1D fields: project as identity so that P o P=P for projection operation
cell_select=true(size(CellInfo));

for icell=1:length(CellInfo)
    if isfield(CellInfo{icell},'ProjModeRequest')
        if ~strcmp(CellInfo{icell}.ProjModeRequest, ProjMode)
            cell_select(icell)=0;
        end
        if strcmp(ProjMode,'interp_tps')&& ~strcmp(CellInfo{icell}.CoordType,'tps')
            cell_select(icell)=0;
        end
    end
end
if isempty(find(cell_select))
    errormsg=[' invalid projection mode ''' ProjMode ''': use ''interp_tps'' to interpolate spatial derivatives'];
    return
end
CellInfo=CellInfo(cell_select);

%% projection line: object types selected from  proj_field='line','polyline','polygon','rectangle','ellipse':
LineCoord=ObjectData.Coord;
switch ObjectData.Type
    case 'ellipse'
        LineLength=2*pi*ObjectData.RangeX*ObjectData.RangeY;
        NbSegment=0;
    case 'rectangle'
        LineCoord([1 4],1)=ObjectData.Coord(1,1)-ObjectData.RangeX;
        LineCoord([1 2],2)=ObjectData.Coord(1,2)-ObjectData.RangeY;
        LineCoord([2 3],1)=ObjectData.Coord(1,1)+ObjectData.RangeX;
        LineCoord([4 1],2)=ObjectData.Coord(1,2)+ObjectData.RangeY;
    case 'polygon'
        LineCoord(NbPoints+1)=LineCoord(1);
end
if ~strcmp(ObjectData.Type,'ellipse')
    if ~strcmp(ObjectData.Type,'rectangle') && NbPoints<2
        return% line needs at least 2 points to be defined
    end
    dlinx=diff(LineCoord(:,1));
    dliny=diff(LineCoord(:,2));
    [theta,dlength]=cart2pol(dlinx,dliny);%angle and length of each segment
    LineLength=sum(dlength);
    NbSegment=numel(LineLength);
end
CheckClosedLine=~isempty(find(strcmp(ObjectData.Type,{'rectangle','ellipse','polygon'})));

%     x = a \ \cosh \mu \ \cos \nu
%
%     y = a \ \sinh \mu \ \sin \nu

%% angles of the polyline and boundaries of action for mode 'projection'

% determine a rectangles at +-width from the line (only used for the ProjMode='projection or 'interp_tps')
xsup=zeros(1,NbPoints); xinf=zeros(1,NbPoints); ysup=zeros(1,NbPoints); yinf=zeros(1,NbPoints);
if isequal(ProjMode,'projection')
    if strcmp(ObjectData.Type,'line')
        xsup=ObjectData.Coord(:,1)-width*sin(theta);
        xinf=ObjectData.Coord(:,1)+width*sin(theta);
        ysup=ObjectData.Coord(:,2)+width*cos(theta);
        yinf=ObjectData.Coord(:,2)-width*cos(theta);
    else
        errormsg='mode projection only available for simple line, use interpolation otherwise';
        return
    end
else % need to define the set of interpolation points
    if isfield(ObjectData,'DX') && ~isempty(ObjectData.DX)
        DX=abs(ObjectData.DX);%mesh of interpolation points along the line
        if CheckClosedLine
            NbPoint=ceil(LineLength/DX);
            DX=LineLength/NbPoint;%adjust DX to get an integer nbre of intervals in a closed line
            DX_edge=DX/2;
        else
            DX_edge=(LineLength-DX*floor(LineLength/DX))/2;%margin from the first point and first interpolation point, the same for the end point
        end
        XI=[];
        YI=[];
        ThetaI=[];
        dlengthI=[];
        if strcmp(ObjectData.Type,'ellipse')
            phi=(DX_edge:DX:LineLength)*2*pi/LineLength;
            XI=ObjectData.RangeX*cos(phi);
            YI=ObjectData.RangeY*sin(phi);
            dphi=2*pi*DX/LineLength;
            [ThetaI,dlengthI]=cart2pol(-ObjectData.RangeX*sin(phi)*dphi,ObjectData.RangeY*cos(phi)*dphi);
        else
            for isegment=1:NbSegment
                costheta=cos(theta(isegment));
                sintheta=sin(theta(isegment));
                %                 XIsegment=LineCoord(isegment,1)+DX_edge*costheta:DX*costheta:LineCoord(isegment+1,1));
                %                 YIsegment=(LineCoord(isegment,2)+DX_edge*sintheta:DX*sintheta:LineCoord(isegment+1,2));
                NbInterval=floor((dlength(isegment)-DX_edge)/DX);
                LastX=DX_edge+DX*NbInterval;
                NbPoint=NbInterval+1;
                XIsegment=linspace(LineCoord(isegment,1)+DX_edge*costheta,LineCoord(isegment,1)+LastX*costheta,NbPoint);
                YIsegment=linspace(LineCoord(isegment,2)+DX_edge*sintheta,LineCoord(isegment,2)+LastX*sintheta,NbPoint);
                XI=[XI XIsegment];
                YI=[YI YIsegment];
                ThetaI=[ThetaI theta(isegment)*ones(1,numel(XIsegment))];
                dlengthI=[dlengthI DX*ones(1,numel(XIsegment))];
                DX_edge=DX-(dlength(isegment)-LastX);%edge for the next segment set to keep DX=DX_end+DX_edge between two segments
            end
        end
        Xproj=cumsum(dlengthI);
    else
        errormsg='abscissa mesh along line DX needed for interpolation';
        return
    end
end

%% loop on variable cells with the same space dimension 2
ProjData.ListVarName={};
ProjData.VarDimName={};
check_abscissa=0;
for icell=1:length(CellInfo)
    % list of variable types to be projected
    ListProj={'VarIndex_scalar','VarIndex_image','VarIndex_color','VarIndex_vector_x','VarIndex_vector_y'};
    check_proj=false(size(FieldData.ListVarName));
    for ilist=1:numel(ListProj)
        if isfield(CellInfo{icell},ListProj{ilist})
            check_proj(CellInfo{icell}.(ListProj{ilist}))=1;
        end
    end
    VarIndex=find(check_proj);% indices of the variables to be projected
    
    %% identify vector components
    %testU=isfield(CellInfo{icell},'VarIndex_vector_x') &&isfield(CellInfo{icell},'VarIndex_vector_y') ;% test for vectors
    %     if testU
    %         UName=FieldData.ListVarName{CellInfo{icell}.VarIndex_vector_x};
    %         VName=FieldData.ListVarName{CellInfo{icell}.VarIndex_vector_y};
    %         vector_x=FieldData.(UName);
    %         vector_y=FieldData.(VName);
    %     end
    %identify error flag
    errorflag=0; %default, no error flag
    if isfield(CellInfo{icell},'VarIndex_errorflag');% test for error flag
        FFName=FieldData.ListVarName{CellInfo{icell}.VarIndex_errorflag};
        errorflag=FieldData.(FFName);
    end
    VarName=FieldData.ListVarName(VarIndex);% cell array of the names of variables to pje
    ivar_U=[];
    ivar_V=[];
    %% check needed object properties for unstructured positions (position given by the variables with role coord_x, coord_y
    
    %         circul=0;
    %         flux=0;
    %%%%%%%  % A FAIRE CALCULER MEAN DES QUANTITES    %%%%%%
    switch CellInfo{icell}.CoordType
        %case of unstructured coordinates
        case 'scattered'
%             XName= FieldData.ListVarName{CellInfo{icell}.CoordIndex(end)};
%             YName= FieldData.ListVarName{CellInfo{icell}.CoordIndex(end-1)};
            coord_x=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(end)});
            coord_y=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(end-1)});
            
            if isequal(ProjMode,'projection')
                if width==0
                    errormsg='range of the projection object is missing';
                    return
                end
                ProjData.ListVarName=[ProjData.ListVarName FieldData.ListVarName(CellInfo{icell}.CoordIndex(end))];
                ProjData.VarDimName=[ProjData.VarDimName FieldData.ListVarName(CellInfo{icell}.CoordIndex(end))];
                nbvar=numel(ProjData.ListVarName);
                ProjData.VarAttribute{nbvar}.long_name='abscissa along line';
                % select the (non false) input data located in the band of projection
                flagsel=(errorflag==0) & ((coord_y -yinf(1))*(xinf(2)-xinf(1))>(coord_x-xinf(1))*(yinf(2)-yinf(1))) ...
                    & ((coord_y -ysup(1))*(xsup(2)-xsup(1))<(coord_x-xsup(1))*(ysup(2)-ysup(1))) ...
                    & ((coord_y -yinf(2))*(xsup(2)-xinf(2))>(coord_x-xinf(2))*(ysup(2)-yinf(2))) ...
                    & ((coord_y -yinf(1))*(xsup(1)-xinf(1))<(coord_x-xinf(1))*(ysup(1)-yinf(1)));
                coord_x=coord_x(flagsel);
                coord_y=coord_y(flagsel);
                costheta=cos(theta);
                sintheta=sin(theta);
                Xproj=(coord_x-ObjectData.Coord(1,1))*costheta + (coord_y-ObjectData.Coord(1,2))*sintheta; %projection on the line
                [Xproj,indsort]=sort(Xproj);% sort points by increasing absissa along the projection line
                ProjData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(end)})=Xproj;
                for ivar=1:numel(VarIndex)
                    ProjData.(VarName{ivar})=FieldData.(VarName{ivar})(flagsel);% restrict variables to the projection band
                    ProjData.(VarName{ivar})=ProjData.(VarName{ivar})(indsort);% sort by absissa
                    ProjData.ListVarName=[ProjData.ListVarName VarName{ivar}];
                    ProjData.VarDimName=[ProjData.VarDimName FieldData.ListVarName(CellInfo{icell}.CoordIndex(end))];
                    ProjData.VarAttribute{nbvar+ivar}=FieldData.VarAttribute{VarIndex(ivar)};%reproduce var attribute
                    if isfield(ProjData.VarAttribute{nbvar+ivar},'Role')
                        if  strcmp(ProjData.VarAttribute{nbvar+ivar}.Role,'vector_x');
                            ivar_U=nbvar+ivar;
                        elseif strcmp(ProjData.VarAttribute{nbvar+ivar}.Role,'vector_y');
                            ivar_V=nbvar+ivar;
                        end
                    end
                    ProjData.VarAttribute{ivar+nbvar}.Role='discrete';% will promote plots of the profiles with continuous lines
                end
            elseif isequal(ProjMode,'interp_lin')  %filtering %linear interpolation:
                if ~check_abscissa
                    XName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(end)};
                    ProjData.ListVarName=[ProjData.ListVarName {XName}];
                    ProjData.VarDimName=[ProjData.VarDimName {XName}];
                    nbvar=numel(ProjData.ListVarName);
                    ProjData.VarAttribute{nbvar}.long_name='abscissa along line';
                    check_abscissa=1; % define abcissa only once
                end
                if ~isequal(errorflag,0)
                    VarName_FF=FieldData.ListVarName{CellInfo{icell}.VarIndex_errorflag};
                    indsel=find(FieldData.(VarName_FF)==0);
                    coord_x=coord_x(indsel);
                    coord_y=coord_y(indsel);
                    for ivar=1:numel(CellInfo{icell}.VarIndex)
                        VarName=FieldData.ListVarName{CellInfo{icell}.VarIndex(ivar)};
                        FieldData.(VarName)=FieldData.(VarName)(indsel);
                    end
                end
                [ProjVar,ListFieldProj,VarAttribute,errormsg]=calc_field_interp([coord_x coord_y],FieldData,CellInfo{icell}.FieldName,XI,YI);
                ProjData.X=Xproj;
                nbvar=numel(ProjData.ListVarName);
                ProjData.ListVarName=[ProjData.ListVarName ListFieldProj];
                ProjData.VarAttribute=[ProjData.VarAttribute VarAttribute];
                for ivar=1:numel(VarAttribute)
                    ProjData.VarDimName=[ProjData.VarDimName {XName}];
                    if isfield(VarAttribute{ivar},'Role')
                        if  strcmp(VarAttribute{ivar}.Role,'vector_x');
                            ivar_U=ivar+nbvar;
                        elseif strcmp(VarAttribute{ivar}.Role,'vector_y');
                            ivar_V=ivar+nbvar;
                        end
                    end
                    ProjData.VarAttribute{ivar+nbvar}.Role='continuous';% will promote plots of the profiles with continuous lines
                    ProjData.(ListFieldProj{ivar})=ProjVar{ivar};
                end
            end
        case 'tps'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if strcmp(ProjMode,'interp_tps')
                Coord=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex});
                NbCentres=FieldData.(FieldData.ListVarName{CellInfo{icell}.NbCentres_tps});
                SubRange=FieldData.(FieldData.ListVarName{CellInfo{icell}.SubRange_tps});
                if isfield(CellInfo{icell},'VarIndex_vector_x_tps')&&isfield(CellInfo{icell},'VarIndex_vector_y_tps')
                    FieldVar=cat(3,FieldData.(FieldData.ListVarName{CellInfo{icell}.VarIndex_vector_x_tps}),FieldData.(FieldData.ListVarName{CellInfo{icell}.VarIndex_vector_y_tps}));
                end
                [DataOut,VarAttribute,errormsg]=calc_field_tps(Coord,NbCentres,SubRange,FieldVar,CellInfo{icell}.FieldName,cat(3,XI,YI));
                ProjData.ListVarName=[ProjData.ListVarName {'X'}];
                ProjData.VarDimName=[ProjData.VarDimName {'X'}];
                ProjData.X=Xproj;
                nbvar=numel(ProjData.ListVarName);
                ProjData.VarAttribute{nbvar}.long_name='abscissa along line';
                ProjVarName=(fieldnames(DataOut))';
                ProjData.ListVarName=[ProjData.ListVarName ProjVarName];
                ProjData.VarAttribute=[ProjData.VarAttribute VarAttribute];
                for ivar=1:numel(VarAttribute)
                    ProjData.VarDimName=[ProjData.VarDimName {'X'}];
                    if isfield(VarAttribute{ivar},'Role')
                        if  strcmp(VarAttribute{ivar}.Role,'vector_x');
                            ivar_U=ivar+nbvar;
                        elseif strcmp(VarAttribute{ivar}.Role,'vector_y');
                            ivar_V=ivar+nbvar;
                        end
                    end
                    ProjData.VarAttribute{ivar+nbvar}.Role='continuous';% will promote plots of the profiles with continuous lines
                    ProjData.(ProjVarName{ivar})=DataOut.(ProjVarName{ivar});
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        case 'grid'   %case of structured coordinates
            if ~isequal(ObjectData.Type,'line')% exclude polyline
                errormsg=['no  projection available on ' ObjectData.Type 'for structured coordinates']; %
            else
                test_Amat=1;%image or 2D matrix
                test_interp2=0;%default
                AYName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(end-1)};
                AXName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(end)};
                eval(['AX=FieldData.' AXName ';']);% set of x positions
                eval(['AY=FieldData.' AYName ';']);% set of y positions
                AName=FieldData.ListVarName{VarIndex(1)};
                eval(['A=FieldData.' AName ';']);% scalar
                npxy=size(A);
                npx=npxy(2);
                npy=npxy(1);
                if numel(AX)==2
                    DX=(AX(2)-AX(1))/(npx-1);
                else
                    DX_vec=diff(AX);
                    DX=max(DX_vec);
                    DX_min=min(DX_vec);
                    if (DX-DX_min)>0.0001*abs(DX)
                        test_interp2=1;
                        DX=DX_min;
                    end
                end
                if numel(AY)==2
                    DY=(AY(2)-AY(1))/(npy-1);
                else
                    DY_vec=diff(AY);
                    DY=max(DY_vec);
                    DY_min=min(DY_vec);
                    if (DY-DY_min)>0.0001*abs(DY)
                        test_interp2=1;
                        DY=DY_min;
                    end
                end
                AXI=linspace(AX(1),AX(end), npx);%set of  x  positions for the interpolated input data
                AYI=linspace(AY(1),AY(end), npy);%set of  x  positions for the interpolated input data
                if isfield(ObjectData,'DX')
                    DXY_line=ObjectData.DX;%mesh on the projection line
                else
                    DXY_line=sqrt(abs(DX*DY));% mesh on the projection line
                end
                dlinx=ObjectData.Coord(2,1)-ObjectData.Coord(1,1);
                dliny=ObjectData.Coord(2,2)-ObjectData.Coord(1,2);
                linelength=sqrt(dlinx*dlinx+dliny*dliny);
                theta=angle(dlinx+i*dliny);%angle of the line
                if isfield(FieldData,'RangeX')
                    XMin=min(FieldData.RangeX);%shift of the origin on the line
                else
                    XMin=0;
                end
                eval(['ProjData.' AXName '=linspace(XMin,XMin+linelength,linelength/DXY_line+1);'])%abscissa of the new pixels along the line
                y=linspace(-width,width,2*width/DXY_line+1);%ordintes of the new pixels (coordinate across the line)
                eval(['npX=length(ProjData.' AXName ');'])
                npY=length(y); %TODO: utiliser proj_grid
                eval(['[X,Y]=meshgrid(ProjData.' AXName ',y);'])%grid in the line coordinates
                XIMA=ObjectData.Coord(1,1)+(X-XMin)*cos(theta)-Y*sin(theta);
                YIMA=ObjectData.Coord(1,2)+(X-XMin)*sin(theta)+Y*cos(theta);
                XIMA=(XIMA-AX(1))/DX+1;%  index of the original image along x
                YIMA=(YIMA-AY(1))/DY+1;% index of the original image along y
                XIMA=reshape(round(XIMA),1,npX*npY);%indices reorganized in 'line'
                YIMA=reshape(round(YIMA),1,npX*npY);
                flagin=XIMA>=1 & XIMA<=npx & YIMA >=1 & YIMA<=npy;%flagin=1 inside the original image
                ind_in=find(flagin);
                ind_out=find(~flagin);
                ICOMB=(XIMA-1)*npy+YIMA;
                ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
                nbcolor=1; %color images
                if numel(npxy)==2
                    nbcolor=1;
                elseif length(npxy)==3
                    nbcolor=npxy(3);
                else
                    errormsg='multicomponent field not projected';
                    display(errormsg)
                    return
                end
                nbvar=length(ProjData.ListVarName);% number of var from previous cells
                ProjData.ListVarName=[ProjData.ListVarName {AXName}];
                ProjData.VarDimName=[ProjData.VarDimName {AXName}];
                for ivar=VarIndex
                    %VarName{ivar}=FieldData.ListVarName{ivar};
                    if test_interp2% interpolate on new grid
                        FieldData.(FieldData.ListVarName{ivar})=interp2(FieldData.(AXName),FieldData.(AYName),FieldData.(FieldData.ListVarName{ivar}),AXI,AYI);%TO TEST
                    end
                    vec_A=reshape(squeeze(FieldData.(FieldData.ListVarName{ivar})),npx*npy,nbcolor); %put the original image in colum
                    if nbcolor==1
                        vec_B(ind_in)=vec_A(ICOMB);
                        vec_B(ind_out)=zeros(size(ind_out));
                        A_out=reshape(vec_B,npY,npX);
                        ProjData.(FieldData.ListVarName{ivar}) =sum(A_out,1)/npY;
                    elseif nbcolor==3
                        vec_B(ind_in,1:3)=vec_A(ICOMB,:);
                        vec_B(ind_out,1)=zeros(size(ind_out));
                        vec_B(ind_out,2)=zeros(size(ind_out));
                        vec_B(ind_out,3)=zeros(size(ind_out));
                        A_out=reshape(vec_B,npY,npX,nbcolor);
                        ProjData.(FieldData.ListVarName{ivar})=squeeze(sum(A_out,1)/npY);
                    end
                    ProjData.ListVarName=[ProjData.ListVarName FieldData.ListVarName{ivar}];
                    ProjData.VarDimName=[ProjData.VarDimName {AXName}];%to generalize with the initial name of the x coordinate
                    ProjData.VarAttribute{ivar}.Role='continuous';% for plot with continuous line
                end
                if nbcolor==3
                    ProjData.VarDimName{end}={AXName,'rgb'};
                end
            end
    end
    if ~isempty(ivar_U) && ~isempty(ivar_V)
        vector_x =ProjData.(ProjData.ListVarName{ivar_U});
        ProjData.(ProjData.ListVarName{ivar_U}) =cos(theta)*vector_x+sin(theta)*ProjData.(ProjData.ListVarName{ivar_V});
        ProjData.(ProjData.ListVarName{ivar_V}) =-sin(theta)*vector_x+cos(theta)*ProjData.(ProjData.ListVarName{ivar_V});
    end
end

% %shotarter case for horizontal or vertical line (A FAIRE 
% %     Rangx=[0.5 npx-0.5];%image coordiantes of corners
% %     Rangy=[npy-0.5 0.5];
% %     if isfield(Calib,'Pxcmx')&isfield(Calib,'Pxcmy')%old calib
% %         Rangx=Rangx/Calib.Pxcmx;
% %         Rangy=Rangy/Calib.Pxcmy;
% %     else
% %         [Rangx]=phys_XYZ(Calib,Rangx,[0.5 0.5],[0 0]);%case of translations without rotation and quadratic deformation
% %         [xx,Rangy]=phys_XYZ(Calib,[0.5 0.5],Rangy,[0 0]);
% %     end 
% 
% %     test_scal=0;%default% 3- 'UserData':(get(handles.Tag,'UserData')


%-----------------------------------------------------------------
%project on a plane 
% AJOUTER flux,circul,error
function  [ProjData,errormsg] = proj_plane(FieldData, ObjectData)
%-----------------------------------------------------------------

%% rotation angles
PlaneAngle=[0 0 0];
norm_plane=[0 0 1];
cos_om=1;
sin_om=0;
test90x=0;%=1 for 90 degree rotation alround x axis
test90y=0;%=1 for 90 degree rotation alround y axis
if isfield(ObjectData,'Angle')&& isequal(size(ObjectData.Angle),[1 3])&& ~isequal(ObjectData.Angle,[0 0 0])
    test90y=isequal(ObjectData.Angle,[0 90 0]);
    PlaneAngle=(pi/180)*ObjectData.Angle;
    om=norm(PlaneAngle);%norm of rotation angle in radians
    OmAxis=PlaneAngle/om; %unit vector marking the rotation axis
    cos_om=cos(om);
    sin_om=sin(om);
    coeff=OmAxis(3)*(1-cos_om);
    %components of the unity vector norm_plane normal to the projection plane
    norm_plane(1)=OmAxis(1)*coeff+OmAxis(2)*sin_om;
    norm_plane(2)=OmAxis(2)*coeff-OmAxis(1)*sin_om;
    norm_plane(3)=OmAxis(3)*coeff+cos_om;
end
testangle=~isequal(PlaneAngle,[0 0 0])||~isequal(ObjectData.Coord(1:2),[0 0 ]) ;% && ~test90y && ~test90x;%=1 for slanted plane

%% mesh sizes DX and DY
DX=[];
DY=[];%default
if isfield(ObjectData,'DX') && ~isempty(ObjectData.DX)
    DX=abs(ObjectData.DX);%mesh of interpolation points
elseif isfield(FieldData,'CoordMesh')
    DX=FieldData.CoordMesh;
end
if isfield(ObjectData,'DY') && ~isempty(ObjectData.DY)
    DY=abs(ObjectData.DY);%mesh of interpolation points
elseif isfield(FieldData,'CoordMesh')
    DY=FieldData.CoordMesh;
end
if  ~strcmp(ObjectData.ProjMode,'projection') && (isempty(DX)||isempty(DY))
    errormsg='DX or DY not defined';
    return
end

%% extrema along each axis
testXMin=0;% test if min of X coordinates defined on the projection object, =0 by default
testXMax=0;% test if max of X coordinates defined on the projection object, =0 by default
testYMin=0;% test if min of Y coordinates defined on the projection object, =0 by default
testYMax=0;% test if max of Y coordinates defined on the projection object, =0 by default
if isfield(ObjectData,'RangeX') % rangeX defined by the projection object
    XMin=min(ObjectData.RangeX);
    XMax=max(ObjectData.RangeX);
    testXMin=XMax>XMin;%=1 if XMin defined (i.e. RangeY has two distinct elements)
    testXMax=1;% max of X coordinates defined on the projection object
end
if isfield(ObjectData,'RangeY') % rangeY defined by the projection object
    YMin=min(ObjectData.RangeY);
    YMax=max(ObjectData.RangeY);
    testYMin=YMax>YMin;%=1 if YMin defined (i.e. RangeY has tow distinct elements)
    testYMax=1;% max of Y coordinates defined on the projection object
end
width=0;%default width of the projection band
if isfield(ObjectData,'RangeZ')
    width=max(ObjectData.RangeZ);
end

%% interpolation range
thresh2=[];
if isfield(ObjectData,'RangeInterp')
    thresh2=ObjectData.RangeInterp*ObjectData.RangeInterp;%square of interpolation range (do not interpolate beyond this range)
end

%% initiate Matlab  structure for physical field
[ProjData,errormsg]=proj_heading(FieldData,ObjectData);
if ~isempty(errormsg)
    return
end

%% reproduce initial plane position and angle
if isfield(FieldData,'PlaneCoord')&&length(FieldData.PlaneCoord)==3&& isfield(ProjData,'ProjObjectCoord')
    if length(ProjData.ProjObjectCoord)==3% if the projection plane has a z coordinate
        if isfield(ProjData,'.PlaneCoord') && ~isequal(ProjData.PlaneCoord(3),ProjData.ProjObjectCoord) %check the consistency with the z coordinate of the field plane (set by calibration)
            errormsg='inconsistent z position for field and projection plane';
            return
        end
    else % the z coordinate is set only by the field plane (by calibration)
        ProjData.ProjObjectCoord(3)=FieldData.PlaneCoord(3);
    end
    if isfield(FieldData,'PlaneAngle')
        if isfield(ProjData,'ProjObjectAngle')
            if ~isequal(FieldData.PlaneAngle,ProjData.ProjObjectAngle) %check the consistency with the z coordinate of the field plane (set by calibration)
                errormsg='inconsistent plane angle for field and projection plane';
                return
            end
        else
            ProjData.ProjObjectAngle=FieldData.PlaneAngle;
        end
    end
end
ProjData.NbDim=2;
ProjData.ListVarName={};
ProjData.VarDimName={};
ProjData.VarAttribute={};
if ~isempty(DX) && ~isempty(DY)
    ProjData.CoordMesh=sqrt(DX*DY);%define typical data mesh, useful for mouse selection in plots
elseif isfield(FieldData,'CoordMesh')
    ProjData.CoordMesh=FieldData.CoordMesh;
end
error=0;%default
flux=0;
testfalse=0;
ListIndex={};

%% group the variables (fields of 'FieldData') in cells of variables with the same dimensions
[CellInfo,NbDimArray,errormsg]=find_field_cells(FieldData);

if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_plane:' errormsg];
    return
end
check_grid=zeros(size(CellInfo));% =1 if a grid is needed , =0 otherwise, for each field cell

ProjMode=cell(size(CellInfo));
for icell=1:numel(CellInfo)
    ProjMode{icell}=ObjectData.ProjMode;% projection mode of the plane object
end
    icell_grid=[];% field cell index which defines the grid
if ~strcmp(ObjectData.ProjMode,'projection')
    %% define the new coordinates in case of interpolation on a imposed grid
    if ~testYMin
        errormsg='min Y value not defined for the projection grid';return
    end
    if ~testYMax
        errormsg='max Y value not defined for the projection grid';return
    end
    if ~testXMin
        errormsg='min X value not defined for the projection grid';return
    end
    if ~testXMax
        errormsg='max X value not defined for the projection grid';return
    end
else
    %% case of a grid requested by the input field
    for icell=1:numel(CellInfo)% TODO: recalculate coordinates here to get the bounds in the rotated coordinates
        if isfield(CellInfo{icell},'ProjModeRequest')
            switch CellInfo{icell}.ProjModeRequest
                case 'interp_lin'
                    ProjMode{icell}='interp_lin';
                case 'interp_tps'
                    ProjMode{icell}='interp_tps';
            end
        end
        if strcmp(ProjMode{icell},'interp_lin')||strcmp(ProjMode{icell},'interp_tps')
            check_grid(icell)=1;
        end
        if strcmp(CellInfo{icell}.CoordType,'grid')&&NbDimArray(icell)>=2
            if ~testangle && isempty(icell_grid)% if the input gridded data is not modified, choose the first one in case of multiple gridded field cells
                icell_grid=icell;
                ProjMode{icell}='projection';
            end
            check_grid(icell)=1;
        end
    end
    if ~isempty(find(check_grid))% if a grid is requested by the input field
        if isempty(icell_grid)%  if the grid is not given by cell #icell_grid
            if ~isfield(FieldData,'XMax')
                FieldData=find_field_bounds(FieldData);
            end
        end
    end
end
if ~isempty(find(check_grid))||~strcmp(ObjectData.ProjMode,'projection')%no existing gridded data used
    if isempty(icell_grid)||~strcmp(ObjectData.ProjMode,'projection')%no existing gridded data used
        AYName='coord_y';
        AXName='coord_x';
        if strcmp(ObjectData.ProjMode,'projection')
            ProjData.coord_y=[FieldData.YMin FieldData.YMax];%note that if projection is done on a grid, the Min and Max along each direction must have been defined
            ProjData.coord_x=[FieldData.XMin FieldData.XMax];
            coord_x_proj=FieldData.XMin:FieldData.CoordMesh:FieldData.XMax;
            coord_y_proj=FieldData.YMin:FieldData.CoordMesh:FieldData.YMax;
        else
            ProjData.coord_y=[ObjectData.RangeY(1) ObjectData.RangeY(2)];%note that if projection is done on a grid, the Min and Max along each direction must have been defined
            ProjData.coord_x=[ObjectData.RangeX(1) ObjectData.RangeX(2)];
            coord_x_proj=ObjectData.RangeX(1):ObjectData.DX:ObjectData.RangeX(2);
            coord_y_proj=ObjectData.RangeY(1):ObjectData.DY:ObjectData.RangeY(2);
        end
        [XI,YI]=meshgrid(coord_x_proj,coord_y_proj);%grid in the new coordinates
        ProjData.VarDimName={AYName,AXName};
%         XI=ObjectData.Coord(1,1)+(X)*cos(PlaneAngle(3))-YI*sin(PlaneAngle(3));%corresponding coordinates in the original system
%         YI=ObjectData.Coord(1,2)+(X)*sin(PlaneAngle(3))+YI*cos(PlaneAngle(3));
    else% we use the existing grid from field cell #icell_grid
        NbDim=NbDimArray(icell_grid);
        AYName=FieldData.ListVarName{CellInfo{icell_grid}.CoordIndex(NbDim-1)};%name of input x coordinate (name preserved on projection)
        AXName=FieldData.ListVarName{CellInfo{icell_grid}.CoordIndex(NbDim)};%name of input y coordinate (name preserved on projection)
        AYDimName=FieldData.VarDimName{CellInfo{icell_grid}.CoordIndex(NbDim-1)};%
        AXDimName=FieldData.VarDimName{CellInfo{icell_grid}.CoordIndex(NbDim)};%
         ProjData.VarDimName={AYDimName,AXDimName};
        ProjData.(AYName)=FieldData.(AYName); % new (projected ) y coordinates
        ProjData.(AXName)=FieldData.(AXName); % new (projected ) y coordinates
    end
    ProjData.ListVarName={AYName,AXName};
    
    ProjData.VarAttribute={[],[]};
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOOP ON FIELD CELLS, PROJECT VARIABLES
% CellVarIndex=cells of variable index arrays
%ivar_new=0; % index of the current variable in the projected field
% icoord=0;
nbcoord=0;%number of added coordinate variables brought by projection
%nbvar=0;
vector_x_proj=[];
vector_y_proj=[];
for icell=1:length(CellInfo)
    NbDim=NbDimArray(icell);
    if NbDim<2
        continue % only cells represnting 2D or 3D fields are involved
    end
    VarIndex=CellInfo{icell}.VarIndex;%  indices of the selected variables in the list FieldData.ListVarName
    %dimensions
    DimCell=FieldData.VarDimName{VarIndex(1)};
    if ischar(DimCell)
        DimCell={DimCell};%name of dimensions
    end
    coord_z=0;%default
    ListVarName={};% initiate list of projected variables for cell # icell
    VarDimName={};% initiate coresponding list of dimensions for cell # icell
    VarAttribute={};% initiate coresponding list of var attributes  for cell # icell
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch CellInfo{icell}.CoordType
        
        case 'scattered'
            %% case of input fields with unstructured coordinates (applies for projMode ='projection' or 'interp_lin')
            if strcmp(ProjMode{icell},'interp_tps')
                continue %skip for next cell (needs tps field cell)
            end
            coord_x=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(end)});% initial x coordinates
            coord_y=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(end-1)});% initial y coordinates
            check3D=(numel(CellInfo{icell}.CoordIndex)==3);
            if check3D
                coord_z=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(1)});
            end
            
            % translate  initial coordinates to account for the new origin
            coord_x=coord_x-ObjectData.Coord(1,1);
            coord_y=coord_y-ObjectData.Coord(1,2);
            if check3D
                coord_z=coord_z-ObjectData.Coord(1,3);
            end
            
            % selection of the vectors in the projection range (3D case)
            if check3D &&  width > 0
                %components of the unitiy vector normal to the projection plane
                fieldZ=norm_plane(1)*coord_x + norm_plane(2)*coord_y+ norm_plane(3)*coord_z;% distance to the plane
                indcut=find(abs(fieldZ) <= width);
                for ivar=VarIndex
                    VarName=FieldData.ListVarName{ivar};
                    FieldData.(VarName)=FieldData.(VarName)(indcut);
                end
                coord_x=coord_x(indcut);
                coord_y=coord_y(indcut);
                coord_z=coord_z(indcut);
            end
            
            %rotate coordinates if needed: coord_X,coord_Y= = coordinates in the new plane
            Psi=PlaneAngle(1);
            Theta=PlaneAngle(2);
            Phi=PlaneAngle(3);
            if testangle && ~test90y && ~test90x;%=1 for slanted plane
                coord_X=(coord_x *cos(Phi) + coord_y* sin(Phi));
                coord_Y=(-coord_x *sin(Phi) + coord_y *cos(Phi))*cos(Theta);
                coord_Y=coord_Y+coord_z *sin(Theta);
                coord_X=(coord_X *cos(Psi) - coord_Y* sin(Psi));%A VERIFIER
                coord_Y=(coord_X *sin(Psi) + coord_Y* cos(Psi));
            else
                coord_X=coord_x;
                coord_Y=coord_y;
            end
            
            %restriction to the range of X and Y if imposed by the projection object
            testin=ones(size(coord_X)); %default
            testbound=0;
            if testXMin
                testin=testin & (coord_X >= XMin);
                testbound=1;
            end
            if testXMax
                testin=testin & (coord_X <= XMax);
                testbound=1;
            end
            if testYMin
                testin=testin & (coord_Y >= YMin);
                testbound=1;
            end
            if testYMin
                testin=testin & (coord_Y <= YMax);
                testbound=1;
            end
            if testbound
                indcut=find(testin);
                if isempty(indcut)
                    errormsg='data outside the bounds of the projection object';
                    return
                end
                for ivar=VarIndex
                    VarName=FieldData.ListVarName{ivar};
                    FieldData.(VarName)=FieldData.(VarName)(indcut);
                end
                coord_X=coord_X(indcut);
                coord_Y=coord_Y(indcut);
                if check3D
                    coord_Z=coord_Z(indcut);
                end
            end
            
            % two cases of projection for scattered coordinates
            switch ProjMode{icell}
                case 'projection'
                    nbvar=0;
                    %nbvar=numel(ProjData.ListVarName);
                    for ivar=VarIndex %transfer variables to the projection plane
                        VarName=FieldData.ListVarName{ivar};
                        if ivar==CellInfo{icell}.CoordIndex(end)
                            ProjData.(VarName)=coord_X;
                        elseif ivar==CellInfo{icell}.CoordIndex(end-1)  % y coordinate
                            ProjData.(VarName)=coord_Y;
                        elseif ~(check3D && ivar==CellInfo{icell}.CoordIndex(1)) % other variables (except Z coordinate wyhich is not reproduced)
                            ProjData.(VarName)=FieldData.(VarName);
                        end
                        if ~(check3D && ivar==CellInfo{icell}.CoordIndex(1))
                            ListVarName=[ListVarName VarName];
                            VarDimName=[VarDimName DimCell];
                            nbvar=nbvar+1;
                            if isfield(FieldData,'VarAttribute') && length(FieldData.VarAttribute) >=ivar
                                VarAttribute{nbvar}=FieldData.VarAttribute{ivar};
                            end
                        end
                    end
                case 'interp_lin'%interpolate data on a regular grid
                    if isfield(CellInfo{icell},'VarIndex_errorflag')
                        VarName_FF=FieldData.ListVarName{CellInfo{icell}.VarIndex_errorflag};
                        indsel=find(FieldData.(VarName_FF)==0);
                        coord_X=coord_X(indsel);
                        coord_Y=coord_Y(indsel);
                        for ivar=1:numel(CellInfo{icell}.VarIndex)
                            VarName=FieldData.ListVarName{CellInfo{icell}.VarIndex(ivar)};
                            FieldData.(VarName)=FieldData.(VarName)(indsel);
                        end
                    end
                    % interpolate and calculate field on the grid
                    
                    [VarVal,ListVarName,VarAttribute,errormsg]=calc_field_interp([coord_X coord_Y],FieldData,CellInfo{icell}.FieldName,XI,YI);
                    
                    % set to NaN interpolation points which are too far from any initial data (more than 2 CoordMesh)
                    if exist('scatteredInterpolant','file')%recent Matlab versions
                        F=scatteredInterpolant(coord_X, coord_Y,coord_X,'nearest');
                        G=scatteredInterpolant(coord_X, coord_Y,coord_Y,'nearest');
                    else
                        F=TriScatteredInterp([coord_X coord_Y],coord_X,'nearest');
                        G=TriScatteredInterp([coord_X coord_Y],coord_Y,'nearest');
                    end
                    Distx=F(XI,YI)-XI;% diff of x coordinates with the nearest measurement point
                    Disty=G(XI,YI)-YI;% diff of y coordinates with the nearest measurement point
                    Dist=Distx.*Distx+Disty.*Disty;
                    if ~isempty(thresh2)
                        for ivar=1:numel(VarVal)
                            VarVal{ivar}(Dist>thresh2)=NaN;% % put to NaN interpolated positions further than 4 meshes from initial data
                        end
                    end
                    if isfield(CellInfo{icell},'CheckSub') && CellInfo{icell}.CheckSub && ~isempty(vector_x_proj)
                        ProjData.(FieldData.ListVarName{vector_x_proj})=ProjData.(FieldData.ListVarName{vector_x_proj})-VarVal{1};
                        ProjData.(FieldData.ListVarName{vector_y_proj})=ProjData.(FieldData.ListVarName{vector_y_proj})-VarVal{2};
                        ListVarName={};% no new variable
                        VarAttribute={};
                    else
                        VarDimName=cell(size(ListVarName));
                        for ilist=1:numel(ListVarName)% reshape data, excluding coordinates (ilist=1-2), TODO: rationalise
                            ListVarName{ilist}=regexprep(ListVarName{ilist},'(.+','');
                            if ~isempty(find(strcmp(ListVarName{ilist},ProjData.ListVarName)))
                                ListVarName{ilist}=[ListVarName{ilist} '_1'];
                            end
                            ProjData.(ListVarName{ilist})=VarVal{ilist};
                            VarDimName{ilist}={'coord_y','coord_x'};
                        end
                    end
                    if isfield (CellInfo{icell},'VarIndex_vector_x')&& isfield (CellInfo{icell},'VarIndex_vector_y')
                    vector_x_proj=CellInfo{icell}.VarIndex_vector_x; %preserve for next cell
                    vector_y_proj=CellInfo{icell}.VarIndex_vector_y; %preserve for next cell
                    end
            end
            
        case 'tps'
            %% case of tps data (applies only in interp_tps mode)
            if strcmp(ProjMode{icell},'interp_tps')
                Coord=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex});
                NbCentres=FieldData.(FieldData.ListVarName{CellInfo{icell}.NbCentres_tps});
                SubRange=FieldData.(FieldData.ListVarName{CellInfo{icell}.SubRange_tps});
                if isfield(CellInfo{icell},'VarIndex_vector_x_tps')&&isfield(CellInfo{icell},'VarIndex_vector_y_tps')
                    FieldVar=cat(3,FieldData.(FieldData.ListVarName{CellInfo{icell}.VarIndex_vector_x_tps}),FieldData.(FieldData.ListVarName{CellInfo{icell}.VarIndex_vector_y_tps}));
                end
                % interpolate data using thin plate spline
                [DataOut,VarAttribute,errormsg]=calc_field_tps(Coord,NbCentres,SubRange,FieldVar,CellInfo{icell}.FieldName,cat(3,XI,YI));
                
                % set to NaN interpolation points which are too far from any initial data (more than 2 CoordMesh)
                Coord=permute(Coord,[1 3 2]);
                Coord=reshape(Coord,size(Coord,1)*size(Coord,2),2);
                if exist('scatteredInterpolant','file')%recent Matlab versions
                    F=scatteredInterpolant(Coord,Coord(:,1),'nearest');
                    G=scatteredInterpolant(Coord,Coord(:,2),'nearest');
                else
                    F=TriScatteredInterp(Coord,Coord(:,1),'nearest');
                    G=TriScatteredInterp(Coord,Coord(:,2),'nearest');
                end
                Distx=F(XI,YI)-XI;% diff of x coordinates with the nearest measurement point
                Disty=G(XI,YI)-YI;% diff of y coordinates with the nearest measurement point
                Dist=Distx.*Distx+Disty.*Disty;
                ListVarName=(fieldnames(DataOut))';
                VarDimName=cell(size(ListVarName));
                for ilist=1:numel(ListVarName)% reshape data, excluding coordinates (ilist=1-2), TODO: rationalise
                    VarName=ListVarName{ilist};
                    VarDimName{ilist}={'coord_y','coord_x'};
                    ProjData.(VarName)=DataOut.(VarName);
                    if ~isempty(thresh2)
                        ProjData.(VarName)(Dist>thresh2)=NaN;% put to NaN interpolated positions further than RangeInterp from initial data
                    end
                end
            end
            
        case 'grid'
            %% case of input fields defined on a structured  grid
            VarName=FieldData.ListVarName{VarIndex(1)};%get the first variable of the cell to get the input matrix dimensions
            DimValue=size(FieldData.(VarName));%input matrix dimensions
            DimValue(DimValue==1)=[];%remove singleton dimensions
            NbDim=numel(DimValue);%update number of space dimensions
            nbcolor=1; %default number of 'color' components: third matrix index without corresponding coordinate
            if NbDim>=3
                if NbDim>3
                    errormsg='matrices with more than 3 dimensions not handled';
                    return
                else
                    if numel(CellInfo{icell}.CoordIndex)==2% the third matrix dimension does not correspond to a space coordinate
                        nbcolor=DimValue(3);
                        DimValue(3)=[]; %number of 'color' components updated
                        NbDim=2;% space dimension set to 2
                    end
                end
            end
            Coord_z=[];
            Coord_y=[];
            Coord_x=[];
            
            if testangle
                ProjMode{icell}='interp_lin'; %request linear interpolation for projection on a tilted plane
            end
            
            if isequal(ProjMode{icell},'projection')% && (~testangle || test90y || test90x)
                if  NbDim==2 && ~testXMin && ~testXMax && ~testYMin && ~testYMax% no range restriction
                    ListVarName=[ListVarName FieldData.ListVarName(VarIndex)];
                    VarDimName=[VarDimName FieldData.VarDimName(VarIndex)];
                    if isfield(FieldData,'VarAttribute')
                        VarAttribute=[VarAttribute FieldData.VarAttribute(VarIndex)];
                    end
                    ProjData.(AYName)=FieldData.(AYName);
                    ProjData.(AXName)=FieldData.(AXName);
                    for ivar=VarIndex
                        VarName=FieldData.ListVarName{ivar};
                        ProjData.(VarName)=FieldData.(VarName);% no change by projection
                    end
                else
                    Coord{1}=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(1)});
                    Coord{2}=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(2)});
                    if NbDim==3
                        Coord{3}=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(3)});
                    end
                    if numel(Coord{NbDim-1})==2
                        DY=(Coord{NbDim-1}(2)-Coord{NbDim-1}(1))/(DimValue(1)-1);
                    end
                    if numel(Coord{NbDim})==2
                        DX=(Coord{NbDim}(2)-Coord{NbDim}(1))/(DimValue(2)-1);
                    end
                    if testYMax
                         YIndexMax=(YMax-Coord{NbDim-1}(1))/DY+1;% matrix index corresponding to the max y value for the new field
                        if testYMin%test_direct(indY)
                            YIndexMin=(YMin-Coord{NbDim-1}(1))/DY+1;% matrix index corresponding to the min x value for the new field
                        else
                            YIndexMin=1;
                        end          
                    else
                        YIndexMax=Coord{NbDim-1}(end)/DY;
                        YIndexMin=1;
                    end
                    if testXMax
                         XIndexMax=(XMax-Coord{NbDim}(1))/DY+1;% matrix index corresponding to the max y value for the new field
                        if testYMin%test_direct(indY)
                            XIndexMin=(XMin-Coord{NbDim}(1))/DX+1;% matrix index corresponding to the min x value for the new field
                        else
                            XIndexMin=1;
                        end          
                    else
                        XIndexMax=Coord{NbDim}(end)/DX;
                        XIndexMin=1;
                    end
                    YIndexRange(1)=ceil(min(YIndexMin,YIndexMax));%first y index to select from the previous field
                    YIndexRange(1)=max(YIndexRange(1),1);% avoid bound lower than the first index
                    YIndexRange(2)=floor(max(YIndexMin,YIndexMax));%last y index to select from the previous field
                    YIndexRange(2)=min(YIndexRange(2),DimValue(NbDim-1));% limit to the last available index
                    XIndexRange(1)=ceil(min(XIndexMin,XIndexMax));%first x index to select from the previous field
                    XIndexRange(1)=max(XIndexRange(1),1);% avoid bound lower than the first index
                    XIndexRange(2)=floor(max(XIndexMin,XIndexMax));%last x index to select from the previous field
                    XIndexRange(2)=min(XIndexRange(2),DimValue(NbDim));% limit to the last available index
                    if test90y
                        ind_new=[3 2 1];
                        DimCell={AYProjName,AXProjName};
                        iz=ceil((ObjectData.Coord(1,1)-Coord{3}(1))/DX)+1;
                        for ivar=VarIndex
                            VarName=FieldData.ListVarName{ivar};
                            ListVarName=[ListVarName VarName];
                            VarDimName=[VarDimName {DimCell}];
                            VarAttribute{length(ListVarName)}=FieldData.VarAttribute{ivar}; %reproduce the variable attributes
                            ProjData.(VarName)=permute(FieldData.(VarName),ind_new);% permute x and z indices for 90 degree rotation
                            ProjData.(VarName)=squeeze(ProjData.(VarName)(iz,:,:));% select the z index iz
                        end
                        ProjData.(AYName)=[Ybound(1) Ybound(2)]; %record the new (projected ) y coordinates
                        ProjData.(AXName)=[Coord{1}(end),Coord{1}(1)]; %record the new (projected ) x coordinates
                    else
                        if NbDim==3
                            DZ=(Coord{1}(end)-Coord{1}(1))/(numel(Coord{1})-1);
                            DimCell(1)=[]; %suppress z variable
                            DimValue(1)=[];
                            test_direct=1;%TOdo; GENERALIZE, SEE CASE OF points
                            if test_direct(1)
                                iz=ceil((ObjectData.Coord(1,3)-Coord{1}(1))/DZ)+1;
                            else
                                iz=ceil((Coord{1}(1)-ObjectData.Coord(1,3))/DZ)+1;
                            end
                        end
                        for ivar=VarIndex% loop on non coordinate variables
                            VarName=FieldData.ListVarName{ivar};
                            ListVarName=[ListVarName VarName];
                            VarDimName=[VarDimName {DimCell}];
                            if isfield(FieldData,'VarAttribute') && length(FieldData.VarAttribute)>=ivar
                                VarAttribute{length(ListVarName)}=FieldData.VarAttribute{ivar};
                            end
                            if NbDim==3
                                ProjData.(VarName)=squeeze(FieldData.(VarName)(iz,YIndexRange(1):YIndexRange(end),XIndexRange(1):XIndexRange(end)));
                            else
                                ProjData.(VarName)=FieldData.(VarName)(YIndexRange(1):YIndexRange(end),XIndexRange(1):XIndexRange(end),:);
                            end
                        end
                        if testXMax
                         ProjData.(AXName)=Coord{NbDim}(1)+DX*(XIndexRange-1); %record the new (projected ) x coordinates
                        else
                          ProjData.(AXName)=FieldData.(AXName);
                        end
                        if testYMax
                            ProjData.(AYName)=Coord{NbDim-1}(1)+DY*(YIndexRange-1); %record the new (projected ) x coordinates
                        else
                          ProjData.(AYName)=FieldData.(AYName);
                        end                            
                    end
                end
            else       % case with interpolation on a grid
                if NbDim==2 %2D case
                    if isequal(ProjMode{icell},'interp_tps')
                        npx_interp_tps=ceil(abs(DX/DAX));
                        npy_interp_tps=ceil(abs(DY/DAY));
                        Minterp_tps=ones(npy_interp_tps,npx_interp_tps)/(npx_interp_tps*npy_interp_tps);
                        test_interp_tps=1;
                    else
                        test_interp_tps=0;
                    end
                    Coord{1}=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(1)});
                    Coord{2}=FieldData.(FieldData.ListVarName{CellInfo{icell}.CoordIndex(2)});
                    if ~(testXMin && testYMin)% % if the range of the projected coordinates is not fully defined by the projection object, find the extrema of the projected field
                        xcorner=[min(Coord{NbDim}) max(Coord{NbDim}) max(Coord{NbDim}) min(Coord{NbDim})]-ObjectData.Coord(1,1);% corner absissa of the original grid with respect to the new origin
                        ycorner=[min(Coord{NbDim-1}) min(Coord{NbDim-1}) max(Coord{NbDim-1}) max(Coord{NbDim-1})]-ObjectData.Coord(1,2);% corner ordinates of the original grid
                        xcor_new=xcorner*cos(PlaneAngle(3))+ycorner*sin(PlaneAngle(3));%coordinates of the corners in new frame
                        ycor_new=-xcorner*sin(PlaneAngle(3))+ycorner*cos(PlaneAngle(3));
                        if ~testXMin
                            XMin=min(xcor_new);
                        end
                        if ~testXMax
                            XMax=max(xcor_new);
                        end
                        if ~testYMin
                            YMin=min(ycor_new);
                        end
                        if ~testYMax
                            YMax=max(ycor_new);
                        end
                    end
                    coord_x_proj=XMin:DX:XMax;
                    coord_y_proj=YMin:DY:YMax;
                    ProjData.(AYName)=[coord_y_proj(1) coord_y_proj(end)]; %record the new (projected ) y coordinates
                    ProjData.(AXName)=[coord_x_proj(1) coord_x_proj(end)]; %record the new (projected ) x coordinates
                    [X,YI]=meshgrid(coord_x_proj,coord_y_proj);%grid in the new coordinates
                    XI=ObjectData.Coord(1,1)+(X)*cos(PlaneAngle(3))-YI*sin(PlaneAngle(3));%corresponding coordinates in the original system
                    YI=ObjectData.Coord(1,2)+(X)*sin(PlaneAngle(3))+YI*cos(PlaneAngle(3));
                    if numel(Coord{1})==2% x coordiante defiend by its bounds, get the whole set
                        Coord{1}=linspace(Coord{1}(1),Coord{1}(2),CellInfo{icell}.CoordSize(1));
                    end
                    if numel(Coord{2})==2% y coordiante defiend by its bounds, get the whole set
                        Coord{2}=linspace(Coord{2}(1),Coord{2}(2),CellInfo{icell}.CoordSize(2));
                    end
                    [X,Y]=meshgrid(Coord{2},Coord{1});%initial coordinates
                    %name of error flag variable
                    FFName='FF';%default name (if not already used)
                    if isfield(ProjData,'FF')
                        ind=1;
                        while isfield(ProjData,['FF_' num2str(ind)])
                            ind=ind+1;
                        end
                        FFName=['FF_' num2str(ind)];% append an index to the name of error flag, FF_1,FF_2...
                    end
                    % project all variables in the cell
                    for ivar=VarIndex
                        VarName=FieldData.ListVarName{ivar};
                        if size(FieldData.(VarName),3)==1
                            ProjData.(VarName)=interp2(X,Y,double(FieldData.(VarName)),XI,YI,'*linear');%interpolation fct
                        else
                            ProjData.(VarName)=interp2(X,Y,double(FieldData.(VarName)(:,:,1)),XI,YI,'*linear');
                            for icolor=2:size(FieldData.(VarName),3)% project 'color' components
                                ProjData.(VarName)=cat(3,ProjData.(VarName),interp2(X,Y,double(FieldData.(VarName)(:,:,icolor)),XI,YI,'*linear')); 
                            end
                        end
                        if isa(FieldData.(VarName),'uint8')
                            ProjData.(VarName)=uint8(ProjData.(VarName));%put result to integer 8 bits if the initial field is integer (image)
                        elseif isa(FieldData.(VarName),'uint16')
                            ProjData.(VarName)=uint16(ProjData.(VarName));%put result to integer 16 bits if the initial field is integer (image)
                        end
                        ListVarName=[ListVarName VarName];
                        DimCell(1:2)={AYName,AXName};
                        VarDimName=[VarDimName {DimCell}];
                        if isfield(FieldData,'VarAttribute')&&length(FieldData.VarAttribute)>=ivar
                            VarAttribute{length(ListVarName)+nbcoord}=FieldData.VarAttribute{ivar};
                        end;
                        ProjData.(FFName)=isnan(ProjData.(VarName));%detact NaN (points outside the interpolation range)
                        ProjData.(VarName)(ProjData.(FFName))=0; %set to 0 the NaN data
                    end
                    %update list of variables with error flag
                    ListVarName=[ListVarName FFName];
                    VarDimName=[VarDimName {DimCell}];
                    VarAttribute{numel(ListVarName)}.Role='errorflag';
                elseif ~testangle
                    % unstructured z coordinate
                    test_sup=(Coord{1}>=ObjectData.Coord(1,3));
                    iz_sup=find(test_sup);
                    iz=iz_sup(1);
                    if iz>=1 & iz<=npz
                        %ProjData.ListDimName=[ProjData.ListDimName ListDimName(2:end)];
                        %ProjData.DimValue=[ProjData.DimValue npY npX];
                        for ivar=VarIndex
                            VarName=FieldData.ListVarName{ivar};
                            ListVarName=[ListVarName VarName];
                            VarAttribute{length(ListVarName)}=FieldData.VarAttribute{ivar}; %reproduce the variable attributes
                            ProjData.(VarName)=squeeze(FieldData.(VarName)(iz,:,:));% select the z index iz
                            %TODO : do a vertical average for a thick plane
                            if test_interp(2) || test_interp(3)
                                ProjData.(VarName)=interp2(Coord{3},Coord{2},ProjData.(VarName),Coord_x,Coord_y);
                            end
                        end
                    end
                else
                    errormsg='projection of structured coordinates on oblique plane not yet implemented';
                    %TODO: use interp_lin3
                    return
                end
            end
    end
    % update the global list of projected variables:
    ProjData.ListVarName=[ProjData.ListVarName ListVarName];
    ProjData.VarDimName=[ProjData.VarDimName VarDimName];
    ProjData.VarAttribute=[ProjData.VarAttribute VarAttribute];
    
    %% projection of  velocity components in the rotated coordinates
    if testangle
        ivar_U=[];ivar_V=[];ivar_W=[];
        for ivar=1:numel(VarAttribute)
            if isfield(VarAttribute{ivar},'Role')
                if strcmp(VarAttribute{ivar}.Role,'vector_x')
                    ivar_U=ivar;
                elseif strcmp(VarAttribute{ivar}.Role,'vector_y')
                    ivar_V=ivar;
                elseif strcmp(VarAttribute{ivar}.Role,'vector_z')
                    ivar_W=ivar;
                end
            end
        end
        if ~isempty(ivar_U)
            if isempty(ivar_V)
                msgbox_uvmat('ERROR','v velocity component missing in proj_field.m')
                return
            else
                UName=ListVarName{ivar_U};
                VName=ListVarName{ivar_V};
                ProjData.(UName)=cos(PlaneAngle(3))*ProjData.(UName)+ sin(PlaneAngle(3))*ProjData.(VName);
                ProjData.(VName)=(-sin(PlaneAngle(3))*ProjData.(UName)+ cos(PlaneAngle(3))*ProjData.(VName));
                if ~isempty(ivar_W)
                    WName=FieldData.ListVarName{ivar_W};
                    ProjData.(VName)=ProjData.(VName)+ ProjData.(WName)*sin(Theta);%
                    ProjData.(WName)=NormVec_X*ProjData.(UName)+ NormVec_Y*ProjData.(VName)+ NormVec_Z* ProjData.(WName);
                end
            end
        end
    end
end
% %prepare substraction in case of two input fields
% SubData.ListVarName={};
% SubData.VarDimName={};
% SubData.VarAttribute={};
% check_remove=zeros(size(ProjData.ListVarName));
% for iproj=1:numel(ProjData.VarAttribute)
%     if isfield(ProjData.VarAttribute{iproj},'CheckSub')&&isequal(ProjData.VarAttribute{iproj}.CheckSub,1)
%         VarName=ProjData.ListVarName{iproj};
%         SubData.ListVarName=[SubData.ListVarName {VarName}];
%         SubData.VarDimName=[SubData.VarDimName ProjData.VarDimName{iproj}];
%         SubData.VarAttribute=[SubData.VarAttribute ProjData.VarAttribute{iproj}];
%         SubData.(VarName)=ProjData.(VarName);
%         check_remove(iproj)=1;
%     end
% end
% if ~isempty(find(check_remove))
%     ind_remove=find(check_remove);
%     ProjData.ListVarName(ind_remove)=[];
%     ProjData.VarDimName(ind_remove)=[];
%     ProjData.VarAttribute(ind_remove)=[];
%     ProjData=sub_field(ProjData,[],SubData);
% end

%-----------------------------------------------------------------
%projection in a volume
function  [ProjData,errormsg] = proj_volume(FieldData, ObjectData)

%-----------------------------------------------------------------
ProjData=FieldData;%default output

%% axis origin
if isempty(ObjectData.Coord)
    ObjectData.Coord(1,1)=0;%origin of the plane set to [0 0] by default
    ObjectData.Coord(1,2)=0;
    ObjectData.Coord(1,3)=0;
end

%% rotation angles
VolumeAngle=[0 0 0];
norm_plane=[0 0 1];
if isfield(ObjectData,'Angle')&& isequal(size(ObjectData.Angle),[1 3])&& ~isequal(ObjectData.Angle,[0 0 0])
    PlaneAngle=ObjectData.Angle;
    VolumeAngle=ObjectData.Angle;
    om=norm(VolumeAngle);%norm of rotation angle in radians
    OmAxis=VolumeAngle/om; %unit vector marking the rotation axis
    cos_om=cos(pi*om/180);
    sin_om=sin(pi*om/180);
    coeff=OmAxis(3)*(1-cos_om);
    %components of the unity vector norm_plane normal to the projection plane
    norm_plane(1)=OmAxis(1)*coeff+OmAxis(2)*sin_om;
    norm_plane(2)=OmAxis(2)*coeff-OmAxis(1)*sin_om;
    norm_plane(3)=OmAxis(3)*coeff+cos_om;
end
testangle=~isequal(VolumeAngle,[0 0 0]);

%% mesh sizes DX, DY, DZ
DX=0;
DY=0; %default 
DZ=0;
if isfield(ObjectData,'DX')&~isempty(ObjectData.DX)
     DX=abs(ObjectData.DX);%mesh of interpolation points 
end
if isfield(ObjectData,'DY')&~isempty(ObjectData.DY)
     DY=abs(ObjectData.DY);%mesh of interpolation points 
end
if isfield(ObjectData,'DZ')&~isempty(ObjectData.DZ)
     DZ=abs(ObjectData.DZ);%mesh of interpolation points 
end
if  ~strcmp(ProjMode,'projection') && (DX==0||DY==0||DZ==0)
        errormsg='grid mesh DX , DY or DZ is missing';
        return
end

%% extrema along each axis
testXMin=0;
testXMax=0;
testYMin=0;
testYMax=0;
if isfield(ObjectData,'RangeX')
        XMin=min(ObjectData.RangeX);
        XMax=max(ObjectData.RangeX);
        testXMin=XMax>XMin;
        testXMax=1;
end
if isfield(ObjectData,'RangeY')
        YMin=min(ObjectData.RangeY);
        YMax=max(ObjectData.RangeY);
        testYMin=YMax>YMin;
        testYMax=1;
end
width=0;%default width of the projection band
if isfield(ObjectData,'RangeZ')
        ZMin=min(ObjectData.RangeZ);
        ZMax=max(ObjectData.RangeZ);
        testZMin=ZMax>ZMin;
        testZMax=1;
end

%% initiate Matlab  structure for physical field
[ProjData,errormsg]=proj_heading(FieldData,ObjectData);
if ~isempty(errormsg)
    return
end

ProjData.NbDim=3;
ProjData.ListVarName={};
ProjData.VarDimName={};
if ~isequal(DX,0)&& ~isequal(DY,0)
    ProjData.CoordMesh=sqrt(DX*DY);%define typical data mesh, useful for mouse selection in plots
elseif isfield(FieldData,'CoordMesh')
    ProjData.CoordMesh=FieldData.CoordMesh;
end

error=0;%default
flux=0;
testfalse=0;
ListIndex={};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% group the variables (fields of 'FieldData') in cells of variables with the same dimensions
%-----------------------------------------------------------------
idimvar=0;
% LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
% CellVarIndex=cells of variable index arrays
ivar_new=0; % index of the current variable in the projected field
icoord=0;
nbcoord=0;%number of added coordinate variables brought by projection
nbvar=0;
for icell=1:length(CellVarIndex)
    NbDim=NbDimVec(icell);
    if NbDim<3
        continue
    end
    VarIndex=CellVarIndex{icell};%  indices of the selected variables in the list FieldData.ListVarName
    VarType=VarTypeCell{icell};
    ivar_X=VarType.coord_x;
    ivar_Y=VarType.coord_y;
    ivar_Z=VarType.coord_z;
    ivar_U=VarType.vector_x;
    ivar_V=VarType.vector_y;
    ivar_W=VarType.vector_z;
    ivar_C=VarType.scalar ;
    ivar_Anc=VarType.ancillary;
    test_anc=zeros(size(VarIndex));
    test_anc(ivar_Anc)=ones(size(ivar_Anc));
    ivar_F=VarType.warnflag;
    ivar_FF=VarType.errorflag;
    check_unstructured_coord=~isempty(ivar_X) && ~isempty(ivar_Y);
    DimCell=FieldData.VarDimName{VarIndex(1)};
    if ischar(DimCell)
        DimCell={DimCell};%name of dimensions
    end

%% case of input fields with unstructured coordinates
    if check_unstructured_coord
        XName=FieldData.ListVarName{ivar_X};
        YName=FieldData.ListVarName{ivar_Y};
        eval(['coord_x=FieldData.' XName ';'])
        eval(['coord_y=FieldData.' YName ';'])
        if length(ivar_Z)==1
            ZName=FieldData.ListVarName{ivar_Z};
            eval(['coord_z=FieldData.' ZName ';'])
        end

        % translate  initial coordinates
        coord_x=coord_x-ObjectData.Coord(1,1);
        coord_y=coord_y-ObjectData.Coord(1,2);
        if ~isempty(ivar_Z)
            coord_z=coord_z-ObjectData.Coord(1,3);
        end
        
        % selection of the vectors in the projection range
%         if length(ivar_Z)==1 &&  width > 0
%             %components of the unitiy vector normal to the projection plane
%             fieldZ=NormVec_X*coord_x + NormVec_Y*coord_y+ NormVec_Z*coord_z;% distance to the plane            
%             indcut=find(abs(fieldZ) <= width);
%             for ivar=VarIndex
%                 VarName=FieldData.ListVarName{ivar};
%                 eval(['FieldData.' VarName '=FieldData.' VarName '(indcut);'])  
%                     % A VOIR : CAS DE VAR STRUCTUREE MAIS PAS GRILLE REGULIERE : INTERPOLER SUR GRILLE REGULIERE              
%             end
%             coord_x=coord_x(indcut);
%             coord_y=coord_y(indcut);
%             coord_z=coord_z(indcut);
%         end

       %rotate coordinates if needed: TODO modify
       if testangle
           coord_X=(coord_x *cos(Phi) + coord_y* sin(Phi));
           coord_Y=(-coord_x *sin(Phi) + coord_y *cos(Phi))*cos(Theta);
           if ~isempty(ivar_Z)
               coord_Y=coord_Y+coord_z *sin(Theta);
           end
           
           coord_X=(coord_X *cos(Psi) - coord_Y* sin(Psi));%A VERIFIER
           coord_Y=(coord_X *sin(Psi) + coord_Y* cos(Psi));
           
       else
           coord_X=coord_x;
           coord_Y=coord_y;
           coord_Z=coord_z;
       end
        %restriction to the range of x and y if imposed
        testin=ones(size(coord_X)); %default
        testbound=0;
        if testXMin
            testin=testin & (coord_X >= XMin);
            testbound=1;
        end
        if testXMax
            testin=testin & (coord_X <= XMax);
            testbound=1;
        end
        if testYMin
            testin=testin & (coord_Y >= YMin);
            testbound=1;
        end
        if testYMax
            testin=testin & (coord_Y <= YMax);
            testbound=1;
        end
        if testbound
            indcut=find(testin);
            for ivar=VarIndex
                VarName=FieldData.ListVarName{ivar};
                eval(['FieldData.' VarName '=FieldData.' VarName '(indcut);'])            
            end
            coord_X=coord_X(indcut);
            coord_Y=coord_Y(indcut);
            if length(ivar_Z)==1
                coord_Z=coord_Z(indcut);
            end
        end
        % different cases of projection
        if isequal(ObjectData.ProjMode,'projection')%%%%%%%   NOT USED %%%%%%%%%%
            for ivar=VarIndex %transfer variables to the projection plane
                VarName=FieldData.ListVarName{ivar};
                if ivar==ivar_X %x coordinate
                    eval(['ProjData.' VarName '=coord_X;'])
                elseif ivar==ivar_Y % y coordinate
                    eval(['ProjData.' VarName '=coord_Y;'])
                elseif isempty(ivar_Z) || ivar~=ivar_Z % other variables (except Z coordinate wyhich is not reproduced)
                    eval(['ProjData.' VarName '=FieldData.' VarName ';'])
                end
                if isempty(ivar_Z) || ivar~=ivar_Z 
                    ProjData.ListVarName=[ProjData.ListVarName VarName];
                    ProjData.VarDimName=[ProjData.VarDimName DimCell];
                    nbvar=nbvar+1;
                    if isfield(FieldData,'VarAttribute') && length(FieldData.VarAttribute) >=ivar
                        ProjData.VarAttribute{nbvar}=FieldData.VarAttribute{ivar};
                    end
                end
            end  
        elseif isequal(ObjectData.ProjMode,'interp_lin')||isequal(ObjectData.ProjMode,'interp_tps')%interpolate data on a regular grid
            coord_x_proj=XMin:DX:XMax;
            coord_y_proj=YMin:DY:YMax;
            coord_z_proj=ZMin:DZ:ZMax;
            DimCell={'coord_z','coord_y','coord_x'};
            ProjData.ListVarName={'coord_z','coord_y','coord_x'};
            ProjData.VarDimName={'coord_z','coord_y','coord_x'};   
            nbcoord=2;  
            ProjData.coord_z=[ZMin ZMax];
            ProjData.coord_y=[YMin YMax];
            ProjData.coord_x=[XMin XMax];
            if isempty(ivar_X), ivar_X=0; end;
            if isempty(ivar_Y), ivar_Y=0; end;
            if isempty(ivar_Z), ivar_Z=0; end;
            if isempty(ivar_U), ivar_U=0; end;
            if isempty(ivar_V), ivar_V=0; end;
            if isempty(ivar_W), ivar_W=0; end;
            if isempty(ivar_F), ivar_F=0; end;
            if isempty(ivar_FF), ivar_FF=0; end;
            if ~isequal(ivar_FF,0)
                VarName_FF=FieldData.ListVarName{ivar_FF};
                eval(['indsel=find(FieldData.' VarName_FF '==0);'])
                coord_X=coord_X(indsel);
                coord_Y=coord_Y(indsel);
            end
            FF=zeros(1,length(coord_y_proj)*length(coord_x_proj));
            testFF=0;
            [X,Y,Z]=meshgrid(coord_y_proj,coord_z_proj,coord_x_proj);%grid in the new coordinates
            for ivar=VarIndex
                VarName=FieldData.ListVarName{ivar};
                if ~( ivar==ivar_X || ivar==ivar_Y || ivar==ivar_Z || ivar==ivar_F || ivar==ivar_FF || test_anc(ivar)==1)                 
                    ivar_new=ivar_new+1;
                    ProjData.ListVarName=[ProjData.ListVarName {VarName}];
                    ProjData.VarDimName=[ProjData.VarDimName {DimCell}];
                    if isfield(FieldData,'VarAttribute') && length(FieldData.VarAttribute) >=ivar
                        ProjData.VarAttribute{ivar_new+nbcoord}=FieldData.VarAttribute{ivar};
                    end
                    if  ~isequal(ivar_FF,0)
                        eval(['FieldData.' VarName '=FieldData.' VarName '(indsel);'])
                    end
                    % linear interpolation
                    InterpFct=TriScatteredInterp(double(coord_X),double(coord_Y),double(coord_Z),double(FieldData.(VarName)));
                    ProjData.(VarName)=InterpFct(X,Y,Z);
%                     eval(['varline=reshape(ProjData.' VarName ',1,length(coord_y_proj)*length(coord_x_proj));'])
%                     FFlag= isnan(varline); %detect undefined values NaN
%                     indnan=find(FFlag);
%                     if ~isempty(indnan)
%                         varline(indnan)=zeros(size(indnan));
%                         eval(['ProjData.' VarName '=reshape(varline,length(coord_y_proj),length(coord_x_proj));'])
%                         FF(indnan)=ones(size(indnan));
%                         testFF=1;
%                     end
                    if ivar==ivar_U
                        ivar_U=ivar_new;
                    end
                    if ivar==ivar_V
                        ivar_V=ivar_new;
                    end
                    if ivar==ivar_W
                        ivar_W=ivar_new;
                    end
                end
            end
            if testFF
                ProjData.FF=reshape(FF,length(coord_y_proj),length(coord_x_proj));
                ProjData.ListVarName=[ProjData.ListVarName {'FF'}];
               ProjData.VarDimName=[ProjData.VarDimName {DimCell}];
                ProjData.VarAttribute{ivar_new+1+nbcoord}.Role='errorflag';
            end
        end
        
%% case of input fields defined on a structured  grid 
    else
        VarName=FieldData.ListVarName{VarIndex(1)};%get the first variable of the cell to get the input matrix dimensions
        eval(['DimValue=size(FieldData.' VarName ');'])%input matrix dimensions
        DimValue(DimValue==1)=[];%remove singleton dimensions       
        NbDim=numel(DimValue);%update number of space dimensions
        nbcolor=1; %default number of 'color' components: third matrix index without corresponding coordinate
        if NbDim>=3
            if NbDim>3
                errormsg='matrices with more than 3 dimensions not handled';
                return
            else
                if numel(find(VarType.coord))==2% the third matrix dimension does not correspond to a space coordinate
                    nbcolor=DimValue(3);
                    DimValue(3)=[]; %number of 'color' components updated
                    NbDim=2;% space dimension set to 2
                end
            end
        end
        AYName=FieldData.ListVarName{VarType.coord(NbDim-1)};%name of input x coordinate (name preserved on projection)
        AXName=FieldData.ListVarName{VarType.coord(NbDim)};%name of input y coordinate (name preserved on projection)    
        eval(['AX=FieldData.' AXName ';'])
        eval(['AY=FieldData.' AYName ';'])
        ListDimName=FieldData.VarDimName{VarIndex(1)};
        ProjData.ListVarName=[ProjData.ListVarName {AYName} {AXName}]; %TODO: check if it already exists in Projdata (several cells)
        ProjData.VarDimName=[ProjData.VarDimName {AYName} {AXName}];

%         for idim=1:length(ListDimName)
%             DimName=ListDimName{idim};
%             if strcmp(DimName,'rgb')||strcmp(DimName,'nb_coord')||strcmp(DimName,'nb_coord_i')
%                nbcolor=DimValue(idim);
%                DimValue(idim)=[];
%             end
%             if isequal(DimName,'nb_coord_j')% NOTE: CASE OF TENSOR NOT TREATED
%                 DimValue(idim)=[];
%             end
%         end  
        Coord_z=[];
        Coord_y=[];
        Coord_x=[];   

        for idim=1:NbDim %loop on space dimensions
            test_interp(idim)=0;%test for coordiate interpolation (non regular grid), =0 by default
            ivar=VarType.coord(idim);% index of the variable corresponding to the current dimension
            if ~isequal(ivar,0)%  a variable corresponds to the dimension #idim
                eval(['Coord{idim}=FieldData.' FieldData.ListVarName{ivar} ';']) ;% coord values for the input field
                if numel(Coord{idim})==2 %input array defined on a regular grid
                   DCoord_min(idim)=(Coord{idim}(2)-Coord{idim}(1))/DimValue(idim);
                else
                    DCoord=diff(Coord{idim});%array of coordinate derivatives for the input field
                    DCoord_min(idim)=min(DCoord);
                    DCoord_max=max(DCoord);
                %    test_direct(idim)=DCoord_max>0;% =1 for increasing values, 0 otherwise
                    if abs(DCoord_max-DCoord_min(idim))>abs(DCoord_max/1000) 
                        msgbox_uvmat('ERROR',['non monotonic dimension variable # ' num2str(idim)  ' in proj_field.m'])
                                return
                    end               
                    test_interp(idim)=(DCoord_max-DCoord_min(idim))> 0.0001*abs(DCoord_max);% test grid regularity
                end
                test_direct(idim)=(DCoord_min(idim)>0);
            else  % no variable associated with the  dimension #idim, the coordinate value is set equal to the matrix index by default
                Coord_i_str=['Coord_' num2str(idim)];
                DCoord_min(idim)=1;%default
                Coord{idim}=[0.5 DimValue(idim)-0.5];
                test_direct(idim)=1;
            end
        end
        if DY==0
            DY=abs(DCoord_min(NbDim-1));
        end
        npY=1+round(abs(Coord{NbDim-1}(end)-Coord{NbDim-1}(1))/DY);%nbre of points after interpol 
        if DX==0
            DX=abs(DCoord_min(NbDim));
        end
        npX=1+round(abs(Coord{NbDim}(end)-Coord{NbDim}(1))/DX);%nbre of points after interpol 
        for idim=1:NbDim
            if test_interp(idim)
                DimValue(idim)=1+round(abs(Coord{idim}(end)-Coord{idim}(1))/abs(DCoord_min(idim)));%nbre of points after possible interpolation on a regular gri
            end
        end       
        Coord_y=linspace(Coord{NbDim-1}(1),Coord{NbDim-1}(end),npY);
        test_direct_y=test_direct(NbDim-1);
        Coord_x=linspace(Coord{NbDim}(1),Coord{NbDim}(end),npX);
        test_direct_x=test_direct(NbDim);
        DAX=DCoord_min(NbDim);
        DAY=DCoord_min(NbDim-1);  
        minAX=min(Coord_x);
        maxAX=max(Coord_x);
        minAY=min(Coord_y);
        maxAY=max(Coord_y);
        xcorner=[minAX maxAX minAX maxAX]-ObjectData.Coord(1,1);
        ycorner=[maxAY maxAY minAY minAY]-ObjectData.Coord(1,2);
        xcor_new=xcorner*cos(Phi)+ycorner*sin(Phi);%coord new frame
        ycor_new=-xcorner*sin(Phi)+ycorner*cos(Phi);
        if ~testXMax
            XMax=max(xcor_new);
        end
        if ~testXMin
            XMin=min(xcor_new);
        end
        if ~testYMax
            YMax=max(ycor_new);
        end
        if ~testYMin
            YMin=min(ycor_new);
        end
        DXinit=(maxAX-minAX)/(DimValue(NbDim)-1);
        DYinit=(maxAY-minAY)/(DimValue(NbDim-1)-1);
        if DX==0
            DX=DXinit;
        end
        if DY==0
            DY=DYinit;
        end
        if NbDim==3
            DZ=(Coord{1}(end)-Coord{1}(1))/(DimValue(1)-1);
            if ~test_direct(1)
                DZ=-DZ;
            end
            Coord_z=linspace(Coord{1}(1),Coord{1}(end),DimValue(1));
            test_direct_z=test_direct(1);
        end
        npX=floor((XMax-XMin)/DX+1);
        npY=floor((YMax-YMin)/DY+1);   
        if test_direct_y
            coord_y_proj=linspace(YMin,YMax,npY);%abscissa of the new pixels along the line
        else
            coord_y_proj=linspace(YMax,YMin,npY);%abscissa of the new pixels along the line
        end
        if test_direct_x
            coord_x_proj=linspace(XMin,XMax,npX);%abscissa of the new pixels along the line
        else
            coord_x_proj=linspace(XMax,XMin,npX);%abscissa of the new pixels along the line
        end 
        
        % case with no rotation and interpolation
        if isequal(ProjMode,'projection') && isequal(Phi,0) && isequal(Theta,0) && isequal(Psi,0)
            if ~testXMin && ~testXMax && ~testYMin && ~testYMax && NbDim==2
                ProjData=FieldData; 
            else
                indY=NbDim-1;
                if test_direct(indY)
                    min_indy=ceil((YMin-Coord{indY}(1))/DYinit)+1;
                    YIndexFirst=floor((YMax-Coord{indY}(1))/DYinit)+1;
                    Ybound(1)=Coord{indY}(1)+DYinit*(min_indy-1);
                    Ybound(2)=Coord{indY}(1)+DYinit*(YIndexFirst-1);
                else
                    min_indy=ceil((Coord{indY}(1)-YMax)/DYinit)+1;
                    max_indy=floor((Coord{indY}(1)-YMin)/DYinit)+1;
                    Ybound(2)=Coord{indY}(1)-DYinit*(max_indy-1);
                    Ybound(1)=Coord{indY}(1)-DYinit*(min_indy-1);
                end   
                if test_direct(NbDim)==1
                    min_indx=ceil((XMin-Coord{NbDim}(1))/DXinit)+1;
                    max_indx=floor((XMax-Coord{NbDim}(1))/DXinit)+1;
                    Xbound(1)=Coord{NbDim}(1)+DXinit*(min_indx-1);
                    Xbound(2)=Coord{NbDim}(1)+DXinit*(max_indx-1);
                else
                    min_indx=ceil((Coord{NbDim}(1)-XMax)/DXinit)+1;
                    max_indx=floor((Coord{NbDim}(1)-XMin)/DXinit)+1;
                    Xbound(2)=Coord{NbDim}(1)+DXinit*(max_indx-1);
                    Xbound(1)=Coord{NbDim}(1)+DXinit*(min_indx-1);
                end 
                if NbDim==3
                    DimCell(1)=[]; %suppress z variable
                    DimValue(1)=[];
                                        %structured coordinates
                    if test_direct(1)
                        iz=ceil((ObjectData.Coord(1,3)-Coord{1}(1))/DZ)+1;
                    else
                        iz=ceil((Coord{1}(1)-ObjectData.Coord(1,3))/DZ)+1;
                    end
                end
                min_indy=max(min_indy,1);% deals with margin (bound lower than the first index)
                min_indx=max(min_indx,1);
                max_indy=min(max_indy,DimValue(1));
                max_indx=min(max_indx,DimValue(2));
                for ivar=VarIndex% loop on non coordinate variables
                    VarName=FieldData.ListVarName{ivar}; 
                    ProjData.ListVarName=[ProjData.ListVarName VarName];
                    ProjData.VarDimName=[ProjData.VarDimName {DimCell}];
                    if isfield(FieldData,'VarAttribute') && length(FieldData.VarAttribute)>=ivar
                        ProjData.VarAttribute{length(ProjData.ListVarName)}=FieldData.VarAttribute{ivar};
                    end
                    if NbDim==3
                        eval(['ProjData.' VarName '=squeeze(FieldData.' VarName '(iz,min_indy:max_indy,min_indx:max_indx));']);
                    else
                        eval(['ProjData.' VarName '=FieldData.' VarName '(min_indy:max_indy,min_indx:max_indx,:);']);
                    end
                end  
                eval(['ProjData.' AYName '=[Ybound(1) Ybound(2)];']) %record the new (projected ) y coordinates
                eval(['ProjData.' AXName '=[Xbound(1) Xbound(2)];']) %record the new (projected ) x coordinates
            end
        elseif isfield(FieldData,'A') %TO GENERALISE       % case with rotation and/or interpolation
            if NbDim==2 %2D case
                [X,Y]=meshgrid(coord_x_proj,coord_y_proj);%grid in the new coordinates
                XIMA=ObjectData.Coord(1,1)+(X)*cos(Phi)-Y*sin(Phi);%corresponding coordinates in the original image
                YIMA=ObjectData.Coord(1,2)+(X)*sin(Phi)+Y*cos(Phi);
                XIMA=(XIMA-minAX)/DXinit+1;% image index along x
                YIMA=(-YIMA+maxAY)/DYinit+1;% image index along y
                XIMA=reshape(round(XIMA),1,npX*npY);%indices reorganized in 'line'
                YIMA=reshape(round(YIMA),1,npX*npY);
                flagin=XIMA>=1 & XIMA<=DimValue(2) & YIMA >=1 & YIMA<=DimValue(1);%flagin=1 inside the original image 
                if isequal(ObjectData.ProjMode,'interp_tps')
                    npx_interp_tps=ceil(abs(DX/DAX));
                    npy_interp_tps=ceil(abs(DY/DAY));
                    Minterp_tps=ones(npy_interp_tps,npx_interp_tps)/(npx_interp_tps*npy_interp_tps);
                    test_interp_tps=1;
                else
                    test_interp_tps=0;
                end
                eval(['ProjData.' AYName '=[coord_y_proj(1) coord_y_proj(end)];']) %record the new (projected ) y coordinates
                eval(['ProjData.' AXName '=[coord_x_proj(1) coord_x_proj(end)];']) %record the new (projected ) x coordinates
                for ivar=VarIndex
                    VarName=FieldData.ListVarName{ivar};
                    if test_interp(1) || test_interp(2)%interpolate on a regular grid        
                          eval(['ProjData.' VarName '=interp2(Coord{2},Coord{1},FieldData.' VarName ',Coord_x,Coord_y'');']) %TO TEST
                    end
                    %filter the field (image) if option 'interp_tps' is used
                    if test_interp_tps  
                         Aclass=class(FieldData.A);
                         ProjData.(VarName)=interp_tps2(Minterp_tps,FieldData.(VarName),'valid');
                         if ~isequal(Aclass,'double')
                             ProjData.(VarName)=Aclass(FieldData.(VarName));%revert to integer values
                         end
                    end
                    eval(['vec_A=reshape(FieldData.' VarName ',[],nbcolor);'])%put the original image in line              
                    %ind_in=find(flagin);
                    ind_out=find(~flagin);
                    ICOMB=(XIMA-1)*DimValue(1)+YIMA;
                    ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
                    vec_B(flagin,1:nbcolor)=vec_A(ICOMB,:); 
                    for icolor=1:nbcolor
                        vec_B(ind_out,icolor)=zeros(size(ind_out));
                    end
                    ProjData.ListVarName=[ProjData.ListVarName VarName];
                    ProjData.VarDimName=[ProjData.VarDimName {DimCell}];
                    if isfield(FieldData,'VarAttribute')&&length(FieldData.VarAttribute)>=ivar
                        ProjData.VarAttribute{length(ProjData.ListVarName)+nbcoord}=FieldData.VarAttribute{ivar};
                    end     
                    eval(['ProjData.' VarName '=reshape(vec_B,npY,npX,nbcolor);']);
                end
                ProjData.FF=reshape(~flagin,npY,npX);%false flag A FAIRE: tenir compte d'un flga ant�rieur  
                ProjData.ListVarName=[ProjData.ListVarName 'FF'];
                ProjData.VarDimName=[ProjData.VarDimName {DimCell}];
                ProjData.VarAttribute{length(ProjData.ListVarName)}.Role='errorflag';
            else %3D case
                if ~testangle      
                    % unstructured z coordinate
                    test_sup=(Coord{1}>=ObjectData.Coord(1,3));
                    iz_sup=find(test_sup);
                    iz=iz_sup(1);
                    if iz>=1 & iz<=npz
                        %ProjData.ListDimName=[ProjData.ListDimName ListDimName(2:end)];
                        %ProjData.DimValue=[ProjData.DimValue npY npX];
                        for ivar=VarIndex
                            VarName=FieldData.ListVarName{ivar}; 
                            ProjData.ListVarName=[ProjData.ListVarName VarName];
                            ProjData.VarAttribute{length(ProjData.ListVarName)}=FieldData.VarAttribute{ivar}; %reproduce the variable attributes  
                            eval(['ProjData.' VarName '=squeeze(FieldData.' VarName '(iz,:,:));'])% select the z index iz
                            %TODO : do a vertical average for a thick plane
                            if test_interp(2) || test_interp(3)
                                eval(['ProjData.' VarName '=interp2(Coord{3},Coord{2},ProjData.' VarName ',Coord_x,Coord_y'');']) 
                            end
                        end
                    end
                else
                    errormsg='projection of structured coordinates on oblique plane not yet implemented';
                    %TODO: use interp3
                    return
                end
            end
        end
    end

    %% projection of  velocity components in the rotated coordinates
    if testangle
        if isempty(ivar_V)
            msgbox_uvmat('ERROR','v velocity component missing in proj_field.m')
            return
        end
        UName=FieldData.ListVarName{ivar_U};
        VName=FieldData.ListVarName{ivar_V};    
        eval(['ProjData.' UName  '=cos(Phi)*ProjData.' UName '+ sin(Phi)*ProjData.' VName ';'])
        eval(['ProjData.' VName  '=cos(Theta)*(-sin(Phi)*ProjData.' UName '+ cos(Phi)*ProjData.' VName ');'])
        if ~isempty(ivar_W)
            WName=FieldData.ListVarName{ivar_W};
            eval(['ProjData.' VName '=ProjData.' VName '+ ProjData.' WName '*sin(Theta);'])% 
            eval(['ProjData.' WName '=NormVec_X*ProjData.' UName '+ NormVec_Y*ProjData.' VName '+ NormVec_Z* ProjData.' WName ';']);
        end
        if ~isequal(Psi,0)
            eval(['ProjData.' UName '=cos(Psi)* ProjData.' UName '- sin(Psi)*ProjData.' VName ';']);
            eval(['ProjData.' VName '=sin(Psi)* ProjData.' UName '+ cos(Psi)*ProjData.' VName ';']);
        end
    end
end

%------------------------------------------------------------------------
%--- transfer the global attributes
function [ProjData,errormsg]=proj_heading(FieldData,ObjectData)
%------------------------------------------------------------------------
ProjData=[];%default
errormsg='';%default

%% transfer error 
if isfield(FieldData,'Txt')
    errormsg=FieldData.Txt; %transmit erreur message
    return;
end

%% transfer global attributes
if ~isfield(FieldData,'ListGlobalAttribute')
    ProjData.ListGlobalAttribute={};
else
    ProjData.ListGlobalAttribute=FieldData.ListGlobalAttribute;
end
for iattr=1:length(ProjData.ListGlobalAttribute)
    AttrName=ProjData.ListGlobalAttribute{iattr};
    if isfield(FieldData,AttrName)
        ProjData.(AttrName)=FieldData.(AttrName);
    end
end

%% transfer coordinate unit
if isfield(ProjData,'CoordUnit')
    ProjData=rmfield(ProjData,'CoordUnit');% do not transfer by default (to avoid x/y=1 for profiles)
end
if isfield(FieldData,'CoordUnit')
    if isfield(ObjectData,'CoordUnit') && ~strcmp(FieldData.CoordUnit,ObjectData.CoordUnit)
        errormsg=[ObjectData.Type ' in ' ObjectData.CoordUnit ' coordinates, while field in ' FieldData.CoordUnit ];
        return
    elseif strcmp(ObjectData.Type,'plane')|| strcmp(ObjectData.Type,'volume')
         ProjData.CoordUnit=FieldData.CoordUnit;
    end
end

%% store the properties of the projection object
ListObject={'Name','Type','ProjMode','angle','RangeX','RangeY','RangeZ','DX','DY','DZ','Coord'};
for ilist=1:length(ListObject)
    if isfield(ObjectData,ListObject{ilist})
        val=ObjectData.(ListObject{ilist});
        if ~isempty(val)
            ProjData.(['ProjObject' ListObject{ilist}])=val;
            ProjData.ListGlobalAttribute=[ProjData.ListGlobalAttribute {['ProjObject' ListObject{ilist}]}];
        end
    end   
end

