%'find_file_series': check the content onf an input field and find the corresponding file series
%--------------------------------------------------------------------------
% function [i1,i2,j1,j2,NomType,FileType,Object]=find_file_series(fileinput)
%
% OUTPUT:
% i1,i2,j1,j2: set of i1 indices, respectively i2,j1,j2,  of the detected files 
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

function [i1,i2,j1,j2,NomType,FileType,Object]=find_file_series(fileinput)
%------------------------------------------------------------------------
i1=[];%default
i2=[];%default
j1=[];%default
j2=[];%default

%% get input root name and nomenclature type
% [RootPath,RootFile,~,~,~,~,FileExt,NomType,SubDir]=name2display(fileinput);
[RootPath,SubDir,RootFile,~,~,~,~,FileExt,NomType]=fileparts_uvmat(fileinput);

%% check for particular file types: images, movies, civ data
FileType='';
Object=[];
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
            imainfo=imfinfo(fileinput);
            FileType='image';
            if length(imainfo) >1 %case of image with multiple frames
                NomType='*';
                FileType='multimage';
                i1=1;
                i2=length(imainfo);
                [RootPath,RootFile]=fileparts(fileinput);
            end
        else
            try
                Data=nc2struct(fileinput,'ListGlobalAttribute','absolut_time_T0','Conventions');
                if ~isempty(Data.absolut_time_T0')
                    FileType='civx'; % test for civx velocity fields
                elseif strcmp(Data.Conventions','uvmat/civdata')
                    FileType='civdata'; % test for civx velocity fields
                else
                    FileType='netcdf';
                end
            end
            try
                Object=VideoReader(fileinput);
                NomType='*';
                FileType='video';
                i1=1;
                i2=get(Object,'NumberOfFrames');
                [RootPath,RootFile]=fileparts(fileinput);
            end
        end
end
if strcmp(NomType,'')||strcmp(NomType,'*')
    [RootPath,RootFile]=fileparts(fileinput);% case of constant name (no indexing)
%% get the list of existing files
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
    for ifile=1:length(dirpair)
       % [~,~,str_1,str_2,str_a,str_b]=name2display(dirpair(ifile).name);
       dirpair(ifile).name
        [~,~,~,i1_ifile,i2_ifile,j1_ifile,j2_ifile]=fileparts_uvmat(dirpair(ifile).name);  
        if isempty(i1_ifile)
            i1(ifile)=1;
        else
            i1(ifile)=i1_ifile;
        end
        if isempty(i2_ifile)
            i2(ifile)=i1(ifile);
        else
            i2(ifile)=i2_ifile;
        end
        end
        if isempty(j1_ifile)
            j1(ifile)=1;
        else
            j1(ifile)=j1_ifile;
        end
        if isempty(j2_ifile)
            j2(ifile)=j1(ifile);
        else
            j2(ifile)=j2_ifile;
        end
    end  
    % TODO : sort by reference index
    % update the NomType from the minimal index detected (to deal with number strings beginning by 0)
    [~,ifile]=min(i1);
    %[~,~,~,~,~,~,~,NomType]=name2display(dirpair(ifile).name);
    if ~isempty(i1)
           [~,ifile]=min(i1);
    [~,~,~,~,~,~,~,~,NomType]=fileparts_uvmat(dirpair(ifile).name);
    end
end