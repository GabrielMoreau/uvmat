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
if strcmp(title,'status')
    option='status';
else
    option='browser';
end
if exist(InputName,'file')||exist(InputName,'dir')
    [InputDir,InputFileName,Ext]=fileparts(InputName);
    InputFileName=[InputFileName Ext];
    if isdir(InputName)
        InputFileName=['+/' InputFileName];
    end
else
    InputDir=pwd;%look in the current work directory if the input file does not exist
    InputFileName='';
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
    uicontrol('Style','listbox','Units','normalized', 'Position',[0.05 0.09 0.9 0.71], 'Callback', @(src,event)view_file(option,src,event),'tag','list',...
        'FontUnits','points','FontSize',12);
    uicontrol('Style','edit','Units','normalized', 'Position', [0.05 0.87 0.9 0.1],'tag','titlebox','Max',2,...
        'String',InputDir,'FontUnits','points','FontSize',12,'FontWeight','bold');
    uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.7 0.01 0.2 0.07],'Callback',@(src,event)close(option,src,event),...
        'String','Close','FontWeight','bold','FontUnits','points','FontSize',12);
    uicontrol('Style','pushbutton','Tag','refresh','Units','normalized','Position', [0.1 0.01 0.2 0.07],'Callback',@refresh_GUI,...
        'String','Refresh','FontWeight','bold','FontUnits','points','FontSize',12);
    %set(hrefresh,'UserData',StatusData)
    if strcmp(option,'status') %put a run advancement display
        set(hfig,'DeleteFcn',@stop_status)
        uicontrol('Style','frame','Units','normalized', 'Position',[0.05 0.81 0.01 0.05],'BackgroundColor',[1 0 0],'tag','waitbar');
        uicontrol('Style','frame','Units','normalized', 'Position', [0.05 0.81 0.9 0.05]);
    else  %put a title and additional pushbuttons
        uicontrol('Style','text','Units','normalized', 'Position', [0.15 0.81 0.8 0.03],...
            'String',title,'FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','left');
        uicontrol('Style','pushbutton','Tag','backward','Units','normalized','Position',[0.05 0.8 0.1 0.07],...
            'String','<--','FontWeight','bold','FontUnits','points','FontSize',12,'Callback',@backward);
        uicontrol('Style','pushbutton','Units','normalized', 'Position', [0.4 0.01 0.2 0.07],...
            'String','Home','FontWeight','bold','FontUnits','points','FontSize',12,'Callback',@home_dir);
    end
    drawnow
end
refresh_GUI(findobj(hfig,'Tag','refresh'),InputFileName)  
if ~strcmp(option,'status')  
    uiwait(hfig)
end
fileinput=get(hfig,'UserData');% retrieve the input file selection
delete(hfig)

%------------------------------------------------------------------------   
% --- launched by selecting an item on the file list
function view_file(option,hObject,event)
%------------------------------------------------------------------------
list=get(hObject,'String');
index=get(hObject,'Value');
hfig=get(hObject,'parent');%handle of the fig
DirName=get(hfig,'UserData');
SelectName=regexprep(list{index},'^\+/','');% remove the +/ used to mark dir
if strcmp(SelectName,'..')% the upward dir option has been selected
    FullSelectName=fileparts(DirName);
else
    %ind_dot=regexp(SelectName,'\.\.\.');
    % if ~isempty(ind_dot)
    %     SelectName=SelectName(1:ind_dot-1);
    % end
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
    hbackward=findobj(hfig,'Tag','backward');
    set(hbackward,'UserData',DirName); %store the current dir for future backward action
    ListFiles=list_files(FullSelectName);
    set(hObject,'Value',1)
    set(hObject,'String',ListFiles)
    set(hfig,'UserData',FullSelectName)% record the new dir name
    htitlebox=findobj(hfig,'tag','titlebox');  % display the new dir name  
    set(htitlebox,'String',FullSelectName)
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
        hfig=get(hObject,'parent');
        set(hfig,'UserData',FullSelectName);
        uiresume(hfig)
            case 'status'
           uvmat(FullSelectName);
        end
        set(gcbo,'Value',1)
    end
end

%------------------------------------------------------------------------   
% --- launched by selecting home
function home_dir(hObject,event)
%------------------------------------------------------------------------
DirName=pwd;
ListFiles=list_files(DirName);% list the directory content
hfig=get(hObject,'parent');
    set(hfig,'UserData',DirName)% record the new dir name
    htitlebox=findobj(hfig,'tag','titlebox');  % display the new dir name  
    set(htitlebox,'String',DirName)
    hlist=findobj(hfig,'tag','list');% find the list object
set(hlist,'String',ListFiles)
%------------------------------------------------------------------------

%------------------------------------------------------------------------   
% --- launched by pressing the backward (<--) button
function backward(hObject,event)
%------------------------------------------------------------------------
PrevDir=get(hObject,'UserData');
if ~isempty(PrevDir)
hfig=get(hObject,'parent');
set(hfig,'UserData',PrevDir)
htitlebox=findobj(hfig,'tag','titlebox');  % display the new dir name
set(htitlebox,'String',PrevDir)
refresh_GUI(findobj(hfig,'Tag','refresh'))
end

%------------------------------------------------------------------------

%------------------------------------------------------------------------   
% --- launched by refreshing the display figure
function refresh_GUI(hObject,InputFileName)
%------------------------------------------------------------------------
if ~exist('InputFileName','var')
    InputFileName='';
end
hfig=get(hObject,'parent');
DirName=get(hfig,'UserData');
ListFiles=list_files(DirName);% list the directory content
hlist=findobj(hfig,'tag','list');% find the list object
set(hlist,'String',ListFiles)
Value=[];
if ~isempty(InputFileName)
    Value=find(strcmp(InputFileName,ListFiles));
end
if isempty(Value)
    Value=1;
end
set(hlist,'Value',Value)
return

%TODO adapt to series status
hseries=findobj(allchild(0),'tag','series');
hstatus=findobj(hseries,'tag','status');
StatusData=get(hstatus,'UserData');
TimeStart=0;
if isfield(StatusData,'TimeStart')
    TimeStart=StatusData.TimeStart;
end
% testrecent=0;
% datnum=zeros(numel(ListDisplay),1);
% for ilist=1:numel(ListDisplay)
%     ListDisplay{ilist}=ListFiles(ilist).name;
%     if ListFiles(ilist).isdir
%         ListDisplay{ilist}=['/' ListDisplay{ilist}];    
%     elseif isfield(ListFiles(ilist),'datenum')
%         datnum(ilist)=ListFiles(ilist).datenum;%only available in recent matlab versions
%         testrecent=1;
%         if datnum(ilist)<TimeStart
%             ListDisplay{ilist}=[ListDisplay{ilist} '  --OLD--'];
%         end
%     end
% end


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

%-------------------------------------------------------------------------   
% list the content of a directory
function ListFiles=list_files(DirName)
%-------------------------------------------------------------------------
ListStruct=dir(DirName);
if numel(ListStruct)<1
    ListFiles={};
    return
end
if strcmp(ListStruct(1).name,'.')
    ListStruct(1)=[];%removes the first line ='.'
end
ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
ListFiles=ListCells(1,:);%list of file names
check_dir=cell2mat(ListCells(4,:));% check directories
ListFiles(check_dir)=regexprep(ListFiles(check_dir),'^.+','+/$0');% put '+/' in front of dir name display
[tild,index_sort]=sort(check_dir,2,'descend');% sort 
ListFiles=ListFiles(index_sort);% list of names sorted by alaphabetical order and dir and file 
cell_remove=regexp(ListFiles,'^(-|\.|\+/\.)');% detect strings beginning by '-' ,'.' or '+/.'(dir beginning by . )
check_keep=cellfun('isempty', cell_remove);               
ListFiles=[{'+/..'} ListFiles(check_keep)];

%-------------------------------------------------------------------------   
% launched by deleting the status figure (only used in mode series status')
function close(option,hObject, eventdata)
%-------------------------------------------------------------------------
if strcmp(option,'status')
    hseries=findobj(allchild(0),'tag','series');
    hstatus=findobj(hfig,'Tag','status');
    set(hhciv.status,'value',0) %reset the status uicontrol in the GUI civ
    set(hhciv.status,'BackgroundColor',[0 1 0])
end
delete(gcbf)

