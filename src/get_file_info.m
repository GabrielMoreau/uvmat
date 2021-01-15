%'get_file_info': determine info about a file (image, multimage, civdata,...) . 
%------------------------------------------------------------------------
% [FileInfo,VideoObject]=get_file_info(fileinput)
%
% OUTPUT:
% FileInfo: structure containing info on the file (case of images or video), in particular
%      .FileType: type of file, needed as input of read_field.m
%               ='figure': Matlab figure
%               ='xml': xml file
%               ='xls': Excel file
%               ='dat': text file for data,
%               ='image': image format recognised by Matlab
%               ='multimage': image format recognised by Matlab with  multiple frames
%               ='video': video movie file
%               ='mmreader': video from old versions of Matlab (<2009)
%               ='rdvision': images in binary format from company rdvision
%               ='image_DaVis': images from softwar DaVis (company LaVision)
%               ='cine_phantom': images from fast camera Phantom
%               ='bin': binary file without specific organisation
%               ='netcdf': netcdf file 
%               ='civdata': netcdf files provided by civ_series
%               ='civx': netcdf files provided by the obsolete program civx (in fortran)
%               ='pivdata_fluidimage': PIV data from software 'fluidimage'
%      .FieldType='image' for all kinds of images and movies, =FileType  else
%      .FileIndexing='on'/'off', for data files (when series of indexed files are  expected)
%      .Height: image height in pixels
%      .Width:  image width in pixels
%      .BitDepth: nbre of bits per pixel  (8 of 16)
%      .ColorType: 'greyscale' or 'color'
%      .NumberOfFrames: defined for images or movies
%      .FrameRate: nbre of frames per second, =[] for images
% VideoObject: in case of video
%
% INPUT:
% fileinput: name, including path, of the file to analyse

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

function [FileInfo,VideoObject]=get_file_info(fileinput)
VideoObject=[];
FileInfo.FileType='';% input file does not exist
FileInfo.FieldType=''; %default output
% check the existence (not possible for OpenDAP data)
if ~isempty(regexp(fileinput,'^http://'))|| exist(fileinput,'file')
    FileInfo.FileName=fileinput;
    FileInfo.FileType='txt'; %default
else
    return %input file does not exist.
end
[tild,tild,FileExt]=fileparts(fileinput);%get the file extension FileExt

switch FileExt
    case '.fig'
        FileInfo.FileType='figure';
    case '.mat'
        FileInfo.FileType='mat';
    case {'.xml','.xls','.dat','.bin'}
        FileInfo.FileType=regexprep(FileExt,'^.','');% eliminate the dot of the extension;
    case {'.seq','.sqb'}
        [A,FileInfo,timestamps,errormsg]=read_rdvision(fileinput,[]);
    case '.im7'
        try
             Input=readimx(fileinput);
             Image=Input.Frames{1}.Components{1}.Planes{1};
             FileInfo.FileType='image_DaVis';
             FileInfo.NumberOfFrames=numel(Input.Frames);
             FileInfo.Height=size(Image,2);
             FileInfo.Width=size(Image,1);
             FileInfo.TimeName='timestamp';
             for ilist=1:numel(Input.Attributes)
                 if strcmp(Input.Attributes{ilist}.Name,'_Date')
                     DateString=Input.Attributes{ilist}.Value;
                 end
                 if strcmp(Input.Attributes{ilist}.Name,'_Time')
                     TimeString=Input.Attributes{ilist}.Value;
                 end
             end
        catch ME
            msgbox_uvmat('ERROR',{ME.message;'reading image from DaVis is possible only with Matlab version 2013 or earlier'})
            return
        end
    case '.h5'
        hinfo=hdf5info(fileinput);
        if strcmp(hinfo.GroupHierarchy.Attributes(1).Value.Data,'MultipassPIVResults')
            FileInfo.FileType='pivdata_fluidimage';
            FileInfo.CivStage=6; % A MODIFIER
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
    otherwise
        if ~isempty(FileExt)% exclude empty extension
            FileExt=regexprep(FileExt,'^.','');% eliminate the dot of the extension
            if ~isempty(FileExt)
                if ~isempty(imformats(FileExt))%case of images
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
                    end
                else
                    error_nc=0;
                    try
                       [Data,tild,tild,errormsg]=nc2struct(fileinput,[]);
                        if ~isempty(errormsg)
                            error_nc=1;
                        else
                            if isfield(Data,'absolut_time_T0') && isfield(Data,'hart') && ~isempty(Data.absolut_time_T0) && ~isempty(Data.hart)
                                FileInfo.FileType='civx';
                                if isfield(Data,'patch2') && isequal(Data.patch2,1)
                                    FileInfo.CivStage=6;
                                elseif isfield(Data,'fix2') && isequal(Data.fix2,1)
                                    FileInfo.CivStage=5;
                                elseif  isfield(Data,'civ2')&& isequal(Data.civ2,1)
                                    FileInfo.CivStage=4;
                                elseif isfield(Data,'patch')&&isequal(Data.patch,1)
                                    FileInfo.CivStage=3;
                                elseif isfield(Data,'fix')&&isequal(Data.fix,1)
                                    FileInfo.CivStage=2;
                                else
                                    FileInfo.CivStage=1;
                                end
                            elseif isfield(Data,'Conventions') && strcmp(Data.Conventions,'uvmat/civdata')
                                FileInfo.FileType='civdata'; % test for civx velocity fields
                                FileInfo.CivStage=Data.CivStage;
                            else
                                FileInfo.FileType='netcdf';
                                FileInfo.ListVarName=Data.ListVarName;
                            end
                        end
                    catch ME
                        error_nc=1;
                    end
                    if error_nc
                        try
                            if exist('VideoReader.m','file')%recent version of Matlab
                                VideoObject=VideoReader(fileinput);
                                FileInfo=get(VideoObject);
                                FileInfo.FileType='video';
                            elseif exist('mmreader.m','file')% Matlab 2009a
                                VideoObject=mmreader(fileinput);
                                FileInfo=get(VideoObject);
                                FileInfo.FileType='mmreader';
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

if ismember (FileInfo.FileType,{'image','image_DaVis','multimage','mmreader','cine_phantom','video','netcdf','civdata'})
        FileInfo.FileIndexing='on'; % allow to detect file index for scanning series
else
    FileInfo.FileIndexing='off';
end
FileInfo.FieldType=FileInfo.FileType;%default
switch FileInfo.FileType
    case {'image','multimage','video','mmreader','rdvision','image_DaVis','cine_phantom'}
    FileInfo.FieldType='image';
    case {'civx','civdata','pivdata_fluidimage'}
        FileInfo.FieldType='civdata';
end

