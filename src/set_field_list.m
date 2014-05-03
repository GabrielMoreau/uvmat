%'set_field_list': defines variables needed for the diff fields(velocity, vort, div...) 
%---------------------------------------------------------------------
% [FieldList,VecColorList]=set_field_list(UName,VName,CName)
%
% OUTPUT:
% FieldList: list (cell column) of the fields to propose in the menu FieldName
% VecColorList: list (cell column) of the fields to propose in the menu for vector color
%
% INPUT:
% UName: name of the x vector component
% VName: name of the y vector component
% CName: name of an additional scalar for color
%
% FUNCTION related
% varname_generator.m: determines the field names to read in the netcdf
% file, depending on the scalar

function [FieldList,VecColorList]=set_field_list(UName,VName,CName)

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
if exist('CName','var') && ~isempty(CName)
    VecColorList=[{CName};VecColorList];
end


