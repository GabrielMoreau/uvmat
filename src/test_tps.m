%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

x=2*pi*rand(100,1);%set of random x coordinates from 0 to 2pi
y=2*pi*rand(100,1);%set of random y coordinates
%U=exp(-(x-pi).*(x-pi)-(y-pi).*(y-pi));% gaussian
U=x;
[U_smooth,U_tps]=tps_coeff([x y],U,0);%calculate tps coeff
xI=0:0.1:2*pi;%interpolation grid
yI=0:0.1:2*pi;
[XI,YI]=meshgrid(xI,yI);
[npy,npx]=size(XI);
XI=reshape(XI,[],1);
YI=reshape(YI,[],1);
EM = tps_eval([XI YI],[x y]);%evaluate interpolation on the new grid
U_eval=EM*U_tps;
U_eval=reshape(U_eval,npy,npx);
figure(1)
imagesc(U_eval,[-1 1])
[DMX,DMY] = tps_eval_dxy([XI YI],[x y]);
DUX_eval=DMX*U_tps;
DUY_eval=DMY*U_tps;
DUX_eval=reshape(DUX_eval,npy,npx);
% plot(yI,U_eval(:,5))
figure(2)
DUY_eval=reshape(DUY_eval,npy,npx);
imagesc(DUX_eval,[-1 1])
% plot(xI,DU_eval(:,5))
figure(3)
imagesc(DUY_eval,[-1 1])
figure(4)
% plot(x,U_eval(50,:),x,DUX_eval(50,:),x,DUY_eval(50,:))
size(U_eval(50,:))
size(xI)
plot(xI,U_eval(50,:),xI,DUX_eval(50,:),xI,DUY_eval(50,:))
