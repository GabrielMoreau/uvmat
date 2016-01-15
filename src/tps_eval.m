%'tps_eval': calculate the thin plate spline (tps) interpolation at a set of points
% see tps_coeff.m for more information and test_tps.m for an example
%------------------------------------------------------------------------
% function EM = tps_eval(dsites,ctrs)
%------------------------------------------------------------------------
% OUTPUT:
%  EM:  Mx(N+s) matrix representing the contributions at the M sites 
%   from unit sources located at each of the N centers, + (s+1) columns
%   representing the contribution of the linear gradient part.
%  use : U_interp=EM*U_tps
%
% INPUT:
%  dsites:  Mxs matrix representing the postions of the M 'observation' sites, with s the space dimension
%  ctrs: Nxs matrix  representing the postions of the N centers, sources of the tps,
%
% RELATED FUNCTIONS:
%  tps_coeff, tps_eval_dxy
%  tps_coeff_field, set_subdomains, filter_tps, calc_field

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

function EM = tps_eval(dsites,ctrs)
[M,s] = size(dsites); [N,s] = size(ctrs);
EM = zeros(M,N);

% calculate distance matrix: accumulate sum of squares of coordinate differences
% The ndgrid command produces two MxN matrices:
%   Dsite, consisting of N identical columns (each containing
%       the d-th coordinate of the M data sites)
%   Ctrs, consisting of M identical rows (each containing
%       the d-th coordinate of the N centers)
for d=1:s
 [Dsites,Ctrs] = ndgrid(dsites(:,d),ctrs(:,d));
 EM = EM + (Dsites-Ctrs).^2;%EM=square of distance matrices
end

% calculate tps
np=find(EM~=0);
EM(np) = EM(np).*log(EM(np))/2;%= tps formula r^2 log(r) (EM=r^2)

% add linear gradient part:
EM = [EM ones(M,1) dsites];
