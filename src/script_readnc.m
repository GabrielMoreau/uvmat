DataFolder='.fsnet/project/coriolis/2024/24PLUME/1_DATA/EXP27/JAI';
fileinput_1='/im.sback.civ2.mproj.tfilter/img_1-19991.nc';
fileinput_2='/im.sback.civ2.mproj.tfilter/img_1-19991.nc';
fileinput=uigetfile_uvmat('pick an input file',DataFolder);
Data=nc2struct(fileinput);
figure
npy=numel(Data.coord_y);
npx=numel(Data.coord_x);
X=ones(npy,1)*Data.coord_x';
Sum=sum(Data.VMean,2);
XMean=sum(X.*Data.VMean,2)./Sum;
XMean=XMean*ones(1,npx);
Xrms=sum(((X-XMean).*(X-XMean).*Data.VMean),2)./Sum;
Xrm=sqrt(Xrms);
plot(Data.coord_y(3:end-1),Xrms(3:end-1))
%0.024 y+0.14
% spread= sqrt(2*log(2))*0.024=0.028
%y0=-5.8; 

