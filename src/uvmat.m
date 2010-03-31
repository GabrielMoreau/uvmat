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
% visualize, or Matlab structure representing  netcdf fields (with fields
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
% Information stored on the interface:
%    'Strings' of all edit boxes and menus: get(handles.Tag,'String')
%    'Values' of all menus and toggle buttons: get(handles.Tag,'Value')
%     Matlab structure stored as 'UserData' of the figure uvmat.fig,(can be obtained by right mouse click on the interface).
%          It contains the following fields:
%     - Fixed specifiacation of plotting figures and axes (defined bu uvmat_OpeningFcn) 
%          .PosColorbar: [0.8210 0.4710 0.0190 0.4450]; specified position of the colorbar on figures
%     - Information read in the documentation open of a series (activated by RootPath_Callback) :
%          .XmlData, with fields:
%               .Time: matrix of times of the images with index i and j
%               .GeometryCalib: [1x1 struct]
%     - Information defined from the interface:
%           .NewSeries: =1 when the first view of a new field series is displayed, else 0
%           .filename:(char string)
%           .VelType:(char string) type of velocity field selected
%           .VelType_1:(char string)  REMPLACER LE CELL ACTUEL
%           .FieldName: (char string) main field selected('image', 'velocity'...)
%           .FieldName_1:(char string) second field selected('image', 'velocity'...)
%           .CName: (char string)name of the scalar used for vector colors
%           .CoordType: (char string) coordinate transform: e.g. 'phys' or 'px'
%           .MouseAction: store the current effect of mouse button (create or edit objects)
%     - Information on  projection objects
%           .Object: {[1x1 struct]}
%           .CurrentObjectIndex: index of the projection object .Object currently selected for editing
%     -Information on the current field (Field{i})
%            .Txt : text information to display (e.g. error message)
%            .NbDim: number of dimensions (=0 by default)
%            .NbCoord: number of vector components
%            .CoordType: expresses the type of coordinate ('px' for image, 'sig' for instruments, or 'phys')
%            .dt: time interval for the corresponding image pair
%            .Mesh: estimated typical distance between vectors
%            .ZMax:
%            .ZMin: 
%            .X, .Y, .Z: set of vector coordinates 
%            .U,.V,.W: corresponding set of vector components
%            .F: corresponding set of warning flags
%            .FF: corresponding set of false flags, =0 for good vectors
%            .C: corresponding values of the scalar used for vector color
%             (.X, .Y, .Z,.U,.V,.W,.F,.FF,.C are matlab vectors of the same length,
%                     equal to the number of vectors stored in the input open)
%            .CName: name of the scalar .C
%            .CType: type of the scalar .C, setting how the scalar is obtained (see 'Scalars' below)
%            .A image or scalar 
%            .AX: vector of dimension 2 representing the first and last values
%              of the X coordinates for the image or scalar known on a regular grid,
%              or vector of dimension .A for a scaler defined on irregular grid.
%            .AY: same as .AX along the Y direction
%            .AName: name of the scalar, ='image' for an image

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   DATA FLOW  (for run0_Callback) %%%%%%%%%%%%%%%%%%%%:
%
%               Main input open   second input open(_1)        second image (pair animation) 
% read_ncfield.m         |                 |                             
% read image.m           |                 |                                                
%                     Field{1}         Field{2}               
%                                                                         |
% coord transform (phys.m) or other user defined  fct acting on Field{i}  |
%                                                                   Field{i}
%                                                                    |
% calc_field.m: calculate scalar or other derived fields (vort, div..).
%
% sub_field.m: combine the input Field{i} in a single set of fields (vector + scalar):
%              Field{i=1->3}.X --> UvData.X                          |
%                                                                    |
%                                                                 UvData
%                                                                    |
% plot histograms of the whole  field
% proj_field.m: project the set of fields on the current projection objects defined by UvData.Object
%                                                                    |                                                                          |
%                                                                ObjectData
%                                                                    |
% plot_field.m: plot the projected fields and store them as user     |
% data of the plotting axes                                          |
%                                                                    |
%                                                                AxeData
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
%by the fuction calc_scal after the coordinate transform or after projection on an edit
     
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
%     AxeData.Drawing  = create: create a new edit 
%                       = deform: modify an existing edit by moving its defining create
%                      = off: no current drawing action
%                     = translate: translate an existing edit
%                    = zoom: isolate a subregion for zoom in=1 if an edit is being currently drawn, 0 else (set to 0 by releasing mouse button)
%            .hset_edit=handle of the set_edit interface (if a projection edit is edited);
%            .CurrentOrigin: Origin of a curently drawn edit
%            .CurrentLine: currently drawn menuline (A REVOIR)
%            .CurrentObject: handle of the currently drawn edit
%            .CurrentRectZoom: current rectangle used for zoom
%            .zoomon : zoom state (a revoir)
%            .X, .Y, .Z: array of coordinates defining the position of the vector: ASSOCIER AU PLAN (OBJET) PLUTOT QU'A L'AXE ?
%            .U, .V, .W: array of components of the vector
%            .C:
%            .F:
%            .FF:
%            .A

% Properties attached to projection objects (create, menuline, menuplane...):
%    'Tag'='proj_edit': for all projection objects
%    ObjectData.Style=...: style of projection edit:
%              .ProjMode
%              .Coord: defines the position of the edit
%              .XMin,YMin....
%              .XMax,YMax....
%              .DX,DY,DZ
%              .Phi, .Theta, .Psi : Euler angles
%              .X,.Y,.U,.V.... : field data projected on the edit
%              .IndexObj: index in the list of UvData.Object
           %during plotting
%               .plotaxes: handles of the current axes used to plot the  result of field projection on the object
%               .plothandle: vector of handle(s) of the object graphic represnetation in all the opened plotting axes
% To each projection object #iobj, corresponds an axis
% Object{iobj}.plotaxes and nbobj representation graphs  Object{iobj}.plothandles(:) (where nbobj is the
% nbre of current objects opened in uvmat. Note that Object{iobj}.plothandles(iobj)=[] : an object is not represented in its own projection field;
%-------------------------------------------------------------------
%-------------------------------------------------------------------
%  I - MAIN FUNCTION UVMAT (DO NOT MODIFY)
%-------------------------------------------------------------------
%-------------------------------------------------------------------
function varargout = uvmat(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',          mfilename, ...
                   'gui_Singleton',     gui_Singleton, ...
                   'gui_OpeningFcn',    @uvmat_OpeningFcn, ...
                   'gui_OutputFcn',     @uvmat_OutputFcn, ...
                   'gui_LayoutFcn',     [], ...
                   'gui_Callback',      []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    varargout{1:nargout} = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%-------------------------------------------------------------------
% --- Executes just before uvmat is made visible.
function uvmat_OpeningFcn(hObject, eventdata, handles, input )
%-------------------------------------------------------------------
global nb_builtin

% Choose default command menuline output for uvmat
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% set the position of colorbar and ancillary GUIs:
set(hObject,'Units','Normalized')
movegui(hObject,'center')
UvData.PosColorbar=[0.805 0.022 0.019 0.445];
UvData.SetObjectOrigin=[-0.05 -0.03]; %position for set_object
UvData.SetObjectSize=[0.3 0.7];
UvData.CalOrigin=[0.95 -0.03];%position for geometry_calib (TO IMPROVE)
UvData.CalSize=[0.28 1];

%functions for the mouse and keyboard
set(handles.histo_u,'NextPlot','replacechildren');
set(handles.histo_v,'NextPlot','replacechildren');
set(hObject,'KeyPressFcn',{'keyboard_callback',handles})%set keyboard action function
set(hObject,'WindowButtonMotionFcn',{'mouse_motion',handles})%set mouse action functio
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%set mouse click action function
set(hObject,'WindowButtonUpFcn',{'mouse_up',handles}) 
set(hObject,'DeleteFcn',{@closefcn})%

%TRANSFORM menu: loads the information stored in prefdir to initiate the browser and the list of functions
menu_str={'';'phys';'px';'phys_polar'};
nb_builtin=numel(menu_str); %number of functions
path_uvmat=fileparts(which('uvmat'));
addpath(fullfile(path_uvmat,'transform_field'))
fct_handle{1,1}=[];
testexist=zeros(size(menu_str'));%default
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

%refresh projection plane
UvData.Object{1}.Style='plane';%main plotting plane
UvData.Object{1}.ProjMode='projection';%main plotting plane
if ~isfield(UvData.Object{1},'plotaxes')
    UvData.Object{1}.plotaxes=handles.axes3;%default plotting axis
    set(handles.list_object_1,'Value',1);
    set(handles.list_object_1,'String',{'1-PLANE'});
end

%load the list of previously browsed files in menus Open and Open_1
 dir_perso=prefdir; % path to the directory .matlab for personal data
 profil_perso=fullfile(dir_perso,'uvmat_perso.mat');% personal data file uvmauvmat_perso.mat' in .matlab
 if exist(profil_perso,'file')
      h=load (profil_perso);
      if isfield(h,'MenuFile_1')
          set(handles.MenuFile_1,'Label',h.MenuFile_1);
          set(handles.MenuFile_1_1,'Label',h.MenuFile_1);
      end
      if isfield(h,'MenuFile_1')
          set(handles.MenuFile_2,'Label',h.MenuFile_2);
          set(handles.MenuFile_2_1,'Label',h.MenuFile_2);
      end
      if isfield(h,'MenuFile_1')
          set(handles.MenuFile_3,'Label',h.MenuFile_3);
          set(handles.MenuFile_3_1,'Label',h.MenuFile_3);
      end
      if isfield(h,'MenuFile_1')
          set(handles.MenuFile_4,'Label',h.MenuFile_4);
          set(handles.MenuFile_4_1,'Label',h.MenuFile_4);
      end
      if isfield(h,'MenuFile_1')
          set(handles.MenuFile_5,'Label',h.MenuFile_5);
          set(handles.MenuFile_5_1,'Label',h.MenuFile_5);
      end
      if isfield(h,'transform_fct') && iscell(h.transform_fct)
         for ilist=1:length(h.transform_fct);
             [path,file]=fileparts(h.transform_fct{ilist});
             addpath(path)
             if exist(file,'file')
                h_func=str2func(file);
                testexist=[testexist 1]; %#ok<AGROW>
             else
                h_func=[];
                testexist=[testexist 0];  %#ok<AGROW>
             end
             fct_handle=[fct_handle; {h_func}];%#ok<AGROW> %concatene the list of paths
             rmpath(path)
             menu_str=[menu_str; {file}]; %#ok<AGROW>
         end
      end
 end
menu_str=menu_str(testexist==1);%=menu_str(testexist~=0)
fct_handle=fct_handle(testexist==1);
menu_str=[menu_str;{'more...'}];
set(handles.transform_fct,'String',menu_str)
set(handles.transform_fct,'UserData',fct_handle)% store the list of path in UserData of ACTION
 
%initiates menu of vector colors 
list_menu=calc_field;
%list_menu=[{'ima_cor'};{'black'};{'white'};list_menu(3:end)];
set(handles.col_vec,'String',list_menu)

%check the path and date of modification of all functions in uvmat
path_to_uvmat=which ('uvmat');% check the path detected for source file uvmat
[errormsg,date_str]=check_functions;%check the path of the functions called by uvmat.m
date_str=['last modification: ' date_str];
%case of an input argument for uvmat
testinputfield=0;
inputfile=[];
Field=[];
if exist('input','var')
    if ~isempty(errormsg)
        msgbox_uvmat('WARNING',errormsg)
    end
    if ishandle(handles.UVMAT_title)
        delete(handles.UVMAT_title)
    end   
    if isstruct(input)
        if isfield(input,'InputFile')
            inputfile=input.InputFile;
        end
        Field=input;
    elseif ischar(input)% file name introduced as input
           inputfile=input;
    elseif isnumeric(input)%simple matrix introduced as input
        sizinput=size(input);
        if sizinput(1)<=1 || sizinput(2)<=1
            msgbox_uvmat('ERROR','bad input for uvmat: file name, structure or numerical matrix accepted')
            return
        end
        Field.ListVarName={'A','coord_y','coord_x'};
        Field.VarDimName={{'coord_y','coord_x'},'cord_y','coord_x'};
        Field.A=input;
        Field.coord_x=[0.5 size(input,2)-0.5];
        Field.coord_y=[size(input,1)-0.5 0.5];
    end
    if ~isempty(inputfile)
        display_file_name(hObject, eventdata, handles,inputfile)
        testinputfield=1;
    else
        UvData.TestInputFile=0;
    end
    if ~isempty(Field)
        set(handles.Fields,'Value',1)
        set(handles.Fields,'String',{'get_field...'})    
       % set(handles.Fields,'UserData',Field)
        testinputfield=1;
        
        % set the colorbar position on the interface:
        UvData.PosColorbar=[0.805 0.022 0.019 0.445];
    elseif ischar(input)
        scan_i_Callback(handles.scan_i, eventdata, handles);        
    end
else
   if ishandle(handles.UVMAT_title)
       fid=fopen('revision.log');
       if fid~=-1
        a=textscan(fid,'%s%s%s',1,'HeaderLines',1,'Delimiter','|');
        set(handles.UVMAT_title,'String',[{'Copyright Joel Sommeria, 2008, Coriolis/ LEGI / CNRS-UJF-INPG';'GNU General Public License'; path_to_uvmat; ['at revision ' a{1}{1}]};a{3}{1};date_str;errormsg]);
        fclose(fid);
       else
           set(handles.UVMAT_title,'String',[{'Copyright Joel Sommeria, 2008, Coriolis/ LEGI / CNRS-UJF-INPG';'GNU General Public License'; path_to_uvmat;date_str};errormsg]);
       end
   end
end
UvData.NewSeries=1;
set(hObject,'UserData',UvData)
if testinputfield
    %delete drawn objects
    hother=findobj(handles.axes3,'Tag','proj_object');%find all the proj objects
    for iobj=1:length(hother)
        delete_object(hother(iobj))
    end  
    if isempty(inputfile)
        errormsg=refresh_field(handles,[],[],[],[],[],[],{Field});
        set(handles.MenuTools,'Enable','on')
        set(handles.OBJECT_txt,'Visible','on')
        set(handles.edit,'Visible','on')
        set(handles.list_object_1,'Visible','on')
        set(handles.frame_object,'Visible','on')
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',errormsg)
        end
    else
        update_rootinfo(hObject,eventdata,handles);
    end
end
set_vec_col_bar(handles) %update the display of color code for vectors

%-------------------------------------------------------------------
% --- Outputs from this function are returned to the command menuline.
function varargout = uvmat_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;% the only output argument is the handle to the GUI figure

%-------------------------------------------------------------------
%-------------------------------------------------------------------
% II - FUNCTIONS FOR INTRODUCING THE INPUT FILES
% automatically sets the global properties when the rootfile name is introduced
% then activate the view-field action if selected
% it is activated either by clicking on the RootPath window or by the 
% browser 
%------------------------------------------------------------------
%------------------------------------------------------------------

% --- Executes on the menu Open/Browse...
% search the files, recognize their type according to their name and fill the rootfile input windows
function MenuBrowse_Callback(hObject, eventdata, handles)
oldfile=read_file_boxes(handles);

if isempty(oldfile)||isequal(oldfile,'') %loads the previously stored file name and set it as default in the file_input box
         dir_perso=prefdir;
         profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
         if exist(profil_perso,'file')
              h=load (profil_perso);
             if isfield(h,'MenuFile_1')
                  oldfile=h.MenuFile_1;
             end
         end
end
[FileName, PathName] = uigetfile( ...
       {'*.xml;*.xls;*.civ;*.png;*.jpg;*.tif;*.avi;*.AVI;*.vol;*.nc;*.cmx;*.fig;*.log;*.dat;*.bat;', ' (*.xml,*.xls,*.civ,*.jpg ,*.png, .tif, *.avi,*.vol,*.nc,*.cmx ,*.fig,*.log,*.dat,*.bat)';
       '*.xml',  '.xml files '; ...
        '*.xls',  '.xls files '; ...
        '*.civ',  '.civ files '; ...
        '*.jpg',' jpeg image files'; ...
        '*.png','.png image files'; ...
        '*.tif','.tif image files'; ...
        '*.avi;*.AVI','.avi movie files'; ...
        '*.vol','.volume images (png)'; ...
        '*.nc','.netcdf files'; ...
        '*.cdf','.netcdf files'; ...
        '*.cmx','.cmx text files';...
        '*.cmx2','.cmx2 text files';...
        '*.fig','.fig files (matlab fig)';...
        '*.log','.log text files ';...
        '*.dat','.dat text files ';...
        '*.bat','.bat system command text files';...
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file',oldfile);
%global filebase
fileinput=[PathName FileName];%complete file name 
testblank=findstr(fileinput,' ');%look for blanks
if ~isempty(testblank)
    msgbox_uvmat('ERROR',['The input file name ' fileinput ' contains blank character : This is not allowed. Please change name'])
    return
end
sizf=size(fileinput);
if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end

% display the selected field and related information
display_file_name(hObject, eventdata, handles,fileinput)

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
set(handles.MenuFile_1_1,'Label',MenuFile_1)
set(handles.MenuFile_2_1,'Label',MenuFile_2)
set(handles.MenuFile_3_1,'Label',MenuFile_3)
set(handles.MenuFile_4_1,'Label',MenuFile_4)
set(handles.MenuFile_5_1,'Label',MenuFile_5)
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-append'); %store the file names for future opening of uvmat
else
    txt=ver;
    Release=txt(1).Release;
    relnumb=str2double(Release(3:4));
    if relnumb >= 14
        save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-V6'); %store the file names for future opening of uvmat
    else
        save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5'); %store the file names for future opening of uvmat
    end
end

% --------------------------------------------------------------------
function MenuFile_1_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_1,'Label');
display_file_name(hObject, eventdata, handles,fileinput)

% --------------------------------------------------------------------
function MenuFile_2_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_2,'Label');
display_file_name(hObject, eventdata, handles,fileinput)

% --------------------------------------------------------------------
function MenuFile_3_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_3,'Label');
display_file_name(hObject, eventdata, handles,fileinput)

% --------------------------------------------------------------------
function MenuFile_4_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_4,'Label');
display_file_name(hObject, eventdata, handles,fileinput)

% --------------------------------------------------------------------
function MenuFile_5_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_5,'Label');
display_file_name(hObject, eventdata, handles,fileinput)

%----------------------------------------------------------------- 
% fills the edit boxes RootPath, RootFile,NomType...from an input file name 'fileinput'
%----------------------------------------------------------------
function display_file_name(hObject, eventdata, handles,fileinput)
if ~exist(fileinput,'file')
    msgbox_uvmat('ERROR',['input file ' fileinput  ' does not exist'])
    return
end
[RootPath,RootFile,i1,i2,str_a,str_b,ext,NomType,SubDir]=name2display(fileinput);
ext_test=''; %default
if ~isempty(ext) 
    form=imformats(ext(2:end));%test valid Matlab image formats
    if ~isempty(form)
        ext_test='.image';
        imainfo=imfinfo(fileinput);  
        if length(imainfo) >1 %case of image with multiple frames
            i1='1'; % set the frame counter to 1 by default
            i2='';
            str_a='';
            str_b='';
            NomType='*'; %indicate a set of indexed frames within a single file
            [RootPath,RootFile]=fileparts(fileinput); %include the indices in the root file
        end
    elseif isequal(lower(ext),'.avi')
        ext_test='.image';
        i1='1'; % set the frame counter to 1 by default
        i2='';
        str_a='';
        str_b='';
        NomType='*'; %indicate a set of indexed frames within a single file
        [RootPath,RootFile]=fileparts(fileinput); %include the indices in the root file
    else
        ext_test=lower(ext);
    end
end
switch ext_test
    case {'.civ','.log','.cmx','.cmx2','.txt','.bat'}  %display text file
        edit(fileinput)  
    case '.fig'                           %display matlab figure
        hfig=open(fileinput);
        set(hfig,'WindowButtonMotionFcn','mouse_motion')%set mouse action functio
        set(hfig,'WindowButtonUpFcn','mouse_up')%set mouse click action function
        set(hfig,'WindowButtonUpFcn','mouse_down')%set mouse click action function
    case {'.xml','.xls'}                % edit xml or Excel files
       editxml(fileinput);
    case {'.avi','.image','.vol','.nc','.cdf'}    
        set(handles.RootPath,'String',RootPath);
        if  isequal(SubDir,'')
            rootname=fullfile(RootPath,RootFile);
        else
            rootname=fullfile(RootPath,SubDir,RootFile);
            SubDir=['/' SubDir]; %display the separator
        end
        set(handles.SubDir,'String',SubDir);
        set(handles.RootFile,'String',['/' RootFile]); %display the separator
        indices=fileinput(length(rootname)+1:end);
        indices(end-length(ext)+1:end)=[]; %remove extension
        set(handles.FileIndex,'String',indices);        
        set(handles.FileIndex,'UserData',NomType);
        set(handles.FileExt,'String',ext);
        % fill file index counters
        set(handles.i1,'String',i1);    
        set(handles.i2,'String',i2);
        set(handles.j1,'String',str_a);
        set(handles.j2,'String',str_b);
        
        % synchronise indices of the second  input file if it exists
        if get(handles.SubField,'Value')==1% if the subfield button is activated, update the field numbers
            [ff,rr,FileBase_1,ii,FileExt_1,SubDir_1]=read_file_boxes_1(handles);
            NomType_1=get(handles.FileIndex_1,'UserData');     
            FileName_1=name_generator(FileBase_1,stra2num(i1),stra2num(i2),FileExt_1,NomType_1,1,stra2num(str_a),stra2num(str_b),SubDir_1);
            if exist(FileName_1,'file')
                FileIndex_1=name_generator('',stra2num(i1),stra2num(i2),'',NomType_1,1,stra2num(str_a),stra2num(str_b),'');
                set(handles.FileIndex_1,'String',FileIndex_1)
            else
                set(handles.SubField,'Value',0)
                SubField_Callback(hObject, eventdata, handles)
            end
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
        set(handles.OBJECT_txt,'Visible','on')
        set(handles.edit,'Visible','on')
        set(handles.list_object_1,'Visible','on')
        set(handles.frame_object,'Visible','on')
         % initiate input file: 
        update_rootinfo(hObject,eventdata,handles);  
    otherwise
       msgbox_uvmat('ERROR',['invalid input file extension' ext])
end

%-------------------------------------------------------------------
function RootPath_Callback(hObject,eventdata,handles)
update_rootinfo(hObject,eventdata,handles);

%-------------------------------------------------------------------
%-- called by action in RootFile edit box
%-------------------------------------------------------------------
function SubDir_Callback(hObject, eventdata, handles)
%refresh the menu of input fields
Fields_Callback(hObject, eventdata, handles);
% refresh the current field
run0_Callback(hObject, eventdata, handles); 


%-------------------------------------------------------------------
%-- called by action in RootFile edit box
%-------------------------------------------------------------------
function RootFile_Callback(hObject, eventdata, handles)
update_rootinfo(hObject,eventdata,handles)






%-------------------------------------------------------------------
% -- update information about a new field series (indices to scan, timing, calibration from an xml file, then refresh current plots
%-------------------------------------------------------------------
function update_rootinfo(hObject,eventdata,handles)

set(handles.RootPath,'BackgroundColor',[1 1 0])
drawnow
set(handles.Fields,'UserData',[])% reinialize data from uvmat opening
UvData=get(handles.uvmat,'UserData');%huvmat=handles of the uvmat interface
UvData.NewSeries=1; %flag for run0: begin a new series
UvData.TestInputFile=1;
set(handles.fix_pair,'Value',0) % desactivate by default the comp_input '-'input window
%FileIndex_Callback(hObject, eventdata, handles)% update field counters

[FileName,RootPath,FileBase,FileIndices,FileExt,SubDir]=read_file_boxes(handles);
if ~exist(FileName,'file')
   msgbox_uvmat('ERROR',['input file ' FileName ' not found']);
    return
end
nbfield=[];%default
nburst=[];%default

% read timing and total frame number from the current file (movie files) !! may be overrid by xml file
XmlData.Time=[];%default
XmlData.GeometryCalib=[];%default
TimeUnit=[];%default
testima=0; %test for image input
if isequal(lower(FileExt),'.avi') %.avi file
    testima=1;
    info=aviinfo([FileBase FileIndices FileExt]);
    nbfield=info.NumFrames;
    nburst=1;
    set(handles.Dt_txt,'String',['Dt=' num2str(1000/info.FramesPerSecond) 'ms']);%display the elementary time interval in millisec
    XmlData.Time=(0:1/info.FramesPerSecond:(info.NumFrames-1)/info.FramesPerSecond)';
    TimeUnit='s';
    set(handles.npx,'String',num2str(info.Width));%fills nbre of pixels x box
    set(handles.npy,'String',num2str(info.Height));%fills nbre of pixels y box
    hhh=which('mmreader');
    if ~isequal(hhh,'')&& mmreader.isPlatformSupported()% if the function is found (recent version of matlab)
        UvData.MovieObject=mmreader([FileBase FileIndices FileExt]);
    end
elseif ~isempty(imformats(FileExt(2:end))) || isequal(FileExt,'.vol')%&& isequal(NomType,'*')% multi-frame image
    testima=1;
    if ~isequal(SubDir,'')
       RootFile=get(handles.RootFile,'String');
        imainfo=imfinfo([fullfile(RootPath,SubDir,RootFile) FileIndices FileExt]);
    else
        imainfo=imfinfo([FileBase FileIndices FileExt]);
    end
    if length(imainfo) >1 %case of image with multiple frames
        nbfield=length(imainfo);
        nburst=1;
    end 
    if isfield(UvData,'MovieObject')
        UvData=rmfield(UvData,'MovieObject');
    end
else 
    %set(handles.last_i,'String','');%fills last_field box
    set(handles.npx,'String','');%fills nbre of pixels x box
    set(handles.npy,'String','');%fills nbre of pixels y box
    if isfield(UvData,'MovieObject')
        UvData=rmfield(UvData,'MovieObject');
    end
end

% read parameters (time, geometric calibration..) from a documentation file (.xml advised)
filexml=[FileBase '.xml'];
fileciv=[FileBase '.civ'];
warntext='';%default warning message
NbSlice=1;%default

if exist(filexml,'file')
    set(handles.view_xml,'Visible','on')
    set(handles.view_xml,'BackgroundColor',[1 1 0])
    set(handles.RootPath,'BackgroundColor',[1 1 1])
    set(handles.view_xml,'String','view .xml')
    drawnow
    [XmlData,warntext]=imadoc2struct(filexml);
    if ~isempty(warntext)
        msgbox_uvmat('WARNING',warntext)
    end
    if isfield(XmlData,'TimeUnit')
        if isfield(XmlData,'TimeUnit')&& ~isempty(XmlData.TimeUnit)
            TimeUnit=XmlData.TimeUnit;
        end
    end
    set(handles.view_xml,'BackgroundColor',[1 1 1])
    drawnow
elseif exist(fileciv,'file')% if .civ file found 
    [error,XmlData.Time,TimeUnit,mode,npx,npy,pxcmx,pxcmy]=read_imatext([FileBase '.civ']);
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
    set(handles.npx,'String',num2str(npx));%fills nbre of pixels x box
    set(handles.npy,'String',num2str(npy));%fills nbre of pixels y box
    set(handles.pxcm,'String',num2str(pxcmx));%fills scale x (pixel/cm) box
    set(handles.pycm,'String',num2str(pxcmy));%fills scale y (pixel/cm) box
    set(handles.pxcm,'Visible','on');%fills scale x (pixel/cm) box 
    set(handles.pycm,'Visible','on');%fills scale y (pixel/cm) box 
    set(handles.view_xml,'Visible','on')   
    set(handles.view_xml,'String','view .civ')
else
    set(handles.view_xml,'Visible','off')
end

% store last index in handles.lat_i and .last_j
if ~isempty(XmlData.Time)
    nbfield=size(XmlData.Time,1);
    nburst=size(XmlData.Time,2);
end
last_i_cell=get(handles.last_i,'String');
if isempty(nbfield)
    last_i_cell{1}='';
else
    last_i_cell{1}=num2str(nbfield);
end
set(handles.last_i,'String',last_i_cell)
last_j_cell=get(handles.last_j,'String');
if isempty(nburst)
     last_j_cell{1}='';
else
     last_j_cell{1}=num2str(nburst);
end
set(handles.last_j,'String',last_j_cell);

% store geometric calibration in UvData
if isfield(XmlData,'GeometryCalib')
    GeometryCalib=XmlData.GeometryCalib;
    if isempty(GeometryCalib)
        set(handles.pxcm,'String','')
        set(handles.pycm,'String','')
        set(handles.transform_fct,'Value',1); %  no transform by default
    else
        if (isfield(GeometryCalib,'R')& ~isequal(GeometryCalib.R(2,1),0) & ~isequal(GeometryCalib.R(1,2),0)) |...
            (isfield(GeometryCalib,'kappa1')& ~isequal(GeometryCalib.kappa1,0))
            set(handles.pxcm,'String','var')
            set(handles.pycm,'String','var')
        else
            pixcmx=GeometryCalib.f*GeometryCalib.R(1,1)*GeometryCalib.sx/(GeometryCalib.Tz*GeometryCalib.dpx);
            pixcmy=GeometryCalib.f*GeometryCalib.R(2,2)/(GeometryCalib.Tz*GeometryCalib.dpy);
            set(handles.pxcm,'String',num2str(pixcmx))
            set(handles.pycm,'String',num2str(pixcmy))
        end
        set(handles.transform_fct,'Value',2); % phys transform by default
        if isfield(GeometryCalib,'SliceCoord')
           siz=size(GeometryCalib.SliceCoord);
           if siz(1)>1
               NbSlice=siz(1);
               set(handles.slices,'Visible','on')
               set(handles.slices,'Value',1)
           end
           if isfield(GeometryCalib,'NbSlice') && isequal(GeometryCalib.NbSlice,'volume')
               set(handles.nb_slice,'String','volume')
           else
               set(handles.nb_slice,'String',num2str(NbSlice))
           end
           slices_Callback(hObject, eventdata, handles)
    %        Coord=UvData.XmlData.GeometryCalib.SliceCoord;
    %        ZIndex=num_i1-NbSlice*(floor((num_i1-1)/NbSlice));
        end

            
    end
end

%update the data attached to the uvmat interface
% set(handles.nb_slice,'String',num2str(NbSlice)) 
if ~isempty(TimeUnit)
    set(handles.time_txt,'String',['time (' TimeUnit ')'])
end
%set(handles.DtUnit,'String',['10^(-3)' TimeUnit])
UvData.TimeUnit=TimeUnit;
UvData.XmlData=XmlData;
UvData.NewSeries=1;
set(handles.uvmat,'UserData',UvData)

%display warning message
if ~isequal(warntext,'')
    msgbox_uvmat('WARNING',warntext);
end

% set default options in menu 'Fields'
if testima
   set(handles.Fields,'Value',1) % set menu to 'image'
   set(handles.Fields,'String',{'image';'get_field...';'velocity';'vort';'div';'more...'})
elseif isequal(FileExt,'.nc')||isequal(FileExt,'.cdf')
   Data=nc2struct(FileName,'ListGlobalAttribute','absolut_time_T0','civ');
   col_vec=get(handles.col_vec,'String');
   if ~isempty(Data.absolut_time_T0)&& ~isequal(Data.civ,0)
       set(handles.Fields,'String',{'image';'get_field...';'velocity';'vort';'div';'more...'})
       set(handles.Fields,'Value',3) % set menu to 'velocity'
       col_vec{1}='ima_cor';
   else %general netcdf file (not civx)
       set(handles.Fields,'Value',1) % set menu to 'get_field...
       set(handles.Fields,'String',{'get_field...'})
       col_vec{1}='get_field...';
   end
   set(handles.col_vec,'String',col_vec)
else
    msgbox_uvmat('ERROR',['invalid input file extension ' FileExt])
    return
end  

% set index navigation options and refresh plots
set(handles.RootPath,'BackgroundColor',[1 1 1])
drawnow
set_scan_options(hObject, eventdata, handles)


%-------------------------------------------------------------------
%-- set index navigation options for new series input and refresh plot
%-------------------------------------------------------------------
function set_scan_options(hObject, eventdata, handles)

%  set the corresponding index navigation options (TO CHECK WITH THE SECOND FIELD)
NomType=get(handles.FileIndex,'UserData');
NomType_1=get(handles.FileIndex_1,'UserData');
state_j='off'; %default
scan_option='i';
switch NomType
    case {'_i_j','_i_j1-j2','_i1-i2_j','#_ab'},% two navigation indices
        state_j='on';
        if exist('nbfield','var') && isequal(nbfield,1)
            scan_option='j'; 
        else
            scan_option='i';                
        end 
end
if ~isempty(NomType_1)
    switch NomType_1
        case {'_i_j','_i_j1-j2','_i1-i2_j','#_ab'},% two navigation indices
            state_j='on';
            if exist('nbfield','var') && isequal(nbfield,1)
                scan_option='j'; 
            else
                scan_option='i';                
            end 
    end
end
if isequal(scan_option,'i')
     set(handles.scan_i,'Value',1)
     scan_i_Callback(hObject, eventdata, handles); 
else
     set(handles.scan_j,'Value',1)
     scan_j_Callback(hObject, eventdata, handles); 
end
set(handles.scan_j,'Visible',state_j)
set(handles.j1,'Visible',state_j)
set(handles.j2,'Visible',state_j)
set(handles.last_j,'Visible',state_j);
set(handles.frame_j,'Visible',state_j);
set(handles.j_text,'Visible',state_j);

% view the field  
run0_Callback(hObject, eventdata, handles); %view field
mask_test=get(handles.mask_test,'value');
if mask_test
    MaskData=get(handles.mask_test,'UserData');
    if isfield(MaskData,'maskhandle') && ishandle(MaskData.maskhandle)
          delete(MaskData.maskhandle)    %delete old mask
    end
    mask_test_Callback(hObject, eventdata, handles)
end

%-------------------------------------------------------------------
function MenuBrowse_1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
% huvmat=get(handles.run0,'parent');
UvData=get(handles.uvmat,'UserData');

RootPath=get(handles.RootPath,'String');
[FileName, PathName, filterindex] = uigetfile( ...
       {'*.xml;*.xls;*.civ;*.jpg;*.png;*.avi;*.AVI;*.nc;*.cmx;*.fig;*.log;*.dat', ' (*.xml,*.xls,*.civ, *.jpg,*.png, *.avi,*.nc,*.cmx ,*.fig,*.log,*.dat)';
       '*.xml',  '.xml files '; ...
        '*.xls',  '.xls files '; ...
        '*.civ',  '.civ files '; ...
        '*.jpg','.jpg image files'; ...
        '*.png','.png image files'; ...
        '*.avi;*.AVI','.avi movie files'; ...
        '*.nc','.netcdf files'; ...
        '*.cdf','.netcdf files'; ...
        '*.cmx','.cmx text files';...
        '*.cmx2','.cmx2 text files';...
        '*.fig','.fig files (matlab fig)';...
        '*.log','.log text files ';...
        '*.dat','.dat text files ';...
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file',RootPath);
fileinput_1=[PathName FileName];%complete file name 
testblank=findstr(fileinput_1,' ');%look for blanks
if ~isempty(testblank)
    msgbox_uvmat('ERROR',['The input file name ' fileinput_1 ' contains blank character : This is not allowed. Please change name'])
    return
end
sizf=size(fileinput_1);
if (~ischar(fileinput_1)|~isequal(sizf(1),1)),return;end

% refresh the current displayed field
display_file_name_1(hObject,eventdata,handles,fileinput_1)

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

% --------------------------------------------------------------------
function MenuFile_1_1_Callback(hObject, eventdata, handles)
fileinput_1=get(handles.MenuFile_1_1,'Label');
display_file_name_1(hObject,eventdata,handles,fileinput_1)

% --------------------------------------------------------------------
function MenuFile_2_1_Callback(hObject, eventdata, handles)
fileinput_1=get(handles.MenuFile_2_1,'Label');
display_file_name_1(hObject,eventdata,handles,fileinput_1)

% --------------------------------------------------------------------
function MenuFile_3_1_Callback(hObject, eventdata, handles)
fileinput_1=get(handles.MenuFile_3_1,'Label');
display_file_name_1(hObject,eventdata,handles,fileinput_1)

% --------------------------------------------------------------------
function MenuFile_4_1_Callback(hObject, eventdata, handles)
fileinput_1=get(handles.MenuFile_4_1,'Label');
display_file_name_1(hObject,eventdata,handles,fileinput_1)

% --------------------------------------------------------------------
function MenuFile_5_1_Callback(hObject, eventdata, handles)
fileinput_1=get(handles.MenuFile_5_1,'Label');
display_file_name_1(hObject,eventdata,handles,fileinput_1)

%----------------------------------------------------------------- 
% fills the edit boxes RootPath, RootFile,NomType...from an input file name 'fileinput'
%----------------------------------------------------------------
function display_file_name_1(hObject,eventdata,handles,fileinput_1)

%[path,name,ext]=fileparts(fileinput_1);
[RootPath_1,RootFile_1,field_count,str2,str_a,str_b,FileExt_1,NomType_1,SubDir_1]=name2display(fileinput_1);
nbfield_1=1; %default
ext_test=FileExt_1;%default
form=imformats(FileExt_1(2:end));
if ~isempty(form) % if the extension corresponds to an image format recognized by Matlab
    imainfo=imfinfo(fileinput_1);  
    nbfield_1=length(imainfo);
    ext_test='.image';
elseif isequal(lower(FileExt_1),'.avi')
    info=aviinfo(fileinput_1);
    nbfield_1=info.NumFrames;
    ext_test='.image';
end

%open directly fig or text files 
switch ext_test
    case {'.civ','.log','.cmx','.cmx2','.txt'}  %display text file
        edit(fileinput)  
        return
    case '.fig'                           %display matlab figure
        hfig=open(fileinput);
        set(hfig,'WindowButtonMotionFcn','mouse_motion')%set mouse action functio
        set(hfig,'WindowButtonUpFcn','mouse_up')%set mouse click action function
        set(hfig,'WindowButtonUpFcn','mouse_down')%set mouse click action function
        return
    case {'.xml','.xls'}                % edit xml or Excel files
       heditxml=editxml(fileinput);
       return
    case {'.image','.nc','.cdf'}
%         set(handles.FileIndex,'UserData',NomType_1);
    otherwise
        msgbox_uvmat(['invalid input file extension ' FileExt_1 ' for uvmat'],'ERROR')
        return
end

% test for image series in a single file and synchronise file indices of the two series
if nbfield_1 >1 %case of image with multiple frames
    if nbfield_1 < num_i1
        msgbox_uvmat('ERROR','current frame index beyond the input movie length')
        return
    else
        NomType_1='*'; %indicate a set of indexed frames within a single file
        filename_new=fileinput_1;
    end
else  % cases of data files   
    RootPath=get(handles.RootPath,'String');
    RootFile=get(handles.RootFile,'String');
    FileBase=fullfile(RootPath,RootFile);
    FileBase_1=fullfile(RootPath_1,RootFile_1);
    if isequal(FileBase,FileBase_1)
        filename_new=fileinput_1;
    else        
        num_i1=stra2num(get(handles.i1,'String'));%get the current file indices from counters
        num_j1=stra2num(get(handles.j1,'String'));
        num_i2=stra2num(get(handles.i2,'String'));
        num_j2=stra2num(get(handles.j2,'String'));
        [filename_new,idetect]=...
           name_generator(FileBase_1,num_i1,num_j1,FileExt_1,NomType_1,1,num_i2,num_j2,SubDir_1);%create name with indices synchronised with the first file
        indices=''; %default
        if ~idetect
            msgbox_uvmat('ERROR','second input file with indices corresponding to the first one does not exist')
            return
        end 
    end
end
set(handles.FileIndex,'UserData',NomType_1);

% make visible and fill the second raw of edit boxes
set(handles.RootPath_1,'Visible','on')
set(handles.RootFile_1,'Visible','on')
set(handles.SubDir_1,'Visible','on');
set(handles.FileIndex_1,'Visible','on');
set(handles.FileExt_1,'Visible','on');
[FileName,RootPath,FileBase,FileIndices,FileExt,SubDir]=read_file_boxes(handles);
if isequal(FileBase,FileBase_1)
    set(handles.RootPath_1,'String','"')
    set(handles.RootFile_1,'String','"');
else
    set(handles.RootPath_1,'String',RootPath_1)
    set(handles.RootFile_1,'String',['/' RootFile_1]);
end 
if  isequal(SubDir_1,'')
     set(handles.SubDir_1,'String','');
     FileBaseSub_1=FileBase_1;
else  
    set(handles.SubDir_1,'String',['/' SubDir_1]);
    FileBaseSub_1=fullfile(FileBase_1,SubDir_1);
end
indices=filename_new(length(FileBaseSub_1)+1:end);
indices(end-length(FileExt_1)+1:end)=[]; %remove extension
set(handles.FileIndex_1,'String',indices)
set(handles.FileIndex_1,'UserData',NomType_1)
set(handles.FileExt_1,'String',FileExt_1);

% default choice of fields
if isequal(ext_test,'.image')
   set(handles.Fields_1,'String',{'';'image';'get_field...';'velocity';'vort';'div';'more...'})
   set(handles.Fields_1,'Value',2) % set menu to 'image'
elseif isequal(FileExt_1,'.nc')|isequal(FileExt_1,'.cdf')
   Data=nc2struct(fileinput_1,[]);
   if isfield(Data,'absolut_time_T0')
       set(handles.Fields_1,'String',{'';'image';'get_field...';'velocity';'vort';'div';'more...'})
       set(handles.Fields_1,'Value',4) % set menu to 'velocity'
   else   
       set(handles.Fields_1,'Value',2) % set menu to 'get_field...'
       set(handles.Fields_1,'String',{'';'get_field...'});
   end
end  
set(handles.SubField,'Visible','on')
set(handles.SubField,'Value',1)
RootPath_1_Callback(hObject,eventdata,handles);  


%-----------------------------------------------------
function RootPath_1_Callback(hObject,eventdata,handles)
update_rootinfo_1(hObject,eventdata,handles)

%-------------------------------------------------------------------
function RootFile_1_Callback(hObject, eventdata, handles)
update_rootinfo_1(hObject,eventdata,handles)
%-------------------------------------------------------------------

%-------------------------------------------------------------------
function update_rootinfo_1(hObject,eventdata,handles) %A REVOIR

set(handles.RootPath_1,'BackgroundColor',[1 1 0])% indicate active program by yellow color
drawnow
%huvmat=get(handles.RootPath,'parent');
UvData=get(handles.uvmat,'UserData');%huvmat=handles of the uvmat interface
UvData.NewSeries=1; %flag for run0: begin a new series

[FileName,RootPath,FileBase,FileIndices,FileExt]=read_file_boxes_1(handles);
if ~exist(FileName,'file')
    msgbox_uvmat('ERROR',['input file ' FileName ' not found']);
end
nbfield_1=[];%default
nburst_1=[];%default
XmlData.Time=[];
XmlData.GeometryCalib=[];%default
TimeUnit=[];
if isfield(UvData,'TimeUnit')
    TimeUnit=UvData.TimeUnit;
end
TimeUnit_1=[];
% testima=0; %test for image input
if isequal(lower(FileExt),'.avi') %.avi file
%     testima=1;
    info=aviinfo([FileBase FileIndices FileExt]);
    nbfield_1=info.NumFrames;
    nburst_1=1;
    %set(handles.last_i,'String',num2str(info.NumFrames));%fills last_field box
    set(handles.Dt_txt,'String',['Dt=' num2str(1000/info.FramesPerSecond) 'ms']);%display the elementary time interval in millisec
%     set(handles.dt,'UserData',info.FramesPerSecond);
    time=[0:1/info.FramesPerSecond:(info.NumFrames-1)/info.FramesPerSecond]';
    npx=get(handles.npx,'String');
    npy=get(handles.npy,'String');
    if isequal(npx,'') || isequal(npy,'')
        set(handles.npx,'String',num2str(info.Width));%fills nbre of pixels x box
        set(handles.npy,'String',num2str(info.Height));%fills nbre of pixels y box
    end
elseif ~isempty(imformats(FileExt(2:end))) %&& isequal(NomType,'*')% multi-frame image
    testima=1;
    imainfo=imfinfo([FileBase FileIndices FileExt]);  
    if length(imainfo) >1 %case of image with multiple frames
        nbfield_1=length(imainfo);
        nburst_1=1;
        %set(handles.last_i,'String',num2str(length(imainfo)));%fills last_field box
    end       
else 
    %set(handles.last_i,'String','');%fills last_field box
    set(handles.npx,'String','');%fills nbre of pixels x box
    set(handles.npy,'String','');%fills nbre of pixels y box 
end

% find scaling parameters
filexml=[FileBase '.xml'];
fileciv=[FileBase '.civ'];
warntext='';%default warning text
if exist(filexml,'file')
    [XmlData,warntext]=imadoc2struct(filexml);
    if ~isempty(warntext)
        msgbox_uvmat('WARNING',warntext)
    end
    if isfield(XmlData,'Camera')
%         if isfield(XmlData.Camera,'NbSlice')&& ~isempty(XmlData.Camera.NbSlice)
%             NbSlice=XmlData.Camera.NbSlice;
%         end
        if isfield(XmlData.Camera,'TimeUnit')&& ~isempty(XmlData.Camera.TimeUnit)
            TimeUnit=XmlData.Camera.TimeUnit;
        end
    end 
elseif exist(fileciv,'file')% if .civ file found 
    [error,XmlData.Time,TimeUnit,mode,npx,npy,pxcmx,pxcmy]=read_imatext([FileBase '.civ']);
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
    
    set(handles.npx,'String',num2str(npx));%fills nbre of pixels x box
    set(handles.npy,'String',num2str(npy));%fills nbre of pixels y box
    set(handles.pxcm,'String',num2str(pxcmx));%fills scale x (pixel/cm) box
    set(handles.pycm,'String',num2str(pxcmy));%fills scale y (pixel/cm) box
    set(handles.pxcm,'Visible','on');%fills scale x (pixel/cm) box 
    set(handles.pycm,'Visible','on');%fills scale y (pixel/cm) box 
end   
if ~isempty(TimeUnit_1) && ~isequal(TimeUnit_1,TimeUnit)
        msgbox_uvmat('WARNING','the time units for the second series differs from the first one')
end
        
% store last index in handles.lat_i and .last_j
if ~isempty(XmlData.Time)
    nbfield_1=size(XmlData.Time,1);
    nburst_1=size(XmlData.Time,2);   
end
last_i_cell=get(handles.last_i,'String');
if isempty(nbfield_1)
    last_i_cell{2}='';
else
    last_i_cell{2}=num2str(nbfield_1);
end
set(handles.last_i,'String',last_i_cell)
last_j_cell=get(handles.last_j,'String');
if isempty(nburst_1)
     last_j_cell{2}='';
else
     last_j_cell{2}=num2str(nburst_1);
end
set(handles.last_j,'String',last_j_cell);
if ~isequal(last_i_cell{1},last_i_cell{2}) || ~isequal(last_j_cell{1},last_j_cell{2})
        msgbox_uvmat('WARNING','the numbers of input file of the second series differs from the first one')
end

% store calibration data
GeometryCalib=XmlData.GeometryCalib;
if isempty(GeometryCalib)
    if isfield(UvData, 'GeometryCalib_1')
        UvData=rmfield(UvData,'GeometryCalib_1');
    end
else
    UvData.GeometryCalib_1=GeometryCalib;
    if (isfield(GeometryCalib,'R')& ~isequal(GeometryCalib.R(2,1),0) & ~isequal(GeometryCalib.R(1,2),0)) |...
        (isfield(GeometryCalib,'kappa1')& ~isequal(GeometryCalib.kappa1,0))
        set(handles.pxcm,'String','var')
        set(handles.pycm,'String','var')
    else
        pixcmx=GeometryCalib.f*GeometryCalib.R(1,1)*GeometryCalib.sx/(GeometryCalib.Tz*GeometryCalib.dpx);
        pixcmy=GeometryCalib.f*GeometryCalib.R(2,2)/(GeometryCalib.Tz*GeometryCalib.dpy);
        set(handles.pxcm,'String',num2str(pixcmx))
        set(handles.pycm,'String',num2str(pixcmy))
    end
end
UvData.XmlData_1=XmlData;
set(handles.uvmat,'UserData',UvData)%update the data attached to the uvmat interface

if ~isequal(warntext,'')
    msgbox_uvmat('WARNING',warntext)
end

set(handles.RootPath_1,'BackgroundColor',[1 1 1])% signa the end the input operation
drawnow

set_scan_options(hObject, eventdata, handles)

%---------------------------------------------------
% switch file index scanning options scan_i and scan_j in an exclusive way
function scan_i_Callback(hObject, eventdata, handles)
%---------------------------------------------------
if get(handles.scan_i,'Value')==1
    set(handles.scan_i,'BackgroundColor',[1 1 0])
    set(handles.scan_j,'Value',0)
    set(handles.scan_j,'BackgroundColor',[0.831 0.816 0.784])
else
    set(handles.scan_i,'BackgroundColor',[0.831 0.816 0.784])
    set(handles.scan_j,'Value',1)
    set(handles.scan_j,'BackgroundColor',[1 1 0])
end

%-------------------------------------------------------------------
% switch file index scanning options scan_i and scan_j in an exclusive way
function scan_j_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.scan_j,'Value')==1
    set(handles.scan_j,'BackgroundColor',[1 1 0])
    set(handles.scan_i,'Value',0)
    set(handles.scan_i,'BackgroundColor',[0.831 0.816 0.784])
else
    set(handles.scan_j,'BackgroundColor',[0.831 0.816 0.784])
    set(handles.scan_i,'Value',1)
    set(handles.scan_i,'BackgroundColor',[1 1 0])
end

%-------------------------------------------------------------------
function i1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
% [filebase,num1,num_a,num2,num_b,ext,NomType,subdir]=read_input_file(handles);
%[FileName,RootPath,filebase,xx,FileExt]=read_file_boxes(handles);
NomType=get(handles.FileIndex,'UserData');
num1=stra2num(get(handles.i1,'String'));
num2=stra2num(get(handles.i2,'String'));
num_a=stra2num(get(handles.j1,'String'));
num_b=stra2num(get(handles.j2,'String'));
indices=name_generator('',num1,num_a,'',NomType,1,num2,num_b,'');
set(handles.FileIndex,'String',indices)
if get(handles.SubField,'Value')==1
    NomType_1=get(handles.FileIndex_1,'String');
     FileExt_1=get(handles.FileExt_1,'String');
    [P,F,str1,str2,str_a,str_b,Ext,NomType_1]=name2display(['xx' NomType_1 FileExt_1]);
     indices=name_generator('',num1,num_a,'',NomType_1,1,num2,num_b,'');
     set(handles.FileIndex_1,'String',indices)
end
run0_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------
function i2_Callback(hObject, eventdata, handles)
i1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------

%-------------------------------------------------------------------
function j1_Callback(hObject, eventdata, handles)
i1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------

%-------------------------------------------------------------------
function j2_Callback(hObject, eventdata, handles)
i1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------

%-------------------------------------------------------------------
function slices_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.slices,'Value')==1
    set(handles.slices,'BackgroundColor',[1 1 0])
    set(handles.nb_slice,'Visible','on')
    set(handles.z_text,'Visible','on')
    set(handles.z_index,'Visible','on')
    nb_slice_Callback(hObject, eventdata, handles)
else
    set(handles.nb_slice,'Visible','off')
    set(handles.slices,'BackgroundColor',[0.7 0.7 0.7])
    set(handles.z_text,'Visible','off')
    set(handles.z_index,'Visible','off') 
    set(handles.masklevel,'Value',1)
    set(handles.masklevel,'String',{'1'})
end

%-------------------------------------------------------------------
function nb_slice_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
nb_slice_str=get(handles.nb_slice,'String');
if isequal(nb_slice_str,'volume')
    num=stra2num(get(handles.j1,'String'));
    last_j=get(handles.last_j,'String');
    nbslice=str2double(last_j{1});
else
    num=str2double(get(handles.i1,'String'));
    nbslice=str2double(get(handles.nb_slice,'String'));
end
z=mod(num-1,nbslice)+1;
set(handles.z_index,'String',num2str(z))
for ilist=1:nbslice
    list_index{ilist,1}=num2str(ilist);
end   
set(handles.masklevel,'String',list_index)
set(handles.masklevel,'Value',z)


%-------------------------------------------------------------------
% --- Executes on button press in view_xml.
function view_xml_Callback(hObject, eventdata, handles)
[FileName,RootPath,FileBase,FileIndices,FileExt]=read_file_boxes(handles);
option=get(handles.view_xml,'String');
if isequal(option,'view .xml')
    FileXml=[FileBase '.xml'];
    heditxml=editxml(FileXml);
end

%-------------------------------------------------------------------
% --- Executes on button press in mask_test.
function mask_test_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if isequal(get(handles.mask_test,'Value'),1)
    [FF,RootPath,FileBase]=read_file_boxes(handles);
    num_i1=stra2num(get(handles.i1,'String'));
    num_j1=stra2num(get(handles.j1,'String'));
    currentdir=pwd;  
    cd(RootPath);
    maskfiles=dir('*_*mask_*.png');%look for a mask file
    cd(currentdir);%come back to the working directory
    mdetect=0;
    if isempty(maskfiles)
         msgbox_uvmat('ERROR','no mask file detected (format ..._xxmask_ii.png needed), use the menu bar Tools/Make mask')
         return
    end
    for ilist=1:length(maskfiles)
        maskname=maskfiles(ilist).name;% take the first mask file in the list
        [rr,ff,x1,x2,xa,xb,xext,Mask_NomType{ilist}]=name2display(maskname);
        if ~strcmp(Mask_NomType{ilist},Mask_NomType{1})
            msgbox_uvmat('ERROR',['inconsistent mask types ' Mask_NomType{1} Mask_NomType{ilist } ' coexist in the current image directory'])
            return
        end
        [Path2,Name,ext]=fileparts(maskname);
        Namedouble=double(Name);
        val=(48>Namedouble)|(Namedouble>57);% select the non-numerical characters
        ind_mask=findstr('mask',Name);
        i=ind_mask-1;
        while val(i)==0 & i>0
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
        Mask.NomType=Mask_NomType{1};
        [maskname,mdetect]=name_generator(Mask.Base,num_i1,num_j1,'.png',Mask.NomType);%
        mdetect=exist(maskname,'file');
        if mdetect
            set(handles.nb_slice,'String',Name(i+1:ind_mask-1));
            set(handles.nb_slice,'BackgroundColor',[1 1 0])
            set(handles.mask_test,'UserData',Mask);  
            set(handles.mask_test,'BackgroundColor',[1 1 0])
            if nbslice > 1
                set(handles.slices,'value',1)
                slices_Callback(hObject, eventdata, handles)
            end
        end
    end
    if mdetect==0
         msgbox_uvmat('ERROR','no mask file detected (format ..._xxmask_ii.png needed), use the menu bar Tools/Make mask')
         set(handles.mask_test,'Value',0)
         return
    end    
    update_mask(handles,num_i1,num_j1);
else
    MaskData=get(handles.mask_test,'UserData');
    if isfield(MaskData,'maskhandle') && ishandle(MaskData.maskhandle)
          delete(MaskData.maskhandle)    
    end
    set(handles.mask_test,'UserData',[])    
    %huvmat=get(handles.mask_test,'parent');
    UvData=get(handles.uvmat,'UserData');
    if isfield(UvData,'MaskName')
        UvData=rmfield(UvData,'MaskName');
        set(handles.uvmat,'UserData',UvData)
    end
    set(handles.mask_test,'BackgroundColor',[0.7 0.7 0.7])
end

%-------------------------------------------------------------------
function update_mask(handles,num_i1,num_j1)
%-------------------------------------------------------------------

MaskData=get(handles.mask_test,'UserData');
if isfield(MaskData,'maskhandle')&& ishandle(MaskData.maskhandle)
    uistack(MaskData.maskhandle,'top');
end
num_i1_mask=mod(num_i1-1,MaskData.NbSlice)+1;
[MaskName,mdetect]=name_generator(MaskData.Base,num_i1_mask,num_j1,'.png',MaskData.NomType);
huvmat=get(handles.mask_test,'parent');
UvData=get(huvmat,'UserData');

%update mask image if the mask is new
if ~ (isfield(UvData,'MaskName') && isequal(UvData.MaskName,MaskName)) 
    UvData.MaskName=MaskName; %update the recorded name on UvData
    set(huvmat,'UserData',UvData);
    if mdetect==0
        if isfield(MaskData,'maskhandle')&& ishandle(MaskData.maskhandle)
            delete(MaskData.maskhandle)    
        end
    else
        %read mask image
        Mask.AName='image';
        Mask.A=imread(MaskName);
        npxy=size(Mask.A);
        Mask.AX=[0.5 npxy(2)-0.5];
        Mask.AY=[npxy(1)-0.5 0.5 ];
        Mask.CoordType='px';
        if isequal(get(handles.slices,'Value'),1)
           NbSlice=str2num(get(handles.nb_slice,'String'));
           num_i1=str2num(get(handles.i1,'String')); 
           Mask.ZIndex=mod(num_i1-1,NbSlice)+1;
        end
        %px to phys or other transform on field
         menu_transform=get(handles.transform_fct,'String');
        choice_value=get(handles.transform_fct,'Value');
        transform_name=menu_transform{choice_value};%name of the transform fct  given by the menu 'transform_fct'
        transform_list=get(handles.transform_fct,'UserData');
        transform=transform_list{choice_value};
        if  ~isequal(transform_name,'') && ~isequal(transform_name,'px')
            if isfield(UvData,'XmlData') && isfield(UvData.XmlData,'GeometryCalib')%use geometry calib recorded from the ImaDoc xml file as first priority
                Calib=UvData.XmlData.GeometryCalib;
                Mask=transform(Mask,UvData.XmlData);
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
            axes(handles.axes3)
            hold on    
            MaskData.maskhandle=image(Mask.AX,Mask.AY,imflag,'Tag','mask','HitTest','off','AlphaData',0.6*flagmask);
%             set(MaskData.maskhandle,'AlphaData',0.6*flagmask)
            set(handles.mask_test,'UserData',MaskData)
        end
    end
end


%-------------------------------------------------------------------
function MenuExportFigure_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
huvmat=get(handles.MenuExport,'parent');
UvData=get(huvmat,'UserData');
hfig=figure;
newaxes=copyobj(handles.axes3,hfig);
map=colormap(handles.axes3);
colormap(map);%transmit the current colormap to the zoom fig
colorbar

%-------------------------------------------------------------------
%-------------------------------------------------------------------
% III - MAIN REFRESH FUNCTIONS : 'FRAME PLOT'
%-------------------------------------------------------------------
%-------------------------------------------------------------------

%Executes on button press in runplus: make one step forward and call
%run0. The step forward is along the fields series 1 or 2 depending on 
%the scan_i and scan_j check box (exclusive each other)
%-------------------------------------------------------------------
function runplus_Callback(hObject, eventdata, handles)
increment=str2num(get(handles.increment_scan,'String')); %get the field increment d
runpm(hObject,eventdata,handles,increment)

%-------------------------------------------------------------------
%Executes on button press in runmin: make one step backward and call
%run0. The step backward is along the fields series 1 or 2 depending on 
%the scan_i and scan_j check box (exclusive each other)
%-------------------------------------------------------------------
function runmin_Callback(hObject, eventdata, handles)
increment=-str2num(get(handles.increment_scan,'String')); %get the field increment d
runpm(hObject,eventdata,handles,increment)

%-------------------------------------------------------------------
%Executes on button press in runmin: make one step backward and call
%run0. The step backward is along the fields series 1 or 2 depending on 
%the scan_i and scan_j check box (exclusive each other)
%-------------------------------------------------------------------
function RunMovie_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
set(handles.RunMovie,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
increment=str2num(get(handles.increment_scan,'String')); %get the field increment d
set(handles.STOP,'Visible','on')
set(handles.speed,'Visible','on')
set(handles.speed_txt,'Visible','on')
set(handles.RunMovie,'BusyAction','queue')
testavi=0;
UvData=get(handles.uvmat,'UserData');

while get(handles.speed,'Value')~=0 & isequal(get(handles.RunMovie,'BusyAction'),'queue') % enable STOP command
        errormsg=runpm(hObject,eventdata,handles,increment);
        if ~isempty(errormsg)
            return
        end
        pause(1.02-get(handles.speed,'Value'))% wait for next image
end
if isfield(UvData,'aviobj') && ~isempty( UvData.aviobj),
    UvData.aviobj=close(UvData.aviobj);
   set(handles.uvmat,'UserData',UvData);
end
set(handles.RunMovie,'BackgroundColor',[1 0 0])%paint the command buttonback to red

%-------------------------------------------------------------------
function STOP_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
set(handles.movie_pair,'BusyAction','Cancel')
set(handles.movie_pair,'value',0)
set(handles.RunMovie,'BusyAction','Cancel')
set(handles.MenuExportMovie,'BusyAction','Cancel')


%------------------------------------------------------------------
function errormsg=runpm(hObject,eventdata,handles,increment)
%------------------------------------------------------------------
%check for mùovie pair status
movie_status=get(handles.movie_pair,'Value');
if isequal(movie_status,1)
    STOP_Callback(hObject, eventdata, handles)%interrupt movie pair if active
end
%read the data on the current input rootfile(s)

[FileName,RootPath,filebase,FileIndices,FileExt,subdir]=read_file_boxes(handles);
NomType=get(handles.FileIndex,'UserData');

num1=stra2num(get(handles.i1,'String'));
num2=stra2num(get(handles.i2,'String'));
num_a=stra2num(get(handles.j1,'String'));
num_b=stra2num(get(handles.j2,'String'));

sub_value= get(handles.SubField,'Value');
if sub_value % a second input file has been entered
    [FileName_1,RootPath_1,filebase_1,FileIndices_1,FileExt_1,SubDir_1]=read_file_boxes_1(handles);
    [pp,ff,str1,str2,str_a,str_b]=name2display(FileIndices_1);
    num1_1=stra2num(str1);%current set of indices for the second field (may be set different than the main indices)
    num2_1=stra2num(str2);
    num_a_1=stra2num(str_a);
    num_b_1=stra2num(str_b);
    NomType_1=get(handles.FileIndex_1,'UserData');
else
    filename_1=[];
end   

comp_input=get(handles.fix_pair,'Value');
if isequal(NomType,'_i1-i2')||isequal(NomType,'_i1-i2_j')
    comp_input=1; %impose a fixed pair 
    set(handles.fix_pair,'Value',1)
end

%case of scanning along the first direction (rootfile numbers)
if get(handles.scan_i,'Value')==1% case of scanning along index i   
     num1=num1+increment;
     num2=num2+increment;
     [filename,num1,num_a,num2,num_b]=name_generator(filebase,num1,num_a,FileExt,NomType,comp_input,num2,num_b,subdir);
     if sub_value% set the second field name and indices
        num1_1=num1_1+increment;
        num2_1=num2_1+increment;
        filename_1=name_generator(filebase_1,num1_1,num_a_1,FileExt_1,NomType_1,1,num2_1,num_b_1,SubDir_1);
     end   
else % case of scanning along index j (burst numbers)
    num_a=num_a+increment;
    num_b=num_b+increment;
    if sub_value 
        num_a_1=num_a_1+increment;
        num_b_1=num_b_1+increment;
        filename_1=name_generator(filebase_1,num1_1,num_a_1,FileExt_1,NomType_1,1,num2_1,num_b_1,SubDir_1);
%     else % redefine the j index if it exceeds its upper bound (only in the absence of a second field)
%         lastfield_cell=get(handles.last_j,'String'); % get the last field number
%         lastfield=str2double(lastfield_cell{1});
%         if num_a>lastfield && ~isnan(lastfield) 
%             num_a=mod(num_a,lastfield);
%             num_b=mod(num_b,lastfield)
%         end
    end
    [filename,num1,num_a,num2,num_b]=name_generator(filebase,num1,num_a,FileExt,NomType,comp_input,num2,num_b,subdir);
end

% refresh plots
errormsg=refresh_field(handles,filename,filename_1,num1,num2,num_a,num_b);

if isempty(errormsg)  %update the index counters
    set(handles.i1,'String',num2stra(num1,NomType,1)); 
    if isequal(num2,num1)
         set(handles.i2,'String','');
    else
        set(handles.i2,'String',num2stra(num2,NomType,1));
    end 
    set(handles.j1,'String',num2stra(num_a,NomType,2));
    if isequal(num_b,num_a)
         set(handles.j2,'String','');
    else
        set(handles.j2,'String',num2stra(num_b,NomType,2));
    end
    [indices]=name_generator('',num1,num_a,'',NomType,1,num2,num_b,'');
    set(handles.FileIndex,'String',indices);
    if sub_value 
         indices_1=name_generator('',num1_1,num_a_1,'',NomType_1,1,num2_1,num_b_1,'');
         set(handles.FileIndex_1,'String',indices_1);
    end
    if isequal(movie_status,1)
        set(handles.movie_pair,'Value',1)
        movie_pair_Callback(hObject, eventdata, handles); %reactivate moviepair if it was activated
    end
else
     msgbox_uvmat('ERROR',errormsg);
end



%-------------------------------------------------------
% --- Executes on button press in movie_pair: create an alternating movie with two view
%-------------------------------------------------------
function movie_pair_Callback(hObject, eventdata, handles)
status=get(handles.movie_pair,'value');
if isequal(status,0)
    set(handles.movie_pair,'BusyAction','Cancel')%stop movie pair if button is 'off'
    set(handles.i2,'String','')
    set(handles.j2,'String','')
    return
else
    set(handles.movie_pair,'BusyAction','queue')
end
%initialisation
set(handles.movie_pair,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
list_fields=get(handles.Fields,'String');% list menu fields
index_fields=get(handles.Fields,'Value');% selected string index
FieldName=list_fields{index_fields}; % selected field
UvData=get(handles.uvmat,'UserData');
if isequal(FieldName,'image')
    test_1=0;
    [ff,rr,filebase,xx,Ext,SubDir]=read_file_boxes(handles);
    NomType=get(handles.FileIndex,'UserData');
else
    list_fields=get(handles.Fields_1,'String');% list menu fields
    index_fields=get(handles.Fields_1,'Value');% selected string index
    FieldName=list_fields{index_fields}; % selected field
    if isequal(FieldName,'image')
        test_1=1;
        [ff,rr,filebase,xx,Ext,SubDir]=read_file_boxes_1(handles);
        NomType=get(handles.FileIndex_1,'UserData');
    else
        msgbox_uvmat('ERROR','an image or movie must be first introduced as input')
        return
    end
end

num_i1=stra2num(get(handles.i1,'String'));
num_j1=stra2num(get(handles.j1,'String'));
num_i2=stra2num(get(handles.i2,'String'));
num_j2=stra2num(get(handles.j2,'String'));
if isempty(num_j2)
    if isempty(num_i2)   
        msgbox_uvmat('ERROR', 'a second image index i2 or j2 is needed to show the pair as a movie')
        return
    else
        num_j2=num_j1;%repeat the index i1 by default
    end
end
if isempty(num_i2)
    num_i2=num_i1;%repeat the index i1 by default
end
imaname_1=name_generator(filebase,num_i2,num_j2,Ext,NomType);
if ~exist(imaname_1,'file')
      msgbox_uvmat('ERROR',['second input open (-)  ' imaname_1 ' not found']);
      return
end
% set(handles.i2,'String',''); % indicates that the second index i2 is not used
% set(handles.j2,'String',''); % indicates that the second index i2 is not used

%read the second image
Field.AName='image';
if test_1
    Field_a=UvData.Field_1;
else
    Field_a=UvData.Field;
end
Field_b.AX=Field_a.AX;
Field_b.AY=Field_a.AY;
% z index
nbslice=str2double(get(handles.nb_slice,'String'));
if ~isempty(nbslice)
    Field_b.ZIndex=mod(num_i2-1,nbslice)+1;
end
Field_b.CoordType='px';
%determine the input file type
if (test_1 && isfield(UvData,'MovieObject_1'))||(~test_1 && isfield(UvData,'MovieObject'))
    FileType='movie';
elseif isequal(lower(Ext),'.avi')
    FileType='avi';
elseif isequal(lower(Ext),'.vol')
    FileType='vol';
else 
   form=imformats(Ext([2:end]));
   if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
       if isequal(NomType,'*');
           FileType='multimage';
       else
           FileType='image';
       end
   end
end
switch FileType
        case 'movie'
            if test_1
                Field_b.A=read(UvData.MovieObject_1,num_i2);
            else
                Field_b.A=read(UvData.MovieObject,num_i2);
            end
        case 'avi'
            mov=aviread(imaname_1,num_i2);
            Field_b.A=frame2im(mov(1));
        case 'vol'
            Field_b.A=imread(imaname_1);
        case 'multimage'
            Field_b.A=imread(imaname_1,num_i2);
        case 'image'
            Field_b.A=imread(imaname_1);
end 
if get(handles.slices,'Value')
    Field.ZIndex=str2double(get(handles.z_index,'String'));
end

%px to phys or other transform on field
menu_transform=get(handles.transform_fct,'String');
choice_value=get(handles.transform_fct,'Value');
transform_name=menu_transform{choice_value};%name of the transform fct  given by the menu 'transform_fct'
transform_list=get(handles.transform_fct,'UserData');
transform=transform_list{choice_value};
if  ~isequal(transform_name,'') && ~isequal(transform_name,'px')
    if test_1 && isfield(UvData,'XmlData_1') && isfield(UvData.XmlData_1,'GeometryCalib')%use geometry calib recorded from the ImaDoc xml file as first priority
        Field_a=transform(Field_a,UvData.XmlData_1);%the first field has been stored without transform
        Field_b=transform(Field_b,UvData.XmlData_1);
    elseif ~test_1 && isfield(UvData,'XmlData') && isfield(UvData.XmlData,'GeometryCalib')%use geometry calib
        Field_b=transform(Field_b,UvData.XmlData);
    end
end

 % make movie until movie speed is set to 0 or STOP is activated
hima=findobj(handles.axes3,'Tag','ima');% %handles.axes3 =main plotting window (A GENERALISER)
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

%------------------------------------------------------------------------
% --- Executes on button press in run0.
function run0_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
filename=read_file_boxes(handles);

filename_1=[];%default
if get(handles.SubField,'Value')
    filename_1=read_file_boxes_1(handles);
end
num_i1=stra2num(get(handles.i1,'String'));
num_i2=stra2num(get(handles.i2,'String'));
num_j1=stra2num(get(handles.j1,'String'));
num_j2=stra2num(get(handles.j2,'String'));
errormsg=refresh_field(handles,filename,filename_1,num_i1,num_i2,num_j1,num_j2);
if ~isempty(errormsg)
      msgbox_uvmat('ERROR',errormsg);
end    

%------------------------------------------------------------------------
% --- read the input files and refresh all the plots, including projection.
% OUTPUT: 
%  errormsg: error message char string  =[] by default
% INPUT:
% filename: first input file (=[] in the absence of input file)
% filename_1: second input file (=[] in the asbsenc of secodn input file) 
% num_i1,num_i2,num_j1,num_j2; frame indices
% Field: structure describing an optional input field (then replace the input file)

function errormsg=refresh_field(handles,filename,filename_1,num_i1,num_i2,num_j1,num_j2,Field)
%------------------------------------------------------------------------
%initialisation
set(handles.run0,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
errormsg=[]; % default error message
abstime=[];
abstime_1=[];
dt=[];
if ~exist('Field','var')
    Field={};
end
UvData=get(handles.uvmat,'UserData');
%UvData =structure containing information stored outside the uicontrol of uvmat
%      .NewSeries: =1 for a new series (new root fiel introduced), 0 else
%      .MovieObject: movie object representing an input movie
%      .MovieObject_1: idem for a second input series (_1)
%      .filename_1 : last second input file name (to deal with a constant second input without reading again the file)
%      .VelType_1: last velocity type (civ1, civ2...) for the second input series
%      .FieldName_1: last field name(velocity, vorticity...) for the second input series
%      .NbDim: number of space dimensions of the input field
%      .ZMin, .ZMax: range of the z coordinate
%..... to complement

if ishandle(handles.UVMAT_title) %remove title panel on uvmat
    delete(handles.UVMAT_title)
end

% determine the main input file information for action
FileType=[];%default
if ~isempty(filename)
%     [filename,RootPath,filebase,xx,Ext]=read_file_boxes(handles);
    if ~exist(filename,'file')
        errormsg=['input file ' filename ' does not exist'];
        return
    end
    Ext=get(handles.FileExt,'String');
    NomType=get(handles.FileIndex,'UserData');
    %update the z position index
    nbslice_str=get(handles.nb_slice,'String');
    z_index=1;%default
    if isequal(nbslice_str,'volume')
        z_index=num_j1;
        set(handles.z_index,'String',num2str(z_index))
    else
        nbslice=str2num(nbslice_str);
        z_index=mod(num_i1-1,nbslice)+1;
        set(handles.z_index,'String',num2str(z_index))
    end
    % refresh menu for save_mask if relevant
    masknumber=get(handles.masklevel,'String');
    if length(masknumber)>=z_index
        set(handles.masklevel,'Value',z_index)
    end

    % determine the input file type
    if isequal(Ext,'.nc')||isequal(Ext,'.cdf')
        FileType='netcdf';
    elseif isfield(UvData,'MovieObject')
        FileType='movie';
        FieldName='image';
    elseif isequal(lower(Ext),'.avi')
        FileType='avi';
        FieldName='image';
    elseif isequal(lower(Ext),'.vol')
        FileType='vol';
        FieldName='image';
    else 
       form=imformats(Ext([2:end]));
       if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
           if isequal(NomType,'*');
               FileType='multimage';
           else
               FileType='image';
           end
           FieldName='image';
       end
    end
else
    FileType='netcdf';
    FieldName='get_field...';
end
VelType=[];%default
if isequal(FileType,'netcdf')
    list_fields=get(handles.Fields,'String');% list menu fields
    index_fields=get(handles.Fields,'Value');% selected string index
    FieldName= list_fields{index_fields}; % selected field
    if ~isequal(FieldName,'get_field...')% read the field names on the interface get_field...
       VelType=setfield(handles);
    end
end

% choose a second field if Subfield option is 'on'
FieldName_1=[];
scal_color=[];
VelType_1=setfield_1(handles);
sub_value=get(handles.SubField,'Value');
FileType_1='none';%default
if ~isempty(filename_1)
    % test for a constant second field (comparison with a fixed field)
    NomType_1=get(handles.FileIndex_1,'UserData');
    Ext_1=get(handles.FileExt_1,'String');
    % determine the input file type
    if isequal(Ext_1,'.nc')||isequal(Ext_1,'.cdf')
        FileType_1='netcdf';
    elseif isfield(UvData,'MovieObject_1')
        FileType_1='movie';
        FieldName_1='image';
    elseif isequal(lower(Ext_1),'.avi')
        FileType='avi';
        FieldName_1='image';
    elseif isequal(lower(Ext_1),'.vol')
        FileType_1='vol';
        FieldName_1='image';
    else 
       form=imformats(Ext_1([2:end]));
       if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
           if isequal(NomType_1,'*');
               FileType_1='multimage';
           else
               FileType_1='image';
           end
           FieldName_1='image';
       end
    end
    if ~isequal(FieldName_1,'image')
        list_fields=get(handles.Fields_1,'String');% list menu fields
        index_fields=get(handles.Fields_1,'Value');% selected string index
        FieldName_1= list_fields{index_fields}; % selected field
        if isequal(VelType_1,'*')% free veltype choice
            VelType_1=[];
        elseif isequal(VelType_1,'"')% veltype the same as for the first field
            if isempty(VelType)
                VelType_1=[];
            else
                VelType_1=VelType;
            end
        end
    end
    test_keepdata_1=0;% test for keeping the previous stored data if the input files are unchanged
    if ~isequal(NomType_1,'*')%in case of a series of files (not avi movie)
        if isfield(UvData,'filename_1')&& isfield(UvData,'VelType_1') && isfield(UvData,'FieldName_1')
            test_keepdata_1= isequal(filename_1,UvData.filename_1)&&...
                isequal(VelType_1,UvData.filename_1) && isequal(FieldName_1,UvData.FieldName_1);
        end
    end
    if test_keepdata_1
        Field{2}=UvData.Field_1;   
    elseif ~exist(filename_1,'file')
        errormsg=['second file ' filename_1 ' does not exist'];
        return
    end
end

%read the input field(s)
%read images
if ~isempty(filename) && isequal(FieldName,'image')
     switch FileType
        case 'movie'
            A=read(UvData.MovieObject,num_i1);
        case 'avi'
            mov=aviread(filename,num_i1);
            A=frame2im(mov(1));
        case 'vol'
            A=imread(filename);
        case 'multimage'
            A=imread(filename,num_i1);
        case 'image'
            A=imread(filename);
    end 
    npxy=size(A);
    set(handles.npx,'String',num2str(npxy(2)));% display image size on the interface
    set(handles.npy,'String',num2str(npxy(1)));
    Rangx=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
    Rangy=[npxy(1)-0.5 0.5]; %
    Field{1}.AName='image';
    Field{1}.ListVarName={'AY','AX','A'}; % 
    if size(A,3)==3;%color
        Field{1}.VarDimName={'AY','AX',{'AY','AX','rgb'}}; %
    else
        Field{1}.VarDimName={'AY','AX',{'AY','AX'}}; %
    end
    Field{1}.AY=Rangy;
    Field{1}.AX=Rangx;
    Field{1}.A=A;
    Field{1}.CoordType='px'; %used for mouse_motion
    Field{1}.CoordUnit='pixel'; %used for mouse_motion
end

%read a second image
if  ~isempty(filename_1) && ~test_keepdata_1 && isequal(FieldName_1,'image')
    switch FileType_1
        case 'movie'
            A=read(UvData.MovieObject_1,num_i1);
        case 'avi'
            mov=aviread(filename_1,num_i1);
            A=frame2im(mov(1));
        case 'vol'
            A=imread(filename_1);
        case 'multimage'
            A=imread(filename_1,num_i1);
        case 'image'
            A=imread(filename_1);
        case 'netcdf'
        otherwise
            errormsg=['unknown input file type ' filename_1];
    end 
    npxy=size(A);
    set(handles.npx,'String',num2str(npxy(2)));% display image size on the interface
    set(handles.npy,'String',num2str(npxy(1)));
    Rangx=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
    Rangy=[npxy(1)-0.5 0.5]; %
    Field{2}.AName='image';
    Field{2}.ListVarName={'AY','AX','A'}; % 
    if size(A,3)==3;%color
        Field{2}.VarDimName={'AY','AX',{'AY','AX','rgb'}}; %
    else
        Field{2}.VarDimName={'AY','AX',{'AY','AX'}}; %
    end
    Field{2}.AY=Rangy;
    Field{2}.AX=Rangx;
    Field{2}.A=A;
    Field{2}.CoordType='px'; %used for mouse_motion
    Field{2}.CoordUnit='px'; %used for move_mou
end

%read ncfile(s)
CivStage_1=0;%default
VelType_out_1=[];
InputField={FieldName};
InputField_1={FieldName_1};
if (~isempty(filename)&& isequal(FileType,'netcdf')) || (~isempty(filename_1)&& isequal(FileType_1,'netcdf')) ;
    %read the velocity field(s) from netcdf rootfile(s)
    list_code=get(handles.col_vec,'String');% list menu fields
    index_code=get(handles.col_vec,'Value');% selected string index
    scal_color= list_code{index_code(1)}; % selected field
    if isequal(FieldName,'velocity')&& ~isequal(scal_color,'black') && ~isequal(scal_color,'white')
        InputField=[InputField scal_color];
    end
    if isequal(FieldName_1,'velocity') && ~isequal(scal_color,'black') && ~isequal(scal_color,'white')
        InputField_1=[InputField_1 scal_color];
    end
    if isequal(FileType,'netcdf')  %read the first nc field
        if isequal(FieldName,'get_field...')% read the field names on the interface get_field.
            %VelType=get(handles.Fields,'UserData');
            hget_field=findobj(allchild(0),'Name','get_field');%find the get_field... GUI
            if isempty(hget_field)
                hget_field= get_field(filename);%open the get_field GUI    
            end
            hhget_field=guidata(hget_field);
            set(hhget_field.inputfile,'String',filename)% update the list of input fields in get_field
            set(hhget_field.ACTION,'Value',1)% PLOT option selected
            set(hhget_field.list_fig,'Value',2)% plotting axes =uvmat selected
            [Field{1},errormsg]=read_get_field(hget_field); %read the names of the variables to plot in the get_field GUI
            if ~isempty(errormsg)
                errormsg=['error in uvmat/run0_Callback/read_get_field: ' errormsg];
                return
            end
            CivStage=0;
            VelType_out=[];         
        else
            [Field{1},VelType_out]=read_civxdata(filename,InputField,VelType);
            if isfield(Field{1},'Txt')
                errormsg=Field{1}.Txt;
                return
            end
            CivStage=Field{1}.CivStage;
            UvData.NbDim=Field{1}.nb_dim;
        end
    end
    if ~isempty(filename_1) && ~test_keepdata_1 && isequal(FileType_1,'netcdf') %read the second file
        if isequal(FieldName_1,'get_field...')% read the field names on the interface get_field.
            hget_field=findobj(allchild(0),'Name','get_field_1');%find the get_field... GUI
             if isempty(hget_field)
                 hget_field= get_field(filename_1);%open the get_field GUI
                 set(hget_field,'name','get_field_1')
%                 enable_transform(handles,'off')% no field transform (possible transform in the GUI get_field)
             end
            hhget_field=guidata(hget_field);%handles of GUI elements in get_field
            SubField=get_field('read_var_names',hObject,eventdata,hhget_field); %read the names of the variables to plot in the get_field GUI 
            [Field{2},var_detect]=nc2struct(filename_1,SubField.ListVarName); %read the corresponding input data                
            Field{2}.VarAttribute=SubField.VarAttribute;
            %update the display on get_field
            set(hhget_field.inputfile,'String',filename_1)
            set(hhget_field.variables,'Value',1)
            Tabchar={''};%default
            Tabcell=[];
            if isfield(Field{2},'ListGlobalAttribute')& ~isempty(Field{2}.ListGlobalAttribute)
                for iline=1:length(Field{2}.ListGlobalAttribute)
                    Tabcell{iline,1}=Field{2}.ListGlobalAttribute{iline};
                    if isfield(Field{2}, Field{2}.ListGlobalAttribute{iline})
                        eval(['val=Field{2}.' Field{2}.ListGlobalAttribute{iline} ';'])
                        if ischar(val);
                            Tabcell{iline,2}=val;
                        else
                            Tabcell{iline,2}=num2str(val);
                        end
                    end
                end
                if ~isempty(Tabcell)
                    Tabchar=cell2tab(Tabcell,'=');
                    Tabchar=[{''};Tabchar];
                end
            end
            set(hhget_field.attributes,'String',Tabchar);%update list of global attributes in get_field 
        else
            [Field{2},VelType_out_1]=read_civxdata(filename_1,[],VelType_1);
            CivStage_1=Field{2}.CivStage;
        end
        if ~isequal(FileType,'netcdf')
            VelType_out=VelType_out_1;
        end
    end
end

%store the second field for possible latter use
if numel(Field)==2
    UvData.Field_1=Field{2};
end

%update the display buttons for the first velocity type (first menuline)
veltype_handles=[handles.civ1 handles.interp1 handles.filter1 handles.civ2 handles.interp2 handles.filter2];
if ~isequal(FileType,'netcdf')
    reset_vel_type(veltype_handles)
elseif isempty(VelType) && ~isequal(FieldName,'get_field...')
    set_veltype_display(veltype_handles,CivStage)%update the display of available velocity types for the first field
    if isempty(VelType_out)
        reset_vel_type(veltype_handles)
    else
        handle1=eval(['handles.' VelType_out]);
        reset_vel_type(veltype_handles,handle1)
    end
end

%update the display buttons for the second velocity type (second menuline)
veltype_handles_1=[handles.civ1_1 handles.interp1_1 handles.filter1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1];
if ~isequal(FileType_1,'netcdf')
    reset_vel_type(veltype_handles_1)
elseif isempty(VelType_1) && ~isequal(FieldName_1,'get_field...')
    set_veltype_display(veltype_handles_1,CivStage_1)%update the display of available velocity types for the first field
    if isempty(VelType_out_1)
        reset_vel_type(veltype_handles_1)
    else
        handle1=eval(['handles.' VelType_out_1 '_1']);
        reset_vel_type(veltype_handles_1,handle1)
    end
end

%introduce w as background image by default for a new series (only for nbdim=2)
if ~isfield(UvData,'NewSeries')
    UvData.NewSeries=1;
end
%put W as background image by default if NbDim=2:
if ~isfield(UvData,'NbDim')||isempty(UvData.NbDim)||~isequal(UvData.NbDim,3)
    if UvData.NewSeries && isequal(get(handles.SubField,'Value'),0) && isfield(Field{1},'W') && ~isempty(Field{1}.W);
        set(handles.SubField,'Value',1);
        %menu=update_menu(handles.Fields_1,'w');%update the menu for the background scalar nd set the choice to 'w'
        set(handles.RootPath_1,'String','"')
        set(handles.RootFile_1,'String','"')
        set(handles.SubDir_1,'String','"');
        [indices]=name_generator('',num_i1,num_j1,'',NomType,1,num_i2,num_j2,'');
        set(handles.FileIndex_1,'String',indices)
        set(handles.FileExt_1,'String','"');
        set(handles.Fields_1,'Visible','on');
        set(handles.Fields_1,'Visible','on');
        set(handles.RootPath_1,'Visible','on')
        set(handles.RootFile_1,'Visible','on')
        set(handles.SubDir_1,'Visible','on');
        set(handles.FileIndex_1,'Visible','on');
        set(handles.FileExt_1,'Visible','on');
        set(handles.Fields_1,'Visible','on');
        Field{1}.AName='w';
        testscal=1;
    end
end           

%multislice case
if ~isempty(filename) &&(~isfield(UvData,'NbDim') || isequal(UvData.NbDim,2))&&...%2D case
      isfield(UvData,'XmlData') && isfield(UvData.XmlData,'GeometryCalib')&& isfield(UvData.XmlData.GeometryCalib,'SliceCoord')
       siz=size(UvData.XmlData.GeometryCalib.SliceCoord);
       if siz(1)>1
           NbSlice=siz(1);
%            set(handles.slices,'Visible','on')
%            set(handles.slices,'Value',1)
       else
           NbSlice=1;
       end
       %set(handles.nb_slice,'String',num2str(NbSlice))
%        slices_Callback(handles.uvmat, [], handles)
end

%store the current open names, fields and vel types in uvmat interface 
UvData.filename=filename;
UvData.filename_1=filename_1;
UvData.VelType=VelType;
UvData.VelType_1=VelType_1;
UvData.FieldName=FieldName;
UvData.FieldName_1=FieldName_1;
if ~isempty(scal_color)
    UvData.CName=scal_color;
end

%coordinate transform or user fct
XmlData=[];%default
if isfield(UvData,'XmlData')%use geometry calib recorded from the ImaDoc xml file as first priority
    XmlData=UvData.XmlData;
end
XmlData_1=[];%default
if isfield(UvData,'XmlData_1')
   XmlData_1=UvData.XmlData_1;
end
menu_transform=get(handles.transform_fct,'String');
choice_value=get(handles.transform_fct,'Value');
transform_list=get(handles.transform_fct,'UserData');
transform=transform_list{choice_value};%selected function handles

% z index
if ~isempty(filename)
    Field{1}.ZIndex=z_index;
end

%px to phys or other transform on field
if ~isempty(transform) 
    if length(Field)>=2
        Field{2}.ZIndex=z_index;
        [Field{1},Field{2}]=transform(Field{1},XmlData,Field{2},XmlData_1);
        if isempty(Field{2})
            Field(2)=[];
        end
    else
        Field{1}=transform(Field{1},XmlData);
    end
end 

%calculate scalar
if isequal(FileType,'netcdf') && ~isequal(FieldName,'get_field...')%
    Field{1}=calc_field(InputField,Field{1});
end
if length(Field)==2 && ~test_keepdata_1 && isequal(FileType_1,'netcdf') && ~isequal(FieldName_1,'get_field...')
    Field{2}=calc_field(InputField_1,Field{2});
end

% combine the two input fields (e.g. substract velocity fields)
if numel(Field)==2
   UvData.Field=sub_field(Field{1},Field{2}); %TO UPDATE FOR MORE GENERAL INPUT  
else
   UvData.Field=Field{1};
end

% test 3D , default projection menuplane and typical mesh (needed to menuopen set_object)
test_x=0;
test_z=0;% test for unstructured z coordinate
UvData.ZMax=0;
UvData.ZMin=0;%default
UvData.Mesh=1; %default
[UvData.Field,errormsg]=check_field_structure(UvData.Field);
if ~isempty(errormsg)
    errormsg=['error in uvmat/run0_Callback/check_field_structure: ' errormsg];
    return
end
[CellVarIndex,NbDim,VarType]=find_field_indices(UvData.Field);
[NbDim,imax]=max(NbDim);
if isempty(imax)
%    DimVarIndex=0;    
    coord_x=[];
else
%     VarIndex=CellVarIndex{imax};
    coord_x=VarType{imax}.coord_x;
end
if isfield(UvData,'NbDim') && ~isempty(UvData.NbDim)
    NbDim=UvData.NbDim;
else  
    UvData.NbDim=NbDim;
end
if ~isempty(CellVarIndex) && ~isempty(VarType{imax}.coord_x)  && ~isempty(VarType{imax}.coord_y)    %unstructured coordinate z
    XName=UvData.Field.ListVarName{VarType{imax}.coord_x};
    YName=UvData.Field.ListVarName{VarType{imax}.coord_y};
    test_x=1;
elseif isfield(UvData.Field,'X') && isfield(UvData.Field,'Y')
    XName='X';
    YName='Y';
    test_x=1;
end
if test_x
    eval(['UvData.XMax=max(UvData.Field.' XName ');'])
    eval(['UvData.XMin=min(UvData.Field.' XName ');'])
    eval(['UvData.YMax=max(UvData.Field.' YName ');'])
    eval(['UvData.YMin=min(UvData.Field.' YName ');'])
    eval(['nbvec=length(UvData.Field.' XName ');'])
    if NbDim==3%
        if ~isempty(CellVarIndex) && ~isempty(VarType{imax}.coord_z)%unstructured coordinate z
            ZName=UvData.Field.ListVarName{VarType{imax}.coord_z};
            eval(['UvData.ZMax=max(UvData.Field.' ZName ');'])
            eval(['UvData.ZMin=min(UvData.Field.' ZName ');'])
            test_z=1;   
        elseif isfield(UvData,'Z')% usual civ data
            UvData.ZMax=max(UvData.Z);
            UvData.ZMin=min(UvData.Z);
            test_z=1;
        end
    end
    if isequal(UvData.ZMin,UvData.ZMax)%no z dependency
        NbDim=2;
        test_z=0;
    end    
    if test_z
         UvData.Mesh=((UvData.XMax-UvData.XMin)*(UvData.YMax-UvData.YMin)*(UvData.ZMax-UvData.ZMin))/nbvec;% volume per vector
         UvData.Mesh=(UvData.Mesh)^(1/3);
    else
        UvData.Mesh=sqrt((UvData.XMax-UvData.XMin)*(UvData.YMax-UvData.YMin)/nbvec);%2D
    end
end
%case of structured coordinates
if isfield(UvData.Field,'AX') & isfield(UvData.Field,'AY')& isfield(UvData.Field,'A')
    UvData.XMax=max(UvData.Field.AX);
    UvData.XMin=min(UvData.Field.AX);
    UvData.YMax=max(UvData.Field.AY);
    UvData.YMin=min(UvData.Field.AY);
    np_A=size(UvData.Field.A);
    UvData.Mesh=sqrt((UvData.XMax-UvData.XMin)*(UvData.YMax-UvData.YMin)/((np_A(1)-1) * (np_A(2)-1))) ; 
end
if  isempty(coord_x)&~isempty(CellVarIndex)
    VarIndex=CellVarIndex{imax}; % list of variable indices
    DimIndex=UvData.Field.VarDimIndex{VarIndex(1)}; %list of dim indices for the variable
    if NbDim==3
        nbpoints=UvData.Field.DimValue(DimIndex(1));
        %Zvar=DimVarIndex(DimIndex(1));
         %Zvar=DimVarIndex(1);
%          Zvar=VarType{imax}.coord_3;
        if isfield(VarType{imax},'coord_3')&& ~isequal(VarType{imax}.coord_3,0) % z is a dimension variable
            ZName=UvData.Field.ListVarName{VarType{imax}.coord_3}
            eval(['UvData.ZMax=max(UvData.Field.' ZName ');'])
            eval(['UvData.ZMin=min(UvData.Field.' ZName ');'])
        else
            testcoord_z=0;
            if length(UvData.Field.VarAttribute)>=VarIndex(1)
                if isfield(UvData.Field.VarAttribute{VarIndex(1)},'Coord_1')%regular grid 
                    Coord_z=UvData.Field.VarAttribute{VarIndex(1)}.Coord_1;
                    UvData.ZMax=max(Coord_z);
                    UvData.ZMin=min(Coord_z);
                    testcoord_z=1;
                end
            end
            if ~testcoord_z
                  UvData.ZMin=1;
                  UvData.ZMax=UvData.Field.DimValue(DimIndex(1));
            end
        end
        UvData.Mesh=(UvData.ZMax-UvData.ZMin)/(nbpoints-1); 
    elseif NbDim==2
        nbpoints_y=UvData.Field.DimValue(DimIndex(1));       
        Yvar=VarType{imax}.coord_y;
        if Yvar~=0  % x is a dimension variable
            YName=UvData.Field.ListVarName{Yvar};
            eval(['UvData.YMax=max(UvData.Field.' YName ');'])
            eval(['UvData.YMin=min(UvData.Field.' YName ');'])
        else
            testcoord_y=0;
            if ~testcoord_y
                  UvData.YMin=1;
                  UvData.YMax=UvData.Field.DimValue(DimIndex(1));
            end
        end
        DY=(UvData.YMax-UvData.YMin)/(nbpoints_y-1);
        nbpoints_x=UvData.Field.DimValue(DimIndex(2));
        Xvar=VarType{imax}.coord_x;
        if Xvar~=0  % x is a dimension variable
            XName=UvData.Field.ListVarName{Xvar};
            eval(['UvData.XMax=max(UvData.Field.' XName ');'])
            eval(['UvData.XMin=min(UvData.Field.' XName ');'])
        else
            testcoord_x=0;
            if ~testcoord_x
                  UvData.XMin=1;
                  UvData.XMax=UvData.Field.DimValue(DimIndex(2));
            end
        end
        DX=(UvData.XMax-UvData.XMin)/(nbpoints_x-1);
        UvData.Mesh= sqrt(DX*DY); 
    end
end

%create a default projection menuplane
UvData.Object{1}.Style='plane';%main plotting plane
UvData.Object{1}.ProjMode='projection';%main plotting plane
if ~isfield(UvData.Object{1},'plotaxes')
    UvData.Object{1}.plotaxes=handles.axes3;%default plotting axis
    set(handles.list_object_1,'Value',1);
    set(handles.list_object_1,'String',{'1-PLANE'});  
end

%3D case (menuvolume)
if NbDim==3 && UvData.NewSeries
    UvData.Object{1}.NbDim=UvData.NbDim;%test for 3D objects
    UvData.Object{1}.RangeZ=UvData.Mesh;%main plotting plane
    UvData.Object{1}.Coord(1,3)=(UvData.ZMin+UvData.ZMax)/2;%section at a middle plane chosen
    UvData.Object{1}.Phi=0;
    UvData.Object{1}.Theta=0;
    UvData.Object{1}.Psi=0;
    UvData.Object{1}.HandlesDisplay=plot(0,0,'Tag','proj_object');% A REVOIR  
    PlotHandles=get_plot_handles(handles);
    ZBounds(1)=UvData.ZMin; %minimum for the Z slider
    ZBounds(2)=UvData.ZMax;%maximum for the Z slider
    UvData.Object{1}.Name='1-PLANE';
    UvData.Object{1}.enable_plot=1;
    set_object(UvData.Object{1},PlotHandles,ZBounds);
    set(handles.list_object_1,'Value',1);
%multilevel case (single menuplane in a 3D space)
elseif isfield(UvData,'Z')
    if isfield(UvData,'CoordType')& isequal(UvData.CoordType,'phys') & isfield(UvData,'XmlData')
        XmlData=UvData.XmlData;
        if isfield(XmlData,'PlanePos')
             UvData.Object{1}.Coord=XmlData.PlanePos(UvData.ZIndex,:);
        end
        if isfield(XmlData,'PlaneAngle')
            siz=size(XmlData.PlaneAngle);
            indangle=min(siz(1),UvData.ZIndex);%take first angle if a single angle is defined (translating scanning)              
            UvData.Object{1}.Phi=XmlData.PlaneAngle(indangle,1);
            UvData.Object{1}.Theta=XmlData.PlaneAngle(indangle,2);
            UvData.Object{1}.Psi=XmlData.PlaneAngle(indangle,3);
        end
    elseif isfield(UvData,'ZIndex')
        UvData.Object{1}.ZObject=UvData.ZIndex;
    end
end

%Plot the projections on all existing  projection objects
keeplim=get(handles.FixedLimits,'Value');
%reset the min and max of scalar if only the mask is displayed
if isfield(UvData,'Mask')&~isfield(UvData,'A')
    set(handles.MinA,'String','0')
    set(handles.MaxA,'String','255')
end
IndexObj(1)=get(handles.list_object_1,'Value');
if IndexObj(1)> numel(UvData.Object)
    IndexObj(1)=1;
end
IndexObj_2=get(handles.list_object_2,'Value');
if IndexObj_2 <= numel(UvData.Object)
    IndexObj(2)=IndexObj_2;
end
for imap=1:numel(IndexObj)
    iobj=IndexObj(imap);
    if ~isempty(UvData.Object{iobj})%& isfield(Object{iobj},'plotaxes')& ishandle(Object{iobj}.plotaxes)
        %Projeter les champs sur l'objet:*
        ObjectData=proj_field(UvData.Field,UvData.Object{iobj},iobj);
        if imap==2
            UvData.ProjField_2=ObjectData;%store the projection field on uvmat: ***** WILL REPLACE THE FIELD SORED ON THE AXES: AxeData *****
        else
            UvData.ProjField_1=ObjectData;%store the projection field on view_field
        end
        %use of mask
        if isfield(ObjectData,'NbDim')&isequal(ObjectData.NbDim,2)
            if isfield(ObjectData,'Mask') & isfield(ObjectData,'A')
                 flag_mask=double(ObjectData.Mask>200);%=0 for masked regions
                 AX=ObjectData.AX;
                 AY=ObjectData.AY;
                 MaskX=ObjectData.MaskX;
                 MaskY=ObjectData.MaskY;
                 if ~isequal(MaskX,AX)|~isequal(MaskY,AY)
                     nxy=size(flag_mask);
                     sizpx=(ObjectData.MaskX(end)-ObjectData.MaskX(1))/(nxy(2)-1);%size of a mask pixel
                     sizpy=(ObjectData.MaskY(1)-ObjectData.MaskY(end))/(nxy(1)-1);
                     x_mask=[ObjectData.MaskX(1):sizpx:ObjectData.MaskX(end)]; % pixel x coordinates for image display 
                     y_mask=[ObjectData.MaskY(1):-sizpy:ObjectData.MaskY(end)];% pixel x coordinates for image display
                     %project on the positions of the scalar
                     npxy=size(ObjectData.A);
                     dxy(1)=(ObjectData.AY(end)-ObjectData.AY(1))/(npxy(1)-1);%grid mesh in y
                     dxy(2)=(ObjectData.AX(end)-ObjectData.AX(1))/(npxy(2)-1);%grid mesh in x
                     xi=[ObjectData.AX(1):dxy(2):ObjectData.AX(end)];
                     yi=[ObjectData.AY(1):dxy(1):ObjectData.AY(end)];      
                     [XI,YI]=meshgrid(xi,yi);% creates the matrix of regular coordinates
                    flag_mask = interp2(x_mask,y_mask,flag_mask,XI,YI);
                 end
                 AClass=class(ObjectData.A);
                 ObjectData.A=flag_mask.*double(ObjectData.A);
                 ObjectData.A=feval(AClass,ObjectData.A);
                 ind_off=[];
                 if isfield(ObjectData,'ListVarName')
                      for ilist=1:length(ObjectData.ListVarName)
                           if isequal(ObjectData.ListVarName{ilist},'Mask')|isequal(ObjectData.ListVarName{ilist},'MaskX')|isequal(ObjectData.ListVarName{ilist},'MaskY')
                               ind_off=[ind_off ilist];
                           end
                      end
                      ObjectData.ListVarName(ind_off)=[];
                      ObjectData.VarDimIndex(ind_off)=[];
                      ind_off=[];        
                      for ilist=1:length(ObjectData.ListDimName)       
                           if isequal(ObjectData.ListDimName{ilist},'MaskX')|isequal(ObjectData.ListDimName{ilist},'MaskY')
                               ind_off=[ind_off ilist];
                           end
                      end
                      ObjectData.ListDimName(ind_off)=[];
                      ObjectData.DimValue(ind_off)=[];
                 end
            end  
        end
        if ~isempty(ObjectData)
            haxes=[];%default
            if isfield(UvData.Object{iobj},'plotaxes')
                haxes=UvData.Object{iobj}.plotaxes;%axes used for representing the projection on the object
            end
            PosColorbar=[];%default: no colorbar
            if ishandle(haxes) & isequal(get(haxes,'Tag'),'axes3')& isfield(UvData,'PosColorbar')
                PosColorbar=UvData.PosColorbar;%prescribe the colorbar position on the uvmat interface
            else
                PosColorbar='*';%default position
            end
            PlotParam=read_plot_param(handles);%read plotting parameters on the uvmat interface
            [PlotType,ScalOut,UvData.Object{iobj}.plotaxes]=plot_field(ObjectData,haxes,PlotParam,keeplim,PosColorbar);
            if isequal(PlotType,'none')
                hget_field=findobj(allchild(0),'name','get_field');
                if isempty(hget_field)
                    get_field([],ObjectData)% the projected field cannot be automatically plotted: use get_field to specify the variablesdelete(hget_field)
                else
                    errormsg='The field defined by get_field cannot be plotted';
                    return
                end 
            end  
            UvData.Object{iobj}.PlotParam=ScalOut; %record the plotting parameters
        end       
    end
end

%display the updated plotting parameters for the base menuplane
write_plot_param(handles,UvData.Object{1}.PlotParam);% update the display of the plotting parameters
UvData.NewSeries=0;% put to 0 the test for a new field series (set by RootPath_callback)
set(handles.uvmat,'UserData',UvData)

%update the mask
if isequal(get(handles.mask_test,'Value'),1)%if the mask option is on
   update_mask(handles,num_i1,num_i2);
end

%prepare the menus of histograms (for the whole menuvolume in 3D case)
menu_histo=(UvData.Field.ListVarName)';
ind_bad=[];
nb_histo=1;
for ivar=1:numel(menu_histo)
    if isfield(UvData.Field,'VarAttribute') && numel(UvData.Field.VarAttribute)>=ivar && isfield(UvData.Field.VarAttribute{ivar},'Role')
        Role=UvData.Field.VarAttribute{ivar}.Role;
        switch Role
            case {'coord_x','coord_y','coord_z','dimvar'}
                ind_bad=[ind_bad ivar];
            case {'vector_y'}
                nb_histo=nb_histo+1;
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
        ind_bad=[ind_bad ivar];
    end
end
menu_histo(ind_bad)=[];
test_v=0;
if ~isempty(menu_histo)
    set(handles.histo1_menu,'Value',1)
    set(handles.histo1_menu,'String',menu_histo)
    histo1_menu_Callback(handles.histo1_menu, [], handles)
    if nb_histo > 1
        test_v=1;
        set(handles.histo2_menu,'Visible','on')
        set(handles.histo_v,'Visible','on')
        set(handles.histo2_menu,'String',menu_histo)
        set(handles.histo2_menu,'Value',2)
        histo2_menu_Callback(handles.histo2_menu,[], handles)
    end
end
if ~test_v
    set(handles.histo2_menu,'Visible','off')
    set(handles.histo_v,'Visible','off')
    cla(handles.histo_v)
    set(handles.histo2_menu,'Value',1)
end

%display time
testimedoc=0;
if isfield(UvData,'XmlData') && isfield(UvData.XmlData,'Time')
    if isempty(num_i2)
        num_i2=num_i1;
    end
    if isempty(num_j1)
        num_j1=1;
    end
    if isempty(num_j2)
        num_j2=num_j1;
    end
    siz=size(UvData.XmlData.Time);
    if siz(1)>=max(num_i1,num_i2) & siz(2)>=max(num_j1,num_j2)
        abstime=(UvData.XmlData.Time(num_i1,num_j1)+UvData.XmlData.Time(num_i2,num_j2))/2;%overset the time read from files
        dt=(UvData.XmlData.Time(num_i2,num_j2)-UvData.XmlData.Time(num_i1,num_j1));
        testimedoc=1;
    end
end
if isfield(UvData,'XmlData_1') && isfield(UvData.XmlData_1,'Time')
    [P,F,str1,str2,str_a,str_b,E,NomType]=name2display(['xx' get(handles.FileIndex_1,'String') get(handles.FileExt_1,'String')]);
    num_i2=str2num(str2);
    if isempty(num_i2)
        num_i2=num_i1;
    end
    num_j1=str2num(str_a);
    if isempty(num_j1)
        num_j1=1;
    end
    num_j2=str2num(str_b);
    if isempty(num_j2)
        num_j2=num_j1;
    end
    num_i1=str2num(str1);
    siz=size(UvData.XmlData_1.Time);
    if siz(1)>=max(num_i1,num_i2) & siz(2)>=max(num_j1,num_j2)
        abstime_1=(UvData.XmlData_1.Time(num_i1,num_j1)+UvData.XmlData_1.Time(num_i2,num_j2))/2;%overset the time read from files
    end
end
set(handles.abs_time,'String',num2str(abstime,4))
set(handles.abs_time_1,'String',num2str(abstime_1,4))
if testimedoc && isfield(UvData,'dt')
    dt=UvData.dt;
end 
if isequal(dt,0)
    set(handles.Dt_txt,'String','')
else
    if ~(isfield(UvData,'TimeUnit') && ~isempty(UvData.TimeUnit))
        set(handles.Dt_txt,'String',['Dt=' num2str(1000*dt,3) '  10^(-3)'] )
    else
        set(handles.Dt_txt,'String',['Dt=' num2str(1000*dt,3) '  m' UvData.TimeUnit] )
    end
end
set(handles.run0,'BackgroundColor',[1 0 0])



%-------------------------------------------------------------------
% --- translate coordinate to matrix index
%-------------------------------------------------------------------
function [indx,indy]=pos2ind(x0,rangx0,nxy)
indx=1+round((nxy(2)-1)*(x0-rangx0(1))/(rangx0(2)-rangx0(1)));% index x of pixel  
indy=1+round((nxy(1)-1)*(y12-rangy0(1))/(rangy0(2)-rangy0(1)));% index y of pixel

%-------------------------------------------------------------------
% --- Executes on button press in 'FixedLimits'.
%-------------------------------------------------------------------
function FixedLimits_Callback(hObject, eventdata, handles)
test=get(handles.FixedLimits,'Value');
if test
    set(handles.FixedLimits,'BackgroundColor',[1 1 0])
else
    set(handles.FixedLimits,'BackgroundColor',[0.7 0.7 0.7])
end

%-------------------------------------------------------------------
% --- Executes on button press in auto_xy.
function auto_xy_Callback(hObject, eventdata, handles)
test=get(handles.auto_xy,'Value');
if test
    set(handles.auto_xy,'BackgroundColor',[1 1 0])
    cla(handles.axes3)
    update_plot(handles)
else
    set(handles.auto_xy,'BackgroundColor',[0.7 0.7 0.7])
    update_plot(handles)
%     axis(handles.axes3,'image')
end


%-------------------------------------------------------------------

%-------------------------------------------------------------------
% --- Executes on button press in 'zoom'.
%-------------------------------------------------------------------
function zoom_Callback(hObject, eventdata, handles)

if (get(handles.zoom,'Value') == 1); 
    set(handles.zoom,'BackgroundColor',[1 1 0])
    set(handles.FixedLimits,'Value',1)% propose by default fixed limits for the plotting axes
    set(handles.FixedLimits,'BackgroundColor',[1 1 0]) 
else
    set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
end


%-------------------------------------------------------------------
%----Executes on button press in 'record': records the current flags of manual correction.
%-------------------------------------------------------------------
function record_Callback(hObject, eventdata, handles)
% [filebase,num_i1,num_j1,num_i2,num_j2,Ext,NomType,SubDir]=read_input_file(handles);
filename=read_file_boxes(handles);
AxeData=get(gca,'UserData');
[erread,message]=fileattrib(filename);
if ~isempty(message) && ~isequal(message.UserWrite,1)
     msgbox_uvmat('ERROR',['no writting access to ' filename])
     return
end
test_civ2=isequal(get(handles.civ2,'BackgroundColor'),[1 1 0]);
test_civ1=isequal(get(handles.civ1,'BackgroundColor'),[1 1 0]);
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
hhh=which('netcdf.open');% look for built-in matlab netcdf library
if ~isequal(hhh,'')% case of new builtin Matlab netcdf library
    nc=netcdf.open(filename,'NC_WRITE'); 
    netcdf.reDef(nc)
    netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),attrname,1)
    dimid = netcdf.inqDimID(nc,nbname); 
    try
        varid = netcdf.inqVarID(nc,flagname);% look for already existing fixflag variable
    catch
        varid=netcdf.defVar(nc,flagname,'double',dimid);%create fixflag variable if it does not exist
    end
    netcdf.endDef(nc)
    netcdf.putVar(nc,varid,AxeData.FF);
    netcdf.close(nc)  
else %old netcdf library
    netcdf_toolbox(filename,AxeData,attrname,nbname,flagname)
end

function netcdf_toolbox(filename,AxeData,attrname,nbname,flagname)
nc=netcdf(filename,'write'); %open netcdf file
result=redef(nc);
eval(['nc.' attrname '=1;']);
theDim=nc(nbname) ;% get the number of velocity vectors
nb_vectors=size(theDim);
var_FixFlag=ncvar(flagname,nc);% var_FixFlag will be written as the netcdf variable vec_FixFlag
var_FixFlag(1:nb_vectors)=AxeData.FF;% 
fin=close(nc);


%-------------------------------------------------------------------
%determines the fields to read from the interface
%------------------------------------------------------------------
function [VelType,civ]=setfield(handles)

VelType=[]; %default
if (get(handles.civ1,'Value') == 1);
        VelType='civ1';
% interp1   
elseif (get(handles.interp1,'Value') == 1);
    VelType='interp1';
% filter1   
elseif (get(handles.filter1,'Value') == 1); 
    VelType='filter1';  
% CIV2
elseif (get(handles.civ2,'Value') == 1);
    VelType='civ2';
% interp2   
elseif (get(handles.interp2,'Value') == 1); 
    VelType='interp2';
% filter2   
elseif (get(handles.filter2,'Value') == 1);  
    VelType='filter2'; 
end 

if isequal(get(handles.filter2,'Visible'),'on');
    civ=6;
% interp1   
elseif isequal(get(handles.interp2,'Visible'),'on');
    civ=5;
% filter1   
elseif isequal(get(handles.civ2,'Visible'),'on'); 
    civ=4;  
% CIV2
elseif isequal(get(handles.filter1,'Visible'),'on');
   civ=3;
% interp2   
elseif isequal(get(handles.interp1,'Visible'),'on'); 
    civ=2;
% filter2   
elseif isequal(get(handles.civ1,'Visible'),'on');  
    civ=1; 
else
    civ=0;
end 

%-------------------------------------------------------------------
%determines the veltype of the second field to read from the iinterface
%------------------------------------------------------------------
function VelType=setfield_1(handles)

VelType=[]; %default
if (get(handles.civ1_1,'Value') == 1);
    VelType='civ1';
% interp1   
elseif (get(handles.interp1_1,'Value') == 1);
    VelType='interp1';
% filter1   
elseif (get(handles.filter1_1,'Value') == 1); 
    VelType='filter1';  
% CIV2
elseif (get(handles.civ2_1,'Value') == 1);
    VelType='civ2';
% interp2   
elseif (get(handles.interp2_1,'Value') == 1); 
    VelType='interp2';
% filter2   
elseif (get(handles.filter2_1,'Value') == 1);  
    VelType='filter2'; 
end 


%---------------------------------------------------
% --- Executes on button press in SubField
function SubField_Callback(hObject, eventdata, handles)
huvmat=get(handles.run0,'parent');
UvData=get(huvmat,'UserData');
if get(handles.SubField,'Value')==0% if the subfield button is desactivated   
    set(handles.RootPath_1,'String','')
    set(handles.RootFile_1,'String','')
    set(handles.SubDir_1,'String','');
    set(handles.FileIndex_1,'String','');
    set(handles.FileExt_1,'String','');
    set(handles.RootPath_1,'Visible','off')
    set(handles.RootFile_1,'Visible','off')
    set(handles.SubDir_1,'Visible','off');
    set(handles.FileIndex_1,'Visible','off');
    set(handles.FileExt_1,'Visible','off');
    set(handles.Fields_1,'Value',1);%set to blank state
    set_veltype_display([handles.civ1_1 handles.interp1_1 handles.filter1_1 ...
            handles.civ2_1 handles.interp2_1 handles.filter2_1],0)
    if isfield(UvData,'XmlData_1')
        UvData=rmfield(UvData,'XmlData_1');
    end 
    set(huvmat,'UserData',UvData);
    run0_Callback(hObject, eventdata, handles); %run
else
    MenuBrowse_1_Callback(hObject, eventdata, handles)
end

% %----------------------------------------------
% %read the data displayed for the input rootfile windows (new)
% %-------------------------------------------------
function [FileName,RootPath,FileBase,FileIndices,FileExt,SubDir]=read_file_boxes(handles)
RootPath=get(handles.RootPath,'String');
FileName=RootPath; %default
SubDir=get(handles.SubDir,'String');
if ~isempty(SubDir) && ~isequal(SubDir,'')
    if (isequal(SubDir(1),'/')|| isequal(SubDir(1),'\'))
        SubDir(1)=[]; %suppress possible / or \ separator
    end
    FileName=fullfile(RootPath,SubDir);
end
RootFile=get(handles.RootFile,'String');
if ~isempty(RootFile) && ~isequal(RootFile,'')
    if (isequal(RootFile(1),'/')|| isequal(RootFile(1),'\'))
        RootFile(1)=[]; %suppress possible / or \ separator
    end
    FileName=fullfile(FileName,RootFile);
end
FileBase=fullfile(RootPath,RootFile);
FileIndices=get(handles.FileIndex,'String');
FileExt=get(handles.FileExt,'String');
FileName=[FileName FileIndices FileExt];

%----------------------------------------------
%read the data displayed for the second input rootfile windows
%-------------------------------------------------
function [FileName_1,RootPath_1,FileBase_1,FileIndices_1,FileExt_1,SubDir_1]=read_file_boxes_1(handles)
RootPath_1=get(handles.RootPath_1,'String'); % read the data from the file1_input window
if isequal(RootPath_1,'"'),RootPath_1=get(handles.RootPath,'String'); end;
FileName_1=RootPath_1; %default
SubDir_1=get(handles.SubDir_1,'String');
if isequal(SubDir_1,'"')
    SubDir_1=get(handles.SubDir,'String');
end
if ~isempty(SubDir_1) && ~isequal(SubDir_1,'')
    if (isequal(SubDir_1(1),'/')|| isequal(SubDir_1(1),'\'))
        SubDir_1(1)=[]; %suppress possible / or \ separator
    end
    FileName_1=fullfile(RootPath_1,SubDir_1);
end
RootFile_1=get(handles.RootFile_1,'String');
if isequal(RootFile_1,'"'),RootFile_1=get(handles.RootFile,'String'); end;
if ~isempty(RootFile_1) && ~isequal(RootFile_1,'')
    if ~(isequal(RootFile_1(1),'/')|isequal(RootFile_1(1),'\'))
        RootFile_1(1)=[];%suppress possible / or \ separator
    end
    FileName_1=fullfile(FileName_1,RootFile_1);
end
FileBase_1=fullfile(RootPath_1,RootFile_1);
FileIndices_1=get(handles.FileIndex_1,'String');
FileExt_1=get(handles.FileExt_1,'String');
if isequal(FileExt_1,'"'),FileExt_1=get(handles.FileExt,'String'); end;
FileName_1=[FileName_1 FileIndices_1 FileExt_1];

%---------------------------------------------------
% --- Executes on menu selection Fields
function Fields_Callback(hObject, eventdata, handles)
%-------------------------------------------------

list_fields=get(handles.Fields,'String');% list menu fields
index_fields=get(handles.Fields,'Value');% selected string index
field= list_fields{index_fields(1)}; % selected string
if isequal(field,'get_field...')
     veltype_handles=[handles.civ1 handles.interp1 handles.filter1 handles.civ2 handles.interp2 handles.filter2];
     set_veltype_display(veltype_handles,0) % unvisible civ buttons
     filename=read_file_boxes(handles);
     hget_field=findobj(allchild(0),'name','get_field');
     if ~isempty(hget_field)
         delete(hget_field)
     end
     get_field(filename)
    return %no action
end
list_fields=get(handles.Fields_1,'String');% list menu fields
index_fields=get(handles.Fields_1,'Value');% selected string index
field_1= list_fields{index_fields(1)}; % selected string
UvData=get(handles.uvmat,'UserData');

%read the rootfile input display
FileExt=get(handles.FileExt,'String');
[P,F,str1,str2,str_a,str_b,E,NomType]=name2display(['xxx' get(handles.FileIndex,'String') FileExt]);
NomTypeNew=NomType;%default
if isequal(field,'image') 
    % transform netc type to the corresponding image type
    if isequal(NomType,'_i1-i2_j')||isequal(NomType,'_i_j1-j2')|| isequal(NomType,'#_ab')|| isequal(NomType,'_i1-i2')
        UvData.SubDir=get(handles.SubDir,'String'); %preserve the subdir in memory
        if ~isempty(UvData.SubDir) && (isequal(UvData.SubDir(1),'/')||isequal(UvData.SubDir(1),'/'))
            UvData.SubDir(1)=[];
        end
        set(handles.SubDir,'String','')
        set(handles.FileExt,'String','.png');
        if isequal(NomType,'_i1-i2_j')||isequal(NomType,'_i_j1-j2')
            NomTypeNew='_i_j';
        elseif isequal(NomType,'#_ab')
            NomTypeNew='#a';
        elseif isequal(NomType,'_i1-i2')
            NomTypeNew='_i';
        end  
    end
    veltype_handles=[handles.civ1 handles.interp1 handles.filter1 handles.civ2 handles.interp2 handles.filter2];
    set_veltype_display(veltype_handles,0) % unvisible civ buttons
else
    ext=get(handles.FileExt,'String');
    if ~isequal(ext,'.nc') %find the new NomType if the previous display was not already a netcdf file
         MenuBrowse_Callback(hObject, eventdata, handles)
    end
    if isequal(field,'vort') || isequal(field,'div') || isequal(field,'strain')
        set(handles.civ1,'BackgroundColor',[0.702 0.702 0.702]) % put their color to grey
        set(handles.civ2,'BackgroundColor',[0.702 0.702 0.702])
        set(handles.interp1,'BackgroundColor',[0.702 0.702 0.702])
        set(handles.interp2,'BackgroundColor',[0.702 0.702 0.702])
    elseif isequal(field,'more...'); 
        set(handles.civ1,'BackgroundColor',[0.702 0.702 0.702]) % put their color to grey
        set(handles.civ2,'BackgroundColor',[0.702 0.702 0.702])
        str=calc_field;%get the list of available scalars by the function calc_scal
        [ind_answer] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',str);
       % edit the choice in the field and action menu
        scalar=cell2mat(str(ind_answer));
        menu=update_menu(handles.Fields,scalar);
        menu=[{''};menu];
        set(handles.Fields_1,'String',menu);% store the selected scalar type
    end
end
indices=name_generator('',str2double(str1),str2double(str_a),'',NomTypeNew,1,str2double(str2),str2double(str_b),'');
set(handles.FileIndex,'String',indices)
set(handles.FileIndex,'UserData',NomTypeNew)
%common to Fields_1_Callback
if isequal(field,'image')||isequal(field_1,'image')
    set(handles.npx_title,'Visible','on')% visible npx,pxcm... buttons
    set(handles.npy_title,'Visible','on')
    set(handles.npx,'Visible','on')
    set(handles.npy,'Visible','on')
    set(handles.fix_pair,'Value',0)
else
    set(handles.npx_title,'Visible','off')% visible npx,pxcm... buttons
    set(handles.npy_title,'Visible','off')
    set(handles.npx,'Visible','off')
    set(handles.npy,'Visible','off')
    set(handles.fix_pair,'Value',1)
end
setfield(handles);% update the field structure ('civ1'....)

if ~isfield(UvData,'NewSeries')||isequal(UvData.NewSeries,0)
    run0_Callback(hObject, eventdata, handles)
end

%---------------------------------------------------
% --- Executes on menu selection Fields
function Fields_1_Callback(hObject, eventdata, handles)
%-------------------------------------------------
list_fields=get(handles.Fields,'String');% list menu fields
index_fields=get(handles.Fields,'Value');% selected string index
field= list_fields{index_fields(1)}; % selected string
list_fields=get(handles.Fields_1,'String');% list menu fields
index_fields=get(handles.Fields_1,'Value');% selected string index
field_1= list_fields{index_fields(1)}; % selected string for the second field
if isequal(field_1,'') %remove second field if 'blank' field is selected
    set(handles.SubField,'Value',0)
    SubField_Callback(hObject, eventdata, handles)
    return
end
UvData=get(handles.uvmat,'UserData');

%read the rootfile input display
FileExt_prev=get(handles.FileExt_1,'String');
if isempty(FileExt_prev)|isequal(FileExt_prev,'')
    FileExt_1=get(handles.FileExt,'String');
else
    FileExt_1=FileExt_prev;
end
NomType_1=get(handles.FileIndex_1,'UserData');
if isempty(NomType_1)|isequal(NomType_1,'')
    NomType_1=get(handles.FileIndex,'UserData');
end
NomTypeNew=NomType_1;%default

set(handles.SubField,'Value',1)%introduce second field
if isfield(UvData,'XmlData')
    UvData.XmlData_1=UvData.XmlData;
end
set(handles.FileIndex_1,'Visible','on')
set(handles.FileExt_1,'Visible','on')
RootPath_1=get(handles.RootPath_1,'String');
RootFile_1=get(handles.RootFile_1,'String');
if isempty(RootPath_1)|isequal(RootPath_1,'')
    set(handles.RootPath_1,'String','"')
end
if isempty(RootFile_1) | isequal(RootFile_1,'')
    set(handles.RootFile_1,'String','"')
end
if ~isempty(RootFile_1)&(isequal(RootFile_1(1),'/')|isequal(RootFile_1(1),'\'))
    RootFile_1(1)=[];
end

if isequal(field_1,'get_field...')
     veltype_handles=[handles.civ1 handles.interp1 handles.filter1 handles.civ2 handles.interp2 handles.filter2];
     set_veltype_display(veltype_handles,0) % unvisible civ buttons
     filename=read_file_boxes_1(handles);
     hget_field=findobj(allchild(0),'name','get_field_1');
     if ~isempty(hget_field)
         delete(hget_field)
     end
     hget_field=get_field(filename);
     set(hget_field,'name','get_field_1')
    return %no action
end
if isequal(field_1,'image') 
    % transform netc type to the corresponding image type
    set(handles.FileExt_1,'String','.png');
    if isequal(NomType_1,'_i1-i2_j')|isequal(NomType_1,'_i_j1-j2')| isequal(NomType_1,'#_ab')| isequal(NomType_1,'_i1-i2')
        UvData.SubDir_1=get(handles.SubDir_1,'String'); %preserve the subdir in memory
        set(handles.SubDir_1,'String','')
%         set(handles.FileExt_1,'String','.png');        
        if isequal(NomType_1,'_i1-i2_j')|isequal(NomType_1,'_i_j1-j2')
            NomTypeNew='_i_j';
        elseif isequal(NomType_1,'#_ab')
            NomTypeNew='#a';
        elseif isequal(NomType_1,'_i1-i2')
            NomTypeNew='_i';
        end  
    end
    veltype_handles=[handles.civ1_1 handles.interp1_1 handles.filter1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1];
    set_veltype_display(veltype_handles,0) % unvisible civ buttons
else
    set(handles.SubDir_1,'Visible','on')
    if ~isequal(FileExt_prev,'.nc') %find the new NomType if the previous display was not already a netcdf file
        veltype_handles=[handles.civ1_1 handles.interp1_1 handles.filter1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1];
        set_veltype_display(veltype_handles,6); % make all civ buttons visible
        RootPath_1=get(handles.RootPath_1,'String');
        RootFile_1=get(handles.RootFile_1,'String');
        if isempty(RootPath_1)|isequal(RootPath_1,'')
            set(handles.RootPath_1,'String','"')
        end
        if isempty(RootFile_1) | isequal(RootFile_1,'')
            set(handles.RootFile_1,'String','"')
        end
        if ~isempty(RootFile_1)&(isequal(RootFile_1(1),'/')|isequal(RootFile_1(1),'\'))
            RootFile_1(1)=[];
        end
        filebase_1=fullfile(RootPath_1,RootFile_1);
        SubDir_1=get(handles.SubDir,'String');
        if isempty(SubDir_1)|isequal(SubDir_1,'')
            if isfield(UvData,'SubDir_1')
                SubDir_1=UvData.SubDir_1;%retrieve previous subdir
            else
                SubDir_1='?';
            end
        end
        if isequal(NomType_1,'#_ab')|isequal(NomType_1,'_i1-i2_j')|isequal(NomType_1,'_i_j1-j2')|isequal(NomType_1,'_i1-i2')
            NomTypeNew=NomType_1;
        elseif isequal(NomType_1,'#a')
             [filename,idetect,n1,na,n2,nb,SubDir_1]=name_generator(filebase_1, str2num(str1),str2num(str_a),'.nc','#_ab',0,[],[],SubDir_1);
             NomTypeNew='#_ab';
        elseif isequal(NomType_1,'_i_j')
             [filename,idetect,n1,na,n2,nb,SubDir_1]=name_generator(filebase_1,str2num(str1),str2num(str_a),'.nc','_i1-i2_j',0,str2num(str1),[],SubDir_1);
            if idetect==1
                NomTypeNew='_i1-i2_j';
            else
                NomTypeNew='_i_j1-j2';
            end
        else %for instance avi files or any ima_num series
            [filename,idetect,n1,na,n2,nb,SubDir_1]=name_generator(filebase_1,str2num(str1),str2num(str_a),'.nc','_i1-i2',0,str2num(str1),[],SubDir_1);
            NomTypeNew='_i1-i2';
        end            
        [Path,Name]=fileparts(filebase_1);
        set(handles.FileExt_1,'String','.nc');
        if ~isempty(SubDir_1) & ~isequal(SubDir_1,'''')& ~isequal(SubDir_1,'"')
            SubDir_1=['/' SubDir_1];
        end
        set(handles.SubDir_1,'String',SubDir_1);
    end
    if isequal(field,'vort') | isequal(field,'div') | isequal(field,'strain')
        set(handles.civ1_1,'BackgroundColor',[0.702 0.702 0.702]) % put their color to grey
        set(handles.civ2_1,'BackgroundColor',[0.702 0.702 0.702])
        set(handles.interp1_1,'BackgroundColor',[0.702 0.702 0.702])
        set(handles.interp2_1,'BackgroundColor',[0.702 0.702 0.702])
    elseif isequal(field_1,'more...'); %add new item to the menu
        set(handles.civ1_1,'BackgroundColor',[0.702 0.702 0.702]) % put their color to grey
        set(handles.civ2_1,'BackgroundColor',[0.702 0.702 0.702])
        str=calc_field;%get the list of available scalars by the function calc_scal
        [ind_answer,v] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',str);
       % edit the choice in the field and action menu
        scalar=cell2mat(str(ind_answer));
        menu=update_menu(handles.Fields_1,scalar);
        set(handles.Fields_1,'String',menu);% store the selected scalar type
    end
end
str1=get(handles.i1,'String');
str2=get(handles.i2,'String');
str_a=get(handles.j1,'String');
str_b=get(handles.j2,'String');
indices=name_generator('',str2num(str1),stra2num(str_a),'',NomTypeNew,1,str2num(str2),stra2num(str_b),'');
set(handles.FileIndex_1,'String',indices)
set(handles.FileIndex_1,'UserData',NomTypeNew)

%common to Fields_Callback
if isequal(field,'image')|isequal(field_1,'image')
    set(handles.npx_title,'Visible','on')% visible npx,pxcm... buttons
    set(handles.npy_title,'Visible','on')
    set(handles.npx,'Visible','on')
    set(handles.npy,'Visible','on')
    set(handles.fix_pair,'Value',0)
else
    set(handles.npx_title,'Visible','off')% visible npx,pxcm... buttons
    set(handles.npy_title,'Visible','off')
    set(handles.npx,'Visible','off')
    set(handles.npy,'Visible','off')
    set(handles.fix_pair,'Value',1)
end
if isequal(field,'velocity')|isequal(field_1,'velocity');
    state_vect='on';
else
    state_vect='off';
end 
if ~isequal(field,'velocity')|(~isequal(field_1,'velocity')&~isequal(field_1,''));
    state_scal='on';
else
    state_scal='off';
end 
set(handles.uvmat,'UserData',UvData)
setfield(handles);% update the field structure ('civ1'....)
if ~isfield(UvData,'NewSeries')|isequal(UvData.NewSeries,0)
    run0_Callback(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% --- set the visibility of relevant velocity type menus: 
function set_veltype_display(handles,Civ)
%------------------------------------------------------------------------
%Civ=0; all states 'off'
%Civ=6; all states 'on'
if isequal(Civ,0)
    imax=0;
%    set(handles(1),'Visible','on')  % unvisible civ buttons
% else
%    set(handles(1),'String','civ1') 
% end
elseif isequal(Civ,1) || isequal(Civ,2)
   imax=1;
elseif isequal(Civ,3) 
    imax=3;
elseif isequal(Civ,4) || isequal(Civ,5)
    imax=4;
elseif isequal(Civ,6) %patch2
    imax=6;
end
for ibutton=1:imax;
    set(handles(ibutton),'Visible','on')  % unvisible civ buttons
end
% for ibutton=max(imax+1,2):6;
for ibutton=imax+1:6;
    set(handles(ibutton),'Visible','off')  % unvisible civ buttons
    set(handles(ibutton),'Value',0)%unactivate unvisible buttons
end

%-------------------------------------------------------------------
% --- Executes on button press in civ1.
function civ1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.civ1,'Value')==1
    reset_vel_type([handles.interp1 handles.civ2 handles.filter1 handles.interp1 handles.interp2 handles.filter2],handles.civ1)
else
    reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------
% --- Executes on button press in interp1.
function interp1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.interp1,'Value')==1
    reset_vel_type([handles.civ1 handles.civ2 handles.filter1 handles.interp2 handles.filter2],handles.interp1)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------
% --- Executes on button press in filter1.
function filter1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.filter1,'Value')==1
    reset_vel_type([handles.civ1 handles.civ2 handles.interp1 handles.interp2 handles.filter2],handles.filter1)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------
% --- Executes on button press in civ2.
function civ2_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.civ2,'Value')==1
    reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.interp2 handles.filter2],handles.civ2)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%-----------------------------------------
% --- Executes on button press in interp2.
%-------------------------------------------
function interp2_Callback(hObject, eventdata, handles)
if get(handles.interp2,'Value')==1
    reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.filter2],handles.interp2)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)
%---------------------------------------------
% --- Executes on button press in filter2.
%-------------------------------------------
function filter2_Callback(hObject, eventdata, handles)
if get(handles.filter2,'Value')==1
    reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2],handles.filter2)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%---------------------------------------------
function civ1_1_Callback(hObject, eventdata, handles)
%---------------------------------------------
if get(handles.civ1_1,'Value')==1
    reset_vel_type([handles.interp1_1 handles.civ2_1 handles.filter1_1 handles.interp1_1 handles.interp2_1 handles.filter2_1],handles.civ1_1)
else
     reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function interp1_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.interp1_1,'Value')==1
    reset_vel_type([handles.civ1_1 handles.civ2_1 handles.filter1_1 handles.interp2_1 handles.filter2_1],handles.interp1_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function filter1_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.filter1_1,'Value')==1
    reset_vel_type([handles.interp1_1 handles.civ2_1 handles.interp1_1 handles.interp2_1 handles.filter2_1],handles.filter1_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function civ2_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.civ2_1,'Value')==1
    reset_vel_type([handles.civ1_1 handles.interp1_1  handles.filter1_1 handles.interp2_1 handles.filter2_1],handles.civ2_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function interp2_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.interp2_1,'Value')==1
    reset_vel_type([handles.civ1_1 handles.civ2_1 handles.filter1_1 handles.interp1_1 handles.filter2_1],handles.interp2_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function filter2_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.filter2_1,'Value')==1
    reset_vel_type([handles.civ1_1 handles.interp1_1 handles.civ2_1 handles.filter1_1 handles.interp1_1 handles.interp2_1],handles.filter2_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%-----------------------------------------------
% --- reset civ buttons
function reset_vel_type(handles_civ0,handle1)
for ibutton=1:length(handles_civ0)
    set(handles_civ0(ibutton),'BackgroundColor',[0.831 0.816 0.784])
    set(handles_civ0(ibutton),'Value',0)
end
if exist('handle1','var')%handles of selected button
	set(handle1,'BackgroundColor',[1 1 0])  
end

%-------------------------------------------------------
% --- Executes on button press in MENUVOLUME.
%-------------------------------------------------------
function VOLUME_Callback(hObject, eventdata, handles)
%errordlg('command VOL not implemented yet')
if ishandle(handles.UVMAT_title)
    delete(handles.UVMAT_title)
end
UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 
if isequal(get(handles.VOLUME,'Value'),1)
    set(handles.zoom,'Value',0)
    set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)
    set(handles.edit,'Value',0)
    set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
%     set(handles.cal,'Value',0)
%     set(handles.cal,'BackgroundColor',[0 1 0])
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)
    %initiate set_object GUI
    data.TITLE='VOLUME';
    if isfield(UvData,'CoordType')
        data.CoordType=UvData.CoordType;
    end
    if isfield(UvData,'Mesh')&~isempty(UvData.Mesh)
        data.RangeY=UvData.Mesh;
        data.RangeX=UvData.Mesh;
        data.DX=UvData.Mesh;
        data.DY=UvData.Mesh;
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
                                                      % associate the set_edit interface handle to the plotting axes
    if isfield(UvData,'SetObjectOrigin')                                                
    pos_uvmat=get(huvmat,'Position');
    pos_set_object(1:2)=UvData.SetObjectOrigin + pos_uvmat(1:2);
    pos_set_object(3:4)=UvData.SetObjectSize .* pos_uvmat(3:4);  
    set(hset_object,'Position',pos_set_object)
    end
    UvData.MouseAction='create_object';
else
    set(handles.VOLUME,'BackgroundColor',[0 1 0])
    UvData.MouseAction='none';
end
set(huvmat,'UserData',UvData)

%-------------------------------------------------------
function edit_vect_Callback(hObject, eventdata, handles)
%-------------------------------------------------------

UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 
if isequal(get(handles.edit_vect,'Value'),1)
    test_civ2=isequal(get(handles.civ2,'BackgroundColor'),[1 1 0]);
    test_civ1=isequal(get(handles.civ1,'BackgroundColor'),[1 1 0]);
    if ~test_civ2 && ~test_civ1
        msgbox_uvmat('ERROR','manual correction only possible for CIV1 or CIV2 velocity fields')
    end 
    set(handles.record,'Visible','on')
    set(handles.edit_vect,'BackgroundColor',[1 1 0])
    set(handles.edit,'Value',0)
    set(handles.zoom,'Value',0)
    set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
%     set(handles.create,'Value',0)
%     set(handles.create,'BackgroundColor',[0 1 0])
    set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
    set(gcf,'Pointer','arrow')
    UvData.MouseAction='edit_vect';
else
    set(handles.record,'Visible','off')
    set(handles.edit_vect,'BackgroundColor',[0.7 0.7 0.7])
    UvData.MouseAction='none';
end
set(handles.uvmat,'UserData',UvData)

%----------------------------------------------
function save_mask_Callback(hObject, eventdata, handles)
%-----------------------------------------------------------------------
huvmat=get(handles.save_mask,'parent');
UvData=get(huvmat,'UserData');

hpatch=findobj(huvmat,'Type','patch');
flag=1;
npx=size(UvData.Field.A,2);
npy=size(UvData.Field.A,1);
xi=[0.5:npx-0.5];
yi=[0.5:npy-0.5];
[Xi,Yi]=meshgrid(xi,yi);
if isfield(UvData,'Object')
    for iobj=1:length(UvData.Object)
        ObjectData=UvData.Object{iobj};
        if isfield(ObjectData,'ProjMode') &&(isequal(ObjectData.ProjMode,'mask_inside')||isequal(ObjectData.ProjMode,'mask_outside'));
            flagobj=1;
            testphys=0; %coordinates in pixels by default
            if isfield(ObjectData,'CoordType') && isequal(ObjectData.CoordType,'phys')
                if isfield(UvData,'XmlData')&& isfield(UvData.XmlData,'GeometryCalib')
                    Calib=UvData.XmlData.GeometryCalib;
                    testphys=1;
                end
            end
            if isfield(ObjectData,'Coord')& isfield(ObjectData,'Style') 
                if isequal(ObjectData.Style,'polygon') 
                    X=ObjectData.Coord(:,1);
                    Y=ObjectData.Coord(:,2);
                    if testphys
                        [X,Y]=px_XYZ(Calib,X,Y,0);% to generalise with 3D cases
                    end
                    flagobj=~inpolygon(Xi,Yi,X,Y);%=0 inside the polygon, 1 outside                  
                elseif isequal(ObjectData.Style,'ellipse')
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
                elseif isequal(ObjectData.Style,'rectangle')
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
if ~isempty(RootFile)&(isequal(RootFile(1),'/')| isequal(RootFile(1),'\'))
        RootFile(1)=[];
end
filebase=fullfile(RootPath,RootFile);
list=get(handles.masklevel,'String');
masknumber=num2str(length(list));
maskindex=get(handles.masklevel,'Value');
mask_name=name_generator([filebase '_' masknumber 'mask'],maskindex,1,'.png','_i');
imflag=uint8(255*(0.392+0.608*flag));% =100 for flag=0 (vectors not computed when 20<imflag<200)
imflag=flipdim(imflag,1);
% imflag=uint8(255*flag);% =0 for flag=0 (vectors=0 when 20<imflag<200)
msgbox_uvmat('CONFIRMATION',[mask_name ' saved'])
imwrite(imflag,mask_name,'BitDepth',8); 

%display the mask
%update_mask(handles,num_i1,num_j1)
figure;
vec=linspace(0,1,256);%define a linear greyscale colormap
map=[vec' vec' vec'];
colormap(map)

image(imflag);

%-------------------------------------------------------------------
%-------------------------------------------------------------------
%  - FUNCTIONS FOR SETTING PLOTTING PARAMETERS

%------------------------------------------------------------------



%------------------------------------------------------------------
% --- Executes on selection change in col_vec: choice of the color code.
%
function col_vec_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
% edit the choice for color code
list_code=get(handles.col_vec,'String');% list menu fields
index_code=get(handles.col_vec,'Value');% selected string index
col_code= list_code{index_code(1)}; % selected field
if isequal(col_code,'black') | isequal(col_code,'white')
   set(handles.slider1,'Visible','off')
   set(handles.slider2,'Visible','off')
   set(handles.colcode1,'Visible','off')
   set(handles.colcode2,'Visible','off')
   set(handles.AutoVecColor,'Visible','off')
   set_vec_col_bar(handles)
else
   set(handles.slider1,'Visible','on')
   set(handles.slider2,'Visible','on') 
   set(handles.colcode1,'Visible','on')
   set(handles.colcode2,'Visible','on')
   set(handles.AutoVecColor,'Visible','on')  
   if isequal(col_code,'ima_cor')
       set(handles.AutoVecColor,'Value',0)%fixed scale by default
       set(handles.vec_col_bar,'Value',0)% 3 colors r,g,b by default
       set(handles.slider1,'Min',0);
       set(handles.slider1,'Max',1);
       set(handles.slider2,'Min',0);
       set(handles.slider2,'Max',1);
 %      set(handles.min_title_vec,'String','0')
       set(handles.max_vec,'String','1')
       set(handles.colcode1,'String','0.333')
       colcode1_Callback(hObject, eventdata, handles)
       set(handles.colcode2,'String','0.666')
       colcode2_Callback(hObject, eventdata, handles)
   else
       set(handles.AutoVecColor,'Value',1)%auto scale between min,max by default
       set(handles.vec_col_bar,'Value',1)% colormap 'jet' by default
       minval=get(handles.slider1,'Min');
       maxval=get(handles.slider1,'Max');
       set(handles.slider1,'Value',minval)
       set(handles.slider2,'Value',maxval)
       set_vec_col_bar(handles)
   end
%    slider_update(handles)
end
%replot the current graph
run0_Callback(hObject, eventdata, handles)


%----------------------------------------------------------------
% -- Executes on slider movement to set the color code
%
function slider1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
slider1=get(handles.slider1,'Value');
min_val=str2num(get(handles.min_vec,'String'));
max_val=str2num(get(handles.max_vec,'String'));
col=min_val+(max_val-min_val)*slider1;
set(handles.colcode1,'String',num2str(col))
if(get(handles.slider2,'Value') < col)%move also the second slider at the same value if needed
    set(handles.slider2,'Value',col)
    set(handles.colcode2,'String',num2str(col))
end
colcode1_Callback(hObject, eventdata, handles)

%----------------------------------------------------------------
% Executes on slider movement to set the color code
%----------------------------------------------------------------
function slider2_Callback(hObject, eventdata, handles)
slider2=get(handles.slider2,'Value');
min_val=str2num(get(handles.min_vec,'String'));
max_val=str2num(get(handles.max_vec,'String'));
col=min_val+(max_val-min_val)*slider2;
set(handles.colcode2,'String',num2str(col))
if(get(handles.slider1,'Value') > col)%move also the first slider at the same value if needed
    set(handles.slider1,'Value',col)
    set(handles.colcode1,'String',num2str(col))
end
colcode2_Callback(hObject, eventdata, handles)

%----------------------------------------------------------------
%execute on return carriage on the edit box corresponding to slider 1
%----------------------------------------------------------------
function colcode1_Callback(hObject, eventdata, handles)
% col=str2num(get(handles.colcode1,'String'));
% set(handles.slider1,'Value',col) 
set_vec_col_bar(handles)
update_plot(handles)

%----------------------------------------------------------------
%execute on return carriage on the edit box corresponding to slider 2
%----------------------------------------------------------------
function colcode2_Callback(hObject, eventdata, handles)
% col=str2num(get(handles.colcode2,'String'));
% set(handles.slider2,'Value',col) 
% slider2_Callback(hObject, eventdata, handles)
set_vec_col_bar(handles)
update_plot(handles)
%------------------------------------------------------------
%update the slider values after displaying vectors
%--------------------------------------------------------
% function slider_update(handles,auto,minC,colcode1,colcode2,maxC)
% set(handles.slider1,'Min',minC) 
% set(handles.slider1,'Max',maxC)
% set(handles.slider2,'Min',minC) 
% set(handles.slider2,'Max',maxC)
% set(handles.min_title_vec,'String',num2str(minC))
% set(handles.max_vec,'String',num2str(maxC))
% if auto
%         set(handles.colcode1,'String',num2str(colcode1,3))%update display
%         set(handles.colcode2,'String',num2str(colcode2,3))
% end
% set(handles.slider1,'Value',colcode1)%update slider with constant display
% set(handles.slider2,'Value',colcode2)
% set_vec_col_bar(handles)


%-------------------------------------------------------
% --- Executes on button press in AutoVecColor.
%-------------------------------------------------------
function vec_col_bar_Callback(hObject, eventdata, handles)
set_vec_col_bar(handles)

% %--------------------------------------------
% %update the display of color code for vectors
% %--------------------------------------------
% function set_vec_col_bar(handles)
% %get the image of the color display button 'vec_col_bar' in pixels
% uni=get(handles.vec_col_bar,'Unit');
% set(handles.vec_col_bar,'Unit','pixel')
% pos_vert=get(handles.vec_col_bar,'Position');
% set(handles.vec_col_bar,'Unit','Normalized')
% width=ceil(pos_vert(3));
% height=ceil(pos_vert(4));
% %get slider indications
% colcode.min=get(handles.slider1,'Min');
% colcode.max=get(handles.slider1,'Max');
% colcode.colcode1=get(handles.slider1,'Value');
% colcode.colcode2=get(handles.slider2,'Value');
% colcode.option=get(handles.vec_col_bar,'Value');
% colcode.auto=1;
% list_code=get(handles.col_vec,'String');% list menu fields
% index_code=get(handles.col_vec,'Value');% selected string index
% colcode.CName= list_code{index_code(1)}; % selected field used for vector color
% vec_C=colcode.min+(colcode.max-colcode.min)*[0.5:width-0.5]/width;%sample of vec_C values from min to max
% [colorlist,col_vec]=set_col_vec(colcode,vec_C);
% oneheight=ones(1,height);
% A1=colorlist(col_vec,1)*oneheight;
% A2=colorlist(col_vec,2)*oneheight;
% A3=colorlist(col_vec,3)*oneheight;
% A(:,:,1)=A1';
% A(:,:,2)=A2';
% A(:,:,3)=A3';
% set(handles.vec_col_bar,'Cdata',A)

%--------------------------------------------------------
% --- Executes on button press in cal.
function cal_Callback(hObject, eventdata, handles)



%-------------------------------------------------------------
% --- Executes on selection change in transform_fct.
function transform_fct_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------
global nb_builtin

huvmat=get(handles.transform_fct,'parent');
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
   [ppp,transform,ext_fct]=fileparts(FileName);% removes extension .m
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
       for ilist=nb_builtin+1:numel(list_transform)
           ff=functions(list_transform{ilist});
           transform_fct{ilist-nb_builtin}=ff.file;
       end 
        save (profil_perso,'transform_fct','-append'); %store the root name for future opening of uvmat
   end   
end

%check the current path to the selected function
if isa(list_transform{ind_coord},'function_handle')
    func=functions(list_transform{ind_coord});
    set(handles.path_transform,'String',fileparts(func.file)); %show the path to the senlected function
else
    set(handles.path_transform,'String','')
end

set(handles.FixedLimits,'Value',0)
set(handles.FixedLimits,'BackgroundColor',[0.7 0.7 0.7])

UvData=get(huvmat,'UserData');

%delete drawn objects
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
if isfield(UvData,'Object')
     UvData.Object=UvData.Object(1);
end 
list_object=get(handles.list_object_1,'String');
set(handles.list_object_1,'Value',1)
set(handles.list_object_1,'String',list_object(1))
set(handles.list_object_2,'Value',2)
set(handles.list_object_2,'String',[list_object(1);{'...'}])
list_object_2_Callback(hObject, eventdata, handles)



%delete mask if it is displayed 
if isequal(get(handles.mask_test,'Value'),1)%if the mask option is on
   UvData=rmfield(UvData,'MaskName'); %will impose mask refresh  
end
set(huvmat,'UserData',UvData)
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function histo1_menu_Callback(hObject, eventdata, handles)
%--------------------------------------------
%plot first histo
huvmat=get(handles.histo1_menu,'parent');
histo_menu=get(handles.histo1_menu,'String');
histo_value=get(handles.histo1_menu,'Value');
FieldName=histo_menu{histo_value};
UvData=get(huvmat,'UserData');
update_histo(handles.histo_u,huvmat,FieldName)

%----------------------------------------------
function histo2_menu_Callback(hObject, eventdata, handles)
%----------------------------------------------
%plot second histo
huvmat=get(handles.histo2_menu,'parent');
histo_menu=get(handles.histo2_menu,'String');
histo_value=get(handles.histo2_menu,'Value');
FieldName=histo_menu{histo_value};
UvData=get(huvmat,'UserData');
update_histo(handles.histo_v,huvmat,FieldName)


%--------------------------------------------
%read the field .Fieldname stored in UvData and plot its histogram
function update_histo(haxes,huvmat,FieldName)
UvData=get(huvmat,'UserData');

if ~isfield(UvData.Field,FieldName)
    msgbox_uvmat('ERROR',['no field  ' FieldName ' for histogram'])
    return
end
Field=UvData.Field;
FieldHisto=eval(['Field.' FieldName]);
if isfield(Field,'FF') & ~isempty(Field.FF) & isequal(size(Field.FF),size(FieldHisto))
    indsel=find(Field.FF==0);%find values marked as false
    if ~isempty(indsel)
        FieldHisto=FieldHisto(indsel);
    end
end
if isempty(Field)
    msgbox_uvmat('ERROR',['empty field ' FieldName])
else
    nxy=size(FieldHisto);
    Amin=double(min(min(min(FieldHisto))));%min of image
    Amax=double(max(max(max(FieldHisto))));%max of image
    if isequal(Amin,Amax)
       Histo.Txt=['uniform field =' num2str(Amin)];
    else
    Histo.ListVarName={FieldName,'histo'};
    if numel(nxy)==2
        Histo.VarDimName={FieldName,FieldName}; %dimensions for the histogram
    else %color images
        Histo.VarDimName={FieldName,{FieldName,'rgb'}}; %dimensions for the histogram
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
    for col=1:size(FieldHisto,3)
        B=FieldHisto(:,:,col);
        C=reshape(double(B),1,nxy(1)*nxy(2));% reshape in a vector
       eval(['Histo.histo(:,col)=hist(C, Histo.' FieldName ');']);  %calculate histogram
    end
    set(haxes,'XLimMode','auto')%reset auto mode (after zoom effect)
    set(haxes,'YLimMode','auto')
    plot_field(Histo,haxes);
    end
end



%------------------------------------------------
%CALLBACKS FOR PLOTTING PARAMETERS
%-------------------------------------------------

%-----------------------------------------------------------------
function MinA_Callback(hObject, eventdata, handles)
%------------------------------------------
set(handles.AutoScal,'Value',1) %suppress auto mode
set(handles.AutoScal,'BackgroundColor',[1 1 0])
update_plot(handles)

%-----------------------------------------------------------------
function MaxA_Callback(hObject, eventdata, handles)
%--------------------------------------------
set(handles.AutoScal,'Value',1) %suppress auto mode
set(handles.AutoScal,'BackgroundColor',[1 1 0])
update_plot(handles)

%-----------------------------------------------
function AutoScal_Callback(hObject, eventdata, handles)
%--------------------------------------------
test=get(handles.AutoScal,'Value');
if test
    set(handles.AutoScal,'BackgroundColor',[1 1 0])
else
    set(handles.AutoScal,'BackgroundColor',[0.7 0.7 0.7])
    update_plot(handles);
%     set(handles.MinA,'String',num2str(ScalOut.MinA,3))
%     set(handles.MaxA,'String',num2str(ScalOut.MaxA,3))
end

%-------------------------------------------------------------------
function BW_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles)

%-------------------------------------------------------------------
function Contours_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
val=get(handles.Contours,'Value');
if val==2
    set(handles.interval_txt,'Visible','on')
    set(handles.IncrA,'Visible','on')
else
    set(handles.interval_txt,'Visible','off')
    set(handles.IncrA,'Visible','off')
end
update_plot(handles)

%-------------------------------------------------------------------
function IncrA_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles)

%-------------------------------------------------------------------
function HideWarning_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles)

%-------------------------------------------------------------------
function HideFalse_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles)

%-------------------------------------------------------------------
function VecScale_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
set(handles.AutoVec,'Value',1);
set(handles.AutoVec,'BackgroundColor',[1 1 0])
update_plot(handles)

%-------------------------------------------------------------------
function AutoVec_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
test=get(handles.AutoVec,'Value');
if test
    set(handles.AutoVec,'BackgroundColor',[1 1 0])
else
    update_plot(handles);
    %set(handles.VecScale,'String',num2str(ScalOut.VecScale,3))
    set(handles.AutoVec,'BackgroundColor',[0.7 0.7 0.7])
end

%-------------------------------------------------------
% --- Executes on selection change in decimate4 (nb_vec/4).
%-------------------------------------------------------
function decimate4_Callback(hObject, eventdata, handles)
update_plot(handles)


%-------------------------------------------------------
% --- Executes on selection change in color_code menu
%-------------------------------------------------------
function color_code_Callback(hObject, eventdata, handles)
set_vec_col_bar(handles)
update_plot(handles);

%-------------------------------------------------------
% --- Executes on button press in AutoVecColor.
%-------------------------------------------------------
function AutoVecColor_Callback(hObject, eventdata, handles)
test=get(handles.AutoVecColor,'Value');
if test
    set(handles.AutoVecColor,'BackgroundColor',[1 1 0])
else
    update_plot(handles);
    %set(handles.VecScale,'String',num2str(ScalOut.VecScale,3))
    set(handles.AutoVecColor,'BackgroundColor',[0.7 0.7 0.7])
end
%set_vec_col_bar(handles)

%-------------------------------------------------------
% --- Executes on selection change in max_vec.
%-------------------------------------------------------
function min_vec_Callback(hObject, eventdata, handles)
max_vec_Callback(hObject, eventdata, handles)

% --- Executes on selection change in max_vec.
function max_vec_Callback(hObject, eventdata, handles)
set(handles.AutoVecColor,'Value',1)
AutoVecColor_Callback(hObject, eventdata, handles)
min_val=str2num(get(handles.min_vec,'String'));
max_val=str2num(get(handles.max_vec,'String'));
slider1=get(handles.slider1,'Value');
slider2=get(handles.slider2,'Value');
colcode1=min_val+(max_val-min_val)*slider1;
colcode2=min_val+(max_val-min_val)*slider2;
set(handles.colcode1,'String',num2str(colcode1))
set(handles.colcode2,'String',num2str(colcode2))
update_plot(handles);

%-------------------------------------------------------------------
%update the display of color code for vectors
function set_vec_col_bar(handles)
%-------------------------------------------------------------------
%get the image of the color display button 'vec_col_bar' in pixels
set(handles.vec_col_bar,'Unit','pixel');
pos_vert=get(handles.vec_col_bar,'Position');
set(handles.vec_col_bar,'Unit','Normalized');
width=ceil(pos_vert(3));
height=ceil(pos_vert(4));

%get slider indications
list=get(handles.color_code,'String');
ichoice=get(handles.color_code,'Value');
colcode.ColorCode=list{ichoice};
colcode.MinC=str2num(get(handles.min_vec,'String'));
colcode.MaxC=str2num(get(handles.max_vec,'String'));
test3color=strcmp(colcode.ColorCode,'rgb') || strcmp(colcode.ColorCode,'bgr');
if test3color
    colcode.colcode1=str2num(get(handles.colcode1,'String'));
    colcode.colcode2=str2num(get(handles.colcode2,'String'));
end
% colcode.option=get(handles.vec_col_bar,'Value');
colcode.FixedCbounds=0;
% list_code=get(handles.col_vec,'String');% list menu fields
% index_code=get(handles.col_vec,'Value');% selected string index
% colcode.CName= list_code{index_code(1)}; % selected field used for vector color
colcode.FixedCbounds=1;
vec_C=colcode.MinC+(colcode.MaxC-colcode.MinC)*[0.5:width-0.5]/width;%sample of vec_C values from min to max
[colorlist,col_vec]=set_col_vec(colcode,vec_C);
oneheight=ones(1,height);
A1=colorlist(col_vec,1)*oneheight;
A2=colorlist(col_vec,2)*oneheight;
A3=colorlist(col_vec,3)*oneheight;
A(:,:,1)=A1';
A(:,:,2)=A2';
A(:,:,3)=A3';
set(handles.vec_col_bar,'Cdata',A)


%-------------------------------------------------------------------
function [PlotType,ScalOut]=update_plot(handles)
%-------------------------------------------------------------------
haxes= handles.axes3;
AxeData=get(haxes,'UserData');
PlotParam=read_plot_param(handles);
[PlotType,PlotParamOut]= plot_field(AxeData,haxes,PlotParam,1);
write_plot_param(handles,PlotParamOut); %update the auto plot parameters

%-------------------------------------------------------------------
% --- Executes on button press in grid.
function grid_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------

UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 

%suppress the other options if grid is chosen
set(handles.edit_vect,'Value',0)
edit_vect_Callback(hObject, eventdata, handles)
set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
set(handles.edit_vect,'Value',0)  
edit_vect_Callback(hObject, eventdata, handles)
set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
set(handles.list_object_1,'Value',1)      

%prepare display of the set_grid GUI
data.fixedtitle=1;
FileName=read_file_boxes(handles);
[hset_object,UvData.sethandles]=set_grid(FileName);% call the set_object interface
set(handles.uvmat,'UserData',UvData);


%-------------------------------------------------------------------
% --- Executes on selection change in edit.
function edit_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 
test=get(handles.edit,'Value');
if test
    UvData.MouseAction='edit_object';
    set(handles.edit,'BackgroundColor',[1,1,0])  
    %suppress the other options 
    set(handles.zoom,'Value',0)
    zoom_Callback(hObject, eventdata, handles)
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)  
    %list_object_Callback(hObject, eventdata, handles)
else 
    UvData.MouseAction='none';
    set(handles.edit,'BackgroundColor',[0.7,0.7,0.7])   
end
set(handles.uvmat,'UserData',UvData);
hset_object=findobj(allchild(0),'Tag','set_object');
if ~isempty(hset_object)
    hhset_object=guidata(hset_object);
    if test
        set(hhset_object.PLOT,'enable','on');
    else
       set(hhset_object.PLOT,'enable','off'); 
    end
end

%------------------------------------------------------------------------
% --- Executes on selection change in list_object_1.
function list_object_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
list_str=get(handles.list_object_1,'String');
IndexObj=get(handles.list_object_1,'Value');
str_1=list_str{IndexObj};
val_2=get(handles.list_object_2,'Value');
str_2=get(handles.list_object_2,'String');
if isequal(val_2,IndexObj)% if the first selection is equal to the second, it will suppress the second
    set(handles.list_object_2,'Value',numel(str_2))%select the end of the list ('...')
    list_object_2_Callback(hObject, eventdata, handles)
end
update_object(handles,IndexObj,1,str_1)

%------------------------------------------------------------------------
% --- Executes on selection change in list_object_1.
function list_object_2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
list_str=get(handles.list_object_2,'String');
IndexObj=get(handles.list_object_2,'Value');
if isequal(list_str{IndexObj},'...')
    hview_field=findobj(allchild(0),'Tag','view_field');
    if ~isempty(hview_field)
        delete(hview_field)
    end
else
    update_object(handles,IndexObj,2,list_str{IndexObj})
end

%------------------------------------------------------------------------
function update_object(handles,IndexObj,option,ObjectName)
%------------------------------------------------------------------------
UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 
if ~(length(UvData.Object)>=IndexObj);
    return
end
ObjectData=UvData.Object{IndexObj};
ObjectData.Name=ObjectName;
if isequal(get(handles.edit,'Value'),1)
    ObjectData.enable_plot=1; % desable the PLOT option in the set_object GUI (editing mode
end
PlotHandles=get_plot_handles(handles);%get the handles of the interface elements setting the plotting parameters
ZBounds=0; % default
    if isfield(UvData,'ZMin') && isfield(UvData,'ZMax')
        ZBounds(1)=UvData.ZMin; %minimum for the Z slider
        ZBounds(2)=UvData.ZMax;%maximum for the Z slider
    end
hset_object=findobj(allchild(0),'tag','set_object');
if ~isempty(hset_object)
    delete(hset_object)% delete existing version of set_object
end
hset_object=set_object(ObjectData,PlotHandles,ZBounds);% call the set_object interface,
set(hset_object,'name',ObjectName)
% pos_uvmat=get(handles.uvmat,'Position');
% %position the set_object GUI with respect to uvmat
% if isfield(UvData,'SetObjectOrigin')
%     pos_set_object(1:2)=UvData.SetObjectOrigin + pos_uvmat(1:2);
%     pos_set_object(3:4)=UvData.SetObjectSize .* pos_uvmat(3:4);
%     set(hset_object,'Position',pos_set_object)
% end

%project the current field on the object and plot it
ProjData= proj_field(UvData.Field,ObjectData,IndexObj);%project the current interface field on ObjectData
if option==1%length(UvData.Object)>= IndexObj && isfield(UvData.Object{IndexObj},'plotaxes')&& ishandle(UvData.Object{IndexObj}.plotaxes)
    plot_field(ProjData,handles.axes3,PlotHandles);
    UvData.Object{IndexObj}.plotaxes=handles.axes3;
else
    UvData.Object{IndexObj}.plotaxes=view_field(ProjData);
end
set(handles.uvmat,'UserData',UvData)
hother=findobj('Tag','proj_object');%find all the proj objects
for iobj=1:length(hother)
    if isequal(get(hother(iobj),'Type'),'rectangle')|isequal(get(hother(iobj),'Type'),'patch')
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
hother=findobj('Tag','DeformPoint');
set(hother,'Color','b');
set(hother,'Selected','off')    
if isfield(ObjectData,'HandlesDisplay')
    for iview=1:length(ObjectData.HandlesDisplay)
        if ishandle(ObjectData.HandlesDisplay(iview))
            uistack(ObjectData.HandlesDisplay(iview),'top')
            linetype=get(ObjectData.HandlesDisplay(iview),'Type');
            if isequal(linetype,'line')
                set(ObjectData.HandlesDisplay(iview),'Color','m'); %set the selected object to magenta color
            elseif isequal(linetype,'rectangle')
                set(ObjectData.HandlesDisplay(iview),'EdgeColor','m'); %set the selected object to magenta color
            elseif isequal(linetype,'patch')
                set(ObjectData.HandlesDisplay(iview),'FaceColor','m'); %set the selected object to magenta color
            end 
            SubObjectData=get(ObjectData.HandlesDisplay(iview),'UserData');
            if isfield(SubObjectData,'SubObject')& ishandle(SubObjectData.SubObject)
                uistack(SubObjectData.SubObject,'top')
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
            if isfield(SubObjectData,'DeformPoint')& ishandle(SubObjectData.DeformPoint)
                set(SubObjectData.DeformPoint,'Color','m')
            end
        end
    end
end
pause(0.1)
figure(hset_object)%put set_object in front

%------------------------------------------------------
% --- Executes on button press in Menu/Export/field in workspace.
%------------------------------------------------------
function MenuExportField_Callback(hObject, eventdata, handles)
global CurData
huvmat=findobj(allchild(0),'Name','uvmat');
UvData=get(huvmat,'UserData');
CurData=UvData.ProjField_1;
evalin('base','global CurData')%make CurData global in the workspace
display(['UserData of view_field :'])
evalin('base','CurData') %display CurData in the workspace
commandwindow;

%------------------------------------------------------
% --- Executes on button press in Menu/Export/extract figure.
%------------------------------------------------------
function MenuExport_plot_Callback(hObject, eventdata, handles)
huvmat=get(handles.MenuExport_plot,'parent');
UvData=get(huvmat,'UserData');
hfig=figure;
newaxes=copyobj(handles.axes3,hfig);
map=colormap(handles.axes3);
colormap(map);%transmit the current colormap to the zoom fig
colorbar


% --------------------------------------------------------------------
function Insert_Callback(hObject, eventdata, handles)


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


% --------------------------------------------------------------------
function MenuExportMovie_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
set(handles.MenuExportMovie,'BusyAction','queue')% activate the button
huvmat=get(handles.run0,'parent');
UvData=get(huvmat,'UserData');
[xx,xx,FileBase]=read_file_boxes(handles);
 %read the current input file name
prompt = {'movie file name';'frames per second';'frame resolution (*[512x384] pixels)';'axis position relative to the frame';'total frame number (starting from the current uvmat display)'};
dlg_title = 'select properties of the output avi movie';
num_lines= 1;
nbfield_cell=get(handles.last_i,'String');
def     = {[FileBase '_out.avi'];'10';'1';'[0.03 0.05 0.95 0.92]';'10'};
answer = inputdlg(prompt,dlg_title,num_lines,def,'on');
aviname=answer{1};
fps=str2num(answer{2});
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
newaxes=copyobj(handles.axes3,newfig);%new plotting axes in the new figure
set(newaxes,'Tag','movieaxes')
nbpix=[512 384]*str2num(answer{3});
set(gcf,'Position',[1 1 nbpix])% resolution XVGA 
set(newaxes,'Position',eval(answer{4}));
map=colormap(handles.axes3);
colormap(map);%transmit the current colormap to the zoom fig
msgbox_uvmat('INPUT_Y-N',{['adjust figure ' num2str(newfig) ' with its matlab edit menu '] ;...
        ['then press OK to get the avi movie as a copy of figure ' num2str(newfig) ' display']});
UvData.Object{1}.plotaxes=newaxes;% the axis in the new figure becomes the current main plotting axes
set(huvmat,'UserData',UvData);
increment=str2num(get(handles.increment_scan,'String')); %get the field increment d
set(handles.STOP,'Visible','on')
set(handles.speed,'Visible','on')
set(handles.speed_txt,'Visible','on')
set(handles.RunMovie,'BusyAction','queue')

imin=str2num(get(handles.i1,'String'));
imax=str2num(answer{5});
% if isfield(UvData,'Time')
htitle=get(newaxes,'Title');
xlim=get(newaxes,'XLim');
ylim=get(newaxes,'YLim');
set(htitle,'Position',[xlim(2)+0.07*(xlim(2)-xlim(1)) ylim(2)-0.05*(ylim(2)-ylim(1)) 0])
time_str=get(handles.abs_time,'String');
set(htitle,'String',['t=' time_str])
set(handles.speed,'Value',1)
for i=1:imax
    if get(handles.speed,'Value')~=0 & isequal(get(handles.MenuExportMovie,'BusyAction'),'queue') % enable STOP command
            runpm(hObject,eventdata,handles,increment)
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
UvData.Object{1}.plotaxes=handles.axes3;
set(huvmat,'UserData',UvData);
msgbox_uvmat('CONFIRMATION',{['movie ' aviname ' created '];['with ' num2str(imax) ' frames']})


% ------------------------------------------------------------------
function MenuCalib_Callback(hObject, eventdata, handles)

UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 

%suppress competing options 
set(handles.zoom,'Value',0)
set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
set(handles.MenuMask,'enable','off')
set(handles.MenuGrid,'enable','off')
set(handles.MenuObject,'enable','off')
set(handles.MenuEdit,'enable','off')
set(handles.list_object_1,'Value',1)      
% initiate display of GUI geometry_calib
data=[]; %default
if isfield(UvData,'CoordType')
    data.CoordType=UvData.CoordType;
end
pos=get(handles.uvmat,'Position');
pos(1)=pos(1)+pos(3)-0.311+0.04; %0.311= width of the geometry_calib interface (units relative to the srcreen)
pos(2)=pos(2)-0.02;
[FileName,RootPath,FileBase,FileIndices,FileExt,SubDir]=read_file_boxes(handles);
[UvData.hset_object,UvData.sethandles]=geometry_calib(handles,pos,FileName);% call the set_object interface	
pos_uvmat=get(handles.uvmat,'Position');

if isfield(UvData,'CalOrigin')
    pos_cal(1)=pos_uvmat(1)+UvData.CalOrigin(1)*pos_uvmat(3);
    pos_cal(2)=pos_uvmat(2)+UvData.CalOrigin(2)*pos_uvmat(4);
    pos_cal(3:4)=UvData.CalSize .* pos_uvmat(3:4);
    set(UvData.hset_object,'Position',pos_cal)
end
UvData.MouseAction='calib';
set(handles.uvmat,'UserData',UvData);


% ------------------------------------------------------------------
function MenuMask_Callback(hObject, eventdata, handles)
set(handles.TOOLS_txt,'Visible','on')
set(handles.frame_tools,'Visible','on')
% set(handles.create,'Visible','on')
% set(handles.create,'Value',1)
% set(handles.create,'BackgroundColor',[1 1 0]) %visualise in yellow
set(handles.save_mask,'Visible','on')
set(handles.masklevel,'Visible','on')
if isequal(get(handles.z_index,'Visible'),'on')
    nb_slice=str2num(get(handles.nb_slice,'String'));
    for ilist=1:nb_slice
        list_index{ilist,1}=num2str(ilist);
    end   
    set(handles.masklevel,'String',list_index)
    val=str2num(get(handles.z_index,'String'));
    if val<=nb_slice
        set(handles.masklevel,'Value',val)
    end
else
    set(handles.masklevel,'String',{'1'})
    set(handles.masklevel,'Value',1)
end
if ishandle(handles.UVMAT_title)
    delete(handles.UVMAT_title)
end
% huvmat=get(handles.create,'parent');
UvData=get(handles.uvmat,'UserData');%read UvData properties stored on the uvmat interface 
set(handles.zoom,'Value',0)
set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
set(handles.edit_vect,'Value',0)
edit_vect_Callback(hObject, eventdata, handles)
set(handles.edit,'Value',0)
set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
set(handles.edit_vect,'Value',0)  
edit_vect_Callback(hObject, eventdata, handles)
% set(handles.cal,'Value',0)
% set(handles.cal,'BackgroundColor',[0 1 0])

%initiate the GUI set_object
data.TITLE='MASK';
if isfield(UvData,'CoordType')
    data.CoordType=UvData.CoordType;
end
if isfield(UvData,'Mesh')&&~isempty(UvData.Mesh)
    data.YMax=UvData.Mesh;
elseif isfield(UvData.Field,'AX')&&isfield(UvData.Field,'AY')&& isfield(UvData.Field,'A')%only image
    np=size(UvData.Field.A);
    meshx=(UvData.Field.AX(end)-UvData.Field.AX(1))/(np(2)-1);
    meshy=abs(UvData.Field.AY(end)-UvData.Field.AY(1))/(np(1)-1);
    data.YMax=max(meshx,meshy);
    data.DX=max(meshx,meshy);
end
data.Coord=[0 0 0]; %default
PlotHandles=get_plot_handles(handles);%get the handles of the graphic objects setting the plotting parameters
[hset_object,UvData.sethandles]=set_object(data,PlotHandles);% call the set_object interface
pos_uvmat=get(handles.huvmat,'Position');
if isfield(UvData,'SetObjectOrigin')
    pos_set_object(1:2)=UvData.SetObjectOrigin + pos_uvmat(1:2);
    pos_set_object(3:4)=UvData.SetObjectSize .* pos_uvmat(3:4); 
    set(hset_object,'Position',pos_set_object)
end
list_object=get(handles.list_object_1,'String');
if ~isempty(list_object)
    set(handles.list_object_1,'Value',length(list_object))
end
UvData.MouseAction='create_object';
set(handles.uvmat,'UserData',UvData);

% ------------------------------------------------------------------
%-- open the GUI set_grid.fig to create grid
function MenuGrid_Callback(hObject, eventdata, handles)
set(handles.TOOLS_txt,'Visible','on')
set(handles.frame_tools,'Visible','on')
grid_Callback(hObject,eventdata,handles)

%----------------------------------------------------------------
% open the GUI 'series'
%----------------------------------------------------------------
function MenuSeries_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------

[param.FileName]=read_file_boxes(handles);
if isequal(get(handles.SubField,'Value'),1)
    FileName_1=read_file_boxes_1(handles);%
    if ~isequal(FileName_1,param.FileName)
        param.FileName_1=FileName_1;
    end
end
param.NomType=get(handles.FileIndex,'UserData');
param.NomType_1=get(handles.FileIndex_1,'UserData');
param.comp_input=get(handles.fix_pair,'Value');
huvmat=get(handles.MenuSeries,'parent');
UvData=get(huvmat,'UserData');
if isfield(UvData,'Time')
    param.Time=UvData.XmlData.Time;
end
if isequal(get(handles.scan_i,'Value'),1)
    param.incr_i=str2num(get(handles.increment_scan,'String'));
elseif isequal(get(handles.scan_j,'Value'),1)
    param.incr_j=str2num(get(handles.increment_scan,'String'));
end
param.list_fields=get(handles.Fields,'String');% list menu fields
param.list_fields(1)=[]; %suppress  'image' option 
param.index_fields=get(handles.Fields,'Value');% selected string index
if param.index_fields>1
    param.index_fields=param.index_fields-1;
end
param.list_fields_1=get(handles.Fields_1,'String');% list menu fields
param.list_fields_1(1)=[]; %suppress  'image' option
param.index_fields_1=get(handles.Fields_1,'Value')-1;% selected string index
if param.index_fields_1>1
    param.index_fields_1=param.index_fields_1-1;
end
param.civ1=get(handles.civ1,'Value');
param.civ2=get(handles.civ2,'Value');
param.interp1=get(handles.interp1,'Value');
param.interp2=get(handles.interp2,'Value');
param.filter1=get(handles.filter1,'Value');
param.filter2=get(handles.filter2,'Value');
param.menu_coord_str=get(handles.transform_fct,'String');
param.menu_coord_val=get(handles.transform_fct,'Value');

series(param); %run the series interface

% ------------------------------------------------------------------
% -- open the GUI civ.fig for civx (PIV)
% ------------------------------------------------------------------
function MenuPIV_Callback(hObject, eventdata, handles)
 
[FileName,RootPath,filebase,FileIndices,ext,SubDir]=read_file_boxes(handles);
num1=stra2num(get(handles.i1,'String'));
num2=stra2num(get(handles.i2,'String'));
num_a=stra2num(get(handles.j1,'String'));
num_b=stra2num(get(handles.j2,'String'));
NomType=get(handles.FileIndex,'UserData');
ind_opening=1; % default (images): will advice civ1 option by default in the civ interface
if isequal(ext,'.nc') ||  isequal(ext,'.cdf')% netcdf files
    ind_opening=2;% propose 'fix' as the default option
% +read the current netcdf rootfile
    Data=nc2struct(FileName,[]);
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
end      
param.RootName=filebase;
param.NomType=NomType;
param.num1=num1;
param.num2=num2;
param.num_a=num_a;
param.num_b=num_b;
param.SubDir=SubDir;
param.IndOpening=ind_opening;% A REVOIR +TRANSMETTRE IMADOC INFO
param.ImaExt=ext;
civ(param);% interface de civ(not in the uvmat file)

% ------------------------------------------------------------------
function MenuTools_Callback(hObject, eventdata, handles)

% ------------------------------------------------------------------
function MenuEditObject_Callback(hObject, eventdata, handles)
set(handles.edit,'Value',1)
edit_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function enable_transform(handles,state)
set(handles.transform_fct,'Visible',state)
set(handles.TRANSFORM_txt,'Visible',state)    
set(handles.transform_fct,'Visible',state)  
set(handles.path_transform,'Visible',state)
set(handles.pxcmx_txt,'Visible',state)
set(handles.pxcmy_txt,'Visible',state)
set(handles.pxcm,'Visible',state)
set(handles.pycm,'Visible',state)

%------------------------------------------------------------------------
function MenuEditVectors_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.edit_vect,'Visible','on')
set(handles.edit_vect,'Value',1)
edit_vect_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function Menupoints_Callback(hObject, eventdata, handles)
data.Style='points';
data.ProjMode='projection';%default
create_object(data,handles)

% --------------------------------------------------------------------
function Menuline_Callback(hObject, eventdata, handles)
% set(handles.create,'Visible','on')
% set(handles.create,'Value',1)
% LINE_Callback(hObject,eventdata,handles)
data.Style='line';
data.ProjMode='projection';%default
create_object(data,handles)

%------------------------------------------------------------------------
function Menupolyline_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Style='polyline';
data.ProjMode='projection';%default
create_object(data,handles)

%------------------------------------------------------------------------
function Menupolygon_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Style='polygon';
data.ProjMode='inside';%default
create_object(data,handles)

%------------------------------------------------------------------------
function Menurectangle_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Style='rectangle';
data.ProjMode='inside';%default
create_object(data,handles)

%------------------------------------------------------------------------
function Menuellipse_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
data.Style='ellipse';
data.ProjMode='inside';%default
create_object(data,handles)

% ------------------------------------------------------------------
function Menuplane_Callback(hObject, eventdata, handles)
data.Style='plane';
data.ProjMode='projection';%default

create_object(data,handles)

% ------------------------------------------------------------------
function Menuvolume_Callback(hObject, eventdata, handles)
% set(handles.create,'Visible','on')
% set(handles.create,'Value',1)
VOLUME_Callback(hObject,eventdata,handles)

%------------------------------------------------------------------------
function MenuBrowseObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%get the object file 
[FileName, PathName, filterindex] = uigetfile( ...
       {'*.xml;*.mat', ' (*.xml,*.mat)';
       '*.xml',  '.xml files '; ...
        '*.mat',  '.mat matlab files '}, ...
        'Pick a file',get(handles.RootPath,'String'));
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
data.enable_plot=1;
[pp,data.Name]=fileparts(FileName);
%PlotHandles=get_plot_handles(handles);%get the handles of the interface elements setting the plotting parameters
hset_object=findobj(allchild(0),'Name','set_object');
if ~isempty(hset_object)
    delete(hset_object)% delete existing version of set_object
end
UvData=get(handles.uvmat,'UserData');
% [hset_object,UvData.sethandles]=set_object(data);% call the set_object interface
% %position the set_object GUI with respect to uvmat
% pos_uvmat=get(handles.uvmat,'Position');
% if isfield(UvData,'SetObjectOrigin')
%     pos_set_object(1:2)=UvData.SetObjectOrigin + pos_uvmat(1:2);
%     pos_set_object(3:4)=UvData.SetObjectSize .* pos_uvmat(3:4);
%     set(hset_object,'Position',pos_set_object)
% end
set(handles.edit,'Value',0); %suppress the object edit mode
set(handles.edit,'BackgroundColor',[0.7,0.7,0.7])  
UvData.MouseAction='create_object';
set(handles.uvmat,'UserData',UvData)
set(handles.delete_object,'Visible','on')
set(handles.uvmat_title,'Visible','on')
set(handles.view_field_title,'Visible','on')

%------------------------------------------------------------------------
% --- generic function used for the creation of a projection object
function create_object(data,handles)
%------------------------------------------------------------------------
hset_object=findobj(allchild(0),'tag','set_object');
if ~isempty(hset_object)
    delete(hset_object)% delete existing version of set_object
end
UvData=get(handles.uvmat,'UserData');
set(handles.edit,'Value',0); %suppress the object edit mode
set(handles.edit,'BackgroundColor',[0.7,0.7,0.7])  
data.enable_plot=1;
if isfield(UvData,'CoordType')
    data.CoordType=UvData.CoordType;
end
if isfield(UvData,'Mesh')&&~isempty(UvData.Mesh)
    data.RangeX=UvData.Mesh;
    data.RangeY=UvData.Mesh;
    data.DX=UvData.Mesh;
    data.DY=UvData.Mesh;
elseif isfield(UvData.Field,'AX')&& isfield(UvData.Field,'AY')&& isfield(UvData.Field,'A')%only image
    np=size(UvData.Field.A);
    meshx=(UvData.Field.AX(end)-UvData.Field.AX(1))/np(2);
    meshy=abs(UvData.Field.AY(end)-UvData.Field.AY(1))/np(1);
    data.RangeY=max(meshx,meshy);
    data.RangeX=max(meshx,meshy);
    data.DX=max(meshx,meshy);
end 
if isfield(UvData,'NbDim')
    data.NbDim=UvData.NbDim;
end
data.Coord=[0 0 0]; %default
if isfield(data,'Style') && isequal(data.Style,'line')
    if isfield(data,'DX')
        data.Coord=[[0 0 0];[data.DX 0 0]]; %default 
    else
        data.Coord=[[0 0 0];[1 0 0]]; %default 
    end
end
%data.ParentButton=handles.create;
if ishandle(handles.UVMAT_title)
    delete(handles.UVMAT_title)%delete the initial display of uvmat if no field has been entered
end
PlotHandles=get_plot_handles(handles);%get the handles of the interface elements setting the plotting parameters
[hset_object,UvData.sethandles]=set_object(data,PlotHandles);% call the set_object interface

UvData.MouseAction='create_object';
set(handles.uvmat,'UserData',UvData)
set(handles.zoom,'Value',0)
zoom_Callback(handles.uvmat, [], handles)
set(handles.delete_object,'Visible','on')
set(handles.uvmat_title,'Visible','on')
set(handles.view_field_title,'Visible','on')

%------------------------------------------------------------------------
function MenuRuler_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.zoom,'Value',0)
zoom_Callback(handles.uvmat, [], handles)
UvData=get(handles.uvmat,'UserData');
UvData.MouseAction='ruler';
set(handles.uvmat,'UserData',UvData);

%------------------------------------------------------------------------
% --- executed when closing: set the parent interface button to value 0
function closefcn(gcbo,eventdata)
%------------------------------------------------------------------------
%delete all the associated figures if exist
hh=findobj(allchild(0),'tag','view_field');
if ~isempty(hh)
    delete(hh)
end
hh=findobj(allchild(0),'name','geometry_calib');
if ~isempty(hh)
    delete(hh)
end
hh=findobj(allchild(0),'tag','set_object');
if ~isempty(hh)
    hhh=findobj(hh,'tag','PLOT');
    set(hhh,'enable','off')
end


% --- Executes on button press in delete_object.
function delete_object_Callback(hObject, eventdata, handles)
IndexObj=get(handles.list_object_2,'Value');
    if IndexObj>1 
        delete_object(IndexObj)
    end
    

