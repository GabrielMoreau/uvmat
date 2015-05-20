%'series': master function associated to the GUI series.m for analysis field series  
%------------------------------------------------------------------------
% function varargout = series(varargin)
% associated with the GUI series.fig
%
%INPUT
% param: structure with input parameters (link with the GUI uvmat)
%      .menu_coord_str: string for the TransformName (menu for coordinate transforms)
%      .menu_coord_val: value for TransformName (menu for coordinate transforms)
%      .FileName: input file name
%      .FileName_1: second input file name
%      .list_field: menu of input fields
%      .index_fields: chosen index
%      .civ1=0 or 1, .interp1,  ... : input civ field type
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright 2008-2014, LEGI / CNRS UJF G-INP, Joel.Sommeria@legi.grenoble-inp.fr
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

%------------------------------------------------------------------------
%------------------------------------------------------------------------
%  I - MAIN FUNCTION series 
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function varargout = series(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @series_OpeningFcn, ...
                   'gui_OutputFcn',  @series_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%--------------------------------------------------------------------------
% --- Executes just before series is made visible.
%--------------------------------------------------------------------------
function series_OpeningFcn(hObject, eventdata, handles,Param)

% Choose default command line output for series
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

%% initial settings
% position and  size of the GUI at opening
set(0,'Unit','points')
ScreenSize=get(0,'ScreenSize');%size of the current screen, in points (1/72 inch)
Width=900;% prefered width of the GUI in points (1/72 inch)
Height=624;% prefered height of the GUI in points (1/72 inch)
%adjust to screen size (reduced by a min margin)
RescaleFactor=min((ScreenSize(3)-80)/Width,(ScreenSize(4)-80)/Height);
if RescaleFactor>1
    RescaleFactor=min(RescaleFactor,1);
end
Width=Width*RescaleFactor;
Height=Height*RescaleFactor;
LeftX=80*RescaleFactor;%position of the left fig side, in pixels (put to the left side, with some margin)
LowY=round(ScreenSize(4)/2-Height/2); % put at the middle height on the screen
set(hObject,'Units','points')
set(hObject,'Position',[LeftX LowY Width Height])% position and size of the GUI at opening

% settings of table MinIndex_j
set(handles.MinIndex_i,'ColumnFormat',{'numeric'})
set(handles.MinIndex_i,'ColumnEditable',false)
set(handles.MinIndex_i,'ColumnName',{'i min'})
set(handles.MinIndex_i,'Data',[])% initiate Data to double (not cell)

% settings of table MinIndex_j
set(handles.MinIndex_j,'ColumnFormat',{'numeric'})
set(handles.MinIndex_j,'ColumnEditable',false)
set(handles.MinIndex_j,'ColumnName',{'j min'})
set(handles.MinIndex_j,'Data',[])% initiate Data to double (not cell)

% settings of table MaxIndex_i
set(handles.MaxIndex_i,'ColumnFormat',{'numeric'})
set(handles.MaxIndex_i,'ColumnEditable',false)
set(handles.MaxIndex_i,'ColumnName',{'i max'})
set(handles.MaxIndex_i,'Data',[])% initiate Data to double (not cell)

% settings of table MaxIndex_j
set(handles.MaxIndex_j,'ColumnFormat',{'numeric'})
set(handles.MaxIndex_j,'ColumnEditable',false)
set(handles.MaxIndex_j,'ColumnName',{'j max'})
set(handles.MaxIndex_j,'Data',[])% initiate Data to double (not cell)

% settings of table PairString
set(handles.PairString,'ColumnName',{'pairs'})
set(handles.PairString,'ColumnEditable',false)
set(handles.PairString,'ColumnFormat',{'char'})
set(handles.PairString,'Data',{''})

% settings of table MaskTable
set(handles.MaskTable,'ColumnName',{'mask name'})
set(handles.PairString,'ColumnEditable',false)
set(handles.PairString,'ColumnFormat',{'char'})
set(handles.PairString,'Data',{''})

series_ResizeFcn(hObject, eventdata, handles)%resize table according to series GUI size
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%allows mouse action with right button (zoom for uicontrol display)
set(hObject,'DeleteFcn',{@closefcn})%

% check default input data
if ~exist('Param','var')
    Param=[]; %default
end 

%% list of builtin functions in the mebu ActionName
ActionList={'check_data_files';'aver_stat';'time_series';'civ_series';'merge_proj'};% WARNING: fits with nb_builtin_ACTION=4 in ActionName_callback
NbBuiltinAction=numel(ActionList);
set(handles.Action,'UserData',NbBuiltinAction)
[path_series,name,ext]=fileparts(which('series'));% path to the GUI series
path_series_fct=fullfile(path_series,'series');%path of the functions in subdirectroy 'series'
[code, message] = system...
    ('LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | pyp "p.split('':'') |... [s for s in p if ''matlab'' not in s] | '':''.join(p)") python -c "import fluiddyn"'); 
if code==0
    ActionExtList={'.m';'.sh';'.py (in dev.)'};% default choice of extensions (Matlab fct .m or compiled version .sh
else
    ActionExtList={'.m';'.sh'};  % python options not installed
end
ActionPathList=cell(NbBuiltinAction,1);%initiate the cell matrix of Action fct paths
ActionPathList(:)={path_series_fct}; %set the default path to series fcts to all list members
RunModeList={'local';'background'};% default choice of extensions (Matlab fct .m or compiled version .sh)
[s,w]=system('oarstat');% look for cluster system 'oar'
if isequal(s,0)
    RunModeList=[RunModeList;{'cluster_oar'}];
    set(handles.MonitorCluster,'Visible','on'); % make visible button for access to Monika
end
[s,w]=system('qstat --version');% look for cluster system 'sge'
if isequal(s,0)
    if regexp(w,'^pbs')
        RunModeList=[RunModeList;{'cluster_pbs'}];
    else
        RunModeList=[RunModeList;{'cluster_sge'}];
    end
end
set(handles.RunMode,'String',RunModeList)

%% list of builtin transform functions in the menu TransformName
TransformList={'';'sub_field';'phys';'phys_polar'};% WARNING: must fit with the corresponding menu in uvmat and nb_builtin_transform=4 in  TransformName_callback
NbBuiltinTransform=numel(TransformList);
path_transform_fct=fullfile(path_series,'transform_field');
TransformPathList=cell(NbBuiltinTransform,1);%initiate the cell matrix of Action fct paths
TransformPathList(:)={path_transform_fct}; %set the default path to series fcts to all list members

%% get the user defined functions stored in the personal file uvmat_perso.mat 
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    h=load (profil_perso);
    %get the list of previous input files in the upper bar menu Open
    if isfield(h,'MenuFile')
        for ifile=1:min(length(h.MenuFile),5)
            set(handles.(['MenuFile_' num2str(ifile)]),'Label',h.MenuFile{ifile});
            set(handles.(['MenuFile_' num2str(ifile+5)]),'Label',h.MenuFile{ifile});
        end
    end
    %get the list of previous campaigns in the upper bar menu Open campaign
    if isfield(h,'MenuCampaign')
        for ifile=1:min(length(h.MenuCampaign),5)
            set(handles.(['MenuCampaign_' num2str(ifile)]),'Label',h.MenuCampaign{ifile});
        end
    end
    %get the menu of actions
%     if isfield(h,'ActionExtListUser') && iscell(h.ActionExtListUser)
%         ActionExtList=[ActionExtList; h.ActionExtListUser];
%     end 
    if isfield(h,'ActionListUser') && iscell(h.ActionListUser) && isfield(h,'ActionPathListUser') && iscell(h.ActionPathListUser)
        ActionList=[ActionList;h.ActionListUser];
        ActionPathList=[ActionPathList;h.ActionPathListUser(:,1)];
    end
    %get the menu of transform fct
    if isfield(h,'TransformListUser') && iscell(h.TransformListUser) && isfield(h,'TransformPathListUser') && iscell(h.TransformPathListUser)
        TransformList=[TransformList;h.TransformListUser];
        TransformPathList=[TransformPathList;h.TransformPathListUser];
    end
end

%% selection of the input Action fct
ActionCheckExist=true(size(ActionList));%initiate the check of the path to the listed action fct
for ilist=NbBuiltinAction+1:numel(ActionList)%check  the validity of the path of the user defined Action fct
    ActionCheckExist(ilist)=exist(fullfile(ActionPathList{ilist},[ActionList{ilist} '.m']),'file');
end
ActionPathList=ActionPathList(ActionCheckExist,:);% suppress the menu options which are not valid anymore
ActionList=ActionList(ActionCheckExist);
set(handles.ActionName,'String',[ActionList;{'more...'}])
set(handles.ActionName,'UserData',ActionPathList)
ActionIndex=[];
if isfield(Param,'ActionName')% copy the selected menu index transferred in Param from uvmat
    ActionIndex=find(strcmp(Param.ActionName,ActionList),1);
end
if isempty(ActionIndex)
    ActionIndex=1;
end
set(handles.ActionName,'Value',ActionIndex)
set(handles.ActionPath,'String',ActionPathList{ActionIndex})
set(handles.ActionExt,'Value',1)
set(handles.ActionExt,'String',ActionExtList)

%% selection of the input transform fct
TransformCheckExist=true(size(TransformList));
for ilist=NbBuiltinTransform+1:numel(TransformList)
    TransformCheckExist(ilist)=exist(fullfile(TransformPathList{ilist},[TransformList{ilist} '.m']),'file');
end
TransformPathList=TransformPathList(TransformCheckExist);
TransformList=TransformList(TransformCheckExist);
set(handles.TransformName,'String',[TransformList;{'more...'}])
set(handles.TransformName,'UserData',TransformPathList)
TransformIndex=[];
if isfield(Param,'TransformName')% copy the selected menu index transferred in Param from uvmat
    TransformIndex=find(strcmp(Param.TransformName,TransformList),1);
end
if isempty(TransformIndex)
    TransformIndex=1;
end
set(handles.TransformName,'Value',TransformIndex)
set(handles.TransformPath,'String',TransformPathList{TransformIndex})
   
%% fields input initialisation
if isfield(Param,'list_fields')&& isfield(Param,'index_fields') &&~isempty(Param.list_fields) &&~isempty(Param.index_fields)
    set(handles.FieldName,'String',Param.list_fields);% list menu fields
    set(handles.FieldName,'Value',Param.index_fields);% selected string index
end
if isfield(Param,'Coordinates')
    if isfield(Param.Coordinates,'Coord_x')
        set(handles.Coord_x,'String',Param.Coordinates.Coord_x)
    end
    if isfield(Param.Coordinates,'Coord_y')
        set(handles.Coord_y,'String',Param.Coordinates.Coord_y)
    end
    if isfield(Param.Coordinates,'Coord_z')
        set(handles.Coord_z,'String',Param.Coordinates.Coord_z)
    end
end
% if isfield(Param,'Coord_x_str') && ischar(Param.Coord_x_str)
%         set(handles.Coord_x,'String',Param.Coord_x_str);% list menu fields
% end
% if isfield(Param,'Coord_y_str')&& ischar(Param.Coord_y_str)
%         set(handles.Coord_y,'String',Param.Coord_y_str);% list menu fields
% end

%% introduce the input file name(s) if defined from input Param,
set(handles.series,'UserData',[])% initiate Userdata
if isfield(Param,'InputFile')
    
    %% fill the list of file series
    InputTable=[{Param.InputFile.RootPath},{Param.InputFile.SubDir},{Param.InputFile.RootFile},{Param.InputFile.NomType},{Param.InputFile.FileExt}];
    TimeTable=[{Param.InputFile.TimeName},{[]},{[]},{[]},{[]}];
    if isfield(Param.InputFile,'RootPath_1')
        InputTable=[InputTable;[{Param.InputFile.RootPath_1},{Param.InputFile.SubDir_1},{Param.InputFile.RootFile_1},{Param.InputFile.NomType_1},{Param.InputFile.FileExt_1}]];
        TimeTable=[TimeTable; [{Param.InputFile.TimeName_1},{[]},{[]},{[]},{[]}]];
    end
    set(handles.InputTable,'Data',InputTable)
    %% determine the selected reference field indices for pair display
    
    [tild,tild,tild,i1,i2,j1,j2]=fileparts_uvmat(Param.InputFile.FileIndex);
    if isempty(i1)
        i1=1;
    end
    if isempty(i2)
        i2=i1;
    end
    ref_i=floor((i1+i2)/2);% reference image number corresponding to the file
    % set(handles.num_ref_i,'String',num2str(ref_i));
    if isempty(j1)
        j1=1;
    end
    if isempty(j2)
        j2=j1;
    end
    ref_j=floor((j1+j2)/2);% reference image number corresponding to the file
    SeriesData.ref_i=ref_i;
    SeriesData.ref_j=ref_j;
    set(handles.series,'UserData',SeriesData)
    update_rootinfo(handles,Param.HiddenData.i1_series{1},Param.HiddenData.i2_series{1},Param.HiddenData.j1_series{1},Param.HiddenData.j2_series{1},...
        Param.HiddenData.FileInfo{1},Param.HiddenData.MovieObject{1},1)
    if isfield(Param,'FileName_1')
        %         display_file_name(handles,Param,2)
        update_rootinfo(handles,Param.HiddenData.i1_series{2},Param.HiddenData.i2_series{2},Param.HiddenData.j1_series{2},Param.HiddenData.j2_series{2},...
            Param.HiddenData.FileInfo{2},Param.HiddenData.MovieObject{2},2)
    end
    %% enable field and veltype menus, in accordance with the current action
    ActionName_Callback([],[], handles)
    
    %% set length of waitbar
    displ_time(handles)
    
else
    set(handles.REFRESH,'BackgroundColor',[1 0 1])% set REFRESH button to magenta color to indicate that input refresh is needed
end
if isfield(Param,'incr_i')
    set(handles.num_incr_i,'String',num2str(Param.incr_i))
else
    set(handles.num_incr_i,'String','1')
end
if isfield(Param,'incr_j')
    set(handles.num_incr_j,'String',num2str(Param.incr_j))
else
    set(handles.num_incr_j,'String','1')
end

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = series_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
varargout{1} = handles.output;

%------------------------------------------------------------------------
% --- executed when closing uvmat: delete or desactivate the associated figures if exist
function closefcn(gcbo,eventdata)
%------------------------------------------------------------------------

% delete set_object_series if detected
hh=findobj(allchild(0),'name','view_object_series');
if ~isempty(hh)
    delete(hh)
end
hh=findobj(allchild(0),'name','edit_object_series');
if ~isempty(hh)
    delete(hh)
end

%delete the bowser if detected
hh=findobj(allchild(0),'tag','browser');
if ~isempty(hh)
    delete(hh)
end


%------------------------------------------------------------------------
%------------------------------------------------------------------------
%  II - FUNCTIONS FOR INTRODUCING THE INPUT FILES
% automatically sets the global properties when the rootfile name is introduced
% then activate the view-field actionname if selected
% it is activated either by clicking on the RootPath window or by the 
% browser 
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% --- fct activated by the browser under 'Open'
%------------------------------------------------------------------------  
function MenuBrowse_Callback(hObject, eventdata, handles)
%% look for the previously opened file 'oldfile'
InputTable=get(handles.InputTable,'Data');
oldfile=InputTable{1,1};
if isempty(oldfile)
    % use a file name stored in prefdir
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        h=load (profil_perso);
        if isfield(h,'RootPath') && ischar(h.RootPath)
            oldfile=h.RootPath;
        end
    end
end
%% launch the browser
fileinput=uigetfile_uvmat('pick an input file in the series',oldfile);
hh=dir(fileinput);
if numel(hh)>1
    msgbox_uvmat('ERROR','invalid input, probably a broken link');
else
    if ~isempty(fileinput)
        display_file_name(handles,fileinput,'one')
    end
end

% --------------------------------------------------------------------
function MenuBrowseAppend_Callback(hObject, eventdata, handles)

%% look for the previously opened file 'oldfile'
InputTable=get(handles.InputTable,'Data');
RootPathCell=InputTable(:,1);
if isempty(RootPathCell{1})% no input file in the table
     MenuBrowse_Callback(hObject, eventdata, handles)%refresh the input table, not append
     return
end
SubDirCell=InputTable(:,2);
oldfile=fullfile(RootPathCell{1},SubDirCell{1});

%% use a file name stored in prefdir
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    h=load (profil_perso);
    if isfield(h,'RootPath') && ischar(h.RootPath)
        oldfile=h.RootPath;
    end
end

%% launch the browser
fileinput=uigetfile_uvmat('pick a file to append in the input table',oldfile);
hh=dir(fileinput);
if numel(hh)>1
    msgbox_uvmat('ERROR','invalid input, probably a broken link');
else
    if ~isempty(fileinput)
        display_file_name(handles,fileinput,'append')
    end
end

%------------------------------------------------------------------------
% --- fct activated by selecting a previous file under the menu Open
%------------------------------------------------------------------------
function MenuFile_Callback(hObject, eventdata, handles)

errormsg=display_file_name(handles,get(hObject,'Label'),'one');
if ~isempty(errormsg)
    set(hObject,'Label','')
    MenuFile=[{get(handles.MenuFile_1,'Label')};{get(handles.MenuFile_2,'Label')};...
        {get(handles.MenuFile_3,'Label')};{get(handles.MenuFile_4,'Label')};{get(handles.MenuFile_5,'Label')}];
    str_find=strcmp(get(hObject,'Label'),MenuFile);
    MenuFile(str_find)=[];% suppress the input file to the list
    for ifile=1:numel(MenuFile)
        set(handles.(['MenuFile_' num2str(ifile)]),'Label',MenuFile{ifile});
    end
end

%------------------------------------------------------------------------
% --- fct activated by selecting a previous file under the menu Open/append
%------------------------------------------------------------------------
function MenuFile_append_Callback(hObject, eventdata, handles)

InputTable=get(handles.InputTable,'Data');
if isempty(InputTable{1,1})% no input file in the table
    display_file_name(handles,get(hObject,'Label'),'one') %refresh the input table, not append
else
    display_file_name(handles,get(hObject,'Label'),'append')% append the selected file to the current list of InputTable
end

%------------------------------------------------------------------------
% --- fct activated by the browser under 'Open campaign/Browse...'
%------------------------------------------------------------------------ 
function MenuBrowseCampaign_Callback(hObject, eventdata, handles)

%% look for the previously opened file 'oldfile'
InputTable=get(handles.InputTable,'Data');
RootPathCell=InputTable(:,1);
SubDirCell=InputTable(:,2);
oldfile=fullfile(RootPathCell{1},SubDirCell{1});
if isempty(oldfile)
    % use a file name stored in prefdir
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        h=load (profil_perso);
        if isfield(h,'RootPath') && ischar(h.RootPath)
            oldfile=h.RootPath;
        end
    end
end
%% launch the browser
fileinput=uigetfile_uvmat('pick an input file in the series',oldfile);
hh=dir(fileinput);
if numel(hh)>1
    msgbox_uvmat('ERROR','invalid input, probably a broken link');
else
    if ~isempty(fileinput)
        display_file_name(handles,fileinput,'one')
    end
end
append='one';
set(handles.MenuOpenCampaign,'ForegroundColor',[1 1 0])
drawnow
browse_campaign(handles,append);

%------------------------------------------------------------------------
% --- fct activated by the browser under 'Open campaign/Browse...'
%------------------------------------------------------------------------ 
function MenuBrowseCampaignAppend_Callback(hObject, eventdata, handles)
append='append';
browse_campaign(handles,append);

%------------------------------------------------------------------------
function browse_campaign(handles,append);

%% look for the previously opened file 'oldfile'

% 
% 
% InputTable=get(handles.InputTable,'Data');
% RootPath=InputTable{1,1};
% CampaignPath=fileparts(fileparts(RootPath));
% DirFull=uigetfile_uvmat('define this path as the Campaign folder:',CampaignPath,'uigetdir');
% if ~ischar(DirFull)|| ~exist(DirFull,'dir')
%     return
% end
OutPut=browse_data(oldfile);% open the GUI browse_data to get select a campaign dir, experiment and device
if ~isfield(OutPut,'Campaign')
    return
end
DirName=fullfile(OutPut.Campaign,OutPut.Experiment{1},OutPut.DataSeries{1});
ListStruct=dir(DirName); %list files and the dir DataSeries
% select the first appropriate file in the dir
FileName='';
for ilist=1:numel(ListStruct)
    if ~isequal(ListStruct(ilist).isdir,1)%look for files, not dir
        FileName=ListStruct(ilist).name;
        FileInfo=get_file_info(fullfile(DirName,FileName));
        switch FileInfo.FileType
            case {'image','multimage','civx','civdata','netcdf'}
                break
        end
    end
end
if isempty(FileName)
    msgbox_uvmat('ERROR',['no appropriate input file in the DataSeries folder ' fullfile(DirName)])
    return
end

%% update the list of campaigns in the menubar
MenuCampaign=[{get(handles.MenuCampaign_1,'Label')};{get(handles.MenuCampaign_2,'Label')};...
    {get(handles.MenuCampaign_3,'Label')};{get(handles.MenuCampaign_4,'Label')};{get(handles.MenuCampaign_5,'Label')}];
check_dir=isempty(find(strcmp(DirName,MenuCampaign)));
if check_dir %insert the new campaign in the list if it is not found
    MenuCampaign(end)=[]; %suppress the last item
    MenuCampaign=[{DirName};MenuCampaign];%insert the new campaign
    for ilist=1:numel(MenuCampaign)
        set(handles.(['MenuCampaign_' num2str(ilist)]),'Label',MenuCampaign{ilist})
    end
    % save the list for future opening:
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        save (profil_perso,'MenuCampaign','-append'); %store the file names for future opening of uvmat
    else
        save (profil_perso,'MenuCampaign','-V6'); %store the file names for future opening of uvmat
    end
end

%% display the selected field and related information
if get(handles.CheckAppend,'Value')
    display_file_name(handles,fullfile(DirName,FileName),'append')
else
    display_file_name(handles,fullfile(DirName,FileName),'one')
end
set(handles.MenuOpenCampaign,'ForegroundColor',[0 0 0])

% --------------------------------------------------------------------
function MenuCampaign_Callback(hObject, eventdata, handles)
% -------------------------------------------------------------------- 
set(handles.MenuOpenCampaign,'ForegroundColor',[1 1 0])
OutPut=browse_data(get(hObject,'Label'));% open the GUI browse_data to get select a campaign dir, experiment and device
if ~isfield(OutPut,'Campaign')
    return
end
DirName=fullfile(OutPut.Campaign,OutPut.Experiment{1},OutPut.DataSeries{1});
hdir=dir(DirName); %list files and dirs
for ilist=1:numel(hdir)
    if ~isequal(hdir(ilist).isdir,1)%look for files, not dir
        FileName=hdir(ilist).name;
        FileInfo=get_file_info(fullfile(DirName,FileName));
        switch FileInfo.FileType
            case {'image','multimage','civx','civdata','netcdf'}
            break
        end
    end
end
if get(handles.CheckAppend,'Value')
    display_file_name(handles,fullfile(DirName,FileName),'append')
else
    display_file_name(handles,fullfile(DirName,FileName),'one')
end
set(handles.MenuOpenCampaign,'ForegroundColor',[0 0 0])


% --- Executes when selected cell(s) is changed in InputTable.
function InputTable_CellSelectionCallback(hObject, eventdata, handles)
iline=[];
if ~isempty(eventdata.Indices)
    iline=eventdata.Indices(1);
end
set(handles.InputLine,'String',num2str(iline));
% set(handles.InputTable,'UserData',iline);

%------------------------------------------------------------------------
% --- 'key_press_fcn:' function activated when a key is pressed on the keyboard
%------------------------------------------------------------------------
function InputTable_KeyPressFcn(hObject, eventdata, handles)
set(handles.REFRESH,'BackgroundColor',[1 0 1])% set REFRESH button to magenta color to indicate that input refresh is needed
set(handles.OutputSubDir,'BackgroundColor',[1 0 1])% set edit box OutputSubDir to magenta color to indicate that refresh may be needed
xx=double(get(handles.series,'CurrentCharacter')); %get the keyboard character
if ~isempty(xx)
    switch xx
        case 31 %downward arrow
            InputTable=get(handles.InputTable,'Data');
            iline=str2double(get(handles.InputLine,'String'));
            if isequal(iline,size(InputTable,1))% arrow downward
                InputTable=[InputTable;InputTable(iline,:)];% create a new line as a copy of the last one
                set(handles.InputTable,'Data',InputTable);
            end
        case 127  %key 'Suppress'
            ClearLine_Callback(hObject, eventdata, handles)
    end
end

%------------------------------------------------------------------------
% --- Executes on button press in REFRESH.
function REFRESH_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
InputTable=get(handles.InputTable,'Data');
set(handles.series,'Pointer','watch') % set the mouse pointer to 'watch'
set(handles.REFRESH,'BackgroundColor',[1 1 0])% set REFRESH  button to yellow color (indicate activation)
drawnow
empty_line=false(size(InputTable,1),1);
for iline=1:size(InputTable,1)
    empty_line(iline)= isempty(cell2mat(InputTable(iline,1:3)));
end
if ~isempty(find(empty_line));
    InputTable(empty_line,:)=[];%remove empty lines
    set(handles.InputTable,'Data',InputTable)
    ListTable={'MinIndex_i','MaxIndex_i','MinIndex_j','MaxIndex_j','PairString','TimeTable'};
    for ilist=1:numel(ListTable)
        Table=get(handles.(ListTable{ilist}),'Data');
        Table(empty_line,:)=[];%remove empty lines
        set(handles.(ListTable{ilist}),'Data',Table);
    end
    set(handles.series,'UserData',[])%refresh the stored info
end
nbview=size(InputTable,1);
for iview=1:nbview
    RootPath=fullfile(InputTable{iview,1},InputTable{iview,2});
    if ~exist(RootPath,'dir')
        i1_series=[];
        RootFile='';
    else %scan the input folder
        [RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,tild,FileInfo,MovieObject]=...
            find_file_series(fullfile(InputTable{iview,1},InputTable{iview,2}),[InputTable{iview,3} InputTable{iview,4} InputTable{iview,5}]);
    end
    % if no file is found, open a browser
    if isempty(RootFile)&& isempty(i1_series)
        fileinput=uigetfile_uvmat(['wrong input at line ' num2str(iview) ':pick a new input file'],RootPath);
        if isempty(fileinput)
            set(handles.REFRESH,'BackgroundColor',[1 0 0])% set REFRESH  back to red color
            return
        else
            display_file_name(handles,fileinput,iview)
        end
    else
       update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileInfo,MovieObject,iview)
    end
end

%% update MinIndex_i and MaxIndex_i if the input table content has been reduced in line nbre
MinIndex_i_table=get(handles.MinIndex_i,'Data');%retrieve the min indices in the table MinIndex
set(handles.MinIndex_i,'Data',MinIndex_i_table(1:nbview,:));
MinIndex_j_table=get(handles.MinIndex_j,'Data');%retrieve the min indices in the table MinIndex
set(handles.MinIndex_j,'Data',MinIndex_j_table(1:nbview,:));
MaxIndex_i_table=get(handles.MaxIndex_i,'Data');%retrieve the min indices in the table MinIndex
set(handles.MaxIndex_i,'Data',MaxIndex_i_table(1:nbview,:));
MaxIndex_j_table=get(handles.MaxIndex_j,'Data');%retrieve the min indices in the table MinIndex
set(handles.MaxIndex_j,'Data',MaxIndex_j_table(1:nbview,:));
PairString=get(handles.PairString,'Data');%retrieve the min indices in the table MinIndex
set(handles.PairString,'Data',PairString(1:nbview,:));
TimeTable=get(handles.TimeTable,'Data');%retrieve the min indices in the table MinIndex
set(handles.TimeTable,'Data',TimeTable(1:nbview,:));

%% enable field and veltype menus, in accordance with the current action
ActionName_Callback([],[], handles)

%% set length of waitbar
displ_time(handles)

set(handles.REFRESH,'BackgroundColor',[1 0 0])% set REFRESH  button to red color (indicate activation finished)
set(handles.series,'Pointer','arrow') % set the mouse pointer to 'watch'

%------------------------------------------------------------------------
% --- Function called when a new file is opened, either by series_OpeningFcn or by the browser
%------------------------------------------------------------------------
% INPUT:
% handles: handles of elements in the GUI
% Param: structure of input parameters, including  input file name and path
% iview: line index in the input table
%       or 'one': refresh the list
%         'append': add a new line to the input table
function errormsg=display_file_name(handles,Param,iview)
  
set(handles.REFRESH,'BackgroundColor',[1 1 0])% set REFRESH  button to yellow color (indicate activation)
drawnow
errormsg='';%default
if ischar(Param)
    fileinput=Param; 
else% input set when series is opened (called by the GUI uvmat)
    fileinput=Param.FileName;
end
    
%% get the input root name, indices, file extension and nomenclature NomType
if ~exist(fileinput,'file')
    errormsg=['input file ' fileinput  ' does not exist'];
    msgbox_uvmat('ERROR',errormsg)
    set(handles.REFRESH,'BackgroundColor',[1 0 1])% set REFRESH  button to magenta color (refresh still needed)
    return
end

%% detect root name, nomenclature and indices in the input file name:
[FilePath,FileName,FileExt]=fileparts(fileinput);
%%%%%%%%%%%%%%%%%%
%TODO: case of input by uvmat: do not check agai the input seies %%%%%%%
%%%%%%%%%%%%%%%%%%%
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
% the root name and indices may be corrected by including the first index i1 if a corresponding xml file exists
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileInfo,MovieObject,i1,i2,j1,j2]=find_file_series(FilePath,[FileName FileExt]);
FileType=FileInfo.FileType;
if isempty(RootFile)&&isempty(i1_series)
    errormsg='no input file in the series';
    msgbox_uvmat('ERROR',errormsg)
    set(handles.REFRESH,'BackgroundColor',[1 0 1])% set REFRESH  button to magenta color (end of activation)
    return
end
if strcmp(FileType,'txt')
    edit(fileinput)
    set(handles.REFRESH,'BackgroundColor',[1 0 1])% set REFRESH  button to  magenta color (end of activation)
    return
elseif strcmp(FileType,'xml')
    editxml(fileinput)
    set(handles.REFRESH,'BackgroundColor',[1 0 1])% set REFRESH  button to magenta  color (end of activation)
     return
elseif strcmp(FileType,'figure')
    open(fileinput)
    set(handles.REFRESH,'BackgroundColor',[1 0 1])% set REFRESH  button to magenta  color (end of activation)
     return
end

%% enable other menus and uicontrols
set(handles.MenuOpenCampaign,'Enable','on')
set(handles.MenuCampaign_1,'Enable','on')
set(handles.MenuCampaign_2,'Enable','on')
set(handles.MenuCampaign_3,'Enable','on')
set(handles.MenuCampaign_4,'Enable','on')
set(handles.MenuCampaign_5,'Enable','on')
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])% set RUN button to red 
set(handles.InputTable,'BackgroundColor',[1 1 0]) % set RootPath edit box  to yellow
drawnow


%% fill the list of file series
InputTable=get(handles.InputTable,'Data');
SeriesData=get(handles.series,'UserData');
if strcmp(iview,'append') % display the input data as a new line in the table
    iview=size(InputTable,1)+1;% the next line in InputTable becomes the current line
%     InputTable(iview,:)=[{RootPath},{SubDir},{RootFile},{NomType},{FileExt}];
elseif strcmp(iview,'one') % refresh the list of  input  file series
    iview=1; %the first line in InputTable becomes the current line
    InputTable={'','','','',''};
%     InputTable(iview,:)=[{RootPath},{SubDir},{RootFile},{NomType},{FileExt}];
    set(handles.TimeTable,'Data',[{''},{[]},{[]},{[]},{[]}])
    set(handles.MinIndex_i,'Data',[])
    set(handles.MaxIndex_i,'Data',[])
    set(handles.MinIndex_j,'Data',[])
    set(handles.MaxIndex_j,'Data',[])
    set(handles.PairString,'Data',{''})
    SeriesData.CheckPair=0;%reset the list of input lines with pairs
    SeriesData.i1_series={};
    SeriesData.i2_series={};
    SeriesData.j1_series={};
    SeriesData.j2_series={};
    SeriesData.FileType={};
    SeriesData.FileInfo={};
    SeriesData.Time={};
end
if isfield(SeriesData,'i1_series')
    SeriesData.i1_series(iview+1:end)=[];
    SeriesData.i2_series(iview+1:end)=[];
    SeriesData.j1_series(iview+1:end)=[];
    SeriesData.j2_series(iview+1:end)=[];
    SeriesData.FileType(iview+1:end)=[];
    SeriesData.FileInfo(iview+1:end)=[];
    SeriesData.Time(iview+1:end)=[];
end
InputTable(iview,:)=[{RootPath},{SubDir},{RootFile},{NomType},{FileExt}];
if iview >1
    set(handles.InputLine,'String',num2str(iview))
end
set(handles.InputTable,'Data',InputTable)

%% determine the selected reference field indices for pair display
if isempty(i1)
    i1=1;
end
if isempty(i2)
    i2=i1;
end
ref_i=floor((i1+i2)/2);% reference image number corresponding to the file
% set(handles.num_ref_i,'String',num2str(ref_i));
if isempty(j1)
    j1=1;
end
if isempty(j2)
    j2=j1;
end
ref_j=floor((j1+j2)/2);% reference image number corresponding to the file
SeriesData.ref_i=ref_i;
SeriesData.ref_j=ref_j;

%% update first and last indices if they do not exist
Param=read_GUI(handles.series);
first_j=[];
if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
last_j=[];
if isfield(Param.IndexRange,'last_j'); last_j=Param.IndexRange.last_j; end
PairString='';
if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
[i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
    Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
if ~exist(FirstFileName,'file')
    set(handles.num_first_i,'String',num2str(ref_i))
    set(handles.num_first_j,'String',num2str(ref_j))
end
[i1,i2,j1,j2] = get_file_index(Param.IndexRange.last_i,last_j,PairString);
LastFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
    Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
if ~exist(LastFileName,'file')
    set(handles.num_last_i,'String',num2str(ref_i))
    set(handles.num_last_j,'String',num2str(ref_j))
end

%% update the list of recent files in the menubar and save it for future opening
MenuFile=[{get(handles.MenuFile_1,'Label')};{get(handles.MenuFile_2,'Label')};...
    {get(handles.MenuFile_3,'Label')};{get(handles.MenuFile_4,'Label')};{get(handles.MenuFile_5,'Label')}];
str_find=strcmp(fileinput,MenuFile);
if isempty(find(str_find,1))
    MenuFile=[{fileinput};MenuFile];%insert the current file if not already in the list
end
for ifile=1:min(length(MenuFile),5)
    eval(['set(handles.MenuFile_' num2str(ifile) ',''Label'',MenuFile{ifile});'])
end
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    save (profil_perso,'MenuFile','-append'); %store the file names for future opening of uvmat
else
    save (profil_perso,'MenuFile','-V6'); %store the file names for future opening of uvmat
end
% save the opened file to initiate future opening
SeriesData.RefFile{iview}=fileinput;% reference opening file for line iview
SeriesData.Ref_i1=i1;
SeriesData.Ref_i2=i2;
SeriesData.Ref_j1=j1;
SeriesData.Ref_j2=j2;
set(handles.series,'UserData',SeriesData)

set(handles.InputTable,'BackgroundColor',[1 1 1])

%% initiate input file series and refresh the current field view:     
update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileInfo,MovieObject,iview);
%% enable field and veltype menus, in accordance with the current action
ActionName_Callback([],[], handles)

%% set length of waitbar
displ_time(handles)

set(handles.REFRESH,'BackgroundColor',[1 0 0])% set REFRESH  button to red color (end of activation)

%------------------------------------------------------------------------
% --- Update information about a new field series (indices to scan, timing,
%     calibration from an xml file
function update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileInfo,VideoObject,iview)
%------------------------------------------------------------------------
InputTable=get(handles.InputTable,'Data');

%% display the min and max indices for the whole file series
if size(i1_series,2)==2 && min(min(i1_series(:,1,:)))==0
    MinIndex_j=1;% index j set to 1 by default
    MaxIndex_j=1;
    MinIndex_i=find(i1_series(1,2,:), 1 )-1;% min ref index i detected in the series (corresponding to the first non-zero value of i1_series, except for zero index) 
    MaxIndex_i=find(i1_series(1,2,:),1,'last' )-1;%max ref index i detected in the series (corresponding to the last non-zero value of i1_series) 
else
    ref_i=squeeze(max(i1_series(1,:,:),[],2));% select ref_j index for each ref_i
    ref_j=squeeze(max(j1_series(1,:,:),[],3));% select ref_i index for each ref_j
     MinIndex_i=min(find(ref_i))-1;
     MaxIndex_i=max(find(ref_i))-1;
     MaxIndex_j=max(find(ref_j))-1;
     MinIndex_j=min(find(ref_j))-1;
    diff_j_max=diff(ref_j);
    diff_i_max=diff(ref_i);
    if ~isempty(diff_i_max) && isequal (diff_i_max,diff_i_max(1)*ones(size(diff_i_max)))
        set(handles.num_incr_i,'String',num2str(diff_i_max(1)))% detect an increment to dispaly by default
    end
    if ~isempty(diff_j_max) && isequal (diff_j_max,diff_j_max(1)*ones(size(diff_j_max)))
        set(handles.num_incr_j,'String',num2str(diff_j_max(1)))
    end
end
if isequal(MinIndex_i,-1)
    MinIndex_i=0;
end
if isequal(MinIndex_j,-1)
    MinIndex_j=0;
end
MinIndex_i_table=get(handles.MinIndex_i,'Data');%retrieve the min indices in the table MinIndex
MinIndex_j_table=get(handles.MinIndex_j,'Data');%retrieve the min indices in the table MinIndex
MaxIndex_i_table=get(handles.MaxIndex_i,'Data');%retrieve the min indices in the table MinIndex
MaxIndex_j_table=get(handles.MaxIndex_j,'Data');%retrieve the min indices in the table MinIndex
if ~isempty(MinIndex_i)&&~isempty(MaxIndex_i)
    MinIndex_i_table(iview,1)=MinIndex_i;
    MaxIndex_i_table(iview,1)=MaxIndex_i;
end
if ~isempty(MinIndex_j)&&~isempty(MaxIndex_j)
    MinIndex_j_table(iview,1)=MinIndex_j;
    MaxIndex_j_table(iview,1)=MaxIndex_j;
end
set(handles.MinIndex_i,'Data',MinIndex_i_table)%display the min indices in the table MinIndex
set(handles.MinIndex_j,'Data',MinIndex_j_table)%display the max indices in the table MaxIndex
set(handles.MaxIndex_i,'Data',MaxIndex_i_table)%display the min indices in the table MinIndex
set(handles.MaxIndex_j,'Data',MaxIndex_j_table)%display the max indices in the table MaxIndex
SeriesData=get(handles.series,'UserData');

%% adjust the first and last indices for the selected series, only if requested by the bounds
% i index, compare input to min index i
first_i=str2num(get(handles.num_first_i,'String'));%retrieve previous first i
% ref_i=str2num(get(handles.num_ref_i,'String'));%index i given by the input field
ref_i=1;
if isfield(SeriesData,'ref_i')
ref_i=SeriesData.ref_i;
end
if isempty(first_i)
    first_i=ref_i;% first_i updated by the input value
elseif first_i < MinIndex_i
    first_i=MinIndex_i; % first_i set to the min i index (restricted by oter input lines)
elseif first_i >MaxIndex_i
    first_i=MaxIndex_i;% first_i set to the max i index (restricted by oter input lines)
end
% j index,  compare input to min index j
first_j=str2num(get(handles.num_first_j,'String'));
ref_j=1;
if isfield(SeriesData,'ref_j')
ref_j=SeriesData.ref_j;
end
if isempty(first_j)
    first_j=ref_j;% first_j updated by the input value
elseif first_j<MinIndex_j
    first_j=MinIndex_j; % first_j set to the min j index (restricted by oter input lines)
elseif first_j >MaxIndex_j
    first_j=MaxIndex_j; % first_j set to the max j index (restricted by oter input lines)
end
% i index, compare input to max index i
last_i=str2num(get(handles.num_last_i,'String'));
if isempty(last_i)
    last_i=ref_i;
elseif last_i > MaxIndex_i
    last_i=MaxIndex_i;
elseif last_i<first_i
    last_i=first_i;
end
% j index, compare input to max index j
last_j=str2num(get(handles.num_last_j,'String'));
if isempty(last_j)
    last_j=ref_j;
elseif last_j>MaxIndex_j
    last_j=MaxIndex_j;
elseif last_j<first_j
    last_j=first_j;
end
set(handles.num_first_i,'String',num2str(first_i)); 
set(handles.num_first_j,'String',num2str(first_j));
set(handles.num_last_i,'String',num2str(last_i)); 
set(handles.num_last_j,'String',num2str(last_j));

%% number of slices set by default
NbSlice=1;%default
% read  value set by the first series for the append mode (iwiew >1)
if iview>1 && strcmp(get(handles.num_NbSlice,'Visible'),'on')
    NbSlice=str2num(get(handles.num_NbSlice,'String'));
end

%% default time settings
TimeUnit='';
% read  value set by the first series for the append mode (iwiew >1)
if iview>1 
    TimeUnit=get(handles.TimeUnit,'String');
end
TimeName='';
Time=[];%default
TimeMin=[];
TimeFirst=[];
TimeLast=[];
TimeMax=[];

%%  read image documentation file if found
XmlData=[];
check_calib=0;
XmlFileName=find_imadoc(InputTable{iview,1},InputTable{iview,2},InputTable{iview,3},InputTable{iview,5});
if ~isempty(XmlFileName)
    [XmlData,errormsg]=imadoc2struct(XmlFileName);
    if ~isempty(errormsg)
         msgbox_uvmat('WARNING',['error in reading ' XmlFileName ': ' errormsg]);
    end
    % read time if available
    if isfield(XmlData,'Time')
         Time=XmlData.Time;
        TimeName='xml';
    end
    if isfield(XmlData,'Camera')
        if isfield(XmlData.Camera,'NbSlice')&& ~isempty(XmlData.Camera.NbSlice)
            if iview>1 && ~isempty(NbSlice) && ~strcmp(NbSlice,XmlData.Camera.NbSlice)
                msgbox_uvmat('WARNING','inconsistent number of slices with the first field series');
            end
            NbSlice=XmlData.Camera.NbSlice;% Nbre of slices from camera
        end
        if isfield(XmlData.Camera,'TimeUnit')&& ~isempty(XmlData.Camera.TimeUnit)
            if iview>1 && ~isempty(TimeUnit) && ~strcmp(TimeUnit,XmlData.Camera.TimeUnit)
                msgbox_uvmat('WARNING','inconsistent time unit with the first field series');
            end
            TimeUnit=XmlData.Camera.TimeUnit;
        end
    end
    % number of slices
    if isfield(XmlData,'GeometryCalib')
        check_calib=1;
        if isfield(XmlData.GeometryCalib,'SliceCoord')
            siz=size(XmlData.GeometryCalib.SliceCoord);
            if siz(1)>1
                if iview>1 && ~isempty(NbSlice) && ~strcmp(NbSlice,siz(1))
                    msgbox_uvmat('WARNING','inconsistent number of Z indices with the first field series');
                end
                NbSlice=siz(1);
            end
        end
    end
    set(handles.num_NbSlice,'String',num2str(NbSlice))
end

%% read timing  from the current file (prioritary)
if ~isempty(VideoObject)% case of movies
    imainfo=get(VideoObject);
    if isempty(j1_series); %frame index along i
        Time=zeros(imainfo.NumberOfFrames+1,2);
        Time(:,2)=(0:1/imainfo.FrameRate:(imainfo.NumberOfFrames)/imainfo.FrameRate)';
    else
        Time=[0;ones(size(i1_series,3)-1,1)]*(0:1/imainfo.FrameRate:(imainfo.NumberOfFrames)/imainfo.FrameRate);
    end
    TimeName='video';
end 


%% determine the min and max times: case of Netcdf files will be treated later in FieldName_Callback
if ~isempty(TimeName)
    TimeMin=Time(MinIndex_i+1,MinIndex_j+1);
    if size(Time)>=[first_i+1 first_j+1]
        TimeFirst=Time(first_i+1,first_j+1);
    end
    if size(Time)>=[last_i+1 last_j+1]
        TimeLast=Time(last_i+1,last_j+1);
    end
    if size(Time)>=[MaxIndex_i+1 MaxIndex_j+1];
        TimeMax=Time(MaxIndex_i+1,MaxIndex_j+1);
    end
end

%% update the time table
TimeTable=get(handles.TimeTable,'Data');
TimeTable{iview,1}=TimeName;
TimeTable{iview,2}=TimeMin;
TimeTable{iview,3}=TimeFirst;
TimeTable{iview,4}=TimeLast;
TimeTable{iview,5}=TimeMax;
set(handles.TimeTable,'Data',TimeTable)

%% update the series info in 'UserData'
SeriesData.i1_series{iview}=i1_series;
SeriesData.i2_series{iview}=i2_series;
SeriesData.j1_series{iview}=j1_series;
SeriesData.j2_series{iview}=j2_series;
SeriesData.FileType{iview}=FileInfo.FileType;
SeriesData.FileInfo{iview}=FileInfo;
SeriesData.Time{iview}=Time;
% if ~isempty(TimeName)
%     SeriesData.TimeSource=TimeSource;
% end
if check_calib
    SeriesData.GeometryCalib{iview}=XmlData.GeometryCalib;
end
set(handles.series,'UserData',SeriesData)

%% update pair menus
hset_pair=findobj(allchild(0),'Tag','set_pairs');
if ~isempty(hset_pair), delete(hset_pair); end % delete the GUI set_pair if opened
CheckPair= ~isempty(i2_series)||~isempty(j2_series); % check whether index pairs need to be defined
PairString=get(handles.PairString,'Data');
if CheckPair% if pairs need to be display for line iview
    [ModeMenu,ModeValue]=update_mode(i1_series,i2_series,j2_series);
    Menu=update_listpair(i1_series,i2_series,j1_series,j2_series,ModeMenu{ModeValue},Time,TimeUnit,ref_i,ref_j,TimeName,InputTable(iview,:),FileInfo);
    PairString{iview,1}=Menu{1};
else
    PairString{iview,1}='';%no pair for #iview
end
set(handles.PairString,'Data',PairString)
if isempty(find(cellfun('isempty',get(handles.PairString,'Data'))==0, 1))% if all lines of pairs are empty
    set(handles.PairString,'Visible','off')
    set(handles.SetPairs,'Visible','off')
else
    set(handles.PairString,'Visible','on')
    set(handles.SetPairs,'Visible','on')
end


%% display the set of existing files as an image
set(handles.FileStatus,'Units','pixels')
Position=get(handles.FileStatus,'Position');
set(handles.FileStatus,'Units','normalized')
%xI=0.5:Position(3)-0.5;
nbview=numel(SeriesData.i1_series);
j_max=cell(1,nbview);
MaxIndex_i=ones(1,nbview);%default
MinIndex_i=ones(1,nbview);%default
for iline=1:nbview
    pair_max=squeeze(max(SeriesData.i1_series{iline},[],1)); %max on pair index
    j_max{iline}=max(pair_max,[],1);%max on j index
    if ~isempty(j_max{iline})
    MaxIndex_i(iline)=max(find(j_max{iline}))-1;% max ref index i
    MinIndex_i(iline)=min(find(j_max{iline}))-1;% min ref index i
    end
end
MinIndex_i=min(MinIndex_i);
MaxIndex_i=max(MaxIndex_i);
range_index=MaxIndex_i-MinIndex_i+1;
range_y=max(1,floor(Position(4)/nbview));
npx=floor(Position(3));
file_indices=MinIndex_i+floor(((0.5:npx-0.5)/npx)*range_index)+1;
CData=zeros(nbview*range_y,npx);% initiate the image representing the existing files
for iline=1:nbview
    ind_y=1+(iline-1)*range_y:iline*range_y;
    LineData=zeros(size(file_indices));
    file_select=file_indices(file_indices<=numel(j_max{iline}));
    ind_select=find(file_indices<=numel(j_max{iline}));
    LineData(ind_select)=j_max{iline}(file_select)~=0;
    CData(ind_y,:)=ones(size(ind_y'))*LineData;
end
CData=cat(3,zeros(size(CData)),CData,zeros(size(CData)));%make color images r=0,g,b=0
set(handles.FileStatus,'CData',CData);

%-----------------------------------------------------------guide -------------
%------------------------------------------------------------------------
%  III - FUNCTIONS ASSOCIATED TO THE FRAME IndexRange
%------------------------------------------------------------------------


% ---- determine the menu to put in mode and advice a default choice
%------------------------------------------------------------------------
function [ModeMenu,ModeValue]=update_mode(i1_series,i2_series,j2_series)
%------------------------------------------------------------------------    
ModeMenu={''};
if isempty(j2_series)% no j pair
    ModeValue=1;
    if ~isempty(i2_series)
        ModeMenu={'series(Di)'}; % pair menu with only option Di
    end
else %existence of j pairs
    pair_max=squeeze(max(i1_series,[],1)); %max on pair index
    j_max=max(pair_max,[],1);
    MaxIndex_i=find(j_max, 1, 'last' )-1;% max ref index i
    MinIndex_i=find(j_max, 1 )-1;% min ref index i
    i_max=max(pair_max,[],2);
    MaxIndex_j=find(i_max, 1, 'last' )-1;% max ref index i
    MinIndex_j=find(i_max, 1 )-1;% min ref index i
    if MaxIndex_j==MinIndex_j
        ModeValue=1;
        ModeMenu={'bursts'};
    elseif MaxIndex_i==MinIndex_i
        ModeValue=1;
        ModeMenu={'series(Dj)'};
    else
        ModeMenu={'bursts';'series(Dj)'};
        if (MaxIndex_j-MinIndex_j)>10
            ModeValue=2;%set mode to series(Dj) if more than 10 j values
        else
            ModeValue=1;
        end
    end
end


%------------------------------------------------------------------------
function displ_pair=update_listpair(i1_series,i2_series,j1_series,j2_series,mode,time,TimeUnit,ref_i,ref_j,TimeName,InputTable,FileInfo)
%------------------------------------------------------------------------
displ_pair={};
if isempty(TimeUnit)
    dtunit='e-03';
else
    dtunit=['m' TimeUnit];
end
switch mode
    case 'series(Di)'
        diff_i=i2_series-i1_series;
        min_diff=min(diff_i(diff_i>0));
        max_diff=max(diff_i(diff_i>0));
        for ipair=min_diff:max_diff
            if numel(diff_i(diff_i==ipair))>0
                pair_string=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ];
                if ~isempty(time)
                    if ref_i<=floor(ipair/2)
                        ref_i=floor(ipair/2)+1;% shift ref_i to get the first pair
                    end
                    Dt=time(ref_i+ceil(ipair/2),ref_j)-time(ref_i-floor(ipair/2),ref_j);
                    pair_string=[pair_string ', Dt=' num2str(Dt) ' ' dtunit];
                end
                displ_pair=[displ_pair;{pair_string}];
            end
        end
        if ~isempty(displ_pair)
            displ_pair=[displ_pair;{'Di=*|*'}];
        end
    case 'series(Dj)'
        if isempty(j2_series)
            msgbox_uvmat('ERROR','no j1-j2 pair available')
            return
        end
        diff_j=j2_series-j1_series;
        min_diff=min(diff_j(diff_j>0));
        max_diff=max(diff_j(diff_j>0));
        for ipair=min_diff:max_diff
            if numel(diff_j(diff_j==ipair))>0
                pair_string=['Dj= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ];
                if ~isempty(time)
                    if ref_j<=floor(ipair/2)
                        ref_j=floor(ipair/2)+1;% shift ref_i to get the first pair
                    end
                    Dt=time(ref_i,ref_j+ceil(ipair/2))-time(ref_i,ref_j-floor(ipair/2));
                    pair_string=[pair_string ', Dt=' num2str(Dt) ' ' dtunit];
                end
                displ_pair=[displ_pair;{pair_string}];
            end
        end
        if ~isempty(displ_pair)
            displ_pair=[displ_pair;{'Dj=*|*'}];
        end
    case 'bursts'
        if isempty(j2_series)
            msgbox_uvmat('ERROR','no j1-j2 pair available')
            return
        end
        %diff_j=j2_series-j1_series;
        min_j1=min(j1_series(j1_series>0));
        max_j1=max(j1_series(j1_series>0));
        min_j2=min(j2_series(j2_series>0));
        max_j2=max(j2_series(j2_series>0));
        for pair1=min_j1:min(max_j1,min_j1+20)
            for pair2=min_j2:min(max_j2,min_j2+20)
                if numel(j1_series(j1_series==pair1))>0 && numel(j2_series(j2_series==pair2))>0
                    pair_string=['j= ' num2str(pair1) '-' num2str(pair2)];
                    [TimeValue,DtValue]=get_time(ref_i,[],pair_string,InputTable,FileInfo,TimeName,'Dt');
                    %Dt=time(ref_i,pair2+1)-time(ref_i,pair1+1);
                    pair_string=[pair_string ', Dt=' num2str(DtValue) ' ' dtunit];
                    displ_pair=[displ_pair;{pair_string}];
                end
            end
        end
        if ~isempty(displ_pair)
            displ_pair=[displ_pair;{'j=*-*'}];
        end
end

%------------------------------------------------------------------------
function num_first_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
num_last_i_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function num_last_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
SeriesData=get(handles.series,'UserData');
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
displ_time(handles);

%------------------------------------------------------------------------
function num_first_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
 num_last_j_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function num_last_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% first_j=str2num(get(handles.num_first_j,'String'));
% last_j=str2num(get(handles.num_last_j,'String'));
% ref_j=ceil((first_j+last_j)/2);
% set(handles.num_ref_j,'String', num2str(ref_j))
% num_ref_j_Callback(hObject, eventdata, handles)
SeriesData=get(handles.series,'UserData');
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
displ_time(handles);

%------------------------------------------------------------------------
% ---- find the times corresponding to the first and last indices of a series
function displ_time(handles)
%------------------------------------------------------------------------
SeriesData=get(handles.series,'UserData');%
if ~isfield(SeriesData,'Time')
    return
end
PairString=get(handles.PairString,'Data');
ref_i_1=str2num(get(handles.num_first_i,'String'));%first reference index
ref_i_2=str2num(get(handles.num_last_i,'String'));%last reference index
ref_j_1=[];ref_j_2=[];
if strcmp(get(handles.num_first_j,'Visible'),'on')
ref_j_1=str2num(get(handles.num_first_j,'String'));
ref_j_2=str2num(get(handles.num_last_j,'String'));
end
[i1_1,i2_1,j1_1,j2_1] = get_file_index(ref_i_1,ref_j_1,PairString);
[i1_2,i2_2,j1_2,j2_2] = get_file_index(ref_i_2,ref_j_2,PairString);
TimeTable=get(handles.TimeTable,'Data');
%%%%%%
%TODO: read time in netcdf file, see ActionName_Callback
%%%%%%%
%Pairs=get(handles.PairString,'Data');
for iview=1:size(TimeTable,1)
    if size(SeriesData.Time,1)<iview
        break
    end
    TimeTable{iview,3}=[];
    TimeTable{iview,4}=[];
    if size(SeriesData.Time{iview},1)>=i2_2+1 && (isempty(ref_j_1)||size(SeriesData.Time{iview},2)>=j2_2+1)
        if isempty(ref_j_1)
            time_first=(SeriesData.Time{iview}(i1_1+1,2)+SeriesData.Time{iview}(i2_1+1,2))/2;
            time_last=(SeriesData.Time{iview}(i1_2+1,2)+SeriesData.Time{iview}(i2_2+1,2))/2;
        else
            time_first=(SeriesData.Time{iview}(i1_1+1,j1_1+1)+SeriesData.Time{iview}(i2_1+1,j2_1+1))/2;
            time_last=(SeriesData.Time{iview}(i1_2+1,j1_2+1)+SeriesData.Time{iview}(i2_2+1,j2_1+1))/2;
        end
        TimeTable{iview,3}=time_first; %TODO: take into account pairs
        TimeTable{iview,4}=time_last; %TODO: take into account pairs
    end
end
set(handles.TimeTable,'Data',TimeTable)

%% set the waitbar position with respect to the min and max in the series
MinIndex_i=min(get(handles.MinIndex_i,'Data'));
MaxIndex_i=max(get(handles.MaxIndex_i,'Data'));
pos_first=(ref_i_1-MinIndex_i)/(MaxIndex_i-MinIndex_i+1);
pos_last=(ref_i_2-MinIndex_i+1)/(MaxIndex_i-MinIndex_i+1);
if isempty(pos_first), pos_first=0; end
if isempty(pos_last), pos_last=1; end
Position=get(handles.Waitbar,'Position');% position of the waitbar:= [ x,y, width, height]
Position_status=get(handles.FileStatus,'Position');
Position(1)=Position_status(1)+Position_status(3)*pos_first;
Position(3)=max(Position_status(3)*(pos_last-pos_first),0.001);% width must remain positive
set(handles.Waitbar,'Position',Position)
update_waitbar(handles.Waitbar,0)

%------------------------------------------------------------------------
% --- Executes when selected cell(s) is changed in PairString.
function PairString_CellSelectionCallback(hObject, eventdata, handles)
%------------------------------------------------------------------------    
if numel(eventdata.Indices)>=1
    PairString=get(hObject,'Data');
    if ~isempty(PairString{eventdata.Indices(1)})
        SetPairs_Callback(hObject, eventdata.Indices(1), handles)
    end
end

%-------------------------------------
function enable_i(handles,state)
set(handles.i_txt,'Visible',state)
set(handles.num_first_i,'Visible',state)
set(handles.num_last_i,'Visible',state)
set(handles.num_incr_i,'Visible',state)

%-----------------------------------
function enable_j(handles,state)
set(handles.j_txt,'Visible',state)
set(handles.num_first_j,'Visible',state)
set(handles.num_last_j,'Visible',state)
set(handles.num_incr_j,'Visible',state)
set(handles.MinIndex_j,'Visible',state)
set(handles.MaxIndex_j,'Visible',state)


%%%%%%%%%%%%%%%%%%%%
%%  MAIN ActionName FUNCTIONS
%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in RUN.
%------------------------------------------------------------------------
function RUN_Callback(hObject, eventdata, handles)

%% settings of the button RUN
set(handles.RUN,'BusyAction','queue');% activation of STOP button will set BusyAction to 'cancel'
set(handles.RUN, 'Enable','Off')% avoid further RUN action until the current one is finished
set(handles.RUN,'BackgroundColor',[1 1 0])%show activation of RUN by yellow color
drawnow
set(handles.status,'Value',0)% desable status display if relevant
status_Callback([], eventdata, handles)

%% launch action
errormsg=launch_action(handles);
if ~isempty(errormsg)
     msgbox_uvmat('ERROR',errormsg)
end

%% reset the GUI series
update_waitbar(handles.Waitbar,1); % put the waitbar to end position to indicate launching is finished
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])
set(handles.RUN, 'Value',0)

%------------------------------------------------------------------------
% --- called by RUN_Callback
%------------------------------------------------------------------------
function errormsg=launch_action(handles)
errormsg='';%default

%% read the data on the GUI series
Param=read_GUI_series(handles);%displayed parameters
SeriesData=get(handles.series,'UserData');%hidden parameters
if isfield(SeriesData,'TransformInput')
    Param.TransformInput=SeriesData.TransformInput;
end
if ~isfield(SeriesData,'i1_series')
    errormsg='The input field series needs to be refreshed: press REFRESH';
    return
end
if isfield(Param,'InputFields')&& isequal(Param.InputFields.FieldName,'get_field...')
    errormsg='input field name(s) not defined, select get_field...';
    return
end

%% select the Action mode, 'local', 'background' or 'cluster' (if available)
RunMode='local';%default (needed for first opening of the GUI series)
if isfield(Param.Action,'RunMode')
    RunMode=Param.Action.RunMode;
    Param.Action=rmfield(Param.Action,'RunMode');%remove from the recorded xml file to avoid interference during ImportConfig
end
ActionExt='.m';%default
if isfield(Param.Action,'ActionExt')
    ActionExt=Param.Action.ActionExt;% '.m', '.sh' (compiled)  or '.py' (Python)
    Param.Action=rmfield(Param.Action,'ActionExt');%remove from the recorded xml file to avoid interference during ImportConfig
end
ActionName=Param.Action.ActionName;
ActionPath=Param.Action.ActionPath;
path_series=fileparts(which('series'));

%% create the Action fct handle if RunMode option = 'local'
if strcmp(RunMode,'local')
    if ~isequal(ActionPath,path_series)
        eval(['spath=which(''' ActionName ''');']) %spath = current path of the selected function ACTION
        if ~exist(ActionPath,'dir')
            errormsg=['The prescribed function path ' ActionPath ' does not exist'];
            return
        end
        if ~isequal(spath,ActionPath)
            addpath(ActionPath)% add the prescribed path if not the current one
        end
    end
    eval(['h_fun=@' ActionName ';'])%create a function handle for ACTION
    if ~isequal(ActionPath,path_series)
        rmpath(ActionPath)% add the prescribed path if not the current one
    end
end

%% Get RunTime code from the file PARAM.xml (needed to run compiled functions)
errormsg='';%default error message
xmlfile=fullfile(path_series,'PARAM.xml');
test_batch=0;%default: ,no batch mode available
if ~exist(xmlfile,'file')
    [success,message]=copyfile(fullfile(path_series,'PARAM.xml.default'),xmlfile);
end
% RunTime='';
if strcmp(ActionExt,'.sh')
    if exist(xmlfile,'file')
        s=xml2struct(xmlfile);
        if strcmp(RunMode,'cluster_oar') && isfield(s,'BatchParam')
%             if isfield(s.BatchParam,'RunTime')
%                 RunTime=s.BatchParam.RunTime;
%             end
            if isfield(s.BatchParam,'NbCore')
                NbCore=s.BatchParam.NbCore;
            end
        elseif (strcmp(RunMode,'background')||strcmp(RunMode,'local')) && isfield(s,'RunParam')
%             if isfield(s.RunParam,'RunTime')
%                 RunTime=s.RunParam.RunTime;
%             end
            if isfield(s.RunParam,'NbCore')
                NbCore=s.RunParam.NbCore;
            end
        end
    end
%     if isempty(RunTime) && strcmp(RunMode,'cluster_oar')
%        errormsg='RunTime name not found in PARAM.xml, compiled version .sh cannot run on cluster';
%         return
%     end
end

%% If a compiled version has been selected (ext .sh) check weather it needs to be recompiled
if strcmp(ActionExt,'.sh')
    TransformPath='';
    if ~isempty(get(handles.ActionExt,'UserData'))
        TransformPath=get(handles.ActionExt,'UserData');
    end
    set(handles.series,'Pointer','watch') % set the mouse pointer to 'watch'
    set(handles.ActionExt,'BackgroundColor',[1 1 0])
    hver=ver('MATLAB');
    MCRROOT=['MCRROOT' regexprep(hver.Version,'\.','')];%suppress the dot in version number
    RunTime = getenv(MCRROOT);
    ActionNameVersion=[ActionName '_' MCRROOT];
    ActionFullName=fullfile(get(handles.ActionPath,'String'),[ActionNameVersion '.sh']);
    if ~exist(ActionFullName,'file')
        answer=msgbox_uvmat('INPUT_Y-N','compiled version has not been created: compile now?');
        if strcmp(answer,'Yes')
            set(handles.ActionExt,'BackgroundColor',[1 1 0])
            path_uvmat=fileparts(which('series'));
            currentdir=pwd;
            cd(get(handles.ActionPath,'String'))% go to the directory of Action
            addpath(path_uvmat)% add the path to uvmat to run the fct 'compile'
            compile(ActionName,TransformPath)
            cd(currentdir)
        else
            errormsg='Action launch interrupted';
            return
        end       
    else
        sh_file_info=dir(fullfile(get(handles.ActionPath,'String'),[ActionNameVersion '.sh']));
        m_file_info=dir(fullfile(get(handles.ActionPath,'String'),[ActionName '.m']));
        if isfield(m_file_info,'datenum') && m_file_info.datenum>sh_file_info.datenum
            set(handles.ActionExt,'BackgroundColor',[1 1 0])
            drawnow
            answer=msgbox_uvmat('INPUT_Y-N',[ActionNameVersion '.sh needs to be updated: recompile now?']);
            if strcmp(answer,'Yes')
                path_uvmat=fileparts(which('series'));
                currentdir=pwd;
                cd(get(handles.ActionPath,'String'))% go to the directory of Action
                addpath(path_uvmat)% add the path to uvmat to run the fct 'compile'
                addpath(fullfile(path_uvmat,'transform_field'))% add the path to uvmat to run the fct 'compile'
                compile(ActionName,TransformPath)
                cd(currentdir)
            end
        end
    end
    set(handles.ActionExt,'BackgroundColor',[1 1 1])
     set(handles.series,'Pointer','arrow') % set the mouse pointer to 'watch
end

%% set nbre of cluster cores and processes
switch RunMode
    case {'local','background'}
        NbCore=1;% no need to split the calculation
    case 'cluster_oar'
        if strcmp(ActionExt,'.m')% case of Matlab function (uncompiled)
            NbCore=1;% one core used only (limitation of Matlab licences)
            answer=msgbox_uvmat('INPUT_Y-N','Number of cores =1: select the compiled version .sh for multi-core processing. Proceed with the .m version?');
            if ~strcmp(answer,'Yes')
                errormsg='Action launch interrupted';
                return
            end
            extra_oar='';
        else
            answer=inputdlg({'Number of cores (max 36)','extra oar options'},'oarsub parameter',1,{'12',''});
            NbCore=str2double(answer{1});
            extra_oar=answer{2};
        end
    case 'cluster_pbs'
        if strcmp(ActionExt,'.m')% case of Matlab function (uncompiled)
            NbCore=1;% one core used only (limitation of Matlab licences)
            answer=msgbox_uvmat('INPUT_Y-N','Number of cores =1: select the compiled version .sh for multi-core processing. Proceed with the .m version?');
            if ~strcmp(answer,'Yes')
                errormsg='Action launch interrupted';
                return
            end
            extra_oar='';
        else
            answer=inputdlg({'Number of cores (max 36)','extra oar options'},'oarsub parameter',1,{'12',''});
            NbCore=str2double(answer{1});
            %extra_oar=answer{2};%TODO : fix this for LMFA cluster. Maybe
            %extrs_oar and extra_pbs are not the best names
        end
end
if ~isfield(Param.IndexRange,'NbSlice')
    Param.IndexRange.NbSlice=[];
end
if isempty(Param.IndexRange.NbSlice)
    NbProcess=NbCore;% choose one process per core
else
    NbProcess=Param.IndexRange.NbSlice;% the nbre of run processes is equal to the number of slices
    NbCore=min(NbCore,NbProcess);% at least one process per core
end

%% create the output data directory if needed
OutputDir='';
if isfield(Param,'OutputSubDir')
    SubDirOut=[get(handles.OutputSubDir,'String') Param.OutputDirExt];
    SubDirOutNew=SubDirOut;
    detect=exist(fullfile(Param.InputTable{1,1},SubDirOutNew),'dir');% test if  the dir  already exist
    check_create=1; %need to create the result directory by default
    while detect
        answer=msgbox_uvmat('INPUT_Y-N-Cancel',['use existing ouput directory: ' fullfile(Param.InputTable{1,1},SubDirOutNew) ', possibly delete previous data']);
        if strcmp(answer,'Cancel')
            return
        elseif strcmp(answer,'Yes')
            detect=0;
            check_create=0;
        else
            r=regexp(SubDirOutNew,'(?<root>.*\D)(?<num1>\d+)$','names');%detect whether name ends by a number
            if isempty(r)
                r(1).root=[SubDirOutNew '_'];
                r(1).num1='0';
            end
            SubDirOutNew=[r(1).root num2str(str2num(r(1).num1)+1)];%increment the index by 1 or put 1
            detect=exist(fullfile(Param.InputTable{1,1},SubDirOutNew),'dir');% test if  the dir  already exists
            check_create=1;
        end
    end
    Param.OutputDirExt=regexprep(SubDirOutNew,Param.OutputSubDir,'');
    Param.OutputRootFile=Param.InputTable{1,3};% the first sorted RootFile taken for output
    set(handles.OutputDirExt,'String',Param.OutputDirExt)
    OutputDir=fullfile(Param.InputTable{1,1},[Param.OutputSubDir Param.OutputDirExt]);% full name (with path) of output directory
    if check_create    % create output directory if it does not exist
        [tild,msg1]=mkdir(OutputDir);
        if ~strcmp(msg1,'')
            errormsg=['cannot create ' OutputDir ': ' msg1];%error message for directory creation
            return
        end
        [success,msg] = fileattrib(OutputDir,'+w','g','s');% allow writing access for the group of users, recursively in the folder  
        if success==0
            msgbox_uvmat('WARNING',{['unable to set group write access to ' OutputDir ':']; msg1});%error message for directory creation
        end
    end
    
elseif isfield(Param,'ActionInput')&&isfield(Param.ActionInput,'LogPath')% custom definition of the output dir
    OutputDir=Param.ActionInput.LogPath;   
end
DirXml=fullfile(OutputDir,'0_XML');
if ~exist(DirXml,'dir')
    [tild,msg1]=mkdir(DirXml);
    if ~strcmp(msg1,'')
        errormsg=['cannot create ' DirXml ': ' msg1];%error message for directory creation
        return
    end
    [success,msg] = fileattrib(DirXml,'+w','g','s');% allow writing access for the group of users, recursively in the folder
    if success==0
        msgbox_uvmat('WARNING',{['unable to set group write access to ' DirXml ':']; msg});%error message for directory creation
    end
end
OutputNomType=nomtype2pair(Param.InputTable{1,4});% nomenclature for output files

%% get the set of reference field indices
first_i=1;
last_i=1;
incr_i=1;
first_j=1;
last_j=1;
incr_j=1;
if isfield(Param.IndexRange,'first_i')
    first_i=Param.IndexRange.first_i;
    incr_i=Param.IndexRange.incr_i;
    last_i=Param.IndexRange.last_i;
end
if isfield(Param.IndexRange,'first_j')
    first_j=Param.IndexRange.first_j;
    last_j=Param.IndexRange.last_j;
    incr_j=Param.IndexRange.incr_j;
end
if last_i < first_i || last_j < first_j 
    errormsg= 'series/Run_Callback:last field index must be larger or equal to the first one';
    return
end
%incr_i must be defined, =1 by default, if NbSlice is active
if isempty(incr_i)&& ~isempty(Param.IndexRange.NbSlice)
    incr_i=1;
    set(handles.num_incr_i,'String','1')
end
if isempty(incr_i)
    if isempty(incr_j)
        [ref_j,ref_i]=find(squeeze(SeriesData.i1_series{1}(1,:,:)));
        ref_j=ref_j(ref_j>=first_j & ref_j<=last_j);
        ref_i=ref_i(ref_i>=first_i & ref_i<=last_i);
        ref_j=ref_j-1;
        ref_i=ref_i-1;
    else
        ref_j=first_j:incr_j:last_j;
        [tild,ref_i]=find(squeeze(SeriesData.i1_series{1}(1,:,:)));
        ref_i=ref_i-1;
        ref_i=ref_i(ref_i>=first_i & ref_i<=last_i);
    end
else
    ref_i=first_i:incr_i:last_i;
    if isempty(incr_j)
        [ref_j,tild]=find(squeeze(SeriesData.i1_series{1}(1,:,:)));
        ref_j=ref_j-1;
        ref_j=ref_j(ref_j>=first_j & ref_j<=last_j);
    else
        ref_j=first_j:incr_j:last_j;
    end
end
BlockLength=ceil(numel(ref_i)/NbProcess);
nbfield_j=numel(ref_j);

%% record nbre of output files and starting time for computation for status
StatusData=get(handles.status,'UserData');
if isfield(StatusData,'OutputFileMode')
    switch StatusData.OutputFileMode
        case 'NbInput'
            StatusData.NbOutputFile=numel(ref_i)*nbfield_j;
        case 'NbInput_i'
            StatusData.NbOutputFile=numel(ref_i);
        case 'NbSlice'    
            StatusData.NbOutputFile=str2num(get(handles.num_NbSlice,'String'));
    end
end
StatusData.TimeStart=now;
set(handles.status,'UserData',StatusData)


if strcmp(ActionExt, '.py (in dev.)')
    fprintf([
        '\n' ...
        '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n' ...
        'The option .py is used. It is still in development.\n' ...
        'Do not use it unless you really know what you do!\n' ...
        'To try it, first install Pyp and the most recent version of FluidDyn.\n' ...
        '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'])
    RunMode = 'python';
    t = struct2xml(Param);
    t = set(t, 1, 'name', 'Series');
    filexml = fullfile_uvmat(DirXml, '', Param.InputTable{1,3}, '.xml', OutputNomType,...
         Param.IndexRange.first_i, Param.IndexRange.last_i, first_j, last_j);
    save(t, filexml);
end


%% direct processing on the current Matlab session
if strcmp (RunMode,'local')
    for iprocess=1:NbProcess
        if isempty(Param.IndexRange.NbSlice)
            %Param.IndexRange.first_i=first_i+(iprocess-1)*BlockLength*incr_i;
            Param.IndexRange.first_i=ref_i(1+(iprocess-1)*BlockLength);
            if Param.IndexRange.first_i>last_i
                break
            end
            Param.IndexRange.last_i=min(ref_i(iprocess*BlockLength),last_i);
            %Param.IndexRange.last_i=min(first_i+(iprocess)*BlockLength*incr_i-1,last_i);
        else %multislices (then incr_i is not empty)
             Param.IndexRange.first_i= first_i+incr_i*(iprocess-1);
             Param.IndexRange.incr_i=incr_i*Param.IndexRange.NbSlice;
        end
        if isfield(Param,'OutputSubDir')
        t=struct2xml(Param);
        t=set(t,1,'name','Series');
        filexml=fullfile_uvmat(DirXml,'',Param.InputTable{1,3},'.xml',OutputNomType,...
            Param.IndexRange.first_i,Param.IndexRange.last_i,first_j,last_j);
        save(t,filexml);
        end
        switch ActionExt
            case '.m'
                h_fun(Param);
            case '.sh'
                switch computer
                    case {'PCWIN','PCWIN64'} %Windows system
                        filexml=regexprep(filexml,'\\','\\\\');% add '\' so that '\' are left as characters
                        system([fullfile(ActionPath,[ActionName '.sh']) ' ' RunTime ' ' filexml]);% TODO: adapt to DOS system
                    case {'GLNX86','GLNXA64','MACI64'}%Linux  system
                        system([fullfile(ActionPath,[ActionName '.sh']) ' ' RunTime ' ' filexml]);
                end
        end
    end
elseif ~strcmp(RunMode,'python')
    %% processing on a different session of the same computer (background) or cluster, create executable files
    batch_file_list=cell(NbProcess,1);% initiate the list of executable files
    DirBat=fullfile(OutputDir,'0_EXE');
    switch computer
        case {'PCWIN','PCWIN64'} %Windows system
            ExeExt='.bat';
        case {'GLNX86','GLNXA64','MACI64'}%Linux  system
           ExeExt='.sh';
    end
    %create subdirectory for executable files
    if ~exist(DirBat,'dir')
        [tild,msg1]=mkdir(DirBat);
        if ~strcmp(msg1,'')
            errormsg=['cannot create ' DirBat ': ' msg1];%error message for directory creation
            return
        end
    end
    %create subdirectory for log files
    DirLog=fullfile(OutputDir,'0_LOG');
    if ~exist(DirLog,'dir')
        [tild,msg1]=mkdir(DirLog);
        if ~strcmp(msg1,'')
            errormsg=['cannot create ' DirLog ': ' msg1];%error message for directory creation
            return
        end
    end
    for iprocess=1:NbProcess
        if isempty(Param.IndexRange.NbSlice)% process by blocks of i index
            Param.IndexRange.first_i=first_i+(iprocess-1)*BlockLength*incr_i;
            if Param.IndexRange.first_i>last_i
                NbProcess=iprocess-1;
                break% leave the loop, we are at the end of the calculation
            end
            Param.IndexRange.last_i=min(last_i,first_i+(iprocess)*BlockLength*incr_i-1);
        else% process by slices of i index if NbSlice is defined, computation in a single process if NbSlice =1
            Param.IndexRange.first_i= first_i+iprocess-1;
            Param.IndexRange.incr_i=incr_i*Param.IndexRange.NbSlice;
        end
        for ilist=1:size(Param.InputTable,1)
        Param.InputTable{ilist,1}=regexprep(Param.InputTable{ilist,1},'\','/');%correct path name for PCWIN system
        end
        % create, fill and save the xml parameter file
        t=struct2xml(Param);
        t=set(t,1,'name','Series');
        filexml=fullfile_uvmat(DirXml,'',Param.InputTable{1,3},'.xml',OutputNomType,...
            Param.IndexRange.first_i,Param.IndexRange.last_i,first_j,last_j);
        save(t,filexml);% save the parameter file
        
        %create the executable file
         filebat=fullfile_uvmat(DirBat,'',Param.InputTable{1,3},ExeExt,OutputNomType,...
           Param.IndexRange.first_i,Param.IndexRange.last_i,first_j,last_j);
        batch_file_list{iprocess}=filebat;
        [fid,message]=fopen(filebat,'w');% create the executable file
        if isequal(fid,-1)
            errormsg=['creation of .bat file: ' message];
            return
        end
        
        % set the log file name
        filelog=fullfile_uvmat(DirLog,'',Param.InputTable{1,3},'.log',OutputNomType,...
            Param.IndexRange.first_i,Param.IndexRange.last_i,first_j,last_j);
        
        % fill and save the executable file
        switch ActionExt
            case '.m'% Matlab function
                switch computer
                    case {'GLNX86','GLNXA64','MACI64'}
                        cmd=[...
                            '#!/bin/bash \n'...
                            '. /etc/sysprofile \n'...
                            'matlab -nodisplay -nosplash -nojvm -logfile ''' filelog ''' <<END_MATLAB \n'...
                            'addpath(''' path_series '''); \n'...
                            'addpath(''' Param.Action.ActionPath '''); \n'...
                            '' Param.Action.ActionName  '( ''' filexml '''); \n'...
                            'exit \n'...
                            'END_MATLAB \n'];
                        fprintf(fid,cmd);%fill the executable file with the  char string cmd
                        fclose(fid);% close the executable file
                        system(['chmod +x ' filebat]);% set the file to executable
                    case {'PCWIN','PCWIN64'}
                        text_matlabscript=['matlab -automation -logfile ' regexprep(filelog,'\\','\\\\')...
                            ' -r "addpath(''' regexprep(path_series,'\\','\\\\') ''');'...
                            'addpath(''' regexprep(Param.Action.ActionPath,'\\','\\\\') ''');'...
                            '' Param.Action.ActionName  '( ''' regexprep(filexml,'\\','\\\\') ''');exit"'];
                        fprintf(fid,text_matlabscript);%fill the executable file with the  char string cmd
                        fclose(fid);% close the executable file
                end
            case '.sh' % compiled Matlab function
                switch computer
                    case {'GLNX86','GLNXA64','MACI64'}
                        cmd=['#!/bin/bash \n '...
                            '#$ -cwd \n '...
                            'hostname && date \n '...
                            'umask 002 \n'...
                            fullfile(ActionPath,[ActionName '.sh']) ' ' RunTime ' ' filexml];%allow writting access to created files for user group
                        fprintf(fid,cmd);%fill the executable file with the  char string cmd
                        fclose(fid);% close the executable file
                        system(['chmod +x ' filebat]);% set the file to executable
                        
                    case {'PCWIN','PCWIN64'}    
                        fprintf(fid,cmd);
                        fclose(fid);
                end
        end
    end
end

%% launch the executable files for background or cluster processing
switch RunMode
    case 'background'
        for iprocess=1:NbProcess
            system([batch_file_list{iprocess} ' &'])% directly execute the command file for each process
            msgbox_uvmat('CONFIRMATION',[ActionName ' launched in background: press STATUS to see results'])
        end
    case 'cluster_oar' % option 'oar-parexec' used
        %create subdirectory for oar command and log files
        DirOAR=fullfile(OutputDir,'0_OAR');
        if exist(DirOAR,'dir')% delete the content of the dir 0_OAR to allow new input
            curdir=pwd;
            cd(DirOAR)
            delete('*')
            cd(curdir)
        else
            [tild,msg1]=mkdir(DirOAR);
            if ~strcmp(msg1,'')
                errormsg=['cannot create ' DirOAR ': ' msg1];%error message for directory creation
                return
            end
        end
        max_walltime=3600*20; % 20h max total calculation (cannot exceed 24 h)
        walltime_onejob=600;%seconds, max estimated time for asingle file index value
        filename_joblist=fullfile(DirOAR,'job_list.txt');%create name of the global executable file
        fid=fopen(filename_joblist,'w');
        for p=1:length(batch_file_list)
            fprintf(fid,[batch_file_list{p} '\n']);% list of exe files 
        end
        fclose(fid);
        system(['chmod +x ' filename_joblist]);% set the file to executable
        oar_command=['oarsub -n CIVX '...
            '-t idempotent --checkpoint ' num2str(walltime_onejob+60) ' '...
            '-l /core=' num2str(NbCore) ','...
            'walltime=' datestr(min(1.05*walltime_onejob/86400*max(NbProcess*BlockLength*nbfield_j,NbCore)/NbCore,max_walltime/86400),13) ' '...
            '-E ' regexprep(filename_joblist,'\.txt\>','.stderr') ' '...
            '-O ' regexprep(filename_joblist,'\.txt\>','.stdout') ' '...
            extra_oar ' '...
            '"oar-parexec -s -f ' filename_joblist ' '...
            '-l ' filename_joblist '.log"\n'];
        filename_oarcommand=fullfile(DirOAR,'oar_command');
        fid=fopen(filename_oarcommand,'w');
        fprintf(fid,oar_command);
        fclose(fid);
        fprintf(oar_command);% display in command line
        system(oar_command);  
        msgbox_uvmat('CONFIRMATION',[ActionName ' launched in cluster: press STATUS to see results'])
    case 'cluster_pbs' % for LMFA Kepler machine
        %create subdirectory for pbs command and log files
        DirPBS=fullfile(OutputDir,'0_PBS'); %todo : common name OAR/PBS
        if exist(DirPBS,'dir')% delete the content of the dir 0_OAR to allow new input
            curdir=pwd;
            cd(DirPBS)
            delete('*')
            cd(curdir)
        else
            [tild,msg1]=mkdir(DirPBS);
            if ~strcmp(msg1,'')
                errormsg=['cannot create ' DirPBS ': ' msg1];%error message for directory creation
                return
            end
        end
        max_walltime=3600*20; % 20h max total calculation (cannot exceed 24 h)
        walltime_onejob=600;%seconds, max estimated time for asingle file index value
        filename_joblist=fullfile(DirPBS,'job_list.txt');%create name of the global executable file
        fid=fopen(filename_joblist,'w');
        for p=1:length(batch_file_list)
            fprintf(fid,[batch_file_list{p} '\n']);% list of exe files 
        end
        fclose(fid);
        system(['chmod +x ' filename_joblist]);% set the file to executable
        pbs_command=['qstat -n CIVX '...
            '-t idempotent --checkpoint ' num2str(walltime_onejob+60) ' '...
            '-l /core=' num2str(NbCore) ','...
            'walltime=' datestr(min(1.05*walltime_onejob/86400*max(NbProcess*BlockLength*nbfield_j,NbCore)/NbCore,max_walltime/86400),13) ' '...
            '-E ' regexprep(filename_joblist,'\.txt\>','.stderr') ' '...
            '-O ' regexprep(filename_joblist,'\.txt\>','.stdout') ' '...
            extra_oar ' '...
            '"oar-parexec -s -f ' filename_joblist ' '...
            '-l ' filename_joblist '.log"\n'];
        filename_oarcommand=fullfile(DirPBS,'pbs_command');
        fid=fopen(filename_oarcommand,'w');
        fprintf(fid,pbs_command);
        fclose(fid);
        fprintf(pbs_command);% display in command line
        %system(pbs_command);  
        msgbox_uvmat('CONFIRMATION',[ActionName ' command ready to be launched in cluster'])        
    case 'python'
        command = [
            'LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | pyp "p.split('':'') | [s for s in p if ''matlab'' not in s] | '':''.join(p)") ' ...
            'python -m fluiddyn.postproc.uvmat ' filexml];
        % fprintf(['command:\n' command '\n\n'])
        system(command, '-echo');
end

%------------------------------------------------------------------------
function STOP_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RUN, 'BusyAction','cancel')
set(handles.RUN,'BackgroundColor',[1 0 0])
set(handles.RUN,'enable','on')
set(handles.RUN, 'Value',0)


%------------------------------------------------------------------------
% --- read parameters from the GUI series
%------------------------------------------------------------------------
function Param=read_GUI_series(handles)

%% read raw parameters from the GUI series
Param=read_GUI(handles.series);

%% clean the output structure by removing unused information 
if isfield(Param,'Pairs')
    Param=rmfield(Param,'Pairs'); %info Pairs not needed for output
end
if isfield(Param,'InputLine')
    Param=rmfield(Param,'InputLine');
end
if isfield(Param,'EditObject')
    Param=rmfield(Param,'EditObject');
end
Param.IndexRange.TimeSource=Param.IndexRange.TimeTable{end,1};
Param.IndexRange=rmfield(Param.IndexRange,'TimeTable');
empty_line=false(size(Param.InputTable,1),1);
for iline=1:size(Param.InputTable,1)
    empty_line(iline)=isempty(cell2mat(Param.InputTable(iline,1:3)));
end
Param.InputTable(empty_line,:)=[];

%------------------------------------------------------------------------
% --- Executes on selection change in ActionName.
function ActionName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%% stop any ongoing series processing
if isequal(get(handles.RUN,'Value'),1)
    answer= msgbox_uvmat('INPUT_Y-N','stop current Action process?');
    if strcmp(answer,'Yes')
        STOP_Callback(hObject, eventdata, handles)
    else
        return
    end
end
set(handles.ActionName,'BackgroundColor',[1 1 0])
huigetfile=findobj(allchild(0),'tag','status_display');
if ~isempty(huigetfile)
    delete(huigetfile)
end
drawnow

%% check whether the input file(s) need to be refreshed
% SeriesData=get(handles.series,'UserData');%hidden parameters
% if ~isfield(SeriesData,'i1_series')
%     msgbox_uvmat('ERROR','The input field series needs to be refreshed: press REFRESH');
%     return
% end

%% get Action name and path
NbBuiltinAction=get(handles.Action,'UserData'); %nbre of functions initially proposed in the menu ActionName (as defined in the Opening fct of series)
ActionList=get(handles.ActionName,'String');% list menu fields
ActionIndex=get(handles.ActionName,'Value');
if ~isequal(ActionIndex,1)% if we are not just opening series 
    InputTable=get(handles.InputTable,'Data');
    if isempty(InputTable{1,4})
        msgbox_uvmat('ERROR','no input file available: use Open in the menu bar')
        return
    end
end
ActionName= ActionList{get(handles.ActionName,'Value')}; % selected function name
ActionPathList=get(handles.ActionName,'UserData');%list of recorded paths to functions of the list ActionName

%% add a new function to the menu if 'more...' has been selected in the menu ActionName
if isequal(ActionName,'more...')
    [FileName, PathName] = uigetfile( ...
        {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a series processing function ',get(handles.ActionPath,'String'));
    if length(FileName)<2
        return
    end
    [tild,ActionName,ActionExt]=fileparts(FileName);
    
    % insert the choice in the menu ActionName
    ActionIndex=find(strcmp(ActionName,ActionList),1);% look for the selected function in the menu Action
    PathName=regexprep(PathName,'/$','');
    if ~isempty(ActionIndex) && ~strcmp(ActionPathList{ActionIndex},PathName)%compare the path to the existing fct
        ActionIndex=[]; % the selected path is different than the recorded one
    end
    if isempty(ActionIndex)%the qselected fct (with selected path) does not exist in the menu
        ActionIndex= length(ActionList);
        ActionList=[ActionList(1:end-1);{ActionName};ActionList(end)];% the selected function is appended in the menu, before the last item 'more...'
         ActionPathList=[ActionPathList; PathName];
    end
    
    % record the file extension and extend the path list if it is a new extension
    ActionExtList=get(handles.ActionExt,'String');
    ActionExtIndex=find(strcmp(ActionExt,ActionExtList), 1);
    if isempty(ActionExtIndex)
        set(handles.ActionExt,'String',[ActionExtList;{ActionExt}])
    end

    % remove old Action options in the menu (keeping a menu length <nb_builtin_ACTION+5)
    if length(ActionList)>NbBuiltinAction+5; %nb_builtin_ACTION=nbre of functions always remaining in the initial menu
        nbremove=length(ActionList)-NbBuiltinAction-5;
        ActionList(NbBuiltinAction+1:end-5)=[];
        ActionPathList(NbBuiltinAction+1:end-4,:)=[];
        ActionIndex=ActionIndex-nbremove;
    end
    
    % record action menu, choice and path
    set(handles.ActionName,'Value',ActionIndex)
    set(handles.ActionName,'String',ActionList)
       set(handles.ActionName,'UserData',ActionPathList);
    set(handles.ActionExt,'Value',ActionExtIndex)
%     ActionPathList{ActionIndex,ActionExtIndex}=PathName;
        
    %record the user defined menu additions in personal file profil_perso
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if NbBuiltinAction+1<=numel(ActionList)-1
        ActionListUser=ActionList(NbBuiltinAction+1:numel(ActionList)-1);
        ActionPathListUser=ActionPathList(NbBuiltinAction+1:numel(ActionList)-1);
        ActionExtListUser={};
        if numel(ActionExtList)>2
            ActionExtListUser=ActionExtList(3:end);
        end
        if exist(profil_perso,'file')
            save(profil_perso,'ActionListUser','ActionPathListUser','ActionExtListUser','-append')
        else
            save(profil_perso,'ActionListUser','ActionPathListUser','ActionExtListUser','-V6')
        end
    end
end

%% check the current ActionPath to the selected function
ActionPath=ActionPathList{ActionIndex};%current recorded path
set(handles.ActionPath,'String',ActionPath); %show the path to the senlected function

%% reinitialise the waitbar
update_waitbar(handles.Waitbar,0)

%% create the function handle for Action
path_series=which('series');
if ~isequal(ActionPath,path_series)
    eval(['spath=which(''' ActionName ''');']) %spath = current path of the selected function ACTION
    if ~exist(ActionPath,'dir')
        errormsg=['The prescribed function path ' ActionPath ' does not exist'];
        return
    end
    if ~isequal(spath,ActionPath)
        addpath(ActionPath)% add the prescribed path if not the current one
    end
end
eval(['h_fun=@' ActionName ';'])%create a function handle for ACTION
if ~isequal(ActionPath,path_series)
        rmpath(ActionPath)% add the prescribed path if not the current one    
end

%% Activate the Action fct to adapt the configuration of the GUI series and bring specific parameters in SeriesData
Param=read_GUI_series(handles);% read the parameters from the GUI series
ParamOut=h_fun(Param);%run the selected Action function to get the relevant input

%% Put the first line of the selected Action fct as tooltip help
try
    [fid,errormsg] =fopen([ActionName '.m']);
    InputText=textscan(fid,'%s',1,'delimiter','\n');
    fclose(fid);
    set(handles.ActionName,'ToolTipString',InputText{1}{1})% put the first line of the selected function as tooltip help
end


%% Visibility of VelType and VelType_1 menus asked by ActionName
VelTypeRequest=1;%VelType requested by default
VelTypeRequest_1=1;%VelType requested by default
if isfield(ParamOut,'VelType')
    VelTypeRequest=ismember(ParamOut.VelType,{'on','one','two'});
    VelTypeRequest_1=strcmp( ParamOut.VelType,'two');
end
FieldNameRequest=0;  %hidden by default
FieldNameRequest_1=0;  %hidden by default
if isfield(ParamOut,'FieldName')
    FieldNameRequest=ismember(ParamOut.FieldName,{'on','one','two'});
    FieldNameRequest_1=strcmp( ParamOut.FieldName,'two');
end

%% Detect the types of input files and set menus and default options in 'VelType'
SeriesData=get(handles.series,'UserData');% info on the input file series
iview_civ=find(strcmp('civx',SeriesData.FileType)|strcmp('civdata',SeriesData.FileType));
iview_netcdf=find(strcmp('netcdf',SeriesData.FileType)|strcmp('civx',SeriesData.FileType)|strcmp('civdata',SeriesData.FileType));% all nc files, icluding civ
FieldList=get(handles.FieldName,'String');% previous list as default
if ~iscell(FieldList),FieldList={FieldList};end
FieldList_1=get(handles.FieldName_1,'String');% previous list as default
if ~iscell(FieldList_1),FieldList_1={FieldList_1};end
CheckList=0;% indicate whether FieldName has been updated
CheckList_1=1;% indicate whether FieldName_1 has been updated
handles_coord=[handles.Coord_x handles.Coord_y handles.Coord_z handles.Coord_x_title handles.Coord_y_title handles.Coord_z_title];
if VelTypeRequest && numel(iview_civ)>=1 
    menu=set_veltype_display(SeriesData.FileInfo{iview_civ(1)}.CivStage,SeriesData.FileType{iview_civ(1)});
    set(handles.VelType,'Value',1)% set first choice by default
    set(handles.VelType,'String',[{'*'};menu])
    set(handles.VelType,'Visible','on')
    set(handles.VelType_title,'Visible','on')
    FieldList=[set_field_list('U','V');{'C'};{'get_field...'}];%standard menu for civx data
    CheckList=1;
    set(handles.FieldName,'Value',1); %velocity vector choice by default
    if  VelTypeRequest_1 && numel(iview_civ)>=2 
        menu=set_veltype_display(SeriesData.FileInfo{iview_civ(2)}.CivStage,SeriesData.FileType{iview_civ(2)});
        set(handles.VelType_1,'Value',1)% set first choice by default
        set(handles.VelType_1,'String',[{'*'};menu])
        set(handles.VelType_1,'Visible','on')
        set(handles.VelType_title_1,'Visible','on')
        FieldList_1=[set_field_list('U','V');{'C'};{'get_field...'}];%standard menu for civx data
        CheckList_1=1;
        set(handles.FieldName_1,'Value',1); %velocity vector choice by default
    else
        set(handles.VelType_1,'Visible','off')
        set(handles.VelType_title_1,'Visible','off')
    end
else
    set(handles.VelType,'Visible','off')
    set(handles.VelType_title,'Visible','off')
end   

%% Detect the types of input files and set menus and default options in 'FieldName'
if FieldNameRequest && numel(iview_netcdf)>=1
    set(handles.InputFields,'Visible','on')
    %if CheckList==0        % not civ input made
        if isfield(SeriesData.FileInfo{iview_netcdf(1)},'ListVarName')
        ListVarName=SeriesData.FileInfo{iview_netcdf(1)}.ListVarName;
        ind_var=get(handles.FieldName,'Value');%indices of previously selected variables
        for ilist=1:numel(ind_var)
            if isempty(find(strcmp(FieldList{ind_var(ilist)},ListVarName)))
                FieldList={};% previous choice not consistent with new input field
                set(handles.FieldName,'Value',1)
                break
            end
        end
        if ~isempty(FieldList)
            if isempty(find(strcmp(get(handles.Coord_x,'String'),ListVarName)))||...
                    isempty(find(strcmp(get(handles.Coord_y,'String'),ListVarName)))
                FieldList={};
                set(handles.Coord_x,'String','')
                set(handles.Coord_y,'String','')
            end
            Coord_z=get(handles.Coord_z,'String');
            if ~isempty(Coord_z) && isempty(find(strcmp(Coord_z,ListVarName)))
                FieldList={};
                set(handles.Coord_z,'String','')
            end
        end
        set(handles_coord,'Visible','on')
        FieldList=[FieldList;{'get_field...'}];
        if FieldNameRequest_1 && numel(iview_netcdf)>=2
            set(handles.FieldName_1,'Visible','on')
            if CheckList_1==0        % not civ input made
                ListVarName=SeriesData.FileInfo{iview_netcdf(2)}.ListVarName;
                ind_var=get(handles.FieldName,'Value');%indices of previously selected variables
                for ilist=1:numel(ind_var)
                    if isempty(find(strcmp(FieldList{ind_var(ilist)},ListVarName)))
                        FieldList_1={};% previous choice not consistent with new input field
                        set(handles.FieldName_1,'Value',1)
                        break
                    end
                end
                warn_coord=0;
                if isempty(find(strcmp(get(handles.Coord_x,'String'),ListVarName)))||...
                        isempty(find(strcmp(get(handles.Coord_y,'String'),ListVarName)))
                    warn_coord=1;
                end
                if ~isempty(Coord_z) && isempty(find(strcmp(Coord_z,ListVarName)))
                    FieldList_1={};
                    warn_coord=1;
                end
                if warn_coord
                    msgbox_uvmat('WARNING','coordiante names do not exist in the second netcdf input file')
                end
                set(handles.FieldName,'String',[FieldList;{'get_field...'}])
                set(handles.FieldName_1,'Visible','on')
                set(handles.FieldName_1,'Value',1)
                set(handles.FieldName_1,'String',FieldList_1)
            end
        else
            set(handles.FieldName_1,'Visible','off')
        end
        end
%     else
%         set(handles_coord,'Visible','off')% no coord display for civ data
%     end
    set(handles.FieldName,'String',FieldList)
else
    set(handles.InputFields,'Visible','off')
end


%% Check whether alphabetical sorting of input Subdir is allowed by the Action fct  (for multiples series entries)
if isfield(ParamOut,'AllowInputSort')&&isequal(ParamOut.AllowInputSort,'on')&& size(Param.InputTable,1)>1
    [tild,iview]=sort(InputTable(:,2)); %subdirectories sorted in alphabetical order
    set(handles.InputTable,'Data',InputTable(iview,:));
    MinIndex_i=get(handles.MinIndex_i,'Data');
    MinIndex_j=get(handles.MinIndex_j,'Data');
    MaxIndex_i=get(handles.MaxIndex_i,'Data');
    MaxIndex_j=get(handles.MaxIndex_j,'Data');
    set(handles.MinIndex_i,'Data',MinIndex_i(iview,:));
    set(handles.MinIndex_j,'Data',MinIndex_j(iview,:));
    set(handles.MaxIndex_i,'Data',MaxIndex_i(iview,:));
    set(handles.MaxIndex_j,'Data',MaxIndex_j(iview,:));
    TimeTable=get(handles.TimeTable,'Data');
    set(handles.TimeTable,'Data',TimeTable(iview,:));
    PairString=get(handles.PairString,'Data');
    set(handles.PairString,'Data',PairString(iview,:));
end

%% Impose the whole input file index range if requested
if isfield(ParamOut,'WholeIndexRange')&&isequal(ParamOut.WholeIndexRange,'on')
    MinIndex_i=get(handles.MinIndex_i,'Data');
    MinIndex_j=get(handles.MinIndex_j,'Data');
    MaxIndex_i=get(handles.MaxIndex_i,'Data');
    MaxIndex_j=get(handles.MaxIndex_j,'Data');
    set(handles.num_first_i,'String',num2str(MinIndex_i(1)))% set first as the min index (for the first line)
    set(handles.num_last_i,'String',num2str(MaxIndex_i(1)))% set last as the max index (for the first line)
    set(handles.num_incr_i,'String','1')
    set(handles.num_first_j,'String',num2str(MinIndex_j(1)))% set first as the min index (for the first line)
    set(handles.num_last_j,'String',num2str(MaxIndex_j(1)))% set last as the max index (for the first line)
    set(handles.num_incr_j,'String','1')
else  % check index ranges
    first_i=1;last_i=1;first_j=1;last_j=1;
    if isfield(Param.IndexRange,'first_i')
        first_i=Param.IndexRange.first_i;
        last_i=Param.IndexRange.last_i;
    end
    if isfield(Param.IndexRange,'first_j')
        first_j=Param.IndexRange.first_j;
        last_j=Param.IndexRange.last_j;
    end
    if last_i < first_i || last_j < first_j , msgbox_uvmat('ERROR','last field number must be larger than the first one'),...
            set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
end

%% enable or desable j index visibility
status_j='on';%default
if isfield(ParamOut,'Desable_j_index')&&isequal(ParamOut.Desable_j_index,'on')
    status_j='off';
end
if isempty(find(~cellfun(@isempty,SeriesData.j1_series), 1)); % case of empty j indices
    status_j='off'; % no j index needed
elseif strcmp(get(handles.PairString,'Visible'),'on')
    check_burst=cellfun(@isempty,regexp(get(handles.PairString,'Data'),'^j'));%=0 for burst case, 1 otherwise
    if isempty(find(check_burst, 1))% if all pair string begins by j (burst)
        status_j='off'; % no j index needed for bust case
    end
end
enable_j(handles,status_j) % no j index needed


%% NbSlice visibility
NbSliceVisible='off';%default
if isfield(ParamOut,'NbSlice') && isequal(ParamOut.NbSlice,'on')
    NbSliceVisible='on';
    set(handles.num_NbProcess,'String',get(handles.num_NbSlice,'String'))% the nbre of processes is imposed as the nbre of slices
else
    set(handles.num_NbProcess,'String','')% free nbre of processes 
end
set(handles.num_NbSlice,'Visible',NbSliceVisible)
set(handles.NbSlice_title,'Visible',NbSliceVisible)



%% Visibility of FieldTransform menu
FieldTransformVisible='off';  %hidden by default
if isfield(ParamOut,'FieldTransform')
    FieldTransformVisible=ParamOut.FieldTransform;  
    TransformName_Callback([],[], handles)
end
set(handles.FieldTransform,'Visible',FieldTransformVisible)
if isfield(ParamOut,'TransformPath')
    set(handles.ActionExt,'UserData',ParamOut.TransformPath)
else
    set(handles.ActionExt,'UserData',[])
end

%% Visibility of projection object
ProjObjectVisible='off';  %hidden by default
if isfield(ParamOut,'ProjObject')
    ProjObjectVisible=ParamOut.ProjObject;
end
set(handles.CheckObject,'Visible',ProjObjectVisible)
if ~get(handles.CheckObject,'Value')
    ProjObjectVisible='off';
end
set(handles.ProjObject,'Visible',ProjObjectVisible)
set(handles.DeleteObject,'Visible',ProjObjectVisible)
set(handles.ViewObject,'Visible',ProjObjectVisible)
set(handles.EditObject,'Visible',ProjObjectVisible)

%% Visibility of mask input
MaskVisible='off';  %hidden by default
if isfield(ParamOut,'Mask')
    MaskVisible=ParamOut.Mask;
end
set(handles.CheckMask,'Visible',MaskVisible);

%% definition of the directory containing the output files 
if  ~(isfield(SeriesData,'ActionName') && strcmp(ActionName,SeriesData.ActionName))
    OutputDirExt='.series'; %default
    if isfield(ParamOut,'OutputDirExt')&&~isempty(ParamOut.OutputDirExt)
        OutputDirExt=ParamOut.OutputDirExt;
    end
    set(handles.OutputDirExt,'String',OutputDirExt)
end
OutputDirVisible='off';
OutputSubDirMode='auto';%default
SubDirOut='';
if isfield(ParamOut,'OutputSubDirMode')
    OutputSubDirMode=ParamOut.OutputSubDirMode;
end
switch OutputSubDirMode
    case 'auto';%default
        OutputDirVisible='on';
        SubDir=InputTable(1:end,2); %set of subdirectories
        SubDirOut=SubDir{1};
        if numel(SubDir)>1
            for ilist=2:numel(SubDir)
                SubDirOut=[SubDirOut '-' regexprep(SubDir{ilist},'^/','')];
            end
        end
    case 'one'
        OutputDirVisible='on';
        SubDirOut=InputTable{1,2}; %use the first subdir name (+OutputDirExt) as output  subdirectory
    case 'two'
        OutputDirVisible='on';   
        SubDir=InputTable(1:2,2); %set of subdirectories
        SubDirOut=SubDir{1};
        if numel(SubDir)>1
                SubDirOut=[SubDirOut '-' regexprep(SubDir{2},'^/','')];
        end
    case 'last'
        OutputDirVisible='on';
        SubDirOut=InputTable{end,2}; %use the last subdir name (+OutputDirExt) as output  subdirectory
end
set(handles.OutputSubDir,'String',SubDirOut)
set(handles.OutputSubDir,'BackgroundColor',[1 1 1])% set edit box to white color to indicate refreshment
set(handles.OutputDirExt,'Visible',OutputDirVisible)
set(handles.OutputSubDir,'Visible',OutputDirVisible)
set(handles.OutputDir_title,'Visible',OutputDirVisible)
SeriesData.ActionName=ActionName;%record ActionName for next use


%% visibility of the run mode (local or background or cluster)
if strcmp(OutputSubDirMode,'none')
    RunModeVisible='off';% only local mode available if no output file is produced
else
    RunModeVisible='on';
end
set(handles.RunMode,'Visible',RunModeVisible)
set(handles.ActionExt,'Visible',RunModeVisible)
set(handles.RunMode_title,'Visible',RunModeVisible)
set(handles.ActionExt_title,'Visible',RunModeVisible)


%% Expected nbre of output files
if isfield(ParamOut,'OutputFileMode')
    StatusData.OutputFileMode=ParamOut.OutputFileMode;
    set(handles.status,'UserData',StatusData)
end

%% definition of an additional parameter set, determined by an ancillary GUI
if isfield(ParamOut,'ActionInput')
    set(handles.ActionInput,'Visible','on')
    ParamOut.ActionInput.Program=ActionName; % record the program in ActionInput
    SeriesData.ActionInput=ParamOut.ActionInput;
else
    set(handles.ActionInput,'Visible','off')
    if isfield(SeriesData,'ActionInput')
        SeriesData=rmfield(SeriesData,'ActionInput');
    end
end
set(handles.series,'UserData',SeriesData)
set(handles.ActionName,'BackgroundColor',[1 1 1])

%------------------------------------------------------------------------
% --- Executes on selection change in FieldName.
function FieldName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
field_str=get(handles.FieldName,'String');
field_index=get(handles.FieldName,'Value');
field=field_str{field_index(1)};
if isequal(field,'get_field...')
    SeriesData=get(handles.series,'UserData');
    % input line for which the field choice is relevant
    iview=find(ismember(SeriesData.FileType,{'netcdf','civx','civdata'}));% all nc files, icluding civ
    hget_field=findobj(allchild(0),'name','get_field');
    if ~isempty(hget_field)
        delete(hget_field)%delete opened versions of get_field
    end
    Param=read_GUI(handles.series);
    InputTable=Param.InputTable(iview,:);
    % check the existence of the first file in the series
    first_j=[];last_j=[];MinIndex_j=1;MaxIndex_j=1;%default setting for index j
    if isfield(Param.IndexRange,'first_j');% if index j is used     
        first_j=Param.IndexRange.first_j;
        last_j=Param.IndexRange.last_j;
        MinIndex_j=Param.IndexRange.MinIndex_j(iview);
        MaxIndex_j=Param.IndexRange.MaxIndex_j(iview);
    end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString{iview}; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    LineIndex=iview(1);
    if numel(iview)>1      
        answer=msgbox_uvmat('INPUT_TXT',['select the line of the input table:' num2str(iview)] ,num2str(iview(1)));
        LineIndex=str2num(answer);
%         InputLine=str2num(get(handles.InputLine,'String'));
%         if ismember(InputLine,iview)
%             LineIndex=InputLine;
%         end
    end
    FirstFileName=fullfile_uvmat(InputTable{LineIndex,1},InputTable{LineIndex,2},InputTable{LineIndex,3},...
        InputTable{LineIndex,5},InputTable{LineIndex,4},i1,i2,j1,j2);
    if exist(FirstFileName,'file')
        ParamIn.Title='get_field: pick input variables and coordinates for series processing';
        ParamIn.SeriesInput=1;
        GetFieldData=get_field(FirstFileName,ParamIn);
        FieldList={};
        if isfield(GetFieldData,'FieldOption')% if a field has been selected
        switch GetFieldData.FieldOption
            case 'vectors'
                UName=GetFieldData.PanelVectors.vector_x;
                VName=GetFieldData.PanelVectors.vector_y;
                YName={GetFieldData.Coordinates.Coord_y};
                FieldList={['vec(' UName ',' VName ')'];...
                    ['norm(' UName ',' VName ')'];...
                    UName;VName};
            case {'scalar'}
                FieldList=GetFieldData.PanelScalar.scalar;
                YName={GetFieldData.Coordinates.Coord_y};
                if ischar(FieldList)
                    FieldList={FieldList};
                end
            case 'civdata...'
                FieldList=[set_field_list('U','V') ;{'C'}];
                set(handles.FieldName,'Value',1) % set menu to 'velocity
                XName='X';
                YName='y';
        end
        set(handles.FieldName,'Value',1)
        set(handles.FieldName,'String',[FieldList; {'get_field...'}]);
        if ~strcmp(GetFieldData.FieldOption,'civdata...')
           if ~isempty(regexp(FieldList{1},'^vec'))
                set(handles.FieldName,'Value',1)
           else
                set(handles.FieldName,'Value',1:numel(FieldList))%select all input fields by default
           end
            XName=GetFieldData.Coordinates.Coord_x;
            YName=GetFieldData.Coordinates.Coord_y;
            TimeNameStr=GetFieldData.Time.SwitchVarIndexTime;
            % get the time info                     
            TimeTable=get(handles.TimeTable,'Data');
            switch TimeNameStr
                case 'file index'
                    TimeName='';
                case 'attribute'
                    TimeName=['att:' GetFieldData.Time.TimeName];
                    % update the time table
                    TimeTable{LineIndex,2}=get_time(Param.IndexRange.MinIndex_i(LineIndex),MinIndex_j,PairString,InputTable,SeriesData.FileInfo{LineIndex},GetFieldData.Time.TimeName);  % Min time     
                    TimeTable{LineIndex,3}=get_time(Param.IndexRange.first_i,first_j,PairString,InputTable,SeriesData.FileInfo{LineIndex},GetFieldData.Time.TimeName);  % first time              
                    TimeTable{LineIndex,4}=get_time(Param.IndexRange.last_i,last_j,PairString,InputTable,SeriesData.FileInfo{LineIndex},GetFieldData.Time.TimeName);  % last time                     
                    TimeTable{LineIndex,5}=get_time(Param.IndexRange.MaxIndex_i(LineIndex),MaxIndex_j,PairString,InputTable,SeriesData.FileInfo{LineIndex},GetFieldData.Time.TimeName);  % Max time
                case 'variable'
                    set(handles.TimeName,'String',['var:' GetFieldData.Time.TimeName])
                    set(handles.NomType,'String','*')
                    set(handles.RootFile,'String',[get(handles.RootFile,'String') get(handles.FileIndex,'String')])% A VERIFIER !!!!!!
                    set(handles.FileIndex,'String','')
                    ParamIn.TimeVarName=GetFieldData.Time.TimeName;
                case 'matrix_index'
                    TimeName=['dim:' GetFieldData.Time.TimeName];
                    set(handles.NomType,'String','*')
                    set(handles.RootFile,'String',[get(handles.RootFile,'String') get(handles.FileIndex,'String')])
                    set(handles.FileIndex,'String','')
                    ParamIn.TimeDimName=GetFieldData.Time.TimeName;
            end
            TimeTable{LineIndex,1}=TimeName;
            set(handles.TimeTable,'Data',TimeTable);
        end
        set(handles.Coord_x,'String',XName)
        set(handles.Coord_y,'String',YName)
        set(handles.Coord_x,'Visible','on')
        set(handles.Coord_y,'Visible','on')
        end
    else
        msgbox_uvmat('ERROR',[FirstFileName ' does not exist'])
    end
end

function [TimeValue,DtValue]=get_time(ref_i,ref_j,PairString,InputTable,FileInfo,TimeName,DtName)
[i1,i2,j1,j2] = get_file_index(ref_i,ref_j,PairString);
FileName=fullfile_uvmat(InputTable{1},InputTable{2},InputTable{3},InputTable{5},InputTable{4},i1,i2,j1,j2);
Data=nc2struct(FileName,[]);
TimeValue=[];
DtValue=[];
if isequal(FileInfo.FileType,'civdata')
    if ismember(TimeName,{'civ1','filter1'})
        TimeValue=Data.Civ1_Time;
        DtValue=Data.Civ1_Dt;
    else
        TimeValue=Data.Civ2_Time;
        DtValue=Data.Civ2_Dt;
    end
else
    if ~isempty(TimeName)&& isfield(Data,TimeName)
        TimeValue=Data.(TimeName);
    end
    if exist('DtName','var') && isfield(Data,DtName)
        DtValue=Data.(DtName);
    end
end

%------------------------------------------------------------------------
% --- Executes on selection change in FieldName_1.
function FieldName_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
field_str=get(handles.FieldName_1,'String');
field_index=get(handles.FieldName_1,'Value');
field=field_str{field_index(1)};
if isequal(field,'get_field...')
    hget_field=findobj(allchild(0),'name','get_field');
    if ~isempty(hget_field)
        delete(hget_field)%delete opened versions of get_field
    end
    Param=read_GUI(handles.series);
    Param.InputTable=Param.InputTable(1,:);
    % check the existence of the first file in the series
    first_j=[];
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    if isfield(Param.IndexRange,'last_j'); last_j=Param.IndexRange.last_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if exist(FirstFileName,'file')
        ParamIn.SeriesInput=1;
        GetFieldData=get_field(FirstFileName,ParamIn);
        FieldList={};
        switch GetFieldData.FieldOption
            case 'vectors'
                UName=GetFieldData.PanelVectors.vector_x;
                VName=GetFieldData.PanelVectors.vector_y;
                FieldList={['vec(' UName ',' VName ')'];...
                    ['norm(' UName ',' VName ')'];...
                    UName;VName};
            case {'scalar','pick variables'}
                FieldList=GetFieldData.PanelScalar.scalar;
                if ischar(FieldList)
                    FieldList={FieldList};
                end
            case '1D plot'

            case 'civdata...'
                FieldList=set_field_list('U','V','C');
                set(handles.FieldName,'Value',2) % set menu to 'velocity
        end
        if ~strcmp(GetFieldData.FieldOption,'civdata...')
            TimeNameStr=GetFieldData.Time.SwitchVarIndexTime;
            switch TimeNameStr
                case 'file index'
                    set(handles.TimeName,'String','');
                case 'attribute'
                    set(handles.TimeName,'String',['att:' GetFieldData.Time.TimeName]);
                case 'variable'
                    set(handles.TimeName,'String',['var:' GetFieldData.Time.TimeName])
                    set(handles.NomType,'String','*')
                    set(handles.RootFile,'String',[get(handles.RootFile,'String') get(handles.FileIndex,'String')])% A VERIFIER !!!!!!
                    set(handles.FileIndex,'String','')
                    ParamIn.TimeVarName=GetFieldData.Time.TimeName;
                case 'matrix_index'
                    set(handles.TimeName,'String',['dim:' GetFieldData.Time.TimeName]);
                    set(handles.NomType,'String','*')
                    set(handles.RootFile,'String',[get(handles.RootFile,'String') get(handles.FileIndex,'String')])
                    set(handles.FileIndex,'String','')
                    ParamIn.TimeDimName=GetFieldData.Time.TimeName;
            end
        end
        set(handles.FieldName_1,'Value',1)
        set(handles.FieldName_1,'String',[FieldList; {'get_field...'}]);
    end
end   


%%%%%%%%%%%%%
function [ind_remove]=find_pairs(dirpair,ind_i,last_i)
indsel=ind_i;
indiff=diff(ind_i); %test index increment to detect multiplets (several pairs with the same index ind_i) and holes in the series
indiff=[1 indiff last_i-ind_i(end)+1];%for testing gaps with the imposed bounds
if ~isempty(indiff)
    indiff2=diff(indiff);
    indiffp=[indiff2 1];
    indiffm=[1 indiff2];
    ind_multi_m=find((indiff==0)&(indiffm<0))-1;%indices of first members of multiplets
    ind_multi_p=find((indiff==0)&(indiffp>0));%indices of last members of multiplets
    %for each multiplet, select the most recent file
    ind_remove=[];
    for i=1:length(ind_multi_m)
        ind_pairs=ind_multi_m(i):ind_multi_p(i);
        for imulti=1:length(ind_pairs)
            datepair(imulti)=datenum(dirpair(ind_pairs(imulti)).date);%dates of creation
        end
        [datenew,indsort2]=sort(datepair); %sort the multiplet by creation date
        ind_s=indsort2(1:end-1);%
        ind_remove=[ind_remove ind_pairs(ind_s)];%remove these indices, leave the last one
    end
end

%------------------------------------------------------------------------
% --- determine the list of index pairstring of processing file 
function [num_i1,num_i2,num_j1,num_j2,num_i_out,num_j_out]=find_file_indices(num_i,num_j,ind_shift,NomType,mode)
%------------------------------------------------------------------------
num_i1=num_i;% set of first image numbers by default
num_i2=num_i;
num_j1=num_j;
num_j2=num_j;
num_i_out=num_i;
num_j_out=num_j;
% if isequal (NomType,'_1-2_1') || isequal (NomType,'_1-2')
if isequal(mode,'series(Di)')
    num_i1_line=num_i+ind_shift(3);% set of first image numbers
    num_i2_line=num_i+ind_shift(4);
    % adjust the first and last field number
        indsel=find(num_i1_line >= 1);
    num_i_out=num_i(indsel);
    num_i1_line=num_i1_line(indsel);
    num_i2_line=num_i2_line(indsel);
    num_j1=meshgrid(num_j,ones(size(num_i1_line)));
    num_j2=meshgrid(num_j,ones(size(num_i1_line)));
    [xx,num_i1]=meshgrid(num_j,num_i1_line);
    [xx,num_i2]=meshgrid(num_j,num_i2_line);
elseif isequal (mode,'series(Dj)')||isequal (mode,'bursts')
    if isequal(mode,'bursts') %case of bursts (png_old or png_2D)
        num_j1=ind_shift(1)*ones(size(num_i));
        num_j2=ind_shift(2)*ones(size(num_i));
    else
        num_j1_col=num_j+ind_shift(1);% set of first image numbers
        num_j2_col=num_j+ind_shift(2);
        % adjust the first field number
        indsel=find((num_j1_col >= 1));   
        num_j_out=num_j(indsel);
        num_j1_col=num_j1_col(indsel);
        num_j2_col=num_j2_col(indsel);
        [num_i1,num_j1]=meshgrid(num_i,num_j1_col);
        [num_i2,num_j2]=meshgrid(num_i,num_j2_col);
    end    
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckObject.
function CheckObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
hset_object=findobj(allchild(0),'tag','set_object');%find the set_object interface handle
if get(handles.CheckObject,'Value')
    SeriesData=get(handles.series,'UserData');
    if isfield(SeriesData,'ProjObject') && ~isempty(SeriesData.ProjObject)
        set(handles.ViewObject,'Value',1)
        ViewObject_Callback(hObject, eventdata, handles)
    else
        if ishandle(hset_object)
            uistack(hset_object,'top')% show the GUI set_object if opened
        else
            %get the object file
            InputTable=get(handles.InputTable,'Data');
            defaultname=InputTable{1,1};
            if isempty(defaultname)
                defaultname={''};
            end
            fileinput=uigetfile_uvmat('pick a xml object file (or use uvmat to create it)',defaultname,'.xml');
            if isempty(fileinput)% exit if no object file is selected
                set(handles.CheckObject,'Value',0)
                return
            end
            %read the file
            data=xml2struct(fileinput);
            if ~isfield(data,'Type')
                msgbox_uvmat('ERROR',[fileinput ' is not an object xml file'])
                set(handles.CheckObject,'Value',0)
                return
            end
            if ~isfield(data,'ProjMode')
                data.ProjMode='none';
            end
            hset_object=set_object(data);% call the set_object interface
            set(hset_object,'Name','set_object_series')% name to distinguish from set_object used with uvmat
        end
        ProjObject=read_GUI(hset_object);
        set(handles.ProjObject,'String',ProjObject.Name);%display the object name
        SeriesData=get(handles.series,'UserData');
        SeriesData.ProjObject=ProjObject;
        set(handles.series,'UserData',SeriesData);
    end
    set(handles.EditObject,'Visible','on');
    set(handles.DeleteObject,'Visible','on');
    set(handles.ViewObject,'Visible','on');
    set(handles.ProjObject,'Visible','on');
else
    set(handles.EditObject,'Visible','off');
    set(handles.DeleteObject,'Visible','off');
    set(handles.ViewObject,'Visible','off');
    if ~ishandle(hset_object)
        set(handles.ViewObject,'Value',0);
    end
    set(handles.ProjObject,'Visible','off');
end

%------------------------------------------------------------------------
% --- Executes on button press in ViewObject.
%------------------------------------------------------------------------
function ViewObject_Callback(hObject, eventdata, handles)

UserData=get(handles.series,'UserData');
hset_object=findobj(allchild(0),'Tag','set_object');
if ~isempty(hset_object)
    delete(hset_object)% refresh set_object if already opened
end
hset_object=set_object(UserData.ProjObject);
set(hset_object,'Name','view_object_series')


%------------------------------------------------------------------------
% --- Executes on button press in EditObject.
function EditObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if get(handles.EditObject,'Value')
    set(handles.ViewObject,'Value',0)
	UserData=get(handles.series,'UserData');
    hset_object=set_object(UserData.ProjObject);
    set(hset_object,'Name','edit_object_series')
    set(get(hset_object,'Children'),'Enable','on')
else
    hset_object=findobj(allchild(0),'Tag','set_object'); 
    if ~isempty(hset_object)
        set(get(hset_object,'Children'),'Enable','off')
    end 
end

%------------------------------------------------------------------------
% --- Executes on button press in DeleteObject.
function DeleteObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
SeriesData=get(handles.series,'UserData');
SeriesData.ProjObject=[];
set(handles.series,'UserData',SeriesData)
set(handles.ProjObject,'String','')
set(handles.ProjObject,'Visible','off')
set(handles.CheckObject,'Value',0)
set(handles.ViewObject,'Visible','off')
set(handles.EditObject,'Visible','off')
hset_object=findobj(allchild(0),'name','set_object_series');
if ~isempty(hset_object)
    delete(hset_object)
end
set(handles.DeleteObject,'Visible','off')

%------------------------------------------------------------------------
% --- Executed when CheckMask is activated
%------------------------------------------------------------------------
function CheckMask_Callback(hObject, eventdata, handles)

if get(handles.CheckMask,'Value')
    InputTable=get(handles.InputTable,'Data');
    nbview=size(InputTable,1);
    MaskTable=cell(nbview,1);%default
    ListMask=cell(nbview,1);%default
    MaskData=get(handles.MaskTable,'Data');
    MaskData(size(MaskData,1):nbview,1)=cell(size(MaskData,1):nbview,1);%complement if undefined lines
    for iview=1:nbview
        ListMask{iview,1}=num2str(iview);
        RootPath=InputTable{iview,1};
        if ~isempty(RootPath)
            if isempty(MaskData{iview})
                SubDir=InputTable{iview,2};
                MaskPath=fullfile(RootPath,[regexprep(SubDir,'\..*','') '.mask']);%take the root part of SubDir, before the first dot '.'
                if exist(MaskPath,'dir')
                    ListStruct=dir(MaskPath);%look for a mask file
                    ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
                    check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
                    ListFiles=ListCells(1,:);%list of file and dri names
                    ListFiles=ListFiles(~check_dir);%list of file names (excluding dir)
                    mdetect=0;
                    if ~isempty(ListFiles)
                        for ifile=1:numel(ListFiles)
                            [tild,tild,MaskFile{ifile},i1_series,i2_series,j1_series,j2_series,MaskNomType,MaskFileType]=find_file_series(MaskPath,ListFiles{ifile},0);
                            if strcmp(MaskFileType,'image') && isempty(i2_series) && isempty(j2_series)
                                mdetect=1;
                                MaskName=ListFiles{ifile};
                            end
                            if ~strcmp(MaskFile{ifile},MaskFile{1})
                                mdetect=0;% cancel detection test in case of multiple masks, use the brower for selection
                                break
                            end
                        end
                    end
                    if mdetect==1
                        MaskName=fullfile(MaskPath,'mask_1.png');
                    else
                        MaskName=uigetfile_uvmat('select a mask file:',MaskPath,'image');
                    end
                else
                    MaskName=uigetfile_uvmat('select a mask file:',RootPath,'image');
                end
                MaskTable{iview,1}=MaskName ;
                ListMask{iview,1}=num2str(iview);
            end
        end
    end
    set(handles.MaskTable,'Data',MaskTable)
    set(handles.MaskTable,'Visible','on')
    set(handles.MaskBrowse,'Visible','on')
    set(handles.ListMask,'Visible','on')
    set(handles.ListMask,'String',ListMask)
    set(handles.ListMask,'Value',1)
else
    set(handles.MaskTable,'Visible','off')
    set(handles.MaskBrowse,'Visible','off')
    set(handles.ListMask,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on button press in MaskBrowse.
%------------------------------------------------------------------------
function MaskBrowse_Callback(hObject, eventdata, handles)

InputTable=get(handles.InputTable,'Data');
iview=get(handles.ListMask,'Value');
RootPath=InputTable{iview,1};
MaskName=uigetfile_uvmat('select a mask file:',RootPath,'image');
if ~isempty(MaskName)
    MaskTable=get(handles.MaskTable,'Data');
    MaskTable{iview,1}=MaskName ;
    set(handles.MaskTable,'Data',MaskTable)
end

%------------------------------------------------------------------------
% --- Executes when selected cell(s) is changed in MaskTable.
%------------------------------------------------------------------------
function MaskTable_CellSelectionCallback(hObject, eventdata, handles)

if numel(eventdata.Indices)>=1
set(handles.ListMask,'Value',eventdata.Indices(1))
end

%-------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------


% path_to_uvmat=which ('uvmat');% check the path of uvmat
% pathelp=fileparts(path_to_uvmat);
% helpfile=fullfile(pathelp,'uvmat_doc','uvmat_doc.html');
% if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
% else
%     addpath (fullfile(pathelp,'uvmat_doc'))
%     web([helpfile '#series'])
% end

%-------------------------------------------------------------------
% --- Executes on selection change in TransformName.
function TransformName_Callback(hObject, eventdata, handles)
%----------------------------------------------------------------------
TransformList=get(handles.TransformName,'String');
TransformIndex=get(handles.TransformName,'Value');
TransformName=TransformList{TransformIndex};
TransformPathList=get(handles.TransformName,'UserData');
nb_builtin_transform=4;
if isequal(TransformName,'more...');     
    FileName=uigetfile_uvmat('Pick a transform function',get(handles.TransformPath,'String'),'.m');
    if isempty(FileName)
        return     %browser closed without choice
    end
    [TransformPath,TransformName,TransformExt]=fileparts(FileName);% removes extension .m
    if ~strcmp(TransformExt,'.m')
        msgbox_uvmat('ERROR','a Matlab function .m must be introduced');
        return
    end
     % insert the choice in the menu
    TransformIndex=find(strcmp(TransformName,TransformList),1);% look for the selected function in the menu Action
    if isempty(TransformIndex)%the input string does not exist in the menu
        TransformIndex= length(TransformList);
        TransformList=[TransformList(1:end-1);{TransformName};TransformList(end)];% the selected function is appended in the menu, before the last item 'more...'
        set(handles.TransformName,'String',TransformList)
        TransformPathList=[TransformPathList;{TransformPath}];
    else% the input function already exist, we update its path (possibly new)
        TransformPathList{TransformIndex}=TransformPath;% 
        set(handles.TransformName,'Value',TransformIndex)
    end
   % save the new menu in the personal file 'uvmat_perso.mat' 
   dir_perso=prefdir;%personal Matalb directory
   profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
   if exist(profil_perso,'file')
       for ilist=nb_builtin_transform+1:numel(TransformPathList)
           TransformListUser{ilist-nb_builtin_transform}=TransformList{ilist};
           TransformPathListUser{ilist-nb_builtin_transform}=TransformPathList{ilist};
       end 
       TransformPathListUser=TransformPathListUser';
       TransformListUser=TransformListUser';
       save (profil_perso,'TransformPathListUser','TransformListUser','-append'); %store the root name for future opening of uvmat
   end 
end

%display the current function path
set(handles.TransformPath,'String',TransformPathList{TransformIndex}); %show the path to the senlected function
set(handles.TransformName,'UserData',TransformPathList);

%% create the function handle of the selected fct
if ~isempty(TransformName)
    current_dir=pwd;%current working dir
    cd(TransformPathList{TransformIndex})
    transform_handle=str2func(TransformName);
    cd(current_dir)
    Field.Action.RUN=0;% indicate that the transform fct is called only to get input param
    DataOut=feval(transform_handle,Field,[]);% execute the transform fct to get the required conditions
    if isfield(DataOut,'TransformInput')%  used to add transform parameters at selection of the transform fct
        SeriesData=get(handles.series,'UserData');
        SeriesData.TransformInput=DataOut.TransformInput;
        set(handles.series,'UserData',SeriesData)
    end
end

%------------------------------------------------------------------------
% --- fct activated by the upper bar menu ExportConfig
%------------------------------------------------------------------------
function MenuDisplayConfig_Callback(hObject, eventdata, handles)

global Param
Param=read_GUI_series(handles);
evalin('base','global Param')%make CurData global in the workspace
display('current series config :')
evalin('base','Param') %display CurData in the workspace
commandwindow; %brings the Matlab command window to the front

%------------------------------------------------------------------------
% --- fct activated by the upper bar menu InportConfig: import
%     menu settings from an xml file (stored in /0_XML for each run)
%------------------------------------------------------------------------
function MenuImportConfig_Callback(hObject, eventdata, handles)

%% use a browser to choose the xml file containing the processing config
InputTable=get(handles.InputTable,'Data');
oldfile=InputTable{1,1};%current path in InputTable
if isempty(oldfile)
    % use a file name stored in prefdir
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        h=load (profil_perso);
        if isfield(h,'RootPath') && ischar(h.RootPath)
            oldfile=h.RootPath;
        end
    end
end
filexml=uigetfile_uvmat('pick a xml parameter file',oldfile,'.xml');% get the xml file containing processing parameters
if isempty(filexml), return, end % quit function if an xml file has not been opened

%% fill the GUI series with the content of the xml file
Param=xml2struct(filexml);% read the input xml file as a Matlab structure

% ask to stop current Action if button RUN is in action (another process is already running)
if isequal(get(handles.RUN,'Value'),1)
    answer= msgbox_uvmat('INPUT_Y-N','stop current Action process?');
    if strcmp(answer,'Yes')
        STOP_Callback(hObject, eventdata, handles)
    else
        return
    end
end
Param.Action.RUN=0; %desactivate the input RUN=1

fill_GUI(Param,handles.series)% fill the elements of the GUI series with the input parameters
SeriesData=get(handles.series,'UserData');
if isfield(Param,'InputFields')
    ListField=Param.InputFields.FieldName;
    if ischar(ListField),ListField={ListField}; end
    set(handles.FieldName,'String',[ListField;{'get-field...'}])
     set(handles.FieldName,'Value',1:numel(ListField))
     set(handles.FieldName,'Visible','on')
end       
if isfield(Param,'ActionInput')%  introduce  parameters specific to an Action fct, for instance PIV parameters
    set(handles.ActionInput,'Visible','on')
    set(handles.ActionInput,'Value',0)
    Param.ActionInput.ConfigSource=filexml;% record the source of config for future info
    SeriesData.ActionInput=Param.ActionInput;
end
if isfield(Param,'TransformInput')%  introduce  parameters specific to a transform fct
    SeriesData.TransformInput=Param.TransformInput;
end
if isfield(Param,'ProjObject') %introduce projection object if relevant
    SeriesData.ProjObject=Param.ProjObject;
end
set(handles.series,'UserData',SeriesData)
if isfield(Param,'CheckObject') && isequal(Param.CheckObject,1)
    set(handles.ProjObject,'String',Param.ProjObject.Name)
    set(handles.ViewObject,'Visible','on')
    set(handles.EditObject,'Visible','on')
    set(handles.DeleteObject,'Visible','on')
else     
    set(handles.ProjObject,'String','')
    set(handles.ProjObject,'Visible','off')
    set(handles.ViewObject,'Visible','off')
    set(handles.EditObject,'Visible','off')
    set(handles.DeleteObject,'Visible','off')     
end     
set(handles.REFRESH,'BackgroundColor',[1 0 1]); %paint REFRESH button in magenta to indicate that it should be activated


%------------------------------------------------------------------------
% --- Executes when the GUI series is resized.
%------------------------------------------------------------------------
function series_ResizeFcn(hObject, eventdata, handles)

%% input table
set(handles.InputTable,'Unit','pixel')
Pos=get(handles.InputTable,'Position');
set(handles.InputTable,'Unit','normalized')
ColumnWidth=round([0.5 0.14 0.14 0.14 0.08]*(Pos(3)-52));
ColumnWidth=num2cell(ColumnWidth);
set(handles.InputTable,'ColumnWidth',ColumnWidth)

%% MinIndex_j and MaxIndex_i
unit=get(handles.MinIndex_i,'Unit');
set(handles.MinIndex_i,'Unit','pixel')
Pos=get(handles.MinIndex_i,'Position');
set(handles.MinIndex_i,'Unit',unit)
set(handles.MinIndex_i,'ColumnWidth',{Pos(3)-18})
set(handles.MaxIndex_i,'ColumnWidth',{Pos(3)-18})
set(handles.MinIndex_j,'ColumnWidth',{Pos(3)-18})
set(handles.MaxIndex_j,'ColumnWidth',{Pos(3)-18})

%% TimeTable
set(handles.TimeTable,'Unit','pixel')
Pos=get(handles.TimeTable,'Position');
set(handles.TimeTable,'Unit','normalized')
% ColumnWidth=get(handles.TimeTable,'ColumnWidth');
ColumnWidth=num2cell(floor([0.2 0.2 0.2 0.2 0.2]*(Pos(3)-20)));
set(handles.TimeTable,'ColumnWidth',ColumnWidth)


%% PairString
set(handles.PairString,'Unit','pixel')
Pos=get(handles.PairString,'Position');
set(handles.PairString,'Unit','normalized')
set(handles.PairString,'ColumnWidth',{Pos(3)-5})

%% MaskTable
set(handles.MaskTable,'Unit','pixel')
Pos=get(handles.MaskTable,'Position');
set(handles.MaskTable,'Unit','normalized')
set(handles.MaskTable,'ColumnWidth',{Pos(3)-5})

%------------------------------------------------------------------------
% --- Executes on button press in status.
%------------------------------------------------------------------------
function status_Callback(hObject, eventdata, handles)

if get(handles.status,'Value')
    set(handles.status,'BackgroundColor',[1 1 0])
    drawnow
    Param=read_GUI(handles.series);
    RootPath=Param.InputTable{1,1};
    if ~isfield(Param,'OutputSubDir')   
        msgbox_uvmat('ERROR','no standard sub-directory definition for output files, use a browser to check the output')
        set(handles.status,'BackgroundColor',[0 1 0])
        return
    end
    OutputSubDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files
    OutputDir=fullfile(RootPath,OutputSubDir);
    if exist(OutputDir,'dir')
        uigetfile_uvmat('status_display',OutputDir)
    else
        msgbox_uvmat('ERROR','output folder not created yet: calculation did not start')
        set(handles.status,'BackgroundColor',[0 1 0])
    end
else
    %% delete current display fig if selection is off
    set(handles.status,'BackgroundColor',[0 1 0])
    hfig=findobj(allchild(0),'name','status_display');
    if ~isempty(hfig)
        delete(hfig)
    end
    return
end


%------------------------------------------------------------------------   
% launched by selecting a file on the list
%------------------------------------------------------------------------
function view_file(hObject, eventdata)

list=get(hObject,'String');
index=get(hObject,'Value');
rootroot=get(hObject,'UserData');
selectname=list{index};
ind_dot=regexp(selectname,'\.\.\.');
if ~isempty(ind_dot)
    selectname=selectname(1:ind_dot-1);
end
FullSelectName=fullfile(rootroot,selectname);
if exist(FullSelectName,'dir')% a directory has been selected
    ListFiles=dir(FullSelectName);
    ListDisplay=cell(numel(ListFiles),1);
    for ilist=2:numel(ListDisplay)% suppress the first line '.'
        ListDisplay{ilist-1}=ListFiles(ilist).name;
    end
    set(hObject,'Value',1)
    set(hObject,'String',ListDisplay)
    if strcmp(selectname,'..')
        FullSelectName=fileparts(fileparts(FullSelectName));
    end
    set(hObject,'UserData',FullSelectName)
    hfig=get(hObject,'parent');
    htitlebox=findobj(hfig,'tag','titlebox');    
    set(htitlebox,'String',FullSelectName)
elseif exist(FullSelectName,'file')%visualise the vel field if it exists
    FileInfo=get_file_info(FullSelectName);    
    if strcmp(FileInfo.FileType,'txt')
        edit(FullSelectName)
    elseif strcmp(FileInfo.FileType,'xml')
        editxml(FullSelectName)
    else
        uvmat(FullSelectName)
    end
    set(gcbo,'Value',1)
end


%------------------------------------------------------------------------   
% launched by refreshing the status figure
%------------------------------------------------------------------------
function refresh_GUI(hfig)

htitlebox=findobj(hfig,'tag','titlebox');
hlist=findobj(hfig,'tag','list');
hseries=findobj(allchild(0),'tag','series');
hstatus=findobj(hseries,'tag','status');
StatusData=get(hstatus,'UserData');
OutputDir=get(htitlebox,'String');
if ischar(OutputDir),OutputDir={OutputDir};end
ListFiles=dir(OutputDir{1});
if numel(ListFiles)<1
    return
end
ListFiles(1)=[];%removes the first line ='.'
ListDisplay=cell(numel(ListFiles),1);
testrecent=0;
datnum=zeros(numel(ListDisplay),1);
for ilist=1:numel(ListDisplay)
    ListDisplay{ilist}=ListFiles(ilist).name;
      if ~ListFiles(ilist).isdir && isfield(ListFiles(ilist),'datenum')
            datnum(ilist)=ListFiles(ilist).datenum;%only available in recent matlab versions
            testrecent=1;
       end
end
set(hlist,'String',ListDisplay)

%% Look at date of creation
ListDisplay=ListDisplay(datnum~=0);
datnum=datnum(datnum~=0);%keep the non zero values corresponding to existing files
NbOutputFile=[];
if isempty(datnum)
    if testrecent
        message='no civ result created yet';
    else
        message='';
    end
else
    [first,indfirst]=min(datnum);
    [last,indlast]=max(datnum);
    NbOutputFile_str='?';
    NbOutputFile=[];
    if isfield(StatusData,'NbOutputFile')
        NbOutputFile=StatusData.NbOutputFile;
        NbOutputFile_str=num2str(NbOutputFile);
    end
    message={[num2str(numel(datnum)) ' file(s) done over ' NbOutputFile_str] ;['oldest modification:  ' ListDisplay{indfirst} ' : ' datestr(first)];...
        ['latest modification:  ' ListDisplay{indlast} ' : ' datestr(last)]};
end
set(htitlebox,'String', [OutputDir{1};message])

%% update the waitbar
hwaitbar=findobj(hfig,'tag','waitbar');
if ~isempty(NbOutputFile) 
    BarPosition=get(hwaitbar,'Position');
    BarPosition(3)=0.9*numel(datnum)/NbOutputFile;
    set(hwaitbar,'Position',BarPosition)
end

%------------------------------------------------------------------------ 
% --- Executes on selection change in ActionExt.
%------------------------------------------------------------------------ 
function ActionExt_Callback(hObject, eventdata, handles)

ActionExtList=get(handles.ActionExt,'String');
ActionExt=ActionExtList{get(handles.ActionExt,'Value')};
if strcmp(ActionExt,'.py (in dev.)')
    set(handles.RunMode,'Value',2)
end

function num_NbProcess_Callback(hObject, eventdata, handles)


function num_NbSlice_Callback(hObject, eventdata, handles)
NbSlice=str2num(get(handles.num_NbSlice,'String'));
set(handles.num_NbProcess,'String',num2str(NbSlice))

%------------------------------------------------------------------------
% --- set the visibility of relevant velocity type menus: 
function menu=set_veltype_display(Civ,FileType)
%------------------------------------------------------------------------
if ~exist('FileType','var')
    FileType='civx';
end
switch FileType
    case 'civx'
        menu={'civ1';'interp1';'filter1';'civ2';'interp2';'filter2'};
        if isequal(Civ,0)
            imax=0;
        elseif isequal(Civ,1) || isequal(Civ,2)
            imax=1;
        elseif isequal(Civ,3)
            imax=3;
        elseif isequal(Civ,4) || isequal(Civ,5)
            imax=4;
        elseif isequal(Civ,6) %patch2
            imax=6;
        end
    case 'civdata'
        menu={'civ1';'filter1';'civ2';'filter2'};
        if isequal(Civ,0)
            imax=0;
        elseif isequal(Civ,1) || isequal(Civ,2)
            imax=1;
        elseif isequal(Civ,3)
            imax=2;
        elseif isequal(Civ,4) || isequal(Civ,5)
            imax=3;
        elseif isequal(Civ,6) %patch2
            imax=4;
        end
end
menu=menu(1:imax);


% --- Executes on mouse motion over figure - except title and menu.
function series_WindowButtonMotionFcn(hObject, eventdata, handles)
set(hObject,'Pointer','arrow');


% --- Executes on button press in SetPairs.
function SetPairs_Callback(hObject, iview, handles)

%% delete previous occurrence of 'set_pairs'
hfig=findobj(allchild(0),'Tag','set_pairs');
if ~isempty(hfig)
delete(hfig)
end

%% create the GUI set_pairs
set(0,'Unit','points')
ScreenSize=get(0,'ScreenSize');% get the size of the screen, to put the fig on the upper right
Width=220;% fig width in points (1/72 inch)
Height=min(0.8*ScreenSize(4),300);
Left=ScreenSize(3)- Width-40; %right edge close to the right, with margin=40
Bottom=ScreenSize(4)-Height-40; %put fig at top right
hfig=findobj(allchild(0),'Tag','set_slice');
if ~isempty(hfig),delete(hfig), end; %delete existing version of the GUI 
hfig=figure('name','set_pairs','tag','set_pairs','MenuBar','none','NumberTitle','off','Unit','points','Position',[Left,Bottom,Width,Height]);
BackgroundColor=get(hfig,'Color');
SeriesData=get(handles.series,'UserData');
TimeUnit=get(handles.TimeUnit,'String');
PairString=get(handles.PairString,'Data');
ListViewLines=find(cellfun('isempty',PairString)==0);%find list of non empty pairs
ListViewMenu=cell(numel(ListViewLines),1);
for ilist=1:numel(ListViewLines)
    ListViewMenu{ilist}=num2str(ListViewLines(ilist));
end
if isempty(iview)
    ListViewValue=numel(ListViewLines);% we work by default on the pair option for the last line which requires pairs
    iview=ListViewLines(end);
else
    ListViewValue=find(ListViewLines==iview);
end
ref_i=str2num(get(handles.num_first_i,'String'));
ref_j=1;%default
if strcmp(get(handles.num_first_j,'String'),'Visible')
    ref_j=str2num(get(handles.num_first_j,'String'));
end
[ModeMenu,ModeValue]=update_mode(SeriesData.i1_series{iview},SeriesData.i2_series{iview},SeriesData.j2_series{iview});
displ_pair=update_listpair(SeriesData.i1_series{iview},SeriesData.i2_series{iview},SeriesData.j1_series{iview},SeriesData.j2_series{iview},ModeMenu{ModeValue},...
                                                     SeriesData.Time{iview},TimeUnit,ref_i,ref_j,SeriesData.FileInfo{iview});
% first raw of the GUI
uicontrol('Style','text','Units','normalized', 'Position', [0.05 0.88 0.5 0.1],'BackgroundColor',BackgroundColor,...
    'String','row to edit #','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','right');%title
uicontrol('Style','popupmenu','Units','normalized', 'Position', [0.54 0.8 0.3 0.2],'BackgroundColor',[1 1 1],...
    'Callback',@(hObject,eventdata)ListView_Callback(hObject,eventdata),'String',ListViewMenu,'Value',ListViewValue,'FontUnits','points','FontSize',12,'FontWeight','bold',...
    'Tag','ListView','TooltipString','''ListView'':choice of the file series w for pair display');
% second raw of the GUI
uicontrol('Style','text','Units','normalized', 'Position', [0.05 0.79 0.7 0.1],'BackgroundColor',BackgroundColor,...
    'String','mode of index pairing:','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','left');%title
uicontrol('Style','popupmenu','Units','normalized', 'Position', [0.05 0.62 0.9 0.2],'BackgroundColor',[1 1 1],...
    'Callback',@(hObject,eventdata)Mode_Callback(hObject,eventdata),'String',ModeMenu,'Value',ModeValue,'FontUnits','points','FontSize',12,'FontWeight','bold',...
    'Tag','Mode','TooltipString','''Mode'': choice of the image pair mode');
% third raw
uicontrol('Style','text','Units','normalized', 'Position', [0.05 0.6 0.7 0.1],'BackgroundColor',BackgroundColor,...
    'String','pair choice:','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','left');%title
uicontrol('Style','listbox','Units','normalized', 'Position', [0.05 0.42 0.9 0.2],'BackgroundColor',[1 1 1],...
    'Callback',@(hObject,eventdata)ListPair_Callback(hObject,eventdata),'String',displ_pair,'Value',1,'FontUnits','points','FontSize',12,'FontWeight','bold',...
    'Tag','ListPair','TooltipString','''ListPair'': menu for selecting the image pair');
uicontrol('Style','text','Units','normalized', 'Position', [0.1 0.22 0.8 0.1],'BackgroundColor',BackgroundColor,...
    'String','ref_i           ref_j','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','edit','Units','normalized', 'Position', [0.15 0.17 0.3 0.08],'BackgroundColor',[1 1 1],...
    'Callback',@(hObject,eventdata)num_ref_i_Callback(hObject,eventdata),'String',num2str(ref_i),'FontUnits','points','FontSize',12,'FontWeight','bold',...
    'Tag','num_ref_i','TooltipString','''num_ref_i'': reference field index i used to display dt in ''list_pair_civ''');
uicontrol('Style','edit','Units','normalized', 'Position', [0.55 0.17 0.3 0.08],'BackgroundColor',[1 1 1],...
    'Callback',@(hObject,eventdata)num_ref_j_Callback(hObject,eventdata),'String',num2str(ref_j),'FontUnits','points','FontSize',12,'FontWeight','bold',...
    'Tag','num_ref_j','TooltipString','''num_ref_j'': reference field index i used to display dt in ''list_pair_civ''');
uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.01 0.01 0.3 0.12],'BackgroundColor',[0 1 0],...
    'Callback',@(hObject,eventdata)OK_Callback(hObject,eventdata),'String','OK','FontUnits','points','FontSize',12,'FontWeight','bold',...
    'Tag','OK','TooltipString','''OK'': validate the choice');
%  last raw  of the GUI: pushbuttons
% uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.35 0.01 0.3 0.15],'BackgroundColor',[0 1 0],'String','OK','Callback',@(hObject,eventdata)OK_Callback(hObject,eventdata),...
%     'FontWeight','bold','FontUnits','points','FontSize',12,'TooltipString','''OK'': apply the output to the current field series in uvmat');
drawnow

%------------------------------------------------------------------------
function ListView_Callback(hObject,eventdata)
Mode_Callback(hObject,eventdata)

%------------------------------------------------------------------------    
function Mode_Callback(hObject,eventdata)
%% get input info
hseries=findobj(allchild(0),'tag','series');%handles of the GUI series
hhseries=guidata(hseries);%handles of the elements in the GUI series
TimeUnit=get(hhseries.TimeUnit,'String');
SeriesData=get(hseries,'UserData');
mode_list=get(hObject,'String');
mode=mode_list{get(hObject,'Value')};
hListView=findobj(get(hObject,'parent'),'Tag','ListView');
iview=get(hListView,'Value');
i1_series=SeriesData.i1_series{iview};
i2_series=SeriesData.i2_series{iview};
j1_series=SeriesData.j1_series{iview};
j2_series=SeriesData.j2_series{iview};

%% enable j index visibility after the new choice
status_j='on';%default
if isempty(find(~cellfun(@isempty,SeriesData.j1_series), 1)); % case of empty j indices
    status_j='off'; % no j index needed
elseif strcmp(get(handles.PairString,'Visible'),'on')
    check_burst=cellfun(@isempty,regexp(PairString,'^j'));%=0 for burst case, 1 otherwise
    if isempty(find(check_burst, 1))% if all pair string begins by j (burst)
        status_j='off'; % no j index needed for bust case
    end
end
enable_j(handles,status_j) % no j index needed

%% get the reference indices for the time interval Dt
href_i=findobj(get(hObject,'parent'),'Tag','ref_i');
ref_i=[];ref_j=[];
if strcmp(get(href_i,'Visible'),'on')
    ref_i=str2num(get(href_i,'String'));
end
if isempty(ref_i)
    ref_i=1;
end
if isempty(ref_j)
    ref_j=1;
end

%% update the menu ListPair
Menu=update_listpair(i1_series,i2_series,j1_series,j2_series,mode,SeriesData.Time{iview},TimeUnit,ref_i,ref_j,FileInfo);
hlist_pairs=findobj(get(hObject,'parent'),'Tag','ListPair');
set(hlist_pairs,'Value',1)% set the first choice by default in ListPair
set(hlist_pairs,'String',Menu)% set the menu in ListPair
ListPair_Callback(hlist_pairs,[])% apply the default choice in ListPair

%-------------------------------------------------------------
% --- Executes on selection in ListPair.
function ListPair_Callback(hObject,eventdata)
%------------------------------------------------------------
list_pair=get(hObject,'String');%get the menu of image pairs
if isempty(list_pair)
    string='';
else
    string=list_pair{get(hObject,'Value')};
   % string=regexprep(string,',.*','');%removes time indication (after ',')
end
hseries=findobj(allchild(0),'tag','series');
hPairString=findobj(hseries,'tag','PairString');
PairString=get(hPairString,'Data');
hListView=findobj(get(hObject,'parent'),'Tag','ListView');
iview=get(hListView,'Value');
PairString{iview,1}=string;
% report the selected pair string to the table PairString
set(hPairString,'Data',PairString)


%------------------------------------------------------------------------
function num_ref_i_Callback(hObject, eventdata)
%------------------------------------------------------------------------
Mode_Callback([],[])

%------------------------------------------------------------------------
function num_ref_j_Callback(hObject, eventdata)
%------------------------------------------------------------------------
Mode_Callback([],[])

%------------------------------------------------------------------------
function OK_Callback(hObject, eventdata)
%------------------------------------------------------------------------
delete(get(hObject,'parent'))


%------------------------------------------------------------------------
% --- Executes on button press in ClearLine.
%------------------------------------------------------------------------
function ClearLine_Callback(hObject, eventdata, handles)
InputTable=get(handles.InputTable,'Data');
iline=str2double(get(handles.InputLine,'String'));
if size(InputTable,1)>1
    InputTable(iline,:)=[];% suppress the current line if not the first
    set(handles.InputTable,'Data',InputTable);
end
set(handles.REFRESH,'BackgroundColor',[1 0 1])% set REFRESH button to magenta color to indicate that input refr


% --- Executes on button press in MonitorCluster.
function MonitorCluster_Callback(hObject, eventdata, handles)
web('https://www.legi.grenoble-inp.fr/servload/monika')



function OutputSubDir_Callback(hObject, eventdata, handles)
set(handles.OutputSubDir,'BackgroundColor',[1 1 1])
% hObject    handle to OutputSubDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of OutputSubDir as text
%        str2double(get(hObject,'String')) returns contents of OutputSubDir as a double
