%'stereo_input': function associated with the GUI 'stereo_input.fig' to set the input parameters for stereo_civ
%------------------------------------------------------------------------
% function ParamOut = stereo_input(Param)
%
% OUPUT:
% ParamOut: Matlab structure containing the parameters set by the GUI stereo_input
%
% INPUT:
% Param: Matlab structure containing the input parameters set by the GUI

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function varargout = stereo_input(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @stereo_input_OpeningFcn, ...
    'gui_OutputFcn',  @stereo_input_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);

if nargin && ischar(varargin{1}) && ~isempty(regexp(varargin{1},'_Callback$','once'))
        gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

% End initialization code - DO NOT EDIT

%------------------------------------------------------------------------
% --- Executes just before stereo_input is made visible.
function stereo_input_OpeningFcn(hObject, eventdata, handles, Param)
%------------------------------------------------------------------------
% This function has no output args, see OutputFcn.

%% General settings
handles.output = Param;
guidata(hObject, handles); % Update handles structure
set(hObject,'WindowButtonDownFcn',{'mouse_down'}) % allows mouse action with right button (zoom for uicontrol display)
set(hObject,'WindowKeyPressFcn',{@keyboard_callback,handles})%set keyboard action function
%set(hObject,'KeyPressFcn',{@KeyPressFcn,handles})%set keyboard action function
set(handles.ref_i,'KeyPressFcn',{@ref_i_KeyPressFcn,handles})%set keyboard action function
set(handles.ref_j,'KeyPressFcn',{@ref_i_KeyPressFcn,handles})%set keyboard action function
%set(hObject,'WindowKeyPressFcn',{'keyboard_callback',handles})%set keyboard action function
hseries=findobj(allchild(0),'Tag','series');% find the parent GUI 'series'
hhseries=guidata(hseries); %handles of the elements in 'series'
SeriesData=get(hseries,'UserData');% info stored in the GUI series 

%% set visibility options depending on the calling function (Param.Action.ActionName): 
if strcmp(Param.Action.ActionName,'civ_series')||strcmp(Param.Action.ActionName,'stereo_civ')
     set(handles.num_MaxDiff,'Visible','on')
    set(handles.num_MaxVel,'Visible','on')
    set(handles.title_MaxVel,'Visible','on')
    set(handles.title_MaxDiff,'Visible','on')
    set(handles.num_Nx,'Visible','off')
    set(handles.num_Ny,'Visible','off')
    set(handles.title_Nx,'Visible','off')
    set(handles.title_Ny,'Visible','off')
    set(handles.num_CorrSmooth,'Style','popupmenu')
    set(handles.num_CorrSmooth,'Value',1)
    set(handles.num_CorrSmooth,'String',{'1';'2'})
    set(handles.CheckThreshold,'Visible','on')
    set(handles.CheckDeformation,'Value',0)% desactivate (work in progress)
    %set(handles.CheckDecimal,'Value',0)% desactivate (work in progress)
end
switch Param.Action.ActionName
    case 'stereo_civ'
        set(handles.ListCompareMode,'Visible','off')
        set(handles.PairIndices,'Visible','off')
    case 'civ_series'
        set(handles.ListCompareMode,'Visible','on')
        set(handles.PairIndices,'Visible','on')
end

%% input file info
NomTypeInput=Param.InputTable{1,4};
FileType='image';%fdefault
FileInfo=[];
if isfield(SeriesData,'FileType')&&isfield(SeriesData,'FileInfo')
    FileType=SeriesData.FileType{1};%type of the first input file series
    FileInfo=SeriesData.FileInfo{1};% info on the first input file series
else
    set(hhseries.REFRESH,'BackgroundColor',[1 0 1])% indicate that the file input in series needs to be refreshed 
end

%% case of netcdf file as input, read the processing stage and look for corresponding images
ind_opening=0;%default
NomTypeNc='';
NomTypeImaA=NomTypeInput;
iview_image=1;%line # for the input images
switch FileType
    case {'image','multimage','video','mmreader','cine_phantom','netcdf'}
%         NomTypeImaA=NomTypeInput;
%         iview_image=1;%line # for the input images
    case 'civdata'
        if ~strcmp(Param.Action.ActionName,'civ_series')
            msgbox_uvmat('ERROR','bad input data file: open an image or a nc file from civ_series')
            return
        end
        NomTypeNc=NomTypeInput;
        ind_opening=FileInfo.CivStage;
        if isempty(regexp(NomTypeInput,'[ab|AB|-]', 'once'))
            set(handles.ListCompareMode,'Value',2) %mode displacement advised if the nomencalture does not involve index pairs
        else
            set(handles.ListCompareMode,'Value',1)
        end
        [Data,tild,tild,errormsg]=nc2struct(FileInfo.FileName,[]);
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',['error in netcdf input file: ' errormsg])
            return
        end
        [PathCiv1_ImageA,Civ1_ImageA,FileExtA]=fileparts(Data.Civ1_ImageA);%look for the source image A
        [PathCiv1_ImageB,Civ1_ImageB,FileExtA]=fileparts(Data.Civ1_ImageB);%look for the source image B
        if isfield(Data,'Civ2_ImageA')
            [PathCiv2_ImageA,Civ2_ImageA,FileExtA]=fileparts(Data.Civ2_ImageA);
            [PathCiv2_ImageB,Civ2_ImageB,FileExtA]=fileparts(Data.Civ2_ImageB);
        end
        if size(Param.InputTable,1)==1
            series('display_file_name',hhseries,Data.Civ1_ImageA,'append');%append the image series to the input list
        end
        [RootPath,SubDir,RootFile,i1,i2,j1,j2,FileExt,NomTypeImaA]=fileparts_uvmat(Data.Civ1_ImageA);
        [RootPath,SubDir,RootFile,i1,i2,j1,j2,FileExt,NomTypeImaB]=fileparts_uvmat(Data.Civ1_ImageB);
        iview_image=2;%line # for the input images
    case 'civxdata'% case of  civx data,
        msgbox_uvmat('ERROR','old civX convention, use the GUI civ')
        return
    otherwise 
        msgbox_uvmat('ERROR','civ_series needs images, scalar fields in netcdf format, or civ data as input')
        return
end

%% reinitialise menus
set(handles.ListPairMode,'Value',1)
set(handles.ListPairMode,'String',{''})
set(handles.ListPairCiv1,'Value',1)
set(handles.ListPairCiv1,'String',{''})
set(handles.ListPairCiv2,'Value',1)
set(handles.ListPairCiv2,'String',{''}) 
        
%% prepare the GUI with input parameters 
% 
set(handles.ref_i,'String',num2str(Param.IndexRange.first_i))
if isfield(Param.IndexRange,'first_j')
    set(handles.ref_j,'String',num2str(Param.IndexRange.first_j))
end
set(handles.ConfigSource,'String','\default')

%%  set the menus of image pairs and default selection for stereo_input   %%%%%%%%%%%%%%%%%%%

%% display the min and max indices for the whole file series
if isempty(Param.IndexRange.MaxIndex_i)|| isempty(Param.IndexRange.MinIndex_i)
    msgbox_uvmat('ERROR','REFRESH the input files in the GUI series')
     return
end
MaxIndex_i=Param.IndexRange.MaxIndex_i(iview_image);
MinIndex_i=Param.IndexRange.MinIndex_i(iview_image);
MaxIndex_j=1;%default
MinIndex_j=1;
if isfield(Param.IndexRange,'MaxIndex_j')&&isfield(Param.IndexRange,'MinIndex_j')...
        && numel(Param.IndexRange.MaxIndex_j')>=iview_image &&numel(Param.IndexRange.MinIndex_j')>=iview_image
    MaxIndex_j=Param.IndexRange.MaxIndex_j(iview_image);
    MinIndex_j=Param.IndexRange.MinIndex_j(iview_image);
end
%update the bounds if possible
if isfield(SeriesData,'i1_series')&&numel(SeriesData.i1_series)>=iview_image
    if size(SeriesData.i1_series{iview_image},2)==2 && min(min(SeriesData.i1_series{iview_image}(:,1,:)))==0
        MinIndex_j=1;% index j set to 1 by default
        MaxIndex_j=1;
        MinIndex_i=find(SeriesData.i1_series{iview_image}(1,2,:), 1 )-1;% min ref index i detected in the series (corresponding to the first non-zero value of i1_series, except for zero index)
        MaxIndex_i=find(SeriesData.i1_series{iview_image}(1,2,:),1,'last' )-1;%max ref index i detected in the series (corresponding to the last non-zero value of i1_series)
    else
        ref_i=squeeze(max(SeriesData.i1_series{iview_image}(1,:,:),[],2));% select ref_j index for each ref_i
        ref_j=squeeze(max(SeriesData.j1_series{iview_image}(1,:,:),[],3));% select ref_i index for each ref_j
        MinIndex_i=min(find(ref_i))-1;
        MaxIndex_i=max(find(ref_i))-1;
        MaxIndex_j=max(find(ref_j))-1;
        MinIndex_j=min(find(ref_j))-1;
    end
end
if ~isfield(Param.IndexRange,'first_j')||isequal(MaxIndex_j,MinIndex_j)% no possibility of j pairs
    set(handles.ListPairMode,'Value',1)
    set(handles.ListPairMode,'String',{'series(Di)'})
elseif  MaxIndex_i==1 && MaxIndex_j>1% simple series in j
    set(handles.ListPairMode,'String',{'pair j1-j2';'series(Dj)'})
    if  MaxIndex_j <= 10
        set(handles.ListPairMode,'Value',1)% advice 'pair j1-j2' except in MaxIndex_j is large
    end
else
    set(handles.ListPairMode,'String',{'pair j1-j2';'series(Dj)';'series(Di)'})%multiple choice
    if strcmp(NomTypeNc,'_1-2_1')
        set(handles.ListPairMode,'Value',3)% advise 'series(Di)'
    elseif  MaxIndex_j <= 10
        set(handles.ListPairMode,'Value',1)% advice 'pair j1-j2' except in MaxIndex_j is large
    end
end

%%  transfer the time from the GUI series, or use file index by default
time=[];
TimeUnit='frame'; %default
CoordUnit='';%default
pxcm_search=1;
if isfield(SeriesData,'Time') && ~isempty(SeriesData.Time{1})
    time=SeriesData.Time{1};
end
if isfield(Param.IndexRange,'TimeUnit')&&~isempty(Param.IndexRange.TimeUnit)
    TimeUnit=Param.IndexRange.TimeUnit;
end
% if isfield(SeriesData,'TimeSource')
%     set(handles.TimeSource,'String',SeriesData.TimeSource)
% end  
if isfield(SeriesData,'GeometryCalib')
    tsai=SeriesData.GeometryCalib;
    if isfield(tsai,'fx_fy')
        pxcm_search=max(tsai.fx_fy(1),tsai.fx_fy(2));%pixels:cm estimated for the search range
    end
    if isfield(tsai,'CoordUnit')
        CoordUnit=tsai.CoordUnit;
    end
end

%% timing display
%show the reference image edit box if relevant (not needed for movies or in the absence of time information
if numel(time)>=2 % if there are at least two time values to define dt
    if size(time,1)<MaxIndex_i
        msgbox_uvmat('WARNING','maximum i index restricted by the timing of the xml file');
    elseif size(time,2)<MaxIndex_j
        msgbox_uvmat('WARNING','maximum j index restricted by the timing of the xml file');
    end
    MaxIndex_i=min(size(time,1),MaxIndex_i);%possibly adjust the max index according to time data
    MaxIndex_j=min(size(time,2),MaxIndex_j);
    set(handles.TimeSource,'String',Param.IndexRange.TimeSource);
else
    set(handles.TimeSource,'String',''); %xml file not used for timing
    TimeUnit='frame';
    time=ones(MaxIndex_j-MinIndex_j+1,1)*(MinIndex_i:MaxIndex_i);
    time=time+0.001*(MinIndex_j:MaxIndex_j)'*ones(1,MaxIndex_i-MinIndex_i+1);
end
CivInputData.Time=time;
CivInputData.NomTypeIma=NomTypeImaA;
set(handles.civ_input,'UserData',CivInputData)
set(handles.dt_unit,'String',['dt in m' TimeUnit]);%display dt in unit 10-3 of the time (e.g ms)
set(handles.TimeUnit,'String',TimeUnit);
%set(handles.CoordUnit,'String',CoordUnit)
set(handles.SearchRange,'UserData', pxcm_search);

% indicate the min and max indices i and j on the GUI
set(handles.MinIndex_i,'String',num2str(MinIndex_i))
set(handles.MaxIndex_i,'String',num2str(MaxIndex_i))
set(handles.MinIndex_j,'String',num2str(MinIndex_j))
set(handles.MaxIndex_j,'String',num2str(MaxIndex_j))


%% set the stereo_input options, depending on the input file content if a nc file has been opened
ListOptions={'CheckCiv1', 'CheckFix1' 'CheckPatch1', 'CheckCiv2', 'CheckFix2', 'CheckPatch2', 'CheckCiv3', 'CheckFix3', 'CheckPatch3'};
checkbox=zeros(size(ListOptions));%default
checkrefresh=0;
if ind_opening==0  %case of image opening, start with Civ1
    for index=1:numel(ListOptions)
        checkbox(index)=get(handles.(ListOptions{index}),'Value');
    end
    index_max=find(checkbox, 1, 'last' );
    if isempty(index_max),index_max=1;end
    for index=1:index_max
        set(handles.(ListOptions{index}),'Value',1)% select all operations starting from CIV1
    end
else  %case of netcdf file opening, start with the stage read in the file if the input file is being refreshed
    if isequal(get(hhseries.REFRESH,'BackgroundColor'),[1 1 0]) &&...
            ~(isfield(Param,'ActionInput') && isfield(Param.ActionInput,'ConfigSource')) 
%         answer=msgbox_uvmat('INPUT_Y-N',['import the civ parameters from the netcdf file']);
%         if strcmp(answer,'Yes')
            for index = 1:min(ind_opening,5)
                set(handles.(ListOptions{index}),'value',0)
                fill_civ_input(Data,handles); %fill civ_input with the parameters retrieved from an input Civ file
            end
            set(handles.ConfigSource,'String',FileInfo.FileName);
            set(handles.(ListOptions{min(ind_opening+1,6)}),'value',1)
            for index = ind_opening+2:6
                set(handles.(ListOptions{index}),'value',0)
            end
            checkrefresh=1;
%         end
    end
    if ind_opening>=3
        set(handles.CheckCiv3,'Visible','on')% make visible the switch 'iterate/repet' for Civ2.
    else
        set(handles.CheckCiv3,'Visible','off')
    end
end

%% introduce the stored Civ parameters  if available (from previous input or ImportConfig in series)
if ~checkrefresh && isfield(Param,'ActionInput')&& strcmp(Param.ActionInput.Program,Param.Action.ActionName)% the program fits with the stored data
    fill_GUI(Param.ActionInput,hObject);%fill the GUI with the parameters retrieved from the input Param
    hcheckgrid=findobj(handles.civ_input,'Tag','CheckGrid');
    for ilist=1:numel(hcheckgrid)
        if get(hcheckgrid(ilist),'Value')% if a grid is used, do not show Dx and Dy for an automatic grid
            hparent=get(hcheckgrid(ilist),'parent');%handles of the parent panel
            hchildren=get(hparent,'children');
            handle_dx=findobj(hchildren,'tag','num_Dx');
            handle_dy=findobj(hchildren,'tag','num_Dy');
            handle_title_dx=findobj(hchildren,'tag','title_Dx');
            handle_title_dy=findobj(hchildren,'tag','title_Dy');
            set(handle_dx,'Visible','off');
            set(handle_dy,'Visible','off');
            set(handle_title_dy,'Visible','off');
            set(handle_title_dx,'Visible','off');
        end
    end
end

%% set the reference indices from the input file indices
ind_opening=9;
% if ~(isfield(Param,'ActionInput') && isfield(Param.ActionInput,'ConfigSource'))
update_CivOptions(handles,ind_opening)% fill the menu of possible pairs
% % end

%% list the possible index pairs, depending on the option set in ListPairMode
ListPairMode_Callback([], [], handles)
ListPairCiv1_Callback(hObject, eventdata, handles)

%% set the GUI to modal: wait for OK to close
set(handles.civ_input,'WindowStyle','modal')% Make the GUI modal

set(handles.Civ3,'Visible','on')
set(handles.Fix3,'Visible','on')
set(handles.Patch3,'Visible','on')


drawnow
uiwait(handles.civ_input);% wait for OK action to end the function


%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = stereo_input_OutputFcn(hObject, eventdata, handles)
%------------------------------------------------------------------------
% Get default command line output from handles structure
varargout{1}=[];% default output when civ_input is canceled (no 'OK')
if ~isempty(handles)
    varargout{1} = handles.output;
    delete(handles.civ_input)
end

% --- Executes when user attempts to close get_field.
function civ_input_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(handles.get_field, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(handles.civ_input);
else
    % The GUI is no longer waiting, just close it
    delete(handles.civ_input);
end

%------------------------------------------------------------------------
% --- Executes on button press in SetDefaultParam.
%------------------------------------------------------------------------
function SetDefaultParam_Callback(hObject, eventdata, handles)

Param.ConfigSource='\default';

%% Civ1 parameters
Param.Civ1.CorrBoxSize=[25 25];
Param.Civ1.SearchBoxSize=[55 55];
Param.Civ1.SearchBoxShift=[0 0];
Param.Civ1.CorrSmooth=1;
Param.Civ1.Dx=20;
Param.Civ1.Dy=20;
Param.Civ1.CheckGrid=0;
Param.Civ1.CheckMask=0;
Param.Civ1.CheckThreshold=0;
Param.Civ1.TestCiv1=0;

%% Fix1 parameters
Param.Fix1.CheckFmin2=1;
Param.Fix1.CheckF3=1;
Param.Fix1.MinCorr=0.2000;

%% Patch1 parameters
Param.Patch1.FieldSmooth=10;
Param.Patch1.MaxDiff=1.5000;
Param.Patch1.SubDomainSize=1000;
Param.Patch1.TestPatch1=0;

%% Civ2 parameters
Param.Civ2.CorrBoxSize=[21 21];
Param.Civ2.SearchBoxSize=[27 27];
Param.Civ2.CorrSmooth=1;
Param.Civ2.Dx=10;
Param.Civ2.Dy=10;
Param.Civ2.CheckGrid=0;
Param.Civ2.CheckMask=0;
Param.Civ2.CheckThreshold=0;
Param.Civ2.TestCiv2=0;

%% Fix2 parameters
Param.Fix2.CheckFmin2=1;
Param.Fix2.CheckF4=1;
Param.Fix2.CheckF3=1;
Param.Fix2.MinCorr=0.2000;

%% Patch2 parameters
Param.Patch2.FieldSmooth=2;
Param.Patch2.MaxDiff=1.5000;
Param.Patch2.SubDomainSize=1000;
Param.Patch2.TestPatch2=0;

fill_GUI(Param,handles.civ_input)% fill the elements of the GUI series with the input parameters

% -----------------------------------------------------------------------
% -----------------------------------------------------------------------
% --- Open the help html file 
function MenuHelp_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
web('http://servforge.legi.grenoble-inp.fr/projects/soft-uvmat/wiki/UvmatHelp#Civ')

%------------------------------------------------------------------------
% --- Executes on carriage return on the subdir checkciv1 edit window
function Civ1_ImageB_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
SubDir=get(handles.Civ1_ImageB,'String');
menu_str=get(handles.ListSubdirCiv1,'String');% read the list of subdirectories for update
ichoice=find(strcmp(SubDir,menu_str),1);
if isempty(ichoice)
    ilist=numel(menu_str); %select 'new...' in the menu
else
    ilist=ichoice;
end
set(handles.ListSubdirCiv1,'Value',ilist)% select the selected subdir in the menu
if get(handles.CheckCiv1,'Value')% if Civ1 is performed
    set(handles.Civ2_ImageA,'String',SubDir);% set by default civ2 directory the same as civ1 
%     set(handles.ListSubdirCiv2,'Value',ilist)
else % if Civ1 data already exist
    errormsg=find_netcpair_civ(handles,1); %update the list of available index pairs in the new directory
    if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end
end

%------------------------------------------------------------------------
% --- Executes on carriage return on the SubDir checkciv1 edit window
function Civ2_ImageA_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
SubDir=get(handles.Civ1_ImageB,'String');
menu_str=get(handles.ListSubdirCiv2,'String');% read the list of subdirectories for update
ichoice=find(strcmp(SubDir,menu_str),1);
if isempty(ichoice)
    ilist=numel(menu_str); %select 'new...' in the menu
else
    ilist=ichoice;
end
set(handles.ListSubdirCiv2,'Value',ilist)% select the selected subdir in the menu
%update the list of available pairs from netcdf files in the new directory
if ~get(handles.CheckCiv2,'Value') && ~get(handles.CheckCiv1,'Value') && ~get(handles.CheckFix1,'Value') && ~get(handles.CheckPatch1,'Value')
    errormsg=find_netcpair_civ(handles,2);
        if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckCiv1.
function CheckCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% update_CivOptions(handles,0)
if get(hObject,'Value')==1
 set(handles.Civ1,'Visible','on')
else
     set(handles.Civ1,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckFix1.
function CheckFix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% update_CivOptions(handles,0)
if get(hObject,'Value')==1
 set(handles.Fix1,'Visible','on')
else
     set(handles.Fix1,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch1.
function CheckPatch1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% update_CivOptions(handles,0)
if get(hObject,'Value')==1
 set(handles.Patch1,'Visible','on')
else
     set(handles.Patch1,'Visible','off')
end
%------------------------------------------------------------------------
% --- Executes on button press in CheckCiv2.
function CheckCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% update_CivOptions(handles,0)
if get(hObject,'Value')==1
 set(handles.Civ2,'Visible','on')
else
     set(handles.Civ2,'Visible','off')
end
%------------------------------------------------------------------------
% --- Executes on button press in CheckFix2.
function CheckFix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% update_CivOptions(handles,0)
if get(hObject,'Value')==1
 set(handles.Fix2,'Visible','on')
else
     set(handles.Fix2,'Visible','off')
end
%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch2.
function CheckPatch2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%update_CivOptions(handles,0)
if get(hObject,'Value')==1
 set(handles.Patch2,'Visible','on')
else
     set(handles.Patch2,'Visible','off')
end
%------------------------------------------------------------------------
% --- Executes on button press in CheckCiv3.
function CheckCiv3_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% update_CivOptions(handles,0)
if get(hObject,'Value')==1
 set(handles.Civ3,'Visible','on')
else
     set(handles.Civ3,'Visible','off')
end
%------------------------------------------------------------------------
% --- Executes on button press in CheckFix3.
function CheckFix3_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
% update_CivOptions(handles,0)
if get(hObject,'Value')==1
 set(handles.Fix3,'Visible','on')
else
     set(handles.Fix3,'Visible','off')
end
%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch3.
function CheckPatch3_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%update_CivOptions(handles,0)
if get(hObject,'Value')==1
 set(handles.Patch3,'Visible','on')
else
     set(handles.Patch3,'Visible','off')
end
%------------------------------------------------------------------------

% --- activated by any checkbox controling the selection of Civ1,Fix1,Patch1,Civ2,Fix2,Patch2
function update_CivOptions(handles,opening)
%------------------------------------------------------------------------
% if opening>0
%     set(handles.CheckCiv2,'UserData',opening)% store the info on the current status of the civ processing
% % end
% checkbox=zeros(1,9);
% checkbox(1)=get(handles.CheckCiv1,'Value');
% checkbox(2)=get(handles.CheckFix1,'Value');
% checkbox(3)=get(handles.CheckPatch1,'Value');
% checkbox(4)=get(handles.CheckCiv2,'Value');
% checkbox(5)=get(handles.CheckFix2,'Value');
% checkbox(6)=get(handles.CheckPatch2,'Value');
% checkbox(7)=get(handles.CheckCiv3,'Value');
% checkbox(8)=get(handles.CheckFix3,'Value');
% checkbox(9)=get(handles.CheckPatch3,'Value');
% if opening==0
%     errormsg=find_netcpair_civ(handles,1); % select the available netcdf files
%     if ~isempty(errormsg)
%         msgbox_uvmat('ERROR',errormsg)
%     end
% end
% if max(checkbox(4:6))>0% case of civ2 pair choice needed
%     set(handles.TitlePairCiv2,'Visible','on')
%     set(handles.ListPairCiv2,'Visible','on')
%     if ~opening
%         errormsg=find_netcpair_civ(handles,2); % select the available netcdf files
%         if ~isempty(errormsg)
%             msgbox_uvmat('ERROR',errormsg)
%         end
%     end
% else
%     set(handles.ListPairCiv2,'Visible','off')
% end
% 
% 
% %% set the visibility of the different panels
% options={'Civ1','Fix1','Patch1','Civ2','Fix2','Patch2','Civ3','Fix3','Patch3'};
% for ilist=1:length(options)
% %     if checkbox(ilist)
%         set(handles.(options{ilist}),'Visible','on')
% %     else
% %         set(handles.(options{ilist}),'Visible','off')
% %     end
% end

%------------------------------------------------------------------------
% --- Executes on button press in OK: processing on local computer
function OK_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

ActionInput=read_GUI(handles.civ_input);% read the infos on the GUI civ_input

%% correct input inconsistencies
if isfield(ActionInput,'Civ1')
    checkeven=(mod(ActionInput.Civ1.CorrBoxSize,2)==0);
    ActionInput.Civ1.CorrBoxSize(checkeven)=ActionInput.Civ1.CorrBoxSize(checkeven)+1;% set correlation box sizes to odd values
    ActionInput.Civ1.SearchBoxSize=max(ActionInput.Civ1.SearchBoxSize,ActionInput.Civ1.CorrBoxSize+8);% insure that the search box size is large enough
    checkeven=(mod(ActionInput.Civ1.SearchBoxSize,2)==0);
    ActionInput.Civ1.SearchBoxSize(checkeven)=ActionInput.Civ1.SearchBoxSize(checkeven)+1;% set search box sizes to odd values
end
if isfield(ActionInput,'Civ2')
    checkeven=(mod(ActionInput.Civ2.CorrBoxSize,2)==0);
    ActionInput.Civ2.CorrBoxSize(checkeven)=ActionInput.Civ2.CorrBoxSize(checkeven)+1;% set correlation box sizes to odd values
    ActionInput.Civ2.SearchBoxSize=max(ActionInput.Civ2.SearchBoxSize,ActionInput.Civ2.CorrBoxSize+4);
    checkeven=(mod(ActionInput.Civ2.SearchBoxSize,2)==0);
    ActionInput.Civ2.SearchBoxSize(checkeven)=ActionInput.Civ2.SearchBoxSize(checkeven)+1;% set search box sizes to odd values
end

%% correct mask or grid name for Windows system (replace '\' by '/')
if isfield(ActionInput,'Civ1')
    if isfield(ActionInput.Civ1,'Mask')
        ActionInput.Civ1.Mask=regexprep(ActionInput.Civ1.Mask,'\','/');
    end
    if isfield(ActionInput.Civ1,'Grid')
        ActionInput.Civ1.Grid=regexprep(ActionInput.Civ1.Grid,'\','/');
    end
end
if isfield(ActionInput,'Civ2')
    if isfield(ActionInput.Civ2,'Mask')
        ActionInput.Civ2.Mask=regexprep(ActionInput.Civ2.Mask,'\','/');
    end
    if isfield(ActionInput.Civ2,'Grid')
        ActionInput.Civ2.Grid=regexprep(ActionInput.Civ2.Grid,'\','/');
    end
end

%% exit the GUI and close it
handles.output.ActionInput=ActionInput;
guidata(hObject, handles);% Update handles structure
uiresume(handles.civ_input);


%------------------------------------------------------------------------
% --- Executes on button press in ListCompareMode.
function ListCompareMode_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
ListCompareMode=get(handles.ListCompareMode,'String');
option=ListCompareMode{get(handles.ListCompareMode,'Value')};
hseries=findobj(allchild(0),'Tag','series');
SeriesData=get(hseries,'UserData');
check_nc=strcmp(SeriesData.FileType{1},'.nc');
ImageType=SeriesData.FileType(2:end);
if check_nc
    ImageType=SeriesData.FileType(2:end);
else
    ImageType=SeriesData.FileType;
end
hhseries=guidata(hseries);
InputTable=get(hhseries.InputTable,'Data');
OriginIndex='off';
PairIndices='off';
DoubleInputSeries='off';
switch option
    case 'PIV'
        PairIndices='on';% needs to define index pairs for PIV
        
    case 'PIV volume'
        PairIndices='on';% needs to define index pairs for PIV
        set(handles.ListPairMode,'Value',1)
        set(handles.ListPairMode,'String',{'series(Di)'})
        ListPairMode_Callback(hObject, eventdata, handles)
    case 'displacement'
        OriginIndex='on';%define a frame origin for displacement
%     case 'shift'
%         if numel(ImageType)==1
%             fileinput=uigetfile_uvmat('pick a second file series for synchronous shift',InputTable{check_nc+1});
%             if ~isempty(fileinput)
%                 series( 'display_file_name',hhseries,fileinput,'append')
%             end
%             
%             
%         end
end
set(handles.num_OriginIndex,'Visible',OriginIndex)
set(handles.OriginIndex_title,'Visible',OriginIndex)
set(handles.PairIndices,'Visible',PairIndices)
ListPairMode_Callback(hObject, eventdata, handles)
        


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Pair Indices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in ListPairMode.
function ListPairMode_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
compare_list=get(handles.ListCompareMode,'String');
val=get(handles.ListCompareMode,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')||strcmp(compare,'shift')
    mode='displacement';
else
    mode_list=get(handles.ListPairMode,'String');
    if ischar(mode_list)
        mode_list={mode_list};
    end
    mode_value=get(handles.ListPairMode,'Value');
    mode=mode_list{mode_value};
end
% displ_num=[];%default
ref_i=str2double(get(handles.ref_i,'String'));
% last_i=str2num(get(handles.last_i,'String'));
CivInputData=get(handles.civ_input,'UserData');
TimeUnit=get(handles.TimeUnit,'String');
checkframe=strcmp(TimeUnit,'frame');
time=CivInputData.Time;
siztime=size(CivInputData.Time);
nbfield=siztime(1)-1;
nbfield2=siztime(2)-1;
indchosen=1;  %%first pair selected by default
%displ_num used to define the indices of the stereo_input pairs
% in mode 'pair j1-j2', j1 and j2 are the file indices, else the indices
% are relative to the reference indices ref_i and ref_j respectively.
if isequal(mode,'pair j1-j2')%| isequal(mode,'st_pair j1-j2')
    dt=1;
    displ='';
    index=0;
    numlist_a=[];
    numlist_B=[];
    %get all the time intervals in bursts
    displ_dt=1;%default
    nbfield2=min(nbfield2,10);%limitate the number of pairs to 10x10
    for numod_a=1:nbfield2-1 %nbfield2 always >=2 for 'pair j1-j2' mode
        for numod_b=(numod_a+1):nbfield2
            index=index+1;
            numlist_a(index)=numod_a;
            numlist_b(index)=numod_b;
            if size(time,2)>1 && ~checkframe
                dt(numod_a,numod_b)=CivInputData.Time(ref_i+1,numod_b+1)-CivInputData.Time(ref_i+1,numod_a+1);%first time interval dt
                displ_dt(index)=dt(numod_a,numod_b);
            else
                displ_dt(index)=1;
            end
        end
    end
    [dtsort,indsort]=sort(displ_dt);
    if ~isempty(numlist_a)
        displ_num(1,:)=numlist_a(indsort);
        displ_num(2,:)=numlist_b(indsort);
    end
    displ_num(3,:)=0;
    displ_num(4,:)=0;
    enable_j(handles, 'off')
elseif isequal(mode,'series(Dj)') %| isequal(mode,'st_series(Dj)')
    index=1:200;
    displ_num(1,index)=-floor(index/2);
    displ_num(2,index)=ceil(index/2);
    displ_num(3:4,index)=zeros(2,200);
    enable_j(handles, 'on')
elseif isequal(mode,'series(Di)') %| isequal(mode,'st_series(Di)')
%     index=1:200;
%     displ_num(1:2,index)=zeros(2,200);
%     displ_num(3,index)=-floor(index/2);
%     displ_num(4,index)=ceil(index/2);
    enable_i(handles, 'on')
    if nbfield2 > 1
        enable_j(handles, 'on')
    else
        enable_j(handles, 'off')
    end
elseif isequal(mode,'displacement')%the pairs have the same indices
    displ_num(1,1)=0;
    displ_num(2,1)=0;
    displ_num(3,1)=0;
    displ_num(4,1)=0;
    if nbfield > 1 || nbfield==0
        enable_i(handles, 'on')
    else
        enable_j(handles, 'off')
    end
    if nbfield2 > 1
        enable_j(handles, 'on')
    else
        enable_j(handles, 'off')
    end
end
%set(handles.ListPairCiv1,'UserData',displ_num);
errormsg=find_netcpair_civ( handles,1);
    if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end
% find_netcpair_civ2(handles)

function enable_i(handles, state)
set(handles.itext,'Visible',state)
% set(handles.MinIndex_i,'Visible',state)
% set(handles.last_i,'Visible',state)
% set(handles.incr_i,'Visible',state)
set(handles.MaxIndex_i,'Visible',state)
set(handles.ref_i,'Visible',state)

function enable_j(handles, state)
set(handles.jtext,'Visible',state)
% set(handles.MinIndex_j,'Visible',state)
% set(handles.last_j,'Visible',state)
% set(handles.incr_j,'Visible',state)
set(handles.MinIndex_j,'Visible',state)
set(handles.MaxIndex_j,'Visible',state)
set(handles.ref_j,'Visible',state)
%hseries=findobj(allchild(0),'Tag','series');
%hhseries=guidata(hseries);
%series('enable_j',hhseries,state); %file input with xml reading  in uvmat, show the image in phys coordinates



%------------------------------------------------------------------------
% --- Executes on selection change in ListPairCiv1.
function ListPairCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%reproduce by default the chosen pair in the checkciv2 menu
list_pair=get(handles.ListPairCiv1,'String');%get the menu of image pairs
PairString=list_pair{get(handles.ListPairCiv1,'Value')};

[ind1,ind2]=...
    find_pair_indices(PairString);
hseries=findobj(allchild(0),'Tag','series');
hhseries=guidata(hseries);
set(hhseries.num_first_j,'String',num2str(ind1));
set(hhseries.num_last_j,'String',num2str(ind2));
set(hhseries.num_incr_j,'String',num2str(ind2-ind1));
set(handles.ListPairCiv2,'Value',get(handles.ListPairCiv1,'Value'))%civ2 selection the same as civ& by default


%------------------------------------------------------------------------
% --- Executes on selection change in ListPairCiv2.
function ListPairCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------


%------------------------------------------------------------------------
function ref_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.ListPairMode,'String');
mode_value=get(handles.ListPairMode,'Value');
mode=mode_list{mode_value};
errormsg=find_netcpair_civ(handles,1);% update the menu of pairs depending on the available netcdf files
if isequal(mode,'series(Di)') || ...% we do patch2 only
        (get(handles.CheckCiv2,'Value')==0 && get(handles.CheckCiv1,'Value')==0 && get(handles.CheckFix1,'Value')==0 && get(handles.CheckPatch1,'Value')==0)
    errormsg=find_netcpair_civ( handles,2);
end
if isempty(errormsg)
    set(handles.ref_i,'BackgroundColor',[1 1 1])
    set(handles.ref_j,'BackgroundColor',[1 1 1])
else
    msgbox_uvmat('ERROR',errormsg)
end

function ref_i_KeyPressFcn(hObject, eventdata, handles)
set(hObject,'BackgroundColor',[1 0 1])
        
% %------------------------------------------------------------------------
% function ref_j_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% mode_list=get(handles.ListPairMode,'String');
% mode_value=get(handles.ListPairMode,'Value');
% mode=mode_list{mode_value};
% errormsg='';
% if isequal(get(handles.CheckCiv1,'Value'),0)|| isequal(mode,'series(Dj)')
%     errormsg=find_netcpair_civ(handles,1);% update the menu of pairs depending on the available netcdf files
% end
% if isequal(mode,'series(Dj)') || ...
%         (get(handles.CheckCiv2,'Value')==0 && get(handles.CheckCiv1,'Value')==0 && get(handles.CheckFix1,'Value')==0 && get(handles.CheckPatch1,'Value')==0)
%     errormsg=find_netcpair_civ(handles,2);
% end
% if ~isempty(errormsg)
%     msgbox_uvmat('ERROR',errormsg)
% end
% 
% function ref_j_KeyPressFcn(hObject, eventdata, handles)
% set(handles.ref_j,'BackgroundColor',[1 0 1])
%------------------------------------------------------------------------
% determine the menu for checkciv1 pairs depending on existing netcdf file at the middle of
% the field series set by MinIndex_i, incr, last_i
% index=1: look for pairs for civ1
% index=2: look for pairs for civ2
function errormsg=find_netcpair_civ(handles,index)
%------------------------------------------------------------------------
set(gcf,'Pointer','watch')% set the mouse pointer to 'watch' (clock)

%% initialisation
errormsg='';
CivInputData=get(handles.civ_input,'UserData');
%browse=get(handles.RootPath,'UserData');
compare_list=get(handles.ListCompareMode,'String');
val=get(handles.ListCompareMode,'Value');
compare=compare_list{val};
if strcmp(compare,'displacement')||strcmp(compare,'shift')
    mode='displacement';
else
    mode_list=get(handles.ListPairMode,'String');
    mode_value=get(handles.ListPairMode,'Value');
    if isempty(mode_list)
        return
    end
    mode=mode_list{mode_value};
end
nom_type_ima=CivInputData.NomTypeIma;

%% determine nom_type_nc, nomenclature type of the .nc files:
%[nom_type_nc]=nomtype2pair(nom_type_ima,mode);

%% reads .nc subdirectoy and image numbers from the interface
%SubDirImages=get(handles.Civ1_ImageA,'String');
%TODO: determine
%subdir_civ1=[SubDirImages get(handles.Civ1_ImageB,'String')];%subdirectory subdir_civ1 for the netcdf data
%subdir_civ2=[SubDirImages get(handles.Civ2_ImageA,'String')];%subdirectory subdir_civ2 for the netcdf data
ref_i=str2double(get(handles.ref_i,'String'));
ref_j=[];
if isequal(mode,'pair j1-j2')%|isequal(mode,'st_pair j1-j2')
    ref_j=0;
elseif strcmp(get(handles.ref_j,'Visible'),'on')
    ref_j=str2double(get(handles.ref_j,'String'));
end
if isempty(ref_j)
    ref_j=1;
end
CivInputData=get(handles.civ_input,'UserData');
TimeUnit=get(handles.TimeUnit,'String');
Time=CivInputData.Time;
checkframe=strcmp(TimeUnit,'frame');

%% case with no Civ1 operation, netcdf files need to exist for reading
displ_pair={''};
nbpair=200;%default
select=ones(size(1:nbpair));%flag for displayed pairs =1 for display
nbpair=200; %default

%% determine the menu display in .ListPairCiv1
switch mode
    case 'series(Di)'
        for ipair=1:nbpair
            if select(ipair)
                displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2))];
                if ~checkframe
                    if size(Time,1)>=ref_i+1+ceil(ipair/2) && size(Time,2)>=ref_j+1&& ref_i-floor(ipair/2)>=0 && ref_j>=0
                        dt=Time(ref_i+1+ceil(ipair/2),ref_j+1)-Time(ref_i+1-floor(ipair/2),ref_j+1);%Time interval dtref_j+1
                        displ_pair{ipair}=[displ_pair{ipair} ' :dt= ' num2str(dt*1000)];
                    end
                else
                    dt=ipair/1000;
                    displ_pair{ipair}=[displ_pair{ipair} ' :dt= ' num2str(ipair)];
                end
            else
                displ_pair{ipair}='...'; %pair not displayed in the menu
            end
        end
    case 'series(Dj)'
        for ipair=1:nbpair
            if select(ipair)
                displ_pair{ipair}=['Dj= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2))];
                if ~checkframe
                    if size(Time,2)>=ref_j+1+ceil(ipair/2) && size(Time,1)>=ref_i+1 && ref_j-floor(ipair/2)>=0 && ref_i>=0
                        dt=Time(ref_i+1,ref_j+1+ceil(ipair/2))-Time(ref_i+1,ref_j+1-floor(ipair/2));%Time interval dtref_j+1
                        displ_pair{ipair}=[displ_pair{ipair} ' :dt= ' num2str(dt*1000)];
                    end
                else
                    dt=ipair/1000;
                    displ_pair{ipair}=[displ_pair{ipair} ' :dt= ' num2str(dt*1000)];
                end
            else
                displ_pair{ipair}='...'; %pair not displayed in the menu
            end
        end
    case 'pair j1-j2'%case of pairs
%         MinIndex_j=CivInputData.MinIndex_j;
%         MaxIndex_j=min(CivInputData.MaxIndex_j,10);%limitate the number of pairs to 10x10
        MinIndex_j=str2num(get(handles.MinIndex_j,'String'));
        MaxIndex_j=str2num(get(handles.MaxIndex_j,'String'));
        index_pair=0;
        %get all the Time intervals in bursts
        for numod_a=MinIndex_j:MaxIndex_j-1 %nbfield2 always >=2 for 'pair j1-j2' mode
            for numod_b=(numod_a+1):MaxIndex_j
                index_pair=index_pair+1;
                displ_pair{index_pair}=['j= ' num2stra(numod_a,nom_type_ima) '-' num2stra(numod_b,nom_type_ima)];
                dt(index_pair)=numod_b-numod_a;%default dt
                if size(Time,1)>ref_i && size(Time,2)>numod_b  % && ~checkframe
                    dt(index_pair)=Time(ref_i+1,numod_b+1)-Time(ref_i+1,numod_a+1);% Time interval dt
                    displ_pair{index_pair}=[displ_pair{index_pair} ' :dt= ' num2str(dt(index_pair)*1000)];
                end
            end
            
        end
        [tild,indsort]=sort(dt);
        displ_pair=displ_pair(indsort);
    case 'displacement'
        displ_pair={'Di=Dj=0'};
end
if index==1
    set(handles.ListPairCiv1,'String',displ_pair');
end

%% determine the default selection in the pair menu for Civ1
ichoice=find(select,1);% index of first selected pair
if (isempty(ichoice) || ichoice < 1); ichoice=1; end;
initial=get(handles.ListPairCiv1,'Value');%initial choice of pair
if initial>nbpair || (numel(select)>=initial && ~isequal(select(initial),1))
    set(handles.ListPairCiv1,'Value',ichoice);% first valid pair proposed by default in the menu
end

%% determine the default selection in the pair menu for Civ2
if strcmp(get(handles.ListPairCiv2,'Visible'),'on')
    initial=get(handles.ListPairCiv2,'Value');
    if initial>length(displ_pair')%|~isequal(select(initial),1)
        if ichoice <= length(displ_pair')
            set(handles.ListPairCiv2,'Value',ichoice);% same pair proposed by default for civ2
        else
            set(handles.ListPairCiv2,'Value',1);% same pair proposed by default for civ2
        end
    end
else
    set(handles.ListPairCiv2,'Value',get(handles.ListPairCiv1,'Value'))% initiate the choice of Civ2 as a reproduction of if civ1
end
set(handles.ListPairCiv2,'String',displ_pair');
set(gcf,'Pointer','arrow')% Indicate that the process is finished


    
% %------------------------------------------------------------------------   
% % call 'view_field.fig' to display the  field selected in the list of 'status'
% function open_view_field(hObject, eventdata)
% %------------------------------------------------------------------------
% list=get(hObject,'String');
% index=get(hObject,'Value');
% rootroot=get(hObject,'UserData');
% filename=list{index};
% ind_dot=strfind(filename,'...');
% filename=filename(1:ind_dot-1);
% filename=fullfile(rootroot,filename);
% delete(get(hObject,'parent'))%delete the display figure to stop the check process
% if exist(filename,'file')%visualise the vel field if it exists
%     uvmat(filename)
%     set(gcbo,'Value',1)
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Reference Indices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
function MinIndex_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
first_i=str2double(get(handles.MinIndex_i,'String'));
set(handles.ref_i,'String', num2str(first_i))% reference index for pair dt = first index
ref_i_Callback(hObject, eventdata, handles)%refresh dispaly of dt for pairs (in case of non constant dt)

% %------------------------------------------------------------------------
% function MinIndex_j_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% first_j=str2num(get(handles.MinIndex_j,'String'));
% set(handles.ref_j,'String', num2str(first_j))% reference index for pair dt = first index
% ref_j_Callback(hObject, eventdata, handles)%refresh dispaly of dt for pairs (in case of non constant dt)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Civ1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in SearchRange: determine the search range num_SearchBoxSize_1,num_SearchBoxSize_2
function SearchRange_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%determine pair numbers
if strcmp(get(handles.num_UMin,'Visible'),'off')
    set(handles.u_title,'Visible','on')
    set(handles.v_title,'Visible','on')
    set(handles.num_UMin,'Visible','on')
    set(handles.num_UMax,'Visible','on')
    set(handles.num_VMin,'Visible','on')
    set(handles.num_VMax,'Visible','on')
    %set(handles.CoordUnit,'Visible','on')
    %set(handles.TimeUnit,'Visible','on')
    %set(handles.slash_title,'Visible','on')
    set(handles.min_title,'Visible','on')
    set(handles.max_title,'Visible','on')
    set(handles.unit_title,'Visible','on')
else
    get_search_range(hObject, eventdata, handles)
end

%------------------------------------------------------------------------
% ---  determine the search range num_SearchBoxSize_1,num_SearchBoxSize_2 and shift
function get_search_range(hObject, eventdata, handles)
%------------------------------------------------------------------------
param_civ1=read_GUI(handles.Civ1);
umin=param_civ1.UMin;
umax=param_civ1.UMax;
vmin=param_civ1.VMin;
vmax=param_civ1.VMax;
%switch min_title and max_title in case of error
if umax<=umin
    umin_old=umin;
    umin=umax;
    umax=umin_old;
    set(handles.num_UMin,'String', num2str(umin))
    set(handles.num_UMax,'String', num2str(umax))
end
if vmax<=vmin
    vmin_old=vmin;
    vmin=vmax;
    vmax=vmin_old;
    set(handles.num_VMin,'String', num2str(vmin))
    set(handles.num_VMax,'String', num2str(vmax))
end   
if ~(isempty(umin)||isempty(umax)||isempty(vmin)||isempty(vmax))
%     list_pair=get(handles.ListPairCiv1,'String');%get the menu of image pairs
%     index=get(handles.ListPairCiv1,'Value');
%     pair_string=list_pair{index};
%     time=get(handles.TimeSource,'UserData'); %get the set of times
%     pxcm=get(handles.SearchRange,'UserData');
%     mode_list=get(handles.ListPairMode,'String');
%     mode_value=get(handles.ListPairMode,'Value');
%     mode=mode_list{mode_value};      
%     if isequal (mode, 'series(Di)' )
%         ref_i=str2double(get(handles.ref_i,'String'));
%         num1=ref_i-floor(index/2);%  first image numbers
%         num2=ref_i+ceil(index/2);
%         num_a=1;
%         num_b=1;
%     elseif isequal (mode, 'series(Dj)')
%         num1=1;
%         num2=1;
%         ref_j=str2double(get(handles.ref_j,'String'));
%         num_a=ref_j-floor(index/2);%  first image numbers
%         num_b=ref_j+ceil(index/2);
%     elseif isequal(mode,'pair j1-j2') %case of bursts (png_old or png_2D)     
%         ref_i=str2double(get(handles.ref_i,'String'));
%         num1=ref_i;
%         num2=ref_i;
%                 r=regexp(pair_string,'(?<mode>(Di=)|(Dj=)) -*(?<num1>\d+)\|(?<num2>\d+)','names');
%         if isempty(r)
%             r=regexp(pair_string,'(?<num1>\d+)(?<mode>-)(?<num2>\d+)','names');
%         end  
%         num_a=str2num(r.num1);
%         num_b=str2num(r.num2);
%     end
%     dt=time(num2+1,num_b+1)-time(num1+1,num_a+1);
%     ibx=str2double(get(handles.num_CorrBoxSize_1,'String'));
%     iby=str2double(get(handles.num_CorrBoxSize_2,'String'));
%     umin=dt*pxcm*umin;
%     umax=dt*pxcm*umax;
%     vmin=dt*pxcm*vmin;
%     vmax=dt*pxcm*vmax;
    shiftx=round((umin+umax)/2);
    shifty=round((vmin+vmax)/2);
    isx=(umax+2-shiftx)*2+param_civ1.CorrBoxSize(1);
    isx=2*ceil(isx/2)+1;
    isy=(vmax+2-shifty)*2+param_civ1.CorrBoxSize(2);
    isy=2*ceil(isy/2)+1;
    set(handles.num_SearchBoxShift_1,'String',num2str(shiftx));
    set(handles.num_SearchBoxShift_2,'String',num2str(shifty));
    set(handles.num_SearchBoxSize_1,'String',num2str(isx));
    set(handles.num_SearchBoxSize_2,'String',num2str(isy));
end

%------------------------------------------------------------------------
% --- Executes on selection in menu CorrSmooth.
function num_CorrSmooth_Callback(hObject, eventdata, handles)
set(handles.configSource,'String','NEW')
set(handles.OK,'BackgroundColor',[1 0 1])
%------------------------------------------------------------------------

% --- Executes on button press in CheckDeformation.
function CheckDeformation_Callback(hObject, eventdata, handles)
set(handles.ConfigSource,'String','NEW')
set(handles.OK,'BackgroundColor',[1 0 1])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Fix1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% % --- Executes on button press in CheckMask.
% function get_mask_fix1_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% maskval=get(handles.CheckMask,'Value');
% if isequal(maskval,0)
%     set(handles.Mask,'String','')
% else
%     mask_displ='no mask'; %default
%     filebase=get(handles.RootPath,'String');
%     [nbslice, flag_mask]=get_mask(filebase,handles);
%     if isequal(flag_mask,1)
%         mask_displ=[num2str(nbslice) 'mask'];
%     elseif get(handles.ListCompareMode,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
%         filebase_a=get(handles.RootFile_1,'String');
%         [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles);
%         if isequal(flag_mask_a,0) || ~isequal(nbslice_a,nbslice)
%             mask_displ='no mask';
%         end
%     end
%     if isequal(mask_displ,'no mask')
%         [FileName, PathName, filterindex] = uigetfile( ...
%             {'*.png', ' (*.png)';
%             '*.png',  '.png files '; ...
%             '*.*', 'All Files (*.*)'}, ...
%             'Pick a mask file *.png',filebase);
%         mask_displ=fullfile(PathName,FileName);
%         if ~exist(mask_displ,'file')
%             mask_displ='no mask';
%         end
%     end
%     if isequal(mask_displ,'no mask')
%         set(handles.CheckMask,'Value',0)
%         set(handles.CheckMask,'Value',0)
%         set(handles.CheckMask,'Value',0)
%     else
%         %set(handles.CheckMask,'Value',1)
%         set(handles.CheckMask,'Value',1)
%     end
%     set(handles.Mask,'String',mask_displ)
%     set(handles.Mask,'String',mask_displ)
%     set(handles.Mask,'String',mask_displ)
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Civ2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in CheckMask: select box for mask option
function get_mask_civ2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
maskval=get(handles.CheckMask,'Value');
if isequal(maskval,0)
    set(handles.Mask,'String','')
else
    mask_displ='no mask'; %default
    filebase=get(handles.RootPath,'String');
    [nbslice, flag_mask]=get_mask(filebase,handles);
    if isequal(flag_mask,1)
        mask_displ=[num2str(nbslice) 'mask'];
    elseif get(handles.ListCompareMode,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
        filebase_a=get(handles.RootFile_1,'String');
        [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles);
        if isequal(flag_mask_a,0) || ~isequal(nbslice_a,nbslice)
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        [FileName, PathName, filterindex] = uigetfile( ...
            {'*.png', ' (*.png)';
            '*.png',  '.png files '; ...
            '*.*', 'All Files (*.*)'}, ...
            'Pick a mask file *.png',filebase);
        mask_displ=fullfile(PathName,FileName);
        if ~exist(mask_displ,'file')
            mask_displ='no mask';
        end
    end
    if isequal(mask_displ,'no mask')
        set(handles.CheckMask,'Value',0)
        set(handles.CheckMask,'Value',0)
    else
        set(handles.CheckMask,'Value',1)
    end
    set(handles.Mask,'String',mask_displ)
end

% %------------------------------------------------------------------------
% % --- Executes on button press in CheckMask.
% function get_mask_fix2_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% maskval=get(handles.CheckMask,'Value');
% if isequal(maskval,0)
%     set(handles.Mask,'String','')
% else
%     mask_displ='no mask'; %default
%     filebase=get(handles.RootPath,'String');
%     [nbslice, flag_mask]=get_mask(filebase,handles);
%     if isequal(flag_mask,1)
%         mask_displ=[num2str(nbslice) 'mask'];
%     elseif get(handles.ListCompareMode,'Value')>1 & ~isequal(mask_displ,'no mask')% look for the second mask series
%         filebase_a=get(handles.RootFile_1,'String');
%         [nbslice_a, flag_mask_a]=get_mask(filebase_a,handles);
%         if isequal(flag_mask_a,0) || ~isequal(nbslice_a,nbslice)
%             mask_displ='no mask';
%         end
%     end
%     if isequal(mask_displ,'no mask')
%         [FileName, PathName, filterindex] = uigetfile( ...
%             {'*.png', ' (*.png)';
%             '*.png',  '.png files '; ...
%             '*.*', 'All Files (*.*)'}, ...
%             'Pick a mask file *.png',filebase);
%         mask_displ=fullfile(PathName,FileName);
%         if ~exist(mask_displ,'file')
%             mask_displ='no mask';
%         end
%     end
%     if isequal(mask_displ,'no mask')
%         set(handles.CheckMask,'Value',0)
%     end
%     set(handles.Mask,'String',mask_displ)
% end

%------------------------------------------------------------------------
% --- function called to look for mask files
function [nbslice, flag_mask]=get_mask(filebase,handles)
%------------------------------------------------------------------------
%detect mask files, images with appropriate file base
%[filebase '_' xx 'mask'], xx=nbslice
%flag_mask=1 indicates detection

flag_mask=0;%default
nbslice=1;

% subdir=get(handles.Civ1_ImageB,'String');
[Path,Name]=fileparts(filebase);
if ~isdir(Path)
    msgbox_uvmat('ERROR','no path for input files')
    return
end
% currentdir=pwd;
% cd(Path);%move in the dir of the root name filebase
maskfiles=dir(fullfile(Path,[Name '_*mask_*.png']));%look for mask files
% cd(currentdir);%come back to the current working directory
if ~isempty(maskfiles)
    %     msgbox_uvmat('ERROR','no mask available, to create it use Tools/Make mask in the upper menu bar of uvmat')
    % else
    flag_mask=1;
    maskname=maskfiles(1).name;% take the first mask file in the list
    [Path2,Name,ext]=fileparts(maskname);
    Namedouble=double(Name);
    val=(48>Namedouble)|(Namedouble>57);% select the non-numerical characters
    ind_mask=findstr('mask',Name);
    i=ind_mask-1;
    while val(i)==0 && i>0
        i=i-1;
    end
    nbslice=str2double(Name(i+1:ind_mask-1));
    if ~isnan(nbslice) && Name(i)=='_'
        flag_mask=1;
    else
        msgbox_uvmat('ERROR',['bad mask file ' Name ext ' found in ' Path2])
        return
        nbslice=1;
    end
end

%------------------------------------------------------------------------
% --- function called to look for grid files
function [nbslice, flag_grid]=get_grid(filebase,handles)
%------------------------------------------------------------------------
flag_grid=0;%default
nbslice=1;
[Path,Name]=fileparts(filebase);
currentdir=pwd;
cd(Path);%move in the dir of the root name filebase
gridfiles=dir([Name '_*grid_*.grid']);%look for grid files
cd(currentdir);%come back to the current working directory
if ~isempty(gridfiles)
    flag_grid=1;
    gridname=gridfiles(1).name;% take the first grid file in the list
    [Path2,Name,ext]=fileparts(gridname);
    Namedouble=double(Name);
    val=(48>Namedouble)|(Namedouble>57);% select the non-numerical characters
    ind_grid=findstr('grid',Name);
    i=ind_grid-1;
    while val(i)==0 && i>0
        i=i-1;
    end
    nbslice=str2double(Name(i+1:ind_grid-1));
    if ~isnan(nbslice) && Name(i)=='_'
        flag_grid=1;
    else
        msgbox_uvmat('ERROR',['bad grid file ' Name ext ' found in ' Path2])
        return
        nbslice=1;
    end
end

%------------------------------------------------------------------------
% --- transform numbers to letters
function str=num2stra(num,nom_type)
%------------------------------------------------------------------------
if isempty(nom_type)
    str='';
elseif strcmp(nom_type(end),'a')
    str=char(96+num);
elseif strcmp(nom_type(end),'A')
    str=char(96+num);
elseif isempty(nom_type(2:end))%a single index
    str='';
else
    str=num2str(num);
end

% %------------------------------------------------------------------------
% % --- Executes on button press in ListSubdirCiv1.
% function ListSubdirCiv1_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% list_subdir_civ1=get(handles.ListSubdirCiv1,'String');
% val=get(handles.ListSubdirCiv1,'Value');
% SubDir=list_subdir_civ1{val};
% if strcmp(SubDir,'new...')
%     if get(handles.CheckCiv1,'Value')
%         SubDir='STEREO_INPUT'; %default subdirectory
%     else
%         msgbox_uvmat('ERROR','select CheckCiv1 to perform a new stereo_input operation')
%         return
%     end    
% end
% set(handles.Civ1_ImageB,'String',SubDir);
% errormsg=find_netcpair_civ(handles,1);
% if ~isempty(errormsg)
%     msgbox_uvmat('ERROR',errormsg)
% end
%     
%------------------------------------------------------------------------
% % --- Executes on button press in ListSubdirCiv2.
% function ListSubdirCiv2_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% list_subdir_civ2=get(handles.ListSubdirCiv2,'String');
% val=get(handles.ListSubdirCiv2,'Value');
% SubDir=list_subdir_civ2{val};
% if strcmp(SubDir,'new...')
%     if get(handles.CheckCiv2,'Value')
%         SubDir='STEREO_INPUT'; %default subdirectory
%     else
%         msgbox_uvmat('ERROR','select CheckCiv2 to perform a new stereo_input operation')
%         return
%     end
% end
% set(handles.Civ2_ImageA,'String',SubDir);

%------------------------------------------------------------------------
% --- Executes on button press in CheckGrid.
function CheckGrid_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
value=get(hObject,'Value');
hparent=get(hObject,'parent');%handles of the parent panel
hchildren=get(hparent,'children');
handle_txtbox=findobj(hchildren,'tag','Grid');% look for the grid name box in the same panel
handle_dx=findobj(hchildren,'tag','num_Dx');
handle_dy=findobj(hchildren,'tag','num_Dy');
handle_title_dx=findobj(hchildren,'tag','title_Dx');
handle_title_dy=findobj(hchildren,'tag','title_Dy');
testgrid=0;
filegrid='';
if value
        hseries=findobj(allchild(0),'Tag','series');
    hhseries=guidata(hseries);
    InputTable=get(hhseries.InputTable,'Data');
     ind_A=1;% line index of the (first) image series
    if strcmp(InputTable{1,5},'.nc');
        ind_A=2;
    end
    filebase=InputTable{ind_A,1};
    [nbslice, flag_grid]=get_grid(filebase,handles);% look for a grid with appropriate name 
    if isequal(flag_grid,1)
        filegrid=[num2str(nbslice) 'grid'];
        testgrid=1;
    else % browse for a grid 
        filegrid=get(hObject,'UserData');%look for previous grid name stored as UserData
        if exist(filegrid,'file')
            filebase=filegrid;
        end
       filegrid = uigetfile_uvmat('pick a grid file .grid:',filebase,'.grid'); 
        set(hObject,'UserData',filegrid);%store for future use
        if ~isempty(filegrid)
            testgrid=1;
        end 
        set(hObject,'UserData',filegrid);%store for future use
    end
end
if testgrid
    set(handle_dx,'Visible','off');
    set(handle_dy,'Visible','off');
    set(handle_title_dy,'Visible','off');
    set(handle_title_dx,'Visible','off');
    set(handle_txtbox,'Visible','on')
    set(handle_txtbox,'String',filegrid)
else
    set(hObject,'Value',0);
    set(handle_dx,'Visible','on'); 
    set(handle_dy,'Visible','on');
    set(handle_title_dy,'Visible','on');
    set(handle_title_dx,'Visible','on');
    set(handle_txtbox,'Visible','off')
end

%% if hObject is on the checkciv1 frame, duplicate action for checkciv2 frame
PanelName=get(hparent,'tag');
if strcmp(PanelName,'Civ1')
    hchildren=get(handles.Civ2,'children');
    handle_checkbox=findobj(hchildren,'tag','CheckGrid');
    handle_txtbox=findobj(hchildren,'tag','Grid');
    handle_dx=findobj(hchildren,'tag','num_Dx');
    handle_dy=findobj(hchildren,'tag','num_Dy');
    handle_title_dx=findobj(hchildren,'tag','title_Dx');
    handle_title_dy=findobj(hchildren,'tag','title_Dy');
    set(handle_checkbox,'UserData',filegrid);%store for future use
    if testgrid
        set(handle_checkbox,'Value',1);
        set(handle_dx,'Visible','off');
        set(handle_dy,'Visible','off');
        set(handle_title_dx,'Visible','off');
        set(handle_title_dy,'Visible','off');
        set(handle_txtbox,'Visible','on')
        set(handle_txtbox,'String',filegrid)
    end 
end
set(hObject,'BackgroundColor',[1 0 1])
set(handles.configSource,'String','NEW')
set(handles.OK,'BackgroundColor',[1 0 1])
%------------------------------------------------------------------------
% --- Executes on button press in CheckMask: common to all panels (civ1, Civ2..)
function CheckMask_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
value=get(hObject,'Value');
hparent=get(hObject,'parent');
parent_tag=get(hparent,'Tag');
hchildren=get(hparent,'children');
handle_txtbox=findobj(hchildren,'tag','Mask');% look for the mask name box in the same panel

testmask=0;
if value
    hseries=findobj(allchild(0),'Tag','series');
    hhseries=guidata(hseries);
    InputTable=get(hhseries.InputTable,'Data');
    ind_A=1;% line index of the (first) image series
    if strcmp(InputTable{1,5},'.nc');
        ind_A=2;
    end
    [nbslice, flag_mask]=get_mask(InputTable{ind_A,1},handles);% look for a mask with appropriate name
    if isequal(flag_mask,1)
        filemask=[num2str(nbslice) 'mask'];
        testmask=1;
    else % browse for a mask
%         filemask=get(hObject,'UserData');%look for previous mask name stored as UserData
%         if exist(filemask,'file')
%             filebase=filemask;
%         end
        filemask= uigetfile_uvmat('pick a mask image file:',InputTable{ind_A,1},'image');
        set(hObject,'UserData',filemask);%store for future use
        if ~isempty(filemask)
            testmask=1;
        end
    end
end
if testmask
    set(handles.Mask,'Visible','on')
    set(handles.Mask,'String',filemask)
    set(handles.CheckMask,'Value',1)
else
    set(hObject,'Value',0);
    set(handle_txtbox,'Visible','off')
end
set(handles.configSource,'String','NEW')
set(handles.configSource,'BackgroundColor',[1 0 1])

% %------------------------------------------------------------------------
% % --- Executes on button press in get_gridpatch1.
% function get_gridpatch1_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% filebase=get(handles.RootPath,'String');
% [FileName, PathName, filterindex] = uigetfile( ...
%     {'*.grid', ' (*.grid)';
%     '*.grid',  '.grid files '; ...
%     '*.*', 'All Files (*.*)'}, ...
%     'Pick a file',filebase);
% filegrid=fullfile(PathName,FileName);
% set(handles.grid_patch1,'string',filegrid);
% set(hObject,'BackgroundColor',[1 0 1])

%------------------------------------------------------------------------
% --- STEREO Interp
function cmd=RUN_STINTERP(stinterpBin,filename_A_nc,filename_B_nc,filename_nc,nx_patch,ny_patch,rho_patch,subdomain_patch,thresh_value,xmlA,xmlB)
%------------------------------------------------------------------------
namelog=[filename_nc(1:end-3) '_stinterp.log'];
cmd=[stinterpBin ' -f1 ' filename_A_nc  ' -f2 ' filename_B_nc ' -f  ' filename_nc ...
    ' -m ' nx_patch  ' -n ' ny_patch ' -ro ' rho_patch ' -nopt ' subdomain_patch ' -c1 ' xmlA ' -c2 ' xmlB '  -xy  x -Nfy 1024 > ' namelog ' 2>&1']; % redirect standard output to the log file

% %------------------------------------------------------------------------
% %--read images and convert them to the uint16 format used for PIV
% function A=read_image(filename,type_ima,num,movieobject)
% %------------------------------------------------------------------------
% %num is the view number needed for an avi movie
% switch type_ima
%     case 'movie'
%         A=read(movieobject,num);
%     case 'avi'
%         mov=aviread(filename,num);
%         A=frame2im(mov(1));
%     case 'multimage'
%         A=imread(filename,num);
%     case 'image'
%         A=imread(filename);
% end
% siz=size(A);
% if length(siz)==3;%color images
%     A=sum(double(A),3);
%     A=uint16(A);
% end


%------------------------------------------------------------------------
% --- Executes on button press in get_ref_fix1.
function get_ref_fix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
filebase=get(handles.RootPath,'String');
[FileName, PathName, filterindex] = uigetfile( ...
    {'*.nc', ' (*.nc)';
    '*.nc',  'netcdf files '; ...
    '*.*', 'All Files (*.*)'}, ...
    'Pick a file',filebase);

fileinput=[PathName FileName];
sizf=size(fileinput);
if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
%[Path,File,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
[Path,ref.subdir,File,ref.num1,ref.num2,ref.num_a,ref.num_b,ref.ext,ref.nom_type]=fileparts_uvmat(fileinput);
ref.filebase=fullfile(Path,File);
% ref.num_a=stra2num(str_a);
% ref.num_b=stra2num(str_b);
% ref.num1=str2double(field_count);
% ref.num2=str2double(str2);
browse=[];%initialisation
if ~isequal(ref.ext,'.nc')
    msgbox_uvmat('ERROR','the reference file must be in netcdf format (*.nc)')
    return
end
set(handles.ref_fix1,'String',[fullfile(ref.subdir,File) '....nc']);
set(handles.ref_fix1,'UserData',ref)
menu_field{1}='civ1';
Data=nc2struct(fileinput,[]);
if isfield(Data,'patch') && isequal(Data.patch,1)
    menu_field{2}='filter1';
end
if isfield(Data,'civ2') && isequal(Data.civ2,1)
    menu_field{3}='civ2';
end
if isfield(Data,'patch2') && isequal(Data.patch2,1)
    menu_field{4}='filter2';
end
set(handles.field_ref1,'String',menu_field);
set(handles.field_ref1,'Value',length(menu_field));
set(handles.num_MinVel,'Value',2);
set(handles.num_MinVel,'String','1');%default threshold
set(handles.ref_fix1,'Enable','on')

%------------------------------------------------------------------------
% --- Executes on button press in get_ref_fix2.
function get_ref_fix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
if isequal(get(handles.get_ref_fix2,'Value'),1)
    filebase=get(handles.RootPath,'String');
    [FileName, PathName, filterindex] = uigetfile( ...
        {'*.nc', ' (*.nc)';
        '*.nc',  'netcdf files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file',filebase);
    fileinput=[PathName FileName];
    sizf=size(fileinput);
    if (~ischar(fileinput)||~isequal(sizf(1),1)),return;end %stop if fileinput not a character string
    %[Path,File,field_count,str2,str_a,str_b,ref.ext,ref.nom_type,ref.subdir]=name2display(fileinput);
    [Path,ref.subdir,File,ref.num1,ref.num2,ref.num_a,ref.num_b,ref.ext,ref.nom_type]=fileparts_uvmat(fileinput);
    ref.filebase=fullfile(Path,File);
    %     ref.num_a=stra2num(str_a);
    %     ref.num_b=stra2num(str_b);
    %     ref.num1=str2num(field_count);
    %     ref.num2=str2num(str2);
    browse=[];%initialisation
    if ~isequal(ref.ext,'.nc')
        msgbox_uvmat('ERROR','the reference file must be in netcdf format (*.nc)')
        return
    end
    set(handles.ref_fix2,'String',[fullfile(ref.subdir,File) '....nc']);
    set(handles.ref_fix2,'UserData',ref)
    menu_field{1}='civ1';
    Data=nc2struct(fileinput,[]);
    if isfield(Data,'patch') && isequal(Data.patch,1)
        menu_field{2}='filter1';
    end
    if isfield(Data,'civ2') && isequal(Data.civ2,1)
        menu_field{3}='civ2';
    end
    if isfield(Data,'patch2') && isequal(Data.patch2,1)
        menu_field{4}='filter2';
    end
    set(handles.field_ref2,'String',menu_field);
    set(handles.field_ref2,'Value',length(menu_field));
    set(handles.num_MinVel,'Value',2);
    set(handles.num_MinVel,'String','1');%default threshold
    set(handles.ref_fix2,'Enable','on')
    set(handles.ref_fix2,'Visible','on')
    set(handles.field_ref2,'Visible','on')
else
    set(handles.ref_fix2,'Visible','off')
    set(handles.field_ref2,'Visible','off')
end

%------------------------------------------------------------------------
function ref_fix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.num_MinVel,'Value',1);
set(handles.field_ref1,'Value',1)
set(handles.field_ref1,'String',{' '})
set(handles.ref_fix1,'UserData',[]);
set(handles.ref_fix1,'String','');
set(handles.thresh_vel1,'String','0');

%------------------------------------------------------------------------
function ref_fix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
set(handles.num_MinVel,'Value',1);
set(handles.field_ref2,'Value',1)
set(handles.field_ref2,'String',{' '})
set(handles.ref_fix2,'UserData',[]);
set(handles.ref_fix2,'String','');
set(handles.num_MinVel,'String','0');

%------------------------------------------------------------------------
% --- TO ABANDON Executes on button press in test_stereo1.
function CheckStereo_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
hparent=get(hObject,'parent');
parent_tag=get(hparent,'Tag');
hchildren=get(hparent,'children');
handle_txtbox=findobj(hchildren,'tag','txt_Mask');
if isequal(get(hObject,'Value'),0)
    set(handles.num_SubDomainSize,'Visible','on')
    set(handles.num_FieldSmooth,'Visible','on')
else
    set(handles.num_SubDomainSize,'Visible','off')
    set(handles.num_FieldSmooth,'Visible','off')
end

% %------------------------------------------------------------------------
% % --- Executes on button press in CheckStereo.
% function StereoCheck_Callback(hObject, eventdata, handles)
% %------------------------------------------------------------------------
% if isequal(get(handles.CheckStereo,'Value'),0)
%     set(handles.num_subdomainsize,'Visible','on')
%     set(handles.num_FieldSmooth,'Visible','on')
% else

%     set(handles.num_subdomainsize,'Visible','off')
%     set(handles.num_FieldSmooth,'Visible','off')
% end



%------------------------------------------------------------------------ 
%----function introduced for the correlation window figure, activated by deleting this window
function closeview_field(gcbo,eventdata)
%------------------------------------------------------------------------
hview_field=findobj(allchild(0),'tag','view_field');% look for view_field
if ~isempty(hview_field)
    delete(hview_field)
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckThreshold.
function CheckThreshold_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
huipanel=get(hObject,'parent');
obj(1)=findobj(huipanel,'Tag','num_MinIma');
obj(2)=findobj(huipanel,'Tag','num_MaxIma');
obj(3)=findobj(huipanel,'Tag','title_Threshold');
if get(hObject,'Value')
    set(obj,'Visible','on')
else
    set(obj,'Visible','off')
end
set(handles.configSource,'String','NEW')
set(handles.OK,'BackgroundColor',[1 0 1])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%   TEST functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in TestCiv1: prepare the image correlation function
%     activated by mouse motion
function TestCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
drawnow
if get(handles.TestCiv1,'Value')
    set(handles.TestCiv1,'BackgroundColor',[1 1 0])% paint TestCiv1 button to yellow to confirm civ launch  
    %Param.Action.RUN=1;
    
      hseries=findobj(allchild(0),'Tag','series');
     Param=read_GUI(hseries);
     Param.Action.RUN=1;
     Param.ActionInput=read_GUI(handles.civ_input);

     if isfield(Param.ActionInput,'Patch1')
         Param.ActionInput=rmfield(Param.ActionInput,'Patch1');
     end
     if isfield(Param.ActionInput,'Civ2')%remove options that may be selected beyond Patch1
         Param.ActionInput=rmfield(Param.ActionInput,'Civ2');
     end
     if isfield(Param.ActionInput,'Fix2')
         Param.ActionInput=rmfield(Param.ActionInput,'Fix2');
     end
     if isfield(Param.ActionInput,'Patch2')
         Param.ActionInput=rmfield(Param.ActionInput,'Patch2');
     end
     if isfield(Param.ActionInput,'Civ3')%remove options that may be selected beyond Patch1
         Param.ActionInput=rmfield(Param.ActionInput,'Civ3');
     end
     if isfield(Param.ActionInput,'Fix3')
         Param.ActionInput=rmfield(Param.ActionInput,'Fix3');
     end
     if isfield(Param.ActionInput,'Patch3')
         Param.ActionInput=rmfield(Param.ActionInput,'Patch3');
     end
%      if isfield(Param,'OutputSubDir')
%         Param=rmfield(Param,'OutputSubDir'); %remove output file option from civ_series
%      end
     Param.ActionInput.Civ1.CorrSmooth=0;% launch Civ1 with no data point (to get the image names for A and B)
     [Data,errormsg, ~, xmlData]=stereo_civ(Param);% get the civ1+fix1 results 
     % if ~isempty(errormsg), return, end % rmq: error msg displayed in civ_series
     
 %% create image data ImageData for display
     ImageData.ListVarName={'ny','nx','A'};
     ImageData.VarDimName= {'ny','nx',{'ny','nx'}};

     %%%%%%%%%%%%%%%%% modif fonction test %%%%%%%%%%%
     ImageData.VarAttribute{1}.Role='coord_y';
     ImageData.VarAttribute{2}.Role='coord_x';
     ImageData.VarAttribute{3}.Role='scalar';

     A{1}=imread(Data.Civ1_ImageA); % read the first image
     A{2}=imread(Data.Civ1_ImageB); % read the first image

     phys_img = phys_ima(A,xmlData,1);%transform image A in phys coordinates
     ImageData.A = phys_img{1};
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

     if ndims(ImageData.A)==3 %case of color image
         ImageData.VarDimName= {'ny','nx',{'ny','nx','rgb'}};
     end
     ImageData.ny=[size(ImageData.A,1) 1];
     ImageData.nx=[1 size(ImageData.A,2)];
     ImageData.CoordUnit='pixel';% used to set equal scaling for x and y in image dispa=ly 

     %% create the figure view_field for image visualization
     hview_field=view_field(ImageData); %view the image in the GUI view_field 
     set(0,'CurrentFigure',hview_field)
     hhview_field=guihandles(hview_field);
     set(hview_field,'CurrentAxes',hhview_field.PlotAxes)
     ViewData=get(hview_field,'UserData');
     ViewData.CivHandle=handles.civ_input;% indicate the handle of the civ GUI in view_field
     ViewData.PlotAxes.X=Data.Civ1_X';
     ViewData.PlotAxes.Y=Data.Civ1_Y';

     %%%%%%%%%%%%%%%%%%%%%%%
     ViewData.PlotAxes.B=phys_img{2};%store the second image in the UserData of the GUI view_field
     %%%%%%%%%%%%%%%%%%%%%%%

     set(hview_field,'UserData',ViewData)% store the info in the UserData of image view_field
    
    %% look for a current figure for image correlation display
    corrfig=findobj(allchild(0),'tag','corrfig');
    if isempty(corrfig)
        corrfig=figure;
        set(corrfig,'tag','corrfig')
        set(corrfig,'name','image correlation')
        set(corrfig,'DeleteFcn',{@closeview_field})%
        set(handles.TestCiv1,'BackgroundColor',[1 0 0])
    else
        set(handles.TestCiv1,'BackgroundColor',[1 0 0])% paint button to red
        corrfig=findobj(allchild(0),'tag','corrfig');% look for a current figure for image correlation display
        if ~isempty(corrfig)
            delete(corrfig)
        end
        hview_field=findobj(allchild(0),'tag','view_field');% look for view_field
        if ~isempty(hview_field)
            delete(hview_field)
        end
    end
else
    hview_field=findobj(allchild(0),'Tag','view_field'); %view the image in the GUI view_field
    if ~isempty(hview_field)
        delete(hview_field)
    end      
end

% --------------------------------------------------------------------
% --- Executes on button press in TestPatch1.
% --------------------------------------------------------------------
function TestPatch1_Callback(hObject, eventdata, handles)

if get(handles.TestPatch1,'Value')% if TestPatch1 is activated
     set(handles.TestPatch1,'BackgroundColor',[1 1 0])%paint TestPatch1 button in yellow to indicate activation
     set(handles.Civ1,'BackgroundColor',[1 1 0])% indicate civ1 calculation is performed
     hseries=findobj(allchild(0),'Tag','series');
     Param=read_GUI(hseries);
     Param.Action.RUN=1;
     Param.ActionInput=read_GUI(handles.civ_input);

     if isfield(Param.ActionInput,'Civ2')%remove options that may be selected beyond Patch1
         Param.ActionInput=rmfield(Param.ActionInput,'Civ2');
     end
     if isfield(Param.ActionInput,'Fix2')
         Param.ActionInput=rmfield(Param.ActionInput,'Fix2');
     end
     if isfield(Param.ActionInput,'Patch2')
         Param.ActionInput=rmfield(Param.ActionInput,'Patch2');
     end
     if isfield(Param.ActionInput,'Civ3')%remove options that may be selected beyond Patch1
         Param.ActionInput=rmfield(Param.ActionInput,'Civ3');
     end
     if isfield(Param.ActionInput,'Fix3')
         Param.ActionInput=rmfield(Param.ActionInput,'Fix3');
     end
     if isfield(Param.ActionInput,'Patch3')
         Param.ActionInput=rmfield(Param.ActionInput,'Patch3');
     end
     % if isfield(Param,'OutputSubDir')
     % Param=rmfield(Param,'OutputSubDir'); %remove output file option from civ_series
     % end

     ParamPatch1=Param.ActionInput.Patch1; %store the patch1 parameters
     Param.ActionInput=rmfield(Param.ActionInput,'Patch1');% does not execute Patch

     [Data,errormsg]=stereo_civ(Param);% get the civ1+fix1 results
     bckcolor=get(handles.civ_input,'Color');
     set(handles.Civ1,'BackgroundColor',bckcolor)% indicate civ1 calculation is finished
     
     %% prepare Param for iterative Patch processing without input file reading
     Param.Civ1_X=Data.Civ1_X;
     Param.Civ1_Y=Data.Civ1_Y;
     Param.Civ1_U=Data.Civ1_U;
     Param.Civ1_V=Data.Civ1_V;
     Param.Civ1_FF=Data.Civ1_FF;

     %%%%% modif fonction test %%%%%%
     % Param=rmfield(Param,'InputTable');%desactivate input file reading
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isfield(Param.ActionInput,'Civ1')
        Param.ActionInput=rmfield(Param.ActionInput,'Civ1');%desactivate civ1: remove civ1 input param if relevant
    end
    if isfield(Param.ActionInput,'Fix1')
        Param.ActionInput=rmfield(Param.ActionInput,'Fix1');%desactivate fix1:remove fix1 input param if relevant
    end
    SmoothingParam=(ParamPatch1.FieldSmooth/10)*2.^(1:7);%scan the smoothing param from 1/10 to 12.8 current value
    NbGood=numel(find(Data.Civ1_FF==0));
    NbExclude=zeros(1,7);% initialize the set of smoothing parameters
    DiffVel=zeros(1,7);% initialize the rms difference between patch and civ
    Param.ActionInput.Patch1=ParamPatch1;% retrieve Patch1 parameters
    for irho=1:7
        Param.ActionInput.Patch1.FieldSmooth=SmoothingParam(irho);
        [Data,errormsg]= stereo_civ(Param);%apply the processing fct

        %%%%%%%%%% modif fonction test %%%%%%%%%%%%%% 
        % if ~isempty(errormsg)
        %     msgbox_uvmat('ERROR',errormsg)
        %     return
        % end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        ind_good=find(Data.Civ1_FF==0);
        Civ1_U_Diff=Data.Civ1_U(ind_good)-Data.Civ1_U_smooth(ind_good);
        Civ1_V_Diff=Data.Civ1_V(ind_good)-Data.Civ1_V_smooth(ind_good);
        DiffVel(irho)=sqrt(mean(Civ1_U_Diff.*Civ1_U_Diff+Civ1_V_Diff.*Civ1_V_Diff));
        NbExclude(irho)=(NbGood-numel(ind_good))/NbGood;
    end
    figure(1)
    hold on
    semilogx(SmoothingParam,DiffVel,'b',SmoothingParam,NbExclude,'r')
    grid on
    legend('rms velocity diff. Patch1-Civ1 (pixels)','proportion of excluded vectors (between 0 to 1)')
    xlabel('smoothing parameter')
    ylabel('smoothing effect')
    set(handles.TestPatch1,'BackgroundColor',[0 1 0])
else
    corrfig=findobj(allchild(0),'tag','corrfig');% look for a current figure for image correlation display
    if ~isempty(corrfig)
        delete(corrfig)
    end
    hview_field=findobj(allchild(0),'tag','view_field');% look for view_field
    if ~isempty(hview_field)
        delete(hview_field)
    end
end

%------------------------------------------------------------------------
% --- Executes on button press in TestCiv2.
%------------------------------------------------------------------------
function TestCiv2_Callback(hObject, eventdata, handles)
drawnow
if get(handles.TestCiv2,'Value')
    set(handles.TestCiv2,'BackgroundColor',[1 1 0])% paint TestCiv1 button to yellow to confirm civ launch
      hseries=findobj(allchild(0),'Tag','series');
     Param=read_GUI(hseries);
     Param.Action.RUN=1;
     Param.ActionInput=read_GUI(handles.civ_input);

     if isfield(Param.ActionInput,'Patch2')
         Param.ActionInput=rmfield(Param.ActionInput,'Patch2');
     end
     if isfield(Param.ActionInput,'Civ3')%remove options that may be selected beyond Patch1
         Param.ActionInput=rmfield(Param.ActionInput,'Civ3');
     end
     if isfield(Param.ActionInput,'Fix3')
         Param.ActionInput=rmfield(Param.ActionInput,'Fix3');
     end
     if isfield(Param.ActionInput,'Patch3')
         Param.ActionInput=rmfield(Param.ActionInput,'Patch3');
     end

     % if isfield(Param,'OutputSubDir')
     % Param=rmfield(Param,'OutputSubDir'); %remove output file option from civ_series
     % end

     Param.ActionInput.Civ2.CorrSmooth=0;% launch Civ2 with no data point (to get the image names for A and B)
     set(handles.Civ1,'BackgroundColor',[1 1 0])
     set(handles.Fix1,'BackgroundColor',[1 1 0])
     set(handles.Patch1,'BackgroundColor',[1 1 0])
     [Data,errormsg, ~, xmlData]=stereo_civ(Param);% get the civ1+fix1+patch1+civ2+fix2 results
     % if ~isempty(errormsg), return, end
     
     %% create image data ImageData for display
     ImageData.ListVarName={'ny','nx','A'};
     ImageData.VarDimName= {'ny','nx',{'ny','nx'}};

     %%%%%%%%%%%%%%%%% modif fonction test %%%%%%%%%%%
     ImageData.VarAttribute{1}.Role='coord_y';
     ImageData.VarAttribute{2}.Role='coord_x';
     ImageData.VarAttribute{3}.Role='scalar';

     A{1}=imread(Data.Civ2_ImageA); % read the first image
     A{2}=imread(Data.Civ2_ImageB); % read the first image

     phys_img = phys_ima(A,xmlData,1);%transform image A in phys coordinates
     ImageData.A = phys_img{1};
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

     if ndims(ImageData.A)==3 %case of color image
         ImageData.VarDimName= {'ny','nx',{'ny','nx','rgb'}};
     end
     ImageData.ny=[size(ImageData.A,1) 1];
     ImageData.nx=[1 size(ImageData.A,2)];
     ImageData.CoordUnit='pixel';% used to set equal scaling for x and y in image dispa=ly 

     %% create the figure view_field for image visualization
    hview_field=view_field(ImageData); %view the image in the GUI view_field 
    set(0,'CurrentFigure',hview_field)
    % plot the boundaries of the subdomains used for patch
    for isub=1:size(Data.Civ1_SubRange,3);
        pos_x=Data.Civ1_SubRange(1,1,isub);
        pos_y=Data.Civ1_SubRange(2,1,isub);
        width=Data.Civ1_SubRange(1,2,isub)-Data.Civ1_SubRange(1,1,isub);
        height=Data.Civ1_SubRange(2,2,isub)-Data.Civ1_SubRange(2,1,isub);
        rectangle('Position',[pos_x pos_y width height],'EdgeColor',[0 0 1])
    end
    hhview_field=guihandles(hview_field);%
    set(hview_field,'CurrentAxes',hhview_field.PlotAxes)
    ViewData=get(hview_field,'UserData'); % get the currently plotted field (the image A)
    % store info in the UserData of view-field
    ViewData.CivHandle=handles.civ_input;% indicate the handle of the civ GUI in view_field

    %%%%%%%%%%%% modif fonction test %%%%%%%%%%%%%%%%%%%%%%%%%%
    ViewData.PlotAxes.B=phys_img{2};%store the second image in the UserData of the GUI view_field
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    ViewData.PlotAxes.X=Data.Civ2_X';
    ViewData.PlotAxes.Y=Data.Civ2_Y';
    ViewData.PlotAxes.ShiftX=Data.Civ2_U';% shift at each point (from patch1) estimated by the preliminary run of civ2 
    ViewData.PlotAxes.ShiftY=Data.Civ2_V';
    ViewData.PlotAxes.Civ1_SubRange=Data.Civ1_SubRange;
    ViewData.PlotAxes.Civ1_NbCentres=Data.Civ1_NbCentres;
    ViewData.PlotAxes.Civ1_Coord_tps=Data.Civ1_Coord_tps;
    ViewData.PlotAxes.Civ1_U_tps=Data.Civ1_U_tps;
    ViewData.PlotAxes.Civ1_V_tps=Data.Civ1_V_tps;
    ViewData.PlotAxes.Civ1_Dt=Data.Civ1_Dt;
    ViewData.PlotAxes.Civ2_Dt=Data.Civ2_Dt;
    set(hview_field,'UserData',ViewData)% store the info in the UserData of image view_field
    bckcolor=get(handles.civ_input,'Color');
    set(handles.Civ1,'BackgroundColor',bckcolor)% indicate civ1 calmculation is finished
    set(handles.Fix1,'BackgroundColor',bckcolor)
    set(handles.Patch1,'BackgroundColor',bckcolor)
    drawnow
    
    %% look for a current figure for image correlation display
    corrfig=findobj(allchild(0),'tag','corrfig');
    if isempty(corrfig)
        corrfig=figure;
        set(corrfig,'tag','corrfig')
        set(corrfig,'name','image correlation')
        set(corrfig,'DeleteFcn',{@closeview_field})%
        set(handles.TestCiv2,'BackgroundColor',[1 0 0])
    else
        set(handles.TestCiv2,'BackgroundColor',[1 0 0])% paint button to red
        corrfig=findobj(allchild(0),'tag','corrfig');% look for a current figure for image correlation display
        if ~isempty(corrfig)
            delete(corrfig)
        end
        hview_field=findobj(allchild(0),'tag','view_field');% look for view_field
        if ~isempty(hview_field)
            delete(hview_field)
        end
    end   
else
    hview_field=findobj(allchild(0),'Tag','view_field'); %view the image in the GUI view_field
    if ~isempty(hview_field)
        delete(hview_field)
    end      
end


% --- Executes on button press in TestPatch2.
function TestPatch2_Callback(hObject, eventdata, handles)
if get(handles.TestPatch2,'Value')% if TestPatch2 is activated
     set(handles.TestPatch2,'BackgroundColor',[1 1 0])%paint TestPatch2 button in yellow to indicate activation
     set(handles.Civ1,'BackgroundColor',[1 1 0])% indicate civ1 calculation is activated
     set(handles.Fix1,'BackgroundColor',[1 1 0])% indicate fix1 calculation is activated
     set(handles.Patch1,'BackgroundColor',[1 1 0])% indicate Patch1 calculation is activated
     set(handles.Civ2,'BackgroundColor',[1 1 0])% indicate civ2 calculation is activated
     set(handles.Fix2,'BackgroundColor',[1 1 0])% indicate fix2 calculation is activated
     hseries=findobj(allchild(0),'Tag','series');
     Param=read_GUI(hseries);
     Param.Action.RUN=1;
     Param.ActionInput=read_GUI(handles.civ_input);
     if isfield(Param,'OutputSubDir')
     Param=rmfield(Param,'OutputSubDir'); %remove output file option from civ_series
     end
     ParamPatch2=Param.ActionInput.Patch2; %store the patch1 parameters
     Param.ActionInput=rmfield(Param.ActionInput,'Patch2');% does not execute Patch
     [Data,errormsg]=civ_series(Param);% get the civ1+fix1 results
     bckcolor=get(handles.civ_input,'Color');
     set(handles.Civ1,'BackgroundColor',bckcolor)% indicate civ1 calculation is finished
     set(handles.Fix1,'BackgroundColor',bckcolor)% indicate fix1 calculation is finished
     set(handles.Patch1,'BackgroundColor',bckcolor)% indicate Patch1 calculation is finished
     set(handles.Civ2,'BackgroundColor',bckcolor)% indicate civ2 calculation is finished
     set(handles.Fix2,'BackgroundColor',bckcolor)% indicate fix2 calculation is finished
     
     %% prepare Param for iterative Patch processing without input file reading
     Param.Civ2_X=Data.Civ2_X;
     Param.Civ2_Y=Data.Civ2_Y;
     Param.Civ2_U=Data.Civ2_U;
     Param.Civ2_V=Data.Civ2_V;
     Param.Civ2_FF=Data.Civ2_FF;
     Param=rmfield(Param,'InputTable');%desactivate input file reading
    if isfield(Param.ActionInput,'Civ1')
        Param.ActionInput=rmfield(Param.ActionInput,'Civ1');%desactivate civ1: remove civ1 input param if relevant
    end
    if isfield(Param.ActionInput,'Fix1')
        Param.ActionInput=rmfield(Param.ActionInput,'Fix1');%desactivate fix1:remove fix1 input param if relevant
    end
    if isfield(Param.ActionInput,'Patch1')
        Param.ActionInput=rmfield(Param.ActionInput,'Patch1');%desactivate fix1:remove fix1 input param if relevant
    end
    if isfield(Param.ActionInput,'Civ2')
        Param.ActionInput=rmfield(Param.ActionInput,'Civ2');%desactivate civ2: remove civ2 input param if relevant
    end
    if isfield(Param.ActionInput,'Fix2')
        Param.ActionInput=rmfield(Param.ActionInput,'Fix2');%desactivate fix1:remove fix1 input param if relevant
    end
    SmoothingParam=(ParamPatch2.FieldSmooth/10)*2.^(1:7);%scan the smoothing param from 1/10 to 12.8 current value
    NbGood=numel(find(Data.Civ2_FF==0));
    NbExclude=zeros(1,7);% initialize the set of smoothing parameters
    DiffVel=zeros(1,7);% initialize the rms difference between patch and civ
    Param.ActionInput.Patch2=ParamPatch2;% retrieve Patch2 parameters
    for irho=1:7
        Param.ActionInput.Patch2.FieldSmooth=SmoothingParam(irho);
        [Data,errormsg]= civ_series(Param);%apply the processing fct
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',errormsg)
            return
        end
        ind_good=find(Data.Civ2_FF==0);
        Civ2_U_Diff=Data.Civ2_U(ind_good)-Data.Civ2_U_smooth(ind_good);
        Civ2_V_Diff=Data.Civ2_V(ind_good)-Data.Civ2_V_smooth(ind_good);
        DiffVel(irho)=sqrt(mean(Civ2_U_Diff.*Civ2_U_Diff+Civ2_V_Diff.*Civ2_V_Diff));
        NbExclude(irho)=(NbGood-numel(ind_good))/NbGood;
    end
    figure(1)
    hold on
    semilogx(SmoothingParam,DiffVel,'b',SmoothingParam,NbExclude,'r')
    grid on
    legend('rms velocity diff. Patch2-Civ2 (pixels)','proportion of excluded vectors (between 0 to 1)')
    xlabel('smoothing parameter')
    ylabel('smoothing effect')
    set(handles.TestPatch2,'BackgroundColor',[0 1 0])
else
    corrfig=findobj(allchild(0),'tag','corrfig');% look for a current figure for image correlation display
    if ~isempty(corrfig)
        delete(corrfig)
    end
    hview_field=findobj(allchild(0),'tag','view_field');% look for view_field
    if ~isempty(hview_field)
        delete(hview_field)
    end
end
    

%'nomtype2pair': creates nomencalture for index pairs knowing the image nomenclature
%---------------------------------------------------------------------
function NomTypeNc=nomtype2pair(NomTypeIma,mode)
%---------------------------------------------------------------------           
% OUTPUT:
% NomTypeNc
%---------------------------------------------------------------------
% INPUT:
% 'NomTypeIma': string defining the kind of nomenclature used for images

NomTypeNc=NomTypeIma;%default
switch mode
    case 'pair j1-j2'      
    if ~isempty(regexp(NomTypeIma,'a$'))
        NomTypeNc=[NomTypeIma 'b'];
    elseif ~isempty(regexp(NomTypeIma,'A$'))
        NomTypeNc=[NomTypeIma 'B'];
    else
        r=regexp(NomTypeIma,'(?<num1>\d+)_(?<num2>\d+)$','names');
        if ~isempty(r)
            NomTypeNc='_1_1-2';
        end
    end
    case 'series(Dj)'  
%         r=regexp(NomTypeIma,'(?<num1>\d+)_(?<num2>\d+)$','names');
%         if ~isempty(r)
            NomTypeNc='_1_1-2';
%         end
   case 'series(Di)'
        r=regexp(NomTypeIma,'(?<num1>\d+)_(?<num2>\d+)$','names');
        if ~isempty(r)
            NomTypeNc='_1-2_1';
        else
            NomTypeNc='_1-2';
        end
end


%------------------------------------------------------------------------
% --- determine the list of index pairs of processing file
function [ind1,ind2,mode]=...
    find_pair_indices(str_civ,i_series,j_series,MinIndex_i,MaxIndex_i,MinIndex_j,MaxIndex_j)
%------------------------------------------------------------------------
ind1='';
ind2='';
r=regexp(str_civ,'^\D(?<ind>[i|j])=( -| )(?<num1>\d+)\|(?<num2>\d+)','names');
if ~isempty(r)
    mode=['D' r.ind];
    ind1=stra2num(r.num1);
    ind2=stra2num(r.num2);
else
    mode='burst';
    r=regexp(str_civ,'^j= (?<num1>[a-z])-(?<num2>[a-z])','names');
    if ~isempty(r)
        NomTypeNc='_1ab';
    else
        r=regexp(str_civ,'^j= (?<num1>[A-Z])-(?<num2>[A-Z])','names');
        if ~isempty(r)
            NomTypeNc='_1AB';
        else
            r=regexp(str_civ,'^j= (?<num1>\d+)-(?<num2>\d+)','names');
            if ~isempty(r)
                NomTypeNc='_1_1-2';
            end            
        end
    end
    if isempty(r)
        display('wrong pair mode input option')
    else
    ind1=stra2num(r.num1);
    ind2=stra2num(r.num2);
    end
end

%------------------------------------------------------------------------
% --- fill stereo_input with the parameters retrieved from an input Civ file
%------------------------------------------------------------------------
function fill_civ_input(Data,handles)

%% Civ param
% lists of parameters to enter
ListParamNum={'CorrBoxSize','SearchBoxSize','SearchBoxShift','Dx','Dy','Dz','MinIma','MaxIma'};% list of numerical values (to transform in strings)
ListParamValue={'CorrSmooth','CheckGrid','CheckMask','CheckThreshold'};
ListParamString={'Grid','Mask'};
% CorrSmooth ??
option={'Civ1','Civ2'};
for ichoice=1:2
    if isfield(Data,[option{ichoice} '_CorrBoxSize'])
        fill_panel(Data,handles,option{ichoice},ListParamNum,ListParamValue,ListParamString)
    end
end

%% Fix param
option={'Fix1','Fix2'};
for ichoice=1:2
    if isfield(Data,[option{ichoice} '_CheckFmin2'])
        ListParamNum={'MinVel','MaxVel','MinCorr'};% list of numerical values (to transform in strings)
        ListParamValue={'CheckFmin2','CheckF3','CheckF4'};
        ListParamString={'ref_fix_1'};
        fill_panel(Data,handles,option{ichoice},ListParamNum,ListParamValue,ListParamString)
    end
end

%% Patch param
option={'Patch1','Patch2'};
for ichoice=1:2
    if isfield(Data,[option{ichoice} '_FieldSmooth'])
        ListParamNum={'FieldSmooth','MaxDiff','SubDomainSize'};% list of numerical values (to transform in strings)
        ListParamValue={};
        ListParamString={};
        fill_panel(Data,handles,option{ichoice},ListParamNum,ListParamValue,ListParamString)
    end
end
%------------------------------------------------------------------------
% --- fill a panel of stereo_input with the parameters retrieved from an input Civ file
%------------------------------------------------------------------------
function fill_panel(Data,handles,panel,ListParamNum,ListParamValue,ListParamString)
children=get(handles.(panel),'children');%handles of the children of the input GUI with handle 'GUI_handle'
handles_panel=[];
for ichild=1:numel(children)
    if ~isempty(get(children(ichild),'tag'))
        handles_panel.(get(children(ichild),'tag'))=children(ichild);
    end
end
for ilist=1:numel(ListParamNum)
    ParamName=ListParamNum{ilist};
    CivParamName=[panel '_' ParamName];
    if isfield(Data,CivParamName)
        for icoord=1:numel(Data.(CivParamName))
            if numel(Data.(CivParamName))>1
                Tag=['num_' ParamName '_' num2str(icoord)];
            else
                Tag=['num_' ParamName];
            end
            if isfield(handles_panel,Tag)
                set(handles_panel.(Tag),'String',num2str(Data.(CivParamName)(icoord)))
                set(handles_panel.(Tag),'Visible','on')
            end
        end
    end
end
for ilist=1:numel(ListParamValue)
    ParamName=ListParamValue{ilist};
    CivParamName=[panel '_' ParamName];
    if strcmp(ParamName,'CorrSmooth')
        ParamName=['num_' ParamName];
    end
    if isfield(Data,CivParamName)
        if isfield(handles_panel,ParamName)
            set(handles_panel.(ParamName),'Value',Data.(CivParamName))
        end
    end
end
for ilist=1:numel(ListParamString)
    ParamName=ListParamString{ilist};
    CivParamName=[panel '_' ParamName];
    if isfield(Data,CivParamName)
        if isfield(handles_panel,ParamName)
            set(handles_panel.(ParamName),'String',Data.(CivParamName))
        end
    end
end

%------------------------------------------------------------------------
% --- Executes on button press in ImportParam.
%------------------------------------------------------------------------
function ImportParam_Callback(hObject, eventdata, handles)
hseries=findobj(allchild(0),'Tag','series');
hhseries=guidata(hseries);
InputTable=get(hhseries.InputTable,'Data');% read the input file(s) table in the GUI series
oldfile=InputTable{1,1};
if isempty(oldfile)
    % use a file name stored in prefdir
    dir_perso=prefdir;
    profil_perso=fullfile(dir_perso,'uvmat_perso.mat');
    if exist(profil_perso,'file')
        h=load (profil_perso);
        if isfield(h,'RootPath') && ischar(h.RootPath)
            oldfile=h.RootPath;
        end
    end
end
filexml=uigetfile_uvmat('pick a xml parameter file for civ',oldfile,'.xml');% get the xml file containing processing parameters
%proceed only if a file has been introduced by the browser
if ~isempty(filexml)
    Param=xml2struct(filexml);% read the input xml file as a Matlab structure

   % Param.Action.RUN=0; %desactivate the input RUN=1
    if ~isfield(Param,'InputTable')||~isfield(Param,'IndexRange')
        msgbox_uvmat('ERROR','invalid config file: open a file in a folder ''/0_XML''')
        return
    end
    check_input=0;
    if isfield(Param,'ActionInput')
        if isfield(Param.ActionInput,'Program')&& strcmp(Param.ActionInput.Program,'stereo_civ')
            fill_GUI(Param.ActionInput,handles.civ_input)% fill the elements of the GUI series with the input parameters
            set(handles.ConfigSource,'String',filexml)
            check_input=1;
            update_CivOptions(handles,0)             
        end
    end
    if ~check_input
        msgbox_uvmat('ERROR','invalid config file (not for civ_series')
        return
    end
end


%------------------------------------------------------------------------
% --- Executes on key press with selection of a uicontrol
%------------------------------------------------------------------------
function keyboard_callback(hObject,eventdata,handles)
    
ListExclude={'CheckCiv1','CheckFix1','CheckPatch1','CheckCiv2','CheckFix2','CheckPatch2','ref_i'};
if isempty(find(strcmp(get(gco,'Tag'),ListExclude),1))% if the selected uicontrol is not in the Exclude list
    set(handles.ConfigSource,'String','NEW')% indicate that the configuration is new
    set(handles.OK,'BackgroundColor',[1 0 1])%
    drawnow
end



function num_FieldSmooth_Callback(hObject, eventdata, handles)
% hObject    handle to num_FieldSmooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_FieldSmooth as text
%        str2double(get(hObject,'String')) returns contents of num_FieldSmooth as a double


% --- Executes during object creation, after setting all properties.
function num_FieldSmooth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_FieldSmooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_MaxDiff_Callback(hObject, eventdata, handles)
% hObject    handle to num_MaxDiff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_MaxDiff as text
%        str2double(get(hObject,'String')) returns contents of num_MaxDiff as a double


% --- Executes during object creation, after setting all properties.
function num_MaxDiff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_MaxDiff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_SubDomainSize_Callback(hObject, eventdata, handles)
% hObject    handle to num_SubDomainSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_SubDomainSize as text
%        str2double(get(hObject,'String')) returns contents of num_SubDomainSize as a double


% --- Executes during object creation, after setting all properties.
function num_SubDomainSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_SubDomainSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_Nx_Callback(hObject, eventdata, handles)
% hObject    handle to num_Nx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_Nx as text
%        str2double(get(hObject,'String')) returns contents of num_Nx as a double


% --- Executes during object creation, after setting all properties.
function num_Nx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_Nx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_Ny_Callback(hObject, eventdata, handles)
% hObject    handle to num_Ny (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_Ny as text
%        str2double(get(hObject,'String')) returns contents of num_Ny as a double


% --- Executes during object creation, after setting all properties.
function num_Ny_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_Ny (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in TestPatch2.
function togglebutton8_Callback(hObject, eventdata, handles)
% hObject    handle to TestPatch2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of TestPatch2


% % --- Executes on button press in CheckPatch3.
% function CheckPatch3_Callback(hObject, eventdata, handles)
% % hObject    handle to CheckPatch3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of CheckPatch3


% --- Executes on button press in CheckFmin2.
function CheckFmin2_Callback(hObject, eventdata, handles)
% hObject    handle to CheckFmin2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckFmin2


% --- Executes on button press in CheckF4.
function CheckF4_Callback(hObject, eventdata, handles)
% hObject    handle to CheckF4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckF4


% --- Executes on button press in CheckF3.
function CheckF3_Callback(hObject, eventdata, handles)
% hObject    handle to CheckF3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckF3


% --- Executes on button press in get_ref_fix2.
function checkbox56_Callback(hObject, eventdata, handles)
% hObject    handle to get_ref_fix2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of get_ref_fix2



function edit123_Callback(hObject, eventdata, handles)
% hObject    handle to ref_fix2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ref_fix2 as text
%        str2double(get(hObject,'String')) returns contents of ref_fix2 as a double


% --- Executes during object creation, after setting all properties.
function ref_fix2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ref_fix2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_MaxVel_Callback(hObject, eventdata, handles)
% hObject    handle to num_MaxVel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_MaxVel as text
%        str2double(get(hObject,'String')) returns contents of num_MaxVel as a double


% --- Executes during object creation, after setting all properties.
function num_MaxVel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_MaxVel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_MinVel_Callback(hObject, eventdata, handles)
% hObject    handle to num_MinVel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_MinVel as text
%        str2double(get(hObject,'String')) returns contents of num_MinVel as a double


% --- Executes during object creation, after setting all properties.
function num_MinVel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_MinVel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_MinCorr_Callback(hObject, eventdata, handles)
% hObject    handle to num_MinCorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_MinCorr as text
%        str2double(get(hObject,'String')) returns contents of num_MinCorr as a double


% --- Executes during object creation, after setting all properties.
function num_MinCorr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_MinCorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in field_ref2.
function field_ref2_Callback(hObject, eventdata, handles)
% hObject    handle to field_ref2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns field_ref2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from field_ref2


% --- Executes during object creation, after setting all properties.
function field_ref2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to field_ref2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% 
% % --- Executes on button press in CheckFix3.
% function CheckFix3_Callback(hObject, eventdata, handles)
% % hObject    handle to CheckFix3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of CheckFix3
% 


function num_CorrBoxSize_1_Callback(hObject, eventdata, handles)
% hObject    handle to num_CorrBoxSize_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_CorrBoxSize_1 as text
%        str2double(get(hObject,'String')) returns contents of num_CorrBoxSize_1 as a double


% --- Executes during object creation, after setting all properties.
function num_CorrBoxSize_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_CorrBoxSize_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_CorrBoxSize_2_Callback(hObject, eventdata, handles)
% hObject    handle to num_CorrBoxSize_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_CorrBoxSize_2 as text
%        str2double(get(hObject,'String')) returns contents of num_CorrBoxSize_2 as a double


% --- Executes during object creation, after setting all properties.
function num_CorrBoxSize_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_CorrBoxSize_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit114_Callback(hObject, eventdata, handles)
% hObject    handle to num_CorrSmooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_CorrSmooth as text
%        str2double(get(hObject,'String')) returns contents of num_CorrSmooth as a double


% --- Executes during object creation, after setting all properties.
function num_CorrSmooth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_CorrSmooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CheckDeformation.
function checkbox48_Callback(hObject, eventdata, handles)
% hObject    handle to CheckDeformation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckDeformation



function num_Dx_Callback(hObject, eventdata, handles)
% hObject    handle to num_Dx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_Dx as text
%        str2double(get(hObject,'String')) returns contents of num_Dx as a double


% --- Executes during object creation, after setting all properties.
function num_Dx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_Dx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_Dy_Callback(hObject, eventdata, handles)
% hObject    handle to num_Dy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_Dy as text
%        str2double(get(hObject,'String')) returns contents of num_Dy as a double


% --- Executes during object creation, after setting all properties.
function num_Dy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_Dy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CheckGrid.
function checkbox49_Callback(hObject, eventdata, handles)
% hObject    handle to CheckGrid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckGrid



function Grid_Callback(hObject, eventdata, handles)
% hObject    handle to Grid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Grid as text
%        str2double(get(hObject,'String')) returns contents of Grid as a double


% --- Executes during object creation, after setting all properties.
function Grid_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Grid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CheckMask.
function checkbox50_Callback(hObject, eventdata, handles)
% hObject    handle to CheckMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckMask



function Mask_Callback(hObject, eventdata, handles)
% hObject    handle to Mask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Mask as text
%        str2double(get(hObject,'String')) returns contents of Mask as a double


% --- Executes during object creation, after setting all properties.
function Mask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Mask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CheckThreshold.
function checkbox51_Callback(hObject, eventdata, handles)
% hObject    handle to CheckThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckThreshold



function num_MinIma_Callback(hObject, eventdata, handles)
% hObject    handle to num_MinIma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_MinIma as text
%        str2double(get(hObject,'String')) returns contents of num_MinIma as a double


% --- Executes during object creation, after setting all properties.
function num_MinIma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_MinIma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_MaxIma_Callback(hObject, eventdata, handles)
% hObject    handle to num_MaxIma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_MaxIma as text
%        str2double(get(hObject,'String')) returns contents of num_MaxIma as a double


% --- Executes during object creation, after setting all properties.
function num_MaxIma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_MaxIma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in TestCiv3.
function TestCiv3_Callback(hObject, eventdata, handles)
% hObject    handle to TestCiv3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of TestCiv3



function num_SearchBoxSize_1_Callback(hObject, eventdata, handles)
% hObject    handle to num_SearchBoxSize_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_SearchBoxSize_1 as text
%        str2double(get(hObject,'String')) returns contents of num_SearchBoxSize_1 as a double


% --- Executes during object creation, after setting all properties.
function num_SearchBoxSize_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_SearchBoxSize_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_SearchBoxSize_2_Callback(hObject, eventdata, handles)
% hObject    handle to num_SearchBoxSize_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_SearchBoxSize_2 as text
%        str2double(get(hObject,'String')) returns contents of num_SearchBoxSize_2 as a double


% --- Executes during object creation, after setting all properties.
function num_SearchBoxSize_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_SearchBoxSize_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object deletion, before destroying properties.
function num_MinCorr_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to num_MinCorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in CheckLSM.
function CheckLSM_Callback(hObject, eventdata, handles)
% hObject    handle to CheckLSM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% if get(hObject,'Value')==1
%  set(handles.Patch3,'Visible','on')
% else
%      set(handles.Patch3,'Visible','off')

% Hint: get(hObject,'Value') returns toggle state of CheckLSM



function num_resolution_Callback(hObject, eventdata, handles)
% hObject    handle to num_resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_resolution as text
%        str2double(get(hObject,'String')) returns contents of num_resolution as a double


% --- Executes during object creation, after setting all properties.
function num_resolution_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
