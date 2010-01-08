%'read_imadoc': reads the xml file for image documentation, OBSOLETE: replaced by imadoc2struct
%
%function [error,Heading,nom_type_ima,ext_ima,abs_time,TimeUnit,mode,NbSlice,npx,npy,GeometryCalib]=read_imadoc(filecivxml,testime) 
%--------------------------------------------------------
% OUTPUT:
%error= 0: all right
%        2: input file not found
%        1: input file is not an image documentation file 'ImaDoc'
%           1.1: 'ImaDoc/Heading' element absent
%           1.2: 'ImaDoc/Camera' element absent
%                 1.21: 'ImaDoc/Camera/BurstTiming' absent
%                     1.211: 'ImaDoc/Camera/BurstTiming/FrameFrequency' absent
%                     1.212: 'ImaDoc/Camera/BurstTiming/Time' absent
%
% INPUT:
% filecivxml: full name of the xml input file
% testime=1 read the list of times), =0 (default) do not read it to save computing  time
%
%  -- TODO: should be replaced by xml2struct --

function [error,Heading,nom_type_ima,ext_ima,abs_time,TimeUnit,mode,NbSlice,npx,npy,GeometryCalib]=read_imadoc(filecivxml,testime) 
% global t
error=0;%default
Heading=[];%default
nom_type_ima=[];%default
ext_ima=[];%default
abs_time=[];%initiation
TimeUnit='s'; %default
% GeometryCalib.CoordUnit='cm';%default
mode=[]; %default
NbSlice=1;%default
npx=[];%default
npy=[];%default
% GeometryCalib.Pxcmx=1;
% GeometryCalib.Pxcmy=1;
GeometryCalib=[];
NbDtj=1;
tsai=[];%default
if ~exist('testime','var')
    testime=1;%default
end
if exist(filecivxml,'file')~=2, error=2, return;end;%input file does not exist
filecivxml;
t=xmltree(filecivxml);
uid_root=find(t,'/ImaDoc');
if isempty(uid_root), error=1; return; end;%not an ImaDoc .xml file
%Heading
uid_Heading=find(t,'/ImaDoc/Heading');
if isempty(uid_Heading), 
    error=1.1;
else
    uid_Campaign=find(t,'/ImaDoc/Heading/Campaign');
    uid_Exp=find(t,'/ImaDoc/Heading/Experiment');
    uid_Device=find(t,'/ImaDoc/Heading/Device');
    uid_Record=find(t,'/ImaDoc/Heading/Record');
    uid_FirstImage=find(t,'/ImaDoc/Heading/ImageName');
    Heading.Campaign=get(t,children(t,uid_Campaign),'value');
    Heading.Experiment=get(t,children(t,uid_Exp),'value');
    Heading.Device=get(t,children(t,uid_Device),'value');
    if ~isempty(uid_Record)
        Heading.Record=get(t,children(t,uid_Record),'value');
    end
    Heading.ImageName=get(t,children(t,uid_FirstImage),'value');
    FirstImage=Heading.ImageName;
    if ~isempty(FirstImage)
        [Pathsub,RootFile,field_count,str2,str_a,str_b,ext,nom_type_ima]=name2display(FirstImage);
    end
end
%Camera   
uid_Camera=find(t,'/ImaDoc/Camera');
if isempty(uid_Camera)
    error=1.2;
else
    uid_ImageSize=find(t,'/ImaDoc/Camera/ImageSize');
    if ~isempty(uid_ImageSize);
        ImageSize=get(t,children(t,uid_ImageSize),'value');
        xindex=findstr(ImageSize,'x');
        if length(xindex)>=2
            npx=str2num(ImageSize(1:xindex(1)-1));
            npy=str2num(ImageSize(xindex(1)+1:xindex(2)-1));
        end
    end
    uid_NbSlice=find(t,'/ImaDoc/Camera/NbSlice');
    if ~isempty(uid_NbSlice)
        NbSlice=str2num(get(t,children(t,uid_NbSlice),'value'));
        if isempty(NbSlice),NbSlice=1;end; %default
    end
    uid_TimeUnit=find(t,'/ImaDoc/Camera/TimeUnit');
    if ~isempty(uid_TimeUnit)
        TimeUnit=get(t,children(t,uid_TimeUnit),'value');
        if isempty(TimeUnit),TimeUnit='s';end; %default
    end
    uid_BurstTiming=find(t,'/ImaDoc/Camera/BurstTiming');
    if isempty(uid_BurstTiming), error=1.12,return,end;
    if testime
        for k=1:length(uid_BurstTiming)
            Dtj=[];%default
            NbDtj=1;%default
            subt=branch(t,uid_BurstTiming(k));%subtree under BurstTiming
            uid_FrameFrequency=find(subt,'/BurstTiming/FrameFrequency');
           % if isempty(uid_FrameFrequency), error=1.211,return;
            if isempty(uid_FrameFrequency),
                Frequency=1;
            else
                Frequency=str2num(get(subt,children(subt,uid_FrameFrequency),'value'));
            end
            uid_Dtj=find(subt,'/BurstTiming/Dtj');
            uid_NbDtj=find(subt,'/BurstTiming/NbDtj');
            uid_Dti=find(subt,'/BurstTiming/Dti');%new
            uid_NbDti=find(subt,'/BurstTiming/NbDti');%new
            if ~isempty(uid_Dtj)
               Dtj=str2num(get(subt,children(subt,uid_Dtj),'value'));%time intervals in frames
            end
            uid_child=children(subt,uid_NbDtj);
            for ivalue=1:length(uid_child)
                if isequal(get(subt,uid_child(ivalue),'type'),'chardata')
                     NbDtj=str2num(get(subt,uid_child(ivalue),'value'));%nbre of intervals Dtj
               end
            end
            if isempty(uid_Dti)|isempty(uid_NbDti)
               Dti=[]; %default
            else
               Dti=str2num(get(subt,children(subt,uid_Dti),'value'));%time intervals in frames
               uid_child=children(subt,uid_NbDti);
               for ivalue=1:length(uid_child)
                  if isequal(get(subt,uid_child(ivalue),'type'),'chardata')
                     NbDti=str2num(get(subt,uid_child(ivalue),'value'));%nbre of intervals Dti
                  end
               end
            end
            if ~isempty(Dtj)
                Dtj=reshape(Dtj'*ones(1,NbDtj),1,length(Dtj)*NbDtj);
            end
            Dtj=[0 Dtj];
            dtunit=Dtj/Frequency;
            uid_Time=find(subt,'/BurstTiming/Time');
            if isempty(uid_Time)
                error=1.212;
            else
                nbfield=length(uid_Time);
               Time=get(subt,children(subt,uid_Time),'value');
               abstime_read=str2num(char(Time))*ones(1,length(Dtj))+ones(nbfield,1)*cumsum(dtunit);
               abs_time=[abs_time;abstime_read];
               if ~isempty(Dti)&size(abs_time,1)==1
                  abs_time=ones(NbDti+1,1)*abs_time+(Dti/Frequency)*[0:NbDti]'*ones(size(abs_time));
               end
            end
        end
    end
end
% if isempty(abs_time)
%     abs_time=0;%default
% end
%read calibration
uid_GeometryCalib=find(t,'/ImaDoc/GeometryCalib');
if ~isempty(uid_GeometryCalib)
    if length(uid_GeometryCalib)>1
        errordlg(['More than one GeometryCalib in ' filecivxml])
        return
    end
    subt=branch(t,uid_GeometryCalib);%subtree under GeometryCalib
    cont=get(subt,1,'contents');
    if ~isempty(cont)
        uid_pixcmx=find(subt,'/GeometryCalib/Pxcmx');
        uid_pixcmy=find(subt,'/GeometryCalib/Pxcmy');
        if ~isempty(uid_pixcmx) & ~isempty(uid_pixcmy)%NON UTILISE 
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
        if ~isempty(uid_focal) & ~isempty(uid_dpx_dpy) & ~isempty(uid_Cx_Cy)
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
%             if ~ischar(Tx_Ty_T_char)
%                 error='multiple values for Tx_Ty_Tz';
%             else
                Tx_Ty_Tz=str2num(Tx_Ty_T_char);
%             end
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
        uid_Pos=find(subt,'/GeometryCalib/PlanePos');
        if ~isempty(uid_Angle) 
            tsai.PlaneAngle=str2num(get(subt,children(subt,uid_Angle),'value'));
        end
        if ~isempty(uid_Pos)
            for j=1:length(uid_Pos)
                tsai.PlanePos(j,:)=str2num(get(subt,children(subt,uid_Pos(j)),'value'));
            end
        end
        GeometryCalib=tsai;
    end
end   

