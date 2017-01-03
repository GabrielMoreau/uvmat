%'set_field_list': defines variables needed for the diff fields(velocity, vort, div...) 
%---------------------------------------------------------------------
% [FieldList,VecColorList]=set_field_list(UName,VName,CName)
%
% OUTPUT:
%  FieldList: list (cell column) of the fields to propose in the menu FieldName
%  VecColorList: list (cell column) of the fields to propose in the menu for vector color
%
% INPUT:
%  UName: name of the x vector component
%  VName: name of the y vector component
%  CName: name of an additional scalar for color
%
% RELATED FUNCTIONS:
%  varname_generator.m: determines the field names to read in the netcdf
%  file, depending on the scalar

%=======================================================================
% Copyright 2008-2017, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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


