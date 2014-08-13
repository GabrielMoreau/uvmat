%=======================================================================
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

check_active_images;

for kk =  ind_active,
   
   if ~exist(['x_' num2str(kk)]),
      
      fprintf(1,'WARNING: Need to extract grid corners on image %d\n',kk);
      
      active_images(kk) = 0;
      
      eval(['dX_' num2str(kk) ' = NaN;']);
      eval(['dY_' num2str(kk) ' = NaN;']);  
      
      eval(['wintx_' num2str(kk) ' = NaN;']);
      eval(['winty_' num2str(kk) ' = NaN;']);

      eval(['x_' num2str(kk) ' = NaN*ones(2,1);']);
      eval(['X_' num2str(kk) ' = NaN*ones(3,1);']);
      
      eval(['n_sq_x_' num2str(kk) ' = NaN;']);
      eval(['n_sq_y_' num2str(kk) ' = NaN;']);
   
   else
      
      eval(['xkk = x_' num2str(kk) ';']);
      
      if isnan(xkk(1)),
	 
	 fprintf(1,'WARNING: Need to extract grid corners on image %d - This image is now set inactive\n',kk);

	 active_images(kk) = 0;
	 
      end;
      
   end;
   
end;
