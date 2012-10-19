function DataOut=remove_background(DataIn)
%-----------------------------------------------
%% set GUI config: no action defined
DataOut=[];  %default  output field
if strcmp(DataIn,'*')
    return
end

%parameters
threshold=200
nblock_x=30;%size of image subblocks for analysis
nblock_y=30;
%---------------------------------------------------------
DataOut=DataIn;%default

%BACKGROUND LEVEL
Atype=class(DataIn.A);
A=double(DataIn.A);
Backg=zeros(size(A));
Aflagmin=sparse(imregionalmin(A));%Amin=1 for local image minima
Amin=A.*Aflagmin;%values of A at local minima
% local background: find all the local minima in image subblocks
sumblock= inline('sum(sum(x(:)))');
Backg=blkproc(Amin,[nblock_y nblock_x],sumblock);% take the sum in  blocks
Bmin=blkproc(Aflagmin,[nblock_y nblock_x],sumblock);% find the number of minima in blocks
Backg=Backg./Bmin; % find the average of minima in blocks
B=imresize(Backg,size(A),'bilinear');% interpolate to the initial size image
ImPart=(A-B);
DataOut.A=ImPart.*(ImPart>threshold);
DataOut.A=feval(Atype,DataOut.A);