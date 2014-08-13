% 'find_imadoc': find the ImaDoc xml file associated with a given input file
% take into account the old conventions
%-----------------------------------------------------------------------
% function XmlFileName=find_imadoc(RootPath,SubDir,RootFile,FileExt)
%
% OUTPUT:
% XmlFileName: name of the xml file, ='' if none is found
%
% INPUT:
% RootPath,SubDir,RootFile,FileExt, as given from the input file name by fileparts_uvmat

%=======================================================================
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function XmlFileName=find_imadoc(RootPath,SubDir,RootFile,FileExt)
SubDirBase=SubDir;
XmlFileName=fullfile(RootPath,[SubDir '.xml']);
if ~exist (XmlFileName,'file')
    dotchar=regexp(SubDir,'\.');
    for idot=1:numel(dotchar)
        XmlFileName=fullfile(RootPath,[SubDir(1:dotchar(end-idot+1)-1) '.xml']);
        if exist(XmlFileName,'file')
            SubDirBase=fullfile(RootPath,SubDir(1:dotchar(end-idot+1)-1));
            break
        end
    end   
end
if ~exist(XmlFileName,'file')
    XmlFileName=[fullfile(RootPath,SubDirBase,RootFile) '.xml']; % old convention: xml inside the image folder, case of images or new civ files
    if ~exist(XmlFileName,'file')
        XmlFileName=[fullfile(RootPath,SubDirBase,RootFile) '.civ']; % very old convention: .civ file
        if ~exist(XmlFileName,'file') && strcmp(FileExt,'.nc')
            XmlFileName=[fullfile(RootPath,RootFile) '.xml'] ; % old convention: xml inside the image folder, old civ file opened
            if ~exist(XmlFileName,'file')
                XmlFileName=[fullfile(RootPath,RootFile) '.civ']; % very old convention: .civ file
            end
        end
    end
end
if exist(XmlFileName,'file')~=2
    XmlFileName='';
end
