%'civ': function associated with the interface 'civ.fig' for PIV, spline interpolation and stereo PIV (patch)
%------------------------------------------------------------------------
%  provides an interface for the software menucivx
% function varargout = civ(varargin)
% provides an interface for the software menucivx
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2011, LEGI / CNRS-UJF-INPG, sommeria@legi.grenoble-inp.fr
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
%TODO: search range

% Last Modified by GUIDE v2.5 04-Dec-2011 08:42:47
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
function civ_OpeningFcn(hObject, eventdata, handles, fileinput)
%------------------------------------------------------------------------
% This function has no output args, see OutputFcn.

%% General settings
handles.output = hObject;
guidata(hObject, handles); % Update handles structure
set(hObject,'WindowButtonDownFcn',{'mouse_down'}) % allows mouse action with right button (zoom for uicontrol display)

%% Adjust the GUI according to the binaries available in PARAM.xml
path_civ=fileparts(which('civ')); %path to civ
addpath (path_civ) ; %add the path to civ, (useful in case of change of working directory after civ has been s opened in the working directory)
errormsg=[];%default error message
xmlfile='PARAM.xml';
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
    msgbox_uvmat('WARNING',errormsg);
end
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
        sparam.RunParam.CivBin=fullfile(path_civ,sparam.RunParam.CivBin);
    end
else
    sparam.RunParam.CivBin='';
end

%% load the list of previously browsed files in the upper bar menu Open/
dir_perso=prefdir; % path to the directory .matlab for personal data
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');% personal data file uvmauvmat_perso.mat' in .matlab
if exist(profil_perso,'file')
    h=load (profil_perso);
    if isfield(h,'MenuFile')
        for ifile=1:min(length(h.MenuFile),5)
            eval(['set(handles.MenuFile_' num2str(ifile) ',''Label'',h.MenuFile{ifile});'])
        end
    end
end

%% prepare the GUI with parameters from the input file if opened from uvmat
if exist('fileinput','var')% && isfield(param,'RootName') && ~isempty(param.RootName)
    errormsg=display_file_name(handles,fileinput);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg)
    end
end

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = civ_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1} = handles.output;

%------------------------------------------------------------------------
% --- Function activated by the Open/Browse... option in the upper menu bar.
function MenuBrowse_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%get the current input root file name to initiate the browser
filebase=get(handles.RootName,'String');
oldfile=''; %default
if isempty(filebase)|| isequal(filebase,'')%loads the previously stored root file name
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

%% prepare the GUI with parameters from the input file if opened from uvmat
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',erromsg)
end

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
% filebase=fullfile(RootPath,RootFile);
num_i1=str2double(str1);
if isnan(num_i1),num_i1=1;end
num_i2=str2double(str2);
if isnan(num_i2),num_i2=num_i1;end
num_j1=stra2num(str_a);
if isnan(num_j1),num_j1=1;end
num_j2=stra2num(str_b);
if isnan(num_j2),num_j2=num_j1;end
if isequal(get(handles.ListCompareMode,'Value'),1)
    browse=[];%initialisation
else
    browse=get(handlesRootName,'UserData');
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

set(handles.RootName,'UserData',browse);% store information from browser

%------------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_1
function MenuFile_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_1,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',erromsg)
end

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_2
function MenuFile_2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_2,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',erromsg)
end

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_3
function MenuFile_3_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_3,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',erromsg)
end

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_4
function MenuFile_4_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_4,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',erromsg)
end

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_5
function MenuFile_5_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_5,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',erromsg)
end

% -----------------------------------------------------------------------
% --- Prepare the GUI for the compiled CivX program
function MenuCivX_Callback(hObject, eventdata, handles)
set(handles.MenuMatlab,'checked','off')
set(handles.MenuCivX,'checked','on')
%set(handles.thresh_patch1,'Visible','off')
% set(handles.thresh_text1,'Visible','off')
set(handles.num_MaxDiff,'Visible','off')
set(handles.title_MaxDiff,'Visible','off')
set(handles.num_Rho,'Style','edit')
set(handles.num_Rho,'String','1')
set(handles.BATCH,'Enable','on')
% -----------------------------------------------------------------------

% -----------------------------------------------------------------------
% --- Prepare the GUI for the Matlab PIV program
function MenuMatlab_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
set(handles.MenuMatlab,'checked','on')
set(handles.MenuCivX,'checked','off')
% if get(handles.CheckPatch1,'Value')
set(handles.num_MaxDiff,'Visible','on')
set(handles.title_MaxDiff,'Visible','on')

% end
set(handles.num_Rho,'Style','popupmenu')
set(handles.num_Rho,'Value',1)
set(handles.num_Rho,'String',{'1';'2'})
set(handles.BATCH,'Enable','off')

% -----------------------------------------------------------------------
% --- Open the help html file 
function MenuHelp_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
path_civ=fileparts(which ('civ'));
helpfile=fullfile(path_civ,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile))
    msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
else
    addpath (fullfile(path_civ,'uvmat_doc'))
    web([helpfile '#civ'])
end

%------------------------------------------------------------------------
% --- Function activated when a new filebase (image series) is introduced
function RootName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
filebase=get(handles.RootName,'String');
errormsg=display_file_name(handles,filebase);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',erromsg)
end

%------------------------------------------------------------------------
% --- general function activated for an input file series
function errormsg=display_file_name(handles,fileinput)
%------------------------------------------------------------------------
set(handles.ListCompareMode,'Visible','on')
errormsg='';%default empty error message

%% enable RUN, BATCH button and 'status' display
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])%set RUN button to red color
set(handles.BATCH,'Enable','On')
set(handles.BATCH,'BackgroundColor',[1 0 0])%set BATCH button to red color
if isfield(handles,'status')
    set(handles.status,'Value',0);       %suppress the 'status' display
    status_Callback([], [], handles)
end

%% determine nomenclature types and extension of the input files
ext_ima='';%default
nom_type_ima='';%default
nom_type_nc='';
[RootPath,FileName,i1_str,i2_str,j1_str,j2_str,ext_input,nom_type_input,subdir]=name2display(fileinput);
RootName=fullfile(RootPath,FileName);
set(handles.RootName,'String',RootName)
set(handles.RootName,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
i1=str2double(i1_str);
i2=str2double(i2_str);
j1=str2double(j1_str);
j2=str2double(j2_str);
num_ref_i=i1;%efaulmt ref index
num_ref_j=j1;
browse.incr_pair=[0 0];%default

% form=imformats(ext_input(2:end));
if ~isempty(ext_input)&&(~isempty(imformats(ext_input(2:end)))||strcmpi(ext_input,'.avi'))% if the extension corresponds to an image or movie format recognized by Matlab
    ext_ima=ext_input;
    nom_type_ima=nom_type_input;
else %case of netcdf input file, look for corresponding images
    nom_type_nc=nom_type_input;
    if ~isnan(i2)
        num_ref_i=floor((num_ref_i+i2)/2);% reference image number corresponding to the file
        browse.incr_pair(1)=i2-i1;
        browse.incr_pair(2)=0;
    end
    %TODO: read the image name in the netcdf file (if documented)
    %look for double image series '_i_j'
    dirima=dir([RootName '_' i1_str '_' j1_str '.*']);
    if isempty(dirima)
        % look for images series  with sub marker '_'
        dirima=dir([RootName '_*' i1_str  '.*']);
        if isempty(dirima)
            % look for other images series
            dirima=dir([RootName '*' i1_str '.*']);
            if isempty(dirima)
                % look for other images series witth letter appendix
                appendix=char(96+j1_str);
                dirima=dir([RootName '*' i1_str appendix '.*']);
            end
        end
    end
    for ilist=1:numel(dirima)
        [pp,ff,i1_str,i2_str,j1_str,j2_str,ext_list,nom_type_list]=name2display(dirima(ilist).name);
        form=imformats(ext_list(2:end));
        if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
            ext_ima=ext_list;
            nom_type_ima=nom_type_list;
            i1=str2double(i1_str);
            j1=str2double(j1_str);
            i2=str2double(i2_str);
            j2=str2double(j2_str);          
            % set the range of fields (1:1 by default) and selected pair
            if isequal(i2,i1)||isnan(i2)
                num_ref_i=i1;
            else
                num_ref_i=floor((i1+i2)/2);
                browse.incr_pair(1)=i2-i1;
                browse.incr_pair(2)=0;
            end
            if isequal(j1,j2)||isnan(j2)
                if isnan(j1)
                    num_ref_j=1;
                else
                    num_ref_j=j1;
                end
            else
                num_ref_j=floor((j1+j2)/2);
                browse.incr_pair(2)=j2-j1;
            end 
            break
        end
    end
end

%% look for an image documentation file
ext_imadoc='';%default
if exist([RootName '.xml'],'file')
    ext_imadoc='.xml';
elseif exist([RootName '.civxml'],'file')
    ext_imadoc='.civxml';
elseif exist([RootName '.civ'],'file')
    ext_imadoc='.civ';
elseif exist([RootName '.avi'],'file')
    ext_imadoc='.avi';
elseif exist([RootName '.AVI'],'file')
    ext_imadoc='.AVI';
end
set(handles.ImaDoc,'String',ext_imadoc)% display the extension name for the image documentation file used
set(handles.ImaDoc,'BackgroundColor',[1 1 0])
drawnow
%%%%%%%%   read image documentation file  %%%%%%%%%%%%%%%%%%%%%%%%%%%
mode=''; %default
time=[];
TimeUnit='frame'; %default
CoordUnit='px';%default
pxcmx_search=[];%default
pxcmy_search=[];%default
if isequal(ext_imadoc,'.civxml')%TO ABANDON
    [nbfield,nbfield2,time]=read_civxml([RootName '.civxml']);
    mode='pair j1-j2';
    if isempty(nom_type_ima)% dtermine types by default if not already selected by browser or uvmat
        nom_type_ima='_i_j';
    end
elseif isequal(ext_imadoc,'.xml')
    [XmlData,warntext]=imadoc2struct([RootName '.xml']);
    ext_ima_read=[];
    nom_type_read=[];
    if isfield(XmlData,'Heading')&&isfield(XmlData.Heading','ImageName')&&ischar(XmlData.Heading.ImageName)% get image nom type and extension from the xml file
        [PP,FF,fc,str2,str_a,str_b,ext_ima_read,nom_type_read]=name2display(XmlData.Heading.ImageName);
        fullname=fullfile(fileparts(RootName),XmlData.Heading.ImageName); %full name (including path) of the first image defined by the xmle file,
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
            if numel(nom_type_read)>=2 && isempty(regexp(nom_type_read(2:end),'\D','once'))
                time=time';
                nbfield=nbfield2;
                nbfield2=1;
            end
        end
    end
    if isfield(XmlData,'TimeUnit')
        TimeUnit=XmlData.TimeUnit;
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
    [error,time,TimeUnit,mode,npx,npy]=read_imatext([RootName '.civ']);
    if error==2, msgbox_uvmat('WARNING',['no file ' RootName '.civ']);
    elseif error==1, msgbox_uvmat('WARNING','inconsistent number of fields in the .civ file');
    end
    nom_type_ima='001a';
elseif strcmpi(ext_imadoc,'.avi')
    nom_type_ima='*';
    ext_ima=ext_imadoc;
    set(handles.ListPairMode,'Value',1);
    set(handles.ListPairMode,'String',{'series(Di)'})
    dt=0.04;%default
    if exist([RootName ext_imadoc],'file')==2
        info=aviinfo([RootName ext_imadoc]);%read infos on the avi movie
        dt=1/info.FramesPerSecond;%time interval between successive frames
        nbfield=info.NumFrames;%number of frames
    end
    time=(dt*(0:nbfield-1))';%list of image times
end
if isempty(time)
    set(handles.ImaDoc,'String',''); %xml file not used for timing
end
set(handles.ImaDoc,'BackgroundColor',[1 1 1])% set display box to yellow color


%% timing display
%show the reference image edit box if relevant (not needed for movies or in the absence of time information
if ~isempty(time)
    if size(time,1)+size(time,2)>=3 % if there are at least two time values to define dt
        nbfield=size(time,1);
        nbfield2=size(time,2);
        set(handles.ImaDoc,'UserData',time); %store the set of times
        set(handles.dt_unit,'String',['dt in m' TimeUnit]);
        set(handles.TimeUnit,'String',TimeUnit);
        set(handles.nb_field,'String',num2str(nbfield));
        set(handles.nb_field2,'String',num2str(nbfield2));
    end
end
set(handles.CoordUnit,'String',CoordUnit)
set(handles.SearchRange,'UserData',[pxcmx_search pxcmy_search]);
set(handles.ImaExt,'String',ext_ima)
set(handles.ref_i,'String',num2str(num_ref_i))
set(handles.first_i,'String',num2str(num_ref_i));
set(handles.last_i,'String',num2str(num_ref_i));%
set(handles.ref_j,'String',num2str(num_ref_j))
set(handles.first_j,'String',num2str(num_ref_j));
set(handles.last_j,'String',num2str(num_ref_j));%

%% set the civ options depending on the input file content
ind_opening=0;%default
if isequal(ext_input,'.nc')
    browse.nom_type_nc=nom_type_input;
    ind_opening=2;% propose 'fix' as the default option
    Data=nc2struct(fileinput,'ListGlobalAttribute','CivStage','absolut_time_T0','fix','patch','civ2','fix2');
    if isfield(Data,'Txt')
        msgbox_uvmat('ERROR',Data.Txt)
        return
    end
    if ~isempty(Data.CivStage)%test for civ files
        ind_opening=Data.CivStage;
        set(handles.ListPairMode,'Value',3)
    end
end
ListOptions={'CheckCiv1', 'CheckFix1' 'CheckPatch1', 'CheckCiv2', 'CheckFix2', 'CheckPatch2'};
for index = 1:ind_opening
    set(handles.(ListOptions{index}),'value',0)
end
for index = ind_opening+1
    set(handles.(ListOptions{index}),'value',1)
end
update_CivOptions(handles)


%%  set the menus of image pairs and default selection for civ   %%%%%%%%%%%%%%%%%%%
test_ima_i=numel(nom_type_ima)>1 && isempty(regexp(nom_type_ima(2:end),'\D','once'));%images with single indexing
if test_ima_i || isequal(nom_type_nc,'_i1-i2')||~(exist('nbfield2','var')&&(nbfield2~=1))
    set(handles.ListPairMode,'Value',1)
    set(handles.ListPairMode,'String',{'series(Di)'})   
elseif (nbfield==1)% simple series in j
    set(handles.ListPairMode,'Value',1)
    set(handles.ListPairMode,'String',{'series(Dj)'})
else
    set(handles.ListPairMode,'String',{'pair j1-j2';'series(Dj)';'series(Di)'})%multiple choice
    if nbfield2 <= 10
        set(handles.ListPairMode,'Value',1)% advice 'pair j1-j2' for small burst
    end
end

%% update the subdirectory display
listot=dir(RootPath);%directory of RootPath
idir=0;
listdir={''};%default
% get the list of existing civ subdirectories in the path of theinput root  file
for ilist=1:length(listot)
    if listot(ilist).isdir
        name=listot(ilist).name;
        if ~isequal(name,'.') && ~isequal(name,'..')
            idir=idir+1;
            listdir{idir,1}=listot(ilist).name;
        end
    end
end
Value=find(strcmp(subdir,listdir));%search the index of subdir in the cell listdir
if isempty(Value)% if the input subdir is not found
    ValueCiv1=get(handles.ListSubdirCiv1,'Value');%read the currrently selected dir name
    if ValueCiv1>numel(listdir)
        ValueCiv1=1;
    end
    set(handles.txt_SubdirCiv1,'String',listdir{ValueCiv1})
    ValueCiv2=get(handles.ListSubdirCiv2,'Value');
    if ValueCiv2>numel(listdir)
        ValueCiv2=1;
    end
    set(handles.txt_SubdirCiv2,'String',listdir{ValueCiv2})
else
    ValueCiv1=Value;
    ValueCiv2=Value;
     set(handles.txt_SubdirCiv1,'String',listdir{Value})
     set(handles.txt_SubdirCiv2,'String',listdir{Value})
end
set(handles.ListSubdirCiv1,'Value',ValueCiv1)
set(handles.ListSubdirCiv2,'Value',ValueCiv2)
set(handles.ListSubdirCiv1,'String',[listdir;'new...'])
set(handles.ListSubdirCiv2,'String',[listdir;'new...'])
if isempty(listdir)
    set(handles.txt_SubdirCiv1,'String','CIV')
    set(handles.txt_SubdirCiv2,'String','CIV')
end

%% store info
browse.nom_type_ima=nom_type_ima;
set(handles.RootName,'UserData',browse)% store the nomenclature type

%% list the possible index pairs, depending on the option set in ListPairMode
ListPairMode_Callback([], [], handles)

%% store the root input filename for future opening
profil_perso=fullfile(prefdir,'uvmat_perso.mat');
% RootPath=fileparts(RootName);
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
set(handles.RootName,'BackgroundColor',[1 1 1])

%------------------------------------------------------------------------
% --- Executes on carriage return on the subdir checkciv1 edit window
function txt_SubdirCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
subdir=get(handles.txt_SubdirCiv1,'String');
menu_str=get(handles.ListSubdirCiv1,'String');% read the list of subdirectories for update
ichoice=find(strcmp(subdir,menu_str),1);
if isempty(ichoice)
    ilist=numel(menu_str); %select 'new...' in the menu
else
    ilist=ichoice;
end
set(handles.ListSubdirCiv1,'Value',ilist)% select the selected subdir in the menu
if get(handles.CheckCiv1,'Value')% if Civ1 is performed
    set(handles.txt_SubdirCiv2,'String',subdir);% set by default civ2 directory the same as civ1 
    set(handles.ListSubdirCiv2,'Value',ilist)
else % if Civ1 data already exist
    find_netcpair_civ1(handles); %update the list of available pairs from netcdf files in the new directory
end

%------------------------------------------------------------------------
% --- Executes on carriage return on the subdir checkciv1 edit window
function txt_SubdirCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
subdir=get(handles.txt_SubdirCiv1,'String');
menu_str=get(handles.ListSubdirCiv2,'String');% read the list of subdirectories for update
ichoice=find(strcmp(subdir,menu_str),1);
if isempty(ichoice)
    ilist=numel(menu_str); %select 'new...' in the menu
else
    ilist=ichoice;
end
set(handles.ListSubdirCiv2,'Value',ilist)% select the selected subdir in the menu
%update the list of available pairs from netcdf files in the new directory
if ~get(handles.CheckCiv2,'Value') && ~get(handles.CheckCiv1,'Value') && ~get(handles.CheckFix1,'Value') && ~get(handles.CheckPatch1,'Value')
    find_netcpair_civ2(handles);
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckCiv1.
function CheckCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles)

%------------------------------------------------------------------------
% --- Executes on button press in CheckFix1.
function CheckFix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles)

%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch1.
function CheckPatch1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles)

%------------------------------------------------------------------------
% --- Executes on button press in CheckCiv2.
function CheckCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles)

%------------------------------------------------------------------------
% --- Executes on button press in CheckFix2.
function CheckFix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles)

%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch2.
function CheckPatch2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles)

%------------------------------------------------------------------------
% --- activated by any checkbox controling the selection of Civ1,Fix1,Patch1,Civ2,Fix2,Patch2
function update_CivOptions(handles)
%------------------------------------------------------------------------
checkbox=zeros(1,6);
checkbox(1)=get(handles.CheckCiv1,'Value');
checkbox(2)=get(handles.CheckFix1,'Value');
checkbox(3)=get(handles.CheckPatch1,'Value');
checkbox(4)=get(handles.CheckCiv2,'Value');
checkbox(5)=get(handles.CheckFix2,'Value');
checkbox(6)=get(handles.CheckPatch2,'Value');
ind_selected=find(checkbox,1);
if ~isempty(ind_selected)
  RootName=get(handles.RootName,'String');
    if isempty(RootName)
         msgbox_uvmat('ERROR','Please open an image or PIV .nc file with the upper bar menu Open/Browse...')
        return
    end
end
set(handles.PairIndices,'Visible','on')
set(handles.txt_SubdirCiv1,'Visible','on')
set(handles.ListSubdirCiv1,'Visible','on')
find_netcpair_civ1(handles) % select the available netcdf files
if max(checkbox(4:6))% case of civ2 pair choice needed
    set(handles.TitlePairCiv2,'Visible','on')
    set(handles.TitleSubdirCiv2,'Visible','on')
    set(handles.txt_SubdirCiv2,'Visible','on')
    set(handles.ListSubdirCiv2,'Visible','on')
    set(handles.ListPairCiv2,'Visible','on')
    find_netcpair_civ2(handles) % select the available netcdf files
else
    set(handles.TitleSubdirCiv2,'Visible','off')
    set(handles.txt_SubdirCiv2,'Visible','off')
    set(handles.ListSubdirCiv2,'Visible','off')
    set(handles.ListPairCiv2,'Visible','off')
end
options={'Civ1','Fix1','Patch1','Civ2','Fix2','Patch2'};
for ilist=1:length(options)
    if checkbox(ilist)
        set(handles.(options{ilist}),'Visible','on')
    else
        set(handles.(options{ilist}),'Visible','off')
    end
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
elseif  isfield(handles,'status') %&& ~isequal(get(handles.ListPairMode,'Value'),3)
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
Param.CheckCiv1=get(handles.CheckCiv1,'Value');
Param.CheckFix1=get(handles.CheckFix1,'Value');
Param.CheckPatch1=get(handles.CheckPatch1,'Value');
Param.CheckCiv2=get(handles.CheckCiv2,'Value');
Param.CheckFix2=get(handles.CheckFix2,'Value');
Param.CheckPatch2=get(handles.CheckPatch2,'Value');
box_test=[Param.CheckCiv1 Param.CheckFix1 Param.CheckPatch1 Param.CheckCiv2 Param.CheckFix2 Param.CheckPatch2];

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
            Data=nc2struct(civ_files{ifile},'ListGlobalAttribute','CivStage','patch2','fix2','civ2','patch','fix');
            option_list={'civ1','fix1','patch1','civ2','fix2','patch2'};
            if ~isempty(Data.CivStage)
                option=Data.CivStage;
            else
                if ~isempty(Data.patch2) && isequal(Data.patch2,1)
                    option=6;
                    %                 option_str='patch2';
                elseif ~isempty(Data.fix2) && isequal(Data.fix2,1)
                    option=5;
                    %                 option_str='fix2';
                elseif ~isempty(Data.civ2) && isequal(Data.civ2,1);
                    option=4;
                    %                 option_str='civ2';
                elseif ~isempty(Data.patch) && isequal(Data.patch,1);
                    option=3;
                    %                 option_str='patch1';
                elseif ~isempty(Data.fix) && isequal(Data.fix,1);
                    option=2;
                    %                 option_str='fix1';
                else
                    option=1;
                    %                 option_str='civ1';
                end
            end
            option_str=option_list{option};
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
    if count<10||(nbfiles-count)<10
    pause(.5)% wait 0.5 seconds for next check
    else
        pause(10)% wait 10 seconds for next check
    end
end

%------------------------------------------------------------------------
% --- Main lauch command, called by RUN and BATCH
function errormsg=launch_jobs(hObject, eventdata, handles, batch)
%-----------------------------------------------------------------------
errormsg='';%default

%% read the input parameters from the  GUI civ
Param=read_GUI(handles.civ);

%% check the selected list of operations:
operations={'Civ1','Fix1','Patch1','Civ2','Fix2','Patch2'};
box_test=[Param.CheckCiv1 Param.CheckFix1 Param.CheckPatch1 Param.CheckCiv2 Param.CheckFix2 Param.CheckPatch2];
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
%could be included in get_mask callback ?
if isequal(get(handles.CheckMask,'Value'),1)
    maskname=get(handles.txt_Mask,'String');
    if ~exist(maskname,'file')
        get_mask_civ1_Callback(hObject, eventdata, handles);
    end
end
if isequal(get(handles.CheckMask,'Value'),1)
    maskname=get(handles.txt_Mask,'String');
    if ~exist(maskname,'file')
        get_mask_fix1_Callback(hObject, eventdata, handles);
    end
end
if isequal(get(handles.CheckMask,'Value'),1)
    maskname=get(handles.txt_Mask,'String');
    if ~exist(maskname,'file')
        get_mask_civ2_Callback(hObject, eventdata, handles);
    end
end
if isequal(get(handles.CheckMask,'Value'),1)
    maskname=get(handles.txt_Mask,'String');
    if ~exist(maskname,'file')
        get_mask_fix2_Callback(hObject, eventdata, handles);
    end
end

%% reinitialise status callback 
if isfield(handles,'status')
    set(handles.status,'Value',0);%suppress status display
    status_Callback(hObject, eventdata, handles)
end

%% read the PARAM.xml file to get the binaries (and batch_mode if batch)
path_civ=fileparts(which('civ')); %path to the source directory of uvmat
xmlfile='PARAM.xml';
if exist(xmlfile,'file')% search parameter xml file in the whole matlab path
    t=xmltree(xmlfile);
    s=convert(t);
else
    errormsg=['no file ' xmlfile];
    return
end
test_interp=0; %eviter les variables test_ (LG)
if batch
    if isfield(s,'BatchParam')
        Param.xml=s.BatchParam;
        if isfield(Param.xml,'BatchMode')
            batch_mode=Param.xml.BatchMode;
            if ~ismember(batch_mode,{'sge','oar'})
                errormsg=['batch mode ' batch_mode ' not supported by UVMAT'];
                return
            end
        end
    else
        errormsg='no batch civ binaries defined in PARAM.xml';
        return
    end
else % run
    if isfield(s,'RunParam')
        Param.xml=s.RunParam;
    else
        msgbox_uvmat('ERROR','no run civ binaries defined in PARAM.xml')
        return
    end
end

%% check batch mode supported
if batch
    switch batch_mode
        case 'sge'
            test_command='qstat';
        case 'oar'
            test_command='oarstat';
    end   
    [s,w]=system(test_command);
    if ~isequal(s,0)
        msgbox_uvmat('ERROR',[batch_mode ' batch system not available'])
        return
    end
end

%% check if the binaries exist
if isequal(get(handles.MenuMatlab,'checked'),'on')
    CivMode='Matlab';
else
    CivMode='CivX';
end
binary_list={};
switch CivMode
    case 'CivX'
        binary_list={'Civ1Bin','Civ2Bin','PatchBin','FixBin'};
    case 'CivAll'
        binary_list={'Civ'};
    case 'Matlab'
        if batch
            % vérifier MenuMatlab installé sur le cluster
            % difficile a faire a priori
        end          
end
for bin_name=binary_list %loop on the list of binaries
    if isfield(Param.xml,bin_name{1})% bin_name{1} =current name in the list
        if ~exist(Param.xml.(bin_name{1}),'file')%look for the full path if the file name has been defined with a relative path in PARAM.xml
            fullname=fullfile(path_civ,Param.xml.(bin_name{1}));
            if exist(fullname,'file')
                Param.xml.(bin_name{1})=fullname;
            else
                msgbox_uvmat('ERROR',['Binary ' Param.xml.(bin_name{1}) ' defined in PARAM.xml does not exist'])
                return
            end
        else
            [path,name,ext]=fileparts(Param.xml.(bin_name{1}));
            currentdir=pwd;
            cd(path);
            binpath=pwd;%path of the binary
            Param.xml.(bin_name{1})=fullfile(binpath,[name ext]);
            cd(currentdir);
        end
        
    end
end
display('files OK, processing...')

%% set the list of files and check them
display('checking the files...')
[ref_i,ref_j,errormsg]=find_ref_indices(handles);
if ~isempty(errormsg)
    return
end
[filecell,i1_civ1,i2_civ1,j1_civ1,j2_civ1,i1_civ2,i2_civ2,j1_civ2,j2_civ2,nom_type_nc,xx,yy,compare]=...
    set_civ_filenames(handles,ref_i,ref_j,box_test);
Rootbat=fileparts(filecell.nc.civ1{1,1});%output netcdf file (without extention)
set(handles.civ,'UserData',filecell);%store for futur use of status callback
if isempty(filecell)% (error message displayed in fct set_civ_filenames)
    return
end
nbfield=numel(i1_civ1);
nbslice=numel(j1_civ1);

%% MAIN LOOP
time=get(handles.ImaDoc,'UserData'); %get the set of times
batch_file_list=[];
 
for ifile=1:nbfield
    for j=1:nbslice
        % initiate system command
        switch CivMode
            case 'CivX'
                if isunix % check: necessaire aussi en RUN?
                    cmd=['#!/bin/bash \n '...
                        '#$ -cwd \n '...
                        'hostname && date \n '...
                        'umask 002 \n'];%allow writting access to created files for user group
                else
                    cmd=[];
                end
            case 'CivAll'
                CivAllxml=xmltree;% xml contents,  all parameters
                CivAllCmd='';
                CivAllxml=set(CivAllxml,1,'name','CivDoc');
        end
            
        % define output file name
        if Param.CheckCiv2==1 || Param.CheckFix2==1 || Param.CheckPatch2==1
            OutputFile=filecell.nc.civ2{ifile,j};
        else
            OutputFile=filecell.nc.civ1{ifile,j};
        end
        OutputFile=regexprep(OutputFile,'.nc','');
        
        if Param.CheckCiv1
            % read image-dependent parameters
            Param.Civ1.ImageA=filecell.ima1.civ1{ifile,j};
            Param.Civ1.ImageB=filecell.ima2.civ1{ifile,j};
            if size(time,1)>=i2_civ1(ifile) && size(time,2)>=j2_civ1(j)
                Param.Civ1.Dt=(time(i2_civ1(ifile),j2_civ1(j))-time(i1_civ1(ifile),j1_civ1(j)));
                Param.Civ1.Time=((time(i2_civ1(ifile),j2_civ1(j))+time(i1_civ1(ifile),j1_civ1(j)))/2);
            else
                Param.Civ1.Dt=1;
                Param.Civ1.Time=0;
            end
            Param.Civ1.term_a=num2stra(j1_civ1(j),nom_type_nc);%UTILITE?
            Param.Civ1.term_b=num2stra(j2_civ1(j),nom_type_nc);%    
            ImageInfo=imfinfo(filecell.ima1.civ1{1,1});%read the first image to get the size
            Param.Civ1.ImageWidth=ImageInfo.Width;
            Param.Civ1.ImageHeight=ImageInfo.Height;
            Param.Civ1.ImageBitDepth=ImageInfo.BitDepth;
            % read mask parameters
            if Param.Civ1.CheckMask % the lines below should be changed with the new gui
                if ~exist(Param.Civ1.Mask,'file')
                    maskbase=[filecell.filebase '_' Param.Civ1.Mask]; %
                    nbslice_mask=str2double(Param.Civ1.Mask(1:end-4)); %
                    i1_mask=mod(i1_civ1(ifile)-1,nbslice_mask)+1;
                    Param.Civ1.Mask=name_generator(maskbase,i1_mask,1,'.png','_i');
                end
            end
            % read grid parameters
            if Param.Civ1.CheckGrid
                if numel(Param.Civ1.Grid)>=4 && isequal(Param.Civ1.Grid(end-3:end),'grid')
                    nbslice_grid=str2double(Param.Civ1.Grid(1:end-4)); %
                    if ~isnan(nbslice_grid)
                        i1_grid=mod(i1_civ1(ifile)-1,nbslice_grid)+1;
                        Param.Civ1.Grid=[filecell.filebase '_' name_generator(Param.Civ1.Grid,i1_grid,1,'.grid','_i')];
                        if ~exist(Param.Civ1.GridName,'file')
                            msgbox_uvmat('ERROR','grid file absent for civ1')
                        end
                    elseif ~exist(Param.Civ1.Grid,'file')
                        msgbox_uvmat('ERROR','grid file absent for civ1')
                    end
                end
            end
            
            % send command
            switch CivMode
                case 'CivX'
                    cmd=[cmd...
                        cmd_civ1(filecell.nc.civ1{ifile,j},Param) '\n'];
                case 'CivAll'
                    CivAllCmd=[CivAllCmd ' civ1 '];
                    str=CIV1_CMD_Unified(filecell.nc.civ1{ifile,j},'',Param.Civ1);
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
        
        if Param.CheckFix1
            switch CivMode
                case 'CivX'
                    cmd=[cmd...
                        cmd_fix(filecell.nc.civ1{ifile,j},Param,'Fix1') '\n'];
                case 'CivAll'%to abandon
                    fix1.inputFileName=filecell.nc.civ1{ifile,j} ;
                    fix1.fi1=num2str(param.fix1.flagindex1(1));
                    fix1.fi2=num2str(param.fix1.flagindex1(2));
                    fix1.fi3=num2str(param.fix1.flagindex1(3));
                    fix1.threshC=num2str(param.fix1.thresh_vecC1);
                    fix1.threshV=num2str(param.fix1.thresh_vel1);
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
        
        %CheckPatch1
        if Param.CheckPatch1==1
            switch CivMode
                case 'CivX'
                    cmd=[cmd...
                        cmd_patch(filecell.nc.civ1{ifile,j},Param,'Patch1') '\n'];
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
                                i1_grid=mod(i1_civ1(ifile)-1,nbslice_grid)+1;
                                patch1.gridPatch=[filecell.filebase '_' name_generator(gridname,i1_grid,1,'.grid','_i')];
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
        if Param.CheckCiv2==1
            Param.Civ2.ImageA=filecell.ima1.civ2{ifile,j};
            Param.Civ2.ImageB=filecell.ima2.civ2{ifile,j};
            if size(time,1)>=i2_civ2(ifile) && size(time,2)>=j2_civ2(j)
                Param.Civ2.Dt=num2str(time(i2_civ2(ifile),j2_civ2(j))-time(i1_civ2(ifile),j1_civ2(j)));
                Param.Civ2.Time=num2str((time(i2_civ2(ifile),j2_civ2(j))+time(i1_civ2(ifile),j1_civ2(j)))/2);
            else
                Param.Civ2.Dt=1;
                Param.Civ2.Time=0;
            end
            Param.Civ2.term_a=num2stra(j1_civ2(j),nom_type_nc);
            Param.Civ2.term_b=num2stra(j2_civ2(j),nom_type_nc);
            Param.Civ2.filename_nc1=filecell.nc.civ1{ifile,j};
            Param.Civ2.filename_nc1(end-2:end)=[]; % remove '.nc'
            
            % mask 
            if Param.Civ2.CheckMask
                if ~exist(Param.Civ2.Mask,'file')
                    maskbase=[filecell.filebase '_' Param.Civ2.Mask]; %
                    nbslice_mask=str2double(Param.Civ2.Mask(1:end-4)); %
                    i1_mask=mod(i1_civ2(ifile)-1,nbslice_mask)+1;
                    Param.Civ2.Mask=name_generator(maskbase,i1_mask,1,'.png','_i');
                end
            end
            %grid
            if Param.Civ2.CheckGrid
                if numel(Param.Civ2.Grid)>=4 && isequal(Param.Civ2.Grid(end-3:end),'grid')
                    nbslice_grid=str2double(Param.Civ2.Grid(1:end-4)); %
                    if ~isnan(nbslice_grid)
                        i1_grid=mod(i1_civ2(ifile)-1,nbslice_grid)+1;
                        Param.Civ2.Grid=[filecell.filebase '_' name_generator(gridname,i1_grid,1,'.grid','_i')];
                    end
                end
            end
            ImageInfo=imfinfo(filecell.ima1.civ2{1,1});%read the first image to get the size
            Param.Civ2.ImageWidth=ImageInfo.Width;
            Param.Civ2.ImageHeight=ImageInfo.Height;
            Param.Civ2.ImageBitDepth=ImageInfo.BitDepth;
            % TODO: case of movie   
            switch CivMode
                case 'CivX'
                    cmd=[cmd...
                        cmd_civ2(filecell.nc.civ2{ifile,j},Param) '\n'];
                case 'CivAll'
                    CivAllCmd=[CivAllCmd ' civ2 '];
                    str=CIV2_CMD_Unified(filecell.nc.civ2{ifile,j},'',Param.Civ2);
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
        
        % CheckFix2
        if Param.CheckFix2==1
            switch CivMode
                case 'CivX'
                    cmd=[cmd...
                        cmd_fix(filecell.nc.civ2{ifile,j},Param,'Fix2') '\n'];
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
        
        %CheckPatch2
        if Param.CheckPatch2==1
            
            switch CivMode
                
                case 'CivX'
                    cmd=[cmd...
                        cmd_patch(filecell.nc.civ1{ifile,j},Param,'Patch2') '\n'];
                    
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
                                i1_grid=mod(i1_civ2(ifile)-1,nbslice_grid)+1;
                                patch2.gridPatch=[filecell.filebase '_' name_generator(gridname,i1_grid,1,'.grid','_i')];
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
                    save(CivAllxml,[OutputFile '.xml']);
                    cmd=[cmd sparam.CivBin ' -f ' OutputFile '.xml '  CivAllCmd ' >' OutputFile '.log' '\n'];
                end             
                % create the .bat file used in run or batch
                filename_bat=[OutputFile '.bat'];
                [fid,message]=fopen(filename_bat,'w');
                if isequal(fid,-1)
                    msgbox_uvmat('ERROR', ['creation of .bat file: ' message])
                    return
                end
                fprintf(fid,cmd);
                fclose(fid);            
                if isunix
                    system(['chmod +x ' filename_bat]);
                end             
                batch_file_list{length(batch_file_list)+1}=filename_bat;
                
            case 'Matlab'
                drawnow
                if ~strcmp(compare,'stereo PIV')
                    [Data,erromsg]=civ_matlab(Param,filecell.nc.civ1{ifile,j});
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
        case 'oar_old'
                for p=1:length(batch_file_list)
                    oar_command=['!oarsub -n CIVX -q nicejob '...
                   '-E ' regexprep(batch_file_list{p},'.bat','.errors') ' -O ' regexprep(batch_file_list{p},'.bat','.log ')...
                    '-l "/core=1+{type = ''smalljob''}/licence=1,walltime=00:60:00"   ' batch_file_list{p}];
                display(oar_command);eval(oar_command);
                end                
        case 'oar'
            
            oar_modes={'oar-dispatch','mpilauncher'};
            text={'Batch processing on servcalcul3 LEGI';...
                'Please choose one of the followint modes';...
                '* oar-dispatch : jobs in a container';...
                '* mpilauncher : one single job using several cores';...
                '**********************************'...
                };
            [S,v]=listdlg('PromptString',text,'ListString',oar_modes,...
                'SelectionMode','single','ListSize',[400 100],'Name','LEGI job mode');
            switch oar_modes{S}
                
                case 'oar-dispatch' %oar-dispatch.pl
                    filename_joblist=fullfile(Rootbat,'job_list.txt');
                    fid=fopen(filename_joblist,'w');
                    walltime_onejob=600;%seconds
                    for p=1:length(batch_file_list)
                        oar_command=['oarsub -n CIVX '...
                            '-E ' regexprep(batch_file_list{p},'\.bat\>','.errors') ' -O ' regexprep(batch_file_list{p},'\.bat\>','.log ')...
                            '-l "/core=1,walltime=' datestr(walltime_onejob/86400,13) '"   ' batch_file_list{p}];
                        fprintf(fid,[oar_command '\n']);
                    end
                    fclose(fid);
                    ncores=36;
                    oar_command=['oarsub -t container -n civx-container '...
                        '-l /core=' num2str(ncores)...
                        ',walltime=' datestr(1.05*walltime_onejob/86400*max(length(batch_file_list),ncores)/ncores,13)...
                        ' "oar-dispatch -f ' filename_joblist '"'];
                    filename_oarcommand=fullfile(Rootbat,'oar_command');
                    fid=fopen(filename_oarcommand,'w');
                    fprintf(fid,[oar_command '\n']);
                    fclose(fid);
                    display(oar_command);
                    eval(['! . ' filename_oarcommand])
                case 'mpilauncher'
                    filename_joblist=fullfile(Rootbat,'job_list.txt');
                    fid=fopen(filename_joblist,'w');
                    
                    for p=1:length(batch_file_list)
                        fprintf(fid,[batch_file_list{p} '\n']);
                    end
                    fclose(fid)
                    text_oarscript=[...
                        '#!/bin/bash \n'...
                        '#OAR -n Mylauncher \n'...
                        '#OAR -l node=4/core=5,walltime=0:15:00 \n'...
                        '#OAR -E stderrfile.log \n'...
                        '#OAR -O stdoutfile.log \n'...
                        '# ========================================================= \n'...
                        '# This simple program launch a multinode parallel OpenMPI mpilauncher \n'...
                        '# application for coriolis PIV post-processing. \n'...
                        '# OAR uses oarshmost wrapper to propagate the user environement. \n'...
                        '# This wrapper assert that the user has the same environment on all the \n'...
                        '# allocated nodes (basic behavior needed by most MPI applications).  \n'...
                        '# \n'...
                        '# REQUIREMENT: \n'...
                        '# the oarshmost wrapper should be installed in $HOME/bin directory. \n'...
                        '# If a different location is used, change the line following the comment "Bidouille" \n'...
                        '# ========================================================= \n'...
                        '#   USER should only modify these 2 lines  \n'...
                        'WORKDIR=' pwd ' \n'...
                        'COMMANDE="mpilauncher  -f ' filename_joblist '" \n'...
                        '# ========================================================= \n'...
                        '# DO NOT MODIFY the FOLOWING LINES. (or be carefull) \n'...
                        'echo "job starting on: "`hostname` \n'...
                        'MPINODES="-host `tr [\\\\\\n] [,] <$OAR_NODEFILE |sed -e "s/,$/ /"`" \n'...
                        'NCPUS=`cat $OAR_NODEFILE |wc -l` \n'...
                        '#========== Bidouille ============== \n'...
                        'export OMPI_MCA_plm_rsh_agent=oar-envsh \n'...%                     'cd $WORKDIR \n'...
                        'CMD="mpirun -np $NCPUS -wdir $WORKDIR $MPINODES $COMMANDE" \n'...
                        'echo "I run: $CMD"  \n'...
                        '$CMD \n'...
                        'echo "job ending" \n'...
                        ];
                    %                 oarsub -S ./oar.sub
                    filename_oarscript=fullfile(Rootbat,'oar_command');
                    fid=fopen(filename_oarscript,'w');
                    fprintf(fid,[text_oarscript]);
                    fclose(fid);
                    eval(['!chmod +x  ' filename_oarscript]);
                    eval(['!oarsub -S ' filename_oarscript]);
            end
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

%Save info in personal profile (initiate browser next time) TODO
MenuFile={};
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    hh=load (profil_perso);
      if isfield(hh,'MenuFile')
          MenuFile=hh.MenuFile;
      end
      if isfield(filecell.nc,'civ2')
          MenuFile=[filecell.nc.civ2{1,1}; MenuFile];
      else
           MenuFile=[filecell.nc.civ1{1,1}; MenuFile];
      end
      save (profil_perso,'MenuFile','-append'); %store the file names for future opening of uvmat
else
    MenuFile=filecell.ima1.civ1(1,1);
    save (profil_perso,'MenuFile')
end

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
    set_civ_filenames(handles,ref_i,ref_j,checkbox)
%------------------------------------------------------------------------
filecell=[];%default

%% get the root names nomenclature and numbers
filebase=get(handles.RootName,'String');

if isempty(filebase)||isequal(filebase,'')
    msgbox_uvmat('ERROR','please open an image with the upper menu option Open/Browse...')
    return
end

%filebase=regexprep(filebase,'\.fsnet','fsnet');% temporary fix for cluster Coriolis
filecell.filebase=filebase;

browse=get(handles.RootName,'UserData');
compare_list=get(handles.ListCompareMode,'String');
val=get(handles.ListCompareMode,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')
    mode='displacement';
else
    mode_list=get(handles.ListPairMode,'String');
    mode_value=get(handles.ListPairMode,'Value');
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
%determine the new filebase for 'displacement' ListPairMode (comparison of two series)
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
if checkbox(2)==1% fix1 performed
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

%determine reference files for checkfix2:
if checkbox(5)==1% fix2 performed
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
subdir_civ1=get(handles.txt_SubdirCiv1,'String');%subdirectory subdir_civ1 for the netcdf output data
subdir_civ2=get(handles.txt_SubdirCiv2,'String');
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
% %%%%%%%%%%%%  case CheckCiv1 activated   %%%%%%%%%%%%%
if checkbox(1)==1;
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
  
        %create the new txt_SubdirCiv1
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
            %create the new txt_SubdirCiv1
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
    
    %%%%%%%%%%%%%  checkfix1 or checkpatch1 activated but no checkciv1   %%%%%%%%%%%%%
elseif (checkbox(2)==1 || checkbox(3)==1);
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

%%%%%%%%%%%%%  if checkciv2 performed with pairs different than checkciv1  %%%%%%%%%%%%%
testdiff=0;
if (checkbox(4)==1)&&...
        ((get(handles.ListPairCiv1,'Value')~=get(handles.ListPairCiv2,'Value'))||~strcmp(subdir_civ2,subdir_civ1))
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
            %create the new txt_SubdirCiv1
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

%%%%%%%%%%%%%  if checkciv2 results are obtained or used  %%%%%%%%%%%%%
if checkbox(4)==1 || checkbox(5)==1 || checkbox(6)==1 %civ2
    %check source netcdf file of checkciv1 estimates
    if checkbox(1)==0; %no civ1 performed
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
                    if checkbox(4)==0 ; %check the existence of civ2 if it is not calculated
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
                    elseif checkbox(3)==0; %check the existence of patch if it is not calculated
                        Data=nc2struct(filename,'ListGlobalAttribute','CivStage','patch');
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
    %     while detect==1%creates a new subdir if the netcdf files already contain checkciv2 data
    for ifile=1:nbfield
        for j=1:nbslice
            filename=name_generator(filebase_nc,num1_civ2(ifile),num_a_civ2(j),'.nc',...
                nom_type_nc,1,num2_civ2(ifile),num_b_civ2(j),subdir_civ2);
            detect=exist(filename,'file')==2;
            filecell.nc.civ2(ifile,j)={filename};
        end
    end
    %get first image names for checkciv2
    if checkbox(1)==1 && isequal(num1_civ1,num1_civ2) && isequal(num_a_civ1,num_a_civ2)
        filecell.ima1.civ2=filecell.ima1.civ1;
    elseif checkbox(4)==1
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
    
    %get second image names for checkciv2
    if checkbox(1)==1 && isequal(num2_civ1,num2_civ2) && isequal(num_b_civ1,num_b_civ2)
        filecell.ima2.civ2=filecell.ima2.civ1;
    elseif checkbox(4)==1
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
if (checkbox(5) || checkbox(6)) && ~checkbox(4)  % need to read an existing netcdf civ2 file
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
    if  checkbox(3) && isequal(get(handles.test_stereo1,'Value'),1)
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_AB,num1_civ1(ifile),num_a_civ1(j),'.nc',...
                    nom_type_nc,1,num2_civ1(ifile),num_b_civ1(j),subdir_civ1);%
                filecell.st(ifile,j)={filename};
            end
        end
    end
    if  checkbox(6) && isequal(get(handles.CheckStereo,'Value'),1)
        for ifile=1:nbfield
            for j=1:nbslice
                filename=name_generator(filebase_AB,num1_civ2(ifile),num_a_civ2(j),'.nc',...
                    nom_type_nc,1,num2_civ2(ifile),num_b_civ2(j),subdir_civ2);%
                filecell.st(ifile,j)={filename};
            end
        end
    end
end
set(handles.txt_SubdirCiv1,'String',subdir_civ1);%update the edit box
set(handles.txt_SubdirCiv2,'String',subdir_civ2);%update the edit box
browse.nom_type_nc=nom_type_nc;
set(handles.RootName,'UserData',browse); %update the nomenclature type for uvmat


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
    if checkbox(1) %if civ1 is performed
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
    if checkbox(4) %if civ2 is performed
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

list_civ1=get(handles.ListPairCiv1,'String');
index_civ1=get(handles.ListPairCiv1,'Value');
str_civ1=list_civ1{index_civ1};%string defining the image pairs for civ1
if isempty(str_civ1)||isequal(str_civ1,'')
    msgbox_uvmat('ERROR','no image pair selected for civ1')
    return
end
list_civ2=get(handles.ListPairCiv2,'String');
index_civ2=get(handles.ListPairCiv2,'Value');
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
    displ_num=get(handles.ListPairCiv1,'UserData');
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
% --- Executes on button press in ListCompareMode.
function ListCompareMode_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
test=get(handles.ListCompareMode,'Value');
if test==2 || test==3 % case 'dispalcemen' or 'stereo PIV'
    filebase=get(handles.RootName,'String');
    browse=get(handlesRootName,'Userdata');
    browse.nom_type_ima1=browse.nom_type_ima;
    set(handlesRootName,'UserData',browse);
    set(handles.sub_txt,'Visible','on')
    set(handles.RootName_1,'Visible','On');%mkes the second file input window visible
    mode_store=get(handles.ListPairMode,'String');%get the present 'mode'
    set(handles.ListCompareMode,'UserData',mode_store);%store the mode display
    set(handles.ListPairMode,'Visible','off')
    if test==2
        set(handles.ListPairMode,'Visible','off')
        set(handles.ListPairMode,'Value',1) % mode 'civX' selected by default
    else
        set(handles.ListPairMode,'Visible','on')
        set(handles.ListPairMode,'Value',3) % mode 'Matlab' selected for stereo 
    end
    
    %% menuopen an image file with the browser
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
    [path,name,ext]=fileparts(fileinput);
    [path1]=fileparts(filebase);
    if isunix
        [status,path]=system(['readlink ' path]);
        [status,path1]=system(['readlink ' path1]);% look for the true path in case of symbolic paths
    end
    if ~strcmp(path1,path)
        msgbox_uvmat('ERROR','The second image series must be in the same directory as the first one')
        return
     end
%     set(handles.RootName_1,'String',name);
    [RootPath,RootFile,field_count,str2,str_a,str_b,xx,nom_type,subdir]=name2display(name);
    set(handles.RootName_1,'String',RootFile);
    browse=get(handlesRootName,'UserData');
    browse.nom_type_ima_1=nom_type;
    set(handlesRootName,'UserData',browse)
    
    %check image extension
    if ~strcmp(ext,get(handles.ImaExt,'String'))
        msgbox_uvmat('ERROR','The second image series must have the same extension name as the first one')
        return
    end
    
    %% check coincidence of image sizes
%     ref_i=get(handles.ref_i,'string');
%     ref_j=get(handles.ref_j,'string');
%     [filecell,num1_civ1,num2_civ1,num_a_civ1,num_b_civ1,num1_civ2,num2_civ2,num_a_civ2,num_b_civ2,nom_type_nc]=set_civ_filenames(handles,ref_i,ref_j,[1 0 0 0 0 0]);
%     A=imread(filecell.ima1.checkciv1{1});
%     A_1=imread(fileinput);
%     npxy=size(A);
%     npxy_1=size(A_1);
%     if ~isequal(size(A),size(A_1))
%         msgbox_uvmat('ERROR','The two input image series do not have the same size')
%         return
%     end
else
    set(handles.ListPairMode,'Visible','on')
    set(handles.RootName_1,'Visible','Off');
    set(handles.sub_txt,'Visible','off')
    set(handles.RootName_1,'String',[]);
    mode_store=get(handles.ListCompareMode,'UserData');
    set(handles.ListPairMode,'Value',1)
    set(handles.ListPairMode,'String',mode_store)
    set(handles.test_stereo1,'Value',0)
    set(handles.CheckStereo,'Value',0)
    set(handles.ListPairMode,'Value',1) % mode 'civX' selected by default
end
if test==3 && get(handles.CheckPatch1,'Value')
    set(handles.test_stereo1,'Visible','on')
else
    set(handles.test_stereo1,'Visible','off')
end
if test==3 && get(handles.CheckPatch2,'Value')
    set(handles.CheckStereo,'Visible','on')
else
    set(handles.CheckStereo,'Visible','off')
end
mode_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Pair Indices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in ListPairMode.
function ListPairMode_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
compare_list=get(handles.ListCompareMode,'String');
val=get(handles.ListCompareMode,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')
    mode='displacement';
else
    mode_list=get(handles.ListPairMode,'String');
    if ischar(mode_list)
        mode_list={mode_list};
    end
    mode_value=get(handles.ListPairMode,'Value');
    mode=mode_list{mode_value};
end
displ_num=[];%default
ref_i=str2double(get(handles.ref_i,'String'));
% last_i=str2num(get(handles.last_i,'String'));
time=get(handles.ImaDoc,'UserData'); %get the set of times
siztime=size(time);
nbfield=siztime(1);
nbfield2=siztime(2);
indchosen=1;  %%first pair selected by default
%displ_num used to define the indices of the civ pairs
% in mode 'pair j1-j2', j1 and j2 are the file indices, else the indices
% are relative to the reference indices ref_i and ref_j respectively.
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
    index=1:200;
    displ_num(1,index)=-floor(index/2);
    displ_num(2,index)=ceil(index/2);
    displ_num(3:4,index)=zeros(2,200);
%     for index=1:min(nbfield2-1,200)
%         displ_num(1,index)=-floor(index/2);
%         displ_num(2,index)=ceil(index/2);
%         displ_num(3,index)=0;
%         displ_num(4,index)=0;
%     end
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
    index=1:200;
    displ_num(1:2,index)=zeros(2,200);
    displ_num(3,index)=-floor(index/2);
    displ_num(4,index)=ceil(index/2);
%     for index=1:200%min(nbfield-1,200)
%         displ_num(1,index)=0;
%         displ_num(2,index)=0;
%         displ_num(3,index)=-floor(index/2);
%         displ_num(4,index)=ceil(index/2);
%     end
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
set(handles.ListPairCiv1,'UserData',displ_num);
find_netcpair_civ1( handles)
find_netcpair_civ2(handles)

%------------------------------------------------------------------------
% --- Executes on selection change in ListPairCiv1.
function ListPairCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%reproduce by default the chosen pair in the checkciv2 menu
list_pair=get(handles.ListPairCiv1,'String');%get the menu of image pairs
index_pair=get(handles.ListPairCiv1,'Value');
displ_num=get(handles.ListPairCiv1,'UserData');
% num_a=displ_num(1,index_pair);
% num_b=displ_num(2,index_pair);
list_pair2=get(handles.ListPairCiv2,'String');%get the menu of image pairs
if index_pair<=length(list_pair2)
    set(handles.ListPairCiv2,'Value',index_pair);
end

%update first_i and last_i according to the chosen image pairs
mode_list=get(handles.ListPairMode,'String');
mode_value=get(handles.ListPairMode,'Value');
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
% --- Executes on selection change in ListPairCiv2.
function ListPairCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index_pair=get(handles.ListPairCiv2,'Value');%get the selected position index in the menu

%update first_i and last_i according to the chosen image pairs
mode_list=get(handles.ListPairMode,'String');
mode_value=get(handles.ListPairMode,'Value');
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
function ref_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.ListPairMode,'String');
mode_value=get(handles.ListPairMode,'Value');
mode=mode_list{mode_value};
find_netcpair_civ1(handles);% update the menu of pairs depending on the available netcdf files
if isequal(mode,'series(Di)') || ...% we do patch2 only
        (get(handles.CheckCiv2,'Value')==0 && get(handles.CheckCiv1,'Value')==0 && get(handles.CheckFix1,'Value')==0 && get(handles.CheckPatch1,'Value')==0)
    find_netcpair_civ2( handles);
end

%------------------------------------------------------------------------
function ref_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.ListPairMode,'String');
mode_value=get(handles.ListPairMode,'Value');
mode=mode_list{mode_value};
if isequal(get(handles.CheckCiv1,'Value'),0)|| isequal(mode,'series(Dj)')
    find_netcpair_civ1(handles);% update the menu of pairs depending on the available netcdf files
end
if isequal(mode,'series(Dj)') || ...
        (get(handles.CheckCiv2,'Value')==0 && get(handles.CheckCiv1,'Value')==0 && get(handles.CheckFix1,'Value')==0 && get(handles.CheckPatch1,'Value')==0)
    find_netcpair_civ2(handles);
end
% 
%------------------------------------------------------------------------
% determine the menu for checkciv1 pairs depending on existing netcdf file at the middle of
% the field series set by first_i, incr, last_i
function find_netcpair_civ1(handles)
%------------------------------------------------------------------------
set(gcf,'Pointer','watch')
%nomenclature types
filebase=get(handles.RootName,'String');
[filepath,Nme,ext_dir]=fileparts(filebase);
browse=get(handles.RootName,'UserData');
compare_list=get(handles.ListCompareMode,'String');
val=get(handles.ListCompareMode,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')
    mode='displacement';
else
    mode_list=get(handles.ListPairMode,'String');
    mode_value=get(handles.ListPairMode,'Value');
    if isempty(mode_list)
        return
    end
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
set(handles.RootName,'UserData',browse)

%reads .nc subdirectoy and image numbers from the interface
subdir_civ1=get(handles.txt_SubdirCiv1,'String');%subdirectory subdir_civ1 for the netcdf data
ref_i=str2double(get(handles.ref_i,'String'));
if isequal(mode,'pair j1-j2')%|isequal(mode,'st_pair j1-j2')
    ref_j=0;
else
    ref_j=str2double(get(handles.ref_j,'String'));
end
time=get(handles.ImaDoc,'UserData');%get the set of times
if isempty(time)
    time=[0 1];
end
dt_unit=1000;%default
displ_num=get(handles.ListPairCiv1,'UserData');

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

%look for existing processed pairs involving the field at the middle of the series if checkciv1 will not
% be performed, while the result is needed for next steps.
displ_pair={''};
select=ones(size(1:nbpair));%flag for displayed pairs =1 for display
testpair=0;

%% case with no Civ1 operation, netcdf files need to exist for reading
if ~get(handles.CheckCiv1,'Value') %
    if ~exist(fullfile(filepath,subdir_civ1,ext_dir),'dir')
        msgbox_uvmat('ERROR',['no civ1 file available: subdirectory ' subdir_civ1 ' does not exist']);
        set(handles.ListPairCiv1,'String',{});
        return
    end
    for ipair=1:nbpair
        filename=name_generator(filebase,ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair),'.nc',nom_type_nc,1,...
            ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair),subdir_civ1);
        select(ipair)=exist(filename,'file')==2;% put flag to 0 if the file does not exist
    end   
    % case of no displayed pair
    if isequal(select,zeros(size(1:nbpair)))
        if isfield(browse,'incr_pair') && ~isequal(browse.incr_pair,[0 0])
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
            set(handles.ListPairCiv1,'String',{''});
            %COMPLETER CAS STEREO
            return
        end
    end
end

%% determine the menu display in .ListPairCiv1
% the menu depends on the mode defined in ListPairMode_callback through the array displ_num:
% displ_num(1,:)=indices j1
% displ_num(2,:)=indices j2
% displ_num(3,:)=indices i1
% displ_num(4,:)=indices i2
% in mode 'pair j1-j2', j1 and j2 are the file indices, else the indices
% are relative to the reference indices ref_i and ref_j respectively.
if isequal(mode,'series(Di)')
    if testpair
        displ_pair{1}=['Di= ' num2str(-floor(browse.incr_pair(1)/2)) '|' num2str(ceil(browse.incr_pair(1)/2))];
    else
        for ipair=1:nbpair
            if select(ipair)
                displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2))];
                if size(time,1)>=ref_i+displ_num(4,ipair) && size(time,2)>=ref_j+displ_num(2,ipair)
                    dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
                    displ_pair{ipair}=[displ_pair{ipair} ' :dt= ' num2str(dt*1000)];
                end
            else
                displ_pair{ipair}='...'; %pair not displayed in the menu
            end
        end
    end
elseif isequal(mode,'series(Dj)')
    if testpair
        displ_pair{1}=['Dj= ' num2str(-floor(browse.incr_pair(1)/2)) '|' num2str(ceil(browse.incr_pair(1)/2))];
    else
        for ipair=1:nbpair
            if select(ipair)
                displ_pair{ipair}=['Dj= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2))];
                if size(time,1)>=ref_i+displ_num(4,ipair) && size(time,2)>=ref_j+displ_num(2,ipair)
                    dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
                    displ_pair{ipair}=[displ_pair{ipair} ' :dt= ' num2str(dt*1000)];
                end
            else
                displ_pair{ipair}='...'; %pair not displayed in the menu
            end
        end
    end
elseif isequal(mode,'pair j1-j2')%case of pairs
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
set(handles.ListPairCiv1,'String',displ_pair');

%% determine the default selection in the pair menu
ichoice=find(select,1);% index of selected pair
if (isempty(ichoice) || ichoice < 1); ichoice=1; end;
initial=get(handles.ListPairCiv1,'Value');%initial choice of pair
if initial>nbpair || (numel(select)>=initial && ~isequal(select(initial),1))
    set(handles.ListPairCiv1,'Value',ichoice);% first valid pair proposed by default in the menu
end
initial=get(handles.ListPairCiv2,'Value');
if initial>length(displ_pair')%|~isequal(select(initial),1)
    if ichoice <= length(displ_pair')
        set(handles.ListPairCiv2,'Value',ichoice);% same pair proposed by default for civ2
    else
        set(handles.ListPairCiv2,'Value',1);% same pair proposed by default for civ2
    end
end
set(handles.ListPairCiv2,'String',displ_pair');
set(gcf,'Pointer','arrow')

%------------------------------------------------------------------------
% determine the menu for checkciv2 pairs depending on the existing netcdf file at the
%middle of the series set by first_i, incr, last_i
function find_netcpair_civ2(handles)
%------------------------------------------------------------------------
set(gcf,'Pointer','watch')
%nomenclature types
filebase=get(handles.RootName,'String');
[filepath,Nme,ext_dir]=fileparts(filebase);
browse=get(handles.RootName,'UserData');
compare_list=get(handles.ListCompareMode,'String');
val=get(handles.ListCompareMode,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')
    mode='displacement';
else
    mode_list=get(handles.ListPairMode,'String');
    if isempty(mode_list)
        msgbox_uvmat('ERROR','please enter an input image or netcdf file')
        return
    end
    mode_value=get(handles.ListPairMode,'Value');
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
set(handles.RootName,'UserData',browse)

%reads .nc subdirectory and image numbers from the interface
subdir_civ1=get(handles.txt_SubdirCiv1,'String');%subdirectory subdir_civ1 for the netcdf data
subdir_civ2=get(handles.txt_SubdirCiv2,'String');%subdirectory subdir_civ2 for the netcdf data
ref_i=str2double(get(handles.ref_i,'String'));
if isequal(mode,'pair j1-j2')%|isequal(mode,'st_pair j1-j2')
    ref_j=0;
else
    ref_j=str2double(get(handles.ref_j,'String'));
end
time=get(handles.ImaDoc,'UserData'); %get the set of times
if isempty(time)
    time=[0 1];%default
end
displ_num=get(handles.ListPairCiv1,'UserData');

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

%% look for existing processed pairs at the reference indices if Civ1 will not
% be performed, while the result is needed for next steps.
displ_pair={''}; %default
select=ones(size(1:nbpair));%default =1 for numbers of displayed pairs
if ~get(handles.CheckCiv2,'Value') && ~get(handles.CheckCiv1,'Value') && ~get(handles.CheckFix1,'Value') && ~get(handles.CheckPatch1,'Value')
    if ~exist(fullfile(filepath,subdir_civ2,ext_dir),'dir')
        errordlg(['no civ2 file available: subdirectory ' subdir_civ2 ' does not exist'])
        set(handles.ListPairCiv2,'Value',1);
        set(handles.ListPairCiv2,'String',{''});
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
            set(handles.ListPairCiv2,'Value',1);
            set(handles.ListPairCiv2,'String',{''});
            return
        end
    end
end
if isequal(mode,'series(Di)') 
    for ipair=1:nbpair
        if select(ipair)
            displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ];
            if size(time,1)>=ref_i+displ_num(4,ipair) && size(time,2)>=ref_j+displ_num(2,ipair)
                dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
                displ_pair{ipair}=[displ_pair{ipair} ' :dt= ' num2str(dt*1000)];
            end
        else
            displ_pair{ipair}='...'; %pair not displayed in the menu
        end
    end
elseif isequal(mode,'series(Dj)') %| isequal(mode,'st_series(Dj)') % series on the j index
    for ipair=1:nbpair
        if select(ipair)
            displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2)) ];
            if size(time,1)>=ref_i+displ_num(4,ipair) && size(time,2)>=ref_j+displ_num(2,ipair)
                dt=time(ref_i+displ_num(4,ipair),ref_j+displ_num(2,ipair))-time(ref_i+displ_num(3,ipair),ref_j+displ_num(1,ipair));%time interval dt
                displ_pair{ipair}=[displ_pair{ipair} ' :dt= ' num2str(dt*1000)];
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
val=get(handles.ListPairCiv2,'Value');
ichoice=find(select,1);
if (isempty(ichoice) || ichoice < 1); ichoice=1; end;
if get(handles.CheckCiv2,'Value')==0 && get(handles.CheckCiv1,'Value')==0 && get(handles.CheckFix1,'Value')==0 && get(handles.CheckPatch1,'Value')==0
    val=ichoice;% first valid pair proposed by default in the menu
end
if val>length(displ_pair')
    set(handles.ListPairCiv2,'Value',1);% first valid pair proposed by default in the menu
else
    set(handles.ListPairCiv2,'Value',val);
end
set(handles.ListPairCiv2,'String',displ_pair');
set(gcf,'Pointer','arrow')

%-------------------------------------------------------------------
% --- 
function closeview_field(gcbo,eventdata)
hview_field=findobj(allchild(0),'tag','view_field');% look for view_field    
    if ~isempty(hview_field)
        delete(hview_field)
    end
    
    
%------------------------------------------------------------------------   
% call 'view_field.fig' to display the  field selected in the list of 'status'
function open_view_field(hObject, eventdata)
%------------------------------------------------------------------------
list=get(hObject,'String');
index=get(hObject,'Value');
rootroot=get(hObject,'UserData');
filename=list{index};
ind_dot=strfind(filename,'...');
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Reference Indices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
function first_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
first_i=str2double(get(handles.first_i,'String'));
set(handles.ref_i,'String', num2str(first_i))% reference index for pair dt = first index
ref_i_Callback(hObject, eventdata, handles)%refresh dispaly of dt for pairs (in case of non constant dt)

%------------------------------------------------------------------------
function first_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
first_j=str2num(get(handles.first_j,'String'));
set(handles.ref_j,'String', num2str(first_j))% reference index for pair dt = first index
ref_j_Callback(hObject, eventdata, handles)%refresh dispaly of dt for pairs (in case of non constant dt)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Civ1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in SearchRange: determine the search range num_Searchx,num_Searchy
function SearchRange_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%determine pair numbers
if strcmp(get(handles.umin,'Visible'),'off')
    set(handles.u_title,'Visible','on')
    set(handles.v_title,'Visible','on')
    set(handles.umin,'Visible','on')
    set(handles.umax,'Visible','on')
    set(handles.vmin,'Visible','on')
    set(handles.vmax,'Visible','on')
    set(handles.CoordUnit,'Visible','on')
    set(handles.TimeUnit,'Visible','on')
    set(handles.slash_title,'Visible','on')
    set(handles.min_title,'Visible','on')
    set(handles.max_title,'Visible','on')
    set(handles.unit_title,'Visible','on')
else
    get_search_range(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% ---  determine the search range num_Searchx,num_Searchy and shift
function get_search_range(hObject, eventdata, handles)
umin=str2double(get(handles.umin,'String'));
umax=str2double(get(handles.umax,'String'));
vmin=str2double(get(handles.umin,'String'));
vmax=str2double(get(handles.vmax,'String'));
%switch min_title and max_title in case of error
if umax<=umin
    umin_old=umin;
    umin=umax;
    umax=umin_old;
    set(handles.umin,'String', num2str(umin))
    set(handles.umax,'String', num2str(umax))
end
if vmax<=vmin
    vmin_old=vmin;
    vmin=vmax;
    vmax=vmin_old;
    set(handles.vmin,'String', num2str(vmin))
    set(handles.vmax,'String', num2str(vmax))
end   
if ~(isnan(umin)||isnan(umax)||isnan(vmin)||isnan(vmax))
    list_pair=get(handles.ListPairCiv1,'String');%get the menu of image pairs
    index=get(handles.ListPairCiv1,'Value');
    displ_num=get(handles.ListPairCiv1,'UserData');
    time=get(handles.ImaDoc,'UserData'); %get the set of times
    pxcm_xy=get(handles.SearchRange,'UserData');
    pxcmx=pxcm_xy(1);
    pxcmy=pxcm_xy(2);
    mode_list=get(handles.ListPairMode,'String');
    mode_value=get(handles.ListPairMode,'Value');
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
    ibx=str2double(get(handles.num_Bx,'String'));
    iby=str2double(get(handles.num_By,'String'));
    umin=dt*pxcmx*umin;
    umax=dt*pxcmx*umax;
    vmin=dt*pxcmy*vmin;
    vmax=dt*pxcmy*vmax;
    shiftx=round((umin+umax)/2);
    shifty=round((vmin+vmax)/2);
    isx=(umax+2-shiftx)*2+ibx;
    isx=2*ceil(isx/2)+1;
    isy=(vmax+2-shifty)*2+iby;
    isy=2*ceil(isy/2)+1;
    set(handles.num_Shiftx,'String',num2str(shiftx));
    set(handles.num_Shifty,'String',num2str(shifty));
    set(handles.num_Searchx,'String',num2str(isx));
    set(handles.num_Searchy,'String',num2str(isy));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Fix1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in CheckMask.
function get_mask_fix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.CheckMask,'Value');
if isequal(maskval,0)
    set(handles.txt_Mask,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootName,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.ListCompareMode,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
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
        set(handles.CheckMask,'Value',0)
        set(handles.CheckMask,'Value',0)
        set(handles.CheckMask,'Value',0)
    else
        %set(handles.CheckMask,'Value',1)
        set(handles.CheckMask,'Value',1)
    end
    set(handles.txt_Mask,'String',mask_displ)
    set(handles.txt_Mask,'String',mask_displ)
    set(handles.txt_Mask,'String',mask_displ)
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckMask: select box for mask option
function get_mask_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.CheckMask,'Value');
if isequal(maskval,0)
    set(handles.txt_Mask,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootName,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.ListCompareMode,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
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
        set(handles.CheckMask,'Value',0)
        set(handles.CheckMask,'Value',0)
    else
        set(handles.CheckMask,'Value',1)
    end
    set(handles.txt_Mask,'String',mask_displ)
    set(handles.txt_Mask,'String',mask_displ)
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckMask.
function get_mask_fix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.CheckMask,'Value');
if isequal(maskval,0)
    set(handles.txt_Mask,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootName,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.ListCompareMode,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
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
        set(handles.CheckMask,'Value',0)
    end
    set(handles.txt_Mask,'String',mask_displ)
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

% subdir=get(handles.txt_SubdirCiv1,'String');
[Path,Name]=fileparts(filebase);
if ~isdir(Path)
    msgbox_uvmat('ERROR','no path for input files')
    return
end
% currentdir=pwd;
% cd(Path);%move in the dir of the root name filebase
maskfiles=dir(fullfile(Path,[Name '_*mask_*.png']));%look for mask files
% cd(currentdir);%come back to the current working directory
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
% --- Executes on button press in ListSubdirCiv1.
function ListSubdirCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
list_subdir_civ1=get(handles.ListSubdirCiv1,'String');
val=get(handles.ListSubdirCiv1,'Value');
subdir=list_subdir_civ1{val};
if strcmp(subdir,'new...')
    if get(handles.CheckCiv1,'Value')
        subdir='CIV'; %default subdirectory
    else
        msgbox_uvmat('ERROR','select CheckCiv1 to perform a new Civ operation')
        return
    end    
end
set(handles.txt_SubdirCiv1,'String',subdir);
find_netcpair_civ1(handles) 

%------------------------------------------------------------------------
% --- Executes on button press in ListSubdirCiv2.
function ListSubdirCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
list_subdir_civ2=get(handles.ListSubdirCiv2,'String');
val=get(handles.ListSubdirCiv2,'Value');
subdir=list_subdir_civ2{val};
if strcmp(subdir,'new...')
    if get(handles.CheckCiv2,'Value')
        subdir='CIV'; %default subdirectory
    else
        msgbox_uvmat('ERROR','select CheckCiv2 to perform a new Civ operation')
        return
    end
end
set(handles.txt_SubdirCiv2,'String',subdir);

%------------------------------------------------------------------------
% --- Executes on button press in CheckGrid.
function CheckGrid_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
value=get(hObject,'Value');
hparent=get(hObject,'parent');
hchildren=get(hparent,'children');
handle_txtbox=findobj(hchildren,'tag','txt_Grid');
handle_dx=findobj(hchildren,'tag','num_Dx');
handle_dy=findobj(hchildren,'tag','num_Dy');
handle_title_dx=findobj(hchildren,'tag','title_Dx');
handle_title_dy=findobj(hchildren,'tag','title_Dy');
testgrid=0;
filegrid='';
if value
    filebase=get(handles.RootName,'String');
    [nbslice, flag_grid]=get_grid(filebase,handles);% look for a grid with appropriate name 
    if isequal(flag_grid,1)
        filegrid=[num2str(nbslice) 'grid'];
        testgrid=1;
    else % browse for a grid 
        filegrid=get(hObject,'UserData');%look for previous grid name stored as UserData
        if exist(filegrid,'file')
            filebase=filegrid;
        end
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.grid', ' (*.grid)';
            '*.grid',  '.grid files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a file',filebase);
        filegrid=fullfile(PathName,FileName);
        set(hObject,'UserData',filegrid);%store for future use
        if ~(isempty(FileName)||isempty(PathName)||isequal(FileName,0)||~exist(filegrid,'file'))
            testgrid=1;
        end
    end
end
if testgrid
    set(handle_dx,'Visible','off');
    set(handle_dy,'Visible','off');
    set(handle_title_dy,'Visible','off');
    set(handle_title_dx,'Visible','off');
    set(handle_txtbox,'Visible','on')
    set(handle_txtbox,'String',filegrid)
else
    set(hObject,'Value',0);
    set(handle_dx,'Visible','on'); 
    set(handle_dy,'Visible','on');
    set(handle_title_dy,'Visible','on');
    set(handle_title_dx,'Visible','on');
    set(handle_txtbox,'Visible','off')
end

%% if hObject is on the checkciv1 frame, duplicate action for checkciv2 frame
PanelName=get(hparent,'tag')
if strcmp(PanelName,'Civ1')
    hchildren=get(handles.Civ2,'children');
    handle_checkbox=findobj(hchildren,'tag','CheckGrid');
    handle_txtbox=findobj(hchildren,'tag','txt_Grid');
    handle_dx=findobj(hchildren,'tag','num_Dx');
    handle_dy=findobj(hchildren,'tag','num_Dy');
    handle_title_dx=findobj(hchildren,'tag','title_Dx');
    handle_title_dy=findobj(hchildren,'tag','title_Dy');
    set(handle_checkbox,'UserData',filegrid);%store for future use
    if testgrid
        set(handle_checkbox,'Value',1);
        set(handle_dx,'Visible','off');
        set(handle_dy,'Visible','off');
        set(handle_title_dx,'Visible','off');
        set(handle_title_dy,'Visible','off');
        set(handle_txtbox,'Visible','on')
        set(handle_txtbox,'String',filegrid)
%     else
%         set(handle_checkbox,'Value',0);
%         set(handles.CheckGrid,'Value',0);
%         set(handle_dx,'Visible','on');
%         set(handle_dy,'Visible','on');
%          set(handle_title_dx,'Visible','on');
%         set(handle_title_dy,'Visible','on');
%         set(handle_txtbox,'Visible','off')
    end 
end
%------------------------------------------------------------------------
% --- Executes on button press in CheckMask.
function CheckMask_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
value=get(hObject,'Value');
hparent=get(hObject,'parent');
parent_tag=get(hparent,'Tag');
hchildren=get(hparent,'children');
handle_txtbox=findobj(hchildren,'tag','txt_Mask');
% handle_dx=findobj(hchildren,'tag','num_Dx');
% handle_dy=findobj(hchildren,'tag','num_Dy');
testmask=0;
if value
    filebase=get(handles.RootName,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);% look for a mask with appropriate name 
    if isequal(flag_mask,1)
        filemask=[num2str(nbslice) 'mask'];
        testmask=1;
    else % browse for a mask 
        filemask=get(hObject,'UserData');%look for previous mask name stored as UserData
        if exist(filemask,'file')
            filebase=filemask;
        end
        [FileName, PathName] = uigetfile( ...
            {'*.png', ' (*.png)';
            '*.png',  '.png files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a mask file *.png',filebase);
        filemask=fullfile(PathName,FileName);
        set(hObject,'UserData',filemask);%store for future use
        if ~(isempty(FileName)||isempty(PathName)||isequal(FileName,0)||~exist(filemask,'file'))
            testmask=1;
        end
    end
end
if testmask
%     stage=4;%default
    if strcmp(parent_tag,'Civ1')
            set(handles.txt_Mask,'Visible','on')
        set(handles.txt_Mask,'String',filemask)
    set(handles.CheckMask,'Value',1)
    end
%     switch parent_tag
% %         case 'Fix1'
% %             stage=2;
%         case 'Civ2'
%              stage=3;
% %         case 'Fix2'
% %             stage=4;
%     end
%     set(handles.txt_Mask(stage:end),'Visible','on')
%     set(handles.txt_Mask(stage:end),'String',filemask)
%     set(handles.CheckMask(stage:end),'Value',1)
else
    set(hObject,'Value',0);
    set(handle_txtbox,'Visible','off')
end


% --- Executes on button press in get_gridpatch1.
function get_gridpatch1_Callback(hObject, eventdata, handles)
% hObject    handle to get_gridpatch1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MENUMATLAB
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
% --- STEREO Interp
function cmd=RUN_STINTERP(stinterpBin,filename_A_nc,filename_B_nc,filename_nc,nx_patch,ny_patch,rho_patch,subdomain_patch,thresh_value,xmlA,xmlB)
%------------------------------------------------------------------------
namelog=[filename_nc(1:end-3) '_stinterp.log'];
cmd=[stinterpBin ' -f1 ' filename_A_nc  ' -f2 ' filename_B_nc ' -f  ' filename_nc ...
    ' -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ' -nopt ' subdomain_patch ' -c1 ' xmlA ' -c2 ' xmlB '  -xy  x -Nfy 1024 > ' namelog ' 2>&1']; % redirect standard output to the log file

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
set(handles.num_MinVel,'Value',2);
set(handles.num_MinVel,'String','1');%default threshold
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
    if isfield(Data,'patch') && isequal(Data.patch,1)
        menu_field{2}='filter1';
    end
    if isfield(Data,'civ2') && isequal(Data.civ2,1)
        menu_field{3}='civ2';
    end
    if isfield(Data,'patch2') && isequal(Data.patch2,1)
        menu_field{4}='filter2';
    end
    set(handles.field_ref2,'String',menu_field);
    set(handles.field_ref2,'Value',length(menu_field));
    set(handles.num_MinVel,'Value',2);
    set(handles.num_MinVel,'String','1');%default threshold
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
set(handles.num_MinVel,'Value',1);
set(handles.field_ref1,'Value',1)
set(handles.field_ref1,'String',{' '})
set(handles.ref_fix1,'UserData',[]);
set(handles.ref_fix1,'String','');
set(handles.thresh_vel1,'String','0');

%------------------------------------------------------------------------
function ref_fix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.num_MinVel,'Value',1);
set(handles.field_ref2,'Value',1)
set(handles.field_ref2,'String',{' '})
set(handles.ref_fix2,'UserData',[]);
set(handles.ref_fix2,'String','');
set(handles.num_MinVel,'String','0');

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
% --- Executes on button press in CheckStereo.
function StereoCheck_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.CheckStereo,'Value'),0)
    set(handles.num_SubdomainSize,'Visible','on')
    set(handles.num_SmoothingParam,'Visible','on')
else
    set(handles.num_SubdomainSize,'Visible','off')
    set(handles.num_SmoothingParam,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on button press in TestCiv1: display image correlation function
function TestCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.TestCiv1,'BackgroundColor',[1 1 0])
drawnow
if get(handles.TestCiv1,'Value')
    ref_i=str2double(get(handles.ref_i,'String'));
    if strcmp(get(handles.ref_j,'Visible'),'on')
        ref_j=str2double(get(handles.ref_j,'String'));
    else
        ref_j=1;%default
    end
    [filecell,i1,i21,j1,j2,i1_civ2,i2_civ2,j1_civ2,j2_civ2,nom_type_nc,file_ref_fix1,file_ref_fix2]=...
        set_civ_filenames(handles,ref_i,ref_j,[1 0 0 0 0 0]);
    Data.ListVarName={'ny','nx','A'};
    Data.VarDimName= {'ny','nx',{'ny','nx'}};
    Data.A=imread(filecell.ima1.civ1{1});
    Data.ny=[size(Data.A,1) 1];
    Data.nx=[1 size(Data.A,2)];
    par_civ1=read_GUI(handles.Civ1);
    par_civ1.ImageWidth=size(Data.A,1);
    par_civ1.ImageHeight=size(Data.A,2);
    par_civ1.Mask='all';% will provide only the grid set for PIV, no image correlation
    Param.Civ1=par_civ1;
    Grid=civ_matlab(Param);% get the grid of x, y positions set for PIV 
    hview_field=view_field(Data);
    set(0,'CurrentFigure',hview_field)
    hhview_field=guihandles(hview_field);
    set(hview_field,'CurrentAxes',hhview_field.axes3)
    ViewData=get(hview_field,'UserData');
    ViewData.CivHandle=handles.civ;% indicate the handle of the civ GUI in view_field
    ViewData.axes3.B=imread(filecell.ima2.civ1{1});%store the second image in the UserData of the GUI view_field
    ViewData.axes3.X=Grid.Civ1_X; %keep the set of points in memeory
    ViewData.axes3.Y=Grid.Civ1_Y;
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


%------------------------------------------------------------------------
% --- Executes on button press in CheckThreshold.
function CheckThreshold_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
huipanel=get(hObject,'parent');
obj(1)=findobj(huipanel,'Tag','num_MinIma');
obj(2)=findobj(huipanel,'Tag','num_MaxIma');
obj(3)=findobj(huipanel,'Tag','title_Threshold');
if get(hObject,'Value')
    set(obj,'Visible','on')
else
    set(obj,'Visible','off')
end


%------------------------------------------------------------------------
% % --- Executes on button press in ListPairMode.
% function CivMode_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% Listprog=get(handles.ListPairMode,'String');
% index=get(handles.ListPairMode,'Value');
% prog=Listprog{index};
% switch prog
%     case 'MenuCivX'
%         set(handles.thresh_patch1,'Visible','off')
%         set(handles.thresh_text1,'Visible','off')
%         set(handles.num_MaxDiff,'Visible','off')
%         set(handles.title_MaxDiff,'Visible','off')
%         set(handles.num_Rho,'Style','edit')
%         set(handles.num_Rho,'String','1')
%         set(handles.BATCH,'Enable','on')
%     case 'CivAll'
%         if get(handles.CheckPatch1,'Value')
%             set(handles.thresh_patch1,'Visible','on')
%             set(handles.thresh_text1,'Visible','on')
%         end
%         set(handles.num_Rho,'Style','edit')
%         set(handles.num_Rho,'String','1')
%         set(handles.BATCH,'Enable','on')
%     case 'CivUvmat'
%        
% end

%------------------------------------------------------------------------
function cmd=cmd_civ1(filename,Param)
%------------------------------------------------------------------------
%pixels per cm and matrix of the image times, read from the .civ file by uvmat
%changes : filename_cmx -> filename ( no extension )
filename=regexprep(filename,'.nc',''); %file name for the result 
if isequal(Param.Civ1.Dt,'0')
    Param.Civ1.Dt='1' ;%case of 'displacement' mode
end
Param.Civ1.ImageA=regexprep(Param.Civ1.ImageA,'.png','');
Param.Civ1.ImageB=regexprep(Param.Civ1.ImageB,'.png','');
fid=fopen([filename '.civ1.cmx'],'w');
fprintf(fid,['##############   CMX file' '\n' ]);
fprintf(fid,   ['FirstImage ' regexprep(Param.Civ1.ImageA,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid,   ['LastImage  ' regexprep(Param.Civ1.ImageB,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid,  ['XX' '\n' ]);
if isfield(Param.Civ1,'Mask')
    fprintf(fid,  ['Mask ' 'y' '\n' ]);
    fprintf(fid,  ['MaskName ' regexprep(Param.Civ1.Mask,'\\','\\\\') '\n' ]);
else
    fprintf(fid,  ['Mask ' 'n' '\n' ]);
    fprintf(fid,  ['MaskName ' 'noFile use default' '\n' ]);
end
fprintf(fid,   ['ImageSize ' num2str(Param.Civ1.ImageWidth) ' ' num2str(Param.Civ1.ImageHeight) '\n' ]);   %VERIFIER CAS GENERAL ?
fprintf(fid,   ['CorrelationBoxesSize ' num2str(Param.Civ1.Bx) ' ' num2str(Param.Civ1.By) '\n' ]);
fprintf(fid,   ['SearchBoxeSize ' num2str(Param.Civ1.Searchx) ' ' num2str(Param.Civ1.Searchy) '\n' ]);
fprintf(fid,   ['RO ' num2str(Param.Civ1.Rho) '\n' ]);
if isfield(Param.Civ1,'Grid')
    fprintf(fid,   ['GridSpacing ' '25' ' ' '25' '\n' ]);
else
    fprintf(fid,   ['GridSpacing ' num2str(Param.Civ1.Dx) ' ' num2str(Param.Civ1.Dy) '\n' ]);
end
fprintf(fid,   ['XX 1.0' '\n' ]);
fprintf(fid,   ['Dt_TO ' num2str(Param.Civ1.Dt) ' ' num2str(Param.Civ1.Time) '\n' ]);
fprintf(fid,  ['PixCmXY ' '1' ' ' '1' '\n' ]);
fprintf(fid,  ['XX 1' '\n' ]);
fprintf(fid,   ['ShiftXY ' num2str(Param.Civ1.Shiftx) ' '  num2str(Param.Civ1.Shifty) '\n' ]);
if isfield(Param.Civ1,'Grid')
    fprintf(fid,  ['Grid ' 'y' '\n' ]);
    fprintf(fid,   ['GridName ' regexprep(Param.Civ1.Grid,'\\','\\\\') '\n' ]);
else
    fprintf(fid,  ['Grid ' 'n' '\n' ]);
    fprintf(fid,   ['GridName ' 'noFile use default' '\n' ]);
end
fprintf(fid,   ['XX 85' '\n' ]);
fprintf(fid,   ['XX 1.0' '\n' ]);
fprintf(fid,   ['XX 1.0' '\n' ]);
fprintf(fid,   ['Hart 1' '\n' ]);
fprintf(fid,  [ 'DecimalShift 0' '\n' ]);
fprintf(fid,   ['Deformation 0' '\n' ]);
fprintf(fid,  ['CorrelationMin 0' '\n' ]);
fprintf(fid,   ['IntensityMin 0' '\n' ]);
if ~isfield(Param.Civ1,'MinIma')% Image threshold not activated
    fprintf(fid,  ['SeuilImage n' '\n' ]);
    fprintf(fid,   ['SeuilImageValues 0 4096' '\n' ]);%not used in principle
else% Image threshold  activated
    if isempty(Param.Civ1.MaxIma)||isnan(Param.Civ1.MaxIma)
        Param.Civ1.MaxIma=2^Param.Civ1.ImageBitDepth;%take the max image value as upper bound by default
    end
    fprintf(fid,  ['SeuilImage y' '\n' ]);
    fprintf(fid,   ['SeuilImageValues ' num2str(Param.Civ1.MinIma) ' ' num2str(Param.Civ1.MaxIma) '\n' ]);
end
fprintf(fid,   ['ImageToUse ' Param.Civ1.term_a ' ' Param.Civ1.term_b '\n' ]); % VERIFIER ?
fprintf(fid,   ['ImageUsedBefore null null' '\n' ]);
fclose(fid);

if(isunix) %unix (or Mac) system
    cmd=['cp -f ' filename '.civ1.cmx ' filename '.cmx \n '];% the cmx file gives the name to the nc file
    cmd=[cmd Param.xml.Civ1Bin ' -f ' filename '.cmx >' filename '.civ1.log \n ' ]; % redirect standard output to the log file, the result file is named [filename '.nc'] by CIVx
    cmd=[cmd 'rm ' filename '.cmx'];
else %Windows system
    filename=regexprep(filename,'\\','\\\\');
    cmd=['copy /Y "' filename '.civ1.cmx" "' filename '.cmx" \n '];
    cmd=[cmd '"' regexprep(Param.xml.Civ1Bin,'\\','\\\\')...
        '" -f "' filename '.cmx" >"' filename '.civ1.log" \n ' ]; % redirect standard output to the log file
    cmd=[cmd 'del "' filename '.cmx"'];
end


function cmd=cmd_fix(filename,Param,fixname)
%%
switch fixname
    case 'Fix1'
        fi2_value=num2str(Param.(fixname).CheckF2);
    case 'Fix2'
        fi2_value=num2str(Param.(fixname).CheckF4);%need to understand why...
end
filename=regexprep(filename,'.nc','');
MaskName_string='';%default
% if Param.(fixname).CheckMask
%     MaskName_string=[' -maskName "' Param.(fixname).Mask '"'];
% end
MaxVel_string='';%default
if ~isempty(Param.(fixname).MaxVel)
    MaxVel_string=[' -threshV ' num2str(Param.(fixname).MaxVel)];
end
if isunix
    cmd=[Param.xml.FixBin ' -f ' filename '.nc -fi1 ' num2str(Param.(fixname).CheckFmin2) ...
        ' -fi2 ' fi2_value ' -fi3 ' num2str(Param.(fixname).CheckF3) ...
        ' -threshC ' num2str(Param.(fixname).MinCorr) MaxVel_string MaskName_string...
        ' >' filename '.' lower(fixname) '.log 2>&1'];
else
    cmd=['"' Param.xml.FixBin '" -f "' filename '.nc" -fi1 ' num2str(Param.(fixname).CheckFmin2)...
        ' -fi2 ' fi2_value ' -fi3 ' num2str(Param.(fixname).CheckF3) ...
        ' -threshC ' num2str(Param.(fixname).MinCorr) MaxVel_string MaskName_string...
        ' > "' filename '.' lower(fixname) '.log"'];
    cmd=regexprep(cmd,'\\','\\\\');
end


function cmd=cmd_patch(filename,Param,patchname)
%% ------------------------------------------------------------------------
filename=regexprep(filename,'.nc','');
if isunix
    cmd=[Param.xml.PatchBin...
        ' -f ' filename '.nc -m ' num2str(Param.(patchname).Nx)...
        ' -n ' num2str(Param.(patchname).Ny) ' -ro ' num2str(Param.(patchname).SmoothingParam)...
        ' -nopt ' num2str(Param.(patchname).SubdomainSize) ...
        '  > ' filename '.' lower(patchname) '.log 2>&1']; % redirect standard output to the log file
else
    cmd=['"' Param.xml.PatchBin...
        '" -f "' filename '.nc" -m ' num2str(Param.(patchname).Nx)...
        ' -n ' num2str(Param.(patchname).Ny) ' -ro ' num2str(Param.(patchname).SmoothingParam)...
        ' -nopt ' num2str(Param.(patchname).SubdomainSize)...
        '  > "' filename '.' lower(patchname) '.log" 2>&1']; % redirect standard output to the log file
    cmd=regexprep(cmd,'\\','\\\\');
end

%------------------------------------------------------------------------
% --- CheckCiv2  CheckCiv2  CheckCiv2 CheckCiv2
function cmd=cmd_civ2(filename,Param)
%------------------------------------------------------------------------
%pixels per cm and matrix of the image times, read from the .civ file by uvmat
% global civ2Bin sge%name of the executable for checkciv1 calculation
filename=regexprep(filename,'.nc','');
if isequal(Param.Civ2.Dt,'0')
    Param.Civ2.Dt='1' ;%case of 'displacement' mode
end
Param.Civ2.ImageA=regexprep(Param.Civ2.ImageA,'.png','');
Param.Civ2.ImageB=regexprep(Param.Civ2.ImageB,'.png','');% bug : .png appears two times ?
[fid,errormsg]=fopen([filename '.civ2.cmx'],'w');
if isequal(fid,-1)
    msgbox_uvmat('ERROR',errormsg)
    cmd='';
    return
end
fprintf(fid,['##############   CMX file' '\n' ]);
fprintf(fid,   ['FirstImage ' regexprep(Param.Civ2.ImageA,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid,   ['LastImage  ' regexprep(Param.Civ2.ImageB,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid,  ['XX' '\n' ]);
if isfield(Param.Civ2,'Mask')
    fprintf(fid,  ['Mask ' 'y' '\n' ]);
    fprintf(fid,  ['MaskName ' regexprep(Param.Civ2.Mask,'\\','\\\\') '\n' ]);
else
    fprintf(fid,  ['Mask ' 'n' '\n' ]);
    fprintf(fid,  ['MaskName ' 'noFile use default' '\n' ]);
end
% fprintf(fid, ['Mask ' Param.Civ2.MaskFlag '\n' ]);
% fprintf(fid, ['MaskName ' regexprep(Param.Civ2.MaskName,'\\','\\\\') '\n' ]);% for windows compatibility
fprintf(fid,   ['ImageSize ' num2str(Param.Civ2.ImageWidth) ' ' num2str(Param.Civ2.ImageHeight) '\n' ]);  
% fprintf(fid, ['ImageSize ' num2str(Param.Civ2.npx) ' ' num2str(Param.Civ2.npy) '\n' ]);   %VERIFIER CAS GENERAL ?
fprintf(fid, ['CorrelationBoxesSize ' num2str(Param.Civ2.Bx) ' ' num2str(Param.Civ2.By) '\n' ]);
fprintf(fid, ['SearchBoxeSize ' num2str(Param.Civ2.Bx) ' ' num2str(Param.Civ2.By) '\n']);
fprintf(fid, ['RO ' num2str(Param.Civ2.Rho) '\n']);
if isfield(Param.Civ2,'Grid')
    fprintf(fid,   ['GridSpacing ' '25' ' ' '25' '\n' ]);
else
    fprintf(fid,   ['GridSpacing ' num2str(Param.Civ2.Dx) ' ' num2str(Param.Civ2.Dy) '\n' ]);
end
% fprintf(fid, ['GridSpacing ' num2str(Param.Civ2.Dx) ' ' num2str(Param.Civ2.Dy) '\n']);
fprintf(fid, ['XX 1.0' '\n' ]);
fprintf(fid, ['Dt_TO ' num2str(Param.Civ2.Dt) ' ' num2str(Param.Civ2.Time) '\n' ]);
fprintf(fid, ['PixCmXY ' '1' ' ' '1' '\n' ]);
fprintf(fid, ['XX 1' '\n' ]);
fprintf(fid, 'ShiftXY 0 0\n');
if isfield(Param.Civ2,'Grid')
    fprintf(fid,  ['Grid ' 'y' '\n' ]);
    fprintf(fid,   ['GridName ' regexprep(Param.Civ2.Grid,'\\','\\\\') '\n' ]);
else
    fprintf(fid,  ['Grid ' 'n' '\n' ]);
    fprintf(fid,   ['GridName ' 'noFile use default' '\n' ]);
end
% fprintf(fid, ['Grid ' Param.Civ2.GridFlag '\n' ]);
% fprintf(fid, ['GridName ' regexprep(Param.Civ2.GridName,'\\','\\\\') '\n']);
fprintf(fid, ['XX 85' '\n' ]);
fprintf(fid, ['XX 1.0' '\n' ]);
fprintf(fid, ['XX 1.0' '\n' ]);
fprintf(fid, ['Hart 1' '\n' ]);
fprintf(fid, ['DecimalShift ' num2str(Param.Civ2.CheckDecimal) '\n']);
fprintf(fid, ['Deformation ' num2str(Param.Civ2.CheckDeformation) '\n']);
fprintf(fid,  ['CorrelationMin 0' '\n' ]);
fprintf(fid,   ['IntensityMin 0' '\n' ]);

if ~isfield(Param.Civ2,'MinIma')% Image threshold not activated
    fprintf(fid,  ['SeuilImage n' '\n' ]);
    fprintf(fid,   ['SeuilImageValues 0 4096' '\n' ]);%not used in principle
else% Image threshold  activated
    if isempty(Param.Civ2.MaxIma)||isnan(Param.Civ2.MaxIma)
        Param.Civ2.MaxIma=2^Param.Civ2.ImageBitDepth;%take the max image value as upper bound by default
    end
    fprintf(fid,  ['SeuilImage y' '\n' ]);
    fprintf(fid,   ['SeuilImageValues ' num2str(Param.Civ2.MinIma) ' ' num2str(Param.Civ2.MaxIma) '\n' ]);
end
fprintf(fid,   ['ImageToUse ' Param.Civ2.term_a ' ' Param.Civ2.term_b '\n' ]); % VERIFIER ?
fprintf(fid, ['ImageUsedBefore ' regexprep(Param.Civ2.filename_nc1,'\\','\\\\') '\n']);
fclose(fid);

if(isunix)
    cmd=['cp -f ' filename '.civ2.cmx ' filename '.cmx\n'...
        Param.xml.Civ2Bin ' -f ' filename  '.cmx >' filename '.civ2.log \n '... % redirect standard output to the log file, the result file is named [filename '.nc'] by CIVx
        'rm ' filename '.cmx \n'];%rename .cmx as .checkciv2.cmx, the result file is named [filename '.nc'] by CIVx
else 
    filename=regexprep(filename,'\\','\\\\');
    cmd=['copy /Y "' filename '.civ2.cmx" "' filename '.cmx" \n'...
        '"' regexprep(Param.xml.Civ2Bin,'\\','\\\\') '" -f "' filename  '.cmx" >"' filename '.civ2.log" \n'...
        'del "' filename '.cmx" \n'];
end

%------------------------------------------------------------------------
% --- CheckCiv1  Unified: TO ABADON
function xml_civ1_parameters=CIV1_CMD_Unified(filename,namelog,par)
%------------------------------------------------------------------------
%pixels per cm and matrix of the image times, read from the .civ file by uvmat
%global CivBin%name of the executable for checkciv1 calculation

civ1.image1=par.ImageA;
civ1.image2=par.ImageB;
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
civ1.absolut_time_T0=par.Time;
civ1.pixcmx='1';
civ1.pixcmy='1';
civ1.convectFlow='n';

xml_civ1_parameters=civ1;

%------------------------------------------------------------------------
% --- CheckCiv2  Unified: TO ABADON
function civ2=CIV2_CMD_Unified(filename,namelog,par)
%------------------------------------------------------------------------
%pixels per cm and matrix of the image times, read from the .civ file by uvmat
%global CivBin%name of the executable for checkciv1 calculation

filename=regexprep(filename,'.nc','');

civ2.image1=par.ImageA;
civ2.image2=par.ImageB;
civ2.imageSize_X=par.npx;
civ2.imageSize_Y=par.npy;
civ2.inputFileName=[par.filename_nc1 '.nc'];
civ2.outputFileName=[filename '.nc'];
civ2.correlationBoxesSize_X=par.ibx;
civ2.correlationBoxesSize_Y=par.iby;
civ2.ro=par.rho;
%checkciv2.decimalShift=par.CheckDecimal;
%checkciv2.CheckDeformation=par.CheckDeformation;
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
civ2.absolut_time_T0=par.Time;
civ2.pixcmx='1';
civ2.pixcmy='1';
civ2.convectFlow='n';
