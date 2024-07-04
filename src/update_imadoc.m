%'update_imadoc': update an xml file with geometric calibration parameters
%--------------------------------------------------------------------------
%  function [checkcreate,xmlfile,errormsg]=update_imadoc(Struct,RootPath,SubDir,StructName)
%
% OUTPUT:
% checkupdate= 1 if the xml file (containing timing)already exist, =0 when it has to be created
% xmlfile: name of the xmlfile containing the the calibration data
% errormsg: error message, ='' if OK

% INPUT:

% RootPath: path to the folder containing the image series to calibrate
% SubDir: folder contaiting the image series to calibrate
% StructName : Name of the field in the xml file
% Struct: Matlab structure containing the calibration parameters
% checkbackup=1 (default): backup of existing xml file as .xml~, 
%-------------------------------------------------------------

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

function [checkupdate,xmlfile,errormsg]=update_imadoc(RootPath,SubDir,StructName,Struct,checkbackup)

errormsg='';
if ~exist('checkbackup','var')
    checkbackup=1;
end

%% set the output xml file at the root, hide other existing  xml files
xmlfile=find_imadoc(RootPath,SubDir);
if isempty(xmlfile)
    checkupdate=0;
else
    checkupdate=1;
end

%% backup the existing xml file, adding a ~ to its name
if checkupdate
    if checkbackup
        backupfile=xmlfile;
        testexist=2;
        while testexist==2
            backupfile=[backupfile '~'];
            testexist=exist(backupfile,'file');
        end
        [success,message]=copyfile(xmlfile,backupfile);%make backup
        if success~=1
            errormsg=['errror in xml file backup: ' message];
            return
        end
    end
    t=xmltree(xmlfile); %read the file
    title=get(t,1,'name');
    if ~strcmp(title,'ImaDoc')
        errormsg=[xmlfile ' not appropriate for calibration'];
        return
    end
    uid_calib=find(t,['ImaDoc/' StructName]);
    if isempty(uid_calib)  %if Struct does not already exists, create it
        [t,uid_calib]=add(t,1,'element',StructName);
    else %if Struct already exists, delete its content
        uid_child=children(t,uid_calib);
        t=delete(t,uid_child);
    end
else   % create a new xml file
    t=xmltree;
    t=set(t,1,'name','ImaDoc');
    [t,uid_calib]=add(t,1,'element',StructName);
end

%% save the output file
t=struct2xml(Struct,t,uid_calib);
try
    save(t,xmlfile);
catch ME
    errormsg=['error in saving ' xmlfile ': ' ME.message];
end
