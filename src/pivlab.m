% 'pivlab': function piv.m adapted from PIVlab http://pivlab.blogspot.com/
%--------------------------------------------------------------------------
% function [xtable ytable utable vtable typevector] = pivlab (image1,image2,ibx,iby step, subpixfinder, mask, roi)
%
% OUTPUT:
% xtable: set of x coordinates
% ytable: set of y coordiantes
% utable: set of u displacements (along x)
% vtable: set of v displacements (along y)
% ctable: max image correlation for each vector
% typevector: set of flags, =1 for good, =0 for NaN vectors
%
%INPUT:
% image1:first image (matrix)
% image2: second image (matrix)
% ibx,iby: size of the correlation box along x and y (in px)
% step: mesh of the measurement points (in px)
% subpixfinder=1 or 2 controls the curve fitting of the image correlation
% mask: =[] for no mask
% roi: 4 element vector defining a region of interest: x position, y position, width, height, (in image indices), for the whole image, roi=[];
function [xtable ytable utable vtable ctable typevector result_conv errormsg] = pivlab (image1,image2,ibx2,iby2,isx2,isy2,shiftx,shifty, GridIndices, subpixfinder,mask)
%this funtion performs the DCC PIV analysis. Recent window-deformation
%methods perform better and will maybe be implemented in the future.
errormsg='';
warning off %MATLAB:log:logOfZero
[npy_ima npx_ima]=size(image1);
if ~isequal(size(image1),size(image2))
    errormsg='image pair with unequal size';
    return
end
    xroi=0;
    yroi=0;
    image1_roi=double(image1);
    image2_roi=double(image2);
if numel(mask)>0
    cellmask=mask;
    mask=zeros(size(image1));
    for i=1:size(cellmask,1);
        masklayerx=cellmask{i,1};
        masklayery=cellmask{i,2};
        mask = mask + poly2mask(masklayerx-xroi,masklayery-yroi,npy_ima,npx_ima); %kleineres eingangsbild und maske geshiftet
    end
else
    mask=zeros(size(image1));
end
mask(mask>1)=1;

% ibx=2*ibx2-1;%ibx and iby odd, reduced by 1 if even
% iby=2*iby2-1;
% miniy=1+iby2
% minix=1+ibx2
% maxiy=step*(floor(size(image1_roi,1)/step))-(iby-1)+iby2 %statt size deltax von ROI nehmen
% maxix=step*(floor(size(image1_roi,2)/step))-(ibx-1)+ibx2
% numelementsy=floor((maxiy-miniy)/step+1);
% numelementsx=floor((maxix-minix)/step+1);
% 
% LAy=miniy;
% LAx=minix;
% LUy=size(image1_roi,1)-maxiy;
% LUx=size(image1_roi,2)-maxix;
% shift4centery=round((LUy-LAy)/2);
% shift4centerx=round((LUx-LAx)/2);
% if shift4centery<0 %shift4center will be negative if in the unshifted case the left border is bigger than the right border. the vectormatrix is hence not centered on the image. the matrix cannot be shifted more towards the left border because then image2_crop would have a negative index. The only way to center the matrix would be to remove a column of vectors on the right side. but then we weould have less data....
%     shift4centery=0;
% end
% if shift4centerx<0 %shift4center will be negative if in the unshifted case the left border is bigger than the right border. the vectormatrix is hence not centered on the image. the matrix cannot be shifted more towards the left border because then image2_crop would have a negative index. The only way to center the matrix would be to remove a column of vectors on the right side. but then we weould have less data....
%     shift4centerx=0;
% end
% miniy=miniy+shift4centery;
% minix=minix+shift4centerx;
% maxix=maxix+shift4centerx;
% maxiy=maxiy+shift4centery;

image1_roi=padarray(image1_roi,[iby2 ibx2], min(min(image1_roi)));%add a border around the image with minimum image value
image2_roi=padarray(image2_roi,[iby2 ibx2], min(min(image1_roi)));
mask=padarray(mask,[iby2 ibx2],0);
%SubPixOffset=0.5;%odd values chosen for ibx and iby

nbvec=size(GridIndices,1);
xtable=zeros(nbvec,1);
ytable=xtable;
utable=xtable;
vtable=xtable;
u2table=xtable;
v2table=xtable;
s2n=xtable;
typevector=ones(size(xtable));

nrx=0;
nrxreal=0;
nry=0;
increments=0;

%% MAINLOOP
for ivec=1:nbvec
    iref=GridIndices(ivec,1);
    jref=GridIndices(ivec,2);
    %jref=npy_ima-PointCoord(ivec,2)+1;
    image1_crop=image1_roi(jref-iby2:jref+iby2,iref-ibx2:iref+ibx2);
    image2_crop=image2_roi(jref+shifty-isy2:jref+shifty+isy2,iref+shiftx-isx2:iref+shiftx+isx2);
        if mask(jref,iref)==0
           %reference: Oliver Pust, PIV: Direct Cross-Correlation
           % image2_crop: sub image with the size of the search area in image 2
           % image1_crop: sub image of the correlation box in image 1
           % %image2_crop is bigger than image1_crop. Zeropading is therefore not
            result_conv= conv2(image2_crop,rot90(image1_crop,2),'valid');         
            %necessary. 'Valid' makes sure that no zero padded content is returned.
            corrmax= max(max(result_conv));
            result_conv=(result_conv/corrmax)*255; %normalize, peak=always 255
           % result_conv=flipdim(result_conv,2);%reverse x direction
            %Find the 255 peak
            [y,x] = find(result_conv==255);
            if isnan(y)==0 & isnan(x)==0 
                try
                    if subpixfinder==1
                        [vector] = SUBPIXGAUSS (result_conv,x,y);
                    elseif subpixfinder==2
                        [vector] = SUBPIX2DGAUSS (result_conv,x,y);
                    end
                catch ME
                    errormsg=ME.message
                    vector=[0 0]; %if something goes wrong with cross correlation.....
                end
            else
                vector=[0 0]; %if something goes wrong with cross correlation.....
            end
        else %if mask was not 0 then
            vector=[0 0];
            typevector(ivec)=0;
        end

        %Create the vector matrix x, y, u, v
        xtable(ivec)=GridIndices(ivec,1);
        ytable(ivec)=GridIndices(ivec,2);
        utable(ivec)=vector(1);
        vtable(ivec)=vector(2);
        sum_square=sum(sum(image1_crop.*image1_crop));
        ctable(ivec)=corrmax/sum_square;
end
result_conv=result_conv/255;


function [vector] = SUBPIXGAUSS (result_conv,x,y)

if size(x,1)>1 %if there are more than 1 peaks just take the first
    x=x(1:1);
end
if size(y,1)>1 %if there are more than 1 peaks just take the first
    y=y(1:1);
end
if (x <= (size(result_conv,1)-1)) && (y <= (size(result_conv,1)-1)) && (x >= 1) && (y >= 1)
    %the following 8 lines are copyright (c) 1998, Uri Shavit, Roi Gurka, Alex Liberzon, Technion – Israel Institute of Technology
    %http://urapiv.wordpress.com
    f0 = log(result_conv(y,x));
    f1 = log(result_conv(y-1,x));
    f2 = log(result_conv(y+1,x));
    peaky = y+ (f1-f2)/(2*f1-4*f0+2*f2);
    f0 = log(result_conv(y,x));
    f1 = log(result_conv(y,x-1));
    f2 = log(result_conv(y,x+1));
    peakx = x+ (f1-f2)/(2*f1-4*f0+2*f2);
    [npy,npx]=size(result_conv);
    vector=[peakx-floor(npx/2)-1 peaky-floor(npy/2)-1];
else
    vector=[NaN NaN];
end

function [vector] = SUBPIX2DGAUSS (result_conv,x,y)
if size(x,1)>1 %if there are more than 1 peaks just take the first
    x=x(1:1);
end
if size(y,1)>1 %if there are more than 1 peaks just take the first
    y=y(1:1);
end
if (x <= (size(result_conv,1)-1)) && (y <= (size(result_conv,1)-1)) && (x >= 1) && (y >= 1)
    for i=-1:1
        for j=-1:1
            %following 15 lines based on
            %H. Nobach Æ M. Honkanen (2005)
            %Two-dimensional Gaussian regression for sub-pixel displacement
            %estimation in particle image velocimetry or particle position
            %estimation in particle tracking velocimetry
            %Experiments in Fluids (2005) 38: 511–515
            c10(j+2,i+2)=i*log(result_conv(y+j, x+i));
            c01(j+2,i+2)=j*log(result_conv(y+j, x+i));
            c11(j+2,i+2)=i*j*log(result_conv(y+j, x+i));
            c20(j+2,i+2)=(3*i^2-2)*log(result_conv(y+j, x+i));
            c02(j+2,i+2)=(3*j^2-2)*log(result_conv(y+j, x+i));
            %c00(j+2,i+2)=(5-3*i^2-3*j^2)*log(result_conv_norm(maxY+j, maxX+i));
        end
    end
    c10=(1/6)*sum(sum(c10));
    c01=(1/6)*sum(sum(c01));
    c11=(1/4)*sum(sum(c11));
    c20=(1/6)*sum(sum(c20));
    c02=(1/6)*sum(sum(c02)); 
    deltax=(c11*c01-2*c10*c02)/(4*c20*c02-c11^2);
    deltay=(c11*c10-2*c01*c20)/(4*c20*c02-c11^2);
    peakx=x+deltax;
    peaky=y+deltay;
    
    [npy,npx]=size(result_conv);
    vector=[peakx-floor(npx/2)-1 peaky-floor(npy/2)-1];
%     SubpixelX=peakx-(ibx/2)-SubPixOffset;
%     SubpixelY=peaky-(iby/2)-SubPixOffset;
%     vector=[SubpixelX, SubpixelY];
else
    vector=[NaN NaN];
end