%'create_grid': called by the GUI geometry_calib to create a physical grid 
% coord=create_grid(input_grid)
%
% OUTPUT:
% coord: matrix (nbpoint, 3) of coordinates for grid points, with columns x,y,z
%
%INPUT:
% input_grid (optional): structure to initiate the GUI with fields .x_0,.Dx,.x_1
% (defining x coordinates), .y_0,.Dy,.y_1 (defining y coordinates)

function varargout = create_grid(varargin)

% Last Modified by GUIDE v2.5 05-Mar-2010 21:57:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @create_grid_OpeningFcn, ...
                   'gui_OutputFcn',  @create_grid_OutputFcn, ...
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
% End initialization code - DO NOT EDIT

%------------------------------------------------------------------------
% --- Executes just before create_grid is made visible.
function create_grid_OpeningFcn(hObject, eventdata, handles,input_grid)
%------------------------------------------------------------------------
% This function has no output args, see OutputFcn.

% Choose default command line output for create_grid
handles.output = 'Cancel';

% Update handles structure
guidata(hObject, handles);
testNo=0;
testCancel=1;
testinputstring=0;
icontype='quest';%default question icon (text input asked)

% Determine the position of the dialog - centered on the screen
FigPos=get(0,'DefaultFigurePosition');
OldUnits = get(hObject, 'Units');
set(hObject, 'Units', 'pixels');
OldPos = get(hObject,'Position');
FigWidth = OldPos(3);
FigHeight = OldPos(4);
ScreenUnits=get(0,'Units');
set(0,'Units','pixels');
ScreenSize=get(0,'ScreenSize');
set(0,'Units',ScreenUnits);

FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
FigPos(3:4)=[FigWidth FigHeight];
set(hObject, 'Position', FigPos);
set(hObject, 'Units', OldUnits);

% Show a question icon from dialogicons.mat - variables questIconData and questIconMap
load dialogicons.mat
eval(['IconData=' icontype 'IconData;'])
eval(['IconCMap=' icontype 'IconMap;'])
questIconMap(256,:) = get(handles.figure1, 'Color');
Img=image(IconData, 'Parent', handles.axes1);
set(handles.figure1, 'Colormap', IconCMap);
set(handles.axes1, ...
    'Visible', 'off', ...
    'YDir'   , 'reverse'       , ...
    'XLim'   , get(Img,'XData'), ...
    'YLim'   , get(Img,'YData')  ...
    );

if exist('input_grid','var') && ~isempty(input_grid)
   if isfield(input_grid,'x_0')
        set(handles.x_0,'String',num2str(input_grid.x_0));
   end
   if isfield(input_grid,'x_1')
        set(handles.x_1,'String',num2str(input_grid.x_1));
   end
   if isfield(input_grid,'Dx')
        set(handles.Dx,'String',num2str(input_grid.Dx));
   end
   if isfield(input_grid,'y_0')
        set(handles.x_0,'String',num2str(input_grid.x_0));
   end
   if isfield(input_grid,'y_1')
        set(handles.x_1,'String',num2str(input_grid.x_1));
   end
   if isfield(input_grid,'Dy')
        set(handles.Dx,'String',num2str(input_grid.Dx));
   end
   if isfield(input_grid,'z')
        set(handles.z,'String',num2str(input_grid.z));
   end  
end

set(handles.figure1,'WindowStyle','modal')% Make% Make the GUI modal 
% UIWAIT makes create_grid wait for user response (see UIRESUME)
uiwait(handles.figure1);

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = create_grid_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1}=[0 0 0];%default
if ~isequal(handles.output,'Cancel')
    x_0=str2num(get(handles.x_0,'String'));
    Dx=str2num(get(handles.Dx,'String'));
    x_1=str2num(get(handles.x_1,'String'));
    xarray=[x_0:Dx:x_1];
    y_0=str2num(get(handles.y_0,'String'));
    Dy=str2num(get(handles.Dy,'String'));
    y_1=str2num(get(handles.y_1,'String'));
    yarray=[y_0:Dy:y_1];
    [yarray,xarray]=meshgrid(yarray,xarray);
    xarray=reshape(xarray,numel(xarray),1);
    yarray=reshape(yarray,numel(yarray),1);
    z_0=str2num(get(handles.z_0,'String'));
    if isempty(z_0)
        z_0=0;
    end
    zarray=z_0*ones(size(yarray));
    varargout{1}=[xarray yarray zarray];
%     if ~isempty(x_shift)
%         varargout{1}(1)=x_shift;
%     end
%     if ~isempty(y_shift)
%         varargout{1}(2)=y_shift;
%     end
%     if ~isempty(z_shift)
%         varargout{1}(3)=z_shift;
%     end
end
% The figure can be deleted now
delete(handles.figure1);

%------------------------------------------------------------------------
% --- Executes on button press in OK.
function OK_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
handles.output = get(hObject,'String');
guidata(hObject, handles);% Update handles structure
uiresume(handles.figure1);

%------------------------------------------------------------------------
% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
handles.output = get(hObject,'String');
guidata(hObject, handles); % Update handles structure
uiresume(handles.figure1);

%------------------------------------------------------------------------
% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.figure1, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(handles.figure1);
else
    % The GUI is no longer waiting, just close it
    delete(handles.figure1);
end

%------------------------------------------------------------------------
% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    % User said no by hitting escape
    handles.output = 'Cancel';
    
    % Update handles structure
    guidata(hObject, handles);
    
    uiresume(handles.figure1);
end
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.figure1);
end    





