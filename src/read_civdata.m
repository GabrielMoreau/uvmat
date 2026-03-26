%'read_civdata': reads new civ data from netcdf files
%------------------------------------------------------------------
%
% function [Field,VelTypeOut]=read_civdata(FileName,FieldNames,VelType)
%
% OUTPUT:
% Field: structure representing the selected field, containing
%            .Txt: (char string) error message if any
%            .ListGlobalAttribute: list of global attributes containing:
%                    .NbCoord: number of vector components
%                    .NbDim: number of dimensions (=2 or 3)
%                    .Dt: time interval for the corresponding image pair
%                    .Time: absolute time (average of the initial image pair)
%                    .CivStage: =0, 
%                       =1, civ1 has been performed only
%                       =2, fix1 has been performed
%                       =3, pacth1 has been performed
%                       =4, civ2 has been performed 
%                       =5, fix2 has been performed
%                       =6, pacth2 has been performed
%                     .CoordUnit: 'pixel'
%             .ListVarName: {'X'  'Y'  'U'  'V'  'F'  'FF'}
%                   .X, .Y, .Z: set of vector coordinates 
%                    .U,.V,.W: corresponding set of vector components
%                    .F: warning flags
%                    .FF: error flag, =0 for good vectors
%                     .C: scalar associated with velocity (used for vector colors)
%
% VelTypeOut: velocity type corresponding to the selected field: ='civ1','interp1','interp2','civ2'....
%
% INPUT:
% FileName: file name (string).
% FieldNames =cell of field names to get, which can contain the strings:
% 'U','V','norm(U,V)','curl(U,V)','div(U,V)','strain(U,V)'
% VelType : character string indicating the types of velocity fields to read ('civ1','civ2'...)
%            if vel_type=[] or'*', a  priority choice, given by vel_type_out{1,2}, is done depending 
%            if vel_type='filter'; a structured field is sought (filter2 in priority, then filter1)
%
% FUNCTIONS called: 
% 'varcivx_generator':, sets the names of vaiables to read in the netcdf file 
% 'nc2struct': reads a netcdf file 

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

function [Field,VelTypeOut,errormsg]=read_civdata(FileName,FieldNames,VelType,frame_index)

%% default input
if ~exist('frame_index','var')
    frame_index=1;
end
if ~exist('VelType','var')
    VelType='';
end
if isempty(VelType)||strcmp(VelType,'*')
    VelType='';
end
if ~exist('FieldNames','var') 
    FieldNames={}; %default
end
Field=[];
VelTypeOut=VelType;
errormsg='';
if ischar(FieldNames), FieldNames={FieldNames}; end
ProjModeRequest='';
for ilist=1:length(FieldNames)
    if ~isempty(FieldNames{ilist})
        switch FieldNames{ilist}
            case {'U','V','norm(U,V)'}
                if ~strcmp(FieldNames{1},'vec(U,V)')% if the scalar is not used as color of vectors
                ProjModeRequest='interp_lin';
                end
            case {'curl(U,V)','div(U,V)','strain(U,V)'}
                ProjModeRequest='interp_tps';
        end
    end
end

%% reading data
[Data,~,~,errormsg]=nc2struct(FileName,'ListGlobalAttribute','Conventions','CivStage');% read the global attributes to get Data.CivStage
if ~isempty(errormsg)
     errormsg=['read_civdata: ' errormsg];
    return
end

% set the list of variables to read and their role
CheckCompress=strcmp(Data.Conventions,'uvmat/civdata/compress');
[varlist,role,VelTypeOut]=varcivx_generator(ProjModeRequest,VelType,Data.CivStage,CheckCompress);
if isempty(varlist)
    errormsg=['read_civdata: unknow velocity type ' VelType];
    return
else
    if strcmp(Data.Conventions,'uvmat/civdata_3D')
        [Field,vardetect,~,errormsg]=nc2struct(FileName,'TimeDimName','npz',frame_index,varlist);%read the variables in the netcdf file
    else
        [Field,vardetect,~,errormsg]=nc2struct(FileName,varlist);%read the variables in the netcdf file
    end
end
if ~isempty(errormsg)
     errormsg=['read_civdata: ' errormsg];
    return
end
if vardetect(1)==0
     errormsg=[ 'requested field not available in ' FileName '/' VelType ': need to run patch'];
     return
end
if strcmp(Data.Conventions,'uvmat/civdata/compress')
    Field.X=double(Field.X)-0.5+Field.U/2;% shift to the convected position
    Field.Y=double(Field.Y)-0.5+Field.V/2;
end
switch VelTypeOut
    case {'civ1','filter1'}
        if isfield(Field,'Patch1_SubDomain')
            Field.SubDomain=Field.Patch1_SubDomain;
            Field.ListGlobalAttribute=[Field.ListGlobalAttribute {'SubDomain'}];
        end
        if isfield(Field,'Civ1_Dt')
            Field.Dt=Field.Civ1_Dt;
        end
        if isfield(Field,'Civ1_Time')
            Field.Time=Field.Civ1_Time;
        end
    case {'civ2','filter2'}
        if isfield(Field,'Patch2_SubDomain')
            Field.SubDomain=Field.Patch2_SubDomain;
            Field.ListGlobalAttribute=[Field.ListGlobalAttribute {'SubDomain'}];
        end
        if isfield(Field,'Civ2_Dt')
        Field.Dt=Field.Civ2_Dt;
        end
        if isfield(Field,'Civ2_Time')
        Field.Time=Field.Civ2_Time;
        end
end
Field.ListGlobalAttribute=[Field.ListGlobalAttribute {'Dt','Time'}];
ivar_U_tps=[];
ivar_V_tps=[];
var_ind=find(vardetect);
for ivar=1:numel(var_ind)
    Field.VarAttribute{ivar}.Role=role{var_ind(ivar)};
    %Field.VarAttribute{ivar}.Mesh=0.025;%typical mesh for histograms O.025 pixel (used in series)
    Field.VarAttribute{ivar}.ProjModeRequest=ProjModeRequest;
    if strcmp(role{var_ind(ivar)},'vector_x')
        Field.VarAttribute{ivar}.FieldName=FieldNames;
        ivar_U=ivar;
    end
    if strcmp(role{var_ind(ivar)},'vector_x_tps')
        Field.VarAttribute{ivar}.FieldName=FieldNames;
        ivar_U_tps=ivar;
    end
    if strcmp(role{var_ind(ivar)},'vector_y')
        Field.VarAttribute{ivar}.FieldName=FieldNames;
        ivar_V=ivar;
    end
    if strcmp(role{var_ind(ivar)},'vector_y_tps')
        Field.VarAttribute{ivar}.FieldName=FieldNames;
        ivar_V_tps=ivar;
    end
end
if ~isempty(ivar_U_tps)
    Field.VarAttribute{ivar_U}.VarIndex_tps=ivar_U_tps;
end
if ~isempty(ivar_V_tps)
    Field.VarAttribute{ivar_V}.VarIndex_tps=ivar_V_tps;
end

%% update list of global attributes
Field.ListGlobalAttribute=[Field.ListGlobalAttribute {'NbCoord','NbDim','TimeUnit','CoordUnit'}];
Field.NbCoord=2;
Field.NbDim=2;
Field.TimeUnit='s';
Field.CoordUnit='pixel';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [var,role,units,vel_type_out]=varcivx_generator(FieldNames,vel_type) 
%INPUT:
% FieldNames =cell of field names to get, which can contain the strings:
%             'ima_cor': image correlation, vec_c or vec2_C
%             'vort','div','strain': requires velocity derivatives DUDX...
%             'error': error estimate (vec_E or vec2_E)
%             
% vel_type: character string indicating the types of velocity fields to read ('civ1','civ2'...)
%            if vel_type=[] or'*', a  priority choice is done, civ2 considered better than civ1 )

function [var,role,vel_type_out,errormsg]=varcivx_generator(ProjModeRequest,vel_type,CivStage,CheckCompress) 

%% default input values
if ~exist('vel_type','var'),vel_type='';end
if iscell(vel_type),vel_type=vel_type{1}; end%transform cell to string if needed
errormsg='';
if CivStage>=6
    CivStage=6;
end

%% select the priority order for automatic vel_type selection
if strcmp(ProjModeRequest,'derivatives')&& numel(vel_type)>=3 && strcmp(vel_type(1:3),'civ')
    vel_type=['filter' vel_type(4:end)];
end
if isempty(vel_type)||strcmp(vel_type,'*')
    vel_type='filter2';% case CivStage >=6
    switch CivStage
        case {1,2}% civ1 available but not filter1
            vel_type='civ1';
        case 3
            vel_type='filter1';

        case {4,5}% civ2 available but not filter2
            if strcmp(ProjModeRequest,'derivatives')% derivatives needed
                vel_type='filter1';
            else
                vel_type='civ2';
            end
    end
end

if CheckCompress
    switch vel_type
        case{'civ1','civ2'}
            varout={'X','Y','Z','U','V','W','C','FF'};
            varin= {'X','Y','Z','U','V','W','C','FF'};
            role={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','ancillary','errorflag'};
        case{'filter1','filter2'}
            varout={'X','Y','Z','U','V','W','C','FF'};
            varin={'X','Y','Z','U_smooth','V_smooth','W_smooth','C','FF'};
            role={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','ancillary','errorflag'};
            %  rmq: NbCentres and NbSites obsolete replaced by NbCentre, kept for consistency with previous data
    end
else
    switch vel_type
        case{'civ1','civ2'}
            varout={'X','Y','Z','U','V','W','C','FF'};
            varin= {'Civ1_X','Civ1_Y','Civ1_Z','Civ1_U','Civ1_V','Civ1_W','Civ1_C','Civ1_FF'};
            role={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','ancillary','errorflag'};
        case{'filter1','filter2'}
            varout={'X','Y','Z','U','V','W','C','FF','Coord_tps','U_tps','V_tps','W_tps','SubRange','NbCentre','NbCentre','NbCentre'};
            varin={'Civ1_X','Civ1_Y','Civ1_Z','Civ1_U_smooth','Civ1_V_smooth','Civ1_W','Civ1_C','Civ1_FF',...
                'Civ1_Coord_tps','Civ1_U_tps','Civ1_V_tps','Civ1_W_tps','Civ1_SubRange','Civ1_NbCentre','Civ1_NbCentres','Civ1_NbSites'};
            role={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','ancillary','errorflag','coord_tps','vector_x_tps',...
                'vector_y_tps','vector_z_tps','ancillary','ancillary','ancillary','ancillary'};
            %  rmq: NbCentres and NbSites obsolete replaced by NbCentre, kept for consistency with previous data
    end
    switch vel_type
        case {'civ2','filter2'}
            varin=regexprep(varin,'1','2');
    end
end
var=[varout;varin];
if ~strcmp(ProjModeRequest,'interp_tps')
    var=var(:,1:8);%suppress tps if not needed
end
vel_type_out=vel_type;





