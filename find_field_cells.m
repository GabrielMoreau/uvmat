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
%              _histo: index of variable used as histogram
%       .DimIndex
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

%    group the variables  into 'fields' with common dimensions

function [CellInfo,NbDim,errormsg]=find_field_cells(Data)
CellInfo={};%default output
NbDim=[];
errormsg='';
if ~isfield(Data,'ListVarName'), errormsg='the list of variables .ListVarName is missing';return;end
if ~isfield(Data,'VarDimName'), errormsg='the list of dimensions .VarDimName is missing';return;end
nbvar=numel(Data.ListVarName);%number of variables in the field structure
check_used=false(1,nbvar); % flag to mark used variables 
if ~isequal(numel(Data.VarDimName),nbvar), errormsg='.ListVarName and .VarDimName have unequal length';return;end
% check the existence of variable data
check_var=true;
for ilist=1:numel(Data.ListVarName)
    if ~isfield(Data,Data.ListVarName{ilist})
        check_var=false;% dimensions of array defined, but the corresponding array is not given
        break
    end
end

%% role of variables and list of requested operations
%ListRole={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','vector_x_tps','vector_y_tps','errorflag',...
%   'ancillary','color','discrete','scalar','coord_tps'};% rmq vector_x_tps and vector_y_tps to be replaced by vector_x and vector_y
if isfield(Data,'ListRole')
    Role=Data.ListRole;
else
    Role=num2cell(blanks(nbvar));%initialize a cell array of nbvar blanks
end
ProjModeRequest=regexprep(Role,' ',''); % fieldRequest set to '' by default
FieldName=cell(size(Role)); % fieldRequest set to {} by default
CheckSub=zeros(size(Role));% =1 for fields to substract



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

%% detect  fields with different roles
ind_scalar=find(strcmp('scalar',Role));
ind_errorflag=find(strcmp('errorflag',Role));
ind_vector_x=[find(strcmp('vector_x',Role)) find(strcmp('vector_x_tps',Role))];
if ~isempty(ind_vector_x)
    ind_vector_y=[find(strcmp('vector_y',Role)) find(strcmp('vector_y_tps',Role))];
    ind_vector_z=find(strcmp('vector_z',Role));
    ind_ancillary=find(strcmp('ancillary',Role));
end
ind_discrete=find(strcmp('discrete',Role));
ind_coord_x=[find(strcmp('coord_x',Role)) find(strcmp('histo',Role))];
ind_coord_y=find(strcmp('coord_y',Role));
ind_coord_z=find(strcmp('coord_z',Role));
ind_histo=find(strcmp('histo',Role));
ind_coord_tps=find(strcmp('coord_tps',Role));
ind_tabledata=find(strcmp('tabledata',Role));
check_char=cellfun(@ischar,Data.VarDimName);% look for dimension name defined by a char strings in the list Data.VarDimName
Data.VarDimName(check_char)=num2cell(Data.VarDimName(check_char)); %transform each individual dimension 'DimName' into its cell {'DimName'}
check_coord_names= cellfun(@numel,Data.VarDimName)==1;% detect single dimension variables
check_coord_raster=false(size(check_coord_names));% check variables describing regular mesh (raster coordinates), from two values, min and max.
if check_var
    for ivar=find(check_coord_names)
        if numel(Data.(Data.ListVarName{ivar}))==2
            check_coord_raster(ivar)=true;
        end
    end
else
    for ivar=find(check_coord_names)
        DimIndex=find(strcmp(Data.VarDimName{ivar},Data.ListDimName));
        if Data.DimValue(DimIndex)==2
            check_coord_raster(ivar)=true;
        end
    end
end

%% initate cells around each scalar field (coordinates willl be sought later)
DimCell=cell(1:numel(ind_scalar)+numel(ind_vector_x)+numel(ind_tabledata));
CellInfo=cell(1:numel(ind_scalar)+numel(ind_vector_x));
for iscalar=1:numel(ind_scalar) 
    ind_var=ind_scalar(iscalar);% index of the scalar variable in the list ListVarName
    check_used(ind_var)=true;
    icell=[];
    for iprev=1:numel(ind_scalar)
        if isequal(DimCell{iprev},Data.VarDimName{ind_var})% the scalar has the same coordinates as a previous one, do not create a new cell
            icell=iprev;
            break
        end
    end
    if isempty(icell)% new cell
        CellInfo{iscalar}.FieldName=Data.ListVarName{ind_var};
        CellInfo{iscalar}.VarType='scalar';
        CellInfo{iscalar}.VarIndex_scalar=ind_var;
        CellInfo{iscalar}.VarIndex=ind_var;
        DimCell{iscalar}=Data.VarDimName{ind_var};
    else % complement previous cell with the scalar
        CellInfo{iprev}.VarIndex_scalar=[CellInfo{iprev}.VarIndex_scalar ind_var];
        CellInfo{iprev}.VarIndex=[CellInfo{iprev}.VarIndex ind_var];
    end
end

%% initate cells around each vector component x and include other vector components and possible 'color' ancillary scalar (coordinates willl be sought later) 
for index_list=1:numel(ind_vector_x)
    ind_var=ind_vector_x(index_list);% index of the vector_x variable in the list ListVarName
    check_used(ind_var)=true;
    icell=[];
    for iprev=numel(ind_scalar)+1:numel(ind_scalar)+numel(ind_vector_x)% look for previous cells of vectors with the same dimensions
        if isequal(DimCell{iprev},Data.VarDimName{ind_var})
            icell=iprev;
            break
        end
    end
    if isempty(icell)% new cell
        newcell_index=numel(ind_scalar)+index_list;
        CellInfo{newcell_index}.VarType='vector';   
        CellInfo{newcell_index}.VarIndex=ind_var;
        CellInfo{newcell_index}.VarIndex_vector_x=ind_var;
        DimCell{newcell_index}=Data.VarDimName{ind_var};
        %look for vector y component
        CellInfo{newcell_index}.VarIndex_vector_y=[];
        for index_list_y=1:numel(ind_vector_y)
            if isequal(Data.VarDimName{ind_vector_y(index_list_y)},DimCell{newcell_index})
                  CellInfo{newcell_index}.VarIndex_vector_y=[CellInfo{newcell_index}.VarIndex_vector_y ind_vector_y(index_list_y)];
                  CellInfo{newcell_index}.VarIndex=[CellInfo{newcell_index}.VarIndex ind_vector_y(index_list_y)];
            end
        end
          %look for vector z component
         CellInfo{newcell_index}.VarIndex_vector_z=[];
        for index_list_z=1:numel(ind_vector_z)
            if isequal(Data.VarDimName{ind_vector_z(index_list_z)},DimCell{newcell_index})
                  CellInfo{newcell_index}.VarIndex_vector_z=[CellInfo{newcell_index}.VarIndex_vector_z ind_vector_z(index_list_z)];
                  CellInfo{newcell_index}.VarIndex=[CellInfo{newcell_index}.VarIndex ind_vector_z(index_list_z)];
            end
        end
          %look for associated ancillary vector color scalar (not projected or interpolated)
        CellInfo{newcell_index}.VarIndex_ancillary=[];
        for index_list_c=1:numel(ind_ancillary)
            if isequal(Data.VarDimName{ind_ancillary(index_list_c)},DimCell{newcell_index})
                  CellInfo{newcell_index}.VarIndex_ancillary=[CellInfo{newcell_index}.VarIndex_ancillary ind_ancillary(index_list_c)];
                  CellInfo{newcell_index}.VarIndex=[CellInfo{newcell_index}.VarIndex ind_ancillary(index_list_c)];
            end
        end
    else
        CellInfo{iprev}.VarIndex=[CellInfo{icell}.VarIndex ind_var];
        if isfield(CellInfo{iprev},'VarIndex_vector_x')% add the vector_x component to the previous cell
            CellInfo{iprev}.VarIndex_vector_x=[CellInfo{newcell_index}.VarIndex_vector_x ind_var];
        else
            CellInfo{iprev}.VarIndex_vector_x=ind_var;
        end
    end
end

%% initate cells grouping data for table display
for index_list=1:numel(ind_tabledata)
    ind_var=ind_tabledata(index_list);% index of the table variable in the list ListVarName
    check_used(ind_var)=true;
    icell=[];
    for iprev=numel(ind_scalar)+numel(ind_vector_x)+1:numel(DimCell)% look for previous cells of vectors with the same dimensions
        if ~isempty(DimCell{iprev})&& isequal(DimCell{iprev}{1},Data.VarDimName{ind_var}{1})% the scalar has the same nbre of rows than a previous one, do not create a new cell
            icell=iprev;
            break
        end
    end
    newcell_index=numel(ind_scalar)+numel(ind_vector_x)+index_list;
    if isempty(icell)% new cell
        CellInfo{newcell_index}.VarType='tabledata';
        CellInfo{newcell_index}.VarIndex_tabledata=ind_var;
        CellInfo{newcell_index}.VarIndex=ind_var;
        DimCell{newcell_index}=Data.VarDimName{ind_var};
    else % complement previous cell with the data
        CellInfo{iprev}.VarIndex_tabledata=[CellInfo{iprev}.VarIndex_tabledata ind_var];
        CellInfo{iprev}.VarIndex=[CellInfo{iprev}.VarIndex ind_var];
    end
end

%% suppress empty cells
emptyCells = cellfun(@isempty,CellInfo);
CellInfo(emptyCells)=[];
DimCell(emptyCells)=[];

%% look for the associated errorflag
for index_list=1:numel(ind_errorflag)
    ind_var=ind_errorflag(index_list);
    for icell=1:numel(DimCell)
        if isequal(DimCell{icell},Data.VarDimName{ind_var})
             CellInfo{icell}.VarIndex=[CellInfo{icell}.VarIndex ind_var];
             CellInfo{icell}.VarIndex_errorflag=ind_var;% allows only one errorflag per cell
              check_used(ind_var)=true;
            break
        end
    end
end

%% find coordinates for each cell around field variables, scalars or vectors
NbDim=zeros(1,numel(CellInfo));%default
for icell=1:numel(CellInfo)
    CellInfo{icell}.CoordType='';
    if ~strcmp(CellInfo{icell}.VarType,'tabledata')
        ind_var=CellInfo{icell}.VarIndex(1);
        DimCell_var=Data.VarDimName{ind_var};% cell of dimension names for ivar_coord_x(icell)
        if ~check_var
            for idim=1:numel(DimCell_var)
                CellInfo{icell}.DimIndex(idim)=find(strcmp(DimCell_var{idim},Data.ListDimName));
            end
        end
        %look for z scattered coordinates
        if isempty(ind_coord_z)
            NbDim(icell)=2;
            CellInfo{icell}.CoordIndex=[0 0];
        else
            NbDim(icell)=3;
            CellInfo{icell}.CoordIndex=[0 0 0];
            for ivar=ind_coord_z
                DimCell=Data.VarDimName{ivar};
                if isequal(DimCell,DimCell_var)
                    CellInfo{icell}.CoordType='scattered';
                    CellInfo{icell}.CoordIndex(1)=ivar;
                    CellInfo{icell}.ZName=Data.ListVarName{ivar};
                    CellInfo{icell}.ZIndex=ivar;
                    check_used(ivar)=true;
                    break
                else
                    CellInfo{icell}.CoordIndex(1)=[]; % coord_z is only a label of a plane, not a coordinate 
                    NbDim(icell)=2;
                end
            end
        end
        % look for y coordinate
        for ivar=ind_coord_y
            % detect scattered y coordinates, variable with the same dimension(s) as the field variable considered
            DimCell=Data.VarDimName{ivar};
            if isequal(DimCell,DimCell_var)
                CellInfo{icell}.CoordType='scattered';
                CellInfo{icell}.CoordIndex(NbDim(icell)-1)=ivar;
                CellInfo{icell}.YName=Data.ListVarName{ivar};
                CellInfo{icell}.YIndex=ivar;
                check_used(ivar)=true;
                break
            end

        end

        %look for x coordinates
        if strcmp(CellInfo{icell}.CoordType,'scattered')
            for ivar=ind_coord_x
                DimCell=Data.VarDimName{ivar};
                if isequal(DimCell,DimCell_var)
                    CellInfo{icell}.CoordIndex(NbDim(icell))=ivar;
                    CellInfo{icell}.XName=Data.ListVarName{ivar};
                    CellInfo{icell}.XIndex=ivar;
                    check_used(ivar)=true;
                    break
                end
            end
        end
        if isfield(CellInfo{icell},'ZName')
            if isfield(CellInfo{icell},'YName')&& isfield(CellInfo{icell},'XName')
                continue %scattered coordinates OK
            end
        else
            if isfield(CellInfo{icell},'YName')
                if isfield(CellInfo{icell},'XName')
                    NbDim(icell)=2;
                    continue %scattered coordinates OK
                end
            else
                if isfield(CellInfo{icell},'XName') % only one coordinate x, switch vector field to 1D plot
                    for ind=1:numel(CellInfo{icell}.VarIndex)
                        Role{CellInfo{icell}.VarIndex(ind)}='coord_y';
                    end
                    continue
                end
            end
        end

        %look for grid  coordinates
        if isempty(CellInfo{icell}.CoordType)
            NbDim(icell)=numel(DimCell_var);
            CellInfo{icell}.DimOrder=[];
            if NbDim(icell)==3
                if strcmp(DimCell_var{3},'rgb')
                    NbDim(icell)=2;% case of color images
                else
                    %coord z
                    for ivar=ind_coord_z
                        if check_coord_names(ivar)
                            DimRank=find(strcmp(Data.VarDimName{ivar},DimCell_var));
                            check_coord=~isempty(DimRank);
                        elseif check_coord_raster(ivar)
                            DimRank=find(strcmp(Data.ListVarName{ivar},DimCell_var));
                            check_coord=~isempty(DimRank);
                        end
                        if check_coord
                            CellInfo{icell}.CoordType='grid';
                            CellInfo{icell}.CoordIndex(1)=ivar;
                            CellInfo{icell}.ZName=Data.ListVarName{ivar};
                            CellInfo{icell}.ZIndex=ivar;
                            CellInfo{icell}.DimOrder=DimRank;
                            check_used(ivar)=true;
                            break
                        end
                    end
                end
            end
            for ivar=ind_coord_y
                if check_coord_names(ivar)
                    DimRank=find(strcmp(Data.VarDimName{ivar},DimCell_var));
                    check_coord=~isempty(DimRank);
                elseif check_coord_raster(ivar)
                    DimRank=find(strcmp(Data.ListVarName{ivar},DimCell_var));
                    check_coord=~isempty(DimRank);
                end
                if check_coord
                    CellInfo{icell}.CoordType='grid';
                    CellInfo{icell}.CoordIndex(NbDim(icell)-1)=ivar;
                    CellInfo{icell}.YName=Data.ListVarName{ivar};
                    CellInfo{icell}.YIndex=ivar;
                    CellInfo{icell}.DimOrder=[CellInfo{icell}.DimOrder DimRank];
                    check_used(ivar)=true;
                    break
                end
            end
            for ivar=ind_coord_x
                if check_coord_names(ivar)
                    DimRank=find(strcmp(Data.VarDimName{ivar},DimCell_var));
                    check_coord=~isempty(DimRank);
                elseif check_coord_raster(ivar)
                    DimRank=find(strcmp(Data.ListVarName{ivar},DimCell_var));
                    check_coord=~isempty(DimRank);
                end
                if check_coord
                    CellInfo{icell}.CoordIndex(NbDim(icell))=ivar;
                    CellInfo{icell}.XName=Data.ListVarName{ivar};
                    CellInfo{icell}.XIndex=ivar;
                    CellInfo{icell}.DimOrder=[CellInfo{icell}.DimOrder DimRank];
                    check_used(ivar)=true;
                    break
                end
            end
        end
        %look for tps coordinates
        for ivar=ind_coord_tps
            DimCell=Data.VarDimName{ivar};
            if  numel(DimCell)==3 && strcmp(DimCell{1},DimCell_var{1})
                CellInfo{icell}.CoordType='tps';
                CellInfo{icell}.CoordIndex=ivar;
                check_used(ivar)=true;
                if check_var
                    NbDim(icell)=size(Data.(Data.ListVarName{ivar}),2);
                else
                    DimIndex=find(strcmp(Data.VarDimName{ivar}{2},Data.ListDimName));
                    NbDim(icell)= Data.DimValue(DimIndex);
                end
                for ivardim=1:numel(Data.VarDimName)
                    if strcmp(Data.VarDimName{ivardim},DimCell{3})
                        CellInfo{icell}.NbCentres_tps= ivardim;% nbre of sites for each tps subdomain
                    elseif strcmp(Data.VarDimName{ivardim}{1},DimCell{2}) && numel(Data.VarDimName{ivardim})>=3 && strcmp(Data.VarDimName{ivardim}{3},DimCell{3})
                        CellInfo{icell}.SubRange_tps=ivardim;% subrange definiton for tps
                    end
                end
            end
            break
        end
    end
end

%% get number of coordinate points for each cell
if check_var
    for icell=1:numel(CellInfo)
        switch CellInfo{icell}.CoordType
            case 'scattered'
                CellInfo{icell}.CoordSize=numel(Data.(CellInfo{icell}.XName));
            case 'grid'
                VarName=Data.ListVarName{CellInfo{icell}.VarIndex(1)};
                if NbDim(icell)==3
                    CellInfo{icell}.CoordSize=[size(Data.(VarName),3) size(Data.(VarName),2) size(Data.(VarName),1)];
                else
                    CellInfo{icell}.CoordSize=[size(Data.(VarName),1) size(Data.(VarName),2)];
                end
            case 'tps'
                NbDim(icell)=size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),2);
                CellInfo{icell}.CoordSize=size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),1);
        end
    end
else
    for icell=1:numel(CellInfo)
        CellInfo{icell}.CoordSize=size(Data.DimValue(CellInfo{icell}.DimIndex));
    end
end


%% cell for ordinary plots: look for coord_x not included in scalar or vector cells
iremove=false(1,numel(ind_coord_y));
for ilist=1:numel(ind_coord_y)% remove the y coordinates which have been used already in scalar or vector fields
    for icell=1:numel(CellInfo)
        if isfield(CellInfo{icell},'YIndex')&& isequal(CellInfo{icell}.YIndex,ind_coord_y(ilist))
            iremove(ilist)=true;
            continue
        end
    end
end
ind_coord_y(iremove)=[];
if ~isempty(ind_coord_x)
    check_discrete_ordinate=false(1,numel(ind_discrete));
    Cell1DPlot=cell(1,numel(ind_coord_x));
    y_nbre=zeros(1,numel(ind_coord_x));
    for icell=1:numel(ind_coord_x)
        Cell1DPlot{icell}.VarType='1DPlot';
        Cell1DPlot{icell}.XIndex=ind_coord_x(icell);
        Cell1DPlot{icell}.XName=Data.ListVarName{ind_coord_x(icell)};
        Cell1DPlot{icell}.YIndex=[];
        Cell1DPlot{icell}.YIndex_discrete=[];
        DimCell_x=Data.VarDimName{ind_coord_x(icell)};
        for ivar=[ind_coord_y ind_histo]% look for y coordinate corresponding to coord_x
            DimCell=Data.VarDimName{ivar};%dimensions of coord_y
            if  isscalar(DimCell_x) && strcmp(DimCell_x{1},DimCell{1})
                y_nbre(icell)=y_nbre(icell)+1;
                Cell1DPlot{icell}.YIndex(y_nbre(icell))=ivar;
            end
        end
        for ilist=1:numel(ind_discrete)
            ivar=ind_discrete(ilist);
            DimCell=Data.VarDimName{ivar};
            if  strcmp(DimCell_x{1},DimCell{1})
                y_nbre(icell)=y_nbre(icell)+1;
                Cell1DPlot{icell}.YIndex_discrete(y_nbre(icell))=ivar;
                      check_used(ivar)=true;
                      check_discrete_ordinate(ilist)=true;
            end
        end
    end
    Cell1DPlot(y_nbre==0)=[];
    CellInfo=[CellInfo Cell1DPlot];
    NbDim=[NbDim ones(1,numel(Cell1DPlot))];
end


%% document roles of non-coordinate variables
for icell=1:numel(CellInfo)
    if isfield(CellInfo{icell},'VarIndex')
        check_fieldname=0;
        VarIndex=CellInfo{icell}.VarIndex;
        for ivar=VarIndex        
            if ~isempty(ProjModeRequest{ivar})
                CellInfo{icell}.ProjModeRequest=ProjModeRequest{ivar};
            end
            if ~isempty(FieldName{ivar})
                CellInfo{icell}.FieldName=FieldName{ivar};
                check_fieldname=1;
            end
            if CheckSub(ivar)==1
                CellInfo{icell}.CheckSub=1;
            end
        end
        if ~check_fieldname% default FieldName
            if isfield(CellInfo{icell},'VarIndex_vector_x')&& isfield(CellInfo{icell},'VarIndex_vector_y')
                UName=Data.ListVarName{CellInfo{icell}.VarIndex_vector_x};
                VName=Data.ListVarName{CellInfo{icell}.VarIndex_vector_y};        
                CellInfo{icell}.FieldName=['vec(' UName ',' VName ')'];
            end
        end
    end
end



