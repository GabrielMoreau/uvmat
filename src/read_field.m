%'read_field': read the fields from files in different formats (netcdf files, images, video)
%--------------------------------------------------------------------------
%  function [Field,ParamOut,errormsg] = read_field(FileName,FileType,ParamIn,num)
%
% OUTPUT:
% Field: matlab structure representing the field
% ParamOut: structure representing parameters:
%        .FieldName; field name
%        .VelType
%        .CivStage: stage of civx processing (=0, not Civx, =1 (civ1), =2  (fix1)....     
%        .Npx,.Npy: for images, nbre of pixels in x and y
% errormsg: error message, ='' by default
%
%INPUT
% FileName: name of the input file
% FileType: type of file, as determined by the function get_file_info.m
% ParamIn: movie object or Matlab structure of input parameters
%     .FieldName: name (char string) of the input field (for Civx data)
%     .VelType: char string giving the type of velocity data ('civ1', 'filter1', 'civ2'...)
%     .ColorVar: variable used for vector color
%     .Npx, .Npy: nbre of pixels along x and y (used for .vol input files)
%     .TimeDimName: name of the dimension considered as 'time', selected index value then set by input 'num'   
% num: frame number for movies
%
% see also read_image.m,read_civxdata.m,read_civdata.m,

%=======================================================================
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function [Field,ParamOut,errormsg] = read_field(FileName,FileType,ParamIn,num)
%% default output and check input
Field=[];
if ~exist('num','var')
    num=1;
end
if ~exist('ParamIn','var')
    ParamIn=[];
end
ParamOut=ParamIn;%default
errormsg='';
if ~exist(FileName,'file')
    errormsg=['input file ' FileName ' does not exist'];
    return
end
A=[];
InputField={};
check_colorvar=0;
if isstruct(ParamIn)
    if isfield(ParamIn,'FieldName')
        if ischar(ParamIn.FieldName)
            InputField={ParamIn.FieldName};
        else
            InputField= ParamIn.FieldName;
        end
    end
    check_colorvar=zeros(size(InputField));
    if isfield(ParamIn,'ColorVar')&&~isempty(ParamIn.ColorVar)
        InputField=[ParamIn.FieldName {ParamIn.ColorVar}];
        check_colorvar(numel(InputField))=1;
    end
end

%% distingush different input file types
switch FileType
    case 'civdata'% new format for civ results
        [Field,ParamOut.VelType,errormsg]=read_civdata(FileName,InputField,ParamIn.VelType);
        if ~isempty(errormsg),errormsg=['read_civdata / ' errormsg];return,end
%         if ~isempty(strcmp('C',ParamIn.FieldName))% if C image correlation is requested as field (not color visu)
%             ScalarIndex=strcmp('C',Field.ListVarName);
%             Field.VarAttribute{ScalarIndex}.Role='scalar';%put role as 'scalar' instead of ancillary
%         end      
        ParamOut.CivStage=Field.CivStage;
    case 'civx'% old (obsolete) format for civ results
        ParamOut.FieldName='velocity';%Civx data found, set .FieldName='velocity' by default
        [Field,ParamOut.VelType,errormsg]=read_civxdata(FileName,InputField,ParamIn.VelType);
        if ~isempty(errormsg),errormsg=['read_civxdata / ' errormsg];return,end
        ParamOut.CivStage=Field.CivStage;
    case 'netcdf'% general netcdf file (not recognized as civ)
        ListVar={};
        Role={};
        ProjModeRequest={};
        ListInputField={};
        ListOperator={};
        checkU=0;
        checkV=0;
        for ilist=1:numel(InputField)
            % look for input variables to read
            r=regexp(InputField{ilist},'(?<Operator>(^vec|^norm))\((?<UName>.+),(?<VName>.+)\)$','names');
            if isempty(r)%  no operator used
                if isempty(find(strcmp(InputField{ilist},ListVar)))
                    ListVar=[ListVar InputField(ilist)];%append the variable name if not already in the list
                    ListInputField=[ListInputField InputField(ilist)];
                    ListOperator=[ListOperator {''}];
                end
                if check_colorvar(ilist)
                    Role{numel(ListVar)}='ancillary';% not projected with interpolation
                    ProjModeRequest{numel(ListVar)}='';
                else
                    Role{numel(ListVar)}='scalar';
                    ProjModeRequest{numel(ListVar)}='interp_lin';%scalar field (requires interpolation for plot)
                end
            else  % an operator 'vec' or 'norm' is used
                if ~check_colorvar(ilist) && strcmp(r.Operator,'norm')
                    ProjModeRequestVar='interp_lin';%scalar field (requires interpolation for plot)
                else
                    ProjModeRequestVar='';
                end
                ind_var_U=find(strcmp(r.UName,ListVar));%check previous listing of variable r.UName
                ind_var_V=find(strcmp(r.VName,ListVar));%check previous listing of variable r.VName
                if isempty(ind_var_U)
                    ListVar=[ListVar {r.UName}]; % append the variable in the list if not previously listed
                    Role=[Role {'vector_x'}];
                    ProjModeRequest=[ProjModeRequest {ProjModeRequestVar}];
                    ListInputField=[ListInputField InputField(ilist)];
                    %ListOperator=[ListOperator {[r.Operator '_U']}];
                else
                    checkU=1;
                end
                if isempty(ind_var_V)
                    ListVar=[ListVar {r.VName}];% append the variable in the list if not previously listed
                    Role=[Role {'vector_y'}];
                    ProjModeRequest=[ProjModeRequest {ProjModeRequestVar}];
                    ListInputField=[ListInputField {''}];
                    %ListOperator=[ListOperator {[r.Operator '_V']}];
                else
                    checkV=1;
                end
            end
        end
        if ~isfield(ParamIn,'Coord_z')
            ParamIn.Coord_z=[];
        end
        NbCoord=~isempty(ParamIn.Coord_x)+~isempty(ParamIn.Coord_y)+~isempty(ParamIn.Coord_z);
        if isfield(ParamIn,'TimeDimName')% case of reading of a single time index in a multidimensional array
            [Field,var_detect,ichoice,errormsg]=nc2struct(FileName,'TimeDimName',ParamIn.TimeDimName,num,[ParamIn.Coord_x ParamIn.Coord_y ParamIn.Coord_z ListVar]);
        elseif isfield(ParamIn,'TimeVarName')% case of reading of a single time  in a multidimensional array
            [Field,var_detect,ichoice,errormsg]=nc2struct(FileName,'TimeVarName',ParamIn.TimeVarName,num,[ParamIn.Coord_x ParamIn.Coord_y ParamIn.Coord_z ListVar]);
            NbCoord=NbCoord+1;% adds time coordinate
        else
            [Field,var_detect,ichoice,errormsg]=nc2struct(FileName,[ParamIn.Coord_x ParamIn.Coord_y ParamIn.Coord_z ListVar]);
        end
        if ~isempty(errormsg)
            return
        end
        %scan all the variables beyond the two first ones, ParamIn.Coord_x and ParamIn.Coord_y.
        for ilist=NbCoord+1:numel(Field.VarDimName)
            if isequal(Field.VarDimName{1},Field.VarDimName{ilist}) % if a variable has the same dimension as the coordinate, it denotes a field with unstructured coordinates
                Field.VarAttribute{1}.Role='coord_x';%unstructured coordinates
                Field.VarAttribute{2}.Role='coord_y';
                if NbCoord>=3
                    Field.VarAttribute{3}.Role='coord_z';
                end
                break
            end
        end
        NormName='';
        UName='';
        VName='';
        for ilist=1:numel(ListVar)
            Field.VarAttribute{ilist+NbCoord}.Role=Role{ilist};
            Field.VarAttribute{ilist+NbCoord}.ProjModeRequest=ProjModeRequest{ilist};
            if isfield(ParamIn,'FieldName')
                Field.VarAttribute{ilist+NbCoord}.FieldName=ListInputField{ilist};
            end
            r=regexp(ListInputField{ilist},'(?<Operator>(^vec|^norm))\((?<UName>.+),(?<VName>.+)\)$','names');
            if ~isempty(r)&& strcmp(r.Operator,'norm')
                NormName='norm';
                if ~isempty(find(strcmp(ListVar,'norm')))
                    NormName='norm_1';
                end
                Field.ListVarName=[Field.ListVarName {NormName}];
                ilistmax=numel(Field.ListVarName);
                Field.VarDimName{ilistmax}=Field.VarDimName{ilist+2};
                Field.VarAttribute{ilistmax}.Role='scalar';
                Field.(NormName)=Field.(r.UName).*Field.(r.UName)+Field.(r.VName).*Field.(r.VName);
                Field.(NormName)=sqrt(Field.(NormName));
                UName=r.UName;
                VName=r.VName;
            end
        end
        if ~isempty(NormName)% remove U and V if norm has been calculated and U and V are not needed as variables
            ind_var_U=find(strcmp(UName,ListVar));%check previous listing of variable r.UName
            ind_var_V=find(strcmp(VName,ListVar));%check previous listing of variable r.VName
            if ~checkU && ~checkV
                Field.ListVarName([ind_var_U+2 ind_var_V+2])=[];
                Field.VarDimName([ind_var_U+2 ind_var_V+2])=[];
                Field.VarAttribute([ind_var_U+2 ind_var_V+2])=[];
            elseif ~checkU
                Field.ListVarName(ind_var_U+2)=[];
                Field.VarDimName(ind_var_U+2)=[];
                Field.VarAttribute(ind_var_U+2 )=[];
            elseif ~checkV
                Field.ListVarName(ind_var_V+2)=[];
                Field.VarDimName(ind_var_V+2)=[];
                Field.VarAttribute(ind_var_V+2 )=[];
            end
        end
    case 'video'
        if strcmp(class(ParamIn),'VideoReader')
            A=read(ParamIn,num);
        else
            ParamOut=VideoReader(FileName);
            A=read(ParamOut,num);
        end
    case 'mmreader'
        if strcmp(class(ParamIn),'mmreader')
            A=read(ParamIn,num);
        else
            ParamOut=mmreader(FileName);
            A=read(ParamOut,num);
        end
    case 'vol'
        A=imread(FileName);
        Npz=size(A,1)/ParamIn.Npy;
        A=reshape(A',ParamIn.Npx,ParamIn.Npy,Npz);
        A=permute(A,[3 2 1]);
    case 'multimage'
      %  warning 'off'
        A=imread(FileName,num);
    case 'image'
        A=imread(FileName);
    case 'rdvision'
        [A,FileInfo,timestamps]=read_rdvision(FileName,num);
    otherwise
        errormsg=[ FileType ': invalid input file type for uvmat'];
end

%% case of image
if ~isempty(A)
    if strcmp(FileType,'rdvision')
        Field.Time=timestamps;
    end
    if isstruct(ParamOut)
        ParamOut.FieldName='image';
    end
    Npz=1;%default
    npxy=size(A);
    %     Rangx=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
    %     Rangy=[npxy(1)-0.5 0.5]; %
    Field.NbDim=2;%default
    Field.AName='image';
    Field.ListVarName={'Coord_y','Coord_x','A'}; %
    if ndims(A)==3
        if Npz==1;%color
            Field.VarDimName={'Coord_y','Coord_x',{'Coord_y','Coord_x','rgb'}}; %
            Field.Coord_y=[npxy(1)-0.5 0.5];
            Field.Coord_x=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
            if isstruct(ParamOut)
                ParamOut.Npx=npxy(2);% display image size on the interface
                ParamOut.Npy=npxy(1);
            end
            Field.VarAttribute{3}.Mesh=1;
        else
            Field.NbDim=3;
            Field.ListVarName=['AZ' Field.ListVarName];
            Field.VarDimName={'AZ','Coord_y','Coord_x',{'AZ','Coord_y','Coord_x'}};
            Field.AZ=[npxy(1)-0.5 0.5];
            Field.Coord_y=[npxy(2)-0.5 0.5];
            Field.Coord_x=[0.5 npxy(3)-0.5]; % coordinates of the first and last pixel centers
            if isstruct(ParamOut)
                ParamOut.Npx=npxy(3);% display image size on the interface
                ParamOut.Npy=npxy(2);
            end
            Field.VarAttribute{4}.Mesh=1;
        end
    else
        Field.VarDimName={'Coord_y','Coord_x',{'Coord_y','Coord_x'}}; %
        Field.Coord_y=[npxy(1)-0.5 0.5];
        Field.Coord_x=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
        ParamOut.Npx=npxy(2);% display image size on the interface
        ParamOut.Npy=npxy(1);
        Field.VarAttribute{3}.Mesh=1;
    end
    Field.A=A;
    Field.CoordUnit='pixel'; %used for mouse_motion
        
end



