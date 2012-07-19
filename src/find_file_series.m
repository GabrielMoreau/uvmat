%'find_file_series': check the content of an input file and find the corresponding file series
%--------------------------------------------------------------------------
% function [RootPath,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,Object,i1_input,i2_input,j1_input,j2_input]=find_file_series(fileinput)
%
% OUTPUT:
% RootFile: root file detected in fileinput, possibly modified for movies (indexing is then done on image view, not file)
% i1_series(ref_i+1, ref_j+1,pair),i2_series,j1_series,j2_series: set of indices (i1,i2,j1,j2) sorted by ref index ref_i, ref_j, and pairindex in case of multiple pairs with the same ref
%  (ref_i+1 is used to deal with the image index zero sometimes used)
% NomType: nomenclature type corrected after checking the first file (problem of 0 before the number string)
% FileType: type of file, =
%       = 'image', usual image as recognised by Matlab
%       = 'multimage', image series stored in a single file
%       = 'civx', netcdf file with civx convention
%       = 'civdata', civ data with new convention
%       = 'netcdf' other netcdf files
%       = 'video': movie recognised by VideoReader (e;g. avi)
% MovieObject: video object (=[] otherwise)
%
%INPUT
% RootPath: path to the directory to be scanned
% fileinput: name (without path) of the input file sample 
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright  2011, LEGI / CNRS-UJF-INPG, joel.sommeria@legi.grenoble-inp.fr
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This file is part of the toolbox UVMAT.
% 
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function [RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,MovieObject,i1_input,i2_input,j1_input,j2_input]=find_file_series(FilePath,fileinput)
%------------------------------------------------------------------------

%% get input root name and nomenclature type
fullfileinput=fullfile(FilePath,fileinput);% input file name with path
[RootPath,SubDir,RootFile,i1_input,i2_input,j1_input,j2_input,FileExt,NomType]=fileparts_uvmat(fullfileinput);


%% check for particular file types: images, movies, civ data
i1_series=zeros(1,1,1);
i2_series=zeros(1,1,1);
j1_series=zeros(1,1,1);
j2_series=zeros(1,1,1);
[FileType,FileInfo,MovieObject]=get_file_type(fullfileinput);
if ~exist(FilePath,'dir')
    return % don't go further if the dir path does not exist
end
NomTypePref='';
if isempty(NomType)
    if exist(fullfileinput,'file')
        [tild,RootFile]=fileparts(fileinput);% case of constant name (no indexing), get the filename without its extension
    else
        RootFile='';
    end
else
    %% possibly include the first index in the root name, if there exists a corresponding xml file
    r=regexp(NomType,'^(?<tiretnum>_?\d+)','names');%look for a number or _1 at the beginning of NomType
    if ~isempty(r)
        fileinput_end=regexprep(fileinput,['^' RootFile],'');%remove RootFile at the beginning of fileinput
        if isempty(regexp(r.tiretnum,'^_','once'))% if a separator '_' is not  detected
            rr=regexp(fileinput_end,'^(?<i1>\d+)','names');
        else% if a separator '_' is  detected
            rr=regexp(fileinput_end,'^(?<i1>_\d+)','names');
        end
        if ~isempty(rr)
            RootFile_i=[RootFile rr.i1];% new root file
            if exist(fullfile(RootPath,SubDir,[RootFile_i '.xml']),'file') || (strcmp(FileExt,'.nc') && exist(fullfile(RootPath,[RootFile_i '.xml']),'file'))
                RootFile=RootFile_i;
                NomTypePref=r.tiretnum;
                NomType=regexprep(NomType,['^'  NomTypePref],'');
                i1_input=j1_input;
                i2_input=j2_input;
                j1_input=[];
                j2_input=[];
            end       
        end
    end
    %% analyse the list of existing files when relevant
    sep1='';
    i1_str='(?<i1>)';%will set i1=[];
    i1_star='';
    i2_str='(?<i2>)';%will set i2=[];
    i2_star='';
    j1_str='(?<j1>)';%will set j1=[];
    j1_star='';
    j2_str='(?<j2>)';%will set j2=[];
    j2_star='';
    %Look for cases with letter indexing for the second index
    r=regexp(NomType,'^(?<sep1>_?)(?<i1>\d+)(?<j1>[a|A])(?<j2>[b|B]?)$','names');
    if ~isempty(r)
        sep1=r.sep1;
        i1_str='(?<i1>\d+)';
        if strcmp(lower(r.j1),r.j1)% lower case index
            j1_str='(?<j1>[a-z])';
        else
           j1_str='(?<j1>[A-Z])'; % upper case index
        end
        j1_star='*';
        if ~isempty(r.j2)
           if strcmp(lower(r.j1),r.j1)
            j2_str='(?<j2>[a-z])';
            else
           j2_str='(?<j2>[A-Z])'; 
           end
            j2_star='*';
        end
    else %numerical indexing
        r=regexp(NomType,'^(?<sep1>_?)(?<i1>\d+)(?<i2>(-\d+)?)(?<j1>(_\d+)?)(?<j2>(-\d+)?)$','names');
        if ~isempty(r)
            sep1=r.sep1;
            i1_str='(?<i1>\d+)';
            i1_star='*';
            if ~isempty(r.i2)
                i2_str='(?<i2>-\d+)';
                i2_star='-*';
            end
            if ~isempty(r.j1)
                j1_str='(?<j1>_\d+)';
                j1_star='_*';
            end
            if ~isempty(r.j2)
                j2_str='(?<j2>-\d+)';
                j2_star='-*';
            end
        end
    end
    detect_string=['^' RootFile sep1 i1_str i2_str j1_str j2_str FileExt '$'];%string used in regexp to detect file indices
    %find the string used to extract the relevant files with the command dir
    star_string=[RootFile sep1 i1_star i2_star  j1_star j2_star FileExt];
    wd=pwd;%current working directory
    cd (FilePath)% move to the local dir to save time in the operation dir.
    dirpair=dir(star_string);% look for relevant files in the file directory
    cd(wd)
    nbpair=numel(dirpair);
    ref_i_list=zeros(1,nbpair);
    ref_j_list=zeros(1,nbpair);
    if nbpair==0% no detected file
        RootFile='';
    end
    % scan the list of relevant files, extract the indices
    for ifile=1:nbpair
        rr=regexp(dirpair(ifile).name,detect_string,'names');
        if ~isempty(rr)
            i1=str2num(rr.i1);
            i2=str2num(regexprep(rr.i2,'^-',''));
            j1=stra2num(regexprep(rr.j1,'^_',''));
            j2=stra2num(regexprep(rr.j2,'^-',''));
            ref_i=i1;
            if isempty(i2_input)
                if ~isempty(i2)% invalid file name if i2 does not exist in the input file
                    break
                end
            else
                ref_i=floor((i1+i2)/2);
            end
            ref_j=1;
            if isempty(j1_input)
                if  ~isempty(j1)% invalid file name if j1 does not exist in the input file
                    break
                end
            else %j1_input is not empty
                if isempty(j1)% the detected name does not fit with the input
                    break
                else
                    ref_j=j1;
                    if isempty(j2_input)
                        if  ~isempty(j2)% invalid file name if j2 does not exist in the input file
                            break
                        end
                    else
                        ref_j=floor((j1+j2)/2);
                    end
                end
            end
            % update the detected index series
            ref_i_list(ifile)=ref_i;
            ref_j_list(ifile)=ref_j;
            nb_pairs=0;
            if ~isempty(i2_input)|| ~isempty(j2_input) %deals with  pairs
                if size(i1_series,1)>=ref_i+1 && size(i1_series,2)>=ref_j+1
                    nb_pairs=numel(find(i1_series(ref_i+1,ref_j+1,:)~=0));
                end
            end
            i1_series(ref_i+1,ref_j+1,nb_pairs+1)=i1;
            if ~isempty(i2_input)
                i2_series(ref_i+1,ref_j+1,nb_pairs+1)=i2;
            end
            if ~isempty(j1_input)
                j1_series(ref_i+1,ref_j+1,nb_pairs+1)=j1;
            end
            if ~isempty(j2_input)
                j1_series(ref_i+1,ref_j+1,nb_pairs+1)=j1;
                j2_series(ref_i+1,ref_j+1,nb_pairs+1)=j2;
            end
        end
    end
    % look for the numerical string of the first files to update the NomType (take into account the 0 before the number)
    max_j=max(ref_j_list);
    if isempty(max_j)
        ref_ij=ref_i_list;
    else
        ref_ij=ref_i_list*max_j+ref_j_list; % ordered by index i, then by j for a given i.
    end
    ind_select=find(ref_ij>0);
    if isempty(ind_select)
        RootFile='';
        NomType='';
    else
        [tild,ifile_min]=min(ref_ij(ind_select));
        [tild,tild,tild,tild,tild,tild,tild,tild,NomType]=fileparts_uvmat(dirpair(ind_select(ifile_min)).name);% update the representation of indices (number of 0 before the number)
        NomType=regexprep(NomType,['^' NomTypePref],'');
    end
    %% update the file type if the input file does not exist (pb of 0001)
    if isempty(FileType)
        [FileType,tild,MovieObject]=get_file_type(fullfile(FilePath,dirpair(ifile_min).name));
    end
end

%% set to empty array the irrelevant index series
if isequal(i1_series,0), i1_series=[]; end
if isequal(i2_series,0), i2_series=[]; end
if isequal(j1_series,0), j1_series=[]; end
if isequal(j2_series,0), j2_series=[]; end

%% introduce the frame index in case of movies or multimage type
if isfield(FileInfo,'NumberOfFrames') && FileInfo.NumberOfFrames >1
    if isempty(i1_series)
        i1_series=(1:FileInfo.NumberOfFrames)';
        i1_input=1;
        NomType='*';
    else
        i1_series=i1_series(:,2)*ones(1,FileInfo.NumberOfFrames);
        i1_series=[i1_series(:,1) i1_series];
        j1_series=ones(size(i1_series,1),1)*(0:FileInfo.NumberOfFrames);
        %  include the first index in the root name
        r=regexp(NomType,'^(?<tiretnum>_?\d+)','names');%look for a number or _1 at the beginning of NomType
        if ~isempty(r)
            fileinput_end=regexprep(fileinput,['^' RootFile],'');%remove RootFile at the beginning of fileinput
            if isempty(regexp(r.tiretnum,'^_','once'))% if a separator '_' is not  detected
                rr=regexp(fileinput_end,'^(?<i1>\d+)','names');
            else% if a separator '_' is  detected
                rr=regexp(fileinput_end,'^(?<i1>_\d+)','names');
            end
            if ~isempty(rr)
%                 RootFile=[RootFile rr.i1];% new root file
%                 NomTypePref=r.tiretnum;
%                 NomType=regexprep(NomType,['^'  NomTypePref],'');
              %  i1_input=j1_input;
              %  i2_input=j2_input;
                j1_input=1;
                j2_input=[];
            end
        end
    end
end

%% sort pairs by decreasing index differences in case of multiple pairs at the same reference index
if size(i2_series,3)>1 %pairs i1 -i2
    diff_index=abs(i2_series-i1_series);
    [tild,ind_pair]=sort(diff_index,3,'descend');
    for ref_i=1:size(i1_series,1)
        for ref_j=1:size(j1_series,2)
            i1_series(ref_i,ref_j,:)=i1_series(ref_i,ref_j,ind_pair(ref_i,ref_j,:));
            i2_series(ref_i,ref_j,:)=i2_series(ref_i,ref_j,ind_pair(ref_i,ref_j,:));
            if ~isempty(j1_series)
                j1_series(ref_i,ref_j,:)=j1_series(ref_i,ref_j,ind_pair(ref_i,ref_j,:));
            end
        end
    end
elseif size(j2_series,3)>1 %pairs j1 -j2
    diff_index=abs(j2_series-j1_series);
    [tild,ind_pair]=sort(diff_index,3,'descend');
    for ref_i=1:size(i1_series,1)
        for ref_j=1:size(j1_series,2)
            i1_series(ref_i,ref_j,:)=i1_series(ref_i,ref_j,ind_pair(ref_i,ref_j,:));
            if ~isempty(i2_series)
                i2_series(ref_i,ref_j,:)=i2_series(ref_i,ref_j,ind_pair(ref_i,ref_j,:));
            end
            j1_series(ref_i,ref_j,:)=j1_series(ref_i,ref_j,ind_pair(ref_i,ref_j,:));
            j2_series(ref_i,ref_j,:)=j2_series(ref_i,ref_j,ind_pair(ref_i,ref_j,:));
        end
    end
end


