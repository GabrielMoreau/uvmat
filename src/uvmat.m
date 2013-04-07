%'uvmat': function associated with the GUI 'uvmat.fig' for images and data field visualization 
%------------------------------------------------------------------------
% function huvmat=uvmat(input)
%
%OUTPUT
% huvmat=current handles of the GUI uvmat.fig
%%
%
%INPUT:
% input: input file name (if character chain), or input image matrix to
% visualize, or Matlab structure representing  netcdf fieldname (with fieldname
% ListVarName....)
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria,  2008, LEGI / CNRS-UJF-INPG, joel.sommeria@legi.grenoble-inp.fr.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This open is part of the toolbox UVMAT.
% 
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (open UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%
% Information stored on the interface:(use 'Export/field in workspace' in
% the menu bar of uvmat to retrieve it)
%          .OpenParam: structure containing parameters defined when uvmat is opened
%                       .PosColorbar: position (1x4 vector)of the colorbar (relative to the fig uvmat)
%                       .PosSetObject: position of set_object
%                       .PosGeometryCalib: size of set_object
%                       .NbBuiltin: nbre of functions always displayed in TransformName menu
%          .Object: cell array of structures representing the current projection objects, as produced by 'set_object.m'={[]} by default
%          .NewSeries: =0/1 flag telling whether a new field series has been opened
%          .FileName_1: name of the current second field (used to detect a  constant field during file scanning)
%          .FileType: current file type, as defined by the fct  get_file_type.m)
%          .i1_series,.i2_series,.j1_series,.j1_series: series of i1,i2,j1,j2 indices detected in the input dir,set by  the fct find_file_series
%          .MovieObject: current movie object
%          .TimeUnit: unit for time
%          .XmlData: cell array of 1 or 2 structures representing the xml files associated with the input fieldname (containing timing  and geometry calibration)
%          .Field: cell array of 1 or 2 structures representing the current  input field(s)
%          .PlotAxes: field structure representing the current field plotted  on the main axes  (used for mouse operations)
%          .HistoAxes: idem for histogram axes

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   DATA FLOW  (for run0_Callback) %%%%%%%%%%%%%%%%%%%%:
%
%
% 1) Input filenames are determined by MenuBrowse (first field), MenuBrowse_1
% (second field), or by the stored file name .FileName_1, or as an input of uvmat. 
% 2) These functions call 'uvmat/display_file_name.m' which detects the file series, and fills the file index boxes
% 3) Then 'uvmat/update_rootinfo.m' Updates information about a new field series (indices to scan, timing, calibration from an xml file)
% 4) Then fieldname are opened and visualised by the main sub-function 'uvmat/refresh_field.m'
% The function first reads the name of the input file(s) (one or two) from the edit boxes  of the GUI
% It then reads the input file(s) with the function read_field.m and perform the following list of operations:
%
%    %%%%%%%%  structure of uvmat/refresh_field.m %%%%%%%%
%
%           Main input open       second input open_1        
%                    |                   |  
%             read_field.m            read_field.m
%                    |                   |
%                 Field{1}            Field{2}               
%                    |                   |                                  
%                    --->transform fct<---             transform (e.g. phys.m) and combine input fieldname  
%                            |                                    
%                        (tps_coeff_field.m)               calculate tps coefficients (for filter projection or spatial derivatives).
%                            |
%                       UvData.Field-------------->histogram
%               _____________|____________
%              |                          |                    
%        proj_field.m               proj_field.m       project the field on the projection objects (use set_field_list.m)           
%              |                          |
%         UvData.PlotAxes          ViewData.PlotAxes (on view_field)
%              |                          |
%       plot_field.m (uvmat)       plot_field.m (view_field)      plot the projected fieldname
%
%
%%%%%%%%%%%%%%    SCALARS: %%%%%%%%%%%%??%%%
% scalars are displayed either as an image or countour plot, either as a color of
% velocity vectors. The scalar values in the first case is represented by
% UvData.Field.A, and by UvData.Field.C in the second case. The corresponding set of X
% and Y coordinates are represented by UvData.Field.AX and UvData.Field.AY, and .X and
% .Y for C (the same as velocity vectors). If A is a nxxny matrix (scalar
% on a regtular grid), then .AX andf.AY contains only two elements, represneting the
% coordinates of the four image corners. The scalar name is represented by
% the strings .AName and/or .CName.
% If the scalar exists in an input open (image or scalar stored under its
% name in a netcdf open), it is directly read at the level of Field{1}or Field{2}.
% Else only its name AName is recorded in Field{i}, and its field is then calculated 
%by the fuction calc_scal after the coordinate transform or after projection on an edit_object
     
% Properties attached to plotting figures (standard Matlab properties):
%    'CurrentAxes'= gca or get(gcf,'CurrentAxes');
%    'CurrentPoint'=get(gcf,'CurrentPoint'): figure coordinates of the point over which the mouse is positioned
%    'CurrentCharacter'=get(gcf,'CurrentCharacter'): last character typed  over the figure where the mouse is positioned
%    'WindowButtonMotionFcn': function permanently called by mouse motion over the figure
%    'KeyPressFcn': function called by pressing a key on the key board 
%    'WindowButtonDownFcn':  function called by pressing the mouse over the  figure
%    'WindowButtonUpFcn': function called by releasing  the mouse pressure over the  figure

% Properties attached to plotting axes:
%    'CurrentPoint'=get(gca,'CurrentPoint'); (standard Matlab) same as for the figure, but position in plot coordinates.
%     AxeData:=get(gca,'UserData');
%     AxeData.Drawing  = create: create a new object 
%                       = deform: modify an existing object by moving its defining create
%                      = off: no current drawing action
%                     = translate: translate an existing object
%                    = calibration: move a calibration point
%                    = CheckZoom: isolate a subregion for CheckZoom in=1 if an object is being currently drawn, 0 else (set to 0 by releasing mouse button)
%            .CurrentOrigin: Origin of a curently drawn edit_object
%            .CurrentLine: currently drawn menuline (A REVOIR)
%            .CurrentObject: handle of the currently drawn edit_object
%            .CurrentRectZoom: current rectangle used for CheckZoom

% Properties attached to projection objects (create, menuline, menuplane...):
%    'Tag'='proj_object': for all projection objects
%    ObjectData.Type=...: style of projection object:
%              .ProjMode
%              .Coord: defines the position of the object
%              .XMin,YMin....
%              .XMax,YMax....
%              .DX,DY,DZ
%              .Phi, .Theta, .Psi : Euler angles
%              .X,.Y,.U,.V.... : field data projected on the object
%              .IndexObj: index in the list of UvData.Object
           %during plotting
%               .plotaxes: handles of the current axes used to plot the  result of field projection on the object
%               .plothandle: vector of handle(s) of the object graphic represnetation in all the opened plotting axes
% To each projection object #iobj, corresponds an axis
% Object{iobj}.plotaxes and nbobj representation graphs  Object{iobj}.plothandles(:) (where nbobj is the
% nbre of current objects opened in uvmat. Note that Object{iobj}.plothandles(iobj)=[] : an object is not represented in its own projection field;

%------------------------------------------------------------------------
%------------------------------------------------------------------------
%  I - MAIN FUNCTION uvmat
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function varargout = uvmat(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',          mfilename, ...
                   'gui_Singleton',     gui_Singleton, ...
                   'gui_OpeningFcn',    @uvmat_OpeningFcn, ...
                   'gui_OutputFcn',     @uvmat_OutputFcn, ...
                   'gui_LayoutFcn',     [], ...
                   'gui_Callback',      []);
if nargin && ischar(varargin{1})&& ~isempty(regexp(varargin{1},'_Callback','once'))
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    varargout{1:nargout} = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%------------------------------------------------------------------------
% --- Executes just before the GUI uvmat is made visible.
function uvmat_OpeningFcn(hObject, eventdata, handles, input )
%------------------------------------------------------------------------

%% Choose default command menuline output for uvmat (standard GUI)
handles.output = hObject;

%% Update handles structure (standard GUI)
guidata(hObject, handles);

%% add the path to uvmat (useful if uvmat has been opened in the working directory and a working directory change occured)
path_uvmat=fileparts(which('uvmat'));

%% set the position of colorbar and ancillary GUIs:
set(hObject,'Units','Normalized')
movegui(hObject,'center')
%UvData.OpenParam.PosColorbar=[0.8450    0.0900    0.0190    0.3600];
UvData.OpenParam.PosColorbar=[0.805 0.022 0.019 0.445];
UvData.OpenParam.PosSetObject=[-0.05 -0.03 0.3 0.7]; %position for set_object
UvData.OpenParam.PosGeometryCalib=[0.95 -0.03 0.28 1 ];%position for geometry_calib (TO IMPROVE)
% UvData.OpenParam.CalSize=[0.28 1];
% UvData.PlotAxes=[];%initiate the record of plotted field
% UvData.axes2=[];
% UvData.axes1=[];
AxeData.LimEditBox=1; %initialise AxeData
set(handles.PlotAxes,'UserData',AxeData)

%% set functions for the mouse and keyboard
set(hObject,'KeyPressFcn',{'keyboard_callback',handles})%set keyboard action function
set(hObject,'WindowButtonMotionFcn',{'mouse_motion',handles})%set mouse action functio
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%set mouse click action function
set(hObject,'WindowButtonUpFcn',{'mouse_up',handles}) 
set(hObject,'DeleteFcn',{@closefcn})%

%% initialisation
% set(handles.ListObject,'Value',1)% default: empty projection objectproj_field
% set(handles.ListObject,'String',{''})
% set(handles.ListObject_1,'Value',1)% default: empty projection objectproj_field
% set(handles.ListObject_1,'String',{''})
set(handles.FieldName,'Value',1)
set(handles.FieldName,'string',{''})
UvData.Object={[]};

%% TRANSFORM menu: builtin fcts
transform_menu={'';'sub_field';'phys';'phys_polar'};
UvData.OpenParam.NbBuiltin=numel(transform_menu); %number of functions
transform_path=fullfile(path_uvmat,'transform_field');
path_list=cell(UvData.OpenParam.NbBuiltin,1);
path_list{1}='';
for ilist=2:UvData.OpenParam.NbBuiltin
path_list{ilist}=transform_path; % set transform_path to the path_list
end

%% load the list of previously browsed files in menus Open, Open_1 and TransformName
 dir_perso=prefdir; % path to the directory .matlab containing the personal data of the current user
 profil_perso=fullfile(dir_perso,'uvmat_perso.mat');% personal data file uvmat_perso.mat' in .matlab
 if exist(profil_perso,'file')
     h=load (profil_perso);
     if isfield(h,'MenuFile')% load the menu of previously opened files
         for ifile=1:min(length(h.MenuFile),5)
             set(handles.(['MenuFile_' num2str(ifile)]),'Label',h.MenuFile{ifile});
             set(handles.(['MenuFile_' num2str(ifile) '_1']),'Label',h.MenuFile{ifile});
         end
     end
     if isfield(h,'RootPath')
         set(handles.RootPath,'UserData',h.RootPath); %store the previous campaign in the UserData of RootPath
     end
     if isfield(h,'transform_fct') && iscell(h.transform_fct) % load the menu of transform fct set by user
         for ilist=1:length(h.transform_fct);
             if exist(h.transform_fct{ilist},'file')
                 [path,file]=fileparts(h.transform_fct{ilist});
                 transform_menu=[transform_menu; {file}];
                 path_list=[path_list; {path}];
             end
         end
     end
 end
transform_menu=[transform_menu;{'more...'}];%append the option more.. to the menu
set(handles.TransformName,'String',transform_menu)% display the menu of transform fcts
set(handles.TransformName,'UserData',path_list)% store the corresponding list of path in UserData of uicontrol transform_fct
set(handles.TransformPath,'String','')
set(handles.TransformPath,'UserData',[])

%% case of an input argument for uvmat
testinputfield=0;
inputfile=[];
Field=[];
if exist('input','var')
    if ishandle(handles.UVMAT_title)
        delete(handles.UVMAT_title)
    end   
    if isstruct(input)
        if isfield(input,'InputFile')
            inputfile=input.InputFile;
        end
        if isfield(input,'TimeIndex')
            set(handles.i1,num2str(input.TimeIndex))
        end
        if isfield(input,'FieldsString')
            UvData.FieldsString=input.FieldsString;
        end
    elseif ischar(input)% file name introduced as input
           inputfile=input;
    elseif isnumeric(input)%simple matrix introduced as input
        sizinput=size(input);
        if sizinput(1)<=1 || sizinput(2)<=1
            msgbox_uvmat('ERROR','bad input for uvmat: file name, structure or numerical matrix accepted')
            return
        end
        UvData.Field.ListVarName={'A','coord_y','coord_x'};
        UvData.Field.VarDimName={{'coord_y','coord_x'},'cord_y','coord_x'};
        UvData.Field.A=input;
        UvData.Field.coord_x=[0.5 size(input,2)-0.5];
        UvData.Field.coord_y=[size(input,1)-0.5 0.5];
        testinputfield=1;
    end
else
    %% check the path and date of modification of all functions in uvmat
    path_to_uvmat=which ('uvmat');% check the path detected for source file uvmat
    [infomsg,date_str,svn_info]=check_files;%check the path of the functions called by uvmat.m   
    date_str=['last modification: ' date_str];
    if ishandle(handles.UVMAT_title)
        set(handles.UVMAT_title,'String',...
            [{'Copyright  LEGI UMR 5519 /CNRS-UJF-Grenoble INP, 2010'};...
            {'GNU General Public License'};...
            {path_to_uvmat};...
            {date_str};...
            infomsg]);
    end
end
set(handles.uvmat,'UserData',UvData)
if ~isempty(inputfile)
    %%%%% display the input field %%%%%%%
    display_file_name(handles,inputfile)
    %%%%%%%
end

set_vec_col_bar(handles) %update the display of color code for vectors

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command menuline.
function varargout = uvmat_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;% the only output argument is the handle to the GUI figure

%------------------------------------------------------------------------
% --- executed when closing uvmat: delete or desactivate the associated figures if exist
function closefcn(gcbo,eventdata)
%------------------------------------------------------------------------
hh=findobj(allchild(0),'tag','view_field');
if ~isempty(hh)
    delete(hh)
end
hh=findobj(allchild(0),'tag','geometry_calib');
if ~isempty(hh)
    delete(hh)
end
hh=findobj(allchild(0),'tag','set_object');
if ~isempty(hh)
    hhh=findobj(hh,'tag','PLOT');
    set(hhh,'enable','off')
end

%------------------------------------------------------------------------
%------------------------------------------------------------------------
%  II - FUNCTIONS FOR INTRODUCING THE INPUT FILES
% automatically sets the global properties when the rootfile name is introduced
% then activate the view-field action if selected
% it is activated either by clicking on the RootPath window or by the 
% browser 
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% --- Executes on the menu Open/Browse...
% search the files, recognize their type according to their name and fill the rootfile input windows
function MenuBrowse_Callback(hObject, eventdata, handles)
[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
oldfile=fullfile(RootPath,SubDir);
if isempty(oldfile) %loads the previously stored file name and set it as default in the file_input box
    oldfile=get(handles.RootPath,'UserData');
end
hfig=uigetfile_uvmat('file browser',fileparts(oldfile));
uiwait(hfig);
if ishandle(hfig) % stop if browser closed without selection
    fileinput=get(hfig,'UserData');% retrieve the input file selection
    delete(hfig)
    % display the selected field and related information
    display_file_name(handles,fileinput)
end

% 
% 
% 
% [FileName, PathName] = uigetfile({'*.*','All Files(*.*)'},'Pick a file',oldfile);
% if ~ischar(FileName),return,end %abandon if the browser is cancelled
% fileinput=[PathName FileName];%complete file name 

%% display the selected field and related information
% display_file_name( handles,fileinput)

% -----------------------------------------------------------------------
% --- Executes on the menu Open/Browse campaign...
% search the file inside a campaign, using the GUI view_data
function MenuBrowseCampaign_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
RootPath=get(handles.RootPath,'String');
if isempty(RootPath)
    RootPath=get(handles.RootPath,'UserData');%use Rootpath recored from the personal file at uvmat opening
end
CampaignPath=fileparts(fileparts(RootPath));
DirFull = uigetdir(CampaignPath,'Select a Campaign dir, then press OK');
if ~ischar(DirFull)|| ~exist(DirFull,'dir')
    return
end
OutPut=browse_data(DirFull);% open the GUI browse_data to get select a campaign dir, experiment and device
if ~isfield(OutPut,'Campaign')
    return
end
DirName=fullfile(OutPut.Campaign,OutPut.Experiment{1},OutPut.Device{1});
hdir=dir(DirName); %list files and dirs
for ilist=1:numel(hdir)
    if ~isequal(hdir(ilist).isdir,1)%look for files, not dir
        FileName=hdir(ilist).name;
        FileType=get_file_type(fullfile(DirName,FileName));
        switch FileType
            case {'image','multimage','civx','civdata','netcdf'}
            break
        end
    end
end

%% display the selected field and related information
display_file_name( handles,fullfile(DirName,FileName))

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_1
function MenuFile_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_1,'Label');
display_file_name( handles,fileinput)

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_2
function MenuFile_2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_2,'Label');
display_file_name(handles,fileinput)

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_3
function MenuFile_3_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_3,'Label');
display_file_name(handles,fileinput)

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_4
function MenuFile_4_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_4,'Label');
display_file_name(handles,fileinput)

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile_5
function MenuFile_5_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(handles.MenuFile_5,'Label');
display_file_name(handles,fileinput)

%------------------------------------------------------------------------
% --- Executes on the menu Open/Browse_1 for the second input field,
%     search the files, recognize their type according to their name and fill the rootfile input windows
function MenuBrowse_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
RootPath=get(handles.RootPath,'String');
[FileName, PathName] = uigetfile({'*.*','All Files(*.*)'},'Pick a file',RootPath);
if ~ischar(FileName),return,end %abandon if the browser is cancelled
fileinput_1=[PathName FileName];%complete file name 

% refresh the current displayed field
set(handles.SubField,'Value',1)
display_file_name(handles,fileinput_1,2)

%update list of recent files in the menubar
MenuFile_1=fileinput_1;
MenuFile_2=get(handles.MenuFile_1,'Label');
MenuFile_3=get(handles.MenuFile_2,'Label');
MenuFile_4=get(handles.MenuFile_3,'Label');
MenuFile_5=get(handles.MenuFile_4,'Label');
set(handles.MenuFile_1,'Label',MenuFile_1)
set(handles.MenuFile_2,'Label',MenuFile_2)
set(handles.MenuFile_3,'Label',MenuFile_3)
set(handles.MenuFile_4,'Label',MenuFile_4)
set(handles.MenuFile_5,'Label',MenuFile_5)
set(handles.MenuFile_1_1,'Label',MenuFile_1)
set(handles.MenuFile_2_1,'Label',MenuFile_2)
set(handles.MenuFile_3_1,'Label',MenuFile_3)
set(handles.MenuFile_4_1,'Label',MenuFile_4)
set(handles.MenuFile_5_1,'Label',MenuFile_5)
% dir_perso=prefdir;
% profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
% if exist(profil_perso,'file')
%     save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-append'); %store the file names for future opening of uvmat
% else
%     txt=ver('MATLAB');
%     Release=txt.Release;
%     relnumb=str2double(Release(3:4));
%     if relnumb >= 14
%         save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-V6'); %store the file names for future opening of uvmat
%     else
%         save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5'); %store the file names for future opening of uvmat
%     end
% end

% --------------------------------------------------------------------
function MenuBrowseCampaign_1_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
CampaignPath=fileparts(fileparts(get(handles.RootPath,'String')));
DirFull = uigetdir(CampaignPath,'Select a Campaign dir, then press OK');
if ~ischar(DirFull)|| ~exist(DirFull,'dir')
    return
end
OutPut=browse_data(DirFull);% open the GUI browse_data to get select a campaign dir, experiment and device
if ~isfield(OutPut,'Campaign')
    return
end
DirName=fullfile(OutPut.Campaign,OutPut.Experiment{1},OutPut.Device{1});
hdir=dir(DirName); %list files and dirs
for ilist=1:numel(hdir)
    if ~isequal(hdir(ilist).isdir,1)%look for files, not dir
        FileName=hdir(ilist).name;
        FileType=get_file_type(fullfile(DirName,FileName));
        switch FileType
            case {'image','multimage','civx','civdata','netcdf'}
            break
        end
    end
end

%% display the selected field and related information
set(handles.SubField,'Value',1)
display_file_name( handles,fullfile(DirName,FileName),2)

% -----------------------------------------------------------------------
% --- Open again as second field the file whose name has been recorded in MenuFile_1
function MenuFile_1_1_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
fileinput_1=get(handles.MenuFile_1_1,'Label');
set(handles.SubField,'Value',1)
display_file_name(handles,fileinput_1,2)

% -----------------------------------------------------------------------
% --- Open again as second field the file whose name has been recorded in MenuFile_2
function MenuFile_2_1_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
fileinput_1=get(handles.MenuFile_2_1,'Label');
set(handles.SubField,'Value',1)
display_file_name(handles,fileinput_1,2)

% -----------------------------------------------------------------------
% --- Open again as second field the file whose name has been recorded in MenuFile_3
function MenuFile_3_1_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
fileinput_1=get(handles.MenuFile_3_1,'Label');
set(handles.SubField,'Value',1)
display_file_name(handles,fileinput_1,2)

% -----------------------------------------------------------------------
% --- Open again as second field the file whose name has been recorded in MenuFile_4
function MenuFile_4_1_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
fileinput_1=get(handles.MenuFile_4_1,'Label');
set(handles.SubField,'Value',1)
display_file_name(handles,fileinput_1,2)

% -----------------------------------------------------------------------
% --- Open again as second field the file whose name has been recorded in MenuFile_5
function MenuFile_5_1_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
fileinput_1=get(handles.MenuFile_5_1,'Label');
set(handles.SubField,'Value',1)
display_file_name(handles,fileinput_1,2)

%------------------------------------------------------------------------
% --- Called by action in RootPath edit box
function RootPath_Callback(hObject,eventdata,handles)
%------------------------------------------------------------------------
% read the current input file name:
[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
if ~exist(fullfile(RootPath,SubDir),'dir')
    msgbox_uvmat('ERROR',['directory ' fullfile(RootPath,SubDir) ' does not exist'])
    return
end
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,tild,FileType,FileInfo,MovieObject]=find_file_series(fullfile(RootPath,SubDir),[RootFile FileIndices FileExt]);
% initiate the input file series and refresh the current field view: 
update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,MovieObject,1);

%-----------------------------------------------------------------------
% --- Called by action in RootPath_1 edit box
function RootPath_1_Callback(hObject,eventdata,handles)
% -----------------------------------------------------------------------
% update_rootinfo_1(hObject,eventdata,handles)
[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes_1(handles);
if ~exist(fullfile(RootPath,SubDir),'dir')
    msgbox_uvmat('ERROR',['directory ' fullfile(RootPath,SubDir) ' does not exist'])
    return
end
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,tild,FileType,MovieObject]=find_file_series(fullfile(RootPath,SubDir),[RootFile FileIndices FileExt]);
% initiate the input file series and refresh the current field view: 
update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,MovieObject,2);

%------------------------------------------------------------------------
% --- Called by action in RootFile edit box
function SubDir_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%refresh the menu of input fieldname
Fields_Callback(hObject, eventdata, handles);
% refresh the current field view
run0_Callback(hObject, eventdata, handles); 

%------------------------------------------------------------------------
% --- Called by action in RootFile edit box
function RootFile_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
RootPath_Callback(hObject,eventdata,handles)

%-----------------------------------------------------------------------
% --- Called by action in RootFile_1 edit box
function RootFile_1_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
RootPath_1_Callback(hObject,eventdata,handles)

%------------------------------------------------------------------------
% --- Called by action in FileIndex edit box
function FileIndex_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
[tild,tild,tild,i1,i2,j1,j2]=fileparts_uvmat(get(handles.FileIndex,'String'));
set(handles.i1,'String',num2str(i1));
set(handles.i2,'String',num2str(i2));
set(handles.j1,'String',num2str(j1));
set(handles.j2,'String',num2str(j2));

% refresh the current field view
run0_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Called by action in FileIndex_1 edit box
function FileIndex_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
run0_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Called by action in NomType edit box
function NomType_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
i1=str2num(get(handles.i1,'String'));
i2=str2num(get(handles.i2,'String'));
j1=str2num(get(handles.j1,'String'));
j2=str2num(get(handles.j2,'String'));
FileIndex=fullfile_uvmat('','','','',get(handles.NomType,'String'),i1,i2,j1,j2);
set(handles.FileIndex,'String',FileIndex)
% refresh the current settings and refresh the field view
RootPath_Callback(hObject,eventdata,handles)

%------------------------------------------------------------------------
% --- Called by action in NomType edit box
function NomType_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
i1=str2num(get(handles.i1,'String'));
i2=str2num(get(handles.i2,'String'));
j1=str2num(get(handles.j1,'String'));
j2=str2num(get(handles.j2,'String'));
FileIndex=fullfile_uvmat('','','','',get(handles.NomType_1,'String'),i1,i2,j1,j2);
set(handles.FileIndex_1,'String',FileIndex)
% refresh the current settings and refresh the field view
RootPath_1_Callback(hObject,eventdata,handles)

%------------------------------------------------------------------------ 
% --- Fills the edit boxes RootPath, RootFile,NomType...from an input file name 'fileinput'
function display_file_name(handles,fileinput,index)
%------------------------------------------------------------------------
%% look for the input file existence
if ~exist(fileinput,'file')
    msgbox_uvmat('ERROR',['input file ' fileinput  ' does not exist'])
    return
end

%% set the mouse pointer to 'watch'
set(handles.uvmat,'Pointer','watch')
set(handles.RootPath,'BackgroundColor',[1 1 0])
drawnow

%% define the relevant handles for the first field series (index=1) or the second file series (index=2)
if ~exist('index','var')
    index=1;
end
if index==1
    handles_RootPath=handles.RootPath;
    handles_SubDir=handles.SubDir;
    handles_RootFile=handles.RootFile;
    handles_FileIndex=handles.FileIndex;
    handles_NomType=handles.NomType;
    handles_FileExt=handles.FileExt;
elseif index==2
    handles_RootPath=handles.RootPath_1;
    handles_SubDir=handles.SubDir_1;
    handles_RootFile=handles.RootFile_1;
    handles_FileIndex=handles.FileIndex_1;
    handles_NomType=handles.NomType_1;
    handles_FileExt=handles.FileExt_1;
    set(handles.RootPath_1,'Visible','on')
    set(handles.RootFile_1,'Visible','on')
    set(handles.SubDir_1,'Visible','on');
    set(handles.FileIndex_1,'Visible','on');
    set(handles.FileExt_1,'Visible','on');
    set(handles.NomType_1,'Visible','on');
end

%% detect root name, nomenclature and indices in the input file name:
[FilePath,FileName,FileExt]=fileparts(fileinput);
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
% the root name and indices may be corrected by including the first index i1 if a corresponding xml file exists
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileType,FileInfo,MovieObject,i1,i2,j1,j2]=find_file_series(FilePath,[FileName FileExt]);

%% open the file or fill the GUI uvmat according to the detected file type
switch FileType
    case ''
        msgbox_uvmat('ERROR','invalid input file type')
    case 'txt'
        edit(fileinput)
    case 'figure'                           %display matlab figure
        hfig=open(fileinput);
        set(hfig,'WindowButtonMotionFcn','mouse_motion')%set mouse action functio
        set(hfig,'WindowButtonUpFcn','mouse_up')%set mouse click action function
        set(hfig,'WindowButtonUpFcn','mouse_down')%set mouse click action function
    case 'xml'                % edit xml files
        t=xmltree(fileinput);
        % the xml file marks a project or project link, open datatree_browser
        if strcmp(get(t,1,'name'),'Project')&& exist(regexprep(fileinput,'.xml$',''),'dir')
            datatree_browser(fileinput)
        else % other xml file, open the xml editor
            editxml(fileinput);
        end
    case 'xls'% Excel file opended by editxml
        editxml(fileinput);
    otherwise
        set(handles_RootPath,'String',RootPath);
        rootname=fullfile(RootPath,SubDir,RootFile);
        set(handles_SubDir,'String',['/' SubDir]);
        set(handles_RootFile,'String',['/' RootFile]); %display the separator
        indices=fileinput(length(rootname)+1:end);
        indices(end-length(FileExt)+1:end)=[]; %remove extension
        set(handles_FileIndex,'String',indices);
        set(handles_NomType,'String',NomType);
        set(handles_FileExt,'String',FileExt);
        if index==1
            % fill file index counters if the first file series is opened
            set(handles.i1,'String',num2str(i1));
            set(handles.i2,'String',num2str(i2));
            set(handles.j1,'String',num2stra(j1,NomType));
            set(handles.j2,'String',num2stra(j2,NomType));
        else %read the current field index to synchronise with the first series
            i1_s=str2num(get(handles.i1,'String'));
            i2_0=str2num(get(handles.i2,'String'));
            if ~isempty(i2_0)
                i2_s=i2_0;
            else
               i2_s=i2; 
            end
            j1_0=stra2num(get(handles.j1,'String'));
            if ~isempty(j1_0)
                j1_s=j1_0;
            else
                j1_s=j1;
            end
            j2_0=stra2num(get(handles.j2,'String'));
            if ~isempty(j2_0)
                j2_s=j2_0;
            else
                j2_s=j2;
            end
        end
        
        % synchronise indices of the second  input file if it exists
        if get(handles.SubField,'Value')==1% if the subfield button is activated, update the field numbers
            Input=read_GUI(handles.InputFile);
            if ~isfield(Input,'RootPath_1')||strcmp(Input.RootPath_1,'"')
                Input.RootPath_1=Input.RootPath;
            end
            if ~isfield(Input,'SubDir_1')||strcmp(Input.SubDir_1,'"')
                Input.SubDir_1=Input.SubDir;
            end
            if ~isfield(Input,'RootFile_1')||strcmp(Input.RootFile_1,'"')
                Input.RootFile_1=Input.RootFile;
            end
            if ~isfield(Input,'FileExt_1')||strcmp(Input.FileExt_1,'"')
                Input.FileExt_1=Input.FileExt;
            end
            if ~isfield(Input,'NomType_1')||strcmp(Input.NomType_1,'"')
                Input.NomType_1=Input.NomType;
            end
            %updtate the indices of the second field series to correspond to the newly opened one
            FileName_1=fullfile_uvmat(Input.RootPath_1,Input.SubDir_1,Input.RootFile_1,Input.FileExt_1,Input.NomType_1,i1_s,i2_s,j1_s,j2_s);
            if exist(FileName_1,'file')
                FileIndex_1=fullfile_uvmat('','','','',Input.NomType_1,i1_s,i2_s,j1_s,j2_s);
            else
                FileIndex_1=fullfile_uvmat('','','','',Input.NomType_1,i1,i2,j1,j2);
                msgbox_uvmat('WARNING','unable to synchronise the indices of the two series')
            end
            set(handles.FileIndex_1,'String',FileIndex_1)
        end
        
        %enable other menus
        set(handles.MenuOpen_1,'Enable','on')
        set(handles.MenuFile_1_1,'Enable','on')
        set(handles.MenuFile_2_1,'Enable','on')
        set(handles.MenuFile_3_1,'Enable','on')
        set(handles.MenuFile_4_1,'Enable','on')
        set(handles.MenuFile_5_1,'Enable','on')
        set(handles.MenuExport,'Enable','on')
        set(handles.MenuExportFigure,'Enable','on')
        set(handles.MenuExportMovie,'Enable','on')
        set(handles.MenuTools,'Enable','on')

        % initiate input file series and refresh the current field view:     
        update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,MovieObject,index);

end

%% update list of recent files in the menubar and save it for future opening
MenuFile=[{get(handles.MenuFile_1,'Label')};{get(handles.MenuFile_2,'Label')};...
    {get(handles.MenuFile_3,'Label')};{get(handles.MenuFile_4,'Label')};{get(handles.MenuFile_5,'Label')}];
str_find=strcmp(fileinput,MenuFile);
if isempty(find(str_find,1))
    MenuFile=[{fileinput};MenuFile];%insert the current file if not already in the list
end
for ifile=1:min(length(MenuFile),5)
    set(handles.(['MenuFile_' num2str(ifile)]),'Label',MenuFile{ifile});
    set(handles.(['MenuFile_' num2str(ifile) '_1']),'Label',MenuFile{ifile});
end
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    save (profil_perso,'MenuFile','RootPath','-append'); %store the file names for future opening of uvmat
else
    save (profil_perso,'MenuFile','RootPath','-V6'); %store the file names for future opening of uvmat
end

%% set back the mouse pointer to arrow
set(handles.uvmat,'Pointer','arrow')


%------------------------------------------------------------------------
% --- Update information about a new field series (indices to scan, timing,
%     calibration from an xml file, then refresh current plots

function update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileType,VideoObject,index)
%------------------------------------------------------------------------
%% define the relevant handles depending on the index (1=first file series, 2= second file series)
if ~exist('index','var')
    index=1;
end
if index==1
    handles_RootPath=handles.RootPath;
    handles_Fields=handles.FieldName;
elseif index==2
    handles_RootPath=handles.RootPath_1;
    handles_Fields=handles.FieldName_1;
end

set(handles_RootPath,'BackgroundColor',[1 1 0])
drawnow
set(handles.FieldName,'UserData',[])% reinialize data from uvmat opening
UvData=get(handles.uvmat,'UserData');%huvmat=handles of the uvmat interface
UvData.NewSeries=1; %flag for run0: begin a new series
UvData.FileName_1='';% name of the current second field (used to detect a  constant field during file scanning)
UvData.FileType{index}=FileType;
UvData.i1_series{index}=i1_series;
UvData.i2_series{index}=i2_series;
UvData.j1_series{index}=j1_series;
UvData.j2_series{index}=j2_series;
set(handles.FixVelType,'Value',0); %desactivate fixed veltype
if index==1
    [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
else
    [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes_1(handles);
end
FileName=[fullfile(RootPath,SubDir,RootFile) FileIndices FileExt];
FileBase=fullfile(RootPath,RootFile);
if ~exist(FileName,'file')
   msgbox_uvmat('ERROR',['input file ' FileName ' not found']);
    return
end

%% read timing and total frame number from the current file (movie files) !! may be overrid by xml file
XmlData.Time=[];%default
XmlData.GeometryCalib=[];%default
TimeUnit='';%default
Time=[];
% testima=0; %test for image input
imainfo=[];
ColorType='falsecolor'; %default
% hhh=[];
UvData.MovieObject{index}=VideoObject;
if ~isempty(VideoObject)
    imainfo=get(VideoObject);
%     testima=1;
    TimeUnit='s';
    if isempty(j1_series); %frame index along i
        Time=(0:1/imainfo.FrameRate:(imainfo.NumberOfFrames)/imainfo.FrameRate)';
    else
        Time=ones(size(i1_series,1),1)*(0:1/imainfo.FrameRate:(imainfo.NumberOfFrames)/imainfo.FrameRate);
    end
    set(handles.Dt_txt,'String',['Dt=' num2str(1000/imainfo.FrameRate) 'ms']);%display the elementary time interval in millisec
    ColorType='truecolor';
elseif ~isempty(FileExt(2:end))&&(~isempty(imformats(FileExt(2:end))) || isequal(FileExt,'.vol'))%&& isequal(NomType,'*')% multi-frame image
%     testima=1;
    if ~isequal(SubDir,'')
        imainfo=imfinfo([fullfile(RootPath,SubDir,RootFile) FileIndices FileExt]);
    else
        imainfo=imfinfo([FileBase FileIndices FileExt]);
    end
    ColorType=imainfo.ColorType;%='truecolor' for color images
end
if isfield(imainfo,'Width') && isfield(imainfo,'Height')
    if length(imainfo)>1
        set(handles.num_Npx,'String',num2str(imainfo(1).Width));%fills nbre of pixels x box
        set(handles.num_Npy,'String',num2str(imainfo(1).Height));%fills nbre of pixels x box
    else
        set(handles.num_Npx,'String',num2str(imainfo.Width));%fills nbre of pixels x box
        set(handles.num_Npy,'String',num2str(imainfo.Height));%fills nbre of pixels x box
    end
else
    set(handles.num_Npx,'String','');%fills nbre of pixels x box
    set(handles.num_Npy,'String','');%fills nbre of pixels x box
end
set(handles.CheckBW,'Value',strcmp(ColorType,'grayscale'))% select handles.CheckBW if grayscale image

%% read parameters (time, geometric calibration..) from a documentation file (.xml advised)
XmlFileName=find_imadoc(RootPath,SubDir,RootFile,FileExt);
[tild,tild,DocExt]=fileparts(XmlFileName);
warntext='';%default warning message
NbSlice=1;%default
set(handles.RootPath,'BackgroundColor',[1 1 1])
if ~isempty(XmlFileName)
    set(handles.view_xml,'Visible','on')
    set(handles.view_xml,'BackgroundColor',[1 1 0])
    set(handles.view_xml,'String','view .xml')
    drawnow
    [XmlDataRead,warntext]=imadoc2struct(XmlFileName);
    if ~isempty(warntext)
        msgbox_uvmat('WARNING',warntext)
    end
    if isempty(XmlDataRead)
        set(handles.view_xml,'Visible','off')
    else
        set(handles.view_xml,'String',['view ' DocExt])   
        XmlData=XmlDataRead;
        if isfield(XmlData,'TimeUnit')
            if isfield(XmlData,'TimeUnit')&& ~isempty(XmlData.TimeUnit)
                TimeUnit=XmlData.TimeUnit;
            end
        end
        set(handles.view_xml,'BackgroundColor',[1 1 1])
        drawnow
        if isfield(XmlData, 'GeometryCalib') && ~isempty(XmlData.GeometryCalib)
            if isfield(XmlData.GeometryCalib,'VolumeScan') && isequal(XmlData.GeometryCalib.VolumeScan,'y')
                set (handles.slices,'String','volume')
            end
            hgeometry_calib=findobj('tag','geometry_calib');
            if ~isempty(hgeometry_calib)
                GUserData=get(hgeometry_calib,'UserData');
                if ~(isfield(GUserData,'XmlInputFile') && strcmp(GUserData.XmlInputFile,XmlFileName))
                    answer=msgbox_uvmat('INPUT_Y-N','replace the display of geometry_calib with the new input data?');
                    if strcmp(answer,'Yes')
                        geometry_calib(XmlFileName);%diplay the new calibration points and parameters in geometry_calib
                    end
                end
            end
        end
    end
end
if ~(isfield(XmlData,'Time')&& ~isempty(XmlData.Time))
    XmlData.Time=Time; %time set by video
end

%% store last index in handles.lat_i and .last_j
nbfield=max(max(max(i2_series)));
if isempty(nbfield)
    nbfield=max(max(max(i1_series)));
end
nbfield_j=max(max(max(j2_series)));
if isempty(nbfield_j)
    nbfield_j=max(max(max(j1_series)));
end
if ~isempty(XmlData.Time)
    %transform .Time to a column vector if it is a line vector the nomenclature uses a single index
    if isequal(size(XmlData.Time,1),1)
        %NomType=get(handles.NomType,'String');
        XmlData.Time=(XmlData.Time)';
    end
end
last_i_cell=get(handles.last_i,'String');
if isempty(nbfield)
    last_i_cell{index}='';
else
    last_i_cell{index}=num2str(nbfield);
end
set(handles.last_i,'String',last_i_cell)
last_j_cell=get(handles.last_j,'String');
if isempty(nbfield_j)
     last_j_cell{index}='';
else
     last_j_cell{index}=num2str(nbfield_j);
end
set(handles.last_j,'String',last_j_cell);

%% store geometric calibration in UvData
if isfield(XmlData,'GeometryCalib')
    GeometryCalib=XmlData.GeometryCalib;
    if isempty(GeometryCalib)
        set(handles.pxcm,'String','')
        set(handles.pycm,'String','')
        set(handles.TransformName,'Value',1); %  no transform by default
    else
        if (isfield(GeometryCalib,'R')&& ~isequal(GeometryCalib.R(2,1),0) && ~isequal(GeometryCalib.R(1,2),0)) ||...
            (isfield(GeometryCalib,'kappa1')&& ~isequal(GeometryCalib.kappa1,0))
            set(handles.pxcm,'String','var')
            set(handles.pycm,'String','var')
        elseif isfield(GeometryCalib,'fx_fy')
            pixcmx=GeometryCalib.fx_fy(1);%*GeometryCalib.R(1,1)*GeometryCalib.sx/(GeometryCalib.Tz*GeometryCalib.dpx);
            pixcmy=GeometryCalib.fx_fy(2);%*GeometryCalib.R(2,2)/(GeometryCalib.Tz*GeometryCalib.dpy);
            set(handles.pxcm,'String',num2str(pixcmx))
            set(handles.pycm,'String',num2str(pixcmy))
        end
        if ~get(handles.CheckFixLimits,'Value')
            set(handles.TransformName,'Value',3); % phys transform by default if fixedLimits is off
        end
        if isfield(GeometryCalib,'SliceCoord')            
           siz=size(GeometryCalib.SliceCoord);
           if siz(1)>1
               NbSlice=siz(1);
               set(handles.slices,'Visible','on')
               set(handles.slices,'Value',1)
           end
           if isfield(GeometryCalib,'VolumeScan') && isequal(GeometryCalib.VolumeScan,'y')
               set(handles.num_NbSlice,'Visible','off')
           else
               set(handles.num_NbSlice,'Visible','on')
               set(handles.num_NbSlice,'String',num2str(NbSlice))
           end
           slices_Callback([],[], handles)
        end           
    end
end

%% update the data attached to the uvmat interface
if ~isempty(TimeUnit)
    set(handles.time_txt,'String',['time (' TimeUnit ')'])
end
UvData.TimeUnit=TimeUnit;
UvData.XmlData{index}=XmlData;
UvData.NewSeries=1;
% UvData.MovieObject=MovieObject;

%display warning message
if ~isequal(warntext,'')
    msgbox_uvmat('WARNING',warntext);
end

%% set default options in menu 'FieldName'
switch FileType
    case {'civx','civdata'}
%         [FieldList,ColorList]=calc_field;
        [FieldList,ColorList]=set_field_list('U','V','C');
        set(handles_Fields,'String',[{'image'};FieldList;{'get_field...'}]);%standard menu for civx data
        set(handles_Fields,'Value',2) % set menu to 'velocity
        if index==1
            set(handles.FieldName_1,'Value',1);
            set(handles.FieldName_1,'String',[{''};{'image'};FieldList;{'get_field...'}]);%standard menu for civx data reproduced for the second field
        end
        set(handles.ColorScalar,'Value',1)
        set(handles.ColorScalar,'String',ColorList)
        set(handles.Vectors,'Visible','on')
        set(handles.Coord_x,'Value',1);
        set(handles.Coord_x,'String',{'X'});
        set(handles.Coord_y,'Value',1);
        set(handles.Coord_y,'String',{'Y'});
    case 'netcdf'
        set(handles_Fields,'Value',1)
        set(handles_Fields,'String',{'get_field...'})
        FieldName_Callback([],[], handles)
%         hget_field=get_field(FileName);
%         hhget_field=guidata(hget_field);
%         get_field('RUN_Callback',hhget_field.RUN,[],hhget_field);
    otherwise
        set(handles_Fields,'Value',1) % set menu to 'image'
        set(handles_Fields,'String',{'image'})
        set(handles.Coord_x,'Value',1);
        set(handles.Coord_x,'String',{'AX'});
        set(handles.Coord_y,'Value',1);
        set(handles.Coord_y,'String',{'AY'});
end
set(handles.uvmat,'UserData',UvData)

%% set index navigation options and refresh plots
scan_option='i';%default
state_j='off'; %default
if index==2
    if get(handles.scan_j,'Value')
        scan_option='j'; %keep the scan option for the second file series
    end
    if strcmp(get(handles.j1,'Visible'),'on')
        state_j='on';
    end
end
[ref_j,ref_i]=find(squeeze(i1_series(1,:,:)));
if ~isempty(j1_series) 
        state_j='on';
        if index==1
            if isequal(ref_i,ref_i(1)*ones(size(ref_j)))% if ref_i is always equal to its first value
                scan_option='j'; %scan j indext               
            end 
        end
end
if isequal(scan_option,'i')
    diff_ref_i=diff(ref_i,1);
    if isempty(diff_ref_i)
        diff_ref_i=1;
    end
    if isequal (diff_ref_i,diff_ref_i(1)*ones(size(diff_ref_i)))
        set(handles.num_IndexIncrement,'String',num2str(diff_ref_i(1)))
    end
     set(handles.scan_i,'Value',1)
     scan_i_Callback([],[], handles); 
else
    diff_ref_j=diff(ref_j);
    if isempty(diff_ref_j)
        diff_ref_j=1;
    end
    if isequal (diff_ref_j,diff_ref_j(1)*ones(size(diff_ref_j)))
        set(handles.num_IndexIncrement,'String',num2str(diff_ref_j(1)))
    end
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

%% apply the effect of the transform fct and view the field  
transform=get(handles.TransformPath,'UserData');
if index==2 && (~isa(transform,'function_handle')||nargin(transform)<3)
    set(handles.TransformName,'value',2); % set transform to sub_field if the current fct doe not accept two input fields
end
TransformName_Callback([],[],handles)
mask_test=get(handles.CheckMask,'value');
if mask_test
    MaskData=get(handles.CheckMask,'UserData');
    if isfield(MaskData,'maskhandle') && ishandle(MaskData.maskhandle)
          delete(MaskData.maskhandle)    %delete old mask
    end
    CheckMask_Callback([],[],handles)
end

%------------------------------------------------------------------------
% --- switch file index scanning options scan_i and scan_j in an exclusive way
function scan_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if get(handles.scan_i,'Value')==1
%     set(handles.scan_i,'BackgroundColor',[1 1 0])
    set(handles.scan_j,'Value',0)
else
%     set(handles.scan_i,'BackgroundColor',[0.831 0.816 0.784])
    set(handles.scan_j,'Value',1)
end
scan_j_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- switch file index scanning options scan_i and scan_j in an exclusive way
function scan_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if get(handles.scan_j,'Value')==1
%     set(handles.scan_j,'BackgroundColor',[1 1 0])
    set(handles.scan_i,'Value',0)
%     set(handles.scan_i,'BackgroundColor',[0.831 0.816 0.784])
%     NomType=get(handles.NomType,'String');
%     switch NomType
%     case {'_1_1-2','#_ab','%3dab'},% pair with j index
%         set(handles.CheckFixPair,'Visible','on')% option fixed pair on/off made visible (choice of avaible pair with buttons + and - if ='off')
%     otherwise
%         set(handles.CheckFixPair,'Visible','off')
%     end 
else
%     set(handles.scan_j,'BackgroundColor',[0.831 0.816 0.784])
    set(handles.scan_i,'Value',1)
%     set(handles.scan_i,'BackgroundColor',[1 1 0])
    set(handles.CheckFixPair,'Visible','off')
end

%------------------------------------------------------------------------
function i1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_ij(handles,1)

%------------------------------------------------------------------------
function i2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_ij(handles,2)

%------------------------------------------------------------------------
function j1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_ij(handles,3)

%------------------------------------------------------------------------
function j2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_ij(handles,4)

%------------------------------------------------------------------------
%--- update the index display after action on edit boxes i1, i2, j1 or j2
function update_ij(handles,index_rank)
NomType=get(handles.NomType,'String');
indices=get(handles.FileIndex,'String');
[tild,tild,tild,i1,i2,j1,j2]=fileparts_uvmat(indices);% the indices for the second series taken from FileIndex
switch index_rank
    case 1
        indices=fullfile_uvmat('','','','',NomType,stra2num(get(handles.i1,'String')),i2,j1,j2);
        set(handles.i1,'BackgroundColor',[0.7 0.7 0.7])% mark the edit box in grey, then RUN0 will mark it in white for confirmation
    case 2
        indices=fullfile_uvmat('','','','',NomType,i1,stra2num(get(handles.i2,'String')),j1,j2);
        set(handles.i2,'BackgroundColor',[0.7 0.7 0.7])% mark the edit box in grey, then RUN0 will mark it in white for confirmation
    case 3
        indices=fullfile_uvmat('','','','',NomType,i1,i2,stra2num(get(handles.j1,'String')),j2);
        set(handles.j1,'BackgroundColor',[0.7 0.7 0.7])% mark the edit box in grey, then RUN0 will mark it in white for confirmation
    case 4
        indices=fullfile_uvmat('','','','',NomType,i1,i2,j1,stra2num(get(handles.j2,'String')));
        set(handles.j2,'BackgroundColor',[0.7 0.7 0.7])% mark the edit box in grey, then RUN0 will mark it in white for confirmation
end
set(handles.FileIndex,'String',indices)
set(handles.FileIndex,'BackgroundColor',[0.7 0.7 0.7])% mark the edit box in grey, then RUN0 will mark it in white for confirmation
% update the second index if relevant
if strcmp(get(handles.FileIndex_1,'Visible'),'on')
    NomType_1=get(handles.NomType_1,'String');
    indices_1=get(handles.FileIndex_1,'String');
    [tild,tild,tild,i1_1,i2_1,j1_1,j2_1]=fileparts_uvmat(indices_1);% the indices for the second series taken from FileIndex_1
    switch index_rank
        case 1
            indices_1=fullfile_uvmat('','','','',NomType_1,stra2num(get(handles.i1,'String')),i2_1,j1_1,j2_1);
        case 2
            indices_1=fullfile_uvmat('','','','',NomType_1,i1_1,stra2num(get(handles.i2,'String')),j1_1,j2_1);
        case 3
            indices_1=fullfile_uvmat('','','','',NomType_1,i1_1,i2_1,stra2num(get(handles.j1,'String')),j2_1);
        case 4
            indices_1=fullfile_uvmat('','','','',NomType_1,i1_1,i2_1,j1_1,stra2num(get(handles.j2,'String')));
    end
    set(handles.FileIndex_1,'String',indices_1)
    set(handles.FileIndex_1,'BackgroundColor',[0.7 0.7 0.7])% mark the edit box in grey, then RUN0 will mark it in white for confirmation
end
    
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function slices_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if strcmp(get(handles.slices,'String'),'slices')
    if get(handles.slices,'Value')==1
        set(handles.num_NbSlice,'Visible','on')
        set(handles.z_text,'Visible','on')
        set(handles.z_index,'Visible','on')
        num_NbSlice_Callback(hObject, eventdata, handles)
    else
        set(handles.num_NbSlice,'Visible','off')
        set(handles.z_text,'Visible','off')
        set(handles.z_index,'Visible','off')
        set(handles.masklevel,'Value',1)
        set(handles.masklevel,'String',{'1'})
    end
end

%------------------------------------------------------------------------
function num_NbSlice_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode=get(handles.slices,'String');
nb_slice_str=get(handles.num_NbSlice,'String');
if strcmp(mode,'volume')
    z=stra2num(get(handles.j1,'String'));
else
    num=str2double(get(handles.i1,'String'));
    nbslice=str2double(get(handles.num_NbSlice,'String'));
    z=mod(num-1,nbslice)+1;
end
set(handles.z_index,'String',num2str(z))
for ilist=1:nbslice
    list_index{ilist,1}=num2str(ilist);
end   
set(handles.masklevel,'String',list_index)
set(handles.masklevel,'Value',z)

%------------------------------------------------------------------------
% --- Executes on button press in view_xml.
function view_xml_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%[FileName,RootPath,FileBase,FileIndices,FileExt]=read_file_boxes(handles);
 [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
FileBase=fullfile(RootPath,RootFile);
option=get(handles.view_xml,'String');
if isequal(option,'view .xml')
    FileXml=fullfile(RootPath,[SubDir '.xml']);
    if ~exist(FileXml,'file')% case of civ files , removes the extension for subdir
        FileXml=fullfile(RootPath,[regexprep(SubDir,'\..+$','') '.xml']);
    end
    heditxml=editxml(FileXml);
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckMask.
function CheckMask_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%case of view mask selection
if isequal(get(handles.CheckMask,'Value'),1)
     [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
     FileBase=fullfile(RootPath,RootFile);
    num_i1=stra2num(get(handles.i1,'String'));
    num_j1=stra2num(get(handles.j1,'String'));
    currentdir=pwd;  
    cd(RootPath);
    maskfiles=dir('*_*mask_*.png');%look for a mask file
    cd(currentdir);%come back to the working directory
    mdetect=0;
    if ~isempty(maskfiles)
        for ilist=1:length(maskfiles)
            maskname=maskfiles(ilist).name;% take the first mask file in the list
            [tild,tild,tild,tild,tild,tild,tild,MaskExt,Mask_NomType{ilist}]=fileparts_uvmat(maskname);
             [tild,Name]=fileparts(maskname);
            Namedouble=double(Name);
            val=(48>Namedouble)|(Namedouble>57);% select the non-numerical characters
            ind_mask=findstr('mask',Name);
            i=ind_mask-1;
            while val(i)==0 && i>0
                i=i-1;
            end
            nbmask_str=str2num(Name(i+1:ind_mask-1));
            if ~isempty(nbmask_str)
                nbslice(ilist)=nbmask_str; % number of different masks (slices)
            end
        end
        if isequal(min(nbslice),max(nbslice))
            nbslice=nbslice(1);
        else
            msgbox_uvmat('ERROR','several inconsistent mask sets coexist in the current image directory')
            return
        end
        if ~isempty(nbslice) && Name(i)=='_'
            Mask.Base=[FileBase Name(i:ind_mask+3)];
            Mask.NbSlice=nbslice;
            num_i1=mod(num_i1-1,nbslice)+1;
            Mask.NomType=regexprep(Mask_NomType{1},'0','');%remove '0' in nom type for masks
            [RootPath,RootFile]=fileparts(Mask.Base);
            maskname=fullfile_uvmat(RootPath,'',RootFile,'.png',Mask.NomType,num_i1,[],num_j1);
            %maskname=name_generator(Mask.Base,num_i1,num_j1,'.png',Mask.NomType);%
            mdetect=exist(maskname,'file');
            if mdetect
                set(handles.num_NbSlice,'String',Name(i+1:ind_mask-1));
                 set(handles.num_NbSlice,'BackgroundColor',[1 1 0])
                set(handles.CheckMask,'UserData',Mask);
                set(handles.CheckMask,'BackgroundColor',[1 1 0])
                if nbslice > 1
                    set(handles.slices,'value',1)
                    slices_Callback(hObject, eventdata, handles)
                end
            end
        end
    end
    errormsg=[];%default
    if mdetect==0
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.png', ' (*.png)';
            '*.png',  '.png files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a mask file *.png',FileBase);
        if ~ischar(FileName),return,end %abandon if the browser is cancelled
        maskname=fullfile(PathName,FileName);
        [RootDir,SubDir,RootFile,tild,tild,tild,tild,tild,Mask.NomType]=fileparts_uvmat(maskname);
        Mask.Base=fullfile(RootDir,SubDir,RootFile);
        Mask.NbSlice=1;
        set(handles.CheckMask,'UserData',Mask);
        set(handles.CheckMask,'BackgroundColor',[1 1 0])
    end
    if isempty(errormsg)
        errormsg=update_mask(handles,num_i1,num_j1);
    end
    if ~isempty(errormsg)
            set(handles.CheckMask,'Value',0)
            set(handles.CheckMask,'BackgroundColor',[0.7 0.7 0.7])
     end
else % desactivate mask display
    MaskData=get(handles.CheckMask,'UserData');
    if isfield(MaskData,'maskhandle') && ishandle(MaskData.maskhandle)
          delete(MaskData.maskhandle)    
    end
    set(handles.CheckMask,'UserData',[])    
    UvData=get(handles.uvmat,'UserData');
    if isfield(UvData,'MaskName')
        UvData=rmfield(UvData,'MaskName');
        set(handles.uvmat,'UserData',UvData)
    end
    set(handles.CheckMask,'BackgroundColor',[0.7 0.7 0.7])
end

%------------------------------------------------------------------------
function errormsg=update_mask(handles,num_i1,num_j1)
%------------------------------------------------------------------------
errormsg=[];%default
MaskData=get(handles.CheckMask,'UserData');
if isfield(MaskData,'maskhandle')&& ishandle(MaskData.maskhandle)
    uistack(MaskData.maskhandle,'top');
end
num_i1_mask=mod(num_i1-1,MaskData.NbSlice)+1;
[RootPath,RootFile]=fileparts(MaskData.Base);
MaskName=fullfile_uvmat(RootPath,'',RootFile,'.png',MaskData.NomType,num_i1_mask,[],num_j1);
UvData=get(handles.uvmat,'UserData');
%update mask image if the mask is new
if ~ (isfield(UvData,'MaskName') && isequal(UvData.MaskName,MaskName)) 
    UvData.MaskName=MaskName; %update the recorded name on UvData
    set(handles.uvmat,'UserData',UvData);
    if ~exist(MaskName,'file')
        if isfield(MaskData,'maskhandle')&& ishandle(MaskData.maskhandle)
            delete(MaskData.maskhandle)    
        end
    else
        %read mask image
        [Mask,tild,errormsg] = read_field(MaskName,'image');
%         Mask.AName='image';
%         Mask.A=imread(MaskName);
        if ~isempty(errormsg)
            return
        end
        npxy=size(Mask.A);
        if length(npxy)>2
            errormsg=[MaskName ' is not a grey scale image'];
            return
        elseif ~isa(Mask.A,'uint8')
            errormsg=[MaskName ' is not a 8 bit grey level image'];
            return
        end
%         Mask.AX=[0.5 npxy(2)-0.5];
%         Mask.AY=[npxy(1)-0.5 0.5 ];
%         Mask.CoordUnit='pixel';
        if isequal(get(handles.slices,'Value'),1)
           NbSlice=str2num(get(handles.num_NbSlice,'String'));
           num_i1=str2num(get(handles.i1,'String')); 
           Mask.ZIndex=mod(num_i1-1,NbSlice)+1;
        end
        %px to phys or other transform on field
         menu_transform=get(handles.TransformName,'String');
        choice_value=get(handles.TransformName,'Value');
        transform_name=menu_transform{choice_value};%name of the transform fct  given by the menu 'transform_fct'
        transform=get(handles.TransformPath,'UserData');
        if  ~isequal(transform_name,'') && ~isequal(transform_name,'px')
            if isfield(UvData,'XmlData') && isfield(UvData.XmlData{1},'GeometryCalib')%use geometry calib recorded from the ImaDoc xml file as first priority
                Calib=UvData.XmlData{1}.GeometryCalib;
                Mask=transform(Mask,UvData.XmlData{1});
            end
        end
        flagmask=Mask.A < 200;
        
        %make brown color image
        imflag(:,:,1)=0.9*flagmask;
        imflag(:,:,2)=0.7*flagmask;
        imflag(:,:,3)=zeros(size(flagmask));
        
        %update mask image
        hmask=[]; %default
        if isfield(MaskData,'maskhandle')&& ishandle(MaskData.maskhandle)
            hmask=MaskData.maskhandle;
        end
        if ~isempty(hmask)
            set(hmask,'CData',imflag)    
            set(hmask,'AlphaData',flagmask*0.6)
            set(hmask,'XData',Mask.AX);
            set(hmask,'YData',Mask.AY);
%             uistack(hmask,'top')
        else
            axes(handles.PlotAxes)
            hold on    
            MaskData.maskhandle=image(Mask.AX,Mask.AY,imflag,'Tag','mask','HitTest','off','AlphaData',0.6*ones(size(flagmask)));
            set(handles.CheckMask,'UserData',MaskData)
        end
    end
end

%------------------------------------------------------------------------
%------------------------------------------------------------------------
% III - MAIN REFRESH FUNCTIONS : 'FRAME PLOT'
%------------------------------------------------------------------------

%------------------------------------------------------------------------
% --- Executes on button press in runplus: make one step forward and call
% --- run0. The step forward is along the fieldname series 1 or 2 depending on 
% --- the scan_i and scan_j check box (exclusive each other)
function runplus_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.runplus,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
%TODO: introduce the option: increment ='*' to move to the next available view
increment=str2num(get(handles.num_IndexIncrement,'String')); %get the field increment d
% if isnan(increment)
%     set(handles.num_IndexIncrement,'String','1')%default value
%     increment=1;
% end
errormsg=runpm(hObject,eventdata,handles,increment);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg);
end
set(handles.runplus,'BackgroundColor',[1 0 0])%paint the command button back to red

%------------------------------------------------------------------------
% --- Executes on button press in runmin: make one step backward and call
% --- run0. The step backward is along the fieldname series 1 or 2 depending on 
% --- the scan_i and scan_j check box (exclusive each other)
function runmin_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.runmin,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
increment=-str2num(get(handles.num_IndexIncrement,'String')); %get the field increment d
% if isnan(increment)
%     set(handles.num_IndexIncrement,'String','1')%default value
%     increment=1;
% end
errormsg=runpm(hObject,eventdata,handles,increment);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg);
end
set(handles.runmin,'BackgroundColor',[1 0 0])%paint the command button back to red

%------------------------------------------------------------------------
% -- Executes on button press in Movie: make a series of +> steps
function Movie_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.Movie,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
increment=str2num(get(handles.num_IndexIncrement,'String')); %get the field increment d
% if isnan(increment)
%     set(handles.num_IndexIncrement,'String','1')%default value
%     increment=1;
% end
set(handles.STOP,'Visible','on')
set(handles.speed,'Visible','on')
set(handles.speed_txt,'Visible','on')
set(handles.Movie,'BusyAction','queue')
UvData=get(handles.uvmat,'UserData');

while get(handles.Movie,'Value')==1 && get(handles.speed,'Value')~=0 && isequal(get(handles.Movie,'BusyAction'),'queue') % enable STOP command
        errormsg=runpm(hObject,eventdata,handles,increment);
        if ~isempty(errormsg)
            set(handles.Movie,'BackgroundColor',[1 0 0])%paint the command buttonback to red
            return
        end
        pause(1.02-get(handles.speed,'Value'))% wait for next image
end
if isfield(UvData,'aviobj') && ~isempty( UvData.aviobj),
    UvData.aviobj=close(UvData.aviobj);
   set(handles.uvmat,'UserData',UvData);
end
set(handles.Movie,'BackgroundColor',[1 0 0])%paint the command buttonback to red

%------------------------------------------------------------------------
% -- Executes on button press in Movie: make a series of <- steps
function MovieBackward_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.MovieBackward,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
increment=-str2num(get(handles.num_IndexIncrement,'String')); %get the field increment d
set(handles.STOP,'Visible','on')
set(handles.speed,'Visible','on')
set(handles.speed_txt,'Visible','on')
set(handles.MovieBackward,'BusyAction','queue')
UvData=get(handles.uvmat,'UserData');

while get(handles.MovieBackward,'Value')==1 && get(handles.speed,'Value')~=0 && isequal(get(handles.MovieBackward,'BusyAction'),'queue') % enable STOP command
        errormsg=runpm(hObject,eventdata,handles,increment);
        if ~isempty(errormsg)
            set(handles.MovieBackward,'BackgroundColor',[1 0 0])%paint the command buttonback to red
            return
        end
        pause(1.02-get(handles.speed,'Value'))% wait for next image
end
if isfield(UvData,'aviobj') && ~isempty( UvData.aviobj),
    UvData.aviobj=close(UvData.aviobj);
   set(handles.uvmat,'UserData',UvData);
end
set(handles.MovieBackward,'BackgroundColor',[1 0 0])%paint the command buttonback to red

%------------------------------------------------------------------------
function STOP_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.movie_pair,'BusyAction','Cancel')
set(handles.movie_pair,'value',0)
set(handles.Movie,'BusyAction','Cancel')
set(handles.MovieBackward,'BusyAction','Cancel')
set(handles.MenuExportMovie,'BusyAction','Cancel')
set(handles.movie_pair,'BackgroundColor',[1 0 0])%paint the command buttonback to red
set(handles.Movie,'BackgroundColor',[1 0 0])%paint the command buttonback to red
set(handles.MovieBackward,'BackgroundColor',[1 0 0])%paint the command buttonback to red

%------------------------------------------------------------------------
% --- function activated by runplus and run minus
function errormsg=runpm(hObject,eventdata,handles,increment)
%------------------------------------------------------------------------
errormsg='';%default
%% check for movie pair status
movie_status=get(handles.movie_pair,'Value');
if isequal(movie_status,1)
    STOP_Callback(hObject, eventdata, handles)%interrupt movie pair if active
end

%% read the current input file name(s) and field indices
InputFile=read_GUI(handles.InputFile);
InputFile.RootFile=regexprep(InputFile.RootFile,'^[\\/]|[\\/]$','');%suppress possible / or \ separator at the beginning or the end of the string
InputFile.SubDir=regexprep(InputFile.SubDir,'^[\\/]|[\\/]$','');%suppress possible / or \ separator at the beginning or the end of the string
FileExt=InputFile.FileExt;
NomType=get(handles.NomType,'String');
i1=str2num(get(handles.i1,'String'));%read the field indices (for movie, it is not given by the file name)
i2=[];%default
if strcmp(get(handles.i2,'Visible'),'on')
    i2=str2num(get(handles.i2,'String'));
end
j1=[];
if strcmp(get(handles.j1,'Visible'),'on')
    j1=stra2num(get(handles.j1,'String'));
end
j2=j1;
if strcmp(get(handles.j2,'Visible'),'on')
    j2=stra2num(get(handles.j2,'String'));
end
sub_value= get(handles.SubField,'Value');
if sub_value % a second input file has been entered 
     [InputFile.RootPath_1,InputFile.SubDir_1,InputFile.RootFile_1,InputFile.FileIndex_1,InputFile.FileExt_1,InputFile.NomType_1]=read_file_boxes_1(handles);   
    [tild,tild,tild,i1_1,i2_1,j1_1,j2_1]=fileparts_uvmat(InputFile.FileIndex_1);% the indices for the second series taken from FileIndex_1
else
    filename_1=[];
end   

%% increment (or decrement) the field indices and update the input filename(s)
if isempty(increment)
    set(handles.CheckFixPair,'Value',0)
end
CheckFixPair=get(handles.CheckFixPair,'Value')||(isempty(i2)&&isempty(j2));

% the pair i1-i2 or j1-j2 is imposed (check box CheckFixPair selected)
        i1_1=i1;
        i2_1=i2;
        j1_1=j1;
        j2_1=j2;
if CheckFixPair
    if get(handles.scan_i,'Value')==1% case of scanning along index i
        i1=i1+increment;
        i2=i2+increment;
        if sub_value
            i1_1=i1_1+increment;
            i2_1=i2_1+increment;
        end
        
    else % case of scanning along index j (burst numbers)
        j1=j1+increment;
        j2=j2+increment;
        if sub_value
            j1_1=j1_1+increment;
            j2_1=j2_1+increment;
        end
    end
    
% the pair i1-i2 or j1-j2 is free (check box CheckFixPair not selected): the list of existing indices recorded in UvData is used
else
    UvData=get(handles.uvmat,'UserData');
    ref_i=i1;
    if ~isempty(i2)
        ref_i=floor((i1+i2)/2);% current reference index i
    end
    ref_j=1;
    if ~isempty(j1)
        ref_j=j1;
        if ~isempty(j2)
            ref_j=floor((j1+j2)/2);% current reference index j
        end
    end
    if ~isempty(increment)
        if get(handles.scan_i,'Value')==1% case of scanning along index i
            ref_i=ref_i+increment;% increment the current reference index i
        else % case of scanning along index j (burst numbers)
            ref_j=ref_j+increment;% increment the current reference index j if scan_j option is used
        end
    else % free increment
        runaction=get(gcbo,'tag');
        if strcmp(runaction,'runplus')||strcmp(runaction,'Movie')% if runplus or movie is activated
            step=1;
        else
            step=-1;
        end
        if get(handles.scan_i,'Value')==1% case of scanning along index i
            ref_i=ref_i+step;
            while ref_i>=0  && size(UvData.i1_series{1},3)>=ref_i+1 && UvData.i1_series{1}(1,ref_j+1,ref_i+1)==0
                ref_i=ref_i+step;
            end
        else % case of scanning along index j (burst numbers)
            ref_j=ref_j+step;
            while ref_j>=0  && size(UvData.i1_series{1},2)>=ref_j+1 && UvData.i1_series{1}(1,ref_j+1,ref_i+1)==0
                ref_j=ref_j+step;
            end
        end
    end
    if ref_i<0
        errormsg='minimum i index reached';
    elseif ref_j<0
        errormsg='minimum j index reached';
    elseif ref_i+1>size(UvData.i1_series{1},3)
        errormsg='maximum i index reached (reload the input file to update the index bound)';
    elseif ref_j+1>size(UvData.i1_series{1},2)
        errormsg='maximum j index reached (reload the input file to update the index bound)';
    end
    if ~isempty(errormsg),return,end
    siz=size(UvData.i1_series{1});
    ref_indices=ref_i*siz(1)*siz(2)+ref_j*siz(1)+1:ref_i*siz(1)*siz(2)+(ref_j+1)*siz(1);
    i1_subseries=UvData.i1_series{1}(ref_indices);
    ref_indices=ref_indices(i1_subseries>0);
    if isempty(ref_indices)% case of pairs (free index i)
        ref_indices=ref_i*siz(1)*siz(2)+1:(ref_i+1)*siz(1)*siz(2);
        i1_subseries=UvData.i1_series{1}(ref_indices);
        ref_indices=ref_indices(i1_subseries>0);
    end
    if isempty(ref_indices),errormsg='no next frame: set num_IndexIncrement =''*'' to reach the next existing file';return
    end
    i1=UvData.i1_series{1}(ref_indices(end));
    if ~isempty(UvData.i2_series{1})
        i2=UvData.i2_series{1}(ref_indices(end));
    end
    if ~isempty(UvData.j1_series{1})
        j1=UvData.j1_series{1}(ref_indices(end));
    end
    if ~isempty(UvData.j2_series{1})
        j2=UvData.j2_series{1}(ref_indices(end));
    end
    
    % case of a second file series 
    if sub_value
        ref_i_1=i1_1;
        if ~isempty(i2_1)
            ref_i_1=floor((i1_1+i2_1)/2);% current reference index i
        end
        ref_j_1=1;
        if ~isempty(j1_1)
            ref_j_1=j1_1;
            if ~isempty(j2_1)
                ref_j_1=floor((j1_1+j2_1)/2);% current reference index j
            end
        end
        if ~isempty(increment)
            if get(handles.scan_i,'Value')==1% case of scanning along index i
                ref_i_1=ref_i_1+increment;% increment the current reference index i
            else % case of scanning along index j (burst numbers)
                ref_j_1=ref_j_1+increment;% increment the current reference index j if scan_j option is used
            end
        else % free increment, synchronise the ref indices with the first series
            ref_i_1=ref_i;
            ref_j_1=ref_j; 
        end
        if numel(UvData.i1_series)==1
            UvData.i1_series{2}=UvData.i1_series{1};
            UvData.j1_series{2}=UvData.j1_series{1};
            UvData.i2_series{2}=UvData.i2_series{1};
            UvData.j2_series{2}=UvData.j2_series{1};
        end
        if ref_i_1<0
            errormsg='minimum i index reached';
        elseif ref_j_1<0
            errormsg='minimum j index reached';
        elseif ref_i_1+1>size(UvData.i1_series{2},3)
            errormsg='maximum i index reached for the second series (reload the input file to update the index bound)';
        elseif ref_j_1+1>size(UvData.i1_series{2},2)
            errormsg='maximum j index reached for the second series(reload the input file to update the index bound)';
        end
        if ~isempty(errormsg),return,end
        siz=size(UvData.i1_series{2});
        ref_indices=ref_i_1*siz(1)*siz(2)+ref_j_1*siz(1)+1:ref_i_1*siz(1)*siz(2)+(ref_j_1+1)*siz(1);
        i1_subseries=UvData.i1_series{2}(ref_indices);
        ref_indices=ref_indices(i1_subseries>0);
        if isempty(ref_indices)% case of pairs (free index i)
            ref_indices=ref_i_1*siz(1)*siz(2)+1:(ref_i_1+1)*siz(1)*siz(2);
            i1_subseries=UvData.i1_series{2}(ref_indices);
            ref_indices=ref_indices(i1_subseries>0);
        end
        i1_1=UvData.i1_series{2}(ref_indices(end));
        if ~isempty(UvData.i2_series{2})
            i2_1=UvData.i2_series{2}(ref_indices(end));
        end
        if ~isempty(UvData.j1_series{2})
            j1_1=UvData.j1_series{2}(ref_indices(end));
        end
        if ~isempty(UvData.j2_series{2})
            j2_1=UvData.j2_series{1}(ref_indices(end));
        end   
    else% the second series (if needed) is the same file as the first
        i1_1=i1;
        i2_1=i2;
        j1_1=j1;
        j2_1=j2;
    end
end
filename=fullfile_uvmat(InputFile.RootPath,InputFile.SubDir,InputFile.RootFile,FileExt,NomType,i1,i2,j1,j2);
if sub_value
    filename_1=fullfile_uvmat(InputFile.RootPath_1,InputFile.SubDir_1,InputFile.RootFile_1,InputFile.FileExt_1,InputFile.NomType_1,i1_1,i2_1,j1_1,j2_1);
end

%% refresh plots
errormsg=refresh_field(handles,filename,filename_1,i1,i2,j1,j2,i1_1,i2_1,j1_1,j2_1);

%% update the index counters if the index move is successfull
if isempty(errormsg) 
    set(handles.i1,'String',num2stra(i1,NomType,1));
    if isequal(i2,i1)
        set(handles.i2,'String','');
    else
        set(handles.i2,'String',num2stra(i2,NomType,1));
    end
    set(handles.j1,'String',num2stra(j1,NomType,2));
    if isequal(j2,j1)
        set(handles.j2,'String','');
    else
        set(handles.j2,'String',num2stra(j2,NomType,2));
    end
    indices=fullfile_uvmat('','','','',NomType,i1,i2,j1,j2);
    set(handles.FileIndex,'String',indices);
    if ~isempty(filename_1)
        indices_1=fullfile_uvmat('','','','',InputFile.NomType_1,i1_1,i2_1,j1_1,j2_1);
        set(handles.FileIndex_1,'String',indices_1);
    end
    if isequal(movie_status,1)
        set(handles.movie_pair,'Value',1)
        movie_pair_Callback(hObject, eventdata, handles); %reactivate moviepair if it was activated
    end
end

%------------------------------------------------------------------------
% --- Executes on button press in movie_pair: create an alternating movie with two view
function movie_pair_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%% stop movie action if the movie_pair button is off
if ~get(handles.movie_pair,'value')
    set(handles.movie_pair,'BusyAction','Cancel')%stop movie pair if button is 'off'
    set(handles.i2,'String','')
    set(handles.j2,'String','')
    return
else
    set(handles.movie_pair,'BusyAction','queue')
end

%% initialisation
set(handles.movie_pair,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
list_fields=get(handles.FieldName,'String');% list menu fields
index_fields=get(handles.FieldName,'Value');% selected string index
FieldName=list_fields{index_fields}; % selected field
UvData=get(handles.uvmat,'UserData');
if isequal(FieldName,'image')
    index=1;
    [RootPath,SubDir,RootFile,FileIndices,Ext]=read_file_boxes(handles);
    NomType=get(handles.NomType,'String');
else
    list_fields=get(handles.FieldName_1,'String');% list menu fields
    index_fields=get(handles.FieldName_1,'Value');% selected string index
    FieldName=list_fields{index_fields}; % selected field
    if isequal(FieldName,'image')
        index=2;
        [RootPath,tild,RootFile,FileIndex_1,Ext,NomType]=read_file_boxes_1(handles);
    else
        msgbox_uvmat('ERROR','an image or movie must be first introduced as input')
        set(handles.movie_pair,'BackgroundColor',[1 0 0])%paint the command button in red
        set(handles.movie_pair,'Value',0)
        return
    end
end
num_i1=str2num(get(handles.i1,'String'));
num_j1=stra2num(get(handles.j1,'String'));
num_i2=str2num(get(handles.i2,'String'));
num_j2=stra2num(get(handles.j2,'String'));
imaname_1='';
if isempty(num_j2)
    if isempty(num_i2)
        if strcmp(get(handles.j2,'Visible'),'on') %if the j box is visible
            imaname_1=fullfile_uvmat(RootPath,SubDir,RootFile,Ext,NomType,num_i1,[],num_j1+1);
        end
        if exist(imaname_1,'file')
            num_j2=num_j1+1;% look by default for the next j index as the second file
            set(handles.j2,'String',num2stra(num_j2,NomType));
        else
            imaname_1=fullfile_uvmat(RootPath,SubDir,RootFile,Ext,NomType,num_i1+1,[],num_j1);
            if exist(imaname_1,'file')
                num_i2=num_i1+1;
                set(handles.i2,'String',num2str(num_i2));
            else
                msgbox_uvmat('ERROR', 'a second image index i2 or j2 is needed to show the pair as a movie')
                set(handles.movie_pair,'BackgroundColor',[1 0 0])%paint the command button in red
                set(handles.movie_pair,'Value',0)
                return
            end
        end
    else
        num_j2=num_j1;%repeat the index i1 by default
    end
end
if isempty(num_i2)
    num_i2=num_i1;%repeat the index i1 by default
end
imaname_1=fullfile_uvmat(RootPath,SubDir,RootFile,Ext,NomType,num_i2,[],num_j2);
if strcmp(NomType,'*')
    num_frame=num_i2;
else
    num_frame=num_j2;
end
if ~exist(imaname_1,'file')
      msgbox_uvmat('ERROR',['second input open (-)  ' imaname_1 ' not found']);
      set(handles.movie_pair,'BackgroundColor',[1 0 0])%paint the command button in red
       set(handles.movie_pair,'Value',0)
      return
end

%% get the first image
%Field.AName='image';
if index==1
    Field_a=UvData.Field;% movie on the second field
else
    Field_a=UvData.Field_1;% movie on the first field
end

%% read the second image
MovieObject=[];
if numel(UvData.MovieObject)>=index
    MovieObject=UvData.MovieObject{index};
end
[Field_b,ParamOut,errormsg] = read_field(imaname_1,UvData.FileType{index},MovieObject,num_frame);
% Field_b.AX=Field_a.AX;
% Field_b.AY=Field_a.AY;
% % z index
% nbslice=str2double(get(handles.num_NbSlice,'String'));
% if ~isempty(nbslice)
%     Field_b.ZIndex=mod(num_i2-1,nbslice)+1;
% end
% Field_b.CoordUnit='pixel';
% 
% %% determine the input file type
% if (test_1 && isfield(UvData,'MovieObject')&& numel(UvData.MovieObject>=2))||(~test_1 && ~isempty(UvData.MovieObject{1}))
%     FileType='movie';
% elseif isequal(lower(Ext),'.avi')
%     FileType='avi';
% elseif isequal(lower(Ext),'.vol')
%     FileType='vol';
% else 
%    form=imformats(Ext(2:end));
%    if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
%        if isequal(NomType,'*');
%            FileType='multimage';
%        else
%            FileType='image';
%        end
%    end
% end
% switch FileType
%         case 'movie'
%             if test_1
%                 Field_b.A=read(UvData.MovieObject{2},num_i2);
%             else
%                 Field_b.A=read(UvData.MovieObject{1},num_i2);
%             end
%         case 'avi'
%             mov=aviread(imaname_1,num_i2);
%             Field_b.A=frame2im(mov(1));
%         case 'vol'
%             Field_b.A=imread(imaname_1);
%         case 'multimage'
%             Field_b.A=imread(imaname_1,num_i2);
%         case 'image'
%             Field_b.A=imread(imaname_1);
% end 
% if get(handles.slices,'Value')
%     Field.ZIndex=str2double(get(handles.z_index,'String'));
% end

%px to phys or other transform on field
transform=get(handles.TransformPath,'UserData');
if  ~isempty(transform)
    if isfield(UvData,'XmlData') && numel(UvData.XmlData)>=index %use geometry calib recorded from the ImaDoc xml file as first priority
        if index==2
        Field_a=transform(Field_a,UvData.XmlData{index});%the first field has been stored without transform
        end
        Field_b=transform(Field_b,UvData.XmlData{index});
    end
end

 % make movie until movie speed is set to 0 or STOP is activated
hima=findobj(handles.PlotAxes,'Tag','ima');% %handles.PlotAxes =main plotting window (A GENERALISER)
set(handles.STOP,'Visible','on')
set(handles.speed,'Visible','on')
set(handles.speed_txt,'Visible','on')
while get(handles.speed,'Value')~=0 && isequal(get(handles.movie_pair,'BusyAction'),'queue')%isequal(get(handles.run0,'BusyAction'),'queue'); % enable STOP command
    % read and plot the series of images in non erase mode
    set(hima,'CData',Field_b.A); 
    pause(1.02-get(handles.speed,'Value'));% wait for next image
    set(hima,'CData',Field_a.A);
    pause(1.02-get(handles.speed,'Value'));% wait for next image
end
set(handles.movie_pair,'BackgroundColor',[1 0 0])%paint the command button in red
 set(handles.movie_pair,'Value',0)

%------------------------------------------------------------------------
% --- Executes on button press in run0.
function run0_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.run0,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
[RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
filename=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];
filename_1='';%default
FileIndex_1='';
if get(handles.SubField,'Value')
    [RootPath_1,SubDir_1,RootFile_1,FileIndex_1,FileExt_1]=read_file_boxes_1(handles);
    filename_1=[fullfile(RootPath_1,SubDir_1,RootFile_1) FileIndex_1 FileExt_1];
end
num_i1=stra2num(get(handles.i1,'String'));
num_i2=stra2num(get(handles.i2,'String'));
num_j1=stra2num(get(handles.j1,'String'));
num_j2=stra2num(get(handles.j2,'String'));
[tild,tild,tild,i1_1,i2_1,j1_1,j2_1]=fileparts_uvmat(FileIndex_1);

errormsg=refresh_field(handles,filename,filename_1,num_i1,num_i2,num_j1,num_j2,i1_1,i2_1,j1_1,j2_1);

if ~isempty(errormsg)
      msgbox_uvmat('ERROR',errormsg);
else
    set(handles.i1,'BackgroundColor',[1 1 1])
    set(handles.i2,'BackgroundColor',[1 1 1])
    set(handles.j1,'BackgroundColor',[1 1 1])
    set(handles.j2,'BackgroundColor',[1 1 1])
    set(handles.FileIndex,'BackgroundColor',[1 1 1])
    set(handles.FileIndex_1,'BackgroundColor',[1 1 1])
end    
set(handles.run0,'BackgroundColor',[1 0 0])


%------------------------------------------------------------------------
% --- read the input files and refresh all the plots, including projection.
% OUTPUT: 
%  errormsg: error message char string  =[] by default
% INPUT:
% filename: first input file (=[] in the absence of input file)
% filename_1: second input file (=[] in the asbsenc of secodn input file) 
% num_i1,num_i2,num_j1,num_j2; frame indices
% Field: structure describing an optional input field (then replace the input file)

function errormsg=refresh_field(handles,FileName,FileName_1,num_i1,num_i2,num_j1,num_j2,i1_1,i2_1,j1_1,j2_1)
%------------------------------------------------------------------------

%% initialisation
abstime=[];
abstime_1=[];
dt=[];
if ~exist('Field','var')
    Field={};
end
UvData=get(handles.uvmat,'UserData');
if ishandle(handles.UVMAT_title) %remove title panel on uvmat
    delete(handles.UVMAT_title)
end

%% determine the main input file information for action
if ~exist(FileName,'file')
    errormsg=['input file ' FileName ' does not exist'];
    return
end
NomType=get(handles.NomType,'String');
NomType_1='';
if strcmp(get(handles.NomType_1,'Visible'),'on')
    NomType_1=get(handles.NomType_1,'String');
end
%update the z position index
mode_slice=get(handles.slices,'String');
if strcmp(mode_slice,'volume')
    z_index=num_j1;
    set(handles.z_index,'String',num2str(z_index))
else
    nbslice=str2num(get(handles.num_NbSlice,'String'));
    z_index=mod(num_i1-1,nbslice)+1;
    set(handles.z_index,'String',num2str(z_index))
end
% refresh menu for save_mask if relevant
masknumber=get(handles.masklevel,'String');
if length(masknumber)>=z_index
    set(handles.masklevel,'Value',z_index)
end

%% test for need of tps
check_proj_tps=0;
if  (strcmp(UvData.FileType{1},'civdata')||strcmp(UvData.FileType{1},'civx'))
    for iobj=1:numel(UvData.Object)
        if isfield(UvData.Object{iobj},'ProjMode')&& strcmp(UvData.Object{iobj}.ProjMode,'interp_tps')
            check_proj_tps=1;
            break
        end
    end
end

%% read the first input field 
ParamIn.ColorVar='';%default variable name for vector color
frame_index=1;%default
FieldName='';%default
VelType='';%default
switch UvData.FileType{1}
    case {'civx','civdata','netcdf'};
        list_fields=get(handles.FieldName,'String');% list menu fields
        FieldName= list_fields{get(handles.FieldName,'Value')}; % selected field
        % if get_field... is selected, the GUI get_field will be used to enter fields 
        if ~strcmp(FieldName,'get_field...')
            if get(handles.FixVelType,'Value')
                VelTypeList=get(handles.VelType,'String');
                VelType=VelTypeList{get(handles.VelType,'Value')};
            end
        end
        % case of input vector field, get the scalar used for vector color
        if ~isempty(regexp(FieldName,'^vec('))
            list_code=get(handles.ColorCode,'String');% list menu fields
            index_code=get(handles.ColorCode,'Value');% selected string index
            if  ~strcmp(list_code{index_code},'black') &&  ~strcmp(list_code{index_code},'white')
                list_code=get(handles.ColorScalar,'String');% list menu fields
                index_code=get(handles.ColorScalar,'Value');% selected string index
                ParamIn.ColorVar= list_code{index_code}; % selected field
            end
        end
    case {'video','mmreader'}
        ParamIn=UvData.MovieObject{1};      
        if ~strcmp(NomType,'*')
            frame_index=num_j1;%frame index for movies or multimage
        else
            frame_index=num_i1;
        end
    case 'multimage'
        if ~strcmp(NomType,'*')
            frame_index=num_j1;%frame index for movies or multimage
        else
            frame_index=num_i1;
        end
    case 'vol' %TODO: update
        if isfield(UvData.XmlData,'Npy') && isfield(UvData.XmlData,'Npx')
            ParamIn.Npy=UvData.XmlData.Npy;
            ParamIn.Npx=UvData.XmlData.Npx;
        else            
            errormsg='Npx and Npy need to be defined in the xml file for volume images .vol';
            return
        end
end
if isstruct (ParamIn)
    ParamIn.FieldName=FieldName;
    ParamIn.VelType=VelType;
    XNameMenu=get(handles.Coord_x,'String');
    if ~isempty(XNameMenu)
        ParamIn.Coord_x=XNameMenu(get(handles.Coord_x,'Value'));
    end
    YNameMenu=get(handles.Coord_y,'String');
    if ~isempty(YNameMenu)
        ParamIn.Coord_y=YNameMenu(get(handles.Coord_y,'Value'));
    end
end
check_tps = 0;         
if strcmp(UvData.FileType{1},'civdata')&&~strcmp(ParamIn.FieldName,'velocity')&&~strcmp(ParamIn.FieldName,'get_field...') 
       check_tps=1;%tps needed to get the requested field
end
[Field{1},ParamOut,errormsg] = read_field(FileName,UvData.FileType{1},ParamIn,frame_index);
if ~isempty(errormsg)
    errormsg=['uvmat / refresh_field / read_field( ' FileName ') / ' errormsg];
    return
end  
if isfield(ParamOut,'Npx')&& isfield(ParamOut,'Npy')
    set(handles.num_Npx,'String',num2str(ParamOut.Npx));% display image size on the interface
    set(handles.num_Npy,'String',num2str(ParamOut.Npy));
end
if isfield(ParamOut,'TimeIndex')% case of time obtained from get_field
    set(handles.i1,'String',num2str(ParamOut.TimeIndex))
end
if isfield(ParamOut,'TimeValue')
    Field{1}.Time=ParamOut.TimeValue;% case of time obtained from get_field
end
Field{1}.ZIndex=z_index; %used for multiplane 3D calibration


%% choose and read a second field FileName_1 if defined
VelType_1=[];%default
FieldName_1=[];
ParamIn_1=[];
ParamOut_1=[];
frame_index_1=1;
if ~isempty(FileName_1)
    if ~exist(FileName_1,'file')
        errormsg=['second file ' FileName_1 ' does not exist'];
        return
    end
   % Name=FileName_1;
    switch UvData.FileType{2}
        case {'civx','civdata','netcdf'};
            list_fields=get(handles.FieldName_1,'String');% list menu fields
            if ischar(list_fields),list_fields={list_fields};end
            FieldName_1= list_fields{get(handles.FieldName_1,'Value')}; % selected field
            if ~strcmp(FieldName,'get_field...')
                if get(handles.FixVelType,'Value')
                    VelTypeList=get(handles.VelType_1,'String');
                    VelType_1=VelTypeList{get(handles.VelType_1,'Value')};% read the velocity type.
                end
            end
            if strcmp(FieldName_1,'velocity')&& strcmp(get(handles.ColorCode,'Visible'),'on')
                list_code=get(handles.ColorCode,'String');% list menu fields
                index_code=get(handles.ColorCode,'Value');% selected string index
                if  ~strcmp(list_code{index_code},'black') &&  ~strcmp(list_code{index_code},'white')
                    list_code=get(handles.ColorScalar,'String');% list menu fields
                    index_code=get(handles.ColorScalar,'Value');% selected string index
                    ParamIn_1.ColorVar= list_code{index_code}; % selected field for vector color display                  
                end
            end
        case {'video','mmreader'}
            ParamIn_1=UvData.MovieObject{2};
                        if ~strcmp(NomType_1,'*')
                frame_index_1=j1_1;%frame index for movies or multimage
            else
                frame_index_1=i1_1;
            end  
         case 'multimage'
            if ~strcmp(NomType_1,'*')
                frame_index_1=j1_1;%frame index for movies or multimage
            else
                frame_index_1=i1_1;
            end   
        case 'vol' %TODO: update
            if isfield(UvData.XmlData,'Npy') && isfield(UvData.XmlData,'Npx')
                ParamIn_1.Npy=UvData.XmlData.Npy;
                ParamIn_1.Npx=UvData.XmlData.Npx;
            else
                errormsg='Npx and Npy need to be defined in the xml file for volume images .vol';
                return
            end
    end
    if isequal(get(handles.NomType_1,'Visible'),'on')
    NomType_1=get(handles.NomType_1,'String');
    else
        NomType_1=get(handles.NomType,'String');
    end
    test_keepdata_1=0;% test for keeping the previous stored data if the input files are unchanged
    if ~isequal(NomType_1,'*')&& isfield(UvData,'FileName_1')
           test_keepdata_1= strcmp(FileName_1,UvData.FileName_1) ;
    end
    if test_keepdata_1
        Field{2}=UvData.Field_1;% keep the stored field
        ParamOut_1=UvData.ParamOut_1;
    else
        if isempty(ParamIn_1) || isstruct(ParamIn_1)
        ParamIn_1.FieldName=FieldName_1;
        ParamIn_1.VelType=VelType_1;
        ParamIn_1.GUIName='get_field_1';
        end  
        [Field{2},ParamOut_1,errormsg] = read_field(FileName_1,UvData.FileType{2},ParamIn_1,frame_index_1);
        if ~isempty(errormsg)
            errormsg=['error in reading ' FieldName_1 ' in ' FileName_1 ': ' errormsg];
            return
        end
        if isstruct(ParamOut_1)&&~strcmp(ParamOut_1.FieldName,'get_field...')&& (strcmp(UvData.FileType{2},'civdata')||strcmp(UvData.FileType{2},'civx'))...
                &&~strcmp(ParamOut_1.FieldName,'velocity') && ~strcmp(ParamOut_1.FieldName,'get_field...')
            if ~check_proj_tps
             %   Field{2}=calc_field([{ParamOut_1.FieldName} {ParamOut_1.ColorVar}],Field{2});
            end
        end
    end
    Field{2}.ZIndex=z_index;%used for multi-plane 3D calibration
end

%% update uvmat interface
if isfield(ParamOut,'Npx')
    set(handles.num_Npx,'String',num2str(ParamOut.Npx));% display image size on the interface
    set(handles.num_Npy,'String',num2str(ParamOut.Npy));
elseif isfield(ParamOut_1,'Npx')
    set(handles.num_Npx,'String',num2str(ParamOut_1.Npx));% display image size on the interface
    set(handles.num_Npy,'String',num2str(ParamOut_1.Npy));
end

%% update the display menu for the first velocity type (first menuline)
test_veltype=0;
% if ~isequal(FileType,'netcdf')|| isequal(FieldName,'get_field...')
if (strcmp(UvData.FileType{1},'civx')||strcmp(UvData.FileType{1},'civdata'))&& ~strcmp(FieldName,'get_field...')
    test_veltype=1;
    set(handles.VelType,'Visible','on')
    set(handles.VelType_1,'Visible','on')
    set(handles.FixVelType,'Visible','on')
    menu=set_veltype_display(ParamOut.CivStage,UvData.FileType{1});
    index_menu=strcmp(ParamOut.VelType,menu);%look for VelType in  the menu
    index_val=find(index_menu,1);
    if isempty(index_val)
        index_val=1;
    end
    set(handles.VelType,'Value',index_val)
    if ~get(handles.SubField,'value')
        set(handles.VelType,'String',menu)
        set(handles.VelType_1,'Value',1)
        set(handles.VelType_1,'String',[{''};menu])
    end
else
    set(handles.VelType,'Visible','off')
end
% display the FieldName menu from the input file and pick the selected one: 
% if isstruct(ParamOut)
%     field_index=strcmp(ParamOut.FieldName,ParamOut.FieldList);
%     set(handles.FieldName,'String',ParamOut.FieldList); %update the field menu
%     set(handles.FieldName,'Value',find(field_index,1))
% end

%% update the display menu for the second velocity type (second menuline)
test_veltype_1=0;
if isempty(FileName_1)
    %     set(handles.FieldName_1,'Value',1); %update the field menu
    %     if isstruct(ParamOut)
    %     set(handles.FieldName_1,'String',[{''};ParamOut.FieldList]); %update the field menu
    %     end
elseif ~test_keepdata_1
    if (~strcmp(UvData.FileType{2},'netcdf')&&~strcmp(UvData.FileType{2},'civdata')&&~strcmp(UvData.FileType{2},'civx'))|| isequal(FieldName_1,'get_field...')
        set(handles.VelType_1,'Visible','off')
    else
        test_veltype_1=1;
        set(handles.VelType_1,'Visible','on')
        menu=set_veltype_display(ParamOut_1.CivStage,UvData.FileType{2});
        index_menu=strcmp(ParamOut_1.VelType,menu);
        set(handles.VelType_1,'Value',1+find(index_menu,1))
        set(handles.VelType_1,'String',[{''};menu])
    end
    % update the second field menu: the same quantity
    if isstruct(ParamOut_1)
%        set(handles.FieldName_1,'String',[{''};ParamOut_1.FieldList]); %update the field menu
        % display the FieldName menu from the input file and pick the selected one:
        FieldList=get(handles.FieldName_1,'String');
        field_index=strcmp(ParamOut_1.FieldName,FieldList);
        if ~isempty(field_index)
            set(handles.FieldName_1,'Value',find(field_index,1))
        end
    end
end
if test_veltype||test_veltype_1
    set(handles.FixVelType,'Visible','on')
else
    set(handles.FixVelType,'Visible','off')
end

% field_index=strcmp(ParamOut_1.FieldName,ParamOut_1.FieldList);
% set(handles.FieldName,'String',ParamOut.FieldList); %update the field menu
% set(handles.FieldName,'Value',find(field_index,1))
    
%% introduce w as background image by default for a new series (only for nbdim=2)
if ~isfield(UvData,'NewSeries')
    UvData.NewSeries=1;
end
%put W as background image by default if NbDim=2:
if  UvData.NewSeries && isequal(get(handles.SubField,'Value'),0) && isfield(Field{1},'W') && ~isempty(Field{1}.W) && ~isequal(Field{1}.NbDim,3);
        set(handles.SubField,'Value',1);
        set(handles.RootPath_1,'String','"')
        set(handles.RootFile_1,'String','"')
        set(handles.SubDir_1,'String','"');
         indices=fullfile_uvmat('','','','',NomType,num_i1,num_i2,num_j1,num_j2);
        set(handles.FileIndex_1,'String',indices)
        set(handles.FileExt_1,'String','"');
        set(handles.FieldName_1,'Visible','on');
        set(handles.FieldName_1,'Visible','on');
        set(handles.RootPath_1,'Visible','on')
        set(handles.RootFile_1,'Visible','on')
        set(handles.SubDir_1,'Visible','on');
        set(handles.FileIndex_1,'Visible','on');
        set(handles.FileExt_1,'Visible','on');
        set(handles.FieldName_1,'Visible','on');
        Field{1}.AName='w';
end           

%% display time
testimedoc=0;
TimeUnit='';
if isfield(Field{1},'Time')
    abstime=Field{1}.Time;%time read from the netcdf input file 
end
if numel(Field)==2 && isfield(Field{2},'Time')
    abstime_1=Field{2}.Time;%time read from the netcdf input file 
end
if isfield(Field{1},'Dt')
    dt=Field{1}.Dt;%dt read from the netcdf input file
    if isfield(Field{1},'TimeUnit')
       TimeUnit=Field{1}.TimeUnit;
    end
elseif numel(Field)==2 && isfield(Field{2},'Dt')%dt obtained from the second field if not defined in the first
    dt=Field{2}.Dt;%dt read from the netcdf input file
    if isfield(Field{2},'TimeUnit')
       TimeUnit=Field{2}.TimeUnit;
    end
end
% time from xml file overset previous result
if isfield(UvData,'XmlData') && isfield(UvData.XmlData{1},'Time')
    if isempty(num_i2)||isnan(num_i2)
        num_i2=num_i1;
    end
    if isempty(num_j1)||isnan(num_j1)
        num_j1=1;
    end
    if isempty(num_j2)||isnan(num_j2)
        num_j2=num_j1;
    end
    siz=size(UvData.XmlData{1}.Time);
    if ~isempty(num_i1)&& ~isempty(num_i2) && num_i1>0 &&siz(1)>=max(num_i1,num_i2) && siz(2)>=max(num_j1,num_j2)
        abstime=(UvData.XmlData{1}.Time(num_i1,num_j1)+UvData.XmlData{1}.Time(num_i2,num_j2))/2;%overset the time read from files
        dt=(UvData.XmlData{1}.Time(num_i2,num_j2)-UvData.XmlData{1}.Time(num_i1,num_j1));
        Field{1}.Dt=dt;
        if isfield(UvData.XmlData{1},'TimeUnit')
            TimeUnit=UvData.XmlData{1}.TimeUnit;
        end
    end
    if numel(UvData.XmlData)==2
        if isempty(i2_1)
            i2_1=num_i1;
        end
        if isempty(j1_1)
            j1_1=1;
        end
        if isempty(j2_1)
            j2_1=j1_1;
        end
        siz=size(UvData.XmlData{2}.Time);
        if ~isempty(i1_1) && siz(1)>=max(i1_1,i2_1) && siz(2)>=max(j1_1,j2_1)
            abstime_1=(UvData.XmlData{2}.Time(i1_1,j1_1)+UvData.XmlData{2}.Time(i2_1,j2_1))/2;%overset the time read from files
            Field{2}.Dt=(UvData.XmlData{2}.Time(i2_1,j2_1)-UvData.XmlData{2}.Time(i1_1,j1_1));
        end
    end
end
if ~isequal(numel(abstime),1)
    abstime=[];
end
if ~isequal(numel(abstime_1),1)
      abstime_1=[];
end  
set(handles.abs_time,'String',num2str(abstime,5))
set(handles.abs_time_1,'String',num2str(abstime_1,5))
if isempty(dt)||isequal(dt,0)
    set(handles.Dt_txt,'String','')
else
    if  isempty(TimeUnit)
        set(handles.Dt_txt,'String',['Dt=' num2str(1000*dt,3) '  10^(-3)'] )
    else
        set(handles.Dt_txt,'String',['Dt=' num2str(1000*dt,3) '  m' TimeUnit] )
    end
end


%% store the current open names, fieldname and vel types in uvmat interface 
UvData.FileName_1=FileName_1;
UvData.ParamOut_1=ParamOut_1;
if numel(Field)==2
UvData.Field_1=Field{2}; %store the second field for possible use at next RUN
end

%% apply coordinate transform or other user fct
transform=get(handles.TransformPath,'UserData');
if isempty(transform)
    UvData.Field=Field{1};
else
    XmlData=[];%default
    XmlData_1=[];%default
    if isfield(UvData,'XmlData')%use geometry calib recorded from the ImaDoc xml file as first priority
        XmlData=UvData.XmlData{1};
        if numel(UvData.XmlData)==2
            XmlData_1=UvData.XmlData{2};
        end
    end
    transform=get(handles.TransformPath,'UserData');
    switch nargin(transform)
        case 4
            if length(Field)==2
                UvData.Field=transform(Field{1},XmlData,Field{2},XmlData_1);
            else
                UvData.Field=transform(Field{1},XmlData);
            end
        case 3
            if length(Field)==2
                UvData.Field=transform(Field{1},XmlData,Field{2});
            else
                UvData.Field=transform(Field{1},XmlData);
            end
        case 2
            UvData.Field=transform(Field{1},XmlData);
        case 1
            UvData.Field=transform(Field{1});
    end
end

%% calculate tps coefficients if needed
UvData.Field=tps_coeff_field(UvData.Field,check_proj_tps);

%% analyse input field
%test_x=0;
%test_z=0;% test for unstructured z coordinate
%[errormsg,ListDimName,DimValue,VarDimIndex]=check_field_structure(UvData.Field);% check the input field structure
% if ~isempty(errormsg)
%     errormsg=['error in uvmat/refresh_field/check_field_structure: ' errormsg];% display error
%     return
% end
[CellInfo,NbDimArray,errormsg]=find_field_cells(UvData.Field);% analyse  the input field structure
if ~isempty(errormsg)
    errormsg=['uvmat /refresh_field / find_field_cells / ' errormsg];% display error
    return
end

NbDim=max(NbDimArray);% spatial dimension of the input field
imax=find(NbDimArray==NbDim);% indices of field cells to consider
if isfield(UvData.Field,'NbDim')
    NbDim=double(UvData.Field.NbDim);% deal with plane fields containing z coordinates
end

%UvData.Field=get_bounds(UvData.Field);

%% get bounds and mesh (needed  to propose default options for projection objects)
if NbDim>1
    CoordMax=zeros(numel(imax),NbDim);
    CoordMin=zeros(numel(imax),NbDim);
    Mesh=zeros(1,numel(imax));
    for ind=1:numel(imax)
        if strcmp(CellInfo{imax(ind)}.CoordType,'tps')
            CoordName=UvData.Field.ListVarName{CellInfo{imax(ind)}.CoordIndex};% X,Y coordinates in a single variable
            CoordMax(ind,NbDim)=max(max(UvData.Field.(CoordName)(1:end-3,1,:),[],1),[],3);% max of x component (2D case)
            CoordMax(ind,NbDim-1)=max(max(UvData.Field.(CoordName)(1:end-3,2,:),[],1),[],3);% max of y component (2D case)
            CoordMin(ind,NbDim)=min(min(UvData.Field.(CoordName)(1:end-3,1,:),[],1),[],3);
            CoordMin(ind,NbDim-1)=min(min(UvData.Field.(CoordName)(1:end-3,2,:),[],1),[],3);% min of y component (2D case)
        else
            XName=UvData.Field.ListVarName{CellInfo{imax(ind)}.CoordIndex(end)};
            YName=UvData.Field.ListVarName{CellInfo{imax(ind)}.CoordIndex(end-1)};
            CoordMax(ind,NbDim)=max(max(UvData.Field.(XName)));
            CoordMin(ind,NbDim)=min(min(UvData.Field.(XName)));
            CoordMax(ind,NbDim-1)=max(max(UvData.Field.(YName)));
            CoordMin(ind,NbDim-1)=min(min(UvData.Field.(YName)));
            %         test_x=1;%test for unstructured coordinates
            if NbDim==3
                ZName=UvData.Field.ListVarName{CellInfo{imax(ind)}.CoordIndex(1)};
                CoordMax(imax(ind),1)=max(max(UvData.Field.(ZName)));
                CoordMin(ind,1)=min(min(UvData.Field.(ZName)));
            end
        end
        switch CellInfo{imax(ind)}.CoordType
            
            case {'scattered','tps'} %unstructured coordinates
                NbPoints=CellInfo{imax(ind)}.CoordSize;% total nbre of points
                Mesh(ind)=(prod(CoordMax(ind,:)-CoordMin(ind,:))/NbPoints)^(1/NbDim); %(volume or area per point)^(1/NbDim)
            case 'grid'%structured coordinate
                NbPoints=CellInfo{imax(ind)}.CoordSize;% nbre of points in each direction
                Mesh(ind)=min((CoordMax(ind,:)-CoordMin(ind,:))./(NbPoints-1));                
        end
    end
    UvData.Field.CoordMesh=min(Mesh);
    UvData.Field.XMax=max(CoordMax(ind,end));
    UvData.Field.XMin=min(CoordMin(ind,end));
    UvData.Field.YMax=max(CoordMax(ind,end-1));
    UvData.Field.YMin=max(CoordMin(ind,end-1));
    if NbDim==3
        UvData.Field.ZMax=max(CoordMax(ind,1));
        UvData.Field.ZMin=max(CoordMin(ind,1));
    end
    % adjust the mesh to a value 1, 2 , 5 *10^n
    ord=10^(floor(log10(UvData.Field.CoordMesh)));%order of magnitude
    if UvData.Field.CoordMesh/ord>=5
        UvData.Field.CoordMesh=5*ord;
    elseif UvData.Field.CoordMesh/ord>=2
        UvData.Field.CoordMesh=2*ord;
    else
        UvData.Field.CoordMesh=ord;
    end
    % default projection plane
    if isempty(UvData.Object{1})
        UvData.Object{1}.Type='plane';%main plotting plane
        UvData.Object{1}.ProjMode='projection';%main plotting plane
        UvData.Object{1}.DisplayHandle.uvmat=[]; %plane not visible in uvmat
        UvData.Object{1}.DisplayHandle.view_field=[]; %plane not visible in uvmat
    end
    %% 3D case (menuvolume)
    if NbDim==3% && UvData.NewSeries
        test_set_object=1;
        hset_object=findobj(allchild(0),'tag','set_object');% look for the set_object GUI
        ZBounds(1)=UvData.Field.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.Field.ZMax;%maximum for the Z slider
        if ~isempty(hset_object) %if set_object is detected
            delete(hset_object);% delete the GUI set_object if it does not fit
        end
        if test_set_object% reinitiate the GUI set_object
            delete_object(1);% delete the current projection object in the list UvData.Object, delete its graphic representations and update the list displayed in handles.ListObject and 2
            UvData.Object{1}.NbDim=NbDim;%test for 3D objects
            UvData.Object{1}.RangeZ=UvData.Field.CoordMesh;%main plotting plane
            UvData.Object{1}.Coord(1,3)=(UvData.Field.ZMin+UvData.Field.ZMax)/2;%section at a middle plane chosen
            UvData.Object{1}.Angle=[0 0 0];
            UvData.Object{1}.HandlesDisplay=plot(0,0,'Tag','proj_object');% A REVOIR
            UvData.Object{1}.Name='1-PLANE';
            UvData.Object{1}.enable_plot=1;
            set_object(UvData.Object{1},handles,ZBounds);
            set(handles.ListObject,'Value',1);
            set(handles.ListObject,'String',{'1-PLANE'});
            set(handles.edit_object,'Value',1)% put the plane in edit mode to enable the z cursor
            edit_object_Callback([],[], handles)
        end
        %multilevel case (single menuplane in a 3D space)
    elseif isfield(UvData,'Z')
        if isfield(UvData,'CoordType')&& isequal(UvData.CoordType,'phys') && isfield(UvData,'XmlData')
            XmlData=UvData.XmlData{1};
            if isfield(XmlData,'PlanePos')
                UvData.Object{1}.Coord=XmlData.PlanePos(UvData.ZIndex,:);
            end
            if isfield(XmlData,'PlaneAngle')
                siz=size(XmlData.PlaneAngle);
                indangle=min(siz(1),UvData.ZIndex);%take first angle if a single angle is defined (translating scanning)
                UvData.Object{1}.PlaneAngle=XmlData.PlaneAngle(indangle,:);
            end
        elseif isfield(UvData,'ZIndex')
            UvData.Object{1}.ZObject=UvData.ZIndex;
        end
    end
end

testnewseries=UvData.NewSeries;
UvData.NewSeries=0;% put to 0 the test for a new field series (set by RootPath_callback)
set(handles.uvmat,'UserData',UvData)

%% reset the min and max of scalar if only the mask is displayed(TODO: check the need)
% if isfield(UvData,'Mask')&& ~isfield(UvData,'A')
%     set(handles.num_MinA,'String','0')
%     set(handles.num_MaxA,'String','255')
% end

%% usual 1D (x,y) plots
if NbDim<=1
    set(handles.Objects,'Visible','off')
    set(handles.ListObject_1_title,'Visible','off')
    set(handles.ListObject_1,'Visible','off')
    [PlotType,PlotParamOut]=plot_field(UvData.Field,handles.PlotAxes,read_GUI(handles.uvmat));
    errormsg=fill_GUI(PlotParamOut,handles.uvmat);
    for list={'Scalar','Vectors'}
        if ~isfield(PlotParamOut,list{1})
            set(handles.(list{1}),'Visible','off')
        end
    end
    %write_plot_param(handles,PlotParamOut) %update the auto plot parameters
    
%% 2D or 3D fieldname are generally projected
else
    set(handles.Objects,'Visible','on')
    set(handles.ListObject_1_title,'Visible','on')
    set(handles.ListObject_1,'Visible','on')
    
    %% Plot the projections on the selected  projection objects
    % main projection object (uvmat display)
    list_object=get(handles.ListObject_1,'String');
    if isequal(list_object,{''})||isequal(list_object,' ')%refresh list of objects if the menu is empty
        set(handles.ListObject,'Value',1)
        set(handles.ListObject,'String',{'plane'})
        UvData.Object{1}.Type='plane';%main plotting plane
        UvData.Object{1}.ProjMode='projection';%main plotting plane
        UvData.Object{1}.DisplayHandle.uvmat=[]; %plane not visible in uvmat
        UvData.Object{1}.DisplayHandle.view_field=[]; %plane not visible in uvmat
        set(handles.ListObject_1,'Value',1)
        set(handles.ListObject_1,'String',{'plane'})
    end
    IndexObj(1)=get(handles.ListObject_1,'Value');%selected projection object for main view
    if IndexObj(1)> numel(UvData.Object)
        IndexObj(1)=1;%select the first object if the selected one does not exist
        set(handles.ListObject_1,'Value',1)
    end
    IndexObj(2)=get(handles.ListObject,'Value');%selected projection object for main view
    if isequal(IndexObj(2),IndexObj(1))
        IndexObj(2)=[];
    end
    plot_handles{1}=handles;
    if isfield(UvData,'plotaxes')%case of movies
        haxes(1)=UvData.plotaxes;
    else
        haxes(1)=handles.PlotAxes;
    end
    PlotParam{1}=read_GUI(handles.uvmat);
    %default settings if vectors not visible
    if ~isfield(PlotParam{1},'Vectors')
        PlotParam{1}.Vectors.MaxVec=1;
        PlotParam{1}.Vectors.MinVec=0;
        PlotParam{1}.Vectors.CheckFixVecColor=1;
        PlotParam{1}.Vectors.ColCode1=0.33;
        PlotParam{1}.Vectors.ColCode2=0.66;
        PlotParam{1}.Vectors.ColorScalar={''};
        PlotParam{1}.Vectors.ColorCode= {'rgb'};
    end
    PosColorbar{1}=UvData.OpenParam.PosColorbar;%prescribe the colorbar position on the uvmat interface
    
    %% second projection object (view_field display)
    if length( IndexObj)>=2
        view_field_handle=findobj(allchild(0),'tag','view_field');%handles of the view_field GUI
        if ~isempty(view_field_handle)
            plot_handles{2}=guidata(view_field_handle);
            haxes(2)=plot_handles{2}.PlotAxes;
            PlotParam{2}=read_GUI(view_field_handle);
           % PlotParam{2}=read_GUI(handles.uvmat);%read plotting parameters on the uvmat interface
            PosColorbar{2}='*'; %TODO: deal with colorbar position on view_field
        end
    end
    
    %% loop on the projection objects: one or two
    
    for imap=1:numel(IndexObj)
        iobj=IndexObj(imap);
        if numel(UvData.Object)<iobj
            break
        end
        [ObjectData,errormsg]=proj_field(UvData.Field,UvData.Object{iobj});% project field on the object
        if ~isempty(errormsg)
            return
        end
        if testnewseries
            PlotParam{imap}.Scalar.CheckBW=[]; %B/W option depends on the input field (image or scalar)
            if isfield(ObjectData,'CoordUnit')
                PlotParam{imap}.Coordinates.CheckFixAspectRatio=1;% set x and y scaling equal if CoordUnit is defined (common unit for x and y)
                PlotParam{imap}.Coordinates.AspectRatio=1; %set aspect ratio to 1
            end
        end
        %use of mask (TODO: check)
        if isfield(ObjectData,'NbDim') && isequal(ObjectData.NbDim,2) && isfield(ObjectData,'Mask') && isfield(ObjectData,'A')
            flag_mask=double(ObjectData.Mask>200);%=0 for masked regions
            AX=ObjectData.AX;%x coordiantes for the scalar field
            AY=ObjectData.AY;%y coordinates for the scalar field
            MaskX=ObjectData.MaskX;%x coordiantes for the mask
            MaskY=ObjectData.MaskY;%y coordiantes for the mask
            if ~isequal(MaskX,AX)||~isequal(MaskY,AY)
                nxy=size(flag_mask);
                sizpx=(ObjectData.MaskX(end)-ObjectData.MaskX(1))/(nxy(2)-1);%size of a mask pixel
                sizpy=(ObjectData.MaskY(1)-ObjectData.MaskY(end))/(nxy(1)-1);
                x_mask=ObjectData.MaskX(1):sizpx:ObjectData.MaskX(end); % pixel x coordinates for image display
                y_mask=ObjectData.MaskY(1):-sizpy:ObjectData.MaskY(end);% pixel x coordinates for image display
                %project on the positions of the scalar
                npxy=size(ObjectData.A);
                dxy(1)=(ObjectData.AY(end)-ObjectData.AY(1))/(npxy(1)-1);%grid mesh in y
                dxy(2)=(ObjectData.AX(end)-ObjectData.AX(1))/(npxy(2)-1);%grid mesh in x
                xi=ObjectData.AX(1):dxy(2):ObjectData.AX(end);
                yi=ObjectData.AY(1):dxy(1):ObjectData.AY(end);
                [XI,YI]=meshgrid(xi,yi);% creates the matrix of regular coordinates
                flag_mask = interp2(x_mask,y_mask,flag_mask,XI,YI);
            end
            AClass=class(ObjectData.A);
            ObjectData.A=flag_mask.*double(ObjectData.A);
            ObjectData.A=feval(AClass,ObjectData.A);
        end
        if ~isempty(ObjectData)
            %PlotType='none'; %default
            if imap==2 && isempty(view_field_handle)
                view_field(ObjectData)
            else
                [PlotType,PlotParamOut]=plot_field(ObjectData,haxes(imap),PlotParam{imap},PosColorbar{imap});
                if imap==1
                    errormsg=fill_GUI(PlotParamOut,handles.uvmat);
                else
                    errormsg=fill_GUI(PlotParamOut,view_field_handle);
                end
                for list={'Scalar','Vectors'}
                    if ~isfield(PlotParamOut,list{1})
                        set(plot_handles{imap}.(list{1}),'Visible','off')
                    end
                end
                if isfield(Field,'CoordMesh')&&~isempty(Field.CoordMesh)
                    ObjectData.CoordMesh=Field.CoordMesh; % gives an estimated mesh size (useful for mouse action on the plot)
                end
            end
        end
    end
    
    %% update the mask
    if isequal(get(handles.CheckMask,'Value'),1)%if the mask option is on
        update_mask(handles,num_i1,num_i2);
    end
    
    %% prepare the menus of histograms and plot them (histogram of the whole volume in 3D case)
    menu_histo=(UvData.Field.ListVarName)';%list of field variables to be displayed for the menu of histogram display
    ind_skip=[];
    % nb_histo=1;
    Ustring='';
    Vstring='';
    % suppress coordinates from the histogram menu
    for ivar=1:numel(menu_histo)%l loop on field variables:
        if isfield(UvData.Field,'VarAttribute') && numel(UvData.Field.VarAttribute)>=ivar && isfield(UvData.Field.VarAttribute{ivar},'Role')
            Role=UvData.Field.VarAttribute{ivar}.Role;
            switch Role
                case {'coord_x','coord_y','coord_z','dimvar'}
                    ind_skip=[ind_skip ivar];
                case {'vector_x'}
                    Ustring=UvData.Field.ListVarName{ivar};
                    ind_skip=[ind_skip ivar];
                case {'vector_y'}
                    Vstring=UvData.Field.ListVarName{ivar};
                    ind_skip=[ind_skip ivar];
            end
        end
        DimCell=UvData.Field.VarDimName{ivar};
        DimName='';
        if ischar(DimCell)
            DimName=DimCell;
        elseif iscell(DimCell)&& numel(DimCell)==1
            DimName=DimCell{1};
        end
        if strcmp(DimName,menu_histo{ivar})
            ind_skip=[ind_skip ivar];
        end
    end
    menu_histo(ind_skip)=[];% remove skipped items
    if ~isempty(Ustring)
        menu_histo=[{[Ustring ',' Vstring]};menu_histo];% add U, V at the beginning if they exist
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % display menus and plot histograms
    test_v=0;
    if ~isempty(menu_histo)
        set(handles.histo1_menu,'Value',1)
        set(handles.histo1_menu,'String',menu_histo)
        histo1_menu_Callback(handles.histo1_menu, [], handles)% plot first histogram
    end
end

%------------------------------------------------------------------------
function histo1_menu_Callback(hObject, eventdata, handles)
%--------------------------------------------
histo_menu=get(handles.histo1_menu,'String');
histo_value=get(handles.histo1_menu,'Value');
FieldName=histo_menu{histo_value};

UvData=get(handles.uvmat,'UserData');
Field=UvData.Field;
r=regexp(FieldName,'(?<var1>.*)(?<sep>,)(?<var2>.*)','names');
FieldName_2='';
if ~isempty(r)
    FieldName=r.var1;
    FieldName_2=r.var2;
end
if ~isfield(UvData.Field,FieldName)
    msgbox_uvmat('ERROR',['no field  ' FieldName ' for histogram'])
    return
end
FieldHisto=Field.(FieldName);
if isfield(Field,'FF') && ~isempty(Field.FF) && isequal(size(Field.FF),size(FieldHisto))
    indsel=find(Field.FF==0);%find values marked as false
    if ~isempty(indsel)
        FieldHisto=FieldHisto(indsel);
        if ~isempty(FieldName_2)
            FieldHisto(:,:,2)=Field.(FieldName_2)(indsel);
        end
    end
end
if isempty(Field)
    msgbox_uvmat('ERROR',['empty field ' FieldName])
else
    nxy=size(FieldHisto);
    Amin=double(min(min(min(FieldHisto))));%min of field value
    Amax=double(max(max(max(FieldHisto))));%max of field value
    if isequal(Amin,Amax)
        cla(handles.HistoAxes)
    else
        Histo.ListVarName={FieldName,'histo'};
        if isfield(Field,'NbDim') && isequal(Field.NbDim,3)
            Histo.VarDimName={FieldName,FieldName}; %dimensions for the histogram
        else
            if numel(nxy)==2
                Histo.VarDimName={FieldName,FieldName}; %dimensions for the histogram
            else
                Histo.VarDimName={FieldName,{FieldName,'component'}}; %dimensions for the histogram
            end
        end
        %unit
        units=[]; %default
        for ivar=1:numel(Field.ListVarName)
            if strcmp(Field.ListVarName{ivar},FieldName)
                if isfield(Field,'VarAttribute') && numel(Field.VarAttribute)>=ivar && isfield(Field.VarAttribute{ivar},'units')
                    units=Field.VarAttribute{ivar}.units;
                    break
                end
            end
        end
        if ~isempty(units)
            Histo.VarAttribute{1}.units=units;
        end
        eval(['Histo.' FieldName '=linspace(Amin,Amax,50);'])%absissa values for histo
        if isfield(Field,'NbDim') && isequal(Field.NbDim,3)
            C=reshape(double(FieldHisto),1,[]);% reshape in a vector
            Histo.histo(:,1)=hist(C, Histo.(FieldName));  %calculate histogram
        else
            for col=1:size(FieldHisto,3)
                B=FieldHisto(:,:,col);
                C=reshape(double(B),1,nxy(1)*nxy(2));% reshape in a vector
                Histo.histo(:,col)=hist(C, Histo.(FieldName));  %calculate histogram
            end
        end
        plot_field(Histo,handles.HistoAxes);
        hlegend=legend;
        if isempty(FieldName_2)
        set(hlegend,'String',FieldName)
        else
            set(hlegend,'String',{FieldName;FieldName_2})
        end
    end
end

%-------------------------------------------------------------------
% --- translate coordinate to matrix index
%-------------------------------------------------------------------
function [indx,indy]=pos2ind(x0,rangx0,nxy)
indx=1+round((nxy(2)-1)*(x0-rangx0(1))/(rangx0(2)-rangx0(1)));% index x of pixel  
indy=1+round((nxy(1)-1)*(y12-rangy0(1))/(rangy0(2)-rangy0(1)));% index y of pixel


%-------------------------------------------------------------------
% --- Executes on button press in 'CheckZoom'.
%-------------------------------------------------------------------
function CheckZoom_Callback(hObject, eventdata, handles)

if (get(handles.CheckZoom,'Value') == 1); 
    set(handles.CheckZoom,'BackgroundColor',[1 1 0])
    set(handles.CheckFixLimits,'Value',1)% propose by default fixed limits for the plotting axes
    set(handles.CheckFixLimits,'BackgroundColor',[1 1 0]) 
else
    set(handles.CheckZoom,'BackgroundColor',[0.7 0.7 0.7])
end

%-------------------------------------------------------------------
% --- Executes on button press in 'CheckFixLimits'.
%-------------------------------------------------------------------
function CheckFixLimits_Callback(hObject, eventdata, handles)
test=get(handles.CheckFixLimits,'Value');
if test
    set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
else
    set(handles.CheckFixLimits,'BackgroundColor',[0.7 0.7 0.7])
    update_plot(handles);
end

%-------------------------------------------------------------------
% --- Executes on button press in CheckFixAspectRatio.
function CheckFixAspectRatio_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.CheckFixAspectRatio,'Value')
%     set(handles.CheckFixAspectRatio,'BackgroundColor',[1 1 0])
    update_plot(handles);
else
%     set(handles.CheckFixAspectRatio,'BackgroundColor',[0.7 0.7 0.7])
    update_plot(handles);
end

%-------------------------------------------------------------------
function num_AspectRatio_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
set(handles.CheckFixAspectRatio,'Value',1)% select the fixed aspect ratio button
% set(handles.CheckFixAspectRatio,'BackgroundColor',[1 1 0])% mark in yellow
update_plot(handles);
%-------------------------------------------------------------------

%-------------------------------------------------------------------



%-------------------------------------------------------------------
%----Executes on button press in 'record': records the current flags of manual correction.
%-------------------------------------------------------------------
function record_Callback(hObject, eventdata, handles)
% [filebase,num_i1,num_j1,num_i2,num_j2,Ext,NomType,SubDir]=read_input_file(handles);
[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
FileName=[fullfile(RootPath,SubDir,RootFile) FileIndices FileExt];
%FileName=read_file_boxes(handles);
[erread,message]=fileattrib(FileName);
if ~isempty(message) && ~isequal(message.UserWrite,1)
     msgbox_uvmat('ERROR',['no writting access to ' FileName])
     return
end
test_civ2=isequal(get(handles.civ2,'BackgroundColor'),[1 1 0]);
test_civ1=isequal(get(handles.VelType,'BackgroundColor'),[1 1 0]);
if ~test_civ2 && ~test_civ1
    msgbox_uvmat('ERROR','manual correction only possible for CIV1 or CIV2 velocity fields')
end 
if test_civ2
    nbname='nb_vectors2';
   flagname='vec2_FixFlag';
   attrname='fix2';
end
if test_civ1
    nbname='nb_vectors';
   flagname='vec_FixFlag';
   attrname='fix';
end
%write fix flags in the netcdf file
UvData=get(handles.uvmat,'UserData');
hhh=which('netcdf.open');% look for built-in matlab netcdf library
if ~isequal(hhh,'')% case of new builtin Matlab netcdf library
    nc=netcdf.open(FileName,'NC_WRITE'); 
    netcdf.reDef(nc);
    netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),attrname,1);
    dimid = netcdf.inqDimID(nc,nbname); 
    try
        varid = netcdf.inqVarID(nc,flagname);% look for already existing fixflag variable
    catch
        varid=netcdf.defVar(nc,flagname,'double',dimid);%create fixflag variable if it does not exist
    end
    netcdf.endDef(nc);
    netcdf.putVar(nc,varid,UvData.PlotAxes.FF);
    netcdf.close(nc);  
else %old netcdf library
    netcdf_toolbox(FileName,AxeData,attrname,nbname,flagname)
end

%-------------------------------------------------------------------
%----Correct the netcdf file, using toolbox (old versions of Matlab).
%-------------------------------------------------------------------
function netcdf_toolbox(FileName,AxeData,attrname,nbname,flagname)
nc=netcdf(FileName,'write'); %open netcdf file
result=redef(nc);
eval(['nc.' attrname '=1;']);
theDim=nc(nbname) ;% get the number of velocity vectors
nb_vectors=size(theDim);
var_FixFlag=ncvar(flagname,nc);% var_FixFlag will be written as the netcdf variable vec_FixFlag
var_FixFlag(1:nb_vectors)=AxeData.FF;% 
fin=close(nc);

%-------------------------------------------------------------------
% --- Executes on button press in SubField
function SubField_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
UvData=get(handles.uvmat,'UserData');
if get(handles.SubField,'Value')==0% if the subfield button is desactivated   
    set(handles.RootPath_1,'String','')
    set(handles.RootFile_1,'String','')
    set(handles.SubDir_1,'String','');
    set(handles.FileIndex_1,'String','');
    set(handles.FileExt_1,'String','');
    set(handles.RootPath_1,'Visible','off')
    set(handles.RootFile_1,'Visible','off')
    set(handles.SubDir_1,'Visible','off');
    set(handles.NomType_1,'Visible','off');
    set(handles.abs_time_1,'Visible','off')
    set(handles.FileIndex_1,'Visible','off');
    set(handles.FileExt_1,'Visible','off');
    set(handles.FieldName_1,'Value',1);%set to blank state
    set(handles.VelType_1,'Value',1);%set to blank state
    set(handles.num_Opacity,'String','')% desactivate opacity setting
    FieldList=get(handles.FieldName,'String');
    if numel(FieldList)>1   % if a choice of fields exists
        set(handles.FieldName_1,'Value',1)% set second field choice to blank
        set(handles.FieldName_1,'String',[{''};FieldList])% reproduce the menu FieldName plus a blank option
    else
        set(handles.FieldName_1,'String',{''})% set second field choice to blank
    end
    if ~strcmp(get(handles.VelType,'Visible'),'on')
        set(handles.VelType_1,'Visible','off')
    end
    if isfield(UvData,'XmlData_1')
        UvData=rmfield(UvData,'XmlData_1');
    end 
    set(handles.uvmat,'UserData',UvData);
    transform_fct_list=get(handles.TransformName,'String');
    transform_fct=transform_fct_list(get(handles.TransformName,'Value'));
    if strcmp(transform_fct,'sub_field')
        set(handles.TransformName,'Value',1)%suppress the sub_field transform
        transform_fct_Callback(hObject, eventdata, handles); 
    else
        run0_Callback(hObject, eventdata, handles)
    end  
else
    MenuBrowse_1_Callback(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% --- read the data displayed for the input rootfile windows (new): TODO use read_GUI

function [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles)
%------------------------------------------------------------------------
InputFile=read_GUI(handles.InputFile);
RootPath=InputFile.RootPath;
SubDir=regexprep(InputFile.SubDir,'/|\','');
RootFile=regexprep(InputFile.RootFile,'/|\','');
FileIndices=InputFile.FileIndex;
FileExt=InputFile.FileExt;


%------------------------------------------------------------------------
% ---- read the data displayed for the second input rootfile windows
function [RootPath_1,SubDir_1,RootFile_1,FileIndex_1,FileExt_1,NomType_1]=read_file_boxes_1(handles)
%------------------------------------------------------------------------
RootPath_1=get(handles.RootPath_1,'String'); % read the data from the file1_input window
if isequal(get(handles.RootPath_1,'Visible'),'off') || isequal(RootPath_1,'"')
    RootPath_1=get(handles.RootPath,'String');
end;
SubDir_1=get(handles.SubDir_1,'String');
if isequal(get(handles.SubDir_1,'Visible'),'off')|| isequal(SubDir_1,'"')
    SubDir_1=get(handles.SubDir,'String');
end
SubDir_1=regexprep(SubDir_1,'\<[\\/]|[\\/]\>','');%suppress possible / or \ separator at the beginning or the end of the string
RootFile_1=get(handles.RootFile_1,'String');
if isequal(get(handles.RootFile_1,'Visible'),'off') || isequal(RootFile_1,'"')
    RootFile_1=get(handles.RootFile,'String'); 
end
RootFile_1=regexprep(RootFile_1,'\<[\\/]|[\\/]\>','');%suppress possible / or \ separator at the beginning or the end of the string
FileIndex_1=get(handles.FileIndex_1,'String');
if isequal(get(handles.FileIndex_1,'Visible'),'off')|| isequal(FileIndex_1,'"')
    FileIndex_1=get(handles.FileIndex,'String');
end
FileExt_1=get(handles.FileExt_1,'String');
if isequal(get(handles.FileExt_1,'Visible'),'off') || isequal(FileExt_1,'"')
    FileExt_1=get(handles.FileExt,'String');%read FileExt by default
end
NomType_1=get(handles.NomType_1,'String');
if isequal(get(handles.NomType_1,'Visible'),'off') || isequal(NomType_1,'"')
    NomType_1=get(handles.NomType,'String');%read FileExt by default
end
%------------------------------------------------------------------------
% --- Executes on menu selection FieldName
function FieldName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
UvData=get(handles.uvmat,'UserData');
list_fields=get(handles.FieldName,'String');% list menu fields
index_fields=get(handles.FieldName,'Value');% selected string index
field= list_fields{index_fields(1)}; % selected string

%% fill the coordinates and variables from selections in get_field
if isequal(field,'get_field...')
    ParamIn=[];
    if strcmp(get(handles.VelType,'Visible'),'on')
        % we use the civ choice as default input
        ParamIn.SwitchVarIndexTime='attribute';
        ListVelType=get(handles.VelType,'String');
        VelType=ListVelType{get(handles.VelType,'Value')};
        switch VelType
            case 'civ1'
                 ParamIn.TimeVarName='Civ1_Time';
                 ParamIn.vector_x='Civ1_U';
                 ParamIn.vector_y='Civ1_V';
                 ParamIn.vec_color='Civ1_C';                
            case 'filter1'
                 ParamIn.TimeVarName='Civ1_Time';
                 ParamIn.vector_x='Civ1_U_smooth';
                 ParamIn.vector_y='Civ1_V_smooth';
            case 'civ2'
                 ParamIn.TimeVarName='Civ2_Time';
                 ParamIn.vector_x='Civ2_U';
                 ParamIn.vector_y='Civ2_V';
            case 'filter2'
                 ParamIn.TimeVarName='Civ2_Time';
                 ParamIn.vector_x='Civ2_U_smooth';
                 ParamIn.vector_y='Civ2_V_smooth';
                 ParamIn.vec_color='Civ2_C';
        end
    end
    set(handles.FixVelType,'visible','off')
    set(handles.VelType,'Visible','off')
    set(handles.VelType_1,'Visible','off')
    [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
    FileName=[fullfile(RootPath,SubDir,RootFile) FileIndices FileExt];
%     hget_field=findobj(allchild(0),'name','get_field');
%     if ~isempty(hget_field)
%         delete(hget_field)
%     end
    GetFieldData=get_field(FileName,ParamIn);
    FieldList={};
    VecColorList={};
    XName=GetFieldData.XVarName;
    if GetFieldData.CheckVector
        UName=GetFieldData.PanelVectors.vector_x;
        VName=GetFieldData.PanelVectors.vector_y;
        XName=GetFieldData.XVarName;
        YName=GetFieldData.YVarName;
        CName=GetFieldData.PanelVectors.vec_color;
        [FieldList,VecColorList]=set_field_list(UName,VName,CName);
    elseif GetFieldData.CheckScalar
        AName=GetFieldData.PanelScalar.scalar;
        XName=GetFieldData.XVarName;
        YName=GetFieldData.YVarName;
        FieldList={AName};
    elseif GetFieldData.CheckPlot1D;
        YName=GetFieldData.CheckPlot1D.ordinate;
    end
    set(handles.Coord_x,'String',{XName})
    set(handles.Coord_y,'String',{YName})
    set(handles.FieldName,'Value',1)
    set(handles.FieldName,'String',[FieldList; {'get_field...'}]);
    set(handles.ColorScalar,'Value',1)
    set(handles.ColorScalar,'String',VecColorList);
    UvData.FileType{1}='netcdf';
    set(handles.uvmat,'UserData',UvData)
    run0_Callback(hObject, eventdata, handles)
    return %no further action
end



%read the rootfile input display
[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
FileName=[fullfile(RootPath,SubDir,RootFile) FileIndices FileExt];
[tild,tild,tild,i1,i2,j1,j2,tild,NomType]=fileparts_uvmat(['xxx' get(handles.FileIndex,'String') FileExt]);
if isequal(field,'image')
    if  isfield(UvData.Field,'Civ2_ImageA')%get the corresponding input image in the netcdf file
        imagename=UvData.Field.Civ2_ImageA;
    elseif isfield(UvData.Field,'Civ1_ImageA')%
        imagename=UvData.Field.Civ1_ImageA;
    else
        SubDirBase=regexprep(SubDir,'\..*','');%take the root part of SubDir, before the first dot '.'
        imagename=fullfile_uvmat(RootPath,SubDirBase,RootFile,'.png',NomType,i1,[],j1,[]);
    end
    if ~exist(imagename,'file')
        [FileName,PathName] = uigetfile( ...
            {'*.png;*.jpg;*.tif;*.avi;*.AVI;*.vol', ' (*.png, .tif, *.avi,*.vol)';
            '*.jpg',' jpeg image files'; ...
            '*.png','.png image files'; ...
            '*.tif','.tif image files'; ...
            '*.avi;*.AVI','.avi movie files'; ...
            '*.vol','.volume images (png)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Pick an image',imagename); 
        if ~ischar(FileName),return,end %abandon if the browser is cancelled
        imagename=[PathName FileName];
    end
     % display the selected field and related information
    display_file_name(handles,imagename)%display the image
    return
else
    ext=get(handles.FileExt,'String');
    if ~isequal(ext,'.nc') %find the new NomType if the previous display was not already a netcdf file
        [FileName,PathName] = uigetfile( ...
            {'*.nc', ' (*.nc)';
            '*.nc',' netcdf files'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Pick a netcdf file',FileBase);
        if ~ischar(FileName),return,end %abandon if the browser is cancelled
        FullFileName=[PathName FileName];
        % display the selected field and related information
        display_file_name( handles,FullFileName)
        return
    end
end
indices=fullfile_uvmat('','','','',NomType,i1,i2,j1,j2);
set(handles.FileIndex,'String',indices)

%common to Fields_1_Callback
list_fields_1=get(handles.FieldName_1,'String');% list menu fields
field_1='';
if ~isempty(list_fields_1)
field_1= list_fields_1{get(handles.FieldName_1,'Value')}; % selected string
end
if isequal(field,'image')||isequal(field_1,'image')
    set(handles.TitleNpxy,'Visible','on')% visible npx,pxcm... buttons
    set(handles.num_Npx,'Visible','on')
    set(handles.num_Npy,'Visible','on')
else
    set(handles.TitleNpxy,'Visible','off')% visible npx,pxcm... buttons
    set(handles.num_Npx,'Visible','off')
    set(handles.num_Npy,'Visible','off')
end
if ~(isfield(UvData,'NewSeries')&&isequal(UvData.NewSeries,1))
    run0_Callback(hObject, eventdata, handles)
end

%---------------------------------------------------
% --- Executes on menu selection FieldName
function FieldName_1_Callback(hObject, eventdata, handles)
%-------------------------------------------------
%% read input data
check_new=~get(handles.SubField,'Value'); %check_new=1 if a second field was not previously entered
UvData=get(handles.uvmat,'UserData');
if check_new && isfield(UvData,'XmlData')
    UvData.XmlData{2}=UvData.XmlData{1};
end
if isfield(UvData,'Field_1')
    UvData=rmfield(UvData,'Field_1');% remove the stored second field (a new one needs to be read)
end
UvData.FileName_1='';% desactivate the use of a constant second file
list_fields=get(handles.FieldName,'String');% list menu fields
field= list_fields{get(handles.FieldName,'Value')}; % selected string
list_fields=get(handles.FieldName_1,'String');% list menu fields
field_1= list_fields{get(handles.FieldName_1,'Value')}; % selected string for the second field
if isempty(field_1)%||(numel(UvData.FileType)>=2 && strcmp(UvData.FileType{2},'image'))
    set(handles.SubField,'Value',0)
    SubField_Callback(hObject, eventdata, handles)
    return
else
    set(handles.SubField,'Value',1)%state that a second field is now entered
end

%% read the rootfile input display
[RootPath_1,SubDir_1,RootFile_1,FileIndex_1,FileExt_1]=read_file_boxes_1(handles);
FileName_1=[fullfile(RootPath_1,SubDir_1,RootFile_1) FileIndex_1 FileExt_1];
[tild,tild,tild,i1,i2,j1,j2]=fileparts_uvmat(get(handles.FileIndex,'String'));
switch field_1
    case 'get_field...'
        set_veltype_display(0) % no veltype display
        hget_field=findobj(allchild(0),'name','get_field_1');
        if ~isempty(hget_field)
            delete(hget_field)
        end
        hget_field=get_field(FileName_1);
        set(hget_field,'name','get_field_1')
        hhget_field=guidata(hget_field);
        set(hhget_field.list_fig,'Value',1)
        set(hhget_field.list_fig,'String',{'uvmat'})
        if check_new
            UvData.FileType{2}=UvData.FileType{1};
            set(handles.FileIndex_1,'String',get(handles.FileIndex,'String'))
              set(handles.uvmat,'UserData',UvData)
        end
    case 'image'
        % get the image name corresponding to the current netcdf name (no unique correspondance)
        if  isfield(UvData.Field,'Civ2_ImageA')%get the corresponding input image in the netcdf file
            imagename=UvData.Field.Civ2_ImageA;
        elseif isfield(UvData.Field,'Civ1_ImageA')%
            imagename=UvData.Field.Civ1_ImageA;
        else
            SubDirBase=regexprep(SubDir_1,'\..*','');%take the root part of SubDir, before the first dot '.'
            imagename=fullfile_uvmat(RootPath_1,SubDirBase,RootFile_1,'.png',get(handles.NomType,'String'),i1,[],j1);
        end
        if ~exist(imagename,'file') % browse for images if it is not found
            [FileName,PathName] = uigetfile( ...
                {'*.png;*.jpg;*.tif;*.avi;*.AVI;*.vol', ' (*.png, .tif, *.avi,*.vol)';
                '*.jpg',' jpeg image files'; ...
                '*.png','.png image files'; ...
                '*.tif','.tif image files'; ...
                '*.avi;*.AVI','.avi movie files'; ...
                '*.vol','.volume images (png)'; ...
                '*.*',  'All Files (*.*)'}, ...
                'Pick an image',imagename);
            if ~ischar(FileName),return,end %abandon if the browser is cancelled
            imagename=[PathName FileName];
        end
        if ~ischar(imagename)% quit if the browser has  been closed
            set(handles.SubField,'Value',0)
        else %valid browser input:  display the selected image
            set(handles.TitleNpxy,'Visible','on')% visible npx,pxcm... buttons
            set(handles.num_Npx,'Visible','on')
            set(handles.num_Npy,'Visible','on')
            display_file_name(handles,imagename,2)%display the imag
        end
    otherwise
        check_refresh=1;
        if check_new% if a second field was not previously entered, we just read another field in the first input file
            set(handles.FileIndex_1,'String',get(handles.FileIndex,'String'))
            set(handles.FileExt_1,'String',get(handles.FileExt,'String'))
            
            UvData.FileType{2}=UvData.FileType{1};
            UvData.XmlData{2}= UvData.XmlData{1};
            transform=get(handles.TransformPath,'UserData');
             if (~isa(transform,'function_handle')||nargin(transform)<3)
                set(handles.uvmat,'UserData',UvData)
                set(handles.TransformName,'value',2); % set transform fct to 'sub_field' if the current fct does not accept two input fields
                transform_fct_Callback(hObject, eventdata, handles)% activate transform_fct_Callback and refresh current plot
                 check_refresh=0;
             end             
        end
        if ~isequal(field,'image')
            set(handles.TitleNpxy,'Visible','off')% visible npx,pxcm... buttons
            set(handles.num_Npx,'Visible','off')
            set(handles.num_Npy,'Visible','off')
        end
        set(handles.uvmat,'UserData',UvData)
 
        if check_refresh && ~(isfield(UvData,'NewSeries')&&isequal(UvData.NewSeries,1))
            run0_Callback(hObject, eventdata, handles)
        end
end

%------------------------------------------------------------------------
% --- set the visibility of relevant velocity type menus: 
function menu=set_veltype_display(Civ,FileType)
%------------------------------------------------------------------------
if ~exist('FileType','var')
    FileType='civx';
end
switch FileType
    case 'civx'
        menu={'civ1';'interp1';'filter1';'civ2';'interp2';'filter2'};
        if isequal(Civ,0)
            imax=0;
        elseif isequal(Civ,1) || isequal(Civ,2)
            imax=1;
        elseif isequal(Civ,3)
            imax=3;
        elseif isequal(Civ,4) || isequal(Civ,5)
            imax=4;
        elseif isequal(Civ,6) %patch2
            imax=6;
        end
    case 'civdata'
        menu={'civ1';'filter1';'civ2';'filter2'};
        if isequal(Civ,0)
            imax=0;
        elseif isequal(Civ,1) || isequal(Civ,2)
            imax=1;
        elseif isequal(Civ,3)
            imax=2;
        elseif isequal(Civ,4) || isequal(Civ,5)
            imax=3;
        elseif isequal(Civ,6) %patch2
            imax=4;
        end
end
menu=menu(1:imax);

%------------------------------------------------------------------------
% --- Executes on button press in FixVelType.
function FixVelType_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% refresh the current plot if the fixed  veltype is unselected
if ~get(handles.FixVelType,'Value')
    run0_Callback(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% --- Executes on button press in VelType.
function VelType_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.FixVelType,'Value',1)
run0_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on choice selection in VelType_1.
function VelType_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.FixVelType,'Value',1)% the velocity type is now imposed by the GUI (not automatic)
UvData=get(handles.uvmat,'UserData');
set(handles.run0,'BackgroundColor',[1 1 0])%paint run0 button in yellow to indicate its activation
drawnow   
InputFile=read_GUI(handles.InputFile);% read the input file parameters
[RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
[RootPath_1,SubDir_1,RootFile_1,FileIndex_1,FileExt_1]=read_file_boxes_1(handles);
FileName=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];% name of the first input file

check_refresh=0;
if isempty(InputFile.VelType_1)
        FileName_1='';% we plot the first input field without the second field
        set(handles.SubField,'Value',0)
        SubField_Callback(hObject, eventdata, handles)% activate SubField_Callback and refresh current plot, removing the second field
elseif get(handles.SubField,'Value')% if subfield is already 'on'
     FileName_1=[fullfile(RootPath_1,SubDir_1,RootFile_1) FileIndex_1 FileExt_1];% name of the second input file
     check_refresh=1;%will refresh the current plot
else% we introduce the same file (with a different field) for the second series
     FileName_1=FileName;% we compare two fields in the same file 
     UvData.FileType{2}=UvData.FileType{1};
     UvData.XmlData{2}= UvData.XmlData{1};
     set(handles.SubField,'Value',1)
     transform=get(handles.TransformPath,'UserData');
     if (~isa(transform,'function_handle')||nargin(transform)<3)
        set(handles.uvmat,'UserData',UvData)
        set(handles.TransformName,'value',2); % set transform fct to 'sub_field' if the current fct does not accept two input fields
        transform_fct_Callback(hObject, eventdata, handles)% activate transform_fct_Callback and refresh current plot
     else
         check_refresh=1;
     end  
end

% refresh the current plot if it has not been done previously
if check_refresh
    UvData.FileName_1='';% desactivate the use of a constant second file
    set(handles.uvmat,'UserData',UvData)
    num_i1=stra2num(get(handles.i1,'String'));
    num_i2=stra2num(get(handles.i2,'String'));
    num_j1=stra2num(get(handles.j1,'String'));
    num_j2=stra2num(get(handles.j2,'String'));
    [tild,tild,tild,i1_1,i2_1,j1_1,j2_1]=fileparts_uvmat(['xx' FileIndex_1]);
    errormsg=refresh_field(handles,FileName,FileName_1,num_i1,num_i2,num_j1,num_j2,i1_1,i2_1,j1_1,j2_1);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg);
    else
        set(handles.i1,'BackgroundColor',[1 1 1])
        set(handles.i2,'BackgroundColor',[1 1 1])
        set(handles.j1,'BackgroundColor',[1 1 1])
        set(handles.j2,'BackgroundColor',[1 1 1])
        set(handles.FileIndex,'BackgroundColor',[1 1 1])
        set(handles.FileIndex_1,'BackgroundColor',[1 1 1])
    end
    set(handles.run0,'BackgroundColor',[1 0 0])
end


%-----------------------------------------------------------------------
% --- reset civ buttons
function reset_vel_type(handles_civ0,handle1)
%-----------------------------------------------------------------------
for ibutton=1:length(handles_civ0)
    set(handles_civ0(ibutton),'BackgroundColor',[0.831 0.816 0.784])
    set(handles_civ0(ibutton),'Value',0)
end
if exist('handle1','var')%handles of selected button
	set(handle1,'BackgroundColor',[1 1 0])  
end

%-----------------------------------------------------------------------
% --- Executes on button press in MENUVOLUME.
function VOLUME_Callback(hObject, eventdata, handles)
%-----------------------------------------------------------------------
%errordlg('command VOL not implemented yet')
if ishandle(handles.UVMAT_title)
    delete(handles.UVMAT_title)
end
UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 
if isequal(get(handles.VOLUME,'Value'),1)
    set(handles.CheckZoom,'Value',0)
    set(handles.CheckZoom,'BackgroundColor',[0.7 0.7 0.7])
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)
    set(handles.edit_object,'Value',0)
    set(handles.edit_object,'BackgroundColor',[0.7 0.7 0.7])
%     set(handles.cal,'Value',0)
%     set(handles.cal,'BackgroundColor',[0 1 0])
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)
    %initiate set_object GUI
    data.Name='VOLUME';
    if isfield(UvData,'CoordType')
        data.CoordType=UvData.CoordType;
    end
    if isfield(UvData.Field,'CoordMesh')&~isempty(UvData.Field.CoordMesh)
        data.RangeX=[UvData.Field.XMin UvData.Field.XMax];
        data.RangeY=[UvData.Field.YMin UvData.Field.YMax];
        data.DX=UvData.Field.CoordMesh;
        data.DY=UvData.Field.CoordMesh;
    elseif isfield(UvData.Field,'AX')&isfield(UvData.Field,'AY')& isfield(UvData.Field,'A')%only image
        np=size(UvData.Field.A);
        meshx=(UvData.Field.AX(end)-UvData.Field.AX(1))/np(2);
        meshy=abs(UvData.Field.AY(end)-UvData.Field.AY(1))/np(1);
        data.RangeY=max(meshx,meshy);
        data.RangeX=max(meshx,meshy);
        data.DX=max(meshx,meshy);
    end 
    data.ParentButton=handles.VOLUME;
    PlotHandles=get_plot_handles(handles);%get the handles of the interface elements setting the plotting parameters
    [hset_object,UvData.sethandles]=set_object(data,PlotHandles);% call the set_object interface with action on haxes,
                                                      % associate the set_object interface handle to the plotting axes
    set(hset_object,'Position',get(handles.uvmat,'Position')+UvData.OpenParam.PosSetObject)
    UvData.MouseAction='create_object';
else
    set(handles.VOLUME,'BackgroundColor',[0 1 0])
end
set(handles.uvmat,'UserData',UvData)

%-------------------------------------------------------
function edit_vect_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
% 
if isequal(get(handles.edit_vect,'Value'),1)
    VelTypeMenu=get(handles.VelType,'String');
    VelType=VelTypeMenu{get(handles.VelType,'Value')};
    if ~strcmp(VelType,'civ2') && ~strcmp(VelType,'civ1')
        msgbox_uvmat('ERROR','manual correction only possible for CIV1 or CIV2 velocity fields')
    end 
    set(handles.record,'Visible','on')
    set(handles.edit_vect,'BackgroundColor',[1 1 0])
    set(handles.edit_object,'Value',0)
    set(handles.CheckZoom,'Value',0)
    set(handles.CheckZoom,'BackgroundColor',[0.7 0.7 0.7])
    set(handles.edit_object,'BackgroundColor',[0.7 0.7 0.7])
    set(gcf,'Pointer','arrow')
else
    set(handles.record,'Visible','off')
    set(handles.edit_vect,'BackgroundColor',[0.7 0.7 0.7])
end

%----------------------------------------------
function save_mask_Callback(hObject, eventdata, handles)
%-----------------------------------------------------------------------
UvData=get(handles.uvmat,'UserData');

flag=1;
npx=size(UvData.Field.A,2);
npy=size(UvData.Field.A,1);
xi=0.5:npx-0.5;
yi=0.5:npy-0.5;
[Xi,Yi]=meshgrid(xi,yi);
if isfield(UvData,'Object')
    for iobj=1:length(UvData.Object)
        ObjectData=UvData.Object{iobj};
        if isfield(ObjectData,'ProjMode') &&(isequal(ObjectData.ProjMode,'mask_inside')||isequal(ObjectData.ProjMode,'mask_outside'));
            flagobj=1;
            testphys=0; %coordinates in pixels by default
            if isfield(ObjectData,'CoordType') && isequal(ObjectData.CoordType,'phys')
                if isfield(UvData,'XmlData')&& isfield(UvData.XmlData{1},'GeometryCalib')
                    Calib=UvData.XmlData{1}.GeometryCalib;
                    testphys=1;
                end
            end
            if isfield(ObjectData,'Coord')& isfield(ObjectData,'Style') 
                if isequal(ObjectData.Type,'polygon') 
                    X=ObjectData.Coord(:,1);
                    Y=ObjectData.Coord(:,2);
                    if testphys
                        [X,Y]=px_XYZ(Calib,X,Y,0);% to generalise with 3D cases
                    end
                    flagobj=~inpolygon(Xi,Yi,X',Y');%=0 inside the polygon, 1 outside                  
                elseif isequal(ObjectData.Type,'ellipse')
                    if testphys
                        %[X,Y]=px_XYZ(Calib,X,Y,0);% TODO:create a polygon boundary and transform to phys
                    end
                    RangeX=max(ObjectData.RangeX);
                    RangeY=max(ObjectData.RangeY);
                    X2Max=RangeX*RangeX;
                    Y2Max=RangeY*RangeY;
                    distX=(Xi-ObjectData.Coord(1,1));
                    distY=(Yi-ObjectData.Coord(1,2));
                    flagobj=(distX.*distX/X2Max+distY.*distY/Y2Max)>1;
                elseif isequal(ObjectData.Type,'rectangle')
                    if testphys
                        %[X,Y]=px_XYZ(Calib,X,Y,0);% TODO:create a polygon boundary and transform to phys
                    end
                    distX=abs(Xi-ObjectData.Coord(1,1));
                    distY=abs(Yi-ObjectData.Coord(1,2));
                    flagobj=distX>max(ObjectData.RangeX) | distY>max(ObjectData.RangeY);
                end
                if isequal(ObjectData.ProjMode,'mask_outside')
                    flagobj=~flagobj;
                end
                flag=flag & flagobj;
            end
        end
    end
end
% flag=~flag;
%mask name
RootPath=get(handles.RootPath,'String');
RootFile=get(handles.RootFile,'String');
RootFile=regexprep(RootFile,'\<[\\/]|[\\/]\>','');%suppress possible / or \ separator at the beginning or the end of the string
filebase=fullfile(RootPath,RootFile);
list=get(handles.masklevel,'String');
masknumber=num2str(length(list));
maskindex=get(handles.masklevel,'Value');
mask_name=fullfile_uvmat(RootPath,SubDir,[RootFile '_' masknumber 'mask'],'.png','_1',maskindex);
%mask_name=name_generator([filebase '_' masknumber 'mask'],maskindex,1,'.png','_i');
imflag=uint8(255*(0.392+0.608*flag));% =100 for flag=0 (vectors not computed when 20<imflag<200)
imflag=flipdim(imflag,1);
% imflag=uint8(255*flag);% =0 for flag=0 (vectors=0 when 20<imflag<200)
msgbox_uvmat('CONFIRMATION',[mask_name ' saved'])
imwrite(imflag,mask_name,'BitDepth',8); 

%display the mask
figure;
vec=linspace(0,1,256);%define a linear greyscale colormap
map=[vec' vec' vec'];
colormap(map)

image(imflag);

%-------------------------------------------------------------------
%-------------------------------------------------------------------
%  - FUNCTIONS FOR SETTING PLOTTING PARAMETERS

%------------------------------------------------------------------
%-------------------------------------------------------------
% --- Executes on selection change in TransformName.

function TransformName_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------
UvData=get(handles.uvmat,'UserData');
menu=get(handles.TransformName,'String');refresh
ichoice=get(handles.TransformName,'Value');%item number in the menu
transform_name=menu{ichoice};% choice of the transform fct
list_path=get(handles.TransformName,'UserData');

%% add a new item to the menu if the option 'more...' has been selected
prev_path=fullfile(get(handles.TransformPath,'String'));
if ~exist(prev_path,'dir')
    prev_path=fullfile(fileparts(which('uvmat')),'transform_field');
end
if strcmp(transform_name,'more...');
    [FileName, PathName] = uigetfile( ...
        {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick the transform function', prev_path);
    if ~ischar(FileName),return,end %abandon if the browser is cancelled
    path_transform_fct =fullfile(PathName,FileName);
    if isempty(regexp(FileName,'\.m$'))% detect file extension .m
        msgbox_uvmat('ERROR','a Matlab function .m must be introduced');
        return
    else
        transform_name=regexprep(FileName,'\.m','');
    end
    ichoice=find(strcmp(transform_name,menu),1);%look for the selected fct in the existing menu
    if isempty(ichoice)% if the item is not found, add it to the menu (before 'more...' and select it)
        menu=[menu(1:end-1);{transform_name};{'more...'}];
        ichoice=numel(menu)-1;    
    end
    list_path{ichoice}=PathName;%update the list fo fct paths
    set(handles.TransformName,'String',menu)
    set(handles.TransformName,'Value',ichoice)
    
    % save the new menu in the personal file 'uvmat_perso.mat'
    dir_perso=prefdir;%personal Matalb directory
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        nb_builtin=UvData.OpenParam.NbBuiltin;% number of 'builtin' (basic) transform fcts in uvmat
        if nb_builtin<numel(list_path)
        for ilist=nb_builtin+1:numel(list_path)
            transform_fct{ilist-nb_builtin}=[fullfile(list_path{ilist},menu{ilist}) '.m'];
        end
        save (profil_perso,'transform_fct','-append'); %store the root name for future opening of uvmat
        end
    end
end

%% create the function handle of the selected fct

if isempty(list_path{ichoice})% case of no selected fct
    transform_handle=[];
else
    if ~exist(list_path{ichoice},'dir')
        msgbox_uvmat('ERROR','invalid fct path: select the transform fct again with the option more...')
        return
    end
    current_dir=pwd;%current working dir
    cd(list_path{ichoice})
    transform_handle=str2func(transform_name);
    cd(current_dir)
end
set(handles.TransformPath,'String',list_path{ichoice})
set(handles.TransformPath,'UserData',transform_handle)
set(handles.TransformName,'UserData',list_path)

%% update the ToolTip string of the menu TransformName with the first line of the selected fct file
if isempty(list_path{ichoice})% case of no selected fct
    set(handles.TransformName,'ToolTipString','transform_fct:choose a transform function')
else
    try
        [fid,errormsg] =fopen([fullfile(list_path{ichoice},transform_name) '.m']);
        InputText=textscan(fid,'%s',1,'delimiter','\n');
        fclose(fid)
        set(handles.TransformName,'ToolTipString',['transform_fct: ' InputText{1}{1}])% put the first line of the selected function as tooltip help
    end
end

%% adapt the GUI to the input/output conditions of the selected transform fct
DataOut=[];
CoordUnit='';
CoordUnitPrev='';
if isfield(UvData,'Field')&&isfield(UvData.Field,'CoordUnit')
    CoordUnitPrev=UvData.Field.CoordUnit;
end
if ~isempty(list_path{ichoice}) 
    if nargin(transform_handle)>1 && isfield(UvData,'XmlData')&&~isempty(UvData.XmlData)
        XmlData=UvData.XmlData{1};
        DataOut=feval(transform_handle,'*',XmlData);
        if isfield(DataOut,'CoordUnit')
            CoordUnit=DataOut.CoordUnit;
        end
        if isfield(DataOut,'InputFieldType')
            UvData.InputFieldType=DataOut.InputFieldType;
        end
    else
        DataOut=feval(transform_handle,'*');
    end
end


%% delete drawn objects if the output CooordUnit is different from the previous one
if ~strcmp(CoordUnit,CoordUnitPrev)
    set(handles.CheckFixLimits,'Value',0)
set(handles.CheckFixLimits,'BackgroundColor',[0.7 0.7 0.7])
    hother=findobj('Tag','proj_object');%find all the proj objects
    for iobj=1:length(hother)
        delete_object(hother(iobj))
    end
    hother=findobj('Tag','DeformPoint');%find all the proj objects
    for iobj=1:length(hother)
        delete_object(hother(iobj))
    end
    hh=findobj('Tag','calib_points');
    if ~isempty(hh)
        delete(hh)
    end
    hhh=findobj('Tag','calib_marker');
    if ~isempty(hhh)
        delete(hhh)
    end
%     if isfield(UvData,'Object')
%         UvData.Object=UvData.Object(1);
%     end
    set(handles.ListObject,'Value',1)
    set(handles.ListObject,'String',{''})
    set(handles.ListObject_1,'Value',1)
    set(handles.ListObject_1,'String',{''})
    set(handles.ViewObject,'value',0)
    ViewObject_Callback(hObject, eventdata, handles)
    set(handles.ViewField,'value',0)
    ViewField_Callback(hObject, eventdata, handles)
    set(handles.edit_object,'Value',0)
    edit_object_Callback(hObject, eventdata, handles)
    UvData.Object={[]};
end
set(handles.uvmat,'UserData',UvData)

%% refresh the current plot
if isempty(list_path{ichoice}) || nargin(transform_handle)<3
    set(handles.SubField,'Value',0)
    SubField_Callback(hObject, eventdata, handles)
else
    run0_Callback(hObject, eventdata, handles)
end

%------------------------------------------------
%CALLBACKS FOR PLOTTING PARAMETERS
%-------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot coordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
function num_MinX_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%------------------------------------------------------------------------
function num_MaxX_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%------------------------------------------------------------------------
function num_MinY_Callback(hObject, eventdata, handles)
%------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%------------------------------------------------------------------------
function num_MaxY_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scalar or image representation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
function num_MinA_Callback(hObject, eventdata, handles)
%------------------------------------------
set(handles.CheckFixScalar,'Value',1) %suppress auto mode
set(handles.CheckFixScalar,'BackgroundColor',[1 1 0])
MinA=str2double(get(handles.num_MinA,'String'));
MaxA=str2double(get(handles.num_MaxA,'String'));
if MinA>MaxA% switch minA and maxA in case of error
    MinA_old=MinA;
    MinA=MaxA;
    MaxA=MinA_old;
    set(handles.num_MinA,'String',num2str(MinA,5));
    set(handles.num_MaxA,'String',num2str(MaxA,5));
end
update_plot(handles);

%------------------------------------------------------------------------
function num_MaxA_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixScalar,'Value',1) %suppress auto mode
set(handles.CheckFixScalar,'BackgroundColor',[1 1 0])
MinA=str2double(get(handles.num_MinA,'String'));
MaxA=str2double(get(handles.num_MaxA,'String'));
if MinA>MaxA% switch minA and maxA in case of error
        MinA_old=MinA;
    MinA=MaxA;
    MaxA=MinA_old;
    set(handles.num_MinA,'String',num2str(MinA,5));
    set(handles.num_MaxA,'String',num2str(MaxA,5));
end
update_plot(handles);

%------------------------------------------------------------------------
function CheckFixScalar_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
test=get(handles.CheckFixScalar,'Value');
if test
    set(handles.CheckFixScalar,'BackgroundColor',[1 1 0])
else
    set(handles.CheckFixScalar,'BackgroundColor',[0.7 0.7 0.7])
    update_plot(handles);
end

%-------------------------------------------------------------------
function CheckBW_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles);

%-------------------------------------------------------------------
function num_Opacity_Callback(hObject, eventdata, handles)
update_plot(handles);
%-------------------------------------------------------------------

%-------------------------------------------------------------------
function ListContour_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
val=get(handles.ListContour,'Value');
if val==2
    set(handles.interval_txt,'Visible','on')
    set(handles.num_IncrA,'Visible','on')
else
    set(handles.interval_txt,'Visible','off')
    set(handles.num_IncrA,'Visible','off')
end
update_plot(handles);

%-------------------------------------------------------------------
function num_IncrA_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Vector representation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-------------------------------------------------------------------
function CheckHideWarning_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles);

%-------------------------------------------------------------------
function CheckHideFalse_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles);

%-------------------------------------------------------------------
function num_VecScale_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
set(handles.CheckFixVectors,'Value',1);
set(handles.CheckFixVectors,'BackgroundColor',[1 1 0])
update_plot(handles);

%-------------------------------------------------------------------
function CheckFixVectors_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
test=get(handles.CheckFixVectors,'Value');
if test
    set(handles.CheckFixVectors,'BackgroundColor',[1 1 0])
else
    update_plot(handles);
    %set(handles.num_VecScale,'String',num2str(ScalOut.num_VecScale,3))
    set(handles.CheckFixVectors,'BackgroundColor',[0.7 0.7 0.7])
end

%------------------------------------------------------------------------
% --- Executes on selection change in CheckDecimate4 (nb_vec/4).
function CheckDecimate4_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.CheckDecimate4,'Value'),1)
    set(handles.CheckDecimate16,'Value',0)
end
update_plot(handles);

%------------------------------------------------------------------------
% --- Executes on selection change in CheckDecimate16 (nb_vec/16).
function CheckDecimate16_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.CheckDecimate16,'Value'),1)
    set(handles.CheckDecimate4,'Value',0)
end
update_plot(handles);

%------------------------------------------------------------------------
% --- Executes on selection change in ColorCode menu
function ColorCode_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% edit the choice for color code
update_color_code_boxes(handles);
update_plot(handles);

%------------------------------------------------------------------------
function update_color_code_boxes(handles)
%------------------------------------------------------------------------
list_code=get(handles.ColorCode,'String');% list menu fields
colcode= list_code{get(handles.ColorCode,'Value')}; % selected field
enable_slider='off';%default
enable_bounds='off';%default
enable_scalar='off';%default
switch colcode
    case {'rgb','bgr'}
        enable_slider='on';
        enable_bounds='on';
        enable_scalar='on';
    case '64 colors'
        enable_bounds='on';
        enable_scalar='on';
end
set(handles.Slider1,'Visible',enable_slider)
set(handles.Slider2,'Visible', enable_slider)
set(handles.num_ColCode1,'Visible',enable_slider)
set(handles.num_ColCode2,'Visible',enable_slider)
set(handles.TitleColCode1,'Visible',enable_slider)
set(handles.TitleColCode2,'Visible',enable_slider)
set(handles.CheckFixVecColor,'Visible',enable_bounds)
set(handles.num_MinVec,'Visible',enable_bounds)
set(handles.num_MaxVec,'Visible',enable_bounds)
set(handles.ColorScalar,'Visible',enable_scalar)
set_vec_col_bar(handles)

%------------------------------------------------------------------
% --- Executes on selection change in ColorScalar: choice of the color code.
function ColorScalar_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
% edit the choice for color code
list_scalar=get(handles.ColorScalar,'String');% list menu fields
col_scalar= list_scalar{get(handles.ColorScalar,'Value')}; % selected field
if isequal(col_scalar,'ima_cor')
    set(handles.CheckFixVecColor,'Value',1)%fixed scale by default
    ColorCode='rgb';
    set(handles.num_MinVec,'String','0')
    set(handles.num_MaxVec,'String','1')
    set(handles.num_ColCode1,'String','0.333')
    set(handles.num_ColCode2,'String','0.666')
else
    set(handles.CheckFixVecColor,'Value',0)%auto scale between min,max by default
    ColorCode='64 colors';
end
ColorCodeList=get(handles.ColorCode,'String');
ichoice=find(strcmp(ColorCode,ColorCodeList),1);
set(handles.ColorCode,'Value',ichoice)% set color code in the menu

update_color_code_boxes(handles);
%replot the current graph
run0_Callback(hObject, eventdata, handles)

%----------------------------------------------------------------
% -- Executes on slider movement to set the color code
%
function Slider1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
slider1=get(handles.Slider1,'Value');
min_val=str2num(get(handles.num_MinVec,'String'));
max_val=str2num(get(handles.num_MaxVec,'String'));
col=min_val+(max_val-min_val)*slider1;
set(handles.num_ColCode1,'String',num2str(col))
if(get(handles.Slider2,'Value') < col)%move also the second slider at the same value if needed
    set(handles.Slider2,'Value',col)
    set(handles.num_ColCode2,'String',num2str(col))
end
set_vec_col_bar(handles)
update_plot(handles);

%----------------------------------------------------------------
% Executes on slider movement to set the color code
%----------------------------------------------------------------
function Slider2_Callback(hObject, eventdata, handles)
slider2=get(handles.Slider2,'Value');
min_val=str2num(get(handles.num_MinVec,'String'));
max_val=str2num(get(handles.num_MaxVec,'String'));
col=min_val+(max_val-min_val)*slider2;
set(handles.num_ColCode2,'String',num2str(col))
if(get(handles.Slider1,'Value') > col)%move also the first slider at the same value if needed
    set(handles.Slider1,'Value',col)
    set(handles.num_ColCode1,'String',num2str(col))
end
set_vec_col_bar(handles)
update_plot(handles);

%----------------------------------------------------------------
% --- Execute on return carriage on the edit box corresponding to slider 1
%----------------------------------------------------------------
function num_ColCode1_Callback(hObject, eventdata, handles) 
set_vec_col_bar(handles)
update_plot(handles);

%----------------------------------------------------------------
% --- Execute on return carriage on the edit box corresponding to slider 2
%----------------------------------------------------------------
function num_ColCode2_Callback(hObject, eventdata, handles)
set_vec_col_bar(handles)
update_plot(handles);
%------------------------------------------------------------------------
%-------------------------------------------------------
% --- Executes on button press in CheckFixVecColor.
%-------------------------------------------------------
function VecColBar_Callback(hObject, eventdata, handles)
set_vec_col_bar(handles)

%------------------------------------------------------------------------
% --- Executes on button press in CheckFixVecColor.
function CheckFixVecColor_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if ~get(handles.CheckFixVecColor,'Value')
    update_plot(handles);
end

%------------------------------------------------------------------------
% --- Executes on selection change in num_MaxVec.
function num_MinVec_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
max_vec_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on selection change in num_MaxVec.
function num_MaxVec_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixVecColor,'Value',1)
CheckFixVecColor_Callback(hObject, eventdata, handles)
min_val=str2num(get(handles.num_MinVec,'String'));
max_val=str2num(get(handles.num_MaxVec,'String'));
slider1=get(handles.Slider1,'Value');
slider2=get(handles.Slider2,'Value');
colcode1=min_val+(max_val-min_val)*slider1;
colcode2=min_val+(max_val-min_val)*slider2;
set(handles.num_ColCode1,'String',num2str(colcode1))
set(handles.num_ColCode2,'String',num2str(colcode2))
update_plot(handles);

%------------------------------------------------------------------------
% --- update the display of color code for vectors (on vecColBar)
function set_vec_col_bar(handles)
%------------------------------------------------------------------------
%get the image of the color display button 'VecColBar' in pixels
set(handles.VecColBar,'Unit','pixel');
pos_vert=get(handles.VecColBar,'Position');
set(handles.VecColBar,'Unit','Normalized');
width=ceil(pos_vert(3));
height=ceil(pos_vert(4));

%get slider indications
list=get(handles.ColorCode,'String');
ichoice=get(handles.ColorCode,'Value');
colcode.ColorCode=list{ichoice};
colcode.MinVec=str2num(get(handles.num_MinVec,'String'));
colcode.MaxVec=str2num(get(handles.num_MaxVec,'String'));
test3color=strcmp(colcode.ColorCode,'rgb') || strcmp(colcode.ColorCode,'bgr');
if test3color
    colcode.ColCode1=str2num(get(handles.num_ColCode1,'String'));
    colcode.ColCode2=str2num(get(handles.num_ColCode2,'String'));
end
vec_C=colcode.MinVec+(colcode.MaxVec-colcode.MinVec)*(0.5:width-0.5)/width;%sample of vec_C values from min to max
[colorlist,col_vec]=set_col_vec(colcode,vec_C);
oneheight=ones(1,height);
A1=colorlist(col_vec,1)*oneheight;
A2=colorlist(col_vec,2)*oneheight;
A3=colorlist(col_vec,3)*oneheight;
A(:,:,1)=A1';
A(:,:,2)=A2';
A(:,:,3)=A3';
set(handles.VecColBar,'Cdata',A)

%-------------------------------------------------------------------
function update_plot(handles)
%-------------------------------------------------------------------
UvData=get(handles.uvmat,'UserData');
AxeData=UvData.PlotAxes;% retrieve the current plotted data
PlotParam=read_GUI(handles.uvmat);
[tild,PlotParamOut]= plot_field(AxeData,handles.PlotAxes,PlotParam);
errormsg=fill_GUI(PlotParamOut,handles.uvmat);
%write_plot_param(handles,PlotParamOut); %update the auto plot parameters

%------------------------------------------------------------------------
%------------------------------------------------------------------------
%   SELECTION AND EDITION OF PROJECTION OBJECTS
%------------------------------------------------------------------------
%------------------------------------------------------------------------

% --- Executes on selection change in ListObject_1.
function ListObject_1_Callback(hObject, eventdata, handles)
list_str=get(handles.ListObject,'String');
UvData=get(handles.uvmat,'UserData');
ObjectData=UvData.Object{get(handles.ListObject_1,'Value')};

%% update the projection plot on uvmat
ProjData= proj_field(UvData.Field,ObjectData);%project the current input field on object ObjectData
plot_field(ProjData,handles.PlotAxes,read_GUI(handles.uvmat));% plot the projected field;
%replot all the objects within the new projected field
for IndexObj=1:numel(list_str)
        hobject=UvData.Object{IndexObj}.DisplayHandle.uvmat;
        if isempty(hobject) || ~ishandle(hobject)
            hobject=handles.PlotAxes;
        end
        if isequal(IndexObj,get(handles.ListObject,'Value'))
            objectcolor='m'; %paint in magenta the currently selected object in ListObject
        else
            objectcolor='b';
        end
        UvData.Object{IndexObj}.DisplayHandle.uvmat=plot_object(UvData.Object{IndexObj},ObjectData,hobject,objectcolor);%draw the object in uvmat      
end
set(handles.uvmat,'UserData',UvData)

%% display the object parameters if the GUI set_object is already opened
if ~get(handles.ViewObject,'Value')
    ZBounds=0; % default
    if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
        ZBounds(1)=UvData.Field.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.Field.ZMax;%maximum for the Z slider
    end
    ObjectData.Name=list_str{get(handles.ListObject_1,'Value')};
    set_object(ObjectData,[],ZBounds);
    set(handles.ViewObject,'Value',1)% show that the selected object in ListObject_1 is currently visualised
end

%  desactivate the edit object mode
set(handles.edit_object,'Value',0) 
set(handles.edit_object,'BackgroundColor',[0.7,0.7,0.7]) 

%------------------------------------------------------------------------
% --- Executes on selection change in ListObject.
function ListObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
list_str=get(handles.ListObject,'String');
IndexObj=get(handles.ListObject,'Value');%present object selection

%% The object  is displayed in set_object if this GUI is already opened
UvData=get(handles.uvmat,'UserData');
ObjectData=UvData.Object{IndexObj};
hset_object=findobj(allchild(0),'tag','set_object');
if ~isempty(hset_object)
    ZBounds=0; % default
    if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
        ZBounds(1)=UvData.Field.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.Field.ZMax;%maximum for the Z slider
    end
    ObjectData.Name=list_str{IndexObj};
    set_object(ObjectData,[],ZBounds);
    set(handles.ViewField,'Value',1)% show that the selected object in ListObject is currently visualised
end

%%  desactivate the edit object mode
set(handles.edit_object,'Value',0) 
set(handles.edit_object,'BackgroundColor',[0.7,0.7,0.7]) 

%% update the  plot on view_field if view_field is already openened
hview_field=findobj(allchild(0),'tag','view_field');
if isempty(hview_field)
    hhview_field.PlotAxes=[];
else
    Data=get(hview_field,'UserData');
    hhview_field=guidata(hview_field);
    ProjData= proj_field(UvData.Field,ObjectData);%project the current interface field on ObjectData
    [PlotType,PlotParam]=plot_field(ProjData,hhview_field.PlotAxes,read_GUI(hview_field));%read plotting parameters on the uvmat interface
    
    %write_plot_param(hhview_field,PlotParam); %update the display of plotting parameters for the current object
    haxes=findobj(hview_field,'tag','axes3');
    pos=get(hview_field,'Position');  
    if strcmp(get(haxes,'Visible'),'off')%sempty(PlotParam.Coordinates)% case of no plot display (pure text table)
        h_TableDisplay=findobj(hview_field,'tag','TableDisplay');
        pos_table=get(h_TableDisplay,'Position');
        set(hview_field,'Position',[pos(1)+pos(3)-pos_table(3) pos(2)+pos(4)-pos_table(4) pos_table(3) pos_table(4)])
        drawnow% needed to change position before the next command
        set(hview_field,'UserData',Data);% restore the previously stored GUI position after GUI resizing
    else
        set(hview_field,'Position',Data.GUISize)% return to the previously stored GUI position and size
    end
end

%% update the color of the graphic object representation: the selected object in magenta, others in blue
update_object_color(handles.PlotAxes,hhview_field.PlotAxes,UvData.Object{IndexObj}.DisplayHandle.uvmat)

%------------------------------------------------------------------------
%--- update the color representation of objects (indicating the selected ones)
function update_object_color(axes_uvmat,axes_view_field,DisplayHandle)
%------------------------------------------------------------------------
if isempty(axes_view_field)% case with no view_field plot
hother=[findobj(axes_uvmat,'Tag','proj_object');findobj(axes_uvmat,'Tag','DeformPoint')];%find all the proj object and deform point representations
else
hother=[findobj(axes_uvmat,'Tag','proj_object') ;findobj(axes_view_field,'Tag','proj_object');... %find all the proj object representations
findobj(axes_uvmat,'Tag','DeformPoint'); findobj(axes_view_field,'Tag','DeformPoint')];%find all the deform point representations
end
for iobj=1:length(hother)
    if isequal(get(hother(iobj),'Type'),'rectangle')||isequal(get(hother(iobj),'Type'),'patch')
        set(hother(iobj),'EdgeColor','b')
        if isequal(get(hother(iobj),'FaceColor'),'m')
            set(hother(iobj),'FaceColor','b')
        end
    elseif isequal(get(hother(iobj),'Type'),'image')
        Acolor=get(hother(iobj),'CData');
        Acolor(:,:,1)=zeros(size(Acolor,1),size(Acolor,2));
        set(hother(iobj),'CData',Acolor);
    else
        set(hother(iobj),'Color','b')
    end
    set(hother(iobj),'Selected','off')
end
if ishandle(DisplayHandle)
    linetype=get(DisplayHandle,'Type');
    if isequal(linetype,'line')
        set(DisplayHandle,'Color','m'); %set the selected object to magenta color
    elseif isequal(linetype,'rectangle')
        set(DisplayHandle,'EdgeColor','m'); %set the selected object to magenta color
    elseif isequal(linetype,'patch')
        set(DisplayHandle,'FaceColor','m'); %set the selected object to magenta color
    end
    SubObjectData=get(DisplayHandle,'UserData');
    if isfield(SubObjectData,'SubObject') & ishandle(SubObjectData.SubObject)
        for iobj=1:length(SubObjectData.SubObject)
            hsub=SubObjectData.SubObject(iobj);
            if isequal(get(hsub,'Type'),'rectangle')
                set(hsub,'EdgeColor','m'); %set the selected object to magenta color
            elseif isequal(get(hsub,'Type'),'image')
                Acolor=get(hsub,'CData');
                Acolor(:,:,1)=Acolor(:,:,3);
                set(hsub,'CData',Acolor);
            else
                set(hsub,'Color','m')
            end
        end
    end
    if isfield(SubObjectData,'DeformPoint') & ishandle(SubObjectData.DeformPoint)
        set(SubObjectData.DeformPoint,'Color','m')
    end
end

%-------------------------------------------------------------------
% --- Executes on selection change in edit_object.
function edit_object_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
hset_object=findobj(allchild(0),'Tag','set_object');
if get(handles.edit_object,'Value')
    set(handles.edit_object,'BackgroundColor',[1,1,0])  
    %suppress the other options 
    set(handles.CheckZoom,'Value',0)
    CheckZoom_Callback(hObject, eventdata, handles)
    hgeometry_calib=findobj(allchild(0),'tag','geometry_calib');
    if ishandle(hgeometry_calib)
        hhgeometry_calib=guidata(hgeometry_calib);
        set(hhgeometry_calib.edit_append,'Value',0)% desactivate mouse action in geometry_calib
        set(hhgeometry_calib.edit_append,'BackgroundColor',[0.7 0.7 0.7])
    end
    set(handles.ViewObject,'value',1)
    ViewObject_Callback(hObject, eventdata, handles)
else % desctivate object edit mode
    set(handles.edit_object,'BackgroundColor',[0.7,0.7,0.7])  
    if ~isempty(hset_object)% open the 
        hhset_object=guidata(hset_object);
        set(hhset_object.PLOT,'enable','off'); 
        set(get(hset_object,'children'),'enable','inactive')
    end
end


%------------------------------------------------------------------------
% --- Executes on button press in ViewObject.
function ViewObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
check_view=get(handles.ViewObject,'Value');

if check_view %activate set_object    
    IndexObj=get(handles.ListObject,'Value');
    list_object=get(handles.ListObject,'String');
    UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface
    UvData.Object{IndexObj}.Name=list_object{IndexObj};
    if numel(UvData.Object)<IndexObj;% error in UvData
        msgbox_uvmat('ERROR','invalid object list')
        return
    end
    ZBounds=0; % default
    if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
        ZBounds(1)=UvData.Field.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.Field.ZMax;%maximum for the Z slider
    end
%     set(handles.ListObject_1,'Value',IndexObj);%restore ListObject selection after set_object deletion
    data=UvData.Object{IndexObj};
    if ~isfield(data,'Type')% default plane
        data.Type='plane';
    end
%     if isfield(UvData,'Field')
%         Field=UvData.Field;
%         if isfield(UvData.Field,'Mesh')&&~isempty(UvData.Field.Mesh)
%             data.RangeX=[UvData.Field.XMin UvData.Field.XMax];
%             if strcmp(data.Type,'line')||strcmp(data.Type,'polyline')
%                 data.RangeY=UvData.Field.Mesh;
%             else
%                 data.RangeY=[UvData.Field.YMin UvData.Field.YMax];
%             end
%             data.DX=UvData.Field.Mesh;
%             data.DY=UvData.Field.Mesh;
%         end
%         if isfield(Field,'NbDim')&& isequal(Field.NbDim,3)
%             data.Coord=[0 0 0]; %default
%         end
%         if isfield(Field,'CoordUnit')
%             data.CoordUnit=Field.CoordUnit;
%         end
%     end
    hset_object=set_object(data,[],ZBounds);
    hhset_object=guidata(hset_object);
    if get(handles.edit_object,'Value')% edit mode
        set(hhset_object.PLOT,'Enable','on')
        set(get(hset_object,'children'),'enable','on')
    else
        set(hhset_object.PLOT,'Enable','off')
        set(get(hset_object,'children'),'enable','inactive')% deactivate the GUI except SAVE
        set(hhset_object.SAVE,'Enable','on')
    end
else
    hset_object=findobj(allchild(0),'tag','set_object');
    if ~isempty(hset_object)
        delete(hset_object)% delete existing version of set_object
    end
end
  

%------------------------------------------------------------------------
% --- Executes on button press in ViewField.
function ViewField_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
check_view=get(handles.ViewField,'Value');

if check_view
    IndexObj=get(handles.ListObject,'Value');
    UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface
    if numel(UvData.Object)<IndexObj(end);% error in UvData
        msgbox_uvmat('ERROR','invalid object list')
        return
    end
    ZBounds=0; % default
    if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
        ZBounds(1)=UvData.Field.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.Field.ZMax;%maximum for the Z slider
    end
    set(handles.ListObject,'Value',IndexObj);%restore ListObject selection after set_object deletion
    if ~isfield(UvData.Object{IndexObj(1)},'Type')% default plane
        UvData.Object{IndexObj(1)}.Type='plane';
    end
    list_object=get(handles.ListObject,'String');
    UvData.Object{IndexObj(end)}.Name=list_object{IndexObj(end)};
    
    %% show the projection of the selected object on view_field
    ProjData= proj_field(UvData.Field,UvData.Object{IndexObj});%project the current field on ObjectData
    hview_field=findobj(allchild(0),'tag','view_field');
    if isempty(hview_field)
        hview_field=view_field;
    end
    hhview_field=guidata(hview_field);
    [PlotType,PlotParam]=plot_field(ProjData,hhview_field.PlotAxes,read_GUI(hview_field));%read plotting parameters on the GUI view_field);
    errormsg=fill_GUI(PlotParam,hview_field);
                    for list={'Scalar','Vectors'}
                    if ~isfield(PlotParamOut,list{1})
                        set(hhview_field.(list{1}),'Visible','off')
                    end
                end
    %write_plot_param(hhview_field,PlotParam); %update the display of plotting parameters for the current object
    haxes=findobj(hview_field,'tag','axes3');
    pos=get(hview_field,'Position');
    if strcmp(get(haxes,'Visible'),'off')%sempty(PlotParam.Coordinates)% case of no plot display (pure text table)
        h_TableDisplay=findobj(hview_field,'tag','TableDisplay');
        pos_table=get(h_TableDisplay,'Position');
        set(hview_field,'Position',[pos(1)+pos(3)-pos_table(3) pos(2)+pos(4)-pos_table(4) pos_table(3) pos_table(4)])
    else
        Data=get(hview_field,'UserData');
        set(hview_field,'Position',Data.GUISize)% restore the size of view_field for plots
    end
else
    hview_field=findobj(allchild(0),'tag','view_field');
    if ~isempty(hview_field)
        delete(hview_field)% delete existing version of set_object
    end
end


%------------------------------------------------------------------------
% --- Executes on button press in delete_object.
function delete_object_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
IndexObj=get(handles.ListObject,'Value');%projection object selected for view_field
IndexObj_1=get(handles.ListObject_1,'Value');%projection object selected for uvmat plot
if IndexObj>1 && ~isequal(IndexObj,IndexObj_1) % do not delete the object used for the uvmat plot
    delete_object(IndexObj)
end

%------------------------------------------------------------------------
%------------------------------------------------------------------------
%  II - TOOLS FROM THE UPPER MENU BAR
%------------------------------------------------------------------------
%------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export  Menu Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in Menu/Export/field in workspace.
function MenuExportField_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
global Data_uvmat
Data_uvmat=get(handles.uvmat,'UserData');
evalin('base','global Data_uvmat')%make CurData global in the workspace
display('current field :')
evalin('base','Data_uvmat') %display CurData in the workspace
commandwindow; %brings the Matlab command window to the front

%------------------------------------------------------------------------
% --- Executes on button press in Menu/Export/extract figure.
function MenuExportFigure_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% huvmat=get(handles.MenuExport,'parent');
hfig=figure;
copyobj(handles.PlotAxes,hfig);
map=colormap(handles.PlotAxes);
colormap(map);%transmit the current colormap to the zoom fig
colorbar

% --------------------------------------------------------------------
function MenuExportAxis_Callback(hObject, eventdata, handles)
ListFig=findobj(allchild(0),'Type','figure');
nb_option=0;
menu={};
for ilist=1:numel(ListFig)
    FigName=get(ListFig(ilist),'name');
    if isempty(FigName)
        FigName=['figure ' num2str(ListFig(ilist))];
    end
    if ~strcmp(FigName,'uvmat')
        ListAxes=findobj(ListFig(ilist),'Type','axes');
        ListTags=get(ListAxes,'Tag');
        if ~isempty(ListTags) && ~isempty(find(~strcmp('Colorbar',ListTags), 1))
            ListAxes=ListAxes(~strcmp('Colorbar',ListTags));
            if numel(ListAxes)==1
                nb_option=nb_option+1;
                menu{nb_option}=FigName ;
                AxesHandle(nb_option)=ListAxes;
            else
                nb_axis=0;
                for iaxes=1:numel(ListAxes)
                    nb_axis=nb_axis+1;
                    nb_option=nb_option+1;
                    menu{nb_option}=[FigName '_' num2str(nb_axis)];
                    AxesHandle(nb_option)=ListAxes(nb_axis);
                end
            end
        end
    end
end
if isempty(menu)
    answer=msgbox_uvmat('INPUT_Y-N','no existing plotting axes available, create new figure?');
    if strcmp(answer,'Yes')
        hfig=figure;
        copyobj(handles.PlotAxes,hfig);
    else
        return
    end
    map=colormap(handles.PlotAxes);
    colormap(map);%transmit the current colormap to the zoom fig
    colorbar
else
    answer=msgbox_uvmat('INPUT_MENU','select a figure/axis on which the current uvmat plot will be exported',menu);
    if isempty(answer)
        return
    else
        axes(AxesHandle(answer))
        hold on
        hchild=get(handles.PlotAxes,'children');
        copyobj(hchild,gca);
    end
end


%------------------------------------------------------------------------
% --------------------------------------------------------------------
function MenuExportMovie_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
set(handles.MenuExportMovie,'BusyAction','queue')% activate the button
huvmat=get(handles.run0,'parent');
UvData=get(huvmat,'UserData');
%[xx,xx,FileBase]=read_file_boxes(handles);
[RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
FileBase=fullfile(RootPath,RootFile);
 %read the current input file name
prompt = {'movie file name';'frames per second';'frame resolution (*[512x384] pixels)';'axis position relative to the frame';'total frame number (starting from the current uvmat display)'};
dlg_title = 'select properties of the output avi movie';
num_lines= 1;
def     = {[FileBase '_out.avi'];'10';'1';'[0.03 0.05 0.95 0.92]';'10'};
answer = inputdlg(prompt,dlg_title,num_lines,def,'on');
aviname=answer{1};
fps=str2double(answer{2});
% check for existing file with output name aviname
if exist(aviname,'file')
    backup=aviname;
    testexist=2;
    while testexist==2
        backup=[backup '~'];
        testexist=exist(backup,'file');      
    end
    [success,message]=copyfile(aviname,backup);%make backup of the existing file
    if isequal(success,1)
        delete(aviname)%delete existing file 
    else
        msgbox_uvmat('ERROR',message)
        return
    end 
end
%create avi open
aviobj=avifile(aviname,'Compression','None','fps',fps);

%display first view for tests
newfig=figure;
newaxes=copyobj(handles.PlotAxes,newfig);%new plotting axes in the new figure
set(newaxes,'Tag','movieaxes')
nbpix=[512 384]*str2double(answer{3});
set(gcf,'Position',[1 1 nbpix])% resolution XVGA 
set(newaxes,'Position',eval(answer{4}));
map=colormap(handles.PlotAxes);
colormap(map);%transmit the current colormap to the zoom fig
msgbox_uvmat('INPUT_Y-N',{['adjust figure ' num2str(newfig) ' with its matlab edit menu '] ;...
        ['then press OK to get the avi movie as a copy of figure ' num2str(newfig) ' display']});
UvData.plotaxes=newaxes;% the axis in the new figure becomes the current main plotting axes
set(huvmat,'UserData',UvData);
increment=str2num(get(handles.num_IndexIncrement,'String')); %get the field increment d
set(handles.STOP,'Visible','on')
set(handles.speed,'Visible','on')
set(handles.speed_txt,'Visible','on')
set(handles.Movie,'BusyAction','queue')

%imin=str2double(get(handles.i1,'String'));
imax=str2double(answer{5});
% if isfield(UvData,'Time')
htitle=get(newaxes,'Title');
xlim=get(newaxes,'XLim');
ylim=get(newaxes,'YLim');
set(htitle,'Position',[xlim(2)+0.07*(xlim(2)-xlim(1)) ylim(2)-0.05*(ylim(2)-ylim(1)) 0])
time_str=get(handles.abs_time,'String');
set(htitle,'String',['t=' time_str])
set(handles.speed,'Value',1)
for i=1:imax
    if get(handles.speed,'Value')~=0 && isequal(get(handles.MenuExportMovie,'BusyAction'),'queue') % enable STOP command
            runpm(hObject,eventdata,handles,increment)% run plus 
            drawnow
            time_str=get(handles.abs_time,'String');
            if ishandle(htitle)
             set(htitle,'String',['t=' time_str])
            end
            mov=getframe(newfig);
            aviobj=addframe(aviobj,mov);
    end
end
aviobj=close(aviobj);
UvData=rmfield(UvData,'plotaxes');
%UvData.Object{1}.plotaxes=handles.PlotAxes;
set(huvmat,'UserData',UvData);
msgbox_uvmat('CONFIRMATION',{['movie ' aviname ' created '];['with ' num2str(imax) ' frames']})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Projection Objects Menu Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -----------------------------------------------------------------------
function Menupoints_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='points';
data.ProjMode='projection';%default
data.ProjModeMenu={};% do not restrict ProjMode menus
create_object(data,handles)

% -----------------------------------------------------------------------
function Menuline_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='line';
data.ProjMode='projection';%default
data.ProjModeMenu={};% do not restrict ProjMode menus
create_object(data,handles)

%------------------------------------------------------------------------
function Menupolyline_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='polyline';
data.ProjMode='projection';%default
data.ProjModeMenu={};% do not restrict ProjMode menus
create_object(data,handles)

%------------------------------------------------------------------------
function Menupolygon_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='polygon';
data.ProjMode='inside';%default
data.ProjModeMenu={};% do not restrict ProjMode menus
create_object(data,handles)

%------------------------------------------------------------------------
function Menurectangle_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='rectangle';
data.ProjMode='inside';%default
data.ProjModeMenu={};% do not restrict ProjMode menus
create_object(data,handles)

%------------------------------------------------------------------------
function Menuellipse_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='ellipse';
data.ProjMode='inside';%default
data.ProjModeMenu={};% do not restrict ProjMode menus
create_object(data,handles)

%------------------------------------------------------------------------
function MenuMaskObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='polygon';
data.TypeMenu={'polygon'};
data.ProjMode='mask_inside';%default
data.ProjModeMenu={'mask_inside';'mask_outside'};
create_object(data,handles)

%------------------------------------------------------------------------
function Menuplane_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='plane';
data.ProjMode='projection';%default
data.ProjModeMenu={};% do not restrict ProjMode menus
create_object(data,handles)

%------------------------------------------------------------------------
function Menuvolume_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='volume';
data.ProjMode='interp_lin';%default
data.ProjModeMenu={};
% set(handles.create,'Visible','on')
% set(handles.create,'Value',1)
% VOLUME_Callback(hObject,eventdata,handles)data.ProjModeMenu={};
create_object(data,handles)

%------------------------------------------------------------------------
% --- generic function used for the creation of a projection object
function create_object(data,handles)
%------------------------------------------------------------------------
% desactivate geometric calibration if opened
hgeometry_calib=findobj(allchild(0),'tag','geometry_calib');
if ishandle(hgeometry_calib)
    hhgeometry_calib=guidata(hgeometry_calib);
    set(hhgeometry_calib.edit_append,'Value',0)% desactivate mouse action in geometry_calib
    set(hhgeometry_calib.edit_append,'BackgroundColor',[0.7 0.7 0.7])
end
set(handles.edit_object,'Value',0); %suppress the object edit mode
set(handles.edit_object,'BackgroundColor',[0.7,0.7,0.7])  
ListObject=get(handles.ListObject,'String');
if isempty(ListObject)
    ListObject={''};
end
if ~strcmp(ListObject{end},'')
    ListObject=[ListObject;{''}]; %append a blank to the list (if nort already done) to indicate the creation of a new object
    set(handles.ListObject,'String',ListObject)
end
IndexObj=length(ListObject);
set(handles.ListObject,'Value',IndexObj)
UvData=get(handles.uvmat,'UserData');
UvData.Object{IndexObj}=[]; %create a new empty object
UvData.Object{IndexObj}.DisplayHandle.uvmat=handles.PlotAxes; % axes for plot_object
UvData.Object{IndexObj}.DisplayHandle.view_field=[]; %no plot handle before plot_field operation
data.Name=data.Type;% default name=type
data.Coord=[0 0]; %default
if isfield(UvData,'Field')
    Field=UvData.Field;
    if isfield(UvData.Field,'CoordMesh')&&~isempty(UvData.Field.CoordMesh)
        data.RangeX=[UvData.Field.XMin UvData.Field.XMax];
        if strcmp(data.Type,'line')||strcmp(data.Type,'polyline')||strcmp(data.Type,'points')
            data.RangeY=UvData.Field.CoordMesh;
        else
            data.RangeY=[UvData.Field.YMin UvData.Field.YMax];
        end
        data.DX=UvData.Field.CoordMesh;
        data.DY=UvData.Field.CoordMesh;
    end
    if isfield(Field,'NbDim')&& isequal(Field.NbDim,3)
         data.Coord=[0 0 0]; %default
    end
    if isfield(Field,'CoordUnit')
        data.CoordUnit=Field.CoordUnit;
    end
end
if ishandle(handles.UVMAT_title)
    delete(handles.UVMAT_title)%delete the initial display of uvmat if no field has been entered
end
hset_object=set_object(data,handles);% call the set_object interface
hhset_object=guidata(hset_object);
hchild=get(hset_object,'children');
set(hchild,'enable','on')
set(handles.uvmat,'UserData',UvData)
set(handles.CheckZoom,'Value',0) %desactivate the zoom for object creation by the mouse
CheckZoom_Callback(handles.uvmat, [], handles)
set(handles.delete_object,'Visible','on')

%------------------------------------------------------------------------
function MenuBrowseObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%get the object file 
[FileName, PathName, filterindex] = uigetfile( ...
       {'*.xml;*.mat', ' (*.xml,*.mat)';
       '*.xml',  '.xml files '; ...
        '*.mat',  '.mat matlab files '}, ...
        'Pick an xml Object file',get(handles.RootPath,'String'));
fileinput=[PathName FileName];%complete file name 
sizf=size(fileinput);
if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end

%read the file
[data,heading]=xml2struct(fileinput);
if ~strcmp(heading,'ProjObject')
    msgbox_uvmat('WARNING','The xml file does not have the heading ProjObject for projection objects')
end
[tild,data.Name]=fileparts(FileName);% object name set as file name
ListObject=get(handles.ListObject,'String');
if ~strcmp(ListObject{end},'')
    ListObject=[ListObject;{''}]; %append a blank to the list (if not already done) to indicate the creation of a new object
    set(handles.ListObject,'String',ListObject)
end
IndexObj=length(ListObject);

UvData=get(handles.uvmat,'UserData');
UvData.Object{IndexObj}=[]; %create a new empty object
UvData.Object{IndexObj}.DisplayHandle.uvmat=[]; %no plot handle before plot_field operation
UvData.Object{IndexObj}.DisplayHandle.view_field=[]; %no plot handle before plot_field operation
set(handles.uvmat,'UserData',UvData)
set(handles.ListObject,'Value',IndexObj)
hset_object=set_object(data);% call the set_object interface
set(get(hset_object,'children'),'enable','on')% enable edit action on elements on GUI set_object
set(handles.edit_object,'Value',0); %suppress the object edit mode
set(handles.edit_object,'BackgroundColor',[0.7,0.7,0.7])  
set(handles.delete_object,'Visible','on')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MenuEdit Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
function MenuEditObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.edit_object,'Value',1)
edit_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function MenuEditVectors_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.edit_vect,'Visible','on')
set(handles.edit_vect,'Value',1)
edit_vect_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MenuTools Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
function MenuCalib_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 

%suppress competing options 
set(handles.CheckZoom,'Value',0)
set(handles.CheckZoom,'BackgroundColor',[0.7 0.7 0.7])
set(handles.ListObject,'Value',1)      
% initiate display of GUI geometry_calib
data=[]; %default
if isfield(UvData,'CoordType')
    data.CoordType=UvData.CoordType;
end
[RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
FileName=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];
set(handles.view_xml,'Backgroundcolor',[1 1 0])%indicate the reading of the current xml file by geometry_calib
pos_uvmat=get(handles.uvmat,'Position');
pos_cal(1)=pos_uvmat(1)+UvData.OpenParam.PosGeometryCalib(1)*pos_uvmat(3);
pos_cal(2)=pos_uvmat(2)+UvData.OpenParam.PosGeometryCalib(2)*pos_uvmat(4);
pos_cal(3:4)=UvData.OpenParam.PosGeometryCalib(3:4).* pos_uvmat(3:4);
geometry_calib(FileName,pos_cal);% call the geometry_calib interface	
set(handles.view_xml,'Backgroundcolor',[1 1 1])%indicate the end of reading of the current xml file by geometry_calib
set(handles.MenuCalib,'checked','on')% indicate that MenuCalib is activated, test used by mouse action


%-----------------------------------------------------------------------
function MenuLIFCalib_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%% read UvData properties stored on the uvmat interface 
UvData=get(handles.uvmat,'UserData');
if isfield(UvData,'XmlData')&& isfield(UvData.XmlData{1},'GeometryCalib')
    XmlData=UvData.XmlData{1};
else
    msgbox_uvmat('ERROR','geometric calibration needed: use Tools/geometric calibration in the menu bar');
    return
end

%% read lines currently drawn
ListObj=UvData.Object;
select=zeros(1,numel(ListObj));
for iobj=1:numel(ListObj);
    if isfield(ListObj{iobj},'Type') && strcmp(ListObj{iobj}.Type,'line')
        select(iobj)=1;
    end
end
val=find(select);
if numel(val)<2
    msgbox_uvmat('ERROR','light rays must be defined by at least two lines created by Projection object/line in the menu bar');
    return
else
    set(handles.ListObject,'Value',val);% show the selected lines on the list
    ObjectData=UvData.Object(val);
    for iobj=1:length(ObjectData)
%         if isfield(ObjectData{iobj},'Coord')
            xA(iobj)=ObjectData{iobj}.Coord(1,1);
            yA(iobj)=ObjectData{iobj}.Coord(1,2);
            xB(iobj)=ObjectData{iobj}.Coord(2,1);
            yB(iobj)=ObjectData{iobj}.Coord(2,2);
%         end
    end
end

%% find the origin as intersection of the two first lines (see http://www.ahristov.com/tutorial/geometry-games/intersection-lines.html )
x1=xA(1);x2=xB(1);
x3=xA(2);x4=xB(2);
y1=yA(1);y2=yB(1);
y3=yA(2);y4=yB(2);
D = (x1-x2)*(y3-y4) -(y1-y2)*(x3-x4);
if D==0
    msgbox_uvmat('ERROR','the two lines are parallel');
    return
end
x0=((x3-x4)*(x1*y2-y1*x2)-(x1-x2)*(x3*y4-y3*x4))/D;
y0=((y3-y4)*(x1*y2-y1*x2)-(y1-y2)*(x3*y4-y3*x4))/D;
XmlData.Illumination.Origin=[x0 y0];
XmlData.PolarCentre=[x0 y0];

%% display the current image in polar coordinates with origin at the  illumination source
currentdir=pwd;  
uvmatpath=fileparts(which('uvmat'));
cd(fullfile(uvmatpath,'transform_field'));
phys_polar=str2func('phys_polar');
cd(currentdir)
DataOut=phys_polar(UvData.Field,XmlData);
view_field(DataOut);

%% use the third line for reference luminosity
if numel(val)==3
    x_ref=linspace(ObjectData{3}.Coord(1,1),ObjectData{3}.Coord(2,1),10);
    y_ref=linspace(ObjectData{3}.Coord(1,2),ObjectData{3}.Coord(2,2),10);
    x_ref=x_ref-x0;
    y_ref=y_ref-y0;
    [theta_ref,r_ref] = cart2pol(x_ref,y_ref);%theta_ref  and r_ref are the polar coordinates of the points on the line
    theta_ref=theta_ref*180/pi;
    figure
    plot(theta_ref,r_ref)
    azimuth_ima=linspace(DataOut.AY(1),DataOut.AY(2),size(DataOut.A,1));%profile of x index on the transformed image
    dist_source = interp1(theta_ref,r_ref,azimuth_ima);
    dist_source_pixel=round(size(DataOut.A,2)*(dist_source-DataOut.AX(1))/(DataOut.AX(2)-DataOut.AX(1)));
    line_nan= isnan(dist_source_pixel);
    dist_source_pixel(line_nan)=1;
    width=20; %number of pixels used for reference
    DataOut.A=double(DataOut.A);
    Anorm=zeros(size(DataOut.A));
    Aval=mean(mean(DataOut.A));
    for iline=1:size(DataOut.A,1)
        lum(iline)=mean(DataOut.A(iline,dist_source_pixel(iline):dist_source_pixel(iline)+width));
        Anorm(iline,:)=uint16(Aval*DataOut.A(iline,:)/lum(iline));
    end
    lum(line_nan)=NaN;
    figure
    plot(1:size(DataOut.A,1),lum)
end
ImaName=regexprep([get(handles.RootFile,'String') get(handles.FileIndex,'String')],'//','');
NewImageName=fullfile(get(handles.RootPath,'String'),'polar',[ImaName get(handles.FileExt,'String')]);
imwrite(Anorm,NewImageName,'BitDepth',16)

%% record the origin in the xml file
XmlFileName=find_imadoc(get(handles.RootPath,'String'),get(handles.SubDir,'String'),get(handles.RootFile,'String'),get(handles.FileExt,'String'));
answer=msgbox_uvmat('INPUT_Y-N','save the illumination origin in the current xml file?');
if strcmp(answer,'Yes')
    t=xmltree(XmlFileName); %read the file
    title=get(t,1,'name');
    if ~strcmp(title,'ImaDoc')
        msgbox_uvmat('ERROR','wrong xml file');
        return
    end
    % backup the output file if it already exist, and read it
    backupfile=XmlFileName;
    testexist=2;
    while testexist==2
        backupfile=[backupfile '~'];
        testexist=exist(backupfile,'file');
    end
    [success,message]=copyfile(XmlFileName,backupfile);%make backup
    if success~=1
        errormsg=['errror in xml file backup: ' message];
        return
    end
    uid_illumination=find(t,'ImaDoc/Illumination');
    if isempty(uid_illumination)  %if GeometryCalib does not already exists, create it
        [t,uid_illumination]=add(t,1,'element','Illumination');
    end
    uid_origin=find(t,'ImaDoc/Illumination/Origin');
    if ~isempty(uid_origin)  %if GeometryCalib does not already exists, create it
         t=delete(t,uid_origin);
    end
    % save the illumination origin
    t=struct2xml(XmlData.Illumination,t,uid_illumination); 
    save(t,XmlFileName);
end
    


%------------------------------------------------------------------------
function MenuMask_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 
ListObj=UvData.Object;
select=zeros(1,numel(ListObj));
for iobj=1:numel(ListObj);
    if strcmp(ListObj{iobj}.ProjMode,'mask_inside')||strcmp(ListObj{iobj}.ProjMode,'mask_outside')
        select(iobj)=1;
    end
end
val=find(select);
if isempty(val)
    msgbox_uvmat('ERROR','polygons must be first created by Projection object/mask polygon in the menu bar');
    return
else
    set(handles.ListObject,'Value',val);
    flag=1;
    npx=size(UvData.Field.A,2);
    npy=size(UvData.Field.A,1);
    xi=0.5:npx-0.5;
    yi=0.5:npy-0.5;
    [Xi,Yi]=meshgrid(xi,yi);
%     if isfield(UvData,'Object')
        for iobj=1:length(UvData.Object)
            ObjectData=UvData.Object{iobj};
            if isfield(ObjectData,'ProjMode') &&(isequal(ObjectData.ProjMode,'mask_inside')||isequal(ObjectData.ProjMode,'mask_outside'));
                flagobj=1;
                testphys=0; %coordinates in pixels by default
                if isfield(ObjectData,'CoordUnit') && ~isequal(ObjectData.CoordUnit,'pixel')
                    if isfield(UvData,'XmlData')&& isfield(UvData.XmlData{1},'GeometryCalib')
                        Calib=UvData.XmlData{1}.GeometryCalib;
                        testphys=1;
                    end
                end
                if isfield(ObjectData,'Coord')&& isfield(ObjectData,'Type')
                    if isequal(ObjectData.Type,'polygon')
                        X=ObjectData.Coord(:,1);
                        Y=ObjectData.Coord(:,2);
                        if testphys
                            pos=[X Y zeros(size(X))];
                            if isfield(Calib,'SliceCoord') && length(Calib.SliceCoord)>=3
                                if isfield(Calib,'SliceAngle')&&~isequal(Calib.SliceAngle,[0 0 0])
                                    om=norm(Calib.SliceAngle);%norm of rotation angle in radians
                                    OmAxis=Calib.SliceAngle/om; %unit vector marking the rotation axis
                                    cos_om=cos(pi*om/180);
                                    sin_om=sin(pi*om/180);
                                    pos=cos_om*pos+sin_om*cross(OmAxis,pos)+(1-cos_om)*(OmAxis*pos')*OmAxis;
                                end
                                pos(:,1)=pos(:,1)+Calib.SliceCoord(1);
                                pos(:,2)=pos(:,2)+Calib.SliceCoord(2);
                                pos(:,3)=pos(:,3)+Calib.SliceCoord(3);
                            end                           
                            [X,Y]=px_XYZ(Calib,pos(:,1),pos(:,2),pos(:,3));
                        end
                        flagobj=~inpolygon(Xi,Yi,X',Y');%=0 inside the polygon, 1 outside
                    elseif isequal(ObjectData.Type,'ellipse')
                        if testphys
                            %[X,Y]=px_XYZ(Calib,X,Y,0);% TODO:create a polygon boundary and transform to phys
                        end
                        RangeX=max(ObjectData.RangeX);
                        RangeY=max(ObjectData.RangeY);
                        X2Max=RangeX*RangeX;
                        Y2Max=RangeY*RangeY;
                        distX=(Xi-ObjectData.Coord(1,1));
                        distY=(Yi-ObjectData.Coord(1,2));
                        flagobj=(distX.*distX/X2Max+distY.*distY/Y2Max)>1;
                    elseif isequal(ObjectData.Type,'rectangle')
                        if testphys
                            %[X,Y]=px_XYZ(Calib,X,Y,0);% TODO:create a polygon boundary and transform to phys
                        end
                        distX=abs(Xi-ObjectData.Coord(1,1));
                        distY=abs(Yi-ObjectData.Coord(1,2));
                        flagobj=distX>max(ObjectData.RangeX) | distY>max(ObjectData.RangeY);
                    end
                    if isequal(ObjectData.ProjMode,'mask_outside')
                        flagobj=~flagobj;
                    end
                    flag=flag & flagobj;
                end
            end
        end
%     end 
    %mask name
    RootPath=get(handles.RootPath,'String');
    SubDir=get(handles.SubDir,'String');
    RootFile=get(handles.RootFile,'String');
    if ~isempty(RootFile)&&(isequal(RootFile(1),'/')|| isequal(RootFile(1),'\'))
        RootFile(1)=[];
    end
    list=get(handles.masklevel,'String');
    masknumber=num2str(length(list));
    maskindex=get(handles.masklevel,'Value');
   % mask_name=fullfile_uvmat(RootPath,'',[RootFile '_' masknumber 'mask'],'.png','_1',maskindex);
    mask_name=fullfile_uvmat(RootPath,[SubDir '.mask'],'mask','.png','_1',maskindex);
    imflag=uint8(255*(0.392+0.608*flag));% =100 for flag=0 (vectors not computed when 20<imflag<200)
    imflag=flipdim(imflag,1);

    %display the mask
    hfigmask=figure;
    set(hfigmask,'Name','mask image')
    vec=linspace(0,1,256);%define a linear greyscale colormap
    map=[vec' vec' vec'];
    colormap(map)
    image(imflag);
    answer=msgbox_uvmat('INPUT_TXT','mask file name:', mask_name);
    if ~strcmp(answer,'Cancel')
        mask_dir=fileparts(answer);
        if ~exist(mask_dir,'dir')
            [xx,msg1]=mkdir(mask_dir);
            if ~strcmp(msg1,'')
                errormsg=['cannot create ' mask_dir ': ' msg1];%error message for directory creation
                return
            end
        end
        imwrite(imflag,answer,'BitDepth',8);
    end
    set(handles.ListObject,'Value',1)
end

%------------------------------------------------------------------------
%-- open the GUI set_grid.fig to create grid
function MenuGrid_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%suppress the other options if grid is chosen
set(handles.edit_vect,'Value',0)
edit_vect_Callback(hObject, eventdata, handles)
set(handles.edit_object,'BackgroundColor',[0.7 0.7 0.7])
set(handles.ListObject,'Value',1)      

%prepare display of the set_grid GUI
[RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
FileName=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];
UvData=get(handles.uvmat,'UserData');
% CoordList=get(handles.TransformName,'String');
% val=get(handles.TransformName,'Value');
set_grid(FileName,UvData.Field);% call the set_object interface


%------------------------------------------------------------------------
function MenuRuler_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckZoom,'Value',0)
CheckZoom_Callback(handles.uvmat, [], handles)
set(handles.MenuRuler,'checked','on')
UvData=get(handles.uvmat,'UserData');
UvData.MouseAction='ruler';
set(handles.uvmat,'UserData',UvData);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MenuRun Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%------------------------------------------------------------------------
% open the GUI 'series'
function MenuSeries_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
[RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
Param.FileName=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];%first input file name
if isequal(get(handles.SubField,'Value'),1)
    [RootPath_1,SubDir_1,RootFile_1,FileIndex_1,FileExt_1]=read_file_boxes_1(handles);
    FileName_1=[fullfile(RootPath_1,SubDir_1,RootFile_1) FileIndex_1 FileExt_1];
    if ~isequal(FileName_1,Param.FileName)
        Param.FileName_1=FileName_1;%second input file name if relevant
    end
end
Param.NomType=get(handles.NomType,'String');
Param.NomType_1=get(handles.NomType_1,'String');
Param.CheckFixPair=get(handles.CheckFixPair,'Value');
UvData=get(handles.uvmat,'UserData');
if isfield(UvData,'XmlData')&& isfield(UvData.XmlData{1},'Time')
    Param.Time=UvData.XmlData{1}.Time;
end
if isequal(get(handles.scan_i,'Value'),1)
    Param.incr_i=str2num(get(handles.num_IndexIncrement,'String'));
elseif isequal(get(handles.scan_j,'Value'),1)
    Param.incr_j=str2num(get(handles.num_IndexIncrement,'String'));
end

%% transfer fields and coordinate names
Param.list_fields=get(handles.FieldName,'String');% list menu fields
FieldName=Param.list_fields{get(handles.FieldName,'Value')};
ind_image=find(strcmp('image',Param.list_fields));
if ~isempty(ind_image) && numel(Param.list_fields)>1
    Param.list_fields(ind_image)=[]; %suppress  'image' option
end
Param.index_fields=find(strcmp(FieldName,Param.list_fields));% selected string index
Param.list_fields_1=get(handles.FieldName_1,'String');% list menu fields
if ischar(Param.list_fields_1),Param.list_fields_1={Param.list_fields_1};end
FieldName_1=Param.list_fields_1{get(handles.FieldName_1,'Value')};
ind_image=find(strcmp('image',Param.list_fields_1));
if ~isempty(ind_image) && numel(Param.list_fields_1)>1
    Param.list_fields_1(ind_image)=[]; %suppress  'image' option
end
Param.index_fields_1=find(strcmp(FieldName_1,Param.list_fields_1));% selected string index
TransformList=get(handles.TransformName,'String');
Param.TransformName=TransformList{get(handles.TransformName,'Value')};
Param.Coord_x_str=get(handles.Coord_x,'String');
Param.Coord_x_val=get(handles.Coord_x,'Value');
Param.Coord_y_str=get(handles.Coord_y,'String');
Param.Coord_y_val=get(handles.Coord_y,'Value');
series(Param); %run the series interface

%------------------------------------------------------------------------
% -- open the GUI civ.fig for PIV
function MenuPIV_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
 [RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
 FileName=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];
civ(FileName);% interface de civ(not in the uvmat file)

% --------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
else
    addpath (fullfile(pathelp,'uvmat_doc'))
    web(helpfile);
end

% --- Executes on selection change in Coord_y.
function Coord_y_Callback(hObject, eventdata, handles)

% --- Executes on selection change in Coord_x.
function Coord_x_Callback(hObject, eventdata, handles)


% --- Executes on button press in CheckColorBar.
function CheckColorBar_Callback(hObject, eventdata, handles)



function TransformPath_Callback(hObject, eventdata, handles)
% hObject    handle to TransformPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TransformPath as text
%        str2double(get(hObject,'String')) returns contents of TransformPath as a double


%TODO: use to modify fill_GUI
%'write_plot_param': update the plotting parameters on the uvmat or view_field interface after a plotting operation
function write_plot_param(handles,PlotParam)
%% coordinates
if isempty(PlotParam.Coordinates)
    set(handles.Coordinates,'Visible','off')
    set(handles.PlotAxes,'Visible','off')
    set(handles.text_display,'Visible','off')
    set(handles.TableDisplay,'Visible','on')
else
    set(handles.Coordinates,'Visible','on')
    set(handles.PlotAxes,'Visible','on')
    set(handles.text_display,'Visible','on')
    if isfield(handles,'TableDisplay')
    set(handles.TableDisplay,'Visible','off')
    end
    Coordinates=PlotParam.Coordinates;
    if isfield(Coordinates,'CheckFixAspectRatio')
        if Coordinates.CheckFixAspectRatio
            set(handles.CheckFixAspectRatio,'Value',1)
        else
            set(handles.CheckFixAspectRatio,'Value',0)
 
        end
    end
    if isfield(Coordinates,'AspectRatio')
        set(handles.num_AspectRatio,'String',num2str(Coordinates.AspectRatio))
    end
    if isfield(Coordinates,'MinX')
        set(handles.num_MinX,'String',num2str(Coordinates.MinX,4));
        set(handles.num_MaxX,'String',num2str(Coordinates.MaxX,4));
        set(handles.num_MinY,'String',num2str(Coordinates.MinY,4));
        set(handles.num_MaxY,'String',num2str(Coordinates.MaxY,4));
    else
        set(handles.num_MinX,'String','');
        set(handles.num_MaxX,'String','');
        set(handles.num_MinY,'String','');
        set(handles.num_MaxY,'String','');
    end
end

%% scalar or image parameters
if isfield(PlotParam,'Scalar')
    set(handles.Scalar,'Visible','on')
    if isfield(PlotParam.Scalar,'MaxA')
        set(handles.num_MaxA,'String',num2str(PlotParam.Scalar.MaxA,3));
    end
    if isfield(PlotParam.Scalar,'MinA')
        set(handles.num_MinA,'String',num2str(PlotParam.Scalar.MinA,3));
    end   
    if isfield(PlotParam.Scalar,'IncrA')
        set(handles.num_IncrA,'String',num2str(PlotParam.Scalar.IncrA,3))
    end
    set(handles.CheckBW,'Value',PlotParam.Scalar.CheckBW)
    if isfield(PlotParam.Scalar,'Opacity')&&isfield(handles,'num_Opacity')
        set(handles.num_Opacity,'String',num2str(PlotParam.Scalar.Opacity)) 
    end
else
    set(handles.Scalar,'Visible','off')
end

%% parameter for vector field
if isfield(PlotParam,'Vectors')
    set(handles.Vectors,'Visible','on')
    if isfield(PlotParam.Vectors,'VecScale')
        set(handles.num_VecScale,'String',num2str(PlotParam.Vectors.VecScale,3))
    end
    if isfield(PlotParam.Vectors,'MinC')&& isfield(PlotParam.Vectors,'MaxC')
        MinC=PlotParam.Vectors.MinC;
        MaxC=PlotParam.Vectors.MaxC;
        set(handles.num_MinVec,'String', num2str(MinC,3));
        set(handles.num_MaxVec,'String',num2str(MaxC,3));
        list=get(handles.ColorCode,'String');
        ichoice=get(handles.ColorCode,'Value');
        color_option=list{ichoice};
        test3color=strcmp(color_option,'rgb')||strcmp(color_option,'bgr');
        if test3color% need to update color thresholds
            set(handles.num_ColCode1,'Visible','on')
            set(handles.num_ColCode2,'Visible','on')
            set(handles.Slider1,'Visible','on')
            set(handles.Slider2,'Visible','on')
            %ColCode1=MinC+(MaxC-MinC)*PlotParam.Vectors.ColCode1;
            %ColCode2=MinC+(MaxC-MinC)*PlotParam.Vectors.ColCode2;
%             ColCode1=MinC+(MaxC-MinC)*PlotParam.Vectors.ColCode1;
            %ColCode2=MinC+(MaxC-MinC)*PlotParam.Vectors.ColCode2;
            set(handles.num_ColCode1,'String',num2str(PlotParam.Vectors.ColCode1,3))
            set(handles.num_ColCode2,'String',num2str(PlotParam.Vectors.ColCode2,3))
            set(handles.Slider1,'Value',(PlotParam.Vectors.ColCode1-MinC)/(MaxC-MinC))
            set(handles.Slider2,'Value',(PlotParam.Vectors.ColCode2-MinC)/(MaxC-MinC))
        else
            set(handles.num_ColCode1,'Visible','off')
            set(handles.num_ColCode2,'Visible','off')
            set(handles.Slider1,'Visible','off')
            set(handles.Slider2,'Visible','off')
        end
    end
else
    set(handles.Vectors,'Visible','off')
    if isfield(handles,'edit_vect')
        set(handles.edit_vect,'Visible','off')
        set(handles.record,'Visible','off')
    end
end
