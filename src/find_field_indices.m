%'find_file_indices': test field structure for input in proj_field and plot_field
%    group the variables  into 'fields' with common dimensions
%------------------------------------------------------------------------
% function  [CellVarIndex,NbDim,VarType,errormsg]=find_field_indices(Data)
%
% OUTPUT:
% CellVaxIndex: cell whose elements are arrays of indices in the list data.ListVarName  
%              CellvarIndex{i} represents a set of variables with the same dimensions
% NbDim: array with the length of CellVarIndex, giving its  space dimension
% VarType: cell array of structures with fields
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

function [CellVarIndex,NbDim,VarType,errormsg]=find_field_indices(Data)
CellVarIndex={};
NbDim=[];
VarType=[];
errormsg=[];
nbvar=numel(Data.ListVarName);%number of field variables
icell=0;
ivardim=0;
VarDimIndex=[];
VarDimName={};
if ~isfield(Data,'VarDimName')
    errormsg='missing .VarDimName';
    return
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
        Role='';
        if isfield(Data,'VarAttribute') && length(Data.VarAttribute)>=ivar && isfield(Data.VarAttribute{ivar},'Role')
            Role=Data.VarAttribute{ivar}.Role;
        end
        if strcmp(DimCell{1},Data.ListVarName{ivar}) || strcmp(Role,'dimvar')
            ivardim=ivardim+1;
            VarDimIndex(ivardim)=ivar;%index of the variable
            VarDimName{ivardim}=DimCell{1};%name of the dimension
        end
    end
end

%% find the spatial dimensions and vector components 
ListRole={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','warnflag','errorflag',...
    'ancillary','image','color','discrete','scalar','coord_tps'};
NbDim=zeros(size(CellVarIndex));%default
for icell=1:length(CellVarIndex)
    for ilist=1:numel(ListRole)
        eval(['ivar_' ListRole{ilist} '=[];'])
    end
    VarIndex=CellVarIndex{icell};%set of variable indices with the same dim 
    DimCell=Data.VarDimName{VarIndex(1)};% list of dimensions for each variable in the cell #icell
    if isfield(Data,'VarAttribute');
        VarAttribute=Data.VarAttribute;
    else
        VarAttribute={};
    end
    test_2D=0;
    for ivar=VarIndex
        if length(VarAttribute)>=ivar
            if isfield(VarAttribute{ivar},'Role') 
                role=VarAttribute{ivar}.Role;
                switch role
                    case ListRole
                        eval(['ivar_' role '=[ivar_' role ' ivar];']) 
                    otherwise
                       ivar_scalar=[ivar_scalar ivar];%variables are consiered as 'scalar' by default (in the absence of attribute 'Role')
                end
            else
              ivar_scalar=[ivar_scalar ivar];% variable considered as scalar in the absence of Role attribute  
            end
            if isfield(VarAttribute{ivar},'Coord_2')
                test_2D=1; %obsolete convention
            end
        else
            ivar_scalar=[ivar_scalar ivar];%variables are consiered as 'scalar' by default (in the absence of attribute 'Role')
        end
    end
    for ilist=1:numel(ListRole)
        eval(['VarType{icell}.' ListRole{ilist} '=ivar_' ListRole{ilist} ';'])
    end    
    if numel(ivar_coord_x)>1 || numel(ivar_coord_y)>1 || numel(ivar_coord_z)>1
        errormsg='multiply defined coordinates  in the same cell';
        return
    end
    if numel(ivar_errorflag)>1
        errormsg='multiply defined error flag in the same cell';
        return
    end
    if numel(ivar_warnflag)>1
        errormsg='multiply defined warning flag in the same cell';
        return
    end
    test_coord=0;
    if numel(VarIndex)>1      
        if ~isempty(ivar_coord_z)
            NbDim(icell)=3;
            test_coord=1;
        elseif ~isempty(ivar_coord_y)
            NbDim(icell)=2;
            test_coord=1;
        elseif ~isempty(ivar_coord_x)
            NbDim(icell)=1;
            test_coord=1;
        end
    end 
    % look at coordinates variables  
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
    VarType{icell}.coord=coord; 
    if NbDim(icell)==0 && test_2D %look at attributes Coord_1, coord_2 (obsolete convention)
        NbDim(icell)=2;
    end
    %look for tps data
    if ~isempty(VarType{icell}.coord_tps)
        VarType{icell}.var_tps=[];
        tps_dimnames=Data.VarDimName{VarType{icell}.coord_tps};
        if length(tps_dimnames)==3
            for ilist=1:length(Data.VarDimName)
                if strcmp(tps_dimnames{1},Data.VarDimName{ilist}{1}) && strcmp(tps_dimnames{3},Data.VarDimName{ilist}{2})% identify the variables corresponding to the tps site coordinates coord_tps
                    VarType{icell}.var_tps=[VarType{icell}.var_tps ilist];
                elseif length(Data.VarDimName{ilist})==1 && strcmp(tps_dimnames{3},Data.VarDimName{ilist}{1})% identify the variable corresponding to nbsites
                    VarType{icell}.nbsites_tps= ilist;
                elseif length(Data.VarDimName{ilist})==3 && strcmp(tps_dimnames{2},Data.VarDimName{ilist}{1})&& strcmp(tps_dimnames{3},Data.VarDimName{ilist}{3})% identify the variable subrange
                    VarType{icell}.subrange_tps= ilist;
                end
            end
        end
        NbDim(icell)=2;
    end  
end
