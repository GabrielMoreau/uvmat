%'merge_proj': concatene several fields from series, can project them on a regular grid in phys coordinates
%------------------------------------------------------------------------
% function ParamOut=merge_proj(Param)
%------------------------------------------------------------------------
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

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function ParamOut=particle_detect(Param)

%% set the input elements needed on the GUI series when the function is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='on';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.detect';%set the output dir extension
    ParamOut.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
      %check the input files
    ParamOut.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default=1)
    first_j=[];
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('WARNING',['the first input file ' FirstFileName ' does not exist'])
    end
    
    prompt = {'threshold(th)';...
        'particle size (sz)' };
    dlg_title = 'get processing parameters';
    num_lines= 2;
    def     = {'4000';'3'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        return
    end
    %check input consistency
    ParamOut.ActionInput.th=str2num(answer{1});
    ParamOut.ActionInput.sz=str2num(answer{2});
    return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
ParamOut=[]; %default output
RUNHandle=[];
WaitbarHandle=[];
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
else
    hseries=findobj(allchild(0),'Tag','series');
    RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
    WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
end

%% define the directory for result file (with path=RootPath{1})
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files

if ~isfield(Param,'InputFields')
    Param.InputFields.FieldName='';
end

%% root input file(s) name, type and index series
RootPath=Param.InputTable{1,1};
RootFile=Param.InputTable{1,3};
SubDir=Param.InputTable{1,2};
NomType=Param.InputTable{1,4};
FileExt=Param.InputTable{1,5};

hdisp=disp_uvmat('WAITING...','checking the file series',checkrun);
% gives the series of input file names and indices set by the input parameters:
%[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index with i and j reshaped as a 1D array
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
if ~isempty(hdisp),delete(hdisp),end;%end the waiting display


%% determine the file type on each line from the first input file


%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
% EDIT FROM HERE

RootFileOut=RootFile;


%% MAIN LOOP ON FIELDS
%%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
% for i_slice=1:NbSlice
%     index_slice=i_slice:NbSlice:NbField;% select file indices of the slice
%     NbFiles=0;
%     nbmissing=0;

%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
tstart=tic; %used to record the computing time
CheckOverwrite=1;%default
if isfield(Param,'CheckOverwrite')
    CheckOverwrite=Param.CheckOverwrite;
end
%%%%%%   INPUT %%%%%%
th=Param.ActionInput.th
sz=Param.ActionInput.sz
% th=4000;%threshold on image intensity
% sz=3; %size of particles

NbImage=Param.IndexRange.last_i-Param.IndexRange.first_i+1;
incr_i=Param.IndexRange.incr_i;
NbBlock=floor(NbImage/incr_i);

%% MAIN LOOP
for index1=1:NbBlock
    OutputFile=fullfile_uvmat(RootPath,OutputDir,RootFileOut,'.mat','_1-2',(index1-1)*incr_i+1,index1*incr_i)
    if ~CheckOverwrite && exist(OutputFile,'file')
        disp(['existing output file ' OutputFile ' already exists, skip to next field'])
    end
    for index=(index1-1)*incr_i+1:index1*incr_i
        index
        
        %% reading input file(s)
        ImgName=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,index)
        Im=imread(ImgName);
        [Ny,Nx]=size(Im);
        %
        %
        %         frame = kframe+idfile*framesperfiles;
        %     disp(frame);
        %     ImgName = sprintf(join(['%s/%s_cam%d_' format],''),folderin, ManipName, CamNum, frame);
        %     fprintf("%s \n",ImgName);
        %Im = (cast(imread(ImgName),'like',Background) - Background).*mask;
        %% normalizeimage
        Im = double(Im);
        
        %     Imfiltered=filter2(transfert_coef,Im);
        %
        %     Imfiltered(:,1:windowsize)=Imfiltered(:,windowsize)*ones(1,windowsize);
        %     Imfiltered(:,end-windowsize+1:end)=Imfiltered(:,end-windowsize+1)*ones(1,windowsize);
        %     Imfiltered(1:windowsize,:)=ones(windowsize,1)*Imfiltered(windowsize,:);
        %     Imfiltered(end-windowsize+1:end,:)=ones(windowsize,1)*Imfiltered(end-windowsize,:);
        %     Im=Im./(2*Imfiltered);
        %%
        
        out=pkfnd(Im,th,sz); % Provides intensity maxima positionsth,sz,Test,BackgroundType,format
        npar = size(out,1);
        
        %% We keep only spots with a gaussian shape
        cnt = 0;
        x = [];
        y = [];
        for j = 1:npar
            Nwidth = 1;
            if (out(j,2)-Nwidth >0)&&(out(j,1)-Nwidth>0)&&(out(j,2)+Nwidth<Ny)&&(out(j,1)+Nwidth<Nx)
                cnt = cnt+1;
                
                Ip = double(Im(out(j,2)-Nwidth:out(j,2)+Nwidth,out(j,1)-Nwidth:out(j,1)+Nwidth));
                
                x(end+1) = out(j, 1) + 0.5*log(Ip(2,3)/Ip(2,1))/(log((Ip(2,2)*Ip(2,2))/(Ip(2,1)*Ip(2,3))));
                y(end+1) = out(j, 2) + 0.5*log(Ip(3,2)/Ip(1,2))/(log((Ip(2,2)*Ip(2,2))/(Ip(1,2)*Ip(3,2))));
            end
        end
        
        CC(index).X=x;
        CC(index).Y=y;
    end
    
    %% Centers saving into a .mat file
    if Param.IndexRange.last_i>1
        savefile=OutputFile;
        save(savefile,"CC",'-v7.3')
        m = matfile(savefile,'Writable',true);
        m.nframes = incr_i;
    else
        figure("NumberTitle","Off","Name",['RAW picture,' SubDir])
        imshow(imread(ImgName),[0,5000])
        colormap gray
        %     figure("NumberTitle","Off","Name",sprintf("%s, cam %d",BackgroundType,CamNum))
        %     imshow(BackgroundMin,[0,5000])
        %     colormap gray
        %     figure("NumberTitle","Off","Name",sprintf("RAW picture - Background, cam %d, frame %d",CamNum,kframe))
        %     imshow(Im,[0,th])
        %     colormap gray
        colorbar
        
        %% Tracé de l'histogramme des intensités pour définir le seuil
        fig = figure('NumberTitle','Off','Name','Intensity histogram');
        histogram(Im,1000)
        xlabel("Intensity")
        ylabel("Number")
        set(gca, 'XScale', 'log')
        set(gca, 'YScale', 'log')
        
        Nx = size(Im,2);
        Ny = size(Im,1);
        
        out=pkfnd(Im,th,sz); % Provides intensity maxima positions
        npar = size(out,1);
        
        %% We keep only spots with a gaussian shape
        cnt = 0;
        x = [];
        y = [];
        for j = 1:npar
            Nwidth = 1;
            if (out(j,2)-Nwidth >0)&&(out(j,1)-Nwidth>0)&&(out(j,2)+Nwidth<Ny)&&(out(j,1)+Nwidth<Nx)
                cnt = cnt+1;
                
                Ip = double(Im(out(j,2)-Nwidth:out(j,2)+Nwidth,out(j,1)-Nwidth:out(j,1)+Nwidth));
                
                x(end+1) = out(j, 1) + 0.5*log(Ip(2,3)/Ip(2,1))/(log((Ip(2,2)*Ip(2,2))/(Ip(2,1)*Ip(2,3))));
                y(end+1) = out(j, 2) + 0.5*log(Ip(3,2)/Ip(1,2))/(log((Ip(2,2)*Ip(2,2))/(Ip(1,2)*Ip(3,2))));
            end
        end
        CC(1).X=x;
        CC(1).Y=y;
        
        fprintf("%d treated \n",1)
        
        %% Let's plot picture and detected points on a graph !!! Be careful the vertical axis is reversed compared to reality !!!
        figure('NumberTitle','Off','Name',sprintf("frame %d, %d detected points",1,numel(x)))
        imshow(Im,[0,th])
        colormap gray
        
        hold on
        plot(flip(x),flip(y),'r+')
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function CC = CenterFinding2D(session,ManipName,CamNum,firstFrame,nframes,th,sz,Test,BackgroundType,format,withmask)
%%% Detect particles position in picture and provides their positions in
%%% px.
%--------------------------------------------------------------------------------
%%% Parameters :
%%%     session                    : Path to the achitecture root (2 fields: session.input_path
% and session.output_path)
%%%     ManipName                  : Name of the folder experiment
%%%     NumCam                     : number of the camera studied
%%%     nframes                    : total number of pictures
%%%     th                         : threshold
%%%     sz                         : typical size of the particles
%%%     Test                       : true-> test mode, false-> classic mode (optional)
%%%     BackgroundType (optional)  : determine which background is substracted to pictures. By defaut is equal to BackgroundMean,
%%%     format (optional)          : picture names. By defaut it is '%05d.tif'.
%%%     The beginning of picture names has to be %ManipName_cam%CamNum_%format
%--------------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all

framesperfiles = 1000;

%% Test if Test exist or not
if ~exist('Test','var')
    Test=false;
end

%% Test if BackgroundType exist or not
if ~exist('BackgroundType','var')
    BackgroundType="BackgroundMean";
end

% By defaut format='%05d.tif'
if ~exist('format','var')
    format='%05d.tif';
end

if ~exist('withmask','var')
    withmask=false;
end



%% Definition of folders
fprintf(ManipName);
folderin = sprintf("%sDATA/%s/cam%d",session.input_path,ManipName,CamNum)
folderout = sprintf("%sProcessed_DATA/%s",session.output_path,ManipName)
BackgroundFile = sprintf("%s/Background_cam%d.mat",folderout,CamNum);

%% Find centers
if exist(folderout,'dir')==0
    mkdir(char(folderout));
end

% if exist(strcat(folderout,'/Parallel/Matching'),'dir')==0
%     mkdir(char(strcat(folderout,'/Parallel/Matching')));
% end

load(BackgroundFile,'BackgroundMin','BackgroundMax','BackgroundMean')
%% Choice of background type
if BackgroundType=="BackgroundMean"
    Background=BackgroundMean;
elseif BackgroundType=="BackgroundMax"
    Background=BackgroundMax;
elseif BackgroundType=="BackgroundMin"
    Background=BackgroundMin;
end
Nx = size(Background,2);
Ny = size(Background,1);

if withmask
    ImgName = sprintf(join(['%s/%s_cam%d_' format],''),folderin, ManipName, CamNum, 1);
    Im = imread(ImgName);
    imshow(Im,[0,10000])
    BW = roipoly;
    mask = cast(BW,'like',Background);
else
    mask = cast(ones(Ny,Nx),'like',Background);
end

%% param for normailze image
windowsize=round(min(Ny,Nx)/20);
transfert_coef = ones(windowsize)/windowsize^2;
%%

close all
if ~Test
    idfirstfile = fix(firstFrame/framesperfiles);
    idlastfile = fix((nframes-1)/framesperfiles);
    for idfile = idfirstfile:idlastfile
        firstFrame = rem(firstFrame,framesperfiles);
        lastframe = min(framesperfiles,nframes-idfile*framesperfiles);
        for kframe=firstFrame:lastframe
            frame = kframe+idfile*framesperfiles;
            disp(frame);
            ImgName = sprintf(join(['%s/%s_cam%d_' format],''),folderin, ManipName, CamNum, frame);
            fprintf("%s \n",ImgName);
            Im = (cast(imread(ImgName),'like',Background) - Background).*mask;
            %% normalizeimage
            Im = double(Im);

            Imfiltered=filter2(transfert_coef,Im);

            Imfiltered(:,1:windowsize)=Imfiltered(:,windowsize)*ones(1,windowsize);
            Imfiltered(:,end-windowsize+1:end)=Imfiltered(:,end-windowsize+1)*ones(1,windowsize);
            Imfiltered(1:windowsize,:)=ones(windowsize,1)*Imfiltered(windowsize,:);
            Imfiltered(end-windowsize+1:end,:)=ones(windowsize,1)*Imfiltered(end-windowsize,:);
            Im=Im./(2*Imfiltered);
            %%
            
            
            out=pkfnd(Im,th,sz); % Provides intensity maxima positions
            npar = size(out,1);

            %% We keep only spots with a gaussian shape
            cnt = 0;
            x = [];
            y = [];
            for j = 1:npar
                Nwidth = 1;
                if (out(j,2)-Nwidth >0)&&(out(j,1)-Nwidth>0)&&(out(j,2)+Nwidth<Ny)&&(out(j,1)+Nwidth<Nx)
                    cnt = cnt+1;

                    Ip = double(Im(out(j,2)-Nwidth:out(j,2)+Nwidth,out(j,1)-Nwidth:out(j,1)+Nwidth));

                    x(end+1) = out(j, 1) + 0.5*log(Ip(2,3)/Ip(2,1))/(log((Ip(2,2)*Ip(2,2))/(Ip(2,1)*Ip(2,3))));
                    y(end+1) = out(j, 2) + 0.5*log(Ip(3,2)/Ip(1,2))/(log((Ip(2,2)*Ip(2,2))/(Ip(1,2)*Ip(3,2))));
                end
            end

            CC(kframe).X=x;
            CC(kframe).Y=y;
        end
        %% Centers saving into a .mat file
        firstFramefile = framesperfiles*idfile+1;
        lastFramefile = framesperfiles*(idfile+1);
        savefile = sprintf(['%s/Parallel/Matching/centers_cam%d_',format(1:end-4),'-',format(1:end-4),'.mat'],folderout,CamNum,firstFramefile,lastFramefile);
        if exist(savefile,'file')
            m = matfile(savefile,'Writable',true);
            m.CC(1,firstFrame:lastframe) = CC(firstFrame:lastframe);
            m.nframes = framesperfiles;
        else
            save(savefile,"CC","nframes",'-v7.3')
            m = matfile(savefile,'Writable',true);
            m.nframes = framesperfiles;
        end
        firstFrame = 1;
    end
else
    kframe=1
    ImgName = sprintf(join(['%s/%s_cam%d_' format],''),folderin, ManipName, CamNum, kframe);
    fprintf("%s \n",ImgName);
    Im = (cast(imread(ImgName),'like',Background) - Background).*mask;
    %% normalizeimage
    Im = double(Im);

    Imfiltered=filter2(transfert_coef,Im);

    Imfiltered(:,1:windowsize)=Imfiltered(:,windowsize)*ones(1,windowsize);
    Imfiltered(:,end-windowsize+1:end)=Imfiltered(:,end-windowsize+1)*ones(1,windowsize);
    Imfiltered(1:windowsize,:)=ones(windowsize,1)*Imfiltered(windowsize,:);
    Imfiltered(end-windowsize+1:end,:)=ones(windowsize,1)*Imfiltered(end-windowsize,:);
    Im=Im./(2*Imfiltered);
    %%
    figure("NumberTitle","Off","Name",sprintf("RAW picture, cam %d, frame %d",CamNum,kframe))
    imshow(imread(ImgName),[0,5000])
    colormap gray
    figure("NumberTitle","Off","Name",sprintf("%s, cam %d",BackgroundType,CamNum))
    imshow(BackgroundMin,[0,5000])
    colormap gray
    figure("NumberTitle","Off","Name",sprintf("RAW picture - Background, cam %d, frame %d",CamNum,kframe))
    imshow(Im,[0,th])
    colormap gray
    colorbar
    
%     if exist('Erosion','var')
%         se = strel('disk',1);
%         Imerode = imerode(Im,se);
%         Imdilate = imdilate(Imerode,se);
%         figure()
%         imagesc(Imdilate)
%         axis image
%         colormap gray
% 
%         Image = Im;
%         Im = Imdilate;
%     end

    %% Tracé de l'histogramme des intensités pour définir le seuil
    fig = figure('NumberTitle','Off','Name','Intensity histogram');
    histogram(Im,1000)
    xlabel("Intensity")
    ylabel("Number")
    set(gca, 'XScale', 'log')
    set(gca, 'YScale', 'log')
    
    Nx = size(Im,2);
    Ny = size(Im,1);

    out=pkfnd(Im,th,sz); % Provides intensity maxima positions
    npar = size(out,1);
        
    %% We keep only spots with a gaussian shape
    cnt = 0;
    x = [];
    y = [];
    for j = 1:npar
        Nwidth = 1;
        if (out(j,2)-Nwidth >0)&&(out(j,1)-Nwidth>0)&&(out(j,2)+Nwidth<Ny)&&(out(j,1)+Nwidth<Nx)
            cnt = cnt+1;

            Ip = double(Im(out(j,2)-Nwidth:out(j,2)+Nwidth,out(j,1)-Nwidth:out(j,1)+Nwidth));

            x(end+1) = out(j, 1) + 0.5*log(Ip(2,3)/Ip(2,1))/(log((Ip(2,2)*Ip(2,2))/(Ip(2,1)*Ip(2,3))));
            y(end+1) = out(j, 2) + 0.5*log(Ip(3,2)/Ip(1,2))/(log((Ip(2,2)*Ip(2,2))/(Ip(1,2)*Ip(3,2))));
        end
    end
    CC(kframe).X=x;
    CC(kframe).Y=y;

    fprintf("%d treated \n",kframe)

    %% Let's plot picture and detected points on a graph !!! Be careful the vertical axis is reversed compared to reality !!!
    figure('NumberTitle','Off','Name',sprintf("frame %d, %d detected points",kframe,numel(x)))
    imshow(Im,[0,th])
    colormap gray
    
    hold on
    plot(flip(x),flip(y),'r+')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out=pkfnd(im,th,sz)
% finds local maxima in an image to pixel level accuracy.  
%  this provides a rough guess of particle
%  centers to be used by cntrd.m.  Inspired by the lmx subroutine of Grier
%  and Crocker's feature.pro
%--------------------------------------------------------------------------------
% INPUTS:
%   im  : image to process, particle should be bright spots on dark background with little noise
%       ofen an bandpass filtered brightfield image (fbps.m, fflt.m or bpass.m) or a nice
%       fluorescent image
%   th  : the minimum brightness of a pixel that might be local maxima.
%       (NOTE: Make it big and the code runs faster
%       but you might miss some particles.  Make it small and you'll get
%       everything and it'll be slow.)
%   sz  :  if your data's noisy, (e.g. a single particle has multiple local
%       maxima), then set this optional keyword to a value slightly larger than the diameter of your blob.  if
%       multiple peaks are found withing a radius of sz/2 then the code will keep
%       only the brightest.  Also gets rid of all peaks within sz of boundary
% OUTPUT:  a N x 2 array containing, [row,column] coordinates of local maxima
%          out(:,1) are the x-coordinates of the maxima
%          out(:,2) are the y-coordinates of the maxima
%--------------------------------------------------------------------------------
%CREATED: Eric R. Dufresne, Yale University, Feb 4 2005
%MODIFIED: ERD, 5/2005, got rid of ind2rc.m to reduce overhead on tip by
%  Dan Blair;  added sz keyword
% ERD, 6/2005: modified to work with one and zero peaks, removed automatic
%  normalization of image
% ERD, 6/2005: due to popular demand, altered output to give x and y
%  instead of row and column
% ERD, 8/24/2005: pkfnd now exits politely if there's nothing above
%  threshold instead of crashing rudely
% ERD, 6/14/2006: now exits politely if no maxima found
% ERD, 10/5/2006:  fixed bug that threw away particles with maxima
%  consisting of more than two adjacent points



%find all the pixels above threshold
%im=im./max(max(im));
[nr,nc] = size(im);
[i,j,ind]=find(im > th);
n=length(ind);

if n==0
    out=[];[i,j,ind]=find(im > th);
    fprintf('nothing above threshold');
    return;
end
mx=[];
%convert index from find to row and column
rc=[i,j]; % j corresponds to x axis and i to y axis
% rc=[j,i]; % j corresponds to x axis and i to y axis
for ii=1:n
    r=rc(ii,1);
    c=rc(ii,2);
    %check each pixel above threshold to see if it's brighter than it's neighbors
    %  THERE'S GOT TO BE A FASTER WAY OF DOING THIS.  I'M CHECKING SOME MULTIPLE TIMES,
    %  BUT THIS DOESN'T SEEM THAT SLOW COMPARED TO THE OTHER ROUTINES, ANYWAY.
    if r>1 && r<nr && c>1 && c<nc
        if im(r,c)>=im(r-1,c-1) && im(r,c)>=im(r,c-1) && im(r,c)>=im(r+1,c-1) && ...
         im(r,c)>=im(r-1,c)  && im(r,c)>=im(r+1,c) &&   ...
         im(r,c)>=im(r-1,c+1) && im(r,c)>=im(r,c+1) && im(r,c)>=im(r+1,c+1)
         mx=[mx,[r,c]'];  %#ok<AGROW>
         %tst(ind(i))=im(ind(i));
        end
    end
end
%out=tst;
mx=mx';

[npks,crap]=size(mx);

%if size is specified, then get ride of pks within size of boundary
if nargin==3 && npks>0
   %throw out all pks within sz of boundary;
    ind=find(mx(:,1)>sz & mx(:,1)<(nr-sz) & mx(:,2)>sz & mx(:,2)<(nc-sz));
    mx=mx(ind,:);
end

%prevent from finding peaks within size of each other
[npks,crap]=size(mx);
if npks > 1
    %CREATE AN IMAGE WITH ONLY PEAKS
    nmx=npks;
    tmp=0.*im;
    for i=1:nmx
        tmp(mx(i,1),mx(i,2))=im(mx(i,1),mx(i,2));
    end
    %LOOK IN NEIGHBORHOOD AROUND EACH PEAK, PICK THE BRIGHTEST
    for i=1:nmx
        roi=tmp( (mx(i,1)-floor(sz/2)):(mx(i,1)+(floor(sz/2)+1)),(mx(i,2)-floor(sz/2)):(mx(i,2)+(floor(sz/2)+1))) ;
        [mv,indi]=max(roi);
        [mv,indj]=max(mv);
        tmp( (mx(i,1)-floor(sz/2)):(mx(i,1)+(floor(sz/2)+1)),(mx(i,2)-floor(sz/2)):(mx(i,2)+(floor(sz/2)+1)))=0;
        tmp(mx(i,1)-floor(sz/2)+indi(indj)-1,mx(i,2)-floor(sz/2)+indj-1)=mv;
    end
    ind=find(tmp>0);
    mx=[mod(ind,nr),floor(ind/nr)+1];
end

if size(mx)==[0,0]
    out=[];
else
    out(:,2)=mx(:,1);
    out(:,1)=mx(:,2);
end
