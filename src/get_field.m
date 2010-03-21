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

% Last Modified by GUIDE v2.5 06-Feb-2010 09:58:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @get_field_OpeningFcn, ...
                   'gui_OutputFcn',  @get_field_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
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
function get_field_OpeningFcn(hObject, eventdata, handles,filename,Field,haxes)
%------------------------------------------------------------------------
global nb_builtin
browse_fig(handles.list_fig)

% Choose default command line output for get_field
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
%pathuvmat=fileparts(which('uvmat'));
%addpath(fullfile(pathuvmat,'FIELD_FCT'))
%loads the information stored in prefdir to initiate the browser and the list of functions
menu_str={'PLOT';'FFT';'filter_band';'histogram'}; %list of functions included in 'get_field.m'
nb_builtin=numel(menu_str)-1;
%menu_str(end)=[];%remove from the list the last option 'more...'
path_get_field=fileparts(which('get_field'));%path of the function 'get_field'
for ilist=1:length(menu_str)
    fct_path{ilist,1}=fullfile(path_get_field,'get_field');%paths of the fuctions buil-in in 'get_field.m'
end
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
if exist(profil_perso,'file')
    % menu={'RUN';'raw2phys';'histogram';'FFT';'peaklocking'};
      h=load (profil_perso);
     if isfield(h,'get_field_fct') && iscell(h.get_field_fct)
         for ilist=1:length(h.get_field_fct)
            [path,file]=fileparts(h.get_field_fct{ilist});
            fct_path=[fct_path; {path}];%concatene the list of paths
            menu_str=[menu_str; {file}];
         end
     end
end
menu_str=[menu_str;{'more...'}];
set(handles.ACTION,'String',menu_str)
set(handles.ACTION,'UserData',fct_path)% store the list of path in UserData of ACTION  
ACTION_Callback(hObject, eventdata, handles) 
set(hObject,'WindowButtonUpFcn',{@mouse_up_gui,handles})%set mouse click action function
if exist('filename','var')& ischar(filename)
    set(handles.inputfile,'String',filename)
    inputfile_Callback(hObject, eventdata, handles)
else
    set(handles.inputfile,'String','')   
end
if exist('Field','var') & isstruct(Field)
        Field_input(eventdata,handles,Field)
        if exist('haxes','var')
            Field.PlotAxes=haxes;
        end
    set(hObject,'UserData',Field);
end

%load the list of previously browsed files in menus Open 
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

%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = get_field_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
varargout{1} = handles.output;

%------------------------------------------------------------------------
% --- Executes on button press in browse.
function browse_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function inputfile_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
inputfile=get(handles.inputfile,'String');
Field=nc2struct(inputfile);% reads the whole field
hfig=get(handles.inputfile,'parent');
set(hfig,'UserData',Field);
Field_input(eventdata,handles,Field);

%------------------------------------------------------------------------
function Field_input(eventdata,handles,Field)
%------------------------------------------------------------------------
if isfield(Field,'ListDimName')&&~isempty(Field.ListDimName)
    Tabcell(:,1)=Field.ListDimName;
    for iline=1:length(Field.ListDimName)
        Tabcell{iline,2}=num2str(Field.DimValue(iline));
    end
    Tabchar=cell2tab(Tabcell,'=');
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
        set(handles.vector_x,'Value',VarType{imax}.vector_x)
        set(handles.vector_y,'Value',VarType{imax}.vector_y)
        set(handles.check_scalar,'Value',0)
    else
        set(handles.check_scalar,'Value',1)
        set(handles.check_vector,'Value',0)
        if isfield(VarType{imax},'scalar') && length(VarType{imax}.scalar)>=1
            set(handles.scalar,'Value',VarType{imax}.scalar(1))
        end
    end
    check_1Dplot_Callback(handles.check_1Dplot, eventdata, handles)
    check_scalar_Callback(handles.check_scalar, eventdata, handles)
    check_vector_Callback(handles.check_vector, eventdata, handles)
end

%------------------------------------------------------------------------
function ordinate_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%update_field(hObject, eventdata, handles)
% A REVOIR
hselect_field=get(handles.inputfile,'parent');
Field=get(hselect_field,'UserData');
% xindex=get(handles.abscissa,'Value');
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
% Field.VarIndex.y=yindex;
% set(hselect_field,'UserData',Field);
%update_UserData(handles)

%------------------------------------------------------------------------
% --- Executes on selection change in abscissa.
function abscissa_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
 hselect_field=get(handles.inputfile,'parent');
 Field=get(hselect_field,'UserData');%current input field
 xdispindex=get(handles.abscissa,'Value');%index in the list of abscissa
% test_2D=get(handles.check_vector,'Value');% =1 for vector fields
% test_scalar=get(handles.check_scalar,'Value');% =1 for scalar fields
%if isequal(xdispindex,1)% blank selection, no selected variable for abscissa
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
%     variables_Callback(hObject, eventdata, handles)  %display properties of the variable (dim, attributes)
%     if  ~test_2D &  ~test_scalar% look for possible varaibles to RUN in ordinate    
%         index=Field.VarDimIndex{xindex};%dimension indices of the variable selected for abscissa
%         VarIndex=[];
%         for ilist=1:length(Field.VarDimIndex)%detect 
%             index_i=Field.VarDimIndex{ilist};
%             if ~isempty(index_i)
%                 if isequal(index_i(1),index(1))%if the first dimension of the variable coincide with the selected one, RUN is possible
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

%-------------------------------------------------------
% --- Executes on selection change in scalar menu.
function scalar_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
Aindex=get(handles.scalar,'Value');
Astring=get(handles.scalar,'String');
VarName=Astring{Aindex};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in coord_x_scalar.
function coord_x_scalar_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
index=get(handles.coord_x_scalar,'Value');
string=get(handles.coord_x_scalar,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in coord_y_scalar.
function coord_y_scalar_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
index=get(handles.coord_y_scalar,'Value');
string=get(handles.coord_y_scalar,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in coord_z_scalar.
function coord_z_scalar_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
index=get(handles.coord_z_scalar,'Value');
string=get(handles.coord_z_scalar,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in vector_x.
function vector_x_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
index=get(handles.vector_x,'Value');
string=get(handles.vector_x,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in vector_y.
function vector_y_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
index=get(handles.vector_y,'Value');
string=get(handles.vector_y,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in vector_z.
function vector_z_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
index=get(handles.vector_z,'Value');
string=get(handles.vector_z,'String');
VarName=Astring{index};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in coord_x_vectors.
function coord_x_vectors_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
index=get(handles.coord_x_vectors,'Value');
string=get(handles.coord_x_vectors,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in coord_y_vectors.
%-------------------------------------------------------
function coord_y_vectors_Callback(hObject, eventdata, handles)
index=get(handles.coord_y_vectors,'Value');
string=get(handles.coord_y_vectors,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in coord_z_scalar.
function coord_z_vectors_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
index=get(handles.coord_z_vectors,'Value');
string=get(handles.coord_z_vectors,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%-------------------------------------------------------
% --- Executes on selection change in vec_color.
function vec_color_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
index=get(handles.vec_color,'Value');
string=get(handles.vec_color,'String');
VarName=string{index};
update_field(hObject, eventdata, handles,VarName)

%---------------------------------
function update_field(hObject, eventdata, handles,VarName)
% VarName= input variable name for scalar or vector plots
hselect_field=get(handles.inputfile,'parent');
Field=get(hselect_field,'UserData');
index=name2index(VarName,Field.ListVarName);
if ~isempty(index)
    set(handles.variables,'Value',index+1)
    variables_Callback(hObject, eventdata, handles)
end
% 
% 
% hselect_field=get(handles.inputfile,'parent');
% Field=get(hselect_field,'UserData');
% ivar_sel=[];%default
% for ivar=1:length(Field.ListVarName)%detect 
%     if isequal(Field.ListVarName{ivar},VarName)
%         ivar_sel=ivar; %ivar_sel = index of the input variable in the list ListVarName
%         break
%     end
% end
% if isempty(ivar_sel)
%     return
% end
% set(handles.variables,'Value',ivar_sel+1)%select the corresponding item in the displayed  list 'variables'
% variables_Callback(hObject, eventdata, handles)%show the dimensions and attributes of the input variable
% 
% index=Field.VarDimIndex{ivar_sel};%dimension indices of the input variable
% DimValue=Field.DimValue(index);%dimension values of the input variable
% ind_1=find(DimValue==1);
% index(ind_1)=[];%Mremove singletons
% 
% 
% % detect possible variables for abscissa and ordinate
% VarIndex=[];%initiate list of selected variable indices
% ind_coordvar=[]; %initiate list of coordinate variables
% for ilist=1:length(Field.VarDimIndex)
%     if ~isequal(ilist,ivar_sel)        
%         index_i=Field.VarDimIndex{ilist};%indices of dimensions associated with variable #ilist
%         if length(index_i)>1
%             DimValue=Field.DimValue(index_i);
%             ind_1=find(DimValue==1);
%             index_i(ind_1)=[];%Mremove singletons
%             if isequal(index,index_i)
%                 VarIndex=[VarIndex ilist]; %selected variable withb the same dimensions of the input variable
%             end
%         else
%             idim=find(index==index_i(1));
%             if ~isempty(idim)
%                  VarIndex=[VarIndex ilist]; %possible dimension variable
%                  if isequal(Field.ListDimName{index_i(1)},Field.ListVarName{ilist})
%                      ind_coordvar=[ind_coordvar length(VarIndex)];
%                  end
%             end
%         end
%     end
% end
% % val=get(handles.abscissa,'Value');
% % if val>length(Field.ListVarName(VarIndex))+1
% %     set(handles.abscissa,'Value',length(Field.ListVarName(VarIndex))+1)
% % end
% % val=get(handles.ordinate,'Value');
% % if val>length(Field.ListVarName(VarIndex))+1
% %     set(handles.abscissa,'Value',length(Field.ListVarName(VarIndex))+1)
% % end
% % val=get(handles.coord_z_vectors_scalar,'Value');
% % if val>length(Field.ListVarName(VarIndex))+1
% %     set(handles.abscissa,'Value',length(Field.ListVarName(VarIndex))+1)
% % end
% set(handles.abscissa,'Value',1)%default
% set(handles.ordinate,'Value',1)%default
% set(handles.coord_z_scalar,'Value',1)%default
% set(handles.abscissa,'String',[{''} Field.ListVarName(VarIndex) ])
% set(handles.ordinate,'String',[{''} Field.ListVarName(VarIndex) ])
% set(handles.coord_z_scalar,'String',[{''} Field.ListVarName(VarIndex) ])
% if length(ind_coordvar)>=1
%     set(handles.abscissa,'Value',ind_coordvar(1)+1)
% elseif length(index)==1 && length(VarIndex)>=1
%     set(handles.abscissa,'Value',2)
% end
% if length(ind_coordvar)>=2
%     set(handles.ordinate,'Value',ind_coordvar(2)+1)
% elseif length(index)==1 && length(VarIndex)>=2
%     set(handles.ordinate,'Value',3)
% end
% if length(ind_coordvar)>=3
%     set(handles.coord_z_scalar,'Value',ind_coordvar(3)+1)
% elseif length(index)==1 && length(VarIndex)>=3
%     set(handles.coord_z_scalar,'Value',4)
% end

%---------------------------------------------------------
% update the UserData Field for use of the selected variables outsde get_field (taken from RUN_Callback)
function update_UserData(handles)
%---------------------------------------------------------
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
    %TODO possibility of selecting 3 times the same variable for u, v, w components
end


% select the variable  index (or indices) for z coordinates
test_grid=0;
if test_scalar | test_vector
    nbdim=length(DimIndex);
    if nbdim > 3
        msgbox_uvmat('ERROR','array with more than three dimensions, not supported')
        return
    else
        perm_ind=[1:nbdim];
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
%             DimIndex_z=Field.VarDimIndex{VarIndex_z};%dimension indices of the variable    
%             if length(DimIndex_z)==1 & nbdim==3 %dimension variable
%                 VarAttribute{VarIndex_z}.Role=Field.ListDimName{DimIndex_z};
%                 ind_z=find(DimIndex==DimIndex_z(1));
%                 perm_ind(ind_z)=1;
%                 test_grid=1;
%             end
%         end
    end
end

% select the variable  index (or indices) for ordinate
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

%select the variable index for the abscissa
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
path_get_field=fileparts(which('get_field'));
list=get(handles.ACTION,'String');
index=get(handles.ACTION,'Value');
ACTION=list{index};
list_path=get(handles.ACTION,'UserData');
%hselect_field=get(handles.inputfile,'parent');%handle of the get_field interface
fct_path=list_path{index}; %path stored for the function ACTION
if ~isequal(fct_path,path_get_field)
%     eval(['spath=which(''' action ''');']) %spath = current path of the selected function ACTION
%     if ~isequal(spath,fct_path)& exist(fct_path,'dir')
        addpath(fct_path)% add the prescribed path if not the current one
%     end
end
% fct_path
eval(['h_fun=@' ACTION ';'])
if ~isequal(fct_path,path_get_field)
        rmpath(fct_path)% add the prescribed path if not the current one    
end

set(handles.RUN,'BackgroundColor',[0.831 0.816 0.784])
drawnow
h_fun(handles.figure1);%handles.figure1 =handles of the GUI get_field
browse_fig(handles.list_fig); %update the list of new existing figures


%------------------------------------------------
% --- Executes on button press in Plot_histo.
%RUN global histograms
%-------------------------------------------------
function RUN_histo_Callback(hObject, eventdata, handles)
% hObject    handle to RUN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%time plots
leg={};
n=0;
if (get(handles.cm_switch,'Value')==1)
    Uval_p=Uval_cm;
    Vval_p=Vval_cm;
    Uhist_p=Uhist_cm;
    Vhist_p=Vhist_cm;
    xlab='velocity (cm/s)';
else
    Uval_p=Uval;
    Vval_p=Vval;
    Uhist_p=Uhist;
    Vhist_p=Vhist;
    xlab='velocity (pixels)';
end
if (get(handles.vector_y,'Value') == 1)
   hhh=figure(2);
   hold on
   title([filebase ', ' strindex ', ' fieldtitle])
   plot(Uval_p,Uhist_p,'b-')
   n=n+1;
   leg{n}='Uhist';
   xlabel(xlab)
end
if (get(handles.Vhist_input,'Value') == 1)
   hhh=figure(2);
   hold on
   title([filebase ', ' strindex ', ' fieldtitle])
   plot(Vval_p,Vhist_p,'r-')
   n=n+1;
   leg{n}='Vhist';
   xlabel(xlab);
end
if (get(handles.Chist_input,'Value') == 1)
   hhhh=figure(3);
   hold on
   title([filebase ', ' strindex ', ' fieldtitle])
   plot(Cval,Chist,'k-')
   leg{1}='Chist';
end
% hold off
grid on
legend(leg);

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
Field=get(hselect_field,'UserData');
index=get(handles.variables,'Value');%index in the list 'variables'
if isequal(index,1) 
    set(handles.attributes_txt,'String','global attributes')
% list global attribute names and values if index=1 (blank variable display) is selected
    if isfield(Field,'ListGlobalAttribute') && ~isempty(Field.ListGlobalAttribute)
        for iline=1:length(Field.ListGlobalAttribute)
            Tabcell{iline,1}=Field.ListGlobalAttribute{iline};   
            if isfield(Field, Field.ListGlobalAttribute{iline})
                eval(['val=Field.' Field.ListGlobalAttribute{iline} ';'])
                if ischar(val);
                    Tabcell{iline,2}=val;
                else
                    Tabcell{iline,2}=num2str(val);
                end
            end
        end
        Tabchar=cell2tab(Tabcell,'=');
    end
else
%list attribute names and values associated to the variable # injdex-1   
    list_var=get(handles.variables,'String');
    var_select=list_var{index};
    set(handles.attributes_txt,'String', ['attributes of ' var_select])
    if isfield(Field,'VarAttribute')& length(Field.VarAttribute)>=index-1
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
set(handles.attributes,'String',Tabchar);

% list_var=get(handles.dimensions,'String');
% val=get(handles.dimensions,'Value');

% update dimensions;
if isfield(Field,'VarDimIndex')
    Tabdim={};%default
    if isequal(index,1)
        dim_indices=1:length(Field.ListDimName);
        set(handles.dimensions_txt,'String', 'dimensions')
    else
        dim_indices=Field.VarDimIndex{index-1};
        set(handles.dimensions_txt,'String', ['dimensions of ' var_select])
    end
    for iline=1:length(dim_indices)
        Tabdim{iline,1}=Field.ListDimName{dim_indices(iline)};
        Tabdim{iline,2}=num2str(Field.DimValue(dim_indices(iline)));
    end
    Tabchar=cell2tab(Tabdim,'=');
    Tabchar=[{''} ;Tabchar];
    set(handles.dimensions,'String',Tabchar)  
end  

% --- Executes on button press in check_1Dplot.
function check_1Dplot_Callback(hObject, eventdata, handles)
val=get(handles.check_1Dplot,'Value');
if isequal(val,0)
    set(handles.Panel1Dplot,'Visible','off')
%      set(handles.scalar,'Visible','off')
%     set(handles.ordinate,'Max',2.0)%allow multiple ordinate input option
%     if isequal(get(handles.check_vector,'Value'),0);
%         set(handles.coord_z_vectors_scalar,'Visible','off')
%     end
else
    set(handles.Panel1Dplot,'Visible','on')
%     set(handles.scalar,'Visible','on')
%     val=get(handles.ordinate,'Value');
%     val=val(1);
%     set(handles.ordinate,'Value',val);%suppress multiple ordinates
%     set(handles.ordinate,'Max',1.0);%suppress multiple ordinate input option
%       set(handles.coord_z_vectors_scalar,'Visible','on')
end

% --- Executes on button press in check_scalar.
function check_scalar_Callback(hObject, eventdata, handles)
val=get(handles.check_scalar,'Value');
if isequal(val,0)
    set(handles.PanelScalar,'Visible','off')
%      set(handles.scalar,'Visible','off')
%     set(handles.ordinate,'Max',2.0)%allow multiple ordinate input option
%     if isequal(get(handles.check_vector,'Value'),0);
%         set(handles.coord_z_vectors_scalar,'Visible','off')
%     end
else
    set(handles.PanelScalar,'Visible','on')
%     set(handles.scalar,'Visible','on')
%     val=get(handles.ordinate,'Value');
%     val=val(1);
%     set(handles.ordinate,'Value',val);%suppress multiple ordinates
%     set(handles.ordinate,'Max',1.0);%suppress multiple ordinate input option
%       set(handles.coord_z_vectors_scalar,'Visible','on')
end

%---------------------------
% --- Executes on button press in check_vector.
function check_vector_Callback(hObject, eventdata, handles)
val=get(handles.check_vector,'Value');
if isequal(val,0)
    set(handles.PanelVectors,'Visible','off')
else
    set(handles.PanelVectors,'Visible','on')
end



%-----------------------------
function mouse_up_gui(ggg,eventdata,handles)
if isequal(get(ggg,'SelectionType'),'alt') 
    message='';  
    global CurData
    inputfield=get(handles.inputfile,'String');
    if exist(inputfield,'file')
        CurData=nc2struct(inputfield);
    else
        CurData=get(ggg,'UserData');% get_field opened from a input field, not a file
    end
  %%%% TODO: put the matalb command window in front
    evalin('base','global CurData')%make CurData global in the workspace
    evalin('base','CurData') %display CurData in the workspace
end

%---------------------------------------------
% --- Executes on selection change in ACTION.
function ACTION_Callback(hObject, eventdata, handles)
global nb_builtin
list_ACTION=get(handles.ACTION,'String');% list menu fields
index_ACTION=get(handles.ACTION,'Value');% selected string index
ACTION= list_ACTION{index_ACTION}; % selected string
path_get_field=which('get_field');%path to series.m
list_path=get(handles.ACTION,'UserData');

% nb_builtin=0;
% if iscell(list_path)
%     for ilist=1:length(list_path)
%         if isequal(list_path{ilist},path_get_field)
%             nb_builtin=nb_builtin+1;
%         else
%             break
%         end
%     end
% end
% if nb_builtin==0% the path to get_field has been changed, reinitialize
%     get_field_OpeningFcn(hObject, eventdata, handles)
%     return
% end

% add a new function to the menu
if isequal(ACTION,'more...')
    pathfct=fileparts(path_get_field);
    browse_name=fullfile(path_get_field,'FIELD_FCT');
    if length(list_path)>nb_builtin
        browse_name=list_path{end};% initialize browser with  the path of the last introduced function
    end
    [FileName, PathName] = uigetfile( ...
       {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',browse_name);
    if length(FileName)<2
        return
    end
    [pp,ACTION,ext_fct]=fileparts(FileName);
    if ~isequal(ext_fct,'.m')
        msgbox_uvmat('ERROR','a Matlab function .m must be introduced');
        return
    end
%     ACTION=FileName(1:end-2);% ACTION choice updated by the selected item  
    % insert the choice in the action menu
   menu_str=update_menu(handles.ACTION,ACTION);%new action menu in which the new item has been appended if needed
   index_ACTION=get(handles.ACTION,'Value');% currently selected index in the list
   list_path{index_ACTION}=PathName;
   if length(menu_str)>nb_builtin+5;
       nbremove=length(menu_str)-nb_builtin-5;
       menu_str(nb_builtin+1:end-5)=[];
       list_path(nb_builtin+1:end-4)=[];
       index_ACTION=index_ACTION-nbremove;
       set(handles.ACTION,'Value',index_ACTION)
       set(handles.ACTION,'String',menu_str)
   end
   list_path{index_ACTION}=PathName;
   set(handles.ACTION,'UserData',list_path);
   set(handles.path_action,'enable','inactive')% indicate that the current path is accessible (not 'off')
   
   %record the current menu in personal file profil_perso
   dir_perso=prefdir;
   profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
   for ilist=nb_builtin+1:length(menu_str)-1
       get_field_fct{ilist-nb_builtin}=fullfile(list_path{ilist},[menu_str{ilist} '.m']);
   end
   if exist(profil_perso,'file')
        save(profil_perso,'get_field_fct','-append')
   else
        txt=ver;
        Release=txt(1).Release;
        relnumb=str2num(Release(3:4));
        if relnumb >= 14
            save(profil_perso,'get_field_fct','-V6')
        else
            save(profil_perso, 'get_field_fct')
        end
   end
end

   %check the current path to the selected function
PathName=list_path{index_ACTION};%current recorded path
% if ~isequal(path_get_field,PathName)
%     CurrentPath=fileparts(which(ACTION));
%     if ~isequal(CurrentPath,PathName)%&&~isequal(CurrentPath,fullfile(PathName,'private'))
%         addpath(PathName) 
%         errormsg=check_functions;
%         msgbox_uvmat('CONFIRMATION',[['path ' PathName ' added to the current Matlab pathes'];errormsg])
%     end
% end
set(handles.path_action,'String',PathName); %show the path to the senlected function 
    
    
%     fct_name=fullfile(PathName, FileName);
%     if ~exist(fct_name,'file')
%            msgbox_uvmat('ERROR',['procesing fct ' fct_name ' not found'])
%     else
%        ACTION=FileName(1:end-2);% 
%        menu=update_menu(handles.ACTION,ACTION);%add the selected fct to the menu
%        index_ACTION=get(handles.ACTION,'Value');% selected string index
%        list_path{index_ACTION}=PathName;
%        set(handles.ACTION,'UserData',list_path)
%        if exist(profil_perso,'file')
%             save (profil_perso,'coord_fct','-append'); %store the root name for future opening of uvmat
%         end
%     end   
%     
%     
%     fileinput=FileName;%complete file name 
%     eval(['spath=which(''' FileName ''');'])% current path to the function FileName
%     if ~isequal(spath,PathName)
%         addpath(PathName)
%     end
%     FileName([end-1:end])=[];
%     
%    % insert the choice in the action menu
%     nbACTION=length(list_ACTION);
%     index=0;
%     for ilist=1:nbACTION
%        if isequal(FileName,list_ACTION{ilist})%look for the selected scalar in the fields_input menu
%             index=ilist;% 
%        end
%     end
%     if index==0
%        list_ACTION{nbACTION}=FileName; %put the chosen fct at the penultimate place in the fields_input menu
%        list_path{nbACTION}=PathName;
%        index=nbACTION;
%        list_ACTION{nbACTION+1}='more...';
%        set(handles.ACTION,'String',list_ACTION)
%     end
%     set(handles.ACTION,'Value',index);% store the selected scalar type
%     set(handles.ACTION,'UserData',list_path);
%     usr_defined_fct=fct_name;
%     nbmenu=length(list_ACTION);
%     nbadd=nbmenu-5;
%     ilist=0;
%     for imenu=nbmenu-min(4,nbadd):nbmenu-1
%       ilist=ilist+1;
%       fct_get_field{ilist,1}=list_ACTION{imenu};
%       fct_path_get_field{ilist}=list_path{imenu};
%     end
%     if exist(profil_perso,'file')
%         save(profil_perso,'usr_defined_fct','fct_get_field','fct_path_get_field','-append')
%     else
%        save(profil_perso,'usr_defined_fct','fct_get_field','fct_path_get_field','-V6')
%     end
% end

% %check the current path to the selected function
% list_path
% PathName=list_path{index_ACTION}
% CurrentPath=fileparts(which(ACTION))
% if ~isequal(PathName,CurrentPath)
%     addpath(PathName) 
%     errormsg=check_functions;
%     msgbox_uvmat('WARNING',[['path ' PathName ' added to the current Matlab pathes'];errormsg])
% end
% set(handles.path_action,'String',fullfile(PathName,' ')); %show the path to the senlected function

%default setting for the visibility of the GUI elements*
if ~isequal(ACTION,'PLOT')
    varargout=feval(ACTION);% input list asked by the selected function
    test_1Dplot=[];
    test_scalar=[];
    test_vector=[];
    for ilist=1:length(varargout)
        switch varargout{ilist,1}
                           %RootFile always visible
            case 'check_1Dplot'   
                 test_1Dplot=isequal(lower(varargout{ilist,2}),'y');
            case 'check_scalar'
                 test_scalar=isequal(lower(varargout{ilist,2}),'y');   
            case 'check_vector'   
                 test_vector=isequal(lower(varargout{ilist,2}),'y'); 
        end
    end
    if test_1Dplot==0
        set(handles.check_1Dplot,'Value',0);
    end
    if test_1Dplot==1
        set(handles.check_1Dplot,'Value',1);
    end
    if test_scalar==0
        set(handles.check_scalar,'Value',0); 
    end
    if test_scalar==1
        set(handles.check_scalar,'Value',1); 
    end
    if test_vector==0
        set(handles.check_vector,'Value',0);
    end
    if test_vector==1
        set(handles.check_vector,'Value',1);
    end
    check_1Dplot_Callback(hObject, eventdata, handles)
    check_scalar_Callback(hObject, eventdata, handles)
    check_vector_Callback(hObject, eventdata, handles)
end

%-----------------------------------------------------
% --- browse existing figures
%-----------------------------------------------------
function browse_fig(menu_handle)
hh=findobj(allchild(0),'Type','figure');
ilist=0;
list={};
for ifig=1:length(hh)  %look for all existing figures
    name=get(hh(ifig),'Name');
     if ~isequal(name,'uvmat')%case of uvmat GUI
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
list=['new fig...';'uvmat';list];
set(menu_handle,'Value',1)
set(menu_handle,'String',list)


%-----------------------------------------------------
function list_fig_Callback(hObject, eventdata, handles)
%-----------------------------------------------------
list_fig=get(handles.list_fig,'String');
fig_val=get(handles.list_fig,'Value');
plot_fig=list_fig{fig_val};
if isequal(plot_fig,'uvmat')
    huvmat=findobj(allchild(0),'name','uvmat');
    if ~isempty(huvmat)
        uistack(huvmat,'top')
    end    
elseif ~isequal(plot_fig,'new fig...') & ~isequal(plot_fig,'uvmat')
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
testblank=findstr(fileinput,' ');%look for blanks
if ~isempty(testblank)
    msgbox_uvmat('ERROR',['The input file name ' fileinput ' contains blank character : This is not allowed. Please change name'])
    return
end
sizf=size(fileinput);
if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end
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
    txt=ver;
    Release=txt(1).Release;
    relnumb=str2double(Release(3:4));
    if relnumb >= 14
        save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5','-V6'); %store the file names for future opening of uvmat
    else
        save (profil_perso,'MenuFile_1','MenuFile_2','MenuFile_3','MenuFile_4', 'MenuFile_5'); %store the file names for future opening of uvmat
    end
end

% %store input file in personal file uvmat_perso.mat
% dir_perso=prefdir;
% profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
% if exist(profil_perso,'file')
%     save (profil_perso,'RootPath','SubDir','RootFile','NomType', 'ext','-append'); %store the root name for future opening of uvmat
% else
%    save (profil_perso,'RootPath','SubDir','RootFile','NomType', 'ext'); %store the root name for future opening of uvmat 
% end   


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

% --------------------------------------------------------------------
function MenuFile_3_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_3,'Label');
set(handles.inputfile,'String',fileinput)
inputfile_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function MenuFile_4_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_4,'Label');
set(handles.inputfile,'String',fileinput)
inputfile_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function MenuFile_5_Callback(hObject, eventdata, handles)
fileinput=get(handles.MenuFile_5,'Label');
set(handles.inputfile,'String',fileinput)
inputfile_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function MenuExportField_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function MenuHelp_Callback(hObject, eventdata, handles)
% hObject    handle to MenuHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
path_to_uvmat=which ('uvmat');% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
web([helpfile '#get_field'])    
end

