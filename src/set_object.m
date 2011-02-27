%'set_object': GUI to edit a projection object
%------------------------------------------------------------------------
% function hset_object= set_object(data, PlotHandles,ZBounds)
% associated with the GUI set_object.fig
%
% OUTPUT:
% hset_object: handle of the GUI figure
% 
% INPUT:
% data: structure describing the object properties
%    .Style=...
%    .ProjMode
%    .CoordType: 'phys' or 'px'
%    .DX,.DY,.DZ : mesh along each dirction
%    .RangeX, RangeY
%    .Coord(j,i), i=1, 2, 3,  components x, y, z of j=1...n position(s) characterizing the object components
% PlotHandles: handles for projection plots NO MORE USED
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
if nargin & ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT PLOT
%------------------------------------------------------------------------
%------------------------------------------------------------------------
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
%-------------------------------------------------------------------
% Choose default command line output for set_object
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

%default
if ~exist('ZBounds','var')
    ZBounds=0; %default 
end
set(hObject,'KeyPressFcn',{'keyboard_callback',handles})%set keyboard action function (allow action on uvmat when set_object is in front)
enable_plot=0;%default: does not allow plot of object and projection

% fill the interface as set in the input data:
if exist('data','var') 
    if isfield(data,'enable_plot')
        enable_plot=data.enable_plot;%test to desable button PLOT (display mode)
    end
    if isfield(data,'Name')
        set(handles.TITLE,'String',data.Name)
    end
    if ~isfield(data,'NbDim')||~isequal(data.NbDim,3)%2D case
        set(handles.ZObject,'Visible','off')
        set(handles.z_slider,'Visible','off')
    else
        set(handles.ZObject,'Visible','on')
        set(handles.z_slider,'Visible','on')
        if isfield(data,'Coord') && size(data.Coord,2)==3
            set(handles.ZObject,'String',num2str(data.Coord(1,3),4))
        end
    end
    if isfield(data,'StyleMenu')
        set(handles.ObjectStyle,'String',data.StyleMenu);
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
    ObjectStyle_Callback(hObject, eventdata, handles)
    if isfield(data,'ProjMenu')
        set(handles.ProjMode,'String',data.ProjMenu);%overset the standard menu
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
    ProjMode_Callback(hObject, eventdata, handles)
    if isfield(data,'Coord')
        if ischar(data.Coord)
            data.Coord=str2num(data.Coord);
        elseif iscell(data.Coord)
            CoordCell=data.Coord;
            data.Coord=zeros(numel(CoordCell),3);
            data.Coord(:,3)=zeros(numel(CoordCell),1); % z component set to 0 by default
            for iline=1:numel(CoordCell)
                line_vec=str2num(CoordCell{iline});
                if numel(line_vec)==2
                    data.Coord(iline,1:2)=str2num(CoordCell{iline});
                else
                    data.Coord(iline,:)=str2num(CoordCell{iline});
                end
            end
        end
        if size(data.Coord,2)>=2
            sizcoord=size(data.Coord);
            for i=1:sizcoord(1)
                XObject{i}=num2str(data.Coord(i,1),4);
                YObject{i}=num2str(data.Coord(i,2),4);
            end
            set(handles.XObject,'String',XObject)
            set(handles.YObject,'String',YObject)
            if sizcoord(2)>3
                for i=1:sizcoord(1)
                    ZObject{i}=num2str(data.Coord(i,3),4);
                end
                set(handles.ZObject,'String',ZObject)
            end
        end
    end
    if isfield(data,'DX')
        if ~ischar(handles.DX)
            data.DX=num2str(data.DX,3);
        end
        set(handles.DX,'String',data.DX)
    end
    if isfield(data,'DY')
        if ~ischar(handles.DY)
            data.DY=num2str(data.DY,3);
        end
        set(handles.DY,'String',data.DX)
    end
    if isfield(data,'RangeZ') && length(ZBounds) >= 2
        set(handles.ZMax,'String',num2str(max(data.RangeZ),3))
        DZ=max(data.RangeZ);%slider step
        if ~isnan(ZBounds(1)) && ZBounds(2)~=ZBounds(1)
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
        if ischar(data.RangeX)
            data.RangeX=str2num(data.RangeX);
        end
        set(handles.XMax,'String',num2str(max(data.RangeX),3))
        set(handles.XMin,'String',num2str(min(data.RangeX),3))
    end
    if isfield(data,'RangeY')
        if ischar(data.RangeY)
            data.RangeY=str2num(data.RangeY);
        end
        set(handles.YMax,'String',num2str(max(data.RangeY),3))
        set(handles.YMin,'String',num2str(min(data.RangeY),3))
    end
    if isfield(data,'RangeZ')
        if ischar(data.RangeZ)
            data.RangeZ=str2num(data.RangeZ);
        end
        set(handles.ZMax,'String',num2str(max(data.RangeZ),3))
        if numel(data.RangeZ)>=2
            set(handles.ZMin,'String',num2str(min(data.RangeZ),3))
        end
    end  
    if isfield(data,'Phi')
        if ~ischar(handles.Phi)
            data.DY=num2str(data.Phi,3);
        end
         set(handles.Phi,'String',data.Phi)
    end
    if isfield(data,'Theta')
        if ~ischar(handles.Theta)
            data.DY=num2str(data.Theta,3);
        end
        set(handles.Theta,'String',data.Theta)
    end
    if isfield(data,'Psi')
         if ~ischar(handles.Psi)
            data.DY=num2str(data.Psi,3);
        end
         set(handles.Psi,'String',data.Psi)
    end  
    if isfield(data,'DZ')
        if ~ischar(handles.DZ)
            data.DY=num2str(data.DZ,3);
        end
        set(handles.DZ,'String',data.DZ)
    end
    if isfield(data,'CoordUnit')
        set(handles.CoordUnit,'String',data.CoordUnit)
    end
end
if enable_plot
   set(handles.PLOT,'enable','on')
else
   set(handles.PLOT,'enable','off') 
end
huvmat=findobj(allchild(0),'tag','uvmat');
UvData=get(huvmat,'UserData');
pos_uvmat=get(huvmat,'Position');
%position the set_object GUI with respect to uvmat
if isfield(UvData,'SetObjectOrigin')
    pos_set_object(1:2)=UvData.SetObjectOrigin + pos_uvmat(1:2);
    pos_set_object(3:4)=UvData.SetObjectSize .* pos_uvmat(3:4);
    set(hObject,'Position',pos_set_object)
end

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = set_object_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;

%------------------------------------------------------------------------
% --- Executes on selection change in ObjectStyle.
function ObjectStyle_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
style_prev=get(handles.ObjectStyle,'UserData');%previous object style
str=get(handles.ObjectStyle,'String');
val=get(handles.ObjectStyle,'Value');
style=str{val};
% make correspondance between different object styles
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
if isequal(style,'line')
    if strcmp(style_prev,'rectangle')||strcmp(style_prev,'ellipse')
        XMax=get(handles.XMax,'String');
        YMax=get(handles.YMax,'String');
        x_new{2}=num2str(XMax,4);
        y_new{2}=num2str(YMax,4);
        set(handles.XObject,'String',x_new)
        set(handles.YObject,'String',y_new)
        set(handles.ZObject,'String',z_new)
    end
elseif isequal(style,'polyline')
elseif strcmp(style,'rectangle')|| strcmp(style,'ellipse')
     set(handles.XObject,'String',x_new)
     set(handles.YObject,'String',y_new)
     set(handles.ZObject,'String',z_new)
end

switch style
    case {'points','line','polyline','plane'}
        menu_proj={'projection';'interp';'filter';'none'}; 
    case {'polygon','rectangle','ellipse'}
        menu_proj={'inside';'outside';'mask_inside';'mask_outside'};
    case 'volume'
        menu_proj={'interp';'none'};
end   
proj_index=get(handles.ProjMode,'Value');
if proj_index<numel(menu_proj)
    set(handles.ProjMode,'Value',1);% value index must not exceed the menu length
end
set(handles.ProjMode,'String',menu_proj)
ProjMode_Callback(hObject, eventdata, handles)
%store the current option
str=get(handles.ObjectStyle,'String');
val=get(handles.ObjectStyle,'Value');
set(handles.ObjectStyle,'UserData',style)

%------------------------------------------------------------------------
function xObject_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function yObject_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on selection change in zObject.
function zObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%------------------------------------------------------------------------
% --- Executes on selection change in ProjMode.
function ProjMode_Callback(hObject, eventdata, handles)
menu=get(handles.ProjMode,'String');
value=get(handles.ProjMode,'Value');
ProjMode=menu{value};
menu=get(handles.ObjectStyle,'String');
value=get(handles.ObjectStyle,'Value');
ObjectStyle=menu{value};
test3D=isequal(get(handles.ZObject,'Visible'),'on');%3D case

%default setting
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
if strcmp(ObjectStyle,'rectangle')||strcmp(ObjectStyle,'ellipse')
    set(handles.XMax,'Visible','on')
else
   set(handles.XMax,'Visible','off')
end
set(handles.ZMin,'Visible','off')
set(handles.ZMax,'Visible','off')
set(handles.DX,'Visible','off')
set(handles.DY,'Visible','off')
set(handles.DZ,'Visible','off')

switch ObjectStyle
    case 'points'
        set(handles.YMax,'TooltipString','YMax: range of averaging around each point') 
        set(handles.XObject,'TooltipString','XObject: set of x coordinates of the points')
        set(handles.YObject,'TooltipString','YObject: set of y coordinates of the points')
        set(handles.ZObject,'TooltipString','ZObject: set of z coordinates of the points')
    case {'line','polyline','polygon'}
        set(handles.YMax,'TooltipString','YMax: range of averaging around the line')
        set(handles.XObject,'TooltipString','XObject: set of x coordinates defining the line')
        set(handles.YObject,'TooltipString','YObject: set of y coordinates defining the line')
        set(handles.ZObject,'TooltipString','ZObject: set of z coordinates defining the line')
        if isequal(ProjMode,'interp')|| isequal(ProjMode,'filter')
            set(handles.DX,'Visible','on')
            set(handles.DX,'TooltipString','DX: mesh for the interpolated field along the line')
        end       
    case {'rectangle','ellipse'}
        set(handles.XMax,'TooltipString',['XMax: half length of the ' ObjectStyle])
        set(handles.YMax,'TooltipString',['YMax: half width of the ' ObjectStyle])
        set(handles.XObject,'TooltipString',['XObject:  x coordinate of the ' ObjectStyle ' centre'])
        set(handles.YObject,'TooltipString',['YObject:  y coordinate of the ' ObjectStyle ' centre'])
    case {'plane'}  
        set(handles.Phi,'Visible','on')
        set(handles.XMin,'Visible','on')
        set(handles.XMax,'Visible','on')
        set(handles.YMin,'Visible','on')
        set(handles.YMax,'Visible','on')
        set(handles.XObject,'TooltipString',['XObject:  x coordinate of the axis origin for the ' ObjectStyle])
        set(handles.YObject,'TooltipString',['YObject:  y coordinate of the axis origin for the ' ObjectStyle])
        set(handles.ZMax,'TooltipString','ZMax: range of projection normal to the plane')
        if test3D
            set(handles.Theta,'Visible','on')
            set(handles.Psi,'Visible','on')
            set(handles.ZMax,'Visible','on')
        end
        if isequal(ProjMode,'interp')|| isequal(ProjMode,'filter')
            set(handles.DX,'Visible','on')
            set(handles.DY,'Visible','on')
        else
            set(handles.DX,'Visible','off')
            set(handles.DY,'Visible','off')
        end
        if  isequal(ProjMode,'interp')
            set(handles.DZ,'Visible','on')  
        end
     case {'volume'}  
        set(handles.Phi,'Visible','on')
        set(handles.XMin,'Visible','on')
        set(handles.XMax,'Visible','on')
        set(handles.YMin,'Visible','on')
        set(handles.YMax,'Visible','on')
        set(handles.XObject,'TooltipString',['XObject:  x coordinate of the axis origin for the ' ObjectStyle])
        set(handles.YObject,'TooltipString',['YObject:  y coordinate of the axis origin for the ' ObjectStyle])
%         if test3D
            set(handles.Theta,'Visible','on')
            set(handles.Psi,'Visible','on')
            set(handles.ZMin,'Visible','on')
            set(handles.ZMax,'Visible','on')
%         end
        if isequal(ProjMode,'interp')|| isequal(ProjMode,'filter')
            set(handles.DX,'Visible','on')
            set(handles.DY,'Visible','on')
            set(handles.DZ,'Visible','on')
        else
            set(handles.DX,'Visible','off')
            set(handles.DY,'Visible','off')
            set(handles.DZ,'Visible','off')
        end
end
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function Phi_Callback(hObject, eventdata, handles)
update_slider(hObject, eventdata,handles)
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function Theta_Callback(hObject, eventdata, handles)
update_slider(hObject, eventdata,handles)
%------------------------------------------------------------------------
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
%------------------------------------------------------------------------
function DX_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function DY_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function DZ_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%-----------------------------------------------------
% --- Executes on button press in OPEN: DESACTIVATED use uvmat browser
function OPEN_Callback(hObject, eventdata, handles)
%get the object file 
oldfile=' ';
huvmat=findobj('Tag','uvmat');
hchild=get(huvmat,'Children');
hrootpath=findobj(hchild,'Tag','RootPath');
if ~isempty(hrootpath)
    oldfile=get(hrootpath,'String');
    if iscell(oldfile)
        oldfile=oldfile{1};
    end
end
[FileName, PathName, filterindex] = uigetfile( ...
       {'*.xml;*.mat', ' (*.xml,*.mat)';
       '*.xml',  '.xml files '; ...
        '*.mat',  '.mat matlab files '}, ...
        'Pick a file',oldfile);
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
 s=convert(t);
 if ~isfield(s,'Style')
     s.Style='points';
 end
 if ~isfield(s,'ProjMode')
     s.ProjMode='none';
 end
teststyle=0;

switch s.Style
    case {'points','line','polyline','plane'}
        menu_proj={'projection';'interp';'filter';'none'}; 
    case {'polygon','rectangle','ellipse'}
        menu_proj={'inside';'outside';'mask_inside';'mask_outside'};
    case 'volume'
        menu_proj={'none'};
end
set(handles.ObjectStyle,'String',menu_proj)
menu=get(handles.ObjectStyle,'String');
for iline=1:length(menu)
    if isequal(menu{iline},s.Style)
        set(handles.ObjectStyle,'Value',iline)
        teststyle=1;
        break
    end
end
testmode=0;
%menu=get(handles.ProjMode,'String');
for iline=1:length(menu_proj)
    if isequal(menu_proj{iline},s.ProjMode)
        set(handles.ProjMode,'Value',iline)
        testmode=1;
        break
    end
end

ProjMode_Callback(hObject, eventdata, handles);%visualize the appropriate edit boxes
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
%------------------------------------------------------------------------
%----------------------------------------------------
% executed when closing: set the parent interface button to value 0
function closefcn(gcbo,eventdata,parent_button)

huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
%     set(hhuvmat.create,'Value',0)
%     set(hhuvmat.create,'BackgroundColor',[0 1 0])%put unactivated buttons to green
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

%------------------------------------------------------------------------
% --- Executes on button press in PLOT: PLOT the defined object and its projected field
function PLOT_Callback(hObject, eventdata, handles)

%% reading the object parameters on the GUI uvmat
huvmat=findobj('tag','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the GUI uvmat 
hhuvmat=guidata(huvmat);%handles in the uvmat GUI
ObjectName=get(handles.TITLE,'String');%name of the current object 
ListObject=get(hhuvmat.list_object_1,'String');%position in the objet list
IndexObj_1=get(hhuvmat.list_object_1,'Value');
if isequal(get(hhuvmat.list_object_2,'Visible'),'on')
    IndexObj_2=get(hhuvmat.list_object_2,'Value');
    List2=get(hhuvmat.list_object_2,'String');
    if IndexObj_2==length(List2)
        IndexObj_2=[];% '...' selected
    end
else
    IndexObj_2=[];
end
testnew=0;
ObjectData=read_set_object(handles);%read the input parameters defining the object in the GUI set_object
if strcmp(ListObject{IndexObj_1},ObjectName)% we are editing the object whose projection is viewed in the uvmat frame
    IndexObj=IndexObj_1;
    projview='uvmat';
elseif ~isempty(IndexObj_2) && IndexObj_2<=numel(ListObject)&& strcmp(ListObject{IndexObj_2},ObjectName)% we are editing the object whose projection is viewed in view_field  
    IndexObj=IndexObj_2;
    projview='view_field';
else %new object 
    testnew=1;
    IndexObj=numel(ListObject)+1;
    projview='view_field';
end
if strcmp(projview,'view_field')
    hview_field=findobj(allchild(0),'tag','view_field');
    if isempty(hview_field)
        hview_field=view_field;
%     elseif strcmp(ObjectData.ProjMode,'none')||strcmp(ObjectData.ProjMode,'mask_inside')||strcmp(ObjectData.ProjMode,'mask_outside')
    end
    PlotHandles=guidata(hview_field);
    plotaxes=PlotHandles.axes3;%handle of axes3 in view_field
else
    PlotHandles=hhuvmat;
    plotaxes=hhuvmat.axes3;%handle of axes3 in view_field
end   

%% naming the object
if length(ObjectName)<1% name of object not defined in set_object
    ObjectName=[num2str(IndexObj) '-' ObjectData.Style];%default name
elseif ~get(hhuvmat.edit_object,'Value')%not in edit mode (new object created)
    detectname=1;
    ObjectNameNew=ObjectName;
    vers=0;
    while detectname==1 
        detectname=find(strcmp(ObjectNameNew,ListObject),1);%test the existence of the proposed name in the list
        if detectname% if the object name already exists
            indstr=regexp(ObjectNameNew,'\D');
            if indstr(end)<length(ObjectNameNew) %object name ends by a number
                vers=str2double(ObjectNameNew(indstr(end)+1:end))+1;
                ObjectNameNew=[ObjectNameNew(1:indstr(end)) num2str(vers)];
            else
                vers=vers+1;
                ObjectNameNew=[ObjectNameNew(1:indstr(end)) '_' num2str(vers)];      
            end
        end
    end
    ObjectName=ObjectNameNew;
end
ListObject{IndexObj,1}=ObjectName;
set(hhuvmat.list_object_1,'String',ListObject)
set(hhuvmat.list_object_2,'String',[ListObject;{'...'}])

%% update the object plot and projection field
if testnew 
    set(hhuvmat.list_object_2,'Value',IndexObj)
    ObjectData.DisplayHandle_uvmat=hhuvmat.axes3;
    ObjectData.DisplayHandle_view_field=[];
else
    if isfield(UvData.Object{IndexObj},'DisplayHandle_uvmat')% save the previous object graph handles
        ObjectData.DisplayHandle_uvmat=UvData.Object{IndexObj}.DisplayHandle_uvmat;
    else
        ObjectData.DisplayHandle_uvmat=hhuvmat.axes3;%there is no object handle, than the axes handles is used as input
    end
    if isfield(UvData.Object{IndexObj},'DisplayHandle_view_field')% save the previous object graph handles
        ObjectData.DisplayHandle_view_field=UvData.Object{IndexObj}.DisplayHandle_view_field;
    else
        ObjectData.DisplayHandle_view_field=[];
    end
end
UvData.Object{IndexObj}=ObjectData;%update the current object properties
UvData.Object=update_obj(UvData,IndexObj_1,IndexObj_2);
set(huvmat,'UserData',UvData)

%% plot the field projected on the object and store in the corresponding figue
'TESTproj'
ProjData= proj_field(UvData.Field,ObjectData)%project the current interface field on ObjectData
PlotParam=read_plot_param(PlotHandles);
[PlotType,Object_out{IndexObj}.PlotParam,plotaxes]=plot_field(ProjData,plotaxes,PlotParam);%update an existing field plot

%% update the GUI uvmat
hhuvmat=guidata(huvmat);%handles of elements in the uvmat GUI
set(hhuvmat.MenuEditObject,'enable','on')
set(hhuvmat.edit_object,'Value',1) % set uvmat to object edit mode to allow further object update
set(hhuvmat.edit_object,'BackgroundColor',[1 1 0]);% paint the edit text in yellow
%UvData.MouseAction='edit_object'; % set the edit button to 'on'

%------------------------------------------------------------------------
% --- Executes on button press in MenuCoord.
function MenuCoord_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%----------------------------------------------------
function YMin_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

function ZMin_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

function ZMax_Callback(hObject, eventdata, handles)
DZ=str2num(get(handles.ZMax,'String'));
ZMin=get(handles.z_slider,'Min');
ZMax=get(handles.z_slider,'Max');
if ~isequal(ZMax-ZMin,0)
    rel_step(1)=DZ/(ZMax-ZMin);
    rel_step(2)=0.2;
    set(handles.z_slider,'SliderStep',rel_step)
end
%------------------------------------------------------------------------
function YMax_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

function XMin_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

function XMax_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%------------------------------------------------------------------------
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
ObjectName=get(handles.TITLE,'String');
if ~isempty(ObjectName)&&~strcmp(ObjectName,'')
    def={fullfile(dir_save,[ObjectName '.xml'])};
else
    def={fullfile(dir_save,[Object.Style '.xml'])};
end
displ_txt='save object as an .xml file';%default display
menu=get(handles.ProjMode,'String');
value=get(handles.ProjMode,'Value');
ProjMode=menu{value};
if strcmp(ProjMode,'mask_inside')||strcmp(ProjMode,'mask_outside')
    displ_txt='save mask contour as an .xml file: to create a mask image, use save_mask on the GUI uvmat (lower right)';
end
answer=msgbox_uvmat('INPUT_TXT','save object as an .xml file',def);
if ~isempty(answer)
    t=struct2xml(Object);
    save(t,answer{1})
end
msgbox_uvmat('CONFIRMATION',[answer{1}  ' saved'])
%------------------------------------------------------------------------
%------------------------------------------------------------------------
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
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
else
    addpath (fullfile(pathelp,'uvmat_doc'))
    web([helpfile '#set_object']) 
end
%------------------------------------------------------------------------


