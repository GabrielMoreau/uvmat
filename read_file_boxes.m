%------------------------------------------------------------------------
% --- read the data displayed for the input rootfile windows 
%------------------------------------------------------------------------
function [RootPath,SubDir,RootFile,FileIndices,FileExt,NomType]=read_file_boxes(handles)

InputFile=read_GUI(handles.InputFile);
RootPath=InputFile.RootPath;
SubDir=regexprep(InputFile.SubDir,'/|\','');
RootFile=regexprep(InputFile.RootFile,'/|\','');
FileIndices=InputFile.FileIndex;
FileExt=InputFile.FileExt;
NomType=InputFile.NomType;