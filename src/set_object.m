%'set_object': GUI to edit a projection object
%------------------------------------------------------------------------
% function hset_object= set_object(data, PlotHandles,ZBounds)
% associated with the GUI set_object.fig
%
% OUTPUT:
% hset_object: handle of the GUI figure
% 
% INPUT:u
% data: structure describing the object properties
%    .Style=...
%    .ProjMode
%    .CoordType: 'phys' or 'px'
%    .num_DX,.num_DY,.num_DZ : mesh along each dirction
%    .RangeX, RangeY
%    .Coord(j,i), i=1, 2, 3,  components x, y, z of j=1...n position(s) characterizing the object components
% PlotHandles: handles for projection plots NO MORE USED
% Zbounds: bounds on Z ( 3D case)

%=======================================================================
% Copyright 2008-2015, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function varargout = set_object(varargin)

% Last Modified by GUIDE v2.5 16-Jan-2015 11:03:00

% Begin initialization code - DO NOT REFRESH
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @set_object_OpeningFcn, ...
                   'gui_OutputFcn',  @set_object_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT REFRESH
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% --- Executes just before set_object is made visible.
%INPUT: 
% handles: handles of the set_object interface elements
%'IndexObj': NON USED ANYMORE (To suppress) index of the object (on the UvData list) that set_object will modify
%        if =[] or absent: index still undefined (create mode in uvmat)
%        if=0; no associated object (used for series), the button 'REFRESH' is  then unvisible
%'data': read from an existing object selected in the interface
%      .Name : class of object ('POINTS','LINE',....)
%      .num_DX,num_DY,num_DZ; meshes for regular grids
%      .Coord: object position coordinates
%      .ParentButton: handle of the uicontrol object calling the interface
% PlotHandles: set of handles of the elements contolling the plotting of the projected field:
%  if =[] or absent, no refresh (mask mode in uvmat)
% parameters on the uvmat interface (obtained by 'get_plot_handle.m')
function set_object_OpeningFcn(hObject, eventdata, handles, data, PlotHandles,ZBounds)
%-------------------------------------------------------------------
% Choose default command line output for set_object
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

%% position
set(0,'Unit','pixels')
ScreenSize=get(0,'ScreenSize');% get the size of the screen, to put the fig on the upper right
PosGUI=get(handles.set_object,'Position');% fig width in pixels 
Width=PosGUI(3);%width of the gui set_object in pixels
Height=PosGUI(4);
Left=ScreenSize(3)- Width-40; %right edge close to the right, with margin=40 
Bottom=ScreenSize(4)-Height-40; %put fig at top right
set(handles.set_object,'Unit','pixels')
set(handles.set_object,'Position',[Left Bottom Width Height])

%default
if ~exist('ZBounds','var')
    ZBounds=0; %default 
end
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%set mouse click action function
set(hObject,'DeleteFcn',{@closefcn})

% fill the interface as set in the input data:
if exist('data','var') 
    if isfield(data,'Coord') &&size(data.Coord,2)==3
        set(handles.z_slider,'Visible','on')
    else
        set(handles.z_slider,'Visible','off')
    end
    if isfield(data,'TypeMenu')
        set(handles.Type,'String',data.TypeMenu)
    end
    if isfield(data,'ProjModeMenu')
        set(handles.ProjMode,'UserData',data.ProjModeMenu)% data.ProjModeMenu as default menu (used in Type_Callback)
    end
    errormsg=fill_GUI(data,handles.set_object);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR','bad data input in set_object')
        return
    end
    Type_Callback(hObject, eventdata, handles)% update the GUI set_object depending on the object type   
    set(handles.REFRESH,'BackgroundColor',[1 0 0])
    if isfield(data,'RangeZ') && length(ZBounds) >= 2
        set(handles.num_RangeZ_2,'String',num2str(max(data.RangeZ),3))
        DZ=max(data.RangeZ);%slider step
        if ~isnan(ZBounds(1)) && ZBounds(2)~=ZBounds(1)
            rel_step(1)=min(DZ/(ZBounds(2)-ZBounds(1)),0.2);%must be smaller than 1
            rel_step(2)=0.1;
            set(handles.z_slider,'Visible','on')
            set(handles.z_slider,'Min',ZBounds(1))
            set(handles.z_slider,'Max',ZBounds(2))
            set(handles.z_slider,'SliderStep',rel_step)
            set(handles.z_slider,'Value',(ZBounds(1)+ZBounds(2))/2)
        end
    end
    if isfield(data,'RangeX')
        if ischar(data.RangeX)
            data.RangeX=str2num(data.RangeX);
        end
        set(handles.num_RangeX_2,'String',num2str(max(data.RangeX),3))
        set(handles.num_RangeX_1,'String',num2str(min(data.RangeX),3))
    end
    if isfield(data,'RangeY')
        if ischar(data.RangeY)
            data.RangeY=str2num(data.RangeY);
        end
        set(handles.num_RangeY_2,'String',num2str(max(data.RangeY),3))
        set(handles.num_RangeY_1,'String',num2str(min(data.RangeY),3))
    end
    if isfield(data,'RangeZ')
        if ischar(data.RangeZ)
            data.RangeZ=str2num(data.RangeZ);
        end
        set(handles.num_RangeZ_2,'String',num2str(max(data.RangeZ),3))
        if numel(data.RangeZ)>=2
            set(handles.num_RangeZ_1,'String',num2str(min(data.RangeZ),3))
        end
    end  
    if ~isfield(data,'Angle')
        data.Angle=[0 0 0];
    end
%     if isfield(data,'Angle') && isequal(numel(data.Angle),3)
         set(handles.num_Angle_1,'String',num2str(data.Angle(1)))
         set(handles.num_Angle_2,'String',num2str(data.Angle(2)))
         set(handles.num_Angle_3,'String',num2str(data.Angle(3)))
%     end
end
set(get(handles.set_object,'children'),'enable','off')
set(handles.SAVE,'enable','on')
% set(handles.REFRESH,'enable','off') 


%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = set_object_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;

%------------------------------------------------------------------------
% executed when closing the GUI set_object
function closefcn(gcbo,eventdata)
%------------------------------------------------------------------------
huvmat=findobj(allchild(0),'Tag','uvmat');%find the current uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
    set(hhuvmat.CheckViewObject,'value',0)% 
    set(hhuvmat.CheckEditObject,'Value',0)% desactivate the edit option
    % deselect the object in ListObject when view_field is closed
    if isempty(findobj(allchild(0),'Tag','view_field'))
        ObjIndex=get(hhuvmat.ListObject,'Value');
        ObjIndex=ObjIndex(1);%keep only the first object selected
        set(hhuvmat.ListObject,'Value',ObjIndex)
        % draw all object colors in blue (unselected) in uvmat
        hother=[findobj(hhuvmat.PlotAxes,'Tag','proj_object');findobj(hhuvmat.PlotAxes,'Tag','DeformPoint')];%find all the proj object and deform point representations
        for iobj=1:length(hother)
            if isequal(get(hother(iobj),'Type'),'rectangle')||isequal(get(hother(iobj),'Type'),'patch')
                set(hother(iobj),'EdgeColor','b')
                if isequal(get(hother(iobj),'FaceColor'),'m')
                    set(hother(iobj),'FaceColor','b')
                end
            elseif isequal(get(hother(iobj),'Type'),'image')
                Acolor=get(hother(iobj),'CData');
                Acolor(:,:,1)=zeros(size(Acolor,1),size(Acolor,2));
                set(hother(iobj),'CData',Acolor);
            else
                set(hother(iobj),'Color','b')
            end
            set(hother(iobj),'Selected','off')
        end
    end
end
hseries=findobj(allchild(0),'Name','series');%find the current series interface handle
if ~isempty(hseries)
    hhseries=guidata(hseries);
    set(hhseries.EditObject,'Value',0)
end


%------------------------------------------------------------------------
% --- Executes on selection change in Type.
function Type_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

ListType=get(handles.Type,'String');
Type=ListType{get(handles.Type,'Value')};
% make correspondance between different object styles
Coord=get(handles.Coord,'Data');

%% set the number of lines in the Coord table depending on object type
switch Type
    case{'line'}
        if size(Coord,1)<2
            if isequal(size(Coord,2),3)
                Coord=[Coord; 0 0 0];%add a line for edition (3D case)
            else
                Coord=[Coord; 0 0]; %add a line for edition (2D case)
            end
        else
            Coord=Coord(1:2,:);
        end
    case{'rectangle','ellipse','plane','volume'}
        Coord=Coord(1,:);
end
set(handles.Coord,'Data',Coord)

%% set the projection menu and the corresponding options
if isempty(get(handles.ProjMode,'UserData'))
    switch Type
        case {'points','line','plane'}
            menu_proj={'projection';'interp_lin';'interp_tps';'none'};
        case 'polyline'
            menu_proj={'interp_lin';'interp_tps';'none'};
        case {'polygon','rectangle','ellipse'}
            menu_proj={'inside';'outside';'mask_inside';'mask_outside';'interp_lin';'interp_tps';'none'};
        case 'volume'
            menu_proj={'interp_lin';'none'};
        otherwise
            menu_proj={'projection';'interp_lin';'interp_tps';'none'};%default
    end
else
    menu_proj=get(handles.ProjMode,'UserData');
end
ProjModeList=get(handles.ProjMode,'String');
menu_index=find(strcmp(ProjModeList{get(handles.ProjMode,'Value')},menu_proj));
if isempty(menu_index)
    menu_index=1;% 
end
set(handles.ProjMode,'Value',menu_index);% value index must not exceed the menu length
set(handles.ProjMode,'String',menu_proj)
ProjMode_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on selection change in ProjMode.
%------------------------------------------------------------------------
function ProjMode_Callback(hObject, eventdata, handles)

set(handles.REFRESH,'BackgroundColor',[1 0 1])
menu=get(handles.ProjMode,'String');
value=get(handles.ProjMode,'Value');
ProjMode=menu{value};
menu=get(handles.Type,'String');
value=get(handles.Type,'Value');
ObjectStyle=menu{value};
%%%%%%%%% TODO
test3D=0; %TODO: update  test3D=isequal(get(handles.ZObject,'Visible'),'on');%3D case
%%%%%%%%%
%default setting
set(handles.num_Angle_1,'Visible','off')
set(handles.num_Angle_2,'Visible','off')
set(handles.num_Angle_3,'Visible','off')
set(handles.num_RangeX_1,'Visible','off')
set(handles.num_RangeX_2,'Visible','off')
set(handles.num_RangeY_1,'Visible','off')
if isequal(ProjMode,'interp_lin')|| isequal(ProjMode,'interp_tps')
    set(handles.num_RangeY_2,'Visible','off')
else
    set(handles.num_RangeY_2,'Visible','on')
end
if strcmp(ObjectStyle,'rectangle')||strcmp(ObjectStyle,'ellipse')
    set(handles.num_RangeX_2,'Visible','on')
else
   set(handles.num_RangeX_2,'Visible','off')
end
set(handles.num_RangeZ_1,'Visible','off')
set(handles.num_RangeZ_2,'Visible','off')
set(handles.num_DX,'Visible','off')
set(handles.num_DY,'Visible','off')
set(handles.num_DZ,'Visible','off')

switch ObjectStyle
    case 'points'
        set(handles.num_RangeY_2,'TooltipString','num_RangeY_2: range of projection around each point') 
%         set(handles.XObject,'TooltipString','XObject: set of x coordinates of the points')
%         set(handles.YObject,'TooltipString','YObject: set of y coordinates of the points')
%         set(handles.ZObject,'TooltipString','ZObject: set of z coordinates of the points')
    case {'line','polyline','polygon'}
        set(handles.num_RangeY_2,'TooltipString','num_RangeY_2: range of projection around the line')
         set(handles.Coord,'TooltipString','Coord: table of x,y, z coordinates defining the line')
%         set(handles.YObject,'TooltipString','YObject: set of y coordinates defining the line')
%         set(handles.ZObject,'TooltipString','ZObject: set of z coordinates defining the line')
        if isequal(ProjMode,'interp_lin')|| isequal(ProjMode,'interp_tps')
            set(handles.num_DX,'Visible','on')
            set(handles.num_DX,'TooltipString','num_DX: mesh for the interpolated field along the line')
        end       
    case {'rectangle','ellipse'}
        set(handles.num_RangeX_2,'TooltipString',['num_RangeX_2: half length of the ' ObjectStyle])
        set(handles.num_RangeY_2,'TooltipString',['num_RangeY_2: half width of the ' ObjectStyle])
    case {'plane'}  
        set(handles.num_Angle_3,'Visible','on')
        set(handles.num_RangeX_1,'Visible','on')
        set(handles.num_RangeX_2,'Visible','on')
        set(handles.num_RangeY_1,'Visible','on')
        set(handles.num_RangeY_2,'Visible','on')
        set(handles.num_RangeZ_2,'TooltipString','num_ZMax: range of projection normal to the plane')
        if test3D
            set(handles.num_Angle_2,'Visible','on')
            set(handles.num_Angle_1,'Visible','on')
            set(handles.num_RangeZ_2,'Visible','on')
        end
        if isequal(ProjMode,'interp_lin')|| isequal(ProjMode,'interp_tps')
            set(handles.num_DX,'Visible','on')
            set(handles.num_DY,'Visible','on')
        else
            set(handles.num_DX,'Visible','off')
            set(handles.num_DY,'Visible','off')
        end
        if  isequal(ProjMode,'interp_lin')
            set(handles.num_DZ,'Visible','on')  
        end
     case {'volume'}  
        set(handles.num_RangeX_1,'Visible','on')
        set(handles.num_RangeX_2,'Visible','on')
        set(handles.num_RangeY_1,'Visible','on')
        set(handles.num_RangeY_2,'Visible','on')
        set(handles.XObject,'TooltipString',['XObject:  x coordinate of the axis origin for the ' ObjectStyle])
        set(handles.YObject,'TooltipString',['YObject:  y coordinate of the axis origin for the ' ObjectStyle])
        set(handles.num_Angle_1,'Visible','on')
        set(handles.num_Angle_2,'Visible','on')
        set(handles.num_Angle_3,'Visible','on')
        set(handles.num_RangeZ_1,'Visible','on')
        set(handles.num_RangeZ_2,'Visible','on')
        if isequal(ProjMode,'interp_lin')|| isequal(ProjMode,'interp_tps')
            set(handles.num_DX,'Visible','on')
            set(handles.num_DY,'Visible','on')
            set(handles.num_DZ,'Visible','on')
        else
            set(handles.num_DX,'Visible','off')
            set(handles.num_DY,'Visible','off')
            set(handles.num_DZ,'Visible','off')
        end
end
% set default values read in the plot of uvmat to initiate the mesh 
if isequal(ProjMode,'interp_lin')|| isequal(ProjMode,'interp_tps')
    if isempty(str2num(get(handles.num_DX,'String')))||isempty(str2num(get(handles.num_DY,'String')));     
        huvmat=findobj('Tag','uvmat');%find the current uvmat interface handle
        UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
        Field=UvData.Field;
        if  isfield(UvData.Field,'CoordMesh')&&~isempty(UvData.Field.CoordMesh)
            set(handles.num_DX,'String',num2str(UvData.Field.CoordMesh))
            set(handles.num_DY,'String',num2str(UvData.Field.CoordMesh))
            set(handles.num_RangeX_1,'String',num2str(UvData.Field.XMin))
            set(handles.num_RangeX_2,'String',num2str(UvData.Field.XMax))
            set(handles.num_RangeY_1,'String',num2str(UvData.Field.YMin))
            set(handles.num_RangeY_2,'String',num2str(UvData.Field.YMax))
        end
        if isempty(get(handles.CoordUnit,'String'))
            set(handles.CoordUnit,'String',Field.CoordUnit)
        end       
    end
end

%------------------------------------------------------------------------

%------------------------------------------------------------------------
function num_Angle_1_Callback(hObject, eventdata, handles)
update_slider(hObject, eventdata,handles)
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function num_Angle_2_Callback(hObject, eventdata, handles)
update_slider(hObject, eventdata,handles)
%------------------------------------------------------------------------
function update_slider(hObject, eventdata,handles)
%rotation angles
PlaneAngle(1)=str2num(get(handles.num_Angle_1,'String'));%first  angle in degrees
PlaneAngle(2)=str2num(get(handles.num_Angle_2,'String'));%second  angle in degrees
PlaneAngle(3)=str2num(get(handles.num_Angle_3,'String'));%second  angle in degrees
om=norm(PlaneAngle);%norm of rotation angle in radians
OmAxis=PlaneAngle/om; %unit vector marking the rotation axis
cos_om=cos(pi*om/180);
sin_om=sin(pi*om/180);
coeff=OmAxis(3)*(1-cos_om);
%components of the unity vector norm_plane normal to the projection plane
norm_plane(1)=OmAxis(1)*coeff+OmAxis(2)*sin_om;
norm_plane(2)=OmAxis(2)*coeff-OmAxis(1)*sin_om;
norm_plane(3)=OmAxis(3)*coeff+cos_om;
huvmat=findobj('Tag','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
if isfield(UvData,'X') & isfield(UvData,'Y') & isfield(UvData,'Z')
    Z=norm_plane(1)*(UvData.X)+norm_plane(2)*(UvData.Y)+norm_plane(3)*(UvData.Z);
    set(handles.z_slider,'Min',min(Z))
    set(handles.z_slider,'Max',max(Z))
    ZMax_Callback(hObject, eventdata, handles)
end
%------------------------------------------------------------------------
function num_DX_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function num_DY_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%------------------------------------------------------------------------
function num_DZ_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------


%------------------------------------------------------------------------
% --- Executes on button press in REFRESH: refresh the current object , refresh the object and its projected field
%------------------------------------------------------------------------
function REFRESH_Callback(hObject, eventdata, handles)

set(handles.REFRESH,'BackgroundColor',[1 1 0])% indicate activation of REFRESH
drawnow

%% update the object in the GUI series if relevant
if strcmp(get(handles.set_object,'Name'),'edit_object_series')
    hseries=findobj(allchild(0),'Tag','series');
    if ~isempty(hseries)
        SeriesData=get(hseries,'UserData');
    SeriesData.ProjObject=read_GUI(handles.set_object);%read the parameters defining the object in the GUI set_object
    set(hseries,'UserData',SeriesData);
    end
    set(handles.REFRESH,'BackgroundColor',[1 0 0])
    return
end

%% read the object parameters in the GUI set_object
ObjectData=read_GUI(handles.set_object);%read the parameters defining the object in the GUI set_object
if isfield(ObjectData,'CoordLine')% remove CoordLine (not used as object feature)
    ObjectData=rmfield(ObjectData,'CoordLine');
end
if iscell(ObjectData.Coord)%check for empty line
    ObjectData.Coord=[0 0 0];
    hhset_object=guidata(handles.set_object);
    set(hhset_object.Coord,'Data',ObjectData.Coord)
end
checknan=isnan(sum(ObjectData.Coord,2));%check for NaN lines
if ~isempty(checknan)
    ObjectData.Coord(checknan,:)=[];%remove the NaN lines
end
ObjectName=ObjectData.Name;%name of the current object defined in set_object
if isempty(ObjectName)
     ObjectName=ObjectData.Type;% name the object by the object type type by default
end

%% read the current object selection in the GUI uvmat
huvmat=findobj('tag','uvmat');%find the current uvmat GUI handle
UvData=get(huvmat,'UserData');%Data associated to the GUI uvmat 
hhuvmat=guidata(huvmat);%handles of the objects children of the  GUI uvmat
ListObject=get(hhuvmat.ListObject,'String');% list of objects displayed in uvmat

if isequal(get(hhuvmat.CheckEditObject,'Value'),0) %we append a new object
    ListObject=[ListObject;{''}];
    IndexObj=length(ListObject);
    set(hhuvmat.ListObject,'String',ListObject)
    set(hhuvmat.ListObject,'Value',IndexObj)
    UvData.ProjObject{IndexObj}=[]; %create a new empty object
    UvData.ProjObject{IndexObj}.DisplayHandle.uvmat=hhuvmat.PlotAxes; % axes for plot_object
    UvData.ProjObject{IndexObj}.DisplayHandle.view_field=[]; %no plot handle before plot_field operation
else    
    IndexObj=get(hhuvmat.ListObject,'Value');% index of the selected object for display in uvmat
end

%set or modify(edit mode) the name of the currently selected object
detectname=1;
ObjectNameNew=ObjectName;
vers=0;% index of the name
ListOther=ListObject;
ListOther(IndexObj)=[];
while ~isempty(detectname)
    detectname=find(strcmp(ObjectNameNew,ListOther),1);%test the existence of the proposed name in the list
    if detectname% if the object name already exists
        indstr=regexp(ObjectNameNew,'\D');%indices of non number characters
        if indstr(end)<length(ObjectNameNew) %object name ends by a number
            vers=str2double(ObjectNameNew(indstr(end)+1:end))+1;
            ObjectNameNew=[ObjectNameNew(1:indstr(end)) num2str(vers)];
        else
            vers=vers+1;
            ObjectNameNew=[ObjectNameNew(1:indstr(end)) '_' num2str(vers)];
        end
    end
end
ObjectName=ObjectNameNew;
set(handles.Name,'String',ObjectName)% display the default name in set_object
ListObject{IndexObj}=ObjectName;
set(hhuvmat.ListObject,'String',ListObject);%complement the object list
set(hhuvmat.ListObject_1,'String',ListObject);%complement the object list
set(hhuvmat.CheckViewObject,'Value',1)% indicate that the currently selected objected is viewed on set_object
check_handle=isfield(UvData.ProjObject{IndexObj},'DisplayHandle') && isfield(UvData.ProjObject{IndexObj}.DisplayHandle,'uvmat')...
    && ~isempty(UvData.ProjObject{IndexObj}.DisplayHandle.uvmat) && ishandle(UvData.ProjObject{IndexObj}.DisplayHandle.uvmat);
if check_handle
    obj_handle=UvData.ProjObject{IndexObj}.DisplayHandle.uvmat;
end
UvData.ProjObject{IndexObj}=ObjectData;%record the current object properties in uvmat
if check_handle
    UvData.ProjObject{IndexObj}.DisplayHandle.uvmat=obj_handle; %preserve the object plot handle if valid
else
    UvData.ProjObject{IndexObj}.DisplayHandle.uvmat=hhuvmat.PlotAxes; %axes taken as object display handle by defualt
end

%% refresh the field projected on the object
hview_field=[];%default
IndexObj_1=get(hhuvmat.ListObject_1,'Value');
if strcmp(ObjectData.ProjMode,'mask_inside')||strcmp(ObjectData.ProjMode,'mask_outside')||strcmp(ObjectData.ProjMode,'none')
    PlotType='text';
else
    % create tps coeff if needed for ProjMode 'interp_tps'
    if strcmp(ObjectData.ProjMode,'interp_tps')&&~isfield(UvData.Field,'Coord_tps')
        %UvData.Field=calc_tps(UvData.Field,1);
        [UvData.Field,errormsg]=tps_coeff_field(UvData.Field,1);
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR', ['set_object/tps_coeff_field/' errormsg])
            set(handles.REFRESH,'enable','on')
            return
        end
    end
    [ProjData,errormsg]= proj_field(UvData.Field,ObjectData);%project the current field of uvmat on ObjectData
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR', ['set_object/proj_field/' errormsg])
        set(handles.REFRESH,'enable','on')
        return
    end
    if isequal(IndexObj_1,IndexObj) % if  the projection is in uvmat
        PlotType=plot_field(ProjData,hhuvmat.PlotAxes,read_GUI(get(hhuvmat.PlotAxes,'parent')));%update the current uvmat plot
    else  % if the projection is in view_field
        hview_field=findobj(allchild(0),'tag','view_field');
        if isempty(hview_field)
            hview_field=view_field(ProjData); %open the view_field GUI for plot
        else
            hhview_field=guidata(hview_field);
            [PlotType,PlotParam]=plot_field(ProjData,hhview_field.PlotAxes,read_GUI(hview_field));%update an existing  plot in view_field
            errormsg=fill_GUI(PlotParam,hview_field);
            if ~isempty(errormsg)
                msgbox_uvmat('ERROR',errormsg)
                return
            end
            %     write_plot_param(hhview_field,PlotParam); %update the display of plotting parameters for the current object
        end
        haxes=findobj(hview_field,'tag','axes3');
        Data=get(hview_field,'UserData');
        if strcmp(get(haxes,'Visible'),'off')%sempty(PlotParam.Coordinates)% case of no plot display (pure text table)
            h_TableDisplay=findobj(hview_field,'tag','TableDisplay');
            pos_table=get(h_TableDisplay,'Position');
            pos=get(hview_field,'Position');
            set(hview_field,'Position',[pos(1)+pos(3)-pos_table(3) pos(2)+pos(4)-pos_table(4) pos_table(3) pos_table(4)])
            drawnow
            set(hview_field,'UserData',Data);% restore the previously stored GUI position after GUI resizing
        else
            set(hview_field,'Position',Data.GUISize)
        end
    end
end

%% update the object refresh 
hobject=UvData.ProjObject{IndexObj}.DisplayHandle.uvmat;
% if we are editing the object used for projection in uvmat
if isequal(IndexObj_1,IndexObj)
    %update the representation of the current object for projection field represented in view_field
    for iobj=1:numel(UvData.ProjObject)
        UvData.ProjObject{iobj}.DisplayHandle.uvmat=...
            plot_object(UvData.ProjObject{iobj},UvData.ProjObject{IndexObj_1},UvData.ProjObject{iobj}.DisplayHandle.uvmat,'b');
    end
else %  we are editing the object used for projection field represented in view_field
    %update the representation of the current object in uvmat
    UvData.ProjObject{IndexObj}.DisplayHandle.uvmat=...
             plot_object(UvData.ProjObject{IndexObj},UvData.ProjObject{IndexObj_1},UvData.ProjObject{IndexObj}.DisplayHandle.uvmat,'m');
    %indicate the object index in the user data of the object refresh (needed for further mouse editing)
    ObjectInfo=get(UvData.ProjObject{IndexObj}.DisplayHandle.uvmat,'UserData');
    ObjectInfo.IndexObj=IndexObj;
    set(UvData.ProjObject{IndexObj}.DisplayHandle.uvmat,'UserData',ObjectInfo)
    % update the representation of all objects in view_field
    for iobj=1:numel(UvData.ProjObject)
        if isfield(UvData.ProjObject{iobj},'DisplayHandle') && isfield(UvData.ProjObject{iobj}.DisplayHandle,'view_field')
            UvData.ProjObject{iobj}.DisplayHandle.view_field=...
                plot_object(UvData.ProjObject{iobj},UvData.ProjObject{iobj},UvData.ProjObject{iobj}.DisplayHandle.view_field,'b');
        end
    end
end
set(huvmat,'UserData',UvData)

%% update the GUI uvmat
set(hhuvmat.CheckEditObject,'Value',1) % set uvmat to object edit mode to allow further object update
set(hhuvmat.CheckViewField,'Value',1)

set(handles.REFRESH,'BackgroundColor',[1 0 0])
set(handles.num_RangeY_2,'BackgroundColor',[1 1 1])

% --- Executes on button press in DisplayCoord.
function DisplayCoord_Callback(hObject, eventdata, handles)
global Coord
Coord=get(handles.Coord,'Data');
evalin('base','global Coord')%make Coord global in the workspace
display('object coordinates:')
evalin('base','Coord') %display Coord in the workspace
commandwindow; %brings the Matlab command window to the front

%----------------------------------------------------
function num_RangeY_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

function num_RangeZ_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

function num_RangeZ_2_Callback(hObject, eventdata, handles)
DZ=str2num(get(handles.num_RangeZ_2,'String'));
ZMin=get(handles.z_slider,'Min');
ZMax=get(handles.z_slider,'Max');
if ~isequal(ZMax-ZMin,0)
    rel_step(1)=DZ/(ZMax-ZMin);
    rel_step(2)=0.2;
    set(handles.z_slider,'SliderStep',rel_step)
end
%------------------------------------------------------------------------
function num_RangeY_2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

function num_RangeX_1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

function num_RangeX_2_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
%------------------------------------------------------------------------
function SAVE_Callback(hObject, eventdata, handles)
% ------------------------------------------------------
Object=read_GUI(handles.set_object);
if isfield(Object,'CoordLine')% remove CoordLine (not used as object feature)
    Object=rmfield(Object,'CoordLine');
end
huvmat=findobj('Tag','uvmat');
if isempty(huvmat)
    huvmat=findobj(allchild(0),'Name','series');
end
hchild=get(huvmat,'Children');
hrootpath=findobj(hchild,'Tag','RootPath');
if isempty(hrootpath)
    RootPath='';
else
    RootPath=get(hrootpath,'String');
    if iscell(RootPath)
        RootPath=RootPath{1};
    end
end
title={'object name'};
dir_save=uigetfile_uvmat('select the folder for the new xml object file:',RootPath,'uigetdir');
if ~isempty(dir_save)
    ObjectName=get(handles.Name,'String');
    if ~isempty(ObjectName)&&~strcmp(ObjectName,'')
        def=[ObjectName '.xml'];
    else
        def=[Object.Style '.xml'];
    end
    displ_txt={['save object in' dir_save]; 'with file name (.xml):'};%default display
    menu=get(handles.ProjMode,'String');
    value=get(handles.ProjMode,'Value');
    ProjMode=menu{value};
    if strcmp(ProjMode,'mask_inside')||strcmp(ProjMode,'mask_outside')
        displ_txt=[displ_txt; '(note: to create a mask image, use ''Tools/make mask'' on the upper bar menu of uvmat)'];
    end
    answer=msgbox_uvmat('INPUT_TXT',displ_txt,def);
    if ischar(answer)
        FullName=fullfile(dir_save,answer);
        t=struct2xml(Object);
        t=set(t,1,'name','ProjObject');
        save(t,FullName)
        msgbox_uvmat('CONFIRMATION',[FullName  ' saved'])
    end
end

%------------------------------------------------------------------------
% --- Executes on slider movement.
function z_slider_Callback(hObject, eventdata, handles)
%---------------------------------------------------------
Z_value=get(handles.z_slider,'Value');
%rotation angles
PlaneAngle=[0 0 0]; 
norm_plane=[0 0 1];
cos_om=1;
sin_om=0;

PlaneAngle(1)=str2double(get(handles.num_Angle_1,'String'));%first  angle in degrees
PlaneAngle(2)=str2double(get(handles.num_Angle_2,'String'));%second  angle in degrees
PlaneAngle(3)=str2double(get(handles.num_Angle_3,'String'));%second  angle in degrees
PlaneAngle=(pi/180)*PlaneAngle;
om=norm(PlaneAngle);%norm of rotation angle in radians
if isequal(om,0)
    norm_plane=[0 0 1];
else
    OmAxis=PlaneAngle/om; %unit vector marking the rotation axis
    cos_om=cos(om);
    sin_om=sin(om);
    coeff=OmAxis(3)*(1-cos_om);
    %components of the unity vector norm_plane normal to the projection plane
    norm_plane(1)=OmAxis(1)*coeff+OmAxis(2)*sin_om;
    norm_plane(2)=OmAxis(2)*coeff-OmAxis(1)*sin_om;
    norm_plane(3)=OmAxis(3)*coeff+cos_om;
end
Coord=get(handles.Coord,'Data');
Coord(3)=Z_value;
set(handles.Coord,'Data',Coord)

% update graph
REFRESH_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
web('http://servforge.legi.grenoble-inp.fr/projects/soft-uvmat/wiki/UvmatHelp#ProjObject')

%------------------------------------------------------------------------ 
% --- Executes when selected cell(s) is changed in ListCoord.
%------------------------------------------------------------------------ 
function Coord_CellSelectionCallback(hObject, eventdata, handles)
if ~isempty(eventdata.Indices)
    iline=eventdata.Indices(1);% selected line number
    set(handles.CoordLine,'String',num2str(iline))
end


function num_Angle_3_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on key press with selection of a uicontrol
%------------------------------------------------------------------------
function KeyPressFcn(hObject, eventdata, handles)
set(handles.REFRESH,'BackgroundColor',[1 0 1])% se REFRESH to magenta color, indicates that refresh needs to be done
if strcmp(get(hObject,'Tag'),'num_Angle_3')
    set(handles.num_RangeX_1,'String','')
    set(handles.num_RangeX_2,'String','')
        set(handles.num_RangeY_1,'String','')
    set(handles.num_RangeY_2,'String','')
end

%------------------------------------------------------------------------
% --- Executes on key press with focus on Coord and none of its controls.
%------------------------------------------------------------------------
function Coord_KeyPressFcn(hObject, eventdata, handles)

set(handles.REFRESH,'BackgroundColor',[1 0 1])
xx=double(get(handles.set_object,'CurrentCharacter')); %get the keyboard character
if ismember(xx,[127 31])% delete, or downward
    Coord=get(handles.Coord,'Data');
    iline=str2double(get(handles.CoordLine,'String'));
            if isequal(xx, 31)
                if isequal(iline,size(Coord,1))% arrow downward
                Coord=[Coord;zeros(1,size(Coord,2))];
                end
            else
    Coord(iline,:)=[];% suppress the current line 
            end
    set(handles.Coord,'Data',Coord);
end

%------------------------------------------------------------------------
% --- Executes on button press in clear_line.
%------------------------------------------------------------------------
function clear_line_Callback(hObject, eventdata, handles)

Coord=get(handles.Coord,'Data');
iline=str2double(get(handles.CoordLine,'String'));
if isempty(iline)
    msgbox_uvmat('WARNING','no line suppressed, select a line in the table')
else
    Coord(iline,:)=[];
    set(handles.REFRESH,'BackgroundColor',[1 0 1])
    set(handles.Coord,'Data',Coord);
    set(handles.CoordLine,'String','')
    REFRESH_Callback(hObject,eventdata,handles)
end
