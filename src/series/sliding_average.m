%'turb_correlation_time': calculate the time correlation function at each point
%------------------------------------------------------------------------
% function ParamOut=turb_correlation_time(Param)
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
%             900
%    .IndexRange: set the file or frame indices on which the action must be performseriesed
%    .FieldTransform: .TransformName: name of the select39ed transform function
%                     .TransformPath:   path  of the selected transform function
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%             uvmat .Coord_y: name of y coordinate variable
%              .Coord_x: name of x coordinate variable
%    .ProjObject: %sub structure describing a projection object (read from ancillary GUI set_object)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
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

function ParamOut=sliding_average(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to mseriesax (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice=1; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object39(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.tfilter';%set the output dir extension
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
ImageTypeOptions={'image','multimage','mmreader','video','cine_phantom'};
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:NbView
    if ~exist(filecell{iview,1}','file')
        msgbox_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'])
        return
    end
    [FileInfo{iview},MovieObject{iview}]=get_file_info(filecell{iview,1});
    FileType{iview}=FileInfo{iview}.FileType;
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
InputFields{1}=[];%default (case of images)series
if isfield(Param,'InputFields')
    InputFields{1}=Param.InputFields;
end

nbfiles=0;
nbmissing=0;

%% initialisation
T=24.4; %main wave period
t0=3; % time for motion start (torus at its maximum x)
NbPeriod=2; %number of periods for the sliding average
omega=2*pi/T;
amplitude=2.5; %oscillation amplitude
Lscale=15;%diameter of the torus, length scale for normalisation
Uscale=amplitude*omega;

DataOut.ListGlobalAttribute= {'Conventions','Time'};
DataOut.Conventions='uvmat';
DataOut.ListVarName={'coord_y','coord_x','Umean','Vmean','Ucos','Vcos','Usin','Vsin','DUDXsin','DUDXcos','DUDYsin','DVDXsin','DVDXcos'...
    ,'DVDYsin','Ustokes','Vstokes'};
DataOut.VarDimName={'coord_y','coord_x',{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},...
    {'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},...
    {'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'}};

%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
% First get time %
[Data,tild,errormsg]=nc2struct(filecell{1,1});    
Time_1=Data.Time;
if ~isempty(errormsg)
    disp_uvmat('ERROR',errormsg,checkrun)
    return
end
[Data,tild,errormsg]=nc2struct(filecell{1,end});    
Time_end=Data.Time;
dt=(Time_end-Time_1)/(NbField-1); %time interval 
NpTime=round(NbPeriod*T/dt+1);

OutputPath=fullfile(Param.OutputPath,Param.Experiment,Param.Device);
RootFileOut=RootFile{1};
NomTypeOut='_1';
%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
disp('loop for filtering started')
for index=1:NbField
    update_waitbar(WaitbarHandle,index/NbField)
    if ~isempty(RUNHandle)&& ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break
    end
    [Field,tild,errormsg] = read_field(filecell{1,index},FileType{iview},InputFields{iview},frame_index{iview}(index));
    
    %%%%%%%%%%% MAIN RUNNING OPERATIONS  %%%%%%%%%%%%
    if index==1 %first field
        DataOut.coord_x=Field.coord_x/Lscale;
        DataOut.coord_y=Field.coord_y/Lscale;
        npy=numel(DataOut.coord_y);
        npx=numel(DataOut.coord_x);
        Umean=zeros(NpTime,npy,npx);
        Vmean=zeros(NpTime,npy,npx);
        Ucos=zeros(NpTime,npy,npx);
        Vcos=zeros(NpTime,npy,npx);
        Usin=zeros(NpTime,npy,npx);
        Vsin=zeros(NpTime,npy,npx);
        DUDXcos=zeros(NpTime,npy,npx);
        DUDXsin=zeros(NpTime,npy,npx);
        DUDYsin=zeros(NpTime,npy,npx);
        DVDXcos=zeros(NpTime,npy,npx);
        DVDXsin=zeros(NpTime,npy,npx);
        DVDYsin=zeros(NpTime,npy,npx);
    end
    Time(index)=Field.Time-t0;%time from the start of the motion
    Umean=circshift(Umean,[-1 0 0]); %shift U by ishift along the first index
    Vmean=circshift(Vmean,[-1 0 0]); %shift U by ishift along the first index
    Ucos=circshift(Ucos,[-1 0 0]); %shift U by ishift along the first index
    Vcos=circshift(Vcos,[-1 0 0]); %shift U by ishift along the first index
    Usin=circshift(Usin,[-1 0 0]); %shift U by ishift along the first index
    Vsin=circshift(Vsin,[-1 0 0]); %shift U by ishift along the first index
    DUDXcos=circshift(DUDXcos,[-1 0 0]);
    DUDXsin=circshift(DUDXsin,[-1 0 0]);
    DUDYsin=circshift(DUDYsin,[-1 0 0]);        
    DVDXcos=circshift(DVDXcos,[-1 0 0]);
    DVDXsin=circshift(DVDXsin,[-1 0 0]);
    DVDYsin=circshift(DVDYsin,[-1 0 0]);       
    Umean(end,:,:)=Field.U;
    Vmean(end,:,:)=Field.V;
    Ucos(end,:,:)=Field.U*cos(omega*Time(index));
    Vcos(end,:,:)=Field.V*cos(omega*Time(index));
    Usin(end,:,:)=Field.U*sin(omega*Time(index));
    Vsin(end,:,:)=Field.V*sin(omega*Time(index));
    DUDXcos(end,:,:)=Field.DUDX*cos(omega*Time(index));
    DUDXsin(end,:,:)=Field.DUDX*sin(omega*Time(index));
    DUDYsin(end,:,:)=Field.DUDY*sin(omega*Time(index));% ParamOut=[];%default output

    DVDXcos(end,:,:)=Field.DVDX*cos(omega*Time(index));
    DVDXsin(end,:,:)=Field.DVDX*sin(omega*Time(index));
    DVDYsin(end,:,:)=Field.DVDY*sin(omega*Time(index));
    DataOut.Time=(Time(index)-(NpTime-1)*dt/2)/T;%time inperiods from the beginning of the oscillation (torus at max abscissa)
    DataOut.Umean=(1/Uscale)*squeeze(nanmean(Umean,1));
    DataOut.Vmean=(1/Uscale)*squeeze(nanmean(Vmean,1));
    DataOut.Ucos=2*(1/Uscale)*squeeze(nanmean(Ucos,1));
    DataOut.Vcos=2*(1/Uscale)*squeeze(nanmean(Vcos,1));
    DataOut.Usin=2*(1/Uscale)*squeeze(nanmean(Usin,1));
    DataOut.Vsin=2*(1/Uscale)*squeeze(nanmean(Vsin,1));
    DataOut.DUDXcos=2*squeeze(nanmean(DUDXcos,1));
    DataOut.DUDXsin=2*squeeze(nanmean(DUDXsin,1));
    DataOut.DUDYsin=2*squeeze(nanmean(DUDYsin,1));
    DataOut.DVDXcos=2*squeeze(nanmean(DVDXcos,1));
    DataOut.DVDXsin=2*squeeze(nanmean(DVDXsin,1));
    DataOut.DVDYsin=2*squeeze(nanmean(DVDYsin,1));
    DataOut.Ustokes=(1/omega)*(1/Uscale)*(DataOut.Ucos.*DataOut.DUDXsin+DataOut.Vcos.*DataOut.DUDYsin);
    DataOut.Vstokes=(1/omega)*(1/Uscale)*(DataOut.Ucos.*DataOut.DVDXsin+DataOut.Vcos.*DataOut.DVDYsin);

    % writing the result file as netcdf file
    i1=i1_series{1}(index);
    OutputFile=fullfile_uvmat(OutputPath,OutputDir,RootFileOut,'.nc',NomTypeOut,i1);
    errormsg=struct2nc(OutputFile, DataOut);
    if isempty(errormsg)
        disp([OutputFile ' written'])
    else
        disp(errormsg)
    end
end
    