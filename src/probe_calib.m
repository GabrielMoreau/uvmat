%'probe_calib': performs geometric calibration from a set of reference points
function varargout = probe_calib(varargin)
% PROBE_CALIB M-file for probe_calib.fig
%      PROBE_CALIB, by itself, creates a MenuCoord PROBE_CALIB or raises the existing
%      singleton*.
%
%      H = PROBE_CALIB returns the handle to a MenuCoord PROBE_CALIB or the handle to
%      the existing singleton*.
%
%      PROBE_CALIB('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROBE_CALIB.M with the given input arguments.
%
%      PROBE_CALIB('Property','Value',...) creates a MenuCoord PROBE_CALIB or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before probe_calib_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to probe_calib_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help probe_calib

% Last Modified by GUIDE v2.5 04-Feb-2008 15:46:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @probe_calib_OpeningFcn, ...
                   'gui_OutputFcn',  @probe_calib_OutputFcn, ...
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


% --- Executes just before probe_calib is made visible.
%INPUT: 
%handles: handles of the probe_calib interface elements
% PlotHandles: set of handles of the elements contolling the plotting
% parameters on the uvmat interface (obtained by 'get_plot_handle.m')
function probe_calib_OpeningFcn(hObject, eventdata, handles, data,pos,inputfile)

% Choose default command line output for probe_calib
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%default
% set(hObject,'Unit','Normalized')% set the unit normalized to the screen size
% set(hObject,'Position',[0.7 0.1 0.25 0.5])%set the position of the probe_calib interface 
set(hObject,'DeleteFcn',@closefcn)

%set the position of the interface
if exist('pos','var')& length(pos)>2
    pos_gui=get(hObject,'Position');
    pos_gui(1)=pos(1);
    pos_gui(2)=pos(2);
    set(hObject,'Position',pos_gui);
end
% set(handles.XImage,'String','')
% set(handles.YImage,'String','')
% set(handles.XObject,'String','')
% set(handles.YObject,'String','')
% set(handles.ZObject,'String','')
inputxml='';
if exist('inputfile','var')& ~isempty(inputfile)
    [Path,Name,ext]=fileparts(inputfile);
    if isequal(ext,'.png')
        set(hObject,'UserData',inputfile)
        [Pathsub,RootFile,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(inputfile);
        inputxml=[fullfile(Pathsub,RootFile) '.xml'];
    end   
end
if exist(inputxml,'file')
    loadfile(handles,inputxml)
end
set(handles.ListCoord,'KeyPressFcn',{@key_press_fcn,handles})%set keyboard action function


% --- Outputs from this function are returned to the command line.
function varargout = probe_calib_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;

%------------
function Phi_Callback(hObject, eventdata, handles)


%-----------------------------------------------------
% --- Executes on button press in import.
function import_Callback(hObject, eventdata, handles)
%get the object file 
huvmat=findobj('Tag','uvmat');
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
    warndlg_uvmat('forbidden input file name or path: no blank character allowed','ERROR')
    return
end
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
loadfile(handles,fileinput)

%--------------------------------------------------
%read input xml file and update the edit boxes
function loadfile(handles,fileinput)

%read the input xml file
t=xmltree(fileinput);
s=convert(t);%convert to matlab structure

%read data currently displayed on the interface
PointCoord=[];
data=read_probe_calib(handles);
Coord=[]; %default
if isfield(data,'Coord')
    Coord=data.Coord;
end
TabChar_0=get(handles.ListCoord,'String');
nbcoord_0=size(TabChar_0,1);
if isequal(get(handles.edit_append,'Value'),1) %edit mode
    val=get(handles.ListCoord,'Value')-1;
else
   val=length(TabChar_0); 
end
nbcoord=0;

%case of calibration (ImaDoc) input file
if isfield(s,'GeometryCalib')
    Calib=s.GeometryCalib;
    if isfield(Calib,'SourceCalib')
        if isfield(Calib.SourceCalib,'PointCoord')
            PointCoord=Calib.SourceCalib.PointCoord;
        end
        if isfield(Calib.SourceCalib,'ImageCalib')
            hcalib=get(handles.import,'parent');
            set(hcalib,'UserData',Calib.SourceCalib.ImageCalib);%store the source image name in the interface 'UserData'
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
           line=str2num(PointCoord{i})
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
        CoordCell{iline,j}=num2str(Coord(iline,j));
    end
end
        
Tabchar=cell2tab(CoordCell,'    |    ');%transform cells into table ready for display
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)


%----------------------------------------------------
% executed when closing: set the parent interface button to value 0
function closefcn(gcbo,eventdata)
SetData=get(gcbf,'UserData');
if isfield(SetData,'ParentButton') & ishandle(SetData.ParentButton)
    set(SetData.ParentButton, 'Value',0)
end

%-----------------------------------------------------------------------
% --- Executes on button press in edit: PLOT the defined object and its projected field
function edit_Callback(hObject, eventdata, handles)
%hsetobject=get(hObject,'parent');
%SetData=get(hsetobject,'UserData');%get the hidden interface data
%IndexObj=SetData.IndexObj;%index of the current projection object in the list of projection objects (UvData.ProjObject)
huvmat=findobj(allchild(0),'name','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
hplot=findobj(huvmat,'Tag','axes3');
h_menu_coord=findobj(huvmat,'Tag','menu_coord');
menu=get(h_menu_coord,'String');
choice=get(h_menu_coord,'Value');
if iscell(menu)
    option=menu{choice};
else
    option='px'; %default
end
%get axis
%get CoordType
ObjectData=read_probe_calib(handles);%read the interface input parameters defining the object
if isequal(option,'phys')
    ObjectData.Coord=ObjectData.Coord(:,[1:3]);
elseif isequal(option,'px')
    ObjectData.Coord=ObjectData.Coord(:,[4:5]);
else
    errordlg('the choice in coord_coord must be px or phys ')
end
% [UvData,IndexObj]=update_obj(UvData,IndexObj,ObjectData,SetData.PlotHandles);
% SetData.IndexObj=IndexObj;
% set(gcbf,'UserData',SetData)%update object index in the probe_calib interface
% set(huvmat,'UserData',UvData)%update the data in the uvmat interface
ObjectData.ProjMode='none';
plot_object(ObjectData,[],hplot,'b');


% --- Executes on button press in MenuCoord.
function MenuCoord_Callback(hObject, eventdata, handles)


% --- Executes on button press in delete.
function delete_Callback(hObject, eventdata, handles)
SetData=get(gcbf,'UserData');%get the interface data
IndexObj=SetData.IndexObj;
delete_object(IndexObj);

% --- Executes on button press in calibrate_lin.
function calib_offset_Callback(hObject, eventdata, handles)
Object=read_probe_calib(handles);

%make linear calibration
% 'calibration_lin' provides a linear transform on coordinates, 
X=Object.Coord(:,1);
Y=Object.Coord(:,2);
x_ima=Object.Coord(:,4);
y_ima=Object.Coord(:,5);
[px,sx]=polyfit(X,x_ima,1);
[py,sy]=polyfit(Y,y_ima,1);
%err_X1=max(abs(x1-x_ima));%error
%err_Y1=max(abs(y1-y_ima));%error
T_x=px(2);
T_y=py(2);
GeometryCalib.focal=1;
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
GeometryCalib.ErrorMax(2)=max(abs(Ypoints-y_ima))
%calibrate_lin calibration results and point coordinates
huvmat=findobj('Tag','uvmat');
hchild=get(huvmat,'Children');
hrootpath=findobj(hchild,'Tag','RootPath');
hrootfile=findobj(hchild,'Tag','RootFile');
RootPath='';
RootFile='';
if ~isempty(hrootpath)& ~isempty(hrootfile)
    testhandle=1;
    RootPath=get(hrootpath,'String');
    RootFile=get(hrootfile,'String');
    filebase=fullfile(RootPath,RootFile);
    outputfile=[filebase '.xml'] 
else
    question={'save the calibration data and point coordinates in'};
    def={fullfile(RootPath,['ObjectCalib.xml'])};
    options.Resize='on';
    answer=inputdlg(question,'save average in a new file',1,def,options);
    outputfile=answer{1};
end
testappend=0;
if exist(outputfile,'file');%=1 if the output file already exists, 0 else  
    t=xmltree(outputfile); %read the file
    uid=find(t,'ImaDoc');
    if ~isequal(uid,1)%if the xml file is not ImaDoc, delete it (after backup)
        backupfile=outputfile;
        testexist=2;
        while testexist==2
            backupfile=[backupfile '~'];
            testexist=exist(backupfile,'file');       
        end
        [success,message]=copyfile(outputfile,backupfile);%make backup
        if isequal(success,1)
            delete(outputfile)
        else
            return
        end
    else
        uid_calib=find(t,'ImaDoc/GeometryCalib');
        if ~isempty(uid) %if GeometryCalib already exists, delete its content
            backupfile=outputfile;
            testexist=2;
            while testexist==2
                backupfile=[backupfile '~'];
                testexist=exist(backupfile,'file');      
            end
            [success,message]=copyfile(outputfile,backupfile)%make backup
            if isequal(success,1)
                delete(outputfile)
            else
                return
            end
            uid_child=children(t,uid_calib);
            t=delete(t,uid_child);
            testappend=1;
        end
    end
end
if ~testappend
    t=xmltree;
    t=set(t,1,'name','ImaDoc');
    [t,uid_calib]=add(t,1,'element','GeometryCalib');
%     t=struct2xml(GeometryCalib,t,uid_calib);
end
Object.Coord(:,[1:3])=Object.Coord(:,[1:3])*10; %transform in
GeometryCalib.SourceCalib.PointCoord=Object.Coord;
t=struct2xml(GeometryCalib,t,uid_calib); 
save(t,outputfile)

warndlg_uvmat([outputfile 'updated with linear calibration data'],'CONFIRMATION')

%display image with new calibration in the currently opened uvmat interface
Indices=get(findobj(hchild,'Tag','FileIndex'),'String');
Ext=get(findobj(hchild,'Tag','FileExt'),'String');
imagename=[fullfile(RootPath,RootFile) Indices Ext];
% input.menu_coord=1;
huvmat=uvmat(imagename,1);%open uvmat, set phys coord (Value 1)



% --- Executes on button press in calibrate_lin.
function calib_lin_Callback(hObject, eventdata, handles)
Object=read_probe_calib(handles);

%make linear calibration
% 'calibration_lin' provides a linear transform on coordinates, 
X=Object.Coord(:,1);
Y=Object.Coord(:,2);
x_ima=Object.Coord(:,4);
y_ima=Object.Coord(:,5);
XY_mat=[ones(size(X)) X Y];
a_X1=XY_mat\x_ima; %transformation matrix for X
x1=XY_mat*a_X1;%reconstruction
err_X1=max(abs(x1-x_ima));%error
a_Y1=XY_mat\y_ima;%transformation matrix for X
y1=XY_mat*a_Y1;
err_Y1=max(abs(y1-y_ima));%error
T_x=a_X1(1);
T_y=a_Y1(1);
GeometryCalib.focal=1;
GeometryCalib.Tx_Ty_Tz=[T_x T_y 1];
GeometryCalib.R=[a_X1(2),a_X1(3),0;a_Y1(2),a_Y1(3),0;0,0,1];

%check error
GeometryCalib.ErrorRms(1)=sqrt(mean((x1-x_ima).*(x1-x_ima)));
GeometryCalib.ErrorMax(1)=max(abs(x1-x_ima));
GeometryCalib.ErrorRms(2)=sqrt(mean((y1-y_ima).*(y1-y_ima)));
GeometryCalib.ErrorMax(2)=max(abs(y1-y_ima))

%calibrate_lin calibration results and point coordinates
huvmat=findobj('Tag','uvmat');
hchild=get(huvmat,'Children');
hrootpath=findobj(hchild,'Tag','RootPath');
hrootfile=findobj(hchild,'Tag','RootFile');
RootPath='';
RootFile='';
if ~isempty(hrootpath)& ~isempty(hrootfile)
    testhandle=1;
    RootPath=get(hrootpath,'String');
    RootFile=get(hrootfile,'String');
    filebase=fullfile(RootPath,RootFile);
    outputfile=[filebase '.xml']; 
else
    question={'save the calibration data and point coordinates in'};
    def={fullfile(RootPath,['ObjectCalib.xml'])};
    options.Resize='on';
    answer=inputdlg(question,'save average in a new file',1,def,options);
    outputfile=answer{1};
end
testappend=0;
if exist(outputfile,'file');%=1 if the output file already exists, 0 else  
    t=xmltree(outputfile); %read the file
    uid=find(t,'ImaDoc');
    if ~isequal(uid,1)%if the xml file is not ImaDoc, delete it (after backup)
        backupfile=outputfile;
        testexist=2;
        while testexist==2
            backupfile=[backupfile '~'];
            testexist=exist(backupfile,'file');       
        end
        [success,message]=copyfile(outputfile,backupfile)%make backup
        if isequal(success,1);
            delete(outputfile)
        else
            return
        end
    else
        uid_calib=find(t,'ImaDoc/GeometryCalib');
        if ~isempty(uid) %if GeometryCalib already exists, delete its content
            backupfile=outputfile;
            testexist=2;
            while testexist==2
                backupfile=[backupfile '~'];
                testexist=exist(backupfile,'file');      
            end
            [success,message]=copyfile(outputfile,backupfile)%make backup
            if isequal(success,1)
                delete(outputfile)
            else
                return
            end
            uid_child=children(t,uid_calib);
            t=delete(t,uid_child);
            testappend=1;
        end
    end
end
if ~testappend
    t=xmltree;
    t=set(t,1,'name','ImaDoc');
    [t,uid_calib]=add(t,1,'element','GeometryCalib');
%     t=struct2xml(GeometryCalib,t,uid_calib);
end
% Object.Coord(:,[1:3])=Object.Coord(:,[1:3]); %transform in
GeometryCalib.SourceCalib.PointCoord=Object.Coord;
t=struct2xml(GeometryCalib,t,uid_calib); 
save(t,outputfile)

warndlg_uvmat([outputfile 'updated with linear calibration data'],'CONFIRMATION')

%display image with new calibration in the currently opened uvmat interface
Indices=get(findobj(hchild,'Tag','FileIndex'),'String');
Ext=get(findobj(hchild,'Tag','FileExt'),'String');
imagename=[fullfile(RootPath,RootFile) Indices Ext];
% input.menu_coord=1;
if exist(imagename,'file')
    huvmat=uvmat(imagename,1);%open uvmat, set phys coord (Value 1)
else
    huvmat=uvmat;
end


% --- Executes on button press in translation.
function translation_Callback(hObject, eventdata, handles)


function T_x_Callback(hObject, eventdata, handles)
% hObject    handle to T_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of T_x as text
%        str2double(get(hObject,'String')) returns contents of T_x as a double





function T_y_Callback(hObject, eventdata, handles)
% hObject    handle to T_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of T_y as text
%        str2double(get(hObject,'String')) returns contents of T_y as a double


function T_z_Callback(hObject, eventdata, handles)
% hObject    handle to T_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of T_z as text
%        str2double(get(hObject,'String')) returns contents of T_z as a double


% --- Executes on button press in rotation.
function rotation_Callback(hObject, eventdata, handles)
angle_rot=(pi/180)*str2num(get(handles.Phi,'String'))
data=read_probe_calib(handles)
data.Coord(:,1)=cos(angle_rot)*data.Coord(:,1)+sin(angle_rot)*data.Coord(:,2);
data.Coord(:,1)=-sin(angle_rot)*data.Coord(:,1)+cos(angle_rot)*data.Coord(:,2);
set(handles.XObject,'String',num2str(data.Coord(:,1)));
set(handles.YObject,'String',num2str(data.Coord(:,2)));


function XImage_Callback(hObject, eventdata, handles)
update_list(hObject, eventdata,handles)

function YImage_Callback(hObject, eventdata, handles)
update_list(hObject, eventdata,handles)

function XObject_Callback(hObject, eventdata, handles)
update_list(hObject, eventdata,handles)

function YObject_Callback(hObject, eventdata, handles)
update_list(hObject, eventdata,handles)

function ZObject_Callback(hObject, eventdata, handles)
update_list(hObject, eventdata,handles)

function update_list(hObject, eventdata, handles)
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
testappend=get(handles.edit_append,'Value');
if isequal(testappend,1); %edit mode  
    val=get(handles.ListCoord,'Value');
    Coord{val}=strline;
else
    val=length(get(handles.ListCoord,'String'));
    Coord{val+1}=strline;
    set(handles.ListCoord,'Value',val+1)
% if val+1<=length(Coord)
%     set(handles.ListCoord,'Value',val+1)
%     ListCoord_Callback(hObject, eventdata, handles)
end
set(handles.ListCoord,'String',Coord)
%set(handles.ListCoord,'Value',val+1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data=read_probe_calib(handles)
data_XIma=[];
data_YIma=[];
data_XObject=[];
data_YObject=[];
data_ZObject=[];
Coord=get(handles.ListCoord,'String');
% XImage=get(handles.XImage,'String');
% YImage=get(handles.YImage,'String');
% XObject=get(handles.XObject,'String');
% YObject=get(handles.YObject,'String');
% ZObject=get(handles.ZObject,'String');
% if ischar(Xcolumn)
%     Xcolumn={Xcolumn};
% end
nb_defining_points=length(Coord);
iline=0;
for i=1:nb_defining_points
    coord_str=Coord{i};%character string of line number i
    k=findstr('|',coord_str);%find separators '|'
    data1=str2num(coord_str(1:k(1)-5));
    data2=str2num(coord_str(k(1)+5:k(2)-5));
    data3=str2num(coord_str(k(2)+5:k(3)-5));
    data4=str2num(coord_str(k(3)+5:k(4)-5));
    data5=str2num(coord_str(k(4)+5:end));
    if ~isempty(data1)|~isempty(data2)|~isempty(data3)|~isempty(data4)|~isempty(data5)
        iline=iline+1;
        if ~isempty(data1)
            data.Coord(iline,1)=data1;
        end    
        if ~isempty(data2)
            data.Coord(iline,2)=data2;
        end
        if ~isempty(data3)
            data.Coord(iline,3)=data3;
        end
        if ~isempty(data4)
            data.Coord(iline,4)=data4;
        end
        if isempty(data5)
            data.Coord(iline,5)=0;
        else
            data.Coord(iline,5)=data5;
        end
    end
end
data.Style='points';


% --- Executes on selection change in ListCoord.
function ListCoord_Callback(hObject, eventdata, handles)
% hObject    handle to ListCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns ListCoord contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ListCoord
set(handles.edit_append,'Value',1); %set to edit mode
Coord=get(handles.ListCoord,'String');
val=get(handles.ListCoord,'Value');
if length(Coord)>0
coord_str=Coord{val};
k=findstr('|',coord_str);
set(handles.XObject,'String',coord_str(1:k(1)-5))
set(handles.YObject,'String',coord_str(k(1)+5:k(2)-5))
set(handles.ZObject,'String',coord_str(k(2)+5:k(3)-5))
set(handles.XImage,'String',coord_str(k(3)+5:k(4)-5))
set(handles.YImage,'String',coord_str(k(4)+5:end))
end

%------------------------------------------------------
% --- Executes on button press in translation_plus.
function translation_plus_Callback(hObject, eventdata, handles)

T=[0 0 0];
T_x=get(handles.T_x,'String')
T_y=get(handles.T_y,'String')
T_z=get(handles.T_z,'String')
if ~isempty(T_x)
    T(1)=str2num(T_x);
end
if ~isempty(T_y)
    T(2)=str2num(T_y);
end
if ~isempty(T_z)
    T(3)=str2num(T_z);
end
translation(handles,T)



% --- Executes on button press in translation_minus.
function translation_minus_Callback(hObject, eventdata, handles)

T=[0 0 0];
T_x=get(handles.T_x,'String')
T_y=get(handles.T_y,'String')
T_z=get(handles.T_z,'String')
if ~isempty(T_x)
    T(1)=-str2num(T_x);
end
if ~isempty(T_y)
    T(2)=-str2num(T_y);
end
if ~isempty(T_z)
    T(3)=-str2num(T_z);
end
translation(handles,T)


%%%--------------------------------------
function translation(handles,T)
data=read_probe_calib(handles);
data.Coord(:,1)=T(1)+data.Coord(:,1);
data.Coord(:,2)=T(2)+data.Coord(:,2);
data.Coord(:,3)=T(3)+data.Coord(:,3);
data.Coord(:,[4 5])=data.Coord(:,[4 5]);
for i=1:size(data.Coord,1)
    for j=1:5
          Coord{i,j}=num2str(data.Coord(i,j));%phys x,y,z
   end
end
Tabchar=cell2tab(Coord,'    |    ');
set(handles.ListCoord,'String',Tabchar)

%----------------------------------------------------
% --- Executes on button press in rotation_plus.
function rotation_plus_Callback(hObject, eventdata, handles)
Phi=0;
Phi=get(handles.Phi,'String')
if ~isempty(Phi)
    Phi=str2num(Phi);
end
rotation(handles,Phi)

%-------------------------------------------------
% --- Executes on button press in rotation_minus.
function rotation_minus_Callback(hObject, eventdata, handles)
Phi=0;
Phi=get(handles.Phi,'String')
if ~isempty(Phi)
    Phi=-str2num(Phi);
end
rotation(handles,Phi)

%-----------------------------------------------------
%rotation
function rotation(handles,Phi)
O_x=str2num(get(handles.O_x,'String'));
O_y=str2num(get(handles.O_y,'String'));
if isempty(O_x)
    O_x=0;%default
end
if isempty(O_y)
    O_y=0;%default
end
data=read_probe_calib(handles);
r1=cos(pi*Phi/180);
r2=-sin(pi*Phi/180);
r3=sin(pi*Phi/180);
r4=cos(pi*Phi/180);
data.Coord(:,1)=r1*data.Coord(:,1)+r2*data.Coord(:,2);
data.Coord(:,2)=r3*data.Coord(:,1)+r4*data.Coord(:,2);
% data.Coord(:,[4 5])=data.Coord(:,[4 5]);
for i=1:size(data.Coord,1)
    for j=1:5
          Coord{i,j}=num2str(data.Coord(i,j));%phys x,y,z
   end
end
Tabchar=cell2tab(Coord,'    |    ');
set(handles.ListCoord,'String',Tabchar)

function O_x_Callback(hObject, eventdata, handles)
% hObject    handle to O_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of O_x as text
%        str2double(get(hObject,'String')) returns contents of O_x as a double



function O_y_Callback(hObject, eventdata, handles)
% hObject    handle to O_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of O_y as text
%        str2double(get(hObject,'String')) returns contents of O_y as a double


function O_z_Callback(hObject, eventdata, handles)
% hObject    handle to O_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of O_z as text
%        str2double(get(hObject,'String')) returns contents of O_z as a double







% --- Executes on selection change in edit_append.
function edit_append_Callback(hObject, eventdata, handles)
val=get(handles.edit_append,'Value');
if isequal(val,2); %append mode
    %appeler mouse
end


function NEW_Callback(hObject, eventdata, handles)
%A METTRE SOUS UN BOUTON
huvmat=findobj('name','uvmat');
hchild=get(huvmat,'children');
hcoord=findobj(hchild,'Tag','menu_coord')
coordtype=get(hcoord,'Value')
haxes=findobj(hchild,'Tag','axes3');
AxeData=get(haxes,'UserData');
if ~isequal(hcoord,2)
    set(hcoord,'Value',2)
    huvmat=uvmat(AxeData)
    'relancer uvmat'
end
if ~isfield(AxeData,'ZoomAxes')
    warndlg_uvmat('first draw a window around a grid marker','ERRROR')
    return
end 
XLim=get(AxeData.ZoomAxes,'XLim');
YLim=get(AxeData.ZoomAxes,'YLim');
np=size(AxeData.A);
ind_sub_x=round(XLim)
ind_sub_y=np(1)-round(YLim)
Mfiltre=AxeData.A([ind_sub_y(2):ind_sub_y(1)] ,ind_sub_x,:);
Mfiltre_norm=double(Mfiltre);
Mfiltre_norm=Mfiltre_norm/sum(sum(Mfiltre_norm));
Mfiltre_norm=100*(Mfiltre_norm-mean(mean(Mfiltre_norm)));
Atype=class(AxeData.A)
Data.NbDim=2;
Data.A=filter2(Mfiltre_norm,double(AxeData.A)); 
Data.A=feval(Atype,Data.A);
Data.AName='image';
Data.AX=AxeData.AX;
Data.AY=AxeData.AY;
Data.CoordType='px';
plot_field(Data)
 

% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
% hObject    handle to HELP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), errordlg('Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
   web([helpfile '#probe_calib'])
end

%'move_key:' function activated when a key is pressed on the keyboard
%-----------------------------------
function key_press_fcn(hObject,eventdata,handles)
hh=get(hObject,'parent')
xx=double(get(hh,'CurrentCharacter')) %get the keyboard character

if isequal(xx,8)%move arrow right
   data=read_probe_calib(handles);
    Coord=[]; %default
    if isfield(data,'Coord')
        Coord=data.Coord
    end
    val=get(handles.ListCoord,'Value');
    Coord(val,:)=[];
    CoordCell={};
    for iline=1:size(Coord,1)
        for j=1:5
            CoordCell{iline,j}=num2str(Coord(iline,j));
        end
    end
    Tabchar=cell2tab(CoordCell,'    |    ');%transform cells into table ready for display
    val=min(size(Coord,1),val);
    set(handles.ListCoord,'Value',max(val,1))
    set(handles.ListCoord,'String',Tabchar)  
end
