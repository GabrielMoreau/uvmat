%'check_files': check the path, modification date and svn version for all the
%  function in the toolbox UVMAT. Called at the opening of uvmat. Adds the
%  uvmat path to the Matlab path if needed.
%----------------------------------------------------------------------
% function [checkmsg,date_str,ver]=check_files
%
% OUTPUT:
% checkmsg: error message listing functions whose paths are not in the directory of uvmat.m
% date_str: date of the most recent modification of a file in the toolbox
% ver : svn version in case this is a  svn repository

%=======================================================================
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function [checkmsg,date_str,list_fct]=check_files
checkmsg={};%default
svn_info.rep_rev=[];
svn_info.cur_rev=[];
svn_info.status=[];

dir_uvmat=which('uvmat');% full name of uvmat.m, including its detected path
pathuvmat=fileparts(dir_uvmat);% path to the folder containing uvmat.m

%% add the uvmat path to list of matlab path if needed (will maintain the path to uvmat even after a change of working directory)
if isempty(regexp(path,[pathuvmat '(:|\>)'],'once'))
    addpath(pathuvmat);
end

%% check the existence of the subdir xmltree for reading writing xml files
if ~exist(fullfile(pathuvmat,'@xmltree'),'dir')
    checkmsg{1}='ERROR installation: toolbox xmltree missing';
end

%% list of fcts needed for UVMAT
list_fct={...
    'activate';...% emulate the mouse selection of a GUI element, for demo
    'angle2normal';...%rotation vector PlaneAngle (in degree) 
    'browse_data';...% function for scanning directories in a project/campaign
    'browse_data.fig';...% GUI corresponding to dataview
    'calc_field_interp';...% defines fields (velocity, vort, div...) from civx data and calculate them
    'calc_field_tps';...% defines fields (velocity, vort, div...) and calculate them
    'cell2tab';... %transform a Matlab cell in a character array suitable for display in a table
    'check_files';...
    'civ';... % key function  for image correlations (called by series/cvi_series.m)
    'cluster_command_LEGI';...% creates the command string for launching jobs in the cluster system 'oar'. 
    'command_launch_matlab';% creates the command strings for opening a new Matlab session
    'command_load_python';% creates the command strings for loading Python
    'compile';...% compile a Matlab function, create a binary in a subdirectory /bin
    'copyfields';...% copy fields between two matlab structures
    'create_grid';...% called by the GUI geometry_calib to create a physical grid
    'create_grid.fig';...% GUI corresponding to create_grid.m
    'dir_scan';... % scan the structure of the directory tree (for editxml.m)
    'disp_uvmat';...% display a message using  msgbox_uvmat or on the log file in batch mode
    'editxml';...% display and edit xml files using a xls schema
    'editxml.fig';...% interface for editxml
    'fileparts_uvmat';...% extracts the root name,field indexes and nomenclature type from an input filename
    'fill_GUI';...%  fill a GUI with a set of parameters from a Matlab structure 
    'filter_tps';...% find the thin plate spline coefficients for interpolation-smoothing
    'find_field_bounds';... % find the boounds and typical meshs of coordinates
    'find_field_cells';...% group the variables of a 'field object' into 'field cells' and specify their structure
    'find_file_series';...% check the content of an input file and find the corresponding file series
    'find_imadoc';...% find the ImaDoc xml file associated with a given input file
    'fullfile_uvmat';...% creates a file name from a root name and indices.
    'geometry_calib';...% performs geometric calibration from a set of reference points
    'geometry_calib.fig';...% interface for geometry_calib
    'get_field';...% choose and plot a field from a Netcdf file
    'get_field.fig';...%interface for get_field
    'get_file_info';...% determine info about a file (image, multimage, civdata,...) .
    'get_file_series';...% determine the list of file names and file indices for functions called by 'series'.
    'hist_update';...%  update of a current global histogram by inclusion of a new field
    'imadoc2struct';...%convert the image documentation file ImaDoc into a Matlab structure
    'interp2_uvmat';...% linearly interpolate an image or scalar defined on a regular grid
    'keyboard_callback';... % function activated when a key is pressed on the keyboard
    'mask_proj';...% restrict input fields to a mask region, set to 0 outside 
    'mouse_down';% function activated when the mouse button is pressed on a figure (callback for 'WindowButtonDownFcn')
    'mouse_motion';...% permanently called by mouse motion over a figure (callback for 'WindowButtonMotionFcn')
    'mouse_up';... % function to be activated when the mouse button is released (callback for 'WindowButtonUpFcn')
    'msgbox_uvmat';... % associated with GUI msgbox_uvmat.fig to display message boxes, for error, warning or input calls
    'msgbox_uvmat.fig';...
    'nomtype2pair';... creates nomenclature for index pairs knowing the image nomenclature, used by series fct
    'nc2struct';...% transform a netcdf file in a corresponding matlab structure
    'num2stra';...% transform number to the corresponding character string depending on the nomenclature
    'parciv';... % same as civ.m, but for loop replaced by 'parfor' for parallel computing on local computer
    'phys_XYZ';...% transform coordiantes from pixels to phys
    'px_XYZ';...% transform coordiantes from phys to pixels
    'plot_field';...%displays a vector field and/or scalar or images
    'plot_object';...%draws a projection object (points, line, plane...)
    'proj_field';...%project a field on a projection object (plane, line,...)
    'read_civdata';... reads new civ data from netcdf files
    'read_field';...% read the fields from files in different formats (netcdf files, images, video)
    'read_GUI';... %read a GUI and provide the data as a Matlab structure
    'read_image';...%read images or video objects
    'read_multimadoc';... %read a set of Imadoc files and compare their timing of different file series
    'read_xls';...%read excel files containing the list of the experiments
    'reinit';...% suppress the personal parameter file 'uvmat_perso.mat'
    'rotate_points';...%'rotate_points': associated with GUI rotate_points.fig to introduce (2D) rotation parameters
    'rotate_points.fig';...
    'series';...% master function for analysis field series, with interface 'series.fig'
    'series.fig';...% interface for 'series'
    'set_col_vec';...% sets the color code for vectors depending on a scalar and input parameters (used for plot_field)
    'set_field_list';...% set the menu of input fields
    'set_grid';...% creates a grid for PIV
    'set_grid.fig';...% interface for set_grid
    'set_object.m';...%  edit a projection object
    'set_object.fig';...% interface for set_object
    'set_slices.mlapp';% creates illumination slices in 3D context
    'set_subdomains';...% sort a set of points defined by scattered coordinates in subdomains, as needed for tps interpolation
    'stra2num';...% transform letters (a, b, A, B,) or numerical strings ('1','2'..) to the corresponding numbers
    'sub_field';...% combine the two input fields,
    'struct2nc';...% %write fields in netcdf files
    'struct2xml';... transform a matlab structure to a xml tree.
    'tps_coeff';...% calculate the thin plate spline (tps) coefficients
    'tps_coeff_field';...% calculate the thin plate spline (tps) coefficients with subdomains for a field structure
    'tps_eval';... %calculate the thin plate spline (tps) interpolation at a set of points
    'tps_eval_dxy';...% calculate the derivatives of thin plate spline (tps) interpolation at a set of points (limited to the 2D case)
    'translate_points';...% associated with GUI translate_points.fig to display translation parameters
    'translate_points.fig';...
    'uigetfile_uvmat';... browser, and display of directories, faster than the Matlab fct uigetfile
    'update_imadoc';...  %update the ImaDoc xml file
    'uvmat';...% master function for file scanning and visualisation of 2D fields
    'uvmat.fig';...  %interface for uvmat
    'view_field.m';...% function for visualisation of projected fields'
    'view_field.fig';...%GUI for view_field
    'xml2struct';...% read an xml file as a Matlab structure, converts numeric character strings into numbers
    };


%% check the existence, path and latest modification of the functions needed  for the uvmat package
datnum=zeros(numel(list_fct),1);%initiate date of fct files
check_warning=false(numel(list_fct),1);%initiate flag for warning
checkmsg_fct=cell(numel(list_fct),1);% initiate warning messages for functions
for ilist=1:numel(list_fct)
    fullname_fct=which(list_fct{ilist});% full name of fct, including its current path in matlab
    if isempty(fullname_fct)
        check_warning(ilist)=true; % warning found
        checkmsg_fct{ilist}=[list_fct{ilist} ' not found'];% warning msg for function not found
    else
        pth=fileparts(fullname_fct);% matlab path found for the listed fct
        if ~strcmp(pathuvmat,pth) && ~strcmp(fullfile(pathuvmat,'private'),pth)
            check_warning(ilist)=true; % warning found
            checkmsg_fct{ilist}=[fullname_fct ' overrides UVMAT'];% path for the function differs from uvmat
        end
        datfile=dir(fullname_fct);
        if isfield(datfile,'datenum')
            datnum(ilist)= datfile.datenum;
        end
    end
end
checkmsg_fct=checkmsg_fct(check_warning);
checkmsg=[checkmsg;checkmsg_fct];
date_str=datestr(max(datnum));% date of the latest modification


%% check status of GIT
current_dir=pwd;
cd(pathuvmat)
[status,git_msg]=system('git rev-list --count HEAD');% gives the revision number available 
if status==0 % GIT detected
    checkmsg =[checkmsg ;
             {['Repository now at revision ' git_msg ]}];
    [~,svn_info_status]=system('git status');
    t=regexp(svn_info_status,'modified:\s+(?<modif_files>\w+.\w+)','names');% look for modified files
    list_modified=squeeze(struct2cell(t));
    if ~isempty(list_modified)
        list_modified=['files modified with respect to the GIT source:';list_modified];% add the title
    end
    checkmsg =[checkmsg ;list_modified];
    % svn_info.cur_rev=[]; %TODO: how to get the current revision version of the package ?
else % no svn line command available
    checkmsg=[checkmsg ;{'GIT sources not available'}];
end
cd(current_dir)

%% check svn status
%[status,result]=system('svn --help');
% if status==0 % if a svn line command is available
%     svn_info.rep_rev=0;svn_info.cur_rev=0;
%     [tild,result]=system(['svn info ' dir_fct]); %get info fromn the svn server
%     t=regexp(result,'R.vision\s*:\s*(?<rev>\d+)','names');%detect 'revision' or 'Revision' in the text
%     if ~isempty(t)
%         svn_info.cur_rev=str2double(t.rev); %version nbre of the current package
%     end
%     %[tild,result]=system(['svn info -r ''HEAD'' '  pathuvmat]);
%     [tild,result]=system(['svn info ''HEAD'' '  pathuvmat]);
%     t=regexp(result,'R.vision\s*:\s*(?<rev>\d+)','names');
%     if ~isempty(t)
%         svn_info.rep_rev=str2double(t.rev); % version nbre available on the svn repository
%     end
%     [tild,result]=system(['svn status '  pathuvmat]);% '&' prevents the program to stop when the system asks password
%     svn_info.status=result;
%     checkmsg =[checkmsg {['SVN revision : ' num2str(svn_info.cur_rev)]}];%display version nbre of the current uvmat package
%     if svn_info.rep_rev>svn_info.cur_rev %if the repository has a more advanced version than the uvmat package, warning msge
%         checkmsg =[checkmsg ...
%             {['Repository now at revision ' num2str(svn_info.rep_rev) '. Please type svn update in uvmat folder']}];
%     end
%     modifications=regexp(svn_info.status,'M\s[^(\n|\>)]+','match');% detect the files modified compared to the repository
%     if ~isempty(modifications)
%         for ilist=1:numel(modifications)
%             [tild,FileName,FileExt]=fileparts(modifications{ilist});
%             checkmsg=[checkmsg {[FileName FileExt ' modified']}];
%         end
% %     end
% else % no svn line command available
%     checkmsg=[checkmsg {'SVN not available'}];
% end
%checkmsg=checkmsg';


