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

%=======================================================================
% Copyright 2008-2020, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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
      %check the input files
    ParamOut.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default=1)
    first_j=[];
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('WARNING',['the first input file ' FirstFileName ' does not exist'])
    elseif isequal(size(Param.InputTable,1),1) && ~isfield(Param,'ProjObject')
        msgbox_uvmat('WARNING','You may need a projection object of type plane for merge_proj')
    end
    return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
ParamOut=[]; %default output
RUNHandle=[];
WaitbarHandle=[];
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
else
    hseries=findobj(allchild(0),'Tag','series');
    RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
    WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
end

%% define the directory for result file (with path=RootPath{1})
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files

if ~isfield(Param,'InputFields')
    Param.InputFields.FieldName='';
end

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
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:NbView
    if ~exist(filecell{iview,1}','file')
        disp_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'],checkrun)
        return
    end
    [FileInfo{iview},MovieObject{iview}]=get_file_info(filecell{iview,1});
    FileType{iview}=FileInfo{iview}.FileType;
    if strcmp(FileType{iview},'civdata')&&  ~isfield(Param.InputFields,'VelType')
        FileType{iview}='netcdf';
    end
    CheckImage{iview}=strcmp(FileInfo{iview}.FieldType,'image');% =1 for images
    if CheckImage{iview}
        ParamIn{iview}=MovieObject{iview};
    else
        ParamIn{iview}=Param.InputFields;
    end
    CheckNc{iview}=~isempty(find(strcmp(FileType{iview},NcTypeOptions)));% =1 for netcdf files
    if ~isempty(j1_series{iview})
        frame_index{iview}=j1_series{iview};
    else
        frame_index{iview}=i1_series{iview};
    end
end
if NbView >1 && max(cell2mat(CheckImage))>0 && ~isfield(Param,'ProjObject')
    disp_uvmat('ERROR','projection on a common grid is needed to concatene images: use a Projection Object of type ''plane'' with ProjMode=''interp_lin''',checkrun)
    return
end

%% calibration data and timing: read the ImaDoc files
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
if size(time,1)>1
    diff_time=max(max(diff(time)));
    if diff_time>0 
        disp_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time) ': the mean time is chosen in result'],checkrun)
    end   
end
if ~isempty(errormsg)
    disp_uvmat('WARNING',errormsg,checkrun)
end
time=mean(time,1); %averaged time taken for the merged field

%% coordinate transform or other user defined transform
transform_fct='';%default fct handle
if isfield(Param,'FieldTransform')&&~isempty(Param.FieldTransform.TransformName)
    currentdir=pwd;
    cd(Param.FieldTransform.TransformPath)
    transform_fct=str2func(Param.FieldTransform.TransformName);
    cd (currentdir)
    if isfield(Param,'TransformInput')
        for iview=1:NbView
            XmlData{iview}.TransformInput=Param.TransformInput;
        end
    end       
end
%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE

%% check the validity of  input file types
for iview=1:NbView
    if ~isequal(CheckImage{iview},1)&&~isequal(CheckNc{iview},1)
        disp_uvmat('ERROR','input set of input series: need  either netcdf either image series',checkrun)
        return
    end
end

%% output file type
if min(cell2mat(CheckImage))==1 && (~Param.CheckObject || strcmp(Param.ProjObject.Type,'plane'))
    FileExtOut='.png'; %image output (input and proj result = image)
else
    FileExtOut='.nc'; %netcdf output
end
if isempty(j1_series{1})
    NomTypeOut='_1';
else
    NomTypeOut='_1_1';
end
%NomTypeOut=NomType;% output file index will indicate the first and last ref index in the series
RootFileOut=RootFile{1};
for iview=2:NbView
    if ~strcmp(RootFile{iview},RootFile{1})
        RootFileOut='mproj';
        break
    end
end

%% mask (TODO: case of multilevels)
MaskData=cell(NbView,1);
if Param.CheckMask
    if ischar(Param.MaskTable)% case of a single mask (char chain)
        Param.MaskTable={Param.MaskTable};
    end
    for iview=1:numel(Param.MaskTable)
        if exist(Param.MaskTable{iview},'file')
            [MaskData{iview},tild,errormsg] = read_field(Param.MaskTable{iview},'image');
            if ~isempty(transform_fct) && nargin(transform_fct)>=2
                MaskData{iview}=transform_fct(MaskData{iview},XmlData{iview});
            end
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
tstart=tic; %used to record the computing time
CheckOverwrite=1;%default
if isfield(Param,'CheckOverwrite')
    CheckOverwrite=Param.CheckOverwrite;
end
for index=1:NbField
        update_waitbar(WaitbarHandle,index/NbField)
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    
     %% generating the name of the merged field
    i1=i1_series{1}(index);
    if ~isempty(i2_series{end})
        i2=i2_series{end}(index);
    else
        i2=i1;
    end
    j1=1;
    j2=1;
    if ~isempty(j1_series{1})
        j1=j1_series{1}(index);
        if ~isempty(j2_series{end})
            j2=j2_series{end}(index);
        else
            j2=j1;
        end
    end
    OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFileOut,FileExtOut,NomTypeOut,i1,i2,j1,j2);
    if ~CheckOverwrite && exist(OutputFile,'file')
            disp(['existing output file ' OutputFile ' already exists, skip to next field'])
            continue% skip iteration if the mode overwrite is desactivated and the result file already exists
    end
        
    %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
    Data=cell(1,NbView);%initiate the set Data
    timeread=zeros(1,NbView);
    for iview=1:NbView
        %% reading input file(s)      
        [Data{iview},tild,errormsg] = read_field(filecell{iview,index},FileType{iview},ParamIn{iview},frame_index{iview}(index));
        if isempty(errormsg)
            disp([filecell{iview,index} ' read'])
        else
            disp_uvmat('ERROR',['ERROR in merge_proj/read_field/' errormsg],checkrun)
            return
        end
        
        ListVar=Data{iview}.ListVarName;
        for ilist=1:numel(ListVar)
            Data{iview}.(ListVar{ilist})=double(Data{iview}.(ListVar{ilist}));% transform all fields in double before all operations
        end
        % get the time defined in the current file if not already defined from the xml file
        if isempty(time) && isfield(Data{iview},'Time')
            timeread(iview)=Data{iview}.Time;
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

        check_proj_tps= strcmp(FileType{iview},'civdata') && isfield(Param,'ProjObject')&&~isempty(Param.ProjObject)...
            && strcmp(Param.ProjObject.ProjMode,'interp_tps')&&~isfield(Data{iview},'Coord_tps');
        if check_proj_tps
        Data{iview}=tps_coeff_field(Data{iview},check_proj_tps);
        end
        
        %% projection on object (gridded plane)
        if Param.CheckObject
            [Data{iview},errormsg]=proj_field(Data{iview},Param.ProjObject);
            if ~isempty(errormsg)
                disp_uvmat('ERROR',['ERROR in merge_proge/proj_field: ' errormsg],checkrun)
                return
            end
        end
        
        %% mask
        if Param.CheckMask && ~isempty(MaskData{iview})
             [Data{iview},errormsg]=mask_proj(Data{iview},MaskData{iview});
        end
    end
    %%%%%%%%%%%%%%%% END LOOP ON VIEWS %%%%%%%%%%%%%%%%

    %% merge the NbView fields
    [MergeData,errormsg]=merge_field(Data);
    if ~isempty(errormsg)
        disp_uvmat('ERROR',errormsg,checkrun);
        return
    end

    %% time of the merged field: take the average of the different views
    if ~isempty(time)
        timeread=time(index);   
    elseif ~isempty(find(timeread))% time defined from ImaDoc
        timeread=mean(timeread(timeread~=0));% take average over times form the files (when defined)
    else
        timeread=index;% take time=file index 
    end

  
    %% recording the merged field
    if strcmp(FileExtOut,'.png')    %output as image
        if index==1
            if strcmp(class(MergeData.A),'uint8')
            BitDepth=8;
            else
              BitDepth=16;  
            end
            %write xml calibration file, using the first file
            siz=size(MergeData.A);
            npy=siz(1);
            npx=siz(2);
            if isfield(MergeData,'Coord_x') && isfield(MergeData,'Coord_y')
                Rangx=MergeData.Coord_x;
                Rangy=MergeData.Coord_y;
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
            GeometryCal.CalibrationType='rescale';
            GeometryCal.CoordUnit=MergeData.CoordUnit;
            GeometryCal.focal=1;
            GeometryCal.R=[pxcmx,0,0;0,pxcmy,0;0,0,1];
            GeometryCal.Tx_Ty_Tz=[T_x T_y 1];
            ImaDoc.GeometryCalib=GeometryCal;
            t=struct2xml(ImaDoc);
            t=set(t,1,'name','ImaDoc');
            save(t,[fileparts(OutputFile) '.xml'])
        end
        if BitDepth==8
            imwrite(uint8(MergeData.A),OutputFile,'BitDepth',8)
        else
            imwrite(uint16(MergeData.A),OutputFile,'BitDepth',16)
        end
    else   %output as netcdf files
        MergeData.ListGlobalAttribute={'Conventions','Project','InputFile_1','InputFile_end','NbCoord','NbDim'};
        MergeData.Conventions='uvmat';
        MergeData.NbCoord=2;
        MergeData.NbDim=2;
        % time interval of PIV
        Dt=[];
        if isfield(Data{1},'Dt')&& isnumeric(Data{1}.Dt)
            Dt=Data{1}.Dt;
        end
        for iview =2:numel(Data)
            if ~(isfield(Data{iview},'Dt')&& isequal(Data{iview}.Dt,Dt))
                Dt=[];%dt not the same for all fields
            end
        end
        if ~isempty(timeread)
            MergeData.ListGlobalAttribute=[MergeData.ListGlobalAttribute {'Time'}];
            MergeData.Time=timeread;
        end
        % position of projection plane 
        if isfield(Data{1},'ProjObjectCoord')&& isfield(Data{1},'ProjObjectAngle')
            ProjObjectCoord=Data{1}.ProjObjectCoord;
            ProjObjectAngle=Data{1}.ProjObjectAngle;
            for iview =2:numel(Data)
                if ~(isfield(Data{iview},'ProjObjectCoord')&& isequal(Data{iview}.ProjObjectCoord,ProjObjectCoord))...
                        ||~(isfield(Data{iview},'ProjObjectAngle')&& isequal(Data{iview}.ProjObjectAngle,ProjObjectAngle))
                    ProjObjectCoord=[];%dt not the same for all fields
                end
            end
            if ~isempty(ProjObjectCoord)
                MergeData.ListGlobalAttribute=[MergeData.ListGlobalAttribute {'ProjObjectCoord'} {'ProjObjectAngle'}];
                MergeData.ProjObjectCoord=ProjObjectCoord;
                MergeData.ProjObjectAngle=ProjObjectAngle;
            end
        end
        % coord unit
        if isfield(Data{1},'CoordUnit')
            CoordUnit=Data{1}.CoordUnit;
            for iview =2:numel(Data)
                if ~(isfield(Data{iview},'CoordUnit')&& isequal(Data{iview}.CoordUnit,CoordUnit))
                    CoordUnit=[];%CoordUnit not the same for all fields
                end
            end
            if ~isempty(CoordUnit)
                MergeData.ListGlobalAttribute=[MergeData.ListGlobalAttribute {'CoordUnit'}];
                MergeData.CoordUnit=CoordUnit;
            end
        end
        % time unit
        if isfield(Data{1},'TimeUnit')
            TimeUnit=Data{1}.TimeUnit;
            for iview =2:numel(Data)
                if ~(isfield(Data{iview},'TimeUnit')&& isequal(Data{iview}.TimeUnit,TimeUnit))
                    TimeUnit=[];%TimeUnit not the same for all fields
                end
            end
            if ~isempty(TimeUnit)
                MergeData.ListGlobalAttribute=[MergeData.ListGlobalAttribute {'TimeUnit'}];
                MergeData.TimeUnit=TimeUnit;
            end
        end
        error=struct2nc(OutputFile,MergeData);%save result file
        if isempty(error)
            disp(['output file ' OutputFile ' written'])
        else
            disp(error)
        end
    end
end
ellapsed_time=toc(tstart);
disp(['total ellapsed time ' num2str(ellapsed_time/60,2) ' minutes'])
disp([ num2str(ellapsed_time/(60*NbField),3) ' minutes per iteration'])

%'merge_field': concatene fields
%------------------------------------------------------------------------
function [MergeData,errormsg]=merge_field(Data)
%% default output
if isempty(Data)||~iscell(Data)
    MergeData=[];
    return
end
errormsg='';
MergeData=Data{1};% merged field= first field by default, reproduces the global attributes of the first field
NbView=length(Data);
if NbView==1% if there is only one field, just reproduce it in MergeData
    return 
end

%% group the variables (fields of 'Data') in cells of variables with the same dimensions
[CellInfo,NbDim,errormsg]=find_field_cells(Data{1});
if ~isempty(errormsg)
    return
end

%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
for icell=1:length(CellInfo)
    if NbDim(icell)~=1 % skip field cells which are of dim 1
        switch CellInfo{icell}.CoordType
            case 'scattered'  %case of input fields with unstructured coordinates: just concatene data
                for ivar=CellInfo{icell}.VarIndex %  indices of the selected variables in the list FieldData.ListVarName
                    VarName=Data{1}.ListVarName{ivar};
                    for iview=2:NbView
                        MergeData.(VarName)=[MergeData.(VarName); Data{iview}.(VarName)];
                    end
                end
            case 'grid'        %case of fields defined on a structured  grid
                FFName='';
                if isfield(CellInfo{icell},'VarIndex_errorflag') && ~isempty(CellInfo{icell}.VarIndex_errorflag)
                    FFName=Data{1}.ListVarName{CellInfo{icell}.VarIndex_errorflag};% name of errorflag variable
                    MergeData.ListVarName(CellInfo{icell}.VarIndex_errorflag)=[];%remove error flag variable in MergeData (will use NaN instead)
                    MergeData.VarDimName(CellInfo{icell}.VarIndex_errorflag)=[];
                    MergeData.VarAttribute(CellInfo{icell}.VarIndex_errorflag)=[];
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
                        Data{iview}.(VarName)(check_bad)=0; %set to zero NaN or data marked by error flag
                        if iview==1
                            %MergeData.(VarName)=Data{1}.(VarName);% initiate MergeData with the first field
                            MergeData.(VarName)(check_bad)=0; %set to zero NaN or data marked by error flag
                            NbAver=~check_bad;% initiate NbAver: the nbre of good data for each point
                        elseif size(Data{iview}.(VarName))~=size(MergeData.(VarName))
                            errormsg='sizes of the input matrices do not agree, need to interpolate on a common grid using a projection object';
                            return
                        else                             
                            MergeData.(VarName)=MergeData.(VarName) +double(Data{iview}.(VarName));%add data
                            NbAver=NbAver + ~check_bad;% add 1 for good data, 0 else
                        end
                    end
                    MergeData.(VarName)(NbAver~=0)=MergeData.(VarName)(NbAver~=0)./NbAver(NbAver~=0);% take average of defined data at each point
                    MergeData.(VarName)(NbAver==0)=NaN;% set to NaN the points with no good data
                end
        end
    end
end


    
