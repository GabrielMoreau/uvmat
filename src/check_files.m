%'check_files': check the path, modification date and svn version for all the
%  function in the toolbox UVMAT. Called at the opening of uvmat. Adds the
%  uvmat path to the Matlab path if needed.
%----------------------------------------------------------------------
% function [errormsg,date_str,ver]=check_files
%
% OUTPUT:
% errormsg: error message listing functions whose paths are not in the directory of uvmat.m
% date_str: date of the most recent modification of a file in the toolbox
% ver : svn version in case this is a  svn repository

%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function [errormsg,date_str,svn_info]=check_files
errormsg={};%default
date_str='';
svn_info.rep_rev=[];
svn_info.cur_rev=[];
svn_info.status=[];
list_fct={...
    'calc_field';...% defines fields (velocity, vort, div...) from civx data and calculate them
    'cell2tab';... %transform a Matlab cell in a character array suitable for display in a table
    'check_field_structure';...% check the validity of the field struture representation consistant with the netcdf format
    'check_files';...
    'civ';...   %function associated with the interface 'civ.fig' for PIV and spline interpolation
    'civ.fig';...
    'civ_3D';... function associated with the interface 'civ_3D.fig' for PIV in volume (TODO: combine with civ.m)
    'civ_3D.fig';...
    'civ_matlab';...% civ programs, Matlab version (called by civ.m, option Civprogram/Matlab in the upper menu bar)
    'close_fig';...% function  activated when a figure is closed
    'copyfields';...% copy fields between two matlab structures
    'create_grid';...% called by the GUI geometry_calib to create a physical grid
    'create_grid.fig';...% GUI corresponding to create_grid.m
    'dataview';...% function for scanning directories in a campaign
    'dataview.fig';...% GUI corresponding to dataview
    'delete_object';...%delete a projection object, defined by its index in the Uvmat list or by its graphic handle
    'editxml';...%display and edit xml files using a xls schema
    'editxml.fig';...%interface for editxml
    'fileparts_uvmat';...% extracts the root name,field indexes and nomenclature type from an input filename
    'find_field_indices';...% group the variables of a nc-formated Matlab structure into 'fields' with common dimensions
    'find_file_series';...%check the content of an input file and find the corresponding file series
    'fullfile_uvmat';...%creates a file name from a root name and indices.
    'geometry_calib';...%performs geometric calibration from a set of reference points
    'geometry_calib.fig';...%interface for geometry_calib
    'get_field';...% choose and plot a field from a Netcdf file
    'get_field.fig';...%interface for get_field
    'griddata_uvmat';...%make 2D linear interpolation using griddata, with input appropriate for both Matlab 6.5 and 7
    'hist_update';...%  update of a current global histogram by inclusion of a new field
    'imadoc2struct';...%convert the image documentation file ImaDoc into a Matlab structure
    'keyboard_callback';... % function activated when a key is pressed on the keyboard
    'ListDir';... scan the structure of the directory tree (for dataview.m)
    'mouse_down';% function activated when the mouse button is pressed on a figure (callback for 'WindowButtonDownFcn')
    'mouse_motion';...% permanently called by mouse motion over a figure (callback for 'WindowButtonMotionFcn')
    'mouse_up';... % function to be activated when the mouse button is released (callback for 'WindowButtonUpFcn')
    'msgbox_uvmat';... associated with GUI msgbox_uvmat.fig to display message boxes, for error, warning or input calls
    'msgbox_uvmat.fig';...
    'nc2struct';...% transform a netcdf file in a corresponding matlab structure
    'num2stra';...% transform number to the corresponding character string depending on the nomenclature
    'open_uvmat';...% open with uvmat the  field selected in the list of 'civ/status' or 'series/check_data_files'
    'peaklock';...%
    'phys_XYZ';...% transform coordiantes from pixels to phys
    'px_XYZ';...% transform coordiantes from phys to pixels
    'plot_field';...%displays a vector field and/or scalar or images
    'plot_object';...%draws a projection object (points, line, plane...)
    'proj_field';...%project a field on a projection object (plane, line,...)
    'read_civxdata';...reads civx data from netcdf files
    'read_civdata';... reads new civ data from netcdf files
    'read_get_field';... read the list of selected variables from the GUI get_field (TODO: use read_GUI)
    'read_GUI';... %read all parameters set by a GUI as a Matlab structure
    'read_imatext';...%read .civ files (obsolete, but can be adapted to other text documentation files) 
    'read_set_object';...%read the data on the set_object interface, TODO: use instead the general function read_GUI
    'read_xls';...%read excel files containing the list of the experiments
    'reinit';...% suppress the personal parameter file 'uvmat_perso.mat'
    'rotate_points';...%'rotate_points': associated with GUI rotate_points.fig to introduce (2D) rotation parameters
    'rotate_points.fig';...
    'RUN_STLIN';...% combine 2 displacement fields for stereo PIV
    'series';...% master function for analysis field series, with interface 'series.fig'
    'series.fig';...% interface for 'series'
    'set_col_vec';...% sets the color code for vectors depending on a scalar and input parameters (used for plot_field)
    'set_grid';...% creates a grid for PIV
    'set_grid.fig';...% interface for set_grid
    'set_object.m';...%  edit a projection object
    'set_object.fig';...% interface for set_object
    'stra2num';...% transform letters (a, b, A, B,) or numerical strings ('1','2'..) to the corresponding numbers
    'sub_field';...% combine the two input fields,
    'struct2nc';...% %write fields in netcdf files
    'struct2xml';... transform a matlab structure to a xml tree.
    'tps_coeff';...% calculate the thin plate spline (tps) coefficients
    'tps_eval';... %calculate the thin plate spline (tps) interpolation at a set of points
    'tps_eval_dxy';...% calculate the derivatives of thin plate spline (tps) interpolation at a set of points (limited to the 2D case)
    'translate_points';...% associated with GUI translate_points.fig to display translation parameters
    'translate_points.fig';...
    'update_imadoc';...  %update the ImaDoc xml file
    'update_obj';... update the object representation graph and its projection field, record it in the uvmat interface
    'update_waitbar';... update the waitbar display, used for ACTION functions in the GUI 'series'
    'uvmat';...% master function for file scanning and visualisation of 2D fields
    'uvmat.fig';...  %interface for uvmat
    'view_field.m';...% function for visualisation of projected fields'
    'view_field.fig';...%GUI for view_field
    'write_plot_param';...%update plotting parameters after plot, TODO: change into a general function: fill_GUI
    'xml2struct';...% read an xml file as a Matlab structure, converts numeric character strings into numbers
    };
dir_fct=which('uvmat');% path to uvmat
[pathuvmat,name,ext]=fileparts(dir_fct);

%% add the uvmat path to matlab if needed
if isempty(regexp(path,[pathuvmat '(:|\>)'],'once'))
    addpath(pathuvmat);
end


%% loop on the list of functions in the uvmat package

icount=0;
datnum=zeros(1,length(list_fct));
for i=1:length(list_fct)
    dir_fct=which(list_fct{i});% path to fct
    if isempty(dir_fct)
        icount=icount+1;
        errormsg{icount}=[list_fct{i} ' not found'];% test for function not found
    else
        [pth,name,ext]=fileparts(dir_fct);
        if ~isequal(pathuvmat,pth)&~isequal(fullfile(pathuvmat,'private'),pth)
            icount=icount+1;
            errormsg{icount}=[dir_fct ' overrides the package UVMAT'];% bad path for the function
        end
        datfile=dir(dir_fct);
        if isfield(datfile,'datenum')
            datnum(i)= datfile.datenum;
        end
    end
end
date_str=datestr(max(datnum));
[status,result]=system('svn --help');
if status==0
    [tild,result]=system(['svn info ' dir_fct]);
    t=regexp(result,'R.vision\s:\s(?<rev>\d+)','names');
    svn_info.cur_rev=str2double(t.rev);
    [tild,result]=system(['svn info -r ''HEAD'' '  dir_fct]);
    t=regexp(result,'R.vision\s:\s(?<rev>\d+)','names');
    svn_info.rep_rev=str2double(t.rev);
    [tild,result]=system(['svn status'  dir_fct]);
    svn_info.status=result;
    if svn_info.rep_rev>svn_info.cur_rev
        errormsg {length(errormsg)+1}=['Repository now at revision ' num2str(svn_info.rep_rev) '. Please type svn update in uvmat folder'];
    end
    modifications=regexp(svn_info.status,'M\s[^(\n|\>)]+','match');
    if ~isempty(modifications)
        for k=1:length(modifications)
            errormsg {length(errormsg)+1}=modifications{k};
        end
    end
end
errormsg=errormsg';

