
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

% Last Modified by GUIDE v2.5 24-Jul-2012 13:14:00
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @civ_OpeningFcn, ...
    'gui_OutputFcn',  @civ_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ~isempty(regexp(varargin{1},'_Callback$','once'))
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
xmlfile=fullfile(path_civ,'PARAM.xml');
test_batch=0;%default: ,no batch mode available
sparam=[];
if ~exist(xmlfile,'file')
    [success,message]=copyfile(fullfile(path_civ,'PARAM.xml.default'),xmlfile);
end
if exist(xmlfile,'file')
    try
        t=xmltree(xmlfile);
        sparam=convert(t);
    catch ME
        errormsg={' Unable to read the file PARAM.xml defining the civx binaries:';ME.message};
         msgbox_uvmat('WARNING',errormsg);
    end
else
    [s,w]=system('oarstat');
    if ~isequal(s,0)
        [s,w]=system('qstat');
    end
    if isequal(s,0)
        test_batch=1;
    end           
end
if isfield(sparam,'BatchParam') && isfield(sparam.BatchParam,'BatchMode')
    batch_mode=sparam.BatchParam.BatchMode; %sge is currently the only implemented batch mod
    test_command='';
    switch batch_mode
        case 'sge'
            test_command='qstat';
        case 'oar'
            test_command='oarstat';
    end
    if ~isempty(test_command)
        [s,w]=system(test_command);
        if isequal(s,0)
            test_batch=1;
        end
    end
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
    set(handles.RootPath,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
    errormsg=display_file_name(handles,fileinput);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg)
    end
    set(handles.RootPath,'BackgroundColor',[1 1 1])%paint RootName back to white to indicate that the file input is finished
end
Program_Callback([],[], handles)

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
%% get the current input root file name to initiate the browser
filebase=get(handles.RootPath,'String');
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

%% get the new input file with the browser
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

%% case of the xml file opened as input (TODO: check and see whether it is useful)
[path,name,ext]=fileparts(fileinput);
testeditxml=0;
% if isequal(ext,'.xml')
%     testeditxml=1;
%     t_browse=xmltree(fileinput);
%     head_element=get(t_browse,1);
%     if isfield(head_element,'name')&& isequal(head_element.name,'ImaDoc')
%         testeditxml=0;
%     end
% end
% if testeditxml==1 || isequal(ext,'.xls')
%     heditxml=editxml({fileinput});
%     set(heditxml,'Tag','browser')
%     waitfor(heditxml,'Tag','idle')
%     if ~ishandle(heditxml)
%         return
%     end
%     attr=findobj(get(heditxml,'children'),'Tag','CurrentAttributes');
%     set(handles.browse,'UserData',fileinput)% store for future opening with browser
%     fileinput=get(attr,'UserData');
%     if ~exist(fileinput,'file')
%         return
%     end
% end
[tild,tild,tild,i1,i2,j1,j2,FileExt,NomType]=fileparts_uvmat(fileinput);

%% prepare the GUI with parameters from the input file 
set(handles.RootPath,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',erromsg)
end
set(handles.RootPath,'BackgroundColor',[1 1 1])%paint RootName back to white to indicate that the file input is finished

%------------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_1
function MenuFile_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RootPath,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
fileinput=get(handles.MenuFile_1,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
end
set(handles.RootPath,'BackgroundColor',[1 1 1])%paint RootName back to white to indicate that the file input is finished

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_2
function MenuFile_2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RootPath,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
fileinput=get(handles.MenuFile_2,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
end
set(handles.RootPath,'BackgroundColor',[1 1 1])%paint RootName back to white to indicate that the file input is finished

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_3
function MenuFile_3_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RootPath,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
fileinput=get(handles.MenuFile_3,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
end
set(handles.RootPath,'BackgroundColor',[1 1 1])%paint RootName back to white to indicate that the file input is finished

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_4
function MenuFile_4_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RootPath,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
fileinput=get(handles.MenuFile_4,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
end
set(handles.RootPath,'BackgroundColor',[1 1 1])%paint RootName back to white to indicate that the file input is finished

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_5
function MenuFile_5_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RootPath,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
fileinput=get(handles.MenuFile_5,'Label');
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
end
set(handles.RootPath,'BackgroundColor',[1 1 1])%paint RootName back to white to indicate that the file input is finished

% -----------------------------------------------------------------------
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
function RootPath_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.RootPath,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
RootPath=get(handles.RootPath,'String');
SubDirImages=get(handles.SubDirImages,'String');
RootFile=get(handles.RootFile,'String');
ref_i=str2num(get(handles.ref_i,'String'));
ref_j=str2num(get(handles.ref_j,'String'));
NomType=get(handles.NomType,'String');
ImaExt=get(handles.ImaExt,'String');
fileinput=fullfile_uvmat(RootPath,SubDirImages,RootFile,ImaExt,NomType,ref_i,[],ref_j);
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
end
set(handles.RootPath,'BackgroundColor',[1 1 1])%paint RootName back to white to indicate that the file input is finished

%------------------------------------------------------------------------
% --- general function activated for an input file series
function errormsg=display_file_name(handles,fileinput)
%------------------------------------------------------------------------
set(handles.ListCompareMode,'Visible','on')
errormsg='';%default empty error message
drawnow

%% enable RUN, BATCH button and 'status' display
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])%set RUN button to red color
if isfield(handles,'status')
    set(handles.status,'Value',0);       %suppress the 'status' display
    status_Callback([], [], handles)
end

%% determine nomenclature types and extension of the input files
[RootPath,SubDir,RootFile,i1,i2,j1,j2,ExtInput,NomTypeInput]=fileparts_uvmat(fileinput);
NomTypeNc='';%default

%% case of xml file as input, read the civ parameters
ind_opening=0;%default
if strcmp(ExtInput,'.xml')
    %reinitialise menus
        set(handles.ListPairMode,'Value',1)
    set(handles.ListPairMode,'String',{''})
    set(handles.ListPairCiv1,'Value',1)
    set(handles.ListPairCiv1,'String',{''})
        set(handles.ListPairCiv2,'Value',1)
    set(handles.ListPairCiv2,'String',{''}) 
    Param=xml2struct(fileinput);  %read parameters from the xml input file
    fill_GUI(Param,handles);%fill the GUI with the parameters retrieved from the xml file 
    return
end

%% case of netcdf file as input, get the civ processing stage and look for a coresponding image
imageinput=fileinput;%default
if strcmp(ExtInput,'.nc')
    NomTypeNc=NomTypeInput;
    if isempty(regexp(NomTypeInput,'[ab|AB|-]', 'once'))
        set(handles.ListCompareMode,'Value',2) %mode displacement advised if the nomencalture does not involve index pairs
        set(handles.RootFile_1,'Visible','On');
    else
        set(handles.ListCompareMode,'Value',1)
        set(handles.RootFile_1,'Visible','Off');
    end
    imageinput='';
    Data=nc2struct(fileinput,'ListGlobalAttribute','Conventions','absolut_time_T0','CivStage','Civ2_ImageA','Civ1_ImageA','Civ2_ImageB','Civ1_ImageB','fix','patch','civ2','fix2');
    if isfield(Data,'Txt')
        errormsg=Data.Txt;
        return
    end
    % settings for  new civ data,
    if strcmp(Data.Conventions,'uvmat/civdata')% case of new civ data,
        set(handles.Program,'Value',1) %select civ/Matlab by default
        Program_Callback([],[], handles)
        if ~isempty(Data.CivStage)%test for civ files
            ind_opening=Data.CivStage;
        end
        if  ~isempty(Data.Civ2_ImageB)%get the corresponding input image in the netcdf file
            imageinput=Data.Civ2_ImageB;
            [tild,ImaName,ImaExt]=fileparts(Data.Civ2_ImageA);
            set(handles.RootFile_1,'String',[ImaName ImaExt])
        elseif ~isempty(Data.Civ1_ImageB)
            imageinput=Data.Civ1_ImageB;
            [tild,ImaName,ImaExt]=fileparts(Data.Civ1_ImageA);
            set(handles.RootFile_1,'String',[ImaName ImaExt])
        end
        % settings for civx data,
    elseif ~isempty(Data.absolut_time_T0')% case of  civx data,
        set(handles.Program,'Value',3) %select Cix by default
        Program_Callback([],[], handles)
        if ~isempty(Data.fix2)
            ind_opening=5;
        elseif ~isempty(Data.civ2)
            ind_opening=4;
        elseif ~isempty(Data.patch)
            ind_opening=3;
        elseif ~isempty(Data.fix)
            ind_opening=2;
        end
    else
        errormsg='the input netcdf file is not civ data';
        return
    end
    % look for the corresponding input images
    check_letter=~isempty(regexp(NomTypeInput,'[ab|AB]$','once'));%detect pair label by letter
    NomTypeIma=NomTypeInput;
    if check_letter
        NomTypeIma=NomTypeInput(1:end-1);
    else
        r=regexp(NomTypeIma,'.-(?<num2>\d+)$','names');
        if ~isempty(r)
            NomTypeIma=regexprep(NomTypeIma,['-' r.num2],'');
        end
        r=regexp(NomTypeIma,'.-(?<num2>\d+)','names');
        if ~isempty(r)
            NomTypeIma=regexprep(NomTypeIma,['-' r.num2],'');
        end
    end
    if ~exist(imageinput,'file')
    imageinput=fullfile_uvmat(RootPath,regexprep(SubDir,'.civ(_?)(\d*)$',''),RootFile,'.png',NomTypeIma,i1,[],j1);
    end
end

%% no corresponding image found, select manually with the browser
ImaExt=ExtInput;
if ~isempty(NomTypeNc)
    %no corresponding image found, select manually with the browser
    if ~exist(imageinput,'file')
        menu={'*.png;*.jpg;*.tif;*.avi;*.AVI', '(*.png,*.jpg ,*.tif, *.avi,*.AVI)';
            '*.png','.png image files'; ...
            '*.jpg',' jpeg image files'; ...
            '*.tif','.tif image files'; ...
            '*.avi;*.AVI','.avi movie files'; ...
            '*.*',  'All Files (*.*)'};
        [FileName, PathName] = uigetfile( menu, 'Pick an input image file',fileparts(fileparts(fileinput)));
        imageinput=[PathName FileName];%complete file name
        if ~exist(imageinput,'file')
            return %abandon of the browser is cancelled
        end
    end    
    %fileinput=imageinput;
end

%% scan the image file series 
[FilePath,FileName,ImaExt]=fileparts(imageinput);
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
% the root name and indices may be corrected by including the first index i1 if a corresponding xml file exists
[RootPath,SubDirImages,RootFile,i1_series,tild,j1_series,tild,NomTypeIma,FileType,MovieObject]=find_file_series(FilePath,[FileName ImaExt]);
switch FileType
    case {'image','multimage','video','mmreader'}
    otherwise
        errormsg='invalid input file: enter an image, a movie or civ .nc file';
        return
end
set(handles.RootPath,'String',RootPath)
set(handles.SubDirImages,'String',SubDirImages)
set(handles.RootFile,'String',RootFile)
if strcmp(ExtInput,'.nc')
    SubDirCiv=regexprep(SubDir,['^' SubDirImages],'');%suppress the root  SuddirImages;
else
    SubDirCiv= '.civ';
end
set(handles.SubdirCiv1,'String',SubDirCiv)
set(handles.SubdirCiv2,'String',SubDirCiv)
browse=get(handles.RootPath,'UserData');
browse.incr_pair=[0 0];%default

%% scan the images if a civ file has been opened
MinIndex_i=min(i1_series(i1_series>0));
MinIndex_j=min(j1_series(j1_series>0));
MaxIndex_i=max(i1_series(i1_series>0));
MaxIndex_j=max(j1_series(j1_series>0));

%% look for an image documentation file
XmlFileName=find_imadoc(RootPath,SubDir,RootFile,ImaExt);
if isempty(XmlFileName)
    if (strcmp(FileType,'video') || strcmp(FileType,'mmreader'))
        ext_imadoc=ImaExt;% the timing from the video movie is used
    else
        ext_imadoc='';
    end
else
    [tild,tild,ext_imadoc]=fileparts(XmlFileName);
end
set(handles.ImaDoc,'String',ext_imadoc)% display the extension name for the image documentation file used

%%  read the time in the image documentation file  
time=[];
TimeUnit=''; %default
CoordUnit='';%default
pxcm_search=1;
if ~isempty(XmlFileName)
    set(handles.ImaDoc,'BackgroundColor',[1 1 0]) % set edit box to yellow cloro to indicate that the file reading is beginning
    drawnow
    [XmlData,warntext]=imadoc2struct(XmlFileName);
    nom_type_read=[];
    if isfield(XmlData,'Time') && ~isempty(XmlData.Time)
        time=XmlData.Time;
        %transform .Time to a column vector if it is a line vector thenomenclature uses a single index: correct possible bug in xml
        if isequal(MaxIndex_i,1) && ~isequal(MaxIndex_j,1)% .Time is a line vector
            if numel(nom_type_read)>=2 && isempty(regexp(nom_type_read(2:end),'\D','once'))
                time=time';
                MaxIndex_i=MaxIndex_j;
                MaxIndex_j=1;
            end
        end
    end
    if isfield(XmlData,'TimeUnit')
        TimeUnit=XmlData.TimeUnit;
    end
    if isfield(XmlData,'GeometryCalib')
        tsai=XmlData.GeometryCalib;
        if isfield(tsai,'fx_fy')
            pxcm_search=max(tsai.fx_fy(1),tsai.fx_fy(2));%pixels:cm estimated for the search range
        end
        if isfield(tsai,'CoordUnit')
            CoordUnit=tsai.CoordUnit;
        end
    end
end
if isempty(time) && (strcmp(FileType,'video') || strcmp(FileType,'mmreader'))
    set(handles.ListPairMode,'Value',1);
    dt=1/get(MovieObject,'FrameRate');%time interval between successive frames
    if strcmp(NomTypeIma,'*')
        set(handles.ListPairMode,'String',{'series(Di)'})
        MaxIndex_i=get(MovieObject,'NumberOfFrames');
        time=(dt*(0:MaxIndex_i-1))';%list of image times
    else
        set(handles.ListPairMode,'String',[{'series(Dj)'};{'series(Di)'}])
        MaxIndex_i=max(i1_series(i1_series>0));
        MaxIndex_j=get(MovieObject,'NumberOfFrames');
        time=ones(MaxIndex_i,1)*(dt*(0:MaxIndex_j-1));%list of image times
        enable_j(handles,'on')
    end
    TimeUnit='s';
    set(handles.ImaDoc,'BackgroundColor',[1 1 1])% set display box back to whiter
end

%% timing display
%show the reference image edit box if relevant (not needed for movies or in the absence of time information
if numel(time)>=2 % if there are at least two time values to define dt
    MaxIndex_i=min(size(time,1),MaxIndex_i);%possibly adjust the max index according to time data
    MaxIndex_j=min(size(time,2),MaxIndex_j);
    time=[zeros(size(time,1),1) time]; %insert a vertical line of zeros (to deal with zero file indices)
    time=[zeros(1,size(time,2)); time]; %insert a horizontal line of zeros
else
    set(handles.ImaDoc,'String',''); %xml file not used for timing
    time=(i1_series(:,1)+0:size(i1_series,3)-1);% time=index i
    time=time'*ones(1,size(i1_series,2),1); %makes a time matrix with the same time for all j indices
    TimeUnit='frame';
end
set(handles.ImaDoc,'UserData',time); %store the matrix of times
set(handles.dt_unit,'String',['dt in m' TimeUnit]);%display dt in unit 10-3 of the time (e.g ms)
set(handles.TimeUnit,'String',TimeUnit);
set(handles.nb_field,'String',num2str(MaxIndex_i));
set(handles.nb_field2,'String',num2str(MaxIndex_j));
set(handles.CoordUnit,'String',CoordUnit)
set(handles.SearchRange,'UserData', pxcm_search);
set(handles.ImaExt,'String',ImaExt)
set(handles.NomType,'String',NomTypeIma)

%% set the reference indices from the input file indices
num_ref_i=str2num(get(handles.ref_i,'String'));
num_ref_j=str2num(get(handles.ref_j,'String'));
% for movies don't modify except if the current ref is outside index bounds
%if strcmp(ExtInput,'.nc')|| ~(strcmp(FileType,'mmreader')||strcmp(FileType,'VideoReader') && num_ref_i<=MaxIndex_i && num_ref_j<=MaxIndex_j)
if ~isempty(i1)% if i1 has been selected by the input
    num_ref_i=i1;%default ref index
    if ~isempty(i2)
        num_ref_i=floor((num_ref_i+i2)/2);
    end
    if ~isempty(j1)
    num_ref_j=j1;
    if ~isempty(j2)
        num_ref_j=floor((num_ref_j+j2)/2);
    end
    end
end
if num_ref_i>MaxIndex_i||num_ref_i<MinIndex_i
    num_ref_i=round((MinIndex_i+MaxIndex_i)/2);
end
if ~isempty(num_ref_j)&&~isempty(MaxIndex_j)&& ~isempty(MinIndex_j)
    if (num_ref_j>MaxIndex_j||num_ref_j<MinIndex_j)
        num_ref_j=round((MinIndex_j+MaxIndex_j)/2);
    end
end
if isempty(num_ref_j)
    num_ref_j=1;
end

%% update i and j index range if a nc file has been opened or pb withmin max image indices: 
% then set first and last to the inputfile index by default
first_i=str2num(get(handles.first_i,'String'));
last_i=str2num(get(handles.last_i,'String'));
if isempty(first_i) || isempty(last_i)||isempty(MinIndex_i)||isempty(MaxIndex_i)||ind_opening~=0 || isempty(first_i) || isempty(last_i)|| first_i<MinIndex_i || last_i>MaxIndex_i
   first_i=num_ref_i;
   last_i=num_ref_i;
    set(handles.first_i,'String',num2str(first_i));
    set(handles.last_i,'String',num2str(last_i));%
end

%j index range 
first_j=str2num(get(handles.first_j,'String'));
last_j=str2num(get(handles.last_j,'String'));
if isempty(first_j) || isempty(last_j)||isempty(MinIndex_j)||isempty(MaxIndex_j)||ind_opening~=0 || first_j<MinIndex_j || last_j>MaxIndex_j
       first_j=num_ref_j;
   last_j=num_ref_j;
    set(handles.first_j,'String',num2str(first_j));
    set(handles.last_j,'String',num2str(last_j));%
end
if num_ref_i>last_i || num_ref_i<first_i 
    num_ref_i=round((first_i+last_i)/2);
end
if num_ref_j>last_j || num_ref_j<first_j
    num_ref_j=round((first_j+last_j)/2);
end
set(handles.ref_i,'String',num2str(num_ref_i))
set(handles.ref_j,'String',num2str(num_ref_j))

%% set the civ options depending on the input file content when a nc file has been opened
ListOptions={'CheckCiv1', 'CheckFix1' 'CheckPatch1', 'CheckCiv2', 'CheckFix2', 'CheckPatch2'};
checkbox=zeros(size(ListOptions));%default
if ind_opening==0%case of image opening, start with Civ1
    for index=1:numel(ListOptions)
        checkbox(index)=get(handles.(ListOptions{index}),'Value');
    end
    index_max=find(checkbox, 1, 'last' );
    if isempty(index_max),index_max=1;end        
    for index=1:index_max
        set(handles.(ListOptions{index}),'Value',1)% select all operations starting from CIV1
    end
else
    for index = 1:min(ind_opening,5)
        set(handles.(ListOptions{index}),'value',0)
    end
    set(handles.(ListOptions{min(ind_opening+1,6)}),'value',1)
    for index = ind_opening+2:6
        set(handles.(ListOptions{index}),'value',0)
    end
end
%list_operation={'CheckCiv1','CheckFix1','CheckPatch1','CheckCiv2','CheckFix2','CheckPatch2'};

%set(handles.(ListOptions{min(ind_opening+1,6)}),'value',1)
update_CivOptions(handles,ind_opening)

%%  set the menus of image pairs and default selection for civ   %%%%%%%%%%%%%%%%%%%
%check_letter=~isempty(regexp(NomTypeIma,'[ab|AB]$'));%detect pair label by letter
if  isequal(NomTypeNc,'_1-2')||isempty(MaxIndex_j)|| (MaxIndex_j==1)
    set(handles.ListPairMode,'Value',1)
    set(handles.ListPairMode,'String',{'series(Di)'})   
elseif  MaxIndex_i==1 && MaxIndex_j>1% simple series in j
    set(handles.ListPairMode,'String',{'pair j1-j2';'series(Dj)'})
    if  MaxIndex_j <= 10
        set(handles.ListPairMode,'Value',1)% advice 'pair j1-j2' except in MaxIndex_j is large
    end
elseif ~(strcmp(FileType,'video') || strcmp(FileType,'mmreader'))
    set(handles.ListPairMode,'String',{'pair j1-j2';'series(Dj)';'series(Di)'})%multiple choice
    if strcmp(NomTypeNc,'_1-2_1')
        set(handles.ListPairMode,'Value',3)% advise 'series(Di)'
    elseif  MaxIndex_j <= 10
        set(handles.ListPairMode,'Value',1)% advice 'pair j1-j2' except in MaxIndex_j is large
    end
end

%% scan files to update the subdirectory list display
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

%% store info
set(handles.RootPath,'UserData',browse)% store the nomenclature type

%% list the possible index pairs, depending on the option set in ListPairMode
ListPairMode_Callback([], [], handles)

%% store the root input filename for future opening
profil_perso=fullfile(prefdir,'uvmat_perso.mat');
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
set(handles.RootPath,'BackgroundColor',[1 1 1])

%------------------------------------------------------------------------
% --- Executes on carriage return on the subdir checkciv1 edit window
function SubdirCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
SubDir=get(handles.SubdirCiv1,'String');
menu_str=get(handles.ListSubdirCiv1,'String');% read the list of subdirectories for update
ichoice=find(strcmp(SubDir,menu_str),1);
if isempty(ichoice)
    ilist=numel(menu_str); %select 'new...' in the menu
else
    ilist=ichoice;
end
set(handles.ListSubdirCiv1,'Value',ilist)% select the selected subdir in the menu
if get(handles.CheckCiv1,'Value')% if Civ1 is performed
    set(handles.SubdirCiv2,'String',SubDir);% set by default civ2 directory the same as civ1 
%     set(handles.ListSubdirCiv2,'Value',ilist)
else % if Civ1 data already exist
    errormsg=find_netcpair_civ(handles,1); %update the list of available pairs from netcdf files in the new directory
    if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end
end

%------------------------------------------------------------------------
% --- Executes on carriage return on the SubDir checkciv1 edit window
function SubdirCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
SubDir=get(handles.SubdirCiv1,'String');
menu_str=get(handles.ListSubdirCiv2,'String');% read the list of subdirectories for update
ichoice=find(strcmp(SubDir,menu_str),1);
if isempty(ichoice)
    ilist=numel(menu_str); %select 'new...' in the menu
else
    ilist=ichoice;
end
set(handles.ListSubdirCiv2,'Value',ilist)% select the selected subdir in the menu
%update the list of available pairs from netcdf files in the new directory
if ~get(handles.CheckCiv2,'Value') && ~get(handles.CheckCiv1,'Value') && ~get(handles.CheckFix1,'Value') && ~get(handles.CheckPatch1,'Value')
    errormsg=find_netcpair_civ(handles,2);
        if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckCiv1.
function CheckCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- Executes on button press in CheckFix1.
function CheckFix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch1.
function CheckPatch1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- Executes on button press in CheckCiv2.
function CheckCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- Executes on button press in CheckFix2.
function CheckFix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch2.
function CheckPatch2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- activated by any checkbox controling the selection of Civ1,Fix1,Patch1,Civ2,Fix2,Patch2
function update_CivOptions(handles,opening)
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
    RootPath=get(handles.RootPath,'String');
    if isempty(RootPath)
        msgbox_uvmat('ERROR','Please open an image or PIV .nc file with the upper bar menu Open/Browse...')
        return
    end
end
set(handles.PairIndices,'Visible','on')
set(handles.SubdirCiv1,'Visible','on')
set(handles.TitleSubdirCiv1,'Visible','on')
if opening==0
    errormsg=find_netcpair_civ(handles,1); % select the available netcdf files
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg)
    end
end
if max(checkbox(4:6))% case of civ2 pair choice needed
    set(handles.TitlePairCiv2,'Visible','on')
    set(handles.TitleSubdirCiv2,'Visible','on')
    set(handles.SubdirCiv2,'Visible','on')
    %set(handles.ListSubdirCiv2,'Visible','on')
    set(handles.ListPairCiv2,'Visible','on')
    if ~opening
        errormsg=find_netcpair_civ(handles,2); % select the available netcdf files
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',errormsg)
        end
    end
else
    set(handles.TitleSubdirCiv2,'Visible','off')
    set(handles.SubdirCiv2,'Visible','off')
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
set(handles.RUN,'UserData',now)% record the time of launch
errormsg=launch_jobs(hObject, eventdata, handles);
set(handles.RUN, 'Enable','On')
set(handles.RUN,'BackgroundColor',[1 0 0])

% display errors or start status callback to visualise results
if ~isempty(errormsg)
    display(errormsg)
    msgbox_uvmat('ERROR',errormsg)
elseif  isfield(handles,'status') %&& ~isequal(get(handles.ListPairMode,'Value'),3)
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
[rootroot,SubDir,extdir]=fileparts(root);
hfig=findobj(allchild(0),'name','civ_status');
if isempty(hfig)
    hfig=figure('DeleteFcn',@stop_status);
    set(hfig,'MenuBar','none')% suppress the menu bar
    set(hfig,'NumberTitle','off')%suppress the fig number in the title
    set(hfig,'name','civ_status')
    set(hfig,'tag','civ_status')
    set(hfig,'UserData',civ_files)
    hlist= uicontrol('Style','listbox','Units','normalized', 'Position',[0.05 0.09 0.9 0.71], 'Callback', {'open_uvmat'},'tag','list');
    uicontrol('Style','edit','Units','normalized', 'Position', [0.05 0.87 0.9 0.1],'tag','msgbox','Max',2,'String','checking files...');
    uicontrol('Style','frame','Units','normalized', 'Position', [0.05 0.81 0.9 0.05]);
    uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.7 0.01 0.2 0.07],'String','Close','FontWeight','bold','FontUnits','normalized','FontSize',0.9,'Callback',@close_GUI);
    hrefresh=uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.1 0.01 0.2 0.07],'String','Refresh','FontWeight','bold','FontUnits','normalized','FontSize',0.9,'Callback',@refresh_GUI);
    BarPosition=[0.05 0.81 0.01 0.05];
    uicontrol('Style','frame','Units','normalized', 'Position',BarPosition ,'BackgroundColor',[1 0 0],'tag','waitbar');
    drawnow 
end
StatusData.time_ref=get(handles.RUN,'UserData');% get the time of launch
StatusData.option_civ=option_civ;
set(hrefresh,'UserData',StatusData)
filepath=fileparts(civ_files{1});
set(hlist,'UserData',fileparts(filepath))
refresh_GUI(hrefresh,[])

%------------------------------------------------------------------------   
% launched by refreshing the status figure
function refresh_GUI(hObject, eventdata)
%------------------------------------------------------------------------
Tabchar={};
BarPosition=[0.05 0.81 0.01 0.05];
hfig=get(hObject,'parent');
StatusData=get(hObject,'UserData');
civ_files=get(hfig,'UserData');
[filepath,filename,ext]=fileparts(civ_files{1});
[tild,SubDir,extdir]=fileparts(filepath);
SubDir=[SubDir extdir];
option_civ=StatusData.option_civ;
nbfiles=numel(civ_files);
testrecent=0;
count=0;
datnum=zeros(1,nbfiles);
filefound=cell(1,nbfiles);
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
        
        % check the content  netcdf file
        Data=nc2struct(civ_files{ifile},'ListGlobalAttribute','CivStage','patch2','fix2','civ2','patch','fix');
        option_list={'civ1','fix1','patch1','civ2','fix2','patch2'};
        if ~isempty(Data.CivStage)
            option=Data.CivStage;%case of Matlab civ
        else
            if ~isempty(Data.patch2) && isequal(Data.patch2,1)
                option=6;
            elseif ~isempty(Data.fix2) && isequal(Data.fix2,1)
                option=5;
            elseif ~isempty(Data.civ2) && isequal(Data.civ2,1);
                option=4;
            elseif ~isempty(Data.patch) && isequal(Data.patch,1);
                option=3;
            elseif ~isempty(Data.fix) && isequal(Data.fix,1);
                option=2;
            else
                option=1;
            end
        end
        option_str=option_list{option};
        if datnum(ifile)<StatusData.time_ref
            option_str=[option_str '  --OLD--'];
        end
    end
    if option >= option_civ
        count=count+1;
    end
    [filepath,filename,ext]=fileparts(civ_files{ifile});
    Tabchar{ifile,1}=[fullfile(SubDir,filename) ext  '...' option_str];
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
    message={[num2str(count) ' file(s) done over ' num2str(nbfiles)] ;['oldest modification:  ' cell2mat(filefound(ind)) ' : ' datestr(first)];...
        ['latest modification:  ' cell2mat(filefound(indlast)) ' : ' datestr(last)]};
end
hlist=findobj(hfig,'tag','list');
hmsgbox=findobj(hfig,'tag','msgbox');
hwaitbar=findobj(hfig,'tag','waitbar');
set(hlist,'String',Tabchar)
set(hmsgbox,'String', message)
if count>0 %&& ~test_new
    BarPosition(3)=0.9*count/nbfiles;
    set(hwaitbar,'Position',BarPosition)
end


%------------------------------------------------------------------------   
% launched by deleting the status figure
function stop_status(hObject, eventdata)
%------------------------------------------------------------------------
hciv=findobj(allchild(0),'tag','civ');
hhciv=guidata(hciv);
set(hhciv.status,'value',0) %reset the status uicontrol in the GUI civ
set(hhciv.status,'BackgroundColor',[0 1 0])

%------------------------------------------------------------------------   
% launched by pressing OK on the status figure
function close_GUI(hObject, eventdata)
%------------------------------------------------------------------------
    delete(gcbf)


%------------------------------------------------------------------------
% --- Main lauch command, called by RUN and BATCH
function errormsg=launch_jobs(hObject, eventdata, handles)
%------------------------------------------------------------------------
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
    maskname=get(handles.Mask,'String');
    if ~exist(maskname,'file')
        get_mask_civ1_Callback(hObject, eventdata, handles);
    end
end
if isequal(get(handles.CheckMask,'Value'),1)
    maskname=get(handles.Mask,'String');
    if ~exist(maskname,'file')
        get_mask_fix1_Callback(hObject, eventdata, handles);
    end
end
if isequal(get(handles.CheckMask,'Value'),1)
    maskname=get(handles.Mask,'String');
    if ~exist(maskname,'file')
        get_mask_civ2_Callback(hObject, eventdata, handles);
    end
end
if isequal(get(handles.CheckMask,'Value'),1)
    maskname=get(handles.Mask,'String');
    if ~exist(maskname,'file')
        get_mask_fix2_Callback(hObject, eventdata, handles);
    end
end

%% reinitialise status callback 
if isfield(handles,'status')
    set(handles.status,'Value',0);%suppress status display
    status_Callback([], [], handles)
end

%% read the PARAM.xml file to get the binaries (and batch_mode if batch)
path_civ=fileparts(which('civ')); %path to the source directory of uvmat
xmlfile=fullfile(path_civ,'PARAM.xml');
s=[];
if exist(xmlfile,'file')% search parameter xml file in the whole matlab path
    t=xmltree(xmlfile);
    s=convert(t);
end% default configuration
if ~isfield(s,'RunParam')
    Param.xml.Civ1Bin=fullfile('bin','civ1');
    Param.xml.Civ2Bin=fullfile('bin','civ2');
    Param.xml.FixBin=fullfile('bin','fix_flag');
    Param.xml.PatchBin=fullfile('bin','patch_up');
end
if strcmp(Param.RunMode,'cluster') %computation dispatched on a cluster
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
        %default configuration
        Param.xml.Civ1Bin=fullfile('bin','civ1');
        Param.xml.Civ2Bin=fullfile('bin','civ2');
        Param.xml.FixBin=fullfile('bin','fix_flag');
        Param.xml.PatchBin=fullfile('bin','patch_up');
   %     Param.xml.CivmBin=fullfile('bin','civ_matlab');
        Param.xml.BatchMode='oar';% TODO : allow choice for sge
    end
else % run
    if isfield(s,'RunParam')
        Param.xml=s.RunParam;
    else %default configuration
        Param.xml.Civ1Bin=fullfile('bin','civ1');
        Param.xml.Civ2Bin=fullfile('bin','civ2');
        Param.xml.FixBin=fullfile('bin','fix_flag');
        Param.xml.PatchBin=fullfile('bin','patch_up');
    end
end
%Param.xml.CivmBin=fullfile('bin','civ_matlab');

%% check if the binaries exist : to move in civ_opening
binary_list={};
switch Param.Program
    case 'CivX'
        binary_list={'Civ1Bin','Civ2Bin','PatchBin','FixBin'};
    case 'CivAll'% desactivated option
        binary_list={'Civ'};
%     case 'civ_matlab.sh'% compiled version of civ_matlab 
%         binary_list={'CivmBin'};         
end
for bin_name=binary_list %loop on the list of binaries
    if isfield(Param.xml,bin_name{1})% bin_name{1} =current name in the list
        if ~isunix
        Param.xml.(bin_name{1})=[regexprep(Param.xml.(bin_name{1}),'/','\') '.exe'];
        end
        if exist(Param.xml.(bin_name{1}),'file')
            [path,name,ext]=fileparts(Param.xml.(bin_name{1}));
            currentdir=pwd;
            if isempty(path)
                path=fileparts(which('civ.m'));
            end
            if exist(path,'dir')
                cd(path);
                binpath=pwd;%path of the binary
                Param.xml.(bin_name{1})=fullfile(binpath,[name ext]);
                cd(currentdir);
            else
                errormsg=['path ' path ' for binaries specified in PARAM.xml does not exist'];
                return
            end          
        else  %look for the full path if the file name has been defined with a relative path in PARAM.xm
            fullname=fullfile(path_civ,Param.xml.(bin_name{1}));
            if exist(fullname,'file')
                Param.xml.(bin_name{1})=fullname;
            else
                errormsg=['Binary ' Param.xml.(bin_name{1}) ' specified in PARAM.xml does not exist'];
                return
            end
        end
    end
end
if strcmp(Param.Program,'civ_matlab.sh')
    if ~exist(fullfile(path_civ,'civ_matlab.sh'),'file')
        errormsg=[{'no file civ_matlab.sh found'}; {'run compile_functions.m to create it by compiling civ_matlab.m'}];
            return
    end
end

%% set the list of files and check them
display('checking the files...')
[ref_i,ref_j,errormsg]=find_ref_indices(handles);
if ~isempty(errormsg)
    return
end
[filecell,i1_civ1,i2_civ1,j1_civ1,j2_civ1,i1_civ2,i2_civ2,j1_civ2,j2_civ2,nom_type_nc,tild,tild,compare,errormsg]=...
    set_civ_filenames(handles,ref_i,ref_j,box_test);
if ~isempty(errormsg)
    return
end
set(handles.civ,'UserData',filecell);%store for futur use of status callback
display('files OK, processing...')

%% create subfolders for log, cmx, nml, xml, bat
RootBat=fileparts(filecell.nc.civ1{1,1});
switch(Param.Program)
    case {'CivX','CivAll'}
dir_list={'0_BAT','0_CMX','0_LOG'};
    case {'civ_matlab','civ_matlab.sh'}
        dir_list={'0_BAT','0_XML'};
end
for k=1:length(dir_list)
    if ~exist(fullfile(RootBat,dir_list{k}),'dir')
        mkdir(fullfile(RootBat,dir_list{k}));
    end
end

%% get information on input images or movies
nbfield=numel(i1_civ1);
nbslice=numel(j1_civ1);
% if strcmp(Param.Program,'civ_matlab')
    if Param.CheckCiv1
        [Param.Civ1.FileTypeA,ImageInfoA_civ1,Param.Civ1.ImageA]=get_file_type(filecell.ima1.civ1{1});
        [Param.Civ1.FileTypeB,ImageInfoB_civ1,Param.Civ1.ImageB]=get_file_type(filecell.ima2.civ1{1});
    end
    if Param.CheckCiv2
        [Param.Civ2.FileTypeA,ImageInfoA_civ2,Param.Civ2.ImageA]=get_file_type(filecell.ima1.civ2{1});
        [Param.Civ2.FileTypeB,ImageInfoB_civ2,Param.Civ2.ImageB]=get_file_type(filecell.ima2.civ2{1});
    end
% end

%% MAIN LOOP
time=get(handles.ImaDoc,'UserData'); %get the set of times
TimeUnit=get(handles.TimeUnit,'String');
checkframe=strcmp(TimeUnit,'frame');
batch_file_list=[];%should be renamed file_list, can be used for xml or bash files
NomTypeIma=get(handles.NomType,'String');
for ifile=1:nbfield
    for j=1:nbslice
            
        % define output file name
        if Param.CheckCiv2==1 || Param.CheckFix2==1 || Param.CheckPatch2==1
            Param.OutputFile=filecell.nc.civ2{ifile,j};
        else
            Param.OutputFile=filecell.nc.civ1{ifile,j};
        end
        Param.OutputFile=regexprep(Param.OutputFile,'.nc','');

        if Param.CheckCiv1
            % read image-dependent parameters          
            if ~checkframe% && size(time,1)>=i2_civ1(ifile) && size(time,2)>=j2_civ1(j)
                Param.Civ1.Dt=(time(i2_civ1(ifile)+1,j2_civ1(j)+1)-time(i1_civ1(ifile)+1,j1_civ1(j)+1));
            else
                Param.Civ1.Dt=1;
            end
            Param.Civ1.Time=((time(i2_civ1(ifile)+1,j2_civ1(j)+1)+time(i1_civ1(ifile)+1,j1_civ1(j)+1))/2);
            if strcmp(Param.Program,'CivX')
                Param.Civ1.term_a=num2stra(j1_civ1(j),nom_type_nc);%UTILITE?
                Param.Civ1.term_b=num2stra(j2_civ1(j),nom_type_nc);%
            end
            Param.Civ1.ImageA=filecell.ima1.civ1{ifile,j};
            Param.Civ1.ImageB=filecell.ima2.civ1{ifile,j};
            Param.Civ1.ImageBitDepth=ImageInfoA_civ1.BitDepth;
            Param.Civ1.ImageWidth=ImageInfoA_civ1.Width;
            Param.Civ1.ImageHeight=ImageInfoA_civ1.Height;
            if strcmp(NomTypeIma,'*')
                Param.Civ1.FrameIndexA=i1_civ1(ifile);
                Param.Civ1.FrameIndexB=i2_civ1(ifile);
            else% case of movies indexed with i, the frame index is then in j
                Param.Civ1.FrameIndexA=j1_civ1(j);
                Param.Civ1.FrameIndexB=j2_civ1(j);
            end
            % read mask )parameters
            if Param.Civ1.CheckMask % the lines below should be changed with the new gui
                if ~exist(Param.Civ1.Mask,'file')
                    maskbase=[filecell.filebase '_' Param.Civ1.Mask]; %
                    nbslice_mask=str2double(Param.Civ1.Mask(1:end-4)); %
                    i1_mask=mod(i1_civ1(ifile)-1,nbslice_mask)+1;
                    [RootPathMask,RootFileMask]=fileparts(maskbase);
                    Param.Civ1.Mask=fullfile_uvmat(RootPathMask,[],RootFileMask,'.png','_1',i1_mask);
                end
            end
            % read grid parameters
            if Param.Civ1.CheckGrid
                if numel(Param.Civ1.Grid)>=4 && isequal(Param.Civ1.Grid(end-3:end),'grid')
                    nbslice_grid=str2double(Param.Civ1.Grid(1:end-4)); %
                    if ~isnan(nbslice_grid)
                        i1_grid=mod(i1_civ1(ifile)-1,nbslice_grid)+1;
                        Param.Civ1.Grid=[filecell.filebase '_' fullfile_uvmat('','',Param.Civ1.Grid,'.grid','_1',i1_grid)];
                        if ~exist(Param.Civ1.GridName,'file')
                            errormsg='grid file absent for civ1';
                            return
                        end
                    elseif ~exist(Param.Civ1.Grid,'file')
                        errormsg='grid file absent for civ1';
                        return
                    end
                end
            end
            
        end
        
        if Param.CheckCiv2==1
            Param.Civ2.ImageA=filecell.ima1.civ2{ifile,j};
            Param.Civ2.ImageB=filecell.ima2.civ2{ifile,j};          
            if ~checkframe %&& size(time,1)>=i2_civ2(ifile) && size(time,2)>=j2_civ2(j)
                Param.Civ2.Dt=time(i2_civ2(ifile)+1,j2_civ2(j)+1)-time(i1_civ2(ifile)+1,j1_civ2(j)+1);
            else
                Param.Civ2.Dt=1;
            end
            Param.Civ2.Time=(time(i2_civ2(ifile)+1,j2_civ2(j)+1)+time(i1_civ2(ifile)+1,j1_civ2(j)+1))/2;
            if strcmp(Param.Program,'CivX')
                Param.Civ2.term_a=num2stra(j1_civ2(j),nom_type_nc);
                Param.Civ2.term_b=num2stra(j2_civ2(j),nom_type_nc);
            end
            Param.Civ2.filename_nc1=filecell.nc.civ1{ifile,j};
            Param.Civ2.filename_nc1(end-2:end)=[]; % remove '.nc'
            
            % mask
            if Param.Civ2.CheckMask
                if ~exist(Param.Civ2.Mask,'file')
                    maskbase=[filecell.filebase '_' Param.Civ2.Mask]; %
                    nbslice_mask=str2double(Param.Civ2.Mask(1:end-4)); %
                    i1_mask=mod(i1_civ2(ifile)-1,nbslice_mask)+1;
                    [RootPathMask,RootFileMask]=fileparts(maskbase);
                    Param.Civ2.Mask=fullfile_uvmat(RootPathMask,[],RootFileMask,'.png','_1',i1_mask);
                    %                     Param.Civ2.Mask=name_generator(maskbase,i1_mask,1,'.png','_i');
                end
            end
            %grid
            if Param.Civ2.CheckGrid
                if numel(Param.Civ2.Grid)>=4 && isequal(Param.Civ2.Grid(end-3:end),'grid')
                    nbslice_grid=str2double(Param.Civ2.Grid(1:end-4)); %
                    if ~isnan(nbslice_grid)
                        i1_grid=mod(i1_civ2(ifile)-1,nbslice_grid)+1;
                        Param.Civ2.Grid=[filecell.filebase '_' fullfile_uvmat('','',gridname,'.grid','_1',i1_grid)];
                        %                         Param.Civ2.Grid=[filecell.filebase '_' name_generator(gridname,i1_grid,1,'.grid','_i')];
                    end
                end
            end

            Param.Civ2.ImageBitDepth=ImageInfoA_civ2.BitDepth;
            Param.Civ2.ImageWidth=ImageInfoA_civ2.Width;
            Param.Civ2.ImageHeight=ImageInfoA_civ2.Height;
            if strcmp(NomTypeIma,'*')
                Param.Civ2.FrameIndexA=i1_civ2(ifile);
                Param.Civ2.FrameIndexB=i2_civ2(ifile);
            else% case of movies indexed with i, the frame index is then in j
                Param.Civ2.FrameIndexA=j1_civ2(j);
                Param.Civ2.FrameIndexB=j2_civ2(j);
            end
        end
       
        % write the command and eventually the cmx, xml or nml files
        cmd=write_cmd(Param);
        write_param(Param);
              
        % create the file used in run or batch
        switch Param.Program
            case {'civ_matlab'}
                filename_bat=regexprep(Param.OutputFile,'(.+)([/\\])(.+$)','$1$20_BAT$2$3.m');           
                [BatRoot,BatFile]=fileparts(filename_bat);
                 BatFile=regexprep(BatFile,'-','__');%transform name to suppress'-' (not valid for .m files)
                 filename_bat=[fullfile(BatRoot,BatFile) '.m'];
            case {'CivX','CivAll','civ_matlab.sh'}
                switch computer
                    case {'PCWIN','PCWIN64'}
                        filename_bat=regexprep(Param.OutputFile,'(.+)([/\\])(.+$)','$1$20_BAT$2$3.bat');
                    case {'GLNX86','GLNXA64','MACI64'}
                        filename_bat=regexprep(Param.OutputFile,'(.+)([/\\])(.+$)','$1$20_BAT$2$3.sh');
                end
        end
        
        % print the command in the bat file
        [fid,message]=fopen(filename_bat,'w');
        if isequal(fid,-1)
            errormsg=['creation of .bat file: ' message];
            return
        end
        fprintf(fid,cmd);
        fclose(fid);
        
        % special case for civ_matlab on cluster
        if strcmp(Param.Program,'civ_matlab') && strcmp(Param.RunMode,'cluster')
            filename_bat2=regexprep(Param.OutputFile,'(.+)([/\\])(.+$)','$1$20_BAT$2$3.sh');
            [fid,message]=fopen(filename_bat2,'w');
            if isequal(fid,-1)
                errormsg=['creation of .bat file: ' message];
                return
            end
            fprintf(fid,['#!/bin/bash \n' ...
                '/etc/sysprofile \n'...
                'matlab -nodisplay -nosplash -nojvm <<END_MATLAB \n'...
                'addpath(''' path_civ ''');\n']);
            for p=1:length(batch_file_list)
                fprintf(fid,['run ' filename_bat '\n']);
            end
            fprintf(fid, 'exit \n END_MATLAB \n');
            fclose(fid);
            filename_bat=filename_bat2;
        end
        
        switch computer
            case {'GLNX86','GLNXA64','MACI64'}
                system(['chmod +x ' filename_bat]);
        end
        batch_file_list{length(batch_file_list)+1}=filename_bat; 
    end
end

%% start calculation
%computation on cluster
%if batch ==3
switch Param.RunMode,
    case 'cluster'
        switch batch_mode
            case 'sge' %at the moment only psmn ENS Lyon uses it
                for p=1:length(batch_file_list)
                    %cmd=['!qsub -p ' pvalue ' -q civ.q -e ' flname '.errors -o ' flname '.log' ' ' batch_file_list{p}];
                    cmd=['!qsub -q piv1,piv2,piv3 '...
                        '-e ' regexprep(batch_file_list{p},'.bat','.errors') ' -o ' regexprep(batch_file_list{p},'.bat','.log ')...
                        ' -v ' 'LD_LIBRARY_PATH=/home/sjoubaud/matlab_sylvain/civx/lib ' batch_file_list{p}];
                    display(cmd);eval(cmd);
                end
            case 'oar_old' % to remove
                for p=1:length(batch_file_list)
                    oar_command=['!oarsub -n CIVX -q nicejob '...
                        '-E ' regexprep(batch_file_list{p},'.bat','.errors') ' -O ' regexprep(batch_file_list{p},'.bat','.log ')...
                        '-l "/core=1+{type = ''smalljob''}/licence=1,walltime=00:60:00"   ' batch_file_list{p}];
                    display(oar_command);eval(oar_command);
                end
            case 'oar'
                max_walltime=3600*12; % 12h max
                oar_modes={'oar-parexec','oar-dispatch','mpilauncher'};
                text={'Batch processing on servcalcul3 LEGI';...
                    'Please choose one of the followint modes';...
                    '* oar-parexec : default and best choice';...
                    '* oar-dispatch : jobs in a container of several cores';...
                    '* mpilauncher : one single parallel mpi job using several cores';...
                    '**********************************'...
                    };
                [S,v]=listdlg('PromptString',text,'ListString',oar_modes,...
                    'SelectionMode','single','ListSize',[400 100],'Name','LEGI job mode');
                switch oar_modes{S}
                    case 'oar-parexec' %oar-dispatch.pl
                        answer=inputdlg({'Number of cores (max 36)','extra oar options'},'oarsub parameter',1,{'12',''});
                        ncores=str2double(answer{1});
                        if strcmp(Param.Program,'civ_matlab')
                            ncores=1;
                        end
                        extra_oar=answer{2};
                        walltime_onejob=600;%seconds
                        filename_joblist=fullfile(RootBat,'job_list.txt');
                        fid=fopen(filename_joblist,'w');
                        for p=1:length(batch_file_list)
                            fprintf(fid,[batch_file_list{p} '\n']);
                        end
                        fclose(fid);
                        oar_command=['oarsub -n CIVX '...
                            '-t idempotent --checkpoint ' num2str(walltime_onejob+60) ' '...
                            '-l /core=' num2str(ncores) ','...
                            'walltime=' datestr(min(1.05*walltime_onejob/86400*max(length(batch_file_list),ncores)/ncores,max_walltime/86400),13) ' '...
                            '-E ' regexprep(filename_joblist,'\.txt\>','.stderr') ' '...
                            '-O ' regexprep(filename_joblist,'\.txt\>','.stdout') ' '...
                            extra_oar ' '...
                            '"oar-parexec -s -f ' filename_joblist ' '...
                            '-l ' filename_joblist '.log"\n'];
                        filename_oarcommand=fullfile(RootBat,'oar_command');
                        fid=fopen(filename_oarcommand,'w');
                        fprintf(fid,oar_command);
                        fclose(fid);
                        fprintf(oar_command);% display in command line
                        system(oar_command);
%                         eval(['! . ' filename
%                             _oarcommand])
                    case 'oar-dispatch' %oar-dispatch.pl
                        ncores=str2double(...
                            inputdlg('Number of cores (max 36)','oarsub parameter',1,{'6'})...
                            );
                        walltime_onejob=600;%seconds
                        filename_joblist=fullfile(RootBat,'job_list.txt');
                        fid=fopen(filename_joblist,'w');
                        for p=1:length(batch_file_list)
                            oar_command=['oarsub -n CIVX '...
                                '-E ' regexprep(batch_file_list{p},'\.bat\>','.stderr') ' -O ' regexprep(batch_file_list{p},'\.bat\>','.stdout ')...
                                '-l "/core=1,walltime=' datestr(walltime_onejob/86400,13) '"   ' batch_file_list{p}];
                            fprintf(fid,[oar_command '\n']);
                        end
                        fclose(fid);
                        oar_command=['oarsub -t container -n civx-container '...
                            '-l /core=' num2str(ncores)...
                            ',walltime=' datestr(1.05*walltime_onejob/86400*max(length(batch_file_list),ncores)/ncores,13) ' '...
                            '-E ' regexprep(filename_joblist,'\.txt\>','.stderr') ' '...
                            '-O ' regexprep(filename_joblist,'\.txt\>','.stdout') ' '...
                            '"oar-dispatch -f ' filename_joblist '"'];
                        filename_oarcommand=fullfile(RootBat,'oar_command');
                        fid=fopen(filename_oarcommand,'w');
                        fprintf(fid,[oar_command '\n']);
                        fclose(fid);
                        display(oar_command);
                        eval(['! . ' filename_oarcommand])
                    case 'mpilauncher'
                        filename_joblist=fullfile(RootBat,'job_list.txt');
                        fid=fopen(filename_joblist,'w');
                        
                        for p=1:length(batch_file_list)
                            fprintf(fid,[batch_file_list{p} '\n']);
                        end
                        fclose(fid)
                        text_oarscript=[...
                            '#!/bin/bash \n'...
                            '#OAR -n Mylauncher \n'...
                            '#OAR -l node=4/core=5,walltime=0:15:00 \n'...
                            '#OAR -E ' fullfile(RootBat,'stderrfile.log') ' \n'...
                            '#OAR -O ' fullfile(RootBat,'stdoutfile.log') ' \n'...
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
                        filename_oarscript=fullfile(RootBat,'oar_command');
                        fid=fopen(filename_oarscript,'w');
                        fprintf(fid,[text_oarscript]);
                        fclose(fid);
                        eval(['!chmod +x  ' filename_oarscript]);
                        eval(['!oarsub -S ' filename_oarscript]);
                end
        end
    case {'background','local'}
        switch Param.Program
            case {'civ_matlab'}
                switch Param.RunMode
                    case 'background'
                        switch computer
                            case {'PCWIN','PCWIN64'}
                                filename_superbat=fullfile(RootBat,'job_list.bat');
                                fid=fopen(filename_superbat,'w');
                                if fid==-1
                                    msgbox_uvmat('ERROR',['cannot create the command file ' filename_superbat])
                                    return
                                end
                                 fprintf(fid,['matlab -automation '...
                                     '-r "addpath(''' regexprep(path_civ,'\\','\\\\') ''');']);
                                for p=1:length(batch_file_list)
                                    fprintf(fid,['run ' regexprep(batch_file_list{p},'\\','\\\\') ';']);
                                end
                                 fprintf(fid, 'exit"');
                                fclose(fid);
                                dos([filename_superbat ' &']);
                            case {'GLNX86','GLNXA64','MACI64'} 
                                filename_superbat=fullfile(RootBat,'job_list.sh');
                                fid=fopen(filename_superbat,'w');
                                if fid==-1
                                    msgbox_uvmat('ERROR',['cannot create the command file ' filename_superbat])
                                    return
                                end
                                fprintf(fid,['#!/bin/bash \n' ...
                                    '/etc/sysprofile \n'...
                                    'matlab -nodisplay -nosplash -nojvm -logfile  <<END_MATLAB \n'...
                                    'addpath(''' path_civ ''');\n']);
                                for p=1:length(batch_file_list)
                                    fprintf(fid,['run ' batch_file_list{p} '\n']);
                                end
                                fprintf(fid, 'exit \n END_MATLAB \n');
                                fclose(fid);
                                system(['chmod +x ' filename_superbat]);
                                system([filename_superbat ' &']);
                        end
                    case 'local'
                        for p=1:length(batch_file_list)
                            fid=fopen(batch_file_list{p});
                            eval(fscanf(fid,'%s'));
                            fclose(fid);
                        end
                end
            case {'CivX','CivAll','civ_matlab.sh'}
                    switch computer
                        case {'PCWIN','PCWIN64'}
                            filename_superbat=fullfile(RootBat,'job_list.bat');
                            fid=fopen(filename_superbat,'w');
                            if fid==-1
                                msgbox_uvmat('ERROR',['cannot create the command file ' filename_superbat])
                                return
                            end
                            for p=1:length(batch_file_list)
                                fprintf(fid,['@call "' regexprep(batch_file_list{p},'\\','\\\\') '"' '\n']);
                            end
                            fclose(fid);
                            system(['chmod +x ' filename_superbat]);
                        case {'GLNX86','GLNXA64','MACI64'}
                            filename_superbat=fullfile(RootBat,'job_list.bat');
                            fid=fopen(filename_superbat,'w');
                            if fid==-1
                                msgbox_uvmat('ERROR',['cannot create the command file ' filename_superbat])
                                return
                            end
                            for p=1:length(batch_file_list)
                                fprintf(fid,['sh ' batch_file_list{p} '\n']);
                            end
                            fclose(fid);
                            system(['chmod +x ' filename_superbat]);
                    end
                switch Param.RunMode
                    case 'background'
                        system([filename_superbat ' &']);% execute main commmand see what it does in dos ?
                    case 'local'
                        system(filename_superbat);
                end
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
[RootPath,SubDir,RootFile]=fileparts_uvmat(fileresu);
namedoc=fullfile(RootPath,SubDir,RootFile);
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
Param=rmfield(Param,'status');
Param=rmfield(Param,'xml');
t=struct2xml(Param);
t=set(t,1,'name','Civ');% set the head label
save(t,[namedoc '.civ.xml']); %save GUI  parameters as xml file
% saveas(gcbf,namefigfull);%save the interface with name namefigfull (A CHANGER EN FICHIER  .xml)

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
%------------------------------------------------------------------------
% OUTPUT:
% filecell: structure of cell arrays {ref_i,ref_j} containing all the filenames involved in the civ process
%    the indices ref_i and ref_j correspond to the list of reference indices
%       .filebase=fullfile(RootPath,RootFile) used to construct mask names, grid names, CivDoc xml file
%       .ima1.civ1,.ima1.civ2: first image for civ1 and civ2 respectively (possibly different)
%       .ima2.civ1,.ima2.civ2: second image for civ1 and civ2 respectively (possibly different)
%       .nc.civ1,.nc.civ2: netcdf files containing civ1 and civ2 data respectively (possibly different)
% i1_civ1,i2_civ1,j1_civ1,j2_civ1,i1_civ2,i2_civ2,j1_civ2,j2_civ2: arrays of files indices, needed for timing records
function [filecell,i1_civ1,i2_civ1,j1_civ1,j2_civ1,i1_civ2,i2_civ2,j1_civ2,j2_civ2,NomType_nc,file_ref_fix1,file_ref_fix2,compare,errormsg]=...
    set_civ_filenames(handles,ref_i,ref_j,checkbox)
%------------------------------------------------------------------------
filecell=[];%default
errormsg='';
ListProgram=get(handles.Program,'String');
CivMode=ListProgram{get(handles.Program,'Value')};%Program to use , CivX or Matlab

%% get the root name and check dir
RootPath=get(handles.RootPath,'String');
SubDirImages=get(handles.SubDirImages,'String');
RootFile=get(handles.RootFile,'String');
filecell.filebase=fullfile(RootPath,SubDirImages,RootFile);
if isempty(filecell.filebase)
    errormsg='please open an image with the upper menu option Open/Browse...';
    return
end
if ~exist(RootPath,'dir')
    errormsg=['path to images ' RootPath ' not found'];
    return
end
[tild,message]=fileattrib(RootPath);
if ~isempty(message) && ~isequal(message.UserWrite,1)
    errormsg=['No writting access to ' RootPath];
    return
end
%check result directory
subdir_civ1=regexprep(get(handles.SubdirCiv1,'String'),'^.','');%subdirectory subdir_civ1 for the netcdf output data
subdir_civ2=regexprep(get(handles.SubdirCiv2,'String'),'^.','');
if isequal(subdir_civ1,''),subdir_civ1='civ'; end% put default subdir
% subdir_civ1=[ '.' subdir_civ1];
% subdir_civ2=[ '.' subdir_civ2];
if isequal(subdir_civ2,''),subdir_civ2=subdir_civ1; end% put default subdir
subdir_civ1=[SubDirImages '.' subdir_civ1];
subdir_civ2=[SubDirImages '.' subdir_civ2];

%% choose root names depending on ListCompareMode =displacement, shift, PIV or stereo PIV
ListCompareMode=get(handles.ListCompareMode,'String');
compare=ListCompareMode{get(handles.ListCompareMode,'Value')};

% set the nomenclature type of the nc files depending on the pair mode
if strcmp(compare,'displacement')||strcmp(compare,'shift')
    mode='displacement';
else
    mode_list=get(handles.ListPairMode,'String');
    mode_value=get(handles.ListPairMode,'Value');
    mode=mode_list{mode_value};
end
NomType_ima2=get(handles.NomType,'String');
NomType_nc=nomtype2pair(NomType_ima2,mode);

% set the rootfile and image indexing
RootFile_ima2=get(handles.RootFile,'String');%root file for the second image series
ext_ima=get(handles.ImaExt,'String'); % image extension (the same for all images)
switch compare
    case 'PIV'
       RootFile_ima1=RootFile_ima2;% root name of the two image series is the same
       NomType_ima1=NomType_ima2;% the index of the first image follows the index of the second one
       RootFile_nc=RootFile_ima2;
    case 'displacement'
       RootFile_ima1=get(handles.RootFile_1,'String');% root name of the first image series set by handles.RootFile_1
       NomType_ima1='';% no indexing of the first image, a fixed reference for the whole series
       RootFile_nc=RootFile_ima2;
    case 'shift'
       RootFile_ima1=get(handles.RootFile_1,'String');% root name of the first image series set by handles.RootFile_1
       NomType_ima1=NomType_ima2;% the index of the first image follows the index of the second one
       RootFile_nc=[RootFile_ima1 '-' RootFile_ima2];
end

%determine the list of file indices involved
[i1_civ1,i2_civ1,j1_civ1,j2_civ1,i1_civ2,i2_civ2,j1_civ2,j2_civ2]=...
    find_pair_indices(handles,ref_i,ref_j,mode);

%determine the new filebase for 'displacement' ListPairMode (comparison of two series)
%filebase_B=filebase;% root name of the second field series for stereo
% filebase_A=filebase;%default
% if strcmp(compare,'PIV') 
%     filebase_AB=filebase;
% else
%     [Path2,Name2]=fileparts(filebase_B);
%     Name1=RootFile_ima1;
%     filebase_AB=fullfile(Path2,[Name2 '-' Name1]);   
% end
% [RootPath_AB,RootFile_AB]=fileparts(filebase_AB);
% % [RootPath_ima1,RootFile_ima1]=fileparts(filebase_B);
% [RootPath_ima2,RootFile_ima2]=fileparts(filebase_B);
% [RootPath_nc,RootFile_nc]=fileparts(filebase_B);%default
% if strcmp(compare,'displacement')
% %     [RootPath_ima1,RootFile_ima1]=fileparts(filebase_B);
% %     [RootPath_ima2,RootFile_ima2]=fileparts(filebase_B);
%     [RootPath_nc,RootFile_nc]=fileparts(filebase_B);
% elseif strcmp(compare,'shift')
%     RootPath_nc=RootPath_AB;
%     RootFile_nc=RootFile_AB;
% end
% else
%     filebase_ima1=filebase_B;
%     filebase_ima2=filebase_B;
%     filebase_nc=filebase_B;
% [RootPath_ima1,RootFile_ima1]=fileparts(filebase_ima1);
% [RootPath_ima2,RootFile_ima2]=fileparts(filebase_ima2);
% [RootPath_nc,RootFile_nc]=fileparts(filebase_nc);
% [RootPath_A,RootFile_A]=fileparts(filebase_A);

    
%% determine reference files for fix:
file_ref_fix1={};%default
file_ref_fix2={};
nbfield=length(i1_civ1);
nbslice=length(j1_civ1);
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
                [RootPathRef,RootFile]=fileparts(ref.filebase);
                file_ref=fullfile_uvmat(RootPathRef,ref.subdir,RootFile,'.nc',ref.NomType,num_i1(ifile),num_i2(ifile),num_j1(j),num_j2(j));
                file_ref_fix1(ifile,j)={file_ref};
                if ~exist(file_ref,'file')
                    errormsg=['reference file ' file_ref ' not found for fix1'];
                    return
                end
            end
        end
    end
end

%% determine reference files for fix2:
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
                [RootPathRef,RootFile]=fileparts(ref.filebase);
                file_ref=fullfile_uvmat(RootPathRef,ref.subdir,RootFile,'.nc',ref.NomType,num_i1(ifile),num_i2(ifile),num_j1(j),num_j2(j));
                file_ref_fix2(ifile,j)={file_ref};
                if ~exist(file_ref,'file')
                    errormsg=['reference file ' file_ref ' not found for fix2'];
                    return
                end
            end
        end
    end
end

%% check the existence of the netcdf and image files involved
% %%%%%%%%%%%%  case CheckCiv1 activated   %%%%%%%%%%%%%
if checkbox(1)==1;
    detect=1;
    vers=0;
    subdir_civ1_new=subdir_civ1;
    answer='No';
    while detect==1 %create a new subdir if the netcdf files already exist
        for ifile=1:nbfield
            for j=1:nbslice
                filename=fullfile_uvmat(RootPath,subdir_civ1_new,RootFile_nc,'.nc',NomType_nc,i1_civ1(ifile),i2_civ1(ifile),j1_civ1(j),j2_civ1(j));
                detect=exist(filename,'file')==2;
                if detect% if a netcdf file already exists
                    if strcmp(answer,'No')
                        answer=msgbox_uvmat('INPUT_Y-N',['overwrite existing civ files in ' subdir_civ1_new]);
                    end
                    if strcmp(answer,'Yes')
                        detect=0;
                        filecell.nc.civ1(ifile,j)={filename};
                    else
                        r=regexp(subdir_civ1_new,'(?<root>.*\D)(?<num1>\d+)$','names');%detect whether name ends by a number
                        if isempty(r)
                            r(1).root=[subdir_civ1_new '_'];
                            r(1).num1='0';
                        end
                        subdir_civ1_new=[r(1).root num2str(str2num(r(1).num1)+1)];%increment the index by 1 or put 1
                        subdir_civ2=subdir_civ1_new;
                    end
                    break
                end
                filecell.nc.civ1(ifile,j)={filename};
            end
            if detect% if a netcdf file already exists
                break
            end
        end
  
        %create the new SubdirCiv1
        if ~exist(fullfile(RootPath,subdir_civ1_new),'dir')     
            [xx,msg1]=mkdir(fullfile(RootPath,subdir_civ1_new));
            if ~strcmp(msg1,'')
                errormsg=['cannot create ' subdir_civ1_new ': ' msg1];%error message for directory creation
                return
            elseif isunix          
                [xx,msg2] = fileattrib(fullfile(RootPath,subdir_civ1_new),'+w','g'); %yield writing access (+w) to user group (g)
                if ~strcmp(msg2,'')
                    errormsg=['pb of permission for  ' fullfile(RootPath,subdir_civ1_new) ': ' msg2];%error message for directory creation
                    return
                end
            end
        end
        if strcmp(compare,'stereo PIV')&&(strcmp(mode,'pair j1-j2')||strcmp(mode,'series(Dj)')||strcmp(mode,'series(Di)'))%check second nc series
            for ifile=1:nbfield
                for j=1:nbslice
                     filename=fullfile_uvmat(RootPath,subdir_civ1_new,RootFile_A,'.nc',NomType_nc,i1_civ1(ifile),i2_civ1(ifile),j1_civ1(j),j2_civ1(j));
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
            %create the new SubdirCiv1
            if ~exist(fullfile(RootPath,subdir_civ1_new),'dir')        
                [xx,msg1]=mkdir(fullfile(RootPath,subdir_civ1_new));
                if ~strcmp(msg1,'')
                    errormsg=['cannot create ' subdir_civ1_new ': ' msg1];
                    return
                else
                    [xx,msg2] = fileattrib(fullfile(RootPath,subdir_civ1_new),'+w','g'); %yield writing access (+w) to user group (g)
                    if ~strcmp(msg2,'')
                        errormsg=['pb of permission for ' subdir_civ1_new ': ' msg2];%error message for directory creation
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
             filename=fullfile_uvmat(RootPath,SubDirImages,RootFile_ima1,ext_ima,NomType_ima1,i1_civ1(ifile),[],j1_civ1(j));
            idetect(j)=exist(filename,'file')==2;
            filecell.ima1.civ1(ifile,j)={filename}; %first image
            filename=fullfile_uvmat(RootPath,SubDirImages,RootFile_ima2,ext_ima,NomType_ima2,i2_civ1(ifile),[],j2_civ1(j));
            idetect_1(j)=exist(filename,'file')==2;
            filecell.ima2.civ1(ifile,j)={filename};%second image
        end
        [idetectmin,indexj]=min(idetect);
        if idetectmin==0,
            errormsg=[filecell.ima1.civ1{ifile,indexj} ' not found'];
            return
        end
        [idetectmin,indexj]=min(idetect_1);
        if idetectmin==0,
            errormsg=[filecell.ima2.civ1{ifile,indexj} ' not found'];
            return
        end
    end
    if strcmp(compare,'stereo PIV') && (strcmp(mode,'pair j1-j2') || strcmp(mode,'series(Dj)') || strcmp(mode,'series(Di)'))
        for ifile=1:nbfield
            for j=1:nbslice
                filename=fullfile_uvmat(RootPath,'',RootFile_A,ext_ima,NomType_ima1,i1_civ1(ifile),[],j1_civ1(j));
                idetect(j)=exist(filename,'file')==2;
                filecell.imaA1.civ1(ifile,j)={filename} ;%first image
                filename=fullfile_uvmat(RootPath,'',RootFile_A,ext_ima,NomType_ima2,i2_civ1(ifile),[],j2_civ1(j));
                idetect_1(j)=exist(filename,'file')==2;
                filecell.imaA2.civ1(ifile,j)={filename};%second image
            end
            [idetectmin,indexj]=min(idetect);
            if idetectmin==0,
                errormsg=[filecell.imaA1.civ1{ifile,indexj} ' not found'];
                return
            end
            [idetectmin,indexj]=min(idetect_1);
            if idetectmin==0,
                errormsg=[filecell.imaA2.civ1{ifile,indexj} ' not found'];
                return
            end
        end
    end
    
    %%%%%%%%%%%%%  checkfix1 or checkpatch1 activated but no checkciv1   %%%%%%%%%%%%%
elseif (checkbox(2)==1 || checkbox(3)==1);
    for ifile=1:nbfield
        for j=1:nbslice
            filename=fullfile_uvmat(RootPath,subdir_civ1,RootFile_nc,'.nc',NomType_nc,i1_civ1(ifile),i2_civ1(ifile),j1_civ1(j),j2_civ1(j));
            detect=exist(filename,'file')==2;
            if detect==0
                errormsg=[filename ' not found'];
                return
            end
            filecell.nc.civ1(ifile,j)={filename};
        end
    end
    if strcmp(compare,'stereo PIV')
        for ifile=1:nbfield
            for j=1:nbslice
                filename=fullfile_uvmat(RootPath,subdir_civ1,RootFile_A,'.nc',NomType_nc,i1_civ1(ifile),i2_civ1(ifile),j1_civ1(j),j2_civ1(j));
                filecell.ncA.civ1(ifile,j)={filename};
                if ~exist(filename,'file')
                    errormsg=['input file ' filename ' not found'];
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
                filename=fullfile_uvmat(RootPath,subdir_civ2_new,RootFile_nc,'.nc',NomType_nc,i1_civ2(ifile),i2_civ2(ifile),j1_civ2(j),j2_civ2(j));
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
        if ~exist(fullfile(RootPath,subdir_civ2_new),'dir')
            [xx,m2]=mkdir(fullfile(RootPath,subdir_civ2_new));
            [xx,msg2] = fileattrib(fullfile(RootPath,subdir_civ2_new),'+w','g'); %yield writing access (+w) to user group (g)
            if ~isequal(m2,'')
                errormsg=['cannot create ' fullfile(RootPath,subdir_civ2_new) ': ' m2];
                return
            end
        end
        if strcmp(compare,'stereo PIV')%check second nc series
            for ifile=1:nbfield
                for j=1:nbslice
                    filename=fullfile_uvmat(RootPath,subdir_civ2_new,RootFile_A,'.nc',NomType_nc,i1_civ2(ifile),i2_civ2(ifile),j1_civ2(j),j2_civ2(j));
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
            %create the new SubdirCiv1
            if ~exist(fullfile(RootPath,subdir_civ2_new),'dir')
                [xx,m2]=mkdir(subdir_civ2_new);
                 [xx,msg2] = fileattrib(fullfile(RootPath,subdir_civ2_new),'+w','g'); %yield writing access (+w) to user group (g)
                if ~isequal(m2,'')
                    errormsg= ['cannot create ' fullfile(RootPath,subdir_civ2_new) ': ' m2];%error message for directory creation
                    return
                end
            end
        end
    end
    subdir_civ2=subdir_civ2_new;
end

%%%%%%%%%%%%%  if checkciv2 results are obtained or used  %%%%%%%%%%%%%
if checkbox(4)==1 || checkbox(5)==1 || checkbox(6)==1 %civ2
    %check source netcdf file of checkciv1 estimates
    if checkbox(1)==0; %no civ1 performed
        for ifile=1:nbfield
            for j=1:nbslice
                filename=fullfile_uvmat(RootPath,subdir_civ1,RootFile_nc,'.nc',NomType_nc,i1_civ1(ifile),i2_civ1(ifile),j1_civ1(j),j2_civ1(j));%
                filecell.nc.civ1(ifile,j)={filename};% name of the civ1 file
                if ~exist(filename,'file')
                    errormsg=['input file ' filename ' not found'];
                    return
                end
                if ~testdiff % civ2 or patch2 are written in the same file as civ1
                    if checkbox(4)==0 ; %check the existence of civ2 if it is not calculated
                        Data=nc2struct(filename,'ListGlobalAttribute','CivStage','civ2');
                        if isfield(Data,'Txt')
                            errormsg=Data.Txt; 
                            return
                        elseif ~isempty(Data.CivStage)% case of new civ files
                            if Data.CivStage<4 %test for civ files
                            errormsg=['no civ2 data in ' filename];
                            return
                            end
                        elseif isempty(Data.civ2)||isequal(Data.civ2,0)
                            errormsg=['no civ2 data in ' filename];
                            return
                        end
                    elseif checkbox(3)==0; %check the existence of patch if it is not calculated
                        Data=nc2struct(filename,'ListGlobalAttribute','CivStage','patch');
                        if isfield(Data,'Txt')
                            errormsg=Data.Txt;
                            return
                        elseif ~isempty(Data.CivStage)
                            if Data.CivStage<3 %test for civ files
                                errormsg=['no patch data in ' filename];
                                return
                            end
                        elseif isempty(Data.patch)||isequal(Data.patch,0)
                            errormsg=['no patch data in ' filename];
                            return
                        end
                    end
                end
            end
        end
        if strcmp(compare,'stereo PIV')
            for ifile=1:nbfield
                for j=1:nbslice
                    filename=fullfile_uvmat(RootPath,subdir_civ2,RootFile_A,'.nc',NomType_nc,i1_civ2(ifile),i2_civ2(ifile),j1_civ2(j),j2_civ2(j));
                    filecell.ncA.civ2(ifile,j)={filename};
                    if ~exist(filename,'file')
                        errormsg=['input file ' filename ' not found'];
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
            filename=fullfile_uvmat(RootPath,subdir_civ2,RootFile_nc,'.nc',NomType_nc,i1_civ2(ifile),i2_civ2(ifile),j1_civ2(j),j2_civ2(j));
            detect=exist(filename,'file')==2;
            filecell.nc.civ2(ifile,j)={filename};
        end
    end
    %get first image names for checkciv2
    if checkbox(1)==1 && isequal(i1_civ1,i1_civ2) && isequal(j1_civ1,j1_civ2)
        filecell.ima1.civ2=filecell.ima1.civ1;
    elseif checkbox(4)==1
        for ifile=1:nbfield
            for j=1:nbslice
                filename=fullfile_uvmat(RootPath,SubDirImages,RootFile_ima1,ext_ima,NomType_ima1,i1_civ2(ifile),[],j1_civ2(j));
                idetect_2(j)=exist(filename,'file')==2;
                filecell.ima1.civ2(ifile,j)={filename};%first image
            end
            [idetectmin,indexj]=min(idetect_2);
            if idetectmin==0,
               errormsg=['input image ' filecell.ima1.civ2{ifile,indexj} ' not found'];
                return
            end
        end
    end
    
    %get second image names for checkciv2
    if checkbox(1)==1 && isequal(i2_civ1,i2_civ2) && isequal(j2_civ1,j2_civ2)
        filecell.ima2.civ2=filecell.ima2.civ1;
    elseif checkbox(4)==1
        for ifile=1:nbfield
            for j=1:nbslice
                filename=fullfile_uvmat(RootPath,SubDirImages,RootFile_ima2,ext_ima,NomType_ima2,i2_civ2(ifile),[],j2_civ2(j));
                idetect_3(j)=exist(filename,'file')==2;
                filecell.ima2.civ2(ifile,j)={filename};%first image
            end
            [idetectmin,indexj]=min(idetect_3);
            if idetectmin==0,
                errormsg=['input image ' filecell.ima2.civ2{ifile,indexj} ' not found'];
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
                 filename=fullfile_uvmat(RootPath,subdir_civ2,RootFile_nc,'.nc',NomType_nc,i1_civ2(ifile),i2_civ2(ifile),j1_civ2(j),j2_civ2(j));
                filecell.nc.civ2(ifile,j)={filename};
                if ~exist(filename,'file')
                    errormsg=['input file ' filename ' not found'];
                    return
                else
                    Data=nc2struct(filename,'ListGlobalAttribute','CivStage','civ2');
                    if ~isempty(Data.CivStage) && Data.CivStage<4 %test for civ files
                            errormsg=['no civ2 data in ' filename];
                            return
                    elseif isempty(Data.civ2)||isequal(Data.civ2,0)
                        errormsg=['no civ2 data in ' filename];
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
                 filename=fullfile_uvmat(RootPath,subdir_civ1,RootFile_AB,'.nc',NomType_nc,i1_civ1(ifile),i2_civ1(ifile),j1_civ1(j),j2_civ1(j));
                filecell.st(ifile,j)={filename};
            end
        end
    end
    if  checkbox(6) && isequal(get(handles.CheckStereo,'Value'),1)
        for ifile=1:nbfield
            for j=1:nbslice
                 filename=fullfile_uvmat(RootPath,subdir_civ2,RootFile_AB,'.nc',NomType_nc,i1_civ2(ifile),i2_civ2(ifile),j1_civ2(j),j2_civ2(j));
                filecell.st(ifile,j)={filename};
            end
        end
    end
end
set(handles.SubdirCiv1,'String',regexprep(subdir_civ1,['^' SubDirImages],''));%suppress the root  SuddirImages;);%update the edit box
set(handles.SubdirCiv2,'String',regexprep(subdir_civ2,['^' SubDirImages],''));%update the edit box

% For CivX COPY IMAGES TO THE FORMAT .png IF NEEDED 
if strcmp(CivMode,'CivX')
    NomType_imanew1=NomType_ima1;
    NomType_imanew2=NomType_ima2;
    if ~isequal(ext_ima,'.png')
        if checkbox(1) %if civ1 is performed
             [FileType,FileInfo,MovieObject]=get_file_type(filecell.ima1.civ1{1});
            check_j=0;
            if strcmp(FileType,'mmreader')||strcmp(FileType,'VideoReader')||strcmp(FileType,'multimage')
                if max(j1_civ1)>1
                    check_j=1;
                    NomType_imanew1='_1_1';
                else
                    NomType_imanew1='_1';
                end
            end
            h = waitbar(0,'copy images to the .png format for civ1');% display a wait bar
            for ifile=1:nbfield
                waitbar(ifile/nbfield);
                for j=1:nbslice
                    filename=fullfile_uvmat(RootPath,SubDirImages,RootFile_ima1,'.png',NomType_imanew1,i1_civ1(ifile),[],j1_civ1(j));
                    if ~exist(filename,'file')
                        if check_j
                        A=read_image(filecell.ima1.civ1{ifile,j},FileType,MovieObject,j1_civ1(j));
                        else
                            A=read_image(filecell.ima1.civ1{ifile,j},FileType,MovieObject,i1_civ1(ifile));
                        end
                        imwrite(uint16(sum(A,3)),filename,'BitDepth',16);
                    end
                    filecell.ima1.civ1(ifile,j)={filename};
                    filename=fullfile_uvmat(RootPath,SubDirImages,RootFile_ima2,'.png',NomType_imanew1,i2_civ1(ifile),[],j2_civ1(j));
                    if ~exist(filename,'file')
                         if check_j
                            A=read_image(filecell.ima1.civ1{ifile,j},FileType,MovieObject,j2_civ1(j));
                        else
                            A=read_image(filecell.ima1.civ1{ifile,j},FileType,MovieObject,i2_civ1(ifile));
                         end
                        imwrite(uint16(sum(A,3)),filename,'BitDepth',16);
                    end
                    filecell.ima2.civ1(ifile,j)={filename};
                end
            end
            close(h)
        end
        if checkbox(4) %if civ2 is performed
             [FileType,FileInfo,MovieObject]=get_file_type(filecell.ima1.civ2{1});
            check_j=0;
            if strcmp(FileType,'mmreader')||strcmp(FileType,'VideoReader')||strcmp(FileType,'multimage')
                if max(j1_civ2)>1
                    check_j=1;
                    NomType_imanew1='_1_1';
                else
                    NomType_imanew1='_1';
                end
            end
            h = waitbar(0,'copy images to the .png format for civ2');% display a wait bar
            for ifile=1:nbfield
                waitbar(ifile/nbfield);
                for j=1:nbslice
                    filename=fullfile_uvmat(RootPath,SubDirImages,RootFile_ima1,'.png',NomType_imanew1,i1_civ2(ifile),[],j1_civ2(j));
                    if ~exist(filename,'file')
                        if check_j
                        A=read_image(filecell.ima1.civ1{ifile,j},FileType,MovieObject,j1_civ2(j));
                        else
                            A=read_image(filecell.ima1.civ1{ifile,j},FileType,MovieObject,i1_civ2(ifile));
                        end
                        imwrite(uint16(sum(A,3)),filename,'BitDepth',16);
                    end
                    filecell.ima1.civ2(ifile,j)={filename};
                    filename=fullfile_uvmat(RootPath,SubDirImages,RootFile_ima2,'.png',NomType_imanew2,i2_civ2(ifile),[],j2_civ2(j));
                    if ~exist(filename,'file')
                        if check_j
                        A=read_image(filecell.ima1.civ1{ifile,j},FileType,MovieObject,j1_civ2(j));
                        else
                            A=read_image(filecell.ima1.civ1{ifile,j},FileType,MovieObject,i1_civ2(ifile));
                        end
                        imwrite(uint16(sum(A,3)),filename,'BitDepth',16);
                    end
                    filecell.ima2.civ2(ifile,j)={filename};
                end
            end
            close(h);
        end
    end
end

%------------------------------------------------------------------------
% --- determine the list of index pairs of processing file
function [i1_civ1,i2_civ1,j1_civ1,j2_civ1,i1_civ2,i2_civ2,j1_civ2,j2_civ2]=...
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
    i1_civ1=ref_i-floor(index_civ1/2)*ones(size(ref_i));% set of first image numbers
    i2_civ1=ref_i+ceil(index_civ1/2)*ones(size(ref_i));
    j1_civ1=ref_j;
    j2_civ1=ref_j;
    i1_civ2=ref_i-floor(index_civ2/2)*ones(size(ref_i));
    i2_civ2=ref_i+ceil(index_civ2/2)*ones(size(ref_i));
    j1_civ2=ref_j;
    j2_civ2=ref_j;   
    
    % adjust the first and last field number
    lastfield=str2double(get(handles.nb_field,'String'));
    if isnan(lastfield)
        indsel=find((i1_civ1 >= 1)&(i1_civ2 >= 1));
    else
        indsel=find((i2_civ1 <= lastfield)&(i2_civ2 <= lastfield)&(i1_civ1 >= 1)&(i1_civ2 >= 1));
    end
    if length(indsel)>=1
        firstind=indsel(1);
        lastind=indsel(end);
        set(handles.first_i,'String',num2str(ref_i(firstind)))%update the display of first and last fields
        set(handles.last_i,'String',num2str(ref_i(lastind)))
        ref_i=ref_i(indsel);
        i1_civ1=i1_civ1(indsel);
        i1_civ2=i1_civ2(indsel);
        i2_civ1=i2_civ1(indsel);
        i2_civ2=i2_civ2(indsel);
    end
elseif isequal (mode,'series(Dj)')
    lastfield_j=str2double(get(handles.nb_field2,'String'));
    i1_civ1=ref_i;% set of first image numbers
    i2_civ1=ref_i;
    j1_civ1=ref_j-floor(index_civ1/2)*ones(size(ref_j));
    j2_civ1=ref_j+ceil(index_civ1/2)*ones(size(ref_j));
    i1_civ2=ref_i;
    i2_civ2=ref_i;
    j1_civ2=ref_j-floor(index_civ2/2)*ones(size(ref_j));
    j2_civ2=ref_j+ceil(index_civ2/2)*ones(size(ref_j));
    % adjust the first and last field number
    if isnan(lastfield_j)
        indsel=find((j1_civ1 >= 1)&(j1_civ2 >= 1));
    else
        indsel=find((j2_civ1 <= lastfield_j)&(j2_civ2 <= lastfield_j)&(j1_civ1 >= 1)&(j1_civ2 >= 1));
    end
    if length(indsel)>=1
        firstind=indsel(1);
        lastind=indsel(end);
        set(handles.first_j,'String',num2str(ref_j(firstind)))%update the display of first and last fields
        set(handles.last_j,'String',num2str(ref_j(lastind)))
        ref_j=ref_j(indsel);
        j1_civ1=j1_civ1(indsel);
        j2_civ1=j2_civ1(indsel);
        j1_civ2=j1_civ2(indsel);
        j2_civ2=j2_civ2(indsel);
    end
elseif isequal(mode,'pair j1-j2') %case of bursts (png_old or png_2D)
    displ_num=get(handles.ListPairCiv1,'UserData');
    i1_civ1=ref_i;
    i2_civ1=ref_i;
    j1_civ1=displ_num(1,index_civ1);
    j2_civ1=displ_num(2,index_civ1);
    i1_civ2=ref_i;
    i2_civ2=ref_i;
    j1_civ2=displ_num(1,index_civ2);
    j2_civ2=displ_num(2,index_civ2);
elseif isequal(mode,'displacement')
    i1_civ1=ref_i;
    i2_civ1=ref_i;
    j1_civ1=ref_j;
    j2_civ1=ref_j;
    i1_civ2=ref_i;
    i2_civ2=ref_i;
    j1_civ2=ref_j;
    j2_civ2=ref_j;
end

%------------------------------------------------------------------------
% --- Executes on button press in ListCompareMode.
function ListCompareMode_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
ListCompareMode=get(handles.ListCompareMode,'String');
option=ListCompareMode{get(handles.ListCompareMode,'Value')};
if ~strcmp(option,'PIV') % case 'displacement' or 'stereo PIV'
    filebase=get(handles.RootPath,'String');
    set(handles.sub_txt,'Visible','on')
    set(handles.RootFile_1,'Visible','On');%mkes the second file input window visible
    mode_store=get(handles.ListPairMode,'String');%get the present 'mode'
    set(handles.ListCompareMode,'UserData',mode_store);%store the mode display
    set(handles.ListPairMode,'Visible','off')
    
    %% open an image file with the browser
    ind_opening=1;%default
    browse.incr_pair=[0 0]; %default
    oldfile=get(handles.RootPath,'String');
    menu={'*.png;*.jpg;*.tif;*.avi;*.AVI;', ' (*.png,*.jpg ,.tif, *.avi,*.AVI)';
        '*.png','.png image files'; ...
        '*.jpg',' jpeg image files'; ...
        '*.tif','.tif image files'; ...
        '*.avi;*.AVI','.avi movie files'; ...
        '*.*',  'All Files (*.*)'};
    if strcmp(option,'displacement')
        comment='Pick the reference file for displacements';
    else
        comment='Pick a file of the second series';
    end
    [FileName, PathName] = uigetfile( menu, comment,oldfile);
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
        msgbox_uvmat('ERROR','The second image or series must be in the same directory as the first one')
        return
    end
    if strcmp(option,'displacement')
        [tild,RootFile_1]=fileparts(name);
    else
        [FilePath,FileName,Ext]=fileparts(fileinput);
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
% the root name and indices may be corrected by including the first index i1 if a corresponding xml file exists
[RootPath,SubDir,RootFile_1,i1_series,i2_series,j1_series,j2_series,nom_type_1,FileType,Object,i1,i2,j1,j2]=find_file_series(FilePath,[FileName Ext]);

        %check image nom type 
        if ~strcmp(nom_type_1,get(handles.NomType,'String'))
        msgbox_uvmat('ERROR','The second image series must have the same indexing type as the first one, or use the option displacement for a fixed image')
        return
        end
    end   
    %check image  extension 
    if ~strcmp(ext,get(handles.ImaExt,'String'))
        msgbox_uvmat('ERROR','The second image series must have the same extension name as the first one')
        return
    end 
    set(handles.RootFile_1,'String',RootFile_1);
else
    set(handles.ListPairMode,'Visible','on')
    set(handles.RootFile_1,'Visible','Off');
    set(handles.sub_txt,'Visible','off')
    set(handles.RootFile_1,'String',[]);
    mode_store=get(handles.ListCompareMode,'UserData');
    set(handles.ListPairMode,'Value',1)
    set(handles.ListPairMode,'String',mode_store)
    set(handles.CheckStereo,'Value',0)
    set(handles.ListPairMode,'Value',1) % mode 'civX' selected by default
end
ListPairMode_Callback(hObject, eventdata, handles)


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
if strcmp(compare,'displacement')||strcmp(compare,'shift')
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
TimeUnit=get(handles.TimeUnit,'String');
checkframe=strcmp(TimeUnit,'frame');
siztime=size(time);
nbfield=siztime(1)-1;
nbfield2=siztime(2)-1;
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
            if size(time,2)>1 && ~checkframe
                dt(numod_a,numod_b)=time(ref_i+1,numod_b+1)-time(ref_i+1,numod_a+1);%first time interval dt
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
    enable_j(handles, 'off')
elseif isequal(mode,'series(Dj)') %| isequal(mode,'st_series(Dj)')
    index=1:200;
    displ_num(1,index)=-floor(index/2);
    displ_num(2,index)=ceil(index/2);
    displ_num(3:4,index)=zeros(2,200);
    enable_j(handles, 'on')
elseif isequal(mode,'series(Di)') %| isequal(mode,'st_series(Di)')
    index=1:200;
    displ_num(1:2,index)=zeros(2,200);
    displ_num(3,index)=-floor(index/2);
    displ_num(4,index)=ceil(index/2);
    enable_i(handles, 'on')
    if nbfield2 > 1
        enable_j(handles, 'on')
    else
        enable_j(handles, 'off')
    end
elseif isequal(mode,'displacement')%the pairs have the same indices
    displ_num(1,1)=0;
    displ_num(2,1)=0;
    displ_num(3,1)=0;
    displ_num(4,1)=0;
    if nbfield > 1 || nbfield==0
        enable_i(handles, 'on')
    else
        enable_j(handles, 'off')
    end
    if nbfield2 > 1
        enable_j(handles, 'on')
    else
        enable_j(handles, 'off')
    end
end
set(handles.ListPairCiv1,'UserData',displ_num);
errormsg=find_netcpair_civ( handles,1);
    if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end
% find_netcpair_civ2(handles)

function enable_i(handles, state)
set(handles.itext,'Visible',state)
set(handles.first_i,'Visible',state)
set(handles.last_i,'Visible',state)
set(handles.incr_i,'Visible',state)
set(handles.nb_field,'Visible',state)
set(handles.ref_i,'Visible',state)

function enable_j(handles, state)
set(handles.jtext,'Visible',state)
set(handles.first_j,'Visible',state)
set(handles.last_j,'Visible',state)
set(handles.incr_j,'Visible',state)
set(handles.nb_field2,'Visible',state)
set(handles.ref_j,'Visible',state)


%------------------------------------------------------------------------
% --- Executes on selection change in ListPairCiv1.
function ListPairCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%reproduce by default the chosen pair in the checkciv2 menu
list_pair=get(handles.ListPairCiv1,'String');%get the menu of image pairs
index_pair=get(handles.ListPairCiv1,'Value');
displ_num=get(handles.ListPairCiv1,'UserData');
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
errormsg=find_netcpair_civ(handles,1);% update the menu of pairs depending on the available netcdf files
if isequal(mode,'series(Di)') || ...% we do patch2 only
        (get(handles.CheckCiv2,'Value')==0 && get(handles.CheckCiv1,'Value')==0 && get(handles.CheckFix1,'Value')==0 && get(handles.CheckPatch1,'Value')==0)
    errormsg=find_netcpair_civ( handles,2);
end
    if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end

%------------------------------------------------------------------------
function ref_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.ListPairMode,'String');
mode_value=get(handles.ListPairMode,'Value');
mode=mode_list{mode_value};
if isequal(get(handles.CheckCiv1,'Value'),0)|| isequal(mode,'series(Dj)')
    errormsg=find_netcpair_civ(handles,1);% update the menu of pairs depending on the available netcdf files
end
if isequal(mode,'series(Dj)') || ...
        (get(handles.CheckCiv2,'Value')==0 && get(handles.CheckCiv1,'Value')==0 && get(handles.CheckFix1,'Value')==0 && get(handles.CheckPatch1,'Value')==0)
    errormsg=find_netcpair_civ(handles,2);
end
    if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end

%------------------------------------------------------------------------
% determine the menu for checkciv1 pairs depending on existing netcdf file at the middle of
% the field series set by first_i, incr, last_i
% index=1: look for pairs for civ1
% index=2: look for pairs for civ2
function errormsg=find_netcpair_civ(handles,index)
%------------------------------------------------------------------------
set(gcf,'Pointer','watch')% set the mouse pointer to 'watch' (clock)

%% initialisation
errormsg='';
browse=get(handles.RootPath,'UserData');
compare_list=get(handles.ListCompareMode,'String');
val=get(handles.ListCompareMode,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')||strcmp(compare,'shift')
    mode='displacement';
else
    mode_list=get(handles.ListPairMode,'String');
    mode_value=get(handles.ListPairMode,'Value');
    if isempty(mode_list)
        return
    end
    mode=mode_list{mode_value};
end
nom_type_ima=get(handles.NomType,'String');

%% determine nom_type_nc, nomenclature type of the .nc files:
[nom_type_nc]=nomtype2pair(nom_type_ima,mode);

%% reads .nc subdirectoy and image numbers from the interface
SubDirImages=get(handles.SubDirImages,'String');
subdir_civ1=[SubDirImages get(handles.SubdirCiv1,'String')];%subdirectory subdir_civ1 for the netcdf data
subdir_civ2=[SubDirImages get(handles.SubdirCiv2,'String')];%subdirectory subdir_civ2 for the netcdf data
ref_i=str2double(get(handles.ref_i,'String'));
ref_j=[];
if isequal(mode,'pair j1-j2')%|isequal(mode,'st_pair j1-j2')
    ref_j=0;
elseif strcmp(get(handles.ref_j,'Visible'),'on')
    ref_j=str2double(get(handles.ref_j,'String'));
end
if isempty(ref_j)
    ref_j=1;
end
time=get(handles.ImaDoc,'UserData');%get the set of times
TimeUnit=get(handles.TimeUnit,'String');
checkframe=strcmp(TimeUnit,'frame');
displ_num=get(handles.ListPairCiv1,'UserData');

%% eliminate the first pairs inconsistent with the position
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

%% case with no Civ1 operation, netcdf files need to exist for reading
displ_pair={''};
select=ones(size(1:nbpair));%flag for displayed pairs =1 for display
testpair=0;
RootPath=get(handles.RootPath,'String');
RootFile=get(handles.RootFile,'String');
if index==1 % case civ1
    if ~get(handles.CheckCiv1,'Value') %
        if ~exist(fullfile(RootPath,subdir_civ1),'dir')
            errormsg=['no civ1 file available: subdirectory ' subdir_civ1 ' does not exist'];
            set(handles.ListPairCiv1,'String',{});
            return
        end
        for ipair=1:nbpair
            filename=fullfile_uvmat(RootPath,subdir_civ1,RootFile,'.nc',nom_type_nc,...
                ref_i+displ_num(3,ipair),ref_i+displ_num(4,ipair),ref_j+displ_num(1,ipair),ref_j+displ_num(2,ipair));
            select(ipair)=exist(filename,'file')==2;% put flag to 0 if the file does not exist
        end
        % case of no displayed pair
        if isequal(select,zeros(size(1:nbpair)))
            if isfield(browse,'incr_pair') && ~isequal(browse.incr_pair,[0 0])
                num_i1=ref_i-floor(browse.incr_pair(1)/2);
                num_i2=ref_i+ceil(browse.incr_pair(1)/2);
                num_j1=ref_j-floor(browse.incr_pair(2)/2);
                num_j2=ref_j+ceil(browse.incr_pair(2)/2);
                filename=fullfile_uvmat(RootPath,subdir_civ1,RootFile,'.nc',nom_type_nc,num_i1,num_i2,num_j1,num_j2);
                select(1)=exist(filename,'file')==2;
                testpair=1;
            else
%                 if  isequal(mode,'series(Dj)')% | isequal(mode,'st_series(Dj)')
%                     errormsg=['no civ1 file available for the selected reference index j=' num2str(ref_j) ' and subdirectory ' subdir_civ1];
%                 else
                    errormsg=['no civ1 file available for the selected reference indices (i,j)= ' num2str(ref_i) ', ' num2str(ref_j) ' and subdirectory ' subdir_civ1];
%                 end
                set(handles.ListPairCiv1,'String',{''});
                %COMPLETER CAS STEREO
                return
            end
        end
    end
else %case civ2 alone
    if ~get(handles.CheckCiv2,'Value') && ~get(handles.CheckCiv1,'Value') && ~get(handles.CheckFix1,'Value') && ~get(handles.CheckPatch1,'Value')
        if ~exist(fullfile(RootPath,subdir_civ2),'dir')
            msgbox_uvmat('ERROR',['no civ2 file available: subdirectory ' subdir_civ2 ' does not exist'])
            set(handles.ListPairCiv2,'Value',1);
            set(handles.ListPairCiv2,'String',{''});
            return
        end
        for ipair=1:nbpair
            filename=fullfile_uvmat(RootPath,subdir_civ1,RootFile,'.nc',nom_type_nc,...
                ref_i+displ_num(3,ipair),ref_i+displ_num(4,ipair),ref_j+displ_num(1,ipair),ref_j+displ_num(2,ipair));
            select(ipair)=exist(filename,'file')==2;
        end
        if  isequal(select,zeros(size(1:nbpair)))
            if isfield(browse,'incr_pair')
                num_i1=ref_i-floor(browse.incr_pair(1)/2);
                num_i2=ref_i+floor((browse.incr_pair(1)+1)/2);
                num_j1=ref_j-floor(browse.incr_pair(2)/2);
                num_j2=ref_j+floor((browse.incr_pair(2)+1)/2);
                filename=fullfile_uvmat(RootPath,subdir_civ2,RootFile,'.nc',nom_type_nc,num_i1,num_i2,num_j1,num_j2);
                select(1)=exist(filename,'file')==2;
            else
                if  isequal(mode,'series(Dj)')% | isequal(mode,'st_series(Dj)')
                    errormsg=['no civ2 file available for the selected reference index j=' num2str(ref_j) ' and subdirectory ' subdir_civ2];
                else
                    errormsg=['no civ2 file available for the selected reference index i=' num2str(ref_i) ' and subdirectory ' subdir_civ2];
                end
                set(handles.ListPairCiv2,'Value',1);
                set(handles.ListPairCiv2,'String',{''});
                return
            end
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
                %if ~checkframe && size(time,1)>=ref_i+1+displ_num(4,ipair) && size(time,2)>=ref_j+1+displ_num(2,ipair)&&displ_num(2,ipair)>=1 &&displ_num(1,ipair)>=1
                 %   dt=time(ref_i+1+displ_num(4,ipair),ref_j+1+displ_num(2,ipair))-time(ref_i+1+displ_num(3,ipair),ref_j+1+displ_num(1,ipair));%time interval dt
               if ~checkframe && size(time,1)>=ref_i+1+ceil(ipair/2) && size(time,2)>=ref_j+1&& ref_i-floor(ipair/2)>=0 && ref_j>=0
                 dt=time(ref_i+1+ceil(ipair/2),ref_j+1)-time(ref_i+1-floor(ipair/2),ref_j+1);%time interval dtref_j+1
                else
                    dt=1;
                end
                 displ_pair{ipair}=[displ_pair{ipair} ' :dt= ' num2str(dt*1000)];
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
                if ~checkframe && size(time,1)>=ref_i+1+displ_num(4,ipair) && size(time,2)>=ref_j+1+displ_num(2,ipair)
                    dt=time(ref_i+1+displ_num(4,ipair),ref_j+1+displ_num(2,ipair))-time(ref_i+1+displ_num(3,ipair),ref_j+1+displ_num(1,ipair));%time interval dt
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
            if ~checkframe && size(time,2)>1 
            dt=time(ref_i+1+displ_num(4,ipair),displ_num(2,ipair)+1)-time(ref_i+1+displ_num(3,ipair),displ_num(1,ipair)+1);%time interval dt
            else % time set by default to i index
                dt=1;
            end
            displ_pair{ipair}=['j= ' num2stra(displ_num(1,ipair),nom_type_ima) '-' num2stra(displ_num(2,ipair),nom_type_ima) ...
                ' :dt= ' num2str(dt*1000)];
        else
            displ_pair{ipair}='...'; %pair not displayed in the menu
        end
    end
elseif isequal(mode,'displacement')
    displ_pair={'Di=Dj=0'};
end
if index==1
set(handles.ListPairCiv1,'String',displ_pair');
end

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


    
% %------------------------------------------------------------------------   
% % call 'view_field.fig' to display the  field selected in the list of 'status'
% function open_view_field(hObject, eventdata)
% %------------------------------------------------------------------------
% list=get(hObject,'String');
% index=get(hObject,'Value');
% rootroot=get(hObject,'UserData');
% filename=list{index};
% ind_dot=strfind(filename,'...');
% filename=filename(1:ind_dot-1);
% filename=fullfile(rootroot,filename);
% delete(get(hObject,'parent'))%delete the display figure to stop the check process
% if exist(filename,'file')%visualise the vel field if it exists
%     uvmat(filename)
%     set(gcbo,'Value',1)
% end


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
% --- Executes on button press in SearchRange: determine the search range num_SearchBoxSize_1,num_SearchBoxSize_2
function SearchRange_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%determine pair numbers
if strcmp(get(handles.num_UMin,'Visible'),'off')
    set(handles.u_title,'Visible','on')
    set(handles.v_title,'Visible','on')
    set(handles.num_UMin,'Visible','on')
    set(handles.num_UMax,'Visible','on')
    set(handles.num_VMin,'Visible','on')
    set(handles.num_VMax,'Visible','on')
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
% ---  determine the search range num_SearchBoxSize_1,num_SearchBoxSize_2 and shift
function get_search_range(hObject, eventdata, handles)
%------------------------------------------------------------------------
param_civ1=read_GUI(handles.Civ1);
umin=param_civ1.UMin;
umax=param_civ1.UMax;
vmin=param_civ1.VMin;
vmax=param_civ1.VMax;
%switch min_title and max_title in case of error
if umax<=umin
    umin_old=umin;
    umin=umax;
    umax=umin_old;
    set(handles.num_UMin,'String', num2str(umin))
    set(handles.num_UMax,'String', num2str(umax))
end
if vmax<=vmin
    vmin_old=vmin;
    vmin=vmax;
    vmax=vmin_old;
    set(handles.num_VMin,'String', num2str(vmin))
    set(handles.num_VMax,'String', num2str(vmax))
end   
if ~(isempty(umin)||isempty(umax)||isempty(vmin)||isempty(vmax))
    list_pair=get(handles.ListPairCiv1,'String');%get the menu of image pairs
    index=get(handles.ListPairCiv1,'Value');
    pair_string=list_pair{index};
    time=get(handles.ImaDoc,'UserData'); %get the set of times
    pxcm=get(handles.SearchRange,'UserData');
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
                r=regexp(pair_string,'(?<mode>(Di=)|(Dj=)) -*(?<num1>\d+)\|(?<num2>\d+)','names');
        if isempty(r)
            r=regexp(pair_string,'(?<num1>\d+)(?<mode>-)(?<num2>\d+)','names');
        end  
        num_a=str2num(r.num1);
        num_b=str2num(r.num2);
    end
    dt=time(num2+1,num_b+1)-time(num1+1,num_a+1);
    ibx=str2double(get(handles.num_CorrBoxSize_1,'String'));
    iby=str2double(get(handles.num_CorrBoxSize_2,'String'));
    umin=dt*pxcm*umin;
    umax=dt*pxcm*umax;
    vmin=dt*pxcm*vmin;
    vmax=dt*pxcm*vmax;
    shiftx=round((umin+umax)/2);
    shifty=round((vmin+vmax)/2);
    isx=(umax+2-shiftx)*2+param_civ1.Bx;
    isx=2*ceil(isx/2)+1;
    isy=(vmax+2-shifty)*2+param_civ1.Bx;
    isy=2*ceil(isy/2)+1;
    set(handles.num_SearchBoxShift_1,'String',num2str(shiftx));
    set(handles.num_SearchBoxShift_2,'String',num2str(shifty));
    set(handles.num_SearchBoxSize_1,'String',num2str(isx));
    set(handles.num_SearchBoxSize_2,'String',num2str(isy));
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
    set(handles.Mask,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootPath,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.ListCompareMode,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.RootFile_1,'String');
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
    set(handles.Mask,'String',mask_displ)
    set(handles.Mask,'String',mask_displ)
    set(handles.Mask,'String',mask_displ)
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckMask: select box for mask option
function get_mask_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.CheckMask,'Value');
if isequal(maskval,0)
    set(handles.Mask,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootPath,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.ListCompareMode,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.RootFile_1,'String');
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
    set(handles.Mask,'String',mask_displ)
    set(handles.Mask,'String',mask_displ)
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckMask.
function get_mask_fix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.CheckMask,'Value');
if isequal(maskval,0)
    set(handles.Mask,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootPath,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.ListCompareMode,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.RootFile_1,'String');
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
    set(handles.Mask,'String',mask_displ)
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

% subdir=get(handles.SubdirCiv1,'String');
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

% %------------------------------------------------------------------------
% % --- Executes on button press in ListSubdirCiv1.
% function ListSubdirCiv1_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% list_subdir_civ1=get(handles.ListSubdirCiv1,'String');
% val=get(handles.ListSubdirCiv1,'Value');
% SubDir=list_subdir_civ1{val};
% if strcmp(SubDir,'new...')
%     if get(handles.CheckCiv1,'Value')
%         SubDir='CIV'; %default subdirectory
%     else
%         msgbox_uvmat('ERROR','select CheckCiv1 to perform a new Civ operation')
%         return
%     end    
% end
% set(handles.SubdirCiv1,'String',SubDir);
% errormsg=find_netcpair_civ(handles,1);
% if ~isempty(errormsg)
%     msgbox_uvmat('ERROR',errormsg)
% end
%     
%------------------------------------------------------------------------
% % --- Executes on button press in ListSubdirCiv2.
% function ListSubdirCiv2_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% list_subdir_civ2=get(handles.ListSubdirCiv2,'String');
% val=get(handles.ListSubdirCiv2,'Value');
% SubDir=list_subdir_civ2{val};
% if strcmp(SubDir,'new...')
%     if get(handles.CheckCiv2,'Value')
%         SubDir='CIV'; %default subdirectory
%     else
%         msgbox_uvmat('ERROR','select CheckCiv2 to perform a new Civ operation')
%         return
%     end
% end
% set(handles.SubdirCiv2,'String',SubDir);

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
    filebase=get(handles.RootPath,'String');
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
PanelName=get(hparent,'tag');
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
% --- Executes on button press in CheckMask: common to all panels (civ1, Civ2..)
function CheckMask_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
value=get(hObject,'Value');
hparent=get(hObject,'parent');
parent_tag=get(hparent,'Tag');
hchildren=get(hparent,'children');
handle_txtbox=findobj(hchildren,'tag','Mask');% look for the mask name box in the same panel
testmask=0;
if value
    filebase=get(handles.RootPath,'String');
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
    if strcmp(parent_tag,'Civ1')
        set(handles.Mask,'Visible','on')
        set(handles.Mask,'String',filemask)
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
%     set(handles.Mask(stage:end),'Visible','on')
%     set(handles.Mask(stage:end),'String',filemask)
%     set(handles.CheckMask(stage:end),'Value',1)
else
    set(hObject,'Value',0);
    set(handle_txtbox,'Visible','off')
end


% --- Executes on button press in get_gridpatch1.
function get_gridpatch1_Callback(hObject, eventdata, handles)
filebase=get(handles.RootPath,'String');
[FileName, PathName, filterindex] = uigetfile( ...
    {'*.grid', ' (*.grid)';
    '*.grid',  '.grid files '; ...
    '*.*', 'All Files (*.*)'}, ...
    'Pick a file',filebase);
filegrid=fullfile(PathName,FileName);
set(handles.grid_patch1,'string',filegrid);


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

% %------------------------------------------------------------------------
% %--read images and convert them to the uint16 format used for PIV
% function A=read_image(filename,type_ima,num,movieobject)
% %------------------------------------------------------------------------
% %num is the view number needed for an avi movie
% switch type_ima
%     case 'movie'
%         A=read(movieobject,num);
%     case 'avi'
%         mov=aviread(filename,num);
%         A=frame2im(mov(1));
%     case 'multimage'
%         A=imread(filename,num);
%     case 'image'
%         A=imread(filename);
% end
% siz=size(A);
% if length(siz)==3;%color images
%     A=sum(double(A),3);
%     A=uint16(A);
% end


%------------------------------------------------------------------------
% --- Executes on button press in get_ref_fix1.
function get_ref_fix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
filebase=get(handles.RootPath,'String');
[FileName, PathName, filterindex] = uigetfile( ...
    {'*.nc', ' (*.nc)';
    '*.nc',  'netcdf files '; ...
    '*.*', 'All Files (*.*)'}, ...
    'Pick a file',filebase);

fileinput=[PathName FileName];
sizf=size(fileinput);
if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
%[Path,File,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
[Path,ref.subdir,File,ref.num1,ref.num2,ref.num_a,ref.num_b,ref.ext,ref.nom_type]=fileparts_uvmat(fileinput);
ref.filebase=fullfile(Path,File);
% ref.num_a=stra2num(str_a);
% ref.num_b=stra2num(str_b);
% ref.num1=str2double(field_count);
% ref.num2=str2double(str2);
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
    filebase=get(handles.RootPath,'String');
    [FileName, PathName, filterindex] = uigetfile( ...
        {'*.nc', ' (*.nc)';
        '*.nc',  'netcdf files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',filebase);
    fileinput=[PathName FileName];
    sizf=size(fileinput);
    if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
    %[Path,File,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
    [Path,ref.subdir,File,ref.num1,ref.num2,ref.num_a,ref.num_b,ref.ext,ref.nom_type]=fileparts_uvmat(fileinput);
    ref.filebase=fullfile(Path,File);
%     ref.num_a=stra2num(str_a);
%     ref.num_b=stra2num(str_b);
%     ref.num1=str2num(field_count);
%     ref.num2=str2num(str2);
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
% --- TO ABANDON Executes on button press in test_stereo1.
function CheckStereo_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
hparent=get(hObject,'parent');
parent_tag=get(hparent,'Tag');
hchildren=get(hparent,'children');
handle_txtbox=findobj(hchildren,'tag','txt_Mask');
if isequal(get(hObject,'Value'),0)
    set(handles.num_SubdomainSize,'Visible','on')
    set(handles.num_FieldSmooth,'Visible','on')
else
    set(handles.num_SubdomainSize,'Visible','off')
    set(handles.num_FieldSmooth,'Visible','off')
end

% %------------------------------------------------------------------------
% % --- Executes on button press in CheckStereo.
% function StereoCheck_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% if isequal(get(handles.CheckStereo,'Value'),0)
%     set(handles.num_SubdomainSize,'Visible','on')
%     set(handles.num_FieldSmooth,'Visible','on')
% else
%     set(handles.num_SubdomainSize,'Visible','off')
%     set(handles.num_FieldSmooth,'Visible','off')
% end

%------------------------------------------------------------------------
% --- Executes on button press in TestCiv1: prepare the image correlation function
% activated by mouse motion
function TestCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
drawnow
if get(handles.TestCiv1,'Value')
    set(handles.TestCiv1,'BackgroundColor',[0.7 0.7 0.7])% paint TestCiv1 button to grey to confirm civ launch
    ref_i=str2double(get(handles.ref_i,'String'));% read reference i index
    if strcmp(get(handles.ref_j,'Visible'),'on')
        ref_j=str2double(get(handles.ref_j,'String'));% read reference j index if relevant
    else
        ref_j=1;%default j index
    end
    [filecell,i1,i2]=set_civ_filenames(handles,ref_i,ref_j,[1 0 0 0 0 0]);% get the corresponding file name and indices
    Data.ListVarName={'ny','nx','A'};
    Data.VarDimName= {'ny','nx',{'ny','nx'}};

    Data.A=imread(filecell.ima1.civ1{1}); % read the first image
    if ndims(Data.A)==3 %case of color image
        Data.VarDimName= {'ny','nx',{'ny','nx','rgb'}};
    end
    Data.ny=[size(Data.A,1) 1];
    Data.nx=[1 size(Data.A,2)];
    Data.CoordUnit='pixel';% used to set equal scaling for x and y in image dispaly
    par_civ1=read_GUI(handles.Civ1);
    par_civ1.FileTypeA=get_file_type(filecell.ima1.civ1{1});
    par_civ1.ImageWidth=size(Data.A,2);
    par_civ1.ImageHeight=size(Data.A,1);
    par_civ1.Mask='all';% will provide only the grid set for PIV, no image correlation
    par_civ1.FrameIndexA=num2str(i1);
    par_civ1.FrameIndexB=num2str(i2);
    Param.Civ1=par_civ1;
    Grid=civ_matlab(Param);% get the grid of x, y positions set for PIV 
    hview_field=view_field(Data); %view the image in the GUI view_field
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
    set(handles.TestCiv1,'BackgroundColor',[1 0 0])% paint button to red
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
%----function introduced for the correlation window figure, activated by deleting this window
function closeview_field(gcbo,eventdata)
%------------------------------------------------------------------------
hview_field=findobj(allchild(0),'tag','view_field');% look for view_field
if ~isempty(hview_field)
    delete(hview_field)
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




%'nomtype2pair': creates nomencalture for index pairs knowing the image nomenclature
%---------------------------------------------------------------------
function NomTypeNc=nomtype2pair(NomTypeIma,mode)
%---------------------------------------------------------------------           
% OUTPUT:
% NomTypeNc
%---------------------------------------------------------------------
% INPUT:
% 'NomTypeIma': string defining the kind of nomenclature used for images

NomTypeNc=NomTypeIma;%default
switch mode
    case 'pair j1-j2'      
    if ~isempty(regexp(NomTypeIma,'a$'))
        NomTypeNc=[NomTypeIma 'b'];
    elseif ~isempty(regexp(NomTypeIma,'A$'))
        NomTypeNc=[NomTypeIma 'B'];
    else
        r=regexp(NomTypeIma,'(?<num1>\d+)_(?<num2>\d+)$','names');
        if ~isempty(r)
            NomTypeNc='_1_1-2';
        end
    end
    case 'series(Dj)'  
%         r=regexp(NomTypeIma,'(?<num1>\d+)_(?<num2>\d+)$','names');
%         if ~isempty(r)
            NomTypeNc='_1_1-2';
%         end
   case 'series(Di)'
        r=regexp(NomTypeIma,'(?<num1>\d+)_(?<num2>\d+)$','names');
        if ~isempty(r)
            NomTypeNc='_1-2_1';
        else
            NomTypeNc='_1-2';
        end
end

function NomType_Callback(hObject, eventdata, handles)
set(handles.RootPath,'BackgroundColor',[1 1 0])%paint RootName edit box in yellow to indicate that the file input is proceeding
RootPath=get(handles.RootPath,'String');
RootFile=get(handles.RootFile,'String');
SubDirImages=get(handles.SubDirImages,'String');
ref_i=str2num(get(handles.ref_i,'String'));
ref_j=str2num(get(handles.ref_j,'String'));
NomType=get(handles.NomType,'String');
ImaExt=get(handles.ImaExt,'String');
fileinput=fullfile_uvmat(RootPath,SubDirImages,RootFile,ImaExt,NomType,ref_i,[],ref_j);
errormsg=display_file_name(handles,fileinput);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
end
set(handles.RootPath,'BackgroundColor',[1 1 1])%paint RootName back to white to indicate that the file input is finished

% --- Executes on selection change in Program.
function Program_Callback(hObject, eventdata, handles)
ListProgram=get(handles.Program,'String');
Program=ListProgram{get(handles.Program,'value')};
switch Program
    case 'CivX'
        set(handles.num_MaxDiff,'Visible','off')
        set(handles.num_MaxVel,'Visible','off')
        set(handles.title_MaxVel,'Visible','off')
        set(handles.num_Nx,'Visible','on')
        set(handles.num_Ny,'Visible','on')
        set(handles.title_Nx,'Visible','on')
        set(handles.title_Ny,'Visible','on')
        set(handles.title_MaxDiff,'Visible','off')
        set(handles.num_CorrSmooth,'Style','edit')
        set(handles.num_CorrSmooth,'String','1')
        set(handles.BATCH,'Enable','on')
        set(handles.CheckThreshold,'Visible','off')
        set(handles.CheckDeformation,'Value',1)
        set(handles.CheckDecimal,'Value',1)
    case {'civ_matlab','civ_matlab.sh'}
        set(handles.num_MaxDiff,'Visible','on')
        set(handles.num_MaxVel,'Visible','on')
        set(handles.title_MaxVel,'Visible','on')
        set(handles.title_MaxDiff,'Visible','on')
        set(handles.num_Nx,'Visible','off')
        set(handles.num_Ny,'Visible','off')
        set(handles.title_Nx,'Visible','off')
        set(handles.title_Ny,'Visible','off')
        set(handles.num_CorrSmooth,'Style','popupmenu')
        set(handles.num_CorrSmooth,'Value',1)
        set(handles.num_CorrSmooth,'String',{'1';'2'})
        set(handles.CheckThreshold,'Visible','on')
        set(handles.CheckDeformation,'Value',0)% desactivate (work in progress)
        set(handles.CheckDecimal,'Value',0)% desactivate (work in progress)
end

% --- Executes on button press in TestPatch1.
function TestPatch1_Callback(hObject, eventdata, handles)
set(handles.TestPatch1,'BackgroundColor',[1 1 0])
drawnow
if get(handles.TestPatch1,'Value')
    ref_i=str2double(get(handles.ref_i,'String'));
    if strcmp(get(handles.ref_j,'Visible'),'on')
        ref_j=str2double(get(handles.ref_j,'String'));
    else
        ref_j=1;%default
    end
    filecell=set_civ_filenames(handles,ref_i,ref_j,[0 0 1 0 0 0]);    
    Data.ListVarName={'ny','nx','A'};
    Data.VarDimName= {'ny','nx',{'ny','nx'}};   
    param_patch1=read_GUI(handles.Patch1);
    param_patch1.CivFile=filecell.nc.civ1{1};
    Param.Patch1=param_patch1;
    for irho=1:7
        [Data,errormsg]=civ_matlab(Param);% get the grid of x, y positions set for PIV
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',errormsg)
            return
        end
        SmoothingParam(irho)=Param.Patch1.FieldSmooth;
        Data.Civ1_U_Diff=Data.Civ1_U_Diff(Data.Civ1_FF==0);
        Data.Civ1_V_Diff=Data.Civ1_V_Diff(Data.Civ1_FF==0);
        DiffVel(irho)=sqrt(mean(Data.Civ1_U_Diff.*Data.Civ1_U_Diff+Data.Civ1_V_Diff.*Data.Civ1_V_Diff))
        NbSites(irho,:)=Data.Civ1_NbSites*numel(Data.Civ1_NbSites)/numel(Data.Civ1_U_Diff);
        Param.Patch1.SmoothingParam=2*Param.Patch1.FieldSmooth;
    end
    figure
    plot(SmoothingParam,DiffVel,'b',SmoothingParam,NbSites,'r')
    set(handles.TestPatch1,'BackgroundColor',[1 0 0])
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


% --- Executes on button press in TestCiv2.
function TestCiv2_Callback(hObject, eventdata, handles)

function RootFile_Callback(hObject, eventdata, handles)

function SubDirImages_Callback(hObject, eventdata, handles)



function errormsg=write_param(Param)
%------------------------------------------------------------------------
%pixels per cm and matrix of the image times, read from the .civ file by uvmat
%changes : filename_cmx -> filename ( no extension )
errormsg='';
switch Param.Program
    case 'CivX'
        if Param.CheckCiv1
            filename=regexprep(Param.OutputFile,'(.+)([/\\])(.+$)','$1$20_CMX$2$3.civ1.cmx');
            if isequal(Param.Civ1.Dt,0)
                Param.Civ1.Dt=1 ;%case of 'displacement' mode
            end
            Param.Civ1.ImageA=regexprep(Param.Civ1.ImageA,'.png','');
            Param.Civ1.ImageB=regexprep(Param.Civ1.ImageB,'.png','');
            [fid,errormsg]=fopen(filename,'w');
            if isequal(fid,-1)
                errormsg=['cmd file ' filename ' cannot be created: ' errormsg];
                return
            end
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
            fprintf(fid,   ['CorrelationBoxesSize ' num2str(Param.Civ1.CorrBoxSize(1)) ' ' num2str(Param.Civ1.CorrBoxSize(2)) '\n' ]);
            fprintf(fid,   ['SearchBoxeSize ' num2str(Param.Civ1.SearchBoxSize(1)) ' ' num2str(Param.Civ1.SearchBoxSize(2)) '\n' ]);
            fprintf(fid,   ['RO ' num2str(Param.Civ1.CorrSmooth) '\n' ]);
            if isfield(Param.Civ1,'Grid')
                fprintf(fid,   ['GridSpacing ' '25' ' ' '25' '\n' ]);
            else
                fprintf(fid,   ['GridSpacing ' num2str(Param.Civ1.Dx) ' ' num2str(Param.Civ1.Dy) '\n' ]);
            end
            fprintf(fid,   ['XX 1.0' '\n' ]);
            fprintf(fid,   ['Dt_TO ' num2str(Param.Civ1.Dt) ' ' num2str(Param.Civ1.Time) '\n' ]);
            fprintf(fid,  ['PixCmXY ' '1' ' ' '1' '\n' ]);
            fprintf(fid,  ['XX 1' '\n' ]);
            fprintf(fid,   ['ShiftXY ' num2str(Param.Civ1.SearchBoxShift(1)) ' '  num2str(Param.Civ1.SearchBoxShift(2)) '\n' ]);
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
        end
        
        if Param.CheckCiv2
            filename=regexprep(Param.OutputFile,'(.+)([/\\])(.+$)','$1$20_CMX$2$3.civ2.cmx');

            if isequal(Param.Civ2.Dt,'0')
                Param.Civ2.Dt='1' ;%case of 'displacement' mode
            end
            Param.Civ2.ImageA=regexprep(Param.Civ2.ImageA,'.png','');
            Param.Civ2.ImageB=regexprep(Param.Civ2.ImageB,'.png','');% bug : .png appears two times ?
            [fid,errormsg]=fopen(filename,'w');
            if isequal(fid,-1)
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
            fprintf(fid, ['CorrelationBoxesSize ' num2str(Param.Civ2.CorrBoxSize(1)) ' ' num2str(Param.Civ2.CorrBoxSize(2)) '\n' ]);
            fprintf(fid, ['SearchBoxeSize ' num2str(Param.Civ2.CorrBoxSize(1)) ' ' num2str(Param.Civ2.CorrBoxSize(2)) '\n']);
            fprintf(fid, ['RO ' num2str(Param.Civ2.CorrSmooth) '\n']);
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
        end
    case {'civ_matlab','civ_matlab.sh'}
        filename=regexprep(Param.OutputFile,'(.+)([/\\])(.+$)','$1$20_XML$2$3.xml');
        save(struct2xml(Param),filename);
end


function cmd=write_cmd(Param)

% initiate system command
cmd=[];

switch Param.Program
    case 'CivX'
        if isunix % check: necessaire aussi en RUN?
            cmd=[cmd '#!/bin/bash \n'...
                '#$ -cwd \n'...
                'hostname && date \n'...
                'umask 002 \n'];%allow writting access to created files for user group
        end
    case 'CivAll'
        if isunix % check: necessaire aussi en RUN?
            cmd=[cmd '#!/bin/bash \n'...
                '#$ -cwd \n'...
                'hostname && date \n'...
                'umask 002 \n'];%allow writting access to created files for user group
        end
end

filename=regexprep(Param.OutputFile,'.nc','');

if Param.CheckCiv1
    switch Param.Program
        case 'CivX'
            if(isunix) %unix (or Mac) system
                cmd=[cmd 'cp -f ' regexprep(filename,'(.+)/(.+$)','$1/0_CMX/$2.civ1.cmx ') regexprep(filename,'(.+)/(.+$)','$1/$2.cmx \n')...% the cmx file gives the name to the nc file
                    Param.xml.Civ1Bin ' -f ' regexprep(filename,'(.+)/(.+$)','$1/$2.cmx >') regexprep(filename,'(.+)/(.+$)','$1/0_LOG/$2.civ1.log \n')... % redirect standard output to the log file, the result file is named [filename '.nc'] by CIVx
                    'rm ' regexprep(filename,'(.+)/(.+$)','$1/$2.cmx \n')];
            else %Windows system
                filename=regexprep(filename,'\\','\\\\');
                cmd=['copy /Y ' regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\0_CMX\\\\$2.civ1.cmx" ') regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\$2.cmx" \n')...
                    '"' regexprep(Param.xml.Civ1Bin,'\\','\\\\') '" -f ' regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\$2.cmx" > ')...
                    regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\0_LOG\\\\$2.civ1.log" \n')... % redirect standard output to the log file
                    'del ' regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\$2.cmx" \n')];
            end
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
    switch Param.Program
        case 'CivX'
            cmd=[cmd...
                cmd_fix(Param,'Fix1') '\n'];
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
if Param.CheckPatch1
    switch Param.Program
        case 'CivX'
            cmd=[cmd...
                cmd_patch(Param,'Patch1') '\n'];
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
                        patch1.gridPatch=[filecell.filebase '_' fullfile_uvmat('','',gridname,'.grid','_1',i1_grid)];
                        %                                 patch1.gridPatch=[filecell.filebase '_' name_generator(gridname,i1_grid,1,'.grid','_i')];
                        if ~exist(patch1.gridPatch,'file')
                            errormsg='grid file absent for patch1';
                            return
                        end
                    elseif exist(gridname,'file')
                        patch1.gridPatch=gridname;
                    else
                        errormsg='grid file absent for patch1';
                        return
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

if Param.CheckCiv2
    switch Param.Program
        case 'CivX'
            if(isunix)
                cmd=[cmd 'cp -f '  regexprep(filename,'(.+)/(.+$)','$1/0_CMX/$2.civ2.cmx ') regexprep(filename,'(.+)/(.+$)','$1/$2.cmx \n')...
                    Param.xml.Civ2Bin ' -f ' regexprep(filename,'(.+)/(.+$)','$1/$2.cmx >') regexprep(filename,'(.+)/(.+$)','$1/0_LOG/$2.civ2.log \n')...% redirect standard output to the log file, the result file is named [filename '.nc'] by CIVx
                    'rm ' regexprep(filename,'(.+)/(.+$)','$1/$2.cmx \n')];%rename .cmx as .checkciv2.cmx, the result file is named [filename '.nc'] by CIVx
            else
                filename=regexprep(Param.OutputFile,'.nc','');
                filename=regexprep(filename,'\\','\\\\');
                cmd=[cmd 'copy /Y ' regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\0_CMX\\\\$2.civ2.cmx" ') regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\$2.cmx" \n')...
                    '"' regexprep(Param.xml.Civ2Bin,'\\','\\\\') '" -f ' regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\$2.cmx" > ')...
                     regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\0_LOG\\\\$2.civ2.log" \n')... % redirect standard output to the log file
                    'del ' regexprep(filename,'(.+)\\\\(.+$)','"$1\\\\$2.cmx" \n')];                       
            end
                 
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
    switch Param.Program
        case 'CivX'
            cmd=[cmd...
                cmd_fix(Param,'Fix2') '\n'];
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
    
    switch Param.Program
        
        case 'CivX'
            cmd=[cmd...
                cmd_patch(Param,'Patch2') '\n'];
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
                        patch2.gridPatch=[filecell.filebase '_' fullfile_uvmat('','',gridname,'.grid','_1',i1_grid)];
                        %                                 patch2.gridPatch=[filecell.filebase '_' name_generator(gridname,i1_grid,1,'.grid','_i')];
                        if ~exist(patch2.gridPatch,'file')
                            errormsg='grid file absent for patch2';
                            return
                        end
                    elseif exist(gridname,'file')
                        patch2.gridPatch=gridname;
                    else
                        errormsg='grid file absent for patch2';
                        return
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

switch Param.Program
    case 'CivAll'
        save(CivAllxml,[Param.OutputFile '.xml']);
        cmd=[cmd sparam.CivBin ' -f ' Param.OutputFile '.xml '  CivAllCmd ' >' Param.OutputFile '.log' '\n'];
    case 'civ_matlab'
                    switch computer
                        case {'PCWIN','PCWIN64'}                     
                            filename=regexprep(filename,'\\','\\\\');% add '\' so that '\' are left as characters
                                    cmd=['civ_matlab(''' regexprep(filename,'(.+)([/\\])(.+$)','$1$20_XML\\$2$3.xml') ''','''...
            filename '.nc'');'];
                        case {'GLNX86','GLNXA64','MACI64'}
                                    cmd=['civ_matlab(''' regexprep(filename,'(.+)([/\\])(.+$)','$1$20_XML$2$3.xml') ''','''...
            filename '.nc'');'];
                    end

        
    case 'civ_matlab.sh'
        CivmBin=fullfile(fileparts(which('civ')),'civ_matlab.sh'); %path to the source directory of uvmat
        switch computer
            case {'PCWIN','PCWIN64'}
                filename=regexprep(filename,'\\','\\\\');% add '\' so that '\' are left as characters
                % TODO launch command in DOS
            case {'GLNX86','GLNXA64','MACI64'}
                cmd=['#!/bin/bash \n '...
                    '#$ -cwd \n '...
                    'hostname && date \n '...
                    'umask 002 \n'...
                    CivmBin ' ' Param.xml.RunTime ' ' regexprep(filename,'(.+)([/\\])(.+$)','$1$20_XML$2$3.xml') ' ' Param.OutputFile '.nc'];%allow writting access to created files for user group
        end
end    
    

function cmd=cmd_fix(Param,fixname)
%%
switch fixname
    case 'Fix1'
        fi2_value=num2str(Param.(fixname).CheckF2);
        filename=regexprep(Param.OutputFile,'.nc','');
    case 'Fix2'
        fi2_value=num2str(Param.(fixname).CheckF4);%need to understand why...
        filename=regexprep(Param.OutputFile,'.nc','');        
end

% filename=regexprep(Param.(fixname).OutFileName,'.nc','');
MaskName_string='';%default
MaxVel_string='';%default
if ~isempty(Param.(fixname).MinVel)
    MaxVel_string=[' -threshV ' num2str(Param.(fixname).MinVel)];
end
if isunix
    cmd=[Param.xml.FixBin ' -f ' filename '.nc -fi1 ' num2str(Param.(fixname).CheckFmin2) ...
        ' -fi2 ' fi2_value ' -fi3 ' num2str(Param.(fixname).CheckF3) ...
        ' -threshC ' num2str(Param.(fixname).MinCorr) MaxVel_string MaskName_string...
        ' >' regexprep(filename,'(.+)/(.+$)','$1/0_LOG/$2.')  lower(fixname) '.log 2>&1'];
else
    cmd=['"' Param.xml.FixBin '" -f "' filename '.nc" -fi1 ' num2str(Param.(fixname).CheckFmin2)...
        ' -fi2 ' fi2_value ' -fi3 ' num2str(Param.(fixname).CheckF3) ...
        ' -threshC ' num2str(Param.(fixname).MinCorr) MaxVel_string MaskName_string...
        ' > "' regexprep(filename,'(\w+)\\(\w+$)','$1\\0_LOG\\$2.') lower(fixname) '.log"'];
    cmd=regexprep(cmd,'\\','\\\\');
end


function cmd=cmd_patch(Param,patchname)
%% ------------------------------------------------------------------------
switch patchname
    case 'Patch1'
        filename=regexprep(Param.OutputFile,'.nc','');
    case 'Patch2'
        filename=regexprep(Param.OutputFile,'.nc','');        
end
% filename=regexprep(Param.(patchname).OutFileName,'.nc','');
if isunix
    cmd=[Param.xml.PatchBin...
        ' -f ' filename '.nc -m ' num2str(Param.(patchname).Nx)...
        ' -n ' num2str(Param.(patchname).Ny) ' -ro ' num2str(Param.(patchname).FieldSmooth)...
        ' -nopt ' num2str(Param.(patchname).SubdomainSize) ...
        '  > ' regexprep(filename,'(.+)/(.+$)','$1/0_LOG/$2.')  lower(patchname) '.log 2>&1']; % redirect standard output to the log file
else
    cmd=['"' Param.xml.PatchBin...
        '" -f "' filename '.nc" -m ' num2str(Param.(patchname).Nx)...
        ' -n ' num2str(Param.(patchname).Ny) ' -ro ' num2str(Param.(patchname).FieldSmooth)...
        ' -nopt ' num2str(Param.(patchname).SubdomainSize)...
        '  > "' filename '.' lower(patchname) '.log" 2>&1']; % redirect standard output to the log file
    cmd=regexprep(cmd,'\\','\\\\');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USELESS FUNCTIONS BELOW HERE,  TO CLEAN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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


% --- Executes on selection change in RunMode.
function RunMode_Callback(hObject, eventdata, handles)


function nb_field2_Callback(hObject, eventdata, handles)


function last_j_Callback(hObject, eventdata, handles)


function last_i_Callback(hObject, eventdata, handles)
