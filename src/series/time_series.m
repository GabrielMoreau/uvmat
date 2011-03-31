%'time_series': extract a time series, used with series.fig
%------------------------------------------------------------------------
% function GUI_input=time_series(num_i1,num_i2,num_j1,num_j2,Series)
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
%num_i1: series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2: series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1: series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2: series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%Series: Matlab structure containing information set by the series interface
%
function GUI_input=time_series(num_i1,num_i2,num_j1,num_j2,Series) 

%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
    GUI_input={'RootPath';'two';...%nbre of possible input series (options 'on'/'two'/'many', default:'one')
        'SubDir';'on';... % subdirectory of derived files (PIV fields), ('on' by default)
        'RootFile';'on';... %root input file name ('on' by default)
        'FileExt';'on';... %input file extension ('on' by default)
        'NomType';'on';...%type of file indexing ('on' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelTypeMenu';'two';...% menu for selecting the velocity type (civ1,..) options 'off'/'one'/'two', 'off' by default)
        'FieldMenu';'two';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'CoordType';'on';...%can use a transform function 'off' by default
        'GetObject';'on';...%can use projection object ,'off' by default
        %'GetMask';'on'...%can use mask option   ,'off' by default
        %'PARAMETER'; options: name of the user defined parameter',repeat a line for each parameter 
               ''};
    return %exit the function 
end

%------------------------------------------------------
hseries=guidata(Series.hseries);%handles in the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position'); %position of the waitbar frame

%% projection object
test_object=get(hseries.GetObject,'Value');
if test_object
    hset_object=findobj(allchild(0),'tag','set_object');
    ProjObject=read_set_object(guidata(hset_object));
    %answeryes=questdlg({['field series projected on ' Series.ProjObject.Style]});
    answeryes=msgbox_uvmat('INPUT_Y-N',['field series projected on ' ProjObject.Style]);
    if ~isequal(answeryes,'Yes')
        return
    end
else
    msgbox_uvmat('ERROR','a projection object is needed');
    return
end

%% root names
if iscell(Series.RootPath)
    RootPath=Series.RootPath;
    RootFile=Series.RootFile;
    SubDir=Series.SubDir;
    FileExt=Series.FileExt;
    NomType=Series.NomType;
else
    RootPath={Series.RootPath};
    RootFile={Series.RootFile};
    SubDir={Series.SubDir};
    FileExt={Series.FileExt};
    NomType={Series.NomType};
    num_i1={num_i1};
    num_i2={num_i2};
    num_j1={num_j1};
    num_j2={num_j2};
end
ext=FileExt{1};
form=imformats(ext([2:end]));%test valid Matlab image formats
testima=0;
if ~isempty(form)||isequal(lower(ext),'.avi')
    testima=1;
end
nbview=length(RootPath);%number of series (1 or 2)
nbfield=size(num_i1{1},1)*size(num_i1{1},2); %number of fields in the time series

%Number of input series: this function  accepts only one or two input file series (sub_field is used in the latter case)
nbview=length(RootPath);

%determine image type
hhh=which('mmreader');
for iview=1:nbview
    if isequal(FileExt{iview},'.nc')||isequal(FileExt{iview},'.cdf')
        FileType{iview}='netcdf';
    elseif isequal(lower(FileExt{iview}),'.avi')
        if ~isequal(hhh,'')&& mmreader.isPlatformSupported()
            MovieObject{iview}=mmreader(fullfile(RootPath{iview},[RootFile{iview} FileExt{iview}]));
            FileType{iview}='movie';
        else
            FileType{iview}='avi';
        end
    elseif isequal(lower(FileExt{iview}),'.vol')
        FileType{iview}='vol';
    else 
       form=imformats(FileExt{iview}(2:end));
       if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
           if isequal(NomType{iview},'*');
               FileType{iview}='multimage';
           else
               FileType{iview}='image';
           end
       end
    end
end
filebase{1}=fullfile(RootPath{1},RootFile{1});

% number of slices
NbSlice=str2num(get(hseries.NbSlice,'String'));
if isempty(NbSlice)
    NbSlice=1;
end
NbSlice_name=num2str(NbSlice);

% Field and velocity type (the same for the two views)
if isfield(Series,'Field')
    FieldName=Series.Field;%the same set of fields for all views
else
    FieldName={''};
end
if isequal(FieldName,{'get_field...'})
    hget_field=findobj(allchild(0),'name','get_field');%find the get_field... GUI
    if numel(hget_field)>1
        delete(hget_field(2:end)) % delete multiple occurerence of the GUI get_fioeld
    elseif isempty(hget_field)
       filename=name_generator(filebase{1},num_i1{1}(1),num_j1{1}(1),FileExt{1},NomType{1},1,num_i2{1}(1),num_j2{1}(1),SubDir{1}); 
       idetect(iview)=exist(filename,'file');
       hget_field=get_field(filename);
       return
    end
    SubField=read_get_field(hget_field); %read the names of the variables to plot in the get_field GUI
    if isempty(SubField)
        delete(hget_field)
       filename=name_generator(filebase{1},num_i1{1}(1),num_j1{1}(1),FileExt{1},NomType{1},1,num_i2{1}(1),num_j2{1}(1),SubDir{1});
        hget_field=get_field(filename);
        SubField=read_get_field(hget_field); %read the names of the variables to plot in the get_field GUI
    end
end

%detect whether the two files are 'images' or 'netcdf'

testcivx=0;
FileExt=get(hseries.FileExt,'String');
if ~isequal(FieldName,{'get_field...'})
    testcivx=isequal(FileType{1},'netcdf');
end

VelType_str=get(hseries.VelTypeMenu,'String');
VelType_val=get(hseries.VelTypeMenu,'Value');
VelType{1}=VelType_str{VelType_val};
if nbview==2
    VelType_str=get(hseries.VelTypeMenu_1,'String');
    VelType_val=get(hseries.VelTypeMenu_1,'Value');
    VelType{2}=VelType_str{VelType_val};
end

%% Calibration data and timing: read the ImaDoc files
mode=''; %default
timecell={};
XmlData={};
itime=0;
NbSlice_calib={};
for iview=1:nbview%Loop on views
    XmlData{iview}=[];%default
    filebase{iview}=fullfile(RootPath{iview},RootFile{iview});
    if exist([filebase{iview} '.xml'],'file')
        [XmlData{iview},error]=imadoc2struct([filebase{iview} '.xml']); 
        if isfield(XmlData{iview},'Time')
            itime=itime+1;
            timecell{itime}=XmlData{iview}.Time;
        end
        if isfield(XmlData{iview},'GeometryCalib') && isfield(XmlData{iview}.GeometryCalib,'SliceCoord')
            NbSlice_calib{iview}=size(XmlData{iview}.GeometryCalib.SliceCoord,1);%nbre of slices for Zindex in phys transform
            if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
                msgbox_uvmat('WARNING','inconsistent number of Z indices for the field series');
            end
        end 
    elseif exist([filebase{iview} '.civ'],'file')
        [error,time,TimeUnit,mode,npx,npy,pxcmx,pxcmy]=read_imatext([filebase{iview} '.civ']);
        itime=itime+1;
        timecell{itime}=time;
        XmlData{iview}.Time=time;
        GeometryCalib.R=[pxcmx 0 0; 0 pxcmy 0;0 0 0];
        GeometryCalib.Tx=0;
        GeometryCalib.Ty=0;
        GeometryCalib.Tz=1;
        GeometryCalib.dpx=1;
        GeometryCalib.dpy=1;
        GeometryCalib.sx=1;
        GeometryCalib.Cx=0;
        GeometryCalib.Cy=0;
        GeometryCalib.f=1;
        GeometryCalib.kappa1=0;
        GeometryCalib.CoordUnit='cm';
        XmlData{iview}.GeometryCalib=GeometryCalib;
        if error==1
            msgbox_uvmat('WARNING','inconsistent number of fields in the .civ file');
        end
    end
end

%% check coincidence in time
multitime=0;
if isempty(timecell)
    time=[];
elseif length(timecell)==1
    time=timecell{1};
elseif length(timecell)>1
    multitime=1;
    for icell=1:length(timecell)
        if ~isequal(size(timecell{icell}),size(timecell{1}))
            msgbox_uvmat('WARNING','inconsistent time array dimensions in ImaDoc fields, the time for the first series is used')
            time=timecell{1};
            multitime=0;
            break
        end
    end
end
if multitime
    for icell=1:length(timecell)
        time(icell,:,:)=timecell{icell};
    end
    diff_time=max(max(diff(time)));
    if diff_time>0
        msgbox_uvmat('WARNING',['times of series differ by more than ' num2str(diff_time)])
    end   
end
if size(time,2) < num_i2{1}(end) || size(time,3) < num_j2{1}(end)% ime array absent or too short in ImaDoc xml file' 
    time=[];
end

%%  Root name of output files (TO GENERALISE FOR TWO INPUT SERIES)
subdir_result='time_series';
pathdir=fullfile(RootPath{1},subdir_result);
while exist(pathdir,'dir')
    subdir_result=[subdir_result '.0'];
    pathdir=fullfile(RootPath{1},subdir_result);
end
[m1,m2,m3]=mkdir(pathdir);
if ~isequal(m2,'')
     msgbox_uvmat('CONFIRMATION',m2);%error message for directory creation
end
[xx,msg2] = fileattrib(pathdir,'+w','g'); %yield writing access (+w) to user group (g)
if ~strcmp(msg2,'')
    msgbox_uvmat('ERROR',['pb of permission for ' pathdir ': ' msg2])%error message for directory creation
    return
end

filebase_out=filebase{1}; 
NomTypeOut=nomtype2pair(NomType{1},num_i2{end}(end)-num_i1{1}(1),num_j2{end}(end)-num_j1{1}(1));

%% coordinate transform or other user defined transform
transform_fct=[];%default
if isfield(Series,'transform_fct')
    transform_fct=Series.transform_fct;
end

%% velocity type
VelType_str=get(hseries.VelTypeMenu,'String');
VelType_val=get(hseries.VelTypeMenu,'Value');
VelType{1}=VelType_str{VelType_val};
if nbview==2
    VelType_str=get(hseries.VelTypeMenu_1,'String');
    VelType_val=get(hseries.VelTypeMenu_1,'Value');
    VelType{2}=VelType_str{VelType_val};
end

%% LOOP ON SLICES
for i_slice=1:NbSlice
     dt=[];
     nbmissing=0; %number of undetected files
     nbfiles=0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%LOOP ON FIELDS IN  A SLICE
    for ifile=i_slice:NbSlice:nbfield  
        stopstate=get(hseries.RUN,'BusyAction');
        if isequal(stopstate,'queue')% enable STOP command
             update_waitbar(hseries.waitbar,WaitbarPos,ifile/nbfield) 
             for iview=1:nbview
                filename=...
                           name_generator(filebase{iview},num_i1{iview}(ifile),num_j1{iview}(ifile),FileExt{iview},NomType{iview},1,num_i2{iview}(ifile),num_j2{iview}(ifile),SubDir{iview}); 
                idetect(iview)=exist(filename,'file');
                Data{iview}=[]; %default      
                if ~isequal(FileType{iview},'netcdf')                
                    Data{iview}.ListVarName={'A'};
                    Data{iview}.AName='image';
                    switch FileType{iview}
                        case 'movie'
                            A=read(MovieObject{iview},num_i1{iview}(ifile));
                        case 'avi'
                            mov=aviread(filename,num_i1{iview}(ifile));
                            A=frame2im(mov(1));
                        case 'vol'
                            A=imread(filename);
                        case 'multimage'
                            A=imread(filename,num_i1{iview}(ifile));
                        case 'image'
                            A=imread(filename);
                    end 
                    Data{iview}.ListVarName={'AY','AX','A'}; % 
                    npy=size(A,1);
                    npx=size(A,2);
                    nbcolor=size(A,3);
                    if nbcolor==3
                         Data{iview}.VarDimName={'AY','AX',{'AY','AX','rgb'}};
                    else
                         Data{iview}.VarDimName={'AY','AX',{'AY','AX'}};
                    end  
                    Data{iview}.AY=[npy-0.5 0.5];
                    Data{iview}.AX=[0.5 npx-0.5];
                    Data{iview}.A=double(A);
                    Data{iview}.CoordUnit='pixel';
                elseif testcivx
                    [Data{iview},VelTypeOut]=read_civxdata(filename,FieldName,VelType);
                else
                    [Data{iview},var_detect]=nc2struct(filename,SubField.ListVarName); %read the corresponding input data                
                    Data{iview}.VarAttribute=SubField.VarAttribute;
                end
                if ~isempty(NbSlice_calib)  % z index
                    Data{iview}.ZIndex=mod(num_i1{iview}(ifile)-1,NbSlice_calib{1})+1;
                end
             end
             
             % coordinate transform (or other user defined transform)
            if ~isempty(transform_fct)
                 % z index
                if ~isempty(NbSlice_calib)
                    Data{iview}.ZIndex=mod(num_i1{iview}(ifile)-1,NbSlice_calib{1})+1;%Zindex for phys transform
                end
                if nbview==2
                    [Data{1},Data{2}]=transform_fct(Data{1},XmlData{1},Data{2},XmlData{2});
                    if isempty(Data{2})
                        Data(2)=[];
                    end
                else
                    Data{1}=transform_fct(Data{1},XmlData{1});
                end
            end     
            if testcivx
                    Data{iview}=calc_field(FieldName,Data{iview});%calculate field (vort..)
            end
            if length(Data)==2
                [Field,errormsg]=sub_field(Data{1},Data{2}); %substract the two fields
                if ~isempty(errormsg)
                    msgbox_uvmat('ERROR',['error in time_series/sub_field:' errormsg])
                    return
                end
            else
                Field=Data{1};
            end
            if test_object
                [Field,errormsg]=proj_field(Field,ProjObject);
                if ~isempty(errormsg)
                    msgbox_uvmat('ERROR',['error in time_series/proj_field:' errormsg])
                    return
                end
            end
            if min(idetect)>=1% the input file(s) have been detected          
                nbfiles=nbfiles+1;
                if nbfiles==1 %first field: initiate the time series
                    RecordData=Field;%default
                    RecordData.NbDim=Field.NbDim+1; %add the time dimension for plots         
                    nbvar=length(Field.ListVarName);
                    if nbvar==0
                        msgbox_uvmat('ERROR','no input variable selected in get_field')
                        return
                    end
                    testsum=2*ones(1,nbvar);%initiate flag for action on each variable
                    indexfalse=0;
                    CoordName={};
                    indexremove=[];
                    if isfield(Field,'VarAttribute') % look for coordinate and flag variables    
                        for ivar=1:nbvar
                            if length(Field.VarAttribute)>=ivar && isfield(Field.VarAttribute{ivar},'Role')
                               %Field.ListVarName{ivar}
                                var_role=Field.VarAttribute{ivar}.Role;%'role' of the variable
                                if isequal(var_role,'errorflag')
                                    msgbox_uvmat('ERROR','do not handle error flags in time series')
                                    return                                               
                                end
                                if isequal(var_role,'warnflag')                        
                                    testsum(ivar)=0;  % not recorded variable 
                                    eval(['RecordData=rmfield(RecordData,''' Field.ListVarName{ivar} ''');']);%remove variable
                                end                  
                                if isequal(var_role,'coord_x')| isequal(var_role,'coord_y')|...
                                    isequal(var_role,'coord_z')|isequal(var_role,'coord')
                                    testsum(ivar)=1; %constant coordinates, record without time evolution
                                end
                            end
                            % check whether the variable ivar is a dimension variable
                            DimCell=Field.VarDimName{ivar};
                            if ischar(DimCell)
                                DimCell={DimCell};
                            end
                            if numel(DimCell)==1 && isequal(Field.ListVarName{ivar},DimCell{1})%detect dimension variables
                               testsum(ivar)=1;
                            end
                        end
                    end
                    for ivar=1:nbvar
                        if testsum(ivar)==2                     
                            eval(['RecordData.' Field.ListVarName{ivar} '=[];'])
                        end
                    end
                    RecordData.ListVarName=[{'Time'} RecordData.ListVarName];
                end
                for ivar=1:length(Field.ListVarName)
                    VarName=Field.ListVarName{ivar};
                    eval(['VarVal=Field.' VarName ';']);
                    if testsum(ivar)==2% test for recorded variable 
                        eval(['VarVal=Field.' VarName ';']);
                        if isequal(ProjObject.ProjMode,'inside')% take the average in the domain for 'inside' mode
                            if isempty(VarVal)
                                msgbox_uvmat('ERROR',['empty result at frame index ' num2str(num_i1{iview}(ifile))])
                                return                             
                            end
                            VarVal=mean(VarVal,1);
                        end
                        VarVal=shiftdim(VarVal,-1); %shift dimension 
                        eval(['RecordData.' VarName '=cat(1,RecordData.' VarName ',VarVal);']);%concanete the current field to the time series    
                    elseif testsum(ivar)==1% variable representing fixed coordinates
                        eval(['VarInit=RecordData.' VarName ';']);
                        if ~isequal(VarVal,VarInit)
                            msgbox_uvmat('ERROR',['time series requires constant coordinates ' VarName])
                            return
                        end
                    end                 
                end
                % time:
                if isempty(time)% time read in ncfiles
                   if isfield(Field,'Time')
                       RecordData.Time(nbfiles,1)=Field.Time;
                   else
                       RecordData.Time(nbfiles,1)=nbfiles;%default
                   end
                else % time from ImaDoc prevails
                    RecordData.Time(nbfiles,1)=(time(1,num_i1{1}(ifile),num_j1{1}(ifile))+time(end,num_i2{end}(ifile),num_j2{end}(ifile)))/2;
                end
            else
                nbmissing=nbmissing+1;
            end
        end
    end
    %remove time for global attributes if exists
    for iattr=1:numel(RecordData.ListGlobalAttribute) 
        if strcmp(RecordData.ListGlobalAttribute{iattr},'Time')
            RecordData.ListGlobalAttribute(iattr)=[];
            break
        end
    end
    for ivar=1:numel(RecordData.ListVarName)
        VarName=RecordData.ListVarName{ivar};
        eval(['RecordData.' VarName '=squeeze(RecordData.' VarName ');']) %remove singletons
    end
        % add time dimension and update VarDimIndex:
        for ivar=1:length(Field.ListVarName)
             DimCell=Field.VarDimName(ivar);
             if testsum(ivar)==2%variable used as time series
                  RecordData.VarDimName{ivar}=[{'Time'} DimCell];
             elseif testsum(ivar)==1
                 RecordData.VarDimName{ivar}=DimCell;
             end
        end
    indexremove=find(~testsum);
    if ~isempty(indexremove)
        RecordData.ListVarName(1+indexremove)=[];
        RecordData.VarDimName(indexremove)=[];
        if isfield(RecordData,'Role')&~isempty(RecordData.Role{1})%generaliser aus autres attributs
            RecordData.Role(1+indexremove)=[];
        end
    end

    %shift variable attributes
    if isfield(RecordData,'VarAttribute')
        RecordData.VarAttribute=[{[]} RecordData.VarAttribute];
    end 
    RecordData.VarDimName=[{'Time'} RecordData.VarDimName];
    RecordData.Action=Series.Action;%name of the processing programme
    
    %name of result file
    [filemean]=...
               name_generator(filebase_out,num_i1{1}(i_slice),num_j1{1}(i_slice),'.nc','_i1-i2_j1-j2',1,num_i2{end}(ifile),num_j2{end}(ifile),subdir_result);
    errormsg=struct2nc(filemean,RecordData); %save result file
    if isempty(errormsg)
        display([filemean ' written'])
    else
        msgbox_uvmat('ERROR',['error in Series/struct2nc' errormsg])
    end
end

figure
haxes=axes;

plot_field(RecordData,haxes)
hget_field=findobj(allchild(0),'name','get_field');
if ~isempty(hget_field)
    delete(hget_field)
end

get_field(filemean,RecordData)
    
%-----------------------------------------------------------------------
% --- Executes on selection change in CoordType.
function CoordType_Callback(hObject, eventdata, handles)
menu_str=get(handles.CoordType,'String');
ind_coord=get(handles.CoordType,'Value');
coord_option=menu_str{ind_coord};
if isequal(coord_option,'more...'); 
    fct_name='';
    if exist('./TMP/current_usr_fct.mat','file')% if a file is found
        h=load('./TMP/current_usr_fct.mat');
        if isfield(h,'fct_name'); 
            fct_name=h.fct_name;
        end
    end
    prompt = {'Enter the name of the transform function'};
    dlg_title = 'user defined transform';
    num_lines= 1;
    [FileName, PathName, filterindex] = uigetfile( ...
       {'*.m', ' (*.m)';
        '*.m',  '.m files '; ...
        '*.*', 'All Files (*.*)'}, ...
        'Pick a file', fct_name);
    fct_name=fullfile(PathName,FileName);
    addpath(PathName);%add the path to the selected fct
    [errormsg,date_str]=check_functions;%check whether new functions can oversed the uvmat package A UTILISER
    if ~exist(fct_name,'file')
           warndlg(['image procesing fct ' fct_name ' not found'])
    else
        transform=FileName(1:end-2);% 
        update_menu(handles.CoordType,transform)%add the selected fct to the menu
  %      set(handles.mouse_coord,'String',menu([1:end-1])')%update the mouse coord menu 
      %save ('./TMP/current_usr_fct.mat','fct_name');
    end   
end
ind_coord=get(handles.CoordType,'Value');   

%---------------------------------------------------------------------
% % --- Executes on selection change in ProjObject.
% function ProjObject_Callback(hObject, eventdata, handles)
% 
% list_object=get(handles.ProjObject,'String');
% index=get(handles.ProjObject,'Value');
% hseries=get(handles.ProjObject,'Parent');
% SeriesData=get(hseries,'UserData');
% Obj=SeriesData.ProjObject{index};
% [SeriesData.hset_object,SeriesData.sethandles]=set_object(SeriesData.ProjObject{index});
% set(hseries,'UserData',SeriesData);

