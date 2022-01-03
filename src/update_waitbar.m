%'update_waitbar': update the waitbar display, used for ACTION functions in the GUI 'series'
%------------------------------------------------------------------
%INPUT:
% hwaitbar:  handles of the waitbar to update
% advance_ratio: number between 0 and 1 representing the advancement of the calculation (loop index relative to the total length)

%=======================================================================
% Copyright 2008-2022, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function update_waitbar(hwaitbar,advance_ratio)
if ishandle(hwaitbar)
set(hwaitbar,'Units','pixels')
pos=get(hwaitbar,'Position');%read waitbar position in pixels
set(hwaitbar,'Units','normalized')%set back to normalize(the waitbar scales with the GUI)
% CData=ones(floor(pos(4)),floor(pos(3)),3);
% CData(:,:,3)=0 ;% initial color yellow (rgb=[1 1 0])
CData=zeros(floor(pos(4)),floor(pos(3)),3);
CData(:,:,3)=1 ;% initial color blue(rgb=[1 1 0])

CData(:,1:floor(advance_ratio*size(CData,2)),2)=0; % advancement part in red (suppress the second color component green)
set(hwaitbar,'CData',CData)
drawnow
end
