%'read_image': read images or video objects
%----------------------------------------------------------------------
% function [A,ObjectOut]=read_image(FileName,FileType,VideoObject,num)
%
% OUTPUT:
% A(npy,npx,rgb): matrix of integers (iunt8 or uint16) representing the image, with sizes npy, npx, and possibly color component rgb=1:3
% ObjectOut: video object (=[] for single images)
%
% INPUT:
% FileName: input file name
%                 other inputs needed  only for video and multi-image file:
% FileType: input file type, as determined by the function get_file_info.m
% VideoObject: video object (for faster reading if availlable)
% num: frame index for movies or multimage types

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

function [A,ObjectOut]=read_image(FileName,FileType,VideoObject,num)
%-----------------------------------------------------------------------
if ~exist('FileType','var')
    FileType='image';
end
if isempty(FileType)
    FileType='image';
end
if ~exist('VideoObject','var')
    VideoObject=[];
end
if ~exist('num','var')
    num=1;
end
if isempty(num)
    num=1;
end
A=[];
ObjectOut=VideoObject;%default
switch FileType
    case 'video'
        if isa(VideoObject,'VideoReader')
            A=read(VideoObject,num);
        else
            ObjectOut=VideoReader(FileName);
            A=read(ObjectOut,num);
        end
    % case 'mmreader'
    %     if strcmp(class(VideoObject),'mmreader')
    %         A=read(VideoObject,num);
    %     else
    %         ObjectOut=mmreader(FileName);
    %         A=read(ObjectOut,num);
    %     end
    case 'cine_phantom'
        A = read_cine_phantom(FileName,num );
    case 'multimage'
        A=imread(FileName,num);
    case 'image'
        A=imread(FileName);
    case 'image_DaVis'
                Input=readimx(FileName);
                if isscalar(Input.Frames)
                    A=Input.Frames{1}.Components{1}.Planes{1}';
                else
        A=Input.Frames{num}.Components{1}.Planes{1}';
                end
    case 'telopsIR'     
        [A,Header]=readIRCam(FileName,'Frames',num);
        A=flip(A);
         A=(reshape(A,Header(1).Width,Header(1).Height))';
    case 'rdvision'
         A=read_rdvision(FileName,num);
end
