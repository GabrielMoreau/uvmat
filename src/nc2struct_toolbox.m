%'nc2struct_toolbox': transform a netcdf file in a corresponding matlab structure, USE OLD NETCDF LIBRARY
% it reads all the global attributes and all variables, or a selected list.
% The corresponding dimensions and variable attributes are then extracted
%----------------------------------------------------------------------
% function [Data,var_detect,ichoice]=nc2struct_toolbox(nc,varargin)
%
% OUTPUT:
%  Data: structure containing all the information of the netcdf file (or netcdf object)
%           with (optional)fields:
%                    .ListGlobalAttribute: cell listing the names of the global attributes
%                    .Att_1,Att_2... : values of the global attributes
%                    .ListVarName: list of variable names to select (cell array of  char strings {'VarName1', 'VarName2',...} ) 
%                    .VarDimName: list of dimension names for each element of .ListVarName (cell array of string cells)                         
%                    .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName
%                    .ListDimName=list of dimension (added information, not requested for field description)
%                    .DimValue= vlalues of dimensions (added information, not requested for field description)
%  var_detect: vector with same length as the cell array ListVarName, = 1 for each detected variable and 0 else.
%            var_detect=[] in the absence of input cell array 
%  ichoice: index of the selected line in the case of multiple choice 
%        (cell array of varible names with multiple lines) , =[] by default 
%INPUT:
%  nc:  name of a netcdf file (char string) or netcdf object   
%  additional arguments:
%       -no additional arguments: all the variables of the netcdf fiel are read.
%       -a cell array, ListVarName, made of  char strings {'VarName1', 'VarName2',...} ) 
%         if ListVarName=[] or {}, no variables is read (only global attributes)
%         if ListVarName is absent, or = '*', ALL the variables of the netcdf file are read. 
%         if ListVarName is a cell array with n lines, the set of variables will be sought by order of priority
%                  in the list, while output names will be set by the first line
%        - the string 'ListGlobalAttribute' followed by a list of attribute  names: reads only these attributes (fast reading)
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

function [Data,var_detect,ichoice]=nc2struct_toolbox(nc,varargin)

List=varargin{1};
%default output
Data=[];
var_detect=[];
ichoice=[];%default

%open the netcdf file for reading
if ischar(nc)
    if exist(nc,'file') % rmq: time for exist search = 0.5 ms CPU
        nc=netcdf(nc,'nowrite'); % rmq: time needed for opening = 2 ms CPU
        testfile=1;
    else
       Data.Txt=['ERROR:file ' nc ' does not exist'];
       return
    end
else
    testfile=0;
end

% short reading of global attributes
if ~isempty(List) && isequal(List{1},'ListGlobalAttribute')
    for ilist=2:numel(List)
        att_str=List{ilist};
        eval(['Data.' att_str '=nc.' att_str '(:);'])
    end
    close(nc) 
        %total time from beginning : 15 ms for a single attribute
   return
end

% reading of variables, including attributes
if isempty(List)
   ListVarName='*';
else
%     if isempty(List{1})
%         ListVarName='*';
%     else
        ListVarName=List{1};  
%     end
end
%  -------- read global attributes -----------              
att_read=att(nc);%cell of 'global attributes' (nc objects), CPU time 30 ms   
att_key={};%default
iatt_g=0;
for iatt=1:length(att_read)
    aa=att_read{iatt};
    keystr=name(aa);
    indstr1=regexp(keystr,'\\');%replace dots'
    indstr2=regexp(keystr,'\.');%replace dots'
    if ~isequal(keystr,'title') % PROBLEM WITH civx files do not read 'title' 
        if  isempty(indstr1) && isempty(indstr2) % 
           eval(['valuestr=nc.' keystr '(:);'])
            if ischar(valuestr) && length(valuestr)<200
                iatt_g=iatt_g+1;
                indstr1=regexp(keystr,'\\');%replace dots'
                indstr2=regexp(keystr,'\.');%replace dots'
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
end
Data.ListGlobalAttribute=att_key;
nbattr=length(att_key);
neworder=[nbattr+1 (1:nbattr)];
Data=orderfields(Data,neworder);

%  -------- read dimensions -----------
dim_read=dim(nc);%cell of variable dimension names (nc objects): CPU time 0.0013
dim_name={};
dim_value=[];
for idim=1:length(dim_read);
    aa=dim_read{idim};
    if ~isempty(aa)
    dim_name{idim}=name(aa);
    dim_value(idim)=length(aa);
    end
end
if ~isempty(dim_name) && ~isempty(dim_value)
    Data.ListDimName=dim_name;
    Data.DimValue=dim_value;
    used=zeros(1,length(dim_value));%initialize test of used dimensions
end

%  -------- read variables -----------
var_read={}; %default
testmulti=0;
OutputList=[];
if isequal(ListVarName,'*')%|| isempty(ListVarName)
     var_read=var(nc);%cell of all variables
elseif ~isempty(ListVarName)
    sizvar=size(ListVarName);
    testmulti=(sizvar(1)>1);
    if testmulti
        OutputList=ListVarName(1,:);
        testend=0;
        for iline=1:sizvar(1)
            if testend
                break
            end
            for ivar=1:sizvar(2)
                var_read{ivar}=[];%default
                var_detect(ivar)=0;%default
                VarName=ListVarName{iline,ivar};
                if ~isempty(VarName)
                     var_read{ivar}=nc{VarName};%select the input variable names
                     if ivar==1
                        if isempty (var_read{ivar})
                            break%go to next line if the first nc variable is not found
                        else
                            testend=1; %this line will be read
                            ichoice=iline-1; %selectedline number in the list of input names of variables
                            var_detect(ivar)=1;
                        end
                     else
                          var_detect(ivar)=~isempty (var_read{ivar});
                     end
                end
            end
        end
        if ~isempty(find(var_detect,1))
            OutputList=OutputList(find(var_detect));  
        end
    else   %single list of input variables
        var_detect=ones(size(ListVarName));
        for ivar=1:sizvar(2)
            var_read{ivar}=nc{ListVarName{ivar}};%select the input variable names
            var_detect(ivar)=~isempty(var_read{ivar});
        end
    end
    var_read=var_read(find(var_detect));
end

% var_dim_index=[]; %default
Data.ListVarName={};%default
for ivar=1:length(var_read)
    vv=var_read{ivar};
    Data.ListVarName{ivar}=name(vv);%name of the variable
    if testmulti
        Data.ListVarName{ivar}=OutputList{ivar};
    else
        Data.ListVarName{ivar}=name(vv);%name of the variable
    end
    var_dim=dim(vv);%dimension netcdf object of the variable
    for ivardim=1:length(var_dim)
        var_dim_name=name(var_dim{ivardim});%name of the dimension
        for idim=1:length(dim_name)% find the index of the current dimension in the list of dimensions
            if isequal(dim_name{idim},var_dim_name)
                VarDimIndex{ivar}(ivardim)=idim;
                used(idim)=1;
                break
            end
        end
    end 
    Data.VarDimName{ivar}={};
    %variable attributes
    Data.VarAttribute{ivar}=[];%initialisation of the list of variable attributes
    %variable attributes
    att_read=att(vv);
    for iatt=1:length(att_read)
        aa=att_read{iatt};
        eval(['valuestr=vv.' name(aa) '(:);'])
        if ischar(valuestr)
            eval(['Data.VarAttribute{ivar}.' name(aa) '=''' valuestr ''';'])
        elseif isempty(valuestr)
            eval(['Data.VarAttribute{ivar}.' name(aa) '=[];'])
        elseif isnumeric(valuestr)
            eval(['Data.VarAttribute{ivar}.' name(aa) '=valuestr;'])
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
    old_dim_index=find(used); %dimension indices which are used by the selected variables
    old2new=cumsum(used); 
    Data.ListDimName=Data.ListDimName(old_dim_index);
    Data.DimValue=Data.DimValue(old_dim_index);
end
for ivar=1:length(var_read)
    VarDimIndex{ivar}=(old2new(VarDimIndex{ivar}));
    Data.VarDimName{ivar}=(Data.ListDimName(VarDimIndex{ivar}));
end
%variable values

if  ~isempty(ListVarName)
    for ivar=1:length(Data.ListVarName)
        vv=var_read{ivar};
        vdata=vv(:);%data array of the field variable
        eval(['Data.' Data.ListVarName{ivar} '=vdata;'])%read the variable data
    end
end
%  -------- close fle-----------
if testfile==1
    close(nc) 
end

%total time from beginning : 150 ms for a full civ2 field, 65 ms for four fields

