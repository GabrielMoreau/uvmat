%'imadoc2struct': reads the xml file for image documentation 
%
%function [s,errormsg]=imadoc2struct(ImaDoc) 
%--------------------------------------------------------
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
%function [s,error,Heading,nom_type_ima,ext_ima,abs_time,TimeUnit,mode,NbSlice]=imadoc2struct(ImaDoc) 
function [s,errormsg]=imadoc2struct(ImaDoc) 

errormsg=[];%default
s.Heading=[];%default
s.Time=[]; %default
s.TimeUnit=[]; %default
s.GeometryCalib=[];
% nom_type_ima=[];%default
% ext_ima=[];%default
% abs_time=[];%initiation
% GeometryCalib.CoordUnit='cm';%default
% mode=[]; %default
% NbSlice=1;%default
% npx=[];%default
% npy=[];%default
% GeometryCalib.Pxcmx=1;
% GeometryCalib.Pxcmy=1;
% GeometryCalib=[];
% NbDtj=1;
tsai=[];%default
% if ~exist('testime','var')
%     testime=1;%default

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

%Heading
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

%Camera   
uid_Camera=find(t,'/ImaDoc/Camera');
if ~isempty(uid_Camera)
    uid_ImageSize=find(t,'/ImaDoc/Camera/ImageSize');
    if ~isempty(uid_ImageSize);
        ImageSize=get(t,children(t,uid_ImageSize),'value');
        xindex=findstr(ImageSize,'x');
        if length(xindex)>=2
             npx=str2double(ImageSize(1:xindex(1)-1));
             npy=str2double(ImageSize(xindex(1)+1:xindex(2)-1));
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
%                 Time_val'
%                 ones(1,numel(Dtj))
%                 ones(numel(Time_val'),1)
%                 cumsum(Dtj)
                Time_val=Time_val*ones(1,numel(Dtj))+ones(numel(Time_val),1)*cumsum(Dtj);% produce a time matrix with Dtj
            end
            % reading Dtk
            Dtk=get_value(subt,'/BurstTiming/Dtk',[]);
            NbDtk=get_value(subt,'/BurstTiming/NbDtk',1);
            if isempty(Dtk)
                s.Time=[s.Time;Time_val];
            else
                for kblock=1:NbDtk+1
                    Time_val=Time_val+(kblock-1)*Dtk;
                    s.Time=[s.Time;Time_val];
                end
            end
        end
    end
    if size(s.Time,1)==1
        s.Time=(s.Time)'; %change vector into column
    end
end

%read calibration
uid_GeometryCalib=find(t,'/ImaDoc/GeometryCalib');
if ~isempty(uid_GeometryCalib)
    if length(uid_GeometryCalib)>1
        errormsg=['More than one GeometryCalib in ' filecivxml];
        return
    end
    subt=branch(t,uid_GeometryCalib);%subtree under GeometryCalib
    cont=get(subt,1,'contents');
    if ~isempty(cont)
        uid_pixcmx=find(subt,'/GeometryCalib/Pxcmx');
        uid_pixcmy=find(subt,'/GeometryCalib/Pxcmy');
        if ~isempty(uid_pixcmx) && ~isempty(uid_pixcmy)%NON UTILISE 
           pixcmx=str2num(get(subt,children(subt,uid_pixcmx),'value'));
            if isempty(pixcmx),pixcmx=1;end; %default
            pixcmy=str2num(get(subt,children(subt,uid_pixcmy),'value'));
            if isempty(pixcmy),pixcmy=1;end; %default
            tsai.Pxcmx=pixcmx;
            tsai.Pxcmy=pixcmy;
        end
        %default values:
        tsai.f=1;
        tsai.dpx=1;
        tsai.dpy=1;
        tsai.sx=1;
        tsai.Cx=0;
        tsai.Cy=0;
        tsai.Tz=1;
        tsai.Tx=0;
        tsai.Ty=0;
        tsai.R=[1 0 0; 0 1 0; 0 0 0];
        tsai.kappa1=0;
        uid_CoordUnit=find(subt,'/GeometryCalib/CoordUnit');
        if ~isempty(uid_CoordUnit) 
            tsai.CoordUnit=get(subt,children(subt,uid_CoordUnit),'value');
        end
        uid_focal=find(subt,'/GeometryCalib/focal');
        uid_dpx_dpy=find(subt,'/GeometryCalib/dpx_dpy');
        uid_sx=find(subt,'/GeometryCalib/sx');
        uid_Cx_Cy=find(subt,'/GeometryCalib/Cx_Cy');
        uid_kappa1=find(subt,'/GeometryCalib/kappa1');
        uid_Tx_Ty_Tz=find(subt,'/GeometryCalib/Tx_Ty_Tz');
        uid_R=find(subt,'/GeometryCalib/R');
        if ~isempty(uid_focal) && ~isempty(uid_dpx_dpy) && ~isempty(uid_Cx_Cy)
            tsai.f=str2num(get(subt,children(subt,uid_focal),'value'));
            dpx_dpy=str2num(get(subt,children(subt,uid_dpx_dpy),'value'));
            tsai.dpx=dpx_dpy(1);
            tsai.dpy=dpx_dpy(2);
            if ~isempty(uid_sx)
               tsai.sx=str2num(get(subt,children(subt,uid_sx),'value')); 
            end
            Cx_Cy=str2num(get(subt,children(subt,uid_Cx_Cy),'value'));
            tsai.Cx=Cx_Cy(1);
            tsai.Cy=Cx_Cy(2);
        end
        if ~isempty(uid_Tx_Ty_Tz) 
            Tx_Ty_T_char=get(subt,children(subt,uid_Tx_Ty_Tz),'value');
            Tx_Ty_Tz=str2num(Tx_Ty_T_char);
            tsai.Tx=Tx_Ty_Tz(1);
            tsai.Ty=Tx_Ty_Tz(2);
            tsai.Tz=Tx_Ty_Tz(3);
        end
        if ~isempty(uid_R)
            RR=get(subt,children(subt,uid_R),'value');
            if length(RR)==3
                tsai.R=[str2num(RR{1});str2num(RR{2});str2num(RR{3})];
            end
        end
        if ~isempty(uid_kappa1)     
            tsai.kappa1=str2num(get(subt,children(subt,uid_kappa1),'value'));
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
                tsai.SliceCoord=ones(NbSlice,1)*tsai.SliceCoord+DZ*[0:NbSlice-1]'*[0 0 1];
            end         
        end
        s.GeometryCalib=tsai;
    end
end   

%--------------------------------------------------
%  read an xml element
function val=get_value(t,label,default)
%--------------------------------------------------
val=default;
uid=find(t,label);%find the element iud(s)
if ~isempty(uid)
   uid_child=children(t,uid);
   if ~isempty(uid_child)
       data=get(t,uid_child,'type');
       if iscell(data)
           for icell=1:numel(data)
               val_read=str2num(get(t,uid_child(icell),'value'));
               if ~isempty(val_read)
                   val(icell)=val_read;
               end
           end
           val=val';
       else
           val_read=str2num(get(t,uid_child,'value'));
           if ~isempty(val_read)
               val=val_read;
           end
       end
   end
end
