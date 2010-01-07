%'civ_3D': function associated with the interface 'civ_3D.fig' for PIV in volume   
%------------------------------------------------------------------------
%  provides an interface for the software CIVx
% function varargout = civ_3D(varargin)
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
function varargout = civ_3D(varargin)

% Last Modified by GUIDE v2.5 25-Feb-2009 23:14:16
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @civ_3D_OpeningFcn, ...
                   'gui_OutputFcn',  @civ_3D_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%--------------------------------------------------------------------------
% --- Executes just before civ_3D is made visible.
%--------------------------------------------------------------------------
function civ_3D_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to civ_3D (see VARARGIN)
global test_batch patch_new_exe%=1 if patch processing available
%filebase: root name 
%nom_type: nomencalture used ('png_old','_i_j'...)
%list of field numbers to process
%subdir: subdirectory of the opened netcdf file 
%ind_opening: operation number advised for beginning (1=civ1,2=fix1,3=patch1,4=civ2,5=fix2,6=patch2),
%ind_a_opening ind_b_opening chosen pair from the opened netcdf file
% Choose default command line output for civ_3D
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

%default initial parameters
filebase=''; % root file name ('filebase'.civ_3D)
nom_type=[]; % nomenclature type
ext=[];
testall=0; 
browse=[];

%load the initial parameters if the interface is started from uvmat 
if ~isempty(varargin)% the interface is opened from uvmat
    varcell=varargin{1};
    filebase=varcell{1};
    nom_type_read=varcell{2};
    num1=varcell{3};
    num2=varcell{4};
    num_a=varcell{5};
    num_b=varcell{6};
    subdir=varcell{7};
    ind_opening=varcell{8};
    ind_a_opening=varcell{9};
    ind_b_opening=varcell{10};
    ext=varcell{11};
else
    num1=1; % set of field i numbers
    num2=2; % set of field i numbers
    num_a=1; % set of field j numbers (fields a)
    num_b=1; % second set of field j numbers (fields b)
    subdir='A'; % subdir for the netcdf result files
    ind_opening=1; % proposed operation number (1=civ1,2=fix1,3=patch1,4=civ2,5=fix2,6=patch2)
    ind_a_opening=1; % proposed index in the menu of fields a
    ind_b_opening=2; % proposed index in the menu of fields b   
end

if exist('ext','var') & length(ext)>1 & (~isempty(imformats(ext([2:end])))|...
                       isequal(ext,'.avi')|isequal(ext,'.AVI'));%if an image file has been opened by uvmat
        browse.ext_ima=ext; 
        if exist('nom_type_read','var')
            browse.nom_type_ima=nom_type_read; % the image nomenclature is stored
        end
elseif isequal(ext,'.nc')
    if exist('nom_type_read','var')
        browse.nom_type_nc=nom_type_read;% the netcdf  nomenclature is stored
    end
end
set(handles.displ_filebase,'String',filebase);
set(handles.ImaDoc,'UserData',testall);
set(handles.browse_root,'UserData',browse)
set(handles.ImaDoc,'String',ext)


% set(handles.ImaDoc,'String',ext)
  
%read names of the .exe file to adjust the interface according to
%available prog
%read names of the .exe file
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
if isunix
    syst='LINUX'
    %fid = fopen(fullfile(path_UVMAT,'PARAM_LINUX.txt'),'r');%open the file with civ_3D binary names
    xmlfile=fullfile(path_UVMAT,'PARAM_LINUX.xml')
    if exist(xmlfile,'file')
        t=xmltree(xmlfile);
        sparam=convert(t);
    end
else
    syst='WIN'
    %fid = fopen(fullfile(path_UVMAT,'PARAM_WIN.txt'),'r');%open the file with civ_3D binary names
    xmlfile=fullfile(path_UVMAT,'PARAM_WIN.xml');
    if exist(xmlfile,'file')
        t=xmltree(xmlfile);
        sparam=convert(t);
    end
end
   
patch_new_exe='';
todo_patch='';
sge=0;

if isfield(sparam,'PatchNew_exe')
    patch_new_exe=sparam.PatchNew_exe;
end
if isfield(sparam,'Todo_path')
    todo_path=sparam.Todo_path
end
if isfield(sparam,'SGE')
    sge=str2num(sparam.SGE);
end   
name_todo=fullfile(todo_path,'TODO.txt')
test_batch=1;
if ~sge
if isequal(todo_path,'') |isequal(todo_path,[])
    ['no batch distributed processing available:file path TODO.txt not defined in UVMAT/PARAM_' syst]
    test_batch=0;
end
if exist(name_todo,'file')~=2 
    hwarn=warndlg(['no batch distributed processing available, queue file ' name_todo ' absent']);
  %  test_batch=0;  % Problems to detect file on linux/nfs filesystems
end
end


if test_batch==0
    set(handles.BATCH,'BackgroundColor',[0.831 0.816 0.784])% put the BATCH button in grey (unactivated)
end

set(handles.subdir_civ1,'String',subdir)%default subdir on which uvmat was working
set(handles.subdir_civ2,'String',subdir)%default subdir on which uvmat was working

%initiate advised operations
if isequal(ind_opening,[])
    ind_opening=1; % default
end
% set default operation options
    enable_civ1(handles,'off')
    enable_civ2(handles,'off')
    desable_fix1(handles)
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
    enable_fix1(handles)
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
elseif isequal(ind_opening,6)
    set(handles.PATCH2,'Value',1)
    enable_patch2(handles)
    set(handles.frame_subdirciv2,'BackgroundColor',[1 1 0])
    set(handles.list_pair_civ2,'Enable','On')
end

% set the range of fields (1:1 by default) and selected pair
if isempty(num2)|isequal(num2,num1)
    num_ref_i=num1;
else
    num_ref_i=floor((num1+num2)/2);
    browse.incr_pair(1)=num2-num1;
    browse.incr_pair(2)=0;
end
if isempty(num_b)|isequal(num_a,num_b)
    if isempty(num_a)
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
set(handles.browse_root,'UserData',browse);
if ~isempty(varargin)% the interface is opened from uvmat
    displ_filebase_Callback(hObject, eventdata, handles); 
end

set(handles.waitbar_1,'Position',[0.946 0.877 0.03 0.001])
set(handles.waitbar_patch1,'Position',[0.946 0.626 0.03 0.001])
set(handles.waitbar_civ2,'Position',[0.946 0.406 0.03 0.001])
set(handles.waitbar_patch2,'Position',[0.946 0.187 0.03 0.001])


%--------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
%-----------------------------------------------------------------
function varargout = civ_3D_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;

%------------------------------------------------------------------
% --- Executes on button press in browse_root.
function browse_root_Callback(hObject, eventdata, handles)
%get the input file properties
filebase=get(handles.displ_filebase,'String');
oldfile=''; %default
if isempty(filebase)|isequal(filebase,'')%loads the previously stored file name and set it as default in the file_input box
     dir_perso=prefdir;
     profil_perso=fullfile(dir_perso,'uvmat_perso.mat')
     if exist(profil_perso,'file')
          h=load (profil_perso);
         if isfield(h,'filebase')&ischar(h.filebase)
                 oldfile=h.filebase;
         end
         if isfield(h,'RootPath')&ischar(h.RootPath)
%                 oldfile=h.filebase{1} 
                 oldfile=h.RootPath;
         end
     end
 else
     oldfile=filebase;
 end
testall=get(handles.ImaDoc,'UserData');
ind_opening=1;%default
browse.incr_pair=[0 0]; %default

menu={'*.*', 'All Files (*.*)'; '*.xml;*.vol; *.avi;*.AVI','(*.xml,*.civ,*.avi,*.vol)'; ...
        '*.xml', '.xml files';'*.civ', '.civ files';...
         '*.avi;*.AVI', '.avi files';'*.vol', '.vol files'};

[FileName, PathName, filtindex] = uigetfile( menu, 'Pick a file',oldfile);
fileinput=[PathName FileName];%complete file name 
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
[path,name,ext]=fileparts(fileinput);
testeditxml=0;
if isequal(ext,'.xml')
    testeditxml=1;
    t_browse=xmltree(fileinput);
    head_element=get(t_browse,1);
    if isfield(head_element,'name')& isequal(head_element.name,'ImaDoc')
        testeditxml=0;
    end
end
if testeditxml==1 | isequal(ext,'.xls')
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
[RootPath,RootFile,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fileinput);
filebase=fullfile(RootPath,RootFile);
if isequal(get(handles.compare,'Value'),1)
    browse=get(handles.browse_root,'UserData');
else
    browse=[];%initialisation
end
if length(ext)>1 & (~isempty(imformats(ext([2:end])))||...
                       isequal(lower(ext),'.avi')||isequal(ext,'.vol'));%if an image file has been opened by uvmat
    browse.ext_ima=ext; 
    browse.nom_type_ima=nom_type;
    browse.field_count=str2num(field_count);
end
set(handles.ImaDoc,'String',ext);
%%%%% read the state of the selected netcdf file to advise default operation
if isequal(ext,'.nc')
    browse.nom_type_nc=nom_type;
    ind_opening=2;% propose 'fix' as the default option    
    Data=nc2struct(fileinput,[]);
    if isfield(Data,'fix') & isequal(Data.fix,1)
        ind_opening=3;
    end
    if isfield(Data,'patch') & isequal(Data.patch,1)
        ind_opening=4;
    end
    if isfield(Data,'civ2') & isequal(Data.civ2,1)
        ind_opening=5;
    end
    if isfield(Data,'fix2') & isequal(Data.fix2,1)
        ind_opening=6;
    end
    if isfield(Data,'pixcmx') & isequal(Data,'pixcmy')
        browse.pxcmx=Data.pixcmx;
        browse.pxcmy=Data.pixcmy;
    end
    testciv=1; %TO SUPPRESS WITH NEW VERSION OF CIVX
    subdir='';%default
    if testciv
        [Pathbase,Namebase]=fileparts(filebase)
        [Pathprev,subdir,extdir]=fileparts(Pathbase)
        subdir=[subdir extdir]
%         if isequal (subdir,subdir_obs)
        filebase=fullfile(Pathprev,Namebase)% move upward to get the base name (corresponding to the .civ_3D file and images)
%         end
    end
    set(handles.subdir_civ1,'String',subdir);%set the default subdir directories for installing the .nc results
    set(handles.subdir_civ2,'String',subdir);
    browse.testciv=testciv;
    browse.ind_opening=ind_opening;
end
set(handles.displ_filebase,'String',filebase);
set(handles.ImaDoc,'String',ext);
if ~isempty(str2num(field_count))
    ref_i=str2num(field_count);
    if ~isempty(str2num(str2))
        ref_i=floor((ref_i+str2num(str2))/2);% reference image number corresponding to the file
        browse.incr_pair(1)=str2num(str2)-str2num(field_count);
        browse.incr_pair(2)=0;
    end
    set(handles.first_i,'String',num2str(ref_i));
    set(handles.last_i,'String',num2str(ref_i));
    set(handles.ref_i,'String',num2str(ref_i)); 
end
if isempty(str2num(str_a))
    set(handles.ref_j,'String','1');
else
    ref_j=str2num(str_a);
    if ~isempty(str2num(str_b))
        ref_j=floor((str2num(str_a)+str2num(str_b))/2);
        browse.incr_pair(2)=str2num(str_b)-str2num(str_a); 
    end
    set(handles.first_j,'String',num2str(ref_j));
    set(handles.last_j,'String',num2str(ref_j));
    set(handles.ref_j,'String',num2str(ref_j)); 
end;
if isequal(ind_opening,1)
    set(handles.CIV1,'Value',1)
    enable_civ1(handles,'on')
elseif isequal(ind_opening,2)
    set(handles.FIX1,'Value',1)
    enable_fix1(handles)
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
elseif isequal(ind_opening,6)
    set(handles.PATCH2,'Value',1)
    enable_patch2(handles)
    set(handles.frame_subdirciv2,'BackgroundColor',[1 1 0])
    set(handles.list_pair_civ2,'Enable','On')
end
set(handles.browse_root,'UserData',browse);% store information from browser
testall=isequal(menu(filtindex,1),{'*.*'});
set(handles.ImaDoc,'UserData',testall);

displ_filebase_Callback(hObject, eventdata, handles);

%------------------------------------------------

function ImaDoc_Callback(hObject, eventdata, handles)
displ_filebase_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------
%function activated when a new filebase (image series) is introduced
%------------------------------------------------------------
function displ_filebase_Callback(hObject, eventdata, handles)

global test_batch
set(gcf,'Pointer','watch')
ext_ima=[]; %default
nom_type_ima=[];%default
field_count=1;%default
nom_type_nc=[];
npx=[];%default 
npy=[];
TimeUnit='s'; %default
CoordUnit='cm';%default
pxcmx_search=[];%default
pxcmy_search=[];%default
filebase=get(handles.displ_filebase,'String');

ext=get(handles.ImaDoc,'String');
browse=get(handles.browse_root,'UserData');%default
if ~isempty(browse) 
    if isfield(browse,'ext_ima')
        ext_ima=browse.ext_ima;
    end
    if isfield(browse,'nom_type_ima')
        nom_type_ima=browse.nom_type_ima;
    end
    if isfield(browse,'field_count')
        field_count=browse.field_count;
    end
end

%default first_i and j and increments
first_i=str2num(get(handles.first_i,'String'));%value possibly set by uvmat_Opening
if isempty(first_i)| first_i < 1
    first_i=1; %default first_i
end
last_i=str2num(get(handles.last_i,'String'));
if isempty(last_i)| last_i < first_i
    last_i=first_i;  %default last_i
end
first_j=str2num(get(handles.first_j,'String'));
if isempty(first_j)| first_j < 1
    first_j=1; %default first_j
end
last_j=str2num(get(handles.last_j,'String'));
if isempty(last_j)| last_j < first_j
    last_j=first_j; %default last_j
end
incr_i=str2num(get(handles.incr_i,'String'));
if isempty(incr_i) | incr_i < 1;
    set(handles.incr_i,'String','1') %default incr_i
end
incr_j=str2num(get(handles.incr_j,'String'));
if isempty(incr_j) | incr_j < 1;
    set(handles.incr_j,'String','1') %default incr_j
end
dt=[];%default
testmode=0;%default
nbfield=1; %default
if isfield(browse,'pxcmx') & isfield(browse,'pxcmy')
    pxcmx=num2str(browse.pxcmx);
    pxcmy=num2str(browse.pxcmy); 
else
    pxcmx=1;%default
    pxcmy=1; 
end
 %look for an image documentation file
if ~isequal(ext,'.xml') & ~ isequal(ext,'.avi')& ~ isequal(ext,'.AVI')
    if exist([filebase '.xml'],'file')
         ext='.xml';
         set(handles.ImaDoc,'String','.xml')
    elseif exist([filebase '.civ_3D'],'file')
         ext='.civ_3D';
         set(handles.ImaDoc,'String','.civ_3D')
    elseif exist([filebase '.avi'],'file') 
         ext='.avi';
         set(handles.ImaDoc,'String','.avi')
    elseif exist([filebase '.AVI'],'file')
         ext='.AVI';
         set(handles.ImaDoc,'String','.AVI')
    end
end
%%%%%%%%   read image documentation file  %%%%%%%%%%%%%%%%%%%%%%%%%%%
    mode=''; %default
    %read the image documentation file if found
if  isequal(ext,'.xml')
    set(handles.ref_i,'Visible','On')%use a reference index
    set(handles.ref_j,'Visible','On')
    set(handles.dt,'Visible','Off')
    set(handles.dt_text,'String','ref. ind.')
elseif isequal(ext,'.avi') | isequal(ext,'.AVI')
    set(handles.ref_j,'Visible','Off')
    set(handles.dt,'Visible','Off')
    set(handles.dt_text,'String','ref. ind.')
else
    set(handles.ref_i,'Visible','Off')
    set(handles.ref_j,'Visible','Off')
    set(handles.dt,'Visible','On')
    set(handles.dt_text,'String','dt(ms)=')
end

if isequal(ext,'.xml')
    [XmlData,warntext]=imadoc2struct([filebase '.xml']);
        if isfield(XmlData,'Heading')&&isfield(XmlData.Heading','ImageName')
            [PP,FF,fc,str2,str_a,str_b,ext_ima_read,nom_type_read]=name2display(XmlData.Heading.ImageName);
        end
        if isfield(XmlData,'Camera')
            if isfield(XmlData.Camera,'TimeUnit')
                TimeUnit=XmlData.Camera.TimeUnit;
            end
            if isfield(XmlData.Camera,'ImageSize')
               ImageSize=XmlData.Camera.ImageSize;
               if ~isempty(ImageSize)&& ~isempty(ImageSize)
                   xindex=findstr(ImageSize,'x');
                   if length(xindex)>=2
                        npx=str2num(ImageSize(1:xindex(1)-1));
                        npy=str2num(ImageSize(xindex(1)+1:xindex(2)-1));
                   end
               end
           end
        end
        pxcmx_search=1;
        pxcmy_search=1;
        if isfield(XmlData,'GeometryCalib')
            tsai=XmlData.GeometryCalib;
            if isfield(tsai,'f') & isfield(tsai,'Tz') & isfield(tsai,'dpx') & isfield(tsai,'dpy')& isfield(tsai,'R') 
                 rot2D=tsai.R([1:2],[1,2]);
                 pxcmx_search=tsai.f * sqrt(det(rot2D))/(tsai.Tz*tsai.dpx);
                 pxcmy_search=tsai.f * sqrt(det(rot2D))/(tsai.Tz*tsai.dpy);           
            end
            if isfield(tsai,'CoordUnit') 
                 CoordUnit=tsai.CoordUnit;
            end
        end               
        if isempty(ext_ima_read)
              ext_ima='.png';%default
        else
              ext_ima=ext_ima_read;
        end
        if isempty(nom_type_read)
                nom_type_ima='_i_j';
                warndlg_uvmat('no ImageName defined in ImaDoc/Heading, take _i_j indexing by default','WARNING')
        else
                nom_type_ima=nom_type_read;
        end
        
elseif isequal(ext,'.avi')|isequal(ext,'.AVI') 
        nom_type_ima='avi';
        ext_ima=ext;
        set(handles.mode,'String',{'series(Di)'})
        dt=0.04;%default
        if exist([filebase ext],'file')==2
            info=aviinfo([filebase ext]);%read infos on the avi movie
            dt=1/info.FramesPerSecond;%time interval between successive frames
            nbfield=info.NumFrames;%number of frames
        end
        time=(dt*[0:nbfield-1])';%list of image times   
        set(handles.dt,'String',num2str(dt*1000));%store the time interval between successive images
        
     % no image documentation file found: look for a series of existing images or .nc files 
elseif ~isequal(ext,'.nc') 
        subdir=get(handles.subdir_civ1,'String');
        incr_pair=[0 0];%default
        if isfield(browse,'incr_pair')
                incr_pair=browse.incr_pair;
        end
        nbdetect=0;%test of detected images
        field_i=field_count;
        idetect=1;
%         imagename='';%default
        while idetect==1 %look for the maximum file number in the series
                field_i=field_i+1;
%                 imagename_last=imagename;
                [imagename,idetect]=name_generator(filebase,field_i,1,ext_ima,nom_type_ima);
                if isequal(nom_type_ima,'none')
                   idetect=0; %stop if the same image is repeated (if nom_type='none')
                   nbdetect=1;
                end
                %SEE CASE OF NETCDF FILES
                nbdetect=nbdetect+idetect;
        end
%         nb_field=field_i-1;% last detected field number
        nb_field=field_i;% last detected field number
        field_i=field_count;%look for the minimum file number in the series
        idetect=1;
        while idetect==1 
                    field_i=field_i-1;
                    [imagename,idetect]=name_generator(filebase,field_i,1,ext_ima,nom_type_ima);
                    if isequal(nom_type_ima,'none')
                        idetect=0; %stop if the same image is repeted (if nom_type='none')
                        nbdetect=1;
                    end
                    nbdetect=nbdetect+idetect;
        end
        first_i=max(field_i+1,1);
            %determine the set of times and possible intervals for CIV_3D
        dt=(1/1000)*str2num(get(handles.dt,'String'));
        time=(dt*[0:nb_field-1])';
%             set(handles.incr_i,'UserData',dt);%store the time interval
%             between successive images
            %displ_num:list  of possible time intervals for civ_3D calculations
        set(handles.mode,'String',{'series(Di)'})
end
if isequal(nom_type_ima,'none')% no file numbering used
  first_i=1; 
  last_i=1;
   first_j=1;
  last_j=1;
end
if exist('time','var')
    siztime=size(time);
    nbfield=siztime(1);
    nbfield2=siztime(2);
    set(handles.displ_filebase,'UserData',time); %store the set of times
    set(handles.dt_unit,'String',['m' TimeUnit]);
    set(handles.TimeUnit,'String',TimeUnit);
    set(handles.nb_field,'String',num2str(nbfield));
    set(handles.nb_field2,'String',num2str(nbfield2));
end
set(handles.CoordUnit,'String',[CoordUnit '/'])
set(handles.pxcmx,'String',num2str(pxcmx));
set(handles.pxcmy,'String',num2str(pxcmy));
if isempty(pxcmx_search)
   set(handles.calcul_search,'UserData',[pxcmx pxcmy]);
else
   set(handles.calcul_search,'UserData',[pxcmx_search pxcmy_search]);
end
set(handles.pxcmx,'UserData',npx);
set(handles.pxcmy,'UserData',npy);
set(handles.first_i,'String',num2str(first_i));
set(handles.last_i,'String',num2str(last_i));%
set(handles.first_j,'String',num2str(first_j));
set(handles.last_j,'String',num2str(last_j));%
browse.ext_ima=ext_ima;
browse.nom_type_ima=nom_type_ima;
set(handles.browse_root,'UserData',browse)% store the nomenclature type

        %%%%%%%%%%%  set the menus of image pairs and default selection for civ_3D   %%%%%%%%%%%%%%%%%%%
if isequal(get(handles.compare,'Value'),1)
    if isequal(nom_type_ima,'_i')| isequal(nom_type_nc,'_i1-i2')|~exist('nbfield2','var')|(nbfield2==1)
        set(handles.mode,'String',{'st_series(Di)';'displacement'})
        set(handles.mode,'Value',1)
    elseif (nbfield==1)% simple series in j
        set(handles.mode,'String',{'st_series(Dj)';'displacement'})
        set(handles.mode,'Value',1)
    else
        set(handles.mode,'String',{'st_pair j1-j2';'st_series(Dj)';'st_series(Di)';'displacement'})%multiple choice
        if isequal(mode,'volume')
            set(handles.mode,'Value',3)
        elseif nbfield2 <= 5
            set(handles.mode,'Value',1)% advice 'pair j1-j2' for small bursts
        end
    end
else
    if isequal(nom_type_ima,'_i')| isequal(nom_type_nc,'_i1-i2')|~exist('nbfield2','var')|(nbfield2==1)
        set(handles.mode,'String',{'series(Di)'})
        set(handles.mode,'Value',1)
    elseif isequal(nom_type_ima,'png_old')|isequal(nom_type_nc,'netc_old')
        set(handles.mode,'String',{'pair j1-j2'})
        set(handles.mode,'Value',1)
    elseif (nbfield==1)% simple series in j
        set(handles.mode,'String',{'series(Dj)'})
        set(handles.mode,'Value',1)
    else
        set(handles.mode,'String',{'pair j1-j2';'series(Dj)';'series(Di)'})%multiple choice
        if isequal(mode,'volume')
            set(handles.mode,'Value',3)
        elseif nbfield2 <= 5
            set(handles.mode,'Value',1)% advice 'pair j1-j2' for small bursts
        else
            set(handles.mode,'Value',2)% advice series Dj for long bursts, not volume
        end
    end
end
mode_Callback(hObject, eventdata, handles)  

%%%%%% initialize waitbars and RUN button
set(handles.waitbar_1,'Position',[0.946 0.876 0.03 0.001])
set(handles.waitbar_patch1,'Position',[0.946 0.439 0.03 0.001])
set(handles.waitbar_civ2,'Position',[0.946 0.219 0.03 0.001])
set(handles.waitbar_patch2,'Position',[0.946 0.0 0.03 0.001])
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])
if isequal(test_batch,1)%if batch installation is available
    set(handles.BATCH, 'Enable','On')
    set(handles.BATCH,'BackgroundColor',[1 0 0])
end
    
%%%%% store the root input filename for future opening
dir_perso=prefdir;
profil_perso=fullfile(prefdir,'uvmat_perso.mat');
RootPath=fileparts(filebase);
if exist(profil_perso,'file')
    save (profil_perso,'RootPath','-append'); %store the root name for future opening of uvmat
else
    txt=ver;
    Release=txt(1).Release;
    relnumb=str2num(Release(3:4));
    if relnumb >= 14
        save (profil_perso,'RootPath','-V6'); %store the root name for future opening of uvmat 
    else
        save (profil_perso,'RootPath'); %store the root name for future opening of uvmat
    end
end
% save(profil_perso, 'filebase'); %store the root name for future opening of uvmat
set(gcf,'Pointer','arrow')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%????????????
% --- Executes on button press in mode.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mode_Callback(hObject, eventdata, handles)
browse=get(handles.browse_root,'UserData');
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
displ_num=[];%default
first_i=str2num(get(handles.first_i,'String'));
% last_i=str2num(get(handles.last_i,'String'));
time=get(handles.displ_filebase,'UserData'); %get the set of times
siztime=size(time);
nbfield=siztime(1);
nbfield2=siztime(2);
indchosen=1;  %%first pair selected by default
if isequal(mode,'pair j1-j2')| isequal(mode,'st_pair j1-j2')
    dt=1;
    displ='';
    index=0;
    %get all the time intervals in bursts
    displ_dt=1;%default
    nbfield2=min(nbfield2,10),%limitate the number of pairs to 10x10
%     if nbfield2<2
%         nbfield2=2,
%     end
    for numod_a=1:nbfield2-1 %nbfield2 always >=2 for 'pair j1-j2' mode
        for numod_b=(numod_a+1):nbfield2
             index=index+1;
             numlist_a(index)=numod_a;
             numlist_b(index)=numod_b;
             if ~isempty(time)
                dt(numod_a,numod_b)=time(first_i,numod_b)-time(first_i,numod_a);%first time interval dt
                displ_dt(index)=dt(numod_a,numod_b);
             else
                 displ_dt(index)=1
             end
         end
     end
     [dtsort,indsort]=sort(displ_dt);
     displ_num(1,:)=numlist_a(indsort);
     displ_num(2,:)=numlist_b(indsort);
     displ_num(3,:)=0;
     displ_num(4,:)=0;
     set(handles.jtext,'Visible','Off')
    set(handles.first_j,'Visible','Off')
    set(handles.last_j,'Visible','Off')
    set(handles.incr_j,'Visible','Off')
    set(handles.nb_field2,'Visible','Off')
    set(handles.ref_j,'Visible','Off')
elseif isequal(mode,'series(Dj)') | isequal(mode,'st_series(Dj)')
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
elseif isequal(mode,'series(Di)') | isequal(mode,'st_series(Di)') 
     for index=1:min(nbfield-1,200)
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

%--------------------------------------------------------------
% determine the menu for civ1 pairs depending on existing netcdf file at the middle of
% the field series set by first_i, incr, last_i
%----------------------------------------------------------------
function find_netcpair_civ1(hObject, eventdata, handles)
set(gcf,'Pointer','watch')
%nomenclature types
filebase=get(handles.displ_filebase,'String');
[filepath,Nme,ext_dir]=fileparts(filebase);
browse=get(handles.browse_root,'UserData');
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
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
if isequal(nom_type_ima,'png_old') | isequal(nom_type_nc,'netc_old')| isequal(nom_type_ima,'raw_SMD')
    nom_type_nc='netc_old';%nom_type for the netcdf files
elseif isequal(nom_type_ima,'none')|isequal(nom_type_nc,'none')
    nom_type_nc='none';
elseif isequal(nom_type_ima,'avi')|isequal(nom_type_ima,'_i')|isequal(nom_type_ima,'ima_num')|...
        isequal(nom_type_nc,'_i1-i2')
     nom_type_nc='_i1-i2';
elseif isequal(nom_type_ima,'_i_j1-j2')||isequal(nom_type_nc,'_i1-i2_j1-j2')
     nom_type_nc='_i1-i2_j1-j2';
else
    if  isequal(mode,'series(Di)')|isequal(mode,'st_series(Di)')
        nom_type_nc='_i1-i2_j'; % PIV in volume
    else
        nom_type_nc='_i_j1-j2';
    end    
end
browse.nom_type_nc=nom_type_nc;
set(handles.browse_root,'UserData',browse)

%reads .nc subdirectoy and image numbers from the interface
subdir_civ1=get(handles.subdir_civ1,'String');%subdirectory subdir_civ1 for the netcdf data
first_i=str2num(get(handles.first_i,'String'));
last_i=str2num(get(handles.last_i,'String'));
incr=str2num(get(handles.incr_i,'String'));
num1=first_i:incr:last_i;
if isempty(num1)
    set(handles.list_pair_civ1,'String',{''});
    return
end
ref_i=str2num(get(handles.ref_i,'String'));
if isequal(mode,'pair j1-j2')|isequal(mode,'st_pair j1-j2')
    ref_j=0;
else
    ref_j=str2num(get(handles.ref_j,'String'));
end
if isequal(get(handles.dt_text,'String'),'dt(ms)=')%simple series(Di) with equal interval
    ref_i=floor((first_i+last_i)/2);
    ref_j=1;
end
time=get(handles.displ_filebase,'UserData');%get the set of times
if isempty(time)
    time=[0 1];
end 
dt_unit=str2num(get(handles.dt,'String'));% used when there is no image documentation file
displ_num=get(handles.list_pair_civ1,'UserData');

%eliminate the first pairs inconsistent with the position 
if isempty(displ_num)
    nbpair=0;
else
    nbpair=length(displ_num(1,:));%nbre of displayed pairs
    if  isequal(mode,'series(Di)')  | isequal(mode,'st_series(Di)')
        nbpair=min(2*ref_i-1,nbpair);%limit the number of pairs with positive first index
    elseif  isequal(mode,'series(Dj)') | isequal(mode,'st_series(Dj)')
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
    dirname=fullfile(filepath,subdir_civ1,ext_dir);
    if ~exist(fullfile(filepath,subdir_civ1,ext_dir),'dir') 
         hwarn=warndlg_uvmat(['no civ1 file available: subdirectory ' subdir_civ1 ' does not exist'],'ERROR');
         set(handles.list_pair_civ1,'String',{});
         return
    end
    for ipair=1:nbpair   
        [filename,select(ipair)]=name_generator(filebase,ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair),'.nc',nom_type_nc,1,...
        ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair),subdir_civ1);
    end
    if ~exist('select','var') | isequal(select,zeros(size(1:nbpair)))
        if isfield(browse,'incr_pair') 
            num_i1=ref_i-floor(browse.incr_pair(1)/2);
            num_i2=ref_i+ceil(browse.incr_pair(1)/2);
            num_j1=ref_j-floor(browse.incr_pair(2)/2);
            num_j2=ref_j+ceil(browse.incr_pair(2)/2);
            [filename,select(1)]=name_generator(filebase,num_i1,num_j1,'.nc',nom_type_nc,1,num_i2,num_j2,subdir_civ1);
            testpair=1;
        else
            if  isequal(mode,'series(Dj)') | isequal(mode,'st_series(Dj)') 
                hwarn=warndlg_uvmat(['no civ1 file available for the selected reference index j=' num2str(ref_j) ' and subdirectory ' subdir_civ1],'ERROR');
                set(hwarn,'WindowStyle','modal');
            else
                hwarn=warndlg_uvmat(['no civ1 file available for the selected reference index i=' num2str(ref_i) ' and subdirectory ' subdir_civ1],'ERROR');
                set(hwarn,'WindowStyle','modal');
            end
             set(handles.list_pair_civ1,'String',{''});
             %COMPLETER CAS STEREO
            return
        end
    end
end
if isequal(mode,'series(Di)') | isequal(mode,'st_series(Di)')
    if testpair
              displ_pair{1}=['Di= ' num2str(-floor(browse.incr_pair(1)/2)) '|' num2str(ceil(browse.incr_pair(1)/2))];        
    elseif ~isequal(get(handles.dt_text,'String'),'dt(ms)=') 
       for ipair=1:nbpair
          if select(ipair)          
              dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
              displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt*1000)];
          else 
             displ_pair{ipair}='...'; %pair not displayed in the menu
          end
       end
    else
       for ipair=1:nbpair
         if select(ipair)
            displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt_unit*ipair)];
         else 
            displ_pair{ipair}='...'; %pair not displayed in the menu
         end
       end
    end
elseif isequal(mode,'series(Dj)')|isequal(mode,'st_series(Dj)')% series on the j index
    if testpair
         displ_pair{1}=['Dj= ' num2str(-floor(browse.incr_pair(1)/2)) '|' num2str(ceil(browse.incr_pair(1)/2))]; 
    else
       for ipair=1:nbpair
          if select(ipair)
              dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
              displ_pair{ipair}=['Dj= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt*1000)];
           elseif testpair
              displ_pair{1}=['Dj= ' num2str(-floor(browse.incr_pair(2)/2)) '|' num2str(ceil(browse.incr_pair(2)/2))];
          else 
             displ_pair{ipair}='...'; %pair not displayed in the menu
          end
       end
   end
elseif isequal(mode,'pair j1-j2')|isequal(mode,'st_pair j1-j2')%case of pairs
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
if (isempty(ichoice) | ichoice < 1); ichoice=1; end;
initial=get(handles.list_pair_civ1,'Value');
if initial>nbpair |~isequal(select(initial),1)
    set(handles.list_pair_civ1,'Value',ichoice);% first valid pair proposed by default in the menu
end
set(handles.list_pair_civ2,'String',displ_pair');
initial=get(handles.list_pair_civ2,'Value');
if initial>nbpair |~isequal(select(initial),1)
    set(handles.list_pair_civ2,'Value',ichoice);% same pair proposed by default for civ2
end
set(gcf,'Pointer','arrow')
%--------------------------------------------------------------
% determine the menu for civ2 pairs depending on the existing netcdf file at the 
%middle of the series set by first_i, incr, last_i 
%--------------------------------------------------------------
function find_netcpair_civ2(hObject, eventdata, handles)
set(gcf,'Pointer','watch')
%nomenclature types
filebase=get(handles.displ_filebase,'String');
[filepath,Nme,ext_dir]=fileparts(filebase);
browse=get(handles.browse_root,'UserData');
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};

% nomenclature type of the .nc files
nom_type_ima='ima_num';%default
if isfield(browse,'nom_type_ima')
    nom_type_ima=browse.nom_type_ima;
end
nom_type_nc='_i1-i2';%default
if isfield(browse,'nom_type_nc')
    nom_type_nc=browse.nom_type_nc;
end
if isequal(nom_type_ima,'png_old') | isequal(nom_type_ima,'netc_old')| isequal(nom_type_ima,'raw_SMD')| isequal(nom_type_nc,'netc_old')
    nom_type_nc='netc_old';%nom_type for the netcdf files
elseif isequal(nom_type_ima,'none')|isequal(nom_type_nc,'none')
    nom_type_nc='none';
elseif isequal(nom_type_ima,'avi')|isequal(nom_type_ima,'_i')|isequal(nom_type_ima,'ima_num')|isequal(nom_type_nc,'_i1-i2')
     nom_type_nc='_i1-i2';
else
    if  isequal(mode,'series(Di)')|isequal(mode,'st_series(Di)')
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
first_i=str2num(get(handles.first_i,'String'));
last_i=str2num(get(handles.last_i,'String'));
incr=str2num(get(handles.incr_i,'String'));
num1=first_i:incr:last_i;
if isempty(num1)
    set(handles.list_pair_civ2,'String',{});
    return
end
ref_i=str2num(get(handles.ref_i,'String'));
if isequal(mode,'pair j1-j2')|isequal(mode,'st_pair j1-j2')
    ref_j=0;
else
    ref_j=str2num(get(handles.ref_j,'String'));
end
if isequal(get(handles.dt_text,'String'),'dt(ms)=')%simple series(Di) with equal interval
    ref_i=ceil((first_i+last_i)/2);
    ref_j=1;
end
%     ref_i=browse.num_ref;%field number initially selected by the browser
time=get(handles.displ_filebase,'UserData'); %get the set of times
if isempty(time)
    time=[0 1];%default
end
dt_unit=str2num(get(handles.dt,'String'));% used when there is no image documentation file
displ_num=get(handles.list_pair_civ1,'UserData');


%eliminate the first pairs inconsistent with the position 
if isempty(displ_num)
    nbpair=0;
else
    nbpair=length(displ_num(1,:));%nbre of displayed pairs
    if  isequal(mode,'series(Di)') | isequal(mode,'st_series(Di)') 
        nbpair=min(2*ref_i-1,nbpair);%limit the number of pairs with positive first index
    elseif  isequal(mode,'series(Dj)') | isequal(mode,'st_series(Dj)') 
        nbpair=min(2*ref_j-1,nbpair);%limit the number of pairs with positive first index
    end
end
nbpair=min(200,nbpair);%limit the number of displayed pairs to 200

%look for existing processed pairs involving the field at the middle of the series if civ1 will not 
% be performed, while the result is needed for next steps.
displ_pair={''}; %default
select=ones(size(1:nbpair));%default =1 for nubers of displayed pairs
if get(handles.CIV2,'Value')==0 & get(handles.CIV1,'Value')==0 & get(handles.FIX1,'Value')==0 & get(handles.PATCH1,'Value')==0%&...
    if ~exist(fullfile(filepath,subdir_civ2,ext_dir),'dir') 
         errordlg(['no civ2 file available: subdirectory ' subdir_civ2 ' does not exist'])
         set(handles.list_pair_civ2,'String',{});
         return
    end
    for ipair=1:nbpair       
        [filename,select(ipair)]=name_generator(filebase,ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair),'.nc',nom_type_nc,1,...
        ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair),subdir_civ1);
    end
    if  isequal(select,zeros(size(1:nbpair)))
        if isfield(browse,'incr_pair') 
            num_i1=ref_i-floor(browse.incr_pair(1)/2);
            num_i2=ref_i+floor((browse.incr_pair(1)+1)/2);
            num_j1=ref_j-floor(browse.incr_pair(2)/2);
            num_j2=ref_j+floor((browse.incr_pair(2)+1)/2);
            [filename,select(1)]=name_generator(filebase,num_i1,num_j1,'.nc',nom_type_nc,1,num_i2,num_j2,subdir_civ2);
        else
            if  isequal(mode,'series(Dj)') | isequal(mode,'st_series(Dj)') 
                errordlg(['no civ2 file available for the selected reference index j=' num2str(ref_j) ' and subdirectory ' subdir_civ2])
            else
                errordlg(['no civ2 file available for the selected reference index i=' num2str(ref_i) ' and subdirectory ' subdir_civ2])
            end
             set(handles.list_pair_civ2,'String',{});
            return
        end
    end
end
if isequal(mode,'series(Di)')  | isequal(mode,'st_series(Di)') 
    if  ~isequal(get(handles.dt_text,'String'),'dt(ms)=')
       for ipair=1:nbpair
          if select(ipair)
              dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
              displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt*1000)];
          else 
             displ_pair{ipair}='...'; %pair not displayed in the menu
          end
       end
   else
       for ipair=1:nbpair
         if select(ipair)
            displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt_unit*ipair)];
         else 
            displ_pair{ipair}='...'; %pair not displayed in the menu
         end
       end
    end
elseif isequal(mode,'series(Dj)') | isequal(mode,'st_series(Dj)') % series on the j index
       for ipair=1:nbpair
          if select(ipair)
              dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
              displ_pair{ipair}=['Dj= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ' :dt= ' num2str(dt*1000)];
          else 
             displ_pair{ipair}='...'; %pair not displayed in the menu
          end
       end
elseif isequal(mode,'pair j1-j2') | isequal(mode,'st_pair j1-j2') %case of pairs
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
set(handles.list_pair_civ2,'String',displ_pair');
ichoice=min(find(select));
if (isempty(ichoice) | ichoice < 1); ichoice=1; end;
if get(handles.CIV2,'Value')==0 & get(handles.CIV1,'Value')==0 & get(handles.FIX1,'Value')==0 & get(handles.PATCH1,'Value')==0
    set(handles.list_pair_civ2,'Value',ichoice);% first valid pair proposed by default in the menu
end
set(gcf,'Pointer','arrow')
%----------------------------------------------------
%  determine the list of index pairs of processing file 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2]=...
    find_pair_indices(handles,mode)
first_i=str2num(get(handles.first_i,'String'));
last_i=str2num(get(handles.last_i,'String'));
incr=str2num(get(handles.incr_i,'String'));
first_j=str2num(get(handles.first_j,'String'));
last_j=str2num(get(handles.last_j,'String'));
incr_j=str2num(get(handles.incr_j,'String'));
list_civ1=get(handles.list_pair_civ1,'String');
index_civ1=get(handles.list_pair_civ1,'Value');
str_civ1=list_civ1{index_civ1};
list_civ2=get(handles.list_pair_civ2,'String');
index_civ2=get(handles.list_pair_civ2,'Value');
str_civ2=list_civ2{index_civ2};
if isequal(first_i,[])|isequal(first_j,[]), errordlg('first field number not defined'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
if isequal(last_i,[])| isequal(last_j,[]),errordlg('last field number not defined'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
if isequal(incr,[])| isequal(incr_j,[]),errordlg('increment in field number not defined'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
if last_i < first_i | last_j < first_j , errordlg('last field number must be larger than the first one'),...
    set(handles.RUN, 'Enable','On'), set(handles.RUN,'BackgroundColor',[1 0 0]),return,end;
num1=[first_i:incr:last_i];
num_j=[first_j:incr_j:last_j];
if isequal (mode,'series(Di)') |isequal(mode,'st_series(Di)')
     %recognize the pair civ1 from the display
	indsel=find((double(str_civ1)<48)|(double(str_civ1)>57));% character indices of non numerical characters
    str_raw=str_civ1(indsel);
    indsepar=find(str_raw=='|'); %character index of the separator
    d1=str2num(str_civ1([indsel(indsepar-1)+1:indsel(indsepar)-1]));
    if indsepar==length(str_raw)
        d2=str2num(str_civ1([indsel(indsepar)+1:end]));
    else
        d2=str2num(str_civ1([indsel(indsepar)+1:indsel(indsepar+1)-1]));
    end   
    %recognize the pair civ2 from the display
    num1_civ1=num1-d1;% set of first image numbers
    num2_civ1=num1+d2;
    num_a_civ1=num_j;
    num_b_civ1=num_j;
    num1_civ2=num1-floor(index_civ2/2)*ones(size(num1));% set of first image numbers
    num2_civ2=num1+ceil(index_civ2/2)*ones(size(num1));
    num1_civ2=num1-d1;% set of first image numbers
    num2_civ2=num1+d2;
    num_a_civ2=num_j;
    num_b_civ2=num_j;
    % adjust the first and last field number
    lastfield=str2num(get(handles.nb_field,'String'));
    if isequal(lastfield,[])
        indsel=find((num1_civ1 >= 1)&(num1_civ2 >= 1));
    else
        indsel=find((num2_civ1 <= lastfield)&(num2_civ2 <= lastfield)&(num1_civ1 >= 1)&(num1_civ2 >= 1));
    end
    if length(indsel)>=1
        firstind=indsel(1);
        lastind=indsel(end);
        set(handles.first_i,'String',num2str(num1(firstind)))%update the display of first and last fields
        set(handles.last_i,'String',num2str(num1(lastind)))
        num1=num1(indsel);
        num1_civ1=num1_civ1(indsel);
        num1_civ2=num1_civ2(indsel);
        num2_civ1=num2_civ1(indsel);
        num2_civ2=num2_civ2(indsel);
    end
elseif isequal (mode,'series(Dj)')|isequal (mode,'st_series(Dj)')
    lastfield_j=str2num(get(handles.nb_field2,'String'));
    num1_civ1=num1;% set of first image numbers
    num2_civ1=num1;
    num_a_civ1=num_j-floor(index_civ1/2)*ones(size(num_j));
    num_b_civ1=num_j+ceil(index_civ1/2)*ones(size(num_j));
    num1_civ2=num1;
    num2_civ2=num1;
    num_a_civ2=num_j-floor(index_civ2/2)*ones(size(num_j));
    num_b_civ2=num_j+ceil(index_civ2/2)*ones(size(num_j));
    % adjust the first and last field number
    if isequal(lastfield_j,[])
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
elseif isequal(mode,'pair j1-j2') | isequal(mode,'st_pair j1-j2') %case of bursts (png_old or png_2D)
    num1_civ1=num1;
    num1_civ2=num1;
    displ_num=get(handles.list_pair_civ1,'UserData');
    num2_civ1=num1;
    num_a_civ1=displ_num(1,index_civ1);
    num_b_civ1=displ_num(2,index_civ1);
    num2_civ2=num1;
    num_a_civ2=displ_num(1,index_civ2);
    num_b_civ2=displ_num(2,index_civ2);
elseif isequal(mode,'displacement')
    num1_civ1=num1;
    num2_civ1=num1;
    num_a_civ1=num_j;
    num_b_civ1=num_j;
    num1_civ2=num1;
    num2_civ2=num1;
    num_a_civ2=num_j;
    num_b_civ2=num_j;
end


%-------------------------------------------------------------
% --- Executes on selection change in list_pair_civ1.
function list_pair_civ1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------
%reproduce by default the chosen pair in the civ2 menu
list_pair=get(handles.list_pair_civ1,'String');%get the menu of image pairs
index_pair=get(handles.list_pair_civ1,'Value');
displ_num=get(handles.list_pair_civ1,'UserData');
num_a=displ_num(1,index_pair);
num_b=displ_num(2,index_pair);
set(handles.list_pair_civ2,'Value',index_pair);

%update first_i and last_i according to the chosen image pairs 
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if isequal(mode,'series(Di)')
    first_i=str2num(get(handles.first_i,'String'));
    last_i=str2num(get(handles.last_i,'String'));
    incr_i=str2num(get(handles.incr_i,'String'));
    num1=first_i:incr_i:last_i;
    lastfield=str2num(get(handles.nb_field,'String'));
    if ~isequal(lastfield,[])
        ind=find((num1-floor(index_pair/2)*ones(size(num1))>0)& ...
             (num1+ceil(index_pair/2)*ones(size(num1))<=lastfield));
        num1=num1(ind);
    end
    set(handles.first_i,'String',num2str(num1(1)));
    set(handles.last_i,'String',num2str(num1(end)));
elseif isequal(mode,'series(Dj)')
    first_j=str2num(get(handles.first_j,'String'));
    last_j=str2num(get(handles.last_j,'String'));
    incr_j=str2num(get(handles.incr_j,'String'));
    num_j=first_j:incr_j:last_j;
    lastfield2=str2num(get(handles.nb_field2,'String'));
    if ~isequal(lastfield2,[])
        ind=find((num_j-floor(index_pair/2)*ones(size(num_j))>0)& ...
             (num_j+ceil(index_pair/2)*ones(size(num_j))<=lastfield2));
        num1=num_j(ind);
    end
    set(handles.first_j,'String',num2str(num1(1)));
    set(handles.last_j,'String',num2str(num1(end)));
end 

%------------------------------------------------------------------
% --- Executes on selection change in list_pair_civ2.
function list_pair_civ2_Callback(hObject, eventdata, handles)

index_pair=get(handles.list_pair_civ2,'Value');%get the selected position index in the menu 

%update first_i and last_i according to the chosen image pairs 
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if isequal(mode,'series(Di)')
    first_i=str2num(get(handles.first_i,'String'));
    last_i=str2num(get(handles.last_i,'String'));
    incr_i=str2num(get(handles.incr_i,'String'));
    num1=first_i:incr_i:last_i;
    lastfield=str2num(get(handles.nb_field,'String'));
    if ~isequal(lastfield,[])
        ind=find((num1-floor(index_pair/2)*ones(size(num1))>0)& ...
             (num1+ceil(index_pair/2)*ones(size(num1))<=lastfield));
        num1=num1(ind);
    end
    set(handles.first_i,'String',num2str(num1(1)));
    set(handles.last_i,'String',num2str(num1(end)));
elseif isequal(mode,'series(Dj)')
    first_j=str2num(get(handles.first_j,'String'));
    last_j=str2num(get(handles.last_j,'String'));
    incr_j=str2num(get(handles.incr_j,'String'));
    num_j=first_j:incr_j:last_j;
    lastfield2=str2num(get(handles.nb_field2,'String'));
    if ~isequal(lastfield2,[])
        ind=find((num_j-floor(index_pair/2)*ones(size(num_j))>0)& ...
             (num_j+ceil(index_pair/2)*ones(size(num_j))<=lastfield));
        num1=num_j(ind);
    end
    set(handles.first_j,'String',num2str(num1(1)));
    set(handles.last_j,'String',num2str(num1(end)));
end 




%-----------------------------------------------------------
% --- Executes on button press in BATCH: remote processing
%-----------------------------------------------------------
function BATCH_Callback(hObject, eventdata, handles)
global civ1_exe civ2_exe patch_exe patch_new_exe fix_exe todo_path sge Civ_exe

pxcmx=get(handles.pxcmx,'String');
pxcmy=get(handles.pxcmy,'String');
npx=get(handles.pxcmx,'UserData');
npy=get(handles.pxcmy,'UserData');

%check the list of operations:
operations={'CIV1','FIX1','PATCH1','CIV2','FIX2','PATCH2'};
run_flag=1;
box_test(1)=get(handles.CIV1,'Value');
box_test(2)=get(handles.FIX1,'Value');
box_test(3)=get(handles.PATCH1,'Value');
box_test(4)=get(handles.CIV2,'Value');
box_test(5)=get(handles.FIX2,'Value');
box_test(6)=get(handles.PATCH2,'Value');
index=find(box_test==1);
if isempty(index)
    errordlg('no selected operation')
    set(handles.BATCH, 'Enable','On')
    set(handles.BATCH,'BackgroundColor',[1 0 0])
    return
end
index_first=min(index);
index_last=max(index);
box_used=box_test([index_first : index_last]);
[box_missing,ind_missing]=min(box_used);
if isequal(box_missing,0)
    errordlg(['missing' cell2mat(operations(ind_missing))]);
    set(handles.BATCH, 'Enable','On')
    set(handles.BATCH,'BackgroundColor',[1 0 0])
    return
end

%check mask if selecetd
if isequal(get(handles.get_mask_civ1,'Value'),1)
     get_mask_civ1_Callback(hObject, eventdata, handles);
end
if isequal(get(handles.get_mask_fix1,'Value'),1)
     get_mask_fix1_Callback(hObject, eventdata, handles);
end
if isequal(get(handles.get_mask_civ2,'Value'),1)
     get_mask_civ2_Callback(hObject, eventdata, handles);
end
if isequal(get(handles.get_mask_fix2,'Value'),1)
     get_mask_fix2_Callback(hObject, eventdata, handles);
end


%read names of the .exe file
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
if isunix
    %fid = fopen(fullfile(path_UVMAT,'PARAM_LINUX.txt'),'r');%open the file with civ_3D binary names
    xmlfile=fullfile(path_UVMAT,'PARAM_LINUX.xml');
    if exist(xmlfile,'file')
        t=xmltree(xmlfile);
        sparam=convert(t);
    end
else
    %fid = fopen(fullfile(path_UVMAT,'PARAM_WIN.txt'),'r');%open the file with civ_3D binary names
    xmlfile=fullfile(path_UVMAT,'PARAM_WIN.xml');
    if exist(xmlfile,'file')
        t=xmltree(xmlfile);
        sparam=convert(t);
    end
end
 sge=0;
if isfield(sparam,'Civ_exe')
    Civ_exe=sparam.Civ_exe
end
if isfield(sparam,'Civ1_exe')
    civ1_exe=sparam.Civ1_exe
end
if isfield(sparam,'Civ2_exe')
    civ2_exe=sparam.Civ2_exe
end
if isfield(sparam,'Patch_exe')
    patch_exe=sparam.Patch_exe
end
if isfield(sparam,'PatchNew_exe')
    patch_new_exe=sparam.PatchNew_exe
end
if isfield(sparam,'Fix_exe')
    fix_exe=sparam.Fix_exe
end
if isfield(sparam,'Todo_path')
    todo_path=sparam.Todo_path
end
if isfield(sparam,'SGE')
    sge=str2num(sparam.SGE)
end 
%choice of batch priority
ind_answer=2;
if sge
    [s,w]=unix('qstat -q civ_3D.q|grep job_| wc -l'); %check the waiting list (command unix)
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
        warndlg_uvmat('batch system not available','ERROR')
        return
    end
end
%initialize the waitbars
set(handles.waitbar_1,'Position',[0.946 0.876 0.03 0.001])
set(handles.waitbar_patch1,'Position',[0.946 0.439 0.03 0.001])
set(handles.waitbar_civ2,'Position',[0.946 0.219 0.03 0.001])
set(handles.waitbar_patch2,'Position',[0.946 0.0 0.03 0.001])
set(handles.BATCH, 'Enable','Off')
set(handles.BATCH,'BackgroundColor',[0.831 0.816 0.784])

%get the filename root, nomenclature and numbers
filebase=get(handles.displ_filebase,'String');
% for Windows system find the UBC path name if needed
if ~isunix & isequal(todo_path(1:2),'\\') & isequal(filebase(2:3),':\')
    cur_dir=pwd;
    if ~isequal(cur_dir(2:3),':\')
        cd(matlabroot); %move to the Matlab root directory if the current Matlab dir does not allow the dos command or is M: 
    end
    [ss,ww]=dos(['net use ' filebase(1:2)]);
    if isequal(ss,0)
        rankpath=findstr(ww,'\\');
        if ~isempty(rankpath)
            wwrest=ww(rankpath:end);
            rankend=min(find(double(wwrest)==10))-1;
            filebase=[wwrest(1:rankend) filebase(3:end)];
            set(handles.displ_filebase,'String',filebase);
        end
    else
         warndlg_uvmat('for BATCH option, UBC file names, beginning by \\, are needed','ERROR');
         set(handles.BATCH, 'Enable','On')
         set(handles.BATCH,'BackgroundColor',[1 0 0])
         return
    end
end
browse=get(handles.browse_root,'UserData')
ext_ima=browse.ext_ima;
nom_type_nc='_i1-i2';
nom_type_ima=browse.nom_type_ima;
% nom_type_nc=browse.nom_type_nc;
% if isequal(nom_type_ima2,[]),nom_type_ima2='ima_num';end; %default
% if isequal(nom_type_nc,[]),nom_type_nc='_i1-i2';end; %default
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
time=get(handles.displ_filebase,'UserData'); %get the set of times

[num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2]=...
find_pair_indices(handles,mode); %determine the pairs of processing file 

%check dir
subdir_civ1=get(handles.subdir_civ1,'String');%subdirectory subdir_civ1 for the netcdf output data
subdir_civ2=get(handles.subdir_civ2,'String');
if isequal(subdir_civ1,''),subdir_civ1='A'; end% put default subdir
if isequal(subdir_civ2,''),subdir_civ2=subdir_civ1; end% put default subdir
currentdir=pwd;%store the current working directory
[Path_ima,Name]=fileparts(filebase);%Path of the image files (.civ_3D)
if ~exist(Path_ima,'dir')
    warndlg_uvmat(['path to images ' Path_ima ' not found'],'ERROR')
    return
end
cd(Path_ima);%move to the directory of the images
dircur=pwd; %current working directory
m2='';
[erread,message]=fileattrib(Path_ima);
if ~isempty(message) & ~isequal(message.UserWrite,1)
      errordlg(['No writting access to ' Path_ima])
      cd(currentdir)
      return
end

%test for reference file in fix
ref_fix1=get(handles.ref_fix1,'UserData');
ref_fix2=get(handles.ref_fix2,'UserData');
if (~isempty(ref_fix1) & box_test(2)==1)|(~isempty(ref_fix2) & box_test(5)==1)
    errordlg('reference file not implemented in BATCH mode, use RUN')
    set(handles.BATCH, 'Enable','On')
    set(handles.BATCH,'BackgroundColor',[1 0 0])
    return
end
nbfield=length(num1_civ1);
nbslice=length(num_a_civ1);
   
%check the existence of the netcdf and image files involved
% if box_test(1)==1;%CIV1 activated
detect=1; 
while detect==1 %name a new subdir if one of the netcdf files already exists
      for ifile=1:nbfield
%           for j=1:nbslice
              [filename,detect]=name_generator(filebase,num1_civ1(ifile),[],'.nc',...
                nom_type_nc,1,num2_civ1(ifile),[],subdir_civ1);%
              if detect==1% if a netcdf file already exists
                 subdir_civ1=[subdir_civ1 '.0'];
                 subdir_civ2=subdir_civ1;
                 break
              end
              filecell_nc1(ifile)={filename};
          if detect==1% if a netcdf file already exists
              break
          end
      end
       %create the new subdir_civ1 if it does not exist
      if ~exist(fullfile(Path_ima,subdir_civ1),'dir')
          [m1,m2,m3]=mkdir(subdir_civ1)
           if ~isequal(m2,'')
               msgbox(m2);%error message for directory creation
          end
     end
end
%get image names
for ifile=1:nbfield
    [filecell_ima1_civ1{ifile},idetect]=name_generator(filebase, num1_civ1(ifile),[],ext_ima,nom_type_ima);%first image
    [filecell_ima2_civ1{ifile},idetect_1]=name_generator(filebase, num2_civ1(ifile),[],ext_ima,nom_type_ima); %second image
     if idetect==0
            warndlg_uvmat([filecell_ima1_civ1{ifile} ' not found'],'ERROR')
            set(handles.BATCH, 'Enable','On')
            set(handles.BATCH,'BackgroundColor',[1 0 0])
            cd(currentdir)
            return
     end
     if idetect_1==0,
            errordlg([filecell_ima2_civ1{ifile} ' not found'])
            set(handles.BATCH, 'Enable','On')
            set(handles.BATCH,'BackgroundColor',[1 0 0])
            cd(currentdir)
            return
     end
end

cd(currentdir);%come back to the initial working directory 
% if ~isequal(m2,'')
%      msgbox(m2);%error message for directory creation
% end
set(handles.subdir_civ1,'String',subdir_civ1);%update the edit box
set(handles.subdir_civ2,'String',subdir_civ2);%update the edit box
browse.nom_type_nc=nom_type_nc;
set(handles.browse_root,'UserData',browse);%update the nomenclature type for uvmat

%COPY IMAGES TO THE FORMAT .vol IF NEEDED
if isequal(nom_type_ima,'avi')
    nom_type_imanew='_i';
else
    nom_type_imanew=nom_type_ima;
end

if ~isequal(ext_ima,'.vol')
    if box_test(1)==1 %if civ1 is performed
       h = waitbar(0,['copy images to the .png format for civ1']);% display a wait bar 
       for ifile=1:nbfield
            waitbar(ifile/nbfield);
            Atot=[];
            [filename_A,idetect_cur]=name_generator(filebase,num1_civ1(ifile),1,'.png','_i');%A VOIR
            for j=1:nbslice
                    if idetect_cur==0
                        A=read_image(cell2mat(filecell_ima1_civ1(ifile,j)),nom_type_ima2,npx,npy,num1_civ1(ifile));
                        Atot=[Atot;A];
                        %imwrite(A,filename,'BitDepth',16); 
                    end
            end
            imwrite(Atot,filename_A,'BitDepth',16);
                    %filecell_ima1_civ1(ifile,j)={filename};
            Atot=[];
            [filename_B,idetect_cur]=name_generator(filebase, num2_civ1(ifile),1,'.png','_i');
            for j=1:nbslice
                    if idetect_cur==0
                        A=read_image(cell2mat(filecell_ima2_civ1(ifile,j)),nom_type_ima2,npx,npy,num2_civ1(ifile));
                        Atot=[Atot;A];
%                         imwrite(A,filename,'BitDepth',16);
                    end
                    %filecell_ima2_civ1(ifile,j)={filename};
            end
            imwrite(Atot,filename_B,'BitDepth',16);
        end
        close(h)
    end    
end

if ~sge      
    %OPEN THE WAIT LIST FOR BATCH PROCESSES
    name_lock=fullfile(todo_path,'lock'); %lock file 
    iwait=0;
    while(exist(name_lock) & iwait<15)
        pause(1); %wait 1 second
        iwait=iwait+1;
    end
    if iwait==15
        errordlg(['I''m tired to wait for the lock file, please delete it then click again on BATCH' name_lock ])
        set(handles.BATCH, 'Enable','On')
        set(handles.BATCH,'BackgroundColor',[1 0 0])
        return
    end
    p0=fopen(name_lock,'w'); %create the file name_lock: prevents other users to interfere
    name_todo=fullfile(todo_path,'TODO.txt');
    p1=fopen(name_todo,'a');
    if (p1<0)
        errordlg(['error in opening ' name_todo])
        set(handles.BATCH, 'Enable','On')
        set(handles.BATCH,'BackgroundColor',[1 0 0])
        return;
    end
end

for ifile=1:nbfield
    i_cmd=0; 
    cmd='';
    if sge
       cmd='#!/bin/bash';
       cmd=char({cmd;'#$ -cwd'});
       cmd=char({cmd;'hostname && date'});
    end
    filename_cmx=cell2mat(filecell_nc1(ifile));%output netcdf file
    filename_cmx([end-1:end])='cm';%name of cmx file
    filename_cmx=[filename_cmx 'x'];
    
%CIV1
    if box_test(1)==1
        %GET civ_3D PARAMETERS:
        par_civ1=read_param_civ1(handles,cell2mat(filecell_ima1_civ1(1,1)));
        p1text=[];
        [par_civ1.path,resu_file,resu_ext]=fileparts(filecell_nc1{ifile});
        par_civ1.volume1=filecell_ima1_civ1{ifile};
        par_civ1.volume2=filecell_ima2_civ1{ifile}
        par_civ1.nx=1024;
        par_civ1.ny=1024;
        par_civ1.nz=par_civ1.gridLimits_Zmax - par_civ1.gridLimits_Zmin;
        'TEST'
        par_civ1
        % civAll=get(handles.Experimental,'Value'); % Boolean for new civ excution method
        % if isequal(civAll,1)
        civAllxml=struct2xml(par_civ1);% xml contents,  all parameters
        civAllxml=set(civAllxml,1,'name','civ3d3c');
    %    save(civAllxml)
    	par_civ1_3d_xml=fullfile(par_civ1.path,[resu_file '.xml']);%[par_civ1.path '/test_to_change.xml'];
	 pvalue=num2str((1-ind_answer)*500);
    	save(civAllxml,par_civ1_3d_xml);
      if(isunix && sge)
	 ['echo /CIVX/bin/MPI/lam-7.1.3_g95/bin/mpirun C  /CIVX/bin/civ3d3c -p ' par_civ1_3d_xml '|qsub -p ' pvalue ' -q lam.q -pe lam_loose 16 -e ' par_civ1_3d_xml '.errors -o ' par_civ1_3d_xml '.log' ]
	 eval ( ['!echo /CIVX/bin/MPI/lam-7.1.3_g95/bin/mpirun C  /CIVX/bin/civ3d3c -p ' par_civ1_3d_xml '|qsub -p ' pvalue ' -q lam.q -pe lam_loose 16 -e ' par_civ1_3d_xml '.errors -o ' par_civ1_3d_xml '.log' ])
      else
 	    '3D mode is NOT supported without sge'
      end
	 return
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  fichier xml produit
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % A CONTINUER
        %civAllxml
        civAllCmd=[];
        civAllxml=set(civAllxml,1,'name','civ3d3c');
        namelog=[filename_cmx([1:end-3]) 'log'];
        %par_civ1.Dt=num2str(time(num2_civ1(ifile),num_b_civ1(j))-time(num1_civ1(ifile),num_a_civ1(1)));
        %par_civ1.T0=num2str((time(num2_civ1(ifile),num_b_civ1(j))+time(num1_civ1(ifile),num_a_civ1(1)))/2); 
       % test_mask=get(handles.get_mask_civ1,'Value');
        i_cmd=i_cmd+1;
%         if isequal(civAll,0)
%             cmd=char({cmd;BATCH_CIV1(filename_cmx([1:end-4]),namelog,par_civ1,handles)});
%         else
             civAllCmd=[civAllCmd ' civ1 '];
             str=BATCH_CIV1_Unified(filename_cmx([1:end-4]),namelog,par_civ1,handles);
            fieldnames=fields(str);
            [civAllxml,uid_civ1]=add(civAllxml,1,'element','civ1');
            for ilist=1:length(fieldnames)
              val=eval(['str.' fieldnames{ilist}]);
              if ischar(val)
                [civAllxml,uid_t]=add(civAllxml,uid_civ1,'element',fieldnames{ilist});
                [civAllxml,uid_t2]=add(civAllxml,uid_t,'chardata',val);
               end
            end   
%         end
    end         
    if(isunix)
	    cmd=char({cmd ; ['cp -f ' filename_cmx '2 ' filename_cmx]; cmd_CIV2});
    else
        cmd=char({cmd ; ['copy /Y ' filename_cmx '2 ' filename_cmx]; cmd_CIV2});
    end
end
     
%  if isequal(civAll,1)
    save(civAllxml,[filename_cmx([1:end-4]) '.xml']);
    cmd=char({cmd;[Civ_exe ' -f ' [filename_cmx([1:end-4]) '.xml'] ' ' civAllCmd]});

     %save(civAllxml,'/tmp/test.xml');
%  end


% create the .bat file:
if sge
        [Rootbat,Filebat,extbat]=fileparts(filename_cmx);
        filename_bat=fullfile(Rootbat,['job_' Filebat extbat]);
else
    filename_bat=filename_cmx;
end
filename_bat(end-2:end)='bat';

%     pbat=fopen(filename_bat,'w'); %create the file filename_bat
dlmwrite(filename_bat,cmd,'');%write commands in filename_bat
if sge
    pvalue=num2str((1-ind_answer)*500);
    namelog=[filename_bat '.patch.log'];
    ['!qsub -p ' pvalue ' -q civ_3D.q -e ' filename_cmx(1:end-4) '.errors -o ' filename_cmx(1:end-4) '.log' ' ' filename_bat];
    eval(  ['!qsub -p ' pvalue ' -q civ_3D.q -e ' filename_cmx(1:end-4) '.errors -o ' filename_cmx(1:end-4) '.log' ' ' filename_bat]);
else
    if(isunix)
      cmdtodo=['. ' filename_bat ];%removed for Mathieu tests %' && rm -f ' filename_bat] ;
    else
%      cmdtodo=[filename_bat ' && del /F /Q ' filename_bat];
       cmdtodo=[filename_bat];%removed for Mathieu tests %' && del /F /Q ' filename_bat' ;
    end
    count= fprintf(p1,'%s\n', cmdtodo);
end
if ~sge
    fclose(p1);
    fclose(p0);
    delete(name_lock);
end 
set(handles.BATCH, 'Enable','On')
set(handles.BATCH,'BackgroundColor',[1 0 0])
%save interface state
[Path,Name]=fileparts(filebase);
namefig=fullfile(Path,subdir_civ2,Name);
detect=1; 
while detect==1
    namefigfull=[namefig '.fig'];
    hh=dir(namefigfull);
    if ~isempty(hh)
        detect=1;
        namefig=[namefig '.0'];
    else
        detect=0;
    end
end
saveas(gcbf,namefigfull);%save the interface with name namefigfull


%----------------------------------------
%PATCH
%---------------------------------------
function cmd_PATCH=RUN_PATCH(filename_nc,nx_patch,ny_patch,rho_patch,subdomain_patch,thresh_value,test_interp)
global patch_exe patch_new_exe
        namelog=[filename_nc([1:end-3]) '_patch.log'];
        if test_interp==0
            cmd_PATCH=[patch_exe ' -f ' filename_nc ' -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ' -nopt ' subdomain_patch ...
            '  > ' namelog ' 2>&1'] % redirect standard output to the log file
         else %nouveau programme patch
             cmd_PATCH=[patch_new_exe ' -f ' filename_nc ' -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ...
                ' -max ' thresh_value ' -nopt ' subdomain_patch  '  > ' namelog ' 2>&1']; % redirect standard output to the log file
        end

  
%----------------------------------------------------
function first_j_Callback(hObject, eventdata, handles)
last_j_Callback(hObject, eventdata, handles)

%---------------------------------------------------------
% --- Executes on button press in CIV1.
function CIV1_Callback(hObject, eventdata, handles)
enable_civ1(handles,get(handles.CIV1,'Value'))
find_netcpair_civ1(hObject, eventdata, handles);

%------------------------------------------------------
% --- Executes on button press in FIX1.
function FIX1_Callback(hObject, eventdata, handles)

if get(handles.FIX1,'Value')==1
enable_fix1(handles)
else
desable_fix1(handles)
end

%----------------------------------------------------------------
% --- Executes on button press in PATCH1.
function PATCH1_Callback(hObject, eventdata, handles)

if get(handles.PATCH1,'Value')==1
enable_patch1(handles)
else
desable_patch1(handles)
end

%----------------------------------------------------------
% --- Executes on button press in CIV2.
function CIV2_Callback(hObject, eventdata, handles)
state=get(handles.CIV2,'Value');
enable_civ2(handles,state)
if state
    find_netcpair_civ2(hObject, eventdata, handles)
end

%---------------------------------------------------
% --- Executes on button press in FIX2.
function FIX2_Callback(hObject, eventdata, handles)
if get(handles.FIX2,'Value')==1
    enable_fix2(handles)
    if get(handles.CIV2,'Value')==0
        find_netcpair_civ2(hObject, eventdata, handles) % select the available netcdf files
    end
else
    desable_fix2(handles)
end


%-------------------------------------------------------
% --- Executes on button press in PATCH2.
function PATCH2_Callback(hObject, eventdata, handles)
%--------------------------------------------------------
if get(handles.PATCH2,'Value')==1
    enable_patch2(handles)
    if get(handles.CIV2,'Value')==0
        find_netcpair_civ2(hObject, eventdata, handles) % select the available netcdf files
    end
else
    desable_patch2(handles)
end



%-----------------------------------------------------------
function first_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------
last_i_Callback(hObject, eventdata, handles)

%-----------------------------------------------------------
% --- Executes on button press in calcul_search: determine the search range isx,isy
%--------------------------------------------------------
function calcul_search_Callback(hObject, eventdata, handles)

%determine pair numbers
list_pair=get(handles.list_pair_civ1,'String');%get the menu of image pairs
index=get(handles.list_pair_civ1,'Value');
displ_num=get(handles.list_pair_civ1,'UserData');
time=get(handles.displ_filebase,'UserData'); %get the set of times
pxcm_xy=get(handles.calcul_search,'UserData')
pxcmx=pxcm_xy(1);
pxcmy=pxcm_xy(2);
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if isequal (mode, 'series(Di)' )
    ref_i=str2num(get(handles.ref_i,'String'));
    num1=ref_i-floor(index/2);%  first image numbers
    num2=ref_i+ceil(index/2);
    num_a=1;
    num_b=1;
elseif isequal (mode, 'series(Dj)') 
    num1=1;
    num2=1;
    ref_j=str2num(get(handles.ref_j,'String'));
    num_a=ref_j-floor(index/2);%  first image numbers
    num_b=ref_j+ceil(index/2);
elseif isequal(mode,'pair j1-j2') %case of bursts (png_old or png_2D)
    ref_i=str2num(get(handles.ref_i,'String'));
    num1=ref_i;
    num2=ref_i;
    num_a=displ_num(1,index);
    num_b=displ_num(2,index);
end
dt=time(num2,num_b)-time(num1,num_a);
ibx=str2num(get(handles.ibx,'String'));
iby=str2num(get(handles.iby,'String'));
umin=dt*pxcmx*str2num(get(handles.umin,'String'));
umax=dt*pxcmx*str2num(get(handles.umax,'String'));
vmin=dt*pxcmy*str2num(get(handles.vmin,'String'));
vmax=dt*pxcmy*str2num(get(handles.vmax,'String'));
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


%---------------------------------------------------------
% Executes on carriage return on the subdir civ1 edit window
%--------------------------------------------------------
function subdir_civ1_Callback(hObject, eventdata, handles)
subdir=get(handles.subdir_civ1,'String');
set(handles.subdir_civ2,'String',subdir);
if get(handles.CIV1,'Value')==0 
    find_netcpair_civ1(hObject, eventdata, handles); %update the list of available pairs from netcdf files in the new directory
end

%---------------------------------------------------------
% Executes on carriage return on the subdir civ1 edit window
%---------------------------------------------------------
function subdir_civ2_Callback(hObject, eventdata, handles)
%update the list of available pairs from netcdf files in the new directory
if get(handles.CIV2,'Value')==0 & get(handles.CIV1,'Value')==0 & get(handles.FIX1,'Value')==0 & get(handles.PATCH1,'Value')==0
    find_netcpair_civ2(hObject, eventdata, handles);
end

%------------------------------------------------------
% --- Executes on button press in get_mask_civ1.
%------------------------------------------------------
function get_mask_civ1_Callback(hObject, eventdata, handles)
maskval=get(handles.get_mask_civ1,'Value')
if isequal(maskval,0)
    set(handles.mask_civ1,'String','')
else
mask_displ='no mask'; %default
filebase=get(handles.displ_filebase,'String');
[ nbslice, flag_mask]=get_mask(filebase,handles)
if isequal(flag_mask,1)
      mask_displ=[num2str(nbslice) 'mask'];
end
if get(handles.compare,'Value')==1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.displ_filebase2,'String');
        [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles)
        if isequal(flag_mask_a,0) | ~isequal(nbslice_a,nbslice)
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
    set(handles.get_mask_civ2,'Value',1)
    set(handles.get_mask_fix2,'Value',1)
end
set(handles.mask_civ1,'String',mask_displ)
set(handles.mask_fix1,'String',mask_displ)
set(handles.mask_civ2,'String',mask_displ)
set(handles.mask_fix2,'String',mask_displ)
end
%--------------------------------------------------------------
% --- Executes on button press in get_mask_fix1.
function get_mask_fix1_Callback(hObject, eventdata, handles)
maskval=get(handles.get_mask_fix1,'Value')
if isequal(maskval,0)
    set(handles.mask_fix1,'String','')
else
mask_displ='no mask'; %default
filebase=get(handles.displ_filebase,'String');
[nbslice, flag_mask]=get_mask(filebase,handles)
if isequal(flag_mask,1)
      mask_displ=[num2str(nbslice) 'mask'];
end
if get(handles.compare,'Value')==1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.displ_filebase2,'String');
        [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles)
        if isequal(flag_mask_a,0) | ~isequal(nbslice_a,nbslice)
            mask_displ='no mask';
        end
end
if isequal(mask_displ,'no mask')
    set(handles.get_mask_fix1,'Value',0)
    set(handles.get_mask_civ2,'Value',0)
    set(handles.get_mask_fix2,'Value',0)
else
    set(handles.get_mask_civ2,'Value',1)
    set(handles.get_mask_fix2,'Value',1)
end 
set(handles.mask_fix1,'String',mask_displ)
set(handles.mask_civ2,'String',mask_displ)
set(handles.mask_fix2,'String',mask_displ)
end
%-----------------------------------------
% --- Executes on button press in get_mask_civ2.
function get_mask_civ2_Callback(hObject, eventdata, handles)
maskval=get(handles.get_mask_civ2,'Value')
if isequal(maskval,0)
    set(handles.mask_civ2,'String','')
else
mask_displ='no mask'; %default
filebase=get(handles.displ_filebase,'String');
[nbslice, flag_mask]=get_mask(filebase,handles)
if isequal(flag_mask,1)
      mask_displ=[num2str(nbslice) 'mask'];
end
if get(handles.compare,'Value')==1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.displ_filebase2,'String');
        [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles)
        if isequal(flag_mask_a,0) | ~isequal(nbslice_a,nbslice)
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
%-------------------------------------
% --- Executes on button press in get_mask_fix2.
function get_mask_fix2_Callback(hObject, eventdata, handles)
maskval=get(handles.get_mask_fix2,'Value')
if isequal(maskval,0)
    set(handles.mask_fix2,'String','')
else
mask_displ='no mask'; %default
filebase=get(handles.displ_filebase,'String');
[nbslice, flag_mask]=get_mask(filebase,handles)
if isequal(flag_mask,1)
      mask_displ=[num2str(nbslice) 'mask'];
end
if get(handles.compare,'Value')==1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.displ_filebase2,'String');
        [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles)
        if isequal(flag_mask_a,0) | ~isequal(nbslice_a,nbslice)
            mask_displ='no mask';
        end
end
if isequal(mask_displ,'no mask')
    set(handles.get_mask_fix2,'Value',0)
end 
set(handles.mask_fix2,'String',mask_displ)
end

%---------------------------------------
function [nbslice, flag_mask]=get_mask(filebase,handles)
%detect mask files, images with appropriate file base 
%[filebase '_' xx 'mask'], xx=nbslice
%flag_mask=1 indicates detection

flag_mask=0;%default
nbslice=1;

% subdir=get(handles.subdir_civ1,'String');
[Path,Name]=fileparts(filebase)
currentdir=pwd;
cd(Path);%move in the dir of the root name filebase
maskfiles=dir([Name '_*mask_*.png'])%look for mask files
cd(currentdir);%come back to the current working directory
if isempty(maskfiles)
    browse=get(handles.browse_root,'UserData');
     varargin{1}='';
    [image_name,idetect]=name_generator(filebase,1,1,browse.ext_ima,browse.nom_type_ima);%name of an image
    if idetect==1
         varargin{1}=image_name;
    end
    warndlg_uvmat('no mask available, use TOOL menu in the uvmat interface to create it','ERROR')
%     makemask(varargin); %open the makemask interface
else
    maskname=maskfiles(1).name;% take the first mask file in the list
    [Path2,Name,ext]=fileparts(maskname);
    Namedouble=double(Name);
    val=(48>Namedouble)|(Namedouble>57);% select the non-numerical characters
    ind_mask=findstr('mask',Name);
    i=ind_mask-1;
    while val(i)==0 & i>0
       i=i-1;
    end
    nbslice=str2num(Name(i+1:ind_mask-1));
    if ~isequal(nbslice,[]) & Name(i)=='_'
          flag_mask=1;
    else
          errordlg(['bad mask file ' Name ext ' found in ' Path2])
          return
          nbslice=1;
    end
end    
%------------------------------


function grid_civ1_Callback(hObject, eventdata, handles)
% hObject    handle to grid_civ1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of grid_civ1 as text
%        str2double(get(hObject,'String')) returns contents of grid_civ1 as a double


%-----------------------------------------------------------
% transform numbers to letters
%--------------------------------------------
function str=num2stra(num,nom_type);
if isequal(nom_type,'png_old') | isequal(nom_type,'netc_old') |isequal(nom_type,'raw_SMD')
    str=char(96+num);
elseif isequal(nom_type,'_i')|isequal(nom_type,'_i1-i2')...
        |isequal(nom_type,'ima_num')| isequal(nom_type,'avi')| isequal(nom_type,'none')
    str='';
else
    str=num2str(num);
end
%---------------------------------------------------
function mask_civ1_Callback(hObject, eventdata, handles)
set(handles.mask_civ1,'UserData',[])
set(handles.mask_civ1,'String','')
%----------------------------------------------------
function mask_civ2_Callback(hObject, eventdata, handles)
set(handles.mask_civ2,'UserData',[])
set(handles.mask_civ2,'String','')
%----------------------------------------------------
function mask_fix1_Callback(hObject, eventdata, handles)
set(handles.mask_fix1,'UserData',[])
set(handles.mask_fix1,'String','')
%----------------------------------------------------
function mask_fix2_Callback(hObject, eventdata, handles)
set(handles.mask_fix2,'UserData',[])
set(handles.mask_fix2,'String','')

%--------------------------------------------------------------------------
% --- Executes on button press in list_subdir_civ1.
function list_subdir_civ1_Callback(hObject, eventdata, handles)

filebase=get(handles.displ_filebase,'String');
dirinput = uigetdir(filebase)
    set(handles.subdir_civ1,'String',dirinput)
    set(handles.subdir_civ2,'String',dirinput)

displ_filebase_Callback(hObject, eventdata, handles);


function rho_civ2_Callback(hObject, eventdata, handles)
% hObject    handle to rho_civ2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rho_civ2 as text
%        str2double(get(hObject,'String')) returns contents of rho_civ2 as a double

%----------------------------------------------
function last_i_Callback(hObject, eventdata, handles)
first_i=str2num(get(handles.first_i,'String'));
last_i=str2num(get(handles.last_i,'String'));
ref_i=ceil((first_i+last_i)/2);
set(handles.ref_i,'String', num2str(ref_i))
ref_i_Callback(hObject, eventdata, handles)

%-------------------------------------------------------
function last_j_Callback(hObject, eventdata, handles)
first_j=str2num(get(handles.first_j,'String'));
last_j=str2num(get(handles.last_j,'String'));
ref_j=ceil((first_j+last_j)/2);
set(handles.ref_j,'String', num2str(ref_j))
ref_j_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
% --- Executes on button press in browse_gridciv1.
function browse_gridciv1_Callback(hObject, eventdata, handles)
value=get(handles.browse_gridciv1,'Value');
if value
	filebase=get(handles.displ_filebase,'String');
	[FileName, PathName, filterindex] = uigetfile( ...
           {'*.grid', ' (*.grid)';
            '*.grid',  '.grid files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a file',filebase);
	filegrid=fullfile(PathName,FileName);
    if isempty(FileName)|isempty(PathName)|isequal(FileName,0)|~exist(filegrid,'file')
        set(handles.browse_gridciv1,'Value',0);
        set(handles.grid_civ1,'string','');
	    set(handles.dx_civ1,'Visible','on');
	    set(handles.dy_civ1,'Visible','on');
	    set(handles.grid_civ2,'string','');
        if get(handles.CIV2,'Value')
	        set(handles.dx_civ2,'Visible','on');
	        set(handles.dy_civ2,'Visible','on');
        end
    else
		set(handles.grid_civ1,'string',filegrid);
		set(handles.dx_civ1,'Visible','off');
		set(handles.dy_civ1,'Visible','off');
		set(handles.grid_civ2,'string',filegrid);
		set(handles.dx_civ2,'Visible','off');
		set(handles.dy_civ2,'Visible','off');
% set(handles.grid_patch1,'string',filegrid);
% set(handles.grid_patch2,'string',filegrid);
    end
else
    set(handles.grid_civ1,'string','');
	set(handles.dx_civ1,'Visible','on');
	set(handles.dy_civ1,'Visible','on');
	set(handles.grid_civ2,'string','');
    if get(handles.CIV2,'Value')
	    set(handles.dx_civ2,'Visible','on');
	    set(handles.dy_civ2,'Visible','on');
    end
end



function pxcmx_Callback(hObject, eventdata, handles)
% hObject    handle to pxcmx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pxcmx as text
%        str2double(get(hObject,'String')) returns contents of pxcmx as a double



function pxcmy_Callback(hObject, eventdata, handles)
% hObject    handle to pxcmy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pxcmy as text
%        str2double(get(hObject,'String')) returns contents of pxcmy as a double


% --- Executes on button press in browse_gridciv2.
function browse_gridciv2_Callback(hObject, eventdata, handles)

filebase=get(handles.displ_filebase,'String');
[FileName, PathName, filterindex] = uigetfile( ...
       {'*.grid', ' (*.grid)';
        '*.grid',  '.grid files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',filebase);
filegrid=fullfile(PathName,FileName);
set(handles.grid_civ2,'string',filegrid);
set(handles.dx_civ2,'String',' ');
set(handles.dy_civ2,'String',' ');
% set(handles.grid_patch2,'string',filegrid);

% --- Executes on button press in get_gridpatch1.
function get_gridpatch1_Callback(hObject, eventdata, handles)
% hObject    handle to get_gridpatch1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

filebase=get(handles.displ_filebase,'String');
[FileName, PathName, filterindex] = uigetfile( ...
       {'*.grid', ' (*.grid)';
        '*.grid',  '.grid files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',filebase);
filegrid=fullfile(PathName,FileName);
set(handles.grid_patch1,'string',filegrid);
% set(handles.grid_patch2,'string',filegrid

%-----------------------------------------------------------------
% --- Executes on button press in get_gridpatch2.
function get_gridpatch2_Callback(hObject, eventdata, handles)
% hObject    handle to get_gridpatch2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%----------------------------------------------------------
function enable_civ1(handles,state)
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

%----------------------------------------------------------
function enable_fix1(handles)
set(handles.frame_fix1,'BackgroundColor',[1 1 0])
set(handles.REMOVE,'Visible','on')
set(handles.vec_Fmin2,'Visible','on')
set(handles.vec_F2,'Visible','on')
set(handles.vec_F3,'Visible','on')
set(handles.thresh_vecC,'Visible','on')
set(handles.thresh_vecC_title,'Visible','on')
set(handles.thresh_vel,'Visible','on')
set(handles.thresh_vel_text,'Visible','on')
set(handles.mask_fix1,'Visible','on')
set(handles.get_mask_fix1,'Visible','on')
set(handles.get_ref_fix1,'Visible','on')
set(handles.ref_fix1,'Visible','on')
set(handles.inf_sup1,'Visible','on')
set(handles.field_ref1,'Visible','on')

%----------------------------------------------------------
function desable_fix1(handles)
set(handles.frame_fix1,'BackgroundColor',[0.831 0.816 0.784])
set(handles.REMOVE,'Visible','off')
set(handles.vec_Fmin2,'Visible','off')
set(handles.vec_F2,'Visible','off')
set(handles.vec_F3,'Visible','off')
set(handles.thresh_vecC,'Visible','off')
set(handles.thresh_vecC_title,'Visible','off')
set(handles.thresh_vel,'Visible','off')
set(handles.thresh_vel_text,'Visible','off')
set(handles.mask_fix1,'Visible','off')
set(handles.get_mask_fix1,'Visible','off')
set(handles.get_ref_fix1,'Visible','off')
set(handles.ref_fix1,'Visible','off')
set(handles.inf_sup1,'Visible','off')
set(handles.field_ref1,'Visible','off')

%--------------------------------------------------------------
function enable_patch1(handles)
global patch_new_exe
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
if (~isequal(patch_new_exe,[]) & ~isequal(patch_new_exe,[]))
    set(handles.test_interp,'Visible','on');
end
set(handles.get_gridpatch1,'Visible','on')
set(handles.grid_patch1,'string','none');
set(handles.grid_patch1,'Visible','on')

%--------------------------------------------------------------
function desable_patch1(handles)
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
set(handles.test_interp,'Visible','off')
set(handles.get_gridpatch1,'Visible','off')
set(handles.grid_patch1,'Visible','off')

%----------------------------------------------------------
function enable_civ2(handles,state)
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
    end
else
    set(handles.list_pair_civ2,'Visible','on')
    set(handles.subdir_civ2,'Visible','on')
    set(handles.subdir_civ2_text,'Visible','on')
end

%----------------------------------------------------------
% function desable_civ2(handles)
% set(handles.frame_civ2,'BackgroundColor',[0.831 0.816 0.784])
% set(handles.frame_para_civ2,'BackgroundColor',[0.831 0.816 0.784])
% set(handles.frame_grid_civ2,'BackgroundColor',[0.831 0.816 0.784])
% set(handles.ibx_civ2,'Visible','off')
% set(handles.iby_civ2,'Visible','off')
% set(handles.decimal,'Visible','off')
% set(handles.deformation,'Visible','off')
% set(handles.rho_civ2,'Visible','off')
% set(handles.dx_civ2,'Visible','off')
% set(handles.dy_civ2,'Visible','off')
% set(handles.browse_gridciv2,'Visible','off')
% set(handles.get_mask_civ2,'Visible','off')
% set(handles.parameters,'Visible','off')
% set(handles.grid,'Visible','off')
% set(handles.grid,'Visible','on')
% set(handles.parameters_text,'Visible','off')
% set(handles.grid_text,'Visible','off')
% set(handles.grid_civ2,'Visible','off')
% set(handles.mask_civ2,'Visible','off')
% set(handles.dx_civ2_title,'Visible','off')
% set(handles.dy_civ2_title,'Visible','off')
% set(handles.ibx_civ2_text,'Visible','off')
% set(handles.rho_civ2_title,'Visible','off')
% set(handles.frame_subdirciv2,'BackgroundColor',[0.831 0.816 0.784])
% if isequal(get(handles.FIX2,'Value'),0) & isequal(get(handles.PATCH2,'Value'),0) 
%     set(handles.list_pair_civ2,'Visible','off')
%     set(handles.subdir_civ2,'Visible','off')
%     set(handles.subdir_civ2_text,'Visible','off')
% end

%----------------------------------------------------------
function enable_fix2(handles)
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

%----------------------------------------------------------
function desable_fix2(handles)
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

%--------------------------------------------------------------
function enable_patch2(handles)
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

%--------------------------------------------------------------
function desable_patch2(handles)
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

% --- Executes on button press in test_interp.
function test_interp_Callback(hObject, eventdata, handles)


%------------------------------------------------
%Read the parameters for civ1 on the interface
%--------------------------------------------------
function par=read_param_civ1(handles,file_ima)

ibx_val=str2num(get(handles.ibx,'String'));
par.correlationBoxesSize_X=num2str(ibx_val);
iby_val=str2num(get(handles.iby,'String'));
par.correlationBoxesSize_Y=num2str(iby_val);
ibz_val=str2num(get(handles.ibz,'String'));
par.correlationBoxesSize_Z=num2str(ibz_val);
isx=get(handles.isx,'String');
if isempty(str2num(isx)), isx='41'; set(handles.isx,'String','41'), end; %default
maxDisplacement_X=floor((str2num(isx)-ibx_val)/2);
par.maxDisplacement_X=num2str(maxDisplacement_X);
isy=get(handles.isy,'String');
if isempty(str2num(isy)), isy='41'; set(handles.isy,'String','41'), end; %default
maxDisplacement_Y=floor((str2num(isy)-iby_val)/2);
par.maxDisplacement_Y=num2str(maxDisplacement_Y);
isz=get(handles.isz,'String');
if isempty(str2num(isz)), isz='41'; set(handles.isz,'String','41'), end; %default
maxDisplacement_Z=floor((str2num(isz)-ibz_val)/2);
par.maxDisplacement_Z=num2str(maxDisplacement_Z);
%      par.rho=get(handles.rho,'String');
par.gridSpacing_X=get(handles.dx_civ1,'String');
par.gridSpacing_Y=get(handles.dy_civ1,'String');
par.gridSpacing_Z=get(handles.dz_civ1,'String');
% Zmin=str2num(get(handles.first_j,'String'))-1;
Zmax=str2num(get(handles.nb_field2,'String'));
par.gridLimits_Xmin=0;
par.gridLimits_Ymin=0;
par.gridLimits_Zmin=0;
% A=imread(file_ima);%read the first image to get the size
%sizim=size(A);
par.gridLimits_Xmax=1024;%num2str(sizim(2));
par.gridLimits_Ymax=1024;%num2str(sizim(1));
par.gridLimits_Zmax=Zmax;
par.grid='grille';
par.grid_division=4;
par.hart=0;
par.ratioHoverZ=1;

%      
% %----------------------------------------------------------------
% function par=read_param_civ2(handles,file_ima)
%     par.ibx=get(handles.ibx_civ2,'String');
%     par.iby=get(handles.iby_civ2,'String');
%     par.rho=get(handles.rho_civ2,'String');
%     par.decimal=int2str(get(handles.decimal,'Value'));
%     par.deformation=int2str(get(handles.deformation,'Value'));
%     par.dx=get(handles.dx_civ2,'String');
%     par.dy=get(handles.dy_civ2,'String');
%     if isequal(str2num(par.dx),[]) 
%          if isempty(get(handles.grid_civ2,'String'));
%              par.dx='0'; %just read by civ_3D program, not used
%          else
%             par.dx='20';%default
%             set(handles.dx_civ2,'String','20');
%          end
%      end
%      if isequal(str2num(par.dy),[])
%          if isempty(get(handles.grid_civ2,'String'));
%              par.dy='0';%just read by civ_3D program, not used
%          else
%             par.dy='20';%default
%             set(handles.dy_civ2,'String','20');
%          end
%      end
%     par.pxcmx=get(handles.pxcmx,'String');
%     par.pxcmy=get(handles.pxcmy,'String');
%     if isempty(str2num(par.pxcmx)) |isempty(str2num(par.pxcmy)) 
%         par.pxcmx='1';
%          par.pxcmy='1';
%     end
% %     par.npx=get(handles.pxcmx,'UserData');
% %     par.npy=get(handles.pxcmy,'UserData');
%     A=imread(file_ima);%read the first image to get the size
%     sizim=size(A);
%     par.npx=num2str(sizim(2));
%     par.npy=num2str(sizim(1));
%     time=get(handles.displ_filebase,'UserData'); %get the set of times
%     par.gridname=get(handles.grid_civ2,'String');
%     par.gridflag='y';
%     if isequal(par.gridname,'')| isempty(par.gridname)
%         par.gridname='nogrid';
%         par.gridflag='n';
%     end


%---------------------------------------------------------
%CIV1  CIV1  CIV1 CIV1
%----------------------------------------------------------
function cmd_CIV1=BATCH_CIV1(filename,namelog,par,handles)
%pixels per cm and matrix of the image times, read from the .civ_3D file by uvmat
global civ1_exe Civ_exe sge%name of the executable for civ1 calculation

%changes : filename_cmx -> filename ( no extension )

            if isequal(par.Dt,'0')
                par.Dt='1' ;%case of 'displacement' mode
            end         
 
    textcmx={'##############   CMX file';...
    ['FirstImage ' par.filename_ima_a];...
    ['LastImage  ' par.filename_ima_b];...
    'XX' ;...
    ['Mask ' par.maskflag] ;...
    ['MaskName ' par.maskname];...
    ['ImageSize ' par.npx ' ' par.npy];...   %VERIFIER CAS GENERAL ?
    ['CorrelationBoxesSize ' par.ibx ' ' par.iby];...
    ['SearchBoxeSize ' par.isx ' ' par.isy];...
    ['RO ' par.rho];...
    ['GridSpacing ' par.dx ' ' par.dy];...
    'XX 1.0';...
    ['Dt_TO ' par.Dt ' ' par.T0];...
    ['PixCmXY ' par.pxcmx ' ' par.pxcmy];...
    'XX 1';...
    ['ShiftXY ' par.shiftx ' '  par.shifty];...
    ['Grid ' par.gridflag];...
    ['GridName ' par.gridname] ;...
    'XX 85';...
    'XX 1.0';...
    'XX 1.0';...
    'Hart 1';...
    'DecimalShift 0';...
    'Deformation 0';...
    'CorrelationMin 0';...
    'IntensityMin 0';...
    'SeuilImage n';...
    'SeuilImageValues 0 4096';...
    ['ImageToUse ' par.term_a ' ' par.term_b];... % VERIFIER ?
    'ImageUsedBefore null null'};

            textout=char(textcmx);
    %         timeL1=clock;
            dlmwrite([filename '.cmx'],textout,'');
    %             timeL2=clock;
    %     timciv1=etime(timeL2,timeL1)
          if sge  
          cmd_CIV1=[civ1_exe ' -f ' filename '.cmx' ]; % redirect standard output to the log file
          else
              cmd_CIV1=[civ1_exe ' -f ' filename_cmx ' > ' namelog ' 2>&1']; % redirect standard output to the log file
          end
    if(isunix)
    	[Rootbat,Filebat,extbat]=fileparts(namelog);
    	ncName=fullfile(Rootbat,[ Filebat '.nc']);
	    cmd_CIV1=char({cmd_CIV1 ; ['mv ' namelog  ' ' namelog '.civ1.log'];['chmod g+w ' ncName]});
    else
        cmd_CIV1=char({cmd_CIV1 ; ['copy /Y ' namelog ' ' namelog '.civ1.log']});
    end

%---------------------------------------------------------
%CIV1  Unified
%----------------------------------------------------------
function xml_civ1_parameters=BATCH_CIV1_Unified(filename,namelog,par,handles)
%pixels per cm and matrix of the image times, read from the .civ_3D file by uvmat
global civ1_exe Civ_exe%name of the executable for civ1 calculation

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
    end
    civ1.gridSpacing_X=par.dx;
    civ1.gridSpacing_Y=par.dy;
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
   
%---------------------------------------------------------
%CIV2  CIV2  CIV2 CIV2
%----------------------------------------------------------
function cmd_CIV2=BATCH_CIV2(filename_cmx,namelog,par)
%pixels per cm and matrix of the image times, read from the .civ_3D file by uvmat
global civ2_exe sge%name of the executable for civ1 calculation
   if isequal(par.Dt,'0')
                par.Dt='1' ;%case of 'displacement' mode
  end 
textcmx={'##############   CMX file';...
['FirstImage ' par.filename_ima_a];...
['LastImage  ' par.filename_ima_b];...
'XX' ;...
['Mask ' par.maskflag];...
['MaskName ' par.maskname];...
['ImageSize ' par.npx ' ' par.npy];...   
['CorrelationBoxesSize ' par.ibx ' ' par.iby];...
['SearchBoxeSize ' par.ibx ' ' par.iby];...
['RO ' par.rho];...
['GridSpacing ' par.dx ' ' par.dy];...
'XX 1.0';...
['Dt_TO ' par.Dt ' ' par.T0];...
['PixCmXY ' par.pxcmx ' ' par.pxcmy];...
'XX 1';...
['ShiftXY 0 0'];...
['Grid ' par.gridflag];...
['GridName ' par.gridname];...
'XX 85';...
'XX 1.0';...
'XX 1.0';...
'Hart 1';...
['DecimalShift ' par.decimal];...
['Deformation ' par.deformation];...
'CorrelationMin 0';...
'IntensityMin 0';...
'SeuilImage n';...
'SeuilImageValues 0 4096';...
['ImageToUse ' par.term_a ' ' par.term_b];... % VERIFIER ?
['ImageUsedBefore ' par.filename_nc1]};
        textout=char(textcmx);
        dlmwrite([filename_cmx '2'] ,textout,'');
        if sge
        cmd_CIV2=[civ2_exe ' -f ' filename_cmx ]; % redirect standard output to the log file
        else
          cmd_CIV2=[civ2_exe ' -f ' filename_cmx ' > ' namelog ' 2>&1']; % redirect standard output to the log file
      end


% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), errordlg('Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
web([helpfile '#civ_3D'])    
end


%----------------------------------------------------------
%--read images and convert them to the uint16 format used for PIV
function A=read_image(filename,nom_type,npx,npy,num);
%npx, npy are the dimensions needed for the raw SMD images
%num is the view number needed for an avi movie
if isequal(nom_type,'avi')
    mov=aviread(filename,num);
    A=frame2im(mov(1));
    A=sum(double(A),3);
    A=uint16(A);
elseif isequal(nom_type,'raw_SMD')
    [fid,message]=fopen(filename,'r');    
    B=fread(fid,Inf,'int16',0,'ieee-le');%read 16 bit binary file
    A=(reshape(B,npx,npy))'; %remplissage ligne par ligne avec une matrice colonne ? transposer(uB) pour avoir une matrice ligne
    A=uint16(A);
    fclose(fid);
else
    A=imread(filename);
    siz=size(A);
    if length(siz)==3;%color images
        A=sum(double(A),3);
    end
    A=uint16(A);
end
        
%----------------------------------------------------------------
%Executes on carriage return on the time interval dt
%----------------------------------------------------------------
function dt_Callback(hObject, eventdata, handles)
%determine the set of times and possible intervals for CIV_3D
%                 answer=inputdlg('time interval between images?');
                dt=(1/1000)*str2num(get(handles.dt,'String'));
                nbfield=str2num(get(handles.nb_field,'String')); %last image number selected in the processing series
                time=(dt*[0:nbfield-1])';
%                 set(handles.incr_i,'UserData',dt);%store the time interval between successive images
                set(handles.displ_filebase,'UserData',time); %store the set of times
                for index=1:min(nbfield-1,200)
                    displ_num(1,index)=1;
                    displ_num(2,index)=1;
                    displ_num(3,index)=-floor(index/2);
                    displ_num(4,index)=ceil(index/2);
                end
set(handles.list_pair_civ1,'Value',1);
set(handles.list_pair_civ1,'UserData',displ_num);
set(handles.list_pair_civ2,'Value',1);
%update the list of time intervals
find_netcpair_civ1(hObject, eventdata, handles)
find_netcpair_civ2(hObject, eventdata, handles)

%-------------------------------------------------------
function ref_i_Callback(hObject, eventdata, handles)
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if isequal(get(handles.CIV1,'Value'),0)| isequal(mode,'series(Di)') 
    find_netcpair_civ1(hObject, eventdata, handles);% update the menu of pairs depending on the available netcdf files
end
if isequal(mode,'series(Di)') | ...% we do patch2 only
   (get(handles.CIV2,'Value')==0 & get(handles.CIV1,'Value')==0 & get(handles.FIX1,'Value')==0 & get(handles.PATCH1,'Value')==0)
    find_netcpair_civ2(hObject, eventdata, handles);
end

%----------------------------------------------------
function ref_j_Callback(hObject, eventdata, handles)
mode_list=get(handles.mode,'String');
mode_value=get(handles.mode,'Value');
mode=mode_list{mode_value};
if isequal(get(handles.CIV1,'Value'),0)| isequal(mode,'series(Dj)') 
    find_netcpair_civ1(hObject, eventdata, handles);% update the menu of pairs depending on the available netcdf files
end
if isequal(mode,'series(Dj)') | ...
   (get(handles.CIV2,'Value')==0 & get(handles.CIV1,'Value')==0 & get(handles.FIX1,'Value')==0 & get(handles.PATCH1,'Value')==0)
    find_netcpair_civ2(hObject, eventdata, handles);
end
%----------------------------------------------------
% --- Executes on button press in compare.
function compare_Callback(hObject, eventdata, handles)
test=get(handles.compare,'Value');
if test
    filebase=get(handles.displ_filebase,'String');
    browse=get(handles.browse_root,'Userdata');
    browse.nom_type_ima1=browse.nom_type_ima;
    set(handles.browse_root,'UserData',browse);
    set(handles.displ_filebase2,'Visible','On');%mkes the second file input window visible 
    set(handles.displ_filebase2,'String',filebase);
    mode_store=get(handles.mode,'String');%get the present 'mode'
    set(handles.compare,'UserData',mode_store);%store the mode display
    set(handles.mode,'Value',1)
    set(handles.mode,'String',{'displacement';'st_pair j1-j2'})
else
    set(handles.displ_filebase2,'Visible','Off');
    set(handles.displ_filebase2,'String',[]);
    mode_store=get(handles.compare,'UserData');
    set(handles.mode,'String',mode_store)
    set(handles.test_stereo1,'Value',0)
    set(handles.test_stereo2,'Value',0)
end
mode_Callback(hObject, eventdata, handles)

%-----------------------------------------------------------
% --- Executes on button press in get_ref_fix1.
function get_ref_fix1_Callback(hObject, eventdata, handles)
filebase=get(handles.displ_filebase,'String');
[FileName, PathName, filterindex] = uigetfile( ...
       {'*.nc', ' (*.nc)';
        '*.nc',  'netcdf files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',filebase);
    
fileinput=[PathName FileName];
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
%[filebasesub,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
[Path,File,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
%filebase=fullfile(RootPath,RootFile);
% [Pth,FileN]=fileparts(filebasesub);
% Pth=fileparts(Pth);
ref.filebase=fullfile(Path,File);
ref.num_a=stra2num(str_a);
ref.num_b=stra2num(str_b);
ref.num1=str2num(field_count);
ref.num2=str2num(str2);
browse=[];%initialisation
if ~isequal(ref.ext,'.nc')
    errordlg('the reference file must be in netcdf format (*.nc)')
    return
end
% [path,name]=fileparts(ref.filebase);
set(handles.ref_fix1,'String',[fullfile(ref.subdir,File) '....nc']);
set(handles.ref_fix1,'UserData',ref)
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
% [cte_detect,vdt,cte_read]=read_netcdf(fileinput,{'patch','civ2','patch2'});
% if isequal(cte_detect(1),1) & isequal(cte_read(1),1)
%          menu_field{2}='filter1';
% end
% if isequal(cte_detect(2),1) & isequal(cte_read(2),1)
%          menu_field{3}='civ2';
% end
% if isequal(cte_detect(3),1) & isequal(cte_read(3),1)
%          menu_field{4}='filter2';
% end
set(handles.field_ref1,'String',menu_field);
set(handles.field_ref1,'Value',length(menu_field));
set(handles.inf_sup1,'Value',2);
set(handles.thresh_vel,'String','1');%default threshold
set(handles.ref_fix1,'Enable','on')
 
%---------------------------------------------------------------
% --- Executes on button press in get_ref_fix2.
function get_ref_fix2_Callback(hObject, eventdata, handles)
if isequal(get(handles.get_ref_fix2,'Value'),1)
    filebase=get(handles.displ_filebase,'String');
    [FileName, PathName, filterindex] = uigetfile( ...
           {'*.nc', ' (*.nc)';
            '*.nc',  'netcdf files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a file',filebase);
    fileinput=[PathName FileName];
    sizf=size(fileinput);
    if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
    %[filebasesub,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
    [Path,File,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
%     [Pth,FileN]=fileparts(filebasesub);
%     Pth=fileparts(Pth);
    ref.filebase=fullfile(Path,File)
    ref.num_a=stra2num(str_a);
    ref.num_b=stra2num(str_b);
    ref.num1=str2num(field_count);
    ref.num2=str2num(str2);
    browse=[];%initialisation
    if ~isequal(ref.ext,'.nc')
        errordlg('the reference file must be in netcdf format (*.nc)')
        return
    end
%     [path,name]=fileparts(ref.filebase);
    set(handles.ref_fix2,'String',[fullfile(ref.subdir,File) '....nc']);
    set(handles.ref_fix2,'UserData',ref)    
    menu_field{1}='civ1';
%     [cte_detect,vdt,cte_read]=read_netcdf(fileinput,{'patch','civ2','patch2'});
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

%     if isequal(cte_detect(1),1) & isequal(cte_read(1),1)
%              menu_field{2}='filter1';
%     end
%     if isequal(cte_detect(2),1) & isequal(cte_read(2),1)
%              menu_field{3}='civ2';
%     end
%     if isequal(cte_detect(3),1) & isequal(cte_read(3),1)
%              menu_field{4}='filter2';
%     end
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
%-------------------------------------------------------

function ref_fix1_Callback(hObject, eventdata, handles)
    set(handles.inf_sup1,'Value',1);
    set(handles.field_ref1,'Value',1)
    set(handles.field_ref1,'String',{' '})
    set(handles.ref_fix1,'UserData',[]);
    set(handles.ref_fix1,'String','');
    set(handles.thresh_vel1,'String','0');
 

%------------------------------------------------------

function ref_fix2_Callback(hObject, eventdata, handles)
    set(handles.inf_sup2,'Value',1);
    set(handles.field_ref2,'Value',1)
    set(handles.field_ref2,'String',{' '})
    set(handles.ref_fix2,'UserData',[]);
    set(handles.ref_fix2,'String','');
    set(handles.thresh_vel2,'String','0');

%--------------------------------------------------------
% --- Executes on selection change in inf_sup1.
function inf_sup1_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------


% --- Executes on selection change in field_ref.
function field_ref_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------------

% --- Executes on selection change in field_ref2.
function field_ref2_Callback(hObject, eventdata, handles)

% -----------------------------------------------------------
% transform letters to numbers
%--------------------------------------------
function numres=stra2num(str)
numres=double(str)-96;
if double(str) >= 48 & double(str) <= 57 % = 1 for numbers
    numres=str2num(str);
end


% --- Executes on button press in test_stereo1.
function test_stereo1_Callback(hObject, eventdata, handles)
if isequal(get(handles.test_stereo1,'Value'),0)
    set(handles.subdomain_patch1,'Visible','on')
    set(handles.rho_patch1,'Visible','on')
else
    set(handles.subdomain_patch1,'Visible','off')
    set(handles.rho_patch1,'Visible','off')
end

% --- Executes on button press in test_stereo2.
function test_stereo2_Callback(hObject, eventdata, handles)
if isequal(get(handles.test_stereo2,'Value'),0)
    set(handles.subdomain_patch2,'Visible','on')
    set(handles.rho_patch2,'Visible','on')
else
    set(handles.subdomain_patch2,'Visible','off')
    set(handles.rho_patch2,'Visible','off')
end

% --- Executes on button press in ImaThreshold.
function ImaThreshold_Callback(hObject, eventdata, handles)
if isequal(get(handles.ImaThreshold,'Value'),1)
    set(handles.MinIma,'Visible','on')
    set(handles.MaxIma,'Visible','on')
else
    set(handles.MinIma,'Visible','off')
    set(handles.MaxIma,'Visible','off')
end


% --- Executes on button press in ImaThreshold2.
function ImaThreshold2_Callback(hObject, eventdata, handles)
if isequal(get(handles.ImaThreshold2,'Value'),1)
    set(handles.MinIma2,'Visible','on')
    set(handles.MaxIma2,'Visible','on')
else
    set(handles.MinIma2,'Visible','off')
    set(handles.MaxIma2,'Visible','off')
end



% --- Executes on button press in Experimental.
function Experimental_Callback(hObject, eventdata, handles)



function ibz_Callback(hObject, eventdata, handles)
% hObject    handle to ibz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ibz as text
%        str2double(get(hObject,'String')) returns contents of ibz as a double


% --- Executes during object creation, after setting all properties.
function ibz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ibz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit74_Callback(hObject, eventdata, handles)
% hObject    handle to edit74 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit74 as text
%        str2double(get(hObject,'String')) returns contents of edit74 as a double


% --- Executes during object creation, after setting all properties.
function edit74_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit74 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit75_Callback(hObject, eventdata, handles)
% hObject    handle to edit75 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit75 as text
%        str2double(get(hObject,'String')) returns contents of edit75 as a double


% --- Executes during object creation, after setting all properties.
function edit75_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit75 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dz_civ1_Callback(hObject, eventdata, handles)
% hObject    handle to dz_civ1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dz_civ1 as text
%        str2double(get(hObject,'String')) returns contents of dz_civ1 as a double


% --- Executes during object creation, after setting all properties.
function dz_civ1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dz_civ1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


