%'get_file_type': determine info about a file (image, multimage, civdata,...) . 
%------------------------------------------------------------------------
% [FileType,FileInfo,Object]=get_file_type(fileinput)
%
% OUTPUT:
% FileType: type of file
% FileInfo: structure containing info on the file (case of images)
% Object: in case of video
%
% INPUT:
% fileinput: name, including path, of the file to analyse
function [FileType,FileInfo,Object]=get_file_type(fileinput)
FileType='';
FileInfo=[];
Object=[];
[tild,tild,FileExt]=fileparts(fileinput);

switch FileExt
    case {'.civ','.log','.cmx','.cmx2','.txt','.bat'}
        FileType='txt';
    case '.fig'
        FileType='figure';
    case '.xml'
        FileType='xml';
    case '.xls'
        FileType='xls';
    otherwise
        if ~isempty(FileExt)&& ~isempty(imformats(FileExt(2:end)))
            try
                FileType='image';
                imainfo=imfinfo(fileinput);
                if length(imainfo) >1 %case of image with multiple frames
                    FileType='multimage';
                    FileInfo.NbFrame=length(imainfo);
                end
            end
        else
            try
                Data=nc2struct(fileinput,'ListGlobalAttribute','absolut_time_T0','Conventions',...
                    'CivStage','patch2','fix2','civ2','patch','fix');
                if ~isempty(Data.absolut_time_T0')
                    FileType='civx'; % test for civx velocity fields
                    if ~isempty(Data.patch2) && isequal(Data.patch2,1)
                        FileInfo.CivStage=6;
                    elseif ~isempty(Data.fix2) && isequal(Data.fix2,1)
                        FileInfo.CivStage=5;
                    elseif ~isempty(Data.civ2) && isequal(Data.civ2,1);
                        FileInfo.CivStage=4;
                    elseif ~isempty(Data.patch) && isequal(Data.patch,1);
                        FileInfo.CivStage=3;
                    elseif ~isempty(Data.fix) && isequal(Data.fix,1);
                        FileInfo.CivStage=2;
                    elseif ~isempty(Data.absolut_time_T0) && ~isempty(Data.hart)
                        FileInfo.CivStage=1;
                    end
                elseif strcmp(Data.Conventions,'uvmat/civdata')
                    FileType='civdata'; % test for civx velocity fields
                    FileInfo.CivStage=Data.CivStage;
                else
                    FileType='netcdf';
                end
            end
            try
                if exist('VideoReader','file')%recent version of Matlab
                    Object=VideoReader(fullfileinput);
                else
                    Object=mmreader(fullfileinput);%older Matlab function for movies
                end
                FileType='video';
                FileInfo.NbFrame=get(Object,'NumberOfFrames');
            end
        end
end