%'extract_multitif': read image series from PCO cameras (tiff image series) and write .png images
% use a single geometric calibration, with information on the slice positions in case of 3D scanning
%------------------------------------------------------
% the output file indexing is based on the xml file requested by the
% function when it is selected (or possibly inserted in this function in the section TEST)
%  This xml file must contain the following information:
%   NbDti: the number of 'bursts' -1
%   NbDtj: number of frames in each burst-1, or number of repetition of a burst sequence defined by Dtj
%   NbDtk: number of repetitions of a slice scanning process -1 (ignored by default)
% Therefore the total number of frames is  (NbDti+1)*(NbDtj+1)*(NbDtk+1)
% The frame series is stored in a single folder with two indices i:(NbDti+1)*(NbDtk+1) 
%
% To run the function in the cluster in parallel for each multitif file, indicate nb-slice_i equal to the
% number input multitif files


% function ParamOut=extract_multitif(Param)
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

function ParamOut=extract_multitif(Param)

%%%%%%%%%%%%%%%%%    INPUT PREPARATION MODE (no RUN)    %%%%%%%%%%%%%%%%%
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='on';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on'; % 
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.png';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    ParamOut.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default='off')
    ParamOut.CPUTime=10;% expected time for writting the output of one source image ( in minute)
    %% root input file(s) and type
 
    % check the existence of the first file in the series
    first_j=[];% note that the function will propose to cover the whole range of indices
    if isfield(Param.IndexRange,'MinIndex_j')
        first_j=Param.IndexRange.MinIndex_j;
    else
        msgbox_uvmat('ERROR',['select a multitif file labeled by a number, like im@0001.tif '])
        return
    end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('WARNING',['the first input file ' FirstFileName ' does not exist'])
    end
       FileInfo=get_file_info(FirstFileName);
    if ~strcmp(FileInfo.FileType,'multimage')%check the validity of  input file types
        msgbox_uvmat('ERROR',['invalid file type input: ' FileInfo.FileType ' not a tiff image series'])
        return
    end
    
    ParamOut.NbSlice=Param.IndexRange.MaxIndex_i;
    
    ParamOut.ActionInput.XmlFile=uigetfile_uvmat('pick xml file for timing',fileparts(fileparts(FirstFileName)),'.xml');  
    return
end
%%%%%%%%%%%%%%%%%    STOP HERE FOR PAMETER INPUT MODE   %%%%%%%%%%%%%%%%% 

%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
RUNHandle=[];
WaitbarHandle=[];
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
else
    hseries=findobj(allchild(0),'Tag','series');
    RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
    WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
end

%% output directory
OutputDir=fullfile(Param.InputTable{1,1},[Param.OutputSubDir Param.OutputDirExt]);

%% Timing
XmlInputFile=Param.ActionInput.XmlFile;
[XmlInput,errormsg]=imadoc2struct(XmlInputFile,'Camera');
if ~isempty(errormsg)
    disp(['bad xml input file: ' errormsg])
    return
end
ImagesPerLevel=size(XmlInput.Time,2)-1;%100;%use the xmlinformation to get the nbre of j indices

%% create the xml file for timing if it does not exist : example to adapt
TEST=0;
if TEST
    count0=14;
    Dtj=0.05;% time interval between frames
    ImagesPerLevel=455;% total number of images per position, ImagesPerLevel-Nbj images skiiped during motion between two positions
    Nbj=390; %Nbre of images kept at a given position
    Dti=Dtj*ImagesPerLevel;
    NbLevel=11;
    NbScan=3;
    TimeReturn=268.5; %time needed to return back to the first position (in sec)
    NbReturn=round(TimeReturn/Dtj);
    NbSkipReturn=NbReturn+1-NbLevel*ImagesPerLevel;
    
    Newxml=fullfile(Param.InputTable{1,1},[Param.InputTable{1,2} '.xml']);
    if ~exist(Newxml,'file')
        XmlInput.Camera.CameraName='PCO';
        XmlInput.Camera.TimeUnit='s';
        XmlInput.Camera.BurstTiming.FrameFrequency=1;
        XmlInput.Camera.BurstTiming.Time=0;% for 200
        XmlInput.Camera.BurstTiming.Dtj=Dtj;
        XmlInput.Camera.BurstTiming.NbDtj=Nbj-1;
        XmlInput.Camera.BurstTiming.Dti=Dti;
        XmlInput.Camera.BurstTiming.NbDti=NbLevel-1;
        XmlInput.Camera.BurstTiming.Dtk=TimeReturn;
        XmlInput.Camera.BurstTiming.NbDtk=NbScan-1;
        t=struct2xml(XmlInput);
        t=set(t,1,'name','ImaDoc');
        save(t,Newxml);
    end
end

%% loop on the files
% include the first tiff file with no index in the first iteration
if Param.IndexRange.first_i==1% first slice of processing
    firstindex=0;
   count=0;
else
    firstindex=Param.IndexRange.first_i;
    ImageName=fullfile(Param.InputTable{1,1},Param.InputTable{1,2},'im.tif');
    NbFrames=numel(imfinfo(ImageName));
   count=Param.IndexRange.first_i*NbFrames;
end
for ifile=firstindex:Param.IndexRange.last_i
    tic
    if firstindex==0 && ifile==0% first slice of processing
        ImageName=fullfile(Param.InputTable{1,1},Param.InputTable{1,2},'im.tif')
    else
        ImageName=fullfile(Param.InputTable{1,1},Param.InputTable{1,2},['im@' num2str(ifile,'%04d') '.tif'])
    end
    NbFrames=numel(imfinfo(ImageName));
    for iframe=1:NbFrames
        if isequal(ImagesPerLevel,1)% mode series
            OutputFile=fullfile(OutputDir,['img_' num2str(count+1) '.png']);
        else % indices i and j
            i_index=fix(count/ImagesPerLevel)+1;
            j_index=mod(count,ImagesPerLevel)+1;
            OutputFile=fullfile(OutputDir,['img_' num2str(i_index) '_' num2str(j_index) '.png']);
        end
        if Param.CheckOverwrite ||~exist(OutputFile,'file')
            A=imread(ImageName,iframe);
            imwrite(A,OutputFile,'BitDepth',16);
            disp([OutputFile ' written'])
        else
            disp([OutputFile ' already exists'])
        end
        count=count+1;
    end
    tt=toc;
    disp(['elapsed time (in min.) for the file im@' num2str(ifile,'%04d')])
    disp(num2str(tt/60))
end



