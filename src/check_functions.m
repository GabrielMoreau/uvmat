%'check_functions': check the path and modification date for all the
%  function in the toolbox UVMAT. Called at the opening of uvmat
%----------------------------------------------------------------------
% function [errormsg,date_str]=check_functions
%
% OUTPUT:
% errormsg: error message listing functions whose paths are not in the directory of uvmat.m
% date_str: date of the most recent modification of a file in the toolbox

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

function [errormsg,date_str]=check_functions
errormsg={};%default
list_fct={'calc_field';...% defines fields (velocity, vort, div...) from civx data and calculate them  
          'cell2tab';... %transform a Matlab cell in a character array suitable for display in a table
          'check_field_structure';...% check the validity of the field struture representation consistant with the netcdf format
          'check_functions';...  
          'civ';...   %function associated with the interface 'civ.fig' for PIV and spline interpolation
          'civ.fig';...
          'civ_3D';... function associated with the interface 'civ_3D.fig' for PIV in volume (in progress) 
          'civ_3D.fig';...
          'close_fig';...% function  activated when a figure is closed
          'copyfields';...% copy fields between two matlab structures
          'create_grid';...% called by the GUI geometry_calib to create a physical grid
          'create_grid.fig';...% GUI corresponding to create_grid.m
          'dataview';...% function for scanning directories in a campaign
          'delete_object';...%delete a projection object, defined by its index in the Uvmat list or by its graphic handle  
          'editxml';...%display and edit xml files using a xls schema
          'editxml.fig';...%interface for editxml
          'find_field_indices';...% group the variables of a nc-formated Matlab structure into 'fields' with common dimensions
          'geometry_calib';...%performs geometric calibration from a set of reference points
          'geometry_calib.fig';...%interface for geometry_calib
          'get_field';...% choose and plot a field from a Netcdf file
          'get_field.fig';...%interface for get_field
          'get_plot_handles';... %provides handles of elements setting the plotting parameters in the uvmat interface
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
          'name2display';...% extracts the root name and field numbers from an input filename 
          'name_generator';...%creates a file name from a root name and indices. 
          'nc2struct';...% transform a netcdf file in a corresponding matlab structure
          'peaklock';...%
          'plot_field';...%displays a vector field and/or scalar or images
          'plot_object';...%draws a projection object (points, line, plane...)
          'proj_field';...%project a field on a projection object (plane, line,...)
          'read_civxdata';...reads civx data from netcdf files
          'read_imatext';...%read .civ files (obsolete, but can be adapted to other text documentation files)
           'read_plot_param';... %read the plotting option parameters on the uvmat interface
           'read_set_object';...%read the data on the set_object interface
           'read_xls';...%read excel files containing the list of the experiments
           'reinit';...% suppress the personal parameter file 'uvmat_perso.mat' 
           'RUN_FIX';...% fix velocity fields
           'RUN_STLIN';...% combine 2 displacement fields for stereo PIV
           'series';...% master function for analysis field series, with interface 'series.fig'
           'series.fig';...% interface for 'series'
           'set_col_vec';...
           'set_grid';...% creates a grid for PIV
           'set_grid.fig';...% interface for set_grid
           'set_object.m';...%  edit a projection object
           'set_object.fig';...% interface for set_object
           'sub_field';...% combine the two input fields, 
           'struct2nc';...% %write fields in netcdf files
           'uvmat';...% master function for file scanning and visualisation of 2D fields
           'uvmat.fig';...  %interface for uvmat  
           'update_imadoc';...  %update the ImaDoc xml file 
           'update_obj';... update the object representation graph and its projection field, record it in the uvmat interface
           'update_waitbar';... update the waitbar display, used for ACTION functions in the GUI 'series'
            'write_plot_param'};%update plotting parameters after plot 
 dir_fct=which('uvmat');% path to uvmat
[pathuvmat,name,ext]=fileparts(dir_fct);
icount=0;
% loop on the list of functions in the uvmat package
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
       date_str=datfile.date;%string of the date of last modification
       datnum(i)=0;%default
       try 
           datnum(i)=datenum(date_str);
       catch
           datnum(i)=0;%in case of error with datenum (e.g. date in french)
       end
   end
end
errormsg=errormsg';
date_str=datestr(max(datnum));
