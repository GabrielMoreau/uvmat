%'set_field_list': defines variables needed for the diff fields(velocity, vort, div...) 
%---------------------------------------------------------------------
% [FieldList,VecColorList]=set_field_list(UName,VName,CName)
%
% OUTPUT:
% Scal: matlab vector representing the scalar values (length nbvec defined by var_read)
%      if no input, Scal=list of programmed scalar names (to put in menus)
%      if only the field name is put as input, vec_A=type of scalar, which can be:
%                   'discrete': related to the individual velocity vectors, not interpolated by patch
%                   'vel': scalar calculated solely from velocity components
%                   'der': needs spatial derivatives
%                   'var': the scalar name directly corresponds to a field name in the netcdf files
% error: error flag
%      error = 0; OK
%      error = 1; the prescribed scalar cannot be read or calculated from available fields
%
% INPUT:
% FieldList: cell array of strings representing the name(s) of the field(s) to calculate
% DataIn: structure representing the field, as defined in check_field_srtructure.m
% Coord_interp(:,nb_coord) optional set of coordinates to interpolate the field (use with thin plate shell)
%
% FUNCTION related
% varname_generator.m: determines the field names to read in the netcdf
% file, depending on the scalar
function [FieldList,VecColorList]=set_field_list(UName,VName,CName)
%function [DataOut,errormsg]=calc_field(FieldList,DataIn,Coord_interp)

%list of defined scalars to display in menus (in addition to 'ima_cor').
% a type is associated to each scalar:
%              'discrete': related to the individual velocity vectors, not interpolated by patch
%              'vel': calculated from velocity components, continuous field (interpolated with velocity)
%              'der': needs spatial derivatives
%              'var': the scalar name corresponds to a field name in the netcdf files
% a specific variable name for civ1 and civ2 fields are also associated, if
% the scalar is calculated from other fields, as explicited below

FieldList={['vec(' UName ',' VName ')'];...
    ['norm(' UName ',' VName ')'];...
    ['curl(' UName ',' VName ')'];...
    ['div(' UName ',' VName ')'];...
    ['strain(' UName ',' VName ')'];...
    UName;...
    VName};
VecColorList={['norm(' UName ',' VName ')'];...
    UName;...
    VName};...
    if ~isempty(CName)
    VecColorList=[{CName};VecColorList];
    end



% %% list of field options implemented
% FieldList={'vec(U,V)';...%image correlation corresponding to a vel vector
%     'C';...%image correlation corresponding to a vel vector
%     'norm(U,V)';...%norm of the velocity
%     'curl(U,V)';...%vorticity
%     'div(U,V)';...%divergence
%     'strain(U,V)';...%rate of strain
%     'U';... %u velocity component
%     'V';... %v velocity component
%     'W';... %w velocity component
%     'W_normal';... %w velocity component normal to the plane
%     'error'}; %error associated to a vector (for stereo or patch)
% ColorList={'C';...%image correlation corresponding to a vel vector
%     'norm(U,V)';...%norm of the velocity
%     'U';... %u velocity component
%     'V';... %v velocity component
%     }

