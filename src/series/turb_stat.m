%'aver_stat': calculate Reynolds steress components over time series
%------------------------------------------------------------------------
% function ParamOut=turb_stat(Param)
%
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

function ParamOut=turb_stat(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.staturb';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
%     filecell=get_file_series(Param);%check existence of the first input file
%     if ~exist(filecell{1,1},'file')
%         msgbox_uvmat('WARNING','the first input file does not exist')
%     end
    return
end

%%%%%%%%%%%%  STANDARD PART  %%%%%%%%%%%%
ParamOut=[];%default output
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
OutputDir=[Param.OutputSubDir Param.OutputDirExt];
    
%% root input file(s) name, type and index series
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
%%%%%%%%%%%% NbView=1 : a single input series
NbView=numel(i1_series);%number of input file series (lines in InputTable)
NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%% determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video'};
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:NbView
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
XmlData=[];
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


%% settings for the output file
NomTypeOut=nomtype2pair(NomType{1});% determine the index nomenclature type for the output file
first_i=i1_series{1}(1);
last_i=i1_series{1}(end);
if isempty(j1_series{1})% if there is no second index j
    first_j=1;last_j=1;
else
    first_j=j1_series{1}(1);
    last_j=j1_series{1}(end);
end

%% Set field names and velocity types
InputFields{1}=[];%default (case of images)
if isfield(Param,'InputFields')
    InputFields{1}=Param.InputFields;
end

nbfiles=0;
nbmissing=0;

%initialisation
DataOut.ListGlobalAttribute= {'Conventions'};
DataOut.Conventions= 'uvmat';
DataOut.ListVarName={'coord_y', 'coord_x' ,'UMean' , 'VMean','u2Mean','v2Mean','u2Mean_1','v2Mean_1','uvMean','Counter'};
DataOut.VarDimName={'coord_y','coord_x',{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},...
    {'coord_y','coord_x'},{'coord_y','coord_x'}};
DataOut.UMean=0;
DataOut.VMean=0;
DataOut.u2Mean=0;
DataOut.v2Mean=0;
DataOut.u2Mean_1=0;
DataOut.v2Mean_1=0;
DataOut.uvMean=0;
DataOut.Counter=0;
U2Mean=0;
V2Mean=0;
UVMean=0;
U2Mean_1=0;
V2Mean_1=0;
checkgrid=0;% test for a structured grid for input field
%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
for index=1:NbField
    update_waitbar(WaitbarHandle,index/NbField)
    if ~isempty(RUNHandle)&& ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break
    end
    [Field,tild,errormsg] = read_field(filecell{1,index},FileType{iview},InputFields{iview},frame_index{iview}(index));

    %%%%%%%%%%%% MAIN RUNNING OPERATIONS  %%%%%%%%%%%%
    if index==1 %first field
        
        DataOut.coord_y=Field.coord_y;
        DataOut.coord_x=Field.coord_x;
        Uprev=Field.U;
        Vprev=Field.V;
    end
    FF=isnan(Field.U)|Field.U<-60|Field.U>30;% threshold on U
    DataOut.Counter=DataOut.Counter+ (~FF);% add 1 to the couter for non NaN point
    Field.U(FF)=0;% set to 0 the nan values
    Field.V(FF)=0;
    DataOut.UMean=DataOut.UMean+Field.U; %increment the sum
    DataOut.VMean=DataOut.VMean+Field.V; %increment the sum
    U2Mean=U2Mean+(Field.U).*(Field.U); %increment the U squared sum
    V2Mean=V2Mean+(Field.V).*(Field.V); %increment the V squared sum
    UVMean=UVMean+(Field.U).*(Field.V); %increment the sum
    U2Mean_1=U2Mean_1+(Field.U).*Uprev; %increment the U squared sum
    V2Mean_1=V2Mean_1+(Field.V).*Vprev; %increment the V squared sum
    Uprev=Field.U; %store for next iteration
    Vprev=Field.V;
end
%%%%%%%%%%%%%%%% end loop on field indices %%%%%%%%%%%%%%%%

DataOut.Counter(DataOut.Counter==0)=1;% put counter to 1 when it is zero
DataOut.UMean=DataOut.UMean./DataOut.Counter; % normalize the mean
DataOut.VMean=DataOut.VMean./DataOut.Counter; % normalize the mean
U2Mean=U2Mean./DataOut.Counter; % normalize the mean
V2Mean=V2Mean./DataOut.Counter; % normalize the mean
UVMean=UVMean./DataOut.Counter; % normalize the mean
U2Mean_1=U2Mean_1./DataOut.Counter; % normalize the mean
V2Mean_1=V2Mean_1./DataOut.Counter; % normalize the mean
DataOut.u2Mean=U2Mean-DataOut.UMean.*DataOut.UMean; % normalize the mean
DataOut.v2Mean=V2Mean-DataOut.VMean.*DataOut.VMean; % normalize the mean
DataOut.uvMean=UVMean-DataOut.UMean.*DataOut.VMean; % normalize the mean \
DataOut.u2Mean_1=U2Mean_1-DataOut.UMean.*DataOut.UMean; % normalize the mean
DataOut.v2Mean_1=V2Mean_1-DataOut.VMean.*DataOut.VMean; % normalize the mean


%% calculate the profiles
% npx=numel(DataOut.coord_x);
% band=ceil(npx/5) :floor(4*npx/5);% keep only the central band
% for ivar=3:numel(DataOut.ListVarName)-1
%     VarName=DataOut.ListVarName{ivar};% name of the variable
%     DataOut.ListVarName=[DataOut.ListVarName {[VarName 'Profile']}];%append the name of the profile variable
%     DataOut.VarDimName=[DataOut.VarDimName {'coord_y'}];
%    DataOut.([VarName 'Profile'])=mean(DataOut.(VarName)(:,band),2); %take the mean profile of U, excluding the edges
% end

%% writing the result file as netcdf file
OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},FileExtOut,NomTypeOut,first_i,last_i,first_j,last_j);
 %case of netcdf input file , determine global attributes
 errormsg=struct2nc(OutputFile,DataOut); %save result file
 if isempty(errormsg)
     disp([OutputFile ' written']);
 else
     disp(['error in writting result file: ' errormsg])
 end


%% open the result file with uvmat (in RUN mode)
if checkrun
    uvmat(OutputFile)% open the last result file with uvmat
end
