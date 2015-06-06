%=======================================================================
% Copyright 2008-2015, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

%%% Extraction of the final intrinsic and extrinsic paramaters:

check_active_images;

if ~exist('solution_error')
   solution_error = zeros(6*n_ima + 15,1);
end;

fc = solution(1:2);%***
cc = solution(3:4);%***
alpha_c = solution(5);%***
kc = solution(6:10);%***

fc_error = solution_error(1:2);
cc_error = solution_error(3:4);
alpha_c_error = solution_error(5);
kc_error = solution_error(6:10);

% Calibration matrix:
	
KK = [fc(1) fc(1)*alpha_c cc(1);0 fc(2) cc(2); 0 0 1];
inv_KK = inv(KK);

% Extract the extrinsic paramters, and recomputer the collineations

for kk = 1:n_ima,
   
   if active_images(kk),   
      
      omckk = solution(15+6*(kk-1) + 1:15+6*(kk-1) + 3);%***   
      Tckk = solution(15+6*(kk-1) + 4:15+6*(kk-1) + 6);%*** 
      
      omckk_error = solution_error(15+6*(kk-1) + 1:15+6*(kk-1) + 3); 
      Tckk_error = solution_error(15+6*(kk-1) + 4:15+6*(kk-1) + 6);
      
   	Rckk = rodrigues(omckk);
   
   	Hkk = KK * [Rckk(:,1) Rckk(:,2) Tckk];
   
   	Hkk = Hkk / Hkk(3,3);
      
   else
      
      omckk = NaN*ones(3,1);   
      Tckk = NaN*ones(3,1);
      Rckk = NaN*ones(3,3);
      Hkk = NaN*ones(3,3);
      omckk_error = NaN*ones(3,1);
      Tckk_error = NaN*ones(3,1);
      
   end;
   
   eval(['omc_' num2str(kk) ' = omckk;']);
   eval(['Rc_' num2str(kk) ' = Rckk;']);
   eval(['Tc_' num2str(kk) ' = Tckk;']);
   eval(['H_' num2str(kk) '= Hkk;']);
   eval(['omc_error_' num2str(kk) ' = omckk_error;']);
   eval(['Tc_error_' num2str(kk) ' = Tckk_error;']);
   
end;
