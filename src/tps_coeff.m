%'tps_coeff': calculate the thin plate spline (tps) coefficients
% (ref fasshauer@iit.edu MATH 590 ? Chapter 19 32)
% this interpolation/smoothing minimises a linear combination of the squared curvature
%  and squared difference form the initial data. 
% This function calculates the weight coefficients U_tps of the N sites where
% data are known. Interpolated data are then obtained as the matrix product
% EM*U_tps where the matrix EM is obtained by the function tps_eval.
% The spatial derivatives are obtained as EMDX*U_tps and EMDY*U_tps, where
% EMDX and EMDY are obtained from the function tps_eval_dxy.
%------------------------------------------------------------------------
% [U_smooth,U_tps]=tps_coeff(ctrs,U,Smoothing)
%------------------------------------------------------------------------
% OUPUT:
% U_smooth: values of the quantity U at the N centres after smoothing
% U_tps: tps weights of the centres

%INPUT:
% ctrs: Nxs matrix  representing the postions of the N centers, sources of the tps (s=space dimension)
% U: Nx1 column vector representing the values of the considered scalar measured at the centres ctrs
% Smoothing: smoothing parameter: the result is smoother for larger Smoothing.


function [U_smooth,U_tps]=tps_coeff(ctrs,U,Smoothing)
%------------------------------------------------------------------------
%Smoothing smoothing parameter
% X=reshape(X,[],1);
% Y=reshape(Y,[],1);
N=size(ctrs,1);
% rhs = reshape(U,[],1);
U = [U; zeros(3,1)];
% ctrs = [X Y];% coordinates of measurement sites, radial base functions are located at the measurement sites
EM = tps_eval(ctrs,ctrs);
SmoothingMat=Smoothing*eye(N,N);%  Smoothing=1/(2*omega) , omega given by fasshauer;
SmoothingMat=[SmoothingMat zeros(N,3)];
PM=[ones(N,1) ctrs];
IM=[EM+SmoothingMat; [PM' zeros(3,3)]];
U_tps=(IM\U);
U_smooth=EM *U_tps;