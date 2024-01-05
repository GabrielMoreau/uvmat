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
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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
if isempty(num)
    num=1;
end
if ~exist('ParamIn','var')
    ParamIn=[];
end
ParamOut=ParamIn;%default
errormsg='';
if isempty(regexp(FileName,'^http://'))&& ~exist(FileName,'file')
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
        ParamOut.CivStage=Field.CivStage;
    case 'pivdata_fluidimage'
        [Field,ParamOut.VelType,errormsg]=read_pivdata_fluidimage(FileName,InputField,ParamIn.VelType);
        ParamOut.CivStage=Field.CivStage;
    case 'civx'% old (obsolete) format for civ results
        ParamOut.FieldName='velocity';%Civx data found, set .FieldName='velocity' by default
        [Field,ParamOut.VelType,errormsg]=read_civxdata(FileName,InputField,ParamIn.VelType);
        if ~isempty(errormsg),errormsg=['read_civxdata / ' errormsg];return,end
        ParamOut.CivStage=Field.CivStage;
    case {'netcdf','mat'}% general netcdf file (not recognized as civ)
        ListVarName={};
        Role={};
        ProjModeRequest={};
        % scan the list InputField
        Operator=cell(1,numel(InputField));
        InputVar=cell(1,numel(InputField));
        for ilist=1:numel(InputField)
            % look for input variables to read
            r=regexp(InputField{ilist},'(?<Operator>(^vec|^norm))\((?<UName>.+),(?<VName>.+)\)$','names');
            if isempty(r)%  no operator used
                ListVarName=[ListVarName InputField(ilist)];%append the variable name
                if check_colorvar(ilist)% case of field used for vector color
                    Role{numel(ListVarName)}='ancillary';% not projected with interpolation
                    ProjModeRequest{numel(ListVarName)}='';
                else
                    Role{numel(ListVarName)}='scalar';
                    ProjModeRequest{numel(ListVarName)}='interp_lin';%scalar field (requires interpolation for plot)
                end
                Operator{numel(ListVarName)}='';
            else  % an operator 'vec' or 'norm' is used
                ListVarName=[ListVarName {r.UName}]; % append the variable in the list if not previously listed
                if  strcmp(r.Operator,'norm')
                    if check_colorvar(ilist) 
                    Role=[Role {'ancillary'}];
                    else
                       Role=[Role {'scalar'}]; 
                    end
                else
                     Role=[Role {'vector_x'}];
                end
                ListVarName=[ListVarName {r.VName}];% append the variable in the list if not previously listed
                Role=[Role {'vector_y'}];
                Operator{numel(ListVarName)-1}=r.Operator;
                Operator{numel(ListVarName)}='';           
                if ~check_colorvar(ilist) && strcmp(r.Operator,'norm')
                    ProjModeRequest{numel(ListVarName)}='interp_lin';%scalar field (requires interpolation for plot)
                    ProjModeRequest{numel(ListVarName)-1}='interp_lin';%scalar field (requires interpolation for plot)
                else
                    ProjModeRequest{numel(ListVarName)}='';
                    ProjModeRequest{numel(ListVarName)-1}='';
                end
            end
        end
        if ~isfield(ParamIn,'Coord_z')
            ParamIn.Coord_z=[];
        end
        NbCoord=~isempty(ParamIn.Coord_x)+~isempty(ParamIn.Coord_y)+~isempty(ParamIn.Coord_z);
        if isfield(ParamIn,'TimeDimName')% case of reading of a single time index in a multidimensional array
            [Field,var_detect,ichoice,errormsg]=nc2struct(FileName,'TimeDimName',ParamIn.TimeDimName,num,[ParamIn.Coord_x ParamIn.Coord_y ParamIn.Coord_z ListVarName]);
        elseif isfield(ParamIn,'TimeVarName')% case of reading of a single time  in a multidimensional array
            [Field,var_detect,ichoice,errormsg]=nc2struct(FileName,'TimeVarName',ParamIn.TimeVarName,num,[ParamIn.Coord_x ParamIn.Coord_y ParamIn.Coord_z ListVarName]);
            if numel(num)~=1
                NbCoord=NbCoord+1;% adds time coordinate, except if a single time has been selected
            end
        else
            [Field,var_detect,ichoice,errormsg]=nc2struct(FileName,[ParamIn.Coord_x ParamIn.Coord_y ParamIn.Coord_z ListVarName]);
        end
        if ~isempty(errormsg)
            return
        end
        CheckStructured=1;
        %scan all the variables
        NbCoord=0;
        if ~isempty(ParamIn.Coord_x)
            index_Coord_x=find(strcmp(ParamIn.Coord_x,Field.ListVarName));
            Field.VarAttribute{index_Coord_x}.Role='coord_x';%
            NbCoord=NbCoord+1;
        end
        if ~isempty(ParamIn.Coord_y)
            if ischar(ParamIn.Coord_y)
                index_Coord_y=find(strcmp(ParamIn.Coord_y,Field.ListVarName));
                Field.VarAttribute{index_Coord_y}.Role='coord_y';%
                NbCoord=NbCoord+1;
            else
                for icoord_y=1:numel(ParamIn.Coord_y)
                    index_Coord_y=find(strcmp(ParamIn.Coord_y{icoord_y},Field.ListVarName));
                    Field.VarAttribute{index_Coord_y}.Role='coord_y';%
                    NbCoord=NbCoord+1;
                end
            end
        end
        NbDim=1;
        if ~isempty(ParamIn.Coord_z)
            index_Coord_z=find(strcmp(ParamIn.Coord_z,Field.ListVarName));
            Field.VarAttribute{index_Coord_z}.Role='coord_z';%
            NbCoord=NbCoord+1;
            NbDim=3;
        elseif ~isempty(ParamIn.FieldName)
            NbDim=2;
        end
        NormName='';
        UName='';
        VName='';
        if numel(Field.ListVarName)>NbCoord % if there are variables beyond coord (exclude 1 D plots)
            VarAttribute=cell(1,numel(ListVarName));
            for ilist=1:numel(ListVarName)
                index_var=find(strcmp(ListVarName{ilist},Field.ListVarName),1);
                VarDimName{ilist}=Field.VarDimName{index_var};
                DimOrder=[];
                if NbDim ==2
                    DimOrder=[find(strcmp(ParamIn.Coord_y,VarDimName{ilist})) find(strcmp(ParamIn.Coord_x,VarDimName{ilist}))];
                elseif NbDim ==3
                    DimOrder=[find(strcmp(ParamIn.Coord_z,VarDimName{ilist}))...
                        find(strcmp(ParamIn.Coord_y,VarDimName{ilist}))...
                        find(strcmp(ParamIn.Coord_x,VarDimName{ilist}))];
                end
                if ~isempty(DimOrder)
                    Field.(ListVarName{ilist})=permute(Field.(ListVarName{ilist}),DimOrder);
                    VarDimName{ilist}=VarDimName{ilist}(DimOrder);
                end
                if numel(Field.VarAttribute)>=index_var
                VarAttribute{ilist}=Field.VarAttribute{index_var};% read var attributes from input if exist
                end
            end
            check_remove=false(1,numel(Field.ListVarName));
            for ilist=1:numel(ListVarName)
                VarAttribute{ilist}.Role=Role{ilist};
                VarAttribute{ilist}.ProjModeRequest=ProjModeRequest{ilist};
                if isfield(ParamIn,'FieldName')
                    VarAttribute{ilist}.Operator=Operator{ilist};
                end
                if strcmp(Operator{ilist},'norm')
                    UName=ListVarName{ilist};
                    VName=ListVarName{ilist+1};
                    ListVarName{ilist}='norm';
                    Field.norm=Field.(UName).*Field.(UName)+Field.(VName).*Field.(VName);
                    Field.norm=sqrt(Field.norm);
                    check_remove(ilist+1)=true;
                    VarAttribute{ilist}.Operator='';
                end
            end
            ListVarName(check_remove)=[];
            VarDimName(check_remove)=[];
            VarAttribute(check_remove)=[];
            Field.ListVarName=[Field.ListVarName(1:NbCoord) ListVarName];% complement the list of vqriables, which may be listed twice
            Field.VarDimName=[Field.VarDimName(1:NbCoord) VarDimName];
            Field.VarAttribute=[Field.VarAttribute(1:NbCoord) VarAttribute];
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
        [A,FileInfo,timestamps,errormsg]=read_rdvision(FileName,num);
    case 'image_DaVis'
        Input=readimx(FileName);
        if numel(Input.Frames)==1
            num=1;
        end
        A=Input.Frames{num}.Components{1}.Planes{1}';
        for ilist=1:numel(Input.Frames{1}.Attributes)
            if strcmp(Input.Frames{1}.Attributes{ilist}.Name,'AcqTimeSeries')
                timestamps=str2num(Input.Frames{1}.Attributes{ilist}.Value(1:end-3))/1000000;
                break
            end
        end
    case 'cine_phantom'
        [A,FileInfo] = read_cine_phantom(FileName,num );
    otherwise
        errormsg=[ FileType ': invalid input file type for uvmat'];
        
end

%% case of image
if ~isempty(A)
    if strcmp(FileType,'rdvision')||strcmp(FileType,'image_DaVis')
        Field.Time=timestamps;
    end
    if isstruct(ParamOut)
        ParamOut.FieldName='image';
    end
    Npz=1;%default
    npxy=size(A);
    Field.NbDim=2;%default
    Field.AName='image';
    Field.ListVarName={'Coord_y','Coord_x','A'}; %
    Field.VarAttribute{1}.Unit='pixel';
    Field.VarAttribute{2}.Unit='pixel';
    Field.VarAttribute{1}.Role='coord_y';
    Field.VarAttribute{2}.Role='coord_x';
    Field.VarAttribute{3}.Role='scalar';
    if ndims(A)==3
        if Npz==1;%color
            Field.VarDimName={'Coord_y','Coord_x',{'Coord_y','Coord_x','rgb'}}; %
            Field.Coord_y=[npxy(1)-0.5 0.5];
            Field.Coord_x=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
            if isstruct(ParamOut)
                ParamOut.Npx=npxy(2);% display image size on the interface
                ParamOut.Npy=npxy(1);
            end
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
        end
    else
        Field.VarDimName={'Coord_y','Coord_x',{'Coord_y','Coord_x'}}; %
        Field.Coord_y=[npxy(1)-0.5 0.5];
        Field.Coord_x=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
    end
    Field.A=A;
    Field.CoordUnit='pixel'; %used for mouse_motion
end



