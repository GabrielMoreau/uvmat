%'command_load_python': creates the command strings for loading Python
%programmes for Linux system('GLNX86','GLNXA64','MACI64')
%------------------------------------------------------------------------
% function success=command_launch_python
%
%OUTPUT
% success =1 if command successfull, 0 otherwise
                           
%
%INPUT:


function success=command_load_python
code1=system('module load python/3.9.7')
if code1==0
cmd = ['LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | pyp "l = x.split('':''); l = [s for s in l if ''matlab'' not in s]; print('':''.join(l))") ' ...
            'python -c "import fluidimage"'];
code = system(cmd); 
end
success=~code;





