%'relabel_i_j': relabel an image series with two indices, and correct errors from the RDvision transfer program
%------------------------------------------------------------------------
% function ParamOut=relabel_i_j(Param)
%------------------------------------------------------------------------
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%OUTPUT
% ParamOut: sets options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% when Param.Action.RUN=0 (as activated when the current Action is selected
% in series), the function ouput paramOut set the activation of the needed GUI elements
%
% Param contains the elements:(use the menu bar command 'export/GUI config' in series to 
% see the current structure Param)
%    .InputTable: cell of input file names, (several lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDirExt: directory extension for data outputs
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%             .ActionExt: fct extension ('.m', Matlab fct, '.sh', compiled   Matlab fct
%             .RUN =0 for GUI input, =1 for function activation
%             .RunMode='local','background', 'cluster': type of function  use
%             
%    .IndexRange: set the file or frame indices on which the action must be performed
%    .FieldTransform: .TransformName: name of the selected transform function
%                     .TransformPath:   path  of the selected transform function
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%              .Coord_y: name of y coordinate variable
%              .Coord_x: name of x coordinate variable
%    .ProjObject: %sub structure describing a projection object (read from ancillary GUI set_object)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ParamOut=relabel_i_j(Param) %default output=relabel_i_j(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';...% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='on';...% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='one'; ...%nbre of slices, 'one' prevents splitting in several processes, ('off' by default)
    ParamOut.VelType='off';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';...%can use a transform function
    ParamOut.ProjObject='off';...%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';...%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='';%set the output dir extension
    if size(Param.InputTable,1)>1
        msgbox_uvmat('WARNING', 'this function acts only on the first input file line')
    end
return
end

ParamOut=[];
%%%%%%%%%%%% STANDARD PART  %%%%%%%%%%%%
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% root input file(s) and type
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);

% get the set of input file names (cell array filecell), and the lists of
% input file or frame indices i1_series,i2_series,j1_series,j2_series
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
 
% numbers of slices and file indices

nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields

%determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video'};

if ~exist(filecell{1,1}','file')
    msgbox_uvmat('ERROR',['the first input file ' filecell{1,1} ' does not exist'])
    return
end
[FileType{1},FileInfo{1},MovieObject{1}]=get_file_type(filecell{1,1});
CheckImage=~isempty(find(strcmp(FileType{1},ImageTypeOptions)));% =1 for images


%% calibration data and timing: read the ImaDoc files
mode=''; %default
timecell={};
itime=0;
NbSlice_calib={};

SubDirBase=regexprep(SubDir{1},'\..*','');%take the root part of SubDir, before the first dot '.'
filexml=[fullfile(RootPath{1},SubDirBase) '.xml'];%new convention: xml at the level of the image folder
if ~exist(filexml,'file')
    filexml=[fullfile(RootPath{1},SubDir{1},RootFile{1}) '.xml']; % old convention: xml inside the image folder
    if ~exist(filexml,'file')
        filexml=[fullfile(RootPath{1},SubDir{1},RootFile{1}) '.civ']; % very old convention: .civ file
        if ~exist(filexml,'file')
            filexml='';
        end
    end
end
XmlData=[];
if ~isempty(filexml)
    [XmlData,error]=imadoc2struct_special(filexml);
end
if isfield(XmlData,'Time')
    itime=itime+1;
    timecell{itime}=XmlData.Time;
end
if isfield(XmlData,'GeometryCalib') && isfield(XmlData.GeometryCalib,'SliceCoord')
    NbSlice_calib{1}=size(XmlData.GeometryCalib.SliceCoord,1);%nbre of slices for Zindex in phys transform
    if ~isequal(NbSlice_calib{1},NbSlice_calib{1})
        msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
    end
end

%% check coincidence in time for several input file series
% not relevant

%% coordinate transform or other user defined transform
%not relevant
%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE


%% Set field names and velocity types
% not relevant here

%% Initiate output fields
% not relevant here

%% interactive input of specific parameters (for RDvision system)
display('RDvision system')
first_label=0; %image numbers start from 0
if ~CheckImage || ~strcmp(NomType{1},'_000001')
    msgbox_uvmat('WARNING','the input is not a file from RDvision: this function relabel_i_j has no action');%error message for directory creation
    return
else
    answer=msgbox_uvmat('','this function will relabel the file series from RDvision from  and correct the xml file');%error message for directory creation
    if ~strcmp(answer,'Yes')
        return
    end
end

%% copy and adapt the xml file
NomTypeNew='_1_1';
if ~isempty(XmlData)
        t=xmltree(filexml);
        
        %update information on the first image name in the series
        uid_Heading=find(t,'ImaDoc/Heading');
        if isempty(uid_Heading)
            [t,uid_Heading]=add(t,1,'element','Heading');
        end
        uid_ImageName=find(t,'ImaDoc/Heading/ImageName');
        j1=[];
        if ~isempty(j1_series{1})
            j1=j1_series{1};
        end
        ImageName=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},'_1_1',i1_series{1}(1),[],j1);
        [pth,ImageName]=fileparts(ImageName);
        ImageName=[ImageName '.png'];
        if isempty(uid_ImageName)
            [t,uid_ImageName]=add(t,uid_Heading,'element','ImageName');
        end
        uid_value=children(t,uid_ImageName);
        if isempty(uid_value)
            t=add(t,uid_ImageName,'chardata',ImageName);%indicate  name of the first image, with ;png extension
        else
            t=set(t,uid_value(1),'value',ImageName);%indicate  name of the first image, with ;png extension
        end
        
        %%%% correction RDvision %%%%
        if isfield(XmlData,'NbDtj')
            uid_NbDtj=find(t,'ImaDoc/Camera/BurstTiming/NbDtj');
            uid_value=children(t,uid_NbDtj);
            if ~isempty(uid_value)
                t=set(t,uid_value(1),'value',num2str(XmlData.NbDtj));
            end
        end
        if isfield(XmlData,'NbDtk')
            uid_NbDtk=find(t,'ImaDoc/Camera/BurstTiming/NbDtk');
            uid_value=children(t,uid_NbDtk);
            if ~isempty(uid_value)
                t=set(t,uid_value(1),'value',num2str(XmlData.NbDtk));
            end
        end
        if isempty(j1_series{1}) && isfield(XmlData,'NbDti')
            uid_Dti=find(t,'ImaDoc/Camera/BurstTiming/Dti');
            t=add(t,uid_Dti,'chardata',num2str(XmlData.Dti));
            uid_NbDti=find(t,'ImaDoc/Camera/BurstTiming/NbDti');
            t=add(t,uid_NbDti,'chardata',num2str(XmlData.NbDti));
            uid_NbDtj=find(t,'ImaDoc/Camera/BurstTiming/NbDtj');
            uid_NbDtk=find(t,'ImaDoc/Camera/BurstTiming/NbDtk');
            t=delete(t,uid_NbDtj);
            t=delete(t,uid_NbDtk);
            uid_Dtj=find(t,'ImaDoc/Camera/BurstTiming/Dtj');
            uid_Dtk=find(t,'ImaDoc/Camera/BurstTiming/Dtk');
            t=delete(t,uid_Dtj);
            t=delete(t,uid_Dtk);
            NomTypeNew='_1';
        end
            SubDirBase=regexprep(SubDir{1},'\..*','');%take the root part of SubDir, before the first dot '.'
    filexml_new=[fullfile(RootPath{1},SubDirBase) '.xml'];
        save(t,filexml_new)
end

%% main loop on images
%j1=[];%default
nbfield2=1;
if isfield(XmlData,'Time')
nbfield2=size(XmlData.Time,2);
end
for ifile=1:nbfield
            update_waitbar(WaitbarHandle,ifile/nbfield)
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break
    end
    filename=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},NomType{1},i1_series{1}(ifile));
    j1=[];
    if ~isequal(nbfield2,1)
    j1=mod(ifile-1+first_label,nbfield2)+1;
    end
    i1=floor((ifile-1+first_label)/nbfield2)+1;
    filename_new=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},NomTypeNew,i1,[],j1);
    try
        movefile(filename,filename_new);
        [s,errormsg] = fileattrib(filename_new,'-w','a'); %set images to read only '-w' for all users ('a')
        if ~s
            msgbox_uvmat('ERROR',errormsg);
            return
        end
    catch ME
        msgbox_uvmat('ERROR',ME.message);
        return
    end
    
end

%'imadoc2struct_special': reads the xml file for image documentation 
%------------------------------------------------------------------------
% function [s,errormsg]=imadoc2struct_special(ImaDoc,option) 
%
% OUTPUT:
% s: structure representing ImaDoc
%   s.Heading: information about the data hierarchical structure
%   s.Time: matrix of times
%   s.TimeUnit
%  s.GeometryCalib: substructure containing the parameters for geometric calibration
% errormsg: error message
%
% INPUT:
% ImaDoc: full name of the xml input file with head key ImaDoc
% option: ='GeometryCalib': read  the data of GeometryCalib, including source point coordinates

function [s,errormsg]=imadoc2struct_special(ImaDoc,option) 

%% default input and output
if ~exist('option','var')
    option='*';
end
errormsg=[];%default
s.Heading=[];%default
s.Time=[]; %default
s.TimeUnit=[]; %default
s.GeometryCalib=[];
tsai=[];%default

%% opening the xml file
if exist(ImaDoc,'file')~=2, errormsg=[ ImaDoc ' does not exist']; return;end;%input file does not exist
try
    t=xmltree(ImaDoc);
catch
    errormsg={[ImaDoc ' is not a valid xml file']; lasterr};
    display(errormsg);
    return
end
uid_root=find(t,'/ImaDoc');
if isempty(uid_root), errormsg=[ImaDoc ' is not an image documentation file ImaDoc']; return; end;%not an ImaDoc .xml file


%% Heading
uid_Heading=find(t,'/ImaDoc/Heading');
if ~isempty(uid_Heading), 
    uid_Campaign=find(t,'/ImaDoc/Heading/Campaign');
    uid_Exp=find(t,'/ImaDoc/Heading/Experiment');
    uid_Device=find(t,'/ImaDoc/Heading/Device');
    uid_Record=find(t,'/ImaDoc/Heading/Record');
    uid_FirstImage=find(t,'/ImaDoc/Heading/ImageName');
    s.Heading.Campaign=get(t,children(t,uid_Campaign),'value');
    s.Heading.Experiment=get(t,children(t,uid_Exp),'value');
    s.Heading.Device=get(t,children(t,uid_Device),'value');
    if ~isempty(uid_Record)
        s.Heading.Record=get(t,children(t,uid_Record),'value');
    end
    s.Heading.ImageName=get(t,children(t,uid_FirstImage),'value');
end

%% Camera  and timing
if strcmp(option,'*') || strcmp(option,'Camera')
    uid_Camera=find(t,'/ImaDoc/Camera');
    if ~isempty(uid_Camera)
        uid_ImageSize=find(t,'/ImaDoc/Camera/ImageSize');
        if ~isempty(uid_ImageSize);
            ImageSize=get(t,children(t,uid_ImageSize),'value');
            xindex=findstr(ImageSize,'x');
            if length(xindex)>=2
                s.Npx=str2double(ImageSize(1:xindex(1)-1));
                s.Npy=str2double(ImageSize(xindex(1)+1:xindex(2)-1));
            end
        end
        uid_TimeUnit=find(t,'/ImaDoc/Camera/TimeUnit');
        if ~isempty(uid_TimeUnit)
            s.TimeUnit=get(t,children(t,uid_TimeUnit),'value');
        end
        uid_BurstTiming=find(t,'/ImaDoc/Camera/BurstTiming');
        if ~isempty(uid_BurstTiming)
            for k=1:length(uid_BurstTiming)
                subt=branch(t,uid_BurstTiming(k));%subtree under BurstTiming
                % reading Dtk
                Frequency=get_value(subt,'/BurstTiming/FrameFrequency',1);
                Dtj=get_value(subt,'/BurstTiming/Dtj',[]);
                Dtj=Dtj/Frequency;%Dtj converted from frame unit to TimeUnit (e.g. 's')
                NbDtj=get_value(subt,'/BurstTiming/NbDtj',[]);
                %%%% correction RDvision %%%%
%                 NbDtj=NbDtj/numel(Dtj);
%                 s.NbDtj=NbDtj;
%                 %%%%
                Dti=get_value(subt,'/BurstTiming/Dti',[]);
                NbDti=get_value(subt,'/BurstTiming/NbDti',1);
                 %%%% correction RDvision %%%%
                if isempty(Dti)% series 
                     Dti=Dtj;
                      NbDti=NbDtj;
                     Dtj=[];
                     s.Dti=Dti;
                     s.NbDti=NbDti;
                else
                    % NbDtj=NbDtj/numel(Dtj);%bursts
                    if ~isempty(NbDtj)
                    s.NbDtj=NbDtj/numel(Dtj);%bursts;
                    else
                        s.NbDtj=1;
                    end
                end
                %%%% %%%%
                Dti=Dti/Frequency;%Dtj converted from frame unit to TimeUnit (e.g. 's')

                Time_val=get_value(subt,'/BurstTiming/Time',0);%time in TimeUnit
                if ~isempty(Dti)
                    Dti=reshape(Dti'*ones(1,NbDti),NbDti*numel(Dti),1); %concatene Dti vector NbDti times
                    Time_val=[Time_val;Time_val(end)+cumsum(Dti)];%append the times defined by the intervals  Dti
                end
                if ~isempty(Dtj)
                    Dtj=reshape(Dtj'*ones(1,s.NbDtj),1,s.NbDtj*numel(Dtj)); %concatene Dtj vector NbDtj times
                    Dtj=[0 Dtj];
                    Time_val=Time_val*ones(1,numel(Dtj))+ones(numel(Time_val),1)*cumsum(Dtj);% produce a time matrix with Dtj
                end
                % reading Dtk
                Dtk=get_value(subt,'/BurstTiming/Dtk',[]);
                NbDtk=get_value(subt,'/BurstTiming/NbDtk',1);
                %%%% correction RDvision %%%%
                if ~isequal(NbDtk,1)
                    NbDtk=-1+(NbDtk+1)/(NbDti+1);
                end
                s.NbDtk=NbDtk;
                %%%%%
                if isempty(Dtk)
                    s.Time=[s.Time;Time_val];
                else
                    for kblock=1:NbDtk+1
                        Time_val_k=Time_val+(kblock-1)*Dtk;
                        s.Time=[s.Time;Time_val_k];
                    end
                end
            end
        end
    end
end

%% motor
if strcmp(option,'*') || strcmp(option,'GeometryCalib')
    uid_subtree=find(t,'/ImaDoc/TranslationMotor');
    if length(uid_subtree)==1
        subt=branch(t,uid_subtree);%subtree under GeometryCalib
       [s.TranslationMotor,errormsg]=read_subtree(subt,{'Nbslice','ZStart','ZEnd'},[1 1 1],[1 1 1]);
    end 
end
%%  geometric calibration
if strcmp(option,'*') || strcmp(option,'GeometryCalib')
    uid_GeometryCalib=find(t,'/ImaDoc/GeometryCalib');
    if ~isempty(uid_GeometryCalib)
        if length(uid_GeometryCalib)>1
            errormsg=['More than one GeometryCalib in ' filecivxml];
            return
        end
        subt=branch(t,uid_GeometryCalib);%subtree under GeometryCalib
        cont=get(subt,1,'contents');
        if ~isempty(cont)
            uid_CalibrationType=find(subt,'/GeometryCalib/CalibrationType');
            if isequal(length(uid_CalibrationType),1)
                tsai.CalibrationType=get(subt,children(subt,uid_CalibrationType),'value');
            end
            uid_CoordUnit=find(subt,'/GeometryCalib/CoordUnit');
            if isequal(length(uid_CoordUnit),1)
                tsai.CoordUnit=get(subt,children(subt,uid_CoordUnit),'value');
            end
            uid_fx_fy=find(subt,'/GeometryCalib/fx_fy');
            focal=[];%default fro old convention (Reg Wilson)
            if isequal(length(uid_fx_fy),1)
                tsai.fx_fy=str2num(get(subt,children(subt,uid_fx_fy),'value'));
            else %old convention (Reg Wilson)
                uid_focal=find(subt,'/GeometryCalib/focal');
                uid_dpx_dpy=find(subt,'/GeometryCalib/dpx_dpy');
                uid_sx=find(subt,'/GeometryCalib/sx');
                if ~isempty(uid_focal) && ~isempty(uid_dpx_dpy) && ~isempty(uid_sx)
                    dpx_dpy=str2num(get(subt,children(subt,uid_dpx_dpy),'value'));
                    sx=str2num(get(subt,children(subt,uid_sx),'value'));
                    focal=str2num(get(subt,children(subt,uid_focal),'value'));
                    tsai.fx_fy(1)=sx*focal/dpx_dpy(1);
                    tsai.fx_fy(2)=focal/dpx_dpy(2);
                end
            end
            uid_Cx_Cy=find(subt,'/GeometryCalib/Cx_Cy');
            if ~isempty(uid_Cx_Cy)
                tsai.Cx_Cy=str2num(get(subt,children(subt,uid_Cx_Cy),'value'));
            end
            uid_kc=find(subt,'/GeometryCalib/kc');
            if ~isempty(uid_kc)
                tsai.kc=str2double(get(subt,children(subt,uid_kc),'value'));
            else %old convention (Reg Wilson)
                uid_kappa1=find(subt,'/GeometryCalib/kappa1');
                if ~isempty(uid_kappa1)&& ~isempty(focal)
                    kappa1=str2double(get(subt,children(subt,uid_kappa1),'value'));
                    tsai.kc=-kappa1*focal*focal;
                end
            end
            uid_Tx_Ty_Tz=find(subt,'/GeometryCalib/Tx_Ty_Tz');
            if ~isempty(uid_Tx_Ty_Tz)
                tsai.Tx_Ty_Tz=str2num(get(subt,children(subt,uid_Tx_Ty_Tz),'value'));
            end
            uid_R=find(subt,'/GeometryCalib/R');
            if ~isempty(uid_R)
                RR=get(subt,children(subt,uid_R),'value');
                if length(RR)==3
                    tsai.R=[str2num(RR{1});str2num(RR{2});str2num(RR{3})];
                end
            end
            
            %look for laser plane definitions
            uid_Angle=find(subt,'/GeometryCalib/PlaneAngle');
            uid_Pos=find(subt,'/GeometryCalib/SliceCoord');
            if isempty(uid_Pos)
                uid_Pos=find(subt,'/GeometryCalib/PlanePos');%old convention
            end
            if ~isempty(uid_Angle)
                tsai.PlaneAngle=str2num(get(subt,children(subt,uid_Angle),'value'));
            end
            if ~isempty(uid_Pos)
                for j=1:length(uid_Pos)
                    tsai.SliceCoord(j,:)=str2num(get(subt,children(subt,uid_Pos(j)),'value'));
                end
                uid_DZ=find(subt,'/GeometryCalib/SliceDZ');
                uid_NbSlice=find(subt,'/GeometryCalib/NbSlice');
                if ~isempty(uid_DZ) && ~isempty(uid_NbSlice)
                    DZ=str2double(get(subt,children(subt,uid_DZ),'value'));
                    NbSlice=get(subt,children(subt,uid_NbSlice),'value');
                    if isequal(NbSlice,'volume')
                        tsai.NbSlice='volume';
                        NbSlice=NbDtj+1;
                    else
                        tsai.NbSlice=str2double(NbSlice);
                    end
                    tsai.SliceCoord=ones(NbSlice,1)*tsai.SliceCoord+DZ*(0:NbSlice-1)'*[0 0 1];
                end
            end   
            tsai.SliceAngle=get_value(subt,'/GeometryCalib/SliceAngle',[0 0 0]);
            tsai.VolumeScan=get_value(subt,'/GeometryCalib/VolumeScan','n');
            tsai.InterfaceCoord=get_value(subt,'/GeometryCalib/InterfaceCoord',[0 0 0]);
            tsai.RefractionIndex=get_value(subt,'/GeometryCalib/RefractionIndex',1);
            
            if strcmp(option,'GeometryCalib')
                tsai.PointCoord=get_value(subt,'/GeometryCalib/SourceCalib/PointCoord',[0 0 0 0 0]);
            end
            s.GeometryCalib=tsai;
        end
    end
end

%--------------------------------------------------
%  read a subtree
% INPUT: 
% t: xltree
% head_element: head elelemnt of the subtree
% Data, structure containing 
%    .Key: element name
%    .Type: type of element ('charg', 'float'....)
%    .NbOccur: nbre of occurrence, NaN for un specified number 
function [s,errormsg]=read_subtree(subt,Data,NbOccur,NumTest)
%--------------------------------------------------
s=[];%default
errormsg='';
head_element=get(subt,1,'name');
    cont=get(subt,1,'contents');
    if ~isempty(cont)
        for ilist=1:length(Data)
            uid_key=find(subt,[head_element '/' Data{ilist}]);
            if ~isequal(length(uid_key),NbOccur(ilist))
                errormsg=['wrong number of occurence for ' Data{ilist}];
                return
            end
            for ival=1:length(uid_key)
                val=get(subt,children(subt,uid_key(ival)),'value');
                if ~NumTest(ilist)
                    eval(['s.' Data{ilist} '=val;']);
                else
                    eval(['s.' Data{ilist} '=str2double(val);'])
                end
            end
        end
    end


%--------------------------------------------------
%  read an xml element
function val=get_value(t,label,default)
%--------------------------------------------------
val=default;
uid=find(t,label);%find the element iud(s)
if ~isempty(uid) %if the element named label exists
   uid_child=children(t,uid);%find the children 
   if ~isempty(uid_child)
       data=get(t,uid_child,'type');%get the type of child
       if iscell(data)% case of multiple element
           for icell=1:numel(data)
               val_read=str2num(get(t,uid_child(icell),'value'));
               if ~isempty(val_read)
                   val(icell,:)=val_read;
               end
           end
%           val=val';
       else % case of unique element value
           val_read=str2num(get(t,uid_child,'value'));
           if ~isempty(val_read)
               val=val_read;
           else
              val=get(t,uid_child,'value');%char string data
           end
       end
   end
end
