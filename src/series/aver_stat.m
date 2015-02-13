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
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function ParamOut=aver_stat(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)% function activated from the GUI series but not RUN
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on'; %nbre of slices ('off' by default)
    ParamOut.VelType='two';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='two';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.ProjObject='on';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.stat';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    % check the existence of the first file in the series
    first_j=[];
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    last_j=[];
    if isfield(Param.IndexRange,'last_j'); last_j=Param.IndexRange.last_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('WARNING',['the first input file ' FirstFileName ' does not exist'])
    else
        [i1,i2,j1,j2] = get_file_index(Param.IndexRange.last_i,last_j,PairString);
        LastFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
        if ~exist(FirstFileName,'file')
             msgbox_uvmat('WARNING',['the last input file ' LastFileName ' does not exist'])
        end
    end
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
hdisp=disp_uvmat('WAITING...','checking the file series',checkrun);
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
if ~isempty(hdisp),delete(hdisp),end;
%%%%%%%%%%%%
% The cell array filecell is the list of input file names, while
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%%
NbView=numel(i1_series);%number of input file series (lines in InputTable)
NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%% determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video'};
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:NbView
    if ~exist(filecell{iview,1}','file')
        disp_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'],checkrun)
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
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
if size(time,1)>1
    diff_time=max(max(diff(time)));
    if diff_time>0
        disp_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time)],checkrun)
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
    disp_uvmat('ERROR',['invalid file type input ' FileType{1}],checkrun)
    return
end
if NbView==2 && ~isequal(CheckImage{1},CheckImage{2})
    disp_uvmat('ERROR','input must be two image series or two netcdf file series',checkrun)
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
if NbView==2
    InputFields{2}=[];%default (case of images)
end
if isfield(Param,'InputFields')
    InputFields{1}=Param.InputFields;
    if NbView==2
        InputFields{2}=Param.InputFields;%default
        if isfield(Param.InputFields,'FieldName_1')
            InputFields{2}.FieldName=Param.InputFields.FieldName_1;
            if isfield(Param.InputFields,'VelType_1')
                InputFields{2}.VelType=Param.InputFields.VelType_1;
            end
        end
    end
end
% for i_slice=1:NbSlice
% index_slice=i_slice:NbSlice:nbfield;% select file indices of the slice
nbfiles=0;
% nbmissing=0;

%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
for index=1:NbField
    update_waitbar(WaitbarHandle,index/NbField)
    if ~isempty(RUNHandle)&& ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break
    end
    
    %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
    for iview=1:NbView
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
        if isfield(Param,'ProjObject')&&isfield(Param.ProjObject,'ProjMode')&& strcmp(Param.ProjObject.ProjMode,'interp_tps')
            Field=tps_coeff_field(Field,check_proj_tps);
        end
        
        %field projection on an object
        if Param.CheckObject
            [Field,errormsg]=proj_field(Field,Param.ProjObject);
            if ~isempty(errormsg)
                disp_uvmat('ERROR',['error in aver_stat/proj_field:' errormsg],checkrun)
                return
            end
        end
        nbfiles=nbfiles+1;
        
        %%%%%%%%%%%% MAIN RUNNING OPERATIONS  %%%%%%%%%%%%
        if nbfiles==1 %first field
            time_1=[];
            if isfield(Field,'Time')
                time_1=Field.Time(1);
            end
            DataOut=Field;%default
            DataOut.Conventions='uvmat'; %suppress Conventions='uvmat/civdata' for civ input files
            errorvar=zeros(numel(Field.ListVarName));%index of errorflag associated to each variable
            for ivar=1:numel(Field.ListVarName)
                VarName=Field.ListVarName{ivar};
                DataOut.(VarName)=zeros(size(DataOut.(VarName)));% initiate each field to zero
                NbData.(VarName)=zeros(size(DataOut.(VarName)));% initiate the nbre of good data to zero
                for iivar=1:length(Field.VarAttribute)
                    if isequal(Field.VarDimName{iivar},Field.VarDimName{ivar})&& isfield(Field.VarAttribute{iivar},'Role')...
                            && strcmp(Field.VarAttribute{iivar}.Role,'errorflag')
                        errorvar(ivar)=iivar; % index of the errorflag variable corresponding to ivar
                    end
                end
            end
            DataOut.ListVarName(errorvar(errorvar~=0))=[]; %remove errorflag from result
            DataOut.VarDimName(errorvar(errorvar~=0))=[]; %remove errorflag from result
            DataOut.VarAttribute(errorvar(errorvar~=0))=[]; %remove errorflag from result
        end   %current field
        for ivar=1:length(DataOut.ListVarName)
            VarName=Field.ListVarName{ivar};
            sizmean=size(DataOut.(VarName));
            siz=size(Field.(VarName));
            if ~isequal(DataOut.(VarName),0)&& ~isequal(siz,sizmean)
                disp_uvmat('ERROR',['unequal size of input field ' VarName ', need to project  on a grid'],checkrun)
                return
            else
                if errorvar(ivar)==0
                    check_bad=isnan(Field.(VarName));%=0 for NaN data values, 1 else
                else
                    check_bad=isnan(Field.(VarName)) | Field.(Field.ListVarName{errorvar(ivar)})~=0;%=0 for NaN or error flagged data values, 1 else
                end
                Field.(VarName)(check_bad)=0; %set to zero NaN or data marked by error flag
                DataOut.(VarName)=DataOut.(VarName)+ double(Field.(VarName)); % update the sum
                NbData.(VarName)=NbData.(VarName)+ ~check_bad;% records the number of data for each point
            end
        end
        %%%%%%%%%%%%   END MAIN RUNNING OPERATIONS  %%%%%%%%%%%%
    else
        disp(errormsg)
    end
end
%%%%%%%%%%%%%%%% end loop on field indices %%%%%%%%%%%%%%%%

for ivar=1:length(Field.ListVarName)
    VarName=Field.ListVarName{ivar};
    DataOut.(VarName)=DataOut.(VarName)./NbData.(VarName); % normalize the mean
end
nbmissing=NbField-nbfiles;
if nbmissing~=0
    disp_uvmat('WARNING',[num2str(nbmissing) ' input files are missing or skipted'],checkrun)
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
    DataOut.Time=time(1);
    DataOut.Time_end=time(end);
end

%% writing the result file
OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},FileExtOut,NomTypeOut,first_i,last_i,first_j,last_j);
if CheckImage{1} %case of images
    if isequal(FileInfo{1}.BitDepth,16)||(numel(FileInfo)==2 &&isequal(FileInfo{2}.BitDepth,16))
        DataOut.A=uint16(DataOut.A);
        imwrite(DataOut.A,OutputFile,'BitDepth',16); % case of 16 bit images
    else
        DataOut.A=uint8(DataOut.A);
        imwrite(DataOut.A,OutputFile,'BitDepth',8); % case of 16 bit images
    end
    disp([OutputFile ' written']);
else %case of netcdf input file , determine global attributes
    errormsg=struct2nc(OutputFile,DataOut); %save result file
    if isempty(errormsg)
        disp([OutputFile ' written']);
    else
        disp(['error in writting result file: ' errormsg])
    end
end  % end averaging  loop

%% open the result file with uvmat (in RUN mode)
if checkrun
    uvmat(OutputFile)% open the last result file with uvmat
end
