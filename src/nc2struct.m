
%'nc2struct': transform a NetCDF file in a corresponding matlab structure
% or directly read the a matlab data file .mat (calling the fct mat2struct.m)
% it reads all the global attributes and all variables, or a selected list.
% The corresponding dimensions and variable attributes are then extracted
%----------------------------------------------------------------------
% function [Data,var_detect,ichoice,errormsg]=nc2struct(nc,varargin)
%
% OUTPUT:
%  Data: structure containing all the information of the NetCDF file (or NetCDF object)
%           with (optional)fields:
%                    .ListGlobalAttribute: cell listing the names of the global attributes
%                    .Att_1,Att_2... : values of the global attributes
%                    .ListVarName: list of variable names to select (cell array of  char strings {'VarName1', 'VarName2',...} )
%                    .VarDimName: list of dimension names for each element of .ListVarName (cell array of string cells)
%                    .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName
%                  .ListDimName=list of dimension (added information, not requested for field description)
%                  .DimValue= vlalues of dimensions (added information, not requested for field description)
%                  .VarType= integers giving the type of variable as coded by netcdf =2 for char, =4 for single,=( for double
%  var_detect: vector with same length as the cell array ListVarName, = 1 for each detected variable and 0 else.
%            var_detect=[] in the absence of input cell array
%  ichoice: index of the selected line in the case of multiple choice
%        (cell array of varible names with multiple lines) , =[] by default
%
% INPUT:
%  nc:  name of a NetCDF file (char string) or NetCDF object
%  additional arguments:
%       -no additional arguments: all the variables of the NetCDF file are read.
%       -a cell array, ListVarName, made of  char strings {'VarName1', 'VarName2',...} )
%         if ListVarName=[] or {}, no variable value is read (only global attributes and list of variables and dimensions)
%         if ListVarName is absent, or = '*', ALL the variables of the NetCDF file are read.
%         if ListVarName is a cell array with n lines, the set of variables will be sought by order of priority in the list,
%            while output names will be set by the first line
%       - the string 'ListGlobalAttribute' followed by a list of attribute  names: reads only these attributes (fast reading)
%       - the string 'TimeVarName', a string (the name of the variable considered as time), an integer or vector with integer values
%            representing time indices to select for each variable, the cell of other input variable names.
%       - the string 'TimeDimName', a string (the name of the dimension considered as time), an integer or vector with integer values
%            representing time indices to select for each variable, the cell of other input variable names.

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [Data,var_detect,ichoice,errormsg]=nc2struct(nc,varargin)
errormsg='';%default error message
if isempty(varargin)
    varargin{1}='*';
end

%% default output
Data=[];%default
var_detect=[];%default
ichoice=[];%default

%% open the NetCDF (or .mat) file for reading
if ischar(nc)
    testfile=1;
    if exist(nc,'file')
        if ~isempty(regexp(nc,'.mat$'))
            Data=mat2struct(nc,varargin{1});
            return
        else
            try
                nc=netcdf.open(nc,'NC_NOWRITE');
            catch ME
                errormsg=['ERROR opening ' nc ': ' ME.message];
                return
            end
        end
    else %case of OpenDAP files
        if regexp(nc,'^http://')
            try
                nc=netcdf.open(nc,'NC_NOWRITE');
            catch ME
                errormsg=['ERROR opening ' nc ': ' ME.message];
                return
            end
        else
            errormsg=['ERROR:file ' nc ' does not exist'];
            return
        end
    end
else
    testfile=0;
end

%% short reading option for global attributes only, if the first argument is 'ListGlobalAttribute'
if isequal(varargin{1},'ListGlobalAttribute')
    for ilist=2:numel(varargin)
        valuestr=[];%default
        try
            valuestr = netcdf.getAtt(nc,netcdf.getConstant('NC_GLOBAL'),varargin{ilist});
        catch ME
        end
        eval(['Data.' varargin{ilist} '=valuestr;'])
    end
    netcdf.close(nc)
    return
end

%% time variable or dimension
input_index=1;
CheckTimeVar=0;
TimeVarName='';
if isequal(varargin{1},'TimeVarName')
    TimeVarName=varargin{2};
    CheckTimeVar=1;
    TimeIndex=varargin{3};
    input_index=4;% list of variables to read is at fourth argument
elseif isequal(varargin{1},'TimeDimName')
    TimeDimName=varargin{2};
    TimeIndex=varargin{3};
    input_index=4;
end

%% full reading: get the nbre of dimensions, variables, global attributes
ListVarName=varargin{input_index};
[ndims,nvars,ngatts]=netcdf.inq(nc);%nbre of dimensions, variables, global attributes, in the NetCDF file

%%  -------- read all global attributes (constants)-----------
Data.ListGlobalAttribute={};%default
att_key=cell(1,ngatts);%default
for iatt=1:ngatts
    keystr= netcdf.inqAttName(nc,netcdf.getConstant('NC_GLOBAL'),iatt-1);
    valuestr = netcdf.getAtt(nc,netcdf.getConstant('NC_GLOBAL'),keystr);
    keystr=regexprep(keystr,{'\','/','\.','-',' '},{'','','','',''});%remove  '\','.' or '-' if exists
    if strcmp(keystr(1),'_')
        keystr(1)=[];
    end
    try
        if ischar(valuestr) %& length(valuestr)<200 & double(valuestr)<=122 & double(valuestr)>=48 %usual characters
            eval(['Data.' keystr '=''' valuestr ''';'])
        elseif isnumeric(valuestr)
            eval(['Data.' keystr '=valuestr;'])
        else
            eval(['Data.' keystr '='';'])
        end
        att_key{iatt}=keystr;
    catch ME
        att_key{iatt}=['attr_' num2str(iatt)];
        Data.(att_key{iatt})=[];
    end
end
Data.ListGlobalAttribute=att_key;

%%  -------- read dimension names-----------
ListDimNameNetcdf=cell(1,ndims);
dim_value=zeros(1,ndims);
for idim=1:ndims %loop on the dimensions of the NetCDF file
    [ListDimNameNetcdf{idim},dim_value(idim)] = netcdf.inqDim(nc,idim-1);%get name and value of each dimension
end
if ~isempty(ListDimNameNetcdf)
    flag_used=zeros(1,ndims);%initialize the flag indicating the selected dimensions in the list (0=unused)
end
if isequal(varargin{1},'TimeDimName')% time dimension introduced
    TimeDimIndex=find(strcmp(TimeDimName,ListDimNameNetcdf));
    if isempty(TimeDimIndex)
        errormsg=['requested time dimension ' varargin{2} ' not found'];
        return
    end
    if dim_value(TimeDimIndex)<varargin{3}
        errormsg=['requested time index ' num2str(varargin{3}) ' exceeds matrix dimension'];
        return
    end
end

%%  -------- read names of variables -----------
ListVarNameNetcdf=cell(1,nvars); %default
dimids=cell(1,nvars);
nbatt=zeros(1,nvars);
for ncvar=1:nvars %loop on the variables of the NetCDF file
    %get name, type, dimensions and attribute numbers of each variable
    [ListVarNameNetcdf{ncvar},xtype(ncvar),dimids{ncvar},nbatt(ncvar)] = netcdf.inqVar(nc,ncvar-1);
end
%     testmulti=0;
if isequal(ListVarName,'*')||isempty(ListVarName)
    var_index=1:nvars; %all the variables are selected in the NetCDF file
    Data.ListVarName=ListVarNameNetcdf;
else   %select input variables, if requested by the input ListVarName
    check_keep=ones(1,size(ListVarName,2));
    for ivar=1:size(ListVarName,2) % check redondancy of variable names
        if ~isempty(find(strcmp(ListVarName{1,ivar},ListVarName(1:ivar-1)), 1))
            check_keep(ivar)=0;% the variable #ivar is already in the list
        end
    end
    ListVarName=ListVarName(:,logical(check_keep));
    if size(ListVarName,1)>1 %multiple choice of variable ranked by order of priority
        for iline=1:size(ListVarName,1)
            search_index=find(strcmp(ListVarName{iline,1},ListVarNameNetcdf),1);%look for the first variable name in the list of NetCDF variables
            if ~isempty(search_index)
                break % go to the next line
            end
        end
        ichoice=iline-1;%selected line number in the list of input names of variables
    else
        iline=1;
    end
    %ListVarName=ListVarName(iline,:);% select the appropriate option for input variable (lin ein the input name matrix)
    if CheckTimeVar
        TimeVarIndex=find(strcmp(TimeVarName,ListVarNameNetcdf),1); %look for the index of the time variable in the netcdf list
        if isempty(TimeVarIndex)
            errormsg='requested variable for time is missing';
            return
        end
        TimeDimIndex=dimids{TimeVarIndex}(1)+1;
        ListVarName=[ListVarName {TimeVarName}];
    end
    var_index=zeros(1,size(ListVarName,2));%default list of variable indices
    for ivar=1:size(ListVarName,2)
        search_index=find(strcmp(ListVarName{iline,ivar},ListVarNameNetcdf),1);%look for the variable name in the list of NetCDF file
        if ~isempty(search_index)
            var_index(ivar)=search_index;%index of the netcdf list corresponding to the input list index ivar
        end
    end
    var_detect=(var_index~=0);%=1 for detected variables
    list_index=find(var_index);% indices in the input list corresponding to a detected variable
    var_index=var_index(list_index);% NetCDF variable indices corresponding to the output list of read variable
    Data.ListVarName=ListVarName(1,list_index);%the first line of ListVarName sets the output names of the variables
end

%% get the dimensions and attributes associated to  variables
var_dim=cell(size(var_index));% initiate list of dimensions for variables
for ivar=1:length(var_index)
    var_dim{ivar}=dimids{var_index(ivar)}+1; %netcdf dimension indices used by the variable #ivar
    Data.VarDimName{ivar}=ListDimNameNetcdf(var_dim{ivar});
    flag_used(var_dim{ivar})=ones(size(var_dim{ivar}));%flag_used =1 for the indices of used dimensions
    for iatt=1:nbatt(var_index(ivar))
        attname = netcdf.inqAttName(nc,var_index(ivar)-1,iatt-1);
        valuestr= netcdf.getAtt(nc,var_index(ivar)-1,attname);
        attname=regexprep(attname,{'\','/','\.','-',' '},{'','','','',''});%remove  '\','.' or '-' if exists
        if strcmp(attname(1),'_')
            attname(1)=[];
        end
        try
            if ~isempty(valuestr)
                Data.VarAttribute{ivar}.(attname)=valuestr;
            end
        catch ME
            display(attname)
            display(valuestr)
            display(ME.message)
            Data.VarAttribute{ivar}.(['atrr_' num2str(iatt)])='not read';
        end
    end
end

%% select the dimensions used for the set of input variables
if ~isempty(var_index)
    dim_index=find(flag_used);%list of netcdf dimensions indices corresponding to used dimensions
    Data.ListDimName=ListDimNameNetcdf(dim_index);
    Data.DimValue=dim_value(dim_index);
    if input_index==4% if a dimension is selected as time
        Data.DimValue(TimeDimIndex)=numel(TimeIndex);
    end
end

%% get the values of the input variables
if  ~isempty(ListVarName)
    for ivar=1:length(var_index)
        VarName=Data.ListVarName{ivar};
        VarName=regexprep(VarName,'-','_'); %suppress '-' if it exists in the NetCDF variable name (leads to errors in matlab)
        %             CheckSub=0;
        if input_index==4% if a dimension is selected as time
            ind_vec=zeros(1,numel(var_dim{ivar}));% vector with zeros corresponding to al the dimensions of the variable VarName
            ind_size=dim_value(var_dim{ivar});% vector giving the size (for each dimension) of the variable VarName
            index_time=find(var_dim{ivar}==TimeDimIndex);
            if ~isempty(index_time)
                if ind_size(index_time)<max(TimeIndex)
                    errormsg=['requested index ' num2str(TimeIndex) ' exceeds matrix dimension'];
                    return
                end
                ind_vec(index_time)=TimeIndex-1;% selected index(or indices) to read
                ind_size(index_time)=numel(TimeIndex);%length of the selected set of time indices
                if numel(TimeIndex)==1 && ~strcmp(VarName,TimeVarName)
                    Data.VarDimName{ivar}(index_time)=[];% for a single selected time remove the time in the list of dimensions (except for tTime itself)
                end
            end
            Data.(VarName)=netcdf.getVar(nc,var_index(ivar)-1,ind_vec,ind_size); %read the variable data
            Data.(VarName)=squeeze(Data.(VarName));%remove singeton dimension
        else
            Data.(VarName)=netcdf.getVar(nc,var_index(ivar)-1); %read the whole variable data
        end
        if xtype(var_index(ivar))==5
            Data.(VarName)=double(Data.(VarName)); %transform to double for single pecision
        end
    end
end
Data.VarType=xtype(var_index);

%%  -------- close fle-----------
if testfile==1
    netcdf.close(nc)
end

