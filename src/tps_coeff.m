%'tps_coeff': calculate the thin plate spline (tps) coefficients
% (ref fasshauer@iit.edu MATH 590 ? Chapter 19 32)
% this interpolation/smoothing minimises a linear combination of the squared curvature
%  and squared difference form the initial data. 
% This function calculates the weight coefficients U_tps of the N sites where
% data are known. Interpolated data are then obtained as the matrix product
% EM*U_tps where the matrix EM is obtained by the function tps_eval.
% The spatial derivatives are obtained as EMDX*U_tps and EMDY*U_tps, where
% EMDX and EMDY are obtained from the function tps_eval_dxy.
% for big data sets, a splitting in subdomains is needed, see functions
% set_subdomains and tps_coeff_field.
%
%------------------------------------------------------------------------
% [U_smooth,U_tps]=tps_coeff(ctrs,U,Smoothing)
%------------------------------------------------------------------------
% OUTPUT:
%  U_smooth: values of the quantity U at the N centres after smoothing
%  U_tps: tps weights of the centres and columns of the linear

% INPUT:
%  ctrs: NxNbDim matrix  representing the positions of the N centers, sources of the tps (NbDim=space dimension)
%  U: Nx1 column vector representing the values of the considered scalar measured at the centres ctrs
%  Smoothing: smoothing parameter: the result is smoother for larger Smoothing.
%
% RELATED FUNCTIONS:
%  tps_eval, tps_eval_dxy
%  tps_coeff_field, set_subdomains, filter_tps, calc_field

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

function [U_smooth,U_tps]=tps_coeff(ctrs,U,Smoothing)
%------------------------------------------------------------------------
warning off
N=size(ctrs,1);% nbre of source centres
NbDim=size(ctrs,2);% space dimension (2 or 3)
U = [U; zeros(NbDim+1,1)];
EM = tps_eval(ctrs,ctrs);
SmoothingMat=Smoothing*eye(N,N);%  Smoothing=1/(2*omega) , omega given by fasshauer;
SmoothingMat=[SmoothingMat zeros(N,NbDim+1)];
PM=[ones(N,1) ctrs];
IM=[EM+SmoothingMat; [PM' zeros(NbDim+1,NbDim+1)]];
U_tps=(IM\U);
U_smooth=EM *U_tps;
