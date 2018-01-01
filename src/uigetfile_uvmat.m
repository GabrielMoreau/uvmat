%'uigetfile_uvmat': browser, and display of directories, faster than the Matlab fct uigetfile 
%------------------------------------------------------------------------
% fileinput=uigetfile_uvmat(title,InputName,FilterExt)
%
% OUTPUT:
% fileinput: detected file name, including path
%
% INPUT:
% title: = displayed title, 
%        if title='status_display': display advancement of a series calculation, 
%        else uigetfile_uvmat used as browser.
% InputName: initial file or directory selection for the browser
% FilterExt: string to filter the file display:
%          '*' (default) all files displayed
%          'image': any image or movie
%          '.ext': display only files with extension '.ext'
%          'uigetdir'; browser used to select a directory (like the matlab browser 'uigetdir')

%=======================================================================
% Copyright 2008-2018, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function fileinput=uigetfile_uvmat(title,InputName,FilterExt)
if ~exist('FilterExt','var')
    FilterExt='*';
end
fileinput=''; %default file selection
if strcmp(title,'status_display')
    option='status_display';
else
    option='browser';
end
InputDir=pwd;%look in the current work directory if the input file does not exist
InputFileName='';%default
if ischar(InputName)
    if isempty(regexp(InputName,'^http://'))%usual files
        if exist(InputName,'dir')
            InputDir=InputName;
            InputFileName='';
        elseif exist(InputName,'file')
            [InputDir,InputFileName,Ext]=fileparts(InputName);
            if isempty(InputFileName)% if InputName is already the root
                InputFileName=InputDir;
                if  ~isempty(strcmp (computer, {'PCWIN','PCWIN64'}))%case of Windows systems
                    %                 InputDir=[InputDir '\'];% append '\' for a correct action of dir
                    InputFileName=[InputFileName '\'];
                end
            end
            if isdir(InputName)
                InputFileName=['+/' InputFileName Ext];
            end
        end
        if  ismember(computer,{'PCWIN','PCWIN64'})%case of Windows systems
            InputDir=[InputDir '\'];% append '\' for a correct action of dir
        end
    else
        [InputDir,InputFileName,Ext]=fileparts(InputName);
    end
end

hfig=findobj(allchild(0),'tag',option);
if isempty(hfig)
    set(0,'Unit','points')
    ScreenSize=get(0,'ScreenSize');% get the size of the screen, to put the fig on the upper right
    Width=350;% fig width in points (1/72 inch)
    Height=min(0.8*ScreenSize(4),500);
    Left=ScreenSize(3)- Width-40; %right edge close to the right, with margin=40
    Bottom=ScreenSize(4)-Height-40; %put fig at top right
    hfig=figure('name',option,'tag',option,'MenuBar','none','NumberTitle','off','Unit','points','Position',[Left,Bottom,Width,Height],'UserData',InputDir);
    BackgroundColor=get(hfig,'Color');
    path_title=uicontrol('Style','text','Units','normalized', 'Position', [0.02 0.97 0.9 0.03],'BackgroundColor',BackgroundColor,'Tag','Path_title',...
        'String','path:','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','left');
    htitlebox=uicontrol('Style','edit','Units','normalized', 'Position', [0.02 0.89 0.96 0.08],'tag','titlebox','Max',2,'BackgroundColor',[1 1 1],'Callback',@titlebox_Callback,...
        'String',InputDir,'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''titlebox'':current path');
    uicontrol('Style','pushbutton','Tag','backward','Units','normalized','Position',[0.02 0.77 0.1 0.05],...
        'String','<--','FontWeight','bold','FontUnits','points','FontSize',12,'Callback',@backward,'TooltipString','move backward');
    home_button=uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.14 0.77 0.2 0.05],...
        'String','Work dir','FontWeight','bold','FontUnits','points','FontSize',12,'Callback',@home_dir,'TooltipString','reach the current Matlab working directory'); 
    uicontrol('Style','pushbutton','Tag','refresh','Units','normalized','Position', [0.36 0.77 0.2 0.05],'Callback',@refresh_GUI,...
        'String','Refresh','FontWeight','bold','FontUnits','points','FontSize',12);
    uicontrol('Style','popupmenu','Units','normalized', 'Position', [0.75 0.74 0.23 0.05],'tag','sort_option','Callback',@refresh_GUI,'Visible','off',...
        'String',{'sort name';'sort date'},'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''sort_option'': sort the files by names or dates');
    uicontrol('Style','listbox','Units','normalized', 'Position',[0.02 0.08 0.96 0.66], 'Callback', @(src,event)list_Callback(option,FilterExt,src,event),'tag','list',...
        'FontUnits','points','FontSize',12,'TooltipString','''list'':current list of directories, marked by +/, and files');
    
    OK_button=uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.58 0.005 0.2 0.07],'BackgroundColor',[0 1 0],...
        'String','OK','FontWeight','bold','FontUnits','points','FontSize',12,'Callback',@(src,event)OK_Callback(option,FilterExt,src,event));
    close_button=uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.78 0.005 0.2 0.07],'Callback',@(src,event)close(option,src,event),...
        'FontWeight','bold','FontUnits','points','FontSize',12);
    %set(hrefresh,'UserData',StatusData)
    if strcmp(option,'status_display') %put a run advancement display
        set(hfig,'DeleteFcn',@(src,event)close(option,src,event))
        uicontrol('Style','frame','Units','normalized', 'Position', [0.02 0.85 0.9 0.04]);
        uicontrol('Style','frame','Units','normalized', 'Position',[0.02 0.85 0.01 0.04],'BackgroundColor',[1 0 0],'tag','waitbar');
        %             uicontrol('Style','text','Units','normalized', 'Position', [0.4 0.8 0.35 0.03],'BackgroundColor',BackgroundColor,...
        %             'String','sort: ','FontUnits','points','FontSize',12,'FontWeight','bold','HorizontalAlignment','right');
        delete(home_button)
        set(OK_button,'String','Open')
        set(close_button,'String','Close')
    elseif strcmp(FilterExt,'uigetdir') %pick a  directory
        set(path_title,'String',title); %show the input title for path (directory)
        set(OK_button,'String','Select')
        set(close_button,'String','Cancel')
    else  %put a title and additional pushbuttons
        uicontrol('Style','text','Units','normalized', 'Position', [0.02 0.74 0.6 0.03],'BackgroundColor',BackgroundColor,...
            'String',title,'FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','left');
        uicontrol('Style','togglebutton','Units','normalized', 'Position', [0.75 0.78 0.23 0.04],'tag','check_date','Callback',@dates_Callback,...
            'String','show dates','FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''check_date'':press button to display dates');
%         uicontrol('Style','text','Units','normalized', 'Position', [0.37 0.8 0.35 0.03],'BackgroundColor',BackgroundColor,...
%             'String','sort: ','FontUnits','points','FontSize',12,'FontWeight','bold','HorizontalAlignment','right');
         set(OK_button,'String','Open')
         set(close_button,'String','Cancel')    
    end
    drawnow
end
refresh_GUI(findobj(hfig,'Tag','refresh'),InputFileName,FilterExt)% refresh the list of content of the current dir
if ~strcmp(option,'status_display')
    uiwait(hfig)
    if ishandle(hfig)
        htitlebox=findobj(hfig,'Tag','titlebox');
        fileinput=get(htitlebox,'String');% retrieve the input file selection
        delete(hfig)
    end
end

%------------------------------------------------------------------------   
% --- launched by refreshing the display figure
%------------------------------------------------------------------------
function titlebox_Callback(hObject,event)
refresh_GUI(hObject)

%------------------------------------------------------------------------   
% --- launched by selecting OK (relevant for FilterExt='uigetdir')
%------------------------------------------------------------------------
function OK_Callback(option,filter_ext,hObject,event)
set(hObject,'backgroundColor',[1 1 0])% indicate button activation
hfig=get(hObject,'parent');%handle of the fig
htitlebox=findobj(hfig,'tag','titlebox');  % display the current dir name  
DirName=get(htitlebox,'String');
if ~strcmp(filter_ext,'uigetdir')% a file is expected as output, not a dir
    hlist=findobj(hfig,'Tag','list');
    list=get(hlist,'String');
    index=get(hlist,'Value');
    if ~isempty(regexp(list{index},'^\+/'))
        return % quit if a dir has been opened
    end
    %SelectName=regexprep(list{index},'^\+/','');% remove the +/ used to mark dir
    SelectName=list{index};
    ind_dot=regexp(SelectName,'\s*\.\.\.');%remove what is beyond  '...'
    if ~isempty(ind_dot)
        SelectName=SelectName(1:ind_dot-1);
    end
    if isempty(regexp(DirName,'^http://'))% if the input dir is not a web site (begins by http://)
        FullSelectName=fullfile(DirName,SelectName);
        check_exist=exist(FullSelectName,'file');
    else
        FullSelectName=[DirName '/' SelectName];
        check_exist=1;
    end
    if check_exist
        switch option
            case 'browser'
                set(htitlebox,'String',FullSelectName);
                uiresume(hfig)
            case 'status_display'
                FileInfo=get_file_info(FullSelectName);
                if strcmp(FileInfo.FileType,'txt')
                    edit(FullSelectName)
                elseif strcmp(FileInfo.FileType,'xml')
                    editxml(FullSelectName)
                elseif strcmp(FileInfo.FileType,'figure')
                    open(FullSelectName)
                else
                    uvmat(FullSelectName);
                end
        end
    end
end
set(hObject,'backgroundColor',[0 1 0])% indicate end button activation
uiresume(get(hObject,'parent'))

%------------------------------------------------------------------------
% --- launched by refreshing the display figure
function refresh_GUI(hObject,InputFileName,FilterExt)
%------------------------------------------------------------------------
if ~exist('InputFileName','var')
    InputFileName='';
end
if ~exist('FilterExt','var')
    FilterExt='*';
end
if strcmp(FilterExt,'uigetdir')
    FilterExt='*';
end
hfig=get(hObject,'parent');
hlist=findobj(hfig,'tag','list');% find the list object
set(hlist,'BackgroundColor',[1 1 0])
drawnow
htitlebox=findobj(hfig,'tag','titlebox');
DirName=get(htitlebox,'String');
hsort_option=findobj(hfig,'tag','sort_option');
% use with GUI series
if strcmp(get(hfig,'Tag'),'status_display') % use with GUI series
    hseries=findobj(allchild(0),'tag','series');
    hstatus=findobj(hseries,'tag','status');
    StatusData=get(hstatus,'UserData');
    TimeStart=0;
    if isfield(StatusData,'TimeStart')
        TimeStart=StatusData.TimeStart;
    end
    hlist=findobj(hfig,'tag','list');
    testrecent=0;
    NbOutputFile=[];
    if isfield(StatusData,'NbOutputFile')
        NbOutputFile=StatusData.NbOutputFile;
        NbOutputFile_str=num2str(NbOutputFile);
    end
    [ListFiles,NumFiles]=list_files(DirName,1,TimeStart);% list the directory content
    
    % update the waitbar
    hwaitbar=findobj(hfig,'tag','waitbar');
    if ~isempty(NbOutputFile)
        BarPosition=get(hwaitbar,'Position');
        BarPosition(3)=0.9*max(0.01,NumFiles/NbOutputFile);% the bar width cannot be set to 0, set to 0.01 instead
        set(hwaitbar,'Position',BarPosition)
    end
else  %use as usual browser
    sort_option='name';
    if strcmp(get(hsort_option,'Visible'),'on')&& isequal(get(hsort_option,'Value'),2)
        sort_option='date';
    end
    hcheck_date=findobj(hfig,'tag','check_date');
    [ListFiles,NumFiles]=list_files(DirName,get(hcheck_date,'Value'),sort_option,FilterExt);% list the directory content
end

set(hlist,'String',ListFiles)
Value=[];
if ~isempty(InputFileName)
    Value=find(strcmp(InputFileName,ListFiles));
end
if isempty(Value)
    Value=1;
end
set(hlist,'Value',Value)
set(hlist,'BackgroundColor',[0.7 0.7 0.7])

%------------------------------------------------------------------------   
% --- launched by selecting an item on the file list
%------------------------------------------------------------------------
function dates_Callback(hObject,event)

hfig=get(hObject,'parent');
hsort_option=findobj(hfig,'tag','sort_option');
if get(hObject,'Value')
    set(hsort_option,'Visible','on')
    set(hsort_option,'Value',2)
else
    set(hsort_option,'Visible','off')
end
refresh_GUI(hObject,[])


%------------------------------------------------------------------------   
% --- launched by selecting an item on the file list
function list_Callback(option,filter_ext,hObject,event)
%------------------------------------------------------------------------
hfig=get(hObject,'parent');%handle of the fig
set(hObject,'BackgroundColor',[1 1 0])% paint list in yellow to indicate action
    drawnow
list=get(hObject,'String');
index=get(hObject,'Value');

htitlebox=findobj(hfig,'tag','titlebox');  % display the new dir name  
DirName=get(htitlebox,'String');
CheckSubDir=~isempty(regexp(list{index},'^\+'));
SelectName=regexprep(list{index},'^\+/','');% remove the +/ used to mark dir
ind_dot=regexp(SelectName,'\s*\.\.\.');%remove what is beyond  '...'
if ~isempty(ind_dot)
    SelectName=SelectName(1:ind_dot-1);
end
if strcmp(SelectName,'..')% the upward dir option has been selected
    FullSelectName=fileparts(DirName);
else
    if isempty(regexp(DirName,'^http://'))% usual files
        FullSelectName=fullfile(DirName,SelectName);
    else
        FullSelectName=[DirName '/' SelectName];
    end
end
if CheckSubDir%exist(FullSelectName,'dir')% a directory has been selected
    set(hObject,'BackgroundColor',[1 1 0])% paint list in yellow to indicate action
    drawnow
    hbackward=findobj(hfig,'Tag','backward');
    set(hbackward,'UserData',DirName); %store the current dir for future backward action
    hsort_option=findobj(hfig,'tag','sort_option');
    sort_option='name';%default
    if strcmp(get(hsort_option,'Visible'),'on')&& isequal(get(hsort_option,'Value'),2)
        sort_option='date';
    end
    hcheck_date=findobj(hfig,'tag','check_date');
    
    ListFiles=list_files(FullSelectName,get(hcheck_date,'Value'),sort_option,filter_ext);% list the directory content
    set(hObject,'Value',1)
    set(hObject,'String',ListFiles)
    set(hObject,'BackgroundColor',[0.7 0.7 0.7])
    set(htitlebox,'String',FullSelectName)% record the new dir name
end
set(hObject,'BackgroundColor',[0.7 0.7 0.7])% paint list in grey to indicate action end

%-------------------------------------------------------------------------   
% list the content of a directory
function [ListFiles,NumFiles]=list_files(DirName,check_date,sort_option,filter_ext)
%-------------------------------------------------------------------------
ListStruct=dir_uvmat(DirName);% get structure of the current directory
NumFiles=0; %default
if numel(ListStruct)<1  % case of empty dir
    ListFiles={};
    return
end
ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
ListFiles=ListCells(1,:);%list of file names
check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
% for ilist=1:numel(check_dir)
%     if check_dir(ilist)
ListFiles(check_dir)=regexprep(ListFiles(check_dir),'^.+','+/$0');% put '+/' in front of dir name display
%     end
% end
if exist('filter_ext','var') && ~strcmp(filter_ext,'*') &&~strcmp(filter_ext,'uigetdir')
    if strcmp(filter_ext,'image')
        check_keep=cellfun(@isimage,ListFiles) ;
    elseif strcmp(filter_ext(1),'.')
        ind_ext=regexp(ListFiles,[filter_ext '$']);%look for the input file extension
        check_keep=~cellfun('isempty',ind_ext);
    end
    check_keep=check_keep|check_dir;
    ListFiles=ListFiles(check_keep);
    ListCells=ListCells(:,check_keep);
    check_dir=check_dir(check_keep);
end
check_emptydate=cellfun('isempty',ListCells(5,:));% = 1 if datenum undefined 
ListCells(5,find(check_emptydate))={0}; %set to 0 the empty dates
ListDates=cell2mat(ListCells(5,:));%list of numerical dates
if isnumeric(sort_option)
    check_old=ListDates<sort_option-1;% -1 is put to account for a 1 s delay in the record of starting time
    NumFiles=numel(find(~check_old&~check_dir));
end
if ~isempty(find(~check_dir))
ListDates(check_dir)=max(ListDates(~check_dir))+1000; % we set the dir in front
end

if isnumeric(sort_option)|| strcmp(sort_option,'date')
    [tild,index_sort]=sort(ListDates,2,'descend');% sort files by chronological order, recent first, put the dir first in the list
else
    [tild,index_sort]=sort(check_dir,2,'descend');% put the dir first in the list
end
ListFiles=ListFiles(index_sort);% list of names sorted by alaphabetical order and dir and file
cell_remove=regexp(ListFiles,'^(-|\.|\+/\.)');% detect strings beginning by '-' ,'.' or '+/.'(dir beginning by . )
check_keep=cellfun('isempty', cell_remove);
ListFiles=[{'+/..'} ListFiles(check_keep)];
if check_date
    ListDateString=ListCells(2,:);%list of file dates
    if isnumeric(sort_option)
        ListDateString(check_old)={'--OLD--'};
    end
    ListDateString(check_dir)={''};
    ListDateString=ListDateString(index_sort);% sort the corresponding dates
    ListDateString=[{''} ListDateString(check_keep)];
    ListFiles=[ListFiles; ListDateString];
    ListFiles=cell2tab(ListFiles','...');
end

%------------------------------------------------------------------------   
% --- launched by selecting home
function home_dir(hObject,event)
%------------------------------------------------------------------------
DirName=pwd;
hfig=get(hObject,'parent');
hlist=findobj(hfig,'tag','list');% find the list object
set(hlist,'BackgroundColor',[1 1 0])
drawnow
sort_option='name';%default
hsort_option=findobj(hfig,'tag','sort_option');
if strcmp(get(hsort_option,'Visible'),'on')&& isequal(get(hsort_option,'Value'),2)
    sort_option='date';
end
hcheck_date=findobj(hfig,'tag','check_date');
ListFiles=list_files(DirName,get(hcheck_date,'Value'),sort_option);% list the directory content
htitlebox=findobj(hfig,'Tag','titlebox');
set(htitlebox,'String',DirName)% record the new dir name
set(hlist,'Value',1)
set(hlist,'String',ListFiles)
set(hlist,'BackgroundColor',[0.7 0.7 0.7])
%------------------------------------------------------------------------

%------------------------------------------------------------------------   
% --- launched by pressing the backward (<--) button
function backward(hObject,event)
%------------------------------------------------------------------------
PrevDir=get(hObject,'UserData');
if ~isempty(PrevDir)
hfig=get(hObject,'parent');
htitlebox=findobj(hfig,'tag','titlebox');  % display the new dir name
set(htitlebox,'String',PrevDir)
refresh_GUI(findobj(hfig,'Tag','refresh'))
end

%-------------------------------------------------------------------------   
% --- launched by deleting the status figure (only used in mode series status')
%-------------------------------------------------------------------------
function close(option,hObject, eventdata)

if strcmp(option,'status_display')
    hseries=findobj(allchild(0),'Tag','series');
    hstatus=findobj(hseries,'Tag','status');
    set(hstatus,'value',0) %reset the status uicontrol in the GUI series
    set(hstatus,'BackgroundColor',[0 1 0])
end
delete(gcbf)

%-------------------------------------------------------------------------
% --- check whether a file is has an image name extension 
%-------------------------------------------------------------------------
function CheckImage=isimage(filename)

[pp,name,ext]=fileparts(filename);
CheckImage=~isempty(ext)&&~strcmp(ext,'.')&&~isempty(imformats(regexprep(ext,'^.','')));
