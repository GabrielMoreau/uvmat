% 'avi2png': copy an avi movie to a series of B/W .png images (take the average of green and blue color components)
%----------------------------------------------------------------------
function GUI_input=avi2png(num_i1,num_i2,num_j1,num_j2,Series)

if ~exist('num_i1','var')
    GUI_input={};
        return
end
hh=guidata(Series.hseries);
increment=4;
set(hh.incr_i,'String',num2str(increment))
nbfield=length(num_i1);
% basename=[fullfile(Series.RootPath,Series.RootFile) ];
aviname=fullfile(Series.RootPath,[Series.RootFile Series.FileExt]);
rootname=fullfile(Series.RootPath,Series.RootFile);
if ~exist(rootname,'dir')
    mkdir(rootname)% will put the extracted images in a subdirectory with the same lname as the avi file (without extension)
end
basename=fullfile(rootname,'frame');

%enable waitbar and stop buttons on the series interface:
hRUN=findobj(Series.hseries,'Tag','RUN');% handle of the RUN button
hwaitbar=findobj(Series.hseries,'Tag','waitbar');%handle of the waitbar
waitbarpos(1)=Series.WaitbarPos(1);%x position of the waitbar
waitbarpos(3)=Series.WaitbarPos(3);% width of the waitbar

if isequal(lower(Series.FileExt),'.avi')
    hhh=which('mmreader');%look for the existence of 'mmreader'for movie reading
    if ~isequal(hhh,'')&& mmreader.isPlatformSupported()
        MovieObject=mmreader(aviname);
        FileType='movie';
    else
        FileType='avi';
    end
end
%main loop
for ifile=1:nbfield
     stopstate=get(hRUN,'BusyAction');
     if isequal(stopstate,'queue')% if STOP command is not activated
        waitbarpos(4)=(ifile/nbfield)*Series.WaitbarPos(4);
        waitbarpos(2)=Series.WaitbarPos(4)+Series.WaitbarPos(2)-waitbarpos(4);
        set(hwaitbar,'Position',waitbarpos)%update waitbar on the series interface
        drawnow
        D=read_image(aviname,'movie',num_i1(ifile),MovieObject);
        C=uint8(D);% transform to 8 bit integers
        new_index=1+floor((num_i1(ifile)-num_i1(1))/increment);
        filename=[basename '_' num2str(new_index) '.png'];%create image name
        imwrite(C,filename,'BitDepth',8);%write image
     end
end

%create xml file with timing: 
info=aviinfo(aviname);
t=xmltree;
t=set(t,1,'name','ImaDoc');
[t,uid]=add(t,1,'element','Heading');
% A AJOUTER
% Heading.Project='';
Heading.ImageName=[Series.RootFile '_' num2str(num_i1(1)) '.png'];
t=struct2xml(Heading,t,uid);
[t,uid]=add(t,1,'element','Camera');
Camera.TimeUnit='s';
Camera.BurstTiming.FrameFrequency=info.FramesPerSecond/increment;
Camera.BurstTiming.Dti=1;
Camera.BurstTiming.NbDti=numel(num_i1)-1;
Camera.BurstTiming.Time=(num_i1(1)-1)/info.FramesPerSecond;%time of the first frame of the avi movie
t=struct2xml(Camera,t,uid);
save(t,[basename '.xml'])

%------------------------------------------------------------------------
%--read images and convert them to the uint16 format used for PIV
function A=read_image(filename,type_ima,num,MovieObject)
%------------------------------------------------------------------------
%num is the view number needed for an avi movie
switch type_ima
    case 'movie'
        A=read(MovieObject,num);
    case 'avi'
        mov=aviread(filename,num);
        A=frame2im(mov(1));
    case 'multimage'
        A=imread(filename,num);
    case 'image'    
        A=imread(filename);
end
siz=size(A);
if length(siz)==3;%color images
    A=sum(double(A(:,:,2:3)),3)/2;% average green and blue components
end
