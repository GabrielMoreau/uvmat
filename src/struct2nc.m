% 'struct2nc': create a netcdf file from a Matlab structure
%---------------------------------------------------------------------
% errormsg=struct2nc(flname,Data)
%
% OUPUT:
% errormsg=error message, =[]: default, no error
%
% INPUT:
% flname: name of the netcdf file to create (must end with the extension '.nc')
%  Data: structure containing all the information of the netcdf file (or netcdf object)
%           with fields:
%       (optional) .ListGlobalAttribute: list (cell array of character strings) of the names of the global attributes Att_1, Att_2...
%                  .Att_1,Att_2...: values of the global attributes
%      (requested) .ListVarName: list of the variable names Var_1, Var_2....(cell array of character strings). 
%      (requested) .VarDimName: list of dimension names for each element of .ListVarName (cell array of string cells)
%       (optional) .VarAttribute: cell array of structures of the form .VarAttribute{ivar}.key=value, defining an attribute key name and value for the variable #ivar
%      (requested) .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName

%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function errormsg=struct2nc(flname,Data)
if ~ischar(flname)
    errormsg='invalid input for the netcf file name';
    return
end
if ~exist('Data','var')
     errormsg='no data  input for the netcdf file';
    return
end 
FilePath=fileparts(flname);
if ~strcmp(FilePath,'') && ~exist(FilePath,'dir')
    errormsg=['directory ' FilePath ' needs to be created'];
    return
end
%check the validity of the input field structure
[errormsg,ListDimName,DimValue,VarDimIndex]=check_field_structure(Data);
if ~isempty(errormsg)
    errormsg=['error in struct2nc:invalid input structure_' errormsg];
    return
end
ListVarName=Data.ListVarName;
nc=netcdf.create(flname,'NC_CLOBBER');%,'clobber'); %create the netcdf file with name flname   
%write global constants
if isfield(Data,'ListGlobalAttribute')
    keys=Data.ListGlobalAttribute;
    for iattr=1:length(keys)
        if isfield(Data,keys{iattr})
             testvar=0;
            for ivar=1:length(ListVarName)% eliminate possible global attributes with the same name as a variable
                if isequal(ListVarName{ivar}, keys{iattr})
                    testvar=1;
                    break
                end
            end
            if ~testvar               
                eval(['cte=Data.' keys{iattr} ';'])
                if (ischar(cte) ||isnumeric(cte)) &&  ~isempty(cte)%&& ~isequal(cte,'')
                    %write constant only if it is numeric or char string, and not empty
                    netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),keys{iattr},cte)
                end
            end
        end
    end
end
%create dimensions
dimid=zeros(1,length(ListDimName));
for idim=1:length(ListDimName)
     dimid(idim) = netcdf.defDim(nc,ListDimName{idim},DimValue(idim));
end
VarAttribute={}; %default
testattr=0;
if isfield(Data,'VarAttribute')
    VarAttribute=Data.VarAttribute;
    testattr=1;
end
varid=zeros(1,length(Data.ListVarName));
for ivar=1:length(ListVarName)
    varid(ivar)=netcdf.defVar(nc,ListVarName{ivar},'nc_double',dimid(VarDimIndex{ivar}));%define variable  
end
 %write variable attributes
if testattr
    for ivar=1:min(numel(VarAttribute),numel(ListVarName))  
        if isstruct(VarAttribute{ivar})
            attr_names=fields(VarAttribute{ivar});
            for iattr=1:length(attr_names)
                attr_val=VarAttribute{ivar}.(attr_names{iattr});
                if ~isempty(attr_names{iattr})&& ~isempty(attr_val)&&~iscell(attr_val)
                    netcdf.putAtt(nc,varid(ivar),attr_names{iattr},attr_val);
                end
            end
        end
    end
end
netcdf.endDef(nc); %put in data mode
for ivar=1:length(ListVarName)
    if isfield(Data,ListVarName{ivar})
        VarVal=Data.(ListVarName{ivar}); 
        %varval=values of the current variable 
%        VarDimIndex=Data.VarDimIndex{ivar}; %indices of the variable dimensions in the list of dimensions
        VarDimName=Data.VarDimName{ivar};
        if ischar(VarDimName)
            VarDimName={VarDimName};
        end
        siz=size(VarVal);
        testrange=(numel(VarDimName)==1 && strcmp(VarDimName{1},ListVarName{ivar}) && numel(VarVal)==2);% case of a coordinate defined on a regular mesh by the first and last values.
        testline=isequal(length(siz),2) && isequal(siz(1),1)&& isequal(siz(2), DimValue(VarDimIndex{ivar}));%matlab vector
        testcolumn=isequal(length(siz),2) && isequal(siz(1), DimValue(VarDimIndex{ivar}))&& isequal(siz(2),1);%matlab column vector
%             if ~testrange && ~testline && ~testcolumn && ~isequal(siz,DimValue(VarDimIndex))
%                 errormsg=['wrong dimensions declared for ' ListVarName{ivar} ' in struct2nc.m'];
%                 break
%             end 
        if testline || testrange
            if testrange
                VarVal=linspace(VarVal(1),VarVal(2),DimValue(VarDimIndex{ivar}));% restitute the whole array of coordinate values
            end
            netcdf.putVar(nc,varid(ivar), double(VarVal'));
        else
            netcdf.putVar(nc,varid(ivar), double(VarVal));
        end      
    end
end
netcdf.close(nc)


%'check_field_structure': check the validity of the field struture representation consistant with the netcdf format
%------------------------------------------------------------------------
% [errormsg,ListDimName,DimValue,VarDimIndex]=check_field_structure(Data)
%
% OUTPUT:
% errormsg: error message which is not empty when the input structure does not have the right form
% ListDimName: list of dimension names (cell array of cahr strings)
% DimValue: list of dimension values (numerical array with the same dimension as ListDimName)
% VarDimIndex: cell array of dimension index (in the list ListDimName) for each element of Data.ListVarName
%
% INPUT:
% Data:   structure containing 
%         (optional) .ListGlobalAttribute: cell listing the names of the global attributes
%                    .Att_1,Att_2... : values of the global attributes
%         (requested)  .ListVarName: list of variable names to select (cell array of  char strings {'VarName1', 'VarName2',...} ) 
%         (requested)  .VarDimName: list of dimension names for each element of .ListVarName (cell array of string cells)                         
%         (requested) .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName


function [errormsg,ListDimName,DimValue,VarDimIndex]=check_field_structure(Data)
errormsg='';
ListDimName={};
DimValue=[]; %default
VarDimIndex={};
if ~isstruct(Data)
    errormsg='input field is not a structure';
    return
end
if isfield(Data,'ListVarName') && iscell(Data.ListVarName)
    nbfield=numel(Data.ListVarName); 
else
    errormsg='input field does not contain the cell array of variable names .ListVarName';
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
nbdim=0;
ListDimName={};

%% main loop on the list of variables
VarDimIndex=cell(1,nbfield);
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
                sizvar(1)=sizvar(2);
            elseif sizvar(2)==1
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
        elseif nbcoord > numel(DimCell)
            errormsg=['nbre of declared dimensions in .VarDimName{' num2str(ivar) '} smaller than the nbre of dimensions =' num2str(nbcoord) ' of the variable ' VarName];
            return
        end
    end
    DimIndex=[];
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