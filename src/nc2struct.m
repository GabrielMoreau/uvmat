%'nc2struct': transform a netcdf file in a corresponding matlab structure
% it reads all the global attributes and all variables, or a selected list.
% The corresponding dimensions and variable attributes are then extracted
%----------------------------------------------------------------------
% function [Data,var_detect,ichoice]=nc2struct(nc,varargin)
%
% OUTPUT:
%  Data: structure containing all the information of the netcdf file (or netcdf object)
%           with (optional)fields:
%                    .ListGlobalAttribute: cell listing the names of the global attributes
%                    .Att_1,Att_2... : values of the global attributes
%                    .ListVarName: list of variable names to select (cell array of  char strings {'VarName1', 'VarName2',...} ) 
%                    .VarDimName: list of dimension names for each element of .ListVarName (cell array of string cells)                         
%                    .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName
%                  ListDimName=list of dimension (added information, not requested for field description)
%                  DimValue= vlalues of dimensions (added information, not requested for field description)
%         .Txt: error message
%  var_detect: vector with same length as the cell array ListVarName, = 1 for each detected variable and 0 else.
%            var_detect=[] in the absence of input cell array 
%  ichoice: index of the selected line in the case of multiple choice 
%        (cell array of varible names with multiple lines) , =[] by default 
%INPUT:
%  nc:  name of a netcdf file (char string) or netcdf object   
%  additional arguments:
%       -no additional arguments: all the variables of the netcdf file are read.
%       -a cell array, ListVarName, made of  char strings {'VarName1', 'VarName2',...} ) 
%         if ListVarName=[] or {}, no variable value is read (only global attributes and list of variables and dimensions)
%         if ListVarName is absent, or = '*', ALL the variables of the netcdf file are read. 
%         if ListVarName is a cell array with n lines, the set of variables will be sought by order of priority
%                  in the list, while output names will be set by the first line
%        - the string 'ListGlobalAttribute' followed by a list of attribute  names: reads only these attributes (fast reading)
%        - the string 'TimeVarName', a string (the variable considered as
%        time), an integer (the selected time index), the cell of other
%        input variables limited to the input time index (considered as the last index of arrays)
%        - the string 'TimeDimName', a string (the dimension considered as time), an integer (the selected time index), the cell of other
%        input variables limited to the input time index (considered as the last index of arrays)

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

if isempty(varargin)
    varargin{1}='*';
end
hhh=which('netcdf.open');% look for built-in matlab netcdf library

if ~isequal(hhh,'')
    %% default output
    Data=[];%default
    var_detect=[];%default
    ichoice=[];%default
    
    %% open the netcdf file for reading
    if ischar(nc) 
        if exist(nc,'file')
            try
            nc=netcdf.open(nc,'NC_NOWRITE');
            testfile=1;
            catch ME
              Data.Txt=['ERROR opening ' nc ': ' ME.message];
              return
            end
        else
           Data.Txt=['ERROR:file ' nc ' does not exist'];
           return
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
    if isequal(varargin{1},'TimeVarName')
        TimeVarName=varargin{2};
        TimeVarIndex=varargin{3};
        input_index=4;
    elseif isequal(varargin{1},'TimeDimName')
        TimeDimName=varargin{2};
        TimeVarIndex=varargin{3};
        input_index=4;
    end

    %% full reading: get the nbre of dimensions, variables, global attributes
    ListVarName=varargin{input_index}; 
    [ndims,nvars,ngatts]=netcdf.inq(nc);%nbre of dimensions, variables, global attributes, in the netcdf file
    
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
    for idim=1:ndims %loop on the dimensions of the netcdf file
        [ListDimNameNetcdf{idim},dim_value(idim)] = netcdf.inqDim(nc,idim-1);%get name and value of each dimension
    end
    if ~isempty(ListDimNameNetcdf) 
        flag_used=zeros(1,ndims);%initialize the flag indicating the selected dimensions in the list (0=unused)
    end
    if isequal(varargin{1},'TimeDimName')% time dimension introduced
        TimeDimIndex=find(strcmp(varargin{2},ListDimNameNetcdf));
        if isempty(TimeDimIndex)
            Data.Txt=['requested time dimension ' varargin{2} ' not found'];
            return
        end
        if dim_value(TimeDimIndex)<varargin{3}
            Data.Txt=['requested time index ' num2str(varargin{3}) ' exceeds matrix dimension'];
            return
        end
    end
 
    %%  -------- read names of variables -----------
    ListVarNameNetcdf=cell(1,nvars); %default
    dimids=cell(1,nvars);
    nbatt=zeros(1,nvars);
    for ncvar=1:nvars %loop on the variables of the netcdf file
        %get name, type, dimensions and attribute numbers of each variable 
        [ListVarNameNetcdf{ncvar},xtype,dimids{ncvar},nbatt(ncvar)] = netcdf.inqVar(nc,ncvar-1);
    end  
    testmulti=0;
    if isequal(ListVarName,'*')||isempty(ListVarName)
        var_index=1:nvars; %all the variables are selected in the netcdf file 
        Data.ListVarName=ListVarNameNetcdf;
    else   %select input variables, if requested by the input ListVarName
        ind_remove=[];
        check_keep=ones(1,size(ListVarName,2));
        for ivar=1:size(ListVarName,2) % check redondancy of variable names
            if ~isempty(find(strcmp(ListVarName{1,ivar},ListVarName(1:ivar-1)), 1))
                check_keep(ivar)=0;% the variable #ivar is already in the list
            end
        end
        ListVarName=ListVarName(:,logical(check_keep));          
        sizvar=size(ListVarName);
        testmulti=(sizvar(1)>1);%test for multiple choice of variable ranked by order of priority
        var_index=zeros(1,sizvar(2));%default
        if testmulti %multiple choice of variable ranked by order of priority
            for iline=1:sizvar(1)
                search_index=find(strcmp(ListVarName{iline,1},ListVarNameNetcdf),1);%look for the first variable name in the list of netcdf variables
                if ~isempty(search_index)
                    break % go to the next line
                end
            end
            ichoice=iline-1;%selected line number in the list of input names of variables
        else
            iline=1;
        end
        for ivar=1:sizvar(2)
            search_index=find(strcmp(ListVarName{iline,ivar},ListVarNameNetcdf),1);%look for the variable name in the list of netcdf file
            if ~isempty(search_index)
                var_index(ivar)=search_index;%index of the netcdf list corresponding to the input list index ivar
            end
        end
        var_detect=(var_index~=0);%=1 for detected variables          
        list_index=find(var_index);% indices in the input list corresponding to a detected variable
        var_index=var_index(list_index);% netcdf variable indices corresponding to the output list of read variable
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
            if ischar(valuestr)
               % valuestr=regexprep(valuestr,{'\\','\/','\.','\-',' '},{'_','_','_','_','_'});%remove  '\','.' or '-' if exists
                eval(['Data.VarAttribute{ivar}.' attname '=''' valuestr ''';'])
            elseif isempty(valuestr)
                eval(['Data.VarAttribute{ivar}.' attname '=[];'])
            elseif isnumeric(valuestr)
                eval(['Data.VarAttribute{ivar}.' attname '=valuestr;'])
            end
            catch ME
                display(attname)
                display(valuestr)
                display(ME.message)         
                eval(['Data.VarAttribute{ivar}.atrr_' num2str(iatt) '=''not read'';'])
            end
        end
    end
    

    %% select the dimensions used for the set of input variables
    if ~isempty(var_index)      
        dim_index=find(flag_used);%list of netcdf dimensions indices corresponding to used dimensions 
        Data.ListDimName=ListDimNameNetcdf(dim_index); 
        Data.DimValue=dim_value(dim_index);
    end
    
    %% get the values of the input variables
    if  ~isempty(ListVarName)
        for ivar=1:length(var_index)
            VarName=Data.ListVarName{ivar};
            VarName=regexprep(VarName,'-',''); %suppress '-' if it exists in the netcdf variable name
            CheckSub=0;
            if input_index==4% if a dimension is selected as time
                if var_dim{ivar}(end)==TimeDimIndex% if the last dim of the variable is the time
                    slice_length=prod(var_dim{ivar}(1:end-1));
                    Data.(VarName)=double(netcdf.getVar(nc,var_index(ivar)-1),TimeIndex*slice_length,slice_length); %read the variable data
                    CheckSub=1;
                end
            end
            if ~CheckSub
                Data.(VarName)=double(netcdf.getVar(nc,var_index(ivar)-1)); %read the whole variable data
            end
        end
    end
    
    %%  -------- close fle-----------
    if testfile==1
        netcdf.close(nc) 
    end
    
%% old netcdf library 
else
    [Data,var_detect,ichoice]=nc2struct_toolbox(nc,varargin);
end