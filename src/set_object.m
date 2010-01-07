%'set_object': GUI to edit a projection object
%------------------------------------------------------------------------
% function hset_object= set_object(data, PlotHandles,ZBounds)
% associated with the GUI set_object.fig
%
% OUTPUT:
% hset_object: handle of the GUI figure
% 
% INTPUT:
% data: structure describing the object properties
%  PlotHandles: handles for projection plots
% Zbounds: bounds on Z ( 3D case)
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

function varargout = set_object(varargin)

% Last Modified by GUIDE v2.5 24-Nov-2008 14:29:06

% Begin initialization code - DO NOT PLOT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @set_object_OpeningFcn, ...
                   'gui_OutputFcn',  @set_object_OutputFcn, ...
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
% End initialization code - DO NOT PLOT

%-------------------------------------------------------------------
% --- Executes just before set_object is made visible.
%INPUT: 
% handles: handles of the set_object interface elements
%'IndexObj': NON USED ANYMORE (To suppress) index of the object (on the UvData list) that set_object will modify
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
function set_object_OpeningFcn(hObject, eventdata, handles, data, PlotHandles,ZBounds)

% Choose default command line output for set_object
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%default
if ~exist('ZBound','var')
    ZBound=0; %default 
end
set(hObject,'KeyPressFcn',{'keyboard_callback',handles})%set keyboard action function (allow action on uvmat when set_object is in front)
set(handles.MenuCoord,'ListboxTop',1)
if ~exist('PlotHandles','var')
     PlotHandles=[];
end
desable_open=0;%default: allow reading of object from xml file
desable_plot=0;%default
SetData.PlotHandles=PlotHandles;
if exist('data','var') & isfield(data,'ParentButton')
        SetData.ParentButton=data.ParentButton;
        set(hObject,'DeleteFcn',{@closefcn,SetData.ParentButton})%
end
set(hObject,'UserData',SetData)

% fill the interface as set in the input data:
if exist('data','var') 
    if isfield(data,'desable_open')
        desable_open=data.desable_open;%test to desable button OPEN (edit or display mode)
    end
    if isfield(data,'desable_plot')
        desable_plot=data.desable_plot;%test to desable button PLOT (display mode)
    end
    if ~isfield(data,'NbDim')|~isequal(data.NbDim,3)%2D case
        set(handles.ZObject,'Visible','off')
        set(handles.z_slider,'Visible','off')
    else
        set(handles.ZObject,'Visible','on')
        set(handles.z_slider,'Visible','on')
        if isfield(data,'Coord') && size(data.Coord,2)==3
            set(handles.ZObject,'String',num2str(data.Coord(1,3),4))
        end
    end
    if isfield(data,'ProjMode') && isfield(data,'Style')
        data.TITLE=set_title(data.Style,data.ProjMode);% define TITLE in set_object (POINTS, LINE, PATCH,...)
    end
    if isfield(data,'TITLE')
        menutitle=get(handles.TITLE,'String');
        for iline=1:length(menutitle)
            strmenu=menutitle{iline};
            if isequal(data.TITLE,strmenu)
                set(handles.TITLE,'Value',iline)
                break
            end
        end
        TITLE_Callback(hObject, eventdata, handles)% enable edit boxes depending on TITLE
    end
    if isfield(data,'fixedtitle')&isequal(data.fixedtitle,1)
        set(handles.TITLE,'enable','off')
    end
    if isfield(data,'Style')
        menu=get(handles.ObjectStyle,'String');
        for iline=1:length(menu)
            if isequal(menu{iline},data.Style)
                set(handles.ObjectStyle,'Value',iline)
                break
            end
        end
    end
    if isfield(data,'ProjMode')
        menu=get(handles.ProjMode,'String');
        for iline=1:length(menu)
            if isequal(menu{iline},data.ProjMode)
                set(handles.ProjMode,'Value',iline)
                break
            end
        end
    end
    if isfield(data,'Coord') & size(data.Coord,2)>=2
        sizcoord=size(data.Coord);
        for i=1:sizcoord(1)
            XObject{i}=num2str(data.Coord(i,1),4);
            YObject{i}=num2str(data.Coord(i,2),4);
        end
        set(handles.XObject,'String',XObject)
        set(handles.YObject,'String',YObject)
        %set(handles.XObject,'String',mat2cell(data.Coord(:,1),sizcoord(1)))
        %set(handles.YObject,'String',mat2cell(data.Coord(:,2),sizcoord(1)))
        if sizcoord(2)>3
            for i=1:sizcoord(1)
                ZObject{i}=num2str(data.Coord(i,3),4);
            end
            set(handles.ZObject,'String',ZObject)
        end
    end
    if isfield(data,'DX')
        set(handles.DX,'String',num2str(data.DX,3))
    end
    if isfield(data,'DY')
         set(handles.DY,'String',num2str(data.DY,3))
    end
    %OBSOLETE (replaced by Range)
%     if isfield(data,'XMin')
%          set(handles.XMin,'String',num2str(data.XMin,3))
%     end
%     if isfield(data,'XMax')
%          set(handles.XMax,'String',num2str(data.XMax,3))
%     end
%     if isfield(data,'YMin')
%          set(handles.YMin,'String',num2str(data.YMin,3))
%     end
%     if isfield(data,'YMax')
%          set(handles.YMax,'String',num2str(data.YMax,3))
%     end
    if isfield(data,'RangeZ') && length(ZBounds) >= 2
        set(handles.ZMax,'String',num2str(max(data.RangeZ),3))
        DZ=max(data.RangeZ);%slider step
        if ZBounds(2)~=ZBounds(1)
            rel_step(1)=min(DZ/(ZBounds(2)-ZBounds(1)),0.2);%must be smaller than 1
            rel_step(2)=0.1;
            set(handles.z_slider,'Visible','on')
            set(handles.z_slider,'Min',ZBounds(1))
            set(handles.z_slider,'Max',ZBounds(2))
            set(handles.z_slider,'SliderStep',rel_step)
            set(handles.z_slider,'Value',(ZBounds(1)+ZBounds(2))/2)
        end
    end
    if isfield(data,'RangeX')
            set(handles.XMax,'String',num2str(max(data.RangeX),3))
            set(handles.XMin,'String',num2str(min(data.RangeX),3))
    end
    if isfield(data,'RangeY')
            set(handles.YMax,'String',num2str(max(data.RangeY),3))
            set(handles.YMin,'String',num2str(min(data.RangeY),3))
    end
    if isfield(data,'RangeZ')
            set(handles.ZMax,'String',num2str(max(data.RangeZ),3))
            set(handles.ZMin,'String',num2str(min(data.RangeZ),3))
    end  
    if isfield(data,'Phi')
         set(handles.Phi,'String',num2str(data.Phi,3))
    end
    if isfield(data,'Theta')
         set(handles.Theta,'String',num2str(data.Theta,3))
    end
    if isfield(data,'Psi')
         set(handles.Psi,'String',num2str(data.Psi,3))
    end  
    if isfield(data,'DZ')
        set(handles.DZ,'String',num2str(data.DZ,3))
    end
    if isfield(data,'CoordType')
        if isequal(data.CoordType,'phys')
            set(handles.MenuCoord,'Value',1)
        elseif isequal(data.CoordType,'px')
             set(handles.MenuCoord,'Value',2)
        end
    end
end
if desable_open
    set(handles.OPEN,'Visible','off')
else
    set(handles.OPEN,'Visible','on')
end
if desable_plot
   set(handles.PLOT,'Visible','off')
else
   set(handles.PLOT,'Visible','on') 
end


% --- Outputs from this function are returned to the command line.
function varargout = set_object_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;

%-----------------------------------------------
% --- Executes on selection change in ObjectStyle.
function ObjectStyle_Callback(hObject, eventdata, handles)
style_prev=get(handles.ObjectStyle,'UserData');
str=get(handles.ObjectStyle,'String');
val=get(handles.ObjectStyle,'Value');
% make correspondance between different object styles
% if ~isequal(str{val},style_prev)
Xcolumn=get(handles.XObject,'String');
Ycolumn=get(handles.YObject,'String');
if ischar(Xcolumn)
    sizchar=size(Xcolumn);
    for icol=1:sizchar(1)
        Xcolumn_cell{icol}=Xcolumn(icol,:);
    end
    Xcolumn=Xcolumn_cell;
end
if ischar(Ycolumn)
    sizchar=size(Ycolumn);
    for icol=1:sizchar(1)
        Ycolumn_cell{icol}=Ycolumn(icol,:);
    end
    Ycolumn=Ycolumn_cell;
end
Zcolumn={};%default
z_new={};
if isequal(get(handles.ZObject,'Visible'),'on')
    data.NbDim=3; %test 3D object
    Zcolumn=get(handles.ZObject,'String');
    if ischar(Zcolumn)
        Zcolumn={Zcolumn};
    end
end
x_new{1}=Xcolumn{1};
y_new{1}=Ycolumn{1};
if ~isempty(Zcolumn)
    z_new{1}=Zcolumn{1};
end
if isequal(str{val},'line')
    if isequal(style_prev,'rectangle')|isequal(style_prev,'ellipse')
        XMax=get(handles.XMax,'String');
        YMax=get(handles.YMax,'String');
        x_new{2}=num2str(XMax,4);
        y_new{2}=num2str(YMax,4);
        set(handles.XObject,'String',x_new)
        set(handles.YObject,'String',y_new)
        set(handles.ZObject,'String',z_new)
    end
elseif isequal(str{val},'polyline')
elseif isequal(str{val},'rectangle')| isequal(str{val},'ellipse')
     set(handles.XObject,'String',x_new)
     set(handles.YObject,'String',y_new)
     set(handles.ZObject,'String',z_new)
end
% end
            
            

ProjMode_Callback(hObject, eventdata, handles)
%store the current option
str=get(handles.ObjectStyle,'String');
val=get(handles.ObjectStyle,'Value');
set(handles.ObjectStyle,'UserData',str{val})

%----------------------------------------------
function xObject_Callback(hObject, eventdata, handles)


function yObject_Callback(hObject, eventdata, handles)


% --- Executes on selection change in zObject.
function zObject_Callback(hObject, eventdata, handles)



% --- Executes on selection change in ProjMode.
function ProjMode_Callback(hObject, eventdata, handles)
menu=get(handles.ProjMode,'String');
value=get(handles.ProjMode,'Value');
ProjMode=menu{value};
menu=get(handles.ObjectStyle,'String');
value=get(handles.ObjectStyle,'Value');
ObjectStyle=menu{value};
test3D=isequal(get(handles.ZObject,'Visible'),'on');%3D case
if isequal(ObjectStyle,'plane')|isequal(ObjectStyle,'volume')
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
TITLE_list=get(handles.TITLE,'String');
val=get(handles.TITLE,'Value');
TITLE=TITLE_list{val};
switch TITLE
    case {'POINTS','PATCH','MASK'}
        set(handles.DX,'Visible','off')
        set(handles.DY,'Visible','off')
        set(handles.DZ,'Visible','off')
    case {'LINE'}
        if isequal(ProjMode,'interp')|| isequal(ProjMode,'filter')
            set(handles.DX,'Visible','on')
        else
            set(handles.DX,'Visible','off')
        end
    case {'PLANE'}  
        if isequal(ProjMode,'interp')|| isequal(ProjMode,'filter')
            set(handles.DX,'Visible','on')
            set(handles.DY,'Visible','on')
        else
            set(handles.DX,'Visible','off')
            set(handles.DY,'Visible','off')
        end
    case {'VOLUME'} 
        if isequal(ProjMode,'interp')
            set(handles.DX,'Visible','on')
            set(handles.DY,'Visible','on')
            set(handles.DZ,'Visible','on')
        else
            set(handles.DX,'Visible','off')
            set(handles.DY,'Visible','off')
            set(handles.DZ,'Visible','off')   
        end
end

%---------------------------------------------
% --- Executes on selection change in TITLE.
function TITLE_Callback(hObject, eventdata, handles)
%---------------------------------------------
hsetobject=get(handles.TITLE,'parent');
SetData=get(hsetobject,'UserData');%get the hidden interface data
%      function named CALLBACK in UNTITLED.M with the given input arguments.
menu=get(handles.TITLE,'String');
value=get(handles.TITLE,'Value');
titl=menu{value};
if isequal(titl,'POINTS');
     menu_style={'points'};
     menu_proj={'projection';'interp';'filter';'none'};
elseif isequal(titl,'LINE')
     menu_style={'line';'polyline';'rectangle';'polygon';'ellipse'};%'line' =default
     menu_proj={'projection';'interp';'filter';'none'};
elseif isequal(titl,'PATCH')
     menu_style={'rectangle';'polygon';'ellipse'};%'line' =default
     menu_proj={'inside';'outside'};
elseif isequal(titl,'MASK')
     menu_style={'polygon'};%'line' =default
     menu_proj={'mask_inside';'mask_outside'};
elseif isequal(titl,'PLANE')
     menu_style={'plane'};
     menu_proj={'projection';'interp';'filter';'none'};
elseif isequal(titl,'VOLUME')
     menu_style={'volume'};
     menu_proj={'none'};
  
end
old_menu=get(handles.ObjectStyle,'String');
value=get(handles.ObjectStyle,'Value');
old_style=old_menu{value};
teststyle=0;
for iline=1:length(menu_style)
    if isequal(menu_style{iline},old_style)
        styleval=iline;
        teststyle=1;
        break
    end
end
if ~teststyle
    new_style=[];%default
    switch old_style
        case 'polyline'
            new_style='polygon';
        case 'polygon'
            new_style='polyline';
    end
    if ~isempty(new_style)
        for iline=1:length(menu_style)
            if isequal(menu_style{iline},new_style)
                styleval=iline;
                teststyle=1;
                break
            end
        end
    end
end
if ~teststyle
    styleval=1;
end
set(handles.ObjectStyle,'String',menu_style)
set(handles.ObjectStyle,'Value',styleval)
set(handles.ProjMode,'String',menu_proj)
set(handles.ProjMode,'Value',1)
ObjectStyle_Callback(hObject, eventdata, handles)  

%---------------------------------------------
function Phi_Callback(hObject, eventdata, handles)
update_slider(hObject, eventdata,handles)
%---------------------------------------------

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
if isfield(UvData,'X') & isfield(UvData,'Y') & isfield(UvData,'Z')
    Z=NormVec_X *(UvData.X)+NormVec_Y *(UvData.Y)+NormVec_Z *(UvData.Z);
    set(handles.z_slider,'Min',min(Z))
    set(handles.z_slider,'Max',max(Z))
    ZMax_Callback(hObject, eventdata, handles)
end

function DX_Callback(hObject, eventdata, handles)


function DY_Callback(hObject, eventdata, handles)


function DZ_Callback(hObject, eventdata, handles)



%-----------------------------------------------------
% --- Executes on button press in OPEN.
function OPEN_Callback(hObject, eventdata, handles)
%get the object file 
oldfile=' ';
huvmat=findobj('Tag','uvmat');
% if isempty(huvmat)
%     huvmat=findobj(allchild(0),'Name','series');
% end
hchild=get(huvmat,'Children');
hrootpath=findobj(hchild,'Tag','RootPath');
if ~isempty(hrootpath)
    oldfile=get(hrootpath,'String');
    if iscell(oldfile)
        oldfile=oldfile{1};
    end
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
 if ~isfield(s,'Style')
     s.Style='points';
 end
 if ~isfield(s,'ProjMode')
     s.ProjMode='none';
 end
%Display title
title=set_title(s.Style,s.ProjMode);%update the title
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
%     set(hhuvmat.POINTS,'Value',0)
%     set(hhuvmat.POINTS,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.LINE,'Value',0)
%     set(hhuvmat.LINE,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.PATCH,'Value',0)
%     set(hhuvmat.PATCH,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.PLANE,'Value',0)
%     set(hhuvmat.PLANE,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.VOLUME,'Value',0)
%     set(hhuvmat.VOLUME,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     if ~isequal(title,'MASK')
%         eval(['set(hhuvmat.' title ',''Value'',1)'])
%         eval(['set(hhuvmat.' title ',''BackgroundColor'',[1 1 0])'])
%     end
end
menu=get(handles.TITLE,'String');
for iline=1:length(menu)
     if isequal(menu{iline},title)
         set(handles.TITLE,'Value',iline)
         break
     end
end
TITLE_Callback(hObject, eventdata, handles)
teststyle=0;
% if isfield(s,'Style')
menu=get(handles.ObjectStyle,'String');
for iline=1:length(menu)
    if isequal(menu{iline},s.Style)
        set(handles.ObjectStyle,'Value',iline)
        teststyle=1;
        break
    end
end
testmode=0;
menu=get(handles.ProjMode,'String');
for iline=1:length(menu)
    if isequal(menu{iline},s.ProjMode)
        set(handles.ProjMode,'Value',iline)
        testmode=1;
        break
    end
end

ProjMode_Callback(hObject, eventdata, handles);%visualize the appropriate edit boxes
if isfield(s,'CoordType')
    if isequal(s.CoordType,'phys')
        set(handles.MenuCoord,'Value',1)
    elseif isequal(s.CoordType,'px')
        set(handles.MenuCoord,'Value',2)
    else
        warndlg('unknown CoordType (px or phys) in set_object.m')
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
Range=0;
if isfield(s,'Range')
    if ischar(s.Range)
        Range=str2num(s.Range);
    else
        Range(1,:)=str2num(s.Range{1});
        Range(2,:)=str2num(s.Range{2});
    end
end
if size(Range,2)>=3
    if size(Range,1)>=2
       set(handles.ZMin,'String',num2str(Range(2,3),3))
    end
    if size(Range,1)>=2
       set(handles.ZMax,'String',num2str(Range(1,3),3))
    end
end
if size(Range,2)>=2
    if size(Range,1)>=2
       set(handles.YMin,'String',num2str(Range(2,2),3))
    end
    if size(Range,1)>=2
       set(handles.YMax,'String',num2str(Range(1,2),3))
    end
end
if size(Range,2)>=1
    if size(Range,1)>=2
       set(handles.XMin,'String',num2str(Range(2,1),3))
    end
    if size(Range,1)>=2
       set(handles.XMax,'String',num2str(Range(1,1),3))
    end
end
if isfield(s,'RangeX') & ischar(s.RangeX)
     RangeX=str2num(s.RangeX);
    set(handles.XMax,'String',num2str(max(RangeX),3))
    set(handles.XMin,'String',num2str(min(RangeX),3))
end

if isfield(s,'RangeY')
    if ischar(s.RangeY)
        RangeY=str2num(s.RangeY);
        set(handles.YMax,'String',num2str(max(RangeY),3))
        set(handles.YMin,'String',num2str(min(RangeY),3))
    end
end
if isfield(s,'RangeZ')
    if ischar(s.RangeZ)
        RangeZ=str2num(s.RangeZ);
        set(handles.ZMax,'String',num2str(max(RangeZ),3))
        set(handles.ZMin,'String',num2str(min(RangeZ),3))
    end
end
if isfield(s,'Phi')
    set(handles.Phi,'String',s.Phi)
end
if isfield(s,'Theta')
    set(handles.Theta,'String',s.Theta)
end
if isfield(s,'Psi')
    set(handles.Psi,'String',s.Psi)
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
    XObject=num2str(line(1),4);
    YObject=num2str(line(2),4);
else
    for i=1:length(s.Coord)
        line=str2num(s.Coord{i});
        XObject{i}=num2str(line(1),4);
        YObject{i}=num2str(line(2),4);
    end
end
set(handles.XObject,'String',XObject)
set(handles.YObject,'String',YObject)
%METTRA A JOUR ASPECT DE L'INTERFACE (COMME set_object_Opening

%----------------------------------------------------
% executed when closing: set the parent interface button to value 0
function closefcn(gcbo,eventdata,parent_button)

huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
    set(hhuvmat.create,'Value',0)
    set(hhuvmat.create,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.LINE,'Value',0)
%     set(hhuvmat.LINE,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.PATCH,'Value',0)
%     set(hhuvmat.PATCH,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.PLANE,'Value',0)
%     set(hhuvmat.PLANE,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.VOLUME,'Value',0)
%     set(hhuvmat.VOLUME,'BackgroundColor',[0 1 0])%put unactivated buttons to green
    set(hhuvmat.edit,'Value',0)
    set(hhuvmat.edit,'BackgroundColor',[0.7 0.7 0.7])%put unactivated buttons to gree
end
hseries=findobj(allchild(0),'Name','series');%find the current series interface handle
if ~isempty(hseries)
    hhseries=guidata(hseries);
    set(hhseries.GetObject,'Value',0)
    set(hhseries.GetObject,'BackgroundColor',[0 1 0])%put unactivated buttons to green
end

%-----------------------------------------------------------------------
% --- Executes on button press in PLOT: PLOT the defined object and its projected field
function PLOT_Callback(hObject, eventdata, handles)

hsetobject=get(handles.PLOT,'parent');
SetData=get(hsetobject,'UserData');%get the hidden interface data
huvmat=findobj('Name','uvmat');%find the current uvmat interface handle
hlist_object=findobj(huvmat,'Tag','list_object');%handles of the object list in the GUI uvmat 
IndexObj=get(hlist_object,'Value');%position in the objet list
UvData=get(huvmat,'UserData');%Data associated to the GUI uvmat 
ObjectData=read_set_object(handles);%read the input parameters defining the object in the GUI set_object
ObjectData.HandlesDisplay=[]; % new object plot by default
if length(UvData.Object) >= IndexObj && isfield(UvData.Object{IndexObj},'HandlesDisplay')
    hdisplay=UvData.Object{IndexObj}.HandlesDisplay;
    if isequal(UvData.Object{IndexObj}.Style, ObjectData.Style) && isequal(UvData.Object{IndexObj}.ProjMode, ObjectData.ProjMode)
        ObjectData.HandlesDisplay=UvData.Object{IndexObj}.HandlesDisplay;
    else  % for a new object styl, delete the existing object plots 
        for ih=1:length(hdisplay)
            PlotData=get(hdisplay(ih),'UserData');
            if isfield(PlotData,'SubObject') & ishandle(PlotData.SubObject)
                    delete(PlotData.SubObject);
            end
            if isfield(PlotData,'DeformPoint') & ishandle(PlotData.DeformPoint)
                   delete(PlotData.DeformPoint);
            end
            if ~isequal(hdisplay(ih),0)
                delete(hdisplay(ih));
            end
        end
        if isfield(ObjectData,'plotaxes') && ishandle(ObjectData.plotaxes)
            delete(ObjectData.plotaxes)%delete the axes for plotting the current projection result
        end
    end      
end

% update the object plot and projection field
UvData.Object{IndexObj}=update_obj(UvData,IndexObj,ObjectData,SetData.PlotHandles);

set(huvmat,'UserData',UvData)%update the data in the uvmat interface
list_str=get(hlist_object,'String');
TITLE=set_title(ObjectData.Style,ObjectData.ProjMode);
list_str{IndexObj}=[num2str(IndexObj) '-' TITLE];
if isequal(length(list_str),IndexObj)
    list_str{IndexObj+1}='more...';
end
set(hlist_object,'String',list_str)
set(hlist_object,'Value',IndexObj)

%update create buttons on the GUI uvmat: set to object edit mode after object plotting
hhuvmat=guidata(huvmat);%handles of elements in the uvmat GUI
%desactivate all create buttons in mode edit
% if isequal(get(hhuvmat.edit,'Value'),0)
    set(hhuvmat.create,'Value',0)
    set(hhuvmat.create,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.LINE,'Value',0)
%     set(hhuvmat.LINE,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.PATCH,'Value',0)
%     set(hhuvmat.PATCH,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.PLANE,'Value',0)
%     set(hhuvmat.PLANE,'BackgroundColor',[0 1 0])%put unactivated buttons to green
%     set(hhuvmat.VOLUME,'Value',0)
%     set(hhuvmat.VOLUME,'BackgroundColor',[0 1 0])%put unactivated buttons to green
% end
set(hhuvmat.edit,'Value',1)
set(hhuvmat.edit,'BackgroundColor',[1 1 0]);% paint the edit text in yellow
set(hhuvmat.edit,'Value',1);%
UvData.MouseAction='edit_object'; % set the edit button to 'on'
set(huvmat,'UserData',UvData)

% --- Executes on button press in MenuCoord.
function MenuCoord_Callback(hObject, eventdata, handles)

%----------------------------------------------------
function YMin_Callback(hObject, eventdata, handles)


function ZMin_Callback(hObject, eventdata, handles)


function ZMax_Callback(hObject, eventdata, handles)
DZ=str2num(get(handles.ZMax,'String'));
ZMin=get(handles.z_slider,'Min');
ZMax=get(handles.z_slider,'Max');
if ~isequal(ZMax-ZMin,0)
    rel_step(1)=DZ/(ZMax-ZMin);
    rel_step(2)=0.2;
    set(handles.z_slider,'SliderStep',rel_step)
end

function YMax_Callback(hObject, eventdata, handles)


function XMin_Callback(hObject, eventdata, handles)


function XMax_Callback(hObject, eventdata, handles)


% ------------------------------------------------------
function SAVE_Callback(hObject, eventdata, handles)
% ------------------------------------------------------
Object=read_set_object(handles);
huvmat=findobj('Tag','uvmat');
% UvData=get(huvmat,'UserData');
if isempty(huvmat)
    huvmat=findobj(allchild(0),'Name','series');
end
hchild=get(huvmat,'Children');
hrootpath=findobj(hchild,'Tag','RootPath');
if isempty(hrootpath)
    RootPath='';
else
    RootPath=get(hrootpath,'String');
    if iscell(RootPath)
        RootPath=RootPath{1};
    end
end
title={'object name'};
dir_save=uigetdir(RootPath);
def={fullfile(dir_save,['Object' Object.CoordType '.xml'])};
options.Resize='on';
displ_txt='save object as an .xml file';%default display
menu=get(handles.ProjMode,'String');
value=get(handles.ProjMode,'Value');
ProjMode=menu{value};
if strcmp(ProjMode,'mask_inside')||strcmp(ProjMode,'mask_outside')
    displ_txt='save mask contour as an .xml file: to create a mask image, use save_mask on the GUI uvmat (lower right)';
end
answer=msgbox_uvmat('INPUT_TXT','save object as an .xml file',def);
%answer=inputdlg('','save object in a new .xml file',1,def,'on');
if ~isempty(answer)
    t=struct2xml(Object);
    save(t,answer{1})
end
msgbox_uvmat('CONFIRMATION',[answer{1}  ' saved'])
%---------------------------------------------------------
% --- Executes on slider movement.
function z_slider_Callback(hObject, eventdata, handles)
%---------------------------------------------------------
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
set(handles.XObject,'String',num2str(NormVec_X*Z_value,4))
set(handles.YObject,'String',num2str(NormVec_Y*Z_value,4))
set(handles.ZObject,'String',num2str(NormVec_Z*Z_value,4))
PLOT_Callback(hObject, eventdata, handles)



function XObject_Callback(hObject, eventdata, handles)


function YObject_Callback(hObject, eventdata, handles)




function ZObject_Callback(hObject, eventdata, handles)


% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), errordlg('Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
    web([helpfile '#set_object'])    
end




