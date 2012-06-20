%'merge_proj': project and concatene fieldsmerge_proj
% can be used as a template for applying an operation (here projection and concateantion) on each field of an input series
%------------------------------------------------------------------------
% function GUI_config=merge_proj(Param)
%------------------------------------------------------------------------

%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function is used in four modes by the GUI series:
%           1) config GUI: with no input argument, the function determine the suitable GUI configuration
%           2) interactive input: the function is used to interactively introduce input parameters, and then stops
%           3) RUN: the function itself runs, when an appropriate input  structure Param has been introduced. 
%           4) BATCH: the function itself proceeds in BATCH mode, using an xml file 'Param' as input.
%
% This function is used in four modes by the GUI series:
%           1) config GUI: with no input argument, the function determine the suitable GUI configuration
%           2) interactive input: the function is used to interactively introduce input parameters, and then stops
%           3) RUN: the function itself runs, when an appropriate input  structure Param has been introduced. 
%           4) BATCH: the function itself proceeds in BATCH mode, using an xml file 'Param' as input.
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% In the absence of input (as activated when the current Action is selected
% in series), the function ouput GUI_input set the activation of the needed GUI elements
%
% Param contains the elements:(use the menu bar command 'export/GUI config' in series to see the current structure Param)
%    .InputTable: cell of input file names, (several lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDir: directory for data outputs, including path
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%    .IndexRange: set the file or frame indices on which the action must be performed
%    .FieldTransform: .TransformName: name of the selected transform function
%                     .TransformPath:   path  of the selected transform function
%                     .TransformHandle: corresponding function handle
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%    .ProjObject: %sub structure describing a projection object (read from ancillary GUI set_object)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ParamOut=merge_proj(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if ~exist('Param','var') % case with no input parameter 
    ParamOut={'NbViewMax';'';...% max nbre of input file series (default='' , no limitation)
        'AllowInputSort';'off';...% allow alphabetic sorting of the list of input files (options 'off'/'on', 'off' by default)
        'WholeIndexRange';'off';...% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelType';'one';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
        'FieldName';'one';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'FieldTransform'; 'on';...%can use a transform function
        'ProjObject';'on';...%can use projection object(option 'off'/'on',
        'Mask';'off';...%can use mask option   (option 'off'/'on', 'off' by default)
        'OutputDirExt';'.mproj';...%set the output dir extension
               ''};
        return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
%% select different modes,  RUN, parameter input, BATCH
% BATCH  case: read the xml file for batch case
if ischar(Param)
        Param=xml2struct(Param);
        checkrun=0;
% RUN case: parameters introduced as the input structure Param
else
    hseries=guidata(Param.hseries);%handles of the GUI series
    WaitbarPos=get(hseries.waitbar_frame,'Position');%position of the waitbar on the GUI series
    if isfield(Param,'Specific')&& strcmp(Param.Specific,'?')
        checkrun=1;% will only search interactive input parameters (preparation of BATCH mode)
    else
        checkrun=2; % indicate the RUN option is used
    end
end
ParamOut=Param; %default output

%% root input file(s) and type
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);

% get the set of input file names (cell array filecell), and the lists of
% input file or frame indices i1_series,i2_series,j1_series,j2_series
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% filecell{iview,fileindex}: cell array representing the list of file names
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
% set of frame indices used for movie or multimage input 
% numbers of slices and file indices

NbSlice=1;%default
if isfield(Param.IndexRange,'NbSlice')&&~isempty(Param.IndexRange.NbSlice)
    NbSlice=Param.IndexRange.NbSlice;
end
nbview=numel(i1_series);%number of input file series (lines in InputTable)
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields
nbfield_i=floor(nbfield/NbSlice);%total number of  indexes in a slice (adjusted to an integer number of slices) 
nbfield=nbfield_i*NbSlice; %total number of fields after adjustement

%determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video'};
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:nbview
    if ~exist(filecell{iview,1}','file')
        msgbox_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'])
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
mode=''; %default
timecell={};
itime=0;
NbSlice_calib={};
XmlData=cell(1,nbview);%initiate the structures containing the data from the xml file (calibration and timing)
for iview=1:nbview%Loop on views
    SubDirBase=regexprep(SubDir{iview},'\..*','');%take the root part of SubDir, before the first dot '.'
    filexml=[fullfile(RootPath{iview},SubDirBase) '.xml'];%new convention: xml at the level of the image folder
    if ~exist(filexml,'file')
        filexml=[fullfile(RootPath{iview},SubDir{iview},RootFile{iview}) '.xml']; % old convention: xml inside the image folder
        if ~exist(filexml,'file')
            filexml=[fullfile(RootPath{iview},SubDir{iview},RootFile{iview}) '.civ']; % very old convention: .civ file
            if ~exist(filexml,'file')
                filexml='';
            end
        end
    end
    if ~isempty(filexml)
        [XmlData{iview},error]=imadoc2struct(filexml);
    end
    if isfield(XmlData{iview},'Time')
        itime=itime+1;
        timecell{itime}=XmlData{iview}.Time;
    end
    if isfield(XmlData{iview},'GeometryCalib') && isfield(XmlData{iview}.GeometryCalib,'SliceCoord')
        NbSlice_calib{iview}=size(XmlData{iview}.GeometryCalib.SliceCoord,1);%nbre of slices for Zindex in phys transform
        if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
            msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
        end
    end
end

%% check coincidence in time for several input file series
multitime=0;
if isempty(timecell)
    time=[];
elseif length(timecell)==1
    time=timecell{1};
elseif length(timecell)>1
    multitime=1;
    for icell=1:length(timecell)
        if ~isequal(size(timecell{icell}),size(timecell{1}))
            msgbox_uvmat('WARNING','inconsistent time array dimensions in ImaDoc fields, the time for the first series is used')
            time=timecell{1};
            multitime=0;
            break
        end
    end
end
if multitime
    for icell=1:length(timecell)
        time(icell,:,:)=timecell{icell};
    end
    diff_time=max(max(diff(time)));
    if diff_time>0
        msgbox_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time)])
    end   
end
if size(time,2) < i2_series{1}(end) ||( ~isempty(j2_series{1}) && size(time,3) < j2_series{1}(end))% time array absent or too short in ImaDoc xml file' 
    time=[];
end

%% coordinate transform or other user defined transform
transform_fct='';%default
if isfield(Param,'FieldTransform')&&isfield(Param.FieldTransform,'TransformHandle')
    transform_fct=Param.FieldTransform.TransformHandle;
end
%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE

%% check the validity of  input file types
if CheckImage{1}
    FileExtOut='.png'; % write result as .png images for image inputs
elseif CheckNc{1}
    FileExtOut='.nc';% write result as .nc files for netcdf inputs
else 
    msgbox_uvmat('ERROR',['invalid file type input ' FileType{1}])
    return
end
for iview=1:nbview
	if ~isequal(CheckImage{iview},CheckImage{1})||~isequal(CheckNc{iview},CheckNc{1})
        msgbox_uvmat('ERROR','input set of input series: need  either netcdf either image series')
    return
end
NomTypeOut=NomType;% output file index will indicate the first and last ref index in the series

%% Set field names and velocity types
%use Param.InputFields for all views

%% Initiate output fields
%initiate the output structure as a copy of the first input one (reproduce fields)
[DataOut,ParamOut,errormsg] = read_field(filecell{1,1},FileType{1},Param.InputFields,1);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['error reading ' filecell{1,1} ': ' errormsg])
    return
end
time_1=[];
if isfield(DataOut,'Time')
    time_1=DataOut.Time(1);
end
if CheckNc{iview}
    if isempty(strcmp('Conventions',DataOut.ListGlobalAttribute))
        DataOut.ListGlobalAttribute=['Conventions' DataOut.ListGlobalAttribute];
    end
    DataOut.Conventions='uvmat';
    DataOut.ListGlobalAttribute=[DataOut.ListGlobalAttribute {Param.Action}];
    ActionKey='Action';
    while isfield(DataOut,ActionKey)
        ActionKey=[ActionKey '_1'];
    end
    DataOut.(ActionKey)=Param.Action;
    DataOut.ListGlobalAttribute=[DataOut.ListGlobalAttribute {ActionKey}];
    if isfield(DataOut,'Time')
        DataOut.ListGlobalAttribute=[DataOut.ListGlobalAttribute {'Time','Time_end'}];
    end
end

%% MAIN LOOP ON SLICES
%%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
for i_slice=1:NbSlice
    index_slice=i_slice:NbSlice:nbfield;% select file indices of the slice
    nbfiles=0;
    nbmissing=0;
    
   %initiate result fields
   
   for ivar=1:length(DataOut.ListVarName)
       DataOut.(DataOut.ListVarName{ivar})=0; % initialise all fields to zero
   end

    %%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
    for index=index_slice
        if checkrun
            update_waitbar(hseries.waitbar_frame,WaitbarPos,index/(nbfield))
            stopstate=get(hseries.RUN,'BusyAction');
        else
            stopstate='queue';
        end
        
        %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
        Data=cell(1,nbview);%initiate the set Data
        for iview=1:nbview
            % reading input file(s)
            [Data{iview},ParamOut,errormsg] = read_field(filecell{iview,index},FileType{iview},Param.InputFields,frame_index{iview}(index));
            if ~isempty(errormsg)
                errormsg=['error of input reading: ' errormsg];
                break
            end
            if ~isempty(NbSlice_calib)
                Data{iview}.ZIndex=mod(i1_series{iview}(index)-1,NbSlice_calib{iview})+1;%Zindex for phys transform
            end
         %transform the input field (e.g; phys) if requested
            if ~isempty(transform_fct)
                Data{iview}=transform_fct(Data{iview},XmlData{iview});  %transform to phys if requested
            end
                        % field calculation (vort, div...)
            if strcmp(FileType{1},'civx')||strcmp(FileType{1},'civ')
                Data{iview}=calc_field(Param.InputFields.FieldName,Data{iview});%calculate field (vort..)
            end
           
         %projection on object (gridded plane)
            if test_object
                [Data{iview},errormsg]=proj_field(Data{iview},ProjObject);
                if ~isempty(errormsg)
                    msgbox_uvmat('ERROR',['error in merge_proge/proj_field: ' errormsg])
                    return
                end
            end
        end    
        %----------END LOOP ON VIEWS----------------------
         
        %% merge the nbview fields
        MergeData=merge_field(Data);
        if isfield(MergeData,'Txt')
            msgbox_uvmat('ERROR',MergeData.Txt)
            return
        end        
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
     OutputFile=fullfile_uvmat(RootPath{1},Param.OutputSubDir,RootFile{1},FileExtOut,NomType{1},i1,i2,j1,j2);
           
     % time of the merged field:
        time_i=0;%default
        if isempty(time)% time from ImaDoc prevails
            time_i=sum(timeread)/nbtime;
        else
           % time_i=i1;
            time_i=(time(i1,j1)+time(i2,j2))/2; %TODO: upgrade
        end
        
     % recording the merged field
        if testima    %in case of input images an image is produced   
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
            t=struct2xml(ImaDoc);
            t=set(t,1,'name','ImaDoc');
            save(t,[filebase_merge '.xml'])     
            display([filebase_merge '.xml saved'])
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
            MergeData.Time=time_i;
            error=struct2nc(OutputFile,MergeData);%save result file
            if isempty(error)
                display(['output file ' OutputFile ' written'])
            else
                display(error)
            end
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
MergeData=Data{1};%default
error=0;
nbview=length(Data);
if nbview==1
    return
end

%% group the variables (fields of 'FieldData') in cells of variables with the same dimensions
[CellVarIndex,NbDim,VarTypeCell]=find_field_indices(Data{1});
%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
% CellVarIndex=cells of variable index arrays
ivar_new=0; % index of the current variable in the projected field
for icell=1:length(CellVarIndex)
    if NbDim(icell)==1
        continue
    end
    VarIndex=CellVarIndex{icell};%  indices of the selected variables in the list FieldData.ListVarName
    VarType=VarTypeCell{icell};
    ivar_X=VarType.coord_x;
    ivar_Y=VarType.coord_y;
    ivar_FF=VarType.errorflag;
    if isempty(ivar_X)
        test_grid=1;%test for input data on regular grid (e.g. image)coordinates
    else
        if length(ivar_Y)~=1
                msgbox_uvmat('ERROR','y coordinate missing in proj_field.m')
                return
        end
        test_grid=0;
    end
    %case of input fields with unstructured coordinates
    if ~test_grid
        for ivar=VarIndex
            VarName=MergeData.ListVarName{ivar};
            for iview=1:nbview
                eval(['MergeData.' VarName '=[MergeData.' VarName '; Data{iview}.' VarName '];'])
            end
        end
    %case of fields defined on a structured  grid 
    else  
        testFF=0;
        for iview=2:nbview
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                if isfield(MergeData,'VarAttribute')
                    if length(MergeData.VarAttribute)>=ivar && isfield(MergeData.VarAttribute{ivar},'Role') && isequal(MergeData.VarAttribute{ivar}.Role,'errorflag')
                        testFF=1;
                    end
                end
                eval(['MergeData.' VarName '=MergeData.' VarName '+ Data{iview}.' VarName ';'])
            end
        end
        if testFF
            nbaver=nbview-MergeData.FF;
            indgood=find(nbaver>0);
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                eval(['MergeData.' VarName '(indgood)=double(MergeData.' VarName '(indgood))./nbaver(indgood);'])
            end 
        else
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                eval(['MergeData.' VarName '=double(MergeData.' VarName ')./nbview;'])
            end    
        end
    end
end

    