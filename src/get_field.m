%'get_field': display variables and attributes from a Netcdf file, and OK selected fields
%------------------------------------------------------------------------
%function varargout = get_field(varargin)
% associated with the GUI get_field.fig
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

function varargout = get_field(varargin)

% Last Modified by GUIDE v2.5 02-Jun-2013 14:00:39

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
function get_field_OpeningFcn(hObject, eventdata, handles,filename,ParamIn)
%------------------------------------------------------------------------
global nb_builtin % nbre of functions to include by default in the menu of  functions called by RUN

%% Choose default command line output for get_field
handles.output = 'Cancel';

%% Update handles structure
guidata(hObject, handles);
set(hObject,'WindowButtonDownFcn',{'mouse_down'}) % allows mouse action with right button (zoom for uicontrol display)

%% settings for 'slave' mode, called by uvmat, or 'master' mode
if exist('filename','var') && ischar(filename) %transfer input file name in slave mode
    set(handles.inputfile,'String',filename)% prefill the input file name
    Field=nc2struct(filename,[]);% reads the  field structure, without the variables
    if isfield(Field,'Txt')
        msgbox_uvmat('ERROR',['get_field/nc2struct/' Field.Txt])
    else
        if ~exist('ParamIn','var')
            ParamIn=[];
        end
        Field_input(handles,Field,ParamIn);
    end
else  %master mode
    set(handles.inputfile,'String','')
end

%% put the GUI on the lower right of the sceen
set(hObject,'Unit','pixel')
pos_view_field=get(hObject,'Position');
set(0,'Unit','pixels')
ScreenSize=get(0,'ScreenSize');
pos_view_field(1)=ScreenSize(1)+ScreenSize(3)-pos_view_field(3);
pos_view_field(2)=ScreenSize(2);
set(hObject,'Position',pos_view_field)
set(handles.get_field,'WindowStyle','modal')% Make the GUI modal 
drawnow
uiwait(handles.get_field);

%------------------------------------------------------------------------
% --- update the display when a new field is introduced.
function Field_input(handles,Field,ParamIn)
%------------------------------------------------------------------------

%% fill the list and values of dimensions
if isfield(Field,'ListDimName')&&~isempty(Field.ListDimName)
    Tabcell(:,1)=Field.ListDimName;
    for iline=1:length(Field.ListDimName)
        Tabcell{iline,2}=num2str(Field.DimValue(iline));
    end
    Tabchar=cell2tab(Tabcell,' = ');
    set(handles.dimensions,'String',Tabchar)
end
if ~isfield(Field,'ListVarName')
    return
end

%% fill the list of variables
Txt=Field.ListVarName;
set(handles.variables,'Value',1)
set(handles.variables,'String',[{'*'} Txt])
variables_Callback(handles.variables,[], handles)
set(handles.ordinate,'String',Txt)
set(handles.vector_x,'String',Txt)
set(handles.vector_y,'String',Txt )
set(handles.vector_z,'String',[{''} Txt ])
set(handles.vec_color,'String',[{''} Txt ])
set(handles.XVarName,'String',Txt )
set(handles.YVarName,'String',Txt )
set(handles.ZVarName,'String',Txt )
set(handles.scalar,'Value',1)
set(handles.scalar,'String', Txt )

%% analyse the input field cells
[CellInfo,NbDim,errormsg]=find_field_cells(Field);
if ~isempty(errormsg)  
    msgbox_uvmat('ERROR',['get_field / Field_input / find_field_cells: ' errormsg])
    return
end  
[Field.MaxDim,imax]=max(NbDim);
% look at variables with a single dimension
for ilist=1:numel(Field.VarDimName)
    if ischar(Field.VarDimName{ilist})
        Field.VarDimName{ilist}={Field.VarDimName{ilist}}; %transform string into cell
    end
    NbDim=numel(Field.VarDimName{ilist});% TODO eliminate singleton dimensions
    check_singleton=false(1,NbDim);
    for idim=1:NbDim
        dim_index=strcmp(Field.VarDimName{ilist}{idim},Field.ListDimName);
        check_singleton(idim)=isequal(Field.DimValue(dim_index),1);
    end
    Field.VarDimName{ilist}=Field.VarDimName{ilist}(~check_singleton);
    Field.NbDim(ilist)=numel(Field.VarDimName{ilist});
    if Field.NbDim(ilist)==1
        Field.VarDimName{ilist}=cell2mat(Field.VarDimName{ilist});
    end
end
SingleVarName=Field.ListVarName(Field.NbDim==1);%list of variables with a single dim
MultiVarName=Field.ListVarName(Field.NbDim>1);
check_dim=zeros(size(Field.VarDimName));
for ilist=1:numel(Field.VarDimName);
    if iscell(Field.VarDimName{ilist})% exclude single dim
        for idim=1:numel(Field.VarDimName{ilist})
            check_dim=check_dim|strcmp(Field.VarDimName{ilist}{idim},Field.VarDimName);
        end
    end
end
Field.SingleVarName=Field.ListVarName(find(check_dim));%list of variables with a single dim
Field.SingleDimName=Field.VarDimName(find(check_dim));% corresponding list of dimensions for variables with a single dim
Field.MaxDim=max(Field.NbDim);

%% set time mode
ListSwitchVarIndexTime={'file index'};% default setting: the time is the file index
% look at global attributes with numerical values
check_numvalue=false;
check_time=false;
for ilist=1:numel(Field.ListGlobalAttribute)
    Value=Field.(Field.ListGlobalAttribute{ilist});
    check_numvalue(ilist)=isnumeric(Value);
    check_time(ilist)=~isempty(find(regexp(Field.ListGlobalAttribute{ilist},'Time'),1));
end
Field.ListNumAttributes=Field.ListGlobalAttribute(check_numvalue);% select the attributes with float numerical value
if ~isempty(Field.ListNumAttributes)
    ListSwitchVarIndexTime=[ListSwitchVarIndexTime; {'attribute'}];% the time can be chosen as a global attribute
end
nboption=numel(ListSwitchVarIndexTime);
if Field.MaxDim>=2
    ListSwitchVarIndexTime=[ListSwitchVarIndexTime;{'variable'};{'dim index'}];% the time can be chosen as a dim index
end
if Field.MaxDim>=4% for dim >=4, one dim is proposed as time 
    option=nboption+1;
elseif ~isempty(find(check_time, 1))
    option=2;
else
    option=1;
end
set(handles.SwitchVarIndexTime,'String',ListSwitchVarIndexTime)
set(handles.SwitchVarIndexTime,'Value',option)
set(handles.get_field,'UserData',Field);% record the finput field structure
SwitchVarIndexTime_Callback([],[], handles)

%% set z coordinate menu if relevant
if Field.MaxDim>=3
    set(handles.vector_z,'Visible','on')
    set(handles.vector_z,'String',[{''} Txt ])
        set(handles.ZVarName,'Visible','on')
    set(handles.SwitchVarIndexZ,'Visible','on')
    set(handles.Z_title,'Visible','on')
else
    set(handles.vector_z,'Visible','off')
    set(handles.ZVarName,'Visible','off')
%    set(handles.SwitchVarIndexZ,'Visible','off')
    set(handles.Z_title,'Visible','off')
end

%% set vector menu (priority) if detected or scalar menu for space dim >=2, or usual (x,y) plot for 1D fields
if Field.MaxDim>=2 % case of 2D (or 3D) fields
    if isfield(CellInfo{imax},'VarIndex_coord_x')&&  isfield(CellInfo{imax},'VarIndex_coord_y') 
        set(handles.XVarName,'Value',CellInfo{imax}.VarIndex_coord_x(1))
        set(handles.YVarName,'Value',CellInfo{imax}.VarIndex_coord_y(1))
    end
    if isfield(CellInfo{imax},'VarIndex_vector_x') &&  isfield(CellInfo{imax},'VarIndex_vector_y') 
        set(handles.FieldOption,'Value',3)% set vector selection option
        set(handles.vector_x,'Value',CellInfo{imax}.VarIndex_vector_x(1))
        set(handles.vector_y,'Value',CellInfo{imax}.VarIndex_vector_y(1))
        set(handles.FieldOption,'Value',3)
    else
        set(handles.FieldOption,'Value',2)
    end
else % case of 1D fields
    set(handles.FieldOption,'Value',1)
end


%% Make choices in menus from input
if exist('ParamIn','var')&&~isempty(ParamIn)
    fill_GUI(ParamIn,handles.get_field);
end
FieldOption_Callback([],[],handles)

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = get_field_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
varargout{1} = handles.output;
delete(handles.get_field)


% -----------------------------------------------------------------------
% --- Activated by selection in the list of variables
function variables_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
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
                eval(['val=Field.' Field.ListGlobalAttribute{iline} ';'])
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
    var_select=list_var{index};
    set(handles.attributes_txt,'String', ['attributes of ' var_select])
    if isfield(Field,'VarAttribute')&& length(Field.VarAttribute)>=index-1
%         nbline=0;
        VarAttr=Field.VarAttribute{index-1};
        if isstruct(VarAttr)
            attr_list=fieldnames(VarAttr);
            for iline=1:length(attr_list)
                Tabcell{iline,1}=attr_list{iline};
                eval(['val=VarAttr.' attr_list{iline} ';']) 
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
    Tabchar=[{''};Tabchar];
end
set(handles.attributes,'Value',1);% select the first item
set(handles.attributes,'String',Tabchar);

%% update dimensions;
if isfield(Field,'ListDimName')
    Tabdim={};%default
    if isequal(index,1)%list all dimensions
        dim_indices=1:length(Field.ListDimName);
        set(handles.dimensions_txt,'String', 'dimensions')
    else
        DimCell=Field.VarDimName{index-1};
        if ischar(DimCell)
            DimCell={DimCell};
        end   
        dim_indices=[];
        for idim=1:length(DimCell)
            dim_index=strcmp(DimCell{idim},Field.ListDimName);%vector with size of Field.ListDimName, =0 
            dim_index=find(dim_index,1);
            dim_indices=[dim_indices dim_index];
        end
        set(handles.dimensions_txt,'String', ['dimensions of ' var_select])
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



%------------------------------------------------------------------------
% --- Executes on button press in CheckPlot1D.
function CheckPlot1D_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
val=get(handles.CheckPlot1D,'Value');
if isequal(val,0)
    set(handles.Panel1Dplot,'Visible','off')
else
   
end

%------------------------------------------------------------------------
function ordinate_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
Field=get(handles.get_field,'UserData');
list=get(handles.ordinate,'String');
yindex=get(handles.ordinate,'Value');
yindex=name2index(list{yindex(1)},Field.ListVarName);
if ~isempty(yindex)
    set(handles.variables,'Value',yindex+1)
    variables_Callback(hObject, eventdata, handles)
end
[CellInfo,NbDim,errormsg]=find_field_cells(Field);
%[CellVarIndex,NbDim,VarRole,errormsg]=find_field_cells(Field);
for icell=1:numel(CellInfo) 
    VarIndex=CellInfo{icell}.VarIndex;
    if ~isempty(find(VarIndex==yindex,1)) && (isempty(CellInfo{icell}.VarIndex_coord_x)||~isequal(CellInfo{icell}.VarIndex_coord_x,VarIndex))
        cell_select=icell;
        break
    end
end
%val=get(handles.abscissa,'Value');
%set(handles.abscissa,'Value',min(val,2));
coord_x_index=CellInfo{cell_select}.VarIndex_coord_x;
coord_x_index=coord_x_index(coord_x_index~=0);
%set(handles.XVarName,'String',[{''}; (Field.ListVarName(coord_x_index))'; (Field.ListVarName(VarIndex))'])
set(handles.XVarName,'String',[(Field.ListVarName(coord_x_index))'; (Field.ListVarName(VarIndex))'])

%------------------------------------------------------------------------
% --- Executes on button press in CheckScalar.
function CheckScalar_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
val=get(handles.CheckScalar,'Value');
if isequal(val,0)
    set(handles.PanelScalar,'Visible','off')
else
    
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckVector.
function CheckVector_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
val=get(handles.CheckVector,'Value');
if isequal(val,0)
    set(handles.PanelVectors,'Visible','off')
else
    
end


%------------------------------------------------------------------------
% --- Executes on selection change in scalar menu.
function scalar_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
Field=get(handles.get_field,'UserData');
index=get(handles.scalar,'Value');
string=get(handles.scalar,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%eliminate time
TimeDimName='';%default

% SwitchVarIndexTime=get(handles.SwitchVarIndexTime,'String');
% TimeVarOption=SwitchVarIndexTime{get(handles.SwitchVarIndexTime,'Value')};
List=get(handles.TimeVarName,'String');
if get(handles.CheckDimensionTime)
         TimeDimName=List{get(handles.TimeVarName,'Value')};
elseif ~get(handles.CheckAttributeTime) 
    TimeVarName=List{get(handles.TimeVarName,'Value')};
end
% A completer
% if strcmp(get(handles.TimeDimensionMenu,'Visible'),'on')
%     TimeDimList=get(handles.TimeDimensionMenu,'String');
%     TimeDimIndex=get(handles.TimeDimensionMenu,'Value');
%     TimeDimName=TimeDimList{TimeDimIndex};
% end

%check possible coordinates
Field=get(handles.get_field,'UserData');
dim_scalar=Field.VarDimName{index};%list of dimensions of the selected scalar
test_coord=ones(size(Field.VarDimName)); %=1 when variable #ilist is eligible as coordinate
for ilist=1:numel(Field.VarDimName)
    dimnames=Field.VarDimName{ilist}; %list of dimensions for variable #ilist
    if isequal(dimnames,TimeDimName)
        test_coord(ilist)=0;%mark time variables fo elimination
    end
    if ischar(dimnames)
        dimnames={dimnames};
    end
    for idim=1:numel(dimnames)
        if isempty(find(strcmp(dimnames{idim},dim_scalar),1))%dimension not found in the scalar variable
            test_coord(ilist)=0;
            break
        end
    end
end
test_coord(index)=0;%the coordinate variable must be different from the scalar

string_coord=[{''};string(test_coord==1)];
val=get(handles.XVarName,'Value');
if val>numel(string_coord)
    set(handles.XVarName,'Value',1)
end
set(handles.XVarName,'String',string_coord);
val=get(handles.ZVarName,'Value');
if val>numel(string_coord)
    set(handles.ZVarName,'Value',1)
end
set(handles.ZVarName,'String',string_coord);
val=get(handles.ZVarName,'Value');
if val>numel(string_coord)
    set(handles.ZVarName,'Value',1)
end
set(handles.YVarName,'String',string_coord);


%------------------------------------------------------------------------
% --- Executes on selection change in abscissa.
function abscissa_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
 hselect_field=get(handles.inputfile,'parent');
 Field=get(hselect_field,'UserData');%current input field
 xdispindex=get(handles.abscissa,'Value');%index in the list of abscissa
% test_2D=get(handles.CheckVector,'Value');% =1 for vector fields
% test_scalar=get(handles.CheckScalar,'Value');% =1 for scalar fields
%if isequal(xdispindex,1)% blank selection, no selected TimeVariable for abscissa
%     Txt=Field.ListVarName;
%     set(handles.ordinate,'String',[{''} Txt ])% display all the varaibles in the list of ordinates
%     xindex=[];
% else
     xlist=get(handles.abscissa,'String');%list of abscissa
     VarName=xlist{xdispindex}; %selected variable name
     update_field(hObject, eventdata, handles,VarName)
%      xindex=name2index(xname,Field.ListVarName); %index of the selection in the total list of variables
%      if ~isempty(xindex)
%         set(handles.variables,'Value',xindex+1)
%         variables_Callback(hObject, eventdata, handles)
%      end
%     set(handles.variables,'Value',xindex+1)%outline  in the list of variables 
%     variables_Callback(hObject, eventdata, handles)  %display properties of the TimeVariable (dim, attributes)
%     if  ~test_2D &  ~test_scalar% look for possible varaibles to OK in ordinate    
%         index=Field.VarDimIndex{xindex};%dimension indices of the TimeVariable selected for abscissa
%         VarIndex=[];
%         for ilist=1:length(Field.VarDimIndex)%detect 
%             index_i=Field.VarDimIndex{ilist};
%             if ~isempty(index_i)
%                 if isequal(index_i(1),index(1))%if the first dimension of the TimeVariable coincide with the selected one, OK is possible
%                     VarIndex=[VarIndex ilist];
%                 end
%             end
%         end
% %         set(handles.ordinate,'Value',1)
%         set(handles.ordinate,'String',Field.ListVarName(VarIndex))
%     end
% end
% 
% update_UserData(handles)



%------------------------------------------------------------------------
% --- Executes on selection change in XVarName.
function XVarName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.XVarName,'Value');
string=get(handles.XVarName,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in ZVarName.
function ZVarName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.ZVarName,'Value');
string=get(handles.ZVarName,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in YVarName.
function YVarName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.YVarName,'Value');
string=get(handles.YVarName,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in vector_x.
function vector_x_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.vector_x,'Value');
string=get(handles.vector_x,'String');
VarName=string{index};

%check possible coordinates
Field=get(handles.get_field,'UserData');
dim_var=Field.VarDimName{index};%list of dimensions of the selected variable
test_coord=ones(size(Field.VarDimName)); %=1 when variable #ilist is eligible as coordinate
test_component=ones(size(Field.VarDimName)); %=1 when variable #ilist is eligible as other vector component
for ilist=1:numel(Field.VarDimName)
    dimnames=Field.VarDimName{ilist}; %list of dimensions for variable #ilist
    if ~isequal(dimnames,dim_var)
        test_component(ilist)=0;
    end
    for idim=1:numel(dimnames)
        if isempty(find(strcmp(dimnames{idim},dim_var),1))%dimension not found in the scalar variable
            test_coord(ilist)=0;
            break
        end
    end
end
%eliminate time
if get(handles.TimeVariable,'Value')
    TimeName=get(handles.TimeName,'String');
    index_time=find(strcmp( TimeName,Field.ListVarName));
    test_coord(index_time)=0;
end
vlength=numel(string(test_component==1));
val=get(handles.vector_y,'Value');
if val>vlength
    set(handles.vector_y,'Value',1)
end
set(handles.vector_y,'String',[string(test_component==1)])
val=get(handles.vector_z,'Value');
if val>vlength+1
    set(handles.vector_z,'Value',1)
end
set(handles.vector_z,'String',[{''};string(test_component==1)])
val=get(handles.vec_color,'Value');
if val>vlength+1
    set(handles.vec_color,'Value',1)
end
set(handles.vec_color,'String',[{''};string(test_component==1)])
string_coord=[{''};string(test_coord==1)];
val=get(handles.XVarName,'Value');
if val>numel(string_coord)
    set(handles.XVarName,'Value',1)
end
set(handles.XVarName,'Visible','on');
set(handles.XVarName,'String',string_coord);
val=get(handles.YVarName,'Value');
if val>numel(string_coord)
    set(handles.YVarName,'Value',1)
end
set(handles.YVarName,'Visible','on');
set(handles.YVarName,'String',string_coord);
val=get(handles.TimeVarName,'Value');
if val>numel(string_coord)
    set(handles.TimeVarName,'Value',1)
end
set(handles.TimeVarName,'String',string_coord);

update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in vector_y.
function vector_y_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.vector_y,'Value');
string=get(handles.vector_y,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in vector_z.
function vector_z_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.vector_z,'Value');
string=get(handles.vector_z,'String');
VarName=Astring{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in coord_x_vectors.
function coord_x_vectors_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.coord_x_vectors,'Value');
string=get(handles.coord_x_vectors,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in coord_y_vectors.
function coord_y_vectors_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.coord_y_vectors,'Value');
string=get(handles.coord_y_vectors,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in YVarName.
function TimeVarName_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.TimeVarName,'Value');
string=get(handles.TimeVarName,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in vec_color.
function vec_color_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.vec_color,'Value');
string=get(handles.vec_color,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%-----------------------------------------------------------------------
function update_field(hObject, eventdata, handles,VarName)
%-----------------------------------------------------------------------
Field=get(handles.get_field,'UserData');
index=name2index(VarName,Field.ListVarName);
if ~isempty(index)
    set(handles.variables,'Value',index+1)
    variables_Callback(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% update the UserData Field for use of the selected variables outsde get_field (taken from RUN_Callback)
function update_UserData(handles)
%------------------------------------------------------------------------
return
% global SubField
hselect_field=get(handles.inputfile,'parent');%handle of the get_field interface
Field=get(hselect_field,'UserData');% read the current field Structure in the get_field interface
if isfield(Field,'VarAttribute')
    VarAttribute=Field.VarAttribute;
else
    VarAttribute={};
end


% select the indices of field variables for 2D plots
test_CheckPlot1D=get(handles.CheckPlot1D,'Value');
test_scalar=get(handles.CheckScalar,'Value');
test_vector=get(handles.CheckVector,'Value');

%transform if needed (calibration)
list=get(handles.menu_coord,'String');
index=get(handles.menu_coord,'Value');
transform=list{index};
if ~isequal(transform,'')
    Field=feval(transform,Field);
end
VarIndex.u=[];
VarIndex.v=[];
VarIndex.w=[];
VarIndex.A=[];
VarIndex_tot=[];
iuA=[];
if test_scalar
    Astring=get(handles.scalar,'String');
    Aindex=get(handles.scalar,'Value');%selected indices in the ordinate listbox
    list_var=Astring(Aindex);
    VarIndex.A=name2index(list_var,Field.ListVarName);%index of the variable A in ListVarName
    VarIndex_tot= [VarIndex_tot VarIndex.A];
    DimIndex=Field.VarDimIndex{VarIndex.A};%dimension indices of the variable
    DimValue=Field.DimValue(DimIndex);
    ind=find(DimValue==1);
    DimIndex(ind)=[];%Mremove singleton
end
if test_vector
    Ustring=get(handles.vector_x,'String');
    Uindex=get(handles.vector_x,'Value'); %selected indices in the ordinate listbox
    list_var=Ustring{Uindex};%name of the selected scalar
    VarIndex.u=name2index(list_var,Field.ListVarName);
    Vstring=get(handles.vector_y,'String');
    Vindex=get(handles.vector_y,'Value'); %selected indices in the ordinate listbox
    list_var=Ustring{Vindex};%name of the selected scalar
    VarIndex.v=name2index(list_var,Field.ListVarName);
    if isequal(VarIndex.u,VarIndex.A)|isequal(VarIndex.v,VarIndex.A)
        iuA=VarIndex.A; %same variable used for vector and scalar
        VarIndex_tot(iuA)=[];
    end
    VarIndex_tot=[VarIndex_tot VarIndex.u VarIndex.v];
    %dimensions
    DimIndex_u=Field.VarDimIndex{VarIndex.u};%dimension indices of the variable
    DimValue=Field.DimValue(DimIndex_u);
    ind=find(DimValue==1);
    DimIndex_u(ind)=[];%Mremove singleton
    DimIndex_v=Field.VarDimIndex{VarIndex.v};%dimension indices of the variable
    DimValue=Field.DimValue(DimIndex_v);
    ind=find(DimValue==1);
    DimIndex_v(ind)=[];%Mremove singleton
    if ~isequal(DimIndex_u,DimIndex_v)
        msgbox_uvmat('ERROR','inconsistent dimensions for u and v')
        set(handles.vector_y,'Value',1); 
        return
    elseif  test_scalar & ~isequal(DimIndex_u,DimIndex)
         msgbox_uvmat('ERROR','inconsistent dimensions for vector and scalar represented as vector color')
         set(handles.scalar,'Value',1); 
         return
    end
    DimIndex=DimIndex_u;
    %TODO possibility of selecting 3 times the same TimeVariable for u, v, w components
end


% select the TimeVariable  index (or indices) for z coordinates
test_grid=0;
if test_scalar | test_vector
    nbdim=length(DimIndex);
    if nbdim > 3
        msgbox_uvmat('ERROR','array with more than three dimensions, not supported')
        return
    else
        perm_ind=1:nbdim;
    end
    if nbdim==3
        zstring=get(handles.coord_z_vectors_scalar,'String');
        zindex=get(handles.coord_z_vectors_scalar,'Value'); %selected indices in the ordinate listbox
        list_var=zstring(zindex);
        VarIndex_z=name2index(list_var,Field.ListVarName);%index of the selected variable 
        if isequal(VarIndex.A,VarIndex_z)|isequal(VarIndex.u,VarIndex_z)|isequal(VarIndex.v,VarIndex_z)|isequal(VarIndex.w,VarIndex_z)
            if zindex ~= 1
                set(handles.coord_z_vectors_scalar,'Value',1)%ordinate cannot be the same as scalar or vector components
                return
            end
        else 
            VarIndex_tot=[VarIndex_tot VarIndex_z];
            DimIndex_z=Field.VarDimIndex{VarIndex_z};
            DimValue=Field.DimValue(DimIndex_z);
            ind=find(DimValue==1);          
            DimIndex_z(ind)=[];%Mremove singleton
            if isequal(DimIndex_z,DimIndex)
                VarAttribute{VarIndex_z}.Role='coord_z';%unstructured coordinates
            elseif length(DimIndex_z)==1
                VarAttribute{VarIndex_z}.Role=Field.ListDimName{DimIndex_z};  %dimension variable
                ind_z=find(DimIndex==DimIndex_z(1));
                perm_ind(ind_z)=1;
                test_grid=1;
            else
                msgbox_uvmat('ERROR','multiple dimensions for the z coordinate')
                return
            end
        end
%         if ~isempty(VarIndex_z)
%             DimIndex_z=Field.VarDimIndex{VarIndex_z};%dimension indices of the TimeVariable    
%             if length(DimIndex_z)==1 & nbdim==3 %dimension TimeVariable
%                 VarAttribute{VarIndex_z}.Role=Field.ListDimName{DimIndex_z};
%                 ind_z=find(DimIndex==DimIndex_z(1));
%                 perm_ind(ind_z)=1;
%                 test_grid=1;
%             end
%         end
    end
end

% select the TimeVariable  index (or indices) for ordinate
ystring=get(handles.ordinate,'String');
yindex=get(handles.ordinate,'Value'); %selected indices in the ordinate listbox
list_var=ystring(yindex);
VarIndex.y=name2index(list_var,Field.ListVarName);
if isequal(VarIndex.A,VarIndex.y)
    set(handles.ZVarName,'Value',1)
elseif isequal(VarIndex.u,VarIndex.y)||isequal(VarIndex.v,VarIndex.y)||isequal(VarIndex.w,VarIndex.y)
   set(handles.coord_y_vectors,'Value',1)%ordinate cannot be the same as scalar or vector components
else
    for ivar=1:length(VarIndex.y)
        VarAttribute{VarIndex.y(ivar)}.Role='coord_y';
    end
    VarIndex_tot=[VarIndex_tot VarIndex.y];
end
if (test_scalar | test_vector) &  ~isempty(VarIndex.y)
    DimIndex_y=Field.VarDimIndex{VarIndex.y};%dimension indices of the variable
    if length(DimIndex_y)==1 
        ind_y=find(DimIndex==DimIndex_y(1));
        test_grid=1;
        if nbdim==3
            VarAttribute{VarIndex.y}.Role=Field.ListDimName{DimIndex_y};
            perm_ind(ind_y)=2;
        elseif nbdim==2
            VarAttribute{VarIndex.y}.Role=Field.ListDimName{DimIndex_y};
             perm_ind(ind_y)=1;
        end
    elseif test_grid
        msgbox_uvmat('ERROR','the dimension of the y coordinate variable should be 1')   
    end
end

%select the TimeVariable index for the abscissa
xstring=get(handles.abscissa,'String');
xindex=get(handles.abscissa,'Value');
list_var=xstring(xindex);
VarIndex.x=name2index(list_var,Field.ListVarName);%var index corresponding to var name list_var
if length(VarIndex.x)==1    
    DimIndex_x=Field.VarDimIndex{VarIndex.x};
    DimValue=Field.DimValue(DimIndex_x);
    ind=find(DimValue==1);          
    DimIndex_x(ind)=[];%Mremove singleton                      
    VarAttribute{VarIndex.x}.Role=Field.ListDimName{DimIndex_x};  %dimension variable           
%     VarAttribute{VarIndex.x}.Role='coord_x';%default (may be modified)
    index_detect=find(VarIndex_tot==VarIndex.x);
else
    index_detect=[];%coord x variable not already used
end
if isempty(index_detect)
    VarIndex_tot=[VarIndex_tot VarIndex.x]; 
elseif ~test_CheckPlot1D
    VarIndex.x=[];
    set(handles.abscissa,'Value',1)%vchosen abscissa already chosen, suppres it as abscissa
end

if (test_scalar | test_vector) &  ~isempty(VarIndex.x)
    DimIndex_x=Field.VarDimIndex{VarIndex.x};%dimension indices of the variable
    if length(DimIndex_x)==1 
        ind_x=find(DimIndex==DimIndex_x(1)); 
        if nbdim==3
            %VarAttribute{VarIndex.x}.Role=Field.ListDimName{DimIndex_x};
            perm_ind(ind_x)=3;
        elseif nbdim==2
            %VarAttribute{VarIndex.x}.Role=Field.ListDimName{DimIndex_x};
             perm_ind(ind_x)=2;
        end
        if isequal(perm_ind,1:nbdim)
            test_grid=0;
        end
        DimIndex=DimIndex(perm_ind);
    elseif test_grid
        msgbox_uvmat('ERROR','the dimension of the x coordinate variable should be 1')   
    end
    if isequal(DimIndex_x,DimIndex)
                VarAttribute{VarIndex.x}.Role='coord_x';%unstructured coordinates
    end
end

%defined the selected sub-field SubField
SubField.ListGlobalAttribute{1}='InputFile';
SubField.InputFile=get(handles.inputfile,'String');
SubField.ListDimName=Field.ListDimName;
SubField.DimValue=Field.DimValue;
SubField.ListVarName=Field.ListVarName(VarIndex_tot);
SubField.VarDimIndex=Field.VarDimIndex(VarIndex_tot);

testperm=0;
testattr=0;
for ivar=VarIndex.u
    VarAttribute{ivar}.Role='vector_x';
    testattr=1;
    if test_grid
        VarDimIndex{ivar}=DimIndex; %permute dimensions
        testperm=1;
    end
end
for ivar=VarIndex.v
    VarAttribute{ivar}.Role='vector_y';
    testattr=1;
     if test_grid
        VarDimIndex{ivar}=DimIndex;%permute dimensions
        testperm=1;
    end
end
for ivar=VarIndex.A
    if test_grid
        VarDimIndex{ivar}=DimIndex;%permute dimensions
        testperm=1;
    end
    if isempty(iuA)
        VarAttribute{ivar}.Role='scalar';%Role =scalar
        testattr=1;
    else
       VarAttribute=[VarAttribute VarAttribute(ivar)]; %duplicate the attribute for a new variable
       nbattr=length(VarAttribute);
       VarAttribute{nbattr}.Role='scalar';
       testattr=1;
    end
end
if testperm
    SubField.VarDimIndex=VarDimIndex(VarIndex_tot);
end
if testattr
    SubField.VarAttribute=VarAttribute(VarIndex_tot);
end
set(hselect_field,'UserData',Field)

%---------------------------------------------------------
% --- Executes on button press in OK.

function OK_Callback(hObject, eventdata, handles)
%---------------------------------------------------------

handles.output=read_GUI(handles.get_field);
guidata(hObject, handles);% Update handles structure
uiresume(handles.get_field);
drawnow
return

%%%% SKIPPED %%%%
hfield=[];
huvmat=findobj(allchild(0),'tag','uvmat');
hseries=findobj(allchild(0),'tag','series');
check_series=0;
% look for the status of the GUI uvmat
if ~isempty(huvmat)
    hh=guidata(huvmat);
    FieldMenu=get(hh.FieldName,'String');
    FieldName=FieldMenu{get(hh.FieldName,'Value')};
    if strcmp(FieldName,'get_field...')
        hfield=hh.FieldName; %FieldName on uvmat
    elseif strcmp(get(hh.FieldName_1,'Visible'),'on')
        FieldMenu=get(hh.FieldName_1,'String');
        if ~isempty(FieldMenu)
            FieldName=FieldMenu{get(hh.FieldName_1,'Value')};
            if strcmp(FieldName,'get_field...')
                hfield=hh.FieldName_1; %FieldName_1 on uvmat
            end
        end
    end
end
% if no filed data is concerned on uvmat, look at the GUI series
if isempty(hfield) && ~isempty(hseries)
    check_series=1;
    hh=guidata(hseries);
    FieldMenu=get(hh.FieldName,'String');
    FieldName=FieldMenu{get(hh.FieldName,'Value')};
    if strcmp(FieldName,'get_field...')
        hfield=hh.FieldName; %FieldName on series
    else
       FieldMenu=get(hh.FieldName_1,'String');
       FieldName=FieldMenu{get(hh.FieldName_1,'Value')};
       if strcmp(FieldName,'get_field...')
            hfield=hh.FieldName_1; %FieldName_1 on series
       end
    end
end
if ~isempty(hfield)
    get_field_GUI=read_GUI(handles.get_field);
    if isfield(get_field_GUI,'PanelVectors')
        set(hh.Coord_x,'value',1)
        set(hh.Coord_y,'value',1)
        set(hh.Coord_x,'String',{get_field_GUI.PanelVectors.coord_x_vectors})
        set(hh.Coord_y,'String',{get_field_GUI.PanelVectors.coord_y_vectors})
        UName=get_field_GUI.PanelVectors.vector_x;
        VName=get_field_GUI.PanelVectors.vector_y;
        menu_str=[{['vec(' UName ',' VName ')']};{UName};{VName};{['norm(' UName ',' VName ')']};{'get_field...'}];
        menu_color=[{''};{UName};{VName};{['norm(' UName ',' VName ')']}];
        set(hfield,'Value',1)
        set(hfield,'String',menu_str)
        if ~check_series
            ind_menu=find(strcmp(get_field_GUI.PanelVectors.vec_color,menu_color));
            if ~isempty(ind_menu)
                set(hh.ColorScalar,'Value',ind_menu)
            else
                set(hh.ColorScalar,'Value',1)
            end
            set(hh.ColorScalar,'String',menu_color)
        end
    elseif isfield(get_field_GUI,'PanelScalar')
        set(hh.Coord_x,'value',1)
        set(hh.Coord_y,'value',1)
        set(hh.Coord_x,'String',{get_field_GUI.PanelScalar.coord_x_scalar})
        set(hh.Coord_y,'String',{get_field_GUI.PanelScalar.coord_y_scalar})
        AName=get_field_GUI.PanelScalar.scalar;
        menu=get(hfield,'String');
        ind_select=find(strcmp(AName,menu));
        if isempty(ind_select)
            menu=[menu(1:end-1);{AName};{'get_field...'}];
            ind_select=numel(menu)-1;
        end 
        set(hfield,'Value',ind_select);
        set(hfield,'String',menu);
    elseif isfield(get_field_GUI,'Panel1Dplot')
        set(hh.Coord_x,'Value',1)
        set(hh.Coord_x,'String',{get_field_GUI.Panel1Dplot.abscissa})
        set(hh.Coord_y,'String',get_field_GUI.Panel1Dplot.ordinate)
        set(hh.Coord_y,'Max', numel(get_field_GUI.Panel1Dplot.ordinate))
        set(hh.Coord_y,'Value',1:numel(get_field_GUI.Panel1Dplot.ordinate))
        set(hfield,'Value',1)
        set(hfield,'String',[{''};{'get_field...'}])
    end
    if  ~check_series && strcmp(get(gcbf,'tag'),'get_field')%get_field is not called by another GUI (uvmat)
        uvmat('run0_Callback',hObject,eventdata,hh); %refresh uvmat
    end
end
delete(handles.get_field)



%-------------------------------------------------
% give index numbers of the strings str in the list ListvarName
function VarIndex_y=name2index(cell_str,ListVarName)
VarIndex_y=[];
if ischar(cell_str)
    for ivar=1:length(ListVarName)
        varlist=ListVarName{ivar};
        if isequal(varlist,cell_str)
            VarIndex_y= ivar;
            break
        end
    end
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


% -----------------------------------------------------------------------
function TimeName_Callback(hObject, eventdata, handles)

scalar_Callback(hObject, eventdata, handles)% suppress time variable from possible spatial coordinates
vector_x_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on button press in TimeAttribute.
function TimeAttribute_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
val=get(handles.TimeAttribute,'Value');
if val
    set(handles.TimeAttributeMenu,'Visible','on')
    Field=get(handles.get_field,'UserData');
    time_value=zeros(size(Field.ListGlobalAttribute));
    test_time=zeros(size(Field.ListGlobalAttribute));
    for ilist=1:numel(Field.ListGlobalAttribute)
        if isnumeric(eval(['Field.' Field.ListGlobalAttribute{ilist}]))
            eval(['time_val=Field.' Field.ListGlobalAttribute{ilist} ';'])
            if ~isempty(time_val)
                time_value(ilist)=time_val;
                test_time(ilist)=1;
            end
        end
    end
    ListTimeAttribute=Field.ListGlobalAttribute(test_time==1);
    attr_index=get(handles.TimeAttributeMenu,'Value');
    if attr_index>numel(ListTimeAttribute)
        attr_index=1;
        set(handles.TimeAttributeMenu,'Value',1);
    end
    if isempty(ListTimeAttribute)
        set(handles.TimeAttributeMenu,'String',{''})
        set(handles.TimeValue,'Visible','off')
    else
        set(handles.TimeValue,'Visible','on')
        set(handles.TimeAttributeMenu,'String',ListTimeAttribute)
        set(handles.TimeValue,'String',num2str(time_value(attr_index)))
    end
    set(handles.TimeDimension,'Value',0)
    TimeDimension_Callback(hObject, eventdata, handles)
    set(handles.TimeVariable,'Value',0)
    TimeVariable_Callback(hObject, eventdata, handles)
else
    set(handles.TimeAttributeMenu,'Visible','off')
    set(handles.TimeValue,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on selection change in TimeAttributeMenu.
function TimeAttributeMenu_Callback(hObject, eventdata, handles)
 ListTimeAttribute=get(handles.TimeAttributeMenu,'String');
 index=get(handles.TimeAttributeMenu,'Value');
 AttrName=ListTimeAttribute{index};
 Field=get(handles.get_field,'UserData');
 eval(['time_val=Field.' AttrName ';'])
 set(handles.TimeValue,'String',num2str(time_val))
%------------------------------------------------------------------------

%------------------------------------------------------------------------
% --- Executes on button press in TimeVariable.
function TimeDimension_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
val=get(handles.TimeDimension,'Value');%=1 if check box TimeDimension is selected
if val  %if check box TimeDimension is selected
    Field=get(handles.get_field,'UserData');% structure describing the currently opened field
    previous_menu=get(handles.TimeDimensionMenu,'String');
    if ~isequal(previous_menu,Field.ListDimName)%update the list of available dimensions in the menu
        ind_select=find(strcmpi('time',Field.ListDimName),1);% look for a dimension named 'time' or 'Time'
        if isempty(ind_select)
            ind_select=1;% select the first item in the list if 'time' is not found
        end
        set(handles.TimeDimensionMenu,'Value',ind_select);
        set(handles.TimeDimensionMenu,'String',Field.ListDimName)% put the list of available dimensions in the menu
    end    
    set(handles.TimeDimensionMenu,'Visible','on')% the menu is made visible
    set(handles.TimeIndexValue,'Visible','on')% the time matrix index value selected is made visible
    TimeDimensionMenu_Callback(hObject, eventdata, handles)  
    set(handles.TimeAttribute,'Value',0) %deselect alternative options for time
    set(handles.TimeVariable,'Value',0)
    TimeAttribute_Callback(hObject, eventdata, handles)
else
    set(handles.TimeDimensionMenu,'Visible','off')
    set(handles.TimeIndexValue,'Visible','off')
end
% 
% %------------------------------------------------------------------------
% % --- Executes on selection change in TimeDimensionMenu.
% function TimeDimensionMenu_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% index=get(handles.TimeDimensionMenu,'Value');
% DimList=get(handles.TimeDimensionMenu,'String');
% DimName=DimList{index};
% Field=get(handles.get_field,'UserData');
% DimIndex=find(strcmp(DimName,Field.ListDimName),1);
% ref_index=round(Field.DimValue(DimIndex)/2);   
% set(handles.TimeIndexValue,'String',num2str(ref_index))
% scalar_Callback(hObject, eventdata, handles)
% vector_x_Callback(hObject, eventdata, handles)% update menus of coordinates (remove time)
%  % look for a corresponding time variable and value
%  time_test=zeros(size(Field.VarDimName));
%  for ilist=1:numel(Field.VarDimName)
%      if isequal(Field.VarDimName{ilist},{DimName})
%          time_test(ilist)=1;
%      end
%  end
%  ListVariable=Field.ListVarName(time_test==1);
%  set(handles.TimeVariableMenu,'Value',1)
%  if isempty(ListVariable)     
%      set(handles.TimeVariableMenu,'String',{''})
%      set(handles.TimeVarValue,'String','')
%  else
%     set(handles.TimeVariableMenu,'String',ListVariable)
%     TimeVarName=ListVariable{1};
%     VarIndex=find(strcmp(TimeVarName,Field.ListVarName),1);%index in the list of variables
%     inputfile=get(handles.inputfile,'String');% read the input file
%     SubField=nc2struct(inputfile,{TimeVarName});
%     eval(['TimeValue=SubField.' TimeVarName '(ref_index);'])
%     set(handles.TimeVarValue,'Visible','on')
%     set(handles.TimeVariableMenu,'Visible','on')
%     set(handles.TimeVarValue,'String',num2str(TimeValue))
%  end
% 
% 
% % % -----------------------------------------------------------------------
% % % --- Executes on button press in TimeVariable.
% % function TimeVariable_Callback(hObject, eventdata, handles)
% % % -----------------------------------------------------------------------
% % val=get(handles.TimeVariable,'Value');
% % if val
% %     Field=get(handles.get_field,'UserData');
% %     time_test=zeros(size(Field.VarDimName));
% %     for ilist=1:numel(Field.VarDimName)
% %         if isequal(numel(Field.VarDimName{ilist}),1)%select variables with a single dimension
% %             time_test(ilist)=1;
% %         end
% %     end
% %     ind_test=find(time_test);
% %     if isempty(time_test)
% %         set(handles.TimeVariable,'Value',0)
% %         set(handles.TimeVariableMenu,'Visible','off')
% %         set(handles.TimeVarValue,'Visible','off')
% %     else
% %         set(handles.TimeVariableMenu,'Visible','on')
% %         set(handles.TimeVarValue,'Visible','on')
% %         if get(handles.TimeVariableMenu,'Value')>numel(ind_test)
% %             set(handles.TimeVariableMenu,'Value',1)
% %         end
% %         set(handles.TimeVariableMenu,'String',Field.ListVarName(ind_test))
% %         TimeVariableMenu_Callback(hObject, eventdata, handles)
% %         set(handles.TimeDimension,'Value',0) %deseselect alternative option sfor time
% %         set(handles.TimeAttribute,'Value',0)
% %         TimeAttribute_Callback(hObject, eventdata, handles)
% %     end
% % else
% %     set(handles.TimeVariableMenu,'Visible','off')
% %     set(handles.TimeVarValue,'Visible','off')
% % end
% 
% % -----------------------------------------------------------------------
% % --- Executes on selection change in TimeVariableMenu.
% function TimeVariableMenu_Callback(hObject, eventdata, handles)
% % -----------------------------------------------------------------------
% ListVar=get(handles.TimeVariableMenu,'String');
% index=get(handles.TimeVariableMenu,'Value');
% TimeVariable=ListVar{index};% name of the selected variable
% if isempty(TimeVariable)% case of blank selection
%     return
% end
% Field=get(handles.get_field,'UserData'); %index of 
% VarIndex=find(strcmp(TimeVariable,Field.ListVarName),1);%index in the list of variables
% DimName=Field.VarDimName{VarIndex}; % dimension corresponding to the variable
% set(handles.TimeDimensionMenu,'Value',1)
% set(handles.TimeDimensionMenu,'String',DimName)
% inputfile=get(handles.inputfile,'String');% read the input file
% SubField=nc2struct(inputfile,{TimeVariable});
% eval(['TimeDimension=numel(SubField.' TimeVariable ');'])
% ref_index=round(TimeDimension/2);
% eval(['TimeValue=SubField.' TimeVariable '(ref_index);'])
% set(handles.TimeIndexValue,'String',num2str(ref_index))
% set(handles.TimeVarValue,'String',num2str(TimeValue))


% --- Executes on button press in check_rgb.
function check_rgb_Callback(hObject, eventdata, handles)


% --- Executes when user attempts to close get_field.
function get_field_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(handles.get_field, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(handles.get_field);
else
    % The GUI is no longer waiting, just close it
    delete(handles.get_field);
end



%------------------------------------------------------------------------
% --- Executes on selection change in SwitchVarIndexX.
%------------------------------------------------------------------------
function SwitchVarIndexX_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on selection change in SwitchVarIndexTime.
%------------------------------------------------------------------------
function SwitchVarIndexTime_Callback(hObject, eventdata, handles)

menu=get(handles.SwitchVarIndexTime,'String');
option=menu{get(handles.SwitchVarIndexTime,'Value')};
Field=get(handles.get_field,'UserData');
switch option
    case 'file index'
        set(handles.TimeVarName, 'Visible','off')
    case 'attribute'
        set(handles.TimeVarName, 'Visible','on')
        time_index=[];
        PreviousList=get(handles.TimeVarName, 'String');
         index=[];
        if ~isempty(PreviousList)
        PreviousAttr=PreviousList{get(handles.TimeVarName, 'Value')};
        index=find(strcmp(PreviousAttr,Field.ListNumAttributes));
        end
        if isempty(index)
            time_index=find(~cellfun('isempty',regexp(Field.ListNumAttributes,'Time')));% index of the attributes containing the string 'Time'
        end
        if ~isempty(time_index)
            set(handles.TimeVarName,'Value',time_index(1))
        else
            set(handles.TimeVarName,'Value',1)
        end
        set(handles.TimeVarName, 'String',Field.ListNumAttributes)
    case 'variable'
        set(handles.TimeVarName, 'Visible','on')
        TimeVarName=Field.SingleVarName;
        List=get(handles.TimeVarName,'String');
        option=List{get(handles.TimeVarName,'Value')};
        ind=find(strcmp(option,TimeVarName));
        if isempty(ind)
            set(handles.TimeVarName, 'Value',1);
        else
            set(handles.TimeVarName, 'Value',ind);
        end
        set(handles.TimeVarName, 'String',TimeVarName)
    case 'dim index'
        set(handles.TimeVarName, 'Visible','on')
        TimeVarName=Field.SingleDimName;
        List=get(handles.TimeVarName,'String');
        option=List{get(handles.TimeVarName,'Value')};
        ind=find(strcmp(option,TimeVarName));
        if isempty(ind)
            set(handles.TimeVarName, 'Value',1);
        else
            set(handles.TimeVarName, 'Value',ind);
        end
        set(handles.TimeVarName, 'String',TimeVarName)
end

% --- Executes on selection change in FieldOption.
function FieldOption_Callback(hObject, eventdata, handles)
FieldList=get(handles.FieldOption,'String');
FieldOption=FieldList{get(handles.FieldOption,'Value')};
switch FieldOption
    case '1D plot'
        set(handles.Panel1Dplot,'Visible','on')
        pos=get(handles.Panel1Dplot,'Position');
        pos(1)=2;
        pos_coord=get(handles.Coordinates,'Position');
        pos(2)=pos_coord(2)-pos(4)-2;
        set(handles.Panel1Dplot,'Position',pos)
        set(handles.PanelScalar,'Visible','off')
        set(handles.PanelVectors,'Visible','off')
        set(handles.YVarName,'Visible','off')
        %    set(handles.SwitchVarIndexY,'Visible','off')
        set(handles.Y_title,'Visible','off')
        set(handles.ZVarName,'Visible','off')
        %   set(handles.SwitchVarIndexZ,'Visible','off')
        set(handles.Z_title,'Visible','off')
    case 'scalar'
        set(handles.Panel1Dplot,'Visible','off')
        set(handles.PanelScalar,'Visible','on')
        set(handles.PanelVectors,'Visible','off')
        pos=get(handles.PanelScalar,'Position');
        pos(1)=2;
        pos_coord=get(handles.Coordinates,'Position');
        pos(2)=pos_coord(2)-pos(4)-2;
        set(handles.PanelScalar,'Position',pos)
        set(handles.YVarName,'Visible','on')
        set(handles.Y_title,'Visible','on')
    case 'vectors'
        set(handles.Panel1Dplot,'Visible','off')
        set(handles.PanelScalar,'Visible','off')
        set(handles.PanelVectors,'Visible','on')
        pos=get(handles.PanelVectors,'Position');
        pos(1)=2;
        pos_coord=get(handles.Coordinates,'Position');
        pos(2)=pos_coord(2)-pos(4)-2;
        set(handles.PanelVectors,'Position',pos)
        set(handles.YVarName,'Visible','on')
        set(handles.Y_title,'Visible','on')
end
