%'cluster_command_psmn': creates the command string for launching jobs in the PSMN cluster
%------------------------------------------------------------------------
% function cmd=cluster_command_psmn(ListProcess,ActionFullName,DirLog,NbProcess, NbCore,CPUTimeProcess)
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

function cmd=cluster_command_psmn(ListProcessFile, ActionFullName, DirLog, NbProcess, NbCore, CPUTimeProcess)
    SubmitScriptFile = regexprep(ListProcessFile, '\job_list.txt\>', 'submit_script.sh');
	fid_list = fopen(ListProcessFile, 'r');
    fid_submit = fopen(SubmitScriptFile, 'w');
    i=1;
	while(true)
		process = fgets(fid_list);
        if(process == -1)
			break
        end
        n = numel(process);
        process = process(1:(n-1)); % on enlève le trailing \n
        LogFile = regexprep(regexprep(process, '0_EXE\>', '0_LOG'), '\.sh\>', '.log');
        fwrite(fid_submit, ['qsub -V '...
                            '-e ' LogFile ' '...
                            '-o ' LogFile ' '...
                            '-q piv_debian* '...
		            '-P PIV '...
                            '-N UVmat_' num2str(i) ' '...
                            process char(10)]);
        i=i+1;
	end
	fclose(fid_list);
    fclose(fid_submit);
    system(['chmod +x ' SubmitScriptFile]);
    cmd = SubmitScriptFile;
end
