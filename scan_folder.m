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

function [ListCells,errormsg] = scan_folder(DirName)
ListCells={};
errormsg='';
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
%bytes_values=[ListFiles.bytes]/1000000;
%[ListFiles.bytes]=deal(bytes_values);
ListCells=struct2cell(ListFiles);% transform dir struct to a cell arrray
cell_remove=regexp(ListCells(1,:),'^(-|\.)');% detect strings beginning by '-' ,'.' (dir beginning by . )
check_keep=cellfun('isempty', cell_remove);%remove detected cells
ListCells=ListCells(:,check_keep);
ListCells(2,:)=[];
ListCells=ListCells';
ListCells=sortrows(ListCells,4,'descend'); %put folders first
ListCells(:,3)= cellfun(@(x) x/1000000, ListCells(:,3),'UniformOutput',false);% express file size in Mbytes
check_dir=cell2mat(ListCells(:,4));% =1 for directories, =0 for files
Column1=cell(size(ListCells,1),1);
Column1(check_dir)={'+/'};
Column1(~check_dir)={''};
ListCells=[Column1 ListCells];

