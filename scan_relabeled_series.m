%'scan_file_series': check the info from XmlData/FileSeries and find the corresponding index series
%--------------------------------------------------------------------------
% function [RootFile,ref_i_list,ref_j_list,NomType]=scan_relabeled_series(FilePath,FileSeries,Time)

%
% OUTPUT:
% RootFile: root name of the file series
% ref_i_list: (line vector) list of reference i indices, sorted in increasing order, no duplicate. 
% ref_j_list: (column vector) list of detected reference j indices, sorted in increasing order, no duplicate
% NomType: nomenclature type corrected after checking the first file (problem of 0 before the number string)

%
%INPUT
% FilePath: path to the directory to be scanned
% FileSeries: section of the xml file ImaDoc describing the relabeling
% Time: matrix of time(j,i) given by the xml file ImaDoc.
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

function [RootFile,ref_i_list,ref_j_list,NomType]=scan_relabeled_series(FilePath,FileSeries,Time)
%------------------------------------------------------------------------
NbField_j=size(Time,1)-1;
NbField_i=size(Time,2)-1;
NbTime=NbField_i*NbField_j;
if ischar(FileSeries.FileName)
    FileSeries.FileName={FileSeries.FileName};
end
[~,~,RootFile,i1,~,~,~,FileExt,NomType]=fileparts_uvmat(FileSeries.FileName{end});
Step=FileSeries.NbFramePerFile;
NbFiles=ceil(NbTime/Step);
check_exist=zeros(1,NbFiles);
for ifile=1:NbFiles
    if ifile<=numel(FileSeries.FileName)
        FullFileName=fullfile(FilePath,FileSeries.FileName{ifile});
    else
        FileIndex=ifile-numel(FileSeries.FileName)+i1;
        FullFileName=fullfile_uvmat(FilePath,'',RootFile,FileExt,NomType,FileIndex);
    end
    check_exist(ifile)=exist(FullFileName,'file')==2;
end
check_ij=reshape(ones(Step,1)* check_exist,[],1);
FileInfo=get_file_info(FullFileName);%check the info about the last file
if isfield (FileInfo,'NumberOfFrames')
    NbMissingFrames=FileSeries.NbFramePerFile-FileInfo.NumberOfFrames;
    if NbMissingFrames>=1
    check_ij(end-NbMissingFrames+1:end)=[];
    end
end
ref_i=find(check_ij);
ref_i_list=ceil(ref_i/NbField_j);
if NbField_j==1
    ref_j_list=NaN;
else
    ref_j_list=1:NbField_j;
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
