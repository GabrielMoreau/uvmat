%'time_series': extract a time series after projection on an object (points , line..)
% this function can be used as a template for applying a global operation on a series of input fields
%------------------------------------------------------------------------
% function GUI_input=time_series(Param)
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
% Copyright 2008-2016, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function ParamOut=time_series(Param) 

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)% function activated from the GUI series but not RUN
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on'; %nbre of slices ('off' by default)
    ParamOut.VelType='two';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='two';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.ProjObject='on';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.tseries';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    % check for selection of a projection object
    hseries=findobj(allchild(0),'Tag','series');% handles of the GUI series
    hhseries=guidata(hseries);
    if  ~isfield(Param,'ProjObject')
        answer=msgbox_uvmat('INPUT_Y-N','use a projection object for the time_series?');
        if strcmp(answer,'Yes')
            set(hhseries.CheckObject,'Visible','on')
            set(hhseries.CheckObject,'Value',1)
            series('CheckObject_Callback',hseries,[],hhseries); %file input with xml reading  in uvmat, show the image in phys coordinates
        end
    end
    
    % introduce bin size for histograms
    if isfield(Param,'CheckObject') &&Param.CheckObject
        SeriesData=get(hseries,'UserData');
        if ismember(SeriesData.ProjObject.ProjMode,{'inside','outside'})
            answer=msgbox_uvmat('INPUT_TXT','set bin size for histograms (or keep ''auto'' by default)?','auto');
            ParamOut.ActionInput.VarMesh=str2num(answer);
        end
    end
    
    % test for subtraction
    if size(Param.InputTable,1)>2
        msgbox_uvmat('WARNING','''time_series'' uses only one or two input lines (two for substraction). To concatene fields first use ''merge_proj''');
    end
    if size(Param.InputTable,1)>=2
        answer=msgbox_uvmat('INPUT_Y-N','substract the two input file series?');
        if strcmp(answer,'Yes')
            if isempty(Param.FieldTransform.TransformName)
                set(hhseries.TransformName,'value',2) %select sub_field
            end
        else
            set(hhseries.InputTable,'Data',Param.InputTable(1,:))
        end
    end
    
    % check the existence of the first and last file in the series
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
        if ~exist(LastFileName,'file')
            msgbox_uvmat('WARNING',['the last input file ' LastFileName ' does not exist'])
        end
    end
    return
end

%%%%%%%%%%%% STANDARD PART  %%%%%%%%%%%%
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
OutputDir=[Param.OutputSubDir Param.OutputDirExt];

%% root input file(s) name, type and index series
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);

hdisp=disp_uvmat('WAITING...','checking the file series',checkrun);
% gives the series of input file names and indices set by the input parameters:
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index with i and j reshaped as a 1D array
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
if ~isempty(hdisp),delete(hdisp),end;%end the waiting display

NbView=numel(i1_series);%number of input file series (lines in InputTable)
NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%% determine the file type on each line from the first input file
ImageTypeOptions={'image','multimage','mmreader','video'};
NcTypeOptions={'netcdf','civx','civdata'};
FileType=cell(1,nbview);
FileInfo=cell(1,nbview);
MovieObject=cell(1,nbview);
CheckImage=cell(1,nbview);
CheckNc=cell(1,nbview);
frame_index=cell(1,nbview);

for iview=1:nbview
    if ~exist(filecell{iview,1}','file')
        disp_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'],checkrun)
        return
    end
    [FileInfo{iview},MovieObject{iview}]=get_file_info(filecell{iview,1});
    FileType{iview}=FileInfo{iview}.FileType;
    if strcmp(FileType{iview},'civdata')||strcmp(FileType{iview},'civx')
        if ~isfield(Param.InputFields,'VelType')
            FileType{iview}='netcdf';% civ data read as usual netcdf files
        end
    end
    CheckImage{iview}=~isempty(find(strcmp(FileType{iview},ImageTypeOptions)));% =1 for images
    CheckNc{iview}=~isempty(find(strcmp(FileType{iview},NcTypeOptions)));% =1 for netcdf files
    if isempty(j1_series{iview})
        frame_index{iview}=i1_series{iview};
    else
        frame_index{iview}=j1_series{iview};
    end
end

%% calibration data and timing: read the ImaDoc files
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
if ~isempty(errormsg)
    disp_uvmat('ERROR',['error in reading xmlfile: ' errormsg],checkrun)
    return
end
if size(time,1)>1
    diff_time=max(max(diff(time)));
    if diff_time>0
        disp_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time)],checkrun)
    end
    time=time(1,:);% choose the time data from the first sequence
end

%% coordinate transform or other user defined transform
transform_fct=[];%default
if isfield(Param,'FieldTransform')&&~isempty(Param.FieldTransform.TransformName)
    addpath(Param.FieldTransform.TransformPath)
    transform_fct=str2func(Param.FieldTransform.TransformName);
    rmpath(Param.FieldTransform.TransformPath)
    if isfield(Param,'TransformInput')
        XmlData{1}.TransformInput=Param.TransformInput;
    end
end

%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
% EDIT FROM HERE

%% check the validity of  the input file types
if ~CheckImage{1}&&~CheckNc{1}
    disp_uvmat('ERROR',['invalid file type input ' FileType{1}],checkrun)
    return
end
if nbview==2 && ~isequal(CheckImage{1},CheckImage{2})
    disp_uvmat('ERROR','input must be two image series or two netcdf file series',checkrun)
    return
end

%% settings for the output file
FileExtOut='.nc';% write result as .nc files for netcdf inputs
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
if nbview==2
    InputFields{2}=[];%default (case of images)
end
if isfield(Param,'InputFields')
    InputFields{1}=Param.InputFields;
    if nbview==2
        InputFields{2}=Param.InputFields;%default
        if isfield(Param.InputFields,'FieldName_1')
            InputFields{2}.FieldName=Param.InputFields.FieldName_1;
            if isfield(Param.InputFields,'VelType_1')
                InputFields{2}.VelType=Param.InputFields.VelType_1;
            end
        end
    end
end

%% Initiate output fields
%initiate the output structure as a copy of the first input one (reproduce fields)
[DataOut,tild,errormsg] = read_field(filecell{1,1},FileType{1},InputFields{1},1);
if ~isempty(errormsg)
    disp_uvmat('ERROR',['error reading ' filecell{1,1} ': ' errormsg],checkrun)
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

nbfile=0;% not used , to check
nbmissing=0;
VarMesh=[];
checkhisto=0;
if isfield(Param,'ProjObject') && ismember(Param.ProjObject.ProjMode,{'inside','outside'})
    checkhisto=1;
    if isfield(Param,'ActionInput') && isfield(Param.ActionInput,'VarMesh')%case of histograms
        VarMesh=Param.ActionInput.VarMesh;
    else
        VarMesh=[];
        disp_uvmat('WARNING','automatic bin size for histograms, select time_series again to set the value',checkrun)
    end
end

%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
for index=1:nbfield
    update_waitbar(WaitbarHandle,index/nbfield)
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break % leave the loop if stop is ordered
    end
    Data=cell(1,nbview);%initiate the set Data;
    nbtime=0;
    dt=[];
    %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
    for iview=1:nbview
        % reading input file(s)
        [Data{iview},tild,errormsg] = read_field(filecell{iview,index},FileType{iview},InputFields{iview},frame_index{iview}(index));
        if ~isempty(errormsg)
            errormsg=['time_series / read_field / ' errormsg];
            disp(errormsg)
            break% exit the loop on iview
        end
        if ~isempty(NbSlice_calib)
            Data{iview}.ZIndex=mod(i1_series{iview}(index)-1,NbSlice_calib{iview})+1;%Zindex for phys transform
        end
    end
    if ~isempty(errormsg)
        continue %in case of input error skip the current input field, go to next index
    end
    Field=Data{1}; % default input field structure
    % coordinate transform (or other user defined transform)
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
    
    %field projection on an object
    if Param.CheckObject
        % calculate tps coefficients if needed
        if isfield(Param.ProjObject,'ProjMode')&& strcmp(Param.ProjObject.ProjMode,'interp_tps')
            Field=tps_coeff_field(Field,check_proj_tps);
        end
        [Field,errormsg]=proj_field(Field,Param.ProjObject,VarMesh);
        if ~isempty(errormsg)
            disp_uvmat('ERROR',['time_series / proj_field / ' errormsg],checkrun)
            return
        end
    end
    %         nbfile=nbfile+1;
    
    % initiate the time series at the first iteration
    if index==1
        % stop program if the first field reading is in error
        if ~isempty(errormsg)
            disp_uvmat('ERROR',['time_series / sub_field / ' errormsg],checkrun)
            return
        end
        if ~isfield(Field,'ListVarName')
            disp_uvmat('ERROR','no variable in the projected field',checkrun)
            return
        end
        DataOut=Field;%output reproduced the first projected field by default
        nbvar=length(Field.ListVarName);
        if nbvar==0
            disp_uvmat('ERROR','no input variable selected',checkrun)
            return
        end
        if checkhisto%case of histograms
            testsum=zeros(1,nbvar);%initiate flag for action on each variable
            for ivar=1:numel(Field.ListVarName)% list of variable names before projection (histogram)
                VarName=Field.ListVarName{ivar};
                if isfield(Data{1},VarName)
                    DataOut.ListVarName=[DataOut.ListVarName {[VarName 'Histo']}];
                    DataOut.VarDimName=[DataOut.VarDimName {{'Time',VarName}}];
%                     if isfield(DataOut.VarAttribute{ivar},'Role')
%                     DataOut.VarAttribute{ivar}=rmfield(DataOut.VarAttribute{ivar},'Role');
%                     end
                    StatName=pdf2stat;% get the names of statistical quantities to calcuilate at each time
                    for istat=1:numel(StatName)
                        DataOut.ListVarName=[DataOut.ListVarName {[VarName StatName{istat}]}];
                        DataOut.VarDimName=[DataOut.VarDimName {'Time'}];
                    end
                    testsum(ivar)=1;
                    DataOut.(VarName)=Field.(VarName);
                    DataOut.([VarName 'Histo'])=zeros([nbfield numel(DataOut.(VarName))]);
                    VarMesh=Field.(VarName)(2)-Field.(VarName)(1);
                end
            end
            disp(['mesh for histogram = ' num2str(VarMesh)])
        else
            testsum=2*ones(1,nbvar);%initiate flag for action on each variable
            if isfield(Field,'VarAttribute') % look for coordinate and flag variables
                for ivar=1:nbvar
                    if length(Field.VarAttribute)>=ivar && isfield(Field.VarAttribute{ivar},'Role')
                        var_role=Field.VarAttribute{ivar}.Role;%'role' of the variable
                        if isequal(var_role,'errorflag')
                            disp_uvmat('ERROR','do not handle error flags in time series',checkrun)
                            return
                        end
                        if isequal(var_role,'warnflag')
                            testsum(ivar)=0;  % not recorded variable
                            eval(['DataOut=rmfield(DataOut,''' Field.ListVarName{ivar} ''');']);%remove variable
                        end
                        if strcmp(var_role,'coord_x')||strcmp(var_role,'coord_y')||strcmp(var_role,'coord_z')||strcmp(var_role,'coord')
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
                    VarName=Field.ListVarName{ivar};
                    siz=size(Field.(VarName));
                    DataOut.(VarName)=zeros([nbfield siz]);
                end
            end
        end
        DataOut.ListVarName=[{'Time'} DataOut.ListVarName];
    end
    % end initialisation for index==1
    
    % append data from the current field

    if checkhisto % case of histogram (projection mode=inside or outside)
        for ivar=1:length(Field.ListVarName)
            VarName=Field.ListVarName{ivar};
            if isfield(Data{1},VarName)
                MaxValue=max(DataOut.(VarName));% current max of histogram absissa
                MinValue=min(DataOut.(VarName));% current min of histogram absissa
                MaxIndex=round(MaxValue/VarMesh);
                MinIndex=round(MinValue/VarMesh);
                MaxIndex_new=round(max(Field.(VarName)/VarMesh));% max of the current field
                MinIndex_new=round(min(Field.(VarName)/VarMesh));
                if MaxIndex_new>MaxIndex% the variable max for the current field exceeds the previous one
                    DataOut.(VarName)=[DataOut.(VarName) VarMesh*(MaxIndex+1:MaxIndex_new)];% append the new variable values
                    DataOut.([VarName 'Histo'])=[DataOut.([VarName 'Histo']) zeros(nbfield,MaxIndex_new-MaxIndex)]; % append the new histo values
                end
                if MinIndex_new <= MinIndex-1
                    DataOut.(VarName)=[VarMesh*(MinIndex_new:MinIndex-1) DataOut.(VarName)];% insert the new variable values
                    DataOut.([VarName 'Histo'])=[zeros(nbfield,MinIndex-MinIndex_new) DataOut.([VarName 'Histo'])];% insert the new histo values
                    ind_start=1;
                else
                    ind_start=MinIndex_new-MinIndex+1;
                end
                DataOut.([VarName 'Histo'])(index,ind_start:ind_start+MaxIndex_new-MinIndex_new)=...
                    DataOut.([VarName 'Histo'])(index,ind_start:ind_start+MaxIndex_new-MinIndex_new)+Field.([VarName 'Histo']);
                VarVal=pdf2stat((Field.(VarName))',(Field.([VarName 'Histo']))');% max of the current field
                for istat=1:numel(VarVal)
                    DataOut.([VarName StatName{istat}])(index)=VarVal(istat);
                end
            end
        end
    else % not histogram
        for ivar=1:length(Field.ListVarName)
            VarName=Field.ListVarName{ivar};
            VarVal=Field.(VarName);
            if testsum(ivar)==2% test for recorded variable
                if isempty(errormsg)
                    VarVal=shiftdim(VarVal,-1); %shift dimension
                    DataOut.(VarName)(index,:,:)=VarVal;%concanete the current field to the time series
                end
            elseif testsum(ivar)==1% variable representing fixed coordinates
                VarInit=DataOut.(VarName);
                if isempty(errormsg) && ~isequal(VarVal,VarInit)
                    disp_uvmat('ERROR',['time series requires constant coordinates ' VarName ': use projection mode interp'],checkrun)
                    return
                end
            end
        end
    end
    
    % record the time:
    if isempty(time)% time not set by xml filer(s)
        if isfield(Data{1},'Time')
            DataOut.Time(index,1)=Field.Time;
        else
            DataOut.Time(index,1)=index;%default
        end
    else % time from ImaDoc prevails  TODO: correct
        DataOut.Time(index,1)=time(index);%
    end
    index
    % record the number of missing input fields
    if ~isempty(errormsg)
        nbmissing=nbmissing+1;
        display(['index=' num2str(index) ':' errormsg])
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
    DimCell=Field.VarDimName{ivar};
    if ischar(DimCell),DimCell={DimCell};end
    if testsum(ivar)==2% variable for which time series is calculated
        DataOut.VarDimName{ivar}=[{'Time'} DimCell];
    elseif testsum(ivar)==1 % variable represneting a fixed coordinate
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
    DataOut.Time=1:nbfield;
end

% %case of histograms
% if checkhisto
%     for ivar=1:numel(Field.ListVarName)
%         VarName=Field.ListVarName{ivar};
%         if isfield(Data{1},VarName)
%             DataOut.ListVarName=[DataOut.ListVarName {[VarName 'Histo']}];
%             DataOut.VarDimName=[DataOut.VarDimName {{'Time',VarName}}];
%         end
%     end
% end
% display nbmissing
if ~isequal(nbmissing,0)
    disp_uvmat('WARNING',[num2str(nbmissing) ' files skipped: missing files or bad input, see command window display'],checkrun)
end

%% name of result file
OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},FileExtOut,NomTypeOut,first_i,last_i,first_j,last_j);
errormsg=struct2nc(OutputFile,DataOut); %save result file
if isempty(errormsg)
    display([OutputFile ' written'])
else
    disp_uvmat('ERROR',['error in Series/struct2nc: ' errormsg],checkrun)
end

%% plot the time series for  (the last one in case of multislices)
if checkrun %&& isfield(Param,'ProjObject') && strcmp(Param.ProjObject.Type,'points')
    %% open the result file with uvmat (in RUN mode)
    uvmat(OutputFile)% open the last result file with uvmat
end
%     figure
%     haxes=axes;
%     plot_field(DataOut,haxes)
%     
%     %% display the result file using the GUI get_field
%     hget_field=findobj(allchild(0),'name','get_field');
%     if ~isempty(hget_field)
%         delete(hget_field)
%     end
%     get_field(OutputFile,DataOut)
% end


