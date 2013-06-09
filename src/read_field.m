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
% FileType: type of file, as determined by the function get_file_type.m
% ParamIn: movie object or Matlab structure of input parameters
%     .FieldName: name (char string) of the input field (for Civx data)
%     .VelType: char string giving the type of velocity data ('civ1', 'filter1', 'civ2'...)
%     .ColorVar: variable used for vector color
%     .Npx, .Npy: nbre of pixels along x and y (used for .vol input files)
% num: frame number for movies
%
% see also read_image.m,read_civxdata.m,read_civdata.m,

function [Field,ParamOut,errormsg] = read_field(FileName,FileType,ParamIn,num)
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
    erromsg=['input file ' FileName ' does not exist'];
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
    if isfield(ParamIn,'ColorVar')
        InputField=[ParamIn.FieldName {ParamIn.ColorVar}];
        check_colorvar=1;
    end
end

%% distingush different input file types
switch FileType
    case 'civdata'
        [Field,ParamOut.VelType,errormsg]=read_civdata(FileName,InputField,ParamIn.VelType);
        if ~isempty(errormsg),errormsg=['read_civdata / ' errormsg];return,end
        ParamOut.CivStage=Field.CivStage;
    case 'civx'
        ParamOut.FieldName='velocity';%Civx data found, set .FieldName='velocity' by default
        [Field,ParamOut.VelType,errormsg]=read_civxdata(FileName,InputField,ParamIn.VelType);
        if ~isempty(errormsg),errormsg=['read_civxdata / ' errormsg];return,end
        ParamOut.CivStage=Field.CivStage;
    case 'netcdf'
        ListVar={};
        for ilist=1:numel(InputField)
            r=regexp(InputField{ilist},'(?<Operator>(^vec|^norm))\((?<UName>.+),(?<VName>.+)\)$','names');
            if isempty(r)
                ListVar=[ListVar InputField(ilist)];
                Role{numel(ListVar)}='scalar';
                ProjModeRequest{numel(ListVar)}='interp_lin';%scalar field (requires interpolation for plot)
            else
                ListVar=[ListVar {r.UName,r.VName}];
                Role{numel(ListVar)}='vector_y';
                Role{numel(ListVar)-1}='vector_x';
                            switch r.Operator
                                case 'norm'
                                    ProjModeRequest{numel(ListVar)-1}='interp_lin';%scalar field (requires interpolation for plot)
                                    ProjModeRequest{numel(ListVar)}='interp_lin';
                                otherwise
                                   ProjModeRequest{numel(ListVar)-1}='';
                                   ProjModeRequest{numel(ListVar)}='';
                            end
            end
        end
        if check_colorvar
            Role{numel(ListVar)}='ancillary';% scalar used for color vector (not projected)
        end
        if isfield(ParamIn,'TimeDimName')% case of reading of a single time index in a multidimensional array
            [Field,var_detect,ichoice]=nc2struct(FileName,'TimeDimName',ParamIn.TimeDimName,num,[ParamIn.Coord_x (ParamIn.Coord_y) ListVar]);
        else
        [Field,var_detect,ichoice]=nc2struct(FileName,[ParamIn.Coord_x (ParamIn.Coord_y) ListVar]);
        end
        if isfield(Field,'Txt')
            errormsg=Field.Txt;
            return
        end
        for ivar=1:numel(ListVar)
            Field.VarAttribute{ivar+2}.Role=Role{ivar};
            if isfield(ParamIn,'FieldName')
                Field.VarAttribute{ivar+2}.FieldName=ParamIn.FieldName;
            end
            Field.VarAttribute{ivar+2}.ProjModeRequest=ProjModeRequest{ivar};
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
        warning 'off'
        A=imread(FileName,num);
    case 'image'
        A=imread(FileName);
end
if ~isempty(errormsg)
    errormsg=[FileType ' input: ' errormsg];
    return
end

%% case of image
if ~isempty(A)
    if isstruct(ParamOut)
        ParamOut.FieldName='image';
    end
    Npz=1;%default
    npxy=size(A);
    %     Rangx=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
    %     Rangy=[npxy(1)-0.5 0.5]; %
    Field.NbDim=2;%default
    Field.AName='image';
    Field.ListVarName={'AY','AX','A'}; %
    if ndims(A)==3
        if Npz==1;%color
            Field.VarDimName={'AY','AX',{'AY','AX','rgb'}}; %
            Field.AY=[npxy(1)-0.5 0.5];
            Field.AX=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
            if isstruct(ParamOut)
                ParamOut.Npx=npxy(2);% display image size on the interface
                ParamOut.Npy=npxy(1);
            end
            Field.VarAttribute{3}.Mesh=1;
        else
            Field.NbDim=3;
            Field.ListVarName=['AZ' Field.ListVarName];
            Field.VarDimName={'AZ','AY','AX',{'AZ','AY','AX'}};
            Field.AZ=[npxy(1)-0.5 0.5];
            Field.AY=[npxy(2)-0.5 0.5];
            Field.AX=[0.5 npxy(3)-0.5]; % coordinates of the first and last pixel centers
            if isstruct(ParamOut)
                ParamOut.Npx=npxy(3);% display image size on the interface
                ParamOut.Npy=npxy(2);
            end
            Field.VarAttribute{4}.Mesh=1;
        end
    else
        Field.VarDimName={'AY','AX',{'AY','AX'}}; %
        Field.AY=[npxy(1)-0.5 0.5];
        Field.AX=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
        ParamOut.Npx=npxy(2);% display image size on the interface
        ParamOut.Npy=npxy(1);
        Field.VarAttribute{3}.Mesh=1;
    end
    Field.A=A;
    Field.CoordUnit='pixel'; %used for mouse_motion
end



