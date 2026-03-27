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
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function DataOut=ima_remove_background_blocks(DataIn,Param)
%------------------------------------------------------------------------
%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    prompt = {'block size(pixels)'};
    dlg_title = 'get the block size (in pixels) used to calculate the local statistics';
    num_lines= 1;
    def     = { '100'};
    if isfield(Param,'TransformInput')&&isfield(Param.TransformInput,'BlockSize')
        def={num2str(Param.TransformInput.BlockSize)};
    end
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    DataOut.TransformInput.BlockSize=str2num(answer{1}); 
    return
end
if ~isfield(DataIn,'A')
    DataOut.Txt='remove_particles only valid for input images';
    return
end
if ~exist('imerode','file');
        DataOut.Txt='the function imerode from the image processing toolbox is needed';
    return
end

%--------------------------------------------------------- 
DataOut=DataIn;%default
nblock_y=2*Param.TransformInput.BlockSize;
nblock_x=2*Param.TransformInput.BlockSize;
[npy,npx]=size(DataIn.A);
[X,Y]=meshgrid(1:npx,1:npy);

%BACKGROUND LEVEL
Atype=class(DataIn.A);
A=double(DataIn.A);
%Backg=zeros(size(A));
%Aflagmin=sparse(imregionalmin(A));%Amin=1 for local image minima
%Amin=A.*Aflagmin;%values of A at local minima
% local background: find all the local minima in image subblocks
fctblock= inline('median(x(:))');
Backg=blkproc(A,[nblock_y nblock_x],fctblock);% take the median in  blocks
fctblock= inline('mean(x(:))');
B=imresize(Backg,size(A),'bilinear');% interpolate to the initial size image
DataOut.A=B;

% A=(A-B);%substract background
% AMean=blkproc(A,[nblock_y nblock_x],fctblock);% take the mean in  blocks
% fctblock= inline('var(x(:))');
% AVar=blkproc(A,[nblock_y nblock_x],fctblock);% take the mean in  blocks
% Avalue=AVar./AMean;% typical value of particle luminosity
% Avalue=imresize(Avalue,size(A),'bilinear');% interpolate to the initial size image
% DataOut.A=uint16(1000*tanh(A./(2*Avalue)));
%Bmin=blkproc(Aflagmin,[nblock_y nblock_x],sumblock);% find the number of minima in blocks
%Backg=Backg./Bmin; % find the average of minima in blocks




