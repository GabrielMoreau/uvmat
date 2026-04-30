%'calc_background': calculate image background by sorting luminosity in sub-series blocks
%------------------------------------------------------------------------
% Method: 
    %calculate the background image by sorting the luminosity of each point
    % over a sliding sub-sequence of 'nbaver_ima' images. 
    % The luminosity value of rank 'rank' is selected as the
    % 'background'. rank=nbimages/2 gives the median value.  Smaller values are appropriate
    % for a dense set of particles. The extrem value rank=1 gives the true minimum
    % luminosity, but it can be polluted by noise. 
% Organization of image indices:
    % The program is working on a series of images, 
    % In the mode 'volume', nbfield2=1 (1 image at each level)and NbSlice (=NbField_j)
    % Else nbfield2=NbField_j =nbre of images in a burst (j index)
    
% function GUI_config=sub_background(Param)
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%OUTPUT
% GUIParam: sets options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% when Param.Action.RUN=0 (as activated when the current Action is selected
% in series), the function ouput GUIParam set the activation of the needed GUI elements
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

function GUIParam=calc_background (Param)

%%%%%%%%%%%%%%%%%    INPUT PREPARATION MODE (no RUN)    %%%%%%%%%%%%%%%%%
if isstruct(Param) && isequal(Param.Action.RUN,0)
    GUIParam.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    GUIParam.WholeIndexRange='on';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    GUIParam.NbSlice='on'; % edit box nbre of slices made active
    GUIParam.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    GUIParam.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    GUIParam.FieldTransform = 'off';%can use a transform function (option 'off'/'on','off' by default)
    GUIParam.ProjObject='off';%cannot use projection object(option 'off'/'on','off' by default)
    GUIParam.Mask='off';%cannot use mask option   (option 'off'/'on', 'off' by default)
    GUIParam.OutputDirExt='.bkgnd';%set the output dir extension
    GUIParam.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice

    %% check the validity of  input file types
    if isfield(Param,'SeriesData')&& isfield(Param.SeriesData,'FileInfo')
    if ~strcmp(Param.SeriesData.FileInfo{1}.FieldType,'image')
        msgbox_uvmat('ERROR','invalid file type input: not an image series')
        return
    end
    end

    %% numbers of fields
    NbSlice_i=1;%default
    if isfield(Param.IndexRange,'NbSlice')&&~isempty(Param.IndexRange.NbSlice)
        NbSlice_i=Param.IndexRange.NbSlice;
    end
    incr_j=1;%default
    if isfield(Param.IndexRange,'incr_j')&&~isempty(Param.IndexRange.incr_j)
        incr_j=Param.IndexRange.incr_j;
    end
    if isfield(Param.IndexRange,'first_j')&&~isempty(Param.IndexRange.first_j)
        NbField_j=numel(Param.IndexRange.first_j:incr_j:Param.IndexRange.last_j);%nb of fields for the j index (bursts or volume slices)
    else
        NbField_j=1;
    end
    first_i=1;last_i=1;incr_i=1;%default
    if isfield(Param.IndexRange,'MinIndex_i'); first_i=Param.IndexRange.MinIndex_i; end   
    if isfield(Param.IndexRange,'MaxIndex_i'); last_i=Param.IndexRange.MaxIndex_i; end
    if isfield(Param.IndexRange,'incr_i')&&~isempty(Param.IndexRange.incr_i)
        incr_i=Param.IndexRange.incr_i;
    end
    nbfield_i=numel(first_i:incr_i:last_i);%nb of fields for the i index (bursts or volume slices)
    nbfield=NbField_j*nbfield_i; %total number of fields
    nbfield_i=floor(nbfield/NbSlice_i);%total number of  indexes in a slice (adjusted to an integer number of slices)
    
    %% setting of  parameters specific to sub_background
    CheckVolume='No';
    nbaver_init=20; %default number of images used for the sliding background: to be adjusted later to include an integer number of bursts 
     if nbfield_i~=1 && NbField_j<=nbaver_init
        nbaver=floor(nbaver_init/NbField_j); % number of bursts used for the sliding background,
        nbaver_init=nbaver*NbField_j;%propose by default an integer number of bursts
    end
    BrightnessRankThreshold=0.1;
    if isfield(Param,'ActionInput')
        if isfield(Param.ActionInput,'CheckVolume') && Param.ActionInput.CheckVolume
            CheckVolume='Yes';
        end
        if isfield(Param.ActionInput,'SlidingSequenceLength')
         nbaver_init=Param.ActionInput.SlidingSequenceLength;
        end
        if isfield(Param.ActionInput,'BrightnessRankThreshold')
          BrightnessRankThreshold=Param.ActionInput.BrightnessRankThreshold;
        end
%         if isfield(Param.ActionInput,'SaturationValue') 
%             SaturationValue=Param.ActionInput.SaturationValue;
%         end
    end   
    prompt = {'volume scan mode (Yes/No)';...
        'Number of images for the sliding background (MUST FIT IN COMPUTER MEMORY)';...
        'the luminosity rank chosen to define the background (0.1=for dense particle seeding, 0.5 (median) for sparse particles'};
    dlg_title = 'get (slice by slice) a sliding background and substract to each image';
    num_lines= 3;
    def     = { CheckVolume;num2str(nbaver_init);num2str(BrightnessRankThreshold)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        return
    end
    %check input consistency
    if strcmp(answer{1},'No') && ~isequal(NbSlice_i,1)
        check=msgbox_uvmat('INPUT_Y-N',['confirm the multi-level splitting into ' num2str(NbSlice_i) ' slices']);
        if ~strcmp(check,'Yes')
            return
        end
    end
    if strcmp(answer{1},'Yes')
        step=2;%the sliding background is shifted by the length of one burst, assumed =2 for volume 
        GUIParam.NbSlice=1; %nbre of slices displayed 
    else
        step=NbField_j;%case of bursts: the sliding background is shifted by the length of one burst
    end
    GUIParam.ActionInput.SlidingSequenceLength=adjust_slidinglength(str2double(answer{2}),step);
    GUIParam.ActionInput.CheckVolume=strcmp(answer{1},'Yes');
    GUIParam.ActionInput.BrightnessRankThreshold=str2double(answer{3});
    return
end
%%%%%%%%%%%%%%%%%    STOP HERE FOR PAMETER INPUT MODE   %%%%%%%%%%%%%%%%% 


GUIParam=[];
%% read input parameters from an xml file if input is a file name (batch mode)
RUNHandle=[];
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
else
    hseries=findobj(allchild(0),'Tag','series');
    RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series (to allow for run interruption by the button STOP
end

%% input preparation
NbSlice_i=Param.IndexRange.NbSlice;
if ~isequal(NbSlice_i,1)
    disp(['multi-level splitting into ' num2str(NbSlice_i) ' slices']);
end
RootPath=Param.InputTable{1,1};
RootFile=Param.InputTable{1,3};
SubDir=Param.InputTable{1,2};
NomType=Param.InputTable{1,4};
FileExt=Param.InputTable{1,5};

%% file index parameters
% NbSlice_i: nbre of slices for i index in multi-level mode: equal to 1 for a single level
% the function sub_background is then relaunched by the GUI series for each
%      slice, incrementing the first index i by 1
% NbSlice_j: nbre of slices in volume mode
% nbfield : total number of images treated per slice
% step: shift of image index at each step of the sliding background (corresponding to the nbre of images in a burst)
% nbaver_ima: nbre of the images in the sliding sequence used for the background
% nbaver=nbaver_ima/step: nbre of bursts corresponding to nbaver_ima images. It has been adjusted so that nbaver is an odd integer
i_indices=Param.IndexRange.first_i:Param.IndexRange.incr_i:Param.IndexRange.last_i;
if isfield(Param.IndexRange,'first_j')
    j_indices=Param.IndexRange.first_j:Param.IndexRange.incr_j:Param.IndexRange.last_j;
else
    j_indices=1;
end
nbfield_i=numel(i_indices); %nb of fields for the i index (bursts or volume slices)
NbField_j=numel(j_indices); %nb of fields for the j index
j_indices=j_indices'*ones(1,nbfield_i);
i_indices=ones(NbField_j,1)*i_indices;

if Param.ActionInput.CheckVolume% case of volume scan: the background images must be determined for each index j
    step=2;% we assume the burst contains only one image pair
    NbSlice_j=NbField_j;
    nbfield_series=nbfield_i;
else
    if Param.ActionInput.SlidingSequenceLength<NbField_j
        step=1;
    else
        step=NbField_j;%case of bursts: the sliding background is shifted by the length of one burst
    end
    NbSlice_j=1;
    nbfield_series=nbfield_i*NbField_j;
end
nbfield=NbField_j*nbfield_i; %total number of fields
[nbaver_ima,nbaver,step]=adjust_slidinglength(Param.ActionInput.SlidingSequenceLength,step);
if nbaver_ima > nbfield
    disp('number of images in a slice smaller than the proposed number of images for the sliding average')
    return
end
%halfnbaver=floor(nbaver/2); % half width (in unit of bursts) of the sliding background


%% File relabeling documented by the xml file
CheckRelabel=isfield(Param.IndexRange,'Relabel' )&& Param.IndexRange.Relabel;%=true for index relabeling (PCO);

%% Input file info
if CheckRelabel
    XmlFileName=find_imadoc(RootPath,SubDir);
    if ~isempty(XmlFileName)
        XmlData=imadoc2struct(XmlFileName);%read the time from XmlFileName
    end
    RootFileOut='frame';
    [RootFile,frame_index]=index2filename(XmlData.FileSeries,Param.IndexRange.first_i,j_indices(1),NbField_j);
    FirstFileName=fullfile(RootPath,SubDir,RootFile);
else
    FirstFileName=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,Param.IndexRange.first_i,[],j_indices(1));%get first file name
    RootFileOut=RootFile;
end
[FileInfo,MovieObject]=get_file_info(FirstFileName);
if isfield(FileInfo,'ColorType') && strcmp(FileInfo.ColorType,'truecolor')
    BitDepth=16;
else
    BitDepth=FileInfo.BitDepth;
end
FileType=FileInfo.FileType;
if ~CheckRelabel
    if isfield(FileInfo,'NumberOfFrames') && FileInfo.NumberOfFrames >1
        if isempty(regexp(NomType,'1$', 'once'))% no file indexing
            frame_index=i_indices;% the index i denotes the frame number in a movie, no index j
        else
            frame_index=j_indices;% the index j denotes the frame number in a movie
            MovieObject=[]; %not a single video object
        end
    else
        frame_index=ones(1,nbfield);
    end
end

%% output file naming
if Param.ActionInput.CheckVolume || Param.IndexRange.first_j>Param.IndexRange.MinIndex_j || Param.IndexRange.last_j<Param.IndexRange.MaxIndex_j
    NomTypeOut='_1_1';
else
    NomTypeOut='_1';
end
OutputDir=[Param.OutputSubDir Param.OutputDirExt];
OutputPath=fullfile(Param.OutputPath,Param.Experiment,Param.Device);

%% calculate absolute brightness rank
rank=floor(Param.ActionInput.BrightnessRankThreshold*nbaver_ima);
if rank==0
    rank=1;%rank selected in the sorted image series
end

%% selection of frame indices
if Param.ActionInput.CheckVolume
    nbfield=floor(nbfield/NbSlice_j)*NbSlice_j;% truncate the total number of frames in case of incomplete series
    indselect=1:nbfield;
    indselect=reshape(indselect,NbSlice_j,[]);
    NbSlice=NbSlice_j;
else
    NbSlice=NbSlice_i;
    nbfield=floor(nbfield/NbSlice)*NbSlice;% truncate the total number of frames in case of incomplete series
    indselect=reshape(1:nbfield,NbSlice,[]);
    for j_slice=1:NbSlice
        indselect(j_slice,:)=j_slice:NbSlice:nbfield;% select file indices of the slice
    end
end

%%%%%%%  LOOP ON SLICES %%%%%%%
for j_slice=1:NbSlice
     %%%%%%%  LOOP ON BLOCKS OF nbaver_ima files %%%%%%%
    for iblock=1:nbaver_ima:nbfield_series
        last_index=min(iblock+nbaver_ima-1,nbfield_series);
        Ak=zeros(FileInfo.Height,FileInfo.Width,nbaver_ima,['uint' num2str(BitDepth)]); %prealocate memory
        for ifield = iblock:last_index
            ifile=indselect(j_slice,ifield);
            if CheckRelabel
                [filename,FrameIndex]=index2filename(XmlData.FileSeries,i_indices(ifile),j_indices(ifile),NbField_j);
                filename=fullfile(RootPath,SubDir,filename);
            else
                filename=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i_indices(ifile),[],j_indices(ifile))
                FrameIndex=frame_index(ifile);
            end
            if ifield==iblock
                filename_out=fullfile_uvmat(OutputPath,OutputDir,RootFileOut,'.png',NomTypeOut,i_indices(ifile),[],j_indices(ifile));
            end
            Aread=read_image(filename,FileType,MovieObject,FrameIndex);
            if ndims(Aread)==3  %color images 
                Aread=sum(uint16(Aread),3);% take the sum of color components
            end
            Ak(:,:,ifield-iblock+1)=Aread;
        end
        
        B=mink(Ak,rank,3);%sort the luminosity of images at each point, keeping the smallest values (nbre given by rank)
        B=squeeze(B(:,:,rank));%background image
        
        %write result file
        imwrite(B,filename_out,'BitDepth',BitDepth); % save the new image   
        disp([filename_out ' written'])
    end
end


%------------------------------------------
% adjust the number of images used for the sliding average
function [nbaver_ima,nbaver,step_out]=adjust_slidinglength(nb_aver_in,step)
%nbaver_ima=str2double(nb_aver_in);%number of images for the sliding background
nbaver=ceil(nb_aver_in/step);%number of bursts for the sliding background
% if isequal(mod(nbaver,2),0)% if nbaver is even
%     nbaver=nbaver+1;%set the number of bursts to an odd number (so the middle burst is defined)
% end
step_out=step;
if nbaver>1
    nbaver_ima=nbaver*step;% correct the nbre of images corresponding to nbaver
else
    nbaver_ima=nb_aver_in;
%     if isequal(mod(nbaver_ima,2),0)% if nbaver_ima is even
%         nbaver_ima=nbaver_ima+1;%set the number of bursts to an odd number (so the middle burst is defined)
%     end
    step_out=1;
end
