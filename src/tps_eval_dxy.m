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
  function DMXY = tps_eval_dxy(dsites,ctrs)
  %%  matrix declarations
  [M,s] = size(dsites); [N,s] = size(ctrs);
  Dsites=zeros(M,N,s);
  DM = zeros(M,N);
  DMXY = zeros(M,N+1+s,s);
  
  %% Accumulate sum of squares of coordinate differences
  % The ndgrid command produces two MxN matrices:
  %   Dsites, consisting of N identical columns (each containing
  %       the d-th coordinate of the M interpolation sites)
  %  Ctrs, consisting of M identical rows (each containing
  %       the d-th coordinate of the N centers)
  for d=1:s
     [Dsites(:,:,d),Ctrs] = ndgrid(dsites(:,d),ctrs(:,d));%d coordinates of interpolation points (Dsites) and initial points (Ctrs)
     DM = DM + (Dsites(:,:,d)-Ctrs).^2;% add d component squared 
  end
  
  %% calculate mtrix of tps derivatives
  DM(DM~=0) = log(DM)+1; %=2 log(r)+1 derivative of the tps r^2 log(r)
  for d=1:s
    DMXY(:,1:N,d)=Dsites(:,:,d).*DM;
    DMXY(:,N+1+d,d)=1;% effect of mean gradient
  end
