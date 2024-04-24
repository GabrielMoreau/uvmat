%'command_launch_python': creates the command string for launching fluidimage
%------------------------------------------------------------------------
% function cmd=command_launch_python(inputxml)
%
%OUTPUT
% cmd=set of system commands (char string) to write
%
%INPUT:
% inputxml: path of the xml input parameter file for the program fluidimage
% option: = 'background' or 'cluster' depending on the launching option

function cmd=command_launch_python(inputxml)
    cmd = ['python -m fluidimage.run_from_xml ' inputxml];
end
