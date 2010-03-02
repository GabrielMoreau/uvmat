%'series': master function associated to the GUI series.m for analysis field series  
%------------------------------------------------------------------------
% function varargout = series(varargin)
% associated with the GUI series.fig
%
%INPUT
% param: structure with input parameters (link with the GUI uvmat)
%      .menu_coord_str: string for the CoordType (menu for coordinate transforms)
%      .menu_coord_val: value for CoordType (menu for coordinate transforms)
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
    set(handles.CoordType,'String',param.menu_coord_str)
end
if isfield(param,'menu_coord_val')
    set(handles.CoordType,'Value',param.menu_coord_val);
else
     set(handles.CoordType,'Value',1);%default
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
%set(hObject,'UserData', SeriesData)
set(hObject,'WindowButtonUpFcn',{@mouse_up_gui,handles}) 
NomType_Callback(hObject, eventdata, handles)
%mode_Callback(hObject, eventdata, handles)

%loads the information stored in prefdir to initiate the browser and the list of functions
menu_str={'check_files';'aver_stat';'time_series';'merge_proj';'clean_civ_cmx'};
 
% menu_str=get(handles.ACTION,'String');%list of functions included in 'series.m'

%remove from the list the last option 'more...'
[path_series,name,ext]=fileparts(which('series'));
path_series=fullfile(path_series,'/series');%path of the function 'series'

for ilist=1:length(menu_str)
    fct_path{ilist,1}=path_series;%paths of the fuctions buil-in in 'series.m'
end
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    h=load (profil_perso);
    if isfield(h,'series_fct') && iscell(h.series_fct)
         for ilist=1:length(h.series_fct)
             [path,file]=fileparts(h.series_fct{ilist});
             fct_path=[fct_path; {path}];%concatene the list of paths
             menu_str=[menu_str; {file}];
         end
    end
end

menu_str=[menu_str;{'more...'}];
set(handles.ACTION,'String',menu_str)
set(handles.ACTION,'UserData',fct_path)% store the list of path in UserData of ACTION

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

%hseries=get(handles.browse_root,'parent');
RootPathCell=get(handles.RootPath,'String');
% SubDirCell=get(handles.SubDir,'String');  
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

% --------------------------------------------------------------------
% refresh the GUI data after introduction of a new file series
function update_file(hObject, eventdata, handles,fileinput,addtest)
hseries=get(handles.RootPath,'parent');  
% refresh input root name, indices, file extension and nomenclature
[RootPath,RootFile,field_count,str2,str_a,str_b,FileExt,NomType,SubDir]=name2display(fileinput);
%check for movie image files
if ~isempty(imformats(FileExt(2:end)))
    imainfo=imfinfo(fileinput);     
    if length(imainfo) >1 %case of image with multiple frames
        NomType='*';
        [RootPath,RootFile]=fileparts(fileinput);
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
    SeriesData=get(hseries,'UserData');
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
%set(hseries,'UserData',SeriesData);

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

% hseries=get(handles.RootFile,'parent');
% SeriesData=get(hseries,'UserData');%read information set by the browser
% ext_ima_read=[];
% field_count=1;%default
% pxcmx=1;
% pxcmy=1;
TimeUnit=''; %default
% CoordUnit='';%default
time=[];%default
GeometryCalib=[];%default
nb_field=[];%default
nb_field2=[];%default
% Heading=[];
% [PD,Device]=fileparts(RootPathCell{1});
SeriesData.PathCampaign=get(handles.PathCampaign,'String');

% read timing and total frame number from the current file (movie files) !! may be overrid by xml file
%icell=length(RootPathCell);
FileBase=fullfile(RootPath,RootFile);

% nb_field{icell,1}='?';%default 
% nb_field2{icell,1}='?';%default 
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
testtransform=isequal(get(handles.CoordType,'Enable'),'on');
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
% mode=''; %default
% testheading=0;  
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
    size(time)
    GeometryCalib.R=[pxcmx 0 0; 0 pxcmy 0;0 0 0];
    GeometryCalib.Tx=0;
    GeometryCalib.Ty=0;
    GeometryCalib.Tz=1;
    GeometryCalib.dpx=1;
    GeometryCalib.dpy=1;
    GeometryCalib.sx=1;
    GeometryCalib.Cx=0;
    GeometryCalib.Cy=0;
    GeometryCalib.f=1;
    GeometryCalib.kappa1=0;
    GeometryCalib.CoordUnit='cm';
    XmlData.GeometryCalib=GeometryCalib;
    if error==2, warntext=['no file ' FileBase '.civ'];
    elseif error==1, warntext='inconsistent number of fields in the .civ file';
    end  
%     set(handles.npx,'String',num2str(npx));%fills nbre of pixels x box
%     set(handles.npy,'String',num2str(npy));%fills nbre of pixels y box
%     set(handles.pxcm,'String',num2str(pxcmx));%fills scale x (pixel/cm) box
%     set(handles.pycm,'String',num2str(pxcmy));%fills scale y (pixel/cm) box
%     set(handles.pxcm,'Visible','on');%fills scale x (pixel/cm) box 
%     set(handles.pycm,'Visible','on');%fills scale y (pixel/cm) box 
%     set(handles.view_xml,'Visible','on')
%     set(handles.view_xml,'String','view .civ')
end  
if addtest
    SeriesData.Time=[{time} SeriesData.Time];
else
   SeriesData.Time={time};
end

if ~isempty(time)
    siztime=size(time);
    nb_field=siztime(1);
    nb_field2=siztime(2);
end   
set(handles.TimeUnit,'String',TimeUnit)
if isempty(nb_field)
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
set(hseries,'UserData',SeriesData);

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

dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
% save(profil_perso, 'FileBase'); %store the root name for future opening of uvmat
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

function NomType_Callback(hObject, eventdata, handles)
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
end
set(handles.first_j,'Visible',state_j)
set(handles.incr_j,'Visible',state_j)
set(handles.last_j,'Visible',state_j)
set(handles.nb_field2,'Visible',state_j)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%????????????
% --- Executes on button press in mode.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mode_Callback(hObject, eventdata, handles)
hseries=get(handles.mode,'parent');
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
% displ_num=[];%default
% first_i=str2num(get(handles.first_i,'String'));
% last_i=str2num(get(handles.last_i,'String'));
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
    enable_j(handles,'Off')    
elseif  isequal(NomType,'_i_j1-j2')|| isequal(NomType,'_i1-i2_j')
    enable_i(handles,'On')
    enable_j(handles,'On') 
else
    enable_i(handles,'On')
    enable_j(handles,'Off') 
end    
    
    
% elseif isequal(mode,'series(Dj)')       
%     enable_j(handles,'On')     
%     if nbfield==1
%         enable_i(handles,'Off') 
%     else
%         enable_i(handles,'On')
%     end
% elseif isequal(mode,'series(Di)') 
%     if nbfield2 > 1
%          enable_j(handles,'On')
%     else
%          enable_j(handles,'Off')
%     end
% end  
set(handles.list_pair_civ,'Value',indchosen);%set the default choice of image pairs for civ1
% SetSeries.displ_num=displ_num;
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
set(handles.CoordType,'Visible',state);
set(handles.TRANSFORM_title,'Visible',state)

%--------------------------------------------------------------
% determine the menu for civ1 pairs depending on existing netcdf file at the middle of
% the field series set by first_i, incr, last_i
%----------------------------------------------------------------
function find_netcpair_civ(hObject, eventdata, handles,Val)
hseries=get(handles.list_pair_civ,'parent');
SeriesData=get(hseries,'UserData'); 
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
                [Cte,var_detect,ichoice]=nc2struct(nc,{});
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
set(hseries,'UserData',SeriesData)
list_pair_civ_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------
% --- Executes on selection in list_pair_civ.
function list_pair_civ_Callback(hObject, eventdata, handles)
%------------------------------------------------------------

%update first_i and last_i according to the chosen image pairs 
testupdate=0;
Val=get(handles.RootPath,'Value');
IndexCell=get(handles.NomType,'String');
hseries=get(handles.list_pair_civ,'parent');
SeriesData=get(hseries,'UserData');
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
set(hseries,'UserData',SeriesData)
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
        set(handles.first_i,'String',num2str(num1(1)));
        set(handles.last_i,'String',num2str(num1(end)));
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
	if testupdate & isfield(SeriesData,'Time')
        if ~isempty(SeriesData.Time{1})
            displ_time(handles,SeriesData.Time{1});
        end
	end
end
%---------------------------------------------------
% --- Executes on button press in RUN.
%------------------------------------------------------
function RUN_Callback(hObject, eventdata, handles)

%read root name and field type
set(handles.RUN,'BusyAction','queue');
hseries=get(handles.RUN,'parent');
set(0,'CurrentFigure',hseries)
if isequal(get(handles.GetObject,'Value'),1) 
    Series.GetObject=1;
    GetObject_Callback(hObject, eventdata, handles)
else
    Series.GetObject=0;
end
SeriesData=get(hseries,'UserData');
if isfield(SeriesData,'sethandles')
    if iscell(SeriesData.sethandles)
        Series.sethandles=SeriesData.sethandles{1};
    else
        Series.sethandles=SeriesData.sethandles;%retrieve the handles of the set_object interface (to define projection objects)
    end
end

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
menu_coord_state=get(handles.CoordType,'Visible');
Series.CoordType='';%default
if isequal(menu_coord_state,'on')
    menu_coord=get(handles.CoordType,'String');
    menu_index=get(handles.CoordType,'Value');
    Series.CoordType=menu_coord{menu_index};
end
Series.hseries=get(hObject,'Parent');
if isequal(get(handles.ParamVal,'Visible'),'on')
    ParamKey=get(handles.ParamKey,'String');
    if ischar(ParamKey)
        ParamKey{1}=ParamKey;
    end
    ParamString=get(handles.ParamVal,'String');
    if ischar(ParamString)
        for ilist=1:size(ParamString,1)
            ParamVal{ilist}=ParamString(ilist,:);
        end
    else
        ParamVal=ParamString;
    end   
end

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
    
    if isequal(NomType{iview},'_i_j1-j2')| isequal(NomType{iview},'_i1-i2_j')| isequal(NomType{iview},'_i1-i2')| isequal(NomType{iview},'#_ab')
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

% RUN RUN'
path_series=which('series');
list_path=get(handles.ACTION,'UserData');
index=get(handles.ACTION,'Value');
fct_path=list_path{index}; %path stored for the function ACTION
if ~isequal(fct_path,path_series)
    eval(['spath=which(''' action ''');']) %spath = current path of the selected function ACTION
    if ~isequal(spath,fct_path)& exist(fct_path,'dir')
        addpath(fct_path)% add the prescribed path if not the current one
    end
end
% fct_path
        eval(['h_fun=@' action])
if ~isequal(fct_path,path_series)
        rmpath(fct_path)% add the prescribed path if not the current one    
end

Series.Action=action;%name of the processing programme
set(handles.RUN,'BackgroundColor',[0.831 0.816 0.784])
drawnow
if length(RootPath)>1
%    feval(action,num_i1_cell,num_i2_cell,num_j1_cell,num_j2_cell,Series);
    h_fun(num_i1_cell,num_i2_cell,num_j1_cell,num_j2_cell,Series);
else
    h_fun(num_i1,num_i2,num_j1,num_j2,Series);
%     feval(action,num_i1,num_i2,num_j1,num_j2,Series);
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

%----------------------------------------------------
function STOP_Callback(hObject, eventdata, handles)
set(handles.RUN, 'BusyAction','cancel')
set(handles.RUN,'BackgroundColor',[1 0 0])

%----------------------------------------------

%----------------------------------------------------
function first_i_Callback(hObject, eventdata, handles)
last_i_Callback(hObject, eventdata, handles)

%----------------------------------------------
function last_i_Callback(hObject, eventdata, handles)
    hseries=get(handles.last_i,'parent');
first_i=str2num(get(handles.first_i,'String'));
last_i=str2num(get(handles.last_i,'String'));
ref_i=ceil((first_i+last_i)/2);
set(handles.ref_i,'String', num2str(ref_i))
ref_i_Callback(hObject, eventdata, handles)
SeriesData=get(hseries,'UserData');
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
displ_time(handles,SeriesData.Time{1});

%-------------------------------------------------------
function first_j_Callback(hObject, eventdata, handles)
 last_j_Callback(hObject, eventdata, handles)

%-------------------------------------------------------
function last_j_Callback(hObject, eventdata, handles)
    hseries=get(handles.last_i,'parent');
first_j=str2num(get(handles.first_j,'String'));
last_j=str2num(get(handles.last_j,'String'));
ref_j=ceil((first_j+last_j)/2);
set(handles.ref_j,'String', num2str(ref_j))

ref_j_Callback(hObject, eventdata, handles)
SeriesData=get(hseries,'UserData');
if ~isfield(SeriesData,'Time')
    SeriesData.Time{1}=[];
end
displ_time(handles,SeriesData.Time{1});




%-------------------------------------------------------
function ref_i_Callback(hObject, eventdata, handles)
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
hseries=get(handles.ref_i,'parent');
SeriesData=get(hseries,'UserData');
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

%----------------------------------------------------
function ref_j_Callback(hObject, eventdata, handles)
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
hseries=get(handles.ref_i,'parent');
SeriesData=get(hseries,'UserData');
%NomTypeCell=get(handles.NomType,'String');
NomTypeCell=SeriesData.NomType;
if ~isempty(NomTypeCell)
Val=get(handles.NomType,'Value');
NomType=NomTypeCell{Val};
% NomType=get(handles.NomType,'String');
    if isequal(NomType,'_i_j1-j2')|| isequal(NomType,'_i1-i2_j')|| isequal(NomType,'_i1-i2')
        if isequal(mode,'series(Dj)') 
            find_netcpair_civ(hObject, eventdata, handles,Val);% update the menu of pairs depending on the available netcdf files
%             break
        end
    end
end

%----------------------------------------------------
% --- Executes on selection change in ACTION.
function ACTION_Callback(hObject, eventdata, handles)
list_ACTION=get(handles.ACTION,'String');% list menu fields
index_ACTION=get(handles.ACTION,'Value');% selected string index
ACTION= list_ACTION{index_ACTION}; % selected function name
path_series=which('series');%path to series.m
list_path=get(handles.ACTION,'UserData');%list of recorded paths to functions of the list ACTION
nb_builtin=0;
for ilist=1:length(list_path)
    if isequal(list_path{ilist},path_series)
        nb_builtin=nb_builtin+1;
    else
        break
    end
end
if nb_builtin==0% the path of series has been changed, reinitialize
%     series_OpeningFcn(hObject, eventdata, handles)
    return
end

% add a new function to the menu
if isequal(ACTION,'more...')
    pathfct=fileparts(path_series);
    browse_name=fullfile(path_series,'series');%go to UVMAT/SERIES_FCT by default
    if length(list_path)>nb_builtin
        browse_name=list_path{end};% initialize browser with  the path of the last introduced function
     end 
    [FileName, PathName, filterindex] = uigetfile( ...
       {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',browse_name);
    if length(FileName)<2
        return
    end
    
    
    
    ext_fct=FileName(end-1:end);% to be replaced by fileparts
    if ~isequal(ext_fct,'.m')
        msgbox_uvmat('ERROR','a Matlab function .m must be introduced');
        return
    end
    ACTION=FileName(1:end-2);% ACTION choice updated by the selected item
    
    addpath(PathName)
    eval(['h_function=@' ACTION]);
    if ~isequal(path_series,PathName)
    rmpath(PathName)
    end
    functions(h_function)
    
   % insert the choice in the action menu
   menu_str=update_menu(handles.ACTION,ACTION);%new action menu in which the new item has been appended if needed
   index_ACTION=get(handles.ACTION,'Value');% currently selected index in the list
   list_path{index_ACTION}=PathName;
   if length(menu_str)>nb_builtin+5;
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
if ~isequal(path_series,PathName)
    CurrentPath=fileparts(which(ACTION));
    if ~isequal(CurrentPath,PathName)&&~isequal(CurrentPath,fullfile(PathName,'private'))
        addpath(PathName) 
        errormsg=check_functions;
        msgbox_uvmat('CONFIRMATION',[['path ' PathName ' added to the current Matlab pathes'];errormsg])
    end
end
set(handles.path,'String',PathName); %show the path to the senlected function

%default setting for the visibility of the GUI elements
%set( handles.Field,'Visible','off')%default
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
set(handles.CoordType,'Enable','off')
%set the displayed GUI item needed for input parameters
%list_input=feval(ACTION);% input list asked by the selected function
varargout=feval(ACTION);% input list asked by the selected function
Param_list={};
% RootPath=get(handles.RootPath,'String');
% RootFile=get(handles.RootFile,'String');

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
                set(handles.CoordType,'Enable','on')
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

%-------------------------------------------------------------------
% --- Executes on selection change in FieldMenu.
%-------------------------------------------------------------------
function FieldMenu_Callback(hObject, eventdata, handles)

field_str=get(handles.FieldMenu,'String');
field_index=get(handles.FieldMenu,'Value');
field=field_str{field_index(1)};
if isequal(field,'get_field...')    
     hget_field=findobj(allchild(0),'name','get_field');
     if ~isempty(hget_field)
         delete(hget_field)%delete opened versions of get_field
     end
     hseries=get(handles.FieldMenu,'parent');
     SeriesData=get(hseries,'UserData');
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

%------------------------------------------------------
% --- Executes on selection change in FieldMenu_1.
%-----------------------------------------------------
function FieldMenu_1_Callback(hObject, eventdata, handles)
field_str=get(handles.FieldMenu_1,'String');
field_index=get(handles.FieldMenu_1,'Value');
field=field_str{field_index};
if isequal(field,'get_field...')    
     hget_field=findobj(allchild(0),'name','get_field_1');
     if ~isempty(hget_field)
         delete(hget_field)
     end
     hseries=get(handles.FieldMenu,'parent');
     SeriesData=get(hseries,'UserData');
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
% %----------------------------------------------------------------------
% % --makes a time averaged velocity field 
% %----------------------------------------------------------------------
% function aver_vel(num_i1,num_i2,num_j1,num_j2,Series)
%                           %handles of the GUI series
%   
% hseries=guidata(Series.hseries);%handles of the GUI series
% WaitbarPos=get(hseries.waitbar_frame,'Position');
% Field_list=get(hseries.FieldMenu,'String');
% val=get(hseries.FieldMenu,'Value');
% FieldName=Field_list{val(1)};
% set(hseries.FieldMenu,'Value',val(1))% select only one input field
% if isequal(FieldName,'get_field...')
%     hget_field=findobj(allchild(0),'Name','get_field');%find the get_field... GUI
% end
% %root input file and type
% RootPath=get(hseries.RootPath,'String');
% SubDir=get(hseries.SubDir,'String');
% RootFile=get(hseries.RootFile,'String');
% %NomType=get(hseries.NomType,'String');
% NomType=Series.NomType;
% FileExt=get(hseries.FileExt,'String');
% ext=FileExt{1};     
% VelType_str=get(hseries.VelTypeMenu,'String');
% VelType_val=get(hseries.VelTypeMenu,'Value');
% VelType{1}=VelType_str{VelType_val};
% 
% time=0; %default
% % number of slices
% NbSlice=str2num(get(hseries.NbSlice,'String'));
% if isempty(NbSlice)
%     NbSlice=1;
% end
% NbSlice_name=num2str(NbSlice);
% filebase=fullfile(RootPath{1},RootFile{1});
% Calib=[];
% if exist([filebase '.xml'],'file')
%     %[error,Heading,nom_type_read,ext_ima_read,time_imadoc,TimeUnit,mode,NbSlice,npx,npy,Calib]=read_imadoc([filebase '.xml']);
%     [XmlData,warntext]=imadoc2struct([filebase '.xml']);
% end
% if NbSlice==1
%    filebase_mean=[filebase '_mean']; %root name for the result
% else
%    filebase_mean=[filebase '_' NbSlice_name 'mean']; %root name for the results
%    answeryes=questdlg({['will make average in ' num2str(NbSlice) ' slices'];['results stored as files ' filebase_mean ' ...']});
%     if ~isequal(answeryes,'Yes')
%     return
%     end
% end
% siz=size(num_i1);
% nbfield2=siz(1); %nb of consecutive fields at each level(burst)
% lengthtot=siz(1)*siz(2);
% nbfield=floor(lengthtot/(nbfield2*NbSlice));%total number of i indexes (adjusted to an integer number of slices)
% nbfield_slice=nbfield*nbfield2;% number of fields per slice
% %projection object
% GridX=[];
% GridY=[];
% if isfield(Series,'sethandles')
%         Series.ProjObject=read_set_object(Series.sethandles);
%         if isfield(Series.ProjObject,'Style')
%             answeryes=questdlg({['statistics on field series projected on ' Series.ProjObject.Style]});
%             if ~isequal(answeryes,'Yes')
%                 return
%             end
%         end
% end
% 
% %LOOP ON SLICES
% for i_slice=1:NbSlice
%     %select the series of image indices at the level islice
%     for ifield=1:nbfield
%         indselect(:,ifield)=((ifield-1)*NbSlice+(i_slice-1))*nbfield2+[1:nbfield2]';%selected indices on the list of files of a slice
%     end  
%     %name of result file
%     [filemean,idetect]=...
%                name_generator(filebase_mean,num_i1(i_slice),num_j1(1),Series.FileExt{1},'_i1-i2_j1-j2',1,num_i2(i_slice+nbfield_slice*NbSlice-1),num_j2(end),Series.SubDir{1});
% 
%     % field=get(handles.civ1,'UserData');%read current selected field type (civ1,civ2...)
%     itime=0;
%      dt=[];
%      %LOOP ON FIELDS IN  A SLICE
%      test_interpolate=0;%default
%     for index=1:nbfield*nbfield2
%             ifile=indselect(index);
%         stopstate=get(hseries.RUN,'BusyAction');
%         if isequal(stopstate,'queue')% enable STOP command
%             update_waitbar(hseries.waitbar,WaitbarPos,ifile/(nbfield*nbfield2))
%             %name of the current file
%             [filename,idetect]=name_generator(filebase,num_i1(ifile),num_j1(ifile),Series.FileExt{1},Series.NomType{1},1,num_i2(ifile),num_j2(ifile),Series.SubDir{1});
%             %read input file
%             itime=itime+1;
%             if isequal(FieldName,'get_field...')
%                 hhget_field=guidata(hget_field);%handles of GUI elements in get_field
%                 hObject=0;
%                 eventdata=0;
%                 SubField=get_field('read_var_names',hObject,eventdata,hhget_field); %read the names of the variables to plot in the get_field GUI 
%                 [Data,var_detect]=nc2struct(filename,SubField.ListVarName); %read input data   
%                 time(itime)=itime;
%                 dt=1; 
%                 Calib_read=[];
%             else
%                 [nb_coord,nb_dim,Civ,CivStage,timeread,Data,VelTypeOut,Calib_read]=read_ncfield(filename,VelType{1});%reading the first file
%                  time(itime)=timeread;
%                 if isequal(Civ,1)
%                     Data.CoordType='px';%test for pixel coordinates
%                     if isequal(itime,1)
%                         dt=Data.dt;
%                     elseif ~isequal(Data.dt,dt)
%                         warndlg_uvmat('series with non constant dt, need phys coordinates','ERROR')
%                         return
%                     end
%                 end 
%             end
%             %increment the detected fields, skip the others
%             if idetect==0
%                 warndlg_uvmat(['input file ' filename ' not found'],'ERROR')
%                 %A FAIRE STOCKER LE RESULT ACTUEL S'IL EXISTE
%             end
% %             itime=itime+1;
% %             time(itime)=timeread;
%        
%             %coordinate transform
%             if isempty(Calib)
%                 Calib=Calib_read;%use Calib from xml file in priority, then Calib from the current file
%             end
%             if ~isequal(Series.CoordType,'')
%                 Data=feval(Series.CoordType,Data,Calib);
%             end
%             %projection on object if defined
%             if isfield(Series,'ProjObject');
%                 Data=proj_field(Data,Series.ProjObject);
%                 if isequal(itime,1)%use the positions on the first field for the whole series, ou utiliser grille
%                     if isfield(Data,'Txt')%display error message
%                         warndlg(Data.Txt,'ERROR')
%                         return
%                     end
%                 end
%             else%remove false vectors and interpolate on the positions of the first field
%                 Data=document_field(Data);
%                 Data.Style='plane';
%             end 
%     %%%%%%%%% initiate the average at the first iteration: check list and structure of variables
%             if ifile==i_slice%first field in the slice
%                 testfalse=0;
%                 ListIndex={};
%                 testnewcell=1;
%                 %group the variables (fields of 'Data') in cells of variables with the same dimensions
%                 [DimVarIndex,CellVarIndex]=find_field_indices(Data);
%                 VarIndex=CellVarIndex{1}; % ONLY THE FIRST VAR GROUP IS AVERAGED
%                 DimIndex=Data.VarDimIndex{VarIndex(1)};%indices of the dimensions of the first variable (common to all variables in the cell)         
%                 MeanData=Data;%transfer heading
%                 MeanData.Time=[time(1) time(end)];
%                 MeanData.Action=Series.Action;%name of the processing programme
%                 MeanData.ListDimName=Data.ListDimName(DimIndex);%name of dimension 
%                 MeanData.DimValue=Data.DimValue(DimIndex);%values of dimension (nbre of vectors)
%                 MeanData.ListVarName=Data.ListVarName;
%                 MeanData.VarDimIndex=Data.VarDimIndex;
%                 MeanData.ListVarAttribute={'Role'};%list of variable attribute names A FAIRE: transferer les autres attributs
%                 testsum=ones(size(VarIndex));
%                 indexfalse=0;
%                 CoordName={};
%                 indexremove=[];
%                 if isfield(Data,'Role') % look for coordinate and flag variables    
%                     for ivar=1:length(VarIndex)
%                         VarName=Data.ListVarName{VarIndex(ivar)};
%                         var_role=Data.Role{VarIndex(ivar)};%'role' of the variable
%                         MeanData.Role{ivar}=var_role; 
%                         if isequal(var_role,'falseflag')
%                             indexfalse=ivar; %test for false flag 
%                             indexremove=ivar;
%                             FFName=VarName;
%                             testsum(ivar)=0;
%                             eval(['MeanData=rmfield(MeanData,''' VarName ''');']);%remove variable                      
%                         end
%                         if isequal(var_role,'warnflag')                        
%                             testsum(ivar)=0; %do not sum warn flag 
%                             eval(['MeanData=rmfield(MeanData,''' VarName ''');']);%remove variable
%                             indexremove=[indexremove ivar];
%                         end                  
%                         if isequal(var_role,'coord_x')| isequal(var_role,'coord_y')|isequal(var_role,'coord_z')
%                             eval(['MeanData.' VarName '=Data.' VarName ';']);
%                             testsum(ivar)=0;
%                             eval(['CoordName=[CoordName ''' VarName '''];']);
%                         end
%                         if testsum(ivar)~=0
%                            eval(['MeanData.' VarName '=zeros(size(Data.' VarName '));']);%initialise sum
%                         end
%                     end
%                 end
%                 findsum=find(testsum);
%                 VarIndexSum=VarIndex(findsum);%indices of variables to sum (not coordinates nor flags)
%                 if length(CoordName)==0 
%                     if isempty(DimVarIndex)|isequal(DimVarIndex,0)% no coordinate variable for structured coordinates, prepare histograms
%                          for ilist=1:length(VarIndexSum)
%                             VarName=Data.ListVarName{VarIndexSum(ilist)};
%                             eval(['MeanData=rmfield(MeanData,''' VarName ''');']);%remove variable
%                             indexremove=[indexremove ilist];
%                             eval(['[MeanData.' VarName 'hist,MeanData.' VarName 'val]=hist(Data.' VarName ',100);']);%make histo
%                             eval(['sizhist=size(MeanData.' VarName 'hist);'])
%                             if sizhist(1)==1
%                                 eval(['MeanData.' VarName 'hist=MeanData.' VarName 'hist'';'])
%                             end
%                             eval(['maxval=max(MeanData.' VarName 'val);']);
%                             eval(['minval=min(MeanData.' VarName 'val);']);
%                             dC(ilist)=(maxval-minval)/100;%size of the histogram bin    
%                          end
%                     else
% %                         icoord=0;
% %                         for ilist=1:length(DimVarIndex)  
% %                             VarDim=Data.ListVarName{DimVarIndex(ilist)};
% %                             icoord=icoord+1;
% %                             % eval(['Coord{' num2str(icord) '}=[' CoordName ''' VarName ''']']);
% %                              %eval(['Data.' CoordName{icoord} '=Data.' CoordName{icoord} '(indsel);']);
% %                         end
%                     end
%                 end
%                 if ~isempty(indexremove)
%                     MeanData.ListVarName(VarIndex(indexremove))=[];
%                     MeanData.VarDimIndex(VarIndex(indexremove))=[];
%                     if isfield(MeanData,'Role')%generaliser aus autres attributs
%                         MeanData.Role(VarIndex(indexremove))=[];
%                     end
%                 end
%                % END OF INITIALISATION
% 
%             end
%        
%          % A FAIRE: regular grid if coord_x undefined
%             if indexfalse~=0 %suppress false data
%                  eval(['testexist=isfield(Data,''' FFName ''');'])
%                 if testexist
%                     eval(['indsel=find(Data.' FFName '==0);']);
%                     for icoord=1:length(CoordName)
%                         eval(['Data.' CoordName{icoord} '=Data.' CoordName{icoord} '(indsel);']);
%                     end
%                 end
%             end
%             for ilist=1:length(VarIndexSum)
%                 VarName=Data.ListVarName{VarIndexSum(ilist)};
%                 if indexfalse~=0 & testexist
%                     eval(['Data.' VarName '=Data.' VarName '(indsel);']);
%                 end
%                 if length(CoordName)==0%no variable use dfor unstructured coordinates
%                     if isempty(DimVarIndex)|isequal(DimVarIndex,0)% no coordinate variable for structured coordinates
% %                         %update histogram with the current field #ifile
%                         str_left=['[MeanData.' VarName 'val,MeanData.' VarName 'hist]='];
%                         str_right=['hist_update(MeanData.' VarName 'val,MeanData.' VarName 'hist,Data.' VarName ',dC(ilist));']; 
%                         eval([str_left str_right]);%update global histo
%                     else
%                        %INTERPOLER
%                             
%                         eval(['MeanData.' VarName '=MeanData.' VarName '+Data.' VarName ';']);%increment sum%CAS x,y change
%                     end
%                 else   
%                     if length(CoordName)==2
%                         eval(['test_interp= ~isequal(Data.' CoordName{1} ',MeanData.' CoordName{1} ...
%                             ')|~isequal(Data.' CoordName{2} ',MeanData.' CoordName{2} ');'])
%                         if test_interp
%                             eval(['Data.' VarName '=griddata_uvmat(Data.' CoordName{1} ',Data.' CoordName{2}...
%                                 ',Data.' VarName ',MeanData.' CoordName{1} ',MeanData.' CoordName{2} ');']);
%                             test_interpolate=1;
%                         end
%                     end 
%                     eval(['MeanData.' VarName '=MeanData.' VarName '+Data.' VarName ';']);%increment sum
%                 end
%             end
%         end
%     end
%     if length(CoordName)~=0 | ~isequal(DimVarIndex,0)% no coordinate variable for structured coordinates
%         for ilist=1:length(VarIndexSum)  
%             VarName=Data.ListVarName{VarIndexSum(ilist)};
%             eval(['MeanData.' VarName '=MeanData.' VarName '/itime;']);%normalize sum by the number of fields
%         end
%     else
%         MeanData.NbDim=1;
%         MeanData.ListDimName={};
%         MeanData.DimValue=[];
%         for ilist=1:length(VarIndexSum)  
%             VarName=Data.ListVarName{VarIndexSum(ilist)};
%             MeanData.ListVarName=[MeanData.ListVarName {[VarName 'val']} {[VarName 'hist']}];
%             MeanData.VarDimIndex=[MeanData.VarDimIndex {[ilist]} {[ilist]}];
%             MeanData.ListDimName=[MeanData.ListDimName {[VarName 'val']}];
%             eval(['MeanData.DimValue=[MeanData.DimValue length(MeanData.' VarName 'val)];']);
%         end   
%     end
%     figure
%     haxes=axes;
%     plot_field(MeanData,haxes)%plot the resulting average
%     % change variable names for consitency with civ1 data (need to generalize these programs)
%     if length(MeanData.ListVarName) >= 4 & isequal(MeanData.ListVarName(1:4), {'X'  'Y'  'U'  'V'})
%        MeanData.ListGlobalAttribute={'nb_coord','nb_dim','dt','absolut_time_T0','pixcmx','pixcmy','hart','civ','fix'};
%        MeanData.nb_coord=2;
%        MeanData.nb_dim=2;
%        MeanData.dt=1;
%        MeanData.absolut_time_T0=0;
%        MeanData.pixcmx=1; %pix per cm (1 by default)
%        MeanData.pixcmy=1; %pix per cm (1 by default)
%        MeanData.hart=0;
%        if isequal(Data.CoordType,'px')
%          MeanData.civ=1;
%       else
%          MeanData.civ=0;
%        end
%       MeanData.fix=0;
%         MeanData.ListVarName(1:4)={'vec_X'  'vec_Y'  'vec_U'  'vec_V'};
%         MeanData.vec_X=MeanData.X;
%         MeanData.vec_Y=MeanData.Y;
%         MeanData.vec_U=MeanData.U;
%         MeanData.vec_V=MeanData.V;
%     end
%     error=struct2nc(filemean,MeanData); %save result file
%     if isequal(error,0)
%         if test_interpolate
%             'fields interpolated to the positions of the first one'
%         end
%         [filemean ' written']
%     else
%         warndlg_uvmat(error,'ERROR')
%     end
% end

%----------------------------------------------------------------------
% --project fields on a projection object (e. g. a regular grid), possibly
% merge several fields
%----------------------------------------------------------------------
%INPUT: 
%num_i1: series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2: series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1: series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2: series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%OTHER INPUTS given by the structure Series
function GUI_input=merge_proj(num_i1,num_i2,num_j1,num_j2,Series);

%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
    GUI_input={'RootPath';'two';...%nbre of possible input series (options 'on'/'two'/'many', default:'one')
        'SubDir';'on';... % subdirectory of derived files (PIV fields), ('on' by default)
        'RootFile';'on';... %root input file name ('on' by default)
        'FileExt';'on';... %input file extension ('on' by default)
        'NomType';'on';...%type of file indexing ('on' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelTypeMenu';'one';...% menu for selecting the velocity type (civ1,..) options 'off'/'one'/'two', 'off' by default)
        'FieldMenu';'one';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'CoordType';'on';...%can use a transform function 'off' by default
        'GetObject';'on';...%can use projection object ,'off' by default
        %'GetMask';'on'...%can use mask option   ,'off' by default
        %'PARAMETER'; options: name of the user defined parameter',repeat a line for each parameter 
               ''};
    return %exit the function 
end

%-------------------------------------------------
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position'); %positiopn of waitbar frame
%-------------------------------------------------

%numbers of view fields (nbre of inputs in RootPath)
testcell=iscell(Series.RootFile);
if ~testcell
    Series.RootPath={Series.RootPath};
    Series.RootFile={Series.RootFile};
    Series.SubDir={Series.SubDir};
    Series.FileExt={Series.FileExt};
    Series.NomType={Series.NomType};
    num_i1={num_i1};
    num_i2={num_i2};
    num_j1={num_j1};
    num_j2={num_j2};
end 
nbview=length(Series.RootFile);%number of views (file series to merge)
nbfield=size(num_i1{1},1)*size(num_i1{1},2);%number of fields in the time series
transform=Series.CoordType; %  field transform function
hhh=which('mmreader');
for iview=1:nbview
    test_movie(iview)=0;
    if ~isequal(hhh,'')&& mmreader.isPlatformSupported()
        if isequal(lower(FileExt{iview}),'.avi')
            MovieObject{iview}=mmreader(fullfile(RootPath{iview},[RootFile{iview} FileExt{iview}]));
            test_movie(iview)=1;
        end
    end 
end

%Calibration data and timing: read the ImaDoc files
mode=''; %default
timecell={};
itime=0;
NbSlice_calib={}; %test for z index 
for iview=1:nbview%Loop on views
    XmlData{iview}=[];%default
    filebase{iview}=fullfile(Series.RootPath{iview},Series.RootFile{iview});
    if exist([filebase{iview} '.xml'],'file')
        [XmlData{iview},error]=imadoc2struct([filebase{iview} '.xml']); 
        if isfield(XmlData{iview},'Time')
            itime=itime+1;
            timecell{itime}=XmlData{iview}.Time;
        end
        if isfield(XmlData{iview},'GeometryCalib') && isfield(XmlData{iview}.GeometryCalib,'SliceCoord')
            NbSlice_calib{iview}=size(XmlData{iview}.GeometryCalib.SliceCoord,1);
            if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
                msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
            end
        end    
    elseif exist([filebase{iview} '.civ'],'file')
        [error,time,TimeUnit,mode,npx,npy,pxcmx,pxcmy]=read_imatext([filebase{iview} '.civ']);
        itime=itime+1;
        timecell{itime}=time;
        XmlData{iview}.Time=time;
        GeometryCalib.R=[pxcmx 0 0; 0 pxcmy 0;0 0 0];
        GeometryCalib.Tx=0;
        GeometryCalib.Ty=0;
        GeometryCalib.Tz=1;
        GeometryCalib.dpx=1;
        GeometryCalib.dpy=1;
        GeometryCalib.sx=1;
        GeometryCalib.Cx=0;
        GeometryCalib.Cy=0;
        GeometryCalib.f=1;
        GeometryCalib.kappa1=0;
        GeometryCalib.CoordUnit='cm';
        XmlData{iview}.GeometryCalib=GeometryCalib;
        if error==1
            msgbox_uvmat('WARNING','inconsistent number of fields in the .civ file');
        end
    end
end

%check coincidence in time
multitime=0;
if length(timecell)==0
    time=[];
elseif length(timecell)==1
    time=timecell{1};
elseif length(timecell)>1
    multitime=1;
    for icell=1:length(timecell)
        if ~isequal(size(timecell{icell}),size(timecell{1}))
            msgbox_uvmat('WARNING','inconsistent time array dimensions in ImaDoc fields, the time for the first series is used')
            time=timecell{1};
            multitime=0;
            break
        end
    end
end
if multitime
    for icell=1:length(timecell)
        time(icell,:,:)=timecell{icell};
    end
    diff_time=max(max(diff(time)));
    if diff_time>0
        msgbox_uvmat('WARNING',['times of series differ by more than ' num2str(diff_time)])
    end   
end
if size(time,2) < num_i2{1}(end) || size(time,3) < num_j2{1}(end)% ime array absent or too short in ImaDoc xml file' 
    time=[];
end

% Field and velocity type (the same for all views)
Field_str=get(hseries.FieldMenu,'String');
val=get(hseries.FieldMenu,'Value');
FieldName=Field_str(val);%the same set of fields for all views
VelType_str=get(hseries.VelTypeMenu,'String');
VelType_val=get(hseries.VelTypeMenu,'Value');
VelType=VelType_str{VelType_val}; %the same for all views
if isequal(FieldName,'get_field...')
    hget_field=findobj(allchild(0),'Name','get_field');%find the get_field... GUI
   % hhget_field=guidata(hget_field);%handles of GUI elements in get_field
    SubField=get_field('read_get_field',hObject,eventdata,hget_field); %read the names of the variables to plot in the get_field GUI
%     if isequal(get(hhget_field.menu_coord,'Visible'),'on')
%         list_transform=get(hhget_field.menu_coord,'String');
%         val_list=get(hhget_field.menu_coord,'Value');
%         transform=list_transform{val_list};
%     end
end
%detect whether all the files are 'images' or 'netcdf'
testima=0;
testvol=0;
testcivx=0;
testnc=0;
FileExt=get(hseries.FileExt,'String');
for iview=1:nbview
     ext=FileExt{iview};
     form=imformats(ext([2:end]));
     if isequal(lower(ext),'.vol')
         testvol=testvol+1;
     elseif ~isempty(form)||isequal(lower(ext),'.avi')% if the extension corresponds to an image format recognized by Matlab
         testima=testima+1;
     elseif isequal(ext,'.nc')
         testnc=testnc+1;
     end
end
if testvol
    msgbox_uvmat('ERROR','volume images not implemented yet')
    return
end
if testnc~=nbview && testima~=nbview && testvol~=nbview
    msgbox_uvmat('ERROR','need a set of images or a set of netcdf files with the same fields as input')
    return
end
if ~isequal(FieldName,'get_field...')
    testcivx=testnc;
end
%name of output files and directory:
% res_subdir=fullfile(Series.RootPath{1},[Series.SubDir{1} '_STAT']);
ProjectDir=fileparts(fileparts(Series.RootPath{1}));% preoject directory (GERK)
prompt={['result directory (in' ProjectDir ')']};
RootPath=get(hseries.RootPath,'String');
SubDir=get(hseries.SubDir,'String');
if isequal(length(RootPath),1)
    fulldir=RootPath{1};
    subdir='GRID';
    res_subdir=fullfile(fulldir,subdir);
else
    def={fullfile(ProjectDir,'0_RESULTS')};
    dlgTitle='result directory';
    lineNo=1;
    answer=msgbox_uvmat('INPUT_TXT',dlgTitle,def);
    fulldir=answer{1};
    subdir=[];
    dirlist=sort(Series.RootFile);
    for iview=1:nbview
        if ~isempty(subdir)
            subdir=[subdir '-'];
        end
        subdir=[subdir dirlist{iview}];
    end  
    res_subdir=fullfile(fulldir,subdir);
end
ext=FileExt{1};
if ~exist(fulldir,'dir')
    msgbox_uvmat('ERROR',['directory ' fulldir ' needs to be created'])
    return
end
if ~exist(res_subdir,'dir')
    dircur=pwd;
    cd(fulldir)
    error=mkdir(subdir);
    cd(dircur)
end
filebasesub=fullfile(res_subdir,Series.RootFile{1});
filebase_merge=fullfile(res_subdir,'merged');%root name for the merged files

%projection object
if isfield(Series,'sethandles')
    if ishandle(Series.sethandles.set_object)
        Series.ProjObject=read_set_object(Series.sethandles);
        if ~isfield(Series.ProjObject,'Style')
            msgbox_uvmat('ERROR','Undefined projection object style')
            return
        end
        if ~isequal(Series.ProjObject.Style,'plane')
            msgbox_uvmat('ERROR','The projection object must be a plane')
            return
        end
    end
end

    %MAIN LOOP
for ifile=1:nbfield                
    stopstate=get(hseries.RUN,'BusyAction');
    if isequal(stopstate,'queue')% enable STOP command from the 'series' interface
         update_waitbar(hseries.waitbar,WaitbarPos,ifile/nbfield)
         Amerge=0;
         
         %----------LOOP ON VIEWS----------------------
        nbtime=0;
        for iview=1:nbview
            %name of the current file
            filename=name_generator(filebase{iview},num_i1{iview}(ifile),num_j1{iview}(ifile),Series.FileExt{iview},Series.NomType{iview},1,num_i2{iview}(ifile),num_j2{iview}(ifile),SubDir{iview});
            if ~exist(filename,'file')
                msgbox_uvmat('ERROR',['missing input file' filename])
                break
            end

            %reading the current file
            if testima
                if test_movie(iview)
                    Field{iview}.A=read(MovieObject{iview},num_i1{iview}(ifile));
                else
                    Field{iview}.A=read_image(filename,Series.NomType{iview},num_i1{iview}(ifile)); 
                end % TODO: introduce ListVarName
                npxy=size(Field{iview}.A);
                Field{iview}.AX=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
                Field{iview}.AY=[npxy(1)-0.5 0.5];
                Field{iview}.CoordType='px'; 
                Field{iview}.AName='image';
            else
                if testcivx
                    [Field{iview},VelTypeOut]=read_civxdata(filename,FieldName,VelType);
                else
                    [Field{iview},var_detect]=nc2struct(filename,SubField.ListVarName); %read the corresponding input data                
                    Field{iview}.VarAttribute=SubField.VarAttribute;
                end
                if isfield(Field{iview},'Time')
                    timeread(iview)=Field{iview}.Time;
                    nbtime=nbtime+1;
                end
            end
            % coord transform
            % z index
            if ~isempty(NbSlice_calib)
                Field{iview}.ZIndex=mod(num_i1{iview}(ifile)-1,NbSlice_calib{1})+1;
            end
            if ~isequal(transform,'')
                Field{iview}=feval(Series.CoordType,Field{iview},XmlData{iview});%transform to phys if requested
            end
            if testcivx
                    Field{iview}=calc_field(FieldName,Field{iview});
            end

            %projection on object (gridded plane)
            if isfield(Series,'ProjObject')
                Field{iview}=proj_field(Field{iview},Series.ProjObject);
            end
        end    
        
         %----------END LOOP ON VIEWS----------------------
         
        %merge the nbview fields
        MergeData=merge_field(Field);
        if isfield(MergeData,'Txt')
            msgbox_uvmat('ERROR',MergeData.Txt)
            return
        end
        
        % generating the name of the merged field
        mergename=name_generator(filebase_merge,num_i1{iview}(ifile),num_j1{iview}(ifile),Series.FileExt{iview},Series.NomType{iview},1,num_i2{iview}(ifile),num_j2{iview}(ifile));
        
        % time:
        time_i=0;%default
        if isempty(time)% time from ImaDoc prevails
            time_i=sum(timeread)/nbtime;
        else
            time_i=(time(iview,num_i1{iview}(ifile),num_j1{iview}(ifile))+time(iview,num_i2{iview}(ifile),num_j2{iview}(ifile)))/2;
        end
        
        % recording the merged field
        if testima    %in case of input images an image is produced   
            if isa(MergeData.A,'uint8')
                bitdepth=8;
            elseif isa(MergeData.A,'uint16')
                bitdepth=16;
            end
            imwrite(MergeData.A,mergename,'BitDepth',bitdepth); 
            %write xml calibration file
            siz=size(MergeData.A);
            npy=siz(1);
            npx=siz(2);
            if isfield(MergeData,'VarAttribute')&&isfield(MergeData.VarAttribute{1},'Coord_2')&&isfield(MergeData.VarAttribute{1},'Coord_1')
                Rangx=MergeData.VarAttribute{1}.Coord_2;
                Rangy=MergeData.VarAttribute{1}.Coord_1;
            elseif isfield(MergeData,'AX')&& isfield(MergeData,'AY')
                Rangx=[MergeData.AX(1) MergeData.AX(end)];
                Rangy=[MergeData.AY(1) MergeData.AY(end)];
            else
                Rangx=[0.5 npx-0.5];
                Rangy=[npy-0.5 0.5];%default
            end
            pxcmx=(npx-1)/(Rangx(2)-Rangx(1));
            pxcmy=(npy-1)/(Rangy(1)-Rangy(2));
            T_x=-pxcmx*Rangx(1)+0.5;
            T_y=-pxcmy*Rangy(2)+0.5;
            GeometryCal.focal=1;
            GeometryCal.R=[pxcmx,0,0;0,pxcmy,0;0,0,1];
            GeometryCal.Tx_Ty_Tz=[T_x T_y 1];
            ImaDoc.GeometryCalib=GeometryCal;
            t=struct2xml(ImaDoc);
            t=set(t,1,'name','ImaDoc');
            save(t,[filebase_merge '.xml'])     
            display([filebase_merge '.xml saved'])
        else
            MergeData.ListGlobalAttribute={'Project','InputFile_1','InputFile_end','nb_coord','nb_dim','dt','Time','civ'};        
            MergeData.nb_coord=2;
            MergeData.nb_dim=2;
            MergeData.dt=1;
            MergeData.Time=time_i;
            error=struct2nc(mergename,MergeData); %save result file
            if isempty(error)
                display(['output file ' mergename ' written'])
            else
                display(error)
            end
        end
    end
end

%--------------------------------------------------------------------------   
function MergeData=merge_field(Data)
% initiate Matlab  structure for physical field
if isempty(Data)||~iscell(Data)
    MergeData=[];
    return
end
MergeData=Data{1};%default
error=0;
nbview=length(Data);
if nbview==1
    return
end
for iview=1:nbview
    if ~isequal(MergeData.ListDimName,Data{iview}.ListDimName)
        error=1;
    end
    if ~isequal(MergeData.ListVarName,Data{iview}.ListVarName)
        error=1;
    end
%      if ~isequal(MergeData.VarDimIndex,Data{iview}.VarDimIndex)
%         error=1;
%      end
end
if error
    MergeData.Txt='ERROR: attempt at merging fields of incompatible type';
    return
end
%group the variables (fields of 'FieldData') in cells of variables with the same dimensions
%-----------------------------------------------------------------
[CellVarIndex,NbDim,VarTypeCell]=find_field_indices(Data{1});
%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
% CellVarIndex=cells of variable index arrays
ivar_new=0; % index of the current variable in the projected field
icoord=0;
for icell=1:length(CellVarIndex)
    if NbDim(icell)==1
        continue
    end
    VarIndex=CellVarIndex{icell};%  indices of the selected variables in the list FieldData.ListVarName
    VarType=VarTypeCell{icell};
    ivar_X=VarType.coord_x;
    ivar_Y=VarType.coord_y;
    ivar_FF=VarType.errorflag;
    if isempty(ivar_X)
        test_grid=1;%test for input data on regular grid (e.g. image)coordinates
    else
        if length(ivar_Y)~=1
                warndlg_uvmat('y coordinate missing in proj_field.m','ERROR')
                return
        end
        test_grid=0;
    end
%    DimIndices=Data{1}.VarDimIndex{VarIndex(1)};%indices of the dimensions of the first variable (common to all variables in the cell)
    %case of input fields with unstructured coordinates
    if ~test_grid
        for ivar=VarIndex
            VarName=MergeData.ListVarName{ivar};
            for iview=1:nbview
                eval(['MergeData.' VarName '=[MergeData.' VarName '; Data{iview}.' VarName ';'])
            end
        end
    %case of fields defined on a structured  grid 
    else  
%        DimValue=MergeData.DimValue(DimIndices);%set of dimension values
        testFF=0;
        for iview=2:nbview
%             if ~isequal(DimValue,Data{iview}.DimValue(DimIndices))
%                 MergeData.Txt='ERROR: attempt at merging structured fields with different sizes';
%                 return
%             end
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                if isfield(MergeData,'VarAttribute')
                    if length(MergeData.VarAttribute)>=ivar && isfield(MergeData.VarAttribute{ivar},'Role') && isequal(MergeData.VarAttribute{ivar}.Role,'errorflag')
                        testFF=1;
                    end
                end
                eval(['MergeData.' VarName '=MergeData.' VarName '+ Data{iview}.' VarName ';'])
            end
        end
        if testFF
            nbaver=nbview-MergeData.FF;
            indgood=find(nbaver>0);
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                eval(['MergeData.' VarName '(indgood)=double(MergeData.' VarName '(indgood))./nbaver(indgood);'])
            end 
        else
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                eval(['MergeData.' VarName '=double(MergeData.' VarName ')./nbview;'])
            end    
        end
    end
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



% %----------------------------------------------------------------------
% % --- display image movie and display time average
% %OBSOLETE: A SUPPRIMER
% %----------------------------------------------------------------------
% function movie_ima(handles,filecell,filecell_1,num1,num_a,field)
% 
% global hfig1 hfig2 hfig3 poscolbar
% global A val HIST
% 
% A=[];aviobj=[];
% % set(hfig1,'UserData','ima')% set the current field state to 'image'
% set(handles.zoom,'Value',1); %put zoom on
% nom_type=get(handles.file_input,'UserData');
% % field=get(handles.civ1,'UserData');
% % fields=field(1).fields;
% set(handles.speed,'Visible','On')%show slider to set movie speed
% set(handles.mo_speed_txt,'Visible','On')
% 
% if ~isempty(filecell_1)
%    file1=get(handles.file1_input,'UserData');
%    field1=file1.field;
%    scal_type1=field1.fields;
%    vel_type1=field1.vel_type;
%    filename_1=filecell_1(1);% first file name in the series
% else
%    filename_1=[];
% end 
% scal_type{1}=field(1).fields;
% vel_type{1}=field(1).vel_type;
% % display the first field
% [A,time,dt,rangx0,rangy0]=view_ima(handles,cell2mat(filecell(1)),filename_1,num1(1),num_a(1));
% 
% % calculate the histogram of the first image
% nxy=size(A);
% ndim=length(nxy);
% if ndim==2 % case of B/W images
%     nxy(3)=1;
% end
% C=reshape(A,nxy(1)*nxy(2),nxy(3));
% Amaxmax=double(max(max(max(A))));
% Aminmin=double(min(min(min(A))));
% if isa(C,'uint8')|isa(C,'uint16')
%     C=double(C);
%     dC=1;
% else
%     dC=(Amaxmax-Aminmin)/100;
% end
% val=[Aminmin:dC:Amaxmax];% define bins for histogram 
% HIST=hist(C,val);% initiate the global histogram 
% if ndim==2, HIST=HIST'; end; 
% 
% auto_scale=get(handles.auto_scale,'Value');
% min_input=str2num(get(handles.min_input,'String'));% select the minimum
% max_input=str2num(get(handles.scale_input,'String'));% select the max
% zoomstate=get(handles.zoom,'Value');
% 
% if isequal(get(handles.window_input,'String'),'avi'),
%     basename=get(handles.file_input,'String');
%     prompt = {'file name';'frames per second';'frame resolution ([nbpixels x y])';'axis position relative to the frame'};
%     dlg_title = 'select properties of the output avi movie';
%     num_lines= 1;
%     def     = {[basename '_out.avi'];'5';'[1024 768]';'[0.05 0.07 0.87 0.88]'};
%     answer = inputdlg(prompt,dlg_title,num_lines,def);
%     aviname=answer{1};
%     fps=str2num(answer{2});
%     if exist(aviname,'file')==2
%         delete(aviname);
%     end;
%     aviobj=avifile(aviname,'Compression','None','fps',fps);
%     
%     %display first view for tests
%     figure(2);
%     hh=get(gcf,'CurrentAxes');
%     if isempty(hh),
%         hfig1=axes;
%     else
%         hfig1=hh;
%     end;
%     if isequal(filecell_1,{}) 
%         filename_1=[];
%     else
%         filename_1=cell2mat(filecell_1(1));
%     end
%     poscolbar=[0.93 0.15 0.02 0.7];
%     view_ima(handles,cell2mat(filecell(1)),filename_1,num1(1),num_a(1));% show the first field
%     nbpix=eval(answer{3});
%     set(gcf,'Position',[1 1 nbpix])% resolution XVGA 
%     set(hfig1,'Position',eval(answer{4}));
%     
%     msgbox({'adjust figure 2 with its matlab edit menu ' ;...
%             'then type any keyboard key to get the avi movie as a copy of figure 2 display'})
%     pause;
%     hh=colorbar;
%     poscolbar=get(hh,'Position');
% end
% 
% %%%%%%%%%%%%%%%%
% %mask and usrdfct
% maskname=[]; %default
% if isequal(get(handles.mask_test,'Value'),1)
%     maskbase=get(handles.mask_test,'UserData');
% end
% % image or scalar processing programme set by user
% % if (get(handles.usr_fct,'Value')==1)
% %      usrfct=get(handles.usr_fct,'UserData');
% % else
% %      usrfct='';
% % end
% nburst=1; % nburst(1) =nbre of names in filename= nbre of bursts
% set(handles.text_display_1,'String',['image movie'])
% nbfield=length(filecell);
% if nbfield >1
% for ifile=2:nbfield
%     stopstate=get(handles.run0,'BusyAction');
%     if isequal(stopstate,'queue')% enable STOP command
%        pausetime=1.02-get(handles.speed,'Value');
%          pause(pausetime)
%          if isequal(get(handles.mask_test,'Value'),1)
%                 maskname=name_generator(maskbase,num1(ifile),1,'.png','png_series');
%             end
%             if isequal(AName{1},'image')
%                 A=read_image(cell2mat(filecell(ifile)),num1(ifile),maskname);% read the first image, num2 is the counter for avi files
%             else % read the first field from the netcdf file, imposing the pixel positions in the selected domain
%                  [A,time(ifile),dtr,rgx,rgy,vt_out,erread]=read_scalar(filecell{ifile},vel_type,scal_type,rangx0,rangy0,nxy,maskname);
%                 if erread==1;
%                     errordlg({['no spatial derivative in ' filecell{ifile}]; 'run patch first'}); return
%                 elseif erread==2;
%                     errordlg(['no field ' vel_type{1} ' in ' filecell{ifile}]); return
%                 elseif erread==3;
%                     errordlg(['scalar ' scal_type{1} ' not found in' filecell{ifile}]); return
%                 elseif erread==4;
%                     errordlg(['all points aligned in' filecell{ifile}]); return
%                 end
%             end
%           
%             % read the second image
%             if ~isempty(filecell_1)
%                 if isequal(scal_type{1},'image')
%                     A1=read_image(cell2mat(filecell_1(ifile)),num1(ifile),maskname);% read the second image, num2 is the counter for avi files
%                     Avalue_1=double(A1(indy,indx,:));
%                 else % read the second field from the netcdf file, imposing the pixel positions in the selected domain
%                     [Avalue_1,time1(ifile),dtr,rgx,rgy,vt_out,erread]=read_scalar(filecell_1{ifile},{vel_type1},{scal_type1},rangx0,rangy0,npxy,maskname,usrfct); 
%                     if erread==1;
%                         errordlg({['no spatial derivative in ' filecell_1{ifile}]; 'run patch first'}); return
%                     elseif erread==2;
%                         errordlg(['no field ' vel_type1 ' in ' filecell_1{ifile}]); return
%                     elseif erread==3;
%                         errordlg(['scalar ' scal_type1 ' not found in' filecell_1{ifile}]); return
%                     elseif erread==4;
%                         errordlg(['all points aligned in' filecell_1{ifile}]); return
%                     end
%                 end
%                 time(ifile)=(time(ifile)+time1(ifile))/2;
%                 Avalue=Avalue-Avalue_1;
%             end
%         set(handles.abs_time,'String',time);
%         set(handles.field_counter,'String',num2str(num1(ifile)));
%         set(handles.a_input,'String',num2stra(num_a(ifile),nom_type));
%         C=reshape(A,nxy(1)*nxy(2),nxy(3));% reshape in a vector
%         [val,HIST]=hist_update(val,HIST,C,dC);
%         [h,Amin,Amax]=plot_image(hfig1,rangx0,rangy0,1,scal_type{1},auto_scale,min_input,max_input,poscolbar,A);
%         set(handles.min_input,'String',num2str(Amin));% select the minimum
%         set(handles.scale_input,'String',num2str(Amax));% select the minimum
%          if ~isequal(aviobj,[]),
% %              mov=getframe(hfig1);
%               mov=getframe(gcf);
%              aviobj=addframe(aviobj,mov);end
%          if (get(handles.zoom,'Value') == get(handles.zoom,'Max')),zoom on,end
%          set(handles.field_counter,'String',num2str(num1(ifile)))
% %     end
% end
% end
% end
% aviobj=close(aviobj);
% 
% %plot global image histogram
%         HIST=HIST/(nbfield*nxy(1)*nxy(2));% normalized by the number of points
%         axes(hfig2) %in main window
%         if ndim==2
%             plot(val,HIST)
%         else
%             plot(val,HIST(:,1),'r',val,HIST(:,2),'g',val,HIST(:,3),'b')
%         end
%         residu=1-sum(HIST,1);
%         title(['histo, residu ' num2str(residu)])
%         grid on
%         axes(hfig3)
%         cla %clear the second histogram window
%         




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

%--------------------------------------------------------

 
%-----------------------------------------------------------
% find the times corresponding to the first and last indices of a series
%
function displ_time(handles,times)
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
        if siz(1)>=last_i & siz(2)>=last_j
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

%-------------------------------------------------------------------- 
% --- Executes on selection change in VelTypeMenu.
function VelTypeMenu_Callback(hObject, eventdata, handles)
% VelTypeList=get(handles.VelTypeMenu,'String');
% VelTypeIndex=get(handles.VelTypeMenu,'Value');
% VelTypeCell=get(handles.VelType,'String');
% VelTypeCell{1}=VelTypeList{VelTypeIndex};
% set(handles.VelType,'String',VelTypeCell)


%--------------------------------------------------------------------
% --- Executes on button press in GetObject.
function GetObject_Callback(hObject, eventdata, handles)
hseries=get(handles.GetObject,'parent');
SeriesData=get(hseries,'UserData');
value=get(handles.GetObject,'Value');
if value
     set(handles.GetObject,'BackgroundColor',[1 1 0])%put unactivated buttons to yellow
     DataInit.ParentButton=handles.GetObject;
     hset_object=findobj(allchild(0),'Name','set_object');%find the set_object interface handle
     if ishandle(hset_object)
         [SeriesData.hset_object,SeriesData.sethandles]=set_object(DataInit); %open the set_object interface
     else
         DataInit.TITLE='POINTS';%default option
         [SeriesData.hset_object,SeriesData.sethandles]=set_object(DataInit); %open the set_object interface
     end 
else
    set(handles.GetObject,'BackgroundColor',[0 1 0])%put activated buttons to green
    if isfield(SeriesData,'hset_object')&& ishandle(SeriesData.hset_object)
        close(SeriesData.hset_object)
    end
end
set(hseries,'UserData',SeriesData)

%--------------------------------------------------------------
function GetMask_Callback(hObject, eventdata, handles)
value=get(handles.GetMask,'Value');
if value
    errordlg('not implemented yet')
end
%--------------------------------------------------------------

%--------------------------------------------------------------------------
%'uv_ncbrowser': interactively calls the netcdf file browser 'get_field.m'
function ncbrowser_uvmat(hObject, eventdata)
     bla=get(gcbo,'String');
     ind=get(gcbo,'Value');
     filename=cell2mat(bla(ind));
      blank=find(filename==' ');
      filename=filename(1:blank-1);
     get_field(filename)



% --------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)

path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), errordlg('Please put the help file uvmat_doc.html in the  directory UVMAT/UVMAT_DOC')
else
web([helpfile '#series'])    
end






