
%'view_field': function associated with the GUI 'view_field.fig' for images and data field visualization 
%------------------------------------------------------------------------
% function huvmat=view_field(input)
%
%OUTPUT
% huvmat=current handles of the GUI view_field.fig
%%
%
%INPUT:
% input: input file name (if character chain), or input image matrix to
% visualize, or Matlab structure representing  netcdf fields (with fields
% ListVarName....)
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria,  2008, LEGI / CNRS-UJF-INPG, joel.sommeria@legi.grenoble-inp.fr.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This open is part of the toolbox VIEW_FIELD.
% 
%     VIEW_FIELD is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     VIEW_FIELD is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (open VIEW_FIELD/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

%-------------------------------------------------------------------
%  I - MAIN FUNCTION VIEW_FIELD (DO NOT MODIFY)
%-------------------------------------------------------------------
%-------------------------------------------------------------------
function varargout = view_field(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',          mfilename, ...
                   'gui_Singleton',     gui_Singleton, ...
                   'gui_OpeningFcn',    @view_field_OpeningFcn, ...
                   'gui_OutputFcn',     @view_field_OutputFcn, ...
                   'gui_LayoutFcn',     [], ...
                   'gui_Callback',      []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    varargout{1:nargout} = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%-------------------------------------------------------------------
% --- Executes just before view_field is made visible.
function view_field_OpeningFcn(hObject, eventdata, handles, Field )
%-------------------------------------------------------------------

% Choose default command menuline output for view_field
handles.output = handles.axes3;

% Update handles structure
guidata(hObject, handles);

dircur=pwd; %current working directory
dir_opening=dircur;

% set the position of colorbar and ancillary GUIs:
set(hObject,'Units','Normalized')
movegui(hObject,'center')
UvData.PosColorbar=[0.805 0.022 0.019 0.445];
UvData.SetObjectOrigin=[-0.05 -0.03]; %position for set_object
UvData.SetObjectSize=[0.3 0.7];
UvData.CalOrigin=[0.95 -0.03];%position for geometry_calib (TO IMPROVE)
UvData.CalSize=[0.28 1];
handles_mouse=handles;
huvmat=findobj(allchild(0),'Name','uvmat');
hhuvmat=guidata(huvmat);
handles_mouse.create=hhuvmat.create;
handles_mouse.edit=hhuvmat.edit;

%functions for the mouse and keyboard
set(hObject,'KeyPressFcn',{'keyboard_callback',handles_mouse})%set keyboard action function
set(hObject,'WindowButtonMotionFcn',{'mouse_motion',handles_mouse})%set mouse action functio
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%set mouse click action function
set(hObject,'WindowButtonUpFcn',{'mouse_up',handles_mouse}) 


[PlotType,PlotParamOut,haxes]= plot_field(Field,handles.axes3)%,PlotParam,KeepLim,PosColorbar)
%-------------------------------------------------------------------
% --- Outputs from this function are returned to the command menuline.
function varargout = view_field_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;% the only output argument is the handle to the GUI figure

%-------------------------------------------------------------------
%-------------------------------------------------------------------
% II - FUNCTIONS FOR INTRODUCING THE INPUT FILES
% automatically sets the global properties when the rootfile name is introduced
% then activate the view-field action if selected
% it is activated either by clicking on the RootPath window or by the 
% browser 
%------------------------------------------------------------------
%------------------------------------------------------------------

%-------------------------------------------------------------------
function update_mask(handles,num_i1,num_j1)
%-------------------------------------------------------------------

MaskData=get(handles.mask_test,'UserData');
if isfield(MaskData,'maskhandle')&& ishandle(MaskData.maskhandle)
    uistack(MaskData.maskhandle,'top');
end
num_i1_mask=mod(num_i1-1,MaskData.NbSlice)+1;
[MaskName,mdetect]=name_generator(MaskData.Base,num_i1_mask,num_j1,'.png',MaskData.NomType);
huvmat=get(handles.mask_test,'parent');
UvData=get(huvmat,'UserData');

%update mask image if the mask is new
if ~ (isfield(UvData,'MaskName') && isequal(UvData.MaskName,MaskName)) 
    UvData.MaskName=MaskName; %update the recorded name on UvData
    set(huvmat,'UserData',UvData);
    if mdetect==0
        if isfield(MaskData,'maskhandle')&& ishandle(MaskData.maskhandle)
            delete(MaskData.maskhandle)    
        end
    else
        %read mask image
        Mask.AName='image';
        Mask.A=imread(MaskName);
        npxy=size(Mask.A);
        Mask.AX=[0.5 npxy(2)-0.5];
        Mask.AY=[npxy(1)-0.5 0.5 ];
        Mask.CoordType='px';
        if isequal(get(handles.slices,'Value'),1)
           NbSlice=str2num(get(handles.nb_slice,'String'));
           num_i1=str2num(get(handles.i1,'String')); 
           Mask.ZIndex=mod(num_i1-1,NbSlice)+1;
        end
        %px to phys or other transform on field
         menu_transform=get(handles.transform_fct,'String');
        choice_value=get(handles.transform_fct,'Value');
        transform_name=menu_transform{choice_value};%name of the transform fct  given by the menu 'transform_fct'
        transform_list=get(handles.transform_fct,'UserData');
        transform=transform_list{choice_value};
        if  ~isequal(transform_name,'') && ~isequal(transform_name,'px')
            if isfield(UvData,'XmlData') && isfield(UvData.XmlData,'GeometryCalib')%use geometry calib recorded from the ImaDoc xml file as first priority
                Calib=UvData.XmlData.GeometryCalib;
                Mask=transform(Mask,UvData.XmlData);
            end
        end
        flagmask=Mask.A < 200;
        
        %make brown color image
        imflag(:,:,1)=0.9*flagmask;
        imflag(:,:,2)=0.7*flagmask;
        imflag(:,:,3)=zeros(size(flagmask));
        
        %update mask image
        hmask=[]; %default
        if isfield(MaskData,'maskhandle')&& ishandle(MaskData.maskhandle)
            hmask=MaskData.maskhandle;
        end
        if ~isempty(hmask)
            set(hmask,'CData',imflag)    
            set(hmask,'AlphaData',flagmask*0.6)
            set(hmask,'XData',Mask.AX);
            set(hmask,'YData',Mask.AY);
%             uistack(hmask,'top')
        else
            axes(handles.axes3)
            hold on    
            MaskData.maskhandle=image(Mask.AX,Mask.AY,imflag,'Tag','mask','HitTest','off','AlphaData',0.6*flagmask);
%             set(MaskData.maskhandle,'AlphaData',0.6*flagmask)
            set(handles.mask_test,'UserData',MaskData)
        end
    end
end


%-------------------------------------------------------------------
function MenuExportFigure_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
huvmat=get(handles.MenuExport,'parent');
UvData=get(huvmat,'UserData');
hfig=figure;
newaxes=copyobj(handles.axes3,hfig);
map=colormap(handles.axes3);
colormap(map);%transmit the current colormap to the zoom fig
colorbar

%-------------------------------------------------------------------
%-------------------------------------------------------------------
% III - MAIN REFRESH FUNCTIONS : 'FRAME PLOT'
%-------------------------------------------------------------------
%-------------------------------------------------------------------

%Executes on button press in runplus: make one step forward and call
%run0. The step forward is along the fields series 1 or 2 depending on 
%the scan_i and scan_j check box (exclusive each other)
%-------------------------------------------------------------------
function runplus_Callback(hObject, eventdata, handles)
increment=str2num(get(handles.increment_scan,'String')); %get the field increment d
runpm(hObject,eventdata,handles,increment)

%-------------------------------------------------------------------
%Executes on button press in runmin: make one step backward and call
%run0. The step backward is along the fields series 1 or 2 depending on 
%the scan_i and scan_j check box (exclusive each other)
%-------------------------------------------------------------------
function runmin_Callback(hObject, eventdata, handles)
increment=-str2num(get(handles.increment_scan,'String')); %get the field increment d
runpm(hObject,eventdata,handles,increment)

%-------------------------------------------------------------------
%Executes on button press in runmin: make one step backward and call
%run0. The step backward is along the fields series 1 or 2 depending on 
%the scan_i and scan_j check box (exclusive each other)
%-------------------------------------------------------------------
function RunMovie_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
set(handles.RunMovie,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
increment=str2num(get(handles.increment_scan,'String')); %get the field increment d
set(handles.STOP,'Visible','on')
set(handles.speed,'Visible','on')
set(handles.speed_txt,'Visible','on')
set(handles.RunMovie,'BusyAction','queue')
testavi=0;
UvData=get(handles.view_field,'UserData');

while get(handles.speed,'Value')~=0 & isequal(get(handles.RunMovie,'BusyAction'),'queue') % enable STOP command
        runpm(hObject,eventdata,handles,increment)
        pause(1.02-get(handles.speed,'Value'))% wait for next image
end
if isfield(UvData,'aviobj') && ~isempty( UvData.aviobj),
    UvData.aviobj=close(UvData.aviobj);
   set(handles.view_field,'UserData',UvData);
end
set(handles.RunMovie,'BackgroundColor',[1 0 0])%paint the command buttonback to red

%-------------------------------------------------------------------
function STOP_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
set(handles.movie_pair,'BusyAction','Cancel')
set(handles.movie_pair,'value',0)
set(handles.RunMovie,'BusyAction','Cancel')
set(handles.MenuExportMovie,'BusyAction','Cancel')


%------------------------------------------------------------------
function runpm(hObject,eventdata,handles,increment)
%------------------------------------------------------------------
%check for mùovie pair status
movie_status=get(handles.movie_pair,'Value');
if isequal(movie_status,1)
    STOP_Callback(hObject, eventdata, handles)
end
%read the data on the current input rootfile(s)

[FileName,RootPath,filebase,FileIndices,FileExt,subdir]=read_file_boxes(handles);
NomType=get(handles.FileIndex,'UserData');

num1=stra2num(get(handles.i1,'String'));
num2=stra2num(get(handles.i2,'String'));
num_a=stra2num(get(handles.j1,'String'));
num_b=stra2num(get(handles.j2,'String'));

sub_value= get(handles.SubField,'Value');
if sub_value ==1
    [FileName_1,RootPath_1,filebase_1,FileIndices_1,FileExt_1,SubDir_1]=read_file_boxes_1(handles);
end   

comp_input=get(handles.fix_pair,'Value');
if isequal(NomType,'_i1-i2')|isequal(NomType,'_i1-i2_j')
    comp_input=1; %impose a fixed pair interval
    set(handles.fix_pair,'Value',1)
end

%case of scanning along the first direction (rootfile numbers)
if get(handles.scan_i,'Value')==1% case of scanning along field numbers   
     num1=num1+increment;
     num2=num2+increment;
    if comp_input==0% find a free pair
        [filename,num_i1_out,num_j1_out,num_i2_out,num_j2_out]=...
           name_generator(filebase,num1,num_a,FileExt,NomType,0,num2,num_b,subdir);
        if exist(filename,'file')
            num_a=num_j1_out;
            num_b=num_j2_out;
        end 
    end
    if sub_value>=2
        num_i1=num_i1+increment;
        num_i2=num_i2+increment;
    end   
else % case of scanning along the second direction (burst numbers)
    lastfield_cell=get(handles.last_j,'String'); % get the last field number
    lastfield=str2num(lastfield_cell{1});
    num_a=num_a+increment;
    num_b=num_b+increment;
    if sub_value >=2
      num_j1=num_j1+increment;
      num_j2=num_j2+increment;
    elseif ~isempty(lastfield) && num_a>lastfield
        num_a=1;
        num1=num1+1;
        num2=num2+1;
    end
end

% display the new open numbers
set(handles.i1,'String',num2stra(num1,NomType,1)); 
set(handles.i2,'String',num2stra(num2,NomType,1));
set(handles.j1,'String',num2stra(num_a,NomType,2));
set(handles.j2,'String',num2stra(num_b,NomType,2));
[indices]=name_generator('',num1,num_a,'',NomType,1,num2,num_b,'');
set(handles.FileIndex,'String',indices);
if sub_value ==1
    NomType_1=get(handles.FileIndex_1,'UserData');
     [indices]=...
           name_generator('',num1,num_a,'',NomType_1,1,num2,num_b,'');
     set(handles.FileIndex_1,'String',indices);
end

if isequal(movie_status,1)
    set(handles.movie_pair,'Value',1)
    movie_pair_Callback(hObject, eventdata, handles); %run
else
% refresh plots
    run0_Callback(hObject, eventdata, handles); %run
end


%-------------------------------------------------------
% --- Executes on button press in movie_pair: create an alternating movie with two view
%-------------------------------------------------------
function movie_pair_Callback(hObject, eventdata, handles)
status=get(handles.movie_pair,'value');
if isequal(status,0)
    set(handles.movie_pair,'BusyAction','Cancel')
    return
else
    set(handles.movie_pair,'BusyAction','queue')
end
%initialisation
set(handles.movie_pair,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
list_fields=get(handles.Fields,'String');% list menu fields
index_fields=get(handles.Fields,'Value');% selected string index
FieldName=list_fields{index_fields}; % selected field
if isequal(FieldName,'image')
    run0_Callback(hObject, eventdata, handles)%display the first image
    UvData=get(handles.view_field,'UserData');
else
    msgbox_view_field('ERROR','an image or movie must be first introduced as input')
    return
end
[ff,rr,filebase,xx,Ext,SubDir]=read_file_boxes(handles);
NomType=get(handles.FileIndex,'UserData');
num_i1=stra2num(get(handles.i1,'String'));
num_j1=stra2num(get(handles.j1,'String'));
num_i2=stra2num(get(handles.i2,'String'));
num_j2=stra2num(get(handles.j2,'String'));
if isempty(num_j2)
    if isempty(num_i2)   
        msgbox_view_field('ERROR', 'a second image index i2 or j2 is needed to show the pair as a movie')
        return
    else
        num_j2=num_j1;%repeat the index i1 by default
    end
end
if isempty(num_i2)
    num_i2=num_i1;%repeat the index i1 by default
end
imaname_1=name_generator(filebase,num_i2,num_j2,Ext,NomType);
if ~exist(imaname_1,'file')
      msgbox_view_field('ERROR',['second input open (-)  ' imaname_1 ' not found']);
      return
end
% set(handles.i2,'String',''); % indicates that the second index i2 is not used
% set(handles.j2,'String',''); % indicates that the second index i2 is not used

%read the second image
Field.AName='image';
Field.AX=UvData.Field.AX;
Field.AY=UvData.Field.AY;
% z index
nbslice=str2double(get(handles.nb_slice,'String'));
if ~isempty(nbslice)
    Field.ZIndex=mod(num_i2-1,nbslice)+1;
end
Field.CoordType='px';
%determine the input file type
if isfield(UvData,'MovieObject')
    FileType='movie';
elseif isequal(lower(Ext),'.avi')
    FileType='avi';
elseif isequal(lower(Ext),'.vol')
    FileType='vol';
else 
   form=imformats(Ext([2:end]));
   if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
       if isequal(NomType,'*');
           FileType='multimage';
       else
           FileType='image';
       end
   end
end
switch FileType
        case 'movie'
            Field.A=read(UvData.MovieObject,num_i2);
        case 'avi'
            mov=aviread(imaname_1,num_i2);
            Field.A=frame2im(mov(1));
        case 'vol'
            Field.A=imread(imaname_1);
        case 'multimage'
            Field.A=imread(imaname_1,num_i2);
        case 'image'
            Field.A=imread(imaname_1);
end 

%px to phys or other transform on field
menu_transform=get(handles.transform_fct,'String');
choice_value=get(handles.transform_fct,'Value');
transform_name=menu_transform{choice_value};%name of the transform fct  given by the menu 'transform_fct'
transform_list=get(handles.transform_fct,'UserData');
transform=transform_list{choice_value};
if  ~isequal(transform_name,'') && ~isequal(transform_name,'px')
    if isfield(UvData,'XmlData') && isfield(UvData.XmlData,'GeometryCalib')%use geometry calib recorded from the ImaDoc xml file as first priority
        Field=transform(Field,UvData.XmlData);
    end
end

 % make movie until movie speed is set to 0 or STOP is activated
hima=findobj(handles.axes3,'Tag','ima');% %handles.axes3 =main plotting window (A GENERALISER)
set(handles.STOP,'Visible','on')
set(handles.speed,'Visible','on')
set(handles.speed_txt,'Visible','on')
while get(handles.speed,'Value')~=0 && isequal(get(handles.movie_pair,'BusyAction'),'queue')%isequal(get(handles.run0,'BusyAction'),'queue'); % enable STOP command
    % read and plot the series of images in non erase mode
    set(hima,'CData',Field.A); 
    pause(1.02-get(handles.speed,'Value'));% wait for next image
    set(hima,'CData',UvData.Field.A);
    pause(1.02-get(handles.speed,'Value'));% wait for next image
end
set(handles.movie_pair,'BackgroundColor',[1 0 0])%paint the command button in red

%-------------------------------------------------------
% --- Executes on button press in run0.
%-------------------------------------------------
function run0_Callback(hObject, eventdata, handles)

%initialisation
set(handles.run0,'BackgroundColor',[1 1 0])%paint the command button in yellow
drawnow
abstime=[];
abstime_1=[];
dt=[];
Field={};
UvData=get(handles.view_field,'UserData');
if isfield(UvData,'Txt')
    UvData=rmfield(UvData,'Txt');%erase previous error message
end
%set(handles.run0,'BusyAction','queue');
if ishandle(handles.VIEW_FIELD_title) %remove title panel on view_field
    delete(handles.VIEW_FIELD_title)
end

% determine the main input file information for action
TestInputFile=1;%default
if isfield(UvData,'TestInputFile')&& isequal(UvData.TestInputFile,0),
    TestInputFile=0;
end
num_i1=[];%default
FileType=[];%default
if TestInputFile
    [filename,RootPath,filebase,xx,Ext]=read_file_boxes(handles);
    if ~exist(filename,'file')
        msgbox_view_field('ERROR',['input file ' filename ' does not exist'])
        return
    end
    num_i1=stra2num(get(handles.i1,'String'));
    num_i2=stra2num(get(handles.i2,'String'));
    num_j1=stra2num(get(handles.j1,'String'));
    num_j2=stra2num(get(handles.j2,'String'));
    NomType=get(handles.FileIndex,'UserData');
    %update the z position index
    nbslice=str2double(get(handles.nb_slice,'String'));
    if ~isnan(nbslice)
        z_index=mod(num_i1-1,nbslice)+1;
        set(handles.z_index,'String',num2str(z_index))
        % refresh menu for save_mask if relevant
        masknumber=get(handles.masklevel,'String');
        if length(masknumber)>=z_index
            set(handles.masklevel,'Value',z_index)
        end
    end
    % determine the input file type
    if isequal(Ext,'.nc')||isequal(Ext,'.cdf')
        FileType='netcdf';
    elseif isfield(UvData,'MovieObject')
        FileType='movie';
        FieldName='image';
    elseif isequal(lower(Ext),'.avi')
        FileType='avi';
        FieldName='image';
    elseif isequal(lower(Ext),'.vol')
        FileType='vol';
        FieldName='image';
    else 
       form=imformats(Ext([2:end]));
       if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
           if isequal(NomType,'*');
               FileType='multimage';
           else
               FileType='image';
           end
           FieldName='image';
       end
    end
else
    filename=[];
    FileType='netcdf';
    FieldName='get_field...';
end
VelType=[];%default
if isequal(FileType,'netcdf')
    list_fields=get(handles.Fields,'String');% list menu fields
    index_fields=get(handles.Fields,'Value');% selected string index
    FieldName= list_fields{index_fields}; % selected field
    if isequal(FieldName,'get_field...')% read the field names on the interface get_field...
        VelType=get(handles.Fields,'UserData'); 
        Field{1}=get(handles.Fields,'UserData');
    else
       VelType=setfield(handles);
    end
end

% choose a second field if Subfield option is 'on'
filename_1=[];
FieldName_1=[];
scal_color=[];
VelType_1=setfield_1(handles);
sub_value=get(handles.SubField,'Value');
FileType_1='none';%default
if sub_value==1
    filename_1=read_file_boxes_1(handles);
    if ~exist(filename_1,'file')
        msgbox_view_field('ERROR',['second file ' filename_1 ' does not exist'])
        return
    end
    NomType_1=get(handles.FileIndex_1,'UserData');
    Ext_1=get(handles.FileExt_1,'String');
    % determine the input file type
    if isequal(Ext_1,'.nc')||isequal(Ext_1,'.cdf')
        FileType_1='netcdf';
    elseif isfield(UvData,'MovieObject_1')
        FileType_1='movie';
        FieldName_1='image';
    elseif isequal(lower(Ext_1),'.avi')
        FileType='avi';
        FieldName_1='image';
    elseif isequal(lower(Ext_1),'.vol')
        FileType_1='vol';
        FieldName_1='image';
    else 
       form=imformats(Ext([2:end]));
       if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
           if isequal(NomType_1,'*');
               FileType_1='multimage';
           else
               FileType_1='image';
           end
           FieldName_1='image';
       end
    end
    if ~isequal(FieldName_1,'image')
        list_fields=get(handles.Fields_1,'String');% list menu fields
        index_fields=get(handles.Fields_1,'Value');% selected string index
        FieldName_1= list_fields{index_fields}; % selected field
        if isequal(VelType_1,'*')% free veltype choice
            VelType_1=[];
        elseif isequal(VelType_1,'"')% veltype the same as for the first field
            if isempty(VelType)
                VelType_1=[];
            else
                VelType_1=VelType;
            end
        end
    end
end

% test for keeping the previous stored data if the input files are unchanged
test_keepdata_1=0;%defautl
test_keepdata=0;
if sub_value>=2
    if ~isequal(NomType_1,'*')%in cas of a series of files (not avi movie)
        if isfield(UvData,'filename_1')&& isfield(UvData,'VelType_1') && isfield(UvData,'FieldName_1')
            test_keepdata_1= isequal(filename_1,UvData.filename_1)&&...
                isequal(VelType_1,UvData.filename_1) && isequal(FieldName_1,UvData.FieldName_1);

        end
    end
end

%read the input field(s)

%read images
if ~isempty(filename) && isequal(FieldName,'image')
     switch FileType
        case 'movie'
            A=read(UvData.MovieObject,num_i1);
        case 'avi'
            mov=aviread(filename,num_i1);
            A=frame2im(mov(1));
        case 'vol'
            A=imread(filename);
        case 'multimage'
            A=imread(filename,num_i1);
        case 'image'
            A=imread(filename);
    end 
    npxy=size(A);
    set(handles.npx,'String',num2str(npxy(2)));% display image size on the interface
    set(handles.npy,'String',num2str(npxy(1)));
    Rangx=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
    Rangy=[npxy(1)-0.5 0.5]; %
    Field{1}.AName='image';
    Field{1}.ListVarName={'AY','AX','A'}; % 
    if size(A,3)==3;%color
        Field{1}.VarDimName={'AY','AX',{'AY','AX','rgb'}}; %
    else
        Field{1}.VarDimName={'AY','AX',{'AY','AX'}}; %
    end
    Field{1}.AY=Rangy;
    Field{1}.AX=Rangx;
    Field{1}.A=A;
    Field{1}.CoordType='px'; %used for mouse_motion
    Field{1}.CoordUnit='pixel'; %used for mouse_motion
end

%read a second image
if ~isfield(UvData,'Txt')&& ~isempty(filename_1) && isequal(FieldName_1,'image')
    switch FileType_1
        case 'movie'
            A=read(UvData.MovieObject_1,num_i1);
        case 'avi'
            mov=aviread(filename,num_i1);
            A=frame2im(mov(1));
        case 'vol'
            A=imread(filename);
        case 'multimage'
            A=imread(filename,num_i1);
        case 'image'
            A=imread(filename);
    end 
    npxy=size(A);
    set(handles.npx,'String',num2str(npxy(2)));% display image size on the interface
    set(handles.npy,'String',num2str(npxy(1)));
    Rangx=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
    Rangy=[npxy(1)-0.5 0.5]; %
    Field{2}.AName='image';
    Field{2}.ListVarName={'AY','AX','A'}; % 
    if size(A,3)==3;%color
        Field{2}.VarDimName={'AY','AX',{'AY','AX','rgb'}}; %
    else
        Field{2}.VarDimName={'AY','AX',{'AY','AX'}}; %
    end
    Field{2}.AY=Rangy;
    Field{2}.AX=Rangx;
    Field{2}.A=A;
    Field{2}.CoordType='px'; %used for mouse_motion
    Field{2}.CoordUnit='px'; %used for move_mou
end

%read ncfile(s)
CivStage_1=0;%default
VelType_out_1=[];
InputField={FieldName};
InputField_1={FieldName_1};
if ~isfield(UvData,'Txt') && ((~isempty(filename)&& isequal(FileType,'netcdf')) || (~isempty(filename_1)&& isequal(FileType,'netcdf'))) ;
    %read the velocity field(s) from netcdf rootfile(s)
    list_code=get(handles.col_vec,'String');% list menu fields
    index_code=get(handles.col_vec,'Value');% selected string index
    scal_color= list_code{index_code(1)}; % selected field
    if isequal(FieldName,'velocity')&& ~isequal(scal_color,'black') && ~isequal(scal_color,'white')
        InputField=[InputField scal_color];
    end
    if isequal(FieldName_1,'velocity') && ~isequal(scal_color,'black') && ~isequal(scal_color,'white')
        InputField_1=[InputField_1 scal_color];
    end
    if isequal(FileType,'netcdf')  %read the first nc field
        if isequal(FieldName,'get_field...')% read the field names on the interface get_field.
            VelType=get(handles.Fields,'UserData');
            hget_field=findobj(allchild(0),'Name','get_field');%find the get_field... GUI
            if isempty(hget_field)
                hget_field= get_field(filename);%open the get_field GUI    
            end
            hhget_field=guidata(hget_field);
            set(hhget_field.inputfile,'String',filename)% update the list of input fields in get_field
            set(hhget_field.ACTION,'Value',1)% PLOT option selected
            set(hhget_field.list_fig,'Value',2)% plotting axes =view_field selected
            [Field{1},errormsg]=read_get_field(hget_field); %read the names of the variables to plot in the get_field GUI
            if ~isempty(errormsg)
                msgbox_view_field('ERROR',['error in view_field/run0_Callback/read_get_field: ' errormsg])
                return
            end
            CivStage=0;
            VelType_out=[];         
        else
            [Field{1},VelType_out]=read_civxdata(filename,InputField,VelType);
            if isfield(Field{1},'Txt')
                msgbox_view_field('ERROR',Field{1}.Txt)
                return
            end
            CivStage=Field{1}.CivStage;
            UvData.NbDim=Field{1}.nb_dim;
        end
    end
    if ~isempty(filename_1) && isequal(FileType_1,'netcdf') %read the second file
        if isequal(FieldName_1,'get_field...')% read the field names on the interface get_field.
            hget_field=findobj(allchild(0),'Name','get_field_1');%find the get_field... GUI
             if isempty(hget_field)
                 hget_field= get_field(filename_1);%open the get_field GUI
                 set(hget_field,'name','get_field_1')
%                 enable_transform(handles,'off')% no field transform (possible transform in the GUI get_field)
             end
            hhget_field=guidata(hget_field);%handles of GUI elements in get_field
            SubField=get_field('read_var_names',hObject,eventdata,hhget_field); %read the names of the variables to plot in the get_field GUI 
            [Field{2},var_detect]=nc2struct(filename_1,SubField.ListVarName); %read the corresponding input data                
            Field{2}.VarAttribute=SubField.VarAttribute;
            %update the display on get_field
            set(hhget_field.inputfile,'String',filename_1)
            set(hhget_field.variables,'Value',1)
            Tabchar={''};%default
            Tabcell=[];
            if isfield(Field{2},'ListGlobalAttribute')& ~isempty(Field{2}.ListGlobalAttribute)
                for iline=1:length(Field{2}.ListGlobalAttribute)
                    Tabcell{iline,1}=Field{2}.ListGlobalAttribute{iline};
                    if isfield(Field{2}, Field{2}.ListGlobalAttribute{iline})
                        eval(['val=Field{2}.' Field{2}.ListGlobalAttribute{iline} ';'])
                        if ischar(val);
                            Tabcell{iline,2}=val;
                        else
                            Tabcell{iline,2}=num2str(val);
                        end
                    end
                end
                if ~isempty(Tabcell)
                    Tabchar=cell2tab(Tabcell,'=');
                    Tabchar=[{''};Tabchar];
                end
            end
            set(hhget_field.attributes,'String',Tabchar);%update list of global attributes in get_field 
        else
            [Field{2},VelType_out_1]=read_civxdata(filename_1,[],VelType_1);
            CivStage_1=Field{2}.CivStage;
        end
        if ~isequal(FileType,'netcdf')
            VelType_out=VelType_out_1;
        end
    end
end

%update the display buttons for the first velocity type (first menuline)
veltype_handles=[handles.civ1 handles.interp1 handles.filter1 handles.civ2 handles.interp2 handles.filter2];
if ~isequal(FileType,'netcdf')
    reset_vel_type(veltype_handles)
elseif isempty(VelType)
    set_veltype_display(veltype_handles,CivStage)%update the display of available velocity types for the first field
    if isempty(VelType_out)
        reset_vel_type(veltype_handles)
    else
        handle1=eval(['handles.' VelType_out]);
        reset_vel_type(veltype_handles,handle1)
    end
end

%update the display buttons for the second velocity type (second menuline)
veltype_handles_1=[handles.civ1_1 handles.interp1_1 handles.filter1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1];
if ~isequal(FileType_1,'netcdf')
    reset_vel_type(veltype_handles_1)
elseif isempty(VelType_1)
    set_veltype_display(veltype_handles_1,CivStage_1)%update the display of available velocity types for the first field
    if isempty(VelType_out_1)
        reset_vel_type(veltype_handles_1)
    else
        handle1=eval(['handles.' VelType_out_1 '_1']);
        reset_vel_type(veltype_handles_1,handle1)
    end
end

%introduce w as background image by default for a new series (only for nbdim=2)
if ~isfield(UvData,'NewSeries')
    UvData.NewSeries=1;
end
%put W as background image by default if NbDim=2:
if ~isfield(UvData,'NbDim')||isempty(UvData.NbDim)||~isequal(UvData.NbDim,3)
    if UvData.NewSeries && isequal(get(handles.SubField,'Value'),0) && isfield(Field{1},'W') && ~isempty(Field{1}.W);
        set(handles.SubField,'Value',1);
        %menu=update_menu(handles.Fields_1,'w');%update the menu for the background scalar nd set the choice to 'w'
        set(handles.RootPath_1,'String','"')
        set(handles.RootFile_1,'String','"')
        set(handles.SubDir_1,'String','"');
        [indices]=name_generator('',num_i1,num_j1,'',NomType,1,num_i2,num_j2,'');
        set(handles.FileIndex_1,'String',indices)
        set(handles.FileExt_1,'String','"');
        set(handles.Fields_1,'Visible','on');
        set(handles.Fields_1,'Visible','on');
        set(handles.RootPath_1,'Visible','on')
        set(handles.RootFile_1,'Visible','on')
        set(handles.SubDir_1,'Visible','on');
        set(handles.FileIndex_1,'Visible','on');
        set(handles.FileExt_1,'Visible','on');
        set(handles.Fields_1,'Visible','on');
        Field{1}.AName='w';
        testscal=1;
    end
end           

%multislice case
if TestInputFile &&(~isfield(UvData,'NbDim') || isequal(UvData.NbDim,2))&&...%2D case
      isfield(UvData,'XmlData') && isfield(UvData.XmlData,'GeometryCalib')&& isfield(UvData.XmlData.GeometryCalib,'SliceCoord')
%     nbfield2=str2num(get(handles.last_j,'String'));
       siz=size(UvData.XmlData.GeometryCalib.SliceCoord);
       if siz(1)>1
           NbSlice=siz(1);
           set(handles.slices,'Visible','on')
           set(handles.slices,'Value',1)
       else
           NbSlice=1;
       end
       set(handles.nb_slice,'String',num2str(NbSlice))
       slices_Callback(hObject, eventdata, handles)
%        Coord=UvData.XmlData.GeometryCalib.SliceCoord;
%        ZIndex=num_i1-NbSlice*(floor((num_i1-1)/NbSlice));
%        Field{1}.Z=ZIndex;
end

%store the current open names, fields and vel types in view_field interface 
UvData.filename=filename;
UvData.filename_1=filename_1;
UvData.VelType=VelType;
UvData.VelType_1=VelType_1;
UvData.FieldName=FieldName;
UvData.FieldName_1=FieldName_1;
if ~isempty(scal_color)
    UvData.CName=scal_color;
end

%coordinate transform or user fct
XmlData=[];%default
if isfield(UvData,'XmlData')%use geometry calib recorded from the ImaDoc xml file as first priority
    XmlData=UvData.XmlData;
end
XmlData_1=[];%default
if isfield(UvData,'XmlData_1')
   XmlData_1=UvData.XmlData_1;
end
menu_transform=get(handles.transform_fct,'String');
choice_value=get(handles.transform_fct,'Value');
%transform=menu_transform{choice_value};%name of the transform fct  given by the menu 'transform_fct'
transform_list=get(handles.transform_fct,'UserData');
transform=transform_list{choice_value};%selected function handles

% z index
if TestInputFile
    Field{1}.ZIndex=mod(num_i1-1,nbslice)+1;
end
%px to phys or other transform on field
if  ~isempty(transform) 
    if length(Field)>=2
        Field{2}.ZIndex=mod(num_i1-1,nbslice)+1;
        [Field{1},Field{2}]=transform(Field{1},XmlData,Field{2},XmlData_1);
        if isempty(Field{2})
            Field(2)=[];
        end
    else
        Field{1}=transform(Field{1},XmlData);
    end
end 

%calculate scalar
if isequal(FileType,'netcdf') && ~isequal(FieldName,'get_field...')%
    Field{1}=calc_field(InputField,Field{1});
end
if length(Field)==2 && isequal(FileType_1,'netcdf') && ~isequal(FieldName_1,'get_field...')
    Field{2}=calc_field(InputField_1,Field{2});
end

% combine the two input fields (e.g. substract velocity fields)
if numel(Field)==2
    if ~(isequal(get(handles.movie_pair,'Value'),1) && isequal(FieldName,'image') && isequal(FieldName_1,'image')) %combine fields if not viewing image pairs
        UvData.Field=sub_field(Field{1},Field{2}); %TO UPDATE FOR MORE GENERAL INPUT
    end
else
   UvData.Field=Field{1};
end
UvData.NewSeries=0;% put to 0 the test for a new field series (set by RootPath_callback)
% test 3D , default projection menuplane and typical mesh (needed to menuopen set_object)
test_x=0;
test_z=0;% test for unstructured z coordinate
UvData.ZMax=0;
UvData.ZMin=0;%default
UvData.Mesh=1; %default
[UvData.Field,errormsg]=check_field_structure(UvData.Field);
if ~isempty(errormsg)
    msgbox_view_field('ERROR',['error in view_field/run0_Callback/check_field_structure: ' errormsg])
    return
end
[CellVarIndex,NbDim,VarType]=find_field_indices(UvData.Field);
[NbDim,imax]=max(NbDim);
if isempty(imax)
%    DimVarIndex=0;    
    coord_x=[];
else
%     VarIndex=CellVarIndex{imax};
    coord_x=VarType{imax}.coord_x;
end
if isfield(UvData,'NbDim') && ~isempty(UvData.NbDim)
    NbDim=UvData.NbDim;
else  
    UvData.NbDim=NbDim;
end
if ~isempty(CellVarIndex) && ~isempty(VarType{imax}.coord_x)  && ~isempty(VarType{imax}.coord_y)    %unstructured coordinate z
    XName=UvData.Field.ListVarName{VarType{imax}.coord_x};
    YName=UvData.Field.ListVarName{VarType{imax}.coord_y};
    test_x=1;
elseif isfield(UvData.Field,'X') && isfield(UvData.Field,'Y')
    XName='X';
    YName='Y';
    test_x=1;
end
if test_x
    eval(['UvData.XMax=max(UvData.Field.' XName ');'])
    eval(['UvData.XMin=min(UvData.Field.' XName ');'])
    eval(['UvData.YMax=max(UvData.Field.' YName ');'])
    eval(['UvData.YMin=min(UvData.Field.' YName ');'])
    eval(['nbvec=length(UvData.Field.' XName ');'])
    if NbDim==3%
        if ~isempty(CellVarIndex) && ~isempty(VarType{imax}.coord_z)%unstructured coordinate z
            ZName=UvData.Field.ListVarName{VarType{imax}.coord_z};
            eval(['UvData.ZMax=max(UvData.Field.' ZName ');'])
            eval(['UvData.ZMin=min(UvData.Field.' ZName ');'])
            test_z=1;   
        elseif isfield(UvData,'Z')% usual civ data
            UvData.ZMax=max(UvData.Z);
            UvData.ZMin=min(UvData.Z);
            test_z=1;
        end
    end
    if isequal(UvData.ZMin,UvData.ZMax)%no z dependency
        NbDim=2;
        test_z=0;
    end    
    if test_z
         UvData.Mesh=((UvData.XMax-UvData.XMin)*(UvData.YMax-UvData.YMin)*(UvData.ZMax-UvData.ZMin))/nbvec;% volume per vector
         UvData.Mesh=(UvData.Mesh)^(1/3);
    else
        UvData.Mesh=sqrt((UvData.XMax-UvData.XMin)*(UvData.YMax-UvData.YMin)/nbvec);%2D
    end
end
%case of structured coordinates
if isfield(UvData.Field,'AX') & isfield(UvData.Field,'AY')& isfield(UvData.Field,'A')
    UvData.XMax=max(UvData.Field.AX);
    UvData.XMin=min(UvData.Field.AX);
    UvData.YMax=max(UvData.Field.AY);
    UvData.YMin=min(UvData.Field.AY);
    np_A=size(UvData.Field.A);
    UvData.Mesh=sqrt((UvData.XMax-UvData.XMin)*(UvData.YMax-UvData.YMin)/((np_A(1)-1) * (np_A(2)-1))) ; 
end
if  isempty(coord_x)&~isempty(CellVarIndex)
    VarIndex=CellVarIndex{imax}; % list of variable indices
    DimIndex=UvData.Field.VarDimIndex{VarIndex(1)}; %list of dim indices for the variable
    if NbDim==3
        nbpoints=UvData.Field.DimValue(DimIndex(1));
        %Zvar=DimVarIndex(DimIndex(1));
         %Zvar=DimVarIndex(1);
         Zvar=VarType{imax}.coord_3;
        if Zvar~=0 % z is a dimension variable
            ZName=UvData.Field.ListVarName{Zvar};
            eval(['UvData.ZMax=max(UvData.Field.' ZName ');'])
            eval(['UvData.ZMin=min(UvData.Field.' ZName ');'])
        else
            testcoord_z=0;
            if length(UvData.Field.VarAttribute)>=VarIndex(1)
                if isfield(UvData.Field.VarAttribute{VarIndex(1)},'Coord_1')%regular grid 
                    Coord_z=UvData.Field.VarAttribute{VarIndex(1)}.Coord_1;
                    UvData.ZMax=max(Coord_z);
                    UvData.ZMin=min(Coord_z);
                    testcoord_z=1;
                end
            end
            if ~testcoord_z
                  UvData.ZMin=1;
                  UvData.ZMax=UvData.Field.DimValue(DimIndex(1));
            end
        end
        UvData.Mesh=(UvData.ZMax-UvData.ZMin)/(nbpoints-1); 
    elseif NbDim==2
        nbpoints_y=UvData.Field.DimValue(DimIndex(1));       
        Yvar=VarType{imax}.coord_y;
        if Yvar~=0  % x is a dimension variable
            YName=UvData.Field.ListVarName{Yvar};
            eval(['UvData.YMax=max(UvData.Field.' YName ');'])
            eval(['UvData.YMin=min(UvData.Field.' YName ');'])
        else
            testcoord_y=0;
            if ~testcoord_y
                  UvData.YMin=1;
                  UvData.YMax=UvData.Field.DimValue(DimIndex(1));
            end
        end
        DY=(UvData.YMax-UvData.YMin)/(nbpoints_y-1);
        nbpoints_x=UvData.Field.DimValue(DimIndex(2));
        Xvar=VarType{imax}.coord_x;
        if Xvar~=0  % x is a dimension variable
            XName=UvData.Field.ListVarName{Xvar};
            eval(['UvData.XMax=max(UvData.Field.' XName ');'])
            eval(['UvData.XMin=min(UvData.Field.' XName ');'])
        else
            testcoord_x=0;
            if ~testcoord_x
                  UvData.XMin=1;
                  UvData.XMax=UvData.Field.DimValue(DimIndex(2));
            end
        end
        DX=(UvData.XMax-UvData.XMin)/(nbpoints_x-1);
        UvData.Mesh= sqrt(DX*DY); 
    end
end

%create a default projection menuplane
UvData.Object{1}.Style='plane';%main plotting plane
UvData.Object{1}.ProjMode='projection';%main plotting plane
if ~isfield(UvData.Object{1},'plotaxes')
    UvData.Object{1}.plotaxes=handles.axes3;%default plotting axis
    set(handles.list_object,'String',{'1-PLANE';'...'});
    set(handles.list_object,'Value',1);
end

%3D case (menuvolume)
if NbDim==3
    UvData.Object{1}.NbDim=UvData.NbDim;%test for 3D objects
    UvData.Object{1}.RangeZ=UvData.Mesh;%main plotting plane
    UvData.Object{1}.Coord(1,3)=(UvData.ZMin+UvData.ZMax)/2;%section at a middle plane chosen
    UvData.Object{1}.Phi=0;
    UvData.Object{1}.Theta=0;
    UvData.Object{1}.Psi=0;
    UvData.Object{1}.HandlesDisplay=plot(0,0,'Tag','proj_object');% A REVOIR  
    PlotHandles=get_plot_handles(handles);
    ZBounds(1)=UvData.ZMin; %minimum for the Z slider
    ZBounds(2)=UvData.ZMax;%maximum for the Z slider
    set_object(UvData.Object{1},PlotHandles,ZBounds);
    set(handles.list_object,'Value',1);
%multilevel case (single menuplane in a 3D space)
elseif isfield(UvData,'Z')
    if isfield(UvData,'CoordType')& isequal(UvData.CoordType,'phys') & isfield(UvData,'XmlData')
        XmlData=UvData.XmlData;
        if isfield(XmlData,'PlanePos')
             UvData.Object{1}.Coord=XmlData.PlanePos(UvData.ZIndex,:);
        end
        if isfield(XmlData,'PlaneAngle')
            siz=size(XmlData.PlaneAngle);
            indangle=min(siz(1),UvData.ZIndex);%take first angle if a single angle is defined (translating scanning)              
            UvData.Object{1}.Phi=XmlData.PlaneAngle(indangle,1);
            UvData.Object{1}.Theta=XmlData.PlaneAngle(indangle,2);
            UvData.Object{1}.Psi=XmlData.PlaneAngle(indangle,3);
        end
    elseif isfield(UvData,'ZIndex')
        UvData.Object{1}.ZObject=UvData.ZIndex;
    end
end

%Plot the projections on all existing  projection objects
keeplim=get(handles.FixedLimits,'Value');
%reset the min and max of scalar if only the mask is displayed
if isfield(UvData,'Mask')&~isfield(UvData,'A')
    set(handles.MinA,'String','0')
    set(handles.MaxA,'String','255')
end

Object=UvData.Object;
for iobj=1:length(Object)
    if ~isempty(Object{iobj})%& isfield(Object{iobj},'plotaxes')& ishandle(Object{iobj}.plotaxes)
        %Projeter les champs sur l'objet:*
        ObjectData=proj_field(UvData.Field,Object{iobj},iobj);
   
        %use of mask
        if isfield(ObjectData,'NbDim')&isequal(ObjectData.NbDim,2)
            if isfield(ObjectData,'Mask') & isfield(ObjectData,'A')
                 flag_mask=double(ObjectData.Mask>200);%=0 for masked regions
                 AX=ObjectData.AX;
                 AY=ObjectData.AY;
                 MaskX=ObjectData.MaskX;
                 MaskY=ObjectData.MaskY;
                 if ~isequal(MaskX,AX)|~isequal(MaskY,AY)
                     nxy=size(flag_mask);
                     sizpx=(ObjectData.MaskX(end)-ObjectData.MaskX(1))/(nxy(2)-1);%size of a mask pixel
                     sizpy=(ObjectData.MaskY(1)-ObjectData.MaskY(end))/(nxy(1)-1);
                     x_mask=[ObjectData.MaskX(1):sizpx:ObjectData.MaskX(end)]; % pixel x coordinates for image display 
                     y_mask=[ObjectData.MaskY(1):-sizpy:ObjectData.MaskY(end)];% pixel x coordinates for image display
                     %project on the positions of the scalar
                     npxy=size(ObjectData.A);
                     dxy(1)=(ObjectData.AY(end)-ObjectData.AY(1))/(npxy(1)-1);%grid mesh in y
                     dxy(2)=(ObjectData.AX(end)-ObjectData.AX(1))/(npxy(2)-1);%grid mesh in x
                     xi=[ObjectData.AX(1):dxy(2):ObjectData.AX(end)];
                     yi=[ObjectData.AY(1):dxy(1):ObjectData.AY(end)];      
                     [XI,YI]=meshgrid(xi,yi);% creates the matrix of regular coordinates
                    flag_mask = interp2(x_mask,y_mask,flag_mask,XI,YI);
                 end
                 AClass=class(ObjectData.A);
                 ObjectData.A=flag_mask.*double(ObjectData.A);
                 ObjectData.A=feval(AClass,ObjectData.A);
                 ind_off=[];
                 if isfield(ObjectData,'ListVarName')
                      for ilist=1:length(ObjectData.ListVarName)
                           if isequal(ObjectData.ListVarName{ilist},'Mask')|isequal(ObjectData.ListVarName{ilist},'MaskX')|isequal(ObjectData.ListVarName{ilist},'MaskY')
                               ind_off=[ind_off ilist];
                           end
                      end
                      ObjectData.ListVarName(ind_off)=[];
                      ObjectData.VarDimIndex(ind_off)=[];
                      ind_off=[];        
                      for ilist=1:length(ObjectData.ListDimName)       
                           if isequal(ObjectData.ListDimName{ilist},'MaskX')|isequal(ObjectData.ListDimName{ilist},'MaskY')
                               ind_off=[ind_off ilist];
                           end
                      end
                      ObjectData.ListDimName(ind_off)=[];
                      ObjectData.DimValue(ind_off)=[];
                 end
            end  
        end
        if ~isempty(ObjectData)
            haxes=[];%default
            if isfield(Object{iobj},'plotaxes')
                haxes=Object{iobj}.plotaxes;%axes used for representing the projection on the object
            end
            PosColorbar=[];%default: no colorbar
            if ishandle(haxes) & isequal(get(haxes,'Tag'),'axes3')& isfield(UvData,'PosColorbar')
                PosColorbar=UvData.PosColorbar;%prescribe the colorbar position on the view_field interface
            else
                PosColorbar='*';%default position
            end
            PlotParam=read_plot_param(handles);%read plotting parameters on the view_field interface
            [PlotType,ScalOut,UvData.Object{iobj}.plotaxes]=plot_field(ObjectData,haxes,PlotParam,keeplim,PosColorbar);
            if isequal(PlotType,'none')
                hget_field=findobj(allchild(0),'name','get_field');
                if isempty(hget_field)
                    get_field([],ObjectData)% the projected field cannot be automatically plotted: use get_field to specify the variablesdelete(hget_field)
                else
                    msgbox_view_field('ERROR','The field defined by get_field cannot be plotted')
                end 
            end  
            UvData.Object{iobj}.PlotParam=ScalOut; %record the plotting parameters
        end
        
    end
end

%display the updated plotting parameters for the base menuplane
write_plot_param(handles,UvData.Object{1}.PlotParam);% update the display of the plotting parameters
set(handles.view_field,'UserData',UvData)

%update the mask
if isequal(get(handles.mask_test,'Value'),1)%if the mask option is on
   update_mask(handles,num_i1,num_i2);
end

%prepare the menus of histograms (for the whole menuvolume in 3D case)
menu_histo=(UvData.Field.ListVarName)';
ind_bad=[];
nb_histo=1;
for ivar=1:numel(menu_histo)
    if isfield(UvData.Field,'VarAttribute') && numel(UvData.Field.VarAttribute)>=ivar && isfield(UvData.Field.VarAttribute{ivar},'Role')
        Role=UvData.Field.VarAttribute{ivar}.Role;
        switch Role
            case {'coord_x','coord_y','coord_z','dimvar'}
                ind_bad=[ind_bad ivar];
            case {'vector_y'}
                nb_histo=nb_histo+1;
        end
    end
    DimCell=UvData.Field.VarDimName{ivar};
    DimName='';
    if ischar(DimCell)
        DimName=DimCell;
    elseif iscell(DimCell)&& numel(DimCell)==1
        DimName=DimCell{1};
    end
    if strcmp(DimName,menu_histo{ivar})
        ind_bad=[ind_bad ivar];
    end
end
menu_histo(ind_bad)=[];
test_v=0;
if ~isempty(menu_histo)
    set(handles.histo1_menu,'Value',1)
    set(handles.histo1_menu,'String',menu_histo)
    histo1_menu_Callback(hObject, eventdata, handles)
    if nb_histo > 1
        test_v=1;
        set(handles.histo2_menu,'Visible','on')
        set(handles.histo_v,'Visible','on')
        set(handles.histo2_menu,'String',menu_histo)
        set(handles.histo2_menu,'Value',2)
        histo2_menu_Callback(hObject, eventdata, handles)
    end
end
if ~test_v
    set(handles.histo2_menu,'Visible','off')
    set(handles.histo_v,'Visible','off')
    cla(handles.histo_v)
    set(handles.histo2_menu,'Value',1)
end

%display time
testimedoc=0;
if isfield(UvData,'XmlData') && isfield(UvData.XmlData,'Time')
    if isempty(num_i2)
        num_i2=num_i1;
    end
    if isempty(num_j1)
        num_j1=1;
    end
    if isempty(num_j2)
        num_j2=num_j1;
    end
    siz=size(UvData.XmlData.Time);
    if siz(1)>=max(num_i1,num_i2) & siz(2)>=max(num_j1,num_j2)
        abstime=(UvData.XmlData.Time(num_i1,num_j1)+UvData.XmlData.Time(num_i2,num_j2))/2;%overset the time read from files
        dt=(UvData.XmlData.Time(num_i2,num_j2)-UvData.XmlData.Time(num_i1,num_j1));
        testimedoc=1;
    end
end
if isfield(UvData,'XmlData_1') && isfield(UvData.XmlData_1,'Time')
    [P,F,str1,str2,str_a,str_b,E,NomType]=name2display(['xx' get(handles.FileIndex_1,'String') get(handles.FileExt_1,'String')]);
    num_i2=str2num(str2);
    if isempty(num_i2)
        num_i2=num_i1;
    end
    num_j1=str2num(str_a);
    if isempty(num_j1)
        num_j1=1;
    end
    num_j2=str2num(str_b);
    if isempty(num_j2)
        num_j2=num_j1;
    end
    num_i1=str2num(str1);
    siz=size(UvData.XmlData_1.Time);
    if siz(1)>=max(num_i1,num_i2) & siz(2)>=max(num_j1,num_j2)
        abstime_1=(UvData.XmlData_1.Time(num_i1,num_j1)+UvData.XmlData_1.Time(num_i2,num_j2))/2;%overset the time read from files
    end
end
set(handles.abs_time,'String',num2str(abstime,4))
set(handles.abs_time_1,'String',num2str(abstime_1,4))
if testimedoc && isfield(UvData,'dt')
    dt=UvData.dt;
end 
if isequal(dt,0)
    set(handles.Dt_txt,'String','')
else
    if ~(isfield(UvData,'TimeUnit') && ~isempty(UvData.TimeUnit))
        set(handles.Dt_txt,'String',['Dt=' num2str(1000*dt,3) '  10^(-3)'] )
    else
        set(handles.Dt_txt,'String',['Dt=' num2str(1000*dt,3) '  m' UvData.TimeUnit] )
    end
end
set(handles.run0,'BackgroundColor',[1 0 0])



%-------------------------------------------------------------------
% --- translate coordinate to matrix index
%-------------------------------------------------------------------
function [indx,indy]=pos2ind(x0,rangx0,nxy)
indx=1+round((nxy(2)-1)*(x0-rangx0(1))/(rangx0(2)-rangx0(1)));% index x of pixel  
indy=1+round((nxy(1)-1)*(y12-rangy0(1))/(rangy0(2)-rangy0(1)));% index y of pixel

%-------------------------------------------------------------------
% --- Executes on button press in 'FixedLimits'.
%-------------------------------------------------------------------
function FixedLimits_Callback(hObject, eventdata, handles)
test=get(handles.FixedLimits,'Value');
if test
    set(handles.FixedLimits,'BackgroundColor',[1 1 0])
else
    set(handles.FixedLimits,'BackgroundColor',[0.7 0.7 0.7])
end

%-------------------------------------------------------------------
% --- Executes on button press in auto_xy.
function auto_xy_Callback(hObject, eventdata, handles)
test=get(handles.auto_xy,'Value');
if test
    set(handles.auto_xy,'BackgroundColor',[1 1 0])
    cla(handles.axes3)
    update_plot(handles)
else
    set(handles.auto_xy,'BackgroundColor',[0.7 0.7 0.7])
    update_plot(handles)
%     axis(handles.axes3,'image')
end


%-------------------------------------------------------------------

%-------------------------------------------------------------------
% --- Executes on button press in 'zoom'.
%-------------------------------------------------------------------
function zoom_Callback(hObject, eventdata, handles)
if (get(handles.zoom,'Value') == 1); 
    set(handles.zoom,'BackgroundColor',[1 1 0])
    set(handles.FixedLimits,'Value',1)% propose by default fixed limits for the plotting axes
    set(handles.FixedLimits,'BackgroundColor',[1 1 0])
else
    set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
end

%-------------------------------------------------------------------
%----Executes on button press in 'record': records the current flags of manual correction.
%-------------------------------------------------------------------
function record_Callback(hObject, eventdata, handles)
% [filebase,num_i1,num_j1,num_i2,num_j2,Ext,NomType,SubDir]=read_input_file(handles);
filename=read_file_boxes(handles);
AxeData=get(gca,'UserData');
[erread,message]=fileattrib(filename);
if ~isempty(message) && ~isequal(message.UserWrite,1)
     msgbox_view_field('ERROR',['no writting access to ' filename])
     return
end
test_civ2=isequal(get(handles.civ2,'BackgroundColor'),[1 1 0]);
test_civ1=isequal(get(handles.civ1,'BackgroundColor'),[1 1 0]);
if ~test_civ2 && ~test_civ1
    msgbox_view_field('ERROR','manual correction only possible for CIV1 or CIV2 velocity fields')
end 
if test_civ2
    nbname='nb_vectors2';
   flagname='vec2_FixFlag';
   attrname='fix2';
end
if test_civ1
    nbname='nb_vectors';
   flagname='vec_FixFlag';
   attrname='fix';
end
%write fix flags in the netcdf file
hhh=which('netcdf.open');% look for built-in matlab netcdf library
if ~isequal(hhh,'')% case of new builtin Matlab netcdf library
    nc=netcdf.open(filename,'NC_WRITE'); 
    netcdf.reDef(nc)
    netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),attrname,1)
    dimid = netcdf.inqDimID(nc,nbname); 
    try
        varid = netcdf.inqVarID(nc,flagname);% look for already existing fixflag variable
    catch
        varid=netcdf.defVar(nc,flagname,'double',dimid);%create fixflag variable if it does not exist
    end
    netcdf.endDef(nc)
    netcdf.putVar(nc,varid,AxeData.FF);
    netcdf.close(nc)  
else %old netcdf library
    netcdf_toolbox(filename,AxeData,attrname,nbname,flagname)
end

function netcdf_toolbox(filename,AxeData,attrname,nbname,flagname)
nc=netcdf(filename,'write'); %open netcdf file
result=redef(nc);
eval(['nc.' attrname '=1;']);
theDim=nc(nbname) ;% get the number of velocity vectors
nb_vectors=size(theDim);
var_FixFlag=ncvar(flagname,nc);% var_FixFlag will be written as the netcdf variable vec_FixFlag
var_FixFlag(1:nb_vectors)=AxeData.FF;% 
fin=close(nc);


%-------------------------------------------------------------------
%determines the fields to read from the interface
%------------------------------------------------------------------
function [VelType,civ]=setfield(handles)

VelType=[]; %default
if (get(handles.civ1,'Value') == 1);
        VelType='civ1';
% interp1   
elseif (get(handles.interp1,'Value') == 1);
    VelType='interp1';
% filter1   
elseif (get(handles.filter1,'Value') == 1); 
    VelType='filter1';  
% CIV2
elseif (get(handles.civ2,'Value') == 1);
    VelType='civ2';
% interp2   
elseif (get(handles.interp2,'Value') == 1); 
    VelType='interp2';
% filter2   
elseif (get(handles.filter2,'Value') == 1);  
    VelType='filter2'; 
end 

if isequal(get(handles.filter2,'Visible'),'on');
    civ=6;
% interp1   
elseif isequal(get(handles.interp2,'Visible'),'on');
    civ=5;
% filter1   
elseif isequal(get(handles.civ2,'Visible'),'on'); 
    civ=4;  
% CIV2
elseif isequal(get(handles.filter1,'Visible'),'on');
   civ=3;
% interp2   
elseif isequal(get(handles.interp1,'Visible'),'on'); 
    civ=2;
% filter2   
elseif isequal(get(handles.civ1,'Visible'),'on');  
    civ=1; 
else
    civ=0;
end 

%-------------------------------------------------------------------
%determines the veltype of the second field to read from the iinterface
%------------------------------------------------------------------
function VelType=setfield_1(handles)

VelType=[]; %default
if (get(handles.civ1_1,'Value') == 1);
    VelType='civ1';
% interp1   
elseif (get(handles.interp1_1,'Value') == 1);
    VelType='interp1';
% filter1   
elseif (get(handles.filter1_1,'Value') == 1); 
    VelType='filter1';  
% CIV2
elseif (get(handles.civ2_1,'Value') == 1);
    VelType='civ2';
% interp2   
elseif (get(handles.interp2_1,'Value') == 1); 
    VelType='interp2';
% filter2   
elseif (get(handles.filter2_1,'Value') == 1);  
    VelType='filter2'; 
end 


%---------------------------------------------------
% --- Executes on button press in SubField
function SubField_Callback(hObject, eventdata, handles)
huvmat=get(handles.run0,'parent');
UvData=get(huvmat,'UserData');
if get(handles.SubField,'Value')==0% if the subfield button is desactivated   
    set(handles.RootPath_1,'String','')
    set(handles.RootFile_1,'String','')
    set(handles.SubDir_1,'String','');
    set(handles.FileIndex_1,'String','');
    set(handles.FileExt_1,'String','');
    set(handles.RootPath_1,'Visible','off')
    set(handles.RootFile_1,'Visible','off')
    set(handles.SubDir_1,'Visible','off');
    set(handles.FileIndex_1,'Visible','off');
    set(handles.FileExt_1,'Visible','off');
    set(handles.Fields_1,'Value',1);%set to blank state
    set_veltype_display([handles.civ1_1 handles.interp1_1 handles.filter1_1 ...
            handles.civ2_1 handles.interp2_1 handles.filter2_1],0)
    if isfield(UvData,'XmlData_1')
        UvData=rmfield(UvData,'XmlData_1');
    end 
    set(huvmat,'UserData',UvData);
    run0_Callback(hObject, eventdata, handles); %run
else
    MenuBrowse_1_Callback(hObject, eventdata, handles)
end

% %----------------------------------------------
% %read the data displayed for the input rootfile windows (new)
% %-------------------------------------------------
function [FileName,RootPath,FileBase,FileIndices,FileExt,SubDir]=read_file_boxes(handles)
RootPath=get(handles.RootPath,'String');
FileName=RootPath; %default
SubDir=get(handles.SubDir,'String');
if ~isempty(SubDir) && ~isequal(SubDir,'')
    if (isequal(SubDir(1),'/')|| isequal(SubDir(1),'\'))
        SubDir(1)=[]; %suppress possible / or \ separator
    end
    FileName=fullfile(RootPath,SubDir);
end
RootFile=get(handles.RootFile,'String');
if ~isempty(RootFile) && ~isequal(RootFile,'')
    if (isequal(RootFile(1),'/')|| isequal(RootFile(1),'\'))
        RootFile(1)=[]; %suppress possible / or \ separator
    end
    FileName=fullfile(FileName,RootFile);
end
FileBase=fullfile(RootPath,RootFile);
FileIndices=get(handles.FileIndex,'String');
FileExt=get(handles.FileExt,'String');
FileName=[FileName FileIndices FileExt];

%----------------------------------------------
%read the data displayed for the second input rootfile windows
%-------------------------------------------------
function [FileName_1,RootPath_1,FileBase_1,FileIndices_1,FileExt_1,SubDir_1]=read_file_boxes_1(handles)
RootPath_1=get(handles.RootPath_1,'String'); % read the data from the file1_input window
if isequal(RootPath_1,'"'),RootPath_1=get(handles.RootPath,'String'); end;
FileName_1=RootPath_1; %default
SubDir_1=get(handles.SubDir_1,'String');
if isequal(SubDir_1,'"')
    SubDir_1=get(handles.SubDir,'String');
end
if ~isempty(SubDir_1) && ~isequal(SubDir_1,'')
    if (isequal(SubDir_1(1),'/')|| isequal(SubDir_1(1),'\'))
        SubDir_1(1)=[]; %suppress possible / or \ separator
    end
    FileName_1=fullfile(RootPath_1,SubDir_1);
end
RootFile_1=get(handles.RootFile_1,'String');
if isequal(RootFile_1,'"'),RootFile_1=get(handles.RootFile,'String'); end;
if ~isempty(RootFile_1) && ~isequal(RootFile_1,'')
    if ~(isequal(RootFile_1(1),'/')|isequal(RootFile_1(1),'\'))
        RootFile_1(1)=[];%suppress possible / or \ separator
    end
    FileName_1=fullfile(FileName_1,RootFile_1);
end
FileBase_1=fullfile(RootPath_1,RootFile_1);
FileIndices_1=get(handles.FileIndex_1,'String');
FileExt_1=get(handles.FileExt_1,'String');
if isequal(FileExt_1,'"'),FileExt_1=get(handles.FileExt,'String'); end;
FileName_1=[FileName_1 FileIndices_1 FileExt_1];

%---------------------------------------------------
% --- Executes on menu selection Fields
function Fields_Callback(hObject, eventdata, handles)
%-------------------------------------------------
huvmat=get(handles.Fields,'parent');
list_fields=get(handles.Fields,'String');% list menu fields
index_fields=get(handles.Fields,'Value');% selected string index
field= list_fields{index_fields(1)}; % selected string
if isequal(field,'get_field...')
     veltype_handles=[handles.civ1 handles.interp1 handles.filter1 handles.civ2 handles.interp2 handles.filter2];
     set_veltype_display(veltype_handles,0) % unvisible civ buttons
     filename=read_file_boxes(handles);
     hget_field=findobj(allchild(0),'name','get_field');
     if ~isempty(hget_field)
         delete(hget_field)
     end
     get_field(filename)
    return %no action
end
list_fields=get(handles.Fields_1,'String');% list menu fields
index_fields=get(handles.Fields_1,'Value');% selected string index
field_1= list_fields{index_fields(1)}; % selected string
UvData=get(huvmat,'UserData');

%read the rootfile input display
FileExt=get(handles.FileExt,'String');
[P,F,str1,str2,str_a,str_b,E,NomType]=name2display(['xxx' get(handles.FileIndex,'String') FileExt]);
NomTypeNew=NomType;%default
if isequal(field,'image') 
    % transform netc type to the corresponding image type
    if isequal(NomType,'_i1-i2_j')||isequal(NomType,'_i_j1-j2')|| isequal(NomType,'#_ab')|| isequal(NomType,'_i1-i2')
        UvData.SubDir=get(handles.SubDir,'String'); %preserve the subdir in memory
        if ~isempty(UvData.SubDir) && (isequal(UvData.SubDir(1),'/')||isequal(UvData.SubDir(1),'/'))
            UvData.SubDir(1)=[];
        end
        set(handles.SubDir,'String','')
        set(handles.FileExt,'String','.png');
        if isequal(NomType,'_i1-i2_j')||isequal(NomType,'_i_j1-j2')
            NomTypeNew='_i_j';
        elseif isequal(NomType,'#_ab')
            NomTypeNew='#a';
        elseif isequal(NomType,'_i1-i2')
            NomTypeNew='_i';
        end  
    end
    veltype_handles=[handles.civ1 handles.interp1 handles.filter1 handles.civ2 handles.interp2 handles.filter2];
    set_veltype_display(veltype_handles,0) % unvisible civ buttons
else
    ext=get(handles.FileExt,'String');
    if ~isequal(ext,'.nc') %find the new NomType if the previous display was not already a netcdf file
         MenuBrowse_Callback(hObject, eventdata, handles)
    end
    if isequal(field,'vort') || isequal(field,'div') || isequal(field,'strain')
        set(handles.civ1,'BackgroundColor',[0.702 0.702 0.702]) % put their color to grey
        set(handles.civ2,'BackgroundColor',[0.702 0.702 0.702])
        set(handles.interp1,'BackgroundColor',[0.702 0.702 0.702])
        set(handles.interp2,'BackgroundColor',[0.702 0.702 0.702])
    elseif isequal(field,'more...'); 
        set(handles.civ1,'BackgroundColor',[0.702 0.702 0.702]) % put their color to grey
        set(handles.civ2,'BackgroundColor',[0.702 0.702 0.702])
        str=calc_field;%get the list of available scalars by the function calc_scal
        [ind_answer] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',str);
       % edit the choice in the field and action menu
        scalar=cell2mat(str(ind_answer));
        menu=update_menu(handles.Fields,scalar);
        menu=[{''};menu];
        set(handles.Fields_1,'String',menu);% store the selected scalar type
    end
end
indices=name_generator('',str2double(str1),str2double(str_a),'',NomTypeNew,1,str2double(str2),str2double(str_b),'');
set(handles.FileIndex,'String',indices)
set(handles.FileIndex,'UserData',NomTypeNew)
%common to Fields_1_Callback
if isequal(field,'image')||isequal(field_1,'image')
    set(handles.npx_title,'Visible','on')% visible npx,pxcm... buttons
    set(handles.npy_title,'Visible','on')
    set(handles.npx,'Visible','on')
    set(handles.npy,'Visible','on')
    set(handles.fix_pair,'Value',0)
else
    set(handles.npx_title,'Visible','off')% visible npx,pxcm... buttons
    set(handles.npy_title,'Visible','off')
    set(handles.npx,'Visible','off')
    set(handles.npy,'Visible','off')
    set(handles.fix_pair,'Value',1)
end
% if isequal(field,'velocity')|isequal(field_1,'velocity');
%     state_vect='on';
% else
%     state_vect='off';
% end 
% if ~isequal(field,'velocity')|(~isequal(field_1,'velocity'));
%     state_scal='on';
% else
%     state_scal='off';
% end 
setfield(handles);% update the field structure ('civ1'....)

if ~isfield(UvData,'NewSeries')||isequal(UvData.NewSeries,0)
    run0_Callback(hObject, eventdata, handles)
end

%---------------------------------------------------
% --- Executes on menu selection Fields
function Fields_1_Callback(hObject, eventdata, handles)
%-------------------------------------------------
huvmat=get(handles.Fields_1,'parent');
list_fields=get(handles.Fields,'String');% list menu fields
index_fields=get(handles.Fields,'Value');% selected string index
field= list_fields{index_fields(1)}; % selected string
list_fields=get(handles.Fields_1,'String');% list menu fields
index_fields=get(handles.Fields_1,'Value');% selected string index
field_1= list_fields{index_fields(1)}; % selected string for the second field
if isequal(field_1,'') %remove second field if 'blank' field is selected
    set(handles.SubField,'Value',0)
    SubField_Callback(hObject, eventdata, handles)
    return
end
UvData=get(huvmat,'UserData');

%read the rootfile input display
FileExt_prev=get(handles.FileExt_1,'String');
if isempty(FileExt_prev)|isequal(FileExt_prev,'')
    FileExt_1=get(handles.FileExt,'String');
else
    FileExt_1=FileExt_prev;
end
NomType_1=get(handles.FileIndex_1,'UserData');
if isempty(NomType_1)|isequal(NomType_1,'')
    NomType_1=get(handles.FileIndex,'UserData');
end
NomTypeNew=NomType_1;%default

set(handles.SubField,'Value',1)%introduce second field
if isfield(UvData,'XmlData')
    UvData.XmlData_1=UvData.XmlData;
end
set(handles.FileIndex_1,'Visible','on')
set(handles.FileExt_1,'Visible','on')
RootPath_1=get(handles.RootPath_1,'String');
RootFile_1=get(handles.RootFile_1,'String');
if isempty(RootPath_1)|isequal(RootPath_1,'')
    set(handles.RootPath_1,'String','"')
end
if isempty(RootFile_1) | isequal(RootFile_1,'')
    set(handles.RootFile_1,'String','"')
end
if ~isempty(RootFile_1)&(isequal(RootFile_1(1),'/')|isequal(RootFile_1(1),'\'))
    RootFile_1(1)=[];
end

if isequal(field_1,'get_field...')
     veltype_handles=[handles.civ1 handles.interp1 handles.filter1 handles.civ2 handles.interp2 handles.filter2];
     set_veltype_display(veltype_handles,0) % unvisible civ buttons
     filename=read_file_boxes_1(handles);
     hget_field=findobj(allchild(0),'name','get_field_1');
     if ~isempty(hget_field)
         delete(hget_field)
     end
     hget_field=get_field(filename);
     set(hget_field,'name','get_field_1')
    return %no action
end
if isequal(field_1,'image') 
    % transform netc type to the corresponding image type
    set(handles.FileExt_1,'String','.png');
    if isequal(NomType_1,'_i1-i2_j')|isequal(NomType_1,'_i_j1-j2')| isequal(NomType_1,'#_ab')| isequal(NomType_1,'_i1-i2')
        UvData.SubDir_1=get(handles.SubDir_1,'String'); %preserve the subdir in memory
        set(handles.SubDir_1,'String','')
%         set(handles.FileExt_1,'String','.png');        
        if isequal(NomType_1,'_i1-i2_j')|isequal(NomType_1,'_i_j1-j2')
            NomTypeNew='_i_j';
        elseif isequal(NomType_1,'#_ab')
            NomTypeNew='#a';
        elseif isequal(NomType_1,'_i1-i2')
            NomTypeNew='_i';
        end  
    end
    veltype_handles=[handles.civ1_1 handles.interp1_1 handles.filter1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1];
    set_veltype_display(veltype_handles,0) % unvisible civ buttons
else
    set(handles.SubDir_1,'Visible','on')
    if ~isequal(FileExt_prev,'.nc') %find the new NomType if the previous display was not already a netcdf file
        veltype_handles=[handles.civ1_1 handles.interp1_1 handles.filter1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1];
        set_veltype_display(veltype_handles,6); % make all civ buttons visible
        RootPath_1=get(handles.RootPath_1,'String');
        RootFile_1=get(handles.RootFile_1,'String');
        if isempty(RootPath_1)|isequal(RootPath_1,'')
            set(handles.RootPath_1,'String','"')
        end
        if isempty(RootFile_1) | isequal(RootFile_1,'')
            set(handles.RootFile_1,'String','"')
        end
        if ~isempty(RootFile_1)&(isequal(RootFile_1(1),'/')|isequal(RootFile_1(1),'\'))
            RootFile_1(1)=[];
        end
        filebase_1=fullfile(RootPath_1,RootFile_1);
        SubDir_1=get(handles.SubDir,'String');
        if isempty(SubDir_1)|isequal(SubDir_1,'')
            if isfield(UvData,'SubDir_1')
                SubDir_1=UvData.SubDir_1;%retrieve previous subdir
            else
                SubDir_1='?';
            end
        end
        if isequal(NomType_1,'#_ab')|isequal(NomType_1,'_i1-i2_j')|isequal(NomType_1,'_i_j1-j2')|isequal(NomType_1,'_i1-i2')
            NomTypeNew=NomType_1;
        elseif isequal(NomType_1,'#a')
             [filename,idetect,n1,na,n2,nb,SubDir_1]=name_generator(filebase_1, str2num(str1),str2num(str_a),'.nc','#_ab',0,[],[],SubDir_1);
             NomTypeNew='#_ab';
        elseif isequal(NomType_1,'_i_j')
             [filename,idetect,n1,na,n2,nb,SubDir_1]=name_generator(filebase_1,str2num(str1),str2num(str_a),'.nc','_i1-i2_j',0,str2num(str1),[],SubDir_1);
            if idetect==1
                NomTypeNew='_i1-i2_j';
            else
                NomTypeNew='_i_j1-j2';
            end
        else %for instance avi files or any ima_num series
            [filename,idetect,n1,na,n2,nb,SubDir_1]=name_generator(filebase_1,str2num(str1),str2num(str_a),'.nc','_i1-i2',0,str2num(str1),[],SubDir_1);
            NomTypeNew='_i1-i2';
        end            
        [Path,Name]=fileparts(filebase_1);
        set(handles.FileExt_1,'String','.nc');
        if ~isempty(SubDir_1) & ~isequal(SubDir_1,'''')& ~isequal(SubDir_1,'"')
            SubDir_1=['/' SubDir_1];
        end
        set(handles.SubDir_1,'String',SubDir_1);
    end
    if isequal(field,'vort') | isequal(field,'div') | isequal(field,'strain')
        set(handles.civ1_1,'BackgroundColor',[0.702 0.702 0.702]) % put their color to grey
        set(handles.civ2_1,'BackgroundColor',[0.702 0.702 0.702])
        set(handles.interp1_1,'BackgroundColor',[0.702 0.702 0.702])
        set(handles.interp2_1,'BackgroundColor',[0.702 0.702 0.702])
    elseif isequal(field_1,'more...'); %add new item to the menu
        set(handles.civ1_1,'BackgroundColor',[0.702 0.702 0.702]) % put their color to grey
        set(handles.civ2_1,'BackgroundColor',[0.702 0.702 0.702])
        str=calc_field;%get the list of available scalars by the function calc_scal
        [ind_answer,v] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',str);
       % edit the choice in the field and action menu
        scalar=cell2mat(str(ind_answer));
        menu=update_menu(handles.Fields_1,scalar);
        set(handles.Fields_1,'String',menu);% store the selected scalar type
    end
end
str1=get(handles.i1,'String');
str2=get(handles.i2,'String');
str_a=get(handles.j1,'String');
str_b=get(handles.j2,'String');
indices=name_generator('',str2num(str1),stra2num(str_a),'',NomTypeNew,1,str2num(str2),stra2num(str_b),'');
set(handles.FileIndex_1,'String',indices)
set(handles.FileIndex_1,'UserData',NomTypeNew)

%common to Fields_Callback
if isequal(field,'image')|isequal(field_1,'image')
    set(handles.npx_title,'Visible','on')% visible npx,pxcm... buttons
    set(handles.npy_title,'Visible','on')
    set(handles.npx,'Visible','on')
    set(handles.npy,'Visible','on')
    set(handles.fix_pair,'Value',0)
else
    set(handles.npx_title,'Visible','off')% visible npx,pxcm... buttons
    set(handles.npy_title,'Visible','off')
    set(handles.npx,'Visible','off')
    set(handles.npy,'Visible','off')
    set(handles.fix_pair,'Value',1)
end
if isequal(field,'velocity')|isequal(field_1,'velocity');
    state_vect='on';
else
    state_vect='off';
end 
if ~isequal(field,'velocity')|(~isequal(field_1,'velocity')&~isequal(field_1,''));
    state_scal='on';
else
    state_scal='off';
end 
set(huvmat,'UserData',UvData)
setfield(handles);% update the field structure ('civ1'....)
if ~isfield(UvData,'NewSeries')|isequal(UvData.NewSeries,0)
    run0_Callback(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% --- set the visibility of relevant velocity type menus: 
function set_veltype_display(handles,Civ)
%------------------------------------------------------------------------
%Civ=0; all states 'off'
%Civ=6; all states 'on'
if isequal(Civ,0)
    imax=0;
%    set(handles(1),'Visible','on')  % unvisible civ buttons
% else
%    set(handles(1),'String','civ1') 
% end
elseif isequal(Civ,1) || isequal(Civ,2)
   imax=1;
elseif isequal(Civ,3) 
    imax=3;
elseif isequal(Civ,4) || isequal(Civ,5)
    imax=4;
elseif isequal(Civ,6) %patch2
    imax=6;
end
for ibutton=1:imax;
    set(handles(ibutton),'Visible','on')  % unvisible civ buttons
end
% for ibutton=max(imax+1,2):6;
for ibutton=imax+1:6;
    set(handles(ibutton),'Visible','off')  % unvisible civ buttons
    set(handles(ibutton),'Value',0)%unactivate unvisible buttons
end

%-------------------------------------------------------------------
% --- Executes on button press in civ1.
function civ1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.civ1,'Value')==1
    reset_vel_type([handles.interp1 handles.civ2 handles.filter1 handles.interp1 handles.interp2 handles.filter2],handles.civ1)
else
    reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------
% --- Executes on button press in interp1.
function interp1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.interp1,'Value')==1
    reset_vel_type([handles.civ1 handles.civ2 handles.filter1 handles.interp2 handles.filter2],handles.interp1)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------
% --- Executes on button press in filter1.
function filter1_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.filter1,'Value')==1
    reset_vel_type([handles.civ1 handles.civ2 handles.interp1 handles.interp2 handles.filter2],handles.filter1)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------
% --- Executes on button press in civ2.
function civ2_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.civ2,'Value')==1
    reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.interp2 handles.filter2],handles.civ2)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%-----------------------------------------
% --- Executes on button press in interp2.
%-------------------------------------------
function interp2_Callback(hObject, eventdata, handles)
if get(handles.interp2,'Value')==1
    reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.filter2],handles.interp2)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)
%---------------------------------------------
% --- Executes on button press in filter2.
%-------------------------------------------
function filter2_Callback(hObject, eventdata, handles)
if get(handles.filter2,'Value')==1
    reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2],handles.filter2)
else
     reset_vel_type([handles.civ1 handles.filter1 handles.interp1 handles.civ2 handles.interp2 handles.filter2])
end
run0_Callback(hObject, eventdata, handles)

%---------------------------------------------
function civ1_1_Callback(hObject, eventdata, handles)
%---------------------------------------------
if get(handles.civ1_1,'Value')==1
    reset_vel_type([handles.interp1_1 handles.civ2_1 handles.filter1_1 handles.interp1_1 handles.interp2_1 handles.filter2_1],handles.civ1_1)
else
     reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function interp1_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.interp1_1,'Value')==1
    reset_vel_type([handles.civ1_1 handles.civ2_1 handles.filter1_1 handles.interp2_1 handles.filter2_1],handles.interp1_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function filter1_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.filter1_1,'Value')==1
    reset_vel_type([handles.interp1_1 handles.civ2_1 handles.interp1_1 handles.interp2_1 handles.filter2_1],handles.filter1_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function civ2_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.civ2_1,'Value')==1
    reset_vel_type([handles.civ1_1 handles.interp1_1  handles.filter1_1 handles.interp2_1 handles.filter2_1],handles.civ2_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function interp2_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.interp2_1,'Value')==1
    reset_vel_type([handles.civ1_1 handles.civ2_1 handles.filter1_1 handles.interp1_1 handles.filter2_1],handles.interp2_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function filter2_1_Callback(hObject, eventdata, handles)
%--------------------------------------------
if get(handles.filter2_1,'Value')==1
    reset_vel_type([handles.civ1_1 handles.interp1_1 handles.civ2_1 handles.filter1_1 handles.interp1_1 handles.interp2_1],handles.filter2_1)
else
    reset_vel_type([handles.civ1_1 handles.filter1_1 handles.interp1_1 handles.civ2_1 handles.interp2_1 handles.filter2_1])
end
run0_Callback(hObject, eventdata, handles)

%-----------------------------------------------
% --- reset civ buttons
function reset_vel_type(handles_civ0,handle1)
for ibutton=1:length(handles_civ0)
    set(handles_civ0(ibutton),'BackgroundColor',[0.831 0.816 0.784])
    set(handles_civ0(ibutton),'Value',0)
end
if exist('handle1','var')%handles of selected button
	set(handle1,'BackgroundColor',[1 1 0])  
end

%------------------------------------------------
function create_Callback(hObject,eventdata,handles)
%------------------------------------------------
if ishandle(handles.VIEW_FIELD_title)
    delete(handles.VIEW_FIELD_title)
end
huvmat=get(handles.create,'parent');
UvData=get(huvmat,'UserData');%read UvData properties stored on the view_field interface (handles huvmat)
if isequal(get(handles.create,'Value'),1)
    set(handles.zoom,'Value',0)
    zoom_Callback(hObject, eventdata, handles)
     set(handles.create,'BackgroundColor',[1 1 0]) %visualise in yellow
    set(handles.edit_vect,'Value',0)  
    edit_vect_Callback(hObject, eventdata, handles)
    set(handles.edit,'Value',0)
    set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
    list_object=get(handles.list_object,'String');
    if ~isempty(list_object)
        set(handles.list_object,'Value',length(list_object))
    end
    MouseAction='create_object';
    hset_object=findobj(allchild(0),'Name','set_object');
    uistack(hset_object,'top')
else
    set(handles.create,'BackgroundColor',[0 1 0])
    set(handles.edit,'Value',1)
    set(handles.edit,'BackgroundColor',[1 1 0])
    MouseAction='none';
end

UvData.MouseAction=MouseAction;
set(huvmat,'UserData',UvData);

%------------------------------------------------
function POINTS_Callback(hObject,eventdata,handles)
%------------------------------------------------
if ishandle(handles.VIEW_FIELD_title)
    delete(handles.VIEW_FIELD_title)
end
huvmat=get(handles.create,'parent');
UvData=get(huvmat,'UserData');%read UvData properties stored on the view_field interface (handles huvmat)
if isequal(get(handles.create,'Value'),1)
    set(handles.zoom,'Value',0)
    zoom_Callback(hObject, eventdata, handles)
    set(handles.edit_vect,'Value',0)  
    edit_vect_Callback(hObject, eventdata, handles)
    set(handles.edit,'Value',0)
    set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
    %set(handles.grid,'Value',0)
    %set(handles.grid,'BackgroundColor',[0 1 0])
    % initiate set_object GUI
     data.TITLE='POINTS';
    if isfield(UvData,'CoordType')
        data.CoordType=UvData.CoordType;
    end
    if isfield(UvData,'Mesh')&~isempty(UvData.Mesh)
        data.RangeY=UvData.Mesh;
    elseif isfield(UvData,'AX')&isfield(UvData,'AY')& isfield(UvData,'A')%only image
        np=size(UvData.Field.A);
        meshx=(UvData.Field.AX(end)-UvData.Field.AX(1))/np(2);
        meshy=abs(UvData.Field.AY(end)-UvData.Field.AY(1))/np(1);
        data.RangeY=max(meshx,meshy);
        data.DX=max(meshx,meshy);
    end
    data.Coord=[0 0 0]; %default
    data.ParentButton=handles.create;
    PlotHandles=get_plot_handles(handles);%get the handles of the graphic objects setting the plotting parameters
    [hset_object,UvData.sethandles]=set_object(data,PlotHandles);% call the set_object interface
    if isfield(UvData,'SetObjectOrigin')
    pos_view_field=get(huvmat,'Position');
    pos_set_object(1:2)=UvData.SetObjectOrigin + pos_view_field(1:2);
    pos_set_object(3:4)=UvData.SetObjectSize .* pos_view_field(3:4);
    set(hset_object,'Position',pos_set_object)
    end
    %set(hset_object,'Position',[pos_view_field(1) pos_view_field(2)-0.05*pos_view_field(4) 0.2*pos_view_field(3)  0.5*pos_view_field(4)]);
    list_object=get(handles.list_object,'String');
    if ~isempty(list_object)
        set(handles.list_object,'Value',length(list_object))
    end
    MouseAction='create_object';
    %UvData.ZoomOn=0;
else
    set(handles.create,'BackgroundColor',[0 1 0])
    set(handles.edit,'Value',1)
    set(handles.edit,'BackgroundColor',[1 1 0])
    MouseAction='none';
end

UvData.MouseAction=MouseAction;
set(huvmat,'UserData',UvData);

%-----------------------------------------------------------
function LINE_Callback(hObject, eventdata, handles)
%-------------------------------------------------
if ishandle(handles.VIEW_FIELD_title)
    delete(handles.VIEW_FIELD_title)
end
% handles.view_field
huvmat=get(handles.create,'parent');
UvData=get(huvmat,'UserData');%read UvData properties stored on the view_field interface
set(handles.zoom,'Value',0)
zoom_Callback(hObject, eventdata, handles)
set(handles.edit_vect,'BackgroundColor',[0.7 0.7 0.7])
set(handles.edit_vect,'Value',0)
edit_vect_Callback(hObject, eventdata, handles)
set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
set(handles.edit,'Value',0)
set(handles.list_object,'Value',1);
edit_vect_Callback(hObject, eventdata, handles)
set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
set(handles.cal,'Value',0)
set(handles.cal,'BackgroundColor',[0 1 0])
%  initiate the set_object GUI
data.TITLE='LINE';
if isfield(UvData,'CoordType')
    data.CoordType=UvData.CoordType;
end
if isfield(UvData,'Mesh')&~isempty(UvData.Mesh)
    data.RangeX=UvData.Mesh;
    data.RangeY=UvData.Mesh;
    data.DX=UvData.Mesh;
    data.DY=UvData.Mesh;
elseif isfield(UvData.Field,'AX')&isfield(UvData.Field,'AY')& isfield(UvData.Field,'A')%only image
    np=size(UvData.Field.A);
    meshx=(UvData.Field.AX(end)-UvData.Field.AX(1))/np(2);
    meshy=abs(UvData.Field.AY(end)-UvData.Field.AY(1))/np(1);
    data.RangeY=max(meshx,meshy);
    data.RangeX=max(meshx,meshy);
    data.DX=max(meshx,meshy);
end 
if isfield(data,'DX')
    data.Coord=[[0 0 0];[data.DX 0 0]]; %default 
else
    data.Coord=[[0 0 0];[1 0 0]]; %default 
end
data.ParentButton=handles.create;
PlotHandles=get_plot_handles(handles);%get the handles of the interface elements setting the plotting parameters
[hset_object,UvData.sethandles]=set_object(data,PlotHandles);% call the set_object interface with action on haxes,
                                                  % associate the set_edit interface handle to the plotting axes
pos_view_field=get(huvmat,'Position');
if isfield(UvData,'SetObjectOrigin')
    pos_set_object(1:2)=UvData.SetObjectOrigin + pos_view_field(1:2);
    pos_set_object(3:4)=UvData.SetObjectSize .* pos_view_field(3:4);  
    set(hset_object,'Position',pos_set_object)
end
list_object=get(handles.list_object,'String');
if ~isempty(list_object)
    set(handles.list_object,'Value',length(list_object))
end
MouseAction='create_object';
UvData.MouseAction=MouseAction;
set(huvmat,'UserData',UvData)

%-----------------------------------------------------------
function PATCH_Callback(hObject, eventdata, handles)
%-----------------------------------------------------------
if ishandle(handles.VIEW_FIELD_title)
    delete(handles.VIEW_FIELD_title)
end
huvmat=get(handles.create,'parent');
UvData=get(huvmat,'UserData');%read UvData properties stored on the view_field interface 
% if isequal(get(handles.PATCH,'Value'),1)
    set(handles.zoom,'Value',0)
    set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
%     set(handles.create,'Value',0)%suppress the other options if LINE is chosen
%     set(handles.create,'BackgroundColor',[0 1 0])
%     set(handles.LINE,'Value',0)
%     set(handles.LINE,'BackgroundColor',[0 1 0])
%     set(handles.PATCH,'Value',1)
%     set(handles.PATCH,'BackgroundColor',[1 1 0])
%     set(handles.PLANE,'Value',0)
%     set(handles.PLANE,'BackgroundColor',[0 1 0])%put activated buttons to yellow
%     set(handles.VOLUME,'Value',0)
%     set(handles.VOLUME,'BackgroundColor',[0 1 0])
    %set(handles.makemask,'Value',0)
    %makemask_Callback(hObject, eventdata, handles)
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)
    set(handles.edit,'Value',0)
    set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
    set(handles.edit_vect,'Value',0)  
    edit_vect_Callback(hObject, eventdata, handles)
    set(handles.cal,'Value',0)
    set(handles.cal,'BackgroundColor',[0 1 0])
    %set(handles.grid,'Value',0)
    %set(handles.grid,'BackgroundColor',[0 1 0])
    %initiate set_object GUI
    data.TITLE='PATCH';
    if isfield(UvData,'CoordType')
        data.CoordType=UvData.CoordType;
    end
    if isfield(UvData,'Mesh')&~isempty(UvData.Mesh)
        data.YMax=UvData.Mesh;
    elseif isfield(UvData.Field,'AX')&isfield(UvData.Field,'AY')& isfield(UvData.Field,'A')%only image
        np=size(UvData.Field.A);
        meshx=(UvData.Field.AX(end)-UvData.Field.AX(1))/(np(2)-1);
        meshy=abs(UvData.Field.AY(end)-UvData.Field.AY(1))/(np(1)-1);
        data.YMax=max(meshx,meshy);
        data.DX=max(meshx,meshy);
    end
    data.Coord=[0 0 0]; %default
    data.ParentButton=handles.create;
    PlotHandles=get_plot_handles(handles);%get the handles of the graphic objects setting the plotting parameters
    [hset_object,UvData.sethandles]=set_object(data,PlotHandles);% call the set_object interface
    pos_view_field=get(huvmat,'Position');
    if isfield(UvData,'SetObjectOrigin')
        pos_set_object(1:2)=UvData.SetObjectOrigin + pos_view_field(1:2);
        pos_set_object(3:4)=UvData.SetObjectSize .* pos_view_field(3:4); 
        set(hset_object,'Position',pos_set_object)
    end
    list_object=get(handles.list_object,'String');
    if ~isempty(list_object)
        set(handles.list_object,'Value',length(list_object))
    end
    UvData.MouseAction='create_object';
    set(huvmat,'UserData',UvData);
%-------------------------------------------------------
function PLANE_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
if ishandle(handles.VIEW_FIELD_title)
    delete(handles.VIEW_FIELD_title)
end
huvmat=get(handles.create,'parent');
UvData=get(huvmat,'UserData');%read UvData properties stored on the view_field interface 
set(handles.zoom,'Value',0)
set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
set(handles.edit_vect,'Value',0)
edit_vect_Callback(hObject, eventdata, handles)
set(handles.edit,'Value',0)
set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
set(handles.cal,'Value',0)
set(handles.cal,'BackgroundColor',[0 1 0])
%set(handles.grid,'Value',0)
%set(handles.grid,'BackgroundColor',[0 1 0])
%initiate set_object GUI
data.TITLE='PLANE';
if isfield(UvData,'CoordType')
    data.CoordType=UvData.CoordType;
end
%Si 3D data.nbdim=3;
%Si 2D 
if isfield(UvData,'Mesh')&~isempty(UvData.Mesh)
    data.ZMax=UvData.Mesh;
    data.DX=UvData.Mesh;
    data.DY=UvData.Mesh;
elseif isfield(UvData.Field,'AX')&isfield(UvData.Field,'AY')& isfield(UvData.Field,'A')%only image
    np=size(UvData.Field.A);
    meshx=(UvData.Field.AX(end)-UvData.Field.AX(1))/(np(2)-1);
    meshy=abs(UvData.Field.AY(end)-UvData.Field.AY(1))/(np(1)-1);
    data.DX=max(meshx,meshy);
end
if isfield(UvData,'DX')
    data.DX=UvData.DX;
end
if isfield(UvData,'DY')
    data.DY=UvData.DY;
elseif isfield(UvData,'Mesh')
    data.DY=UvData.Mesh;
end
if isfield(UvData.Field,'X')& isfield(UvData.Field,'Y')
    data.Coord=[0 0 0];
    data.Style='plane';
    data.Phi=0;
    data.IndexObj=1; %act on the first reference plane by default
    haxes= handles.axes3;%GENERALISER
    plot_object(data,[],haxes,'m'); %plot the axes of the default plane  
end
data.ParentButton=handles.create;
PlotHandles=get_plot_handles(handles);%get the handles of the graphic objects setting the plotting parameters
ZBounds=0; % default
if isfield(UvData,'ZMin') && isfield(UvData,'ZMax')
    ZBounds(1)=UvData.ZMin; %minimum for the Z slider
    ZBounds(2)=UvData.ZMax;%maximum for the Z slider
end
[hset_object,UvData.sethandles]=set_object(data,PlotHandles,ZBounds);% call the set_object interface with action on haxes,
if isfield(UvData,'SetObjectOrigin')
pos_view_field=get(huvmat,'Position');
pos_set_object(1:2)=UvData.SetObjectOrigin + pos_view_field(1:2);
pos_set_object(3:4)=UvData.SetObjectSize .* pos_view_field(3:4);  
set(hset_object,'Position',pos_set_object)
end
list_object=get(handles.list_object,'String');
nbobject=length(list_object);
set(handles.list_object,'Value',nbobject)
UvData.MouseAction='create_object';
set(huvmat,'UserData',UvData)

%-------------------------------------------------------
% --- Executes on button press in MENUVOLUME.
%-------------------------------------------------------
function VOLUME_Callback(hObject, eventdata, handles)
%errordlg('command VOL not implemented yet')
if ishandle(handles.VIEW_FIELD_title)
    delete(handles.VIEW_FIELD_title)
end
huvmat=get(handles.create,'parent');
UvData=get(huvmat,'UserData');%read UvData properties stored on the view_field interface 
if isequal(get(handles.VOLUME,'Value'),1)
    set(handles.zoom,'Value',0)
    set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)
    set(handles.edit,'Value',0)
    set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
    set(handles.cal,'Value',0)
    set(handles.cal,'BackgroundColor',[0 1 0])
    set(handles.edit_vect,'Value',0)
    edit_vect_Callback(hObject, eventdata, handles)
    %initiate set_object GUI
    data.TITLE='VOLUME';
    if isfield(UvData,'CoordType')
        data.CoordType=UvData.CoordType;
    end
    if isfield(UvData,'Mesh')&~isempty(UvData.Mesh)
        data.RangeY=UvData.Mesh;
        data.RangeX=UvData.Mesh;
        data.DX=UvData.Mesh;
        data.DY=UvData.Mesh;
    elseif isfield(UvData.Field,'AX')&isfield(UvData.Field,'AY')& isfield(UvData.Field,'A')%only image
        np=size(UvData.Field.A);
        meshx=(UvData.Field.AX(end)-UvData.Field.AX(1))/np(2);
        meshy=abs(UvData.Field.AY(end)-UvData.Field.AY(1))/np(1);
        data.RangeY=max(meshx,meshy);
        data.RangeX=max(meshx,meshy);
        data.DX=max(meshx,meshy);
    end 
    data.ParentButton=handles.VOLUME;
    PlotHandles=get_plot_handles(handles);%get the handles of the interface elements setting the plotting parameters
    [hset_object,UvData.sethandles]=set_object(data,PlotHandles);% call the set_object interface with action on haxes,
                                                      % associate the set_edit interface handle to the plotting axes
    if isfield(UvData,'SetObjectOrigin')                                                
    pos_view_field=get(huvmat,'Position');
    pos_set_object(1:2)=UvData.SetObjectOrigin + pos_view_field(1:2);
    pos_set_object(3:4)=UvData.SetObjectSize .* pos_view_field(3:4);  
    set(hset_object,'Position',pos_set_object)
    end
    UvData.MouseAction='create_object';
else
    set(handles.VOLUME,'BackgroundColor',[0 1 0])
    UvData.MouseAction='none';
end
set(huvmat,'UserData',UvData)

%-------------------------------------------------------
function edit_vect_Callback(hObject, eventdata, handles)
%-------------------------------------------------------

UvData=get(handles.view_field,'UserData');%read UvData properties stored on the view_field interface 
if isequal(get(handles.edit_vect,'Value'),1)
    test_civ2=isequal(get(handles.civ2,'BackgroundColor'),[1 1 0]);
    test_civ1=isequal(get(handles.civ1,'BackgroundColor'),[1 1 0]);
    if ~test_civ2 && ~test_civ1
        msgbox_view_field('ERROR','manual correction only possible for CIV1 or CIV2 velocity fields')
    end 
    set(handles.record,'Visible','on')
    set(handles.edit_vect,'BackgroundColor',[1 1 0])
    set(handles.edit,'Value',0)
    set(handles.create,'Value',0)
    set(handles.create,'BackgroundColor',[0 1 0])
    set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
    set(gcf,'Pointer','arrow')
    UvData.MouseAction='edit_vect';
else
    set(handles.record,'Visible','off')
    set(handles.edit_vect,'BackgroundColor',[0.7 0.7 0.7])
    UvData.MouseAction='none';
end
set(handles.view_field,'UserData',UvData)

%----------------------------------------------
function save_mask_Callback(hObject, eventdata, handles)
%-----------------------------------------------------------------------
huvmat=get(handles.save_mask,'parent');
UvData=get(huvmat,'UserData');

hpatch=findobj(huvmat,'Type','patch');
flag=1;
npx=size(UvData.Field.A,2);
npy=size(UvData.Field.A,1);
xi=[0.5:npx-0.5];
yi=[0.5:npy-0.5];
[Xi,Yi]=meshgrid(xi,yi);
if isfield(UvData,'Object')
    for iobj=1:length(UvData.Object)
        ObjectData=UvData.Object{iobj};
        if isfield(ObjectData,'ProjMode') &&(isequal(ObjectData.ProjMode,'mask_inside')||isequal(ObjectData.ProjMode,'mask_outside'));
            flagobj=1;
            testphys=0; %coordinates in pixels by default
            if isfield(ObjectData,'CoordType') && isequal(ObjectData.CoordType,'phys')
                if isfield(UvData,'XmlData')&& isfield(UvData.XmlData,'GeometryCalib')
                    Calib=UvData.XmlData.GeometryCalib;
                    testphys=1;
                end
            end
            if isfield(ObjectData,'Coord')& isfield(ObjectData,'Style') 
                if isequal(ObjectData.Style,'polygon') 
                    X=ObjectData.Coord(:,1);
                    Y=ObjectData.Coord(:,2);
                    if testphys
                        [X,Y]=px_XYZ(Calib,X,Y,0);% to generalise with 3D cases
                    end
                    flagobj=~inpolygon(Xi,Yi,X,Y);%=0 inside the polygon, 1 outside                  
                elseif isequal(ObjectData.Style,'ellipse')
                    if testphys
                        %[X,Y]=px_XYZ(Calib,X,Y,0);% TODO:create a polygon boundary and transform to phys
                    end
                    RangeX=max(ObjectData.RangeX);
                    RangeY=max(ObjectData.RangeY);
                    X2Max=RangeX*RangeX;
                    Y2Max=RangeY*RangeY;
                    distX=(Xi-ObjectData.Coord(1,1));
                    distY=(Yi-ObjectData.Coord(1,2));
                    flagobj=(distX.*distX/X2Max+distY.*distY/Y2Max)>1;
                elseif isequal(ObjectData.Style,'rectangle')
                    if testphys
                        %[X,Y]=px_XYZ(Calib,X,Y,0);% TODO:create a polygon boundary and transform to phys
                    end
                    distX=abs(Xi-ObjectData.Coord(1,1));
                    distY=abs(Yi-ObjectData.Coord(1,2));
                    flagobj=distX>max(ObjectData.RangeX) | distY>max(ObjectData.RangeY);
                end
                if isequal(ObjectData.ProjMode,'mask_outside')
                    flagobj=~flagobj;
                end
                flag=flag & flagobj;
            end
        end
    end
end
% flag=~flag;
%mask name
RootPath=get(handles.RootPath,'String');
RootFile=get(handles.RootFile,'String');
if ~isempty(RootFile)&(isequal(RootFile(1),'/')| isequal(RootFile(1),'\'))
        RootFile(1)=[];
end
filebase=fullfile(RootPath,RootFile);
list=get(handles.masklevel,'String');
masknumber=num2str(length(list));
maskindex=get(handles.masklevel,'Value');
mask_name=name_generator([filebase '_' masknumber 'mask'],maskindex,1,'.png','_i');
imflag=uint8(255*(0.392+0.608*flag));% =100 for flag=0 (vectors not computed when 20<imflag<200)
imflag=flipdim(imflag,1);
% imflag=uint8(255*flag);% =0 for flag=0 (vectors=0 when 20<imflag<200)
msgbox_view_field('CONFIRMATION',[mask_name ' saved'])
imwrite(imflag,mask_name,'BitDepth',8); 

%display the mask
%update_mask(handles,num_i1,num_j1)
figure;
vec=linspace(0,1,256);%define a linear greyscale colormap
map=[vec' vec' vec'];
colormap(map)

image(imflag);

%-------------------------------------------------------------------
%-------------------------------------------------------------------
%  - FUNCTIONS FOR SETTING PLOTTING PARAMETERS

%------------------------------------------------------------------



%------------------------------------------------------------------
% --- Executes on selection change in col_vec: choice of the color code.
%
function col_vec_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
% edit the choice for color code
list_code=get(handles.col_vec,'String');% list menu fields
index_code=get(handles.col_vec,'Value');% selected string index
col_code= list_code{index_code(1)}; % selected field
if isequal(col_code,'black') | isequal(col_code,'white')
   set(handles.slider1,'Visible','off')
   set(handles.slider2,'Visible','off')
   set(handles.colcode1,'Visible','off')
   set(handles.colcode2,'Visible','off')
   set(handles.AutoVecColor,'Visible','off')
   set_vec_col_bar(handles)
else
   set(handles.slider1,'Visible','on')
   set(handles.slider2,'Visible','on') 
   set(handles.colcode1,'Visible','on')
   set(handles.colcode2,'Visible','on')
   set(handles.AutoVecColor,'Visible','on')  
   if isequal(col_code,'ima_cor')
       set(handles.AutoVecColor,'Value',0)%fixed scale by default
       set(handles.vec_col_bar,'Value',0)% 3 colors r,g,b by default
       set(handles.slider1,'Min',0);
       set(handles.slider1,'Max',1);
       set(handles.slider2,'Min',0);
       set(handles.slider2,'Max',1);
 %      set(handles.min_title_vec,'String','0')
       set(handles.max_vec,'String','1')
       set(handles.colcode1,'String','0.333')
       colcode1_Callback(hObject, eventdata, handles)
       set(handles.colcode2,'String','0.666')
       colcode2_Callback(hObject, eventdata, handles)
   else
       set(handles.AutoVecColor,'Value',1)%auto scale between min,max by default
       set(handles.vec_col_bar,'Value',1)% colormap 'jet' by default
       minval=get(handles.slider1,'Min');
       maxval=get(handles.slider1,'Max');
       set(handles.slider1,'Value',minval)
       set(handles.slider2,'Value',maxval)
       set_vec_col_bar(handles)
   end
%    slider_update(handles)
end
%replot the current graph
run0_Callback(hObject, eventdata, handles)


%----------------------------------------------------------------
% -- Executes on slider movement to set the color code
%
function slider1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------
slider1=get(handles.slider1,'Value');
min_val=str2num(get(handles.min_vec,'String'));
max_val=str2num(get(handles.max_vec,'String'));
col=min_val+(max_val-min_val)*slider1;
set(handles.colcode1,'String',num2str(col))
if(get(handles.slider2,'Value') < col)%move also the second slider at the same value if needed
    set(handles.slider2,'Value',col)
    set(handles.colcode2,'String',num2str(col))
end
colcode1_Callback(hObject, eventdata, handles)

%----------------------------------------------------------------
% Executes on slider movement to set the color code
%----------------------------------------------------------------
function slider2_Callback(hObject, eventdata, handles)
slider2=get(handles.slider2,'Value');
min_val=str2num(get(handles.min_vec,'String'));
max_val=str2num(get(handles.max_vec,'String'));
col=min_val+(max_val-min_val)*slider2;
set(handles.colcode2,'String',num2str(col))
if(get(handles.slider1,'Value') > col)%move also the first slider at the same value if needed
    set(handles.slider1,'Value',col)
    set(handles.colcode1,'String',num2str(col))
end
colcode2_Callback(hObject, eventdata, handles)

%----------------------------------------------------------------
%execute on return carriage on the edit box corresponding to slider 1
%----------------------------------------------------------------
function colcode1_Callback(hObject, eventdata, handles)
% col=str2num(get(handles.colcode1,'String'));
% set(handles.slider1,'Value',col) 
set_vec_col_bar(handles)
update_plot(handles)

%----------------------------------------------------------------
%execute on return carriage on the edit box corresponding to slider 2
%----------------------------------------------------------------
function colcode2_Callback(hObject, eventdata, handles)
% col=str2num(get(handles.colcode2,'String'));
% set(handles.slider2,'Value',col) 
% slider2_Callback(hObject, eventdata, handles)
set_vec_col_bar(handles)
update_plot(handles)
%------------------------------------------------------------
%update the slider values after displaying vectors
%--------------------------------------------------------
% function slider_update(handles,auto,minC,colcode1,colcode2,maxC)
% set(handles.slider1,'Min',minC) 
% set(handles.slider1,'Max',maxC)
% set(handles.slider2,'Min',minC) 
% set(handles.slider2,'Max',maxC)
% set(handles.min_title_vec,'String',num2str(minC))
% set(handles.max_vec,'String',num2str(maxC))
% if auto
%         set(handles.colcode1,'String',num2str(colcode1,3))%update display
%         set(handles.colcode2,'String',num2str(colcode2,3))
% end
% set(handles.slider1,'Value',colcode1)%update slider with constant display
% set(handles.slider2,'Value',colcode2)
% set_vec_col_bar(handles)


%-------------------------------------------------------
% --- Executes on button press in AutoVecColor.
%-------------------------------------------------------
function vec_col_bar_Callback(hObject, eventdata, handles)
set_vec_col_bar(handles)

% %--------------------------------------------
% %update the display of color code for vectors
% %--------------------------------------------
% function set_vec_col_bar(handles)
% %get the image of the color display button 'vec_col_bar' in pixels
% uni=get(handles.vec_col_bar,'Unit');
% set(handles.vec_col_bar,'Unit','pixel')
% pos_vert=get(handles.vec_col_bar,'Position');
% set(handles.vec_col_bar,'Unit','Normalized')
% width=ceil(pos_vert(3));
% height=ceil(pos_vert(4));
% %get slider indications
% colcode.min=get(handles.slider1,'Min');
% colcode.max=get(handles.slider1,'Max');
% colcode.colcode1=get(handles.slider1,'Value');
% colcode.colcode2=get(handles.slider2,'Value');
% colcode.option=get(handles.vec_col_bar,'Value');
% colcode.auto=1;
% list_code=get(handles.col_vec,'String');% list menu fields
% index_code=get(handles.col_vec,'Value');% selected string index
% colcode.CName= list_code{index_code(1)}; % selected field used for vector color
% vec_C=colcode.min+(colcode.max-colcode.min)*[0.5:width-0.5]/width;%sample of vec_C values from min to max
% [colorlist,col_vec]=set_col_vec(colcode,vec_C);
% oneheight=ones(1,height);
% A1=colorlist(col_vec,1)*oneheight;
% A2=colorlist(col_vec,2)*oneheight;
% A3=colorlist(col_vec,3)*oneheight;
% A(:,:,1)=A1';
% A(:,:,2)=A2';
% A(:,:,3)=A3';
% set(handles.vec_col_bar,'Cdata',A)

%--------------------------------------------------------
% --- Executes on button press in cal.
function cal_Callback(hObject, eventdata, handles)

huvmat=get(handles.cal,'parent');%handles of the view_field interface
UvData=get(huvmat,'UserData');%read UvData properties stored on the view_field interface 
%reinitialize the edit interface associated with view_field
value=get(handles.cal,'Value'); 
if value
        set(handles.cal,'BackgroundColor',[1 1 0])
        %suppress the other options if MENULINE is chosen
        set(handles.zoom,'Value',0)
        set(handles.zoom,'BackgroundColor',[0.7 0.7 0.7])
        set(handles.create,'Value',0)
        set(handles.create,'BackgroundColor',[0 1 0])
        set(handles.create,'enable','off')      
        set(handles.edit_vect,'Value',0)
        set(handles.edit_vect,'enable','off')
        edit_vect_Callback(hObject, eventdata, handles)
        set(handles.edit,'Value',0)
        set(handles.edit,'BackgroundColor',[0.7 0.7 0.7])
        set(handles.edit,'enable','off')
        set(handles.list_object,'Value',1)      
        % initiate display of GUI geometry_calib
        data=[]; %default
		if isfield(UvData,'CoordType')
            data.CoordType=UvData.CoordType;
        end
        %data.ParentButton=handles.cal; % transmit the handles of the calling button to the GUI geometry_calib
		pos=get(huvmat,'Position');
		pos(1)=pos(1)+pos(3)-0.311+0.04; %0.311= width of the geometry_calib interface (units relative to the srcreen)
		pos(2)=pos(2)-0.02;
        [FileName,RootPath,FileBase,FileIndices,FileExt,SubDir]=read_file_boxes(handles);
%         [filebase,num_i1,num_j1,num_i2,num_j2,Ext,NomType,SubDir]=read_input_file(handles);
%         [inputfile,idetect]=name_generator(filebase,num_i1,num_j1,Ext,NomType,1,num_i2,num_j2,SubDir);
		[UvData.hset_object,UvData.sethandles]=geometry_calib(handles,pos,FileName);% call the set_object interface	
        pos_view_field=get(huvmat,'Position');
        %pos_cal(1:2)=UvData.CalOrigin + pos_view_field(1:2);
        if isfield(UvData,'CalOrigin')
            pos_cal(1)=pos_view_field(1)+UvData.CalOrigin(1)*pos_view_field(3);
            pos_cal(2)=pos_view_field(2)+UvData.CalOrigin(2)*pos_view_field(4);
            pos_cal(3:4)=UvData.CalSize .* pos_view_field(3:4);
            set(UvData.hset_object,'Position',pos_cal)
        end
        UvData.MouseAction='calib';
else
     UvData.MouseAction='none';     
     hgeometry_calib=findobj(allchild(0),'Name','geometry_calib');
%      if ~isempty(hgeometry_calib)
%          answer=questdlg('close the GUI geometry-calib?');
%          if isequal(answer,'Yes')
%              delete(hgeometry_calib)
%              set(handles.cal,'BackgroundColor',[0 1 0])
%          else
%              set(handles.cal,'Value',1)% keep the calibration function active
%          end
%      end
     set(handles.edit_vect,'enable','on')
     set(handles.edit,'enable','on')
     set(handles.create,'enable','on')
%      set(handles.LINE,'enable','on')
%      set(handles.PATCH,'enable','on')
%      set(handles.PLANE,'enable','on')
%      set(handles.VOLUME,'enable','on')
     %set(handles.makemask,'enable','on')
     hh=findobj(handles.axes3,'Tag','calib_points');
     if ~isempty(hh)
         delete(hh)
     end
     hhh=findobj(handles.axes3,'Tag','calib_marker');
     if ~isempty(hhh)
         delete(hhh)
     end    
end
set(huvmat,'UserData',UvData);

%-------------------------------------------------------------
% --- Executes on selection change in transform_fct.
function transform_fct_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------
global nb_builtin

huvmat=get(handles.transform_fct,'parent');
menu=get(handles.transform_fct,'String');
ind_coord=get(handles.transform_fct,'Value');
coord_option=menu{ind_coord};
list_transform=get(handles.transform_fct,'UserData');
ff=functions(list_transform{end});  
if isequal(coord_option,'more...'); 
    coord_fct='';

%     if exist(profil_perso,'file')
%           h=load (profil_perso);
%          if isfield(h,'transform_fct')
%                 transform_fct=h.transform_fct;
%          end
%     end
    prompt = {'Enter the name of the transform function'};
    dlg_title = 'user defined transform';
    num_lines= 1;
    [FileName, PathName, filterindex] = uigetfile( ...
       {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file', ff.file);
    if isequal(PathName(end),'/')||isequal(PathName(end),'\')
        PathName(end)=[];
    end
    transform_selected =fullfile(PathName,FileName);
    if ~exist(transform_selected,'file')
%            msgbox_view_field('ERROR',['procesing fct ' transform_selected ' not found'])
           return
    end
   [ppp,transform,ext_fct]=fileparts(FileName);% removes extension .m
   if ~isequal(ext_fct,'.m')
        msgbox_view_field('ERROR','a Matlab function .m must be introduced');
        return
   end
   menu=update_menu(handles.transform_fct,transform);%add the selected fct to the menu
   ind_coord=get(handles.transform_fct,'Value');
   addpath(PathName)
   list_transform{ind_coord}=str2func(transform);% create the function handle corresponding to the newly seleced function
   set(handles.transform_fct,'UserData',list_transform)
   rmpath(PathName)
   % save the new menu in the personal file 'view_field_perso.mat' 
   dir_perso=prefdir;%personal Matalb directory
   profil_perso=fullfile(dir_perso,'view_field_perso.mat');
   if exist(profil_perso,'file')
       for ilist=nb_builtin+1:numel(list_transform)
           ff=functions(list_transform{ilist});
           transform_fct{ilist-nb_builtin}=ff.file;
       end 
        save (profil_perso,'transform_fct','-append'); %store the root name for future opening of view_field
   end   
end

%check the current path to the selected function
if isa(list_transform{ind_coord},'function_handle')
    func=functions(list_transform{ind_coord});
    set(handles.path_transform,'String',fileparts(func.file)); %show the path to the senlected function
else
    set(handles.path_transform,'String','')
end
%CurrentPath=fileparts(which(coord_option));
% if ~isequal(PathName,CurrentPath)
%     addpath(PathName) 
%     errormsg=check_functions;
%     msgbox_view_field('WARNING',[['path ' PathName ' added to the current Matlab pathes'];errormsg])
% end
%set(handles.path_transform,'String',fullfile(PathName,' ')); %show the path to the senlected function
set(handles.FixedLimits,'Value',0)
set(handles.FixedLimits,'BackgroundColor',[0.7 0.7 0.7])

UvData=get(huvmat,'UserData');

%delete drawn objects
hother=findobj('Tag','proj_object');%find all the proj objects
for iobj=1:length(hother)
    delete_object(hother(iobj))
end
hother=findobj('Tag','DeformPoint');%find all the proj objects
for iobj=1:length(hother)
    delete_object(hother(iobj))
end
hh=findobj('Tag','calib_points');
if ~isempty(hh)
    delete(hh)
end
hhh=findobj('Tag','calib_marker');
if ~isempty(hhh)
    delete(hhh)
end
if isfield(UvData,'Object')
    nbobject=length(UvData.Object);
    UvData.Object([2:nbobject])=[];
end 

%delete mask if it is displayed 
if isequal(get(handles.mask_test,'Value'),1)%if the mask option is on
   UvData=rmfield(UvData,'MaskName'); %will impose mask refresh  
end
set(huvmat,'UserData',UvData)
run0_Callback(hObject, eventdata, handles)

%--------------------------------------------
function histo1_menu_Callback(hObject, eventdata, handles)
%--------------------------------------------
%plot first histo
huvmat=get(handles.histo1_menu,'parent');
histo_menu=get(handles.histo1_menu,'String');
histo_value=get(handles.histo1_menu,'Value');
FieldName=histo_menu{histo_value};
UvData=get(huvmat,'UserData');
update_histo(handles.histo_u,huvmat,FieldName)

%----------------------------------------------
function histo2_menu_Callback(hObject, eventdata, handles)
%----------------------------------------------
%plot second histo
huvmat=get(handles.histo2_menu,'parent');
histo_menu=get(handles.histo2_menu,'String');
histo_value=get(handles.histo2_menu,'Value');
FieldName=histo_menu{histo_value};
UvData=get(huvmat,'UserData');
update_histo(handles.histo_v,huvmat,FieldName)


%--------------------------------------------
%read the field .Fieldname stored in UvData and plot its histogram
function update_histo(haxes,huvmat,FieldName)
UvData=get(huvmat,'UserData');

if ~isfield(UvData.Field,FieldName)
    msgbox_view_field('ERROR',['no field  ' FieldName ' for histogram'])
    return
end
Field=UvData.Field;
FieldHisto=eval(['Field.' FieldName]);
if isfield(Field,'FF') & ~isempty(Field.FF) & isequal(size(Field.FF),size(FieldHisto))
    indsel=find(Field.FF==0);%find values marked as false
    if ~isempty(indsel)
        FieldHisto=FieldHisto(indsel);
    end
end
if isempty(Field)
    msgbox_view_field('ERROR',['empty field ' FieldName])
else
    nxy=size(FieldHisto);
    Amin=double(min(min(min(FieldHisto))));%min of image
    Amax=double(max(max(max(FieldHisto))));%max of image
    if isequal(Amin,Amax)
       Histo.Txt=['uniform field =' num2str(Amin)];
    else
    Histo.ListVarName={FieldName,'histo'};
    if numel(nxy)==2
        Histo.VarDimName={FieldName,FieldName}; %dimensions for the histogram
    else %color images
        Histo.VarDimName={FieldName,{FieldName,'rgb'}}; %dimensions for the histogram
    end
    %unit
    units=[]; %default
    for ivar=1:numel(Field.ListVarName)    
        if strcmp(Field.ListVarName{ivar},FieldName)
            if isfield(Field,'VarAttribute') && numel(Field.VarAttribute)>=ivar && isfield(Field.VarAttribute{ivar},'units')
                units=Field.VarAttribute{ivar}.units;
                break
            end
        end
    end
    if ~isempty(units)
        Histo.VarAttribute{1}.units=units;
    end
    eval(['Histo.' FieldName '=linspace(Amin,Amax,50);'])%absissa values for histo
    for col=1:size(FieldHisto,3)
        B=FieldHisto(:,:,col);
        C=reshape(double(B),1,nxy(1)*nxy(2));% reshape in a vector
       eval(['Histo.histo(:,col)=hist(C, Histo.' FieldName ');']);  %calculate histogram
    end
    set(haxes,'XLimMode','auto')%reset auto mode (after zoom effect)
    set(haxes,'YLimMode','auto')
    plot_field(Histo,haxes);
    end
end



%------------------------------------------------
%CALLBACKS FOR PLOTTING PARAMETERS
%-------------------------------------------------

%-----------------------------------------------------------------
function MinA_Callback(hObject, eventdata, handles)
%------------------------------------------
set(handles.AutoScal,'Value',1) %suppress auto mode
set(handles.AutoScal,'BackgroundColor',[1 1 0])
update_plot(handles)

%-----------------------------------------------------------------
function MaxA_Callback(hObject, eventdata, handles)
%--------------------------------------------
set(handles.AutoScal,'Value',1) %suppress auto mode
set(handles.AutoScal,'BackgroundColor',[1 1 0])
update_plot(handles)

%-----------------------------------------------
function AutoScal_Callback(hObject, eventdata, handles)
%--------------------------------------------
test=get(handles.AutoScal,'Value');
if test
    set(handles.AutoScal,'BackgroundColor',[1 1 0])
else
    set(handles.AutoScal,'BackgroundColor',[0.7 0.7 0.7])
    update_plot(handles);
%     set(handles.MinA,'String',num2str(ScalOut.MinA,3))
%     set(handles.MaxA,'String',num2str(ScalOut.MaxA,3))
end

%-------------------------------------------------------------------
function BW_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles)

%-------------------------------------------------------------------
function Contours_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
val=get(handles.Contours,'Value');
if val==2
    set(handles.interval_txt,'Visible','on')
    set(handles.IncrA,'Visible','on')
else
    set(handles.interval_txt,'Visible','off')
    set(handles.IncrA,'Visible','off')
end
update_plot(handles)

%-------------------------------------------------------------------
function IncrA_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles)

%-------------------------------------------------------------------
function HideWarning_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles)

%-------------------------------------------------------------------
function HideFalse_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles)

%-------------------------------------------------------------------
function VecScale_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
set(handles.AutoVec,'Value',1);
set(handles.AutoVec,'BackgroundColor',[1 1 0])
update_plot(handles)

%-------------------------------------------------------------------
function AutoVec_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
test=get(handles.AutoVec,'Value');
if test
    set(handles.AutoVec,'BackgroundColor',[1 1 0])
else
    update_plot(handles);
    %set(handles.VecScale,'String',num2str(ScalOut.VecScale,3))
    set(handles.AutoVec,'BackgroundColor',[0.7 0.7 0.7])
end

%-------------------------------------------------------
% --- Executes on selection change in decimate4 (nb_vec/4).
%-------------------------------------------------------
function decimate4_Callback(hObject, eventdata, handles)
update_plot(handles)


%-------------------------------------------------------
% --- Executes on selection change in color_code menu
%-------------------------------------------------------
function color_code_Callback(hObject, eventdata, handles)
set_vec_col_bar(handles)
update_plot(handles);

%-------------------------------------------------------
% --- Executes on button press in AutoVecColor.
%-------------------------------------------------------
function AutoVecColor_Callback(hObject, eventdata, handles)
test=get(handles.AutoVecColor,'Value');
if test
    set(handles.AutoVecColor,'BackgroundColor',[1 1 0])
else
    update_plot(handles);
    %set(handles.VecScale,'String',num2str(ScalOut.VecScale,3))
    set(handles.AutoVecColor,'BackgroundColor',[0.7 0.7 0.7])
end
%set_vec_col_bar(handles)

%-------------------------------------------------------
% --- Executes on selection change in max_vec.
%-------------------------------------------------------
function min_vec_Callback(hObject, eventdata, handles)
max_vec_Callback(hObject, eventdata, handles)

% --- Executes on selection change in max_vec.
function max_vec_Callback(hObject, eventdata, handles)
set(handles.AutoVecColor,'Value',1)
AutoVecColor_Callback(hObject, eventdata, handles)
min_val=str2num(get(handles.min_vec,'String'));
max_val=str2num(get(handles.max_vec,'String'));
slider1=get(handles.slider1,'Value');
slider2=get(handles.slider2,'Value');
colcode1=min_val+(max_val-min_val)*slider1;
colcode2=min_val+(max_val-min_val)*slider2;
set(handles.colcode1,'String',num2str(colcode1))
set(handles.colcode2,'String',num2str(colcode2))
update_plot(handles);

%-------------------------------------------------------------------
%update the display of color code for vectors
function set_vec_col_bar(handles)
%-------------------------------------------------------------------
%get the image of the color display button 'vec_col_bar' in pixels
set(handles.vec_col_bar,'Unit','pixel');
pos_vert=get(handles.vec_col_bar,'Position');
set(handles.vec_col_bar,'Unit','Normalized');
width=ceil(pos_vert(3));
height=ceil(pos_vert(4));

%get slider indications
list=get(handles.color_code,'String');
ichoice=get(handles.color_code,'Value');
colcode.ColorCode=list{ichoice};
colcode.MinC=str2num(get(handles.min_vec,'String'));
colcode.MaxC=str2num(get(handles.max_vec,'String'));
test3color=strcmp(colcode.ColorCode,'rgb') || strcmp(colcode.ColorCode,'bgr');
if test3color
    colcode.colcode1=str2num(get(handles.colcode1,'String'));
    colcode.colcode2=str2num(get(handles.colcode2,'String'));
end
% colcode.option=get(handles.vec_col_bar,'Value');
colcode.FixedCbounds=0;
% list_code=get(handles.col_vec,'String');% list menu fields
% index_code=get(handles.col_vec,'Value');% selected string index
% colcode.CName= list_code{index_code(1)}; % selected field used for vector color
colcode.FixedCbounds=1;
vec_C=colcode.MinC+(colcode.MaxC-colcode.MinC)*[0.5:width-0.5]/width;%sample of vec_C values from min to max
[colorlist,col_vec]=set_col_vec(colcode,vec_C);
oneheight=ones(1,height);
A1=colorlist(col_vec,1)*oneheight;
A2=colorlist(col_vec,2)*oneheight;
A3=colorlist(col_vec,3)*oneheight;
A(:,:,1)=A1';
A(:,:,2)=A2';
A(:,:,3)=A3';
set(handles.vec_col_bar,'Cdata',A)


%-------------------------------------------------------------------
function [PlotType,ScalOut]=update_plot(handles)
%-------------------------------------------------------------------
haxes= handles.axes3;
AxeData=get(haxes,'UserData');
PlotParam=read_plot_param(handles);
[PlotType,PlotParamOut]= plot_field(AxeData,haxes,PlotParam,1);
write_plot_param(handles,PlotParamOut); %update the auto plot parameters



%------------------------------------------------------
% --- Executes on button press in Menu/Export/field in workspace.
%------------------------------------------------------
function MenuExportField_Callback(hObject, eventdata, handles)

global CurData
huvmat=findobj(allchild(0),'Name','uvmat');
CurData=get(huvmat,'UserData');
evalin('base','global CurData')%make CurData global in the workspace
display(['UserData of view_field :'])
evalin('base','CurData') %display CurData in the workspace
commandwindow;

%------------------------------------------------------
% --- Executes on button press in Menu/Export/extract figure.
%------------------------------------------------------
function MenuExport_plot_Callback(hObject, eventdata, handles)
huvmat=get(handles.MenuExport_plot,'parent');
UvData=get(huvmat,'UserData');
hfig=figure;
newaxes=copyobj(handles.axes3,hfig);
map=colormap(handles.axes3);
colormap(map);%transmit the current colormap to the zoom fig
colorbar



function edit84_Callback(hObject, eventdata, handles)
% hObject    handle to edit84 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit84 as text
%        str2double(get(hObject,'String')) returns contents of edit84 as a double


% --- Executes during object creation, after setting all properties.
function edit84_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit84 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit85_Callback(hObject, eventdata, handles)
% hObject    handle to edit85 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit85 as text
%        str2double(get(hObject,'String')) returns contents of edit85 as a double


% --- Executes during object creation, after setting all properties.
function edit85_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit85 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit86_Callback(hObject, eventdata, handles)
% hObject    handle to edit86 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit86 as text
%        str2double(get(hObject,'String')) returns contents of edit86 as a double


% --- Executes during object creation, after setting all properties.
function edit86_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit86 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit87_Callback(hObject, eventdata, handles)
% hObject    handle to edit87 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit87 as text
%        str2double(get(hObject,'String')) returns contents of edit87 as a double


% --- Executes during object creation, after setting all properties.
function edit87_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit87 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox39.
function checkbox39_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox39 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox39



function edit88_Callback(hObject, eventdata, handles)
% hObject    handle to edit88 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit88 as text
%        str2double(get(hObject,'String')) returns contents of edit88 as a double


% --- Executes during object creation, after setting all properties.
function edit88_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit88 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox40.
function checkbox40_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox40 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox40



function edit82_Callback(hObject, eventdata, handles)
% hObject    handle to edit82 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit82 as text
%        str2double(get(hObject,'String')) returns contents of edit82 as a double


% --- Executes during object creation, after setting all properties.
function edit82_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit82 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit83_Callback(hObject, eventdata, handles)
% hObject    handle to edit83 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit83 as text
%        str2double(get(hObject,'String')) returns contents of edit83 as a double


% --- Executes during object creation, after setting all properties.
function edit83_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit83 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider9_Callback(hObject, eventdata, handles)
% hObject    handle to slider9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider10_Callback(hObject, eventdata, handles)
% hObject    handle to slider10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in checkbox41.
function checkbox41_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox41 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox41



function edit89_Callback(hObject, eventdata, handles)
% hObject    handle to edit89 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit89 as text
%        str2double(get(hObject,'String')) returns contents of edit89 as a double


% --- Executes during object creation, after setting all properties.
function edit89_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit89 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit90_Callback(hObject, eventdata, handles)
% hObject    handle to edit90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit90 as text
%        str2double(get(hObject,'String')) returns contents of edit90 as a double


% --- Executes during object creation, after setting all properties.
function edit90_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton35.
function pushbutton35_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton35 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


