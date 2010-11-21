%----------------------------------------------------------------------
% --- substract background to the images: rank the images by luminosity at each point and substracts to the images
%----------------------------------------------------------------------
% Method: 
    %calculate the background image by sorting the luminosity of each point
    % over a sliding sub-sequence of 'nbaver_ima' images. 
    % The luminosity value of rank 'rank' is selected as the
    % 'background'. rank=nbimages/2 gives the median value.  Smaller values are appropriate
    % for a dense set of particles. The extrem value rank=1 gives the true minimum
    % luminosity, but it can be polluted by noise. 
% Organization of image indices:
    % The program is working on a series of images, labelled by two indices i and j, given 
    % by the input matlab vectors num_i1 and num_j1 respectively. In the list, j is the fastest increasing index.
    % The processing can be done in slices (number nbslice), with bursts of
    % nbfield2 successive images for a given slice (mode 'multilevel')
    % In the mode 'volume', nbfield2=1 (1 image at each level), and
    % nbslice=
%INPUT:
% num_i1: matrix of image indices i
% num_j1: matrix of image indices j, must be the same size as num_i1
% num_i2 and num_j2: not used for a function acting on images
% Series: matlab structure containing parameters, as defined by the interface UVMAT/series
%       Series.RootPath: path to the image series
%       Series.RootFile: root file name
%       Series.FileExt: image file extension 
%       Series.NomType: nomenclature type for file indexing
%       Series.NbSlice: %number of slices defined on the interface

function GUI_input=sub_background (num_i1,num_i2,num_j1,num_j2,Series)

%------------------------------------------------------------------------
%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
    GUI_input={'RootPath';'on';...
        'SubDir';'off';... % subdirectory of derived files (PIV fields), ('on' by default)
        'RootFile';'on';... %root input file name ('on' by default)
        'FileExt';'on';... %inputf file extension ('on' by default)
        'NomType';'on';...%type of file indexing ('on' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        %'VelTypeMenu';'on';...% menu for selecting the velocity type (civ1,..)('off' by default)
        %'FieldMenu';'on';...% menu for selecting the velocity field (s) in the input file ('off' by default)
        %'VelTypeMenu_1';'on';...% menu for selecting the velocity type (civ1,..)('off' by default)
        %'FieldMenu_1';'on';...% menu for selecting the velocity field (s) in the input file ('off' by default)
        %'CoordType';...%can use a transform function
        %'GetObject';...;%can use projection object
        %'GetMask';...;%can use mask option  
        'PARAMETER';'NbSliding';...
        'PARAMETER';'VolumeScan';...
        'PARAMETER';'RankBrightness';...
               ''};
    return %exit the function 
end

%----------------------------------------------------------------
% initiate the waitbar
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position');
%-----------------------------------------------------------------
if iscell(Series.RootPath)
    msgbox_uvmat('ERROR','This function use only one input image series')
    return
end

%determine input image type
FileType=[];%default
MovieObject=[];
FileExt=Series.FileExt;

if isequal(lower(FileExt),'.avi')
    hhh=which('mmreader');
    if ~isequal(hhh,'')&& mmreader.isPlatformSupported()
        MovieObject=mmreader(fullfile(RootPath,[RootFile FileExt]));
        FileType='movie';
    else
        FileType='avi';
    end
elseif isequal(lower(FileExt),'.vol')
    FileType='vol';
else 
   form=imformats(FileExt(2:end));
   if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
       if isequal(Series.NomType,'*');
           FileType='multimage';
       else
           FileType='image';
       end
   end
end
if isempty(FileType)
    msgbox_uvmat('ERROR',['invalid file extension ' FileExt ': this function only accepts image or movie input'])
    return
end

nbslice_i=Series.NbSlice; %number of slices 
siz=size(num_i1);
nbaver_init=23;%approximate number of images used for the sliding background: to be adjusted later to include an integer number of bursts

%adjust the proposed number of images in the sliding average to include an integer number of bursts
if siz(2)~=1
    nbaver=floor(nbaver_init/siz(1)); % number of bursts used for the sliding background, 
    if isequal(floor(nbaver/2),nbaver)
        nbaver=nbaver+1;%put the number of burst to an odd number (so the middle burst is defined)
    end
    nbaver_init=nbaver*siz(1);%propose by default an integer number of bursts
end

filebase=fullfile(Series.RootPath,Series.RootFile);
dir_images=Series.RootPath;
nom_type=Series.NomType;

%create dir of the new images
[dir_images,namebase]=fileparts(filebase);
[path,subdir_ima]=fileparts(dir_images);
curdir=pwd;
cd(path);
mkdir([subdir_ima '_b']);
[xx,msg2] = fileattrib(subdir_ima,'+w','g'); %yield writing access (+w) to user group (g)
if ~strcmp(msg2,'')
    msgbox_uvmat('ERROR',['pb of permission for ' subdir_ima ': ' msg2])%error message for directory creation
    cd(curdir)
    return
end
cd(curdir);
filebase_b=fullfile(path,[subdir_ima '_b'],namebase);

prompt = {'Number of images for the sliding background';'The number of positions (laser slices)';'volume scan mode (Yes/No)';...
        'the luminosity rank chosen to define the background (0.1=for dense particle seeding, 0.5 (median) for sparse particles'};
dlg_title = ['get (slice by slice) a sliding background and substract to each image, result in subdir ' subdir_ima '_b'];
num_lines= 3;
def     = { num2str(nbaver_init);num2str(nbslice_i);'No';'0.1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
set(hseries.ParamVal,'String',answer([1 [3:4]]))
set(hseries.ParamVal,'Visible','on')

nbaver_ima=str2num(answer{1});%number of images for the sliding background
nbaver=ceil(nbaver_ima/siz(1))%number of bursts for the sliding background
if isequal(floor(nbaver/2),nbaver)
   nbaver=nbaver+1%put the number of burst to an odd number (so the middle burst is defined)
end
% if isequal(nbaver,round(nbaver))
step=siz(1);%case of bursts: the sliding background is shifted by one burst 
% else
%    step=1;
% end
vol_test=answer{3};
if isequal(vol_test,'Yes')
    nbfield2=1;%case of volume: no consecutive series at a given level
    nbslice_i=siz(1);%number of slices 
else
    nbfield2=siz(1); %nb of consecutive images at each level(burst)
    if siz(2)>1
       nbslice_i=str2num(answer{2})/(num_i1(1,2)-num_i1(1,1));% number of slices
    else
        nbslice_i=1;
    end
    if ~isequal(floor(nbslice_i),nbslice_i)
        msgbox_uvmat('ERROR','the number of slices must be a multiple of the i increment')
        return
    end
end
% nbaver=floor(nbaver_init/nbfield2); % number of bursts used for the sliding background, 
% if isequal(floor(nbaver/2),nbaver)
%     nbaver=nbaver+1;%put the number of burst to an odd number 
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nbaver_ima=nbaver*nbfield2;% adjust the number of sliding images A  REMETRE
% if ~isequal(nbaver_ima,nbaver_init)
%     hwarn=warndlg(['number of images in the sliding average adjusted to ' num2str(nbaver_ima)]);
%     set(hwarn,'Units','normalized')
%     set(hwarn,'Position',[0.3 0.3 0.4 0.1])
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rank=floor(str2num(answer{4})*nbaver_ima);
if rank==0
    rank=1;%rank selected in the sorted image series
end
lengthtot=siz(1)*siz(2);
nbfield=floor(lengthtot/(nbfield2*nbslice_i));%total number of i indexes (adjusted to an integer number of slices)
nbfield_slice=nbfield*nbfield2;% number of fields per slice
% test_plot=isequal(answer{5},'Yes'); %=1 to display background images
if nbaver_ima > nbfield*nbfield2
    errordlg('number of images in a slice smaller than the proposed number of images for the sliding average')
    return
end
nbfirst=(ceil(nbaver/2))*step;
if nbfirst>nbaver_ima
    nbfirst=ceil(nbaver_ima/2)
    step=1;
    nbaver=nbaver_ima;
end

%copy the xml file
if exist([filebase '.xml'],'file')
    copyfile([filebase '.xml'],[filebase_b '.xml']);% copy the .civ file
    t=xmltree([filebase_b '.xml']);
    
    %update information on the first image name in the series
    uid_Heading=find(t,'ImaDoc/Heading');
    if isempty(uid_Heading)
        [t,uid_Heading]=add(t,1,'element','Heading');
    end   
    uid_ImageName=find(t,'ImaDoc/Heading/ImageName');
    ImageName=name_generator(filebase_b,num_i1(1),num_j1(1),'.png',Series.NomType);
    [pth,ImageName]=fileparts(ImageName);
    ImageName=[ImageName '.png']
    if isempty(uid_ImageName)
       [t,uid_ImageName]=add(t,uid_Heading,'element','ImageName');
    end
    uid_value=children(t,uid_ImageName);
    if isempty(uid_value)
        t=add(t,uid_ImageName,'chardata',ImageName)%indicate  name of the first image, with ;png extension
    else
        t=set(t,uid_value(1),'value',ImageName)%indicate  name of the first image, with ;png extension
    end  

    %add information about image transform
    [t,new_uid]=add(t,1,'element','ImageTransform');
    [t,NameFunction_uid]=add(t,new_uid,'element','NameFunction');
    [t]=add(t,NameFunction_uid,'chardata','sub_background');      
    [t,NbSlice_uid]=add(t,new_uid,'element','NbSlice');
    [t]=add(t,new_uid,'chardata',num2str(nbslice_i));
    [t,NbSlidingImages_uid]=add(t,new_uid,'element','NbSlidingImages');
    [t]=add(t,NbSlidingImages_uid,'chardata',num2str(nbaver));
    [t,LuminosityRank_uid]=add(t,new_uid,'element','RankBackground');
    [t]=add(t,LuminosityRank_uid,'chardata',num2str(rank));% luminosity rank almong the nbaver sliding images 
    save(t,[filebase_b '.xml'])
elseif exist([filebase '.civ'],'file')
    copyfile([filebase '.civ'],[filebase_b '.civ']);% copy the .civ file
end
%copy the mask
if exist([filebase '_1mask_1'],'file')
     copyfile([filebase '_1mask_1'],[filebase_b '_1mask_1']);% copy the mask file
end

%MAIN LOOP ON SLICES
for islice=1:nbslice_i
    %select the series of image indices at the level islice
    for ifield=1:nbfield
        for iburst=1:nbfield2
            indselect(iburst,ifield)=((ifield-1)*nbslice_i+(islice-1))*nbfield2+iburst;
        end
    end  
    %read the first series of nbaver_ima images and sort by luminosity at each pixel
    for ifield = 1:nbaver_ima
        ifile=indselect(ifield);
        filename=name_generator(filebase,num_i1(ifile),num_j1(ifile),Series.FileExt,Series.NomType);
        Aread=read_image(filename,FileType,num_i1(ifile),MovieObject);
        Ak(:,:,ifield)=Aread;           
    end
    Asort=sort(Ak,3);%sort the luminosity of images at each point
    B=Asort(:,:,rank);%background image
% 
%     namemean=name_generator([filebase '_back'],islice,[],'.png','_i');% makes the file name
%     imwrite(B,namemean,'BitDepth',16); % save the first background image
%     ['background image for slice ' num2str(islice) ' saved in ' namemean]
    %substract the background from each of the first images and save the new images
%     for ifield=1:floor(nbaver_ima/2)+1 
    'first background image will be substracted'

    for ifield=1:nbfirst
            Acor=double(Ak(:,:,ifield))-double(B);%substract background to the current image
            Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
            C=uint16(Acor);% set to integer 16 bits
            ifile=indselect(ifield);
            newname=name_generator(filebase_b,num_i1(ifile),num_j1(ifile),'.png',nom_type)% makes the new file name
            imwrite(C,newname,'BitDepth',16); % save the new image
    end
    %repeat the operation on a sliding series of nbaver*nbfield2 images
    'sliding background image will be substracted'
    if nbfield_slice > nbaver_ima
%         for ifield = floor(nbaver_ima/2)+2:step:nbfield_slice-floor(nbaver_ima/2)
        for ifield = step*ceil(nbaver/2)+1:step:nbfield_slice-step*floor(nbaver/2)
            stopstate=get(hseries.RUN,'BusyAction');
            if isequal(stopstate,'queue')% enable STOP command
                update_waitbar(hseries.waitbar,WaitbarPos,(ifield+(islice-1)*nbfield_slice)/(nbfield_slice*nbslice_i))
                (ifield+(islice-1)*nbfield_slice)/(nbfield_slice*nbslice_i)
                Ak(:,:,[1:nbaver_ima-step])=Ak(:,:,[1+step:nbaver_ima]);% shift the current image series by one burst (step)
                %incorporate next burst in the current image series
                for iburst=1:step
                    ifile=indselect(ifield+step*floor(nbaver/2)+iburst-1);
                    filename=name_generator(filebase,num_i1(ifile),num_j1(ifile),Series.FileExt,Series.NomType);
                    Aread=read_image(filename,FileType,num_i1(ifile),MovieObject);
                    Ak(:,:,nbaver_ima-step+iburst)=Aread;
                end
                Asort=sort(Ak,3);%sort the new current image series by luminosity
                B=Asort(:,:,rank);%current background image
                for iburst=1:step
%                     Acor=double(Ak(:,:,floor(nbaver_ima/2)+iburst-1))-double(B);
                    index=step*floor(nbaver/2)+iburst;
                    Acor=double(Ak(:,:,index))-double(B);
                    Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
                    C=uint16(Acor);
                    ifile=indselect(ifield+iburst-1);
                    [newname]=...
                       name_generator(filebase_b,num_i1(ifile),num_j1(ifile),'.png',Series.NomType)
%                     newname=name_generator(filebase_b,num_i1(indselect(ifield+iburst-1)),num_j1(indselect(ifield+iburst-1)),'.png',nom_type)% makes the new file name
                    imwrite(C,newname,'BitDepth',16); % save the new image
                end  
            else
                return
            end
        end
    end

%substract the background from the last images
%     for ifield=nbfield_slice-floor(nbaver_ima/2)+1:nbfield_slice
     'last background image will be substracted'
     ifield=nbfield_slice-(step*ceil(nbaver/2))+1:nbfield_slice;
    for ifield=nbfield_slice-(step*floor(nbaver/2))+1:nbfield_slice  
        index=ifield-nbfield_slice+step*(2*floor(nbaver/2)+1);
        Acor=double(Ak(:,:,index))-double(B);
        Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
        C=uint16(Acor);
        ifile=indselect(ifield);
        newname=name_generator(filebase_b,num_i1(ifile),num_j1(ifile),'.png',nom_type)% makes the new file name
        imwrite(C,newname,'BitDepth',16); % save the new image
    end
end

%finish the waitbar
update_waitbar(hseries.waitbar,WaitbarPos,1)


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
    A=sum(double(A),3);
end
    
