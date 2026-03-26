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

%=======================================================================
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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
    ParamOut.OutputDirExt='.synchro_multi';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    %     filecell=get_file_series(Param);%check existence of the first input file
    %     if ~exist(filecell{1,1},'file')
    %         msgbox_uvmat('WARNING','the first input file does not exist')
    %     end
    def={''};
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
FileInfo=get_file_info(filecell{1,1});
 FileType=FileInfo.FileType;
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
            currentdir=pwd;
    cd(Param.FieldTransform.TransformPath)
    transform_fct=str2func(Param.FieldTransform.TransformName);
    cd (currentdir)
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

main_period=Param.ActionInput.WavePeriod;
main_frequency=2*pi/main_period;
frequency=(0:main_frequency/16:3*main_frequency)';
nbfrequency=numel(frequency);
%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
for index=1:nbfield
    index
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
    %initiate average
    if index==1
        nby=numel(Data.coord_y);
        nbx=numel(Data.coord_x);
        cos_U=zeros(nbfrequency,numel(Data.coord_y),numel(Data.coord_x));
        sin_U=zeros(nbfrequency,numel(Data.coord_y),numel(Data.coord_x));
        cos_V=zeros(nbfrequency,numel(Data.coord_y),numel(Data.coord_x));
        sin_V=zeros(nbfrequency,numel(Data.coord_y),numel(Data.coord_x));
        NbField=zeros(nbfrequency,numel(Data.coord_y),numel(Data.coord_x));
    end
    %update average
    FF=isnan(Data.U)|isnan(Data.V);% check NaN values
    Data.U(FF)=0;% set to zero the NaN values
    Data.V(FF)=0;
    for ifreq=1:nbfrequency
        NbField(ifreq,:,:)=NbField(ifreq,:,:)+reshape(~FF,1,nby,nbx);%count the NaN values
        cos_U(ifreq,:,:)=cos_U(ifreq,:,:)+reshape(Data.U,1,nby,nbx)*cos(Data.Time*frequency(ifreq));
        sin_U(ifreq,:,:)=sin_U(ifreq,:,:)+reshape(Data.U,1,nby,nbx)*sin(Data.Time*frequency(ifreq));
        cos_V(ifreq,:,:)=cos_V(ifreq,:,:)+reshape(Data.V,1,nby,nbx)*cos(Data.Time*frequency(ifreq));
        sin_V(ifreq,:,:)=sin_V(ifreq,:,:)+reshape(Data.V,1,nby,nbx)*sin(Data.Time*frequency(ifreq));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%
Data.ListVarName={'coord_x','coord_y','frequency','cos_U','cos_V','sin_U','sin_V','a_U','a_V','phase_U','phase_V'};
%Data.ListVarName=[{'coord_y','coord_x'} Data.ListVarName];
Data.VarDimName={'coord_x', 'coord_y','frequency'};
for ilist=1:numel(Data.ListVarName)-3
    Data.VarDimName{ilist+3}={'frequency','coord_y','coord_x'};
end
Data.frequency=frequency;
Data.cos_U=cos_U./NbField;
Data.sin_U=sin_U./NbField;
Data.cos_V=cos_V./NbField;
Data.sin_V=sin_V./NbField;
Data.a_U=sqrt(2)*sqrt(Data.cos_U.*Data.cos_U+Data.sin_U.*Data.sin_U);
Data.a_V=sqrt(2)*sqrt(Data.cos_V.*Data.cos_V+Data.sin_V.*Data.sin_V);
Data.phase_U=angle(Data.cos_U+1i*Data.sin_U);
Data.phase_V=angle(Data.cos_V+1i*Data.sin_V);


%% write the results
OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},'.nc','',1);
errormsg=struct2nc(OutputFile,Data);% write the output file
if isempty(errormsg)
    disp_uvmat('CONFIRMATION',[OutputFile ' successfully written'],checkrun)
else
    disp_uvmat('ERROR',errormsg,checkrun)
end
    

%% open the result file with uvmat (in RUN mode)
% if checkrun
%     uvmat(OutputFile)% open the last result file with uvmat
% end
'#### THE END ####'
