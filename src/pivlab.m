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
% ibx2,iby2: half size of the correlation box along x and y, in px (size=(2*iby2+1,2*ibx2+1)
% isx2,isy2: half size of the search box along x and y, in px (size=(2*isy2+1,2*isx2+1)
% shiftx, shifty: shift of the search box (in pixel index, yshift reversed)
% step: mesh of the measurement points (in px)
% subpixfinder=1 or 2 controls the curve fitting of the image correlation
% mask: =[] for no mask
% roi: 4 element vector defining a region of interest: x position, y position, width, height, (in image indices), for the whole image, roi=[];
function [xtable ytable utable vtable ctable F result_conv errormsg] = pivlab (image1,image2,ibx2,iby2,isx2,isy2,shiftx,shifty, GridIndices, subpixfinder,mask)
%this funtion performs the DCC PIV analysis. Recent window-deformation
%methods perform better and will maybe be implemented in the future.
nbvec=size(GridIndices,1);
xtable=zeros(nbvec,1);
ytable=xtable;
utable=xtable;
vtable=xtable;
ctable=xtable;
F=xtable;
result_conv=[];
errormsg='';
%warning off %MATLAB:log:logOfZero
[npy_ima npx_ima]=size(image1);
if ~isequal(size(image2),[npy_ima npx_ima])
    errormsg='image pair with unequal size';
    return
end

%% mask
testmask=0;
if exist('mask','var') && ~isempty(mask)
   testmask=1;
   if ~isequal(size(mask),[npy_ima npx_ima])
        errormsg='mask must be an image with the same size as the images';
        return
   end
    % Convention for mask
    % mask >200 : velocity calculated
    %  200 >=mask>150;velocity not calculated, interpolation allowed (bad spots)
    % 150>=mask >100: velocity not calculated, nor interpolated
    %  100>=mask> 20: velocity not calculated, impermeable (no flux through mask boundaries)
    %  20>=mask: velocity=0
    test_noflux=(mask<=100) ;
    test_undefined=(mask<=200 & mask>100 );
    image1(test_undefined)=min(min(image1))*ones(size(image1));% put image to zero in the undefined  area
    image2(test_undefined)=min(min(image1))*ones(size(image1));% put image to zero in the undefined  area
end
image1=double(image1);
image2=double(image2);

%% calculate correlations: MAINLOOP
corrmax=0;
sum_square=1;% default
for ivec=1:nbvec
    iref=GridIndices(ivec,1);
    jref=GridIndices(ivec,2);
    testmask_ij=0;
    test0=0;
    if testmask
        if mask(jref,iref)<=20
           vector=[0 0];
           test0=1;
        else
            mask_crop1=mask(jref-iby2:jref+iby2,iref-ibx2:iref+ibx2);
            mask_crop2=mask(jref+shifty-isy2:jref+shifty+isy2,iref+shiftx-isx2:iref+shiftx+isx2);
            if ~isempty(find(mask_crop1<=200 & mask_crop1>100,1)) || ~isempty(find(mask_crop2<=200 & mask_crop2>100,1));
                testmask_ij=1;
            end
        end
    end
    if ~test0
        image1_crop=image1(jref-iby2:jref+iby2,iref-ibx2:iref+ibx2);
        image2_crop=image2(jref+shifty-isy2:jref+shifty+isy2,iref+shiftx-isx2:iref+shiftx+isx2);
        image1_crop=image1_crop-mean(mean(image1_crop));
        image2_crop=image2_crop-mean(mean(image2_crop));
        %reference: Oliver Pust, PIV: Direct Cross-Correlation
        result_conv= conv2(image2_crop,flipdim(flipdim(image1_crop,2),1),'valid');
        corrmax= max(max(result_conv));
        result_conv=(result_conv/corrmax)*255; %normalize, peak=always 255
        %Find the correlation max, at 255
        [y,x] = find(result_conv==255,1);
        if ~isempty(y) && ~isempty(x)
            try
                if subpixfinder==1
                    [vector,F(ivec)] = SUBPIXGAUSS (result_conv,x,y);
                elseif subpixfinder==2
                    [vector,F(ivec)] = SUBPIX2DGAUSS (result_conv,x,y);
                end
                sum_square=sum(sum(image1_crop.*image1_crop));
                ctable(ivec)=corrmax/sum_square;% correlation value
%                 if vector(1)>shiftx+isx2-ibx2+subpixfinder || vector(2)>shifty+isy2-iby2+subpixfinder
%                     F(ivec)=-2;%vector reaches the border of the search zone
%                 end
            catch ME
                vector=[0 0]; %if something goes wrong with cross correlation.....
                F(ivec)=3;
            end
        else
            vector=[0 0]; %if something goes wrong with cross correlation.....
            F(ivec)=3;
        end
        if testmask_ij
            F(ivec)=3;
        end
    end
    
    %Create the vector matrix x, y, u, v
    xtable(ivec)=iref+vector(1)/2;% convec flow (velocity taken at the point middle from imgae1 and 2)
    ytable(ivec)=jref+vector(2)/2;
    utable(ivec)=vector(1)+shiftx;
    vtable(ivec)=vector(2)+shifty;
end
result_conv=result_conv*corrmax/(255*sum_square);% keep the last correlation matrix for output


function [vector,F] = SUBPIXGAUSS (result_conv,x,y)
vector=[0 0]; %default
F=0;
[npy,npx]=size(result_conv);

% if (x <= (size(result_conv,1)-1)) && (y <= (size(result_conv,1)-1)) && (x >= 1) && (y >= 1)
    %the following 8 lines are copyright (c) 1998, Uri Shavit, Roi Gurka, Alex Liberzon, Technion – Israel Institute of Technology
    %http://urapiv.wordpress.com
    peaky = y;
    if y <= npy-1 && y >= 1
        f0 = log(result_conv(y,x));
        f1 = real(log(result_conv(y-1,x)));
        f2 = real(log(result_conv(y+1,x)));
        peaky = peaky+ (f1-f2)/(2*f1-4*f0+2*f2);
    else
        F=-2; % warning flag for vector truncated by the limited search box
    end
    peakx=x;
    if x <= npx-1 && x >= 1
        f0 = log(result_conv(y,x));
        f1 = real(log(result_conv(y,x-1)));
        f2 = real(log(result_conv(y,x+1)));
        peakx = peakx+ (f1-f2)/(2*f1-4*f0+2*f2);
    else
        F=-2; % warning flag for vector truncated by the limited search box
    end
    vector=[peakx-floor(npx/2)-1 peaky-floor(npy/2)-1];
% else
%     vector=[NaN NaN];
% end

function [vector,F] = SUBPIX2DGAUSS (result_conv,x,y)
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
    if abs(deltax)<1
        peakx=x+deltax;
    end
    if abs(deltay)<1
        peaky=y+deltay;
    end
end
vector=[peakx-floor(npx/2)-1 peaky-floor(npy/2)-1];
