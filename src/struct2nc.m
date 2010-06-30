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
    errormsg='no name input for the netcf file';
    return
end
if ~exist('Data','var')
     errormsg='no data  input for the netcdf file';
    return
end 
hhh=which('netcdf.create');% look for built-in matlab library

%USE OF built-in  netcdf library
if ~isequal(hhh,'')
    FilePath=fileparts(flname);
    if ~strcmp(FilePath,'') && ~exist(FilePath,'dir')
        errormsg=['directory ' FilePath ' needs to be created'];
        return
    end
    [Data,errormsg]=check_field_structure(Data);%check the validity of the input field structure
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
                    if (ischar(cte) ||isnumeric(cte)) &&  ~isempty(cte)&& ~isequal(cte,'')
                        netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),keys{iattr},cte)
                    else
                        errormsg='global attributes must be characters or numbers';
                        return
                    end
                end
            end
        end
    end
    %create dimensions
    dimid=[];
    for idim=1:length(Data.ListDimName)
         dimid(idim) = netcdf.defDim(nc,Data.ListDimName{idim},Data.DimValue(idim)); 
    end
    VarAttribute={}; %default
    testattr=0;
    if isfield(Data,'VarAttribute')
        VarAttribute=Data.VarAttribute;
        testattr=1;
    end
    varid=[];
    for ivar=1:length(ListVarName)
        varid(ivar)=netcdf.defVar(nc,ListVarName{ivar},'double',dimid(Data.VarDimIndex{ivar}));%define variable  
    end
     %write variable attributes
    if testattr
        for ivar=1:length(VarAttribute)  
            if isstruct(VarAttribute{ivar})
                attr_names=fields(VarAttribute{ivar});
                for iattr=1:length(attr_names)
                    eval(['attr_val=VarAttribute{ivar}.' attr_names{iattr} ';']);
                    if ~isempty(attr_names{iattr})&& ~isempty(attr_val)
                        netcdf.putAtt(nc,varid(ivar),attr_names{iattr},attr_val);
                    end
                end
            end
        end
    end
    netcdf.endDef(nc); %put in data mode
    for ivar=1:length(ListVarName)
        if isfield(Data,ListVarName{ivar})
            eval(['VarVal=Data.' ListVarName{ivar} ';'])%varval=values of the current variable 
            VarDimIndex=Data.VarDimIndex{ivar}; %indices of the variable dimensions in the list of dimensions
            siz=size(VarVal);
            VarDimName=Data.VarDimName{ivar};
            if ischar(VarDimName)
                VarDimName={VarDimName};
            end
            testrange=(numel(VarDimName)==1 && strcmp(VarDimName{1},ListVarName{ivar}) && numel(VarVal)==2);
            testline=isequal(length(siz),2) && isequal(siz(1),1)&& isequal(siz(2), Data.DimValue(VarDimIndex));
            testcolumn=isequal(length(siz),2) && isequal(siz(1), Data.DimValue(VarDimIndex))&& isequal(siz(2),1);
            if ~testrange && ~testline && ~testcolumn && ~isequal(siz,Data.DimValue(VarDimIndex))
                errormsg=['wrong dimensions declared for ' ListVarName{ivar} ' in struct2nc.m'];
                break
            end 
            if testline || testrange
                if testrange
                    VarVal=linspace(VarVal(1),VarVal(2),Data.DimValue(VarDimIndex));
                end
               %nc{ListVarName{ivar}}=ncfloat(Data.ListDimName(VarDimIndex));%vector of x coordinates
               netcdf.putVar(nc,varid(ivar), double(VarVal'));
            else
                netcdf.putVar(nc,varid(ivar), double(VarVal));
                %nc{ListVarName{ivar}}(:) = VarVal;
            end
            
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%OLD netcdf toolbox
else
    errormsg=struct2nc_toolbox(flname,Data);
end

