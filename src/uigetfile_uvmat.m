%'uigetfile_uvmat': browser faster than the Matlab fct uigetfile 
%------------------------------------------------------------------------
% hfig=uigetfile_uvmat(OutputDir,option)
%
% OUTPUT:
% fileinput: detected file name, including path
%
% INPUT:
% title: = displayed title, 'status': display advancement of a series calculation
% InputDir: directory to browse at first display

function fileinput=uigetfile_uvmat(title,InputName)
fileinput=''; %default file selection
if strcmp(title,'status_display')
    option='status_display';
else
    option='browser';
end
InputDir=pwd;%look in the current work directory if the input file does not exist
InputFileName='';%default
if ischar(InputName)
    if exist(InputName,'dir')
        InputDir=InputName;
        InputFileName='';
    elseif exist(InputName,'file')
        [InputDir,InputFileName,Ext]=fileparts(InputName);
        if isempty(InputFileName)% if InputName is already the root
            InputFileName=InputDir;
            if  ~isempty(strcmp (computer, {'PCWIN','PCWIN64'}))%case of Windows systems
                InputDir=[InputDir '\'];% append '\' for a correct action of dir
                InputFileName=[InputFileName '\'];
            end
        end
        if isdir(InputName)
            InputFileName=['+/' InputFileName Ext];
        end
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
    uicontrol('Style','text','Units','normalized', 'Position', [0.05 0.97 0.5 0.03],'BackgroundColor',BackgroundColor,...
            'String','path:','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','left');
    uicontrol('Style','edit','Units','normalized', 'Position', [0.05 0.89 0.9 0.08],'tag','titlebox','Max',2,'BackgroundColor',[1 1 1],'Callback',@titlebox_Callback,...
        'String',InputDir,'FontUnits','points','FontSize',12,'FontWeight','bold');
    uicontrol('Style','pushbutton','Tag','backward','Units','normalized','Position',[0.05 0.75 0.1 0.07],...
            'String','<--','FontWeight','bold','FontUnits','points','FontSize',12,'Callback',@backward);
    uicontrol('Style','togglebutton','Units','normalized', 'Position', [0.75 0.75 0.2 0.04],'tag','check_date','Callback',@dates_Callback,...
            'String','dates','FontUnits','points','FontSize',12,'FontWeight','bold');
    uicontrol('Style','text','Units','normalized', 'Position', [0.4 0.8 0.35 0.03],'BackgroundColor',BackgroundColor,...
            'String','sort: ','FontUnits','points','FontSize',12,'FontWeight','bold','HorizontalAlignment','right');
    uicontrol('Style','popupmenu','Units','normalized', 'Position', [0.75 0.8 0.2 0.04],'tag','sort_option','Callback',@refresh_GUI,'Visible','off',...
            'String',{'name';'date'},'FontUnits','points','FontSize',12,'FontWeight','bold');   
    uicontrol('Style','listbox','Units','normalized', 'Position',[0.05 0.08 0.9 0.66], 'Callback', @(src,event)list_Callback(option,src,event),'tag','list',...
        'FontUnits','points','FontSize',12);
    uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.7 0.005 0.2 0.07],'Callback',@(src,event)close(option,src,event),...
        'String','Close','FontWeight','bold','FontUnits','points','FontSize',12);
    uicontrol('Style','pushbutton','Tag','refresh','Units','normalized','Position', [0.1 0.005 0.2 0.07],'Callback',@refresh_GUI,...
        'String','Refresh','FontWeight','bold','FontUnits','points','FontSize',12);
    %set(hrefresh,'UserData',StatusData)
    if strcmp(option,'status_display') %put a run advancement display
        set(hfig,'DeleteFcn',@stop_status)
        uicontrol('Style','frame','Units','normalized', 'Position',[0.05 0.81 0.01 0.05],'BackgroundColor',[1 0 0],'tag','waitbar');
        uicontrol('Style','frame','Units','normalized', 'Position', [0.05 0.81 0.9 0.05]);
    else  %put a title and additional pushbuttons
        uicontrol('Style','text','Units','normalized', 'Position', [0.15 0.75 0.6 0.03],'BackgroundColor',BackgroundColor,...
            'String',title,'FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','left');

        uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.4 0.005 0.2 0.07],...
            'String','Home','FontWeight','bold','FontUnits','points','FontSize',12,'Callback',@home_dir);
    end
    drawnow
end
refresh_GUI(findobj(hfig,'Tag','refresh'),InputFileName)% refresh the list of content of the current dir  
if ~strcmp(option,'status_display')  
    uiwait(hfig)
    htitlebox=findobj(hfig,'Tag','titlebox');
    fileinput=get(htitlebox,'String');% retrieve the input file selection
    delete(hfig)
end

%------------------------------------------------------------------------   
% --- launched by refreshing the display figure
function titlebox_Callback(hObject,event)
refresh_GUI(hObject)
%------------------------------------------------------------------------

%------------------------------------------------------------------------   
% --- launched by refreshing the display figure
function refresh_GUI(hObject,InputFileName)
%------------------------------------------------------------------------
if ~exist('InputFileName','var')
    InputFileName='';
end
hfig=get(hObject,'parent');
hlist=findobj(hfig,'tag','list');% find the list object
set(hlist,'BackgroundColor',[1 1 0])
drawnow
htitlebox=findobj(hfig,'tag','titlebox');
DirName=get(htitlebox,'String');
hsort_option=findobj(hfig,'tag','sort_option');
sort_option='name';
if strcmp(get(hsort_option,'Visible'),'on')&& isequal(get(hsort_option,'Value'),2)
    sort_option='date';
end
hcheck_date=findobj(hfig,'tag','check_date');
ListFiles=list_files(DirName,get(hcheck_date,'Value'),sort_option);% list the directory content

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
if strcmp(get(hfig,'Tag'),'status_display') 
    hseries=findobj(allchild(0),'tag','series');
    hstatus=findobj(hseries,'tag','status_display');
    StatusData=get(hstatus,'UserData');
    TimeStart=0;
    if isfield(StatusData,'TimeStart')
        TimeStart=StatusData.TimeStart;
    end 
    hlist=findobj(hfig,'tag','list');
    testrecent=0;
    datnum=zeros(numel(ListDisplay),1);
    for ilist=1:numel(ListDisplay)
        ListDisplay{ilist}=ListFiles(ilist).name;
        if ListFiles(ilist).isdir
            ListDisplay{ilist}=['/' ListDisplay{ilist}];
        elseif isfield(ListFiles(ilist),'datenum')
            datnum(ilist)=ListFiles(ilist).datenum;%only available in recent matlab versions
            testrecent=1;
            if datnum(ilist)<TimeStart
                ListDisplay{ilist}=[ListDisplay{ilist} '  --OLD--'];
            end
        end
    end
    
    %% Look at date of creation
    ListDisplay=ListDisplay(datnum~=0);
    datnum=datnum(datnum~=0);%keep the non zero values corresponding to existing files
    
    NbOutputFile=[];
    if isempty(datnum)
        if testrecent
            message='no result created yet';
        else
            message='';
        end
    else
        [first,indfirst]=min(datnum);
        [last,indlast]=max(datnum);
        NbOutputFile_str='?';
        if isfield(StatusData,'NbOutputFile')
            NbOutputFile=StatusData.NbOutputFile;
            NbOutputFile_str=num2str(NbOutputFile);
        end
        message={[num2str(numel(datnum)) ' file(s) done over ' NbOutputFile_str] ;['oldest modification:  ' ListDisplay{indfirst} ' : ' datestr(first)];...
            ['latest modification:  ' ListDisplay{indlast} ' : ' datestr(last)]};
    end
    set(htitlebox,'String', [DirName{1};message])
    
    %% update the waitbar
    hwaitbar=findobj(hfig,'tag','waitbar');
    if ~isempty(NbOutputFile)
        BarPosition=get(hwaitbar,'Position');
        BarPosition(3)=0.9*numel(datnum)/NbOutputFile;
        set(hwaitbar,'Position',BarPosition)
    end
end

%------------------------------------------------------------------------   
% --- launched by selecting an item on the file list
function dates_Callback(hObject,event)
%------------------------------------------------------------------------
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
function list_Callback(option,hObject,event)
%------------------------------------------------------------------------
hfig=get(hObject,'parent');%handle of the fig
% if ~strcmp(get(hfig,'SelectionType'),'open')
%     return %select double click
% end
set(hObject,'BackgroundColor',[1 1 0])% paint list in yellow to indicate action
    drawnow
list=get(hObject,'String');
index=get(hObject,'Value');

htitlebox=findobj(hfig,'tag','titlebox');  % display the new dir name  
DirName=get(htitlebox,'String');
SelectName=regexprep(list{index},'^\+/','');% remove the +/ used to mark dir
ind_dot=regexp(SelectName,'\s*\.\.\.');%remove what is beyond  '...'
if ~isempty(ind_dot)
    SelectName=SelectName(1:ind_dot-1);
end
if strcmp(SelectName,'..')% the upward dir option has been selected
    FullSelectName=fileparts(DirName);
else
    FullSelectName=fullfile(DirName,SelectName);
end
if exist(FullSelectName,'dir')% a directory has been selected
    %     ListFiles=dir(FullSelectName);
    %     ListDisplay=cell(numel(ListFiles),1);
    %     for ilist=2:numel(ListDisplay)% suppress the first line '.'
    %         ListDisplay{ilist-1}=ListFiles(ilist).name;
    %     end
    %     set(hObject,'Value',1)
    %     set(hObject,'String',ListDisplay)
    %     if strcmp(selectname,'..')
    %         FullSelectName=fileparts(fileparts(FullSelectName));
    %     end
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
    
    ListFiles=list_files(FullSelectName,get(hcheck_date,'Value'),sort_option);% list the directory content
    set(hObject,'Value',1)
    set(hObject,'String',ListFiles)
    set(hObject,'BackgroundColor',[0.7 0.7 0.7])
    set(htitlebox,'String',FullSelectName)% record the new dir name
elseif exist(FullSelectName,'file')%visualise the field if it exists
    FileType=get_file_type(FullSelectName);
    if strcmp(FileType,'txt')
        edit(FullSelectName)
    elseif strcmp(FileType,'xml')
        editxml(FullSelectName)
    elseif strcmp(FileType,'figure')
        open(FullSelectName)
    else
        %uvmat(FullSelectName);
        switch option
            case 'browser'
                set(htitlebox,'String',FullSelectName);
                uiresume(hfig)
            case 'status_display'
                uvmat(FullSelectName);
        end
    end
end
set(hObject,'BackgroundColor',[0.7 0.7 0.7])% paint list in grey to indicate action end

%-------------------------------------------------------------------------   
% list the content of a directory
function ListFiles=list_files(DirName,check_date,sort_option)
%-------------------------------------------------------------------------
ListStruct=dir(DirName);% get structure of the current directory
if numel(ListStruct)<1  % case of empty dir
    ListFiles={};
    return
end
ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
ListFiles=ListCells(1,:);%list of file names
check_dir=cell2mat(ListCells(4,:));% =1 for directories, =0 for files
ListFiles(check_dir)=regexprep(ListFiles(check_dir),'^.+','+/$0');% put '+/' in front of dir name display
if strcmp(sort_option,'date')
    ListDates=cell2mat(ListCells(5,:));%list of numerical dates
    ListDates(check_dir)=max(ListDates(~check_dir))+1000; % we set the dir in front 
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
% launched by deleting the status figure (only used in mode series status')
function close(option,hObject, eventdata)
%-------------------------------------------------------------------------
if strcmp(option,'status_display')
    hseries=findobj(allchild(0),'tag','series');
    hstatus=findobj(hfig,'Tag','status_display');
    set(hhciv.status,'value',0) %reset the status uicontrol in the GUI civ
    set(hhciv.status,'BackgroundColor',[0 1 0])
end
delete(gcbf)

