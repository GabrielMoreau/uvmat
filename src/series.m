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
function series_OpeningFcn(hObject, eventdata, handles,param)
global nb_builtin_ACTION nb_builtin_transform
% Choose default command line output for series
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
%default initial parameters
drawnow
set(hObject,'Units','pixels')
set(handles.PairString,'ColumnName',{'pairs'})
set(handles.PairString,'ColumnEditable',logical(0))
set(handles.PairString,'ColumnFormat',{'char'})
set(handles.PairString,'Data',{''})
series_ResizeFcn(hObject, eventdata, handles)%resize table according to series GUI size
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%allows mouse action with right button (zoom for uicontrol display)
dir_perso=prefdir;
test_profil_perso=0;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
     h=load (profil_perso);
     if isfield(h,'MenuFile')
          for ifile=1:min(length(h.MenuFile),5)
              eval(['set(handles.MenuFile_' num2str(ifile) ',''Label'',h.MenuFile{ifile});'])
          end
     end
     test_profil_perso=1;
end

%check default input data
if ~exist('param','var')
    param=[]; %default
end

%% file name and browser initialisation
if isfield(param,'transform_str')
    set(handles.TransformName,'String',param.transform_str)
end
if isfield(param,'transform_val')
    set(handles.TransformName,'Value',param.transform_val);
else
     set(handles.TransformName,'Value',1);%default
end
if isfield(param,'FileName')
    InputTable={'','','','',''};
    set(handles.InputTable,'Data',InputTable)
    if isfield(param,'FileName_1')
        display_file_name(handles,param.FileName_1,0)
        display_file_name(handles,param.FileName,1)
    else
        display_file_name(handles,param.FileName,0)
    end
end  
if isfield(param,'incr_i')
    set(handles.num_incr_i,'String',num2str(param.incr_i))
end
if isfield(param,'incr_j')
    set(handles.num_incr_j,'String',num2str(param.incr_j))
end

%% fields input initialisation
if isfield(param,'list_fields')&& isfield(param,'index_fields') &&~isempty(param.list_fields) &&~isempty(param.index_fields)
    set(handles.FieldName,'String',param.list_fields);% list menu fields
    set(handles.FieldName,'Value',param.index_fields);% selected string index
end
if isfield(param,'Coord_x_str')&& isfield(param,'Coord_x_val')
        set(handles.Coord_x,'String',param.Coord_x_str);% list menu fields
    set(handles.Coord_x,'Value',param.Coord_x_val);% selected string index
end
if isfield(param,'Coord_y_str')&& isfield(param,'Coord_y_val')
        set(handles.Coord_y,'String',param.Coord_y_str);% list menu fields
    set(handles.Coord_y,'Value',param.Coord_y_val);% selected string index
end

%loads the information stored in prefdir to initiate  the list of ActionName functions
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
menu_str={'';'sub_field';'phys';'phys_polar'};
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

%% read the list of transform functions stored in the personal file 'uvmat_perso.mat' in prefdir
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
set(handles.ActionName,'String',fct_menu)
set(handles.ActionName,'UserData',fct_path)% store the list of path in UserData of ACTION
menu_str=menu_str(find(testexist));
fct_handle=fct_handle(find(testexist));
menu_str=[menu_str;{'more...'}];
set(handles.TransformName,'String',menu_str)
set(handles.TransformName,'UserData',fct_handle)% store the list of path in UserData of ACTION

%% Adjust the GUI according to the binaries available in PARAM.xml
path_uvmat=fileparts(which('uvmat')); %path to civ
addpath (path_uvmat) ; %add the path to civ, (useful in case of change of working directory after civ has been s opened in the working directory)
errormsg=[];%default error message
xmlfile='PARAM.xml';
if exist(xmlfile,'file')
    try
        t=xmltree(xmlfile);
        sparam=convert(t);
    catch ME
        errormsg={' Unable to read the file PARAM.xml defining the civx binaries:';ME.message};
    end
else
    errormsg=[xmlfile ' not found: path to civx binaries undefined'];
end
if ~isempty(errormsg)
    msgbox_uvmat('WARNING',errormsg);
end
test_batch=0;%default: ,no batch mode available
if isfield(sparam,'BatchParam') && isfield(sparam.BatchParam,'BatchMode')
    test_batch=strcmp(sparam.BatchParam.BatchMode,'sge'); %sge is currently the only implemented batch mod
end
RUNVal=get(handles.RunMode,'Value');
if test_batch==0
   if RUNVal>2
       set(handles.RunMode,'Value',1)
   end
   set(handles.RunMode,'String',{'local';'background'})
else
    set(handles.RunMode,'String',{'local';'background';'cluster'})
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
if isempty(fileinput),return;end %abandon if no file is introduced by the browser
[path,name,ext]=fileparts(fileinput);
if isequal(ext,'.xml')
    [Param,Heading]=xml2struct(fileinput);
    if ~strcmp(Heading,'Series')
        msg_box_uvmat('ERROR','xml file heading is not <Series>')
    else
        fill_GUI(Param,handles);%fill the GUI with the parameters retrieved from the xml file
        if isfield(Param,'CheckObject')&& Param.CheckObject
            set_object(Param.ProjObject)
        end
        set(handles.REFRESH,'UserData',[1:size(Param.InputTable,1)])
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
        [RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,tild,FileType,MovieObject]=...
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
        update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,MovieObject,iview)
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
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,MovieObject,i1,i2,j1,j2]=find_file_series(FilePath,[FileName FileExt]);
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
update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,MovieObject,iview);

%------------------------------------------------------------------------
% --- Update information about a new field series (indices to scan, timing,
%     calibration from an xml file
function update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,VideoObject,iview)
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
if size(i1_series,2)==1
    MinIndex_j=1;
    MaxIndex_j=1; 
    MinIndex_i=min(find(i1_series));
    MaxIndex_i=max(find(i1_series));
else
pair_max=squeeze(max(i1_series,[],1)); %max on pair index
j_max=max(pair_max,[],1);
%i_sum=sum(sum(i1_series,2),1);%sum of i1_series on the last index
MaxIndex_i=max(find(j_max))-1;% max ref index i
MinIndex_i=min(find(j_max))-1;% min ref index i
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
    if isempty(MinIndex_j)
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
        TimeTable{iview,2}=time(first_i,first_j);
        TimeTable{iview,3}=time(last_i,last_j);
        TimeTable{iview,4}=time(MaxIndex_i,MaxIndex_j);
    end
    set(handles.TimeTable,'Data',TimeTable)
end

%% number of slices
NbSlice=1;%default
if isfield(XmlData,'GeometryCalib') && isfield(XmlData.GeometryCalib,'SliceCoord')
    siz=size(XmlData.GeometryCalib.SliceCoord);
    if siz(1)>1
        NbSlice=siz(1);
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
SeriesData.i1_series{iview}=i1_series;
SeriesData.i2_series{iview}=i2_series;
SeriesData.j1_series{iview}=j1_series;
SeriesData.j2_series{iview}=j2_series;
SeriesData.FileType{iview}=FileType;
SeriesData.Time{iview}=time;
set(handles.series,'UserData',SeriesData)

%% enable j index visibilitycellfun(@isempty,regexp(PairString,'^j'))
state='off';
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
    LineData=interp1(x,LineData,xI,'nearest');
    CData(ind_y,:)=ones(size(ind_y'))*LineData;
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
        [FieldList,ColorList]=calc_field;
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
        hget_field=get_field(FileName);
        hhget_field=guidata(hget_field);
        get_field('RUN_Callback',hhget_field.RUN,[],hhget_field);
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
% for iview=1:numel(SeriesData.i1_series)
% [tild,index_min(iview)]=min(SeriesData.i1_series{iview}(SeriesData.i1_series{iview}>0));
% [tild,index_max(iview)]=max(SeriesData.i1_series{iview}(SeriesData.i1_series{iview}>0));
% end
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
%index_first=(ref_i(1)-1)*(size(SeriesData.i1_series{iview_min},2)-1)+ref_j(1);
%index_last=(ref_i(2)-1)*(size(SeriesData.i1_series{iview_max},2)-1)+ref_j(2);
index_first=(ref_i(1))*(size(SeriesData.i1_series{iview_min},2))+ref_j(1)+1;
index_last=(ref_i(2))*(size(SeriesData.i1_series{iview_max},2))+ref_j(2)+1;
end
range=index_max-index_min+1;
coeff_min=(index_first-index_min)/range;
coeff_max=(index_last-index_min+1)/range;
Position=get(handles.Waitbar,'Position');
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
[h_fun,Series,filexml,errormsg]=prepare_jobs(handles);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    return
end
RunModeList=get(handles.RunMode,'String');
RunMode=RunModeList{get(handles.RunMode,'Value')};

switch RunMode
    case 'local'
        Series=h_fun(Series);
        if ~isempty(filexml)
            t=struct2xml(Series);
            t=set(t,1,'name','Series');
            save(t,filexml);
        end
    case 'background'
        if isempty(filexml)
            Series=h_fun(Series);% no background in the absence of output file
        else
            % update the xml file after interactive input with the function
            Series.Specific='?';
            Series=h_fun(Series);
            t=struct2xml(Series);
            t=set(t,1,'name','Series');
            save(t,filexml);
            path_uvmat=fileparts(which('uvmat'));
            
            filename_bat=regexprep(filexml,'.xml$','.bat');
            [fid,message]=fopen(filename_bat,'w');
            if isequal(fid,-1)
                msgbox_uvmat('ERROR', ['creation of .bat file: ' message]);
                return
            end
            path_fct=get(handles.ActionPath,'String');
            filelog=regexprep(filexml,'.xml$','.log');
       
            switch computer
                case {'GLNX86','GLNXA64','MACI64'}
                    text_matlabscript=[...
                        '#!/bin/bash \n'...
                        '. /etc/sysprofile \n'...
                        'matlab -nodisplay -nosplash -nojvm -logfile ''' filelog ''' <<END_MATLAB \n'...
                        'addpath(''' path_uvmat '''); \n'...
                        'addpath(''' Series.Action.ActionPath '''); \n'...
                        '' Series.Action.ActionName  '( ''' filexml '''); \n'...
                        'exit \n'...
                        'END_MATLAB \n'];
                    fprintf(fid,text_matlabscript);
                    fclose(fid);
                    system(['chmod +x ' filename_bat]);% set the file to executable
                    system(['. ' filename_bat ' &']);%execute fct
                    
                case {'PCWIN','PCWIN64'}
                    text_matlabscript=['matlab -automation -logfile ' regexprep(filelog,'\\','\\\\')...
                        ' -r "addpath(''' regexprep(path_uvmat,'\\','\\\\') ''');'...
                        'addpath(''' regexprep(Series.Action.ActionPath,'\\','\\\\') ''');'...
                        '' Series.Action.ActionName  '( ''' regexprep(filexml,'\\','\\\\') ''');exit"'];
                    fprintf(fid,text_matlabscript);
                    fclose(fid);
                    dos([filename_bat ' &']);
            end
        end
        update_waitbar(handles.Waitbar,1); % put the waitbar to end position to indicate lounching is finished
end

set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])

%------------------------------------------------------------------------
function STOP_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RUN, 'BusyAction','cancel')
set(handles.RUN,'BackgroundColor',[1 0 0])
set(handles.RUN,'enable','on')
% set(handles.BATCH,'BackgroundColor',[1 0 0])
% set(handles.BATCH,'enable','on')

%------------------------------------------------------------------------
% --- Executes on button press in BATCH.
function BATCH_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------    


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
function [h_fun,Series,filexml,errormsg]=prepare_jobs(handles,run)
%INPUT: 
% handles: handles of graphic objects on the GUI series
% run=0, just to display parameters for MenuExport/GUI config
% run=1 (default) prepare the computation

%------------------------------------------------------------------------
h_fun=[];
filexml='';
errormsg='';
if ~exist('run','var')
    run=1;
end
%% Read parameters from series
Series=read_GUI(handles.series);
if isfield(Series,'Pairs')
Series=rmfield(Series,'Pairs'); %info Pairs not needed for output
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
    incr_j=Series.IndexRange.incr_j;
    last_j=Series.IndexRange.last_j;
end

%% read input file parameters and set menus
menu_coord_state=get(handles.TransformName,'Visible');
if isequal(menu_coord_state,'on')
    menu_index=get(handles.TransformName,'Value');
    transform_list=get(handles.TransformName,'UserData');
    Series.FieldTransform.TransformHandle=transform_list{menu_index};% transform function handles
end

if last_i < first_i | last_j < first_j , msgbox_uvmat('ERROR','last field number must be larger than the first one'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;

%% projection object
if isfield(Series,'CheckObject')
    if Series.CheckObject
        hset_object=findobj(allchild(0),'tag','set_object');
        Series.ProjObject=read_GUI(hset_object);
        CheckObject_Callback([], [], handles)
    end
else
    Series.CheckObject=0;
end

%% get_field GUI
if isfield(Series,'InputFields')&&isfield(Series.InputFields,'Field')
    if strcmp(Series.InputFields.Field,'get_field...')
        hget_field=findobj(allchild(0),'name','get_field');
        Series.GetField=read_GUI(hget_field);
    end
end

if ~run
    return
end

%% defining the ActionName function handle
list_action=get(handles.ActionName,'String');% list menu action
index=get(handles.ActionName,'Value');
action= list_action{index}; % selected string
%Series.Action=action;%name of the processing programme
Series.hseries=handles.series; % handles to the series GUI
path_series=which('series');
list_path=get(handles.ActionName,'UserData');
fct_path=list_path{index}; %path stored for the function ACTION
if ~isequal(fct_path,path_series)
    eval(['spath=which(''' action ''');']) %spath = current path of the selected function ACTION
    if ~exist(fct_path,'dir')
        errormsg=['The prescribed function path ' fct_path ' does not exist'];
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

%% create the output data directory and write in it the xml file from the GUI config
%determine the root file corresponding to the first sub dir
if isfield(Series,'OutputSubDir')
    SubDirOut=[Series.OutputSubDir Series.OutputDirExt];
    SubDirOutNew=SubDirOut;
    iview=1;
    SeriesData=get(handles.series,'UserData');
    if size(Series.InputTable,1)>1 && isfield(SeriesData,'AllowInputSort') && isfield(SeriesData.AllowInputSort)
        [tild,iview]=sort(Series.InputTable(:,2)); %subdirectories sorted in alphabetical order
        Series.InputTable=Series.InputTable(iview,:);
    end
    detect=exist(fullfile(Series.InputTable{1,1},SubDirOutNew),'dir');% test if  the dir  already exist
    check_create=1; %need to create the result directory by default
    while detect
        answer=msgbox_uvmat('INPUT_Y-N',['use existing ouput directory: ' fullfile(Series.InputTable{1,1},SubDirOutNew) ', possibly delete previous data']);
        if isequal(answer,'Yes')
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
 %   Series.OutputSubDir=SubDirOutNew;
 %   Series.OutputDir=fullfile(Series.InputTable{1,1},Series.OutputSubDir);%directory set for output results
    Series.OutputRootFile=Series.InputTable{1,3};% the first sorted RootFile taken for output
    set(handles.OutputDirExt,'String',Series.OutputDirExt)
    % create output directory 
    OutputDir=fullfile(Series.InputTable{1,1},[Series.OutputSubDir Series.OutputDirExt]);
    if check_create
        [tild,msg1]=mkdir(OutputDir);
        if ~strcmp(msg1,'')
            errormsg=['cannot create ' OutputDir ': ' msg1];%error message for directory creation
            return
        end
    end
    filexml=fullfile(OutputDir,[Series.InputTable{1,3} '.xml']);% name of the parameter xml file set in this directory
end
%removes redondant information
Series.IndexRange=rmfield(Series.IndexRange,'TimeTable');
Series.IndexRange=rmfield(Series.IndexRange,'MinIndex');
Series.IndexRange=rmfield(Series.IndexRange,'MaxIndex');
%removes empty lines of InputTable
empty_line=zeros(size(Series.InputTable,1),1);
for iline=1:size(Series.InputTable,1)
    empty_line(iline)=isequal(Series.InputTable(iline,1:3),{'','',''});
end
Series.InputTable(find(empty_line),:)=[];

%------------------------------------------------------------------------
% --- Executes on selection change in ActionName.
function ActionName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
global nb_builtin_ACTION
list_ACTION=get(handles.ActionName,'String');% list menu fields
index_ACTION=get(handles.ActionName,'Value');% selected string index
ACTION= list_ACTION{index_ACTION}; % selected function name
path_series=which('series');%path to series.m
list_path=get(handles.ActionName,'UserData');%list of recorded paths to functions of the list ACTION
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
    
   % insert the choice in the actionname menu
   menu_str=update_menu(handles.ActionName,ACTION);%new action menu in which the new item has been appended if needed
   index_ACTION=get(handles.ActionName,'Value');% currently selected index in the list
   list_path{index_ACTION}=PathName;
   if length(menu_str)>nb_builtin_ACTION+5; %nb_builtin=nbre of functions always remaining in the initial menu
       nbremove=length(menu_str)-nb_builtin_ACTION-5;
       menu_str(nb_builtin_ACTION+1:end-5)=[];
       list_path(nb_builtin_ACTION+1:end-4)=[];
       index_ACTION=index_ACTION-nbremove;
       set(handles.ActionName,'Value',index_ACTION)
       set(handles.ActionName,'String',menu_str)
   end
   list_path{index_ACTION}=PathName;
   set(handles.ActionName,'UserData',list_path);
   set(handles.ActionPath,'enable','inactive')% indicate that the current path is accessible (not 'off')
   
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

%check the current ActionPath to the selected function
PathName=list_path{index_ACTION};%current recorded path
set(handles.ActionPath,'String',PathName); %show the path to the senlected function

%reinitialise the waitbar
update_waitbar(handles.Waitbar,0)

%default setting for the visibility of the GUI elements
set(handles.num_NbSlice,'Visible','off')
set(handles.NbSlice_title,'Visible','off')
set(handles.VelType,'Visible','off');
set(handles.VelType_text,'Visible','off');
set(handles.VelType_1,'Visible','off');
set(handles.VelType_text_1,'Visible','off');
set(handles.InputFields,'Visible','off')
set(handles.FieldName_1,'Visible','off')
%view_FieldMenu_1(handles,'off')
set(handles.FieldTransform,'Visible','off')
set(handles.CheckObject,'Visible','off');
set(handles.ProjObject,'Visible','off');
set(handles.CheckMask,'Visible','off')
set(handles.Mask,'Visible','off')
set(handles.OutputDirExt,'Visible','off')
set(handles.OutputSubDir,'Visible','off')
set(handles.OutputDir_title,'Visible','off') 
%set the displayed GUI item needed for input parameters
if ~isequal(path_series,PathName)
    addpath(PathName)
end
eval(['h_function=@' ACTION ';']);
try
    [fid,errormsg] =fopen([ACTION '.m']);
    InputText=textscan(fid,'%s',1,'delimiter','\n');
    fclose(fid)
    set(handles.ActionName,'ToolTipString',InputText{1}{1})% put the first line of the selected function as tooltip help
end
if ~isequal(path_series,PathName)
    rmpath(PathName)
end
varargout=h_function();
Param_list={};

InputTable=get(handles.InputTable,'Data');
nbview=size(InputTable,1);
SeriesData=get(handles.series,'UserData');
nb_civ=numel(find(strcmp('civx',SeriesData.FileType)|strcmp('civdata',SeriesData.FileType)));
nb_netcdf=numel(find(strcmp('netcdf',SeriesData.FileType)));
for ilist=1:length(varargout)-1
    switch varargout{ilist}
        case 'AllowInputSort'
            if isequal(lower(varargout{ilist+1}),'on')% sort the input table by alphabetical order of the SubDir
                SeriesData.AllowInputSort=1;
                set(handles.series,'UserData',SeriesData)
            end                      
        case 'WholeIndexRange'
            if isequal(lower(varargout{ilist+1}),'on')% set by default the input index range from min to max
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
            end            
        case 'NbSlice'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on')
                set(handles.num_NbSlice,'Visible','on')
                set(handles.NbSlice_title,'Visible','on')
            end
        case 'VelType'   %hidden by default
             if isequal(lower(varargout{ilist+1}),'one') || isequal(lower(varargout{ilist+1}),'two')
                if nb_civ>=1 
                    set(handles.VelType,'Visible','on')
                    set(handles.VelType_text,'Visible','on');
                end
             end
            if isequal(lower(varargout{ilist+1}),'two')
                if nb_civ>=2
                    set(handles.VelType_1,'Visible','on')
                    set(handles.VelType_text_1,'Visible','on');
                end
            end
        case 'FieldName'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'one')||isequal(lower(varargout{ilist+1}),'two')
                if (nb_civ+nb_netcdf)>=1
                 set(handles.FieldName,'Visible','on') % test for MenuBorser 
                 set(handles.InputFields,'Visible','on')
                end
            end
            if isequal(lower(varargout{ilist+1}),'two')
                if (nb_civ+nb_netcdf)>=1
                set(handles.FieldName_1,'Visible','on') 
                end
            end
        case 'FieldTransform'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on') 
                set(handles.TransformName,'Enable','on')
                set(handles.FieldTransform,'Visible','on')
                TransformName_Callback([],[], handles)
            end
        case 'ProjObject'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on')   
                set(handles.CheckObject,'Visible','on')
                set(handles.ProjObject,'Visible','on')
            end
        case 'Mask'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on')   
                set(handles.Mask,'Visible','on')
                 set(handles.CheckMask,'Visible','on');
            end  
        case 'OutputDirExt'
            if ~isempty(varargout{ilist+1})
            set(handles.OutputDirExt,'String',varargout{ilist+1})
            set(handles.OutputDirExt,'Visible','on')
            set(handles.OutputSubDir,'Visible','on')
            set(handles.OutputDir_title,'Visible','on')  
            end
    end
end
if ~isempty(Param_list)
    set(handles.ParamKey,'String',Param_list)
    set(handles.ParamVal,'Visible','on')
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
     filecell=get_file_series(read_GUI(handles.series));
     if exist(filecell{1,1},'file')
        get_field(filecell{1,1})
     end
elseif isequal(field,'more...')
    str=calc_field;
    [ind_answer,v] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',str);
       % edit the choice in the fields and actionname menu
     scalar=cell2mat(str(ind_answer));
     update_menu(handles.FieldName,scalar)
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
elseif isequal(field,'more...')
    str=calc_field;
    [ind_answer,v] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',str);
       % edit the choice in the fields and actionname menu
     scalar=cell2mat(str(ind_answer));
     update_menu(handles.FieldName_1,scalar)
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
% SeriesData=get(handles.series,'UserData');
value=get(handles.CheckObject,'Value');
if value
     set(handles.CheckObject,'BackgroundColor',[1 1 0])%put unactivated buttons to yellow
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
     Object=read_GUI(hset_object);
     set(handles.ProjObject,'String',Object.Name);%display the object name
else
    set(handles.CheckObject,'BackgroundColor',[0.7 0.7 0.7])%put activated buttons to green
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
%-------------------------------------------------------------------
global nb_transform

menu=get(handles.TransformName,'String');
ind_coord=get(handles.TransformName,'Value');
coord_option=menu{ind_coord};
list_transform=get(handles.TransformName,'UserData');
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
   menu=update_menu(handles.TransformName,transform);%add the selected fct to the menu
   ind_coord=get(handles.TransformName,'Value');
   addpath(PathName)
   list_transform{ind_coord}=str2func(transform);% create the function handle corresponding to the newly seleced function
   set(handles.TransformName,'UserData',list_transform)
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

%check the current ActionPath to the selected function
if ~isempty(list_transform{ind_coord})
    func=functions(list_transform{ind_coord});
    set(handles.TransformPath,'String',fileparts(func.file)); %show the path to the senlected function
else
    set(handles.TransformPath,'String',''); %show the path to the senlected function
end



% --------------------------------------------------------------------
function MenuExportConfig_Callback(hObject, eventdata, handles)
global Series
[tild,Series,errormsg]=prepare_jobs(handles,0);
% Series=read_GUI(handles.series);

evalin('base','global Series')%make CurData global in the workspace
display('current series config :')
evalin('base','Series') %display CurData in the workspace
commandwindow; %brings the Matlab command window to the front


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
