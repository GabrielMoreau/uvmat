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
% OUPUT: 
% SubData: structure representing the resulting field
%
% INPUT: 
% Field: matlab structure representing the first field
% Field_1:matlab structure representing the second field

function SubData=sub_field(Field,XmlData,Field_1)

SubData=[];
if strcmp(Field,'*')
    return
end
if nargin<3
    SubData=Field;
    return
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
FieldRequest=cell(size(Field.ListVarName));
for ilist=1:numel(Field.VarAttribute)
    if isfield(Field.VarAttribute{ilist},'FieldRequest')
        FieldRequest{ilist}=Field.VarAttribute{ilist}.FieldRequest;
    end
end
FieldRequest_1=cell(size(Field_1.ListVarName));
for ilist=1:numel(Field_1.VarAttribute)
    if isfield(Field_1.VarAttribute{ilist},'FieldRequest')
        FieldRequest_1{ilist}=Field_1.VarAttribute{ilist}.FieldRequest;
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

%look for coordinates common to Field in Field_1
ind_remove=zeros(size(Field_1.ListVarName));
for ilist=1:numel(Field_1.ListVarName)
    if ischar(Field_1.VarDimName{ilist})||numel(Field_1.VarDimName{ilist})==1
        OldDim=Field_1.VarDimName{ilist};
        if ischar(OldDim)
            OldDim=Field_1.VarDimName(ilist);
        end
        VarVal=Field_1.(Field_1.ListVarName{ilist});
        for i1=1:numel(Field.ListVarName)
            if (isempty(FieldRequest{i1})&&isempty(FieldRequest_1{ilist})||strcmp(FieldRequest{i1},FieldRequest_1{ilist})) && isequal(Field.(Field.ListVarName{i1}),VarVal)
               ind_remove(ilist)=1;
               NewDim=Field.VarDimName{i1};
               if ischar(NewDim)
                   NewDim={NewDim};
               end
               Field_1.VarDimName=regexprep_r(Field_1.VarDimName,OldDim{1},NewDim{1});
            end
        end
    end
end
Field_1.ListVarName(find(ind_remove))=[];%removes these redondent coordinates
Field_1.VarDimName(find(ind_remove))=[];
Field_1.VarAttribute(find(ind_remove))=[];

%append the other variables of the second field, modifying their name if needed
for ilist=1:numel(Field_1.ListVarName)
    VarName=Field_1.ListVarName{ilist};
    ind_prev=find(strcmp(VarName,Field.ListVarName));
    if isempty(ind_prev)% variable name does not exist in Field
        VarNameNew=VarName;
    else  % variable name exists in Field     
            VarNameNew=[VarName '_1'];   
    end
        SubData.ListVarName=[SubData.ListVarName {VarNameNew}];
        SubData.VarDimName=[SubData.VarDimName Field_1.VarDimName(ilist)];
        SubData.(VarNameNew)=Field_1.(VarName);
        SubData.VarAttribute=[SubData.VarAttribute Field_1.VarAttribute(ilist)];
        SubData.VarAttribute{end}.CheckSub=1;% mark that the field needs to be substracted
end

%append the other variables of the second field, modifying their name if needed

%% substrat fields when possible
%[CellVarIndex,NbDim,CellVarType,errormsg]=find_field_cells(SubData);
[CellInfo,NbDim,errormsg]=find_field_cells(SubData)
ind_remove=zeros(size(SubData.ListVarName));
ivar=[];
ivar_1=[];
for icell=1:numel(CellInfo)
    if ~isempty(CellInfo{icell})
        if isfield(CellInfo{icell},'VarIndex_scalar') && numel(CellInfo{icell}.VarIndex_scalar)==2 && SubData.VarAttribute{CellInfo{icell}.VarIndex_scalar(2)}.CheckSub;
            ivar=[ivar CellInfo{icell}.VarIndex_scalar(1)];
            ivar_1=[ivar_1 CellInfo{icell}.VarIndex_scalar(2)];
        end
        if isfield(CellInfo{icell},'VarIndex_vector_x') && numel(CellInfo{icell}.VarIndex_vector_x)==2 && SubData.VarAttribute{CellInfo{icell}.VarIndex_vector_x(2)}.CheckSub;
            ivar=[ivar CellInfo{icell}.VarIndex_vector_x(1)];
            ivar_1=[ivar_1 CellInfo{icell}.VarIndex_vector_x(2)];
        end
        if isfield(CellInfo{icell},'VarIndex_vector_y') && numel(CellInfo{icell}.VarIndex_vector_y)==2 && SubData.VarAttribute{CellInfo{icell}.VarIndex_vector_y(2)}.CheckSub;
            ivar=[ivar CellInfo{icell}.VarIndex_vector_y(1)];
            ivar_1=[ivar_1 CellInfo{icell}.VarIndex_vector_y(2)];
        end
    end
end
for imod=1:numel(ivar)
        VarName=SubData.ListVarName{ivar(imod)};
        VarName_1=SubData.ListVarName{ivar_1(imod)};
        SubData.(VarName)=double(SubData.(VarName))-double(SubData.(VarName_1));
        ind_remove(ivar_1(imod))=1;
end
SubData.ListVarName(find(ind_remove))=[];
SubData.VarDimName(find(ind_remove))=[];
SubData.VarAttribute(find(ind_remove))=[];

function OutputCell=regexprep_r(InputCell,dimname,dimname_new)
for icell=1:numel(InputCell)
    OutputCell{icell}=regexprep(InputCell{icell},['^' dimname '$'],dimname_new);
end
        
    
