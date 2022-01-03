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
% Copyright 2008-2022, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [checkmsg,date_str,svn_info]=check_files
checkmsg={};%default
svn_info.rep_rev=[];
svn_info.cur_rev=[];
svn_info.status=[];
list_fct={...
    'activate';...% emulate the mouse selection of a GUI element, for demo
    'browse_data';...% function for scanning directories in a project/campaign
    'browse_data.fig';...% GUI corresponding to dataview
    'calc_field_interp';...% defines fields (velocity, vort, div...) from civx data and calculate them
    'calc_field_tps';...% defines fields (velocity, vort, div...) and calculate them
    'cell2tab';... %transform a Matlab cell in a character array suitable for display in a table
    'check_files';...
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
    'phys_XYZ';...% transform coordiantes from pixels to phys
    'px_XYZ';...% transform coordiantes from phys to pixels
    'plot_field';...%displays a vector field and/or scalar or images
    'plot_object';...%draws a projection object (points, line, plane...)
    'proj_field';...%project a field on a projection object (plane, line,...)
    'read_civxdata';...reads civx data from netcdf files
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
    'update_waitbar';... update the waitbar display, used for ACTION functions in the GUI 'series'
    'uvmat';...% master function for file scanning and visualisation of 2D fields
    'uvmat.fig';...  %interface for uvmat
    'view_field.m';...% function for visualisation of projected fields'
    'view_field.fig';...%GUI for view_field
    'xml2struct';...% read an xml file as a Matlab structure, converts numeric character strings into numbers
    };
dir_fct=which('uvmat');% path to uvmat
pathuvmat=fileparts(dir_fct);

%% add the uvmat path to matlab if needed
if isempty(regexp(path,[pathuvmat '(:|\>)'],'once'))
    addpath(pathuvmat);
end


%% loop on the list of functions in the uvmat package
icount=0;
if ~exist(fullfile(pathuvmat,'@xmltree'),'dir')
    icount=icount+1;
    checkmsg{icount}='ERROR installation: toolbox xmltree missing';
end
datnum=zeros(1,length(list_fct));
for i=1:length(list_fct)
    dir_fct=which(list_fct{i});% path to fct
    if isempty(dir_fct)
        icount=icount+1;
        checkmsg{icount}=[list_fct{i} ' not found'];% test for function not found
    else
        pth=fileparts(dir_fct);
        if ~isequal(pathuvmat,pth) && ~isequal(fullfile(pathuvmat,'private'),pth)
            icount=icount+1;
            checkmsg{icount}=[dir_fct ' overrides the package UVMAT'];% bad path for the function
        end
        datfile=dir(dir_fct);
        if isfield(datfile,'datenum')
            datnum(i)= datfile.datenum;
        end
    end
end
date_str=datestr(max(datnum));

%% check svn status
[status,result]=system('svn --help');
if status==0 % if a svn line command is available
    svn_info.rep_rev=0;svn_info.cur_rev=0;
    [tild,result]=system(['svn info ' dir_fct]); %get info fromn the svn server
    t=regexp(result,'R.vision\s*:\s*(?<rev>\d+)','names');%detect 'revision' or 'Revision' in the text
    if ~isempty(t)
        svn_info.cur_rev=str2double(t.rev); %version nbre of the current package
    end
    %[tild,result]=system(['svn info -r ''HEAD'' '  pathuvmat]);
    [tild,result]=system(['svn info ''HEAD'' '  pathuvmat]);
    t=regexp(result,'R.vision\s*:\s*(?<rev>\d+)','names');
    if ~isempty(t)
        svn_info.rep_rev=str2double(t.rev); % version nbre available on the svn repository
    end
    [tild,result]=system(['svn status '  pathuvmat]);% '&' prevents the program to stop when the system asks password
    svn_info.status=result;
    checkmsg =[checkmsg {['SVN revision : ' num2str(svn_info.cur_rev)]}];%display version nbre of the current uvmat package
    if svn_info.rep_rev>svn_info.cur_rev %if the repository has a more advanced version than the uvmat package, warning msge
        checkmsg =[checkmsg ...
            {['Repository now at revision ' num2str(svn_info.rep_rev) '. Please type svn update in uvmat folder']}];
    end
    modifications=regexp(svn_info.status,'M\s[^(\n|\>)]+','match');% detect the files modified compared to the repository
    if ~isempty(modifications)
        for ilist=1:numel(modifications)
            [tild,FileName,FileExt]=fileparts(modifications{ilist});
            checkmsg=[checkmsg {[FileName FileExt ' modified']}];
        end
    end
else % no svn line command available
    checkmsg=[checkmsg {'SVN not available'}];
end
checkmsg=checkmsg';

%% check dates of compilation
% currentdir=pwd;
% cd(pathuvmat)
% list_compile=dir('*.sh');
% for ilist=1:numel(list_compile)
%     mfile=regexprep(list_compile(ilist).name,'.sh$','.m');
%     if exist(mfile,'file')
%         datfile=dir(mfile);
%         if ~isempty(datfile) && isfield(datfile,'datenum') && datfile.datenum>list_compile(ilist).datenum
%             checkmsg=[checkmsg;{[list_compile(ilist).name ' needs to be updated by compile_functions']}];
%         end
%     end
% end
% cd(currentdir)

