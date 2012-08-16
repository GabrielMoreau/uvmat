%'read_civdata': reads new civ data from netcdf files
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


% FUNCTIONS called: 
% 'varcivx_generator':, sets the names of vaiables to read in the netcdf file 
% 'nc2struct': reads a netcdf file 

function [Field,VelTypeOut,errormsg]=read_civdata(filename,FieldNames,VelType,CivStage)

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
errormsg='';
if ischar(FieldNames), FieldNames={FieldNames}; end;
FieldRequest='';
for ilist=1:length(FieldNames)
    if ~isempty(FieldNames{ilist})
        switch FieldNames{ilist}
            case{'U','V','norm(U,V)'}
                FieldRequest='interp_lin';
            case {'curl(U,V)','div(U,V)','strain(U,V)'}
                FieldRequest='interp_tps';
        end
    end
end

%% reading data
[varlist,role,VelTypeOut]=varcivx_generator(FieldRequest,VelType,CivStage);
if isempty(varlist)
    erromsg=['error in read_civdata: unknow velocity type ' VelType];
    return
else
    [Field,vardetect]=nc2struct(filename,varlist);%read the variables in the netcdf file
end
if isfield(Field,'Txt')
    errormsg=Field.Txt;
    return
end
if vardetect(1)==0
     errormsg=[ 'requested field not available in ' filename '/' VelType ': need to run patch'];
     return
end
switch VelTypeOut
    case{'civ1','filter1'}
        if isfield(Field,'Patch1_SubDomain')
            Field.SubDomain=Field.Patch1_SubDomain;
            Field.ListGlobalAttribute=[Field.ListGlobalAttribute {'SubDomain'}];
        end     
        Field.Dt=Field.Civ1_Dt;
        Field.Time=Field.Civ1_Time;
    case{'civ2','filter2'}
        if isfield(Field,'Patch2_SubDomain')
            Field.SubDomain=Field.Patch2_SubDomain;
            Field.ListGlobalAttribute=[Field.ListGlobalAttribute {'SubDomain'}];
        end
        Field.Dt=Field.Civ2_Dt;
        Field.Time=Field.Civ2_Time;
end
Field.ListGlobalAttribute=[Field.ListGlobalAttribute {'Dt','Time'}];
ivar_U_tps=[];
var_ind=find(vardetect);
for ivar=1:numel(var_ind)
    Field.VarAttribute{ivar}.Role=role{var_ind(ivar)};
    Field.VarAttribute{ivar}.FieldRequest=FieldRequest;
    if strcmp(role{var_ind(ivar)},'vector_x')
        Field.VarAttribute{ivar}.Operation=FieldNames;
        ivar_U=ivar;
    end
    if strcmp(role{var_ind(ivar)},'vector_x_tps')
        Field.VarAttribute{ivar}.Operation=FieldNames;
        ivar_U_tps=ivar;
    end
%     Field.VarAttribute{ivar}.Unit=units{var_ind(ivar)};
    Field.VarAttribute{ivar}.Mesh=0.1;%typical mesh for histograms O.1 pixel
end
if ~isempty(ivar_U_tps)
    Field.VarAttribute{ivar_U}.VarIndex_tps=ivar_U_tps;
end

Field.ListGlobalAttribute=[Field.ListGlobalAttribute {'NbCoord','NbDim','TimeUnit','CoordUnit'}];
% %% update list of global attributes
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

function [var,role,vel_type_out,errormsg]=varcivx_generator(FieldRequest,vel_type,CivStage) 

%% default input values
if ~exist('vel_type','var'),vel_type='';end;
if iscell(vel_type),vel_type=vel_type{1}; end;%transform cell to string if needed
errormsg='';

%% select the priority order for automatic vel_type selection
if strcmp(vel_type,'civ2') && strcmp(FieldRequest,'derivatives')
    vel_type='filter2';
elseif strcmp(vel_type,'civ1') && strcmp(FieldRequest,'derivatives')
    vel_type='filter1';
end
if isempty(vel_type)||strcmp(vel_type,'*')
    switch CivStage
        case {6} %filter2 available
            vel_type='filter2';
        case {4,5}% civ2 available but not filter2
            if strcmp(FieldRequest,'derivatives')% derivatives needed
                vel_type='filter1';
            else
                vel_type='civ2';
            end
        case 3
            vel_type='filter1';
        case {1,2}% civ1 available but not filter1
            vel_type='civ1';
    end
end

var={};
switch vel_type
    case 'civ1'
        var={'X','Y','Z','U','V','W','C','F','FF';...
            'Civ1_X','Civ1_Y','Civ1_Z','Civ1_U','Civ1_V','Civ1_W','Civ1_C','Civ1_F','Civ1_FF'};
        role={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','ancillary','warnflag','errorflag'};
    %    units={'pixel','pixel','pixel','pixel','pixel','pixel','','',''};
    case 'filter1'
        var={'X','Y','Z','U','V','W','C','F','FF','Coord_tps','U_tps','V_tps','W_tps','SubRange','NbSites';...
            'Civ1_X','Civ1_Y','Civ1_Z','Civ1_U_smooth','Civ1_V_smooth','Civ1_W','Civ1_C','Civ1_F','Civ1_FF',...
            'Civ1_Coord_tps','Civ1_U_tps','Civ1_V_tps','Civ1_W_tps','Civ1_SubRange','Civ1_NbSites'};
        role={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','ancillary','warnflag','errorflag','coord_tps','vector_x_tps',...
            'vector_y_tps','vector_z_tps','ancillary','ancillary'};
     %   units={'pixel','pixel','pixel','pixel','pixel','pixel','','','','pixel','pixel','pixel','pixel','pixel',''};
    case 'civ2'
        var={'X','Y','Z','U','V','W','C','F','FF';...
            'Civ2_X','Civ2_Y','Civ2_Z','Civ2_U','Civ2_V','Civ2_W','Civ2_C','Civ2_F','Civ2_FF'};
        role={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','ancillary','warnflag','errorflag'};
      %  units={'pixel','pixel','pixel','pixel','pixel','pixel','','',''};
    case 'filter2'
        var={'X','Y','Z','U','V','W','C','F','FF','Coord_tps','U_tps','V_tps','W_tps','SubRange','NbSites';...
            'Civ2_X','Civ2_Y','Civ2_Z','Civ2_U_smooth','Civ2_V_smooth','Civ2_W','Civ2_C','Civ2_F','Civ2_FF',...
            'Civ2_Coord_tps','Civ2_U_tps','Civ2_V_tps','','Civ2_SubRange','Civ2_NbSites'};
        role={'coord_x','coord_y','coord_z','vector_x','vector_y','vector_z','ancillary','warnflag','errorflag','coord_tps','vector_x_tps',...
            'vector_y_tps','vector_z_tps','ancillary','ancillary'};
       % units={'pixel','pixel','pixel','pixel','pixel','pixel','','','','pixel','pixel','pixel','pixel','pixel',''};
end
if ~strcmp(FieldRequest,'interp_tps')
    var=var(:,1:9);%suppress tps if not needed
end
vel_type_out=vel_type;





