%'imadoc2struct': reads the xml file for image documentation 
%------------------------------------------------------------------------
% function [s,errormsg]=imadoc2struct(ImaDoc,option) 
%
% OUTPUT:
% s: structure representing ImaDoc
%   s.Heading: information about the data hierarchical structure
%   s.Time: matrix of times, note that s.Time(i+1,j+1) is the time for file indices i and j (in order to deal with index 0)
%   s.TimeUnit
%  s.GeometryCalib: substructure containing the parameters for geometric calibration
% errormsg: error message
%
% INPUT:
% ImaDoc: full name of the xml input file with head key ImaDoc
% varargin: optional list of strings to restrict the reading to a selection of subtrees, for instance 'GeometryCalib' (save time) 

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

function [s,errormsg]=imadoc2struct(ImaDoc,varargin) 

s=[]; %default output

%% opening the xml file
if nargin ==1% no additional input variable beyond 'ImaDoc'
    [s,Heading,errormsg]=xml2struct(ImaDoc);% convert the whole xml file in a structure s
elseif nargin ==2 %one additional input variable beyond 'ImaDoc'specifying the subtree to read
    [s,Heading,errormsg]=xml2struct(ImaDoc,varargin{1});% convert the xml file in a structure s, keeping only the subtree defined in input
else % case of two subtrees, TODO: deal with more than two subtrees?
    [s,Heading,errormsg]=xml2struct(ImaDoc,varargin{1},varargin{2});% convert the xml file in a structure s, keeping only the two subtrees defined in input
end
if ~isempty(errormsg)
    errormsg=['error in reading ImaDoc xml file: ' errormsg];
    return
end
if ~strcmp(Heading,'ImaDoc')
    errormsg='imadoc2struct/the input xml file is not ImaDoc';
    return
end

%% reading timing
if isfield(s,'Camera')
    if isfield(s.Camera,'TimeUnit')
        s.TimeUnit=s.Camera.TimeUnit;
    end
    if ~isfield(s.Camera,'FirstFrameIndexI')
        s.Camera.FirstFrameIndexI=1; %first index assumed equl to 1 by default
    end
    s.Time=xmlburst2time(s.Camera.BurstTiming,s.Camera.FirstFrameIndexI);
end

