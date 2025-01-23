%'civ_input': function associated with the GUI 'civ_input.fig' to set the input parameters for civ_series
%------------------------------------------------------------------------
% function ParamOut = civ_input(Param)
%
% OUPUT:
% ParamOut: Matlab structure containing the parameters set by the GUI civ_input
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

function varargout = civ_input(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @civ_input_OpeningFcn, ...
    'gui_OutputFcn',  @civ_input_OutputFcn, ...
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
% --- Executes just before civ_input is made visible.
function civ_input_OpeningFcn(hObject, eventdata, handles, Param)
%------------------------------------------------------------------------
% This function has no output args, see OutputFcn.

%% General settings
handles.output = Param;
guidata(hObject, handles); % Update handles structure
set(hObject,'WindowButtonDownFcn',{'mouse_down'}) % allows mouse action with right button (zoom for uicontrol display)
set(hObject,'WindowKeyPressFcn',{@keyboard_callback,handles})%set keyboard action function
set(handles.ref_i,'KeyPressFcn',{@ref_i_KeyPressFcn,handles})%set keyboard action function
set(handles.ref_j,'KeyPressFcn',{@ref_i_KeyPressFcn,handles})%set keyboard action function
hseries=findobj(allchild(0),'Tag','series');% find the parent GUI 'series'
hhseries=guidata(hseries); %handles of the elements in 'series'
SeriesData=get(hseries,'UserData');% info stored in the GUI series 

%% set visibility options depending on the calling function (Param.Action.ActionName): 
switch Param.Action.ActionName
    case 'stereo_civ'
        set(handles.ListCompareMode,'Visible','off')
        set(handles.PairIndices,'Visible','off')
    case 'civ_series'
        set(handles.ListCompareMode,'Visible','on')
        set(handles.PairIndices,'Visible','on')
    case 'civ_3D'
        set(handles.ListCompareMode,'Visible','on')
        set(handles.PairIndices,'Visible','on')
        set(handles.title_z,'Visible','on')
        set(handles.num_CorrBoxSize_3,'Visible','on')
        set(handles.num_SearchRange_3,'Visible','on')
        set(handles.num_SearchBoxShift_3,'Visible','on')
        set(handles.num_Dz,'Visible','on')
        set(handles.title_Dz,'Visible','on')
end

%% input file info
NomTypeInput=Param.InputTable{1,4};
FileType='image';%fdefault
FileInfo=[];
if isfield(SeriesData,'FileInfo')
    FileType=SeriesData.FileInfo{1}.FileType;% info on the first input file series
    FieldType=SeriesData.FileInfo{1}.FieldType;% info on the first input file series
else
    set(hhseries.REFRESH,'BackgroundColor',[1 0 1])% indicate that the file input in series needs to be refreshed 
end

%% case of netcdf file as input, read the processing stage and look for corresponding images
ind_opening=0;%default
NomTypeNc='';
NomTypeImaA=NomTypeInput;
iview_image=1;%line # for the input images
if ismember( FileType,{'civdata','civdata_3D'})
        NomTypeNc=NomTypeInput;
        ind_opening=SeriesData.FileInfo{1}.CivStage;
        if isempty(regexp(NomTypeInput,'[ab|AB|-]', 'once'))
            set(handles.ListCompareMode,'Value',2) %mode displacement advised if the nomenclature does not involve index pairs
        else
            set(handles.ListCompareMode,'Value',1)
        end
        [Data,~,~,errormsg]=nc2struct(SeriesData.FileInfo{1}.FileName,[]);
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',['error in netcdf input file: ' errormsg])
            return
        end
        
        if size(Param.InputTable,1)==1     
             if isfield(Data,'Civ2_ImageA')
                 ImageName=Data.Civ2_ImageA;
             elseif isfield(Data,'Civ1_ImageA')
                 ImageName=Data.Civ1_ImageA;
             else
                  msgbox_uvmat('ERROR','no original image defined in netcdf input file ')
            return
             end
            series('display_file_name',hhseries,ImageName,'append');%append the image series to the input list
                    [~,~,~,~,~,~,~,~,NomTypeImaA]=fileparts_uvmat(ImageName);
        end

        iview_image=2;%line # for the input images
end
        
%% prepare the GUI with input parameters 
% 
set(handles.ref_i,'String',num2str(Param.IndexRange.first_i))
if isfield(Param.IndexRange,'first_j')
    set(handles.ref_j,'String',num2str(Param.IndexRange.first_j))
end
set(handles.ConfigSource,'String','\default')

%%  set the menus of image pairs and default selection for civ_input   %%%%%%%%%%%%%%%%%%%

%% display the min and max indices for the whole file series
if isempty(Param.IndexRange.MaxIndex_i)|| isempty(Param.IndexRange.MinIndex_i)
    msgbox_uvmat('ERROR','REFRESH the input files in the GUI series')
     return
end

MaxIndex_i=Param.IndexRange.MaxIndex_i(1);
MinIndex_i=Param.IndexRange.MinIndex_i(1);
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


%%  transfer the time from the GUI series, or use file index by default
time=[];
TimeUnit='frame'; %default
CoordUnit='';%default
pxcm_search=1;
if isfield(SeriesData,'Time') &&numel(SeriesData.Time')>=1 && ~isempty(SeriesData.Time{1})
    time=SeriesData.Time{1};
end
if isfield(Param.IndexRange,'TimeUnit')&&~isempty(Param.IndexRange.TimeUnit)
    TimeUnit=Param.IndexRange.TimeUnit;
end 
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
% set(handles.SearchRange,'UserData', pxcm_search);


%% set the civ_input options, depending on the input file content if a nc file has been opened
ListOptions={'CheckCiv1', 'CheckFix1' 'CheckPatch1', 'CheckCiv2', 'CheckFix2', 'CheckPatch2'};
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
        update_CivOptions(handles,0)
        update_frame(handles,ListOptions{index})
    end
else  %case of netcdf file opening, start with the stage read in the file if the input file is being refreshed
    %     if isequal(get(hhseries.REFRESH,'BackgroundColor'),[1 1 0]) &&...
    %             ~(isfield(Param,'ActionInput') && isfield(Param.ActionInput,'ConfigSource'))
    for index = 1:min(ind_opening,5)
        set(handles.(ListOptions{index}),'value',0)
        fill_civ_input(Data,handles); %fill civ_input with the parameters retrieved from an input Civ file
    end
    if isempty(FileInfo)
        FileInfo.FileName='';
    end
    set(handles.ConfigSource,'String',FileInfo.FileName);
    if ind_opening<6
        for index = 1:ind_opening
            set(handles.(ListOptions{index}),'value',0)
            set(handles.(ListOptions{index}),'String',regexprep(ListOptions{index},'Check','redo '))
        end
%         for index = ind_opening+1:6
%             set(handles.(ListOptions{index}),'value',1)
%         end
        set(handles.CheckCiv3,'Visible','off')% make visible the switch 'iterate/repet' for Civ2.
        set(handles.CheckCiv3,'Value',0)% select'iterate/repet' by default
    else
        for index = 1:3
            set(handles.(ListOptions{index}),'value',0)
        end
%         for index = 4:6
%             set(handles.(ListOptions{index}),'value',1)
%         end
        set(handles.CheckCiv3,'Visible','on')% make visible the switch 'iterate/repet' for Civ2.
        set(handles.CheckCiv3,'Value',1)% select'iterate/repet' by default
    end
    checkrefresh=1;
    %     end
    % if ind_opening==6
    %     set(handles.CheckCiv3,'Visible','on')% make visible the switch 'iterate/repet' for Civ2.
    % else
    %     set(handles.CheckCiv3,'Visible','off')
    % end
end

%% introduce the stored Civ parameters  if available (from previous input or ImportConfig in series)
if ~checkrefresh && isfield(Param,'ActionInput')&& strcmp(Param.ActionInput.Program,Param.Action.ActionName)% the program fits with the stored data
    fill_GUI(Param.ActionInput,hObject);%fill the GUI with the parameters retrieved from the input Param

    if isfield(Param.ActionInput,'Civ1')&& isfield(Param.ActionInput.Civ1,'SearchBoxSize')%transform from SearchBoxSize to SearchRange (old to new convention)
               SearchRange=round((Param.ActionInput.Civ1.SearchBoxSize-Param.ActionInput.Civ1.CorrBoxSize)/2);
                set(handles.num_SearchRange_1(1),'String',num2str(SearchRange(1)))
                set(handles.num_SearchRange_2(1),'String',num2str(SearchRange(2)))
            end
            if isfield(Param.ActionInput,'Civ2')&& isfield(Param.ActionInput.Civ2,'SearchBoxSize')
               SearchRange=round((Param.ActionInput.Civ2.SearchBoxSize-Param.ActionInput.Civ2.CorrBoxSize)/2);
                set(handles.num_SearchRange_1(2),'String',num2str(SearchRange(1)))
                set(handles.num_SearchRange_2(2),'String',num2str(SearchRange(2)))
            end
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
    if isfield(Param.ActionInput,'Civ2')
        CheckDeformation_Callback(hObject, eventdata, handles)
    end
end
if isfield(Param,'ActionInput') && isfield(Param.ActionInput,'ListCompareMode')&&...
        strcmp(Param.ActionInput.ListCompareMode,'displacement')
    set(handles.PairIndices,'Visible','off')
        set(handles.CheckRefFile,'Visible','on')
else
    set(handles.CheckRefFile,'Visible','off')
end

%% reinitialise pair menus
set(handles.ListPairMode,'Value',1)
set(handles.ListPairMode,'String',{''})
set(handles.ListPairCiv1,'Value',1)
set(handles.ListPairCiv1,'String',{''})
set(handles.ListPairCiv2,'Value',1)
set(handles.ListPairCiv2,'String',{''}) 

%% set the menu and default choice of civ pairs
if isequal(MaxIndex_j,MinIndex_j)|| strcmp(Param.Action.ActionName,'civ_3D')% no possibility of j pairs
    PairMenu={'series(Di)'};
elseif MaxIndex_j-MinIndex_j==1
    PairMenu={'pair j1-j2'};
elseif  MaxIndex_i==MinIndex_i && MaxIndex_j-MinIndex_j>2% simple series in j
    PairMenu={'pair j1-j2';'series(Dj)'};
else
    PairMenu={'pair j1-j2';'series(Dj)';'series(Di)'};%multiple choice
end
set(handles.ListPairMode,'String',PairMenu)

%% set default choice of pair mode
PairIndex=[];
if isfield(Param,'ActionInput') && isfield(Param.ActionInput,'PairIndices')
    PairIndex=find(strcmp(Param.ActionInput.PairIndices.ListPairMode,PairMenu));%retrieve the previous option
end
if strcmp(Param.Action.ActionName,'civ_3D')
    PairIndex=1;
else
    if isempty(PairIndex)
        if ~isfield(Param.IndexRange,'first_j')||isequal(MaxIndex_j,MinIndex_j)% no possibility of j pairs
            PairIndex=1;
        elseif  MaxIndex_i==1 && MaxIndex_j>1% simple series in j
            if  MaxIndex_j <= 10
                PairIndex=1;% advice 'pair j1-j2' except in MaxIndex_j is large
            end
        else
            if strcmp(NomTypeNc,'_1-2_1')
                PairIndex=3;% advise 'series(Di)'
            elseif  MaxIndex_j <= 10
                PairIndex=1;% advice 'pair j1-j2' except in MaxIndex_j is large
            else
                PairIndex=2;% advice 'Dj'
            end
        end
    end
end
set(handles.ListPairMode,'Value',PairIndex);

%% indicate the min and max indices i and j on the GUI
set(handles.MinIndex_i,'String',num2str(MinIndex_i))
set(handles.MaxIndex_i,'String',num2str(MaxIndex_i))
set(handles.MinIndex_j,'String',num2str(MinIndex_j))
set(handles.MaxIndex_j,'String',num2str(MaxIndex_j))

%% set the reference indices from the input file indices
if ~(isfield(Param,'ActionInput') && isfield(Param.ActionInput,'ConfigSource'))
update_CivOptions(handles,ind_opening)% fill the menu of possible pairs
end

%% list the possible index pairs, depending on the option set in ListPairMode
ListPairMode_Callback([], [], handles)

%% set the GUI to modal: wait for OK to close
set(handles.civ_input,'WindowStyle','modal')% Make the GUI modal
drawnow
uiwait(handles.civ_input);% wait for OK action to end the function


%------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = civ_input_OutputFcn(hObject, eventdata, handles)
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
%Param.CheckCiv1=1;
Param.Civ1.CorrBoxSize=[31 31 1];
Param.Civ1.SearchRange=[15 15];
Param.Civ1.SearchBoxShift=[0 0];
Param.Civ1.CorrSmooth=1;
Param.Civ1.Dx=20;
Param.Civ1.Dy=20;
Param.Civ1.CheckGrid=0;
Param.Civ1.CheckMask=0;
Param.Civ1.Mask='';
Param.Civ1.CheckThreshold=0;
Param.Civ1.TestCiv1=0;

%% Fix1 parameters
Param.Fix1.MinCorr=0.2000;

%% Patch1 parameters
%Param.CheckPatch1=1;
Param.Patch1.FieldSmooth=200;
Param.Patch1.MaxDiff=1.5;
Param.Patch1.SubDomainSize=125;

%% Civ2 parameters
%Param.CheckCiv2=1;
Param.Civ2.CorrBoxSize=[21 21];
Param.Civ2.SearchRange=[3 3];
Param.Civ2.CorrSmooth=1;
Param.Civ2.Dx=10;
Param.Civ2.Dy=10;
Param.Civ2.CheckGrid=0;
Param.Civ2.CheckMask=0;
Param.Civ2.Mask='';
Param.Civ2.CheckThreshold=0;

%% Fix2 parameters
Param.Fix2.MinCorr=0.2000;

%% Patch2 parameters
Param.Patch2.FieldSmooth=20;
Param.Patch2.MaxDiff=1;
Param.Patch2.SubDomainSize=250;

fill_GUI(Param,handles.civ_input)% fill the elements of the GUI series with the input parameters
update_CivOptions(handles,0)

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
update_CivOptions(handles,0)
update_frame(handles,'CheckCiv1')


%------------------------------------------------------------------------
% --- Executes on button press in CheckFix1.
function CheckFix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)
update_frame(handles,'CheckFix1')

%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch1.
function CheckPatch1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)
update_frame(handles,'CheckPatch1')


%------------------------------------------------------------------------
% --- Executes on button press in CheckCiv2.
function CheckCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)
update_frame(handles,'CheckCiv2')

%------------------------------------------------------------------------
% --- Executes on button press in CheckFix2.
function CheckFix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)
update_frame(handles,'CheckFix2')

%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch2.
function CheckPatch2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)
update_frame(handles,'CheckPatch2')

function update_frame(handles,option)
if get(handles.(option),'Value')
    option=regexprep(option,'Check','');
set(handles.(option),'Visible','on')
children=get(handles.(option),'children');
set(children,'Enable','on')
else
    option=regexprep(option,'Check','');
    set(handles.(option),'Visible','off')
end

%------------------------------------------------------------------------
% --- activated by any checkbox controling the selection of Civ1,Fix1,Patch1,Civ2,Fix2,Patch2
function update_CivOptions(handles,opening)
%------------------------------------------------------------------------
if opening>0
    set(handles.CheckCiv2,'UserData',opening)% store the info on the current status of the civ processing
end
checkbox=zeros(1,6);
checkbox(1)=get(handles.CheckCiv1,'Value');
checkbox(2)=get(handles.CheckFix1,'Value');
checkbox(3)=get(handles.CheckPatch1,'Value');
checkbox(4)=get(handles.CheckCiv2,'Value');
checkbox(5)=get(handles.CheckFix2,'Value');
checkbox(6)=get(handles.CheckPatch2,'Value');
if opening==0
    errormsg=find_netcpair_civ(handles,1); % select the available netcdf files
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg)
    end
end
if max(checkbox(4:6))>0% case of civ2 pair choice needed
    set(handles.TitlePairCiv2,'Visible','on')
    set(handles.ListPairCiv2,'Visible','on')
    if ~opening
        errormsg=find_netcpair_civ(handles,2); % select the available netcdf files
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',errormsg)
        end
    end
else
    set(handles.ListPairCiv2,'Visible','off')
end
hseries=findobj(allchild(0),'Tag','series');% find the parent GUI 'series'
hhseries=guidata(hseries); %handles of the elements in 'series'
InputTable=get(hhseries.InputTable,'Data');
if size(InputTable,1)>=1 && strcmp(InputTable{1,5},'.nc') && max(checkbox(1:3))==0 %&& get(handles.CheckCiv2,'UserData')==6,% no operation asked before Civ2 and input file ready for civ3
    set(handles.CheckCiv3,'Visible','on')
else
    set(handles.CheckCiv3,'Visible','off')
end

%% set the visibility of the different panels
options={'Civ1','Fix1','Patch1','Civ2','Fix2','Patch2'};
for ilist=1:length(options)
    if checkbox(ilist)
%          set(handles.(options{ilist}),'Visible','on')
        set(handles.(options{ilist}),'Enable','on')
%         set(handles.(['Check' options{ilist}]),'Strin
    else
%         set(handles.(options{ilist}),'Visible','off')
        set(handles.(options{ilist}),'Enable','off')
    end
end

%------------------------------------------------------------------------
% --- Executes on button press in OK: processing on local computer
function OK_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

ActionInput=read_GUI(handles.civ_input);% read the infos on the GUI civ_input

%% correct input inconsistencies
if isfield(ActionInput,'Civ1')
    checkeven=(mod(ActionInput.Civ1.CorrBoxSize,2)==0);
    ActionInput.Civ1.CorrBoxSize(checkeven)=ActionInput.Civ1.CorrBoxSize(checkeven)+1;% set correlation box sizes to odd values
    %ActionInput.Civ1.SearchBoxSize(1:2)=max(ActionInput.Civ1.SearchBoxSize(1:2),ActionInput.Civ1.CorrBoxSize(1:2)+8);% insure that the search box size is large enough
    %checkeven=(mod(ActionInput.Civ1.SearchBoxSize,2)==0);
    %ActionInput.Civ1.SearchBoxSize(checkeven)=ActionInput.Civ1.SearchBoxSize(checkeven)+1;% set search box sizes to odd values
end
if isfield(ActionInput,'Civ2')
    checkeven=(mod(ActionInput.Civ2.CorrBoxSize,2)==0);
    ActionInput.Civ2.CorrBoxSize(checkeven)=ActionInput.Civ2.CorrBoxSize(checkeven)+1;% set correlation box sizes to odd values
    %ActionInput.Civ2.SearchBoxSize=max(ActionInput.Civ2.SearchBoxSize,ActionInput.Civ2.CorrBoxSize+4);
    % checkeven=(mod(ActionInput.Civ2.SearchBoxSize,2)==0);
    %ActionInput.Civ2.SearchBoxSize(checkeven)=ActionInput.Civ2.SearchBoxSize(checkeven)+1;% set search box sizes to odd values
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
switch option
    case 'PIV'
        PairIndices='on';% needs to define index pairs for PIV       
    % case 'PIV volume'
    %     PairIndices='on';% needs to define index pairs for PIV
    %     set(handles.ListPairMode,'Value',1)
    %     set(handles.ListPairMode,'String',{'series(Di)'})
    %     ListPairMode_Callback(hObject, eventdata, handles)
    case 'displacement'
        OriginIndex='on';%define a frame origin for displacement
end
set(handles.num_OriginIndex,'Visible',OriginIndex)
set(handles.OriginIndex_title,'Visible',OriginIndex)
set(handles.CheckRefFile,'Visible',OriginIndex)
set(handles.RefFile,'Visible',OriginIndex)
set(handles.PairIndices,'Visible',PairIndices)
ListPairMode_Callback(hObject,eventdata,handles)
if strcmp(OriginIndex,'on')
    set(handles.CheckRefFile,'Value',1)
    CheckRefFile_Callback(hObject,eventdata,handles)
end
        


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
    mode_selected='displacement';
else
    mode_list=get(handles.ListPairMode,'String');
    if ischar(mode_list)
        mode_list={mode_list};
    end  
    mode_value=get(handles.ListPairMode,'Value');
    if isempty(mode_value)|| mode_value>numel(mode_list)
        mode_value=1;
    end
    mode_selected=mode_list{mode_value};
end
ref_i=str2double(get(handles.ref_i,'String'));
CivInputData=get(handles.civ_input,'UserData');
TimeUnit=get(handles.TimeUnit,'String');
checkframe=strcmp(TimeUnit,'frame');
time=CivInputData.Time;
siztime=size(CivInputData.Time);
nbfield=siztime(1)-1;
nbfield2=siztime(2)-1;
%indchosen=1;  %%first pair selected by default
% in mode 'pair j1-j2', j1 and j2 are the file indices, else the indices
% are relative to the reference indices ref_i and ref_j respectively.
if isequal(mode_selected,'pair j1-j2')
    dt=1;
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
            if size(time,2)>1 && ~checkframe && size(CivInputData.Time,1)>ref_i && size(CivInputData.Time,2)>numod_b
                dt(numod_a,numod_b)=CivInputData.Time(ref_i+1,numod_b+1)-CivInputData.Time(ref_i+1,numod_a+1);%first time interval dt
                displ_dt(index)=dt(numod_a,numod_b);
            else
                displ_dt(index)=1;
            end
        end
    end
    [dtsort,indsort]=sort(displ_dt);
    enable_j(handles, 'off')
elseif isequal(mode_selected,'series(Dj)') %| isequal(mode,'st_series(Dj)')
    enable_j(handles, 'on')
elseif isequal(mode_selected,'series(Di)') %| isequal(mode,'st_series(Di)')
    enable_i(handles, 'on')
    if nbfield2 > 1
        enable_j(handles, 'on')
    else
        enable_j(handles, 'off')
    end
elseif isequal(mode_selected,'displacement')%the pairs have the same indices
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
errormsg=find_netcpair_civ( handles,1);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
end

%------------------------------------------------------------------------
function enable_i(handles, state)
set(handles.itext,'Visible',state)
set(handles.MaxIndex_i,'Visible',state)
set(handles.ref_i,'Visible',state)

%------------------------------------------------------------------------
function enable_j(handles, state)
set(handles.jtext,'Visible',state)
set(handles.MinIndex_j,'Visible',state)
set(handles.MaxIndex_j,'Visible',state)
set(handles.ref_j,'Visible',state)

%------------------------------------------------------------------------
% --- Executes on selection change in ListPairCiv1.
function ListPairCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
%reproduce by default the chosen pair in the checkciv2 menu
set(handles.ListPairCiv2,'Value',get(handles.ListPairCiv1,'Value'))%civ2 selection the same as civ1 by default
ListPairCiv2_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on selection change in ListPairCiv2.
function ListPairCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function ref_i_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.ListPairMode,'String');
mode_value=get(handles.ListPairMode,'Value');
mode_selected=mode_list{mode_value};
errormsg=find_netcpair_civ(handles,1);% update the menu of pairs depending on the available netcdf files
if isequal(mode_selected,'series(Di)') || ...% we do patch2 only
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

function errormsg=find_netcpair_civ(handles,index)
%------------------------------------------------------------------------
set(gcf,'Pointer','watch')% set the mouse pointer to 'watch' (clock)

%% initialisation
errormsg='';
CivInputData=get(handles.civ_input,'UserData');
compare_list=get(handles.ListCompareMode,'String');
val=get(handles.ListCompareMode,'Value');
compare=compare_list{val};
mode_selected='displacement';
if ~strcmp(compare,'displacement')%||strcmp(compare,'shift')
 
    mode_list=get(handles.ListPairMode,'String');
    mode_value=get(handles.ListPairMode,'Value');
    if isempty(mode_value)||mode_value>numel(mode_list)
        mode_value=1;
    end
    if isempty(mode_list)
        return
    end
    mode_selected=mode_list{mode_value};
end
nom_type_ima=CivInputData.NomTypeIma;
menu_pair=get(handles.ListPairCiv1,'String');%previous menu of ListPairCiv1
PairCiv1Init=menu_pair{get(handles.ListPairCiv1,'Value')};%previous choice of pair
menu_pair=get(handles.ListPairCiv2,'String');%previous menu of ListPairCiv1
PairCiv2Init=menu_pair{get(handles.ListPairCiv2,'Value')};%previous choice of pair

%% reads .nc subdirectoy and image numbers from the interface
%SubDirImages=get(handles.Civ1_ImageA,'String');
%TODO: determine
%subdir_civ1=[SubDirImages get(handles.Civ1_ImageB,'String')];%subdirectory subdir_civ1 for the netcdf data
%subdir_civ2=[SubDirImages get(handles.Civ2_ImageA,'String')];%subdirectory subdir_civ2 for the netcdf data
ref_i=str2double(get(handles.ref_i,'String'));
ref_j=[];
if isequal(mode_selected,'pair j1-j2')%|isequal(mode,'st_pair j1-j2')
     ref_j=0;
    MinIndex_j=str2num(get(handles.MinIndex_j,'String'));
        MaxIndex_j=str2num(get(handles.MaxIndex_j,'String'));
        if MaxIndex_j-MinIndex_j>10
            mode_selected= 'series(Dj)';
           ref_j= str2double(get(handles.ref_j,'String'));
        end
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

%% determine the menu display in .ListPairCiv1
switch mode_selected
    case 'series(Di)'
        for ipair=1:nbpair
            if select(ipair)
                displ_pair{ipair}=['Di= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2))];
                displ_pair_dt{ipair}=displ_pair{ipair};
                if ~checkframe
                    if size(Time,1)>=ref_i+1+ceil(ipair/2) && size(Time,2)>=ref_j+1&& ref_i-floor(ipair/2)>=0 && ref_j>=0
                        dt=Time(ref_i+1+ceil(ipair/2),ref_j+1)-Time(ref_i+1-floor(ipair/2),ref_j+1);%Time interval dtref_j+1
                        displ_pair_dt{ipair}=[displ_pair_dt{ipair} ' :dt= ' num2str(dt*1000)];
                    end
                else
                    dt=ipair/1000;
                    displ_pair_dt{ipair}=[displ_pair_dt{ipair} ' :dt= ' num2str(ipair)];
                end
            else
                displ_pair{ipair}='...';
                displ_pair_dt{ipair}='...'; %pair not displayed in the menu
            end
        end
    case 'series(Dj)'
        for ipair=1:nbpair
            if select(ipair)
                displ_pair{ipair}=['Dj= ' num2str(-floor(ipair/2)) '|' num2str(ceil(ipair/2))];
                displ_pair_dt{ipair}=displ_pair{ipair};
                if ~checkframe
                    if size(Time,2)>=ref_j+1+ceil(ipair/2) && size(Time,1)>=ref_i+1 && ref_j-floor(ipair/2)>=0 && ref_i>=0
                        dt=Time(ref_i+1,ref_j+1+ceil(ipair/2))-Time(ref_i+1,ref_j+1-floor(ipair/2));%Time interval dtref_j+1
                        displ_pair_dt{ipair}=[displ_pair_dt{ipair} ' :dt= ' num2str(dt*1000)];
                    end
                else
                    dt=ipair/1000;
                    displ_pair_dt{ipair}=[displ_pair_dt{ipair} ' :dt= ' num2str(dt*1000)];
                end
            else
                displ_pair{ipair}='...'; %pair not displayed in the menu
                displ_pair_dt{ipair}='...'; %pair not displayed in the menu
            end
        end
    case 'pair j1-j2'%case of pairs
%         MinIndex_j=str2num(get(handles.MinIndex_j,'String'));
%         MaxIndex_j=str2num(get(handles.MaxIndex_j,'String'));
%         if MaxIndex_j-MinIndex_j>10
%             disp('too many pairs, switch to mode series(Dj)')
%             return
%         end
        index_pair=0;
        %get all the Time intervals in bursts
        displ_pair_dt='';
        for numod_a=MinIndex_j:MaxIndex_j-1 %nbfield2 always >=2 for 'pair j1-j2' mode
            for numod_b=(numod_a+1):MaxIndex_j
                index_pair=index_pair+1;
                displ_pair{index_pair}=['j= ' num2stra(numod_a,nom_type_ima) '-' num2stra(numod_b,nom_type_ima)];
                displ_pair_dt{index_pair}=displ_pair{index_pair};
                dt(index_pair)=numod_b-numod_a;%default dt
                if size(Time,1)>ref_i && size(Time,2)>numod_b  % && ~checkframe
                    dt(index_pair)=Time(ref_i+1,numod_b+1)-Time(ref_i+1,numod_a+1);% Time interval dt
                    displ_pair_dt{index_pair}=[displ_pair_dt{index_pair} ' :dt= ' num2str(dt(index_pair)*1000)];
                end
            end
            
        end
        if index_pair ~=0
        [tild,indsort]=sort(dt);
        displ_pair=displ_pair(indsort);
        displ_pair_dt=displ_pair_dt(indsort);
        end
    case 'displacement'
%         displ_pair={'Di=Dj=0'};
%         displ_pair_dt={'Di=Dj=0'};
        set(handles.PairIndices,'Visible','off')
end
if index==1 && ~strcmp(mode_selected,'displacement')
    set(handles.ListPairCiv1,'String',displ_pair_dt');
end

%% determine the default selection in the pair menu for Civ1
%ichoice=find(select,1);% index of first selected pair
%if (isempty(ichoice) || ichoice < 1); ichoice=1; end;
end_pair=regexp(PairCiv1Init,' :dt=');
if ~isempty(end_pair)
    PairCiv1Init=PairCiv1Init(1:end_pair-1);
end
ichoice=find(strcmp(PairCiv1Init,displ_pair'),1);
if ~isempty(ichoice)
    set(handles.ListPairCiv1,'Value',ichoice);% first valid pair proposed by default in the menu
else
   set(handles.ListPairCiv1,'Value',1) 
end

%% determine the default selection in the pair menu for Civ2
if ~strcmp(mode_selected,'displacement')
if strcmp(get(handles.ListPairCiv2,'Visible'),'on')
    end_pair=regexp(PairCiv2Init,' :dt=');
    if ~isempty(end_pair)
        PairCiv2Init=PairCiv2Init(1:end_pair-1);
    end
    ichoice=find(strcmp(PairCiv2Init,displ_pair'),1);
    if ~isempty(ichoice)
        set(handles.ListPairCiv2,'Value',ichoice);% first valid pair proposed by default in the menu
    else
        set(handles.ListPairCiv2,'Value',1)
    end
else
    set(handles.ListPairCiv2,'Value',get(handles.ListPairCiv1,'Value'))% initiate the choice of Civ2 as a reproduction of if civ1
end
set(handles.ListPairCiv2,'String',displ_pair_dt');
end
set(gcf,'Pointer','arrow')% Indicate that the process is finished


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
% --- Executes on button press in SearchRange: determine the search range num_SearchRange_1,num_SearchRange_2
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
% ---  determine the search range num_SearchRange_1,num_SearchRange_2 and shift
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
    shiftx=round((umin+umax)/2);
    shifty=round((vmin+vmax)/2);
    isx=(umax+2-shiftx)*2+param_civ1.CorrBoxSize(1);
    isx=2*ceil(isx/2)+1;
    isy=(vmax+2-shifty)*2+param_civ1.CorrBoxSize(2);
    isy=2*ceil(isy/2)+1;
    set(handles.num_SearchBoxShift_1,'String',num2str(shiftx));
    set(handles.num_SearchBoxShift_2,'String',num2str(shifty));
    set(handles.num_SearchRange_1,'String',num2str(isx));
    set(handles.num_SearchRange_2,'String',num2str(isy));
end

%------------------------------------------------------------------------
% --- Executes on selection in menu CorrSmooth.
function num_CorrSmooth_Callback(hObject, eventdata, handles)
set(handles.ConfigSource,'String','NEW')
set(handles.OK,'BackgroundColor',[1 0 1])
%------------------------------------------------------------------------

% --- Executes on button press in CheckDeformation.
function CheckDeformation_Callback(hObject, eventdata, handles)
set(handles.ConfigSource,'String','NEW')
set(handles.OK,'BackgroundColor',[1 0 1])
handles_CoorSmooth=findobj(get(handles.Civ2,'children'),'Tag','num_CorrSmooth');
if get(handles.CheckDeformation,'Value')   
    set(handles_CoorSmooth,'Visible','off')
else
    set(handles_CoorSmooth,'Visible','on')
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
gridfiles=dir([Name '_*grid_*.nc']);%look for grid files
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
%         SubDir='CIV_INPUT'; %default subdirectory
%     else
%         msgbox_uvmat('ERROR','select CheckCiv1 to perform a new civ_input operation')
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
%         SubDir='CIV_INPUT'; %default subdirectory
%     else
%         msgbox_uvmat('ERROR','select CheckCiv2 to perform a new civ_input operation')
%         return
%     end
% end
% set(handles.Civ2_ImageA,'String',SubDir);

%------------------------------------------------------------------------
% --- Executes on button press in CheckGrid.
function CheckGrid_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
hparent=get(hObject,'parent');
PanelName=get(hparent,'tag');
handle_txtbox=handles.Grid
if strcmp(PanelName,'civ2')
    handle_txtbox=handle_txtbox(2);
end
% hchildren=get(hparent,'children');
% handle_txtbox=findobj(hchildren,'tag','Grid');% look for the grid name box in the same panel
% handle_NbSlice=findobj(hchildren,'tag','num_NbSlice');% look for the mask name box in the same panel
testgrid=false;
corrstatus='on';
if get(hObject,'Value')% if the checkbox is activated
    hseries=findobj(allchild(0),'Tag','series');
    hhseries=guidata(hseries);
    InputTable=get(hhseries.InputTable,'Data');
    % browse for a grid file
    filegrid= uigetfile_uvmat('pick a grid netcdf file (made by script_makegrid.m):',InputTable{1,1},'.nc');
    if ~isempty(filegrid)
        [FilePath,FileName,FileExt]=fileparts(filegrid);
        Data=nc2struct(filegrid);
        if isfield(Data,'Grid')
        testgrid=true;
        end
        if isfield(Data,'CorrBox')
        corrstatus='off';
        end
    end
end
if testgrid
    set(handle_txtbox,'Visible','on')
    set(handle_txtbox,'String',filegrid)
    set(handles.num_Dx,'Visible','off')
    set(handles.num_Dy,'Visible','off')
else
    set(handles.num_Dx,'Visible','on')
    set(handles.num_Dy,'Visible','on')
    set(hObject,'Value',0)
    set(handle_txtbox,'Visible','off')
end

set(handles.num_CorrBoxSize_1,'Visible',corrstatus)
set(handles.num_CorrBoxSize_2,'Visible',corrstatus)


%% if hObject is on the checkciv1 frame, duplicate action for checkciv2 frame
% PanelName=get(hparent,'tag');
% if strcmp(PanelName,'Civ1')
%     hchildren=get(handles.Civ2,'children');
%     handle_checkbox=findobj(hchildren,'tag','CheckGrid');
%     handle_txtbox=findobj(hchildren,'tag','Grid');
%     handle_dx=findobj(hchildren,'tag','num_Dx');
%     handle_dy=findobj(hchildren,'tag','num_Dy');
%     handle_title_dx=findobj(hchildren,'tag','title_Dx');
%     handle_title_dy=findobj(hchildren,'tag','title_Dy');
%     %set(handle_checkbox,'UserData',filegrid);%store for future use
%     if testgrid
%         set(handle_checkbox,'Value',1);
%         set(handle_dx,'Visible','off');
%         set(handle_dy,'Visible','off');
%         set(handle_title_dx,'Visible','off');
%         set(handle_title_dy,'Visible','off');
%         set(handle_txtbox,'Visible','on')
%         set(handle_txtbox,'String',filegrid)
%     end 
% end
set(handles.ConfigSource,'String','NEW')
set(handles.OK,'BackgroundColor',[1 0 1])

%------------------------------------------------------------------------
% --- Executes on button press in CheckMask: common to all panels (civ1, Civ2..)
function CheckMask_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
hparent=get(hObject,'parent');
hchildren=get(hparent,'children');
handle_txtbox=findobj(hchildren,'tag','Mask');% look for the mask name box in the same panel
% handle_NbSlice=findobj(hchildren,'tag','num_NbSlice');% look for the mask name box in the same panel
testmask=0;
if get(hObject,'Value')% if the checkbox is activated
    hseries=findobj(allchild(0),'Tag','series');
    hhseries=guidata(hseries);
    InputTable=get(hhseries.InputTable,'Data');
    if strcmp(InputTable{1,5},'.nc')
        ind_A=2;%case of nc file as input (for civ3), image in second line
    else
        ind_A=1;% line index of the (first) image series
    end
    % browse for a mask
    filemask= uigetfile_uvmat('pick a mask image file:',InputTable{ind_A,1},'image');
    if ~isempty(filemask)
        [FilePath,FileName,FileExt]=fileparts(filemask);
        [RootPath,SubDir,RootFile,i1_series,i2,j1,j2,NomType]=find_file_series(FilePath,[FileName FileExt]);
        if strcmp(NomType,'_1')
            NbSlice=i1_series(1,2,end);
            set(handles.num_NbSlice,'String',num2str(NbSlice))
        elseif ~strcmp(NomType,'*')
            msgbox_uvmat('ERROR','multilevel masks must be labeled with a single index as _1,_2,...');
            return
        end
        set(hObject,'UserData',filemask);%store for future use
        testmask=1;
    end
end
if testmask
    set(handles.Mask,'Visible','on')
    set(handles.Mask,'String',filemask)
    set(handles.CheckMask,'Value',1)
    if strcmp(NomType,'_1')
        set(handles.num_NbSlice,'Visible','on')
    end
else
    set(hObject,'Value',0);
    set(handle_txtbox,'Visible','off')
    set(handles.num_NbSlice,'Visible','off')
end
set(handles.ConfigSource,'String','NEW')
set(handles.ConfigSource,'BackgroundColor',[1 0 1])

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
set(handles.ConfigSource,'String','NEW')
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
    set(handles.CheckFix1,'value',0)% desactivate next step
    set(handles.CheckPatch1,'value',0)% desactivate next step
    set(handles.CheckCiv2,'value',0)% desactivate next step
    set(handles.CheckFix2,'value',0)% desactivate next step
    set(handles.CheckPatch2,'value',0)% desactivate next step
    update_CivOptions(handles,0)
    % get info from the GUI 'series'
    hseries=findobj(allchild(0),'Tag','series');
    Param=read_GUI(hseries);
    Param.Action.RUN=1;
    Param.ActionInput=read_GUI(handles.civ_input);
    i1=str2num(get(handles.ref_i,'String'));  %references indices
    i2=i1;
    j1=1;
    if strcmp(get(handles.ref_j,'Visible'),'on')
        j1=str2num(get(handles.ref_j,'String'));
    end
    j2=j1;
    str_civ=Param.ActionInput.PairIndices.ListPairCiv1;
    r=regexp(str_civ,'^\D(?<ind>[i|j])=( -| )(?<num1>\d+)\|(?<num2>\d+)','names');
    if ~isempty(r)
        if strcmp(r.ind,'i')
            i1=i1-str2num(r.num1);
            i2=i2 +str2num(r.num2);
        elseif strcmp(r.ind,'j')
            j1=j1-str2num(r.num1);
            j2=j2 +str2num(r.num2);
        end
    else % mode='j1-j2';
        r=regexp(str_civ,'^j= (?<num1>[a-z])-(?<num2>[a-z])','names');
        if isempty(r)
            r=regexp(str_civ,'^j= (?<num1>[A-Z])-(?<num2>[A-Z])','names');
            if isempty(r)
                r=regexp(str_civ,'^j= (?<num1>\d+)-(?<num2>\d+)','names');
            end
        end
        if isempty(r)
            disp('wrong pair mode input option')
        else
            j1=stra2num(r.num1);
            j2=stra2num(r.num2);
        end
    end
    
    par_civ1=Param.ActionInput.Civ1;
      
    if strcmp(Param.ActionInput.ListCompareMode,'displacement')
        ImageName_A=Param.ActionInput.RefFile;
    else
        RootPath_A=Param.InputTable{1,1};
        SubDir_A=Param.InputTable{1,2};
        RootFile_A=Param.InputTable{1,3};
        NomType_A=Param.InputTable{1,4};
        FileExt_A=Param.InputTable{1,5};
        ImageName_A=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i1,[],j1);
        ImageName_B=fullfile_uvmat(RootPath_A,SubDir_A,RootFile_A,FileExt_A,NomType_A,i2,[],j2);
    end
    par_civ1.ImageA = read_image(ImageName_A);
    par_civ1.ImageB = read_image(ImageName_B);
    par_civ1.CorrSmooth=0;% will give only the grid of data points expected for PIV, computations will be activated by the fct mouse_motion.m
    [Data.Civ1_X,Data.Civ1_Y,Data.Civ1_U,Data.Civ1_V,Data.Civ1_C,Data.Civ1_FF, ~, errormsg]=civ(par_civ1);
    if ~isempty(errormsg)
        disp(errormsg)
        return
    end % rmq: error msg displayed in civ_series
    
    %% create image data ImageData for display
    ImageData.ListVarName={'ny','nx','A'};
    ImageData.VarDimName= {'ny','nx',{'ny','nx'}};
    ImageData.VarAttribute{1}.Role='coord_y';
    ImageData.VarAttribute{2}.Role='coord_x';
    ImageData.VarAttribute{3}.Role='scalar';
    ImageData.A=par_civ1.ImageA; % get the first image
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
    ViewData.PlotAxes.B=par_civ1.ImageB;%store the second image in the UserData of the GUI view_field
    set(hview_field,'UserData',ViewData)% store the info in the UserData of image view_field, to be used by mouse_motion.m
    
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
msgbox_uvmat('WARNING','open the civ file and run "series/test_filter_tps" ')


%'nomtype2pair': creates nomenclature for index pairs knowing the image nomenclature
%---------------------------------------------------------------------
function NomTypeNc=nomtype2pair(NomTypeIma,mode_selected)
%---------------------------------------------------------------------
% OUTPUT:
% NomTypeNc
%---------------------------------------------------------------------
% INPUT:
% 'NomTypeIma': string defining the kind of nomenclature used for images

NomTypeNc=NomTypeIma;%default
switch mode_selected
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
function [ind1,ind2,mode_selected]=...
    find_pair_indices(str_civ,i_series,j_series,MinIndex_i,MaxIndex_i,MinIndex_j,MaxIndex_j)
%------------------------------------------------------------------------
ind1='';
ind2='';
r=regexp(str_civ,'^\D(?<ind>[i|j])=( -| )(?<num1>\d+)\|(?<num2>\d+)','names');
if ~isempty(r)
    mode_selected=['D' r.ind];
    ind1=stra2num(r.num1);
    ind2=stra2num(r.num2);
else
    mode_selected='burst';
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
% --- fill civ_input with the parameters retrieved from an input Civ file
%------------------------------------------------------------------------
function fill_civ_input(Data,handles)

%% Civ param
% lists of parameters to enter
ListParamNum={'CorrBoxSize','SearchRange','SearchBoxShift','Dx','Dy','Dz','MinIma','MaxIma'};% list of numerical values (to transform in strings)
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
% --- fill a panel of civ_input with the parameters retrieved from an input Civ file
%------------------------------------------------------------------------
function fill_panel(Data,handles,panel,ListParamNum,ListParamValue,ListParamString)
children=get(handles.(panel),'children');%handles of the children of the input GUI with handle 'GUI_handle'
set(children,'enable','off')
set(handles.(panel),'Visible','on')
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
    if ~isfield(Param,'InputTable')||~isfield(Param,'IndexRange')
        msgbox_uvmat('ERROR','invalid config file: open a file in a folder ''/0_XML''')
        return
    end
    check_input=0;
    if isfield(Param,'ActionInput')
        if isfield(Param.ActionInput,'Program')&& ismember(Param.ActionInput.Program,{'civ_series','civ_3D'})
            fill_GUI(Param.ActionInput,handles.civ_input)% fill the elements of the GUI series with the input parameters
            set(handles.ConfigSource,'String',filexml)
            check_input=1;
            if isfield(Param.ActionInput,'Civ1')&& isfield(Param.ActionInput.Civ1,'SearchBoxSize')
               SearchRange=round((Param.ActionInput.Civ1.SearchBoxSize-Param.ActionInput.Civ1.CorrBoxSize)/2);
                set(handles.num_SearchRange_1(1),'String',num2str(SearchRange(1)))
                set(handles.num_SearchRange_2(1),'String',num2str(SearchRange(2)))
            end
            if isfield(Param.ActionInput,'Civ2')&& isfield(Param.ActionInput.Civ2,'SearchBoxSize')
               SearchRange=round((Param.ActionInput.Civ2.SearchBoxSize-Param.ActionInput.Civ2.CorrBoxSize)/2);
                set(handles.num_SearchRange_1(2),'String',num2str(SearchRange(1)))
                set(handles.num_SearchRange_2(2),'String',num2str(SearchRange(2)))
            end
            update_CivOptions(handles,0)             
        end
    end
    if ~check_input
        msgbox_uvmat('ERROR','invalid config file (not for civ_series')
        return
    end
end

%------------------------------------------------------------------------
% --- Executes on selection change in CheckCiv3.
%------------------------------------------------------------------------
function CheckCiv3_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
% --- Executes on button press in CheckRefFile.
%------------------------------------------------------------------------
function CheckRefFile_Callback(hObject, eventdata, handles)

hseries=findobj(allchild(0),'Tag','series');
hhseries=guidata(hseries);
InputTable=get(hhseries.InputTable,'Data');
i1=str2num(get(hhseries.num_first_i,'String'));
j1=str2num(get(hhseries.num_first_j,'String'));
InputFile=fullfile_uvmat(InputTable{1,1},InputTable{1,2},InputTable{1,3},InputTable{1,5},InputTable{1,4},i1,[],j1);
% browse for a reference file for displacement
fileref= uigetfile_uvmat('pick a reference image file:',InputFile);
if ~isempty(fileref)
    FileInfo=get_file_info(fileref);
    CheckImage=strcmp(FileInfo.FieldType,'image');% =1 for images
    if ~CheckImage
        msgbox_uvmat('ERROR',['invalid file type input for reference image: ' FileInfo.FileType ' not an image'])
    else
        if isfield (FileInfo,'NumberOfFrames')&& FileInfo.NumberOfFrames>1
            set(handles.num_OriginIndex,'Visible','on')
            set(handles.OriginIndex_title,'Visible','on')
        else
            set(handles.num_OriginIndex,'Visible','off')
            set(handles.OriginIndex_title,'Visible','off')
        end
        set(handles.RefFile,'String',fileref)
        set(handles.ConfigSource,'String','NEW')
        set(handles.ConfigSource,'BackgroundColor',[1 0 1])
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




function MinIndex_j_Callback(hObject, eventdata, handles)


% --- Executes on selection change in field_ref2.
function field_ref2_Callback(hObject, eventdata, handles)



function num_SearchRange_3_Callback(hObject, eventdata, handles)
% hObject    handle to num_SearchRange_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_SearchRange_3 as text
%        str2double(get(hObject,'String')) returns contents of num_SearchRange_3 as a double



function edit108_Callback(hObject, eventdata, handles)
% hObject    handle to edit108 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit108 as text
%        str2double(get(hObject,'String')) returns contents of edit108 as a double


