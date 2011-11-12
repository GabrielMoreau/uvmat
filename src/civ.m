%'civ': function associated with the interface 'civ.fig' for PIV, spline interpolation and stereo PIV (patch)
%------------------------------------------------------------------------
%  provides an interface for the software CIVx
% function varargout = civ(varargin)
% provides an interface for the software CIVx
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
function varargout = civ(varargin)

% Last Modified by GUIDE v2.5 27-May-2011 17:55:50
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @civ_OpeningFcn, ...
    'gui_OutputFcn',  @civ_OutputFcn, ...
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

%------------------------------------------------------------------------
% --- Executes just before civ is made visible.
function civ_OpeningFcn(hObject, eventdata, handles, param)
%------------------------------------------------------------------------
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to civ (see VARARGIN)
global patch_newBin %=1 if new patch processing available
%filebase: root name
%nom_type: nomencalture used ('png_old','_i_j'...)
%list of field numbers to process
%subdir: subdirectory of the opened netcdf file
%ind_opening: operation number advised for beginning (1=civ1,2=fix1,3=patch1,4=civ2,5=fix2,6=patch2),
%ind_a_opening ind_b_opening chosen pair from the opened netcdf file
% Choose default command line output for civ
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
set(hObject,'WindowButtonDownFcn',{'mouse_alt_gui',handles}) % allows mouse action with right button (zoom for uicontrol display)
%default initial parameters
filebase=''; % root file name ('filebase'.civ)
ext=[];

%default input parameters:
num_i1=1; % set of field i numbers
num_i2=1; % set of field i numbers
num_j1=1; % set of field j numbers (fields a)
num_j2=1; % second set of field j numbers (fields b)
subdir='A'; % subdir for the netcdf result files
ind_opening=1; % proposed operation number (1=civ1,2=fix1,3=patch1,4=civ2,5=fix2,6=patch2)
%load the initial parameters if the interface is started from uvmat
if exist('param','var')&&isstruct(param)% the interface is opened from uvmat
    filebase=param.RootName;
    nom_type_read=param.NomType;
    num_i1=param.num1;
    if isnan(num_i1),num_i1=1;end
    num_i2=param.num2;
    if isnan(num_i2),num_i2=num_i1;end
    num_j1=param.num_a;
    if isnan(num_j1),num_j1=1;end
    num_j2=param.num_b;
    if isnan(num_j2),num_j2=num_j1;end
    subdir=param.SubDir;
    ind_opening=param.IndOpening;
    ext=param.ImaExt;
end
browse.num_i1=num_i1;
browse.num_i2=num_i2;
browse.num_j1=num_j1;
browse.num_j2=num_j2;
if ~isempty(ext) && (~isempty(imformats(ext(2:end)))||strcmpi(ext,'.avi'));%if an image file has been opened by uvmat
    set(handles.ImaExt,'String',ext)
    browse.ext_ima=ext;
    if exist('nom_type_read','var')
        browse.nom_type_ima=nom_type_read; % the image nomenclature is stored
    end
elseif isequal(ext,'.nc')
    if exist('nom_type_read','var')
        browse.nom_type_nc=nom_type_read;% the netcdf  nomenclature is stored
    end
end
set(handles.RootName,'String',filebase);
set(handles.ImaDoc,'String',ext)

%read names of the .exe file to adjust the interface according to available binaries
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
errormsg=[];%default error message
xmlfile='PARAM.xml';
if exist(xmlfile,'file')
    try
        t=xmltree(xmlfile);
        sparam=convert(t);
    catch
        errormsg={' Unable to read the file PARAM.xml defining the civx binaries:'; lasterr};
        return
    end
else
    errormsg=[xmlfile ' not found: path to civx binaries undefined'];
    return
end


if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg);
end
% patch_newBin='';
test_batch=0;%default: ,no batch mode available
if isfield(sparam,'BatchParam') && isfield(sparam.BatchParam,'BatchMode')
    test_batch=strcmp(sparam.BatchParam.BatchMode,'sge'); %sge is currently the only implemented batch mod
end
if test_batch==0
    set(handles.BATCH,'Enable','off')% put the BATCH button in grey (unactivated)
    set(handles.BATCH,'BackgroundColor',[0.831 0.816 0.784])% put the BATCH button in grey (unactivated)
end
if isfield(sparam.RunParam,'CivBin')
    if ~exist(sparam.RunParam.CivBin,'file')
        sparam.RunParam.CivBin=fullfile(path_UVMAT,sparam.RunParam.CivBin);
    end
else
    sparam.RunParam.CivBin='';
end
patch_newBin=exist(sparam.RunParam.CivBin,'file');
set(handles.subdir_civ1,'String',subdir)%default subdir on which uvmat was working
set(handles.subdir_civ2,'String',subdir)%default subdir on which uvmat was working

%initiate advised operations
if isequal(ind_opening,[])
    ind_opening=1; % default
end
% set default operation options
enable_civ1(handles,'off')
enable_civ2(handles,'off')
enable_pair1(handles,'on')
enable_fix1(handles,'off')
desable_patch1(handles)
desable_fix2(handles)
desable_patch2(handles)
set(handles.CIV1,'Value',0)
set(handles.FIX1,'Value',0)
set(handles.PATCH1,'Value',0)
set(handles.CIV2,'Value',0)
set(handles.FIX2,'Value',0)
set(handles.PATCH2,'Value',0)
set(handles.frame_subdirciv2,'BackgroundColor',[0.831 0.816 0.784])
if isequal(ind_opening,1)
    set(handles.CIV1,'Value',1)
    enable_civ1(handles,'on')
elseif isequal(ind_opening,2)
    set(handles.FIX1,'Value',1)
    enable_fix1(handles,'on')
elseif isequal(ind_opening,3)
    set(handles.PATCH1,'Value',1)
    enable_patch1(handles)
elseif isequal(ind_opening,4)
    set(handles.CIV2,'Value',1)
    enable_civ2(handles,'on')
elseif isequal(ind_opening,5)
    set(handles.FIX2,'Value',1)
    enable_fix2(handles)
    set(handles.frame_subdirciv2,'BackgroundColor',[1 1 0])
    set(handles.list_pair_civ2,'Enable','On')
    set(handles.list_pair_civ2,'Enable','On')
    enable_pair1(handles,'off')
elseif isequal(ind_opening,6)
    set(handles.PATCH2,'Value',1)
    enable_patch2(handles)
    set(handles.frame_subdirciv2,'BackgroundColor',[1 1 0])
    set(handles.list_pair_civ2,'Enable','On')
    enable_pair1(handles,'off')
end

% set the range of fields (1:1 by default) and selected pair
if isequal(num_i2,num_i1)
    num_ref_i=num_i1;
else
    num_ref_i=floor((num_i1+num_i2)/2);
    browse.incr_pair(1)=num_i2-num_i1;
    browse.incr_pair(2)=0;
end
if isequal(num_j1,num_j2)
    if isnan(num_j1)
        num_ref_j=1;
    else
        num_ref_j=num_j1;
    end
else
    num_ref_j=floor((num_j1+num_j2)/2);
    browse.incr_pair(2)=num_j2-num_j1;
end
set(handles.first_i,'String',num2str(num_ref_i));
set(handles.last_i,'String',num2str(num_ref_i));
set(handles.first_j,'String',num2str(num_ref_j));
set(handles.last_j,'String',num2str(num_ref_j));
set(handles.ref_i,'String',num2str(num_ref_i));
set(handles.ref_j,'String',num2str(num_ref_j));
set(handles.ref_i_civ2,'String',num2str(num_ref_i));
set(handles.ref_j_civ2,'String',num2str(num_ref_j));
set(handles.browse_root,'UserData',browse);
if exist('param','var') && isfield(param,'RootName') && ~isempty(param.RootName)%varargin the interface is opened from uvmat
    RootName_Callback(hObject, eventdata, handles);
end

% set(handles.waitbar_1,'Position',[0.946 0.877 0.03 0.001])
% set(handles.waitbar_patch1,'Position',[0.946 0.626 0.03 0.001])
% set(handles.waitbar_civ2,'Position',[0.946 0.406 0.03 0.001])
% set(handles.waitbar_patch2,'Position',[0.946 0.187 0.03 0.001])

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = civ_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;

%------------------------------------------------------------------------
% --- Executes on button press in browse_root.
function browse_root_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%get the input file properties
filebase=get(handles.RootName,'String');
oldfile=''; %default
if isempty(filebase)|| isequal(filebase,'')%loads the previously stored file name and set it as default in the file_input box
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        h=load (profil_perso);
        if isfield(h,'filebase')&& ischar(h.filebase)
            oldfile=h.filebase;
        end
        if isfield(h,'RootPath') && ischar(h.RootPath)
            oldfile=h.RootPath;
        end
    end
else
    oldfile=filebase;
end
ind_opening=1;%default
browse.incr_pair=[0 0]; %default
menu={'*.xml;*.civ;*.png;*.jpg;*.tif;*.avi;*.AVI;*.nc;', ' (*.xml,*.civ,*.png,*.jpg ,.tif, *.avi,*.nc)';
       '*.xml',  '.xml files '; ...
        '*.civ',  '.civ files '; ...
        '*.png','.png image files'; ...
        '*.jpg',' jpeg image files'; ...
        '*.tif','.tif image files'; ...
        '*.avi;*.AVI','.avi movie files'; ...
        '*.nc','.netcdf files'; ...
        '*.*',  'All Files (*.*)'};
[FileName, PathName, filtindex] = uigetfile( menu, 'Pick a file',oldfile);
fileinput=[PathName FileName];%complete file name
sizf=size(fileinput);
if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
[path,name,ext]=fileparts(fileinput);
testeditxml=0;
if isequal(ext,'.xml')
    testeditxml=1;
    t_browse=xmltree(fileinput);
    head_element=get(t_browse,1);
    if isfield(head_element,'name')&& isequal(head_element.name,'ImaDoc')
        testeditxml=0;
    end
end
if testeditxml==1 || isequal(ext,'.xls')
    heditxml=editxml({fileinput});
    set(heditxml,'Tag','browser')
    waitfor(heditxml,'Tag','idle')
    if ~ishandle(heditxml)
        return
    end
    attr=findobj(get(heditxml,'children'),'Tag','CurrentAttributes');
    set(handles.browse,'UserData',fileinput)% store for future opening with browser
    fileinput=get(attr,'UserData');
    if ~exist(fileinput,'file')
        return
    end
end
[RootPath,RootFile,str1,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fileinput);
filebase=fullfile(RootPath,RootFile);
num_i1=str2double(str1);
if isnan(num_i1),num_i1=1;end
num_i2=str2double(str2);
if isnan(num_i2),num_i2=num_i1;end
num_j1=stra2num(str_a);
if isnan(num_j1),num_j1=1;end
num_j2=stra2num(str_b);
if isnan(num_j2),num_j2=num_j1;end
if isequal(get(handles.compare,'Value'),1)
    browse=[];%initialisation
else
    browse=get(handles.browse_root,'UserData');
end
browse.num_i1=num_i1;
browse.num_i2=num_i2;
browse.num_j1=num_j1;
browse.num_j2=num_j2;
if length(ext)>1 && (~isempty(imformats(ext(2:end)))||strcmpi(ext,'.avi'));%if an image file has been opened by uvmat
    browse.nom_type_ima=nom_type;
    browse.ext_ima=ext;
    set(handles.ImaExt,'String',ext)
end
set(handles.ImaDoc,'String',ext);

%%%%% read the state of the selected netcdf file to advise default operation
if isequal(ext,'.nc')
    browse.nom_type_nc=nom_type;
    ind_opening=2;% propose 'fix' as the default option
    Data=nc2struct(fileinput,'ListGlobalAttribute','CivStage','absolut_time_T0','fix','patch','civ2','fix2');
    if ~isempty(Data.CivStage)%test for civ files
        ind_opening=Data.CivStage;
        set(handles.CivMode,'Value',3)
    end
    if ~isempty(Data.absolut_time_T0)%test for civx files
        set(handles.CivMode,'Value',1)
        if isfield(Data,'fix') && isequal(Data.fix,1)
            ind_opening=3;
        end
        if isequal(Data.patch,1)
            ind_opening=4;
        end
        if isequal(Data.civ2,1)
            ind_opening=5;
        end
        if  isequal(Data.fix2,1)
            ind_opening=6;
        end
        testciv=1; %TO SUPPRESS WITH NEW VERSION OF CIVX
    else
        ind_opening=3; %GUI used only for patch
        testciv=0;
    end
    set(handles.subdir_civ1,'String',subdir);%set the default subdir directories for installing the .nc results
    set(handles.subdir_civ2,'String',subdir);
    browse.testciv=testciv;
    browse.ind_opening=ind_opening;
end
set(handles.RootName,'String',filebase);
set(handles.ImaDoc,'String',ext);
if ~isempty(num_i1)
    ref_i=num_i1;
    if ~isempty(num_i2)
        ref_i=floor((ref_i+num_i2)/2);% reference image number corresponding to the file
        browse.incr_pair(1)=num_i2-num_i1;
        browse.incr_pair(2)=0;
    end
    set(handles.first_i,'String',num2str(ref_i));
    set(handles.last_i,'String',num2str(ref_i));
    set(handles.ref_i,'String',num2str(ref_i));
    set(handles.ref_i_civ2,'String',num2str(ref_i))
end
if isempty(num_j1)
    set(handles.ref_j,'String','1');
    set(handles.ref_j_civ2,'String','1');
else
    ref_j=num_j1;
    if ~isempty(num_j2)
        ref_j=floor((num_j1+num_j2)/2);
        browse.incr_pair(2)=num_j2-num_j1;
    end
    set(handles.first_j,'String',num2str(ref_j));
    set(handles.last_j,'String',num2str(ref_j));
    set(handles.ref_j,'String',num2str(ref_j));
    set(handles.ref_j_civ2,'String',num2str(ref_j));
end

% set default operation options
enable_civ1(handles,'off')
enable_civ2(handles,'off')
enable_pair1(handles,'on')
enable_fix1(handles,'off')
desable_patch1(handles)
desable_fix2(handles)
desable_patch2(handles)
set(handles.CIV1,'Value',0)
set(handles.FIX1,'Value',0)
set(handles.PATCH1,'Value',0)
set(handles.CIV2,'Value',0)
set(handles.FIX2,'Value',0)
set(handles.PATCH2,'Value',0)
set(handles.frame_subdirciv2,'BackgroundColor',[0.831 0.816 0.784])
if isequal(ind_opening,1)
    set(handles.CIV1,'Value',1)
    enable_civ1(handles,'on')
elseif isequal(ind_opening,2)
    set(handles.FIX1,'Value',1)
    enable_fix1(handles,'on')
elseif isequal(ind_opening,3)
    set(handles.PATCH1,'Value',1)
    enable_patch1(handles)
elseif isequal(ind_opening,4)
    set(handles.CIV2,'Value',1)
    enable_civ2(handles,'on')
elseif isequal(ind_opening,5)
    enable_pair1(handles,'off')
    set(handles.FIX2,'Value',1)
    enable_fix2(handles)
    set(handles.frame_subdirciv2,'BackgroundColor',[1 1 0])
    set(handles.list_pair_civ2,'Enable','On')
    set(handles.list_pair_civ2,'Enable','On')
elseif isequal(ind_opening,6)
    enable_pair1(handles,'off')
    set(handles.PATCH2,'Value',1)
    enable_patch2(handles)
    set(handles.frame_subdirciv2,'BackgroundColor',[1 1 0])
    set(handles.list_pair_civ2,'Enable','On')
end
set(handles.browse_root,'UserData',browse);% store information from browser

RootName_Callback(hObject, eventdata, handles);

%------------------------------------------------------------------------
function ImaDoc_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
RootName_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- function activated when a new filebase (image series) is introduced
function RootName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.compare,'Visible','on')
ext_ima='';%default
nom_type_ima=[];%default
field_count=1;%default
nom_type_nc=[];
time=[];
TimeUnit='frame'; %default
CoordUnit='px';%default
pxcmx_search=[];%default
pxcmy_search=[];%default
filebase=get(handles.RootName,'String');
ext_imadoc=get(handles.ImaDoc,'String');
browse=get(handles.browse_root,'UserData');%default
if isfield(browse,'nom_type_ima')
    nom_type_ima=browse.nom_type_ima;% get an image nomenclature type already determined by an input image name
end 
if isfield(browse,'ext_ima')
    ext_ima=browse.ext_ima;
end
if isfield(browse,'nom_type_nc')
    nom_type_nc=browse.nom_type_nc;% get an image nomenclature type already determined by an input image name
end
if isfield(browse,'num_i1')
    field_count=browse.num_i1;% get an image index type already determined by an input file
end
set(handles.civ,'UserData',[]); %refresh list of previous civ files (for STATUS)

%default first_i and j and increments
first_i=str2double(get(handles.first_i,'String'));%value possibly set by uvmat_Opening
if isnan(first_i)|| first_i < 1
    first_i=1; %default first_i
end
last_i=str2double(get(handles.last_i,'String'));
if isnan(last_i)|| last_i < first_i
    last_i=first_i;  %default last_i
end
first_j=str2double(get(handles.first_j,'String'));
if isnan(first_j)|| first_j < 1
    first_j=1; %default first_j
end
last_j=str2double(get(handles.last_j,'String'));
if isnan(last_j)|| last_j < first_j
    last_j=first_j; %default last_j
end
incr_i=str2double(get(handles.incr_i,'String'));
if isnan(incr_i) || incr_i < 1;
    set(handles.incr_i,'String','1') %default incr_i
end
incr_j=str2double(get(handles.incr_j,'String'));
if isnan(incr_j) || incr_j < 1;
    set(handles.incr_j,'String','1') %default incr_j
end
dt=[];%default
testmode=0;%default
nbfield=[]; %default
nburst=[];%default
pxcmx=1;
pxcmy=1;

%look for an image documentation file
if ~strcmp(ext_imadoc,'.xml') && ~strcmp(ext_imadoc,'.civ')&& ~strcmpi(ext_imadoc,'.avi')
    if exist([filebase '.xml'],'file')
        ext_imadoc='.xml';
    elseif exist([filebase '.civxml'],'file')
        ext_imadoc='.civxml';
    elseif exist([filebase '.civ'],'file')
        ext_imadoc='.civ';
    elseif exist([filebase '.avi'],'file')
        ext_imadoc='.avi';
    elseif exist([filebase '.AVI'],'file')
        ext_imadoc='.AVI';
    end
    set(handles.ImaDoc,'String',ext_imadoc)
end

%%%%%%%%   read image documentation file  %%%%%%%%%%%%%%%%%%%%%%%%%%%
mode=''; %default
set(handles.ImaDoc,'BackgroundColor',[1 1 0])
drawnow
if isequal(ext_imadoc,'.civxml') || isequal(ext_imadoc,'.xml')|| isequal(ext_imadoc,'.civ')
    set(handles.ref_i,'Visible','On')%use a reference index
    set(handles.ref_j,'Visible','On')
elseif isequal(ext_imadoc,'.avi') || isequal(ext_imadoc,'.AVI')
    set(handles.ref_j,'Visible','Off')
else
    set(handles.ref_i,'Visible','Off')
    set(handles.ref_j,'Visible','Off')
end
testima_xml=0;
if isequal(ext_imadoc,'.civxml')%TO ABANDON
    [nbfield,nbfield2,time]=read_civxml([filebase '.civxml']);
    mode='pair j1-j2';
    if isempty(nom_type_ima)% dtermine types by default if not already selected by browser or uvmat
        nom_type_ima='_i_j';
    end
elseif isequal(ext_imadoc,'.xml')
    [XmlData,warntext]=imadoc2struct([filebase '.xml']);
    ext_ima_read=[];
    nom_type_read=[];
    if isfield(XmlData,'Heading')&&isfield(XmlData.Heading','ImageName')&&ischar(XmlData.Heading.ImageName)% get image nom type and extension from the xml file
        [PP,FF,fc,str2,str_a,str_b,ext_ima_read,nom_type_read]=name2display(XmlData.Heading.ImageName);
        fullname=fullfile(fileparts(filebase),XmlData.Heading.ImageName); %full name (including path) of the first image defined by the xmle file,
        if ~exist(fullname,'file')
            msgbox_uvmat('WARNING',['FirstImage ' fullname ' defined in the xml file does not exist'])
        end
    end
    if isfield(XmlData,'Time')
        time=XmlData.Time;
        nbfield=size(time,1);
        nbfield2=size(time,2);
        %transform .Time to a column vector if it is a line vector thenomenclature uses a single index: correct possible bug in xml
        if isequal(nbfield,1) && ~isequal(nbfield2,1)% .Time is a line vector
            if numel(nom_type_read)>=2 && isempty(regexp(nom_type_read(2:end),'\D'))
                time=time';
                nbfield=nbfield2;
                nbfield2=1;
            end
        end
    end
    if isfield(XmlData,'TimeUnit')
        TimeUnit=XmlData.TimeUnit;
    end
    if isfield(XmlData,'Npx')
        npx=XmlData.Npx;
        npy=XmlData.Npy;
    end
    pxcmx_search=1;
    pxcmy_search=1;
    if isfield(XmlData,'GeometryCalib')
        tsai=XmlData.GeometryCalib;
        if isfield(tsai,'f') && isfield(tsai,'Tz') && isfield(tsai,'dpx') && isfield(tsai,'dpy')&& isfield(tsai,'R')
            rot2D=tsai.R(1:2,[1,2]);
            pxcmx_search=tsai.f * sqrt(det(rot2D))/(tsai.Tz*tsai.dpx);
            pxcmy_search=tsai.f * sqrt(det(rot2D))/(tsai.Tz*tsai.dpy);
        end
        if isfield(tsai,'CoordUnit')
            CoordUnit=tsai.CoordUnit;
        end
    end
elseif strcmp(ext_imadoc,'.civ')% case of .civ image documentation file
    [error,time,TimeUnit,mode,npx,npy]=read_imatext([filebase '.civ']);
    if error==2, msgbox_uvmat('WARNING',['no file ' filebase '.civ']);
    elseif error==1, msgbox_uvmat('WARNING','inconsistent number of fields in the .civ file');
    end
    nom_type_ima='001a';
elseif strcmpi(ext_imadoc,'.avi')
    nom_type_ima='*';
    ext_ima=ext_imadoc;
    set(handles.mode,'Value',1);
    set(handles.mode,'String',{'series(Di)'})
    dt=0.04;%default
    if exist([filebase ext_imadoc],'file')==2
        info=aviinfo([filebase ext_imadoc]);%read infos on the avi movie
        dt=1/info.FramesPerSecond;%time interval between successive frames
        nbfield=info.NumFrames;%number of frames
    end
    time=(dt*(0:nbfield-1))';%list of image times
end
if isempty(time)
    set(handles.ImaDoc,'String',''); %xml file not used for timing
end
set(handles.ImaDoc,'BackgroundColor',[1 1 1])

%get the imabe nomenclature type if not defined by the input file nor by the xml file
dirima=[];%default
if isempty(nom_type_ima)
    %look for double image series '_i_j'
    dirima=dir([filebase '_' num2str(first_i) '_' num2str(first_j) '.*']);
    if isempty(dirima)
        % look for images series  with sub marker '_'
        dirima=dir([filebase '_*' num2str(first_i) '.*']);
        if isempty(dirima)
            % look for other images series
            dirima=dir([filebase '*' num2str(first_i) '.*']);
            if isempty(dirima)
                % look for other images series witth letter appendix
                appendix=char(96+first_j);
                dirima=dir([filebase '*' num2str(first_i) appendix '.*']);
            end
        end
    end
end
for ilist=1:numel(dirima)
    [pp,ff,fc,str2,str_a,str_b,ext_list,nom_type_list]=name2display(dirima(ilist).name);
    form=imformats(ext_list(2:end));
    if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
        ext_ima=ext_list;
        nom_type_ima=nom_type_list;
            break
    end
end
% no image documentation file found: look for a series of existing files,images by priority or .nc files
if isempty(nom_type_ima)
    ext_search=ext_imadoc;
    nom_type_search=nom_type_nc;
else
    ext_search=ext_ima;
    nom_type_search=nom_type_ima;
end
if isempty(time) && ~strcmp(nom_type_search,'none') && ~strcmp(nom_type_search,'') && ~strcmp(nom_type_search,'*')
    subdir=get(handles.subdir_civ1,'String');
    incr_pair=[0 0];%default
    if isfield(browse,'incr_pair')
        incr_pair=browse.incr_pair;
    end
    %     nbdetect=0;%test of detected images
    field_i=browse.num_i2;
    imagename=name_generator(filebase,field_i,1,ext_search,nom_type_search);
    imagename_plus='';
    idetect=1;
    while idetect %look for the maximum file number in the series
        imagename_plus=name_generator(filebase,field_i+1,1,ext_search,nom_type_search);
        idetect=(exist(imagename_plus,'file')==2)&& ~strcmp(imagename,imagename_plus);
        if idetect
            field_i=field_i+1;
        end
        %SEE CASE OF NETCDF FILES
        %             nbdetect=nbdetect+(exist(imagename,'file')==2);
    end
    nbfield=field_i;% last detected field number
    field_i=browse.num_i1;%look for the minimum file number in the series
    imagename_min='';
    idetect=1;
    while idetect==1
        imagename_min=name_generator(filebase,field_i-1,1,ext_search,nom_type_search);
        idetect=(exist(imagename_min,'file')==2)&& ~strcmp(imagename,imagename_min);
        if idetect
            field_i=field_i-1;
        end
    end
    first_i=max(field_i,1); 
    if numel(regexp(nom_type_search,'\D'))>=1%two indices i and j
        field_i=browse.num_i1;
        field_j=browse.num_j2;
        imagename=name_generator(filebase,field_i,field_j,ext_search,nom_type_search);
        imagename_plus='';
        jdetect=1;
        while jdetect==1 %look for the maximum file number in the series
            imagename_plus=name_generator(filebase,field_i,field_j+1,ext_search,nom_type_search);
            jdetect=(exist(imagename_plus,'file')==2)&& ~strcmp(imagename,imagename_plus);
            if jdetect
                field_j=field_j+1;
            end
            %SEE CASE OF NETCDF FILES
            %             nbdetect=nbdetect+(exist(imagename,'file')==2);
        end
        nbfield2=field_j;% last detected field number
     end
 
    %determine the set of times and possible intervals for CIV
    %   dt=(1/1000)*str2double(get(handles.dt,'String'));
    time=(0:nbfield-1)';% time=file index -1  by default
    if numel(regexp(nom_type_search,'\D'))>=1%two indices i and j
        [x,y]=meshgrid(0:nbfield2-1,0:nbfield-1);
        time=x+y;
    end
end

if exist('time','var')
    if size(time,1)+size(time,2)>=3 % if there are at least two time values to define dt
        nbfield=size(time,1);
        nbfield2=size(time,2);
        set(handles.RootName,'UserData',time); %store the set of times
        set(handles.dt_unit,'String',['dt in m' TimeUnit]);
        set(handles.dt_unit_civ2,'String',['dt in m' TimeUnit]);
        set(handles.TimeUnit,'String',TimeUnit);
        set(handles.nb_field,'String',num2str(nbfield));
        set(handles.nb_field2,'String',num2str(nbfield2));
    end
end
set(handles.CoordUnit,'String',CoordUnit)
set(handles.calcul_search,'UserData',[pxcmx_search pxcmy_search]);
% npxy=[npy npx];
set(handles.ImaExt,'String',ext_ima)
set(handles.first_i,'String',num2str(first_i));
set(handles.last_i,'String',num2str(last_i));%
set(handles.first_j,'String',num2str(first_j));
set(handles.last_j,'String',num2str(last_j));%
browse.nom_type_ima=nom_type_ima;
set(handles.browse_root,'UserData',browse)% store the nomenclature type

%%%%%%%%%%%  set the menus of image pairs and default selection for civ   %%%%%%%%%%%%%%%%%%%
test_ima_i=numel(nom_type_ima)>1 && isempty(regexp(nom_type_ima(2:end),'\D','once'));%images with single indexing
if test_ima_i || isequal(nom_type_nc,'_i1-i2')||~(exist('nbfield2','var')&&(nbfield2~=1))
    set(handles.mode,'Value',1)
    set(handles.mode,'String',{'series(Di)'})   
elseif (nbfield==1)% simple series in j
    set(handles.mode,'Value',1)
    set(handles.mode,'String',{'series(Dj)'})
else
    set(handles.mode,'String',{'pair j1-j2';'series(Dj)';'series(Di)'})%multiple choice
    if nbfield2 <= 10
        set(handles.mode,'Value',1)% advice 'pair j1-j2' for small burst
    end
end

%update the subdir
pathdir=fileparts(filebase);%path to the current xml file
listot=dir(pathdir);
idir=0;
listdir={''};%default
for ilist=1:length(listot)
    if listot(ilist).isdir
        name=listot(ilist).name;
        if ~isequal(name,'.') && ~isequal(name,'..')
            idir=idir+1;
            listdir{idir,1}=listot(ilist).name;
        end
    end
end
set(handles.list_subdir_civ1,'Value',1)
set(handles.list_subdir_civ2,'Value',1)
set(handles.list_subdir_civ1,'String',[{'browse...'};listdir])
set(handles.list_subdir_civ2,'String',[{'browse...'};listdir])
%check wether the current subdir exists:
subdir_civ1=get(handles.subdir_civ1,'String');
subdir_civ2=get(handles.subdir_civ2,'String');

mode_Callback(hObject, eventdata, handles)

%% desable status and RUN button
% set(handles.waitbar_1,'Position',[0.946 0.876 0.03 0.001])
% set(handles.waitbar_patch1,'Position',[0.946 0.439 0.03 0.001])
% set(handles.waitbar_civ2,'Position',[0.946 0.219 0.03 0.001])
% set(handles.waitbar_patch2,'Position',[0.946 0.0 0.03 0.001])
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])
set(handles.BATCH,'Enable','On')
set(handles.BATCH,'BackgroundColor',[1 0 0])
if isfield(handles,'status')
set(handles.status,'Value',0);%suppress status display
status_Callback(hObject, eventdata, handles)
end

%% store the root input filename for future opening
dir_perso=prefdir;
profil_perso=fullfile(prefdir,'uvmat_perso.mat');
RootPath=fileparts(filebase);
if exist(profil_perso,'file')
    save (profil_perso,'RootPath','-append'); %store the root name for future opening of uvmat
else
    txt=ver('MATLAB');
    Release=txt.Release;
    relnumb=str2double(Release(3:4));
    if relnumb >= 14
        save (profil_perso,'RootPath','-V6'); %store the root name for future opening of uvmat
    else
        save (profil_perso,'RootPath'); %store the root name for future opening of uvmat
    end
end

%------------------------------------------------------------------------
% --- Executes on button press in mode.
function mode_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
browse=get(handles.browse_root,'UserData');
compare_list=get(handles.compare,'String');
val=get(handles.compare,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')
    mode='displacement';
else
    mode_list=get(handles.mode,'String');
    if ischar(mode_list)
        mode_list={mode_list};
    end
    mode_value=get(handles.mode,'Value');
    mode=mode_list{mode_value};
end
displ_num=[];%default
ref_i=str2double(get(handles.ref_i,'String'));
% last_i=str2num(get(handles.last_i,'String'));
time=get(handles.RootName,'UserData'); %get the set of times
siztime=size(time);
nbfield=siztime(1);
nbfield2=siztime(2);
indchosen=1;  %%first pair selected by default
if isequal(mode,'pair j1-j2')%| isequal(mode,'st_pair j1-j2')
    dt=1;
    displ='';
    index=0;
    numlist_a=[];
    numlist_B=[];
    %get all the time intervals in bursts
    displ_dt=1;%default
    nbfield2=min(nbfield2,10);%limitate the number of pairs to 10x10
    for numod_a=1:nbfield2-1 %nbfield2 always >=2 for 'pair j1-j2' mode
        for numod_b=(numod_a+1):nbfield2
            index=index+1;
            numlist_a(index)=numod_a;
            numlist_b(index)=numod_b;
            if ~isempty(time)
                dt(numod_a,numod_b)=time(ref_i,numod_b)-time(ref_i,numod_a);%first time interval dt
                displ_dt(index)=dt(numod_a,numod_b);
            else
                displ_dt(index)=1;
            end
        end
    end
    [dtsort,indsort]=sort(displ_dt);
    if ~isempty(numlist_a)
        displ_num(1,:)=numlist_a(indsort);
        displ_num(2,:)=numlist_b(indsort);
    end
    displ_num(3,:)=0;
    displ_num(4,:)=0;
    set(handles.jtext,'Visible','Off')
    set(handles.first_j,'Visible','Off')
    set(handles.last_j,'Visible','Off')
    set(handles.incr_j,'Visible','Off')
    set(handles.nb_field2,'Visible','Off')
    set(handles.ref_j,'Visible','Off')
elseif isequal(mode,'series(Dj)') %| isequal(mode,'st_series(Dj)')
    for index=1:min(nbfield2-1,200)
        displ_num(1,index)=-floor(index/2);
        displ_num(2,index)=ceil(index/2);
        displ_num(3,index)=0;
        displ_num(4,index)=0;
    end
    set(handles.jtext,'Visible','On')
    set(handles.first_j,'Visible','On')
    set(handles.last_j,'Visible','On')
    set(handles.incr_j,'Visible','On')
    set(handles.nb_field2,'Visible','On')
    set(handles.ref_j,'Visible','On')
    if nbfield > 1
        set(handles.itext,'Visible','On')
        set(handles.first_i,'Visible','On')
        set(handles.last_i,'Visible','On')
        set(handles.incr_i,'Visible','On')
        set(handles.nb_field,'Visible','On')
        set(handles.ref_i,'Visible','On')
    else
        set(handles.itext,'Visible','Off')
        set(handles.first_i,'Visible','Off')
        set(handles.last_i,'Visible','Off')
        set(handles.incr_i,'Visible','Off')
        set(handles.nb_field,'Visible','Off')
        set(handles.ref_i,'Visible','Off')
    end
elseif isequal(mode,'series(Di)') %| isequal(mode,'st_series(Di)')
    for index=1:200%min(nbfield-1,200)
        displ_num(1,index)=0;
        displ_num(2,index)=0;
        displ_num(3,index)=-floor(index/2);
        displ_num(4,index)=ceil(index/2);
    end
    set(handles.itext,'Visible','On')
    set(handles.first_i,'Visible','On')
    set(handles.last_i,'Visible','On')
    set(handles.incr_i,'Visible','On')
    set(handles.nb_field,'Visible','On')
    set(handles.ref_i,'Visible','On')
    if nbfield2 > 1
        set(handles.jtext,'Visible','On')
        set(handles.first_j,'Visible','On')
        set(handles.last_j,'Visible','On')
        set(handles.incr_j,'Visible','On')
        set(handles.nb_field2,'Visible','On')
        set(handles.ref_j,'Visible','On')
    else
        set(handles.jtext,'Visible','Off')
        set(handles.first_j,'Visible','Off')
        set(handles.last_j,'Visible','Off')
        set(handles.incr_j,'Visible','Off')
        set(handles.nb_field2,'Visible','Off')
        set(handles.ref_j,'Visible','Off')
    end
elseif isequal(mode,'displacement')%the pairs have the same indices
    displ_num(1,1)=0;
    displ_num(2,1)=0;
    displ_num(3,1)=0;
    displ_num(4,1)=0;
    if nbfield > 1
        set(handles.itext,'Visible','On')
        set(handles.first_i,'Visible','On')
        set(handles.last_i,'Visible','On')
        set(handles.incr_i,'Visible','On')
        set(handles.nb_field,'Visible','On')
        set(handles.ref_i,'Visible','On')
    else
        set(handles.itext,'Visible','Off')
        set(handles.first_i,'Visible','Off')
        set(handles.last_i,'Visible','Off')
        set(handles.incr_i,'Visible','Off')
        set(handles.nb_field,'Visible','Off')
        set(handles.ref_i,'Visible','Off')
    end
    if nbfield2 > 1
        set(handles.jtext,'Visible','On')
        set(handles.first_j,'Visible','On')
        set(handles.last_j,'Visible','On')
        set(handles.incr_j,'Visible','On')
        set(handles.nb_field2,'Visible','On')
        set(handles.ref_j,'Visible','On')
    else
        set(handles.jtext,'Visible','Off')
        set(handles.first_j,'Visible','Off')
        set(handles.last_j,'Visible','Off')
        set(handles.incr_j,'Visible','Off')
        set(handles.nb_field2,'Visible','Off')
        set(handles.ref_j,'Visible','Off')
    end
end
set(handles.list_pair_civ1,'UserData',displ_num);
find_netcpair_civ1(hObject, eventdata, handles)
find_netcpair_civ2(hObject, eventdata, handles)

%------------------------------------------------------------------------
% determine the menu for civ1 pairs depending on existing netcdf file at the middle of
% the field series set by first_i, incr, last_i
function find_netcpair_civ1(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(gcf,'Pointer','watch')
%nomenclature types
filebase=get(handles.RootName,'String');
[filepath,Nme,ext_dir]=fileparts(filebase);
browse=get(handles.browse_root,'UserData');
compare_list=get(handles.compare,'String');
val=get(handles.compare,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')
    mode='displacement';
else
    mode_list=get(handles.mode,'String');
    mode_value=get(handles.mode,'Value');
    mode=mode_list{mode_value};
end

% nomenclature type of the .nc files
nom_type_ima=[];%default
if isfield(browse,'nom_type_ima')
    nom_type_ima=browse.nom_type_ima;
end

%determine nom_type_nc:
nom_type_nc=[];%default
if isfield(browse,'nom_type_nc')
    nom_type_nc=browse.nom_type_nc;
end
if isempty(nom_type_nc)
    [nom_type_nc]=nomtype2pair(nom_type_ima,isequal(mode,'series(Di)'),isequal(mode,'series(Dj)'));
end
browse.nom_type_nc=nom_type_nc;
set(handles.browse_root,'UserData',browse)

%reads .nc subdirectoy and image numbers from the interface
subdir_civ1=get(handles.subdir_civ1,'String');%subdirectory subdir_civ1 for the netcdf data
% first_i=str2num(get(handles.first_i,'String'));
% last_i=str2num(get(handles.last_i,'String'));
% incr=str2num(get(handles.incr_i,'String'));
% num1=first_i:incr:last_i;
% if isempty(num1)
%     set(handles.list_pair_civ1,'String',{''});
%     return
% end
ref_i=str2double(get(handles.ref_i,'String'));
if isequal(mode,'pair j1-j2')%|isequal(mode,'st_pair j1-j2')
    ref_j=0;
else
    ref_j=str2double(get(handles.ref_j,'String'));
end
time=get(handles.RootName,'UserData');%get the set of times
if isempty(time)
    time=[0 1];
end
%dt_unit=str2double(get(handles.dt,'String'));% used when there is no image documentation file
dt_unit=1000;%default
displ_num=get(handles.list_pair_civ1,'UserData');

%eliminate the first pairs inconsistent with the position
if isempty(displ_num)
    nbpair=0;
else
    nbpair=length(displ_num(1,:));%nbre of displayed pairs
    if  isequal(mode,'series(Di)')  %| isequal(mode,'st_series(Di)')
        nbpair=min(2*ref_i-1,nbpair);%limit the number of pairs with positive first index
    elseif  isequal(mode,'series(Dj)')% | isequal(mode,'st_series(Dj)')
        nbpair=min(2*ref_j-1,nbpair);%limit the number of pairs with positive first index
    end
end
nbpair=min(200,nbpair);%limit the number of displayed pairs to 200

%look for existing processed pairs involving the field at the middle of the series if civ1 will not
% be performed, while the result is needed for next steps.
displ_pair={''};
select=ones(size(1:nbpair));%default =1 for numbers of displayed pairs
testpair=0;
if get(handles.CIV1,'Value')==0 %
    if ~exist(fullfile(filepath,subdir_civ1,ext_dir),'dir')
        msgbox_uvmat('ERROR',['no civ1 file available: subdirectory ' subdir_civ1 ' does not exist']);
        set(handles.list_pair_civ1,'String',{});
        return
    end
    for ipair=1:nbpair
        filename=name_generator(filebase,ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair),'.nc',nom_type_nc,1,...
            ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair),subdir_civ1);
        select(ipair)=exist(filename,'file')==2;
    end
    if ~exist('select','var') || isequal(select,zeros(size(1:nbpair)))
        if isfield(browse,'incr_pair')
            num_i1=ref_i-floor(browse.incr_pair(1)/2);
            num_i2=ref_i+ceil(browse.incr_pair(1)/2);
            num_j1=ref_j-floor(browse.incr_pair(2)/2);
            num_j2=ref_j+ceil(browse.incr_pair(2)/2);
            filename=name_generator(filebase,num_i1,num_j1,'.nc',nom_type_nc,1,num_i2,num_j2,subdir_civ1);
            select(1)=exist(filename,'file')==2;
            testpair=1;
        else
            if  isequal(mode,'series(Dj)')% | isequal(mode,'st_series(Dj)')
                msgbox_uvmat('ERROR',['no civ1 file available for the selected reference index j=' num2str(ref_j) ' and subdirectory ' subdir_civ1]);
            else
                msgbox_uvmat('ERROR',['no civ1 file available for the selected reference index i=' num2str(ref_i) ' and subdirectory ' subdir_civ1]);
            end
            set(handles.list_pair_civ1,'String',{''});
            %COMPLETER CAS STEREO
            return
        end
    end
end
if isequal(mode,'series(Di)') %| isequal(mode,'st_series(Di)')
    if testpair
        displ_pair{1}=['Di= ' num2str(-floor(browse.incr_pair(1)/2)) '|' num2str(ceil(browse.incr_pair(1)/2))];
        %     elseif ~isequal(get(handles.root_txt,'String'),'dt(ms)=')
        %        for ipair=1:nbpair
        %           if select(ipair)
        %               if size(time,1)>=ref_i+displ_num(4,ipair) && size(time,2)>=ref_j+displ_num(2,ipair)
        %               dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
        %               displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt*1000)];
        %               end
        %           else
        %              displ_pair{ipair}='...'; %pair not displayed in the menu
        %           end
        %        end
    else
        for ipair=1:nbpair
            if select(ipair)
                if size(time,1)>=ref_i+displ_num(4,ipair) && size(time,2)>=ref_j+displ_num(2,ipair)
                    dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
                    displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt*1000)];
                else
                    displ_pair{ipair}='...'; %pair not displayed in the menu
                end
            end
        end
    end
elseif isequal(mode,'series(Dj)')%|isequal(mode,'st_series(Dj)')% series on the j index
    if testpair
        displ_pair{1}=['Dj= ' num2str(-floor(browse.incr_pair(1)/2)) '|' num2str(ceil(browse.incr_pair(1)/2))];
    else
        for ipair=1:nbpair
            if select(ipair)
                if size(time,1)>=ref_i+displ_num(4,ipair) && size(time,2)>=ref_j+displ_num(2,ipair)
                    dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
                    displ_pair{ipair}=['Dj= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt*1000)];
                end
            elseif testpair
                displ_pair{1}=['Dj= ' num2str(-floor(browse.incr_pair(2)/2)) '|' num2str(ceil(browse.incr_pair(2)/2))];
            else
                displ_pair{ipair}='...'; %pair not displayed in the menu
            end
        end
    end
elseif isequal(mode,'pair j1-j2')%|isequal(mode,'st_pair j1-j2')%case of pairs
    for ipair=1:nbpair
        if select(ipair)
            dt=time(ref_i+displ_num(4,ipair),displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),displ_num(1,ipair));%time interval dt
            displ_pair{ipair}=['j= ' num2stra(displ_num(1,ipair),nom_type_ima) '-' num2stra(displ_num(2,ipair),nom_type_ima) ...
                ' :dt= ' num2str(dt*1000)];
        else
            displ_pair{ipair}='...'; %pair not displayed in the menu
        end
    end
elseif isequal(mode,'displacement')
    displ_pair={'Di=Dj=0'};
end
set(handles.list_pair_civ1,'String',displ_pair');
ichoice=find(select,1);
if (isempty(ichoice) || ichoice < 1); ichoice=1; end;
initial=get(handles.list_pair_civ1,'Value');%initial choice of pair
if initial>nbpair
    set(handles.list_pair_civ1,'Value',ichoice);% first valid pair proposed by default in the menu
end
if numel(select)>=initial && ~isequal(select(initial),1)
    set(handles.list_pair_civ1,'Value',ichoice);% first valid pair proposed by default in the menu
end

%set(handles.list_pair_civ2,'String',displ_pair');
initial=get(handles.list_pair_civ2,'Value');
if initial>length(displ_pair')%|~isequal(select(initial),1)
    if ichoice <= length(displ_pair')
        set(handles.list_pair_civ2,'Value',ichoice);% same pair proposed by default for civ2
    else
        set(handles.list_pair_civ2,'Value',1);% same pair proposed by default for civ2
    end
end
set(handles.list_pair_civ2,'String',displ_pair');
set(gcf,'Pointer','arrow')

%------------------------------------------------------------------------
% determine the menu for civ2 pairs depending on the existing netcdf file at the
%middle of the series set by first_i, incr, last_i
function find_netcpair_civ2(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(gcf,'Pointer','watch')
%nomenclature types
filebase=get(handles.RootName,'String');
[filepath,Nme,ext_dir]=fileparts(filebase);
browse=get(handles.browse_root,'UserData');
compare_list=get(handles.compare,'String');
val=get(handles.compare,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')
    mode='displacement';
else
    mode_list=get(handles.mode,'String')
    if isempty(mode_list)
        msgbox_uvmat('ERROR','please enter an input image or netcdf file')
        return
    end
    mode_value=get(handles.mode,'Value')
    mode=mode_list{mode_value};
end

% nomenclature type of the .nc files
nom_type_ima='ima_num';%default
if isfield(browse,'nom_type_ima')
    nom_type_ima=browse.nom_type_ima;
end
nom_type_nc='_i1-i2';%default
if isfield(browse,'nom_type_nc')
    nom_type_nc=browse.nom_type_nc;
end
if isequal(nom_type_ima,'png_old') || isequal(nom_type_ima,'netc_old')|| isequal(nom_type_ima,'raw_SMD')|| isequal(nom_type_nc,'netc_old')
    nom_type_nc='netc_old';%nom_type for the netcdf files
elseif isequal(nom_type_ima,'none')||isequal(nom_type_nc,'none')
    nom_type_nc='none';
elseif isequal(nom_type_ima,'avi')||isequal(nom_type_ima,'_i')||isequal(nom_type_ima,'ima_num')||isequal(nom_type_nc,'_i1-i2')
    nom_type_nc='_i1-i2';
else
    if  isequal(mode,'series(Di)')%|isequal(mode,'st_series(Di)')
        nom_type_nc='_i1-i2_j'; % PIV in volume
    else
        nom_type_nc='_i_j1-j2';
    end
end
browse.nom_type_nc=nom_type_nc;
set(handles.browse_root,'UserData',browse)

%reads .nc subdirectory and image numbers from the interface
subdir_civ1=get(handles.subdir_civ1,'String');%subdirectory subdir_civ1 for the netcdf data
subdir_civ2=get(handles.subdir_civ2,'String');%subdirectory subdir_civ2 for the netcdf data
% first_i=str2num(get(handles.first_i,'String'));
% last_i=str2num(get(handles.last_i,'String'));
% incr=str2num(get(handles.incr_i,'String'));
% num1=first_i:incr:last_i;
% if isempty(num1)
%     set(handles.list_pair_civ2,'Value',1);
%     set(handles.list_pair_civ2,'String',{''});
%     return
% end
ref_i=str2double(get(handles.ref_i_civ2,'String'));
if isequal(mode,'pair j1-j2')%|isequal(mode,'st_pair j1-j2')
    ref_j=0;
else
    ref_j=str2double(get(handles.ref_j_civ2,'String'));
end
time=get(handles.RootName,'UserData'); %get the set of times
if isempty(time)
    time=[0 1];%default
end
%dt_unit=str2num(get(handles.dt,'String'));% used when there is no image documentation file
%dt_unit=1000;
displ_num=get(handles.list_pair_civ1,'UserData');


%eliminate the first pairs inconsistent with the position
if isempty(displ_num)
    nbpair=0;
else
    nbpair=length(displ_num(1,:));%nbre of displayed pairs
    if  isequal(mode,'series(Di)')% | isequal(mode,'st_series(Di)')
        nbpair=min(2*ref_i-1,nbpair);%limit the number of pairs with positive first index
    elseif  isequal(mode,'series(Dj)')% | isequal(mode,'st_series(Dj)')
        nbpair=min(2*ref_j-1,nbpair);%limit the number of pairs with positive first index
    end
end
nbpair=min(200,nbpair);%limit the number of displayed pairs to 200

%look for existing processed pairs involving the field at the middle of the series if civ1 will not
% be performed, while the result is needed for next steps.
displ_pair={''}; %default
select=ones(size(1:nbpair));%default =1 for numbers of displayed pairs
if get(handles.CIV2,'Value')==0 & get(handles.CIV1,'Value')==0 & get(handles.FIX1,'Value')==0 & get(handles.PATCH1,'Value')==0%&...
    if ~exist(fullfile(filepath,subdir_civ2,ext_dir),'dir')
        errordlg(['no civ2 file available: subdirectory ' subdir_civ2 ' does not exist'])
        set(handles.list_pair_civ2,'Value',1);
        set(handles.list_pair_civ2,'String',{''});
        return
    end
    for ipair=1:nbpair
        filename=name_generator(filebase,ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair),'.nc',nom_type_nc,1,...
            ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair),subdir_civ1);
        select(ipair)=exist(filename,'file')==2;
    end
    if  isequal(select,zeros(size(1:nbpair)))
        if isfield(browse,'incr_pair')
            num_i1=ref_i-floor(browse.incr_pair(1)/2);
            num_i2=ref_i+floor((browse.incr_pair(1)+1)/2);
            num_j1=ref_j-floor(browse.incr_pair(2)/2);
            num_j2=ref_j+floor((browse.incr_pair(2)+1)/2);
            filename=name_generator(filebase,num_i1,num_j1,'.nc',nom_type_nc,1,num_i2,num_j2,subdir_civ2);
            select(1)=exist(filename,'file')==2;
        else
            if  isequal(mode,'series(Dj)')% | isequal(mode,'st_series(Dj)')
                errordlg(['no civ2 file available for the selected reference index j=' num2str(ref_j) ' and subdirectory ' subdir_civ2])
            else
                errordlg(['no civ2 file available for the selected reference index i=' num2str(ref_i) ' and subdirectory ' subdir_civ2])
            end
            set(handles.list_pair_civ2,'Value',1);
            set(handles.list_pair_civ2,'String',{''});
            return
        end
    end
end
if isequal(mode,'series(Di)') % | isequal(mode,'st_series(Di)')
    for ipair=1:nbpair
        if select(ipair)
            if size(time,1)>=ref_i+displ_num(4,ipair) && size(time,2)>=ref_j+displ_num(2,ipair)
                dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
                displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt*1000)];
            end
        else
            displ_pair{ipair}='...'; %pair not displayed in the menu
        end
    end
elseif isequal(mode,'series(Dj)') %| isequal(mode,'st_series(Dj)') % series on the j index
    for ipair=1:nbpair
        if select(ipair)
            if size(time,1)>=ref_i+displ_num(4,ipair) && size(time,2)>=ref_j+displ_num(2,ipair)
                dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
                displ_pair{ipair}=['Dj= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt*1000)];
            end
        else
            displ_pair{ipair}='...'; %pair not displayed in the menu
        end
    end
elseif isequal(mode,'pair j1-j2')% | isequal(mode,'st_pair j1-j2') %case of pairs
    for ipair=1:nbpair
        if select(ipair)
            dt=time(ref_i+displ_num(4,ipair),displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),displ_num(1,ipair));%time interval dt
            displ_pair{ipair}=['j= ' num2stra(displ_num(1,ipair),nom_type_ima) '-' num2stra(displ_num(2,ipair),nom_type_ima) ...
                ' :dt= ' num2str(dt*1000)];
        else
            displ_pair{ipair}='...'; %pair not displayed in the menu
        end
    end
elseif isequal(mode,'displacement')
    displ_pair={'Di=Dj=0'};
end
val=get(handles.list_pair_civ2,'Value');
ichoice=find(select,1);
if (isempty(ichoice) || ichoice < 1); ichoice=1; end;
if get(handles.CIV2,'Value')==0 && get(handles.CIV1,'Value')==0 && get(handles.FIX1,'Value')==0 && get(handles.PATCH1,'Value')==0
    val=ichoice;% first valid pair proposed by default in the menu
end
if val>length(displ_pair')
    set(handles.list_pair_civ2,'Value',1);% first valid pair proposed by default in the menu
else
    set(handles.list_pair_civ2,'Value',val);
end
set(handles.list_pair_civ2,'String',displ_pair');
set(gcf,'Pointer','arrow')




%------------------------------------------------------------------------
% --- Executes on selection change in list_pair_civ1.
function list_pair_civ1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%reproduce by default the chosen pair in the civ2 menu
list_pair=get(handles.list_pair_civ1,'String');%get the menu of image pairs
index_pair=get(handles.list_pair_civ1,'Value');
displ_num=get(handles.list_pair_civ1,'UserData');
% num_a=displ_num(1,index_pair);
% num_b=displ_num(2,index_pair);
list_pair2=get(handles.list_pair_civ2,'String');%get the menu of image pairs
if index_pair<=length(list_pair2)
    set(handles.list_pair_civ2,'Value',index_pair);
end

%update first_i and last_i according to the chosen image pairs
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if isequal(mode,'series(Di)')
    first_i=str2double(get(handles.first_i,'String'));
    last_i=str2double(get(handles.last_i,'String'));
    incr_i=str2double(get(handles.incr_i,'String'));
    num1=first_i:incr_i:last_i;
    lastfield=str2double(get(handles.nb_field,'String'));
    if ~isnan(lastfield)
        test_find=(num1-floor(index_pair/2)*ones(size(num1))>0)& ...
            (num1+ceil(index_pair/2)*ones(size(num1))<=lastfield);
        num1=num1(test_find);
    end
    set(handles.first_i,'String',num2str(num1(1)));
    set(handles.last_i,'String',num2str(num1(end)));
elseif isequal(mode,'series(Dj)')
    first_j=str2double(get(handles.first_j,'String'));
    last_j=str2double(get(handles.last_j,'String'));
    incr_j=str2double(get(handles.incr_j,'String'));
    num_j=first_j:incr_j:last_j;
    lastfield2=str2double(get(handles.nb_field2,'String'));
    if ~isnan(lastfield2)
        test_find=(num_j-floor(index_pair/2)*ones(size(num_j))>0)& ...
            (num_j+ceil(index_pair/2)*ones(size(num_j))<=lastfield2);
        num1=num_j(test_find);
    end
    set(handles.first_j,'String',num2str(num1(1)));
    set(handles.last_j,'String',num2str(num1(end)));
end

%------------------------------------------------------------------------
% --- Executes on selection change in list_pair_civ2.
function list_pair_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index_pair=get(handles.list_pair_civ2,'Value');%get the selected position index in the menu

%update first_i and last_i according to the chosen image pairs
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if isequal(mode,'series(Di)')
    first_i=str2double(get(handles.first_i,'String'));
    last_i=str2double(get(handles.last_i,'String'));
    incr_i=str2double(get(handles.incr_i,'String'));
    num1=first_i:incr_i:last_i;
    lastfield=str2double(get(handles.nb_field,'String'));
    if ~isnan(lastfield)
        test_find=(num1-floor(index_pair/2)*ones(size(num1))>0)& ...
            (num1+ceil(index_pair/2)*ones(size(num1))<=lastfield);
        num1=num1(test_find);
    end
    set(handles.first_i,'String',num2str(num1(1)));
    set(handles.last_i,'String',num2str(num1(end)));
elseif isequal(mode,'series(Dj)')
    first_j=str2double(get(handles.first_j,'String'));
    last_j=str2double(get(handles.last_j,'String'));
    incr_j=str2double(get(handles.incr_j,'String'));
    num_j=first_j:incr_j:last_j;
    lastfield2=str2double(get(handles.nb_field2,'String'));
    if ~isnan(lastfield2)
        test_find=(num_j-floor(index_pair/2)*ones(size(num_j))>0)& ...
            (num_j+ceil(index_pair/2)*ones(size(num_j))<=lastfield2);
        num1=num_j(test_find);
    end
    set(handles.first_j,'String',num2str(num1(1)));
    set(handles.last_j,'String',num2str(num1(end)));
end

%------------------------------------------------------------------------
% --- Executes on button press in RUN: processing on local computer
function RUN_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RUN, 'Enable','Off')
set(handles.RUN,'BackgroundColor',[0.831 0.816 0.784])
batch=0;
errormsg=launch_jobs(hObject, eventdata, handles,batch);
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])

% start status callback to visualise results
if ~isempty(errormsg)
    display(errormsg)
    msgbox_uvmat('ERROR',errormsg)
elseif  isfield(handles,'status') %&& ~isequal(get(handles.CivMode,'Value'),3)
    set(handles.status,'Value',1);%suppress status display
    status_Callback(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% --- Executes on button press in BATCH: remote processing
function BATCH_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
set(handles.BATCH, 'Enable','Off')
set(handles.BATCH,'BackgroundColor',[0.831 0.816 0.784])
batch=1;
errormsg=launch_jobs(hObject, eventdata, handles, batch);
set(handles.BATCH, 'Enable','On')
set(handles.BATCH,'BackgroundColor',[1 0 0])

% start status callback to visualise results
if ~isempty(errormsg)
    display(errormsg)
    msgbox_uvmat('ERROR',errormsg)
elseif isfield(handles,'status')
    set(handles.status,'Value',1);%suppress status display
    status_Callback(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% --- Lauch command called by RUN and BATCH: remote processing
function errormsg=launch_jobs(hObject, eventdata, handles, batch)
%-----------------------------------------------------------------------
errormsg='';%default
%% check the selected list of operations:
operations={'CIV1','FIX1','PATCH1','CIV2','FIX2','PATCH2'};
box_test(1)=get(handles.CIV1,'Value');
box_test(2)=get(handles.FIX1,'Value');
box_test(3)=get(handles.PATCH1,'Value');
box_test(4)=get(handles.CIV2,'Value');
box_test(5)=get(handles.FIX2,'Value');
box_test(6)=get(handles.PATCH2,'Value');
index_first=find(box_test==1,1);
if isempty(index_first)
    errormsg='no selected operation';
    return
end
index_last=find(box_test==1,1,'last');
box_used=box_test(index_first : index_last);
[box_missing,ind_missing]=min(box_used);
if isequal(box_missing,0); %there is a missing step in the sequence of operations
    errormsg=['missing' cell2mat(operations(ind_missing))];
    return
end

%% check mask if selecetd
if isequal(get(handles.get_mask_civ1,'Value'),1)
    maskname=get(handles.mask_civ1,'String');
    if ~exist(maskname,'file')
        get_mask_civ1_Callback(hObject, eventdata, handles);
    end
end
if isequal(get(handles.get_mask_fix1,'Value'),1)
    maskname=get(handles.mask_fix1,'String');
    if ~exist(maskname,'file')
        get_mask_fix1_Callback(hObject, eventdata, handles);
    end
end
if isequal(get(handles.get_mask_civ2,'Value'),1)
    maskname=get(handles.mask_civ2,'String');
    if ~exist(maskname,'file')
        get_mask_civ2_Callback(hObject, eventdata, handles);
    end
end
if isequal(get(handles.get_mask_fix2,'Value'),1)
    maskname=get(handles.mask_fix2,'String');
    if ~exist(maskname,'file')
        get_mask_fix2_Callback(hObject, eventdata, handles);
    end
end

%% reinitialise status callback 
if isfield(handles,'status')
    set(handles.status,'Value',0);%suppress status display
    status_Callback(hObject, eventdata, handles)
end

%% set the list of files and check them
display('checking the files...')
[ref_i,ref_j,errormsg]=find_ref_indices(handles);
if ~isempty(errormsg)
    return
end
[filecell,num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2,nom_type_nc,xx,yy,compare]=...
    set_civ_filenames(handles,ref_i,ref_j,box_test)

set(handles.civ,'UserData',filecell);%store for futur use of status callback
if isempty(filecell)% (error message displayed in fct set_civ_filenames)
    return
end
nbfield=numel(num1_civ1);
nbslice=numel(num_a_civ1);

%% choose the batch or run mode 
path_UVMAT=fileparts(which('uvmat')); %path to the source directory of uvmat
xmlfile='PARAM.xml';
if exist(xmlfile,'file')% search parameter xml file in the whole matlab path
    t=xmltree(xmlfile);
    s=convert(t);
end
test_interp=0;
if batch
    if isfield(s,'BatchParam')
        sparam=s.BatchParam;
        if isfield(sparam,'BatchMode')
            batch_mode=sparam.BatchMode;
            if ~ismember(batch_mode,{'sge','oar'})
                errormsg=['batch mode ' batch_mode ' not supported by UVMAT'];
                return
            end
        end
    else
        errormsg='no batch civ binaries defined in PARAM.xml';
        return
    end
    
    switch batch_mode
        case 'sge'
            % choice of batch priority:
            [s,w]=unix('qstat -q civ.q|grep job_| wc -l'); %check the waiting list (command unix)
            if isequal(s,0)
                w(end)=[];
                str_displ={[w ' jobs in the waiting list'];...
                    '***********************';...
                    'JOBS PRIORITY POLICY';...
                    '- urgent = less than 100 images pairs';...
                    '- normal = during the experiments';...
                    '- low = post processing';...
                    '***********************';...
                    'Select a priority:'};
                ' ';...
                    str={'urgent';'normal';'low'};
                [ind_answer,v] = listdlg('PromptString',str_displ,...
                    'SelectionMode','single',...
                    'ListString',str,'ListSize',[200 100],'Name','job priority','InitialValue',3);
                pvalue=num2str((1-ind_answer)*500); %                 
                if isequal(v,0) % to handle Cancel button and figure close,
                    errormsg='job cancelled';
                    return % a better way should be create
                end
            else
                msgbox_uvmat('ERROR','sge batch system not available')
                return
            end
        case 'oar'
            [s,w]=unix('oarstat'); %check the waiting list (command unix)
            if ~isequal(s,0)
                msgbox_uvmat('ERROR','oar batch system not available')
                return
            end
    end
else % run
    if isfield(s,'RunParam')
        sparam=s.RunParam;
    else
        msgbox_uvmat('ERROR','no run civ binaries defined in PARAM.xml')
        return
    end
end

%% choose the civ program
ProgList=get(handles.CivMode,'String');
index=get(handles.CivMode,'Value');
% CivX=isequal(ProgList{index},'CivX');
% CivAll=isequal(ProgList{index},'CivAll');
% CivUvmat=isequal(ProgList{index},'CivUvmat');
CivMode=ProgList{index};
%CivMode=isequal(get(handles.CivMode,'Value'),2); % Boolean for new civ programs

switch CivMode
    case 'CivAll'
        if isfield(sparam,'CivBin')
            CivBin=sparam.CivBin;
            if ~exist(CivBin,'file') || isempty(which(CivBin))% if path defined as relative to uvmat
                sparam.CivBin=fullfile(path_UVMAT,CivBin);
                if ~exist(sparam.CivBin,'file')
                    msgbox_uvmat('ERROR',['CIVx binary ' CivBin ' defined in PARAM.xm does not exist'])
                    return
                end
            end
        end
    case 'CivX'
        if isfield(sparam,'Civ1Bin')
            Civ1Bin=sparam.Civ1Bin;
            if ~exist(Civ1Bin,'file')&&~isempty(which(Civ1Bin))% if path defined as relative to uvmat
                sparam.Civ1Bin=fullfile(path_UVMAT,Civ1Bin);
                if ~exist(sparam.Civ1Bin,'file')
                    msgbox_uvmat('ERROR',['civ1 binary ' Civ1Bin ' defined in PARAM.xm does not exist'])
                    return
                end
            end
        end
        if isfield(sparam,'Civ2Bin')
            Civ2Bin=sparam.Civ2Bin;
            if ~exist(Civ2Bin,'file')&&~isempty(which(Civ2Bin))% if path defined as relative to uvmat
                sparam.Civ2Bin=fullfile(path_UVMAT,Civ2Bin);
                if ~exist(sparam.Civ2Bin,'file')
                    msgbox_uvmat('ERROR',['civ2 binary ' Civ2Bin ' defined in PARAM.xm does not exist'])
                    return
                end
            end
        end
        if  isfield(sparam,'PatchBin')
            if ~exist(sparam.PatchBin,'file')&&~isempty(which(sparam.PatchBin))% if path defined as relative to uvmat
                sparam.PatchBin=fullfile(path_UVMAT,sparam.PatchBin);
            end
        end
        if isfield(sparam,'FixBin')
            if ~exist(sparam.FixBin,'file')&&~isempty(which(sparam.FixBin))% if path defined as relative to uvmat
                sparam.FixBin=fullfile(path_UVMAT,sparam.FixBin);
            end
        end
    case 'Matlab'
        if batch
            %% v�rifier Mtlab install� sur le cluster
        end          
end



%% get civ1 parameters:
display('files OK, processing...')
if box_test(1)==1
    par_civ1=read_param_civ1(handles,filecell.ima1.civ1{1,1});
end

%% get fix1 parameters TODO : par_fix1=read_param_fix1(handles);
if box_test(2)==1
    flagindex1(1)=get(handles.vec_Fmin2, 'Value');
    flagindex1(2)=get(handles.vec_F3, 'Value');
    flagindex1(3)=get(handles.vec_F2, 'Value');
    thresh_vecC1=str2double(get(handles.thresh_vecC,'String'));%threshold on image correlation vec_C
    thresh_vel1=str2double(get(handles.thresh_vel,'String'));%threshold on velocity modulus
    test_mask=get(handles.get_mask_fix1,'Value');
    nbslice_mask=get(handles.mask_fix1,'UserData'); % get the number of slices (= number of masks)
    %%%%%%%%%%%%%COMPLETER LE PROGRAMME FIX
    %     inf_sup=get(handles.inf_sup1,'Value');80
    %     fileref=get(handles.ref_fix1,'String');
    %     refpath=get(handles.ref_fix1,'UserData');
    %     fileref=fullfile(refpath,fileref);
    menu=get(handles.field_ref1,'String');
    index=get(handles.field_ref1,'Value');
    if isempty(menu)
        fieldchoice='';
    else
        fieldchoice=menu{index};
        msgbox_uvmat('WARNING','reference field is not used presently with batch, use RUN option')
    end
end

%% get patch1 parameters
if box_test(3)==1
    rho_patch1=str2double(get(handles.rho_patch1,'String'));
    if isnan(rho_patch1)
        rho_patch1='1000';
        set(handles.rho_patch1,'String','1')
    else
        rho_patch1=num2str(1000*rho_patch1);
    end
    nx_patch1=get(handles.nx_patch1,'String');
    ny_patch1=get(handles.ny_patch1,'String');
    if isnan(str2double(nx_patch1))
        nx_patch1='50' ;%default
        set(handles.nx_patch1,'String','50');
    end
    if isnan(str2double(ny_patch1))
        ny_patch1='50' ;%default
        set(handles.ny_patch1,'String','50');
    end
    subdomain_patch1=get(handles.subdomain_patch1,'String');
    thresh_patch1=get(handles.thresh_patch1,'String');
end

%% get civ2 parameters:
if box_test(4)==1
    par_civ2=read_param_civ2(handles,cell2mat(filecell.ima1.civ2(1,1)));
end

%% get fix2 parameters
if box_test(5)==1
    flagindex2(1)=get(handles.vec_Fmin2_2, 'Value');
    flagindex2(2)=get(handles.vec_F3_2, 'Value');
    flagindex2(3)=get(handles.vec_F4, 'Value');
    thresh_vec2C=str2double(get(handles.thresh_vec2C,'String'));%threshold on image correlation vec_C
    thresh_vel2=str2double(get(handles.thresh_vel2,'String'));%threshold on velocity modulus
    test_mask=get(handles.get_mask_fix2,'Value');
    nbslice_mask=get(handles.mask_fix2,'UserData'); % get the number of slices (= number of masks)
    %%%%%%%%%%%%%COMPLETER LE PROGRAMME FIX AVEC REF FILE ET OPTION inf_sup=2
    %     inf_sup=get(handles.inf_sup2,'Value');
    %     ref=get(handles.ref_fix2,'UserData');
    
    %%%%%%%%%%%%%%%%%%%
end

%% get patch2 parameters
if box_test(6)==1
    rho_patch2=str2double(get(handles.rho_patch2,'String'));
    if isnan(rho_patch2)
        rho_patch2='1000';
        set(handles.rho_patch2,'String','1')
    else
        rho_patch2=num2str(1000*rho_patch2);
    end
    nx_patch2=get(handles.nx_patch2,'String');
    ny_patch2=get(handles.ny_patch2,'String');
    if isnan(str2double(nx_patch2))
        nx_patch2='50' ;%default
        set(handles.nx_patch2,'String','50');
    end
    if isnan(str2double(ny_patch2))
        ny_patch2='50' ;%default
        set(handles.ny_patch2,'String','50');
    end
    subdomain_patch2=get(handles.subdomain_patch2,'String');
    thresh_patch2=get(handles.thresh_patch2,'String');
end

%% MAIN LOOP
time=get(handles.RootName,'UserData'); %get the set of times

super_cmd=[];
batch_file_list=[];
    
for ifile=1:nbfield
    for j=1:nbslice
        % initiate system command
        i_cmd=0;
        switch CivMode
            case 'CivX'
                cmd='';
                if isunix % check: necessaire aussi en RUN?
                    cmd='#!/bin/bash \n';
                    cmd=[cmd '#$ -cwd \n'];
                    cmd=[cmd 'hostname && date \n'];
                    cmd=[cmd 'umask 002 \n'];%allow writting access to created files for user group
                end
            case 'CivAll'
                %         if CivAll
                CivAllxml=xmltree;% xml contents,  all parameters
                CivAllCmd='';
                CivAllxml=set(CivAllxml,1,'name','CivDoc');
        end
        [Rootbat,Filebat]=fileparts(filecell.nc.civ1{ifile,j});%output netcdf file (without extension)

        filename_bat=[fullfile(Rootbat,Filebat) '.bat'];
        
        %CIV1
        if box_test(1)==1
            par_civ1.filename_ima_a=filecell.ima1.civ1{ifile,j};
            par_civ1.filename_ima_b=filecell.ima2.civ1{ifile,j};
            par_civ1.Dt=num2str(time(num2_civ1(ifile),num_b_civ1(j))-time(num1_civ1(ifile),num_a_civ1(j)));
            par_civ1.T0=num2str((time(num2_civ1(ifile),num_b_civ1(j))+time(num1_civ1(ifile),num_a_civ1(j)))/2);
            par_civ1.term_a=num2stra(num_a_civ1(j),nom_type_nc);%UTILITE?
            par_civ1.term_b=num2stra(num_b_civ1(j),nom_type_nc);%
            test_mask=get(handles.get_mask_civ1,'Value');
            if test_mask==0
                par_civ1.maskname='noFile use default';
                par_civ1.maskflag='n';
            else
                maskdispl=get(handles.mask_civ1,'String');
                if exist(maskdispl,'file')
                    par_civ1.maskname=maskdispl;
                    par_civ1.maskflag='y';
                else
                    maskbase=[filecell.filebase '_' maskdispl]; %
                    nbslice_mask=str2double(maskdispl(1:end-4)); %
                    num1_mask=mod(num1_civ1(ifile)-1,nbslice_mask)+1;
                    par_civ1.maskname=name_generator(maskbase,num1_mask,1,'.png','_i');
                    if exist(par_civ1.maskname,'file')
                        par_civ1.maskflag='y';
                    else
                        par_civ1.maskname='noFile use default';
                        par_civ1.maskflag='n';
                    end
                end
            end
            test_grid=get(handles.browse_gridciv1,'Value');
            if test_grid
                par_civ1.gridflag='y';
                gridname=get(handles.grid_civ1,'String');
                if isequal(gridname(end-3:end),'grid')
                    nbslice_grid=str2double(gridname(1:end-4)); %
                    if ~isnan(nbslice_grid)
                        num1_grid=mod(num1_civ1(ifile)-1,nbslice_grid)+1;
                        par_civ1.gridname=[filecell.filebase '_' name_generator(gridname,num1_grid,1,'.grid','_i')];
                        if ~exist(par_civ1.gridname,'file')
                            msgbox_uvmat('ERROR','grid file absent for civ1')
                        end
                    elseif exist(gridname,'file')
                        par_civ1.gridname=gridname;
                    else
                        msgbox_uvmat('ERROR','grid file absent for civ1')
                    end
                end
            else
                par_civ1.gridname='noFile use default';
                par_civ1.gridflag='n';
            end
            
            i_cmd=i_cmd+1;
            switch CivMode
                case 'CivX'
                    civ1_exe=CIV1_CMD(fullfile(Rootbat,Filebat),'',par_civ1,handles,sparam);%create the parameter file .civ1.cmx and set the execution string civ1_exe
                    cmd=[cmd civ1_exe '\n'];
                case 'CivAll'
                    CivAllCmd=[CivAllCmd ' civ1 '];
                    str=CIV1_CMD_Unified(fullfile(Rootbat,Filebat),'',par_civ1);
                    fieldnames=fields(str);
                    [CivAllxml,uid_civ1]=add(CivAllxml,1,'element','civ1');
                    for ilist=1:length(fieldnames)
                        val=eval(['str.' fieldnames{ilist}]);
                        if ischar(val)
                            [CivAllxml,uid_t]=add(CivAllxml,uid_civ1,'element',fieldnames{ilist});
                            [CivAllxml,uid_t2]=add(CivAllxml,uid_t,'chardata',val);
                        end
                    end
            end
        end
        
        % FIX1
        if box_test(2)==1
            test_mask=get(handles.get_mask_fix1,'Value');
            if test_mask==0
                maskname='';
            else
                maskdispl=get(handles.mask_fix1,'String');
                nbslice_mask=str2double(maskdispl(1:end-4)); %
                num1_mask=mod(num1_civ1(ifile)-1,nbslice_mask)+1;
                maskbase=[filecell.filebase '_' maskdispl];
                maskname=name_generator(maskbase,num1_mask,1,'.png','_i');
            end
            switch CivMode
                %             if CivX
                case 'CivX'
                    if isunix %unix system
                        cmd_FIX=[sparam.FixBin ' -f ' filecell.nc.civ1{ifile,j} ' -fi1 ' num2str(flagindex1(1)) ...
                            ' -fi2 ' num2str(flagindex1(2)) ' -fi3 ' num2str(flagindex1(3)) ...
                            ' -threshC ' num2str(thresh_vecC1) ' -threshV ' num2str(thresh_vel1) ' -maskName ' maskname];
                    else %windows system
                        cmd_FIX=['"' sparam.FixBin '" -f "' filecell.nc.civ1{ifile,j} '" -fi1 ' num2str(flagindex1(1)) ...
                            ' -fi2 ' num2str(flagindex1(2)) ' -fi3 ' num2str(flagindex1(3)) ...
                            ' -threshC ' num2str(thresh_vecC1) ' -threshV ' num2str(thresh_vel1) ' -maskName "' maskname '"'];
                        cmd_FIX=regexprep(cmd_FIX,'\\','\\\\');
                    end
                    cmd=[cmd cmd_FIX '\n'];
                case 'CivAll'
                    fix1.inputFileName=filecell.nc.civ1{ifile,j} ;
                    fix1.fi1=num2str(flagindex1(1));
                    fix1.fi2=num2str(flagindex1(2));
                    fix1.fi3=num2str(flagindex1(3));
                    fix1.threshC=num2str(thresh_vecC1);
                    fix1.threshV=num2str(thresh_vel1);
                    fieldnames=fields(fix1);
                    [CivAllxml,uid_fix1]=add(CivAllxml,1,'element','fix1');
                    for ilist=1:length(fieldnames)
                        val=eval(['fix1.' fieldnames{ilist}]);
                        if ischar(val)
                            [CivAllxml,uid_t]=add(CivAllxml,uid_fix1,'element',fieldnames{ilist});
                            [CivAllxml,uid_t2]=add(CivAllxml,uid_t,'chardata',val);
                        end
                    end
                    CivAllCmd=[CivAllCmd ' fix1 '];
            end
        end
        
        %PATCH1
        if box_test(3)==1
            switch CivMode
                case 'CivX'
                    cmd_PATCH=PATCH_CMD(filecell.nc.civ1{ifile,j},nx_patch1,ny_patch1,rho_patch1,subdomain_patch1,thresh_patch1,test_interp,sparam.PatchBin);
                    cmd=[cmd cmd_PATCH '\n'];
                case 'CivAll'
                    patch1.inputFileName=filecell.nc.civ1{ifile,j} ;
                    patch1.nopt=subdomain_patch1;
                    patch1.maxdiff=thresh_patch1;
                    patch1.ro=rho_patch1;
                    test_grid=get(handles.get_gridpatch1,'Value');
                    if test_grid
                        patch1.gridflag='y';
                        gridname=get(handles.grid_patch1,'String');
                        if isequal(gridname(end-3:end),'grid')
                            nbslice_grid=str2double(gridname(1:end-4)); %
                            if ~isnan(nbslice_grid)
                                num1_grid=mod(num1_civ1(ifile)-1,nbslice_grid)+1;
                                patch1.gridPatch=[filecell.filebase '_' name_generator(gridname,num1_grid,1,'.grid','_i')];
                                if ~exist(patch1.gridPatch,'file')
                                    msgbox_uvmat('ERROR','grid file absent for patch1')
                                end
                            elseif exist(gridname,'file')
                                patch1.gridPatch=gridname;
                            else
                                msgbox_uvmat('ERROR','grid file absent for patch1')
                            end
                        end
                    else
                        patch1.gridPatch='none';
                        patch1.gridflag='n';
                        patch1.m=nx_patch1;
                        patch1.n=ny_patch1;
                    end
                    patch1.convectFlow='n';
                    fieldnames=fields(patch1);
                    [CivAllxml,uid_patch1]=add(CivAllxml,1,'element','patch1');
                    for ilist=1:length(fieldnames)
                        val=eval(['patch1.' fieldnames{ilist}]);
                        if ischar(val)
                            [CivAllxml,uid_t]=add(CivAllxml,uid_patch1,'element',fieldnames{ilist});
                            [CivAllxml,uid_t2]=add(CivAllxml,uid_t,'chardata',val);
                        end
                    end
                    CivAllCmd=[CivAllCmd ' patch1 '];
            end
        end
        if box_test(4)==1 || box_test(5)==1 || box_test(6)==1
 %                 pvalue=num2str((1-ind_answer)*500);
           filename_cmx=filecell.nc.civ2{ifile,j};%output netcdf file
            filename_cmx(end-1:end+1)='cmx';%name of cmx file
        end
        if box_test(4)==1
            par_civ2.filename_ima_a=filecell.ima1.civ2{ifile,j};
            par_civ2.filename_ima_b=filecell.ima2.civ2{ifile,j};
            [Rootbat,Filebat]=fileparts(filecell.nc.civ2{ifile,j});%output netcdf file (without extention)
            par_civ2.Dt=num2str(time(num2_civ2(ifile),num_b_civ2(j))-time(num1_civ2(ifile),num_a_civ2(j)));
            par_civ2.T0=num2str((time(num2_civ1(ifile),num_b_civ2(j))+time(num1_civ2(ifile),num_a_civ2(j)))/2);
            par_civ2.term_a=num2stra(num_a_civ2(j),nom_type_nc);
            par_civ2.term_b=num2stra(num_b_civ2(j),nom_type_nc);
            par_civ2.filename_nc1=filecell.nc.civ1{ifile,j};
            par_civ2.filename_nc1(end-2:end)=[]; % remove '.nc'
            test_mask=get(handles.get_mask_civ2,'Value');
            if test_mask==0
                par_civ2.maskname='noFile use default';
                par_civ2.maskflag='n';
            else
                maskdispl=get(handles.mask_civ2,'String');
                if exist(maskdispl,'file')
                    par_civ2.maskname=maskdispl;
                    par_civ2.maskflag='y';
                else
                    maskbase=[filecell.filebase '_' maskdispl]; %
                    nbslice_mask=str2double(maskdispl(1:end-4)); %
                    num1_mask=mod(num1_civ2(ifile)-1,nbslice_mask)+1;
                    par_civ2.maskname=name_generator(maskbase,num1_mask,1,'.png','_i');
                    if exist(par_civ2.maskname,'file')
                        par_civ2.maskflag='y';
                    else
                        par_civ2.maskname='noFile use default';
                        par_civ2.maskflag='n';
                    end
                end
            end
            gridname=get(handles.grid_civ2,'String');
            if numel(gridname)>=4 && isequal(gridname(end-3:end),'grid')
                nbslice_grid=str2double(gridname(1:end-4)); %
                if ~isnan(nbslice_grid)
                    par_civ2.gridflag='y';
                    num1_grid=mod(num1_civ2(ifile)-1,nbslice_grid)+1;
                    par_civ2.gridname=[filecell.filebase '_' name_generator(gridname,num1_grid,1,'.grid','_i')];
                    if exist(par_civ2.gridname,'file')
                        par_civ2.gridflag='y';
                    else
                        par_civ2.gridname='noFile use default';
                        par_civ2.gridflag='n';
                    end
                elseif exist(gridname,'file')
                    par_civ2.gridflag='y';
                else
                    par_civ2.gridname='noFile use default';
                    par_civ2.gridflag='n';
                end
            end
            i_cmd=i_cmd+1;
            flname=fullfile(Rootbat,Filebat);
            switch CivMode
                case 'CivX'
                    cmd_CIV2=CIV2_CMD(flname,[],par_civ2,sparam);%creates the cmx file [fullfile(Rootbat,Filebat) '.civ2.cmx]
                    cmd=[cmd cmd_CIV2 '\n'];
                case 'CivAll'
                    CivAllCmd=[CivAllCmd ' civ2 '];
                    str=CIV2_CMD_Unified(flname,'',par_civ2);
                    fieldnames=fields(str);
                    [CivAllxml,uid_civ2]=add(CivAllxml,1,'element','civ2');
                    for ilist=1:length(fieldnames)
                        val=eval(['str.' fieldnames{ilist}]);
                        if ischar(val)
                            [CivAllxml,uid_t]=add(CivAllxml,uid_civ2,'element',fieldnames{ilist});
                            [CivAllxml,uid_t2]=add(CivAllxml,uid_t,'chardata',val);
                        end
                    end
            end
        end
        
        % FIX2
        if box_test(5)==1
            test_mask=get(handles.get_mask_fix2,'Value');
            if test_mask==0
                maskname=''; %no mask used
            else
                maskdispl=get(handles.mask_fix2,'String');
                maskbase=[filecell.filebase '_' maskdispl]; %
                nbslice_mask=str2double(maskdispl(1:end-4)); %
                num1_mask=mod(num1_civ2(ifile)-1,nbslice_mask)+1;
                maskname =name_generator(maskbase,num1_mask,1,'.png','_i');
            end
            switch CivMode
                case 'CivX'
                    if isunix
                        cmd_FIX=[sparam.FixBin ' -f ' filecell.nc.civ2{ifile,j} ' -fi1 ' num2str(flagindex2(1)) ...
                            ' -fi2 ' num2str(flagindex2(2)) ' -fi3 ' num2str(flagindex2(3)) ...
                            ' -threshC ' num2str(thresh_vec2C) ' -threshV ' num2str(thresh_vel2) ' -maskName ' maskname];
                    else
                        cmd_FIX=['"' sparam.FixBin '" -f "' filecell.nc.civ2{ifile,j} '" -fi1 ' num2str(flagindex2(1)) ...
                            ' -fi2 ' num2str(flagindex2(2)) ' -fi3 ' num2str(flagindex2(3)) ...
                            ' -threshC ' num2str(thresh_vec2C) ' -threshV ' num2str(thresh_vel2) ' -maskName "' maskname '"'];
                        cmd_FIX=regexprep(cmd_FIX,'\\','\\\\');
                    end
                    cmd=[cmd cmd_FIX '\n'];
                case 'CivAll'
                    fix2.inputFileName=filecell.nc.civ2{ifile,j} ;
                    fix2.fi1=num2str(flagindex2(1));
                    fix2.fi2=num2str(flagindex2(2));
                    fix2.fi3=num2str(flagindex2(3));
                    fix2.threshC=num2str(thresh_vec2C);
                    fix2.threshV=num2str(thresh_vel2);
                    fieldnames=fields(fix2);
                    [CivAllxml,uid_fix2]=add(CivAllxml,1,'element','fix2');
                    for ilist=1:length(fieldnames)
                        val=eval(['fix2.' fieldnames{ilist}]);
                        if ischar(val)
                            [CivAllxml,uid_t]=add(CivAllxml,uid_fix2,'element',fieldnames{ilist});
                            [CivAllxml,uid_t2]=add(CivAllxml,uid_t,'chardata',val);
                        end
                    end
                    CivAllCmd=[CivAllCmd ' fix2 '];
            end
        end
        
        %PATCH2
        if box_test(6)==1
            switch CivMode
                case 'CivX'
                    cmd_PATCH=PATCH_CMD(filecell.nc.civ2{ifile,j},nx_patch2,ny_patch2,rho_patch2,subdomain_patch2,thresh_patch2,test_interp,sparam.PatchBin);
                    cmd=[cmd cmd_PATCH '\n'];
                case 'CivAll'
                    patch2.inputFileName=filecell.nc.civ1{ifile,j} ;
                    patch2.nopt=subdomain_patch2;
                    patch2.maxdiff=thresh_patch2;
                    patch2.ro=rho_patch2;
                    test_grid=get(handles.get_gridpatch2,'Value');
                    if test_grid
                        patch2.gridflag='y';
                        gridname=get(handles.grid_patch2,'String');
                        if isequal(gridname(end-3:end),'grid')
                            nbslice_grid=str2double(gridname(1:end-4)); %
                            if ~isnan(nbslice_grid)
                                num1_grid=mod(num1_civ2(ifile)-1,nbslice_grid)+1;
                                patch2.gridPatch=[filecell.filebase '_' name_generator(gridname,num1_grid,1,'.grid','_i')];
                                if ~exist(patch2.gridPatch,'file')
                                    msgbox_uvmat('ERROR','grid file absent for patch2')
                                end
                            elseif exist(gridname,'file')
                                patch2.gridPatch=gridname;
                            else
                                msgbox_uvmat('ERROR','grid file absent for patch2')
                            end
                        end
                    else
                        patch2.gridPatch='none';
                        patch2.gridflag='n';
                        patch2.m=nx_patch2;
                        patch2.n=ny_patch2;
                    end
                    patch2.convectFlow='n';
                    fieldnames=fields(patch2);
                    [CivAllxml,uid_patch2]=add(CivAllxml,1,'element','patch2');
                    for ilist=1:length(fieldnames)
                        val=eval(['patch2.' fieldnames{ilist}]);
                        if ischar(val)
                            [CivAllxml,uid_t]=add(CivAllxml,uid_patch2,'element',fieldnames{ilist});
                            [CivAllxml,uid_t2]=add(CivAllxml,uid_t,'chardata',val);
                        end
                    end
                    CivAllCmd=[CivAllCmd ' patch2 '];
            end
        end
 
        switch CivMode
            case {'CivX','CivAll'}
                if isequal(CivMode,'CivAll')
                    save(CivAllxml,[flname '.xml']);
                    cmd=[cmd sparam.CivBin ' -f ' flname '.xml '  CivAllCmd ' >' flname '.log' '\n'];
                end
                % create the .bat file:
                [fid,message]=fopen(filename_bat,'w');
                if isequal(fid,-1)
                    msgbox_uvmat('ERROR', ['creation of .bat file: ' message])
                    return
                end
                fprintf(fid,cmd);
                fclose(fid);
                
                batch_file_list{length(batch_file_list)+1}=filename_bat;
                
%                 if batch
%                     switch batch_mode
%                         case 'sge'                            
%                             display(['!qsub -p ' pvalue ' -q civ.q -e ' flname '.errors -o ' flname '.log' ' ' filename_bat]);
%                             eval(  ['!qsub -p ' pvalue ' -q civ.q -e ' flname '.errors -o ' flname '.log' ' ' filename_bat]);
%                         case 'oar'
% %                             eval(  ['!chmod +x ' filename_bat]);
% %                             %eval(  ['!oarsub -n CIVX -l /core=1,walltime=00:10:00  ' filename_bat]);                    
% %                             eval(  ['!oarsub -n CIVX -l "/core=1+{type = ''smalljob''}/licence=1,walltime=00:10:00"   ' filename_bat]);
% 
%                     cmd_str=['sh ' filename_bat];
%                     super_cmd{length(super_cmd)+1}=cmd_str;
%                            
%                     end
%                 else
%                     %% to lauch the jobs locally :
%                     if(isunix)
%                         cmd_str=['. ' filename_bat];
%                     else %case of Windows
%                         cmd_str=['@call "' regexprep(filename_bat,'\\','\\\\') '"'];
%                     end
%                     super_cmd=[super_cmd cmd_str '\n'];
%                     disp(cmd_str);
%                 end
            case 'Matlab'
                drawnow
                if box_test(1)==1
                    Param.Civ1=par_civ1;
                end
                if box_test(2)==1
                    fix1.WarnFlags=[];
                    if get(handles.vec_Fmin2,'Value')
                        fix1.WarnFlags=[fix1.WarnFlags -2];
                    end
                    if get(handles.vec_F3,'Value')
                        fix1.WarnFlags=[fix1.WarnFlags 3];
                    end
                    fix1.LowerBoundCorr=thresh_vecC1;
                    if get(handles.inf_sup1,'Value')
                        fix1.UppperBoundVel=thresh_vel1;
                    else
                        fix1.LowerBoundVel=thresh_vel1;
                    end
                    if get(handles.get_mask_fix1,'Value')
                        fix1.MaskName=maskname;
                    end
                    Param.Fix1=fix1;
                end
                if box_test(3)==1
                    if strcmp(compare,'stereo PIV')
                        filebase_A=filecell.filebase;
                        [pp,ff]=fileparts(filebase_A);
                        filebase_B=fullfile(pp,get(handles.RootName_1,'String'));
                        RUN_STLIN(filecell.ncA.civ1{ifile,j},filecell.nc.civ1{ifile,j},'civ1',filecell.st{ifile,j},...
                            str2num(nx_patch1),str2num(ny_patch1),str2num(thresh_patch1),[filebase_A '.xml'],[filebase_B '.xml'])
                    else
                        Param.Patch1.Rho=rho_patch1;
                        Param.Patch1.Threshold=thresh_patch1;
                        Param.Patch1.SubDomain=subdomain_patch1;
                    end
                end
                if box_test(4)==1
                    Param.Civ2=par_civ2;
                end
                if box_test(5)==1
                    fix2.WarnFlags=[];
                    if get(handles.vec_Fmin2_2,'Value')
                        fix2.WarnFlags=[fix2.WarnFlags -2];
                    end
                    if get(handles.vec_F4,'Value')
                        fix2.WarnFlags=[fix2.WarnFlags 4];
                    end
                    if get(handles.vec_F3_2,'Value')
                        fix2.WarnFlags=[fix2.WarnFlags 3];
                    end
                    fix2.LowerBoundCorr=thresh_vec2C;
                    if get(handles.inf_sup2,'Value')
                        fix2.UppperBoundVel=thresh_vel2;
                    else
                        fix2.LowerBoundVel=thresh_vel2;
                    end
                    if get(handles.get_mask_fix2,'Value')
                        fix2.MaskName=maskname;
                    end
                    Param.Fix2=fix2;
                end
                if box_test(6)==1
                    if strcmp(compare,'stereo PIV')
                        filebase_A=filecell.filebase;
                        [pp,ff]=fileparts(filebase_A);
                        filebase_B=fullfile(pp,get(handles.RootName_1,'String'));
                        RUN_STLIN(filecell.ncA.civ2{ifile,j},filecell.nc.civ2{ifile,j},'civ2',filecell.st{ifile,j},...
                            str2num(nx_patch2),str2num(ny_patch2),str2num(thresh_patch2),[filebase_A '.xml'],[filebase_B '.xml'])
                    else
                        Param.Patch2.Rho=rho_patch2;
                        Param.Patch2.Threshold=thresh_patch2;
                        Param.Patch2.SubDomain=subdomain_patch2;
                    end
                end
                if ~strcmp(compare,'stereo PIV')
                    [Data,erromsg]=civ_uvmat(Param,filecell.nc.civ1{ifile,j});
                    if isempty(errormsg)
                        display([filecell.nc.civ1{ifile,j} ' written'])
                    else
                        msgbox_uvmat('ERROR',errormsg)
                    end

                end
        end
    end
end

if batch
    switch batch_mode                        
        case 'sge'
            for p=1:length(batch_file_list)
                cmd=['!qsub -p ' pvalue ' -q civ.q -e ' flname '.errors -o ' flname '.log' ' ' batch_file_list{p}];
                display(cmd);eval(cmd);
            end
        case 'oar'
            for p=0:floor(length(batch_file_list)/6);                
                filename_batch_group=fullfile(Rootbat,['job_list_' num2str(p) '.bat']);
                fid=fopen(filename_batch_group,'w');
                if fid==-1
                    msgbox_uvmat('ERROR',['cannot create the command file ' filename_superbat])
                    return
                end
                if p==floor(length(batch_file_list)/6)
                    kmax=mod(length(batch_file_list),6);
                else
                    kmax=6;
                end
                for k=1:kmax
                    fprintf(fid,['sh ' batch_file_list{p*6+k} '\n']);
                end
                fclose(fid);
                system(['chmod +x ' filename_batch_group]);
                eval(  ['!oarsub -n CIVX -q nicejob -l "/core=1+{type = ''smalljob''}/licence=1,walltime=00:60:00"   ' filename_batch_group]);
            end
        case 'oar_new' % to be develloped with Patrick Begou
                filename_joblist=fullfile(Rootbat,'job_list.txt');
                fid=fopen(filename_superbat,'w');
                if fid==-1
                    msgbox_uvmat('ERROR',['cannot create the command file ' filename_superbat])
                    return
                end
                for p=1:length(batch_file_list)
                    fprintf(fid,[batch_file_list{p} '\n']);
                end
                fclose(fid);
                walltime=datestr(length(super_cmd)*10/24/60,13);
                eval(  ['!oarsub -n CIVX -q nicejob -l "/core=1+{type = ''smalljob''}/licence=1,walltime=' walltime '"   ' filename_superbat]);
    end
else
    if ~isequal(CivMode,'Matlab')
        filename_superbat=fullfile(Rootbat,'job_list.bat');
        fid=fopen(filename_superbat,'w');
        if fid==-1
            msgbox_uvmat('ERROR',['cannot create the command file ' filename_superbat])
            return
        end
        for p=1:length(batch_file_list)
            if isunix
                fprintf(fid,['sh ' batch_file_list{p} '\n']);
            else
                fprintf(fid,['@call "' regexprep(filename_bat,'\\','\\\\') '"' '\n']);
            end
        end
        fclose(fid);
        if(isunix)
            system(['chmod +x ' filename_superbat]);
        end
        system([filename_superbat ' &']);% execute main commmand
    end
    
end


%% save interface state
if isfield(filecell,'nc')
    if isfield(filecell.nc,'civ2')
        fileresu=filecell.nc.civ2{1,1};
    else
        fileresu=filecell.nc.civ1{1,1};
    end
end
[RootPath,RootFile,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fileresu);
namedoc=fullfile(RootPath,subdir,RootFile);
detect=1;
while detect==1
    namefigfull=[namedoc '.fig'];
    hh=dir(namefigfull);
    if ~isempty(hh)
        detect=1;
        namedoc=[namedoc '.0'];
    else
        detect=0;
    end
end
saveas(gcbf,namefigfull);%save the interface with name namefigfull (A CHANGER EN FICHIER  .xml)

%------------------------------------------------------------------------
% --- determine the list of reference indices of processing file
function [ref_i,ref_j,errormsg]=find_ref_indices(handles)
%------------------------------------------------------------------------
errormsg=''; %default error message
first_i=str2double(get(handles.first_i,'String'));%first index i
last_i=str2double(get(handles.last_i,'String'));%last index i
incr_i=str2double(get(handles.incr_i,'String'));% increment
if isequal(get(handles.first_j,'Visible'),'on')
    first_j=str2double(get(handles.first_j,'String'));%first index j
    last_j=str2double(get(handles.last_j,'String'));%last index j
    incr_j=str2double(get(handles.incr_j,'String'));% increment
else
    first_j=1;
    last_j=1;
    incr_j=1;
end
ref_i=first_i:incr_i:last_i;% list of i indices (reference values for each pair)
ref_j=first_j:incr_j:last_j;% list of j indices (reference values for each pair)
if isnan(first_i)||isnan(first_j)
    errormsg='first field number not defined';
elseif isnan(last_i)||isnan(last_j)
    errormsg='last field number not defined';
elseif isnan(incr_i)||isnan(incr_j)
    errormsg='increment in field number not defined';
elseif last_i < first_i || last_j < first_j 
    errormsg='last field number must be larger than the first one';
end

%------------------------------------------------------------------------
% --- determine the list of filenames and indices needed for launch_job
function [filecell,num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2,nom_type_nc,file_ref_fix1,file_ref_fix2,compare]=...
    set_civ_filenames(handles,ref_i,ref_j,box_test)
%------------------------------------------------------------------------
filecell=[];%default

%% get the root names nomenclature and numbers
filebase=get(handles.RootName,'String');

if isempty(filebase)||isequal(filebase,'')
    msgbox_uvmat('ERROR','no input files')
    return
end

%filebase=regexprep(filebase,'\.fsnet','fsnet');% temporary fix for cluster Coriolis
filecell.filebase=filebase;

browse=get(handles.browse_root,'UserData');
compare_list=get(handles.compare,'String');
val=get(handles.compare,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')
    mode='displacement';
else
    mode_list=get(handles.mode,'String');
    mode_value=get(handles.mode,'Value');
    mode=mode_list{mode_value};
end
%time=get(handles.RootName,'UserData'); %get the set of times
ext_ima=get(handles.ImaExt,'String');
nom_type_nc=browse.nom_type_nc;
if isfield(browse,'nom_type_ima')
    nom_type_ima2=browse.nom_type_ima;
end
if isempty(nom_type_ima2),nom_type_ima2='1';end; %default
if isempty(nom_type_nc),nom_type_nc='_i1-i2';end; %default
[num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2]=...
    find_pair_indices(handles,ref_i,ref_j,mode);
%determine the new filebase for 'displacement' mode (comparison of two series)
filebase_B=filebase;% root name of the second field series for stereo
if strcmp(compare,'displacement') || strcmp(compare,'stereo PIV')
%     test_disp=1;
    nom_type_ima1=browse.nom_type_ima_1; %nomenclature type of the second file series
    [Path2,Name2]=fileparts(filebase_B);
    Path1=Path2;
    Name1=get(handles.RootName_1,'String');% root name of the first field series for stereo
    filebase_A=fullfile(Path1,Name1);
    if length(Name1)>6
        Name1=Name1(end-5:end);
    end
    if length(Name2)>6
        Name2=Name2(end-5:end);
    end
    filebase_AB=fullfile(Path2,[Name2 '-' Name1]);
else
%     test_disp=0;
    filebase_A=filebase;
    nom_type_ima1=nom_type_ima2;
    filebase_AB=filebase;
end
if strcmp(compare,'displacement')
    filebase_ima1=filebase_A;
    filebase_ima2=filebase_B;
    filebase_nc=filebase_AB; %root name for the result of civ2
else
    filebase_ima1=filebase_B;
    filebase_ima2=filebase_B;
    filebase_nc=filebase_B;
end

%determine reference files for fix:
file_ref_fix1={};%default
file_ref_fix2={};
nbfield=length(num1_civ1);
nbslice=length(num_a_civ1);
if box_test(2)==1% fix1 performed
    ref=get(handles.ref_fix1,'UserData');%read data on the ref file stored by get_ref_fix1_Callback
    if ~isempty(ref)
        first_i=str2double(get(handles.first_i,'String'));
        last_i=str2double(get(handles.last_i,'String'));
        incr_i=str2double(get(handles.incr_i,'String'));
        first_j=str2double(get(handles.first_j,'String'));
        last_j=str2double(get(handles.last_j,'String'));
        incr_j=str2double(get(handles.incr_j,'String'));
        num_i_ref=first_i:incr_i:last_i;
        num_j_ref=first_j:incr_j:last_j;
        if isequal(mode,'displacement')
            num_i1=num_i_ref;
            num_i2=num_i_ref;
            num_j1=num_j_ref;
            num_j2=num_j_ref;
        elseif isequal(mode,'pair j1-j2')% isequal(mode,'st_pair j1-j2')
            num_i1=num_i_ref;
            num_i2=num_i1;
            num_j1=ref.num_a*ones(size(num_i_ref));
            num_j2=ref.num_b*ones(size(num_i_ref));
        elseif isequal(mode,'series(Di)') % isequal(mode,'st_series(Di)')
            delta1=floor((ref.num2-ref.num1)/2);
            delta2=ceil((ref.num2-ref.num1)/2);
            num_i1=num_i_ref-delta1*ones(size(num_i_ref));
            num_i2=num_i_ref+delta2*ones(size(num_i_ref));
            if isempty(ref.num_a)
                ref.num_a=1;
            end
            num_j1=ref.num_a*ones(size(num_i1));
            num_j2=num_j1;
        elseif isequal(mode,'series(Dj)')%| isequal(mode,'st_series(Dj)')
            delta1=floor((ref.num_b-ref.num_a)/2);
            delta2=ceil((ref.num_b-ref.num_a)/2);
            num_i1=ref.num1*ones(size(num_i_ref));
            num_i2=num_i1;
            num_j1=num_j_ref-delta1*ones(size(num_j_ref));
            num_j2=num_j_ref+delta2*ones(size(num_j_ref));
        end
        for ifile=1:nbfield
            for j=1:nbslice
                file_ref=name_generator(ref.filebase,num_i1(ifile),num_j1(j),'.nc',ref.nom_type,1,num_i2(ifile),num_j2(j),ref.subdir);%
                file_ref_fix1(ifile,j)={file_ref};
                if ~exist(file_ref,'file')
                    msgbox_uvmat('ERROR',['reference file ' file_ref ' not found for fix1'])
                    filecell=[];
                    return
                end
            end
        end
    end
end

%determine reference files for fix2:
if box_test(5)==1% fix2 performed
    ref=get(handles.ref_fix2,'UserData');
    if ~isempty(ref)
        first_i=str2double(get(handles.first_i,'String'));
        last_i=str2double(get(handles.last_i,'String'));
        incr_i=str2double(get(handles.incr_i,'String'));
        first_j=str2double(get(handles.first_j,'String'));
        last_j=str2double(get(handles.last_j,'String'));
        incr_j=str2double(get(handles.incr_j,'String'));
        num_i_ref=first_i:incr_i:last_i;
        num_j_ref=first_j:incr_j:last_j;
        if isequal(mode,'displacement')
            num_i1=num_i_ref;
            num_i2=num_i_ref;
            num_j1=num_j_ref;
            num_j2=num_j_ref;
        elseif isequal(mode,'pair j1-j2')
            num_i1=num_i_ref;
            num_i2=num_i1;
            num_j1=ref.num_a;
            num_j2=ref.num_b;
        elseif isequal(mode,'series(Di)')
            delta1=floor((ref.num2-ref.num1)/2);
            delta2=ceil((ref.num2-ref.num1)/2);
            num_i1=num_i_ref-delta1*ones(size(num_i_ref));
            num_i2=num_i_ref+delta2*ones(size(num_i_ref));
            num_j1=ref.num_a*ones(size(num_i1));
            num_j2=num_j1;
        elseif isequal(mode,'series(Dj)')
            delta1=floor((ref.num_b-ref.num_a)/2);
            delta2=ceil((ref.num_b-ref.num_a)/2);
            num_i1=ref.num1*ones(size(num_i_ref));
            num_i2=num_i1;
            num_j1=num_j_ref-delta1*ones(size(num_j_ref));
            num_j2=num_j_ref+delta2*ones(size(num_j_ref));
        end
        for ifile=1:nbfield
            for j=1:nbslice
                file_ref=name_generator(ref.filebase,num_i1(ifile),num_j1(j),'.nc',ref.nom_type,1,num_i2(ifile),num_j2(j),ref.subdir);%
                file_ref_fix2(ifile,j)={file_ref};
                if ~exist(file_ref,'file')
                    msgbox_uvmat('ERROR',['reference file ' file_ref ' not found for fix2'])
                    filecell={};
                    return
                end
            end
        end
    end
end

%check dir
subdir_civ1=get(handles.subdir_civ1,'String');%subdirectory subdir_civ1 for the netcdf output data
subdir_civ2=get(handles.subdir_civ2,'String');
if isequal(subdir_civ1,''),subdir_civ1='CIV'; end% put default subdir
if isequal(subdir_civ2,''),subdir_civ2=subdir_civ1; end% put default subdir
% currentdir=pwd;%store the current working directory
[Path_ima,Name]=fileparts(filebase);%Path of the image files (.civ)
if ~exist(Path_ima,'dir')
    msgbox_uvmat('ERROR',['path to images ' Path_ima ' not found'])
    filecell={};
    return
end
[xx,message]=fileattrib(Path_ima);
if ~isempty(message) && ~isequal(message.UserWrite,1)
    msgbox_uvmat('ERROR',['No writting access to ' Path_ima])
    filecell={};
%     cd(currentdir);
    return
end

%check the existence of the netcdf and image files involved
% %%%%%%%%%%%%  case CIV1 activated   %%%%%%%%%%%%%
if box_test(1)==1;
    detect=1;
    vers=0;
    subdir_civ1_new=subdir_civ1;
    while detect==1 %create a new subdir if the netcdf files already exist
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_nc,num1_civ1(ifile),num_a_civ1(j),'.nc',nom_type_nc,1,num2_civ1(ifile),num_b_civ1(j),subdir_civ1_new);
                detect=exist(filename,'file')==2;
                if detect% if a netcdf file already exists
                    indstr=regexp(subdir_civ1_new,'\D');
                    if indstr(end)<length(subdir_civ1_new) %subdir_civ1 ends by a number
                        vers=str2double(subdir_civ1_new(indstr(end)+1:end))+1;
                        subdir_civ1_new=[subdir_civ1_new(1:indstr(end)) num2str(vers)];
                    else
                        vers=vers+1;
                        subdir_civ1_new=[subdir_civ1_new(1:indstr(end)) '_' num2str(vers)];       
                    end
                    subdir_civ2=subdir_civ1_new;
                    break
                end
                filecell.nc.civ1(ifile,j)={filename};
            end
            if detect% if a netcdf file already exists
                break
            end
        end
  
        %create the new subdir_civ1
        if ~exist(fullfile(Path_ima,subdir_civ1_new),'dir')
%             cd(Path_ima);          
            [xx,msg1]=mkdir(fullfile(Path_ima,subdir_civ1_new));

            if ~strcmp(msg1,'')
                msgbox_uvmat('ERROR',['cannot create ' subdir_civ1_new ': ' msg1])%error message for directory creation
                filecell={};
                return
            elseif isunix          
                [xx,msg2] = fileattrib(fullfile(Path_ima,subdir_civ1_new),'+w','g'); %yield writing access (+w) to user group (g)
                if ~strcmp(msg2,'')
                    msgbox_uvmat('ERROR',['pb of permission for  ' fullfile(Path_ima,subdir_civ1_new) ': ' msg2])%error message for directory creation
                    filecell={};
                    return
                end
            end
%             cd(currentdir);
        end
        if strcmp(compare,'stereo PIV')&&(strcmp(mode,'pair j1-j2')||strcmp(mode,'series(Dj)')||strcmp(mode,'series(Di)'))%check second nc series
            for ifile=1:nbfield
                for j=1:nbslice
                    filename=name_generator(filebase_A,num1_civ1(ifile),num_a_civ1(j),'.nc',nom_type_nc,1,num2_civ1(ifile),num_b_civ1(j),subdir_civ1_new);%
                    detect=exist(filename,'file')==2;
                    if detect% if a netcdf file already exists
                       indstr=regexp(subdir_civ1_new,'\D');
                       if indstr(end)<length(subdir_civ1_new) %subdir_civ1 ends by a number
                           vers=str2double(subdir_civ1_new(indstr(end)+1:end))+1;
                           subdir_civ1_new=[subdir_civ1_new(1:indstr(end)) num2str(vers)];
                       else
                           vers=vers+1;
                           subdir_civ1_new=[subdir_civ1_new '_' num2str(vers)];
                       end
                       subdir_civ2=subdir_civ1;
                       break
                    end
                    filecell.ncA.civ1(ifile,j)={filename};
                end
                if detect% if a netcdf file already exists
                    break
                end
            end
            %create the new subdir_civ1
            if ~exist(fullfile(Path_ima,subdir_civ1_new),'dir')
%                    cd(Path_ima);          
                [xx,msg1]=mkdir(fullfile(Path_ima,subdir_civ1_new));
%                             cd(currentdir);
                if ~strcmp(msg1,'')
                    msgbox_uvmat('ERROR',['cannot create ' subdir_civ1_new ': ' msg1])
%                     cd(currentdir)
                    filecell={};
                    return
                else
                    [xx,msg2] = fileattrib(fullfile(Path_ima,subdir_civ1_new),'+w','g'); %yield writing access (+w) to user group (g)
                    if ~strcmp(msg2,'')
                        msgbox_uvmat('ERROR',['pb of permission for ' subdir_civ1_new ': ' msg2])%error message for directory creation
%                         cd(currentdir)
                        filecell={};
                        return
                    end
                end
            end
        end
    end
    subdir_civ1=subdir_civ1_new;
    % get image names
    for ifile=1:nbfield
        for j=1:nbslice
            filename=name_generator(filebase_ima1, num1_civ1(ifile),num_a_civ1(j),ext_ima,nom_type_ima1);
            idetect(j)=exist(filename,'file')==2;
            filecell.ima1.civ1(ifile,j)={filename}; %first image
            filename=name_generator(filebase_ima2, num2_civ1(ifile),num_b_civ1(j),ext_ima,nom_type_ima2);
            idetect_1(j)=exist(filename,'file')==2;
            filecell.ima2.civ1(ifile,j)={filename};%second image
        end
        [idetectmin,indexj]=min(idetect);
        if idetectmin==0,
            msgbox_uvmat('ERROR',[filecell.ima1.civ1{ifile,indexj} ' not found'])
            filecell={};
           % cd(currentdir)
            return
        end
        [idetectmin,indexj]=min(idetect_1);
        if idetectmin==0,
            msgbox_uvmat('ERROR',[filecell.ima2.civ1{ifile,indexj} ' not found'])
            filecell={};
            %cd(currentdir)
            return
        end
    end
    if strcmp(compare,'stereo PIV') && (strcmp(mode,'pair j1-j2') || strcmp(mode,'series(Dj)') || strcmp(mode,'series(Di)'))
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_A, num1_civ1(ifile),num_a_civ1(j),ext_ima,nom_type_ima1);
                idetect(j)=exist(filename,'file')==2;
                filecell.imaA1.civ1(ifile,j)={filename} ;%first image
                filename=name_generator(filebase_A, num2_civ1(ifile),num_b_civ1(j),ext_ima,nom_type_ima2);
                idetect_1(j)=exist(filename,'file')==2;
                filecell.imaA2.civ1(ifile,j)={filename};%second image
            end
            [idetectmin,indexj]=min(idetect);
            if idetectmin==0,
                msgbox_uvmat('ERROR',[filecell.imaA1.civ1{ifile,indexj} ' not found'])
                filecell={};
               % cd(currentdir)
                return
            end
            [idetectmin,indexj]=min(idetect_1);
            if idetectmin==0,
                msgbox_uvmat('ERROR',[filecell.imaA2.civ1{ifile,indexj} ' not found'])
                filecell={};
               % cd(currentdir)
                return
            end
        end
    end
    
    %%%%%%%%%%%%%  fix1 or patch1 activated but no civ1   %%%%%%%%%%%%%
elseif (box_test(2)==1 || box_test(3)==1);
    for ifile=1:nbfield
        for j=1:nbslice
            filename=name_generator(filebase_nc,num1_civ1(ifile),num_a_civ1(j),'.nc',...
                nom_type_nc,1,num2_civ1(ifile),num_b_civ1(j),subdir_civ1);%
            detect=exist(filename,'file')==2;
            if detect==0
                msgbox_uvmat('ERROR',[filename ' not found'])
                filecell={};
               % cd(currentdir)
                return
            end
            filecell.nc.civ1(ifile,j)={filename};
        end
    end
    if strcmp(compare,'stereo PIV')
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_A,num1_civ1(ifile),num_a_civ1(j),'.nc',nom_type_nc,1,num2_civ1(ifile),num_b_civ1(j),subdir_civ1);%
                filecell.ncA.civ1(ifile,j)={filename};
                if ~exist(filename,'file')
                    msgbox_uvmat('ERROR',['input file ' filename ' not found'])
                    set(handles.RUN, 'Enable','On')
                    set(handles.RUN,'BackgroundColor',[1 0 0])
                    filecell={};
                    %cd(currentdir)
                    return
                end
            end
        end
    end
end

%%%%%%%%%%%%%  if civ2 performed with pairs different than civ1  %%%%%%%%%%%%%
testdiff=0;
if (box_test(4)==1)&&...
        ((get(handles.list_pair_civ1,'Value')~=get(handles.list_pair_civ2,'Value'))||~strcmp(subdir_civ2,subdir_civ1))
    testdiff=1;
    detect=1;
    vers=0;
    subdir_civ2_new=subdir_civ2;
    while detect==1 %create a new subdir if the netcdf files already exist
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_nc,num1_civ2(ifile),num_a_civ2(j),'.nc',nom_type_nc,1,num2_civ2(ifile),num_b_civ2(j),subdir_civ2_new);%
                detect=exist(filename,'file')==2;
                if detect% if a netcdf file already exists
                    indstr=regexp(subdir_civ2,'\D');
                    if indstr(end)<length(subdir_civ2) %subdir_civ1 ends by a number
                        vers=str2double(subdir_civ2(indstr(end)+1:end))+1;
                        subdir_civ2_new=[subdir_civ2(1:indstr(end)) num2str(vers)];
                    else
                        vers=vers+1;
                        subdir_civ2_new=[subdir_civ1 '_' num2str(vers)];
                    end
                    break
                end
                filecell.nc.civ2(ifile,j)={filename};
            end
            if detect% if a netcdf file already exists
                break
            end
        end
        %create the new subdir_civ2_new
        if ~exist(fullfile(Path_ima,subdir_civ2_new),'dir')
            [xx,m2]=mkdir(fullfile(Path_ima,subdir_civ2_new));
            [xx,msg2] = fileattrib(fullfile(Path_ima,subdir_civ2_new),'+w','g'); %yield writing access (+w) to user group (g)
            if ~isequal(m2,'')
                msgbox_uvmat('ERROR',['cannot create ' fullfile(Path_ima,subdir_civ2_new) ': ' m2])
                filecell={};
               % cd(currentdir)
                return
            end
        end
        if strcmp(compare,'stereo PIV')%check second nc series
            for ifile=1:nbfield
                for j=1:nbslice
                    filename=name_generator(filebase_A,num1_civ2(ifile),num_a_civ2(j),'.nc',...
                        nom_type_nc,1,num2_civ2(ifile),num_b_civ1(j),subdir_civ2_new);%
                    detect=exist(filename,'file')==2;
                    if detect% if a netcdf file already exists
                        indstr=regexp(subdir_civ2,'\D');
                        if indstr(end)<length(subdir_civ2) %subdir_civ1 ends by a number
                           vers=str2double(subdir_civ2(indstr(end)+1:end))+1;
                           subdir_civ2_new=[subdir_civ2(1:indstr(end)) num2str(vers)];
                        else
                           vers=vers+1;
                           subdir_civ2_new=[subdir_civ1 '_' num2str(vers)];
                        end
                        break
                    end
                    filecell.ncA.civ2(ifile,j)={filename};
                end
                if detect% if a netcdf file already exists
                    break
                end
            end
            subdir_civ2=subdir_civ2_new;
            %create the new subdir_civ1
            if ~exist(fullfile(Path_ima,subdir_civ2_new),'dir')
                [xx,m2]=mkdir(subdir_civ2_new);
                 [xx,msg2] = fileattrib(fullfile(Path_ima,subdir_civ2_new),'+w','g'); %yield writing access (+w) to user group (g)
                if ~isequal(m2,'')
                    msgbox_uvmat('ERROR', ['cannot create ' fullfile(Path_ima,subdir_civ2_new) ': ' m2])%error message for directory creation
                  %  cd(currentdir)
                    filecell={};
                    return
                end
            end
        end
    end
    subdir_civ2=subdir_civ2_new;
end
%cd(currentdir);%come back to the current working directory

%%%%%%%%%%%%%  if civ2 results are obtained or used  %%%%%%%%%%%%%
if box_test(4)==1 || box_test(5)==1 || box_test(6)==1 %civ2
    %check source netcdf file of civ1 estimates
    if box_test(1)==0; %no civ1 performed
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_nc,num1_civ1(ifile),num_a_civ1(j),'.nc',...
                    nom_type_nc,1,num2_civ1(ifile),num_b_civ1(j),subdir_civ1);%
                filecell.nc.civ1(ifile,j)={filename};% name of the civ1 file
                if ~exist(filename,'file')
                    msgbox_uvmat('ERROR',['input file ' filename ' not found'])
                    filecell={};
                    return
                end
                if ~testdiff % civ2 or patch2 are written in the same file as civ1
                    if box_test(4)==0 ; %check the existence of civ2 if it is not calculated
                        Data=nc2struct(filename,'ListGlobalAttribute','CivStage','civ2');
                        if ~isempty(Data.CivStage) && Data.CivStage<4 %test for civ files
                            msgbox_uvmat('ERROR',['no civ2 data in ' filename])
                            filecell=[];
                            return
                        elseif isempty(Data.civ2)||isequal(Data.civ2,0)
                            msgbox_uvmat('ERROR',['no civ2 data in ' filename])
                            filecell=[];
                            return
                        end
                    elseif box_test(3)==0; %check the existence of patch if it is not calculated
                        Data=nc2struct(filename,'ListGlobalAttribute','CivStage','patch')
                        if ~isempty(Data.CivStage)
                            if Data.CivStage<3 %test for civ files
                                msgbox_uvmat('ERROR',['no patch data in ' filename])
                                filecell=[];
                                return
                            end
                        elseif isempty(Data.patch)||isequal(Data.patch,0)
                            msgbox_uvmat('ERROR',['no patch data in ' filename])
                            filecell=[];
                            return
                        end
                    end
                end
            end
        end
        if strcmp(compare,'stereo PIV')
            for ifile=1:nbfield
                for j=1:nbslice
                    filename=name_generator(filebase_A,num1_civ2(ifile),num_a_civ2(j),'.nc',...
                        nom_type_nc,1,num2_civ2(ifile),num_b_civ2(j),subdir_civ2);%
                    filecell.ncA.civ2(ifile,j)={filename};
                    if ~exist(filename,'file')
                        msgbox_uvmat('ERROR',['input file ' filename ' not found'])
                        set(handles.RUN, 'Enable','On')
                        set(handles.RUN,'BackgroundColor',[1 0 0])
                        return
                    end
                end
            end
        end
    end
    
    detect=1;
    %     while detect==1%creates a new subdir if the netcdf files already contain civ2 data
    for ifile=1:nbfield
        for j=1:nbslice
            filename=name_generator(filebase_nc,num1_civ2(ifile),num_a_civ2(j),'.nc',...
                nom_type_nc,1,num2_civ2(ifile),num_b_civ2(j),subdir_civ2);
            detect=exist(filename,'file')==2;
            filecell.nc.civ2(ifile,j)={filename};
        end
    end
    %get first image names for civ2
    if box_test(1)==1 & isequal(num1_civ1,num1_civ2) & isequal(num_a_civ1,num_a_civ2)
        filecell.ima1.civ2=filecell.ima1.civ1;
    elseif box_test(4)==1
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_ima1, num1_civ2(ifile),num_a_civ2(j),ext_ima,nom_type_ima1);
                idetect_2(j)=exist(filename,'file')==2;
                filecell.ima1.civ2(ifile,j)={filename};%first image
            end
            [idetectmin,indexj]=min(idetect_2);
            if idetectmin==0,
                msgbox_uvmat('ERROR',['input image ' filecell.ima1.civ2{ifile,indexj} ' not found'])
                filecell=[];
                return
            end
        end
    end
    
    %get second image names for civ2
    if box_test(1)==1 & isequal(num2_civ1,num2_civ2) & isequal(num_b_civ1,num_b_civ2)
        filecell.ima2.civ2=filecell.ima2.civ1;
    elseif box_test(4)==1
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_ima2, num2_civ2(ifile),num_b_civ2(j),ext_ima,nom_type_ima2);
                idetect_3(j)=exist(filename,'file')==2;
                filecell.ima2.civ2(ifile,j)={filename};%first image
            end
            [idetectmin,indexj]=min(idetect_3);
            if idetectmin==0,
                msgbox_uvmat('ERROR',['input image ' filecell.ima2.civ2{ifile,indexj} ' not found'])
                filecell=[];
                return
            end
        end
    end
end
if (box_test(5)==1 || box_test(6)==1 ) && box_test(4)==0  % need to read an existing netcdf civ2 file
    if ~testdiff
        filecell.nc.civ2=filecell.nc.civ1;% file already checked
    else     % check the civ2 files
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_nc,num1_civ2(ifile),num_a_civ2(j),'.nc',...
                    nom_type_nc,1,num2_civ2(ifile),num_b_civ2(j),subdir_civ2);%
                filecell.nc.civ2(ifile,j)={filename};
                if ~exist(filename,'file')
                    msgbox_uvmat('ERROR',['input file ' filename ' not found'])
                    filecell=[];
                    return
                else
                    Data=nc2struct(filename,'ListGlobalAttribute','CivStage','civ2');
                    if ~isempty(Data.CivStage) && Data.CivStage<4 %test for civ files
                            msgbox_uvmat('ERROR',['no civ2 data in ' filename])
                            filecell=[];
                            return
                    elseif isempty(Data.civ2)||isequal(Data.civ2,0)
                        msgbox_uvmat('ERROR',['no civ2 data in ' filename])
                        filecell=[];
                        return
                    end
                end
            end
        end
    end
end

%%%%%%%%%%%%%  if stereo fields are calculated by PATCH %%%%%%%%%%%%%
if strcmp(compare,'stereo PIV')
    if  box_test(3)==1 && isequal(get(handles.test_stereo1,'Value'),1)
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_AB,num1_civ1(ifile),num_a_civ1(j),'.nc',...
                    nom_type_nc,1,num2_civ1(ifile),num_b_civ1(j),subdir_civ1);%
                filecell.st(ifile,j)={filename};
            end
        end
    end
    if  box_test(6)==1 && isequal(get(handles.test_stereo2,'Value'),1)
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_AB,num1_civ2(ifile),num_a_civ2(j),'.nc',...
                    nom_type_nc,1,num2_civ2(ifile),num_b_civ2(j),subdir_civ2);%
                filecell.st(ifile,j)={filename};
            end
        end
    end
end
set(handles.subdir_civ1,'String',subdir_civ1);%update the edit box
set(handles.subdir_civ2,'String',subdir_civ2);%update the edit box
browse.nom_type_nc=nom_type_nc;
set(handles.browse_root,'UserData',browse); %update the nomenclature type for uvmat


%COPY IMAGES TO THE FORMAT .png IF NEEDED
if isequal(nom_type_ima1,'*')%case of movie files
    nom_type_imanew1='_i';
else
    nom_type_imanew1=nom_type_ima1;
end
if isequal(nom_type_ima2,'*')%case of movie files
    nom_type_imanew2='_i';
else
    nom_type_imanew2=nom_type_ima2;
end
if ~isequal(ext_ima,'.png')
    %%type of image file
    type_ima1='none';%default
    movieobject1=[];%default
    if strcmpi(ext_ima,'.avi')
        hhh=which('mmreader');
        if ~isequal(hhh,'')&& mmreader.isPlatformSupported()% if the mmreader function is found (recent version of matlab)
            type_ima1='movie';
            movieobject1=mmreader([filebase_ima2 ext_ima]);
        else
            type_ima1='avi';
        end
    elseif ischar(ext_ima) && ~isempty(ext_ima(2:end))
        form=imformats(ext_ima(2:end));
        if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
            if isequal(nom_type_ima1,'*');
                type_ima1='multimage';%image series in a single image file
            else
                type_ima1='image';
            end
        end
    end
    type_ima2='none';%default
    movieobject2=[];
    if strcmpi(ext_ima,'.avi')
        hhh=which('mmreader');
        if ~isequal(hhh,'')&& mmreader.isPlatformSupported()% if the mmreader function is found (recent version of matlab)
            type_ima2='movie';
            movieobject2=mmreader([filebase_ima2 ext_ima]);
        else
            type_ima2='avi';
        end
    elseif ischar(ext_ima) && ~isempty(ext_ima(2:end))
        form=imformats(ext_ima(2:end));
        if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
            if isequal(nom_type_ima1,'*');
                type_ima2='multimage';%image series in a single image file
            else
                type_ima2='image';
            end
        end
    end
    %npxy=get(handles.ImaExt,'UserData');
    % %     if numel(npxy)<2
    %
    %         filename=name_generator(filebase_ima1,num1_civ1(1),num_a_civ1(1),ImaExt,nom_type_ima1);
    %         A=imread(filename);
    %         npxy=size(A);
    % %     end
    %     npy=npxy(1);
    %     npx=npxy(2);
    if box_test(1)==1 %if civ1 is performed
        h = waitbar(0,'copy images to the .png format for civ1');% display a wait bar
        for ifile=1:nbfield
            waitbar(ifile/nbfield);
            for j=1:nbslice
                filename=name_generator(filebase_ima1,num1_civ1(ifile),num_a_civ1(j),'.png',nom_type_imanew1);
                if ~exist(filename,'file')
                    A=read_image(filecell.ima1.civ1{ifile,j},type_ima1,num1_civ1(ifile),movieobject1);
                    imwrite(A,filename,'BitDepth',16);
                end
                filecell.ima1.civ1(ifile,j)={filename};
                filename=name_generator(filebase_ima2, num2_civ1(ifile),num_b_civ1(j),'.png',nom_type_imanew2);
                if ~exist(filename,'file')
                    A=read_image(filecell.ima2.civ1{ifile,j},type_ima2,num2_civ1(ifile),movieobject2);
                    imwrite(A,filename,'BitDepth',16);
                end
                filecell.ima2.civ1(ifile,j)={filename};
            end
        end
        close(h)
    end
    if box_test(4)==1 %if civ2 is performed
        h = waitbar(0,'copy images to the .png format for civ2');% display a wait bar
        for ifile=1:nbfield
            waitbar(ifile/nbfield);
            for j=1:nbslice
                filename=name_generator(filebase_ima1,num1_civ2(ifile),num_a_civ2(j),'.png',nom_type_imanew1);
                if ~exist(filename,'file')
                    A=read_image(cell2mat(filecell.ima1.civ2(ifile,j)),type_ima2,num1_civ2(ifile));
                    imwrite(A,filename,'BitDepth',16);
                end
                filecell.ima1.civ2(ifile,j)={filename};
                filename=name_generator(filebase_ima2, num2_civ2(ifile),num_b_civ2(j),'.png',nom_type_imanew2);
                if ~exist(filename,'file')
                    A=read_image(cell2mat(filecell.ima2.civ2(ifile,j)),type_ima2,num2_civ2(ifile));
                    imwrite(A,filename,'BitDepth',16);
                end
                filecell.ima2.civ2(ifile,j)={filename};
            end
        end
        close(h);
    end
end

%------------------------------------------------------------------------
% --- determine the list of index pairs of processing file
function [num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2]=...
    find_pair_indices(handles,ref_i,ref_j,mode)
%------------------------------------------------------------------------

list_civ1=get(handles.list_pair_civ1,'String');
index_civ1=get(handles.list_pair_civ1,'Value');
str_civ1=list_civ1{index_civ1};%string defining the image pairs for civ1
if isempty(str_civ1)||isequal(str_civ1,'')
    msgbox_uvmat('ERROR','no image pair selected for civ1')
    return
end
list_civ2=get(handles.list_pair_civ2,'String');
index_civ2=get(handles.list_pair_civ2,'Value');
if index_civ2>length(list_civ2)
    list_civ2=list_civ1;
    index_civ2=index_civ1;
end
str_civ2=list_civ2{index_civ2};%string defining the image pairs for civ2

if isequal (mode,'series(Di)')
    lastfield=str2double(get(handles.nb_field,'String'));
    num1_civ1=ref_i-floor(index_civ1/2)*ones(size(ref_i));% set of first image numbers
    num2_civ1=ref_i+ceil(index_civ1/2)*ones(size(ref_i));
    num_a_civ1=ref_j;
    num_b_civ1=ref_j;
    num1_civ2=ref_i-floor(index_civ2/2)*ones(size(ref_i));
    num2_civ2=ref_i+ceil(index_civ2/2)*ones(size(ref_i));
    num_a_civ2=ref_j;
    num_b_civ2=ref_j;   
    
    % adjust the first and last field number
    lastfield=str2double(get(handles.nb_field,'String'));
    if isnan(lastfield)
        indsel=find((num1_civ1 >= 1)&(num1_civ2 >= 1));
    else
        indsel=find((num2_civ1 <= lastfield)&(num2_civ2 <= lastfield)&(num1_civ1 >= 1)&(num1_civ2 >= 1));
    end
    if length(indsel)>=1
        firstind=indsel(1);
        lastind=indsel(end);
        set(handles.first_i,'String',num2str(ref_i(firstind)))%update the display of first and last fields
        set(handles.last_i,'String',num2str(ref_i(lastind)))
        ref_i=ref_i(indsel);
        num1_civ1=num1_civ1(indsel);
        num1_civ2=num1_civ2(indsel);
        num2_civ1=num2_civ1(indsel);
        num2_civ2=num2_civ2(indsel);
    end
elseif isequal (mode,'series(Dj)')
    lastfield_j=str2double(get(handles.nb_field2,'String'));
    num1_civ1=ref_i;% set of first image numbers
    num2_civ1=ref_i;
    num_a_civ1=ref_j-floor(index_civ1/2)*ones(size(ref_j));
    num_b_civ1=ref_j+ceil(index_civ1/2)*ones(size(ref_j));
    num1_civ2=ref_i;
    num2_civ2=ref_i;
    num_a_civ2=ref_j-floor(index_civ2/2)*ones(size(ref_j));
    num_b_civ2=ref_j+ceil(index_civ2/2)*ones(size(ref_j));
    % adjust the first and last field number
    if isnan(lastfield_j)
        indsel=find((num_a_civ1 >= 1)&(num_a_civ2 >= 1));
    else
        indsel=find((num_b_civ1 <= lastfield_j)&(num_b_civ2 <= lastfield_j)&(num_a_civ1 >= 1)&(num_a_civ2 >= 1));
    end
    if length(indsel)>=1
        firstind=indsel(1);
        lastind=indsel(end);
        set(handles.first_j,'String',num2str(ref_j(firstind)))%update the display of first and last fields
        set(handles.last_j,'String',num2str(ref_j(lastind)))
        ref_j=ref_j(indsel);
        num_a_civ1=num_a_civ1(indsel);
        num_b_civ1=num_b_civ1(indsel);
        num_a_civ2=num_a_civ2(indsel);
        num_b_civ2=num_b_civ2(indsel);
    end
elseif isequal(mode,'pair j1-j2') %case of bursts (png_old or png_2D)
    displ_num=get(handles.list_pair_civ1,'UserData');
    num1_civ1=ref_i;
    num2_civ1=ref_i;
    num_a_civ1=displ_num(1,index_civ1);
    num_b_civ1=displ_num(2,index_civ1);
    num1_civ2=ref_i;
    num2_civ2=ref_i;
    num_a_civ2=displ_num(1,index_civ2);
    num_b_civ2=displ_num(2,index_civ2);
elseif isequal(mode,'displacement')
    num1_civ1=ref_i;
    num2_civ1=ref_i;
    num_a_civ1=ref_j;
    num_b_civ1=ref_j;
    num1_civ2=ref_i;
    num2_civ2=ref_i;
    num_a_civ2=ref_j;
    num_b_civ2=ref_j;
end


%------------------------------------------------------------------------
% --- PATCH
function cmd_PATCH=PATCH_CMD(filename_nc,nx_patch,ny_patch,rho_patch,subdomain_patch,thresh_value,test_interp,PatchBin)
%------------------------------------------------------------------------
namelog=[filename_nc(1:end-3) '_patch.log'];
if test_interp==0
    if isunix
    cmd_PATCH=[PatchBin ' -f ' filename_nc ' -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ' -nopt ' subdomain_patch ...
        '  > ' namelog ' 2>&1']; % redirect standard output to the log file
    else
      cmd_PATCH=['"' PatchBin '" -f "' filename_nc '" -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ' -nopt ' subdomain_patch ...
        '  > "' namelog '" 2>&1']; % redirect standard output to the log file
    end
else %nouveau programme patch
    cmd_PATCH=[PatchBin ' -f ' filename_nc ' -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ...
        ' -max ' thresh_value ' -nopt ' subdomain_patch  '  > ' namelog ' 2>&1']; % redirect standard output to the log file
end
cmd_PATCH=regexprep(cmd_PATCH,'\\','\\\\');
%------------------------------------------------------------------------
% --- STEREO Interp
function cmd=RUN_STINTERP(stinterpBin,filename_A_nc,filename_B_nc,filename_nc,nx_patch,ny_patch,rho_patch,subdomain_patch,thresh_value,xmlA,xmlB)
%------------------------------------------------------------------------
namelog=[filename_nc(1:end-3) '_stinterp.log'];
cmd=[stinterpBin ' -f1 ' filename_A_nc  ' -f2 ' filename_B_nc ' -f  ' filename_nc ...
    ' -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ' -nopt ' subdomain_patch ' -c1 ' xmlA ' -c2 ' xmlB '  -xy  x -Nfy 1024 > ' namelog ' 2>&1']; % redirect standard output to the log file

%------------------------------------------------------------------------
% --- Executes on button press in CIV1.
function CIV1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
val=get(handles.CIV1,'Value');
if isequal(val,1)
    enable_civ1(handles,'on')
    enable_pair1(handles,'on')
else
    enable_civ1(handles,'off')
end
find_netcpair_civ1(hObject, eventdata, handles);

%------------------------------------------------------------------------
% --- Executes on button press in FIX1.
function FIX1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
enable_fix1(handles,get(handles.FIX1,'Value'))

%------------------------------------------------------------------------
% --- Executes on button press in PATCH1.
function PATCH1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if get(handles.PATCH1,'Value')==1
    enable_patch1(handles)
else
    desable_patch1(handles)
end

%------------------------------------------------------------------------
% --- Executes on button press in CIV2.
function CIV2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
state=get(handles.CIV2,'Value');
enable_civ2(handles,state)
if state
    find_netcpair_civ2(hObject, eventdata, handles)
    enable_pair1(handles,'on')
end

%------------------------------------------------------------------------
% --- Executes on button press in FIX2.
function FIX2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if get(handles.FIX2,'Value')==1
    enable_fix2(handles)
    if get(handles.CIV2,'Value')==0
        find_netcpair_civ2(hObject, eventdata, handles) % select the available netcdf files
    end
else
    desable_fix2(handles)
end

%------------------------------------------------------------------------
% --- Executes on button press in PATCH2.
function PATCH2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if get(handles.PATCH2,'Value')==1
    enable_patch2(handles)
    if get(handles.CIV2,'Value')==0
        find_netcpair_civ2(hObject, eventdata, handles) % select the available netcdf files
    end
else
    desable_patch2(handles)
end

%------------------------------------------------------------------------
function first_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% last_i_Callback(hObject, eventdata, handles)
first_i=str2double(get(handles.first_i,'String'));
% last_i=str2num(get(handles.last_i,'String'));
% ref_i=ceil((first_i+last_i)/2);
set(handles.ref_i,'String', num2str(first_i))% reference index for pair dt = first index
set(handles.ref_i_civ2,'String', num2str(first_i))% reference index for pair dt = first index
ref_i_Callback(hObject, eventdata, handles)%refresh dispaly of dt for pairs (in case of non constant dt)

%------------------------------------------------------------------------
function first_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
first_j=str2num(get(handles.first_j,'String'));
set(handles.ref_j,'String', num2str(first_j))% reference index for pair dt = first index
ref_j_Callback(hObject, eventdata, handles)%refresh dispaly of dt for pairs (in case of non constant dt)

%------------------------------------------------------------------------
% --- Executes on button press in calcul_search: determine the search range isx,isy
function calcul_search_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%determine pair numbers
list_pair=get(handles.list_pair_civ1,'String');%get the menu of image pairs
index=get(handles.list_pair_civ1,'Value');
displ_num=get(handles.list_pair_civ1,'UserData');
time=get(handles.RootName,'UserData'); %get the set of times
pxcm_xy=get(handles.calcul_search,'UserData');
pxcmx=pxcm_xy(1);
pxcmy=pxcm_xy(2);
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if isequal (mode, 'series(Di)' )
    ref_i=str2double(get(handles.ref_i,'String'));
    num1=ref_i-floor(index/2);%  first image numbers
    num2=ref_i+ceil(index/2);
    num_a=1;
    num_b=1;
elseif isequal (mode, 'series(Dj)')
    num1=1;
    num2=1;
    ref_j=str2double(get(handles.ref_j,'String'));
    num_a=ref_j-floor(index/2);%  first image numbers
    num_b=ref_j+ceil(index/2);
elseif isequal(mode,'pair j1-j2') %case of bursts (png_old or png_2D)
    ref_i=str2double(get(handles.ref_i,'String'));
    num1=ref_i;
    num2=ref_i;
    num_a=displ_num(1,index);
    num_b=displ_num(2,index);
end
dt=time(num2,num_b)-time(num1,num_a);
ibx=str2double(get(handles.ibx,'String'));
iby=str2double(get(handles.iby,'String'));
umin=dt*pxcmx*str2double(get(handles.umin,'String'));
umax=dt*pxcmx*str2double(get(handles.umax,'String'));
vmin=dt*pxcmy*str2double(get(handles.vmin,'String'));
vmax=dt*pxcmy*str2double(get(handles.vmax,'String'));
shiftx=round((umin+umax)/2);
shifty=round((vmin+vmax)/2);
isx=(umax+2-shiftx)*2+ibx;
isx=2*ceil(isx/2)+1;
isy=(vmax+2-shifty)*2+iby;
isy=2*ceil(isy/2)+1;
set(handles.shiftx,'String',num2str(shiftx));
set(handles.shifty,'String',num2str(shifty));
set(handles.isx,'String',num2str(isx));
set(handles.isy,'String',num2str(isy));

%------------------------------------------------------------------------
% --- Executes on carriage return on the subdir civ1 edit window
function subdir_civ1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
subdir=get(handles.subdir_civ1,'String');
set(handles.subdir_civ2,'String',subdir);
if get(handles.CIV1,'Value')==0
    find_netcpair_civ1(hObject, eventdata, handles); %update the list of available pairs from netcdf files in the new directory
end

%------------------------------------------------------------------------
% --- Executes on carriage return on the subdir civ1 edit window
function subdir_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%update the list of available pairs from netcdf files in the new directory
if get(handles.CIV2,'Value')==0 & get(handles.CIV1,'Value')==0 & get(handles.FIX1,'Value')==0 & get(handles.PATCH1,'Value')==0
    find_netcpair_civ2(hObject, eventdata, handles);
end

%------------------------------------------------------------------------
% --- Executes on button press in get_mask_civ1: select box for mask option
function get_mask_civ1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.get_mask_civ1,'Value')
if isequal(maskval,0)
    set(handles.mask_civ1,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootName,'String');
    [ nbslice_mask, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice_mask) 'mask'];
    elseif get(handles.compare,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        common_path=fileparts(filebase);
        filebase_a=fullfile(common_path,get(handles.RootName_1,'String'));
        [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles);
        if isequal(flag_mask_a,0) || ~isequal(nbslice_a,nbslice_mask)
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.png', ' (*.png)';
            '*.png',  '.png files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a mask file *.png',filebase);
        mask_displ=fullfile(PathName,FileName);
        if ~exist(mask_displ,'file')
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        set(handles.get_mask_civ1,'Value',0)
        set(handles.get_mask_fix1,'Value',0)
        set(handles.get_mask_civ2,'Value',0)
        set(handles.get_mask_fix2,'Value',0)
    else
        set(handles.get_mask_fix1,'Value',1)
        set(handles.get_mask_fix2,'Value',1)
    end
    set(handles.mask_civ1,'String',mask_displ)
    set(handles.mask_fix1,'String',mask_displ)
    set(handles.mask_civ2,'String',mask_displ)
    set(handles.mask_fix2,'String',mask_displ)
end
set(handles.get_mask_civ2,'Value',maskval)%update the civ2 mask with the same option as civ1

%------------------------------------------------------------------------
% --- Executes on button press in get_mask_fix1.
function get_mask_fix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.get_mask_fix1,'Value');
if isequal(maskval,0)
    set(handles.mask_fix1,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootName,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.compare,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.RootName_1,'String');
        [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles);
        if isequal(flag_mask_a,0) || ~isequal(nbslice_a,nbslice)
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.png', ' (*.png)';
            '*.png',  '.png files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a mask file *.png',filebase);
        mask_displ=fullfile(PathName,FileName);
        if ~exist(mask_displ,'file')
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        set(handles.get_mask_fix1,'Value',0)
        set(handles.get_mask_civ2,'Value',0)
        set(handles.get_mask_fix2,'Value',0)
    else
        %set(handles.get_mask_civ2,'Value',1)
        set(handles.get_mask_fix2,'Value',1)
    end
    set(handles.mask_fix1,'String',mask_displ)
    set(handles.mask_civ2,'String',mask_displ)
    set(handles.mask_fix2,'String',mask_displ)
end

%------------------------------------------------------------------------
% --- Executes on button press in get_mask_civ2: select box for mask option
function get_mask_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.get_mask_civ2,'Value');
if isequal(maskval,0)
    set(handles.mask_civ2,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootName,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.compare,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.RootName_1,'String');
        [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles);
        if isequal(flag_mask_a,0) || ~isequal(nbslice_a,nbslice)
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.png', ' (*.png)';
            '*.png',  '.png files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a mask file *.png',filebase);
        mask_displ=fullfile(PathName,FileName);
        if ~exist(mask_displ,'file')
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        set(handles.get_mask_civ2,'Value',0)
        set(handles.get_mask_fix2,'Value',0)
    else
        set(handles.get_mask_fix2,'Value',1)
    end
    set(handles.mask_civ2,'String',mask_displ)
    set(handles.mask_fix2,'String',mask_displ)
end

%------------------------------------------------------------------------
% --- Executes on button press in get_mask_fix2.
function get_mask_fix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.get_mask_fix2,'Value');
if isequal(maskval,0)
    set(handles.mask_fix2,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootName,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.compare,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.RootName_1,'String');
        [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles);
        if isequal(flag_mask_a,0) || ~isequal(nbslice_a,nbslice)
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.png', ' (*.png)';
            '*.png',  '.png files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a mask file *.png',filebase);
        mask_displ=fullfile(PathName,FileName);
        if ~exist(mask_displ,'file')
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        set(handles.get_mask_fix2,'Value',0)
    end
    set(handles.mask_fix2,'String',mask_displ)
end

%------------------------------------------------------------------------
% --- function called to look for mask files
function [nbslice, flag_mask]=get_mask(filebase,handles)
%------------------------------------------------------------------------
%detect mask files, images with appropriate file base
%[filebase '_' xx 'mask'], xx=nbslice
%flag_mask=1 indicates detection

flag_mask=0;%default
nbslice=1;

% subdir=get(handles.subdir_civ1,'String');
[Path,Name]=fileparts(filebase);
if ~isdir(Path)
    msgbox_uvmat('ERROR','no path for input files')
    return
end
currentdir=pwd;
cd(Path);%move in the dir of the root name filebase
maskfiles=dir([Name '_*mask_*.png']);%look for mask files
cd(currentdir);%come back to the current working directory
if ~isempty(maskfiles)
    %     msgbox_uvmat('ERROR','no mask available, to create it use Tools/Make mask in the upper menu bar of uvmat')
    % else
    flag_mask=1;
    maskname=maskfiles(1).name;% take the first mask file in the list
    [Path2,Name,ext]=fileparts(maskname);
    Namedouble=double(Name);
    val=(48>Namedouble)|(Namedouble>57);% select the non-numerical characters
    ind_mask=findstr('mask',Name);
    i=ind_mask-1;
    while val(i)==0 && i>0
        i=i-1;
    end
    nbslice=str2double(Name(i+1:ind_mask-1));
    if ~isnan(nbslice) && Name(i)=='_'
        flag_mask=1;
    else
        msgbox_uvmat('ERROR',['bad mask file ' Name ext ' found in ' Path2])
        return
        nbslice=1;
    end
end

%------------------------------------------------------------------------
% --- function called to look for grid files
function [nbslice, flag_mask]=get_grid(filebase,handles)
%------------------------------------------------------------------------
flag_mask=0;%default
nbslice=1;
[Path,Name]=fileparts(filebase);
currentdir=pwd;
cd(Path);%move in the dir of the root name filebase
maskfiles=dir([Name '_*grid_*.grid']);%look for mask files
cd(currentdir);%come back to the current working directory
if ~isempty(maskfiles)
    flag_mask=1;
    maskname=maskfiles(1).name;% take the first mask file in the list
    [Path2,Name,ext]=fileparts(maskname);
    Namedouble=double(Name);
    val=(48>Namedouble)|(Namedouble>57);% select the non-numerical characters
    ind_mask=findstr('grid',Name);
    i=ind_mask-1;
    while val(i)==0 && i>0
        i=i-1;
    end
    nbslice=str2double(Name(i+1:ind_mask-1));
    if ~isnan(nbslice) && Name(i)=='_'
        flag_mask=1;
    else
        msgbox_uvmat('ERROR',['bad grid file ' Name ext ' found in ' Path2])
        return
        nbslice=1;
    end
end

%------------------------------------------------------------------------
% --- transform numbers to letters
function str=num2stra(num,nom_type)
%------------------------------------------------------------------------
if isempty(nom_type)
    str='';
elseif strcmp(nom_type(end),'a')
    str=char(96+num);
elseif strcmp(nom_type(end),'A')
    str=char(96+num);
elseif isempty(nom_type(2:end))%a single index
    str='';
else
    str=num2str(num);
end

%------------------------------------------------------------------------
% --- Executes on button press in list_subdir_civ1.
function list_subdir_civ1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
list_subdir_civ1=get(handles.list_subdir_civ1,'String');
val=get(handles.list_subdir_civ1,'Value');
if val>1
    subdir=list_subdir_civ1{val};
    set(handles.subdir_civ1,'String',subdir);
    set(handles.list_subdir_civ1,'Value',1);
end

%------------------------------------------------------------------------
% --- Executes on button press in list_subdir_civ2.
function list_subdir_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
list_subdir_civ2=get(handles.list_subdir_civ2,'String');
val=get(handles.list_subdir_civ2,'Value');
if val>1
    subdir=list_subdir_civ2{val};
    set(handles.subdir_civ2,'String',subdir);
    set(handles.list_subdir_civ2,'Value',1);
end

%------------------------------------------------------------------------
% --- Executes on button press in browse_gridciv1.
function browse_gridciv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
value=get(handles.browse_gridciv1,'Value');
testgrid=0;
if value
    filebase=get(handles.RootName,'String');
    [nbslice, flag_grid]=get_grid(filebase,handles);
    if isequal(flag_grid,1)
        filegrid=[num2str(nbslice) 'grid'];
        testgrid=1;
    else
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.grid', ' (*.grid)';
            '*.grid',  '.grid files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a file',filebase);
        filegrid=fullfile(PathName,FileName);
        if ~(isempty(FileName)||isempty(PathName)||isequal(FileName,0)||~exist(filegrid,'file'))
            testgrid=1;
        end
    end
end
if testgrid
    set(handles.browse_gridciv2,'Value',1)
    set(handles.get_gridpatch1,'Value',1)
    set(handles.get_gridpatch2,'Value',1)
    set(handles.dx_civ1,'Visible','off');
    set(handles.dy_civ1,'Visible','off');
    set(handles.dx_civ2,'Visible','off');
    set(handles.dy_civ2,'Visible','off');
    set(handles.grid_civ1,'String',filegrid)
    set(handles.grid_patch1,'String',filegrid)
    set(handles.grid_civ2,'String',filegrid)
    set(handles.grid_patch2,'String',filegrid)
else
    set(handles.browse_gridciv1,'Value',0);
    set(handles.browse_gridciv2,'Value',0);
    set(handles.get_gridpatch1,'Value',0)
    set(handles.get_gridpatch2,'Value',0)
    set(handles.dx_civ1,'Visible','on');
    set(handles.dy_civ1,'Visible','on');
    set(handles.dx_civ2,'Visible','on');
    set(handles.dy_civ2,'Visible','on');
    set(handles.grid_civ1,'String','')
    set(handles.grid_patch1,'String','')
    set(handles.grid_civ2,'String','')
    set(handles.grid_patch2,'String','')
end

%------------------------------------------------------------------------
% --- Executes on button press in browse_gridciv1.
function browse_gridciv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
value=get(handles.browse_gridciv2,'Value');
if value
    filebase=get(handles.RootName,'String');
    [nbslice, flag_grid]=get_grid(filebase,handles);
    if isequal(flag_grid,1)
        mask_displ=[num2str(nbslice) 'grid'];
        set(handles.grid_civ2,'String',mask_displ)
        set(handles.dx_civ2,'Visible','off');
        set(handles.dy_civ2,'Visible','off');
    else
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.grid', ' (*.grid)';
            '*.grid',  '.grid files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a file',filebase);
        filegrid=fullfile(PathName,FileName);
        if isempty(FileName)||isempty(PathName)||isequal(FileName,0)||~exist(filegrid,'file')
            set(handles.browse_gridciv2,'Value',0);
            set(handles.grid_civ2,'string','');
            set(handles.dx_civ2,'Visible','on');
            set(handles.dy_civ2,'Visible','on');
            set(handles.grid_civ2,'string','');
        else
            set(handles.grid_civ2,'string',filegrid);
            set(handles.dx_civ2,'Visible','off');
            set(handles.dy_civ2,'Visible','off');
            set(handles.grid_civ2,'string',filegrid);
        end
    end
else
    set(handles.grid_civ2,'string','');
    set(handles.dx_civ2,'Visible','on');
    set(handles.dy_civ2,'Visible','on');
    set(handles.grid_civ2,'string','');
end

% % --- Executes on button press in browse_gridciv2.
% function browse_gridciv2_Callback(hObject, eventdata, handles)
%
% filebase=get(handles.RootName,'String');
% [FileName, PathName, filterindex] = uigetfile( ...
%        {'*.grid', ' (*.grid)';
%         '*.grid',  '.grid files '; ...
%         '*.*', 'All Files (*.*)'}, ...
%         'Pick a file',filebase);
% filegrid=fullfile(PathName,FileName);
% set(handles.grid_civ2,'string',filegrid);
% set(handles.dx_civ2,'String',' ');
% set(handles.dy_civ2,'String',' ');
% % set(handles.grid_patch2,'string',filegrid);

% --- Executes on button press in get_gridpatch1.
function get_gridpatch1_Callback(hObject, eventdata, handles)
% hObject    handle to get_gridpatch1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

filebase=get(handles.RootName,'String');
[FileName, PathName, filterindex] = uigetfile( ...
    {'*.grid', ' (*.grid)';
    '*.grid',  '.grid files '; ...
    '*.*', 'All Files (*.*)'}, ...
    'Pick a file',filebase);
filegrid=fullfile(PathName,FileName);
set(handles.grid_patch1,'string',filegrid);
% set(handles.grid_patch2,'string',filegrid

%------------------------------------------------------------------------
% --- Executes on button press in get_gridpatch2.
function get_gridpatch2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function enable_civ1(handles,state)
%------------------------------------------------------------------------
if isequal(state,'on')
    set(handles.frame_civ1,'BackgroundColor',[1 1 0])
    set(handles.frame_para_civ1,'BackgroundColor',[1 1 0])
    set(handles.frame_grid_civ1,'BackgroundColor',[1 1 0])
else
    set(handles.frame_civ1,'BackgroundColor',[0.831 0.816 0.784])
    set(handles.frame_para_civ1,'BackgroundColor',[0.831 0.816 0.784])
    set(handles.frame_grid_civ1,'BackgroundColor',[0.831 0.816 0.784])
end
set(handles.ibx,'Visible',state)
set(handles.iby,'Visible',state)
set(handles.isx,'Visible',state)
set(handles.isy,'Visible',state)
set(handles.shiftx,'Visible',state)
set(handles.shifty,'Visible',state)
set(handles.rho,'Visible',state)
set(handles.dx_civ1,'Visible',state)
set(handles.dy_civ1,'Visible',state)
set(handles.calcul_search,'Visible',state)
set(handles.u_text,'Visible',state)
set(handles.v_text,'Visible',state)
set(handles.min,'Visible',state)
set(handles.max,'Visible',state)
set(handles.umin,'Visible',state)
set(handles.umax,'Visible',state)
set(handles.vmin,'Visible',state)
set(handles.vmax,'Visible',state)
set(handles.grid_civ1,'Visible',state)
set(handles.mask_civ1,'Visible',state)
set(handles.browse_gridciv1,'Visible',state)
set(handles.get_mask_civ1,'Visible',state)
set(handles.parameters,'Visible',state)
set(handles.grid,'Visible',state)
set(handles.dx_civ1,'Visible',state)
set(handles.dy_civ1,'Visible',state)
set(handles.ImaThreshold,'Visible',state)
if isequal(state,'off')
    set(handles.MinIma,'Visible','off')
    set(handles.MaxIma,'Visible','off')
    set(handles.ImaThreshold,'Value',0)
end
set(handles.dx_civ1_title,'Visible',state)
set(handles.dy_civ1_title,'Visible',state)
set(handles.ImaThreshold_title,'Visible',state)
set(handles.ib_title,'Visible',state)
set(handles.is_title,'Visible',state)
set(handles.shift_title,'Visible',state)
set(handles.rho_title,'Visible',state)
set(handles.TestCiv1,'Visible',state)
%set(handles.CivMode,'Visible',state)

%------------------------------------------------------------------------
function enable_fix1(handles,state)
%------------------------------------------------------------------------
if isequal(state,0)
    state='off';
end
if isequal(state,1)
    state='on';
end
if isequal(state,'on')
    set(handles.frame_fix1,'BackgroundColor',[1 1 0])
else
    set(handles.frame_fix1,'BackgroundColor',[0.7 0.7 0.7])
end
set(handles.REMOVE,'Visible',state)
set(handles.vec_Fmin2,'Visible',state)
set(handles.vec_F2,'Visible',state)
set(handles.vec_F3,'Visible',state)
set(handles.thresh_vecC,'Visible',state)
set(handles.thresh_vecC_title,'Visible',state)
set(handles.thresh_vel,'Visible',state)
set(handles.thresh_vel_text,'Visible',state)
set(handles.mask_fix1,'Visible',state)
set(handles.get_mask_fix1,'Visible',state)
set(handles.get_ref_fix1,'Visible',state)
set(handles.ref_fix1,'Visible',state)
set(handles.inf_sup1,'Visible',state)
set(handles.field_ref1,'Visible',state)

%------------------------------------------------------------------------
function enable_patch1(handles)
%------------------------------------------------------------------------
set(handles.frame_patch1,'BackgroundColor',[1 1 0])
set(handles.rho_patch1,'Visible','on')
set(handles.rho_text1,'Visible','on')
if get(handles.CivMode,'Value')==2
    set(handles.thresh_patch1,'Visible','on')
    set(handles.thresh_text1,'Visible','on')
end
set(handles.subdomain_patch1,'Visible','on')
set(handles.subdomain_text1,'Visible','on')
set(handles.nx_patch1,'Visible','on')
set(handles.ny_patch1,'Visible','on')
set(handles.nx_patch1_title,'Visible','on')
set(handles.ny_patch1_title,'Visible','on')
% if ~isempty(patch_newBin)
set(handles.test_interp,'Visible','off');
stereo_test=get(handles.compare,'Value');
if stereo_test==3
    set(handles.test_stereo1,'Visible','on')
end
% end
%set(handles.get_gridpatch1,'Visible','on')
%set(handles.grid_patch1,'string','none');
%set(handles.grid_patch1,'Visible','on')

%------------------------------------------------------------------------
function desable_patch1(handles)
%------------------------------------------------------------------------
set(handles.frame_patch1,'BackgroundColor',[0.831 0.816 0.784])
set(handles.rho_patch1,'Visible','off')
set(handles.rho_text1,'Visible','off')
set(handles.thresh_patch1,'Visible','off')
set(handles.thresh_text1,'Visible','off')
set(handles.subdomain_patch1,'Visible','off')
set(handles.subdomain_text1,'Visible','off')
set(handles.nx_patch1,'Visible','off')
set(handles.ny_patch1,'Visible','off')
set(handles.nx_patch1_title,'Visible','off')
set(handles.ny_patch1_title,'Visible','off')
set(handles.test_stereo1,'Visible','off')
%set(handles.test_interp,'Visible','off')
%set(handles.get_gridpatch1,'Visible','off')
%set(handles.grid_patch1,'Visible','off')

%------------------------------------------------------------------------
function enable_civ2(handles,state)
%------------------------------------------------------------------------
if isequal(state,0)
    state='off';
end
if isequal(state,1)
    state='on';
end
if isequal(state,'on')
    set(handles.frame_civ2,'BackgroundColor',[1 1 0])
    set(handles.frame_para_civ2,'BackgroundColor',[1 1 0])
    set(handles.frame_grid_civ2,'BackgroundColor',[1 1 0])
    set(handles.frame_subdirciv2,'BackgroundColor',[1 1 0])
else
    set(handles.frame_civ2,'BackgroundColor',[0.831 0.816 0.784])
    set(handles.frame_para_civ2,'BackgroundColor',[0.831 0.816 0.784])
    set(handles.frame_grid_civ2,'BackgroundColor',[0.831 0.816 0.784])
    set(handles.frame_subdirciv2,'BackgroundColor',[0.831 0.816 0.784])
end
set(handles.ibx_civ2,'Visible',state)
set(handles.iby_civ2,'Visible',state)
set(handles.decimal,'Visible',state)
set(handles.deformation,'Visible',state)
set(handles.rho_civ2,'Visible',state)
set(handles.dx_civ2,'Visible',state)
set(handles.dy_civ2,'Visible',state)
set(handles.browse_gridciv2,'Visible',state)
set(handles.get_mask_civ2,'Visible',state)
set(handles.parameters,'Visible',state)
set(handles.grid,'Visible',state)
set(handles.parameters_text,'Visible',state)
set(handles.grid_text,'Visible',state)
set(handles.grid_civ2,'Visible',state)
set(handles.mask_civ2,'Visible',state)
set(handles.dx_civ2_title,'Visible',state)
set(handles.dy_civ2_title,'Visible',state)
set(handles.ibx_civ2_text,'Visible',state)
set(handles.rho_civ2_title,'Visible',state)
set(handles.ImaThreshold2,'Visible',state)
set(handles.ImaThreshold_title2,'Visible',state)
if isequal(state,'off')
    set(handles.MinIma2,'Visible','off')
    set(handles.MaxIma2,'Visible','off')
    set(handles.ImaThreshold2,'Value',0)
    if isequal(get(handles.FIX2,'Value'),0) & isequal(get(handles.PATCH2,'Value'),0)
        set(handles.list_pair_civ2,'Visible','off')
        set(handles.subdir_civ2,'Visible','off')
        set(handles.subdir_civ2_text,'Visible','off')
        set(handles.dt_unit_civ2,'Visible','off')
        set(handles.ref_i_civ2,'Visible','off')
        set(handles.i_ref_civ2_title,'Visible','off')
        set(handles.j_ref_civ2_title,'Visible','off')
        set(handles.ref_j_civ2,'Visible','off')
    end
else
    set(handles.list_pair_civ2,'Visible','on')
    set(handles.subdir_civ2,'Visible','on')
    set(handles.subdir_civ2_text,'Visible','on')
    set(handles.dt_unit_civ2,'Visible','on')
    set(handles.ref_i_civ2,'Visible','on')
    set(handles.i_ref_civ2_title,'Visible','on')
    set(handles.j_ref_civ2_title,'Visible','on')
    set(handles.ref_j_civ2,'Visible','on')
end
set(handles.rho_civ2_title,'Visible',state)

%------------------------------------------------------------------------
function enable_fix2(handles)
%------------------------------------------------------------------------
set(handles.frame_fix2,'BackgroundColor',[1 1 0])
set(handles.REMOVE2,'Visible','on')
set(handles.vec_Fmin2_2,'Visible','on')
set(handles.vec_F4,'Visible','on')
set(handles.vec_F3_2,'Visible','on')
set(handles.thresh_vec2C,'Visible','on')
set(handles.thresh_vec2C_text,'Visible','on')
set(handles.thresh_vel2,'Visible','on')
set(handles.thresh_vel2_text,'Visible','on')
set(handles.mask_fix2,'Visible','on')
set(handles.get_mask_fix2,'Visible','on')
set(handles.list_pair_civ2,'Visible','on')
set(handles.subdir_civ2,'Visible','on')
set(handles.subdir_civ2_text,'Visible','on')
set(handles.get_ref_fix2,'Visible','on')
set(handles.ref_fix2,'Visible','on')
set(handles.inf_sup2,'Visible','on')
set(handles.field_ref2,'Visible','on')

%------------------------------------------------------------------------
function desable_fix2(handles)
%------------------------------------------------------------------------
set(handles.frame_fix2,'BackgroundColor',[0.831 0.816 0.784])
set(handles.REMOVE2,'Visible','off')
set(handles.vec_Fmin2_2,'Visible','off')
set(handles.vec_F4,'Visible','off')
set(handles.vec_F3_2,'Visible','off')
set(handles.thresh_vec2C,'Visible','off')
set(handles.thresh_vec2C_text,'Visible','off')
set(handles.thresh_vel2,'Visible','off')
set(handles.thresh_vel2_text,'Visible','off')
set(handles.mask_fix2,'Visible','off')
set(handles.get_mask_fix2,'Visible','off')
set(handles.get_ref_fix2,'Visible','off')
set(handles.ref_fix2,'Visible','off')
set(handles.inf_sup2,'Visible','off')
set(handles.field_ref2,'Visible','off')
if isequal(get(handles.CIV2,'Value'),0) & isequal(get(handles.PATCH2,'Value'),0)
    set(handles.list_pair_civ2,'Visible','off')
    set(handles.subdir_civ2,'Visible','off')
    set(handles.subdir_civ2_text,'Visible','off')
end

%------------------------------------------------------------------------
function enable_patch2(handles)
%------------------------------------------------------------------------
set(handles.frame_patch2,'BackgroundColor',[1 1 0])
set(handles.rho_patch2,'Visible','on')
set(handles.rho_text2,'Visible','on')
set(handles.thresh_patch2,'Visible','on')
set(handles.thresh_text2,'Visible','on')
set(handles.subdomain_patch2,'Visible','on')
set(handles.subdomain_text2,'Visible','on')
set(handles.nx_patch2,'Visible','on')
set(handles.ny_patch2,'Visible','on')
set(handles.nx_patch2_title,'Visible','on')
set(handles.ny_patch2_title,'Visible','on')
% set(handles.get_gridpatch2,'Visible','on')
% set(handles.grid_patch2,'Visible','on')
set(handles.list_pair_civ2,'Visible','on')
set(handles.subdir_civ2,'Visible','on')
set(handles.subdir_civ2_text,'Visible','on')
stereo_test=get(handles.compare,'Value');
if stereo_test==3
    set(handles.test_stereo2,'Visible','on')
end

%------------------------------------------------------------------------
function desable_patch2(handles)
%------------------------------------------------------------------------
set(handles.frame_patch2,'BackgroundColor',[0.831 0.816 0.784])
set(handles.rho_patch2,'Visible','off')
set(handles.rho_text2,'Visible','off')
set(handles.thresh_patch2,'Visible','off')
set(handles.thresh_text2,'Visible','off')
set(handles.subdomain_patch2,'Visible','off')
set(handles.subdomain_text2,'Visible','off')
set(handles.nx_patch2,'Visible','off')
set(handles.ny_patch2,'Visible','off')
set(handles.nx_patch2_title,'Visible','off')
set(handles.ny_patch2_title,'Visible','off')
% set(handles.get_gridpatch2,'Visible','off')
% set(handles.grid_patch2,'Visible','off')
if isequal(get(handles.CIV2,'Value'),0) & isequal(get(handles.FIX2,'Value'),0)
    set(handles.list_pair_civ2,'Visible','off')
    set(handles.subdir_civ2,'Visible','off')
    set(handles.subdir_civ2_text,'Visible','off')
end
set(handles.test_stereo2,'Visible','off')
%------------------------------------------------------------------------
function enable_pair1(handles,state)
%------------------------------------------------------------------------
set(handles.subdir_civ1,'Visible',state)
set(handles.list_subdir_civ1,'Visible',state)
set(handles.SUBDIR_CIV1_txt,'Visible',state)
set(handles.frame_subdirciv1,'Visible',state)
set(handles.list_pair_civ1,'Visible',state)
set(handles.PAIR_txt,'Visible',state)
%set(handles.dt_unit,'Visible',state)
set(handles.PAIR_frame,'Visible',state)

%------------------------------------------------------------------------
% --- Read the parameters for civ1 on the interface
function par=read_param_civ1(handles,file_ima)
%------------------------------------------------------------------------
ibx_val=str2double(get(handles.ibx,'String'));
par.ibx=num2str(ibx_val);
iby_val=str2double(get(handles.iby,'String'));
par.iby=num2str(iby_val);
isx=get(handles.isx,'String');
if isnan(str2double(isx)), isx='41'; set(handles.isx,'String','41'), end; %default
if str2double(isx)<ibx_val+8,isx=num2str(ibx_val+8); set(handles.isx,'String',num2str(ibx_val+8)); end
isy=get(handles.isy,'String');
if isnan(str2double(isy)), isy='41'; set(handles.isy,'String','41'), end;%default
if str2double(isy)<iby_val+8,isy=num2str(iby_val+8); set(handles.isy,'String',num2str(iby_val+8)); end
par.isx=get(handles.isx,'String');
par.isy=get(handles.isy,'String');
par.shiftx=get(handles.shiftx,'String');
par.shifty=get(handles.shifty,'String');
if isnan(str2double(par.isx))
    par.isx='41';%default
    set(handles.isx,'String','41');
end
if isnan(str2double(par.isy))
    par.isy='41'; %default
    set(handles.isy,'String','41');
end
if isnan(str2double(par.shiftx))
    par.shiftx='0';%default
    set(handles.shiftx,'String','0');
end
if isnan(str2double(par.shifty))
    par.shifty='0'; %default
    set(handles.shifty,'String','0');
end
par.rho=get(handles.rho,'String');
if isequal(get(handles.rho,'Style'),'popupmenu')
    index=get(handles.rho,'Value');
    par.rho=par.rho{index};
end
par.dx=get(handles.dx_civ1,'String');
par.dy=get(handles.dy_civ1,'String');
if isnan(str2double(par.dx))
    if isempty(get(handles.grid_civ1,'String'));
        par.dx='0'; %just read by civ program, not used
    else
        par.dx='20';%default
        set(handles.dx_civ1,'String','20');
    end
end
if isnan(str2double(par.dy))
    if isempty(get(handles.grid_civ1,'String'));
        par.dy='0';%just read by civ program, not used
    else
        par.dy='20';%default
        set(handles.dy_civ1_title,'String','20');
    end
end
par.pxcmx='1'; %velocities are expressed in pixel dispalcement
par.pxcmy='1';
if exist('file_ima','var')
A=imread(file_ima);%read the first image to get the size
sizim=size(A);
par.npx=num2str(sizim(2));
par.npy=num2str(sizim(1));
end
%time=get(handles.RootName,'UserData'); %get the set of times
par.gridname=get(handles.grid_civ1,'String');
par.gridflag='y';
if strcmp(par.gridname,'')|| isempty(par.gridname)
    par.gridname='nogrid';
    par.gridflag='n';
end

%------------------------------------------------------------------------
function par=read_param_civ2(handles,file_ima)
%------------------------------------------------------------------------
par.ibx=get(handles.ibx_civ2,'String');
par.iby=get(handles.iby_civ2,'String');
par.rho=get(handles.rho_civ2,'String');
par.decimal=int2str(get(handles.decimal,'Value'));
par.deformation=int2str(get(handles.deformation,'Value'));
par.dx=get(handles.dx_civ2,'String');
par.dy=get(handles.dy_civ2,'String');
if isnan(str2double(par.dx))
    if isempty(get(handles.grid_civ2,'String'));
        par.dx='0'; %just read by civ program, not used
    else
        par.dx='20';%default
        set(handles.dx_civ2,'String','20');
    end
end
if isnan(str2double(par.dy))
    if isempty(get(handles.grid_civ2,'String'));
        par.dy='0';%just read by civ program, not used
    else
        par.dy='20';%default
        set(handles.dy_civ2,'String','20');
    end
end
par.pxcmx='1';
par.pxcmy='1';
A=imread(file_ima);%read the first image to get the size
sizim=size(A);
par.npx=num2str(sizim(2));
par.npy=num2str(sizim(1));
%time=get(handles.RootName,'UserData'); %get the set of times
par.gridname=get(handles.grid_civ2,'String');
par.gridflag='y';
if strcmp(par.gridname,'')|| isempty(par.gridname)
    par.gridname='nogrid';
    par.gridflag='n';
end

%------------------------------------------------------------------------
% --- CIV1  CIV1  CIV1 CIV1
function cmd_CIV1=CIV1_CMD(filename,namelog,par,handles,sparam)
%------------------------------------------------------------------------
%pixels per cm and matrix of the image times, read from the .civ file by uvmat

%changes : filename_cmx -> filename ( no extension )
% input namelog not used
if isequal(par.Dt,'0')
    par.Dt='1' ;%case of 'displacement' mode
end
par.filename_ima_a=regexprep(par.filename_ima_a,'.png','');
par.filename_ima_b=regexprep(par.filename_ima_b,'.png','');
fid=fopen([filename '.civ1.cmx'],'w');
fprintf(fid,['##############   CMX file' '\n' ]);
fprintf(fid,   ['FirstImage ' regexprep(par.filename_ima_a,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid,   ['LastImage  ' regexprep(par.filename_ima_b,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid,  ['XX' '\n' ]);
fprintf(fid,  ['Mask ' par.maskflag '\n' ]);
fprintf(fid,  ['MaskName ' regexprep(par.maskname,'\\','\\\\') '\n' ]);
fprintf(fid,   ['ImageSize ' par.npx ' ' par.npy '\n' ]);   %VERIFIER CAS GENERAL ?
fprintf(fid,   ['CorrelationBoxesSize ' par.ibx ' ' par.iby '\n' ]);
fprintf(fid,   ['SearchBoxeSize ' par.isx ' ' par.isy '\n' ]);
fprintf(fid,   ['RO ' par.rho '\n' ]);
fprintf(fid,   ['GridSpacing ' par.dx ' ' par.dy '\n' ]);
fprintf(fid,   ['XX 1.0' '\n' ]);
fprintf(fid,   ['Dt_TO ' par.Dt ' ' par.T0 '\n' ]);
fprintf(fid,  ['PixCmXY ' par.pxcmx ' ' par.pxcmy '\n' ]);
fprintf(fid,  ['XX 1' '\n' ]);
fprintf(fid,   ['ShiftXY ' par.shiftx ' '  par.shifty '\n' ]);
fprintf(fid,  ['Grid ' par.gridflag '\n' ]);
fprintf(fid,   ['GridName ' regexprep(par.gridname,'\\','\\\\') '\n' ]);
fprintf(fid,   ['XX 85' '\n' ]);
fprintf(fid,   ['XX 1.0' '\n' ]);
fprintf(fid,   ['XX 1.0' '\n' ]);
fprintf(fid,   ['Hart 1' '\n' ]);
fprintf(fid,  [ 'DecimalShift 0' '\n' ]);
fprintf(fid,   ['Deformation 0' '\n' ]);
fprintf(fid,  ['CorrelationMin 0' '\n' ]);
fprintf(fid,   ['IntensityMin 0' '\n' ]);
fprintf(fid,  ['SeuilImage n' '\n' ]);
fprintf(fid,   ['SeuilImageValues 0 4096' '\n' ]);
fprintf(fid,   ['ImageToUse ' par.term_a ' ' par.term_b '\n' ]); % VERIFIER ?
fprintf(fid,   ['ImageUsedBefore null null' '\n' ]);
fclose(fid);

% cmd_CIV1=[sparam.Civ1Bin ' -f ' filename '.cmx >' filename '.log' ]; % redirect standard output to the log file
% cmd_CIV1=regexprep(cmd_CIV1,'\\','\\\\');
% namelog=regexprep(namelog,'\\','\\\\');
if(isunix)
    cmd_CIV1=['cp -f ' filename '.civ1.cmx ' filename '.cmx\n'];
    cmd_CIV1=[cmd_CIV1 sparam.Civ1Bin ' -f ' filename '.cmx >' filename '.log' ]; % redirect standard output to the log file, the result file is named [filename '.nc'] by CIVx
    cmd_CIV1=[cmd_CIV1 '\n' 'mv ' filename '.log' ' ' filename '.civ1.log' '\n' 'chmod g+w ' filename '.civ1.log' '\n' 'chmod g+w ' filename '.nc'];%rename .log as .civ1.log and set the netcdf result file for group user writting
   % cmd_CIV1=[cmd_CIV1 '\n' 'mv ' filename '.cmx' ' ' filename '.civ1.cmx' '\n'];%rename .cmx as .civ1.cmx
else %Windows system
%                     flname=regexprep(flname,'\\','\\\\');
%                     cmd=[cmd 'copy /Y "' flname '.civ1.cmx" "' flname '.cmx"\n'];
%     filename=regexprep(filename,'\\','\\\\');
    cmd_CIV1=['copy /Y "' filename '.civ1.cmx" "' filename '.cmx"\n'];% copy the .civ1.cmx parameter file to .cmx
    cmd_CIV1=['"' sparam.Civ1Bin '" -f "' filename '.cmx" >"' filename '.log"' ]; % redirect standard output to the log file
    cmd_CIV1=regexprep(cmd_CIV1,'\\','\\\\');
    namelog=regexprep(namelog,'\\','\\\\');
    cmd_CIV1=[cmd_CIV1 '\n' 'copy /Y "' filename '.log' '" "' filename '.civ1.log"']; %preserve the log file as .civ1.log
  %  cmd_CIV1=[cmd_CIV1 '\n' 'copy /Y "' filename '.cmx' '" "' filename '.civ1.cmx"'];
end

%------------------------------------------------------------------------
% --- CIV1  Unified
function xml_civ1_parameters=CIV1_CMD_Unified(filename,namelog,par)
%------------------------------------------------------------------------
%pixels per cm and matrix of the image times, read from the .civ file by uvmat
%global CivBin%name of the executable for civ1 calculation

civ1.image1=par.filename_ima_a;
civ1.image2=par.filename_ima_b;
civ1.imageSize_X=par.npx;
civ1.imageSize_Y=par.npy;
civ1.outputFileName=[filename '.nc'];
civ1.correlationBoxesSize_X=par.ibx;
civ1.correlationBoxesSize_Y=par.iby;
civ1.searchBoxesSize_X=par.isx;
civ1.searchBoxesSize_Y=par.isy;
civ1.globalShift_X=par.shiftx;
civ1.globalShift_Y=par.shifty;
civ1.ro=par.rho;
civ1.hart='y';
if isequal(par.gridflag,'y')
    civ1.grid=par.gridname;
else
    civ1.grid='n';
    civ1.gridSpacing_X=par.dx;
    civ1.gridSpacing_Y=par.dy;
end
if isequal(par.maskflag,'y')
    civ1.mask=par.maskname;
end
civ1.dt=par.Dt;
civ1.unit='pixel';
civ1.absolut_time_T0=par.T0;
civ1.pixcmx=par.pxcmx;
civ1.pixcmy=par.pxcmy;
civ1.convectFlow='n';

xml_civ1_parameters=civ1;

%------------------------------------------------------------------------
% --- CIV2  Unified
function civ2=CIV2_CMD_Unified(filename,namelog,par)
%------------------------------------------------------------------------
%pixels per cm and matrix of the image times, read from the .civ file by uvmat
%global CivBin%name of the executable for civ1 calculation

civ2.image1=par.filename_ima_a;
civ2.image2=par.filename_ima_b;
civ2.imageSize_X=par.npx;
civ2.imageSize_Y=par.npy;
civ2.inputFileName=[par.filename_nc1 '.nc'];
civ2.outputFileName=[filename '.nc'];
civ2.correlationBoxesSize_X=par.ibx;
civ2.correlationBoxesSize_Y=par.iby;
civ2.ro=par.rho;
%civ2.decimalShift=par.decimal;
%civ2.deformation=par.deformation;
if isequal(par.decimal,'1')
    civ2.decimalShift='y';
else
    civ2.decimalShift='n';
end
if isequal(par.deformation,'1')
    civ2.deformation='y';
else
    civ2.deformation='n';
end
if isequal(par.gridflag,'y')
    civ2.grid=par.gridname;
else
    civ2.grid='n';
    civ2.gridSpacing_X=par.dx;
    civ2.gridSpacing_Y=par.dy;
end
civ2.gridSpacing_X='10';
civ2.gridSpacing_Y='10';%NOTE: faut mettre gridSpacing pourque ca tourne, meme si c'est la grille qui est utilisee
if isequal(par.maskflag,'y')
    civ2.mask=par.maskname;
else
    civ2.mask='n';
end
civ2.dt=par.Dt;
civ2.unit='pixel';
civ2.absolut_time_T0=par.T0;
civ2.pixcmx=par.pxcmx;
civ2.pixcmy=par.pxcmy;
civ2.convectFlow='n';
civ2.pixcmx=par.pxcmx;
civ2.pixcmy=par.pxcmy;
civ2.convectFlow='n';

%------------------------------------------------------------------------
% --- CIV2  CIV2  CIV2 CIV2
function cmd_CIV2=CIV2_CMD(filename,namelog,par,sparam)
%------------------------------------------------------------------------
%pixels per cm and matrix of the image times, read from the .civ file by uvmat
% global civ2Bin sge%name of the executable for civ1 calculation
if isequal(par.Dt,'0')
    par.Dt='1' ;%case of 'displacement' mode
end
par.filename_ima_a=regexprep(par.filename_ima_a,'.png','');
par.filename_ima_b=regexprep(par.filename_ima_b,'.png','');% bug : .png appears two times ?
[fid,errormsg]=fopen([filename '.civ2.cmx'],'w');
if isequal(fid,-1)
    msgbox_uvmat('ERROR',errormsg)
    cmd_CIV2='';
    return
end
fprintf(fid,['##############   CMX file' '\n' ]);
fprintf(fid,   ['FirstImage ' regexprep(par.filename_ima_a,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid,   ['LastImage  ' regexprep(par.filename_ima_b,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid,  ['XX' '\n' ]);
fprintf(fid, ['Mask ' par.maskflag '\n' ]);
fprintf(fid, ['MaskName ' regexprep(par.maskname,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid, ['ImageSize ' par.npx ' ' par.npy '\n' ]);   %VERIFIER CAS GENERAL ?
fprintf(fid, ['CorrelationBoxesSize ' par.ibx ' ' par.iby '\n' ]);
fprintf(fid, ['SearchBoxeSize ' par.ibx ' ' par.iby '\n']);
fprintf(fid, ['RO ' par.rho '\n']);
fprintf(fid, ['GridSpacing ' par.dx ' ' par.dy '\n']);
fprintf(fid, ['XX 1.0' '\n' ]);
fprintf(fid, ['Dt_TO ' par.Dt ' ' par.T0 '\n' ]);
fprintf(fid, ['PixCmXY ' par.pxcmx ' ' par.pxcmy '\n' ]);
fprintf(fid, ['XX 1' '\n' ]);
fprintf(fid, 'ShiftXY 0 0\n');
fprintf(fid, ['Grid ' par.gridflag '\n' ]);
fprintf(fid, ['GridName ' regexprep(par.gridname,'\\','\\\\') '\n']);
fprintf(fid, ['XX 85' '\n' ]);
fprintf(fid, ['XX 1.0' '\n' ]);
fprintf(fid, ['XX 1.0' '\n' ]);
fprintf(fid, ['Hart 1' '\n' ]);
fprintf(fid, ['DecimalShift ' par.decimal '\n']);
fprintf(fid, ['Deformation ' par.deformation '\n']);
fprintf(fid,  ['CorrelationMin 0' '\n' ]);
fprintf(fid,   ['IntensityMin 0' '\n' ]);
fprintf(fid,  ['SeuilImage n' '\n' ]);
fprintf(fid,   ['SeuilImageValues 0 4096' '\n' ]);
fprintf(fid,   ['ImageToUse ' par.term_a ' ' par.term_b '\n' ]); % VERIFIER ?
fprintf(fid, ['ImageUsedBefore ' regexprep(par.filename_nc1,'\\','\\\\') '\n']);
fclose(fid);

if(isunix)
    cmd_CIV2=['cp -f ' filename '.civ2.cmx ' filename '.cmx\n'];
    cmd_CIV2=[cmd_CIV2 sparam.Civ2Bin ' -f ' filename  '.cmx >' filename '.log' ]; % redirect standard output to the log file, the result file is named [filename '.nc'] by CIVx
    cmd_CIV2=[cmd_CIV2 '\n' 'mv ' filename '.log' ' ' filename '.civ2.log' '\n' 'chmod g+w ' filename '.nc'];%preserve the log file as .civ2.log
%    cmd_CIV2=[cmd_CIV2 '\n' 'mv ' filename '.cmx' ' ' filename '.civ2.cmx' '\n'];%rename .cmx as .civ2.cmx, the result file is named [filename '.nc'] by CIVx

else 
    filename=regexprep(filename,'\\','\\\\');
    cmd_CIV2=['copy /Y "' filename '.civ2.cmx" "' filename '.cmx"\n'];
    cmd_CIV2=[cmd_CIV2 '"' sparam.Civ2Bin '" -f "' filename  '.cmx" >"' filename '.log"' ]; % redirect standard output to the log file
    cmd_CIV2=regexprep(cmd_CIV2,'\\','\\\\');
    cmd_CIV2=[cmd_CIV2 '\n' 'copy /Y "' filename '.log' '" "' filename '.civ2.log"'];
 %    cmd_CIV2=[cmd_CIV2 '\n' 'copy /Y "' filename '.cmx' '" "' filename '.civ2.cmx"'];
end

% %------------------------------------------------------------------------
% % --- civ using pivlab
% function Data=civ_uvmat(par_civ1)
% %------------------------------------------------------------------------
% image1=imread(par_civ1.filename_ima_a);
% image2=imread(par_civ1.filename_ima_b);
% stepx=str2num(par_civ1.dx);
% stepy=str2num(par_civ1.dy);
% ibx2=ceil(str2num(par_civ1.ibx)/2);
% iby2=ceil(str2num(par_civ1.iby)/2);
% isx2=ceil(str2num(par_civ1.isx)/2);
% isy2=ceil(str2num(par_civ1.isy)/2);
% shiftx=str2num(par_civ1.shiftx);
% shifty=str2num(par_civ1.shifty);
% miniy=max(1+isy2-shifty,1+iby2);
% minix=max(1+isx2-shiftx,1+ibx2);
% maxiy=min(size(image1,1)-isy2-shifty,size(image1,1)-iby2);
% maxix=min(size(image1,2)-isx2-shiftx,size(image1,2)-ibx2);
% [GridX,GridY]=meshgrid(minix:stepx:maxix,miniy:stepy:maxiy);
% PointCoord(:,1)=reshape(GridX,[],1);
% PointCoord(:,2)=reshape(GridY,[],1);
% % caluclate velocity data (y and v in indices, reverse to y component)
% [xtable ytable utable vtable ctable F] = pivlab (image1,image2,ibx2,iby2,isx2,isy2,shiftx,shifty,PointCoord, 1, []);
% Data.ListGlobalAttribute=[{'Conventions','Program','CivStage'} {'Time','Dt'}];
% Data.Conventions='uvmat/civdata';
% Data.Program='civ_uvmat';
% Data.CivStage=1;
% % list_param=fieldnames(Param.Civ1);
% % for ilist=1:length(list_param)
% %     eval(['Data.Civ1_' list_param{ilist} '=Param.Civ1.' list_param{ilist} ';'])
% % end
% Data.Time=str2double(par_civ1.T0);
% Data.Dt=str2double(par_civ1.Dt);
% Data.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_F'};%  cell array containing the names of the fields to record
% Data.VarDimName={'nbvec','nbvec','nbvec','nbvec','nbvec','nbvec'};
% Data.VarAttribute{1}.Role='coord_x';
% Data.VarAttribute{2}.Role='coord_y';
% Data.VarAttribute{3}.Role='vector_x';
% Data.VarAttribute{4}.Role='vector_y';
% Data.VarAttribute{5}.Role='warnflag';
% Data.Civ1_X=reshape(xtable,[],1);
% Data.Civ1_Y=reshape(size(image1,1)-ytable+1,[],1);
% Data.Civ1_U=reshape(utable,[],1);
% Data.Civ1_V=reshape(-vtable,[],1);
% Data.Civ1_C=reshape(ctable,[],1);
% Data.Civ1_F=reshape(F,[],1);

%------------------------------------------------------------------------
% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
else
    addpath (fullfile(pathelp,'uvmat_doc'))
    web([helpfile '#civ'])
end

%------------------------------------------------------------------------
%--read images and convert them to the uint16 format used for PIV
function A=read_image(filename,type_ima,num,movieobject)
%------------------------------------------------------------------------
%num is the view number needed for an avi movie
switch type_ima
    case 'movie'
        A=read(movieobject,num);
    case 'avi'
        mov=aviread(filename,num);
        A=frame2im(mov(1));
    case 'multimage'
        A=imread(filename,num);
    case 'image'
        A=imread(filename);
end
siz=size(A);
if length(siz)==3;%color images
    A=sum(double(A),3);
    A=uint16(A);
end

%------------------------------------------------------------------------
function ref_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
find_netcpair_civ1(hObject, eventdata, handles);% update the menu of pairs depending on the available netcdf files
if isequal(mode,'series(Di)') || ...% we do patch2 only
        (get(handles.CIV2,'Value')==0 && get(handles.CIV1,'Value')==0 && get(handles.FIX1,'Value')==0 && get(handles.PATCH1,'Value')==0)
    find_netcpair_civ2(hObject, eventdata, handles);
end

%------------------------------------------------------------------------
function ref_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if isequal(get(handles.CIV1,'Value'),0)|| isequal(mode,'series(Dj)')
    find_netcpair_civ1(hObject, eventdata, handles);% update the menu of pairs depending on the available netcdf files
end
if isequal(mode,'series(Dj)') || ...
        (get(handles.CIV2,'Value')==0 && get(handles.CIV1,'Value')==0 && get(handles.FIX1,'Value')==0 && get(handles.PATCH1,'Value')==0)
    find_netcpair_civ2(hObject, eventdata, handles);
end

%------------------------------------------------------------------------
function ref_i_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
find_netcpair_civ2(hObject, eventdata, handles);% update the menu of pairs depending on the available netcdf files

%------------------------------------------------------------------------
function ref_j_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if  isequal(mode,'series(Dj)')
    find_netcpair_civ2(hObject, eventdata, handles);% update the menu of pairs depending on the available netcdf files
end

%------------------------------------------------------------------------
% --- Executes on button press in compare.
function compare_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
test=get(handles.compare,'Value');
if test==2 || test==3 % case 'dispalcemen' or 'stereo PIV'
    filebase=get(handles.RootName,'String');
    browse=get(handles.browse_root,'Userdata');
    browse.nom_type_ima1=browse.nom_type_ima;
    set(handles.browse_root,'UserData',browse);
    set(handles.sub_txt,'Visible','on')
    set(handles.RootName_1,'Visible','On');%mkes the second file input window visible
    mode_store=get(handles.mode,'String');%get the present 'mode'
    set(handles.compare,'UserData',mode_store);%store the mode display
    set(handles.mode,'Visible','off')
    if test==2
        set(handles.mode,'Visible','off')
        set(handles.CivMode,'Value',1) % mode 'civX' selected by default
    else
        set(handles.mode,'Visible','on')
        set(handles.CivMode,'Value',3) % mode 'Matlab' selected for stereo 
    end
    
    %% open an image file with the browser
    ind_opening=1;%default
    browse.incr_pair=[0 0]; %default
    oldfile=get(handles.RootName,'String');
     menu={'*.xml;*.civ;*.png;*.jpg;*.tif;*.avi;*.AVI;*.nc;', ' (*.xml,*.civ,*.png,*.jpg ,.tif, *.avi,*.nc)';
       '*.xml',  '.xml files '; ...
        '*.civ',  '.civ files '; ...
        '*.png','.png image files'; ...
        '*.jpg',' jpeg image files'; ...
        '*.tif','.tif image files'; ...
        '*.avi;*.AVI','.avi movie files'; ...
        '*.nc','.netcdf files'; ...
        '*.*',  'All Files (*.*)'};
    [FileName, PathName, filtindex] = uigetfile( menu, 'Pick a file of the second series',oldfile);
    fileinput=[PathName FileName];%complete file name
    sizf=size(fileinput);
    if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
    [path,name,ext]=fileparts(fileinput)
    [path1]=fileparts(filebase);
    if isunix
        [status,path]=system(['readlink ' path])
        [status,path1]=system(['readlink ' path1])% look for the true path in case of symbolic paths
    end
    if ~strcmp(path1,path)
        msgbox_uvmat('ERROR','The second image series must be in the same directory as the first one')
        return
     end
%     set(handles.RootName_1,'String',name);
    [RootPath,RootFile,field_count,str2,str_a,str_b,xx,nom_type,subdir]=name2display(name);
    set(handles.RootName_1,'String',RootFile);
    browse=get(handles.browse_root,'UserData');
    browse.nom_type_ima_1=nom_type;
    set(handles.browse_root,'UserData',browse)
    
    %check image extension
    if ~strcmp(ext,get(handles.ImaExt,'String'))
        msgbox_uvmat('ERROR','The second image series must have the same extension name as the first one')
        return
    end
    
    %% check coincidence of image sizes
%     ref_i=get(handles.ref_i,'string');
%     ref_j=get(handles.ref_j,'string');
%     [filecell,num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2,nom_type_nc]=set_civ_filenames(handles,ref_i,ref_j,[1 0 0 0 0 0]);
%     A=imread(filecell.ima1.civ1{1});
%     A_1=imread(fileinput);
%     npxy=size(A);
%     npxy_1=size(A_1);
%     if ~isequal(size(A),size(A_1))
%         msgbox_uvmat('ERROR','The two input image series do not have the same size')
%         return
%     end
else
    set(handles.mode,'Visible','on')
    set(handles.RootName_1,'Visible','Off');
    set(handles.sub_txt,'Visible','off')
    set(handles.RootName_1,'String',[]);
    mode_store=get(handles.compare,'UserData');
    set(handles.mode,'Value',1)
    set(handles.mode,'String',mode_store)
    set(handles.test_stereo1,'Value',0)
    set(handles.test_stereo2,'Value',0)
    set(handles.CivMode,'Value',1) % mode 'civX' selected by default
end
if test==3 && get(handles.PATCH1,'Value')
    set(handles.test_stereo1,'Visible','on')
else
    set(handles.test_stereo1,'Visible','off')
end
if test==3 && get(handles.PATCH2,'Value')
    set(handles.test_stereo2,'Visible','on')
else
    set(handles.test_stereo2,'Visible','off')
end
mode_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on button press in get_ref_fix1.
function get_ref_fix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
filebase=get(handles.RootName,'String');
[FileName, PathName, filterindex] = uigetfile( ...
    {'*.nc', ' (*.nc)';
    '*.nc',  'netcdf files '; ...
    '*.*', 'All Files (*.*)'}, ...
    'Pick a file',filebase);

fileinput=[PathName FileName];
sizf=size(fileinput);
if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
[Path,File,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
ref.filebase=fullfile(Path,File);
ref.num_a=stra2num(str_a);
ref.num_b=stra2num(str_b);
ref.num1=str2double(field_count);
ref.num2=str2double(str2);
browse=[];%initialisation
if ~isequal(ref.ext,'.nc')
    msgbox_uvmat('ERROR','the reference file must be in netcdf format (*.nc)')
    return
end
set(handles.ref_fix1,'String',[fullfile(ref.subdir,File) '....nc']);
set(handles.ref_fix1,'UserData',ref)
menu_field{1}='civ1';
Data=nc2struct(fileinput,[]);
if isfield(Data,'patch') && isequal(Data.patch,1)
    menu_field{2}='filter1';
end
if isfield(Data,'civ2') && isequal(Data.civ2,1)
    menu_field{3}='civ2';
end
if isfield(Data,'patch2') && isequal(Data.patch2,1)
    menu_field{4}='filter2';
end
set(handles.field_ref1,'String',menu_field);
set(handles.field_ref1,'Value',length(menu_field));
set(handles.inf_sup1,'Value',2);
set(handles.thresh_vel,'String','1');%default threshold
set(handles.ref_fix1,'Enable','on')

%------------------------------------------------------------------------
% --- Executes on button press in get_ref_fix2.
function get_ref_fix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.get_ref_fix2,'Value'),1)
    filebase=get(handles.RootName,'String');
    [FileName, PathName, filterindex] = uigetfile( ...
        {'*.nc', ' (*.nc)';
        '*.nc',  'netcdf files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',filebase);
    fileinput=[PathName FileName];
    sizf=size(fileinput);
    if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
    [Path,File,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
    ref.filebase=fullfile(Path,File);
    ref.num_a=stra2num(str_a);
    ref.num_b=stra2num(str_b);
    ref.num1=str2num(field_count);
    ref.num2=str2num(str2);
    browse=[];%initialisation
    if ~isequal(ref.ext,'.nc')
        msgbox_uvmat('ERROR','the reference file must be in netcdf format (*.nc)')
        return
    end
    set(handles.ref_fix2,'String',[fullfile(ref.subdir,File) '....nc']);
    set(handles.ref_fix2,'UserData',ref)
    menu_field{1}='civ1';
    Data=nc2struct(fileinput,[]);
    if isfield(Data,'patch') & isequal(Data.patch,1)
        menu_field{2}='filter1';
    end
    if isfield(Data,'civ2') & isequal(Data.civ2,1)
        menu_field{3}='civ2';
    end
    if isfield(Data,'patch2') & isequal(Data.patch2,1)
        menu_field{4}='filter2';
    end
    set(handles.field_ref2,'String',menu_field);
    set(handles.field_ref2,'Value',length(menu_field));
    set(handles.inf_sup2,'Value',2);
    set(handles.thresh_vel2,'String','1');%default threshold
    set(handles.ref_fix2,'Enable','on')
    set(handles.ref_fix2,'Visible','on')
    set(handles.field_ref2,'Visible','on')
else
    set(handles.ref_fix2,'Visible','off')
    set(handles.field_ref2,'Visible','off')
end

%------------------------------------------------------------------------
function ref_fix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.inf_sup1,'Value',1);
set(handles.field_ref1,'Value',1)
set(handles.field_ref1,'String',{' '})
set(handles.ref_fix1,'UserData',[]);
set(handles.ref_fix1,'String','');
set(handles.thresh_vel1,'String','0');

%------------------------------------------------------------------------
function ref_fix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.inf_sup2,'Value',1);
set(handles.field_ref2,'Value',1)
set(handles.field_ref2,'String',{' '})
set(handles.ref_fix2,'UserData',[]);
set(handles.ref_fix2,'String','');
set(handles.thresh_vel2,'String','0');

%------------------------------------------------------------------------
% --- Executes on button press in test_stereo1.
function test_stereo1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.test_stereo1,'Value'),0)
    set(handles.subdomain_patch1,'Visible','on')
    set(handles.rho_patch1,'Visible','on')
else
    set(handles.subdomain_patch1,'Visible','off')
    set(handles.rho_patch1,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on button press in test_stereo2.
function test_stereo2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.test_stereo2,'Value'),0)
    set(handles.subdomain_patch2,'Visible','on')
    set(handles.rho_patch2,'Visible','on')
else
    set(handles.subdomain_patch2,'Visible','off')
    set(handles.rho_patch2,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on button press in ImaThreshold.
function ImaThreshold_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.ImaThreshold,'Value'),1)
    set(handles.MinIma,'Visible','on')
    set(handles.MaxIma,'Visible','on')
else
    set(handles.MinIma,'Visible','off')
    set(handles.MaxIma,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on button press in ImaThreshold2.
function ImaThreshold2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.ImaThreshold2,'Value'),1)
    set(handles.MinIma2,'Visible','on')
    set(handles.MaxIma2,'Visible','on')
else
    set(handles.MinIma2,'Visible','off')
    set(handles.MaxIma2,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on button press in TestCiv1: display image correlation function
function TestCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.TestCiv1,'BackgroundColor',[1 1 0])
drawnow
test_civ1=get(handles.TestCiv1,'Value');
if test_civ1
    ref_i=str2double(get(handles.ref_i,'String'));
    if strcmp(get(handles.ref_j,'Visible'),'on')
        ref_j=str2double(get(handles.ref_j,'String'));
    else
        ref_j=1;%default
    end
    [filecell,num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2,nom_type_nc,file_ref_fix1,file_ref_fix2]=...
        set_civ_filenames(handles,ref_i,ref_j,[1 0 0 0 0 0])
    Data.ListVarName={'ny','nx','A'};
    Data.VarDimName={'ny','nx',{'ny','nx'}};
    Data.A=imread(filecell.ima1.civ1{1});
    Data.ny=[size(Data.A,1) 1];
    Data.nx=[1 size(Data.A,2)];
    par_civ1=read_param_civ1(handles,filecell.ima1.civ1{1});
    par_civ1.filename_ima_a=filecell.ima1.civ1{1};
    par_civ1.filename_ima_b=filecell.ima2.civ1{1};
    par_civ1.T0=0;
    par_civ1.Dt=1;
    Param.Civ1=par_civ1;
    Data=civ_uvmat(Param);
    Data.ListVarName=[Data.ListVarName {'ny','nx','A'}];
    Data.VarDimName=[Data.VarDimName {'ny','nx',{'ny','nx'}}];
    Data.A=imread(filecell.ima1.civ1{1});
    Data.ny=[size(Data.A,1) 1];
    Data.nx=[1 size(Data.A,2)];
    hview_field=view_field(Data);
    set(0,'CurrentFigure',hview_field)
    hhview_field=guihandles(hview_field);
    set(hview_field,'CurrentAxes',hhview_field.axes3)
    ViewData=get(hview_field,'UserData');
    ViewData.CivHandle=handles.civ;% indicate the handle of the civ GUI in view_field
    ViewData.axes3.B=imread(filecell.ima2.civ1{1});%store the second image in the UserData of the GUI view_field
    ViewData.axes3.X=Data.Civ1_X; %keep the set of points in memeory
    ViewData.axes3.Y=Data.Civ1_Y;
    set(hview_field,'UserData',ViewData)
    corrfig=findobj(allchild(0),'tag','corrfig');% look for a current figure for image correlation display
    if isempty(corrfig)
        corrfig=figure;
        set(corrfig,'tag','corrfig')
        set(corrfig,'name','image correlation')
        set(corrfig,'DeleteFcn',{@closeview_field})%
    end
    set(handles.TestCiv1,'BackgroundColor',[1 0 0])
else
    corrfig=findobj(allchild(0),'tag','corrfig');% look for a current figure for image correlation display
    if ~isempty(corrfig)
        delete(corrfig)
    end
    hview_field=findobj(allchild(0),'tag','view_field');% look for view_field    
    if ~isempty(hview_field)
        delete(hview_field)
    end
end

function closeview_field(gcbo,eventdata)
hview_field=findobj(allchild(0),'tag','view_field');% look for view_field    
    if ~isempty(hview_field)
        delete(hview_field)
    end
%-------------------------------------------------------------------
% --- Executes on button press in status.
function status_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
val=get(handles.status,'Value');
if val==0
    set(handles.status,'BackgroundColor',[0 1 0])
    hfig=findobj(allchild(0),'name','civ_status');
    if ~isempty(hfig)
        delete(hfig)
    end
    return
end
set(handles.status,'BackgroundColor',[1 1 0])
drawnow
listtype={'civ1','fix1','patch1','civ2','fix2','patch2'};
box_test(1)=get(handles.CIV1,'Value');
box_test(2)=get(handles.FIX1,'Value');
box_test(3)=get(handles.PATCH1,'Value');
box_test(4)=get(handles.CIV2,'Value');
box_test(5)=get(handles.FIX2,'Value');
box_test(6)=get(handles.PATCH2,'Value');
option_civ=find(box_test,1,'last');%last selected option (non-zero index of box_test)
filecell=get(handles.civ,'UserData');%retrieve the list of output files expected for PIV
test_new=0;
if ~isfield(filecell,'nc')
    test_new=1;
    [ref_i,ref_j,errormsg]=find_ref_indices(handles);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg)
        return
    end
    filecell=set_civ_filenames(handles,ref_i,ref_j,box_test);%determine the output file expected from the GUI status
end
if ~isequal(box_test(4:6),[0 0 0])
    civ_files=filecell.nc.civ2;%case of civ2 operations
else
    civ_files=filecell.nc.civ1;
end
[root,filename,ext]=fileparts(civ_files{1});
[rootroot,subdir,extdir]=fileparts(root);
hfig=findobj(allchild(0),'name','civ_status');
if isempty(hfig)
    hfig=figure('DeleteFcn',@stop_status);
    set(hfig,'name','civ_status')
    hlist=uicontrol('Style','listbox','Units','normalized', 'Position',[0.05 0.09 0.9 0.71], 'Callback', @open_view_field,'tag','list');
    uicontrol('Style','edit','Units','normalized', 'Position', [0.05 0.87 0.9 0.1],'tag','msgbox','Max',2,'String','checking files...');
    uicontrol('Style','frame','Units','normalized', 'Position', [0.05 0.81 0.9 0.05]);
    uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.7 0.01 0.2 0.07],'String','OK','FontWeight','bold','FontUnits','normalized','FontSize',0.9,'Callback',@close_GUI);
    BarPosition=[0.05 0.81 0.01 0.05];
    hwaitbar=uicontrol('Style','frame','Units','normalized', 'Position',BarPosition ,'BackgroundColor',[1 0 0],'tag','waitbar');
    drawnow
end
% datnum=[];
Tabchar={};
nbfiles=numel(civ_files);
count=0;
testrecent=0;
while count<nbfiles
    count=0;
    datnum=zeros(1,nbfiles);
    for ifile=1:nbfiles
        detect=exist(civ_files{ifile},'file'); % check the existence of the file
        option=0;
        if detect==0
            option_str='not created';
        else
            datfile=dir(civ_files{ifile});
            if isfield(datfile,'datenum')
                datnum(ifile)=datfile.datenum;%only available in recent matlab versions
                testrecent=1;
            end
            filefound(ifile)={datfile.name};
            lastfield='';
            % check the content  netcdf file
            Data=nc2struct(civ_files{ifile},'ListGlobalAttribute','patch2','fix2','civ2','patch','fix');
            if ~isempty(Data.patch2) && isequal(Data.patch2,1)
                option=6;
                option_str='patch2';
            elseif ~isempty(Data.fix2) && isequal(Data.fix2,1)
                option=5;
                option_str='fix2';
            elseif ~isempty(Data.civ2) && isequal(Data.civ2,1);
                option=4;
                option_str='civ2';
            elseif ~isempty(Data.patch) && isequal(Data.patch,1);
                option=3;
                option_str='patch1';
            elseif ~isempty(Data.fix) && isequal(Data.fix,1);
                option=2;
                option_str='fix1';
            else
                option=1;
                option_str='civ1';
            end
        end
        if option >= option_civ
            count=count+1;
        end
        [rr,filename,ext]=fileparts(civ_files{ifile});
        Tabchar{ifile,1}=[fullfile([subdir extdir],filename) ext  '...' option_str];
    end
    datnum=datnum(datnum~=0);%keep the non zero values corresponding to existing files
    if isempty(datnum) 
        if testrecent
            message='no civ result created yet';
        else
            message='';
        end
    else
        datnum=datnum(datnum~=0);%keep the non zero values corresponding to existing files
        [first,ind]=min(datnum);
        [last,indlast]=max(datnum);
        if test_new
            message='existing file status, no processing launched yet';
        else
        message={[num2str(count) ' file(s) done over ' num2str(nbfiles)] ;['oldest modification:  ' cell2mat(filefound(ind)) ' : ' datestr(first)];...
            ['latest modification:  ' cell2mat(filefound(indlast)) ' : ' datestr(last)]};
        end
    end
    hfig=findobj(allchild(0),'name','civ_status');
    if isempty(hfig)% the status list has been deleted
        return
    else
        hlist=findobj(hfig,'tag','list');
        hmsgbox=findobj(hfig,'tag','msgbox');
        hwaitbar=findobj(hfig,'tag','waitbar');
        set(hlist,'String',Tabchar)
        set(hmsgbox,'String', message)
        if count>0 && ~test_new
            BarPosition(3)=0.9*count/nbfiles;
            set(hwaitbar,'Position',BarPosition)
        end
    end
    set(hlist,'UserData',rootroot)
    pause(10)% wait 10 seconds for next check
end

    
%------------------------------------------------------------------------   
% call 'view_field.fig' to display the  field selected in the list of 'status'
function open_view_field(hObject, eventdata)
%------------------------------------------------------------------------
list=get(hObject,'String');
index=get(hObject,'Value');
rootroot=get(hObject,'UserData');
filename=list{index};
ind_dot=findstr(filename,'...');
filename=filename(1:ind_dot-1);
filename=fullfile(rootroot,filename);
delete(get(hObject,'parent'))%delete the display figure to stop the check process
if exist(filename,'file')%visualise the vel field if it exists
    uvmat(filename)
    set(gcbo,'Value',1)
end

%------------------------------------------------------------------------   
% launched by pressing OK on the status figure
function close_GUI(hObject, eventdata)
%------------------------------------------------------------------------
    delete(gcbf)
    
%------------------------------------------------------------------------   
% launched by deleting the status figure
function stop_status(hObject, eventdata)
%------------------------------------------------------------------------
hciv=findobj(allchild(0),'tag','civ');
hhciv=guidata(hciv);
set(hhciv.status,'value',0) %reset the status uicontrol in the GUI civ
set(hhciv.status,'BackgroundColor',[0 1 0])

%------------------------------------------------------------------------
% --- Executes on button press in CivMode.
function CivMode_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
Listprog=get(handles.CivMode,'String');
index=get(handles.CivMode,'Value');
prog=Listprog{index};
switch prog
    case 'CivX'
        set(handles.thresh_patch1,'Visible','off')
        set(handles.thresh_text1,'Visible','off')
        set(handles.thresh_patch2,'Visible','off')
        set(handles.thresh_text2,'Visible','off')
        set(handles.rho,'Style','edit')
        set(handles.rho,'String','1')
        set(handles.BATCH,'Enable','on')
    case 'CivAll'
        if get(handles.PATCH1,'Value')
            set(handles.thresh_patch1,'Visible','on')
            set(handles.thresh_text1,'Visible','on')
        end
        set(handles.rho,'Style','edit')
        set(handles.rho,'String','1')
        set(handles.BATCH,'Enable','on')
    case 'CivUvmat'
        if get(handles.PATCH1,'Value')
            set(handles.thresh_patch1,'Visible','on')
            set(handles.thresh_text1,'Visible','on')
        end
        if get(handles.PATCH2,'Value')
            set(handles.thresh_patch2,'Visible','on')
            set(handles.thresh_text2,'Visible','on')
        end
        set(handles.rho,'Style','popupmenu')
        set(handles.rho,'Value',1)
        set(handles.rho,'String',{'1';'2'})
        set(handles.BATCH,'Enable','off')
end
