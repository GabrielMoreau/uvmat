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

function GUIParam=check_field_series(Param)

GUIParam=[];

%% input preparation mode (no RUN)
if isstruct(Param) && isequal(Param.Action.RUN,0)
    GUIParam.OutputSubDirMode='auto'; %(options 'none'/'custom'/'auto'/'first'/'last','auto' by default)  
    GUIParam.OutputDirExt='.check_fields';%set the output dir extension
     msgbox_uvmat('CONFIMATION','This function will check the series of input fields')
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

%% scans the series indexed with i and j
i_index=Param.IndexRange.first_i:Param.IndexRange.incr_i:Param.IndexRange.last_i;
j_index=Param.IndexRange.first_j:Param.IndexRange.incr_j:Param.IndexRange.last_j;
FileCell=cell(numel(j_index),numel(i_index));%initiate cell array of input file names
for ifile=1:numel(i_index)
    for jfile=1:numel(j_index)
        FullFileName=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i_index(ifile),[],j_index(jfile));
        FileName=fullfile_uvmat('','',RootFile,FileExt,NomType,i_index(ifile),[],j_index(jfile));%name without path
        if exist(FullFileName,'file')
            FileInfo=get_file_info(FullFileName);% get the info on the file          
            FileCell{jfile,ifile}=[FileName ': ' FileInfo.FileType];
        else
            FileCell{jfile,ifile}=[FileName ': missing'];
        end
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

