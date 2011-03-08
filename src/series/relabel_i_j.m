% relabel_i_j: relabel an image series with two indices, and correct errors from the RDvision transfer program
%----------------------------------------------------------------------
function GUI_input=relabel_i_j(num_i1,num_i2,num_j1,num_j2,Series)
%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)

GUI_input={};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%enable waitbar
hGUI=findobj(allchild(0),'name','series');
hseries=guidata(hGUI);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PARAMETERS (for RDvision system)
display('RDvision system')
first_label=0 %image numbers start from 0
%errorfactor=1 %correct a factor of 2 in NbDk+1

%% read imadoc
RootPath=get(hseries.RootPath,'String');
RootFile=get(hseries.RootFile,'String');
if ~iscell(RootFile)
    msgbox_uvmat('ERROR','please enter an input image series from RDVision system')%error message for xml file reading
    return
end
basename=fullfile(RootPath{1},RootFile{1}); 
[XmlData,warntext]=imadoc2struct([basename '.xml'])% read the xml file appended to the present function (containing bug corrections)
if ~isempty(warntext)
    msgbox_uvmat('ERROR',warntext)%error message for xml file reading
end
nbfield1=size(XmlData.Time,1);
nbfield2=size(XmlData.Time,2);

set(hseries.first_i,'String',num2str(first_label))% display the first image in the process
set(hseries.last_i,'String',num2str(nbfield1*nbfield2-1+first_label))% display the last image in the process
set(hseries.nb_field,'String',{num2str(nbfield1*nbfield2-1+first_label)})% display the total nbre of images
SeriesData=get(hGUI,'UserData');
if ~strcmp(SeriesData.NomType,'_000001')
    msgbox_uvmat('WARNING','the input is not a file from RDvision: this function relabel_i_j has no action')%error message for directory creation
    return
else
    msgbox_uvmat('CONFIRMATION','this function will relabel the file series from RDvision and correct the xml file')%error message for directory creation
end

%% stop program ther when it is selected in the menu (no run action)
if ~exist('num_i1','var')
    return
end

answer=msgbox_uvmat('CONFIRMATION',[num2str(nbfield1) ' bursts containing ' num2str(nbfield2) ' images each'])%error message for directory creation

%% apply the image rescaling function 'level' (avoid bright particles)
% answer=msgbox_uvmat('INPUT_Y-N','apply image rescaling function levels.m');
% test_level=isequal(answer,'Yes');

%% copy and adapt the xml file
if exist([basename '.xml'],'file')
    try
    copyfile([basename '.xml'],[basename '.xml~']);% backup the xml file
    catch
    errormsg=lasterr
            msgbox_uvmat('ERROR',errormsg);
            return
    end
    t=xmltree([basename '.xml']);
    
    %update information on the first image name in the series
    uid_Heading=find(t,'ImaDoc/Heading');
    if isempty(uid_Heading)
        [t,uid_Heading]=add(t,1,'element','Heading');
    end   
    uid_ImageName=find(t,'ImaDoc/Heading/ImageName');
    ImageName=name_generator(basename,1,1,'.png','_i_j');
    [pth,ImageName]=fileparts(ImageName);
    ImageName=[ImageName '.png']
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
    uid_NbDtj=find(t,'ImaDoc/Camera/BurstTiming/NbDtj');
    t=set(t,uid_NbDtj,'value',num2str(XmlData.NbDtj));
    uid_NbDtk=find(t,'ImaDoc/Camera/BurstTiming/NbDtk');
    t=set(t,uid_NbDtk,'value',num2str(XmlData.NbDtk));
    %%%
    
    save(t,[basename '.xml'])
end

%% main loop
for ifile=1:nbfield1*nbfield2
    update_waitbar(hseries.waitbar,WaitbarPos,ifile/(nbfield1*nbfield2))
    filename=name_generator(basename,ifile-1,1,Series.FileExt,Series.NomType);
    num_j=mod(ifile-1+first_label,nbfield2)+1;
    num_i=floor((ifile-1+first_label)/nbfield2)+1;
    filename_new=name_generator(basename,num_i,num_j,'.png','_i_j');
    try
        movefile(filename,filename_new);
        [s,errormsg] = fileattrib(filename_new,'-w','a'); %set images to read only '-w' for all users ('a')
        if ~s
            msgbox_uvmat('ERROR',errormsg);
            return
        end
    catch
        errormsg=lasterr
        msgbox_uvmat('ERROR',errormsg);
        return
    end
    %     if test_level
    %         A=imread(filename);
    %         C=levels(A);
    %         imwrite(C,filename_new)
    %     else
    %         try
    %             copyfile(filename,filename_new);
    %         catch
    %             errormsg=lasterr
    %             msgbox_uvmat('ERROR',errormsg);
    %             return
    %         end
    %     end
end


function C=levels(A)
%whos A;
B=double(A(:,:,1));
windowsize=round(min(size(B,1),size(B,2))/20);
windowsize=floor(windowsize/2)*2+1;
ix=[1/2-windowsize/2:-1/2+windowsize/2];%
%del=np/3;
%fct=exp(-(ix/del).^2);
fct2=cos(ix/(windowsize-1)/2*pi/2);
%Mfiltre=(ones(5,5)/5^2);
%Mfiltre=fct2';
Mfiltre=fct2'*fct2;
Mfiltre=Mfiltre/(sum(sum(Mfiltre)));

C=filter2(Mfiltre,B);
C(:,1:windowsize)=C(:,windowsize)*ones(1,windowsize);
C(:,end-windowsize+1:end)=C(:,end-windowsize+1)*ones(1,windowsize);
C(1:windowsize,:)=ones(windowsize,1)*C(windowsize,:);
C(end-windowsize+1:end,:)=ones(windowsize,1)*C(end-windowsize,:);
C=tanh(B./(2*C));
[n,c]=hist(reshape(C,1,[]),100);
% figure;plot(c,n);

[m,i]=max(n);
c_max=c(i);
[dummy,index]=sort(abs(c-c(i)));
n=n(index);
c=c(index);
i_select = find(cumsum(n)<0.95*sum(n));
if isempty(i_select)
    i_select = 1:length(c);
end
c_select=c(i_select);
n_select=n(i_select);
cmin=min(c_select);
cmax=max(c_select);
C=(C-cmin)/(cmax-cmin)*256;
C=uint8(C);

%'imadoc2struct': reads the xml file for image documentation 
%------------------------------------------------------------------------
% function [s,errormsg]=imadoc2struct(ImaDoc,option) 
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

function [s,errormsg]=imadoc2struct(ImaDoc,option) 
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
                NbDtj=get_value(subt,'/BurstTiming/NbDtj',1);
                %%%% correction RDvision %%%%
                NbDtj=NbDtj/numel(Dtj);
                s.NbDtj=NbDtj;
                %%%%
                Dti=get_value(subt,'/BurstTiming/Dti',[]);
                Dti=Dti/Frequency;%Dtj converted from frame unit to TimeUnit (e.g. 's')
                NbDti=get_value(subt,'/BurstTiming/NbDti',1);
                Time_val=get_value(subt,'/BurstTiming/Time',0);%time in TimeUnit
                if ~isempty(Dti)
                    Dti=reshape(Dti'*ones(1,NbDti),NbDti*numel(Dti),1); %concatene Dti vector NbDti times
                    Time_val=[Time_val;Time_val(end)+cumsum(Dti)];%append the times defined by the intervals  Dti
                end
                if ~isempty(Dtj)
                    Dtj=reshape(Dtj'*ones(1,NbDtj),1,NbDtj*numel(Dtj)); %concatene Dtj vector NbDtj times
                    Dtj=[0 Dtj];
                    Time_val=Time_val*ones(1,numel(Dtj))+ones(numel(Time_val),1)*cumsum(Dtj);% produce a time matrix with Dtj
                end
                % reading Dtk
                Dtk=get_value(subt,'/BurstTiming/Dtk',[]);
                NbDtk=get_value(subt,'/BurstTiming/NbDtk',1);
                %%%% correction RDvision %%%%
                NbDtk=-1+(NbDtk+1)/(NbDti+1)
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
