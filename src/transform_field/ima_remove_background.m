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
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function DataOut=remove_background(DataIn,Param)
%------------------------------------------------------------------------
%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    prompt = {'radius'};
    dlg_title = 'get the disk radius (pixels) used to calculate the regional minimum';
    num_lines= 1;
    def     = { '4'};
    if isfield(Param,'TransformInput')&&isfield(Param.TransformInput,'DiskRadius')
        def={num2str(Param.TransformInput.DiskRadius)};
    end
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    DataOut.TransformInput.DiskRadius=str2num(answer{1}); 
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

SE=strel('disk',Param.TransformInput.DiskRadius);
%--------------------------------------------------------- 
DataOut=DataIn;%default

[npy,npx]=size(DataIn.A);
[X,Y]=meshgrid(1:npx,1:npy);

%BACKGROUND LEVEL
Atype=class(DataIn.A);
Aerode=imerode(DataIn.A,SE);
Aflagmin=find(DataIn.A==Aerode);
Xmin=X(Aflagmin);
Ymin=Y(Aflagmin);
Amin=double(DataIn.A(Aflagmin));
F = TriScatteredInterp([Xmin Ymin], Amin);
DataOut.A=double(DataOut.A)-F(X,Y);
DataOut.A=feval(Atype,DataOut.A);

%BACKGROUND LEVEL
% Atype=class(DataIn.A);
% A=double(DataIn.A);
% Backg=zeros(size(A));
% Aflagmin=sparse(imregionalmin(A));%Amin=1 for local image minima
% Amin=A.*Aflagmin;%values of A at local minima
% % local background: find all the local minima in image subblocks
% sumblock= inline('sum(sum(x(:)))');
% Backg=blkproc(Amin,[nblock_y nblock_x],sumblock);% take the sum in  blocks
% Bmin=blkproc(Aflagmin,[nblock_y nblock_x],sumblock);% find the number of minima in blocks
% Backg=Backg./Bmin; % find the average of minima in blocks
% B=imresize(Backg,size(A),'bilinear');% interpolate to the initial size image
% ImPart=(A-B);
% DataOut.A=ImPart;
% %DataOut.A=ImPart.*(ImPart>threshold);
% DataOut.A=feval(Atype,DataOut.A);
