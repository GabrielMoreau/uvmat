%'compile': compile a Matlab function, create a binary in a subdirectory /bin
%--------------------------------------------------------------------
% compile (FctName)
%
%INPUT:
%FctName: name of the Matlab fct to compile (without .m extension)

%=======================================================================
% Copyright 2008-2018, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function compile (FctName,SubfctPath)
hh=[]; % handles of message display window
if isempty(which('mcc'))
    msgbox_uvmat('ERROR','no Matlab compiler toolbox mcc installed')
    return
else
    hh=msgbox_uvmat('WAITING...',['compilation of ' FctName ' in progress...']);
end
disp(['compiling ' FctName ' ...'])
% commands to compile civ_matlab and eventually other functions
if ~exist('bin','dir')
    [success,errormsg]=mkdir('bin');
    if success~=1
        display(errormsg)
    end
end
if ~isempty(SubfctPath)
    SubfctPath=['-I ' SubfctPath]; % string indicating the option of including the path SubfctPath
end
[mcrmajor, mcrminor] = mcrversion;   
MCRROOT = ['MCRROOT',int2str(mcrmajor),int2str(mcrminor)];
FctNameVersion=[FctName,'_',MCRROOT];
try
    disp(['mcc -m -R -nojvm -R -nodisplay -R -singleCompThread ' SubfctPath ' ' FctName '.m'])
    eval(['mcc -m -R -nojvm -R -nodisplay -R -singleCompThread ' SubfctPath ' ' FctName '.m'])% compile the source file [FctName .m], which produces a binary file FctName and a cmd file [run_' FctName '.sh]
    system(['mv -f ' FctName ' bin/']); % move the binary file FctName to the subdir /bin
    system(['sed -e ''''s#/' FctName '#/bin/' FctName '#'''' run_' FctName '.sh > ' FctNameVersion '.sh']); % modify the cmd file and copy it to [FctName '.sh']
    system(['rm run_' FctName '.sh']); % remove the initial cmd file [run_' FctName '.sh]
    system(['chmod +x ' FctNameVersion '.sh']); % set the cmd file to 'executable'
catch ME
    hh=msgbox_uvmat('ERROR',ME.message);
end
display('** END **')
if ~isempty(hh)
delete(hh)
end


