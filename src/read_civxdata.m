%'read_civxdata': reads civx data from netcdf files
%------------------------------------------------------------------
%
% function [Field,VelTypeOut]=read_civxdata(filename,FieldNames,VelType)
%
% OUTPUT:
% Field: structure representing the selected field, containing
%            .Txt: (char string) error message if any
%            .ListGlobalAttribute: list of global attributes containing:
%                    .NbCoord: number of vector components
%                    .NbDim: number of dimensions (=2 or 3)
%                    .dt: time interval for the corresponding image pair
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
%                    .DijU; matrix of spatial derivatives (DijU(1,1,:)=DUDX,
%                        DijU(1,2,:)=DUDY, Dij(2,1,:)=DVDX, DijU(2,2,:)=DVDY
%
% VelTypeOut: velocity type corresponding to the selected field: ='civ1','interp1','interp2','civ2'....
%
% INPUT:
% filename: file name (string).
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
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [Field,VelTypeOut,errormsg]=read_civxdata(filename,FieldNames,VelType)
errormsg='';
Field=[];
VelTypeOut=[];
DataTest=nc2struct(filename,'ListGlobalAttribute','Conventions','CivStage');
if isfield(DataTest,'Txt')
    errormsg=['nc2struct / ' DataTest.Txt]; 
    return
elseif isequal(DataTest.Conventions,'uvmat/civdata')%test for new civ format
     [Field,VelTypeOut,errormsg]=read_civdata(filename,FieldNames,VelType,DataTest.CivStage);
      if ~isempty(errormsg),errormsg=['read_civdata / ' errormsg];end
     return
end
    
%% default input
if ~exist('VelType','var')
    VelType=[];
end
if isequal(VelType,'*')
    VelType=[];
end
if ~exist('FieldNames','var') 
    FieldNames=[]; %default
end

%% reading data
VelTypeOut=VelType;%default
[var,role,units,vel_type_out_cell]=varcivx_generator(FieldNames,VelType);%determine the names of constants and variables to read
[Field,vardetect,ichoice]=nc2struct(filename,var);%read the variables in the netcdf file
if isfield(Field,'Txt')
    errormsg=['nc2struct / ' Field.Txt];
    return
end
if vardetect(1)==0
     errormsg=[ 'requested field not available in ' filename '/' VelType];
     return
end
var_ind=find(vardetect);
for ilist=1:length(FieldNames)
        testinterp=isempty(regexp(FieldNames{ilist},'(^vec|^C)', 'once'));%test need for gridded data
        if testinterp, break;end
end   
for ivar=1:length(var_ind)
    Field.VarAttribute{ivar}.Role=role{var_ind(ivar)};
    Field.VarAttribute{ivar}.Mesh=0.1;%typical mesh for histograms O.1 pixel
    if strcmp(role{var_ind(ivar)},'vector_x')
        Field.VarAttribute{ivar}.FieldName=FieldNames;
        if testinterp
            Field.VarAttribute{ivar}.ProjModeRequest='interp_lin';
        end
    end
end
VelTypeOut=VelType;
if ~isempty(ichoice)
    VelTypeOut=vel_type_out_cell{ichoice};
end

%% adjust for Djui:
if isfield(Field,'DjUi')
    Field.ListVarName{end-3}='DjUi';
    Field.VarDimName{end-3}=[Field.VarDimName{end-3} {'nb_coord'} {'nb_coord'}];
    Field.ListVarName(end-2:end)=[];
    Field.VarDimName(end-2:end)=[];
    Field.VarAttribute(end-2:end)=[];
end

%% renaming for standard conventions
Field.NbCoord=Field.nb_coord;
Field.NbDim=Field.nb_dim;

%% CivStage
if isfield(Field,'patch2')&& isequal(Field.patch2,1)
    Field.CivStage=6;
elseif isfield(Field,'fix2')&& isequal(Field.fix2,1)
    Field.CivStage=5;
elseif isfield(Field,'civ2')&& isequal(Field.civ2,1)
    Field.CivStage=4; 
elseif isfield(Field,'patch')&& isequal(Field.patch,1)
    Field.CivStage=3; 
elseif isfield(Field,'fix')&& isequal(Field.fix,1)
    Field.CivStage=2;
else
    Field.CivStage=1;
end 

%determine the appropriate constant for time and dt for the PIV pair
test_civ1=isequal(VelTypeOut,'civ1')||isequal(VelTypeOut,'interp1')||isequal(VelTypeOut,'filter1');
test_civ2=isequal(VelTypeOut,'civ2')||isequal(VelTypeOut,'interp2')||isequal(VelTypeOut,'filter2');
Field.Time=0; %default
Field.TimeUnit='s'; 
if test_civ1
    if isfield(Field,'absolut_time_T0')
        Field.Time=double(Field.absolut_time_T0);
        Field.Dt=double(Field.dt);
    else
       errormsg='the input file is not civx'; 
       Field.CivStage=0;
       Field.Dt=0;
    end
elseif test_civ2
    Field.Time=double(Field.absolut_time_T0_2);
    Field.Dt=double(Field.dt2);
else
    errormsg='the input file is not civx';
    Field.CivStage=0;
    Field.Dt=0;
end

%% rescale fields to pixel coordinates
if isfield(Field,'pixcmx')
    Field.pixcmx=double(Field.pixcmx);
    Field.pixcmy=double(Field.pixcmy);
    Field.U=Field.U*Field.pixcmx;
    Field.V=Field.V*Field.pixcmy;
    Field.X=Field.X*Field.pixcmx;
    Field.Y=Field.Y*Field.pixcmy;
end
if ~isequal(Field.Dt,0)
    Field.U=Field.U*Field.Dt;%translate in px displacement
    Field.V=Field.V*Field.Dt;
    if isfield(Field,'DjUi')
       Field.DjUi(:,1,1)=Field.Dt*Field.DjUi(:,1,1);
       Field.DjUi(:,2,2)=Field.Dt*Field.DjUi(:,2,2);
       Field.DjUi(:,1,2)=(Field.pixcmy/Field.pixcmx)*Field.Dt*Field.DjUi(:,1,2);
       Field.DjUi(:,2,1)=(Field.pixcmx/Field.pixcmy)*Field.Dt*Field.DjUi(:,2,1);
    end
end

%% update list of global attributes
List=Field.ListGlobalAttribute;
ind_remove=[];
for ilist=1:length(List)
    switch(List{ilist})
        case {'patch2','fix2','civ2','patch','fix','dt','dt2','absolut_time_T0','absolut_time_T0_2','nb_coord','nb_dim','pixcmx','pixcmy'}
            ind_remove=[ind_remove ilist];
            Field=rmfield(Field,List{ilist});
    end
end
List(ind_remove)=[];
Field.ListGlobalAttribute=[{'NbCoord'},{'NbDim'} List {'Time','Dt','TimeUnit','CivStage','CoordUnit'}];
Field.CoordUnit='pixel';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [var,role,units,vel_type_out]=varcivx_generator(FieldNames,vel_type) 
%INPUT:
% FieldNames =cell of field names to get, which can contain the strings:
%             'C': image correlation, vec_c or vec2_C
%             'curl','div','strain': requires velocity derivatives DUDX...
%             'error': error estimate (vec_E or vec2_E)
%             
% vel_type: character string indicating the types of velocity fields to read ('civ1','civ2'...)
%            if vel_type=[] or'*', a  priority choice, given by vel_type_out{1,2}, is done depending 
%            if vel_type='filter'; a structured field is sought (filter2 in priority, then filter1)

function [var,role,units,vel_type_out]=varcivx_generator(FieldNames,vel_type) 

%% default input values
if ~exist('vel_type','var'),vel_type=[];end;
if iscell(vel_type),vel_type=vel_type{1}; end;%transform cell to string if needed
if ~exist('FieldNames','var'),FieldNames={'C'};end;%default scalar 
if ischar(FieldNames), FieldNames={FieldNames}; end;

%% select the priority order for automatic vel_type selection
testder=0;
for ilist=1:length(FieldNames)
        testder=~isempty(regexp(FieldNames{ilist},'(^curl|^div|^strain)', 'once'));%test need for derivatives
        if testder, break;end
end      
if isempty(vel_type) || isequal(vel_type,'*') %undefined velocity type (civ1,civ2...)
    if testder
         vel_type_out{1}='filter2'; %priority to filter2 for scalar reading, filter1 as second
        vel_type_out{2}='filter1';
    else
        vel_type_out{1}='civ2'; %priority to civ2 for vector reading, civ1 as second priority      
        vel_type_out{2}='civ1';
    end
elseif isequal(vel_type,'filter')
        vel_type_out{1}='filter2'; %priority to filter2 for scalar reading, filter1 as second
        vel_type_out{2}='filter1';
        if ~testder
            vel_type_out{3}='civ1';%civ1 as third priority if derivatives are not needed
        end
elseif testder
    test_civ1=isequal(vel_type,'civ1')||isequal(vel_type,'interp1')||isequal(vel_type,'filter1');
    if test_civ1
        vel_type_out{1}='filter1'; %switch to filter for reading spatial derivatives
    else
        vel_type_out{1}='filter2';
    end
else   
    vel_type_out{1}=vel_type;%imposed velocity field 
end
vel_type_out=vel_type_out';

%% determine names of netcdf variables to read
var={'X','Y','Z','U','V','W','C','F','FF'};
role={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','ancillary','warnflag','errorflag'};
units={'pixel','pixel','pixel','pixel','pixel','pixel',[],[],[]};
if testder
    var=[var {'DjUi(:,1,1)','DjUi(:,1,2)','DjUi(:,2,1)','DjUi(:,2,2)'}];
    role=[role {'tensor','tensor','tensor','tensor'}];
    units=[units {'pixel','pixel','pixel','pixel'}];
end
for ilist=1:length(vel_type_out)
    var=[var;varname1(vel_type_out{ilist},FieldNames)];
end

%------------------------------------------------------------------------  
%--- determine  var names to read
function varin=varname1(vel_type,FieldNames)
%------------------------------------------------------------------------
testder=0;
C1='';
C2='';
for ilist=1:length(FieldNames)
    if ~isempty(FieldNames{ilist})
    switch FieldNames{ilist}
        case 'C' %image correlation corresponding to a vel vector
            C1='vec_C';
            C2='vec2_C';
        case 'error'
            C1='vec_E';
            C2='vec2_E';
        otherwise
          testder=~isempty(regexp(FieldNames{ilist},'(^curl|^div|strain)', 'once'));%test need for derivatives
    end
    end
end      
switch vel_type
    case 'civ1'
        varin={'vec_X','vec_Y','vec_Z','vec_U','vec_V','vec_W',C1,'vec_F','vec_FixFlag'};
    case 'interp1'
        varin={'vec_patch_X','vec_patch_Y','','vec_patch0_U','vec_patch0_V','','','',''};
    case 'filter1'
        varin={'vec_patch_X','vec_patch_Y','','vec_patch_U','vec_patch_V','','','',''};
    case 'civ2'
        varin={'vec2_X','vec2_Y','vec2_Z','vec2_U','vec2_V','vec2_W',C2,'vec2_F','vec2_FixFlag'};
    case 'interp2'
        varin={'vec2_patch_X','vec2_patch_Y','vec2_patch_Z','vec2_patch0_U','vec2_patch0_V','vec2_patch0_W','','',''};
    case 'filter2'
        varin={'vec2_patch_X','vec2_patch_Y','vec2_patch_Z','vec2_patch_U','vec2_patch_V','vec2_patch0_W','','',''};
end
if testder
     switch vel_type
        case 'filter1'
            varin=[varin {'vec_patch_DUDX','vec_patch_DVDX','vec_patch_DUDY','vec_patch_DVDY'}];
        case 'filter2'
            varin=[varin {'vec2_patch_DUDX','vec2_patch_DVDX','vec2_patch_DUDY','vec2_patch_DVDY'}];
    end   
end
