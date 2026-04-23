% 'movie2png': copy a movie to a series of grey scale .png images 
%------------------------------------------------------------------------
% function ParamOut=movie2png(Param)
%------------------------------------------------------------------------
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
function ParamOut=movie2png(Param)

%% set the input elements needed on the GUI series when the function is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.OutputDirExt='.png';%set the output dir extension
    ParamOut.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    
    first_j=[];
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,'');
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('WARNING',['the first input file ' FirstFileName ' does not exist'])
    end
    return
end

%% INPUT PARAMETERS (to edit)
increment=Param.IndexRange.incr_i;% frame increment: the frequency of the png images will be (initial frequency)/increment.
colorweight=[1 1 1] % relative weight of color components [r g b] for the resulting B/W image

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
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
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files
if ~isfield(Param,'InputFields')
    Param.InputFields.FieldName='';
end
%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE
 
%% root input file type
RootPath=Param.InputTable{1,1};
RootFile=Param.InputTable{1,3};
SubDir=Param.InputTable{1,2};
NomType=Param.InputTable{1,4};
FileExt=Param.InputTable{1,5};
    first_j=[];
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,'');
    InputFileName=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i1,i2,j1,j2);
[FileInfo,VideoObject]=get_file_info(InputFileName);

%% determine the file type on each line from the first input file 
if isempty(find(strcmp(FileInfo.FileType,{'mmreader','video'})));% =1 for images
    disp_uvmat('ERROR','the input is not a movie or image series',checkrun)
end
FileExtOut='.png'; %image output (input and proj result = image)
NomTypeOut='_1';% output file index will indicate the first and last ref index in the series
RootFileOut=RootFile;
NbField=floor((Param.IndexRange.last_i-Param.IndexRange.first_i+1)/increment);
%% create xml file with timing: 
%info=aviinfo(aviname);
t=xmltree;
t=set(t,1,'name','ImaDoc');
[t,uid]=add(t,1,'element','Heading');
% A AJOUTER
% Heading.Project='';
Heading.ImageName='frame_1.png';
t=struct2xml(Heading,t,uid);
[t,uid]=add(t,1,'element','Camera');
Camera.TimeUnit='s';
% Camera.BurstTiming.FrameFrequency=info.FramesPerSecond/increment;
Camera.BurstTiming.Dti=1/FileInfo.FrameRate;
Camera.BurstTiming.NbDti=NbField*increment;
Camera.BurstTiming.Time=i1/FileInfo.FrameRate;%time of the first frame of the avi movie
t=struct2xml(Camera,t,uid);
save(t,[fileparts(InputFileName) '.xml'])

%% LOOP ON FRAMES

for index=Param.IndexRange.first_i:increment:Param.IndexRange.last_i
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    A=read_image(InputFileName,FileInfo.FileType,VideoObject,index);
    if ndims(A)==3% convert color image to B/W
        A=double(A);
        A=colorweight(1)*A(:,:,1)+colorweight(2)*A(:,:,2)+colorweight(3)*A(:,:,3);
        A=uint16(A);% transform to 16 bit integers
    end
    %new_index=1+floor((index-Param.IndexRange.first_i)/increment);
    OutputFileName=fullfile_uvmat(RootPath,OutputDir,RootFile,FileExtOut,NomTypeOut,index);
    %filename=[basename '_' num2str(new_index) '.png'];%create image name
    imwrite(A,OutputFileName,'BitDepth',16);%write image
    disp(['new frame '  num2str(index) ' written as png image'])
end

%% main loop on frames
% for ifile=1:nbfield
%      stopstate=get(hRUN,'BusyAction');
%      if isequal(stopstate,'queue')% if STOP command is not activated
%         waitbarpos(4)=(ifile/nbfield)*Series.WaitbarPos(4);
%         waitbarpos(2)=Series.WaitbarPos(4)+Series.WaitbarPos(2)-waitbarpos(4);
%         set(hwaitbar,'Position',waitbarpos)%update waitbar on the series interface
%         drawnow
%         A=read_image(aviname,'movie',num_i1(ifile),MovieObject);
%         if ndims(A)==3% convert color image to B/W
%             A=double(A);
%             A=colorweight(1)*A(:,:,1)+colorweight(2)*A(:,:,2)+colorweight(3)*A(:,:,3);
%             A=uint8(A);% transform to 8 bit integers
%         end
%         new_index=1+floor((num_i1(ifile)-num_i1(1))/increment);
%         filename=[basename '_' num2str(new_index) '.png'];%create image name
%         imwrite(A,filename,'BitDepth',8);%write image
%         display(['new frame '  num2str(new_index) ' written as png image'])
%      end
% end



