%'read_image': read images or video objects
%----------------------------------------------------------------------
% function [A,ObjectOut]=read_image(FileName,FileType,VideoObject,num)
%
% OUTPUT:
% A(npy,npx,rgb): matrix of integers (iunt8 or uint16) representing the image, with sizes npy, npx, and possibly color component rgb=1:3
% ObjectOut: video object (=[] for images)
%
% INPUT:
% FileName: input file name
% FileType: input file type, as determined by the function get_file_type.m
% VideoObject: video object (for faster reading if availlable)
% num: frame index for movies or multimage types
%
function [A,ObjectOut]=read_image(FileName,FileType,VideoObject,num)
%-----------------------------------------------------------------------
if ~exist('VideoObject','var')
    VideoObject=[];
end
if ~exist('num','var')
    num=1;
end
ObjectOut=VideoObject;%default
switch FileType
         case 'video'
            if strcmp(class(VideoObject),'VideoReader')
                A=read(VideoObject,num);
            else
                ObjectOut=VideoReader(FileName);
                A=read(ObjectOut,num);
            end
        case 'mmreader'
            if strcmp(class(VideoObject),'mmreader')
                A=read(VideoObject,num);
            else
                ObjectOut=mmreader(FileName);
                A=read(ObjectOut,num);
            end
    case 'multimage'
        A=imread(FileName,num);
    case 'image'    
        A=imread(FileName);
end
