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
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
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
drawnow
set(hObject,'Units','pixels')
set(handles.PairString,'ColumnName',{'pairs'})
set(handles.PairString,'ColumnEditable',false)
set(handles.PairString,'ColumnFormat',{'char'})
set(handles.PairString,'Data',{''})
series_ResizeFcn(hObject, eventdata, handles)%resize table according to series GUI size
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%allows mouse action with right button (zoom for uicontrol display)
% check default input data
if ~exist('Param','var')
    Param=[]; %default
end

%% default list of functions in the mebu ActionName
ActionList={'check_data_files';'aver_stat';'time_series';'merge_proj'};% WARNING: fits with nb_builtin_ACTION=4 in ActionName_callback
[path_series,name,ext]=fileparts(which('series'));% path to the GUI series
path_series_fct=fullfile(path_series,'series');%path of the functions in subdirectroy 'series'
%path_bin=fullfile(path_series,'bin');%path of the binary functions (compiled)
ActionPathList=regexprep(ActionList,'^.+$',path_series_fct);% set path=path_series to each function in the list ('^.+$'=any non empty nbre of char form beginning to end of char string)
ActionPathList=[ActionPathList ActionPathList];% set path to .sh commands for compiled functions
ActionExtList={'.m';'.sh'};% default choice of extensions (Matlab fct .m or compiled version .sh)
RunModeList={'local';'background'};% default choice of extensions (Matlab fct .m or compiled version .sh)
[s,w]=system('oarstat');% look for cluster system 'oar'
if isequal(s,0)
    RunModeList=[RunModeList;{'cluster_oar'}];
end
[s,w]=system('qstat');% look for cluster system 'sge'
if isequal(s,0)
    RunModeList=[RunModeList;{'cluster_sge'}];
end
set(handles.RunMode,'String',RunModeList)

%% default list of functions in the mebu TransformName
TransformList={'';'sub_field';'phys';'phys_polar'};% WARNING: must fit with the corresponding menu in uvmat and nb_builtin_transform=4 in  TransformName_callback
path_transform_fct=fullfile(path_series,'transform_field');
TransformPathList=regexprep(TransformList,'^.+$',path_transform_fct);% set path=path_transform_fct to each function in the list ('^.+$'=any non empty nbre of char form beginning to end of char string)

%% load the personal file uvmat_perso.mat 
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    h=load (profil_perso);
    %get the list of previous input files in the upper bar menu Open
    if isfield(h,'MenuFile')
        for ifile=1:min(length(h.MenuFile),5)
            eval(['set(handles.MenuFile_' num2str(ifile) ',''Label'',h.MenuFile{ifile});'])
        end
    end
    %get the menu of actions
    if isfield(h,'ActionExtListUser') && iscell(h.ActionExtListUser)
        ActionExtList=[ActionExtList; h.ActionExtListUser];
    end 
    if isfield(h,'ActionListUser') && iscell(h.ActionListUser) && isfield(h,'ActionPathListUser') && iscell(h.ActionPathListUser)
        ActionList=[ActionList;h.ActionListUser];
        ActionPathList=[ActionPathList;h.ActionPathListUser];
    end
    %get the menu of transform fct
    if isfield(h,'TransformListUser') && iscell(h.TransformListUser) && isfield(h,'TransformPathListUser') && iscell(h.TransformPathListUser)
        TransformList=[TransformList;h.TransformListUser];
        TransformPathList=[TransformPathList;h.TransformPathListUser];
    end
end

%% selection of the input Action fct
ActionCheckExist=false(size(ActionList));
for ilist=1:numel(ActionList)
    ActionCheckExist(ilist)=exist(fullfile(ActionPathList{ilist},[ActionList{ilist} '.m']),'file');
end
ActionPathList=ActionPathList(ActionCheckExist,:);
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
TransformCheckExist=false(size(TransformList));
TransformCheckExist(1)=1;%the first option is blank: no transform, always allowed
for ilist=2:numel(TransformList)
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
if isfield(Param,'Coord_x_str')&& isfield(Param,'Coord_x_val')
        set(handles.Coord_x,'String',Param.Coord_x_str);% list menu fields
    set(handles.Coord_x,'Value',Param.Coord_x_val);% selected string index
end
if isfield(Param,'Coord_y_str')&& isfield(Param,'Coord_y_val')
        set(handles.Coord_y,'String',Param.Coord_y_str);% list menu fields
    set(handles.Coord_y,'Value',Param.Coord_y_val);% selected string index
end

%% Adjust the GUI according to the binaries available in PARAM.xml
% path_uvmat=fileparts(which('uvmat')); %path to civ
% addpath (path_uvmat) ; %add the path to civ, (useful in case of change of working directory after civ has been s opened in the working directory)
% errormsg=[];%default error message
% xmlfile='PARAM.xml';
% if exist(xmlfile,'file')
%     try
%         t=xmltree(xmlfile);
%         sparam=convert(t);
%     catch ME
%         errormsg={' Unable to read the file PARAM.xml defining the  binaries:';ME.message};
%     end
% else
%     errormsg=[xmlfile ' not found: path to binaries undefined'];
% end
% if ~isempty(errormsg)
%     msgbox_uvmat('WARNING',errormsg);
% end
% test_batch=0;%default: ,no batch mode available
% if isfield(sparam,'BatchParam') && isfield(sparam.BatchParam,'BatchMode')
%     test_batch=strcmp(sparam.BatchParam.BatchMode,'sge'); %sge is currently the only implemented batch mod
% end
% RUNVal=get(handles.RunMode,'Value');
% if test_batch==0
%    if RUNVal>2
%        set(handles.RunMode,'Value',1)
%    end
%    set(handles.RunMode,'String',{'local';'background'})
% else
%     set(handles.RunMode,'String',{'local';'background';'cluster'})
% end

%% introduce the input file name(s) if defined from input Param
if isfield(Param,'FileName')
    InputTable={'','','','',''}; % refresh the file input table
    set(handles.InputTable,'Data',InputTable)
    if isfield(Param,'FileName_1')
        display_file_name(handles,Param.FileName_1,0)
        display_file_name(handles,Param.FileName,1)
    else
        display_file_name(handles,Param.FileName,0)
    end
end  
if isfield(Param,'incr_i')
    set(handles.num_incr_i,'String',num2str(Param.incr_i))
end
if isfield(Param,'incr_j')
    set(handles.num_incr_j,'String',num2str(Param.incr_j))
end


%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = series_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------ 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;

%------------------------------------------------------------------------
%------------------------------------------------------------------------
%  II - FUNCTIONS FOR INTRODUCING THE INPUT FILES
% automatically sets the global properties when the rootfile name is introduced
% then activate the view-field actionname if selected
% it is activated either by clicking on the RootPath window or by the 
% browser 
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function MenuBrowse_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------   
InputTable=get(handles.InputTable,'Data');
if isempty(InputTable)
    RootPathCell={};
else
    RootPathCell=InputTable(:,1);
end
oldfile=''; %default
if isempty(RootPathCell)||isequal(RootPathCell,{''})%loads the previously stored file name and set it as default in the file_input box
     dir_perso=prefdir;
     profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
     if exist(profil_perso,'file')
          h=load (profil_perso);
         if isfield(h,'filebase')&&ischar(h.filebase)
                 oldfile=h.filebase;
         end
         if isfield(h,'RootPath')&&ischar(h.RootPath) 
                 oldfile=h.RootPath;
         end
     end
else
     SubDirCell=InputTable(:,2);
    RootFileCell=InputTable(:,3);
     oldfile=fullfile(RootPathCell{1},SubDirCell{1},RootFileCell{1});
 end
[FileName, PathName] = uigetfile( ...
       {'*.xml;*.xls;*.png;*.tif;*.avi;*.AVI;*.nc', ' (*.xml,*.xls, *.png,*.tif, *.avi,*.nc)';
       '*.xml',  '.xml files '; ...
        '*.xls',  '.xls files '; ...
        '*.png','.png image files'; ...
        '*.tif','.tif image files'; ...
        '*.avi;*.AVI','.avi movie files'; ...
        '*.nc','.netcdf files'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file',oldfile);
fileinput=[PathName FileName];%complete file name 
if isempty(fileinput),return;end %abandon if no file is introduced by the browser
[path,name,ext]=fileparts(fileinput);
if isequal(ext,'.xml')
    [Param,Heading]=xml2struct(fileinput);
    if ~strcmp(Heading,'Series')
        msg_box_uvmat('ERROR','xml file heading is not <Series>')
    else
        fill_GUI(Param,handles.series);%fill the GUI with the parameters retrieved from the xml file
        if isfield(Param,'CheckObject')&& Param.CheckObject
            set_object(Param.ProjObject)
        end
        set(handles.REFRESH,'UserData',1:size(Param.InputTable,1))
        REFRESH_Callback([],[], handles)
        return
    end
elseif isequal(ext,'.xls')
    msg_box_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
else
    display_file_name(handles,fileinput,0)
end

% --------------------------------------------------------------------
function MenuFile_1_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_1,'Label');
display_file_name(handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_2_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_2,'Label');
display_file_name(handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_3_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_3,'Label');
display_file_name( handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_4_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_4,'Label');
display_file_name(handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_5_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_5,'Label');
display_file_name(handles,fileinput,0)

% --------------------------------------------------------------------
function MenuBrowse_insert_Callback(hObject, eventdata, handles)
InputTable=get(handles.InputTable,'Data');
RootPathCell=InputTable(:,1);
SubDirCell=InputTable(:,3);
RootFileCell=InputTable(:,2);
oldfile=''; %default
if isempty(RootPathCell)||isequal(RootPathCell,{''})%loads the previously stored file name and set it as default in the file_input box
     dir_perso=prefdir;
     profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
     if exist(profil_perso,'file')
          h=load (profil_perso);
         if isfield(h,'filebase')&ischar(h.filebase)
                 oldfile=h.filebase;
         end
         if isfield(h,'RootPath')&ischar(h.RootPath) 
                 oldfile=h.RootPath;
         end
     end
 else
     oldfile=fullfile(RootPathCell{1},RootFileCell{1});
 end
[FileName, PathName, filterindex] = uigetfile( ...
       {'*.xml;*.xls;*.png;*.avi;*.AVI;*.nc', ' (*.xml,*.xls, *.png, *.avi,*.nc)';
       '*.xml',  '.xml files '; ...
        '*.xls',  '.xls files '; ...
        '*.png','.png image files'; ...
        '*.avi;*.AVI','.avi movie files'; ...
        '*.nc','.netcdf files'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file',oldfile);
fileinput=[PathName FileName];%complete file name 
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
[path,name,ext]=fileparts(fileinput);
if isequal(ext,'.xml')
    msgbox_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
elseif isequal(ext,'.xls')
    msgbox_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
else
    display_file_name(handles,fileinput,'append')
end

% --------------------------------------------------------------------
function MenuFile_insert_1_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------    
fileinput=get(handles.MenuFile_insert_1,'Label');
display_file_name(handles,fileinput,'append')

% --------------------------------------------------------------------
function MenuFile_insert_2_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------    
fileinput=get(handles.MenuFile_insert_2,'Label');
display_file_name(handles,fileinput,'append')

% --------------------------------------------------------------------
function MenuFile_insert_3_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------   
fileinput=get(handles.MenuFile_insert_3,'Label');
display_file_name( handles,fileinput,'append')

% --------------------------------------------------------------------
function MenuFile_insert_4_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------    
fileinput=get(handles.MenuFile_insert_4,'Label');
display_file_name( handles,fileinput,'append')

% --------------------------------------------------------------------
function MenuFile_insert_5_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------    
fileinput=get(handles.MenuFile_insert_5,'Label');
display_file_name(handles,fileinput,'append')

%------------------------------------------------------------------------
% --- Executes when entered data in editable cell(s) in InputTable.
function InputTable_CellEditCallback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.REFRESH,'Visible','on')
iview=eventdata.Indices(1);
view_set=get(handles.REFRESH,'UserData');
if isempty(find(view_set==iview))
    set(handles.REFRESH,'UserData',[view_set iview])
end
%% enable other menus and uicontrols
set(handles.MenuOpen_insert,'Enable','on')
set(handles.MenuFile_insert_1,'Enable','on')
set(handles.MenuFile_insert_2,'Enable','on')
set(handles.MenuFile_insert_3,'Enable','on')
set(handles.MenuFile_insert_4,'Enable','on')
set(handles.MenuFile_insert_5,'Enable','on')
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])% set RUN button to red 

%update the output dir
% SubDir=sort(InputTable(:,2)); %set of subdirectories sorted in alphabetical order
% SubDirOut=SubDir{1};
% if numel(SubDir)>1
%     for ilist=2:numel(SubDir)
%         SubDirOut=[SubDirOut '-' SubDir{ilist}];
%     end
% end
% set(handles.OutputSubDir,'String',SubDirOut)

%------------------------------------------------------------------------
% --- Executes on button press in REFRESH.
function REFRESH_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
InputTable=get(handles.InputTable,'Data');
view_set=get(handles.REFRESH,'UserData');
set(handles.REFRESH,'BackgroundColor',[0.7 0.7 0.7])% set REFRESH  button to grey color
drawnow
for iview=view_set
    RootPath=fullfile(InputTable{iview,1},InputTable{iview,2});
    if ~exist(RootPath,'dir')
        i1_series=[];
        RootPath=fileparts(RootPath); %will try the upped forldr
    else
        [RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,tild,FileType,FileInfo,MovieObject]=...
            find_file_series(fullfile(InputTable{iview,1},InputTable{iview,2}),[InputTable{iview,3} InputTable{iview,4} InputTable{iview,5}]);
    end
    if isempty(i1_series)
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.xml;*.xls;*.png;*.tif;*.avi;*.AVI;*.nc', ' (*.xml,*.xls, *.png,*.tif, *.avi,*.nc)';
            '*.xml',  '.xml files '; ...
            '*.xls',  '.xls files '; ...
            '*.png','.png image files'; ...
            '*.tif','.tif image files'; ...
            '*.avi;*.AVI','.avi movie files'; ...
            '*.nc','.netcdf files'; ...
            '*.*',  'All Files (*.*)'}, ...
            ['unvalid entry at line ' num2str(iview) ', pick a file'],RootPath);
        fileinput=[PathName FileName];%complete file name
        if isempty(fileinput),return;end %abandon if the operation has been cancelled: no input from browser
        [path,name,ext]=fileparts(fileinput);
        display_file_name(handles,fileinput,iview)
    else
        update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,FileInfo,MovieObject,iview)
    end
end
set(handles.REFRESH,'BackgroundColor',[1 0 0])% set REFRESH  button to grey color
set(handles.REFRESH,'Visible','off')
set(handles.REFRESH,'UserData',[])

%------------------------------------------------------------------------
% --- Function called when a new file is opened, either by series_OpeningFcn or by the browser
function display_file_name(handles,fileinput,iview)
%------------------------------------------------------------------------  
%
% INPUT:
% handles: handles of elements in the GUI
% fielinput: input file name, including path
% append =0 (refresh the Input table with the new file), ='append' append a new line in the table

%% get the input root name, indices, file extension and nomenclature NomType
if ~exist(fileinput,'file')
    msgbox_uvmat('ERROR',['input file ' fileinput  ' does not exist'])
    return
end

%% enable other menus and uicontrols
set(handles.MenuOpen_insert,'Enable','on')
set(handles.MenuFile_insert_1,'Enable','on')
set(handles.MenuFile_insert_2,'Enable','on')
set(handles.MenuFile_insert_3,'Enable','on')
set(handles.MenuFile_insert_4,'Enable','on')
set(handles.MenuFile_insert_5,'Enable','on')
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])% set RUN button to red 
set(handles.InputTable,'BackgroundColor',[1 1 0]) % set RootPath edit box  to yellow
drawnow

%% detect root name, nomenclature and indices in the input file name:
[FilePath,FileName,FileExt]=fileparts(fileinput);
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
% the root name and indices may be corrected by including the first index i1 if a corresponding xml file exists
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,FileInfo,MovieObject,i1,i2,j1,j2]=find_file_series(FilePath,[FileName FileExt]);
if isempty(RootFile)&&isempty(i1_series)
    errormsg='no input file in the series';
    return
end

%% fill the list of file series
InputTable=get(handles.InputTable,'Data');
if strcmp(iview,'append') % display the input data as a new line in the table
     iview=size(InputTable,1);
     InputTable(iview+1,:)={'','','','',''};
     InputTable(iview,:)=[{RootPath},{SubDir},{RootFile},{NomType},{FileExt}];
elseif iview==0 % or re-initialise the list of  input  file series
    iview=1;
    InputTable=[{'','','','',''};{'','','','',''}];
     InputTable(iview,:)=[{RootPath},{SubDir},{RootFile},{NomType},{FileExt}];
    set(handles.TimeTable,'Data',[{[]},{[]},{[]},{[]}]) 
    set(handles.MinIndex,'Data',[{[]},{[]}])
    set(handles.MaxIndex,'Data',[{[]},{[]}])
    set(handles.ListView,'Value',1)
    set(handles.ListView,'String',{'1'})
end
nbview=size(InputTable,1);
set(handles.ListView,'String',mat2cell((1:nbview)',ones(nbview,1)))
set(handles.ListView,'Value',iview)
set(handles.InputTable,'Data',InputTable)

%% determine the selected reference field indices for pair display
if isempty(i1)
    i1=1;
end
if isempty(i2)
    i2=i1;
end
ref_i=floor((i1+i2)/2);% reference image number corresponding to the file
set(handles.num_ref_i,'String',num2str(ref_i));
set(handles.num_ref_i,'UserData',[i1 i2])
if isempty(j1)
    j1=1;
end
if isempty(j2)
    j2=j1;
end
ref_j=floor((j1+j2)/2);% reference image number corresponding to the file
set(handles.num_ref_j,'String',num2str(ref_j)); 
set(handles.num_ref_j,'UserData',[j1 j2])

%% update the list of recent files in the menubar and save it for future opening
MenuFile=[{get(handles.MenuFile_1,'Label')};{get(handles.MenuFile_2,'Label')};...
    {get(handles.MenuFile_3,'Label')};{get(handles.MenuFile_4,'Label')};{get(handles.MenuFile_5,'Label')}];
str_find=strcmp(fileinput,MenuFile);
if isempty(find(str_find,1))
    MenuFile=[{fileinput};MenuFile];%insert the current file if not already in the list
end
for ifile=1:min(length(MenuFile),5)
    eval(['set(handles.MenuFile_' num2str(ifile) ',''Label'',MenuFile{ifile});'])
    eval(['set(handles.MenuFile_insert_' num2str(ifile) ',''Label'',MenuFile{ifile});'])
end
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    save (profil_perso,'MenuFile','-append'); %store the file names for future opening of uvmat
else
    save (profil_perso,'MenuFile','-V6'); %store the file names for future opening of uvmat
end

set(handles.InputTable,'BackgroundColor',[1 1 1])

%% initiate input file series and refresh the current field view:     
update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,FileInfo,MovieObject,iview);

%------------------------------------------------------------------------
% --- Update information about a new field series (indices to scan, timing,
%     calibration from an xml file
function update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,FileInfo,VideoObject,iview)
%------------------------------------------------------------------------
%% update the output dir
InputTable=get(handles.InputTable,'Data');
SubDir=sort(InputTable(1:end-1,2)); %set of subdirectories sorted in alphabetical order
SubDirOut=SubDir{1};
if numel(SubDir)>1
    for ilist=2:numel(SubDir)
        SubDirOut=[SubDirOut '-' SubDir{ilist}];
    end
end
set(handles.OutputSubDir,'String',SubDirOut)

%% display the min and max indices for the file series
if size(i1_series,2)==2 && min(min(i1_series(:,1,:)))==0
    MinIndex_j=1;
    MaxIndex_j=1;
    MinIndex_i=find(i1_series(:,2,:), 1 )-1;
    MaxIndex_i=find(i1_series(:,2,:), 1, 'last' )-1;
else
    pair_max=squeeze(max(i1_series,[],1)); %max on pair index
    j_max=max(pair_max,[],1);
    %i_sum=sum(sum(i1_series,2),1);%sum of i1_series on the last index
    MaxIndex_i=find(j_max, 1, 'last' )-1;% max ref index i
    MinIndex_i=find(j_max, 1 )-1;% min ref index i
    diff_i_max=diff(j_max);
    if isequal (diff_i_max,diff_i_max(1)*ones(size(diff_i_max)))
        set(handles.num_incr_i,'String',num2str(diff_i_max(1)))
    end
    i_max=max(pair_max,[],2);
    MaxIndex_j=max(find(i_max))-1;% max ref index i
    MinIndex_j=min(find(i_max))-1;% min ref index i
    diff_j_max=diff(i_max);
    if isequal (diff_j_max,diff_j_max(1)*ones(size(diff_j_max)))
        set(handles.num_incr_j,'String',num2str(diff_j_max(1)))
    end
end
MinIndex=get(handles.MinIndex,'Data');%retrieve the min indices in the table MinIndex
MaxIndex=get(handles.MaxIndex,'Data');%retrieve the max indices in the table MaxIndex
if isequal(MinIndex_i,-1)
    MinIndex_i=0;
end
if isequal(MinIndex_j,-1)
    MinIndex_j=0;
end
MinIndex{iview,1}=MinIndex_i;
MinIndex{iview,2}=MinIndex_j;
MaxIndex{iview,1}=MaxIndex_i;
MaxIndex{iview,2}=MaxIndex_j;

set(handles.MinIndex,'Data',MinIndex)%display the min indices in the table MinIndex
set(handles.MaxIndex,'Data',MaxIndex)%display the max indices in the table MaxIndex

%% adjust the first and last indices if requested by the bounds
first_i=str2num(get(handles.num_first_i,'String'));
ref_i=str2num(get(handles.num_ref_i,'String'));
ref_j=str2num(get(handles.num_ref_j,'String'));
if isempty(first_i)
    first_i=ref_i;
elseif first_i < MinIndex_i
    first_i=MinIndex_i;
elseif first_i >MaxIndex_i
    first_i=MinIndex_i;
end
first_j=str2num(get(handles.num_first_j,'String'));
if isempty(first_j)
    first_j=ref_j;
elseif first_j<MinIndex_j
    first_j=MinIndex_j;
elseif first_j >MaxIndex_j
    first_j=MinIndex_j;
end
last_i=str2num(get(handles.num_last_i,'String'));
if isempty(last_i)
    last_i=ref_i;
elseif last_i > MaxIndex_i
    last_i=MaxIndex_i;
elseif last_i<first_i
    last_i=first_i;
end
last_j=str2num(get(handles.num_first_j,'String'));
if isempty(last_j)
    last_j=ref_j;
elseif last_j>MaxIndex_j
    last_j=MaxIndex_j;
elseif last_i<first_i
    last_i=first_i;
end
set(handles.num_first_i,'String',num2str(first_i)); 
set(handles.num_first_j,'String',num2str(first_j));
set(handles.num_last_i,'String',num2str(last_i)); 
set(handles.num_last_j,'String',num2str(last_j));

%% read timing and total frame number from the current file (movie files) may be overrid by xml file
InputTable=get(handles.InputTable,'Data');
FileBase=fullfile(InputTable{iview,1},InputTable{iview,3});
time=[];%default
% case of movies
if strcmp(InputTable{iview,4},'*')
    if ~isempty(VideoObject)
        imainfo=get(VideoObject);
        time=(0:1/imainfo.FrameRate:(imainfo.NumberOfFrames-1)/imainfo.FrameRate)';
       % set(handles.Dt_txt,'String',['Dt=' num2str(1000/imainfo.FrameRate) 'ms']);%display the elementary time interval in millisec
        ColorType='truecolor';
    elseif ~isempty(imformats(regexprep(InputTable{iview,5},'^.',''))) || isequal(InputTable{iview,5},'.vol')%&& isequal(NomType,'*')% multi-frame image
        if ~isempty(InputTable{iview,2})
            imainfo=imfinfo(fullfile(InputTable{iview,1},InputTable{iview,2},[InputTable{iview,3} InputTable{iview,5}]));
        else
            imainfo=imfinfo([FileBase InputTable{iview,5}]);
        end
        ColorType=imainfo.ColorType;%='truecolor' for color images
        if length(imainfo) >1 %case of image with multiple frames
            nbfield=length(imainfo);
            nbfield_j=1;
        end
    end
end

%%  read image documentation file  if found%%%%%%%%%%%%%%%%%%%%%%%%%%%
XmlData=[];
NbSlice_calib={};
XmlFileName=find_imadoc(InputTable{iview,1},InputTable{iview,2},InputTable{iview,3},InputTable{iview,5});
TimeUnit='';
if ~isempty(XmlFileName)
        [XmlData,warntext]=imadoc2struct(XmlFileName);
        if isfield(XmlData,'Heading') && isfield(XmlData.Heading,'ImageName') && ischar(XmlData.Heading.ImageName)
            [PP,FF,ext_ima_read]=fileparts(XmlData.Heading.ImageName);
        end
        if isfield(XmlData,'Time')
            time=XmlData.Time;
        end
        if isfield(XmlData,'Camera')
            if isfield(XmlData.Camera,'NbSlice')&& ~isempty(XmlData.Camera.NbSlice)
                NbSlice_calib{iview}=XmlData.Camera.NbSlice;% Nbre of slices for Zindex in phys transform
                if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
                    msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
                end
            end
            if isfield(XmlData.Camera,'TimeUnit')&& ~isempty(XmlData.Camera.TimeUnit)
                TimeUnit=XmlData.Camera.TimeUnit;
            end
        end
        if ~isempty(warntext)
            msgbox_uvmat('WARNING',warntext)
        end  
end

%% update time table
if ~isempty(time)
    TimeTable=get(handles.TimeTable,'Data');
    first_i=str2num(get(handles.num_first_i,'String'));
    last_i=str2num(get(handles.num_last_i,'String'));
    first_j=str2num(get(handles.num_first_j,'String'));
    last_j=str2num(get(handles.num_last_j,'String'));
    MinIndexTable=get(handles.MinIndex,'Data');
    MinIndex_i=MinIndexTable{iview,1};
    MinIndex_j=MinIndexTable{iview,2};
    MaxIndexTable=get(handles.MaxIndex,'Data');
    MaxIndex_i=MaxIndexTable{iview,1};
    MaxIndex_j=MaxIndexTable{iview,2};
    if isempty(MinIndex_j)% only i index
        if MinIndex_i>0
            TimeTable{iview,1}=time(MinIndex_i);
        end
        TimeTable{iview,2}=time(first_i);
        TimeTable{iview,3}=time(last_i);
        TimeTable{iview,4}=time(MaxIndex_i);
    elseif ~isempty(time)
        if MinIndex_i>0
            TimeTable{iview,1}=time(MinIndex_i,MinIndex_j);
        end
        if size(time)>=[last_i last_j]
            TimeTable{iview,2}=time(first_i,first_j);
            TimeTable{iview,3}=time(last_i,last_j);
        end
        if size(time)>=[MaxIndex_i MaxIndex_j];
            TimeTable{iview,4}=time(MaxIndex_i,MaxIndex_j);
        end
    end
    set(handles.TimeTable,'Data',TimeTable)
end

%% number of slices
NbSlice=1;%default
check_calib=0;
if isfield(XmlData,'GeometryCalib') 
    check_calib=1;
    if isfield(XmlData.GeometryCalib,'SliceCoord')
    siz=size(XmlData.GeometryCalib.SliceCoord);
    if siz(1)>1
        NbSlice=siz(1);
    end
    end
end
set(handles.num_NbSlice,'String',num2str(NbSlice))
   
%% update pair menus
set(handles.Pairs,'Visible','on')
set(handles.PairString,'Visible','on')
ListView=get(handles.ListView,'String');
ListView{iview}=num2str(iview);
set(handles.ListView,'String',ListView);
set(handles.ListView,'Value',iview)
update_mode(handles,i1_series,i2_series,j1_series,j2_series,time)

%% update the series info in 'UserData'
SeriesData=get(handles.series,'UserData');
SeriesData.Ref_i{iview}=get(handles.num_ref_i,'UserData');
SeriesData.Ref_j{iview}=get(handles.num_ref_j,'UserData');
SeriesData.i1_series{iview}=i1_series;
SeriesData.i2_series{iview}=i2_series;
SeriesData.j1_series{iview}=j1_series;
SeriesData.j2_series{iview}=j2_series;
SeriesData.FileType{iview}=FileType;
SeriesData.FileInfo{iview}=FileInfo;
SeriesData.Time{iview}=time;
if ~isempty(TimeUnit)
    SeriesData.TimeUnit=TimeUnit;
end
if check_calib
SeriesData.GeometryCalib{iview}=XmlData.GeometryCalib;
end
set(handles.series,'UserData',SeriesData)

%% enable j index visibilitycellfun(@isempty,regexp(PairString,'^j'))
% state='off';
check_jindex=~cellfun(@isempty,SeriesData.j1_series); %look for non empty j indices
if isempty(find(check_jindex))
    enable_j(handles,'off') % no j index needed
else
    PairString=get(handles.PairString,'Data');
    if isempty(find(cellfun(@isempty,regexp(PairString,'^j'))))% if all pair string begins by j (burst)
        enable_j(handles,'off') % no j index needed
    else
        enable_j(handles,'on')
    end
end

%% display the set of existing files as an image
set(handles.FileStatus,'Units','pixels')
Position=get(handles.FileStatus,'Position');
set(handles.FileStatus,'Units','normalized')
xI=0.5:Position(3)-0.5;
nbview=numel(SeriesData.i1_series);
pair_max=cell(1,nbview);
for iview=1:nbview
    pair_max{iview}=squeeze(max(SeriesData.i1_series{iview},[],1)); %max on pair index
    if (strcmp(get(handles.num_first_j,'Visible'),'off')&& size(pair_max{iview},2)~=1)
        pair_max{iview}=squeeze(max(pair_max{iview},[],1)); % consider only the i index
    end
    index_min(iview)=find(pair_max{iview}>0, 1 );
    index_max(iview)=find(pair_max{iview}>0, 1, 'last' );
end
index_min=min(index_min);
index_max=max(index_max);
range_index=index_max-index_min+1;
scale_y=Position(4)/nbview;
scale_x=Position(3)/range_index;
x=(0.5:range_index-0.5)*Position(3)/range_index;
% y=(0.5:nbview-0.5)*Position(4)/nbview;
range_y=max(1,floor(Position(4)/nbview));
CData=zeros(nbview*range_y,Position(3));
for iview=1:nbview
    ind_y=1+(iview-1)*range_y:iview*range_y;
    LineData=zeros(1,range_index);
    x_index=find(pair_max{iview}>0)-index_min+1;
    LineData(x_index)=1;
    if numel(x)>1
    LineData=interp1(x,LineData,xI,'nearest');
    CData(ind_y,:)=ones(size(ind_y'))*LineData;
    end
end
CData=cat(3,zeros(size(CData)),CData,zeros(size(CData)));
set(handles.FileStatus,'CData',CData);


%% enable field and veltype menus, in accordance with the current action
ActionName_Callback([],[], handles)

%% check for pair display
check_pairs=0;
for iview=1:numel(SeriesData.i2_series)
    if ~isempty(SeriesData.i2_series{iview})||~isempty(SeriesData.j2_series{iview})
        check_pairs=1;
    end
end
if check_pairs
    set(handles.Pairs,'Visible','on')
    set(handles.PairString,'Visible','on')
else
    set(handles.Pairs,'Visible','off')
    set(handles.PairString,'Visible','off')
end

%% set length of waitbar
displ_time(handles)


%% set default options in menu 'Fields'
switch FileType
    case {'civx','civdata'}
        [FieldList,ColorList]=set_field_list('U','V','C');
        set(handles.FieldName,'String',[{'image'};FieldList;{'get_field...'}]);%standard menu for civx data
        set(handles.FieldName,'Value',2) % set menu to 'velocity
        set(handles.Coord_x,'Value',1);
        set(handles.Coord_x,'String',{'X'});
        set(handles.Coord_y,'Value',1);
        set(handles.Coord_y,'String',{'Y'});
    case 'netcdf'
        set(handles.FieldName,'Value',1)
        set(handles.FieldName,'String',{'get_field...'})
        if isempty(i2_series)
            i2=[];
        else
            i2=i2_series(1,ref_j+1,ref_i+1);
        end
        if isempty(j1_series)
            j1=[];j2=[];
        else
            j1=j1_series(1,ref_j+1,ref_i+1);
            if isempty(j2_series)
                j2=[];
            else
                j2=j2_series(1,ref_j+1,ref_i+1);
            end
        end
        FileName=fullfile_uvmat(InputTable{iview,1},InputTable{iview,2},InputTable{iview,3},InputTable{iview,5},InputTable{iview,4},i1_series(1,ref_j+1,ref_i+1),i2,j1,j2);
%         hget_field=get_field(FileName);
%         hhget_field=guidata(hget_field);
%         get_field('RUN_Callback',hhget_field.RUN,[],hhget_field);
    otherwise
        set(handles.FieldName,'Value',1) % set menu to 'image'
        set(handles.FieldName,'String',{'image'})
        set(handles.Coord_x,'Value',1);
        set(handles.Coord_x,'String',{'AX'});
        set(handles.Coord_y,'Value',1);
        set(handles.Coord_y,'String',{'AY'});
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
first_j=str2num(get(handles.num_first_j,'String'));
last_j=str2num(get(handles.num_last_j,'String'));
ref_j=ceil((first_j+last_j)/2);
set(handles.num_ref_j,'String', num2str(ref_j))
num_ref_j_Callback(hObject, eventdata, handles)
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
ref_i=[str2num(get(handles.num_first_i,'String')) str2num(get(handles.num_last_i,'String'))];
ref_j=[str2num(get(handles.num_first_j,'String')) str2num(get(handles.num_last_j,'String'))];
TimeTable=get(handles.TimeTable,'Data');
Pairs=get(handles.PairString,'Data');
for iview=1:size(TimeTable,1)
    if size(SeriesData.Time,1)<iview
        break
    end
    i1=ref_i;
    j1=ref_j;
    i2=ref_i;
    j2=ref_j;
    % case of pairs
    if ~isempty(Pairs{iview,1})
        r=regexp(Pairs{iview,1},'(?<mode>(Di=)|(Dj=)) -*(?<num1>\d+)\|(?<num2>\d+)','names');
        if isempty(r)
            r=regexp(Pairs{iview,1},'(?<num1>\d+)(?<mode>-)(?<num2>\d+)','names');
        end
        switch r.mode
            case 'Di='  %  case 'series(Di)')
                i1=ref_i-str2num(r.num1);
                i2=ref_i+str2num(r.num2);
            case 'Dj='  %  case 'series(Dj)'
                j1=ref_j-str2num(r.num1);
                j2=ref_j+str2num(r.num2);
            case '-'  % case 'bursts'
                j1=str2num(r.num1)*ones(size(ref_i));
                j2=str2num(r.num2)*ones(size(ref_i));
        end
    end
    TimeTable{iview,2}=[];
    TimeTable{iview,3}=[];
    if size(SeriesData.Time{iview},1)>=i2(2)&&size(SeriesData.Time{iview},1)>=j2(2)
        if isempty(ref_j)
            time_first=(SeriesData.Time{iview}(i1(1))+SeriesData.Time{iview}(i2(1)))/2;
            time_last=(SeriesData.Time{iview}(i1(2))+SeriesData.Time{iview}(i2(2)))/2;
        else
            time_first=(SeriesData.Time{iview}(i1(1),j1(1))+SeriesData.Time{iview}(i2(1),j2(1)))/2;
            time_last=(SeriesData.Time{iview}(i1(2),j1(2))+SeriesData.Time{iview}(i2(2),j2(2)))/2;
        end
        TimeTable{iview,2}=time_first; %TODO: take into account pairs
        TimeTable{iview,3}=time_last; %TODO: take into account pairs
    end
end
set(handles.TimeTable,'Data',TimeTable)

%% set the waitbar position with respect to the min and max in the series
for iview=1:numel(SeriesData.i1_series)
    pair_max{iview}=squeeze(max(SeriesData.i1_series{iview},[],1)); %max on pair index
    if (strcmp(get(handles.num_first_j,'Visible'),'off')&& size(pair_max{iview},2)~=1)
        pair_max{iview}=squeeze(max(pair_max{iview},[],1)); % consider only the i index
    end
    pair_max{iview}=reshape(pair_max{iview},1,[]);
    index_min(iview)=find(pair_max{iview}>0, 1 );
    index_max(iview)=find(pair_max{iview}>0, 1, 'last' );
end
[index_min,iview_min]=min(index_min);
[index_max,iview_max]=min(index_max);
if size(SeriesData.i1_series{iview_min},2)==1% movie
    index_first=ref_i(1);
    index_last=ref_i(2);
else
    index_first=(ref_i(1)-1)*(size(SeriesData.i1_series{iview_min},1))+ref_j(1)+1;
    index_last=(ref_i(2)-1)*(size(SeriesData.i1_series{iview_max},1))+ref_j(2)+1;
end
range=index_max-index_min+1;
coeff_min=(index_first-index_min)/range;
coeff_max=(index_last-index_min+1)/range;
Position=get(handles.Waitbar,'Position');% position of the waitbar:= [ x,y, width, height]
Position_status=get(handles.FileStatus,'Position');
Position(1)=coeff_min*Position_status(3)+Position_status(1);
Position(3)=Position_status(3)*(coeff_max-coeff_min);
set(handles.Waitbar,'Position',Position)
update_waitbar(handles.Waitbar,0)

%------------------------------------------------------------------------
% --- Executes when selected cell(s) is changed in PairString.
function PairString_CellSelectionCallback(hObject, eventdata, handles)
%------------------------------------------------------------------------    
set(handles.ListView,'Value',eventdata.Indices(1))% detect the selected raw index
ListView_Callback ([],[],handles) % update the list of available pairs

%------------------------------------------------------------------------
%------------------------------------------------------------------------
%  III - FUNCTIONS ASSOCIATED TO THE FRAME SET PAIRS
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% --- Executes on selection change in ListView.
function ListView_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------    
SeriesData=get(handles.series,'UserData');
i2_series=[];
j2_series=[];
iview=get(handles.ListView,'Value');
if ~isempty(SeriesData.i2_series{iview})
    i2_series=SeriesData.i2_series{iview};
end
if ~isempty(SeriesData.j2_series{iview})
    j2_series=SeriesData.j2_series{iview};
end
update_mode(handles,SeriesData.i1_series{iview},SeriesData.i2_series{iview},...
    SeriesData.j1_series{iview},SeriesData.j2_series{iview},SeriesData.Time{iview})

%------------------------------------------------------------------------
% --- Executes on button press in mode.
function mode_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------       
SeriesData=get(handles.series,'UserData');
iview=get(handles.ListView,'Value');
mode_list=get(handles.mode,'String');
mode=mode_list{get(handles.mode,'Value')};
if isequal(mode,'bursts')
    enable_i(handles,'On')
    enable_j(handles,'Off') %do not display j index scanning in burst mode (j is fixed by the burst choice)
else
    enable_i(handles,'On')
    enable_j(handles,'Off')
end
fill_ListPair(handles,SeriesData.i1_series{iview},SeriesData.i2_series{iview},...
    SeriesData.j1_series{iview},SeriesData.j2_series{iview},SeriesData.Time{iview})
ListPairs_Callback([],[],handles)

%-------------------------------------------------------------
% --- Executes on selection in ListPairs.
function ListPairs_Callback(hObject,eventdata,handles)
%------------------------------------------------------------
list_pair=get(handles.ListPairs,'String');%get the menu of image pairs
if isempty(list_pair)
    string='';
else
    string=list_pair{get(handles.ListPairs,'Value')};
    string=regexprep(string,',.*','');%removes time indication (after ',')
end
PairString=get(handles.PairString,'Data');
iview=get(handles.ListView,'Value');
PairString{iview,1}=string;
% report the selected pair string to the table PairString
set(handles.PairString,'Data',PairString)

%------------------------------------------------------------------------
function num_ref_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.mode,'String');
mode=mode_list{get(handles.mode,'Value')};
SeriesData=get(handles.series,'UserData');
iview=get(handles.ListView,'Value');
fill_ListPair(handles,SeriesData.i1_series{iview},SeriesData.i2_series{iview},...
    SeriesData.j1_series{iview},SeriesData.j2_series{iview},SeriesData.Time{iview});% update the menu of pairs depending on the available netcdf files
ListPairs_Callback([],[],handles)

%------------------------------------------------------------------------
function num_ref_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
num_ref_i_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function update_mode(handles,i1_series,i2_series,j1_series,j2_series,time)
%------------------------------------------------------------------------    
% check_burst=0;
if isempty(j2_series)% no j pair
    if isempty(i2_series)
        set(handles.mode,'Value',1)
        set(handles.mode,'String',{''})% no pair menu to display
    else   
        set(handles.mode,'Value',1)
        set(handles.mode,'String',{'series(Di)'}) % pair menu with only option Di
    end
else %existence of j pairs
    pair_max=squeeze(max(i1_series,[],1)); %max on pair index
    j_max=max(pair_max,[],1);
    MaxIndex_i=max(find(j_max))-1;% max ref index i
    MinIndex_i=min(find(j_max))-1;% min ref index i
    i_max=max(pair_max,[],2);
    MaxIndex_j=max(find(i_max))-1;% max ref index i
    MinIndex_j=min(find(i_max))-1;% min ref index i
    if MaxIndex_j==MinIndex_j
        set(handles.mode,'Value',1);
        set(handles.mode,'String',{'bursts'})
%         check_burst=1;
    elseif MaxIndex_i==MinIndex_i
        set(handles.mode,'Value',1);
        set(handles.mode,'String',{'series(Dj)'})
    else
        set(handles.mode,'String',{'bursts';'series(Dj)'})
        if (MaxIndex_j-MinIndex_j)>10
            set(handles.mode,'Value',2);%set mode to series(Dj) if more than 10 j values
        else
            set(handles.mode,'Value',1);
%             check_burst=1;
        end
    end
end
% if check_burst
%     enable_i(handles,'On')
%     enable_j(handles,'Off') %do not display j index scanning in burst mode (j is fixed by the burst choice)
% else
%     enable_i(handles,'On')
%     if isempty(j1_series)
%          enable_j(handles,'Off')
%     else
%         enable_j(handles,'On')
%     end
% end
fill_ListPair(handles,i1_series,i2_series,j1_series,j2_series,time)
ListPairs_Callback([],[],handles)

%--------------------------------------------------------------
% determine the menu for civ1 pairstring depending on existing netcdf files 
% with the reference indices num_ref_i and num_ref_j
%----------------------------------------------------------------
function fill_ListPair(handles,i1_series,i2_series,j1_series,j2_series,time)

mode_list=get(handles.mode,'String');
mode=mode_list{get(handles.mode,'Value')};
ref_i=str2num(get(handles.num_ref_i,'String'));
if isempty(ref_i)
    ref_i=1;
end
if strcmp(get(handles.num_ref_j,'Visible'),'on')
    ref_j=str2num(get(handles.num_ref_j,'String'));
    if isempty(ref_j)
        ref_j=1;
    end
else
    ref_j=1;
end
TimeUnit=get(handles.TimeUnit,'String');
if length(TimeUnit)>=1
    dtunit=['m' TimeUnit];
else
    dtunit='e-03';
end

displ_pair={};
if strcmp(mode,'series(Di)') 
    if isempty(i2_series)
        msgbox_uvmat('ERROR','no i1-i2 pair available')
        return
    end
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
elseif strcmp(mode,'series(Dj)')
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
elseif strcmp(mode,'bursts')
    if isempty(j2_series)
        msgbox_uvmat('ERROR','no j1-j2 pair available')
        return
    end
    diff_j=j2_series-j1_series;
    min_j1=min(j1_series(j1_series>0));
    max_j1=max(j1_series(j1_series>0));
    min_j2=min(j2_series(j2_series>0));
    max_j2=max(j2_series(j2_series>0));
    for pair1=min_j1:min(max_j1,min_j1+20)
        for pair2=min_j2:min(max_j2,min_j2+20)
        if numel(j1_series(j1_series==pair1))>0 && numel(j2_series(j2_series==pair2))>0
            displ_pair=[displ_pair;{['j= ' num2str(pair1) '-' num2str(pair2)]}];
        end
        end
    end
    if ~isempty(displ_pair)
        displ_pair=[displ_pair;{'j=*-*'}];
    end
end
set(handles.num_ref_i,'String',num2str(ref_i)) % update ref_i and ref_j 
set(handles.num_ref_j,'String',num2str(ref_j))

%% display list of pairstring
displ_pair_list=get(handles.ListPairs,'String');
NewVal=[];
if ~isempty(displ_pair_list)
Val=get(handles.ListPairs,'Value');
NewVal=find(strcmp(displ_pair_list{Val},displ_pair),1);% look at the previous display in the new menu displ_p�ir
end
if ~isempty(NewVal)
    set(handles.ListPairs,'Value',NewVal)
else
    set(handles.ListPairs,'Value',1)
end
set(handles.ListPairs,'String',displ_pair)

%-------------------------------------
function enable_i(handles,state)
set(handles.i_txt,'Visible',state)
set(handles.num_first_i,'Visible',state)
set(handles.num_last_i,'Visible',state)
set(handles.num_incr_i,'Visible',state)
% set(handles.num_MaxIndex_i,'Visible',state)
set(handles.num_ref_i,'Visible',state)
set(handles.ref_i_text,'Visible',state)

%-----------------------------------
function enable_j(handles,state)
set(handles.j_txt,'Visible',state)
set(handles.num_first_j,'Visible',state)
set(handles.num_last_j,'Visible',state)
set(handles.num_incr_j,'Visible',state)
set(handles.num_ref_j,'Visible',state)
set(handles.ref_j_text,'Visible',state)
% if strcmp(state,'off')
%     set(handles.MinIndex,'ColumnName',{'imax'})
% set(handles.MinIndex,'ColumnEditable',logical(0))
% else
%         set(handles.MinIndex,'ColumnName',{'imax','jmax'})
% end


%%%%%%%%%%%%%%%%%%%%
%%  MAIN ActionName FUNCTIONS
%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in RUN.
function RUN_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

set(handles.RUN,'BusyAction','queue');
set(0,'CurrentFigure',handles.series)
set(handles.RUN, 'Enable','Off')
set(handles.RUN,'BackgroundColor',[0.831 0.816 0.784])
drawnow

%% read the input parameters and set the output dir and nomenclature
[Series,OutputDir,errormsg]=prepare_jobs(handles);% get parameters form the GUI series
if ~isempty(errormsg)
    if ~strcmp(errormsg,'Cancel')
    msgbox_uvmat('ERROR',errormsg)
    end
    STOP_Callback([],[], handles)
    return
end
OutputNomType=nomtype2pair(Series.InputTable{1,4});% nomenclature for output files
DirXml=fullfile(OutputDir,'0_XML');
if ~exist(DirXml,'dir')
    [tild,msg1]=mkdir(DirXml);
    if ~strcmp(msg1,'')
        msgbox_uvmat('ERROR',['cannot create ' DirXml ': ' msg1]);%error message for directory creation
        return
    end
end

%% select the Action modes
RunMode='local';%default
if isfield(Series.Action,'RunMode')
RunMode=Series.Action.RunMode;
end
ActionExt='.m';%default
if isfield(Series.Action,'ActionExt')
    ActionExt=Series.Action.ActionExt;% '.m' or '.sh' (compiled)
end
ActionName=Series.Action.ActionName;
ActionPath=Series.Action.ActionPath;
path_series=fileparts(which('series'));

%% create the Action fct handle if RunMode option = 'local'
if strcmp(RunMode,'local')
    if ~isequal(ActionPath,path_series)
        eval(['spath=which(''' ActionName ''');']) %spath = current path of the selected function ACTION
        if ~exist(ActionPath,'dir')
            msgbox_uvmat('ERROR',['The prescribed function path ' ActionPath ' does not exist']);
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
RunTime='';
if strcmp(ActionExt,'.sh')
    if exist(xmlfile,'file')
        s=xml2struct(xmlfile);
        if strcmp(RunMode,'cluster_oar') && isfield(s,'BatchParam')
            if isfield(s.BatchParam,'RunTime')
                RunTime=s.BatchParam.RunTime;
            end
            if isfield(s.BatchParam,'NbCore')
                NbCore=s.BatchParam.NbCore;
            end
        elseif (strcmp(RunMode,'background')||strcmp(RunMode,'local')) && isfield(s,'RunParam')
            if isfield(s.RunParam,'RunTime')
                RunTime=s.RunParam.RunTime;
            end
            if isfield(s.RunParam,'NbCore')
                NbCore=s.RunParam.NbCore;
            end
        end
    end
    if isempty(RunTime) && strcmp(RunMode,'cluster_oar')
        msgbox_uvmat('ERROR','RunTime name not found in PARAM.xml, compiled version .sh cannot run on cluster')
        return
    end
%     Series.RunTime=RunTime;
end

%% set nbre of cluster cores and processes
switch RunMode
    case {'local','background'}
        NbCore=1;% no need to split the calculation
    case 'cluster_oar'
        if strcmp(Series.Action.ActionExt,'.m')% case of Matlab function (uncompiled)
            NbCore=1;% one core used only (limitation of Matlab licences)
            msgbox_uvmat('WARNING','Number of cores =1: select the compiled version civ_matlab.sh for multi-core processing');
            extra_oar='';
        else
            answer=inputdlg({'Number of cores (max 36)','extra oar options'},'oarsub parameter',1,{'12',''});
            NbCore=str2double(answer{1});
            extra_oar=answer{2};
        end
end
if ~isfield(Series.IndexRange,'NbSlice')
    Series.IndexRange.NbSlice=[];
end
if isempty(Series.IndexRange.NbSlice)
    NbProcess=NbCore;% choose one process per core
else
    NbProcess=Series.IndexRange.NbSlice;% the nbre of run processes is equal to the number of slices
    NbCore=min(NbCore,NbProcess);% at least one process per core
end
        

%% read index ranges
first_i=1;
last_i=1;
incr_i=1;
first_j=1;
last_j=1;
incr_j=1;
if isfield(Series.IndexRange,'first_i')
    first_i=Series.IndexRange.first_i;
    incr_i=Series.IndexRange.incr_i;
    last_i=Series.IndexRange.last_i;
end
if isfield(Series.IndexRange,'first_j')
    first_j=Series.IndexRange.first_j;
    last_j=Series.IndexRange.last_j;
    incr_j=Series.IndexRange.incr_j;
end
if last_i < first_i || last_j < first_j , msgbox_uvmat('ERROR','last field number must be larger than the first one'),...
        set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return
else
    BlockLength=ceil(numel(first_i:incr_i:last_i)/NbProcess);
end
nbfield_j=numel(first_j:incr_j:last_j);

%% record nbre of output files for status
StatusData=get(handles.status,'UserData');
StatusData.NbCore=NbCore;
StatusData.NbProcess=NbProcess;
if isfield(StatusData,'OutputFileMode')
switch StatusData.OutputFileMode
    case 'NbInput'%TODO:finish
end
end

%% direct processing on the current Matlab session
if strcmp (RunMode,'local')
    Series.RUNHandle=handles.RUN;
    Series.WaitbarHandle=handles.Waitbar;
    for iprocess=1:NbProcess
        if isempty(Series.IndexRange.NbSlice)
            Series.IndexRange.first_i=first_i+(iprocess-1)*BlockLength*incr_i;
            if Series.IndexRange.first_i>last_i
                break
            end
            Series.IndexRange.last_i=min(first_i+(iprocess)*BlockLength*incr_i-1,last_i);
        else
            Series.IndexRange.first_i= first_i+iprocess-1;
            Series.IndexRange.incr_i=incr_i*Series.IndexRange.NbSlice;
        end
        t=struct2xml(Series);
        t=set(t,1,'name','Series');
        filexml=fullfile_uvmat(DirXml,'',Series.InputTable{1,3},'.xml',OutputNomType,...
            Series.IndexRange.first_i,Series.IndexRange.last_i,first_j,last_j);
        save(t,filexml);
        switch ActionExt
            case '.m'
                h_fun(Series);
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
elseif strcmp(get(handles.OutputDirExt,'Visible'),'off')
    msgbox_uvmat('ERROR',['no output file for Action ' ActionName ', use run mode = local']);% a output dir is needed for background option
    return
else
    %% processing on a different session of the same computer (background) or cluster, create executable files
    batch_file_list=cell(NbProcess,1);% initiate the list of executable files
    DirBat=fullfile(OutputDir,'0_BAT');
    %create subdirectory for executable files
    if ~exist(DirBat,'dir')
        [tild,msg1]=mkdir(DirBat);
        if ~strcmp(msg1,'')
            msgbox_uvmat('ERROR',['cannot create ' DirBat ': ' msg1]);%error message for directory creation
            return
        end
    end
    %create subdirectory for log files
    DirLog=fullfile(OutputDir,'0_LOG');
    if ~exist(DirLog,'dir')
        [tild,msg1]=mkdir(DirLog);
        if ~strcmp(msg1,'')
            msgbox_uvmat('ERROR',['cannot create ' DirLog ': ' msg1]);%error message for directory creation
            return
        end
    end
    for iprocess=1:NbProcess
        if isempty(Series.IndexRange.NbSlice)% process by blocks of i index
            Series.IndexRange.first_i=first_i+(iprocess-1)*BlockLength*incr_i;
            if Series.IndexRange.first_i>last_i
                NbProcess=iprocess-1;
                break% leave the loop, we are at the end of the calculation
            end
            Series.IndexRange.last_i=min(last_i,first_i+(iprocess)*BlockLength*incr_i-1);
        else% process by slices of i index if NbSlice is defined, computation in a single process if NbSlice =1
            Series.IndexRange.first_i= first_i+iprocess-1;
            Series.IndexRange.incr_i=incr_i*Series.IndexRange.NbSlice;
        end
        
        % create, fill and save the xml parameter file
        t=struct2xml(Series);
        t=set(t,1,'name','Series');
        filexml=fullfile_uvmat(DirXml,'',Series.InputTable{1,3},'.xml',OutputNomType,...
            Series.IndexRange.first_i,Series.IndexRange.last_i,first_j,last_j);
        save(t,filexml);% save the parameter file
        
        %create the executable file
%         filebat=fullfile_uvmat(DirBat,'',Series.InputTable{1,3},'.bat',OutputNomType,...
%             Series.IndexRange.first_i,Series.IndexRange.last_i,first_j,last_j);
         filebat=fullfile_uvmat(DirBat,'',Series.InputTable{1,3},'.sh',OutputNomType,...
           Series.IndexRange.first_i,Series.IndexRange.last_i,first_j,last_j);
        batch_file_list{iprocess}=filebat;
        [fid,message]=fopen(filebat,'w');% create the executable file
        if isequal(fid,-1)
            msgbox_uvmat('ERROR', ['creation of .bat file: ' message]);
            return
        end
        
        % set the log file name
        filelog=fullfile_uvmat(DirLog,'',Series.InputTable{1,3},'.log',OutputNomType,...
            Series.IndexRange.first_i,Series.IndexRange.last_i,first_j,last_j);
        
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
                            'addpath(''' Series.Action.ActionPath '''); \n'...
                            '' Series.Action.ActionName  '( ''' filexml '''); \n'...
                            'exit \n'...
                            'END_MATLAB \n'];
                        fprintf(fid,cmd);%fill the executable file with the  char string cmd
                        fclose(fid);% close the executable file
                        system(['chmod +x ' filebat]);% set the file to executable
                    case {'PCWIN','PCWIN64'}
                        text_matlabscript=['matlab -automation -logfile ' regexprep(filelog,'\\','\\\\')...
                            ' -r "addpath(''' regexprep(path_series,'\\','\\\\') ''');'...
                            'addpath(''' regexprep(Series.Action.ActionPath,'\\','\\\\') ''');'...
                            '' Series.Action.ActionName  '( ''' regexprep(filexml,'\\','\\\\') ''');exit"'];
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
                        
                    case {'PCWIN','PCWIN64'}    %       TODO: adapt to Windows system
                        %                                 cmd=['matlab -automation -logfile ' regexprep(filelog,'\\','\\\\')...
                        %                                     ' -r "addpath(''' regexprep(path_series,'\\','\\\\') ''');'...
                        %                                     'addpath(''' regexprep(Series.Action.ActionPath,'\\','\\\\') ''');'...
                        %                                     '' Series.Action.ActionName  '( ''' regexprep(filexml,'\\','\\\\') ''');exit"'];
                        fprintf(fid,cmd);
                        fclose(fid);
                        %                               dos([filebat ' &']);
                end
        end
    end
end

%% launch the executable files for background or cluster processing
switch RunMode
    case 'background'
        for iprocess=1:NbProcess
            system(batch_file_list{iprocess})% directly execute the command file for each process
        end
    case 'cluster_oar' % option 'oar-parexec' used
        %create subdirectory for oar command and log files
        DirOAR=fullfile(OutputDir,'0_OAR');
        if ~exist(DirOAR,'dir')
            [tild,msg1]=mkdir(DirOAR);
            if ~strcmp(msg1,'')
                msgbox_uvmat('ERROR',['cannot create ' DirOAR ': ' msg1]);%error message for directory creation
                return
            end
        end
        max_walltime=3600*12; % 12h max total calculation 
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
        %system(['chmod +x ' oar_command]);% set the file to executable
        system(oar_command);     
end

%% reset the GUI series
update_waitbar(handles.Waitbar,1); % put the waitbar to end position to indicate launching is finished
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])
set(handles.RUN, 'Value',0)

%------------------------------------------------------------------------
function STOP_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RUN, 'BusyAction','cancel')
set(handles.RUN,'BackgroundColor',[1 0 0])
set(handles.RUN,'enable','on')
set(handles.RUN, 'Value',0)

% %------------------------------------------------------------------------
% % --- Executes on button press in BIN.
% function BIN_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
%     cmd=['#!/bin/bash \n '...
%         '#$ -cwd \n '...
%         'hostname && date \n '...
%         'umask 002 \n'...
%         Param.xml.CivmBin ' ' Param.xml.RunTime ' ' filename_xml ' ' OutputFile '.nc'];
%     
%------------------------------------------------------------------------
% --- Main launch command, called by RUN and BATCH

function [Series,OutputDir,errormsg]=prepare_jobs(handles)
%INPUT: 
% handles: handles of graphic objects on the GUI series

%------------------------------------------------------------------------
OutputDir='';
errormsg='';

%% Read parameters from series
Series=read_GUI(handles.series);

%% get_field GUI
% if isfield(Series,'InputFields')&&isfield(Series.InputFields,'Field')
%     if strcmp(Series.InputFields.Field,'get_field...')
%         hget_field=findobj(allchild(0),'name','get_field');
%         Series.GetField=read_GUI(hget_field);
%     end
% end

%% create the output data directory 
%determine the root file corresponding to the first sub dir
if get(handles.RUN,'value') && isfield(Series,'OutputSubDir')
    SubDirOut=[get(handles.OutputSubDir,'String') Series.OutputDirExt];
    SubDirOutNew=SubDirOut;
    SeriesData=get(handles.series,'UserData');
    if size(Series.InputTable,1)>1 && isfield(SeriesData,'AllowInputSort') && SeriesData.AllowInputSort
        [tild,iview]=sort(Series.InputTable(:,2)); %subdirectories sorted in alphabetical order
        Series.InputTable=Series.InputTable(iview,:);
    end
    detect=exist(fullfile(Series.InputTable{1,1},SubDirOutNew),'dir');% test if  the dir  already exist
    check_create=1; %need to create the result directory by default
    while detect
        answer=msgbox_uvmat('INPUT_Y-N',['use existing ouput directory: ' fullfile(Series.InputTable{1,1},SubDirOutNew) ', possibly delete previous data']);
        if strcmp(answer,'Cancel')
            errormsg='Cancel';
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
            detect=exist(fullfile(Series.InputTable{1,1},SubDirOutNew),'dir');% test if  the dir  already exists   
            check_create=1;
        end
    end
    Series.OutputDirExt=regexprep(SubDirOutNew,Series.OutputSubDir,'');
    Series.OutputRootFile=Series.InputTable{1,3};% the first sorted RootFile taken for output
    set(handles.OutputDirExt,'String',Series.OutputDirExt)
    OutputDir=fullfile(Series.InputTable{1,1},[Series.OutputSubDir Series.OutputDirExt]);% full name (with path) of output directory 
    if check_create    % create output directory if it does not exist
        [tild,msg1]=mkdir(OutputDir);
        if ~strcmp(msg1,'')
            errormsg=['cannot create ' OutputDir ': ' msg1];%error message for directory creation
            return
        end
    end
   % RootOut=fullfile(OutputDir,Series.InputTable{1,3});% name of the parameter xml file set in this directory
end

%% removes unused information on Series
if isfield(Series,'Pairs')
    Series=rmfield(Series,'Pairs'); %info Pairs not needed for output
end
Series.IndexRange=rmfield(Series.IndexRange,'TimeTable');
% Series.IndexRange=rmfield(Series.IndexRange,'MinIndex');
% Series.IndexRange=rmfield(Series.IndexRange,'MaxIndex');
empty_line=false(size(Series.InputTable,1),1);
for iline=1:size(Series.InputTable,1)
    empty_line(iline)=isequal(Series.InputTable(iline,1:3),{'','',''});
end
Series.InputTable(empty_line,:)=[];

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
drawnow

%% get Action name and path
nb_builtin_ACTION=4; %nbre of functions initially proposed in the menu ActionName (as defined in the Opening fct of series)
ActionList=get(handles.ActionName,'String');% list menu fields
ActionIndex=get(handles.ActionName,'Value');
if ~isequal(ActionIndex,1)
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
    [ActionPath,ActionName,ActionExt]=fileparts(FileName);
    
    % insert the choice in the menu ActionName
    ActionIndex=find(strcmp(ActionName,ActionList),1);% look for the selected function in the menu Action
    if isempty(ActionIndex)%the input string does not exist in the menu
        ActionIndex= length(ActionList);
        ActionList=[ActionList(1:end-1);{ActionName};ActionList(end)];% the selected function is appended in the menu, before the last item 'more...'
        set(handles.ActionName,'String',ActionList)
    end
    
    % record the file extension and extend the path list if it is a new extension
    ActionExtList=get(handles.ActionExt,'String');
    ActionExtIndex=find(strcmp(ActionExt,ActionExtList), 1);
    if isempty(ActionExtIndex)
        set(handles.ActionExt,'String',[ActionExtList;{ActionExt}])
        ActionExtIndex=numel(ActionExtList)+1;
        ActionPathNew=cell(size(ActionPathList,1),1);%new column of ActionPath
        ActionPathList=[ActionPathList ActionPathNew];
    end
    set(handles.ActionName,'UserData',ActionPathList);

    % remove old Action options in the menu (keeping a menu length <nb_builtin_ACTION+5)
    if length(ActionList)>nb_builtin_ACTION+5; %nb_builtin=nbre of functions always remaining in the initial menu
        nbremove=length(ActionList)-nb_builtin_ACTION-5;
        ActionList(nb_builtin_ACTION+1:end-5)=[];
        ActionPathList(nb_builtin_ACTION+1:end-4,:)=[];
        ActionIndex=ActionIndex-nbremove;
    end
    
    % record action menu, choice and path
    set(handles.ActionName,'Value',ActionIndex)
    set(handles.ActionName,'String',ActionList)
    set(handles.ActionExt,'Value',ActionExtIndex)
    ActionPathList{ActionIndex,ActionExtIndex}=PathName;
        
    %record the user defined menu additions in personal file profil_perso
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if nb_builtin_ACTION+1<=numel(ActionList)-1
        ActionListUser=ActionList(nb_builtin_ACTION+1:numel(ActionList)-1);
        ActionPathListUser=ActionPathList(nb_builtin_ACTION+1:numel(ActionList)-1,:);
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

%% default setting for the visibility of the GUI elements
% set(handles.FieldTransform,'Visible','off')
% set(handles.CheckObject,'Visible','off');
% set(handles.ProjObject,'Visible','off');
% set(handles.CheckMask,'Visible','off')
% set(handles.Mask,'Visible','off')

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

%% Activate the Action fct
[Series,tild,errormsg]=prepare_jobs(handles);% read the parameters from the GUI series
if ~isempty(errormsg)
    if ~strcmp(errormsg,'Cancel')
    msgbox_uvmat('ERROR',errormsg)
    end
    return
end
ParamOut=h_fun(Series);

%% Put the first line of the selected Action fct as tooltip help
try
    [fid,errormsg] =fopen([ActionName '.m']);
    InputText=textscan(fid,'%s',1,'delimiter','\n');
    fclose(fid);
    set(handles.ActionName,'ToolTipString',InputText{1}{1})% put the first line of the selected function as tooltip help
end

%% Detect the types of input files
SeriesData=get(handles.series,'UserData');
nb_civ=0;nb_netcdf=0;
if ~isempty(SeriesData)
    nb_civ=numel(find(strcmp('civx',SeriesData.FileType)|strcmp('civdata',SeriesData.FileType)));
    nb_netcdf=numel(find(strcmp('netcdf',SeriesData.FileType)));
end

%% Check whether alphabetical sorting of input Subdir is alowed by the Action fct  (for multiples series entries)
SeriesData.AllowInputSort=0;%default
if isfield(ParamOut,'AllowInputSort')&&isequal(ParamOut.AllowInputSort,'on')
    SeriesData.AllowInputSort=1;
end

%% Impose the whole input file index range if requested
if isfield(ParamOut,'WholeIndexRange')&&isequal(ParamOut.WholeIndexRange,'on')
    MinIndex=get(handles.MinIndex,'Data');
    MaxIndex=get(handles.MaxIndex,'Data');
    if ~isempty(MinIndex)
        set(handles.num_first_i,'String',num2str(MinIndex{1}))
        set(handles.num_last_i,'String',num2str(MaxIndex{1}))
        set(handles.num_incr_i,'String','1')
        if size(MinIndex,2)>=2
            set(handles.num_first_j,'String',num2str(MinIndex{1,2}))
            set(handles.num_last_j,'String',num2str(MaxIndex{1,2}))
            set(handles.num_incr_j,'String','1')
        end
    end
else
% check index ranges
first_i=1;last_i=1;first_j=1;last_j=1;
if isfield(Series.IndexRange,'first_i')
    first_i=Series.IndexRange.first_i;
    last_i=Series.IndexRange.last_i;
end
if isfield(Series.IndexRange,'first_j')
    first_j=Series.IndexRange.first_j;
    last_j=Series.IndexRange.last_j;
end
if last_i < first_i || last_j < first_j , msgbox_uvmat('ERROR','last field number must be larger than the first one'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
end

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

%% Visibility of VelType and VelType_1 menus
VelTypeVisible='off';  %hidden by default
VelType_1Visible='off';
InputFieldsVisible='off';%visibility of the frame Fields
if isfield(ParamOut,'VelType')
    if strcmp( ParamOut.VelType,'one')||strcmp( ParamOut.VelType,'two')
        if nb_civ>=1
            VelTypeVisible='on';
            InputFieldsVisible='on';
        end
    end
    if strcmp( ParamOut.VelType,'two')
        if nb_civ>=2
            VelType_1Visible='on';
        end
    end
end
set(handles.VelType,'Visible',VelTypeVisible)
set(handles.VelType_text,'Visible',VelTypeVisible);
set(handles.VelType_1,'Visible',VelType_1Visible)
set(handles.VelType_text_1,'Visible',VelType_1Visible);

%% Visibility of FieldName and FieldName_1 menus
FieldNameVisible='off';  %hidden by default
FieldName_1Visible='off';  %hidden by default
if isfield(ParamOut,'FieldName')
    if strcmp( ParamOut.FieldName,'one')||strcmp( ParamOut.FieldName,'two')
        if (nb_civ+nb_netcdf)>=1
            InputFieldsVisible='on';
            FieldNameVisible='on';
        end
    end
    if strcmp( ParamOut.FieldName,'two')
        if (nb_civ+nb_netcdf)>=1
            FieldName_1Visible='on';
        end
    end
end
set(handles.InputFields,'Visible',InputFieldsVisible)
set(handles.FieldName,'Visible',FieldNameVisible) % test for MenuBorser
set(handles.FieldName_1,'Visible',FieldName_1Visible)

%% Visibility of FieldTransform menu
FieldTransformVisible='off';  %hidden by default
if isfield(ParamOut,'FieldTransform')
    FieldTransformVisible=ParamOut.FieldTransform;  
    TransformName_Callback([],[], handles)
end
set(handles.FieldTransform,'Visible',FieldTransformVisible)

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


%% Visibility of mask input
MaskVisible='off';  %hidden by default
if isfield(ParamOut,'Mask')
    MaskVisible=ParamOut.Mask;
end
set(handles.Mask,'Visible',MaskVisible)
set(handles.CheckMask,'Visible',MaskVisible);

%% definition of the directory containing the output files 
OutputDirVisible='off';
if isfield(ParamOut,'OutputDirExt')&&~isempty(ParamOut.OutputDirExt)
    set(handles.OutputDirExt,'String',ParamOut.OutputDirExt)
    OutputDirVisible='on';
end
set(handles.OutputDirExt,'Visible',OutputDirVisible)
set(handles.OutputSubDir,'Visible',OutputDirVisible)
set(handles.OutputDir_title,'Visible',OutputDirVisible)
set(handles.RunMode,'Visible',OutputDirVisible)
set(handles.ActionExt,'Visible',OutputDirVisible)
set(handles.RunMode_title,'Visible',OutputDirVisible)
set(handles.ActionExt_title,'Visible',OutputDirVisible)

%% Expected nbre of output files
if isfield(ParamOut,'OutputFileMode')
StatusData.NbOutputFile=ParamOut.OutputFileMode;
set(handles.status,'UserData',StatusData)
end

%% definition of an additional parameter set, determined by an ancillary GUI
if isfield(ParamOut,'ActionInput')
    set(handles.ActionInput,'Visible','on')
    set(handles.ActionInput_title,'Visible','on')
    set(handles.ActionInputView,'Visible','on')
    set(handles.ActionInputView,'Value',0)
    set(handles.ActionInput,'String',ActionName)
    ParamOut.ActionInput.Program=ActionName; % record the program in ActionInput
    SeriesData.ActionInput=ParamOut.ActionInput;
else
    set(handles.ActionInput,'Visible','off')
    set(handles.ActionInput_title,'Visible','off')
    set(handles.ActionInputView,'Visible','off')
    if isfield(SeriesData,'ActionInput')
    SeriesData=rmfield(SeriesData,'ActionInput');
    end
end   
set(handles.series,'UserData',SeriesData)
set(handles.ActionName,'BackgroundColor',[1 1 1])

%------------------------------------------------------------------------
% --- Executes on button press in ActionInputView.
function ActionInputView_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if get(handles.ActionInputView,'Value')
ActionName_Callback(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% --- Executes on selection change in FieldName.
function FieldName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
field_str=get(handles.FieldName,'String');
field_index=get(handles.FieldName,'Value');
field=field_str{field_index(1)};
if isequal(field,'get_field...')
    hget_field=findobj(allchild(0),'name','get_field');
    if ~isempty(hget_field)
        delete(hget_field)%delete opened versions of get_field
    end
    Series=read_GUI(handles.series);
    Series.InputTable=Series.InputTable(1,:);
    filecell=get_file_series(Series);
    if exist(filecell{1,1},'file')
        GetFieldData=get_field(filecell{1,1});
        FieldList={};
        XName=GetFieldData.XVarName;
        if GetFieldData.CheckVector
            UName=GetFieldData.PanelVectors.vector_x;
            VName=GetFieldData.PanelVectors.vector_y;
            XName=GetFieldData.XVarName;
            YName=GetFieldData.YVarName;
            CName=GetFieldData.PanelVectors.vec_color;
            [FieldList,VecColorList]=set_field_list(UName,VName,CName);
        elseif GetFieldData.CheckScalar
            AName=GetFieldData.PanelScalar.scalar;
            XName=GetFieldData.XVarName;
            YName=GetFieldData.YVarName;
            FieldList={AName};
        elseif GetFieldData.CheckPlot1D;
            YName=GetFieldData.CheckPlot1D.ordinate;
        end
        set(handles.Coord_x,'String',{XName})
        set(handles.Coord_y,'String',{YName})
        set(handles.FieldName,'Value',1)
        set(handles.FieldName,'String',[FieldList; {'get_field...'}]);
        %         set(handles.ColorScalar,'Value',1)
        %         set(handles.ColorScalar,'String',VecColorList);
        %         UvData.FileType{1}='netcdf';
        %         set(handles.uvmat,'UserData',UvData)
    end
    % elseif isequal(field,'more...')
    %     str=calc_field;
    %     [ind_answer,v] = listdlg('PromptString','Select a file:',...
    %                 'SelectionMode','single',...
    %                 'ListString',str);
    %        % edit the choice in the fields and actionname menu
    %      scalar=cell2mat(str(ind_answer));
    %      update_menu(handles.FieldName,scalar)
end

%------------------------------------------------------------------------
% --- Executes on selection change in FieldName_1.
function FieldName_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
field_str=get(handles.FieldName_1,'String');
field_index=get(handles.FieldName_1,'Value');
field=field_str{field_index};
if isequal(field,'get_field...')    
     hget_field=findobj(allchild(0),'name','get_field_1');
     if ~isempty(hget_field)
         delete(hget_field)
     end
     SeriesData=get(handles.series,'UserData');
     filename=SeriesData.CurrentInputFile_1;
     if exist(filename,'file')
        hget_field=get_field(filename);
        set(hget_field,'name','get_field_1')
     end
% elseif isequal(field,'more...')
%     str=calc_field;
%     [ind_answer,v] = listdlg('PromptString','Select a file:',...
%                 'SelectionMode','single',...
%                 'ListString',str);
%        % edit the choice in the fields and actionname menu
%      scalar=cell2mat(str(ind_answer));
%      update_menu(handles.FieldName_1,scalar)
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
value=get(handles.CheckObject,'Value');
if value
%      set(handles.CheckObject,'BackgroundColor',[1 1 0])%put unactivated buttons to yellow
     hset_object=findobj(allchild(0),'tag','set_object');%find the set_object interface handle
     if ishandle(hset_object)
         uistack(hset_object,'top')% show the GUI set_object if opened
     else
         %get the object file 
         InputTable=get(handles.InputTable,'Data');
         defaultname=InputTable{1,1};
         if isempty(defaultname)
            defaultname={''};
         end
        [FileName, PathName] = uigetfile( ...
       {'*.xml;*.mat', ' (*.xml,*.mat)';
       '*.xml',  '.xml files '; ...
        '*.mat',  '.mat matlab files '}, ...
        'Pick an xml object file (or use uvmat to create it)',defaultname);
        fileinput=[PathName FileName];%complete file name 
        sizf=size(fileinput);
        if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end
        %read the file
        data=xml2struct(fileinput);
        if ~isfield(data,'Type')
             msgbox_uvmat('ERROR',[fileinput ' is not an object xml file'])
             return
        end
        if ~isfield(data,'ProjMode')
             data.ProjMode='none';
        end
        hset_object=set_object(data);% call the set_object interface
     end 
     ProjObject=read_GUI(hset_object);
     set(handles.ProjObject,'String',ProjObject.Name);%display the object name
     SeriesData=get(handles.series,'UserData');
     SeriesData.ProjObject=ProjObject;
     set(handles.series,'UserData',SeriesData);
     set(handles.DeleteObject,'Visible','on');
     set(handles.ViewObject,'Visible','on');
     set(handles.ProjObject,'Visible','on');
else
         set(handles.DeleteObject,'Visible','off');
     set(handles.ViewObject,'Visible','off');
     set(handles.ProjObject,'Visible','off');
%     set(handles.CheckObject,'BackgroundColor',[0.7 0.7 0.7])%put activated buttons to green
end
%set(handles.series,'UserData',SeriesData)

%--------------------------------------------------------------
function CheckMask_Callback(hObject, eventdata, handles)
value=get(handles.CheckMask,'Value');
if value
    msgbox_uvmat('ERROR','not implemented yet')
end
%--------------------------------------------------------------

%-------------------------------------------------------------------
%'uv_ncbrowser': interactively calls the netcdf file browser 'get_field.m'
function ncbrowser_uvmat(hObject, eventdata)
%-------------------------------------------------------------------
     bla=get(gcbo,'String');
     ind=get(gcbo,'Value');
     filename=cell2mat(bla(ind));
      blank=find(filename==' ');
      filename=filename(1:blank-1);
     get_field(filename)

% ------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
else
    addpath (fullfile(pathelp,'uvmat_doc'))
    web([helpfile '#series'])
end

%-------------------------------------------------------------------
% --- Executes on selection change in TransformName.
function TransformName_Callback(hObject, eventdata, handles)
%----------------------------------------------------------------------
TransformList=get(handles.TransformName,'String');
TransformIndex=get(handles.TransformName,'Value');
TransformName=TransformList{TransformIndex};
TransformPathList=get(handles.TransformName,'UserData');
nb_builtin_transform=4;
% ff=functions(list_transform{end});
if isequal(TransformName,'more...'); 
%     coord_fct='';
%     prompt = {'Enter the name of the transform function'};
%     dlg_title = 'user defined transform';
%     num_lines= 1;
    [FileName, PathName] = uigetfile( ...
       {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a transform function',get(handles.TransformPath,'String'));
    if isequal(FileName,0)
        return     %browser closed without choice
    end
    if isequal(PathName(end),'/')||isequal(PathName(end),'\')
        PathName(end)=[];
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
        TransformList=[TransformList(1:end-1);{TransformnName};TransformList(end)];% the selected function is appended in the menu, before the last item 'more...'
        set(handles.TransformName,'String',TransformList)
        TransformPathList=[TransformPathList;{TransformPath}];
    end
   % save the new menu in the personal file 'uvmat_perso.mat' 
   dir_perso=prefdir;%personal Matalb directory
   profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
   if exist(profil_perso,'file')
       for ilist=nb_builtin_transform+1:numel(TransformPathList)
           TransformListUser{ilist-nb_builtin_transform}=TransformList{ilist};
           TransformPathListUser{ilist-nb_builtin_transform}=TransformPathList{ilist};
       end 
       save (profil_perso,'TransformPathListUser','TransformListUser','-append'); %store the root name for future opening of uvmat
   end 
end

%display the current function path
set(handles.TransformPath,'String',TransformPathList{TransformIndex}); %show the path to the senlected function
set(handles.TransformName,'UserData',TransformPathList);


% --------------------------------------------------------------------
function MenuExportConfig_Callback(hObject, eventdata, handles)
global Series
[Series,errormsg]=prepare_jobs(handles);

evalin('base','global Series')%make CurData global in the workspace
display('current series config :')
evalin('base','Series') %display CurData in the workspace
commandwindow; %brings the Matlab command window to the front


% --------------------------------------------------------------------
function MenuImportConfig_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
InputTable=get(handles.InputTable,'Data');
[FileName, PathName] = uigetfile( ...
       {'*.xml', ' (*.xml)';
       '*.xml',  '.xml files '; ...
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file',InputTable{1,1});
filexml=[PathName FileName];%complete file name 
if isempty(filexml),return;end %abandon if no file is introduced by the browser
Param=xml2struct(filexml);
fill_GUI(Param,handles.series)

% --- Executes on selection change in RunMode.
function RunMode_Callback(hObject, eventdata, handles)

% --- Executes on selection change in Coord_x.
function Coord_x_Callback(hObject, eventdata, handles)


% --- Executes on selection change in Coord_y.
function Coord_y_Callback(hObject, eventdata, handles)



% --- Executes when series is resized.
function series_ResizeFcn(hObject, eventdata, handles)
%% input table
set(handles.InputTable,'Unit','pixel')
Pos=get(handles.InputTable,'Position');
set(handles.InputTable,'Unit','normalized')
ColumnWidth=round([0.5 0.14 0.14 0.14 0.08]*(Pos(3)-52));
ColumnWidth=num2cell(ColumnWidth);
set(handles.InputTable,'ColumnWidth',ColumnWidth)

%% MinIndex and MaxIndex
set(handles.MinIndex,'Unit','pixel')
Pos=get(handles.MinIndex,'Position');
set(handles.MinIndex,'Unit','normalized')
ColumnWidth=get(handles.MinIndex,'ColumnWidth');
if numel(ColumnWidth)==2
    ColumnWidth=num2cell(floor([0.5 0.5]*(Pos(3)-20)));
else
    ColumnWidth={Pos(3)-5};
end    
set(handles.MinIndex,'ColumnWidth',ColumnWidth)
set(handles.MaxIndex,'ColumnWidth',ColumnWidth)

%% TimeTable
set(handles.TimeTable,'Unit','pixel')
Pos=get(handles.TimeTable,'Position');
set(handles.TimeTable,'Unit','normalized')
ColumnWidth=get(handles.TimeTable,'ColumnWidth');
ColumnWidth=num2cell(floor([0.25 0.25 0.25 0.25]*(Pos(3)-20)));
set(handles.TimeTable,'ColumnWidth',ColumnWidth)


%% PairString
set(handles.PairString,'Unit','pixel')
Pos=get(handles.PairString,'Position');
set(handles.PairString,'Unit','normalized')
set(handles.PairString,'ColumnWidth',{Pos(3)-5})


% --- Executes on button press in status.
function status_Callback(hObject, eventdata, handles)

if get(handles.status,'Value')
    set(handles.status,'BackgroundColor',[1 1 0])
    drawnow
    StatusData.time_ref=get(handles.RUN,'UserData');% get the time of launch
    Param=read_GUI(handles.series);
    RootPath=Param.InputTable{1,1};
    if ~isfield(Param,'OutputSubDir')   
        msgbox_uvmat('ERROR','no directory defined for output files')
        return
    end
    OutputSubDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files
    OutputDir=fullfile(RootPath,OutputSubDir);
    hfig=findobj(allchild(0),'name','series_status');
    if isempty(hfig)
        hfig=figure('DeleteFcn',@stop_status,'Position',[600 600 560 600]);
        set(hfig,'MenuBar','none')% suppress the menu bar
        set(hfig,'NumberTitle','off')%suppress the fig number in the title
        set(hfig,'name','series_status')
        set(hfig,'tag','series_status')
        uicontrol('Style','listbox','Units','normalized', 'Position',[0.05 0.09 0.9 0.71], 'Callback', @view_file,'tag','list','UserData',OutputDir);
        uicontrol('Style','edit','Units','normalized', 'Position', [0.05 0.87 0.9 0.1],'tag','titlebox','Max',2,'String',OutputDir);
        uicontrol('Style','frame','Units','normalized', 'Position', [0.05 0.81 0.9 0.05]);
        uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.7 0.01 0.2 0.07],'String','Close','FontWeight','bold','FontUnits','points','FontSize',11,'Callback',@stop_status);
        hrefresh=uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.1 0.01 0.2 0.07],'String','Refresh','FontWeight','bold','FontUnits','points','FontSize',11,'Callback',@refresh_GUI);
        set(hrefresh,'UserData',StatusData)
        BarPosition=[0.05 0.81 0.01 0.05];
        uicontrol('Style','frame','Units','normalized', 'Position',BarPosition ,'BackgroundColor',[1 0 0],'tag','waitbar');
        drawnow
    end
    refresh_GUI(hrefresh,[]) 
else
    %% delete current display fig if selection is off
    set(handles.status,'BackgroundColor',[0 1 0])
    hfig=findobj(allchild(0),'name','series_status');
    if ~isempty(hfig)
        delete(hfig)
    end
    return
end


%------------------------------------------------------------------------   
% launched by selecting a file on the list
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
    FileType=get_file_type(FullSelectName);
    if strcmp(FileType,'txt')
        edit(FullSelectName)
    elseif strcmp(FileType,'xml')
        editxml(FullSelectName)
    else
        uvmat(FullSelectName)
    end
    set(gcbo,'Value',1)
end


%------------------------------------------------------------------------

%------------------------------------------------------------------------   
% launched by refreshing the status figure
function refresh_GUI(hObject, eventdata)
%------------------------------------------------------------------------
hfig=get(hObject,'parent');
htitlebox=findobj(hfig,'tag','titlebox');
hlist=findobj(hfig,'tag','list');
StatusData=get(hObject,'UserData');
OutputDir=get(htitlebox,'String');
if ischar(OutputDir),OutputDir={OutputDir};end
ListFiles=dir(OutputDir{1});
ListDisplay=cell(numel(ListFiles),1);
testrecent=0;
datnum=zeros(numel(ListDisplay)-1,1);
for ilist=2:numel(ListDisplay)
    ListDisplay{ilist-1}=ListFiles(ilist).name;
      if ~ListFiles(ilist).isdir && isfield(ListFiles(ilist),'datenum')
            datnum(ilist)=ListFiles(ilist).datenum;%only available in recent matlab versions
            testrecent=1;
       end
end
set(hlist,'String',ListDisplay)

%% Look at date of creation
datnum=datnum(datnum~=0);%keep the non zero values corresponding to existing files
ListDisplay=ListDisplay(datnum~=0);
if isempty(datnum)
    if testrecent
        message='no civ result created yet';
    else
        message='';
    end
else
    [first,indfirst]=min(datnum);
    [last,indlast]=max(datnum);
    message={[num2str(numel(datnum)) ' file(s) done over ?'] ;['oldest modification:  ' ListDisplay{indfirst} ' : ' datestr(first)];...
        ['latest modification:  ' ListDisplay{indlast} ' : ' datestr(last)]};
end
titlebox=findobj(hfig,'tag','titlebox');
msg_old=get(titlebox,'String');
set(titlebox,'String', [msg_old(1);message])
hwaitbar=findobj(hfig,'tag','waitbar');
%TODO: adjust waitbar

% civ_files=get(hfig,'UserData');

% [filepath,filename,ext]=fileparts(civ_files{1});
% [tild,SubDir,extdir]=fileparts(filepath);
% SubDir=[SubDir extdir];
% option_civ=StatusData.option_civ;
% nbfiles=numel(civ_files);
% testrecent=0;
% count=0;
% datnum=zeros(1,nbfiles);
% filefound=cell(1,nbfiles);
% for ifile=1:nbfiles
%     detect=exist(civ_files{ifile},'file'); % check the existence of the file
%     option=0;
%     if detect==0
%         option_str='not created';
%     else
%         datfile=dir(civ_files{ifile});
%         if isfield(datfile,'datenum')
%             datnum(ifile)=datfile.datenum;%only available in recent matlab versions
%             testrecent=1;
%         end
%         filefound(ifile)={datfile.name};
%         
%         % check the content  netcdf file
%         Data=nc2struct(civ_files{ifile},'ListGlobalAttribute','CivStage','patch2','fix2','civ2','patch','fix');
%         option_list={'civ1','fix1','patch1','civ2','fix2','patch2'};
%         if ~isempty(Data.CivStage)
%             option=Data.CivStage;%case of Matlab civ
%         else
%             if ~isempty(Data.patch2) && isequal(Data.patch2,1)
%                 option=6;
%             elseif ~isempty(Data.fix2) && isequal(Data.fix2,1)
%                 option=5;
%             elseif ~isempty(Data.civ2) && isequal(Data.civ2,1);
%                 option=4;
%             elseif ~isempty(Data.patch) && isequal(Data.patch,1);
%                 option=3;
%             elseif ~isempty(Data.fix) && isequal(Data.fix,1);
%                 option=2;
%             else
%                 option=1;
%             end
%         end
%         option_str=option_list{option};
%         if datnum(ifile)<StatusData.time_ref
%             option_str=[option_str '  --OLD--'];
%         end
%     end
%     if option >= option_civ
%         count=count+1;
%     end
%     [filepath,filename,ext]=fileparts(civ_files{ifile});
%     Tabchar{ifile,1}=[fullfile(SubDir,filename) ext  '...' option_str];
% end
% datnum=datnum(datnum~=0);%keep the non zero values corresponding to existing files
% if isempty(datnum)
%     if testrecent
%         message='no civ result created yet';
%     else
%         message='';
%     end
% else
%     datnum=datnum(datnum~=0);%keep the non zero values corresponding to existing files
%     [first,ind]=min(datnum);
%     [last,indlast]=max(datnum);
%     message={[num2str(count) ' file(s) done over ' num2str(nbfiles)] ;['oldest modification:  ' cell2mat(filefound(ind)) ' : ' datestr(first)];...
%         ['latest modification:  ' cell2mat(filefound(indlast)) ' : ' datestr(last)]};
% end
% hlist=findobj(hfig,'tag','list');
% htitlebox=findobj(hfig,'tag','titlebox');
% hwaitbar=findobj(hfig,'tag','waitbar');
% set(hlist,'String',Tabchar)
% set(htitlebox,'String', message)
% if count>0 %&& ~test_new
%     BarPosition(3)=0.9*count/nbfiles;
%     set(hwaitbar,'Position',BarPosition)
% end
%------------------------------------------------------------------------   
% launched by deleting the status figure
function stop_status(hObject, eventdata)
%------------------------------------------------------------------------
hciv=findobj(allchild(0),'tag','series');
hhciv=guidata(hciv);
set(hhciv.status,'value',0) %reset the status uicontrol in the GUI civ
set(hhciv.status,'BackgroundColor',[0 1 0])
delete(gcbf)

% --- Executes on selection change in ActionExt.
function ActionExt_Callback(hObject, eventdata, handles)
ActionExtList=get(handles.ActionExt,'String');
ActionExt=ActionExtList{get(handles.ActionExt,'Value')};
ActionList=get(handles.ActionName,'String');
ActionName=ActionList{get(handles.ActionName,'Value')};
if strcmp(ActionExt,'.sh')
    ActionFullName=fullfile(get(handles.ActionPath,'String'),[ActionName '.sh']);
    if ~exist(ActionFullName,'file')
        answer=msgbox_uvmat('INPUT_Y-N','compiled version has not been created: compile now?');
        if strcmp(answer,'Yes')
            currentdir=pwd;
            cd(get(handles.ActionPath,'String'))
            compile(ActionName)
            cd(currentdir)
        end
    end
    currentdir=pwd;
    cd(get(handles.ActionPath,'String'))
    sh_file=dir([ActionName '.sh']);
    m_file=dir([ActionName '.m']);
    if isfield(m_file,'datenum') && m_file.datenum>sh_file.datenum
        set(handles.ActionExt,'BackgroundColor',[1 1 0])
        drawnow
        answer=msgbox_uvmat('INPUT_Y-N',[ActionName '.sh needs to be updated: recompile now?']);
        if strcmp(answer,'Yes')
            compile(ActionName)
        end
        set(handles.ActionExt,'BackgroundColor',[1 1 1])
    end
    cd(currentdir)
end


function ActionInput_Callback(hObject, eventdata, handles)


% --- Executes on button press in DeleteObject.
function DeleteObject_Callback(hObject, eventdata, handles)
if get(handles.DeleteObject,'Value')
	SeriesData=get(handles.series,'UserData');
    SeriesData.ProjObject=[];
    set(handles.series,'UserData',SeriesData)
    set(handles.ProjObject,'String','')
    set(handles.CheckObject,'Value',0)
    set(handles.DeleteObject,'Visible','off')
    set(handles.ViewObject,'Visible','off')
end

% --- Executes on button press in ViewObject.
function ViewObject_Callback(hObject, eventdata, handles)
if get(handles.ViewObject,'Value')
	UserData=get(handles.series,'UserData');
    set_object(UserData.ProjObject)
else
    hset_object=findobj(allchild(0),'Tag','set_object');
    if ~isempty(hset_object)
        delete(hset_object)
    end 
end


function num_NbProcess_Callback(hObject, eventdata, handles)


function num_NbSlice_Callback(hObject, eventdata, handles)
NbSlice=str2num(get(handles.num_NbSlice,'String'));
set(handles.num_NbProcess,'String',num2str(NbSlice))


