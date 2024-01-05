%'dir_uvmat': list the content of a folder, extending 'dir' to the case of OpeNDAP server
%--------------------------------------------------------------------
%[RootPath,SubDir,RootFile,i1,i2,j1,j2,Ext,NomType]=fileparts_uvmat(FileInput)
%
%OUTPUT:
%ListFiles: 
%
%INPUT:
%DirName: complete name of the folder to scan, including path

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
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

function [ListFiles,errormsg] = dir_uvmat(DirName)
ListFiles=[];
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

