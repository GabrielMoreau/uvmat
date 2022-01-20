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

%=======================================================================
% Copyright 2008-2022, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

% Information stored on the interface:(use 'Export/field in workspace' in
% the menu bar of uvmat to retrieve it)
%          .OpenParam: structure containing parameters defined when uvmat is opened
%                       .PosColorbar: position (1x4 vector)of the colorbar (relative to the fig uvmat)
%                       .PosGeometryCalib: size of set_object
%                       .NbBuiltin: nbre of functions always displayed in TransformName menu
%          .ProjObject: cell array of structures representing the current projection objects, as produced by 'set_object.m'={[]} by default
%          .NewSeries: =0/1 flag telling whether a new field series has been opened
%          .FileName_1: name of the current second field (used to detect a  constant field during file scanning)
%          .FileType: current file type, as defined by the fct  get_file_type.m)
%          .i1_series,.i2_series,.j1_series,.j1_series: series of i1,i2,j1,j2 indices detected in the input dir,set by  the fct find_file_series
%          .MovieObject: current movie object
%          .TimeUnit: unit for time
%          .XmlData: cell array of 1 or 2 structures representing the xml files associated with the input fieldname (containing timing  and geometry calibration)
%          .Field: cell array of 1 or 2 structures representing the current  input field(s)
%          .PlotAxes: field structure representing the current field plotted  on the main axes  (used for mouse operations)
%          .HistoAxes: idem for Histogram axes

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   DATA FLOW  (for REFRESH_Callback) %%%%%%%%%%%%%%%%%%%%:
%
%
% 1) Input filenames are determined by MenuBrowse (first field), MenuBrowseCampaign
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
%                       UvData.Field-------------->Histogram
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
% and Y axes are represented by UvData.Field.Coord_x and UvData.Field.Coord_y, and .X and
% .Y for C (the same as velocity vectors). If A is a nxxny matrix (scalar
% on a regtular grid), then .Coord_x andf.Coord_y contains only two elements, represneting the
% axes of the four image corners. The scalar name is represented by
% the strings .AName and/or .CName.
% If the scalar exists in an input open (image or scalar stored under its
% name in a netcdf open), it is directly read at the level of Field{1}or Field{2}.
% Else only its name AName is recorded in Field{i}, and its field is then calculated
%by the fuction calc_scal after the coordinate transform or after projection on an CheckEditObject

% Properties attached to plotting figures (standard Matlab properties):
%    'CurrentAxes'= gca or get(gcf,'CurrentAxes');
%    'CurrentPoint'=get(gcf,'CurrentPoint'): figure axes of the point over which the mouse is positioned
%    'CurrentCharacter'=get(gcf,'CurrentCharacter'): last character typed  over the figure where the mouse is positioned
%    'WindowButtonMotionFcn': function permanently called by mouse motion over the figure
%    'KeyPressFcn': function called by pressing a key on the key board
%    'WindowButtonDownFcn':  function called by pressing the mouse over the  figure
%    'WindowButtonUpFcn': function called by releasing  the mouse pressure over the  figure

% Properties attached to plotting axes:
%    'CurrentPoint'=get(gca,'CurrentPoint'); (standard Matlab) same as for the figure, but position in plot axes.
%     AxeData:=get(gca,'UserData');
%     AxeData.Drawing  = create: create a new object
%                       = deform: modify an existing object by moving its defining create
%                      = off: no current drawing action
%                     = translate: translate an existing object
%                    = calibration: move a calibration point
%                    = CheckZoom: isolate a subregion for CheckZoom in=1 if an object is being currently drawn, 0 else (set to 0 by releasing mouse button)
%            .CurrentOrigin: Origin of a curently drawn CheckEditObject
%            .CurrentLine: currently drawn menuline (A REVOIR)
%            .CurrentObject: handle of the currently drawn CheckEditObject
%            .CurrentRectZoom: current rectangle used for CheckZoom

% Properties attached to projection objects (create, menuline, menuplane...):
%    'Tag'='proj_object': for all projection objects
%    ObjectData.Type=...: style of projection object:
%              .ProjMode
%              .Coordinates: defines the position of the object
%              .XMin,YMin....
%              .XMax,YMax....
%              .DX,DY,DZ
%              .Phi, .Theta, .Psi : Euler angles
%              .X,.Y,.U,.V.... : field data projected on the object
%              .IndexObj: index in the list of UvData.ProjObject
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

%% set the position of the GUI, colorbar and ancillary GUIs:
set(hObject,'Units','pixels')%
set(0,'Units','pixels');
ScreenSize=get(0,'ScreenSize');%size of the current screen
Width=1050;
Height=700;
%adjust to screen size (reduced by a min margin)
RescaleFactor=min((ScreenSize(3)-80)/Width,(ScreenSize(4)-80)/Height);
if RescaleFactor>1
    RescaleFactor=RescaleFactor/2+1/2; %reduce the rescale factor to provide an increased margin for a big screen
end
Width=Width*RescaleFactor;
Height=Height*RescaleFactor;
LeftX=80*RescaleFactor;%position of the left fig side, in pixels (put to the left side, with some margin)
LowY=round(ScreenSize(4)/2-Height/2); % put at the middle height on the screen
set(hObject,'Position',[LeftX LowY Width Height])
UvData.PosColorbar=[0.80 0.02 0.018 0.445];
AxeData.LimEditBox=1; %initialise AxeData
set(handles.PlotAxes,'UserData',AxeData)

%% set functions for the mouse and keyboard
set(hObject,'WindowKeyPressFcn',{'keyboard_callback',handles})%set keyboard action function
set(hObject,'WindowButtonMotionFcn',{'mouse_motion',handles})%set mouse action functio
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%set mouse click action function
set(hObject,'WindowButtonUpFcn',{'mouse_up',handles})
set(hObject,'DeleteFcn',{@closefcn})%
set(hObject,'ResizeFcn',{@ResizeFcn,handles})%

%% initialisation
set(handles.FieldName,'Value',1)
set(handles.FieldName,'string',{''})
UvData.ProjObject={[]};

%% TRANSFORM menu: builtin fcts
transform_menu={'';'sub_field';'phys';'phys_polar'};
UvData.OpenParam.NbBuiltin=numel(transform_menu); %number of functions
transform_path=fullfile(path_uvmat,'transform_field');
path_list=cell(UvData.OpenParam.NbBuiltin,1);
path_list{1}='';
for ilist=2:UvData.OpenParam.NbBuiltin
    path_list{ilist}=transform_path; % set transform_path to the path_list
end

%% EXPORT menu
export_menu={'as field in workspace';'in new figure';'on existing axis';'make movie';'more...'};
export_path=fullfile(path_uvmat,'export_fct');

%% load the list of previously browsed files in menus Open, Open_1 and TransformName
dir_perso=prefdir; % path to the directory .matlab containing the personal data of the current user
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');% personal data file uvmat_perso.mat' in .matlab
if exist(profil_perso,'file')% if the file exists
    h=load (profil_perso); % open the personal file
    if isfield(h,'MenuFile')% load the saved menu of previously opened files
        for ifile=1:min(length(h.MenuFile),5)
            set(handles.(['MenuFile_' num2str(ifile)]),'Label',h.MenuFile{ifile});
        end
    end
    if isfield(h,'MenuCampaign')% load the saved menu of previously opened campaigns
        for ifile=1:min(length(h.MenuCampaign),5)
            set(handles.(['MenuCampaign_' num2str(ifile)]),'Label',h.MenuCampaign{ifile});
        end
    end
    if isfield(h,'RootPath')
        set(handles.RootPath,'UserData',h.RootPath); %store the previous campaign in the UserData of RootPath
    end
    if isfield(h,'transform_fct') && iscell(h.transform_fct) % load the menu of transform fct set by user
        for ilist=1:length(h.transform_fct)
            if exist(h.transform_fct{ilist},'file')
                [path,file]=fileparts(h.transform_fct{ilist});
                transform_menu=[transform_menu; {file}];
                path_list=[path_list; {path}];
            end
        end
    end
    if isfield(h,'export_fct') && iscell(h.export_fct) % load the menu of export fct set by user
        for ilist=1:length(h.export_fct)
            if exist(h.export_fct{ilist},'file')
                [path,file]=fileparts(h.export_fct{ilist});
                export_menu=[export_menu; {file}];
            end
        end
    end
end
transform_menu=[transform_menu;{'more...'}];%append the option more.. to the menu
set(handles.TransformName,'String',transform_menu)% display the menu of transform fcts
set(handles.TransformName,'UserData',path_list)% store the corresponding list of path in UserData of uicontrol transform_fct
set(handles.TransformPath,'String','')
set(handles.TransformPath,'UserData',[])
export_menu=[export_menu;{'more...'}];%append the option more.. to the menu
%set(handles.TransformName,'String',transform_menu)% display the menu of transform fcts

%% case of an input argument for uvmat
%testinputfield=0;
inputfile=[];
%Field=[];
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
            [{'Copyright 2008-2022, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France'};...
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
%------------------------------------------------------------------------
varargout{1} = handles.output;% the only output argument is the handle to the GUI figure

%------------------------------------------------------------------------
% --- executed when closing uvmat: delete or desactivate the associated figures if exist
function closefcn(gcbo,eventdata)
%------------------------------------------------------------------------
% delete GUI 'view_field' if detected
hh=findobj(allchild(0),'tag','view_field');
if ~isempty(hh)
    delete(hh)
end
% delete GUI 'geometry_calib' if detected
hh=findobj(allchild(0),'tag','geometry_calib');
if ~isempty(hh)
    delete(hh)
end
% desable set_object editing action if detected
hh=findobj(allchild(0),'name','set_object');
if ~isempty(hh)
    hhh=findobj(hh,'tag','PLOT');
    set(hhh,'enable','off')
end
%delete the bowser if detected
hh=findobj(allchild(0),'tag','browser');
if ~isempty(hh)
    delete(hh)
end

%------------------------------------------------------------------------
%--- activated when resizing the GUI view_field
 function ResizeFcn(gcbo,eventdata,handles)
%------------------------------------------------------------------------
set(handles.uvmat,'Units','pixels')
size_fig=get(handles.uvmat,'Position');
ColumnWidth=max(150,0.18*size_fig(3));
ColumnWidth=min(ColumnWidth,250); % width of the right side display column, between 150 and 250, depending on the fig width

%% position of panel InputFile
set(handles.InputFile,'Units','pixels')
pos_InputFile=get(handles.InputFile,'Position');% [lower x lower y width height] for text_display
pos_InputFile(1)=0;
pos_InputFile(2)=size_fig(4)-pos_InputFile(4);             % set frame InputFile to the top of the fig
pos_InputFile(3)=size_fig(3);
set(handles.InputFile,'Position',pos_InputFile);% [lower x lower y width height] for text_display

%% reset position of text_display and TableDisplay
set(handles.text_display,'Units','pixels')
set(handles.TableDisplay,'Units','pixels')
pos_1=get(handles.text_display,'Position');% [lower x lower y width height] for text_display
    pos_1(3)=1.2*ColumnWidth;
pos_1(1)=size_fig(3)-pos_1(3);             % set text display to the right of the fig
pos_1(2)=size_fig(4)-pos_InputFile(4)-pos_1(4);             % set text display to the top of the fig
set(handles.text_display,'Position',pos_1)
set(handles.TableDisplay,'Position',[pos_1(1) 10 pos_1(3) 5*pos_1(4)])
% reset position of CheckTable
set(handles.CheckTable,'Units','pixels')
pos_CheckTable=get(handles.CheckTable,'Position');% [lower x lower y width height] for CheckHold
pos_CheckTable(1)=pos_1(1)-pos_CheckTable(3);       % set 'CheckHold' to the right of the fig
pos_CheckTable(2)=pos_InputFile(2)-pos_CheckTable(4);          % set 'CheckHold' to the lower edge of text display
set(handles.CheckTable,'Position',pos_CheckTable)

%% reset position of CheckHold
% pos_CheckHold=get(handles.CheckHold,'Position');% [lower x lower y width height] for CheckHold
% pos_CheckHold(1)=size_fig(3)-pos_CheckHold(3);       % set 'CheckHold' to the right of the fig
% pos_CheckHold(2)=pos_1(2)-pos_CheckHold(4);          % set 'CheckHold' to the lower edge of text display
% set(handles.CheckHold,'Position',pos_CheckHold)

%% reset position of Coordinates panel
set(handles.Coordinates,'Units','pixels')
pos_2=get(handles.Coordinates,'Position');% [lower x lower y width height] for frame 'Coordinates'
pos_2(3)=ColumnWidth;
pos_2(1)=size_fig(3)-pos_2(3);       % set 'Coordinates' to the right of the fig
pos_2(2)=pos_1(2)-pos_2(4);          % set 'Coordinates' to the lower edge of text display, allowing a margin for CheckHold
set(handles.Coordinates,'Position',pos_2)

%% reset position of Axes panel
set(handles.Axes,'Units','pixels')
pos_3=get(handles.Axes,'Position');% [lower x lower y width height] for frame 'Coordinates'
pos_3(3)=ColumnWidth;
pos_3(1)=size_fig(3)-pos_3(3);       % set 'Coordinates' to the right of the fig
pos_3(2)=pos_2(2)-pos_3(4);          % set 'Coordinates' to the lower edge of text display, allowing a margin for CheckHold
set(handles.Axes,'Position',pos_3)

%% reset position of  Scalar
set(handles.Scalar,'Units','pixels')
pos_4=get(handles.Scalar,'Position'); % [lower x lower y width height] for frame 'Scalar'
pos_4(3)=ColumnWidth;
pos_4(1)=size_fig(3)-pos_4(3);         % set 'Scalar' to the right of the fig
if strcmp(get(handles.Scalar,'Visible'),'on')
    pos_4(2)=pos_3(2)-pos_4(4); % set 'Scalar' to the lower edge of frame 'Coordinates' if visible
else
    pos_4(2)=pos_3(2);% set 'Scalar' to the lower edge of frame 'text display' if  unvisible
end
set(handles.Scalar,'Position',pos_4)

%% reset position of  Vectors
set(handles.Vectors,'Units','pixels')
pos_5=get(handles.Vectors,'Position');
pos_5(3)=ColumnWidth;
pos_5(1)=size_fig(3)-pos_5(3);
if strcmp(get(handles.Vectors,'visible'),'on')
    pos_5(2)=pos_4(2)-pos_5(4);
else
    pos_5(2)=pos_4(2);
end
set(handles.Vectors,'Position',pos_5)

%% reset position and scale of axis
pos(1)=0.2*size_fig(3)+35;
pos(2)=50;
pos(3)=0.77*size_fig(3)-1.2*ColumnWidth;
pos(4)=size_fig(4)-100;
set(handles.PlotAxes,'Units','pixels')
set(handles.PlotAxes,'Position',pos)
set(handles.PlotAxes,'Units','normalized')



%------------------------------------------------------------------------
%------------------------------------------------------------------------
%  II - TOOLS FROM THE UPPER MENU BAR
%------------------------------------------------------------------------
%------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open Menu Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%------------------------------------------------------------------------
% --- Executes on the menu Open/Browse...fill_GUI
% search the files, recognize their type according to their name and fill the rootfile input windows
function MenuBrowse_Callback(hObject, eventdata, handles)
[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
if isempty(regexp(RootPath,'^http://'))%usual files
oldfile=[fullfile(RootPath,SubDir,RootFile) FileIndices FileExt];
else %Opendap
    oldfile=[RootPath '/' SubDir '/' RootFile FileIndices FileExt];
end
if isempty(oldfile) %loads the previously stored file name and set it as default in the file_input box
    oldfile=get(handles.RootPath,'UserData');
end
fileinput=uigetfile_uvmat('pick an input file',oldfile);
hh=dir(fileinput);
if numel(hh)>1
    msgbox_uvmat('ERROR','invalid input, probably a broken link');
else

    %% display the selected field and related information
    if ~isempty(fileinput)
        set(handles.SubField,'Value',0)
        desable_subfield(handles)
        display_file_name(handles,fileinput)
    end
end

% --------------------------------------------------------------------
function MenuBrowseOpendap_Callback(hObject, eventdata, handles)
    oldfile=get(hObject,'Label');
fileinput=uigetfile_uvmat('pick an input file',oldfile);
hh=dir(fileinput);
if numel(hh)>1
    msgbox_uvmat('ERROR','invalid input, probably a broken link');
else

    %% display the selected field and related information
    if ~isempty(fileinput)
        set(handles.SubField,'Value',0)
        desable_subfield(handles)
        display_file_name(handles,fileinput)
    end
end

% -----------------------------------------------------------------------
% --- Open again the file whose name has been recorded in MenuFile
function MenuFile_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=get(hObject,'Label');
set(handles.SubField,'Value',0)
desable_subfield(handles)
errormsg=display_file_name( handles,fileinput);
if ~isempty(errormsg)
    set(hObject,'Label','')
    MenuFile=[{get(handles.MenuFile_1,'Label')};{get(handles.MenuFile_2,'Label')};...
        {get(handles.MenuFile_3,'Label')};{get(handles.MenuFile_4,'Label')};{get(handles.MenuFile_5,'Label')}];
    str_find=strcmp(get(hObject,'Label'),MenuFile);
    MenuFile(str_find)=[];% suppress the input file to the list
    for ifile=1:numel(MenuFile)
        set(handles.(['MenuFile_' num2str(ifile)]),'Label',MenuFile{ifile});
    end
end



% -----------------------------------------------------------------------
% --- Executes on the menu Open/Browse campaign...
% --- search the file inside a campaign, using the GUI browse_data
% -----------------------------------------------------------------------
function MenuBrowseCampaign_Callback(hObject, eventdata, handles)
% set(handles.MenuOpenCampaign,'ForegroundColor',[1 1 0])
% drawnow
[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
DataSeries=fullfile(RootPath,SubDir);
if isempty(DataSeries) %loads the previously stored file name and set it as default in the file_input box
    DataSeries=get(handles.RootPath,'UserData');
end
OutPut=browse_data(DataSeries,'on');% open the GUI browse_data to get select a campaign dir, experiment and device
if ~isfield(OutPut,'Campaign')
    return
end
DataSeries=fullfile(OutPut.Campaign,OutPut.Experiment{1},OutPut.DataSeries{1});
fileinput=uigetfile_uvmat('pick an input file',DataSeries);
hh=dir(fileinput);
if numel(hh)>1
    msgbox_uvmat('ERROR','invalid input, probably a broken link');
    return
end

%% update the list of campaigns in the menubar
MenuCampaign=[{get(handles.MenuCampaign_1,'Label')};{get(handles.MenuCampaign_2,'Label')};...
    {get(handles.MenuCampaign_3,'Label')};{get(handles.MenuCampaign_4,'Label')};{get(handles.MenuCampaign_5,'Label')}];
check_dir=isempty(find(strcmp(DataSeries,MenuCampaign)));
if check_dir %insert the new campaign in the list if it is not found
    MenuCampaign(end)=[]; %suppress the last item
    MenuCampaign=[{DataSeries};MenuCampaign];%insert the new campaign
    for ilist=1:numel(MenuCampaign)
        set(handles.(['MenuCampaign_' num2str(ilist)]),'Label',MenuCampaign{ilist})
    end
    % save the list for future opening:
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        save (profil_perso,'MenuCampaign','RootPath','-append'); %store the file names for future opening of uvmat
    else
        save (profil_perso,'MenuCampaign','RootPath','-V6'); %store the file names for future opening of uvmat
    end
end

%% display the selected field and related information
%display_file_name( handles,fullfile(DirName,FileName))
display_file_name( handles,fileinput)
set(handles.MenuOpenCampaign,'ForegroundColor',[0 0 0])

% -----------------------------------------------------------------------
% --- Open again as second field the file whose name has been recorded in MenuFile_1
% -----------------------------------------------------------------------
function MenuCampaign_Callback(hObject, eventdata, handles)

set(handles.MenuOpenCampaign,'ForegroundColor',[1 1 0])
OutPut=browse_data(get(hObject,'Label'),'on');% open the GUI browse_data to get select a campaign dir, experiment and device
if isfield(OutPut,'Campaign')
    fileinput=uigetfile_uvmat('pick an input file',fullfile(OutPut.Campaign,OutPut.Experiment{1},OutPut.DataSeries{1}));
    hh=dir(fileinput);
    if numel(hh)>1
        msgbox_uvmat('ERROR','invalid input, probably a broken link');
    else
        display_file_name(handles,fileinput)
    end
end
set(handles.MenuOpenCampaign,'ForegroundColor',[0 0 0])


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
disp('Data_uvmat.Field=')
evalin('base','Data_uvmat.Field') %display CurData in the workspace
commandwindow; %brings the Matlab command window to the front

%------------------------------------------------------------------------
% --- Executes on button press in Menu/Export/extract figure.
function MenuExportFigure_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
hfig=figure;
hc=copyobj(handles.PlotAxes,hfig);
set(hc,'Position',[0.1 0.1 0.8 0.8])
title_menu=get(handles.FieldName,'String');
title_string=title_menu{get(handles.FieldName,'Value')};
title(title_string);
h=findobj(handles.PlotAxes,'tag','ima'); %look for image in the plot
if ~isempty(h)
    map=colormap(handles.PlotAxes);
    colormap(map);%transmit the current colormap to the new fig
    colorbar
end
%% copy the colormap of the vector color if relevant
if strcmp(get(handles.Vectors,'Visible'),'on')
    color_menu=get(handles.ColorCode,'String');
    color_mode=color_menu{get(handles.ColorCode,'Value')};
    if ~(strcmp(color_mode,'black')||strcmp(color_mode,'white'))
        hveccolor=axes('Position',[0.93 0.1 0.02 0.5]);
        ima=permute(get(handles.VecColBar,'CData'),[2 1 3]);
        ymin=str2num(get(handles.num_MinVec,'String'));
        ymax=str2num(get(handles.num_MaxVec,'String'));
        set(hveccolor,'YLim',[ymin ymax])
        imagesc([0 1],[ymin ymax],ima)
        set(hveccolor,'YDir','normal')
        set(hveccolor,'YAxisLocation', 'right')
        set(hveccolor,'XTickLabel','')
        scalar_menu=get(handles.ColorScalar,'String');
        scalar_title=scalar_menu{get(handles.ColorScalar,'Value')};
        htitle=get(hveccolor,'Title');
        set(htitle,'String',scalar_title)
    end
end


% --------------------------------------------------------------------
function MenuExportAxis_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
ListFig=findobj(allchild(0),'Type','figure');
nb_option=0;
menu={};
for ilist=1:numel(ListFig)
    FigName=get(ListFig(ilist),'name');
    if isempty(FigName)
        FigName=['figure ' num2str(get(ListFig(ilist),'number'))];
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
% function called by the upper bar menu item Export/make movie
% --------------------------------------------------------------------
function MenuExportMovie_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
set(handles.MenuExportMovie,'BusyAction','queue')% activate the button

[RootPath,SubDir,RootFile]=read_file_boxes(handles);%read input file path from the GUI uvmat

%% create a fig and axis for movies
figure_movie=findobj(allchild(0),'name','figure_movie');% find existing movie figure
if ~isempty(figure_movie)
    delete(figure_movie)%delete existing figure_movie
end
figure_movie=figure;% create a new movie figure 
nbpix=[640 480];% resolution VGA
set(figure_movie,'name','figure_movie','Position',[1 1 nbpix])
newaxes=copyobj(handles.PlotAxes,figure_movie);%new plotting axes in the new figure
set(newaxes,'Tag','movieaxes')

%% display time if defined in uvmat
time_str=get(handles.TimeValue,'String');
if ~isempty(time_str)
    htitle=get(newaxes,'Title');
    set(htitle,'String',['t=' time_str])
end
map=colormap(handles.PlotAxes);
colormap(map);%transmit the current colormap to the zoom fig
colorbar

%% create the GUI set_movie
Position=get(figure_movie,'Position');
Position(2)=Position(2)+1.2*Position(4);
Position(3)=1.5*Position(3);
Position(4)=Position(4)/2;
hfig=findobj(allchild(0),'Tag','set_movie');
if ~isempty(hfig),delete(hfig), end %delete existing version of the GUI
hfig=figure('name','set_movie','tag','set_movie','MenuBar','none','NumberTitle','off','Units','pixels',...
    'Position',Position);
BackgroundColor=get(hfig,'Color');
hh=0.14; % box height (relative)
% first raw of the GUI
uicontrol('Style','text','Units','normalized', 'Position', [0.05 0.95-hh/2 0.9 hh/2],'BackgroundColor',BackgroundColor,...
    'String','movie name:','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','edit','Units','normalized', 'Position', [0.05 0.95-1.5*hh 0.9 hh],'tag','MovieName','BackgroundColor',[1 1 1],...
    'String',fullfile(RootPath,[SubDir '.movie'], [RootFile '.avi']),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''MovieName'': name (with path) of the movie to create');%edit box
uicontrol('Style','text','Units','normalized', 'Position', [0.05 0.95-2.5*hh 0.33 hh/2],'BackgroundColor',BackgroundColor,...
    'String','frames per second:','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','text','Units','normalized', 'Position', [0.3 0.95-2.5*hh 0.33 hh/2],'BackgroundColor',BackgroundColor,...
    'String','resolution:','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','text','Units','normalized', 'Position', [0.55 0.95-2.5*hh 0.33 hh/2],'BackgroundColor',BackgroundColor,...
    'String','total nbre of frames:','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','edit','Units','normalized', 'Position', [0.05 0.95-3.5*hh 0.3 hh],'tag','num_FramePerSecond','BackgroundColor',[1 1 1],...
    'String','10','FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_FramePerSecond'': nbre of frames per second');%edit box

uicontrol('Style','listbox','Units','normalized', 'Position', [0.35 0.15 0.3 3*hh],'tag','MovieSize','BackgroundColor',[1 1 1],...
    'Callback',@(hObject,eventdata)set_movie_size_Callback(hObject,eventdata),'String',{'640x480(VGA)';'720x480(mpeg2 16/9)';'1280x720(HD)'},...
    'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''MovieSize'': resolution of the movie');%menu

uicontrol('Style','edit','Units','normalized', 'Position', [0.65 0.95-3.5*hh 0.3 hh],'tag','num_FrameNumber','BackgroundColor',[1 1 1],...
    'String','10','FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_FrameNumber'': total nbre of frames');%edit box

uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.05 0.15 0.25 hh],'BackgroundColor',[1 0 0],'String','START','Callback',@(hObject,eventdata)set_movie_START_Callback(hObject,eventdata),...
    'FontWeight','bold','FontUnits','points','FontSize',12,'TooltipString','''APPLY'': apply the output to the current field series in uvmat');
uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.7 0.15 0.25 hh],'Callback',@(hObject,eventdata)set_movie_Cancel_Callback(hObject,eventdata),...
    'String','Cancel','FontWeight','bold','FontUnits','points','FontSize',12,'TooltipString','''Cancel'': quit GUI without action');
uicontrol('Style','text','Units','normalized', 'Position', [0.05 0.05 0.9 hh/2],'BackgroundColor',BackgroundColor,...
    'String','will extract the result of ++> on uvmat: adjust figure_movie with its Matlab edit menu, then press ''START ''','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
drawnow

%------------------------------------------------------------------------
% function called by selecting movie size in the GUI  set_movie
function set_movie_size_Callback(hObject,eventdata)
hset_movie=get(hObject,'parent');
hMovieSize=findobj(hset_movie,'Tag','MovieSize');
nbpix=[640 480; 720 480; 1280 720];
SizeOption=get(hMovieSize,'Value');
nbpix=nbpix(SizeOption,:);

%% look for movie fig
figure_movie=findobj(allchild(0),'name','figure_movie');
if isempty(figure_movie)
    figure_movie=figure;
    set(figure_movie,'name','figure_movie','Position',[1 1 nbpix])
    huvmat=findobj(allchild(0),'tag','uvmat');
    hhuvmat=guidata(huvmat);
    newaxes=copyobj(hhuvmat.PlotAxes,figure_movie);%new plotting axes in the new figure
    set(newaxes,'Tag','movieaxes')

    %% display time if defined in uvmat
    time_str=get(hhuvmat.TimeValue,'String');
    if ~isempty(time_str)
        htitle=get(newaxes,'Title');
        set(htitle,'String',['t=' time_str])
    end
    map=colormap(handles.PlotAxes);
    colormap(map);%transmit the current colormap to the zoom fig
    colorbar
else
    Pos=get(figure_movie,'Position');
    set(figure_movie,'Position',[Pos(1) Pos(2) nbpix])
end


%------------------------------------------------------------------------
% function called by pressing APPLY in the GUI  set_movie
function set_movie_START_Callback(hObject,eventdata)
%------------------------------------------------------------------------
%% read info from the GUI set_movie
hset_movie=get(hObject,'parent');
hMovieName=findobj(hset_movie,'Tag','MovieName');
MovieName=get(hMovieName,'String');
hFramePerSecond=findobj(hset_movie,'Tag','num_FramePerSecond');
fps=str2double(get(hFramePerSecond,'String'));
hFrameNumber=findobj(hset_movie,'Tag','num_FrameNumber');
FrameNumber=str2double(get(hFrameNumber,'String'));% total nbre of frames

%% create the movie file
MovieDir=fileparts(MovieName);
if ~exist(MovieDir,'dir')
    [success,message]=mkdir(MovieDir);
    if ~isequal(success,1)
        msgbox_uvmat('ERROR',message)
        return
    end
    [success,message] = fileattrib(MovieDir,'+w','g','s');% allow writing access for the group of users, recursively in the folder
    if success==0
        msgbox_uvmat('WARNING',{['unable to set group write access to ' MovieDir ':']; message});%error message for directory creation
    end
end
if exist(MovieName,'file')
    backup=MovieName;
    testexist=2;
    while testexist==2
        backup=[backup '~'];
        testexist=exist(backup,'file');
    end
    [success,message]=copyfile(MovieName,backup);%make backup of the existing file
    if isequal(success,1)
        delete(MovieName)%delete existing file
    else
        msgbox_uvmat('ERROR',message)
        return
    end
end

%% create movie
% duration = 2*FrameNumber/60;
% [~,name,~] = fileparts(MovieName);
% ffmpegcmd = ['ffmpeg -i ' ' ' MovieName ' ' '-filter:v "setpts=(',...
%      num2str(fps/duration),')*PTS"' ' ' strcat(MovieDir,...
%      strcat('/',name,'.mkv'))];
% [ffmpeg_err,~] = system(ffmpegcmd);
% if ffmpeg_err
%     disp_uvmat('ERROR',['ERROR: Errors in conversion to mkv, close MATLAB and run "LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 matlab" in terminal'],1 )
%     return
% end
% msgbox_uvmat('CONFIRMATION',{['movie ' MovieName ' created '];['with ' num2str(FrameNumber) ' frames']})


% 
aviobj = VideoWriter(MovieName,'Motion JPEG AVI');
open(aviobj)
%% get info from uvmat and adjust it
huvmat=findobj(allchild(0),'Tag','uvmat');
hhuvmat=guidata(huvmat);
increment=str2num(get(hhuvmat.num_IndexIncrement,'String')); %get the field increment from uvmat
set(hhuvmat.STOP,'Visible','on')
set(hhuvmat.speed,'Visible','on')
set(hhuvmat.speed_txt,'Visible','on')
set(hhuvmat.Movie,'BusyAction','queue')
set(hhuvmat.speed,'Value',1)
figure_movie=findobj(allchild(0),'name','figure_movie');
hhuvmat.PlotAxes=findobj(figure_movie,'Tag','movieaxes');% the axis in the new figure becomes the current main plotting axes
for i=1:FrameNumber
    if get(hhuvmat.speed,'Value')~=0 && isequal(get(hhuvmat.MenuExportMovie,'BusyAction'),'queue') % enable STOP command
            runpm(hObject,eventdata,hhuvmat,increment)% run plus
            drawnow
            time_str=get(hhuvmat.TimeValue,'String');
            htitle=get(hhuvmat.PlotAxes,'Title');
            Title=get(htitle,'String');
            set(htitle,'String',regexprep(Title,'t=\d+.\d*',['t=' time_str]))
            mov=getframe(figure_movie);
            writeVideo(aviobj,mov);
    end
end
close(aviobj);
msgbox_uvmat('CONFIRMATION',{['movie ' MovieName ' created '];['with ' num2str(FrameNumber) ' frames']})

%------------------------------------------------------------------------
% function called by pressing APPLY in the GUI  set_slices
function set_movie_Cancel_Callback(hObject,eventdata)
%------------------------------------------------------------------------
delete(hObject)

% --------------------------------------------------------------------
function MenuExportCustom_Callback(hObject, eventdata, handles)
export_fct_name=get(handles.MenuExportCustom,'label');
if strcmp(export_fct_name,'user export fct.')
    MenuExportMore_Callback(hObject, eventdata, handles)
else
    current_dir=pwd;%current working dir
    cd(fullfile(fileparts(which('uvmat')),'export_fct'))
    export_handle=str2func(export_fct_name);
    cd(current_dir)
    export_handle(handles)
end
        
% --------------------------------------------------------------------
function MenuExportMore_Callback(hObject, eventdata, handles)

prev_path=fullfile(fileparts(which('uvmat')),'export_fct');
transform_fct_chosen=uigetfile_uvmat('Pick the export function',prev_path,'.m');
if ~isempty(transform_fct_chosen)
    [PathName,transform_name]=fileparts(transform_fct_chosen);
    set(handles.MenuExportCustom,'label',transform_name)
    set(handles.MenuExportCustom,'checked','on')
    MenuExportCustom_Callback(hObject, eventdata, handles)
end

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
% --- Callback of the Menu command line
%------------------------------------------------------------------------
function Menuline_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Type='line';
data.ProjMode='projection';%default
data.ProjModeMenu={};% do not restrict ProjMode menus
create_object(data,handles)

% -----------------------------------------------------------------------
% --- Callback of the Menu command line_x
%------------------------------------------------------------------------
function Menuline_x_Callback(hObject, eventdata, handles)

data.Type='line_x';
data.ProjMode='projection';%default
data.ProjModeMenu={};% do not restrict ProjMode menus
create_object(data,handles)

% -----------------------------------------------------------------------
% --- Callback of the Menu command line_y
% -----------------------------------------------------------------------
function Menuline_y_Callback(hObject, eventdata, handles)

data.Type='line_y';
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

% --------------------------------------------------------------------
function Menuplane_z_Callback(hObject, eventdata, handles)
data.Type='plane_z';
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
%% desactivate concurrent tools
set(handles.MenuRuler,'checked','off')%desactivate ruler
hgeometry_calib=findobj(allchild(0),'tag','geometry_calib');% search the GUI geometric calibration
if ishandle(hgeometry_calib)
    hhgeometry_calib=guidata(hgeometry_calib);
    set(hhgeometry_calib.CheckEnableMouse,'Value',0)% desactivate mouse action in geometry_calib
    set(hhgeometry_calib.CheckEnableMouse,'BackgroundColor',[0.7 0.7 0.7])
end
set(handles.CheckEditObject,'Value',0)  %desactivate the object edit mode
CheckEditObject_Callback([],[],handles)
set(handles.CheckViewObject,'Value',0) % desactivate view_object (new object created)
set(handles.CheckZoomFig,'Value',0) %desactivate zoom sub fig
set(handles.CheckZoom,'Value',0)    %desactivate the zoom action
set(handles.MenuObject,'checked','on')% indicate object creation for mouse pointer display
if ishandle(handles.UVMAT_title)
    delete(handles.UVMAT_title)     %delete the initial display of uvmat if no field has been entered yet
end

%% initiate the new projection object
UvData=get(handles.uvmat,'UserData');
data.Name=data.Type;% default name=type
data.Coord=[0 0]; %default
check_plot=0;
if isfield(UvData,'Field')
    if isfield(UvData.Field,'NbDim')&& isequal(UvData.Field.NbDim,3)
         data.Coord=[0 0 0]; %default
    end
    if isfield(UvData.Field,'CoordUnit')
        data.CoordUnit=UvData.Field.CoordUnit;
    end
    if isfield(UvData.Field,'CoordMesh')&&~isempty(UvData.Field.CoordMesh)
        %data.RangeX=[UvData.Field.XMin UvData.Field.XMax];
        data.DX=UvData.Field.CoordMesh;
        data.DY=UvData.Field.CoordMesh;
        switch data.Type
            case {'line','polyline','points'}
                data.RangeY=UvData.Field.CoordMesh;
                data.RangeInterp=3*UvData.Field.CoordMesh;
            case 'line_x'
                check_plot=1; %plot the line directly when set_object is opened
                data.Type='line';
                data.RangeX=UvData.Field.XMin ;
                data.RangeY=UvData.Field.CoordMesh;
                data.RangeInterp=3*UvData.Field.CoordMesh;
                if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
                    Coord_z=(UvData.Field.ZMin +UvData.Field.ZMax)/2;
                else
                    Coord_z=0;
                end
                data.Coord=[UvData.Field.XMin (UvData.Field.YMin +UvData.Field.YMax)/2 Coord_z;...
                           UvData.Field.XMax (UvData.Field.YMin +UvData.Field.YMax)/2 Coord_z];% put line at the middle of the y axis
            case 'line_y'
                check_plot=1; %plot the line directly when set_object is opened
                data.Type='line';
                data.RangeX=UvData.Field.YMin ;
                data.RangeY=UvData.Field.CoordMesh;
                data.RangeInterp=3*UvData.Field.CoordMesh;
                if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
                    Coord_z=(UvData.Field.ZMin +UvData.Field.ZMax)/2;
                else
                    Coord_z=0;
                end
                data.Coord=[(UvData.Field.XMin+UvData.Field.XMax)/2 UvData.Field.YMin Coord_z;...
                            (UvData.Field.XMin +UvData.Field.XMax)/2 UvData.Field.YMax Coord_z];% put line at the middle of the y axis
            case {'rectangle','ellipse'}
                data.RangeY=[UvData.Field.YMin UvData.Field.YMax];
                data.RangeX=UvData.Field.CoordMesh;
                data.RangeY=UvData.Field.CoordMesh;
            case 'plane_z'
                data.Type='plane';
                if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
                    data.RangeY=[UvData.Field.ZMin UvData.Field.ZMax];
                else
                    msgbox_uvmat('ERROR','The input field is not 3D: no vertical plane projection')
                    return
                end
                data.Angle=[90 0 0];
                data.DX=UvData.Field.CoordMesh;
                data.DY=UvData.Field.CoordMesh;
                data.RangeZ=UvData.Field.CoordMesh;      
                data.Coord=[];
            otherwise
                data.RangeX=[UvData.Field.XMin UvData.Field.XMax];
                data.RangeY=[UvData.Field.YMin UvData.Field.YMax];
        end
    end
    if isfield(UvData.Field,'ProjModeRequest')
        data.ProjMode=UvData.Field.ProjModeRequest;%set the request proj mode option by default
    end
end
hset_object=findobj(allchild(0),'Tag','set_object');
if ~isempty(hset_object)
    delete(hset_object)%delete existing GUI set_object
end
hset_object=set_object(data,handles);% call the GUI set_object
hchild=get(hset_object,'children');
set(hchild,'enable','on')
set(handles.DeleteObject,'Visible','on')% make the object delete button visible
if check_plot
    hhset_object=guidata(hset_object);
    set_object('REFRESH_Callback',1,[],hhset_object);% call the GUI set_object
end
set(handles.CheckViewField,'Visible','on')
set(handles.DeleteObject,'Visible','on')
set(handles.ListObject_1,'Visible','on')
set(handles.ListObject_1_title,'Visible','on')

%------------------------------------------------------------------------
function MenuBrowseObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%get the object file
fileinput=uigetfile_uvmat('pick an xml object file:',get(handles.RootPath,'String'),'.xml');
if ~isempty(fileinput)
    %read the file
    [data,heading]=xml2struct(fileinput);
    if ~strcmp(heading,'ProjObject')
        msgbox_uvmat('WARNING','The xml file does not have the heading ProjObject for projection objects')
    end
    ListObject=get(handles.ListObject,'String');
    ListObject=[ListObject;{data.Name}];
    IndexObj=length(ListObject);
    UvData=get(handles.uvmat,'UserData');
    UvData.ProjObject{IndexObj}=[]; %create a new empty object
    UvData.ProjObject{IndexObj}.DisplayHandle.uvmat=[]; %no plot handle before plot_field operation
    UvData.ProjObject{IndexObj}.DisplayHandle.view_field=[]; %no plot handle before plot_field operation
    set(handles.uvmat,'UserData',UvData)
    set(handles.CheckViewObject,'Value',1)
    set(handles.CheckViewField,'Value',1)
    hset_object=set_object(data);% call the set_object interface
    hhset_object=guidata(hset_object);
    set_object('REFRESH_Callback',hObject,eventdata,hhset_object);% plot projection
    set(handles.CheckEditObject,'Value',0); %suppress the object edit mode
    CheckEditObject_Callback([],[],handles)
    set(handles.DeleteObject,'Visible','on')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MenuTools Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
function MenuCalib_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%% suppress the second field if exists
if get(handles.SubField,'Value')
    set(handles.SubField,'Value',0)
    SubField_Callback(hObject, eventdata, handles)
end
UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface

%% suppress competing tools
set(handles.MenuRuler,'checked','off')%desactivate ruler
set(handles.CheckZoom,'Value',0)
set(handles.CheckZoom,'BackgroundColor',[0.7 0.7 0.7])
set(handles.ListObject,'Value',1)

%% initiate display of the GUI geometry_calib
data=[]; %default
if isfield(UvData,'CoordType')
    data.CoordType=UvData.CoordType;
end
[RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
FileName=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];
set(handles.view_xml,'BackgroundColor',[1 1 0])%indicate the reading of the current xml file by geometry_calib
geometry_calib(FileName);% call the geometry_calib interface
set(handles.view_xml,'BackgroundColor',[1 1 1])%indicate the end of reading of the current xml file by geometry_calib
set(handles.MenuCalib,'checked','on')% indicate that MenuCalib is activated, test used by mouse action


% --------------------------------------------------------------------
% --- set the slice plane ro the set of slice planes when volume scan is used
function MenuSetSlice_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
%% suppress the second input field if exists
if get(handles.SubField,'Value')
    set(handles.SubField,'Value',0)
    SubField_Callback(hObject, eventdata, handles)
end

UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface
% check=0;
if isfield(UvData,'XmlData')&&isfield(UvData.XmlData{1},'GeometryCalib')&& isfield(UvData.XmlData{1}.GeometryCalib,'SliceCoord')
    GeometryCalib=UvData.XmlData{1}.GeometryCalib;
else
    msgbox_uvmat('ERROR','3D geometric calibration needed before defining slices')
    return
end
SliceCoord=GeometryCalib.SliceCoord;
InterfaceCoord=min(SliceCoord(:,3));
if isfield(GeometryCalib,'InterfaceCoord')
    InterfaceCoord=GeometryCalib.InterfaceCoord(1,3);
end
NbSlice=size(SliceCoord,1);
CheckVolumeScan=0;
if isfield(GeometryCalib,'CheckVolumeScan')
    CheckVolumeScan=GeometryCalib.CheckVolumeScan;
end
RefractionIndex=1.33;
CheckRefraction=0;% default value of the check box refraction
if isfield(GeometryCalib,'RefractionIndex')
    RefractionIndex=GeometryCalib.RefractionIndex;
    CheckRefraction=1;
end
SliceAngle=[0 0 0];
if isfield(GeometryCalib,'SliceAngle')
    SliceAngle=GeometryCalib.SliceAngle;
end

%% create the GUI set_slice
set(0,'Units','points')
ScreenSize=get(0,'ScreenSize');% get the size of the screen, to put the fig on the upper right
Width=350;% fig width in points (1/72 inch)
Height=min(0.8*ScreenSize(4),300);
Left=ScreenSize(3)- Width-40; %right edge close to the right, with margin=40
Bottom=ScreenSize(4)-Height-40; %put fig at top right
hfig=findobj(allchild(0),'Tag','set_slice');
if ~isempty(hfig),delete(hfig), end; %delete existing version of the GUI
hfig=figure('name','set_slices','tag','set_slice','MenuBar','none','NumberTitle','off','Units','pixels','Position',[Left,Bottom,Width,Height],'UserData',GeometryCalib);
BackgroundColor=get(hfig,'Color');
hh=0.14; % box height (relative)
ii=0.01; % gap between uicontrols

ww=(1-5*ii)/4; % box width (relative)
% first raw of the GUI
uicontrol('Style','text','Units','normalized', 'Position', [2*ii+ww 0.95-ii-0.25*hh ww hh/2],'BackgroundColor',BackgroundColor,...
    'String','first','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','text','Units','normalized', 'Position', [3*ii+2*ww 0.95-ii-0.25*hh ww hh/2],'BackgroundColor',BackgroundColor,...
    'String','last','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','text','Units','normalized', 'Position', [4*ii+3*ww 0.95-ii-0.25*hh ww hh/2],'BackgroundColor',BackgroundColor,...
    'String','surface','Visible','off','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
%  raw 2 of the GUI
uicontrol('Style','text','Units','normalized', 'Position', [ii 0.95-2*ii-0.75*hh ww hh/2],'BackgroundColor',BackgroundColor,...
    'String','Z','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','right');%title
uicontrol('Style','edit','Units','normalized', 'Position', [2*ii+ww 0.95-2*ii-hh ww hh],'tag','num_Z_1','BackgroundColor',[1 1 1],...
    'String',num2str(SliceCoord(1,3)),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_Z_1'': z position of first slice');%edit box
uicontrol('Style','edit','Units','normalized', 'Position', [3*ii+2*ww 0.95-2*ii-hh ww hh],'tag','num_Z_2','BackgroundColor',[1 1 1],...
    'String',num2str(SliceCoord(end,3)),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_Z_2'': z position of last slice');%edit box
uicontrol('Style','edit','Units','normalized', 'Position', [4*ii+3*ww 0.95-2*ii-hh ww hh],'tag','num_H','BackgroundColor',[1 1 1],...
    'String',num2str(InterfaceCoord),'Visible','off','FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_H'': z position of the water surface (=Z_1 in air)');%edit box
%  raw 3 of the GUI
hcheckrefraction=uicontrol('Style','checkbox','Units','normalized', 'Position', [2*ii+ww 0.95-3*ii-2*hh 2*ww hh],'tag','CheckRefraction','BackgroundColor',BackgroundColor,...
    'Callback',@(hObject,eventdata)set_slice_CheckRefraction_Callback(hObject,eventdata),...
    'String','refraction','Value',CheckRefraction,'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''CheckRefraction'':=1 to provide refraction correction');
uicontrol('Style','text','Units','normalized', 'Position', [2*ii+2*ww 0.95-3*ii-1.7*hh ww hh/2],'BackgroundColor',BackgroundColor,'Tag','Refraction_title',...
    'String','index','Visible','off','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','right');%title
uicontrol('Style','edit','Units','normalized', 'Position', [4*ii+3*ww 0.95-3*ii-2*hh ww hh],'tag','num_RefractionIndex','BackgroundColor',[1 1 1],...
    'String',num2str(RefractionIndex),'Visible','off','FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_RefractionIndex'': refraction index of water');
%  raw 4 of the GUI
uicontrol('Style','text','Units','normalized', 'Position', [ii 0.95-4*ii-3.0*hh ww hh],'BackgroundColor',BackgroundColor,'Tag','NbSlice_title',...
    'String','NbSlice','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','right');%title
uicontrol('Style','edit','Units','normalized', 'Position', [2*ii+ww 0.95-4*ii-2.8*hh ww hh],'tag','num_NbSlice','BackgroundColor',[1 1 1],...
    'String',num2str(NbSlice),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_NbSlice'':number of slices');%edit box
uicontrol('Style','checkbox','Units','normalized', 'Position', [3*ii+2*ww 0.95-4*ii-2.7*hh 2*ww hh],'tag','CheckVolumeScan','BackgroundColor',BackgroundColor,...
    'String','volume scan','Value',CheckVolumeScan,'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''CheckVolumeScan'':=1 for volume scan (z varies with j index)');
%  raw 5 of the GUI
uicontrol('Style','text','Units','normalized', 'Position', [2*ii+1*ww 0.95-2*ii-3.9*hh ww hh],'BackgroundColor',BackgroundColor,...
    'String','origin','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','text','Units','normalized', 'Position', [2*ii+2*ww 0.95-2*ii-3.5*hh ww hh],'BackgroundColor',BackgroundColor,...
    'String',{'first';'angle'},'FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','text','Units','normalized', 'Position', [3*ii+3*ww 0.95-2*ii-3.5*hh ww hh],'BackgroundColor',BackgroundColor,...
    'String',{'last';'angle'},'FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title

uicontrol('Style','edit','Units','normalized', 'Position', [3*ii+ww 0.95-5*ii-4.2*hh ww hh],'tag','num_SliceCoord_1','BackgroundColor',[1 1 1],...
    'String',num2str(SliceCoord(1)),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_SliceCoord_1'':x position of the tild origin');%edit box
uicontrol('Style','edit','Units','normalized', 'Position', [3*ii+ww 0.95-6*ii-5.2*hh ww hh],'tag','num_SliceCoord_2','BackgroundColor',[1 1 1],...
    'String',num2str(SliceCoord(2)),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_SliceCoord_2'':y position of the tild origin');%edit box

uicontrol('Style','text','Units','normalized', 'Position', [ii 0.95-5*ii-4*hh 1.3*ww hh/2],'BackgroundColor',BackgroundColor,'Tag','Angle_title_1',...
    'String','tild x axis','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
uicontrol('Style','text','Units','normalized', 'Position', [ii 0.95-6*ii-5*hh 1.3*ww hh/2],'BackgroundColor',BackgroundColor,'Tag','Angle_title_2',...
    'String','tild y axis','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','center');%title
%  raw 6 of the GUI
uicontrol('Style','edit','Units','normalized', 'Position', [3*ii+2*ww 0.95-5*ii-4.2*hh ww hh],'tag','num_SliceAngle_1_1','BackgroundColor',[1 1 1],...
    'String',num2str(SliceAngle(1,1)),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_SliceAngle_1_1'':first slice angle of inclination around the x axis');%edit box
uicontrol('Style','edit','Units','normalized', 'Position', [4*ii+3*ww 0.95-5*ii-4.2*hh ww hh],'tag','num_SliceAngle_1_2','BackgroundColor',[1 1 1],...
    'String',num2str(SliceAngle(end,1)),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_SliceAngle_1_2'':last slice angle of inclination around the x axis');%edit box
uicontrol('Style','edit','Units','normalized', 'Position', [3*ii+2*ww 0.95-6*ii-5.2*hh ww hh],'tag','num_SliceAngle_2_1','BackgroundColor',[1 1 1],...
    'String',num2str(SliceAngle(1,2)),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_SliceAngle_2_1'':first slice angle of inclination around the y axis');%edit box
uicontrol('Style','edit','Units','normalized', 'Position', [4*ii+3*ww 0.95-6*ii-5.2*hh ww hh],'tag','num_SliceAngle_2_2','BackgroundColor',[1 1 1],...
    'String',num2str(SliceAngle(end,2)),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_SliceAngle_2_2'':last slice angle of inclination around the y axis');%edit box

%  raw 7 of the GUI: pushbuttons
wwp=(1-4*ii)/3; %width of the push buttons
uicontrol('Style','pushbutton','Units','normalized', 'Position', [ii ii wwp hh],'BackgroundColor',[1 0 0],'String','APPLY','Callback',@(hObject,eventdata)set_slice_APPLY_Callback(hObject,eventdata),...
    'FontWeight','bold','FontUnits','points','FontSize',12,'TooltipString','''APPLY'': apply the output to the current field series in uvmat');
uicontrol('Style','checkbox','Units','normalized', 'Position', [2*ii+wwp ii wwp hh],'tag','CheckReplicate','BackgroundColor',[1 0 0],'String','Replicate','Callback',@(hObject,eventdata)set_slice_REPLICATE_Callback(hObject,eventdata),...
    'FontWeight','bold','FontUnits','points','FontSize',12,'TooltipString','''CheckReplicate'': select to replicate the output of APPLY to a series of experiments');
uicontrol('Style','pushbutton','Units','normalized', 'Position', [3*ii+2*wwp ii wwp hh],'Callback',@(hObject,eventdata)set_slice_Cancel_Callback(hObject,eventdata),...
    'String','Cancel','FontWeight','bold','FontUnits','points','FontSize',12,'TooltipString','''Cancel'': quit GUI without action');
drawnow
set_slice_CheckRefraction_Callback(hcheckrefraction,[])

%------------------------------------------------------------------------
% function called by selecting CheckRefraction in the GUI set_slices
function set_slice_CheckRefraction_Callback(hObject,eventdata)
%------------------------------------------------------------------------
hset_slice=get(hObject,'parent');
h_refraction(1)=findobj(hset_slice,'String','surface');
h_refraction(2)=findobj(hset_slice,'Tag','num_H');
h_refraction(3)=findobj(hset_slice,'String','index');
h_refraction(4)=findobj(hset_slice,'Tag','num_RefractionIndex');
if isequal(get(hObject,'Value'),1)
    set(h_refraction,'Visible','on')
else
    set(h_refraction,'Visible','off')
end

%------------------------------------------------------------------------
% function called by pressing APPLY in the GUI  set_slices
function set_slice_APPLY_Callback(hObject,eventdata)
%------------------------------------------------------------------------
set(hObject,'BackgroundColor',[1 1 0]);% paint button in yellow to indicate action
drawnow

%% get the uvmat GUI data and read the current xml file
huvmat=findobj(allchild(0),'Tag','uvmat');
hhuvmat=guidata(huvmat);
[RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(hhuvmat);
FileName=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];%name of the current input file
[RootPath,SubDir,RootFile,tild,tild,tild,tild,FileExt]=fileparts_uvmat(FileName);
XmlFile=find_imadoc(RootPath,SubDir,RootFile,FileExt);%find name of the relevant xml file
[s,errormsg]=imadoc2struct(XmlFile,'GeometryCalib');%read the xml file
if~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    return
end
GeometryCalib=s.GeometryCalib;% get thegeometric calibration data

%% read the content of the GUI set_slice
hset_slice=get(hObject, 'parent');
hZ=findobj(hset_slice,'Tag','num_Z_1');
Z_plane=str2num(get(hZ,'String'));% set of Z positions explicitly entered as a Matlab vector
SliceData=read_GUI(hset_slice);
GeometryCalib.NbSlice=SliceData.NbSlice;
GeometryCalib.CheckVolumeScan=SliceData.CheckVolumeScan;
if numel(Z_plane)<=2
    Z_plane=linspace(SliceData.Z(1),SliceData.Z(2),SliceData.NbSlice);
else
    set(hZ,'String',num2str(Z_plane))% restitute the display qfter reqding by read_GUI
end
GeometryCalib.SliceCoord=Z_plane'*[0 0 1];
GeometryCalib.SliceCoord(:,1)=SliceData.SliceCoord(1);
GeometryCalib.SliceCoord(:,2)=SliceData.SliceCoord(2);
GeometryCalib.SliceAngle=zeros(GeometryCalib.NbSlice,3);
Angle_1=linspace(SliceData.SliceAngle_1(1),SliceData.SliceAngle_1(2),SliceData.NbSlice);
Angle_2=linspace(SliceData.SliceAngle_2(1),SliceData.SliceAngle_2(2),SliceData.NbSlice);
GeometryCalib.SliceAngle(:,1)=Angle_1';%rotation angle around x axis 
GeometryCalib.SliceAngle(:,2)=Angle_2';%rotation angle around y axis 
GeometryCalib.SliceAngle(:,3)=0;
if SliceData.CheckRefraction
    GeometryCalib.InterfaceCoord=[0 0 SliceData.H];
    GeometryCalib.RefractionIndex=SliceData.RefractionIndex;
elseif isfield(GeometryCalib,'RefractionIndex')
    GeometryCalib=rmfield(GeometryCalib,'RefractionIndex');
    GeometryCalib=rmfield(GeometryCalib,'InterfaceCoord');
end

hreplicate=findobj(hset_slice,'Tag','CheckReplicate');
if get(hreplicate,'Value')
    %% open the GUI browse_data
    hbrowse=findobj(allchild(0),'Tag','browse_data');
    if ~isempty(hbrowse)% look for the GUI browse_data
        BrowseData=guidata(hbrowse);
        SourceDir=get(BrowseData.SourceDir,'String');
        ListExp=get(BrowseData.ListExperiments,'String');
        ExpIndices=get(BrowseData.ListExperiments,'Value');
        ListExp=ListExp(ExpIndices);
        ListDevices=get(BrowseData.ListDevices,'String');
        DeviceIndices=get(BrowseData.ListDevices,'Value');
        ListDevices=ListDevices(DeviceIndices);
        ListDataSeries=get(BrowseData.DataSeries,'String');
        DataSeriesIndices=get(BrowseData.DataSeries,'Value');
        ListDataSeries=ListDataSeries(DataSeriesIndices);
        NbExp=0; % counter of the number of experiments set by the GUI browse_data
        for iexp=1:numel(ListExp)
            if ~isempty(regexp(ListExp{iexp},'^\+/'))% if it is a folder
                for idevice=1:numel(ListDevices)
                    if ~isempty(regexp(ListDevices{idevice},'^\+/'))% if it is a folder
                        for isubdir=1:numel(ListDataSeries)
                            if ~isempty(regexp(ListDataSeries{isubdir},'^\+/'))% if it is a folder
                                lpath= fullfile(SourceDir,regexprep(ListExp{iexp},'^\+/',''),...
                                    regexprep(ListDevices{idevice},'^\+/',''));
                                ldir= regexprep(ListDataSeries{isubdir},'^\+/','');
                                if exist(fullfile(lpath,ldir),'dir')
                                    NbExp=NbExp+1;
                                    ListPath{NbExp}=lpath;
                                    ListSubdir{NbExp}=ldir;
                                    ExpIndex{NbExp}=iexp;
                                end
                            end
                        end
                    end
                end
            end
        end
        for iexp=1:NbExp
            XmlName=fullfile(ListPath{iexp},[ListSubdir{iexp} '.xml']);
            if exist(XmlName,'file')
                check_update=1;
            else
                check_update=0;
            end
            errormsg=update_imadoc(GeometryCalib,XmlName,'GeometryCalib');% introduce the calibration data in the xml file
            if ~strcmp(errormsg,'')
                msgbox_uvmat('ERROR',errormsg);
            else
                if check_update
                    display([XmlName ' updated with slice positions'])
                else
                    display([XmlName ' created with slice positions'])
                end
            end
        end
    end
    msgbox_uvmat('CONFIMATION',['slices replicated for ' num2str(NbExp) ' experiments']);
else
    
    %% store the result in the xml file used for calibration
    errormsg=update_imadoc(GeometryCalib,XmlFile,'GeometryCalib');% introduce the calibration data in the xml file
    if strcmp(errormsg,'')
        msgbox_uvmat('CONFIRMATION',['slice positions saved in ' XmlFile]);
    else
        msgbox_uvmat('ERROR',errormsg);
    end
    
    %% display image with new calibration in the currently opened uvmat interface
    %set(hhuvmat.CheckFixLimits,'Value',0)% put FixedLimits option to 'off' to plot the whole image
    uvmat('InputFileREFRESH_Callback',huvmat,[],hhuvmat); %file input with xml reading  in uvmat, show the image in phys coordinates
    set(hObject,'BackgroundColor',[1 0 0]);% paint button back to red
end

delete(hset_slice)

%------------------------------------------------------------------------
% function called by pressing REPLICATE in the GUI  set_slices
function set_slice_REPLICATE_Callback(hObject,eventdata)
%------------------------------------------------------------------------
if get(hObject,'Value') %open the GUI browse_data
    % look for the GUI uvmat and check for an image as input
    huvmat=findobj(allchild(0),'Name','uvmat');
    hhuvmat=guidata(huvmat);%handles of elements in the GUI uvmat
    RootPath=get(hhuvmat.RootPath,'String');
    SubDir=get(hhuvmat.SubDir,'String');
    browse_data(fullfile(RootPath,SubDir))
else
    hbrowse=findobj(allchild(0),'Tag','browse_data');
    if ~isempty(hbrowse)
        delete(hbrowse)
    end
end


%------------------------------------------------------------------------
% function called by pressing Cancel in the GUI  set_slices
function set_slice_Cancel_Callback(hObject,eventdata)
%------------------------------------------------------------------------
hset_slice=get(hObject,'parent');
delete(hset_slice)

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

%% read the lines previously used for LIF calibration if available, and display them
ListObjectName=get(handles.ListObject,'String');
if isfield(XmlData,'LIFCalib')
    if isfield(XmlData.LIFCalib,'Ray1Coord') && isfield(XmlData.LIFCalib,'Ray2Coord') && isfield(XmlData.LIFCalib,'RefLineCoord')
        ListObjectName(1:4)={'plane';'Ray1';'Ray2';'RefLine'};
        data.Name='Ray1';
        data.Type='line';
        data.ProjMode='none';%default
        data.Coord=XmlData.LIFCalib.Ray1Coord;
        UvData.ProjObject{2}=data;
        UvData.ProjObject{2}.DisplayHandle.uvmat=plot_object(UvData.ProjObject{2},UvData.ProjObject{1},handles.PlotAxes,'b');
        data.Name='Ray2';
        data.Coord=XmlData.LIFCalib.Ray2Coord;
        UvData.ProjObject{3}=data;
        UvData.ProjObject{3}.DisplayHandle.uvmat=plot_object(UvData.ProjObject{3},UvData.ProjObject{1},handles.PlotAxes,'b');
        data.Name='RefLine';
        data.Coord=XmlData.LIFCalib.RefLineCoord;
        UvData.ProjObject{4}=data;
        UvData.ProjObject{4}.DisplayHandle.uvmat=plot_object(UvData.ProjObject{4},UvData.ProjObject{1},handles.PlotAxes,'b');
    end
    if isfield(XmlData.LIFCalib,'MaskPolygonCoord')
        ListObjectName{5}='MaskPolygon';
        data.Name='MaskPolygon';
        data.Type='polygon';
        data.ProjMode='mask_outside';
        data.Coord=XmlData.LIFCalib.MaskPolygonCoord;
        UvData.ProjObject{5}=data;
        UvData.ProjObject{5}.DisplayHandle.uvmat=plot_object(UvData.ProjObject{5},UvData.ProjObject{1},handles.PlotAxes,'b');
    end
    set(handles.ListObject,'String',ListObjectName)
    set(handles.ListObject,'Value',1)
    set(handles.uvmat,'UserData',UvData);
    answer=msgbox_uvmat('INPUT_Y-N', 'keep calibration lines');  
    if ~strcmp(answer,'Yes')
        return
    end
end
%% read lines currently drawn
ListObj=UvData.ProjObject;% get the current list of projection objects 
select_line=zeros(1,numel(ListObj));
select_mask=zeros(1,numel(ListObj));
for iobj=1:numel(ListObj)
    if isfield(ListObj{iobj},'Type') && strcmp(ListObj{iobj}.Type,'line')
        select_line(iobj)=1;% select the lines among the projection objects
    end
    if isfield(ListObj{iobj},'Type') && strcmp(ListObj{iobj}.Type,'polygon')
        select_mask(iobj)=1;% select the mask among the projection objects
    end
end
if numel(find(select_line))<2
    msgbox_uvmat('ERROR',{'lines must be defined by Projection object in the upper menu bar: ';'1-two lines following the illumination rays'; ...
    '2-a reference line near the fluid boundary receiving the illumination beam';'a mask polygon to select the area in which the exponential decay is fitted'});
    return
else
    LineData=UvData.ProjObject(find(select_line));
    for iobj=1:2
            xA(iobj)=LineData{iobj}.Coord(1,1);
            yA(iobj)=LineData{iobj}.Coord(1,2);
            xB(iobj)=LineData{iobj}.Coord(2,1);
            yB(iobj)=LineData{iobj}.Coord(2,2);
    end
end


%% set the image offset
BlackOffset=0;
RefLineWidth=20;
if isfield(XmlData,'LIFCalib')&& isfield(XmlData.LIFCalib,'BlackOffset')
    BlackOffset=XmlData.LIFCalib.BlackOffset ;% image value for black background, to be determined by taking images with a cover on the objective lens
    RefLineWidth=XmlData.LIFCalib.RefLineWidth;
end

prompt = {'offset luminosity value in the absence of illumination';'smoothing width for the reference line (in pixels)';...
    'LIF Temperature Coeff1';'LIF Temperature Coeff2';'LIF Temperature Coeff3'};
    dlg_title = 'set the parameters for LIF';
    num_lines= 5;
    def     = { num2str(BlackOffset);num2str(RefLineWidth);'0';'0';'0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
if isempty(answer) 
    return
else
    XmlData.LIFCalib.BlackOffset=str2double(answer{1}) ;% image value for black background, to be determined by taking images with a cover on the objective lens
    XmlData.LIFCalib.RefLineWidth=str2double(answer{2}) ;% smoothing width used for the reference line
    XmlData.LIFCalib.TLIFCoeff=[str2double(answer{3}) str2double(answer{4}) str2double(answer{5})];
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
XmlData.LIFCalib.LightOrigin=[x0 y0];% origin of the light source to be saved in the current xml file
XmlData.LIFCalib.Ray1Coord=LineData{1}.Coord;
XmlData.LIFCalib.Ray2Coord=LineData{2}.Coord;
if numel(LineData)<3
    msgbox_uvmat('ERROR','draw a reference line of direct laser illumination (without dye absorbsion)');
    return
end
XmlData.LIFCalib.RefLineCoord=LineData{3}.Coord;

%% rescale the image
[nby,nbx]=size(UvData.Field.A);
x=linspace(UvData.Field.Coord_x(1),UvData.Field.Coord_x(2),nbx)-nbx/2;
y=linspace(UvData.Field.Coord_y(1),UvData.Field.Coord_y(2),nby)-nby/2;
[X,Y]=meshgrid(x,y);
%coeff_quad=0.15*4/(nbx*nbx);% image luminosity reduced by 10% at the edge
%UvData.Field.A=double(UvData.Field.A).*(1+coeff_quad*(X.*X+Y.*Y));

%% display the current image in polar axes with origin at the  illumination source
currentdir=pwd;
uvmatpath=fileparts(which('uvmat'));
cd(fullfile(uvmatpath,'transform_field'));
phys_polar=str2func('phys_polar');
cd(currentdir)
XmlData.TransformInput.PolarCentre=[x0 y0];
DataPol=phys_polar(UvData.Field,XmlData);%transform the input image in polar coordinates with origin at the light source

%% use the third line for reference luminosity, renormalize the image intensity along each ray to get a uniform brightness along this line
if numel(find(select_line))==3
    x_ref=linspace(LineData{3}.Coord(1,1),LineData{3}.Coord(2,1),10);
    y_ref=linspace(LineData{3}.Coord(1,2),LineData{3}.Coord(2,2),10);
    x_ref=x_ref-x0;
    y_ref=y_ref-y0;
    [theta_ref,r_ref] = cart2pol(x_ref,y_ref);%theta_ref  and r_ref are the polar coordinates of the points on the line
    theta_ref=theta_ref*180/pi;% theta_ref in degrees
    figure(10)
    plot(theta_ref,r_ref)
    xlabel('azimuth(degrees)')
    ylabel('radius from light source')
    title('ref line in polar coordinates')
    azimuth_ima=linspace(DataPol.Coord_y(1),DataPol.Coord_y(2),size(DataPol.A,1))-360;%array of angular indices on the transformed image
    dist_source = interp1(theta_ref,r_ref,azimuth_ima);% get the polar position of the reference line
    dist_source_pixel=round(size(DataPol.A,2)*(dist_source-DataPol.Coord_x(1))/(DataPol.Coord_x(2)-DataPol.Coord_x(1)));
    line_nan= isnan(dist_source);
    dist_source_pixel(line_nan)=1;
    DataPol.A=double(DataPol.A)-XmlData.LIFCalib.BlackOffset;% black background substracted
    Anorm=zeros(size(DataPol.A));
    for iline=1:size(DataPol.A,1)
        lum(iline)=mean(DataPol.A(iline,dist_source_pixel(iline):dist_source_pixel(iline)+XmlData.LIFCalib.RefLineWidth));% average the luminosity on a band width lying on the reference line
        Anorm(iline,:)=DataPol.A(iline,:)/lum(iline);% for each ray (iline), renormalise the image by the brightness at the reference line 
    end
    lum(line_nan)=NaN;
    XmlData.LIFCalib.RefLineAzimuth=DataPol.Coord_y;
    XmlData.LIFCalib.RefLineRadius=dist_source;
    XmlData.LIFCalib.RefLineLum=lum;
    figure(11)
    plot(1:size(DataPol.A,1),lum)
    xlabel('azimuth (pixels)')
    ylabel('image brightness')
    title('ref brightness profile')
end

%% get the image A*r
[npy,npx]=size(Anorm);
AX=DataPol.Coord_x;
AY=DataPol.Coord_y;
dX=(AX(2)-AX(1))/(npx-1);
dY=(AY(1)-AY(2))/(npy-1);%mesh of new pixels
[R,Theta]=meshgrid(linspace(AX(1),AX(2),npx),linspace(AY(1),AY(2),npy));
A=R.*Anorm;
A=(A<=0).*ones(npy,npx)+(A>0).*A; %replaces zeros by ones
A=log(A); % rA(r) should have a slope -gamma in x (radius from laser source)

%% get the exponential decay law
index_mask=find(select_mask);
if ~isempty(index_mask)
    if numel(index_mask)>1
        msgbox_uvmat('ERROR',{'only one mask polygon accepted'});
        return
    else
        MaskData=UvData.ProjObject{index_mask};
        XmlData.LIFCalib.MaskPolygonCoord=MaskData.Coord;
    end
end

%% loop on lines iY (angle in polar coordiantes)
gamma_coeff=NaN(1,npy);
fitlength=NaN(1,npy);
for iY=1:npy% loop on the y index of the image in polar coordinate
    ALine=A(iY,:);%profile of image luminosity log (vs radial index)
    RLine=R(iY,:);%radius of the reference line (vs radial index)
    ThetaLine=Theta(iY,:)*pi/180;
    [XLine,YLine] = pol2cart(ThetaLine,RLine);
    XLine=XLine+x0;
    YLine=YLine+y0;
    if ~isempty(index_mask)
        check_good=inpolygon(XLine,YLine,MaskData.Coord(:,1),MaskData.Coord(:,2));
        if numel(find(check_good))>npx/4;% keep only lines with reasonable length
            ALine=ALine(check_good);
            RLine=RLine(check_good);
        else
            continue
        end
    end
    p = polyfit(RLine,ALine,1);
    gamma_coeff(iY)=-p(1);
    fitlength(iY)=numel(find(check_good));
end

%% show and store the rescaled image
NewImageName=fullfile(get(handles.RootPath,'String'),'LIF_ref_rescaled.png');
DataPol.A=uint16(1000*A);
view_field(DataPol);
imwrite(DataPol.A,NewImageName,'BitDepth',16)
figure(13)
plot(Theta(:,1),100*gamma_coeff)
xlabel('angle(degree)')
ylabel('decay coeff(m-1)')

%% keep the average of gamma_coeff
XmlData.LIFCalib.DecayRate=mean(gamma_coeff(gamma_coeff>0));

%% record the calibration data in the xml file
hbrowse=browse_data(fullfile(get(handles.RootPath,'String'),get(handles.SubDir,'String')));
answer = questdlg('Where','record the LIF parameters','Current series', 'Replicate', 'Cancel', 'Cancel');
if strcmp(answer,'Current series')
    XmlFileName=find_imadoc(get(handles.RootPath,'String'),get(handles.SubDir,'String'),get(handles.RootFile,'String'),get(handles.FileExt,'String'));
    update_imadoc(XmlData.LIFCalib,XmlFileName,'LIFCalib');% introduce the calibration data in the xml file
    % display the concentration in uvmat
    InputFileREFRESH_Callback(hObject, eventdata, handles);% refresh the current xml file to apply 'ima2concentration'
    transform_list=get(handles.TransformName,'String');
    ichoice=find(strcmp('ima2concentration',transform_list),1);%look for the selected fct in the existing menu
    if isempty(ichoice)% if the item is not found, add it to the menu (before 'more...' and select it)
        transform_list=transform_list(1:end-1);
        ichoice=numel(transform_list)-1;
    end
    set(handles.TransformName,'Value',ichoice)
    TransformName_Callback(hObject, eventdata, handles)
elseif strcmp(answer,'Replicate')
    
    BrowseData=guidata(hbrowse);
    SourceDir=get(BrowseData.SourceDir,'String');
    ListExp=get(BrowseData.ListExperiments,'String');
    ExpIndices=get(BrowseData.ListExperiments,'Value');
    ListExp=ListExp(ExpIndices);
    ListDevices=get(BrowseData.ListDevices,'String');
    DeviceIndices=get(BrowseData.ListDevices,'Value');
    ListDevices=ListDevices(DeviceIndices);
    ListDataSeries=get(BrowseData.DataSeries,'String');
    DataSeriesIndices=get(BrowseData.DataSeries,'Value');
    ListDataSeries=ListDataSeries(DataSeriesIndices);
    NbExp=0; % counter of the number of experiments set by the GUI browse_data
    for iexp=1:numel(ListExp)
        if ~isempty(regexp(ListExp{iexp},'^\+/'))% if it is a folder
            for idevice=1:numel(ListDevices)
                if ~isempty(regexp(ListDevices{idevice},'^\+/'))% if it is a folder
                    for isubdir=1:numel(ListDataSeries)
                        if ~isempty(regexp(ListDataSeries{isubdir},'^\+/'))% if it is a folder
                            lpath= fullfile(SourceDir,regexprep(ListExp{iexp},'^\+/',''),...
                                regexprep(ListDevices{idevice},'^\+/',''));
                            ldir= regexprep(ListDataSeries{isubdir},'^\+/','');
                            if exist(fullfile(lpath,ldir),'dir')
                                NbExp=NbExp+1;
                                ListPath{NbExp}=lpath;
                                ListSubdir{NbExp}=ldir;
                                ExpIndex{NbExp}=iexp;
                            end
                        end
                    end
                end
            end
        end
    end
    for iexp=1:NbExp
        XmlName=fullfile(ListPath{iexp},[ListSubdir{iexp} '.xml']);
        if exist(XmlName,'file')
            check_update=1;
        else
            check_update=0;
        end
        errormsg=update_imadoc(XmlData.LIFCalib,XmlName,'LIFCalib');% introduce the calibration data in the xml file
        if ~strcmp(errormsg,'')
            msgbox_uvmat('ERROR',errormsg);
        else
            if check_update
                display([XmlName ' updated with calibration parameters'])
            else
                display([XmlName ' created with calibration parameters'])
            end
        end
    end
    msgbox_uvmat('CONFIMATION',['LIF calibration replicated for ' num2str(NbExp) ' experiments']);
end



%     
%     
%     t=xmltree(XmlFileName); %read the file
%     title_str=get(t,1,'name');
%     if ~strcmp(title_str,'ImaDoc')
%         msgbox_uvmat('ERROR','wrong xml file');
%         return
%     end
%     % backup the output file if it already exist, and read it
%     backupfile=XmlFileName;
%     testexist=2;
%     while testexist==2
%         backupfile=[backupfile '~'];
%         testexist=exist(backupfile,'file');
%     end
%     [success,message]=copyfile(XmlFileName,backupfile);%make backup
%     if success~=1
%         errormsg=['errror in xml file backup: ' message];
%         return
%     end
%     uid_illumination=find(t,'ImaDoc/LIFCalib');
%     if isempty(uid_illumination)  %if GeometryCalib does not already exists, create it
%         [t,uid_illumination]=add(t,1,'element','LIFCalib');
%     end
%     uid_origin=find(t,'ImaDoc/LIFCalib/LightOrigin');
%     if ~isempty(uid_origin)  %if LightOrigin already exists, delete it
%         t=delete(t,uid_origin);
%     end
%     uid_line=find(t,'ImaDoc/LIFCalib/Ray1Coord');
%     if ~isempty(uid_line)  %if Ray1Coord already exists, delete it
%         t=delete(t,uid_line);
%     end
%     uid_line=find(t,'ImaDoc/LIFCalib/Ray2Coord');
%     if ~isempty(uid_line)  %if Ray2Coord already exists, delete it
%         t=delete(t,uid_line);
%     end
%     uid_line=find(t,'ImaDoc/LIFCalib/RefLineCoord');
%     if ~isempty(uid_line)  %if RefLineCoord already exists, delete it
%         t=delete(t,uid_line);
%     end
%     uid_mask=find(t,'ImaDoc/LIFCalib/MaskPolygonCoord');
%     if ~isempty(uid_mask) %if MaskPolygonCoord already exists, delete it
%         t=delete(t,uid_mask);
%     end
%     uid_BlackOffset=find(t,'ImaDoc/LIFCalib/BlackOffset');
%     if ~isempty(uid_BlackOffset)  %if BlackOffset already exists, delete it
%         t=delete(t,uid_BlackOffset);
%     end
%     uid_RefLineWidth=find(t,'ImaDoc/LIFCalib/RefLineWidth');
%     if ~isempty(uid_RefLineWidth)  %if RefLineWidth already exists, delete it
%         t=delete(t,uid_RefLineWidth);
%     end
%     uid_DecayRate=find(t,'ImaDoc/LIFCalib/DecayRate');
%     if ~isempty(uid_DecayRate)  %if DecayRate already exists, delete it
%         t=delete(t,uid_DecayRate);
%     end
%     uid_RefLineRadius=find(t,'ImaDoc/LIFCalib/RefLineRadius');
%     if ~isempty(uid_RefLineRadius)  %if RefLineLum already exists, delete it
%         t=delete(t,uid_RefLineRadius);
%     end
%     uid_RefLineLum=find(t,'ImaDoc/LIFCalib/RefLineLum');
%     if ~isempty(uid_RefLineLum)  %if RefLineLum already exists, delete it
%         t=delete(t,uid_RefLineLum);
%     end
%     uid_RefLineAzimuth=find(t,'ImaDoc/LIFCalib/RefLineAzimuth');
%     if ~isempty(uid_RefLineAzimuth)  %if RefLineLum already exists, delete it
%         t=delete(t,uid_RefLineAzimuth);
%     end
%     
%     % save the LIF calibration data
%     t=struct2xml(XmlData.LIFCalib,t,uid_illumination);
%     save(t,XmlFileName);
    




%------------------------------------------------------------------------
function MenuMask_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface
ListObj=UvData.ProjObject;
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
    if ~isfield(UvData.Field,'A')
        msgbox_uvmat('ERROR','an image needs to be opened to set the mask size');
        return
    end
    npx=size(UvData.Field.A,2);
    npy=size(UvData.Field.A,1);
    xi=0.5:npx-0.5;
    yi=0.5:npy-0.5;
    [Xi,Yi]=meshgrid(xi,yi);
    for iobj=1:length(UvData.ProjObject)
        ObjectData=UvData.ProjObject{iobj};
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
            [success,msg]=mkdir(mask_dir);
            if success==0
                msgbox_uvmat('ERROR',['cannot create ' mask_dir ': ' msg]);%error message for directory creation
                return
            end
            [success,msg] = fileattrib(mask_dir,'+w','g','s');% allow writing access for the group of users, recursively in the folder
            if success==0
                msgbox_uvmat('WARNING',{['unable to set group write access to ' mask_dir ':']; msg});%error message for directory creation
            end
        end
        try
            imwrite(imflag,answer,'BitDepth',8);
        catch ME
            msgbox_uvmat('ERROR',ME.message)
        end
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
if strcmp(get(handles.MenuRuler,'checked'),'on')
    set(handles.MenuRuler,'checked','off')%desactivate if activated
else
    set(handles.MenuRuler,'checked','on')%activate if selected
    set(handles.CheckZoom,'Value',0)
    CheckZoom_Callback(handles.uvmat, [], handles)
    UvData=get(handles.uvmat,'UserData');
    UvData.MouseAction='ruler';
    set(handles.uvmat,'UserData',UvData);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MenuRun Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%------------------------------------------------------------------------
% open the GUI 'series'
function MenuSeries_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
Param=read_GUI(handles.uvmat);
Param.HiddenData=get(handles.uvmat,'UserData');
series(Param); %run the series interface

% --------------------------------------------------------------------
function MenuPIV_Callback(hObject, eventdata, handles)
Param=read_GUI(handles.uvmat);
Param.HiddenData=get(handles.uvmat,'UserData');
hseries=series(Param);
hhseries=guidata(hseries);
ActionMenu=get(hhseries.ActionName,'String');
index_action=find(strcmp('civ_series',ActionMenu));
set(hhseries.ActionName,'Value',index_action);
series('ActionName_Callback',hObject,eventdata,hhseries); %file input with xml reading  in uvmat, show the image in phys coordinates

%------------------------------------------------------------------------
% -- open the GUI civ.fig for PIV
function MenuCIVx_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
 [RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
 FileName=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];
civ(FileName);% interface de civ(not in the uvmat file)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MenuHelp Callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
web('http://servforge.legi.grenoble-inp.fr/projects/soft-uvmat/wiki/UvmatHelp')










%------------------------------------------------------------------------
% --- Called by action in FileIndex edit box
function FileIndex_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
[tild,tild,tild,i1,i2,j1,j2]=fileparts_uvmat(get(handles.FileIndex,'String'));
set(handles.i1,'String',num2str(i1));%update the counters
set(handles.i2,'String',num2str(i2));
set(handles.j1,'String',num2str(j1));
set(handles.j2,'String',num2str(j2));


%------------------------------------------------------------------------
% --- Called by action in NomType edit box
function NomType_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
i1=str2num(get(handles.i1,'String'));
i2=str2num(get(handles.i2,'String'));
j1=str2num(get(handles.j1,'String'));
j2=str2num(get(handles.j2,'String'));
NomType=get(hObject,'String');
if strcmp(NomType,'level')
    FileIndex=str2num(get(handles.i1,'String'));
else
FileIndex=fullfile_uvmat('','','','',get(handles.NomType,'String'),i1,i2,j1,j2);
end
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
NomType=get(hObject,'String');
if strcmp(NomType,'level')
    FileIndex=str2num(get(handles.i1,'String'));
else
FileIndex=fullfile_uvmat('','','','',get(handles.NomType_1,'String'),i1,i2,j1,j2);
end
set(handles.FileIndex_1,'String',FileIndex)
% inputfilerefresh the current settings and inputfilerefresh the field view
RootPath_1_Callback(hObject,eventdata,handles)

%------------------------------------------------------------------------
% --- Executes on button press in InputFileREFRESH.
function InputFileREFRESH_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.InputFileREFRESH,'BackgroundColor',[1 1 0])% set button color to yellow to indicate that refresh is under action
set(handles.uvmat,'Pointer','watch') % set the mouse pointer to 'watch'
drawnow
% get the current input file name:
[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,tild,FileInfo,MovieObject]=find_file_series(fullfile(RootPath,SubDir),[RootFile FileIndices FileExt]);
errormsg='';
if isempty(RootFile)
    fileinput=uigetfile_uvmat('pick an input file',fullfile(RootPath,SubDir));
    hh=dir(fileinput);
    if numel(hh)>1
        msgbox_uvmat('ERROR','invalid input, probably a broken link');
    else
        %% display the selected field and related information
        if isempty(fileinput)
            errormsg='aborted';
        else
            display_file_name(handles,fileinput,1)
        end
    end
else
    % initiate the input file series and refresh the current field view:
    errormsg=update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileInfo,MovieObject,1);
end

%% refresh the second series if relevant
if ~isempty(errormsg) && get(handles.SubField,'Value')
    [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes_1(handles);
    % detect the file type, get the movie object if relevant, and look for the corresponding file series:
    [RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,tild,FileInfo,MovieObject]=find_file_series(fullfile(RootPath,SubDir),[RootFile FileIndices FileExt]);
    if isempty(i1_series)
        fileinput=uigetfile_uvmat('pick an input file for the second line',fullfile(RootPath,SubDir));
        hh=dir(fileinput);
        if numel(hh)>1
            msgbox_uvmat('ERROR','invalid input, probably a broken link');
        else
            %% display the selected field and related information
            if isempty(fileinput)
                errormsg='aborted';
            else
                display_file_name(handles,fileinput,2)
            end
        end
    else
        % initiate the input file series and inputfilerefresh the current field view:
        errormsg=update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileInfo,MovieObject,2);
    end
end
if ~isempty(errormsg)
    set(handles.InputFileREFRESH,'BackgroundColor',[1 0 1])% put back button color to magenta, input not succesfull
end
set(handles.uvmat,'Pointer','arrow')% set back the mouse pointer to arrow

%------------------------------------------------------------------------
% --- Fills the edit boxes RootPath, RootFile,NomType...from an input file name 'fileinput'
function errormsg=display_file_name(handles,fileinput,index)
%------------------------------------------------------------------------
%% look for the input file existence
errormsg='';%default
if isempty(regexp(fileinput,'^http')) && ~exist(fileinput,'file')
    errormsg=['input file ' fileinput  ' does not exist'];
    msgbox_uvmat('ERROR',errormsg)
    return
end

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
    set(handles.TimeName_1,'Visible','on')
    set(handles.TimeValue_1,'Visible','on')
end
set(handles.InputFileREFRESH,'BackgroundColor',[1 1 0])% paint REFRESH button to yellow to visualise root file input
set(handles.uvmat,'Pointer','watch') % set the mouse pointer to 'watch'
drawnow

%% detect root name, nomenclature and indices in the input file name:
[FilePath,FileName,FileExt]=fileparts(fileinput);
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
% the root name and indices may be corrected by including the first index i1 if a corresponding xml file exists
[RootPath,SubDir,RootFile,i1_series,i2_series,j1_series,j2_series,NomType,FileInfo,MovieObject,i1,i2,j1,j2]=...
    find_file_series(FilePath,[FileName FileExt]);

%% open the file or fill the GUI uvmat according to the detected file type
FieldType=FileInfo.FieldType;
switch FieldType
    case ''
        msgbox_uvmat('ERROR','invalid input file type')
        return
    case 'txt'
        edit(fileinput)
        return
    case 'figure'                           %display matlab figure
        hfig=open(fileinput);
        set(hfig,'WindowButtonMotionFcn','mouse_motion')%set mouse action functio
        set(hfig,'WindowButtonUpFcn','mouse_up')%set mouse click action function
        set(hfig,'WindowButtonUpFcn','mouse_down')%set mouse click action function
        return
    case 'xml'                % edit xml files
        t=xmltree(fileinput);
        % the xml file marks a project or project link, open datatree_browser
        if strcmp(get(t,1,'name'),'Project')&& exist(regexprep(fileinput,'.xml$',''),'dir')
            datatree_browser(fileinput)
        else % other xml file, open the xml editor
            editxml(fileinput);
        end
        return
    case 'xls'% Excel file opended by editxml
        editxml(fileinput);
        return
%     case 'mat'% matlab data file
% %         global Data_uvmat
% Data_uvmat.Field=load(fileinput);
% evalin('base','global Data_uvmat')%make CurData global in the workspace
% disp('Data_uvmat.Field=')
% evalin('base','Data_uvmat.Field') %display CurData in the workspace
% commandwindow; %brings the Matlab command window to the front
% return
    otherwise
        set(handles_RootPath,'String',RootPath);
        set(handles_SubDir,'String',['/' SubDir]);
        set(handles_RootFile,'String',['/' RootFile]); %display the separator
        if isempty(regexp(RootPath,'^http://'))
            rootname=fullfile(RootPath,SubDir,RootFile);
        else
            rootname=[RootPath '/' SubDir '/' RootFile];
        end
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
%                 msgbox_uvmat('WARNING','unable to synchronise the indices of the two series')
            end
            set(handles.FileIndex_1,'String',FileIndex_1)
        end
        
        %enable other menus
        set(handles.MenuExport,'Enable','on')
        set(handles.MenuExportFigure,'Enable','on')
        set(handles.MenuExportMovie,'Enable','on')
        set(handles.MenuTools,'Enable','on')
        
        % initiate input file series and inputfilerefresh the current field view:
        update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileInfo,MovieObject,index);
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
end
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    save (profil_perso,'MenuFile','RootPath','-append'); %store the file names for future opening of uvmat
else
    save (profil_perso,'MenuFile','RootPath','-V6'); %store the file names for future opening of uvmat
end

set(handles.InputFileREFRESH,'BackgroundColor',[1 0 0])% paint back button to red to indicate update is finished
set(handles.uvmat,'Pointer','arrow')% set back the mouse pointer to arrow


%------------------------------------------------------------------------
% --- Update information about a new field series (indices to scan, timing,
%     calibration from an xml file, then inputfilerefresh current plots
function errormsg=update_rootinfo(handles,i1_series,i2_series,j1_series,j2_series,FileInfo,VideoObject,index)
%------------------------------------------------------------------------
errormsg=''; %default error msg

%% define the relevant handles depending on the index (1=first file series, 2= second file series)
if ~exist('index','var')
    index=1;
end
if index==1
    handles_Fields=handles.FieldName;
elseif index==2
    handles_Fields=handles.FieldName_1;
end
set(handles.FixVelType,'Value',0); %desactivate fixed veltype by default

%% record info in UserData of the figure uvmat
UvData=get(handles.uvmat,'UserData');%huvmat=handles of the uvmat interface
UvData.NewSeries=1; %flag for REFRESH: begin a new series
UvData.FileName_1='';% name of the current second field (used to detect a  constant field during file scanning)
%UvData.FileType{index}=FileInfo.FileType;
UvData.FileInfo{index}=FileInfo;
UvData.MovieObject{index}=VideoObject;
UvData.i1_series{index}=i1_series;
UvData.i2_series{index}=i2_series;
UvData.j1_series{index}=j1_series;
UvData.j2_series{index}=j2_series;
nbfield=max(max(max(i2_series)));% total number of fields (i index)
if isempty(nbfield)
    nbfield=max(max(max(i1_series)));
end
nbfield_j=max(max(max(j2_series)));% number of fields along j index
if isempty(nbfield_j)
    nbfield_j=max(max(max(j1_series)));
end

%% read timing and total frame number from the current file (e.g. movie files)
TimeUnit='';%default
TimeName='';%default
XmlData.Time=[];%default
ColorType='falsecolor'; %default
if isfield(FileInfo,'FrameRate')% frame rate given in the file (case of video data)
    TimeUnit='s';
    if isempty(j1_series) %frame index along i
        XmlData.Time=zeros(FileInfo.NumberOfFrames+1,2);
        XmlData.Time(:,2)=(0:1/FileInfo.FrameRate:(FileInfo.NumberOfFrames)/FileInfo.FrameRate)';
    else
        XmlData.Time=[0;ones(size(i1_series,3)-1,1)]*(0:1/FileInfo.FrameRate:(FileInfo.NumberOfFrames)/FileInfo.FrameRate);
    end
end
if isfield(FileInfo,'TimeName')
    TimeName=FileInfo.TimeName;
end
if isfield(FileInfo,'ColorType')
    ColorType=FileInfo.ColorType;%='truecolor' for color images
end
if strcmp(ColorType,'truecolor')
    set(handles.CheckBW,'String',{'grayscale';'truecolor'})
else 
    set(handles.CheckBW,'String',{'grayscale';'default';'jet';'BuYlRd'})
end
if strcmp(ColorType,'grayscale')
    set(handles.CheckBW,'Value',1)
else
    set(handles.CheckBW,'Value',2)
end

%% read parameters (time, geometric calibration..) from a documentation file (.xml advised)
XmlData.GeometryCalib=[];%default
if index==1
    [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
else
    [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes_1(handles);
end
XmlFileName=find_imadoc(RootPath,SubDir,RootFile,FileExt);
[tild,tild,DocExt]=fileparts(XmlFileName);
warntext='';%default warning message
NbSlice=1;%default
ImaDoc_str='';
if ~isempty(XmlFileName)
    set(handles.view_xml,'Visible','on')
    set(handles.view_xml,'BackgroundColor',[1 1 0])% paint  to yellow color to indicate reading of the xml file
    set(handles.view_xml,'String','view .xml')
    drawnow
    [XmlDataRead,warntext]=imadoc2struct(XmlFileName);
    if ~isempty(warntext)
        msgbox_uvmat('WARNING',warntext)
    end
    if ~isempty(XmlDataRead)
        ImaDoc_str=['view ' DocExt];  % DocExt= '.xml' or .civ (obsolete case)
        if isfield(XmlDataRead,'TimeUnit')&& ~isempty(XmlDataRead.TimeUnit)
            TimeUnit=XmlDataRead.TimeUnit;
        end
        if isfield(XmlDataRead,'Time')&& ~isempty(XmlDataRead.Time)
            XmlData.Time=XmlDataRead.Time;
            if XmlDataRead.Time(1,:)==XmlDataRead.Time(2,:)% case starting with index 1
                sizDti=size(XmlDataRead.Time,1)-1;%size of the time vector explicitly defined in the xml file
                ind_start=1;
            else
                sizDti=size(XmlDataRead.Time,1);% case starting with index 0
                ind_start=0;
            end
        end
        set(handles.view_xml,'BackgroundColor',[1 1 1])% paint back to white
        drawnow
        if isfield(XmlDataRead, 'GeometryCalib') && ~isempty(XmlDataRead.GeometryCalib)
            XmlData.GeometryCalib=XmlDataRead.GeometryCalib;
            if isfield(XmlData.GeometryCalib,'CheckVolumeScan') && isequal(XmlData.GeometryCalib.CheckVolumeScan,1)
                set (handles.slices,'String','volume')
            end
            % check whether the GUI geometry_calib is opened
            hgeometry_calib=findobj('tag','geometry_calib');
            if ~isempty(hgeometry_calib) % check whether the display of the GUI geometry_calib is consistent with the current calib param
                GUserData=get(hgeometry_calib,'UserData');
                if ~(isfield(GUserData,'XmlInputFile') && strcmp(GUserData.XmlInputFile,XmlFileName))
                    answer=msgbox_uvmat('INPUT_Y-N','refresh the display of the GUI geometry_calib with the new input data?');
                    if strcmp(answer,'Yes')
                        geometry_calib(XmlFileName);%diplay the new calibration points and parameters in geometry_calib
                    end
                end
            end
        end
        if isfield(XmlDataRead, 'LIFCalib')
            XmlData.LIFCalib=XmlDataRead.LIFCalib;
        end
    end
end
if isempty(ImaDoc_str)
    set(handles.view_xml,'Visible','off') % no .xml (or .civ) file detected
else
    set(handles.view_xml,'String',ImaDoc_str)% indicate that a xml file has been detected
end

%% Define timing
% time not set by the input file: images or civ data: indicate that time is read from the xml file
%FileType=FileInfo.FileType;
if isfield(XmlData,'Time')&& ~isempty(XmlData.Time) && ...
        (strcmp(FileInfo.FileType,'image')|| strcmp(FileInfo.FileType,'multimage'))%||strcmp(FileType,'civdata')||strcmp(FileType,'civx'))
    TimeName='xml';
elseif strcmp(FileInfo.FieldType,'civdata')% ajouter pivdata_fluidimage
    TimeName='civdata';
end
if index==1
    set(handles.TimeName,'String',TimeName)
else
    set(handles.TimeName_1,'String',TimeName)
    set(handles.TimeName_1,'Visible','on')
end

%% store last index in handles.MaxIndex_i and .MaxIndex_j
if isfield(XmlData,'Time')&& ~isempty(XmlData.Time)
    %transform .Time to a column vector if it is a line vector the nomenclature uses a single index
    if isequal(size(XmlData.Time,1),1)
        XmlData.Time=(XmlData.Time)';
    end
end
last_i_cell=get(handles.MaxIndex_i,'String');
if isempty(nbfield)
    last_i_cell{index}='';
else
    last_i_cell{index}=num2str(nbfield);
end
set(handles.MaxIndex_i,'String',last_i_cell)
last_j_cell=get(handles.MaxIndex_j,'String');
if isempty(nbfield_j)
     last_j_cell{index}='';
else
     last_j_cell{index}=num2str(nbfield_j);
end
set(handles.MaxIndex_j,'String',last_j_cell);

%% store geometric calibration in UvData
if isfield(XmlData,'GeometryCalib')
    GeometryCalib=XmlData.GeometryCalib;
    if isempty(GeometryCalib)
        set(handles.pxcmx,'String','')
        set(handles.pxcmy,'String','')
        set(handles.pxcmx,'Visible','off')
        set(handles.pxcmy,'Visible','off')
        if index==1
        set(handles.TransformName,'Value',1); %  no transform by default
        end
    else
        set(handles.pxcmx,'Visible','on')
        set(handles.pxcmy,'Visible','on')
        if (isfield(GeometryCalib,'R')&& ~isequal(GeometryCalib.R(2,1),0) && ~isequal(GeometryCalib.R(1,2),0)) ||...
            (isfield(GeometryCalib,'kappa1')&& ~isequal(GeometryCalib.kappa1,0))
            set(handles.pxcmx,'String','var')
            set(handles.pxcmy,'String','var')
        elseif isfield(GeometryCalib,'fx_fy')
            pixcmx=GeometryCalib.fx_fy(1);%*GeometryCalib.R(1,1)*GeometryCalib.sx/(GeometryCalib.Tz*GeometryCalib.dpx);
            pixcmy=GeometryCalib.fx_fy(2);%*GeometryCalib.R(2,2)/(GeometryCalib.Tz*GeometryCalib.dpy);
            set(handles.pxcmx,'String',num2str(pixcmx))
            set(handles.pxcmy,'String',num2str(pixcmy))
        end
        if ~get(handles.CheckFixLimits,'Value')&& index==1
            set(handles.TransformName,'Value',3); % phys transform by default if fixedLimits is off
        end
        if isfield(GeometryCalib,'SliceCoord')
           siz=size(GeometryCalib.SliceCoord);
           if siz(1)>1
               NbSlice=siz(1);
               set(handles.slices,'Visible','on')
               set(handles.slices,'Value',1)
           end
           if isfield(GeometryCalib,'CheckVolumeScan') && isequal(GeometryCalib.CheckVolumeScan,1)
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
    if index==2 && isfield(UvData,'TimeUnit') && ~strcmp(UvData.TimeUnit,TimeUnit)
        msgbox_uvmat('WARNING',['time unit for second file series ' TimeUnit ' inconsistent with first series'])
    else
        UvData.TimeUnit=TimeUnit;
    end
end
UvData.XmlData{index}=XmlData;
UvData.NewSeries=1;
set(handles.uvmat,'UserData',UvData)

%display warning message
if ~isequal(warntext,'')
    msgbox_uvmat('WARNING',warntext);
end

%% set default options in menu 'FieldName'
switch FileInfo.FieldType
    case 'civdata'
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
        %set(handles.Coord_x,'Value',1);
        set(handles.Coord_x,'String','X');
        set(handles.Coord_y,'String','Y');
    case {'netcdf','mat'}
        set(handles_Fields,'Value',1)
        set(handles_Fields,'String',{'get_field...'})
        if index==1
            FieldName_Callback([],[], handles)
        else
            FieldName_1_Callback([],[], handles)
        end
    otherwise
        set(handles_Fields,'Value',1) % set menu to 'image'
        set(handles_Fields,'String',{'image'})
        %set(handles.Coord_x,'Value',1);
        set(handles.Coord_x,'String','Coord_x');
    set(handles.Coord_y,'String','Coord_y');
end


%% set index navigation options
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
if ~isempty(i1_series)
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
end
set(handles.scan_j,'Visible',state_j)
set(handles.j1,'Visible',state_j)
set(handles.j2,'Visible',state_j)
set(handles.MaxIndex_j,'Visible',state_j);
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
set(handles.InputFileREFRESH,'BackgroundColor',[1 0 0])% set button color to red to indicate that refresh has been updated
TransformName_Callback([],[],handles)% callback for the selection of transform function, then refresh the current plot
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
%------------------------------------------------------------------------
function scan_i_Callback(hObject, eventdata, handles)

if get(handles.scan_i,'Value')==1
    set(handles.scan_j,'Value',0)
else
    set(handles.scan_j,'Value',1)
end
scan_j_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- switch file index scanning options scan_i and scan_j in an exclusive way
%------------------------------------------------------------------------
function scan_j_Callback(hObject, eventdata, handles)

if get(handles.scan_j,'Value')==1
    set(handles.scan_i,'Value',0)
else
    set(handles.scan_i,'Value',1)
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
%------------------------------------------------------------------------
function update_ij(handles,index_rank)

NomType=get(handles.NomType,'String');

if strcmp(NomType,'level')
    indices=get(handles.i1,'String');
else
    indices=get(handles.FileIndex,'String');
    [tild,tild,tild,i1,i2,j1,j2]=fileparts_uvmat(indices);% the indices for the second series taken from FileIndex
    switch index_rank
        case 1
            indices=fullfile_uvmat('','','','',NomType,stra2num(get(handles.i1,'String')),i2,j1,j2);
        case 2
            indices=fullfile_uvmat('','','','',NomType,i1,stra2num(get(handles.i2,'String')),j1,j2);
        case 3
            indices=fullfile_uvmat('','','','',NomType,i1,i2,stra2num(get(handles.j1,'String')),j2);
        case 4
            indices=fullfile_uvmat('','','','',NomType,i1,i2,j1,stra2num(get(handles.j2,'String')));
    end
end
set(handles.FileIndex,'String',indices)

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
%------------------------------------------------------------------------
function view_xml_Callback(hObject, eventdata, handles)

% if TimeName defined, open the xml file corresponding to the first file
% series, else open the xml file corresponding to the second series
if isempty(get(handles.TimeName,'String'))% open the xml file corresponding to the secodn file series
    [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes_1(handles);
else
   [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
end
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
    [RootPath,SubDir]=read_file_boxes(handles);
    MaskSubDir=regexprep(SubDir,'\..*','');%take the root part of SubDir, before the first dot '.'
    MaskPath=fullfile(RootPath,[MaskSubDir '.mask']);
    mdetect=0;
    if exist(MaskPath,'dir')
        ListStruct=dir(MaskPath);%look for a mask file
        ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
        check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
        ListFiles=ListCells(1,:);%list of file and dri names
        ListFiles=ListFiles(~check_dir);%list of file names (excluding dir)
        if ~isempty(ListFiles)
            for ifile=1:numel(ListFiles)
                [tild,tild,MaskExt]=fileparts(ListFiles{1});
                [tild,tild,MaskFile{ifile},i1_series,i2_series,j1_series,j2_series,MaskNomType,MaskFileInfo]=find_file_series(MaskPath,ListFiles{ifile},0);
                MaskFileType=MaskFileInfo.FileType;
                if strcmp(MaskFileType,'image') && isempty(i2_series) && isempty(j2_series)
                    mdetect=1;
                end
                if ~strcmp(MaskFile{ifile},MaskFile{1})
                    mdetect=0;% cancel detection test in case of multiple masks, use the brower for selection
                    break
                end
            end
        end
        RootPath=MaskPath;
    end
    if mdetect==0 % if no mask is detected in the current folder
        MaskFullName=uigetfile_uvmat('pick a mask image file:',RootPath,'image');
        if isempty(MaskFullName)
            set(handles.CheckMask,'Value',0)
        end
        [MaskPath,MaskName,MaskExt]=fileparts(MaskFullName);
        [tild,tild,MaskFile,i1_series,i2_series,j1_series,j2_series,MaskNomType]=find_file_series(MaskPath,[MaskName MaskExt],0);
        if ~(isempty(i2_series) && isempty(j2_series))
            MaskNomType='*';
        end
    end
    Mask.Path=MaskPath;
    if isempty(MaskFile)
        Mask.File='';
    elseif ischar(MaskFile)
        Mask.File=MaskFile;
    else
        Mask.File=MaskFile{1};
    end
    Mask.NbSlice_i=1;
    Mask.NbSlice_j=1;
    if isempty(j1_series)
        if isempty(i1_series)
            MaskNomType='*';
        else
        Mask.NbSlice_i=i1_series(1,2,end);
        end
    else
        Mask.NbSlice_j=j1_series(1,end,2);
    end
    Mask.Ext=MaskExt;
    Mask.NomType=MaskNomType;
    set(handles.CheckMask,'UserData',Mask);
    errormsg=update_mask(handles);
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
function errormsg=update_mask(handles)
%------------------------------------------------------------------------
errormsg=[];%default
Mask=get(handles.CheckMask,'UserData');
if strcmp(get(handles.z_index,'Visible'),'on')
    MaskIndex_i=str2num(get(handles.z_index,'String'));
else
    MaskIndex_i=mod(str2num(get(handles.i1,'String'))-1,Mask.NbSlice_i)+1;
end
MaskIndex_z=MaskIndex_i;%default
if Mask.NbSlice_j>1
    MaskIndex_j=str2num(get(handles.j1,'String'));
    MaskIndex_z=MaskIndex_j;
else
    MaskIndex_j=1;
end
if isfield(Mask,'maskhandle')&& ishandle(Mask.maskhandle)
    uistack(Mask.maskhandle,'top');
end
MaskName=fullfile_uvmat(Mask.Path,'',Mask.File,Mask.Ext,Mask.NomType,MaskIndex_i,[],MaskIndex_j);
UvData=get(handles.uvmat,'UserData');

%% update mask image if the mask is new
if ~ (isfield(UvData,'MaskName') && isequal(UvData.MaskName,MaskName))
    UvData.MaskName=MaskName; %update the recorded name on UvData
    set(handles.uvmat,'UserData',UvData);
    if ~exist(MaskName,'file')
        if isfield(Mask,'maskhandle')&& ishandle(Mask.maskhandle)
            delete(Mask.maskhandle)
        end
    else
        %read mask image
        [MaskField,tild,errormsg] = read_field(MaskName,'image');
        if ~isempty(errormsg)
            return
        end
        npxy=size(MaskField.A);
        if length(npxy)>2
            errormsg=[MaskName ' is not a grey scale image'];
            return
        elseif ~isa(MaskField.A,'uint8')
            errormsg=[MaskName ' is not a 8 bit grey level image'];
            return
        end
        MaskField.ZIndex=MaskIndex_z;
        %px to phys or other transform on field
         menu_transform=get(handles.TransformName,'String');
        choice_value=get(handles.TransformName,'Value');
        transform_name=menu_transform{choice_value};%name of the transform fct  given by the menu 'transform_fct'
        transform=get(handles.TransformPath,'UserData');
        if  ~isequal(transform_name,'') && ~isequal(transform_name,'px')
            if isfield(UvData,'XmlData') && isfield(UvData.XmlData{1},'GeometryCalib')%use geometry calib recorded from the ImaDoc xml file as first priority
                Calib=UvData.XmlData{1}.GeometryCalib;
                MaskField=transform(MaskField,UvData.XmlData{1});
            end
        end
        flagmask=MaskField.A < 200;

        %make brown color image
        imflag(:,:,1)=0.9*flagmask;
        imflag(:,:,2)=0.7*flagmask;
        imflag(:,:,3)=zeros(size(flagmask));

        %update mask image
        hmask=[]; %default
        if isfield(Mask,'maskhandle')&& ishandle(Mask.maskhandle)
            hmask=Mask.maskhandle;
        end
        if ~isempty(hmask)
            set(hmask,'CData',imflag)
            set(hmask,'AlphaData',flagmask*0.6)
            set(hmask,'XData',MaskField.Coord_x);
            set(hmask,'YData',MaskField.Coord_y);
%             uistack(hmask,'top')
        else
            axes(handles.PlotAxes)
            hold on
            Mask.maskhandle=image(MaskField.Coord_x,MaskField.Coord_y,imflag,'Tag','mask','HitTest','off','AlphaData',0.6*ones(size(flagmask)));
            set(handles.CheckMask,'UserData',Mask)
        end
    end
end

%------------------------------------------------------------------------
%------------------------------------------------------------------------
% III - MAIN InputFileREFRESH FUNCTIONS : 'FRAME PLOT'
%------------------------------------------------------------------------

%------------------------------------------------------------------------
% --- Executes on button press in runplus: make one step forward and call
% --- InputFileREFRESH. The step forward is along the fieldname series 1 or 2 depending on
% --- the scan_i and scan_j check box (exclusive each other)
function runplus_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

set(handles.runplus,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
increment=str2double(get(handles.num_IndexIncrement,'String')); %get the field increment d
if isnan(increment)% case of free increment: move to next available field index
    increment='+';
end
errormsg=runpm(hObject,eventdata,handles,increment);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg);
end
set(handles.runplus,'BackgroundColor',[1 0 0])%paint the command button back in red

%------------------------------------------------------------------------
% --- Executes on button press in runmin: make one step backward and call
% --- InputFileREFRESH. The step backward is along the fieldname series 1 or 2 depending on
% --- the scan_i and scan_j check box (exclusive each other)
function runmin_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

set(handles.runmin,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
increment=-str2double(get(handles.num_IndexIncrement,'String')); %get the field increment d
if isnan(increment)% case of free increment: move to previous available field index
    increment='-';
end
errormsg=runpm(hObject,eventdata,handles,increment);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg);
end
set(handles.runmin,'BackgroundColor',[1 0 0])%paint the command button back in red

%------------------------------------------------------------------------
% -- Executes on button press in Movie: make a series of +> steps
function Movie_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

set(handles.Movie,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
increment=str2double(get(handles.num_IndexIncrement,'String')); %get the field increment d
if isnan(increment)% case of free increment: move to next available field index
    increment='+';
end
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
if isfield(UvData,'aviobj') && ~isempty( UvData.aviobj)
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
increment=-str2double(get(handles.num_IndexIncrement,'String')); %get the field increment d
if isnan(increment)% case of free increment: move to next available field index
    increment='-';
end
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
set(handles.Movie,'BackgroundColor',[1 0 0])%paint the command buttonback to red
set(handles.MovieBackward,'BackgroundColor',[1 0 0])%paint the command buttonback to red

%------------------------------------------------------------------------
% --- function activated by runplus and run minus
function errormsg=runpm(hObject,eventdata,handles,increment)
%------------------------------------------------------------------------
errormsg='';%default
%% check for movie pair status
% movie_status=get(handles.movie_pair,'Value');
% if movie_status
%     STOP_Callback(hObject, eventdata, handles)%interrupt movie pair if active
% end

%% read the current input file name(s) and field indices
InputFile=read_GUI(handles.InputFile);
InputFile.RootFile=regexprep(InputFile.RootFile,'^[\\/]|[\\/]$','');%suppress possible / or \ separator at the beginning or the end of the string
InputFile.SubDir=regexprep(InputFile.SubDir,'^[\\/]|[\\/]$','');%suppress possible / or \ separator at the beginning or the end of the string
FileExt=InputFile.FileExt;
NomType=InputFile.NomType;
[tild,tild,tild,i1,i2,j1,j2]=fileparts_uvmat(InputFile.FileIndex);% check back the indices used
if isempty(i1)
    i1=str2num(get(handles.i1,'String'));%read the field indices (for movie, it is not given by the file name)
elseif isempty(j1) && strcmp(get(handles.j1,'Visible'),'on')
    j1=str2num(get(handles.j1,'String'));%case of indexed movie
end
% if movie_status% we read the second index from the edit box
%     i2=str2num(get(handles.i2,'String'));%read the field indices (for movie, it is not given by the file name)
%     if strcmp(get(handles.j2,'Visible'),'on')
%     j2=str2num(get(handles.j2,'String'));%
%     end
% end
sub_value= get(handles.SubField,'Value');
if sub_value % a second input file has been entered
    [InputFile.RootPath_1,InputFile.SubDir_1,InputFile.RootFile_1,InputFile.FileIndex_1,InputFile.FileExt_1,InputFile.NomType_1]=read_file_boxes_1(handles);
    [tild,tild,tild,i1_1,i2_1,j1_1,j2_1]=fileparts_uvmat(InputFile.FileIndex_1);% the indices for the second series taken from FileIndex_1
    if isempty(i1_1)
        i1_1=str2num(get(handles.i1,'String'));%read the field indices (for movie, it is not given by the file name)
    elseif isempty(j1_1) && strcmp(get(handles.j1,'Visible'),'on')
        j1_1=str2num(get(handles.j1,'String'));%case of indexed movie
    end
else
    filename_1=[];
end

%% increment (or decrement) the field indices and update the input filename(s)
if ~isnumeric(increment)% undefined increment value
    set(handles.CheckFixPair,'Value',0)
end
CheckFixPair=get(handles.CheckFixPair,'Value')||(isempty(i2)&& isempty(j2));

% the pair i1-i2 or j1-j2 is imposed (check box CheckFixPair selected)
if CheckFixPair && isnumeric(increment)
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
    if isnumeric(increment)
        if get(handles.scan_i,'Value')==1% case of scanning along index i
            ref_i=ref_i+increment;% increment the current reference index i
        else % case of scanning along index j (burst numbers)
            ref_j=ref_j+increment;% increment the current reference index j if scan_j option is used
        end
    else % free increment
        if strcmp(increment,'+')% if runplus or movie is activated
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
        if isnumeric(increment)
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
        elseif ref_i_1+1>size(UvData.i1_series{2},3)&&~isempty(InputFile.NomType_1)
            errormsg='maximum i index reached for the second series (reload the input file to update the index bound)';
        elseif ref_j_1+1>size(UvData.i1_series{2},2)&&~isempty(InputFile.NomType_1)
            errormsg='maximum j index reached for the second series(reload the input file to update the index bound)';
        end
        if ~isempty(errormsg),return,end
        siz=size(UvData.i1_series{2});
        ref_indices=ref_i_1*siz(1)*siz(2)+ref_j_1*siz(1)+1:ref_i_1*siz(1)*siz(2)+(ref_j_1+1)*siz(1);
        if ~isempty(InputFile.NomType_1)
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
        end
    else% the second series (if needed) is the same file as the first
        i1_1=i1;
        i2_1=i2;
        j1_1=j1;
        j2_1=j2;
    end
end
filename=fullfile_uvmat(InputFile.RootPath,InputFile.SubDir,InputFile.RootFile,FileExt,NomType,i1,i2,j1,j2);

%% refresh plots
if sub_value
    filename_1=fullfile_uvmat(InputFile.RootPath_1,InputFile.SubDir_1,InputFile.RootFile_1,InputFile.FileExt_1,InputFile.NomType_1,i1_1,i2_1,j1_1,j2_1);
    errormsg=refresh_field(handles,filename,filename_1,i1,i2,j1,j2,i1_1,i2_1,j1_1,j2_1);
else
    errormsg=refresh_field(handles,filename,filename_1,i1,i2,j1,j2);
end
set(handles.InputFileREFRESH,'BackgroundColor',[1 0 0])
set(handles.runplus,'BackgroundColor',[1 0 0])
set(handles.runmin,'BackgroundColor',[1 0 0])

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
    if strcmp(NomType,'level')
        indices=num2str(i1);
    else
        indices=fullfile_uvmat('','','','',NomType,i1,i2,j1,j2);
    end
    set(handles.FileIndex,'String',indices);
    if ~isempty(filename_1)
        indices_1=fullfile_uvmat('','','','',InputFile.NomType_1,i1_1,i2_1,j1_1,j2_1);
        set(handles.FileIndex_1,'String',indices_1);
    end
    if isempty(i2), set(handles.i2,'String',''); end % suppress the second index display if not used
    if isempty(j2), set(handles.j2,'String',''); end
end

%------------------------------------------------------------------------
% --- Executes on button press in movie_pair: create an alternating movie with two view
function movie_pair_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%% stop movie action if the movie_pair button is off
if ~get(handles.movie_pair,'value')
    set(handles.movie_pair,'BusyAction','Cancel')%stop movie pair if button is 'off'
    set(handles.i2,'String','')% the second i index display is suppressed
    set(handles.j2,'String','')% the second j index display is suppressed
    set(handles.Dt_txt,'String','')% the time interval indication is suppressed
    return
else
    set(handles.movie_pair,'BackgroundColor',[1 1 0])%paint the command button in yellow
    drawnow
end

increment=str2double(get(handles.num_IndexIncrement,'String')); %get the field increment d
if isnan(increment)% case of free increment: move to next available field index
    increment='+';
end

%% make movie until movie speed is set to 0 or STOP is activated
hima=findobj(handles.PlotAxes,'Tag','ima');% %handles.PlotAxes =main plotting window (A GENERALISER)
set(handles.STOP,'Visible','on')
set(handles.speed,'Visible','on')
set(handles.speed_txt,'Visible','on')
set(handles.movie_pair,'BusyAction','queue')
while get(handles.speed,'Value')~=0 && isequal(get(handles.movie_pair,'BusyAction'),'queue') % enable STOP command
    % read and plot the series of images in non erase mode
    errormsg=runpm(hObject,eventdata,handles,increment);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg);
    end
    pause(1.02-get(handles.speed,'Value'));% wait for next image
    errormsg=runpm(hObject,eventdata,handles,-increment);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg);
        return
    end
    pause(1.02-get(handles.speed,'Value'));% wait for next image
    get(handles.speed,'Value')~=0 && isequal(get(handles.movie_pair,'BusyAction'),'queue')
end
set(handles.movie_pair,'BackgroundColor',[1 0 0])%paint the command button in red
set(handles.movie_pair,'Value',0)
set(handles.Dt_txt,'String','')

set(handles.runplus,'BackgroundColor',[1 0 0])%paint the command button back in red


%------------------------------------------------------------------------
% --- Executes on button press in InputFileREFRESH.
function REFRESH_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.REFRESH,'BackgroundColor',[1 1 0])%paint the REFRESH button in yellow to indicate its activity
drawnow
[RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);%read the features of the input file name (first line)
[tild,tild,tild,i1,i2,j1,j2]=fileparts_uvmat(FileIndex);% check back the indices used
if isempty(i2), set(handles.i2,'String',''); end % suppress the second i index display if not used
if isempty(j2), set(handles.j2,'String',''); end % suppress the second j index display if not used
if isempty(regexp(RootPath,'^http://'))
    filename=[fullfile(RootPath,SubDir,RootFile) FileIndex FileExt];% build the input file name (first line)
else
    filename=[RootPath '/' SubDir '/' RootFile FileIndex FileExt];%
end
filename_1='';%default second file name
FileIndex_1='';
if get(handles.SubField,'Value')% if a second file is introduced
    [RootPath_1,SubDir_1,RootFile_1,FileIndex_1,FileExt_1]=read_file_boxes_1(handles);%read the features of the input file name (second line)
    filename_1=[fullfile(RootPath_1,SubDir_1,RootFile_1) FileIndex_1 FileExt_1]; %build the input file name (second line)
end
num_i1=stra2num(get(handles.i1,'String'));
num_i2=stra2num(get(handles.i2,'String'));
num_j1=stra2num(get(handles.j1,'String'));
num_j2=stra2num(get(handles.j2,'String'));
[tild,tild,tild,i1_1,i2_1,j1_1,j2_1]=fileparts_uvmat(FileIndex_1);% get the indices of the second series from the string FileIndex_1
if isempty(j1_1)% case of movies, the index is not given by file index
    j1_1=num_j1;
end
% in case of movies the index is set by edit boxes i1 or j1 (case of movies indexed by index i)
errormsg=refresh_field(handles,filename,filename_1,num_i1,num_i2,num_j1,num_j2,i1_1,i2_1,j1_1,j2_1);
ResizeFcn(handles.uvmat,[],handles)
if isempty(errormsg)
    set(handles.REFRESH,'BackgroundColor',[1 0 0])% set button color to red, update successfull
else
     msgbox_uvmat('ERROR',errormsg);
     set(handles.REFRESH,'BackgroundColor',[1 0 1])% keep button color magenta, input not succesfull
end

%------------------------------------------------------------------------
% --- read the input files and inputfilerefresh all the plots, including projection.
% OUTPUT:
%  errormsg: error message char string  =[] by default
% INPUT:
% FileName: first input file (=[] in the absence of input file)
% FileName_1: second input file (=[] in the asbsence of second input file)
% num_i1,num_i2,num_j1,num_j2; frame indices
% i1_1,i2_1,j1_1,j2_1: frame indices for the second input file  (needed if FileName_1 is not empty)
%------------------------------------------------------------------------
function errormsg=refresh_field(handles,FileName,FileName_1,num_i1,num_i2,num_j1,num_j2,i1_1,i2_1,j1_1,j2_1)
%------------------------------------------------------------------------

%% initialisation
pointer=get(handles.uvmat,'Pointer');
if strcmp(pointer,'watch')% reinitialise the mouse if stuck to 'watch'
    set(handles.CheckZoom,'Value',0)
    pointer='arrow';
end
set(handles.uvmat,'Pointer','watch')
drawnow
if ~exist('Field','var')
    Field={};
end
UvData=get(handles.uvmat,'UserData');
if ishandle(handles.UVMAT_title) %remove title panel on uvmat (which appears at the first openning of the GUI)
    delete(handles.UVMAT_title)
end

%% determine the main input file information for action
if isempty(regexp(FileName,'^http://')) &&~exist(FileName,'file')
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
if  (strcmp(UvData.FileInfo{1}.FileType,'civdata')||strcmp(UvData.FileInfo{1}.FileType,'civx'))
    for iobj=1:numel(UvData.ProjObject)
        if isfield(UvData.ProjObject{iobj},'ProjMode')&& strcmp(UvData.ProjObject{iobj}.ProjMode,'interp_tps')
            check_proj_tps=1;% tps projection proposed
            break
        end
    end
end

%% read the first input field
ParamIn.ColorVar='';%default variable name for vector color
frame_index=1;%default
FieldName='';%default
VelType='';%default
if isfield(UvData.FileInfo{1},'FieldType') && strcmp(UvData.FileInfo{1}.FieldType,'image')
    FieldName='image';
    frame_index=1;%default
    if UvData.FileInfo{1}.NumberOfFrames>1
        if strcmp(NomType,'*')
            if num_i1>UvData.FileInfo{1}.NumberOfFrames
                errormsg='specified frame index exceeds file content';
                return
            else
                frame_index=num_i1;%frame index from a single movies or multimage
            end
        else
            if num_j1>UvData.FileInfo{1}.NumberOfFrames
                errormsg='specified frame index exceeds file content';
                return
            else
                frame_index=num_j1;% frame index from a set of indexed movies
            end
        end
    end
    if isfield(UvData,'MovieObject')
        ParamIn=UvData.MovieObject{1};
    end
end
switch UvData.FileInfo{1}.FieldType
    case {'civdata','netcdf','mat'}
        list_fields=get(handles.FieldName,'String');% list menu fields
        FieldName= list_fields{get(handles.FieldName,'Value')}; % selected field
        if strcmp(FieldName,'get_field...')
            FieldName_Callback(hObject, eventdata, handles)
            return
        else
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
    ParamIn.Coord_x=get(handles.Coord_x,'String');
    ParamIn.Coord_y=get(handles.Coord_y,'String');
    if iscell(ParamIn.Coord_y)
        ParamIn.Coord_y=ParamIn.Coord_y';
    end
    ParamIn.Coord_z=get(handles.Coord_z,'String');
    TimeName=get(handles.TimeName,'String');
    r=regexp(TimeName,'^(?<type>(dim:)|(var:))','names');%look for 'var:' or 'dim:' at the beginning of time name
    if ~isempty(r)
        frame_index=num_i1;%time index chosen by i1
        if strcmp(r.type,'dim:')
            ParamIn.TimeDimName=TimeName(5:end);
        elseif strcmp(r.type,'var:')
            ParamIn.TimeVarName=TimeName(5:end);
        end
    end
end

[Field{1},ParamOut,errormsg] = read_field(FileName,UvData.FileInfo{1}.FileType,ParamIn,frame_index);
if ~isempty(errormsg)
    errormsg=['uvmat / refresh_field / read_field( ' FileName ') / ' errormsg];
    return
end
if isfield(ParamOut,'Npx')&& isfield(ParamOut,'Npy')
    set(handles.num_Npx,'String',num2str(ParamOut.Npx));% display image size on the interface
    set(handles.num_Npy,'String',num2str(ParamOut.Npy));
end
Field{1}.ZIndex=z_index; %used for multiplane 3D calibration

%% choose and read a second field FileName_1 if defined
ParamOut_1=[];
if ~isempty(FileName_1)
    if numel(UvData.FileInfo)==1
        UvData.FileInfo{2}=UvData.FileInfo{1};
    end
    VelType_1=[];%default
    FieldName_1=[];
    ParamIn_1=[];
 
    frame_index_1=1;
    if ~isempty(FileName_1)
        if ~exist(FileName_1,'file')
            errormsg=['second file ' FileName_1 ' does not exist'];
            return
        end
    end
    if isequal(get(handles.NomType_1,'Visible'),'on')
        NomType_1=get(handles.NomType_1,'String');
    else
        NomType_1=get(handles.NomType,'String');
    end
    if strcmp(UvData.FileInfo{2}.FileType,'image')
        FieldName_1='image';
        frame_index_1=1;%default
        if UvData.FileInfo{2}.NumberOfFrames>1
            if strcmp(NomType_1,'*')
                if num_i1>UvData.FileInfo{2}.NumberOfFrames
                    errormsg='specified frame index exceeds file content';
                    return
                else
                    frame_index_1=num_i1;%frame index from a single movies or multimage
                end
            else
                if num_j1>UvData.FileInfo{2}.NumberOfFrames
                    errormsg='specified frame index exceeds file content';
                    return
                else
                    frame_index_1=num_j1;% frame index from a set of indexed movies
                end
            end
        end
        if isfield(UvData,'MovieObject')
            ParamIn_1=UvData.MovieObject{2};
        end
    end
    switch UvData.FileInfo{2}.FileType
        case {'civx','civdata','netcdf','pivdata_fluidimage','mat'}
            list_fields=get(handles.FieldName_1,'String');% list menu fields
            FieldName_1= list_fields{get(handles.FieldName_1,'Value')}; % selected field
            if ~strcmp(FieldName_1,'get_field...')
                if get(handles.FixVelType,'Value')
                    VelTypeList=get(handles.VelType_1,'String');
                    VelType_1=VelTypeList{get(handles.VelType_1,'Value')};
                end
            end
            % case of input vector field, get the scalar used for vector color
            if ~isempty(regexp(FieldName_1,'^vec('))
                list_code=get(handles.ColorCode,'String');% list menu fields
                index_code=get(handles.ColorCode,'Value');% selected string index
                if  ~strcmp(list_code{index_code},'black') &&  ~strcmp(list_code{index_code},'white')
                    list_code=get(handles.ColorScalar,'String');% list menu fields
                    index_code=get(handles.ColorScalar,'Value');% selected string index
                    ParamIn_1.ColorVar= list_code{index_code}; % selected field
                end
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
    
    test_keepdata_1=0;% test for keeping the previous stored data if the input files are unchanged
    if test_keepdata_1
        Field{2}=UvData.Field_1;% keep the stored field
        ParamOut_1=UvData.ParamOut_1;
    else
        if isempty(ParamIn_1) || isstruct(ParamIn_1)
            ParamIn_1.FieldName=FieldName_1;
            ParamIn_1.VelType=VelType_1;
            ParamIn_1.Coord_x=get(handles.Coord_x,'String');
            ParamIn_1.Coord_y=get(handles.Coord_y,'String');
        end
        [Field{2},ParamOut_1,errormsg] = read_field(FileName_1,UvData.FileInfo{2}.FileType,ParamIn_1,frame_index_1);
        if ~isempty(errormsg)
            errormsg=['error in reading ' FieldName_1 ' in ' FileName_1 ': ' errormsg];
            return
        end
        if isstruct(ParamOut_1)&&~strcmp(ParamOut_1.FieldName,'get_field...')&& (strcmp(UvData.FileInfo{2}.FileType,'civdata')||strcmp(UvData.FileInfo{2}.FileType,'civx'))...
                &&~strcmp(ParamOut_1.FieldName,'velocity') && ~strcmp(ParamOut_1.FieldName,'get_field...')
            if ~check_proj_tps
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
if isfield(UvData.FileInfo{1},'FieldType') && strcmp(UvData.FileInfo{1}.FieldType,'civdata')&& ~strcmp(FieldName,'get_field...')
    test_veltype=1;
    set(handles.VelType,'Visible','on')
    set(handles.VelType_1,'Visible','on')
    set(handles.FixVelType,'Visible','on')
    menu=set_veltype_display(ParamOut.CivStage,UvData.FileInfo{1}.FileType);
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

%% update the display menu for the second velocity type (second menuline)
test_veltype_1=0;
if ~isempty(FileName_1)

    if strcmp(UvData.FileInfo{2}.FileType,'civdata')&& ~strcmp(FieldName_1,'get_field...')
        test_veltype_1=1;
        set(handles.VelType_1,'Visible','on')
        menu=set_veltype_display(ParamOut_1.CivStage,UvData.FileInfo{2}.FileType);
        index_menu=strcmp(ParamOut_1.VelType,menu);
        set(handles.VelType_1,'Value',1+find(index_menu,1))
        set(handles.VelType_1,'String',[{''};menu])
    else
         set(handles.VelType_1,'Visible','off')
    end
    % update the second field menu: the same quantity
    if isstruct(ParamOut_1)
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

%% introduce w as background image by default for a new series (only for nbdim=2)
if ~isfield(UvData,'NewSeries')
    UvData.NewSeries=1;
end

%% display time value of the current file
abstime=[];%default inputs
dt=[];
TimeUnit='';
if isfield(UvData,'TimeUnit')
    TimeUnit=UvData.TimeUnit;%retrieve info from update_rootinfo
end
TimeName=get(handles.TimeName,'String');

% time from xml file or video movie
if strcmp(TimeName,'xml')||strcmp(TimeName,'video')
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
    if ~isempty(num_i1)&& ~isempty(num_i2) && num_i1>=0 &&siz(1)>=max(num_i1+1,num_i2+1) && siz(2)>=max(num_j1+1,num_j2+1)
        abstime=(UvData.XmlData{1}.Time(num_i1+1,num_j1+1)+UvData.XmlData{1}.Time(num_i2+1,num_j2+1))/2;%overset the time read from files
        dt=(UvData.XmlData{1}.Time(num_i2+1,num_j2+1)-UvData.XmlData{1}.Time(num_i1+1,num_j1+1));
        Field{1}.Dt=dt;
        if isfield(UvData.XmlData{1},'TimeUnit')
            TimeUnit=UvData.XmlData{1}.TimeUnit;
        end
    end
end

% time in the input file, not defined in a xml file or movie
if isempty(abstime)
    if (strcmp(TimeName,'civdata')||strcmp(TimeName,'civx')||strcmp(TimeName,'timestamp'))&&isfield(Field{1},'Time')
        abstime=Field{1}.Time;
    elseif ~isempty(regexp(TimeName,'^att:', 'once'))
        abstime=Field{1}.(TimeName(5:end));%the time is an attribute  selected by get_file
        if isfield(Field{1},[TimeName(5:end) 'Unit'])
            TimeUnit=Field{1}.([TimeName(5:end) 'Unit']);
        else
            TimeUnit='';
        end
    elseif  ~isempty(regexp(TimeName,'^var:', 'once'))
        abstime=Field{1}.(TimeName(5:end));%the time is a variale selected by get_file
        % TODO: look for time unit attribute
    elseif ~isempty(regexp(TimeName,'^dim:'))
        abstime=str2num(get(handles.i1,'String'));
        TimeUnit='index';
    end
    if isfield(Field{1},'Dt')
        dt=Field{1}.Dt;%dt read from the netcdf input file
    elseif numel(Field)==2 && isfield(Field{2},'Dt')%dt obtained from the second field if not defined in the first
        dt=Field{2}.Dt;%dt read from the netcdf input file
    end
end
set(handles.TimeValue,'String',num2str(abstime))

%% display time value of the second current file if relevant
abstime_1=[];
if ~isempty(FileName_1)
    TimeName_1=get(handles.TimeName_1,'String');% indicate whether time is from xml or video
    % time from xml file or video movie as a second file series
    if strcmp(TimeName_1,'xml')||strcmp(TimeName_1,'video')
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
            if ~isempty(i1_1) && siz(1)>=max(i1_1+1,i2_1+1) && siz(2)>=max(j1_1+1,j2_1+1)
                abstime_1=(UvData.XmlData{2}.Time(i1_1+1,j1_1+1)+UvData.XmlData{2}.Time(i2_1+1,j2_1+1))/2;%overset the time read from files
                Field{2}.Dt=(UvData.XmlData{2}.Time(i2_1+1,j2_1+1)-UvData.XmlData{2}.Time(i1_1+1,j1_1+1));
            end
        end
    end

    % get time in the input file of the second series, not defined in a xml file or movie
    if isempty(abstime_1) && numel(Field)==2
         if strcmp(TimeName_1,'civdata')||strcmp(TimeName_1,'civx')
        abstime_1=Field{2}.Time;
         elseif  ~isempty(regexp(TimeName_1,'^att:')) ||~isempty(regexp(TimeName_1,'^dim:'))||~isempty(regexp(TimeName_1,'^var:'))
        abstime_1=Field{2}.(TimeName_1(5:end));%the time is an attribute or variale selected by get_file
         end
    end
    set(handles.TimeValue_1,'String',num2str(abstime_1,5))
end

if isempty(dt)||isequal(dt,0)
    set(handles.Dt_txt,'String','')
else
    if  isempty(TimeUnit)
        set(handles.Dt_txt,'String',['Dt=' num2str(1000*dt,3) '  10^(-3)'] )
    else
        set(handles.Dt_txt,'String',['Dt=' num2str(1000*dt,3) '  m' TimeUnit] )
    end
end

%% Time title with unit
if isempty(abstime)&&isempty(abstime_1)
    Time_title='';
else
    Time_title='Time';
    if ~isempty(TimeUnit)
        Time_title=['Time (' TimeUnit ')'];
    end
end
set(handles.Time_title,'String',Time_title)

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
    if numel(Field)==2
        UvData.Field=sub_field(Field{1},[],Field{2});
    end      
else
    XmlData=[];%default
    XmlData_1=[];%default
    if isfield(UvData,'XmlData')%use geometry calib recorded from the ImaDoc xml file as first priority
        XmlData=UvData.XmlData{1};
        if isfield(UvData,'TransformInput')
            XmlData.TransformInput=UvData.TransformInput;
        end
        if numel(UvData.XmlData)==2
            XmlData_1=UvData.XmlData{2};
        end
    end
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

testnewseries=UvData.NewSeries;
UvData.NewSeries=0;% put to 0 the test for a new field series (set by RootPath_callback)


%% usual (x,y) plot
if strcmp(FieldName,'')
    set(handles.Objects,'Visible','off')
    set(handles.CheckFixAspectRatio,'Value',0)
    coord_x_name=get(handles.Coord_x,'String');
    check_x_name=find(strcmp(coord_x_name,UvData.Field.ListVarName));
    UvData.Field.VarAttribute{check_x_name}.Role='coord_x';
    [PlotType,PlotParamOut,haxes]=plot_field(UvData.Field,handles.PlotAxes,read_GUI(handles.uvmat));
    UvData.PlotAxes=UvData.Field; %store data for further plot modifications
    errormsg=fill_GUI(PlotParamOut,handles.uvmat);
    for list={'Scalar','Vectors'}
        if ~isfield(PlotParamOut,list{1})
            set(handles.(list{1}),'Visible','off')
        end
    end
    set(handles.Histogram,'Visible','off')
    set(handles.HistoMenu,'Visible','off')
    set(handles.HistoAxes,'Visible','off')
    hlegend=findobj(handles.uvmat,'Tag','HistoLegend');
    if ~isempty(hlegend)
        delete(hlegend)
    end
    cla(handles.HistoAxes)% clear the curves and legend in histogram axes
    UvData.Field.NbDim=1;
    set(handles.uvmat,'UserData',UvData)
    
%% 2D or 3D fieldname are generally projected
else
    UvData.Field=find_field_bounds(UvData.Field);

%% get bounds and dimensions of the input field

%% calculate tps coefficients if needed
    UvData.Field=tps_coeff_field(UvData.Field,check_proj_tps);

   
%% Plot the projections on the selected  projection objects
     set(handles.Objects,'Visible','on')
    %if no projection object exists, create a default one
    if isempty(UvData.ProjObject{1})% if no projection object is specified
        set(handles.ListObject,'Value',1)
        set(handles.ListObject,'String',{'plane'})
        UvData.ProjObject{1}.Type='plane';%main plotting plane
        UvData.ProjObject{1}.ProjMode='projection';%main plotting plane
        UvData.ProjObject{1}.DisplayHandle.uvmat=[]; %plane not visible in uvmat
        UvData.ProjObject{1}.DisplayHandle.view_field=[]; %plane not visible in uvmat
        set(handles.ListObject_1,'Value',1)
        set(handles.ListObject_1,'String',{'plane'})
        if UvData.Field.NbDim==3 %3D case
            UvData.ProjObject{1}.NbDim=3;%test for 3D objects
            UvData.ProjObject{1}.RangeZ=UvData.Field.CoordMesh;%main plotting plane
            UvData.ProjObject{1}.Coord(1,3)=(UvData.Field.ZMin+UvData.Field.ZMax)/2;%section at a middle plane chosen
            UvData.ProjObject{1}.Angle=[0 0];
            if isfield(UvData.Field,'CoordUnit')
                UvData.ProjObject{1}.CoordUnit=UvData.Field.CoordUnit;
            end
        %elseif isfield(UvData,'Z')
        else
            %multilevel case (single menuplane in a 3D space)
            if isfield(UvData,'CoordType')&& isequal(UvData.CoordType,'phys') && isfield(UvData,'XmlData')
                XmlData=UvData.XmlData{1};
                if isfield(XmlData,'PlanePos')
                    UvData.ProjObject{1}.Coord=XmlData.PlanePos(UvData.ZIndex,:);
                end
                if isfield(XmlData,'PlaneAngle')
                    siz=size(XmlData.PlaneAngle);
                    indangle=min(siz(1),UvData.ZIndex);%take first angle if a single angle is defined (translating scanning)
                    UvData.ProjObject{1}.PlaneAngle=XmlData.PlaneAngle(indangle,:);
                end
            elseif isfield(UvData,'ZIndex')
                UvData.ProjObject{1}.ZObject=UvData.ZIndex;
            end
        end
    end
    IndexObj=get(handles.ListObject_1,'Value');%selected projection object for main view
    if IndexObj> numel(UvData.ProjObject)
        IndexObj=1;%select the first object if the selected one does not exist
        set(handles.ListObject_1,'Value',1)
    end
    if get(handles.CheckViewField,'Value')
        IndexObj_2=get(handles.ListObject,'Value');%selected projection object for view_field
        if ~isequal(IndexObj_2,IndexObj(1))
            IndexObj(2)=IndexObj_2;
        end
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
        if isfield(ParamOut,'ColorVar')
            PlotParam{1}.Vectors.ColorScalar=ParamOut.ColorVar;
        end
    end

    %% second projection object (view_field display)
    if length( IndexObj)==2
        view_field_handle=findobj(allchild(0),'tag','view_field');%handles of the view_field GUI
        if ~isempty(view_field_handle)
            plot_handles{2}=guidata(view_field_handle);
            haxes(2)=plot_handles{2}.PlotAxes;
            PlotParam{2}=read_GUI(view_field_handle);
        end
    end

    %% introduce default  projection objects in 3D
    for imap=1:numel(IndexObj)
        iobj=IndexObj(imap);
        if numel(UvData.ProjObject)<iobj
            break
        end
        if isfield(UvData.Field,'NbDim') && UvData.Field.NbDim==3
            UvData.ProjObject{iobj}.NbDim=3;%test for 3D objects
            if ~isfield(UvData.ProjObject{iobj},'RangeZ')
                UvData.ProjObject{iobj}.RangeZ=UvData.Field.CoordMesh;%main plotting plane
            end
            if iobj==1 && ~(isfield(UvData.ProjObject{iobj},'Coord') && size(UvData.ProjObject{iobj}.Coord,2)>=3 && UvData.ProjObject{iobj}.Coord(1,3)<UvData.Field.ZMax && UvData.ProjObject{iobj}.Coord(1,3)>UvData.Field.ZMin)
                UvData.ProjObject{iobj}.Coord(1,3)=(UvData.Field.ZMin+UvData.Field.ZMax)/2;%section at a middle plane chosen
            end
        end
    end
   
    set(handles.uvmat,'UserData',UvData)
    
    %% loop on the projection objects: one or two
    for imap=1:numel(IndexObj)
        iobj=IndexObj(imap);
        if numel(UvData.ProjObject)<iobj
            break
        end
        [ObjectData,errormsg]=proj_field(UvData.Field,UvData.ProjObject{iobj});% project field on the object
        if ~isempty(errormsg)
            errormsg=['projection on ' UvData.ProjObject{iobj}.Type ': ' errormsg ];
            return
        end
        if testnewseries
            PlotParam{imap}.Scalar.CheckBW=[]; %B/W option depends on the input field (image or scalar)
            if isfield(ObjectData,'CoordUnit')
                PlotParam{imap}.Axes.CheckFixAspectRatio=1;% set x and y scaling equal if CoordUnit is defined (common unit for x and y)
                PlotParam{imap}.Axes.AspectRatio=1; %set aspect ratio to 1
            end
        end
        %use of mask (TODO: check)
        if isfield(ObjectData,'NbDim') && isequal(ObjectData.NbDim,2) && isfield(ObjectData,'Mask') && isfield(ObjectData,'A')
            flag_mask=double(ObjectData.Mask>200);%=0 for masked regions
            Coord_x=ObjectData.Coord_x;%x coordiantes for the scalar field
            Coord_y=ObjectData.Coord_y;%y coordinates for the scalar field
            MaskX=ObjectData.MaskX;%x coordiantes for the mask
            MaskY=ObjectData.MaskY;%y coordiantes for the mask
            if ~isequal(MaskX,Coord_x)||~isequal(MaskY,Coord_y)
                nxy=size(flag_mask);
                sizpx=(ObjectData.MaskX(end)-ObjectData.MaskX(1))/(nxy(2)-1);%size of a mask pixel
                sizpy=(ObjectData.MaskY(1)-ObjectData.MaskY(end))/(nxy(1)-1);
                x_mask=ObjectData.MaskX(1):sizpx:ObjectData.MaskX(end); % pixel x coordinates for image display
                y_mask=ObjectData.MaskY(1):-sizpy:ObjectData.MaskY(end);% pixel x coordinates for image display
                %project on the positions of the scalar
                npxy=size(ObjectData.A);
                dxy(1)=(ObjectData.Coord_y(end)-ObjectData.Coord_y(1))/(npxy(1)-1);%grid mesh in y
                dxy(2)=(ObjectData.Coord_x(end)-ObjectData.Coord_x(1))/(npxy(2)-1);%grid mesh in x
                xi=ObjectData.Coord_x(1):dxy(2):ObjectData.Coord_x(end);
                yi=ObjectData.Coord_y(1):dxy(1):ObjectData.Coord_y(end);
                [XI,YI]=meshgrid(xi,yi);% creates the matrix of regular coordinates
                flag_mask = interp2(x_mask,y_mask,flag_mask,XI,YI);
            end
            AClass=class(ObjectData.A);
            ObjectData.A=flag_mask.*double(ObjectData.A);
            ObjectData.A=feval(AClass,ObjectData.A);
        end

        if ~isempty(ObjectData)
            if imap==2 && isempty(view_field_handle)
                view_field(ObjectData)
            else
                [PlotType,PlotParamOut]=plot_field(ObjectData,haxes(imap),PlotParam{imap});
                if ~isempty(regexp(PlotType,'^error'))%exit in case of plotting error
                    if ~isempty(regexp(PlotType,'attempt to plot two vector fields'))
                        set(handles.CheckEditObject,'Value',1)
                        CheckEditObject_Callback([], [], handles)% propose to edit the main projection plane
                        hset_object=findobj(allchild(0),'Tag','set_object');%find the GUI set_object
                        hhset_object=guidata(hset_object);%
                        set(hhset_object.ProjMode,'Value',2);
                        set_object('ProjMode_Callback',hset_object,[],hhset_object);
                    end
                    return
                end
                if imap==1
                    errormsg=fill_GUI(PlotParamOut,handles.uvmat);
                else
                    errormsg=fill_GUI(PlotParamOut,view_field_handle);%TODO: check effect on text display
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
        update_mask(handles);
    end

    %% prepare the menus of histograms and plot them (Histogram of the whole volume in 3D case)
    menu_histo=(UvData.Field.ListVarName)';%list of field variables to be displayed for the menu of histogram display
    ind_skip=[];
    % nb_histo=1;
    Ustring='';
    Vstring='';
    % suppress axes from the Histogram menu
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
        set(handles.HistoMenu,'Value',1)
        set(handles.HistoMenu,'String',menu_histo)
        set(handles.Histogram,'Visible','on')
        set(handles.HistoMenu,'Visible','on')
        set(handles.HistoAxes,'Visible','on')
        HistoMenu_Callback(handles.HistoMenu, [], handles)% plot first histogram
    end
end
% open the set_object for interactive plane projection in 3D case
if UvData.Field.NbDim==3
    set(handles.CheckEditObject,'Value',1)
    CheckEditObject_Callback(handles.uvmat, [], handles)
end

set(handles.uvmat,'Pointer',pointer)

%------------------------------------------------------------------------
function HistoMenu_Callback(hObject, eventdata, handles)
%--------------------------------------------
%% get the current field stored in uvmat user data
UvData=get(handles.uvmat,'UserData');
Field=UvData.Field;

%% get from the menu 'HistoMenu' the name(s) of the fields to use
histo_menu=get(handles.HistoMenu,'String');
histo_value=get(handles.HistoMenu,'Value');
FieldName=histo_menu{histo_value};
r=regexp(FieldName,'(?<var1>.*)(?<sep>,)(?<var2>.*)','names');
FieldName_2='';
if ~isempty(r)
    FieldName=r.var1;% name of first variable
    FieldName_2=r.var2;% name of second variable
end
if ~isfield(UvData.Field,FieldName)
    msgbox_uvmat('ERROR',['no field  ' FieldName ' for histogram'])
    return
end

%% extract the fields to use
% eliminate false data if relevant (false flag FF exists)
check_false=0;
if isfield(Field,'FF') && ~isempty(Field.FF) && isequal(size(Field.FF),size(Field.(FieldName)))
    indsel=find(Field.FF==0);%find values marked as false
    if ~isempty(indsel)
        FieldHisto=Field.(FieldName)(indsel);%field of the first variable (U)
        if ~isempty(FieldName_2)
            if isfield(Field,'NbDim') && Field.NbDim==3
                 FieldHisto(:,:,:,2)=Field.(FieldName_2)(indsel);%field of the second variable (U)
            else
            FieldHisto(:,:,2)=Field.(FieldName_2)(indsel);%field of the second variable (U)
            end
        end
        check_false=1;
    end
end
% no false data
if ~check_false
    FieldHisto=Field.(FieldName);%field of the first variable (U)
    if ~isempty(FieldName_2)
        if isfield(Field,'NbDim') && Field.NbDim==3
            FieldHisto(:,:,:,2)=Field.(FieldName_2);%field of the second variable (V)
        else
            FieldHisto(:,:,2)=Field.(FieldName_2);%field of the second variable (V)
        end
    end
end

%% calculate and plot Histogram
if isempty(Field)
    msgbox_uvmat('ERROR',['empty field ' FieldName])
else
    nxy=size(FieldHisto);
    Amin=double(min(min(min(min(FieldHisto)))));%min of field value
    Amax=double(max(max(max(max(FieldHisto)))));%max of field value
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
        Histo.VarAttribute{1}.Role='coord_x';
        Histo.VarAttribute{2}.Role='coord_y';
        if ~isempty(units)
            Histo.VarAttribute{1}.units=units;
        end
        VarMesh=(Amax-Amin)/100;
        ord=10^(floor(log10(VarMesh)));%order of magnitude
        if VarMesh/ord >=5
            VarMesh=5*ord;
        elseif VarMesh/ord >=2
            VarMesh=2*ord;
        else
            VarMesh=ord;
        end
        Amin=VarMesh*(ceil(Amin/VarMesh));
        Amax=VarMesh*(floor(Amax/VarMesh));
        Histo.(FieldName)=Amin:VarMesh:Amax; %absissa values for histo
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
        hlegend=findobj(handles.uvmat,'Tag','HistoLegend');
        if isempty(hlegend)
            hlegend=legend;
            set(hlegend,'Tag','HistoLegend')
        end
        if isempty(FieldName_2)
            set(hlegend,'String',FieldName)
        else
            set(hlegend,'String',{FieldName;FieldName_2})
        end
    end
end

%------------------------------------------------------------------------
% --- translate coordinate to matrix index
%------------------------------------------------------------------------
function [indx,indy]=pos2ind(x0,rangx0,nxy)
indx=1+round((nxy(2)-1)*(x0-rangx0(1))/(rangx0(2)-rangx0(1)));% index x of pixel
indy=1+round((nxy(1)-1)*(y12-rangy0(1))/(rangy0(2)-rangy0(1)));% index y of pixel

%------------------------------------------------------------------------
% --- Executes on button press in 'CheckZoom'.
%------------------------------------------------------------------------
function CheckZoom_Callback(hObject, eventdata, handles)

    if get(handles.CheckZoom,'Value')
        set(handles.CheckFixLimits,'Value',1)% propose by default fixed limits for the plotting axes
        set(handles.CheckZoomFig,'Value',0)%desactivate zoom fig
    end


%------------------------------------------------------------------------
% --- Executes on button press in CheckZoomFig.
%------------------------------------------------------------------------
function CheckZoomFig_Callback(hObject, eventdata, handles)

if get(handles.CheckZoomFig,'Value')
    set(handles.CheckZoom,'value',0)
end

%------------------------------------------------------------------------
% --- Executes on button press in 'CheckFixLimits'.
%------------------------------------------------------------------------
function CheckFixLimits_Callback(hObject, eventdata, handles)

if ~get(handles.CheckFixLimits,'Value')
    update_plot(handles)
    set(handles.CheckZoom,'Value',0)
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckFixAspectRatio.
function CheckFixAspectRatio_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
 update_plot(handles);

%------------------------------------------------------------------------
function num_AspectRatio_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixAspectRatio,'Value',1)% select the fixed aspect ratio button
update_plot(handles);

%------------------------------------------------------------------------
%----Executes on button press in 'record': records the current flags of manual correction.
%------------------------------------------------------------------------
function record_Callback(hObject, eventdata, handles)

[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
FileName=[fullfile(RootPath,SubDir,RootFile) FileIndices FileExt];
[erread,message]=fileattrib(FileName);
if ~isempty(message) && ~isequal(message.UserWrite,1)
     msgbox_uvmat('ERROR',['no writting access to ' FileName])
     return
end
MenuVelType=get(handles.VelType,'String');
test_civ2=strcmp(MenuVelType{get(handles.VelType,'Value')},'civ2');
test_civ1=strcmp(MenuVelType{get(handles.VelType,'Value')},'civ1');
if ~test_civ2 && ~test_civ1
    msgbox_uvmat('ERROR','manual correction only possible for CIV1 or CIV2 velocity fields')
end
if test_civ2
    nbname='nb_vec_2';
   flagname='Civ2_FF';
   CivStage=5;
end
if test_civ1
    nbname='nb_vec_1';
   flagname='Civ1_FF';
    CivStage=2;
end
%write fix flags in the netcdf file
UvData=get(handles.uvmat,'UserData');
hhh=which('netcdf.open');% look for built-in matlab netcdf library
if ~isequal(hhh,'')% case of  builtin Matlab netcdf library
    nc=netcdf.open(FileName,'NC_WRITE');
    netcdf.reDef(nc);
    netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),'CivStage',CivStage);
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

%-----------------------------------------------------------------------
% --- Executes on button press in SubField
%-----------------------------------------------------------------------
function SubField_Callback(hObject, eventdata, handles)

if get(handles.SubField,'Value')==0% if the subfield button is desactivated
    desable_subfield(handles)
    transform_fct_list=get(handles.TransformName,'String');
    transform_fct=transform_fct_list(get(handles.TransformName,'Value'));
    if strcmp(transform_fct,'sub_field')
        set(handles.TransformName,'Value',1)%suppress the sub_field transform
        TransformName_Callback(hObject, eventdata, handles);
    else
        REFRESH_Callback(hObject, eventdata, handles)
    end
else
    fileinput_1=uigetfile_uvmat('select a second input file:',get(handles.RootPath,'String'));
    if isempty(fileinput_1)
        set(handles.SubField,'Value',0)
    else
        % refresh the current displayed field
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
    end
end

%-----------------------------------------------------------------------
% --- desactivate display used for a second file series
%-----------------------------------------------------------------------
function desable_subfield(handles)

set(handles.RootPath_1,'String','')
set(handles.RootFile_1,'String','')
set(handles.SubDir_1,'String','');
set(handles.FileIndex_1,'String','');
set(handles.FileExt_1,'String','');
set(handles.RootPath_1,'Visible','off')
set(handles.RootFile_1,'Visible','off')
set(handles.SubDir_1,'Visible','off');
set(handles.NomType_1,'Visible','off');
set(handles.FileIndex_1,'Visible','off');
set(handles.FileExt_1,'Visible','off');
set(handles.TimeName_1,'String','');
set(handles.TimeName_1,'Visible','off');
set(handles.TimeValue_1,'String','');
set(handles.TimeValue_1,'Visible','off');
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
UvData=get(handles.uvmat,'UserData');
if isfield(UvData,'XmlData_1')
    UvData=rmfield(UvData,'XmlData_1');
end
set(handles.uvmat,'UserData',UvData);

%------------------------------------------------------------------------
% --- read the data displayed for the input rootfile windows (new): TODO use read_GUI
%------------------------------------------------------------------------
function [RootPath,SubDir,RootFile,FileIndices,FileExt,NomType]=read_file_boxes(handles)

InputFile=read_GUI(handles.InputFile);
RootPath=InputFile.RootPath;
SubDir=regexprep(InputFile.SubDir,'/|\','');
RootFile=regexprep(InputFile.RootFile,'/|\','');
FileIndices=InputFile.FileIndex;
FileExt=InputFile.FileExt;
NomType=InputFile.NomType;

%------------------------------------------------------------------------
% ---- read the data displayed for the second input rootfile windows
%------------------------------------------------------------------------
function [RootPath_1,SubDir_1,RootFile_1,FileIndex_1,FileExt_1,NomType_1]=read_file_boxes_1(handles)

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

%% read data from uvmat
UvData=get(handles.uvmat,'UserData');
list_fields=get(handles.FieldName,'String');% list menu fields
index_fields=get(handles.FieldName,'Value');% selected string index
field= list_fields{index_fields(1)}; % selected string
[RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
if isempty(regexp(RootPath,'^http://'))
    FileName=[fullfile(RootPath,SubDir,RootFile) FileIndices FileExt];
else
    FileName=[RootPath '/' SubDir '/' RootFile FileIndices FileExt];
end
[tild,tild,tild,i1,i2,j1,j2,tild,NomType]=fileparts_uvmat(['xxx' get(handles.FileIndex,'String') FileExt]);

switch field
    case 'get_field...'
        %% fill the axes and variables from selections in get_field
        ParamIn.Title='get_field: choose input field for display in uvmat' ;
        % in case of civ data, we use the civ choice as default input for the GUI get_field
        if strcmp(get(handles.VelType,'Visible'),'on')
            ParamIn.SwitchVarIndexTime='attribute';
            ListVelType=get(handles.VelType,'String');
            VelType=ListVelType{get(handles.VelType,'Value')};
            switch VelType
                case 'civ1'
                    ParamIn.TimeAttrName='Civ1_Time';
                    ParamIn.vector_x='Civ1_U';
                    ParamIn.vector_y='Civ1_V';
                    ParamIn.vec_color='Civ1_C';
                case 'filter1'
                    ParamIn.TimeAttrName='Civ1_Time';
                    ParamIn.vector_x='Civ1_U_smooth';
                    ParamIn.vector_y='Civ1_V_smooth';
                case 'civ2'
                    ParamIn.TimeAttrName='Civ2_Time';
                    ParamIn.vector_x='Civ2_U';
                    ParamIn.vector_y='Civ2_V';
                case 'filter2'
                    ParamIn.TimeAttrName='Civ2_Time';
                    ParamIn.vector_x='Civ2_U_smooth';
                    ParamIn.vector_y='Civ2_V_smooth';
                    ParamIn.vec_color='Civ2_C';
            end
        else
            ParamIn.TimeAttrName=get(handles.TimeName,'String');
            ParamIn.Coord_x=get(handles.Coord_x,'String');
            ParamIn.Coord_y=get(handles.Coord_y,'String');
            ParamIn.Coord_z=get(handles.Coord_z,'String');
        end

        % VelType menu desactivated
        set(handles.FixVelType,'visible','off')
        set(handles.VelType,'Visible','off')

        %read selection from get_field
        [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes(handles);
        if isempty(regexp(RootPath,'^http://'))
        FileName=[fullfile(RootPath,SubDir,RootFile) FileIndices FileExt];
        else
            FileName=[RootPath '/' SubDir '/' RootFile FileIndices FileExt];
        end
        GetFieldData=get_field(FileName,ParamIn);% inport field names from the GUI get_field
        FieldList={};
        VecColorList={''};
        XName='';
        YName='';
        ZName='';
        switch GetFieldData.FieldOption
            case 'vectors'
                UName=GetFieldData.PanelVectors.vector_x;
                VName=GetFieldData.PanelVectors.vector_y;
                if isfield(GetFieldData,'Coordinates')
                    YName=GetFieldData.Coordinates.Coord_y;
                    if isfield(GetFieldData.Coordinates,'Coord_z')
                        ZName=GetFieldData.Coordinates.Coord_z;
                    end
                end
                CName=GetFieldData.PanelVectors.vec_color;
                FieldList={['vec(' UName ',' VName ')'];...
                    ['norm(' UName ',' VName ')'];...
                    UName;VName};
                VecColorList={['norm(' UName ',' VName ')'];...
                    UName;VName};
                if ~isempty(CName)
                    VecColorList=[{CName};VecColorList];
                end
            case 'scalar'
                AName=GetFieldData.PanelScalar.scalar;
                if isfield(GetFieldData,'Coordinates')
                    YName=GetFieldData.Coordinates.Coord_y;
                    if isfield(GetFieldData.Coordinates,'Coord_z')
                        ZName=GetFieldData.Coordinates.Coord_z;
                    end
                end
                FieldList={AName};
            case '1D plot'
                YName=GetFieldData.Coordinates.Coord_y;
                FieldList={''};  
                set(handles.uvmat,'ToolBar','figure')
                set(handles.Coord_y,'Max',2)
                %set(huvmat,
            case 'civdata...'%reinitiate input, return to automatic civ data readingget_field
                display_file_name(handles,FileName,1)
        end
        % get time as file index, attribute, variable or matrix index
        if ~strcmp(GetFieldData.FieldOption,'civdata...')
            if isfield(GetFieldData,'Coordinates')
                XName=GetFieldData.Coordinates.Coord_x;
            end
            TimeNameStr=GetFieldData.Time.SwitchVarIndexTime;
            switch TimeNameStr
                case 'file index'
                    set(handles.TimeName,'String','');
                case 'attribute'
                    set(handles.TimeName,'String',['att:' GetFieldData.Time.TimeName]);
                case 'variable'
                    set(handles.TimeName,'String',['var:' GetFieldData.Time.TimeName])
                    set(handles.NomType,'String','*')
                    set(handles.RootFile,'String',[get(handles.RootFile,'String') get(handles.FileIndex,'String')])
                    set(handles.i1,'String','1')% set counter to 1 (now the time index in the input matrix)
                    MaxIndex_i=get(handles.MaxIndex_i,'String');
                    MaxIndex_i{1}=num2str(GetFieldData.Time.TimeDimension);
                    set(handles.MaxIndex_i,'String',MaxIndex_i)%TODO: record time unit
                    UvData.TimeUnit=GetFieldData.Time.TimeUnit;
                    set(handles.uvmat,'UserData',UvData);
                    set(handles.FileIndex,'String','')
                    ParamIn.TimeVarName=GetFieldData.Time.TimeName;
                case 'matrix index'
                    set(handles.TimeName,'String',['dim:' GetFieldData.Time.TimeName]);
                    set(handles.NomType,'String','*')
                    set(handles.RootFile,'String',[get(handles.RootFile,'String') get(handles.FileIndex,'String')])
                    set(handles.i1,'String','1')% set counter to 1 (now the time index in the input matrix)
                    MaxIndex_i=get(handles.MaxIndex_i,'String');
                    MaxIndex_i{1}=num2str(GetFieldData.Time.TimeDimension);
                    set(handles.MaxIndex_i,'String',MaxIndex_i)%TODO: record time unit
                    UvData.TimeUnit=GetFieldData.Time.TimeUnit;
                    set(handles.uvmat,'UserData',UvData);
                    set(handles.FileIndex,'String','')
                    ParamIn.TimeDimName=GetFieldData.Time.TimeName;
            end
            set(handles.Coord_x,'String',XName)
            set(handles.Coord_y,'String',YName)
            set(handles.Coord_z,'String',ZName)
            set(handles.FieldName,'Value',1)
            set(handles.FieldName,'String',[FieldList; {'get_field...'}]);
            set(handles.ColorScalar,'Value',1)
            set(handles.ColorScalar,'String',VecColorList);
           % UvData.FileInfo{1}.FileType='netcdf';
            set(handles.uvmat,'UserData',UvData)
            REFRESH_Callback(hObject, eventdata, handles)
        end

    case 'image'
        %% look for image corresponding to civ data
        if  isfield(UvData.Field,'Civ2_ImageA')%get the corresponding input image in the netcdf file
            imagename=UvData.Field.Civ2_ImageA;
        elseif isfield(UvData.Field,'Civ1_ImageA')%
            imagename=UvData.Field.Civ1_ImageA;
        else
            SubDirBase=regexprep(SubDir,'\..*','');%take the root part of SubDir, before the first dot '.'
            imagename=fullfile_uvmat(RootPath,SubDirBase,RootFile,'.png',NomType,i1,[],j1,[]);
        end
        if ~exist(imagename,'file')
            imagename=uigetfile_uvmat('Pick an image file',imagename,'image');
            if isempty(imagename)
                return
            end
        end
        % display the selected field and related information
        display_file_name(handles,imagename)%display the image
    otherwise
        REFRESH_Callback(hObject, eventdata, handles)
end

%----------------------------------------------------------------
% --- Executes on menu selection FieldName_1
function FieldName_1_Callback(hObject, eventdata, handles)
%-------------------------------------------------

%%%%%% TODO: modify like FieldName_Callback
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
         %% fill the axes and variables from selections in get_field
        ParamIn=[];
        % in case of civ data, we use the civ choice as default input for the GUI get_field
        if strcmp(get(handles.VelType_1,'Visible'),'on')
            ParamIn.SwitchVarIndexTime='attribute';
            ListVelType=get(handles.VelType_1,'String');
            VelType=ListVelType{get(handles.VelType_1,'Value')};
            switch VelType
                case 'civ1'
                    ParamIn.TimeAttrName='Civ1_Time';
                    ParamIn.vector_x='Civ1_U';
                    ParamIn.vector_y='Civ1_V';
                    ParamIn.vec_color='Civ1_C';
                case 'filter1'
                    ParamIn.TimeAttrName='Civ1_Time';
                    ParamIn.vector_x='Civ1_U_smooth';
                    ParamIn.vector_y='Civ1_V_smooth';
                case 'civ2'
                    ParamIn.TimeAttrName='Civ2_Time';
                    ParamIn.vector_x='Civ2_U';
                    ParamIn.vector_y='Civ2_V';
                case 'filter2'
                    ParamIn.TimeAttrName='Civ2_Time';
                    ParamIn.vector_x='Civ2_U_smooth';
                    ParamIn.vector_y='Civ2_V_smooth';
                    ParamIn.vec_color='Civ2_C';
            end
        end

        % VelType menu desactivated
        set(handles.FixVelType,'visible','off')
        set(handles.VelType,'Visible','off')

        %read selection from get_field
        [RootPath,SubDir,RootFile,FileIndices,FileExt]=read_file_boxes_1(handles);
        FileName=[fullfile(RootPath,SubDir,RootFile) FileIndices FileExt];
        GetFieldData=get_field(FileName,ParamIn);% inport field names from the GUI get_field
        FieldList={};
        switch GetFieldData.FieldOption
            case 'vectors'
                UName=GetFieldData.PanelVectors.vector_x;
                VName=GetFieldData.PanelVectors.vector_y;
                if isfield(GetFieldData,'Coordinates')
                    YName=GetFieldData.Coordinates.Coord_y;
                    if isfield(GetFieldData.Coordinates,'Coord_z')
                        ZName=GetFieldData.Coordinates.Coord_z;
                    end
                end
                CName=GetFieldData.PanelVectors.vec_color;
                FieldList={['vec(' UName ',' VName ')'];...
                    ['norm(' UName ',' VName ')'];...
                    UName;VName};
                VecColorList={['norm(' UName ',' VName ')'];...
                    UName;VName};
                if ~isempty(CName)
                    VecColorList=[{CName};VecColorList];
                end
                 set(handles.ColorScalar,'Value',1)
                 set(handles.ColorScalar,'String',VecColorList);
            case 'scalar'
                set(handles.Scalar,'Visible','on')
                ResizeFcn(gcbo,[],handles)
                AName=GetFieldData.PanelScalar.scalar;
                if isfield(GetFieldData,'Coordinates')
                    YName=GetFieldData.Coordinates.Coord_y;
                    if isfield(GetFieldData.Coordinates,'Coord_z')
                        ZName=GetFieldData.Coordinates.Coord_z;
                    end
                end
                FieldList={AName};
            case '1D plot'
                YName=GetFieldData.PanelOrdinate.ordinate;
                FieldList={''}; 
            case 'civdata...'%reinitiate input, return to automatic civ data reading
                display_file_name(handles,FileName,1)
        end      
        if ~strcmp(GetFieldData.FieldOption,'civdata...')
            XName=GetFieldData.Coordinates.Coord_x;
            TimeNameStr=GetFieldData.Time.SwitchVarIndexTime;
            switch TimeNameStr
                case 'file index'
                    set(handles.TimeName_1,'String','');
                case 'attribute'
                    set(handles.TimeName_1,'String',['att:' GetFieldData.Time.TimeName]);
                case 'variable'
                    set(handles.TimeName_1,'String',['var:' GetFieldData.Time.TimeName])
                    set(handles.NomType_1,'String','*')
                    set(handles.RootFile_1,'String',[get(handles.RootFile,'String') get(handles.FileIndex,'String')])
                    set(handles.FileIndex_1,'String','')
                    ParamIn.TimeVarName=GetFieldData.Time.TimeName;
                case 'matrix_index'
                    set(handles.TimeName_1,'String',['dim:' GetFieldData.Time.TimeName]);
                    set(handles.NomType_1,'String','*')
                    set(handles.RootFile_1,'String',[get(handles.RootFile,'String') get(handles.FileIndex,'String')])
                    set(handles.FileIndex_1,'String','')
                    ParamIn.TimeDimName_1=GetFieldData.Time.TimeName;
            end
            set(handles.Coord_x,'String',XName)
%             if ischar(YName)
%                 YName={YName};
%             end
            set(handles.Coord_y,'String',YName)
            set(handles.FieldName_1,'Value',1)
            set(handles.FieldName_1,'String',[FieldList; {'get_field...'}]);
           
            UvData.FileInfo{2}.FileType='netcdf';
            set(handles.uvmat,'UserData',UvData)
            REFRESH_Callback(hObject, eventdata, handles)
        end
    case 'image'
        %% look for image corresponding to civ data
        if  isfield(UvData.Field,'Civ2_ImageA')%get the corresponding input image in the netcdf file
            imagename=UvData.Field.Civ2_ImageA;
        elseif isfield(UvData.Field,'Civ1_ImageA')%
            imagename=UvData.Field.Civ1_ImageA;
        else
            [RootPath,SubDir,RootFile,FileIndex,FileExt]=read_file_boxes(handles);
            SubDirBase=regexprep(SubDir,'\..*','');%take the root part of SubDir, before the first dot '.'
            imagename=fullfile_uvmat(RootPath,SubDirBase,RootFile,'.png','_1',i1,[],j1,[]);
        end
        if ~exist(imagename,'file')
            imagename=uigetfile_uvmat('Pick an image file',imagename,'image');

        end
        if isempty(imagename)
            set(handles.SubField,'Value',0)
            return
        else
            display_file_name(handles,imagename,2)%display the image as second field
        end
    otherwise
        check_refresh=1;
        if check_new% if a second field was not previously entered, we just read another field in the first input file
            set(handles.FileIndex_1,'String',get(handles.FileIndex,'String'))
            set(handles.FileExt_1,'String',get(handles.FileExt,'String'))

            UvData.FileType{2}=UvData.FileInfo{1}.FileType;
            UvData.XmlData{2}= UvData.XmlData{1};
            transform=get(handles.TransformPath,'UserData');
             if (~isa(transform,'function_handle')||nargin(transform)<3)
                set(handles.uvmat,'UserData',UvData)
                set(handles.TransformName,'value',2); % set transform fct to 'sub_field' if the current fct does not accept two input fields
                TransformName_Callback(hObject, eventdata, handles)% activate transform_fct_Callback and refresh current plot
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
            REFRESH_Callback(hObject, eventdata, handles)
        end
end

%------------------------------------------------------------------------
% --- set the visibility of relevant velocity type menus:
function menu=set_veltype_display(Civ,FileType)
%------------------------------------------------------------------------
if ~exist('FileType','var')
    FileType='civx';
end
imin=1;
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
    case {'civdata','pivdata_fluidimage'}
        menu={'civ1';'filter1';'civ2';'filter2'};
        if isequal(Civ,0)
            imax=0;
        elseif isequal(Civ,1) || isequal(Civ,2)
            imax=1;
        elseif isequal(Civ,3)
            imax=2;
        elseif isequal(Civ,4) || isequal(Civ,5)
            imax=3;
        elseif Civ==6 %patch2
            imax=4;
        else
            imax=4;imin=3;
        end
end
menu=menu(imin:imax);

%------------------------------------------------------------------------
% --- Executes on button press in FixVelType.
function FixVelType_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% inputfilerefresh the current plot if the fixed  veltype is unselected
if ~get(handles.FixVelType,'Value')
    REFRESH_Callback(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% --- Executes on button press in VelType.
function VelType_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.FixVelType,'Value',1)
REFRESH_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on choice selection in VelType_1.
function VelType_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.FixVelType,'Value',1)% the velocity type is now imposed by the GUI (not automatic)
UvData=get(handles.uvmat,'UserData');
set(handles.InputFileREFRESH,'BackgroundColor',[1 1 0])%paint REFRESH button in yellow to indicate its activation
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
     UvData.FileInfo{2}.FileType=UvData.FileInfo{1}.FileType;
     UvData.XmlData{2}= UvData.XmlData{1};
     set(handles.SubField,'Value',1)
     transform=get(handles.TransformPath,'UserData');
     if (~isa(transform,'function_handle')||nargin(transform)<3)
        set(handles.uvmat,'UserData',UvData)
        set(handles.TransformName,'value',2); % set transform fct to 'sub_field' if the current fct does not accept two input fields
        TransformName_Callback(hObject, eventdata, handles)% activate transform_fct_Callback and refresh current plot
     else
         check_refresh=1;
     end
end

% inputfilerefresh the current plot if it has not been done previously
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
%         set(handles.i1,'BackgroundColor',[1 1 1])
%         set(handles.i2,'BackgroundColor',[1 1 1])
%         set(handles.j1,'BackgroundColor',[1 1 1])
%         set(handles.j2,'BackgroundColor',[1 1 1])
%         set(handles.FileIndex,'BackgroundColor',[1 1 1])
%         set(handles.FileIndex_1,'BackgroundColor',[1 1 1])
    end
    set(handles.InputFileREFRESH,'BackgroundColor',[1 0 0])
end


%------------------------------------------------------------------------
% --- reset civ buttons
function reset_vel_type(handles_civ0,handle1)
%------------------------------------------------------------------------
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
%     set(handles.CheckZoom,'BackgroundColor',[0.7 0.7 0.7])
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)
    set(handles.CheckEditObject,'Value',0)
%     set(handles.CheckEditObject,'BackgroundColor',[0.7 0.7 0.7])
%     set(handles.cal,'Value',0)
%     set(handles.cal,'BackgroundColor',[0 1 0])
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)
    %initiate set_object GUI
    data.Name='VOLUME';
    if isfield(UvData,'CoordType')
        data.CoordType=UvData.CoordType;
    end
    if isfield(UvData.Field,'CoordMesh')&& ~isempty(UvData.Field.CoordMesh)
        data.RangeX=[UvData.Field.XMin UvData.Field.XMax];
        data.RangeY=[UvData.Field.YMin UvData.Field.YMax];
        data.DX=UvData.Field.CoordMesh;
        data.DY=UvData.Field.CoordMesh;
    elseif isfield(UvData.Field,'Coord_x')&& isfield(UvData.Field,'Coord_y') && isfield(UvData.Field,'A')%only image
        np=size(UvData.Field.A);
        meshx=(UvData.Field.Coord_x(end)-UvData.Field.Coord_x(1))/np(2);
        meshy=abs(UvData.Field.Coord_y(end)-UvData.Field.Coord_y(1))/np(1);
        data.RangeY=max(meshx,meshy);
        data.RangeX=max(meshx,meshy);
        data.DX=max(meshx,meshy);
    end
    data.ParentButton=handles.VOLUME;
    PlotHandles=get_plot_handles(handles);%get the handles of the interface elements setting the plotting parameters
    [hset_object,UvData.sethandles]=set_object(data,PlotHandles);% call the set_object interface with action on haxes,
                                                      % associate the set_object interface handle to the plotting axes
    set(hset_object,'name','set_object')
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
    set(handles.CheckEditObject,'Value',0)
    set(handles.CheckZoom,'Value',0)
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
if isfield(UvData,'ProjObject')
    for iobj=1:length(UvData.ProjObject)
        ObjectData=UvData.ProjObject{iobj};
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

%------------------------------------------------------------------------
%------------------------------------------------------------------------
%  - FUNCTIONS FOR SETTING PLOTTING PARAMETERS

%------------------------------------------------------------------------
%------------------------------------------------------------------------
% --- Executes on selection change in TransformName.

function TransformName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.TransformName,'backgroundColor',[1 1 0])% indicate activation  of the menu
drawnow
UvData=get(handles.uvmat,'UserData');
menu=get(handles.TransformName,'String');%refresh
ichoice=get(handles.TransformName,'Value');%item number in the menu
transform_name=menu{ichoice};% choice of the transform fct
list_path=get(handles.TransformName,'UserData');

%% handles  visibility of the path to the transform function
if isempty(transform_name)
    set(handles.TransformPath,'Visible','off')
else
    set(handles.TransformPath,'Visible','on')
end

%% add a new item to the menu if the option 'more...' has been selected
prev_path=fullfile(get(handles.TransformPath,'String'));
if ~exist(prev_path,'dir')
    prev_path=fullfile(fileparts(which('uvmat')),'transform_field');
end
if strcmp(transform_name,'more...')
    transform_fct_chosen=uigetfile_uvmat('Pick the transform function',prev_path,'.m');
    if ~isempty(transform_fct_chosen)
        [PathName,transform_name]=fileparts(transform_fct_chosen);
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
        fclose(fid);
        set(handles.TransformName,'ToolTipString',['transform_fct: ' InputText{1}{1}])% put the first line of the selected function as tooltip help
    end
end

%% adapt the GUI to the input/output conditions of the selected transform fct
CoordUnit='';
CoordUnitPrev='';
if isfield(UvData,'Field')&&isfield(UvData.Field,'CoordUnit')
    CoordUnitPrev=UvData.Field.CoordUnit;
end
if ~isempty(list_path{ichoice})
    if nargin(transform_handle)>1 %&& isfield(UvData,'XmlData')&&~isempty(UvData.XmlData)
        XmlData=[];
        if isfield(UvData,'XmlData')&&~isempty(UvData.XmlData)
            XmlData=UvData.XmlData{1};
        end
        if isfield(UvData,'TransformInput')
            XmlData.TransformInput=UvData.TransformInput;
        end
        UvData.Field.Action.RUN=0;% indicate that the transform fct is called only to get input param
        DataOut=feval(transform_handle,UvData.Field,XmlData);% execute the transform fct to get the required conditions
        if isfield(DataOut,'CoordUnit')% set the requested coord unit (info used to possibly delete the current projection objects)
            CoordUnit=DataOut.CoordUnit;
        end
        if isfield(DataOut,'InputFieldType')% to be used to impose a type of input file (eg. for image transform)
            UvData.InputFieldType=DataOut.InputFieldType;
        end
        if isfield(DataOut,'TransformInput')%  used to add transform parameters at selection of the transform fct
            UvData.TransformInput=DataOut.TransformInput;
        end
    end
end

%% delete drawn objects if the output CooordUnit is different from the previous one
% if  ~strcmp(CoordUnit,CoordUnitPrev)
%     set(handles.CheckFixLimits,'Value',0)
%     hother=findobj('Tag','proj_object');%find all the proj objects
%     for iobj=1:length(hother)
%         delete(hother(iobj))
%     end
%     hother=findobj('Tag','DeformPoint');%find all the proj objects
%     for iobj=1:length(hother)
%         delete(hother(iobj))
%     end
%     hh=findobj('Tag','calib_points');
%     if ~isempty(hh)
%         delete(hh)
%     end
%     hhh=findobj('Tag','calib_marker');
%     if ~isempty(hhh)
%         delete(hhh)
%     end
%     set(handles.ListObject,'Value',1)
%     set(handles.ListObject,'String',{''})
%     set(handles.ListObject_1,'Value',1)
%     set(handles.ListObject_1,'String',{''})
%     set(handles.CheckViewObject,'value',0)
%     CheckViewObject_Callback(hObject, eventdata, handles)
%     set(handles.CheckViewField,'value',0)
%     CheckViewField_Callback(hObject, eventdata, handles)
%     set(handles.CheckEditObject,'Value',0)
%     CheckEditObject_Callback(hObject, eventdata, handles)
%     UvData.ProjObject={[]};
% end
set(handles.uvmat,'UserData',UvData)
set(handles.TransformName,'backgroundColor',[1 1 1])% indicate desactivation  of the menu
drawnow

%% inputfilerefresh the current plot
if isempty(list_path{ichoice}) || nargin(transform_handle)<3
    set(handles.SubField,'Value',0)
    SubField_Callback(hObject, eventdata, handles)
else
    REFRESH_Callback(hObject, eventdata, handles)
end

%------------------------------------------------
%CALLBACKS FOR PLOTTING PARAMETERS
%-------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
function num_MinX_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
% set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%------------------------------------------------------------------------
function num_MaxX_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
% set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%------------------------------------------------------------------------
function num_MinY_Callback(hObject, eventdata, handles)
%------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
% set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%------------------------------------------------------------------------
function num_MaxY_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
update_plot(handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scalar or image representation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
function num_MinA_Callback(hObject, eventdata, handles)
%------------------------------------------
set(handles.CheckFixScalar,'Value',1) %suppress auto mode
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
% set(handles.CheckFixScalar,'BackgroundColor',[1 1 0])
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
if ~get(handles.CheckFixScalar,'Value')
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
if val==2% option 'contours'
    set(handles.interval_txt,'Visible','on')
    set(handles.num_IncrA,'Visible','on')
    set(handles.num_IncrA,'String','')% refresh contour interval
else % option 'image'
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
%set(handles.CheckFixVectors,'BackgroundColor',[1 1 0])
update_plot(handles);

%-------------------------------------------------------------------
function CheckFixVectors_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if ~get(handles.CheckFixVectors,'Value')
    update_plot(handles);
end

%------------------------------------------------------------------------
% --- Executes on selection change in CheckDecimate4 (nb_vec/4).
%------------------------------------------------------------------------
function CheckDecimate4_Callback(hObject, eventdata, handles)

if isequal(get(handles.CheckDecimate4,'Value'),1)
    set(handles.CheckDecimate16,'Value',0)
end
update_plot(handles);

%------------------------------------------------------------------------
% --- Executes on selection change in CheckDecimate16 (nb_vec/16).
%------------------------------------------------------------------------
function CheckDecimate16_Callback(hObject, eventdata, handles)

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
    case {'64 colors','BuYlRd'}
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
REFRESH_Callback(hObject, eventdata, handles)

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
num_MaxVec_Callback(hObject, eventdata, handles)

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
set(handles.VecColBar,'Units','pixel');
pos_vert=get(handles.VecColBar,'Position');
set(handles.VecColBar,'Units','Normalized');
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
set(handles.REFRESH,'BackgroundColor',[1 1 0]);% display plot activity by yellow color
drawnow
UvData=get(handles.uvmat,'UserData');
AxeData=[];
if isfield(UvData,'PlotAxes')
    AxeData=UvData.PlotAxes;% retrieve the current plotted data
end
PlotParam=read_GUI(handles.uvmat);
[tild,PlotParamOut]= plot_field(AxeData,handles.PlotAxes,PlotParam);
errormsg=fill_GUI(PlotParamOut,handles.uvmat);
if isempty(errormsg)
    set(handles.REFRESH,'BackgroundColor',[1 0 0]);% operation finished, back to red color
else
    msgbox_uvmat('ERROR',errormsg)
    set(handles.REFRESH,'BackgroundColor',[1 0 1]);% magenta color: graph still needs to be updated
end


%------------------------------------------------------------------------
%------------------------------------------------------------------------
%   SELECTION AND EDITION OF PROJECTION OBJECTS
%------------------------------------------------------------------------
%------------------------------------------------------------------------

% --- Executes on selection change in ListObject_1.
function ListObject_1_Callback(hObject, eventdata, handles)
list_str=get(handles.ListObject,'String');
UvData=get(handles.uvmat,'UserData');
ObjectData=UvData.ProjObject{get(handles.ListObject_1,'Value')};

%% update the projection plot on uvmat
[ProjData,errormsg]= proj_field(UvData.Field,ObjectData);%project the current input field on object ObjectData
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',['projection on ' UvData.ProjObject{iobj}.Type ': ' errormsg ])
        return
    end
plot_field(ProjData,handles.PlotAxes,read_GUI(handles.uvmat));% plot the projected field;
UvData.PlotAxes=ProjData;% store the plotted field for further update
%replot all the objects within the new projected field
for IndexObj=1:numel(list_str)
        hobject=UvData.ProjObject{IndexObj}.DisplayHandle.uvmat;
        if isempty(hobject) || ~ishandle(hobject)
            hobject=handles.PlotAxes;
        end
        if isequal(IndexObj,get(handles.ListObject,'Value'))
            objectcolor='m'; %paint in magenta the currently selected object in ListObject
        else
            objectcolor='b';
        end
        UvData.ProjObject{IndexObj}.DisplayHandle.uvmat=plot_object(UvData.ProjObject{IndexObj},ObjectData,hobject,objectcolor);%draw the object in uvmat
end
set(handles.uvmat,'UserData',UvData)

%% display the object parameters if the GUI set_object is already opened
if ~get(handles.CheckViewObject,'Value')
    ZBounds=0; % default
    if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
        ZBounds(1)=UvData.Field.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.Field.ZMax;%maximum for the Z slider
    end
    ObjectData.Name=list_str{get(handles.ListObject_1,'Value')};
    hset_object=set_object(ObjectData,[],ZBounds);
    set(hset_object,'name','set_object')
    set(handles.CheckViewObject,'Value',1)% show that the selected object in ListObject_1 is currently visualised
end

%  desactivate the edit object mode
set(handles.CheckEditObject,'Value',0)
% set(handles.CheckEditObject,'BackgroundColor',[0.7,0.7,0.7])

%------------------------------------------------------------------------
% --- Executes on selection change in ListObject.
function ListObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
list_str=get(handles.ListObject,'String');
IndexObj=get(handles.ListObject,'Value');%present object selection
UvData=get(handles.uvmat,'UserData');
if numel(UvData.ProjObject)<IndexObj
    return
end
ObjectData=UvData.ProjObject{IndexObj};
    ZBounds=0; % default
    if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
        ZBounds(1)=UvData.Field.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.Field.ZMax;%maximum for the Z slider
    end

%% show object features if view_object isselected
if get(handles.CheckViewObject,'value')
    hset_object=set_object(ObjectData,[],ZBounds);
    set(hset_object,'name','set_object')
end

%%  desactivate the edit object mode for security
set(handles.CheckEditObject,'Value',0)

%% update the  plot on view_field if view_field is already openened
hview_field=findobj(allchild(0),'tag','view_field');
if isempty(hview_field)
    hhview_field.PlotAxes=[];
else
    Data=get(hview_field,'UserData');
    hhview_field=guidata(hview_field);
    [ProjData,errormsg]= proj_field(UvData.Field,ObjectData);%project the current interface field on ObjectData
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',['projection on ' UvData.ProjObject{iobj}.Type ': ' errormsg ])
        return
    end
    [PlotType,PlotParam]=plot_field(ProjData,hhview_field.PlotAxes,read_GUI(hview_field));%read plotting parameters on the uvmat interface
    haxes=findobj(hview_field,'tag','axes3');
    pos=get(hview_field,'Position');
    if strcmp(get(haxes,'Visible'),'off')%sempty(PlotParam.Axes)% case of no plot display (pure text table)
        h_TableDisplay=findobj(hview_field,'tag','TableDisplay');
        pos_table=get(h_TableDisplay,'Position');
        set(hview_field,'Position',[pos(1)+pos(3)-pos_table(3) pos(2)+pos(4)-pos_table(4) pos_table(3) pos_table(4)])
        drawnow% needed to change position before the next command
        set(hview_field,'UserData',Data);% restore the previously stored GUI position after GUI resizing
    else
%         set(hview_field,'Position',Data.GUISize)% return to the previously stored GUI position and size
    end
end

%% update the color of the graphic object representation: the selected object in magenta, others in blue
update_object_color(handles.PlotAxes,hhview_field.PlotAxes,UvData.ProjObject{IndexObj}.DisplayHandle.uvmat)

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
% --- Executes on selection change in CheckEditObject.
function CheckEditObject_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
get(handles.CheckEditObject,'Value')
hset_object=findobj(allchild(0),'Tag','set_object');
if get(handles.CheckEditObject,'Value')% if the edit box has been selected
    %suppress the other options
    set(handles.MenuObject,'checked','off')
    set(handles.CheckZoom,'Value',0)
    CheckZoom_Callback(hObject, eventdata, handles)
    hgeometry_calib=findobj(allchild(0),'tag','geometry_calib');
    if ishandle(hgeometry_calib)
        hhgeometry_calib=guidata(hgeometry_calib);
        set(hhgeometry_calib.CheckEnableMouse,'Value',0)% desactivate mouse action in geometry_calib
        set(hhgeometry_calib.CheckEnableMouse,'BackgroundColor',[0.7 0.7 0.7])
    end
    set(handles.CheckViewObject,'value',1)
    CheckViewObject_Callback(hObject, eventdata, handles)
else % desactivate object edit mode
    if ~isempty(hset_object)% open the
        set(get(hset_object,'children'),'Enable','off')
        hSAVE=findobj(hset_object,'Tag','SAVE');
        set(hSAVE,'Enable','on')
    end
end


%------------------------------------------------------------------------
% --- Executes on button press in CheckViewObject.
function CheckViewObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
check_view=get(handles.CheckViewObject,'Value');
hset_object=findobj(allchild(0),'tag','set_object');
% if ~isempty(hset_object)
%     delete(hset_object)% delete existing version of set_object
% end
if check_view %activate set_object
    IndexObj=get(handles.ListObject,'Value');
    list_object=get(handles.ListObject,'String');
    UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface
    UvData.ProjObject{IndexObj}.Name=list_object{IndexObj};
    if numel(UvData.ProjObject)<IndexObj;% error in UvData
        msgbox_uvmat('ERROR','invalid object list')
        return
    end
    ZBounds=0; % default
    if  ~isfield(UvData,'Field')
        disp('an input field needs to be introduced')
        return
    end
    if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
        ZBounds(1)=UvData.Field.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.Field.ZMax;%maximum for the Z slider
    end
    data=UvData.ProjObject{IndexObj};
    if ~isfield(data,'Type')% default plane
        data.Type='plane';
    end
    
    %% initiate the new projection object
    if isempty(hset_object)
    hset_object=set_object(data,[],ZBounds);
    set(hset_object,'name','set_object')
    end
    
    hhset_object=guidata(hset_object);
    if get(handles.CheckEditObject,'Value')% edit mode
        set(get(hset_object,'children'),'Enable','on')
    else
        set(get(hset_object,'children'),'Enable','off')% deactivate the GUI except SAVE
        set(hhset_object.SAVE,'Enable','on')
    end
else
    delete(hset_object)
end


%------------------------------------------------------------------------
% --- Executes on button press in CheckViewField.
function CheckViewField_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
check_view=get(handles.CheckViewField,'Value');

if check_view
    IndexObj=get(handles.ListObject,'Value');
    UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface
    if numel(UvData.ProjObject)<IndexObj(end);% error in UvData
        msgbox_uvmat('ERROR','invalid object list')
        return
    end
    ZBounds=0; % default
    if isfield(UvData.Field,'ZMin') && isfield(UvData.Field,'ZMax')
        ZBounds(1)=UvData.Field.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.Field.ZMax;%maximum for the Z slider
    end
    set(handles.ListObject,'Value',IndexObj);%restore ListObject selection after set_object deletion
    if ~isfield(UvData.ProjObject{IndexObj(1)},'Type')% default plane
        UvData.ProjObject{IndexObj(1)}.Type='plane';
    end
    list_object=get(handles.ListObject,'String');
    UvData.ProjObject{IndexObj(end)}.Name=list_object{IndexObj(end)};

    %% show the projection of the selected object on view_field
    [ProjData,errormsg]= proj_field(UvData.Field,UvData.ProjObject{IndexObj});%project the current field on ObjectData
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',['projection on ' UvData.ProjObject{IndexObj}.Type ': ' errormsg])
        return
    end
    hview_field=findobj(allchild(0),'tag','view_field');
    if isempty(hview_field)
        hview_field=view_field;
    end
    hhview_field=guidata(hview_field);
    [PlotType,PlotParam]=plot_field(ProjData,hhview_field.PlotAxes,read_GUI(hview_field));%read plotting parameters on the GUI view_field);
    errormsg=fill_GUI(PlotParam,hview_field);
    for list={'Scalar','Vectors'}
        if ~isfield(PlotParam,list{1})
            set(hhview_field.(list{1}),'Visible','off')
        end
    end
    haxes=findobj(hview_field,'tag','axes3');
    pos=get(hview_field,'Position');
    if strcmp(get(haxes,'Visible'),'off')%sempty(PlotParam.Axes)% case of no plot display (pure text table)
        h_TableDisplay=findobj(hview_field,'tag','TableDisplay');
        pos_table=get(h_TableDisplay,'Position');
        set(hview_field,'Position',[pos(1)+pos(3)-pos_table(3) pos(2)+pos(4)-pos_table(4) pos_table(3) pos_table(4)])
    else
        Data=get(hview_field,'UserData');
    end
else
    hview_field=findobj(allchild(0),'tag','view_field');
    if ~isempty(hview_field)
        delete(hview_field)% delete existing version of set_object
    end
end


%------------------------------------------------------------------------
% --- Executes on button press in DeleteObject.
%------------------------------------------------------------------------
function DeleteObject_Callback(hObject, eventdata, handles)

IndexObj=get(handles.ListObject,'Value');%projection object selected for view_field
IndexObj_1=get(handles.ListObject_1,'Value');%projection object selected for uvmat plot
if IndexObj>1 && ~isequal(IndexObj,IndexObj_1) % do not delete the object used for the uvmat plot
    delete_object(IndexObj)
end

%'DeleteObject': delete a projection object, defined by its index in the Uvmat list or by its graphic handle
%------------------------------------------------------------------------
% function DeleteObject(hObject)
%
% INPUT:
% hObject: object index (if integer) or handle of the graphic object. If
%          hObject is a subobject, the parent object is detected and deleted.

function delete_object(IndexObj)

huvmat=findobj('tag','uvmat');%handles of the uvmat interface
UvData=get(huvmat,'UserData');
hlist_object=findobj(huvmat,'Tag','ListObject');%handles of the object list in the uvmat interface
list_str=get(hlist_object,'String');%objet list
if  ~isempty(UvData) && isfield(UvData, 'ProjObject') && length(UvData.ProjObject)>=IndexObj
    if isfield(UvData.ProjObject{IndexObj},'DisplayHandle') && isfield(UvData.ProjObject{IndexObj}.DisplayHandle,'uvmat')
        hdisplay=UvData.ProjObject{IndexObj}.DisplayHandle.uvmat;%handle of the object graphic representation in uvmat
        for iview=1:length(hdisplay)
            if ishandle(hdisplay(iview)) && ~isequal(hdisplay(iview),0)
                ObjectData=get(hdisplay(iview),'UserData');
                if isfield(ObjectData,'SubObject') && ~isempty(ObjectData.SubObject)
                    delete(ObjectData.SubObject(ishandle(ObjectData.SubObject)));% delete the graphic 'sub-objects (e.g. projection bounds)
                end
                if isfield(ObjectData,'DeformPoint')&& ~isempty(ObjectData.DeformPoint)
                    delete(ObjectData.DeformPoint(ishandle(ObjectData.DeformPoint)));% delete the graphic deformation points
                    delete(hdisplay(iview))% delete the main graphic representation of the object
                end
            end
            ishandle(hdisplay(iview))
        end
        for iobj=IndexObj+1:length(UvData.ProjObject)
            hdisplay=UvData.ProjObject{iobj}.DisplayHandle.uvmat;%handle of the object drawing
            for iview=1:length(hdisplay)
                if ishandle(hdisplay(iview)) && ~isequal(hdisplay(iview),0)
                    PlotData=get(hdisplay(iview),'UserData');
                    PlotData.IndexObj=iobj-1;
                    set(hdisplay(iview),'UserData',PlotData);
                end
            end
        end
    end
    UvData.ProjObject(IndexObj)=[];
end
if numel(list_str)>=IndexObj
    list_str(IndexObj)=[];
end
set(huvmat,'UserData',UvData);
set(hlist_object,'String',list_str)
set(hlist_object,'Value',length(list_str))
hlist_object_1=findobj(huvmat,'Tag','ListObject_1');%handles of the first object list in the uvmat interface
old_index=get(hlist_object_1,'Value');
set(hlist_object_1,'String',list_str)
if IndexObj<=old_index
    set(hlist_object_1,'Value',old_index-1)
end



% --------------------------------------------------------------------
% --- Executes on button press in CheckTable.
% --------------------------------------------------------------------
function CheckTable_Callback(hObject, eventdata, handles)
if get(handles.CheckTable,'Value')
    set(handles.TableDisplay,'Visible','on')
else
    set(handles.TableDisplay,'Visible','off')
end





