%--read images or video objects
function [A,ParamOut]=read_image(FileName,FileType,VideoObject,num)
%------------------------------------------------------------------------
%num is the view number needed for an avi movie
ParamOut=VideoObject;%default
switch FileType
         case 'video'
            if strcmp(class(VideoObject),'VideoReader')
                A=read(VideoObject,num);
            else
                ParamOut=VideoReader(FileName);
                A=read(ParamOut,num);
            end
        case 'mmreader'
            if strcmp(class(VideoObject),'mmreader')
                A=read(VideoObject,num);
            else
                ParamOut=mmreader(FileName);
                A=read(ParamOut,num);
            end
    case 'multimage'
        A=imread(FileName,num);
    case 'image'    
        A=imread(FileName);
end
