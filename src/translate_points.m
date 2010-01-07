%'translate_points': associated with GUI translate_points.fig to display message boxes, for error, warning or input calls
% translate_points(title,display)
%
% OUTPUT:
% answer  (text string)= 'yes', 'No', 'cancel', or the text string introduced as input
%
%INPUT:
% title: string indicating the type of message box:
%          title= 'INPUT_TXT','CONFIMATION' ,'ERROR', 'WARNING', 'INPUT_Y-N', default = 'INPUT_TXT' (the title is displayed in the upper bar of the fig). 
%          if title='INPUT_TXT', input data is asked in an edit box
%          if title='CONFIMATION'', 'ERROR', 'WARNING', the figure remains  opened until a button 'OK' is pressed
%          if title='INPUT_Y-N', an answer Yes/No is requested
% display, displayed text
% default_answer: default answer in the edit box (only used with title='INPUT_TXT')

function varargout = translate_points(varargin)

% Last Modified by GUIDE v2.5 05-Jan-2010 09:49:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @translate_points_OpeningFcn, ...
                   'gui_OutputFcn',  @translate_points_OutputFcn, ...
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

% --- Executes just before translate_points is made visible.
function translate_points_OpeningFcn(hObject, eventdata, handles,input_shift)
% This function has no output args, see OutputFcn.

% Choose default command line output for translate_points
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

if exist('input_shift','var') && ~isempty(input_shift)
   set(handles.x_shift,'String',num2str(input_shift(1)));
   if numel(input_shift)>=2
    set(handles.y_shift,'String',num2str(input_shift(2)));
   end
   if numel(input_shift)>=3
    set(handles.z_shift,'String',num2str(input_shift(3)));
   end
end

set(handles.figure1,'WindowStyle','modal')% Make% Make the GUI modal 
% UIWAIT makes translate_points wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = translate_points_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1}=[0 0 0];%default
if ~isequal(handles.output,'Cancel')
    x_shift=str2num(get(handles.x_shift,'String'));
    y_shift=str2num(get(handles.y_shift,'String'));
    z_shift=str2num(get(handles.z_shift,'String'));
    if ~isempty(x_shift)
        varargout{1}(1)=x_shift;
    end
    if ~isempty(y_shift)
        varargout{1}(2)=y_shift;
    end
    if ~isempty(z_shift)
        varargout{1}(3)=z_shift;
    end
end
% The figure can be deleted now
delete(handles.figure1);

% --- Executes on button press in OK.
function OK_Callback(hObject, eventdata, handles)
handles.output = get(hObject,'String');
guidata(hObject, handles);% Update handles structure
uiresume(handles.figure1);

% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
handles.output = get(hObject,'String');
%handles.output = 'Cancel'
guidata(hObject, handles); % Update handles structure
% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(handles.figure1, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(handles.figure1);
else
    % The GUI is no longer waiting, just close it
    delete(handles.figure1);
end

% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, eventdata, handles)
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





