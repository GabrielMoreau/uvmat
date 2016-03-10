%'ima2netcdf': read image series and transform to netcdf
%------------------------------------------------------------------------

    
% function ParamOut=ima2netcdf(Param)
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

function ParamOut=ima2netcdf(Param)

%%%%%%%%%%%%%%%%%    INPUT PREPARATION MODE (no RUN)    %%%%%%%%%%%%%%%%%
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='on';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on'; % edit box nbre of slices made active
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.png';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    
    %% root input file(s) and type
    % check the existence of the first file in the series
        first_j=[];% note that the function will propose to cover the whole range of indices
    if isfield(Param.IndexRange,'MinIndex_j'); first_j=Param.IndexRange.MinIndex_j; end
    last_j=[];
    if isfield(Param.IndexRange,'MaxIndex_j'); last_j=Param.IndexRange.MaxIndex_j; end
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

    %% check the validity of  input file types
    ImageTypeOptions={'image','multimage','mmreader','video'};%allowed input file types(images)
    FileInfo=get_file_info(FirstFileName);
    FileType=FileInfo.FileType;
    CheckImage=~isempty(find(strcmp(FileType,ImageTypeOptions), 1));% =1 for images
    if ~CheckImage
        msgbox_uvmat('ERROR',['invalid file type input: ' FileType ' not an image'])
        return
    end
    
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

%% list of input images
DirImages=fullfile(Param.InputTable{1,1},Param.InputTable{1,2});
ListStruct=dir(DirImages);   
ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
check_bad=strcmp('.',ListCells(1,:))|strcmp('..',ListCells(1,:));%detect the dir '.' to exclude it
check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
ListFile=ListCells(1,find(~check_dir & ~check_bad));

% %% create the netcdf file with name flname in format NETCDF4
 OutputDir=fullfile(Param.InputTable{1,1},[Param.OutputSubDir Param.OutputDirExt]);
 
% cmode = netcdf.getConstant('NETCDF4');
% cmode = bitor(cmode, netcdf.getConstant('CLASSIC_MODEL'));
% cmode = bitor(cmode, netcdf.getConstant('CLOBBER'));
% nc = netcdf.create(fullfile(OutputDir,'images.nc'), cmode); 

%% Main loop
ImagesPerLevel=100;%100;
count=0;
%count=933;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%CORRECTION EXP08: 67->_11_1
%count=1934%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%CORRECTION EXP07: 
%% loop on the files 
for ifile=1:numel(ListFile)
    update_waitbar(WaitbarHandle,ifile/numel(ListFile))
    if ~isempty(RUNHandle)&& ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break
    end
    ImageName=fullfile(DirImages,ListFile{ifile});
    NbFrames=numel(imfinfo(ImageName));
    % loop on the frames within the tiff file
    for iframe=1:NbFrames      
        A=imread(ImageName,iframe);
        count=count+1;
        if isequal(ImagesPerLevel,1)% mode series 
            
            OutputFile=fullfile(OutputDir,['img_' num2str(count) '.png']);
        else % mode multilevel or volume (indices i and j)
            i_index=fix(count/ImagesPerLevel)+1;
            j_index=mod(count,ImagesPerLevel)+1;
            OutputFile=fullfile(OutputDir,['img_' num2str(i_index) '_' num2str(j_index) '.png']);
        end
        imwrite(A,OutputFile,'BitDepth',16)
    end
end


