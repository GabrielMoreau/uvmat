%'extract_rdvision': relabel an image series with two indices, and correct errors from the RDvision transfer program
%------------------------------------------------------------------------
% function ParamOut=extract_rdvision(Param)
%------------------------------------------------------------------------
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

%=======================================================================
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function ParamOut=extract_rdvision(Param) %default output=relabel_i_j(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';...% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='on';...% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='one'; ...%nbre of slices, 'one' prevents splitting in several processes, ('off' by default)
    ParamOut.VelType='off';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';...%can use a transform function
    ParamOut.ProjObject='off';...%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';...%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputSubDirMode='custom'; %output folder given by the program, not by the GUI series
     % detect the set of image folder
    RootPath=Param.InputTable{1,1};
    ListStruct=dir(RootPath);   
    ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
    check_bad=strcmp('.',ListCells(1,:))|strcmp('..',ListCells(1,:));%detect the dir '.' to exclude it
    check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
    ListDir=ListCells(1,find(check_dir & ~check_bad));
%     InputTable=cell(numel(ListDir),5);
%     InputTable(:,2)=ListDir';
    isel=0;
    InputTable=Param.InputTable;
    for ilist=1:numel(ListDir)
        ListStructSub=dir(fullfile(RootPath,ListDir{ilist}));
        ListCellSub=struct2cell(ListStructSub);% transform dir struct to a cell arrray
        detect_seq=regexp(ListCellSub(1,:),'.seq$');
        seq_index=find(~cellfun('isempty',detect_seq),1);
        if ~isempty(seq_index)
%             msgbox_uvmat('ERROR',['not seq file in ' ListDir{ilist} ': please check the input folders'])
%         else
           isel=isel+1;
           InputTable{isel,1}=RootPath;
           InputTable{isel,2}=ListDir{ilist};
            RootFile=regexprep(ListCellSub{1,seq_index},'.seq$','');
            InputTable{isel,3}=RootFile;
        InputTable{isel,4}='*';
        InputTable{isel,5}='.seq';
    end
    end
    hseries=findobj(allchild(0),'Tag','series');% find the parent GUI 'series'
    hhseries=guidata(hseries); %handles of the elements in 'series'
    set(hhseries.InputTable,'Data',InputTable)
    ParamOut.ActionInput.LogPath=RootPath;% indicate the path for the output info: 0_LOG ....
return
end

ParamOut=[];
%%%%%%%%%%%% STANDARD PART  %%%%%%%%%%%%
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% root input file(s) and type
RootPath=Param.InputTable{1,1};
if ~isempty(find(~strcmp(RootPath,Param.InputTable(:,1))))% if the Rootpath for each camera are not identical
    disp_uvmat('ERROR','Rootpath for all cameras must be identical',checkrun)
    return
end

% get the set of input file names (cell array filecell), and the lists of
% input file or frame indices i1_series,i2_series,j1_series,j2_series
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);

%OutputDir=[Param.OutputSubDir Param.OutputDirExt];
 
% numbers of slices and file indices
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields

%determine the file type on each line from the first input file 

FileInfo=get_file_info(filecell{1,1});
if strcmp(FileInfo.FileType,'rdvision')
    if ~isequal(FileInfo.NumberOfFrames,nbfield)
        msgbox_uvmat('ERROR',['the whole series of ' num2str(FileInfo.NumberOfFrames) ' images must be extracted at once'])
        %rmfield(OutputDir)
        return
    end
    %% interactive input of specific parameters (for RDvision system)
    display('converting images from RDvision system...')
else
    msgbox_uvmat('ERROR','the input is not from rdvision: a .seq or .sqb file must be opened')
    return
end
t=xmltree;
%%% A REMETTREE %%%%%%%%%%%%%%%%%%%%%
save(t,fullfile(RootPath,'Running.xml'))%create an xml file to indicate that processing takes place

%% calibration data and timing: read the ImaDoc files
mode=''; %default
timecell={};
itime=0;
NbSlice_calib={};

%SubDirBase=regexprep(SubDir{1},'\..*','');%take the root part of SubDir, before the first dot '.'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  loop on the cameras ( #iview)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RootPath=Param.InputTable(:,1);
% RootFile=Param.InputTable(:,3);
% SubDir=Param.InputTable(:,2);
% NomType=Param.InputTable(:,4);
% FileExt=Param.InputTable(:,5);

% [XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
% if size(time,1)>1
%     diff_time=max(max(diff(time)));
%     if diff_time>0
%         disp_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time)],checkrun)
%     end   
% end
% 
%      nbfield2=size(time,1);



for iview=1:size(Param.InputTable,1)
     filexml=[fullfile(RootPath,Param.InputTable{iview,3}) '.xml'];%new convention: xml at the level of the image folder
    if ~exist(filexml,'file')
        disp_uvmat('ERROR',[filexml ' missing'],checkrun)
        return
    end
%     %[XmlData,error]=imadoc2struct_special(filexml);
     [XmlData,error]=imadoc2struct(filexml);
%     if ~isempty(error)
%         disp(error)
%     end
%     if isfield(XmlData,'Time')
%         itime=itime+1;
%         timecell{itime}=XmlData.Time;
%     end
%     if isfield(XmlData,'GeometryCalib') && isfield(XmlData.GeometryCalib,'SliceCoord')
%         NbSlice_calib{1}=size(XmlData.GeometryCalib.SliceCoord,1);%nbre of slices for Zindex in phys transform
%         if ~isequal(NbSlice_calib{1},NbSlice_calib{1})
%             msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
%         end
%     end
    
    
%     % correction to RDvision xml file
%   t=xmltree(filexml);
%     
%     % correct Dtj and Dtk
 %    NomTypeNew='_1_1';% new file nomencalture by default
%     ImageName='img_1_1.png';% first image name
%      if isfield(XmlData,'NbDtj')
%          uid_NbDtj=find(t,'ImaDoc/Camera/BurstTiming/NbDtj');
%          uid_value=children(t,uid_NbDtj);
%         if ~isempty(uid_value)
%             t=set(t,uid_value(1),'value',num2str(XmlData.NbDtj));
%         end
%     end
%     if isfield(XmlData,'NbDtk')
%         uid_NbDtk=find(t,'ImaDoc/Camera/BurstTiming/NbDtk');
%         uid_value=children(t,uid_NbDtk);
%         if ~isempty(uid_value)
%             t=set(t,uid_value(1),'value',num2str(XmlData.NbDtk));
%         end
%     end
%     if isempty(j1_series{1}) && isfield(XmlData,'NbDti')
%         uid_Dti=find(t,'ImaDoc/Camera/BurstTiming/Dti');
%         t=add(t,uid_Dti,'chardata',num2str(XmlData.Dti));
%         uid_NbDti=find(t,'ImaDoc/Camera/BurstTiming/NbDti');
%         t=add(t,uid_NbDti,'chardata',num2str(XmlData.NbDti));
%         uid_NbDtj=find(t,'ImaDoc/Camera/BurstTiming/NbDtj');
%         uid_NbDtk=find(t,'ImaDoc/Camera/BurstTiming/NbDtk');
%         t=delete(t,uid_NbDtj);
%         t=delete(t,uid_NbDtk);
%         uid_Dtj=find(t,'ImaDoc/Camera/BurstTiming/Dtj');
%         uid_Dtk=find(t,'ImaDoc/Camera/BurstTiming/Dtk');
%         t=delete(t,uid_Dtj);
%         t=delete(t,uid_Dtk);
%         NomTypeNew='_1';
%         ImageName='img_1.png';
%     end
%     
%     %update information of 'Heading'
%     uid_Heading=find(t,'ImaDoc/Heading');
%     if isempty(uid_Heading)
%         [t,uid_Heading]=add(t,1,'element','Heading');
%     end
%     uid_SubCampaign=find(t,'ImaDoc/Heading/SubCampaign');
%     if ~isempty(uid_SubCampaign), t=delete(t,uid_SubCampaign); end
%     uid_Experiment=find(t,'ImaDoc/Heading/Experiment');
%     if ~isempty(uid_Experiment), t=delete(t,uid_Experiment); end
%     uid_Device=find(t,'ImaDoc/Heading/Device');
%     if ~isempty(uid_Device), t=delete(t,uid_Device); end
%     uid_Record=find(t,'ImaDoc/Heading/Record');
%     if ~isempty(uid_Record), t=delete(t,uid_Record); end
%     uid_DateExp=find(t,'ImaDoc/Heading/DateExp');
%     if ~isempty(uid_DateExp), t=delete(t,uid_DateExp); end
%     
%     %indicate the name of the first image (as a check that the xml file is not moved)
%     uid_ImageName=find(t,'ImaDoc/Heading/ImageName');
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
%     %indicate the date and time of the image acquisition start
%     % if isfield(FileInfo,'binrepertoire') && isfield(FileInfo,'starttime')
%     %     sep_pos=regexp(FileInfo.binrepertoire,'T');
%     %     DateTime=FileInfo.starttime;
%     %     if ~isempty(sep_pos)
%     %         DateTime=[FileInfo.binrepertoire(1:sep_pos-1) ' ' DateTime];
%     %     end
%     %     uid_DateTime=find(t,'ImaDoc/Heading/DateTime');
%     %     if isempty(uid_DateTime)
%     %         [t,uid_DateTime]=add(t,uid_Heading,'element','DateTime');
%     %     end
%     %     uid_value=children(t,uid_DateTime);
%     %     if isempty(uid_value)
%     %         t=add(t,uid_DateTime,'chardata',DateTime);%indicate  name of the first image, with ;png extension
%     %     else
%     %         t=set(t,uid_value(1),'value',DateTime);%indicate  name of the first image, with ;png extension
%     %     end
%     % end
%     
%     %% backup the previous xml file and save the corrected one
% %    [success,message]=copyfile(filexml,[filexml '~']);%make backup
% %     if success~=1
% %         disp(['errror in xml file backup: ' message]);
% %         return
% %     end
%     save(t,filexml)

    nbfield2=size(XmlData.Time,2)-1;
    if nbfield2>1
        NomTypeNew='_1_1';
    else
         NomTypeNew='_1';
    end
    %% get the names of .seq and .sqb files
    switch Param.InputTable{iview,5}
        case {'.seq','.sqb'}
            filename_seq=fullfile(RootPath,Param.InputTable{iview,2},[Param.InputTable{iview,3} '.seq']);
            filename_sqb=fullfile(RootPath,Param.InputTable{iview,2},[Param.InputTable{iview,3} '.sqb']);
        otherwise
            errormsg='input file extension must be .seq or .sqb';
    end
    if ~exist(filename_seq,'file')
        errormsg=[filename_seq ' does not exist'];
        return
    end
    
    %% get data from .seq file
    s=ini2struct(filename_seq);
    SeqData=s.sequenceSettings;
    SeqData.width=str2double(SeqData.width);
    SeqData.height=str2double(SeqData.height);
    SeqData.bytesperpixel=str2double(SeqData.bytesperpixel);
    SeqData.nb_frames=str2double(s.sequenceSettings.numberoffiles);
    if isempty(SeqData.binrepertoire)%used when binrepertoire empty, strange feature of rdvision
        SeqData.binrepertoire=regexprep(s.sequenceSettings.bindirectory,'\\$','');%tranform Windows notation to Linux
        SeqData.binrepertoire=regexprep(SeqData.binrepertoire,'\','/');
        [tild,binrepertoire,DirExt]=fileparts(SeqData.binrepertoire);
        SeqData.binrepertoire=[SeqData.binrepertoire DirExt];
    end
%     PathDir=fileparts(PathDir);
    
    %% reading the .sqb file
    m = memmapfile(filename_sqb,'Format', { 'uint32' [1 1] 'offset'; ...
        'uint32' [1 1] 'garbage1';...
        'double' [1 1] 'timestamp';...
        'uint32' [1 1] 'file_idx';...
        'uint32' [1 1] 'garbage2' },'Repeat',SeqData.nb_frames);
    
    %%%%%%%BRICOLAGE in case of unreadable .sqb file: remplace lecture du fichier
%         ind=[111 114:211];%indices of bin files
%         w=1024;%w=width of images in pixels
%         h=1024;%h=height of images in pixels
%         bpp=2;% nbre of bytes per pixel
%         lengthimage=w*h*bpp;% lengthof an image record on the binary file
%         nbimages=32; %nbre of images of each camera in a bin file 
%         for ii=1:32*numel(ind)
%             data(ii).offset=mod(ii-1,32)*2*lengthimage+lengthimage;%Dalsa_2
%             %data(ii).offset=mod(ii-1,32)*2*lengthimage;%Dalsa_1
%             data(ii).file_idx=ind(ceil(ii/32));
%             data(ii).timestamp=0.2*(ii-1);
%         end
%         m.Data=data;
    %%%%%%%
    
    for ii=1: numel(m.Data)
        timestamp(ii)=m.Data(ii).timestamp;
    end
    %timestamp %todo: check withDt from the xml file
    [BinSize,errormsg]=binread_rdv_series(RootPath,SeqData,m.Data,nbfield2,NomTypeNew)
    if ~isempty(errormsg)
        disp_uvmat('ERROR',errormsg,checkrun)
        return
    end
end
delete(fullfile(RootPath,'Running.xml'))%delete the  xml file to indicate that processing is finished

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------- reads a series of bin files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [BinSize,errormsg]=binread_rdv_series(PathDir,SeqData,SqbData,nbfield2,NomTypeNew)
% BINREAD_RDV Permet de lire les fichiers bin g�n�r�s par Hiris � partir du
% fichier seq associ�.
%   [IMGS,TIMESTAMPS,NB_FRAMES] = BINREAD_RDV(FILENAME,FRAME_IDX) lit
%   l'image d'indice FRAME_IDX de la s�quence FILENAME.
%
%   Entr�es
%   -------
%   FILENAME  : Nom du fichier s�quence (.seq).
%   FRAME_IDX : Indice de l'image � lire. Si FRAME_IDX vaut -1 alors la
%   s�quence est enti�rement lue. Si FRAME_IDX est un tableau d'indices
%   alors toutes les images d'incides correspondant sont lues. Si FRAME_IDX
%   est un tableau vide alors aucune image n'est lue mais le nombre
%   d'images et tous les timestamps sont renvoy�s. Les indices commencent �
%   1 et se termines � NB_FRAMES.
%
%   Sorties
%   -------
%   IMGS        : Images de sortie.
%   TIMESTAMPS  : Timestaps des images lues.
%   NB_FRAMES   : Nombres d'images dans la s�quence.
NbBinFile=0;
BinSize=0;
fid=0;
errormsg='';
classname=sprintf('uint%d',SeqData.bytesperpixel*8);

classname=['*' classname];
BitDepth=8*SeqData.bytesperpixel;%needed to write images (8 or 16 bits)
binrepertoire=fullfile(PathDir,SeqData.binrepertoire);
OutputDir=fullfile(PathDir,SeqData.sequencename);
if ~exist(OutputDir,'dir')
    %     errormsg=[OutputDir ' already exist, delete it first'];
    %     return
    % end
    [s,errormsg]=mkdir(OutputDir);
    
    if s==0
        disp(errormsg)
        return%not able to create new image dir
    end
end
for ii=1:SeqData.nb_frames
    j1=[];
    if ~isequal(nbfield2,1)
        j1=mod(ii-1,nbfield2)+1;
    end
    i1=floor((ii-1)/nbfield2)+1;
    OutputFile=fullfile_uvmat(PathDir,SeqData.sequencename,'img','.png',NomTypeNew,i1,[],j1);% TODO: set NomTypeNew from SeqData.mode
    fname=fullfile(binrepertoire,sprintf('%s%.5d.bin',SeqData.binfile,SqbData(ii).file_idx));
    if exist(OutputFile,'file')
        fid=0;
    else
        if fid==0 || ~strcmp(fname,fname_prev) % open the bin file if not in use
            if fid~=0
                fclose(fid);%close the previous bin file if relevant
            end
            [fid,msg]=fopen(fname,'rb');
            if isequal(fid,-1)
                disp(['error in opening ' fname ': ' msg])
            else
                disp([fname ' opened for reading'])
            end
            fseek(fid,SqbData(ii).offset,-1);%look at the right starting place in the bin file
            NbBinFile=NbBinFile+1;%counter of binary files (for checking purpose)
            BinSize(NbBinFile)=0;% strat counter for new bin file
        else
            %             fclose(fid);%close the previous bin file
            %             fid=fopen(fname,'rb');% open the new bin file
            fseek(fid,SqbData(ii).offset,-1);%look at the right starting place in the bin file
        end
        fname_prev=fname;
        A=reshape(fread(fid,SeqData.width*SeqData.height,classname),SeqData.width,SeqData.height);%read the current image
        A=A';
        BinSize(NbBinFile)=BinSize(NbBinFile)+SeqData.width*SeqData.height*SeqData.bytesperpixel*8; %record bits read
        try
            imwrite(A,OutputFile,'BitDepth',BitDepth) % case of 16 bit images
            disp([OutputFile ' written']);
            % [s,errormsg] = fileattrib(OutputFile,'-w','a'); %set images to read only '-w' for all users ('a')
            %         if ~s
            % %             disp_uvmat('ERROR',errormsg,checkrun);
            %             return
            %         end
        catch ME
            errormsg=ME.message;
            return
        end
    end
end
if fid~=0
fclose(fid)
end




% for ifile=1:nbfield
%             update_waitbar(WaitbarHandle,ifile/nbfield)
%     if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
%         disp('program stopped by user')
%         break
%     end
%     [A,FileInfo,timestamps]=read_rdvision(filename,ifile);
%     if ifile==1
%         classA=class(A);
%         if strcmp(classA,'uint8')
%             BitDepth=8;
%         else
%         BitDepth=16;
%         end
%     end
%     j1=[];
%     if ~isequal(nbfield2,1)
%     j1=mod(ifile-1+first_label,nbfield2)+1;
%     end
%     i1=floor((ifile-1+first_label)/nbfield2)+1;
%     OutputFile=fullfile_uvmat(RootPath{1},OutputDir,'img','.png',NomTypeNew,i1,[],j1);
%     try
%         imwrite(A,OutputFile,'BitDepth',BitDepth) % case of 16 bit images
%     disp([OutputFile ' written']);
%         [s,errormsg] = fileattrib(OutputFile,'-w','a'); %set images to read only '-w' for all users ('a')
%         if ~s
%             disp_uvmat('ERROR',errormsg,checkrun);
%             return
%         end
%     catch ME
%         disp_uvmat('ERROR',ME.message,checkrun);
%         return
%     end
%
% end

%'imadoc2struct_special': reads the xml file for image documentation
%------------------------------------------------------------------------
% function [s,errormsg]=imadoc2struct_special(ImaDoc,option)
%
% OUTPUT:
% s: structure representing ImaDoc
%   s.Heading: information about the data hierarchical structure
%   s.Time: matrix of times
%   s.TimeUnit
%  s.GeometryCalib: substructure containing the parameters for geometric calibration
% errormsg: error message
%
% INPUT:
% ImaDoc: full name of the xml input file with head key ImaDoc
% option: ='GeometryCalib': read  the data of GeometryCalib, including source point coordinates

function [s,errormsg]=imadoc2struct_special(ImaDoc,option) 

%% default input and output
if ~exist('option','var')
    option='*';
end
errormsg=[];%default
s.Heading=[];%default
s.Time=[]; %default
s.TimeUnit=[]; %default
s.GeometryCalib=[];
tsai=[];%default

%% opening the xml file
if exist(ImaDoc,'file')~=2, errormsg=[ ImaDoc ' does not exist']; return;end;%input file does not exist
try
    t=xmltree(ImaDoc);
catch
    errormsg={[ImaDoc ' is not a valid xml file']; lasterr};
    display(errormsg);
    return
end
uid_root=find(t,'/ImaDoc');
if isempty(uid_root), errormsg=[ImaDoc ' is not an image documentation file ImaDoc']; return; end;%not an ImaDoc .xml file


%% Heading
uid_Heading=find(t,'/ImaDoc/Heading');
if ~isempty(uid_Heading), 
    uid_Campaign=find(t,'/ImaDoc/Heading/Campaign');
    uid_Exp=find(t,'/ImaDoc/Heading/Experiment');
    uid_Device=find(t,'/ImaDoc/Heading/Device');
    uid_Record=find(t,'/ImaDoc/Heading/Record');
    uid_FirstImage=find(t,'/ImaDoc/Heading/ImageName');
    s.Heading.Campaign=get(t,children(t,uid_Campaign),'value');
    s.Heading.Experiment=get(t,children(t,uid_Exp),'value');
    s.Heading.Device=get(t,children(t,uid_Device),'value');
    if ~isempty(uid_Record)
        s.Heading.Record=get(t,children(t,uid_Record),'value');
    end
    s.Heading.ImageName=get(t,children(t,uid_FirstImage),'value');
end

%% Camera  and timing
if strcmp(option,'*') || strcmp(option,'Camera')
    uid_Camera=find(t,'/ImaDoc/Camera');
    if ~isempty(uid_Camera)
        uid_ImageSize=find(t,'/ImaDoc/Camera/ImageSize');
        if ~isempty(uid_ImageSize);
            ImageSize=get(t,children(t,uid_ImageSize),'value');
            xindex=findstr(ImageSize,'x');
            if length(xindex)>=2
                s.Npx=str2double(ImageSize(1:xindex(1)-1));
                s.Npy=str2double(ImageSize(xindex(1)+1:xindex(2)-1));
            end
        end
        uid_TimeUnit=find(t,'/ImaDoc/Camera/TimeUnit');
        if ~isempty(uid_TimeUnit)
            s.TimeUnit=get(t,children(t,uid_TimeUnit),'value');
        end
        uid_BurstTiming=find(t,'/ImaDoc/Camera/BurstTiming');
        if ~isempty(uid_BurstTiming)
            for k=1:length(uid_BurstTiming)
                subt=branch(t,uid_BurstTiming(k));%subtree under BurstTiming
                % reading Dtk
                Frequency=get_value(subt,'/BurstTiming/FrameFrequency',1);
                Dtj=get_value(subt,'/BurstTiming/Dtj',[]);
                Dtj=Dtj/Frequency;%Dtj converted from frame unit to TimeUnit (e.g. 's')
                NbDtj=get_value(subt,'/BurstTiming/NbDtj',[]);
                %%%% correction RDvision %%%%
%                 NbDtj=NbDtj/numel(Dtj);
%                 s.NbDtj=NbDtj;
%                 %%%%
                Dti=get_value(subt,'/BurstTiming/Dti',[]);
                NbDti=get_value(subt,'/BurstTiming/NbDti',1);
                 %%%% correction RDvision %%%%
                if isempty(Dti)% series 
                     Dti=Dtj;
                      NbDti=NbDtj;
                     Dtj=[];
                     s.Dti=Dti;
                     s.NbDti=NbDti;
                else
                    % NbDtj=NbDtj/numel(Dtj);%bursts
                    if ~isempty(NbDtj)
                    s.NbDtj=NbDtj/numel(Dtj);%bursts;
                    else
                        s.NbDtj=1;
                    end
                end
                %%%% %%%%
                Dti=Dti/Frequency;%Dtj converted from frame unit to TimeUnit (e.g. 's')

                Time_val=get_value(subt,'/BurstTiming/Time',0);%time in TimeUnit
                if ~isempty(Dti)
                    Dti=reshape(Dti'*ones(1,NbDti),NbDti*numel(Dti),1); %concatene Dti vector NbDti times
                    Time_val=[Time_val;Time_val(end)+cumsum(Dti)];%append the times defined by the intervals  Dti
                end
                if ~isempty(Dtj)
                    Dtj=reshape(Dtj'*ones(1,s.NbDtj),1,s.NbDtj*numel(Dtj)); %concatene Dtj vector NbDtj times
                    Dtj=[0 Dtj];
                    Time_val=Time_val*ones(1,numel(Dtj))+ones(numel(Time_val),1)*cumsum(Dtj);% produce a time matrix with Dtj
                end
                % reading Dtk
                Dtk=get_value(subt,'/BurstTiming/Dtk',[]);
                NbDtk=get_value(subt,'/BurstTiming/NbDtk',1);
                %%%% correction RDvision %%%%
                if ~isequal(NbDtk,1)
                    NbDtk=-1+(NbDtk+1)/(NbDti+1);
                end
                s.NbDtk=NbDtk;
                %%%%%
                if isempty(Dtk)
                    s.Time=[s.Time;Time_val];
                else
                    for kblock=1:NbDtk+1
                        Time_val_k=Time_val+(kblock-1)*Dtk;
                        s.Time=[s.Time;Time_val_k];
                    end
                end
            end
        end
    end
end

%% motor
if strcmp(option,'*') || strcmp(option,'GeometryCalib')
    uid_subtree=find(t,'/ImaDoc/TranslationMotor');
    if length(uid_subtree)==1
        subt=branch(t,uid_subtree);%subtree under GeometryCalib
       [s.TranslationMotor,errormsg]=read_subtree(subt,{'Nbslice','ZStart','ZEnd'},[1 1 1],[1 1 1]);
    end 
end
%%  geometric calibration
if strcmp(option,'*') || strcmp(option,'GeometryCalib')
    uid_GeometryCalib=find(t,'/ImaDoc/GeometryCalib');
    if ~isempty(uid_GeometryCalib)
        if length(uid_GeometryCalib)>1
            errormsg=['More than one GeometryCalib in ' filecivxml];
            return
        end
        subt=branch(t,uid_GeometryCalib);%subtree under GeometryCalib
        cont=get(subt,1,'contents');
        if ~isempty(cont)
            uid_CalibrationType=find(subt,'/GeometryCalib/CalibrationType');
            if isequal(length(uid_CalibrationType),1)
                tsai.CalibrationType=get(subt,children(subt,uid_CalibrationType),'value');
            end
            uid_CoordUnit=find(subt,'/GeometryCalib/CoordUnit');
            if isequal(length(uid_CoordUnit),1)
                tsai.CoordUnit=get(subt,children(subt,uid_CoordUnit),'value');
            end
            uid_fx_fy=find(subt,'/GeometryCalib/fx_fy');
            focal=[];%default fro old convention (Reg Wilson)
            if isequal(length(uid_fx_fy),1)
                tsai.fx_fy=str2num(get(subt,children(subt,uid_fx_fy),'value'));
            else %old convention (Reg Wilson)
                uid_focal=find(subt,'/GeometryCalib/focal');
                uid_dpx_dpy=find(subt,'/GeometryCalib/dpx_dpy');
                uid_sx=find(subt,'/GeometryCalib/sx');
                if ~isempty(uid_focal) && ~isempty(uid_dpx_dpy) && ~isempty(uid_sx)
                    dpx_dpy=str2num(get(subt,children(subt,uid_dpx_dpy),'value'));
                    sx=str2num(get(subt,children(subt,uid_sx),'value'));
                    focal=str2num(get(subt,children(subt,uid_focal),'value'));
                    tsai.fx_fy(1)=sx*focal/dpx_dpy(1);
                    tsai.fx_fy(2)=focal/dpx_dpy(2);
                end
            end
            uid_Cx_Cy=find(subt,'/GeometryCalib/Cx_Cy');
            if ~isempty(uid_Cx_Cy)
                tsai.Cx_Cy=str2num(get(subt,children(subt,uid_Cx_Cy),'value'));
            end
            uid_kc=find(subt,'/GeometryCalib/kc');
            if ~isempty(uid_kc)
                tsai.kc=str2double(get(subt,children(subt,uid_kc),'value'));
            else %old convention (Reg Wilson)
                uid_kappa1=find(subt,'/GeometryCalib/kappa1');
                if ~isempty(uid_kappa1)&& ~isempty(focal)
                    kappa1=str2double(get(subt,children(subt,uid_kappa1),'value'));
                    tsai.kc=-kappa1*focal*focal;
                end
            end
            uid_Tx_Ty_Tz=find(subt,'/GeometryCalib/Tx_Ty_Tz');
            if ~isempty(uid_Tx_Ty_Tz)
                tsai.Tx_Ty_Tz=str2num(get(subt,children(subt,uid_Tx_Ty_Tz),'value'));
            end
            uid_R=find(subt,'/GeometryCalib/R');
            if ~isempty(uid_R)
                RR=get(subt,children(subt,uid_R),'value');
                if length(RR)==3
                    tsai.R=[str2num(RR{1});str2num(RR{2});str2num(RR{3})];
                end
            end
            
            %look for laser plane definitions
            uid_Angle=find(subt,'/GeometryCalib/PlaneAngle');
            uid_Pos=find(subt,'/GeometryCalib/SliceCoord');
            if isempty(uid_Pos)
                uid_Pos=find(subt,'/GeometryCalib/PlanePos');%old convention
            end
            if ~isempty(uid_Angle)
                tsai.PlaneAngle=str2num(get(subt,children(subt,uid_Angle),'value'));
            end
            if ~isempty(uid_Pos)
                for j=1:length(uid_Pos)
                    tsai.SliceCoord(j,:)=str2num(get(subt,children(subt,uid_Pos(j)),'value'));
                end
                uid_DZ=find(subt,'/GeometryCalib/SliceDZ');
                uid_NbSlice=find(subt,'/GeometryCalib/NbSlice');
                if ~isempty(uid_DZ) && ~isempty(uid_NbSlice)
                    DZ=str2double(get(subt,children(subt,uid_DZ),'value'));
                    NbSlice=get(subt,children(subt,uid_NbSlice),'value');
                    if isequal(NbSlice,'volume')
                        tsai.NbSlice='volume';
                        NbSlice=NbDtj+1;
                    else
                        tsai.NbSlice=str2double(NbSlice);
                    end
                    tsai.SliceCoord=ones(NbSlice,1)*tsai.SliceCoord+DZ*(0:NbSlice-1)'*[0 0 1];
                end
            end   
            tsai.SliceAngle=get_value(subt,'/GeometryCalib/SliceAngle',[0 0 0]);
            tsai.VolumeScan=get_value(subt,'/GeometryCalib/VolumeScan','n');
            tsai.InterfaceCoord=get_value(subt,'/GeometryCalib/InterfaceCoord',[0 0 0]);
            tsai.RefractionIndex=get_value(subt,'/GeometryCalib/RefractionIndex',1);
            
            if strcmp(option,'GeometryCalib')
                tsai.PointCoord=get_value(subt,'/GeometryCalib/SourceCalib/PointCoord',[0 0 0 0 0]);
            end
            s.GeometryCalib=tsai;
        end
    end
end

%--------------------------------------------------
%  read a subtree
% INPUT: 
% t: xltree
% head_element: head elelemnt of the subtree
% Data, structure containing 
%    .Key: element name
%    .Type: type of element ('charg', 'float'....)
%    .NbOccur: nbre of occurrence, NaN for un specified number 
function [s,errormsg]=read_subtree(subt,Data,NbOccur,NumTest)
%--------------------------------------------------
s=[];%default
errormsg='';
head_element=get(subt,1,'name');
    cont=get(subt,1,'contents');
    if ~isempty(cont)
        for ilist=1:length(Data)
            uid_key=find(subt,[head_element '/' Data{ilist}]);
            if ~isequal(length(uid_key),NbOccur(ilist))
                errormsg=['wrong number of occurence for ' Data{ilist}];
                return
            end
            for ival=1:length(uid_key)
                val=get(subt,children(subt,uid_key(ival)),'value');
                if ~NumTest(ilist)
                    eval(['s.' Data{ilist} '=val;']);
                else
                    eval(['s.' Data{ilist} '=str2double(val);'])
                end
            end
        end
    end


%--------------------------------------------------
%  read an xml element
function val=get_value(t,label,default)
%--------------------------------------------------
val=default;
uid=find(t,label);%find the element iud(s)
if ~isempty(uid) %if the element named label exists
   uid_child=children(t,uid);%find the children 
   if ~isempty(uid_child)
       data=get(t,uid_child,'type');%get the type of child
       if iscell(data)% case of multiple element
           for icell=1:numel(data)
               val_read=str2num(get(t,uid_child(icell),'value'));
               if ~isempty(val_read)
                   val(icell,:)=val_read;
               end
           end
%           val=val';
       else % case of unique element value
           val_read=str2num(get(t,uid_child,'value'));
           if ~isempty(val_read)
               val=val_read;
           else
              val=get(t,uid_child,'value');%char string data
           end
       end
   end
end




