%'merge_proj_volume': concatene several fields from series, project on volumes
%------------------------------------------------------------------------
% function ParamOut=merge_proj_volume(Param)
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
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function ParamOut=merge_proj_volume(Param)

%% set the input elements needed on the GUI series when the function is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='on';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.ProjObject='on';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.volume';%set the output dir extension
    ParamOut.OutputFileMode='NbInput_i';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
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
if ~(isfield(Param,'ProjObject') && strcmp(Param.ProjObject.Type,'volume')&& strcmp(Param.ProjObject.ProjMode,'interp_lin'))
 msgbox_uvmat('ERROR','a projection object of type volume with ProjMode interp_lin must be introduced')
 return
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
NbView=numel(i1_series);%number of input file series (lines in InputTable)
NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%% define the name for result file (with path=RootPath{1})
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files

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

%% check calibration data
for iview=1:NbView
    if isfield(XmlData{iview}.GeometryCalib,'CheckVolumeScan')  %old convention (<2022)
        CheckVolumeScan{iview}=XmlData{iview}.GeometryCalib.CheckVolumeScan;
        XmlData{iview}.Slice.SliceCoord=XmlData{iview}.GeometryCalib.SliceCoord;
        XmlData{iview}.Slice.SliceAngle=XmlData{iview}.GeometryCalib.SliceAngle;
    elseif isfield(XmlData{1},'Slice')&& isfield(XmlData{iview}.Slice,'CheckVolumeScan')  %new convention (>=2022)
        CheckVolumeScan{iview}=XmlData{iview}.Slice.CheckVolumeScan;
    else
        disp('no volume info in calibration data (xml file)')
        return
    end
    if CheckVolumeScan{iview}==0
         disp('input field sereis with volume scan (index j) is needed')
        return
    end
end

%% initiate output field
DataVol.ListGlobalAttribute={'Conventions','CoordUnit','Time'};
DataVol.Conventions='uvmat';
DataVol.CoordUnit=XmlData{1}.GeometryCalib.CoordUnit;
DataVol.Time=0; %TO UPDATE
DataVol.ListVarName={'coord_x','coord_y','coord_z','A'};
DataVol.VarDimName={'coord_x','coord_y','coord_z',{'coord_y','coord_x','coord_z'}};
DataVol.VarAttribute{1}.Role='coord_x';
DataVol.VarAttribute{2}.Role='coord_y';
DataVol.VarAttribute{3}.Role='coord_z';
DataVol.VarAttribute{4}.Role='scalar';
DataVol.coord_x=Param.ProjObject.RangeX(1):Param.ProjObject.DX:Param.ProjObject.RangeX(2);
DataVol.coord_y=Param.ProjObject.RangeY(1):Param.ProjObject.DY:Param.ProjObject.RangeY(2);
DataVol.coord_z=Param.ProjObject.RangeZ(1):Param.ProjObject.DZ:Param.ProjObject.RangeZ(2);
DataVol.A=zeros(numel(DataVol.coord_z),numel(DataVol.coord_y),numel(DataVol.coord_x));
%% coordinate transform or other user defined transform
% transform_fct='';%default fct handle
% if isfield(Param,'FieldTransform')&&~isempty(Param.FieldTransform.TransformName)
%         currentdir=pwd;
%         cd(Param.FieldTransform.TransformPath)
%         transform_fct=str2func(Param.FieldTransform.TransformName);
%         cd (currentdir)
%         if isfield(Param,'TransformInput')
%             for iview=1:NbView
%             XmlData{iview}.TransformInput=Param.TransformInput;
%             end
%         end
% end
%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
% EDIT FROM HERE

% %% output file type
if isempty(j1_series{1})
    disp('error: no index j for z position label')
    return
end
NomTypeOut='_1';

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


for index_i=1:NbField_i
    
    for index_j=1:NbField_j
        index_j
        %% generating the name of the merged field
        OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFileOut,'.nc',NomTypeOut,index_i);
        if ~CheckOverwrite && exist(OutputFile,'file')
            disp(['existing output file ' OutputFile ' already exists, skip to next field'])
            continue% skip iteration if the mode overwrite is desactivated and the result file already exists
        end

        %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
       
        timeread=zeros(1,NbView);
%         for iview=1:NbView
            %% reading input file(s)
            [Data,tild,errormsg] = read_field(filecell{1,index_j},FileType{1},ParamIn{1},frame_index{1}(index_j));
            if ~isempty(errormsg)
                disp_uvmat('ERROR',['ERROR in merge_proj/read_field/' errormsg],checkrun)
                return
            end
            Data.A=Data.A(1:4:end,1:4:end);% reduce the mage size
            ListVar=Data.ListVarName;
            %reduce the image size
            for ilist=1:numel(ListVar)
                Data.(ListVar{ilist})=double(Data.(ListVar{ilist}));% transform all fields in double before all operations
            end
            % get the time defined in the current file if not already defined from the xml file
            if ~isempty(time) && isfield(Data,'Time')
                timeread(iview)=Data.Time;
            end
            Data.ZIndex=index_j;
            [X,Y,Z]=meshgrid(DataVol.coord_x,DataVol.coord_y,DataVol.coord_z);%grid in physical coordinates
            %Data{iview}=proj_plane(Data{iview},XmlData{iview},X,Y); %project on the common x,y plane

        if index_j==1
            AMerge=zeros(size(Data.A,1),size(Data.A,2),NbField_j);
        end
        AMerge(:,:,index_j)=Data.A;

        %%%%%%%%%%%%%%%% END LOOP FOR VOLUME SCAN %%%%%%%%%%%%%%%%
    end
    %interpolate on the vertical grid
    DataVol.A=proj_volume(AMerge,XmlData{1},X,Y,Z);
%     Z=zeros(1,NbField_j);
%     for j_index=1:numel(DataVol.coord_y)
%         for i_index=1:numel(DataVol.coord_x)
%             for ZIndex=1:NbField_j
%             Z(ZIndex)=Zpos(XmlData{iview},ZIndex,X(j_index,i_index),Y(j_index,i_index));
%             end
%             DataVol.A(:,j_index,i_index) = interp1(Z,AMerge(:,j_index,i_index),DataVol.coord_z);
%         end
%     end
    error=struct2nc(OutputFile,DataVol)%save result file

end

% disp([ num2str(ellapsed_time/(60*NbField),3) ' minutes per iteration'])

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

% get the X position corresponding to X,Y for a given plane (labelled by ZIndex)

function Z=Zpos(XmlData,ZIndex,X,Y)% Z positions correspoonding to X,Y positions
Z=XmlData.Slice.SliceCoord(ZIndex,3)*ones(size(X));
if isfield(XmlData.Slice,'SliceAngle')&&~isequal(XmlData.Slice.SliceAngle,[0 0 0])
    [norm_plane(1), norm_plane(2), norm_plane(3)] =rotate_vector(XmlData.SliceAngle(ZIndex,:)*pi/180,0,0,1);
    Z=Z-(norm_plane(1)*(X-XmlData.Slice.SliceCoord(ZIndex,1))+norm_plane(2)*(Y-XmlData.Slice.SliceCoord(ZIndex,2)))/norm_plane(3);
end


function ZIndex=XYZtoIndex(XmlData,X,Y,Z)% Z positions corresponding to X,Y positions
Zp=Z-XmlData.Slice.SliceCoord(1,3);
DZ=XmlData.Slice.SliceCoord(end,3)-XmlData.Slice.SliceCoord(1,3)/(size(XmlData.Slice.SliceCoord,1)-1);
if DZ~=0
ZIndex=(Z-XmlData.Slice.SliceCoord(1,3))/DZ+1;% Z=XmlData.SliceCoord(1,3)+(ZIndex-1)*DZ
end
% effect of angular deviation
SliceAngleMax=XmlData.Slice.SliceAngle(end,:)-XmlData.Slice.SliceAngle(1,:);
normAxe=norm(SliceAngleMax);
if normAxe>0 % case of angle scan
a=-SliceAngleMax(2)/normAxe;
b=-SliceAngleMax(1)/normAxe;
c=-a*XmlData.Slice.SliceCoord(1,1)+b*XmlData.Slice.SliceCoord(1,2);%equation of the axis ax+by+c=0
DNormal=norm(a*X+b*Y+c);
Ang=atand(Zp./DNormal);
ZIndex=ZIndex+Ang-norm(XmlData.Slice.SliceAngle(1,:))+1;
end

%------------------------------------------------------------
% proj_volume: poject each image on a common grid given by coord_x and coord_y 
function A=proj_volume(AMerge,XmlData,X,Y,Z)

A=[]; %default output

%% initial image coordinates
[npy,npx,npz]=size(AMerge);
xima=0.5:npx-0.5;%image coordinates of corners
%yima=npy-0.5:-1:0.5;
yima=0.5:npy-0.5;
zima=0.5:npz-0.5;
[XIMA_init,YIMA_init,ZIMA_init]=meshgrid(xima,yima,zima);%grid of initial image in px coordinates

%% projected coordinates
ZIndex=XYZtoIndex(XmlData,X,Y,Z);% Z positions correspoonding to X,Y positions

%% interpolation on the new grid
[XIMA,YIMA]=px_XYZ(XmlData.GeometryCalib,XmlData.Slice,X,Y,Z);% image coordinates for each point in the real
A=interp3(XIMA_init,YIMA_init,ZIMA_init,AMerge,XIMA,YIMA,ZIndex);



% proj_plane: poject each image on a common grid given by coord_x and coord_y 
function DataOut=proj_plane(DataIn,XmlData,X,Y)

DataOut=DataIn; %default output

%% initial image coordinates
[npy,npx]=size(DataIn.A);
xima=0.5:npx-0.5;%image coordinates of corners
yima=npy-0.5:-1:0.5;
[XIMA_init,YIMA_init]=meshgrid(xima,yima);%grid of initial image in px coordinates

%% projected coordinates
Z=Zpos(XmlData,DataIn.ZIndex,X,Y);% Z positions correspoonding to X,Y positions

%% interpolation on the new grid
[XIMA,YIMA]=px_XYZ(XmlData.GeometryCalib,XmlData.Slice,X,Y,Z);% image coordinates for each point in the real
DataOut.A=interp2(XIMA_init,YIMA_init,DataIn.A,XIMA,YIMA);





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
