% function ParamOut=particle_tracking(Param)
%
% Method: 
   
% Organization of image indices:
    
%INPUT:
% num_i1: matrix of image indices i
% num_j1: matrix of image indices j, must be the same size as num_i1
% num_i2 and num_j2: not used for a function acting on images
% Series: matlab structure containing parameters, as defined by the interface UVMAT/series
%       Series.RootPath{1}: path to the image series
%       Series.RootFile{1}: root file name
%       Series.FileExt{1}: image file extension 
%       Series.NomType{1}: nomenclature type for file in
%
% Method: 
%       Series.NbSlice: %number of slices defined on the interface
% global A rangx0 rangy0 minA maxA; % make current image A accessible in workspace
% global hfig1 hfig2 scalar
% global Abackg nbpart lum diam
%%%%%%%%%%%%%%�
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
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function ParamOut=particle_tracking(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    % general settings of the GUI:
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.patch';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    filecell=get_file_series(Param);%check existence of the first input file
    if ~exist(filecell{1,1},'file')
        msgbox_uvmat('WARNING','the first input file does not exist') 
    end
    % parameters specific to the function 
    prompt = {'threshold value'};
    dlg_title = 'get threshold';
    num_lines= 1;
    def     = { '0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        return
    end
    ParamOut.ActionInput.LumThreshold=str2double(answer{1});
    
    return
end

%%%%%%%%%%%%  STANDARD RUN PART  %%%%%%%%%%%%
ParamOut=[];
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% define the directory for result file
OutputDir=[Param.OutputSubDir Param.OutputDirExt];

%% root input file(s) name, type and index series
RootPath=Param.InputTable{1,1};
RootFile=Param.InputTable{1,3};
SubDir=Param.InputTable{1,2};
NomType=Param.InputTable{1,4};
FileExt=Param.InputTable{1,5};
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
%%%%%%%%%%%%
% The cell array filecell is the list of input file names, while
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%%
nbview=numel(i1_series);%number of input file series (lines in InputTable)
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields

%% frame index for movie or multimage file input  
if ~isempty(j1_series{1})
    frame_index=j1_series{1};
else
    frame_index=i1_series{1};
end

%% check the input file type  
[FileInfo,VideoObject]=get_file_info(filecell{1,1});
FileType=FileInfo.FileType;
ImageTypeOptions={'image','multimage','mmreader','video','cine_phantom'};
if isempty(find(strcmp(FileType,ImageTypeOptions)))
    disp('input file not images')
    return
end

%% calibration data and timing: read the ImaDoc files
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);

%%%%%%%%%%%%   SPECIFIC PART (to edit) %%%%%%%%%%%%
%filter for particle center of mass(luminosity)

Threshold=Param.ActionInput.LumThreshold;% luminosity threshold for particle detection, < 0 for black particles, >0 for white particles

%%  fixed mask to avoid tube image
Amask=imread('/fsnet/project/coriolis/2015/15MINI_MEDDY/0_REF_FILES/mask_patch.png');

%% initiate output statistics data
Data.ListVarName={'Time','z','Area',  'MajorAxisLength' , 'MinorAxisLength'};
Data.VarDimName={'Time','z',{'Time','z'},{'Time','z'},{'Time','z'}};
Data.Time = 1:nbfield_i; %default
Data.z=1:nbfield_j;
Data.Area=zeros(nbfield_i,nbfield_j);
Data.MajorAxisLength=zeros(nbfield_i,nbfield_j);
Data.MinorAxisLength=zeros(nbfield_i,nbfield_j);

%%%%%% MAIN LOOP ON FRAMES %%%%%%
for ifile=1:nbfield
    if checkrun
        update_waitbar(WaitbarHandle,ifile/nbfield)
        if ~isempty(RUNHandle) &&ishandle(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
            disp('program stopped by user')
            return
        end
    end
    i1=i1_series{1}(ifile);
    j1=1;
    if ~isempty(j1_series)&&~isequal(j1_series,{[]})
        j1=j1_series{1}(ifile);
    end
    filename=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i1,[],j1);
    A=read_image(filename,FileType,VideoObject,frame_index(ifile));% read the current frame
    
    A=(A>Threshold) & Amask>100;%transform to binary image format
    try
        STATS = regionprops(A, 'FilledArea','MinorAxisLength','MajorAxisLength','PixelIdxList');
        Area=zeros(size(STATS));
        for iobj=1:numel(STATS)
            Area(iobj)=STATS(iobj).FilledArea;
        end
        [Data.Area(i1,j1), main_obj]=max(Area);
        Data.MajorAxisLength(i1,j1)=STATS(main_obj).MajorAxisLength;
        Data.MinorAxisLength(i1,j1)=STATS(main_obj).MinorAxisLength;
        for iobj=1:numel(STATS)
            if iobj~=main_obj
                A(STATS(iobj).PixelIdxList)=0;
            end
        end

    catch ME
        disp('image toolbox not available, program stopped')
%         return
    end
            filename_out=fullfile_uvmat(RootPath,OutputDir,RootFile,'.png',NomType,i1,[],j1);
        imwrite(255*A,filename_out,'BitDepth',8)
        disp([filename_out ' written'])
end
    
%% record time series of stat
[filename_nc,idetect]=name_generator(RootPath,OutputDir,RootFile,'.nc','_i1-i2',1,nbfield_i)
errormsg=struct2nc(filename_nc,Data);

if isempty(errormsg)
    [filename_nc ' written']
else
    disp(errormsg)
end

