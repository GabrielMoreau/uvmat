% 'DXYMatrix': calculate the matrix of thin-plate shell derivatives
% 
% function DMXY = DXYMatrix(dsites,ctrs)
%
% INPUT:
%   dsites: M x s matrix of interpolation site coordinates (s=space dimension)
%   ctrs: N x s matrix of centre coordinates (initial data)
%
% OUTPUT:
%     DMXY: Mx(N+1+s)xs matrix corresponding to M interpolation sites and
%            N centres, with s=space dimension, DMXY(:,:,k) gives the derivatives
%            along dimension k (=x, y,z) after multiplication by the N+1+s tps sources.
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
DX=Dsites-Ctrs;
[Dsites,Ctrs] = ndgrid(dsites(:,2),ctrs(:,2));%d coordinates of interpolation points (Dsites) and initial points (Ctrs)
DY=Dsites-Ctrs;
DM = DX.*DX + DY.*DY;% add d component squared 

 %% calculate matrix of tps derivatives
DM(DM~=0) = log(DM(DM~=0))+1; %=2 log(r)+1 derivative of the tps r^2 log(r)

DMX=[DX.*DM zeros(M,1)  ones(M,1) zeros(M,1)];% effect of mean gradient
DMY=[DY.*DM zeros(M,1)  ones(M,1) zeros(M,1)];% effect of mean gradient

