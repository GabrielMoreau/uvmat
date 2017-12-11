%'get_file_info': determine info about a file (image, multimage, civdata,...) . 
%------------------------------------------------------------------------
% [FileInfo,VideoObject]=get_file_info(fileinput)
%
% OUTPUT:
% FileInfo: structure containing info on the file (case of images or video), in particular
%      .FileType: type of file, needed as input of read_field.m
%      .FileIndexing='on' for data files (when series of indexed files are  expected)
%      .Height: image height in pixels
%      .Width:  image width in pixels
%      .BitDepth: nbre of bits per pixel  (8 of 16)
%      .ColorType: 'greyscale' or 'color'
%      .NumberOfFrames
%      .FrameRate: nbre of frames per second, =[] for images
% VideoObject: in case of video
%
% INPUT:
% fileinput: name, including path, of the file to analyse

%=======================================================================
% Copyright 2008-2017, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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
if ~isempty(regexp(fileinput,'^http://'))|| exist(fileinput,'file')
    FileInfo.FileName=fileinput;
    FileInfo.FileType='txt'; %default
else
    FileInfo.FileType='';
    return
end
[tild,tild,FileExt]=fileparts(fileinput);%get the file extension FileExt

switch FileExt
    case '.fig'
        FileInfo.FileType='figure';
    case {'.xml','.xls','.dat','.bin'}
        FileInfo.FileType=regexprep(FileExt,'^.','');% eliminate the dot of the extension;
    case {'.seq','.sqb'}
        [A,FileInfo,timestamps,errormsg]=read_rdvision(fileinput,[]);
%         %%%%%
%         FileInfo.NumberOfFrame=24000;
%         %%%%%%%%
    case '.im7'
        try
             Input=readimx(fileinput);
             Image=Input.Frames{1}.Components{1}.Planes{1};
             FileInfo.FileType='image_DaVis';
             FileInfo.NumberOfFrames=numel(Input.Frames);
             FileInfo.Height=size(Image,2);
             FileInfo.Width=size(Image,1);
        catch ME
            msgbox_uvmat('ERROR',ME.message)
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
                            FileInfo.FileName=fileinput;
                            nbfield=numel(fieldnames(FileInfo));
                            FileInfo=orderfields(FileInfo,[nbfield nbfield-3 nbfield-1 nbfield-2 (1:nbfield-4)]); %reorder the fields of fileInfo for clarity
                        end
                    end
                end
            end
        end
end
switch FileInfo.FileType
    case {'image','image_DaVis','multimage','mmreader','cine_phantom','video','netcdf','civdata'}
        FileInfo.FileIndexing='on'; % allow to detect file index for scanning series
end
