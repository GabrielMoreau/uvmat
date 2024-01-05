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
%             'ima_cor': image correlation, vec_c or vec2_C
%             'vort','div','strain': requires velocity derivatives DUDX...
%             'error': error estimate (vec_E or vec2_E)
%             
% VelType : character string indicating the types of velocity fields to read ('civ1','civ2'...)
%            if vel_type=[] or'*', a  priority choice, given by vel_type_out{1,2}, is done depending 
%            if vel_type='filter'; a structured field is sought (filter2 in priority, then filter1)
%
% FUNCTIONS called: 
% 'varcivx_generator':, sets the names of vaiables to read in the netcdf file 
% 'nc2struct': reads a netcdf file 

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

function [Field,VelTypeOut,errormsg]=read_pivdata_fluidimage(FileName,FieldNames,VelType)

%% default input
if ~exist('VelType','var')
    VelType='';
end
if isequal(VelType,'*')
    VelType='';
end
if isempty(VelType)
    VelType='';
end
if ~exist('FieldNames','var') 
    FieldNames=[]; %default
end
Field=[];
VelTypeOut=VelType;
errormsg='';
if ~exist(FileName,'file')
    errormsg=['input file ' FileName ' does not exist'];
    return
end
if ischar(FieldNames), FieldNames={FieldNames}; end;
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


% Data=nc2struct(FileName,'ListGlobalAttribute','CivStage');
% if isfield(Data,'Txt')
%      erromsg=['error in read_civdata: ' Data.Txt];
%     return
% end
% % set the list of variables to read and their role
%[varlist,role,VelTypeOut]=varcivx_generator(ProjModeRequest,VelType,Datasets.CivStage);
% if isempty(varlist)
%     erromsg=['error in read_civdata: unknow velocity type ' VelType];
%     return
% else
Datasets=hdf5load(FileName);%read the variables in the netcdf file
%[varlist,role,VelTypeOut]=varcivx_generator(ProjModeRequest,VelType,Datasets.CivStage);
role={'coord_x','coord_y','vector_x','vector_y','ancillary','warnflag','errorflag'};
vardetect=ones(size(role));
Field.ListGlobalAttribute= {'Dt','Time','CivStage'};
Field.Dt=1;
Field.Time=0;
if isfield(Datasets, 'piv1')
    Field.CivStage=6;
else
    Field.CivStage=3;
end
VelTypeOut=VelType;
switch VelType
    case {'civ1','filter1'}
        Data=Datasets.piv0;
        VelTypeOut='filter1';
    case {'civ2','filter2'}
        Data=Datasets.piv1;
        VelTypeOut='filter2';
    case ''
        if isfield(Datasets, 'piv1')
            Data=Datasets.piv1;
            VelTypeOut='filter2';
        else
            Data=Datasets.piv0;
            VelTypeOut='filter1';
        end 
end
switch VelType
    case {'civ1','civ2'}
        Field.X= double(Data.xs);
        Field.Y= double(Data.ys);
        Field.U= double(Data.deltaxs);
        Field.U(isnan(Field.U)) = 0;
        Field.V= double(Data.deltays);
        Field.V(isnan(Field.V)) = 0;
    case {'filter1','filter2',''}
        Field.X= double(Data.ixvecs_final);
        Field.Y= double(Data.iyvecs_final);
        Field.U= double(Data.deltaxs_final);
        Field.U(isnan(Field.U)) = 0;
        Field.V= double(Data.deltays_final);
        Field.V(isnan(Field.V)) = 0;
end
Field.ListVarName={'X'  'Y'  'U'  'V'  'C'  'F'  'FF'};
Field.VarDimName={'nb_vec' 'nb_vec' 'nb_vec' 'nb_vec' 'nb_vec' 'nb_vec' 'nb_vec'};
Field.C = double(Data.correls_max);
Field.F=zeros(size(Field.U)); Field.F(Data.errors.keys + 1)=1; % !!! convention matlab vs python
Field.FF=zeros(size(Field.U)); Field.FF(Data.errors.keys + 1)=1;
% if vardetect(1)==0
%      errormsg=[ 'requested field not available in ' FileName '/' VelType ': need to run patch'];
%      return
% end
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
%Field.ListGlobalAttribute=[Field.ListGlobalAttribute {'Dt','Time'}];
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
