
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
    coord_x=[0.5 siz(2)-0.5];
    coord_y=[0.5 siz(1)-0.5];
    x_edge=[linspace(coord_x(1),coord_x(end),npx(icell)) coord_x(end)*ones(1,npy(icell))...
        linspace(coord_x(end),coord_x(1),npx(icell)) coord_x(1)*ones(1,npy(icell))];%x coordinates of the image edge(four sides)
    y_edge=[coord_y(1)*ones(1,npx(icell)) linspace(coord_y(1),coord_y(end),npy(icell))...
        coord_y(end)*ones(1,npx(icell)) linspace(coord_y(end),coord_y(1),npy(icell))];%y coordinates of the image edge(four sides)
    [xcorner_new,ycorner_new]=phys_XYZ(Calib,x_edge,y_edge,ZIndex);%corresponding physical coordinates
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

npX=1+round((Rangx(2)-Rangx(1))/max(dx));% nbre of pixels in the new image (use the largest resolution max(dx) in the set of images)
npY=1+round((Rangy(1)-Rangy(2))/max(dy));

x=linspace(Rangx(1),Rangx(2),npX);
y=linspace(Rangy(1),Rangy(2),npY);
[X,Y]=meshgrid(x,y);%grid in physical coordinates
A_out=cell(1,numel(A));

for icell=1:length(A)
    Calib=XmlData{icell}.GeometryCalib;
    % rescaling of the image coordinates without change of the image array
    if strcmp(Calib.CalibrationType,'rescale') && isequal(Calib,XmlData{1}.GeometryCalib)
        A_out{icell}=A{icell};%no transform
        Rangx=[0.5 npx-0.5];%image coordiantes of corners
        Rangy=[npy-0.5 0.5];
        [Rangx]=phys_XYZ(Calib,Rangx,[0.5 0.5],ZIndex);%case of translations without rotation and quadratic deformation
        [~,Rangy]=phys_XYZ(Calib,[0.5 0.5],Rangy,ZIndex);
    else
        % the image needs to be interpolated to the new coordinates
        Z=0; %default
        if isfield(Calib,'SliceCoord') %.Z= index of plane
            SliceCoord=Calib.SliceCoord(ZIndex,:);
            Z=SliceCoord(3);
            if isfield(Calib, 'SliceAngle') && size(Calib.SliceAngle,1)>=ZIndex && ~isequal(Calib.SliceAngle(ZIndex,:),[0 0 0])
                norm_plane=angle2normal(Calib.SliceAngle(ZIndex,:));
                Z=Z-(norm_plane(1)*(X-SliceCoord(1))+norm_plane(2)*(Y-SliceCoord(2)))/norm_plane(3);
            end
        end
        xima=0.5:npx(icell)-0.5;%image coordinates of corners
        yima=npy(icell)-0.5:-1:0.5;
        [XIMA_init,YIMA_init]=meshgrid(xima,yima);%grid of initial image in px coordinates
        [XIMA,YIMA]=px_XYZ(XmlData{icell}.GeometryCalib,X,Y,Z);% image coordinates for each point in the real
        testuint8=isa(A{icell},'uint8');
        testuint16=isa(A{icell},'uint16');
        if ismatrix(A{icell}) %(B/W images)
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
