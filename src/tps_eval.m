%'tps_eval': calculate the thin plate spline (tps) interpolation at a set of points
% see tps_ceff for more information
%------------------------------------------------------------------------
% function EM = tps_eval(dsites,ctrs)
%------------------------------------------------------------------------
% OUPUT:
% EM:  Mx(N+s) matrix representing the contributions at the M sites 
%   from unit sources located at each of the N centers, + (s+1) columns
%   representing the contribution of the linear gradient part.
%
%INPUT:
%dsites:  Nxs matrix representing the postions of the N 'observation' sites, with s the space dimension
%ctrs: Mxs matrix  representing the postions of the M centers, sources of the tps,
%
% related functions:
% tps_coeff, tps_eval_dxy

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