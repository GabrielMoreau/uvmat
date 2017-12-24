%'sub_field': combines two input fields
%
% the two fields are subtstracted when of the same nature (scalar or
% vector), if the coordinates do not coincide, the second field is
% interpolated on the cooridintes of the first one
%
% when scalar and vectors are combined, the fields are just merged in a single matlab structure for common visualisation
%-----------------------------------------------------------------------
% function SubData=sub_field(Field,XmlData,Field_1)
%
% OUTPUT: 
% SubData: structure representing the resulting field
%
% INPUT: 
% Field: matlab structure representing the first field
% Field_1:matlab structure representing the second field

%=======================================================================
% Copyright 2008-2017, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function SubData=sub_field(Field,XmlData,Field_1)

SubData=[];
if strcmp(Field,'*')
    return
end
if nargin<3
    SubData=Field;
    return
end
if ~isfield(Field_1,'VarAttribute')
    Field_1.VarAttribute={};
end

%% global attributes
SubData.ListGlobalAttribute={};%default
%transfer global attributes of Field
if isfield(Field,'ListGlobalAttribute')
    SubData.ListGlobalAttribute=Field.ListGlobalAttribute;
    for ilist=1:numel(Field.ListGlobalAttribute)
        AttrName=Field.ListGlobalAttribute{ilist};
        SubData.(AttrName)=Field.(AttrName);
    end
end
%transfer global attributes of Field_1
if isfield(Field_1,'ListGlobalAttribute')
    for ilist=1:numel(Field_1.ListGlobalAttribute)
        AttrName=Field_1.ListGlobalAttribute{ilist};
        AttrNameNew=AttrName;
        while ~isempty(find(strcmp(AttrNameNew,SubData.ListGlobalAttribute)))&&~isequal(Field_1.(AttrNameNew),Field.(AttrNameNew))
            AttrNameNew=[AttrNameNew '_1'];
        end
        if ~isfield(Field,AttrName) || ~isequal(Field_1.(AttrName),Field.(AttrName))
            SubData.ListGlobalAttribute=[SubData.ListGlobalAttribute {AttrNameNew}];
            SubData.(AttrNameNew)=Field_1.(AttrName);
        end
    end
end

%% variables
%reproduce variables of the first field and list its dimensions
SubData.ListVarName=Field.ListVarName;
SubData.VarDimName=Field.VarDimName;
if isfield(Field,'VarAttribute')
    SubData.VarAttribute=Field.VarAttribute;
end
ListDimName={};
for ilist=1:numel(Field.ListVarName)
    VarName=Field.ListVarName{ilist};
    SubData.(VarName)=Field.(VarName);
    SubData.VarAttribute{ilist}.CheckSub=0;
    DimCell=Field.VarDimName{ilist};
    if ischar(DimCell)
        DimCell={DimCell};
    end
    for idim=1:numel(DimCell)
        if isempty(find(strcmp(DimCell{idim},ListDimName)))
            ListDimName=[ListDimName DimCell(idim)];
        end
    end
end

%% field request
ProjModeRequest=cell(size(Field.ListVarName));
if isfield(Field,'VarAttribute')
for ilist=1:numel(Field.VarAttribute)
    if isfield(Field.VarAttribute{ilist},'ProjModeRequest')
        ProjModeRequest{ilist}=Field.VarAttribute{ilist}.ProjModeRequest;
    end
end
end
ProjModeRequest_1=cell(size(Field_1.ListVarName));
if isfield(Field_1,'VarAttribute')
for ilist=1:numel(Field_1.VarAttribute)
    if isfield(Field_1.VarAttribute{ilist},'ProjModeRequest')
        ProjModeRequest_1{ilist}=Field_1.VarAttribute{ilist}.ProjModeRequest;
    end
end
end

%% rename the dimensions of the second field if identical to those of the first
for ilist=1:numel(Field_1.VarDimName)
    DimCell=Field_1.VarDimName{ilist};
    if ischar(DimCell)
        DimCell={DimCell};
    end
    for idim=1:numel(DimCell)
        ind_dim=find(strcmp(DimCell{idim},ListDimName));
        if ~isempty(ind_dim)
            if ischar(Field_1.VarDimName{ilist})
                Field_1.VarDimName{ilist}=Field_1.VarDimName(ilist);
            end
            Field_1.VarDimName{ilist}{idim}=[ListDimName{ind_dim} '_1'];
        end
    end
end

%% look for coordinates common to Field in Field_1
ind_remove=false(size(Field_1.ListVarName));
% loop on the variables of the second field Field_1
for ilist=1:numel(Field_1.VarAttribute)
    % case of variable with a single dimension
    if ~isempty(Field_1.VarAttribute{ilist}) && isfield(Field_1.VarAttribute{ilist},'Role')&&~isempty(regexp(Field_1.VarAttribute{ilist}.Role,'^coord'))% if variable with Role coord... is found.
        OldDimName=Field_1.VarDimName{ilist};
        if ischar(OldDimName), OldDimName={OldDimName}; end% transform char string to cell if relevant
        if numel(OldDimName)==1
            OldDim=Field_1.(Field_1.ListVarName{ilist});% get variable
            %look for the existence of the variable OldDim in the first field Field
            for i1=1:numel(Field.ListVarName)
                if  isequal(Field.(Field.ListVarName{i1}),OldDim) &&...
                        ((isempty(ProjModeRequest{i1}) && isempty(ProjModeRequest_1{ilist}))  || strcmp(ProjModeRequest{i1},ProjModeRequest_1{ilist}))
                    ind_remove(ilist)=1;
                    NewDimName=Field.VarDimName{i1};
                    if ischar(NewDimName), NewDimName={NewDimName}; end %transform char chain to cell if needed
                    Field_1.VarDimName=regexprep_r(Field_1.VarDimName,['^' OldDimName{1} '$'],NewDimName{1});% change the var name of Field_1 to the corresponding var name of Field
                end
            end
        end
    end
end
if ~isempty(find(ind_remove, 1))
Field_1.ListVarName(ind_remove)=[];%removes the redondent coordinate
Field_1.VarDimName(ind_remove)=[];
Field_1.VarAttribute(ind_remove)=[];
end

%% append the other variables of the second field, modifying their name if needed
ListVarNameSub=Field_1.ListVarName;
ListVarNameNew=ListVarNameSub;
check_rename=zeros(size(ListVarNameSub));
check_remove=zeros(size(ListVarNameSub));
VarDimNameSub=Field_1.VarDimName;
VarAttributeSub={};
if isfield(Field_1,'VarAttribute')&&~isempty(Field_1.VarAttribute)
    for ilist=1:numel(ListVarNameSub)
        ind_prev=find(strcmp(ListVarNameSub{ilist},Field.ListVarName),1);% look for duplicated variable name
        if ~isempty(ind_prev)% variable name exists in Field
            if isfield(Field_1.VarAttribute{ilist},'Role')&&...
                    ismember(Field_1.VarAttribute{ilist}.Role,{'coord_x','coord_y','scalar','vector_x','vector_y','errorflag'})
                ListVarNameNew{ilist}=[ListVarNameSub{ilist} '_1'];%modify the name of the second variable
                check_rename(ilist)=1;
            else
                check_remove(ilist)=1;% variable will be removed
            end
        end
    end
    ListVarNameSub=ListVarNameSub(~check_remove); %eliminate removed variables from the list of the second field
    ListVarNameNew=ListVarNameNew(~check_remove); % %list of renaimed varaibles corresponding to ListVarNameSub
    VarDimNameSub=Field_1.VarDimName(~check_remove);
    if numel(Field_1.VarAttribute)<max(find(~check_remove))
        for ilist=numel(Field_1.VarAttribute)+1:max(find(~check_remove))
            Field_1.VarAttribute{ilist}={};
        end
    end
    VarAttributeSub=Field_1.VarAttribute(~check_remove);
    check_rename=check_rename(~check_remove);
end
% apply the variable renaming and mark the second field variables with the attribute .CheckSub
for ilist=1:numel(ListVarNameSub)
     SubData.(ListVarNameNew{ilist})=Field_1.(ListVarNameSub{ilist});% copy the variable content to the new name
    if check_rename(ilist)   
          % replace name in field expression FieldName, e.g. 'norm(U,V)'-> 'norm(U_1,V_1)'
        if  isfield(VarAttributeSub{ilist},'FieldName')
            for ivar=1:numel(find(check_rename))
                VarAttributeSub{ilist}.FieldName=regexprep_r(VarAttributeSub{ilist}.FieldName,...
                    ListVarNameSub{ivar},ListVarNameNew{ivar});
            end
        end
    end
    VarAttributeSub{ilist}.CheckSub=1;% mark that the field needs to be substracted as an attribute
end

SubData.ListVarName=[SubData.ListVarName ListVarNameNew];
SubData.VarDimName=[SubData.VarDimName VarDimNameSub];
SubData.VarAttribute=[SubData.VarAttribute VarAttributeSub];

%% substrat fields when possible
[CellInfo,NbDim,errormsg]=find_field_cells(SubData);
ind_remove=false(size(SubData.ListVarName));
ivar=[];
ivar_1=[];
for icell=1:numel(CellInfo)
    if ~isempty(CellInfo{icell})
        % if two scalar are in the same cell
        if isfield(CellInfo{icell},'VarIndex_scalar') && numel(CellInfo{icell}.VarIndex_scalar)==2 && SubData.VarAttribute{CellInfo{icell}.VarIndex_scalar(2)}.CheckSub;
            ivar=[ivar CellInfo{icell}.VarIndex_scalar(1)];
            ivar_1=[ivar_1 CellInfo{icell}.VarIndex_scalar(2)];
        end
        % if two vector u components are in the same cell
        if isfield(CellInfo{icell},'VarIndex_vector_x') && numel(CellInfo{icell}.VarIndex_vector_x)==2 && SubData.VarAttribute{CellInfo{icell}.VarIndex_vector_x(2)}.CheckSub;
            ivar=[ivar CellInfo{icell}.VarIndex_vector_x(1)];
            ivar_1=[ivar_1 CellInfo{icell}.VarIndex_vector_x(2)];
        end
         % if two vector v components are in the same cell
        if isfield(CellInfo{icell},'VarIndex_vector_y') && numel(CellInfo{icell}.VarIndex_vector_y)==2 && SubData.VarAttribute{CellInfo{icell}.VarIndex_vector_y(2)}.CheckSub;
            ivar=[ivar CellInfo{icell}.VarIndex_vector_y(1)];
            ivar_1=[ivar_1 CellInfo{icell}.VarIndex_vector_y(2)];
        end
        % merge the error flags if needed
        if isfield(CellInfo{icell},'VarIndex_errorflag') && numel(CellInfo{icell}.VarIndex_errorflag)==2 && SubData.VarAttribute{CellInfo{icell}.VarIndex_vector_y(2)}.CheckSub;
            ivar_flag=CellInfo{icell}.VarIndex_errorflag(1);
            ivar_flag_1=CellInfo{icell}.VarIndex_errorflag(2);
            VarName=SubData.ListVarName{ivar_flag};
            VarName_1=SubData.ListVarName{ivar_flag_1};
            SubData.(VarName)=SubData.(VarName)~=0 | SubData.(VarName_1)~=0;% combine the error flags of the two fields
            ind_remove(ivar_flag_1)=1;
        end
    end
end
% subtract fields if relevant
for imod=1:numel(ivar)
        VarName=SubData.ListVarName{ivar(imod)};
        VarName_1=SubData.ListVarName{ivar_1(imod)};
        SubData.(VarName)=double(SubData.(VarName))-double(SubData.(VarName_1));
        ind_remove(ivar_1(imod))=1;
end
SubData.ListVarName(ind_remove)=[];
SubData.VarDimName(ind_remove)=[];
SubData.VarAttribute(ind_remove)=[];

function OutputCell=regexprep_r(InputCell,search_string,new_string)
if ischar(InputCell); InputCell={InputCell}; end
OutputCell=InputCell;%default
for icell=1:numel(InputCell)
    OutputCell{icell}=regexprep(InputCell{icell},search_string,new_string);
end
        
    
