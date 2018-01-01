% 'ima_remove_particles': removes particles from an image (keeping the local minimum)
% requires the Matlab image processing toolbox
%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input %%%%
% OUTPUT: 
% DataOut:   output field structure 
%
%INPUT:
% DataIn:  first input field structure

%=======================================================================
% Copyright 2008-2018, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function DataOut=ima_find_particles(DataIn)
%------------------------------------------------------------------------
DataOut=DataIn;  %default  output field
if strcmp(DataIn,'*')
    return
end

%parameters
AbsThreshold=150;
SizePart=3;
%--------------------------------------------------------- 
   %A=double(DataIn.A(:,:,3));% take the blue component
% if ndims(DataIn.A)==3;%color images
    A=sum(double(DataIn.A),3);% take the sum of color components
% end
%%  mask to reduce the  working area (optional)
Mask=ones(size(A));
Mask(1:SizePart,:)=0;
Mask(end-SizePart:end,:)=0;
Mask(:,1:SizePart)=0;
Mask(:,end-SizePart:end)=0;
[Js,Is]=find(A<AbsThreshold &abs(double(DataIn.A(:,:,1))-double(DataIn.A(:,:,3)))<20 & Mask==1);%indices (I,J) of dark pixels
X=zeros(size(Is));
Y=zeros(size(Js));
F=zeros(size(Js));
for ipart=1:numel(Is)
    if Mask(Js(ipart),Is(ipart))==1
        subimage=A(Js(ipart)-SizePart:Js(ipart)+SizePart,Is(ipart)-SizePart:Is(ipart)+SizePart);
        subimage=max(max(subimage))-subimage;%take negative of the image
        [vector,F(ipart)] = SUBPIX2DGAUSS (subimage,SizePart+1,SizePart+1);
        %             X0(ipart)=Is(ipart);%TEST
        %             Y0(ipart)=Js(ipart);%TEST
        X(ipart)=Is(ipart)+vector(1);%corrected position
        Y(ipart)=Js(ipart)+vector(2);
        Xround=round(X(ipart));
        Xlow=max(1,Xround-SizePart);
        Xhigh=min(size(A,2),Xround+SizePart);
        Yround=round(Y(ipart));
        Ylow=max(1,Yround-SizePart);
        Yhigh=min(size(A,1),Yround+SizePart);
        Mask(Ylow:Yhigh,Xlow:Xhigh)=0;% mask the subregion already treated to
        % avoid double counting
    end
end
X=X(X>0);
Y=Y(Y>0);
huvmat=findobj(allchild(0),'Tag','uvmat');
if ~isempty(huvmat)
    haxes=findobj(huvmat,'Tag','PlotAxes');
    set(haxes,'NextPlot','add')
    % hold on
    axes(haxes)
    plot(X-0.5,size(A,1)-Y+0.5,'+')
    set(haxes,'NextPlot','replace')
end
% hold off
hmovie=findobj(allchild(0),'Tag','movieaxes');
if ~isempty(hmovie)
    set(hmovie,'NextPlot','add')
    axes(hmovie)
    plot(X-0.5,size(A,1)-Y+0.5,'+')
    set(hmovies,'NextPlot','replace')
end

        
        %------------------------------------------------------------------------
% --- Find the maximum of the correlation function after interpolation
function [vector,F] = SUBPIX2DGAUSS (result_conv,x,y)
%------------------------------------------------------------------------
vector=[0 0]; %default
F=-2;
peaky=y;
peakx=x;
[npy,npx]=size(result_conv);
if (x <= npx-1) && (y <= npy-1) && (x >= 1) && (y >= 1)
    F=0;
    for i=-1:1
        for j=-1:1
            %following 15 lines based on
            %H. Nobach � M. Honkanen (2005)
            %Two-dimensional Gaussian regression for sub-pixel displacement
            %estimation in particle image velocimetry or particle position
            %estimation in particle tracking velocimetry
            %Experiments in Fluids (2005) 38: 511�515
            c10(j+2,i+2)=i*log(result_conv(y+j, x+i));
            c01(j+2,i+2)=j*log(result_conv(y+j, x+i));
            c11(j+2,i+2)=i*j*log(result_conv(y+j, x+i));
            c20(j+2,i+2)=(3*i^2-2)*log(result_conv(y+j, x+i));
            c02(j+2,i+2)=(3*j^2-2)*log(result_conv(y+j, x+i));
        end
    end
    c10=(1/6)*sum(sum(c10));
    c01=(1/6)*sum(sum(c01));
    c11=(1/4)*sum(sum(c11));
    c20=(1/6)*sum(sum(c20));
    c02=(1/6)*sum(sum(c02)); 
    deltax=(c11*c01-2*c10*c02)/(4*c20*c02-c11^2);
    deltay=(c11*c10-2*c01*c20)/(4*c20*c02-c11^2);
    if abs(deltax)<1
        peakx=x+deltax;
    end
    if abs(deltay)<1
        peaky=y+deltay;
    end
end
vector=[peakx-floor(npx/2)-1 peaky-floor(npy/2)-1];
