%'peaklock': determines peacklocking errors from velocity histograms.
%-------------------------------------------------------
%first smooth the input histogram 'histu' in such a way that the integral over
%n-n+1 is preserved, then deduce the peaklocking 'error' function of the pixcel displacement 'x'.
%
% [histinter,x,error]=peaklock(nbb,minim,maxim,histu)
%OUTPUT:
%histinter: smoothed interpolated histogram
% x: vector of displacement values.
% error: vector of estimated errors corresponding to x
%INPUT:
%histu=vector representing the values of histogram  of measured velocity ;
%minim, maxim: extremal values of the measured velocity (absica for histu)
%nbb: number of bins inside each integer interval for the histograms
%SUBROUTINES INCLUDED:
%spline4.m% spline interpolation at 4th order
%splinhist.m: give spline coeff cc for a smooth histo (call spline4)
%histsmooth.m(x,cc): calculate the smooth histo for any value x
%histder.m(x,cc): calculate the derivative of the smooth histo
function [histinter,x,error]=peaklock(nbb,minim,maxim,histu)

nint=maxim-minim+1
xfin=[minim-0.5+1/(2*nbb):(1/nbb):maxim+0.5-(1/(2*nbb))];
histo=(reshape(histu,nbb,nint));%extract values with x between integer -1/2 integer +1/2
Integ=sum(histo)/nbb; %integral of the pdf on each integer bin
[histinter,cc]=splinhist(Integ,minim,nbb);
histx=reshape(histinter,nbb,nint);
xint=[minim:1:maxim];
x=zeros(nbb,nint);
%determination of the displacement x(j,:)
%j=1
delx=histo(1,:)./histsmooth(-0.5*ones(1,nint),cc)/nbb;
%del(1,:)=delx;
x(1,:)=-0.5+delx-(delx.*delx/2).*histder(-0.5*ones(1,nint),cc);
%histx(1,:)=histsmooth(x(j-1,:),cc);
for j=2:nbb
    delx=histo(j,:)./histsmooth(x(j-1,:),cc)/nbb;
    %delx=delx.*(delx<3*ones(1,nint)/nbb)+3*ones(1,nint)/nbb.*~(delx <3*ones(1,nint)/nbb)
    x(j,:)=x(j-1,:)+delx-(delx.*delx/2).*histder(x(j-1,:),cc);
end
%reshape
xint=ones(nbb,1)*xint;
x=x+xint;
x=reshape(x,1,nbb*nint);
error=xfin+1/(2*nbb)-x;

%-------------------------------------------------------
% --- determine the spline coefficients cc for the interpolated histogram.
%-------------------------------------------------
function [histsmooth,cc]= splinhist(Integ,mini,nbb)
% provides a smooth histogramm histmooth, which remains always positive,
% and is such that its sum over each integer bin [i-1/2 i+1/2] is equal to
% Integ(i). The function determines histmooth as the exponential of a 4th
% order spline function and adjust the cefficients by a Newton method to
% fit the integral conditions Integ
% histmooth is determined at the abscissa
% xfin=[mini-0.5+1/(2*n):(1/n):maxi+0.5-(1/(2*n))] (maxi=mini+size(aa)-1)
%cc(1-5,i) provides the spline coefficients

% order 0
siz=size(Integ);
nint=siz(2);
izero=find(Integ==0); %indices of zero elements
inonzero=find(Integ);
Integ(izero)=min(Integ(inonzero));
aa=log(Integ);%initial guess for a coeff
spli=spline4(aa,mini,nbb);  %appel à la fonction spline4
histsmooth=exp(spli);

S=(sum(reshape(histsmooth,nbb,nint)))/nbb;% integral of the fit histsmooth on ]i-1/2 i+1/2[
epsilon=max(abs(Integ-S));
iter=0;
while epsilon > 0.000001 & iter<10
ident=eye(nint);
dSda=ones(nint);
for j=1:nint% determination of the jacobian matrix dSda
dhistda=spline4(ident(j,:),mini,nbb);
expdhistda=dhistda.*histsmooth;
dSda(j,:)=(sum(reshape(expdhistda,nbb,nint)))/nbb;
end
aa=aa+(Integ-S)*inv(dSda);%new estimate of coefficients aa by linear interpolation
[spli,bb]=spline4(aa,mini,nbb);% new fit histsmooth
histsmooth=exp(spli);
S=(sum(reshape(histsmooth,nbb,nint)))/nbb;% integral of the fit histsmooth on ]i-1/2 i+1/2[
epsilon=max(abs(Integ-S));
iter=iter+1;
end
if iter==10, errordlg('splinhist did not converge after 10 iterations'),end
cc(1,:)=aa;
cc(2,:)=bb(1,:);
cc(3,:)=bb(2,:);
cc(4,:)=bb(3,:);
cc(5,:)=bb(4,:);

%-------------------------------------------------------
% --- determine the 4th order spline coefficients from the function values aa.
%-------------------------------------------------
function [histsmooth,bb]= spline4(aa,mini,n)
% spline interpolation at 4th order
%aa=vector of values of a function at integer abscissa, starting at mini
%n=number of subdivisions for the interpolated function
% histmooth =interpolated values at absissa
% xfin=[mini-0.5+1/(2*n):(1/n):maxi+0.5-(1/(2*n))] (maxi=mini+size(aa)-1)
%bb=[b(i);c(i);d(i); e(i)] matrix of spline coeff
L1=[1/2 1/4 1/8 1/16;1 1 3/4 1/2;0 2 3 3;0 0 6 12];
L2=[-1/2 1/4 -1/8 1/16;1 -1 3/4 -1/2;0 2 -3 3;0 0 6 -12];
M=inv(L2)*L1;
[V,D]=eig(M);
F=-inv(V)*inv(L2)*[1 ;0 ;0;0];
a1rev=[1 -1/D(1,1)];
b1rev=[F(1)/D(1,1)];
a2rev=[1 -1/D(2,2)];
b2rev=[F(2)/D(2,2)];
a3=[1 -D(3,3)];
b3=[F(3)];
a4=[1 -D(4,4)];
b4=[F(4)];

%data
% n=10;% résolution de la pdf: nbre de points par unite de u
% mini=-10.0;%general mini=uint16(min(values)-1 CHOOSE maxi-mini+1 EVEN
% maxi=9.0; % general maxi=uint16(max(values))+1
%nint=double(maxi-mini+1); % nombre d'intervals entiers EVEN!
siz=size(aa);
nint=siz(2);
maxi=mini+nint-1;
npdf=nint*n;% nbre total d'intervals à introduire dans la pdf: hist(u,npdf)
%simulation de pdf
xfin=[mini-0.5+1/(2*n):(1/n):maxi+0.5-(1/(2*n))];% valeurs d'interpolation: we take n values in each integer interval
%histolin=exp(-(xfin-1).*(xfin-1)).*(2+cos(10*(xfin-1)));% simulation d'une pdf
%histo=log(histolin);
%histo=sin(2*pi*xfin);
%histextract=(reshape(histo,n,nint));
%aa=sum(histextract)/n %integral of the pdf on each integer bin
IP=[0 diff(aa)];
Irev=zeros(size(aa));
for i=1:nint
    Irev(i)=aa(end-i+1);
end
IPrev=[0 diff(Irev)];

%get the spline coelfficients a_d, using filter on the eigen vectors A,B,C
Arev=filter(b1rev,a1rev,IPrev);
Brev=filter(b2rev,a2rev,IPrev);
C=filter(b3,a3,IP);
D=filter(b4,a4,IP);
A=zeros(size(Arev));
B=zeros(size(Brev));
for i=1:nint
    A(i)=Arev(end-i+1);
    B(i)=Brev(end-i+1);
end
%Matr=V*[A;B;C;D];
bb=V*[A;B;C;D];
%b=Matr(1,:);
%c=Matr(2,:);
%d=Matr(3,:);
%e=Matr(4,:);
%a=aa;

%calculate the interpolation using the spline coefficients a-d
%xextract=(reshape(xfin,n,nint));% 
chi=xfin+1/(2*n)-min(xfin)-double(int16(xfin+(1/(2*n))-min(xfin)))-0.5;% decimal part
chi2=chi.*chi;
chi3=chi2.*chi;
chi4=chi3.*chi;
avec=reshape(ones(n,1)*aa,1,n*nint);
bvec=reshape(ones(n,1)*bb(1,:),1,n*nint);
cvec=reshape(ones(n,1)*bb(2,:),1,n*nint);
dvec=reshape(ones(n,1)*bb(3,:),1,n*nint);
evec=reshape(ones(n,1)*bb(4,:),1,n*nint);
histsmooth=avec+bvec.*chi+cvec.*chi2+dvec.*chi3+evec.*chi4;

%-------------------------------------------------------
% --- determine the interpolated histogram at points chi from the spline ceff cc.
%-------------------------------------------------
function histx= histsmooth(chi,cc)
% provides the value of the interpolated histogram at values chi=x-i
%(difference with the mnearest integer)
% cc(5,size(chi)) is the set of spline coefficients obtained by splinhist
chi2=chi.*chi;
chi3=chi2.*chi;
chi4=chi3.*chi;
histx=exp(cc(1,:)+cc(2,:).*chi+cc(3,:).*chi2+cc(4,:).*chi3+cc(5,:).*chi4);

%-------------------------------------------------------
% --- determine the derivative p'/p of the interpolated histogram at points chi from the spline ceff cc.
%-------------------------------------------------
function histder= histder(chi,cc)
% provides the logarithmique derivative p'/p of the interpolated histogram
%at values chi=x-i
%(difference with the nearest integer)
% cc(5,size(chi)) is the set of spline coefficients obtained by splinhist
chi2=chi.*chi;
chi3=chi2.*chi;
chi4=chi3.*chi;
histder=cc(2,:)+2*cc(3,:).*chi+3*cc(4,:).*chi2+4*cc(5,:).*chi3;