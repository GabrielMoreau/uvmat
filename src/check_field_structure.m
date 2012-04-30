%'check_field_structure': check the validity of the field struture representation consistant with the netcdf format
%------------------------------------------------------------------------
% function [DataOut,errormsg]=check_field_structure(Data)
%
% OUTPUT:
% DataOut: structure reproducing the input structure Data (TODO: suppress this output)
% errormsg: error message which is not empty when the input structure does not have the right form
%
% INPUT:
% Data:   structure containing 
%         (optional) .ListGlobalAttribute: cell listing the names of the global attributes
%                    .Att_1,Att_2... : values of the global attributes
%         (requested)  .ListVarName: list of variable names to select (cell array of  char strings {'VarName1', 'VarName2',...} ) 
%         (requested)  .VarDimName: list of dimension names for each element of .ListVarName (cell array of string cells)                         
%         (requested) .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName


function [errormsg,ListDimName,DimValue,VarDimIndex]=check_field_structure(Data)
DataOut=[]; %default
errormsg=[];
if ~isstruct(Data)
    errormsg='input field is not a structure';
    return
end
if isfield(Data,'ListVarName') && iscell(Data.ListVarName)
    nbfield=numel(Data.ListVarName); 
else
    errormsg='input field does not contain the cell array of variable names .ListVarNames';
    return
end
%check dimension names
if (isfield(Data,'VarDimName') && iscell(Data.VarDimName))
    if  numel(Data.VarDimName)~=nbfield
       errormsg=' .ListVarName and .VarDimName have different lengths';
        return
    end
else
    errormsg='input field does not contain the  cell array of dimension names .VarDimName';
    return
end
% if isfield(Data,'DimValue')
%     Data=rmfield(Data,'DimValue');
% end
nbdim=0;
ListDimName={};

%% main loop on the list of variables
for ivar=1:nbfield
    VarName=Data.ListVarName{ivar};
    if ~isfield(Data,VarName)
        errormsg=['the listed variable ' VarName ' is not found'];
        return
    end
    sizvar=size(Data.(VarName));% sizvar = dimension of variable
    DimCell=Data.VarDimName{ivar};
    if ischar(DimCell)
        DimCell={DimCell};%case of a single dimension name, defined by a string
    elseif ~iscell(DimCell)
        errormsg=['wrong format for .VarDimName{' num2str(ivar) ' (must be the cell of dimension names of the variable ' VarName];
        return
        
    end
    nbcoord=numel(sizvar);%nbre of coordinates for variable named VarName
    testrange=0;
    if numel(DimCell)==0
        errormsg=['empty declared dimension .VarDimName{' num2str(ivar) '} for ' VarName];
        return
    elseif numel(DimCell)==1% one dimension declared
        if nbcoord==2
            if sizvar(1)==1
                nbcoord=1;
                sizvar(1)=sizvar(2);
            elseif sizvar(2)==1
                nbcoord=1;
            else
                errormsg=['1 dimension declared in .VarDimName{' num2str(ivar) '} inconsistent with the nbre of dimensions =2 of the variable ' VarName];
                return
            end
            if sizvar(1)==2 && isequal(VarName,DimCell{1})
                testrange=1;% test for a dimension variable representing a range 
            end
        else
            errormsg=['1 dimension declared in .VarDimName{' num2str(ivar) '} inconsistent with the nbre of dimensions =' num2str(nbcoord) ' of the variable ' VarName];
            return
        end
    else
        if numel(DimCell)>nbcoord
            sizvar(nbcoord+1:numel(DimCell))=1;% case of singleton dimensions (not seen by the function size)
           % DimCell=DimCell(end-nbcoord+1:end)%first singleton diemensions omitted,
        elseif nbcoord > numel(DimCell)
            errormsg=['nbre of declared dimensions in .VarDimName{' num2str(ivar) '} smaller than the nbre of dimensions =' num2str(nbcoord) ' of the variable ' VarName];
            return
        end
    end
    DimIndex=[];
    %for idim=1:nbcoord
    for idim=1:numel(DimCell) %loop on the coordinates of variable #ivar
        DimName=DimCell{idim};
        iprev=find(strcmp(DimName,ListDimName),1);%look for dimension name DimName in the current list
        if isempty(iprev)% append the dimension name to the current list
            nbdim=nbdim+1;
            RangeTest(nbdim)=0; %default
            if sizvar(idim)==2 && strcmp(DimName,VarName)%case of a coordinate defined by the two end values (regular spacing)
                RangeTest(nbdim)=1; %to be updated for a later variable  
            end
            DimValue(nbdim)=sizvar(idim);
            ListDimName{nbdim}=DimName;
            DimIndex=[DimIndex nbdim];
        else % DimName is detected in the current list of dimension names
            if ~isequal(DimValue(iprev),sizvar(idim))
                if isequal(DimValue(iprev),2)&& RangeTest(iprev)  % the dimension has been already detected as a range [min max]
                    DimValue(iprev)=sizvar(idim); %update with actual value
                elseif ~testrange                
                    errormsg=['dimension declaration inconsistent with the size =[' num2str(sizvar) '] for ' VarName];
                    return
                end
            end
            DimIndex=[DimIndex iprev];
        end
    end
    VarDimIndex{ivar}=DimIndex;
end
DataOut=Data;
    
   