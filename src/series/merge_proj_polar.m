%'merge_proj': concatene several fields from series, project on a polar grid
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
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function ParamOut=merge_proj_polar(Param)

%% set the input elements needed on the GUI series when the function is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='on';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on'; %nbre of slices ('off' by default)
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.polar';%set the output dir extension
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
    end
    return
end

%%%% specific input parameters
% calculate the positions on which to interpolate
radius_ref=450;% radius of the mountain top
radius_shifted=-130:2:130;% radius shifted by the radius of the origin at the topography summit
radius=radius_ref+radius_shifted;%radius from centre of the tank
azimuth_arclength=(-150:2:400);%azimuth in arc length at origin position
azimuth=pi/2-azimuth_arclength/radius_ref;%azimuth in radian
[Radius,Azimuth]=meshgrid(radius,azimuth);
XI=Radius.*cos(Azimuth);% set of x axis of the points where interpolqtion needs to be done
YI=Radius.*sin(Azimuth)-radius_ref;% set of y axis of the points where interpolqtion needs to be done
FieldNames={'vec(U,V)';'curl(U,V)';'div(U,V)'};
HeadData.ListVarName= {'radius','azimuth'} ;
HeadData.VarDimName={'radius','azimuth'};
HeadData.VarAttribute{1}.Role='coord_y';
HeadData.VarAttribute{2}.Role='coord_x';
HeadData.radius=radius_shifted;
HeadData.azimuth=azimuth_arclength;    
thresh2=16; % square of the interpolation range

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

%% root input file type
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
%NomType=Param.InputTable(:,4);
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
% NbSlice=1;%default
% if isfield(Param.IndexRange,'NbSlice')&&~isempty(Param.IndexRange.NbSlice)
%     NbSlice=Param.IndexRange.NbSlice;
% end
NbView=numel(i1_series);%number of input file series (lines in InputTable)
NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%% define the name for result file (with path=RootPath{1})
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files
% OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},'.nc','_1',i1_series{1}(1));
% CheckOverwrite=1;%default
% if isfield(Param,'CheckOverwrite')
%     CheckOverwrite=Param.CheckOverwrite;
% end
% if ~CheckOverwrite && exist(OutputFile,'file')
%     disp(['existing output file ' OutputFile ' already exists, skip to next field'])
%     return% skip iteration if the mode overwrite is desactivated and the result file already exists
% end

if ~isfield(Param,'InputFields')
    Param.InputFields.FieldName='';
end


%% determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video','cine_phantom'};
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:NbView
    if ~exist(filecell{iview,1}','file')
        disp_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'],checkrun)
        return
    end
    [FileInfo{iview},MovieObject{iview}]=get_file_info(filecell{iview,1});
    FileType{iview}=FileInfo{iview}.FileType;
    CheckImage{iview}=~isempty(find(strcmp(FileType{iview},ImageTypeOptions)));% =1 for images
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

%% height z
    % position of projection plane
    
ProjObjectCoord=XmlData{1}.GeometryCalib.SliceCoord;
CoordUnit=XmlData{1}.GeometryCalib.CoordUnit;
for iview =2:numel(XmlData)
    if ~(isfield(XmlData{iview},'GeometryCalib')&& isequal(XmlData{iview}.GeometryCalib.SliceCoord,ProjObjectCoord))...
        disp('error: geometric calibration missing or inconsistent plane positions')
        return
    end
end


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
    if ~isequal(CheckNc{iview},1)
        disp_uvmat('ERROR','input files needs to be in netcdf (extension .nc)',checkrun)
        return
    end
end

% %% output file type
if isempty(j1_series{1})
    NomTypeOut='_1';
else
    NomTypeOut='_1_1';
end
RootFileOut=RootFile{1};
for iview=2:NbView
    if ~strcmp(RootFile{iview},RootFile{1})
        RootFileOut='mproj';
        break
    end
end


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
    disp(['index=' num2str(index)])
    disp(['ellapsed time ' num2str(toc(tstart)/60,4) ' minutes'])
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
       OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFileOut,'.nc',NomTypeOut,i1,i2,j1,j2);
        if ~CheckOverwrite && exist(OutputFile,'file')
            disp(['existing output file ' OutputFile ' already exists, skip to next field'])
            continue% skip iteration if the mode overwrite is desactivated and the result file already exists
        end
    
    %% z position
    ZIndex=mod(i1_series{1}(index)-1,NbSlice_calib{1})+1;%Zindex for phys transform
    ZPosNew=ProjObjectCoord(ZIndex,3);
    if index==1
        ZPos=ZPosNew;
    else
        if ZPosNew~=ZPos
            disp('inconsistent z positions in the series')
            return
        end
    end
    % radius of the topography section at z position
    ind_mask=[];
    if ZPos<20
        TopoRadius=40*sin(acos((20+ZPos)/40));
        ind_mask=(XI'.*XI'+YI'.*YI')<TopoRadius*TopoRadius;% indidces of data to mask
    end
    
    %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
    Data=cell(1,NbView);%initiate the set Data
    timeread=zeros(1,NbView);
    for iview=1:NbView
        %% reading input file(s)
        [Data{iview},tild,errormsg] = read_field(filecell{iview,index},FileType{iview},ParamIn{iview},frame_index{iview}(index));
        if ~isempty(errormsg)
            disp_uvmat('ERROR',['ERROR in merge_proj/read_field/' errormsg],checkrun)
            return
        end
        ListVar=Data{iview}.ListVarName;
        for ilist=1:numel(ListVar)
            Data{iview}.(ListVar{ilist})=double(Data{iview}.(ListVar{ilist}));% transform all fields in double before all operations
        end
        % get the time defined in the current file if not already defined from the xml file
        if ~isempty(time) && isfield(Data{iview},'Time')
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
        
        %% calculate tps coefficients
        Data{iview}=tps_coeff_field(Data{iview},1);
        
        %% projection on the polar grid
        [DataOut,VarAttribute,errormsg]=calc_field_tps(Data{iview}.Coord_tps,Data{iview}.NbCentre,Data{iview}.SubRange,...
            cat(3,Data{iview}.U_tps,Data{iview}.V_tps),FieldNames,cat(3,XI,YI));
        % set to NaN interpolation points which are too far from any initial data (more than 2 CoordMesh)
        Coord=permute(Data{iview}.Coord_tps,[1 3 2]);
        Coord=reshape(Coord,size(Coord,1)*size(Coord,2),2);
        if exist('scatteredInterpolant','file')%recent Matlab versions
            F=scatteredInterpolant(Coord,Coord(:,1),'nearest');
            G=scatteredInterpolant(Coord,Coord(:,2),'nearest');
        else
            F=TriScatteredInterp(Coord,Coord(:,1),'nearest');
            G=TriScatteredInterp(Coord,Coord(:,2),'nearest');
        end
        Distx=F(XI,YI)-XI;% diff of x coordinates with the nearest measurement point
        Disty=G(XI,YI)-YI;% diff of y coordinates with the nearest measurement point
        Dist=Distx.*Distx+Disty.*Disty;
        ListVarName=(fieldnames(DataOut))';
        VarDimName=cell(size(ListVarName));
        ProjData{iview}=HeadData;
        ProjData{iview}.ListVarName= [ProjData{iview}.ListVarName ListVarName];
        ProjData{iview}.VarDimName={'radius','azimuth'};
%         ProjData{iview}.VarAttribute{1}.Role='coord_y';
%         ProjData{iview}.VarAttribute{2}.Role='coord_x';
        ProjData{iview}.VarAttribute=[ProjData{iview}.VarAttribute VarAttribute];
        for ivar=1:numel(ListVarName)
            ProjData{iview}.VarDimName{ivar+2}={'radius','azimuth'};
            VarName=ListVarName{ivar};
            if ~isempty(thresh2)
                DataOut.(VarName)(Dist>thresh2)=NaN;% put to NaN interpolated positions further than RangeInterp from initial data
            end
            ProjData{iview}.(VarName)=(DataOut.(VarName))';
        end
        
    end
    %%%%%%%%%%%%%%%% END LOOP ON VIEWS %%%%%%%%%%%%%%%%
    
    %% merge the NbView fields
    [MergeData,errormsg]=merge_field(ProjData);
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
    
    %% rotating the velocity vectors to the local axis of the polatr coordinates
    Unew=MergeData.U.*sin(Azimuth')-MergeData.V.*cos(Azimuth');
    Vnew=MergeData.U.*cos(Azimuth')+MergeData.V.*sin(Azimuth');
    if ~isempty(ind_mask)
        Unew(ind_mask)=NaN;
        Vnew(ind_mask)=NaN;
        MergeData.curl(ind_mask)=NaN;
        MergeData.div(ind_mask)=NaN;
    end
    [npy,npx]=size(Unew);
    
    %% create the output file for the first iteration of the loop
    if index==1
        TimeData.ListGlobalAttribute={'Conventions','Project','CoordUnit','TimeUnit','ZPos','Time'};
        TimeData.Conventions='uvmat';
        TimeData.Project='2016_Circumpolar';
        TimeData.CoordUnit='cm';
        TimeData.TimeUnit='s';
        TimeData.ZPos=ZPos;
        TimeData.ListVarName={'radius','azimuth','U','V','curl','div'};
        TimeData.VarDimName={'radius','azimuth',{'radius','azimuth'},{'radius','azimuth'}...
            {'radius','azimuth'},{'radius','azimuth'}};
        TimeData.VarAttribute{1}.Role='';
        TimeData.VarAttribute{2}.Role='';
        TimeData.VarAttribute{3}.Role='vector_x';
        TimeData.VarAttribute{4}.Role='vector_y';
        TimeData.VarAttribute{5}.Role='scalar';
        TimeData.VarAttribute{6}.Role='scalar';
        
        TimeData.radius=radius_shifted;
        TimeData.azimuth=azimuth_arclength;
    end
        
        %% append data to the netcdf file for next iterations
        TimeData.Time=timeread;
       TimeData.U=Unew;
       TimeData.V=Vnew;
       TimeData.curl=MergeData.curl;
       TimeData.div=MergeData.div;

            [error,ncid]=struct2nc(OutputFile,TimeData);%save result file
        if isempty(error)
            disp(['output file ' OutputFile ' written'])
        else
            disp(error)
        end
            ellapsed_time=toc(tstart);
    disp(['total ellapsed time ' num2str(ellapsed_time/60,2) ' minutes'])
end

ellapsed_time=toc(tstart);
disp(['total ellapsed time ' num2str(ellapsed_time/60,2) ' minutes'])
disp([ num2str(ellapsed_time/(60*NbField),3) ' minutes per iteration'])

% %'merge_field': concatene fields
% %------------------------------------------------------------------------
% function [MergeData,errormsg]=merge_field(Data)
% %% default output
% if isempty(Data)||~iscell(Data)
%     MergeData=[];
%     return
% end
% errormsg='';
% MergeData=Data{1};% merged field= first field by default, reproduces the global attributes of the first field
% NbView=length(Data);
% if NbView==1% if there is only one field, just reproduce it in MergeData
%     return
% end
% 
% %% group the variables (fields of 'Data') in cells of variables with the same dimensions
% [CellInfo,NbDim,errormsg]=find_field_cells(Data{1});
% if ~isempty(errormsg)
%     return
% end
% 
% %LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
% for icell=1:length(CellInfo)
%     if NbDim(icell)~=1 % skip field cells which are of dim 1
%         switch CellInfo{icell}.CoordType
%             case 'scattered'  %case of input fields with unstructured coordinates: just concatene data
%                 for ivar=CellInfo{icell}.VarIndex %  indices of the selected variables in the list FieldData.ListVarName
%                     VarName=Data{1}.ListVarName{ivar};
%                     for iview=2:NbView
%                         MergeData.(VarName)=[MergeData.(VarName); Data{iview}.(VarName)];
%                     end
%                 end
%             case 'grid'        %case of fields defined on a structured  grid
%                 FFName='';
%                 if isfield(CellInfo{icell},'VarIndex_errorflag') && ~isempty(CellInfo{icell}.VarIndex_errorflag)
%                     FFName=Data{1}.ListVarName{CellInfo{icell}.VarIndex_errorflag};% name of errorflag variable
%                     MergeData.ListVarName(CellInfo{icell}.VarIndex_errorflag)=[];%remove error flag variable in MergeData (will use NaN instead)
%                     MergeData.VarDimName(CellInfo{icell}.VarIndex_errorflag)=[];
%                     MergeData.VarAttribute(CellInfo{icell}.VarIndex_errorflag)=[];
%                 end
%                 % select good data on each view
%                 for ivar=CellInfo{icell}.VarIndex  %  indices of the selected variables in the list FieldData.ListVarName
%                     VarName=Data{1}.ListVarName{ivar};
%                     for iview=1:NbView
%                         if isempty(FFName)
%                             check_bad=isnan(Data{iview}.(VarName));%=0 for NaN data values, 1 else
%                         else
%                             check_bad=isnan(Data{iview}.(VarName)) | Data{iview}.(FFName)~=0;%=0 for NaN or error flagged data values, 1 else
%                         end
%                         Data{iview}.(VarName)(check_bad)=0; %set to zero NaN or data marked by error flag
%                         if iview==1
%                             %MergeData.(VarName)=Data{1}.(VarName);% initiate MergeData with the first field
%                             MergeData.(VarName)(check_bad)=0; %set to zero NaN or data marked by error flag
%                             NbAver=~check_bad;% initiate NbAver: the nbre of good data for each point
%                         elseif size(Data{iview}.(VarName))~=size(MergeData.(VarName))
%                             errormsg='sizes of the input matrices do not agree, need to interpolate on a common grid using a projection object';
%                             return
%                         else
%                             MergeData.(VarName)=MergeData.(VarName) +double(Data{iview}.(VarName));%add data
%                             NbAver=NbAver + ~check_bad;% add 1 for good data, 0 else
%                         end
%                     end
%                     MergeData.(VarName)(NbAver~=0)=MergeData.(VarName)(NbAver~=0)./NbAver(NbAver~=0);% take average of defined data at each point
%                     MergeData.(VarName)(NbAver==0)=NaN;% set to NaN the points with no good data
%                 end
%         end
%    
%     end
% end


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
