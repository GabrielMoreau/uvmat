%'extract_rdvision': relabel an image series with two indices, and correct errors from the RDvision transfer program
%------------------------------------------------------------------------
% function ParamOut=extract_rdvision(Param)
%------------------------------------------------------------------------
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %
%%%%%%%%%%%%%%%%%%%%%%%%%%
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
% Copyright 2008-2016, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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
    ParamOut.NbSlice=1; ...%nbre of slices, 1 prevents splitting in several processes, ('off' by default)
    ParamOut.VelType='off';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';...%can use a transform function
    ParamOut.ProjObject='off';...%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';...%can use mask option   (option 'off'/'on', 'off' by default)
     ParamOut.OutputDirExt='.extract';%set the output dir extension
    ParamOut.OutputSubDirMode='one'; %output folder given by the folder name of the first input line
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
%         return
    end
    %% interactive input of specific parameters (for RDvision system)
    display('converting images from RDvision system...')
else
    msgbox_uvmat('ERROR','the input is not from rdvision: a .seq or .sqb file must be opened')
    return
end
t=xmltree;

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
checkpreserve=0;% if =1, will npreserve the original images, else it erases them at the end
for iview=1:size(Param.InputTable,1)
    for iview_xml=1:size(Param.InputTable,1)% look for the xml files in the different data directories
        filexml=[fullfile(RootPath,Param.InputTable{iview_xml,2},Param.InputTable{iview,3}) '.xml'];%new convention: xml at the level of the image folder
        if exist(filexml,'file')
            break
        end
    end
    if ~exist(filexml,'file')
        disp_uvmat('ERROR',[filexml ' missing'],checkrun)
        return
    end
 
    newxml=fullfile(RootPath,Param.InputTable{iview,3});
    newxml=regexprep(newxml,'_Master_Dalsa_4M180$','');%suppress '_Master_Dalsa_4M180'
    newxml=[newxml '.xml'];
    
    %copyfile_modif(filexml,newxml); %copy the xml file in the upper folder
    
    %[XmlData,errormsg]=imadoc2struct(newxml);
%     nbfield2=size(XmlData.Time,2)-1;
%     if nbfield2>1
%         NomTypeNew='_1_1';
%     else
%         NomTypeNew='_1';
%     end
    %% get the names of .seq and .sqb files
    switch Param.InputTable{iview,5}
        case {'.seq','.sqb'}
            filename_seq=fullfile(RootPath,Param.InputTable{iview,2},[Param.InputTable{iview,3} '.seq']);
            filename_sqb=fullfile(RootPath,Param.InputTable{iview,2},[Param.InputTable{iview,3} '.sqb']);
            logdir=[Param.OutputSubDir Param.OutputDirExt];
            [success,errormsg] = copyfile(filename_seq,[fullfile(RootPath,logdir,Param.InputTable{iview,3}) '.seq']); %copy the seq file in the upper folder
            [success,errormsg] = copyfile(filename_sqb,[fullfile(RootPath,logdir,Param.InputTable{iview,3}) '.sqb']); %copy the sqb file in the upper folder
        otherwise
            errormsg='input file extension must be .seq or .sqb';
    end
    if ~exist(filename_seq,'file')
        errormsg=[filename_seq ' does not exist'];
    end
    if ~isempty(errormsg)
        disp_uvmat('ERRROR',errormsg,checkrun);
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
    timestamp=zeros(1,numel(m.Data));
    for ii=1: numel(m.Data)
        timestamp(ii)=m.Data(ii).timestamp;
%         j1=1;
%         if ~isequal(nbfield2,1)
%             j1=mod(ii-1,nbfield2)+1;
%         end
%         i1=floor((ii-1)/nbfield2)+1;
        %diff_time(i1,j1)= timestamp(ii)-XmlData.Time(i1+1,j1+1);
    end
    [nbfield2,msg]=copyfile_modif(filexml,timestamp,newxml); %copy the xml file in the upper folder
    [XmlData,errormsg]=imadoc2struct(newxml);% check reading of the new xml file
    if ~isempty(errormsg)
        disp(errormsg)
        return
    end
    difftime=XmlData.Time(2:end,2:end)-(reshape(timestamp,nbfield2,[]))';
    disp(['time from xml and timestamp differ by ' num2str(max(max(abs(difftime))))])
    if max(abs(difftime))>0.01
        checkpreserve=1;% will not erase the initial files, possibility of error
    end
    
        %% checking consistency with the xml file
    if ~isequal(SeqData.nb_frames,numel(timestamp))
        disp_uvmat('ERRROR',['inconsistent number of images ' num2str(SeqData.nb_frames) ' with respect to the xml file: ' num2str(numel(timestamp))] ,checkrun);
        return
    end    
    
    if nbfield2>1
        NomTypeNew='_1_1';
    else
        NomTypeNew='_1';
    end

    [BinList,errormsg]=binread_rdv_series(RootPath,SeqData,m.Data,nbfield2,NomTypeNew);
    if ~isempty(errormsg)
        disp_uvmat('ERROR',errormsg,checkrun)
        return
    end
    
    % check the existence of the expected output image files (from the xml)
    FileDir=SeqData.sequencename;
     FileDir=regexprep(FileDir,'_Master_Dalsa_4M180$','');%suppress '_Master_Dalsa_4M180'
    for i1=1:numel(timestamp)/nbfield2
        for j1=1:nbfield2
            OutputFile=fullfile_uvmat(RootPath,FileDir,'img','.png',NomTypeNew,i1,[],j1);% TODO: set NomTypeNew from SeqData.mode
            try 
            A=imread(OutputFile);% check image reading (stop if error)
            catch ME
                disp(['checking ' OutputFile])
                disp(ME.message)
            end
        end
    end
end

%% remove binary files if transfer OK
    if ~checkpreserve
        for iview=1:size(Param.InputTable,1)
         fullfile(RootPath,Param.InputTable{iview,2})

        [SUCCESS,MESSAGE]=rmdir(fullfile(RootPath,Param.InputTable{iview,2}),'s')
        end
    end
delete(fullfile(RootPath,'Running.xml'))%delete the  xml file to indicate that processing is finished

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------- reads a series of bin files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [BinList,errormsg]=binread_rdv_series(PathDir,SeqData,SqbData,nbfield2,NomTypeNew)
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
BinList={};

classname=sprintf('uint%d',SeqData.bytesperpixel*8);

classname=['*' classname];
BitDepth=8*SeqData.bytesperpixel;%needed to write images (8 or 16 bits)
binrepertoire=fullfile(PathDir,SeqData.binrepertoire);
FileDir=SeqData.sequencename;
FileDir=regexprep(FileDir,'_Master_Dalsa_4M180$','');%suppress '_Master_Dalsa_4M180'
OutputDir=fullfile(PathDir,FileDir);
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
bin_file_counter=0;
for ii=1:SeqData.nb_frames
    j1=[];
    if ~isequal(nbfield2,1)
        j1=mod(ii-1,nbfield2)+1;
    end
    i1=floor((ii-1)/nbfield2)+1;
    OutputFile=fullfile_uvmat(PathDir,FileDir,'img','.png',NomTypeNew,i1,[],j1);% TODO: set NomTypeNew from SeqData.mode
    fname=fullfile(binrepertoire,sprintf('%s%.5d.bin',SeqData.binfile,SqbData(ii).file_idx));
    if exist(OutputFile,'file')% do not recreate existing image file
        fid=0;
    else
        if fid==0 || ~strcmp(fname,fname_prev) % open the bin file if not in use
            if fid~=0
                fclose(fid);%close the previous bin file if relevant
            end
            [fid,msg]=fopen(fname,'rb');
            if isequal(fid,-1)
                errormsg=['error in opening ' fname ': ' msg];
                return
            else
                disp([fname ' opened for reading'])
                bin_file_counter=bin_file_counter+1;
                BinList{bin_file_counter}=fname;
            end
            fseek(fid,SqbData(ii).offset,-1);%look at the right starting place in the bin file
            NbBinFile=NbBinFile+1;%counter of binary files (for checking purpose)
            BinSize(NbBinFile)=0;% strat counter for new bin file
        else
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




function [nbfield2,msg]=copyfile_modif(filexml,timestamp,newxml)
msg='';
t=xmltree(filexml);

%% correct NbDtj
uid_NbDtj=find(t,'ImaDoc/Camera/BurstTiming/NbDtj');
uid_content=get(t,uid_NbDtj,'contents');
t=set(t,uid_content,'value','1');% set NbDtj to 1 (correct error in the xml file)

%% check Dtj
uid_Dtj=find(t,'ImaDoc/Camera/BurstTiming/Dtj');
uid_content=get(t,uid_Dtj,'contents');
Dtj=str2num(get(t,uid_content,'value'));
nbfield2=numel(Dtj)+1;
timestamp=(reshape(timestamp,nbfield2,[]))';
diff_Dtj=diff(timestamp(1,:))-Dtj;
if max(abs(diff_Dtj))>min(Dtj)/1000
    disp(['Dtj from xml file differs from time stamp by ' num2str(max(abs(diff_Dtj))) ', '])%'
else
    disp('Dtj OK');
end

%% correct NbDti
NbDti=size(timestamp,1); %default for series or burst
uid_motor_nbslice=find(t,'ImaDoc/TranslationMotor/Nbslice');
if ~isempty(uid_motor_nbslice)
    uid_content=get(t,uid_motor_nbslice,'contents');
    NbSlice=str2num(get(t,uid_content,'value'));
    NbDti=NbSlice-1;
uid_NbDti=find(t,'ImaDoc/Camera/BurstTiming/NbDti');
uid_content=get(t,uid_NbDti,'contents');
t=set(t,uid_content,'value',num2str(NbDti));
end

%% adjust Dti
uid_Dti=find(t,'ImaDoc/Camera/BurstTiming/Dti');
uid_content=get(t,uid_Dti,'contents');
Dti=str2num(get(t,uid_content,'value'));
Dti_stamp=(timestamp(1+NbDti,1)-timestamp(1,1))/NbDti;
if abs(Dti_stamp-Dti)>Dti/1000
    disp([msg 'Dti from xml file corrected by ' num2str(Dti_stamp-Dti) ', ']);%'
else
    disp('Dti OK')
end
t=set(t,uid_content,'value',num2str(Dti_stamp));

%% adjust Dtk
uid_Dtk=find(t,'ImaDoc/Camera/BurstTiming/Dtk');
if ~isempty(uid_Dtk)
uid_content_Dtk=get(t,uid_Dtk,'contents');
Dtk=str2num(get(t,uid_content_Dtk,'value'));
uid_NbDtk=find(t,'ImaDoc/Camera/BurstTiming/NbDtk');
uid_content_NbDtk=get(t,uid_NbDtk,'contents');
NbDtk=str2num(get(t,uid_content_NbDtk,'value'));
Dtk_stamp=(timestamp(end-NbDti,1)-timestamp(1,1))/NbDtk;
if abs(Dtk_stamp-Dtk)>Dtk/1000
    disp([msg 'Dtk from xml file corrected by ' num2str(Dtk_stamp-Dtk)]);
else
    disp('Dtk OK')
end
t=set(t,uid_content_Dtk,'value',num2str(Dtk_stamp));
end

save(t,newxml)




