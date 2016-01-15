%'struct2nc_toolbox': create a netcdf file from a Matlab structure: use of netcdf toolbox
%---------------------------------------------------------------------
% errormsg=struct2nc_toolbox(flname,Data)
%
% OUTPUT:
% errormsg=error message, =[]: default, no error
%
% INPUT:
% flname: name of the netcdf file to create (must end with the extension '.nc')
%  Data: structure containing all the information of the netcdf file (or netcdf object)
%           with fields:
%    .ListGlobalAttribute: cell listing the names of the global attributes (note that a global atribute with the same name as a variable is excluded)
%        .Att_1,Att_2... : values of the global attributes
%            .ListDimName: cell listing the names of the array dimensions
%               .DimValue: array dimension values (Matlab vector with the same length as .ListDimName
%            .ListVarName: cell listing the names of the variables
%            .VarDimIndex: cell containing the set of dimension indices (in list .ListDimName) for each variable of .ListVarName
%           .VarAttribute: cell of structures s containing names and values of variable attributes (s.name=value) for each variable of .ListVarName
%        .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName

%=======================================================================
% Copyright 2008-2016, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function errormsg=struct2nc_toolbox(flname,Data)

FilePath=fileparts(flname);
if ~strcmp(FilePath,'') &&~exist(FilePath,'dir')
    errormsg=['directory ' FilePath ' needs to be created'];
    return
end
[Data,errormsg]=check_field_structure(Data);
if ~isempty(errormsg)
    return
end
ListVarName=Data.ListVarName;
nc=netcdf(flname,'clobber'); %create the netcdf file with name flname
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
                if ischar(cte) && ~isequal(cte,'')
                    eval(['nc.' keys{iattr} '=''' cte ''';']);
                elseif isnumeric(cte)&& ~isempty(cte)
                    eval(['nc.' keys{iattr} '= cte; ']);
                else
                    errormsg='global attributes must be characters or numbers';
                    return
                end
            end
        end
    end
end
for idim=1:length(Data.ListDimName)
    nc(Data.ListDimName{idim})=Data.DimValue(idim);%create dimensions
end

VarAttribute={}; %default
testattr=0;
if isfield(Data,'VarAttribute')
    VarAttribute=Data.VarAttribute;
    testattr=1;
end
for ivar=1:length(ListVarName)
    if isfield(Data,ListVarName{ivar})
        eval(['VarVal=Data.' ListVarName{ivar} ';'])%varval=values of the current variable 
        siz=size(VarVal);
        VarDimIndex=Data.VarDimIndex{ivar}; %indices of the variable dimensions in the list of dimensions
        VarDimName=Data.VarDimName{ivar};
        if ischar(VarDimName)
            VarDimName={VarDimName};
        end
        testrange=(numel(VarDimName)==1 && strcmp(VarDimName{1},ListVarName{ivar}) && numel(VarVal)==2); 
        testline=isequal(length(siz),2) & isequal(siz(1),1)& isequal(siz(2), Data.DimValue(VarDimIndex));
        testcolumn=isequal(length(siz),2) & isequal(siz(1), Data.DimValue(VarDimIndex))& isequal(siz(2),1);
        if ~testrange && ~testline && ~testcolumn && ~isequal(siz,Data.DimValue(VarDimIndex))
            errormsg=['wrong dimensions declared for ' ListVarName{ivar} ' in struct2nc.m'];
            break
        end 
        if testline || testrange
           dimname=Data.ListDimName{VarDimIndex};
           if testrange
               VarVal=linspace(VarVal(1),VarVal(2),Data.DimValue(VarDimIndex));
           end
           nc{ListVarName{ivar}}=ncfloat(dimname);%vector of x coordinates
           nc{ListVarName{ivar}}(:) = VarVal';  
        else
            nc{ListVarName{ivar}}=ncfloat(Data.ListDimName(VarDimIndex));%vector of x coordinates
            nc{ListVarName{ivar}}(:) = VarVal;
        end
    end
end
%write variable attributes
if testattr
    for ivar=1:min(numel(VarAttribute),numel(ListVarName))  %loop on the attributes of variable ivar
        if isstruct(VarAttribute{ivar})
            attr_names=fields(VarAttribute{ivar});
            for iattr=1:length(attr_names)
                eval(['attr_val=VarAttribute{ivar}.' attr_names{iattr} ';']);
                if ischar(attr_val) && ~isequal(attr_val,'')
                    eval(['nc{''' ListVarName{ivar} '''}.' attr_names{iattr} '=''' attr_val ''';'])
                elseif isnumeric(attr_val)&& ~isempty(attr_val)
                     eval(['nc{''' ListVarName{ivar} '''}.' attr_names{iattr} '=attr_val ;'])
                end
            end
        end
    end
 end


close(nc);
