% A matrix (npy,npx) to interpolate
%XIMA: matrix of non-integer x index values (npY,npX)
%YIMA: matrix of non-integer y index values (npY,npX), (with the same size as XIMA)
function A_out=interp2_uvmat(A,XIMA,YIMA)
npx=size(A,2);
npy=size(A,1);
npX=size(XIMA,2);
npY=size(XIMA,1)
XIMA=reshape(XIMA,1,npX*npY)+0.5;%indices corresponding to XIMA, reshaped in a matlab vector
YIMA=reshape(YIMA,1,npX*npY)+0.5;%indices corresponding to XIMA, reshaped in a matlab vector
X_delta=XIMA-floor(XIMA);%distance to the closest integer value
XIMA=floor(XIMA);%integer x index on the image
Y_delta=YIMA-floor(YIMA);%distance to the closest integer value
YIMA=floor(YIMA);%integer x index on the image        
flagin=(XIMA>=1 & XIMA<=npx-1 & YIMA >=1 & YIMA<=npy-1);%flagin=1 inside the original image
ind_in=find(flagin);%list of indices of XIndex for valid values of image indices (inside the original image) 
ind_out=find(~flagin);      
vec_A=double(reshape(A(:,:,1),1,npx*npy));%reshape the original image as a Matlab image vector
ICOMB=((XIMA-1)*npy+(npy+1-YIMA));%determine the indices in the image Matlab vector corresponding to XIMA and YIMA
ICOMB=ICOMB(flagin);%selection of the valid indices
X_delta=X_delta(ind_in);
Y_delta=Y_delta(ind_in);
A_out(ind_in)=(1-Y_delta).*(1-X_delta).*vec_A(ICOMB)+Y_delta.*(1-X_delta).*vec_A(ICOMB-1)+X_delta.*(1-Y_delta).*vec_A(ICOMB+npy)+X_delta.*Y_delta.*vec_A(ICOMB+npy-1);
A_out(ind_out)=zeros(size(ind_out));
A_out=reshape(A_out,npY,npX);%interpolated image 