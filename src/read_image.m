%--read images or video objects
function A=read_image(FileName,FileType,VideoObject,num)
%------------------------------------------------------------------------
%num is the view number needed for an avi movie
switch FileType
    case {'video','mmreader'}
        A=read(VideoObject,num);
    case 'multimage'
        A=imread(FileName,num);
    case 'image'    
        A=imread(FileName);
end
