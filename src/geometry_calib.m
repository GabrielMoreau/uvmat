%'geometry_calib': performs geometric calibration from a set of reference points
%
% function varargout = geometry_calib(varargin)
%
%A%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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

function varargout = geometry_calib(varargin)
% GEOMETRY_CALIB M-file for geometry_calib.fig
%      GEOMETRY_CALIB, by itself, creates a MenuCoord GEOMETRY_CALIB or raises the existing
%      singleton*.
%
%      H = GEOMETRY_CALIB returns the handle to a MenuCoord GEOMETRY_CALIB or the handle to
%      the existing singleton*.
%
%      GEOMETRY_CALIB('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GEOMETRY_CALIB.M with the given input arguments.
%
%      GEOMETRY_CALIB('Property','Value',...) creates a MenuCoord GEOMETRY_CALIB or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before geometry_calib_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to geometry_calib_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help geometry_calib

% Last Modified by GUIDE v2.5 25-Mar-2010 19:10:05

% Begin initialization code - DO NOT edit
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @geometry_calib_OpeningFcn, ...
                   'gui_OutputFcn',  @geometry_calib_OutputFcn, ...
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
% End initialization code - DO NOT edit


% --- Executes just before geometry_calib is made visible.
%INPUT: 
%handles: handles of the geometry_calib interface elements
% PlotHandles: set of handles of the elements contolling the plotting
% parameters on the uvmat interface (obtained by 'get_plot_handle.m')
%------------------------------------------------------------------------
function geometry_calib_OpeningFcn(hObject, eventdata, handles, handles_uvmat,pos,inputfile)
%------------------------------------------------------------------------
% Choose default command line output for geometry_calib
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
%movegui(hObject,'east');% position the GUI ton the right of the screen
% if exist('handles_uvmat','var') %& isfield(data,'ParentButton')
      set(hObject,'DeleteFcn',{@closefcn})%
% end
%set the position of the interface
if exist('pos','var')& length(pos)>2
    pos_gui=get(hObject,'Position');
    pos_gui(1)=pos(1);
    pos_gui(2)=pos(2);
    set(hObject,'Position',pos_gui);
end
inputxml='';
if exist('inputfile','var')& ~isempty(inputfile)
    [Path,Name,ext]=fileparts(inputfile);
    form=imformats(ext([2:end]));
    if ~isempty(form)% if the input file is an image
        struct.XmlInputfile=inputfile;
        set(hObject,'UserData',struct)
        [Pathsub,RootFile,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(inputfile);
        inputxml=[fullfile(Pathsub,RootFile) '.xml'];
    end   
end
set(handles.ListCoord,'String',{'...'})
if exist(inputxml,'file')
    loadfile(handles,inputxml)% load the point coordiantes existing in the xml file
end

set(handles.ListCoord,'KeyPressFcn',{@key_press_fcn,handles})%set keyboard action function
%set(hObject,'KeyPressFcn',{'keyboard_callback',handles})%set keyboard action function on uvmat interface when geometry_calib is on top 
%htable=uitable(10,5) 
%set(htable,'ColumnNames',{'x','y','z','X(pixels)','Y(pixels)'})

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = geometry_calib_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;

%------------
function Phi_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
%read input xml file and update the edit boxes
function loadfile(handles,fileinput)
%------------------------------------------------------------------------
%read the input xml file
t=xmltree(fileinput);
s=convert(t);%convert to matlab structure
%read data currently displayed on the interface
PointCoord=[];
Coord_cell=get(handles.ListCoord,'String');
data=read_geometry_calib(Coord_cell);
%data=read_geometry_calib(handles);
Coord=[]; %default
if isfield(data,'Coord')
    Coord=data.Coord;
end
TabChar_0=get(handles.ListCoord,'String');
nbcoord_0=size(TabChar_0,1);
if isequal(get(handles.edit_append,'Value'),2) %edit mode  A REVOIR
    val=get(handles.ListCoord,'Value')-1;
else
   val=length(TabChar_0); 
end
nbcoord=0;

%case of calibration (ImaDoc) input file
% hcalib=get(handles.calib_type,'parent');
CalibData=get(handles.geometry_calib,'UserData');
CalibData.XmlInput=fileinput;
if isfield(s,'Heading')
    CalibData.Heading=s.Heading;
end

set(handles.geometry_calib,'UserData',CalibData);%store the heading in the interface 'UserData'
if isfield(s,'GeometryCalib')
    Calib=s.GeometryCalib;
    if isfield(Calib,'CalibrationType')
        CalibrationType=Calib.CalibrationType;
        switch CalibrationType
            case 'linear'
                set(handles.calib_type,'Value',2)
            case 'tsai'
                set(handles.calib_type,'Value',3)
        end
    end
    if isfield(Calib,'SourceCalib')
        if isfield(Calib.SourceCalib,'PointCoord')
            PointCoord=Calib.SourceCalib.PointCoord;
        end
    end
    nbcoord=length(PointCoord);
    if ~isfield(Calib,'ErrorRms')&~isfield(Calib,'ErrorMax') %old convention of Gauthier (cord in mm)
        for i=1:length(PointCoord)
          line=str2num(PointCoord{i});
          Coord(i+val,4:5)=line(4:5);%px x
          Coord(i+val,1:3)=line(1:3)/10;%phys x
        end
    else
        for i=1:length(PointCoord)
          line=str2num(PointCoord{i});
          Coord(i,4:5)=line(4:5);%px x
          Coord(i,1:3)=line(1:3);%phys x
       end
    end
end
%case of xml files of points 
if isfield(s,'Coord')
    PointCoord=s.Coord;
    nbcoord=length(PointCoord);
     %case of image coordinates
    if isfield(s,'CoordType')& isequal(s.CoordType,'px')
        for i=1:nbcoord
           line=str2num(PointCoord{i});
           Coord(i+val,4:5)=line(1:2);
        end
     %case of  physical coordinates
    else
        for i=1:nbcoord
           line=str2num(PointCoord{i});
           Coord(i+val,1:3)=line(1:3);
           nbcolumn=size(Coord,2);
           if nbcolumn<5
               Coord(i+val,nbcolumn+1:5)=zeros(1,5-nbcolumn);
           end
        end
     end
end
CoordCell={};
for iline=1:size(Coord,1)
    for j=1:5
        CoordCell{iline,j}=num2str(Coord(iline,j),4);
    end
end
CoordCell=[CoordCell;{' ',' ',' ',' ',' '}];
Tabchar=cell2tab(CoordCell,'    |    ');%transform cells into table ready for display
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)

% 
%------------------------------------------------------------------------
% executed when closing: set the parent interface button to value 0
function closefcn(gcbo,eventdata)
%------------------------------------------------------------------------
huvmat=findobj(allchild(0),'Name','uvmat');
if ~isempty(huvmat)
    handles=guidata(huvmat);
    set(handles.MenuTools,'enable','on')
    set(handles.MenuObject,'enable','on')
    set(handles.MenuEdit,'enable','on')
    set(handles.edit,'enable','on')
    hobject=findobj(handles.axes3,'tag','calib_points');
    if ~isempty(hobject)
        delete(hobject)
    end
    hobject=findobj(handles.axes3,'tag','calib_marker');
    if ~isempty(hobject)
        delete(hobject)
    end    
end

%------------------------------------------------------------------------
% --- Executes on button press in calibrate_lin.
function APPLY_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
calib_cell=get(handles.calib_type,'String');
val=get(handles.calib_type,'Value');
calib_type=calib_cell{val};
Coord_cell=get(handles.ListCoord,'String');
Object=read_geometry_calib(Coord_cell);

if isequal(calib_type,'rescale')
    GeometryCalib=calib_rescale(Object.Coord);
elseif isequal(calib_type,'linear')
    GeometryCalib=calib_linear(Object.Coord);
elseif isequal(calib_type,'tsai_cpp')
    GeometryCalib=calib_tsai(Object.Coord);
elseif isequal(calib_type,'tsai_matlab')
    GeometryCalib=calib_tsai2(Object.Coord);
end
unitlist=get(handles.CoordUnit,'String');
unit=unitlist{get(handles.CoordUnit,'value')};
GeometryCalib.CoordUnit=unit;
GeometryCalib.SourceCalib.PointCoord=Object.Coord;
huvmat=findobj(allchild(0),'Name','uvmat');
hhuvmat=guidata(huvmat);%handles of elements in the GUI uvmat
RootPath='';
RootFile='';
if ~isempty(hhuvmat.RootPath)& ~isempty(hhuvmat.RootFile)
    testhandle=1;
    RootPath=get(hhuvmat.RootPath,'String');
    RootFile=get(hhuvmat.RootFile,'String');
    filebase=fullfile(RootPath,RootFile);
    outputfile=[filebase '.xml'];
else
    question={'save the calibration data and point coordinates in'};
    def={fullfile(RootPath,['ObjectCalib.xml'])};
    options.Resize='on';
    answer=inputdlg(question,'save average in a new file',1,def,options);
    outputfile=answer{1};
end
update_imadoc(GeometryCalib,outputfile)
msgbox_uvmat('CONFIRMATION',{[outputfile ' updated with calibration data'];...
    ['Error rms (along x,y)=' num2str(GeometryCalib.ErrorRms) ' pixels'];...
    ['Error max (along x,y)=' num2str(GeometryCalib.ErrorMax) ' pixels']})

%display image with new calibration in the currently opened uvmat interface
hhh=findobj(hhuvmat.axes3,'Tag','calib_marker');% delete calib points and markers
if ~isempty(hhh)
    delete(hhh);
end
hhh=findobj(hhuvmat.axes3,'Tag','calib_points');
if ~isempty(hhh)
    delete(hhh);
end
set(hhuvmat.FixedLimits,'Value',0)% put FixedLimits option to 'off'
set(hhuvmat.FixedLimits,'BackgroundColor',[0.7 0.7 0.7])
uvmat('RootPath_Callback',hObject,eventdata,hhuvmat); %file input with xml reading  in uvmat

figure(handles.geometry_calib)

%------------------------------------------------------------------
% --- Executes on button press in calibrate_lin.
function REPLICATE_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
calib_cell=get(handles.calib_type,'String');
val=get(handles.calib_type,'Value');
calib_type=calib_cell{val};
Coord_cell=get(handles.ListCoord,'String');
Object=read_geometry_calib(Coord_cell);

if isequal(calib_type,'rescale')
    GeometryCalib=calib_rescale(Object.Coord);
elseif isequal(calib_type,'linear')
    GeometryCalib=calib_linear(Object.Coord);
elseif isequal(calib_type,'tsai')
    GeometryCalib=calib_tsai(Object.Coord);
end
% %record image source
GeometryCalib.SourceCalib.PointCoord=Object.Coord;

%open and read the dataview GUI
h_dataview=findobj(allchild(0),'name','dataview');
if ~isempty(h_dataview)
    delete(h_dataview)
end
CalibData=get(handles.geometry_calib,'UserData');%read the calibration image source on the interface userdata

if isfield(CalibData,'XmlInput')
    XmlInput=fileparts(CalibData.XmlInput);
    [XmlInput,filename,ext]=fileparts(XmlInput);
end
SubCampaignTest='n'; %default
testinput=0;
if isfield(CalibData,'Heading')
    Heading=CalibData.Heading;
    if isfield(Heading,'Record') && isequal([filename ext],Heading.Record)
        [XmlInput,filename,ext]=fileparts(XmlInput);
    end
    if isfield(Heading,'Device') && isequal([filename ext],Heading.Device)
        [XmlInput,filename,ext]=fileparts(XmlInput);
        Device=Heading.Device;
    end
    if isfield(Heading,'Experiment') && isequal([filename ext],Heading.Experiment)
        [PP,filename,ext]=fileparts(XmlInput);
    end
    testinput=0;
    if isfield(Heading,'SubCampaign') && isequal([filename ext],Heading.SubCampaign)
        SubCampaignTest='y';
        testinput=1;
    elseif isfield(Heading,'Campaign') && isequal([filename ext],Heading.Campaign)
        testinput=1;
    end 
end
if ~testinput
    filename='PROJETS';%default
    if isfield(CalibData,'XmlInput')
         [pp,filename]=fileparts(CalibData.XmlInput);
    end
    while ~isequal(filename,'PROJETS') && numel(filename)>1
        filename_1=filename;
        pp_1=pp;
        [pp,filename]=fileparts(pp);
    end
    XmlInput=fullfile(pp_1,filename_1);
    testinput=1;
end
if testinput
    outcome=dataview(XmlInput,SubCampaignTest,GeometryCalib);
end

%------------------------------------------------------------------------
% determine the parameters for a calibration by an affine function (rescaling and offset, no rotation)
function GeometryCalib=calib_rescale(Coord)
%------------------------------------------------------------------------
 
X=Coord(:,1);
Y=Coord(:,2);
x_ima=Coord(:,4);
y_ima=Coord(:,5);
[px,sx]=polyfit(X,x_ima,1);
[py,sy]=polyfit(Y,y_ima,1);
T_x=px(2);
T_y=py(2);
GeometryCalib.CalibrationType='rescale';
GeometryCalib.focal=1;
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=[T_x T_y 1];
GeometryCalib.R=[px(1),0,0;0,py(1),0;0,0,1];

%check error
Calib.dpx=1;
Calib.dpy=1;
Calib.sx=1;
Calib.Cx=0;
Calib.Cy=0;
Calib.Tz=1;
Calib.kappa1=0;
Calib.f=GeometryCalib.focal;
Calib.Tx=T_x;
Calib.Ty=T_y;
Calib.R=GeometryCalib.R;
[Xpoints,Ypoints]=px_XYZ(Calib,X,Y,0);
GeometryCalib.ErrorRms(1)=sqrt(mean((Xpoints-x_ima).*(Xpoints-x_ima)));
GeometryCalib.ErrorMax(1)=max(abs(Xpoints-x_ima));
GeometryCalib.ErrorRms(2)=sqrt(mean((Ypoints-y_ima).*(Ypoints-y_ima)));
GeometryCalib.ErrorMax(2)=max(abs(Ypoints-y_ima));

%------------------------------------------------------------------------
% determine the parameters for a calibration by a linear transform matrix (rescale and rotation)
function GeometryCalib=calib_linear(Coord)
%------------------------------------------------------------------------
X=Coord(:,1);
Y=Coord(:,2);
x_ima=Coord(:,4);
y_ima=Coord(:,5);
XY_mat=[ones(size(X)) X Y];
a_X1=XY_mat\x_ima; %transformation matrix for X
x1=XY_mat*a_X1;%reconstruction
err_X1=max(abs(x1-x_ima));%error
a_Y1=XY_mat\y_ima;%transformation matrix for X
y1=XY_mat*a_Y1;
err_Y1=max(abs(y1-y_ima));%error
T_x=a_X1(1);
T_y=a_Y1(1);
GeometryCalib.CalibrationType='linear';
GeometryCalib.focal=1;
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=[T_x T_y 1]; 
GeometryCalib.R=[a_X1(2),a_X1(3),0;a_Y1(2),a_Y1(3),0;0,0,1];

%check error
GeometryCalib.ErrorRms(1)=sqrt(mean((x1-x_ima).*(x1-x_ima)));
GeometryCalib.ErrorMax(1)=max(abs(x1-x_ima));
GeometryCalib.ErrorRms(2)=sqrt(mean((y1-y_ima).*(y1-y_ima)));
GeometryCalib.ErrorMax(2)=max(abs(y1-y_ima));

%------------------------------------------------------------------------
function GeometryCalib=calib_tsai2(Coord)
%------------------------------------------------------------------
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT

x_1=Coord(:,4:5)';
X_1=Coord(:,1:3)';
n_ima=1;
% check_cond=0;
nx=1024;ny=1024;
% est_kc=[1;0;0;0;0];
est_dist=[1;0;0;0;0];
run('D:\PROG\MATLAB\TOOLBOX_calib\go_calib_optim');

GeometryCalib.CalibrationType='tsai';
GeometryCalib.focal=f(2);
GeometryCalib.dpx_dpy=[1 1];
GeometryCalib.Cx_Cy=cc';
GeometryCalib.sx=fc(1)/fc(2);
GeometryCalib.kappa1=-k(1)/f(2)^2;
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=Tc_1';
GeometryCalib.R=Rc_1;
Calib.dpx=GeometryCalib.dpx_dpy(1);
Calib.dpy=GeometryCalib.dpx_dpy(2);
Calib.sx=GeometryCalib.sx;
Calib.Cx=GeometryCalib.Cx_Cy(1);
Calib.Cy=GeometryCalib.Cx_Cy(2);
Calib.kappa1=GeometryCalib.kappa1;
Calib.f=GeometryCalib.focal;
Calib.Tx=GeometryCalib.Tx_Ty_Tz(1);
Calib.Ty=GeometryCalib.Tx_Ty_Tz(2);
Calib.Tz=GeometryCalib.Tx_Ty_Tz(3);
Calib.R=GeometryCalib.R;
X=Coord(:,1);
Y=Coord(:,2);
Z=Coord(:,3);
x_ima=Coord(:,4);
y_ima=Coord(:,5);
[Xpoints,Ypoints]=px_XYZ(Calib,X,Y,Z);

GeometryCalib.ErrorRms(1)=sqrt(mean((Xpoints-x_ima).*(Xpoints-x_ima)));
GeometryCalib.ErrorMax(1)=max(abs(Xpoints-x_ima));
GeometryCalib.ErrorRms(2)=sqrt(mean((Ypoints-y_ima).*(Ypoints-y_ima)));
GeometryCalib.ErrorMax(2)=max(abs(Ypoints-y_ima));

function GeometryCalib=calib_tsai(Coord)
%------------------------------------------------------------------------
%TSAI
% 'calibration_lin' provides a linear transform on coordinates, 
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
% if isunix
    %fid = fopen(fullfile(path_UVMAT,'PARAM_LINUX.txt'),'r');%open the file with civ binary names
xmlfile=fullfile(path_UVMAT,'PARAM.xml');
if exist(xmlfile,'file')
    t=xmltree(xmlfile);
    sparam=convert(t);
end
if ~isfield(sparam,'GeometryCalib_exe')
    msgbox_uvmat('ERROR',['calibration program <GeometryCalib_exe> undefined in parameter file ' xmlfile])
    return
end
Tsai_exe=sparam.GeometryCalib_exe;
if ~exist(Tsai_exe,'file')%the binary is defined in /bin, default setting
     Tsai_exe=fullfile(path_UVMAT,Tsai_exe);
end
if ~exist(Tsai_exe,'file')
    msgbox_uvmat('ERROR',['calibration program ' sparam.GeometryCalib_exe ' defined in PARAM.xml does not exist'])
    return
end

textcoord=num2str(Coord,4);
dlmwrite('t.txt',textcoord,'');  
% ['!' Tsai_exe ' -f1 0 -f2 t.txt']
    eval(['!' Tsai_exe ' -f t.txt > tsaicalib.log']);
if ~exist('calib.dat','file')
    msgbox_uvmat('ERROR','no output from calibration program Tsai_exe: possibly too few points')
end
calibdat=dlmread('calib.dat');
delete('calib.dat')
delete('t.txt')
GeometryCalib.CalibrationType='tsai';
GeometryCalib.focal=calibdat(10);
GeometryCalib.dpx_dpy=[calibdat(5) calibdat(6)];
GeometryCalib.Cx_Cy=[calibdat(7) calibdat(8)];
GeometryCalib.sx=calibdat(9);
GeometryCalib.kappa1=calibdat(11);
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=[calibdat(12) calibdat(13) calibdat(14)];
Rx_Ry_Rz=calibdat([15:17]);
sa = sin(Rx_Ry_Rz(1)) ; 
ca=cos(Rx_Ry_Rz(1));
sb=sin(Rx_Ry_Rz(2));
cb =cos(Rx_Ry_Rz(2));
sg =sin(Rx_Ry_Rz(3));
cg =cos(Rx_Ry_Rz(3)); 
r1 = cb * cg;
r2 = cg * sa * sb - ca * sg;
r3 = sa * sg + ca * cg * sb;
r4 = cb * sg;
r5 = sa * sb * sg + ca * cg;
r6 = ca * sb * sg - cg * sa;
r7 = -sb;
r8 = cb * sa;
r9 = ca * cb;
%EN DEDUIRE MATRICE R ??
GeometryCalib.R=[r1,r2,r3;r4,r5,r6;r7,r8,r9];
%erreur a caracteriser?
%check error
Calib.dpx=GeometryCalib.dpx_dpy(1);
Calib.dpy=GeometryCalib.dpx_dpy(2);
Calib.sx=GeometryCalib.sx;
Calib.Cx=GeometryCalib.Cx_Cy(1);
Calib.Cy=GeometryCalib.Cx_Cy(2);
Calib.kappa1=GeometryCalib.kappa1;
Calib.f=GeometryCalib.focal;
Calib.Tx=GeometryCalib.Tx_Ty_Tz(1);
Calib.Ty=GeometryCalib.Tx_Ty_Tz(2);
Calib.Tz=GeometryCalib.Tx_Ty_Tz(3);
Calib.R=GeometryCalib.R;
X=Coord(:,1);
Y=Coord(:,2);
Z=Coord(:,3);
x_ima=Coord(:,4);
y_ima=Coord(:,5);
[Xpoints,Ypoints]=px_XYZ(Calib,X,Y,Z);

GeometryCalib.ErrorRms(1)=sqrt(mean((Xpoints-x_ima).*(Xpoints-x_ima)));
GeometryCalib.ErrorMax(1)=max(abs(Xpoints-x_ima));
GeometryCalib.ErrorRms(2)=sqrt(mean((Ypoints-y_ima).*(Ypoints-y_ima)));
GeometryCalib.ErrorMax(2)=max(abs(Ypoints-y_ima));
% Nfx
% dx
% dy
% 5 dpx
% 6 dpy
% cx
% cy
% sx
% f
% kappa1
% tx
% ty
% tz
% rx
% ry
% rz
% p1
% p2

%calibcoeff=str2num(calibdat)


%------------------------------------------------------------------------
% --- Executes on button press in rotation.
function rotation_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
angle_rot=(pi/180)*str2num(get(handles.Phi,'String'));
Coord_cell=get(handles.ListCoord,'String');
data=read_geometry_calib(Coord_cell);
data.Coord(:,1)=cos(angle_rot)*data.Coord(:,1)+sin(angle_rot)*data.Coord(:,2);
data.Coord(:,1)=-sin(angle_rot)*data.Coord(:,1)+cos(angle_rot)*data.Coord(:,2);
set(handles.XObject,'String',num2str(data.Coord(:,1),4));
set(handles.YObject,'String',num2str(data.Coord(:,2),4));

%------------------------------------------------------------------------
function XImage_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_list(hObject, eventdata,handles)

%------------------------------------------------------------------------
function YImage_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_list(hObject, eventdata,handles)

function XObject_Callback(hObject, eventdata, handles)
update_list(hObject, eventdata,handles)

function YObject_Callback(hObject, eventdata, handles)
update_list(hObject, eventdata,handles)

function ZObject_Callback(hObject, eventdata, handles)
update_list(hObject, eventdata,handles)

%------------------------------------------------------------------------
function update_list(hObject, eventdata, handles)
%------------------------------------------------------------------------
str4=get(handles.XImage,'String');
str5=get(handles.YImage,'String');
str1=get(handles.XObject,'String');
tt=double(str1);
str2=get(handles.YObject,'String');
str3=get(handles.ZObject,'String');
if ~isempty(str1) & ~isequal(double(str1),32) & (isempty(str3)|isequal(double(str3),32))
    str3='0';%put z to 0 by default
end
strline=[str1 '    |    ' str2 '    |    ' str3 '    |    ' str4 '    |    ' str5];
Coord=get(handles.ListCoord,'String');
val=get(handles.ListCoord,'Value');
Coord{val}=strline;
set(handles.ListCoord,'String',Coord)
%update the plot 
ListCoord_Callback(hObject, eventdata, handles)
MenuPlot_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% --- Executes on selection change in ListCoord.
function ListCoord_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
Coord_cell=get(handles.ListCoord,'String');
val=get(handles.ListCoord,'Value');
if length(Coord_cell)>0
    coord_str=Coord_cell{val};
    k=findstr('|',coord_str);
    if isempty(k)
        return
    end
    set(handles.XObject,'String',coord_str(1:k(1)-5))
    set(handles.YObject,'String',coord_str(k(1)+5:k(2)-5))
    set(handles.ZObject,'String',coord_str(k(2)+5:k(3)-5))
    set(handles.XImage,'String',coord_str(k(3)+5:k(4)-5))
    set(handles.YImage,'String',coord_str(k(4)+5:end))
    huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
    hplot=findobj(huvmat,'Tag','axes3');%main plotting axis of uvmat
    h_menu_coord=findobj(huvmat,'Tag','menu_coord');
    menu=get(h_menu_coord,'String');
    choice=get(h_menu_coord,'Value');
    if iscell(menu)
        option=menu{choice};
    else
        option='px'; %default
    end
    if isequal(option,'phys')
        XCoord=str2num(coord_str(1:k(1)-5));
        YCoord=str2num(coord_str(k(1)+5:k(2)-5));
    elseif isequal(option,'px')|| isequal(option,'')
        XCoord=str2num(coord_str(k(3)+5:k(4)-5));
        YCoord=str2num(coord_str(k(4)+5:end));
    else
        msgbox_uvmat('ERROR','the choice in menu_coord of uvmat must be px or phys ')
    end
    huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
    hplot=findobj(huvmat,'Tag','axes3');%main plotting axis of uvmat
    hhh=findobj(hplot,'Tag','calib_marker');
    if isempty(hhh)
        axes(hplot)
        line(XCoord,YCoord,'Color','m','Tag','calib_marker','LineStyle','.','Marker','o','MarkerSize',20);
    else
        set(hhh,'XData',XCoord)
        set(hhh,'YData',YCoord)
    end
end

%------------------------------------------------------------------------
% --- Executes on selection change in edit_append.
function edit_append_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
choice=get(handles.edit_append,'Value');
if choice==1
       Coord=get(handles.ListCoord,'String'); 
       val=length(Coord);
       if val>=1 & isequal(Coord{val},'')
            val=val-1; %do not take into account blank
       end
       Coord{val+1}='';
       set(handles.ListCoord,'String',Coord)
       set(handles.ListCoord,'Value',val+1)
end


    
function NEW_Callback(hObject, eventdata, handles)
%A METTRE SOUS UN BOUTON
huvmat=findobj(allchild(0),'Name','uvmat');
hchild=get(huvmat,'children');
hcoord=findobj(hchild,'Tag','menu_coord');
coordtype=get(hcoord,'Value');
haxes=findobj(hchild,'Tag','axes3');
AxeData=get(haxes,'UserData');
if ~isequal(hcoord,2)
    set(hcoord,'Value',2)
    huvmat=uvmat(AxeData);
    'relancer uvmat';
end
if ~isfield(AxeData,'ZoomAxes')
    msgbox_uvmat('ERROR','first draw a window around a grid marker')
    return
end 
XLim=get(AxeData.ZoomAxes,'XLim');
YLim=get(AxeData.ZoomAxes,'YLim');
np=size(AxeData.A);
ind_sub_x=round(XLim);
ind_sub_y=np(1)-round(YLim);
Mfiltre=AxeData.A([ind_sub_y(2):ind_sub_y(1)] ,ind_sub_x,:);
Mfiltre_norm=double(Mfiltre);
Mfiltre_norm=Mfiltre_norm/sum(sum(Mfiltre_norm));
Mfiltre_norm=100*(Mfiltre_norm-mean(mean(Mfiltre_norm)));
Atype=class(AxeData.A);
Data.NbDim=2;
Data.A=filter2(Mfiltre_norm,double(AxeData.A)); 
Data.A=feval(Atype,Data.A);
Data.AName='image';
Data.AX=AxeData.AX;
Data.AY=AxeData.AY;
Data.CoordType='px';
plot_field(Data)
 

%------------------------------------------------------------------------
% --- 'key_press_fcn:' function activated when a key is pressed on the keyboard
function key_press_fcn(hObject,eventdata,handles)
%------------------------------------------------------------------------
hh=get(hObject,'parent');
xx=double(get(hh,'CurrentCharacter')); %get the keyboard character

if ismember(xx,[8 127])%backspace or delete
    Coord_cell=get(handles.ListCoord,'String');
    data=read_geometry_calib(Coord_cell);
    Coord=[]; %default
    if isfield(data,'Coord')
        Coord=data.Coord;
    end
    val=get(handles.ListCoord,'Value');
    Coord(val,:)=[];%suppress the selected item in the list
    CoordCell={};
    for iline=1:size(Coord,1)
        for j=1:5
            CoordCell{iline,j}=num2str(Coord(iline,j),4);
        end
    end
    Tabchar=cell2tab(CoordCell,'    |    ');%transform cells into table ready for display
    val=min(size(Coord,1),val);
    set(handles.ListCoord,'Value',max(val,1))
    set(handles.ListCoord,'String',Tabchar)  
    ListCoord_Callback(hObject, eventdata, handles)
    MenuPlot_Callback(hObject,eventdata,handles)
end

%------------------------------------------------------------------------
% --- Executes on button press in append_point.
function append_point_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
       Coord=get(handles.ListCoord,'String'); 
       val=length(Coord);
       if val>=1 & isequal(Coord{val},'')
            val=val-1; %do not take into account blank
       end
       Coord{val+1}='';
       set(handles.ListCoord,'String',Coord)
       set(handles.ListCoord,'Value',val+1)

%------------------------------------------------------------------------
function MenuOpen_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%get the object file 
huvmat=findobj(allchild(0),'Name','uvmat');
UvData=get(huvmat,'UserData');
hchild=get(huvmat,'Children');
hrootpath=findobj(hchild,'Tag','RootPath');
oldfile=get(hrootpath,'String');
if isempty(oldfile)
    oldfile='';
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
    msgbox_uvmat('ERROR','forbidden input file name or path: no blank character allowed')
    return
end
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
loadfile(handles,fileinput)


%------------------------------------------------------------------------
function MenuPlot_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
hhuvmat=guidata(huvmat); %handles of GUI elements in uvmat
hplot=findobj(huvmat,'Tag','axes3');%main plotting axis of uvmat
h_menu_coord=findobj(huvmat,'Tag','transform_fct');
menu=get(h_menu_coord,'String');
choice=get(h_menu_coord,'Value');
if iscell(menu)
    option=menu{choice};
else
    option='px'; %default
end
Coord_cell=get(handles.ListCoord,'String');
ObjectData=read_geometry_calib(Coord_cell);
%ObjectData=read_geometry_calib(handles);%read the interface input parameters defining the object
if isequal(option,'phys')
    ObjectData.Coord=ObjectData.Coord(:,[1:3]);
elseif isequal(option,'px')||isequal(option,'')
    ObjectData.Coord=ObjectData.Coord(:,[4:5]);
else
    msgbox_uvmat('ERROR','the choice in menu_coord of uvmat must be px or phys ')
end
axes(hhuvmat.axes3)
hh=findobj('Tag','calib_points');
if isempty(hh)
    hh=line(ObjectData.Coord(:,1),ObjectData.Coord(:,2),'Color','m','Tag','calib_points','LineStyle','.','Marker','+');
else
    set(hh,'XData',ObjectData.Coord(:,1))
    set(hh,'YData',ObjectData.Coord(:,2))
end
pause(.1)
figure(handles.geometry_calib)

% --------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
    helpfile=fullfile(pathelp,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
else
   addpath (fullfile(pathelp,'uvmat_doc'))
   web([helpfile '#geometry_calib'])
end

%------------------------------------------------------------------------
function MenuCreateGrid_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%hcalib=get(handles.calib_type,'parent');%handles of the GUI geometry_calib
CalibData=get(handles.geometry_calib,'UserData');
Tinput=[];%default
if isfield(CalibData,'grid')
    Tinput=CalibData.grid;
end
[T,CalibData.grid]=create_grid(grid_input);%display the GUI create_grid
set(handles.geometry_calib,'UserData',CalibData)

%grid in phys space
Coord_cell=get(handles.ListCoord,'String');
data=read_geometry_calib(Coord_cell);
nbpoints=size(data.Coord,1); %nbre of calibration points
data.Coord(1:size(T,1),1:3)=T;%update the existing list of phys coordinates from the GUI create_grid
for i=1:nbpoints
   for j=1:5
          Coord{i,j}=num2str(data.Coord(i,j),4);%display coordiantes with 4 digits
   end
end
for i=nbpoints+1:size(data.Coord,1)
    for j=1:3
          Coord{i,j}=num2str(data.Coord(i,j),4);%display coordiantes with 4 digits
    end
    for j=4:5
          Coord{i,j}='';%display coordiantes with 4 digi
    end
end


%size(data.Coord,1)
Tabchar=cell2tab(Coord,'    |    ');
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)

%-----------------------------------------------------------------------
function MenuTranslatePoints_Callback(hObject, eventdata, handles)
%-----------------------------------------------------------------------
%hcalib=get(handles.calib_type,'parent');%handles of the GUI geometry_calib
CalibData=get(handles.geometry_calib,'UserData');
Tinput=[];%default
if isfield(CalibData,'translate')
    Tinput=CalibData.translate;
end
T=translate_points(Tinput);%display translate_points GUI and get shift parameters 
CalibData.translate=T;
set(handles.geometry_calib,'UserData',CalibData)
%translation
Coord_cell=get(handles.ListCoord,'String');
data=read_geometry_calib(Coord_cell);
data.Coord(:,1)=T(1)+data.Coord(:,1);
data.Coord(:,2)=T(2)+data.Coord(:,2);
data.Coord(:,3)=T(3)+data.Coord(:,3);
data.Coord(:,[4 5])=data.Coord(:,[4 5]);
for i=1:size(data.Coord,1)
    for j=1:5
          Coord{i,j}=num2str(data.Coord(i,j),4);%phys x,y,z
   end
end
Tabchar=cell2tab(Coord,'    |    ');
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)


% --------------------------------------------------------------------
function MenuRotatePoints_Callback(hObject, eventdata, handles)
%hcalib=get(handles.calib_type,'parent');%handles of the GUI geometry_calib
CalibData=get(handles.geometry_calib,'UserData');
Tinput=[];%default
if isfield(CalibData,'rotate')
    Tinput=CalibData.rotate;
end
T=rotate_points(Tinput);%display translate_points GUI and get shift parameters 
CalibData.rotate=T;
set(handles.geometry_calib,'UserData',CalibData)
%-----------------------------------------------------
%rotation
Phi=T(1);
O_x=0;%default
O_y=0;%default
if numel(T)>=2
    O_x=T(2);%default
end
if numel(T)>=3
    O_y=T(3);%default
end
Coord_cell=get(handles.ListCoord,'String');
data=read_geometry_calib(Coord_cell);
r1=cos(pi*Phi/180);
r2=-sin(pi*Phi/180);
r3=sin(pi*Phi/180);
r4=cos(pi*Phi/180);
x=data.Coord(:,1)-O_x;
y=data.Coord(:,2)-O_y;
data.Coord(:,1)=r1*x+r2*y;
data.Coord(:,2)=r3*x+r4*y;
% data.Coord(:,[4 5])=data.Coord(:,[4 5]);
for i=1:size(data.Coord,1)
    for j=1:5
          Coord{i,j}=num2str(data.Coord(i,j),4);%phys x,y,z
   end
end
Tabchar=cell2tab(Coord,'    |    ');
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)
% --------------------------------------------------------------------
function MenuDetectGrid_Callback(hObject, eventdata, handles)

CalibData=get(handles.geometry_calib,'UserData');
grid_input=[];%default
if isfield(CalibData,'grid')
    grid_input=CalibData.grid;%retrieve the previously used grid
end
[T,CalibData.grid]=create_grid(grid_input);%display the GUI create_grid 
set(handles.geometry_calib,'UserData',CalibData)%store the phys grid for later use

%read the four last point coordiantes in pixels
Coord_cell=get(handles.ListCoord,'String');%read list of coordiantes on geometry_calib
data=read_geometry_calib(Coord_cell);
nbpoints=size(data.Coord,1); %nbre of calibration points
if nbpoints~=4
    msgbox_uvmat('ERROR','four points must be selected by the mouse, beginning by the new x axis, to delimitate the phs grid area')
end
corners_X=(data.Coord(end-3:end,4)); %pixel absissa of the four corners
corners_Y=(data.Coord(end-3:end,5)); 

%reorder the last two points if needed
angles=angle((corners_X-corners_X(1))+i*(corners_Y-corners_Y(1)));
if abs(angles(4)-angles(2))>abs(angles(3)-angles(2))
      X_end=corners_X(4);
      Y_end=corners_Y(4);
      corners_X(4)=corners_X(3);
      corners_Y(4)=corners_Y(3);
      corners_X(3)=X_end;
      corners_Y(3)=Y_end;
end

%read the current image
huvmat=findobj(allchild(0),'Name','uvmat');
UvData=get(huvmat,'UserData');
A=UvData.Field.A;
npxy=size(A);
%linear transform on the current image
X=[CalibData.grid.x_0 CalibData.grid.x_1 CalibData.grid.x_0 CalibData.grid.x_1]';%corner absissa in the rectified image
Y=[CalibData.grid.y_0 CalibData.grid.y_0 CalibData.grid.y_1 CalibData.grid.y_1]';%corner absissa in the rectified image
XY_mat=[ones(size(X)) X Y];
a_X1=XY_mat\corners_X; %transformation matrix for X
x1=XY_mat*a_X1;%reconstruction
err_X1=max(abs(x1-corners_X))%error
a_Y1=XY_mat\corners_Y;%transformation matrix for X
y1=XY_mat*a_Y1;
err_Y1=max(abs(y1-corners_Y))%error
GeometryCalib.CalibrationType='linear';
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.f=1;
GeometryCalib.dpx=1;
GeometryCalib.dpy=1;
GeometryCalib.sx=1;
GeometryCalib.Cx=0;
GeometryCalib.Cy=0;
GeometryCalib.kappa1=0;
GeometryCalib.Tx=a_X1(1);
GeometryCalib.Ty=a_Y1(1);
GeometryCalib.Tz=1;
GeometryCalib.R=[a_X1(2),a_X1(3),0;a_Y1(2),a_Y1(3),0;0,0,1];
[Amod,Rangx,Rangy]=phys_Ima(A-min(min(A)),GeometryCalib,0);
Amod=double(Amod);
%figure(12)
%Amax=max(max(Amod))
%image(Rangx,Rangy,uint8(255*Amod/Amax))
ind_range=10;% range of search of image ma around each point obtained by linear interpolation from the marked points
nbpoints=size(T,1);
for ipoint=1:nbpoints
    Dx=(Rangx(2)-Rangx(1))/(npxy(2)-1); %x mesh in real space
    Dy=(Rangy(2)-Rangy(1))/(npxy(1)-1); %y mesh in real space
    i0=1+round((T(ipoint,1)-Rangx(1))/Dx);%round(Xpx(ipoint));
    j0=1+round((T(ipoint,2)-Rangy(1))/Dy);%round(Xpx(ipoint));
    Asub=Amod(j0-ind_range:j0+ind_range,i0-ind_range:i0+ind_range);
    x_profile=sum(Asub,1);
    y_profile=sum(Asub,2);
    [Amax,ind_x_max]=max(x_profile);
    [Amax,ind_y_max]=max(y_profile);
    %sub-pixel improvement using moments
    x_shift=0;
    y_shift=0;
    if ind_x_max+2<=2*ind_range+1 && ind_x_max-2>=1
        Atop=x_profile(ind_x_max-2:ind_x_max+2);
        x_shift=sum(Atop.*[-2 -1 0 1 2])/sum(Atop);
    end
    if ind_y_max+2<=2*ind_range+1 && ind_y_max-2>=1
        Atop=y_profile(ind_y_max-2:ind_y_max+2);
        y_shift=sum(Atop.*[-2 -1 0 1 2]')/sum(Atop);
    end
    Delta(ipoint,1)=(x_shift+ind_x_max-ind_range-1)*Dx;%shift from the initial guess
    Delta(ipoint,2)=(y_shift+ind_y_max-ind_range-1)*Dy;
end
Tmod=T(:,(1:2))+Delta;
[Xpx,Ypx]=px_XYZ(GeometryCalib,Tmod(:,1),Tmod(:,2));
for ipoint=1:nbpoints
     Coord{ipoint,1}=num2str(T(ipoint,1),4);%display coordiantes with 4 digits
     Coord{ipoint,2}=num2str(T(ipoint,2),4);%display coordiantes with 4 digits
     Coord{ipoint,3}='0';
     Coord{ipoint,4}=num2str(Xpx(ipoint),4);%display coordiantes with 4 digi
     Coord{ipoint,5}=num2str(Ypx(ipoint),4);%display coordiantes with 4 digi
end
Tabchar=cell2tab(Coord,'    |    ');
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)
MenuPlot_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%
function [A_out,Rangx,Rangy]=phys_Ima(A,Calib,ZIndex)
xcorner=[];
ycorner=[];
npx=[];
npy=[];
siz=size(A);
npx=[npx siz(2)];
npy=[npy siz(1)];
xima=[0.5 siz(2)-0.5 0.5 siz(2)-0.5];%image coordiantes of corners
yima=[0.5 0.5 siz(1)-0.5 siz(1)-0.5];
[xcorner,ycorner]=phys_XYZ(Calib,xima,yima,ZIndex);%corresponding physical coordinates
Rangx(1)=min(xcorner);
Rangx(2)=max(xcorner);
Rangy(2)=min(ycorner);
Rangy(1)=max(ycorner);
test_multi=(max(npx)~=min(npx)) | (max(npy)~=min(npy)); 
npx=max(npx);
npy=max(npy);
x=linspace(Rangx(1),Rangx(2),npx);
y=linspace(Rangy(1),Rangy(2),npy);
[X,Y]=meshgrid(x,y);%grid in physical coordiantes
vec_B=[];

zphys=0; %default
if isfield(Calib,'SliceCoord') %.Z= index of plane
   SliceCoord=Calib.SliceCoord(ZIndex,:);
   zphys=SliceCoord(3); %to generalize for non-parallel planes
end
[XIMA,YIMA]=px_XYZ(Calib,X,Y,zphys);%corresponding image indices for each point in the real space grid
XIMA=reshape(round(XIMA),1,npx*npy);%indices reorganized in 'line'
YIMA=reshape(round(YIMA),1,npx*npy);
flagin=XIMA>=1 & XIMA<=npx & YIMA >=1 & YIMA<=npy;%flagin=1 inside the original image
testuint8=isa(A,'uint8');
testuint16=isa(A,'uint16');
if numel(siz)==2 %(B/W images)
    vec_A=reshape(A,1,npx*npy);%put the original image in line
    ind_in=find(flagin);
    ind_out=find(~flagin);
    ICOMB=((XIMA-1)*npy+(npy+1-YIMA));
    ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
    vec_B(ind_in)=vec_A(ICOMB);
    vec_B(ind_out)=zeros(size(ind_out));
    A_out=reshape(vec_B,npy,npx);%new image in real coordinates
elseif numel(siz)==3     
    for icolor=1:siz(3)
        vec_A=reshape(A{icell}(:,:,icolor),1,npx*npy);%put the original image in line
        ind_in=find(flagin);
        ind_out=find(~flagin);
        ICOMB=((XIMA-1)*npy+(npy+1-YIMA));
        ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
        vec_B(ind_in)=vec_A(ICOMB);
        vec_B(ind_out)=zeros(size(ind_out));
        A_out(:,:,icolor)=reshape(vec_B,npy,npx);%new image in real coordinates
    end
end
if testuint8
    A_out=uint8(A_out);
end
if testuint16
    A_out=uint16(A_out);
end

%INPUT:
%Z: index of plane
function [Xphys,Yphys,Zphys]=phys_XYZ(Calib,X,Y,Z)
if exist('Z','var')& isequal(Z,round(Z))& Z>0 & isfield(Calib,'SliceCoord')&length(Calib.SliceCoord)>=Z
    Zindex=Z;
    Zphys=Calib.SliceCoord(Zindex,3);%GENERALISER AUX CAS AVEC ANGLE
else
%     if exist('Z','var')
%         Zphys=Z;
%     else
        Zphys=0;
%     end
end
if ~exist('X','var')||~exist('Y','var')
    Xphys=[];
    Yphys=[];%default
    return
end
Xphys=X;%default
Yphys=Y;
%image transform
if isfield(Calib,'R')
    R=(Calib.R)';
    Dx=R(5)*R(7)-R(4)*R(8);
    Dy=R(1)*R(8)-R(2)*R(7);
    D0=Calib.f*(R(2)*R(4)-R(1)*R(5));
    Z11=R(6)*R(8)-R(5)*R(9);
    Z12=R(2)*R(9)-R(3)*R(8);  
    Z21=R(4)*R(9)-R(6)*R(7);
    Z22=R(3)*R(7)-R(1)*R(9);
    Zx0=R(3)*R(5)-R(2)*R(6);
    Zy0=R(1)*R(6)-R(3)*R(4);
    A11=R(8)*Calib.Ty-R(5)*Calib.Tz+Z11*Zphys;
    A12=R(2)*Calib.Tz-R(8)*Calib.Tx+Z12*Zphys;
    A21=-R(7)*Calib.Ty+R(4)*Calib.Tz+Z21*Zphys;
    A22=-R(1)*Calib.Tz+R(7)*Calib.Tx+Z11*Zphys;
    X0=Calib.f*(R(5)*Calib.Tx-R(2)*Calib.Ty+Zx0*Zphys);
    Y0=Calib.f*(-R(4)*Calib.Tx+R(1)*Calib.Ty+Zy0*Zphys);
        %px to camera:
    Xd=(Calib.dpx/Calib.sx)*(X-Calib.Cx); % sensor coordinates
    Yd=Calib.dpy*(Y-Calib.Cy);
    dist_fact=1+Calib.kappa1*(Xd.*Xd+Yd.*Yd); %distortion factor
    Xu=dist_fact.*Xd;%undistorted sensor coordinates
    Yu=dist_fact.*Yd;
    denom=Dx*Xu+Dy*Yu+D0;
    % denom2=denom.*denom;
    Xphys=(A11.*Xu+A12.*Yu+X0)./denom;%world coordinates
    Yphys=(A21.*Xu+A22.*Yu+Y0)./denom;
end
