


%'merge_proj': project and concatene fields, used with series.fig
%------------------------------------------------------------------------
% function GUI_input=merge_proj(Param)
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
% Param: structure containing all the parameters read on the GUI series
%  or name of the xml file containing these parameters (BATCH case)
%
function GUI_input=merge_proj(Param)

%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('Param','var')
    GUI_input={'RootPath';'two';...%nbre of possible input series (options 'on'/'two'/'many', default:'one')
        'SubDir';'on';... % subdirectory of derived files (PIV fields), ('on' by default)
        'RootFile';'on';... %root input file name ('on' by default)
        'FileExt';'on';... %input file extension ('on' by default)
        'NomType';'on';...%type of file indexing ('on' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelTypeMenu';'one';...% menu for selecting the velocity type (civ1,..) options 'off'/'one'/'two', 'off' by default)
        'FieldMenu';'one';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'CoordType';'on';...%can use a transform function 'off' by default
        'GetObject';'on';...%can use projection object ,'off' by default
        %'GetMask';'on'...%can use mask option   ,'off' by default
        %'PARAMETER'; options: name of the user defined parameter',repeat a line for each parameter 
               ''};
    return %exit the function 
end

%% input parameters: 
% read the xml file for batch case
if ischar(Param) && ~isempty(find(regexp('Param','.xml$')))
    Param=xml2struct(Param);
else % RUN case : parameters introduced as the input structure Param
    hseries=guidata(Param.hseries);%handles of the GUI series
    WaitbarPos=get(hseries.waitbar_frame,'Position');% info for the waitbar
end
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);

%% coordinate transform or other user defined transform (TODO: case BATCH ?)
transform_fct='';%default
if isfield(Param,'transform_fct') % transform function handle
    transform_fct=Param.transform_fct;
end

%% projection object
test_object=get(hseries.GetObject,'Value');
if test_object
    hset_object=findobj(allchild(0),'tag','set_object');
    %ProjObject=read_set_object(guidata(hset_object));
    ProjObject=read_GUI(hset_object);
    if ~isfield(ProjObject,'Style')
            msgbox_uvmat('ERROR','Undefined projection object style')
            return
    end
    if ~isequal(ProjObject.Type,'plane')|| isequal(ProjObject.ProjMode,'projection')
            msgbox_uvmat('ERROR','The projection object must be a plane with projection mode interp or filter')
            return
    end
    answeryes=msgbox_uvmat('INPUT_Y-N',['field series projected on ' ProjObject.Type]);
    if ~isequal(answeryes,'Yes')
        return
    end
end

%% features of the input fields
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);

nbview=length(RootFile);%number of views (file series to merge)
nbfield=size(i1_series{1},1)*size(i1_series{1},2);%number of fields in the time series
hhh=which('mmreader');
for iview=1:nbview
    test_movie(iview)=0;
    if ~isequal(hhh,'')&& mmreader.isPlatformSupported()
        if isequal(lower(FileExt{iview}),'.avi')
            MovieObject{iview}=mmreader(fullfile(RootPath{iview},[RootFile{iview} FileExt{iview}]));
            test_movie(iview)=1;
        end
    end
end

%% Calibration data and timing: read the ImaDoc files
timecell={};
itime=0;
NbSlice_calib={}; %test for z index 
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
            NbSlice_calib{iview}=size(XmlData{iview}.GeometryCalib.SliceCoord,1);
            if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
                msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
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
% if size(time,2) < i2_series{1}(end) || size(time,3) < j2_series{1}(end)% ime array absent or too short in ImaDoc xml file' 
%     time=[];
% end

%% Field and velocity type (the same for all views)
FieldName='';
if isfield(Param,'InputFields')&&isfield(Param.InputFields,'FieldMenu')  
    FieldName=Param.InputFields.FieldMenu;%the same set of fields for all views
    VelType=Param.InputFields.VelTypeMenu;
end
% if strcmp(get(hseries.FieldMenu,'Visible'),'on')
%     Field_str=get(hseries.FieldMenu,'String');
%     val=get(hseries.FieldMenu,'Value');
%     FieldName=Field_str(val);%the same set of fields for all views
%     VelType_str=get(hseries.VelTypeMenu,'String');
%     VelType_val=get(hseries.VelTypeMenu,'Value');
%     VelType=VelType_str{VelType_val}; %the same for all views
    if strcmp(FieldName,'')
        msgbox_uvmat('ERROR','no input field defined in FieldMenu')
    elseif strcmp(FieldName,'get_field...')
        hget_field=findobj(allchild(0),'Name','get_field');%find the get_field... GUI
        SubField=get_field('read_get_field',hObject,eventdata,hget_field); %read the names of the variables to plot in the get_field GUI
    end
% end
%detect whether all the files are 'images' or 'netcdf'
testima=0;
testvol=0;
testcivx=0;
testnc=0;
for iview=1:nbview
     ext=FileExt{iview};
     form=imformats(ext(2:end));
     if isequal(lower(ext),'.vol')
         testvol=testvol+1;
     elseif ~isempty(form)||isequal(lower(ext),'.avi')% if the extension corresponds to an image format recognized by Matlab
         testima=testima+1;
     elseif isequal(ext,'.nc')
         testnc=testnc+1;
     end
end
if testvol
    msgbox_uvmat('ERROR','volume images not implemented yet')
    return
end
if testnc~=nbview && testima~=nbview && testvol~=nbview
    msgbox_uvmat('ERROR','need a set of images or a set of netcdf files with the same fields as input')
    return
end
if ~isequal(FieldName,'get_field...')
    testcivx=testnc;
end

%% name of output files and directory:
ProjectDir=fileparts(fileparts(RootPath{1}));% preoject directory (GERK)
prompt={['result directory (in' ProjectDir ')']};
% RootPath=get(hseries.RootPath,'String');
% SubDir=get(hseries.SubDir,'String');
if isequal(length(RootPath),1)
    fulldir=RootPath{1};
    subdir='merge_proj';
    res_subdir=fullfile(fulldir,subdir);
else
    def={fullfile(ProjectDir,'0_RESULTS')};
    dlgTitle='result directory';
    lineNo=1;
    answer=msgbox_uvmat('INPUT_TXT',dlgTitle,def);
    fulldir=answer{1};
    subdir=[];
    dirlist=sort(RootFile);
    for iview=1:nbview
        if ~isempty(subdir)
            subdir=[subdir '-'];
        end
        subdir=[subdir dirlist{iview}];
    end  
    res_subdir=fullfile(fulldir,subdir);
end
ext=FileExt{1};
if ~exist(fulldir,'dir')
    msgbox_uvmat('ERROR',['directory ' fulldir ' needs to be created'])
    return
end
if ~exist(res_subdir,'dir')
    dircur=pwd;
    cd(fulldir);
    succeed=mkdir(subdir);
    if succeed
        [xx,msg2] = fileattrib(res_subdir,'+w','g'); %yield writing access (+w) to user group (g)
        if ~strcmp(msg2,'')
            msgbox_uvmat('ERROR',['pb of permission for ' res_subdir ': ' msg2])%error message for directory creation
            cd(dircur)
            return
        end
        cd(dircur);
    else
        msgbox_uvmat('ERROR',['Cannot create directory ' fulldir])
        return
    end
end
filebasesub=fullfile(res_subdir,RootFile{1});
%filebase_merge=fullfile(res_subdir,'merged');%root name for the merged files

%% MAIN LOOP
for ifile=1:nbfield                
    stopstate=get(hseries.RUN,'BusyAction');
    if isequal(stopstate,'queue')% enable STOP command from the 'series' interface
         update_waitbar(hseries.waitbar,WaitbarPos,ifile/nbfield)
         
        %% ----------LOOP ON VIEWS----------------------
        nbtime=0;
        for iview=1:nbview
         %name of the current file
         filename=filecell{iview,ifile};
          %  filename=name_generator(filebase{iview},i1_series{iview}(ifile),j1_series{iview}(ifile),FileExt{iview},NomType{iview},1,i2_series{iview}(ifile),j2_series{iview}(ifile),SubDir{iview});
            if ~exist(filename,'file')
                msgbox_uvmat('ERROR',['missing input file' filename])
                break
            end
            timeread(iview)=0;
         %reading the current file
            if testima
                if test_movie(iview)
                    Field{iview}.A=read(MovieObject{iview},i1_series{iview}(ifile));
                else
                    Field{iview}.A=imread(filename); 
                end % TODO: introduce ListVarName
                npxy=size(Field{iview}.A);
                Field{iview}.ListVarName={'AX','AY','A'};
                Field{iview}.VarDimName={'AX','AY',{'AY','AX'}};
                Field{iview}.AX=[0.5 npxy(2)-0.5]; % coordinates of the first and last pixel centers
                Field{iview}.AY=[npxy(1)-0.5 0.5];
                Field{iview}.CoordUnit='pixel'; 
                Field{iview}.AName='image';
            else
                if testcivx
                    [Field{iview},VelTypeOut]=read_civxdata(filename,FieldName,VelType);
                else
                    [Field{iview},var_detect]=nc2struct(filename,SubField.ListVarName); %read the corresponding input data                
                    Field{iview}.VarAttribute=SubField.VarAttribute;
                end
                if isfield(Field{iview},'Txt')
                    msgbox_uvmat('ERROR',Field{iview}.Txt)
                    return
                end
                if isfield(Field{iview},'Time')
                    timeread(iview)=Field{iview}.Time;
                    nbtime=nbtime+1;
                end
            end
            if ~isempty(NbSlice_calib)
                Field{iview}.ZIndex=mod(i1_series{iview}(ifile)-1,NbSlice_calib{1})+1;
            end
         %transform the input field (e.g; phys) if requested
            if ~isempty(transform_fct)
                Field{iview}=transform_fct(Field{iview},XmlData{iview});  %transform to phys if requested
            end
            if testcivx
                Field{iview}=calc_field(FieldName,Field{iview});
            end
         %projection on object (gridded plane)
            if test_object
                Field{iview}=proj_field(Field{iview},ProjObject);
            end
        end    
        %----------END LOOP ON VIEWS----------------------
         
        %% merge the nbview fields
        MergeData=merge_field(Field);
        if isfield(MergeData,'Txt')
            msgbox_uvmat('ERROR',MergeData.Txt)
            return
        end        
     % generating the name of the merged field
     if testima
         ResultExt='.png';
     else
         ResultExt=FileExt{iview};
     end
     i1=i1_series{iview}(ifile);
     if ~isempty(i2_series{iview})
         i2=i2_series{iview}(ifile);
     else
         i2=i1;
     end
     j1=1;
     j2=1;
     if ~isempty(j1_series{iview})
         j1=j1_series{iview}(ifile);
          if ~isempty(j2_series{iview})
              j2=j2_series{iview}(ifile);
          else
              j2=j1;
          end
     end
     mergename=fullfile_uvmat(res_subdir,'','merged',ResultExt,NomType{iview},i1,i2,j1,j2);
    % mergename=name_generator(filebase_merge,i1,j1_series{iview}(ifile),ResultExt,NomType{iview},1,i2_series{iview}(ifile),j2_series{iview}(ifile));
        
     % time of the merged field:
        time_i=0;%default
        if isempty(time)% time from ImaDoc prevails
            time_i=sum(timeread)/nbtime;
        else
            time_i=i1;
            %time_i=(time(iview,i1,j1)+time(iview,i2,j2))/2; TODO: upgrade
        end
        
     % recording the merged field
        if testima    %in case of input images an image is produced   
            if isa(MergeData.A,'uint8')
                bitdepth=8;
            elseif isa(MergeData.A,'uint16')
                bitdepth=16;
            end
            imwrite(MergeData.A,mergename,'BitDepth',bitdepth); 
            %write xml calibration file
            siz=size(MergeData.A);
            npy=siz(1);
            npx=siz(2);
            if isfield(MergeData,'VarAttribute')&&isfield(MergeData.VarAttribute{1},'Coord_2')&&isfield(MergeData.VarAttribute{1},'Coord_1')
                Rangx=MergeData.VarAttribute{1}.Coord_2;
                Rangy=MergeData.VarAttribute{1}.Coord_1;
            elseif isfield(MergeData,'AX')&& isfield(MergeData,'AY')
                Rangx=[MergeData.AX(1) MergeData.AX(end)];
                Rangy=[MergeData.AY(1) MergeData.AY(end)];
            else
                Rangx=[0.5 npx-0.5];
                Rangy=[npy-0.5 0.5];%default
            end
            pxcmx=(npx-1)/(Rangx(2)-Rangx(1));
            pxcmy=(npy-1)/(Rangy(1)-Rangy(2));
            T_x=-pxcmx*Rangx(1)+0.5;
            T_y=-pxcmy*Rangy(2)+0.5;
            GeometryCal.focal=1;
            GeometryCal.R=[pxcmx,0,0;0,pxcmy,0;0,0,1];
            GeometryCal.Tx_Ty_Tz=[T_x T_y 1];
            ImaDoc.GeometryCalib=GeometryCal;
            t=struct2xml(ImaDoc);
            t=set(t,1,'name','ImaDoc');
            save(t,[filebase_merge '.xml'])     
            display([filebase_merge '.xml saved'])
        else
            MergeData.ListGlobalAttribute={'Project','InputFile_1','InputFile_end','nb_coord','nb_dim','dt','Time','civ'};        
            MergeData.nb_coord=2;
            MergeData.nb_dim=2;
            dt=[];
            if isfield(Field{1},'dt')&& isnumeric(Field{1}.dt)
                dt=Field{1}.dt;
            end
            for iview =2:numel(Field)
                if ~(isfield(Field{iview},'dt')&& isequal(Field{iview}.dt,dt))
                    dt=[];%dt not the same for all fields
                end
            end
            if isempty(dt)
                MergeData.ListGlobalAttribute(6)=[];
            else
               MergeData.dt=dt;
            end
            MergeData.Time=time_i;
            error=struct2nc(mergename,MergeData);%save result file
            if isempty(error)
                display(['output file ' mergename ' written'])
            else
                display(error)
            end
        end
    end
end

%'merge_field': concatene fields
%------------------------------------------------------------------------
function MergeData=merge_field(Data)
%% default output
if isempty(Data)||~iscell(Data)
    MergeData=[];
    return
end
MergeData=Data{1};%default
error=0;
nbview=length(Data);
if nbview==1
    return
end

%% group the variables (fields of 'FieldData') in cells of variables with the same dimensions
[CellVarIndex,NbDim,VarTypeCell]=find_field_indices(Data{1});
%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
% CellVarIndex=cells of variable index arrays
ivar_new=0; % index of the current variable in the projected field
for icell=1:length(CellVarIndex)
    if NbDim(icell)==1
        continue
    end
    VarIndex=CellVarIndex{icell};%  indices of the selected variables in the list FieldData.ListVarName
    VarType=VarTypeCell{icell};
    ivar_X=VarType.coord_x;
    ivar_Y=VarType.coord_y;
    ivar_FF=VarType.errorflag;
    if isempty(ivar_X)
        test_grid=1;%test for input data on regular grid (e.g. image)coordinates
    else
        if length(ivar_Y)~=1
                msgbox_uvmat('ERROR','y coordinate missing in proj_field.m')
                return
        end
        test_grid=0;
    end
    %case of input fields with unstructured coordinates
    if ~test_grid
        for ivar=VarIndex
            VarName=MergeData.ListVarName{ivar};
            for iview=1:nbview
                eval(['MergeData.' VarName '=[MergeData.' VarName '; Data{iview}.' VarName '];'])
            end
        end
    %case of fields defined on a structured  grid 
    else  
        testFF=0;
        for iview=2:nbview
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                if isfield(MergeData,'VarAttribute')
                    if length(MergeData.VarAttribute)>=ivar && isfield(MergeData.VarAttribute{ivar},'Role') && isequal(MergeData.VarAttribute{ivar}.Role,'errorflag')
                        testFF=1;
                    end
                end
                eval(['MergeData.' VarName '=MergeData.' VarName '+ Data{iview}.' VarName ';'])
            end
        end
        if testFF
            nbaver=nbview-MergeData.FF;
            indgood=find(nbaver>0);
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                eval(['MergeData.' VarName '(indgood)=double(MergeData.' VarName '(indgood))./nbaver(indgood);'])
            end 
        else
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                eval(['MergeData.' VarName '=double(MergeData.' VarName ')./nbview;'])
            end    
        end
    end
end

    