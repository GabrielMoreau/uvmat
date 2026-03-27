%'cluster_command': creates the command string for launching jobs in the cluster
%------------------------------------------------------------------------
% function cmd=cluster_command(ListProcess,ActionFullName,DirLog,NbProcess, NbCore,CPUTimeProcess)
%
%OUTPUT
% cmd=system command (char string) to launch jobs
%%
%
%INPUT:
% ListProcessFile: name of the file containing the list of processes to perform
% ActionFullName: name given to the action (function activated by series)
% DirLog: name of the folder used to store the log files from calculations
% NbProcess: number of processes in the list, these processed are grouped by the systwm into jobs dipatched to NbCore cores
% NbCore: number of computer cores to which the processes are dispatched
% CPUTimeProcess: estimated CPU time for an individual process (in min)

function cmd=cluster_command(ListProcessFile,ActionFullName,DirLog,NbProcess, NbCore,CPUTimeProcess)

filename_log=fullfile(DirLog,'job_list.stdout'); % file for output messages of the master oar process
filename_errors=fullfile(DirLog,'job_list.stderr'); % file for error messages of the master oar process
        if NbProcess>=6
            bigiojob_string=['+{type = ' char(39) 'bigiojob' char(39) '}/licence=1'];% char(39) is quote - bigiojob limit UVmat parallel launch on cluster to avoid saturation of disk access to data
        else
            bigiojob_string='';
        end 

WallTimeMax=23;% absolute limit on computation time (in hours)
WallTimeTotal=min(WallTimeMax,4*CPUTimeProcess/60);% chosen limit on computation time (in hours),possibly smaller than the absolute limit to favor job priority in the system.  
WallTimeOneProcess=min(4*CPUTimeProcess+10,WallTimeTotal*60/2); % estimated max time of an individual process, used for checkpoint: 
        
 oar_command=['oarsub -n UVmat_' ActionFullName ' '...
            '-t idempotent --checkpoint ' num2str(WallTimeOneJob*60) ' '...
            '-q watu -l "{cluster=''calcul8''}/core=' num2str(NbCore)...%             '+{type = ' char(39) 'bigiojob' char(39) '}/licence=1'... % char(39) is quote - bigiojob limit UVmat parallel launch on cluster
            ',walltime=' datestr(WallTimeTotal/24,13) '" '...
            '-E ' filename_errors ' '...
            '-O ' filename_log ' '...
            '"oar-parexec -s -f ' ListProcessFile ' '...
            '-l ' ListProcessFile '.log"'];
