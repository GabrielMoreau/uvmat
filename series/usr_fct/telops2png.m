%'check_field_series': checks the existence and type of the input file series
%------------------------------------------------------------------------
% function GUIParam=check_data_files(Param)
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%OUTPUT
% GUISeriesParam=list of options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% In the absence of input (as activated when the current Action is selected
% in series), the function ouput GUI_input set the activation of the needed GUI elements

function GUIParam=telops2png(Param)

GUIParam=[];

%% input preparation mode (no RUN)
if isstruct(Param) && isequal(Param.Action.RUN,0)
    GUIParam.OutputSubDirMode='auto'; %(options 'none'/'custom'/'auto'/'first'/'last','auto' by default)  
    GUIParam.OutputDirExt='.png';%set the output dir extension
     msgbox_uvmat('CONFIMATION','this function will copy the telops fields as png images')
    return
end
%------------------------------------------------------------------------

%% read input parameters from an xml file if input is a file name (batch mode)
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
end

%% root input file(s) and type
RootPath=Param.InputTable{1,1};
SubDir=Param.InputTable{1,2};
RootFile=Param.InputTable{1,3};
NomType=Param.InputTable{1,4};
FileExt=Param.InputTable{1,5};

%% File relabeling documented by the xml file
CheckRelabel=isfield(Param.IndexRange,'Relabel' )&& Param.IndexRange.Relabel;%=true for index relabeling (PCO);

%% Input file info
if CheckRelabel
    XmlFileName=find_imadoc(RootPath,SubDir);
    if ~isempty(XmlFileName)
        XmlData=imadoc2struct(XmlFileName);%read the time from XmlFileName
    end
    RootFileOut='frame';
    [RootFile,frame_index]=index2filename(XmlData.FileSeries,Param.IndexRange.first_i,j_indices(1),NbField_j);
    FirstFileName=fullfile(RootPath,SubDir,RootFile);
else
    FirstFileName=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,Param.IndexRange.first_i,[],j_indices(1));%get first file name
    RootFileOut=RootFile;
end
[FileInfo,MovieObject]=get_file_info(FirstFileName);
FileType=FileInfo.FileType;
if ~CheckRelabel
    if isfield(FileInfo,'NumberOfFrames') && FileInfo.NumberOfFrames >1
        if isempty(regexp(NomType,'1$', 'once'))% no file indexing
            frame_index=i_indices;% the index i denotes the frame number in a movie, no index j
        else
            frame_index=j_indices;% the index j denotes the frame number in a movie
            MovieObject=[]; %not a single video object
        end
    else
        frame_index=ones(1,nbfield);
    end
end

%% output file naming
if strcmp(FileInfo.FileType,'image')
    NomTypeOut=NomType;
elseif NbField_j==1
    NomTypeOut='_1';
else
    NomTypeOut='_1_1';% case of purely numerical indexing
end
OutputDir=[Param.OutputSubDir Param.OutputDirExt];
OutputPath=fullfile(Param.OutputPath,Param.Experiment,Param.Device);









%% scans the series indexed with i and j
i_index=Param.IndexRange.first_i:Param.IndexRange.incr_i:Param.IndexRange.last_i;

FileCell=cell(numel(j_index),numel(i_index));%initiate cell array of input file names
for ifile=1:numel(i_index)
  
        FullFileName=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i_index(ifile),[],j_index(jfile));
        FileName=fullfile_uvmat('','',RootFile,FileExt,NomType,i_index(ifile),[],j_index(jfile));%name without path
        if exist(FullFileName,'file')
            FileInfo=get_file_info(FullFileName);% get the info on the file          
            FileCell{jfile,ifile}=[FileName ': ' FileInfo.FileType];
        else
            FileCell{jfile,ifile}=[FileName ': missing'];
        end

end

%% transform cell arrays into text and display in workspace
OutputText = strjoin(FileCell, '\n'); %transform cell arrays into text
disp(OutputText) %display the list of files

%% save the list in the appropriate output folder
OutputPath=fullfile(Param.OutputPath,Param.Experiment,Param.Device);
OutputSubDir=[Param.OutputSubDir Param.OutputDirExt];
FullOutputFile=fullfile_uvmat(OutputPath,OutputSubDir,RootFile,'.txt','1-2',i_index(1),i_index(end))
writelines(OutputText,FullOutputFile);

'END'

