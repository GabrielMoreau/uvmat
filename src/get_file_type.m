%'get_file_type': determine info about a file (image, multimage, civdata,...) . 
%------------------------------------------------------------------------
% [FileType,FileInfo,Object]=get_file_type(fileinput)
%
% OUTPUT:
% FileType: type of file
% FileInfo: structure containing info on the file (case of images or video), in particular
%      .Height: image height in pixels
%      .Width:  image width in pixels
%      .BitDepth: nbre of bits per pixel  (8 of 16)
%      .ColorType: 'greyscale' or 'color'
%      .NumberOfFrames
%      .FrameRate: nbre of frames per second, =[] for images
% Object: in case of video
%
% INPUT:
% fileinput: name, including path, of the file to analyse
function [FileInfo,VideoObject]=get_file_type(fileinput)
VideoObject=[];
if exist(fileinput,'file')
    FileInfo.FileName=fileinput;
    FileInfo.FileType='txt'; %default
else
    FileInfo.FileType='';
    return
end
[tild,tild,FileExt]=fileparts(fileinput);%get the fiel extension FileExt

switch FileExt
    case '.fig'
        FileInfo.FileType='figure';
    case '.xml'
        FileInfo.FileType='xml';
    case '.xls'
        FileInfo.FileType='xls';
    case '.dat'
        FileInfo.FileType='dat';;
    otherwise
        if ~isempty(FileExt)% exclude empty extension
            FileExt=regexprep(FileExt,'^.','');% eliminate the dot of the extension
            if ~isempty(FileExt)
                if ~isempty(imformats(FileExt))%case of images
                    try
                        imainfo=imfinfo(fileinput);
                        if length(imainfo) >1 %case of image with multiple frames   
                            FileInfo=imainfo(1);%take info from the first frame
                            FileInfo.FileType='multimage';
                            FileInfo.NumberOfFrames=length(imainfo);
                        else
                            FileInfo=imainfo;
                            FileInfo.FileType='image';
                            FileInfo.NumberOfFrames=1;
                        end
                        FileInfo.FileName=FileInfo.Filename; %correct the info given by imfinfo
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
                                FileType='civx'; % test for civx velocity fields
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
                               % FileType='civdata'; % test for civx velocity fields
                                FileInfo.CivStage=Data.CivStage;
                            else
                                FileInfo.FileType='netcdf';
                                %FileType='netcdf';
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
                            FileInfo.FileName=fileinput;
                            FileInfo.BitDepth=FileInfo.BitsPerPixel/3;
                        end
                    end
                end
            end
        end
end