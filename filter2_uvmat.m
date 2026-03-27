% Apply a sliding average with ny*nx points excluding NaN and outerbound values
function Afilt=filter2_omitnan(npx,npy,A)
Afilt=A;%default
npy2=ceil(npy/2);
npx2=ceil(npx/2);
for iline=1:size(A,2)
    for icolumn=1:size(A,1)
        lowboundy=max(icolumn-npy2,1);
        trunc_y1=lowboundy-icolumn+npy2;%nbre of elements removed low
        highboundy=min(icolumn+npy2,size(A,1));
        trunc_y2=icolumn+npy2-highboundy;%nbre of elements removed high
        lowboundx=max(iline-npx2,1);
        trunc_x1=lowboundx-iline+npx2;%nbre of elements removed low
        highboundx=min(iline+npx2,size(A,2));
        trunc_x2=iline+npx2-highboundx;%nbre of elements removed high
        Asub=A(lowboundy:highboundy,lowboundx:highboundx);%nbre of elements removed high
        Afilt(icolumn,iline)=mean(Asub,'all','omitnan');
    end
end