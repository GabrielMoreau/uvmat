%'read_image': reads an image from a single file or a movie file
function [A,error]=read_image(filename,NomType,num);
 %read  images in different formats. 
A=[]; %default
error=0; %default
if ~exist(filename,'file')
    error='input file not found in read_image'
    return
end
testframe=0;
if ~exist('NomType','var')
    NomType=[];
end
if ~exist('num','var')
    num=1;
end
[pth,fl,ext]=fileparts(filename);
if isequal(lower(ext),'.avi')
    mov=aviread(filename,num);
    A=frame2im(mov(1));
elseif isequal(lower(ext),'.vol')
     A=imread(filename);
else
     form=imformats(ext([2:end]));
     if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
         if isequal(NomType,'*');
            A=imread(filename,num);
         else 
           A=imread(filename);  
         end
     else
         error=['ERROR in read_image: file extension not recognized by matlab as image'];
         return
     end
end
 
