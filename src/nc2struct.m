%'nc2struct': transform a netcdf file in a corresponding matlab structure
% it reads all the global attributes and all variables, or a selected list.
% The corresponding dimensions and variable attributes are then extracted
%%%%%% TODO: add the possibility to read only attributes, see  nc2struct_toolbox %%%
%----------------------------------------------------------------------
% function [Data,var_detect,ichoice]=nc2struct(nc,ListVarName)
%
% OUTPUT:
%  Data: structure containing all the information of the netcdf file (or netcdf object)
%           with fields:
%    .ListGlobalAttribute: cell listing the names of the global attributes
%        .Att_1,Att_2... : values of the global attributes
%            .ListDimName: cell listing the names of the array dimensions
%               .DimValue: array dimension values (Matlab vector with the same length as .ListDimName
%            .ListVarName: cell listing the names of the variables
%            .VarDimIndex: cell containing the set of dimension indices (in list .ListDimName) for each variable of .ListVarName
%            .VarDimName: cell containing a cell of dimension names (in list .ListDimName) for each variable of .ListVarName
%           .VarAttribute: cell of structures s containing names and values of variable attributes (s.name=value) for each variable of .ListVarName
%        .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName
%  var_detect: vector with same length as ListVarName, with 1 for each detected variable and 0 else.
%  ichoice: = line 
%
%INPUT:
%     nc:      name of a netcdf file (char string) or netcdf object   
% ListVarName: optional list of variable names to select (cell array of  char strings {'VarName1', 'VarName2',...} ) 
%         if ListVarName=[] or {}, no variables is read (only global attributes and lists of dimensions, variables and attriburtes)
%         if ListVarName is absent, or = '*', ALL the variables are read. 
%        if ListVarName is a cell array with n lines, the set of variables
%                        will be sought by order of priority in the list, while output names will be set by the first line
% 
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
   
function [Data,var_detect,ichoice]=nc2struct(nc,varargin)
List=varargin;
if nargin==0
    List{1}='*';
end
% if ~exist('ListVarName','var')
%     ListVarName='*';
% end
hhh=which('netcdf.open');% look for built-in matlab netcdf library

if ~isequal(hhh,'')
    %default output
    Data=[];
    var_detect=[];
    ichoice=[];%default
    %open the netcdf file for reading
    if ischar(nc) 
        if exist(nc,'file')
            nc=netcdf.open(nc,'NC_NOWRITE');
            testfile=1;
        else
           Data.Txt=['ERROR:file ' nc ' does not exist'];
           return
        end
    else
        testfile=0;
    end
    % short reading of global attributes
    if isequal(List{1},'ListGlobalAttribute')
        for ilist=2:numel(List)
            try
            valuestr = netcdf.getAtt(nc,netcdf.getConstant('NC_GLOBAL'),List{ilist});
            catch
                valuestr=[];
            end
            eval(['Data.' List{ilist} '=valuestr;'])
        end
        netcdf.close(nc)
       return
    end

    % reading of variables, including attributes
    ListVarName=List{1};  
    [ndims,nvars,ngatts]=netcdf.inq(nc);%nbre of dimensions, variables, attributes
    
    %  -------- read global attributes (constants)-----------
    att_key={};%default
    iatt_g=0;
    Data.ListGlobalAttribute={};%default
    for iatt=1:ngatts
        keystr= netcdf.inqAttName(nc,netcdf.getConstant('NC_GLOBAL'),iatt-1);
        indstr1=regexp(keystr,'\\');%detect '\\'
        indstr2=regexp(keystr,'\.');%detect '\.'
        if isempty(indstr1) && isempty(indstr2)
           valuestr = netcdf.getAtt(nc,netcdf.getConstant('NC_GLOBAL'),keystr);
           if ischar(valuestr) && length(valuestr)<200
                iatt_g=iatt_g+1;
                indstr1=regexp(keystr,'\\');%detect '\\'
                indstr2=regexp(keystr,'\.');%detect '\.'
                if isempty(indstr1) && isempty(indstr2)
                    eval(['Data.' keystr '=''' valuestr ''';'])
                    att_key{iatt_g}=keystr;
                end
            elseif isempty(valuestr)
                iatt_g=iatt_g+1;
                eval(['Data.' keystr '=[];'])
                att_key{iatt_g}=keystr;
            elseif isnumeric(valuestr)
                iatt_g=iatt_g+1;
                eval(['Data.' keystr '=valuestr;'])
                att_key{iatt_g}=keystr;
            end
        end
    end
    Data.ListGlobalAttribute=att_key;

    %  -------- read dimensions -----------
    dim_name={};
    dim_value=[];
    for idim=1:ndims%length(dim_read);
        [dim_name{idim},dim_value(idim)] = netcdf.inqDim(nc,idim-1);
    end
    if ~isempty(dim_name) && ~isempty(dim_value)
        Data.ListDimName=dim_name;
        Data.DimValue=dim_value;
%         DimIndices=[1:ndims]; %index of the dimension in the netcdf file
        dim_used=zeros(1,ndims);%initialize test of used dimensions
    end
 
    %  -------- read variables -----------
    var_read={}; %default
    dimids={};
    nbatt=[];
    for ivar=1:nvars
        [var_read{ivar},xtype,dimids{ivar},nbatt(ivar)] = netcdf.inqVar(nc,ivar-1); 
    end  
    var_index=1:nvars; %default set of variable indices in the netcdf file
    testmulti=0;
    OutputList=[];
    %select input variables, if requested by the input ListVarName
    if ~(isequal(ListVarName,'*')||isempty(ListVarName))
        sizvar=size(ListVarName);
        testmulti=(sizvar(1)>1);
        var_index=zeros(1,sizvar(2));%default
        if testmulti
            OutputList=ListVarName(1,:);
            testend=0;
            for iline=1:sizvar(1)
                if testend
                    break
                end
          %      var_index=zeros(size(ListVarName));%default
                for ivar=1:sizvar(2)
                    if ~isempty(ListVarName{iline,ivar})
                         for ilist=1:nvars
                            if isequal(var_read{ilist},ListVarName{iline,ivar})
                                var_index(ivar)=ilist;
     %                          var_detect(ivar)=1;
                            break
                            end
                         end
                         if ivar==1
                            if var_index(ivar)==0
                                break%go to next line if the first nc variable is not found
                            else
                                testend=1; %this line will be read
                                ichoice=iline-1; %selectedline number in the list of input names of variables
                            end
                         end
                    end
                end
            end
        else   %single list of input variables
            for ivar=1:sizvar(2)
                for ilist=1:nvars
                    if isequal(var_read{ilist},ListVarName{ivar})
                        var_index(ivar)=ilist;
                        var_detect(ivar)=1;
                        break
                    end
                end
            end
        end
        list_index=find(var_index);
        if ~isempty(list_index)
            if testmulti
                OutputList=OutputList(list_index);
            end
            var_index=var_index(list_index);
            var_detect=(var_index~=0);
            var_read=var_read(var_index);         
        end
    end
    
    
    %select variable attributes and associate dimensions
%     var_dim_index=[]; %default
    Data.ListVarName={};%default
    VarDimIndex={};%default
    for ivar=1:length(var_read)
        if testmulti
            Data.ListVarName{ivar}=OutputList{ivar};%new name given by ListVarName(1,:)
        else
            Data.ListVarName{ivar}=var_read{ivar};%name of the variable
        end
        var_dim=dimids{var_index(ivar)}+1; %dimension indices used by the variable
        dim_used(var_dim)=ones(size(var_dim));
        VarDimIndex{ivar}=var_dim;

        %variable attributes
        if ivar==1
            Data.VarAttribute={};%initialisation of the list of variable attributes
        end
        %variable attributes
        for iatt=1:nbatt(var_index(ivar))
            attname = netcdf.inqAttName(nc,var_index(ivar)-1,iatt-1);
            valuestr= netcdf.getAtt(nc,var_index(ivar)-1,attname);
            if ischar(valuestr)
                eval(['Data.VarAttribute{ivar}.' attname '=''' valuestr ''';'])
            elseif isempty(valuestr)
                eval(['Data.VarAttribute{ivar}.' attname '=[];'])
            elseif isnumeric(valuestr)
                eval(['Data.VarAttribute{ivar}.' attname '=valuestr;'])
            end
        end
    end

    %select the used dimensions
    if isempty(var_read) 
        if isfield(Data,'ListDimName') && isfield(Data,'DimValue')
        Data=rmfield(Data,'ListDimName');
        Data=rmfield(Data,'DimValue');
        end
    else
%         list_dim=1:ndims;
        dim_index=find(dim_used);
%         list_dim=list_dim(dim_index);
        old2new=cumsum(dim_used); 
        Data.ListDimName=Data.ListDimName(dim_index);
        Data.DimValue=Data.DimValue(dim_index);
    end
    for ivar=1:length(var_read)
        Data.VarDimIndex{ivar}=old2new(VarDimIndex{ivar});% ENLEVER Data.VarDimIndex ulterieurement
        Data.VarDimName{ivar}=Data.ListDimName(Data.VarDimIndex{ivar});
    end
    %variable values
    if  ~isempty(ListVarName)
        for ivar=1:length(Data.ListVarName)
            VarName=Data.ListVarName{ivar};
            indstr=regexp(VarName,'-');%detect '-'
            if ~isempty(indstr)
                VarName(indstr)=[];
            end
            eval(['Data.' VarName '=netcdf.getVar(nc,var_index(ivar)-1);'])%read the variable data
            eval(['siz=size(Data.' VarName ');'])
            if numel(siz)<=2
            eval(['Data.' VarName '=Data.' VarName ''';'])%read the variable data
            end
        end
    end
    %  -------- close fle-----------
    if testfile==1
        netcdf.close(nc) 
    end
else
    [Data,var_detect,ichoice]=nc2struct_toolbox(nc,varargin);
end