% 'find_imadoc': find the ImaDoc xml file associated with a given input file
% take into account the old conventions
%-----------------------------------------------------------------------
% function XmlFileName=find_imadoc(RootPath,SubDir)
%
% OUTPUT:
% XmlFileName: name of the xml file, ='' if none is found
%
% INPUT:
% RootPath: path to the folder containing the image series,
% SubDir: name of the folder containing the image series

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function XmlFileName=find_imadoc(RootPath,SubDir)
XmlFileName=fullfile(RootPath,[SubDir '.xml']);
if ~exist(XmlFileName,'file')
    dotchar=regexp(SubDir,'\.');%detect the dots in the folder name
    if ~isempty(dotchar)
        for idot=1:numel(dotchar)
            SubDir=SubDir(1:dotchar(end-idot+1)-1);
            XmlFileName=fullfile(RootPath,[SubDir '.xml']);
            if exist(XmlFileName,'file')
                break
            end
        end
    end
    if ~exist(XmlFileName,'file')
        XmlFileName='';
    end
end




