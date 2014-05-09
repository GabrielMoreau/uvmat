%'sub_background': substract a sliding background to an image series
%------------------------------------------------------------------------
% Method: 
    %calculate the background image by sorting the luminosity of each point
    % over a sliding sub-sequence of 'nbaver_ima' images. 
    % The luminosity value of rank 'rank' is selected as the
    % 'background'. rank=nbimages/2 gives the median value.  Smaller values are appropriate
    % for a dense set of particles. The extrem value rank=1 gives the true minimum
    % luminosity, but it can be polluted by noise. 
% Organization of image indices:
    % The program is working on a series of images, 
    % In the mode 'volume', nbfield2=1 (1 image at each level)and NbSlice (=nbfield_j)
    % Else nbfield2=nbfield_j =nbre of images in a burst (j index)
    
% function GUI_config=sub_background(Param)
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%OUTPUT
% ParamOut: sets options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% when Param.Action.RUN=0 (as activated when the current Action is selected
% in series), the function ouput paramOut set the activation of the needed GUI elements
%
% Param contains the elements:(use the menu bar command 'export/GUI config' in series to 
% see the current structure Param)
%    .InputTable: cell of input file names, (several lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDirExt: directory extension for data outputs
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%             .ActionExt: fct extension ('.m', Matlab fct, '.sh', compiled   Matlab fct
%             .RUN =0 for GUI input, =1 for function activation
%             .RunMode='local','background', 'cluster': type of function  use
%             
%    .IndexRange: set the file or frame indices on which the action must be performed
%    .FieldTransform: .TransformName: name of the selected transform function
%                     .TransformPath:   path  of the selected transform function
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%              .Coord_y: name of y coordinate variable
%              .Coord_x: name of x coordinate variable
%    .ProjObject: %sub structure describing a projection object (read from ancillary GUI set_object)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
function ParamOut=sub_background (Param)

%%%%%%%%%%%%%%%%%    INPUT PREPARATION MODE (no RUN)    %%%%%%%%%%%%%%%%%
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='on';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on'; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.sback';%set the output dir extension
    ParamOut.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    
    %% root input file(s) and type
    % check the existence of the first file in the series
        first_j=[];
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    last_j=[];
    if isfield(Param.IndexRange,'last_j'); last_j=Param.IndexRange.last_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('WARNING',['the first input file ' FirstFileName ' does not exist'])
    else
        [i1,i2,j1,j2] = get_file_index(Param.IndexRange.last_i,last_j,PairString);
        LastFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
        if ~exist(FirstFileName,'file')
             msgbox_uvmat('WARNING',['the last input file ' LastFileName ' does not exist'])
        end
    end

    %% check the validity of  input file types
    ImageTypeOptions={'image','multimage','mmreader','video'};%allowed input file types(images)
    FileType=get_file_type(FirstFileName);
    CheckImage=~isempty(find(strcmp(FileType,ImageTypeOptions), 1));% =1 for images
    if ~CheckImage
        msgbox_uvmat('ERROR',['invalid file type input: ' FileType ' not an image'])
        return
    end
    
    %% numbers of fields
    NbSlice=1;%default
    if isfield(Param.IndexRange,'NbSlice')&&~isempty(Param.IndexRange.NbSlice)
        NbSlice=Param.IndexRange.NbSlice;
    end
    incr_j=1;%default
    if isfield(Param.IndexRange,'incr_j')&&~isempty(Param.IndexRange.incr_j)
        incr_j=Param.IndexRange.incr_j;
    end
    if isempty(first_j)||isempty(last_j)
        nbfield_j=1;
    else
        nbfield_j=numel(first_j:incr_j:last_j);%nb of fields for the j index (bursts or volume slices)
    end
    incr_i=1;%default
    first_i=1;last_i=1;incr_i;%default
    if isfield(Param.IndexRange,'first_i'); last_i=Param.IndexRange.first_i; end   
    if isfield(Param.IndexRange,'last_i'); last_i=Param.IndexRange.last_j; end
    if isfield(Param.IndexRange,'incr_i')&&~isempty(Param.IndexRange.incr_i)
        incr_i=Param.IndexRange.incr_i;
    end
    nbfield_i=numel(first_i:incr_i:last_i);%nb of fields for the i index (bursts or volume slices)
    nbfield=nbfield_j*nbfield_i; %total number of fields
    nbfield_i=floor(nbfield/NbSlice);%total number of  indexes in a slice (adjusted to an integer number of slices)
    
    %% setting of  parameters specific to sub_background
    nbaver_init=23; %default number of images used for the sliding background: to be adjusted later to include an integer number of bursts  
    if nbfield_i~=1
        nbaver=floor(nbaver_init/nbfield_j); % number of bursts used for the sliding background,
        if isequal(floor(nbaver/2),nbaver)
            nbaver=nbaver+1;%put the number of burst to an odd number (so the middle burst is defined)
        end
        nbaver_init=nbaver*nbfield_j;%propose by default an integer number of bursts
    end
    
    prompt = {'volume scan mode (Yes/No)';'Number of images for the sliding background (MUST FIT IN COMPUTER MEMORY)';...
        'the luminosity rank chosen to define the background (0.1=for dense particle seeding, 0.5 (median) for sparse particles'};
    dlg_title = 'get (slice by slice) a sliding background and substract to each image';
    num_lines= 3;
    def     = { 'No';num2str(nbaver_init);'0.1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    %check input consistency
    if strcmp(answer{1},'No') && ~isequal(NbSlice,1)
        check=msgbox_uvmat('INPUT_Y-N',['confirm the multi-level splitting into ' num2str(NbSlice) ' slices']);
        if ~strcmp(check,'Yes')
            return
        end
    end
    if strcmp(answer{1},'Yes')
        step=1;
    else
        step=nbfield_j;%case of bursts: the sliding background is shifted by the length of one burst
    end
    nbaver_ima=str2num(answer{2});%number of images for the sliding background
    nbaver=ceil(nbaver_ima/step);%number of bursts for the sliding background
    if isequal(floor(nbaver/2),nbaver)
        nbaver=nbaver+1;%set the number of bursts to an odd number (so the middle burst is defined)
    end
    nbaver_ima=nbaver*step;% correct the nbre of images corresponding to nbaver
    ParamOut.ActionInput.CheckVolume=strcmp(answer{1},'Yes');
    ParamOut.ActionInput.SlidingSequenceLength=nbaver_ima;
    ParamOut.ActionInput.BrightnessRankThreshold=str2num(answer{3});
    
    % apply the image rescaling function 'level' (avoid the blinking effects of bright particles)
    answer=msgbox_uvmat('INPUT_Y-N','apply image rescaling function levels.m after sub_background');
    ParamOut.ActionInput.CheckLevelTransform=strcmp(answer,'Yes');
    return
end
%%%%%%%%%%%%%%%%%    STOP HERE FOR PAMETER INPUT MODE   %%%%%%%%%%%%%%%%% 

%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% input preparation
nbaver_ima=Param.ActionInput.SlidingSequenceLength;
NbSlice=Param.IndexRange.NbSlice;
if ~isequal(NbSlice,1)
    display(['multi-level splitting into ' num2str(NbSlice) ' slices']);
end
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);
hdisp=disp_uvmat('WAITING...','checking the file series',checkrun);
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
if ~isempty(hdisp),delete(hdisp),end;
%%%%%%%%%%%%
    % The cell array filecell is the list of input file names, while
    % filecell{iview,fileindex}:
    %        iview: line in the table corresponding to a given file series
    %        fileindex: file index within  the file series,
    % i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j
    % i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%%
[FileType{1},FileInfo{1},MovieObject{1}]=get_file_type(filecell{1,1});
    if ~isempty(j1_series{1})
        frame_index{1}=j1_series{1};
    else
        frame_index{1}=i1_series{1};
    end
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields
nbfield_i=floor(nbfield/NbSlice);%total number of  indexes in a slice (adjusted to an integer number of slices)
nbfield=nbfield_i*NbSlice; %total number of fields after adjustement

%% output
FileExtOut='.png'; % write result as .png images for image inputs
if strcmp(lower(NomType{1}(end)),'a')
    NomTypeOut=NomType{1};%case of letter appendix
elseif isempty(j1_series)
    NomTypeOut='_1';
else
    NomTypeOut='_1_1';% caseof purely numerical indexing
end

OutputDir=[Param.OutputSubDir Param.OutputDirExt];

if isequal(Param.ActionInput.CheckVolume,1)
    step=1;
else
    step=nbfield_j;%case of bursts: the sliding background is shifted by the length of one burst
end
nbaver_ima=Param.ActionInput.SlidingSequenceLength;%number of images for the sliding background
nbaver=ceil(nbaver_ima/step);%number of bursts for the sliding background
if isequal(floor(nbaver/2),nbaver)
    nbaver=nbaver+1;%set the number of bursts to an odd number (so the middle burst is defined)
end
nbaver_ima=nbaver*step;
if nbaver_ima > nbfield
    display('number of images in a slice smaller than the proposed number of images for the sliding average')
    return
end

% calculate absolute brightness rank
rank=floor(Param.ActionInput.BrightnessRankThreshold*nbaver_ima);
if rank==0
    rank=1;%rank selected in the sorted image series
end

%% prealocate memory for the sliding background
try
    Afirst=read_image(filecell{1,1},FileType{1},MovieObject{1},frame_index{1}(1));
    [npy,npx,nbcolor]=size(Afirst);% the argument nbcolor is important to get npx right for color images
    if strcmp(class(Afirst),'uint8') % case of 8bit images
        Ak=zeros(npy,npx,nbaver_ima,'uint8'); %prealocate memory
        Asort=zeros(npy,npx,nbaver_ima,'uint8'); %prealocate memory
    else
        Ak=zeros(npy,npx,nbaver_ima,'uint16'); %prealocate memory
        Asort=zeros(npy,npx,nbaver_ima,'uint16'); %prealocate memory
    end
catch ME
    msgbox_uvmat('ERROR',['sub_background/read_image/' ME.message])
    return
end

%% summary of the parameters:
% nbfield : total number of images treated (in case of multislices the function sub_background is repeated for each slice)
% step: shift at each step of the sliding background (corresponding to the nbre of images in a burst)
% nbaver_ima: length of the sequence used for the sliding background

% nbaver=nbaver_ima/step: nbaver_ima has been adjusted so that nbaver is an odd integer
halfnbaver=floor(nbaver/2); % half width (in unit of bursts) of the sliding background 

%% select the series of image indices to process
indselect=1:step:nbfield;% select file indices of the slice
for ifield=1:step-1
    indselect=[indselect;indselect(end,:)+1];
end

%% read the first series of nbaver_ima images and sort by luminosity at each pixel
for ifield = 1:nbaver_ima
    ifile=indselect(ifield);
    filename=filecell{1,ifile};
    Aread=read_image(filename,FileType{1},MovieObject{1},frame_index{1}(ifile));
    if ndims(Aread)==3;%color images
        Aread=sum(double(Aread),3);% take the sum of color components
    end
    Ak(:,:,ifield)=Aread;
end
Asort=sort(Ak,3);%sort the luminosity of images at each point
B=Asort(:,:,rank);%background image

%% substract the first background image to the first images
display( 'first background image will be substracted')
for ifield=1:step*(halfnbaver+1);% nbre of images treated by the first background image
    Acor=double(Ak(:,:,ifield))-double(B);%substract background to the current image
    Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
    ifile=indselect(ifield);
    if ~isempty(j1_series{1})
        j1=j1_series{1}(ifile);
    end
    newname=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},FileExtOut,NomTypeOut,i1_series{1}(ifile),[],j1);
    
    %write result file
    if Param.ActionInput.CheckLevelTransform
        C=levels(Acor);
        imwrite(C,newname,'BitDepth',8); % save the new image
    else
        if isequal(FileInfo{1}.BitDepth,16)
            C=uint16(Acor);
            imwrite(C,newname,'BitDepth',16); % save the new image
        else
            C=uint8(Acor);
            imwrite(C,newname,'BitDepth',8); % save the new image
        end
    end
    display([newname ' written'])
end

%% repeat the operation on a sliding series of images
display('sliding background image will be substracted')
if nbfield_i > nbaver_ima
    for ifield = step*(halfnbaver+1):step:nbfield_i-step*(halfnbaver+1)% ifield +iburst=index of the current processed image
        update_waitbar(WaitbarHandle,ifield/nbfield_i)
        if ~isempty(RUNHandle) &&ishandle(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
            disp('program stopped by user')
            return
        end
        Ak(:,:,1:nbaver_ima-step)=Ak(:,:,1+step:nbaver_ima);% shift the current image series by one burst (step)
        %incorporate next burst in the current image series
        for iburst=1:step
            ifile=indselect(ifield+iburst+step*halfnbaver);
            filename=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},NomType{1},i1_series{1}(ifile),[],j1_series{1}(ifile));
            Aread=read_image(filename,FileType{1},MovieObject{1},i1_series{1}(ifile));
            if ndims(Aread)==3;%color images
                Aread=sum(double(Aread),3);% take the sum of color components
            end
            Ak(:,:,nbaver_ima-step+iburst)=Aread;% fill the last burst of the current image series by the new image
        end
        Asort=sort(Ak,3);%sort the new current image series by luminosity
        B=Asort(:,:,rank);%current background image
        %substract the background for the current burst
        for iburst=1:step
            Acor=double(Ak(:,:,step*halfnbaver+iburst))-double(B); %the current image has been already read ans stored as index step*halfnbaver+iburst in the current series
            Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
            ifile=indselect(ifield+iburst);
            if ~isempty(j1_series{1})
                j1=j1_series{1}(ifile);
            end
            newname=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},FileExtOut,NomTypeOut,i1_series{1}(ifile),[],j1);
            %write result file
            if Param.ActionInput.CheckLevelTransform
                C=levels(Acor);
                imwrite(C,newname,'BitDepth',8); % save the new image
            else
                if isequal(FileInfo{1}.BitDepth,16)
                    C=uint16(Acor);
                    imwrite(C,newname,'BitDepth',16); % save the new image
                else
                    C=uint8(Acor);
                    imwrite(C,newname,'BitDepth',8); % save the new image
                end
            end
            display([newname ' written'])        
        end
    end
end

%% substract the background from the last images
display('last background image will be substracted')
for  ifield=nbfield_i-step*halfnbaver+1:nbfield_i
    Acor=double(Ak(:,:,ifield-nbfield_i+step*(2*halfnbaver+1)))-double(B);
    Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
    ifile=indselect(ifield);
    if ~isempty(j1_series{1})
        j1=j1_series{1}(ifile);
    end
    newname=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},FileExtOut,NomTypeOut,i1_series{1}(ifile),[],j1);  
    %write result file
    if Param.ActionInput.CheckLevelTransform
        C=levels(Acor);
        imwrite(C,newname,'BitDepth',8); % save the new image
    else
        if isequal(FileInfo{1}.BitDepth,16)
            C=uint16(Acor);
            imwrite(C,newname,'BitDepth',16); % save the new image
        else
            C=uint8(Acor);
            imwrite(C,newname,'BitDepth',8); % save the new image
        end
    end
    display([newname ' written'])
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