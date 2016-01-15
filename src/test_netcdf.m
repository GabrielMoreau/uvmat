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

% program to test struct2nc for creating netcdf files
%% creating a simple netcdf file 
Data.ListVarName={'A'};% matrix A to record
Data.VarDimName={{'ny','nx'}};
[x,y] = meshgrid(-2:.2:2);
Data.A = x.*exp(-x.^2-y.^2);
err=struct2nc('test_1.nc',Data);
if isempty(err)
    display('test_1.nc written')
end
%
%% reading the simple netcdf file
DataOut=nc2struct('test_1.nc');
display( 'reading the simple netcdf file:')
display(DataOut)

%% writing a documented set of fields in a netcdf file
Data.ListGlobalAttribute={'title','Time','TimeUnit'};
Data.title='test field for netcdf';
Data.Time=15;
Data.TimeUnit='s';
Data.ListVarName={'X','Y','U','V','coord_y','coord_x','A'};%  cell array containing the names of the fields to record
Data.VarDimName={'nbvec','nbvec','nbvec','nbvec','coord_y','coord_x',{'coord_y','coord_x'}};
Data.VarAttribute{1}.longname='abscissa';
Data.VarAttribute{2}.longname='ordinate';
Data.VarAttribute{3}.longname='x velocity component';
Data.VarAttribute{4}.longname='y velocity component';
Data.VarAttribute{5}.longname='interpolated abscissa';
Data.VarAttribute{6}.longname='interpolated ordinate';
Data.VarAttribute{7}.longname='stream function';
Data.VarAttribute{1}.Role='coord_x';
Data.VarAttribute{2}.Role='coord_y';
Data.VarAttribute{3}.Role='vector_x';
Data.VarAttribute{4}.Role='vector_y';

nbvec=200;
Data.X=4*rand(1,nbvec)-2;%random set of abscissa between -2 and 2
Data.Y=4*rand(1,nbvec)-2;%random set of ordinates between -2 and 2
Psi=exp(-Data.X.^2-Data.Y.^2);
Data.U=Data.Y.*Psi;
Data.V=-Data.X.*Psi;
Data.coord_y=[-2 2];
Data.coord_x=[-2 2];
Data.A =exp(-x.^2-y.^2);
err=struct2nc('test_2.nc',Data);
if isempty(err)
    display('test_2.nc written')
else
    msgbox_uvmat('ERROR',err)
end

%% fast reading of global attributes
DataOut_global=nc2struct('test_2.nc','ListGlobalAttribute','title','Time');
display('fast reading of global attributes:')
display(DataOut_global)

%% reading of the whole netcdf file
DataOut_all=nc2struct('test_2.nc');
display('reading of the whole netcdf file:')
display(DataOut_all)

%% reading only the field A, coord_y, coord_x  only
DataOut_A=nc2struct('test_2.nc',{'coord_y','coord_x','A'}); 
display('reading only the field A, coord_y, coord_x  only:')
display(DataOut_A)
