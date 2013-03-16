%'ima_levels': rescale the image intensity to reduce strong luminosity peaks (their blinking effects often perturbs PIV))
% this function can be used as a template for applying a transform (here 'levels.m') to each image of a series
%------------------------------------------------------------------------
% function GUI_input=ima_levels(Param)
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function is used in four modes by the GUI series:
%           1) config GUI: with no input argument, the function determine the suitable GUI configuration
%           2) interactive input: the function is used to interactively introduce input parameters, and then stops
%           3) RUN: the function itself runs, when an appropriate input  structure Param has been introduced. 
%           4) BATCH: the function itself proceeds in BATCH mode, using an xml file 'Param' as input.
%
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
 
function GUI_input=ima_levels (Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if ~exist('Param','var') % case with no input parameter 
    GUI_input={'NbViewMax';1;...% max nbre of input file series (default='' , no limitation)
        'AllowInputSort';'off';...% allow alphabetic sorting of the list of input files (options 'off'/'on', 'off' by default)
        'NbSlice';'off'; ...%nbre of slices ('off' by default)
        'VelType';'off';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
        'FieldName';'off';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'FieldTransform'; 'off';...%can use a transform function
        'ProjObject';'off';...%can use projection object(option 'off'/'on',
        'Mask';'off';...%can use mask option   (option 'off'/'on', 'off' by default)
        'OutputDirExt';'.lev';...%set the output dir extension
               ''};
        return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
%% select different modes,  RUN, parameter input, BATCH
% BATCH  case: read the xml file for batch case
if ischar(Param)
    if strcmp(Param,'input?')
        checkrun=1;% will inly search input parameters (preparation of BATCH mode)
    else
        Param=xml2struct(Param);
        checkrun=0;
    end
% RUN case: parameters introduced as the input structure Param
else
    hseries=guidata(Param.hseries);%handles of the GUI series
    checkrun=2; % indicate the RUN option is used
end

%% root input file(s) and type
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);
OutputSubDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files

% get the set of input file names (cell array filecell), and the lists of
% input file or frame indices i1_series,i2_series,j1_series,j2_series
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% filecell{iview,fileindex}: cell array representing the list of file names
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
% set of frame indices used for movie or multimage input 
% numbers of slices and file indices

NbSlice=1;%default
if isfield(Param.IndexRange,'NbSlice')
    NbSlice=Param.IndexRange.NbSlice;
end
nbview=numel(i1_series);%number of input file series (lines in InputTable)
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields
nbfield_i=floor(nbfield/NbSlice);%total number of  indexes in a slice (adjusted to an integer number of slices) 
nbfield=nbfield_i*NbSlice; %total number of fields after adjustement

%determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video'};%allowed input file types(images)

[FileType{1},FileInfo{1},MovieObject{1}]=get_file_type(filecell{1,1});
CheckImage{1}=~isempty(find(strcmp(FileType,ImageTypeOptions)));% =1 for images
if ~isempty(j1_series{1})
    frame_index{1}=j1_series{1};
else
    frame_index{1}=i1_series{1};
end

%% calibration data and timing: read the ImaDoc files
%not relevant for this function

%% check coincidence in time for several input file series
%not relevant for this function

%% coordinate transform or other user defined transform
%not relevant for this function

%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE

 %% check the validity of  input file types
if CheckImage{1}
    FileExtOut='.png'; % write result as .png images for image inputs
    if strcmp(lower(NomType{1}(end)),'a')
        NomTypeOut=NomType{1};
    else
        NomTypeOut='_1_1';
    end
else 
    msgbox_uvmat('ERROR',['invalid file type input: ' FileType{1} ' not an image'])
    return
end

%% Set field names and velocity types
%not relevant for this function

%% Initiate output fields
%not relevant for this function

%% set processing parameters
% not needed for this function

%% update the xml file
% not needed for this function

%% main loop on images
j1=[];%default
for ifile=1:nbfield
    if checkrun
        update_waitbar(hseries.Waitbar,ifile/nbfield)
        stopstate=get(hseries.RUN,'BusyAction');
    else
        stopstate='queue';
    end
    if isequal(stopstate,'queue') % enable STOP command
        if ~isempty(j1_series)&&~isequal(j1_series,{[]})
            j1=j1_series{1}(ifile);
        end
        filename=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},NomType{1},i1_series{1}(ifile),[],j1);
        A=read_image(filename,FileType{1},MovieObject{1},frame_index{1}(ifile));
        if ndims(A)==3;%color images
            A=sum(double(Aread),3);% take the sum of color components
        end
        % operation on images
        A=levels(A);
        filename_new=fullfile_uvmat(RootPath{1},OutputSubDir,RootFile{1},FileExtOut,NomTypeOut,i1_series{1}(ifile),[],j1);
        imwrite(A,filename_new)
        display([filename_new ' written'])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function C=levels(A)
%whos A;
B=double(A(:,:,1));
windowsize=round(min(size(B,1),size(B,2))/20);
windowsize=floor(windowsize/2)*2+1;
ix=[1/2-windowsize/2:-1/2+windowsize/2];%
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
