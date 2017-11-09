%'cluster_command': creates the command string for launching jobs in the cluster
%------------------------------------------------------------------------
% function cmd=cluster_command_pbs(ListProcess,ActionFullName,DirLog,NbProcess, NbCore,CPUTimeProcess)
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

function cmd=cluster_command_pbs(ListProcessFile,ActionFullName,DirLog,NbProcess, NbCore,CPUTimeProcess)
  
          max_walltime=3600*20; % 20h max total calculation (cannot exceed 24 h)
        walltime_onejob=1800; % seconds, max estimated time for asingle file index value
       % ListProcess=fullfile(DirPBS,'job_list.txt'); % create name of the global executable file
        fid=fopen(ListProcess,'w');
        for iprocess=1:length(batch_file_list)
            fprintf(fid,[batch_file_list{iprocess} '\n']); % list of exe files
        end
        fclose(fid);
        system(['chmod +x ' ListProcess]); % set the file to executable
        cmd=['qsub -n CIVX '...
            '-t idempotent --checkpoint ' num2str(walltime_onejob+60) ' '...
            '-l /core=' num2str(NbCore) ','...
            'walltime=' datestr(min(1.05*walltime_onejob/86400*max(NbProcess*BlockLength*nbfield_j,NbCore)/NbCore,max_walltime/86400),13) ' '...
            '-E ' regexprep(ListProcessFile,'\.txt\>','.stderr') ' '...
            '-O ' regexprep(ListProcessFile,'\.txt\>','.log') ' '...
            '"oar-parexec -s -f ' ListProcessFile ' '...
            '-l ' ListProcessFile '.log"'];