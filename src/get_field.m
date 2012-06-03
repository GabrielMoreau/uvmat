%'get_field': display variables and attributes from a Netcdf file, and RUN selected fields
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

% Last Modified by GUIDE v2.5 31-May-2012 22:52:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
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
function get_field_OpeningFcn(hObject, eventdata, handles,filename,multiple)
%------------------------------------------------------------------------
global nb_builtin % nbre of functions to include by default in the menu of  functions called by RUN



%% Choose default command line output for get_field
handles.output = hObject;

%% Update handles structure
guidata(hObject, handles);
set(hObject,'WindowButtonDownFcn',{'mouse_down'}) % allows mouse action with right button (zoom for uicontrol display)

%% prepare the list of RUN fcts and set their paths
% functions included by default in 'get_field.m
menu_str={'PLOT';'FFT';'filter_band'}; 
nb_builtin=numel(menu_str);
path_uvmat=fileparts(which('uvmat'));%path of the function 'uvmat'
addpath(fullfile(path_uvmat,'get_field'))
testexist=zeros(size(menu_str'));%default
for ilist=1:length(menu_str)
    if exist(menu_str{ilist},'file')
        fct_handle{ilist,1}=str2func(menu_str{ilist});
        testexist(ilist)=1;
    else
        fct_handle{ilist,1}=[];
        testexist(ilist)=0;
    end
end
rmpath(fullfile(path_uvmat,'get_field'))
dir_perso=prefdir;

% look for functions previously used (names and paths saved in the personal file uvmat_perso.mat):
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
      h=load (profil_perso);
     if isfield(h,'get_field_fct') && iscell(h.get_field_fct)
         for ilist=1:length(h.get_field_fct)
            [path,file]=fileparts(h.get_field_fct{ilist});
            addpath(path)        
            if exist(file,'file')
                h_func=str2func(file);
                testexist=[testexist 1]; 
             else
                h_func=[];
                testexist=[testexist 0]; 
             end
             fct_handle=[fct_handle; {h_func}]; %concatene the list of paths
             rmpath(path)
             menu_str=[menu_str; {file}]; 
         end
     end
end

menu_str=menu_str(testexist==1);%=menu_str(testexist~=0)
fct_handle=fct_handle(testexist==1);
menu_str=[menu_str;{'more...'}];
set(handles.ACTION,'String',menu_str)
set(handles.ACTION,'UserData',fct_handle)% store the list of path in UserData of ACTION
set(handles.path_action,'String',fullfile(path_uvmat,'get_field'))
set(handles.ACTION,'Value',1)% PLOT option selected

%% settings for 'slave' mode, called by uvamt, or 'master' mode
if exist('filename','var') && ischar(filename) %transfer input file name in slave mode
    set(handles.inputfile,'String',filename)% prefill the input file name
    Field=nc2struct(filename,[]);% reads the whole field
    if isfield(Field,'Txt')
        msgbox_uvmat('ERROR',Field.Txt)
    else
        set(handles.get_field,'UserData',Field);
        Field_input(eventdata,handles,Field);
    end
else  %master mode
    set(handles.inputfile,'String','')
end

%% load the list of previously browsed files for the upper bar menu Open
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');%
if exist(profil_perso,'file')
    h=load (profil_perso);
    if isfield(h,'MenuFile_1')
        set(handles.MenuFile_1,'Label',h.MenuFile_1);
    end
    if isfield(h,'MenuFile_1')
        set(handles.MenuFile_2,'Label',h.MenuFile_2);
    end
    if isfield(h,'MenuFile_1')
        set(handles.MenuFile_3,'Label',h.MenuFile_3);
    end
    if isfield(h,'MenuFile_1')
        set(handles.MenuFile_4,'Label',h.MenuFile_4);
    end
    if isfield(h,'MenuFile_1')
        set(handles.MenuFile_5,'Label',h.MenuFile_5);
    end
end

%% put the GUI on the lower right of the sceen
pos_view_field=get(hObject,'Position');
ScreenSize=get(0,'ScreenSize');
pos_view_field(1)=ScreenSize(1)+ScreenSize(3)-pos_view_field(3);
pos_view_field(2)=ScreenSize(2);
set(hObject,'Position',pos_view_field)

%% remove already opened get_field GUI with name get_field
if ~(exist('multiple','var') && isequal(multiple,1)) %set single occurrence
    hget_field=findobj(allchild(0),'Name','get_field'); %hget_field(1)= new GUI
    if length(hget_field)>1
        delete(hget_field(2))
    end
else
    set(hObject,'name','get_field_1')
end


%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = get_field_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
varargout{1} = handles.output;

%------------------------------------------------------------------------
% --- Executes when a new input file name is introduced.
function inputfile_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
inputfile=get(handles.inputfile,'String');
Field=nc2struct(inputfile,[]);% reads the  field description, without data
if isfield(Field,'Txt')
    msgbox_uvmat('ERROR',Field.Txt)
else
set(handles.get_field,'UserData',Field);
Field_input(eventdata,handles,Field);
end
huvmat=findobj(allchild(0),'tag','uvmat');
if ~isempty(huvmat)
    delete(huvmat)%delete uvmat for plot reinitialisation 
end

%------------------------------------------------------------------------
% --- update the display when a new field is introduced.
function Field_input(eventdata,handles,Field)
%------------------------------------------------------------------------
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
Txt=Field.ListVarName;
set(handles.variables,'Value',1)
set(handles.variables,'String',[{'*'} Txt])
variables_Callback(handles.variables,[], handles)
set(handles.abscissa,'String',[{''} Txt ])
set(handles.ordinate,'String',Txt)
set(handles.vector_x,'String',[Txt ])
set(handles.vector_y,'String',[Txt ])
set(handles.vector_z,'String',[{''} Txt ])
set(handles.vec_color,'String',[{''} Txt ])
set(handles.coord_x_scalar,'String',[{''} Txt ])
set(handles.coord_y_scalar,'String',[{''} Txt ])
set(handles.coord_x_vectors,'String',[{''} Txt ])
set(handles.coord_y_vectors,'String',[{''} Txt ])
set(handles.coord_z_scalar,'String',[{''} Txt ])
set(handles.coord_z_vectors,'String',[{''} Txt ])
set(handles.scalar,'Value',1)

set(handles.scalar,'String', Txt )
[CellVarIndex,NbDim,VarType,errormsg]=find_field_indices(Field);
if ~isempty(errormsg)  
    msgbox_uvmat('ERROR',['error in get_field/Field_input/find_field_indices: ' errormsg])
    return
end  
for icell=1:numel(CellVarIndex)
    NbDim(icell)=max(NbDim(icell),numel(CellVarIndex{icell}));
end
[maxdim,imax]=max(NbDim);
   
if maxdim>=3
    set(handles.vector_z,'Visible','on')
    set(handles.vector_z,'String',[{''} Txt ])
    set(handles.coord_z_vectors,'Visible','on')
    set(handles.coord_z_vectors,'String',[{''} Txt ])
    set(handles.coord_z_scalar,'Visible','on')
    set(handles.coord_z_scalar,'String',[{''} Txt ])
else
    set(handles.vector_z,'Visible','off')
    set(handles.coord_z_vectors,'Visible','off')
    set(handles.coord_z_scalar,'Visible','off')
end
if maxdim>=2 
    set(handles.check_1Dplot,'Value',0)
    if ~isempty(VarType{imax}.vector_x) && ~isempty(VarType{imax}.vector_y)      
        set(handles.check_vector,'Value',1)
        set(handles.check_scalar,'Value',0)
        set(handles.vector_x,'Value',VarType{imax}.vector_x(1))
        set(handles.vector_y,'Value',VarType{imax}.vector_y(1))
        if ~isempty(VarType{imax}.coord_x) && ~isempty(VarType{imax}.coord_y)
            set(handles.coord_x_vectors,'Value',VarType{imax}.coord_x+1)
            set(handles.coord_y_vectors,'Value',VarType{imax}.coord_y+1)
        end
        if ~isempty(VarType{imax}.coord) 
            set(handles.coord_y_vectors,'Value',VarType{imax}.coord(1)+1)
            if numel(VarType{imax}.coord)>=2
                set(handles.coord_x_vectors,'Value',VarType{imax}.coord(2)+1)
            end
        end
    else
        set(handles.check_scalar,'Value',1)
        set(handles.check_vector,'Value',0)
        if isfield(VarType{imax},'scalar') && length(VarType{imax}.scalar)>=1
            set(handles.scalar,'Value',VarType{imax}.scalar(1))
            if ~isempty(VarType{imax}.coord_x) && ~isempty(VarType{imax}.coord_y)
                set(handles.coord_x_scalar,'Value',VarType{imax}.coord_x+1)
                set(handles.coord_y_scalar,'Value',VarType{imax}.coord_y+1)
            end
            if ~isempty(VarType{imax}.coord_z) 
                set(handles.coord_z_scalar,'Value',VarType{imax}.coord_z+1)
            end
            if ~isempty(VarType{imax}.coord)
                if numel(VarType{imax}.coord)>=maxdim-2 && maxdim>=3
                    set(handles.coord_z_scalar,'Value',VarType{imax}.coord(maxdim-2)+1)
                end
                if numel(VarType{imax}.coord)>=maxdim-1
                    set(handles.coord_y_scalar,'Value',VarType{imax}.coord(maxdim-1)+1)
                end
                if numel(VarType{imax}.coord)>=maxdim
                    set(handles.coord_x_scalar,'Value',VarType{imax}.coord(maxdim)+1)
                end     
            end
        end
    end
    check_1Dplot_Callback(handles.check_1Dplot, eventdata, handles)
    check_scalar_Callback(handles.check_scalar, eventdata, handles)
    check_vector_Callback(handles.check_vector, eventdata, handles)
end
%scalar_Callback(handles.get_field, eventdata, handles)
%vector_x_Callback(handles.get_field, eventdata, handles)

%------------------------------------------------------------------------
function ordinate_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
hselect_field=get(handles.inputfile,'parent');
Field=get(hselect_field,'UserData');
list=get(handles.ordinate,'String');
yindex=get(handles.ordinate,'Value');
yindex=name2index(list{yindex(1)},Field.ListVarName);
if ~isempty(yindex)
    set(handles.variables,'Value',yindex+1)
    variables_Callback(hObject, eventdata, handles)
end
[CellVarIndex,NbDim,VarType,errormsg]=find_field_indices(Field);
for icell=1:numel(CellVarIndex)
    VarIndex=CellVarIndex{icell};
    if ~isempty(find(VarIndex==yindex,1)) && (isempty(VarType{icell}.coord_x)||~isequal(VarType{icell}.coord_x,VarIndex))
        cell_select=icell;
        break
    end
end

val=get(handles.abscissa,'Value');
set(handles.abscissa,'Value',min(val,2));
coord_x_index=VarType{cell_select}.coord;
coord_x_index=coord_x_index(coord_x_index~=0);
set(handles.abscissa,'String',[{''}; (Field.ListVarName(coord_x_index))'; (Field.ListVarName(VarIndex))'])

%------------------------------------------------------------------------
% --- Executes on selection change in abscissa.
function abscissa_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
 hselect_field=get(handles.inputfile,'parent');
 Field=get(hselect_field,'UserData');%current input field
 xdispindex=get(handles.abscissa,'Value');%index in the list of abscissa
% test_2D=get(handles.check_vector,'Value');% =1 for vector fields
% test_scalar=get(handles.check_scalar,'Value');% =1 for scalar fields
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
%     if  ~test_2D &  ~test_scalar% look for possible varaibles to RUN in ordinate    
%         index=Field.VarDimIndex{xindex};%dimension indices of the TimeVariable selected for abscissa
%         VarIndex=[];
%         for ilist=1:length(Field.VarDimIndex)%detect 
%             index_i=Field.VarDimIndex{ilist};
%             if ~isempty(index_i)
%                 if isequal(index_i(1),index(1))%if the first dimension of the TimeVariable coincide with the selected one, RUN is possible
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
% --- Executes on selection change in scalar menu.
function scalar_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.scalar,'Value');
string=get(handles.scalar,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%eliminate time
TimeDimName='';%default
if strcmp(get(handles.TimeDimensionMenu,'Visible'),'on')
    TimeDimList=get(handles.TimeDimensionMenu,'String');
    TimeDimIndex=get(handles.TimeDimensionMenu,'Value');
    TimeDimName=TimeDimList{TimeDimIndex};
end

%check possible coordinates
Field=get(handles.get_field,'UserData');
dim_scalar=Field.VarDimName{index};%list of dimensions of the selected scalar
test_coord=ones(size(Field.VarDimName)); %=1 when variable #ilist is eligible as coordinate
for ilist=1:numel(Field.VarDimName)
    dimnames=Field.VarDimName{ilist}; %list of dimensions for variable #ilist
    if isequal(dimnames,{TimeDimName})
        test_coord(ilist)=0;%mark time variables fo elimination
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
val=get(handles.coord_x_scalar,'Value');
if val>numel(string_coord)
    set(handles.coord_x_scalar,'Value',1)
end
set(handles.coord_x_scalar,'String',string_coord);
val=get(handles.coord_y_scalar,'Value');
if val>numel(string_coord)
    set(handles.coord_y_scalar,'Value',1)
end
set(handles.coord_y_scalar,'String',string_coord);
val=get(handles.coord_y_scalar,'Value');
if val>numel(string_coord)
    set(handles.coord_y_scalar,'Value',1)
end
set(handles.coord_z_scalar,'String',string_coord);


%------------------------------------------------------------------------
% --- Executes on selection change in coord_x_scalar.
function coord_x_scalar_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.coord_x_scalar,'Value');
string=get(handles.coord_x_scalar,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in coord_y_scalar.
function coord_y_scalar_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.coord_y_scalar,'Value');
string=get(handles.coord_y_scalar,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%------------------------------------------------------------------------
% --- Executes on selection change in coord_z_scalar.
function coord_z_scalar_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.coord_z_scalar,'Value');
string=get(handles.coord_z_scalar,'String');
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
dim_var=Field.VarDimName{index};%list of dimensions of the selected scalar
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
val=get(handles.coord_x_vectors,'Value');
if val>numel(string_coord)
    set(handles.coord_x_vectors,'Value',1)
end
set(handles.coord_x_vectors,'String',string_coord);
val=get(handles.coord_y_vectors,'Value');
if val>numel(string_coord)
    set(handles.coord_y_vectors,'Value',1)
end
set(handles.coord_y_vectors,'String',string_coord);
val=get(handles.coord_z_vectors,'Value');
if val>numel(string_coord)
    set(handles.coord_z_vectors,'Value',1)
end
set(handles.coord_z_vectors,'String',string_coord);

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
% --- Executes on selection change in coord_z_scalar.
function coord_z_vectors_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.coord_z_vectors,'Value');
string=get(handles.coord_z_vectors,'String');
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
test_check_1Dplot=get(handles.check_1Dplot,'Value');
test_scalar=get(handles.check_scalar,'Value');
test_vector=get(handles.check_vector,'Value');

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
    set(handles.coord_y_scalar,'Value',1)
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
elseif ~test_check_1Dplot
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
% --- Executes on button press in RUN.

function RUN_Callback(hObject, eventdata, handles)
%---------------------------------------------------------
set(handles.RUN,'BackgroundColor',[1 1 0])% mark use of RUN action
test_fig=get(handles.SelectFigure,'Value');

% plot requested in uvmat
if ~test_fig
    inputfile=get(handles.inputfile,'String');
    huvmat=findobj(allchild(0),'tag','uvmat');
    if isempty(huvmat)
        input.InputFile=inputfile;
        input.FieldsString={'get_field...'};
        uvmat(input)
    else
        set(huvmat,'Visible','on')%make uvmat visible (bugs can hide it in some cases)
        hhuvmat=guidata(huvmat);
        set(hhuvmat.Fields,'Value',1)
        set(hhuvmat.Fields,'String',{'get_field...'})
        uvmat('run0_Callback',hObject,eventdata,hhuvmat); % display field in uvmat
    end
   
% other kind of plot
else  %TODO: check and update: add plot on an existing axes
    figcell=get(handles.list_fig,'String');
    index=get(handles.list_fig,'value');
    figstring=figcell{index};
    index=get(handles.ACTION,'Value');
    list_func=get(handles.ACTION,'UserData');
    h_fun=list_func{index};
    set(handles.RUN,'BackgroundColor',[0.831 0.816 0.784])
    drawnow
    SubField=h_fun(handles.get_field);%handles.figure1 =handles of the GUI get_field
    if ~isempty(SubField)
        plot_get_field(SubField,handles)
    end
    browse_fig(handles.list_fig); %update the list of new existing figures
end
set(handles.RUN,'BackgroundColor',[1 0 0])

%------------------------------------------------------------------------
% --- Function for plotting the current subfield
function plot_get_field(SubField,handles)
%------------------------------------------------------------------------
list_fig=get(handles.list_fig,'String');
val=get(handles.list_fig,'Value');
if strcmp(list_fig{val},'uvmat')
    set(handles.inputfile,'Enable','off')% desactivate the input file edit box   
    set(handles.RUN,'Visible','off')% RUN button not visible (passive mode, get_field used to define the field for uvamt)
    set(handles.MenuOpen,'Visible','off')
    set(handles.MenuExport,'Visible','off')
    uvmat(get(handles.inputfile,'String'))
elseif strcmp(list_fig{val},'view_field')
    view_field(SubField)
else
    hfig=str2double(list_fig{val});% chosen figure number from tyhe GUI
    if isnan(hfig)
        hfig=figure;
        list_fig=[list_fig;num2str(hfig)];
        set(handles.list_fig,'String',list_fig);
        haxes=axes;
    else
        figure(hfig);
    end
    haxes=findobj(hfig,'Type','axes');
    plot_field(SubField,haxes) 
end

% %------------------------------------------------
% % --- Executes on button press in Plot_histo.
% %RUN global histograms
% %-------------------------------------------------
% function RUN_histo_Callback(hObject, eventdata, handles)
% % hObject    handle to RUN (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% %timename plots
% leg={};
% n=0;
% if (get(handles.cm_switch,'Value')==1)
%     Uval_p=Uval_cm;
%     Vval_p=Vval_cm;
%     Uhist_p=Uhist_cm;
%     Vhist_p=Vhist_cm;
%     xlab='velocity (cm/s)';
% else
%     Uval_p=Uval;
%     Vval_p=Vval;
%     Uhist_p=Uhist;
%     Vhist_p=Vhist;
%     xlab='velocity (pixels)';
% end
% if (get(handles.vector_y,'Value') == 1)
%    hhh=figure(2);
%    hold on
%    title([filebase ', ' strindex ', ' fieldtitle])
%    plot(Uval_p,Uhist_p,'b-')
%    n=n+1;
%    leg{n}='Uhist';
%    xlabel(xlab)
% end
% if (get(handles.Vhist_input,'Value') == 1)
%    hhh=figure(2);
%    hold on
%    title([filebase ', ' strindex ', ' fieldtitle])
%    plot(Vval_p,Vhist_p,'r-')
%    n=n+1;
%    leg{n}='Vhist';
%    xlabel(xlab);
% end
% if (get(handles.Chist_input,'Value') == 1)
%    hhhh=figure(3);
%    hold on
%    title([filebase ', ' strindex ', ' fieldtitle])
%    plot(Cval,Chist,'k-')
%    leg{1}='Chist';
% end
% % hold off
% grid on
% legend(leg);

% %-------------------------------------------------------------
% % --- Executes on button press in Save_input.
% function Save_input_Callback(hObject, eventdata, handles)
% list_str=get(handles.abscissa,'String');
% val=get(handles.abscissa,'Value');
% var=list_str{val};
% hselect_field=get(handles.Save_input,'parent')
% set(hselect_field,'UserData',var);
% set(hselect_field,'Tag','idle')

%     
% %-------------------------------------------------------------
% % --- Executes on button press in save_histo.
% function save_histo_Callback(hObject, eventdata, handles)
% global filebase
% 
% pathstr = fileparts(filebase)
% if (get(handles.Chist_input,'Value') == 1)
%     def = {[pathstr pathstr(1) 'PIV_corr_histo.fig']};
%     else

%     def = {[pathstr pathstr(1) 'vel_histo.fig']};
% end
% prompt={'save figure(2) as'}
% dlg_title = 'save figure';
% num_lines= 1;
% answer = inputdlg(prompt,dlg_title,num_lines,def)
% saveas(2,answer{1})
 

%%-------------------------------------------------------
% --- Executes on button press in peaklocking.
%-------------------------------------------------
function peaklocking(handles)
%evaluation of peacklocking errors
%use splinhist: give spline coeff cc for a smooth histo (call spline4)
%use histsmooth(x,cc): calculate the smooth histo for any value x
%use histder(x,cc): calculate the derivative of the smooth histo
global hfig1 hfig2 hfig3
global nbb Uval Vval Uhist Vhist % nbb resolution of the histogram nbb=10: 10 values in unity interval
global xval xerror yval yerror

set(handles.vector_y,'Value',1)% trigger the option Uhist on the interface
set(handles.Vhist_input,'Value',1)
set(handles.cm_switch,'Value',0) % put the switch to 'pixel'

%adjust the extremal values of the histogram in U with respect to integer
%values
minimU=round(min(Uval)-0.5)+0.5; %first value of the histogram with integer bins 
maximU=round(max(Uval)-0.5)+0.5;
minim_fin=(minimU-0.5+1/(2*nbb)); % first bin valueat the beginning of an integer interval
maxim_fin=(maximU+0.5-1/(2*nbb)); % last integer value
nb_bin_min= round(-(minim_fin - min(Uval))*nbb); % nbre of bins added below
nb_bin_max=round((maxim_fin -max(Uval))*nbb); %nbre of bins added above
Uval=[minim_fin:(1/nbb):maxim_fin];
histu_min=zeros(nb_bin_min,1);
histu_max=zeros(nb_bin_max,1);
Uhist=[histu_min; Uhist ;histu_max]; % column vector

%adjust the extremal values of the histogram in V
minimV=round(min(Vval-0.5)+0.5);
maximV=round(max(Vval-0.5)+0.5);
minim_fin=minimV-0.5+1/(2*nbb); % first bin valueat the beginning of an integer interval
maxim_fin=maximV+0.5-1/(2*nbb); % last integer value
nb_bin_min=round((min(Vval) - minim_fin)*nbb); % nbre of bins added below
nb_bin_max=round((maxim_fin -max(Vval))*nbb);
Vval=[minim_fin:(1/nbb):maxim_fin];
histu_min=zeros(nb_bin_min,1);
histu_max=zeros(nb_bin_max,1);
Vhist=[histu_min; Vhist ;histu_max]; % column vector

% RUN_histo_Callback(hObject, eventdata, handles)
% %adjust the histogram to integer values:

%histoU and V
[Uhistinter,xval,xerror]=peaklock(nbb,minimU,maximU,Uhist);
[Vhistinter,yval,yerror]=peaklock(nbb,minimV,maximV,Vhist);

% selection of value ranges such that histo>=10 (enough statistics)
Uval_ind=find(Uhist>=10);
ind_min=min(Uval_ind);
ind_max=max(Uval_ind);
U_min=Uval(ind_min);% minimum allowed value 
U_max=Uval(ind_max);%maximum allowed value

% selection of value ranges such that histo>=10 (enough statistics)
Vval_ind=find(Vhist>=10);
ind_min=min(Vval_ind);
ind_max=max(Vval_ind);
V_min=Vval(ind_min);% minimum allowed value 
V_max=Vval(ind_max);%maximum allowed value

figure(4)% plot U histogram with smoothed one
plot(Uval,Uhist,'b')
grid on
hold on
plot(Uval,Uhistinter,'r');
hold off

figure(5)% plot V histogram with smoothed one
plot(Vval,Vhist,'b')
grid on
hold on
plot(Vval,Vhistinter,'r');
hold off

figure(6)% plot pixel error in two subplots
hfig4=subplot(2,1,1);
hfig5=subplot(2,1,2);
axes(hfig4)
plot(xval,xerror)
axis([U_min U_max -0.4 0.4])
xlabel('velocity u (pix)')
ylabel('peaklocking error (pix)')
grid on
axes(hfig5)
plot(yval,yerror)
axis([V_min V_max -0.4 0.4]);
xlabel('velocity v (pix)')
ylabel('peaklocking error (pix)')
grid on


% ------------------------------------------------------------------
function variables_Callback(hObject, eventdata, handles)
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
% --- Executes on button press in check_1Dplot.
function check_1Dplot_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
val=get(handles.check_1Dplot,'Value');
if isequal(val,0)
    set(handles.Panel1Dplot,'Visible','off')
else
    set(handles.Panel1Dplot,'Visible','on')
end

%------------------------------------------------------------------------
% --- Executes on button press in check_scalar.
function check_scalar_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
val=get(handles.check_scalar,'Value');
if isequal(val,0)
    set(handles.PanelScalar,'Visible','off')
else
    set(handles.PanelScalar,'Visible','on')
end

%------------------------------------------------------------------------
% --- Executes on button press in check_vector.
function check_vector_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
val=get(handles.check_vector,'Value');
if isequal(val,0)
    set(handles.PanelVectors,'Visible','off')
else
    set(handles.PanelVectors,'Visible','on')
end

% %------------------------------------------------------------------------
% function mouse_up_gui(ggg,eventdata,handles)
% %------------------------------------------------------------------------
% if isequal(get(ggg,'SelectionType'),'alt') 
%     message='';  
%     global CurData
%     inputfield=get(handles.inputfile,'String');
%     if exist(inputfield,'file')
%         CurData=nc2struct(inputfield);
%     else
%         CurData=get(ggg,'UserData');% get_field opened from a input field, not a file
%     end
%   %%%% TODO: put the matalb command window in front
%     evalin('base','global CurData')%make CurData global in the workspace
%     evalin('base','CurData') %display CurData in the workspace
% end

%------------------------------------------------------------------------
% --- Executes on selection change in ACTION.
%------------------------------------------------------------------------
function ACTION_Callback(hObject, eventdata, handles)
global nb_builtin
list_ACTION=get(handles.ACTION,'String');% list menu fields
index_ACTION=get(handles.ACTION,'Value');% selected string index
ACTION= list_ACTION{index_ACTION}; % selected string
list_func_handles=get(handles.ACTION,'UserData');% get list of function handles (full address of the function, including name and path)
ff=functions(list_func_handles{end});
% add a new function to the menu
if isequal(ACTION,'more...')
    [FileName, PathName] = uigetfile( ...
       {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',ff.file);
    if length(FileName)<2
        return
    end
    [pp,ACTION,ext_fct]=fileparts(FileName);
    if ~isequal(ext_fct,'.m')
        msgbox_uvmat('ERROR','a Matlab function .m must be introduced');
        return
    end

    % insert the choice in the action menu
   menu_str=update_menu(handles.ACTION,ACTION);%new action menu in which the new item has been appended if needed
   index_ACTION=get(handles.ACTION,'Value');% currently selected index in the list
   addpath(PathName)
   list_func_handles{index_ACTION}=str2func(ACTION);% create the function handle corresponding to the newly seleced function
   set(handles.ACTION,'UserData',list_func_handles)
   set(handles.path_action,'enable','inactive')% indicate that the current path is accessible (not 'off')
   %list_path{index_ACTION}=PathName;
   if length(menu_str)>nb_builtin+5;
       nbremove=length(menu_str)-nb_builtin-5;
       menu_str(nb_builtin+1:end-5)=[];
       list_func_handles(nb_builtin+1:end-4)=[];
       index_ACTION=index_ACTION-nbremove;
       set(handles.ACTION,'Value',index_ACTION)
       set(handles.ACTION,'String',menu_str)
   end   
   %record the current menu in personal file profil_perso
   dir_perso=prefdir;
   profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
   get_field_fct={};
   for ilist=nb_builtin+1:length(menu_str)-1
       ff=functions(list_func_handles{ilist});
       get_field_fct{ilist-nb_builtin}=ff.file;
   end
   if exist(profil_perso,'file')
        save(profil_perso,'get_field_fct','-append')
   else
     txt=ver('MATLAB');
    Release=txt.Release;
       relnumb=str2num(Release(3:4));
        if relnumb >= 14
            save(profil_perso,'get_field_fct','-V6')
        else
            save(profil_perso, 'get_field_fct')
        end
   end
end

%check the current path to the selected function
h_fun=list_func_handles{index_ACTION};
if isa(h_fun,'function_handle')
    func=functions(h_fun);
    set(handles.path_action,'String',fileparts(func.file)); %show the path to the senlected function
    GUI_input=h_fun();%handles.figure1 =handles of the GUI get_field
else
    set(handles.path_action,'String','')
    msgbox_uvmat('ERROR','unknown path to ACTION function, reload it')
    return
end

%prepare the GUI options for the selected ACTION
test_1Dplot=0;
test_scalar=0;
test_vector=0;
if iscell(GUI_input)
    for ilist=1:length(GUI_input)
        switch GUI_input{ilist}
                           %RootFile always visible
            case 'check_1Dplot'   
                 test_1Dplot=1;
            case 'check_scalar'
                 test_scalar=1;   
            case 'check_vector'   
                 test_vector=1; 
        end
    end
end
set(handles.check_1Dplot,'Value',test_1Dplot);
set(handles.check_scalar,'Value',test_scalar); 
set(handles.check_vector,'Value',test_vector);
check_1Dplot_Callback(hObject, eventdata, handles)
check_scalar_Callback(hObject, eventdata, handles)
check_vector_Callback(hObject, eventdata, handles)


%-----------------------------------------------------
% --- browse existing figures
%-----------------------------------------------------
function browse_fig(menu_handle)
hh=findobj(allchild(0),'Type','figure');
ilist=0;
list={};
for ifig=1:length(hh)  %look for all existing figures
    name=get(hh(ifig),'Name');
     if ~strcmp(name,'uvmat')&& ~strcmp(name,'view_field') %case of uvmat GUI
        hchild=get(hh(ifig),'children');% look for axes contained in each figure
        nbaxe=0;
        for ichild=1:length(hchild)           
            Type=get(hchild(ichild),'Type');
            Tag=get(hchild(ichild),'Tag');
            if isequal(Type,'axes')
                if ~isequal(Tag,'Colorbar')& ~isequal(Tag,'legend')% don't select colorbars for plotting
                     nbaxe=nbaxe+1;%count the existing axis
                end 
            end
        end    
        if nbaxe==1
             ilist=ilist+1;%add a line in the list of axis
            list{ilist,1}=num2str(hh(ifig));
        elseif nbaxe>1
            for iaxe=1:nbaxe
               ilist=ilist+1;%add a line in the list of axis
               list{ilist,1}=[num2str(hh(ifig)) '_' num2str(iaxe)];
            end
        end
     end
end
list=['uvmat';list];
set(menu_handle,'Value',1)
set(menu_handle,'String',list)


%-----------------------------------------------------
function list_fig_Callback(hObject, eventdata, handles)
%-----------------------------------------------------
list_fig=get(handles.list_fig,'String');
fig_val=get(handles.list_fig,'Value');
plot_fig=list_fig{fig_val};
if strcmp(plot_fig,'view_field')
%     huvmat=findobj(allchild(0),'name','uvmat');
%     if ~isempty(huvmat)
%         uistack(huvmat,'top')
%     end    
else%if ~isequal(plot_fig,'new fig...') & ~isequal(plot_fig,'uvmat')
    sep=regexp(plot_fig,'_');
    if ~isempty(sep)
        plot_fig=plot_fig([1:sep-1]);
    end
    if ishandle(str2num(plot_fig))
        figure(str2num(plot_fig))% display existing figure
    else
        browse_fig(handles.list_fig); %reset the current list of figures
    end
end


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

% --------------------------------------------------------------------
function MenuOpen_Callback(hObject, eventdata, handles)
% hObject    handle to MenuOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MenuExport_Callback(hObject, eventdata, handles)
% hObject    handle to MenuExport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MenuBrowse_Callback(hObject, eventdata, handles)

oldfile=get(handles.inputfile,'String');
testrootfile=0;
testsubdir=0;
if isempty(oldfile)|isequal(oldfile,'') %loads the previously stored file name and set it as default in the file_input box
        oldfile=''; 
        dir_perso=prefdir;
         profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
         if exist(profil_perso,'file')
              h=load (profil_perso);
             if isfield(h,'RootPath')
                  RootPath=h.RootPath;
             end
             if isfield(h,'SubDir')
                  SubDir=h.SubDir;
                  if ~isempty(SubDir)
                    testsubdir=1;
                  end
             end
             if isfield(h,'RootFile')
                  RootFile=h.RootFile;
                  if ~isempty(RootFile)
                    testrootfile=1;
                  end
             end
         end
end
if testrootfile
    if ~testsubdir
        oldfile=fullfile(RootPath,RootFile);
    else
        oldfile=fullfile(RootPath,SubDir,RootFile);
    end
end
[FileName, PathName] = uigetfile( ...
       {'*.nc', ' *.nc';...
       '*.cdf', ' *.cdf';...
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file',oldfile);

%global inputfile
fileinput=[PathName FileName];%complete file name 
sizf=size(fileinput);
if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end
set(handles.inputfile,'String',fileinput)
inputfile_Callback(hObject, eventdata, handles)

%update list of recent files in the menubar
MenuFile_1=fileinput;
MenuFile_2=get(handles.MenuFile_1,'Label');
MenuFile_3=get(handles.MenuFile_2,'Label');
MenuFile_4=get(handles.MenuFile_3,'Label');
MenuFile_5=get(handles.MenuFile_4,'Label');
set(handles.MenuFile_1,'Label',MenuFile_1)
set(handles.MenuFile_2,'Label',MenuFile_2)
set(handles.MenuFile_3,'Label',MenuFile_3)
set(handles.MenuFile_4,'Label',MenuFile_4)
set(handles.MenuFile_5,'Label',MenuFile_5)
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
display(profil_perso)
if exist(profil_perso,'file')
    save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-append'); %store the file names for future opening of uvmat
else
    txt=ver('MATLAB');
    Release=txt.Release;
    relnumb=str2double(Release(3:4));
    if relnumb >= 14
        save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-V6'); %store the file names for future opening of uvmat
    else
        save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5'); %store the file names for future opening of uvmat
    end
end

% --------------------------------------------------------------------
function MenuFile_1_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_1,'Label');
set(handles.inputfile,'String',fileinput)
inputfile_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function MenuFile_2_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_2,'Label');
set(handles.inputfile,'String',fileinput)
inputfile_Callback(hObject, eventdata, handles)

% -----------------------------------------------------------------------
function MenuFile_3_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
fileinput=get(handles.MenuFile_3,'Label');
set(handles.inputfile,'String',fileinput)
inputfile_Callback(hObject, eventdata, handles)

% -----------------------------------------------------------------------
function MenuFile_4_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
fileinput=get(handles.MenuFile_4,'Label');
set(handles.inputfile,'String',fileinput)
inputfile_Callback(hObject, eventdata, handles)

% -----------------------------------------------------------------------
function MenuFile_5_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
fileinput=get(handles.MenuFile_5,'Label');
set(handles.inputfile,'String',fileinput)
inputfile_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function MenuExportField_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
global Data_get_field
% huvmat=findobj(allchild(0),'Name','uvmat');
inputfile=get(handles.inputfile,'String');
Data_get_field=nc2struct(inputfile);
% Data_view_field=UvData.ProjField_2;
evalin('base','global Data_get_field')%make CurData global in the workspace
display(['content of ' inputfile ':'])
evalin('base','Data_get_field') %display CurData in the workspace
commandwindow;

%------------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
web([helpfile '#get_field'])    
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

%------------------------------------------------------------------------
% --- Executes on selection change in TimeDimensionMenu.
function TimeDimensionMenu_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
index=get(handles.TimeDimensionMenu,'Value');
DimList=get(handles.TimeDimensionMenu,'String');
DimName=DimList{index};
Field=get(handles.get_field,'UserData');
DimIndex=find(strcmp(DimName,Field.ListDimName),1);
ref_index=round(Field.DimValue(DimIndex)/2);   
set(handles.TimeIndexValue,'String',num2str(ref_index))
scalar_Callback(hObject, eventdata, handles)
vector_x_Callback(hObject, eventdata, handles)% update menus of coordinates (remove time)
 % look for a corresponding time variable and value
 time_test=zeros(size(Field.VarDimName));
 for ilist=1:numel(Field.VarDimName)
     if isequal(Field.VarDimName{ilist},{DimName})
         time_test(ilist)=1;
     end
 end
 ListVariable=Field.ListVarName(time_test==1);
 set(handles.TimeVariableMenu,'Value',1)
 if isempty(ListVariable)     
     set(handles.TimeVariableMenu,'String',{''})
     set(handles.TimeVarValue,'String','')
 else
    set(handles.TimeVariableMenu,'String',ListVariable)
    TimeVarName=ListVariable{1};
    VarIndex=find(strcmp(TimeVarName,Field.ListVarName),1);%index in the list of variables
    inputfile=get(handles.inputfile,'String');% read the input file
    SubField=nc2struct(inputfile,{TimeVarName});
    eval(['TimeValue=SubField.' TimeVarName '(ref_index);'])
    set(handles.TimeVarValue,'Visible','on')
    set(handles.TimeVariableMenu,'Visible','on')
    set(handles.TimeVarValue,'String',num2str(TimeValue))
 end


% % -----------------------------------------------------------------------
% % --- Executes on button press in TimeVariable.
% function TimeVariable_Callback(hObject, eventdata, handles)
% % -----------------------------------------------------------------------
% val=get(handles.TimeVariable,'Value');
% if val
%     Field=get(handles.get_field,'UserData');
%     time_test=zeros(size(Field.VarDimName));
%     for ilist=1:numel(Field.VarDimName)
%         if isequal(numel(Field.VarDimName{ilist}),1)%select variables with a single dimension
%             time_test(ilist)=1;
%         end
%     end
%     ind_test=find(time_test);
%     if isempty(time_test)
%         set(handles.TimeVariable,'Value',0)
%         set(handles.TimeVariableMenu,'Visible','off')
%         set(handles.TimeVarValue,'Visible','off')
%     else
%         set(handles.TimeVariableMenu,'Visible','on')
%         set(handles.TimeVarValue,'Visible','on')
%         if get(handles.TimeVariableMenu,'Value')>numel(ind_test)
%             set(handles.TimeVariableMenu,'Value',1)
%         end
%         set(handles.TimeVariableMenu,'String',Field.ListVarName(ind_test))
%         TimeVariableMenu_Callback(hObject, eventdata, handles)
%         set(handles.TimeDimension,'Value',0) %deseselect alternative option sfor time
%         set(handles.TimeAttribute,'Value',0)
%         TimeAttribute_Callback(hObject, eventdata, handles)
%     end
% else
%     set(handles.TimeVariableMenu,'Visible','off')
%     set(handles.TimeVarValue,'Visible','off')
% end

% -----------------------------------------------------------------------
% --- Executes on selection change in TimeVariableMenu.
function TimeVariableMenu_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
ListVar=get(handles.TimeVariableMenu,'String');
index=get(handles.TimeVariableMenu,'Value');
TimeVariable=ListVar{index};% name of the selected variable
if isempty(TimeVariable)% case of blank selection
    return
end
Field=get(handles.get_field,'UserData'); %index of 
VarIndex=find(strcmp(TimeVariable,Field.ListVarName),1);%index in the list of variables
DimName=Field.VarDimName{VarIndex}; % dimension corresponding to the variable
set(handles.TimeDimensionMenu,'Value',1)
set(handles.TimeDimensionMenu,'String',DimName)
inputfile=get(handles.inputfile,'String');% read the input file
SubField=nc2struct(inputfile,{TimeVariable});
eval(['TimeDimension=numel(SubField.' TimeVariable ');'])
ref_index=round(TimeDimension/2);
eval(['TimeValue=SubField.' TimeVariable '(ref_index);'])
set(handles.TimeIndexValue,'String',num2str(ref_index))
set(handles.TimeVarValue,'String',num2str(TimeValue))


function TimeValue_Callback(hObject, eventdata, handles)
%TO suppress 

% -----------------------------------------------------------------------
function TimeIndexValue_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
TimeIndex=str2double(get(handles.TimeIndexValue,'String'));
TimeVarName=Field.ListVarName{time_index};
set(handles.TimeVariable,'Value',1)
set(handles.TimeName,'String',TimeVarName)
fileinput=get(handles.inputfile,'String');
SubField=nc2struct(fileinput,{TimeVarName});
eval(['TimeValue=SubField.' TimeVarName '(ref_index);']);
set(handles.TimeValue,'Visible','on')
set(handles.TimeValue,'String',num2str(TimeValue))

% -----------------------------------------------------------------------
function SelectFigure_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
val=get(handles.SelectFigure,'Value');
if val
    set(handles.list_fig,'Visible','on')
    %% look at the existing figures in the work space
    browse_fig(handles.list_fig)
else
   set(handles.list_fig,'Visible','off') 
end


function TimeVarValue_Callback(hObject, eventdata, handles)



% --- Executes on button press in check_rgb.
function check_rgb_Callback(hObject, eventdata, handles)
