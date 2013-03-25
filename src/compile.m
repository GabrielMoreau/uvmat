%'compile': compile a Matlab function, create a binary in a subdirectory /bin
%--------------------------------------------------------------------
% compile (FctName)
%
%INPUT:
%FctName: name of the Matlab fct to compile (without .m extension)
%
function compile (FctName)
if isempty(which('mcc'))
    msgbox_uvmat('no Matlab compiler toolbox mcc installed')
    return
end
display(['compiling ' FctName ' ...'])
% commands to compile civ_matlab and eventually other functions
if ~exist('bin','dir')
    [success,errormsg]=mkdir('bin');
    if success~=1
        display(errormsg)
    end
end
eval(['mcc -m -R -nojvm -R -nodisplay ' FctName '.m']);
system(['mv -f ' FctName ' bin/']);
system(['sed -e ''''s#/' FctName '#/bin/' FctName '#'''' run_' FctName '.sh > ' FctName '.sh']);
system(['rm run_' FctName '.sh']);
system(['chmod +x ' FctName '.sh']);
display('** END **')



