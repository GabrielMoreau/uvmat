% 'ima_filter': low-pass filter of an image or other 2D fields defined on a regular grid
% the size of the filtering window in x and y is interactivement defined

%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input and parameters %%%%
% OUTPUT:
% DataOut:   output field structure
%
%INPUT:
% DataIn:  input field structure
%
% Param: matlab structure whose field Param.TransformInput contains the filter parameters
% DataIn_1: variables possibly introduced as a second input field
%-----------------------------------

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

function DataOut=ima_filter(DataIn,Param,DataIn_1)

%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    prompt = {'npx';'npy'};
    dlg_title = 'get the filter size in x and y';
    num_lines= 2;
    def     = { '20';'20'};
    if isfield(Param,'TransformInput')&&isfield(Param.TransformInput,'FilterBoxSize_x')&&...
            isfield(Param.TransformInput,'FilterBoxSize_y')
        def={num2str(Param.TransformInput.FilterBoxSize_x);num2str(Param.TransformInput.FilterBoxSize_y)};
    end
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    DataOut.TransformInput.FilterBoxSize_x=str2num(answer{1}); %size of the filtering window
    DataOut.TransformInput.FilterBoxSize_y=str2num(answer{2}); %size of the filtering window
    return
end

DataOut=DataIn; %default

%definition of the cos shape matrix filter
ix=1/2-Param.TransformInput.FilterBoxSize_x/2:-1/2+Param.TransformInput.FilterBoxSize_x/2;%
iy=1/2-Param.TransformInput.FilterBoxSize_y/2:-1/2+Param.TransformInput.FilterBoxSize_y/2;%
%del=np/3;
%fct=exp(-(ix/del).^2);
fct2_x=cos(ix/((Param.TransformInput.FilterBoxSize_x-1)/2)*pi/2);
fct2_y=cos(iy/((Param.TransformInput.FilterBoxSize_y-1)/2)*pi/2);
%Mfiltre=(ones(5,5)/5^2);
Mfiltre=fct2_y'*fct2_x;
Mfiltre=Mfiltre/(sum(sum(Mfiltre)));%normalize filter

[CellInfo,NbDim,errormsg]=find_field_cells(DataIn)
for icell=1:numel(CellInfo)
    if isfield(CellInfo{icell},'CoordType')&& strcmp(CellInfo{icell}.CoordType,'grid')
        for ivar=1:numel(CellInfo{icell}.VarIndex)
            VarName=DataIn.ListVarName{CellInfo{icell}.VarIndex(ivar)};
            Atype=class(DataIn.(VarName));% detect integer 8 or 16 bits
            if numel(size(DataIn.(VarName)))==3
                DataOut.(VarName)=filter2(Mfiltre,sum(DataIn.(VarName),3));%filter the input image, after summation on the color component (for color images)
                DataOut.(VarName)=uint16(DataOut.(VarName)); %transform to 16 bit images
            else
                DataOut.(VarName)=filter2(Mfiltre,DataIn.(VarName));
                DataOut.(VarName)=feval(Atype,DataOut.(VarName));%transform to the initial image format
            end
        end
    end
end
if exist('DataIn_1','var')
    [CellInfo,NbDim,errormsg]=find_field_cells(DataIn_1);
    for icell=1:numel(CellInfo)
        if isfield(CellInfo{icell},'CoordType')&& strcmp(CellInfo{icell}.CoordType,'grid')
            for ivar=1:numel(CellInfo{icell}.VarIndex)
                VarName=DataIn_1.ListVarName{CellInfo{icell}.VarIndex(ivar)};
                Atype=class(DataIn_1.(VarName));% detect integer 8 or 16 bits
                if numel(size(DataIn_1.(VarName)))==3
                    DataOut.(VarName)=filter2(Mfiltre,sum(DataIn_1.(VarName),3));%filter the input image, after summation on the color component (for color images)
                    DataOut.(VarName)=uint16(DataOut.(VarName)); %transform to 16 bit images
                else
                    DataOut.(VarName)=filter2(Mfiltre,DataIn_1.(VarName));
                    DataOut.(VarName)=feval(Atype,DataOut.(VarName));%transform to the initial image format
                end
            end
        end
    end
end

 
