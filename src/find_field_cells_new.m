%'find_file_indices': test field structure for input in proj_field and plot_field
%    group the variables  into 'fields' with common dimensions
%------------------------------------------------------------------------
% function  [CellVarIndex,NbDim,CoordType,VarRole,errormsg]=find_field_cells(Data)=find_field_cells(Data)
%
% OUTPUT:
% CellVaxIndex: cell whose elements are arrays of the variable indices in the list Data.ListVarName for each field cell   
%              CellvarIndex{i} represents a set of variables with the same dimensions
% NbDim: array with the length of CellVarIndex, giving the space dimension of each field cell
% CoordType: cell array with elements 'scattered','grid','tps'; type of coordinates for each field cell
% VarRole: cell array of structures with fields
%      .coord_x, y, z: indices (in .ListVarname) of variables representing scattered (unstructured) coordinates x, y, z 
%      .vector_x,_y,_z: indices of variables giving the vector components x, y, z
%      .warnflag: index of warnflag
%      .errorflag: index of error flag
%      .ancillary: indices of ancillary variables
%      .image   : B/W image, (behaves like scalar)
%      .color : color image, the last index, which is not a coordinate variable, represent the 3 color components rgb
%      .discrete: like scalar, but set of data points without continuity, represented as dots in a usual plot, instead of continuous lines otherwise
%      .scalar: scalar field (default)
%      .coord: vector of indices of coordinate variables corresponding to matrix dimensions
%
%      .FieldRequest= 'interp_lin', 'interp_tps' indicate whether lin interpolation  or derivatives (tps) is needed to calculate the requested field
%      .Operation = operation to be performed to finalise the field cell after projection
%      .SubCheck=0 /1 indicate that the field must be substracted (second  entry in uvmat)
% errormsg: error message
%   
% INPUT:
% Data: structure representing fields, output of check_field_structure
%            .ListVarName: cell array listing the names (cahr strings) of the variables
%            .VarDimName: cell array of cells containing the set of dimension names for each variable of .ListVarName
%            .VarAttribute: cell array of structures containing the variable attributes: 
%                     .VarAttribute{ilist}.key=value, where ilist is the variable
%                     index, key is the name of the attribute, value its value (char string or number)
%
% HELP: 
% to get the dimensions of arrays common to the field #icell
%         VarIndex=CellVarIndex{icell}; % list of variable indices
%         DimIndex=Data.VarDimIndex{VarIndex(1)} % list of dimensions for each variable in the cell #icell
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
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.for input in proj_field and plot_field
%    group the variables  into 'fields' with common dimensions

function [CellVarIndex,NbDim,CoordType,VarRole,errormsg]=find_field_cells(Data)
CellVarIndex={};

CellVarType=[];
errormsg=[];
if ~isfield(Data,'ListVarName'), erromsg='the list of variables .ListVarName is missing';return;end
if ~isfield(Data,'VarDimName'), erromsg='the list of dimensions .VarDimName is missing';return;end
nbvar=numel(Data.ListVarName);%number of field variables
if ~isequal(numel(Data.VarDimName),nbvar), erromsg='.ListVarName and .VarDimName have unequal length';return;end
if isfield(Data,'ListDimName')&& isfield(Data,'DimValue')&&isequal(numel(Data.ListDimName),numel(Data.DimValue))
    check_dim=1;% dimensions of data defined, data not needed for this function
else
    check_dim=0;
    for ilist=1:numel(ListVarName)
        if ~isfield(Data,Data.ListVarName{ilist})
            errormsg=['missing variable ' Data.ListVarName{ilist}];
            return
        end
    end
end
icell=0;

NbDim=[];
VarDimIndex=[];
VarDimName={};

%% role of variables and list of requested operations
%ListRole={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','vector_x_tps','vector_y_tps','warnflag','errorflag',...
%   'ancillary','image','color','discrete','scalar','coord_tps'};% rmq vector_x_tps and vector_y_tps to be replaced by vector_x and vector_y
Role=num2cell(blanks(nbvar));%initialize a cell array of nbvar blanks
FieldRequest=regexprep(Role,' ',''); % fieldRequest set to '' by default
Operation=cell(size(Role)); % fieldRequest set to {} by default
CheckSub=zeros(size(Role));% =1 for fields to substract
Role=regexprep(Role,' ','scalar'); % Role set to 'scalar' by default
if isfield(Data,'VarAttribute')
    for ivar=1:numel(Data.VarAttribute)
        if isfield(Data.VarAttribute{ivar},'Role')
            Role{ivar}=Data.VarAttribute{ivar}.Role;
        end
        if isfield(Data.VarAttribute{ivar},'FieldRequest')
            FieldRequest{ivar}=Data.VarAttribute{ivar}.FieldRequest;
        end
        if isfield(Data.VarAttribute{ivar},'Operation')
            Operation{ivar}=Data.VarAttribute{ivar}.Operation;
        end
        if isfield(Data.VarAttribute{ivar},'CheckSub')
            CheckSub(ivar)=Data.VarAttribute{ivar}.CheckSub;
        end
    end
end

%% find scattered coordinates
ivar_coord_x=find(strcmp('coord_x',Role);
VarDimCell=cell(numel(ivar_coord_x));
check_select=zeros(1,nbvar);
CellVarIndex=cell(1,numel(ivar_coord_x));
CoordType=cell(1,numel(ivar_coord_x));
VarRole=cell(1,numel(ivar_coord_x));
for icell=1:numel(ivar_coord_x)
    DimCell=Data.VarDimName{ivar_coord_x(icell)};
    if ischar(DimCell),DimCell={DimCell};end
    check_cell=zeros(numel(DimCell),nbvar);
    for idim=1:numel(DimCell)
        for ivar=1:nbvar
            check_cell(idim,ivar)=strcmp(DimCell{idim},Data.VarDimName{ivar});
        end
    end
    check_cell=sum(check_cell,1)==numel(DimCell);%logical array=1 for variables belonging to the current cell
    VarIndex=find(check_cell);
    if ~(numel(VarIndex)==1 && numel(DimCell)==1)% exclude case of isolated coord_x variable (treated later)
        if numel(VarIndex)==1 && numel(DimCell)>1% no variable associated to coordinate
            NbDim(icell)=0;
        else
            VarRole{icell}.Coord=ivar_coord_x(icell);
            ind_y=find(strcmp('coord_y',Role(CellVarIndex{icell})));
            if numel(VarIndex)==2||isempty(ind_y)% no variable, except possibly y
                NbDim(icell)=1;
            else
                CoordType{icell}='scattered';
                ind_z=find(strcmp('coord_z',Role(CellVarIndex{icell})));
                if numel(VarIndex)==3||isempty(ind_z)% no z variable, except possibly as a fct z(x,y)
                    VarRole{icell}.Coord=[VarIndex(ind_y) VarRole{icell}.Coord];
                    NbDim(icell)=2;
                else
                    VarRole{icell}.Coord=[VarIndex(ind_z) VarRole{icell}.Coord];
                    NbDim(icell)=3;
                end
            end
        end
        CellVarIndex{icell}=VarIndex;
        check_select=check_select|check_cell;
    end
end

%% look for tps coordinates
ivar_remain=find(~check_select);
check_coord_tps= strcmp('coord_tps',Role(~check_select));
ivar_tps=ivar_remain(check_coord_tps);
for icell_tps=1:numel(ivar_tps)
    DimCell=Data.VarDimName{ivar_tps(icell_tps)};
    icell=numel(CellVarIndex)+icell_tps;
    VarRole{icell}.Coord=ivar_tps(icell);
    VarRole{icell}.subrange_tps=[];
    VarRole{icell}.nbsites_tps=[];
    if numel(DimCell)==3
        VarDimName=Data.VarDimName(~check_select);
        for ivardim=1:numel(VarDimName)
            if strcmp(VarDimName{ivardim},DimCell{3})
                VarRole{icell}.nbsites_tps= ivar_remain(ivardim);
                check_cell(ivar_remain(ivardim))=1;% nbre of sites for each tps subdomain
            elseif strcmp(VarDimName{ivardim}{1},DimCell{2}) && strcmp(VarDimName{ivardim}{3},DimCell{3})
                VarRole{icell}.subrange_tps=ivar_remain(ivardim);
                check_cell(ivar_remain(ivardim))=1;% subrange definiton for tps
            elseif strcmp(VarDimName{ivardim}{1},DimCell{1}) && strcmp(VarDimName{ivardim}{2},DimCell{3})
                check_cell(ivar_remain(ivardim))=1;% variable
            end
        end
    end
    if check_dim
        check_index= strcmp(DimCell{2},Data.ListDimName);
        NbDim(icell)=Data.DimValue(check_index);
    else
        NbDim(icell)=size(Data.(Data.ListVarName{VarRole{icell}.Coord}),2);
    end
    CoordType{icell}='tps';
    CellVarIndex{icell}=find(check_cell);
    check_select=check_select|check_cell;
end

%% look for dimension variables and corresponding gridded data
ivar_remain=find(~check_select);
check_coord= cellfun(@numel,VarDimName)==1|cellfun(@ischar,VarDimName)==1;% find variables with a single dimension
ListCoordIndex=ivar_remain(check_coord);
ListCoordName=Data.ListVarName(ListCoordIndex);
ListDimName=Data.VarDimName(ListCoordIndex);
for ilist=1:numel(ListCoordIndex)
    if ischar(ListDimName{ilist})
        ListDimName{ilist}=ListDimName(ilist);%transform string to cell
    end
    if check_dim
        check_index= strcmp(ListDimName{ilist}{1},Data.ListDimName);
       DimValue=Data.DimValue(check_index);
    else
       DimValue=numel(Data.(ListCoordName{ilist});
    end
    if DimValue==2% case of uniform grid coordinate defined by lower and upper bounds only
        ListDimName{ilist}=ListCoordName{ilist};% look for dimensions with name equal to coordinate for 
    end
end
NewCellVarIndex={};
NewCellDimIndex={];
NewNbDim=[];
NewCoordType={};
NewVarRole={};
VarDimName=Data.VarDimName(~check_select);%dimensions of remaining variables
for ivardim=1:numel(VarDimName) % loop on the list of remaining variables
    DimCell=VarDimName{ivardim};% dimension names of the current variable
    DimIndices=[];
    for idim=1:numel(DimCell)
        ind_dim=find(strcmp(DimCell{idim},ListDimName));%find the dim index in the list of coord dim
        if ~isempty(ind_dim)
        DimIndices=[DimIndices ind_dim]; %update the list of coord dims included in DimCell
        end
    end
    check_previous=0;
    for iprev=1:numel(NewCellVarIndex)
        if isequal(DimIndices,NewCellDimIndex{iprev})
            NewCellVarIndex{iprev}=[NewCellVarIndex{iprev} ivar_remain(ivardim)];%append the current variable index to the found field cell
            check_previous=1;
            break
        end
    end
    if ~check_previous
        nbcell=numel(NewCellVarIndex)+1;
        NewCellVarIndex{nbcell}=[ivar_remain(ivardim)];% create a new field cell with the current variable index
        NewCellDimIndex{nbcell}=DimIndices;
        NewNbDim(nbcell)=numel(DimIndices);
        NewCoordType{nbcell}='grid';
        NewVarRole{nbcell}.Coord=ListCoordIndex(DimIndices);
    end
end
CellVarIndex=[CellVarIndex NewCellVarIndex];
NbDim=[NbDim NewNbDim];
CoordType=[CoordType NewCoordType];
VarRole=[VarRole NewVarRole];

%% suppress empty cells
check_empty=cellfun(@isempty,CellVarIndex);
CellVarIndex(check_empty)=[];
NbDim(check_empty)=[];
CoordType(check_empty)=[];
VarRole(check_empty)=[];

%% document roles of non-coordinate variables
ListRole={'vector_x','vector_y','vector_z','vector_x_tps','vector_y_tps','warnflag','errorflag',...
   'ancillary','image','color','discrete','scalar'};% except coord,coord_x,_y,_z,Coord_tps already taken, into account
for icell=1:numel(CellVarIndex)
    VarIndex=CellVarIndex{icell};
    for ivar=VarIndex
        if isfield(VarRole{icell},Role{ivar})
            VarRole{icell}.(Role{ivar})=[VarRole{icell}.(Role{ivar}) ivar];
        else
            VarRole{icell}.(Role{ivar})= ivar;
        end
        if ~isempty(FieldRequest{ivar})
            VarRole{icell}.FieldRequest=FieldRequest{ivar};
        end
        if ~isempty(Operation{ivar})
            VarRole{icell}.Operation=Operation{ivar};
        end
        if CheckSub{ivar}==1
            VarRole{icell}.CheckSub=1;
        end
    end
end
