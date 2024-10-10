%'aver_stat': calculate Reynolds stress components over time series
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

function ParamOut=LIF_proj(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('on' if needed as input, fixed value e.g. 1, 'off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.lif_proj';%set the output dir extension
    ParamOut.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
%     filecell=get_file_series(Param);%check existence of the first input file
%     if ~exist(filecell{1,1},'file')
%         msgbox_uvmat('WARNING','the first input file does not exist')
%     end
    if ~strcmp(Param.InputTable{1,5},'.png')
         msgbox_uvmat('ERROR','put .png image in first input line');
    end
    if ~strcmp(Param.InputTable{2,5},'.nc')
         msgbox_uvmat('ERROR','put .nc file (mproj) in second input line');
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

%% settings for the output file
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

   RootPathOut=fullfile(Param.OutputPath,Param.Experiment,Param.Device);
    OutputDir=[Param.OutputSubDir Param.OutputDirExt];

interval=Param.IndexRange.incr_i% statistics is done taking into account the input index increment

%%
%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%

ind_first=Param.IndexRange.first_i;
for index_i=ind_first:interval:Param.IndexRange.last_i
    if ~isempty(RUNHandle)&& ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break
    end
    % read teh netcdf file with velocity data (after vel3C)
    InputFile=fullfile_uvmat(RootPath{2},SubDir{2},RootFile{2},FileExt{2},NomType{2},index_i)
    [Field,tild,errormsg] = nc2struct(InputFile);
    Field.ListVarName=[Field.ListVarName {'C'}];% add image intensity to the list of fields
    Field.VarDimName=[Field.VarDimName {{'coord_y','coord_x'}}];% same dimension as for the projected velocity data
    Dx=(Field.coord_x(end)-Field.coord_x(1))/(numel(Field.coord_x)-1);%mesh of the projected velocity  data
    Dy=(Field.coord_y(end)-Field.coord_y(1))/(numel(Field.coord_y)-1);
    %read the two images of the pair
    InputFile_1=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},NomType{1},index_i,[],first_j);
    [Ima,tild,errormsg] = read_field(InputFile_1,'image');
    InputFile_2=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},NomType{1},index_i,[],last_j);
    B=imread(InputFile_2);
    Ima.A=Ima.A+B; % take the sum of the two images of the pair corresponding to the PIV data
    
    [A_out,Rangx,Rangy]=phys_ima(Ima.A,XmlData{1},1);%transfor to phys coordinates
    pixel_x=(Rangx(2)-Rangx(1))/size(A_out,2);% phys size of a pixel
    pixel_y=(Rangy(1)-Rangy(2))/size(A_out,1);
    Npfilt_x=round(Dx/(2*pixel_x));
    Npfilt_y=round(Dy/(2*pixel_y));
    ix=-Npfilt_x:Npfilt_x;
    iy=-Npfilt_y:Npfilt_y;
    fct2_x=cos(ix*pi/(2*(Npfilt_x-1)));
    fct2_y=cos(iy*pi/(2*(Npfilt_y-1)));
    %definition of the cos shape matrix filter
    
    Mfiltre=fct2_y'*fct2_x;
    Mfiltre=Mfiltre/(sum(sum(Mfiltre)));%normalize filter
    A_out=filter2(Mfiltre,A_out);%filtered image
    ind_x=round((Field.coord_x-Rangx(1))/pixel_x)+1;
    first_ind_x=find(ind_x>=1,1);
    last_ind_x=find(ind_x>size(A_out,2),1)-1;
    ind_x=ind_x(first_ind_x:last_ind_x);
    ind_y=round((Rangy(1)-Field.coord_y)/pixel_y)+1;
    last_ind_y=find(ind_y<1,1)-1;
    if isempty(last_ind_y)
        last_ind_y=numel(ind_y);
    end
    first_ind_y=find(ind_y<=size(A_out,1),1);
    if isempty(first_ind_y)
        first_ind_y=1;
    end
    ind_y=ind_y(first_ind_y:last_ind_y);
    Field.C=NaN(numel(Field.coord_y),numel(Field.coord_x));
    Field.C(first_ind_y:last_ind_y,first_ind_x:last_ind_x)=A_out(ind_y,ind_x);%image values at positions of the PIV data
    
    %% writing the result file as netcdf file
    
    OutputFile=fullfile_uvmat(RootPathOut,OutputDir,RootFile{1},'.nc',NomType{2},index_i);
    %case of netcdf input file , determine global attributes
    errormsg=struct2nc(OutputFile,Field); %save result file
    if isempty(errormsg)
        disp([OutputFile ' written']);
    else
        disp(['error in writting result file: ' errormsg])
    end
    
end
    
  
