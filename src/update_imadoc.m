%'update_imadoc': update an xml file with geometric calibration parameters
%--------------------------------------------------------------------------
%  function update_imadoc(Struct,outputfile)
%
%INPUT:
% Struct: structure containing the calibration parameters
% outputfile: xml file to modify
% StructName : Name of the field in the xml file
%-------------------------------------------------------------

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function errormsg=update_imadoc(Struct,outputfile,StructName)
errormsg='';
testappend=0;
%% backup the output file if it already exist, and read it
if exist(outputfile,'file')%=1 if the output file already exists, 0 else
    testappend=1;
    backupfile=outputfile;
    t=xmltree(outputfile); %read the file
    title=get(t,1,'name');
    if strcmp(title,'ImaDoc')
        %         testappend=1;
        %rename the existing file for backup
        testexist=2;
        while testexist==2
            backupfile=[backupfile '~'];
            testexist=exist(backupfile,'file');
        end
        [success,message]=movefile(outputfile,backupfile);%make backup
        if success~=1
            errormsg=['errror in xml file backup: ' message];
            return
        end
        %if the xml file is  ImaDoc
        uid_calib=find(t,['ImaDoc/' StructName]);
        if isempty(uid_calib)  %if Struct does not already exists, create it
            [t,uid_calib]=add(t,1,'element',StructName);
        else %if Struct already exists, delete its content
            uid_child=children(t,uid_calib);
            t=delete(t,uid_child);
        end
    end
end

%% create a new xml file
if ~testappend
    t=xmltree;
    t=set(t,1,'name','ImaDoc');
    % in case of movie (avi file), copy timing info in the new xml file
    [pp,outputroot]=fileparts(outputfile);
    %     imainfo=[];
    if exist(fullfile(pp,[outputroot '.avi']),'file')
        FileName=fullfile(pp,[outputroot '.avi']);
        hhh=which('videoreader');
        if isempty(hhh)%use old video function of matlab
            imainfo=aviinfo(FileName);
            imainfo.FrameRate=imainfo.FramesPerSecond;
            imainfo.NumberOfFrames=imainfo.NumFrames;
        else %use video function videoreader of matlab
            imainfo=get(videoreader(FileName));
        end
        if ~isempty(imainfo)
            [t,uid_camera]=add(t,1,'element','Camera');
            Camera.TimeUnit='s';
            Camera.BurstTiming.Time=0;
            Camera.BurstTiming.Dti=1/imainfo.FrameRate;
            Camera.BurstTiming.NbDti=imainfo.NumberOfFrames-1;
            t=struct2xml(Camera,t,uid_camera);
        end
    end
    [t,uid_calib]=add(t,1,'element',StructName);
end

%% save the output file
t=struct2xml(Struct,t,uid_calib);
try
    save(t,outputfile);
catch ME
    errormsg=['error in saving ' outputfile ': ' ME.message];
end
