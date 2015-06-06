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

if ~exist('I_1'),
   active_images_save = active_images;
   ima_read_calib;
   active_images = active_images_save;
   check_active_images;
end;

check_active_images;

if isempty(ind_read),
   return;
end;


n_col = floor(sqrt(n_ima*nx/ny));

n_row = ceil(n_ima / n_col);


ker2 = 1;
for ii  = 1:n_col,
   ker2 = conv(ker2,[1/4 1/2 1/4]);
end;


II = I_1(1:n_col:end,1:n_col:end);

[ny2,nx2] = size(II);



kk_c = 1;

II_mosaic = [];

for jj = 1:n_row,
    
    
    II_row = [];
    
    for ii = 1:n_col,
        
        if (exist(['I_' num2str(kk_c)])) & (kk_c <= n_ima),
            
            if active_images(kk_c),
                eval(['I = I_' num2str(kk_c) ';']);
                %I = conv2(conv2(I,ker2,'same'),ker2','same'); % anti-aliasing
                I = I(1:n_col:end,1:n_col:end);
            else
                I = zeros(ny2,nx2);
            end;
            
        else
            
            I = zeros(ny2,nx2);
            
        end;
        
        
        
        II_row = [II_row I];
        
        if ii ~= n_col,
            
            II_row = [II_row zeros(ny2,3)];
            
        end;
        
        
        kk_c = kk_c + 1;
        
    end;
    
    nn2 = size(II_row,2);
    
    if jj ~= n_row,
        II_row = [II_row; zeros(3,nn2)];
    end;
    
    II_mosaic = [II_mosaic ; II_row];
    
end;

figure(2);
image(II_mosaic);
colormap(gray(256));
title('Calibration images');
set(gca,'Xtick',[])
set(gca,'Ytick',[])
axis('image');

