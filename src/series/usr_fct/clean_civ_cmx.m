%'clean_civ_cmx': suppress all ancillary files used for PIV: ;cmx,log,.bat...
%------------------------------------------------------------------------
% function GUI_input=clean_civ_cmx(num_i1,num_i2,num_j1,num_j2,Series)
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
%num_i1: (not used) series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2: (not used) series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1: (not used) series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2: (not used) series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%Series: Matlab structure containing information set by the series interface

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

function GUI_input=clean_civ_cmx(num_i1,num_i2,num_j1,num_j2,Series) %(filecell,filecell_1,num_i,num_j,vel_type,field,param);

%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
    GUI_input={'RootPath';'many';...%nbre of possible input series (options 'on'/'two'/'many', default:'one')
        'SubDir';'on';... % subdirectory of derived files (PIV fields), ('on' by default)
        %'RootFile';'on';... %root input file name ('on' by default)
        %'FileExt';'on';... %input file extension ('on' by default)
        %'NomType';'on';...%type of file indexing ('on' by default)
        %'NbSlice';'on'; ...%nbre of slices ('off' by default)
        %'VelTypeMenu';'one';...% menu for selecting the velocity type (civ1,..) options 'off'/'one'/'two', 'off' by default)
        %'FieldMenu';'one';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        %'CoordType';'on'...%can use a transform function 'off' by default
        %'GetObject';'on'...%can use projection object ,'off' by default
        %'GetMask';'on'...%can use mask option   ,'off' by default
        %'PARAMETER'; options: name of the user defined parameter',repeat a line for each parameter 
               ''};
    return %exit the function 
end
%---------------------------------------------------------
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position');

%%%%%%%%%%%%%%%%%%%%%%%%
message='this function will delete all files with extensions .log, .bat, .cmx,.cmx2,.errors in the input directory(ies)';
answer=msgbox_uvmat('INPUT_Y-N',message);
if ~isequal(answer,'Yes')
    return
end
nbdelete=0;
testcell=iscell(Series.RootFile);
if ~testcell
    Series.RootPath={Series.RootPath};
    Series.RootFile={Series.RootFile};
    Series.SubDir={Series.SubDir};
    Series.FileExt={Series.FileExt};
    Series.NomType={Series.NomType};
end 
for iview=1:length(Series.RootFile)
    hdir=dir(fullfile(Series.RootPath{iview},Series.SubDir{iview}));%list files
    for ilist=1:length(hdir)
%         update_waitbar(hseries.waitbar,WaitbarPos,ilist/length(hdir))
        FileName=hdir(ilist).name;
        [dd,ff,Ext]=fileparts(FileName);
        if isequal(Ext,'.log')||isequal(Ext,'.bat')||isequal(Ext,'.cmx')||isequal(Ext,'.cmx2')|| isequal(Ext,'.errors')
            delete(fullfile(Series.RootPath{iview},Series.SubDir{iview},FileName))
            nbdelete=nbdelete+1;
        end
    end
end
msgbox_uvmat('CONFIRMATION',['END: ' num2str(nbdelete) ' files deleted by clean_civ_cmx'])



