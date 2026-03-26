%'set_col_vec': % sets the color code for vectors depending on a scalar and input parameters (used for plot_field)
%-----------------------------------------------------------------------
%function [colorlist,col_vec,minC,ColCode1,ColCode2,maxC]=set_col_vec(colcode,vec_C)
%-----------------------------------------------------------------------
%OUTPUT
%colorlist(nb,3); %list of nb colors
%col_vec, size=[length(vec_C),3)];%list of color indices corresponding to vec_C
%minC, maxC: min and max of vec_C
%ColCode1, ColCode2: absolute threshold in vec_C corresponding to colcode.ColCode1 and colcode.ColCode2
%
%INPUT
% colcode: struture setting the colorcode for vectors
%    colcode.CName: 'ima_cor','black','white',...
%    colcode.ColorCode ='black', 'white', 'rgb','brg', '64 colors','BuYlRd'
%    colcode.CheckFixVecColor =0; thresholds scaling relative to min and max, =1 fixed thresholds
%    colcode.MinVec; min
%    colcode.MaxVec; max
%    colcode.ColCode1: first threshold for rgb, relative to min (0) and max (1)
%    colcode.ColCode2: second threshold for rgb, relative to min (0) and max (1),
%    rmq: we need min <= ColCode1 <= ColCode2 <= max, otherwise
%    ColCode1 and ColCode2 are adjusted to the bounds
% vec_C: matlab vector representing the scalar setting the color

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

function [colorlist,col_vec,colcode_out]=set_col_vec(colcode,vec_C)
col_vec=ones(size(vec_C));%all vectors at color#1 by default

if ~isstruct(colcode),colcode=[];end
colcode_out=colcode;%default
if isempty(vec_C) || ~isnumeric(vec_C)
    colorlist=[0 0 1]; %blue
    return
end

%% uniform color plot
check_multicolors=0;
%default input parameters
if ~isfield(colcode,'ColorCode') || isempty(colcode.ColorCode)
    colorlist=[0 0 1]; %blue
else
    if strcmp(colcode.ColorCode,'black')% black vectors
        colorlist(1,:)=[0 0 0];%black
    elseif strcmp(colcode.ColorCode,'white')% white vectors
        colorlist(1,:)=[1 1 1];%white
    else
        check_multicolors=1;
    end
end

%% colored vectors
if check_multicolors
    if (isfield(colcode,'CheckFixVecColor') && isequal(colcode.CheckFixVecColor,1))
        minC=colcode.MinVec;
        maxC=colcode.MaxVec;
    else
        minC=min(vec_C);
        maxC=max(vec_C);
    end
    colcode_out.MinVec=minC;
    colcode_out.MaxVec=maxC;
    if strcmp(colcode.ColorCode,'rgb')|| strcmp(colcode.ColorCode,'bgr')% 3 color representation
        if  isfield(colcode,'ColCode1')
            colcode_out.ColCode1=colcode.ColCode1;
        else
            colcode_out.ColCode1=minC+(maxC-minC)/3;%default
        end
        if  isfield(colcode,'ColCode2')
            colcode_out.ColCode2=colcode.ColCode2;
        else
            colcode_out.ColCode2=minC+2*(maxC-minC)/3;%default
        end
        colorlist(2,:)=[0 1 0];%green
        col_vec(vec_C < colcode_out.ColCode1)=1;% vectors with vec_C smaller than ColCode1 set to the first color (r or b)
        col_vec((vec_C >= colcode_out.ColCode1) & (vec_C < colcode_out.ColCode2))=2;% select green vectors
        col_vec(vec_C >= colcode_out.ColCode2)=3;
        if strcmp(colcode.ColorCode,'rgb')
            colorlist(1,:)=[1 0 0];%red
            colorlist(3,:)=[0 0 1];%blue
        else
            colorlist(1,:)=[0 0 1];%blue
            colorlist(3,:)=[1 0 0];%red
        end
    else
        switch colcode.ColorCode
            case '64 colors'
        colorjet=jet;% ususal colormap from blue to red
            case 'BuYlRd'
            hh=load('BuYlRd.mat');
            colorjet=hh.BuYlRd;
        end
        sizlist=size(colorjet,1);
        indsel=ceil((sizlist(1)/64)*(1:64));
        colorlist(:,1)=colorjet(indsel,1);
        colorlist(:,2)=colorjet(indsel,2);
        colorlist(:,3)=colorjet(indsel,3);
        nblevel=size(colorlist,1);
        col2_1=maxC-minC;
        col_vec=1+floor(nblevel*(vec_C-minC)/col2_1);
        col_vec=col_vec.*(col_vec<= nblevel)+nblevel*(col_vec >nblevel);% take color #nblevel at saturation
        col_vec=col_vec.*(col_vec>= 1)+  (col_vec <1);% take color #1 for values below 1
    end
end
