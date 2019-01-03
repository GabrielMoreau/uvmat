%'ima_levels': rescale the image intensity to reduce strong luminosity peaks (their blinking effects often perturbs PIV))
% this function can be used as a template for applying a transform (here 'levels.m') to each image of a series
%------------------------------------------------------------------------
% function GUI_input=ima_levels(Param)
%
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
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function ParamOut=ima_levels (Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.NbViewMax=1;% max nbre of input file series (default , no limitation)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='on';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='';%set the output dir extension
    ParamOut.OutputFileMode='NbInput';% ='=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    %check the type of the existence and type of the first input file:
    Param.IndexRange.last_i=Param.IndexRange.first_i;%keep only the first index in the series
    if isfield(Param.IndexRange,'first_j')
    Param.IndexRange.last_j=Param.IndexRange.first_j;
    end
    filecell=get_file_series(Param);
    if ~exist(filecell{1,1},'file')
        msgbox_uvmat('WARNING','the first input file does not exist')
    else
        FileInfo=get_file_info(filecell{1,1});
        FileType=FileInfo.FileType;
        if isempty(find(strcmp(FileType,{'image','multimage','mmreader','video'})));% =1 for images
            msgbox_uvmat('ERROR',['bad input file type for ' mfilename ': an image is needed'])
        end
    end
return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
%% read input parameters from an xml file if input is a file name (batch mode)
ParamOut=[];
RUNHandle=[];
WaitbarHandle=[];
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
else% interactive mode in Matlab
    hseries=findobj(allchild(0),'Tag','series');
    RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
    WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
end

%% subdirectory for output files
SubdirOut=[Param.OutputSubDir Param.OutputDirExt];

%% root input file names and nomenclature type (cell arrays with one element)
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);


%% get the set of input file names (cell array filecell), and file indices
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% filecell{iview,fileindex}: cell array representing the list of file names
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields
[FileInfo{1},VideoObject{1}]=get_file_info(filecell{1,1});% type of input file
FileType{1}=FileInfo{1}.FileType;

%% frame index for movie or multimage file input  
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

 %% Extension and indexing nomenclature for output file
 FileExtOut='.png'; % write result as .png images for image inputs
 if strcmpi(NomType{1}(end),'a')
     NomTypeOut=NomType{1};
 else
     NomTypeOut='_1_1';
 end

%% Set field names and velocity types
%not relevant for this function

%% Initiate output fields
%not relevant for this function

%% set processing parameters
% not needed for this function

%% update the xml file
% not needed for this function

%% main loop on fields
j1=[];%default
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
for ifile=1:nbfield
            update_waitbar(WaitbarHandle,ifile/nbfield)
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    if ~isempty(j1_series)&&~isequal(j1_series,{[]})
        j1=j1_series{1}(ifile);
    end
   % filename=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},NomType{1},i1_series{1}(ifile),[],j1);
    filename=filecell{ifile,1}
   filename_new=regexprep(filename,'mproj','img');
   % filename_new=fullfile_uvmat(RootPath{1},SubdirOut,'img',FileExtOut,NomTypeOut,i1_series{1}(ifile),[],j1);
    movefile(filename,filename_new);
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
