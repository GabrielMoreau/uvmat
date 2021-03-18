%'proj_grid': project  fields with unstructured coordinantes on a regular grid
% -------------------------------------------------------------------------
% function [A,rangx,rangy]=proj_grid(vec_X,vec_Y,vec_A,rgx_in,rgy_in,npxy_in)

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [A,rangx,rangy]=proj_grid(vec_X,vec_Y,vec_A,rgx_in,rgy_in,npxy_in)
    if length(vec_Y)<2
        msgbox_uvmat('ERROR','less than 2 points in proj_grid.m');
        return; 
    end
    diffy=diff(vec_Y); %difference dy=vec_Y(i+1)-vec_Y(i)
    index=find(diffy);% find the indices of vec_Y after wich a change of horizontal line occurs(diffy non zero)
    if isempty(index); msgbox_uvmat('ERROR','points aligned along abscissa in proj_grid.m'); return; end;%points aligned% A FAIRE: switch to line plot.
    diff2=diff(diffy(index));% diff2 = fluctuations of the detected vertical grid mesh dy 
    if max(abs(diff2))>0.001*abs(diffy(index(1))) % if max(diff2) is larger than 1/1000 of the first mesh dy
        % the data are not regularly spaced and must be interpolated  on a regular grid
        if exist('rgx_in','var') & ~isempty (rgx_in) & isnumeric(rgx_in) & length(rgx_in)==2%  positions imposed from input
            rangx=rgx_in; % first and last positions
            rangy=rgy_in;
%             npxy=npxy_in;
            dxy(1)=1/(npxy_in(1)-1);%grid mesh in y
            dxy(2)=1/(npxy_in(2)-1);%grid mesh in x
            dxy(1)=(rangy(2)-rangy(1))/(npxy_in(1)-1);%grid mesh in y
            dxy(2)=(rangx(2)-rangx(1))/(npxy_in(2)-1);%grid mesh in x
        else % interpolation grid automatically determined
            rangx(1)=min(vec_X);
            rangx(2)=max(vec_X);
            rangy(2)=min(vec_Y);
            rangy(1)=max(vec_Y);
            dxymod=sqrt((rangx(2)-rangx(1))*(rangy(1)-rangy(2))/length(vec_X));
            dxy=[-dxymod/4 dxymod/4];% increase the resolution 4 times
        end
        xi=[rangx(1):dxy(2):rangx(2)];
        yi=[rangy(1):dxy(1):rangy(2)];
        [XI,YI]=meshgrid(xi,yi);% creates the matrix of regular coordinates
        A=griddata_uvmat(vec_X,vec_Y,vec_A,xi,yi'); 
        A=reshape(A,length(yi),length(xi));
    else
        x=vec_X(1:index(1));% the set of abscissa (obtained on the first line)
        indexend=index(end);% last vector index of line change
        ymax=vec_Y(indexend+1);% y coordinate AFTER line change
        ymin=vec_Y(index(1));
        %y=[vec_Y(index) ymax]; % the set of y ordinates including the last one
        y=vec_Y(index);
        y(length(y)+1)=ymax;
        nx=length(x);   %number of grid points in x
        ny=length(y);   % number of grid points in y
        B=(reshape(vec_A,nx,ny))'; %vec_A reshaped as a rectangular matrix
        [X,Y]=meshgrid(x,y);% positions X and Y also reshaped as matrix 
        
        %linear interpolation to improve the image resolution and/or adjust
        %to prescribed positions 
        test_interp=1;
        if exist('rgx_in','var') & ~isempty (rgx_in) & isnumeric(rgx_in) & length(rgx_in)==2%  positions imposed from input
            rangx=rgx_in; % first and last positions
            rangy=rgy_in;
            npxy=npxy_in;
        else        
            rangx=[vec_X(1) vec_X(nx)];% first and last position found for x
%             rangy=[ymin ymax];
              rangy=[max(ymax,ymin) min(ymax,ymin)];
            if max(nx,ny) <= 64 & isequal(npxy_in,'np>256')
                npxy=[8*ny 8*nx];% increase the resolution 8 times
            elseif max(nx,ny) <= 128 & isequal(npxy_in,'np>256')
                npxy=[4*ny 4*nx];% increase the resolution 4 times
            elseif max(nx,ny) <= 256 & isequal(npxy_in,'np>256')
                npxy=[2*ny 2*nx];% increase the resolution 2 times
            else
                npxy=[ny nx];
                test_interp=0; % no interpolation done
            end
        end
        if test_interp==1%if we interpolate
            xi=[rangx(1):(rangx(2)-rangx(1))/(npxy(2)-1):rangx(2)];
            yi=[rangy(1):(rangy(2)-rangy(1))/(npxy(1)-1):rangy(2)];
            [XI,YI]=meshgrid(xi,yi);
            A = interp2(X,Y,B,XI,YI);
        else %no interpolation for a resolution higher than 256
            A=B;
            XI=X;
            YI=Y;
        end
    end
