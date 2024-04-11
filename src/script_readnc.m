DataFolder='.fsnet/project/coriolis/2024/24PLUME/VectorsEyemotion';
fileinput={'Tore_a8b40_T22s_N047_A1cm.png.civ.mproj.tfilter_1'}
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

