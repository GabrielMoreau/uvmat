%'dir_scan': scan the structure of the directory tree (for browse_data.m)
%------------------------------------------------------------------------
% function [ListDevices,ListRecords,ListXml,List]=dir_scan(CurrentPath,ListExperiments,ListDevices_in,ListRecords_in)
%
% 
% OUTPUT:
%  ListDevices: list of Devices 
%  ListRecords: list of records
%  ListXml: list of xml file names
%  List: structure representing the tree structure
%
% INPUT:
%  CurrentPath: full name (including path) to the input campaign (or subcampaign), we assume that
%          data are organised as (sub)campaign/Experiment/Device/(Record/)/file .xml
%  ListExperiments: list of experiments to scan (cell of names)
%  ListDevices_in: list of devices to scan (cell of names)
%  ListRecords_in: list of records to scan (cell of names)

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

function [ListDevices,ListRecords,ListXml,List]=dir_scan(CurrentPath,ListExperiments,ListDevices_in,ListRecords_in)

ListRecords={};
ListDevices={};
ListXml={};
irecord_tot=0;
idevice_tot=0;
ixml_tot=0;
for iexp=1:length(ListExperiments) 
    List.Experiment{iexp}.name=ListExperiments{iexp};
    hdir=dir(fullfile(CurrentPath,ListExperiments{iexp}));
    idevice=0;
    for isub=1:length(hdir)% scan the sub-directories  of the current experiment       
        if hdir(isub).isdir
            name=hdir(isub).name;%name of the current device
            if ~isequal(name(1),'.')% subdirectory of the current experiment
                [testnew,testselect]=test_select(name,ListDevices,ListDevices_in);
                if testselect
                    idevice=idevice+1;
                    List.Experiment{iexp}.Device{idevice}.name=name;             
                    if testnew
                         idevice_tot=idevice_tot+1;
                         ListDevices{idevice_tot}=name;
                    end
                    CurrentDevice=fullfile(CurrentPath,ListExperiments{iexp},name);
                    hsubxml=dir(fullfile(CurrentDevice,'*.xml'));%look at xml files in the subdirectory of the current device
                    if isempty(hsubxml) % the subdirectory of the current device contains directories 'Record'' 
                        hsubdir=dir(fullfile(CurrentPath,ListExperiments{iexp},name));%list what is inside the directory 'Device'   
                        irecord=0;
                        for isubsub=1:length(hsubdir)% subdirectories of the current device
                            if hsubdir(isubsub).isdir                       
                                RecordName=hsubdir(isubsub).name;  
                                if ~isequal(RecordName(1),'.')
                                    [testnew,testselect]=test_select(RecordName,ListRecords,ListRecords_in);
                                    if testselect
                                        if testnew
                                            irecord_tot=irecord_tot+1;
                                            ListRecords{irecord_tot}=RecordName;
                                        end
                                        irecord=irecord+1;
                                        List.Experiment{iexp}.Device{idevice}.Record{irecord}.name=RecordName;
                                        hsubsubxml=dir(fullfile(CurrentDevice,RecordName,'*.xml'));%
                                        for ixml=1:length(hsubsubxml)
                                            XmlName=hsubsubxml(ixml).name;
                                            List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile{ixml}=XmlName;
                                            testnew=test_select(XmlName,ListXml,{});
                                            if testnew
                                                ixml_tot=ixml_tot+1;
                                                ListXml{ixml_tot}=XmlName;
                                            end
                                        end 
                                    end              
                                end
                            end
                        end
                    else
                        for ixml=1:length(hsubxml)
                            XmlName=hsubxml(ixml).name;
                            List.Experiment{iexp}.Device{idevice}.xmlfile{ixml}=XmlName;
                            testnew=test_select(XmlName,ListXml,{});
                            if testnew
                                ixml_tot=ixml_tot+1;
                                ListXml{ixml_tot}=XmlName;
                            end
                        end
                    end
                end
            end
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ListDevices: list of devices already scanned
% ListDevices_in: list of input devices to scan
function [testnew,testselect]=test_select(name,ListDevices,ListDevices_in)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(ListDevices_in)
    testnew=0;
    testselect=0;
    for ilist=1:length(ListDevices_in)
        if isequal(name,ListDevices_in{ilist})
            testnew=1;
            testselect=1; 
            break
        end
    end
else
    testnew=1; 
    testselect=1;
end
if testnew
    for ilist=1:length(ListDevices)
         if isequal(name,ListDevices{ilist})
              testnew=0;
              break
         end
    end
end
