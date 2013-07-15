%'civ_input': function associated with the GUI 'civ_input.fig' to set the input parameters for civ_series
%------------------------------------------------------------------------
% function ParamOut = civ_input(Param)
%
% OUPUT:
% ParamOut: Matlab structure containing the parameters set by the GUI civ_input
%
% INPUT:
% Param: Matlab structure containing the input parameters set by the GUI
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2011, LEGI / CNRS-UJF-INPG, sommeria@legi.grenoble-inp.fr
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
hseries=findobj(allchild(0),'Tag','series');
SeriesData.ParentHandle=hseries;
SeriesData=get(hseries,'UserData');
% relevant data in gcbf:.FileType,.FileInfo,.Time,.TimeUnit,.GeometryCalib{1};

%% set visibility options: 
if strcmp(Param.Action.ActionName,'civ_series')
        set(handles.Program,'String','civ_series')
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
        set(handles.CheckDecimal,'Value',0)% desactivate (work in progress)
end

%% input file info
RootPath=Param.InputTable{1,1};
%set(handles.RootPath,'String',RootPath)
RootFile=Param.InputTable{1,3};
SubDir=Param.InputTable{1,2};
NomTypeInput=Param.InputTable{1,4};
FileExt=Param.InputTable{1,5};
FileType=SeriesData.FileType{1};%type of the first input file series
FileInfo=SeriesData.FileInfo{1};
FileInput=SeriesData.RefFile{1};

%% case of netcdf file as input, get the processing stage and look for corresponding images
% imageinput=fileinput;%default
% TODO: insert image input in the GUI series
ind_opening=0;%default
NomTypeNc='';
switch FileType
    case {'image','multimage','video','mmreader'}
        NomTypeImaA=NomTypeInput;
        iview_image=1;%line # for the input images
    case 'civdata'
        if ~strcmp(Param.Action.ActionName,'civ_series')
            msgbox_uvmat('ERROR','bad input data file: open an image or a nc file from civ_series')
            return
        end
        NomTypeNc=NomTypeInput;
        ind_opening=FileInfo.CivStage;
        if isempty(regexp(NomTypeInput,'[ab|AB|-]', 'once'))
            set(handles.ListCompareMode,'Value',2) %mode displacement advised if the nomencalture does not involve index pairs
            set(handles.RootFile_1,'Visible','On');
        else
            set(handles.ListCompareMode,'Value',1)
            %            set(handles.RootFile_1,'Visible','Off');
        end
        imageinput='';
        Data=nc2struct(FileInput,'ListGlobalAttribute','Civ2_ImageA','Civ1_ImageA','Civ2_ImageB','Civ1_ImageB');
        [PathCiv1_ImageA,Civ1_ImageA,FileExtA]=fileparts(Data.Civ1_ImageA);
        [PathCiv1_ImageB,Civ1_ImageB,FileExtA]=fileparts(Data.Civ1_ImageB);
        if ~isempty(Data.Civ2_ImageA)
            [PathCiv2_ImageA,Civ2_ImageA,FileExtA]=fileparts(Data.Civ2_ImageA);
            [PathCiv2_ImageB,Civ2_ImageB,FileExtA]=fileparts(Data.Civ2_ImageB);
        end
        hhseries=guidata(gcbf);
        if size(Param.InputTable,1)==1
            series('display_file_name',hhseries,Data.Civ1_ImageA,'append');%append the image series to the input list
        end
        if isfield(Data,'Txt')
            errormsg=Data.Txt;
            return
            %TODO: introduce the image in the input table of series
        end
        [RootPath,SubDir,RootFile,i1,i2,j1,j2,FileExt,NomTypeImaA]=fileparts_uvmat(Data.Civ1_ImageA);
        [RootPath,SubDir,RootFile,i1,i2,j1,j2,FileExt,NomTypeImaB]=fileparts_uvmat(Data.Civ1_ImageB);
        iview_image=2;%line # for the input images
    case 'civxdata'% case of  civx data,
        NomTypeNc=NomTypeInput;
        ind_opening=FileInfo.CivStage;
        set(handles.Program,'Value',3) %select Cix by default
        msgbox_uvmat('ERROR','old civX convention, use the GUI civ')
        return
end
if numel(SeriesData.FileType)>=2 && strcmp(SeriesData.FileType{end-1},'image') &&   strcmp(SeriesData.FileType{end},'image')
    set(handles.ListCompareMode,'Value',3)% we compare two image series term to term ('shift')
    set(handles.PairIndices,'Visible','off')
end

%% TODO: get corresponding image in nc case

%% reinitialise menus
set(handles.ListPairMode,'Value',1)
set(handles.ListPairMode,'String',{''})
set(handles.ListPairCiv1,'Value',1)
set(handles.ListPairCiv1,'String',{''})
set(handles.ListPairCiv2,'Value',1)
set(handles.ListPairCiv2,'String',{''}) 
        
%% prepare the GUI with input parameters 
set(handles.ListCompareMode,'Visible','on')

%display the parameters stored on the GUI series
set(handles.ref_i,'String',num2str(Param.IndexRange.first_i))
if isfield(Param.IndexRange,'first_j')
    set(handles.ref_j,'String',num2str(Param.IndexRange.first_j))
end

%% set the civ_input options depending on the input file content when a nc file has been opened
ListOptions={'CheckCiv1', 'CheckFix1' 'CheckPatch1', 'CheckCiv2', 'CheckFix2', 'CheckPatch2'};
checkbox=zeros(size(ListOptions));%default
if ind_opening==0%case of image opening, start with Civ1
    for index=1:numel(ListOptions)
        checkbox(index)=get(handles.(ListOptions{index}),'Value');
    end
    index_max=find(checkbox, 1, 'last' );
    if isempty(index_max),index_max=1;end
    for index=1:index_max
        set(handles.(ListOptions{index}),'Value',1)% select all operations starting from CIV1
    end
else
    for index = 1:min(ind_opening,5)
        set(handles.(ListOptions{index}),'value',0)
    end
    set(handles.(ListOptions{min(ind_opening+1,6)}),'value',1)
    for index = ind_opening+2:6
        set(handles.(ListOptions{index}),'value',0)
    end
end


%%  set the menus of image pairs and default selection for civ_input   %%%%%%%%%%%%%%%%%%%
MaxIndex_i=Param.IndexRange.MaxIndex_i(iview_image);
MinIndex_i=Param.IndexRange.MinIndex_i(iview_image);
MaxIndex_j=1;%default
MinIndex_j=1;
if isfield(Param.IndexRange,'MaxIndex_j')&&isfield(Param.IndexRange,'MinIndex_j')
MaxIndex_j=Param.IndexRange.MaxIndex_j(iview_image);
MinIndex_j=Param.IndexRange.MinIndex_j(iview_image);
end
CivInputData.MaxIndex_i=MaxIndex_i;
CivInputData.MaxIndex_j=MaxIndex_j;
CivInputData.MinIndex_i=MinIndex_i;
CivInputData.MinIndex_j=MinIndex_j;
if ~isfield(Param.IndexRange,'first_j')||isequal(MaxIndex_j,MinIndex_j)% no possibility of j pairs
    set(handles.ListPairMode,'Value',1)
    set(handles.ListPairMode,'String',{'series(Di)'})
elseif  MaxIndex_i==1 && MaxIndex_j>1% simple series in j
    set(handles.ListPairMode,'String',{'pair j1-j2';'series(Dj)'})
    if  MaxIndex_j <= 10
        set(handles.ListPairMode,'Value',1)% advice 'pair j1-j2' except in MaxIndex_j is large
    end
%elseif ~(strcmp(FileType,'video') || strcmp(FileType,'mmreader'))
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
if isfield(SeriesData,'TimeSource')
    set(handles.ImaDoc,'String',SeriesData.TimeSource)
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
    if size(time,1)<MaxIndex_i;
        msgbox_uvmat('WARNING','maximum i index restricted by the timing of the xml file');
    elseif size(time,2)<MaxIndex_j
        msgbox_uvmat('WARNING','maximum j index restricted by the timing of the xml file');
    end
    MaxIndex_i=min(size(time,1),MaxIndex_i);%possibly adjust the max index according to time data
    MaxIndex_j=min(size(time,2),MaxIndex_j);
else
    set(handles.ImaDoc,'String',''); %xml file not used for timing
    TimeUnit='frame';
    time=ones(MaxIndex_j-MinIndex_j+1,1)*(MinIndex_i:MaxIndex_i);
    time=time+0.001*(MinIndex_j:MaxIndex_j)'*ones(1,MaxIndex_i-MinIndex_i+1);
end
CivInputData.Time=time;
CivInputData.NomTypeIma=NomTypeImaA;
set(handles.civ_input,'UserData',CivInputData)
set(handles.dt_unit,'String',['dt in m' TimeUnit]);%display dt in unit 10-3 of the time (e.g ms)
set(handles.TimeUnit,'String',TimeUnit);
set(handles.CoordUnit,'String',CoordUnit)
set(handles.SearchRange,'UserData', pxcm_search);

%% set the reference indices from the input file indices
num_ref_i=str2num(get(handles.ref_i,'String'));
num_ref_j=str2num(get(handles.ref_j,'String'));

update_CivOptions(handles,ind_opening)

%% list the possible index pairs, depending on the option set in ListPairMode
ListPairMode_Callback([], [], handles)
ListPairCiv1_Callback(hObject, eventdata, handles)

%% introduce the stored parameters if relevant
if isfield(Param,'ActionInput')
fill_GUI(Param.ActionInput,hObject);%fill the GUI with the parameters retrieved from the input Param
end

%% set the GUI to modal: wait for OK to close
set(handles.civ_input,'WindowStyle','modal')% Make the GUI modal
drawnow
uiwait(handles.civ_input);



%Program_Callback([],[], handles)

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



% -----------------------------------------------------------------------
% -----------------------------------------------------------------------
% --- Open the help html file 
function MenuHelp_Callback(hObject, eventdata, handles)
% -----------------------------------------------------------------------
path_civ=fileparts(which ('civ'));
helpfile=fullfile(path_civ,'uvmat_doc','uvmat_doc.html');
if isempty(dir(helpfile))
    msgbox_uvmat('ERROR','Please put the help file uvmat_doc.html in the sub-directory /uvmat_doc of the UVMAT package')
else
    addpath (fullfile(path_civ,'uvmat_doc'))
    web([helpfile '#civ'])
end


%------------------------------------------------------------------------
% --- general function activated for an input file series
function errormsg=display_file_name(handles,fileinput)
%------------------------------------------------------------------------


%% enable OK, BATCH button and 'status' display
% set(handles.OK, 'Enable','On')
% set(handles.OK,'BackgroundColor',[1 0 0])%set RUN button to red color
% if isfield(handles,'status')
%     set(handles.status,'Value',0);       %suppress the 'status' display
%     status_Callback([], [], handles)
% end

%% determine nomenclature types and extension of the input files
% [RootPath,SubDir,Civ2_ImageB,i1,i2,j1,j2,ExtInput,NomTypeInput]=fileparts_uvmat(fileinput);
% NomTypeNc='';%default



%% scan the image file series
[FilePath,FileName,ImaExt]=fileparts(imageinput);
% detect the file type, get the movie object if relevant, and look for the corresponding file series:
% the root name and indices may be corrected by including the first index i1 if a corresponding xml file exists
%[RootPath,Civ1_ImageA,Civ2_ImageB,i1_series,tild,j1_series,tild,NomTypeIma,FileType,MovieObject]=find_file_series(FilePath,[FileName ImaExt]);
switch Param.FileType{1}
    case {'image','multimage','video','mmreader'}
    otherwise
        errormsg='invalid input file: enter an image, a movie or civ .nc file';
        return
end
set(handles.RootPath,'String',RootPath)
set(handles.Civ1_ImageA,'String',SubDirImages)
set(handles.Civ2_ImageB,'String',RootFile)
if strcmp(ExtInput,'.nc')
    SubDirCiv=regexprep(SubDir,['^' SubDirImages],'');%suppress the root  SuddirImages;
else
    SubDirCiv= '.civ';
end
set(handles.Civ1_ImageB,'String',SubDirCiv)
set(handles.Civ2_ImageA,'String',SubDirCiv)
browse=get(handles.RootPath,'UserData');
browse.incr_pair=[0 0];%default

%% scan the images if a civ_input file has been opened
MinIndex_i=min(i1_series(i1_series>0));
MinIndex_j=min(j1_series(j1_series>0));
MaxIndex_i=max(i1_series(i1_series>0));
MaxIndex_j=max(j1_series(j1_series>0));

%% look for an image documentation file
XmlFileName=find_imadoc(RootPath,SubDir,RootFile,ImaExt);
if isempty(XmlFileName)
    if (strcmp(FileType,'video') || strcmp(FileType,'mmreader'))
        ext_imadoc=ImaExt;% the timing from the video movie is used
    else
        ext_imadoc='';
    end
else
    [tild,tild,ext_imadoc]=fileparts(XmlFileName);
end
set(handles.ImaDoc,'String',ext_imadoc)% display the extension name for the image documentation file used



%% update i and j index range if a nc file has been opened or pb withmin max image indices:
% then set first and last to the inputfile index by default
first_i=str2num(get(handles.MinIndex_i,'String'));
last_i=str2num(get(handles.last_i,'String'));
if isempty(first_i) || isempty(last_i)||isempty(MinIndex_i)||isempty(MaxIndex_i)||ind_opening~=0 || isempty(first_i) || isempty(last_i)|| first_i<MinIndex_i || last_i>MaxIndex_i
    first_i=num_ref_i;
    last_i=num_ref_i;
    set(handles.MinIndex_i,'String',num2str(first_i));
    set(handles.last_i,'String',num2str(last_i));%
end

%j index range
first_j=str2num(get(handles.MinIndex_j,'String'));
last_j=str2num(get(handles.last_j,'String'));
if isempty(first_j) || isempty(last_j)||isempty(MinIndex_j)||isempty(MaxIndex_j)||ind_opening~=0 || first_j<MinIndex_j || last_j>MaxIndex_j
    first_j=num_ref_j;
    last_j=num_ref_j;
    set(handles.MinIndex_j,'String',num2str(first_j));
    set(handles.last_j,'String',num2str(last_j));%
end
if num_ref_i>last_i || num_ref_i<first_i
    num_ref_i=round((first_i+last_i)/2);
end
if num_ref_j>last_j || num_ref_j<first_j
    num_ref_j=round((first_j+last_j)/2);
end
set(handles.ref_i,'String',num2str(num_ref_i))
set(handles.ref_j,'String',num2str(num_ref_j))



%% scan files to update the subdirectory list display
listot=dir(RootPath);%directory of RootPath
idir=0;
listdir={''};%default
% get the list of existing civ_input subdirectories in the path of theinput root  file
for ilist=1:length(listot)
    if listot(ilist).isdir
        name=listot(ilist).name;
        if ~isequal(name,'.') && ~isequal(name,'..')
            idir=idir+1;
            listdir{idir,1}=listot(ilist).name;
        end
    end
end

%% store info
%set(handles.RootPath,'UserData',browse)% store the nomenclature type

%% list the possible index pairs, depending on the option set in ListPairMode
ListPairMode_Callback([], [], handles)

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
    errormsg=find_netcpair_civ(handles,1); %update the list of available pairs from netcdf files in the new directory
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

%------------------------------------------------------------------------
% --- Executes on button press in CheckFix1.
function CheckFix1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch1.
function CheckPatch1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- Executes on button press in CheckCiv2.
function CheckCiv2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- Executes on button press in CheckFix2.
function CheckFix2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- Executes on button press in CheckPatch2.
function CheckPatch2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
update_CivOptions(handles,0)

%------------------------------------------------------------------------
% --- activated by any checkbox controling the selection of Civ1,Fix1,Patch1,Civ2,Fix2,Patch2
function update_CivOptions(handles,opening)
%------------------------------------------------------------------------
checkbox=zeros(1,6);
checkbox(1)=get(handles.CheckCiv1,'Value');
checkbox(2)=get(handles.CheckFix1,'Value');
checkbox(3)=get(handles.CheckPatch1,'Value');
checkbox(4)=get(handles.CheckCiv2,'Value');
checkbox(5)=get(handles.CheckFix2,'Value');
checkbox(6)=get(handles.CheckPatch2,'Value');
ind_selected=find(checkbox,1);
% if ~isempty(ind_selected)
%     RootPath=get(handles.RootPath,'String');
%     if isempty(RootPath)
%         msgbox_uvmat('ERROR','Please open an image or PIV .nc file with the upper bar menu Open/Browse...')
%         return
%     end
% end
set(handles.PairIndices,'Visible','on')
%set(handles.Civ1_ImageB,'Visible','on')
%set(handles.TitleSubdirCiv1,'Visible','on')
if opening==0
    errormsg=find_netcpair_civ(handles,1); % select the available netcdf files
    if ~isempty(errormsg)
        msgbox_uvmat('ERROR',errormsg)
    end
end
if max(checkbox(4:6))% case of civ2 pair choice needed
    set(handles.TitlePairCiv2,'Visible','on')
%    set(handles.TitleSubdirCiv2,'Visible','on')
%    set(handles.Civ2_ImageA,'Visible','on')
    %set(handles.ListSubdirCiv2,'Visible','on')
    set(handles.ListPairCiv2,'Visible','on')
    if ~opening
        errormsg=find_netcpair_civ(handles,2); % select the available netcdf files
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',errormsg)
        end
    end
else
%    set(handles.TitleSubdirCiv2,'Visible','off')
%    set(handles.Civ2_ImageA,'Visible','off')
    set(handles.ListPairCiv2,'Visible','off')
end
options={'Civ1','Fix1','Patch1','Civ2','Fix2','Patch2'};
for ilist=1:length(options)
    if checkbox(ilist)
        set(handles.(options{ilist}),'Visible','on')
    else
        set(handles.(options{ilist}),'Visible','off')
    end
end

%------------------------------------------------------------------------
% --- Executes on button press in OK: processing on local computer
function OK_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------

handles.output.ActionInput=read_GUI(handles.civ_input);
guidata(hObject, handles);% Update handles structure
uiresume(handles.civ_input);

% %------------------------------------------------------------------------
% % --- determine the list of index pairs of processing file
% function [i1_civ1,i2_civ1,j1_civ1,j2_civ1,i1_civ2,i2_civ2,j1_civ2,j2_civ2]=...
%     find_pair_indices(handles,ref_i,ref_j,mode)
% %------------------------------------------------------------------------
% 
% list_civ1=get(handles.ListPairCiv1,'String');
% index_civ1=get(handles.ListPairCiv1,'Value');
% str_civ1=list_civ1{index_civ1};%string defining the image pairs for civ1
% if isempty(str_civ1)||isequal(str_civ1,'')
%     msgbox_uvmat('ERROR','no image pair selected for civ1')
%     return
% end
% list_civ2=get(handles.ListPairCiv2,'String');
% index_civ2=get(handles.ListPairCiv2,'Value');
% if index_civ2>length(list_civ2)
%     list_civ2=list_civ1;
%     index_civ2=index_civ1;
% end
% str_civ2=list_civ2{index_civ2};%string defining the image pairs for civ2
% 
% if isequal (mode,'series(Di)')
%     lastfield=str2double(get(handles.MaxIndex_i,'String'));
%     i1_civ1=ref_i-floor(index_civ1/2)*ones(size(ref_i));% set of first image numbers
%     i2_civ1=ref_i+ceil(index_civ1/2)*ones(size(ref_i));
%     j1_civ1=ref_j;
%     j2_civ1=ref_j;
%     i1_civ2=ref_i-floor(index_civ2/2)*ones(size(ref_i));
%     i2_civ2=ref_i+ceil(index_civ2/2)*ones(size(ref_i));
%     j1_civ2=ref_j;
%     j2_civ2=ref_j;
%     
%     % adjust the first and last field number
%     lastfield=str2double(get(handles.MaxIndex_i,'String'));
%     if isnan(lastfield)
%         indsel=find((i1_civ1 >= 1)&(i1_civ2 >= 1));
%     else
%         indsel=find((i2_civ1 <= lastfield)&(i2_civ2 <= lastfield)&(i1_civ1 >= 1)&(i1_civ2 >= 1));
%     end
%     if length(indsel)>=1
%         firstind=indsel(1);
%         lastind=indsel(end);
%         set(handles.MinIndex_i,'String',num2str(ref_i(firstind)))%update the display of first and last fields
%         set(handles.last_i,'String',num2str(ref_i(lastind)))
%         ref_i=ref_i(indsel);
%         i1_civ1=i1_civ1(indsel);
%         i1_civ2=i1_civ2(indsel);
%         i2_civ1=i2_civ1(indsel);
%         i2_civ2=i2_civ2(indsel);
%     end
% elseif isequal (mode,'series(Dj)')
%     lastfield_j=str2double(get(handles.MaxIndex_j,'String'));
%     i1_civ1=ref_i;% set of first image numbers
%     i2_civ1=ref_i;
%     j1_civ1=ref_j-floor(index_civ1/2)*ones(size(ref_j));
%     j2_civ1=ref_j+ceil(index_civ1/2)*ones(size(ref_j));
%     i1_civ2=ref_i;
%     i2_civ2=ref_i;
%     j1_civ2=ref_j-floor(index_civ2/2)*ones(size(ref_j));
%     j2_civ2=ref_j+ceil(index_civ2/2)*ones(size(ref_j));
%     % adjust the first and last field number
%     if isnan(lastfield_j)
%         indsel=find((j1_civ1 >= 1)&(j1_civ2 >= 1));
%     else
%         indsel=find((j2_civ1 <= lastfield_j)&(j2_civ2 <= lastfield_j)&(j1_civ1 >= 1)&(j1_civ2 >= 1));
%     end
%     if length(indsel)>=1
%         firstind=indsel(1);
%         lastind=indsel(end);
%         set(handles.MinIndex_j,'String',num2str(ref_j(firstind)))%update the display of first and last fields
%         set(handles.last_j,'String',num2str(ref_j(lastind)))
%         ref_j=ref_j(indsel);
%         j1_civ1=j1_civ1(indsel);
%         j2_civ1=j2_civ1(indsel);
%         j1_civ2=j1_civ2(indsel);
%         j2_civ2=j2_civ2(indsel);
%     end
% elseif isequal(mode,'pair j1-j2') %case of bursts (png_old or png_2D)
%     displ_num=get(handles.ListPairCiv1,'UserData');
%     i1_civ1=ref_i;
%     i2_civ1=ref_i;
%     j1_civ1=displ_num(1,index_civ1);
%     j2_civ1=displ_num(2,index_civ1);
%     i1_civ2=ref_i;
%     i2_civ2=ref_i;
%     j1_civ2=displ_num(1,index_civ2);
%     j2_civ2=displ_num(2,index_civ2);
% elseif isequal(mode,'displacement')
%     i1_civ1=ref_i;
%     i2_civ1=ref_i;
%     j1_civ1=ref_j;
%     j2_civ1=ref_j;
%     i1_civ2=ref_i;
%     i2_civ2=ref_i;
%     j1_civ2=ref_j;
%     j2_civ2=ref_j;
% end

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
        %         set(handles.RootFile_1,'Visible','Off');
        %         set(handles.sub_txt,'Visible','off')
        %         set(handles.RootFile_1,'String',[]);
        %         mode_store=get(handles.ListCompareMode,'UserData');
        %         set(handles.ListPairMode,'Visible','on')
        %         set(handles.ListPairMode,'Value',1)
        %         set(handles.ListPairMode,'String',{'series(Di)'})
        %         set(handles.CheckStereo,'Value',0)
        %         set(handles.last_j,'String',get(handles.MaxIndex_j,'String'))% select the whole volume scan by default
        %         set(handles.incr_i,'String',num2str(2))%
    case 'displacement'
        OriginIndex='on';%define a frame origin for displacement
    case 'shift'
        if numel(ImageType)==1
            fileinput=uigetfile_uvmat('pick a second file series for synchronous shift',InputTable{check_nc+1});
            if ~isempty(fileinput)
                series( 'display_file_name',hhseries,fileinput,'append')
            end
            
            
        end
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
%displ_num used to define the indices of the civ_input pairs
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
index_pair=get(handles.ListPairCiv2,'Value');%get the selected position index in the menu

%update MinIndex_i and last_i according to the chosen image pairs
mode_list=get(handles.ListPairMode,'String');
mode_value=get(handles.ListPairMode,'Value');
mode=mode_list{mode_value};
if isequal(mode,'series(Di)')
    first_i=str2double(get(handles.MinIndex_i,'String'));
    last_i=str2double(get(handles.last_i,'String'));
    incr_i=str2double(get(handles.incr_i,'String'));
    num_i=first_i:incr_i:last_i;
    lastfield=str2double(get(handles.MaxIndex_i,'String'));
    if ~isnan(lastfield)
        test_find=(num_i-floor(index_pair/2)*ones(size(num_i))>0)& ...
            (num_i+ceil(index_pair/2)*ones(size(num_i))<=lastfield);
        num_i=num_i(test_find);
    end
    set(handles.MinIndex_i,'String',num2str(num_i(1)));
    set(handles.last_i,'String',num2str(num_i(end)));
elseif isequal(mode,'series(Dj)')
    first_j=str2double(get(handles.MinIndex_j,'String'));
    last_j=str2double(get(handles.last_j,'String'));
    incr_j=str2double(get(handles.incr_j,'String'));
    num_j=first_j:incr_j:last_j;
    lastfield2=str2double(get(handles.MaxIndex_j,'String'));
    if ~isnan(lastfield2)
        test_find=(num_j-floor(index_pair/2)*ones(size(num_j))>0)& ...
            (num_j+ceil(index_pair/2)*ones(size(num_j))<=lastfield2);
        num_j=num_j(test_find);
    end
    set(handles.MinIndex_j,'String',num2str(num_j(1)));
    set(handles.last_j,'String',num2str(num_j(end)));
end

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
    if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end

%------------------------------------------------------------------------
function ref_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
mode_list=get(handles.ListPairMode,'String');
mode_value=get(handles.ListPairMode,'Value');
mode=mode_list{mode_value};
if isequal(get(handles.CheckCiv1,'Value'),0)|| isequal(mode,'series(Dj)')
    errormsg=find_netcpair_civ(handles,1);% update the menu of pairs depending on the available netcdf files
end
if isequal(mode,'series(Dj)') || ...
        (get(handles.CheckCiv2,'Value')==0 && get(handles.CheckCiv1,'Value')==0 && get(handles.CheckFix1,'Value')==0 && get(handles.CheckPatch1,'Value')==0)
    errormsg=find_netcpair_civ(handles,2);
end
    if ~isempty(errormsg)
    msgbox_uvmat('ERROR',errormsg)
    end

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
[nom_type_nc]=nomtype2pair(nom_type_ima,mode);

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
testpair=0;
nbpair=200; %default

%% determine the menu display in .ListPairCiv1
testpair=0; %TODO: check
if isequal(mode,'series(Di)')
    if testpair
        displ_pair{1}=['Di= ' num2str(-floor(browse.incr_pair(1)/2)) '|' num2str(ceil(browse.incr_pair(1)/2))];
    else
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
    end
elseif isequal(mode,'series(Dj)')
    if testpair
        displ_pair{1}=['Dj= ' num2str(-floor(browse.incr_pair(1)/2)) '|' num2str(ceil(browse.incr_pair(1)/2))];
    else
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
    end
elseif isequal(mode,'pair j1-j2')%case of pairs
    MinIndex_j=CivInputData.MinIndex_j;
    MaxIndex_j=min(CivInputData.MaxIndex_j,10);%limitate the number of pairs to 10x10
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
    [dtsort,indsort]=sort(dt);
    displ_pair=displ_pair(indsort);
elseif isequal(mode,'displacement')
    displ_pair={'Di=Dj=0'};
end
if index==1
set(handles.ListPairCiv1,'String',displ_pair');
end

%% determine the default selection in the pair menu
ichoice=find(select,1);% index of selected pair
if (isempty(ichoice) || ichoice < 1); ichoice=1; end;
initial=get(handles.ListPairCiv1,'Value');%initial choice of pair
if initial>nbpair || (numel(select)>=initial && ~isequal(select(initial),1))
    set(handles.ListPairCiv1,'Value',ichoice);% first valid pair proposed by default in the menu
end
initial=get(handles.ListPairCiv2,'Value');
if initial>length(displ_pair')%|~isequal(select(initial),1)
    if ichoice <= length(displ_pair')
        set(handles.ListPairCiv2,'Value',ichoice);% same pair proposed by default for civ2
    else
        set(handles.ListPairCiv2,'Value',1);% same pair proposed by default for civ2
    end
end
set(handles.ListPairCiv2,'String',displ_pair');
set(gcf,'Pointer','arrow')


    
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

%------------------------------------------------------------------------
function MinIndex_j_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
first_j=str2num(get(handles.MinIndex_j,'String'));
set(handles.ref_j,'String', num2str(first_j))% reference index for pair dt = first index
ref_j_Callback(hObject, eventdata, handles)%refresh dispaly of dt for pairs (in case of non constant dt)

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
    set(handles.CoordUnit,'Visible','on')
    set(handles.TimeUnit,'Visible','on')
    set(handles.slash_title,'Visible','on')
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
    list_pair=get(handles.ListPairCiv1,'String');%get the menu of image pairs
    index=get(handles.ListPairCiv1,'Value');
    pair_string=list_pair{index};
    time=get(handles.ImaDoc,'UserData'); %get the set of times
    pxcm=get(handles.SearchRange,'UserData');
    mode_list=get(handles.ListPairMode,'String');
    mode_value=get(handles.ListPairMode,'Value');
    mode=mode_list{mode_value};      
    if isequal (mode, 'series(Di)' )
        ref_i=str2double(get(handles.ref_i,'String'));
        num1=ref_i-floor(index/2);%  first image numbers
        num2=ref_i+ceil(index/2);
        num_a=1;
        num_b=1;
    elseif isequal (mode, 'series(Dj)')
        num1=1;
        num2=1;
        ref_j=str2double(get(handles.ref_j,'String'));
        num_a=ref_j-floor(index/2);%  first image numbers
        num_b=ref_j+ceil(index/2);
    elseif isequal(mode,'pair j1-j2') %case of bursts (png_old or png_2D)     
        ref_i=str2double(get(handles.ref_i,'String'));
        num1=ref_i;
        num2=ref_i;
                r=regexp(pair_string,'(?<mode>(Di=)|(Dj=)) -*(?<num1>\d+)\|(?<num2>\d+)','names');
        if isempty(r)
            r=regexp(pair_string,'(?<num1>\d+)(?<mode>-)(?<num2>\d+)','names');
        end  
        num_a=str2num(r.num1);
        num_b=str2num(r.num2);
    end
    dt=time(num2+1,num_b+1)-time(num1+1,num_a+1);
    ibx=str2double(get(handles.num_CorrBoxSize_1,'String'));
    iby=str2double(get(handles.num_CorrBoxSize_2,'String'));
    umin=dt*pxcm*umin;
    umax=dt*pxcm*umax;
    vmin=dt*pxcm*vmin;
    vmax=dt*pxcm*vmax;
    shiftx=round((umin+umax)/2);
    shifty=round((vmin+vmax)/2);
    isx=(umax+2-shiftx)*2+param_civ1.Bx;
    isx=2*ceil(isx/2)+1;
    isy=(vmax+2-shifty)*2+param_civ1.Bx;
    isy=2*ceil(isy/2)+1;
    set(handles.num_SearchBoxShift_1,'String',num2str(shiftx));
    set(handles.num_SearchBoxShift_2,'String',num2str(shifty));
    set(handles.num_SearchBoxSize_1,'String',num2str(isx));
    set(handles.num_SearchBoxSize_2,'String',num2str(isy));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks in the uipanel Fix1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------------------------------------------------
% --- Executes on button press in CheckMask.
function get_mask_fix1_Callback(hObject, eventdata, handles)
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
        set(handles.CheckMask,'Value',0)
    else
        %set(handles.CheckMask,'Value',1)
        set(handles.CheckMask,'Value',1)
    end
    set(handles.Mask,'String',mask_displ)
    set(handles.Mask,'String',mask_displ)
    set(handles.Mask,'String',mask_displ)
end

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
    set(handles.Mask,'String',mask_displ)
end

%------------------------------------------------------------------------
% --- Executes on button press in CheckMask.
function get_mask_fix2_Callback(hObject, eventdata, handles)
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
    end
    set(handles.Mask,'String',mask_displ)
end

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
        filemask=get(hObject,'UserData');%look for previous mask name stored as UserData
        if exist(filemask,'file')
            filebase=filemask;
        end
        filemask= uigetfile_uvmat('pick a mask image file:',InputTable{ind_A,1},'image'); 
        set(hObject,'UserData',filemask);%store for future use
        if ~isempty(filemask)
            testmask=1;
        end
    end
end
if testmask
    if strcmp(parent_tag,'Civ1')
        set(handles.Mask,'Visible','on')
        set(handles.Mask,'String',filemask)
    set(handles.CheckMask,'Value',1)
    end
else
    set(hObject,'Value',0);
    set(handle_txtbox,'Visible','off')
end

%------------------------------------------------------------------------
% --- Executes on button press in get_gridpatch1.
function get_gridpatch1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
filebase=get(handles.RootPath,'String');
[FileName, PathName, filterindex] = uigetfile( ...
    {'*.grid', ' (*.grid)';
    '*.grid',  '.grid files '; ...
    '*.*', 'All Files (*.*)'}, ...
    'Pick a file',filebase);
filegrid=fullfile(PathName,FileName);
set(handles.grid_patch1,'string',filegrid);


%------------------------------------------------------------------------
% --- Executes on button press in get_gridpatch2.
function get_gridpatch2_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------


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
% --- Executes on button press in TestCiv1: prepare the image correlation function
% activated by mouse motion
function TestCiv1_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------
drawnow
if get(handles.TestCiv1,'Value')
    set(handles.TestCiv1,'BackgroundColor',[1 1 0])% paint TestCiv1 button to yellow to confirm civ launch
    ref_i=str2double(get(handles.ref_i,'String'));% read reference i index
    if strcmp(get(handles.ref_j,'Visible'),'on')
        ref_j=str2double(get(handles.ref_j,'String'));% read reference j index if relevant
    else
        ref_j=1;%default j index
    end
   % [filecell,i1,i2]=set_civ_filenames(handles,ref_i,ref_j,[1 0 0 0 0 0]);% get the corresponding file name and indices
    Data.ListVarName={'ny','nx','A'};
    Data.VarDimName= {'ny','nx',{'ny','nx'}};
    hseries=findobj(allchild(0),'Tag','series');
    hhseries=guidata(hseries);
    InputTable=get(hhseries.InputTable,'Data');
    ind_A=1;
    if strcmp(InputTable{1,5},'.nc');
        ind_A=2;
    end
    [i1_series_Civ1,i2_series_Civ1,j1_series_Civ1,j2_series_Civ1,check_bounds,NomTypeNc]=...
            find_pair_indices(PairCiv1,i_series{1},j_series{1},MinIndex_i,MaxIndex_i,MinIndex_j,MaxIndex_j);
 
    ImageName_A=fullfile_uvmat(InputTable{ind_A,1},InputTable{ind_A,2},InputTable{ind_A,3},InputTable{ind_A,5},InputTable{ind_A,4},...
        ref_i,[],ref_j);
    Data.A=imread(filecell.ima1.civ1{1}); % read the first image
    if ndims(Data.A)==3 %case of color image
        Data.VarDimName= {'ny','nx',{'ny','nx','rgb'}};
    end
    Data.ny=[size(Data.A,1) 1];
    Data.nx=[1 size(Data.A,2)];
    Data.CoordUnit='pixel';% used to set equal scaling for x and y in image dispaly
    par_civ1=read_GUI(handles.Civ1);
    par_civ1.FileTypeA=get_file_type(filecell.ima1.civ1{1});
    par_civ1.ImageWidth=size(Data.A,2);
    par_civ1.ImageHeight=size(Data.A,1);
    par_civ1.Mask='all';% will provide only the grid set for PIV, no image correlation
    par_civ1.FrameIndexA=num2str(i1);
    par_civ1.FrameIndexB=num2str(i2);
    Param.Civ1=par_civ1;
    Grid=civ_matlab(Param);% get the grid of x, y positions set for PIV 
    hview_field=view_field(Data); %view the image in the GUI view_field
    set(0,'CurrentFigure',hview_field)
    hhview_field=guihandles(hview_field);
    set(hview_field,'CurrentAxes',hhview_field.PlotAxes)
    ViewData=get(hview_field,'UserData');
    ViewData.CivHandle=handles.civ_input;% indicate the handle of the civ GUI in view_field
    ViewData.PlotAxes.B=imread(filecell.ima2.civ1{1});%store the second image in the UserData of the GUI view_field
    ViewData.PlotAxes.X=Grid.Civ1_X; %keep the set of points in memeory
    ViewData.PlotAxes.Y=Grid.Civ1_Y;
    set(hview_field,'UserData',ViewData)
    corrfig=findobj(allchild(0),'tag','corrfig');% look for a current figure for image correlation display
    if isempty(corrfig)
        corrfig=figure;
        set(corrfig,'tag','corrfig')
        set(corrfig,'name','image correlation')
        set(corrfig,'DeleteFcn',{@closeview_field})%
    end
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

% --- Executes on button press in TestPatch1.
function TestPatch1_Callback(hObject, eventdata, handles)
set(handles.TestPatch1,'BackgroundColor',[1 1 0])
drawnow
if get(handles.TestPatch1,'Value')
    ref_i=str2double(get(handles.ref_i,'String'));
    if strcmp(get(handles.ref_j,'Visible'),'on')
        ref_j=str2double(get(handles.ref_j,'String'));
    else
        ref_j=1;%default
    end
    filecell=set_civ_filenames(handles,ref_i,ref_j,[0 0 1 0 0 0]);    
    Data.ListVarName={'ny','nx','A'};
    Data.VarDimName= {'ny','nx',{'ny','nx'}};   
    param_patch1=read_GUI(handles.Patch1);
    param_patch1.CivFile=filecell.nc.civ1{1};
    Param.Patch1=param_patch1;
    for irho=1:7
        [Data,errormsg]=civ_matlab(Param);% get the grid of x, y positions set for PIV
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',errormsg)
            return
        end
        SmoothingParam(irho)=Param.Patch1.FieldSmooth;
        Data.Civ1_U_Diff=Data.Civ1_U_Diff(Data.Civ1_FF==0);
        Data.Civ1_V_Diff=Data.Civ1_V_Diff(Data.Civ1_FF==0);
        DiffVel(irho)=sqrt(mean(Data.Civ1_U_Diff.*Data.Civ1_U_Diff+Data.Civ1_V_Diff.*Data.Civ1_V_Diff));
        NbSites(irho,:)=Data.Civ1_NbSites*numel(Data.Civ1_NbSites)/numel(Data.Civ1_U_Diff);
        Param.Patch1.SmoothingParam=2*Param.Patch1.FieldSmooth;
    end
    figure
    plot(SmoothingParam,DiffVel,'b',SmoothingParam,NbSites,'r')
    set(handles.TestPatch1,'BackgroundColor',[1 0 0])
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


% --- Executes on button press in TestCiv2.
function TestCiv2_Callback(hObject, eventdata, handles)



function num_OriginIndex_Callback(hObject, eventdata, handles)
% hObject    handle to num_OriginIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_OriginIndex as text
%        str2double(get(hObject,'String')) returns contents of num_OriginIndex as a double


% --- Executes during object creation, after setting all properties.
function num_OriginIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_OriginIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%------------------------------------------------------------------------
% --- determine the list of index pairs of processing file
function [ind1,ind2]=...
    find_pair_indices(str_civ,i_series,j_series,MinIndex_i,MaxIndex_i,MinIndex_j,MaxIndex_j)
%------------------------------------------------------------------------
% i1_series=i_series;% set of first image indexes
% i2_series=i_series;
% j1_series=ones(size(i_series));% set of first image numbers
% j2_series=ones(size(i_series));
% check_bounds=false(size(i_series));
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
% if strcmp (mode,'Di')
%     i1_series=i_series-ind1;% set of first image numbers
%     i2_series=i_series+ind2;
%      check_bounds=i1_series<MinIndex_i | i2_series>MaxIndex_i;
%     if isempty(j_series)
%         NomTypeNc='_1-2';
%     else
%         j1_series=j_series;
%         j2_series=j_series;
%         NomTypeNc='_1-2_1';
%     end
% elseif strcmp (mode,'Dj')
%     j1_series=j_series-ind1;
%     j2_series=j_series+ind2;
%     check_bounds=j1_series<MinIndex_j | j2_series>MaxIndex_j;
%     NomTypeNc='_1_1-2';
% else  %bursts
%     j1_series=ind1*ones(size(i_series));
%     j2_series=ind2*ones(size(i_series));
% end
