%'compile': compile a Matlab function, create a binary in a subdirectory /bin
%--------------------------------------------------------------------
% compile (FctName)
%
%INPUT:
%FctName: name of the Matlab fct to compile (without .m extension)
%
function compile (FctName,SubfctPath)
if isempty(which('mcc'))
    msgbox_uvmat('ERROR','no Matlab compiler toolbox mcc installed')
    return
else
    hh=msgbox_uvmat('INFO',['compilation of ' FctName ' in progress...']);
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
    SubfctPath=['-I ' SubfctPath];%string indicating the option of including the path SubfctPath
end
disp(['mcc -m -R -nojvm -R -nodisplay ' SubfctPath ' ' FctName '.m'])
try
    eval(['mcc -m -R -nojvm -R -nodisplay ' SubfctPath ' ' FctName '.m'])% compile the source file [FctName .m], which produces a binary file FctName and a cmd file [run_' FctName '.sh]
    system(['mv -f ' FctName ' bin/']);%move the binary file FctName to the subdir /bin
    system(['sed -e ''''s#/' FctName '#/bin/' FctName '#'''' run_' FctName '.sh > ' FctName '.sh']);%modify the cmd file and copy it to [FctName '.sh']
    system(['rm run_' FctName '.sh']);% remove the initial cmd file [run_' FctName '.sh]
    system(['chmod +x ' FctName '.sh']); % set the cmd file to 'executable'
catch ME
    msgbox_uvmat('ERROR',ME.message);
end
display('** END **')
delete(hh)



