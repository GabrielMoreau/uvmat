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
handles.output = handles.view_field;

% Update handles structure
guidata(hObject, handles);

dircur=pwd; %current working directory
dir_opening=dircur;

% set the position of colorbar and ancillary GUIs:
set(hObject,'Units','Normalized')
handles_mouse=handles;
huvmat=findobj(allchild(0),'Name','uvmat');
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
    set(hhuvmat.list_object_2,'Visible','on')
    % handles_mouse.create=hhuvmat.create;
    handles_mouse.edit=hhuvmat.edit;
    pos_uvmat=get(huvmat,'Position');
    pos_view_field(1)=pos_uvmat(1)+pos_uvmat(3)/2;
    pos_view_field(2)=pos_uvmat(2)-pos_uvmat(3)/4;
    pos_view_field(3:4)=pos_uvmat(3:4);
    set(hObject,'Position',pos_view_field)
end

%functions for the mouse and keyboard
set(hObject,'KeyPressFcn',{'keyboard_callback',handles_mouse})%set keyboard action function
set(hObject,'WindowButtonMotionFcn',{'mouse_motion',handles_mouse})%set mouse action functio
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%set mouse click action function
set(hObject,'WindowButtonUpFcn',{'mouse_up',handles_mouse}) 
set(hObject,'CloseRequestFcn',{@closefcn})%

[PlotType,PlotParamOut]= plot_field(Field,handles.axes3);%,PlotParam,KeepLim,PosColorbar)
ViewFieldData.axes3=Field;
set(handles.view_field,'UserData',ViewFieldData);%store the current field
get(handles.view_field)
if isfield(PlotParamOut,'Vectors')
    set(handles.VECT_title,'Visible','on')
end
write_plot_param(handles,PlotParamOut);% update the display of the plotting parameters

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
 %      set(handles.min_C_title_vec,'String','0')
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
% set(handles.min_C_title_vec,'String',num2str(minC))
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
'TEST'
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
function PlotType=update_plot(handles)
%-------------------------------------------------------------------
haxes= handles.axes3;
%huvmat=findobj(allchild(0),'tag','uvmat');
ProjField=get(haxes,'UserData');
PlotParam=read_plot_param(handles);
[PlotType,PlotParamOut]= plot_field(ProjField,haxes,PlotParam,1);
write_plot_param(handles,PlotParamOut); %update the auto plot parameters

%------------------------------------------------------
% --- Executes on button press in Menu/Export/field in workspace.
%------------------------------------------------------
function MenuExportField_Callback(hObject, eventdata, handles)

global Data_view_field
% huvmat=findobj(allchild(0),'Name','uvmat');
Data_view_field=get(handles.view_field,'UserData');
Data_view_field=Data_view_field.axes3;
% Data_view_field=UvData.ProjField_2;
evalin('base','global Data_view_field')%make CurData global in the workspace
display(['UserData of view_field :'])
evalin('base','Data_view_field') %display CurData in the workspace
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



function npx_Callback(hObject, eventdata, handles)



function npy_Callback(hObject, eventdata, handles)


function edit86_Callback(hObject, eventdata, handles)


function edit87_Callback(hObject, eventdata, handles)


% --- Executes on button press in auto_sclar.
function auto_sclar_Callback(hObject, eventdata, handles)
% hObject    handle to auto_sclar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of auto_sclar



% --- Executes on slider movement.
function slider9_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes on slider movement.
function slider10_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of
%        slider


function closefcn(hObject, eventdata, handles)
huvmat=findobj(allchild(0),'Name','uvmat');
if ~isempty(huvmat)
hhuvmat=guidata(huvmat);
list_object_2=get(hhuvmat.list_object_2,'String');
set(hhuvmat.list_object_2,'Value',numel(list_object_2))%select the last value ('...')
end
delete(hObject)


% --- Executes on selection change in popupmenu18.
function popupmenu18_Callback(hObject, eventdata, handles)



function text_display_Callback(hObject, eventdata, handles)
% hObject    handle to text_display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_display as text
%        str2double(get(hObject,'String')) returns contents of text_display as a double


% --- Executes during object creation, after setting all properties.
function text_display_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


