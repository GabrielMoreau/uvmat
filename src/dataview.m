%'dataview': function for scanning directories in a campaign 
%------------------------------------------------------------------------
% function varargout = series(varargin)
% associated with the GUI dataview.fig
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
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

function varargout = dataview(varargin)

% Last Modified by GUIDE v2.5 13-Jan-2010 07:28:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dataview_OpeningFcn, ...
                   'gui_OutputFcn',  @dataview_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before dataview is made visible.
function dataview_OpeningFcn(hObject, eventdata, handles, RootDir, SubCampaignTst,GeometryCalib)

% Choose default command line output for dataview
handles.output = 'Cancel';

% Update handles structure
guidata(hObject, handles);
testCancel=1;
testinputstring=0;
icontype='quest';%default question icon (text input asked)

% Determine the position of the dialog - centered on the screen
FigPos=get(0,'DefaultFigurePosition');
OldUnits = get(hObject, 'Units');
set(hObject, 'Units', 'pixels');
OldPos = get(hObject,'Position');
FigWidth = OldPos(3);
FigHeight = OldPos(4);
ScreenUnits=get(0,'Units');
set(0,'Units','pixels');
ScreenSize=get(0,'ScreenSize');
set(0,'Units',ScreenUnits);

FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
FigPos(3:4)=[FigWidth FigHeight];
set(hObject, 'Position', FigPos);
set(hObject, 'Units', OldUnits);

% % Show a question icon from dialogicons.mat - variables questIconData and questIconMap
% load dialogicons.mat
% eval(['IconData=' icontype 'IconData;'])
% eval(['IconCMap=' icontype 'IconMap;'])
% questIconMap(256,:) = get(handles.figure1, 'Color');
% Img=image(IconData, 'Parent', handles.axes1);
% set(handles.figure1, 'Colormap', IconCMap);
% set(handles.axes1, ...
%     'Visible', 'off', ...
%     'YDir'   , 'reverse'       , ...
%     'XLim'   , get(Img,'XData'), ...
%     'YLim'   , get(Img,'YData')  ...
%     );
if exist('GeometryCalib','var')
    DataviewData.GeometryCalib=GeometryCalib;
    set(hObject,'UserData',DataviewData)
end
if exist('SubCampaignTst','var') && isequal(SubCampaignTst,'y')
   set(handles.SubCampaignTest,'Value',1);
end
if exist('RootDir','var') 
   set(handles.RootDirectory,'String',RootDir);
   set(handles.clean_civ_cmx,'Visible','off')
   set(handles.edit_xml,'Visible','off')
   set(handles.HELP,'Visible','off')
   set(handles.OK,'Visible','on')
   set(handles.Cancel,'Visible','on')
   set(handles.figure,'WindowStyle','modal')% Make% Make the GUI modal 
   RootDirectory_Callback(hObject, eventdata, handles)
   % UIWAIT makes translate_points wait for user response (see UIRESUME)
   uiwait(handles.figure);
end



%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = dataview_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in browser.
function browser_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
CurrentFile='/raid/PROJETS';%get(handles.RootDirectory,'String');
set(handles.SubCampaignTest,'Value',0)
CampaignDir=uigetdir(CurrentFile,'Open the Campaign directory'); %file browser
set(handles.RootDirectory,'String',CampaignDir)
RootDirectory_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on button press in open_SubCampaign.
function OpenSubCampaign_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
CurrentFile='/coriolis/bigone/PROJETS';%get(handles.RootDirectory,'String');
set(handles.SubCampaignTest,'Value',1)
CampaignDir=uigetdir(CurrentFile,'Open the Campaign directory'); %file browser
set(handles.RootDirectory,'String',CampaignDir)

RootDirectory_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function RootDirectory_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
CampaignDir=get(handles.RootDirectory,'String');
ExpName={''};
if exist(CampaignDir,'dir')
    hdir=dir(CampaignDir); %list files and dirs
    idir=0;
    for ilist=1:length(hdir)
        if hdir(ilist).isdir
            dirname=hdir(ilist).name;
            if ~isequal(dirname(1),'.')&&~isequal(dirname(1),'0')
                idir=idir+1;
                ExpName{idir}=hdir(ilist).name;
            end
            % look for the list of 'devices'
        else
            %warning for isolated files
        end
    end
    set(handles.ListExperiments,'String',[{'*'};ExpName'])
    set(handles.ListExperiments,'Value',1)
    ListExperiments_Callback(hObject, eventdata, handles)
else
    msgbox_uvmat('ERROR',['The input ' CampaignDir ' is not a directory'])
end

%------------------------------------------------------------------------
% --- Executes on selection change in ListExperiments.
 function ListExperiments_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
CurrentPath=get(handles.RootDirectory,'String');
ListExperiments=get(handles.ListExperiments,'String');
list_val=get(handles.ListExperiments,'Value');
if isequal(list_val(1),1)
    ListExperiments=ListExperiments(2:end); %choose all experiments
    testList=1;
    set(handles.ListExperiments,'Value',1)
else
    ListExperiments=ListExperiments(list_val);%choose selected experiments
    testList=0;
end
set(handles.ListDevices,'Value',1)
set(handles.ListRecords,'Value',1)
set(handles.ListXml,'Value',1)
[ListDevices,ListRecords,ListXml,List]=ListDir(CurrentPath,ListExperiments,{},{});
set(handles.ListRecords,'String',[{'*'};ListRecords'])
set(handles.ListDevices,'String',[{'*'};ListDevices'])
set(handles.ListXml,'String',[{'*'};ListXml'])
if testList
    DataviewData=get(handles.figure,'UserData');
    DataView.List=List;
    set(handles.figure,'UserData',DataviewData)
end
set(handles.CampaignDoc,'Visible','on')
% set(handles.edit_xml,'Visible','on')

%------------------------------------------------------------------------
% --- Executes on button press in update_headings.
function ListDevices_Callback(hObject, eventdata, handles)
CurrentPath=get(handles.RootDirectory,'String');
ListExperiments=get(handles.ListExperiments,'String');
list_val=get(handles.ListExperiments,'Value');
if isequal(list_val,1)
    ListExperiments=ListExperiments(2:end);
else
    ListExperiments=ListExperiments(list_val);
end
set(handles.ListRecords,'Value',1)
set(handles.ListXml,'Value',1)
ListDevices=get(handles.ListDevices,'String');
list_val=get(handles.ListDevices,'Value');
if isequal(list_val,1)
    ListDevices=ListDevices(2:end);
else
    ListDevices=ListDevices(list_val);
end
[ListDevices,ListRecords,ListXml]=ListDir(CurrentPath,ListExperiments,ListDevices,{});
set(handles.ListRecords,'String',[{'*'};ListRecords'])
set(handles.ListXml,'String',[{'*'};ListXml'])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%------------------------------------------------------------------------
% --- Executes on selection change in ListRecords.
function ListRecords_Callback(hObject, eventdata, handles)
Value=get(handles.ListRecords,'Value');
if isequal(Value(1),1)
    set(handles.ListRecords,'Value',1);
end

%------------------------------------------------------------------------
% --- Executes on button press in CampaignDoc.
function CampaignDoc_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------   
answer=msgbox_uvmat('INPUT_Y-N','This function will update the global xml rpresentation of the data set and the Heading of each xml file')
if ~isequal(answer{1},'OK')
    return
end
set(handles.ListExperiments,'Value',1)
ListExperiments_Callback(hObject, eventdata, handles)%update the overview of the experiment directories
DataviewData=get(handles.figure,'UserData');
List=DataviewData.List;
Currentpath=get(handles.RootDirectory,'String');
[Currentpath,Campaign,DirExt]=fileparts(Currentpath);
Campaign=[Campaign DirExt];
t=xmltree;
t=set(t,1,'name','CampaignDoc');
t = attributes(t,'add',1,'source','directory');
SubCampaignTest=get(handles.SubCampaignTest,'Value');
root_uid=1;
if SubCampaignTest
    %TO DO open an exoiting xml doc
    [t,root_uid]=add(t,1,'element','SubCampaign');
    t =attributes(t,'add',root_uid,'DirName',Campaign);
end
for iexp=1:length(List.Experiment)
    set(handles.ListExperiments,'Value',iexp+1)
    drawnow
    test_mod=0;
    [t,uid_exp]=add(t,root_uid,'element','Experiment');
    t = attributes(t,'add',uid_exp,'i',num2str(iexp));
    ExpName=List.Experiment{iexp}.name;
    t = attributes(t,'add',uid_exp,'DirName',List.Experiment{iexp}.name);
   
    if isfield(List.Experiment{iexp},'Device')
        for idevice=1:length(List.Experiment{iexp}.Device)
            [t,uid_device]=add(t,uid_exp,'element','Device');
            DeviceName=List.Experiment{iexp}.Device{idevice}.name;
            t = attributes(t,'add',uid_device,'DirName',List.Experiment{iexp}.Device{idevice}.name);       
            if isfield(List.Experiment{iexp}.Device{idevice},'xmlfile')
                for ixml=1:length(List.Experiment{iexp}.Device{idevice}.xmlfile)
                    FileName=List.Experiment{iexp}.Device{idevice}.xmlfile{ixml};
                    [Title,test]=check_heading(Currentpath,Campaign,ExpName,DeviceName,[],FileName,SubCampaignTest);
                    if test
                        [List.Experiment{iexp}.Device{idevice}.xmlfile{ixml} ' , Heading updated']
                    end
                    if isequal(Title,'ImaDoc')
                        [t,uid_xml]=add(t,uid_device,'element','ImaDoc');
                        t = attributes(t,'add',uid_xml,'source','file');
                        [t]=add(t,uid_xml,'chardata',List.Experiment{iexp}.Device{idevice}.xmlfile{ixml});                    
                    end
                end
             elseif isfield(List.Experiment{iexp}.Device{idevice},'Record')
                for irecord=1:length(List.Experiment{iexp}.Device{idevice}.Record)
                    RecordName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.name;
                    [t,uid_record]=add(t,uid_device,'element','Record');
                    t = attributes(t,'add',uid_record,'DirName',RecordName);
                    if isfield(List.Experiment{iexp}.Device{idevice}.Record{irecord},'xmlfile')
                        for ixml=1:length(List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile)
                            FileName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile{ixml};
                            [Title,test]=check_heading(Currentpath,Campaign,ExpName,DeviceName,RecordName,FileName,SubCampaignTest);
                            if test
                                [FileName ' , Heading updated']
                            end
                            [t,uid_xml]=add(t,uid_record,'element','ImaDoc');
                            t = attributes(t,'add',uid_xml,'source','file');
                            [t]=add(t,uid_xml,'chardata',FileName);
                        end
                    end
                end
            end
        end
    end
end
set(handles.ListExperiments,'Value',1)
outputdir=get(handles.RootDirectory,'String');
[path,dirname]=fileparts(outputdir);
outputfile=fullfile(outputdir,[dirname '.xml']);
%campaigndoc(t);
save(t,outputfile)

%------------------------------------------------------------------------
% --- Executes on button press in CampaignDoc.
function edit_xml_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
CurrentPath=get(handles.RootDirectory,'String');
%[CurrentPath,Name,Ext]=fileparts(CurrentDir);
ListExperiments=get(handles.ListExperiments,'String');
Value=get(handles.ListExperiments,'Value');
if ~isequal(Value,1)
    ListExperiments=ListExperiments(Value);
end
ListDevices=get(handles.ListDevices,'String');
Value=get(handles.ListDevices,'Value');
if ~isequal(Value,1)
    ListDevices=ListDevices(Value);
end
ListRecords=get(handles.ListRecords,'String');
Value=get(handles.ListRecords,'Value');
if ~isequal(Value,1)
    ListRecords=ListRecords(Value);
end
[ListDevices,ListRecords,ListXml,List]=ListDir(CurrentPath,ListExperiments,ListDevices,ListRecords);
ListXml=get(handles.ListXml,'String');
Value=get(handles.ListXml,'Value');
set(handles.ListXml,'Value',Value(1));
if isequal(Value(1),1)
    warndlg_uvmat('an xml file needs to be selected','ERROR')
   return
else
    XmlName=ListXml{Value(1)};
end
for iexp=1:length(List.Experiment)
    ExpName=List.Experiment{iexp}.name;
    if isfield(List.Experiment{iexp},'Device')
        for idevice=1:length(List.Experiment{iexp}.Device)
            DeviceName=List.Experiment{iexp}.Device{idevice}.name;
            if isfield(List.Experiment{iexp}.Device{idevice},'xmlfile')
                for ixml=1:length(List.Experiment{iexp}.Device{idevice}.xmlfile)
                    FileName=List.Experiment{iexp}.Device{idevice}.xmlfile{ixml}
                    if isequal(FileName,XmlName)
                        editxml(fullfile(CurrentPath,ExpName,DeviceName,FileName));
                        return
                    end
                end
             elseif isfield(List.Experiment{iexp}.Device{idevice},'Record')
                for irecord=1:length(List.Experiment{iexp}.Device{idevice}.Record)
                    RecordName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.name;
                    if isfield(List.Experiment{iexp}.Device{idevice}.Record{irecord},'xmlfile')
                        for ixml=1:length(List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile)
                            FileName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile{ixml};
                            if isequal(FileName,XmlName)
                                editxml(fullfile(CurrentPath,ExpName,DeviceName,RecordName,FileName));
                                return
                            end                          
                        end
                    end
                end
            end
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CurrentPath/Campaign: root directory 
function  [Title,test_mod]=check_heading(Currentpath,Campaign,Experiment,Device,Record,xmlname,testSubCampaign)

 %Shema for Heading:
%  Campaign             
%  (SubCampaign)
% Experiment
%  Device
%  (Record)
%  ImageName
%  DateExp
%                 old: %Project: suppressed ( changed to Campaign)
                       %Exp: suppressed (changed to experiment)
                       %ImaNames: changed to ImageName
if exist('Record','var') && ~isempty(Record)
    xmlfullname=fullfile(Currentpath,Campaign,Experiment,Device,Record,xmlname);  
    testrecord=1;
else
    xmlfullname=fullfile(Currentpath,Campaign,Experiment,Device,xmlname); 
    testrecord=0;
end
if ~exist('testSubCampaign','var')
    testSubCampaign=0;
end
if testSubCampaign
   SubCampaign=Campaign;
   [Currentpath,Campaign,DirExt]=fileparts(Currentpath);
   Campaign=[Campaign DirExt];
end
test_mod=0; %test for the modification of the xml file
t_device=xmltree(xmlfullname);
Title=get(t_device,1,'name');
uid_child=children(t_device,1);
Heading_old=[];
uidheading=0;
for ilist=1:length(uid_child)
    name=get(t_device,uid_child(ilist),'name');
    if isequal(name,'Heading')
        uidheading=uid_child(ilist);
    end
end
if uidheading
    subt=branch(t_device,uidheading);
    Heading_old=convert(subt);
else
   return % do not edit xml files without element 'Heading'
end
if ~(isfield(Heading_old,'Campaign')&& isequal(Heading_old.Campaign,Campaign))
    test_mod=1;
end
Heading.Campaign=Campaign;
if testSubCampaign
    if ~(isfield(Heading_old,'SubCampaign')&& isequal(Heading_old.SubCampaign,SubCampaign))
        test_mod=1;
    end
    Heading.SubCampaign=SubCampaign;
end
if ~(isfield(Heading_old,'Experiment')&& isequal(Heading_old.Experiment,Experiment))
    test_mod=1;
end
Heading.Experiment=Experiment;
if ~(isfield(Heading_old,'Device')&& isequal(Heading_old.Device,Device))
    test_mod=1;
end
Heading.Device=Device;
if testrecord
    if ~(isfield(Heading_old,'Record')&& isequal(Heading_old.Record,Record))
        test_mod=1;
    end
    Heading.Record=Record;
end
if isfield(Heading_old,'ImaNames')
    test_mod=1;
    if  ~isempty(Heading_old.ImaNames)
        Heading.ImageName=Heading_old.ImaNames;
    end
end
if isfield(Heading_old,'ImageName')&& ~isempty(Heading_old.ImageName)
    Heading.ImageName=Heading_old.ImageName;
end
if isfield(Heading_old,'DateExp')&& ~isempty(Heading_old.DateExp)
    Heading.DateExp=Heading_old.DateExp;
end
if test_mod && uidheading
     uid_child=children(t_device,uidheading);
     t_device=delete(t_device,uid_child);
    t_device=struct2xml(Heading,t_device,uidheading);
    backupfile=xmlfullname;
    testexist=2;
    while testexist==2
       backupfile=[backupfile '~'];
       testexist=exist(backupfile,'file');
    end
    [success,message]=copyfile(xmlfullname,backupfile);%make backup
    if isequal(success,1)
        delete(xmlfullname)
    else
        return
    end
    save(t_device,xmlfullname)
end

%------------------------------------------------------------------------
% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
path_to_uvmat=which ('uvmat')% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
web([helpfile '#dataview'])    
end



% --- Executes on selection change in ListXml.
function ListXml_Callback(hObject, eventdata, handles)
Value=get(handles.ListXml,'Value');
if isequal(Value(1),1)
    set(handles.ListXml,'Value',1);
end


% --- Executes on button press in clean_civ_cmx.
function clean_civ_cmx_Callback(hObject, eventdata, handles)
message='this function will delete all files with extensions .log, .bat, .cmx,.cmx2,.errors in the input directory(ies)';
answer=msgbox_uvmat('INPUT_Y-N',message);
if ~isequal(answer{1},'OK')
    return
end
set(handles.ListExperiments,'Value',1)
ListExperiments_Callback(hObject, eventdata, handles)%update the overview of the experiment directories
DataviewData=get(handles.figure,'UserData');
List=DataviewData.List;
Currentpath=get(handles.RootDirectory,'String');
[Currentpath,Campaign,DirExt]=fileparts(Currentpath);
Campaign=[Campaign DirExt];
SubCampaignTest=get(handles.SubCampaignTest,'Value');
nbdelete_tot=0;
for iexp=1:length(List.Experiment)
    set(handles.ListExperiments,'Value',iexp+1)
    drawnow
    test_mod=0;
    ExpName=List.Experiment{iexp}.name;  
    nbdelete=0;
    if isfield(List.Experiment{iexp},'Device')
        for idevice=1:length(List.Experiment{iexp}.Device)
            DeviceName=List.Experiment{iexp}.Device{idevice}.name;     
            if isfield(List.Experiment{iexp}.Device{idevice},'xmlfile')
                currentdir=fullfile(Currentpath,Campaign,ExpName,DeviceName);
                hdir=dir(currentdir); %list files and dirs
                idir=0;
                for ilist=1:length(hdir)
                    if hdir(ilist).isdir
                        dirname=hdir(ilist).name;
                        if ~isequal(dirname(1),'.')&&~isequal(dirname(1),'0')
                            CivDir=fullfile(currentdir,dirname)
                            hCivDir=dir(CivDir);
                            for ilist=1:length(hCivDir)
                                FileName=hCivDir(ilist).name;
                                [dd,ff,Ext]=fileparts(FileName);
                                if isequal(Ext,'.log')||isequal(Ext,'.bat')||isequal(Ext,'.cmx')||isequal(Ext,'.cmx2')|| isequal(Ext,'.errors')
                                    delete(fullfile(CivDir,FileName))
                                    nbdelete=nbdelete+1;
                                end
                            end
                        end
                    end
                end
             elseif isfield(List.Experiment{iexp}.Device{idevice},'Record')
                for irecord=1:length(List.Experiment{iexp}.Device{idevice}.Record)
                    RecordName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.name;
                    if isfield(List.Experiment{iexp}.Device{idevice}.Record{irecord},'xmlfile')
                        'look at subdirectories'
                    end
                end
            end
        end
    end
    display([num2str(nbdelete) ' files deleted'])
    nbdelete_tot=nbdelete_tot+nbdelete;
end
msgbox_uvmat('CONFIRMATION',['END: ' num2str(nbdelete_tot) ' files deleted by clean_civ_cmx'])
set(handles.ListExperiments,'Value',1)


% --- Executes on button press in OK.
function OK_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
CurrentPath=get(handles.RootDirectory,'String');
ListExperiments=get(handles.ListExperiments,'String');
IndicesExp=get(handles.ListExperiments,'Value');
if ~isequal(IndicesExp,1)
    ListExperiments=ListExperiments(IndicesExp);
end
ListDevices=get(handles.ListDevices,'String');
Value=get(handles.ListDevices,'Value');
if isequal(Value,1)
    msgbox_uvmat('ERROR','manually select in the GUI dataview the device being calibrated')
    return
else 
    ListDevices=ListDevices(Value);
end
ListRecords=get(handles.ListRecords,'String');
Value=get(handles.ListRecords,'Value');
if ~isequal(Value,1)
    ListRecords=ListRecords(Value);
end
[ListDevices,ListRecords,ListXml,List]=ListDir(CurrentPath,ListExperiments,ListDevices,ListRecords);
ListXml=get(handles.ListXml,'String');
Value=get(handles.ListXml,'Value');
if isequal(Value,1)
    msgbox_uvmat('ERROR','you need to select in the GUI dataview the xml files to edit')
    return
else
    ListXml=ListXml(Value);
end

%update all the selected xml files
DataviewData=get(handles.figure,'UserData');
% answer=msgbox_uvmat('INPUT_Y-N',[num2str(length(Value)) ' xml files for device ' ListDevices{1} ' will be refreshed with ' ...
%     DataviewData.GeometryCalib.CalibrationType ' calibration data'])
% if ~isequal(answer,'Yes')
%     return
% end
%List.Experiment{1}.Device{1}
%List.Experiment{2}.Device{1}
for iexp=1:length(List.Experiment)
    ExpName=List.Experiment{iexp}.name;
    set(handles.ListExperiments,'Value',IndicesExp(iexp));
    if isfield(List.Experiment{iexp},'Device')
        for idevice=1:length(List.Experiment{iexp}.Device)
            DeviceName=List.Experiment{iexp}.Device{idevice}.name;      
            if isfield(List.Experiment{iexp}.Device{idevice},'xmlfile')
                for ixml=1:length(List.Experiment{iexp}.Device{idevice}.xmlfile)
                    FileName=List.Experiment{iexp}.Device{idevice}.xmlfile{ixml};
                    for ilistxml=1:length(ListXml)
                        if isequal(FileName,ListXml{ilistxml})
                            set(handles.ListXml,'Value',Value(ilistxml))
                            drawnow
                            xmlfullname=fullfile(CurrentPath,ExpName,DeviceName,FileName);
                            update_imadoc(DataviewData.GeometryCalib,xmlfullname)
                            display([xmlfullname ' updated'])
                            break
                        end
                    end
                end
             elseif isfield(List.Experiment{iexp}.Device{idevice},'Record')
                for irecord=1:length(List.Experiment{iexp}.Device{idevice}.Record)
                    RecordName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.name;
                    if isfield(List.Experiment{iexp}.Device{idevice}.Record{irecord},'xmlfile')
                        for ixml=1:length(List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile)
                            FileName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile{ixml};
                            for ilistxml=1:length(ListXml)
                                if isequal(FileName,ListXml{ilistxml})
                                    set(handles.ListXml,'Value',Value(ilistxml))
                                    drawnow
                                    xmlfullname=fullfile(CurrentPath,ExpName,DeviceName,RecordName,FileName);
                                    update_imadoc(DataviewData.GeometryCalib,xmlfullname)
                                    display([xmlfullname ' updated'])
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
set(handles.ListXml,'Value',Value)   
%     
%     
%     
%     
%     
%     
%     
% CurrentPath=get(handles.RootDirectory,'String');%= get(hObject,'String');
% ListExperiments=get(handles.ListExperiments,'String');
% Value=get(handles.ListExperiments,'Value');
% if ~isequal(Value,1)
%     ListExperiments=ListExperiments(Value);
% end
% ListDevices=get(handles.ListDevices,'String');
% Value=get(handles.ListDevices,'Value');
% if isequal(Value,1)
%     msgbox_uvmat('ERROR','manually select in the GUI dataview the device being calibrated')
%     return
% else 
%     ListDevices=ListDevices(Value);
% end
% ListRecords=get(handles.ListRecords,'String');
% Value=get(handles.ListRecords,'Value');
% if ~isequal(Value,1)
%     ListRecords=ListRecords(Value);
% end
% [ListDevices,ListRecords,ListXml,List]=ListDir(CurrentPath,ListExperiments,ListDevices,ListRecords);
% ListXml=get(handles.ListXml,'String');
% Value=get(handles.ListXml,'Value');
% if isequal(Value,1)
%     msgbox_uvmat('ERROR','you need to select in the GUI dataview the xml files to edit')
%     return
% else
%     ListXml=ListXml(Value);
% end
% handles.output.CurrentPath=CurrentPath;
% handles.output.ListExperiments=ListExperiments;
% handles.output.ListDevices=ListDevices;
% handles.output.ListRecords=ListRecords;
% handles.output.ListXml=ListXml;
% handles.output.List=List;
handles.output ='OK, Calibration replicated';
guidata(hObject, handles);% Update handles structure
uiresume(handles.figure);

% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
handles.output = get(hObject,'String');
guidata(hObject, handles); % Update handles structure
% Use UIRESUME instead of delete because the OutputFcn needs
uiresume(handles.figure);

% --- Executes when user attempts to close figure.
function figure_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(handles.figure, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(handles.figure);
else
    % The GUI is no longer waiting, just close it
    delete(handles.figure);
end

% --- Executes on key press over figure1 with no controls selected.
function figure_KeyPressFcn(hObject, eventdata, handles)
% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    % User said no by hitting escape
    handles.output = 'Cancel';
    
    % Update handles structure
    guidata(hObject, handles);
    
    uiresume(handles.figure);
end
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.figure);
end 