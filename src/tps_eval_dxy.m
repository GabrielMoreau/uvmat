%'tps_eval_dxy': calculate the derivatives of thin plate spline (tps) interpolation at a set of points (limited to the 2D case)
%------------------------------------------------------------------------
% function [DMX,DMY] = tps_eval_dxy(dsites,ctrs)
%------------------------------------------------------------------------
% OUTPUT:
%  DMX: Mx(N+3) matrix representing the contributions to the X
%  derivatives at the M sites from unit sources located at each of the N
%  centers, + 3 columns representing the contribution of the linear gradient part.
%  DMY: idem for Y derivatives
%
% INPUT:
%  dsites: M x s matrix of interpolation site coordinates (s=space dimension=2 here)
%  ctrs: N x s matrix of centre coordinates (initial data)
%
% RELATED FUNCTIONS:
%  tps_coeff, tps_eval
%  tps_coeff_field, set_subdomains, filter_tps, calc_field

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [DMX,DMY] = tps_eval_dxy(dsites,ctrs)
  %%  matrix declarations
  [M,s] = size(dsites); [N,s] = size(ctrs);
  Dsites=zeros(M,N);
  DM = zeros(M,N);
 % DMXY = zeros(M,N+1+s);
  
  %% Accumulate sum of squares of coordinate differences
  % The ndgrid command produces two MxN matrices:
  %   Dsites, consisting of N identical columns (each containing
  %       the d-th coordinate of the M interpolation sites)
  %  Ctrs, consisting of M identical rows (each containing
  %       the d-th coordinate of the N centers)
  
[Dsites,Ctrs] = ndgrid(dsites(:,1),ctrs(:,1));%d coordinates of interpolation points (Dsites) and initial points (Ctrs)
DX=Dsites-Ctrs;% set of x wise distances between sites and centres
[Dsites,Ctrs] = ndgrid(dsites(:,2),ctrs(:,2));%d coordinates of interpolation points (Dsites) and initial points (Ctrs)
DY=Dsites-Ctrs;% set of y wise distances between sites and centres
DM = DX.*DX + DY.*DY;% add d component squared 

 %% calculate matrix of tps derivatives
DM(DM~=0) = log(DM(DM~=0))+1; %=2 log(r)+1 derivative of the tps r^2 log(r)

DMX=[DX.*DM zeros(M,1)  ones(M,1) zeros(M,1)];% effect of mean gradient
DMY=[DY.*DM zeros(M,1)  zeros(M,1) ones(M,1)];% effect of mean gradient

