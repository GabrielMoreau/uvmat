%'sub_background': substract background to an image series, used with series.fig
%------------------------------------------------------------------------
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
    % In the mode 'volume', nbfield2=1 (1 image at each level)
    
% function GUI_input=sub_background(Param)
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% In the absence of input (as activated when the current Action is selected
% in series), the function ouput GUI_input set the activation of the needed GUI elements
%
% Param contains the elements:(use the menu bar command 'export/GUI config' in series to see the current structure Param)
%    .InputTable: cell of input file names, (several lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDir: directory for data outputs, including path
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%    .IndexRange: set the file or frame indices on which the action must be performed
%    .FieldTransform: .TransformName: name of the selected transform function
%                     .TransformPath:   path  of the selected transform function
%                     .TransformHandle: corresponding function handle
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%    .ProjObject: %sub structure describing a projection object (read from ancillary GUI set_object)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
function GUI_input=sub_background (Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if ~exist('Param','var') % case with no input parameter 
    GUI_input={'NbViewMax';1;...% max nbre of input file series (default='' , no limitation)
        'AllowInputSort';'off';...% allow alphabetic sorting of the list of input files (options 'off'/'on', 'off' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelType';'off';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
        'FieldName';'off';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'FieldTransform'; 'off';...%can use a transform function
        'ProjObject';'off';...%can use projection object(option 'off'/'on',
        'Mask';'off';...%can use mask option   (option 'off'/'on', 'off' by default)
        'OutputDirExt';'.sbk';...%set the output dir extension
               ''};
        return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
%% get input parameters, file names and indices
% BATCH  case: read the xml file for batch case
if ischar(Param) && ~isempty(find(regexp(Param,'.xml$')))
    Param=xml2struct(Param);
    checkrun=0;
% RUN case: parameters introduced as the input structure Param  
else 
    hseries=guidata(Param.hseries);%handles of the GUI series
    WaitbarPos=get(hseries.waitbar_frame,'Position');%position of the waitbar on the GUI series
    checkrun=1; % indicate the RUN option is used
end
% get the set of input file names (cell array filecell), and the lists of
% input file or frame indices i1_series,i2_series,j1_series,j2_series
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% filecell{iview,fileindex}: cell array representing the list of file names
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
% set of frame indices used for movie or multimage input 
if ~isempty(j1_series)
    frame_index=j1_series;
else
    frame_index=i1_series;
end

%% root input file(s) and type
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);

% numbers of slices and file indices
NbSlice=1;%default
if isfield(Param.IndexRange,'NbSlice')
    NbSlice=Param.IndexRange.NbSlice;
end
nbview=size(i1_series,1);%number of input file series (lines in InputTable)
nbfield_j=size(i1_series,2); %nb of consecutive fields at each level(burst
nbfield=nbfield_j*size(i1_series,3); %total number of files or frames
nbfield_i=floor(nbfield/NbSlice);%total number of i indexes (adjusted to an integer number of slices)
nbfield=nbfield_i*nbfield_j; %total number of fields after adjustement

%determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video'};
NcTypeOptions={'netcdf','civx','civdata'};
    
% % for iview=1:nbview
%     if ~exist(filecell{iview,1}','file')
%         msgbox_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'])
%         return
%     end
%     [FileType{iview},FileInfo{iview},Object{iview}]=get_file_type(filecell{iview,1});
%     CheckImage{iview}=~isempty(find(strcmp(FileType{iview},ImageTypeOptions)));% =1 for images
%     CheckNc{iview}=~isempty(find(strcmp(FileType{iview},NcTypeOptions)));% =1 for netcdf files
% end

[FileType,FileInfo,MovieObject]=get_file_type(filecell{1,1});
CheckImage=~isempty(find(strcmp(FileType,ImageTypeOptions)));% =1 for images

%% calibration data and timing: read the ImaDoc files
%not relevant here

%% check coincidence in time for several input file series
%not relevant here

%% coordinate transform or other user defined transform
%not relevant here

%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE

 %% check the validity of  input file types
if CheckImage
    FileExtOut='.png'; % write result as .png images for image inputs
    NomTypeOut='_1_1';
else 
    msgbox_uvmat('ERROR',['invalid file type input: ' FileType{1} ' not an image'])
    return
end
% 
% NomTypeOut='_1-2_1';% output file index will indicate the first and last ref index in the series
% if NbSlice~=nbfield_j
%     answer=msgbox_uvmat('INPUT_Y-N',['will not average slice by slice: for so cancel and set NbSlice= ' num2str(nbfield_j)]);
%     if ~strcmp(answer,'Yes')
%         return
%     end
% end

%% Set field names and velocity types
%not relevant here


%% Initiate output fields
%not relevant here
 
%%% SPECIFIC PART BEGINS HERE
NbSlice=Param.IndexRange.NbSlice; %number of slices
siz=size(i1_series);
nbaver_init=23;%approximate number of images used for the sliding background: to be adjusted later to include an integer number of bursts
j1=[];%default

%% apply the image rescaling function 'level' (avoid the blinking effects of bright particles)
answer=msgbox_uvmat('INPUT_Y-N','apply image rescaling function levels.m after sub_background');
test_level=isequal(answer,'Yes');

%% adjust the proposed number of images in the sliding average to include an integer number of bursts
if siz(3)~=1
    nbaver=floor(nbaver_init/siz(2)); % number of bursts used for the sliding background,
    if isequal(floor(nbaver/2),nbaver)
        nbaver=nbaver+1;%put the number of burst to an odd number (so the middle burst is defined)
    end
    nbaver_init=nbaver*siz(2);%propose by default an integer number of bursts
end

%% set processing parameters
prompt = {'Number of images for the sliding background (MUST FIT IN COMPUETER MEMORY)';'The number of positions (laser slices)';'volume scan mode (Yes/No)';...
    'the luminosity rank chosen to define the background (0.1=for dense particle seeding, 0.5 (median) for sparse particles'};
dlg_title = ['get (slice by slice) a sliding background and substract to each image, result in subdir ' Param.OutputDir];
num_lines= 3;
def     = { num2str(nbaver_init);num2str(NbSlice);'No';'0.1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
set(hseries.ParamVal,'String',answer([1 [3:4]]))
set(hseries.ParamVal,'Visible','on')

nbaver_ima=str2num(answer{1});%number of images for the sliding background
nbaver=ceil(nbaver_ima/siz(2));%number of bursts for the sliding background
if isequal(floor(nbaver/2),nbaver)
    nbaver=nbaver+1;%put the number of burst to an odd number (so the middle burst is defined)
end
step=siz(2);%case of bursts: the sliding background is shifted by one burst
vol_test=answer{3};
if isequal(vol_test,'Yes')
    nbfield2=1;%case of volume: no consecutive series at a given level
    NbSlice=siz(2);%number of slices
else
    nbfield2=siz(2); %nb of consecutive images at each level(burst)
    if siz(3)>1
        % NbSlice=str2num(answer{2})/(num_i1(1,2)-num_i1(1,1));% number of slices
        NbSlice=str2num(answer{2})/(i1_series(1,1,2)-i1_series(1,1,1));% number of slices
    else
        NbSlice=1;
    end
    if ~isequal(floor(NbSlice),NbSlice)
        msgbox_uvmat('ERROR','the number of slices must be a multiple of the i increment')
        return
    end
end
rank=floor(str2num(answer{4})*nbaver_ima);
if rank==0
    rank=1;%rank selected in the sorted image series
end
lengthtot=siz(2)*siz(3);
nbfield=floor(lengthtot/(nbfield2*NbSlice));%total number of i indexes (adjusted to an integer number of slices)
nbfield_slice=nbfield*nbfield2;% number of fields per slice
if nbaver_ima > nbfield*nbfield2
    msgbox_uvmat('ERROR','number of images in a slice smaller than the proposed number of images for the sliding average')
    return
end
nbfirst=(ceil(nbaver/2))*step;
if nbfirst>nbaver_ima
    nbfirst=ceil(nbaver_ima/2);
    step=1;
    nbaver=nbaver_ima;
end

%% prealocate memory for the sliding background
Afirst=read_image(filecell{1,1},FileType{1},MovieObject,i1_series(1,1));
[npy,npx]=size(Afirst);
try
    Ak=zeros(npy,npx,nbaver_ima,'uint16'); %prealocate memory
    Asort=zeros(npy,npx,nbaver_ima,'uint16'); %prealocate memory
catch ME
    msgbox_uvmat('ERROR',ME.message)
    return
end

%% update the xml file
SubDirBase=regexprep(Param.InputTable{1,2},'\..*','');%take the root part of SubDir, before the first dot '.'
filexml=fullfile(RootPath{1},[SubDirBase '.xml']);
if ~exist(filexml,'file') && exist([filebase '.xml'],'file')% xml inside the image directory
    copyfile([filebase '.xml'],filexml);% copy the .xml file
end
if exist(filexml,'file')
    t=xmltree(filexml);  
    %update information on the first image name in the series
    uid_Heading=find(t,'ImaDoc/Heading');
    if isempty(uid_Heading)
        [t,uid_Heading]=add(t,1,'element','Heading');
    end
    uid_ImageName=find(t,'ImaDoc/Heading/ImageName');
    if ~isempty(j1_series{1})
        j1=j1_series{1}(1);
    end
    ImageName=fullfile_uvmat([dir_images term],'',RootFile{1},'.png',NomType,i1_series(1,1),[],j1);
    [pth,ImageName]=fileparts(ImageName);
    ImageName=[ImageName '.png'];
    if isempty(uid_ImageName)
        [t,uid_ImageName]=add(t,uid_Heading,'element','ImageName');
    end
    uid_value=children(t,uid_ImageName);
    if isempty(uid_value)
        t=add(t,uid_ImageName,'chardata',ImageName);%indicate  name of the first image, with ;png extension
    else
        t=set(t,uid_value(1),'value',ImageName);%indicate  name of the first image, with ;png extension
    end
    
    %add information about image transform
    [t,new_uid]=add(t,1,'element','ImageTransform');
    [t,NameFunction_uid]=add(t,new_uid,'element','NameFunction');
    [t]=add(t,NameFunction_uid,'chardata','sub_background');
    if test_level
        [t,NameFunction_uid]=add(t,new_uid,'element','NameFunction');
        [t]=add(t,NameFunction_uid,'chardata','levels');
    end
    [t,NbSlice_uid]=add(t,new_uid,'element','NbSlice');
    [t]=add(t,new_uid,'chardata',num2str(NbSlice));
    [t,NbSlidingImages_uid]=add(t,new_uid,'element','NbSlidingImages');
    [t]=add(t,NbSlidingImages_uid,'chardata',num2str(nbaver));
    [t,LuminosityRank_uid]=add(t,new_uid,'element','RankBackground');
    [t]=add(t,LuminosityRank_uid,'chardata',num2str(rank));% luminosity rank almong the nbaver sliding images
    save(t,filexml)
end
%copy the mask
% if exist([filebase '_1mask_1'],'file')
%     copyfile([filebase '_1mask_1'],[filebase_b '_1mask_1']);% copy the mask file
% end

%MAIN LOOP ON SLICES
for islice=1:NbSlice
    %% select the series of image indices at the level islice
    for ifield=1:nbfield
        for iburst=1:nbfield2
            indselect(iburst,ifield)=((ifield-1)*NbSlice+(islice-1))*nbfield2+iburst;
        end
    end
    
    %% read the first series of nbaver_ima images and sort by luminosity at each pixel
    for ifield = 1:nbaver_ima
        ifile=indselect(ifield);
        filename=filecell{1,ifile};
        Aread=read_image(filename,FileType,MovieObject,i1_series{1}(ifile));
        Ak(:,:,ifield)=Aread;
    end
    Asort=sort(Ak,3);%sort the luminosity of images at each point
    B=Asort(:,:,rank);%background image
    display( 'first background image will be substracted')
    for ifield=1:nbfirst
        Acor=double(Ak(:,:,ifield))-double(B);%substract background to the current image
        Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
        C=uint16(Acor);% set to integer 16 bits
        ifile=indselect(ifield);
        %             newname=name_generator(filebase_b,num_i1(ifile),num_j1(ifile),'.png',NomType)% makes the new file name
        if ~isempty(j1_series{1})
            j1=j1_series{1}(ifile);
        end
        newname=fullfile_uvmat(RootPath{1},Param.OutputSubDir,RootFile{1},FileExtOut,NomTypeOut,i1_series(1,ifile),[],i_slice,[]);
%         newname=fullfile_uvmat(RootPath{1},SubdirResult,RootFile{1},'.png',NomType,i1_series{1}(ifile),[],j1);
        %newname=name_generator(filebase_b,i1_series{1}(ifile),j1_series{1}(ifile),'.png',NomType);% makes the new file name
        if test_level
            C=levels(C);
            imwrite(C,newname,'BitDepth',8); % save the new image
        else
            imwrite(C,newname,'BitDepth',16); % save the new image
        end
    end
    
    %% repeat the operation on a sliding series of nbaver*nbfield2 images
    display('sliding background image will be substracted')
    if nbfield_slice > nbaver_ima
        for ifield = step*ceil(nbaver/2)+1:step:nbfield_slice-step*floor(nbaver/2)
            if checkrun
                stopstate=get(hseries.RUN,'BusyAction');
                update_waitbar(hseries.waitbar_frame,WaitbarPos,(ifield+(islice-1)*nbfield_slice)/(nbfield_slice*NbSlice))
            else
                stopstate='queue';
            end
            if isequal(stopstate,'queue')% enable STOP command
                Ak(:,:,1:nbaver_ima-step)=Ak(:,:,1+step:nbaver_ima);% shift the current image series by one burst (step)
                %incorporate next burst in the current image series
                for iburst=1:step
                    ifile=indselect(ifield+step*floor(nbaver/2)+iburst-1);
                    filename=fullfile_uvmat(RootPath{1},SubDir,RootFile{1},FileExt,NomType,i1_series(1,ifile),[],j1_series(1,ifile));
                    %filename=name_generator(filebase,num_i1(ifile),num_j1(ifile),FileExt,NomType);
                    Aread=read_image(filename,FileType,MovieObject,i1_series(1,ifile));
                    Ak(:,:,nbaver_ima-step+iburst)=Aread;
                end
                Asort=sort(Ak,3);%sort the new current image series by luminosity
                B=Asort(:,:,rank);%current background image
                for iburst=1:step
                    index=step*floor(nbaver/2)+iburst;
                    Acor=double(Ak(:,:,index))-double(B);
                    Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
                    C=uint16(Acor);
                    ifile=indselect(ifield+iburst-1);
                    if ~isempty(j1_series{1})
                        j1=j1_series{1}(ifile);
                    end
                    newname=fullfile_uvmat(RootPath{1},Param.OutputSubDir,RootFile{1},FileExtOut,NomTypeOut,i1_series(1,1),[],i_slice,[]);
                   % newname=fullfile_uvmat(Param.InputTable{1,1},SubdirResult,Param.InputTable{1,3},'.png',NomType,i1_series{1}(ifile),[],j1);
                    %[newname]=name_generator(filebase_b,num_i1(ifile),num_j1(ifile),'.png',NomType) % makes the new file name
                    if test_level
                        C=levels(C);
                        imwrite(C,newname,'BitDepth',8); % save the new image
                    else
                        imwrite(C,newname,'BitDepth',16); % save the new image
                    end
                end
            else
                return
            end
        end
    end
    
    %% substract the background from the last images
    display('last background image will be substracted')
    ifield=nbfield_slice-(step*ceil(nbaver/2))+1:nbfield_slice;
    for ifield=nbfield_slice-(step*floor(nbaver/2))+1:nbfield_slice
        index=ifield-nbfield_slice+step*(2*floor(nbaver/2)+1);
        Acor=double(Ak(:,:,index))-double(B);
        Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
        C=uint16(Acor);
        ifile=indselect(ifield);
        if ~isempty(j1_series{1})
            j1=j1_series{1}(ifile);
        end
        newname=fullfile_uvmat(RootPath{1},Param.OutputSubDir,RootFile{1},FileExtOut,NomTypeOut,i1_series(1,ifile),[],j1);
%         newname=fullfile_uvmat(Param.InputTable{1,1},SubdirResult,Param.InputTable{1,3},'.png',NomType,i1_series{1}(ifile),[],j1);
        if test_level
            C=levels(C);
            imwrite(C,newname,'BitDepth',8); % save the new image
        else
            imwrite(C,newname,'BitDepth',16); % save the new image
        end
    end
end

%finish the waitbar
if checkrun
    update_waitbar(hseries.waitbar,WaitbarPos,1)
end

%------------------------------------------------------------------------
%--read images and convert them to the uint16 format used for PIV
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
siz=size(A);
if length(siz)==3;%color images
    A=sum(double(A),3);% take the sum of color components
end
    

function C=levels(A)
%whos A;
B=double(A(:,:,1));
windowsize=round(min(size(B,1),size(B,2))/20);
windowsize=floor(windowsize/2)*2+1;
ix=1/2-windowsize/2:-1/2+windowsize/2;%
%del=np/3;
%fct=exp(-(ix/del).^2);
fct2=cos(ix/(windowsize-1)/2*pi/2);
%Mfiltre=(ones(5,5)/5^2);
%Mfiltre=fct2';
Mfiltre=fct2'*fct2;
Mfiltre=Mfiltre/(sum(sum(Mfiltre)));

C=filter2(Mfiltre,B);
C(:,1:windowsize)=C(:,windowsize)*ones(1,windowsize);
C(:,end-windowsize+1:end)=C(:,end-windowsize+1)*ones(1,windowsize);
C(1:windowsize,:)=ones(windowsize,1)*C(windowsize,:);
C(end-windowsize+1:end,:)=ones(windowsize,1)*C(end-windowsize,:);
C=tanh(B./(2*C));
[n,c]=hist(reshape(C,1,[]),100);
% figure;plot(c,n);

[m,i]=max(n);
c_max=c(i);
[dummy,index]=sort(abs(c-c(i)));
n=n(index);
c=c(index);
i_select = find(cumsum(n)<0.95*sum(n));
if isempty(i_select)
    i_select = 1:length(c);
end
c_select=c(i_select);
n_select=n(i_select);
cmin=min(c_select);
cmax=max(c_select);
C=(C-cmin)/(cmax-cmin)*256;
C=uint8(C);