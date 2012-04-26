%'proj_field': projects the field on a projection object
%--------------------------------------------------------------------------
%  function [ProjData,errormsg]=proj_field(FieldData,ObjectData,FieldName)
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
%    .CoordType: 'px' or 'phys' type of coordinates of the field, must be the same as for the projection object, transmitted
%    .Mesh: typical distance between data points (used for mouse action or display), transmitted
%    .CoordUnit, .TimeUnit, .dt: transmitted
% standardised description of fields, nc-formated Matlab structure with fields:
%         .ListGlobalAttribute: cell listing the names of the global attributes
%        .Att_1,Att_2... : values of the global attributes
%            .ListVarName: cell listing the names of the variables
%           .VarAttribute: cell of structures s containing names and values of variable attributes (s.name=value) for each variable of .ListVarName
%        .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName
% The variables are grouped in 'fields', made of a set of variables with common dimensions (using the function find_field_indices)
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
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This file is part of the toolbox UVMAT.
% 
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function [ProjData,errormsg]=proj_field(FieldData,ObjectData,FieldName)
errormsg='';%default
if ~exist('FieldName','var')
    FieldName='';
end
%% case of no projection (object is used only as graph display)
if isfield(ObjectData,'ProjMode') && (isequal(ObjectData.ProjMode,'none')||isequal(ObjectData.ProjMode,'mask_inside')||isequal(ObjectData.ProjMode,'mask_outside'))
    if ~isempty(FieldName)
        [ProjData,errormsg]=calc_field(FieldName,FieldData);
    else
    ProjData=[];
    end
    return
end

%% in the absence of object Type or projection mode, or object coordinaes, the input field is just tranfered without change
if ~isfield(ObjectData,'Type')||~isfield(ObjectData,'ProjMode')
    ProjData=FieldData;
    return
end
if ~isfield(ObjectData,'Coord')
    if strcmp(ObjectData.Type,'plane')
        ObjectData.Coord=[0 0 0];%default
    else
        ProjData=FieldData;
        return
    end
end
        
%% OBSOLETE
if isfield(ObjectData,'XMax') && ~isempty(ObjectData.XMax)
    ObjectData.RangeX(1)=ObjectData.XMax;
end
if isfield(ObjectData,'XMin') && ~isempty(ObjectData.XMin)
    ObjectData.RangeX(2)=ObjectData.XMin;
end
if isfield(ObjectData,'YMax') && ~isempty(ObjectData.YMax)
    ObjectData.RangeY(1)=ObjectData.YMax;
end
if isfield(ObjectData,'YMin') && ~isempty(ObjectData.YMin)
    ObjectData.RangeY(2)=ObjectData.YMin;
end
if isfield(ObjectData,'ZMax') && ~isempty(ObjectData.ZMax)
    ObjectData.RangeZ(1)=ObjectData.ZMax;
end
if isfield(ObjectData,'ZMin') && ~isempty(ObjectData.ZMin)
    ObjectData.RangeZ(2)=ObjectData.ZMin;
end
%%%%%%%%%%

%% apply projection depending on the object type
switch ObjectData.Type
    case 'points'
    [ProjData,errormsg]=proj_points(FieldData,ObjectData);
    case {'line','polyline'}
     [ProjData,errormsg] = proj_line(FieldData,ObjectData);
    case {'polygon','rectangle','ellipse'}
        if isequal(ObjectData.ProjMode,'inside')||isequal(ObjectData.ProjMode,'outside')
            [ProjData,errormsg] = proj_patch(FieldData,ObjectData);
        else
            [ProjData,errormsg] = proj_line(FieldData,ObjectData);
        end
    case 'plane'
            [ProjData,errormsg] = proj_plane(FieldData,ObjectData,FieldName);
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
elseif  ~isequal(ObjectData.ProjMode,'interp')
    errormsg=(['ProjMode option ' ObjectData.ProjMode ' not available in proj_field']);
        return
end
[ProjData,errormsg]=proj_heading(FieldData,ObjectData);
ProjData.NbDim=0;
[CellVarIndex,NbDimCell,VarTypeCell,errormsg]=find_field_indices(FieldData);
if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_points:' errormsg];
    return
end
%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
for icell=1:length(CellVarIndex)
    if NbDimCell(icell)==1
        continue
    end
    VarIndex=CellVarIndex{icell};%  indices of the selected variables in the list FieldData.ListVarName
    VarType=VarTypeCell{icell};% structure defining the types of variables in the cell
    ivar_X=VarType.coord_x;
    ivar_Y=VarType.coord_y;
    ivar_Z=VarType.coord_z;
    ivar_Anc=VarType.ancillary;
    test_anc(ivar_Anc)=ones(size(ivar_Anc));
    ivar_F=VarType.warnflag;
    ivar_FF=VarType.errorflag;
    VarIndex([ivar_X ivar_Y ivar_Z ivar_Anc ivar_F ivar_FF])=[];% not projected variables removed frlom list
    if isempty(ivar_X)
        test_grid=1;%test for input data on regular grid (e.g. image)coordinates      
    else
        if length(ivar_X)>1 || length(ivar_Y)>1 || length(ivar_Z)>1
                 errormsg='multiple coordinate input in proj_field.m';
                    return
        end
        if length(ivar_Y)~=1
                errormsg='y coordinate not defined in proj_field.m';
                return
        end
        test_grid=0;
    end
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
    if ~test_grid
        eval(['coord_x=FieldData.' FieldData.ListVarName{ivar_X} ';'])
        eval(['coord_y=FieldData.' FieldData.ListVarName{ivar_Y} ';'])
        test3D=0;% TEST 3D CASE : NOT COMPLETED ,  3D CASE : NOT COMPLETED 
        if length(ivar_Z)==1
            eval(['coord_z=FieldData.' FieldData.ListVarName{ivar_Z} ';'])
            test3D=1;
        end
        if length(ivar_F)>1 || length(ivar_FF)>1 
                 msgbox_uvmat('ERROR','multiple flag input in proj_field.m')
                    return
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
                    if isequal(ObjectData.ProjMode,'interp')
                         ProjData.(VarName)(ipoint,1)=griddata_uvmat(coord_x(indsel),coord_y(indsel),Var,Xpoint(1),Xpoint(2));
                    end
               end
            end
        end
    else    %case of structured coordinates
        if  numel(VarType.coord)>=2 & VarType.coord(1:2) > 0;
            AYName=FieldData.ListVarName{VarType.coord(1)};
            AXName=FieldData.ListVarName{VarType.coord(2)};
            eval(['AX=FieldData.' AXName ';']);% set of x positions
            eval(['AY=FieldData.' AYName ';']);% set of y positions  
            AName=FieldData.ListVarName{VarIndex(1)};% a single variable assumed in the current cell
            eval(['A=FieldData.' AName ';']);% scalar
            npxy=size(A);        
            NbDim=numel(VarType.coord(VarType.coord>0));%number of space dimensions 
            %update VarDimName in case of components (non coordinate dimensions e;g. color components)
            if numel(npxy)>NbDim
                ProjData.VarDimName{end}={'nb_points','component'};
            end
            for idim=1:NbDim %loop on space dimensions
                test_interp(idim)=0;%test for coordiate interpolation (non regular grid), =0 by default
                test_coord(idim)=0;%test for defined coordinates, =0 by default
                ivar=VarType.coord(idim);
                Coord{idim}=FieldData.(FieldData.ListVarName{ivar}); % position for the first index
                if numel(Coord{idim})==2
                    DCoord_min(idim)= (Coord{idim}(2)-Coord{idim}(1))/(npxy(idim)-1);
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
function  [ProjData,errormsg]=proj_patch(FieldData,ObjectData)%%
%-------------------------------------------------------------------
[ProjData,errormsg]=proj_heading(FieldData,ObjectData);

objectfield=fieldnames(ObjectData);
widthx=0;
widthy=0;
if isfield(ObjectData,'RangeX')&~isempty(ObjectData.RangeX)
    widthx=max(ObjectData.RangeX);
end
if isfield(ObjectData,'RangeY')&~isempty(ObjectData.RangeY)
    widthy=max(ObjectData.RangeY);
end

%A REVOIR, GENERALISER: UTILISER proj_line
ProjData.NbDim=1;
ProjData.ListVarName={};
ProjData.VarDimName={};
ProjData.VarAttribute={};

Mesh=zeros(1,numel(FieldData.ListVarName));
if isfield (FieldData,'VarAttribute')
    %ProjData.VarAttribute=FieldData.VarAttribute;%list of variable attribute names
    for iattr=1:length(FieldData.VarAttribute)%initialization of variable attribute values
%         ProjData.VarAttribute{iattr}={};
        if isfield(FieldData.VarAttribute{iattr},'Unit')
            unit{iattr}=FieldData.VarAttribute{iattr}.Unit;
        end
        if isfield(FieldData.VarAttribute{iattr},'Mesh')
            Mesh(iattr)=FieldData.VarAttribute{iattr}.Mesh;
        end
    end
end

%group the variables (fields of 'FieldData') in cells of variables with the same dimensions
testfalse=0;
ListIndex={};
% DimVarIndex=0;%initilise list of indices for dimension variables
idimvar=0;
[CellVarIndex,NbDim,VarTypeCell,errormsg]=find_field_indices(FieldData);
if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_patch:' errormsg];
    return
end

%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
dimcounter=0;
for icell=1:length(CellVarIndex)
    testX=0;
    testY=0;
    test_Amat=0;
    testfalse=0;
    VarIndex=CellVarIndex{icell};%  indices of the selected variables in the list FieldData.ListVarName
    VarType=VarTypeCell{icell};
  %  DimIndices=FieldData.VarDimIndex{VarIndex(1)};%indices of the dimensions of the first variable (common to all variables in the cell)
    if NbDim(icell)~=2% proj_patch acts only on fields of space dimension 2
        continue
    end
    testX=~isempty(VarType.coord_x) && ~isempty(VarType.coord_y);
    testfalse=~isempty(VarType.errorflag);
    testproj(VarIndex)=zeros(size(VarIndex));%default
    testproj(VarType.scalar)=1;
    testproj(VarType.vector_x)=1;
    testproj(VarType.vector_y)=1;
    testproj(VarType.vector_z)=1;
    testproj(VarType.image)=1;
    testproj(VarType.color)=1;
    VarIndex=VarIndex(find(testproj(VarIndex)));%select only the projected variables
    if testX %case of unstructured coordinates
         eval(['nbpoint=numel(FieldData.' FieldData.ListVarName{VarIndex(1)} ');'])
         for ivar=[VarIndex VarType.coord_x VarType.coord_y VarType.errorflag]
               VarName=FieldData.ListVarName{ivar};
            eval(['FieldData.' VarName '=reshape(FieldData.' VarName ',nbpoint,1);'])
         end
         XName=FieldData.ListVarName{VarType.coord_x};
         YName=FieldData.ListVarName{VarType.coord_y};
         eval(['coord_x=FieldData.' XName ';'])
         eval(['coord_y=FieldData.' YName ';'])
    end
    if testfalse
        FFName=FieldData.ListVarName{VarType.errorflag};
        eval(['errorflag=FieldData.' FFName ';'])
    end
    % image or 2D matrix
    if numel(VarType.coord)>=2 & VarType.coord(1:2) > 0;
        test_Amat=1;% test for image or 2D matrix
        AYName=FieldData.ListVarName{VarType.coord(1)};
        AXName=FieldData.ListVarName{VarType.coord(2)};
        eval(['AX=FieldData.' AXName ';'])% x coordinate
        eval(['AY=FieldData.' AYName ';'])% y coordinate
        VarName=FieldData.ListVarName{VarIndex(1)};
        DimValue=size(FieldData.(VarName));
       if length(AX)==2
           AX=linspace(AX(1),AX(end),DimValue(2));
       end
       if length(AY)==2
           AY=linspace(AY(1),AY(end),DimValue(1));
       end
%         for idim=1:length(DimValue)        
%             Coord_i_str=['Coord_' num2str(idim)];
%             DCoord_min(idim)=1;%default
%             Coord{idim}=[0.5 DimValue(idim)];
%             test_direct(idim)=1;
%         end
%         AX=linspace(Coord{2}(1),Coord{2}(2),DimValue(2));
%         AY=linspace(Coord{1}(1),Coord{1}(2),DimValue(1));  %TODO : 3D case 
%         testcolor=find(numel(DimValue)==3);
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
%            if ~isfield(ObjectData,'RangeX')|~isfield(ObjectData,'RangeY')
%                 errormsg='rectangle half sides RangeX and RangeY needed'
%                 return
%            end
       if testX
            distX=abs(coord_x-ObjectData.Coord(1,1));
            distY=abs(coord_y-ObjectData.Coord(1,2));
            testin=distX<widthx & distY<widthy;
       elseif test_Amat
           distX=abs(Xi-ObjectData.Coord(1,1));
           distY=abs(Yi-ObjectData.Coord(1,2));
           testin=distX<widthx & distY<widthy;
       end
    elseif isequal(ObjectData.Type,'polygon')
        if testX
            testin=inpolygon(coord_x,coord_y,ObjectData.Coord(:,1),ObjectData.Coord(:,2));
        elseif test_Amat
           testin=inpolygon(Xi,Yi,ObjectData.Coord(:,1),ObjectData.Coord(:,2));
       else%calculate the scalar
           testin=[]; %A REVOIR
       end
    elseif isequal(ObjectData.Type,'ellipse')
       X2Max=widthx*widthx;
       Y2Max=(widthy)*(widthy);
       if testX
            distX=(coord_x-ObjectData.Coord(1,1));
            distY=(coord_y-ObjectData.Coord(1,2));
            testin=(distX.*distX/X2Max+distY.*distY/Y2Max)<1;
       elseif test_Amat %case of usual 2x2 matrix
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
    for ivar=VarIndex
        if testproj(ivar)
            VarName=FieldData.ListVarName{ivar};
            ProjData.([VarName 'Mean'])=mean(double(FieldData.(VarName)(indsel,:))); % take the mean in the selected region, for each color component 
            ProjData.([VarName 'Min'])=min(double(FieldData.(VarName)(indsel,:))); % take the min in the selected region , for each color component  
            ProjData.([VarName 'Max'])=max(double(FieldData.(VarName)(indsel,:))); % take the max in the selected region , for each color component
            if isequal(Mesh(ivar),0)
                eval(['[ProjData.' VarName 'Histo,ProjData.' VarName ']=hist(double(FieldData.' VarName '(indsel,:,:)),100);']); % default histogram with 100 bins
            else
                eval(['ProjData.' VarName '=(ProjData.' VarName 'Min+Mesh(ivar)/2:Mesh(ivar):ProjData.' VarName 'Max);']); % list of bin values
                eval(['ProjData.' VarName 'Histo=hist(double(FieldData.' VarName '(indsel,:)),ProjData.' VarName ');']); % histogram at predefined bin positions
            end
            ProjData.ListVarName=[ProjData.ListVarName {VarName} {[VarName 'Histo']} {[VarName 'Mean']} {[VarName 'Min']} {[VarName 'Max']}];
            if test_Amat && testcolor
                 ProjData.VarDimName=[ProjData.VarDimName  {VarName} {{VarName,'rgb'}} {'rgb'} {'rgb'} {'rgb'}];%{{'nb_point','rgb'}};
            else
               ProjData.VarDimName=[ProjData.VarDimName {VarName} {VarName} {'one'} {'one'} {'one'}];
            end
            ProjData.VarAttribute=[ProjData.VarAttribute FieldData.VarAttribute{ivar} {[]} {[]} {[]} {[]}];
        end
    end 
%     if test_Amat & testcolor
%        %ProjData.ListDimName=[ProjData.ListDimName {'rgb'}];
%       % ProjData.DimValue=[ProjData.DimValue 3];
%       % ProjData.VarDimIndex={[1 2]};
%        ProjData.VarDimName=[ProjData.VarDimName {VarName} {VarName,'rgb'}];%{{'nb_point','rgb'}};
%        ProjData.VarDimName
%     end
end


%-----------------------------------------------------------------
%project on a line
% AJOUTER flux,circul,error
function  [ProjData,errormsg] = proj_line(FieldData, ObjectData)
%-----------------------------------------------------------------
[ProjData,errormsg]=proj_heading(FieldData,ObjectData);%transfer global attributes
if ~isempty(errormsg)
    return
end
ProjData.NbDim=1;
%initialisation of the input parameters and defaultoutput
ProjMode='projection';%direct projection on the line by default
if isfield(ObjectData,'ProjMode'),ProjMode=ObjectData.ProjMode; end; 
% ProjAngle=90; %90 degrees projection by default
% if isfield(FieldData,'ProjAngle'),ProjAngle=ObjectData.ProjAngle; end; 
width=0;%default width of the projection band
if isfield(ObjectData,'Range')&&size(ObjectData.Range,2)>=2
    width=abs(ObjectData.Range(1,2));
end
if isfield(ObjectData,'RangeY')
    width=max(ObjectData.RangeY);
end

% default output
errormsg=[];%default
Xline=[];
flux=0;
circul=0;
liny=ObjectData.Coord(:,2);
siz_line=size(ObjectData.Coord);
if siz_line(1)<2
    return% line needs at least 2 points to be defined
end
testfalse=0;
ListIndex={};

%angles of the polyline and boundaries of action
dlinx=diff(ObjectData.Coord(:,1));
dliny=diff(ObjectData.Coord(:,2));
theta=angle(dlinx+i*dliny);%angle of each segment
theta(siz_line(1))=theta(siz_line(1)-1);
% determine a rectangles at +-width from the line (only used for the ProjMode='projection or 'filter')
if isequal(ProjMode,'projection') || isequal(ProjMode,'filter')
    xsup(1)=ObjectData.Coord(1,1)-width*sin(theta(1));
    xinf(1)=ObjectData.Coord(1,1)+width*sin(theta(1));
    ysup(1)=ObjectData.Coord(1,2)+width*cos(theta(1));
    yinf(1)=ObjectData.Coord(1,2)-width*cos(theta(1));
    for ip=2:siz_line(1)
        xsup(ip)=ObjectData.Coord(ip,1)-width*sin((theta(ip)+theta(ip-1))/2)/cos((theta(ip-1)-theta(ip))/2);
        xinf(ip)=ObjectData.Coord(ip,1)+width*sin((theta(ip)+theta(ip-1))/2)/cos((theta(ip-1)-theta(ip))/2);
        ysup(ip)=ObjectData.Coord(ip,2)+width*cos((theta(ip)+theta(ip-1))/2)/cos((theta(ip-1)-theta(ip))/2);
        yinf(ip)=ObjectData.Coord(ip,2)-width*cos((theta(ip)+theta(ip-1))/2)/cos((theta(ip-1)-theta(ip))/2);
    end
end

%group the variables (fields of 'FieldData') in cells of variables with the same dimensions
[CellVarIndex,NbDim,VarTypeCell,errormsg]=find_field_indices(FieldData);
if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_line:' errormsg];
    return
end

% loop on variable cells with the same space dimension
ProjData.ListVarName={};
ProjData.VarDimName={};
for icell=1:length(CellVarIndex)
    VarIndex=CellVarIndex{icell};%  indices of the selected variables in the list FieldData.ListVarName
    VarType=VarTypeCell{icell}; %types of variables
    if NbDim(icell)~=2% proj_line acts only on fields of space dimension 2, TODO: check 3D case
        continue
    end
    testX=~isempty(VarType.coord_x) && ~isempty(VarType.coord_y);% test for unstructured coordinates
    testU=~isempty(VarType.vector_x) && ~isempty(VarType.vector_y);% test for vectors
    testfalse=~isempty(VarType.errorflag);% test for error flag
    testproj(VarIndex)=zeros(size(VarIndex));% test =1 for simply projected variables, default =0
                                             %=0 for vector components, treated separately
    testproj(VarType.scalar)=1;
    testproj(VarType.image)=1;
    testproj(VarType.color)=1;
    VarIndex=VarIndex(find(testproj(VarIndex)));%select only the projected variables
    if testU
         VarIndex=[VarIndex VarType.vector_x VarType.vector_y];%append u and v at the end of the list of variables
    end
    %identify vector components   
    if testU
        UName=FieldData.ListVarName{VarType.vector_x};
        VName=FieldData.ListVarName{VarType.vector_y};
        eval(['vector_x=FieldData.' UName ';'])
        eval(['vector_y=FieldData.' VName ';'])
    end  
    %identify error flag
    if testfalse
        FFName=FieldData.ListVarName{VarType.errorflag};
        eval(['errorflag=FieldData.' FFName ';'])
    end   
    % check needed object properties for unstructured positions (position given by the variables with role coord_x, coord_y
    if testX
        if  ~isequal(ProjMode,'interp')
            if width==0
                errormsg='range of the projection object is missing';
                return      
            else
                lambda=2/(width*width); %smoothing factor used for filter: weight exp(-2) at distance width from the line
            end
        end
        if ~isequal(ProjMode,'projection')
            if isfield(ObjectData,'DX')&~isempty(ObjectData.DX)
                DX=abs(ObjectData.DX);%mesh of interpolation points along the line
            else
                errormsg='DX missing';
                return
            end
        end
        XName= FieldData.ListVarName{VarType.coord_x};
        YName= FieldData.ListVarName{VarType.coord_y};
        eval(['coord_x=FieldData.' XName ';'])    
        eval(['coord_y=FieldData.' YName ';'])
    end   
    %initiate projection
    for ivar=1:length(VarIndex)
        ProjLine{ivar}=[];
    end
    XLine=[];
    linelengthtot=0;

%         circul=0;
%         flux=0;
  %%%%%%%  % A FAIRE CALCULER MEAN DES QUANTITES    %%%%%%
   %case of unstructured coordinates
    if testX   
        for ip=1:siz_line(1)-1     %Loop on the segments of the polyline
            linelength=sqrt(dlinx(ip)*dlinx(ip)+dliny(ip)*dliny(ip));  
            %select the vector indices in the range of action
            if testfalse
                flagsel=(errorflag==0); % keep only non false vectors
            else
                flagsel=ones(size(coord_x));
            end
            if isequal(ProjMode,'projection') | isequal(ProjMode,'filter')
                flagsel=flagsel & ((coord_y -yinf(ip))*(xinf(ip+1)-xinf(ip))>(coord_x-xinf(ip))*(yinf(ip+1)-yinf(ip))) ...
                & ((coord_y -ysup(ip))*(xsup(ip+1)-xsup(ip))<(coord_x-xsup(ip))*(ysup(ip+1)-ysup(ip))) ...
                & ((coord_y -yinf(ip+1))*(xsup(ip+1)-xinf(ip+1))>(coord_x-xinf(ip+1))*(ysup(ip+1)-yinf(ip+1))) ...
                & ((coord_y -yinf(ip))*(xsup(ip)-xinf(ip))<(coord_x-xinf(ip))*(ysup(ip)-yinf(ip)));
            end
            indsel=find(flagsel);%indsel =indices of good vectors 
            X_sel=coord_x(indsel);
            Y_sel=coord_y(indsel);
            nbvar=0;
            for iselect=1:numel(VarIndex)-2*testU
                VarName=FieldData.ListVarName{VarIndex(iselect)};
                eval(['ProjVar{iselect}=FieldData.' VarName '(indsel);']);%scalar value
            end   
            if testU
                ProjVar{numel(VarIndex)-1}=cos(theta(ip))*vector_x(indsel)+sin(theta(ip))*vector_y(indsel);% longitudinal component
                ProjVar{numel(VarIndex)}=-sin(theta(ip))*vector_x(indsel)+cos(theta(ip))*vector_y(indsel);%transverse component         
            end
            if isequal(ProjMode,'projection')
                sintheta=sin(theta(ip));
                costheta=cos(theta(ip));
                Xproj=(X_sel-ObjectData.Coord(ip,1))*costheta + (Y_sel-ObjectData.Coord(ip,2))*sintheta; %projection on the line
                [Xproj,indsort]=sort(Xproj);
                for ivar=1:numel(ProjVar)
                    if ~isempty(ProjVar{ivar})
                        ProjVar{ivar}=ProjVar{ivar}(indsort);
                     end
                end
            elseif isequal(ProjMode,'interp') %linear interpolation:
                npoint=floor(linelength/DX)+1;% nbre of points in the profile (interval DX)
                Xproj=linelength/(2*npoint):linelength/npoint:linelength-linelength/(2*npoint);
                xreg=cos(theta(ip))*Xproj+ObjectData.Coord(ip,1);
                yreg=sin(theta(ip))*Xproj+ObjectData.Coord(ip,2);
                for ivar=1:numel(ProjVar)
                     if ~isempty(ProjVar{ivar})
                        ProjVar{ivar}=griddata_uvmat(X_sel,Y_sel,ProjVar{ivar},xreg,yreg);
                     end
                end
            elseif isequal(ProjMode,'filter') %filtering
                npoint=floor(linelength/DX)+1;% nbre of points in the profile (interval DX)
                Xproj=linelength/(2*npoint):linelength/npoint:linelength-linelength/(2*npoint);
                siz=size(X_sel);
                xregij=cos(theta(ip))*ones(siz(1),1)*Xproj+ObjectData.Coord(ip,1);
                yregij=sin(theta(ip))*ones(siz(1),1)*Xproj+ObjectData.Coord(ip,2);
                xij=X_sel*ones(1,npoint);
                yij=Y_sel*ones(1,npoint);
                Aij=exp(-lambda*((xij-xregij).*(xij-xregij)+(yij-yregij).*(yij-yregij)));
                norm=Aij'*ones(siz(1),1);
                for ivar=1:numel(ProjVar)
                     if ~isempty(ProjVar{ivar})
                        ProjVar{ivar}=Aij'*ProjVar{ivar}./norm;
                     end
                end              
            end
            %prolongate the total record
            for ivar=1:numel(ProjVar)
                  if ~isempty(ProjVar{ivar})
                     ProjLine{ivar}=[ProjLine{ivar}; ProjVar{ivar}];
                  end
            end
            XLine=[XLine ;(Xproj+linelengthtot)];%along line abscissa
            linelengthtot=linelengthtot+linelength;
            %     circul=circul+(sum(U_sel))*linelength/npoint;
            %     flux=flux+(sum(V_sel))*linelength/npoint;
        end
        ProjData.X=XLine';
        cur_index=1;
        ProjData.ListVarName=[ProjData.ListVarName {XName}];
        ProjData.VarDimName=[ProjData.VarDimName {XName}];
        ProjData.VarAttribute{1}.long_name='abscissa along line';
        for iselect=1:numel(VarIndex)
            VarName=FieldData.ListVarName{VarIndex(iselect)};
            eval(['ProjData.' VarName '=ProjLine{iselect};'])
            ProjData.ListVarName=[ProjData.ListVarName {VarName}];
            ProjData.VarDimName=[ProjData.VarDimName {XName}];
            ProjData.VarAttribute{iselect}=FieldData.VarAttribute{VarIndex(iselect)};
            if strcmp(ProjMode,'projection')
                ProjData.VarAttribute{iselect}.Role='discrete';
            else
                 ProjData.VarAttribute{iselect}.Role='continuous';
            end
        end
    
    %case of structured coordinates
    elseif  numel(VarType.coord)>=2 & VarType.coord(1:2) > 0;
        if ~isequal(ObjectData.Type,'line')% exclude polyline
            errormsg=['no  projection available on ' ObjectData.Type 'for structured coordinates']; % 
        else
            test_Amat=1;%image or 2D matrix
            test_interp2=0;%default
%             if ~isempty(VarType.coord_y)  
            AYName=FieldData.ListVarName{VarType.coord(1)};
            AXName=FieldData.ListVarName{VarType.coord(2)};
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
                VarName{ivar}=FieldData.ListVarName{ivar};
                if test_interp2% interpolate on new grid
                    eval(['FieldData.' VarName{ivar} '=interp2(FieldData.' AXName ',FieldData.' AYName ',FieldData.' VarName{ivar} ',AXI,AYI'');']) %TO TEST
                end
                eval(['vec_A=reshape(squeeze(FieldData.' VarName{ivar} '),npx*npy,nbcolor);']) %put the original image in colum
                if nbcolor==1
                    vec_B(ind_in)=vec_A(ICOMB);
                    vec_B(ind_out)=zeros(size(ind_out));
                    A_out=reshape(vec_B,npY,npX);
                    eval(['ProjData.' VarName{ivar} '=((sum(A_out,1)/npY))'';']);
                elseif nbcolor==3
                    vec_B(ind_in,1:3)=vec_A(ICOMB,:);
                    vec_B(ind_out,1)=zeros(size(ind_out));
                    vec_B(ind_out,2)=zeros(size(ind_out));
                    vec_B(ind_out,3)=zeros(size(ind_out));
                    A_out=reshape(vec_B,npY,npX,nbcolor);
                    eval(['ProjData.' VarName{ivar} '=squeeze(sum(A_out,1)/npY);']);
                end  
                ProjData.ListVarName=[ProjData.ListVarName VarName{ivar} ];
                ProjData.VarDimName=[ProjData.VarDimName {AXName}];%to generalize with the initial name of the x coordinate
                ProjData.VarAttribute{ivar}.Role='continuous';% for plot with continuous line
            end
            if testU
                 eval(['vector_x =ProjData.' VarName{VarType.vector_x} ';'])
                 eval(['vector_y =ProjData.' VarName{VarType.vector_y} ';'])
                 eval(['ProjData.' VarName{VarType.vector_x} '=cos(theta)*vector_x+sin(theta)*vector_y;'])
                 eval(['ProjData.' VarName{VarType.vector_y} '=-sin(theta)*vector_x+cos(theta)*vector_y;'])
            end
            ProjData.VarAttribute{nbvar+1}.long_name='abscissa along line';
            if nbcolor==3
                ProjData.VarDimName{end}={AXName,'rgb'};
            end
        end      
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
 function  [ProjData,errormsg] = proj_plane(FieldData, ObjectData,FieldName)
%-----------------------------------------------------------------

%% initialisation of the input parameters of the projection plane
ProjMode='projection';%direct projection by default
if isfield(ObjectData,'ProjMode'),ProjMode=ObjectData.ProjMode; end;

%% axis origin
if isempty(ObjectData.Coord)
    ObjectData.Coord(1,1)=0;%origin of the plane set to [0 0] by default
    ObjectData.Coord(1,2)=0;
    ObjectData.Coord(1,3)=0;
end

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
testangle=~isequal(PlaneAngle,[0 0 0]);% && ~test90y && ~test90x;%=1 for slanted plane 

%% mesh sizes DX and DY
DX=0;
DY=0; %default 
if isfield(ObjectData,'DX') && ~isempty(ObjectData.DX)
     DX=abs(ObjectData.DX);%mesh of interpolation points 
end
if isfield(ObjectData,'DY') && ~isempty(ObjectData.DY)
     DY=abs(ObjectData.DY);%mesh of interpolation points 
end
if  ~strcmp(ProjMode,'projection') && (DX==0||DY==0)
        errormsg='DX or DY missing';
        display(errormsg)
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
        width=max(ObjectData.RangeZ);
end

%% initiate Matlab  structure for physical field
[ProjData,errormsg]=proj_heading(FieldData,ObjectData);
ProjData.NbDim=2;
ProjData.ListVarName={};
ProjData.VarDimName={};
if ~isequal(DX,0)&& ~isequal(DY,0)
    ProjData.Mesh=sqrt(DX*DY);%define typical data mesh, useful for mouse selection in plots
elseif isfield(FieldData,'Mesh')
    ProjData.Mesh=FieldData.Mesh;
end
error=0;%default
flux=0;
testfalse=0;
ListIndex={};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% group the variables (fields of 'FieldData') in cells of variables with the same dimensions
%-----------------------------------------------------------------
idimvar=0;

[CellVarIndex,NbDimVec,VarTypeCell,errormsg]=find_field_indices(FieldData);
if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_plane:' errormsg];
    return
end

% LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
% CellVarIndex=cells of variable index arrays
ivar_new=0; % index of the current variable in the projected field
icoord=0;
nbcoord=0;%number of added coordinate variables brought by projection
nbvar=0;
for icell=1:length(CellVarIndex)
    NbDim=NbDimVec(icell);
    if NbDim<2
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
    testX=~isempty(ivar_X) && ~isempty(ivar_Y);
    DimCell=FieldData.VarDimName{VarIndex(1)};
    if ischar(DimCell)
        DimCell={DimCell};%name of dimensions
    end
    
    %% case of input fields with unstructured coordinates
    coord_z=0;%default
    if testX
        XName=FieldData.ListVarName{ivar_X};
        YName=FieldData.ListVarName{ivar_Y};
        coord_x=FieldData.(XName);
        coord_y=FieldData.(YName);
        if length(ivar_Z)==1
            ZName=FieldData.ListVarName{ivar_Z};
            coord_z=FieldData.(ZName);
        end
        
        % translate  initial coordinates
        coord_x=coord_x-ObjectData.Coord(1,1);
        coord_y=coord_y-ObjectData.Coord(1,2);
        if ~isempty(ivar_Z)
            coord_z=coord_z-ObjectData.Coord(1,3);
        end
        
        % selection of the vectors in the projection range (3D case)
        if length(ivar_Z)==1 &&  width > 0
            %components of the unitiy vector normal to the projection plane
            fieldZ=norm_plane(1)*coord_x + norm_plane(2)*coord_y+ norm_plane(3)*coord_z;% distance to the plane
            indcut=find(abs(fieldZ) <= width);
            size(indcut)
            for ivar=VarIndex
                VarName=FieldData.ListVarName{ivar};
                eval(['FieldData.' VarName '=FieldData.' VarName '(indcut);'])
                % A VOIR : CAS DE VAR STRUCTUREE MAIS PAS GRILLE REGULIERE : INTERPOLER SUR GRILLE REGULIERE
            end
            coord_x=coord_x(indcut);
            coord_y=coord_y(indcut);
            coord_z=coord_z(indcut);
        end
        
        %rotate coordinates if needed: 
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
        if testYMin
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
        if isequal(ObjectData.ProjMode,'projection')
            %the list of dimension
            %ProjData.ListDimName=[ProjData.ListDimName FieldData.VarDimName(VarIndex(1))];%add the point index to the list of dimensions
            %ProjData.DimValue=[ProjData.
            %length(coord_X)];
            
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
        elseif isequal(ObjectData.ProjMode,'interp')||isequal(ObjectData.ProjMode,'filter')%interpolate data on a regular grid
            if isequal(ObjectData.ProjMode,'filter')
                rho=1000;%smoothing parameter, (small for strong smoothing)
            else
                rho=0;
            end
            coord_x_proj=XMin:DX:XMax;
            coord_y_proj=YMin:DY:YMax;
            if isfield(FieldData,[VarName '_tps'])
                [XI,YI]=meshgrid(coord_x_proj,coord_y_proj');
                XI=reshape(XI,[],1);
                YI=reshape(YI,[],1);         
            end
            DimCell={'coord_y','coord_x'};
            ProjData.ListVarName={'coord_y','coord_x'};
            ProjData.VarDimName={'coord_y','coord_x'};
            nbcoord=2;
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
            FieldName
            if ~isempty(FieldName)
                ProjData=calc_field(FieldName,FieldData,[XI YI]);
            else
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
                            FieldData.(VarName)=FieldData.(VarName)(indsel);
                        end
                        %                     if isfield(FieldData,[VarName '_tps'])
                        %                         [XI,YI]=meshgrid(coord_x_proj,coord_y_proj');
                        %                         XI=reshape(XI,[],1);
                        %                         YI=reshape(YI,[],1);
                        %
                        ProjData.(VarName)=griddata_uvmat(double(coord_X),double(coord_Y),double(FieldData.(VarName)),coord_x_proj,coord_y_proj',rho);
                        varline=reshape(ProjData.(VarName),1,length(coord_y_proj)*length(coord_x_proj));
                        FFlag= isnan(varline); %detect undefined values NaN
                        indnan=find(FFlag);
                        if~isempty(indnan)
                            varline(indnan)=zeros(size(indnan));
                            ProjData.(VarName)=reshape(varline,length(coord_y_proj),length(coord_x_proj));
                            FF(indnan)=ones(size(indnan));
                            testFF=1;
                        end
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
        if testangle% TODO modify name also in case of origin shift in x or y
            AYProjName='Y';
            AXProjName='X';
            count=0;
            %modify coordinate names if they are already used
            while ~(isempty(find(strcmp('AXName',ProjData.ListVarName),1)) && isempty(find(strcmp('AYName',ProjData.ListVarName),1)))
                count=count+1;
                AYProjName=[AYProjName '_' num2str(count)];
                AXProjName=[AXProjName '_' num2str(count)];
            end
        else
            AYProjName=AYName;% (name preserved on projection)
            AXProjName=AXName;%name of input y coordinate (name preserved on projection)
        end
        ListDimName=FieldData.VarDimName{VarIndex(1)};
        ProjData.ListVarName=[ProjData.ListVarName {AYProjName} {AXProjName}]; %TODO: check if it already exists in Projdata (several cells)
        ProjData.VarDimName=[ProjData.VarDimName {AYProjName} {AXProjName}];
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
        xcor_new=xcorner*cos_om+ycorner*sin_om;%coord new frame
        ycor_new=-xcorner*sin_om+ycorner*cos_om;
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
        % case with no  interpolation
        if isequal(ProjMode,'projection') && (~testangle || test90y || test90x)
            if  NbDim==2 && ~testXMin && ~testXMax && ~testYMin && ~testYMax 
                ProjData=FieldData;% no change by projection
            else
                indY=NbDim-1;
                if test_direct(indY)
                    min_indy=ceil((YMin-Coord{indY}(1))/DYinit)+1;
                    max_indy=floor((YMax-Coord{indY}(1))/DYinit)+1;
                    Ybound(1)=Coord{indY}(1)+DYinit*(min_indy-1);
                    Ybound(2)=Coord{indY}(1)+DYinit*(max_indy-1);
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
                min_indy=max(min_indy,1);% deals with margin (bound lower than the first index)
                min_indx=max(min_indx,1);

                if test90y
                    ind_new=[3 2 1];
                    DimCell={AYProjName,AXProjName};
%                     DimValue=DimValue(ind_new);
                    iz=ceil((ObjectData.Coord(1,1)-Coord{3}(1))/DX)+1;
                    for ivar=VarIndex
                        VarName=FieldData.ListVarName{ivar};
                        ProjData.ListVarName=[ProjData.ListVarName VarName];
                        ProjData.VarDimName=[ProjData.VarDimName {DimCell}];
                        ProjData.VarAttribute{length(ProjData.ListVarName)}=FieldData.VarAttribute{ivar}; %reproduce the variable attributes
                        eval(['ProjData.' VarName '=permute(FieldData.' VarName ',ind_new);'])% permute x and z indices for 90 degree rotation
                        eval(['ProjData.' VarName '=squeeze(ProjData.' VarName '(iz,:,:));'])% select the z index iz
                    end
                    eval(['ProjData.' AYProjName '=[Ybound(1) Ybound(2)];']) %record the new (projected ) y coordinates
                    eval(['ProjData.' AXProjName '=[Coord{1}(end),Coord{1}(1)];']) %record the new (projected ) x coordinates
                else
                    if NbDim==3
                        DimCell(1)=[]; %suppress z variable
                        DimValue(1)=[];
                        if test_direct(1)
                            iz=ceil((ObjectData.Coord(1,3)-Coord{1}(1))/DZ)+1;
                        else
                            iz=ceil((Coord{1}(1)-ObjectData.Coord(1,3))/DZ)+1;
                        end
                    end
                    max_indy=min(max_indy,DimValue(1));%introduce bounds in y and x indices
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
                    eval(['ProjData.' AYProjName '=[Ybound(1) Ybound(2)];']) %record the new (projected ) y coordinates
                    eval(['ProjData.' AXProjName '=[Xbound(1) Xbound(2)];']) %record the new (projected ) x coordinates
                end
            end
        else       % case with rotation and/or interpolation
            if NbDim==2 %2D case
                [X,Y]=meshgrid(coord_x_proj,coord_y_proj);%grid in the new coordinates
                XIMA=ObjectData.Coord(1,1)+(X)*cos(PlaneAngle(3))-Y*sin(PlaneAngle(3));%corresponding coordinates in the original image
                YIMA=ObjectData.Coord(1,2)+(X)*sin(PlaneAngle(3))+Y*cos(PlaneAngle(3));
                XIMA=(XIMA-minAX)/DXinit+1;% image index along x
                YIMA=(-YIMA+maxAY)/DYinit+1;% image index along y
                XIMA=reshape(round(XIMA),1,npX*npY);%indices reorganized in 'line'
                YIMA=reshape(round(YIMA),1,npX*npY);
                flagin=XIMA>=1 & XIMA<=DimValue(2) & YIMA >=1 & YIMA<=DimValue(1);%flagin=1 inside the original image
                if isequal(ObjectData.ProjMode,'filter')
                    npx_filter=ceil(abs(DX/DAX));
                    npy_filter=ceil(abs(DY/DAY));
                    Mfilter=ones(npy_filter,npx_filter)/(npx_filter*npy_filter);
                    test_filter=1;
                else
                    test_filter=0;
                end
                eval(['ProjData.' AYName '=[coord_y_proj(1) coord_y_proj(end)];']) %record the new (projected ) y coordinates
                eval(['ProjData.' AXName '=[coord_x_proj(1) coord_x_proj(end)];']) %record the new (projected ) x coordinates
                for ivar=VarIndex
                    VarName=FieldData.ListVarName{ivar};
                    if test_interp(1) || test_interp(2)%interpolate on a regular grid
                        eval(['ProjData.' VarName '=interp2(Coord{2},Coord{1},FieldData.' VarName ',Coord_x,Coord_y'');']) %TO TEST
                    end
                    %filter the field (image) if option 'filter' is used
                    if test_filter
                        Aclass=class(FieldData.A);
                        eval(['ProjData.' VarName '=filter2(Mfilter,FieldData.' VarName ',''valid'');'])
                        if ~isequal(Aclass,'double')
                            eval(['ProjData.' VarName '=' Aclass '(FieldData.' VarName ');'])%revert to integer values
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
                ProjData.FF=reshape(~flagin,npY,npX);%false flag A FAIRE: tenir compte d'un flga antérieur
                ProjData.ListVarName=[ProjData.ListVarName 'FF'];
                ProjData.VarDimName=[ProjData.VarDimName {DimCell}];
                ProjData.VarAttribute{length(ProjData.ListVarName)}.Role='errorflag';
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
    
    %% projection of  velocity components in the rotated coordinates
    if testangle && length(ivar_U)==1
        if isempty(ivar_V)
            msgbox_uvmat('ERROR','v velocity component missing in proj_field.m')
            return
        end
        UName=FieldData.ListVarName{ivar_U};
        VName=FieldData.ListVarName{ivar_V};
        eval(['ProjData.' UName  '=cos(PlaneAngle(3))*ProjData.' UName '+ sin(PlaneAngle(3))*ProjData.' VName ';'])
        eval(['ProjData.' VName  '=cos(Theta)*(-sin(PlaneAngle(3))*ProjData.' UName '+ cos(PlaneAngle(3))*ProjData.' VName ');'])
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

%-----------------------------------------------------------------
%projection in a volume 
 function  [ProjData,errormsg] = proj_volume(FieldData, ObjectData)
%-----------------------------------------------------------------
ProjData=FieldData;%default output

%% initialisation of the input parameters of the projection plane
ProjMode='projection';%direct projection by default
if isfield(ObjectData,'ProjMode'),ProjMode=ObjectData.ProjMode; end;

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
ProjData.NbDim=3;
ProjData.ListVarName={};
ProjData.VarDimName={};
if ~isequal(DX,0)&& ~isequal(DY,0)
    ProjData.Mesh=sqrt(DX*DY);%define typical data mesh, useful for mouse selection in plots
elseif isfield(FieldData,'Mesh')
    ProjData.Mesh=FieldData.Mesh;
end

error=0;%default
flux=0;
testfalse=0;
ListIndex={};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% group the variables (fields of 'FieldData') in cells of variables with the same dimensions
%-----------------------------------------------------------------
idimvar=0;
[CellVarIndex,NbDimVec,VarTypeCell,errormsg]=find_field_indices(FieldData);
if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_plane:' errormsg];
    return
end

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
    testX=~isempty(ivar_X) && ~isempty(ivar_Y);
    DimCell=FieldData.VarDimName{VarIndex(1)};
    if ischar(DimCell)
        DimCell={DimCell};%name of dimensions
    end

%% case of input fields with unstructured coordinates
    if testX
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
        elseif isequal(ObjectData.ProjMode,'interp')||isequal(ObjectData.ProjMode,'filter')%interpolate data on a regular grid
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
                    eval(['InterpFct=TriScatteredInterp(double(coord_X),double(coord_Y),double(coord_Z),double(FieldData.' VarName '))'])
                    eval(['ProjData.' VarName '=InterpFct(X,Y,Z);'])
%                     eval(['varline=reshape(ProjData.' VarName ',1,length(coord_y_proj)*length(coord_x_proj));'])
%                     FFlag= isnan(varline); %detect undefined values NaN
%                     indnan=find(FFlag);
%                     if~isempty(indnan)
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
                    max_indy=floor((YMax-Coord{indY}(1))/DYinit)+1;
                    Ybound(1)=Coord{indY}(1)+DYinit*(min_indy-1);
                    Ybound(2)=Coord{indY}(1)+DYinit*(max_indy-1);
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
        else       % case with rotation and/or interpolation
            if NbDim==2 %2D case
                [X,Y]=meshgrid(coord_x_proj,coord_y_proj);%grid in the new coordinates
                XIMA=ObjectData.Coord(1,1)+(X)*cos(Phi)-Y*sin(Phi);%corresponding coordinates in the original image
                YIMA=ObjectData.Coord(1,2)+(X)*sin(Phi)+Y*cos(Phi);
                XIMA=(XIMA-minAX)/DXinit+1;% image index along x
                YIMA=(-YIMA+maxAY)/DYinit+1;% image index along y
                XIMA=reshape(round(XIMA),1,npX*npY);%indices reorganized in 'line'
                YIMA=reshape(round(YIMA),1,npX*npY);
                flagin=XIMA>=1 & XIMA<=DimValue(2) & YIMA >=1 & YIMA<=DimValue(1);%flagin=1 inside the original image 
                if isequal(ObjectData.ProjMode,'filter')
                    npx_filter=ceil(abs(DX/DAX));
                    npy_filter=ceil(abs(DY/DAY));
                    Mfilter=ones(npy_filter,npx_filter)/(npx_filter*npy_filter);
                    test_filter=1;
                else
                    test_filter=0;
                end
                eval(['ProjData.' AYName '=[coord_y_proj(1) coord_y_proj(end)];']) %record the new (projected ) y coordinates
                eval(['ProjData.' AXName '=[coord_x_proj(1) coord_x_proj(end)];']) %record the new (projected ) x coordinates
                for ivar=VarIndex
                    VarName=FieldData.ListVarName{ivar};
                    if test_interp(1) || test_interp(2)%interpolate on a regular grid        
                          eval(['ProjData.' VarName '=interp2(Coord{2},Coord{1},FieldData.' VarName ',Coord_x,Coord_y'');']) %TO TEST
                    end
                    %filter the field (image) if option 'filter' is used
                    if test_filter  
                         Aclass=class(FieldData.A);
                         eval(['ProjData.' VarName '=filter2(Mfilter,FieldData.' VarName ',''valid'');'])
                         if ~isequal(Aclass,'double')
                             eval(['ProjData.' VarName '=' Aclass '(FieldData.' VarName ');'])%revert to integer values
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
                ProjData.FF=reshape(~flagin,npY,npX);%false flag A FAIRE: tenir compte d'un flga antérieur  
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
        eval(['ProjData.' AttrName '=FieldData.' AttrName ';']);
    end
end

%% transfer coordinate unit
if isfield(FieldData,'CoordUnit')
    if isfield(ObjectData,'CoordUnit') && ~strcmp(FieldData.CoordUnit,ObjectData.CoordUnit)
        errormsg=[ObjectData.Type ' in ' ObjectData.CoordUnit ' coordinates, while field in ' FieldData.CoordUnit ];
        return
    else
         ProjData.CoordUnit=FieldData.CoordUnit;
    end
end

%% store the properties of the projection object
ListObject={'Type','ProjMode','RangeX','RangeY','RangeZ','Phi','Theta','Psi','Coord'};
for ilist=1:length(ListObject)
    if isfield(ObjectData,ListObject{ilist})
        eval(['val=ObjectData.' ListObject{ilist} ';'])
        if ~isempty(val)
            eval(['ProjData.Object' ListObject{ilist} '=val;']);
            ProjData.ListGlobalAttribute=[ProjData.ListGlobalAttribute {['Object' ListObject{ilist}]}];
        end
    end   
end
