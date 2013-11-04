%'geometry_calib': associated to the GUI geometry_calib to perform geometric calibration from a set of reference points
%------------------------------------------------------------------------
% function hgeometry_calib = geometry_calib(inputfile,pos)
%
%OUTPUT: 
% hgeometry_calib=current handles of the GUI geometry_calib.fig
%
%INPUT:
% inputfile: (optional) name of an xml file containing coordinates of reference points
% pos: (optional) 4 element vector setting the 'Position' of the GUI 
%
%A%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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

% Last Modified by GUIDE v2.5 29-Oct-2013 06:46:10

% Begin initialization code - DO NOT edit
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @geometry_calib_OpeningFcn, ...
                   'gui_OutputFcn',  @geometry_calib_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin
   [pp,ff]=fileparts(which(varargin{1})); % name of the input file
   if strcmp(ff,mfilename)% if we are activating a sub-function of geometry_calib
   % ~isempty(regexp(varargin{1},'_Callback','once'))
    gui_State.gui_Callback = str2func(varargin{1});
   end
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
function geometry_calib_OpeningFcn(hObject, eventdata, handles,inputfile)
%------------------------------------------------------------------------
% Choose default command line output for geometry_calib

handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(hObject,'DeleteFcn',{@closefcn})%
%set(hObject,'WindowButtonDownFcn',{'mouse_alt_gui',handles}) % allows mouse action with right button (zoom for uicontrol display)

%% position
set(0,'Unit','pixels')
ScreenSize=get(0,'ScreenSize');% get the size of the screen, to put the fig on the upper right
Left=ScreenSize(3)- 460; %right edge close to the right, with margin=40 (GUI width=420 px)
if ScreenSize(4)>920
    Height=840;%default height of the GUI
    Bottom=ScreenSize(4)-Height-40; %put fig at top right
else
    Height=ScreenSize(4)-80;
    Bottom=40; % GUI lies o the screen bottom (with margin =40)
end
set(handles.calib_type,'Position',[1 Height-40 194 30])%  rank 1
set(handles.APPLY,'Position',[197 Height-40 110 30])%  rank 1
set(handles.REPLICATE,'Position',[309 Height-40 110 30])%  rank 1
set(handles.Intrinsic,'Position',[1 Height-40-2-92 418 92])%  rank 2
set(handles.Extrinsic,'Position',[1 Height-40-4-92-75 418 75])%  rank 3
set(handles.PointLists,'Position',[1 Height-40-6-92-75-117 418 117]) %  rank 4
set(handles.CheckEnableMouse,'Position',[3 Height-40-8-92-75-117-30 203 30])%  rank 5
set(handles.PLOT,'Position',[3 Height-394 120 30])%  rank 6
set(handles.Copy,'Position',[151 Height-394 120 30])%  rank 6
set(handles.CLEAR_PTS,'Position',[297 Height-394 120 30])%  rank 6
set(handles.ClearLine,'Position',[297 Height-364 120 30])%  rank 6
set(handles.phys_title,'Position',[38 Height-426 125 20])%  rank 7
set(handles.CoordUnit,'Position',[151 Height-426 120 30])%  rank 7
set(handles.px_title,'Position',[272 Height-426 125 20])%  rank 7
set(handles.ListCoord,'Position',[1 20 418 Height-446])% rank 8
set(handles.geometry_calib,'Position',[Left Bottom 420 Height])

%set menu of calibration options
set(handles.calib_type,'String',{'rescale';'linear';'3D_linear';'3D_quadr';'3D_extrinsic'})
if exist('inputfile','var')&& ~isempty(inputfile)
    struct.XmlInputFile=inputfile;
    [RootPath,SubDir,RootFile,tild,tild,tild,tild,FileExt]=fileparts_uvmat(inputfile);
    if ~strcmp(FileExt,'.xml')
        inputfile=fullfile(RootPath,[SubDir '.xml']);%xml file corresponding to the input file
        if ~exist(inputfile,'file')% case of civ files , removes the extension for subdir
            inputfile=fullfile(RootPath,[regexprep(SubDir,'\..+$','') '.xml']);
            if ~exist(inputfile,'file')
                inputfile=[fullfile(RootPath,SubDir,RootFile) '.xml'];%old convention
                if ~exist(inputfile,'file')
                    inputfile='';
                end
            end
        end
    end
    set(handles.ListCoord,'Data',[])
    if exist(inputfile,'file')
        Heading=loadfile(handles,inputfile);% load data from the xml file
        if isfield(Heading,'Campaign')&& ischar(Heading.Campaign)
            struct.Campaign=Heading.Campaign;
        end
    end   
    set(hObject,'UserData',struct)
end

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = geometry_calib_OutputFcn(~, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;
% 
%------------------------------------------------------------------------
% executed when closing: set the parent interface button to value 0
function closefcn(gcbo,eventdata)
%------------------------------------------------------------------------
huvmat=findobj(allchild(0),'Name','uvmat');
if ~isempty(huvmat)
    handles=guidata(huvmat);
    set(handles.MenuCalib,'Checked','off')
    hobject=findobj(handles.PlotAxes,'tag','calib_points');
    if ~isempty(hobject)
        delete(hobject)
    end
    hobject=findobj(handles.PlotAxes,'tag','calib_marker');
    if ~isempty(hobject)
        delete(hobject)
    end    
end

%------------------------------------------------------------------------
% --- Executes on button press APPLY (used to launch the calibration).
function APPLY_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%% look for the GUI uvmat and check for an image as input
set(handles.APPLY,'BackgroundColor',[1 1 0])
huvmat=findobj(allchild(0),'Name','uvmat');
hhuvmat=guidata(huvmat);%handles of elements in the GUI uvmat

RootPath='';
if ~isempty(hhuvmat.RootPath)&& ~isempty(hhuvmat.RootFile)
    RootPath=get(hhuvmat.RootPath,'String');
    SubDirBase=regexprep(get(hhuvmat.SubDir,'String'),'\..+$','');
    outputfile=[fullfile(RootPath,SubDirBase) '.xml'];%xml file associated with the currently displayed image
else
    question={'save the calibration data and point coordinates in'};
    def={fullfile(RootPath,'ObjectCalib.xml')};
    options.Resize='on';
    answer=inputdlg(question,'',1,def,options);
    outputfile=answer{1};
end
[GeometryCalib,index]=calibrate(handles,hhuvmat);% apply calibration

if isempty(GeometryCalib) % if calibration cancelled
    set(handles.APPLY,'BackgroundColor',[1 0 1])
else   % if calibration confirmed
    
    %% copy the xml file from the old location if appropriate, then update with the calibration parameters
    if ~exist(outputfile,'file') && ~isempty(SubDirBase)
        oldxml=[fullfile(RootPath,SubDirBase,get(hhuvmat.RootFile,'String')) '.xml'];
        if exist(oldxml,'file')
            [success,message]=copyfile(oldxml,outputfile);%copy the old xml file to a new one with the new convention
        end
    end
    errormsg=update_imadoc(GeometryCalib,outputfile,'GeometryCalib');% introduce the calibration data in the xml file
    if ~strcmp(errormsg,'')
        msgbox_uvmat('ERROR',errormsg);
    end
    
    %% display image with new calibration in the currently opened uvmat interface
    hhh=findobj(hhuvmat.PlotAxes,'Tag','calib_marker');% delete calib points and markers
    if ~isempty(hhh)
        delete(hhh);
    end
    hhh=findobj(hhuvmat.PlotAxes,'Tag','calib_points');
    if ~isempty(hhh)
        delete(hhh);
    end
    set(hhuvmat.CheckFixLimits,'Value',0)% put FixedLimits option to 'off'
    set(hhuvmat.CheckFixLimits,'BackgroundColor',[0.7 0.7 0.7])
    UserData=get(handles.geometry_calib,'UserData');
    UserData.XmlInputFile=outputfile;%save the current xml file name
    set(handles.geometry_calib,'UserData',UserData)
    uvmat('RootPath_Callback',hObject,eventdata,hhuvmat); %file input with xml reading  in uvmat, show the image in phys coordinates
    PLOT_Callback(hObject, eventdata, handles)
    Data=get(handles.ListCoord,'Data');
    Data(:,6)=zeros(size(Data,1),1);
    Data(index,6)=-1;% indicate in the list the point with max deviation (possible mistake)
    set(handles.ListCoord,'Data',Data)% indicate in the list the point with max deviation (possible mistake)
    figure(handles.geometry_calib)
    set(handles.APPLY,'BackgroundColor',[1 0 0])
end

%------------------------------------------------------------------------
% --- Executes on button press in REPLICATE
function REPLICATE_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%% look for the GUI uvmat and check for an image as input
huvmat=findobj(allchild(0),'Name','uvmat');
hhuvmat=guidata(huvmat);%handles of elements in the GUI uvmat
GeometryCalib=calibrate(handles,hhuvmat);% apply calibration

%% open the GUI browse_data
CalibData=get(handles.geometry_calib,'UserData');%read the calibration image source on the interface userdata
if isfield(CalibData,'XmlInputFile')
    InputDir=fileparts(fileparts(CalibData.XmlInputFile));
end
answer=msgbox_uvmat('INPUT_TXT','Campaign to calibrate?',InputDir); 
if strcmp(answer,'Cancel')
    return
end
OutPut=browse_data(answer);
nbcalib=0;
for ilist=1:numel(OutPut.Experiment)
    SubDirBase=regexprep(OutPut.Device{1},'\..+$','');
    XmlName=fullfile(OutPut.Campaign,OutPut.Experiment{ilist},[SubDirBase '.xml']);
    % copy the xml file from the old location if appropriate, then update with the calibration parameters
    if ~exist(XmlName,'file') && ~isempty(SubDirBase)
        oldxml=fullfile(OutPut.Campaign,OutPut.Experiment{ilist},SubDirBase,[get(hhuvmat.RootFile,'String') '.xml']);
        if exist(oldxml,'file')
            [success,message]=copyfile(oldxml,XmlName);%copy the old xml file to a new one with the new convention
        end
    end
    errormsg=update_imadoc(GeometryCalib,XmlName,'GeometryCalib');% introduce the calibration data in the xml file
    if ~strcmp(errormsg,'')
        msgbox_uvmat('ERROR',errormsg);
    else
        display([XmlName ' updated with calibration parameters'])
        nbcalib=nbcalib+1;
    end
end
msgbox_uvmat('CONFIMATION',[SubDirBase ' calibrated for ' num2str(nbcalib) ' experiments']);

%------------------------------------------------------------------------
% --- activate calibration and store parameters in ouputfile .
function [GeometryCalib,index]=calibrate(handles,hhuvmat)
%------------------------------------------------------------------------
%% read the current calibration points
Coord=get(handles.ListCoord,'Data');
Coord(:,6)=[];
% apply the calibration, whose type is selected in  handles.calib_type
if ~isempty(Coord)
    calib_cell=get(handles.calib_type,'String');
    val=get(handles.calib_type,'Value');
    GeometryCalib=feval(['calib_' calib_cell{val}],Coord,handles);
else
    msgbox_uvmat('ERROR','No calibration points, abort')
    return
end 
Z_plane=[];
if ~isempty(Coord)
    %check error
    X=Coord(:,1);
    Y=Coord(:,2);
    Z=Coord(:,3);
    x_ima=Coord(:,4);
    y_ima=Coord(:,5);
    [Xpoints,Ypoints]=px_XYZ(GeometryCalib,X,Y,Z);
    GeometryCalib.ErrorRms(1)=sqrt(mean((Xpoints-x_ima).*(Xpoints-x_ima)));
    [GeometryCalib.ErrorMax(1),index(1)]=max(abs(Xpoints-x_ima));
    GeometryCalib.ErrorRms(2)=sqrt(mean((Ypoints-y_ima).*(Ypoints-y_ima)));
    [GeometryCalib.ErrorMax(2),index(2)]=max(abs(Ypoints-y_ima));
    [tild,ind_dim]=max(GeometryCalib.ErrorMax);
    index=index(ind_dim);
    %set the Z position of the reference plane used for calibration
    if isequal(max(Z),min(Z))%Z constant
        Z_plane=Z(1);
        GeometryCalib.NbSlice=1;
        GeometryCalib.SliceCoord=[0 0 Z_plane];
    end
end
%set the coordinate unit
unitlist=get(handles.CoordUnit,'String');
unit=unitlist{get(handles.CoordUnit,'value')};
GeometryCalib.CoordUnit=unit;
%record the points
GeometryCalib.SourceCalib.PointCoord=Coord;
display_intrinsic(GeometryCalib,handles)%display calibration intrinsic parameters

% Display extrinsinc parameters (rotation and translation of camera with  respect to the phys coordiantes)
set(handles.Tx,'String',num2str(GeometryCalib.Tx_Ty_Tz(1),4))
set(handles.Ty,'String',num2str(GeometryCalib.Tx_Ty_Tz(2),4))
set(handles.Tz,'String',num2str(GeometryCalib.Tx_Ty_Tz(3),4))
set(handles.Phi,'String',num2str(GeometryCalib.omc(1),4))
set(handles.Theta,'String',num2str(GeometryCalib.omc(2),4))
set(handles.Psi,'String',num2str(GeometryCalib.omc(3),4))

%% store the calibration data, by default in the xml file of the currently displayed image
UvData=get(hhuvmat.uvmat,'UserData');
NbSlice_j=1;%default
ZStart=Z_plane;
ZEnd=Z_plane;
volume_scan='n';
if isfield(UvData,'XmlData')
    if isfield(UvData.XmlData,'TranslationMotor')
        NbSlice_j=UvData.XmlData.TranslationMotor.Nbslice;
        ZStart=UvData.XmlData.TranslationMotor.ZStart/10;
        ZEnd=UvData.XmlData.TranslationMotor.ZEnd/10;
        volume_scan='y';
    end
end

answer=msgbox_uvmat('INPUT_Y-N',{'store calibration data';...
    ['Error rms (along x,y)=' num2str(GeometryCalib.ErrorRms) ' pixels'];...
    ['Error max (along x,y)=' num2str(GeometryCalib.ErrorMax) ' pixels']});

%% get plane position(s)
if ~strcmp(answer,'Yes')
    GeometryCalib=[];
    index=1;
    return
end
if strcmp(calib_cell{val}(1:2),'3D')%set the plane position for 3D (projection) calibration
    input_key={'Z (first position)','Z (last position)','Z (water surface)', 'refractive index','NbSlice','volume scan (y/n)','tilt angle y axis','tilt angle x axis'};
    input_val=[{num2str(ZEnd)} {num2str(ZStart)} {num2str(ZStart)} {'1.333'} num2str(NbSlice_j) {volume_scan} {'0'} {'0'}];
    answer=inputdlg(input_key,'slice position(s)',ones(1,8), input_val,'on');
    GeometryCalib.NbSlice=str2double(answer{5});
    GeometryCalib.VolumeScan=answer{6};
    if isempty(answer)
        Z_plane=0; %default
    else
        Z_plane=linspace(str2double(answer{1}),str2double(answer{2}),GeometryCalib.NbSlice);
    end
    GeometryCalib.SliceCoord=Z_plane'*[0 0 1];
    GeometryCalib.SliceAngle(:,3)=0;
    GeometryCalib.SliceAngle(:,2)=str2double(answer{7})*ones(GeometryCalib.NbSlice,1);%rotation around y axis (to generalise)
    GeometryCalib.SliceAngle(:,1)=str2double(answer{8})*ones(GeometryCalib.NbSlice,1);%rotation around x axis (to generalise)
    GeometryCalib.InterfaceCoord=[0 0 str2double(answer{3})];
    GeometryCalib.RefractionIndex=str2double(answer{4});
end



%------------------------------------------------------------------------
% determine the parameters for a calibration by an affine function (rescaling and offset, no rotation)
function GeometryCalib=calib_rescale(Coord,handles)
%------------------------------------------------------------------------
X=Coord(:,1);
Y=Coord(:,2);% Z not used
x_ima=Coord(:,4);
y_ima=Coord(:,5);
[px]=polyfit(X,x_ima,1);
[py]=polyfit(Y,y_ima,1);
% T_x=px(2);
% T_y=py(2);
GeometryCalib.CalibrationType='rescale';
GeometryCalib.fx_fy=[px(1) py(1)];%.fx_fy corresponds to pxcm along x and y
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=[px(2)/px(1) py(2)/py(1) 1];
GeometryCalib.omc=[0 0 0];

%------------------------------------------------------------------------
% determine the parameters for a calibration by a linear transform matrix (rescale and rotation)


function GeometryCalib=calib_linear(Coord,handles) 
%------------------------------------------------------------------------
X=Coord(:,1);
Y=Coord(:,2);% Z not used
x_ima=Coord(:,4);
y_ima=Coord(:,5);
XY_mat=[ones(size(X)) X Y];
a_X1=XY_mat\x_ima; %transformation matrix for X
a_Y1=XY_mat\y_ima;%transformation matrix for X
R=[a_X1(2),a_X1(3);a_Y1(2),a_Y1(3)];
epsilon=sign(det(R));
norm=abs(det(R));
GeometryCalib.CalibrationType='linear';
if (a_X1(2)/a_Y1(3))>0
    GeometryCalib.fx_fy(1)=sqrt((a_X1(2)/a_Y1(3))*norm);
else
    GeometryCalib.fx_fy(1)=-sqrt(-(a_X1(2)/a_Y1(3))*norm);
end
GeometryCalib.fx_fy(2)=(a_Y1(3)/a_X1(2))*GeometryCalib.fx_fy(1);
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=[a_X1(1)/GeometryCalib.fx_fy(1) a_Y1(1)/GeometryCalib.fx_fy(2) 1];
R(1,:)=R(1,:)/GeometryCalib.fx_fy(1);
R(2,:)=R(2,:)/GeometryCalib.fx_fy(2);
R=[R;[0 0]];
GeometryCalib.R=[R [0;0;-epsilon]];
GeometryCalib.omc=(180/pi)*[acos(GeometryCalib.R(1,1)) 0 0];

%------------------------------------------------------------------------
% determine the tsai parameters for a view normal to the grid plane
% NOT USED
function GeometryCalib=calib_normal(Coord,handles)
%------------------------------------------------------------------------
Calib.f1=str2num(get(handles.fx,'String'));
Calib.f2=str2num(get(handles.fy,'String'));
Calib.k=str2num(get(handles.kc,'String'));
Calib.Cx=str2num(get(handles.Cx,'String'));
Calib.Cy=str2num(get(handles.Cy,'String'));
%default
if isempty(Calib.f1)
    Calib.f1=25/0.012;
end
if isempty(Calib.f2)
    Calib.f2=25/0.012;
end
if isempty(Calib.k)
    Calib.k=0;
end
if isempty(Calib.Cx)||isempty(Calib.Cy)
    huvmat=findobj(allchild(0),'Tag','uvmat');
    hhuvmat=guidata(huvmat);
    Calib.Cx=str2num(get(hhuvmat.num_Npx,'String'))/2;
    Calib.Cx=str2num(get(hhuvmat.num_Npy,'String'))/2;
end   
%tsai parameters
Calib.dpx=0.012;%arbitrary
Calib.dpy=0.012;
Calib.sx=Calib.f1*Calib.dpx/(Calib.f2*Calib.dpy);
Calib.f=Calib.f2*Calib.dpy;
Calib.kappa1=Calib.k/(Calib.f*Calib.f);

%initial guess
X=Coord(:,1);
Y=Coord(:,2);
Zmean=mean(Coord(:,3));
x_ima=Coord(:,4)-Calib.Cx;
y_ima=Coord(:,5)-Calib.Cy;
XY_mat=[ones(size(X)) X Y];
a_X1=XY_mat\x_ima; %transformation matrix for X
a_Y1=XY_mat\y_ima;%transformation matrix for Y
R=[a_X1(2),a_X1(3),0;a_Y1(2),a_Y1(3),0;0,0,-1];% rotation+ z axis reversal (upward)
norm=sqrt(det(-R));
calib_param(1)=0;% quadratic distortion
calib_param(2)=a_X1(1);
calib_param(3)=a_Y1(1);
calib_param(4)=Calib.f/(norm*Calib.dpx)-R(3,3)*Zmean;
calib_param(5)=angle(a_X1(2)+1i*a_X1(3));
display(['initial guess=' num2str(calib_param)])

%optimise the parameters: minimisation of error
calib_param = fminsearch(@(calib_param) error_calib(calib_param,Calib,Coord),calib_param);

GeometryCalib.CalibrationType='tsai_normal';
GeometryCalib.focal=Calib.f;
GeometryCalib.dpx_dpy=[Calib.dpx Calib.dpy];
GeometryCalib.Cx_Cy=[Calib.Cx Calib.Cy];
GeometryCalib.sx=Calib.sx;
GeometryCalib.kappa1=calib_param(1);
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=[calib_param(2) calib_param(3) calib_param(4)]; 
alpha=calib_param(5);
GeometryCalib.R=[cos(alpha) sin(alpha) 0;-sin(alpha) cos(alpha) 0;0 0 -1];

%------------------------------------------------------------------------
function GeometryCalib=calib_3D_linear(Coord,handles)
%------------------------------------------------------------------
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
huvmat=findobj(allchild(0),'Tag','uvmat');
hhuvmat=guidata(huvmat);
coord_files=get(handles.ListCoordFiles,'String');
if ischar(coord_files)
    coord_files={coord_files};
end
if isempty(coord_files{1}) || isequal(coord_files,{''})
    coord_files={};
end
%retrieve the calibration points stored in the files listed in the popup list ListCoordFiles
x_1=Coord(:,4:5)';%px coordinates of the ref points
nx=str2num(get(hhuvmat.num_Npx,'String'));
ny=str2num(get(hhuvmat.num_Npy,'String'));
x_1(2,:)=ny-x_1(2,:);%reverse the y image coordinates
X_1=Coord(:,1:3)';%phys coordinates of the ref points
n_ima=numel(coord_files)+1;
if ~isempty(coord_files) 
    msgbox_uvmat('CONFIRMATION',['The xy coordinates of the calibration points in ' num2str(n_ima) ' planes will be used'])
    for ifile=1:numel(coord_files)
    t=xmltree(coord_files{ifile});
    s=convert(t);%convert to matlab structure
        if isfield(s,'GeometryCalib')
            if isfield(s.GeometryCalib,'SourceCalib')
                if isfield(s.GeometryCalib.SourceCalib,'PointCoord')
                PointCoord=s.GeometryCalib.SourceCalib.PointCoord;
                Coord_file=zeros(length(PointCoord),5);%default
                for i=1:length(PointCoord)
                    line=str2num(PointCoord{i});
                    Coord_file(i,4:5)=line(4:5);%px x
                    Coord_file(i,1:3)=line(1:3);%phys x
                end
                eval(['x_' num2str(ifile+1) '=Coord_file(:,4:5)'';']);
                eval(['x_' num2str(ifile+1) '(2,:)=ny-x_' num2str(ifile+1) '(2,:);' ]);
                eval(['X_' num2str(ifile+1) '=Coord_file(:,1:3)'';']);
                end
            end
        end
    end
end
n_ima=numel(coord_files)+1;
est_dist=[0;0;0;0;0];
est_aspect_ratio=0;
est_fc=[1;1];
center_optim=0;
run(fullfile(path_UVMAT,'toolbox_calib','go_calib_optim'));% apply fct 'toolbox_calib/go_calib_optim'
GeometryCalib.CalibrationType='3D_linear';
GeometryCalib.fx_fy=fc';
GeometryCalib.Cx_Cy=cc';
GeometryCalib.kc=kc(1);
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=Tc_1';
GeometryCalib.R=Rc_1;
GeometryCalib.R(2,1:3)=-GeometryCalib.R(2,1:3);%inversion of the y image coordinate
GeometryCalib.Tx_Ty_Tz(2)=-GeometryCalib.Tx_Ty_Tz(2);%inversion of the y image coordinate
GeometryCalib.Cx_Cy(2)=ny-GeometryCalib.Cx_Cy(2);%inversion of the y image coordinate
GeometryCalib.omc=(180/pi)*omc_1;%angles in degrees
GeometryCalib.ErrorRMS=[];
GeometryCalib.ErrorMax=[];

%------------------------------------------------------------------------
function GeometryCalib=calib_3D_quadr(Coord,handles)
%------------------------------------------------------------------

path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
huvmat=findobj(allchild(0),'Tag','uvmat');
hhuvmat=guidata(huvmat);
% check_cond=0;
coord_files=get(handles.ListCoordFiles,'String');
if ischar(coord_files)
    coord_files={coord_files};
end
if isempty(coord_files{1}) || isequal(coord_files,{''})
    coord_files={};
end

%retrieve the calibration points stored in the files listed in the popup list ListCoordFiles
x_1=Coord(:,4:5)';%px coordinates of the ref points
nx=str2num(get(hhuvmat.num_Npx,'String'));
ny=str2num(get(hhuvmat.num_Npy,'String'));
x_1(2,:)=ny-x_1(2,:);%reverse the y image coordinates
X_1=Coord(:,1:3)';%phys coordinates of the ref points
n_ima=numel(coord_files)+1;
if ~isempty(coord_files) 
    msgbox_uvmat('CONFIRMATION',['The xy coordinates of the calibration points in ' num2str(n_ima) ' planes will be used'])
    for ifile=1:numel(coord_files)
    t=xmltree(coord_files{ifile});
    s=convert(t);%convert to matlab structure
        if isfield(s,'GeometryCalib')
            if isfield(s.GeometryCalib,'SourceCalib')
                if isfield(s.GeometryCalib.SourceCalib,'PointCoord')
                PointCoord=s.GeometryCalib.SourceCalib.PointCoord;
                Coord_file=zeros(length(PointCoord),5);%default
                for i=1:length(PointCoord)
                    line=str2num(PointCoord{i});
                    Coord_file(i,4:5)=line(4:5);%px x
                    Coord_file(i,1:3)=line(1:3);%phys x
                end
                eval(['x_' num2str(ifile+1) '=Coord_file(:,4:5)'';']);
                eval(['x_' num2str(ifile+1) '(2,:)=ny-x_' num2str(ifile+1) '(2,:);' ]);
                eval(['X_' num2str(ifile+1) '=Coord_file(:,1:3)'';']);
                end
            end
        end
    end
end
n_ima=numel(coord_files)+1;
est_dist=[1;0;0;0;0];
est_aspect_ratio=1;
center_optim=0;
run(fullfile(path_UVMAT,'toolbox_calib','go_calib_optim'));% apply fct 'toolbox_calib/go_calib_optim'

GeometryCalib.CalibrationType='3D_quadr';
GeometryCalib.fx_fy=fc';
GeometryCalib.Cx_Cy=cc';
GeometryCalib.kc=kc(1);
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=Tc_1';
if ~exist('Rc_1','var')
    msgbox_uvmat('ERROR',['calibration function ' fullfile('toolbox_calib','go_calib_optim') ' did not converge: use multiple views or option 3D_extrinsic']) 
    return
end
GeometryCalib.R=Rc_1;
GeometryCalib.R(2,1:3)=-GeometryCalib.R(2,1:3);%inversion of the y image coordinate
GeometryCalib.Tx_Ty_Tz(2)=-GeometryCalib.Tx_Ty_Tz(2);%inversion of the y image coordinate
GeometryCalib.Cx_Cy(2)=ny-GeometryCalib.Cx_Cy(2);%inversion of the y image coordinate
GeometryCalib.omc=(180/pi)*omc_1;%angles in degrees
GeometryCalib.ErrorRMS=[];
GeometryCalib.ErrorMax=[];


%------------------------------------------------------------------------
function GeometryCalib=calib_3D_extrinsic(Coord,handles)
%------------------------------------------------------------------
path_uvmat=which('geometry_calib');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
x_1=double(Coord(:,4:5)');%image coordiantes
X_1=double(Coord(:,1:3)');% phys coordinates
huvmat=findobj(allchild(0),'Tag','uvmat');
hhuvmat=guidata(huvmat);
ny=str2double(get(hhuvmat.num_Npy,'String'));
x_1(2,:)=ny-x_1(2,:);%reverse the y image coordinates
n_ima=1;
GeometryCalib.CalibrationType='3D_extrinsic';
GeometryCalib.fx_fy(1)=str2num(get(handles.fx,'String'));
GeometryCalib.fx_fy(2)=str2num(get(handles.fy,'String'));
GeometryCalib.Cx_Cy(1)=str2num(get(handles.Cx,'String'));
GeometryCalib.Cx_Cy(2)=str2num(get(handles.Cy,'String'));
GeometryCalib.kc=str2num(get(handles.kc,'String'));
fct_path=fullfile(path_UVMAT,'toolbox_calib');
addpath(fct_path)
GeometryCalib.Cx_Cy(2)=ny-GeometryCalib.Cx_Cy(2);%reverse Cx_Cy(2) for calibration (inversion of px ordinate)
[omc,Tc1,Rc1,H,x,ex,JJ] = compute_extrinsic(x_1,X_1,...
   (GeometryCalib.fx_fy)',GeometryCalib.Cx_Cy',[GeometryCalib.kc 0 0 0 0]);
rmpath(fct_path);
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=Tc1';
%inversion of z axis 
GeometryCalib.R=Rc1;
GeometryCalib.R(2,1:3)=-GeometryCalib.R(2,1:3);%inversion of the y image coordinate
GeometryCalib.Tx_Ty_Tz(2)=-GeometryCalib.Tx_Ty_Tz(2);%inversion of the y image coordinate
GeometryCalib.Cx_Cy(2)=ny-GeometryCalib.Cx_Cy(2);%inversion of the y image coordinate
GeometryCalib.omc=(180/pi)*omc';
%GeometryCalib.R(3,1:3)=-GeometryCalib.R(3,1:3);%inversion for z upward



%------------------------------------------------------------------------
%function GeometryCalib=calib_tsai_heikkila(Coord)
% TEST: NOT IMPLEMENTED
%------------------------------------------------------------------
% path_uvmat=which('uvmat');% check the path detected for source file uvmat
% path_UVMAT=fileparts(path_uvmat); %path to UVMAT
% path_calib=fullfile(path_UVMAT,'toolbox_calib_heikkila');
% addpath(path_calib)
% npoints=size(Coord,1);
% Coord(:,1:3)=10*Coord(:,1:3);
% Coord=[Coord zeros(npoints,2) -ones(npoints,1)];
% [par,pos,iter,res,er,C]=cacal('dalsa',Coord);
% GeometryCalib.CalibrationType='tsai';
% GeometryCalib.focal=par(2);


%------------------------------------------------------------------------
% --- determine the rms of calibration error
function ErrorRms=error_calib(calib_param,Calib,Coord)
%calib_param: vector of free calibration parameters (to optimise)
%Calib: structure of the given calibration parameters
%Coord: list of phys coordinates (columns 1-3, and pixel coordinates (columns 4-5)
Calib.f=25;
Calib.dpx=0.012;
Calib.dpy=0.012;
Calib.sx=1;
Calib.Cx=512;
Calib.Cy=512;
Calib.kappa1=calib_param(1);
Calib.Tx=calib_param(2);
Calib.Ty=calib_param(3);
Calib.Tz=calib_param(4);
alpha=calib_param(5);
Calib.R=[cos(alpha) sin(alpha) 0;-sin(alpha) cos(alpha) 0;0 0 -1];

X=Coord(:,1);
Y=Coord(:,2);
Z=Coord(:,3);
x_ima=Coord(:,4);
y_ima=Coord(:,5); 
[Xpoints,Ypoints]=px_XYZ(Calib,X,Y,Z);
ErrorRms(1)=sqrt(mean((Xpoints-x_ima).*(Xpoints-x_ima)));
ErrorRms(2)=sqrt(mean((Ypoints-y_ima).*(Ypoints-y_ima)));
ErrorRms=mean(ErrorRms);

% %------------------------------------------------------------------------
% function XImage_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% update_list(hObject, eventdata,handles)
% 
% %------------------------------------------------------------------------
% function YImage_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% update_list(hObject, eventdata,handles)

%------------------------------------------------------------------------
% --- Executes on button press in STORE.
function STORE_Callback(hObject, eventdata, handles)
Coord=get(handles.ListCoord,'Data');
%Object=read_geometry_calib(Coord_cell);
unitlist=get(handles.CoordUnit,'String');
unit=unitlist{get(handles.CoordUnit,'value')};
GeometryCalib.CoordUnit=unit;
GeometryCalib.SourceCalib.PointCoord=Coord(:,1:5);
huvmat=findobj(allchild(0),'Name','uvmat');
hhuvmat=guidata(huvmat);%handles of elements in the GUI uvmat
% RootPath='';
% RootFile='';
if ~isempty(hhuvmat.RootPath)&& ~isempty(hhuvmat.RootFile)
%     testhandle=1;
    RootPath=get(hhuvmat.RootPath,'String');
    RootFile=get(hhuvmat.RootFile,'String');
    filebase=fullfile(RootPath,RootFile);
    while exist([filebase '.xml'],'file')
        filebase=[filebase '~'];
    end
    outputfile=[filebase '.xml'];
    errormsg=update_imadoc(GeometryCalib,outputfile,'GeometryCalib');
    if ~strcmp(errormsg,'')
        msgbox_uvmat('ERROR',errormsg);
    end
    listfile=get(handles.ListCoordFiles,'string');
    if isequal(listfile,{''})
        listfile={outputfile};
    else
        listfile=[listfile;{outputfile}];%update the list of coord files
    end
    set(handles.ListCoordFiles,'string',listfile);
end
set(handles.ListCoord,'Data',[])

% --------------------------------------------------------------------
% --- Executes on button press in CLEAR_PTS: clear the list of calibration points
function CLEAR_PTS_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
set(handles.ListCoord,'Data',[])
PLOT_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on button press in CLEAR.
function CLEAR_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.ListCoordFiles,'Value',1)
set(handles.ListCoordFiles,'String',{''})

%------------------------------------------------------------------------
% --- Executes on selection change in CheckEnableMouse.
function CheckEnableMouse_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
choice=get(handles.CheckEnableMouse,'Value');
if choice
    set(handles.CheckEnableMouse,'BackgroundColor',[1 1 0])
    huvmat=findobj(allchild(0),'tag','uvmat');
    if ishandle(huvmat)
        hhuvmat=guidata(huvmat);
        if get(hhuvmat.CheckEditObject,'Value')
        set(hhuvmat.CheckEditObject,'Value',0)
        uvmat('CheckEditObject_Callback',hhuvmat.CheckEditObject,[],hhuvmat)
        end
    end
else
    set(handles.CheckEnableMouse,'BackgroundColor',[0.7 0.7 0.7]) 
end


% --------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)
path_to_uvmat=which('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
else
   addpath (fullfile(pathelp,'uvmat_doc'))
   web([helpfile '#geometry_calib'])
end

% --------------------------------------------------------------------
function MenuSetScale_Callback(hObject, eventdata, handles)

 answer=msgbox_uvmat('INPUT_TXT','scale pixel/cm?','');
 %create test points
 huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
npy=size(UvData.Field.A,1);
npx=size(UvData.Field.A,2);
Xima=[0.25*npx 0.75*npx 0.75*npx 0.25*npx]';
Yima=[0.25*npy 0.25*npy 0.75*npy 0.75*npy]';
x=Xima/str2num(answer);
y=Yima/str2num(answer);
Coord=[x y zeros(4,1) Xima Yima zeros(4,1)];
set(handles.ListCoord,'Data',Coord)
set(handles.APPLY,'BackgroundColor',[1 0 1])

%------------------------------------------------------------------------
function MenuCreateGrid_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
CalibData=get(handles.geometry_calib,'UserData');
Tinput=[];%default
if isfield(CalibData,'grid')
    Tinput=CalibData.grid;
end
[T,CalibData.grid]=create_grid(Tinput);%display the GUI create_grid
set(handles.geometry_calib,'UserData',CalibData)

%grid in phys space
Coord=get(handles.ListCoord,'Data');
Coord(1:size(T,1),1:3)=T;%update the existing list of phys coordinates from the GUI create_grid
set(handles.ListCoord,'Data',Coord)
set(handles.APPLY,'BackgroundColor',[1 0 1])

% -----------------------------------------------------------------------
% --- automatic grid dectection from local maxima of the images 
function MenuDetectGrid_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%% read the four last point coordinates in pixels
Coord=get(handles.ListCoord,'Data');%read list of coordinates on geometry_calib
nbpoints=size(Coord,1); %nbre of calibration points
if nbpoints~=4
    msgbox_uvmat('ERROR','four points must have be selected by the mouse to delimitate the phys grid area; the Ox axis will be defined by the two first points')
    return
end
corners_X=(Coord(end:-1:end-3,4)); %pixel absissa of the four corners
corners_Y=(Coord(end:-1:end-3,5)); 

%reorder the last two points (the two first in the list) if needed
angles=angle((corners_X-corners_X(1))+1i*(corners_Y-corners_Y(1)));
if abs(angles(4)-angles(2))>abs(angles(3)-angles(2))
      X_end=corners_X(4);
      Y_end=corners_Y(4);
      corners_X(4)=corners_X(3);
      corners_Y(4)=corners_Y(3);
      corners_X(3)=X_end;
      corners_Y(3)=Y_end;
end

%% initiate the grid
CalibData=get(handles.geometry_calib,'UserData');%get information stored on the GUI geometry_calib
grid_input=[];%default
if isfield(CalibData,'grid')
    grid_input=CalibData.grid;%retrieve the previously used grid
end
[T,CalibData.grid,CalibData.grid.CheckWhite]=create_grid(grid_input,'detect_grid');%display the GUI create_grid, read the set of phys coordinates T
set(handles.geometry_calib,'UserData',CalibData)%store the phys grid parameters for later use

%% read the current image, displayed in the GUI uvmat
huvmat=findobj(allchild(0),'Name','uvmat');
UvData=get(huvmat,'UserData');
A=UvData.Field.A;%currently displayed image
npxy=size(A);
X=[CalibData.grid.x_0 CalibData.grid.x_1 CalibData.grid.x_0 CalibData.grid.x_1]';%corner absissa in the phys coordinates (cm)
Y=[CalibData.grid.y_0 CalibData.grid.y_0 CalibData.grid.y_1 CalibData.grid.y_1]';%corner ordinates in the phys coordinates (cm)

%calculate transform matrices for plane projection: rectangle assumed to be viewed in perspective
% reference: http://alumni.media.mit.edu/~cwren/interpolator/ by Christopher R. Wren
B = [ X Y ones(size(X)) zeros(4,3)        -X.*corners_X -Y.*corners_X ...
      zeros(4,3)        X Y ones(size(X)) -X.*corners_Y -Y.*corners_Y ];
B = reshape (B', 8 , 8 )';
D = [ corners_X , corners_Y ];
D = reshape (D', 8 , 1 );
l = (B' * B)\B' * D;
Amat = reshape([l(1:6)' 0 0 1 ],3,3)';
C = [l(7:8)' 1];

% transform grid image into 'phys' coordinates 
GeometryCalib.CalibrationType='3D_linear';
GeometryCalib.fx_fy=[1 1];
GeometryCalib.Tx_Ty_Tz=[Amat(1,3) Amat(2,3) 1];
GeometryCalib.R=[Amat(1,1),Amat(1,2),0;Amat(2,1),Amat(2,2),0;C(1),C(2),0];
GeometryCalib.CoordUnit='cm';
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
addpath(fullfile(path_UVMAT,'transform_field'))
Data.ListVarName={'AY','AX','A'};
Data.VarDimName={'AY','AX',{'AY','AX'}};
if ndims(A)==3
    A=mean(A,3);
end
Data.A=A-min(min(A));
Data.AY=[npxy(1)-0.5 0.5];
Data.AX=[0.5 npxy(2)];
Data.CoordUnit='pixel';
Calib.GeometryCalib=GeometryCalib;
DataOut=phys(Data,Calib);
rmpath(fullfile(path_UVMAT,'transform_field'))
Amod=DataOut.A;% current imgage expressed in 'phys' coord
Rangx=DataOut.AX;
Rangy=DataOut.AY;
if CalibData.CheckWhite
    Amod=double(Amod);%case of white grid markers: will look for image maxima
else
    Amod=-double(Amod);%case of black grid markers: will look for image minima
end

%% detection of local image extrema in each direction
Dx=(Rangx(2)-Rangx(1))/(npxy(2)-1); %x mesh in real space
Dy=(Rangy(2)-Rangy(1))/(npxy(1)-1); %y mesh in real space
ind_range_x=ceil(abs(GeometryCalib.R(1,1)*CalibData.grid.Dx/3));% range of search of image ma around each point obtained by linear interpolation from the marked points
ind_range_y=ceil(abs(GeometryCalib.R(2,2)*CalibData.grid.Dy/3));% range of search of image ma around each point obtained by linear interpolation from the marked points
nbpoints=size(T,1);
%lokk for image maxima around each expected pgrid point
for ipoint=1:nbpoints
    i0=1+round((T(ipoint,1)-Rangx(1))/Dx);%round(Xpx(ipoint));
    j0=1+round((T(ipoint,2)-Rangy(1))/Dy);%round(Xpx(ipoint));
    j0min=max(j0-ind_range_y,1);
    j0max=min(j0+ind_range_y,size(Amod,1));
    i0min=max(i0-ind_range_x,1);
    i0max=min(i0+ind_range_x,size(Amod,2));
    Asub=Amod(j0min:j0max,i0min:i0max);
  

   
    x_profile=sum(Asub,1);%profile of subimage summed over y
    y_profile=sum(Asub,2);%profile of subimage summed over x
    %%%%
%     if ipoint==5
%                 figure(10)
%   imagesc(Asub)
%     figure(11)
%     plot(x_profile,'r')
%     hold on
%     plot(y_profile,'b')
%     end
    %%%%
    [tild,ind_x_max]=max(x_profile);
    [tild,ind_y_max]=max(y_profile);
    %sub-pixel improvement using moments
    x_shift=0;
    y_shift=0;
    if ind_x_max+2<=numel(x_profile) && ind_x_max-2>=1
        Atop=x_profile(ind_x_max-2:ind_x_max+2);% extract x profile around the max
        x_shift=sum(Atop.*[-2 -1 0 1 2])/sum(Atop);
    end
    if ind_y_max+2<=numel(y_profile) && ind_y_max-2>=1
        Atop=y_profile(ind_y_max-2:ind_y_max+2);% extract y profile around the max
        y_shift=sum(Atop.*[-2 -1 0 1 2]')/sum(Atop);
    end
    Delta(ipoint,1)=(i0min+ind_x_max-1+x_shift-i0)*Dx;%shift from the initial guess
    Delta(ipoint,2)=(j0min+ind_y_max-1+y_shift-j0)*Dy;
end
Tmod=T(:,(1:2))+Delta;% 'phys' coordinates of the detected points 
Tmod(:,2)=flipdim(Tmod(:,2),1);% inverse the order of y coordinates
[Xpx,Ypx]=px_XYZ(GeometryCalib,Tmod(:,1),Tmod(:,2));% image coordinates of the detected points
Coord=[T Xpx Ypx zeros(size(T,1),1)];
set(handles.ListCoord,'Data',Coord)
PLOT_Callback(hObject, eventdata, handles)
set(handles.APPLY,'BackgroundColor',[1 0 1])

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
Coord=get(handles.ListCoord,'Data');
Coord(:,1)=T(1)+Coord(:,1);
Coord(:,2)=T(2)+Coord(:,2);
Coord(:,3)=T(3)+Coord(:,3);
set(handles.ListCoord,'Data',Coord);
set(handles.APPLY,'BackgroundColor',[1 0 1])

% --------------------------------------------------------------------
function MenuRotatePoints_Callback(hObject, eventdata, handles)
%hcalib=get(handles.calib_type,'parent');%handles of the GUI geometry_calib
CalibData=get(handles.geometry_calib,'UserData');
Tinput=[];%default
if isfield(CalibData,'rotate')
    Tinput=CalibData.rotate;
end
T=rotate_points(Tinput);%display rotate_points GUI to introduce rotation parameters 
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
Coord=get(handles.ListCoord,'Data');
r1=cos(pi*Phi/180);
r2=-sin(pi*Phi/180);
r3=sin(pi*Phi/180);
r4=cos(pi*Phi/180);
x=Coord(:,1)-O_x;
y=Coord(:,2)-O_y;
Coord(:,1)=r1*x+r2*y;
Coord(:,2)=r3*x+r4*y;
set(handles.ListCoord,'Data',Coord)
set(handles.APPLY,'BackgroundColor',[1 0 1])

% --------------------------------------------------------------------
function MenuImportPoints_Callback(hObject, eventdata, handles)
fileinput=browse_xml(hObject, eventdata, handles);
if isempty(fileinput)
    return
end
[s,errormsg]=imadoc2struct(fileinput,'GeometryCalib');
if ~isfield(s,'GeometryCalib')
    msgbox_uvmat('ERROR','invalid input file: no geometry_calib data')
    return
end
GeometryCalib=s.GeometryCalib;
if ~(isfield(GeometryCalib,'SourceCalib')&&isfield(GeometryCalib.SourceCalib,'PointCoord'))
        msgbox_uvmat('ERROR','invalid input file: no calibration points')
    return
end
Coord=GeometryCalib.SourceCalib.PointCoord;
Coord=[Coord zeros(size(Coord,1),1)];
set(handles.ListCoord,'Data',Coord)
PLOT_Callback(handles.geometry_calib, [], handles)
set(handles.APPLY,'BackgroundColor',[1 0 1])

% -----------------------------------------------------------------------
function MenuImportIntrinsic_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=browse_xml(hObject, eventdata, handles);
if isempty(fileinput)
    return
end
[s,errormsg]=imadoc2struct(fileinput,'GeometryCalib');
GeometryCalib=s.GeometryCalib;
display_intrinsic(GeometryCalib,handles)

% -----------------------------------------------------------------------
function MenuImportAll_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=browse_xml(hObject, eventdata, handles);
if ~isempty(fileinput)
    loadfile(handles,fileinput)
end

% -----------------------------------------------------------------------
% --- Executes on menubar option Import/Grid file: introduce previous grid files
function MenuGridFile_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
inputfile=browse_xml(hObject, eventdata, handles);
listfile=get(handles.ListCoordFiles,'String');
if isequal(listfile,{''})
    listfile={inputfile};
else
    listfile=[listfile;{inputfile}];%update the list of coord files
end
set(handles.ListCoordFiles,'string',listfile);


%------------------------------------------------------------------------
function fileinput=browse_xml(hObject, eventdata, handles)
%------------------------------------------------------------------------
fileinput=[];%default
oldfile=''; %default
UserData=get(handles.geometry_calib,'UserData');
if isfield(UserData,'XmlInputFile')
    oldfile=UserData.XmlInputFile;
end
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
if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end
UserData.XmlInputFile=fileinput;
set(handles.geometry_calib,'UserData',UserData)%record current file foer further use of browser

% -----------------------------------------------------------------------
function Heading=loadfile(handles,fileinput)
%------------------------------------------------------------------------
Heading=[];%default
[s,errormsg]=imadoc2struct(fileinput,'Heading','GeometryCalib');
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    return
end
if ~isempty(s.Heading)
    Heading=s.Heading;
end

GeometryCalib=s.GeometryCalib;
fx=1;fy=1;Cx=0;Cy=0;kc=0; %default
CoordCell={};
Tabchar={};%default
val_cal=1;%default
if ~isempty(GeometryCalib)
    % choose the calibration option
    if isfield(GeometryCalib,'CalibrationType')
        calib_list=get(handles.calib_type,'String');
        for ilist=1:numel(calib_list)
            if strcmp(calib_list{ilist},GeometryCalib.CalibrationType)
                val_cal=ilist;
                break
            end
        end
    end
    display_intrinsic(GeometryCalib,handles)%intrinsic param
    %extrinsic param
    if isfield(GeometryCalib,'Tx_Ty_Tz')
        Tx_Ty_Tz=GeometryCalib.Tx_Ty_Tz;
        set(handles.Tx,'String',num2str(GeometryCalib.Tx_Ty_Tz(1),4))
        set(handles.Ty,'String',num2str(GeometryCalib.Tx_Ty_Tz(2),4))
        set(handles.Tz,'String',num2str(GeometryCalib.Tx_Ty_Tz(3),4))
    end
    if isfield(GeometryCalib,'omc')
        set(handles.Phi,'String',num2str(GeometryCalib.omc(1),4))
        set(handles.Theta,'String',num2str(GeometryCalib.omc(2),4))
        set(handles.Psi,'String',num2str(GeometryCalib.omc(3),4))
    end
    if isfield(GeometryCalib,'SourceCalib')
        calib=GeometryCalib.SourceCalib.PointCoord;
        Coord=[calib zeros(size(calib,1),1)];
        set(handles.ListCoord,'Data',Coord)
    end
    PLOT_Callback(handles.geometry_calib, [], handles)
    set(handles.APPLY,'BackgroundColor',[1 0 1])
end
set(handles.calib_type,'Value',val_cal)

if isempty(CoordCell)% allow mouse action by default in the absence of input points
    set(handles.CheckEnableMouse,'Value',1)
    set(handles.CheckEnableMouse,'BackgroundColor',[1 1 0])
else % does not allow mouse action by default in the presence of input points
    set(handles.CheckEnableMouse,'Value',0)
    set(handles.CheckEnableMouse,'BackgroundColor',[0.7 0.7 0.7])
end

%------------------------------------------------------------------------
%---display calibration intrinsic parameters
function display_intrinsic(GeometryCalib,handles)
%------------------------------------------------------------------------
fx=[];
fy=[];
if isfield(GeometryCalib,'fx_fy')
    fx=GeometryCalib.fx_fy(1);
    fy=GeometryCalib.fx_fy(2);
end
Cx_Cy=[0 0];%default
if isfield(GeometryCalib,'Cx_Cy')
    Cx_Cy=GeometryCalib.Cx_Cy;
end
kc=0;
if isfield(GeometryCalib,'kc')
    kc=GeometryCalib.kc; %* GeometryCalib.focal*GeometryCalib.focal;
end
set(handles.fx,'String',num2str(fx,5))
set(handles.fy,'String',num2str(fy,5))
set(handles.Cx,'String',num2str(Cx_Cy(1),'%1.1f'))
set(handles.Cy,'String',num2str(Cx_Cy(2),'%1.1f'))
set(handles.kc,'String',num2str(kc,'%1.4f'))


% --- Executes when user attempts to close geometry_calib.
function geometry_calib_CloseRequestFcn(hObject, eventdata, handles)

delete(hObject); % closes the figure

%------------------------------------------------------------------------
% --- Executes on button press in PLOT.
%------------------------------------------------------------------------
function PLOT_Callback(hObject, eventdata, handles)
huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
hhuvmat=guidata(huvmat); %handles of GUI elements in uvmat
h_menu_coord=findobj(huvmat,'Tag','TransformName');
menu=get(h_menu_coord,'String');
choice=get(h_menu_coord,'Value');
if iscell(menu)
    option=menu{choice};
else
    option='px'; %default
end
Coord=get(handles.ListCoord,'Data');
if ~isempty(Coord)
    if isequal(option,'phys')
        Coord_plot=Coord(:,1:3);
    elseif isequal(option,'px')||isequal(option,'')
        Coord_plot=Coord(:,4:5);
    else
        msgbox_uvmat('ERROR','the choice in menu_coord of uvmat must be blank, px or phys ')
    end
end

set(0,'CurrentFigure',huvmat)
set(huvmat,'CurrentAxes',hhuvmat.PlotAxes)
hh=findobj('Tag','calib_points');
if  ~isempty(Coord) && isempty(hh)
    hh=line(Coord_plot(:,1),Coord_plot(:,2),'Color','m','Tag','calib_points','LineStyle','.','Marker','+');
elseif isempty(Coord)%empty list of points, suppress the plot
    delete(hh)
else
    set(hh,'XData',Coord_plot(:,1))
    set(hh,'YData',Coord_plot(:,2))
end
pause(.1)
figure(handles.geometry_calib)

%------------------------------------------------------------------------ 
% --- Executes on button press in Copy: display Coord on the Matlab work space
%------------------------------------------------------------------------
function Copy_Callback(hObject, eventdata, handles)
global Coord
evalin('base','global Coord')%make CurData global in the workspace
Coord=get(handles.ListCoord,'Data');
display('coordinates of calibration points (phys,px,marker) :')
evalin('base','Coord') %display CurData in the workspace
commandwindow; %brings the Matlab command window to the front

%------------------------------------------------------------------------ 
% --- Executes when selected cell(s) is changed in ListCoord.
%------------------------------------------------------------------------ 
function ListCoord_CellSelectionCallback(hObject, eventdata, handles)
if ~isempty(eventdata.Indices)
    iline=eventdata.Indices(1);% selected line number
    Data=get(handles.ListCoord,'Data');
    Data(:,6)=zeros(size(Data,1),1);
    Data(iline,6)=-1;% mark the selected line
    set(handles.ListCoord,'Data',Data)
    update_calib_marker(Data(iline,:))
end

%------------------------------------------------------------------------ 
% --- Executes when entered data in editable cell(s) in ListCoord.
%------------------------------------------------------------------------ 
function ListCoord_CellEditCallback(hObject, eventdata, handles)

Input=str2num(eventdata.EditData);%pasted input
Coord=get(handles.ListCoord,'Data');
iline=eventdata.Indices(1);% selected line number
if size(Coord,1)<iline+numel(Input)
    Coord=[Coord ; zeros(iline+numel(Input)-size(Coord,1),6)];% append zeros to fit the new column
end
Coord(iline:iline+numel(Input)-1,eventdata.Indices(2))=Input';
set(handles.ListCoord,'Data',Coord)
PLOT_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- 'key_press_fcn:' function activated when a key is pressed on the keyboard
%------------------------------------------------------------------------
function ListCoord_KeyPressFcn(hObject, eventdata, handles)
xx=double(get(handles.geometry_calib,'CurrentCharacter'));%get the keyboard character
if ismember(xx,[30 31 127])% arrow upward, downward, or delete
    Coord=get(handles.ListCoord,'Data');
    ind=find(Coord(:,6));%find the marker '+' for line selection
    Coord(:,6)=zeros(size(Coord,1),1);% desactivate the current line mark
    switch xx
        case 30 % arrow upward
            Coord(ind-1,6)=1;
        case 31% arrow downward
            Coord(ind+1,6)=1;
        case 127% remove line
            Coord(ind,:)=[];
            PLOT_Callback(hObject,eventdata,handles)
            set(handles.APPLY,'BackgroundColor',[1 0 1])
        otherwise
    end
    set(handles.ListCoord,'Data',Coord);
else
    set(handles.APPLY,'BackgroundColor',[1 0 1])
end


%------------------------------------------------------------------------
% --- update the plot of calibration points
%------------------------------------------------------------------------ 
function update_calib_marker(Coord)
%% update the plot on uvmat
huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
hplot=findobj(huvmat,'Tag','PlotAxes');%main plotting axis of uvmat
hhh=findobj(hplot,'Tag','calib_marker');

h_menu_coord=findobj(huvmat,'Tag','TransformName');
menu=get(h_menu_coord,'String');
choice=get(h_menu_coord,'Value');
if iscell(menu)
    option=menu{choice};
else
    option='px'; %default
end
if isequal(option,'phys')
    XCoord=Coord(1);
    YCoord=Coord(2);
elseif isequal(option,'px')|| isequal(option,'')
    XCoord=Coord(4);
    YCoord=Coord(5);
else
    msgbox_uvmat('ERROR','the choice in menu_coord of uvmat must be blank, px or phys ')
end
if isempty(XCoord)||isempty(YCoord)
     if ~isempty(hhh)
        delete(hhh)%delete the circle marker
    end
    return
end
xlim=get(hplot,'XLim');
ylim=get(hplot,'YLim');
ind_range=max(abs(xlim(2)-xlim(1)),abs(ylim(end)-ylim(1)))/20;%defines the size of the circle marker
if isempty(hhh)
    set(0,'CurrentFig',huvmat)
    set(huvmat,'CurrentAxes',hplot)
    rectangle('Curvature',[1 1],...
              'Position',[XCoord-ind_range/2 YCoord-ind_range/2 ind_range ind_range],'EdgeColor','m',...
              'LineStyle','-','Tag','calib_marker');
else
    set(hhh,'Position',[XCoord-ind_range/2 YCoord-ind_range/2 ind_range ind_range])
end

%------------------------------------------------------------------------
% --- Executes on button press in ClearLine: remove the selected line in the table Coord
%------------------------------------------------------------------------
function ClearLine_Callback(hObject, eventdata, handles)

Coord=get(handles.ListCoord,'Data');
ind=find(Coord(:,6));%find the marker '-' for line selection
if isempty(ind)
    msgbox_uvmat('WARNING','no line suppressed, select a line in the table')
else
    answer=msgbox_uvmat('INPUT_Y-N',['suppress line ' num2str(ind) '?']);
    if isequal(answer,'Yes')
Coord(:,6)=zeros(size(Coord,1),1);% desactivate the current line mark
Coord(ind,:)=[];
PLOT_Callback(hObject,eventdata,handles)
set(handles.APPLY,'BackgroundColor',[1 0 1])
set(handles.ListCoord,'Data',Coord);
    end
end
