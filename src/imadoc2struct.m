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
                Dti=get_value(subt,'/BurstTiming/Dti',[]);
                Dti=Dti/Frequency;%Dtj converted from frame unit to TimeUnit (e.g. 's')
                NbDti=get_value(subt,'/BurstTiming/NbDti',1);
                Time_val=get_value(subt,'/BurstTiming/Time',0);%time in TimeUnit
                if ~isempty(Dti)
                    Dti=reshape(Dti'*ones(1,NbDti),NbDti*numel(Dti),1); %concatene Dti vector NbDti times
                    Time_val=[Time_val;Time_val(end)+cumsum(Dti)];%append the times defined by the intervals  Dti
                end
                if ~isempty(Dtj)
                    Dtj=reshape(Dtj'*ones(1,NbDtj),1,NbDtj*numel(Dtj)); %concatene Dti vector NbDti times
                    Dtj=[0 Dtj];
                    Time_val=Time_val*ones(1,numel(Dtj))+ones(numel(Time_val),1)*cumsum(Dtj);% produce a time matrix with Dtj
                end
                % reading Dtk
                Dtk=get_value(subt,'/BurstTiming/Dtk',[]);
                NbDtk=get_value(subt,'/BurstTiming/NbDtk',1);
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
       [s.TranslationMotor,errormsg]=read_subtree(subt,{'Nbslice','ZStart','ZEnd'},[1 1 1],[1 1 1])
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
            uid_VolumeScan=find(subt,'/GeometryCalib/VolumeScan');
            if ~isempty(uid_VolumeScan)
                tsai.VolumeScan=get(subt,children(subt,uid_VolumeScan),'value');
            end
            tsai.InterfaceCoord=get_value(subt,'/GeometryCalib/InterfaceCoord',[0 0 0])
            tsai.RefractionIndex=get_value(subt,'/GeometryCalib/RefractionIndex',1)
            
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
head_element=get(subt,1,'name')
    cont=get(subt,1,'contents');
    if ~isempty(cont)
        for ilist=1:length(Data)
            uid_key=find(subt,[head_element '/' Data{ilist}])
            if ~isequal(length(uid_key),NbOccur(ilist))
                errormsg=['wrong number of occurence for ' Data{ilist}]
                return
            end
            for ival=1:length(uid_key)
                val=get(subt,children(subt,uid_key(ival)),'value')
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
           end
       end
   end
end
