%'find_file_series': check the content onf an input field and find the corresponding file series
%--------------------------------------------------------------------------
% function [RootPath,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,Object]=find_file_series(fileinput)
%
% OUTPUT:
% RootPath,RootFile: root path and root name detected in fileinput, possibly modified for movies (indexing is then done on image view, not file)
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
% fileinput: name (including path)  of the input file
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

function [RootPath,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,Object]=find_file_series(fileinput)
%------------------------------------------------------------------------

%% get input root name and nomenclature type
[RootPath,SubDir,RootFile,tild,i2_input,j1_input,j2_input,FileExt,NomType]=fileparts_uvmat(fileinput);

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
                imainfo=imfinfo(fileinput);
                FileType='image';
                if length(imainfo) >1 %case of image with multiple frames
                    NomType='*';
                    FileType='multimage';
                    i1_series=(1:length(imainfo))';
                    [RootPath,RootFile]=fileparts(fileinput);
                end
            end
        else
            try
                Data=nc2struct(fileinput,'ListGlobalAttribute','absolut_time_T0','Conventions');
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
                    Object=VideoReader(fileinput);    
                else
                    Object=mmreader(fileinput);%older Matlab function for movies                
                end
                NomType='*';
                FileType='video';  
                i1_series=(1:get(Object,'NumberOfFrames'))';
            end
        end
end

%% get the list of existing files when relevant
if strcmp(NomType,'')||strcmp(NomType,'*')
    if exist(fileinput,'file')
    [RootPath,RootFile]=fileparts(fileinput);% case of constant name (no indexing)
    else
       RootPath='';
       RootFile='';
    end
else
    if strcmp(SubDir,'')
        filebasesub=fullfile(RootPath,RootFile);
    else
        filebasesub=fullfile(RootPath,SubDir,RootFile);
    end
    detect_string=regexprep(NomType,'\d','*');%replace numbers by '*'
    old_string='';
    detect_string=regexprep(detect_string,'[ab]$','*');%suppress the possible letter ab at the end
    detect_string=regexprep(detect_string,'[AB]$','*');%suppress the possible letter ab at the end
    detect_string=regexprep(detect_string,'[a|A]$','*');%suppress a possible second letter a,A at the end
    while ~strcmp(detect_string,old_string)%removes multiple '*'
        old_string=detect_string;
        detect_string=regexprep(detect_string,'**','*');
    end
    dirpair=dir([filebasesub detect_string FileExt]);
    nbpair=numel(dirpair);
    ref_i_list=zeros(1,nbpair);
    ref_j_list=zeros(1,nbpair);
    if nbpair==0% no detected file
        RootPath='';
        RootFile='';
    end
    for ifile=1:nbpair
        [tild,tild,tild,i1,i2,j1,j2]=fileparts_uvmat(dirpair(ifile).name);
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
    % look for the numerical string of the first files to update the NomType (take into account the 0 before the number)
    max_j=max(ref_j_list);
    if isempty(max_j)
        ref_ij=ref_i_list;
    else
        ref_ij=ref_i_list*max_j+ref_j_list; % ordered by index i, then by j for a given i.
    end
    [tild,ifile]=min(ref_ij(ref_ij>0));
    if isempty(ifile)
        RootPath='';
        RootFile='';
        NomType='';
    else
    [tild,tild,tild,tild,tild,tild,tild,tild,NomType]=fileparts_uvmat(dirpair(ifile).name);
    end
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

