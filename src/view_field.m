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

%functions for the mouse and keyboard
set(hObject,'KeyPressFcn',{'keyboard_callback',handles})%set keyboard action function
set(hObject,'WindowButtonMotionFcn',{'mouse_motion',handles})%set mouse action functio
set(hObject,'WindowButtonDownFcn',{'mouse_down'})%set mouse click action function
set(hObject,'WindowButtonUpFcn',{'mouse_up',handles}) 
set(hObject,'DeleteFcn',{@closefcn})%
set(hObject,'ResizeFcn',{@ResizeFcn,handles})%
ViewFieldData.PlotAxes=[];%initiates the record of the current field (will be updated by plot_field)
set(handles.view_field,'Units','pixels')
ViewFieldData.GUISize=get(handles.view_field,'Position');
set(handles.view_field,'UserData',ViewFieldData);%store the initial fig size in UserData
AxeData.LimEditBox=1; %initialise AxeData, the parent figure sets plot parameters
set(handles.PlotAxes,'UserData',AxeData)
if exist('Field','var')
    [PlotType,PlotParamOut]= plot_field(Field,handles.PlotAxes);%,PlotParam,KeepLim,PosColorbar)
    set(handles.Coordinates,'Visible','on')
    if isfield(PlotParamOut,'Vectors')
        set(handles.Vectors,'Visible','on')
    else
        set(handles.Vectors,'Visible','off')
    end
    if isfield(PlotParamOut,'Scalar')
        set(handles.Scalar,'Visible','on')
    else
        set(handles.Scalar,'Visible','off')
    end
    
    errormsg=fill_GUI(PlotParamOut,hObject);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg)
        return
    end
    %write_plot_param(handles,PlotParamOut);% update the display of the plotting parameters
end

%put the GUI on the lower right of the sceen
pos_view_field=get(hObject,'Position');
set(0,'Unit','pixel')
ScreenSize=get(0,'ScreenSize');
pos_view_field(1)=ScreenSize(1)+ScreenSize(3)-pos_view_field(3);
pos_view_field(2)=ScreenSize(2);
set(hObject,'Position',pos_view_field)

%------------------------------------------------------------------------
%--- activated when resizing the GUI view_field
 function ResizeFcn(gcbo,eventdata,handles)
%------------------------------------------------------------------------     
set(handles.view_field,'Units','pixels')
size_fig=get(handles.view_field,'Position');
Data=get(handles.view_field,'UserData');
Data.GUISize=size_fig;
set(handles.view_field,'UserData',Data)

%% reset position of text_display or TableDisplay
if strcmp(get(handles.TableDisplay,'Visible'),'off')
    pos_1=get(handles.text_display,'Position');% [lower x lower y width height] for text_display
    pos_1(1)=size_fig(3)-pos_1(3);             % set text display to the right of the fig
    pos_1(2)=size_fig(4)-pos_1(4);             % set text display to the top of the fig
    set(handles.text_display,'Position',pos_1)
    % reset position of TableDisplay
else
    pos_1=get(handles.TableDisplay,'Position');
    pos_1(1)=size_fig(3)-pos_1(3);
    pos_1(2)=size_fig(4)-pos_1(4);
    set(handles.TableDisplay,'Position',pos_1)
end

%% reset position of CheckHold
pos_CheckHold=get(handles.CheckHold,'Position');% [lower x lower y width height] for CheckHold
pos_CheckHold(1)=size_fig(3)-pos_CheckHold(3);       % set 'CheckHold' to the right of the fig
pos_CheckHold(2)=pos_1(2)-pos_CheckHold(4);          % set 'CheckHold' to the lower edge of text display
set(handles.CheckHold,'Position',pos_CheckHold)

%% reset position of Coordinates
pos_2=get(handles.Coordinates,'Position');% [lower x lower y width height] for frame 'Coordinates'
pos_2(1)=size_fig(3)-pos_2(3);       % set 'Coordinates' to the right of the fig
pos_2(2)=pos_CheckHold(2)-pos_2(4);          % set 'Coordinates' to the lower edge of text display, allowing a margin for CheckHold
set(handles.Coordinates,'Position',pos_2)

%% reset position of  Scalar
pos_3=get(handles.Scalar,'Position'); % [lower x lower y width height] for frame 'Scalar'
pos_3(1)=size_fig(3)-pos_3(3);         % set 'Scalar' to the right of the fig
if strcmp(get(handles.Scalar,'visible'),'on')
    pos_3(2)=pos_2(2)-pos_3(4); % set 'Scalar' to the lower edge of frame 'Coordinates' if visible
else
    pos_3(2)=pos_2(2);% set 'Scalar' to the lower edge of frame 'text display' if  unvisible
end
set(handles.Scalar,'Position',pos_3)

%% reset position of  Vectors
pos_4=get(handles.Vectors,'Position');
pos_4(1)=size_fig(3)-pos_4(3);
if strcmp(get(handles.Vectors,'visible'),'on')
    pos_4(2)=pos_3(2)-pos_4(4);
else
    pos_4(2)=pos_3(2);
end
set(handles.Vectors,'Position',pos_4)

%% reset position and scale of axis
bord=[50 40 30 60]; %bordure left,inf, right,sup
pos(1)=bord(1);
pos(2)=bord(2);
pos(3)=max(1,pos_1(1)-pos(1)-bord(3));
pos(4)=max(1,size_fig(4)-bord(4));
set(handles.PlotAxes,'Position',pos)

%------------------------------------------------------------------------
%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command menuline.
function varargout = view_field_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
varargout{1} = handles.output;% the only output argument is the handle to the GUI figure
varargout{2} = strcmp(get(handles.PlotAxes,'Visible'),'on');% check active plot axis

%------------------------------------------------------------------------
%--- activated when closing the GUI view_field
function closefcn(gcbo,eventdata)
%------------------------------------------------------------------------
huvmat=findobj(allchild(0),'Tag','uvmat');%find the current uvmat interface handle
if ~isempty(huvmat)
    hhuvmat=guidata(huvmat);
    set(hhuvmat.CheckViewField,'Value',0)
    %set(hhuvmat.edit_object,'BackgroundColor',[0.7 0.7 0.7])%put unactivated buttons to gree
    % deselect the object in ListObject when view_field is closed
    if isempty(findobj(allchild(0),'Tag','set_object'))
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
hciv=findobj(allchild(0),'Tag','civ');%find the current civ GUI
if ~isempty(hciv)
    hhciv=guidata(hciv);
    set(hhciv.TestCiv1,'Value',0)% desactivate  TestCiv1 if on
    set(hhciv.TestCiv1,'BackgroundColor',[1 0 0])% 
end
corrfig=findobj(allchild(0),'tag','corrfig');% look for a civ correlation window used with TesCiv1
if ~isempty(corrfig)
    delete(corrfig)
end

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
[RootPath,RootFile]=fullfile(MaskData.Base);
MaskName=fullfile_uvmat(RootPath,'',RootFile,'.png',MaskData.NomType,num_i1_mask,[],num_j1);
%[MaskName,mdetect]=name_generator(MaskData.Base,num_i1_mask,num_j1,'.png',MaskData.NomType);
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
        Mask.CoordUnit='pixel';
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
            axes(handles.PlotAxes)
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
newaxes=copyobj(handles.PlotAxes,hfig);
map=colormap(handles.PlotAxes);
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

% %-------------------------------------------------------------------
% %Executes on button press in runmin: make one step backward and call
% %run0. The step backward is along the fields series 1 or 2 depending on 
% %the scan_i and scan_j check box (exclusive each other)
% %-------------------------------------------------------------------
% function RunMovie_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------
% set(handles.RunMovie,'BackgroundColor',[1 1 0])%paint the command button in yellow
% drawnow
% increment=str2num(get(handles.increment_scan,'String')); %get the field increment d
% set(handles.STOP,'Visible','on')
% set(handles.speed,'Visible','on')
% set(handles.speed_txt,'Visible','on')
% set(handles.RunMovie,'BusyAction','queue')
% testavi=0;
% UvData=get(handles.view_field,'UserData');
% 
% while get(handles.speed,'Value')~=0 & isequal(get(handles.RunMovie,'BusyAction'),'queue') % enable STOP command
%         runpm(hObject,eventdata,handles,increment)
%         pause(1.02-get(handles.speed,'Value'))% wait for next image
% end
% if isfield(UvData,'aviobj') && ~isempty( UvData.aviobj),
%     UvData.aviobj=close(UvData.aviobj);
%    set(handles.view_field,'UserData',UvData);
% end
% set(handles.RunMovie,'BackgroundColor',[1 0 0])%paint the command buttonback to red

%------------------------------------------------------------------------
% --- translate coordinate to matrix index
%------------------------------------------------------------------------
function [indx,indy]=pos2ind(x0,rangx0,nxy)
indx=1+round((nxy(2)-1)*(x0-rangx0(1))/(rangx0(2)-rangx0(1)));% index x of pixel  
indy=1+round((nxy(1)-1)*(y12-rangy0(1))/(rangy0(2)-rangy0(1)));% index y of pixel

%------------------------------------------------------------------------
% --- Executes on button press in 'CheckZoom'.
%------------------------------------------------------------------------
function CheckZoom_Callback(hObject, eventdata, handles)

if get(handles.CheckZoom,'Value') 
    set(handles.CheckFixLimits,'Value',1)% propose by default fixed limits for the plotting axes
    set(handles.CheckZoomFig,'Value',0)%desactivate zoom fig
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckZoomFig.
%------------------------------------------------------------------------
function CheckZoomFig_Callback(hObject, eventdata, handles)

if get(handles.CheckZoomFig,'Value')
    set(handles.CheckZoom,'value',0)
end

%-------------------------------------------------------------------
% --- Executes on button press in 'FixLimits'.
%-------------------------------------------------------------------
function CheckFixLimits_Callback(hObject, eventdata, handles)
test=get(handles.CheckFixLimits,'Value');
% if test
%     set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
% else
%     set(handles.CheckFixLimits,'BackgroundColor',[0.7 0.7 0.7])
% end
update_plot(handles)
 
 %-------------------------------------------------------------------
% --- Executes on button press in CheckFixAspectRatio.
function CheckFixAspectRatio_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
if get(handles.CheckFixAspectRatio,'Value')
    update_plot(handles);
else
    update_plot(handles);
end

%-------------------------------------------------------------------
function num_AspectRatio_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
set(handles.CheckFixAspectRatio,'Value',1)% select the fixed aspect ratio button
update_plot(handles);

%-------------------------------------------------------------------

% %-------------------------------------------------------------------
% %----Executes on button press in 'record': records the current flags of manual correction.
% %-------------------------------------------------------------------
% function record_Callback(hObject, eventdata, handles)
% % [filebase,num_i1,num_j1,num_i2,num_j2,Ext,NomType,SubDir]=read_input_file(handles);
% filename=read_file_boxes(handles);
% AxeData=get(gca,'UserData');
% [erread,message]=fileattrib(filename);
% if ~isempty(message) && ~isequal(message.UserWrite,1)
%      msgbox_view_field('ERROR',['no writting access to ' filename])
%      return
% end
% test_civ2=isequal(get(handles.civ2,'BackgroundColor'),[1 1 0]);
% test_civ1=isequal(get(handles.civ1,'BackgroundColor'),[1 1 0]);
% if ~test_civ2 && ~test_civ1
%     msgbox_view_field('ERROR','manual correction only possible for CIV1 or CIV2 velocity fields')
% end 
% if test_civ2
%     nbname='nb_vectors2';
%    flagname='vec2_FixFlag';
%    attrname='fix2';
% end
% if test_civ1
%     nbname='nb_vectors';
%    flagname='vec_FixFlag';
%    attrname='fix';
% end
% %write fix flags in the netcdf file
% hhh=which('netcdf.open');% look for built-in matlab netcdf library
% if ~isequal(hhh,'')% case of new builtin Matlab netcdf library
%     nc=netcdf.open(filename,'NC_WRITE'); 
%     netcdf.reDef(nc)
%     netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),attrname,1)
%     dimid = netcdf.inqDimID(nc,nbname); 
%     try
%         varid = netcdf.inqVarID(nc,flagname);% look for already existing fixflag variable
%     catch
%         varid=netcdf.defVar(nc,flagname,'double',dimid);%create fixflag variable if it does not exist
%     end
%     netcdf.endDef(nc)
%     netcdf.putVar(nc,varid,AxeData.FF);
%     netcdf.close(nc)  
% else %old netcdf library
%     netcdf_toolbox(filename,AxeData,attrname,nbname,flagname)
% end
% 
% function netcdf_toolbox(filename,AxeData,attrname,nbname,flagname)
% nc=netcdf(filename,'write'); %open netcdf file
% result=redef(nc);
% eval(['nc.' attrname '=1;']);
% theDim=nc(nbname) ;% get the number of velocity vectors
% nb_vectors=size(theDim);
% var_FixFlag=ncvar(flagname,nc);% var_FixFlag will be written as the netcdf variable vec_FixFlag
% var_FixFlag(1:nb_vectors)=AxeData.FF;% 
% fin=close(nc);


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

%-------------------------------------------------------
% --- Executes on button press in AutoVecColor.
%-------------------------------------------------------
function vec_col_bar_Callback(hObject, eventdata, handles)
set_vec_col_bar(handles)

%------------------------------------------------
%CALLBACKS FOR PLOTTING PARAMETERS
%-------------------------------------------------

%------------------------------------------------------------------------
function num_MinX_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
% set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%------------------------------------------------------------------------
function num_MaxX_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
% set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%------------------------------------------------------------------------
function num_MinY_Callback(hObject, eventdata, handles)
%------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
% set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%------------------------------------------------------------------------
function num_MaxY_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.CheckFixLimits,'Value',1) %suppress auto mode
% set(handles.CheckFixLimits,'BackgroundColor',[1 1 0])
update_plot(handles);

%-----------------------------------------------------------------
function num_MinA_Callback(hObject, eventdata, handles)
%------------------------------------------
set(handles.CheckFixScalar,'Value',1) %suppress auto mode
set(handles.CheckFixScalar,'BackgroundColor',[1 1 0])
update_plot(handles)

%-----------------------------------------------------------------
function num_MaxA_Callback(hObject, eventdata, handles)
%--------------------------------------------
set(handles.CheckFixScalar,'Value',1) %suppress auto mode
% set(handles.CheckFixScalar,'BackgroundColor',[1 1 0])
update_plot(handles)

%-----------------------------------------------
function CheckFixScalar_Callback(hObject, eventdata, handles)
%--------------------------------------------
test=get(handles.CheckFixScalar,'Value');
% if test
%     set(handles.CheckFixScalar,'BackgroundColor',[1 1 0])
% else
%     set(handles.CheckFixScalar,'BackgroundColor',[0.7 0.7 0.7])
%     update_plot(handles);
% %     set(handles.MinA,'String',num2str(ScalOut.MinA,3))
% %     set(handles.MaxA,'String',num2str(ScalOut.MaxA,3))
% end

%-------------------------------------------------------------------
function CheckBW_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
update_plot(handles)

%-------------------------------------------------------------------
function ListContour_Callback(hObject, eventdata, handles)
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
function num_VecScale_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
set(handles.CheckFixVectors,'Value',1);
update_plot(handles)

%-------------------------------------------------------------------
function FixVec_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------
test=get(handles.FixVec,'Value');
if test
    set(handles.FixVec,'BackgroundColor',[1 1 0])
else
    update_plot(handles);
    %set(handles.VecScale,'String',num2str(ScalOut.VecScale,3))
%     set(handles.FixVec,'BackgroundColor',[0.7 0.7 0.7])
end

%-------------------------------------------------------
% --- Executes on selection change in decimate4 (nb_vec/4).
%-------------------------------------------------------
function CheckDecimate4_Callback(hObject, eventdata, handles)
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
colcode.FixedCbounds=0;
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
function update_plot(handles)
%-------------------------------------------------------------------
Data=get(handles.view_field,'UserData');
AxeData=Data.PlotAxes;% retrieve the current plotted data
PlotParam=read_GUI(handles.view_field);
[PP,PlotParamOut]= plot_field(AxeData,handles.PlotAxes,PlotParam);
errormsg=fill_GUI(PlotParamOut,handles.view_field);
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg)
        return
    end
%write_plot_param(handles,PlotParamOut); %update the auto plot parameters

%------------------------------------------------------------------------
% --- Executes on button press in Menu/Export/field in workspace.
function MenuExportField_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
global Data_view_field
% huvmat=findobj(allchild(0),'Name','uvmat');
Data_view_field=get(handles.view_field,'UserData');
Data_view_field=Data_view_field.PlotAxes;
% Data_view_field=UvData.ProjField_2;
evalin('base','global Data_view_field')%make CurData global in the workspace
display(['UserData of view_field :'])
evalin('base','Data_view_field') %display CurData in the workspace
commandwindow;

%------------------------------------------------------------------------
% --- Executes on button press in Menu/Export/extract figure.
function MenuExport_plot_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
huvmat=get(handles.MenuExport_plot,'parent');
UvData=get(huvmat,'UserData');
hfig=figure;
newaxes=copyobj(handles.PlotAxes,hfig);
map=colormap(handles.PlotAxes);
colormap(map);%transmit the current colormap to the zoom fig
colorbar


% --- Executes on selection change in ColorCode.
function ColorCode_Callback(hObject, eventdata, handles)


% --- Executes on selection change in ColorScalar.
function ColorScalar_Callback(hObject, eventdata, handles)


function num_ColCode2_Callback(hObject, eventdata, handles)

