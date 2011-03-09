%'aver_stat': calculate field average, used with series.fig
%------------------------------------------------------------------------
% function GUI_input=aver_stat(num_i1,num_i2,num_j1,num_j2,Series)
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
function GUI_input=aver_stat(num_i1,num_i2,num_j1,num_j2,Series)
%----------------------------------------------------------------------
% --- make average on a series of files
%----------------------------------------------------------------------
%INPUT: 
%num_i1: series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2: series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1: series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2: series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%OTHER INPUTS given by the structure Series
%  Series.Time: 
%  Series.GeometryCalib:%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
    GUI_input={'RootPath';'two';...%nbre of possible input series (options 'on'/'two'/'many', default:'one')
        'SubDir';'on';... % subdirectory of derived files (PIV fields), ('on' by default)
        'RootFile';'on';... %root input file name ('on' by default)
        'FileExt';'on';... %input file extension ('on' by default)
        'NomType';'on';...%type of file indexing ('on' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelTypeMenu';'two';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
        'FieldMenu';'two';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'CoordType'; 'on';...%can use a transform function
        'GetObject';'on';...%can use projection object(option 'off'/'one'/'two',
        %'GetMask';'on'...%can use mask option   
        %'PARAMETER'; %options: name of the user defined parameter',repeat a line for each parameter 
               ''};
        return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%projection object
test_object=get(hseries.GetObject,'Value');
if test_object%isfield(Series,'sethandles')
    hset_object=findobj(allchild(0),'tag','set_object');
    ProjObject=read_set_object(guidata(hset_object));
    %answeryes=questdlg({['field series projected on ' Series.ProjObject.Style]});
    answeryes=msgbox_uvmat('INPUT_Y-N',['field series projected on ' ProjObject.Style ' before averaging']);
    if ~isequal(answeryes,'Yes')
        return
    end
end

%root input file and type
if ~iscell(Series.RootPath)% case of a single input field series
    num_i1={num_i1};num_j1={num_j1};num_i2={num_i2};num_j2={num_j2};
    RootPath={Series.RootPath};
    RootFile={Series.RootFile};
    SubDir={Series.SubDir};
    FileExt={Series.FileExt};
    NomType={Series.NomType};
else
    RootPath=Series.RootPath;
    RootFile=Series.RootFile;
    SubDir=Series.SubDir;
    NomType=Series.NomType;
    FileExt=Series.FileExt;
end   
ext=FileExt{1};
form=imformats(ext([2:end]));%test valid Matlab image formats
testima=0;
if ~isempty(form)||isequal(lower(ext),'.avi')||isequal(lower(ext),'.vol')
    testima(1)=1;
end
if length(FileExt)>=2
    ext_1=FileExt{2};
    form=imformats(ext_1([2:end]));%test valid Matlab image formats
    if ~isempty(form)||isequal(lower(ext_1),'.avi')||isequal(lower(ext_1),'.vol')
        testima(2)=1;
    end
    if testima(2)~=testima(1)
        msgbox_uvmat('ERROR','images and netcdf files cannot be compared')
        return
    end
end

%Number of input series: this function  accepts two input file series at most (then it operates on the difference of fields)
nbview=length(RootPath);
if nbview>2  
    RootPath=RootPath(1:2);
    set(hseries.RootPath,'String',RootPath)
    SubDir=SubDir(1:2);
    set(hseries.SubDir,'String',SubDir)
    RootFile=RootFile(1:2);
    set(hseries.RootFile,'String',RootFile)
    NomType=NomType(1:2);
    FileExt=FileExt(1:2);
    set(hseries.FileExt,'String',FileExt)
    nbview=2;
end

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

% number of slices
NbSlice=str2num(get(hseries.NbSlice,'String'));
if isempty(NbSlice)
    NbSlice=1;
end
NbSlice_name=num2str(NbSlice);

% Field and velocity type (the same for the two views)
Field_str=get(hseries.FieldMenu,'String');
FieldName=[]; %default
testfield=get(hseries.FieldMenu,'Visible');
if isequal(testfield,'on')
    val=get(hseries.FieldMenu,'Value');
    FieldName=Field_str(val);%the same set of fields for all views
    if isequal(FieldName,{'get_field...'})
        hget_field=findobj(allchild(0),'name','get_field');%find the get_field... GUI
        if length(hget_field)>1
            delete(hget_field(2:end))
        elseif isempty(hget_field)
           filename=...
                 name_generator(fullfile(RootPath{1},RootFile{1}),num_i1{1}(1),num_j1{1}(1),FileExt{1},NomType{1},1,num_i2{1}(1),num_j2{1}(1),SubDir{1}); 
           get_field(filename);
           return
        end
        %hhget_field=guidata(hget_field);%handles of GUI elements in get_field
        SubField=read_get_field(hget_field); %read the names of the variables to plot in the get_field GUI
    end
end
%detect whether the two files are 'images' or 'netcdf'
% testima=0;
% testvol=0;
testcivx=0;
% testnc=0;
FileExt=get(hseries.FileExt,'String');
% test_movie=0;
% for iview=1:nbview
%      ext=FileExt{iview};
%      form=imformats(ext([2:end]));
%      if isequal(lower(ext),'.vol')
%          testvol=testvol+1;
%      elseif ~isempty(form)||isequal(lower(ext),'.avi')% if the extension corresponds to an image format recognized by Matlab
%          testima=testima+1;
%      elseif isequal(ext,'.nc')
%          testnc=testnc+1;
%      end
% end
% if testvol
%     msgbox_uvmat('ERROR','volume images not implemented yet')
%     return
% end
% if testnc~=nbview && testima~=nbview && testvol~=nbview
%     msgbox_uvmat('ERROR','compare two image series or two netcdf files with the same fields as input')
%     return
% end
if ~isequal(FieldName,{'get_field...'})
    testcivx=isequal(FileType{1},'netcdf');
end
% if ~isequal(FieldName,{'get_field...'})
%     if isequal(FieldName,{''}) && ~testima
%         msgbox_uvmat('ERROR','an input field needs to be selected')
%         return
%     end
%     testcivx=testnc;
% end

if testcivx
    VelType_str=get(hseries.VelTypeMenu,'String');
    VelType_val=get(hseries.VelTypeMenu,'Value');
    VelType{1}=VelType_str{VelType_val};
    if nbview==2
        VelType_str=get(hseries.VelTypeMenu_1,'String');
        VelType_val=get(hseries.VelTypeMenu_1,'Value');
        VelType{2}=VelType_str{VelType_val};
    end
end

%Calibration data and timing: read the ImaDoc files
mode=''; %default
timecell={};
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

%check coincidence in time
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

%% Root name of output files (TO GENERALISE FOR TWO INPUT SERIES)
subdir_result='aver_stat';
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

% coordinate transform or other user defined transform
transform_fct=[];%default
if isfield(Series,'transform_fct')
    transform_fct=Series.transform_fct;
end

%% slice loop
siz=size(num_i1{1});
lengthtot=siz(1)*siz(2);
nbfield=floor(lengthtot/(siz(1)*NbSlice));%total number of i indexes (adjusted to an integer number of slices)
nbfield_slice=nbfield*siz(1);% number of fields per slice

for i_slice=1:NbSlice
   S=0; %initiate the image sum S 
   nbfiles=0;
   nbmissing=0;
    %averaging loop
   for ifile=i_slice:NbSlice:lengthtot
        stopstate=get(hseries.RUN,'BusyAction');
        if isequal(stopstate,'queue') % enable STOP command
             update_waitbar(hseries.waitbar,WaitbarPos,ifile/lengthtot)
             for iview=1:nbview
                [filename]=...
                           name_generator(filebase{iview},num_i1{iview}(ifile),num_j1{iview}(ifile),FileExt{iview},NomType{iview},1,num_i2{iview}(ifile),num_j2{iview}(ifile),SubDir{iview});
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
                    Atype{iview}=class(A);
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
                if isfield(Data{iview},'Txt')
                    msgbox_uvmat('ERROR',['error of input reading: ' Data{iview}.Txt])
                    return
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
                    msgbox_uvmat('ERROR',['error in aver_stat/sub_field:' errormsg])
                    return
                end
            else
                Field=Data{1};
            end
            if test_object
                [Field,errormsg]=proj_field(Field,ProjObject);
                 if ~isempty(errormsg)
                    msgbox_uvmat('ERROR',['error in aver_stat/proj_field:' errormsg])
                    return
                end
             end                                                        
                nbfiles=nbfiles+1;
                if nbfiles==1 %first field
                    time_1=[];
                    if isfield(Field,'Time')
                        time_1=Field.Time(1);
                    end
                    DataMean=Field;%default
                else
                    for ivar=1:length(Field.ListVarName)
                        VarName=Field.ListVarName{ivar};
                        eval(['sizmean=size(DataMean.' VarName ');']);
                        eval(['siz=size(Field.' VarName ');']);
                        if ~isequal(siz,sizmean)
                           msgbox_uvmat('ERROR',['unequal size of input field ' VarName ', need to interpolate on a grid']) 
                           return
                        else
                            eval(['DataMean.' VarName '=DataMean.' VarName '+ Field.' VarName ';']); % update the sum 
                        end
                    end
                end
        end
    end %end averaging loop
    for ivar=1:length(Field.ListVarName)
        VarName=Field.ListVarName{ivar};
        eval(['DataMean.' VarName '=DataMean.' VarName '/nbfiles;']); % normalize the mean
    end
    if nbmissing~=0
        msgbox_uvmat('WARNING',[num2str(nbmissing) ' input files are missing or skipted'])
    end
    if isempty(time) % time read from files  prevails
        time_end=[];
        if isfield(Field,'Time')
            time_end=Field.Time(1);%last time read
            if ~isempty(time_1)
                DataMean.Time=time_1;
                DataMean.Time_end=time_end;
            end
        end
    else  % time from ImaDoc prevails
        DataMean.Time=time(1,num_i1{1}(1),num_j1{1}(1));
        DataMean.Time_end=time(end,num_i1{end}(end),num_j1{end}(end));
    end

    %writing the result file
   if testima   
        [filemean]=name_generator(filebase_out,num_i1{1}(1),num_j1{1}(1),'.png',NomTypeOut,1,num_i2{end}(end),num_j2{end}(end),subdir_result);
        if exist(filemean,'file')
            backupfile=filemean;
            testexist=2;
            while testexist==2
                backupfile=[backupfile(1:end-4) '~.png'];
                testexist=exist(backupfile,'file');
            end
            [success,message]=copyfile(filemean,backupfile);%make backup
            if ~isequal(success,1)
                msgbox_uvmat('ERROR',['previous file result ' filemean ' already exists, problem in backup'])
                return
            end
        end
        if isequal(Atype{1},'uint16')
            imwrite(uint16(DataMean.A),filemean,'BitDepth',16);
        else
            imwrite(uint8(DataMean.A),filemean,'BitDepth',8);
        end
        display([filemean ' written']);
    else %case of netcdf input file , determine global attributes
        DataMean.ListGlobalAttribute=[DataMean.ListGlobalAttribute {Series.Action}];
        ActionKey='Action';
        while isfield(DataMean,ActionKey)
            ActionKey=[ActionKey '_1'];
        end
        eval(['DataMean.' ActionKey '=Series.Action;'])
        DataMean.ListGlobalAttribute=[DataMean.ListGlobalAttribute {ActionKey}];
        if isfield(DataMean,'Time')
            DataMean.ListGlobalAttribute=[DataMean.ListGlobalAttribute {'Time','Time_end'}];
        end  
        filemean=name_generator(filebase_out,num_i1{1}(1),num_j1{1}(1),'.nc',NomTypeOut,1,num_i2{end}(end),num_j2{end}(end),subdir_result);
        if exist(filemean,'file')
            backupfile=filemean;
            testexist=2;
            while testexist==2
                backupfile=[backupfile(1:end-3) '~.nc'];
                testexist=exist(backupfile,'file');
            end
            [success,message]=copyfile(filemean,backupfile);%make backup
            if ~isequal(success,1)
                msgbox_uvmat('ERROR',['previous file result ' filemean ' already exists, problem in backup'])
                display(['previous file result ' filemean ' already exists, problem in backup'])
                return
            end
        end
        errormsg=struct2nc(filemean,DataMean); %save result file
        if isempty(errormsg)
            display([filemean ' written']);
        else
            msgbox_uvmat('ERROR',['error in writting result file: ' errormsg])
            display(errormsg)
        end
   end
end

hget_field=findobj(allchild(0),'name','get_field');%find the get_field... GUI
delete(hget_field)
uvmat(filemean)