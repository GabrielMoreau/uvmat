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

%% input preparation mode (no RUN)
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
    filecell=get_file_series(Param);%check existence of the first input file
    %%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
    
    %% root input file(s) and type
    [filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
    if ~exist(filecell{1,1},'file')
        msgbox_uvmat('WARNING','the first input file does not exist')
        return
    end
    %%%%%%%%%%%%
    % The cell array filecell is the list of input file names, while
    % filecell{iview,fileindex}:
    %        iview: line in the table corresponding to a given file series
    %        fileindex: file index within  the file series,
    % i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j
    % i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
    %%%%%%%%%%%%
    NbSlice=1;%default
    if isfield(Param.IndexRange,'NbSlice')&&~isempty(Param.IndexRange.NbSlice)
        NbSlice=Param.IndexRange.NbSlice;
    end
    nbview=numel(i1_series);%number of input file series (lines in InputTable)
    nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
    nbfield_i=size(i1_series{1},2); %nb of fields for the i index
    nbfield=nbfield_j*nbfield_i; %total number of fields
    nbfield_i=floor(nbfield/NbSlice);%total number of  indexes in a slice (adjusted to an integer number of slices)
    nbfield=nbfield_i*NbSlice; %total number of fields after adjustement
    
    %determine the file type on each line from the first input file

    
    %% calibration data and timing: read the ImaDoc files
    %not relevant here
    
    %% check coincidence in time for several input file series
    %not relevant here
    
    %% coordinate transform or other user defined transform
    %not relevant here
    
    %%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
    % EDIT FROM HERE
    
    %% check the validity of  input file types
    ImageTypeOptions={'image','multimage','mmreader','video'};%allowed input file types(images)
    FileType=get_file_type(filecell{1,1});
    CheckImage=~isempty(find(strcmp(FileType,ImageTypeOptions), 1));% =1 for images
    if ~CheckImage
        msgbox_uvmat('ERROR',['invalid file type input: ' FileType{1} ' not an image'])
        return
    end
    
    %% Set field names and velocity types
    %not relevant here
    
    %% Initiate output fields
    %not relevant here
    
    %%% SPECIFIC PART BEGINS HERE
    NbSlice=1;
    if isfield(Param.IndexRange,'NbSlice')
        NbSlice=Param.IndexRange.NbSlice; %number of slices
    end
    %siz=size(i1_series);
    nbaver_init=23;%approximate number of images used for the sliding background: to be adjusted later to include an integer number of bursts
    j1=[];%default
    
    %% adjust the proposed number of images in the sliding average to include an integer number of bursts
    if nbfield_i~=1
        nbaver=floor(nbaver_init/nbfield_j); % number of bursts used for the sliding background,
        if isequal(floor(nbaver/2),nbaver)
            nbaver=nbaver+1;%put the number of burst to an odd number (so the middle burst is defined)
        end
        nbaver_init=nbaver*nbfield_j;%propose by default an integer number of bursts
    end
    
    %% input of specific parameters
    %if checkrun %get specific parameters interactively
    if isequal(Param.Action.RUN,0)
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
        nbaver_ima=nbaver*step;
    end
    ParamOut.ActionInput.CheckVolume=strcmp(answer{1},'Yes');
    ParamOut.ActionInput.SlidingSequenceLength=nbaver_ima;
    ParamOut.ActionInput.BrightnessRankThreshold=str2num(answer{3});
    
    % apply the image rescaling function 'level' (avoid the blinking effects of bright particles)
    answer=msgbox_uvmat('INPUT_Y-N','apply image rescaling function levels.m after sub_background');
    ParamOut.ActionInput.CheckLevelTransform=strcmp(answer,'Yes');
    return
end
%%%%%%%%%%%%%%%%%%%%%%  STOP HERE FOR PAMETER INPUT MODE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
%% Input preparation
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
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
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

%% Output
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
    [npy,npx]=size(Afirst);
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

%% update the xml file
% SubDirBase=regexprep(Param.InputTable{1,2},'\..*','');%take the root part of SubDir, before the first dot '.'
% filexml=fullfile(RootPath{1},[SubDirBase '.xml']);
% if ~exist(filexml,'file') && exist([fullfile(RootPath{1},SubDir{1},RootFile{1}) '.xml'],'file')% xml inside the image directory
%     copyfile([filebase '.xml'],filexml);% copy the .xml file
% end
% if exist(filexml,'file')
%     t=xmltree(filexml);  
%     %update information on the first image name in the series
%     uid_Heading=find(t,'ImaDoc/Heading');
%     if isempty(uid_Heading)
%         [t,uid_Heading]=add(t,1,'element','Heading');
%     end
%     uid_ImageName=find(t,'ImaDoc/Heading/ImageName');
%     if ~isempty(j1_series{1})
%         j1=j1_series{1}(1);
%     end
%     ImageName=fullfile_uvmat([dir_images term],'',RootFile{1},'.png',NomType,i1_series(1,1),[],j1);
%     [pth,ImageName]=fileparts(ImageName);
%     ImageName=[ImageName '.png'];
%     if isempty(uid_ImageName)
%         [t,uid_ImageName]=add(t,uid_Heading,'element','ImageName');
%     end
%     uid_value=children(t,uid_ImageName);
%     if isempty(uid_value)
%         t=add(t,uid_ImageName,'chardata',ImageName);%indicate  name of the first image, with ;png extension
%     else
%         t=set(t,uid_value(1),'value',ImageName);%indicate  name of the first image, with ;png extension
%     end
%     
%     %add information about image transform
%     [t,new_uid]=add(t,1,'element','ImageTransform');
%     [t,NameFunction_uid]=add(t,new_uid,'element','NameFunction');
%     [t]=add(t,NameFunction_uid,'chardata','sub_background');
%     if GUI_config.CheckLevel
%         [t,NameFunction_uid]=add(t,new_uid,'element','NameFunction');
%         [t]=add(t,NameFunction_uid,'chardata','levels');
%     end
%     [t,NbSlice_uid]=add(t,new_uid,'element','NbSlice');
%     [t]=add(t,new_uid,'chardata',num2str(NbSlice));
%     [t,NbSlidingImages_uid]=add(t,new_uid,'element','NbSlidingImages');
%     [t]=add(t,NbSlidingImages_uid,'chardata',num2str(nbaver));
%     [t,LuminosityRank_uid]=add(t,new_uid,'element','RankBackground');
%     [t]=add(t,LuminosityRank_uid,'chardata',num2str(rank));% luminosity rank almong the nbaver sliding images
%     save(t,filexml)
% end
%copy the mask
% if exist([filebase '_1mask_1'],'file')
%     copyfile([filebase '_1mask_1'],[filebase_b '_1mask_1']);% copy the mask file
% end

%MAIN LOOP ON SLICES
% for islice=1:NbSlice
%% select the series of image indices
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
display( 'first background image will be substracted')
nbfirst=(ceil(nbaver/2))*step;
for ifield=1:nbfirst
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
    for ifield = step*ceil(nbaver/2)+1:step:nbfield_i-step*floor(nbaver/2)
                update_waitbar(WaitbarHandle,ifield/nbfield_i)
    if ishandle(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
%         if isequal(stopstate,'queue')% enable STOP command
            Ak(:,:,1:nbaver_ima-step)=Ak(:,:,1+step:nbaver_ima);% shift the current image series by one burst (step)
            %incorporate next burst in the current image series
            for iburst=1:step
                ifile=indselect(ifield+step*floor(nbaver/2)+iburst-1);
                filename=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},NomType{1},i1_series{1}(ifile),[],j1_series{1}(ifile));
                Aread=read_image(filename,FileType{1},MovieObject{1},i1_series{1}(ifile));
                if ndims(Aread)==3;%color images
                    Aread=sum(double(Aread),3);% take the sum of color components
                end
                Ak(:,:,nbaver_ima-step+iburst)=Aread;
            end
            Asort=sort(Ak,3);%sort the new current image series by luminosity
            B=Asort(:,:,rank);%current background image
            for iburst=1:step
                index=step*floor(nbaver/2)+iburst;
                Acor=double(Ak(:,:,index))-double(B);
                Acor=(Acor>0).*Acor; % put to 0 the negative elements in Acor
                ifile=indselect(ifield+iburst-1);
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
%         else
%             return
%         end
    end
end

%% substract the background from the last images
display('last background image will be substracted')
ifield=nbfield_i-(step*ceil(nbaver/2))+1:nbfield_i;
for ifield=nbfield_i-(step*floor(nbaver/2))+1:nbfield_i
    index=ifield-nbfield_i+step*(2*floor(nbaver/2)+1);
    Acor=double(Ak(:,:,index))-double(B);
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