% 'ima_filter': example of image transform with input parameters: low-pass filter of an image

%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input and parameters %%%%
% OUTPUT: 
% DataOut:   output field structure 
%
%INPUT:
% DataIn:  input field structure
% Param: matlab structure whose field Param.TransformInput contains the filter parameters
%-----------------------------------

%=======================================================================
% Copyright 2008-2016, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function DataOut=ima_filter(DataIn)

Origin_x=469;
DataOut=DataIn; %default
DataOut.A=

%definition of the cos shape matrix filter
ix=[1/2-Param.TransformInput.FilterBoxSize_x/2:-1/2+Param.TransformInput.FilterBoxSize_x/2];%
iy=[1/2-Param.TransformInput.FilterBoxSize_y/2:-1/2+Param.TransformInput.FilterBoxSize_y/2];%
%del=np/3;
%fct=exp(-(ix/del).^2);
fct2_x=cos(ix/((Param.TransformInput.FilterBoxSize_x-1)/2)*pi/2);
fct2_y=cos(iy/((Param.TransformInput.FilterBoxSize_y-1)/2)*pi/2);
%Mfiltre=(ones(5,5)/5^2);
Mfiltre=fct2_y'*fct2_x;
Mfiltre=Mfiltre/(sum(sum(Mfiltre)));%normalize filter

Atype=class(DataIn.A);% detect integer 8 or 16 bits
if numel(size(DataIn.A))==3
    DataOut.A=filter2(Mfiltre,sum(DataIn.A,3));%filter the input image, after summation on the color component (for color images)
    DataOut.A=uint16(DataOut.A); %transform to 16 bit images
else
    DataOut.A=filter2(Mfiltre,DataIn.A)
    DataOut.A=feval(Atype,DataOut.A);%transform to the initial image format
end
 
