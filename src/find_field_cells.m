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
% Copyright 2008-2018, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

%    group the variables  into 'fields' with common dimensions

function [CellInfo,NbDim,errormsg]=find_field_cells(Data)
CellInfo={};%default output
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
        check_var=0;% dimensions of array defined, but the corresponding array is not given
        break
    end
end

%% role of variables and list of requested operations
%ListRole={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','vector_x_tps','vector_y_tps','warnflag','errorflag',...
%   'ancillary','image','color','discrete','scalar','coord_tps'};% rmq vector_x_tps and vector_y_tps to be replaced by vector_x and vector_y
Role=num2cell(blanks(nbvar));%initialize a cell array of nbvar blanks
ProjModeRequest=regexprep(Role,' ',''); % fieldRequest set to '' by default
FieldName=cell(size(Role)); % fieldRequest set to {} by default
CheckSub=zeros(size(Role));% =1 for fields to substract
%Role=regexprep(Role,' ','scalar'); % Role set to 'scalar' by default
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
ind_image=find(strcmp('image',Role));
ind_vector_x=[find(strcmp('vector_x',Role)) find(strcmp('vector_x_tps',Role))];
if ~isempty(ind_vector_x)
    ind_vector_y=[find(strcmp('vector_y',Role)) find(strcmp('vector_y_tps',Role))];
    ind_vector_z=find(strcmp('vector_z',Role));
    ind_warnflag=find(strcmp('warnflag',Role));
    ind_ancillary=find(strcmp('ancillary',Role));
end
ind_discrete=find(strcmp('discrete',Role));
ind_coord_x=find(strcmp('coord_x',Role));
ind_coord_y=find(strcmp('coord_y',Role));
ind_coord_z=find(strcmp('coord_z',Role));
ind_coord_tps=find(strcmp('coord_tps',Role));
check_string=cellfun(@ischar,Data.VarDimName)==1;
index_string=find(check_string);
for ivar=index_string
    Data.VarDimName{ivar}={Data.VarDimName{ivar}};%transform char strings into cells
end
check_coord_names= cellfun(@numel,Data.VarDimName)==1;
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


%% initate cells around each scalar field
index_remove=[];
cell_nbre=numel(ind_scalar)+numel(ind_vector_x);
flag_remove=false(1,cell_nbre);
NbDim=zeros(1,cell_nbre);
index_coord_x=zeros(size(ind_coord_x));
for icell=1:numel(ind_scalar)
    CellInfo{icell}.VarType='scalar';
    CellInfo{icell}.VarIndex_scalar=ind_scalar(icell);
    CellInfo{icell}.VarIndex=ind_scalar(icell);
    DimCell_var=Data.VarDimName{ind_scalar(icell)};% cell of dimension names for ivar_coord_x(icell)
    %look for errorflag
    for ivar=ind_errorflag
        DimCell=Data.VarDimName{ivar};
        if isequal(DimCell,DimCell_var)
            CellInfo{icell}.VarIndex(2)=ivar;
            CellInfo{icell}.VarIndex_errorflag=ivar;
            break
        end
    end
end

%% initate cells around each vector field
for icell=numel(ind_scalar)+1:cell_nbre
    CellInfo{icell}.VarType='vector';
    CellInfo{icell}.VarIndex(1)=ind_vector_x(icell-numel(ind_scalar));
    CellInfo{icell}.VarIndex_vector_x=ind_vector_x(icell-numel(ind_scalar));
    DimCell_var=Data.VarDimName{ind_vector_x(icell-numel(ind_scalar))};% cell of dimension names for ivar_coord_x(icell)
    % look for the associated y vector component
    nbvar=1;
    for ivar=ind_vector_y
        DimCell=Data.VarDimName{ivar};
        if isequal(DimCell,DimCell_var)
            CellInfo{icell}.VarIndex(2)=ivar;
            nbvar=2;
            CellInfo{icell}.VarIndex_vector_y=ivar;
            break
        end
    end
    if ~isfield(CellInfo{icell},'VarIndex_vector_y')
        flag_remove(icell)=true;% no vector_y found , mark cell to remove
    end
    % look for the associated z vector component
    for ivar=ind_vector_z
        DimCell=Data.VarDimName{ivar};
        if isequal(DimCell,DimCell_var)
            CellInfo{icell}.VarIndex(3)=ivar;
            nbvar=3;
            break
        end
    end
    %look for the vector color scalar (ancillary)
    for ivar=ind_ancillary
        DimCell=Data.VarDimName{ivar};
        if isequal(DimCell,DimCell_var)
            nbvar=nbvar+1;
            CellInfo{icell}.VarIndex(nbvar)=ivar;
            CellInfo{icell}.VarIndex_ancillary=ivar;
            break
        end
    end
    %look for warnflag
    for ivar=ind_warnflag
        DimCell=Data.VarDimName{ivar};
        if isequal(DimCell,DimCell_var)
            nbvar=nbvar+1;
            CellInfo{icell}.VarIndex(nbvar)=ivar;
            CellInfo{icell}.VarIndex_warnflag=ivar;
            break
        end
    end
    %look for errorflag
    for ivar=ind_errorflag
        DimCell=Data.VarDimName{ivar};
        if isequal(DimCell,DimCell_var)
            nbvar=nbvar+1;
            CellInfo{icell}.VarIndex(nbvar)=ivar;
            CellInfo{icell}.VarIndex_errorflag=ivar;
            break
        end
    end
end

%% find coordinates for each cell around field variables, scalars or vectors
for icell=1:cell_nbre
    CellInfo{icell}.CoordType='';
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
                break
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
            if isfield(CellInfo{icell},'XName'); % only one coordinate x, switch vector field to 1D plot
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
            %coord z
            for ivar=ind_coord_z
                if check_coord_names(ivar)
                    DimRank=find(strcmp(Data.VarDimName{ivar},DimCell_var));
                check_coord=~isempty(DimRank);
            elseif check_coord_raster(ivar)
                DimRank=find(strcmp(Data.ListVarName{ivar},DimCell_var));
                check_coord=~isempty(DimRank);
            end
%                 check_coord= (check_coord_names(ivar) && strcmp(Data.VarDimName{ivar},DimCell_var{1}))||...% coord varbable
%                     (check_coord_raster(ivar) && strcmp(Data.ListVarName{ivar},DimCell_var{1})); % rasrewr coord defined by min and max
                if check_coord
                    CellInfo{icell}.CoordType='grid';
                    CellInfo{icell}.CoordIndex(1)=ivar;
                    CellInfo{icell}.ZName=Data.ListVarName{ivar};
                    CellInfo{icell}.ZIndex=ivar;
                    CellInfo{icell}.DimOrder=DimRank;
                    break
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
%             check_coord= (check_coord_names(ivar) && strcmp(Data.VarDimName{ivar},DimCell_var{NbDim(icell)-1}))||...% coord variable
%                 (check_coord_raster(ivar) && strcmp(Data.ListVarName{ivar},DimCell_var{NbDim(icell)-1})); % rasrewr coord defined by min and max
            if check_coord
                CellInfo{icell}.CoordType='grid';
                CellInfo{icell}.CoordIndex(NbDim(icell)-1)=ivar;
                CellInfo{icell}.YName=Data.ListVarName{ivar};
                CellInfo{icell}.YIndex=ivar;
                CellInfo{icell}.DimOrder=[CellInfo{icell}.DimOrder DimRank];
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
%             check_coord= (check_coord_names(ivar) && strcmp(Data.VarDimName{ivar},DimCell_var{NbDim(icell)}))||...% coord variable
%                 (check_coord_raster(ivar) && strcmp(Data.ListVarName{ivar},DimCell_var{NbDim(icell)})); % raster coord defined by min and max
            if check_coord
                CellInfo{icell}.CoordIndex(NbDim(icell))=ivar;
                CellInfo{icell}.XName=Data.ListVarName{ivar};
                CellInfo{icell}.XIndex=ivar;
                CellInfo{icell}.DimOrder=[CellInfo{icell}.DimOrder DimRank];
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
            if check_var
                NbDim(icell)=size(Data.(Data.ListVarName{ivar}),2);
            else
                DimIndex=find(strcmp(Data.VarDimName{ivar},Data.ListDimName));
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

%% get number of coordinate points for each cell
if check_var
    for icell=1:numel(CellInfo)
        switch CellInfo{icell}.CoordType
            case 'scattered'
                CellInfo{icell}.CoordSize=numel(Data.(CellInfo{icell}.XName));
            case 'grid'
                if NbDim(icell)==3
                    CellInfo{icell}.CoordSize=[numel(Data.(CellInfo{icell}.XName)) numel(Data.(CellInfo{icell}.YName)) numel(Data.(CellInfo{icell}.YName))];
                else
                    CellInfo{icell}.CoordSize=[numel(Data.(CellInfo{icell}.XName)) numel(Data.(CellInfo{icell}.YName))];
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
%
% %% loop on the tps coordinate sets
%
%     for icell_tps=1:numel(ind_coord_tps)
%         check_cell=zeros(1,nbvar);% =1 for the variables selected in the current cell
%         check_cell(ivar_tps(icell_tps))=1;% mark the coordinate variable as selected
%         DimCell=Data.VarDimName{ivar_tps(icell_tps)};% dimension names for the current tps coordinate variable
%         icell=numel(CellInfo)+icell_tps; % new field cell index
%         CellInfo{icell}.CoordIndex=ivar_tps(icell_tps);% index of the  tps coordinate variable
%         if numel(DimCell)==3
%             VarDimName=Data.VarDimName(~check_select);
%             for ivardim=1:numel(VarDimName)
%                 if strcmp(VarDimName{ivardim},DimCell{3})
%                     CellInfo{icell}.NbCentres_tps= ivar_remain(ivardim);% nbre of sites for each tps subdomain
%                     check_cell(ivar_remain(ivardim))=1;% mark the variable as selected
%                 elseif strcmp(VarDimName{ivardim}{1},DimCell{2}) && numel(VarDimName{ivardim})>=3 && strcmp(VarDimName{ivardim}{3},DimCell{3})
%                     CellInfo{icell}.SubRange_tps=ivar_remain(ivardim);% subrange definiton for tps
%                     check_cell(ivar_remain(ivardim))=1;% mark the variable as selected
%                 elseif strcmp(VarDimName{ivardim}{1},DimCell{1}) && strcmp(VarDimName{ivardim}{2},DimCell{3})% variable
%                     check_cell(ivar_remain(ivardim))=1;% mark the variable as selected
%                 end
%             end
%         end
%         CellInfo{icell}.CoordType='tps';
%         CellInfo{icell}.VarIndex=find(check_cell);
%         if check_var
%             NbDim(icell)=size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),2);
%             CellInfo{icell}.CoordSize=size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),1)*size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),3);
%         else
%             check_index_1= strcmp(DimCell{1},Data.ListDimName);
%             check_index_2= strcmp(DimCell{2},Data.ListDimName);
%             NbDim(icell)=Data.DimValue(check_index_2);
%             if numel(DimCell)>=3
%                 check_index_3= strcmp(DimCell{3},Data.ListDimName);
%                 CellInfo{icell}.CoordSize=Data.DimValue(check_index_1)*Data.DimValue(check_index_3);
%             end
%         end
%         check_select=check_select|check_cell;
%     end


%% cell for ordinary plots
iremove=false(1,numel(ind_coord_y));
for ilist=1:numel(ind_coord_y)% remove the y coordinates which have been used yet in scalar or vector fields
    for icell=1:numel(CellInfo)
        if isfield(CellInfo{icell},'YIndex')&& isequal(CellInfo{icell}.YIndex,ind_coord_y(ilist))
            iremove(ilist)=true;
            continue
        end
    end
end
ind_coord_y(iremove)=[];
if ~isempty(ind_coord_x)
    y_nbre=zeros(1,numel(ind_coord_x));
    for icell=1:numel(ind_coord_x)
        Cell1DPlot{icell}.VarType='1DPlot';
        Cell1DPlot{icell}.XIndex=ind_coord_x(icell);
        Cell1DPlot{icell}.XName=Data.ListVarName{ind_coord_x(icell)};
        DimCell_x=Data.VarDimName{ind_coord_x(icell)};
        for ivar=[ind_coord_y ind_discrete]
            DimCell=Data.VarDimName{ivar};
            if  numel(DimCell)==1 && strcmp(DimCell_x{1},DimCell{1})
                y_nbre(icell)=y_nbre(icell)+1;
                Cell1DPlot{icell}.YIndex(y_nbre(icell))=ivar;
                break
            end
        end
    end
    Cell1DPlot(find(y_nbre==0))=[];
    CellInfo=[CellInfo Cell1DPlot];
    NbDim=[NbDim ones(1,numel(Cell1DPlot))];
end

%% document roles of non-coordinate variables
for icell=1:numel(CellInfo)
    if isfield(CellInfo{icell},'VarIndex')
        VarIndex=CellInfo{icell}.VarIndex;
        for ivar=VarIndex
            %         if isfield(CellInfo{icell},['VarIndex_' Role{ivar}])
            %             CellInfo{icell}.(['VarIndex_' Role{ivar}])=[CellInfo{icell}.(['VarIndex_' Role{ivar}]) ivar];
            %         else
            %             CellInfo{icell}.(['VarIndex_' Role{ivar}])= ivar;
            %         end
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
end
% for icell=ind_coord_tps
%     VarIndex=CellInfo{icell}.VarIndex;
%     for ivar=VarIndex
%         if isfield(CellInfo{icell},['VarIndex_' Role{ivar}])
%             CellInfo{icell}.(['VarIndex_' Role{ivar}])=[CellInfo{icell}.(['VarIndex_' Role{ivar}]) ivar];
%         else
%             CellInfo{icell}.(['VarIndex_' Role{ivar}])= ivar;
%         end
%         if ~isempty(ProjModeRequest{ivar})
%             CellInfo{icell}.ProjModeRequest=ProjModeRequest{ivar};
%         end
%         if ~isempty(FieldName{ivar})
%             CellInfo{icell}.FieldName=FieldName{ivar};
%         end
%         if CheckSub(ivar)==1
%             CellInfo{icell}.CheckSub=1;
%         end
%     end
% end



% 
% %% analyse vector fields
% if ~isempty(ind_vector_x) && ~isempty(ind_vector_y)
%     if numel(ind_vector_x)>1
%         errormsg='multiply defined vector x component'
%         return
%     end
%     DimCell_vec=Data.VarDimName{ind_vector_x};% cell of dimension names for ivar_coord_x(icell)
%     if ischar(DimCell),DimCell={DimCell};end % transform char to cell for a single dimension
%     DimCell_y=Data.VarDimName{ind_vector_y};% cell of dimension names for ivar_coord_x(icell)
%     if ischar(DimCell_y),DimCell_y={DimCell_y};end % transform char to cell for a single dimension
%     if ~isequal(DimCell,DimCell_y)
%         errormsg='inconsistent x and y vector components';
%         return
%     end
%     %look for coordinates
%     for ivar=ind_coord_y
%         DimCell=Data.VarDimName{ivar};
%         if ischar(DimCell),DimCell={DimCell};end % transform char to cell for a single dimension
%         if isequal(DimCell,DimCell_vec)
%             CoordType='scattered';
%             coordy=ivar;
%         else
%             if isempty(ind_coord_z) && strcmp(DimCell{1},DimCell_vec{1})
%                 CoordType='grid';
%                 coordy=ivar;
%             elseif ~isempty(ind_coord_z) && strcmp(DimCell{1},DimCell_vec{2})
%                 CoordType='grid';
%                 coordy=ivar;
%                 coordz=ind_coord_z;
%             end
%         end
%         
%         %% find scattered (unstructured) coordinates
%         ivar_coord_x=find(strcmp('coord_x',Role));%find variables with Role='coord_x'
%         check_select=false(1,nbvar);
%         check_coord=false(1,nbvar);
%         CellInfo=cell(1,numel(ivar_coord_x));
%         NbDim=zeros(1,numel(ivar_coord_x));
%         % loop on unstructured coordinate x -> different field cells
%         for icell=1:numel(ivar_coord_x)
%             DimCell=Data.VarDimName{ivar_coord_x(icell)};% cell of dimension names for ivar_coord_x(icell)
%             if ischar(DimCell),DimCell={DimCell};end % transform char to cell for a single dimension
%             % look for variables sharing dimension(s) with ivar_coord_x(icell)
%             check_cell=zeros(numel(DimCell),nbvar);
%             for idim=1:numel(DimCell);% for each variable with role coord_x, look at which other variables contain the same dimension
%                 for ivar=1:nbvar
%                     check_cell(idim,ivar)=max(strcmp(DimCell{idim},Data.VarDimName{ivar}));
%                 end
%             end
%             check_cell=sum(check_cell,1)==numel(DimCell);%logical array=1 for variables belonging to the current cell
%             VarIndex=find(check_cell);% list of detected variable indices
%             if ~(numel(VarIndex)==1 && numel(DimCell)==1)% exclude case of isolated coord_x variable (treated later)
%                 if ~(numel(VarIndex)==1 && numel(DimCell)>1)% a variable is associated to coordinate
%                     CellInfo{icell}.CoordIndex=ivar_coord_x(icell);
%                     % size of coordinate var
%                     if check_var
%                         CellInfo{icell}.CoordSize=numel(Data.(Data.ListVarName{ivar_coord_x(icell)}));
%                     else
%                         for idim=1:numel(DimCell)
%                             check_index= strcmp(DimCell{idim},Data.ListDimName);
%                             CellInfo{icell}.CoordSize(idim)=Data.DimValue(check_index);
%                         end
%                         CellInfo{icell}.CoordSize=prod(CellInfo{icell}.CoordSize);
%                     end
%                     %             ind_scalar=find(strcmp('scalar',Role(VarIndex)));
%                     %             ind_vector_x=find(strcmp('vector_x',Role(VarIndex)));
%                     %             ind_vector_y=find(strcmp('vector_y',Role(VarIndex)));
%                     ind_y=find(strcmp('coord_y',Role(VarIndex)));
%                     if numel([ind_scalar ind_vector_x ind_vector_y])==0
%                         %             if numel(VarIndex)==2||isempty(ind_y)% no variable, except possibly y
%                         NbDim(icell)=1;
%                     else
%                         CellInfo{icell}.CoordType='scattered';
%                         ind_z=find(strcmp('coord_z',Role(VarIndex)));
%                         if numel(VarIndex)==3||isempty(ind_z)% no z variable, except possibly as a fct z(x,y)
%                             CellInfo{icell}.CoordIndex=[VarIndex(ind_y) CellInfo{icell}.CoordIndex];
%                             NbDim(icell)=2;
%                         else
%                             CellInfo{icell}.CoordIndex=[VarIndex(ind_z) CellInfo{icell}.CoordIndex];
%                             NbDim(icell)=3;
%                         end
%                     end
%                 end
%                 CellInfo{icell}.VarIndex=VarIndex;
%                 check_select=check_select|check_cell;
%             end
%         end
%         
%         %% look for tps coordinates
%         ivar_remain=find(~check_select);% indices of remaining variables (not already selected)
%         check_coord_tps= strcmp('coord_tps',Role(~check_select));
%         ivar_tps=ivar_remain(check_coord_tps);% variable indices corresponding to tps coordinates
%         
%         % loop on the tps coordinate sets
%         for icell_tps=1:numel(ivar_tps)
%             check_cell=zeros(1,nbvar);% =1 for the variables selected in the current cell
%             check_cell(ivar_tps(icell_tps))=1;% mark the coordinate variable as selected
%             DimCell=Data.VarDimName{ivar_tps(icell_tps)};% dimension names for the current tps coordinate variable
%             icell=numel(CellInfo)+icell_tps; % new field cell index
%             CellInfo{icell}.CoordIndex=ivar_tps(icell_tps);% index of the  tps coordinate variable
%             if numel(DimCell)==3
%                 VarDimName=Data.VarDimName(~check_select);
%                 for ivardim=1:numel(VarDimName)
%                     if strcmp(VarDimName{ivardim},DimCell{3})
%                         CellInfo{icell}.NbCentres_tps= ivar_remain(ivardim);% nbre of sites for each tps subdomain
%                         check_cell(ivar_remain(ivardim))=1;% mark the variable as selected
%                     elseif strcmp(VarDimName{ivardim}{1},DimCell{2}) && numel(VarDimName{ivardim})>=3 && strcmp(VarDimName{ivardim}{3},DimCell{3})
%                         CellInfo{icell}.SubRange_tps=ivar_remain(ivardim);% subrange definiton for tps
%                         check_cell(ivar_remain(ivardim))=1;% mark the variable as selected
%                     elseif strcmp(VarDimName{ivardim}{1},DimCell{1}) && strcmp(VarDimName{ivardim}{2},DimCell{3})% variable
%                         check_cell(ivar_remain(ivardim))=1;% mark the variable as selected
%                     end
%                 end
%             end
%             CellInfo{icell}.CoordType='tps';
%             CellInfo{icell}.VarIndex=find(check_cell);
%             if check_var
%                 NbDim(icell)=size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),2);
%                 CellInfo{icell}.CoordSize=size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),1)*size(Data.(Data.ListVarName{CellInfo{icell}.CoordIndex}),3);
%             else
%                 check_index_1= strcmp(DimCell{1},Data.ListDimName);
%                 check_index_2= strcmp(DimCell{2},Data.ListDimName);
%                 NbDim(icell)=Data.DimValue(check_index_2);
%                 if numel(DimCell)>=3
%                     check_index_3= strcmp(DimCell{3},Data.ListDimName);
%                     CellInfo{icell}.CoordSize=Data.DimValue(check_index_1)*Data.DimValue(check_index_3);
%                 end
%             end
%             check_select=check_select|check_cell;
%         end
%         
%      
%         
%         % determine dimension sizes
%         CoordSize=zeros(size(ListCoordIndex));
%         for ilist=1:numel(ListCoordIndex)
%             if iscell(ListDimName{ilist})
%                 ListDimName(ilist)=ListDimName{ilist};%transform cell to string
%             end
%             if check_var% if the list of dimensions has been directly defined, no variable data available
%                 CoordSize(ilist)=numel(Data.(ListCoordName{ilist}));% number of elements in the variable corresponding to the dimension #ilist
%             else
%                 check_index= strcmp(ListDimName{ilist},Data.ListDimName);% find the  index in the list of dimensions
%                 CoordSize(ilist)=Data.DimValue(check_index);% find the  corresponding dimension value
%             end
%             if CoordSize(ilist)==2% case of uniform grid coordinate defined by lower and upper bounds only
%                 ListDimName{ilist}=ListCoordName{ilist};% replace the dimension name by the coordinate variable name
%             end
%         end
%     end
% end
% 
% 
% 
% %% suppress empty cells or cells with a single coordinate variable 
% check_remove=false(size(CellInfo));
% for icell=1:numel(check_remove)
%     if isempty(CellInfo{icell})||(numel(CellInfo{icell}.VarIndex)==1 && numel(check_coord)>=icell && check_coord(icell))
%         check_remove(icell)=1;
%     end
% end
% CellInfo(check_remove)=[];
% NbDim(check_remove)=[];
% 
% 
