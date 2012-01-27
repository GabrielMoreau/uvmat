%'set_object': GUI to edit a projection object
%------------------------------------------------------------------------
% function hset_object= set_object(data, PlotHandles,ZBounds)
% associated with the GUI set_object.fig
%
% OUTPUT:
% hset_object: handle of the GUI figure
% 
% INPUT:
% data: structure describing the object properties
%    .Style=...
%    .ProjMode
%    .CoordType: 'phys' or 'px'
%    .num_DX,.num_DY,.num_DZ : mesh along each dirction
%    .RangeX, RangeY
%    .Coord(j,i), i=1, 2, 3,  components x, y, z of j=1...n position(s) characterizing the object components
% PlotHandles: handles for projection plots NO MORE USED
% Zbounds: bounds on Z ( 3D case)
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

function varargout = set_object(varargin)

% Last Modified by GUIDE v2.5 26-Jan-2012 22:00:47

% Begin initialization code - DO NOT PLOT
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
% End initialization code - DO NOT PLOT
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% --- Executes just before set_object is made visible.
%INPUT: 
% handles: handles of the set_object interface elements
%'IndexObj': NON USED ANYMORE (To suppress) index of the object (on the UvData list) that set_object will modify
%        if =[] or absent: index still undefined (create mode in uvmat)
%        if=0; no associated object (used for series), the button 'PLOT' is  then unvisible
%'data': read from an existing object selected in the interface
%      .Name : class of object ('POINTS','LINE',....)
%      .num_DX,num_DY,num_DZ; meshes for regular grids
%      .Coord: object position coordinates
%      .ParentButton: handle of the uicontrol object calling the interface
% PlotHandles: set of handles of the elements contolling the plotting of the projected field:
%  if =[] or absent, no plot (mask mode in uvmat)
% parameters on the uvmat interface (obtained by 'get_plot_handle.m')
function set_object_OpeningFcn(hObject, eventdata, handles, data, PlotHandles,ZBounds)
%-------------------------------------------------------------------
% Choose default command line output for set_object
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

%default
if ~exist('ZBounds','var')
    ZBounds=0; %default 
end
set(hObject,'KeyPressFcn',{'keyboard_callback',handles})%set keyboard action function (allow action on uvmat when set_object is in front)
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%set mouse click action function
enable_plot=0;%default: does not allow plot of object and projection

% fill the interface as set in the input data:
if exist('data','var') 
    if isfield(data,'enable_plot')
        enable_plot=data.enable_plot;%test to desable button PLOT (display mode)
    end
    if isfield(data,'Coord') &&size(data.Coord,2)==3
        set(handles.z_slider,'Visible','on')
    else
        set(handles.z_slider,'Visible','off')
    end
    errormsg=fill_GUI(data,handles);
%     if isfield(data,'StyleMenu')
%         set(handles.Type,'String',data.StyleMenu);
%     end
%     if isfield(data,'Type')
%         menu=get(handles.Type,'String');
%         for iline=1:length(menu)
%             if isequal(menu{iline},data.Style)
%                 set(handles.Type,'Value',iline)
%                 break
%             end
%         end
%     end
    Type_Callback(hObject, eventdata, handles)
%     if isfield(data,'ProjMenu')
%         set(handles.ProjMode,'String',data.ProjMenu);%overset the standard menu
%     end
%     if isfield(data,'ProjMode')
%         menu=get(handles.ProjMode,'String');
%         for iline=1:length(menu)
%             if isequal(menu{iline},data.ProjMode)
%                 set(handles.ProjMode,'Value',iline)
%                 break
%             end
%         end
%     end
%    ProjMode_Callback(hObject, eventdata, handles)
%     if isfield(data,'Coord')
%         if ischar(data.Coord)
%             data.Coord=str2num(data.Coord);
%         elseif iscell(data.Coord)
%             CoordCell=data.Coord;
%             data.Coord=zeros(numel(CoordCell),3);
%             data.Coord(:,3)=zeros(numel(CoordCell),1); % z component set to 0 by default
%             for iline=1:numel(CoordCell)
%                 line_vec=str2num(CoordCell{iline});
%                 if numel(line_vec)==2
%                     data.Coord(iline,1:2)=str2num(CoordCell{iline});
%                 else
%                     data.Coord(iline,:)=str2num(CoordCell{iline});
%                 end
%             end
%         end
%         if size(data.Coord,2)>=2
%             sizcoord=size(data.Coord);
%             for i=1:sizcoord(1)
%                 XObject{i}=num2str(data.Coord(i,1),4);
%                 YObject{i}=num2str(data.Coord(i,2),4);
%             end
% %             set(handles.XObject,'String',XObject)
% %             set(handles.YObject,'String',YObject)
%             if sizcoord(2)>3
%                 for i=1:sizcoord(1)
%                     ZObject{i}=num2str(data.Coord(i,3),4);
%                 end
%                 set(handles.ZObject,'String',ZObject)
%             end
%         end
%     end
%     if isfield(data,'DX')
%         if ~ischar(handles.num_DX)
%             data.DX=num2str(data.DX,3);
%         end
%         set(handles.num_DX,'String',data.DX)
%     end
%     if isfield(data,'DY')
%         if ~ischar(handles.num_DY)
%             data.DY=num2str(data.DY,3);
%         end
%         set(handles.num_DY,'String',data.DX)
%     end
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
    if isfield(data,'Angle') && isequal(numel(data.Angle),3)
         set(handles.num_Angle_1,'String',num2str(data.Angle(1)))
         set(handles.num_Angle_2,'String',num2str(data.Angle(2)))
         set(handles.num_Angle_3,'String',num2str(data.Angle(3)))
    end
%     if isfield(data,'DZ')
%         if ~ischar(handles.num_DZ)
%             data.DY=num2str(data.DZ,3);
%         end
%         set(handles.num_DZ,'String',data.DZ)
%     end
%     if isfield(data,'CoordUnit')
%         set(handles.CoordUnit,'String',data.CoordUnit)
%     end
end
if enable_plot
   set(handles.PLOT,'enable','on')
else
   set(handles.PLOT,'enable','off') 
end
huvmat=findobj(allchild(0),'tag','uvmat');
UvData=get(huvmat,'UserData');
pos_uvmat=get(huvmat,'Position');
%position the set_object GUI with respect to uvmat
if isfield(UvData,'SetObjectOrigin')
    pos_set_object(1:2)=UvData.SetObjectOrigin + pos_uvmat(1:2);
    pos_set_object(3:4)=UvData.SetObjectSize .* pos_uvmat(3:4);
    set(hObject,'Position',pos_set_object)
end


%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = set_object_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2}=handles;

%------------------------------------------------------------------------
% --- Executes on selection change in Type.
function Type_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%style_prev=get(handles.Type,'UserData');%previous object style
ListType=get(handles.Type,'String');
Type=ListType{get(handles.Type,'Value')};
% make correspondance between different object styles
Coord=get(handles.Coord,'Data');
% 
% Xcolumn=get(handles.XObject,'String');
% Ycolumn=get(handles.YObject,'String');
% if ischar(Xcolumn)
%     sizchar=size(Xcolumn);
%     for icol=1:sizchar(1)
%         Xcolumn_cell{icol}=Xcolumn(icol,:);
%     end
%     Xcolumn=Xcolumn_cell;
% end
% if ischar(Ycolumn)
%     sizchar=size(Ycolumn);
%     for icol=1:sizchar(1)
%         Ycolumn_cell{icol}=Ycolumn(icol,:);
%     end
%     Ycolumn=Ycolumn_cell;
% end
% Zcolumn={};%default
% z_new={};
% if isequal(get(handles.ZObject,'Visible'),'on')
%     %data.NbDim=3; %test 3D object
%     Zcolumn=get(handles.ZObject,'String');
%     if ischar(Zcolumn)
%         Zcolumn={Zcolumn};
%     end
% end
% x_new{1}=Xcolumn{1};
% y_new{1}=Ycolumn{1};
% x_new{1}=Coord(1,1);
% y_new{1}=Coord(1,2);
% z_new{1}=Coord(1,3);
% if ~isempty(Zcolumn)
%     z_new{1}=Zcolumn{1};
% end
% if isequal(style,'line')
%     if strcmp(style_prev,'rectangle')||strcmp(style_prev,'ellipse')
%         num_RangeX_2=get(handles.num_RangeX_2,'String');
%         num_RangeY_2=get(handles.num_RangeY_2,'String');
%         x_new{2}=num2str(num_RangeX_2,4);
%         y_new{2}=num2str(num_RangeY_2,4);
%         set(handles.XObject,'String',x_new)
%         set(handles.YObject,'String',y_new)
%         set(handles.ZObject,'String',z_new)
%     end
% elseif isequal(style,'polyline')
% elseif strcmp(style,'rectangle')|| strcmp(style,'ellipse')
%      set(handles.XObject,'String',x_new)
%      set(handles.YObject,'String',y_new)
%      set(handles.ZObject,'String',z_new)
% end

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
switch Type
    case {'points','line','polyline','plane'}
        menu_proj={'projection';'interp';'filter';'none'}; 
    case {'polygon','rectangle','ellipse'}
        menu_proj={'inside';'outside';'mask_inside';'mask_outside'};
    case 'volume'
        menu_proj={'interp';'none'};
    otherwise
        menu_proj={'projection';'interp';'filter';'none'};%default
end   
proj_index=get(handles.ProjMode,'Value');
if proj_index<numel(menu_proj)
    set(handles.ProjMode,'Value',1);% value index must not exceed the menu length
end
set(handles.ProjMode,'String',menu_proj)
ProjMode_Callback(hObject, eventdata, handles)

%store the current option
% str=get(handles.Type,'String');
% val=get(handles.Type,'Value');
% set(handles.Type,'UserData',style)

%------------------------------------------------------------------------
function xObject_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function yObject_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on selection change in zObject.
function zObject_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%------------------------------------------------------------------------
% --- Executes on selection change in ProjMode.
function ProjMode_Callback(hObject, eventdata, handles)
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
if isequal(ProjMode,'interp')
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
        set(handles.num_RangeY_2,'TooltipString','num_YMax: range of projection around each point') 
%         set(handles.XObject,'TooltipString','XObject: set of x coordinates of the points')
%         set(handles.YObject,'TooltipString','YObject: set of y coordinates of the points')
%         set(handles.ZObject,'TooltipString','ZObject: set of z coordinates of the points')
    case {'line','polyline','polygon'}
        set(handles.num_RangeY_2,'TooltipString','num_YMax: range of projection around the line')
         set(handles.Coord,'TooltipString','Coord: table of x,y, z coordinates defining the line')
%         set(handles.YObject,'TooltipString','YObject: set of y coordinates defining the line')
%         set(handles.ZObject,'TooltipString','ZObject: set of z coordinates defining the line')
        if isequal(ProjMode,'interp')|| isequal(ProjMode,'filter')
            set(handles.num_DX,'Visible','on')
            set(handles.num_DX,'TooltipString','num_DX: mesh for the interpolated field along the line')
        end       
    case {'rectangle','ellipse'}
        set(handles.num_RangeX_2,'TooltipString',['num_XMax: half length of the ' ObjectStyle])
        set(handles.num_RangeY_2,'TooltipString',['num_YMax: half width of the ' ObjectStyle])
%         set(handles.XObject,'TooltipString',['XObject:  x coordinate of the ' Type ' centre'])
%         set(handles.YObject,'TooltipString',['YObject:  y coordinate of the ' Type ' centre'])
    case {'plane'}  
        set(handles.num_Angle_3,'Visible','on')
        set(handles.num_RangeX_1,'Visible','on')
        set(handles.num_RangeX_2,'Visible','on')
        set(handles.num_RangeY_1,'Visible','on')
        set(handles.num_RangeY_2,'Visible','on')
%         set(handles.XObject,'TooltipString',['XObject:  x coordinate of the axis origin for the ' Type])
%         set(handles.YObject,'TooltipString',['YObject:  y coordinate of the axis origin for the ' Type])
        set(handles.num_RangeZ_2,'TooltipString','num_ZMax: range of projection normal to the plane')
        if test3D
            set(handles.num_Angle_2,'Visible','on')
            set(handles.num_Angle_1,'Visible','on')
            set(handles.num_RangeZ_2,'Visible','on')
        end
        if isequal(ProjMode,'interp')|| isequal(ProjMode,'filter')
            set(handles.num_DX,'Visible','on')
            set(handles.num_DY,'Visible','on')
        else
            set(handles.num_DX,'Visible','off')
            set(handles.num_DY,'Visible','off')
        end
        if  isequal(ProjMode,'interp')
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
        if isequal(ProjMode,'interp')|| isequal(ProjMode,'filter')
            set(handles.num_DX,'Visible','on')
            set(handles.num_DY,'Visible','on')
            set(handles.num_DZ,'Visible','on')
        else
            set(handles.num_DX,'Visible','off')
            set(handles.num_DY,'Visible','off')
            set(handles.num_DZ,'Visible','off')
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
%------------------------------------------------------------------------
%----------------------------------------------------
% executed when closing: set the parent interface button to value 0
function closefcn(gcbo,eventdata,parent_button)
huvmat=findobj(allchild(0),'Name','uvmat');%find the current uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
    set(hhuvmat.edit,'Value',0)
    set(hhuvmat.edit,'BackgroundColor',[0.7 0.7 0.7])%put unactivated buttons to gree
end
hseries=findobj(allchild(0),'Name','series');%find the current series interface handle
if ~isempty(hseries)
    hhseries=guidata(hseries);
    set(hhseries.GetObject,'Value',0)
    set(hhseries.GetObject,'BackgroundColor',[0 1 0])%put unactivated buttons to green
end

%------------------------------------------------------------------------
% --- Executes on button press in PLOT: PLOT the defined object and its projected field
function PLOT_Callback(hObject, eventdata, handles)

%% reading the object parameters on the GUI uvmat
huvmat=findobj('tag','uvmat');%find the current uvmat interface handle
UvData=get(huvmat,'UserData');%Data associated to the GUI uvmat 
hhuvmat=guidata(huvmat);%handles in the uvmat GUI
ListObject=get(hhuvmat.ListObject,'String');%position in the objet list
IndexObj=get(hhuvmat.ListObject,'Value');

%% read the object on the GUI set_object
%ObjectData=read_set_object(handles.set_object);%read the input parameters defining the object in the GUI set_object
ObjectData=read_GUI(handles.set_object);%read the input parameters defining the object in the GUI set_object
%ObjectData.Coord=cell2mat(ObjectData.Coord);
ObjectName=ObjectData.Name;%name of the current object defiend in set_object
if isempty(ObjectName)
    if get(hhuvmat.edit_object,'Value')% edit mode
        ObjectName=ListObject{IndexObj(end)};%take the name of the last (second) selected item
    else %new object
        StyleList=get(handles.Type,'String');
        StyleVal=get(handles.Type,'Value');
        ObjectName=StyleList{StyleVal};
    end
end
if ~get(hhuvmat.edit_object,'Value') %new object is being created
    detectname=1;
    ObjectNameNew=ObjectName;
    vers=0;
    while detectname==1
        detectname=find(strcmp(ObjectNameNew,ListObject),1);%test the existence of the proposed name in the list
        if detectname% if the object name already exists
            indstr=regexp(ObjectNameNew,'\D');
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
    IndexObj(2)=numel(ListObject)+1;% append an object to the list in uvmat
    set(hhuvmat.ListObject,'String',[ListObject;{ObjectName}]);%complement the object list
    set(hhuvmat.ListObject,'Value',IndexObj)
    UvData.Object{IndexObj(2)}=[];%initiate a new object (empty yet)
end
testnew=0;
if numel(IndexObj)==1   % if only one object is selected, the projection is in uvmat
 %       PlotHandles=hhuvmat;
    plotaxes=hhuvmat.axes3;%handle of axes3 in view_field
else  % if a second object is selected, the projection is in view_field, and this second object is selected
    hview_field=findobj(allchild(0),'tag','view_field');
    if isempty(hview_field)
        hview_field=view_field;
    end
    PlotHandles=guidata(hview_field);
    plotaxes=PlotHandles.axes3;%handle of axes3 in view_field
end 

%% naming the object
ListObject{IndexObj(end),1}=ObjectName;
set(hhuvmat.ListObject,'String',ListObject)

%% update the object plot and projection field
if testnew
    set(hhuvmat.ListObject,'Value',IndexObj)
    ObjectData.DisplayHandle_uvmat=hhuvmat.axes3;
    ObjectData.DisplayHandle_view_field=[];
else
    if IndexObj(end)<=length(UvData.Object) && isfield(UvData.Object{IndexObj(end)},'DisplayHandle_uvmat')% save the previous object graph handles
        ObjectData.DisplayHandle_uvmat=UvData.Object{IndexObj(end)}.DisplayHandle_uvmat;
    else
        ObjectData.DisplayHandle_uvmat=hhuvmat.axes3;%there is no object handle, than the axes handles is used as input
    end
    if isfield(UvData.Object{IndexObj(end)},'DisplayHandle_view_field')% save the previous object graph handles
        ObjectData.DisplayHandle_view_field=UvData.Object{IndexObj(end)}.DisplayHandle_view_field;
    else
        ObjectData.DisplayHandle_view_field=[];
    end
end
UvData.Object{IndexObj(end)}=ObjectData;%update the current object properties
if numel(IndexObj)==2
    UvData.Object=update_obj(UvData,IndexObj(1),IndexObj(2));
end
set(huvmat,'UserData',UvData)

%% plot the field projected on the object and store in the corresponding figue
[ProjData,errormsg]= proj_field(UvData.Field,ObjectData);%project the current interface field on ObjectData
if ~isempty(errormsg)
    msgbox_uvmat('ERROR', errormsg)
    return
end
fighandle=get(plotaxes,'parent');
PlotParam=read_GUI(fighandle);
[PlotType,Object_out{IndexObj(end)}.PlotParam,plotaxes]=plot_field(ProjData,plotaxes,PlotParam);%update an existing field plot

%% update the GUI uvmat
hhuvmat=guidata(huvmat);%handles of elements in the uvmat GUI
set(hhuvmat.MenuEditObject,'enable','on')
set(hhuvmat.edit_object,'Value',1) % set uvmat to object edit mode to allow further object update
set(hhuvmat.edit_object,'BackgroundColor',[1 1 0]);% paint the edit text in yellow

%------------------------------------------------------------------------
% --- Executes on button press in MenuCoord.
function MenuCoord_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
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
%Object=read_set_object(handles);
Object=read_GUI(handles.set_object);
huvmat=findobj('Tag','uvmat');
% UvData=get(huvmat,'UserData');
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
dir_save=uigetdir(RootPath);
ObjectName=get(handles.Name,'String');
if ~isempty(ObjectName)&&~strcmp(ObjectName,'')
    def={fullfile(dir_save,[ObjectName '.xml'])};
else
    def={fullfile(dir_save,[Object.Style '.xml'])};
end
displ_txt='save object as an .xml file';%default display
menu=get(handles.ProjMode,'String');
value=get(handles.ProjMode,'Value');
ProjMode=menu{value};
if strcmp(ProjMode,'mask_inside')||strcmp(ProjMode,'mask_outside')
    displ_txt='save mask contour as an .xml file: to create a mask image, use save_mask on the GUI uvmat (lower right)';
end
answer=msgbox_uvmat('INPUT_TXT','save object as an .xml file',def);
if ~isempty(answer)
    t=struct2xml(Object);
    save(t,answer{1})
end
msgbox_uvmat('CONFIRMATION',[answer{1}  ' saved'])

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

%set new plane position and update graph
% set(handles.XObject,'String',num2str(norm_plane(1)*Z_value,4))
% set(handles.YObject,'String',num2str(norm_plane(2)*Z_value,4))
% set(handles.ZObject,'String',num2str(norm_plane(3)*Z_value,4))
PLOT_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
else
    addpath (fullfile(pathelp,'uvmat_doc'))
    web([helpfile '#set_object']) 
end
%------------------------------------------------------------------------

function Name_Callback(hObject, eventdata, handles)
% hObject    handle to Name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Name as text
%        str2double(get(hObject,'String')) returns contents of Name as a double

%------------------------------------------------------------------------
% --- Executes when entered data in editable cell(s) in Coord.
function Coord_CellEditCallback(hObject, eventdata, handles)
%------------------------------------------------------------------------
ListType=get(handles.Type,'String');
Type=ListType{get(handles.Type,'Value')};
switch Type
    % add lines if multi line input needed
    case{'points','polyline','polygon'}
        Coord=get(handles.Coord,'Data');
        if isequal(size(Coord,2),3)
            Coord=[Coord;{[]} {[]} {[]}];%add a line for edition (3D case)
        else
            Coord=[Coord;{[]} {[]}]; %add a line for edition (2D case)
        end
        set(handles.Coord,'Data',Coord)
end



function num_Angle_3_Callback(hObject, eventdata, handles)
% hObject    handle to num_Angle_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_Angle_3 as text
%        str2double(get(hObject,'String')) returns contents of num_Angle_3 as a double
