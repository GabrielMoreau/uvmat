% 'ima_remove_background': removes backgound from an image (using the local minimum)
% requires the Matlab image processing toolbox
%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input %%%%
% OUTPUT: 
% DataOut:   output field structure 
%
%INPUT:
% DataIn:  first input field structure

%=======================================================================
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function DataOut=remove_background(DataIn)
%------------------------------------------------------------------------
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
