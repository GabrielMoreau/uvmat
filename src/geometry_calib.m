%%
%'geometry_calib': performs geometric calibration from a set of reference points
%
% function varargout = geometry_calib(varargin)
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

% Last Modified by GUIDE v2.5 05-Oct-2010 13:47:00

% Begin initialization code - DO NOT edit
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @geometry_calib_OpeningFcn, ...
                   'gui_OutputFcn',  @geometry_calib_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ~isempty(regexp(varargin{1},'_Callback','once'))
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
function geometry_calib_OpeningFcn(hObject, eventdata, handles,inputfile,pos)
%------------------------------------------------------------------------
% Choose default command line output for geometry_calib

handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(hObject,'DeleteFcn',{@closefcn})%

%set the position of the interface
if exist('pos','var')&& length(pos)>=4
%     %pos_gui=get(hObject,'Position');
%     pos_gui(1)=pos(1);
%     pos_gui(2)=pos(2);
    set(hObject,'Position',pos);
end

%set menu of calibration options
set(handles.calib_type,'String',{'rescale';'linear';'3D_linear';'3D_quadr';'3D_extrinsic'})
inputxml='';
if exist('inputfile','var')&& ~isempty(inputfile)
    struct.XmlInputFile=inputfile;
    [Pathsub,RootFile,field_count,str2,str_a,str_b,ext]=name2display(inputfile);
    if ~strcmp(ext,'.xml')
        inputfile=[fullfile(Pathsub,RootFile) '.xml'];%xml file corresponding to the input file
    end
    set(handles.ListCoord,'String',{'......'})
    if exist(inputfile,'file')
        Heading=loadfile(handles,inputfile);% load the point coordiantes existing in the xml file
        if isfield(Heading,'Campaign')&& ischar(Heading.Campaign)
            struct.Campaign=Heading.Campaign;
        end
    end   
    set(hObject,'UserData',struct)
end

set(handles.ListCoord,'KeyPressFcn',{@key_press_fcn,handles})%set keyboard action function


%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = geometry_calib_OutputFcn(hObject, eventdata, handles)
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
%     set(handles.MenuMask,'enable','on')
%     set(handles.MenuGrid,'enable','on')
%     set(handles.MenuObject,'enable','on')
%     set(handles.MenuEdit,'enable','on')
%     set(handles.edit,'enable','on')
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
%read the current calibration points
Coord_cell=get(handles.ListCoord,'String');
Object=read_geometry_calib(Coord_cell);
Coord=Object.Coord;
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
    [EM,ind_dim]=max(GeometryCalib.ErrorMax);
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

% store the calibration data, by default in the xml file of the currently displayed image
hhuvmat=guidata(findobj(allchild(0),'Name','uvmat'));%handles of elements in the GUI uvmat
RootPath='';
RootFile='';
if ~isempty(hhuvmat.RootPath)&& ~isempty(hhuvmat.RootFile)
    testhandle=1;
    RootPath=get(hhuvmat.RootPath,'String');
    RootFile=get(hhuvmat.RootFile,'String');
    filebase=fullfile(RootPath,RootFile);
    outputfile=[filebase '.xml'];%xml file associated with the currently displayed image
else
    question={'save the calibration data and point coordinates in'};
    def={fullfile(RootPath,'ObjectCalib.xml')};
    options.Resize='on';
    answer=inputdlg(question,'save average in a new file',1,def,options);
    outputfile=answer{1};
end
answer=msgbox_uvmat('INPUT_Y-N',{[outputfile ' updated with calibration data'];...
    ['Error rms (along x,y)=' num2str(GeometryCalib.ErrorRms) ' pixels'];...
    ['Error max (along x,y)=' num2str(GeometryCalib.ErrorMax) ' pixels']});

%% record the calibration parameters and display the current image of uvmat in the new phys coordinates
if strcmp(answer,'Yes')
    if strcmp(calib_cell{val}(1:2),'3D')%set the plane position for 3D (projection) calibration
        answer_1=msgbox_uvmat('INPUT_TXT',' Z= ',num2str(Z_plane)); 
        if strcmp(answer_1,'Cancel')
            Z_plane=0; %default
        else
            Z_plane=str2double(answer_1);
        end
        GeometryCalib.NbSlice=1;
        GeometryCalib.SliceCoord=[0 0 Z_plane];
    end
    errormsg=update_imadoc(GeometryCalib,outputfile);% introduce the calibration data in the xml file
    if ~strcmp(errormsg,'')
        msgbox_uvmat('ERROR',errormsg);
    end
    
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
    UserData=get(handles.geometry_calib,'UserData');
    UserData.XmlInputFile=outputfile;%save the current xml file name
    set(handles.geometry_calib,'UserData',UserData)
    uvmat('RootPath_Callback',hObject,eventdata,hhuvmat); %file input with xml reading  in uvmat, show the image in phys coordinates
    MenuPlot_Callback(hObject, eventdata, handles)
    set(handles.ListCoord,'Value',index)% indicate in the list the point with max deviation (possible mistake)
    ListCoord_Callback(hObject, eventdata, handles)
    figure(handles.geometry_calib)
end

%------------------------------------------------------------------
% --- Executes on button press in calibrate_lin.

function REPLICATE_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%% Apply calibration
calib_cell=get(handles.calib_type,'String'); %#ok<NASGU>
val=get(handles.calib_type,'Value'); %#ok<NASGU>

%read the current calibration points
Coord_cell=get(handles.ListCoord,'String');
Object=read_geometry_calib(Coord_cell);
Coord=Object.Coord;

% apply the calibration, whose type is selected in  handles.calib_type
if ~isempty(Coord)
    calib_cell=get(handles.calib_type,'String');
    val=get(handles.calib_type,'Value');
    GeometryCalib=feval(['calib_' calib_cell{val}],Coord,handles);
else
    msgbox_uvmat('ERROR','No calibration points, abort')
    return
end 

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
    [EM,ind_dim]=max(GeometryCalib.ErrorMax);
%     index=index(ind_dim);
    %set the Z position of the reference plane used for calibration
    Z_plane=[];
    if isequal(max(Z),min(Z))
        Z_plane=Z(1);
    end
    answer_1=msgbox_uvmat('INPUT_TXT',' Z= ',num2str(Z_plane)); 
    Z_plane=str2double(answer_1);
    GeometryCalib.NbSlice=1;
    GeometryCalib.SliceCoord=[0 0 Z_plane];
    %set the coordinate unit
    unitlist=get(handles.CoordUnit,'String');
    unit=unitlist{get(handles.CoordUnit,'value')};
    GeometryCalib.CoordUnit=unit;
    %record the points
    GeometryCalib.SourceCalib.PointCoord=Coord;
end

%% display calibration paprameters
display_intrinsic(GeometryCalib,handles)%display calibration intrinsic parameters

% Display extrinsinc parameters (rotation and translation of camera with  respect to the phys coordiantes)
set(handles.Tx,'String',num2str(GeometryCalib.Tx_Ty_Tz(1),4))
set(handles.Ty,'String',num2str(GeometryCalib.Tx_Ty_Tz(2),4))
set(handles.Tz,'String',num2str(GeometryCalib.Tx_Ty_Tz(3),4))
set(handles.Phi,'String',num2str(GeometryCalib.omc(1),4))
set(handles.Theta,'String',num2str(GeometryCalib.omc(2),4))
set(handles.Psi,'String',num2str(GeometryCalib.omc(3),4))

%% open the GUI dataview 
h_dataview=findobj(allchild(0),'name','dataview');
if ~isempty(h_dataview)
    delete(h_dataview)
end
CalibData=get(handles.geometry_calib,'UserData');%read the calibration image source on the interface userdata
InputFile='';
if isfield(CalibData,'XmlInputFile')
    InputDir=fileparts(CalibData.XmlInputFile);
    [InputDir,DirName]=fileparts(InputDir);
end
SubCampaignTest='n'; %default
testup=0;
if isfield(CalibData,'SubCampaign')
    SubCampaignTest='y';
    dir_ref=CalibData.SubCampaign;
    testup=1;
elseif isfield(CalibData,'Campaign')
    dir_ref=CalibData.Campaign;
    testup=1;
end
while testup
    [InputDir,DirName]=fileparts(InputDir);
    if strcmp(DirName,dir_ref)
        break
    end
end
InputDir=fullfile(InputDir,DirName);
answer=msgbox_uvmat('INPUT_TXT','Campaign ?',InputDir); 
if strcmp(answer,'Cancel')
    return
end

dataview(answer,SubCampaignTest,GeometryCalib);
        
%     if isfield(Heading,'Device') && isequal([filename ext],Heading.Device)
%         [XmlInput,filename,ext]=fileparts(XmlInput);
%         Device=Heading.Device;
%     end
%     if isfield(Heading,'Experiment') && isequal([filename ext],Heading.Experiment)
%         [PP,filename,ext]=fileparts(XmlInput);
%     end
%     testinput=0;
%     if isfield(Heading,'SubCampaign') && isequal([filename ext],Heading.SubCampaign)
%         SubCampaignTest='y';
%         testinput=1;
%     elseif isfield(Heading,'Campaign') && isequal([filename ext],Heading.Campaign)
%         testinput=1;
% %     end 
% end
% if ~testinput
%     filename='PROJETS';%default
%     if isfield(CalibData,'XmlInputFile')
%          [pp,filename]=fileparts(CalibData.XmlInputFile);
%     end
%     while ~isequal(filename,'PROJETS') && numel(filename)>1
%         filename_1=filename;
%         pp_1=pp;
%         [pp,filename]=fileparts(pp);
%     end
%     XmlInput=fullfile(pp_1,filename_1);
%     testinput=1;
% end
% if testinput
%     outcome=dataview(XmlInput,SubCampaignTest,GeometryCalib);
% end

%------------------------------------------------------------------------
% determine the parameters for a calibration by an affine function (rescaling and offset, no rotation)
function GeometryCalib=calib_rescale(Coord,handles)
%------------------------------------------------------------------------
X=Coord(:,1);
Y=Coord(:,2);% Z not used
x_ima=Coord(:,4);
y_ima=Coord(:,5);
[px,sx]=polyfit(X,x_ima,1);
[py,sy]=polyfit(Y,y_ima,1);
T_x=px(2);
T_y=py(2);
GeometryCalib.CalibrationType='rescale';
GeometryCalib.fx_fy=[px(1) py(1)];%.fx_fy corresponds to pxcm along x and y
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=[px(2)/px(1) py(2)/py(1) 1];
%GeometryCalib.R=[1,0,0;0,1,0;0,0,0];
GeometryCalib.omc=[0 0 0];

%------------------------------------------------------------------------
% determine the parameters for a calibration by a linear transform matrix (rescale and rotation)
function GeometryCalib=calib_linear(Coord,handles) %TO UPDATE
%------------------------------------------------------------------------
X=Coord(:,1);
Y=Coord(:,2);% Z not used
x_ima=Coord(:,4);
y_ima=Coord(:,5);
XY_mat=[ones(size(X)) X Y];
a_X1=XY_mat\x_ima; %transformation matrix for X
% x1=XY_mat*a_X1;%reconstruction
% err_X1=max(abs(x1-x_ima));%error
a_Y1=XY_mat\y_ima;%transformation matrix for X
% y1=XY_mat*a_Y1;
% err_Y1=max(abs(y1-y_ima));%error
% R=[a_X1(2),a_X1(3),0;a_Y1(2),a_Y1(3),0;0,0,1];
R=[a_X1(2),a_X1(3);a_Y1(2),a_Y1(3)];
norm=abs(det(R));
GeometryCalib.CalibrationType='linear';
GeometryCalib.fx_fy(1)=sqrt((a_X1(2)/a_Y1(3))*norm);
GeometryCalib.fx_fy(2)=(a_Y1(3)/a_X1(2))*GeometryCalib.fx_fy(1);
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=[a_X1(1) a_Y1(1) 1]; 
R(1,:)=R(1,:)/GeometryCalib.fx_fy(1);
R(2,:)=R(2,:)/GeometryCalib.fx_fy(2);
R=[R;[0 0]];
GeometryCalib.R=[R [0;0;1]];
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
    Calib.Cx=str2num(get(hhuvmat.npx,'String'))/2;
    Calib.Cx=str2num(get(hhuvmat.npy,'String'))/2;
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
coord_files=get(handles.coord_files,'String');
if ischar(coord_files)
    coord_files={coord_files};
end
if isempty(coord_files{1}) || isequal(coord_files,{''})
    coord_files={};
end
%retrieve the calibration points stored in the files listed in the popup list coord_files
x_1=Coord(:,4:5)';%px coordinates of the ref points
nx=str2num(get(hhuvmat.npx,'String'));
ny=str2num(get(hhuvmat.npy,'String'));
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
%fc=[25;25]/0.012;
center_optim=0;
run(fullfile(path_UVMAT,'toolbox_calib','go_calib_optim'));
GeometryCalib.CalibrationType='3D_linear';
GeometryCalib.fx_fy=fc';
%GeometryCalib.focal=fc(2);
%GeometryCalib.dpx_dpy=[1 1];
GeometryCalib.Cx_Cy=cc';
%GeometryCalib.sx=fc(1)/fc(2);
GeometryCalib.kc=kc(1);
%GeometryCalib.kappa1=-kc(1)/fc(2)^2;
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
coord_files=get(handles.coord_files,'String');
if ischar(coord_files)
    coord_files={coord_files};
end
if isempty(coord_files{1}) || isequal(coord_files,{''})
    coord_files={};
end

%retrieve the calibration points stored in the files listed in the popup list coord_files
x_1=Coord(:,4:5)';%px coordinates of the ref points
nx=str2num(get(hhuvmat.npx,'String'));
ny=str2num(get(hhuvmat.npy,'String'));
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
%est_fc=[0;0];
%fc=[25;25]/0.012;
center_optim=0;
run(fullfile(path_UVMAT,'toolbox_calib','go_calib_optim'));

GeometryCalib.CalibrationType='3D_quadr';
GeometryCalib.fx_fy=fc';
%GeometryCalib.focal=fc(2);
%GeometryCalib.dpx_dpy=[1 1];
GeometryCalib.Cx_Cy=cc';
%GeometryCalib.sx=fc(1)/fc(2);
GeometryCalib.kc=kc(1);
%GeometryCalib.kappa1=-kc(1)/fc(2)^2;
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
function GeometryCalib=calib_3D_extrinsic(Coord,handles)
%------------------------------------------------------------------
path_uvmat=which('geometry_calib');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
x_1=double(Coord(:,4:5)');%image coordiantes
X_1=double(Coord(:,1:3)');% phys coordinates
huvmat=findobj(allchild(0),'Tag','uvmat');
hhuvmat=guidata(huvmat);
ny=str2double(get(hhuvmat.npy,'String'));
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
% [omc1,Tc1,Rc1,H,x,ex,JJ] = compute_extrinsic(x_1,X_1,...
%     [Calib.f Calib.f*Calib.sx]',...
%     [Calib.Cx Calib.Cy]',...
%     [-Calib.kappa1*Calib.f^2 0 0 0 0]);
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


%--------------------------------------------------------------------------
function GeometryCalib=calib_tsai(Coord,handles)% OBSOLETE: old version using gauthier's bianry ccal_fo
% NOT USED
%------------------------------------------------------------------------
%TSAI
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
xmlfile=fullfile(path_UVMAT,'PARAM.xml');%name of the file containing names of binary executables
if exist(xmlfile,'file')
    t=xmltree(xmlfile);% read the (xml) file containing names of binary executables
    sparam=convert(t);% convert to matlab structure
end
if ~isfield(sparam,'GeometryCalibBin')
    msgbox_uvmat('ERROR',['calibration program <GeometryCalibBin> undefined in parameter file ' xmlfile])
    return
end
Tsai_exe=sparam.GeometryCalibBin;
if ~exist(Tsai_exe,'file')%the binary is defined in /bin, default setting
     Tsai_exe=fullfile(path_UVMAT,Tsai_exe);
end
if ~exist(Tsai_exe,'file')
    msgbox_uvmat('ERROR',['calibration program ' sparam.GeometryCalibBin ' defined in PARAM.xml does not exist'])
    return
end

textcoord=num2str(Coord,4);
dlmwrite('t.txt',textcoord,'');  
% ['!' Tsai_exe ' -fx 0 -fy t.txt']
eval(['!' Tsai_exe ' -f t.txt > tsaicalib.log']);
if ~exist('calib.dat','file')
    msgbox_uvmat('ERROR','no output from calibration program Tsai_exe: possibly too few points')
end
calibdat=dlmread('calib.dat');
delete('calib.dat')
%delete('t.txt')
GeometryCalib.CalibrationType='tsai';
GeometryCalib.focal=calibdat(10);
GeometryCalib.dpx_dpy=[calibdat(5) calibdat(6)];
GeometryCalib.Cx_Cy=[calibdat(7) calibdat(8)];
GeometryCalib.sx=calibdat(9);
GeometryCalib.kappa1=calibdat(11);
GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
GeometryCalib.Tx_Ty_Tz=[calibdat(12) calibdat(13) calibdat(14)];
Rx_Ry_Rz=calibdat(15:17);
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

%------------------------------------------------------------------------
function XImage_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_list(hObject, eventdata,handles)

%------------------------------------------------------------------------
function YImage_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_list(hObject, eventdata,handles)

%------------------------------------------------------------------------
% --- Executes on button press in STORE.
function STORE_Callback(hObject, eventdata, handles)
Coord_cell=get(handles.ListCoord,'String');
Object=read_geometry_calib(Coord_cell);
unitlist=get(handles.CoordUnit,'String');
unit=unitlist{get(handles.CoordUnit,'value')};
GeometryCalib.CoordUnit=unit;
GeometryCalib.SourceCalib.PointCoord=Object.Coord;
huvmat=findobj(allchild(0),'Name','uvmat');
hhuvmat=guidata(huvmat);%handles of elements in the GUI uvmat
% RootPath='';
% RootFile='';
if ~isempty(hhuvmat.RootPath)&& ~isempty(hhuvmat.RootFile)
    testhandle=1;
    RootPath=get(hhuvmat.RootPath,'String');
    RootFile=get(hhuvmat.RootFile,'String');
    filebase=fullfile(RootPath,RootFile);
    while exist([filebase '.xml'],'file')
        filebase=[filebase '~'];
    end
    outputfile=[filebase '.xml'];
    errormsg=update_imadoc(GeometryCalib,outputfile);
    if ~strcmp(errormsg,'')
        msgbox_uvmat('ERROR',errormsg);
    end
    listfile=get(handles.coord_files,'string');
    if isequal(listfile,{''})
        listfile={outputfile};
    else
        listfile=[listfile;{outputfile}];%update the list of coord files
    end
    set(handles.coord_files,'string',listfile);
end
set(handles.ListCoord,'Value',1)% refresh the display of coordinates
set(handles.ListCoord,'String',{'......'})

% --------------------------------------------------------------------
% --- Executes on button press in CLEAR_PTS: clear the list of calibration points
function CLEAR_PTS_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
set(handles.ListCoord,'Value',1)% refresh the display of coordinates
set(handles.ListCoord,'String',{'......'})
MenuPlot_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on button press in CLEAR.
function CLEAR_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.coord_files,'Value',1)
set(handles.coord_files,'String',{''})

%------------------------------------------------------------------------
function XObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_list(hObject, eventdata,handles)

%------------------------------------------------------------------------
function YObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_list(hObject, eventdata,handles)

%------------------------------------------------------------------------
function ZObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_list(hObject, eventdata,handles)

%------------------------------------------------------------------------
function update_list(hObject, eventdata, handles)
%------------------------------------------------------------------------
newval(4)=str2double(get(handles.XImage,'String'));
newval(5)=str2double(get(handles.YImage,'String'));
newval(1)=str2double(get(handles.XObject,'String'));
newval(2)=str2double(get(handles.YObject,'String'));
newval(3)=str2double(get(handles.ZObject,'String'));
if isnan(newval(3)) 
    newval(3)=0;%put z to 0 by default
end
Coord=get(handles.ListCoord,'String');
Coord(end)=[]; %remove last string '.....'
val=get(handles.ListCoord,'Value');
data=read_geometry_calib(Coord);
data.Coord(val,:)=newval;
for i=1:size(data.Coord,1)
    for j=1:5
          Coord_cell{i,j}=num2str(data.Coord(i,j),4);%display coordiantes with 4 digits
    end
end

Tabchar=cell2tab(Coord_cell,' | ');
Tabchar=[Tabchar ;{'......'}];
set(handles.ListCoord,'String',Tabchar)

%update the plot 
ListCoord_Callback(hObject, eventdata, handles)
MenuPlot_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on selection change in ListCoord.
function ListCoord_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
hplot=findobj(huvmat,'Tag','axes3');%main plotting axis of uvmat
hhh=findobj(hplot,'Tag','calib_marker');
Coord_cell=get(handles.ListCoord,'String');
val=get(handles.ListCoord,'Value');
if numel(val)>1
    return %no action if several lines have been selected
end
coord_str=Coord_cell{val};
k=findstr(' | ',coord_str);
if isempty(k)%last line '.....' selected
    if ~isempty(hhh)
        delete(hhh)%delete the circle marker
    end
    return
end
%fill the edit boxex
set(handles.XObject,'String',coord_str(1:k(1)-1))
set(handles.YObject,'String',coord_str(k(1)+3:k(2)-1))
set(handles.ZObject,'String',coord_str(k(2)+3:k(3)-1))
set(handles.XImage,'String',coord_str(k(3)+3:k(4)-1))
set(handles.YImage,'String',coord_str(k(4)+3:end))
h_menu_coord=findobj(huvmat,'Tag','transform_fct');
menu=get(h_menu_coord,'String');
choice=get(h_menu_coord,'Value');
if iscell(menu)
    option=menu{choice};
else
    option='px'; %default
end
if isequal(option,'phys')
    XCoord=str2double(coord_str(1:k(1)-1));
    YCoord=str2double(coord_str(k(1)+3:k(2)-1));
elseif isequal(option,'px')|| isequal(option,'')
    XCoord=str2double(coord_str(k(3)+3:k(4)-1));
    YCoord=str2double(coord_str(k(4)+3:end));
else
    msgbox_uvmat('ERROR','the choice in menu_coord of uvmat must be px or phys ')
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
% --- Executes on selection change in edit_append.
function edit_append_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
choice=get(handles.edit_append,'Value');
if choice
    set(handles.edit_append,'BackgroundColor',[1 1 0])
else
    set(handles.edit_append,'BackgroundColor',[0.7 0.7 0.7]) 
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
function MenuPlot_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
%UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
hhuvmat=guidata(huvmat); %handles of GUI elements in uvmat
%hplot=findobj(huvmat,'Tag','axes3');%main plotting axis of uvmat
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
if ~isempty(ObjectData.Coord)
    if isequal(option,'phys')
        ObjectData.Coord=ObjectData.Coord(:,[1:3]);
    elseif isequal(option,'px')||isequal(option,'')
        ObjectData.Coord=ObjectData.Coord(:,[4:5]);
    else
        msgbox_uvmat('ERROR','the choice in menu_coord of uvmat must be '''', px or phys ')
    end
end
axes(hhuvmat.axes3)
hh=findobj('Tag','calib_points');
if  ~isempty(ObjectData.Coord) && isempty(hh)
    hh=line(ObjectData.Coord(:,1),ObjectData.Coord(:,2),'Color','m','Tag','calib_points','LineStyle','.','Marker','+');
elseif isempty(ObjectData.Coord)%empty list of points, suppress the plot
    delete(hh)
else
    set(hh,'XData',ObjectData.Coord(:,1))
    set(hh,'YData',ObjectData.Coord(:,2))
end
pause(.1)
figure(handles.geometry_calib)

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

%------------------------------------------------------------------------
function MenuCreateGrid_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%hcalib=get(handles.calib_type,'parent');%handles of the GUI geometry_calib
CalibData=get(handles.geometry_calib,'UserData');
Tinput=[];%default
if isfield(CalibData,'grid')
    Tinput=CalibData.grid;
end
[T,CalibData.grid]=create_grid(Tinput);%display the GUI create_grid
set(handles.geometry_calib,'UserData',CalibData)

%grid in phys space
Coord=get(handles.ListCoord,'String');
val=get(handles.ListCoord,'Value');
data=read_geometry_calib(Coord);
%nbpoints=size(data.Coord,1); %nbre of calibration points
data.Coord(val:val+size(T,1)-1,1:3)=T(end:-1:1,:);%update the existing list of phys coordinates from the GUI create_grid
% for i=1:nbpoints
%    for j=1:5
%           Coord{i,j}=num2str(data.Coord(i,j),4);%display coordiantes with 4 digits
%    end
% end
%update the phys coordinates starting from the selected point (down in the
Coord(end,:)=[]; %remove last string '.....'
for i=1:size(data.Coord,1)
    for j=1:5
          Coord{i,j}=num2str(data.Coord(i,j),4);%display coordiantes with 4 digits
    end
end

%size(data.Coord,1)
Tabchar=cell2tab(Coord,' | ');
Tabchar=[Tabchar ;{'......'}];
set(handles.ListCoord,'String',Tabchar)

% -----------------------------------------------------------------------
% --- automatic grid dectection from local maxima of the images 
function MenuDetectGrid_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
CalibData=get(handles.geometry_calib,'UserData');%get information stored on the GUI geometry_calib
grid_input=[];%default
if isfield(CalibData,'grid')
    grid_input=CalibData.grid;%retrieve the previously used grid
end
[T,CalibData.grid,white_test]=create_grid(grid_input,'detect_grid');%display the GUI create_grid, read the set of phys coordinates T

set(handles.geometry_calib,'UserData',CalibData)%store the phys grid parameters for later use

%read the four last point coordinates in pixels
Coord_cell=get(handles.ListCoord,'String');%read list of coordinates on geometry_calib
data=read_geometry_calib(Coord_cell);
nbpoints=size(data.Coord,1); %nbre of calibration points
if nbpoints~=4
    msgbox_uvmat('ERROR','four points must be selected by the mouse, beginning by the new x axis, to delimitate the phs grid area')
    return
end
corners_X=(data.Coord(end:-1:end-3,4)); %pixel absissa of the four corners
corners_Y=(data.Coord(end:-1:end-3,5)); 

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

%read the current image, displayed in the GUI uvmat
huvmat=findobj(allchild(0),'Name','uvmat');
UvData=get(huvmat,'UserData');
A=UvData.Field.A;
npxy=size(A);
%linear transform on the current image
X=[CalibData.grid.x_0 CalibData.grid.x_1 CalibData.grid.x_0 CalibData.grid.x_1]';%corner absissa in the phys coordinates
Y=[CalibData.grid.y_0 CalibData.grid.y_0 CalibData.grid.y_1 CalibData.grid.y_1]';%corner ordinates in the phys coordinates

%calculate transform matrices: 
% reference: http://alumni.media.mit.edu/~cwren/interpolator/ by Christopher R. Wren
B = [ X Y ones(size(X)) zeros(4,3)        -X.*corners_X -Y.*corners_X ...
      zeros(4,3)        X Y ones(size(X)) -X.*corners_Y -Y.*corners_Y ];
B = reshape (B', 8 , 8 )';
D = [ corners_X , corners_Y ];
D = reshape (D', 8 , 1 );
%l = inv(B' * B) * B' * D;
l = (B' * B)\B' * D;
Amat = reshape([l(1:6)' 0 0 1 ],3,3)';
C = [l(7:8)' 1];

%GeometryCalib.CalibrationType='tsai';
%GeometryCalib.CoordUnit=[];% default value, to be updated by the calling function
% GeometryCalib.f=1;
% GeometryCalib.dpx=1;
% GeometryCalib.dpy=1;
% GeometryCalib.sx=1;
% GeometryCalib.Cx=0;
% GeometryCalib.Cy=0;
% GeometryCalib.kappa1=0;
% GeometryCalib.Tx=Amat(1,3);
% GeometryCalib.Ty=Amat(2,3);
% GeometryCalib.Tz=1;
% GeometryCalib.R=[Amat(1,1),Amat(1,2),0;Amat(2,1),Amat(2,2),0;C(1),C(2),0];
% 
% [Amod,Rangx,Rangy]=phys_Ima(A-min(min(A)),GeometryCalib,0);

GeometryCalib.fx_fy=[1 1];
GeometryCalib.Tx_Ty_Tz=[Amat(1,3) Amat(2,3) 1];
GeometryCalib.R=[Amat(1,1),Amat(1,2),0;Amat(2,1),Amat(2,2),0;C(1),C(2),0];
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
Amod=DataOut.A;
Rangx=DataOut.AX;
Rangy=DataOut.AY;
% GeometryCalib.dpx=1;
% GeometryCalib.dpy=1;
% GeometryCalib.sx=1;
% GeometryCalib.Cx=0;
% GeometryCalib.Cy=0;
% GeometryCalib.kappa1=0;
% GeometryCalib.Tx=Amat(1,3);
% GeometryCalib.Ty=Amat(2,3);
% GeometryCalib.Tz=1;
% GeometryCalib.R=[Amat(1,1),Amat(1,2),0;Amat(2,1),Amat(2,2),0;C(1),C(2),0];
% 
% [Amod,Rangx,Rangy]=phys_Ima(A-min(min(A)),GeometryCalib,0);

if white_test
    Amod=double(Amod);%will look for image maxima
else
    Amod=-double(Amod);%will look for image minima
end
% figure(12) %display corrected image
% Amax=max(max(Amod));
% image(Rangx,Rangy,uint8(255*Amod/Amax))

Dx=(Rangx(2)-Rangx(1))/(npxy(2)-1); %x mesh in real space
Dy=(Rangy(2)-Rangy(1))/(npxy(1)-1); %y mesh in real space
ind_range_x=ceil(abs(GeometryCalib.R(1,1)*CalibData.grid.Dx/3));% range of search of image ma around each point obtained by linear interpolation from the marked points
ind_range_y=ceil(abs(GeometryCalib.R(2,2)*CalibData.grid.Dy/3));% range of search of image ma around each point obtained by linear interpolation from the marked points
nbpoints=size(T,1);
for ipoint=1:nbpoints
    i0=1+round((T(ipoint,1)-Rangx(1))/Dx);%round(Xpx(ipoint));
    j0=1+round((T(ipoint,2)-Rangy(1))/Dy);%round(Xpx(ipoint));
    j0min=max(j0-ind_range_y,1);
    j0max=min(j0+ind_range_y,size(Amod,1));
    i0min=max(i0-ind_range_x,1);
    i0max=min(i0+ind_range_x,size(Amod,2));
    Asub=Amod(j0min:j0max,i0min:i0max);
    x_profile=sum(Asub,1);
    y_profile=sum(Asub,2);
    [Amax,ind_x_max]=max(x_profile);
    [Amax,ind_y_max]=max(y_profile);
    %sub-pixel improvement using moments
    x_shift=0;
    y_shift=0;
    %if ind_x_max+2<=2*ind_range_x+1 && ind_x_max-2>=1
    if ind_x_max+2<=numel(x_profile) && ind_x_max-2>=1
        Atop=x_profile(ind_x_max-2:ind_x_max+2);
        x_shift=sum(Atop.*[-2 -1 0 1 2])/sum(Atop);
    end
    if ind_y_max+2<=numel(y_profile) && ind_y_max-2>=1
        Atop=y_profile(ind_y_max-2:ind_y_max+2);
        y_shift=sum(Atop.*[-2 -1 0 1 2]')/sum(Atop);
    end
    Delta(ipoint,1)=(x_shift+ind_x_max+i0min-i0-1)*Dx;%shift from the initial guess
    Delta(ipoint,2)=(y_shift+ind_y_max+j0min-j0-1)*Dy;
end
Tmod=T(:,(1:2))+Delta;
[Xpx,Ypx]=px_XYZ(GeometryCalib,Tmod(:,1),Tmod(:,2));
for ipoint=1:nbpoints
     Coord{ipoint,1}=num2str(T(ipoint,1),4);%display coordiantes with 4 digits
     Coord{ipoint,2}=num2str(T(ipoint,2),4);%display coordiantes with 4 digits
     Coord{ipoint,3}=num2str(T(ipoint,3),4);%display coordiantes with 4 digits;
     Coord{ipoint,4}=num2str(Xpx(ipoint),4);%display coordiantes with 4 digits
     Coord{ipoint,5}=num2str(Ypx(ipoint),4);%display coordiantes with 4 digits
end
Tabchar=cell2tab(Coord(end:-1:1,:),' | ');
Tabchar=[Tabchar ;{'......'}];
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)
MenuPlot_Callback(hObject, eventdata, handles)

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
Tabchar=cell2tab(Coord,' | ');
Tabchar=[Tabchar; {'.....'}];
%set(handles.ListCoord,'Value',1)
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
Tabchar=cell2tab(Coord,' | ');
Tabchar=[Tabchar;{'......'}];
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)


% %------------------------------------------------------------------------
% % --- Executes on button press in rotation.
% function rotation_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% angle_rot=(pi/180)*str2num(get(handles.Phi,'String'));
% Coord_cell=get(handles.ListCoord,'String');
% data=read_geometry_calib(Coord_cell);
% data.Coord(:,1)=cos(angle_rot)*data.Coord(:,1)+sin(angle_rot)*data.Coord(:,2);
% data.Coord(:,1)=-sin(angle_rot)*data.Coord(:,1)+cos(angle_rot)*data.Coord(:,2);
% set(handles.XObject,'String',num2str(data.Coord(:,1),4));
% set(handles.YObject,'String',num2str(data.Coord(:,2),4));


%------------------------------------------------------------------------
% image transform from px to phys 
%INPUT:
%Zindex: index of plane
% function [A_out,Rangx,Rangy]=phys_Ima(A,Calib,ZIndex)
% %------------------------------------------------------------------------
% xcorner=[];
% ycorner=[];
% npx=[];
% npy=[];
% siz=size(A)
% npx=[npx siz(2)];
% npy=[npy siz(1)]
% xima=[0.5 siz(2)-0.5 0.5 siz(2)-0.5];%image coordinates of corners
% yima=[0.5 0.5 siz(1)-0.5 siz(1)-0.5];
% [xcorner,ycorner]=phys_XYZ(Calib,xima,yima,ZIndex);%corresponding physical coordinates
% Rangx(1)=min(xcorner);
% Rangx(2)=max(xcorner);
% Rangy(2)=min(ycorner);
% Rangy(1)=max(ycorner);
% test_multi=(max(npx)~=min(npx)) | (max(npy)~=min(npy)); 
% npx=max(npx);
% npy=max(npy);
% x=linspace(Rangx(1),Rangx(2),npx);
% y=linspace(Rangy(1),Rangy(2),npy);
% [X,Y]=meshgrid(x,y);%grid in physical coordiantes
% vec_B=[];
% 
% zphys=0; %default
% if isfield(Calib,'SliceCoord') %.Z= index of plane
%    SliceCoord=Calib.SliceCoord(ZIndex,:);
%    zphys=SliceCoord(3); %to generalize for non-parallel planes
% end
% [XIMA,YIMA]=px_XYZ(Calib,X,Y,zphys);%corresponding image indices for each point in the real space grid
% XIMA=reshape(round(XIMA),1,npx*npy);%indices reorganized in 'line'
% YIMA=reshape(round(YIMA),1,npx*npy);
% flagin=XIMA>=1 & XIMA<=npx & YIMA >=1 & YIMA<=npy;%flagin=1 inside the original image
% testuint8=isa(A,'uint8');
% testuint16=isa(A,'uint16');
% if numel(siz)==2 %(B/W images)
%     vec_A=reshape(A,1,npx*npy);%put the original image in line
%     ind_in=find(flagin);
%     ind_out=find(~flagin);
%     ICOMB=((XIMA-1)*npy+(npy+1-YIMA));
%     ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
%     vec_B(ind_in)=vec_A(ICOMB);
%     vec_B(ind_out)=zeros(size(ind_out));
%     A_out=reshape(vec_B,npy,npx);%new image in real coordinates
% elseif numel(siz)==3     
%     for icolor=1:siz(3)
%         vec_A=reshape(A{icell}(:,:,icolor),1,npx*npy);%put the original image in line
%         ind_in=find(flagin);
%         ind_out=find(~flagin);
%         ICOMB=((XIMA-1)*npy+(npy+1-YIMA));
%         ICOMB=ICOMB(flagin);%index corresponding to XIMA and YIMA in the aligned original image vec_A
%         vec_B(ind_in)=vec_A(ICOMB);
%         vec_B(ind_out)=zeros(size(ind_out));
%         A_out(:,:,icolor)=reshape(vec_B,npy,npx);%new image in real coordinates
%     end
% end
% if testuint8
%     A_out=uint8(A_out);
% end
% if testuint16
%     A_out=uint16(A_out);
% end

%------------------------------------------------------------------------
% pointwise transform from px to phys
%INPUT:
%Z: index of plane
% function [Xphys,Yphys,Zphys]=phys_XYZ(Calib,X,Y,Z)
% %------------------------------------------------------------------------
% if exist('Z','var')& isequal(Z,round(Z))& Z>0 & isfield(Calib,'SliceCoord')&length(Calib.SliceCoord)>=Z
%     Zindex=Z;
%     Zphys=Calib.SliceCoord(Zindex,3);%GENERALISER AUX CAS AVEC ANGLE
% else
%     Zphys=0;
% end
% if ~exist('X','var')||~exist('Y','var')
%     Xphys=[];
%     Yphys=[];%default
%     return
% end
% Xphys=X;%default
% Yphys=Y;
% %image transform
% if isfield(Calib,'R')
%     R=(Calib.R)';
%     Dx=R(5)*R(7)-R(4)*R(8);
%     Dy=R(1)*R(8)-R(2)*R(7);
%     D0=Calib.f*(R(2)*R(4)-R(1)*R(5));
%     Z11=R(6)*R(8)-R(5)*R(9);
%     Z12=R(2)*R(9)-R(3)*R(8);  
%     Z21=R(4)*R(9)-R(6)*R(7);
%     Z22=R(3)*R(7)-R(1)*R(9);
%     Zx0=R(3)*R(5)-R(2)*R(6);
%     Zy0=R(1)*R(6)-R(3)*R(4);
%     A11=R(8)*Calib.Ty-R(5)*Calib.Tz+Z11*Zphys;
%     A12=R(2)*Calib.Tz-R(8)*Calib.Tx+Z12*Zphys;
%     A21=-R(7)*Calib.Ty+R(4)*Calib.Tz+Z21*Zphys;
%     A22=-R(1)*Calib.Tz+R(7)*Calib.Tx+Z11*Zphys;
%     X0=Calib.f*(R(5)*Calib.Tx-R(2)*Calib.Ty+Zx0*Zphys);
%     Y0=Calib.f*(-R(4)*Calib.Tx+R(1)*Calib.Ty+Zy0*Zphys);
%         %px to camera:
%     Xd=(Calib.dpx/Calib.sx)*(X-Calib.Cx); % sensor coordinates
%     Yd=Calib.dpy*(Y-Calib.Cy);
%     dist_fact=1+Calib.kappa1*(Xd.*Xd+Yd.*Yd); %distortion factor
%     Xu=dist_fact.*Xd;%undistorted sensor coordinates
%     Yu=dist_fact.*Yd;
%     denom=Dx*Xu+Dy*Yu+D0;
%     % denom2=denom.*denom;
%     Xphys=(A11.*Xu+A12.*Yu+X0)./denom;%world coordinates
%     Yphys=(A21.*Xu+A22.*Yu+Y0)./denom;
% end


% --------------------------------------------------------------------
function MenuImportPoints_Callback(hObject, eventdata, handles)
fileinput=browse_xml(hObject, eventdata, handles);
if isempty(fileinput)
    return
end
[s,errormsg]=imadoc2struct(fileinput,'GeometryCalib');
GeometryCalib=s.GeometryCalib;
%GeometryCalib=load_calib(hObject, eventdata, handles)
calib=reshape(GeometryCalib.PointCoord,[],1);
for ilist=1:numel(calib)
    CoordCell{ilist}=num2str(calib(ilist));
end
CoordCell=reshape(CoordCell,[],5);
Tabchar=cell2tab(CoordCell,' | ');%transform cells into table ready for display
Tabchar=[Tabchar;{'......'}];
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)
MenuPlot_Callback(handles.geometry_calib, [], handles)

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
listfile=get(handles.coord_files,'string');
if isequal(listfile,{''})
    listfile={inputfile};
else
    listfile=[listfile;{inputfile}];%update the list of coord files
end
set(handles.coord_files,'string',listfile);

%------------------------------------------------------------------------
% --- 'key_press_fcn:' function activated when a key is pressed on the keyboard
function key_press_fcn(hObject,eventdata,handles)
%------------------------------------------------------------------------
xx=double(get(handles.geometry_calib,'CurrentCharacter')); %get the keyboard character
if ismember(xx,[8 127])%backspace or delete
    Coord_cell=get(handles.ListCoord,'String');
    val=get(handles.ListCoord,'Value');
     if max(val)<numel(Coord_cell) % the last element '...' has not been selected
        Coord_cell(val)=[];%remove the selected line
        set(handles.ListCoord,'Value',min(val)) 
        set(handles.ListCoord,'String',Coord_cell)         
        ListCoord_Callback(hObject, eventdata, handles) 
        MenuPlot_Callback(hObject,eventdata,handles)
     end
end

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
[s,errormsg]=imadoc2struct(fileinput,'GeometryCalib');
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['Error for reading ' fileinput ': '  errormsg])
    return
end
if ~isempty(s.Heading)
    Heading=s.Heading;
end
    
GeometryCalib=s.GeometryCalib;
fx=1;fy=1;Cx=0;Cy=0;kc=0; %default
%     Tabchar={};
CoordCell={};
%     kc=0;%default
%     f1=1000;
%     f2=1000;
%     hhuvmat=guidata(findobj(allchild(0),'Name','uvmat'));
%     Cx=str2num(get(hhuvmat.npx,'String'))/2;
%     Cy=str2num(get(hhuvmat.npy,'String'))/2;
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
    calib=reshape(GeometryCalib.PointCoord,[],1);
    for ilist=1:numel(calib)
        CoordCell{ilist}=num2str(calib(ilist));
    end
    CoordCell=reshape(CoordCell,[],5);
    Tabchar=cell2tab(CoordCell,' | ');%transform cells into table ready for display
    MenuPlot_Callback(handles.geometry_calib, [], handles)
end
set(handles.calib_type,'Value',val_cal)
Tabchar=[Tabchar;{'......'}];
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)

if isempty(CoordCell)% allow mouse action by default in the absence of input points
    set(handles.edit_append,'Value',1)
    set(handles.edit_append,'BackgroundColor',[1 1 0])
else % does not allow mouse action by default in the presence of input points
    set(handles.edit_append,'Value',0)
    set(handles.edit_append,'BackgroundColor',[0.7 0.7 0.7])
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


