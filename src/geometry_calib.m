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

% Last Modified by GUIDE v2.5 05-Jan-2010 23:22:04

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
function geometry_calib_OpeningFcn(hObject, eventdata, handles, handles_uvmat,pos,inputfile)

% Choose default command line output for geometry_calib
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
movegui(hObject,'east');% position the GUI ton the right of the screen
if exist('handles_uvmat','var') %& isfield(data,'ParentButton')
     set(hObject,'DeleteFcn',{@closefcn,handles_uvmat})%
end
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
set(handles.ListCoord,'String',{''})
if exist(inputxml,'file')
    loadfile(handles,inputxml)% load the point coordiantes existing in the xml file
end

set(handles.ListCoord,'KeyPressFcn',{@key_press_fcn,handles})%set keyboard action function
%set(hObject,'KeyPressFcn',{'keyboard_callback',handles})%set keyboard action function on uvmat interface when geometry_calib is on top 
%htable=uitable(10,5) 
%set(htable,'ColumnNames',{'x','y','z','X(pixels)','Y(pixels)'})

% --- Outputs from this function are returned to the command line.
function varargout = geometry_calib_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;

%------------
function Phi_Callback(hObject, eventdata, handles)




%--------------------------------------------------
%read input xml file and update the edit boxes
function loadfile(handles,fileinput)

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
hcalib=get(handles.calib_type,'parent');
CalibData=get(hcalib,'UserData');
CalibData.XmlInput=fileinput;
if isfield(s,'Heading')
    CalibData.Heading=s.Heading;
end

set(hcalib,'UserData',CalibData);%store the heading in the interface 'UserData'
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
Tabchar=cell2tab(CoordCell,'    |    ');%transform cells into table ready for display
set(handles.ListCoord,'Value',1)
set(handles.ListCoord,'String',Tabchar)


%----------------------------------------------------
% executed when closing: set the parent interface button to value 0
function closefcn(gcbo,eventdata,handles_uvmat)
huvmat=findobj(allchild(0),'Name','uvmat');
if exist('handles_uvmat','var')
    set(handles_uvmat.cal,'Value',0)
    uvmat('cal_Callback',huvmat,[],handles_uvmat);
%     set(parent_button,'Value',0)%put unactivated buttons to green
%     set(parent_button,'BackgroundColor',[0 1 0]);
end


% % --- Executes on button press in MenuCoord.
% function MenuCoord_Callback(hObject, eventdata, handles)

% 
% % --- Executes on button press in delete.
% function delete_Callback(hObject, eventdata, handles)
% SetData=get(gcbf,'UserData');%get the interface data
% IndexObj=SetData.IndexObj;
% delete_object(IndexObj);


%------------------------------------------------------------------
% --- Executes on button press in calibrate_lin.
function APPLY_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
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
unitlist=get(handles.CoordUnit,'String');
unit=unitlist{get(handles.CoordUnit,'value')};
GeometryCalib.CoordUnit=unit;

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
testappend=0;
if exist(outputfile,'file');%=1 if the output file already exists, 0 else 
    t=xmltree(outputfile); %read the file
    backupfile=outputfile;
    testexist=2;
    while testexist==2
        backupfile=[backupfile '~'];% make a backup name by adding  ~ to the xml file name
        testexist=exist(backupfile,'file');
    end
    [success,message]=copyfile(outputfile,backupfile);%make backup   
    t=xmltree(outputfile); %read the file
    uid=find(t,'ImaDoc');
    if ~isequal(uid,1)%if the xml file is not ImaDoc, delete it (after backup)
        if isequal(success,1)
            delete(outputfile)
        else
            msgbox_uvmat('ERROR',['error in the backup of the existing xml file: ' message])
            return
        end
    else
        uid_calib=find(t,'ImaDoc/GeometryCalib');
        testappend=1;
        if isempty(uid_calib)
            [t,uid_calib]=add(t,1,'element','GeometryCalib');
        else %if GeometryCalib already exists, delete its content
            uid_child=children(t,uid_calib);
            t=delete(t,uid_child);
%             testappend=1;
        end
    end
end
if ~testappend %create a new xml file for calibration data
    t=xmltree;
    t=set(t,1,'name','ImaDoc');
    [t,uid_calib]=add(t,1,'element','GeometryCalib');
end
% hgrid=get(handles.REPLICATE,'parent');%read the calibration image source on the interface userdata
% imagename=get(hgrid,'UserData');
% if exist(imagename,'file')
%     GeometryCalib.SourceCalib.ImageCalib=imagename;
% end
GeometryCalib.SourceCalib.PointCoord=Object.Coord;
t=struct2xml(GeometryCalib,t,uid_calib); 
save(t,outputfile);
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

%------------------------------------------------------------------
% --- Executes on button press in calibrate_lin.
function REPLICATE_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
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
% hgrid=get(handles.REPLICATE,'parent');%read the calibration image source on the interface userdata
% imagename=get(hgrid,'UserData');
% if exist(imagename,'file')
%     GeometryCalib.SourceCalib.ImageCalib=imagename;
% end
GeometryCalib.SourceCalib.PointCoord=Object.Coord;


%root PROJETS

%open and read the dataview GUI
h_dataview=findobj(allchild(0),'name','dataview');
if ~isempty(h_dataview)
    delete(h_dataview)
end
CalibData=get(handles.figure1,'UserData');%read the calibration image source on the interface userdata
% filename='PROJETS';%default
% if isfield(CalibData,'XmlInput')
%      [pp,filename]=fileparts(CalibData.XmlInput);
% end
% while ~isequal(filename,'PROJETS') && numel(filename)>1
%     filename_1=filename;
%     pp_1=pp;
%     [pp,filename]=fileparts(pp)
% end
% projinput=fullfile(pp_1,filename_1)
% dd=dataview(projinput)

% 
% Device=[];%default
% 
% h_dataview=dataview;
% hhdataview=guidata(h_dataview);
% drawnow

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
%         set(hhdataview.RootDirectory,'String',XmlInput)
%         set(hhdataview.SubCampaignTest,'Value',1)
        SubCampaignTest='y';
        testinput=1;
    elseif isfield(Heading,'Campaign') && isequal([filename ext],Heading.Campaign)
%         set(hhdataview.RootDirectory,'String',XmlInput)
%         set(hhdataview.SubCampaignTest,'Value',0)
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
    outcome=dataview(XmlInput,SubCampaignTest,GeometryCalib)%,SubCampaignTest)
end
%     %A COMPLETER
%     dataview('RootDirectory_Callback',hObject,eventdata,hhdataview)
%     ListDevices=get(hhdataview.ListDevices,'String');
%     for ilist=1:length(ListDevices)
%         if isequal(ListDevices{ilist},Device)
%             set(hhdataview.ListDevices,'Value',ilist)
%             dataview('ListDevices_Callback',hObject,eventdata,hhdataview)
%             break
%         end
%     end

% % hhdataview=guidata(h_dataview);
% CurrentPath=get(hhdataview.RootDirectory,'String');
% ListExperiments=get(hhdataview.ListExperiments,'String');
% Value=get(hhdataview.ListExperiments,'Value');
% if ~isequal(Value,1)
%     ListExperiments=ListExperiments(Value);
% end
% ListDevices=get(hhdataview.ListDevices,'String');
% Value=get(hhdataview.ListDevices,'Value');
% if isequal(Value,1)
%     msgbox_uvmat('ERROR','manually select in the GUI dataview the device being calibrated')
%     return
% else 
%     ListDevices=ListDevices(Value);
% end
% ListRecords=get(hhdataview.ListRecords,'String');
% Value=get(hhdataview.ListRecords,'Value');
% if ~isequal(Value,1)
%     ListRecords=ListRecords(Value);
% end
% [ListDevices,ListRecords,ListXml,List]=ListDir(CurrentPath,ListExperiments,ListDevices,ListRecords);
% ListXml=get(hhdataview.ListXml,'String');
% Value=get(hhdataview.ListXml,'Value');
% if isequal(Value,1)
%     msgbox_uvmat('ERROR','you need to select in the GUI dataview the xml files to edit')
%     return
% else
%     ListXml=ListXml(Value);
% end
% 
% %update all the selected xml files
% answer=msgbox_uvmat('INPUT_Y-N',[num2str(length(Value)) ' xml files for device ' ListDevices{1} ' will be refreshed with ' calib_type ' calibration data'])
% if ~isequal(answer,'Yes')
%     return
% end
% 'TESTcalib'
% List=DataFiles.List
% for iexp=1:length(List.Experiment)
%     ExpName=List.Experiment{iexp}.name;
%     if isfield(List.Experiment{iexp},'Device')
%         for idevice=1:length(List.Experiment{iexp}.Device)
%             DeviceName=List.Experiment{iexp}.Device{idevice}.name;       
%             if isfield(List.Experiment{iexp}.Device{idevice},'xmlfile')
%                 for ixml=1:length(List.Experiment{iexp}.Device{idevice}.xmlfile)
%                     FileName=List.Experiment{iexp}.Device{idevice}.xmlfile{ixml};
%                     for ilistxml=1:length(ListXml)
%                         if isequal(FileName,ListXml{ilistxml})
%                             set(hhdataview.ListXml,'Value',Value(ilistxml))
%                             drawnow
%                             xmlfullname=fullfile(CurrentPath,ExpName,DeviceName,FileName);
%                             update_imadoc(GeometryCalib,xmlfullname)
%                             break
%                         end
%                     end
%                 end
%              elseif isfield(List.Experiment{iexp}.Device{idevice},'Record')
%                 for irecord=1:length(List.Experiment{iexp}.Device{idevice}.Record)
%                     RecordName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.name;
%                     if isfield(List.Experiment{iexp}.Device{idevice}.Record{irecord},'xmlfile')
%                         for ixml=1:length(List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile)
%                             FileName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile{ixml};
%                             for ilistxml=1:length(ListXml)
%                                 if isequal(FileName,ListXml{ilistxml})
%                                     set(hhdataview.ListXml,'Value',Value(ilistxml))
%                                     drawnow
%                                     xmlfullname=fullfile(CurrentPath,ExpName,DeviceName,RecordName,FileName);
%                                     update_imadoc(GeometryCalib,xmlfullname)
%                                     break
%                                 end
%                             end
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end
% set(hhdataview.ListXml,'Value',Value)


%-----------------------------------------------------------------
% determine the parameters for a calibration by an affine function (rescaling and offset, no rotation)
function GeometryCalib=calib_rescale(Coord)
%------------------------------------------------------------------
 
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


%------------------------------------------------------------------
% determine the parameters for a calibration by a linear transform matrix (rescale and rotation)
function GeometryCalib=calib_linear(Coord)
%------------------------------------------------------------------
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




%------------------------------------------------------------------
function GeometryCalib=calib_tsai(Coord)
%------------------------------------------------------------------
%TSAI
% 'calibration_lin' provides a linear transform on coordinates, 
path_uvmat=which('uvmat');% check the path detected for source file uvmat
path_UVMAT=fileparts(path_uvmat); %path to UVMAT
if isunix
    %fid = fopen(fullfile(path_UVMAT,'PARAM_LINUX.txt'),'r');%open the file with civ binary names
    xmlfile=fullfile(path_UVMAT,'PARAM_LINUX.xml');
    if exist(xmlfile,'file')
        t=xmltree(xmlfile);
        sparam=convert(t);
    end
else
    %fid = fopen(fullfile(path_UVMAT,'PARAM_WIN.txt'),'r');%open the file with civ binary names
    xmlfile=fullfile(path_UVMAT,'PARAM_WIN.xml');
    if exist(xmlfile,'file')
        t=xmltree(xmlfile);
        sparam=convert(t);
    end
end 
if ~isfield(sparam,'GeometryCalib_exe')
    warndlg_uvmat(['calibration program <GeometryCalib_exe> undefined in parameter file ' xmlfile],'ERROR')
    return
end
Tsai_exe=sparam.GeometryCalib_exe;
if ~exist(Tsai_exe,'file')
    warndlg_uvmat(['calibration program ' Tsai_exe ' does not exist'],'ERROR')
    return
end

textcoord=num2str(Coord,4);
dlmwrite('t.txt',textcoord,'');  
% ['!' Tsai_exe ' -f1 0 -f2 t.txt']
    eval(['!' Tsai_exe ' -f t.txt > tsaicalib.log']);
if ~exist('calib.dat','file')
    warndlg_uvmat('no output from calibration program Tsai_exe: possibly too few points','ERROR')
end
calibdat=dlmread('calib.dat');
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



% --- Executes on button press in rotation.
function rotation_Callback(hObject, eventdata, handles)
angle_rot=(pi/180)*str2num(get(handles.Phi,'String'));
Coord_cell=get(handles.ListCoord,'String');
data=read_geometry_calib(Coord_cell);
data.Coord(:,1)=cos(angle_rot)*data.Coord(:,1)+sin(angle_rot)*data.Coord(:,2);
data.Coord(:,1)=-sin(angle_rot)*data.Coord(:,1)+cos(angle_rot)*data.Coord(:,2);
set(handles.XObject,'String',num2str(data.Coord(:,1),4));
set(handles.YObject,'String',num2str(data.Coord(:,2),4));


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
val=get(handles.ListCoord,'Value');
Coord{val}=strline;
set(handles.ListCoord,'String',Coord)

%--------------------------------------------------------------------
% --- Executes on selection change in ListCoord.
%--------------------------------------------------------------------
function ListCoord_Callback(hObject, eventdata, handles)
% hObject    handle to ListCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns ListCoord contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ListCoord
%set(handles.edit_append,'Value',2); %set to edit mode
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
        warndlg_uvmat('the choice in menu_coord of uvmat must be px or phys ','ERROR')
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


%----------------------------------------------------
% --- Executes on button press in rotation_plus.
function rotation_plus_Callback(hObject, eventdata, handles)
Phi=0;
Phi=get(handles.Phi,'String');
if ~isempty(Phi)
    Phi=str2num(Phi);
end
rotation(handles,Phi)

%-------------------------------------------------
% --- Executes on button press in rotation_minus.
function rotation_minus_Callback(hObject, eventdata, handles)
Phi=0;
Phi=get(handles.Phi,'String');
if ~isempty(Phi)
    Phi=-str2num(Phi);
end
rotation(handles,Phi)



function O_x_Callback(hObject, eventdata, handles)


function O_y_Callback(hObject, eventdata, handles)


function O_z_Callback(hObject, eventdata, handles)


% --- Executes on selection change in edit_append.
function edit_append_Callback(hObject, eventdata, handles)
% val=get(handles.PLOT_append,'Value');
% if isequal(val,2); %append mode
%     %appeler mouse
% end
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


%A REVOIR
% if choice==2
%     %display image with px coordinates
%     hrootpath=findobj(huvmat,'Tag','RootPath');
%     hrootfile=findobj(huvmat,'Tag','RootFile');
%     RootPath='';
%     RootFile='';
% %     if ~isempty(hrootpath)& ~isempty(hrootfile)
%         testhandle=1;
%         RootPath=get(hrootpath,'String');
%         RootFile=get(hrootfile,'String');
% %         filebase=fullfile(RootPath,RootFile);
% %         outputfile=[filebase '.xml']; 
%         Indices=get(findobj(huvmat,'Tag','FileIndex'),'String');
%         Ext=get(findobj(huvmat,'Tag','FileExt'),'String');
%         imagename=[fullfile(RootPath,RootFile) Indices Ext];
%         % input.menu_coord=1;
%          h_menu_coord=findobj(huvmat,'Tag','menu_coord');
%         set(h_menu_coord,'Value',3)
%         huvmat=uvmat(imagename);%open uvmat, set phys coord (Value 1)
%      
% %     end
% end
    
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
    warndlg_uvmat('first draw a window around a grid marker','ERRROR')
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
 


%'key_press_fcn:' function activated when a key is pressed on the keyboard
%-----------------------------------
function key_press_fcn(hObject,eventdata,handles)
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
    PLOT_Callback(hObject,eventdata,handles)
end


% --- Executes on button press in append_point.
function append_point_Callback(hObject, eventdata, handles)

       Coord=get(handles.ListCoord,'String'); 
       val=length(Coord);
       if val>=1 & isequal(Coord{val},'')
            val=val-1; %do not take into account blank
       end
       Coord{val+1}='';
       set(handles.ListCoord,'String',Coord)
       set(handles.ListCoord,'Value',val+1)


% --------------------------------------------------------------------
function MenuOpen_Callback(hObject, eventdata, handles)
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


% --------------------------------------------------------------------
function Untitled_3_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MenuPlot_Callback(hObject, eventdata, handles)

huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
hhuvmat=guidata(huvmat); %handles of GUI elements in uvmat
hplot=findobj(huvmat,'Tag','axes3');%main plotting axis of uvmat
h_menu_coord=findobj(huvmat,'Tag','menu_coord');
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

% --------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
    helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), warndlg_uvmat('The help file uvmat_doc.html needs to be put in the directory UVMAT/UVMAT_DOC','ERROR')
else
   web([helpfile '#geometry_calib'])
end



% --------------------------------------------------------------------
function MenuCreateGrid_Callback(hObject, eventdata, handles)
hcalib=get(handles.calib_type,'parent');%handles of the GUI geometry_calib
CalibData=get(hcalib,'UserData');
Tinput=[];%default
if isfield(CalibData,'grid')
    Tinput=CalibData.grid;
end
T=create_grid(Tinput);%display translate_points GUI and get shift parameters 
CalibData.grid=T;
set(hcalib,'UserData',CalibData)

%grid in phys space
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
function MenuTranslatePoints_Callback(hObject, eventdata, handles)
hcalib=get(handles.calib_type,'parent');%handles of the GUI geometry_calib
CalibData=get(hcalib,'UserData')
Tinput=[];%default
if isfield(CalibData,'translate')
    Tinput=CalibData.translate;
end
T=translate_points(Tinput);%display translate_points GUI and get shift parameters 
CalibData.translate=T;
set(hcalib,'UserData',CalibData)
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
hcalib=get(handles.calib_type,'parent');%handles of the GUI geometry_calib
CalibData=get(hcalib,'UserData')
Tinput=[];%default
if isfield(CalibData,'rotate')
    Tinput=CalibData.rotate;
end
T=rotate_points(Tinput);%display translate_points GUI and get shift parameters 
CalibData.rotate=T;
set(hcalib,'UserData',CalibData)
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


