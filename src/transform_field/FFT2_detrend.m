% 'FFT2_detrend': calculate the 2D spectrum of the input scalar after removing the linear trend
%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input %%%%
% OUTPUT: 
% DataOut:   output field structure 
%
%INPUT:
% DataIn:  first input field structure

%=======================================================================
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function DataOut=FFT2_detrend(DataIn)
%------------------------------------------------------------------------
DataOut=[];
if strcmp(DataIn,'*')   
    DataOut.InputFieldType='scalar';
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%
[CellInfo,NbDim,errormsg]=find_field_cells(DataIn);
if ~isempty(errormsg)
    DataOut.Txt=errormsg;
    return
end
DataOut.ListVarName={};
DataOut.VarDimName={};
for ilist=1:numel(CellInfo)
    if NbDim(ilist)==2 && numel(CellInfo{ilist}.CoordIndex)==2 % field with structured coordinates
        %process coordinates
        CoordName=DataIn.ListVarName(CellInfo{ilist}.CoordIndex);
        x1 = DataIn.(CoordName{2}); y1 = DataIn.(CoordName{1});
        [x y] = meshgrid(x1,y1);
        coeff(1,1) = sum(sum(x.^2)); coeff(1,2) = sum(sum(x.*y)); coeff(1,3) = sum(sum(x));
        coeff(2,1) = sum(sum(x.*y)); coeff(2,2) = sum(sum(y.^2)); coeff(2,3) = sum(sum(y));
        coeff(3,1) = sum(sum(x)); coeff(3,2) = sum(sum(y)); coeff(3,3) = length(x1)*length(y1);
        delta_x = x1(2) - x1(1); delta_y = y1(2) - y1(1);
        Nx = length(x1); Ny = length(y1);
        Nxa = 1:Nx; Nya = 1:Ny;
        ssx = find(Nxa<Nx/2); ssy = find(Nya<Ny/2);
        Nxa(Nx-ssx+1) = -Nxa(ssx)+1; Nya(Ny-ssy+1) = -Nya(ssy)+1;
        [Nxa Ix] = sort(Nxa); [Nya Iy] = sort(Nya);
        kx1 = (2*pi/delta_x/Nx)*(Nxa-1); ky1 = (2*pi/delta_y/Ny)*(Nya-1);
        ss = find(ky1>=0); ky1 = ky1(ss);
        [kx ky] = meshgrid(kx1,ky1);
        DataOut.(CoordName{2}) = kx1; DataOut.(CoordName{1}) = ky1;
        if isfield(DataIn,'CoordUnit')
            DataOut.CoordUnit=[DataIn.CoordUnit '^{-1}'];
            DataOut.ListGlobalAttribute={'CoordUnit'};
        end
        %process scalar
        ivar=CellInfo{ilist}.VarIndex_scalar(1);
        VarName=DataIn.ListVarName{ivar};
        z=DataIn.(VarName);
        rhs(1) = sum(sum(x.*z)); rhs(2) = sum(sum(y.*z)); rhs(3) = sum(sum(z));
        lin_coeff = inv(coeff)*rhs';
        lin_trend = lin_coeff(1)*x + lin_coeff(2)*y + lin_coeff(3);
        z2 = z - lin_trend;
        spec2 = abs(fft2(z2)).^2;
        spec2 = spec2(Iy,Ix);
        spec2 = spec2(ss,:);
        %DataOut.(VarName) = log(spec2);
        DataOut.(VarName) = spec2;
        spec_sum=sum(sum(spec2));
        kx_mean=sum(sum(spec2.*kx))/spec_sum;
        ky_mean=sum(sum(spec2.*ky))/spec_sum;
        theta=atand(ky_mean/kx_mean);
        lambda=2*pi/(sqrt(kx_mean*kx_mean+ky_mean*ky_mean));
        
        DataOut.ListVarName=[CoordName {VarName}];%list of variables
        DataOut.VarDimName=[CoordName {CoordName}];%list of dimensions for variables
        break
    end
end
  


