%'scan_file_series': check the content of an input file and find the corresponding file series
%--------------------------------------------------------------------------
% function [RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileInfo,Object,i1_input,i2_input,j1_input,j2_input]=find_file_series(FilePath,fileinput)
%
% OUTPUT:
% RootPath: path to the dir containing the input file
% SubDir: data dir containing the input file series
% RootFile: root file detected in fileinput, possibly modified for movies (indexing is then done on image view, not file)
% i1_series(pair,ref_j+1, ref_i+1): set of indices i1 sorted by ref index ref_i, ref_j, and pair index in case of multiple pairs with the same ref.
%     (ref_i+1 is used to deal with the image index zero sometimes used)
% i2_series,j1_series,j2_series: same as i1_series but for the indices i2,j1,j2.
%  
% NomType: nomenclature type corrected after checking the first file (problem of 0 before the number string)
% FileInfo: structure containing info on the input files (assumed identical on the whole series)
% FileInfo.FileType: type of file, =
%       = 'image', usual image as recognised by Matlab
%       = 'multimage', image series stored in a single file
%       = 'civx', netcdf file with civx convention
%       = 'civdata', civ data with new convention
%       = 'netcdf' other netcdf files
%       = 'video': movie recognised by VideoReader (e;g. avi)
% MovieObject: video object (=[] otherwise
% i1_input,i2_input,j1_input,j2_input: indices of the input file, or of the first file in the series if the input file does not exist
%
%INPUT
% FilePath: path to the directory to be scanned
% fileinput: name (without path) of the input file sample

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

function [RootPath,SubDir,RootFile,i1_list,i2_list,j1_list,j2_list,NomType,FileInfo,MovieObject,i1_input,i2_input,j1_input,j2_input]=scan_file_series(FilePath,fileinput)
%------------------------------------------------------------------------

%% get input root name and info on the input file
if isempty(regexp(FilePath,'^http://','once'))% case of usual file input
  fullfileinput=fullfile(FilePath,fileinput);% input file name with path
else
  fullfileinput=[FilePath '/' fileinput]; % case of web input
end
[FileInfo,MovieObject]=get_file_info(fullfileinput);

%% default output
[RootPath,SubDir,RootFile,i1_input,i2_input,j1_input,j2_input,~,NomType]=fileparts_uvmat(fullfileinput);
i1_list=i1_input;
i2_list=i2_input;
j1_list=j1_input;
j2_list=j2_input;
if isempty(regexp(FilePath,'^http://', 'once')) && ~exist(FilePath,'dir')
    return % don't go further if the dir path does not exist
end
if isempty(NomType)||strcmp(NomType,'*')
    if exist_file(fullfileinput)
        [~,RootFile]=fileparts(fileinput);% case of constant name (no indexing), get the filename without its extension
    else
        RootFile='';
    end
else  % scan the directory of FilePath to detect file indices
    detect_string=get_search_string(NomType);% get the search string for regexp from the name NomType
    ListStruct=dir_uvmat(FilePath);% scan the content of the folder FilePath
    ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
    ListFiles=ListCells(1,:);%list of file names
    rr=regexp(ListFiles,detect_string,'names');
    nbpair=numel(rr);
    if nbpair==0% no detected file
        RootFile='';
    end
    % scan the list of relevant files, extract the indices
    i1_list=nan(nbpair,1);
    j1_list=nan(nbpair,1);
    i2_list=nan(nbpair,1);
    j2_list=nan(nbpair,1);
    for ifile=1:nbpair
        if ~isempty(rr{ifile})
            i1_list(ifile)=str2double(rr{ifile}.i1);
            i2_list=str2double(regexprep(rr{ifile}.i2,'^-',''));
            j1_list(ifile)=stra2double(regexprep(rr{ifile}.j1,'^_',''));
            j2_list(ifile)=stra2double(regexprep(rr{ifile}.j2,'^-',''));
        end
    end
     % update the nom type if the input file does not exist (pb of 0001)
    [i1_min,ifile_min]=min(i1_list);
    [~,~,~,~,~,~,~,~,NomType]=fileparts_uvmat(ListFiles{ifile_min});% update the representation of indices (number of 0 before the number)      
    if isempty(FileInfo.FileName)% get file info if the input file does not exist
        [FileInfo,MovieObject]=get_file_info(fullfile(FilePath,ListFiles{ind_select(ifile_min)}));
    end
end

% 
% 
% %% introduce the frame index in case of movies or multimage type
% if isfield(FileInfo,'NumberOfFrames') && FileInfo.NumberOfFrames >1
%     if isempty(i1_series)% if there is no file index, i denotes the frame index
%         i1_series=zeros(FileInfo.NumberOfFrames+1,2);% first column =0
%         i1_series(:,2)=(0:FileInfo.NumberOfFrames)'; % second column=frame index -1
%         i1_input=1;
%         NomType='*';
%     else  % if there is a file index, j denotes the frame index while i denotes the file index
%         if ~isempty(regexp(NomType,'ab$', 'once'))% recognized as a pair
%             RootFile=fullfile_uvmat('','',RootFile,'',NomType,i1_input,i2_input,j1_input,j2_input);% restitute the root name without the detected indices
%             i1_series=zeros(FileInfo.NumberOfFrames+1,2);% first column =0
%             i1_series(:,2)=(0:FileInfo.NumberOfFrames)'; % second column=frame index -1
%             j1_series=[];
%             i1_input=1;
%             NomType='*';
%         else
%             i1_series=i1_series(:,2)*ones(1,FileInfo.NumberOfFrames);%
%             i1_series=[zeros(size(i1_series,1),1) i1_series];
%             if ~isempty(i2_series)
%                 i2_series=i2_series(:,2)*ones(1,FileInfo.NumberOfFrames);%
%                 i2_series=[zeros(size(i2_series,1),1) i2_series];
%             end
%             j1_series=ones(size(i1_series,1),1)*(1:FileInfo.NumberOfFrames);%
%             j1_series=[zeros(size(i1_series,1),1) j1_series];
%             %  include the first index in the root name
%             r=regexp(NomType,'^(?<tiretnum>_?\d+)','names');%look for a number or _1 at the beginning of NomType
%             if ~isempty(r)
%                 fileinput_end=regexprep(fileinput,['^' RootFile],'');%remove RootFile at the beginning of fileinput
%                 if isempty(regexp(r.tiretnum,'^_','once'))% if a separator '_' is not  detected
%                     rr=regexp(fileinput_end,'^(?<i1>\d+)','names');
%                 else% if a separator '_' is  detected
%                     rr=regexp(fileinput_end,'^(?<i1>_\d+)','names');
%                 end
%                 if ~isempty(rr)
%                     j1_input=1;
%                     j2_input=[];
%                 end
%             end
%         end
%     end
% end

%-----------------------------------------------------------------------
%determine the search string to use in regexp to detect file indices from file names
function detect_string=get_search_string(NomType)
%-----------------------------------------------------------------------
sep1='';
sep2='';
i1_str='(?<i1>)';%will set i1=[];
i2_str='(?<i2>)';%will set i2=[];
j1_str='(?<j1>)';%will set j1=[];
j2_str='(?<j2>)';%will set j2=[];

%Look for cases with letter indexing for the second index
r=regexp(NomType,'^(?<sep1>_?)(?<i1>\d+)(?<sep2>_?)(?<j1>[a|A])(?<j2>[b|B]?)$','names');
if ~isempty(r) %indexing image pair with letters
    sep1=r.sep1;
    sep2=r.sep2;
    i1_str='(?<i1>\d+)';
    if strcmp(lower(r.j1),r.j1)% lower case index
        j1_str='(?<j1>[a-z])';
    else
        j1_str='(?<j1>[A-Z])'; % upper case index
    end
    if ~isempty(r.j2)
        if strcmp(lower(r.j1),r.j1)
            j2_str='(?<j2>[a-z])';
        else
            j2_str='(?<j2>[A-Z])';
        end
    end
else %numerical indexing
    r=regexp(NomType,'^(?<sep1>_?)(?<i1>\d+)(?<i2>(-\d+)?)(?<j1>(_\d+)?)(?<j2>(-\d+)?)$','names');
    if ~isempty(r)
        sep1=r.sep1;
        i1_str='(?<i1>\d+)';
        if ~isempty(r.i2)
            i2_str='(?<i2>-\d+)';
        end
        if ~isempty(r.j1)
            j1_str='(?<j1>_\d+)';
        end
        if ~isempty(r.j2)
            j2_str='(?<j2>-\d+)';
        end
    end
end
detect_string=['^' RootFile sep1 i1_str i2_str sep2 j1_str j2_str FileExt '$'];
