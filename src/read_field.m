%'read_field': read the fields from files in different formats (netcdf files, images, video)
%--------------------------------------------------------------------------
%  function [Field,ParamOut,errormsg] = read_field(FileName,FileType,ParamIn,num)
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
% if isfield(ParamIn,'VelType')
% VelType=ParamIn.VelType;
% end
A=[];
%% distingush different input file types
try
    switch FileType
        case 'civdata'
%             ParamOut.FieldName='velocity';%Civx data found, set .FieldName='velocity' by default
%                         ParamOut.ColorVar='ima_cor';
                        if isfield(ParamIn,'ColorVar')
                        InputField=[{ParamIn.FieldName} {ParamIn.ColorVar}];
                        else
                           InputField= {ParamIn.FieldName};
                        end
                        [Field,ParamOut.VelType,errormsg]=read_civdata(FileName,InputField,ParamIn.VelType);
                        if ~isempty(errormsg),errormsg=['read_civdata:' errormsg];return,end
                        ParamOut.CivStage=Field.CivStage;
         case 'civx'
            ParamOut.FieldName='velocity';%Civx data found, set .FieldName='velocity' by default
                       % ParamOut.ColorVar='ima_cor';
                       if isfield(ParamIn,'ColorVar')
                        InputField=[{ParamIn.FieldName} {ParamIn.ColorVar}];
                        else
                           InputField= {ParamIn.FieldName};
                        end
                        [Field,ParamOut.VelType]=read_civxdata(FileName,InputField,ParamIn.VelType);
                        if ~isempty(errormsg),errormsg=['read_civxdata:' errormsg];return,end
                        ParamOut.CivStage=Field.CivStage;
        case 'netcdf'
            r=regexp(ParamIn.FieldName,'(^vec|^norm)\((?<UName>.+),(?<VName>.+)\)$','names');
            if isempty(r)
                ListVar={ParamIn.FieldName};
                input='scalar';
            else
                ListVar={r.UName,r.VName};
                input='vectors';
            end
            if ~isempty(ParamIn.ColorVar)
                r=regexp(ParamIn.ColorVar,'(^vec|^norm)\((?<UName>.+),(?<VName>.+)\)$','names');
                if isempty(r)
                    ListVar=[ListVar {ParamIn.ColorVar}];
                else
                    ListVar=[ListVar {r.UName,r.VName}];
                end
            end
                [Field,var_detect,ichoice]=nc2struct(FileName,[ParamIn.CoordName ListVar]);
                if strcmp(input,'vectors')
                    Field.VarAttribute{3}.Role='vector_x';
                    Field.VarAttribute{4}.Role='vector_y';
                else
                    Field.VarAttribute{3}.Role='scalar';
                end
%             GUIName='get_field'; %default name of the GUI get_field
%             if isfield(ParamIn,'GUIName')
%                 GUIName=ParamIn.GUIName;
%             end
%             CivStage=0;
% %             if ~strcmp(ParamIn.FieldName,'get_field...')% if get_field is not requested, look for Civx data
%                 FieldList=calc_field;%list of possible fields for Civx data
%                 ParamOut.ColorVar='';%default
%                 if ischar(ParamIn.FieldName)
%                     FieldName=ParamIn.FieldName;
%                 else
%                     FieldName=ParamIn.FieldName{1};
%                 end
%                 field_index=strcmp(FieldName,FieldList);%look for ParamIn.FieldName in the list of possible fields for Civx data
%                 if isempty(find(field_index,1))% ParamIn.FieldName is not in the list, check whether Civx data exist
%                     Data=nc2struct(FileName,'ListGlobalAttribute','Conventions','absolut_time_T0','civ','CivStage');
%                     % case of new civdata conventions
%                     if isequal(Data.Conventions,'uvmat/civdata')
%                         
%                         %case of old civx conventions
%                     elseif ~isempty(Data.absolut_time_T0)&& ~isequal(Data.civ,0)
%                         ParamOut.FieldName='velocity';%Civx data found, set .FieldName='velocity' by default
%                         ParamOut.ColorVar='ima_cor';
%                         InputField=[{ParamOut.FieldName} {ParamOut.ColorVar}];
%                         [Field,ParamOut.VelType]=read_civxdata(FileName,InputField,ParamIn.VelType);
%                         if ~isempty(errormsg),errormsg=['read_civxdata:' errormsg];return,end
%                         CivStage=Field.CivStage;
%                         ParamOut.CivStage=Field.CivStage;
%                         % not cvix file, fields will be chosen through the GUI get_field
%                     else
%                         ParamOut.FieldName='get_field...';
%                         hget_field=findobj(allchild(0),'Name',GUIName);%find the get_field... GUI
%                         if ~isempty(hget_field)
%                             delete(hget_field)%delete  get_field for reinitialisation
%                         end
%                     end
%                 else              
%                     InputField=ParamOut.FieldName;
%                     if ischar(InputField)
%                         InputField={InputField};
%                     end
%                     if isfield(ParamIn,'ColorVar')
%                         ParamOut.ColorVar=ParamIn.ColorVar;
%                         InputField=[InputField {ParamOut.ColorVar}];
%                     end
%                     [Field,ParamOut.VelType,errormsg]=read_civxdata(FileName,InputField,ParamIn.VelType);
%                     if ~isempty(errormsg),errormsg=['read_civxdata:' errormsg];return,end
%                     CivStage=Field.CivStage;
%                     ParamOut.CivStage=Field.CivStage;
%                 end
%                 ParamOut.FieldList=[{'image'};FieldList;{'get_field...'}];
%             end
%             if CivStage==0% read the field names on the interface get_field.
%                 hget_field=findobj(allchild(0),'Name',GUIName);%find the get_field... GUI
%                 if isempty(hget_field)% open the GUI get_field if it is not found
%                     hget_field= get_field(FileName);%open the get_field GUI
%                     set(hget_field,'Name',GUIName)%update the name of get_field (e.g. get_field_1)
%                 end
%                 hhget_field=guidata(hget_field);
%                 %% update  the get_field GUI
%                 set(hhget_field.inputfile,'String',FileName)
%                 set(hhget_field.list_fig,'Value',1)
%                 if exist('num','var')&&~isnan(num)
%                     set(hhget_field.TimeIndexValue,'String',num2str(num))
%                 end
% %                 funct_list=get(hhget_field.ACTION,'UserData');
% %                 funct_index=get(hhget_field.ACTION,'Value');
% %                 funct=funct_list{funct_index};%select  the current action in get_field, e;g. PLOT
% %                 Field=funct(hget_field); %%activate the current action selected in get_field, e;g.read the names of the variables to plot
%                 [Field,errormsg]=read_get_field(hget_field);
%                 Tabchar={''};%default
%                 Tabcell=[];
%                 set(hhget_field.inputfile,'String',FileName)
%                 if isfield(Field,'ListGlobalAttribute')&& ~isempty(Field.ListGlobalAttribute)
%                     for iline=1:length(Field.ListGlobalAttribute)
%                         Tabcell{iline,1}=Field.ListGlobalAttribute{iline};
%                         if isfield(Field, Field.ListGlobalAttribute{iline})
%                             val=Field.(Field.ListGlobalAttribute{iline});
%                             if ischar(val);
%                                 Tabcell{iline,2}=val;
%                             else
%                                 Tabcell{iline,2}=num2str(val);
%                             end
%                         end
%                     end
%                     if ~isempty(Tabcell)
%                         Tabchar=cell2tab(Tabcell,'=');
%                         Tabchar=[{''};Tabchar];
%                     end
%                 end
%                 ParamOut.CivStage=0;
%                 ParamOut.VelType=[];
%                 if isfield(Field,'TimeIndex')
%                     ParamOut.TimeIndex=Field.TimeIndex;
%                 end
%                 if isfield(Field,'TimeValue')
%                     ParamOut.TimeValue=Field.TimeValue;
%                 end
%                 ParamOut.FieldList={'get_field...'};

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
catch ME
    errormsg=[FileType ' input: ' ME.message];
    return
end

%% case of image
if ~isempty(A)
    if isstruct(ParamOut)
    ParamOut.FieldName='image';
    ParamOut.FieldList={'image'};
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



