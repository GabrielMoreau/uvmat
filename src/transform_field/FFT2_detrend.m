% 'FFT2_detrend': calculate the 2D spectrum of the input scalar or image after removing the linear trend
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

function DataOut=FFT2_detrend(DataIn)
%------------------------------------------------------------------------
DataOut=[];
if strcmp(DataIn,'*')   
    DataOut.InputFieldType='scalar';
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%
[CellInfo,NbDim,errormsg]=find_field_cells(DataIn);% detect the input fields
if ~isempty(errormsg)
    DataOut.Txt=errormsg;
    return
end
DataOut.ListVarName={};
DataOut.VarDimName={};
for ilist=1:numel(CellInfo)
    if NbDim(ilist)==2 && numel(CellInfo{ilist}.CoordIndex)==2 % field with structured 2D coordinates
        %process scalar
        ivar=CellInfo{ilist}.VarIndex_scalar(1);
        VarName=DataIn.ListVarName{ivar};% name o the scalar field
        z=double(DataIn.(VarName));% transform integer input to double real
        z(isnan(z))=0;% set NaN values to 0
        [npy,npx]=size(z);
        
        %process coordinates
        CoordName=DataIn.ListVarName(CellInfo{ilist}.CoordIndex);
        x1 = linspace(DataIn.(CoordName{2})(1),DataIn.(CoordName{2})(end),npx);
        y1 =linspace(DataIn.(CoordName{1})(1),DataIn.(CoordName{1})(end),npy);
        [x,y] = meshgrid(x1,y1);% 2D grid of coordinates
        
        % prepare the grid of wave vectors
        delta_x = x1(2) - x1(1); delta_y = y1(2) - y1(1);
        Nx = length(x1); Ny = length(y1);
        Nxa = 1:Nx; Nya = 1:Ny;
        ssx = find(Nxa<Nx/2); ssy = find(Nya<Ny/2);
        Nxa(Nx-ssx+1) = -Nxa(ssx)+1; Nya(Ny-ssy+1) = -Nya(ssy)+1;
        [Nxa, Ix] = sort(Nxa); [Nya, Iy] = sort(Nya);         
        kx1 = (2*pi/delta_x/Nx)*(Nxa-1); ky1 = (2*pi/delta_y/Ny)*(Nya-1);
        ss = find(ky1>=0); ky1 = ky1(ss);
        [kx,ky] = meshgrid(kx1,ky1);
        DataOut.(CoordName{2}) = kx1; DataOut.(CoordName{1}) = ky1;
        if isfield(DataIn,'CoordUnit')
            DataOut.CoordUnit=[DataIn.CoordUnit '^{-1}'];%unit of wave vectors
            DataOut.ListGlobalAttribute={'CoordUnit'};
        end
        
        % get the coeff to calulate the linear trend
        coeff(1,1) = sum(sum(x.^2)); coeff(1,2) = sum(sum(x.*y)); coeff(1,3) = sum(sum(x));
        coeff(2,1) = sum(sum(x.*y)); coeff(2,2) = sum(sum(y.^2)); coeff(2,3) = sum(sum(y));
        coeff(3,1) = sum(sum(x)); coeff(3,2) = sum(sum(y)); coeff(3,3) = length(x1)*length(y1);
        rhs(1) = sum(sum(x.*z)); rhs(2) = sum(sum(y.*z)); rhs(3) = sum(sum(z));
       % lin_coeff = inv(coeff)*rhs';
       lin_coeff = coeff\rhs';
        lin_trend = lin_coeff(1)*x + lin_coeff(2)*y + lin_coeff(3);
        z2 = z - lin_trend;% substract the linear trend to the input field
        
        spec2 = abs(fft2(z2)).^2;% get spectrum as squared of fft modulus
        spec2 = spec2(Iy,Ix);
        spec2 = spec2(ss,:);
        %DataOut.(VarName) = log10(spec2);% take the log10 of spectrum
        DataOut.(VarName) = spec2;
%         spec_sum=sum(sum(spec2));
%         kx_mean=sum(sum(spec2.*kx))/spec_sum;
%         ky_mean=sum(sum(spec2.*ky))/spec_sum;
%         theta=atand(ky_mean/kx_mean);
%         lambda=2*pi/(sqrt(kx_mean*kx_mean+ky_mean*ky_mean));
        
        DataOut.ListVarName=[CoordName {VarName}];%list of variables
        DataOut.VarDimName=[CoordName {CoordName}];%list of dimensions for variables
        DataOut.VarAttribute{1}.Role='coord_y';
        DataOut.VarAttribute{2}.Role='coord_x';
        DataOut.VarAttribute{3}.Role='scalar';
        break
    end
end
  


