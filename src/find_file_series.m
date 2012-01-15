%'find_file_series': check the content of an input file and find the corresponding file series
%--------------------------------------------------------------------------
% function [RootPath,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,Object]=find_file_series(fileinput)
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
% Object: video object (=[] otherwise)
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

function [RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,Object]=find_file_series(RootPath,fileinput,option)
%------------------------------------------------------------------------
if ~exist('option','var')
    option='all';
end
%% get input root name and nomenclature type
[tild,tild,RootFile,tild,i2_input,j1_input,j2_input,FileExt,NomType]=fileparts_uvmat(fileinput);
fullfileinput=fullfile(RootPath,fileinput);

%% check for particular file types: images, movies, civ data
FileType='';
Object=[];
i1_series=zeros(1,1,1);
i2_series=zeros(1,1,1);
j1_series=zeros(1,1,1);
j2_series=zeros(1,1,1);

switch FileExt
    % ancillary files, no field indexing
    case {'.civ','.log','.cmx','.cmx2','.txt','.bat'}
        FileType='txt';
        NomType='';
    case '.fig'
        FileType='figure';
        NomType='';
    case '.xml'
        FileType='xml';
        NomType='';
    case '.xls'
        FileType='xls';
        NomType='';
    otherwise
      
        if ~isempty(FileExt)&& ~isempty(imformats(FileExt(2:end)))
            try
                imainfo=imfinfo(fullfileinput);
                FileType='image';
                if length(imainfo) >1 %case of image with multiple frames
                    NomType='*';
                    FileType='multimage';
                    i1_series=(1:length(imainfo))';
                    [RootPath,RootFile]=fileparts(fullfileinput);
                end
            end
        else
            try
                Data=nc2struct(fullfileinput,'ListGlobalAttribute','absolut_time_T0','Conventions');
                if ~isempty(Data.absolut_time_T0')
                    FileType='civx'; % test for civx velocity fields
                elseif strcmp(Data.Conventions,'uvmat/civdata')
                    FileType='civdata'; % test for civx velocity fields
                else
                    FileType='netcdf';
                end
            end
            try
                if exist('VideoReader','file')%recent version of Matlab
                    Object=VideoReader(fullfileinput);
                else
                    Object=mmreader(fullfileinput);%older Matlab function for movies
                end
                NomType='*';
                FileType='video';
                i1_series=(1:get(Object,'NumberOfFrames'))';
            end
        end
end

if strcmp(NomType,'')||strcmp(NomType,'*')||strcmp(option,'filetype')
    if exist(fullfileinput,'file')
        [tild,RootFile]=fileparts(fileinput);% case of constant name (no indexing)
    else     
        RootFile='';
    end
else   
    %% analyse the list of existing files when relevant
    sep1='';
    i1_str='(?<i1>)';
    i1_star='';
    sep2='';
    i2_str='(?<i2>)';
    i2_star='';
    sep3='';
    j1_str='(?<j1>)';
    j1_star='';
    sep4='';
    j2_str='(?<j2>)';
    j2_star='';
    NomTypeStr=NomType;
    if ~isempty(regexp(NomTypeStr,'^_\d'))
        sep1='_';
        NomTypeStr(1)=[];%remove '_' from the beginning of NomTypeStr
    end
    r=regexp(NomTypeStr,'^(?<num1>\d+)','names');%look for a number at the beginning of NomTypeStr
    if ~isempty(r)
        i1_str='(?<i1>\d+)';
        i1_star='*';
        NomTypeStr=regexprep(NomTypeStr,['^' r.num1],'');
        r=regexp(NomTypeStr,'^-(?<num2>\d+)','names');%look for a pair i1-i2
        if ~isempty(r)
            sep2='-';
            i2_str='(?<i2>\d+)';
            i2_star='*';
            NomTypeStr=regexprep(NomTypeStr,['^-' r.num2],'');
        end
        if ~isempty(regexp(NomTypeStr,'^_'));
            sep3='_';
            NomTypeStr(1)=[];%remove '_' from the beginning of NomTypeStr
        end
        if ~isempty(regexp(NomTypeStr,'^[a|A]'));
            j1_str='(?<j1>[a-z]|[A-Z])';
            j1_star='*';
            if ~isempty(regexp(NomTypeStr,'[b|B]$'));
                j2_str='(?<j2>[a-z]|[A-Z])';
                j2_star='*';
            end
        else
            r=regexp(NomTypeStr,'^(?<num3>\d+)','names');
            if ~isempty(r)
                j1_str='(?<j1>\d+)';
                 j1_star='*';
                NomTypeStr=regexprep(NomTypeStr,['^' r.num3],'');
            end
            r=regexp(NomTypeStr,'-(?<num4>\d+)','names');
            if ~isempty(r)
                sep4='-';
                j2_str='(?<j2>\d+)';
                 j2_star='*';
            end
        end
    end
    detect_string=['^' RootFile sep1 i1_str sep2 i2_str sep3 j1_str sep4 j2_str FileExt '$'];%string used in regexp to detect file indices
    %find the string used to extract the relevant files with the command dir
    star_string=[RootFile sep1 i1_star sep2 i2_star sep3 j1_star sep4 j2_star '*'];
    wd=pwd;%current working directory
    %RR=fullfile(RootPath,SubDir);
    cd (RootPath)% move to the local dir to save time in the operation dir.
    dirpair=dir([star_string FileExt]);% look for relevant files in the file directory
    cd(wd)
    nbpair=numel(dirpair);
    ref_i_list=zeros(1,nbpair);
    ref_j_list=zeros(1,nbpair);
    if nbpair==0% no detected file
        RootPath='';
        RootFile='';
    end
    % scan the list of relevant files, extract the indices
    for ifile=1:nbpair
        rr=regexp(dirpair(ifile).name,detect_string,'names');
        if ~isempty(rr)
        i1=str2num(rr.i1);
        i2=str2num(rr.i2);
        j1=stra2num(rr.j1);
        j2=stra2num(rr.j2);
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
    [tild,ifile_min]=min(ref_ij(ref_ij>0));
    if isempty(ifile_min)
        RootPath='';
        RootFile='';
        NomType='';
    else
        [tild,tild,tild,tild,tild,tild,tild,tild,NomType]=fileparts_uvmat(dirpair(ifile_min).name);% update the representation of indices (number of 0 before the number)
    end
end

%% update the file type if the input file does not exist (pb of 0001)
if strcmp(option,'filetype')
    return
elseif isempty(FileType)
    [tild,tild, tild,tild,tild,tild,FileType,Object]=find_file_series(RootPath,dirpair(ifile_min).name,'filetype');
end

%% set to empty array the irrelevant index series
if isequal(i1_series,0), i1_series=[]; end
if isequal(i2_series,0), i2_series=[]; end
if isequal(j1_series,0), j1_series=[]; end
if isequal(j2_series,0), j2_series=[]; end

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

