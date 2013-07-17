%'merge_proj': concatene several fields from series, can project them on a regular grid in phys coordinates
%------------------------------------------------------------------------
% function ParamOut=merge_proj(Param)
%------------------------------------------------------------------------
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%OUTPUT
% ParamOut: sets options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% when Param.Action.RUN=0 (as activated when the current Action is selected
% in series), the function ouput paramOut set the activation of the needed GUI elements
%
% Param contains the elements:(use the menu bar command 'export/GUI config' in series to 
% see the current structure Param)
%    .InputTable: cell of input file names, (several lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDirExt: directory extension for data outputs
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%             .ActionExt: fct extension ('.m', Matlab fct, '.sh', compiled   Matlab fct
%             .RUN =0 for GUI input, =1 for function activation
%             .RunMode='local','background', 'cluster': type of function  use
%             
%    .IndexRange: set the file or frame indices on which the action must be performed
%    .FieldTransform: .TransformName: name of the selected transform function
%                     .TransformPath:   path  of the selected transform function
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%              .Coord_y: name of y coordinate variable
%              .Coord_x: name of x coordinate variable
%    .ProjObject: %sub structure describing a projection object (read from ancillary GUI set_object)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ParamOut=merge_proj(Param)

%% set the input elements needed on the GUI series when the function is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.ProjObject='on';%can use projection object(option 'off'/'on',
    ParamOut.Mask='on';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.mproj';%set the output dir extension
    ParamOut.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    filecell=get_file_series(Param);%check existence of the first input file
    if ~exist(filecell{1,1},'file')
        msgbox_uvmat('WARNING','the first input file does not exist')
    elseif isequal(size(Param.InputTable,1),1) && ~isfield(Param,'ProjObject')
        msgbox_uvmat('WARNING','You may need a projection object of type plane for merge_proj')
    end
    return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
ParamOut=[]; %default output
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% define the directory for result file (with path=RootPath{1})
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files

if ~isfield(Param,'InputFields')
    Param.InputFields.FieldName='';
end

%% root input file type
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
%%%%%%%%%%%%
% The cell array filecell is the list of input file names, while
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%%
% NbSlice=1;%default
% if isfield(Param.IndexRange,'NbSlice')&&~isempty(Param.IndexRange.NbSlice)
%     NbSlice=Param.IndexRange.NbSlice;
% end
NbView=numel(i1_series);%number of input file series (lines in InputTable)
NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video'};
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:NbView
    if ~exist(filecell{iview,1}','file')
        disp_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'],checkrun)
        return
    end
    [FileType{iview},FileInfo{iview},MovieObject{iview}]=get_file_type(filecell{iview,1});
    CheckImage{iview}=~isempty(find(strcmp(FileType{iview},ImageTypeOptions)));% =1 for images
    CheckNc{iview}=~isempty(find(strcmp(FileType{iview},NcTypeOptions)));% =1 for netcdf files
    if ~isempty(j1_series{iview})
        frame_index{iview}=j1_series{iview};
    else
        frame_index{iview}=i1_series{iview};
    end
end

%% calibration data and timing: read the ImaDoc files
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
if size(time,1)>1
    diff_time=max(max(diff(time)));
    if diff_time>0 
        disp_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time) ': time of first series chosen in result'],checkrun)
    end   
end

%% coordinate transform or other user defined transform
transform_fct='';%default fct handle
if isfield(Param,'FieldTransform')&&~isempty(Param.FieldTransform.TransformName)
        currentdir=pwd;
        cd(Param.FieldTransform.TransformPath)
        transform_fct=str2func(Param.FieldTransform.TransformName);
        cd (currentdir)
end
%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE

%% check the validity of  input file types
if CheckImage{1}
    FileExtOut='.png'; % write result as .png images for image inputs
elseif CheckNc{1}
    FileExtOut='.nc';% write result as .nc files for netcdf inputs
else
    disp_uvmat('ERROR',['invalid file type input ' FileType{1}],checkrun)
    return
end
for iview=1:NbView
    if ~isequal(CheckImage{iview},CheckImage{1})||~isequal(CheckNc{iview},CheckNc{1})
        disp_uvmat('ERROR','input set of input series: need  either netcdf either image series',checkrun)
        return
    end
end
NomTypeOut=NomType;% output file index will indicate the first and last ref index in the series

%% mask (TODO: case of multilevels)
MaskData=cell(NbView,1);
if Param.CheckMask
    for iview=1:numel(Param.MaskTable)
%     MaskData=cell(NbView,1);
%     MaskSubDir=regexprep(Param.InputTable{iview,2},'\..*','');%take the root part of SubDir, before the first dot '.'
%     MaskName=fullfile(Param.InputTable{iview,1},[MaskSubDir '.mask'],'mask_1.png');
%     if exist(MaskName,'file')
        [MaskData{iview},tild,errormsg] = read_field(Param.MaskTable{iview},'image');
        if ~isempty(transform_fct) && nargin(transform_fct)>=2
            MaskData{iview}=transform_fct(MaskData{iview},XmlData{iview});
        end
    end
end

%% Set field names and velocity types
%use Param.InputFields for all views

%% MAIN LOOP ON FIELDS
%%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
% for i_slice=1:NbSlice
%     index_slice=i_slice:NbSlice:NbField;% select file indices of the slice
%     NbFiles=0;
%     nbmissing=0;

    %%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
for index=1:NbField
        update_waitbar(WaitbarHandle,index/NbField)
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
    Data=cell(1,NbView);%initiate the set Data
    nbtime=0;
    for iview=1:NbView
        %% reading input file(s)
        [Data{iview},tild,errormsg] = read_field(filecell{iview,index},FileType{iview},Param.InputFields,frame_index{iview}(index));
        if ~isempty(errormsg)
            disp(['ERROR in merge_proj/read_field/' errormsg])
            return
        end
        timeread(iview)=0;
        if isfield(Data{iview},'Time')
            timeread(iview)=Data{iview}.Time;
            nbtime=nbtime+1;
        end
        if ~isempty(NbSlice_calib)
            Data{iview}.ZIndex=mod(i1_series{iview}(index)-1,NbSlice_calib{iview})+1;%Zindex for phys transform
        end
        
        %% transform the input field (e.g; phys) if requested (no transform involving two input fields)
        if ~isempty(transform_fct)
            if nargin(transform_fct)>=2
                Data{iview}=transform_fct(Data{iview},XmlData{iview});
            else
                Data{iview}=transform_fct(Data{iview});
            end
        end
        
        %% calculate tps coefficients if needed
        check_proj_tps= isfield(Param,'ProjObject')&&~isempty(Param.ProjObject)&& strcmp(Param.ProjObject.ProjMode,'interp_tps')&&~isfield(Data{iview},'Coord_tps');
        Data{iview}=tps_coeff_field(Data{iview},check_proj_tps);
        
        %% projection on object (gridded plane)
        if Param.CheckObject
            [Data{iview},errormsg]=proj_field(Data{iview},Param.ProjObject);
            if ~isempty(errormsg)
                disp(['ERROR in merge_proge/proj_field: ' errormsg])
                return
            end
        end
        
        %% mask
        if Param.CheckMask && ~isempty(MaskData{iview})
             [Data{iview},errormsg]=mask_proj(Data{iview},MaskData{iview});
        end
    end
    %----------END LOOP ON VIEWS----------------------

    %% merge the NbView fields
    MergeData=merge_field(Data);
    if isfield(MergeData,'Txt')
        disp(MergeData.Txt);
        return
    end

    % time of the merged field:
    if ~isempty(time)% time defined from ImaDoc
        timeread=time(:,index);
    end
    timeread=mean(timeread);

    % generating the name of the merged field
    i1=i1_series{iview}(index);
    if ~isempty(i2_series{iview})
        i2=i2_series{iview}(index);
    else
        i2=i1;
    end
    j1=1;
    j2=1;
    if ~isempty(j1_series{iview})
        j1=j1_series{iview}(index);
        if ~isempty(j2_series{iview})
            j2=j2_series{iview}(index);
        else
            j2=j1;
        end
    end
    OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},FileExtOut,NomType{1},i1,i2,j1,j2);

    % recording the merged field
    if CheckImage{1}    %in case of input images an image is produced
        if isa(MergeData.A,'uint8')
            bitdepth=8;
        elseif isa(MergeData.A,'uint16')
            bitdepth=16;
        end
        imwrite(MergeData.A,OutputFile,'BitDepth',bitdepth);
        %write xml calibration file
        siz=size(MergeData.A);
        npy=siz(1);
        npx=siz(2);
        if isfield(MergeData,'VarAttribute')&&isfield(MergeData.VarAttribute{1},'Coord_2')&&isfield(MergeData.VarAttribute{1},'Coord_1')
            Rangx=MergeData.VarAttribute{1}.Coord_2;
            Rangy=MergeData.VarAttribute{1}.Coord_1;
        elseif isfield(MergeData,'AX')&& isfield(MergeData,'AY')
            Rangx=[MergeData.AX(1) MergeData.AX(end)];
            Rangy=[MergeData.AY(1) MergeData.AY(end)];
        else
            Rangx=[0.5 npx-0.5];
            Rangy=[npy-0.5 0.5];%default
        end
        pxcmx=(npx-1)/(Rangx(2)-Rangx(1));
        pxcmy=(npy-1)/(Rangy(1)-Rangy(2));
        T_x=-pxcmx*Rangx(1)+0.5;
        T_y=-pxcmy*Rangy(2)+0.5;
        GeometryCal.focal=1;
        GeometryCal.R=[pxcmx,0,0;0,pxcmy,0;0,0,1];
        GeometryCal.Tx_Ty_Tz=[T_x T_y 1];
        ImaDoc.GeometryCalib=GeometryCal;
    else
        MergeData.ListGlobalAttribute={'Conventions','Project','InputFile_1','InputFile_end','nb_coord','nb_dim','dt','Time','civ'};
        MergeData.Conventions='uvmat';
        MergeData.nb_coord=2;
        MergeData.nb_dim=2;
        dt=[];
        if isfield(Data{1},'dt')&& isnumeric(Data{1}.dt)
            dt=Data{1}.dt;
        end
        for iview =2:numel(Data)
            if ~(isfield(Data{iview},'dt')&& isequal(Data{iview}.dt,dt))
                dt=[];%dt not the same for all fields
            end
        end
        if isempty(dt)
            MergeData.ListGlobalAttribute(6)=[];
        else
            MergeData.dt=dt;
        end
        MergeData.Time=timeread;
        error=struct2nc(OutputFile,MergeData);%save result file
        if isempty(error)
            display(['output file ' OutputFile ' written'])
        else
            display(error)
        end
    end
end


%'merge_field': concatene fields
%------------------------------------------------------------------------
function MergeData=merge_field(Data)
%% default output
if isempty(Data)||~iscell(Data)
    MergeData=[];
    return
end
error=0;
NbView=length(Data);
if NbView==1
    return
end
MergeData=Data{1};% merged field= first field by default, reproduces the glabal attributes of the first field

%% group the variables (fields of 'Data') in cells of variables with the same dimensions
[CellInfo,NbDim,errormsg]=find_field_cells(Data{1});

%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
for icell=1:length(CellInfo)
    if NbDim(icell)~=1 % skip field cells which are of dim 1
        switch CellInfo{icell}.CoordType
            case 'scattered'  %case of input fields with unstructured coordinates: just concacene data
                for ivar=CellInfo{icell}.VarIndex %  indices of the selected variables in the list FieldData.ListVarName
                    VarName=Data{1}.ListVarName{ivar};
                    %MergeData=Data{1};% merged field= first field by default, reproduces the glabal attributes of the first field
                    for iview=2:NbView
                        MergeData.(VarName)=[MergeData.(VarName); Data{iview}.(VarName)];
                    end
                end
            case 'grid'        %case of fields defined on a structured  grid
                FFName='';
                if ~isempty(CellInfo{icell}.VarIndex_errorflag)
                    FFName=Data{1}.ListVarName{CellInfo{icell}.VarIndex_errorflag};% name of errorflag variable
                end
                % select good data on each view
                for ivar=CellInfo{icell}.VarIndex  %  indices of the selected variables in the list FieldData.ListVarName
                    VarName=Data{1}.ListVarName{ivar};
                    for iview=1:NbView
                        if isempty(FFName)
                            check_bad=isnan(Data{iview}.(VarName));%=0 for NaN data values, 1 else
                        else
                            check_bad=isnan(Data{iview}.(VarName)) | Data{iview}.(FFName)~=0;%=0 for NaN or error flagged data values, 1 else
                        end
                        Data{iview}.(VarName)(check_bad)=0; %set to zero NaN or masked data
                        if iview==1
                            MergeData.(VarName)=Data{1}.(VarName);% correct the field of MergeData
                            NbAver=~check_bad;% initiate NbAver: the nbre of good data for each point
                        else
                            MergeData.(VarName)=MergeData.(VarName) + Data{iview}.(VarName);%add data
                            NbAver=NbAver + ~check_bad;% add 1 for good data, 0 else
                        end
                    end
                    MergeData.(VarName)(NbAver~=0)=MergeData.(VarName)(NbAver~=0)./NbAver(NbAver~=0);% take average of defined data at each point
                end
        end
        if isempty(FFName)
            FFName='FF';
        end
        MergeData.(FFName)(NbAver~=0)=0;% flag to 1 undefined summed data
        MergeData.(FFName)(NbAver==0)=1;% flag to 1 undefined summed data
    end
end


    