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
function series_OpeningFcn(hObject, eventdata, handles,param)
global nb_builtin_ACTION nb_builtin_transform
% Choose default command line output for series
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
%default initial parameters
drawnow
set(hObject,'Units','pixels')
set(handles.PairString,'ColumnEditable',logical(0))
set(handles.PairString,'ColumnFormat',{'char'})
set(handles.PairString,'ColumnWidth',{60})
set(handles.PairString,'Data',{''})
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

%% file name and browser initialisation
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
        display_file_name(handles,param.FileName_1,0)
        display_file_name(handles,param.FileName,1)
    else
        display_file_name(handles,param.FileName,0)
    end
end  

%% fields input initialisation
if isfield(param,'list_fields')&& isfield(param,'index_fields') &&~isempty(param.list_fields) &&~isempty(param.index_fields)
    set(handles.FieldMenu,'String',param.list_fields);% list menu fields
    set(handles.FieldMenu,'Value',param.index_fields);% selected string index
    FieldCell{1}=param.list_fields{param.index_fields};
end

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

%% TRANSFORM menu: loads the information stored in prefdir to initiate  the list of field transform functions
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

%% read the list of functions stored in the personal file 'uvmat_perso.mat' in prefdir
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
% then activate the view-field action if selected
% it is activated either by clicking on the RootPath window or by the 
% browser 
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function MenuBrowse_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------   
InputTable=get(handles.InputTable,'Data');
RootPathCell=InputTable(:,1);
SubDirCell=InputTable(:,2);
RootFileCell=InputTable(:,3);
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
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
[path,name,ext]=fileparts(fileinput);
SeriesData=[];%dfault
if isequal(ext,'.xml')
    msgbox_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
elseif isequal(ext,'.xls')
    msg_box_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
else
    display_file_name(handles,fileinput,0)
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
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
[path,name,ext]=fileparts(fileinput);
if isequal(ext,'.xml')
    msgbox_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
elseif isequal(ext,'.xls')
    msgbox_uvmat('ERROR','input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
else
    display_file_name(handles,fileinput,1)
end

% --------------------------------------------------------------------
function MenuFile_insert_1_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------    
fileinput=get(handles.MenuFile_insert_1,'Label');
display_file_name(handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_2_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------    
fileinput=get(handles.MenuFile_insert_2,'Label');
display_file_name(handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_3_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------   
fileinput=get(handles.MenuFile_insert_3,'Label');
display_file_name( handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_4_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------    
fileinput=get(handles.MenuFile_insert_4,'Label');
display_file_name( handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_5_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------    
fileinput=get(handles.MenuFile_insert_5,'Label');
display_file_name(handles,fileinput,1)

%------------------------------------------------------------------------
% --- Executes when entered data in editable cell(s) in InputTable.
function InputTable_CellEditCallback(hObject, eventdata, handles)
%------------------------------------------------------------------------
iview=eventdata.Indices(1);
InputTable=get(handles.InputTable,'Data');
filename=fullfile(InputTable{iview,1},InputTable{iview,2},[InputTable{iview,3} InputTable{iview,4} InputTable{iview,5}])
display_file_name(handles,fileinput,0)

% hObject    handle to InputTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
% check_lines=get(handles.REFRESH_INDICES,'UserData');
% check_lines(eventdata.Indices(1))=1; %select the edited line for refresh
% set(handles.REFRESH_INDICES,'UserData',check_lines);
% set(handles.REFRESH_INDICES,'Visible','on')
%InputTable=get(handles.InputTable,'Data')

%------------------------------------------------------------------------
% ---  refresh the GUI data after introduction of a new file
% INPUT:
% handles: handles of the elements in the GUI series
% fileinput: name of the input file
% append: =0 to refresh the list of file series, =1 to append a new series to the list (from the menu bar option 'Open_insert')
function display_file_name(handles,fileinput,append)
%------------------------------------------------------------------------  

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
% set(handles.RootPath,'BackgroundColor',[1 1 0]) % set RootPath edit box  to yellow
set(handles.InputTable,'BackgroundColor',[1 1 0]) % set RootPath edit box  to yellow
drawnow


%% detect root name, nomenclature and indices in the input file name:
[FilePath,FileName,FileExt]=fileparts(fileinput);
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
% the root name and indices may be corrected by including the first index i1 if a corresponding xml file exists
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,MovieObject,i1,i2,j1,j2]=find_file_series(FilePath,[FileName FileExt]);
if isempty(RootFile)&&isempty(i1_series)
    errormsg='no input file in the series';
    return
end

%% fill the list of file series
InputTable=get(handles.InputTable,'Data');
if append % display the input data as a new line in the table
     lastview=size(InputTable,1)+1;
     InputTable(lastview,:)=[{RootPath},{SubDir},{RootFile},{NomType},{FileExt}];
    set(handles.ListView,'String',[get(handles.ListView,'String');{num2str(lastview)}])
    set(handles.ListView,'Value',lastview)
%     check_lines=get(handles.REFRESH_INDICES,'UserData');
else % or re-initialise the list of  input  file series
    lastview=1;
    InputTable=[{RootPath},{SubDir},{RootFile},{NomType},{FileExt}];
    set(handles.TimeTable,'Data',[{[]},{[]},{[]},{[]}]) 
    set(handles.MinIndex,'Data',[{[]},{[]}])
    set(handles.MaxIndex,'Data',[{[]},{[]}])
    set(handles.ListView,'Value',1)
    set(handles.ListView,'String',{'1'})
end
set(handles.InputTable,'Data',InputTable)
% check_lines(lastview)=1; %select the edited line for refresh
% set(handles.REFRESH_INDICES,'UserData',check_lines);

%% refresh menus with info from the new series: TODO:check 
%REFRESH_INDICES_Callback([],[], handles)

%% determine the selected reference field indices for pair display
ref_i=1; %default ref_i is a reference frame index used to find existing pairs from PIV
if ~isempty(i1)
    ref_i=i1;
    if ~isempty(i2)
        ref_i=floor((ref_i+i2)/2);% reference image number corresponding to the file
    end
end
set(handles.num_ref_i,'String',num2str(ref_i));
ref_j=1; %default  ref_j is a reference frame index used to find existing pairs from PIV
if ~isempty(j1)
    ref_j=j1;
    if ~isempty(j2)
        ref_j=floor((j1+j2)/2);
    end          
end
set(handles.num_ref_j,'String',num2str(ref_j)); 

%% update list of recent files in the menubar and save it for future opening
MenuFile=[{get(handles.MenuFile_1,'Label')};{get(handles.MenuFile_2,'Label')};...
    {get(handles.MenuFile_3,'Label')};{get(handles.MenuFile_4,'Label')};{get(handles.MenuFile_5,'Label')}];
str_find=strcmp(FileName,MenuFile);
if isempty(find(str_find,1))
    MenuFile=[{FileName};MenuFile];%insert the current file if not already in the list
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
update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,MovieObject,lastview);

%------------------------------------------------------------------------
% --- Update information about a new field series (indices to scan, timing,
%     calibration from an xml file, then refresh current plots
function update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,VideoObject,iview)
%------------------------------------------------------------------------

%% enable j index visibility
if isempty(j1_series)
    state='off';
else
    state='on';
end
enable_j(handles,state)

%% display the min and max indices for all the file series
MinIndex=get(handles.MinIndex,'Data');%retrieve the min indices in the table MinIndex
MaxIndex=get(handles.MaxIndex,'Data');%retrieve the max indices in the table MaxIndex
% MinIndex_i=min(i1_series(i1_series>0));
% if ~isempty(i2_series)
%     MaxIndex_i=max(i2_series(i2_series>0));
% else
%     MaxIndex_i=max(i1_series(i1_series>0));
% end
% MinIndex_j=min(j1_series(j1_series>0));
% if ~isempty(j2_series)
%     MaxIndex_j=max(j2_series(j2_series>0));
% else
%     MaxIndex_j=max(j1_series(j1_series>0));
% end
i_sum=sum(sum(i1_series,2),3);
MaxIndex_i=max(find(i_sum>0))-1;
MinIndex_i=min(find(i_sum>0))-1;
j_sum=sum(sum(i1_series,1),3);
MaxIndex_j=max(find(j_sum>0))-1;
MinIndex_j=min(find(j_sum>0))-1;
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
end
first_j=str2num(get(handles.num_first_j,'String'));
if isempty(first_j)
    first_j=ref_j;
elseif first_j<MinIndex_j
    first_j=MinIndex_j;
end
last_i=str2num(get(handles.num_last_i,'String'));
if isempty(last_i)
    last_i=ref_i;
elseif last_i > MaxIndex_i
    last_i=MaxIndex_i;
end
last_j=str2num(get(handles.num_first_j,'String'));
if isempty(last_j)
    last_j=ref_j;
elseif last_j>MaxIndex_j
    last_j=MaxIndex_j;
end
set(handles.num_first_i,'String',num2str(first_i)); 
set(handles.num_first_j,'String',num2str(first_j));
set(handles.num_last_i,'String',num2str(last_i)); 
set(handles.num_last_j,'String',num2str(last_j));

%% read timing and total frame number from the current file (movie files) !! may be overrid by xml file
InputTable=get(handles.InputTable,'Data');
FileBase=fullfile(InputTable{iview,1},InputTable{iview,3});
time=[];%default
% case of movies
if strcmp(InputTable{iview,4},'*')
    if ~isempty(VideoObject)
        imainfo=get(VideoObject);
        time=(0:1/imainfo.FrameRate:(imainfo.NumberOfFrames-1)/imainfo.FrameRate)';
        set(handles.Dt_txt,'String',['Dt=' num2str(1000/imainfo.FrameRate) 'ms']);%display the elementary time interval in millisec
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

ext_imadoc='';
if exist([FileBase '.xml'],'file')
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

%% update time table
TimeTable=get(handles.TimeTable,'Data');
if isempty(MinIndex_j)
    TimeTable{iview,1}=time(MinIndex_i);
    TimeTable{iview,2}=time(first_i);
    TimeTable{iview,3}=time(last_i);
    TimeTable{iview,4}=time(MaxIndex_i);
elseif ~isempty(time)
    TimeTable{iview,1}=time(MinIndex_i,MinIndex_j);
    TimeTable{iview,2}=time(first_i,first_j);
    TimeTable{iview,3}=time(last_i,last_j);
    TimeTable{iview,4}=time(MaxIndex_i,MaxIndex_j);
end
set(handles.TimeTable,'Data',TimeTable)

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

%% update pair menus
ListView=get(handles.ListView,'String');
ListView{iview}=num2str(iview);
set(handles.ListView,'String');
set(handles.ListView,'Value',iview)
update_mode(handles,i1_series,i2_series,j1_series,j2_series,time)

%% display the set of existing files as an image
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
SeriesData=get(handles.series,'UserData');
SeriesData.FileType{iview}=FileType;
check_civ=0;
check_netcdf=0;
for iview=1:length(SeriesData.FileType)
    switch SeriesData.FileType{iview}
        case {'civx','civdata'}
            check_civ=check_civ+1;
        case 'netcdf'
            check_netcdf=check_netcdf+1;
    end 
end
if check_civ
    enable='on';
else
    enable='off';
end
set(handles.VelTypeMenu,'Visible',enable)
set(handles.VelType_text,'Visible',enable)
if check_civ>=2
    enable='on';
else
    enable='off';
end
set(handles.VelTypeMenu_1,'Visible',enable)
set(handles.VelType_text_1,'Visible',enable)
if check_civ || check_netcdf
    enable='on';
else
    enable='off';
end
set(handles.FieldMenu,'Visible',enable)
set(handles.Field_text,'Visible',enable)
if check_civ+ check_netcdf>=2
    enable='on';
else
    enable='off';
end
set(handles.FieldMenu_1,'Visible',enable)
set(handles.Field_text_1,'Visible',enable)
FieldString={''};
if check_civ
    FieldString=[calc_field;{'get_field...'}];
elseif check_netcdf 
    FieldString={'get_field...'};
end
set(handles.FieldMenu,'String',FieldString)
FieldString={''};
if check_civ>=2
    FieldString=[calc_field;{'get_field...'}];
elseif check_civ+check_netcdf>=2
    FieldString={'get_field...'};
end
set(handles.FieldMenu_1,'String',{'get_field...'})
% testfield=isequal(get(handles.FieldMenu,'enable'),'on');
% testfield_1=isequal(get(handles.FieldMenu_1,'enable'),'on');
% testveltype=isequal(get(handles.VelTypeMenu,'enable'),'on');
% testveltype_1=isequal(get(handles.VelTypeMenu_1,'enable'),'on');
% testtransform=isequal(get(handles.transform_fct,'Enable'),'on');
% testnc=0;
% testnc_1=0;
% testcivx=0;
% testcivx_1=0;
% testima=0; %test for image input
% if isequal(lower(FileExt),'.avi') %.avi file
%     testima=1;
% elseif ~isempty(imformats(FileExt(2:end))) 
%     testima=1;
% elseif isequal(FileExt,'.vol')
%      testima=1;
% end
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
% switch FileType
%     case {'civx','civdata'}
%     view_FieldMenu(handles,'on')
%     menustr=get(handles.FieldMenu,'String');
%     if isequal(menustr,{'get_field...'})
%         set(handles.FieldMenu,'String',{'get_field...';'velocity';'vort';'div';'more...'})
%     end
%     set(handles.VelTypeMenu,'Visible','on')
%     set(handles.FieldTransform,'Visible','on')
%     %      view_TRANSFORM(handles,'on')
%     %     TODO: second menu
%     %           view_FieldMenu_1(handles,'on')
%     %     if testcivx_1
%     %         menustr=get(handles.FieldMenu_1,'String');
%     %         if isequal(menustr,{'get_field...'})
%     %             set(handles.FieldMenu_1,'String',{'get_field...';'velocity';'vort';'div';'more...'})
%     %         end
%     %     else
%     %         set(handles.FieldMenu_1,'Value',1)
%     %         set(handles.FieldMenu_1,'String',{'get_field...'})
%     %     set(handles.VelTypeMenu_1,'Visible','on')
%     %     set(handles.VelType_text_1,'Visible','on');
%     %     end
%     %     view_FieldMenu_1(handles,'off')
%     case 'netcdf'
%     view_FieldMenu(handles,'on')
%     set(handles.FieldMenu,'Value',1)
%     set(handles.FieldMenu,'String',{'get_field...'})
%     set(handles.FieldTransform,'Visible','off')
%     %     view_TRANSFORM(handles,'off')
%     case {'image','multimage','video'}
%     view_FieldMenu(handles,'off')
%     view_FieldMenu_1(handles,'off')
%     set(handles.VelTypeMenu,'Visible','off')
%     set(handles.VelType_text,'Visible','off');
% end



%% store the series info in 'UserData'

SeriesData.i1_series{iview}=i1_series;
SeriesData.i2_series{iview}=i2_series;
SeriesData.j1_series{iview}=j1_series;
SeriesData.j2_series{iview}=j2_series;
SeriesData.FileType{iview}=FileType;
SeriesData.Time{iview}=time;
set(handles.series,'UserData',SeriesData)



return

%% set default options in menu 'Fields'%% TODO: check VelType 
if ~testima
    testcivx=0;
    if isfield(UvData,'FieldsString') && isequal(UvData.FieldsString,{'get_field...'})% field menu defined as input (from get_field)
        set(handles_Fields,'Value',1)
        set(handles_Fields,'String',{'get_field...'})
        UvData=rmfield(UvData,'FieldsString');
    else
        Data=nc2struct(FileName,'ListGlobalAttribute','Conventions','absolut_time_T0','civ');
        if strcmp(Data.Conventions,'uvmat/civdata') ||( ~isempty(Data.absolut_time_T0)&& ~isequal(Data.civ,0))%if the new input is Civx
            FieldList=calc_field;
            set(handles_Fields,'String',[{'image'};FieldList;{'get_field...'}]);%standard menu for civx data
            set(handles_Fields,'Value',2) % set menu to 'velocity'
            col_vec=FieldList;
            col_vec(1)=[];%remove 'velocity' option for vector color (must be a scalar)
            testcivx=1;
        end
        if ~testcivx
            set(handles_Fields,'Value',1) % set menu to 'get_field...
            set(handles_Fields,'String',{'get_field...'})
            col_vec={'get_field...'};
        end
        set(handles.ColorScalar,'String',col_vec)
    end
end
set(handles.uvmat,'UserData',UvData)

%% set index navigation options and refresh plots
scan_option='i';%default
state_j='off'; %default
if index==2
    if get(handles.scan_j,'Value')
        scan_option='j'; %keep the scan option for the second fiel series
    end
    if strcmp(get(handles.j1,'Visible'),'on')
        state_j='on';
    end
end
if ~isempty(j1_series) 
        state_j='on';
        if isequal(nbfield,1) &&index==1
            scan_option='j'; %scan j index by default if nbfield=1                
        end 
end
if isequal(scan_option,'i')
     set(handles.scan_i,'Value',1)
     scan_i_Callback([],[], handles); 
else
     set(handles.scan_j,'Value',1)
     scan_j_Callback([],[], handles); 
end
set(handles.scan_j,'Visible',state_j)
set(handles.j1,'Visible',state_j)
set(handles.j2,'Visible',state_j)
set(handles.last_j,'Visible',state_j);
set(handles.frame_j,'Visible',state_j);
set(handles.j_text,'Visible',state_j);
if ~isempty(i2_series)||~isempty(j2_series)
    set(handles.CheckFixPair,'Visible','on')
elseif index==1
    set(handles.CheckFixPair,'Visible','off')
end


mode_Callback(hObject, eventdata, handles)

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
        [InputTable{ind_list,3},InputTable{(ind_list),4},errormsg]=update_indices(handles,fileinput,ind_list);
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
    for iview=1:size(InputTable,1)
        if ~isempty(SeriesData.j1_series{iview})
            state_j='on';
        end
        if ~isempty(SeriesData.i2_series{iview})||~isempty(SeriesData.j2_series{iview})
            state_Pairs='on';
            ListViewString{iview}=num2str(iview);
            if check_lines(iview)
                val=iview;%select the last pair if it is a new entry
            end
        end
        if strcmp(SeriesData.FileType{iview},'civx')||strcmp(SeriesData.FileType{iview},'civdata')
            state_InputFields='on';
        end
    end
end
set(handles.ListView,'Value',val)
set(handles.ListView,'String',ListViewString)
if strcmp(state_Pairs,'on')
    ListView_Callback(hObject,eventdata,handles)
end
set(handles.PairString,'Visible',state_Pairs)
enable_j(handles,state_j)


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
string=list_pair{get(handles.ListPairs,'Value')};
string=regexprep(string,',.*','');%removes time indication (after ',')
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
    SeriesData.j1_series{iview},SeriesData.j2_series{iview},SeriesData.time{iview});% update the menu of pairs depending on the available netcdf files
ListPairs_Callback([],[],handles)

%------------------------------------------------------------------------
function num_ref_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
num_ref_i_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function update_mode(handles,i1_series,i2_series,j1_series,j2_series,time)
%------------------------------------------------------------------------    
check_burst=1;
if isempty(j2_series)% no pair menu to display
    if isempty(i2_series)
        set(handles.mode,'String',{''})
    else
        set(handles.mode,'Value',1)
        set(handles.mode,'String',{'series(Di)'})
    end
else
    nbfield=size(j2_series,1);
    nbfield2=size(j2_series,2);
    set(handles.mode,'String',{'bursts';'series(Dj)'})
    if nbfield2>10 || nbfield==1
        set(handles.mode,'Value',2);
    else
        set(handles.mode,'Value',1);
        check_burst=1;
    end
end
if check_burst
    enable_i(handles,'On')
    enable_j(handles,'Off') %do not display j index scanning in burst mode (j is fixed by the burst choice)
else
    enable_i(handles,'On')
    enable_j(handles,'Off')
end
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
ref_j=str2num(get(handles.num_ref_j,'String'));
if isempty(ref_i)
    ref_i=1;
end
if isempty(ref_j)
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
if isempty(displ_pair)
    msgbox_uvmat('ERROR',['no file available for the selected subdirectory ' subdir])
end



% return
% %%%%%%%%
% %update num_first_i and num_last_i according to the chosen image pairstring 
% testupdate=0;
% 
% SeriesData=get(handles.series,'UserData');
% NomType=SeriesData.NomType{Val};
% list_pair=get(handles.ListPairs,'String');%get the menu of image pairs
% index_pair=get(handles.ListPairs,'Value');
% str_pair=list_pair{index_pair};
% ind_equ=strfind(str_pair,'=');%find '='
% ind_sep=strfind(str_pair,'|');%find pair separator '|'
% ind_com=strfind(str_pair,':');%find ':'
% test_bursts=0;
% if isempty(ind_sep)
%     ind_sep=strfind(str_pair,'-');%find pair separator if it is not '|'
%     test_bursts=1;% we are in the case of bursts
% end
% displ_num=[0 0 0 0]; %default
% if ~isempty(ind_sep)&& ~strcmp(str_pair(ind_sep-1),'*')% if there is a pair separator ('|' or '-')
%     num1_str=str_pair(ind_equ(1)+1:ind_sep-1);
%     num2_str=str_pair(ind_sep+1:ind_com-1);
%     num1=str2double(num1_str);
%     num2=str2double(num2_str);
%     if isequal(num1_str(1),' ')
%         num1_str(1)=[];
%     end   
%     if isequal(num2_str(end),' ')
%         num2_str(end)=[];
%     end
%     switch NomType
%        case {'_1-2_1'}
%            if isequal(num1_str(1),'0')
%                IndexCell{Val}=['_(i-(i+' num2_str ')_j'];
%            else
%                IndexCell{Val}=['_(i' num1_str ')-(i+' num2_str ')_j'];
%            end
%            displ_num(3)=num1;
%            displ_num(4)=num2;
%        case {'_1-2'}
%            if isequal(num1_str(1),'0')
%                IndexCell{Val}=['_(i' num1_str ')-(i+' num2_str ')'];
%            else
%                IndexCell{Val}=['_(i' num1_str ')-(i+' num2_str ')'];
%            end
%            displ_num(3)=num1;
%            displ_num(4)=num2;
%        case '_1_1-2'
%           if test_bursts
%               IndexCell{Val}=['_i_' num1_str '-' num2_str ];
%           else
%               if isequal(num1_str(1),'0')
%                  IndexCell{Val}=['_i_j-(j+' num2_str ')'];
%               else
%                  IndexCell{Val}=['_i_(j' num1_str ')-(j+' num2_str ')'];
%               end
%           end
%           displ_num(1)=num1;
%           displ_num(2)=num2;
%        case {'#_ab'} %TO COMPLETE
%            IndexCell{Val}=['_i_' num1_str '-' num2_str ];
% 
%     end
% end
% set(handles.NomType,'String',IndexCell)
% SeriesData.displ_num(Val,:)=displ_num;
% set(handles.series,'UserData',SeriesData)
% % set(handles.NomType,'Value',Val)
% 
% if ~isequal(str_pair,'Dj=*|*')&~isequal(str_pair,'Di=*|*')
% 	mode_list=get(handles.mode,'String');
%     mode_value=get(handles.mode,'Value');
%     mode=mode_list{mode_value};
% 	if isequal(mode,'series(Di)')
%         first_i=str2num(get(handles.num_first_i,'String'));
%         last_i=str2num(get(handles.num_last_i,'String'));
%         incr_i=str2num(get(handles.num_incr_i,'String'));
%         num1=first_i:incr_i:last_i;
%         lastfieldCell=get(handles.num_MaxIndex_i,'String');
%         lastfield=str2num(lastfieldCell{1});
%         if ~isempty(lastfield)
%             ind=find((num1-floor(index_pair/2)*ones(size(num1))>0)& (num1+ceil(index_pair/2)*ones(size(num1))<=lastfield));
%             num1=num1(ind);       
%         end
%         if ~isempty(num1)
%             set(handles.num_first_i,'String',num2str(num1(1)));
%             set(handles.num_last_i,'String',num2str(num1(end)));
%         end
%         testupdate=1;
% 	elseif isequal(mode,'series(Dj)')
%         first_j=str2num(get(handles.num_first_j,'String'));
%         last_j=str2num(get(handles.num_last_j,'String'));
%         incr_j=str2num(get(handles.num_incr_j,'String'));
%         num_j=first_j:incr_j:last_j;
%         lastfieldCell=get(handles.num_MaxIndex_j,'String');
%         if ~isempty(lastfieldCell)
%             lastfield2=lastfieldCell{1};
%             ind=find((num_j-floor(index_pair/2)*ones(size(num_j))>0)& ...
%                  (num_j+ceil(index_pair/2)*ones(size(num_j))<=lastfield2));
%         end
%         testupdate=1;
% 	end 
% 	
% 	%update the first and last times of the series
% 	if testupdate && isfield(SeriesData,'Time')
%         if ~isempty(SeriesData.Time{1})
%             displ_time(handles);
%         end
% 	end
% end

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
% set(handles.num_MinIndex_j,'Visible',state)
set(handles.num_first_j,'Visible',state)
set(handles.num_last_j,'Visible',state)
set(handles.num_incr_j,'Visible',state)
% set(handles.num_MaxIndex_j,'Visible',state)
set(handles.num_ref_j,'Visible',state)
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


%list_pair_civ_Callback([],[],handles)



%------------------------------------------------------------------------
% --- Executes on button press in RUN.
function RUN_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%% Read parameters from series
Series=read_GUI(handles.series);%TODO: extend to all input param
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
% RootPath=Series.InputTable(:,1);
% SubDir=Series.InputTable(:,2);
% RootFile=Series.InputTable(:,3);
% NomType=Series.InputTable(:,4);
% FileExt=Series.InputTable(:,5);
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
    Series.FieldTransform.fct_handle=transform_list{menu_index};% transform function handles
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
set(handles.num_ref_j,'String', num2str(ref_j))
ref_j_Callback(hObject, eventdata, handles)
SeriesData=get(handles.series,'UserData');
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
displ_time(handles);


% NomTypeCell=SeriesData.NomType;
% if ~isempty(NomTypeCell)
%     Val=get(handles.NomType,'Value');
%     NomType=NomTypeCell{Val};
%     if isequal(NomType,'_1_1-2')|| isequal(NomType,'_1-2_1')|| isequal(NomType,'_1-2')
%         if isequal(mode,'series(Dj)') 
%             fill_ListPair(handles,Val);% update the menu of pairstring depending on the available netcdf files
%         end
%     end
% end
%------------------------------------------------------------------------
% ---- find the times corresponding to the first and last indices of a series
function displ_time(handles)
%------------------------------------------------------------------------
SeriesData=get(handles.series,'UserData');%
ref_i=[str2num(get(handles.num_first_i,'String')) str2num(get(handles.num_last_i,'String'))];
ref_j=[str2num(get(handles.num_first_j,'String')) str2num(get(handles.num_last_j,'String'))];
% last_i=str2num(get(handles.num_last_i,'String'));
% last_j=str2num(get(handles.num_last_j,'String'));
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
            r=regexp(Pairs.list_pair_civ,'(?<num1>\d+)(?<mode>-)(?<num2>\d+)','names');
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


% 
% NomType=InputTable(:,4);
% mode_list=get(handles.mode,'String');
% index_mode=get(handles.mode,'Value');
% 
% mode=mode_list{index_mode};
% 
% time_first=[];
% time_last=[];
% if ~isfield(SeriesData,'Time')
%     SeriesData.Time{1}=[];
% end
% TimeTable=get(handles.TimeTable,'Data');
% for iview=1:size(TimeTable,1)
%     time_first_cell{iview}='?';
%     time_last_cell{iview}='?';%default
%     time=SeriesData.Time{iview};
%     if isequal(NomType{iview},'_1-2_1')|isequal(NomType{iview},'_1_1-2')|isequal(NomType{iview},'#_ab')|isequal(NomType{iview},'_1-2')
%         if isfield(SeriesData,'displ_num')& ~isempty(SeriesData.displ_num)
%             ind_shift=SeriesData.displ_num(iview,:);
%             if isequal(mode,'bursts')
%                 first_j=0;
%                 last_j=0;
%             end
%             first_i1=first_i +ind_shift(3);
%             first_i2 =first_i +ind_shift(4);
%             first_j1 =first_j +ind_shift(1);
%             first_j2 =first_j +ind_shift(2);
%             last_i1=last_i +ind_shift(3);
%             last_i2 =last_i +ind_shift(4);    
%             last_j1 =last_j +ind_shift(1);
%             last_j2 =last_j +ind_shift(2);
%             siz=size(SeriesData.Time{1});
%             if first_i1>=1 && first_j1>=1 && siz(1)>=last_i2 && siz(2)>=last_j2
%                 time_first=(time(first_i1,first_j1)+time(first_i2,first_j2))/2;
%                 time_last=(time(last_i1,last_j1)+time(last_i2,last_j2))/2;
%             else%read the time in the nc files
%                 RootPath=get(handles.RootPath,'String');
%                 RootFile=get(handles.RootFile,'String');
%                 SubDir=get(handles.SubDir,'String');
%                 %VelType=get(handles.VelType,'String');
%                 VelType_str=get(handles.VelTypeMenu,'String');
%                 VelType_val=get(handles.VelTypeMenu,'Value');
%                 VelType=VelType_str{VelType_val};
%                 filebase=fullfile(RootPath{1},RootFile{1});
%                 [filefirst]=name_generator(filebase,first_i1,first_j1,'.nc',NomType{iview},1,first_i2,first_j2,SubDir{iview});
%                 if  exist(filefirst,'file')
%                     Attrib=nc2struct(filefirst,[]);
%                     if isfield(Attrib,'Time')
%                         time_first=Attrib.Time;
%                     else
%                         if isfield(Attrib,'absolut_time_T0')
%                             time_first=Attrib.absolut_time_T0;
%                         end
%                         if isfield(Attrib,'absolut_time_T0_2')&&~(isequal(VelType,'civ1')||isequal(VelType,'interp1')||isequal(VelType,'filter1'))
%                             time_first=Attrib.absolut_time_T0_2;
%                         end
%                     end 
%                 end
%                 [filelast]=name_generator(filebase,last_i1,last_j1,'.nc',NomType{iview},1,last_i2,last_j2,SubDir{iview});
%                 if exist(filelast,'file')
%                    Attrib=nc2struct(filelast,[]);
%                     if isfield(Attrib,'Time')
%                         time_last=Attrib.Time;
%                     else
%                         if isfield(Attrib,'absolut_time_T0')
%                             time_last=Attrib.absolut_time_T0;
%                         end
%                         if isfield(Attrib,'absolut_time_T0_2')&&~(isequal(VelType,'civ1')||isequal(VelType,'interp1')||isequal(VelType,'filter1'))
%                             time_last=Attrib.absolut_time_T0_2;
%                         end
%                     end 
%                 end
%             end
%         end
%     else
%         siz=size(time);
%         if siz(1)>=last_i && siz(2)>=last_j && first_i>=1 && first_j>=1
%             time_first=times(first_i,first_j);
%             time_last=times(last_i,last_j); 
%         end
%     end
%     time_first_cell{iview}=num2str(time_first,4);
%     time_last_cell{iview}=num2str(time_last,4);
% end
% 

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
InputTable=get(handles.InputTable,'Data');
nb_series=size(InputTable,1);
% if ~isempty(checkcell)
% nb_series=checkcell(end);
% end
% nb_series=size(InputFiles,1)
testima_series=1; %test for a list of images only
testima=1;
testima_1=1;
testciv_series=1;
for iview=1:nb_series
     ext=InputTable{iview,5};
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
%                     set(handles.Field_frame,'Visible','on')
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
        [FileName, PathName, filterindex] = uigetfile( ...
       {'*.xml;*.mat', ' (*.xml,*.mat)';
       '*.xml',  '.xml files '; ...
        '*.mat',  '.mat matlab files '}, ...
        'Pick an xml object file (or use uvmat to create it)',defaultname{1});
        fileinput=[PathName FileName];%complete file name 
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
%         data.desable_plot=1;
        [SeriesData.hset_object,SeriesData.sethandles]=set_object(data);% call the set_object interface
     end 
else
    set(handles.GetObject,'BackgroundColor',[0.7 0.7 0.7])%put activated buttons to green
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
% --- Executes on button press in REFRESH_INDICES.
    function REFRESH_INDICES_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------        
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
        [InputTable{ind_list,3},InputTable{(ind_list),4},errormsg]=update_indices(handles,fileinput,ind_list);
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
    for iview=1:size(InputTable,1)
        if ~isempty(SeriesData.j1_series{iview})
            state_j='on';
        end
        if ~isempty(SeriesData.i2_series{iview})||~isempty(SeriesData.j2_series{iview})
            state_Pairs='on';
            ListViewString{iview}=num2str(iview);
            if check_lines(iview)
                val=iview;%select the last pair if it is a new entry
            end
        end
        if strcmp(SeriesData.FileType{iview},'civx')||strcmp(SeriesData.FileType{iview},'civdata')
            state_InputFields='on';
        end
    end
end
set(handles.ListView,'Value',val)
set(handles.ListView,'String',ListViewString)
if strcmp(state_Pairs,'on')
    ListView_Callback(hObject,eventdata,handles)
end
set(handles.PairString,'Visible',state_Pairs)
enable_j(handles,state_j)
set(handles.REFRESH_INDICES,'BackgroundColor',[1 0 0])
set(handles.REFRESH_INDICES,'visible','off')

% -----------------------------------------------------------------------
% --- Update min and max indices of a file series by scanning with find_file_series
% --- which also changes the root file and NomType in case of movie. Also adjust the string representation of indices (e.g;
% --- 1 or 001 by the function find_file_series
% --- This function also dispaly the set of availbale files in the series
% --- and the menus appropriate to the file type as well as timing possibly set
% --- by an xml image documentation file
function [RootFile,NomType,errormsg]=update_indices(handles,fileinput,iview)
% -----------------------------------------------------------------------
%% look for min and max indices existing in the file series and update SeriesData
errormsg='';
[FilePath,FileName,FileExt]=fileparts(fileinput);
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
% the root name and indices may be corrected by including the first index i1 if a corresponding xml file exists
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,Object,i1,i2,j1,j2]=find_file_series(FilePath,[FileName FileExt]);
if isempty(RootFile)&&isempty(i1_series)
    errormsg='no input file in the series';
    return
end

%% adjust the min and max indices common to all the file series
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

%% display the set of existing files as an image
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
% testnc=0;
% testnc_1=0;
% testcivx=0;
% testcivx_1=0;
% testima=0; %test for image input
% if isequal(lower(FileExt),'.avi') %.avi file
%     testima=1;
% elseif ~isempty(imformats(FileExt(2:end))) 
%     testima=1;
% elseif isequal(FileExt,'.vol')
%      testima=1;
% end
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
switch FileType
    case {'civx','civdata'}
    view_FieldMenu(handles,'on')
    menustr=get(handles.FieldMenu,'String');
    if isequal(menustr,{'get_field...'})
        set(handles.FieldMenu,'String',{'get_field...';'velocity';'vort';'div';'more...'})
    end
    set(handles.VelTypeMenu,'Visible','on')
    set(handles.FieldTransform,'Visible','on')
    %      view_TRANSFORM(handles,'on')
    %     TODO: second menu
    %           view_FieldMenu_1(handles,'on')
    %     if testcivx_1
    %         menustr=get(handles.FieldMenu_1,'String');
    %         if isequal(menustr,{'get_field...'})
    %             set(handles.FieldMenu_1,'String',{'get_field...';'velocity';'vort';'div';'more...'})
    %         end
    %     else
    %         set(handles.FieldMenu_1,'Value',1)
    %         set(handles.FieldMenu_1,'String',{'get_field...'})
    %     set(handles.VelTypeMenu_1,'Visible','on')
    %     set(handles.VelType_text_1,'Visible','on');
    %     end
    %     view_FieldMenu_1(handles,'off')
    case 'netcdf'
    view_FieldMenu(handles,'on')
    set(handles.FieldMenu,'Value',1)
    set(handles.FieldMenu,'String',{'get_field...'})
    set(handles.FieldTransform,'Visible','off')
    %     view_TRANSFORM(handles,'off')
    case {'image','multimage','video'}
    view_FieldMenu(handles,'off')
    view_FieldMenu_1(handles,'off')
    set(handles.VelTypeMenu,'Visible','off')
    set(handles.VelType_text,'Visible','off');
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
            time{iview}=XmlData.Time;
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
    time{iview}=XmlData.Time;
    if error==2, warntext=['no file ' FileBase '.civ'];
    elseif error==1, warntext='inconsistent number of fields in the .civ file';
    end  
end

%% update time table
TimeTable=get(handles.TimeTable,'Data')
TimeTable{iview,1}=time(MinIndex_i,MinIndex_j);
TimeTable{iview,4}=time(MaxIndex_i,MaxIndex_j);
set(handles.TimeTable,'Data',TimeTable)

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
% set(handles.mode,'Visible','off') % do not show index pairstring by default
set(handles.PairString,'Visible','off')
% set(handles.num_ref_i,'Visible','off')
% set(handles.ref_i_text,'Visible','off')
testpair=0;
%set the menus of image pairstring and default selection for series
%list pairstring if relevant
% Val=get(handles.NomType,'Value');
% synchronise_view(handles,Val)

% if ~isfield(SeriesData,'j1_series')||isempty(SeriesData.j1_series{index})
%     state_j='off'; %no need for j index
% else
%     state_j='on'; %case of j index
% end
% show index pairstring if files exist
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
