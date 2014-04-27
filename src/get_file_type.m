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
function [FileType,FileInfo,VideoObject]=get_file_type(fileinput)

FileInfo=[];
VideoObject=[];
if exist(fileinput,'file')
    FileType='txt';%default, text file
else
    FileType='';
    return
end
[tild,tild,FileExt]=fileparts(fileinput);

switch FileExt
    case '.fig'
        FileType='figure';
    case '.xml'
        FileType='xml';
    case '.xls'
        FileType='xls';
    otherwise
        if ~isempty(FileExt)% exclude empty extension
            FileExt=regexprep(FileExt,'^.','');% eliminate the dot of the extension
            if ~isempty(FileExt)
                if ~isempty(imformats(FileExt))%case of images
                    try
                        imainfo=imfinfo(fileinput);
                        if length(imainfo) >1 %case of image with multiple frames
                            FileType='multimage';
                            FileInfo=imainfo(1);%take info from the first frame
                            FileInfo.NumberOfFrames=length(imainfo);
                        else
                            FileType='image';
                            FileInfo=imainfo;
                            FileInfo.NumberOfFrames=1;
                        end
                    end
                else
                    error_nc=0;
                    try
                        [Data,tild,tild,errormsg]=nc2struct(fileinput,'ListGlobalAttribute','absolut_time_T0','Conventions',...
                            'CivStage','patch2','fix2','civ2','patch','fix','hart');
                        if ~isempty(errormsg)
                            error_nc=1;
                        else
                            if ~isempty(Data.absolut_time_T0') && ~isempty(Data.hart)
                                FileType='civx'; % test for civx velocity fields
                                if isequal(Data.patch2,1)
                                    FileInfo.CivStage=6;
                                elseif isequal(Data.fix2,1)
                                    FileInfo.CivStage=5;
                                elseif  isequal(Data.civ2,1)
                                    FileInfo.CivStage=4;
                                elseif isequal(Data.patch,1)
                                    FileInfo.CivStage=3;
                                elseif isequal(Data.fix,1)
                                    FileInfo.CivStage=2;
                                else
                                    FileInfo.CivStage=1;
                                end
                            elseif strcmp(Data.Conventions,'uvmat/civdata')
                                FileType='civdata'; % test for civx velocity fields
                                FileInfo.CivStage=Data.CivStage;
                            else
                                FileType='netcdf';
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
                                FileType='video';
                            elseif exist('mmreader.m','file')% Matlab 2009a
                                VideoObject=mmreader(fileinput);
                                FileInfo=get(VideoObject);
                                FileType='mmreader';
                            end
                            FileInfo.BitDepth=FileInfo.BitsPerPixel/3;
                        end
                    end
                end
            end
        end
end