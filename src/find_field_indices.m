%'find_file_indices': test field structure for input in proj_field and plot_field
%    group the variables  into 'fields' with common dimensions
%------------------------------------------------------------------------
% function  [CellVarIndex,NbDim,CellVarType,errormsg]=find_field_indices(Data)
%
% OUTPUT:
% CellVaxIndex: cell whose elements are arrays of indices in the list data.ListVarName  
%              CellvarIndex{i} represents a set of variables with the same dimensions
% NbDim: array with the length of CellVarIndex, giving its  space dimension
% CellVarType: cell array of structures with fields
%      .coord_x, y, z: indices (in .ListVarname) of variables representing  unstructured coordinates x, y, z 
%      .vector_x,_y,_z: indices of variables giving the vector components x, y, z
%      .warnflag: index of warnflag
%      .errorflag: index of error flag
%      .ancillary: indices of ancillary variables
%      .image   : B/W image, (behaves like scalar)
%      .color : color image, the last index, which is not a coordinate variable, represent the 3 color components rgb
%      .discrete: like scalar, but set of data points without continuity, represented as dots in a usual plot, instead of continuous lines otherwise
%      .scalar: scalar field (default)
%      .coord: vector of indices of coordinate variables corresponding to matrix dimensions
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
%------------------------------------------------------------------------
% function  [CellVarIndex,NbDim,CellVarType,errormsg]=find_field_indices(Data)
%
% OUTPUT:
% CellVaxIndex: cell whose elements are arrays of indices in the list data.ListVarName  
%              CellvarIndex{i} represents a set of variables with the same dimensions
% NbDim: array with the length of CellVarIndex, giving its  space dimension
% CellVarType: cell array of structures with fields
%      .coord_x, y, z: indices (in .ListVarname) of variables representing  unstructured coordinates x, y, z 
%      .vector_x,_y,_z: indices of variables giving the vector components x, y, z
%      .warnflag: index of warnflag
%      .errorflag: index of error flag
%      .ancillary: indices of ancillary variables
%      .image   : B/W image, (behaves like scalar)
%      .color : color image, the last index, which is not a coordinate variable, represent the 3 color components rgb
%      .discrete: like scalar, but set of data points without continuity, represented as dots in a usual plot, instead of continuous lines otherwise
%      .scalar: scalar field (default)
%      .coord: vector of indices of coordinate variables corresponding to matrix dimensions
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
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function [CellVarIndex,NbDim,CellVarType,errormsg]=find_field_indices(Data)
CellVarIndex={};

NbDim=[];
CellVarType=[];
errormsg=[];
nbvar=numel(Data.ListVarName);%number of field variables
icell=0;

NbDim=[];
ivardim=0;
VarDimIndex=[];
VarDimName={};
if ~isfield(Data,'VarDimName')
    errormsg='missing .VarDimName';
    return
end

%% role of variables
Role=mat2cell(blanks(nbvar),1,ones(1,nbvar));%initialize a cell array of nbvar blanks
Role=regexprep(Role,' ','scalar'); % Role set to 'scalar' by default
if isfield(Data,'VarAttribute')
    for ivar=1:numel(Data.VarAttribute)
        if isfield(Data.VarAttribute{ivar},'Role')
            Role{ivar}=Data.VarAttribute{ivar}.Role;
        end
    end
end

%% loop on the list of variables, group them by common dimensions
for ivar=1:nbvar
    DimCell=Data.VarDimName{ivar}; %dimensions associated with the variable #ivar
    if ischar(DimCell)
        DimCell={DimCell};
        Data.VarDimName{ivar}={Data.VarDimName{ivar}};%transform char chain into cell
    end
    testnewcell=1;
    for icell_prev=1:numel(CellVarIndex)%detect whether the dimensions of ivar fit with an existing cell
        PrevVarIndex=CellVarIndex{icell_prev};%list of variable indices in cell # icell_prev
        PrevDimName=Data.VarDimName{PrevVarIndex(1)};%list of corresponding variable names
        if isequal(PrevDimName,DimCell)
            CellVarIndex{icell_prev}=[CellVarIndex{icell_prev} ivar];% add variable index #ivar to the cell #icell_prev
            testnewcell=0; %existing cell detected
            break
        end
    end
    if testnewcell
        icell=icell+1;
        CellVarIndex{icell}=ivar;%put the current variabl index in the new cell 
    end
   
    %look for dimension variables
    if numel(DimCell)==1% if the variable has a single dimension 
        if strcmp(DimCell{1},Data.ListVarName{ivar}) || strcmp(Role{ivar},'dimvar')
            ivardim=ivardim+1;
            VarDimIndex(ivardim)=ivar;%index of the variable
            VarDimName{ivardim}=DimCell{1};%name of the dimension
        end
    end
end

%% find the spatial dimensions and vector components 
ListRole={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','vector_x_tps','vector_y_tps','warnflag','errorflag',...
    'ancillary','image','color','discrete','scalar','coord_tps'};% rmq vector_x_tps and vector_y_tps to be replaced by vector_x and vector_y
NbDim=zeros(size(CellVarIndex));%default

for ilist=1:numel(ListRole)
    VarType.(ListRole{ilist})=find(strcmp(ListRole{ilist},Role));
end
%look for tps coordinates
if ~isempty(VarType.coord_tps)
    VarType.subrange_tps=[];
    VarType.nbsites_tps=[];
    for ifield=1:numel(VarType.coord_tps)
        select(ifield)=0;
        DimCell=Data.VarDimName{VarType.coord_tps(ifield)};
        if numel(DimCell)==3
            for ivardim=1:numel(Data.VarDimName)
                if strcmp(Data.VarDimName{ivardim},DimCell{3})
                    VarType.nbsites_tps=[VarType.nbsites_tps ivardim];
                    select(ifield)=select(ifield)+1;
                elseif strcmp(Data.VarDimName{ivardim}{1},DimCell{2}) && strcmp(Data.VarDimName{ivardim}{3},DimCell{3})
                    VarType.subrange_tps=[VarType.subrange_tps ivardim];
                    select(ifield)=select(ifield)+1;
                end
            end
        end
    end
    VarType.coord_tps=VarType.coord_tps(select==2);
    VarType.subrange_tps=VarType.subrange_tps(select==2);
    VarType.nbsites_tps=VarType.nbsites_tps(select==2);
end

index_remove=[];
CellVarType=cell(1,length(CellVarIndex));
for icell=1:length(CellVarIndex)
    VarIndex=CellVarIndex{icell};%set of variable indices with the same dim
    check_remove=0;
    for ifield=1:numel(VarType.coord_tps)
        if isequal(VarIndex,VarType.coord_tps(ifield))||isequal(VarIndex,VarType.subrange_tps(ifield))||isequal(VarIndex,VarType.nbsites_tps(ifield))
            index_remove=[index_remove icell];% removes Coord_tps as field cell
            check_remove=1;
        end
    end
    
    if ~check_remove
        for ilist=1:numel(ListRole)
            CellVarType{icell}.(ListRole{ilist})=VarIndex(find(strcmp(ListRole{ilist},Role(VarIndex))));
        end
        DimCell=Data.VarDimName{VarIndex(1)};% list of dimensions for each variable in the cell #icell
        if numel(CellVarType{icell}.coord_x)>1 || numel(CellVarType{icell}.coord_y)>1 || numel(CellVarType{icell}.coord_z)>1
            errormsg='multiply defined coordinates  in the same cell';
            return
        end
        if numel(CellVarType{icell}.errorflag)>1
            errormsg='multiply defined error flag in the same cell';
            return
        end
        if numel(CellVarType{icell}.warnflag)>1
            errormsg='multiply defined warning flag in the same cell';
            return
        end
        test_coord=0;
        % look for unstructured coordinates
        if numel(VarIndex)>1
            if ~isempty(CellVarType{icell}.coord_z)
                NbDim(icell)=3;
                test_coord=1;
            elseif ~isempty(CellVarType{icell}.coord_y)
                NbDim(icell)=2;
                test_coord=1;
            elseif ~isempty(CellVarType{icell}.coord_x)
                NbDim(icell)=1;
                test_coord=1;
            end
        end
        % look for coordinates variables
        coord=zeros(1,numel(DimCell));%default
        %     if NbDim(icell)==0 && ~isempty(VarDimName)% no unstructured coordinate found
        if  ~test_coord && ~isempty(VarDimName)
            for idim=1:numel(DimCell)   %loop on the dimensions of the variables in cell #icell
                for ivardim=1:numel(VarDimName)
                    if strcmp(VarDimName{ivardim},DimCell{idim})
                        coord(idim)=VarDimIndex(ivardim);
                        break
                    end
                end
            end
            NbDim(icell)=numel(find(coord));
        end
        CellVarType{icell}.coord=coord;
        %look for tps data
        if ~isempty(VarType.coord_tps)
            for ilist=1:numel(VarType.coord_tps)
            tps_dimnames=Data.VarDimName{VarType.coord_tps(ilist)};
            if length(tps_dimnames)==3 && strcmp(tps_dimnames{1},DimCell{1}) && strcmp(tps_dimnames{3},DimCell{2})
                CellVarIndex{icell}=[CellVarIndex{icell} VarType.coord_tps(ilist) VarType.nbsites_tps(ilist) VarType.subrange_tps(ilist)];
                CellVarType{icell}.coord_tps=VarType.coord_tps(ilist);
                CellVarType{icell}.nbsites_tps=VarType.nbsites_tps(ilist);
                CellVarType{icell}.subrange_tps=VarType.subrange_tps(ilist);
                if isfield(Data,'ListDimName')
                    dim_index=find(strcmp(tps_dimnames{2},Data.ListDimName));
                    NbDim(icell)=Data.DimValue(dim_index);
                else
                NbDim(icell)=size(Data.(Data.ListVarName{VarType.coord_tps(ilist)}),2);
                end
            end
            end
        end
    end
end
if ~isempty(index_remove)
    CellVarIndex(index_remove)=[];
    CellVarType(index_remove)=[];
    NbDim(index_remove)=[];
end
