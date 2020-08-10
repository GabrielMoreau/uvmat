%'get_field': display variables and attributes from a Netcdf file, and OK selected fields
%------------------------------------------------------------------------
% GetFieldData=get_field(FileName,ParamIn)
% associated with the GUI get_field.fig
%
% OUTPUT:
% GetFieldData: structure containing the information on the selected
%      fields, obtained by applying the fct red_GUI to the GUI get_field
%   .FieldOption='vectors': variables are used for vector plot
%                  'scalar': variables are used for scalar plot, 
%                  '1Dplot': variables are used for usual x-y plot,
%                  'civdata...': go back to automatic reading of civ data
%   .PanelVectors: sub-structure variables used as vector components
%   .PanelScalar:
% INPUT:
% FileName: name (including path) of the netcdf file to open
% ParmIn: structure containing parameters for preselecting menus:
%   .Title: set the title of the GUI get_field
%   .SwitchVarIndexTime='file index','variable' or 'matrix index': select the default option for 'time'
%   .TimeAttrName: preselect the name of a global attribute for time
%   .SeriesInput=1 if get_field is called by the GUI series,=0 otherwise (plot options provided in the latter case)
%   .Coord_x,.Coord_y,.Coord_z, names of the variables used as the three coordinates
%   .scalar : set the default choise of the scale variable
%   .vector_x, .vector_y : set the default choise for the variables used for the x and y vector components

%=======================================================================
% Copyright 2008-2020, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function varargout = get_field(varargin)

% Last Modified by GUIDE v2.5 18-Feb-2015 23:42:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @get_field_OpeningFcn, ...
                   'gui_OutputFcn',  @get_field_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})&& ~isempty(regexp(varargin{1},'_Callback','once'))
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
      
%------------------------------------------------------------------------
% --- Executes just before get_field is made visible.
%------------------------------------------------------------------------
function get_field_OpeningFcn(hObject, eventdata, handles,filename,ParamIn)

%% GUI settings
handles.output = 'Cancel';
guidata(hObject, handles);
set(hObject,'WindowButtonDownFcn',{'mouse_down'}) % allows mouse action with right button (zoom for uicontrol display)
set(hObject,'CloseRequestFcn',{@closefcn,handles})

%% enter input data
if ischar(filename) % input file name
    set(handles.inputfile,'String',filename)% fill the input file name
    [Field,tild,tild,errormsg]=nc2struct(filename,[]);% reads the  field structure, without the variables
else
    msgbox_uvmat('ERROR','get_field requires a file name as input')% display error message for input file reading
    return
end
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['get_field/nc2struct/' errormsg])% display error message for input file reading
    return
end
if ~isfield(Field,'ListVarName')
    msgbox_uvmat('ERROR',['no variable found in ' filename])% display error message for input file reading
    return
end
if ~exist('ParamIn','var')
    ParamIn.Coord_z='';
end

%% look at singletons and variables with a single dimension
Field.Display=Field;
Field.Check0D=zeros(size(Field.ListVarName));% =1 for arrays with a single value
NbVar=numel(Field.VarDimName);%nbre of variables in the input data
for ilist=1:NbVar
    if ischar(Field.VarDimName{ilist})
        Field.VarDimName{ilist}={Field.VarDimName{ilist}}; %transform string into cell
    end
    NbDim=numel(Field.VarDimName{ilist});
    check_singleton=false(1,NbDim);%  check singleton, false by default
    for idim=1:NbDim
        dim_index=strcmp(Field.VarDimName{ilist}{idim},Field.ListDimName);%index in the list of dimensions
        check_singleton(idim)=isequal(Field.DimValue(dim_index),1);%check_singleton=1 for singleton
    end
    Field.Check0D(ilist)=(isequal(check_singleton,ones(1,NbDim)))||(~isequal(Field.VarType(ilist),4)&&~isequal(Field.VarType(ilist),5)&&~isequal(Field.VarType(ilist),6));% =1 if the variable reduces to a single value
    if ~Field.Check0D(ilist)
    Field.Display.VarDimName{ilist}=Field.VarDimName{ilist}(~check_singleton);% eliminate singletons in the list of variable dimensions
    end
end
if ~isfield(Field,'VarAttribute')
    Field.VarAttribute={};
end
if numel(Field.VarAttribute)<NbVar% complement VarAttribute by blanjs if neded
    Field.VarAttribute(numel(Field.VarAttribute)+1:NbVar)=cell(1,NbVar-numel(Field.VarAttribute));
end
% Field.Display = list of variables and corresponding properties obtained after removal of variables with a single value and singleton dimensions
Field.Display.ListVarName=Field.ListVarName(~Field.Check0D); %list of variables available for plots, after eliminating variables with a single value
Field.Display.VarAttribute=Field.VarAttribute(~Field.Check0D);
Field.Display.VarDimName=Field.Display.VarDimName(~Field.Check0D);
Field.Display.ListDimName=Field.ListDimName(Field.DimValue~=1);% list of non singleton dimension names
Field.Display.DimValue=Field.DimValue(Field.DimValue~=1);% corresponding list of non singleton dimension values


%% analyse the input field cells
[CellInfo,NbDim,errormsg]=find_field_cells(Field.Display);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['get_field / Field_input / find_field_cells: ' errormsg])
    return
end
if isempty(CellInfo)
    [Field.MaxDim,imax]=max(cellfun(@numel,Field.Display.VarDimName));% maximum number of dimensions for the input fields
    ListDim=Field.Display.VarDimName{imax};
    check_cellinfo=false;
else
    [Field.MaxDim,imax]=max(NbDim);% maximum number of dimensions for the input fields identified by attributes
    check_cellinfo=true;
end

%% set time mode
ListSwitchVarIndexTime={'file index'};% default setting: the time is the file index
% look at global attributes with numerical values
check_numvalue=false(1,numel(Field.ListGlobalAttribute));
for ilist=1:numel(Field.ListGlobalAttribute)
    Value=Field.(Field.ListGlobalAttribute{ilist});
    check_numvalue(ilist)=isnumeric(Value);
end
Field.Display.ListGlobalAttribute=Field.ListGlobalAttribute(check_numvalue);% select the attributes with float numerical value
if ~isempty(Field.Display.ListGlobalAttribute)
    ListSwitchVarIndexTime=[ListSwitchVarIndexTime; {'attribute'}];% the time can be chosen as a global attribute
end

Check_index=0;
if Field.MaxDim>=2
    ListSwitchVarIndexTime=[ListSwitchVarIndexTime;{'variable'};{'matrix index'}];% the time can be chosen as a dim index
else
    for ilist=1:numel(Field.Display.VarDimName)
        NbComponent=numel(Field.Display.VarDimName{ilist});
        if NbComponent>=2% multicomponent matrices without coordinate variables (thus not considered in the fct find_field_cell)
            ListSwitchVarIndexTime=[ListSwitchVarIndexTime;{'matrix index'}];% the time can be chosen as a dim index
            Check_index=1;
            break
        end
    end
end

%% select the Time attribute from input
if Field.MaxDim >2
    variable_index=find(strcmp('variable',ListSwitchVarIndexTime),1);
    set(handles.SwitchVarIndexTime,'Value',variable_index);
else
    if isfield(ParamIn,'TimeAttrName')&& ~isempty(ParamIn.TimeAttrName)
        time_index=find(strcmp(ParamIn.TimeAttrName,Field.Display.ListGlobalAttribute),1);
    else
        time_index=find(strcmp('Time',Field.Display.ListGlobalAttribute));% look for global attribute containing name 'Time'
    end
    if isempty(time_index)
        set(handles.SwitchVarIndexTime,'Value',1);
    else
        set(handles.SwitchVarIndexTime,'Value',2);
        set(handles.TimeName,'UserData',time_index)
    end
end
set(handles.SwitchVarIndexTime,'String',ListSwitchVarIndexTime)
set(handles.SwitchVarIndexTime,'UserData',ListSwitchVarIndexTime); % keep string in memory for check3D
set(handles.get_field,'UserData',Field);% record the finput field structure
SwitchVarIndexTime_Callback([], [], handles)

%% set vector menu (priority) if detected or scalar menu for space dim >=2, or usual (x,y) plot for 1D fields
set(handles.vector_x,'String',Field.Display.ListVarName)% fill the menu of x vector components
set(handles.vector_y,'String',Field.Display.ListVarName)% fill the menu of y vector components
set(handles.vector_z,'String',[{''} Field.Display.ListVarName])% fill the menu of y vector components
set(handles.vec_color,'String',[{''} Field.Display.ListVarName])% fill the menu of y vector components
set(handles.scalar,'Value',1)% fill the menu of y vector components
set(handles.scalar,'String',Field.Display.ListVarName)% fill the menu for scalar
%set(handles.ordinate,'Value',1)% fill the menu of y vector components
%set(handles.ordinate,'String',Field.Display.ListVarName)% fill the menu of y coordinate for 1D plots
checkseries=0;
if isfield(ParamIn,'SeriesInput') && ParamIn.SeriesInput% case of call by series
    set(handles.FieldOption,'value',1)
    if isfield(Field,'Conventions')&& strcmp(Field.Conventions,'uvmat/civdata')
    set(handles.FieldOption,'String',{'scalar';'vectors';'civdata...'})
    else
       set(handles.FieldOption,'String',{'scalar';'vectors'}) 
    end
    checkseries=1;
    set(handles.scalar,'Max',2)
elseif isfield(Field,'Conventions')&& strcmp(Field.Conventions,'uvmat/civdata')
    set(handles.FieldOption,'String',{'1D plot';'scalar';'vectors';'civdata...'})% provides the possibility to come back to civdata
    set(handles.scalar,'Max',1)
else
    set(handles.FieldOption,'String',{'1D plot';'scalar';'vectors'})
    set(handles.scalar,'Max',1)
end

%% set default field options
checknbdim=cellfun('size',Field.Display.VarDimName,2);
% if max(checknbdim)<=1
%     Field.MaxDim=1;% only 1D fields, considered as a time series by default
% end
if Field.MaxDim>=2 && ~checkseries% case of 2D (or 3D) fields
    check_vec_input=0;
    % case of vector initially selected from uvmat input
    if isfield(ParamIn,'vector_x')&& isfield(ParamIn,'vector_y')
        ichoice_x=find(strcmp(ParamIn.vector_x,Field.Display.ListVarName),1);
        ichoice_y=find(strcmp(ParamIn.vector_y,Field.Display.ListVarName),1);
        if ~isempty(ichoice_x)&&~isempty(ichoice_y)
            set(handles.vector_x,'UserData',ichoice_x)
            set(handles.vector_y,'UserData',ichoice_y)
            check_vec_input=1;
        end
    end
    % otherwise select vectors marked as attributes in the input field
    if check_cellinfo && ~check_vec_input && isfield(CellInfo{imax},'VarIndex_vector_x') &&  isfield(CellInfo{imax},'VarIndex_vector_y')
        set(handles.vector_x,'UserData',CellInfo{imax}.VarIndex_vector_x(1))
        set(handles.vector_y,'UserData',CellInfo{imax}.VarIndex_vector_y(1))
        check_vec_input=1;
    end
    if check_vec_input
        set(handles.FieldOption,'Value',3)% set vector selection option
    else     
        set(handles.FieldOption,'Value',2)% set scalar selection option
    end
else % case of 1D fields
    set(handles.FieldOption,'Value',1)
end

%% fill the general list of dimensions, variables, attributes
if isfield(Field,'ListDimName')&&~isempty(Field.ListDimName)
    Tabcell(:,1)=Field.ListDimName;
    for iline=1:length(Field.ListDimName)
        Tabcell{iline,2}=num2str(Field.DimValue(iline));
    end
    Tabchar=cell2tab(Tabcell,' = ');
    set(handles.dimensions,'String',Tabchar)
end

%% fill menus for coordinates and time
FieldOption_Callback(handles.variables,[], handles)% list the global attributes

%% put the GUI on the lower right of the sceen
set(hObject,'Unit','pixels')
%pos_view_field=get(hObject,'Position');
set(0,'Unit','pixels')
ScreenSize=get(0,'ScreenSize');
pos_view_field(3:4)=[955 648];
pos_view_field(1)=ScreenSize(1)+ScreenSize(3)-pos_view_field(3);
pos_view_field(2)=ScreenSize(2);
set(hObject,'Position',pos_view_field)
set(handles.get_field,'WindowStyle','modal')% Make the GUI modal
if isfield(ParamIn,'Title')
    set(hObject,'Name',ParamIn.Title)
end

%% set z coordinate menu if relevant
if Field.MaxDim>=3 && prod(Field.DimValue)<10^8 && ~(isfield(ParamIn,'Coord_z') && isempty(ParamIn.Coord_z)) % 3D field (with memory content smaller than 400 Mo)
    set(handles.Check3D,'Value',1)
else
    set(handles.Check3D,'Value',0)
end
Check3D_Callback(hObject, eventdata, handles)
set(handles.variables,'Value',1)
set(handles.variables,'String',[{'*'} Field.ListVarName])
variables_Callback(handles.variables,[], handles)% list the global attributes
drawnow
uiwait(handles.get_field);

% -----------------------------------------------------------------------
% --- Activated by selection in the list of variables
% ----------------------------------------------------------------------
function variables_Callback(hObject, VarName, handles)

Tabchar={''};%default
Tabcell=[];
hselect_field=get(handles.variables,'parent');
Field=get(handles.get_field,'UserData');
index=get(handles.variables,'Value');%index in the list 'variables'

%% list global TimeAttribute names and values if index=1 (blank TimeVariable display) is selected
if isequal(index,1)
    set(handles.attributes_txt,'String','global attributes')
    if isfield(Field,'ListGlobalAttribute') && ~isempty(Field.ListGlobalAttribute)
        for iline=1:length(Field.ListGlobalAttribute)
            Tabcell{iline,1}=Field.ListGlobalAttribute{iline};
            if isfield(Field, Field.ListGlobalAttribute{iline})
                val=Field.(Field.ListGlobalAttribute{iline});
                if ischar(val);% attribute value is char string
                    Tabcell{iline,2}=val;
                elseif size(val,1)==1 %attribute value is a number or matlab vector
                    Tabcell{iline,2}=num2str(val);
                end
            end
        end
        Tabchar=cell2tab(Tabcell,'=');
    end
    %% list Attribute names and values associated to the Variable # index-1
else
    list_var=get(handles.variables,'String');
    if index>numel(list_var)
        return
    end
    VarName=list_var{index};
    set(handles.attributes_txt,'String', ['attributes of ' VarName])
    if isfield(Field,'VarAttribute')&& length(Field.VarAttribute)>=index-1
        VarAttr=Field.VarAttribute{index-1};
        if isstruct(VarAttr)
            attr_list=fieldnames(VarAttr);
            for iline=1:length(attr_list)
                Tabcell{iline,1}=attr_list{iline};
                val=VarAttr.(attr_list{iline}) ;
                if ischar(val);
                    Tabcell{iline,2}=val;
                else
                    Tabcell{iline,2}=num2str(val);
                end
            end
        end
    end
end
if ~isempty(Tabcell)
    Tabchar=cell2tab(Tabcell,'=');
end
set(handles.attributes,'Value',1);% select the first item
set(handles.attributes,'String',Tabchar);

%% update dimensions;
if isfield(Field,'ListDimName')
    Tabdim={};%default
    if isequal(index,1)%list all dimensions if '*' is selected as the variable
        dim_indices=1:length(Field.ListDimName);
        set(handles.dimensions_txt,'String', 'dimensions')
    else   % a specific variable has been selected
        DimCell=Field.VarDimName{index-1};
        if ischar(DimCell)
            DimCell={DimCell};% transform into a cell for a single dimension defined by a char string
        end
        dim_indices=[];
        for idim=1:length(DimCell)
            dim_index=strcmp(DimCell{idim},Field.ListDimName);%vector with size of Field.ListDimName, =0
            dim_index=find(dim_index,1);
            dim_indices=[dim_indices dim_index];
        end
        set(handles.dimensions_txt,'String', ['dimensions of ' VarName])
    end
    for iline=1:length(dim_indices)
        Tabdim{iline,1}=Field.ListDimName{dim_indices(iline)};
        Tabdim{iline,2}=num2str(Field.DimValue(dim_indices(iline)));
    end
    Tabchar=cell2tab(Tabdim,' = ');
    Tabchar=[{''} ;Tabchar];
    set(handles.dimensions,'Value',1)
    set(handles.dimensions,'String',Tabchar)
end

%% propose a plot by default if variables_Callback has not been already called by FieldOption_Callback (VarName is not a char string)
if ~ischar(VarName) && ~isequal(index,1)
    if numel(DimCell)==1
        set(handles.FieldOption,'Value',1)%propose 1D plot
    else
        set(handles.FieldOption,'Value',2)%propose scalar plot
    end
    if numel(DimCell)<=2
        set(handles.Check3D,'Value',0)
    else
        set(handles.Check3D,'Value',1)
    end
    FieldOption_Callback(hObject, VarName, handles)
end

%------------------------------------------------------------------------
% --- Executes on selection change in FieldOption.
%------------------------------------------------------------------------
function FieldOption_Callback(hObject, VarName, handles)

Field=get(handles.get_field,'UserData');
FieldList=get(handles.FieldOption,'String');
FieldOption=FieldList{get(handles.FieldOption,'Value')};
switch FieldOption
    case '1D plot'
        set(handles.Coordinates,'Visible','on')
        %set(handles.PanelOrdinate,'Visible','on')
        %pos=get(handles.PanelOrdinate,'Position');
%         pos(1)=2;
%         pos_coord=get(handles.Coordinates,'Position');
%         pos(2)=pos_coord(2)-pos(4)-2;
        %set(handles.PanelOrdinate,'Position',pos)
        set(handles.PanelScalar,'Visible','off')
        set(handles.PanelVectors,'Visible','off')
        set(handles.Coord_y,'Visible','on')
        set(handles.Coord_y,'Max',2)%allow multiple selection
        set(handles.Y_title,'Visible','on')
        set(handles.Coord_z,'Visible','off')
        set(handles.Z_title,'Visible','off')
        set(handles.Coord_x,'String',Field.Display.ListVarName')
        Coord_x_Callback(hObject, VarName, handles) 
        %set(handles.Coord_y,'String',Field.Display.ListVarName')
        %Coord_x_Callback(hObject, VarName, handles)       
    case {'scalar'}
        set(handles.Coordinates,'Visible','on')
        %set(handles.PanelOrdinate,'Visible','off')
        set(handles.PanelScalar,'Visible','on')
        set(handles.PanelVectors,'Visible','off')
        pos=get(handles.PanelScalar,'Position');
        pos(1)=2;
        pos_coord=get(handles.Coordinates,'Position');
        pos(2)=pos_coord(2)-pos(4)-2;
        set(handles.PanelScalar,'Position',pos)
        set(handles.Coord_y,'Visible','on')
        set(handles.Y_title,'Visible','on')     
        if ~ischar(VarName)      
            %default scalar selection
            test_coord=zeros(size(Field.Display.VarDimName)); %=1 when variable #ilist is eligible as structured coordiante
            for ilist=1:numel(Field.Display.VarDimName)
                if isfield(Field.Display,'VarAttribute') && numel(Field.Display.VarAttribute)>=ilist && isfield(Field.Display.VarAttribute{ilist},'Role')
                    Role=Field.Display.VarAttribute{ilist}.Role;
                    if strcmp(Role,'coord_x')||strcmp(Role,'coord_y')
                        test_coord(ilist)=1;
                    end
                end
                dimnames=Field.Display.VarDimName{ilist}; %list of dimensions for variable #ilist
                if numel(dimnames)==1 && strcmp(dimnames{1},Field.Display.ListVarName{ilist})%dimension variable
                    test_coord(ilist)=1;
                end
            end
            scalar_index=find(~test_coord,1);%get the first variable not a coordinate
            if isempty(scalar_index)
                set(handles.scalar,'Value',1)
            else
                set(handles.scalar,'Value',scalar_index)
            end
        end
        scalar_Callback(hObject,VarName, handles)        
    case 'vectors'
        set(handles.PanelVectors,'Visible','on')
        set(handles.Coordinates,'Visible','on')
        %set(handles.PanelOrdinate,'Visible','off')
        set(handles.PanelScalar,'Visible','off')
        pos=get(handles.PanelVectors,'Position');
        pos(1)=2;
        pos_coord=get(handles.Coordinates,'Position');
        pos(2)=pos_coord(2)-pos(4)-2;
        set(handles.PanelVectors,'Position',pos)
        set(handles.Coord_y,'Visible','on')
        set(handles.Y_title,'Visible','on')
        %default vector selection
        vector_x_value=get(handles.vector_x,'UserData');
        vector_y_value=get(handles.vector_y,'UserData');
        if ~isempty(vector_x_value)&&~isempty(vector_y_value)
            set(handles.vector_x,'Value',vector_x_value)
            set(handles.vector_y,'Value',vector_y_value)
        else
            test_coord=zeros(size(Field.Display.VarDimName)); %=1 when variable #ilist is eligible as structured coordinate
            for ilist=1:numel(Field.Display.VarDimName)
                if isfield(Field.Display,'VarAttribute') && numel(Field.Display.VarAttribute)>=ilist && isfield(Field.Display.VarAttribute{ilist},'Role')
                    Role=Field.Display.VarAttribute{ilist}.Role;
                    if strcmp(Role,'coord_x')||strcmp(Role,'coord_y')
                        test_coord(ilist)=1;
                    end
                end
                dimnames=Field.Display.VarDimName{ilist}; %list of dimensions for variable #ilist
                if numel(dimnames)==1 && strcmp(dimnames{1},Field.Display.ListVarName{ilist})%dimension variable
                    test_coord(ilist)=1;
                end
            end
            vector_index=find(~test_coord,2);%get the two first variables not a coordinate
            if isempty(vector_index)
                set(handles.vector_x,'Value',1)
                set(handles.vector_y,'Value',2)
            else
                set(handles.vector_x,'Value',vector_index(1))
                set(handles.vector_y,'Value',vector_index(2))
            end
        end
        vector_Callback(handles)      
    case 'civdata...'
        %set(handles.PanelOrdinate,'Visible','off')
        set(handles.PanelScalar,'Visible','off')
        set(handles.PanelVectors,'Visible','off')
        set(handles.Coordinates,'Visible','off')
end


function set_coord_y_options(handles,VarName)
%------------------------------------------------------------------------
Field=get(handles.get_field,'UserData');
VarIndex=find(strcmp(VarName,Field.Display.ListVarName),1);
DimCell=Field.Display.VarDimName{VarIndex};
% y_index=get(handles.Coord_y,'Value');
% y_menu=get(handles.Coord_y,'String');
% if isempty(y_menu)
%     return
% else
% YName=y_menu{y_index};
% end

%% set list of possible coordinates
% test_component=zeros(size(Field.Display.VarDimName));%=1 when variable #ilist is eligible as unstructured coordinate
test_coord=zeros(size(Field.Display.VarDimName)); %=1 when variable #ilist is eligible as structured coordiante
% ListCoord={''};
% dim_var=Field.Display.VarDimName{y_index};%list of dimensions of the selected variable

for ilist=1:numel(Field.Display.VarDimName)
    dimnames=Field.Display.VarDimName{ilist}; %list of dimensions for variable #ilist
    if isequal(dimnames,DimCell)||isequal(dimnames(1:end-1),DimCell)||isequal(dimnames(2:end),DimCell)
        test_coord(ilist)=1;
    end
end
ListCoord=Field.Display.ListVarName(find(test_coord));
set(handles.Coord_y,'String',ListCoord)
val_y=1;
if strcmp(VarName,ListCoord{1})&& numel(ListCoord)>=2
    val_y=2;
end
set(handles.Coord_y,'Value',val_y)

%% set default coord selection
% if numel(find(test_coord))>3
%      SwitchVarIndexTime=get(handles.SwitchVarIndexTime,'String');
%     if numel(SwitchVarIndexTime)<3
%         SwitchVarIndexTime=[SwitchVarIndexTime;'matrix_index'];
%         set(handles.SwitchVarIndexTime,'String',SwitchVarIndexTime)
%     end
%     set(handles.SwitchVarIndexTime,'Value',3)% the last dim must be considered as time
%     SwitchVarIndexTime_Callback([], [], handles)
% end
% if numel(var_component)<2
%     if numel(test_coord)<2
%         ListCoord={''};
%     else
%         set(handles.Coord_x,'Value',2)
%         set(handles.Coord_y,'Value',1)
%     end
% else
%     coord_val=1;
%     for ilist=1:numel(var_component)
%         ivar=var_component(ilist);
%         if isfield(Field.Display,'VarAttribute') && numel(Field.Display.VarAttribute)>=ivar && isfield(Field.Display.VarAttribute{ivar},'Role')
%             Role=Field.Display.VarAttribute{ivar}.Role;
%             if strcmp(Role,'coord_x')
%                 coord_val=ilist;
%             end
%         end
%     end
%     set(handles.Coord_x,'Value',coord_val+1)
% end
% set(handles.Coord_x,'String',[{''}; ListCoord])


% %% set list of time coordinates
% menu=get(handles.SwitchVarIndexTime,'String');
% TimeOption=menu{get(handles.SwitchVarIndexTime,'Value')};
% switch TimeOption
%     case 'variable'
%         if numel(find(test_coord))<3
%             ListTime={''};
%         else
%             ListTime=Field.Display.ListVarName(find(test_coord,end));
%         end
%         set(handles.TimeName,'Value',1)
%         set(handles.TimeName,'String',ListTime)
%     case 'matrix index'
%         if numel(find(test_coord))<3
%             ListTime={''};
%         else
%             ListTime=Field.Display.VarDimName{find(test_coord,end)};
%         end
%         set(handles.TimeName,'Value',1)
%         set(handles.TimeName,'String',ListTime)
% end  
% if ~ischar(DimCell)
% update_field(handles,YName)
% end
         
%------------------------------------------------------------------------
% --- Executes on selection change in scalar menu.
%------------------------------------------------------------------------
function scalar_Callback(hObject, VarName, handles)

Field=get(handles.get_field,'UserData');% get the input field info stored in UserData of the GUI
scalar_menu=get(handles.scalar,'String');% read the menu for scalar selection
if ischar(VarName)% case of a call with input variable
    ScalarName=VarName;
    scalar_index=find(strcmp(VarName,scalar_menu));
    set(handles.scalar,'Value',scalar_index)% select the input variable field in the menu
else % no input variable, the variable ScalarName is selected from the menu
    scalar_index=get(handles.scalar,'Value');
    ScalarName=scalar_menu{scalar_index};
end

%% set list of possible coordinates
test_component=zeros(size(Field.Display.VarDimName));%=1 when variable #ilist is eligible as unstructured coordinate
test_coord=zeros(size(Field.Display.VarDimName)); %=1 when variable #ilist is eligible as structured coordiante
dim_var=Field.Display.VarDimName{scalar_index};%list of dimensions of the selected variable
%if ~get(handles.CheckDimensionX,'Value')
%look for coordinate variables among the other variables
for ilist=1:numel(Field.Display.VarDimName)
    dimnames=Field.Display.VarDimName{ilist}; %list of dimensions for variable #ilist
    if isequal(dimnames,dim_var)
        test_component(ilist)=1;% the listed variable has the same dimension as the selected scalar-> possibly chosen as unstructured coordinate
    elseif numel(dimnames)==1 && ~isempty(find(strcmp(dimnames{1},dim_var), 1))%variable ilist is a 1D array which can be coordinate variable
        test_coord(ilist)=1;
    end
end
%end
var_component=find(test_component);% list of variable indices elligible as unstructured coordinates
var_coord=find(test_coord);% % list of variable indices elligible as gridded coordinates
var_coord(var_coord==scalar_index)=[];
var_component(var_component==scalar_index)=[];
ListCoord=Field.Display.ListVarName([var_coord var_component]);
coord_val=zeros(size(ListCoord));

%% set default selection for grid coordinates
if numel(var_coord)>=2
    coord_val(1)=var_coord(end);
    coord_val(2)=var_coord(end-1);
    if numel(var_coord)>=3
        coord_val(3)=var_coord(end-2);
    end
end
% if numel(find(test_coord))>3
%     SwitchVarIndexTime=get(handles.SwitchVarIndexTime,'String');
%     if numel(SwitchVarIndexTime)<3
%         SwitchVarIndexTime=[SwitchVarIndexTime;'matrix_index'];
%         set(handles.SwitchVarIndexTime,'String',SwitchVarIndexTime)
%     end
%     set(handles.SwitchVarIndexTime,'Value',3)% the last dim must be considered as time
%     SwitchVarIndexTime_Callback([], [], handles)
% end

%% default selection for labelled unstructured coordinates
for ilist=1:numel(var_component)
    ivar=var_component(ilist);
    if isfield(Field.Display,'VarAttribute') && numel(Field.Display.VarAttribute)>=ivar && isfield(Field.Display.VarAttribute{ivar},'Role')
        Role=Field.Display.VarAttribute{ivar}.Role;
        if strcmp(Role,'coord_x')
            coord_val(1)=ilist;
        elseif strcmp(Role,'coord_y')
            coord_val(2)=ilist;
        elseif strcmp(Role,'coord_z')
            coord_val(3)=ilist;
        end
    end
end
if numel(find(coord_val))<2 % no predefiend components
    if numel(var_coord)>=3
        coord_val(3)=3;
    end
    coord_val([1 2])=[1 2];
end

%% set menu and default selection for coordinates
set(handles.Coord_x,'Value',coord_val(1))
set(handles.Coord_x,'String',ListCoord)
set(handles.Coord_y,'Value',coord_val(2))
set(handles.Coord_y,'String',ListCoord)
if numel(find(coord_val))>=3
    set(handles.Coord_z,'Value',coord_val(3))
    set(handles.Coord_z,'String',ListCoord)
    set(handles.Coord_z,'Visible','on')
    set(handles.Check3D,'Value', 1)
end

%% set list of time coordinates
menu=get(handles.SwitchVarIndexTime,'String');
TimeOption=menu{get(handles.SwitchVarIndexTime,'Value')};
switch TimeOption
    case 'variable'
        if numel(find(test_coord))<3
            ListTime={''};
        else
            ListTime=Field.Display.ListVarName(find(test_coord,end));
        end
        set(handles.TimeName,'Value',1)
        set(handles.TimeName,'String',ListTime)
    case 'dim index'
        if numel(find(test_coord))<3
            ListTime={''};
        else
            ListTime=Field.Display.VarDimName{find(test_coord,end)};
        end
        set(handles.TimeName,'Value',1)
        set(handles.TimeName,'String',ListTime)
end
if ~ischar(VarName)
    update_field(handles,ScalarName)
end

% --- Executes on button press in check_rgb.
function check_rgb_Callback(hObject, eventdata, handles)


%------------------------------------------------------------------------
% --- Executes on selection change in vector_x.
%------------------------------------------------------------------------
function vector_x_Callback(hObject, DimCell, handles)

vector_x_menu=get(handles.vector_x,'String');
vector_x_index=get(handles.vector_x,'Value');
vector_x=vector_x_menu{vector_x_index};
vector_Callback(handles)
if ~ischar(DimCell)
update_field(handles,vector_x)
end

%------------------------------------------------------------------------
% --- Executes on selection change in vector_x.
%------------------------------------------------------------------------
function vector_y_Callback(hObject, DimCell, handles)

vector_y_menu=get(handles.vector_x,'String');
vector_y_index=get(handles.vector_x,'Value');
vector_y=vector_y_menu{vector_y_index};
vector_Callback(handles)
if ~ischar(DimCell)
update_field(handles,vector_y)
end

%------------------------------------------------------------------------
% --- Executes on selection change in vector_z.
function vector_z_Callback(hObject, DimCell, handles)
%------------------------------------------------------------------------
vector_z_menu=get(handles.vector_z,'String');
vector_z_index=get(handles.vector_z,'Value');
vector_z=vector_z_menu{vector_z_index};
vector_Callback(handles)
if ~ischar(DimCell)
update_field(handles,vector_z)
end
%------------------------------------------------------------------------
% --- Executes on selection change in vec_color.
function vec_color_Callback(hObject, DimCell, handles)
%------------------------------------------------------------------------
index=get(handles.vec_color,'Value');
string=get(handles.vec_color,'String');
VarName=string{index};
vector_Callback(handles)
if ~ischar(DimCell)
update_field(handles,VarName)
end
%------------------------------------------------------------------------
% --- Executes on selection change in vector_x or vector_y
function vector_Callback( handles)
%------------------------------------------------------------------------
Field=get(handles.get_field,'UserData');
vector_x_index=get(handles.vector_x,'Value');
vector_y_index=get(handles.vector_y,'Value');
vec_color_index=get(handles.vec_color,'Value');

%% set list of possible coordinates
test_component=zeros(size(Field.Display.VarDimName));%=1 when variable #ilist is eligible as unstructured coordinate
test_coord=zeros(size(Field.Display.VarDimName)); %=1 when variable #ilist is eligible as structured coordinate
check_consistent=1;%check that the selected vector components (and possibly color var) have the same dimensiosn
ListCoord={''};
dim_var=Field.Display.VarDimName{vector_x_index};%list of dimensions of the selected variable
if ~isequal(dim_var,Field.Display.VarDimName{vector_y_index})
    check_consistent=0;
elseif vec_color_index~=1 && ~isequal(dim_var,Field.Display.VarDimName{vec_color_index})
    check_consistent=0;
end
% the two vector components have consistent dimensions
if check_consistent
    for ilist=1:numel(Field.Display.VarDimName)
        dimnames=Field.Display.VarDimName{ilist}; %list of dimensions for variable #ilist
        if isequal(dimnames,dim_var)
            test_component(ilist)=1;
        elseif numel(dimnames)==1 && ~isempty(find(strcmp(dimnames{1},dim_var)))%variable ilist is a 1D array which can be coordinate variable
            test_coord(ilist)=1;
        end
    end
    var_component=find(test_component);% list of variable indices elligible as unstructured coordinates
    var_coord=find(test_coord);% % list of variable indices elligible as structured coordinates
    var_component(var_component==vector_x_index|var_component==vector_y_index)=[];
    var_coord(var_coord==vector_x_index|var_coord==vector_y_index)=[];% remove vector components form te possible list of coordinates
    ListCoord=Field.Display.ListVarName([var_coord var_component]);
    
    %% set default coord selection
    if numel(find(test_coord))>3
        set(handles.SwitchVarIndexTime,'Value',3)% the last dim must be considered as time
    end
    if numel(var_component)<2 %unstructured coordinates excluded
        if numel(find(test_coord))<2
            ListCoord={''};
        else
            if numel(find(test_coord))>=3
                set(handles.Coord_x,'Value',3)
                set(handles.Coord_y,'Value',2)
                set(handles.Coord_z,'Value',1)
            else
                set(handles.Coord_x,'Value',2)
                set(handles.Coord_y,'Value',1)
            end
        end
    else
        coord_val=[0 0 0];
        for ilist=1:numel(var_component)
            ivar=var_component(ilist);
            if isfield(Field.Display,'VarAttribute') && numel(Field.Display.VarAttribute)>=ivar && isfield(Field.Display.VarAttribute{ivar},'Role')
                Role=Field.Display.VarAttribute{ivar}.Role;
                if strcmp(Role,'coord_x')
                    coord_val(1)=ilist;
                elseif strcmp(Role,'coord_y')
                    coord_val(2)=ilist;
                elseif strcmp(Role,'coord_z')
                    coord_val(3)=ilist;
                end
            end
        end
        if isempty(find(coord_val))
            coord_val=var_coord;% case of dimension coordinates
        end
        if numel(find(coord_val))<2
            coord_val=[1 2 3];
        end
        set(handles.Coord_x,'Value',coord_val(end))
        set(handles.Coord_y,'Value',coord_val(end-1))
        if numel(coord_val)>=3
            set(handles.Coord_z,'Value',coord_val(end-2))
        end
    end
end
set(handles.Coord_z,'String',ListCoord)
set(handles.Coord_y,'String',ListCoord)
set(handles.Coord_x,'String',ListCoord)


%% set list of time coordinates
menu=get(handles.SwitchVarIndexTime,'String');
TimeOption=menu{get(handles.SwitchVarIndexTime,'Value')};
switch TimeOption
    case 'variable'
        if numel(find(test_coord))<3
            ListTime={''};
        else
            ListTime=Field.Display.ListVarName(find(test_coord,end));
        end
        set(handles.TimeName,'Value',1)
        set(handles.TimeName,'String',ListTime)
    case 'dim index'
        if numel(find(test_coord))<3
            ListTime={''};
        else
            ListTime=Field.Display.VarDimName{find(test_coord,end)};
        end
        set(handles.TimeName,'Value',1)
        set(handles.TimeName,'String',ListTime)
end  

%------------------------------------------------------------------------
% --- Executes on selection change in SwitchVarIndexX.
%------------------------------------------------------------------------
function SwitchVarIndexX_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on selection change in Coord_x.
%------------------------------------------------------------------------
function Coord_x_Callback(hObject, DimCell, handles)
DimCell
index=get(handles.Coord_x,'Value');
string=get(handles.Coord_x,'String');
VarName=string{index};
if ~ischar(DimCell)
    update_field(handles,VarName)
end
if isequal(get(handles.FieldOption,'Value'),1)
set_coord_y_options(handles,VarName)
end

%------------------------------------------------------------------------
% --- Executes on selection change in Coord_y.
%------------------------------------------------------------------------
function Coord_y_Callback(hObject, DimCell, handles)

index=get(handles.Coord_y,'Value');
string=get(handles.Coord_y,'String');
VarName=string{index};

if ~ischar(DimCell)
update_field(handles,VarName)
end

%------------------------------------------------------------------------
% --- Executes on selection change in Coord_z.
%------------------------------------------------------------------------
function Coord_z_Callback(hObject, DimCell, handles)

index=get(handles.Coord_z,'Value');
string=get(handles.Coord_z,'String');
VarName=string{index};
if ~ischar(DimCell)
update_field(handles,VarName)
end

%------------------------------------------------------------------------
% --- Executes on selection change in SwitchVarIndexTime.
%------------------------------------------------------------------------

function SwitchVarIndexTime_Callback(hObject, eventdata, handles)

Field=get(handles.get_field,'UserData');
menu=get(handles.SwitchVarIndexTime,'String');
option=menu{get(handles.SwitchVarIndexTime,'Value')};

switch option
    case 'file index'
        set(handles.TimeName, 'Visible','off')% the time is taken as the file index
    case 'attribute'
        set(handles.TimeName, 'Visible','on')% timeName menu represents the available attributes
        time_index=get(handles.TimeName,'UserData');    %select the input data
        if isempty(time_index)
            PreviousList=get(handles.TimeName, 'String');
            if ~isempty(PreviousList)
                PreviousAttr=PreviousList{get(handles.TimeName, 'Value')};
                index=find(strcmp(PreviousAttr,Field.Display.ListGlobalAttribute),1);
            end
        end
        if isempty(time_index)
            time_index=find(~cellfun('isempty',regexp(Field.Display.ListGlobalAttribute,'Time')),1);% index of the attributes containing the string 'Time'
        end      
        if ~isempty(time_index)
            set(handles.TimeName,'Value',time_index)
        else
            set(handles.TimeName,'Value',1)
        end
        set(handles.TimeName, 'String',Field.Display.ListGlobalAttribute)

    case 'variable'% TimeName menu represents the available variables
        set(handles.TimeName, 'Visible','on')
        VarNbDim=cellfun('length',Field.Display.VarDimName); % check the nbre of dimensions of each input variable
        TimeVarName=Field.Display.ListVarName(VarNbDim==1);% list of variables with a single dimension (candidate for time)
        List=get(handles.TimeName,'String');% list of names on the menu for time
        if isempty(List)
            ind=1;
        else
            option=List{get(handles.TimeName,'Value')};% previous selected option
            ind=find(strcmp(option,TimeVarName)); %check whether the previous selection is available in the newlist
            if isempty(ind)
                ind=1;
            end
        end
        if ~isempty(TimeVarName)
            set(handles.TimeName, 'Value',ind);% select first value in the menu if the option is not found
            set(handles.TimeName, 'String',TimeVarName)% update the menu for time name
        end
    case 'matrix index'% TimeName menu represents the available dimensions
        set(handles.TimeName, 'Visible','on')     
        set(handles.TimeName, 'Value',1);
        set(handles.TimeName, 'String',Field.Display.ListDimName)
end
TimeName_Callback(hObject, [], handles)

%-----------------------------------------------------------------------
% update the display of the variable 'VarName' and its dimensions in the list of variables
function update_field(handles,VarName)
%-----------------------------------------------------------------------
Field=get(handles.get_field,'UserData');
index=name2index(VarName,Field.ListVarName);
if ~isempty(index)
    set(handles.variables,'Value',index+1)
    variables_Callback(handles.variables, VarName, handles)
end

%------------------------------------------------------------------------
% --- give index numbers of the strings str in the list ListvarName
% -----------------------------------------------------------------------
function VarIndex_y=name2index(cell_str,ListVarName)

VarIndex_y=[];
if ischar(cell_str)
    VarIndex_y=find(strcmp(cell_str,ListVarName),1);
elseif iscell(cell_str)
    for isel=1:length(cell_str)
        varsel=cell_str{isel};
        for ivar=1:length(ListVarName)
            varlist=ListVarName{ivar};
            if isequal(varlist,varsel)
                VarIndex_y=[VarIndex_y ivar];
            end
        end
    end
end



% % --- Executes on button press in CheckDimensionY.
% function CheckDimensionY_Callback(hObject, eventdata, handles)
% FieldList=get(handles.FieldOption,'String');
% FieldOption=FieldList{get(handles.FieldOption,'Value')};
% switch FieldOption
%     case '1D plot'
%         
%     case {'scalar','pick variables'}
%        scalar_Callback(hObject, eventdata, handles)
%     case 'vectors'
% end
% 
% 
% % --- Executes on button press in CheckDimensionZ.
% function CheckDimensionZ_Callback(hObject, eventdata, handles)
% FieldList=get(handles.FieldOption,'String');
% FieldOption=FieldList{get(handles.FieldOption,'Value')};
% switch FieldOption
%     case '1D plot'
%         
%     case 'scalar'
%        scalar_Callback(hObject, eventdata, handles)
%     case 'vectors'
% end

% --- Executes on selection change in TimeName.
function TimeName_Callback(hObject, eventdata, handles)
Field=get(handles.get_field,'UserData');
index=get(handles.SwitchVarIndexTime,'Value');
MenuIndex=get(handles.TimeName,'Value');
string=get(handles.TimeName,'String');
TimeName='';%default
if ~isempty(string)&&iscell(string)
TimeName=string{MenuIndex};
end
switch index
    case 1
        set(handles.num_TimeDimension,'String','')
        set(handles.TimeUnit,'String','index')
    case 2
        set(handles.num_TimeDimension,'String','')
        attr_index=find(strcmpi([TimeName 'Unit'],Field.ListGlobalAttribute));% look for time unit
        if ~isempty(attr_index)
            AttrName=Field.ListGlobalAttribute{attr_index};
            set(handles.TimeUnit,'String',Field.(AttrName))
        else
            set(handles.TimeUnit,'String','')
        end
    case {3 ,4}
        if index==3  % TimeName is used to chose a variable
            VarIndex=name2index(TimeName,Field.ListVarName);
            DimName=Field.VarDimName{VarIndex};
            DimIndex=name2index(DimName,Field.ListDimName);
            DimValue=Field.DimValue(DimIndex);
            set(handles.num_TimeDimension,'String',num2str(DimValue))
            unit='';
            if isfield(Field,'VarAttribute')&& isfield(Field.VarAttribute{VarIndex},'Unit')
                unit=Field.VarAttribute{VarIndex}.Unit;
            end
            set(handles.TimeUnit,'String',unit)
            update_field(handles,TimeName)
        elseif index==4% TimeName is used to chose a dimension
            DimName=string{MenuIndex};
            DimIndex=name2index(DimName,Field.ListDimName);
            DimValue=Field.DimValue(DimIndex);
            set(handles.num_TimeDimension,'String',num2str(DimValue))
            set(handles.TimeUnit,'String','index')
        end
end

%-----------------------------------------------------------------------
% --- Executes on button press in Check3D.
%-----------------------------------------------------------------------
function Check3D_Callback(hObject, eventdata, handles)
if get(handles.Check3D,'Value')% 3D fields
    status='on';
else% fields studied as 2D
    status='off';
end

set(handles.Coord_z,'Visible',status)
% set(handles.CheckDimensionZ,'Visible',status)
set(handles.Z_title,'Visible',status)
set(handles.vector_z,'Visible',status)
set(handles.W_title,'Visible',status)
Field=get(handles.get_field,'UserData');
if strcmp(status,'on')% ask for 3D input       
    if Field.MaxDim>3% for 4D fields, propose to use the fourth variable as time
        %set(handles.Time,'Visible','on')
        menu=get(handles.SwitchVarIndexTime,'String');
        val=find(strcmp('variable',menu));
        if ~isempty(val)
            set(handles.SwitchVarIndexTime,'Value',val)
        end
    else
        set(handles.SwitchVarIndexTime,'Value',1)
        set(handles.SwitchVarIndexTime,'String',{'file index';'attribute'})
    end
else 
   set(handles.SwitchVarIndexTime,'String',get(handles.SwitchVarIndexTime,'UserData'))
   if Field.MaxDim >=3
       var_index=find(strcmp('variable',get(handles.SwitchVarIndexTime,'UserData')));
       set(handles.SwitchVarIndexTime,'Value',var_index)
   end
end
SwitchVarIndexTime_Callback(handles.SwitchVarIndexTime,[], handles)

%------------------------------------------------------------------------
% --- Executes on button press in OK.
%------------------------------------------------------------------------
function OK_Callback(hObject, eventdata, handles)
handles.output=read_GUI(handles.get_field);
guidata(hObject, handles);% Update handles structure
uiresume(handles.get_field);
drawnow
% this function then activate get_field_OutputFcn

%------------------------------------------------------------------------
% --- Executes when the GUI is closed by the mouse on upper right corner.
%------------------------------------------------------------------------
function closefcn(hObject, eventdata, handles)
handles.output=[];
guidata(hObject, handles);% Update handles structure
uiresume(handles.get_field);
drawnow

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
%------------------------------------------------------------------------
function varargout = get_field_OutputFcn(hObject, eventdata, handles)

varargout{1} =handles.output;
delete(handles.get_field)
