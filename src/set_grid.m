%'set_grid':produce grid for PIV with one or two images (stereo case) 
%------------------------------------------------------------------------
% function varargout = set_grid(varargin)
% associated with the GUI set_grid.fig
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

function varargout = set_grid(varargin)

% Last Modified by GUIDE v2.5 04-Feb-2008 16:05:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @set_grid_OpeningFcn, ...
                   'gui_OutputFcn',  @set_grid_OutputFcn, ...
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

%-------------------------------------------------------------------
% --- Executes just before set_grid is made visible.
%INPUT: 
% handles: handles of the set_grid interface elements
%'IndexObj': index of the object (on the UvData list) that set_grid will modify
%        if =[] or absent: index still undefined (create mode in uvmat)
%        if=0; no associated object (used for series), the button 'PLOT' is  then unvisible
%'data': read from an existing object selected in the interface
%      .TITLE : class of object ('POINTS','LINE',....)
%      .DX,DY,DZ; meshes for regular grids
%      .Coord: object position coordinates
%      .ParentButton: handle of the uicontrol object calling the interface
% PlotHandles: set of handles of the elements contolling the plotting of the projected field:
%  if =[] or absent, no plot (mask mode in uvmat)
% parameters on the uvmat interface (obtained by 'get_plot_handle.m')
function set_grid_OpeningFcn(hObject, eventdata, handles,inputfile)

% Choose default command line output for set_grid
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%default
% set(hObject,'Unit','Normalized')% set the unit normalized to the screen size
% set(hObject,'Position',[0.7 0.1 0.25 0.5])%set the position of the set_grid interface 
set(hObject,'DeleteFcn',@closefcn)
set(handles.TITLE,'Value',1)
set(handles.ObjectStyle,'Value',1)
set(handles.ProjMode,'Value',1)
set(handles.MenuCoord,'ListboxTop',1)
set(handles.MenuCoord,'Value',1);
set(handles.MenuCoord,'String',{'phys';'px'});
if exist('inputfile','var')& ~isempty(inputfile)
   set(handles.image_1,'String',inputfile)
   set(handles.image_2,'String',inputfile)
end


% --- Outputs from this function are returned to the command line.
function varargout = set_grid_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;

% --- Executes on selection change in ObjectStyle.
function ObjectStyle_Callback(hObject, eventdata, handles)

ProjMode_Callback(hObject, eventdata, handles)

%----------------------------------------------
function xObject_Callback(hObject, eventdata, handles)


function yObject_Callback(hObject, eventdata, handles)


% --- Executes on selection change in zObject.
function zObject_Callback(hObject, eventdata, handles)


%---------------------------------------------------
% --- Executes on selection change in ProjMode.
function ProjMode_Callback(hObject, eventdata, handles)
menu=get(handles.ProjMode,'String');
value=get(handles.ProjMode,'Value');
ProjMode=menu{value};
menu=get(handles.ObjectStyle,'String');
value=get(handles.ObjectStyle,'Value');
ObjectStyle=menu{value};
test3D=isequal(get(handles.ZObject,'Visible'),'on');%3D case
if isequal(ObjectStyle,'plane')||isequal(ObjectStyle,'volume')
    set(handles.Phi,'Visible','on')
    if test3D%3D case
        set(handles.Theta,'Visible','on')
        set(handles.Psi,'Visible','on')
    end
    set(handles.XMin,'Visible','on')
    set(handles.XMax,'Visible','on')
    set(handles.YMin,'Visible','on')
    set(handles.YMax,'Visible','on')
    if test3D
        set(handles.Theta,'Visible','on')
        set(handles.Psi,'Visible','on')
        set(handles.ZMin,'Visible','on')
        set(handles.ZMax,'Visible','on')
    end
else
    set(handles.Phi,'Visible','off')
    set(handles.Theta,'Visible','off')
    set(handles.Psi,'Visible','off')
    set(handles.XMin,'Visible','off')
    set(handles.XMax,'Visible','off')
    set(handles.YMin,'Visible','off')
    if isequal(ProjMode,'interp')
        set(handles.YMax,'Visible','off')
    else
        set(handles.YMax,'Visible','on')
    end
    if isequal(ObjectStyle,'rectangle')|isequal(ObjectStyle,'ellipse')
        set(handles.XMax,'Visible','on')
    else
       set(handles.XMax,'Visible','off')
    end
    set(handles.ZMin,'Visible','off')
    set(handles.ZMax,'Visible','off')
end
if isequal(ProjMode,'projection')|isequal(ProjMode,'inside')|isequal(ProjMode,'outside')|isequal(ObjectStyle,'points')
    set(handles.DX,'Visible','off')
    set(handles.DY,'Visible','off')
    set(handles.DZ,'Visible','off')   
else
    set(handles.DX,'Visible','on')
    set(handles.DY,'Visible','on')
    if test3D%3D case
        set(handles.DZ,'Visible','on')
    end
end

%---------------------------------------------
% --- Executes on selection change in TITLE.
function TITLE_Callback(hObject, eventdata, handles)
hsetobject=get(handles.TITLE,'parent');
SetData=get(hsetobject,'UserData');%get the hidden interface data
%      function named CALLBACK in UNTITLED.M with the given input arguments.
menu=get(handles.TITLE,'String');
value=get(handles.TITLE,'Value');
titl=menu{value};
if isequal(titl,'POINTS')
     menu_style={'points'};
     menu_proj={'projection';'interp';'filter';'none'};
elseif isequal(titl,'LINE')
     menu_style={'line';'polyline';'rectangle';'polygon';'ellipse'};%'line' =default
     menu_proj={'projection';'interp';'filter';'none'};
elseif isequal(titl,'PATCH')
     menu_style={'rectangle';'polygon';'ellipse'};%'line' =default
     menu_proj={'inside';'outside';'none'};
 elseif isequal(titl,'PLANE')
     menu_style={'plane'};
     menu_proj={'projection';'interp'};
elseif isequal(titl,'VOLUME')
     menu_style={'volume'};
     menu_proj={'none'};
  
end
set(handles.ObjectStyle,'String',menu_style)
set(handles.ObjectStyle,'Value',1)
set(handles.ProjMode,'String',menu_proj)
set(handles.ProjMode,'Value',1)
if isfield(SetData,'ParentButton')
    update_parentbutton(SetData.ParentButton,titl)
end
ObjectStyle_Callback(hObject, eventdata, handles)  

%-----------
function update_parentbutton(ParentButton,titl)

if isstruct(ParentButton)
    parentfields=fields(ParentButton);
    for ibutton=1:length(parentfields)
        buttonhandle=eval(['ParentButton.' parentfields{ibutton}]);
        if ishandle(buttonhandle)
            set(buttonhandle,'Value',0)
            set(buttonhandle,'BackgroundColor',[0 1 0])%put unactivated buttons to green
        end
    end
    if isfield(ParentButton,titl)
       buttonhandle=eval(['ParentButton.' titl]);
       if ishandle(buttonhandle)
            set(buttonhandle,'Value',1)
            set(buttonhandle,'BackgroundColor',[1 1 0])%put activated button to yellow
       end
    end
end
%------------
function Phi_Callback(hObject, eventdata, handles)
update_slider(hObject, eventdata,handles)

function Theta_Callback(hObject, eventdata, handles)
update_slider(hObject, eventdata,handles)

function update_slider(hObject, eventdata,handles)
%rotation angles
Phi=(pi/180)*str2num(get(handles.Phi,'String'));%first Euler angle in radian
Theta=(pi/180)*str2num(get(handles.Theta,'String'));%second Euler angle in radian

%components of the unitiy vector normal to the projection plane
NormVec_X=-sin(Phi)*sin(Theta);
NormVec_Y=cos(Phi)*sin(Theta);
NormVec_Z=cos(Theta);
huvmat=findobj('Tag','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
Z=NormVec_X *(UvData.X)+NormVec_Y *(UvData.Y)+NormVec_Z *(UvData.Z);
set(handles.z_slider,'Min',min(Z))
set(handles.z_slider,'Max',max(Z))
ZMax_Callback(hObject, eventdata, handles)

function DX_Callback(hObject, eventdata, handles)


function DY_Callback(hObject, eventdata, handles)


function DZ_Callback(hObject, eventdata, handles)



%-----------------------------------------------------
% --- Executes on button press in import.
function import_Callback(hObject, eventdata, handles)
%get the object file 
oldfile='';
huvmat=findobj('Tag','uvmat');
if isempty(huvmat)
    huvmat=findobj(allchild(0),'Name','series');
end
hchild=get(huvmat,'Children');
hrootpath=findobj(hchild,'Tag','RootPath');
oldfile=get(hrootpath,'String');
if iscell(oldfile)
    oldfile=oldfile{1};
end
%[FileName,PathName] = uigetfile('*.civ','Select a .civ file',oldfile)
[FileName, PathName, filterindex] = uigetfile( ...
       {'*.xml;*.mat', ' (*.xml,*.mat)';
       '*.xml',  '.xml files '; ...
        '*.mat',  '.mat matlab files '}, ...
        'Pick a file',oldfile);
fileinput=[PathName FileName];%complete file name 
testblank=findstr(fileinput,' ');%look for blanks
if ~isempty(testblank)
    errordlg('forbidden input file name: contain blanks')
    return
end
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end

%read the file
 t=xmltree(fileinput);
 s=convert(t);
%Display title
title=set_title(s.Style,s.ProjMode);%update the title
% menu=get(handles.TITLE,'String')
% for iline=1:length(menu)
%      if isequal(menu{iline},title)
%          set(handles.TITLE,'Value',iline)
%          break
%      end
% end
% TITLE_Callback(hObject, eventdata, handles)
% teststyle=0;
% if isfield(s,'Style')
%         menu=get(handles.ObjectStyle,'String');
%         for iline=1:length(menu)
%             if isequal(menu{iline},s.Style)
%                 set(handles.ObjectStyle,'Value',iline)
%                 teststyle=1;
%                 break
%             end
%         end
% end
% if teststyle==0;
%        s.Style='points';
%        set(handles.ObjectStyle,'Value',1); %default (points)
% end
testmode=0;
if isfield(s,'ProjMode')
        menu=get(handles.ProjMode,'String');
        for iline=1:length(menu)
            if isequal(menu{iline},s.ProjMode)
                set(handles.ProjMode,'Value',iline)
                testmode=1;
                break
            end
        end
end

ProjMode_Callback(hObject, eventdata, handles);%visualize the appropriate edit boxes
if isfield(s,'CoordType')
    if isequal(s.CoordType,'phys')
        set(handles.MenuCoord,'Value',1)
    elseif isequal(s.CoordType,'px')
        set(handles.MenuCoord,'Value',2)
    else
        warndlg('unknown CoordType (px or phys) in set_grid.m')
    end
end
if isfield(s,'XMax')
    set(handles.XMax,'String',s.XMax)
end
if isfield(s,'XMin')
    set(handles.XMin,'String',s.XMin)
end
if isfield(s,'YMax')
    set(handles.YMax,'String',s.YMax)
end
if isfield(s,'YMin')
    set(handles.YMin,'String',s.YMin)
end
if isfield(s,'DX')
    set(handles.DX,'String',s.DX)
end
if isfield(s,'DY')
    set(handles.DY,'String',s.DY)
end
if ~isfield(s,'Coord')
    XObject='0';%default
    YObject='0';
elseif ischar(s.Coord)
    line=str2num(s.Coord);
    XObject=num2str(line(1));
    YObject=num2str(line(2));
else
    for i=1:length(s.Coord)
        line=str2num(s.Coord{i});
        XObject{i}=num2str(line(1));
        YObject{i}=num2str(line(2));
    end
end
set(handles.XObject,'String',XObject)
set(handles.YObject,'String',YObject)
%METTRA A JOUR ASPECT DE L'INTERFACE (COMME set_grid_Opening

%----------------------------------------------------
% executed when closing: set the parent interface button to value 0
function closefcn(gcbo,eventdata)
huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
parent_button=findobj(huvmat,'Tag','grid');
if ~isempty(parent_button)
    set(parent_button,'Value',0)%put unactivated buttons to green
    tag=get(parent_button,'Tag');
    if isequal(tag,'edit')
        set(parent_button,'BackgroundColor',[0.7 0.7 0.7]);
    else 
        set(parent_button,'BackgroundColor',[0 1 0]);
    end
end

%-----------------------------------------------------------------------
% --- Executes on button press in edit: PLOT the defined object and its projected field
function edit_Callback(hObject, eventdata, handles)
hsetobject=get(hObject,'parent');
SetData=get(hsetobject,'UserData');%get the hidden interface data
%IndexObj=SetData.IndexObj%index of the current projection object in the list of projection objects (UvData.ProjObject)
huvmat=findobj('Tag','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
if isfield(UvData,'CuurentObjectIndex')
    IndexObj=UvData.CurrentObjectIndex;
else
    IndexObj=[];
end
ObjectData=read_set_grid(handles);%read the interface input parameters defining the object
[UvData,IndexObj]=update_obj(UvData,IndexObj,ObjectData,SetData.PlotHandles);
uvmat('write_plot_param',PlotHandles,UvData.Object{IndexObj}.PlotParam); %update the display of plotting parameters for the current object
SetData.IndexObj=IndexObj;
set(gcbf,'UserData',SetData)%update object index in the set_grid interface
set(huvmat,'UserData',UvData)%update the data in the uvmat interface


% --- Executes on button press in MenuCoord.
function MenuCoord_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in delete.
function delete_Callback(hObject, eventdata, handles)

%SetData=get(gcbf,'UserData');%get the interface data
%IndexObj=SetData.IndexObj;
huvmat=findobj('Name','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
if isfield(UvData,'CurrentObjectIndex')
    IndexObj=UvData.CurrentObjectIndex;
else
    IndexObj=[];
end
delete_object(IndexObj);

%----------------------------------------------------
function YMin_Callback(hObject, eventdata, handles)
% hObject    handle to YMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YMin as text
%        str2double(get(hObject,'String')) returns contents of YMin as a double


function ZMin_Callback(hObject, eventdata, handles)


function ZMax_Callback(hObject, eventdata, handles)
DZ=str2num(get(handles.ZMax,'String'));
ZMin=get(handles.z_slider,'Min');
ZMax=get(handles.z_slider,'Max');
rel_step(1)=DZ/(ZMax-ZMin);
rel_step(2)=0.2;
set(handles.z_slider,'SliderStep',rel_step)

function YMax_Callback(hObject, eventdata, handles)


function XMin_Callback(hObject, eventdata, handles)


function XMax_Callback(hObject, eventdata, handles)


% ------------------------------------------------------
function save_Callback(hObject, eventdata, handles)
% ------------------------------------------------------
Object=read_set_object(handles);%read the set_grid interface;
DX=Object.DX;
DY=Object.DY;
RangeX=Object.RangeX;
RangeY=Object.RangeY;
 array_realx=[RangeX(2):DX:RangeX(1)];
 array_realy=[RangeY(2):DY:RangeY(1)];
 nx_patch=length(array_realx);
 ny_patch=length(array_realy);
 [grid_realx,grid_realy]=meshgrid(array_realx,array_realy);
 grid_real(:,1)=reshape(grid_realx,nx_patch*ny_patch,1);
 grid_real(:,2)=reshape(grid_realy,nx_patch*ny_patch,1);
 grid_real(:,3)=zeros(nx_patch*ny_patch,1);
 
imageA=get(handles.image_1,'String');
imageB=get(handles.image_2,'String');
testB=1;
if isempty(imageA) | isequal(imageA,'')
    if isempty(imageB) | isequal(imageB,'')
        msgbox_uvmat('ERROR','at least one image file name must be introduced')
    else
        imageA=imageB;
        testB=0;
    end
end
if isempty(imageB) || isequal(imageB,'') || isequal(imageA,imageB)
    testB=0;
end

testexist=exist(imageA,'file');
if isequal(testexist,0)
    msgbox_uvmat('ERROR',['input image file' imageA 'does not exist'])
    return
end
[Pathsub,RootFile,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(imageA);
form=imformats(ext([2:end]));
if isempty(form)% if the extension corresponds to an image format recognized by Matlab
     msgbox_uvmat('ERROR',['error in read_image.m: ' imageA ' is not an image name recognized by Matlab '])
     return
end
fileAxml=[fullfile(Pathsub,RootFile) '.xml'];
[XmlDataA,error]=imadoc2struct(fileAxml); 
if isfield(XmlDataA,'GeometryCalib')
     tsaiA=XmlDataA.GeometryCalib;
 else
     msgbox_uvmat('WARNING','no geometric calibration available for image A')
     tsaiA=[];
end
[grid_imaA(:,1),grid_imaA(:,2)]=px_XYZ(tsaiA,grid_real(:,1),grid_real(:,2),0);
    A=imread(imageA);
   siz=size(A);
   npxA=siz(2);
   npyA=siz(1);

flagA=grid_imaA(:,1)>0 & grid_imaA(:,1)<npxA & grid_imaA(:,2)>0 & grid_imaA(:,2)<npyA; 

if testB
    testexist=exist(imageB,'file');
    if isequal(testexist,0)
        msgbox_uvmat('ERROR',['input image file' imageB 'does not exist'])
        return
    end
    [Pathsub,RootFile,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(imageB);
    form=imformats(ext([2:end]));
    if isempty(form)% if the extension corresponds to an image format recognized by Matlab
         msgbox_uvmat('ERROR',['error in read_image.m: ' imageB ' is not an image name recognized by Matlab '])
         return
    end
    fileBxml=[fullfile(Pathsub,RootFile) '.xml'];
    [XmlDataB,error]=imadoc2struct(fileBxml); 
    if isfield(XmlDataB,'GeometryCalib')
     tsaiB=XmlDataB.GeometryCalib;
    else
     msgbox_uvmat('WARNING','no geometric calibration available for image B')
     tsaiB=[];
 end
    %[error,Heading,nom_type_read,ext_ima_read,time,TimeUnit,mode,NbSlice,...
    %     npxB,npyB,tsaiB]=read_imadoc(fileBxml,0);
    [grid_imaB(:,1),grid_imaB(:,2)]=px_XYZ(tsaiB,grid_real(:,1),grid_real(:,2),0);
%     if isempty(npxB)|isempty(npyB)
        B=imread(imageB);
       siz=size(B);
       npxB=siz(2);
       npyB=siz(1);
%     end
    flagB=grid_imaB(:,1)>0 & grid_imaB(:,1)<npxB & grid_imaB(:,2)>0 & grid_imaB(:,2)<npyB; 
end
if testB
    ind_good=find(flagA==1&flagB==1);
    XimaB=grid_imaB(ind_good,1);
    YimaB=grid_imaB(ind_good,2);
else
    ind_good=find(flagA==1);
end
XimaA=grid_imaA(ind_good,1);
YimaA=grid_imaA(ind_good,2);

grid_real_x=grid_real(ind_good,1);
grid_real_y=grid_real(ind_good,2);
nx_patch_new=length(grid_real_x); 
grid_real2(:,1)=grid_real_x;
grid_real2(:,2)=grid_real_y;
grid_real2(:,3)=zeros(nx_patch_new,1);
[grid_pix_A(:,1),grid_pix_A(:,2)]=px_XYZ(tsaiA,grid_real2(:,1),grid_real2(:,2));
if testB
    [grid_pix_B(:,1),grid_pix_B(:,2)]=px_XYZ(tsaiB,grid_real2(:,1),grid_real2(:,2));
end

 %ECRIRE FICHIERS
nbpointsA=size(grid_pix_A);
XA=grid_pix_A(:,1);
YA=grid_pix_A(:,2);
unitcolumn=32*ones(size(XA));
Xchar=num2str(XA);
blanc=char(unitcolumn);
Ychar=num2str(YA);
tete=['1 ' num2str(nbpointsA(1))];
txt=[Xchar blanc Ychar];
textgrid={tete;txt};
textout=char(textgrid);
Answer = msgbox_uvmat('INPUT_TXT','grid file name (*.grid)',fullfile(Pathsub,'gridA.grid'));
% Answer = inputdlg('grid file name (*.grid)',' ',1,{fullfile(Pathsub,'gridA.grid')},'on');
dlmwrite(Answer,textout,'');
msgbox_uvmat('CONFIRMATION',[Answer ' written as ASCII text file']);
if testB
    nbpointsB=size(grid_pix_B);
    XB=grid_pix_B(:,1);
    YB=grid_pix_B(:,2);
    unitcolumn=32*ones(size(XB));
    Xchar=num2str(XB);
    blanc=char(unitcolumn);
    Ychar=num2str(YB);
    tete=['1 ' num2str(nbpointsB(1))];
    txt=[Xchar blanc Ychar];
    textgrid={tete;txt};
    textout=char(textgrid);
    Answer = msgbox_uvmat('INPUT_TXT','grid file name (*.grid)',fullfile(Pathsub,'gridB.grid'));
    dlmwrite(Answer,textout,'');
    msgbox_uvmat('CONFIRMATION',[Answer ' written as ASCII text file']);
end


%------------------------------------------------
function TITLE=set_title(Style,ProjMode)
%------------------------------------------------
if isequal(Style,'points')
    TITLE='POINTS';
elseif isequal(Style,'line')|isequal(Style,'polyline')
    TITLE='LINE';
elseif isequal(Style,'plane')
    TITLE='PLANE';
elseif isequal(Style,'volume')
    TITLE='VOLUME';
elseif isequal(Style,'polygon')|isequal(Style,'rectangle')|isequal(Style,'ellipse')
    if isequal(ProjMode,'inside')|isequal(ProjMode,'outside')
        TITLE='PATCH';
    else
        TITLE='LINE';
    end
end


% --- Executes on slider movement.
function z_slider_Callback(hObject, eventdata, handles)
%A ADAPTER
Z_value=get(handles.z_slider,'Value');

%rotation angles
Phi=(pi/180)*str2num(get(handles.Phi,'String'));%first Euler angle in radian
Theta=(pi/180)*str2num(get(handles.Theta,'String'));%second Euler angle in radian

%components of the unity vector normal to the projection plane
NormVec_X=-sin(Phi)*sin(Theta);
NormVec_Y=cos(Phi)*sin(Theta);
NormVec_Z=cos(Theta);

%set new plane position and update graph
set(handles.XObject,'String',num2str(NormVec_X*Z_value))
set(handles.YObject,'String',num2str(NormVec_Y*Z_value))
set(handles.ZObject,'String',num2str(NormVec_Z*Z_value))
edit_Callback(hObject, eventdata, handles)



function XObject_Callback(hObject, eventdata, handles)


function YObject_Callback(hObject, eventdata, handles)




function ZObject_Callback(hObject, eventdata, handles)


function image_2_Callback(hObject, eventdata, handles)
% hObject    handle to image_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of image_2 as text
%        str2double(get(hObject,'String')) returns contents of image_2 as a double



function image_1_Callback(hObject, eventdata, handles)
% hObject    handle to image_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of image_1 as text
%        str2double(get(hObject,'String')) returns contents of image_1 as a double


% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), errordlg('Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
web([helpfile '#set_grid'])    
end

