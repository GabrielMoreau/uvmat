%   DM:     MxN matrix whose i,j position contains the Euclidean
%              distance between the i-th data site and j-th center
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