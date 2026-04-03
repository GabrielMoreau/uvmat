%'check_files': check the path, modification date and svn version for all the
%  function in the toolbox UVMAT. Called at the opening of uvmat. Adds the
%  uvmat path to the Matlab path if needed.
%----------------------------------------------------------------------
% function [msg_checklist,date_str,list_fct_uvmat]=check_files
%
% OUTPUT:
% msg_checklist: message listing functions whose are not in the directory of uvmat.m or have been modified since the git pull
% date_str: date of the most recent git pull
% ver : svn version in case this is a  svn repository
% list_fct_uvmat: list of key functions used in the main folder and series folder

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

function [msg_checklist,date_str,list_fct_uvmat]=check_files
msg_checklist={};%default

dir_uvmat=which('uvmat');% full name of uvmat.m, including its detected path
pathuvmat=fileparts(dir_uvmat);% path to the folder containing uvmat.m

%% check the info about git 
HeadFile=fullfile(pathuvmat,'.git','FETCH_HEAD');
if exist(HeadFile,'file')~=2
    HeadFile=fullfile(pathuvmat,'.git','HEAD');% case of first git clone, FETCH_HEAD created only during update (command git pull)
end
date_str='';
if exist(HeadFile,'file')% check the existence of GIT info
    datfile=dir(HeadFile);
    if isfield(datfile,'datenum')
        dathead= datfile.datenum;
        date_str=datestr(dathead);%string for date display
    end
end

%% add the uvmat path to list of matlab path if needed (will maintain the path to uvmat even after a change of working directory)
if isempty(regexp(path,[pathuvmat '(:|\>)'],'once'))
    addpath(pathuvmat);
end

%% check the existence of the subdir xmltree and series for reading writing xml files
if ~exist(fullfile(pathuvmat,'@xmltree'),'dir')
    msg_checklist{1}='ERROR installation: toolbox xmltree missing';
end
CheckSeries=true;
if ~exist(fullfile(pathuvmat,'series'),'dir')
    CheckSeries=false;
    msg_checklist{1}='ERROR installation: sub-folder series missing';
end

%% list of fcts needed for UVMAT
list_fct_uvmat={...
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
    'concentration';...%transform LIF images to dye concentration images
    'copyfields';...% copy fields between two matlab structures
    'create_grid';...% called by the GUI geometry_calib to create a physical grid
    'create_grid.fig';...% GUI corresponding to create_grid.m
    'dir_scan';... % scan the structure of the directory tree (for editxml.m)
    'disp_uvmat';...% display a message using  msgbox_uvmat or on the log file in batch mode
    'editxml';...% display and edit xml files using a xls schema
    'editxml.fig';...% interface for editxml
    'exist_file.m';...% check the existence of an input file, or  web source OpenDap
    'fileparts_uvmat';...% extracts the root name,field indexes and nomenclature type from an input filename
    'fill_GUI';...%  fill a GUI with a set of parameters from a Matlab structure 
    'filter_tps';...% find the thin plate spline coefficients for interpolation-smoothing (2D fields)
    'filter_tps_3D';... find the thin plate spline coefficients for interpolation-smoothing of 3D fields
    'find_field_bounds';... % find the boounds and typical meshs of coordinates
    'find_field_cells';...% group the variables of a 'field object' into 'field cells' and specify their structure
    'find_file_series';...% check the content of an input file and find the corresponding file series
    'find_imadoc';...% find the ImaDoc xml file associated with a given input file
    'fullfile_uvmat';...% creates a file name from a root name and indices.
    'geometry_calib';...% performs geometric calibration from a set of reference points
    'geometry_calib.fig';...% interface for geometry_calib
    'get_background_name';...% determine the name of the background file for frame indices i_index and j_index
    'get_field';...% choose and plot a field from a Netcdf file
    'get_field.fig';...%interface for get_field
    'get_file_index';... determine the frame indexes from ref indices and pair option for civ
    'get_file_info';...% determine info about a file (image, multimage, civdata,...) .
    'get_file_series';...% determine the list of file names and file indices for functions called by 'series'.
    'get_mask_name';...% determine the name of the mask file for frame indices i_index and j_index
    'hist_update';...%  update of a current global histogram by inclusion of a new field
    'imadoc2struct';...%convert the image documentation file ImaDoc into a Matlab structure
    'index2filename';...translate logical indices i1, j1, into file name and frame index in 'relabel' mode
    'ini2struct';...% reading tool for image files of RDvision
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
    'phys_XYZ';...% transform coordinates from pixels to phys
    'phys_ima';...% transform several images in phys coordinates on a common pixel grid
    'px_XYZ';...% transform coordiantes from phys to pixels
    'plot_field';...%displays a vector field and/or scalar or images
    'plot_object';...%draws a projection object (points, line, plane...)
    'proj_field';...%project a field on a projection object (plane, line,...)
    'proj_grid';... % project  fields with unstructured coordinantes on a regular grid
    'read_civdata';... reads new civ data from netcdf files
    'read_field';...% read the fields from files in different formats (netcdf files, images, video)
    'read_GUI';... %read a GUI and provide the data as a Matlab structure
    'read_image';...%read images or video objects
    'read_multimadoc';... %read a set of Imadoc files and compare their timing of different file series
    'read_xls';...%read excel files containing the list of the experiments
    'rename_indexing';...% add an index to a name, or increment an existing index, if the proposed Name (char string) already exists in the list ListName (cell)
    'rodrigues';...Transform rotation matrix into rotation vector and viceversa (from JEAN-YVES BOUGUET, Caltech)
    'script_reinit';...% suppress the personal parameter file 'uvmat_perso.mat'
    'rotate_points';...%'rotate_points': associated with GUI rotate_points.fig to introduce (2D) rotation parameters
    'rotate_points.fig';...
    'rotate_vector';...%calculate the components of the unit vector norm_plane normal to the plane
    'round_uvmat';...% provide a simple round value of Val of the form  1, 2 , 5 *10^n
    'series';...% master function for analysis field series, with interface 'series.fig'
    'series.fig';...% interface for 'series'
    'set_col_vec';...% sets the color code for vectors depending on a scalar and input parameters (used for plot_field)
    'set_field_list';...% set the menu of input fields
    'set_grid';...% creates a grid for PIV
    'set_grid.fig';...% interface for set_grid
    'set_object.m';...%  edit a projection object
    'set_object.fig';...% interface for set_object
    'set_param_input';... set input parameters for 'transform' functions
    'set_slices.mlapp';% creates illumination slices in 3D context
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
check_path=false(numel(list_fct_uvmat),1);%initiate flag for warning
msg_path=cell(numel(list_fct_uvmat),1);% initiate warning messages for function path
for ilist=1:numel(list_fct_uvmat)
    fullname_fct=which(list_fct_uvmat{ilist});% full name of fct, including its current path in matlab
    if isempty(fullname_fct)
        check_path(ilist)=true; % warning found
        msg_path{ilist}=[list_fct_uvmat{ilist} ' not found'];% warning msg for function not found
    else
        pth=fileparts(fullname_fct);% matlab path found for the listed fct
        if ~strcmp(pathuvmat,pth) %&& ~strcmp(fullfile(pathuvmat,'private'),pth)
            check_path(ilist)=true; % warning found
            msg_path{ilist}=['''' fullname_fct ''' overrides UVMAT'];% path for the function differs from uvmat
        elseif ~isempty(date_str)
            datfile=dir(fullname_fct);
            if isfield(datfile,'datenum')
                if datfile.datenum - dathead>0.0002 % less than 17 s between HEAD and file writting
                    check_path(ilist)=true;
                    msg_path{ilist}=['''' list_fct_uvmat{ilist} '''  changed since git pull'];% fct has changed since git pull
                end
            end
        end
    end
end
msg_path=msg_path(check_path);
msg_checklist=[msg_checklist;msg_path];

%% check functions in series
if CheckSeries
    list_fct_series={...
        'aver_stat';...% calculate field average over a time series
        'calc_background';... %calculate image background by sorting luminosity in sub-series blocks
        'check_data_files';...% check the existence, type and status of the input data files selected by the GUI series
        'civ2vel_3C';... %combine the civ velocity fields from two cameras to get three velocity components
        'civ_input.fig';...
        'civ_input';...%function associated with the GUI 'civ_input.fig' to set the input parameters for civ_series
        'merge_proj';...% concatene several fields from series, can project them on a regular grid in phys coordinates
        'time_series'...% extract a time series after projection on an object (points , line..)
        };
    current_dir=pwd;
    pathseries=fullfile(pathuvmat,'series');
    cd(pathseries)
    check_path=false(numel(list_fct_series),1);%initiate flag for warning
    msg_path=cell(numel(list_fct_series),1);% initiate warning messages for function path
    for ilist=1:numel(list_fct_series)
        fullname_fct=which(list_fct_series{ilist});% full name of fct, including its current path in matlab
        if isempty(fullname_fct)
            check_path(ilist)=true; % warning found
            msg_path{ilist}=['''series/' list_fct_series{ilist} ''' not found'];% warning msg for function not found
        else
            pth=fileparts(fullname_fct);% matlab path found for the listed fct
            if ~strcmp(pathseries,pth) %&& ~strcmp(fullfile(pathuvmat,'private'),pth)
                check_path(ilist)=true; % warning found
                msg_path{ilist}=['''' fullname_fct ''' overrides UVMAT'];% path for the function differs from uvmat
            elseif ~isempty(date_str)
                datfile=dir(fullname_fct);
                if isfield(datfile,'datenum')
                    if datfile.datenum - dathead>0.0002 % less than 17 s between HEAD and file writting
                        check_path(ilist)=true;
                        msg_path{ilist}=['''series/' list_fct_series{ilist} ''' changed since last git update'];% fct has changed since git pull
                    end
                end
            end
        end
    end
    list_fct_uvmat=[list_fct_uvmat;list_fct_series];
    msg_path=msg_path(check_path);
    cd(current_dir)
end
msg_checklist=[msg_checklist;{''};msg_path];


%% check status of GIT
% current_dir=pwd;
% cd(pathuvmat)
% [status,git_msg]=system('git rev-list --count HEAD');% gives the revision number available 
% if status==0 % GIT detected
%     msg_checklist =[msg_checklist ;
%              {['Repository now at revision ' git_msg ]}];
%     [~,svn_info_status]=system('git status');
%     t=regexp(svn_info_status,'modified:\s+(?<modif_files>\w+.\w+)','names');% look for modified files
%     list_modified=squeeze(struct2cell(t));
%     if ~isempty(list_modified)
%         list_modified=['files modified with respect to the GIT source:';list_modified];% add the title
%     end
%     msg_checklist =[msg_checklist ;list_modified];
%     % svn_info.cur_rev=[]; %TODO: how to get the current revision version of the package ?
% else % no svn line command available
%     msg_checklist=[msg_checklist ;{'GIT sources not available'}];
% end
% cd(current_dir)



