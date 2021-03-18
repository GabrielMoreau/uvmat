%'close_fig': function  activated when a figure is closed
%----------------------------------------------------------------
% function close_fig(ggg,eventdata,hparent,type)
% activated by the command:
%set(hObject,'DeleteFcn',{@close_fig,hparent,type})
% where hObject is the handle of the figure
%

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

function close_fig(ggg,eventdata,hparent,type)
if isequal(type,'zoom')
    delete(hparent)  % delete the rectangle showing the zoom graph in the parent fig
end
