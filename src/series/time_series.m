%'time_series': extract a time series, used with series.fig
% this function can be used as a template for applying a global operation on a series of input fields
%------------------------------------------------------------------------
% function GUI_input=time_series(Param)
%
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
%
function ParamOut=time_series(Param) 

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if ~exist('Param','var') % case with no input parameter 
    ParamOut={'NbViewMax';2;...% max nbre of input file series (default='' , no limitation)
        'AllowInputSort';'off';...% allow alphabetic sorting of the list of input files (options 'off'/'on', 'off' by default)
        'WholeIndexRange';'off';...% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelType';'two';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
        'FieldName';'two';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'FieldTransform'; 'on';...%can use a transform function
        'ProjObject';'on';...%can use projection object(option 'off'/'on',
        'Mask';'off';...%can use mask option   (option 'off'/'on', 'off' by default)
        'OutputDirExt';'.tseries';...%set the output dir extension
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
if nbview==2 && ~isequal(CheckImage{1},CheckImage{2})
        msgbox_uvmat('ERROR','input must be two image series or two netcdf file series')
    return
end
NomTypeOut='_1-2_1';% output file index will indicate the first and last ref index in the series
if NbSlice~=nbfield_j
    answer=msgbox_uvmat('INPUT_Y-N',['will not average slice by slice: for so cancel and set NbSlice= ' num2str(nbfield_j)]);
    if ~strcmp(answer,'Yes')
        return
    end
end

%% Set field names and velocity types
InputFields{1}=[];%default (case of images)
if isfield(Param,'InputFields')
    InputFields{1}=Param.InputFields;
end
if nbview==2
    InputFields{2}=[];%default (case of images)
    if isfield(Param,'InputFields')
        InputFields{2}=Param.InputFields{1};%default
        if isfield(Param.InputFields,'FieldName_1')
            InputFields{2}.FieldName=Param.InputFields.FieldName_1;
            if isfield(Param.InputFields,'VelType_1')
                InputFields{2}.VelType=Param.InputFields.VelType_1;
            end
        end
    end
end
%%% TO UPDATE
if isequal(InputFields{1},'get_field...')
    hget_field=findobj(allchild(0),'name','get_field');%find the get_field... GUI
    if numel(hget_field)>1
        delete(hget_field(2:end)) % delete multiple occurerence of the GUI get_fioeld
    elseif isempty(hget_field)
        filename=filecell{1,1};
      % filename=name_generator(filebase{1},i1_series{1}(1),j1_series{1}(1),FileExt{1},NomType{1},1,i2_series{1}(1),num_j2{1}(1),SubDir{1}); 
       idetect(iview)=exist(filename,'file');
       hget_field=get_field(filename);
       return
    end
    SubField=read_get_field(hget_field); %read the names of the variables to plot in the get_field GUI
    if isempty(SubField)
        delete(hget_field)
        filename=filecell{1,1};
       %filename=name_generator(filebase{1},i1_series{1}(1),j1_series{1}(1),FileExt{1},NomType{1},1,i2_series{1}(1),j2_series{1}(1),SubDir{1});
        hget_field=get_field(filename);
        SubField=read_get_field(hget_field); %read the names of the variables to plot in the get_field GUI
    end
end
%%%%%%%

%% Initiate output fields
%initiate the output structure as a copy of the first input one (reproduce fields)
[DataOut,ParamOut,errormsg] = read_field(filecell{1,1},FileType{1},InputFields{1},1);
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

%% LOOP ON SLICES
nbmissing=0; %number of undetected files
for i_slice=1:NbSlice
    dt=[];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%  LOOP ON FIELDS WITHIN  A SLICE
    filecounter=0;
    for ifile=i_slice:NbSlice:nbfield
        if checkrun
            update_waitbar(hseries.waitbar_frame,WaitbarPos,ifile/nbfield)
            stopstate=get(hseries.RUN,'BusyAction');
        else
            stopstate='queue';
        end
        errormsg='';
        if isequal(stopstate,'queue')% enable STOP command
            % loop on views (in case of multiple input series)
            for iview=1:nbview
                filename=filecell{iview,ifile};
               % filename=name_generator(filebase{iview},...
                %    i1_series{iview}(ifile),j1_series{iview}(ifile),FileExt{iview},NomType{iview},1,i2_series{iview}(ifile),j2_series{iview}(ifile),SubDir{iview});
                if exist(filename,'file')
                    try
                        Data{iview}=[]; %default
                        if ~isequal(FileType{iview},'netcdf')
                            Data{iview}.ListVarName={'A'};
                            Data{iview}.AName='image';
                            switch FileType{iview}
                                case 'movie'
                                    A=read(MovieObject{iview},i1_series{iview}(ifile));
                                case 'avi'
                                    mov=aviread(filename,i1_series{iview}(ifile));
                                    A=frame2im(mov(1));
                                case 'vol'
                                    A=imread(filename);
                                case 'multimage'
                                    A=imread(filename,i1_series{iview}(ifile));
                                case 'image'
                                    A=imread(filename);
                            end
                            Data{iview}.ListVarName={'AY','AX','A'}; %
                            npy=size(A,1);
                            npx=size(A,2);
                            nbcolor=size(A,3);
                            if nbcolor==3
                                Data{iview}.VarDimName={'AY','AX',{'AY','AX','rgb'}};
                            else
                                Data{iview}.VarDimName={'AY','AX',{'AY','AX'}};
                            end
                            Data{iview}.AY=[npy-0.5 0.5];
                            Data{iview}.AX=[0.5 npx-0.5];
                            Data{iview}.A=double(A);
                            Data{iview}.CoordUnit='pixel';
                        elseif testcivx
                            [Data{iview},VelTypeOut]=read_civxdata(filename,FieldName,VelType);
                            if ~isequal(FieldName,{''})
                                Data{iview}=calc_field(FieldName,Data{iview});%calculate field (vort..)
                            end
                        else
                            [Data{iview},var_detect]=nc2struct(filename,SubField.ListVarName); %read the corresponding input data
                            Data{iview}.VarAttribute=SubField.VarAttribute;
                        end
                        if ~isempty(NbSlice_calib)  % z index
                            Data{iview}.ZIndex=mod(i1_series{iview}(ifile)-1,NbSlice_calib{1})+1;
                        end
                    catch ME
                        errormsg=ME.message;
                    end
                else
                    errormsg=[filename ' is missing'];
                end
                if isempty(errormsg)
                    % coordinate transform (or other user defined transform)
                    if ~isempty(transform_fct)
                        if nbview==2
                            [Data{1},Data{2}]=transform_fct(Data{1},XmlData{1},Data{2},XmlData{2});
                            if isempty(Data{2})
                                Data(2)=[];
                            end
                        else
                            Data{1}=transform_fct(Data{1},XmlData{1});
                        end
                    end
                    if length(Data)==2
                        [Field,errormsg]=sub_field(Data{1},Data{2}); %substract the two fields
                    else
                        Field=Data{1};
                    end
                    if Param.CheckObject
                        [Field,errormsg]=proj_field(Field,Param.ProjObject);
                    end
                end
                filecounter=filecounter+1;
                
                % initiate the time series at the first iteration
                if filecounter==1
                    % stop program if the first field reading is in error
                    if ~isempty(errormsg)
                        msgbox_uvmat('ERROR',['error in time_series/sub_field:' errormsg])
                        return
                    end
                    DataOut=Field;%default
                    DataOut.NbDim=Field.NbDim+1; %add the time dimension for plots
                    nbvar=length(Field.ListVarName);
                    if nbvar==0
                        msgbox_uvmat('ERROR','no input variable selected in get_field')
                        return
                    end
                    testsum=2*ones(1,nbvar);%initiate flag for action on each variable
                    if isfield(Field,'VarAttribute') % look for coordinate and flag variables
                        for ivar=1:nbvar
                            if length(Field.VarAttribute)>=ivar && isfield(Field.VarAttribute{ivar},'Role')
                                var_role=Field.VarAttribute{ivar}.Role;%'role' of the variable
                                if isequal(var_role,'errorflag')
                                    msgbox_uvmat('ERROR','do not handle error flags in time series')
                                    return
                                end
                                if isequal(var_role,'warnflag')
                                    testsum(ivar)=0;  % not recorded variable
                                    eval(['DataOut=rmfield(DataOut,''' Field.ListVarName{ivar} ''');']);%remove variable
                                end
                                if isequal(var_role,'coord_x')| isequal(var_role,'coord_y')|...
                                        isequal(var_role,'coord_z')|isequal(var_role,'coord')
                                    testsum(ivar)=1; %constant coordinates, record without time evolution
                                end
                            end
                            % check whether the variable ivar is a dimension variable
                            DimCell=Field.VarDimName{ivar};
                            if ischar(DimCell)
                                DimCell={DimCell};
                            end
                            if numel(DimCell)==1 && isequal(Field.ListVarName{ivar},DimCell{1})%detect dimension variables
                                testsum(ivar)=1;
                            end
                        end
                    end
                    for ivar=1:nbvar
                        if testsum(ivar)==2
                            eval(['DataOut.' Field.ListVarName{ivar} '=[];'])
                        end
                    end
                    DataOut.ListVarName=[{'Time'} DataOut.ListVarName];
                end
                
                % add data to the current field
                for ivar=1:length(Field.ListVarName)
                    VarName=Field.ListVarName{ivar};
                    VarVal=Field.(VarName);
                    if testsum(ivar)==2% test for recorded variable
                        if isempty(errormsg)
                            if isequal(Param.ProjObject.ProjMode,'inside')% take the average in the domain for 'inside' mode
                                if isempty(VarVal)
                                    msgbox_uvmat('ERROR',['empty result at frame index ' num2str(i1_series{iview}(ifile))])
                                    return
                                end
                                VarVal=mean(VarVal,1);
                            end
                            VarVal=shiftdim(VarVal,-1); %shift dimension
                            DataOut.(VarName)=cat(1,DataOut.(VarName),VarVal);%concanete the current field to the time series
                        else
                            DataOut.(VarName)=cat(1,DataOut.(VarName),0);% put each variable to 0 in case of input reading error
                        end
                    elseif testsum(ivar)==1% variable representing fixed coordinates
                        eval(['VarInit=DataOut.' VarName ';']);
                        if isempty(errormsg) && ~isequal(VarVal,VarInit)
                            msgbox_uvmat('ERROR',['time series requires constant coordinates ' VarName])
                            return
                        end
                    end
                end
                
                % record the time:
                if isempty(time)% time read in ncfiles
                    if isfield(Field,'Time')
                        DataOut.Time(filecounter,1)=Field.Time;
                    else
                        DataOut.Time(filecounter,1)=ifile;%default
                    end
                else % time from ImaDoc prevails  TODO: correct 
                  %  DataOut.Time(filecounter,1)=time{1}(i1_series{1})(ifile),j1_series{1}(ifile))+time(end,i2_series{end}(ifile),j2_series{end}(ifile)))/2;
                  DataOut.Time(filecounter,1)=i1_series{1}(ifile);% TODO : generalise
                end
                
                % record the number of missing input fields
                if ~isempty(errormsg)
                    nbmissing=nbmissing+1;
                    display(['ifile=' num2str(ifile) ':' errormsg])
                end
            end
        end
    end
    %%%%%%% END OF LOOP WITHIN A SLICE
   
    %remove time for global attributes if exists
    Time_index=find(strcmp('Time',DataOut.ListGlobalAttribute));
    if ~isempty(Time_index)
        DataOut.ListGlobalAttribute(Time_index)=[];
    end
    DataOut.Conventions='uvmat';
    for ivar=1:numel(DataOut.ListVarName)
        VarName=DataOut.ListVarName{ivar};
        eval(['DataOut.' VarName '=squeeze(DataOut.' VarName ');']) %remove singletons
    end
    
    % add time dimension 
    for ivar=1:length(Field.ListVarName)
        DimCell=Field.VarDimName(ivar);
        if testsum(ivar)==2%variable used as time series
            DataOut.VarDimName{ivar}=[{'Time'} DimCell];
        elseif testsum(ivar)==1
            DataOut.VarDimName{ivar}=DimCell;
        end
    end
    indexremove=find(~testsum);
    if ~isempty(indexremove)
        DataOut.ListVarName(1+indexremove)=[];
        DataOut.VarDimName(indexremove)=[];
        if isfield(DataOut,'Role') && ~isempty(DataOut.Role{1})%generaliser aus autres attributs
            DataOut.Role(1+indexremove)=[];
        end
    end
    
    %shift variable attributes
    if isfield(DataOut,'VarAttribute')
        DataOut.VarAttribute=[{[]} DataOut.VarAttribute];
    end
    DataOut.VarDimName=[{'Time'} DataOut.VarDimName];
    DataOut.Action=Param.Action;%name of the processing programme
    test_time=diff(DataOut.Time)>0;% test that the readed time is increasing (not constant)
    if ~test_time
        DataOut.Time=[1:filecounter];
    end
    
    % display nbmissing
    if ~isequal(nbmissing,0)
        msgbox_uvmat('WARNING',[num2str(nbmissing) ' files skipped: missing files or bad input, see command window display'])
    end
    
    %name of result file
%     filemean=fullfile_uvmat(RootPath{1},subdir_result,RootFile{1},'.nc','_1',i1_series{1}(i_slice));
    OutputFile=fullfile_uvmat(RootPath{1},Param.OutputSubDir,RootFile{1},FileExtOut,NomTypeOut,i1_series{1}(1),i1_series{1}(end),i_slice,[]);
    errormsg=struct2nc(OutputFile,DataOut); %save result file
    if isempty(errormsg)
        display([OutputFile ' written'])
    else
        msgbox_uvmat('ERROR',['error in Series/struct2nc: ' errormsg])
    end
end

%% plot the time series (the last one in case of multislices)
figure
haxes=axes;
plot_field(DataOut,haxes)

%% display the result file using the GUI get_field
hget_field=findobj(allchild(0),'name','get_field');
if ~isempty(hget_field)
    delete(hget_field)
end
get_field(OutputFile,DataOut)
    


