%'command_launch_matlab': creates the command strings for opening a new Matlab
%session and running a programme in a Linux system('GLNX86','GLNXA64','MACI64')
%------------------------------------------------------------------------
% function cmd=command_launch_matlab(filelog,path_uvmat,ActionPath,ActionName,inputxml,option)
%
%OUTPUT
% cmd=set of system commands (char string) to write in an executable file: [fid,message]=fopen(file_exe,'w');
                           % fprintf(fid,cmd); % fill the executable file with the  char string cmd
                           % fclose(fid); % close the executable file
                           %  system(['chmod +x ' file_exe]); % set the file to executable
                           % system([file_exe ' &'])%  execute the command file
                           
%
%INPUT:
% filelog: name (char string)  of the file to collect the output in the Matlab command window
% path_uvmat: path to the UVMAT Matlab toolbox
% ActionPath:  path to the Matlab programme to launch
% ActionName: name of the programme to launch
% inputxml: full name, including path, of the xml input parameter file for the programme ActionName
% option: ='bacground' or 'cluster' depending on the launching option

function cmd=command_launch_matlab(filelog,path_uvmat,ActionPath,ActionName,inputxml,option)
ThreadOption='';
if strcmp(option,'cluster')
    ThreadOption='-singleCompThread';
    inputxml={inputxml};% single input parameter file
end
matlab_ver = ver('MATLAB');
matlab_version = matlab_ver.Version;
cmd=[...
    '#!/bin/bash\n'...
    'source /etc/profile\n'...
    'module purge\n'...
    'module load matlab/' matlab_version '\n'...% CHOICE OF THE SAME MATLAB VERSION AS THE CURRENT MATLAB SESSION (not mandatory)
    'time_start=$(date +%%s)\n'...
    'matlab -nodisplay -nosplash -nojvm ''' ThreadOption ''' -logfile ''' filelog ''' <<END_MATLAB\n'...%launch the new Matlab session  without display
    'addpath(''' path_uvmat ''');\n'...
    'addpath(''' ActionPath ''');\n'];
for iprocess=1:numel(inputxml)
    cmd=[cmd '' ActionName  '(''' inputxml{iprocess} ''');\n'];
end
cmd=[cmd  'exit\n' 'END_MATLAB\n'];
    if strcmp(option,'background')
    cmd=[cmd ...
    'time_end=$(date +%%s)\n'...
    'echo "global time = " $(($time_end - $time_start)) >> ''' filelog '''\n'];
    end

%% case cluster:
% matlab_ver = ver('MATLAB');
%                     matlab_version = matlab_ver.Version;
%                     cmd=[...
%                         '#!/bin/bash\n'...
%                         'source /etc/profile\n'...
%                         'module purge\n'...
%                         'module load matlab/' matlab_version '\n'...% CHOICE OF CURRENT MATLAB VERSION
%                         'matlab -nodisplay -nosplash -nojvm -singleCompThread -logfile ''' filelog{iprocess} ''' <<END_MATLAB\n'...% open a new Matlab session without display
%                         'addpath(''' path_series ''');\n'...
%                         'addpath(''' ActionPath ''');\n'...
%                         '' ActionName  '(''' filexml{iprocess} ''');\n'...% launch the Matlab function selected by the GUI 'series'
%                         'exit\n'...
%                         'END_MATLAB\n'];
%                 end


