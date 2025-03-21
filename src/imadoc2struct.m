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
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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
%% default input and output
errormsg='';%default
s=[];

%% opening the xml file
[tild,tild,FileExt]=fileparts(ImaDoc);

if nargin ==1
    [s,Heading,errormsg]=xml2struct(ImaDoc);% convert the whole xml file in a structure s
elseif nargin ==2
    [s,Heading,errormsg]=xml2struct(ImaDoc,varargin{1});% convert the xml file in a structure s, keeping only the subtree defined in input
else %TODO: deal with more than two subtrees?
    [s,Heading,errormsg]=xml2struct(ImaDoc,varargin{1},varargin{2});% convert the xml file in a structure s, keeping only the subtree defined in input
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


function [s,errormsg]=read_subtree(subt,Data,NbOccur,NumTest)
%--------------------------------------------------
s=[];%default
errormsg='';
head_element=get(subt,1,'name');
    cont=get(subt,1,'contents');
    if ~isempty(cont)
        for ilist=1:length(Data)
            uid_key=find(subt,[head_element '/' Data{ilist}]);
            if ~isequal(length(uid_key),NbOccur(ilist))
                errormsg=['wrong number of occurence for ' Data{ilist}];
                return
            end
            for ival=1:length(uid_key)
                val=get(subt,children(subt,uid_key(ival)),'value');
                if ~NumTest(ilist)
                    eval(['s.' Data{ilist} '=val;']);
                else
                    eval(['s.' Data{ilist} '=str2double(val);'])
                end
            end
        end
    end


%--------------------------------------------------
%  read an xml element
function val=get_value(t,label,default)
%--------------------------------------------------
val=default;
uid=find(t,label);%find the element iud(s)
if ~isempty(uid) %if the element named label exists
   uid_child=children(t,uid);%find the children 
   if ~isempty(uid_child)
       data=get(t,uid_child,'type');%get the type of child
       if iscell(data)% case of multiple element
           for icell=1:numel(data)
               val_read=str2num(get(t,uid_child(icell),'value'));
               if ~isempty(val_read)
                   val(icell,:)=val_read;
               end
           end
%           val=val';
       else % case of unique element value
           val_read=str2num(get(t,uid_child,'value'));
           if ~isempty(val_read)
               val=val_read;
           else
              val=get(t,uid_child,'value');%char string data
           end
       end
   end
end

%------------------------------------------------------------------------
%'read_imatext': reads the .civ file for image documentation (obsolete)
% fileinput: name of the documentation file 
% time: matrix of times for the set of images
%pxcmx: scale along x in pixels/cm
%pxcmy: scale along y in pixels/cm
function [error,time,TimeUnit,mode,npx,npy,GeometryCalib]=read_imatext(fileinput)
%------------------------------------------------------------------------
error='';%default
time=[]; %default
TimeUnit='s';
mode='pairs';
npx=[]; %default
npy=[]; %default
GeometryCalib=[];
if ~exist(fileinput,'file'), error=['image doc file ' fileinput ' does not exist']; return;end;%input file does not exist
dotciv=textread(fileinput);
sizdot=size(dotciv);
if ~isequal(sizdot(1)-8,dotciv(1,1));
    error=1; %inconsistent number of bursts
end
nbfield=sizdot(1)-8;
npx=(dotciv(2,1));
npy=(dotciv(2,2));
pxcmx=(dotciv(6,1));% pixels/cm in the .civ file 
pxcmy=(dotciv(6,2));
% nburst=dotciv(3,1); % nbre of bursts
abs_time1=dotciv([9:nbfield+8],2);
dtime=dotciv(5,1)*(dotciv([9:nbfield+8],[3:end-1])+1);
timeshift=[abs_time1 dtime];
time=cumsum(timeshift,2);
GeometryCalib.CalibrationType='rescale';
GeometryCalib.R=[pxcmx 0 0; 0 pxcmy 0;0 0 0];
GeometryCalib.Tx=0;
GeometryCalib.Ty=0;
GeometryCalib.Tz=1;
GeometryCalib.dpx=1;
GeometryCalib.dpy=1;
GeometryCalib.sx=1;
GeometryCalib.Cx=0;
GeometryCalib.Cy=0;
GeometryCalib.f=1;
GeometryCalib.kappa1=0;
GeometryCalib.CoordUnit='cm';
