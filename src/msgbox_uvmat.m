%'msgbox_uvmat': associated with GUI msgbox_uvmat.fig to display message boxes, for error, warning or input calls
% msgbox_uvmat(title,display)
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

function varargout = msgbox_uvmat(varargin)

% Last Modified by GUIDE v2.5 24-Oct-2009 21:55:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @msgbox_uvmat_OpeningFcn, ...
                   'gui_OutputFcn',  @msgbox_uvmat_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ~isempty(regexp(varargin{1},'_Callback','once'))
    gui_State.gui_Callback = str2func(varargin{1});%for running msgbox_uvmat from a Callback
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before msgbox_uvmat is made visible.
function msgbox_uvmat_OpeningFcn(hObject, eventdata, handles,title,display,default_answer)
% This function has no output args, see OutputFcn.

% Choose default command line output for msgbox_uvmat
handles.output = 'Cancel';

% Update handles structure
guidata(hObject, handles);
testNo=0;
testCancel=1;
testinputstring=0;
icontype='quest';%default question icon (text input asked)
if exist('title','var')
      set(hObject, 'Name', title); 
      if isequal (title,'CONFIRMATION')
         icontype='';
         testCancel=0; %no cancel button
      elseif isequal (title,'ERROR')
         icontype='error';
         testCancel=0; %no cancel button
      elseif isequal (title,'WARNING')
         icontype='warn';
         testCancel=0; %no cancel button
      elseif isequal (title,'INPUT_Y-N')
         icontype='quest'; 
         testNo=1; % button No activated
      else
          testinputstring=1;
      end
end
if exist('display','var')
    set(handles.text1, 'String', display);
end
if testinputstring
    set(handles.edit_box, 'Visible', 'on');
else
    set(handles.text1, 'Position', [0.15 0.3 0.85 0.7]);
end
if exist('default_answer','var') &&  testinputstring
    set(handles.edit_box, 'String', default_answer);
end
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
if isequal(icontype,'')
    hima=findobj(handles.axes1,'Type','image');
    if ~isempty(hima)
        delete(hima)
    end
else
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
end 
if testCancel
     set(handles.Cancel,'Visible','on')
else
    set(handles.Cancel,'Visible','off')
end
if testNo
     set(handles.No,'Visible','on')
else
    set(handles.No,'Visible','off')
end   
set(handles.figure1,'WindowStyle','modal')% Make% Make the GUI modal 
% UIWAIT makes msgbox_uvmat wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = msgbox_uvmat_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
if isequal(handles.output,'Cancel')
    varargout{1}='Cancel';
elseif isequal(handles.output,'No')
    varargout{1}='No';
else
    varargout{1}=get(handles.edit_box,'String');
    if isempty(varargout{1}) || isequal(varargout{1},'')
        varargout{1}='Yes';
    end
end
% The figure can be deleted now
delete(handles.figure1);

% --- Executes on button press in OK.
function OK_Callback(hObject, eventdata, handles)
handles.output = get(hObject,'String');
guidata(hObject, handles);% Update handles structure
uiresume(handles.figure1);

% --- Executes on button press in No.
function No_Callback(hObject, eventdata, handles)
handles.output='No';
guidata(hObject, handles);
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
    handles.output = 'No';
    
    % Update handles structure
    guidata(hObject, handles);
    
    uiresume(handles.figure1);
end
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.figure1);
end    





