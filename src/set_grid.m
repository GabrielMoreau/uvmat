%'set_grid':produce grid for PIV with one or two images (stereo case) 
%------------------------------------------------------------------------
% function varargout = set_grid(varargin)
% associated with the GUI set_grid.fig

%=======================================================================
% Copyright 2008-2016, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function varargout = set_grid(varargin)

% Last Modified by GUIDE v2.5 26-Jun-2015 08:54:56

% Begin initialization code - DO NOT PLOT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @set_grid_OpeningFcn, ...
                   'gui_OutputFcn',  @set_grid_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
               
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

%-------------------------------------------------------------------
% --- Executes just before set_grid is made visible.
%INPUT: 
% handles: handles of the set_grid interface elements
%'IndexObj': index of the object (on the UvData list) that set_grid will modify
%        if =[] or absent: index still undefined (create mode in uvmat)
%        if=0; no associated object (used for series), the button 'PLOT' is  then unvisible
%'data': read from an existing object selected in the interface
%      .TITLE : class of object ('POINTS','LINE',....)
%      .num_DX,num_DY,DZ; meshes for regular grids
%      .Coord: object position coordinates
%      .ParentButton: handle of the uicontrol object calling the interface
% PlotHandles: set of handles of the elements contolling the plotting of the projected field:
%  if =[] or absent, no plot (mask mode in uvmat)
% parameters on the uvmat interface (obtained by 'get_plot_handle.m')
function set_grid_OpeningFcn(hObject, eventdata, handles,InputFile,InputField)

% Choose default command line output for set_grid
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%default 
set(hObject,'DeleteFcn',@closefcn)
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%set mouse click action function
set(handles.CoordType,'ListboxTop',1)
set(handles.CoordType,'Value',1);
set(handles.CoordType,'String',{'phys';'px'});
if exist('InputFile','var')
   set(handles.ImageA,'String',InputFile)
end

%% use InputField input from uvmat
check_pixel=0;
if exist('InputField','var')
    if strcmp(InputField.CoordUnit,'pixel')
        set(handles.CoordType,'Value',2)
        set(handles.TxtWarning,'Visible','on')
        Mesh=20;%default mesh in pixel
        check_pixel=1;
    else
        set(handles.CoordType,'Value',1)
        InputField.CoordMesh=20*InputField.CoordMesh; % about 20 pixels
        % adjust the mesh to a value 1, 2 , 5 *10^n
        ord=10^(floor(log10(InputField.CoordMesh)));%order of magnitude
        if InputField.CoordMesh/ord>=5
            Mesh=5*ord;
        elseif InputField.CoordMesh/ord>=2
            Mesh=2*ord;
        else
            Mesh=ord;
        end
    end
    Input.DX=Mesh;
    Input.DY=Mesh;
    Input.XMin=(Mesh/2)*ceil(InputField.XMin/(Mesh/2))-0.5*check_pixel;
    Input.XMax=Input.XMin+Mesh*floor((InputField.XMax-Input.XMin)/Mesh)-0.5*check_pixel;
    Input.YMin=(Mesh/2)*ceil(InputField.YMin/(Mesh/2))-0.5*check_pixel;
    Input.YMax=Input.YMin+Mesh*floor((InputField.YMax-Input.YMin)/Mesh)-0.5*check_pixel;
    errormsg=fill_GUI(Input,handles.set_grid);
end

% --- Outputs from this function are returned to the command line.
function varargout = set_grid_OutputFcn(hObject, eventdata, handles)
% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;

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
[grid_pix_A,grid_pix_B,grid_phys]=get_grid(read_GUI(handles.set_grid));
huvmat=findobj(allchild(0),'tag','uvmat');
hhuvmat=guidata(huvmat);
axes(hhuvmat.PlotAxes);
hold on
UvData=get(huvmat,'UserData');
if isfield(UvData.Field, 'CoordUnit')&& strcmp(UvData.Field.CoordUnit,'pixel')
    plot(grid_pix_A(:,1),grid_pix_A(:,2),'.','Tag','proj_object')
else
    plot(grid_phys(:,1),grid_phys(:,2),'.','Tag','proj_object')
end

%% display grid in second image defined
if ~isempty(grid_pix_B)
    hviewfield=view_field(get(handles.imageB,'String'));
    hhviewfield=guidata(hviewfield);
    axes(hhviewfield.PlotAxes);
    hold on
    if isfield(UvData.Field, 'CoordUnit')&& strcmp(UvData.Field.CoordUnit,'pixel')
        plot(grid_pix_B(:,1),grid_pix_B(:,2),'.')
    else
        plot(grid_phys(:,1),grid_phys(:,2),'.')
    end
end

% --- Executes on button press in clear.
function clear_Callback(hObject, eventdata, handles)
huvmat=findobj(allchild(0),'tag','uvmat');
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
    hpoints=findobj(hhuvmat.PlotAxes,'Tag','proj_object');
    if ~isempty(hpoints)
        delete(hpoints)
    end
end
%------------------------------------------------------------------------
% --- Executes on button press in CoordType.
function CoordType_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.num_XMin,'String','')
set(handles.num_XMax,'String','')
set(handles.num_DX,'String','')
set(handles.num_YMin,'String','')
set(handles.num_YMax,'String','')
set(handles.num_DY,'String','')
set(handles.num_Z,'String','')
if isequal(get(handles.CoordType,'Value'),2)
    set(handles.TxtWarning,'visible','on')
else
    set(handles.TxtWarning,'visible','on')
end

% ------------------------------------------------------
function Save_Callback(hObject, eventdata, handles)
% ------------------------------------------------------
[grid_pix_A,grid_pix_B]=get_grid(read_GUI(handles.set_grid));


 %ECRIRE FICHIERS
nbpointsA=size(grid_pix_A);
XA=grid_pix_A(:,1);%index=position+0.5 rounded at the nearest integer value
YA=grid_pix_A(:,2);
unitcolumn=32*ones(size(XA));
Xchar=num2str(XA,'%1.1f');% write x coordinate in px, rounded at the first decimal
blanc=char(unitcolumn);
Ychar=num2str(YA,'%1.1f');% write y coordinate in px, rounded at the first decimal
tete=['1 ' num2str(nbpointsA(1))];
txt=[Xchar blanc Ychar];
textgrid={tete;txt};
textout=char(textgrid);
imageA=get(handles.ImageA,'String');
RootPath=fileparts_uvmat(imageA);
Answer = msgbox_uvmat('INPUT_TXT','grid file name (*.grid)',fullfile(RootPath,'gridA.grid'));
dlmwrite(Answer,textout,'');
msgbox_uvmat('CONFIRMATION',[Answer ' written as ASCII text file']);
if ~isempty(grid_pix_B)
    nbpointsB=size(grid_pix_B);
    XB=round(grid_pix_B(:,1)+0.5);%index=position+0.5 rounded at the nearest integer value
    YB=round(grid_pix_B(:,2)+0.5);
    unitcolumn=32*ones(size(XB));
    Xchar=num2str(XB);
    blanc=char(unitcolumn);
    Ychar=num2str(YB);
    tete=['1 ' num2str(nbpointsB(1))];
    txt=[Xchar blanc Ychar];
    textgrid={tete;txt};
    textout=char(textgrid);
    Answer = msgbox_uvmat('INPUT_TXT','grid file name (*.grid)',fullfile(RootPath,'gridB.grid'));
    dlmwrite(Answer,textout,'');
    msgbox_uvmat('CONFIRMATION',[Answer ' written as ASCII text file']);
end


%------------------------------------------------------------------------
function [grid_pix_A,grid_pix_B,grid_phys]=get_grid(GUI)
%------------------------------------------------------------------------
grid_pix_B=[];%default
array_x=GUI.XMin:GUI.DX:GUI.XMax;% array of x values
array_y=GUI.YMin:GUI.DY:GUI.YMax;% array of y values
[grid_x,grid_y]=meshgrid(array_x,array_y);% matrices of x and y values
grid_x=reshape(grid_x,[],1); %matrix of x  values reshaped in line
grid_y=reshape(grid_y,[],1);%matrix of y values reshaped in line
% grid_z=zeros(nx_patch*ny_patch,1);% plane coordinates (TODO: 3D grids)

%% check the input image A
if ~exist(GUI.ImageA,'file')
    msgbox_uvmat('ERROR',['input image file' imageA 'does not exist'])
    return
end
[FileInfo,VideoObject]=get_file_info(GUI.ImageA);
switch FileInfo.FileType
    case {'image','multimage','video','mmreader'}% case of input image or movie OK
    otherwise
        msgbox_uvmat('ERROR',['error: ' GUI.ImageA ' is not an image type recognized by Matlab '])
        return
end
[RootPath,SubDir,RootFile,tild,tild,tild,tild,FileExt]=fileparts_uvmat(GUI.ImageA);

%% transform to pixels if the grid is defined in phys coordinates
grid_x_imaA=grid_x;%default grid in image A coordinates
grid_y_imaA=grid_y;
% MenuCoord=get(handles.CoordType,'String');% type of coordinates for grid definition, phys or pixel
if strcmp(GUI.CoordType,'phys')
    fileAxml=fullfile(RootPath,[SubDir '.xml']);% new convention for xml name
    if ~exist(fileAxml,'file')
        fileAxml=[fullfile(RootPath,RootFile) '.xml'];% old convention for xml name
    end
    tsaiA=[];%default
    if exist(fileAxml,'file')
        [XmlDataA,errormsg]=imadoc2struct(fileAxml);
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',['error in ' fileAxml ': ' errormsg])
            return
        end
        if isfield(XmlDataA,'GeometryCalib')
            tsaiA=XmlDataA.GeometryCalib;
        end
    end
    if isempty(tsaiA)
        msgbox_uvmat('WARNING','no geometric calibration available for image A, phys =pixel')
    else
        [grid_x_imaA,grid_y_imaA]=px_XYZ(tsaiA,grid_x,grid_y,GUI.Z);
    end
end

%% detect the grid points which are inside image A
A=read_image(GUI.ImageA,FileInfo.FileType,VideoObject,1);
npxA=size(A,2);
npyA=size(A,1);
flag=grid_x_imaA>=1 & grid_x_imaA<=npxA & grid_y_imaA>=1 & grid_y_imaA<=npyA;% ='true' inside the image

%% detect the grid points which are inside image B if relevant (use for stereo PIV)
if isfield(GUI,'ImageB')
    if ~exist(imageB,'file')
        msgbox_uvmat('ERROR',['input image file' GUI.ImageB 'does not exist'])
        return
    end
    [RootPathB,SubDirB,RootFileB,tild,tild,tild,tild,FileExt]=fileparts_uvmat(GUI.ImageB);
    fileBxml=fullfile(RootPathB,[SubDirB '.xml']);% new convention for xml name
    if ~exist(fileBxml,'file')
        fileBxml=[fullfile(RootPathB,RootFileB) '.xml'];% old convention for xml name
    end
    tsaiB=[];%default
    if exist(fileBxml,'file')
        [XmlDataB,errormsg]=imadoc2struct(fileBxml);
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',['error in ' fileAxml ': ' errormsg])
            return
        end
        if isfield(XmlDataB,'GeometryCalib')
            tsaiB=XmlDataB.GeometryCalib;
        end
    end
    if isempty(tsaiB)
        msgbox_uvmat('WARNING','no geometric calibration available for image B, phys =pixel')
        grid_x_imaB=grid_x;
        grid_y_imaB=grid_y;
    else
        [grid_x_imaB,grid_y_imaB]=px_XYZ(tsaiB,grid_x,grid_y,GUI.Z);
    end
    B=imread(GUI.ImageB);
    npxB=size(B,2);
    npyB=size(B,1);
    flagB=grid_x_imaB>=1 & grid_x_imaB<=npxB & grid_y_imaB>=1 & grid_y_imaB<=npyB;
    flag=flagA & flagB;
    grid_pix_B(:,1)=round(grid_x_imaB(flag));
    grid_pix_B(:,2)=round(grid_y_imaB(flag));
end

grid_x_imaA=grid_x_imaA(flag);
grid_y_imaA=grid_y_imaA(flag);
grid_pix_A=[grid_x_imaA grid_y_imaA];
grid_x=grid_x(flag);
grid_y=grid_y(flag);
grid_phys=[grid_x grid_y];


function GetImageB_Callback(hObject, eventdata, handles)
if isequal(get(handles.GetImageB,'Value'),1)
    set(handles.ImageB,'Visible','on')
    [FileName, PathName, filterindex] = uigetfile( ...
            {'*.*', 'All Files (*.*)'}, ...
            'Pick the second image file',fileparts(fileparts(get(handles.ImageA,'String'))));
        ImageB=fullfile(PathName,FileName);
        [FileInfo,tild,VideoObject]=get_file_info(ImageB);
    switch FileInfo.FileType
        case {'image','multimage','video','mmreader'}% case of input image or movie OK
            set(handles.ImageB,'String',ImageB)
        otherwise
            msgbox_uvmat('ERROR',['error: ' imageB ' is not an image type recognized by Matlab '])
            return
    end
else
    set(handles.ImageB,'Visible','off')
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



function ImageA_Callback(hObject, eventdata, handles)
% hObject    handle to ImageA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ImageA as text
%        str2double(get(hObject,'String')) returns contents of ImageA as a double




