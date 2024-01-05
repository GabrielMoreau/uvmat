% 'ima_edge_detection': find edges 

%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input and parameters %%%%
% OUTPUT: 
% Data:   output field structure 
%
%INPUT:
% DataIn:  input field structure
% Param: matlab structure whose field Param.TransformInput contains the filter parameters
%-----------------------------------

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function Data=ima_edge_detection(Data,Param,Data_1)

%% request input parameters
if isfield(Data,'Action') && isfield(Data.Action,'RUN') && isequal(Data.Action.RUN,0)
    prompt = {'npx';'npy';'threshold'};
    dlg_title = 'get the filter size in x and y';
    num_lines= 3;
    def     = { '50';'50';'0.3'};
    if isfield(Param,'TransformInput')&&isfield(Param.TransformInput,'FilterBoxSize_x')&&...
            isfield(Param.TransformInput,'FilterBoxSize_y')&&isfield(Param.TransformInput,'LumThreshold')
        def={num2str(Param.TransformInput.FilterBoxSize_x);num2str(Param.TransformInput.FilterBoxSize_y);num2str(Param.TransformInput.LumThreshold)};
    end
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    Data.TransformInput.FilterBoxSize_x=str2num(answer{1}); %size of the filtering window
    Data.TransformInput.FilterBoxSize_y=str2num(answer{2}); %size of the filtering window
    Data.TransformInput.LumThreshold=str2num(answer{3}); %size of the filtering window
    return
end


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

Afilt=filter2(Mfiltre,Data.A);% smooth the image, excluding the edges (spurious reflexions)

    %Afilt=filter2(Mfiltre,Data.A(100:end-100,100:end-100));% smooth the image, excluding the edges (spurious reflexions)
  %Data.A= double(Data.A)-Afilt;


    
    
%     
    Amax=max(max(Afilt));
    Amin=min(min(Afilt));
%     Data.A( Data_1.A(100:end-100,100:end-100)==100)=(Amin+Amax)/2;

 
 
    Athreshold=(Amin+Amax)*Param.TransformInput.LumThreshold;
%     
%     Data.A=zeros(size(Data.A,1),size(Data.A,2),3);
    Data.A=(Data.A>Athreshold);%transform to the initial image format
%     Data.A(:,:,1)=Data.A;%transform to the initial image format, red
STATS = regionprops(Data.A, 'FilledArea','MinorAxisLength','MajorAxisLength','PixelIdxList');
Area=zeros(size(STATS));
for iobj=1:numel(STATS)
    Area(iobj)=STATS(iobj).FilledArea;
end
[Area, main_obj]=max(Area)
    MajorAxisLength=STATS(main_obj).MajorAxisLength;
    MinorAxisLength=STATS(main_obj).MinorAxisLength;
for iobj=1:numel(STATS)
    if iobj~=main_obj
    Data.A(STATS(iobj).PixelIdxList)=0;
    end
end

Data.A=Amax*Data.A;
 
