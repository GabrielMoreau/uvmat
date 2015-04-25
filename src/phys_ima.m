
% phys_ima: transform several images in phys coordinates on a common pixel grid
%------------------------------------------------------------------------
% OUTPUT: 
% A_out: cell array of oitput images corresponding to the transform of the input images
% Rangx, Rangy; vectors with two elements defining the phys positions of first and last pixels in each direction
%  (the same for all the ouput images)
%
% INPUT:  
% A: cell array of input images
% XmlData: cell array of structures defining the calibration parameters for each image
% ZIndex: index of the reference plane used to define the phys position in 3D

function [A_out,Rangx,Rangy]=phys_ima(A,XmlData,ZIndex)
xcorner=[];
ycorner=[];
npx=[];
npy=[];
dx=ones(1,numel(A));
dy=ones(1,numel(A));
if isstruct(XmlData)
    XmlData={XmlData};
end
for icell=1:numel(A)
    siz=size(A{icell});
    npx=[npx siz(2)];
    npy=[npy siz(1)];
    Calib=XmlData{icell}.GeometryCalib;
    xima=[0.5 siz(2)-0.5 0.5 siz(2)-0.5];%image coordinates of corners
    yima=[0.5 0.5 siz(1)-0.5 siz(1)-0.5];
    [xcorner_new,ycorner_new]=phys_XYZ(Calib,xima,yima,ZIndex);%corresponding physical coordinates
    dx(icell)=(max(xcorner_new)-min(xcorner_new))/(siz(2)-1);
    dy(icell)=(max(ycorner_new)-min(ycorner_new))/(siz(1)-1);
    xcorner=[xcorner xcorner_new];
    ycorner=[ycorner ycorner_new];
end
Rangx(1)=min(xcorner);
Rangx(2)=max(xcorner);
Rangy(2)=min(ycorner);
Rangy(1)=max(ycorner);
test_multi=(max(npx)~=min(npx)) || (max(npy)~=min(npy)); %different image lengths
npX=1+round((Rangx(2)-Rangx(1))/min(dx));% nbre of pixels in the new image (use the finest resolution min(dx) in the set of images)
npY=1+round((Rangy(1)-Rangy(2))/min(dy));
x=linspace(Rangx(1),Rangx(2),npX);
y=linspace(Rangy(1),Rangy(2),npY);
[X,Y]=meshgrid(x,y);%grid in physical coordiantes
%vec_B=[];
A_out=cell(1,numel(A));
for icell=1:length(A) 
    Calib=XmlData{icell}.GeometryCalib;
    % rescaling of the image coordinates without change of the image array
    if strcmp(Calib.CalibrationType,'rescale') && isequal(Calib,XmlData{1}.GeometryCalib)
        A_out{icell}=A{icell};%no transform
        Rangx=[0.5 npx-0.5];%image coordiantes of corners
        Rangy=[npy-0.5 0.5];
        [Rangx]=phys_XYZ(Calib,Rangx,[0.5 0.5],ZIndex);%case of translations without rotation and quadratic deformation
        [xx,Rangy]=phys_XYZ(Calib,[0.5 0.5],Rangy,ZIndex);
    else         
        % the image needs to be interpolated to the new coordinates
        zphys=0; %default
        if isfield(Calib,'SliceCoord') %.Z= index of plane
           SliceCoord=Calib.SliceCoord(ZIndex,:);
           zphys=SliceCoord(3); %to generalize for non-parallel planes
%            if isfield(Calib,'InterfaceCoord') && isfield(Calib,'RefractionIndex') 
%                 H=Calib.InterfaceCoord(3);
%                 if H>zphys
%                     zphys=H-(H-zphys)/Calib.RefractionIndex; %corrected z (virtual object)
%                 end
%            end
        end
        xima=0.5:npx-0.5;%image coordinates of corners
        yima=npy-0.5:-1:0.5;
        [XIMA_init,YIMA_init]=meshgrid(xima,yima);%grid of initial image in px coordinates
        [XIMA,YIMA]=px_XYZ(XmlData{icell}.GeometryCalib,X,Y,zphys);% image coordinates for each point in the real
        testuint8=isa(A{icell},'uint8');
        testuint16=isa(A{icell},'uint16');
        if ndims(A{icell})==2 %(B/W images)
        A_out{icell}=interp2(XIMA_init,YIMA_init,double(A{icell}),XIMA,YIMA);
         elseif ndims(A{icell})==3     
             for icolor=1:size(A{icell},3)
                 A{icell}=double(A{icell});
                 A_out{icell}(:,:,icolor)=interp2(XIMA_init,YIMA_init,A{icell}(:,:,icolor),XIMA,YIMA);
             end
         end
        if testuint8
            A_out{icell}=uint8(A_out{icell});
        end
        if testuint16
            A_out{icell}=uint16(A_out{icell});
        end      
    end
end
