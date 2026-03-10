%'gext_file_info': determine info about a file (image, multimage, civdata,...) .
%------------------------------------------------------------------------
% [FileInfo,VideoObject]=get_file_info(fileinput)
%
% OUTPUT:
% FileInfo: structure containing info on the file (case of images or video), in particular
%     .FileName: confirms the file name, ='' if the file is not detected  
%     .FileType: type of file, needed as input of read_field.m
%               ='': unknown format
%               ='bin': binary file without specific organisation
%               ='dat': text file for data
%               ='figure': Matlab figure file, ext .fig
%               ='mat': Matlab data file
%               ='netcdf': generic netcdf file
%               ='xml': xml file
%               ='xls': Excel file
%               ='civdata': netcdf files provided by civ_series
%               ='pivdata_fluidimage': PIV data from software 'fluidimage'
%   different image and movie formats:
%               ='image': image format recognised by Matlab
%               ='multimage': image format recognised by Matlab with  multiple frames
%               ='video': video movie file
%               ='mmreader': video from old versions of Matlab (<2009)
%               ='rdvision': images in binary format from company rdvision
%               ='image_DaVis': images from softwar DaVis (company LaVision), requires specific conditions of Matlab version and computer system
%               ='cine_phantom': images from fast camera Phantom
%               ='telopsIR': Infrared images from  company Telops
%      .FieldType='image' for all kinds of images and movies, =FileType  else
%      .FileIndexing='on'/'off', = 'on' for series of indexed files or frames to scan
%      .Height: image height in pixels
%      .Width:  image width in pixels
%      .BitDepth: nbre of bits per pixel  (8 of 16)
%      .ColorType: 'greyscale' or 'color'
%      .NumberOfFrames: defined for images or movies
%      .FrameRate: nbre of frames per second, =[] if not documented
% VideoObject: in case of video
%
% INPUT:
% fileinput: name, including path, of the file to analyse

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

function [FileInfo,VideoObject]=get_file_info(fileinput)

VideoObject=[];
FileInfo.FileName='';% file doe not exist, defautlt
FileInfo.FileType='';% input file type not detected
FileInfo.FieldType=''; %default output
if ~ischar(fileinput)
    return
end

%% check the existence (not possible for OpenDAP data)
if ~isempty(regexp(fileinput,'^http://','once'))|| exist(fileinput,'file')
    FileInfo.FileName=fileinput;
%     FileInfo.FileType='txt'; %default
else
    return %input file does not exist.
end
[~,~,FileExt]=fileparts(fileinput);%get the file extension FileExt

%% look according to file extension
switch FileExt
    case '.fig'% Matlab figure assumed
        FileInfo.FileType='figure';
    case '.mat'% Matlab data format
        FileInfo.FileType='mat';
    case {'.txt','.log','.stdout','.stderr','.sh'}
        FileInfo.FileType='txt';
    case {'.xml','.xls','.dat','.bin'}
        FileInfo.FileType=regexprep(FileExt,'^.','');% eliminate the dot of the extension;
    case {'.seq','.sqb'}% data from rdvision
        [~,FileInfo]=read_rdvision(fileinput,[]);
    case '.im7'% data from LaVision (DaVis), requires specific conditions of Matlab version and computer system
        try
            Input=readimx(fileinput);
            Image=Input.Frames{1}.Components{1}.Planes{1};
            FileInfo.FileType='image_DaVis';
            FileInfo.NumberOfFrames=numel(Input.Frames);
            FileInfo.Height=size(Image,2);
            FileInfo.Width=size(Image,1);
            FileInfo.TimeName='timestamp';
            for ilist=1:numel(Input.Attributes)
                % if strcmp(Input.Attributes{ilist}.Name,'_Date')
                %     DateString=Input.Attributes{ilist}.Value;
                % end
                % if strcmp(Input.Attributes{ilist}.Name,'_Time')
                %     TimeString=Input.Attributes{ilist}.Value;
                % end
            end
        catch ME
            msgbox_uvmat('ERROR',{ME.message;'reading image from DaVis is not possible with this Matlab version and system'})
            return
        end
    case '.h5'% format hdf5, used for specific case of PIV data from 'Fluidimage'
        hinfo=h5info(fileinput);
        FileInfo.CivStage=0;
        for igroup=1:numel(hinfo.Groups)
            if strcmp(hinfo.Groups(igroup).Name,'/piv0')
                FileInfo.CivStage=3;
            end
            if strcmp(hinfo.Groups(igroup).Name,'/piv1')
                FileInfo.CivStage=6;
                break
            end
        end
        if FileInfo.CivStage~=0
            FileInfo.FileType='pivdata_fluidimage';
        else
            FileInfo.FileType='h5';
        end
    case '.cine'
        [FileInfo,BitmapInfoHeader, CameraSetup]=readCineHeader(fileinput);
        FileInfo.FileType='cine_phantom';
        FileInfo.NumberOfFrames=FileInfo.ImageCount;
        FileInfo.FrameRate=CameraSetup.FrameRate;
        FileInfo.Height=BitmapInfoHeader.biHeight;
        FileInfo.Width=BitmapInfoHeader.biWidth;
        FileInfo.BitDepth=BitmapInfoHeader.biBitCount;
        FileInfo.TimeName='video';
    case '.hcc' % infrared camera Telops
        installToolboxIRCAM
        [~,InfoArray]=readIRCam(fileinput,'HeadersOnly',true);
        FileInfo.FileType='telopsIR';
        FileInfo.Height=InfoArray(1).Height;
        FileInfo.Width=InfoArray(1).Width;
        FileInfo.FrameRate=InfoArray(1).AcquisitionFrameRate;
        FileInfo.NumberOfFrames=numel(InfoArray);
        FileInfo.TimeName='video';
        Path=fileparts(fileinput);% look for the xml file to document theb file series
        [RootPath,SubDir,DirExt]=fileparts(Path);
        if ~isempty(DirExt)
            disp(['ERROR: change the name of the folder containing the image files: no file extension ' DirExt])
            FileInfo.FileType='error';
            return
        end
%         XmlFile=fullfile(RootPath,[SubDir '.xml']);
%         CheckWriteImaDoc=true;
%         if exist(XmlFile,'file')
%             [XmlData,~,errormsg]=xml2struct(XmlFile);
%             if ~isempty(errormsg)
%                 disp(errormsg)
%                 FileInfo.FileType='error';
%                 return
%             elseif isfield(XmlData,'FileSeries')
%                 CheckWriteImaDoc=false;
%             end
%         end
%         if CheckWriteImaDoc
%             DirContent=dir(Path);
%             NbFiles=0;
%             FileSeries.Convention='telopsIR';
%             for ilist=1:numel(DirContent)
%                 FName=DirContent(ilist).name;
%                 if ~isempty(regexp(FName,'.hcc$', 'once'))
%                     NbFiles=NbFiles+1;
%                     FileSeries.FileName{NbFiles,1}=FName;
%                 end
%             end
%             FileSeries.NbFramePerFile=FileInfo.NumberOfFrames;
%             [checkupdate,xmlfile,errormsg]=update_imadoc(RootPath,SubDir,'FileSeries',FileSeries);
%         end

    otherwise
        if ~isempty(FileExt)% exclude empty extension
            FileExt=regexprep(FileExt,'^.','');% eliminate the dot of the extension
            if ~isempty(FileExt)
                if ~isempty(imformats(FileExt))%case of images
                    FileInfo.FileType='image';
                    try
                        imainfo=imfinfo(fileinput);
                        if length(imainfo) >1 %case of image with multiple frames
                            FileInfo=imainfo(1);%take info from the first frame
                            FileInfo.NumberOfFrames=length(imainfo);
                            FileInfo.FileType='multimage';
                        else
                            FileInfo=imainfo;
                            FileInfo.NumberOfFrames=1;
                            FileInfo.FileType='image';
                        end
                        FileInfo.FileName=FileInfo.Filename; %correct the info given by imfinfo
                        nbfield=numel(fieldnames(FileInfo));
                        FileInfo=orderfields(FileInfo,[nbfield nbfield-1 nbfield-2 (1:nbfield-3)]); %reorder the fields of fileInfo for clarity
                    catch ME
                        FileInfo.error=ME.message;
                    end

                else
                    error_nc=0;
                    try %try netcdf file
                        [Data,tild,tild,errormsg]=nc2struct(fileinput,[]);
                        if isempty(errormsg)
                            if isfield(Data,'Conventions') && ismember(Data.Conventions,{'uvmat/civdata','uvmat/civdata/compress'})
                               if strcmp(Data.Conventions,'uvmat/civdata')
                                FileInfo.FileType='civdata'; % test for civ velocity fields
                               else
                                   FileInfo.FileType='civdata_compress'; % test for civ velocity fields
                               end
                                FileInfo.CivStage=Data.CivStage;
                                MaskFile='';
                                if isfield(Data,'Civ2_Mask')
                                    MaskFile=Data.Civ2_Mask;
                                    if isfield(Data,'Civ2_NbSlice')
                                        FileInfo.MaskNbSlice=Data.Civ2_NbSlice;
                                    end
                                elseif isfield(Data,'Civ1_Mask')
                                    MaskFile=Data.Civ1_Mask;
                                    if isfield(Data,'Civ1_NbSlice')
                                        FileInfo.MaskNbSlice=Data.Civ1_NbSlice;
                                    end
                                end
                                if isfield(Data,'VolumeScan')
                                    FileInfo.VolumeScan=Data.VolumeScan;
                                end
                                if ~isempty(MaskFile)
                                    [RootPath,SubDir,RootFile,~,~,~,~,FileExt,NomType]=fileparts_uvmat(MaskFile);
                                    if strcmp(NomType,'_1')&& isfield(FileInfo,'MaskNbSlice')
                                        FileInfo.MaskFile=fullfile(RootPath,SubDir,RootFile);
                                    else
                                        FileInfo.MaskFile=MaskFile;% single mask for the series (no indexing)
                                    end
                                    FileInfo.MaskExt=FileExt;
                                end
                            elseif isfield(Data,'Conventions') && strcmp(Data.Conventions,'uvmat/civdata_3D')
                                FileInfo.FileType='civdata_3D'; % test for 3D volume civ velocity fields
                                FileInfo.CivStage=Data.CivStage;
                                z_dim_index=find(strcmp(Data.ListDimName,'npz'));
                                FileInfo.NumberOfFrames=Data.DimValue(z_dim_index);
                            else
                                FileInfo.FileType='netcdf';
                                FileInfo.ListVarName=Data.ListVarName;
                                FileInfo.VarAttribute={};
                                if isfield(Data,'VarAttribute')
                                    FileInfo.VarAttribute=Data.VarAttribute;
                                end
                                FileInfo.ListDimName=Data.ListDimName;
                                %                                 FileInfo.NumberOfFrames=Data.DimValue;
                            end
                        else
                            error_nc=1;
                        end
                    catch ME
                        error_nc=1;
                    end
                    if error_nc
                        try
                            if exist('mmreader.m','file')% Matlab 2009a
                                INFO=mmfileinfo (fileinput);
                                if  ~isempty(INFO.Video.Format)
                                    VideoObject=mmreader(fileinput);
                                    FileInfo=get(VideoObject);
                                    FileInfo.FileType='mmreader';
                                end
                            end
                            FileInfo.BitDepth=FileInfo.BitsPerPixel/3;
                            FileInfo.ColorType='truecolor';
                            FileInfo.TimeName='video';
                            FileInfo.FileName=fileinput;
                            nbfield=numel(fieldnames(FileInfo));
                            FileInfo=orderfields(FileInfo,[nbfield nbfield-4 nbfield-3 nbfield-1 nbfield-2 (1:nbfield-5)]); %reorder the fields of fileInfo for clarity
                            if ~isfield(FileInfo,'NumberOfFrames')
                                FileInfo.NumberOfFrames=floor(FileInfo.Duration*FileInfo.FrameRate);
                            end
                        end
                    end
                end
            end
        end
end

FileInfo.FieldType=FileInfo.FileType;%default
switch FileInfo.FileType
    case {'image','multimage','video','mmreader','rdvision','image_DaVis','cine_phantom','telopsIR'}
        FileInfo.FieldType='image';
    case {'civdata','civdata_compress','pivdata_fluidimage'}
        FileInfo.FieldType='civdata';
end

if strcmp(FileInfo.FieldType,'image') || ismember (FileInfo.FileType,{'mat','netcdf','civdata','civdata_compress'})
    FileInfo.FileIndexing='on'; % allow to detect file index for scanning series
else
    FileInfo.FileIndexing='off';
end


