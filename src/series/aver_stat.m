%'aver_stat': calculate field average over a time series
%------------------------------------------------------------------------
% function ParamOut=aver_stat(Param)
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
%    .OutputDirExt: directory extension for data outputs
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

function ParamOut=aver_stat(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if ~exist('Param','var') % case with no input parameter 
    ParamOut={'AllowInputSort';'off';...% allow alphabetic sorting of the list of input files (options 'off'/'on', 'off' by default)
        'WholeIndexRange';'off';...% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelType';'two';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
        'FieldName';'two';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'FieldTransform'; 'on';...%can use a transform function
        'ProjObject';'on';...%can use projection object(option 'off'/'on',
        'Mask';'off';...%can use mask option   (option 'off'/'on', 'off' by default)
        'OutputDirExt';'.stat';...%set the output dir extension
               ''};
        return
end

%%%%%%%%%%%%  STANDARD PART  %%%%%%%%%%%%
%% select different modes,  RUN, parameter input, BATCH
% BATCH  case: read the xml file for batch case
if ischar(Param)
        Param=xml2struct(Param);
        checkrun=0;
% RUN case: parameters introduced as the input structure Param
else
    if isfield(Param,'Specific')&& strcmp(Param.Specific,'?')
        checkrun=1;% will only search interactive input parameters (preparation of BATCH mode)
    else
        checkrun=2; % indicate the RUN option is used
    end
    hseries=guidata(Param.hseries);%handles of the GUI series
end
ParamOut=Param; %default output
OutputDir=[Param.OutputSubDir Param.OutputDirExt];
    
%% root input file(s) and type
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
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
if size(time,1)>1
    diff_time=max(max(diff(time)));
    if diff_time>0
        msgbox_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time)])
    end   
end

%% coordinate transform or other user defined transform
transform_fct='';%default
if isfield(Param,'FieldTransform')&&~isempty(Param.FieldTransform.TransformName)
    addpath(Param.FieldTransform.TransformPath)
    transform_fct=str2func(Param.FieldTransform.TransformName);
    rmpath(Param.FieldTransform.TransformPath)
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
if checkrun==1
    return % stop here for input checks
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

%% MAIN LOOP ON SLICES
for i_slice=1:NbSlice
    index_slice=i_slice:NbSlice:nbfield;% select file indices of the slice
    nbfiles=0;
    nbmissing=0;

    %%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
    for index=index_slice
        if checkrun
            update_waitbar(hseries.Waitbar,index/(nbfield))
            stopstate=get(hseries.RUN,'BusyAction');
        else
            stopstate='queue';
        end
        if isequal(stopstate,'queue')% enable STOP command
            
        %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
        for iview=1:nbview
            % reading input file(s)
            [Data{iview},tild,errormsg] = read_field(filecell{iview,index},FileType{iview},InputFields{iview},frame_index{iview}(index));
            if ~isempty(errormsg)
                errormsg=['error of input reading: ' errormsg];
                break
            end
            if ~isempty(NbSlice_calib)
                Data{iview}.ZIndex=mod(i1_series{iview}(index)-1,NbSlice_calib{iview})+1;%Zindex for phys transform
            end
        end
        else
            errormsg='stop';
        end
        %%%%%%%%%%%%%%%% end loop on views (input lines) %%%%%%%%%%%%%%%%
        %%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
        % EDIT FROM HERE
    
        if isempty(errormsg)
            Field=Data{1}; % default input field structure
            %% coordinate transform (or other user defined transform)
            if ~isempty(transform_fct)
                switch nargin(transform_fct)
                    case 4
                        if length(Data)==2
                            Field=transform_fct(Data{1},XmlData{1},Data{2},XmlData{2});
                        else
                            Field=transform_fct(Data{1},XmlData{1});
                        end
                    case 3
                        if length(Data)==2
                            Field=transform_fct(Data{1},XmlData{1},Data{2});
                        else
                            Field=transform_fct(Data{1},XmlData{1});
                        end
                    case 2
                        Field=transform_fct(Data{1},XmlData{1});
                    case 1
                        Field=transform_fct(Data{1});
                end
            end
            
            %% calculate tps coefficients if needed
            if isfield(Param.ProjObject,'ProjMode')&& strcmp(Param.ProjObject.ProjMode,'interp_tps')
                Field=tps_coeff_field(Field,check_proj_tps);
            end

            %field projection on an object
            if Param.CheckObject
                [Field,errormsg]=proj_field(Field,Param.ProjObject);
                if ~isempty(errormsg)
                    msgbox_uvmat('ERROR',['error in aver_stat/proj_field:' errormsg])
                    return
                end
            end
            nbfiles=nbfiles+1;
            
            %%%%%%%%%%%% MAIN RUNNING OPERATIONS  %%%%%%%%%%%%
            %update sum
            if nbfiles==1 %first field
                time_1=[];
                if isfield(Field,'Time')
                    time_1=Field.Time(1);
                end
                DataOut=Field;%default
                for ivar=1:length(Field.ListVarName)
                    VarName=Field.ListVarName{ivar};
                    DataOut.(VarName)=double(DataOut.(VarName));
                end
            else   %current field
                for ivar=1:length(Field.ListVarName)
                    VarName=Field.ListVarName{ivar};
                    sizmean=size(DataOut.(VarName));
                    siz=size(Field.(VarName));
                    if ~isequal(DataOut.(VarName),0)&& ~isequal(siz,sizmean)
                        msgbox_uvmat('ERROR',['unequal size of input field ' VarName ', need to project  on a grid'])
                        return
                    else
                        DataOut.(VarName)=DataOut.(VarName)+ double(Field.(VarName)); % update the sum
                    end
                end
            end
            %%%%%%%%%%%%   END MAIN RUNNING OPERATIONS  %%%%%%%%%%%%
        else
            display(errormsg)
        end
    end
    %%%%%%%%%%%%%%%% end loop on field indices %%%%%%%%%%%%%%%%
    
    for ivar=1:length(Field.ListVarName)
        VarName=Field.ListVarName{ivar};
        DataOut.(VarName)=DataOut.(VarName)/nbfiles; % normalize the mean
    end
    if nbmissing~=0
        msgbox_uvmat('WARNING',[num2str(nbmissing) ' input files are missing or skipted'])
    end
    if isempty(time) % time is read from files
        if isfield(Field,'Time')
            time_end=Field.Time(1);%last time read
            if ~isempty(time_1)
                DataOut.Time=time_1;
                DataOut.Time_end=time_end;
            end
        end
    else  % time from ImaDoc prevails if it exists
%         j1=1;%default
%         if ~isempty(j1_series{1})
%             j1=j1_series{1};
%         end
        %DataOut.Time=time(1,i1_series{1}(1),j1);
        %DataOut.Time_end=time(end,i1_series{end}(end),j1_series{end}(end));
        DataOut.Time=time(1);
        DataOut.Time_end=time(end);
    end
    
    %writting the result file
    OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},FileExtOut,NomTypeOut,i1_series{1}(1),i1_series{1}(end),i_slice,[]);
    if CheckImage{1} %case of images
        if isequal(FileInfo{1}.BitDepth,16)||(numel(FileInfo)==2 &&isequal(FileInfo{2}.BitDepth,16))
            DataOut.A=uint16(DataOut.A);
            imwrite(DataOut.A,OutputFile,'BitDepth',16); % case of 16 bit images
        else
            DataOut.A=uint8(DataOut.A);
            imwrite(DataOut.A,OutputFile,'BitDepth',8); % case of 16 bit images
        end
        display([OutputFile ' written']);
    else %case of netcdf input file , determine global attributes
        errormsg=struct2nc(OutputFile,DataOut); %save result file
        if isempty(errormsg)
            display([OutputFile ' written']);
        else
            msgbox_uvmat('ERROR',['error in writting result file: ' errormsg])
            display(errormsg)
        end
    end  % end averaging  loop
end
%%%%%%%%%%%%%%%% end loop on slices %%%%%%%%%%%%%%%%

%% open the result file with uvmat (in RUN mode)
if checkrun
%     hget_field=findobj(allchild(0),'name','get_field');%find the get_field... GUI
%     delete(hget_field)
    uvmat(OutputFile)% open the last result file with uvmat
end