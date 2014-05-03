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
%%%% TODO: suppress the output argument FileType, contained in FileInfo %%%%
FileInfo=[];% will remain empty in the absence of input file
VideoObject=[];
if exist(fileinput,'file')
    FileInfo.FileName=fileinput;
    FileInfo.FileType='txt'; %default
    FileType='txt';%default, text file
else
    FileType='';
    return
end
[tild,tild,FileExt]=fileparts(fileinput);

switch FileExt
    case '.fig'
        FileInfo.FileType='figure';
        FileType='figure';
    case '.xml'
        FileInfo.FileType='xml';
        FileType='xml';
    case '.xls'
        FileInfo.FileType='xls';
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
                        FileInfo.FileName=FileInfo.Filename; %correct the info given by imfinfo
                        FileInfo.FileType=FileType;
                    end
                else
                    error_nc=0;
                    try
                      %  [Data,tild,tild,errormsg]=nc2struct(fileinput,'ListGlobalAttribute','absolut_time_T0','Conventions',...
                       %     'CivStage','patch2','fix2','civ2','patch','fix','hart');
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
                                FileType='civdata'; % test for civx velocity fields
                                FileInfo.CivStage=Data.CivStage;
                            else
                                FileInfo.FileType='netcdf';
                                FileType='netcdf';
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
                                FileType='video';
                            elseif exist('mmreader.m','file')% Matlab 2009a
                                VideoObject=mmreader(fileinput);
                                FileInfo=get(VideoObject);
                                FileType='mmreader';
                            end
                            FileInfo.FileName=fileinput;
                            FileInfo.FileType=FileType;
                            FileInfo.BitDepth=FileInfo.BitsPerPixel/3;
                        end
                    end
                end
            end
        end
end