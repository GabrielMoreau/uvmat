%'call_command_clean': call a command with LD_LIBRARY_PATH cleaned

function [status, result]=call_command_clean(command)

paths = strsplit(getenv('LD_LIBRARY_PATH'), ':');
cc = regexp(paths, 'matlab/');
new_paths = paths(cellfun('isempty', cc));
clean_ld_lib_path = strjoin(new_paths, ':');

[status, result] = system(['OMP_NUM_THREADS=1 LD_LIBRARY_PATH=' clean_ld_lib_path ' ' command ' &'], '-echo');
end
