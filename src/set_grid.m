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

% Last Modified by GUIDE v2.5 23-Apr-2010 15:44:47

% Begin initialization code - DO NOT PLOT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @set_grid_OpeningFcn, ...
                   'gui_OutputFcn',  @set_grid_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
% if nargin & isstr(varargin{1})
%     gui_State.gui_Callback = str2func(varargin{1});
% end
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT PLOT

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
function set_grid_OpeningFcn(hObject, eventdata, handles,inputfile,CoordType)

% Choose default command line output for set_grid
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%default
% set(hObject,'Unit','Normalized')% set the unit normalized to the screen size
% set(hObject,'Position',[0.7 0.1 0.25 0.5])%set the position of the set_grid interface 
set(hObject,'DeleteFcn',@closefcn)
% set(handles.TITLE,'Value',1)
%set(handles.ObjectStyle,'Value',1)
%set(handles.ProjMode,'Value',1)
set(handles.MenuCoord,'ListboxTop',1)
set(handles.MenuCoord,'Value',1);
set(handles.MenuCoord,'String',{'phys';'px'});
if exist('inputfile','var')& ~isempty(inputfile)
   set(handles.image_1,'String',inputfile)
   set(handles.image_2,'String',inputfile)
end
if exist('CoordType','var')
    if strcmp(CoordType,'px')
        set(handles.MenuCoord,'Value',2)
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = set_grid_OutputFcn(hObject, eventdata, handles)
% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;


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
% --- Executes on button press in plot: PLOT the defined object and its projected field
function plot_Callback(hObject, eventdata, handles)
grid_pix_A=get_grid(handles);
huvmat=uvmat(get(handles.image_1,'String'));
hhuvmat=guidata(huvmat);
set(hhuvmat.transform_fct,'Value',1)
uvmat('run0_Callback',hObject,eventdata,hhuvmat); %file input with xml reading  in uvmat
axes(hhuvmat.axes3);
hold on
plot(grid_pix_A(:,1),grid_pix_A(:,2),'.')

% --- Executes on button press in plot_2.
function plot_2_Callback(hObject, eventdata, handles)
[grid_pix_A,grid_pix_B]=get_grid(handles);
huvmat=uvmat(get(handles.image_2,'String'));
hhuvmat=guidata(huvmat);
set(hhuvmat.transform_fct,'Value',1)
uvmat('run0_Callback',hObject,eventdata,hhuvmat); %file input with xml reading  in uvmat
axes(hhuvmat.axes3);
hold on
plot(grid_pix_B(:,1),grid_pix_B(:,2),'.')



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


% ------------------------------------------------------
function save_Callback(hObject, eventdata, handles)
% ------------------------------------------------------
[grid_pix_A,grid_pix_B]=get_grid(handles);

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
imageA=get(handles.image_1,'String');
[Pathsub]=name2display(imageA);
Answer = msgbox_uvmat('INPUT_TXT','grid file name (*.grid)',fullfile(Pathsub,'gridA.grid'));
% Answer = inputdlg('grid file name (*.grid)',' ',1,{fullfile(Pathsub,'gridA.grid')},'on');
dlmwrite(Answer,textout,'');
msgbox_uvmat('CONFIRMATION',[Answer ' written as ASCII text file']);
if ~isempty(grid_pix_B)
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

%-------------------------
function [grid_pix_A,grid_pix_B]=get_grid(handles);
%Object=read_set_object(handles);%read the set_grid interface;
grid_pix_B=[];%default
DX=str2num(get(handles.DX,'String'));
DY=str2num(get(handles.DY,'String'));
XMin=str2num(get(handles.XMin,'String'));
XMax=str2num(get(handles.XMax,'String'));
YMin=str2num(get(handles.YMin,'String'));
YMax=str2num(get(handles.YMax,'String'));
array_realx=[XMin:DX:XMax];
array_realy=[YMin:DY:YMax];
nx_patch=length(array_realx);
ny_patch=length(array_realy);
[grid_realx,grid_realy]=meshgrid(array_realx,array_realy);
grid_real(:,1)=reshape(grid_realx,nx_patch*ny_patch,1);
grid_real(:,2)=reshape(grid_realy,nx_patch*ny_patch,1);
grid_real(:,3)=zeros(nx_patch*ny_patch,1);
 
imageA=get(handles.image_1,'String');
imageB=get(handles.image_2,'String');
testB=1;
if isempty(imageA) || isequal(imageA,'')
    if isempty(imageB) || isequal(imageB,'')
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
form=imformats(ext(2:end));
if isempty(form)% if the extension corresponds to an image format recognized by Matlab
     msgbox_uvmat('ERROR',['error: ' imageA ' is not an image name recognized by Matlab '])
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
MenuCoord=get(handles.MenuCoord,'String');
val=get(handles.MenuCoord,'Value');
if isempty(tsaiA)||strcmp(MenuCoord{val},'px')
    grid_imaA(:,1)=grid_real(:,1);
    grid_imaA(:,2)=grid_real(:,2);
else
    [grid_imaA(:,1),grid_imaA(:,2)]=px_XYZ(tsaiA,grid_real(:,1),grid_real(:,2),0);
end
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
         msgbox_uvmat('ERROR',['error: ' imageB ' is not an image name recognized by Matlab '])
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
if isempty(tsaiA)||strcmp(MenuCoord{val},'px')
    grid_pix_A(:,1)=grid_real2(:,1);
   grid_pix_A(:,2)= grid_real2(:,2);
else
    [grid_pix_A(:,1),grid_pix_A(:,2)]=px_XYZ(tsaiA,grid_real2(:,1),grid_real2(:,2));
end
if testB
    [grid_pix_B(:,1),grid_pix_B(:,2)]=px_XYZ(tsaiB,grid_real2(:,1),grid_real2(:,2));
end



%------------------------------------------------------------------------
% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile)), errordlg('Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
web([helpfile '#set_grid'])    
end



