%--------------------------------------------------------------------------
%  'civ': key function  for image correlations (called by series/cvi_series.m)
% function [xtable ytable utable vtable typevector] = civ (image1,image2,ibx,iby step, subpixfinder, mask, roi)
%
% OUTPUT:
% xtable: set of x coordinates
% ytable: set of y coordinates
% utable: set of u displacements (along x)
% vtable: set of v displacements (along y)
% ctable: max image correlation for each vector
% typevector: set of flags, =1 for good, =0 for NaN vectors
%
%INPUT:
% par_civ: structure of input parameters, with fields:
%  .ImageA: first image for correlation (matrix)
%  .ImageB: second image for correlation(matrix)
%  .CorrBoxSize: 1,2 vector giving the size of the correlation box in x and y
%  .SearchBoxSize:  1,2 vector giving the size of the search box in x and y
%  .SearchBoxShift: 1,2 vector or 2 column matrix (for civ2) giving the shift of the search box in x and y
%  .CorrSmooth: =1 or 2 determines the choice of the sub-pixel determination of the correlation max
%  .ImageWidth: nb of pixels of the image in x
%  .Dx, Dy: mesh for the PIV calculation
%  .Grid: grid giving the PIV calculation points (alternative to .Dx .Dy): centres of the correlation boxes in Image A
%  .Mask: name of a mask file or mask image matrix itself
%  .MinIma: thresholds for image luminosity
%  .MaxIma
%  .CheckDeformation=1 for subpixel interpolation and image deformation (linear transform)
%  .DUDX: matrix of deformation obtained from patch at each grid point
%  .DUDY
%  .DVDX:
%  .DVDY

function [xtable,ytable,utable,vtable,ctable,FF,result_conv,errormsg] = civ (par_civ)

%% check input images
par_civ.ImageA=sum(double(par_civ.ImageA),3);%sum over rgb component for color images
par_civ.ImageB=sum(double(par_civ.ImageB),3);
[npy_ima,npx_ima]=size(par_civ.ImageA);
if ~isequal(size(par_civ.ImageB),[npy_ima npx_ima])
    errormsg='image pair with unequal size';
    return
end

%% prepare measurement grid if not given as input
if ~isfield(par_civ,'Grid')% grid points defining central positions of the sub-images in image A
    nbinterv_x=floor((npx_ima-1)/par_civ.Dx);
    gridlength_x=nbinterv_x*par_civ.Dx;
    minix=ceil((npx_ima-gridlength_x)/2);
    nbinterv_y=floor((npy_ima-1)/par_civ.Dy);
    gridlength_y=nbinterv_y*par_civ.Dy;
    miniy=ceil((npy_ima-gridlength_y)/2);
    [GridX,GridY]=meshgrid(minix:par_civ.Dx:npx_ima-1,miniy:par_civ.Dy:npy_ima-1);
    par_civ.Grid(:,1)=reshape(GridX,[],1);
    par_civ.Grid(:,2)=reshape(GridY,[],1);% increases with array index
end
nbvec=size(par_civ.Grid,1);


%% prepare correlation and search boxes
CorrBoxSizeX=par_civ.CorrBoxSize(:,1);
CorrBoxSizeY=par_civ.CorrBoxSize(:,2);
if size(par_civ.CorrBoxSize,1)==1
    CorrBoxSizeX=par_civ.CorrBoxSize(1)*ones(nbvec,1);
    CorrBoxSizeY=par_civ.CorrBoxSize(2)*ones(nbvec,1);
end

shiftx=par_civ.SearchBoxShift(:,1);%use the input shift estimate, rounded to the next integer value
shifty=-par_civ.SearchBoxShift(:,2);% sign minus because image j index increases when y decreases
if numel(shiftx)==1% case of a unique shift for the whole field( civ1)
    shiftx=shiftx*ones(nbvec,1);
    shifty=shifty*ones(nbvec,1);
end

%% shift the grid by half the expected displacement to get the velocity closer to the initial grid
par_civ.Grid(:,1)=par_civ.Grid(:,1)-shiftx/2;
par_civ.Grid(:,2)=par_civ.Grid(:,2)+shifty/2;

%% Array initialisation and default output  if par_civ.CorrSmooth=0 (just the grid calculated, no civ computation)
xtable=round(par_civ.Grid(:,1)+0.5)-0.5;
ytable=round(npy_ima-par_civ.Grid(:,2)+0.5)-0.5;% y index corresponding to the position in image coordinates
shiftx=round(shiftx);
shifty=round(shifty);
utable=shiftx;%zeros(nbvec,1);
vtable=shifty;%zeros(nbvec,1);
ctable=zeros(nbvec,1);
FF=zeros(nbvec,1);
result_conv=[];
errormsg='';

%% prepare mask
if isfield(par_civ,'Mask') && ~isempty(par_civ.Mask)
    if strcmp(par_civ.Mask,'all')
        return    % get the grid only, no civ calculation
    elseif ischar(par_civ.Mask)
        par_civ.Mask=imread(par_civ.Mask);% read the mask if not allready done
    end
end
check_MinIma=isfield(par_civ,'MinIma');% test for image luminosity threshold
check_MaxIma=isfield(par_civ,'MaxIma') && ~isempty(par_civ.MaxIma);

%% Apply mask
% Convention for mask, IDEAS NOT IMPLEMENTED 
% mask >200 : velocity calculated
%  200 >=mask>150;velocity not calculated, interpolation allowed (bad spots)
% 150>=mask >100: velocity not calculated, nor interpolated
%  100>=mask> 20: velocity not calculated, impermeable (no flux through mask boundaries)
%  20>=mask: velocity=0
checkmask=0;
MinA=min(min(par_civ.ImageA));
if isfield(par_civ,'Mask') && ~isempty(par_civ.Mask)
    checkmask=1;
    if ~isequal(size(par_civ.Mask),[npy_ima npx_ima])
        errormsg='mask must be an image with the same size as the images';
        return
    end
    check_undefined=(par_civ.Mask<200 & par_civ.Mask>=20 );
end

%% compute image correlations: MAINLOOP on velocity vectors
sum_square=1;% default
mesh=1;% default
CheckDeformation=isfield(par_civ,'CheckDeformation')&& par_civ.CheckDeformation==1;
if CheckDeformation
    mesh=0.25;%mesh in pixels for subpixel image interpolation (x 4 in each direction)
    par_civ.CorrSmooth=2;% use SUBPIX2DGAUSS (take into account more points near the max)
end

if par_civ.CorrSmooth~=0 % par_civ.CorrSmooth=0 implies no civ computation (just input image and grid points given)
    for ivec=1:nbvec
        iref=round(par_civ.Grid(ivec,1)+0.5);% xindex on the image A for the middle of the correlation box
        jref=round(npy_ima-par_civ.Grid(ivec,2)+0.5);%  j index  for the middle of the correlation box in the image A
        FF(ivec)=0;
        ibx2=floor(CorrBoxSizeX(ivec)/2);
        iby2=floor(CorrBoxSizeY(ivec)/2);
        isx2=ibx2+ceil(par_civ.SearchRange(1));
        isy2=iby2+ceil(par_civ.SearchRange(2));
        subrange1_x=iref-ibx2:iref+ibx2;% x indices defining the first subimage
        subrange1_y=jref-iby2:jref+iby2;% y indices defining the first subimage
        subrange2_x=iref+shiftx(ivec)-isx2:iref+shiftx(ivec)+isx2;%x indices defining the second subimage
        subrange2_y=jref+shifty(ivec)-isy2:jref+shifty(ivec)+isy2;%y indices defining the second subimage
        image1_crop=MinA*ones(numel(subrange1_y),numel(subrange1_x));% default value=min of image A
        image2_crop=MinA*ones(numel(subrange2_y),numel(subrange2_x));% default value=min of image A
        check1_x=subrange1_x>=1 & subrange1_x<=npx_ima;% check which points in the subimage 1 are contained in the initial image 1
        check1_y=subrange1_y>=1 & subrange1_y<=npy_ima;
        check2_x=subrange2_x>=1 & subrange2_x<=npx_ima;% check which points in the subimage 2 are contained in the initial image 2
        check2_y=subrange2_y>=1 & subrange2_y<=npy_ima;
        image1_crop(check1_y,check1_x)=par_civ.ImageA(subrange1_y(check1_y),subrange1_x(check1_x));%extract a subimage (correlation box) from image A
        image2_crop(check2_y,check2_x)=par_civ.ImageB(subrange2_y(check2_y),subrange2_x(check2_x));%extract a larger subimage (search box) from image B
        if checkmask
            mask1_crop=ones(numel(subrange1_y),numel(subrange1_x));% default value=1 for mask
            mask2_crop=ones(numel(subrange2_y),numel(subrange2_x));% default value=1 for mask
            mask1_crop(check1_y,check1_x)=check_undefined(subrange1_y(check1_y),subrange1_x(check1_x));%extract a mask subimage (correlation box) from image A
            mask2_crop(check2_y,check2_x)=check_undefined(subrange2_y(check2_y),subrange2_x(check2_x));%extract a mask subimage (search box) from image B
            sizemask=sum(sum(mask1_crop))/(numel(subrange1_y)*numel(subrange1_x));%size of the masked part relative to the correlation sub-image
            if sizemask > 1/2% eliminate point if more than half of the correlation box is masked
                FF(ivec)=1; %
                utable(ivec)=NaN;
                vtable(ivec)=NaN;
            else
                image1_crop=image1_crop.*~mask1_crop;% put to zero the masked pixels (mask1_crop='true'=1)
                image2_crop=image2_crop.*~mask2_crop;
                image1_mean=mean(mean(image1_crop))/(1-sizemask);
                image2_mean=mean(mean(image2_crop))/(1-sizemask);
            end
        else
            image1_mean=mean(mean(image1_crop));
            image2_mean=mean(mean(image2_crop));
        end
        %threshold on image minimum
        if FF(ivec)==0
            if check_MinIma && (image1_mean < par_civ.MinIma || image2_mean < par_civ.MinIma)
                FF(ivec)=1;
                %threshold on image maximum
            elseif check_MaxIma && (image1_mean > par_civ.MaxIma || image2_mean > par_civ.MaxIma)
                FF(ivec)=1;
            end
            if FF(ivec)==1
                utable(ivec)=NaN;
                vtable(ivec)=NaN;
            else
                %mask
                if checkmask
                    image1_crop=(image1_crop-image1_mean).*~mask1_crop;%substract the mean, put to zero the masked parts
                    image2_crop=(image2_crop-image2_mean).*~mask2_crop;
                else
                    image1_crop=(image1_crop-image1_mean);
                    image2_crop=(image2_crop-image2_mean);
                end
                %deformation
                if CheckDeformation
                    xi=(1:mesh:size(image1_crop,2));
                    yi=(1:mesh:size(image1_crop,1))';
                    [XI,YI]=meshgrid(xi-ceil(size(image1_crop,2)/2),yi-ceil(size(image1_crop,1)/2));
                    XIant=XI-par_civ.DUDX(ivec)*XI+par_civ.DUDY(ivec)*YI+ceil(size(image1_crop,2)/2);
                    YIant=YI+par_civ.DVDX(ivec)*XI-par_civ.DVDY(ivec)*YI+ceil(size(image1_crop,1)/2);
                    image1_crop=interp2(image1_crop,XIant,YIant);
                    image1_crop(isnan(image1_crop))=0;
                    xi=(1:mesh:size(image2_crop,2));
                    yi=(1:mesh:size(image2_crop,1))';
                    image2_crop=interp2(image2_crop,xi,yi,'*spline');
                    image2_crop(isnan(image2_crop))=0;
                end
                sum_square=sum(sum(image1_crop.*image1_crop));
                %reference: Oliver Pust, PIV: Direct Cross-Correlation
                %%%%%% correlation calculation
                result_conv= conv2(image2_crop,flip(flip(image1_crop,2),1),'valid');
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                corrmax= max(max(result_conv));
                
                %result_conv=(result_conv/corrmax); %normalize, peak=always 255
                %Find the correlation max, at 255
                [y,x] = find(result_conv==corrmax,1);
                subimage2_crop=image2_crop(y:y+2*iby2/mesh,x:x+2*ibx2/mesh);%subimage of image 2 corresponding to the optimum displacement of first image
                sum_square=sum_square*sum(sum(subimage2_crop.*subimage2_crop));% product of variances of image 1 and 2
                sum_square=sqrt(sum_square);% srt of the variance product to normalise correlation
                if ~isempty(y) && ~isempty(x)
                    try
                        if par_civ.CorrSmooth==1
                            [vector,FF(ivec)] = SUBPIXGAUSS (result_conv,x,y);
                        elseif par_civ.CorrSmooth==2
                            [vector,FF(ivec)] = SUBPIX2DGAUSS (result_conv,x,y);
                        else
                            [vector,FF(ivec)] = quadr_fit(result_conv,x,y);
                        end
                        utable(ivec)=vector(1)*mesh+shiftx(ivec);
                        vtable(ivec)=-(vector(2)*mesh+shifty(ivec));
                        xtable(ivec)=iref+utable(ivec)/2-0.5;% convec flow (velocity taken at the point middle from imgae 1 and 2)
                        ytable(ivec)=jref+vtable(ivec)/2-0.5;% and position of pixel 1=0.5 (convention for image coordinates=0 at the edge)
                        iref=round(xtable(ivec)+0.5);% nearest image index for the middle of the vector
                        jref=round(ytable(ivec)+0.5);
                        % eliminate vectors located in the mask
                        if  checkmask && (iref<1 || jref<1 ||iref>npx_ima || jref>npy_ima ||( par_civ.Mask(jref,iref)<200 && par_civ.Mask(jref,iref)>=100))
                            utable(ivec)=0;
                            vtable(ivec)=0;
                            FF(ivec)=1;
                        end
                        ctable(ivec)=corrmax/sum_square;% correlation value
                    catch ME
                        FF(ivec)=1;
                        disp(ME.message)
                    end
                else
                    FF(ivec)=1;
                end
            end
        end
    end
end
ytable=npy_ima-ytable+1;%reverse from j index to image coordinate y
result_conv=result_conv/sum_square;% keep the last correlation matrix for output



%------------------------------------------------------------------------
% --- Find the maximum of the correlation function with subpixel resolution
% make a fit with a gaussian curve from the three correlation values across the max, along each direction.
% OUPUT:
% vector = optimum displacement vector with subpixel correction
% FF =flag: =0 OK
%           =1 , max too close to the edge of the search box (1 pixel margin)
% INPUT:
% result_conv: 2D correlation fct
% x,y: position of the maximum correlation at integer values

function [vector,FF] = SUBPIXGAUSS (result_conv,x,y)
%------------------------------------------------------------------------
% vector=[0 0]; %default
FF=true;% error flag for vector truncated by the limited search box
[npy,npx]=size(result_conv);

peaky = y; peakx=x;
if y < npy && y > 1 && x < npx-1 && x > 1
    FF=false; % no error by the limited search box
    max_conv=result_conv(y,x);% max correlation
    %peak2noise= max(4,max_conv/std(reshape(result_conv,1,[])));% ratio of max conv to standard deviation of correlations (estiamtion of noise level), set to value 4 if it is too low
    peak2noise=100;% TODO: make this threshold more precise, depending on the image noise
    result_conv=result_conv*peak2noise/max_conv;% renormalise the correlation with respect to the noise
    result_conv(result_conv<1)=1; %set to 1 correlation values smaller than 1  (=0 by discretisation, to avoid divergence in the log)
    
    f0 = log(result_conv(y,x));
    f1 = log(result_conv(y-1,x));
    f2 = log(result_conv(y+1,x));
    peaky = peaky+ (f1-f2)/(2*f1-4*f0+2*f2);
    f1 = log(result_conv(y,x-1));
    f2 = log(result_conv(y,x+1));
    peakx = peakx+ (f1-f2)/(2*f1-4*f0+2*f2);
end

vector=[peakx-floor(npx/2)-1 peaky-floor(npy/2)-1];

%------------------------------------------------------------------------
% --- Find the maximum of the correlation function after interpolation
function [vector,FF] = SUBPIX2DGAUSS (result_conv,x,y)
%------------------------------------------------------------------------
% vector=[0 0]; %default
FF=true;
peaky=y;
peakx=x;
[npy,npx]=size(result_conv);
if (x < npx) && (y < npy) && (x > 1) && (y > 1)
    FF=false;
max_conv=result_conv(y,x);% max correlation
    peak2noise= max(4,max_conv/std(reshape(result_conv,1,[])));% ratio of max conv to standard deviation of correlations (estiamtion of noise level), set to value 4 if it is too low
    result_conv=result_conv*peak2noise/max_conv;% renormalise the correlation with respect to the noise 
    result_conv(result_conv<1)=1; %set to 1 correlation values smaller than 1  (=0 by discretisation, to avoid divergence in the log)
    for i=-1:1
        for j=-1:1
  %following 15 lines based on  H. Nobach and M. Honkanen (2005)
  % Two-dimensional Gaussian regression for sub-pixel displacement
  % estimation in particle image velocimetry or particle position
  % estimation in particle tracking velocimetry
  % Experiments in Fluids (2005) 38: 511-515
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
    deltax=(c11*c01-2*c10*c02)/(4*c20*c02-c11*c11);
    deltay=(c11*c10-2*c01*c20)/(4*c20*c02-c11*c11);
    if abs(deltax)<1
        peakx=x+deltax;
    end
    if abs(deltay)<1
        peaky=y+deltay;
    end
end
vector=[peakx-floor(npx/2)-1 peaky-floor(npy/2)-1];

%------------------------------------------------------------------------
% --- Find the maximum of the correlation function after quadratic interpolation
function [vector,F] = quadr_fit(result_conv,x,y)
[npy,npx]=size(result_conv);
if x<4 || y<4 || npx-x<4 ||npy-y <4
    F=1;
    vector=[x y];
else
    F=0;
    x_ind=x-4:x+4;
    y_ind=y-4:y+4;
    x_vec=0.25*(x_ind-x);
    y_vec=0.25*(y_ind-y);
    [X,Y]=meshgrid(x_vec,y_vec);
    coord=[reshape(X,[],1) reshape(Y,[],1)];
    result_conv=reshape(result_conv(y_ind,x_ind),[],1);
    
    
    % n=numel(X);
    % x=[X Y];
    % X=X-0.5;
    % Y=Y+0.5;
    % y = (X.*X+2*Y.*Y+X.*Y+6) + 0.1*rand(n,1);
    p = polyfitn(coord,result_conv,2);
    A(1,1)=2*p.Coefficients(1);
    A(1,2)=p.Coefficients(2);
    A(2,1)=p.Coefficients(2);
    A(2,2)=2*p.Coefficients(4);
    vector=[x y]'-A\[p.Coefficients(3) p.Coefficients(5)]';
    vector=vector'-[floor(npx/2) floor(npy/2)]-1 ;
    % zg = polyvaln(p,coord);
    % figure
    % surf(x_vec,y_vec,reshape(zg,9,9))
    % hold on
    % plot3(X,Y,reshape(result_conv,9,9),'o')
    % hold off
end


