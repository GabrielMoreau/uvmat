%'browse_data': function for scanning directories in a campaign 
%------------------------------------------------------------------------
% function varargout = series(varargin)
% associated with the GUI browse_data.fig

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

function varargout = browse_data(varargin)

% Last Modified by GUIDE v2.5 11-Mar-2014 22:09:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @browse_data_OpeningFcn, ...
                   'gui_OutputFcn',  @browse_data_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ~isempty(regexp(varargin{1},'_Callback','once'))              
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%------------------------------------------------------------------------
% --- Executes just before browse_data is made visible.
function browse_data_OpeningFcn(hObject, eventdata, handles, Campaign,EnableMirror)
%------------------------------------------------------------------------

%% Choose default command line output for browse_data
handles.output = 'Cancel';

%% Update handles structure
guidata(hObject, handles);
set(hObject,'WindowButtonDownFcn',{'mouse_down'}) % allows mouse action with right button (zoom for uicontrol display)

%% Determine the position of the dialog - centered on the screen
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
if exist('EnableMirror','var') && strcmp(EnableMirror,'on')
    set(handles.CreateMirror,'Visible','on')
    set(handles.mirror_txt,'Visible','on')
else
    set(handles.CreateMirror,'Visible','off')
    set(handles.mirror_txt,'Visible','off')
end
if exist('Campaign','var')
    [tild,CampaignName]=fileparts(Campaign);
    RootXml=fullfile(Campaign,[CampaignName '.xml']);
    s=[];
    if exist(RootXml,'file') 
        [s,Heading]=xml2struct(RootXml);%read the xml file
        if isfield(s,'SourceDir')
            set(handles.SourceDir,'String',s.SourceDir);%display the source dir if a mirror has been opened
            set(handles.MirrorDir,'Visible','on');%  mirror dir display
            set(handles.MirrorDir,'String',Campaign);%display the opened mirror dir
            set(handles.CreateMirror,'String','update_mirror')
        end
    end
    if isempty(s) %a source dir has been opened
        set(handles.SourceDir,'String',Campaign);
        set(handles.MirrorDir,'Visible','off');% no mirror dir display
        set(handles.CreateMirror,'String','create_mirror')
    end
    errormsg=scan_campaign(handles,Campaign);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg)
        return
    end
    set(handles.OK,'Visible','on')
    set(handles.Cancel,'Visible','on')
    set(handles.browse_data,'WindowStyle','modal')% Make the GUI modal
    set(hObject,'Visible','on')
    drawnow
    % UIWAIT makes GUI wait for user response (see UIRESUME)
    uiwait(handles.browse_data);
end


%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = browse_data_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.browse_data)

%------------------------------------------------------------------------
% --- Executes on button press in CreateMirror.
function CreateMirror_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.SourceDir,'BackgroundColor',[1 1 0])% indicate action of button by yellow color
drawnow
SourceDir=get(handles.SourceDir,'String');
[SourcePath,ProjectName]=fileparts(SourceDir);
if strcmp(get(handles.MirrorDir,'Visible'),'on')
    MirrorDir=get(handles.MirrorDir,'String');% name of the mirror folder
else% create the mirror folder if it does not exist
    MirrorRoot=uigetfile_uvmat('select the folder which must contain the mirror directory:',SourcePath,'uigetdir');
    if isempty(MirrorRoot)
        return
    elseif strcmp(MirrorRoot,SourcePath)
        msgbox_uvmat('ERROR','The mirror folder must be different from the source')
        return
    else
        MirrorDir=fullfile(MirrorRoot,ProjectName);
    end
    if exist(MirrorDir,'dir')
        msgbox_uvmat('ERROR',['The folder ' MirrorDir ' chosen as new mirror campaign already exists']) 
        return
    else
        [s,errormsg]=mkdir(MirrorDir)% create the mirror dir
        if s~=1
            msgbox_uvmat('ERROR',['error in creating ' MirrorDir ': ' errormsg]) 
            return
        end
    end
    MirrorDoc.SourceDir=SourceDir;
    t=struct2xml(MirrorDoc);
    set(t,1,'name','DataTree');
    save(t,fullfile(MirrorDir,[ProjectName '.xml']))% create an xml file in the mirror folder to indicate its source folder
    set(handles.MirrorDir,'String',MirrorDir)
    set(handles.MirrorDir,'Visible','on')
    set(handles.CreateMirror,'String','update_mirror')
end
ExpName={''};

%% update the mirror from the source dir
if exist(SourceDir,'dir')
    hdir=dir(SourceDir); %list files and dirs
    idir=0;
    for ilist=1:length(hdir)
        if hdir(ilist).isdir% scan all subfolders
            dirname=hdir(ilist).name;%
            if ~isequal(dirname(1),'.')&&~isequal(dirname(1),'0')%skip subfolder beginning by '0'
                idir=idir+1;
                mirror=fullfile(MirrorDir,hdir(ilist).name);% corresponding name in the mirror
                if ~exist(mirror,'dir')
                   mkdir(mirror)% create the mirror folder if it does not exist
                end
                ExpName{idir}=['+/' hdir(ilist).name];% insert '+/' in the list to show that it is a folder
            end
            % look for the list of 'devices'
        else
            %warning for isolated files
        end
    end
    set(handles.ListExperiments,'String',[{'*'};ExpName'])
    set(handles.ListExperiments,'Value',1)
     update_experiments(handles,[{'*'};ExpName'],SourceDir,MirrorDir)
   % ListExperiments_Callback(hObject, eventdata, handles) % list the content of the experiment
else
    msgbox_uvmat('ERROR',['The input ' SourceDir ' is not a directory'])
end
set(handles.SourceDir,'BackgroundColor',[1 1 1])


%------------------------------------------------------------------------
function errormsg=scan_campaign(handles,Campaign)
%------------------------------------------------------------------------
%set(handles.SourceDir,'BackgroundColor',[1 1 0])
%drawnow
%SourceDir=get(handles.SourceDir,'String');
%MirrorDir=get(handles.MirrorDir,'String');
% ExpName={''};
errormsg='';
if exist(Campaign,'dir')
    ListStruct=dir(Campaign); %list files and dirs
    if numel(ListStruct)>1000% A campaign folder must contain maily a list of 'experiment' sub-folders
        errormsg=[Campaign ' contains too many items (>1000) to be a Campaign folder'];
        return
    end
    ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
    ListFiles=ListCells(1,:);%list of dir and file  names
    check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
    ListFiles(check_dir)=regexprep(ListFiles(check_dir),'^.+','+/$0');% put '+/' in front of dir name display
    cell_remove=regexp(ListFiles,'^(-|\.|\+/\.)');% detect strings beginning by '-' ,'.' or '+/.'(dir beginning by . )
    check_keep=cellfun('isempty', cell_remove);
    ListFiles=sort((ListFiles(check_keep))');
    set(handles.ListExperiments,'String',[{'*'};ListFiles])
    set(handles.ListExperiments,'Value',1)
    ListExperiments_Callback([],[], handles)
else
    msgbox_uvmat('ERROR',['The input ' Campaign ' is not a directory'])
end
%set(handles.SourceDir,'BackgroundColor',[1 1 1])


%------------------------------------------------------------------------
% --- Executes on selection change in ListExperiments.
%------------------------------------------------------------------------
 function ListExperiments_Callback(hObject, eventdata, handles)

if strcmp(get(handles.MirrorDir,'Visible'),'on')
    MirrorPath=get(handles.MirrorDir,'String');
else
    MirrorPath=get(handles.SourceDir,'String');
end
ListExperiments=get(handles.ListExperiments,'String');
list_val=get(handles.ListExperiments,'Value');
if isequal(list_val(1),1)
    ListExperiments=ListExperiments(2:end); %choose all experiments if the first line '*' is selected
    set(handles.ListExperiments,'Value',1)
else
    ListExperiments=ListExperiments(list_val);%choose selected experiments
end
list_dataseries(handles,ListExperiments,MirrorPath)

%------------------------------------------------------------------------
% --- List the DataSeries when a set of experiments is selected
%------------------------------------------------------------------------
 function list_dataseries(handles,ListExperiments,MirrorPath)

ListDevices={};
for iexp=1:numel(ListExperiments)
    if strcmp(ListExperiments{iexp}(1),'+')% if the item is a directory
        ListExperiments{iexp}(1)=[];%remove the first char '+' used to mark folders
        ListStruct=dir(fullfile(MirrorPath,ListExperiments{iexp})); %list files and dir in the source experiment directory
        ListCells=struct2cell(ListStruct);%transform dir struct to a cell arrray
        ListFiles=ListCells(1,:);%list of dir and file  names
        cell_remove=regexp(ListFiles,'^(-|\.|\+/\.)');% detect strings beginning by '-' ,'.' or '+/.'(dir beginning by . )
        check_keep=cellfun('isempty', cell_remove);
        check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
        for ilist=1:numel(ListFiles)
            if check_keep(ilist)% loop on eligible DataSeries folders
                mirror=fullfile(MirrorPath,ListExperiments{iexp},ListFiles{ilist});%source folder
                if ~exist(mirror,'file') && ~exist(mirror,'dir')% if the name is a broken link
                    delete(mirror)% delete broken link
                else %update the list of dataSeries
                    [tild,msg]=fileattrib(mirror);
                    if ~strcmp(msg.Name,mirror)% if it is a link
                        ListFiles{ilist}=['~' ListFiles{ilist}];%mark link by '@' in the list
                    end
                    if check_dir(ilist)
                        ListFiles{ilist}=['+/' ListFiles{ilist}];%mark dir by '+' in the list
                    end
                    if isempty(find(strcmp(ListFiles{ilist},ListDevices), 1))% if the item is not already in ListDevices
                        ListDevices=[ListDevices;ListFiles{ilist}]; %append the item to the list
                    end                   
                end
            end
        end
    end
end
set(handles.ListDevices,'String',sort(ListDevices))

%------------------------------------------------------------------------
% --- Executes when the mirror is created or updated
%------------------------------------------------------------------------
 function update_experiments(handles,ListExperiments,CampaignPath,MirrorPath)

ListDevices={};
for iexp=1:numel(ListExperiments)
    if strcmp(ListExperiments{iexp}(1),'+')% if the item is a directory
        ListExperiments{iexp}(1)=[];
        ListStruct=dir(fullfile(CampaignPath,ListExperiments{iexp})); %list files and dir in the source experiment directory
        ListCells=struct2cell(ListStruct);%transform dir struct to a cell arrray
        ListFiles=ListCells(1,:);%list of dir and file  names
        cell_remove=regexp(ListFiles,'^(-|\.|\+/\.)');% detect strings beginning by '-' ,'.' or '+/.'(dir beginning by . )
        check_keep=cellfun('isempty', cell_remove);
        check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
        for ilist=1:numel(ListFiles)
            if check_keep(ilist)% loop on eligible DataSeries folders
                DataSeries=fullfile(CampaignPath,ListExperiments{iexp},ListFiles{ilist});%source folder
                if ~isempty(MirrorPath)
                    mirror=fullfile(MirrorPath,ListExperiments{iexp},ListFiles{ilist});
                    if exist(mirror,'file')% if mirror already exists as a file or folder
                        [tild,msg]=fileattrib(mirror);
                        if strcmp(msg.Name,mirror)%if the mirror name already exists as a local file or dir
                            if msg.directory% case of a folder
                                answer=msgbox_uvmat('INPUT_Y-N',['replace local folder ' msg.Name ' by a link to the source dir']);
                                if strcmp(answer,'Yes')
                                    [ss,msg]=rmdir(mirror);
                                    if ss==1
                                        system(['ln -s ' DataSeries ' ' mirror]); % create the link to the source folder
                                    else
                                        msgbox_uvmat('ERROR',['enable to delete local folder: ' msg]);
                                    end
                                end
                            else % case of an existing mirror file
                                answer=msgbox_uvmat('INPUT_Y-N',['replace local file ' msg.Name ' by a link to the source file']);
                                if strcmp(answer,'Yes')
                                    delete(mirror);
                                    system(['ln -s ' DataSeries ' ' mirror]); % create the link to the source folder                                  
                                end
                            end
                        end
                    else% create mirror to the data series if needed
                        system(['ln -s ' DataSeries ' ' mirror]); % create the link to the source folder                     
                    end
                    if isempty(find(strcmp(ListFiles{ilist},ListDevices), 1))% if the item is not already in ListDevices
                        if check_dir(ilist)
                            ListFiles{ilist}=['+/' ListFiles{ilist}];%mark dir by '+' in the list
                        end
                        ListDevices=[ListDevices;ListFiles{ilist}]; %append the item to the list
                    end
                end
            end
        end
    end
end
set(handles.ListDevices,'String',sort(ListDevices))

%------------------------------------------------------------------------
% --- Executes on button press in CampaignDoc.
function CampaignDoc_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------   
answer=msgbox_uvmat('INPUT_Y-N','This function will update the global xml rpresentation of the data set and the Heading of each xml file');
if ~isequal(answer{1},'OK')
    return
end
set(handles.ListExperiments,'Value',1)
ListExperiments_Callback(hObject, eventdata, handles)%update the overview of the experiment directories
DataviewData=get(handles.browse_data,'UserData');
List=DataviewData.List;
Currentpath=get(handles.SourceDir,'String');
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
                        disp([List.Experiment{iexp}.Device{idevice}.xmlfile{ixml} ' , Heading updated'])
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
                                disp([FileName ' , Heading updated'])
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
outputdir=get(handles.SourceDir,'String');
[path,dirname]=fileparts(outputdir);
outputfile=fullfile(outputdir,[dirname '.xml']);
%campaigndoc(t);
save(t,outputfile)

% %------------------------------------------------------------------------
% % --- Executes on button press in CampaignDoc.
% function edit_xml_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% CurrentPath=get(handles.SourceDir,'String');
% %[CurrentPath,Name,Ext]=fileparts(CurrentDir);
% ListExperiments=get(handles.ListExperiments,'String');
% Value=get(handles.ListExperiments,'Value');
% if ~isequal(Value,1)
%     ListExperiments=ListExperiments(Value);
% end
% ListDevices=get(handles.ListDevices,'String');
% Value=get(handles.ListDevices,'Value');
% if ~isequal(Value,1)
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
% set(handles.ListXml,'Value',Value(1));
% if isequal(Value(1),1)
%     msgbox_uvmat('ERROR','an xml file needs to be selected')
%    return
% else
%     XmlName=ListXml{Value(1)};
% end
% for iexp=1:length(List.Experiment)
%     ExpName=List.Experiment{iexp}.name;
%     if isfield(List.Experiment{iexp},'Device')
%         for idevice=1:length(List.Experiment{iexp}.Device)
%             DeviceName=List.Experiment{iexp}.Device{idevice}.name;
%             if isfield(List.Experiment{iexp}.Device{idevice},'xmlfile')
%                 for ixml=1:length(List.Experiment{iexp}.Device{idevice}.xmlfile)
%                     FileName=List.Experiment{iexp}.Device{idevice}.xmlfile{ixml};
%                     if isequal(FileName,XmlName)
%                         editxml(fullfile(CurrentPath,ExpName,DeviceName,FileName));
%                         return
%                     end
%                 end
%              elseif isfield(List.Experiment{iexp}.Device{idevice},'Record')
%                 for irecord=1:length(List.Experiment{iexp}.Device{idevice}.Record)
%                     RecordName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.name;
%                     if isfield(List.Experiment{iexp}.Device{idevice}.Record{irecord},'xmlfile')
%                         for ixml=1:length(List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile)
%                             FileName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile{ixml};
%                             if isequal(FileName,XmlName)
%                                 editxml(fullfile(CurrentPath,ExpName,DeviceName,RecordName,FileName));
%                                 return
%                             end                          
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % CurrentPath/Campaign: root directory 
% function  [Title,test_mod]=check_heading(Currentpath,Campaign,Experiment,Device,Record,xmlname,testSubCampaign)
% 
%  %Shema for Heading:
% %  Campaign             
% %  (SubCampaign)
% % Experiment
% %  Device
% %  (Record)
% %  ImageName
% %  DateExp
% %                 old: %Project: suppressed ( changed to Campaign)
%                        %Exp: suppressed (changed to experiment)
%                        %ImaNames: changed to ImageName
% if exist('Record','var') && ~isempty(Record)
%     xmlfullname=fullfile(Currentpath,Campaign,Experiment,Device,Record,xmlname);  
%     testrecord=1;
% else
%     xmlfullname=fullfile(Currentpath,Campaign,Experiment,Device,xmlname); 
%     testrecord=0;
% end
% if ~exist('testSubCampaign','var')
%     testSubCampaign=0;
% end
% if testSubCampaign
%    SubCampaign=Campaign;
%    [Currentpath,Campaign,DirExt]=fileparts(Currentpath);
%    Campaign=[Campaign DirExt];
% end
% test_mod=0; %test for the modification of the xml file
% t_device=xmltree(xmlfullname);
% Title=get(t_device,1,'name');
% uid_child=children(t_device,1);
% Heading_old=[];
% uidheading=0;
% for ilist=1:length(uid_child)
%     name=get(t_device,uid_child(ilist),'name');
%     if isequal(name,'Heading')
%         uidheading=uid_child(ilist);
%     end
% end
% if uidheading
%     subt=branch(t_device,uidheading);
%     Heading_old=convert(subt);
% else
%    return % do not edit xml files without element 'Heading'
% end
% if ~(isfield(Heading_old,'Campaign')&& isequal(Heading_old.Campaign,Campaign))
%     test_mod=1;
% end
% Heading.Campaign=Campaign;
% if testSubCampaign
%     if ~(isfield(Heading_old,'SubCampaign')&& isequal(Heading_old.SubCampaign,SubCampaign))
%         test_mod=1;
%     end
%     Heading.SubCampaign=SubCampaign;
% end
% if ~(isfield(Heading_old,'Experiment')&& isequal(Heading_old.Experiment,Experiment))
%     test_mod=1;
% end
% Heading.Experiment=Experiment;
% if ~(isfield(Heading_old,'Device')&& isequal(Heading_old.Device,Device))
%     test_mod=1;
% end
% Heading.Device=Device;
% if testrecord
%     if ~(isfield(Heading_old,'Record')&& isequal(Heading_old.Record,Record))
%         test_mod=1;
%     end
%     Heading.Record=Record;
% end
% if isfield(Heading_old,'ImaNames')
%     test_mod=1;
%     if  ~isempty(Heading_old.ImaNames)
%         Heading.ImageName=Heading_old.ImaNames;
%     end
% end
% if isfield(Heading_old,'ImageName')&& ~isempty(Heading_old.ImageName)
%     Heading.ImageName=Heading_old.ImageName;
% end
% if isfield(Heading_old,'DateExp')&& ~isempty(Heading_old.DateExp)
%     Heading.DateExp=Heading_old.DateExp;
% end
% if test_mod && uidheading
%      uid_child=children(t_device,uidheading);
%      t_device=delete(t_device,uid_child);
%     t_device=struct2xml(Heading,t_device,uidheading);
%     backupfile=xmlfullname;
%     testexist=2;
%     while testexist==2
%        backupfile=[backupfile '~'];
%        testexist=exist(backupfile,'file');
%     end
%     [success,message]=copyfile(xmlfullname,backupfile);%make backup
%     if isequal(success,1)
%         delete(xmlfullname)
%     else
%         return
%     end
%     save(t_device,xmlfullname)
% end

%------------------------------------------------------------------------
% --- Executes on button press in OK.
%------------------------------------------------------------------------
function OK_Callback(hObject, eventdata, handles)

if strcmp(get(handles.MirrorDir,'Visible'),'on')
    Campaign=get(handles.MirrorDir,'String');
else
    Campaign=get(handles.SourceDir,'String');
end
handles.output.Campaign=Campaign;
Experiment=get(handles.ListExperiments,'String');
IndicesExp=get(handles.ListExperiments,'Value');
if ~isequal(IndicesExp,1)% if first element ('*') selected all the experiments are selected
    Experiment=Experiment(IndicesExp);% use the selection of the list of experiments
end
Experiment=regexprep(Experiment,'^\+/','');% remove the +/ used to mark dir
Device=get(handles.ListDevices,'String');
Value=get(handles.ListDevices,'Value');
Device=Device(Value);
Device=regexprep(Device,'^\+/','');% remove the +/ used to mark dir
Device=regexprep(Device,'^~','');% remove the ~ used to mark symbolic link
handles.output.Experiment=Experiment;
handles.output.DataSeries=Device;
guidata(hObject, handles);% Update handles structure
uiresume(handles.browse_data);
drawnow

%------------------------------------------------------------------------
% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
web([helpfile '#dataview'])    
end

%------------------------------------------------------------------------
% --- Executes on button press in Cancel.
%------------------------------------------------------------------------
function Cancel_Callback(hObject, eventdata, handles)
    
handles.output = get(hObject,'String');
guidata(hObject, handles); % Update handles structure
% Use UIRESUME instead of delete because the OutputFcn needs
uiresume(handles.browse_data);

%------------------------------------------------------------------------
% --- Executes when user attempts to close browse_data.
%------------------------------------------------------------------------
function browse_data_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(handles.browse_data, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    handles.output = get(hObject,'String');
    guidata(hObject, handles); % Update handles structure
    uiresume(handles.browse_data);
else
    % The GUI is no longer waiting, just close it
    delete(handles.browse_data);
end

%------------------------------------------------------------------------
% --- Executes on key press over figure1 with no controls selected.
%------------------------------------------------------------------------
function browse_data_KeyPressFcn(hObject, eventdata, handles)
    
% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    % User said no by hitting escape
    handles.output = 'Cancel';
    
    % Update handles structure
    guidata(hObject, handles);
    
    uiresume(handles.browse_data);
end
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.browse_data);
end 


% --- Executes during object deletion, before destroying properties.
function browse_data_DeleteFcn(hObject, eventdata, handles)
