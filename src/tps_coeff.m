%'tps_uvmat': calculate thin plate shell coefficients
%------------------------------------------------------------------------
%fasshauer@iit.edu MATH 590 ? Chapter 19 32
% X,Y initial coordiantes
% XI vector, YI column vector for the grid of interpolation points
function [U_smooth,U_tps]=tps_coeff(X,Y,U,rho)
%------------------------------------------------------------------------
%rho smoothing parameter
% ep = 1; 
X=reshape(X,[],1);
Y=reshape(Y,[],1);
N=numel(X);
rhs = reshape(U,[],1);
rhs = [rhs; zeros(3,1)];
ctrs = [X Y];% coordinates of measurement sites, radial base functions are located at the measurement sites
%ctrs = dsites;%radial base functions are located at the measurement sites
EM = tps_eval(ctrs,ctrs);
% DM_data = DistanceMatrix(ctrs,ctrs);%2D matrix of distances between spline centres (=initial points) ctrs
% IM_sites = tps(1,DM_data);%values of thin plate at site points
% PM=[ones(N,1) ctrs];
% EM = [IM_sites PM];
%IM = IM_sites + rho*eye(size(IM_sites));%  rho=1/(2*omega) , omega given by fasshauer;

%IM=[IM PM; [PM' zeros(3,3)]];
RhoMat=rho*eye(N,N);%  rho=1/(2*omega) , omega given by fasshauer;
RhoMat=[RhoMat zeros(N,3)];
PM=[ones(N,1) ctrs];

IM=[EM+RhoMat; [PM' zeros(3,3)]];
%fprintf('Condition number estimate: %e\n',condest(IM))
%DM_eval = DistanceMatrix(epoints,ctrs);%2D matrix of distances between extrapolation points epoints and spline centres (=site points) ctrs
%EM = tps(ep,DM_eval);%values of thin plate 
%PM = [ones(size(epoints,1),1) epoints]; 
%EM = [EM PM];
U_tps=(IM\rhs);
% PM = [ones(size(dsites,1),1) dsites]; 

U_smooth=EM *U_tps;