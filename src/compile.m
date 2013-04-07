%'compile': compile a Matlab function, create a binary in a subdirectory /bin
%--------------------------------------------------------------------
% compile (FctName)
%
%INPUT:
%FctName: name of the Matlab fct to compile (without .m extension)
%
function compile (FctName,SubfctPath)
if isempty(which('mcc'))
    msgbox_uvmat('no Matlab compiler toolbox mcc installed')
    return
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
eval(['mcc -m -R -nojvm -R -nodisplay ' SubfctPath ' ' FctName '.m'])% compile the source file [FctName .m], which produces a binary file FctName and a cmd file [run_' FctName '.sh]
%eval(['mcc -m -R -nojvm -R -nodisplay ' FctName '.m'])% compile the source file [FctName .m], which produces a binary file FctName and a cmd file [run_' FctName 
system(['mv -f ' FctName ' bin/']);%move the binary file FctName to the subdir /bin
system(['sed -e ''''s#/' FctName '#/bin/' FctName '#'''' run_' FctName '.sh > ' FctName '.sh']);%modify the cmd file and copy it to [FctName '.sh']
system(['rm run_' FctName '.sh']);% remove the initial cmd file [run_' FctName '.sh]
system(['chmod +x ' FctName '.sh']); % set the cmd file to 'executable'
display('** END **')
end



