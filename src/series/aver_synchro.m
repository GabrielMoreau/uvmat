%'aver_stat': calculate field average over a time series
%------------------------------------------------------------------------
% function ParamOut=aver_stat(Param)
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

function ParamOut=aver_synchro(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on'; %nbre of slices ('off' by default)
    ParamOut.VelType='two';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='two';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.ProjObject='on';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.synchro';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    %     filecell=get_file_series(Param);%check existence of the first input file
    %     if ~exist(filecell{1,1},'file')
    %         msgbox_uvmat('WARNING','the first input file does not exist')
    %     end
    def={'26'};
    if isfield (Param,'ActionInput')&& isfield(Param.ActionInput,'WavePeriod')
        def=Param.ActionInput.WavePeriod;
        
        def={num2str(def)};
    end
    prompt={'wave period'};
    dlgTitle='primary period';
    lineNo=1;
    answer=inputdlg(prompt,dlgTitle,lineNo,def);
    ParamOut.ActionInput.WavePeriod=str2num(answer{1});
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
 [FileType,FileInfo]=get_file_type(filecell{1,1});
%%%%%%%%%%%%
% The cell array filecell is the list of input file names, while
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%%
nbview=numel(i1_series);%number of input file series (lines in InputTable)
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields

%% determine the input file type 
% if ~strcmp(FileType{1},'netcdf')
%     displ_uvmat('ERROR','netcdf file series with field projected on a regular mesh must be put as input')
%     return
% end

%% calibration data and timing: read the ImaDoc files
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
% if size(time,1)>1
%     diff_time=max(max(diff(time)));
%     if diff_time>0
%         msgbox_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time)])
%     end   
% end

%% coordinate transform or other user defined transform
transform_fct='';%default
if isfield(Param,'FieldTransform')&&~isempty(Param.FieldTransform.TransformName)
    addpath(Param.FieldTransform.TransformPath)
    transform_fct=str2func(Param.FieldTransform.TransformName);
    rmpath(Param.FieldTransform.TransformPath)
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

% for i_slice=1:NbSlice
% index_slice=i_slice:NbSlice:nbfield;% select file indices of the slice
nbfiles=0;
nbmissing=0;
MeanU=0;
MeanV=0;
MinU=0;
MaxU=0;
MinV=0;
MaxV=0;
vec_X=0;
vec_Y=0;
vec_U=0; %initiate the sum 
vec_V=0;
cos1_U=0;
cos1_V=0;
sin1_U=0;
sin1_V=0;
cos2_U=0;
cos2_V=0;
sin2_U=0;
sin2_V=0;
cos3_U=0;
cos3_V=0;
sin3_U=0;
sin3_V=0;
cossub_U=0;
cossub_V=0;
sinsub_U=0;
sigma1=2*pi/Param.ActionInput.WavePeriod;%primary wave frequency
sigma2=4*pi/Param.ActionInput.WavePeriod;%harmonic 2
sigma3=6*pi/Param.ActionInput.WavePeriod;%harmonic 3
sigma_sub=pi/Param.ActionInput.WavePeriod;%subharmonic
sinsub_V=0;
vec_C=0;
 
%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
for index=1:nbfield
    update_waitbar(WaitbarHandle,index/nbfield)
    if ~isempty(RUNHandle)&& ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break
    end
    
    % reading input file(s)
    [Data,tild,errormsg] = read_field(filecell{1,index},FileType,InputFields{1});
    if ~isempty(errormsg)
        displ_uvmat('ERROR',['error of input reading: ' errormsg],checkrun);
        break
    end
    if ~isempty(NbSlice_calib)
        Data.ZIndex=mod(i1_series{1}(index)-1,NbSlice_calib{1})+1;%Zindex for phys transform
    end
    %update average
    MeanU=MeanU+Data.U;
    MeanV=MeanV+Data.V;
    MaxU=(MaxU>=Data.U).*MaxU+(MaxU<Data.U).*Data.U;
    MinU=(MinU<=Data.U).*MinU+(MinU>Data.U).*Data.U;
    MaxV=(MaxV>=Data.V).*MaxV+(MaxV<Data.V).*Data.V;
    MinV=(MinV<=Data.V).*MinV+(MinV>Data.V).*Data.V;
    cos1_U=cos1_U+Data.U*cos(Data.Time*sigma1);
    cos1_V=cos1_V+Data.V*cos(Data.Time*sigma1);
    sin1_U=sin1_U+Data.U*sin(Data.Time*sigma1);
    sin1_V=sin1_V+Data.V*sin(Data.Time*sigma1);
    cos2_U=cos2_U+Data.U*cos(Data.Time*sigma2);
    cos2_V=cos2_V+Data.V*cos(Data.Time*sigma2);
    sin2_U=sin2_U+Data.U*sin(Data.Time*sigma2);
    sin2_V=sin2_V+Data.V*sin(Data.Time*sigma2);
    cos3_U=cos3_U+Data.U*cos(Data.Time*sigma3);
    cos3_V=cos3_V+Data.V*cos(Data.Time*sigma3);
    sin3_U=sin3_U+Data.U*sin(Data.Time*sigma3);
    sin3_V=sin3_V+Data.V*sin(Data.Time*sigma3);
    cossub_U=cossub_U+Data.U*cos(Data.Time*sigma_sub);
    cossub_V=cossub_V+Data.V*cos(Data.Time*sigma_sub);
    sinsub_U=sinsub_U+Data.U*sin(Data.Time*sigma_sub);
    sinsub_V=sinsub_V+Data.V*sin(Data.Time*sigma_sub);
    
    
end

%%%%%%%%%%%%%%%%%%%%%%%%
Data.ListVarName={'X','Y','MeanU','MeanV','cos1_U','cos1_V','a1_U','a1_V','a2_U','a2_V','a3_U','a3_V','asub_U','asub_V',...
    'phase1_U','phase1_V','phase2_U','phase2_V','phase3_U','phase3_V'};
%Data.ListVarName=[{'coord_y','coord_x'} Data.ListVarName];
%Data.VarDimName={'coord_y', 'coord_x'};
for ilist=1:numel(Data.ListVarName)
    %Data.VarDimName{ilist+2}={'coord_y','coord_x'};
    Data.VarDimName{ilist}='nb_vectors';
end
Data.MeanU=MeanU/nbfield;
Data.MeanV=MeanV/nbfield;
Data.cos1_U=cos1_U/nbfield;
Data.cos1_V=cos1_V/nbfield;
sin1_U=sin1_U/nbfield;
sin1_V=sin1_V/nbfield;
cos2_U=cos2_U/nbfield;
cos2_V=cos2_V/nbfield;
sin2_U=sin2_U/nbfield;
sin2_V=sin2_V/nbfield;
cos3_U=cos3_U/nbfield;
cos3_V=cos3_V/nbfield;
sin3_U=sin3_U/nbfield;
sin3_V=sin3_V/nbfield;
cossub_U=cossub_U/nbfield;
cossub_V=cossub_V/nbfield;
sinsub_U=sinsub_U/nbfield;
sinsub_V=sinsub_V/nbfield;
Data.a1_U=sqrt(2)*sqrt(Data.cos1_U.*Data.cos1_U+sin1_U.*sin1_U);
Data.a1_V=-sqrt(2)*sqrt(Data.cos1_V.*Data.cos1_V+sin1_V.*sin1_V);
Data.a2_U=sqrt(2)*sqrt(cos2_U.*cos2_U+sin2_U.*sin2_U);
Data.a2_V=-sqrt(2)*sqrt(cos2_V.*cos2_V+sin2_V.*sin2_V);
Data.a3_U=sqrt(2)*sqrt(cos3_U.*cos3_U+sin3_U.*sin3_U);
Data.a3_V=-sqrt(2)*sqrt(cos3_V.*cos3_V+sin3_V.*sin3_V);
Data.asub_U=sqrt(2)*sqrt(cossub_U.*cossub_U+sinsub_U.*sinsub_U);
Data.asub_V=-sqrt(2)*sqrt(cossub_V.*cossub_V+sinsub_V.*sinsub_V);
clear i
Data.phase1_U=(angle(cos1_U+i*sin1_U));
Data.phase1_V=angle(cos1_V+i*sin1_V);
Data.phase2_U=(angle(cos2_U+i*sin2_U));
Data.phase2_V=(angle(cos2_V+i*sin2_V));
Data.phase3_U=(angle(cos3_U+i*sin3_U));
Data.phase3_V=(angle(cos3_V+i*sin3_V));
Data.phasesub_U=(angle(cossub_U+i*sinsub_U));
Data.phasesub_V=(angle(cossub_V+i*sinsub_V));

%% write the results
OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},'.nc','',1);
errormsg=struct2nc(OutputFile,Data)% write the output file

%% open the result file with uvmat (in RUN mode)
% if checkrun
%     uvmat(OutputFile)% open the last result file with uvmat
% end
'#### THE END ####'