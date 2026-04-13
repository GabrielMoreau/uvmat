%'scan_file_series': check the info about an input file and find the corresponding index series
%--------------------------------------------------------------------------
% function [RootFile,ref_i_list,ref_j_list,ref_ij,i1_list,i2_list,j1_list,j2_list,NomType,FileInfo,MovieObject,i1_input,i2_input,j1_input,j2_input]=scan_file_series(FilePath,fileinput)
%
% OUTPUT:
% ref_i_list: (line vector) list of detected reference i indices, sorted in increasing order, no duplicate. For multimage files or movies indexing is done on frames
% ref_j_list: (column vector) list of detected reference j indices, sorted in increasing order, no duplicate
% ref_ij: sorted list of combined indices  (ref_i_list-min_i)*Nbj+ref_j_list;
% i1_list,i2_list,j1_list,j2_list: list of indices, sorted in correspondance with ref_ij
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

function [RootFile,ref_i_list,ref_j_list,ref_ij,i1_list,i2_list,j1_list,j2_list,NomType,FileInfo,MovieObject,i1_input,i2_input,j1_input,j2_input]=scan_file_series(FilePath,fileinput)
%------------------------------------------------------------------------

%% get input root name and info on the input file
if isempty(regexp(FilePath,'^http://','once'))% case of usual file input
  fullfileinput=fullfile(FilePath,fileinput);% input file name with path
else
  fullfileinput=[FilePath '/' fileinput]; % case of web input
end
[FileInfo,MovieObject]=get_file_info(fullfileinput);

%% default output
[~,~,RootFile,i1_input,i2_input,j1_input,j2_input,FileExt,NomType]=fileparts_uvmat(fullfileinput);
i1_list=i1_input;
i2_list=i2_input;
j1_list=j1_input;
j2_list=j2_input;
ref_i_list=i1_input;
ref_j_list=j1_input;
ref_ij=i1_input;
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
    detect_string=get_search_string(RootFile,FileExt,NomType);% get the search string for regexp from the name NomType
    ListStruct=dir_uvmat(FilePath);% scan the content of the folder FilePath
    ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
    ListFiles=ListCells(1,:);%list of file names
    rr=regexp(ListFiles,detect_string,'names');%detect the string 'detect_string'
    NbDetectedFiles=numel(rr);
    if NbDetectedFiles==0% no detected file
        RootFile='';
    end
    % scan the list of relevant files, extract the indices
    i1_list=nan(NbDetectedFiles,1);
    j1_list=nan(NbDetectedFiles,1);
    i2_list=nan(NbDetectedFiles,1);
    j2_list=nan(NbDetectedFiles,1);
    for ifile=1:NbDetectedFiles
        if ~isempty(rr{ifile})
            i1_list(ifile)=str2double(rr{ifile}.i1);
            i2_list(ifile)=str2double(regexprep(rr{ifile}.i2,'^-',''));
            j1_list(ifile)=stra2num(regexprep(rr{ifile}.j1,'^_',''));
            j2_list(ifile)=stra2num(regexprep(rr{ifile}.j2,'^-',''));
        end
    end
     % update the nom type if the input file does not exist (pb of 0001)
    [~,ifile_min]=min(i1_list);
    [~,~,~,~,~,~,~,~,NomType]=fileparts_uvmat(ListFiles{ifile_min});% update the representation of indices (number of 0 before the number)      
    if isempty(FileInfo.FileName)%  if the input file does not exist, get the info in the file with lower index i in the series
        [FileInfo,MovieObject]=get_file_info(fullfile(FilePath,ListFiles{ifile_min}));
    end
    % get the reference indices
    check_i1_nan=isnan(i1_list);%detect and suppress the files with no index i
    i1_list(check_i1_nan)=[];
     i2_list(check_i1_nan)=[];
      j1_list(check_i1_nan)=[];
       j2_list(check_i1_nan)=[];
    check_i2_nan=isnan(i2_list);%detect NaN i2 indices, 
    check_j2_nan=isnan(j2_list);%detect NaN j2 indices, set them to j1
    ref_i_list(check_i2_nan)=i1_list(check_i2_nan);
    ref_i_list(~check_i2_nan)=floor(0.5*(i1_list(~check_i2_nan)+i2_list(~check_i2_nan)));
    ref_j_list(check_j2_nan)=j1_list(check_j2_nan);
    ref_j_list(~check_j2_nan)=floor(0.5*(j1_list(~check_j2_nan)+j2_list(~check_j2_nan)));
    min_j=min(ref_j_list,[],'omitnan');max_j=max(ref_j_list,[],'omitnan');
    if isnan(min_j)
        Nbj=1;
    else
           Nbj=max_j-min_j+1;
    end
    min_i=min(ref_i_list);%max_i=max(ref_i_list);
    ref_ij=(ref_i_list-min_i)*Nbj+ref_j_list;
    [ref_ij,ind_sort]=sort(ref_ij);% sort the combined index
    i1_list=i1_list(ind_sort);
    i2_list=i2_list(ind_sort);
    j1_list=j1_list(ind_sort);
    j2_list=j2_list(ind_sort);
    ref_i_list=unique(sort(ref_i_list));
    ref_j_list=unique(sort(ref_j_list));
end
if all(isnan(i1_list))
    i1_list=NaN;
end
if all(isnan(i2_list))
    i2_list=NaN;
end
if all(isnan(j1_list))
    j1_list=NaN;
end
if all(isnan(j2_list))
    j2_list=NaN;
end
% 
% 
%% introduce the frame index in case of movies or multimage type
if isfield(FileInfo,'NumberOfFrames') && FileInfo.NumberOfFrames >1
    if isempty(ref_i_list)%  if there is no file index, i denotes the frame index
        ref_i_list=1:FileInfo.NumberOfFrames;% i= list of frame indices
        i1_input=1;
        NomType='*';
    else  % if there is a file index, j denotes the frame index while i denotes the file index
        if ~isempty(regexp(NomType,'ab$', 'once'))% recognized as a pair (case LaVision, to check !!)
            RootFile=fullfile_indices(RootFile,'',NomType,i1_input,i2_input,j1_input,j2_input);% restitute the root name without the detected indices
           ref_i_list=1:FileInfo.NumberOfFrames;% i= list of frame indices
            i1_input=1;
            NomType='*';
        else
            ref_j_list=(1:FileInfo.NumberOfFrames)';% the frame index becomes index j
        end
    end
end

%-----------------------------------------------------------------------
%determine the search string to use in regexp to detect file indices from file names
function detect_string=get_search_string(RootFile,FileExt,NomType)
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
