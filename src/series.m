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
global nb_builtin nb_transform
% Choose default command line output for series
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
%default initial parameters

%load the list of previously browsed files in menus Open and Open_1
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
     h=load (profil_perso);
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
        update_file(hObject, eventdata, handles,param.FileName_1,0)
        update_file(hObject, eventdata, handles,param.FileName,1)
    else
        update_file(hObject, eventdata, handles,param.FileName,0)
    end
end  

%fields input initialisation
if isfield(param,'list_fields')&& isfield(param,'index_fields') &&~isempty(param.list_fields) &&~isempty(param.index_fields)
    set(handles.FieldMenu,'String',param.list_fields);% list menu fields
    set(handles.FieldMenu,'Value',param.index_fields);% selected string index
    FieldCell{1}=param.list_fields{param.index_fields};
end
if isfield(param,'civ1')&& islogical(param.civ1) && isfield(param,'civ2')&& islogical(param.civ2)&...
        isfield(param,'interp1')&& islogical(param.interp1)&&isfield(param,'interp2')&& islogical(param.interp2)&...
        isfield(param,'filter1')&& islogical(param.filter1)&&isfield(param,'filter2')&& islogical(param.filter2)
    set(handles.civ1,'Value',param.civ1);
    set(handles.civ2,'Value',param.civ1);
    set(handles.interp1,'Value',param.interp1);
    set(handles.interp2,'Value',param.interp2);
    set(handles.filter1,'Value',param.filter1);
    set(handles.filter2,'Value',param.filter2);
end
set(hObject,'WindowButtonUpFcn',{@mouse_up_gui,handles}) 
NomType_Callback(hObject, eventdata, handles)

%loads the information stored in prefdir to initiate  the list of ACTION functions
fct_menu={'check_files';'aver_stat';'time_series';'merge_proj';'clean_civ_cmx'};
transform_menu={'';'phys';'px';'phys_polar'};
nb_builtin=numel(fct_menu); %number of functions
nb_transform=numel(transform_menu);
[path_series,name,ext]=fileparts(which('series'));
path_series=fullfile(path_series,'series');%path of the function 'series'
path_transform=fullfile(path_series,'transform_field');%path of the field transform functions 
for ilist=1:length(fct_menu)
    fct_path{ilist,1}=path_series;%paths of the fuctions buil-in in 'series.m'
end

%TRANSFORM menu: loads the information stored in prefdir to initiate  the list of field transform functions
menu_str={'';'phys';'px';'phys_polar'};
nb_builtin=numel(menu_str); %number of functions
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
dir_perso=prefdir; 
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    h=load (profil_perso);
    if isfield(h,'series_fct') && iscell(h.series_fct)
         for ilist=1:length(h.series_fct)
             [path,file]=fileparts(h.series_fct{ilist});
             fct_path=[fct_path; {path}];%concatene the list of paths
             transform_menu=[transform_menu; {file}];
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

% display the GUI for the default action 'check_files'
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

RootPathCell=get(handles.RootPath,'String');
SubDirCell=get(handles.SubDir,'String');  
RootFileCell=get(handles.RootFile,'String');
oldfile=''; %default
if isempty(RootPathCell)|isequal(RootPathCell,{''})%loads the previously stored file name and set it as default in the file_input box
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
testblank=findstr(fileinput,' ');%look for blanks
if ~isempty(testblank)
    errordlg('forbidden input file name: contain blanks')
    return
end
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
[path,name,ext]=fileparts(fileinput);
SeriesData=[];%dfault
if isequal(ext,'.xml')
    errordlg('input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
elseif isequal(ext,'.xls')
    errordlg('input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
else
    update_file(hObject, eventdata, handles,fileinput,0)
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
        txt=ver;
        Release=txt(1).Release;
        relnumb=str2num(Release(3:4));
        if relnumb >= 14
            save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-V6'); %store the file names for future opening of uvmat
        else
            save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5'); %store the file names for future opening of uvmat
        end
    end
end
% set(hseries,'UserData',SeriesData);
% RootFile_Callback(hObject, eventdata, handles); 
% FileExt_Callback(hObject, eventdata, handles); 
% NomType_Callback(hObject, eventdata, handles)
% mode_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function MenuFile_1_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_1,'Label');
update_file(hObject, eventdata, handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_2_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_2,'Label');
update_file(hObject, eventdata, handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_3_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_3,'Label');
update_file(hObject, eventdata, handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_4_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_4,'Label');
update_file(hObject, eventdata, handles,fileinput,0)

% --------------------------------------------------------------------
function MenuFile_5_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_5,'Label');
update_file(hObject, eventdata, handles,fileinput,0)

% --------------------------------------------------------------------
function MenuBrowse_insert_Callback(hObject, eventdata, handles)

RootPathCell=get(handles.RootPath,'String'); 
RootFileCell=get(handles.RootFile,'String');
oldfile=''; %default
if isempty(RootPathCell)|isequal(RootPathCell,{''})%loads the previously stored file name and set it as default in the file_input box
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
testblank=findstr(fileinput,' ');%look for blanks
if ~isempty(testblank)
    errordlg('forbidden input file name: contain blanks')
    return
end
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
[path,name,ext]=fileparts(fileinput);
SeriesData=[];%dfault
if isequal(ext,'.xml')
    errordlg('input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
elseif isequal(ext,'.xls')
    errordlg('input file type not implemented')%A Faire: ouvrir le fichier pour naviguer
else
    update_file(hObject, eventdata, handles,fileinput,1)
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
        txt=ver;
        Release=txt(1).Release;
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
update_file(hObject, eventdata, handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_2_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_insert_2,'Label');
update_file(hObject, eventdata, handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_3_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_insert_3,'Label');
update_file(hObject, eventdata, handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_4_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_insert_4,'Label');
update_file(hObject, eventdata, handles,fileinput,1)

% --------------------------------------------------------------------
function MenuFile_insert_5_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_insert_5,'Label');
update_file(hObject, eventdata, handles,fileinput,1)

%------------------------------------------------------------------------
% ---  refresh the GUI data after introduction of a new file series
function update_file(hObject, eventdata, handles,fileinput,addtest)
%------------------------------------------------------------------------  
if ~exist(fileinput,'file')
    msgbox_uvmat('ERROR',['input file ' fileinput  ' does not exist'])
    return
end

% refresh input root name, indices, file extension and nomenclature
[RootPath,RootFile,field_count,str2,str_a,str_b,FileExt,NomType,SubDir]=name2display(fileinput);

%check for movie image files
if ~isempty(FileExt)
    if ~isempty(imformats(FileExt(2:end)))
        imainfo=imfinfo(fileinput);
        if length(imainfo) >1 %case of image with multiple frames
            NomType='*';
            [RootPath,RootFile]=fileparts(fileinput);
        end
    end
end
NcType='none';%default
if isequal(FileExt,'.nc')
   Data=nc2struct(fileinput,[]);
   if isfield(Data,'absolut_time_T0')
       NcType='civx'; % test for civx velocity fields
   end
end

set(handles.RootPath,'Value',1)
set(handles.SubDir,'Value',1)
set(handles.RootFile,'Value',1)
set(handles.NomType,'Value',1)
set(handles.FileExt,'Value',1)
set(handles.nb_field,'Value',1)
set(handles.nb_field2,'Value',1)
if addtest
    SeriesData=get(handles.figure1,'UserData');
    SeriesData.displ_num=[0 0 0 0;SeriesData.displ_num];
    SeriesData.CurrentInputFile_1=SeriesData.CurrentInputFile;
    RootPathCell=[{RootPath}; get(handles.RootPath,'String')] ; 
    SubDirCell=[{SubDir}; get(handles.SubDir,'String')];
    RootFileCell=[{RootFile}; get(handles.RootFile,'String')]; 
    NomTypeCell=[{NomType}; SeriesData.NomType];
    FileExtCell=[{FileExt}; get(handles.FileExt,'String')];
    NcTypeCell=[{NcType};SeriesData.NcType];
    set(handles.NomType,'String',[{};get(handles.NomType,'String')])
else
    SeriesData=[];%re-initialisation 
    SeriesData.displ_num=[0 0 0 0];
    RootPathCell={RootPath};
    SubDirCell={SubDir};
    RootFileCell={RootFile};   
    NomTypeCell={NomType};
    FileExtCell={FileExt};   
    NcTypeCell={NcType};
end

SeriesData.NomType=NomTypeCell;
SeriesData.NcType=NcTypeCell;
SeriesData.CurrentInputFile=fileinput;
set(handles.RootPath,'String',RootPathCell);
set(handles.SubDir,'String',SubDirCell);
set(handles.RootFile,'String',RootFileCell);
set(handles.NomType,'String',NomTypeCell);
set(handles.FileExt,'String',FileExtCell);  

%determine field indices
ref_i=1; %default ref_i is a reference frame index used to find existing pairs from PIV
if ~isempty(str2num(field_count))
    ref_i=str2num(field_count);
    if ~isempty(str2num(str2))
        ref_i=floor((ref_i+str2num(str2))/2);% reference image number corresponding to the file
        SeriesData.browse_Di=str2num(str2)-str2num(field_count);
    end
end
set(handles.ref_i,'String',num2str(ref_i));
set(handles.first_i,'String',num2str(ref_i));
set(handles.last_i,'String',num2str(ref_i));
ref_j=1; %default  ref_j is a reference frame index used to find existing pairs from PIV
if ~isempty(str2num(str_a))
    ref_j=str2num(str_a);
    if ~isempty(str2num(str_b))
        ref_j=floor((str2num(str_a)+str2num(str_b))/2);
        SeriesData.browse_Dj=str2num(str_b)-str2num(str_a); 
    end          
end
set(handles.ref_j,'String',num2str(ref_j)); 
set(handles.first_j,'String',num2str(ref_j))
set(handles.last_j,'String',num2str(ref_j)); 

%enable other menus and uicontrols
set(handles.MenuOpen_insert,'Enable','on')
set(handles.MenuFile_insert_1,'Enable','on')
set(handles.MenuFile_insert_2,'Enable','on')
set(handles.MenuFile_insert_3,'Enable','on')
set(handles.MenuFile_insert_4,'Enable','on')
set(handles.MenuFile_insert_5,'Enable','on')
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])% set RUN button to red 
set(handles.RootPath,'BackgroundColor',[1 1 0]) % set RootPath edit box  to yellow
drawnow

TimeUnit=''; %default
time=[];%default
GeometryCalib=[];%default
nb_field=[];%default
nb_field2=[];%default
SeriesData.PathCampaign=get(handles.PathCampaign,'String');

% read timing and total frame number from the current file (movie files) !! may be overrid by xml file
FileBase=fullfile(RootPath,RootFile);

testima=0; %test for image input
if isequal(lower(FileExt),'.avi') %.avi file
    testima=1;
    info=aviinfo([FileBase FileExt]);
    time=[0:1/info.FramesPerSecond:(info.NumFrames-1)/info.FramesPerSecond]';
    nb_field=info.NumFrames;
    nb_field2=1;
elseif ~isempty(imformats(FileExt(2:end))) 
    testima=1;
    if isequal(NomType,'*')% multi-frame image
        imainfo=imfinfo([FileBase FileExt]);     
        if length(imainfo) >1 %case of image with multiple frames
            nb_field=length(imainfo);
            nb_field2=1;
        end
    end
elseif isequal(FileExt,'.vol')
     testima=1;
end

% enable field and veltype menus
testfield=isequal(get(handles.FieldMenu,'enable'),'on');
testfield_1=isequal(get(handles.FieldMenu_1,'enable'),'on');
testveltype=isequal(get(handles.VelTypeMenu,'enable'),'on');
testveltype_1=isequal(get(handles.VelTypeMenu_1,'enable'),'on');
testtransform=isequal(get(handles.transform_fct,'Enable'),'on');
testnc=0;
testnc_1=0;
testcivx=0;
testcivx_1=0;
if length(FileExtCell)==1 || length(FileExtCell)>2
    for iview=1:length(FileExtCell)
        if isequal(FileExtCell{iview},'.nc')
            testnc=1;
        end
        if isequal(NcTypeCell{iview},'civx')
            testcivx=1;
        end
    end
elseif length(FileExtCell)==2
    testnc=isequal(FileExtCell{1},'.nc');
    testnc_1=isequal(FileExtCell{2},'.nc');
    testcivx=isequal(NcTypeCell{1},'civx');
    testcivx_1=isequal(NcTypeCell{2},'civx');
end
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
     view_TRANSFORM(handles,'on')
else
    view_TRANSFORM(handles,'off')
end
if ~isequal(FileExt,'.nc') && ~isequal(FileExt,'.cdf') && ~testima
    msgbox_uvmat('ERROR',['invalid input file extension ' FileExt])
    return
end  

%%%%%%%%   read image documentation file  if found%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %look for the file existence
ext_imadoc='';
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
        if isfield(XmlData,'Heading') && isfield(XmlData.Heading,'ImageName')
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
if addtest
    SeriesData.Time=[{time} SeriesData.Time];
else
   SeriesData.Time={time};
end


% if ~isempty(time)
%     siztime=size(time);
%     nb_field=siztime(1);
%     nb_field2=siztime(2);
% end   
set(handles.TimeUnit,'String',TimeUnit)
%look for max indices
if ~strcmp(NomType,'*')
    [num_i1,num_i2,num_j1,num_j2]=find_indexseries(fileinput);
    nb_field=max(floor((max(num_i1)+max(num_i2))/2));
    nb_field2=max(floor((max(num_j1)+max(num_j2))/2));
end
if isempty(nb_field)||isnan(nb_field)
    nb_field_str='?';
    nb_field_str2='?';
else
    nb_field_str=num2str(nb_field);
    nb_field_str2=num2str(nb_field2);
end
if addtest
    nb_field_cell=[{nb_field_str} ;get(handles.nb_field,'String')];
    nb_field2_cell=[{nb_field_str2} ;get(handles.nb_field2,'String')];
else
    nb_field_cell={nb_field_str};
    nb_field2_cell={nb_field_str2};
end
set(handles.nb_field,'String',nb_field_cell);
set(handles.nb_field2,'String',nb_field2_cell);
set(handles.figure1,'UserData',SeriesData);

%number of slices
if isfield(XmlData,'GeometryCalib') && isfield(XmlData.GeometryCalib,'SliceCoord')
       siz=size(XmlData.GeometryCalib.SliceCoord);
       if siz(1)>1
           NbSlice=siz(1);
       else
           NbSlice=1;
       end
       set(handles.NbSlice,'String',num2str(NbSlice))
end

% set menus of index pairs
NomType_Callback(hObject, eventdata, handles)

%store the root name for future opening of uvmat
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    save (profil_perso,'RootPath','SubDir','RootFile','NomType', '-append'); %store the root name for future opening of uvmat
else
    txt=ver;
    Release=txt(1).Release;
    relnumb=str2num(Release(3:4));
    if relnumb >= 14
        save (profil_perso,'RootPath','SubDir','RootFile','NomType','-V6') %store the root name for future opening of uvmat
    else
        save(profil_perso,'RootPath','SubDir','RootFile','NomType')
    end         
end
set(handles.RootPath,'BackgroundColor',[1 1 1])
set(handles.PathCampaign,'String',SeriesData.PathCampaign)
last_j_Callback(hObject, eventdata, handles)
last_i_Callback(hObject, eventdata, handles)

%------------------------------------------------------------
function RootPath_Callback(hObject, eventdata, handles)
Val=get(handles.RootPath,'Value');
synchronise_view(handles,Val)
NomType_Callback(hObject, eventdata, handles)
%------------------------------------------------------------

function synchronise_view(handles,Val)
set(handles.RootPath,'Value',Val)
set(handles.SubDir,'Value',Val)
set(handles.RootFile,'Value',Val)
set(handles.NomType,'Value',Val)
set(handles.FileExt,'Value',Val)
set(handles.nb_field,'Value',Val)
set(handles.nb_field2,'Value',Val)
set(handles.time_first,'Value',Val)
set(handles.time_last,'Value',Val)


%---------------------------------------------------------
% Executes on carriage return on the subdir civ1 edit window
%--------------------------------------------------------
function SubDir_Callback(hObject, eventdata, handles)

Val=get(handles.SubDir,'Value');
synchronise_view(handles,Val)
NomType_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------
%function activated when a new filebase (image series) is introduced
%------------------------------------------------------------
function RootFile_Callback(hObject, eventdata, handles)
Val=get(handles.RootFile,'Value');
synchronise_view(handles,Val)
NomType_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------
%function activated when a new filebase (image series) is introduced
%------------------------------------------------------------
function FileExt_Callback(hObject, eventdata, handles)
Val=get(handles.FileExt,'Value');
synchronise_view(handles,Val)

%--------------------------------------------------------------
%function activated when a new filebase (image series) is introduced
%------------------------------------------------------------
function nb_field_Callback(hObject, eventdata, handles)
Val=get(handles.nb_field,'Value');
synchronise_view(handles,Val)

%--------------------------------------------------------------
%function activated when a new filebase (image series) is introduced
%------------------------------------------------------------
function nb_field2_Callback(hObject, eventdata, handles)
Val=get(handles.nb_field2,'Value');
synchronise_view(handles,Val)

%--------------------------------------------------------------
%function activated when a new filebase (image series) is introduced
%------------------------------------------------------------
function time_first_Callback(hObject, eventdata, handles)
Val=get(handles.time_first,'Value');
synchronise_view(handles,Val)

%--------------------------------------------------------------
%function activated when a new filebase (image series) is introduced
%------------------------------------------------------------
function time_last_Callback(hObject, eventdata, handles)
Val=get(handles.time_last,'Value');
synchronise_view(handles,Val)

%--------------------------------------------------------------
%function activated by NomType
%------------------------------------------------------------
NomType_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function NomType_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
hseries=get(handles.ProjObject,'Parent');
SeriesData=get(hseries,'UserData');
if isfield(SeriesData,'NomType')
    NomTypeCell=SeriesData.NomType;
else
    NomTypeCell={};
end
nbfield2_cell=get(handles.nb_field2,'String');
val=get(handles.nb_field2,'Value');
if iscell(nbfield2_cell)
    nbfield2=str2num(nbfield2_cell{val});
else
    nbfield2=str2num(nbfield2_cell);
end
nbfield_cell=get(handles.nb_field,'String');
if iscell(nbfield_cell)
    nbfield=str2num(nbfield_cell{val});
else
   nbfield=str2num(nbfield_cell);
end

set(handles.mode,'Visible','off') % do not show index pairs by default
set(handles.list_pair_civ,'Visible','off')
set(handles.ref_i,'Visible','off')
set(handles.ref_i_text,'Visible','off')
testpair=0;
state_j='off';
%set the menus of image pairs and default selection for series
%list pairs if relevant
Val=get(handles.NomType,'Value');
synchronise_view(handles,Val)
if ~isempty(NomTypeCell)
    NomType=NomTypeCell{Val};
    switch NomType  
            case {'_i1-i2_j', '_i1-i2'}
                set(handles.mode,'String',{'series(Di)'})
                set(handles.mode,'Value',1);
                set(handles.mode,'Visible','on')
                testpair=1;
            case {'#_ab'} 
                set(handles.mode,'String',{'bursts'})
                set(handles.mode,'Value',1);
                testpair=1;
            case '_i_j1-j2'
                set(handles.mode,'String',{'bursts';'series(Dj)'})%multiple choice
                if ~isempty(nbfield) && ~isempty(nbfield2) && ((nbfield2>10) || (nbfield==1))
                    set(handles.mode,'Value',2);
                else
                    set(handles.mode,'Value',1);% advice 'bursts' for small bursts
                end
                set(handles.mode,'Visible','on')
                testpair=1;
    end
    switch NomType   
            case {'_i_j','_i_j1-j2','_i1-i2_j','#_ab'},% two navigation indices
                state_j='on';
    end
end 
if testpair
    mode_Callback(hObject, eventdata, handles)  
else
    set(handles.NomType,'String',NomTypeCell)
    set(handles.first_j,'Visible',state_j)
    set(handles.incr_j,'Visible',state_j)
    set(handles.last_j,'Visible',state_j)
    set(handles.nb_field2,'Visible',state_j)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%????????????
% --- Executes on button press in mode.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mode_Callback(hObject, eventdata, handles)
%hseries=get(handles.mode,'parent');
hseries=handles.figure1;
SeriesData=get(hseries,'UserData');
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
NomType=[];
test_find_pair=0;
if isfield(SeriesData,'NomType')
    NomTypeCell=SeriesData.NomType;
    Val=get(handles.NomType,'Value');
    NomType=NomTypeCell{Val};
    test_find_pair=isequal(NomType,'_i_j1-j2')|| isequal(NomType,'_i1-i2_j')|| isequal(NomType,'_i1-i2')|| isequal(NomType,'#_ab');
end
time=[];
if isfield(SeriesData,'Time')
time=SeriesData.Time{1}; %get the set of times
end
siztime=size(time);
nbfield=siztime(1);
nbfield2=siztime(2);
indchosen=1;  %%first pair selected by default
if isequal(mode,'bursts')
    enable_i(handles,'On')
    enable_j(handles,'Off') %do not display j index scanning in burst mode (j is fixed by the burst choice)  
elseif  isequal(NomType,'_i_j1-j2')|| isequal(NomType,'_i1-i2_j')
    enable_i(handles,'On')
    enable_j(handles,'On') % allow both i and j index scanning
else
    enable_i(handles,'On')
    enable_j(handles,'Off') 
end    
set(handles.list_pair_civ,'Value',indchosen);%set the default choice of image pairs for civ1
set(hseries,'UserData',SeriesData)

%list pairs if relevant
if test_find_pair
     find_netcpair_civ(hObject, eventdata, handles,Val)
end

%-------------------------------------
function enable_i(handles,state)
set(handles.i_txt,'Visible',state)
set(handles.first_i,'Visible',state)
set(handles.last_i,'Visible',state)
set(handles.incr_i,'Visible',state)
set(handles.nb_field,'Visible',state)
set(handles.ref_i,'Visible',state)
set(handles.ref_i_text,'Visible',state)

%-----------------------------------
function enable_j(handles,state)
set(handles.j_txt,'Visible',state)
set(handles.first_j,'Visible',state)
set(handles.last_j,'Visible',state)
set(handles.incr_j,'Visible',state)
set(handles.nb_field2,'Visible',state)
set(handles.ref_j,'Visible',state)
set(handles.ref_j_text,'Visible',state)

%-----------------------------------
function view_FieldMenu(handles,state)
set(handles.FieldMenu,'Visible',state)
set(handles.Field_text,'Visible',state)
set(handles.Field_frame,'Visible',state)

%-----------------------------------
function view_FieldMenu_1(handles,state)
set(handles.FieldMenu_1,'Visible',state)
set(handles.Field_text_1,'Visible',state)

%-----------------------------------
function view_TRANSFORM(handles,state)
set(handles.TRANSFORM_frame,'Visible',state)
set(handles.transform_fct,'Visible',state);
set(handles.TRANSFORM_title,'Visible',state)

%--------------------------------------------------------------
% determine the menu for civ1 pairs depending on existing netcdf files 
% with the reference indices ref_i and ref_j
%----------------------------------------------------------------
function find_netcpair_civ(hObject, eventdata, handles,Val)
%hseries=get(handles.list_pair_civ,'parent');
SeriesData=get(handles.figure1,'UserData'); 
% NomTypeCell=get(handles.NomType,'String');
NomTypeCell=SeriesData.NomType;
NomType=NomTypeCell{Val};
  set(handles.list_pair_civ,'Visible','on')
%nomenclature types
RootPathCell=get(handles.RootPath,'String');
filepath=RootPathCell{Val};
RootFileCell=get(handles.RootFile,'String');
filename=RootFileCell{Val};
filebase=fullfile(filepath,filename);
SubDirCell=get(handles.SubDir,'String');
subdir=SubDirCell{Val};
if ~exist(fullfile(filepath,subdir),'dir') 
         msgbox_uvmat('ERROR',['no civ file available: subdirectory ' subdir ' does not exist'])
         set(handles.list_pair_civ,'String',{''});
         return
end
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};

%reads image numbers from the interface
ref_i=str2num(get(handles.ref_i,'String'));
ref_j=str2num(get(handles.ref_j,'String'));
% time=[];
% ref_time=[];
 ref_time=0;
if isfield(SeriesData,'Time')&~isempty(SeriesData.Time{Val})&~isequal(SeriesData.Time{Val},0)
    time=SeriesData.Time{Val}; %get the set of times
    siztime=size(time);
    nbfield=siztime(1);
    nbfield2=siztime(2);
%     test_imadoc=1;
else
%     test_imadoc=0;%no image documentation file
    nbfield=50;
    nbfield2=50;%default max number of pairs
end
%look for existing processed pairs involving the field at the middle of the series if civ1 will not 
% be performed, while the result is needed for next steps.
displ_pair={''};
displ_num=[];
ind_exist=0;
TimeUnit=get(handles.TimeUnit,'String');
if length(TimeUnit)>=1
    dtunit=['m' TimeUnit];
else
    dtunit='e-03';
end
if isequal(mode,'series(Di)') 
     for index=1:min(nbfield-1,50)
         filename=name_generator(filebase,ref_i-floor(index/2),ref_j,'.nc',NomType,1,ref_i+ceil(index/2),ref_j,subdir);
         select=(exist(filename,'file')==2);
         if select==1
               ind_exist=ind_exist+1;
                displ_num(1,ind_exist)=0;
                displ_num(2,ind_exist)=0;
                displ_num(3,ind_exist)=-floor(index/2);
                displ_num(4,ind_exist)=ceil(index/2);
                %[cte_detect,vdt,cte_read]=read_netcdf(filename,{'dt','dt2','absolut_time_T0','absolute_time_TO_2'});
                [Cte,var_detect,ichoice]=nc2struct(filename,{});
                if isfield(Cte,'dt2')
                    dt=Cte.dt2;
                elseif isfield(Cte,'dt')
                    dt=Cte.dt;
                end
                if isfield(Cte,'absolut_time_TO_2')
                    ref_time(ind_exist)=Cte.absolut_time_TO_2;%civ2 data used in priority
                elseif isfield(Cte,'absolut_time_TO')
                    ref_time(ind_exist)=Cte.absolut_time_TO;%civ2 data used in priorit
                elseif isfield(Cte,'Time')
                    ref_time(ind_exist)=Cte.Time;
                end
                displ_pair{ind_exist}=['Di= ' num2str(-floor(index/2)) '|' num2str(ceil(index/2)) ' :dt= ' num2str(dt*1000) dtunit];
         end
     end
     set(handles.list_pair_civ,'String',[displ_pair';{'Di=*|*'}]);   
elseif isequal(mode,'series(Dj)')% series on the j index
       for index=1:min(nbfield2-1,50)
           filename=name_generator(filebase,ref_i,ref_j-floor(index/2),'.nc',NomType,1,ref_i,ref_j+ceil(index/2),subdir);
           select=(exist(filename,'file')==2);
           if select==1
               ind_exist=ind_exist+1;
                displ_num(1,ind_exist)=-floor(index/2);
                displ_num(2,ind_exist)=ceil(index/2);
                displ_num(3,ind_exist)=0;
                displ_num(4,ind_exist)=0;
                %[cte_detect,vdt,cte_read]=read_netcdf(filename,{'dt','dt2','absolut_time_T0','absolute_time_TO_2'});
                [Cte,var_detect,ichoice]=nc2struct(filename,{});
                if isfield(Cte,'dt2')
                    dt=Cte.dt2;
                elseif isfield(Cte,'dt')
                    dt=Cte.dt;
                end
                if isfield(Cte,'absolut_time_TO_2')
                    ref_time(ind_exist)=Cte.absolut_time_TO_2;%civ2 data used in priority
                elseif isfield(Cte,'absolut_time_TO')
                    ref_time(ind_exist)=Cte.absolut_time_TO;%civ2 data used in priorit
                elseif isfield(Cte,'Time')
                    ref_time(ind_exist)=Cte.Time;
                end
%                 if cte_detect(2)==1;
%                     dt=cte_read(2);
%                     ref_time(ind_exist)=cte_read(4);%civ2 data used in priority
%                 else
%                     dt=cte_read(1);
%                     ref_time(ind_exist)=cte_read(3);
%                 end 
                displ_pair{ind_exist}=['Dj= ' num2str(-floor(index/2)) '|' num2str(ceil(index/2)) ' :dt= ' num2str(dt*1000) dtunit];
           end
       end
       set(handles.list_pair_civ,'String',[displ_pair';{'Dj=*|*'}]);
elseif isequal(mode,'bursts') %case of bursts
    for numod_a=1:nbfield2-1 %nbfield2 always >=2 for 'bursts' mode
        for numod_b=(numod_a+1):nbfield2
            [filename]=name_generator(filebase,ref_i,numod_a,'.nc',NomType,1,ref_i,numod_b,subdir);
            select=(exist(filename,'file')==2);
            if select==1
                ind_exist=ind_exist+1;
                numlist_a(ind_exist)=numod_a;
                numlist_b(ind_exist)=numod_b;
                Attr=nc2struct(filename,[]);
                isfield(Attr,'absolut_time_T0_2')
                if isfield(Attr,'dt2')
                   dt(ind_exist)=Attr.dt2;
                   ref_time(ind_exist)=Attr.absolut_time_T0_2;
                elseif isfield(Attr,'dt')& isfield(Attr,'absolut_time_T0')
                   dt(ind_exist)=Attr.dt;
                   ref_time(ind_exist)=Attr.absolut_time_T0;
                else
                   dt(ind_exist)=NaN;%no information on dt
                end
                %determine nom_type_ima for pair display (used in num2stra.m)
                switch NomType
                    case {'#ab'}
                        nom_type_ima='#a';
                    case {'#AB'}
                        nom_type_ima='#A';
                    otherwise
                         nom_type_ima='_i_j';
                end
               displ_pair{ind_exist}=['j= ' num2stra(numod_a,nom_type_ima,2) '-' num2stra(numod_b,nom_type_ima,2) ...
                        ' :dt= ' num2str(dt(ind_exist)*1000)];
            end
         end
         set(handles.list_pair_civ,'String',[displ_pair';{'j=*-*'}]);
     end
     if exist('dt','var') & ~isempty(dt)
         [dtsort,indsort]=sort(dt);
         displ_num(1,:)=numlist_a(indsort);
         displ_num(2,:)=numlist_b(indsort);
         displ_num(3,:)=0;
         displ_num(4,:)=0;
         displ_pair=displ_pair(indsort);
         ref_time=ref_time(indsort);
     end
end
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

val=get(handles.list_pair_civ,'Value');
if val > length(displ_pair)
    set(handles.list_pair_civ,'Value',1);% first pair proposed by default in the menu
    val=1;
end
iview=get(handles.NomType,'Value');
SeriesData.displ_num(iview,:)=(displ_num(:,val))';
SeriesData.ref_time=ref_time;
set(handles.figure1,'UserData',SeriesData)
list_pair_civ_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------
% --- Executes on selection in list_pair_civ.
function list_pair_civ_Callback(hObject, eventdata, handles)
%------------------------------------------------------------

%update first_i and last_i according to the chosen image pairs 
testupdate=0;
Val=get(handles.RootPath,'Value');
IndexCell=get(handles.NomType,'String');
%hseries=get(handles.list_pair_civ,'parent');
SeriesData=get(handles.figure1,'UserData');
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
       case {'_i1-i2_j'}
           if isequal(num1_str(1),'0')
               IndexCell{Val}=['_(i-(i+' num2_str ')_j'];
           else
               IndexCell{Val}=['_(i' num1_str ')-(i+' num2_str ')_j'];
           end
           displ_num(3)=num1;
           displ_num(4)=num2;
       case {'_i1-i2'}
           if isequal(num1_str(1),'0')
               IndexCell{Val}=['_(i' num1_str ')-(i+' num2_str ')'];
           else
               IndexCell{Val}=['_(i' num1_str ')-(i+' num2_str ')'];
           end
           displ_num(3)=num1;
           displ_num(4)=num2;
       case '_i_j1-j2'
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
set(handles.figure1,'UserData',SeriesData)
% set(handles.NomType,'Value',Val)

if ~isequal(str_pair,'Dj=*|*')&~isequal(str_pair,'Di=*|*')
	mode_list=get(handles.mode,'String');
    mode_value=get(handles.mode,'Value');
    mode=mode_list{mode_value};
	if isequal(mode,'series(Di)')
        first_i=str2num(get(handles.first_i,'String'));
        last_i=str2num(get(handles.last_i,'String'));
        incr_i=str2num(get(handles.incr_i,'String'));
        num1=first_i:incr_i:last_i;
        lastfieldCell=get(handles.nb_field,'String');
        lastfield=str2num(lastfieldCell{1});
        if ~isempty(lastfield)
            ind=find((num1-floor(index_pair/2)*ones(size(num1))>0)& (num1+ceil(index_pair/2)*ones(size(num1))<=lastfield));
            num1=num1(ind);       
        end
        if ~isempty(num1)
            set(handles.first_i,'String',num2str(num1(1)));
            set(handles.last_i,'String',num2str(num1(end)));
        end
        testupdate=1;
	elseif isequal(mode,'series(Dj)')
        first_j=str2num(get(handles.first_j,'String'));
        last_j=str2num(get(handles.last_j,'String'));
        incr_j=str2num(get(handles.incr_j,'String'));
        num_j=first_j:incr_j:last_j;
        lastfieldCell=get(handles.nb_field2,'String');
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
            displ_time(handles,SeriesData.Time{1});
        end
	end
end

%------------------------------------------------------------------------
% --- Executes on button press in RUN.
function RUN_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%read root name and field type
set(handles.RUN,'BusyAction','queue');
%hseries=get(handles.RUN,'parent');
set(0,'CurrentFigure',handles.figure1)
if isequal(get(handles.GetObject,'Visible'),'on') && isequal(get(handles.GetObject,'Value'),1) 
    Series.GetObject=1;
    GetObject_Callback(hObject, eventdata, handles)
else
    Series.GetObject=0;
end
SeriesData=get(handles.figure1,'UserData');

%reinitiate waitbar position
Series.WaitbarPos=get(handles.waitbar_frame,'Position');%TO SUPPRESS
waitbarpos=Series.WaitbarPos;
waitbarpos(4)=0.005;%reinitialize waitbar to zero height
waitbarpos(2)=Series.WaitbarPos(2)+Series.WaitbarPos(4)-0.005;
set(handles.waitbar,'Position',waitbarpos)

% read input file parameters and set menus
Series.PathProject=get(handles.PathCampaign,'String');
RootPath=get(handles.RootPath,'String');% path of the root name of the first field series
RootFile=get(handles.RootFile,'String');% root name of the first field series 
SubDir=get(handles.SubDir,'String');% subdirectory for netcdf files
FileExt=get(handles.FileExt,'String');%file extension
if isempty(SeriesData)
    msgbox_uvmat('ERROR','no input file series')
    return
end
NomType=SeriesData.NomType;
if length(RootPath)==1 %string character input for user fct
    Series.RootPath=RootPath{1};
    Series.RootFile=RootFile{1};
    Series.SubDir=SubDir{1};
    Series.FileExt=FileExt{1};
    Series.NomType=NomType{1};
else %cell input for user fct
    Series.RootPath=RootPath;
    Series.RootFile=RootFile;
    Series.SubDir=SubDir;
    Series.FileExt=FileExt;
    Series.NomType=NomType;
end
if isequal(get(handles.FieldMenu,'Visible'),'on')
    FieldMenu=get(handles.FieldMenu,'String');
    FieldValue=get(handles.FieldMenu,'Value');
    Series.Field=FieldMenu(FieldValue);
end
menu_coord_state=get(handles.transform_fct,'Visible');
Series.CoordType='';%default
if isequal(menu_coord_state,'on')
%     menu_coord=get(handles.transform_fct,'String');
    menu_index=get(handles.transform_fct,'Value');
    transform_list=get(handles.transform_fct,'UserData');
    Series.transform_fct=transform_list{menu_index};% transform function handles
end
Series.hseries=handles.figure1; % handles to the series GUI

%read the set of field numbers
first_i=str2num(get(handles.first_i,'String'));
last_i=str2num(get(handles.last_i,'String'));
incr_i=str2num(get(handles.incr_i,'String'));
first_j=str2num(get(handles.first_j,'String'));
last_j=str2num(get(handles.last_j,'String'));
incr_j=str2num(get(handles.incr_j,'String'));
if ~isequal(get(handles.first_i,'Visible'),'on')
   first_i=1;
   last_i=1;
   incr_i=1;
end
if ~isequal(get(handles.first_j,'Visible'),'on')
    first_j=1;
    last_j=1;
    incr_j=1;
end
Series.NbSlice=str2num(get(handles.NbSlice,'String'));
if isequal(first_i,[])|isequal(first_j,[]), msgbox_uvmat('ERROR','first field number not defined'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
if isequal(last_i,[])| isequal(last_j,[]),msgbox_uvmat('ERROR','last field number not defined'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
if isequal(incr_i,[])| isequal(incr_j,[]),msgbox_uvmat('ERROR','increment in field number not defined'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
if last_i < first_i | last_j < first_j , msgbox_uvmat('ERROR','last field number must be larger than the first one'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
num_i=[first_i:incr_i:last_i];
num_j=[first_j:incr_j:last_j];
nbfield_cell=get(handles.nb_field,'String');
nbfield=[]; %default
for iview=1:length(nbfield_cell)
    nb=str2num(nbfield_cell{iview});
    if ~isempty(nb)
        nbfield=[nbfield nb];
    end
end
nbfield=min(nbfield);
nbfield2_cell=get(handles.nb_field2,'String');
nbfield2=[]; %default
for iview=1:length(nbfield2_cell)
    nb=str2num(nbfield2_cell{iview});
    if ~isempty(nb)
        nbfield2=[nbfield2 nb];
    end
end
nbfield2=min(nbfield2);

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
for iview=1:length(RootPath)
    %case of pairs (.nc files)
    
    if isequal(NomType{iview},'_i_j1-j2')|| isequal(NomType{iview},'_i1-i2_j')|| isequal(NomType{iview},'_i1-i2')|| isequal(NomType{iview},'#_ab')
        ind_shift=SeriesData.displ_num(iview,:);
        if isequal(ind_shift,[0 0 0 0]) % undefined pairs
            if isequal(NomType{iview},'#_ab')
                mode='#_ab';
            end
            [num_i1,num_i2,num_j1,num_j2,nbmissing]=netseries_generator(fullfile(RootPath{iview},RootFile{iview}),SubDir{iview},mode,first_i,incr_i,last_i,first_j,incr_j,last_j);
        else    
            [num_i1,num_i2,num_j1,num_j2,num_i,num_j]=find_file_indices(num_i,num_j,ind_shift,NomType{iview},mode);
            if isempty(num_i)
                msgbox_uvmat('ERROR','ERROR: empty set of input files chosen')
                return
            end
            if num_i(1)>first_i
               set(handles.first_i,'String',num2str(num_i(1)))%update the display of first field
               last_i_Callback(hObject, eventdata, handles)
            end
            if num_i(end)<last_i
               set(handles.last_i,'String',num2str(num_i(end)))%update the display of last field
               last_i_Callback(hObject, eventdata, handles)
            end
            if num_j(1)>first_j
               set(handles.first_j,'String',num2str(num_j(1)))%update the display of first field
               last_j_Callback(hObject, eventdata, handles)
            end
            if num_j(end)<last_j
               set(handles.last_j,'String',num2str(num_j(end)))%update the display of last field
               last_j_Callback(hObject, eventdata, handles)
            end 
        end
    else%case of images
        [num_i1,num_j1]=meshgrid(num_i,num_j);
        num_i2=num_i1;
        num_j2=num_j1;
    end
    if length(RootPath)>1
        num_i1_cell{iview}=num_i1;
        num_i2_cell{iview}=num_i2;
        num_j1_cell{iview}=num_j1;
        num_j2_cell{iview}=num_j2;
    end
end

% defining the ACTION function handle
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

% RUN ACTION
Series.Action=action;%name of the processing programme
set(handles.RUN,'BackgroundColor',[0.831 0.816 0.784])

if length(RootPath)>1
    h_fun(num_i1_cell,num_i2_cell,num_j1_cell,num_j2_cell,Series);
else
    h_fun(num_i1,num_i2,num_j1,num_j2,Series);
end
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
function first_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
last_i_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function last_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%     hseries=get(handles.last_i,'parent');
% first_i=str2num(get(handles.first_i,'String'));
% last_i=str2num(get(handles.last_i,'String'));
% ref_i=ceil((first_i+last_i)/2);
% set(handles.ref_i,'String', num2str(ref_i))
% ref_i_Callback(hObject, eventdata, handles)
SeriesData=get(handles.figure1,'UserData');
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
displ_time(handles,SeriesData.Time{1});

%------------------------------------------------------------------------
function first_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
 last_j_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function last_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
first_j=str2num(get(handles.first_j,'String'));
last_j=str2num(get(handles.last_j,'String'));
ref_j=ceil((first_j+last_j)/2);
set(handles.ref_j,'String', num2str(ref_j))
ref_j_Callback(hObject, eventdata, handles)
SeriesData=get(handles.figure1,'UserData');
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
displ_time(handles,SeriesData.Time{1});


%------------------------------------------------------------------------
function ref_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
%hseries=get(handles.ref_i,'parent');
SeriesData=get(handles.figure1,'UserData');
%NomTypeCell=get(handles.NomType,'String');
NomTypeCell=SeriesData.NomType;
if ~isempty(NomTypeCell)
Val=get(handles.NomType,'Value');
NomType=NomTypeCell{Val};
% for ilist=1:length(NomType)
    if isequal(NomType,'_i_j1-j2')|| isequal(NomType,'_i1-i2_j')|| isequal(NomType,'_i1-i2')
        if isequal(mode,'series(Di)') 
            find_netcpair_civ(hObject, eventdata, handles,Val);% update the menu of pairs depending on the available netcdf files
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
%hseries=get(handles.ref_i,'parent');
SeriesData=get(handles.figure1,'UserData');
NomTypeCell=SeriesData.NomType;
if ~isempty(NomTypeCell)
    Val=get(handles.NomType,'Value');
    NomType=NomTypeCell{Val};
    if isequal(NomType,'_i_j1-j2')|| isequal(NomType,'_i1-i2_j')|| isequal(NomType,'_i1-i2')
        if isequal(mode,'series(Dj)') 
            find_netcpair_civ(hObject, eventdata, handles,Val);% update the menu of pairs depending on the available netcdf files
        end
    end
end

%------------------------------------------------------------------------
% --- Executes on selection change in ACTION.
function ACTION_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
global nb_builtin
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
   if length(menu_str)>nb_builtin+5; %nb_builtin=nbre of functions always remaining in the initial menu
       nbremove=length(menu_str)-nb_builtin-5;
       menu_str(nb_builtin+1:end-5)=[];
       list_path(nb_builtin+1:end-4)=[];
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
   for ilist=nb_builtin+1:length(menu_str)-1
       series_fct{ilist-nb_builtin}=fullfile(list_path{ilist},[menu_str{ilist} '.m']);
   end
   if exist(profil_perso,'file')
        save(profil_perso,'series_fct','-append')
   else
        txt=ver;
        Release=txt(1).Release;
        relnumb=str2num(Release(3:4));
        if relnumb >= 14
            save(profil_perso,'series_fct','-V6')
        else
            save(profil_perso, 'series_fct')
        end
   end
end

%check the current path to the selected function
PathName=list_path{index_ACTION};%current recorded path
set(handles.path,'String',PathName); %show the path to the senlected function

%default setting for the visibility of the GUI elements
set(handles.RootPath,'UserData','many')
set(handles.SubDir,'Visible','on')
set(handles.RootFile,'Visible','on')
set(handles.NomType,'Visible','on')
set(handles.FileExt,'Visible','on')
set(handles.NbSlice,'Visible','off')
set(handles.NbSlice_title,'Visible','off')
set(handles.VelTypeMenu,'Visible','off');
set(handles.VelType_text,'Visible','off');
set(handles.VelTypeMenu_1,'Visible','off');
set(handles.VelType_text_1,'Visible','off');
view_FieldMenu(handles,'off')
view_FieldMenu_1(handles,'off')
view_TRANSFORM(handles,'off')
set(handles.ProjObject_frame,'Visible','off');
set(handles.GetMask,'Visible','off')
set(handles.Mask,'Visible','off')
set(handles.GetObject,'Visible','off');
set(handles.ProjObject,'Visible','off');
set(handles.OutputDir,'Visible','off');
set(handles.PARAMETERS_frame,'Visible','off');
set(handles.PARAMETERS_title,'Visible','off');
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
if ~isequal(path_series,PathName)
    rmpath(PathName)
end

varargout=h_function();
Param_list={};

%nb_series=length(RootFile);
FileExt=get(handles.FileExt,'String');
nb_series=length(FileExt);
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
         case 'RootPath'   %visible by default
            value=lower(varargout{ilist+1});
            if isequal(value,'one')||isequal(value,'two')||isequal(value,'many')
                set(handles.RootFile,'UserData',value)% for use in menu Open_insert
            end
        case 'SubDir' %visible by default
            if isequal(lower(varargout{ilist+1}),'off')
                set(handles.SubDir,'Visible','off')
            end
        case 'RootFile'   %visible by default
            value=lower(varargout{ilist+1});
            if isequal(value,'off')
                set(handles.RootFile,'Visible','off')
            elseif isequal(value,'one')||isequal(value,'two')||isequal(value,'many')
                set(handles.RootFile,'Visible','on')
                set(handles.RootFile,'UserData',value)% for use in menu Open_insert
            end
        case 'NomType'   %visible by default
            if isequal(lower(varargout{ilist+1}),'off')
                set(handles.NomType,'Visible','off')
            end 
        case 'FileExt'   %visible by default
            if isequal(lower(varargout{ilist+1}),'off')
                set(handles.FileExt,'Visible','off')
            end
        case 'NbSlice'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on')
                set(handles.NbSlice,'Visible','on')
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
                view_TRANSFORM(handles,'on')
            end
        case 'GetObject'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on')   
                set(handles.ProjObject_frame,'Visible','on')
                set(handles.GetObject,'Visible','on');
            end
        case 'Mask'   %hidden by default
            if isequal(lower(varargout{ilist+1}),'on')   
                set(handles.ProjObject_frame,'Visible','on')
                set(handles.GetMask,'Visible','on');
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
     %hseries=get(handles.FieldMenu,'parent');
     SeriesData=get(handles.figure1,'UserData');
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
     %hseries=get(handles.FieldMenu,'parent');
     SeriesData=get(handles.figure1,'UserData');
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

%-----------------------------
function mouse_up_gui(ggg,eventdata,handles)
if isequal(get(ggg,'SelectionType'),'alt') 
    display('global CurData, UserData of GUI series')
    global CurData
    CurData=get(ggg,'UserData');
    evalin('base','global CurData');%make CurData global in the workspace
    evalin('base','CurData'); %display CurData in the workspace
    commandwindow
   % plot_text(CurData)
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
if isequal (NomType,'_i1-i2_j') || isequal (NomType,'_i1-i2')
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
elseif isequal (NomType,'_i_j1-j2') || isequal (NomType,'#_ab')
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
function displ_time(handles,times)
%------------------------------------------------------------------------
hseries=get(handles.last_i,'parent');
SeriesData=get(hseries,'UserData');%
first_i=str2num(get(handles.first_i,'String'));
first_j=str2num(get(handles.first_j,'String'));
last_i=str2num(get(handles.last_i,'String'));
last_j=str2num(get(handles.last_j,'String'));
% index_civ=get(handles.list_pair_civ,'Value');
% NomType=get(handles.NomType,'String');
NomType=SeriesData.NomType;
mode_list=get(handles.mode,'String');
index_mode=get(handles.mode,'Value');
mode=mode_list{index_mode};
% ind_shift=0;%default

time_first=[];
time_last=[];
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
for iview=1:length(NomType)
    time_first_cell{iview}='?';
    time_last_cell{iview}='?';%default
    time=SeriesData.Time{iview};
    if isequal(NomType{iview},'_i1-i2_j')|isequal(NomType{iview},'_i_j1-j2')|isequal(NomType{iview},'#_ab')|isequal(NomType{iview},'_i1-i2')
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
        siz=size(times);
        if siz(1)>=last_i && siz(2)>=last_j && first_i>=1 && first_j>=1
            time_first=times(first_i,first_j);
            time_last=times(last_i,last_j); 
        end
    end
    time_first_cell{iview}=num2str(time_first,4);
    time_last_cell{iview}=num2str(time_last,4);
end
set(handles.time_first,'Value',1)
set(handles.time_last,'Value',1)
set(handles.time_first,'String',time_first_cell);
set(handles.time_last,'String',time_last_cell);

%------------------------------------------------------------------------
% --- Executes on button press in GetObject.
function GetObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
hseries=get(handles.GetObject,'parent');
SeriesData=get(hseries,'UserData');
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
        if isequal(transform_menu{ichoice},'px');
            data.CoordType='px';
        else
            data.CoordType='phys';
        end
        data.desable_plot=1;
        [SeriesData.hset_object,SeriesData.sethandles]=set_object(data);% call the set_object interface
     end 
else
    set(handles.GetObject,'BackgroundColor',[0.7 0.7 0.7])%put activated buttons to green
%     if isfield(SeriesData,'hset_object')&& ishandle(SeriesData.hset_object)
%         close(SeriesData.hset_object)
%     end
end
set(hseries,'UserData',SeriesData)

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

% huvmat=get(handles.transform_fct,'parent');
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
func=functions(list_transform{ind_coord});
set(handles.path_transform,'String',fileparts(func.file)); %show the path to the senlected function

%------------------------------------------------------------------------
% --- generates a series of file names with reference numbers between range1 and
% --- range2 with increment incr. The reference number num_ref is the image number at the middle of the
% --- image pair. The set of first numbers num1 of the image pairs is also
% --- given as output
function [num_i1,num_i2,num_j1,num_j2,nbmissing]=netseries_generator(filebase,subdir,mode,first_i,incr_i,last_i,first_j,incr_j,last_j)
%------------------------------------------------------------------------
[Path,Name]=fileparts(filebase);
filebasesub=fullfile(Path,subdir,Name);
filecell={};%default
num_i1=[];
num_i2=[];
num_j1=[];
num_j2=[];
ind0_i=first_i:incr_i:last_i;
nbcolumn=length(ind0_i);
ind0_j=first_j:incr_j:last_j;
nbline=length(ind0_j);
if isequal(mode,'#_ab')
    dirpair=dir([filebasesub '*_*.nc']);
elseif isequal(mode,'bursts')|isequal(mode,'series(Dj)')  
    dirpair=dir([filebasesub '_*_*-*.nc']);
elseif isequal(mode,'series(Di)')
    dirpair=dir([filebasesub '_*-*_*.nc']);
else
    msgbox_uvmat('ERROR','option *|* not yet implemented')
    return
end
if isempty(dirpair)
        msgbox_uvmat('ERROR','no pair detected in the selected range')
        return
end

if isequal(mode,'bursts')||isequal(mode,'#_ab')
    icount=0;
    for ifile=1:length(dirpair)
        [RootPath,RootFile,str_1,str_2,str_a,str_b,ext,nom_type]=name2display(dirpair(ifile).name);
        num1_r=str2num(str_1);
        if isequal(RootFile,Name) & ~isempty(num1_r)   
            num_i1(ifile)=num1_r;
            num_a(ifile)=stra2num(str_a);
            num_b(ifile)=stra2num(str_b);
        end      
    end
    test_range= (num_i1 >=first_i)&(num_i1<= last_i);% =1 when both numbers are in the range
    ind_i=((num_i1-first_i)/incr_i)+1;%indices i in the list of prescribed file indices 
    select=find(test_range &(floor(ind_i)==ind_i));%selected indices of num_i1 in the file directory
    ind_i=ind_i(select);%set of selected indices ind_i
    [ind_i,indsort]=sort(ind_i);%sorted list of ind_i
    select=select(indsort);
    num_i1=num_i1(select);
    num_a=num_a(select);
    num_b=num_b(select);
    dirpair=dirpair(select);
    [ind_remove]=find_pairs(dirpair,ind_i,nbcolumn); 
    ind_i(ind_remove)=[];
    num_a(ind_remove)=[];
    num_b(ind_remove)=[];
    num_j1=zeros(1,nbcolumn);%default
    num_j2=num_j1;
    num_j1(ind_i)=num_a;
    num_j2(ind_i)=num_b;
    num_i1=first_i:incr_i:last_i;
    num_i2=num_i1;
    nbmissing=nbcolumn-length(ind_i);

elseif isequal(mode,'series(Di)') 
    %ind0_i=first_i:incr_i:last_i;
    %nbcolumn=length(ind0_i);
    %ind0_j=first_j:incr_j:last_j;
    %nbline=length(ind0_j);
    %dirpair=dir([filebasesub '_*-*_*.nc']);
    for ifile=1:length(dirpair)
        [RootPath,RootFile,str_1,str_2,str_a,str_b,ext,nom_type]=name2display(dirpair(ifile).name);
        num_i1_r(ifile)=str2num(str_1);
        num_i2_r(ifile)=str2num(str_2);
        num_j(ifile)=str2num(str_a);
    end
    num_i=floor((num_i1_r+num_i2_r)/2); %list of reference indices of the detected files
    test_range= (num_i >=first_i)&(num_i<= last_i)&(num_j >=first_j)&(num_j<= last_j);% =1 when both numbers are in the range
    ind_i=((num_i-first_i)/incr_i)+1;%indices i and j in the list of prescribed file indices 
    ind_j=((num_j-first_j)/incr_j)+1;
    ind_ij=ind_j+nbline*(ind_i-1);%indices in the reshhaped series of prescribed file indices
    select=find(test_range &(floor(ind_i)==ind_i)&(floor(ind_j)==ind_j));%selected indices in the file directory
    ind_ij=ind_ij(select);%set of selected indices ind_ij
    [ind_ij,indsort]=sort(ind_ij);%sorted list of ind_ij 
    select=select(indsort);
    num_i1_r=num_i1_r(select);
    num_i2_r=num_i2_r(select);
    dirpair=dirpair(select);
    [ind_remove]=find_pairs(dirpair,ind_ij,nbcolumn*nbline) ;
    ind_ij(ind_remove)=[];
    num_i1_r(ind_remove)=[];
    num_i2_r(ind_remove)=[];
    num_i1=zeros(1,nbline*nbcolumn);%default
    num_i2=num_i1;
    num_i1(ind_ij)=num_i1_r;
    num_j2(ind_ij)=num_i2_r;
    num_i1=reshape(num_i1,nbline,nbcolumn);
    num_i2=reshape(num_i2,nbline,nbcolumn);
    num_j1=meshgrid(ind0_i,ind0_j);
    num_j2=num_j1;
    nbmissing=nbline*nbcolumn-length(ind_ij);
elseif isequal(mode,'series(Dj)')
    for ifile=1:length(dirpair)
        [RootPath,RootFile,str_1,str_2,str_a,str_b,ext,nom_type]=name2display(dirpair(ifile).name);
        num_i(ifile)=str2num(str_1);
        num_a(ifile)=str2num(str_a);
        num_b(ifile)=str2num(str_b);
    end
    num_j=floor((num_a+num_b)/2); %list of reference indices of the detected files
    test_range= (num_i >=first_i)&(num_i<= last_i)&(num_j >=first_j)&(num_j<= last_j);% =1 when both numbers are in the range
    ind_i=((num_i-first_i)/incr_i)+1;%indices i and j in the list of prescribed file indices 
    ind_j=((num_j-first_j)/incr_j)+1;
    ind_ij=ind_j+nbline*(ind_i-1);%indices in the reshhaped series of prescribed file indices
    select=find(test_range &(floor(ind_i)==ind_i)&(floor(ind_j)==ind_j));%selected indices in the file directory
    ind_ij=ind_ij(select);%set of selected indices ind_ij
    [ind_ij,indsort]=sort(ind_ij);%sorted list of ind_ij 
    select=select(indsort);
    num_i=num_i(select);
    num_a=num_a(select);
    num_b=num_b(select);
    dirpair=dirpair(select);
    [ind_remove]=find_pairs(dirpair,ind_ij,nbcolumn*nbline) ;
    ind_ij(ind_remove)=[];
    num_a(ind_remove)=[];
    num_b(ind_remove)=[];
    num_j1=zeros(1,nbline*nbcolumn);%default
    num_j2=num_j1;
    num_j1(ind_ij)=num_a;
    num_j2(ind_ij)=num_b;
    num_j1=reshape(num_j1,nbline,nbcolumn);
    num_j2=reshape(num_j2,nbline,nbcolumn);
    num_i1=meshgrid(ind0_i,ind0_j);
    num_i2=num_i1;
    nbmissing=nbline*nbcolumn-length(ind_ij);
end

%------------------------------------------------------------------------
% --- generates series of file indices corresponding to a file fileinput
function [num_i1,num_i2,num_j1,num_j2]=find_indexseries(fileinput)
%------------------------------------------------------------------------
num_i1=NaN;%default
num_i2=NaN;%default
num_j1=NaN;%default
num_j2=NaN;%default
% refresh input root name, indices, file extension and nomenclature
[RootPath,RootFile,field_count,str2,str_a,str_b,FileExt,NomType,SubDir]=name2display(fileinput);
if strcmp(SubDir,'')
    filebasesub=fullfile(RootPath,RootFile);
else
    filebasesub=fullfile(RootPath,SubDir,RootFile);
end
dirpair=[]; %default
switch NomType
    case '_i'
        dirpair=dir([filebasesub '_*' FileExt]);
    case '_i_j'
        dirpair=dir([filebasesub '_*_*' FileExt]);
    case '_i1-i2'
        dirpair=dir([filebasesub '_*-*' FileExt]);
    case '#_ab'
        dirpair=dir([filebasesub '*_*' FileExt]);
    case '_i_j1-j2'
        dirpair=dir([filebasesub '*_*-*' FileExt]);   
    case '_i1-i2_j'
        dirpair=dir([filebasesub '*-*_*' FileExt]);   
end
%       nom_type='#' series of indexed images wich is not series_i
%       [filebase index ext], e.g. 'aa045.jpg' or 'aa45.tif'
%       nom_type='#a','#A' with a numerical index and an index letter(e.g.'aa045b.png'), OBSOLETE (replaced by 'series_i_j')
%       nom_type='%03d' or '%04d', series of indexed images with numbers completed with zeros to 3 or 4 digits, e.g.'aa045.tif'
%       nom_type='_%03d', '_%04d', or '_%05d', series of indexed images with _ and numbers completed with zeros to 3, 4 or 5 digits, e.g.'aa_045.tif'
%       nom_type='raw_SMD', same as '#a' but with no extension ext='', OBSOLETE
%       nom_type='#_ab' from pairs of '#a' images (e.g. 'aa045bc.nc'), ext='.nc', OBSOLETE (replaced by 'netc_2D')
%       nom_type='%3dab' from pairs of '%3da' images (e.g. 'aa045bc.nc'), ext='.nc', OBSOLETE (replaced by 'netc_2D')
for ifile=1:length(dirpair)
    [RootPath,RF,str_1,str_2,str_a,str_b]=name2display(dirpair(ifile).name);
    num_i1(ifile)=str2double(str_1);
    num_i2(ifile)=str2double(str_2);
    if isnan(num_i2(ifile))
        num_i2(ifile)=num_i1(ifile);
    end
    num_j1(ifile)=stra2num(str_a);
    if isnan(num_j1(ifile))
        num_j1(ifile)=1;
    end
    num_j2(ifile)=stra2num(str_b);
    if isnan(num_j2(ifile))
        num_j2(ifile)=num_j1(ifile);
    end
end

