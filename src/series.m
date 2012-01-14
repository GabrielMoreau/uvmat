%'series': master function associated to the GUI series.m for analysis field series  
%------------------------------------------------------------------------
% function varargout = series(varargin)
% associated with the GUI series.fig
%
%INPUT
% param: structure with input parameters (link with the GUI uvmat)
%      .menu_coord_str: string for the transform_fct (menu for coordinate transforms)
%      .menu_coord_val: value for transform_fct (menu for coordinate transforms)
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
function series_OpeningFcn(hObject, eventdata, handles,param)
global nb_builtin_ACTION nb_builtin_transform
% Choose default command line output for series
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
%default initial parameters
drawnow
set(hObject,'Units','pixels')
% set(0,'Units','pixels')
% screensize=get(0,'ScreenSize'); %screen size in pixels
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%allows mouse action with right button (zoom for uicontrol display)
%set(hObject,'Position',[150 100 1000 600] );%position and size in pixels (get adjusted to the screen size in case of excess)
%load the list of previously browsed files in menus Open and Open_1
dir_perso=prefdir;
test_profil_perso=0;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
     h=load (profil_perso);
     test_profil_perso=1;
     if isfield(h,'MenuFile_1')
          set(handles.MenuFile_1,'Label',h.MenuFile_1);
          set(handles.MenuFile_insert_1,'Label',h.MenuFile_1);
     end
     if isfield(h,'MenuFile_1')
          set(handles.MenuFile_2,'Label',h.MenuFile_2);
          set(handles.MenuFile_insert_2,'Label',h.MenuFile_2);
     end
     if isfield(h,'MenuFile_1')
          set(handles.MenuFile_3,'Label',h.MenuFile_3);
          set(handles.MenuFile_insert_3,'Label',h.MenuFile_3);
     end
     if isfield(h,'MenuFile_1')
          set(handles.MenuFile_4,'Label',h.MenuFile_4);
          set(handles.MenuFile_insert_4,'Label',h.MenuFile_4);
     end
     if isfield(h,'MenuFile_1')
          set(handles.MenuFile_5,'Label',h.MenuFile_5);
          set(handles.MenuFile_insert_5,'Label',h.MenuFile_5);
     end
end

%check default input data
if ~exist('param','var')
    param=[]; %default
end

%file name and browser initialisation
if isfield(param,'menu_coord_str')
    set(handles.transform_fct,'String',param.menu_coord_str)
end
if isfield(param,'menu_coord_val')
    set(handles.transform_fct,'Value',param.menu_coord_val);
else
     set(handles.transform_fct,'Value',1);%default
end

if isfield(param,'FileName')
    if isfield(param,'FileName_1')
        update_rootfile(handles,param.FileName_1,0)
        update_rootfile(handles,param.FileName,1)
    else
        update_rootfile(handles,param.FileName,0)
    end
end  

%fields input initialisation
if isfield(param,'list_fields')&& isfield(param,'index_fields') &&~isempty(param.list_fields) &&~isempty(param.index_fields)
    set(handles.FieldMenu,'String',param.list_fields);% list menu fields
    set(handles.FieldMenu,'Value',param.index_fields);% selected string index
    FieldCell{1}=param.list_fields{param.index_fields};
end
% NomType_Callback(hObject, eventdata, handles)
REFRESH_INDICES_Callback(hObject, eventdata, handles)
%loads the information stored in prefdir to initiate  the list of ACTION functions
fct_menu={'check_data_files';'aver_stat';'time_series';'merge_proj';'clean_civ_cmx'};
transform_menu={'';'phys';'px';'phys_polar'};
nb_builtin_ACTION=numel(fct_menu); %number of functions
nb_transform=numel(transform_menu);
[path_series,name,ext]=fileparts(which('series'));
path_series=fullfile(path_series,'series');%path of the function 'series'
addpath (path_series) ; %add the path to UVMAT, (useful in case of change of working directory after civ has been s opened in the working directory)
path_transform=fullfile(path_series,'transform_field');%path to the field transform functions 
for ilist=1:length(fct_menu)
    fct_path{ilist,1}=path_series;%paths of the fuctions buil-in in 'series.m'
end

%TRANSFORM menu: loads the information stored in prefdir to initiate  the list of field transform functions
menu_str={'';'phys';'px';'phys_polar'};
nb_builtin_transform=numel(menu_str); %number of functions
[path_uvmat,name,ext]=fileparts(which('uvmat'));
addpath(fullfile(path_uvmat,'transform_field'))
fct_handle{1,1}=[];
testexist(1)=1;
for ilist=2:length(menu_str)
    if exist(menu_str{ilist},'file')
        fct_handle{ilist,1}=str2func(menu_str{ilist});
        testexist(ilist)=1;
    else
        testexist(ilist)=0;
    end
end
rmpath(fullfile(path_uvmat,'transform_field'))

% read the list of functions stored in the personal file 'uvmat_perso.mat' in prefdir
if test_profil_perso
    if isfield(h,'series_fct') && iscell(h.series_fct)
         for ilist=1:length(h.series_fct)
             [path,file]=fileparts(h.series_fct{ilist});
             fct_path=[fct_path; {path}];%concatene the list of paths
             fct_menu=[fct_menu; {file}];
         end
    end
    if isfield(h,'transform_fct') && iscell(h.transform_fct)
        for ilist=1:length(h.transform_fct);
             [path,file]=fileparts(h.transform_fct{ilist});
             addpath(path)
             if exist(file,'file')
                h_func=str2func(file);
                testexist=[testexist 1];
             else
                h_func=[];
                testexist=[testexist 0]; 
             end
             fct_handle=[fct_handle; {h_func}];%concatene the list of paths
             rmpath(path)
             menu_str=[menu_str; {file}];
        end
    end
end
fct_menu=[fct_menu;{'more...'}];
set(handles.ACTION,'String',fct_menu)
set(handles.ACTION,'UserData',fct_path)% store the list of path in UserData of ACTION

menu_str=menu_str(find(testexist));
fct_handle=fct_handle(find(testexist));
menu_str=[menu_str;{'more...'}];
set(handles.transform_fct,'String',menu_str)
set(handles.transform_fct,'UserData',fct_handle)% store the list of path in UserData of ACTION

% display the GUI for the default action 'check_data_files'
ACTION_Callback(hObject, eventdata, handles) 

%--------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
%-----------------------------------------------------------------
function varargout = series_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function MenuBrowse_Callback(hObject, eventdata, handles)
InputTable=get(handles.InputTable,'Data');
RootPathCell=InputTable(:,1);
SubDirCell=InputTable(:,2);
RootFileCell=InputTable(:,3);
%RootPathCell=get(handles.RootPath,'String');
%SubDirCell=get(handles.SubDir,'String');  
%RootFileCell=get(handles.RootFile,'String');
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
     oldfile=fullfile(RootPathCell{1},SubDirCell{1},RootFileCell{1});
 end
[FileName, PathName, filterindex] = uigetfile( ...
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
%testblank=findstr(fileinput,' ');%look for blanks
% if ~isempty(testblank)
%     errordlg('forbidden input file name: contain blanks')
%     return
% end
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
[path,name,ext]=fileparts(fileinput);
SeriesData=[];%dfault
if isequal(ext,'.xml')
    warndlg_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
elseif isequal(ext,'.xls')
    warndlg_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
else
    update_rootfile(handles,fileinput,0)
     %update list of recent files in the menubar
    MenuFile_1=fileinput;
    MenuFile_2=get(handles.MenuFile_1,'Label');
    MenuFile_3=get(handles.MenuFile_2,'Label');
    MenuFile_4=get(handles.MenuFile_3,'Label');
    MenuFile_5=get(handles.MenuFile_4,'Label');
    set(handles.MenuFile_1,'Label',MenuFile_1)
    set(handles.MenuFile_2,'Label',MenuFile_2)
    set(handles.MenuFile_3,'Label',MenuFile_3)
    set(handles.MenuFile_4,'Label',MenuFile_4)
    set(handles.MenuFile_5,'Label',MenuFile_5)
    set(handles.MenuFile_insert_1,'Label',MenuFile_1)
    set(handles.MenuFile_insert_2,'Label',MenuFile_2)
    set(handles.MenuFile_insert_3,'Label',MenuFile_3)
    set(handles.MenuFile_insert_4,'Label',MenuFile_4)
    set(handles.MenuFile_insert_5,'Label',MenuFile_5)
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-append'); %store the file names for future opening of uvmat
    else
    txt=ver('MATLAB');
    Release=txt.Release;
        relnumb=str2num(Release(3:4));
        if relnumb >= 14
            save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-V6'); %store the file names for future opening of uvmat
        else
            save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5'); %store the file names for future opening of uvmat
        end
    end
end


% --------------------------------------------------------------------
function MenuFile_1_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_1,'Label');
update_rootfile(handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_2_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_2,'Label');
update_rootfile(handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_3_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_3,'Label');
update_rootfile( handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_4_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_4,'Label');
update_rootfile(handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_5_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_5,'Label');
update_rootfile(handles,fileinput,0)

% --------------------------------------------------------------------
function MenuBrowse_insert_Callback(hObject, eventdata, handles)
InputTable=get(handles.InputTable,'Data');
RootPathCell=InputTable(:,1);
SubDirCell=InputTable(:,3);
RootFileCell=InputTable(:,2);
% RootPathCell=get(handles.RootPath,'String'); 
% RootFileCell=get(handles.RootFile,'String');
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
% testblank=findstr(fileinput,' ');%look for blanks
% if ~isempty(testblank)
%     errordlg('forbidden input file name: contain blanks')
%     return
% end
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
[path,name,ext]=fileparts(fileinput);
SeriesData=[];%dfault
if isequal(ext,'.xml')
    msgbox_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
elseif isequal(ext,'.xls')
    msgbox_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
else
    update_rootfile(handles,fileinput,1)
    %update list of recent files in the menubar
    MenuFile_1=fileinput;
    MenuFile_2=get(handles.MenuFile_1,'Label');
    MenuFile_3=get(handles.MenuFile_2,'Label');
    MenuFile_4=get(handles.MenuFile_3,'Label');
    MenuFile_5=get(handles.MenuFile_4,'Label');
    set(handles.MenuFile_1,'Label',MenuFile_1)
    set(handles.MenuFile_2,'Label',MenuFile_2)
    set(handles.MenuFile_3,'Label',MenuFile_3)
    set(handles.MenuFile_4,'Label',MenuFile_4)
    set(handles.MenuFile_5,'Label',MenuFile_5)
    set(handles.MenuFile_insert_1,'Label',MenuFile_1)
    set(handles.MenuFile_insert_2,'Label',MenuFile_2)
    set(handles.MenuFile_insert_3,'Label',MenuFile_3)
    set(handles.MenuFile_insert_4,'Label',MenuFile_4)
    set(handles.MenuFile_insert_5,'Label',MenuFile_5)
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-append'); %store the file names for future opening of uvmat
    else
    txt=ver('MATLAB');
    Release=txt.Release;
        relnumb=str2num(Release(3:4));
        if relnumb >= 14
            save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-V6'); %store the file names for future opening of uvmat
        else
            save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5'); %store the file names for future opening of uvmat
        end
    end
end
%------------------------------------------------

% --------------------------------------------------------------------
function MenuFile_insert_1_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_insert_1,'Label');
update_rootfile(handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_2_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_insert_2,'Label');
update_rootfile(handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_3_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_insert_3,'Label');
update_rootfile( handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_4_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_insert_4,'Label');
update_rootfile( handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_5_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_insert_5,'Label');
update_rootfile(handles,fileinput,1)

%------------------------------------------------------------------------
% ---  refresh the GUI data after introduction of a new file series
% INPUT:
% handles: 
% fileinput: name of the input file
% addtest: =0 to refresh the list of file series, =1 to append a new series to the list (from the menu bar option 'Open_insert')
function update_rootfile(handles,fileinput,addtest)
%------------------------------------------------------------------------  

%% enable other menus and uicontrols
set(handles.MenuOpen_insert,'Enable','on')
set(handles.MenuFile_insert_1,'Enable','on')
set(handles.MenuFile_insert_2,'Enable','on')
set(handles.MenuFile_insert_3,'Enable','on')
set(handles.MenuFile_insert_4,'Enable','on')
set(handles.MenuFile_insert_5,'Enable','on')
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])% set RUN button to red 
% set(handles.RootPath,'BackgroundColor',[1 1 0]) % set RootPath edit box  to yellow
set(handles.InputTable,'BackgroundColor',[1 1 0]) % set RootPath edit box  to yellow
drawnow

%% get the input root name, indices, file extension and nomenclature NomType
if ~exist(fileinput,'file')
    msgbox_uvmat('ERROR',['input file ' fileinput  ' does not exist'])
    return
end
[RootPath,SubDir,RootFile,i1,i2,j1,j2,FileExt,NomType]=fileparts_uvmat(fileinput);

%% determine reference field indices
ref_i=1; %default ref_i is a reference frame index used to find existing pairs from PIV
if ~isempty(i1)
    ref_i=i1;
    if ~isempty(i2)
        ref_i=floor((ref_i+i2)/2);% reference image number corresponding to the file
%         SeriesData.browse_Di=i2-i1;
    end
end
set(handles.ref_i,'String',num2str(ref_i));
set(handles.num_first_i,'String',num2str(ref_i));
set(handles.num_last_i,'String',num2str(ref_i));
ref_j=1; %default  ref_j is a reference frame index used to find existing pairs from PIV
if ~isempty(j1)
    ref_j=j1;
    if ~isempty(j2)
        ref_j=floor((j1+j2)/2);
%         SeriesData.browse_Dj=j2-j1; 
    end          
end
set(handles.ref_j,'String',num2str(ref_j)); 
set(handles.num_first_j,'String',num2str(ref_j))
set(handles.num_last_j,'String',num2str(ref_j)); 
TimeUnit=''; %default
time=[];%default

% read timing and total frame number from the current file (movie files) !! may be overrid by xml file
FileBase=fullfile(RootPath,RootFile);

testima=0; %test for image input
if isequal(lower(FileExt),'.avi') %.avi file
    testima=1;
elseif ~isempty(imformats(FileExt(2:end))) 
    testima=1;
elseif isequal(FileExt,'.vol')
     testima=1;
end

%% fill the list of file series

% insert the current file series at the head of the list
InputTable=get(handles.InputTable,'Data');
if addtest %insert the new data at the first line of the table
     val=size(InputTable,1)+1;
     InputTable(val,:)=[{RootPath},{SubDir},{RootFile},{NomType},{FileExt}];
    check_lines=get(handles.REFRESH_INDICES,'UserData');
else % or re-initialise the list of  input  file series
    val=1;
    InputTable=[{RootPath},{SubDir},{RootFile},{NomType},{FileExt}]
    set(handles.TimeTable,'Data',[{[]},{[]},{[]},{[]}]) 
    set(handles.MinIndex,'Data',[{[]},{[]}])
    set(handles.MaxIndex,'Data',[{[]},{[]}])
end
set(handles.InputTable,'Data',InputTable)
check_lines(val)=1; %select the edited line for refresh
set(handles.REFRESH_INDICES,'UserData',check_lines);
REFRESH_INDICES_Callback([],[], handles)

%store the root name for future opening of uvmat
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    save (profil_perso,'RootPath','SubDir','RootFile','NomType', '-append'); %store the root name for future opening of uvmat
else
    txt=ver('MATLAB');
    Release=txt.Release;
    relnumb=str2num(Release(3:4));
    if relnumb >= 14
        save (profil_perso,'RootPath','SubDir','RootFile','NomType','-V6') %store the root name for future opening of uvmat
    else
        save(profil_perso,'RootPath','SubDir','RootFile','NomType')
    end         
end
set(handles.InputTable,'BackgroundColor',[1 1 1])
% set(handles.PathCampaign,'String',SeriesData.PathCampaign)
%num_last_j_Callback([], [], handles)% TODO:update
%num_last_i_Callback([], [], handles)

% %------------------------------------------------------------------------
% function RootPath_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% Val=get(handles.RootPath,'Value');
% synchronise_view(handles,Val)
% NomType_Callback(hObject, eventdata, handles)

% %------------------------------------------------------------------------
% function synchronise_view(handles,Val)
% %------------------------------------------------------------------------
% set(handles.RootPath,'Value',Val)
% set(handles.SubDir,'Value',Val)
% set(handles.RootFile,'Value',Val)
% set(handles.NomType,'Value',Val)
% set(handles.FileExt,'Value',Val)
% set(handles.num_MaxIndex_i,'Value',Val)
% set(handles.num_MaxIndex_j,'Value',Val)
% % set(handles.time_first,'Value',Val)
% % set(handles.time_last,'Value',Val)


% %------------------------------------------------------------------------
% % Executes on carriage return on the subdir civ1 edit window
% function SubDir_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% Val=get(handles.SubDir,'Value');
% synchronise_view(handles,Val)
% NomType_Callback(hObject, eventdata, handles)

% %------------------------------------------------------------------------
% % --- function activated when a new filebase (image series) is introduced
% function RootFile_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% Val=get(handles.RootFile,'Value');
% synchronise_view(handles,Val)
% NomType_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------
% %function activated when a new filebase (image series) is introduced
% %------------------------------------------------------------
% function FileExt_Callback(hObject, eventdata, handles)
% Val=get(handles.FileExt,'Value');
% synchronise_view(handles,Val)

% %--------------------------------------------------------------
% %function activated when a new filebase (image series) is introduced
% %------------------------------------------------------------
% function num_MaxIndex_i_Callback(hObject, eventdata, handles)
% Val=get(handles.num_MaxIndex_i,'Value');
% synchronise_view(handles,Val)

% %--------------------------------------------------------------
% %function activated when a new filebase (image series) is introduced
% %------------------------------------------------------------
% function num_MaxIndex_j_Callback(hObject, eventdata, handles)
% Val=get(handles.num_MaxIndex_j,'Value');
% synchronise_view(handles,Val)
% 
% %--------------------------------------------------------------
% %function activated when a new filebase (image series) is introduced
% %------------------------------------------------------------
% function time_first_Callback(hObject, eventdata, handles)
% Val=get(handles.time_first,'Value');
% synchronise_view(handles,Val)
% 
% %--------------------------------------------------------------
% %function activated when a new filebase (image series) is introduced
% %------------------------------------------------------------
% function time_last_Callback(hObject, eventdata, handles)
% Val=get(handles.time_last,'Value');
% synchronise_view(handles,Val)
% NomType_Callback(hObject, eventdata, handles)

% %------------------------------------------------------------------------
% function NomType_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------

% --- Executes when entered data in editable cell(s) in InputTable.
function InputTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to InputTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
eventdata
check_lines=get(handles.REFRESH_INDICES,'UserData');
check_lines(eventdata.Indices(1))=1; %select the edited line for refresh
set(handles.REFRESH_INDICES,'UserData',check_lines);
set(handles.REFRESH_INDICES,'Visible','on')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%????????????
% --- Executes on button press in mode.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function mode_Callback(hObject, eventdata, handles)
        
        SeriesData=get(handles.series,'UserData');
        mode_list=get(handles.mode,'String');
        mode_value=get(handles.mode,'Value');
        mode=mode_list{mode_value};
%         NomType=[];
        % test_find_pair=0;
        % if isfield(SeriesData,'NomType')
%         NomTypeCell=SeriesData.NomType;
%         Val=get(handles.NomType,'Value');
%         NomType=NomTypeCell{Val};
% check_pairs=0;
% for 
%         check_pairs=~isempty(SeriesData.i2_series{Val})||~isempty(SeriesData.j2_series{Val});
        
        time=[];
        if isfield(SeriesData,'Time')
            time=SeriesData.Time{1}; %get the set of times
        end
%         siztime=size(time);
%         nbfield=siztime(1);
%         nbfield2=siztime(2);
        % indchosen=1;  %%first pair selected by default
        if isequal(mode,'bursts')
            enable_i(handles,'On')
            enable_j(handles,'Off') %do not display j index scanning in burst mode (j is fixed by the burst choice)
%         elseif  ~isempty(SeriesData.j2_series{Val})
%             enable_i(handles,'On')
%             enable_j(handles,'On') % allow both i and j index scanning
        else
            enable_i(handles,'On')
            enable_j(handles,'Off')
        end
        % set(handles.list_pair_civ,'Value',indchosen);%set the default choice of image pairs for civ1
%         set(handles.series,'UserData',SeriesData)
        
        %list pairs if relevant
%         if check_pairs
            find_netcpair_civ(handles)
%         end

%-------------------------------------
function enable_i(handles,state)
set(handles.i_txt,'Visible',state)
set(handles.num_first_i,'Visible',state)
set(handles.num_last_i,'Visible',state)
set(handles.num_incr_i,'Visible',state)
% set(handles.num_MaxIndex_i,'Visible',state)
set(handles.ref_i,'Visible',state)
set(handles.ref_i_text,'Visible',state)

%-----------------------------------
function enable_j(handles,state)
set(handles.j_txt,'Visible',state)
% set(handles.num_MinIndex_j,'Visible',state)
set(handles.num_first_j,'Visible',state)
set(handles.num_last_j,'Visible',state)
set(handles.num_incr_j,'Visible',state)
% set(handles.num_MaxIndex_j,'Visible',state)
set(handles.ref_j,'Visible',state)
set(handles.ref_j_text,'Visible',state)

%-----------------------------------
function view_FieldMenu(handles,state)
% set(handles.FieldMenu,'Visible',state)
% set(handles.Field_text,'Visible',state)
set(handles.InputFields,'Visible',state)

%-----------------------------------
function view_FieldMenu_1(handles,state)
set(handles.FieldMenu_1,'Visible',state)
set(handles.Field_text_1,'Visible',state)

% %-----------------------------------
% function view_TRANSFORM(handles,state)
% set(handles.TRANSFORM_frame,'Visible',state)
% set(handles.transform_fct,'Visible',state);
% set(handles.TRANSFORM_title,'Visible',state)

%--------------------------------------------------------------
% determine the menu for civ1 pairs depending on existing netcdf files 
% with the reference indices ref_i and ref_j
%----------------------------------------------------------------
function find_netcpair_civ(handles)
SeriesData=get(handles.series,'UserData'); 
% NomTypeCell=get(handles.NomType,'String');
% NomTypeCell=SeriesData.NomType;
% NomType=NomTypeCell{Val};

set(handles.Pairs,'Visible','on')% makes the panel "Pairs' visible
%nomenclature types
% RootPathCell=get(handles.RootPath,'String');
% filepath=RootPathCell{Val};
% RootFileCell=get(handles.RootFile,'String');
% filename=RootFileCell{Val};
% filebase=fullfile(filepath,filename);
% SubDirCell=get(handles.SubDir,'String');
% subdir=SubDirCell{Val};
% if ~exist(fullfile(filepath,subdir),'dir') 
%          msgbox_uvmat('ERROR',['no civ file available: subdirectory ' subdir ' does not exist'])
%          set(handles.list_pair_civ,'String',{''});
%          return
% end
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};

%reads image numbers from the interface
% ref_i=str2num(get(handles.ref_i,'String'));
% ref_j=str2num(get(handles.ref_j,'String'));
% ref_time=0;
% nbfield=50;
% nbfield2=50;%default max number of pairs

%look for existing processed pairs involving the field at the middle of the series if civ1 will not 
% be performed, while the result is needed for next steps.

% ind_exist=0;
TimeUnit=get(handles.TimeUnit,'String');
if length(TimeUnit)>=1
    dtunit=['m' TimeUnit];
else
    dtunit='e-03';
end

%% NEW
for Val=1:numel(SeriesData.i1_series)
    
i1_series=SeriesData.i1_series{Val};
i2_series=SeriesData.i2_series{Val};
j1_series=SeriesData.j1_series{Val};
j2_series=SeriesData.j2_series{Val};
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
            displ_pair=[displ_pair;{['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ]}];
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
            displ_pair=[displ_pair;{['Dj= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ]}];
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
end
%% display list of pairs
displ_pair_list=get(handles.list_pair_civ,'String');
NewVal=[];
if ~isempty(displ_pair_list)
Val=get(handles.list_pair_civ,'Value');
NewVal=find(strcmp(displ_pair_list{Val},displ_pair),1);% look at the previous display in the new menu displ_pâir
end
if ~isempty(NewVal)
    set(handles.list_pair_civ,'Value',NewVal)
else
    set(handles.list_pair_civ,'Value',1)
end
set(handles.list_pair_civ,'String',displ_pair)
displ_pair

 %   displ_pair{ind_exist}=['Di= ' num2str(-floor(index/2)) '|' num2str(ceil(index/2)) ' :dt= ' num2str(dt*1000) dtunit];
% if strcmp(mode,'series(Di)') 
%      for index=1:min(nbfield-1,50)
%          filename=name_generator(filebase,ref_i-floor(index/2),ref_j,'.nc',NomType,1,ref_i+ceil(index/2),ref_j,subdir);
%          select=(exist(filename,'file')==2);
%          if select==1
%                ind_exist=ind_exist+1;
%                 displ_num(1,ind_exist)=0;
%                 displ_num(2,ind_exist)=0;
%                 displ_num(3,ind_exist)=-floor(index/2);
%                 displ_num(4,ind_exist)=ceil(index/2);
%                 %[cte_detect,vdt,cte_read]=read_netcdf(filename,{'dt','dt2','absolut_time_T0','absolute_time_TO_2'});
%                 [Cte,var_detect,ichoice]=nc2struct(filename,{});
%                 if isfield(Cte,'dt2')
%                     dt=Cte.dt2;
%                 elseif isfield(Cte,'dt')
%                     dt=Cte.dt;
%                 end
%                 if isfield(Cte,'absolut_time_TO_2')
%                     ref_time(ind_exist)=Cte.absolut_time_TO_2;%civ2 data used in priority
%                 elseif isfield(Cte,'absolut_time_TO')
%                     ref_time(ind_exist)=Cte.absolut_time_TO;%civ2 data used in priorit
%                 elseif isfield(Cte,'Time')
%                     ref_time(ind_exist)=Cte.Time;
%                 end
%                 displ_pair{ind_exist}=['Di= ' num2str(-floor(index/2)) '|' num2str(ceil(index/2)) ' :dt= ' num2str(dt*1000) dtunit];
%          end
%      end
%      set(handles.list_pair_civ,'String',[displ_pair';{'Di=*|*'}]);   
% elseif isequal(mode,'series(Dj)')% series on the j index
%        for index=1:min(nbfield2-1,50)
%            filename=name_generator(filebase,ref_i,ref_j-floor(index/2),'.nc',NomType,1,ref_i,ref_j+ceil(index/2),subdir);
%            select=(exist(filename,'file')==2);
%            if select==1
%                ind_exist=ind_exist+1;
%                 displ_num(1,ind_exist)=-floor(index/2);
%                 displ_num(2,ind_exist)=ceil(index/2);
%                 displ_num(3,ind_exist)=0;
%                 displ_num(4,ind_exist)=0;
%                 [Cte,var_detect,ichoice]=nc2struct(filename,{});
%                 if isfield(Cte,'dt2')
%                     dt=Cte.dt2;
%                 elseif isfield(Cte,'dt')
%                     dt=Cte.dt;
%                 end
%                 if isfield(Cte,'absolut_time_TO_2')
%                     ref_time(ind_exist)=Cte.absolut_time_TO_2;%civ2 data used in priority
%                 elseif isfield(Cte,'absolut_time_TO')
%                     ref_time(ind_exist)=Cte.absolut_time_TO;%civ2 data used in priorit
%                 elseif isfield(Cte,'Time')
%                     ref_time(ind_exist)=Cte.Time;
%                 end
%                 displ_pair{ind_exist}=['Dj= ' num2str(-floor(index/2)) '|' num2str(ceil(index/2)) ' :dt= ' num2str(dt*1000) dtunit];
%            end
%        end
%        set(handles.list_pair_civ,'String',[displ_pair';{'Dj=*|*'}]);
% elseif isequal(mode,'bursts') %case of bursts
%     for numod_a=1:nbfield2-1 %nbfield2 always >=2 for 'bursts' mode
%         for numod_b=(numod_a+1):nbfield2
%             [filename]=name_generator(filebase,ref_i,numod_a,'.nc',NomType,1,ref_i,numod_b,subdir)
%             select=(exist(filename,'file')==2)
%             if select==1
%                 ind_exist=ind_exist+1;
%                 numlist_a(ind_exist)=numod_a;
%                 numlist_b(ind_exist)=numod_b;
%                 Attr=nc2struct(filename,[]);
%                 isfield(Attr,'absolut_time_T0_2')
%                 if isfield(Attr,'dt2')
%                    dt(ind_exist)=Attr.dt2;
%                    ref_time(ind_exist)=Attr.absolut_time_T0_2;
%                 elseif isfield(Attr,'dt')& isfield(Attr,'absolut_time_T0')
%                    dt(ind_exist)=Attr.dt;
%                    ref_time(ind_exist)=Attr.absolut_time_T0;
%                 else
%                    dt(ind_exist)=NaN;%no information on dt
%                 end
%                 %determine nom_type_ima for pair display (used in num2stra.m)
%                 switch NomType
%                     case {'#ab'}
%                         nom_type_ima='#a';
%                     case {'#AB'}
%                         nom_type_ima='#A';
%                     otherwise
%                          nom_type_ima='_1_1';
%                 end
%                displ_pair{ind_exist}=['j= ' num2stra(numod_a,nom_type_ima,2) '-' num2stra(numod_b,nom_type_ima,2) ...
%                         ' :dt= ' num2str(dt(ind_exist)*1000)];
%             end
%          end
%          set(handles.list_pair_civ,'String',[displ_pair';{'j=*-*'}]);
%      end
%      if exist('dt','var') & ~isempty(dt)
%          [dtsort,indsort]=sort(dt);
%          displ_num(1,:)=numlist_a(indsort);
%          displ_num(2,:)=numlist_b(indsort);
%          displ_num(3,:)=0;
%          displ_num(4,:)=0;
%          displ_pair=displ_pair(indsort);
%          ref_time=ref_time(indsort);
%      end
% end
if isempty(displ_pair)
    msgbox_uvmat('ERROR',['no file available for the selected subdirectory ' subdir])
end
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%END FUNCTION


if ind_exist==0
         if  isequal(mode,'series(Dj)') | isequal(mode,'st_series(Dj)') 
            msgbox_uvmat('ERROR',['no .nc file available for the selected reference index j=' num2str(ref_j) ' and subdirectory ' subdir])
        else
            msgbox_uvmat('ERROR',['no .nc file available for the selected reference index i=' num2str(ref_i) ' and subdirectory ' subdir])
        end
        if isequal(mode,'bursts') %case of bursts
            set(handles.list_pair_civ,'String',{'j=*-*'});
        elseif isequal(mode,'series(Di)') %case of bursts
            set(handles.list_pair_civ,'String',{'Di=*|*'});
        elseif isequal(mode,'series(Dj)') %case of bursts
            set(handles.list_pair_civ,'String',{'Dj=*|*'});
        end
end
return
%TO update
val=get(handles.list_pair_civ,'Value');
if val > length(displ_pair)
    set(handles.list_pair_civ,'Value',1);% first pair proposed by default in the menu
    val=1;
end
iview=get(handles.NomType,'Value');
SeriesData.displ_num(iview,:)=(displ_num(:,val))';
SeriesData.ref_time=ref_time;
set(handles.series,'UserData',SeriesData)
list_pair_civ_Callback([],[],handles)

%-------------------------------------------------------------
% --- Executes on selection in list_pair_civ.
function list_pair_civ_Callback(hObject,eventdata,handles)
%------------------------------------------------------------
return
%%%%%%%%
%update num_first_i and num_last_i according to the chosen image pairs 
testupdate=0;
Val=get(handles.RootPath,'Value');
IndexCell=get(handles.NomType,'String');
SeriesData=get(handles.series,'UserData');
NomType=SeriesData.NomType{Val};
list_pair=get(handles.list_pair_civ,'String');%get the menu of image pairs
index_pair=get(handles.list_pair_civ,'Value');
str_pair=list_pair{index_pair};
ind_equ=strfind(str_pair,'=');%find '='
ind_sep=strfind(str_pair,'|');%find pair separator '|'
ind_com=strfind(str_pair,':');%find ':'
test_bursts=0;
if isempty(ind_sep)
    ind_sep=strfind(str_pair,'-');%find pair separator if it is not '|'
    test_bursts=1;% we are in the case of bursts
end
displ_num=[0 0 0 0]; %default
if ~isempty(ind_sep)&& ~strcmp(str_pair(ind_sep-1),'*')% if there is a pair separator ('|' or '-')
    num1_str=str_pair(ind_equ(1)+1:ind_sep-1);
    num2_str=str_pair(ind_sep+1:ind_com-1);
    num1=str2double(num1_str);
    num2=str2double(num2_str);
    if isequal(num1_str(1),' ')
        num1_str(1)=[];
    end   
    if isequal(num2_str(end),' ')
        num2_str(end)=[];
    end
    switch NomType
       case {'_1-2_1'}
           if isequal(num1_str(1),'0')
               IndexCell{Val}=['_(i-(i+' num2_str ')_j'];
           else
               IndexCell{Val}=['_(i' num1_str ')-(i+' num2_str ')_j'];
           end
           displ_num(3)=num1;
           displ_num(4)=num2;
       case {'_1-2'}
           if isequal(num1_str(1),'0')
               IndexCell{Val}=['_(i' num1_str ')-(i+' num2_str ')'];
           else
               IndexCell{Val}=['_(i' num1_str ')-(i+' num2_str ')'];
           end
           displ_num(3)=num1;
           displ_num(4)=num2;
       case '_1_1-2'
          if test_bursts
              IndexCell{Val}=['_i_' num1_str '-' num2_str ];
          else
              if isequal(num1_str(1),'0')
                 IndexCell{Val}=['_i_j-(j+' num2_str ')'];
              else
                 IndexCell{Val}=['_i_(j' num1_str ')-(j+' num2_str ')'];
              end
          end
          displ_num(1)=num1;
          displ_num(2)=num2;
       case {'#_ab'} %TO COMPLETE
           IndexCell{Val}=['_i_' num1_str '-' num2_str ];

    end
end
set(handles.NomType,'String',IndexCell)
SeriesData.displ_num(Val,:)=displ_num;
set(handles.series,'UserData',SeriesData)
% set(handles.NomType,'Value',Val)

if ~isequal(str_pair,'Dj=*|*')&~isequal(str_pair,'Di=*|*')
	mode_list=get(handles.mode,'String');
    mode_value=get(handles.mode,'Value');
    mode=mode_list{mode_value};
	if isequal(mode,'series(Di)')
        first_i=str2num(get(handles.num_first_i,'String'));
        last_i=str2num(get(handles.num_last_i,'String'));
        incr_i=str2num(get(handles.num_incr_i,'String'));
        num1=first_i:incr_i:last_i;
        lastfieldCell=get(handles.num_MaxIndex_i,'String');
        lastfield=str2num(lastfieldCell{1});
        if ~isempty(lastfield)
            ind=find((num1-floor(index_pair/2)*ones(size(num1))>0)& (num1+ceil(index_pair/2)*ones(size(num1))<=lastfield));
            num1=num1(ind);       
        end
        if ~isempty(num1)
            set(handles.num_first_i,'String',num2str(num1(1)));
            set(handles.num_last_i,'String',num2str(num1(end)));
        end
        testupdate=1;
	elseif isequal(mode,'series(Dj)')
        first_j=str2num(get(handles.num_first_j,'String'));
        last_j=str2num(get(handles.num_last_j,'String'));
        incr_j=str2num(get(handles.num_incr_j,'String'));
        num_j=first_j:incr_j:last_j;
        lastfieldCell=get(handles.num_MaxIndex_j,'String');
        if ~isempty(lastfieldCell)
            lastfield2=lastfieldCell{1};
            ind=find((num_j-floor(index_pair/2)*ones(size(num_j))>0)& ...
                 (num_j+ceil(index_pair/2)*ones(size(num_j))<=lastfield2));
        end
        testupdate=1;
	end 
	
	%update the first and last times of the series
	if testupdate && isfield(SeriesData,'Time')
        if ~isempty(SeriesData.Time{1})
            displ_time(handles);
        end
	end
end

%------------------------------------------------------------------------
% --- Executes on button press in RUN.
function RUN_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%% Read parameters from series
Series=read_GUI(handles.series)%TODO: extend to all input param
Series.hseries=handles.series; % handles to the series GUI

%% read root name and field type
set(handles.RUN,'BusyAction','queue');
set(0,'CurrentFigure',handles.series)
if isequal(get(handles.GetObject,'Visible'),'on') && isequal(get(handles.GetObject,'Value'),1) 
    Series.GetObject=1;
    GetObject_Callback(hObject, eventdata, handles)
else
    Series.GetObject=0;
end
% SeriesData=get(handles.series,'UserData');

% Series.hseries=handles.series; % handles to the series GUI
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
    incr_j=Series.IndexRange.incr_j;
    last_j=Series.IndexRange.last_j;
end

%% read input file parameters and set menus
Series.PathProject=get(handles.PathCampaign,'String');
% InputTable=get(handles.InputTable,'Data');
RootPath=Series.InputTable(:,1);
SubDir=Series.InputTable(:,2);
RootFile=Series.InputTable(:,3);
NomType=Series.InputTable(:,4);
FileExt=Series.InputTable(:,5);
% if isempty(SeriesData)
%     msgbox_uvmat('ERROR','no input file series')
%     return
% end
% NomType=SeriesData.NomType;
% if length(RootPath)==1 %string character input for user fct
%     Series.RootPath=RootPath{1};
%     Series.RootFile=RootFile{1};
%     Series.SubDir=SubDir{1};
%     Series.FileExt=FileExt{1};
%     Series.NomType=NomType{1};
% else %cell input for user fct
%     Series.RootPath=RootPath;
%     Series.RootFile=RootFile;
%     Series.SubDir=SubDir;
%     Series.FileExt=FileExt;
%     Series.NomType=NomType;
% end
% if isequal(get(handles.FieldMenu,'Visible'),'on')
%     FieldMenu=get(handles.FieldMenu,'String');
%     FieldValue=get(handles.FieldMenu,'Value');
%     Series.Field=FieldMenu(FieldValue);
% end
menu_coord_state=get(handles.transform_fct,'Visible');
Series.CoordType='';%default
if isequal(menu_coord_state,'on')
%     menu_coord=get(handles.transform_fct,'String');
    menu_index=get(handles.transform_fct,'Value');
    transform_list=get(handles.transform_fct,'UserData');
    Series.transform_fct=transform_list{menu_index};% transform function handles
end

%reinitiate waitbar position
Series.WaitbarPos=get(handles.waitbar_frame,'Position');%TO SUPPRESS
waitbarpos=Series.WaitbarPos;
waitbarpos(4)=0.005;%reinitialize waitbar to zero height
waitbarpos(2)=Series.WaitbarPos(2)+Series.WaitbarPos(4)-0.005;
% set(handles.waitbar,'Position',waitbarpos)

if isfield(Series.IndexRange,'NbSlice')
Series.NbSlice=Series.IndexRange.NbSlice;
end
if last_i < first_i | last_j < first_j , msgbox_uvmat('ERROR','last field number must be larger than the first one'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
num_i=first_i:incr_i:last_i;
num_j=first_j:incr_j:last_j;
% nbfield_cell=get(handles.num_MaxIndex_i,'String');
nbfield=cell2mat(Series.IndexRange.MaxIndex);
nb=min(nbfield,1);
% nbfield=nb(1);
% nbfield2=nb(2);

%get complementary information from the 'series' interface
list_action=get(handles.ACTION,'String');% list menu action
index_action=get(handles.ACTION,'Value');% selected string index
action= list_action{index_action}; % selected string
mode_list=get(handles.mode,'String');
index_mode=get(handles.mode,'Value');
mode=mode_list{index_mode};
ind_shift=0;%default

%determine the list of input file names
nbmissing=0;
% for iview=1:length(RootPath)
%     %case of pairs (.nc files)
%     fileinput=name_generator(fullfile(RootPath{iview},RootFile{iview}),first_i,first_j,FileExt{iview},NomType{iview},1,first_i+1,first_j+1,SubDir{iview});
%     if strcmp(get(handles.Pairs,'Visible'),'on')
%        pair_list=get(handles.list_pair_civ,'String');
%        val=get(handles.list_pair_civ,'Value');
%        pair_string=pair_list{val};
%        r=regexp(pair_string,'.*\D(?<num1>[\d+|*])(?<delim>[-||])(?<num2>[\d+|*])','names');
%        if ~isempty(r)
%            if strcmp(r.num1,'*')%free pairs
%                [tild,RootFile,i1_series,i2_series,j1_series,j2_series,tild,tild,Object]=find_file_series(fileinput);% TODO: choice pair when multiple choice
%  
%                if isempty(i2_series) %j pairs
%                    ind_sel=i1_series>=i1_series>=first_i & i1_series<=last_i & j1_series>first_j & j2_series<last_j;
%                    j2_series=j2_series(ind_sel);
%                else%i pairs
%                    if isempty(j1_series) %j pairs
%                         ind_sel=i1_series>=first_i & i2_series<=last_i ;
%                    else
%                        ind_sel=i1_series>=first_i & i2_series<=last_i& j1_series>first_j & j1_series<last_j; 
%                        j1_series=j1_series(ind_sel);
%                        i2_series=i2_series(ind_sel);
%                    end
%                end
%                i1_series=i1_series(ind_sel);             
%            else
%                if strcmp(r.delim,'-')
%                    ind_shift(1)=str2num(r.num1);
%                    ind_shift(2)=str2num(r.num2);
%                else
%                    ind_shift(1)=-str2num(r.num1);
%                    ind_shift(2)=str2num(r.num2);
%                end
%                [i1_series,i2_series,j1_series,j2_series,nbmissing]=find_file_indices(num_i,num_j,ind_shift,NomType{iview},mode);
%            end
%        end
%        if isempty(i1_series)
%            msgbox_uvmat('ERROR','no file in the considered range')
%            return
%        end
%        if isempty(i2_series)
%            i2_series=i1_series;
%        end
%        if isempty(j2_series)
%            j2_series=j1_series;
%        end 
%     else%case of images
%         [i1_series,j1_series]=meshgrid(num_i,num_j);
%         i2_series=i1_series;
%         j2_series=j1_series;
%     end
%     if length(RootPath)>1
%         i1_series_cell{iview}=i1_series;
%         i2_series_cell{iview}=i2_series;
%         j1_series_cell{iview}=j1_series;
%         j2_series_cell{iview}=j2_series;
%     end
% end

%% defining the ACTION function handle
path_series=which('series');
list_path=get(handles.ACTION,'UserData');
index=get(handles.ACTION,'Value');
fct_path=list_path{index}; %path stored for the function ACTION
if ~isequal(fct_path,path_series)
    eval(['spath=which(''' action ''');']) %spath = current path of the selected function ACTION
    if ~exist(fct_path,'dir')
        msgbox_uvmat('ERROR',['The prescibed function path ' fct_path ' does not exist'])
        return
    end
    if ~isequal(spath,fct_path)
        addpath(fct_path)% add the prescribed path if not the current one
    end
end
eval(['h_fun=@' action ';'])%create a function handle for ACTION
if ~isequal(fct_path,path_series)
        rmpath(fct_path)% add the prescribed path if not the current one    
end

%% RUN ACTION
Series.Action=action;%name of the processing programme
Series
set(handles.RUN,'BackgroundColor',[0.831 0.816 0.784])
h_fun(Series);
% if length(RootPath)>1
%     h_fun(i1_series_cell,i2_series_cell,j1_series_cell,j2_series_cell,Series);
% else
%     h_fun(i1_series,i2_series,j1_series,j2_series,Series);
% end
set(handles.RUN,'BackgroundColor',[1 0 0])

% %save the current interface setting as figure namefig, append .0 to the name if it already exists
% detect=1; 
% while detect==1
%     namefigfull=[namedoc '.fig'];
%     hh=dir(namefigfull);
%     if ~isempty(hh)
%         detect=1;
%         namedoc=[namedoc '.0'];
%     else
%         detect=0;
%     end
% end
% saveas(gcbf,namefigfull);%save the interface with name namefigfull (A CHANGER EN FICHIER  .xml)

%------------------------------------------------------------------------
function STOP_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RUN, 'BusyAction','cancel')
set(handles.RUN,'BackgroundColor',[1 0 0])


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
set(handles.ref_j,'String', num2str(ref_j))
ref_j_Callback(hObject, eventdata, handles)
SeriesData=get(handles.series,'UserData');
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
displ_time(handles);


%------------------------------------------------------------------------
function ref_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
SeriesData=get(handles.series,'UserData');
%NomTypeCell=get(handles.NomType,'String');
NomTypeCell=SeriesData.NomType;
if ~isempty(NomTypeCell)
Val=get(handles.NomType,'Value');
NomType=NomTypeCell{Val};
% for ilist=1:length(NomType)
    if isequal(NomType,'_1_1-2')|| isequal(NomType,'_1-2_1')|| isequal(NomType,'_1-2')
        if isequal(mode,'series(Di)') 
            find_netcpair_civ(handles,Val);% update the menu of pairs depending on the available netcdf files
%             break
        end
    end
end

%------------------------------------------------------------------------
function ref_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
SeriesData=get(handles.series,'UserData');
NomTypeCell=SeriesData.NomType;
if ~isempty(NomTypeCell)
    Val=get(handles.NomType,'Value');
    NomType=NomTypeCell{Val};
    if isequal(NomType,'_1_1-2')|| isequal(NomType,'_1-2_1')|| isequal(NomType,'_1-2')
        if isequal(mode,'series(Dj)') 
            find_netcpair_civ(handles,Val);% update the menu of pairs depending on the available netcdf files
        end
    end
end

%------------------------------------------------------------------------
% --- Executes on selection change in ACTION.
function ACTION_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
global nb_builtin_ACTION
list_ACTION=get(handles.ACTION,'String');% list menu fields
index_ACTION=get(handles.ACTION,'Value');% selected string index
ACTION= list_ACTION{index_ACTION}; % selected function name
path_series=which('series');%path to series.m
list_path=get(handles.ACTION,'UserData');%list of recorded paths to functions of the list ACTION
default_file=fullfile(list_path{end},ACTION);
% add a new function to the menu if the selected item is 'more...'
if isequal(ACTION,'more...')
    pathfct=fileparts(path_series);
    [FileName, PathName, filterindex] = uigetfile( ...
       {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',default_file);
    if length(FileName)<2
        return
    end 
    [pp,ACTION,ext_fct]=fileparts(FileName);%(end-1:end);
    if ~isequal(ext_fct,'.m')
        msgbox_uvmat('ERROR','a Matlab function .m must be introduced');
        return
    end
    
   % insert the choice in the action menu
   menu_str=update_menu(handles.ACTION,ACTION);%new action menu in which the new item has been appended if needed
   index_ACTION=get(handles.ACTION,'Value');% currently selected index in the list
   list_path{index_ACTION}=PathName;
   if length(menu_str)>nb_builtin_ACTION+5; %nb_builtin=nbre of functions always remaining in the initial menu
       nbremove=length(menu_str)-nb_builtin_ACTION-5;
       menu_str(nb_builtin_ACTION+1:end-5)=[];
       list_path(nb_builtin_ACTION+1:end-4)=[];
       index_ACTION=index_ACTION-nbremove;
       set(handles.ACTION,'Value',index_ACTION)
       set(handles.ACTION,'String',menu_str)
   end
   list_path{index_ACTION}=PathName;
   set(handles.ACTION,'UserData',list_path);
   set(handles.path,'enable','inactive')% indicate that the current path is accessible (not 'off')
   
   %record the current menu in personal file profil_perso
   dir_perso=prefdir;
   profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
   for ilist=nb_builtin_ACTION+1:length(menu_str)-1
       series_fct{ilist-nb_builtin_ACTION}=fullfile(list_path{ilist},[menu_str{ilist} '.m']);      
   end
   if nb_builtin_ACTION+1<=length(menu_str)-1
       if exist(profil_perso,'file')% && nb_builtin_ACTION+1>=length(menu_str)-1
           save(profil_perso,'series_fct','-append')
       else
           txt=ver('MATLAB');
           Release=txt.Release;
           relnumb=str2num(Release(3:4));
           if relnumb >= 14%recent relaese of Matlab
               save(profil_perso,'series_fct','-V6')
           else
               save(profil_perso, 'series_fct')
           end
       end
   end
end

%check the current path to the selected function
PathName=list_path{index_ACTION};%current recorded path
set(handles.path,'String',PathName); %show the path to the senlected function

%default setting for the visibility of the GUI elements
% set(handles.RootPath,'UserData','many')
% set(handles.SubDir,'Visible','on')
% set(handles.RootFile,'Visible','on')
% set(handles.NomType,'Visible','on')
% set(handles.FileExt,'Visible','on')
set(handles.num_NbSlice,'Visible','off')
set(handles.NbSlice_title,'Visible','off')
set(handles.VelTypeMenu,'Visible','off');
set(handles.VelType_text,'Visible','off');
set(handles.VelTypeMenu_1,'Visible','off');
set(handles.VelType_text_1,'Visible','off');
view_FieldMenu(handles,'off')
view_FieldMenu_1(handles,'off')
set(handles.FieldTransform,'Visible','off')
% view_TRANSFORM(handles,'off')Visible','off')
set(handles.Objects,'Visible','off');
set(handles.GetMask,'Visible','off')
set(handles.Mask,'Visible','off')
% set(handles.GetObject,'Visible','off');
set(handles.OutputDir,'Visible','off');
% set(handles.PARAMETERS_frame,'Visible','off');
% set(handles.PARAMETERS_title,'Visible','off');
set(handles.ParamKey,'Visible','off')
set(handles.ParamVal,'Visible','off')
ParamKey={};
set(handles.FieldMenu,'Enable','off')
set(handles.VelTypeMenu,'Enable','off')
set(handles.FieldMenu_1,'Enable','off')
set(handles.VelTypeMenu_1,'Enable','off')
set(handles.transform_fct,'Enable','off')
%set the displayed GUI item needed for input parameters
if ~isequal(path_series,PathName)
    addpath(PathName)
end
eval(['h_function=@' ACTION ';']);
try
    [fid,errormsg] =fopen([ACTION '.m']);
    InputText=textscan(fid,'%s',1,'delimiter','\n');
    fclose(fid)
    set(handles.ACTION,'ToolTipString',InputText{1}{1})
end
if ~isequal(path_series,PathName)
    rmpath(PathName)
end
varargout=h_function();
Param_list={};

%nb_series=length(RootFile);
% FileExt=get(handles.FileExt,'String');
% nb_series=length(FileExt);
InputFiles=get(handles.InputTable,'Data')
FileExt=InputFiles(:,5);
checkcell=find(cellfun('isempty',FileExt)~=0);
nb_series=0;
if ~isempty(checkcell)
nb_series=checkcell(end);
end
% nb_series=size(InputFiles,1)
testima_series=1; %test for a list of images only
testima=1;
testima_1=1;
testciv_series=1;
for iview=1:nb_series
     ext=FileExt{iview};
    if length(ext)<2
        ext='.none';
    end
    testimaview=~isempty(imformats(ext(2:end))) || isequal(lower(ext),'.avi');
    if ~testimaview
        if iview==1
            testima=0;
        end
        if iview==2
            testima_1=0;
        end
        testima_series=0;
    end
end
for ilist=1:length(varargout)-1
    switch varargout{ilist}
                       %RootFile always visible
%          case 'RootPath'   %visible by default
%             value=lower(varargout{ilist+1});
%             if isequal(value,'one')||isequal(value,'two')||isequal(value,'many')
%                 set(handles.RootFile,'UserData',value)% for use in menu Open_insert
%             end
%         case 'SubDir' %visible by default
%             if isequal(lower(varargout{ilist+1}),'off')
%                 set(handles.SubDir,'Visible','off')
%             end
%         case 'RootFile'   %visible by default
%             value=lower(varargout{ilist+1});
%             if isequal(value,'off')
%                 set(handles.RootFile,'Visible','off')
%             elseif isequal(value,'one')||isequal(value,'two')||isequal(value,'many')
%                 set(handles.RootFile,'Visible','on')
%                 set(handles.RootFile,'UserData',value)% for use in menu Open_insert
%             end
%         case 'NomType'   %visible by default
%             if isequal(lower(varargout{ilist+1}),'off')
%                 set(handles.NomType,'Visible','off')
%             end 
%         case 'FileExt'   %visible by default
%             if isequal(lower(varargout{ilist+1}),'off')
%                 set(handles.FileExt,'Visible','off')
%             end
        case 'NbSlice'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on')
                set(handles.num_NbSlice,'Visible','on')
                set(handles.NbSlice_title,'Visible','on')
            end
        case 'VelTypeMenu'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'one') || isequal(lower(varargout{ilist+1}),'two')
                set(handles.VelTypeMenu,'Enable','on')
                if nb_series >=1 && ~testima_series
                    set(handles.VelTypeMenu,'Visible','on')
                    set(handles.VelType_text,'Visible','on');
                    set(handles.Field_frame,'Visible','on')
                end
            end
            if isequal(lower(varargout{ilist+1}),'two')
                set(handles.VelTypeMenu_1,'Enable','on')
                if nb_series >=2 && ~testima_series
                    set(handles.VelTypeMenu_1,'Visible','on')
                    set(handles.VelType_text_1,'Visible','on');
                end
            end
        case 'FieldMenu'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'one')||isequal(lower(varargout{ilist+1}),'two')
                set(handles.FieldMenu,'Enable','on') % test for MenuBorser 
                if nb_series >=1 && ~testima_series
                    view_FieldMenu(handles,'on')
                end
            end
            if isequal(lower(varargout{ilist+1}),'two')
                set(handles.FieldMenu_1,'Enable','on')
                if nb_series >=2 && ~testima_1
                    view_FieldMenu_1(handles,'on')
                end
            end
        case 'CoordType'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on') 
                set(handles.transform_fct,'Enable','on')
                set(handles.FieldTransform,'Visible','on')
%                 view_TRANSFORM(handles,'on')
            end
        case 'GetObject'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on')   
                set(handles.Objects,'Visible','on')
%                 set(handles.GetObject,'Visible','on');
            end
        case 'Mask'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on')   
                set(handles.Objects,'Visible','on')
%                 set(handles.GetMask,'Visible','on');
            end
        case 'PARAMETER'  
            set(handles.PARAMETERS_frame,'Visible','on')
            set(handles.PARAMETERS_title,'Visible','on')
            set(handles.ParamKey,'Visible','on')
            %set(handles.ParamVal,'Visible','on')
            Param_str=varargout{ilist+1};
            Param_list=[Param_list; {Param_str}];          
    end
end
if ~isempty(Param_list)
    set(handles.ParamKey,'String',Param_list)
    set(handles.ParamVal,'Visible','on')
end

%------------------------------------------------------------------------
% --- Executes on selection change in FieldMenu.
function FieldMenu_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
field_str=get(handles.FieldMenu,'String');
field_index=get(handles.FieldMenu,'Value');
field=field_str{field_index(1)};
if isequal(field,'get_field...')    
     hget_field=findobj(allchild(0),'name','get_field');
     if ~isempty(hget_field)
         delete(hget_field)%delete opened versions of get_field
     end
     SeriesData=get(handles.series,'UserData');
     filename=SeriesData.CurrentInputFile;
     if exist(filename,'file')
        get_field(filename)
     end
elseif isequal(field,'more...')
    str=calc_field;
    [ind_answer,v] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',str);
       % edit the choice in the fields and action menu
     scalar=cell2mat(str(ind_answer));
     update_menu(handles.FieldMenu,scalar)
end

%------------------------------------------------------------------------
% --- Executes on selection change in FieldMenu_1.
function FieldMenu_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
field_str=get(handles.FieldMenu_1,'String');
field_index=get(handles.FieldMenu_1,'Value');
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
elseif isequal(field,'more...')
    str=calc_field;
    [ind_answer,v] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',str);
       % edit the choice in the fields and action menu
     scalar=cell2mat(str(ind_answer));
     update_menu(handles.FieldMenu_1,scalar)
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
% --- determine the list of index pairs of processing file 
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
% ---- find the times corresponding to the first and last indices of a series
function displ_time(handles)
%------------------------------------------------------------------------
SeriesData=get(handles.series,'UserData');%
first_i=str2num(get(handles.num_first_i,'String'));
first_j=str2num(get(handles.num_first_j,'String'));
last_i=str2num(get(handles.num_last_i,'String'));
last_j=str2num(get(handles.num_last_j,'String'));
InputTable=get(handles.InputTable,'Data');
NomType=InputTable(:,4);
% NomType=SeriesData.NomType;
mode_list=get(handles.mode,'String');
index_mode=get(handles.mode,'Value');
mode=mode_list{index_mode};

time_first=[];
time_last=[];
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
for iview=1:length(NomType)
    time_first_cell{iview}='?';
    time_last_cell{iview}='?';%default
    time=SeriesData.Time{iview};
    if isequal(NomType{iview},'_1-2_1')|isequal(NomType{iview},'_1_1-2')|isequal(NomType{iview},'#_ab')|isequal(NomType{iview},'_1-2')
        if isfield(SeriesData,'displ_num')& ~isempty(SeriesData.displ_num)
            ind_shift=SeriesData.displ_num(iview,:);
            if isequal(mode,'bursts')
                first_j=0;
                last_j=0;
            end
            first_i1=first_i +ind_shift(3);
            first_i2 =first_i +ind_shift(4);
            first_j1 =first_j +ind_shift(1);
            first_j2 =first_j +ind_shift(2);
            last_i1=last_i +ind_shift(3);
            last_i2 =last_i +ind_shift(4);    
            last_j1 =last_j +ind_shift(1);
            last_j2 =last_j +ind_shift(2);
            siz=size(SeriesData.Time{1});
            if first_i1>=1 && first_j1>=1 && siz(1)>=last_i2 && siz(2)>=last_j2
                time_first=(time(first_i1,first_j1)+time(first_i2,first_j2))/2;
                time_last=(time(last_i1,last_j1)+time(last_i2,last_j2))/2;
            else%read the time in the nc files
                RootPath=get(handles.RootPath,'String');
                RootFile=get(handles.RootFile,'String');
                SubDir=get(handles.SubDir,'String');
                %VelType=get(handles.VelType,'String');
                VelType_str=get(handles.VelTypeMenu,'String');
                VelType_val=get(handles.VelTypeMenu,'Value');
                VelType=VelType_str{VelType_val};
                filebase=fullfile(RootPath{1},RootFile{1});
                [filefirst]=name_generator(filebase,first_i1,first_j1,'.nc',NomType{iview},1,first_i2,first_j2,SubDir{iview});
                if  exist(filefirst,'file')
                    Attrib=nc2struct(filefirst,[]);
                    if isfield(Attrib,'Time')
                        time_first=Attrib.Time;
                    else
                        if isfield(Attrib,'absolut_time_T0')
                            time_first=Attrib.absolut_time_T0;
                        end
                        if isfield(Attrib,'absolut_time_T0_2')&&~(isequal(VelType,'civ1')||isequal(VelType,'interp1')||isequal(VelType,'filter1'))
                            time_first=Attrib.absolut_time_T0_2;
                        end
                    end 
                end
                [filelast]=name_generator(filebase,last_i1,last_j1,'.nc',NomType{iview},1,last_i2,last_j2,SubDir{iview});
                if exist(filelast,'file')
                   Attrib=nc2struct(filelast,[]);
                    if isfield(Attrib,'Time')
                        time_last=Attrib.Time;
                    else
                        if isfield(Attrib,'absolut_time_T0')
                            time_last=Attrib.absolut_time_T0;
                        end
                        if isfield(Attrib,'absolut_time_T0_2')&&~(isequal(VelType,'civ1')||isequal(VelType,'interp1')||isequal(VelType,'filter1'))
                            time_last=Attrib.absolut_time_T0_2;
                        end
                    end 
                end
            end
        end
    else
        siz=size(time);
        if siz(1)>=last_i && siz(2)>=last_j && first_i>=1 && first_j>=1
            time_first=times(first_i,first_j);
            time_last=times(last_i,last_j); 
        end
    end
    time_first_cell{iview}=num2str(time_first,4);
    time_last_cell{iview}=num2str(time_last,4);
end
% set(handles.time_first,'Value',1)
% set(handles.time_last,'Value',1)
% set(handles.time_first,'String',time_first_cell);
% set(handles.time_last,'String',time_last_cell);

%------------------------------------------------------------------------
% --- Executes on button press in GetObject.
function GetObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
SeriesData=get(handles.series,'UserData');
value=get(handles.GetObject,'Value');
if value
     set(handles.GetObject,'BackgroundColor',[1 1 0])%put unactivated buttons to yellow
%      DataInit.ParentButton=handles.GetObject;
     hset_object=findobj(allchild(0),'tag','set_object');%find the set_object interface handle
     if ishandle(hset_object)
         uistack(hset_object,'top')
        %[SeriesData.hset_object,SeriesData.sethandles]=set_object(DataInit); %open the set_object interface
     else
         %get the object file 
         defaultname=get(handles.RootPath,'String');
         if isempty(defaultname)
            defaultname={''};
         end
        [FileName, PathName, filterindex] = uigetfile( ...
       {'*.xml;*.mat', ' (*.xml,*.mat)';
       '*.xml',  '.xml files '; ...
        '*.mat',  '.mat matlab files '}, ...
        'Pick an xml object file (or use uvmat to create it)',defaultname{1});
        fileinput=[PathName FileName];%complete file name 
        testblank=findstr(fileinput,' ');%look for blanks
        if ~isempty(testblank)
            msgbox_uvmat('ERROR','forbidden input file name: contain blanks')
            return
        end
        sizf=size(fileinput);
        if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end
        %read the file
        t=xmltree(fileinput);
        data=convert(t);
        if ~isfield(data,'Style')
             data.Style='points';
        end
        if ~isfield(data,'ProjMode')
             data.ProjMode='projection';
        end
        transform_menu=get(handles.transform_fct,'String');
        ichoice=get(handles.transform_fct,'Value');
%         if isequal(transform_menu{ichoice},'px');
%             data.CoordType='px';
%         else
%             data.CoordType='phys';
%         end
        data.desable_plot=1;
        [SeriesData.hset_object,SeriesData.sethandles]=set_object(data);% call the set_object interface
     end 
else
    set(handles.GetObject,'BackgroundColor',[0.7 0.7 0.7])%put activated buttons to green
%     if isfield(SeriesData,'hset_object')&& ishandle(SeriesData.hset_object)
%         close(SeriesData.hset_object)
%     end
end
set(handles.series,'UserData',SeriesData)

%--------------------------------------------------------------
function GetMask_Callback(hObject, eventdata, handles)
value=get(handles.GetMask,'Value');
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
% --- Executes on selection change in transform_fct.
function transform_fct_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
global nb_transform

menu=get(handles.transform_fct,'String');
ind_coord=get(handles.transform_fct,'Value');
coord_option=menu{ind_coord};
list_transform=get(handles.transform_fct,'UserData');
ff=functions(list_transform{end});
if isequal(coord_option,'more...'); 
    coord_fct='';
    prompt = {'Enter the name of the transform function'};
    dlg_title = 'user defined transform';
    num_lines= 1;
    [FileName, PathName, filterindex] = uigetfile( ...
       {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file', ff.file);
    if isequal(PathName(end),'/')||isequal(PathName(end),'\')
        PathName(end)=[];
    end
    transform_selected =fullfile(PathName,FileName);
    if ~exist(transform_selected,'file')
          return
    end
    [ppp,transform,xt_fct]=fileparts(FileName);% removes extension .m
    if ~isequal(ext_fct,'.m')
        msgbox_uvmat('ERROR','a Matlab function .m must be introduced');
        return
    end
   menu=update_menu(handles.transform_fct,transform);%add the selected fct to the menu
   ind_coord=get(handles.transform_fct,'Value');
   addpath(PathName)
   list_transform{ind_coord}=str2func(transform);% create the function handle corresponding to the newly seleced function
   set(handles.transform_fct,'UserData',list_transform)
   rmpath(PathName)
   % save the new menu in the personal file 'uvmat_perso.mat' 
   dir_perso=prefdir;%personal Matalb directory
   profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
   if exist(profil_perso,'file')
       for ilist=nb_transform+1:numel(list_transform)
           ff=functions(list_transform{ilist});
           transform_fct{ilist-nb_transform}=ff.file;
       end 
        save (profil_perso,'transform_fct','-append'); %store the root name for future opening of uvmat
   end 
end

%check the current path to the selected function
if ~isempty(list_transform{ind_coord})
func=functions(list_transform{ind_coord});
set(handles.path_transform,'String',fileparts(func.file)); %show the path to the senlected function
else
   set(handles.path_transform,'String',''); %show the path to the senlected function 
end
%------------------------------------------------------------------------
% --- generates a series of file names with reference numbers between range1 and
% --- range2 with increment incr. The reference number num_ref is the image number at the middle of the
% --- image pair. The set of first numbers num1 of the image pairs is also
% --- given as output
% function [num_i1,num_i2,num_j1,num_j2,nbmissing]=netseries_generator(filebase,subdir,mode,first_i,incr_i,last_i,first_j,incr_j,last_j)
% %------------------------------------------------------------------------
% [Path,Name]=fileparts(filebase);
% filebasesub=fullfile(Path,subdir,Name);
% filecell={};%default
% num_i1=[];
% num_i2=[];
% num_j1=[];
% num_j2=[];
% ind0_i=first_i:incr_i:last_i;
% nbcolumn=length(ind0_i);
% ind0_j=first_j:incr_j:last_j;
% nbline=length(ind0_j);
% if isequal(mode,'#_ab')
%     dirpair=dir([filebasesub '*_*.nc']);
% elseif isequal(mode,'bursts')||isequal(mode,'series(Dj)')  
%     dirpair=dir([filebasesub '_*_*-*.nc']);
% elseif isequal(mode,'series(Di)')
%     dirpair=dir([filebasesub '_*-*_*.nc']);
% else
%     msgbox_uvmat('ERROR','option *|* not yet implemented')
%     return
% end
% if isempty(dirpair)
%         msgbox_uvmat('ERROR','no pair detected in the selected range')
%         return
% end
% 
% if isequal(mode,'bursts')||isequal(mode,'#_ab')
%     icount=0;
%     for ifile=1:length(dirpair)
%         [RootPath,RootFile,str_1,str_2,str_a,str_b,ext,nom_type]=name2display(dirpair(ifile).name);
%         num1_r=str2num(str_1);
%         if isequal(RootFile,Name) & ~isempty(num1_r)   
%             num_i1(ifile)=num1_r;
%             num_a(ifile)=stra2num(str_a);
%             num_b(ifile)=stra2num(str_b);
%         end      
%     end
%     test_range= (num_i1 >=first_i)&(num_i1<= last_i);% =1 when both numbers are in the range
%     ind_i=((num_i1-first_i)/incr_i)+1;%indices i in the list of prescribed file indices 
%     select=find(test_range &(floor(ind_i)==ind_i));%selected indices of num_i1 in the file directory
%     ind_i=ind_i(select);%set of selected indices ind_i
%     [ind_i,indsort]=sort(ind_i);%sorted list of ind_i
%     select=select(indsort);
%     num_i1=num_i1(select);
%     num_a=num_a(select);
%     num_b=num_b(select);
%     dirpair=dirpair(select);
%     [ind_remove]=find_pairs(dirpair,ind_i,nbcolumn); 
%     ind_i(ind_remove)=[];
%     num_a(ind_remove)=[];
%     num_b(ind_remove)=[];
%     num_j1=zeros(1,nbcolumn);%default
%     num_j2=num_j1;
%     num_j1(ind_i)=num_a;
%     num_j2(ind_i)=num_b;
%     num_i1=first_i:incr_i:last_i;
%     num_i2=num_i1;
%     nbmissing=nbcolumn-length(ind_i);
% 
% elseif isequal(mode,'series(Di)') 
%     %ind0_i=num_first_i:num_incr_i:num_last_i;
%     %nbcolumn=length(ind0_i);
%     %ind0_j=num_first_j:num_incr_j:num_last_j;
%     %nbline=length(ind0_j);
%     %dirpair=dir([filebasesub '_*-*_*.nc']);
%     for ifile=1:length(dirpair)
%         [RootPath,RootFile,str_1,str_2,str_a,str_b,ext,nom_type]=name2display(dirpair(ifile).name);
%         num_i1_r(ifile)=str2num(str_1);
%         num_i2_r(ifile)=str2num(str_2);
%         num_j(ifile)=str2num(str_a);
%     end
%     num_i=floor((num_i1_r+num_i2_r)/2); %list of reference indices of the detected files
%     test_range= (num_i >=first_i)&(num_i<= last_i)&(num_j >=first_j)&(num_j<= last_j);% =1 when both numbers are in the range
%     ind_i=((num_i-first_i)/incr_i)+1;%indices i and j in the list of prescribed file indices 
%     ind_j=((num_j-first_j)/incr_j)+1;
%     ind_ij=ind_j+nbline*(ind_i-1);%indices in the reshhaped series of prescribed file indices
%     select=find(test_range &(floor(ind_i)==ind_i)&(floor(ind_j)==ind_j));%selected indices in the file directory
%     ind_ij=ind_ij(select);%set of selected indices ind_ij
%     [ind_ij,indsort]=sort(ind_ij);%sorted list of ind_ij 
%     select=select(indsort);
%     num_i1_r=num_i1_r(select);
%     num_i2_r=num_i2_r(select);
%     dirpair=dirpair(select);
%     [ind_remove]=find_pairs(dirpair,ind_ij,nbcolumn*nbline) ;
%     ind_ij(ind_remove)=[];
%     num_i1_r(ind_remove)=[];
%     num_i2_r(ind_remove)=[];
%     num_i1=zeros(1,nbline*nbcolumn);%default
%     num_i2=num_i1;
%     num_i1(ind_ij)=num_i1_r;
%     num_j2(ind_ij)=num_i2_r;
%     num_i1=reshape(num_i1,nbline,nbcolumn);
%     num_i2=reshape(num_i2,nbline,nbcolumn);
%     num_j1=meshgrid(ind0_i,ind0_j);
%     num_j2=num_j1;
%     nbmissing=nbline*nbcolumn-length(ind_ij);
% elseif isequal(mode,'series(Dj)')
%     for ifile=1:length(dirpair)
%         [RootPath,RootFile,str_1,str_2,str_a,str_b,ext,nom_type]=name2display(dirpair(ifile).name);
%         num_i(ifile)=str2num(str_1);
%         num_a(ifile)=str2num(str_a);
%         num_b(ifile)=str2num(str_b);
%     end
%     num_j=floor((num_a+num_b)/2); %list of reference indices of the detected files
%     test_range= (num_i >=first_i)&(num_i<= last_i)&(num_j >=first_j)&(num_j<= last_j);% =1 when both numbers are in the range
%     ind_i=((num_i-first_i)/incr_i)+1;%indices i and j in the list of prescribed file indices 
%     ind_j=((num_j-first_j)/incr_j)+1;
%     ind_ij=ind_j+nbline*(ind_i-1);%indices in the reshhaped series of prescribed file indices
%     select=find(test_range &(floor(ind_i)==ind_i)&(floor(ind_j)==ind_j));%selected indices in the file directory
%     ind_ij=ind_ij(select);%set of selected indices ind_ij
%     [ind_ij,indsort]=sort(ind_ij);%sorted list of ind_ij 
%     select=select(indsort);
%     num_i=num_i(select);
%     num_a=num_a(select);
%     num_b=num_b(select);
%     dirpair=dirpair(select);
%     [ind_remove]=find_pairs(dirpair,ind_ij,nbcolumn*nbline) ;
%     ind_ij(ind_remove)=[];
%     num_a(ind_remove)=[];
%     num_b(ind_remove)=[];
%     num_j1=zeros(1,nbline*nbcolumn);%default
%     num_j2=num_j1;
%     num_j1(ind_ij)=num_a;
%     num_j2(ind_ij)=num_b;
%     num_j1=reshape(num_j1,nbline,nbcolumn);
%     num_j2=reshape(num_j2,nbline,nbcolumn);
%     num_i1=meshgrid(ind0_i,ind0_j);
%     num_i2=num_i1;
%     nbmissing=nbline*nbcolumn-length(ind_ij);
% end


% --- Executes on button press in REFRESH_INDICES.

    
    function REFRESH_INDICES_Callback(hObject, eventdata, handles)
% hObject    handle to REFRESH_INDICES (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.REFRESH_INDICES,'BackgroundColor',[0.7 0.7 0.7])
InputTable=get(handles.InputTable,'Data');
check_lines=get(handles.REFRESH_INDICES,'UserData');

%% check the indices and FileTypes for each series (limited to the new ones to save time)
for ind_list=1:length(check_lines)
    if  check_lines(ind_list)
        InputLine=InputTable(ind_list,:);
        detect_idem=strcmp('"',InputLine);% look for '" (repeat of previous data)
        detect_idem=detect_idem(detect_idem>0);
        if ~isempty (detect_idem)
            InputLine(detect_idem)=InputTable(ind_list-1,detect_idem);
            set(handles.InputTable,'Data',InputTable)
        end
        fileinput=fullfile_uvmat(InputLine{1},InputLine{2},InputLine{3},InputLine{5},InputLine{4},1,2,1,2);
        %fileinput=name_generator(fullfile(InputLine{1},InputLine{3}),1,1,InputLine{5},InputLine{4},1,2,2,InputLine{2})
        %update file series defined by the selected line
        [InputTable{ind_list,1},InputTable{ind_list,3},InputTable{(ind_list),4},errormsg]=update_indices(handles,fileinput,ind_list);
        if ~isempty(errormsg)
                msgbox_uvmat('ERROR',errormsg)
                return
        end
    end
end
set(handles.InputTable,'Data',InputTable)
SeriesData=get(handles.series,'UserData');

state_j='off';
state_Pairs='off';
state_InputFields='off';
val=get(handles.ListView,'Value');
ListViewString={''};
if ~isempty(SeriesData)
%     ListViewString={};
    for ilist=1:size(InputTable,1)
        if ~isempty(SeriesData.j1_series{ilist})
            state_j='on';
        end
        if ~isempty(SeriesData.i2_series{ilist})||~isempty(SeriesData.j2_series{ilist})
            state_Pairs='on';
            ListViewString{ilist}=num2str(ilist);
            if check_lines(ilist)
                val=ilist;%select the last pair if it is a new entry
            end
        end
        if strcmp(SeriesData.FileType,'civx')||strcmp(SeriesData.FileType,'civdata')
            state_InputFields='on';
        end
    end
end
set(handles.ListView,'Value',val)
set(handles.ListView,'String',ListViewString)
if strcmp(state_Pairs,'on')
    ListView_Callback(hObject,eventdata,handles)
end
set(handles.Pairs,'Visible',state_InputFields)
enable_j(handles,state_j)
set(handles.REFRESH_INDICES,'BackgroundColor',[1 0 0])
set(handles.REFRESH_INDICES,'visible','off')

% update min and max indices for a series
function [RootPath,RootFile,NomType,errormsg]=update_indices(handles,fileinput,iview)

%% look for min and max indices existing in the file series and update SeriesData
errormsg='';
[RootPath,FileName,FileExt]=fileparts(fileinput);
[RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,Object]=find_file_series(RootPath,[FileName FileExt]);
if isempty(RootFile)&&isempty(i1_series)
    errormsg='no input file in the series';
    return
end
[tild,tild,FileExt]=fileparts(fileinput);

MinIndex=get(handles.MinIndex,'Data');
MaxIndex=get(handles.MaxIndex,'Data');
MinIndex_i=min(i1_series(i1_series>0));
if ~isempty(i2_series)
    MaxIndex_i=max(i2_series(i2_series>0));
else
    MaxIndex_i=max(i1_series(i1_series>0));
end
MinIndex_j=min(j1_series(j1_series>0));
if ~isempty(j2_series)
    MaxIndex_j=max(j2_series(j2_series>0));
else
    MaxIndex_j=max(j1_series(j1_series>0));
end
MinIndex{iview,1}=MinIndex_i;
MinIndex{iview,2}=MinIndex_j;
MaxIndex{iview,1}=MaxIndex_i;
MaxIndex{iview,2}=MaxIndex_j;
set(handles.MinIndex,'Data',MinIndex)
set(handles.MaxIndex,'Data',MaxIndex)
SeriesData=get(handles.series,'UserData');
SeriesData.i1_series{iview}=i1_series;
SeriesData.i2_series{iview}=i2_series;
SeriesData.j1_series{iview}=j1_series;
SeriesData.j2_series{iview}=j2_series;
SeriesData.FileType{iview}=FileType;

%% represents the set of existing files as an image
set(handles.waitbar_frame,'Units','pixels')
pos=get(handles.waitbar_frame,'Position');
xima=0.5:pos(3)-0.5;% pixel positions on the image representing the existing file indices
yima=0.5:pos(4)-0.5;
[XIma,YIma]=meshgrid(xima,yima);
nb_i=size(i1_series,1);
nb_j=size(i1_series,2);
ind_i=(0.5:nb_i-0.5)*pos(3)/nb_i;
ind_j=(0.5:nb_j-0.5)*pos(4)/nb_j;
[Ind_i,Ind_j]=meshgrid(ind_i,ind_j);
CData=zeros([size(XIma) 3]);
file_ima=double((i1_series(:,:,1)>0)');
if numel(file_ima)>=2
if size(file_ima,1)==1
    CLine=interp1(ind_i,file_ima,xima,'nearest');
    CData(:,:,2)=ones(size(yima'))*CLine;
else
    CData(:,:,2)=interp2(Ind_i,Ind_j,file_ima,XIma,YIma,'nearest');
end
set(handles.waitbar_frame,'CData',CData)
end
set(handles.waitbar_frame,'Units','normalized')

%% enable field and veltype menus
testfield=isequal(get(handles.FieldMenu,'enable'),'on');
testfield_1=isequal(get(handles.FieldMenu_1,'enable'),'on');
testveltype=isequal(get(handles.VelTypeMenu,'enable'),'on');
testveltype_1=isequal(get(handles.VelTypeMenu_1,'enable'),'on');
testtransform=isequal(get(handles.transform_fct,'Enable'),'on');
testnc=0;
testnc_1=0;
testcivx=0;
testcivx_1=0;
%TODO: update
% if length(FileExtCell)==1 || length(FileExtCell)>2
%     for iview=1:length(FileExtCell)
%         if isequal(FileExtCell{iview},'.nc')
%             testnc=1;
%         end
%         if isequal(FileTypeCell{iview},'civx')
%             testcivx=1;
%         end
%     end
% elseif length(FileExtCell)==2
%     testnc=isequal(FileExtCell{1},'.nc');
%     testnc_1=isequal(FileExtCell{2},'.nc');
%     testcivx=isequal(FileTypeCell{1},'civx');
%     testcivx_1=isequal(FileTypeCell{2},'civx');
% end
if testfield && testnc 
    view_FieldMenu(handles,'on')
    if testcivx
        menustr=get(handles.FieldMenu,'String');
        if isequal(menustr,{'get_field...'})
            set(handles.FieldMenu,'String',{'get_field...';'velocity';'vort';'div';'more...'})
        end
    else
        set(handles.FieldMenu,'Value',1)
        set(handles.FieldMenu,'String',{'get_field...'}) 
    end
else
    view_FieldMenu(handles,'off')
end
if testfield_1 && testnc_1
    view_FieldMenu_1(handles,'on')
    if testcivx_1
        menustr=get(handles.FieldMenu_1,'String');
        if isequal(menustr,{'get_field...'})
            set(handles.FieldMenu_1,'String',{'get_field...';'velocity';'vort';'div';'more...'})
        end
    else
        set(handles.FieldMenu_1,'Value',1)
        set(handles.FieldMenu_1,'String',{'get_field...'}) 
    end
else
    view_FieldMenu_1(handles,'off')
end
if testveltype && testcivx
    set(handles.VelTypeMenu,'Visible','on')
    set(handles.VelType_text,'Visible','on');
else
    set(handles.VelTypeMenu,'Visible','off')
    set(handles.VelType_text,'Visible','off');
end
if testveltype_1 && testcivx_1
    set(handles.VelTypeMenu_1,'Visible','on')
    set(handles.VelType_text_1,'Visible','on');
else
    set(handles.VelTypeMenu_1,'Visible','off')
    set(handles.VelType_text_1,'Visible','off');
end
if testtransform && (testcivx || testima)
    set(handles.FieldTransform,'Visible','on')
%      view_TRANSFORM(handles,'on')
else
    set(handles.FieldTransform,'Visible','off')
%     view_TRANSFORM(handles,'off')
end
%TODO:update
% if ~isequal(FileExt,'.nc') && ~isequal(FileExt,'.cdf') && ~testima
%     msgbox_uvmat('ERROR',['invalid input file extension ' FileExt])
%     return
% end  

%%  read image documentation file  if found%%%%%%%%%%%%%%%%%%%%%%%%%%%
ext_imadoc='';
FileBase=fullfile(RootPath,RootFile);
if isequal(FileExt,'.xml')||isequal(FileExt,'.civ')
    ext_imadoc=FileExt;
elseif exist([FileBase '.xml'],'file')
    ext_imadoc='.xml';
elseif exist([FileBase '.civ'],'file')
    ext_imadoc='.civ';
end
%read the ImaDoc file
XmlData=[];
NbSlice_calib={};
if isequal(ext_imadoc,'.xml')
        [XmlData,warntext]=imadoc2struct([FileBase '.xml']);
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
elseif isequal(ext_imadoc,'.civ')
    [error,XmlData.Time,TimeUnit,mode,npx,npy,pxcmx,pxcmy]=read_imatext([FileBase '.civ']);
    time=XmlData.Time;
    if error==2, warntext=['no file ' FileBase '.civ'];
    elseif error==1, warntext='inconsistent number of fields in the .civ file';
    end  
end  


%% number of slices
if isfield(XmlData,'GeometryCalib') && isfield(XmlData.GeometryCalib,'SliceCoord')
       siz=size(XmlData.GeometryCalib.SliceCoord);
       if siz(1)>1
           NbSlice=siz(1);
       else
           NbSlice=1;
       end
       set(handles.num_NbSlice,'String',num2str(NbSlice))
end
% set(handles.mode,'Visible','off') % do not show index pairs by default
set(handles.Pairs,'Visible','off')
% set(handles.ref_i,'Visible','off')
% set(handles.ref_i_text,'Visible','off')
testpair=0;
%set the menus of image pairs and default selection for series
%list pairs if relevant
% Val=get(handles.NomType,'Value');
% synchronise_view(handles,Val)

% if ~isfield(SeriesData,'j1_series')||isempty(SeriesData.j1_series{index})
%     state_j='off'; %no need for j index
% else
%     state_j='on'; %case of j index
% end
% show index pairs if files exist
set(handles.series,'UserData',SeriesData)



% --- Executes on button press in BATCH.
function BATCH_Callback(hObject, eventdata, handles)
% hObject    handle to BATCH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Series=read_GUI(handles.series);
t=struct2xml(Series);
save(t); %TODO: determine a xml file name

% list_action=get(handles.ACTION,'String');% list menu action
% index_action=get(handles.ACTION,'Value');% selected string index
% action= list_action{index_action}; % selected string

%% defining the ACTION function handle
path_series=which('series');
list_path=get(handles.ACTION,'UserData');
index=get(handles.ACTION,'Value');
fct_path=list_path{index}; %path stored for the function ACTION
if ~isequal(fct_path,path_series)
    eval(['spath=which(''' action ''');']) %spath = current path of the selected function ACTION
    if ~exist(fct_path,'dir')
        msgbox_uvmat('ERROR',['The prescibed function path ' fct_path ' does not exist'])
        return
    end
    if ~isequal(spath,fct_path)
        addpath(fct_path)% add the prescribed path if not the current one
    end
end
eval(['h_fun=@' action ';'])%create a function handle for ACTION
if ~isequal(fct_path,path_series)
        rmpath(fct_path)% add the prescribed path if not the current one    
end

h_fun('BATCH');% TODO modify the called function to read the xml file as input parameter


% --- Executes on selection change in txt_Pairs
function txt_Pairs_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on selection change in ListView.
function ListView_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------    
ListViewString=get(handles.ListView,'String');
if isempty(ListViewString)
    ListViewString={''};
end
ListViewValue=get(handles.ListView,'Value');
View=str2double(ListViewString{ListViewValue});
if isnan(View)
    set(handles.Pairs,'Visible','off')
else
    set(handles.Pairs,'Visible','on')
    SeriesData=get(handles.series,'UserData');
    if isfield(SeriesData,'j1_series')&&(~isempty(SeriesData.i2_series{View})||~isempty(SeriesData.j2_series{View}))
        if ~isempty(SeriesData.i2_series{View}) %pairs with i View
            set(handles.mode,'Value',1)
            set(handles.mode,'String',{'series(Di)'})
        else  %pairs with j View
            nbfield=size(SeriesData.j2_series{View},1);
            nbfield2=size(SeriesData.j2_series{View},2);
            set(handles.mode,'Value',1)
            set(handles.mode,'String',{'bursts';'series(Dj)'})
            if nbfield2>10 || nbfield==1
                set(handles.mode,'Value',2);
            else
                set(handles.mode,'Value',1);
            end
        end
    end
    mode_Callback([],[], handles)
end

    
