% 'avi2png': copy an avi movie to a series of B/W .png images (take the average of green and blue color components)
%----------------------------------------------------------------------
function GUI_input=avi2png(num_i1,num_i2,num_j1,num_j2,Series)
%% INPUT PARAMETERS (to edit)
increment=4% frame increment: the frequency of the png images will be (initial frequency)/increment.
colorweight=[0 0.5 0.5]; % relative weight of color components [r g b] for the resulting B/W image
colorweight=colorweight/sum(colorweight)

%% default output (set the input options in the GUI series)
if ~exist('num_i1','var')
    GUI_input={};
        return
end
hh=guidata(Series.hseries);
set(hh.incr_i,'String',num2str(increment))% preset the increment in the GUI

%% set file names
nbfield=length(num_i1);
aviname=fullfile(Series.RootPath,[Series.RootFile Series.FileExt]);
rootname=fullfile(Series.RootPath,Series.RootFile);
if ~exist(rootname,'dir')
    mkdir(rootname)% will put the extracted images in a subdirectory with the same lname as the avi file (without extension)
end
basename=fullfile(rootname,'frame');

%% enable waitbar and stop buttons on the series interface:
hRUN=findobj(Series.hseries,'Tag','RUN');% handle of the RUN button
hwaitbar=findobj(Series.hseries,'Tag','waitbar');%handle of the waitbar
waitbarpos(1)=Series.WaitbarPos(1);%x position of the waitbar
waitbarpos(3)=Series.WaitbarPos(3);% width of the waitbar

%% read the movie object
if isequal(lower(Series.FileExt),'.avi')
    display('opening the avi movie ...')
    hhh=which('mmreader');%look for the existence of 'mmreader'for movie reading
    if ~isequal(hhh,'')&& mmreader.isPlatformSupported()
        MovieObject=mmreader(aviname);
        FileType='movie';
    else
        FileType='avi';
    end
end

%% main loop on frames
for ifile=1:nbfield
     stopstate=get(hRUN,'BusyAction');
     if isequal(stopstate,'queue')% if STOP command is not activated
        waitbarpos(4)=(ifile/nbfield)*Series.WaitbarPos(4);
        waitbarpos(2)=Series.WaitbarPos(4)+Series.WaitbarPos(2)-waitbarpos(4);
        set(hwaitbar,'Position',waitbarpos)%update waitbar on the series interface
        drawnow
        A=read_image(aviname,'movie',num_i1(ifile),MovieObject);
        if ndims(A)==3% convert color image to B/W
            A=double(A);
            A=colorweight(1)*A(:,:,1)+colorweight(2)*A(:,:,2)+colorweight(3)*A(:,:,3);
            A=uint8(A);% transform to 8 bit integers
        end
        new_index=1+floor((num_i1(ifile)-num_i1(1))/increment);
        filename=[basename '_' num2str(new_index) '.png'];%create image name
        imwrite(A,filename,'BitDepth',8);%write image
        display(['new frame '  num2str(new_index) ' written as png image'])
     end
end

%% create xml file with timing: 
info=aviinfo(aviname);
t=xmltree;
t=set(t,1,'name','ImaDoc');
[t,uid]=add(t,1,'element','Heading');
% A AJOUTER
% Heading.Project='';
Heading.ImageName='frame_1.png';
t=struct2xml(Heading,t,uid);
[t,uid]=add(t,1,'element','Camera');
Camera.TimeUnit='s';
% Camera.BurstTiming.FrameFrequency=info.FramesPerSecond/increment;
Camera.BurstTiming.Dti=increment/info.FramesPerSecond;
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

