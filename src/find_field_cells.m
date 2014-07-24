%'find_field_cells': analyse the field structure for input in uvmat functions, grouping the variables  into 'fields' with common coordinates
%------------------------------------------------------------------------
% function  [CellInfo,NbDim,errormsg]=find_field_cells(Data)
%
% OUTPUT:
% CellInfo: cell of structures describing field cells
%     .CoordType:  type of coordinates for each field cell = 'scattered','grid','tps';
%     .CoordIndex: array of the indices of the variables representing the coordinates (in the order z,y,x)
%     .CoordSize: array of the nbre of values for each  coordinate in a grid, nbre of points in the unstructured case
%     .NbCentres_tps:
%     .SubRange_tps
%     .VarIndex: arrays of the variable indices in the field cell
%     .VarIndex_ancillary: indices of ancillary variables
%              _color : color image, the last index, which is not a coordinate variable, represent the 3 color components rgb
%              _discrete: like scalar, but set of data points without continuity, represented as dots in a usual plot, instead of continuous lines otherwise
%              _errorflag: index of error flag
%              _image   : B/W image, (behaves like scalar)
%              _vector_x,_y,_z: indices of variables giving the vector components x, y, z
%              _warnflag: index of warnflag    
%      .ProjModeRequest= 'interp_lin', 'interp_tps' indicate whether lin interpolation  or derivatives (tps) is needed to calculate the requested field
%      .FieldName = operation to be performed to finalise the field cell after projection
%      .SubCheck=0 /1 indicate that the field must be substracted (second  entry in uvmat)
% NbDim: array with the length of CellVarIndex, giving the space dimension of each field cell
% errormsg: error message
%   
% INPUT:
% Data: structure representing fields, output of check_field_structure
%            .ListGlobalAttributes
%            .ListVarName: cell array listing the names (cahr strings) of the variables
%            .VarDimName: cell array of cells containing the set of dimension names for each variable of .ListVarName
%            .VarAttribute: cell array of structures containing the variable attributes: 
%                     .VarAttribute{ilist}.key=value, where ilist is the variable
%                     index, key is the name of the attribute, value its value (char string or number)
%            .Attr1, .Attr2....
%        case of actual data:
%            .Var1, .Var2...
%        case of data structure, without the  data themselves
%            .LisDimName: list of dimension names
%            .DimValue: list of corresponding dimension values
% HELP: 
% to get the dimensions of arrays common to the field #icell
%         VarIndex=CellVarIndex{icell}; % list of variable indices
%         DimIndex=Data.VarDimIndex{VarIndex(1)} % list of dimensions for each variable in the cell #icell
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright 2008-2014, LEGI / CNRS UJF G-INP, Joel.Sommeria@legi.grenoble-inp.fr
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
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.for input in proj_field and plot_field
%    group the variables  into 'fields' with common dimensions

function [CellInfo,NbDim,errormsg]=find_field_cells(Data)
CellInfo={};
NbDim=0;
errormsg='';
if ~isfield(Data,'ListVarName'), errormsg='the list of variables .ListVarName is missing';return;end
if ~isfield(Data,'VarDimName'), errormsg='the list of dimensions .VarDimName is missing';return;end
nbvar=numel(Data.ListVarName);%number of variables in the field structure
if ~isequal(numel(Data.VarDimName),nbvar), errormsg='.ListVarName and .VarDimName have unequal length';return;end
% check the existence of variable data
check_var=1;
for ilist=1:numel(Data.ListVarName)
    if ~isfield(Data,Data.ListVarName{ilist})
        check_var=0;% dimensions of data defined, data not needed for this function
        break
    end
end
if ~check_var &&  ~(isfield(Data,'ListDimName')&& isfield(Data,'DimValue')&&isequal(numel(Data.ListDimName),numel(Data.DimValue)))
    errormsg=['missing variable or values of dimensions' Data.ListVarName{ilist}];
    return
end


%% role of variables and list of requested operations
%ListRole={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','vector_x_tps','vector_y_tps','warnflag','errorflag',...
%   'ancillary','image','color','discrete','scalar','coord_tps'};% rmq vector_x_tps and vector_y_tps to be replaced by vector_x and vector_y
Role=num2cell(blanks(nbvar));%initialize a cell array of nbvar blanks
ProjModeRequest=regexprep(Role,' ',''); % fieldRequest set to '' by default
FieldName=cell(size(Role)); % fieldRequest set to {} by default
CheckSub=zeros(size(Role));% =1 for fields to substract
Role=regexprep(Role,' ','scalar'); % Role set to 'scalar' by default
if isfield(Data,'VarAttribute')
    for ivar=1:numel(Data.VarAttribute)
        if isfield(Data.VarAttribute{ivar},'Role')
            Role{ivar}=Data.VarAttribute{ivar}.Role;
        end
        if isfield(Data.VarAttribute{ivar},'ProjModeRequest')
            ProjModeRequest{ivar}=Data.VarAttribute{ivar}.ProjModeRequest;
        end
        if isfield(Data.VarAttribute{ivar},'FieldName')
            FieldName{ivar}=Data.VarAttribute{ivar}.FieldName;
        end
        if isfield(Data.VarAttribute{ivar},'CheckSub')
            CheckSub(ivar)=Data.VarAttribute{ivar}.CheckSub;
        end
    end
end

%% find scattered (unstructured) coordinates
ivar_coord_x=find(strcmp('coord_x',Role));%find variables with Role='coord_x'
check_select=false(1,nbvar);
check_coord=false(1,nbvar);
CellInfo=cell(1,numel(ivar_coord_x));
NbDim=zeros(1,numel(ivar_coord_x));
% loop on unstructured coordinate x -> different field cells
for icell=1:numel(ivar_coord_x)
    DimCell=Data.VarDimName{ivar_coord_x(icell)};% cell of dimension names for ivar_coord_x(icell)
    if ischar(DimCell),DimCell={DimCell};end % transform char to cell for a single dimension
    % look for variables sharing dimension(s) with ivar_coord_x(icell)
    check_cell=zeros(numel(DimCell),nbvar);
    for idim=1:numel(DimCell)
        for ivar=1:nbvar
            check_cell(idim,ivar)=max(strcmp(DimCell{idim},Data.VarDimName{ivar}));
        end
    end
    check_cell=sum(check_cell,1)==numel(DimCell);%logical array=1 for variables belonging to the current cell
    VarIndex=find(check_cell);% list of detected variable indices
    if ~(numel(VarIndex)==1 && numel(DimCell)==1)% exclude case of isolated coord_x variable (treated later)
        if ~(numel(VarIndex)==1 && numel(DimCell)>1)% a variable is associated to coordinate
            CellInfo{icell}.CoordIndex=ivar_coord_x(icell);
            % size of coordinate var
            if check_var
                CellInfo{icell}.CoordSize=numel(Data.(Data.ListVarName{ivar_coord_x(icell)}));
            else
                for idim=1:numel(DimCell)
                    check_index= strcmp(DimCell{idim},Data.ListDimName);
                    CellInfo{icell}.CoordSize(idim)=Data.DimValue(check_index);
                end
                CellInfo{icell}.CoordSize=prod(CellInfo{icell}.CoordSize);
            end
            ind_y=find(strcmp('coord_y',Role(VarIndex)));
            if numel(VarIndex)==2||isempty(ind_y)% no variable, except possibly y
                NbDim(icell)=1;
            else
                CellInfo{icell}.CoordType='scattered';
                ind_z=find(strcmp('coord_z',Role(VarIndex)));
                if numel(VarIndex)==3||isempty(ind_z)% no z variable, except possibly as a fct z(x,y)
                    CellInfo{icell}.CoordIndex=[VarIndex(ind_y) CellInfo{icell}.CoordIndex];
                    NbDim(icell)=2;
                else
                    CellInfo{icell}.CoordIndex=[VarIndex(ind_z) CellInfo{icell}.CoordIndex];
                    NbDim(icell)=3;
                end
            end
        end
        CellInfo{icell}.VarIndex=VarIndex;
        check_select=check_select|check_cell;
    end
end

%% look for tps coordinates
ivar_remain=find(~check_select);% indices of remaining variables (not already selected)
check_coord_tps= strcmp('coord_tps',Role(~check_select));
ivar_tps=ivar_remain(check_coord_tps);% variable indices corresponding to tps coordinates

% loop on the tps coordinate sets
for icell_tps=1:numel(ivar_tps)
    check_cell=zeros(1,nbvar);% =1 for the variables selected in the current cell
    check_cell(ivar_tps(icell_tps))=1;% mark the coordinate variable as selected
    DimCell=Data.VarDimName{ivar_tps(icell_tps)};% dimension names for the current tps coordinate variable
    icell=numel(CellInfo)+icell_tps; % new field cell index
    CellInfo{icell}.CoordIndex=ivar_tps(icell_tps);% index of the  tps coordinate variable
    if numel(DimCell)==3
        VarDimName=Data.VarDimName(~check_select);
        for ivardim=1:numel(VarDimName)
            if strcmp(VarDimName{ivardim},DimCell{3})
                CellInfo{icell}.NbCentres_tps= ivar_remain(ivardim);% nbre of sites for each tps subdomain
                check_cell(ivar_remain(ivardim))=1;% mark the variable as selected
            elseif strcmp(VarDimName{ivardim}{1},DimCell{2}) && numel(VarDimName{ivardim})>=3 && strcmp(VarDimName{ivardim}{3},DimCell{3})
                CellInfo{icell}.SubRange_tps=ivar_remain(ivardim);% subrange definiton for tps
                check_cell(ivar_remain(ivardim))=1;% mark the variable as selected
            elseif strcmp(VarDimName{ivardim}{1},DimCell{1}) && strcmp(VarDimName{ivardim}{2},DimCell{3})% variable
                check_cell(ivar_remain(ivardim))=1;% mark the variable as selected
            end
        end
    end
    CellInfo{icell}.CoordType='tps';
    CellInfo{icell}.VarIndex=find(check_cell);
    if check_var
        NbDim(icell)=size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),2);
        CellInfo{icell}.CoordSize=size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),1)*size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),3);
    else
        check_index_1= strcmp(DimCell{1},Data.ListDimName);
        check_index_2= strcmp(DimCell{2},Data.ListDimName);
        NbDim(icell)=Data.DimValue(check_index_2);
        if numel(DimCell)>=3
        check_index_3= strcmp(DimCell{3},Data.ListDimName);  
        CellInfo{icell}.CoordSize=Data.DimValue(check_index_1)*Data.DimValue(check_index_3);
        end
    end
    check_select=check_select|check_cell;
end

%% look for coordinate variables and corresponding gridded data:
% coordinate variables are variables associated with a single dimension, defining the coordinate values
% two cases: 1)the coordiante variable represents the set of coordiante values
%            2)the coordinate variable contains only two elements, representing the coordinate bounds for the dimension with the same name as the cordinate
ivar_remain=find(~check_select);% indices of remaining variables, not already taken into account
ListVarName=Data.ListVarName(~check_select);%list of remaining variables
VarDimName=Data.VarDimName(~check_select);%dimensions of remaining variables
check_coord_select= cellfun(@numel,VarDimName)==1|cellfun(@ischar,VarDimName)==1;% find remaining variables with a single dimension
check_coord_select=check_coord_select & ~strcmp('ancillary',Role(~check_select));% do not select ancillary variables as coordinates
%check_coord(~check_select)=check_coord_select;
ListCoordIndex=ivar_remain(check_coord_select);% indices of remaining variables with a single dimension
ListCoordName=ListVarName(check_coord_select);% corresponding names of remaining variables with a single dimension
ListDimName=VarDimName(check_coord_select);% dimension names of remaining variables with a single dimension

%remove redondant variables -> keep only one variable per dimension
check_keep=logical(ones(size(ListDimName)));
for idim=1:numel(ListDimName)
    prev_ind=strcmp(ListDimName{idim},ListDimName(1:idim-1));% check whether the dimension is already taken into account
    if ~isempty(prev_ind)
        if strcmp(ListCoordName{idim},ListDimName{idim}) %variable with the same name as the coordinate taken in priority
            check_keep(prev_ind)=0;
        else
           check_keep(idim)=0; 
        end
    end
end
ListCoordIndex=ListCoordIndex(check_keep);% list of coordinate variable indices
ListCoordName=ListCoordName(check_keep);% list of coordinate variable names
ListDimName=ListDimName(check_keep);% list of coordinate dimension names

% determine dimension sizes
CoordSize=zeros(size(ListCoordIndex));
for ilist=1:numel(ListCoordIndex)
    if iscell(ListDimName{ilist})
        ListDimName(ilist)=ListDimName{ilist};%transform cell to string
    end
    if check_var% if the list of dimensions has been directly defined, no variable data available
        CoordSize(ilist)=numel(Data.(ListCoordName{ilist}));% number of elements in the variable corresponding to the dimension #ilist
    else
        check_index= strcmp(ListDimName{ilist},Data.ListDimName);% find the  index in the list of dimensions
        CoordSize(ilist)=Data.DimValue(check_index);% find the  corresponding dimension value
    end
    if CoordSize(ilist)==2% case of uniform grid coordinate defined by lower and upper bounds only
        ListDimName{ilist}=ListCoordName{ilist};% replace the dimension name by the coordinate variable name 
    end
end

%% group the remaining variables in cells sharing the same coordinate variables
NewCellInfo={};
NewCellDimIndex={};
NewNbDim=[];
for ivardim=1:numel(VarDimName) % loop at the list of remaining variables
    DimCell=VarDimName{ivardim};% dimension names of the current variable 
    if ischar(DimCell), DimCell={DimCell}; end %transform char to cell if needed
    DimIndices=[];
    for idim=1:numel(DimCell)
        ind_dim=find(strcmp(DimCell{idim},ListDimName));%find the dim index in the list of dimensions ListDimName
        if ~isempty(ind_dim)
            DimIndices=[DimIndices ind_dim]; %update the list of dim indices included in DimCell
            if check_var && CoordSize(ind_dim)==2 % determine the size of the coordinate in case of coordinate definition limited to lower and upper bounds
                if isvector(Data.(ListVarName{ivardim})) 
                    if numel(Data.(ListVarName{ivardim}))>2
                        CoordSize(ind_dim)=numel(Data.(ListVarName{ivardim}));
                    end
                else
                    CoordSize(ind_dim)=size(Data.(ListVarName{ivardim}),idim);
                end
            end
        end
    end
    % look for cells of variables with the same coordinate variables
    check_previous=0;
    for iprev=1:numel(NewCellInfo)
        if isequal(DimIndices,NewCellDimIndex{iprev})
            check_previous=1;
            NewCellInfo{iprev}.VarIndex=[NewCellInfo{iprev}.VarIndex ivar_remain(ivardim)];%append the current variable index to the found field cell
            break
        end
    end
    % create a new cell if no previous one contains the coordinate variables
    if ~check_previous
        nbcell=numel(NewCellInfo)+1;
        NewCellDimIndex{nbcell}=DimIndices;
        NewCellInfo{nbcell}.VarIndex=ivar_remain(ivardim);% create a new field cell with the current variable index
        NewNbDim(nbcell)=numel(DimIndices);
        NewCellInfo{nbcell}.CoordType='grid';
        NewCellInfo{nbcell}.CoordSize=CoordSize(DimIndices);
        NewCellInfo{nbcell}.CoordIndex=ListCoordIndex(DimIndices);
    end
end
NbDim=[NbDim NewNbDim];
CellInfo=[CellInfo NewCellInfo];

%% suppress empty cells or cells with a single coordinate variable 
check_remove=false(size(CellInfo));
for icell=1:numel(check_remove)
    if isempty(CellInfo{icell})||(numel(CellInfo{icell}.VarIndex)==1 && check_coord(icell))
        check_remove(icell)=1;
    end
end
CellInfo(check_remove)=[];
NbDim(check_remove)=[];

%% document roles of non-coordinate variables
for icell=1:numel(CellInfo)
    VarIndex=CellInfo{icell}.VarIndex;
    for ivar=VarIndex
        if isfield(CellInfo{icell},['VarIndex_' Role{ivar}])
            CellInfo{icell}.(['VarIndex_' Role{ivar}])=[CellInfo{icell}.(['VarIndex_' Role{ivar}]) ivar];
        else
            CellInfo{icell}.(['VarIndex_' Role{ivar}])= ivar;
        end
        if ~isempty(ProjModeRequest{ivar})
            CellInfo{icell}.ProjModeRequest=ProjModeRequest{ivar};
        end
        if ~isempty(FieldName{ivar})
            CellInfo{icell}.FieldName=FieldName{ivar};
        end
        if CheckSub(ivar)==1
            CellInfo{icell}.CheckSub=1;
        end
    end
end
