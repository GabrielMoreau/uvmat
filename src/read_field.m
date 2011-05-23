%'read_field': read input fields in different formats
%--------------------------------------------------------------------------
%  function [Field,ParamOut,errormsg] = read_field(ObjectName,FileType,ParamIn)
%
% OUTPUT:
% Field: matlab structure representing the field
% ParamOut: structure representing parameters:
%        .FieldName; field name
%        .FieldList: menu of possible fields
%        .VelType
%        .CivStage: stage of civx processing (=0, not Civx, =1 (civ1), =2  (fix1)....     
%        .Npx,.Npy: for images, nbre of pixels in x and y
% errormsg: error message, ='' by default
%
%INPUT
% ObjectName: name of the input file, or movie object when the Matlab function mmreader is used
% FileType: type of file
%     = netcdf : netcdf file 
%     = image : usual image as recognised by Matlab
%     = multimage: image series stored in a single file
%     = movie: movie read with mmreader
%     = avi: avi movie read with aviread (OBSOLETE, used only when mmreader is not available, old versions of Matlab)
%     = vol: images representing scanned volume (images concatened in the y direction)
% ParamIn: Matlab structure of input parameters
%     .FieldName: name of the input field (for Civx data)
%     .VelType: type of velocity data ('civ1', 'filter1', 'civ2'...)
%     .ColorVar: variable used for vector color
%     .Npx, .Npy: nbre of pixels along x and y (used for .vol input files)
function [Field,ParamOut,errormsg] = read_field(ObjectName,FileType,ParamIn,num)
Field=[];
ParamOut=[];
errormsg='';
if isfield(ParamIn,'VelType')
VelType=ParamIn.VelType;
end

%% case of netcdf input file
if strcmp(FileType,'netcdf')  %read the first nc field
    ParamOut.FieldName=ParamIn.FieldName;
    GUIName='get_field'; %default name of the GUI get_field
    if isfield(ParamIn,'GUIName')
        GUIName=ParamIn.GUIName;
    end
    test_civx=0;
    if ~strcmp(ParamIn.FieldName,'get_field...')% if get_field is not requested, look for Civx data
        FieldList=calc_field;%list of possible fields for Civx data
        ParamOut.ColorVar='';%default
        field_index=strcmp(ParamIn.FieldName,FieldList);%look for ParamIn.FieldName in the list of possible fields for Civx data
        if isempty(find(field_index,1))% ParamIn.FieldName is not in the list, check whether Civx data exist
            Data=nc2struct(ObjectName,'ListGlobalAttribute','Conventions','absolut_time_T0','civ');
            if isequal(Data.Conventions,'uvmat/civdata')
                ParamOut.FieldName='velocity';%Civx data found, set .FieldName='velocity' by default
                ParamOut.ColorVar='ima_cor';
                InputField=[{ParamOut.FieldName} {ParamOut.ColorVar}];
                [Field,ParamOut.VelType]=read_civdata(ObjectName,InputField,ParamIn.VelType);
                test_civx=Field.CivStage;
            elseif ~isempty(Data.absolut_time_T0)&& ~isequal(Data.civ,0)
                ParamOut.FieldName='velocity';%Civx data found, set .FieldName='velocity' by default
                ParamOut.ColorVar='ima_cor';
                InputField=[{ParamOut.FieldName} {ParamOut.ColorVar}];
                [Field,ParamOut.VelType]=read_civxdata(ObjectName,InputField,ParamIn.VelType);
                test_civx=Field.CivStage;
                ParamOut.CivStage=Field.CivStage;
            else % not cvix file, fields will be chosen through the GUI get_field
                ParamOut.FieldName='get_field...';
                hget_field=findobj(allchild(0),'Name',GUIName);%find the get_field... GUI
                if ~isempty(hget_field)
                    delete(hget_field)%delete  get_field for reinitialisation
                end
            end
        else
            InputField={ParamOut.FieldName};
            if isfield(ParamIn,'ColorVar')
                ParamOut.ColorVar=ParamIn.ColorVar;
                InputField=[InputField {ParamOut.ColorVar}];
            end
            [Field,ParamOut.VelType,errormsg]=read_civxdata(ObjectName,InputField,ParamIn.VelType);
            if ~isempty(errormsg)
                return
            end
            test_civx=Field.CivStage;
            ParamOut.CivStage=Field.CivStage;
        end
    end
    if ~test_civx% read the field names on the interface get_field.
        hget_field=findobj(allchild(0),'Name',GUIName);%find the get_field... GUI
        if isempty(hget_field)% open the GUI get_field if it is not found
            hget_field= get_field(ObjectName);%open the get_field GUI
            set(hget_field,'Name',GUIName)%update the name of get_field (e.g. get_field_1)
        end
        hhget_field=guidata(hget_field);
        %% update  the get_field GUI
        set(hhget_field.inputfile,'String',ObjectName)
        set(hhget_field.list_fig,'Value',1)
        if exist('num','var')&&~isnan(num)
            set(hhget_field.TimeIndexValue,'String',num2str(num))
        end
        funct_list=get(hhget_field.ACTION,'UserData');
        funct_index=get(hhget_field.ACTION,'Value');
        funct=funct_list{funct_index};%select  the current action in get_field, e;g. PLOT
        Field=funct(hget_field); %%activate the current action selected in get_field, e;g.read the names of the variables to plot
        Tabchar={''};%default
        Tabcell=[];
        set(hhget_field.inputfile,'String',ObjectName)
        if isfield(Field,'ListGlobalAttribute')&& ~isempty(Field.ListGlobalAttribute)
            for iline=1:length(Field.ListGlobalAttribute)
                Tabcell{iline,1}=Field.ListGlobalAttribute{iline};
                if isfield(Field, Field.ListGlobalAttribute{iline})
                    eval(['val=Field.' Field.ListGlobalAttribute{iline} ';'])
                    if ischar(val);
                        Tabcell{iline,2}=val;
                    else
                        Tabcell{iline,2}=num2str(val);
                    end
                end
            end
            if ~isempty(Tabcell)
                Tabchar=cell2tab(Tabcell,'=');
                Tabchar=[{''};Tabchar];
            end
        end
        %set(hhget_field.attributes,'String',Tabchar);%update list of global attributes in get_field
        ParamOut.CivStage=0;
        ParamOut.VelType=[];
        if isfield(Field,'TimeIndex')
            ParamOut.TimeIndex=Field.TimeIndex;
        end
        if isfield(Field,'TimeValue')
            ParamOut.TimeValue=Field.TimeValue;
        end
    end
    if test_civx
        ParamOut.FieldList=[{'image'};FieldList;{'get_field...'}];
    else
        ParamOut.FieldList={'get_field...'};
    end
else
    
    %% case of image
    ParamOut.FieldName='image';
    ParamOut.FieldList={'image'};
    Npz=1;%default
    switch FileType
        case 'movie'
            try
                A=read(ObjectName,num);
                FieldName='image';
            catch ME
                errormsg=ME.message;
                return
            end
        case 'avi'
            try
                mov=aviread(ObjectName,num);
            catch ME
                errormsg=ME.message;
                return
            end
            A=frame2im(mov(1));
            FieldName='image';
        case 'vol'
            A=imread(ObjectName);
            Npz=size(A,1)/ParamIn.Npy;
            A=reshape(A',ParamIn.Npx,ParamIn.Npy,Npz);
            A=permute(A,[3 2 1]);
            FieldName='image';
        case 'multimage'
            A=imread(ObjectName,num);
            FieldName='image';
        case 'image'
            A=imread(ObjectName);
            FieldName='image';
    end
    npxy=size(A);
    Rangx=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
    Rangy=[npxy(1)-0.5 0.5]; %
    Field.NbDim=2;%default
    Field.AName='image';
    Field.ListVarName={'AY','AX','A'}; %
    if ndims(A)==3
        if Npz==1;%color
            Field.VarDimName={'AY','AX',{'AY','AX','rgb'}}; %
            Field.AY=[npxy(1)-0.5 0.5];
            Field.AX=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
            ParamOut.Npx=npxy(2);% display image size on the interface
            ParamOut.Npy=npxy(1);
            Field.VarAttribute{3}.Mesh=1;
        else
            Field.NbDim=3;
            Field.ListVarName=['AZ' Field.ListVarName];
            Field.VarDimName={'AZ','AY','AX',{'AZ','AY','AX'}};
            Field.AZ=[npxy(1)-0.5 0.5];
            Field.AY=[npxy(2)-0.5 0.5];
            Field.AX=[0.5 npxy(3)-0.5]; % coordinates of the first and last pixel centers
            ParamOut.Npx=npxy(3);% display image size on the interface
            ParamOut.Npy=npxy(2);
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


