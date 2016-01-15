%'ima_levels': rescale the image intensity to reduce strong luminosity peaks
%------------------------------------------------------------------------
% function GUI_input=ima_levels(num_i1,num_i2,num_j1,num_j2,Series)
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
%num_i1: series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2:  series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1:  series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2:  series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%Series: Matlab structure containing information set by the series interface% relabel_i_j: relabel an image series with two indices, according to the time matrix given by ImaDoc
%----------------------------------------------------------------------

%=======================================================================
% Copyright 2008-2016, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function GUI_input=ima_levels_batch(num_i1,num_i2,num_j1,num_j2,Series)
%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
    GUI_input={};
    return %exit the function 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%enable waitbar
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

basename=fullfile(Series.RootPath,Series.RootFile) ;

%create dir of the new images
[dir_images,namebase]=fileparts(basename);
[path,subdir_ima]=fileparts(dir_images);
dircur=pwd;
cd(path);
mkdir([subdir_ima '_levels']);
  [xx,msg2] = fileattrib([subdir_ima '_levels'],'+w','g'); %yield writing access (+w) to user group (g)
if ~strcmp(msg2,'')
    msgbox_uvmat('ERROR',['pb of permission for ' subdir_ima ': ' msg2])%error message for directory creation
    cd(dircur)
    return
end
cd(dircur);
basename_new=fullfile(path,[subdir_ima '_levels'],namebase);

% read imadoc
%[XmlData,warntext]=imadoc2struct([basename '.xml']);
% nbfield1=size(XmlData.Time,1);
% nbfield2=size(XmlData.Time,2);

msgbox_uvmat('CONFIRMATION','apply image rescaling function levels.m ');

%copy the xml file
if exist([basename '.xml'],'file')
    copyfile([basename '.xml'],[basename_new '.xml']);% copy the .civ file
end

%main loop
batch_file_list={};
nbfield=size(num_i1,2);
nbfield2=size(num_i1,1);
for ifile=1:nbfield
    update_waitbar(hseries.waitbar,WaitbarPos,ifile/nbfield)
    stopstate=get(hseries.RUN,'BusyAction');
    if isequal(stopstate,'queue') % enable STOP command
        for jfile=1:nbfield2
            OutputFile=name_generator(basename_new,num_i1(jfile,ifile),num_j1(jfile,ifile),'',Series.NomType);
            filename=name_generator(basename,num_i1(jfile,ifile),num_j1(jfile,ifile),Series.FileExt,Series.NomType);
            filename_new=name_generator(basename_new,num_i1(jfile,ifile),num_j1(jfile,ifile),'.png',Series.NomType);
            path_series=[fileparts(which('civ')) '/series'];
            
            filename_bat=[OutputFile '.bat'];
            [fid,message]=fopen(filename_bat,'w');
            if isequal(fid,-1)
                msgbox_uvmat('ERROR', ['creation of .bat file: ' message])
                return
            end
            fprintf(fid,['/opt/matlab/R2011a/bin/matlab -nodisplay -nosplash -r "cd(''' path_series ''');'...
                'A=imread(' filename ');C=levels(A);imwrite(C,' filename_new ');exit"']);
            fclose(fid);
            if isunix
                system(['chmod +x ' filename_bat]);
            end
            batch_file_list{length(batch_file_list)+1}=filename_bat;
        end
    end
end


ncores=1;
walltime_onejob=10;%seconds
filename_joblist=fullfile(path,[subdir_ima '_levels'],'job_list.txt')
fid=fopen(filename_joblist,'w+')
for p=1:length(batch_file_list)
    fprintf(fid,[batch_file_list{p} '\n']);
end
fclose(fid);
oar_command=['oarsub -n ima_levels '...
    '-l /core=' num2str(ncores) ','...
    'walltime=' datestr(1.05*walltime_onejob/86400*max(length(batch_file_list),ncores)/ncores,13) ' '...
    '-E ' regexprep(filename_joblist,'\.txt\>','.errors') ' '...
    '-O ' regexprep(filename_joblist,'\.txt\>','.log') ' '...
    '"oar-parexec -f ' filename_joblist ' -l ' filename_joblist '.log"'];
filename_oarcommand=fullfile(path,[subdir_ima '_levels'],'oar_command');
fid=fopen(filename_oarcommand,'w');
fprintf(fid,[oar_command '\n']);
fclose(fid);
display(oar_command);
eval(['! . ' filename_oarcommand])


