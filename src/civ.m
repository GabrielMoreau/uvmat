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

% Last Modified by GUIDE v2.5 27-Mar-2010 13:41:11
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

%default initial parameters
filebase=''; % root file name ('filebase'.civ)
ext=[];
testall=0;
%default input parameters:
num1=1; % set of field i numbers
num2=1; % set of field i numbers
num_a=1; % set of field j numbers (fields a)
num_b=1; % second set of field j numbers (fields b)
subdir='A'; % subdir for the netcdf result files
ind_opening=1; % proposed operation number (1=civ1,2=fix1,3=patch1,4=civ2,5=fix2,6=patch2)
%load the initial parameters if the interface is started from uvmat
if exist('param','var')&&isstruct(param)% the interface is opened from uvmat
    filebase=param.RootName;
    nom_type_read=param.NomType;
    num1=param.num1;
    num2=param.num2;
    num_a=param.num_a;
    num_b=param.num_b;
    subdir=param.SubDir;
    ind_opening=param.IndOpening;
    ext=param.ImaExt;
end
browse.num_i1=num1;
browse.num_i2=num2;
browse.num_j1=num_a;
browse.num_j2=num_b;
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
set(handles.ImaDoc,'UserData',testall);
set(handles.ImaDoc,'String',ext)

%read names of the .exe file to adjust the interface according to available binaries
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
errormsg=[];%default error message
% xmlfile=fullfile(path_UVMAT,'PARAM.xml');
% if ~exist(xmlfile,'file')
xmlfile='PARAM.xml';
% end
if exist(xmlfile,'file')
    try
        t=xmltree(xmlfile);
        sparam=convert(t);
    catch
        errormsg={' Unable to read the file PARAM.xml defining the civx binaries:'; lasterr};
    end
else
    errormsg=[xmlfile ' not found: path to civx binaries undefined'];
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
    enable_civ2(handles,1)
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
if isnan(num2)||isequal(num2,num1)
    num_ref_i=num1;
else
    num_ref_i=floor((num1+num2)/2);
    browse.incr_pair(1)=num2-num1;
    browse.incr_pair(2)=0;
end
if isnan(num_b)||isequal(num_a,num_b)
    if isnan(num_a)
        num_ref_j=1;
    else
        num_ref_j=num_a;
    end
else
    num_ref_j=floor((num_a+num_b)/2);
    browse.incr_pair(2)=num_b-num_a;
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
if exist('param','var')%varargin the interface is opened from uvmat
    RootName_Callback(hObject, eventdata, handles);
end

set(handles.waitbar_1,'Position',[0.946 0.877 0.03 0.001])
set(handles.waitbar_patch1,'Position',[0.946 0.626 0.03 0.001])
set(handles.waitbar_civ2,'Position',[0.946 0.406 0.03 0.001])
set(handles.waitbar_patch2,'Position',[0.946 0.187 0.03 0.001])

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
testall=get(handles.ImaDoc,'UserData');
ind_opening=1;%default
browse.incr_pair=[0 0]; %default
if testall
    menu={'*.*', 'All Files (*.*)'; '*.xml; *.avi;*.AVI;*.nc','(*.xml,*.avi,*.nc)'; ...
        '*.xml', '.xml files';'*.avi;*.AVI', '.avi files';'*.nc','.nc files'};
else % menu selecting only .civ or .avi files
    menu={'*.xml;*.avi;*.AVI;*.nc','(*.xml,*.avi,*.nc)'; ...
        '*.xml', '.xml files';'*.avi;*.AVI', '.avi files';'*.nc', '.nc files';...
        '*.*', 'All Files (*.*)'};
end
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
%     set(handles.ImaExt,'String',ext)
    browse.nom_type_ima=nom_type;
    browse.ext_ima=ext;
end
set(handles.ImaDoc,'String',ext);

%%%%% read the state of the selected netcdf file to advise default operation
if isequal(ext,'.nc')
    browse.nom_type_nc=nom_type;
    ind_opening=2;% propose 'fix' as the default option
    Data=nc2struct(fileinput,[]);
    if isfield(Data,'absolut_time_T0')%test for civx files
        if isfield(Data,'fix') && isequal(Data.fix,1)
            ind_opening=3;
        end
        if isfield(Data,'patch') && isequal(Data.patch,1)
            ind_opening=4;
        end
        if isfield(Data,'civ2') && isequal(Data.civ2,1)
            ind_opening=5;
        end
        if isfield(Data,'fix2') && isequal(Data.fix2,1)
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
    enable_civ2(handles,1)
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
testall=isequal(menu(filtindex,1),{'*.*'});
set(handles.ImaDoc,'UserData',testall);

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
%ext_ima=get(handles.ImaExt,'String');
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
%     if ~isempty(ext_ima_read) && ~isempty(nom_type_read)
% %         if isempty(ext_ima)
% %             ext_ima=ext_ima_read;% define image extension from the xml file if an image has not been opened previously
% %         else   %keep the image extension
% %             if  ~strcmp(ext_ima_read,ext_ima)
% %                 msgbox_uvmat('WARNING',['FirtsImage extension ' ext_ima_read ' announced in the xml file inconsistent with the selected image'])
% %             end
% %         end
%         nom_type_ima=nom_type_read;
%     end
elseif strcmp(ext_imadoc,'.civ')% case of .civ image documentation file
    [error,time,TimeUnit,mode,npx,npy]=read_imatext([filebase '.civ']);
    if error==2, msgbox_uvmat('WARNING',['no file ' filebase '.civ']);
    elseif error==1, msgbox_uvmat('WARNING','inconsistent number of fields in the .civ file');
    end
    nom_type_ima='001a';
elseif strcmpi(ext_imadoc,'.avi')
    nom_type_ima='*';
    ext_ima=ext_imadoc;
    set(handles.mode,'String',{'series(Di)'})
    dt=0.04;%default
    if exist([filebase ext_imadoc],'file')==2
        info=aviinfo([filebase ext_imadoc]);%read infos on the avi movie
        dt=1/info.FramesPerSecond;%time interval between successive frames
        nbfield=info.NumFrames;%number of frames
    end
    time=(dt*(0:nbfield-1))';%list of image times
    %set(handles.dt,'String',num2str(dt*1000));%store the time interval between successive images
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
    idetect=1;
    while idetect==1 %look for the maximum file number in the series
        imagename=name_generator(filebase,field_i+1,1,ext_search,nom_type_search);
        idetect=(exist(imagename,'file')==2);
        if idetect
            field_i=field_i+1;
        end
        %SEE CASE OF NETCDF FILES
        %             nbdetect=nbdetect+(exist(imagename,'file')==2);
    end
    nbfield=field_i;% last detected field number
    field_i=browse.num_i1;%look for the minimum file number in the series
    idetect=1;
    while idetect==1
        imagename=name_generator(filebase,field_i-1,1,ext_search,nom_type_search);
        idetect=(exist(imagename,'file')==2);
        if idetect
            field_i=field_i-1;
        end
    end
    first_i=max(field_i,1); 
    if numel(regexp(nom_type_search,'\D'))>=1%two indices i and j
        field_i=browse.num_i1;
        field_j=browse.num_j2;
        jdetect=1;
        while jdetect==1 %look for the maximum file number in the series
            imagename=name_generator(filebase,field_i,field_j,ext_search,nom_type_search);
            jdetect=(exist(imagename,'file')==2);
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
%     switch nom_type_search  
%         case {'_i_j','%01dA','%02dA','%03dA','%04dA'}
        % time=[0:nb_field-1]'*ones(1,nb_field_j);% time=file index -1  by default
        [x,y]=meshgrid(0:nbfield2-1,0:nbfield-1);
        time=x+y;
%         time=[0:nb_field-1]'*[0:nb_field_j-1];% time=file index -1  by default
    end
%     set(handles.mode,'String',{'series(Di)'})
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
test_ima_i=numel(nom_type_ima)>1 && isempty(regexp(nom_type_ima(2:end),'\D'));%images with single indexing
if test_ima_i || isequal(nom_type_nc,'_i1-i2')||~(exist('nbfield2','var')&&(nbfield2~=1))
    set(handles.mode,'String',{'series(Di)'})
    set(handles.mode,'Value',1)
elseif (nbfield==1)% simple series in j
    set(handles.mode,'String',{'series(Dj)'})
    set(handles.mode,'Value',1)
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

%%%%%% initialize waitbars and RUN button
set(handles.waitbar_1,'Position',[0.946 0.876 0.03 0.001])
set(handles.waitbar_patch1,'Position',[0.946 0.439 0.03 0.001])
set(handles.waitbar_civ2,'Position',[0.946 0.219 0.03 0.001])
set(handles.waitbar_patch2,'Position',[0.946 0.0 0.03 0.001])
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])
set(handles.BATCH,'Enable','On')
set(handles.BATCH,'BackgroundColor',[1 0 0])

%%%%% store the root input filename for future opening
dir_perso=prefdir;
profil_perso=fullfile(prefdir,'uvmat_perso.mat');
RootPath=fileparts(filebase);
if exist(profil_perso,'file')
    save (profil_perso,'RootPath','-append'); %store the root name for future opening of uvmat
else
    txt=ver;
    Release=txt(1).Release;
    relnumb=str2double(Release(3:4));
    if relnumb >= 14
        save (profil_perso,'RootPath','-V6'); %store the root name for future opening of uvmat
    else
        save (profil_perso,'RootPath'); %store the root name for future opening of uvmat
    end
end
% save(profil_perso, 'filebase'); %store the root name for future opening of uvmat
set(gcf,'Pointer','arrow')

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
ichoice=min(find(select));
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
    mode_list=get(handles.mode,'String');
    mode_value=get(handles.mode,'Value');
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
ichoice=min(find(select));
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
%  determine the list of index pairs of processing file
function [num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2]=...
    find_pair_indices(handles,mode)
%------------------------------------------------------------------------
first_i=str2double(get(handles.first_i,'String'));%first index i
last_i=str2double(get(handles.last_i,'String'));%last index i
incr=str2double(get(handles.incr_i,'String'));% increment
num_i=first_i:incr:last_i;% list of i indices (reference values for each pair)
if isequal(get(handles.first_j,'Visible'),'on')
    first_j=str2double(get(handles.first_j,'String'));%first index j
    last_j=str2double(get(handles.last_j,'String'));%last index j
    incr_j=str2double(get(handles.incr_j,'String'));% increment
else
    first_j=1;
    last_j=1;
    incr_j=1;
end
num_j=[first_j:incr_j:last_j];% list of j indices (reference values for each pair)
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
if isempty(first_i)||isempty(first_j), msgbox_uvmat('ERROR','first field number not defined'),...
        return,end;
if isequal(last_i,[])|| isequal(last_j,[]),msgbox_uvmat('ERROR','last field number not defined'),...
        return,end;
if isequal(incr,[])|| isequal(incr_j,[]),msgbox_uvmat('ERROR','increment in field number not defined'),...
        return,end;
if last_i < first_i || last_j < first_j , msgbox_uvmat('ERROR','last field number must be larger than the first one'),...
        return,end;
if isequal (mode,'series(Di)')
    %recognize the pair civ1 from the display
    indsel=find((double(str_civ1)<48)|(double(str_civ1)>57));% character indices of non numerical characters
    str_raw=str_civ1(indsel);
    indsepar=find(str_raw=='|'); %character index of the separator
    d1=str2double(str_civ1(indsel(indsepar-1)+1:indsel(indsepar)-1));
    if indsepar==length(str_raw)
        d2=str2double(str_civ1(indsel(indsepar)+1:end));
    else
        d2=str2double(str_civ1(indsel(indsepar)+1:indsel(indsepar+1)-1));
    end
    num1_civ1=num_i-d1;% set of first image numbers
    num2_civ1=num_i+d2;
    num_a_civ1=num_j;
    num_b_civ1=num_j;
    
    %recognize the pair civ2 from the display
    indsel=find((double(str_civ2)<48)|(double(str_civ2)>57));% character indices of non numerical characters
    str_raw=str_civ2(indsel);
    indsepar=find(str_raw=='|'); %character index of the separator
    d1=str2double(str_civ2(indsel(indsepar-1)+1:indsel(indsepar)-1));
    if indsepar==length(str_raw)
        d2=str2double(str_civ2(indsel(indsepar)+1:end));
    else
        d2=str2double(str_civ2(indsel(indsepar)+1:indsel(indsepar+1)-1));
    end
    if isnan(d1)
        num1_civ2=num_i;
    else
        num1_civ2=num_i-d1;% set of first image numbers
    end
    if isnan(d2)
        num2_civ2=num_i;
    else
        num2_civ2=num_i+d2;
    end
    num_a_civ2=num_j;
    num_b_civ2=num_j;
    
    % adjust the first and last field number
    lastfield=str2double(get(handles.nb_field,'String'));
    if isequal(lastfield,[])
        indsel=find((num1_civ1 >= 1)&(num1_civ2 >= 1));
    else
        indsel=find((num2_civ1 <= lastfield)&(num2_civ2 <= lastfield)&(num1_civ1 >= 1)&(num1_civ2 >= 1));
    end
    if length(indsel)>=1
        firstind=indsel(1);
        lastind=indsel(end);
        set(handles.first_i,'String',num2str(num_i(firstind)))%update the display of first and last fields
        set(handles.last_i,'String',num2str(num_i(lastind)))
        num_i=num_i(indsel);
        num1_civ1=num1_civ1(indsel);
        num1_civ2=num1_civ2(indsel);
        num2_civ1=num2_civ1(indsel);
        num2_civ2=num2_civ2(indsel);
    end
elseif isequal (mode,'series(Dj)')
    lastfield_j=str2double(get(handles.nb_field2,'String'));
    num1_civ1=num_i;% set of first image numbers
    num2_civ1=num_i;
    num_a_civ1=num_j-floor(index_civ1/2)*ones(size(num_j));
    num_b_civ1=num_j+ceil(index_civ1/2)*ones(size(num_j));
    num1_civ2=num_i;
    num2_civ2=num_i;
    num_a_civ2=num_j-floor(index_civ2/2)*ones(size(num_j));
    num_b_civ2=num_j+ceil(index_civ2/2)*ones(size(num_j));
    % adjust the first and last field number
    if isnan(lastfield_j)
        indsel=find((num_a_civ1 >= 1)&(num_a_civ2 >= 1));
    else
        indsel=find((num_b_civ1 <= lastfield_j)&(num_b_civ2 <= lastfield_j)&(num_a_civ1 >= 1)&(num_a_civ2 >= 1));
    end
    if length(indsel)>=1
        firstind=indsel(1);
        lastind=indsel(end);
        set(handles.first_j,'String',num2str(num_j(firstind)))%update the display of first and last fields
        set(handles.last_j,'String',num2str(num_j(lastind)))
        num_j=num_j(indsel);
        num_a_civ1=num_a_civ1(indsel);
        num_a_civ2=num_a_civ2(indsel);
        num_b_civ1=num_b_civ1(indsel);
        num_b_civ2=num_b_civ2(indsel);
    end
elseif isequal(mode,'pair j1-j2') %case of bursts (png_old or png_2D)
    num1_civ1=num_i;
    num1_civ2=num_i;
    displ_num=get(handles.list_pair_civ1,'UserData');
    num2_civ1=num_i;
    num_a_civ1=displ_num(1,index_civ1);
    num_b_civ1=displ_num(2,index_civ1);
    num2_civ2=num_i;
    num_a_civ2=displ_num(1,index_civ2);
    num_b_civ2=displ_num(2,index_civ2);
elseif isequal(mode,'displacement')
    num1_civ1=num_i;
    num2_civ1=num_i;
    num_a_civ1=num_j;
    num_b_civ1=num_j;
    num1_civ2=num_i;
    num2_civ2=num_i;
    num_a_civ2=num_j;
    num_b_civ2=num_j;
end


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
        ind=find((num1-floor(index_pair/2)*ones(size(num1))>0)& ...
            (num1+ceil(index_pair/2)*ones(size(num1))<=lastfield));
        num1=num1(ind);
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
        ind=find((num_j-floor(index_pair/2)*ones(size(num_j))>0)& ...
            (num_j+ceil(index_pair/2)*ones(size(num_j))<=lastfield2));
        num1=num_j(ind);
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
        ind=find((num1-floor(index_pair/2)*ones(size(num1))>0)& ...
            (num1+ceil(index_pair/2)*ones(size(num1))<=lastfield));
        num1=num1(ind);
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
        ind=find((num_j-floor(index_pair/2)*ones(size(num_j))>0)& ...
            (num_j+ceil(index_pair/2)*ones(size(num_j))<=lastfield2));
        num1=num_j(ind);
    end
    set(handles.first_j,'String',num2str(num1(1)));
    set(handles.last_j,'String',num2str(num1(end)));
end

function RUN_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% global civ1_exe civ2_exe patch_exe patch_new_exe sge
set(handles.RUN, 'Enable','Off')
set(handles.RUN,'BackgroundColor',[0.831 0.816 0.784])
batch=0;
launch_jobs(hObject, eventdata, handles,batch);
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])

%------------------------------------------------------------------------
% --- Executes on button press in BATCH: remote processing
function BATCH_Callback(hObject, eventdata, handles)
%% -----------------------------------------------------------------------
%global civ1_exe civ2_exe patch_exe patch_new_exe fix_exe todo_path sge Civ_exe % probabely to remove
set(handles.BATCH, 'Enable','Off')
set(handles.BATCH,'BackgroundColor',[0.831 0.816 0.784])
batch=1;
launch_jobs(hObject, eventdata, handles, batch)
set(handles.BATCH, 'Enable','On')
set(handles.BATCH,'BackgroundColor',[1 0 0])

%------------------------------------------------------------------------
% --- Lauch command called by RUN and BATCH: remote processing
function launch_jobs(hObject, eventdata, handles, batch)
%-----------------------------------------------------------------------
%% check the selected list of operations:
operations={'CIV1','FIX1','PATCH1','CIV2','FIX2','PATCH2'};
box_test(1)=get(handles.CIV1,'Value');
box_test(2)=get(handles.FIX1,'Value');
box_test(3)=get(handles.PATCH1,'Value');
box_test(4)=get(handles.CIV2,'Value');
box_test(5)=get(handles.FIX2,'Value');
box_test(6)=get(handles.PATCH2,'Value');
index=find(box_test==1);
if isempty(index)
    msgbox_uvmat('ERROR','no selected operation')
    return
end
index_first=min(index);
index_last=max(index);
box_used=box_test([index_first : index_last]);
[box_missing,ind_missing]=min(box_used);
if isequal(box_missing,0)
    msgbox_uvmat('ERROR',['missing' cell2mat(operations(ind_missing))]);
    return
end

%check mask if selecetd
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

%% initialize the waitbars: TO suppress, waitbar not used
set(handles.waitbar_1,'Position',[0.946 0.876 0.03 0.001])
set(handles.waitbar_patch1,'Position',[0.946 0.439 0.03 0.001])
set(handles.waitbar_civ2,'Position',[0.946 0.219 0.03 0.001])
set(handles.waitbar_patch2,'Position',[0.946 0.0 0.03 0.001])
drawnow

%% set the list of files and check them
display('checking the files...')
compare=get(handles.compare,'Value');%test for usual PIV (compare=1) or displacement (=2) or stereo PIV (=3)
[filecell,num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2,nom_type_nc]=...
    set_civ_filenames(handles,compare,box_test);
if isempty(filecell)% (error message displayed in fct set_civ_filenames)
    return
end
nbfield=numel(num1_civ1);
nbslice=numel(num_a_civ1);

%% choice of batch priority
ind_answer=2;
if batch
    [s,w]=unix('qstat -q civ.q|grep job_| wc -l'); %check the waiting list (command unix)
    if isequal(s,0)
        w(end)=[];
        str_displ={[w ' jobs in the waiting list'];'Select a priority:'};
        str={'urgent';'normal';'low'};
        [ind_answer,v] = listdlg('PromptString',str_displ,...
            'SelectionMode','single',...
            'ListString',str,'ListSize',[200 200],'Name','job priority','InitialValue',3);
        if isequal(v,0) % to handle Cancel button and figure close,
            return % a better way should be create
        end
    else
        msgbox_uvmat('ERROR','batch system not available')
        return
    end
else
    if isunix
        [xx,w]=unix('ps faux |grep civ|wc -l');
        w(end)=[];
        if str2double(w)+numel(num1_civ1)> 50
            msgbox_uvmat('ERROR',{['There are already ' w ' civ processes running locally'];'Use BATCH or submit RUN later'})
            return
        end
    end
end


%% read names of the .exe files for PIV and patch
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
        if ~ismember(sparam.BatchMode,{'sge'})
            msgbox_uvmat('ERROR',['batch mode ' sparam.BatchMode ' not supported by UVMAT'])
        end
    else
        msgbox_uvmat('ERROR','no batch mode defined in PARAM.xml')
        return
    end
else
    if isfield(s,'RunParam')
        sparam=s.RunParam;
    else
        msgbox_uvmat('ERROR','no civ binaries defined in PARAM.xml')
        return
    end
    if isfield(sparam,'CivBin')
        if ~exist(sparam.CivBin,'file')
            sparam.CivBin=fullfile(path_UVMAT,sparam.CivBin);
        end
    end
    if isfield(sparam,'Civ1Bin')
        if ~exist(sparam.Civ1Bin,'file')
            sparam.Civ1Bin=fullfile(path_UVMAT,sparam.Civ1Bin);
        end
    end
    if isfield(sparam,'Civ2Bin')
        if ~exist(sparam.Civ2Bin,'file')
            sparam.Civ2Bin=fullfile(path_UVMAT,sparam.Civ2Bin);
        end
    end
    %test_interp=get(handles.test_interp,'Value');

    if  isfield(sparam,'PatchBin')
        if ~exist(sparam.PatchBin,'file')
            sparam.PatchBin=fullfile(path_UVMAT,sparam.PatchBin);
        end
    end
    % if test_interp && isfield(sparam,'PatchNewBin')
    %     if ~exist(sparam.PatchNewBin,'file')
    %          sparam.PatchNewBin=fullfile(path_UVMAT,sparam.PatchNewBin);
    %     end
    % end
    if isfield(sparam,'FixBin')
        if ~exist(sparam.FixBin,'file')
            sparam.FixBin=fullfile(path_UVMAT,sparam.FixBin);
        end
    end
end
if batch
    if isfield(sparam,'BatchMode')
        batch_mode=sparam.BatchMode;
    end
else
%     MaxCivProcesses=50;
%     if isfield(sparam,'MaxCivProcesses')
%         MaxCivProcesses=str2double(sparam.MaxCivProcesses);
%     end
end


%% get civ1 parameters:
display('files OK, processing...')
%get civ parameters
if box_test(1)==1
    par_civ1=read_param_civ1(handles,filecell.ima1.civ1{1,1});
end

%% get fix1 parameters
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
    %              test_interp=get(handles.test_interp,'Value');
end

%% MAIN LOOP
time=get(handles.RootName,'UserData'); %get the set of times
civAll=get(handles.Experimental,'Value'); % Boolean for new civ excution method
super_cmd=[];

for ifile=1:nbfield
    for j=1:nbslice
        i_cmd=0;
        cmd='';
        if isunix % check: necessaire aussi en RUN?
            %fid=fopen([filename '.cmx'],'w')
            cmd='#!/bin/bash \n';
            cmd=[cmd '#$ -cwd \n'];
            cmd=[cmd 'hostname && date \n'];
            cmd=[cmd 'umask 002 \n'];
        end
        if civAll
            civAllxml=xmltree;% xml contents,  all parameters
            civAllCmd='';
            civAllxml=set(civAllxml,1,'name','CivDoc');
        end
        filename_cmx=filecell.nc.civ1{ifile,j};%output netcdf file
        filename_cmx(end-1:end+1)='cmx';%name of cmx file
        
        %CIV1
        if box_test(1)==1
            par_civ1.filename_ima_a=filecell.ima1.civ1{ifile,j};
            par_civ1.filename_ima_b=filecell.ima2.civ1{ifile,j};
            namelog=[filename_cmx([1:end-3]) 'log'];
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
            %
            i_cmd=i_cmd+1;
            if isequal(civAll,0)
                cmd=[cmd CIV1_CMD(filename_cmx(1:end-4),namelog,par_civ1,handles,sparam) '\n'];
            else
                civAllCmd=[civAllCmd ' civ1 '];
                str=CIV1_CMD_Unified(filename_cmx([1:end-4]),namelog,par_civ1);
                fieldnames=fields(str);
                [civAllxml,uid_civ1]=add(civAllxml,1,'element','civ1');
                for ilist=1:length(fieldnames)
                    val=eval(['str.' fieldnames{ilist}]);
                    if ischar(val)
                        [civAllxml,uid_t]=add(civAllxml,uid_civ1,'element',fieldnames{ilist});
                        [civAllxml,uid_t2]=add(civAllxml,uid_t,'chardata',val);
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
            if isequal(civAll,0)
                cmd_FIX=[sparam.FixBin ' -f ' filecell.nc.civ1{ifile,j} ' -fi1 ' num2str(flagindex1(1)) ...
                    ' -fi2 ' num2str(flagindex1(2)) ' -fi3 ' num2str(flagindex1(3)) ...
                    ' -threshC ' num2str(thresh_vecC1) ' -threshV ' num2str(thresh_vel1) ' -maskName ' maskname];
                cmd_FIX=regexprep(cmd_FIX,'\\','\\\\');
                cmd=[cmd cmd_FIX '\n'];
            else
                fix1.inputFileName=filecell.nc.civ1{ifile,j} ;
                fix1.fi1=num2str(flagindex1(1));
                fix1.fi2=num2str(flagindex1(2));
                fix1.fi3=num2str(flagindex1(3));
                fix1.threshC=num2str(thresh_vecC1);
                fix1.threshV=num2str(thresh_vel1);
                fieldnames=fields(fix1);
                [civAllxml,uid_fix1]=add(civAllxml,1,'element','fix1');
                for ilist=1:length(fieldnames)
                    val=eval(['fix1.' fieldnames{ilist}]);
                    if ischar(val)
                        [civAllxml,uid_t]=add(civAllxml,uid_fix1,'element',fieldnames{ilist});
                        [civAllxml,uid_t2]=add(civAllxml,uid_t,'chardata',val);
                    end
                end
                civAllCmd=[civAllCmd ' fix1 '];
            end
        end
        
        %PATCH1
        if box_test(3)==1
            if isequal(civAll,0)
                cmd_PATCH=PATCH_CMD(filecell.nc.civ1{ifile,j},nx_patch1,ny_patch1,rho_patch1,subdomain_patch1,thresh_patch1,test_interp,sparam.PatchBin);
                cmd_PATCH=regexprep(cmd_PATCH,'\\','\\\\');
                cmd=[cmd cmd_PATCH '\n'];
            else
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
                [civAllxml,uid_patch1]=add(civAllxml,1,'element','patch1');
                for ilist=1:length(fieldnames)
                    val=eval(['patch1.' fieldnames{ilist}]);
                    if ischar(val)
                        [civAllxml,uid_t]=add(civAllxml,uid_patch1,'element',fieldnames{ilist});
                        [civAllxml,uid_t2]=add(civAllxml,uid_t,'chardata',val);
                    end
                end
                civAllCmd=[civAllCmd ' patch1 '];
            end
        end
        
        if box_test(4)==1 || box_test(5)==1 || box_test(6)==1
            filename_cmx=filecell.nc.civ2{ifile,j};%output netcdf file
            filename_cmx([end-1:end+1])=[ 'cmx'];%name of cmx file
%             filename_cmx=[filename_cmx 'x'];
        end
        
        if box_test(4)==1
            par_civ2.filename_ima_a=filecell.ima1.civ2{ifile,j};
            %par_civ2.filename_ima_a([end-3:end])=[];%remove .png extension
            par_civ2.filename_ima_b=filecell.ima2.civ2{ifile,j};
            %par_civ2.filename_ima_b([end-3:end])=[];%remove .png extension
            namelog=[filename_cmx([1:end-3]) 'log'];
            par_civ2.Dt=num2str(time(num2_civ2(ifile),num_b_civ2(j))-time(num1_civ2(ifile),num_a_civ2(j)));
            par_civ2.T0=num2str((time(num2_civ1(ifile),num_b_civ2(j))+time(num1_civ2(ifile),num_a_civ2(j)))/2);
            par_civ2.term_a=num2stra(num_a_civ2(j),nom_type_nc);
            par_civ2.term_b=num2stra(num_b_civ2(j),nom_type_nc);
            par_civ2.filename_nc1=filecell.nc.civ1{ifile,j};
            par_civ2.filename_nc1([end-2:end])=[]; % remove '.nc'
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
            %TESTgrid
            %test_grid=get(handles.browse_gridciv2,'Value');
            gridname=get(handles.grid_civ2,'String');
            %gridflag='y';
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
            %endTESTgrid
            i_cmd=i_cmd+1;
            cmd_CIV2=CIV2_CMD(filename_cmx(1:end-4),namelog,par_civ2,sparam);
            if isequal(civAll,0)
                if(isunix)
                    cmd=[cmd 'cp -f ' filename_cmx '2 ' filename_cmx '\n' cmd_CIV2 '\n'];
                else
                    filename_cmx=regexprep(filename_cmx,'\\','\\\\');
                    cmd=[cmd 'copy /Y ' filename_cmx '2 ' filename_cmx '\n' cmd_CIV2 '\n'];
                end
            else
                civAllCmd=[civAllCmd ' civ2 '];
                str=CIV2_CMD_Unified(filename_cmx([1:end-4]),namelog,par_civ2);
                fieldnames=fields(str);
                [civAllxml,uid_civ2]=add(civAllxml,1,'element','civ2');
                for ilist=1:length(fieldnames)
                    val=eval(['str.' fieldnames{ilist}]);
                    if ischar(val)
                        [civAllxml,uid_t]=add(civAllxml,uid_civ2,'element',fieldnames{ilist});
                        [civAllxml,uid_t2]=add(civAllxml,uid_t,'chardata',val);
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
            if isequal(civAll,0)
                cmd_FIX=[sparam.FixBin ' -f ' filecell.nc.civ2{ifile,j} ' -fi1 ' num2str(flagindex2(1)) ...
                    ' -fi2 ' num2str(flagindex2(2)) ' -fi3 ' num2str(flagindex2(3)) ...
                    ' -threshC ' num2str(thresh_vec2C) ' -threshV ' num2str(thresh_vel2) ' -maskName ' maskname];
                cmd_FIX=regexprep(cmd_FIX,'\\','\\\\');
                cmd=[cmd cmd_FIX '\n'];
            else
                fix2.inputFileName=filecell.nc.civ2{ifile,j} ;
                fix2.fi1=num2str(flagindex2(1));
                fix2.fi2=num2str(flagindex2(2));
                fix2.fi3=num2str(flagindex2(3));
                fix2.threshC=num2str(thresh_vec2C);
                fix2.threshV=num2str(thresh_vel2);
                fieldnames=fields(fix2);
                [civAllxml,uid_fix2]=add(civAllxml,1,'element','fix2');
                for ilist=1:length(fieldnames)
                    val=eval(['fix2.' fieldnames{ilist}]);
                    if ischar(val)
                        [civAllxml,uid_t]=add(civAllxml,uid_fix2,'element',fieldnames{ilist});
                        [civAllxml,uid_t2]=add(civAllxml,uid_t,'chardata',val);
                    end
                end
                civAllCmd=[civAllCmd ' fix2 '];
            end
        end
        
        %PATCH2
        if box_test(6)==1
            if isequal(civAll,0)
                cmd_PATCH=PATCH_CMD(filecell.nc.civ2{ifile,j},nx_patch2,ny_patch2,rho_patch2,subdomain_patch2,thresh_patch2,test_interp,sparam.PatchBin);
                cmd_PATCH=regexprep(cmd_PATCH,'\\','\\\\');
                cmd=[cmd cmd_PATCH '\n'];
            else
                patch2.inputFileName=filecell.nc.civ1{ifile,j} ;
                patch2.nopt=subdomain_patch1;
                patch2.maxdiff=thresh_patch1;
                patch2.ro=rho_patch1;
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
                [civAllxml,uid_patch2]=add(civAllxml,1,'element','patch2');
                for ilist=1:length(fieldnames)
                    val=eval(['patch2.' fieldnames{ilist}]);
                    if ischar(val)
                        [civAllxml,uid_t]=add(civAllxml,uid_patch2,'element',fieldnames{ilist});
                        [civAllxml,uid_t2]=add(civAllxml,uid_t,'chardata',val);
                    end
                end
                civAllCmd=[civAllCmd ' patch2 '];
            end
        end
        if isequal(civAll,1)
            save(civAllxml,[filename_cmx([1:end-4]) '.xml']);
            %cmd=char({cmd;[CivBin ' -f ' [filename_cmx([1:end-4]) '.xml'] ' ' civAllCmd]});
            cmd=[cmd CivBin ' -f ' filename_cmx(1:end-4) '.xml '  civAllCmd  '\n'];
        end
        % create the .bat file:
        if batch
            [Rootbat,Filebat,extbat]=fileparts(filename_cmx);
            filename_bat=fullfile(Rootbat,['job_' Filebat extbat]);
         else
            filename_bat=filename_cmx;
        end
        filename_bat(end-2:end)='bat';
        fid=fopen(filename_bat,'w');
        fprintf(fid,cmd);
        fclose(fid);
        %dlmwrite(filename_bat,cmd,'');%write commands in filename_bat
        if batch
            switch batch_mode
                case 'sge'
                    pvalue=num2str((1-ind_answer)*500);
                    %namelog=[filename_bat '.patch.log'];
                    display(['!qsub -p ' pvalue ' -q civ.q -e ' filename_cmx(1:end-4) '.errors -o ' filename_cmx(1:end-4) '.log' ' ' filename_bat]);
                    eval(  ['!qsub -p ' pvalue ' -q civ.q -e ' filename_cmx(1:end-4) '.errors -o ' filename_cmx(1:end-4) '.log' ' ' filename_bat]);
            end
        else
            %% to lauch the jobs locally :
            if(isunix)
                cmd_str=['. ' filename_bat];
                % cmd_str=['!at -qb now -f ' filename_bat ' &']; %ou at -qb now -f bad idea...
            else %case of Windows
                cmd_str=['@call ' regexprep(filename_bat,'\\','\\\\')];
            end
            super_cmd=[super_cmd cmd_str '\n'];         
            %             eval(cmd_str);
            disp(cmd_str);
        end
    end
end

if ~batch
    [Rootbat,Filebat,extbat]=fileparts(filename_cmx);
    filename_superbat=fullfile(Rootbat,['job_list.bat']);
    fid=fopen(filename_superbat,'w');
    fprintf(fid,super_cmd');
    fclose(fid);
    if(isunix)
        eval(['!. ' filename_superbat ' &']);
    else
        eval(['!' filename_superbat ' &']);
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



function [filecell,num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2,nom_type_nc,file_ref_fix1,file_ref_fix2]=...
    set_civ_filenames(handles,compare,box_test)
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
    find_pair_indices(handles,mode);
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
        num_i_ref=[first_i:incr_i:last_i];
        num_j_ref=[first_j:incr_j:last_j];
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
if isequal(subdir_civ1,''),subdir_civ1='A'; end% put default subdir
if isequal(subdir_civ2,''),subdir_civ2=subdir_civ1; end% put default subdir
currentdir=pwd;%store the current working directory
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
    cd(currentdir);
    return
end

%check the existence of the netcdf and image files involved
% %%%%%%%%%%%%  case CIV1 activated   %%%%%%%%%%%%%
if box_test(1)==1;
    detect=1;
    vers=0;
    subdir_civ1_new=subdir_civ1;
    ind_test=0;
    while detect==1 && ind_test<10%create a new subdir if the netcdf files already exist
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
            cd(Path_ima);          
            [xx,msg1]=mkdir(subdir_civ1_new);

            if ~strcmp(msg1,'')
                msgbox_uvmat('ERROR',['cannot create ' subdir_civ1_new ': ' msg1])%error message for directory creation
                filecell={};
                return
            else          
                [xx,msg2] = fileattrib(subdir_civ1_new,'+w','g'); %yield writing access (+w) to user group (g)
                if ~strcmp(msg2,'')
                    msgbox_uvmat('ERROR',['pb of permission for  ' subdir_civ1_new ': ' msg2])%error message for directory creation
                    filecell={};
                    return
                end
            end
            cd(currentdir);
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
            if exist(fullfile(Path_ima,subdir_civ1_new),'dir')
                   cd(Path_ima);          
                [xx,msg1]=mkdir(subdir_civ1_new);
                            cd(currentdir);
                if ~strcmpl(msg1,'')
                    msgbox_uvmat('ERROR',['cannot create ' subdir_civ1_new ': ' msg1])
                    cd(currentdir)
                    filecell={};
                    return
                else
                    [xx,msg2] = fileattrib(subdir_civ1_new,'+w','g'); %yield writing access (+w) to user group (g)
                    if ~strcmp(msg2,'')
                        msgbox_uvmat('ERROR',['pb of permission for ' subdir_civ1_new ': ' msg2])%error message for directory creation
                        cd(currentdir)
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
            cd(currentdir)
            return
        end
        [idetectmin,indexj]=min(idetect_1);
        if idetectmin==0,
            msgbox_uvmat('ERROR',[filecell.ima2.civ1{ifile,indexj} ' not found'])
            filecell={};
            cd(currentdir)
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
                cd(currentdir)
                return
            end
            [idetectmin,indexj]=min(idetect_1);
            if idetectmin==0,
                msgbox_uvmat('ERROR',[filecell.imaA2.civ1{ifile,indexj} ' not found'])
                filecell={};
                cd(currentdir)
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
                cd(currentdir)
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
                    cd(currentdir)
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
            [xx,m2]=mkdir(subdir_civ2_new);
            [xx,msg2] = fileattrib(subdir_civ2_new,'+w','g'); %yield writing access (+w) to user group (g)
            if ~isequal(m2,'')
                msgbox_uvmat('ERROR',['cannot create ' subdir_civ2_new ': ' m2])
                filecell={};
                cd(currentdir)
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
                 [xx,msg2] = fileattrib(subdir_civ2_new,'+w','g'); %yield writing access (+w) to user group (g)
                if ~isequal(m2,'')
                    msgbox_uvmat('ERROR', ['cannot create ' subdir_civ2_new ': ' m2])%error message for directory creation
                    cd(currentdir)
                    filecell={};
                    return
                end
            end
        end
    end
    subdir_civ2=subdir_civ2_new;
end
cd(currentdir);%come back to the current working directory

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
                        Data=nc2struct(filename,'ListGlobalAttribute','civ2');
                        if isempty(Data.civ2)||isequal(Data.civ2,0)
                            msgbox_uvmat('ERROR',['no civ2 data in ' filename])
                            filecell=[];
                            return
                        end
                    elseif box_test(3)==0; %check the existence of patch if it is not calculated
                        Data=nc2struct(filename,'ListGlobalAttribute','patch');
                        if isempty(Data.patch)||isequal(Data.patch,0)
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
                    Data=nc2struct(filename,'ListGlobalAttribute','civ2');
                    if isempty(Data.civ2)||isequal(Data.civ2,0)
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
        h = waitbar(0,['copy images to the .png format for civ1']);% display a wait bar
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
        h = waitbar(0,['copy images to the .png format for civ2']);% display a wait bar
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
% --- PATCH
function cmd_PATCH=PATCH_CMD(filename_nc,nx_patch,ny_patch,rho_patch,subdomain_patch,thresh_value,test_interp,PatchBin)
%------------------------------------------------------------------------
namelog=[filename_nc([1:end-3]) '_patch.log'];
if test_interp==0
    cmd_PATCH=[PatchBin ' -f ' filename_nc ' -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ' -nopt ' subdomain_patch ...
        '  > ' namelog ' 2>&1']; % redirect standard output to the log file
else %nouveau programme patch
    cmd_PATCH=[PatchBin ' -f ' filename_nc ' -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ...
        ' -max ' thresh_value ' -nopt ' subdomain_patch  '  > ' namelog ' 2>&1']; % redirect standard output to the log file
end

%------------------------------------------------------------------------
% --- STEREO Interp
function cmd=RUN_STINTERP(stinterpBin,filename_A_nc,filename_B_nc,filename_nc,nx_patch,ny_patch,rho_patch,subdomain_patch,thresh_value,xmlA,xmlB)
%------------------------------------------------------------------------
namelog=[filename_nc([1:end-3]) '_stinterp.log'];
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
maskval=get(handles.get_mask_civ1,'Value');
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
        if isequal(flag_mask_a,0) | ~isequal(nbslice_a,nbslice)
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
        if isequal(flag_mask_a,0) | ~isequal(nbslice_a,nbslice)
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
        if isequal(flag_mask_a,0) | ~isequal(nbslice_a,nbslice)
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
function mask_civ1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.mask_civ1,'UserData',[])
set(handles.mask_civ1,'String','')

%------------------------------------------------------------------------
function mask_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.mask_civ2,'UserData',[])
set(handles.mask_civ2,'String','')

%------------------------------------------------------------------------
function mask_fix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.mask_fix1,'UserData',[])
set(handles.mask_fix1,'String','')

%------------------------------------------------------------------------
function mask_fix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.mask_fix2,'UserData',[])
set(handles.mask_fix2,'String','')

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
        if isempty(FileName)|isempty(PathName)|isequal(FileName,0)|~exist(filegrid,'file')
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
if isequal(state,0)
    state='off';
end
if isequal(state,1)
    state='on';
end
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
global patch_newBin
set(handles.frame_patch1,'BackgroundColor',[1 1 0])
set(handles.rho_patch1,'Visible','on')
set(handles.rho_text1,'Visible','on')
set(handles.thresh_patch1,'Visible','on')
set(handles.thresh_text1,'Visible','on')
set(handles.subdomain_patch1,'Visible','on')
set(handles.subdomain_text1,'Visible','on')
set(handles.nx_patch1,'Visible','on')
set(handles.ny_patch1,'Visible','on')
set(handles.nx_patch1_title,'Visible','on')
set(handles.ny_patch1_title,'Visible','on')
% if ~isempty(patch_newBin)
%     set(handles.test_interp,'Visible','on');
% end
set(handles.get_gridpatch1,'Visible','on')
set(handles.grid_patch1,'string','none');
set(handles.grid_patch1,'Visible','on')

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
%set(handles.test_interp,'Visible','off')
set(handles.get_gridpatch1,'Visible','off')
set(handles.grid_patch1,'Visible','off')

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
set(handles.get_gridpatch2,'Visible','on')
set(handles.grid_patch2,'Visible','on')
set(handles.list_pair_civ2,'Visible','on')
set(handles.subdir_civ2,'Visible','on')
set(handles.subdir_civ2_text,'Visible','on')

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
set(handles.get_gridpatch2,'Visible','off')
set(handles.grid_patch2,'Visible','off')
if isequal(get(handles.CIV2,'Value'),0) & isequal(get(handles.FIX2,'Value'),0)
    set(handles.list_pair_civ2,'Visible','off')
    set(handles.subdir_civ2,'Visible','off')
    set(handles.subdir_civ2_text,'Visible','off')
end

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
%      end
A=imread(file_ima);%read the first image to get the size
sizim=size(A);
par.npx=num2str(sizim(2));
par.npy=num2str(sizim(1));
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

if isequal(par.Dt,'0')
    par.Dt='1' ;%case of 'displacement' mode
end
%
%     textcmx={'##############   CMX file';...
%     ['FirstImage ' par.filename_ima_a];...
%     ['LastImage  ' par.filename_ima_b];...
%     'XX' ;...
%     ['Mask ' par.maskflag] ;...
%     ['MaskName ' par.maskname];...
%     ['ImageSize ' par.npx ' ' par.npy];...   %VERIFIER CAS GENERAL ?
%     ['CorrelationBoxesSize ' par.ibx ' ' par.iby];...
%     ['SearchBoxeSize ' par.isx ' ' par.isy];...
%     ['RO ' par.rho];...
%     ['GridSpacing ' par.dx ' ' par.dy];...
%     'XX 1.0';...
%     ['Dt_TO ' par.Dt ' ' par.T0];...
%     ['PixCmXY ' par.pxcmx ' ' par.pxcmy];...
%     'XX 1';...
%     ['ShiftXY ' par.shiftx ' '  par.shifty];...
%     ['Grid ' par.gridflag];...
%     ['GridName ' par.gridname] ;...
%     'XX 85';...
%     'XX 1.0';...
%     'XX 1.0';...
%     'Hart 1';...
%     'DecimalShift 0';...
%     'Deformation 0';...
%     'CorrelationMin 0';...
%     'IntensityMin 0';...
%     'SeuilImage n';...
%     'SeuilImageValues 0 4096';...
%     ['ImageToUse ' par.term_a ' ' par.term_b];... % VERIFIER ?
%     'ImageUsedBefore null null'};
%
%             textout=char(textcmx);
par.filename_ima_a=regexprep(par.filename_ima_a,'.png','');
par.filename_ima_b=regexprep(par.filename_ima_b,'.png','');
fid=fopen([filename '.cmx'],'w');
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

cmd_CIV1=[sparam.Civ1Bin ' -f ' filename '.cmx >' filename '.log' ]; % redirect standard output to the log file
cmd_CIV1=regexprep(cmd_CIV1,'\\','\\\\');
namelog=regexprep(namelog,'\\','\\\\');

if(isunix)
    [Rootbat,Filebat,extbat]=fileparts(namelog);
    ncName=fullfile(Rootbat,[ Filebat '.nc']);
    cmd_CIV1=[cmd_CIV1 '\n' 'mv ' namelog  ' ' regexprep(namelog,'\.log','') '.civ1.log' '\n' 'chmod g+w ' ncName];
else
    cmd_CIV1=[cmd_CIV1 '\n' 'copy /Y ' namelog ' ' regexprep(namelog,'\.log','') '.civ1.log'];
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
% textcmx=['##############   CMX file'  '\n'...
% ['FirstImage ' par.filename_ima_a]  '\n'...
% ['LastImage  ' par.filename_ima_b]  '\n'...
% 'XX'   '\n'...
% ['Mask ' par.maskflag]  '\n'...
% ['MaskName ' par.maskname]  '\n'...
% ['ImageSize ' par.npx ' ' par.npy]  '\n'...
% ['CorrelationBoxesSize ' par.ibx ' ' par.iby]  '\n'...
% ['SearchBoxeSize ' par.ibx ' ' par.iby]  '\n'...
% ['RO ' par.rho]  '\n'...
% ['GridSpacing ' par.dx ' ' par.dy]  '\n'...
% 'XX 1.0'  '\n'...
% ['Dt_TO ' par.Dt ' ' par.T0]  '\n'...
% ['PixCmXY ' par.pxcmx ' ' par.pxcmy]  '\n'...
% 'XX 1'  '\n'...
% ['ShiftXY 0 0']  '\n'...
% ['Grid ' par.gridflag]  '\n'...
% ['GridName ' par.gridname]  '\n'...
% 'XX 85'  '\n'...
% 'XX 1.0'  '\n'...
% 'XX 1.0'  '\n'...
% 'Hart 1'  '\n'...
% ['DecimalShift ' par.decimal]  '\n'...
% ['Deformation ' par.deformation]  '\n'...
% 'CorrelationMin 0'  '\n'...
% 'IntensityMin 0'  '\n'...
% 'SeuilImage n'  '\n'...
% 'SeuilImageValues 0 4096'  '\n'...
% ['ImageToUse ' par.term_a ' ' par.term_b]  '\n'... % VERIFIER ?
% ['ImageUsedBefore ' par.filename_nc1]];
% textout=char(textcmx);
% fid=fopen([filename_cmx '2'],'w');
% fprintf(fid,textout);
% fclose(fid)

par.filename_ima_a=regexprep(par.filename_ima_a,'.png','');
par.filename_ima_b=regexprep(par.filename_ima_b,'.png','');% bug : .png appears two times ?
fid=fopen([filename '.cmx2'],'w');
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

cmd_CIV2=[sparam.Civ2Bin ' -f ' filename  '.cmx >' filename '.log' ]; % redirect standard output to the log file
cmd_CIV2=regexprep(cmd_CIV2,'\\','\\\\');
namelog=regexprep(namelog,'\\','\\\\');

if(isunix)
    [Rootbat,Filebat,extbat]=fileparts(namelog);
    ncName=fullfile(Rootbat,[ Filebat '.nc']);
    cmd_CIV2=[cmd_CIV2 '\n' 'mv ' namelog  ' ' regexprep(namelog,'\.log','') '.civ2.log' '\n' 'chmod g+w ' ncName];
else
    cmd_CIV2=[cmd_CIV2 '\n' 'copy /Y ' namelog ' ' regexprep(namelog,'\.log','') '.civ2.log'];
end



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
if test==2 || test==3
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
    else
        set(handles.mode,'Visible','on')
    end
    
    % open an image file with the browser
    ind_opening=1;%default
    browse.incr_pair=[0 0]; %default
    oldfile=get(handles.RootName,'String');
    menu={'*.xml;*.avi;*.AVI;*.nc','(*.xml,*.avi,*.nc)'; ...
        '*.xml', '.xml files';'*.avi;*.AVI', '.avi files';'*.nc', '.nc files';...
        '*.*', 'All Files (*.*)'};
    [FileName, PathName, filtindex] = uigetfile( menu, 'Pick a file',oldfile);
    fileinput=[PathName FileName];%complete file name
    sizf=size(fileinput);
    if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
    [path,name,ext]=fileparts(fileinput);
    [path1]=fileparts(filebase);
    if ~strcmp(path1,path)
        msgbox_uvmat('ERROR','The two  input image series must be in the same directory')
        return
    end
    set(handles.RootName_1,'String',name);
    [RootPath,RootFile,field_count,str2,str_a,str_b,xx,nom_type,subdir]=name2display(name);
    browse=get(handles.browse_root,'UserData');
    browse.nom_type_ima_1=nom_type;
    set(handles.browse_root,'UserData',browse)
    
    %check image extension
    if ~strcmp(ext,get(handles.ImaExt,'String'))
        msgbox_uvmat('ERROR','The two  input image series must have the same extenion name')
        return
    end
    
    %check image size
    A=imread(fileinput);
    npxy=get(handles.ImaExt,'UserData');
    if ~isequal(npxy(1),size(A,1))|| ~isequal(npxy(2),size(A,2))
        msgbox_uvmat('ERROR','The two input image series must have the same size')
        return
    end
else
    set(handles.mode,'Visible','on')
    set(handles.RootName_1,'Visible','Off');
    set(handles.sub_txt,'Visible','off')
    set(handles.RootName_1,'String',[]);
    mode_store=get(handles.compare,'UserData');
    set(handles.mode,'String',mode_store)
    set(handles.test_stereo1,'Value',0)
    set(handles.test_stereo2,'Value',0)
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




