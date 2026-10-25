%'scan_folder': list the content of a folder, extending 'dir' to the case of OpeNDAP server
%--------------------------------------------------------------------
%
%OUTPUT:
%ListCells: cell array with 5 columns
% 1 st columns: list of file or folder names
% 2 nd column:  string ='+/' for folders, blank for files
% 3 rd column:  last modification dates, in display string
% 4 th column: size in bytes
% 5th column: last modification dates, in datenum numbers

%
%INPUT:
%DirName: complete name of the folder to scan, including path
%sort_option:= 'name'/'date' (default='name'): sort files in alphabetic
%         order or by dates of last transform,from most recent to old

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

function [ListCells,NbDir,NbXml,errormsg] = scan_folder(DirName,sort_option,verbosity)
ListCells={};
errormsg='';
NbDir=0;NbXml=0;
if ~exist('sort_option','var')
    sort_option='name';
end
if ~exist('verbosity','var')
    verbosity='long';
end
if ~ischar(DirName)
    errormsg='the function dir_uvmat needs a character string input';
    return
end
if regexp(DirName,'^http://')
    % OpeNDAP case - read catalog.xml file
    catalog=[DirName,'/catalog.xml'];
    try
    str=urlread(catalog);
    catch ME
        errormsg=ME.message;
        return
    end
    ListFiles=(regexp(str,'xlink:title="(?<name>[^"]+)"','names'))'; % list subfolders
    NumDir=numel(ListFiles);
    ListFiles=[ListFiles;(regexp(str,'dataset name="(?<name>[^"]+)"','names'))']; % append files to the list
    for ilist=1:numel(ListFiles)
        ListFiles(ilist).date=0;
        ListFiles(ilist).bytes=0;
        ListFiles(ilist).isdir=false;
        ListFiles(ilist).datenum=0;
    end
    for ilist=1:NumDir
        ListFiles(ilist).isdir=true;
    end
    ListFiles(NumDir+1)=[];
else
    % Standart case
    ListFiles=dir(DirName);
end
ListItems=fieldnames(ListFiles);% fields of the structure ListFiles
folder_line=find(strcmp('folder',ListItems));
dir_line=find(strcmp('isdir',ListItems));
date_line=find(strcmp('datenum',ListItems));
bytes_line=find(strcmp('bytes',ListItems));
ListCells=struct2cell(ListFiles);% transform dir struct to a cell arrray
cell_remove=regexp(ListCells(1,:),'^(-|\.)');% detect strings beginning by '-' ,'.' (dir beginning by . )
check_keep=cellfun('isempty', cell_remove);
ListCells=ListCells(:,check_keep);%remove detected cells
ListCells=ListCells';% switch to column display
ListCells=sortrows(ListCells,dir_line,'descend'); %put folders first
check_dir=cell2mat(ListCells(:,dir_line));% =1 for directories, =0 for files
check_xml=~cellfun('isempty',regexp(ListCells(:,1),'.xml$'));
check_files=~check_dir & ~check_xml;
NbDir=numel(find(check_dir));
NbXml=numel(find(check_xml));

ListCells(:,bytes_line)= cellfun(@(x) x/1000000, ListCells(:,bytes_line),'UniformOutput',false);% express file size in Mbytes
TotalSize=sum(cell2mat(ListCells(~check_dir,bytes_line)));% total size of files
if strcmp(sort_option,'date')
    ListCells(check_dir,:)=sortrows(ListCells(check_dir,:),date_line,'descend'); % sort by date the files (keepin gthe folders first)
    ListCells(check_xml,:)=sortrows(ListCells(check_xml,:),date_line,'descend'); % sort by date the files (keepin gthe folders first)
    ListCells(check_files,:)=sortrows(ListCells(check_files,:),date_line,'descend'); % sort by date the files (keepin gthe folders first)
end

%ListCells(check_dir,1)=regexprep(ListCells(check_dir,1),'^.+','+/$0');% put '+/' in front of dir name display
ListCells(check_dir,1)=strcat('+/',ListCells(check_dir,1));
% ListCells(check_xml,1)=strcat('<html><span style="color:red">',ListCells(check_xml,1));
% ListCells(check_xml,1)=strcat(ListCells(check_xml,1),'</span></html>');
ListCells (~check_dir,:)=[ListCells(check_xml,:);ListCells(check_files,:)];% put xml first in the list
ListCells(:,[folder_line dir_line date_line])=[];% eliminate non usefull columns
if strcmp(verbosity,'long')% long output with the whole file list
    ListCells (~check_dir,:)=[ListCells(check_xml,:);ListCells(check_files,:)];% put xml first in the list
else% short output, without the non xml files
    NbFiles=size(ListCells,1)-NbDir-NbXml;
%     ListCells(~check_files,:)=[];
    if NbFiles==0
         ListCells (~check_dir,:)=ListCells(check_xml,:);
    else
         ListCells (~check_dir,:)=[ListCells(check_xml,:);{[num2str(NbFiles) ' files,' num2str(TotalSize) ' Mo'],'',''}];
    end
end


