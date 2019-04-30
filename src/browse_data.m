%'browse_data': function for scanning directories in a campaign 
%------------------------------------------------------------------------
% function varargout = series(varargin)
% associated with the GUI browse_data.fig

%=======================================================================
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

% Last Modified by GUIDE v2.5 17-Apr-2019 18:15:24

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
function browse_data_OpeningFcn(hObject, eventdata, handles, InputDir,EnableMirror,MultiDevices)
%------------------------------------------------------------------------

%% Choose default command line output for browse_data
handles.output =hObject;% 'Cancel';

%% Update handles structure
guidata(hObject, handles);
set(hObject,'WindowButtonDownFcn',{'mouse_down'}) % allows mouse action with right button (zoom for uicontrol display)
set(hObject,'DeleteFcn',{@closefcn})%

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
if exist('MultiDevices','var') && strcmp(MultiDevices,'on')
    set(handles.DataSeries,'Max',2)
else
    set(handles.DataSeries,'Max',1)
end
if exist('EnableMirror','var') && strcmp(EnableMirror,'on')
    set(handles.CreateMirror,'Visible','on')
    set(handles.mirror_txt,'Visible','on')
else
    set(handles.CreateMirror,'Visible','off')
    set(handles.mirror_txt,'Visible','off')
end

%% initialize the GUI
if isempty(regexp(InputDir,'^http:'))&& ~(exist('InputDir','var') && ischar(InputDir) && exist(InputDir,'dir'))
    InputDir=pwd;% current dir is the starting data series by default
end
% [Experiment,DataSeries,Ext]=fileparts(DataSeries);
% DataSeries=[DataSeries Ext];
% [Campaign,Experiment,Ext]=fileparts(Experiment);
% Experiment=[Experiment Ext];
[ExpWithPath,DataSeries]=fileparts(InputDir);
[Campaign,Experiment,Ext]=fileparts(ExpWithPath);
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
errormsg=scan_campaign(handles,Campaign,Experiment,ExpWithPath);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    return
end
% set(handles.OK,'Visible','on')
% set(handles.Cancel,'Visible','on')

%set(handles.browse_data,'WindowStyle','modal')% Make the GUI
%modal%%%%%%%%%%%%%%%%%%%%%%%
set(hObject,'Visible','on')
drawnow
% UIWAIT makes GUI wait for user response (see UIRESUME)%%%%%%%%%%%%%%%%TO
% CHECK
%uiwait(handles.browse_data);



%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = browse_data_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1} = handles.output;
%%%%%%%%%%%%%%%%%%delete(handles.browse_data)

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
% List the experiments in a campaign, filling the menu ListExperiments
%------------------------------------------------------------------------
function errormsg=scan_campaign(handles,Campaign,Experiment,DataInput)
%------------------------------------------------------------------------
errormsg='';
if ~isempty(regexp(Campaign,'^http'))|| exist(Campaign,'dir')
    ListStruct=dir_uvmat(Campaign); %list files and dirs
    if numel(ListStruct)>1000% A campaign folder must contain maily a list of 'experiment' sub-folders
        errormsg=[Campaign ' contains too many items (>1000) to be a Project folder'];
        return
    end
    ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
    ListFiles=ListCells(1,:);%list of dir and file  names
    check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
    ListFiles(check_dir)=regexprep(ListFiles(check_dir),'^.+','+/$0');% put '+/' in front of dir name display
    cell_remove=regexp(ListFiles,'^(-|\.|\+/\.)');% detect strings beginning by '-' ,'.' or '+/.'(dir beginning by . )
    check_keep=cellfun('isempty', cell_remove);
    ListFiles=sort((ListFiles(check_keep))');
    index=find(strcmp(['+/' Experiment],ListFiles));
    if isempty(index), index=1; end
    set(handles.ListExperiments,'String',ListFiles)
    set(handles.ListExperiments,'Value',index)% initialise the menu selection with the folder defined by the input
    ListExperiments_Callback([],[], handles)
    DataSeries=get(handles.DataSeries,'String');
    index=find(strcmp(['+/' DataInput],DataSeries));
    if isempty(index)
        index=find(strcmp(['~/' DataInput],DataSeries));
    end
    if ~isempty(index)
          set(handles.DataSeries,'Value',index)
    end
else
    msgbox_uvmat('ERROR',['The input ' Campaign ' is not a directory'])
end

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
ListExperiments=ListExperiments(list_val);%choose selected experiments
list_dataseries(handles,ListExperiments,MirrorPath)

%------------------------------------------------------------------------
% --- List the DataSeries when a set of experiments is selected
%------------------------------------------------------------------------
 function list_dataseries(handles,ListExperiments,MirrorPath)

DataSeries={};
for iexp=1:numel(ListExperiments)
    if strcmp(ListExperiments{iexp}(1),'+')% if the item is a directory
        ListExperiments{iexp}(1)=[];%remove the first char '+' used to mark folders
        ListStruct=dir(fullfile(MirrorPath,ListExperiments{iexp})); %list files and dir in the source experiment directory
        ListCells=struct2cell(ListStruct);%transform dir struct to a cell arrray
        ListFiles=ListCells(1,:);%list of dir and file  names
        cell_remove=regexp(ListFiles,'^(-|\.|\+/\.)');% detect strings beginning by '-' ,'.' or '+/.'(dir beginning by . )
        cell_remove_tild=regexp(ListFiles,'~$');% detect tild the end of file nqme (do not list)
        check_keep=cellfun('isempty', cell_remove) & cellfun('isempty', cell_remove_tild);
        check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
        for ilist=1:numel(ListFiles)
            if check_keep(ilist)% loop on eligible DataSeries folders
                mirror=fullfile(MirrorPath,ListExperiments{iexp},ListFiles{ilist});%source folder
                if ~exist(mirror,'file') && ~exist(mirror,'dir')% if the name is a broken link
                    delete(mirror)% delete broken link
                else %update the list of dataSeries
                    [tild,msg]=fileattrib(mirror);
%                     msg.Name=regexprep(msg.Name,'^/.','/');%remove the dot in /. at the beginning of the name
%                     if ~strcmp(msg.Name,mirror)% if it is a link
%                         ListFiles{ilist}=['~' ListFiles{ilist}];%mark link by '@' in the list
%                     end
                    if check_dir(ilist)
                        ListFiles{ilist}=['+/' ListFiles{ilist}];%mark dir by '+' in the list
                    end
                    if isempty(find(strcmp(ListFiles{ilist},DataSeries), 1))% if the item is not already in DataSeries
                        DataSeries=[DataSeries;ListFiles{ilist}]; %append the item to the list
                    end                   
                end
            end
        end
    end
end
if get(handles.CheckDevices,'Value')
    set(handles.ListDevices,'Value',1)
set(handles.ListDevices,'String',sort(DataSeries))
CheckDevices_Callback([],[], handles)
else
set(handles.DataSeries,'Value',1)
set(handles.DataSeries,'String',sort(DataSeries))
end

%------------------------------------------------------------------------
% --- Executes when the mirror is created or updated
%------------------------------------------------------------------------
 function update_experiments(handles,ListExperiments,CampaignPath,MirrorPath)

DataSeries={};
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
                    if isempty(find(strcmp(ListFiles{ilist},DataSeries), 1))% if the item is not already in DataSeries
                        if check_dir(ilist)
                            ListFiles{ilist}=['+/' ListFiles{ilist}];%mark dir by '+' in the list
                        end
                        DataSeries=[DataSeries;ListFiles{ilist}]; %append the item to the list
                    end
                end
            end
        end
    end
end
set(handles.DataSeries,'String',sort(DataSeries))

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



%------------------------------------------------------------------------
% --- Executes on button press in OK.
%------------------------------------------------------------------------
function OK_Callback(hObject, eventdata, handles)

if strcmp(get(handles.MirrorDir,'Visible'),'on')
    Campaign=get(handles.MirrorDir,'String');
else
    Campaign=get(handles.SourceDir,'String');
end
handles.output=[];
handles.output.Campaign=Campaign;
Experiment=get(handles.ListExperiments,'String');
IndicesExp=get(handles.ListExperiments,'Value');
if ~isequal(IndicesExp,1)% if first element ('*') selected all the experiments are selected
    Experiment=Experiment(IndicesExp);% use the selection of the list of experiments
end
Experiment=regexprep(Experiment,'^\+/','');% remove the +/ used to mark dir
Device=get(handles.DataSeries,'String');
Value=get(handles.DataSeries,'Value');
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
% --- Executes when user attempts to close browse_data.
%------------------------------------------------------------------------
function closefcn(gcbo, eventdata)
% if isequal(get(handles.browse_data, 'waitstatus'), 'waiting')
%     % The GUI is still in UIWAIT, us UIRESUME
%     handles.output = get(hObject,'String');
%     guidata(hObject, handles); % Update handles structure
%     uiresume(handles.browse_data);
% else
%     % The GUI is no longer waiting, just close it
%     delete(handles.browse_data);
% end
hseries=findobj(allchild(0),'Tag','series');
if ~isempty(hseries)
    hreplicate=findobj(hseries,'Tag','Replicate');
    set(hreplicate,'Value',0)
end
hcalib=findobj(allchild(0),'Tag','geometry_calib');
if ~isempty(hcalib)
    hreplicate=findobj(hcalib,'Tag','Replicate');
    set(hreplicate,'Value',0)
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


% --- Executes on button press in Up.
function Up_Callback(hObject, eventdata, handles)
SourceDir=get(handles.SourceDir,'String');
browse_data(SourceDir)


% --- Executes on button press in Down.
function Down_Callback(hObject, eventdata, handles)
SourceDir=get(handles.SourceDir,'String');
ListExperiments=get(handles.ListExperiments,'String');
list_val=get(handles.ListExperiments,'Value');
SourceFolder=regexprep(ListExperiments{list_val(1)},'+','');
set(handles.SourceDir,'String',fullfile(SourceDir,SourceFolder))
DataSeries=get(handles.DataSeries,'String');
ValueDevice=get(handles.DataSeries,'Value');
set(handles.ListExperiments,'String',DataSeries)
set(handles.ListExperiments,'Value',ValueDevice)
ListExperiments_Callback(hObject, [], handles)


% --- Executes on selection change in DataSeries.
function DataSeries_Callback(hObject, eventdata, handles)


% --- Executes on button press in CheckDevices.
function CheckDevices_Callback(hObject, eventdata, handles)
if get(handles.CheckDevices,'Value')
    set(handles.ListDevices,'Visible','on')
    ListDevices=get(handles.DataSeries,'String');
    Index=get(handles.DataSeries,'Value');
    set(handles.ListDevices,'String',ListDevices)
    set(handles.ListDevices,'Value',Index)
    set(handles.DataSeries,'Value',1)
    if strcmp(get(handles.MirrorDir,'Visible'),'on')
    MirrorPath=get(handles.MirrorDir,'String');
    else
    MirrorPath=get(handles.SourceDir,'String');
    end
    IndexExperiment=get(handles.ListExperiments,'Value');
    ListExperiment=get(handles.ListExperiments,'String');
    Experiment=ListExperiment{get(handles.ListExperiments,'Value')};
    Experiment=regexprep(Experiment,'^\+/','');% remove the +/ used to mark dir
    Experiment=regexprep(Experiment,'^~','');% remove the ~ used to mark symbolic link
    Device=regexprep(ListDevices{Index},'^\+/','');% remove the +/ used to mark dir
    Device=regexprep(Device,'^~','');% remove the ~ used to mark symbolic link
    DataSeries=dir(fullfile(MirrorPath,Experiment,Device));
    DataSeriesCell=struct2cell(DataSeries);
    set(handles.DataSeries,'String',DataSeriesCell(1,:)')
else
    ListDevices=get(handles.ListDevices,'String');
    Index=get(handles.ListDevices,'Value');
    set(handles.ListDevices,'Visible','off')
    set(handles.DataSeries,'String',ListDevices)
    set(handles.DataSeries,'Value',Index)
end
