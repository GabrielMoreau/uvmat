%'disp_uvmat': display a message using  msgbox_uvmat or on the log file in batch mode
%--------------------------------------------------------------------------
%
%  displ_uvmat(title,display_str,checkrun)
%
%  INPUT:
%  title: ='ERROR' or 'WARNING', as requested as input of  msgbox_uvmat.m
%  display_str: message string to display
%  checkrun: =1: run mode, use of msgbox_uvmat window
%  checkrun: =0: batch mode: text display on log file

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function hh=disp_uvmat(title,display_str,checkrun)
hh=[];
if checkrun
    hh=msgbox_uvmat(title,display_str,'');
else
    disp([title ': ' display_str])
end
    
