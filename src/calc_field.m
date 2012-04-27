%'calc_field': defines fields (velocity, vort, div...) from civx data and calculate them
%---------------------------------------------------------------------
% [DataOut,errormsg]=calc_field(FieldList,DataIn,Coord_interp)
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

function [DataOut,errormsg]=calc_field(FieldList,DataIn,Coord_interp)

%list of defined scalars to display in menus (in addition to 'ima_cor').
% a type is associated to each scalar:
%              'discrete': related to the individual velocity vectors, not interpolated by patch
%              'vel': calculated from velocity components, continuous field (interpolated with velocity)
%              'der': needs spatial derivatives
%              'var': the scalar name corresponds to a field name in the netcdf files
% a specific variable name for civ1 and civ2 fields are also associated, if
% the scalar is calculated from other fields, as explicited below

list_field={'velocity';...%image correlation corresponding to a vel vector
    'ima_cor';...%image correlation corresponding to a vel vector
    'norm_vel';...%norm of the velocity
    'vort';...%vorticity
    'div';...%divergence
    'strain';...%rate of strain
    'u';... %u velocity component
    'v';... %v velocity component
    'w';... %w velocity component
    'w_normal';... %w velocity component normal to the plane
    'error'}; %error associated to a vector (for stereo or patch)
errormsg=[]; %default error message
if ~exist('FieldList','var')
    DataOut=list_field;% gives the list of possible fields in the absence of input
else
    if ~exist('DataIn','var')
        DataIn=[];
    end
    if ischar(FieldList)
        FieldList={FieldList};%convert a string input to a cell with one string element
    end
    if isfield(DataIn,'Z')&& isequal(size(DataIn.Z),size(DataIn.X))
        nbcoord=3;
    else
        nbcoord=2;
    end
    ListVarName={};
    ValueList={};
    RoleList={};
    units_cell={};
    
    %% interpolation with new civ data
    if isfield(DataIn,'SubRange') && isfield(DataIn,'Coord_tps')&& exist('Coord_interp','var')
        DataOut.ListGlobalAttribute=DataIn.ListGlobalAttribute; %reproduce global attribute
        for ilist=1:numel(DataOut.ListGlobalAttribute)
            DataOut.(DataOut.ListGlobalAttribute{ilist})=DataIn.(DataIn.ListGlobalAttribute{ilist});
        end
        DataOut.ListVarName={'coord_y','coord_x','FF'};
        DataOut.VarDimName{1}='coord_y';
        DataOut.VarDimName{2}='coord_x';
        XMax=max(max(DataIn.SubRange(1,:,:)));% extrema of the coordinates
        YMax=max(max(DataIn.SubRange(2,:,:)));
        XMin=min(min(DataIn.SubRange(1,:,:)));
        YMin=min(min(DataIn.SubRange(2,:,:)));
        check_der=0;
        check_val=0;
        nb_sites=size(Coord_interp,1);
        nb_coord=size(Coord_interp,2);
        for ilist=1:length(FieldList)
            switch FieldList{ilist}
                case 'velocity'
                    check_val=1;
                    DataOut.U=zeros(nb_sites,1);
                    DataOut.V=zeros(nb_sites,1);
                case{'vort','div','strain'}% case of spatial derivatives
                    check_der=1;
                    DataOut.(FieldList{ilist})=zeros(nb_sites,1);
%                 otherwise % case of a scalar
%                     check_val=1;
%                     DataOut.(FieldList{ilist})=zeros(size(Coord_interp,1));
            end
        end
        nbval=zeros(nb_sites,1);
        NbSubDomain=size(DataIn.SubRange,3);
        %DataIn.Coord_tps=DataIn.Coord_tps(1:end-3,:,:);% suppress the 3 zeros used to fit with the dimensions of variables
        for isub=1:NbSubDomain
            nbvec_sub=DataIn.NbSites(isub);
            check_range=(Coord_interp >=ones(nb_sites,1)*DataIn.SubRange(:,1,isub)' & Coord_interp<=ones(nb_sites,1)*DataIn.SubRange(:,2,isub)');
            ind_sel=find(sum(check_range,2)==nb_coord);
            %rho smoothing parameter
            %                 epoints = Coord_interp(ind_sel) ;% coordinates of interpolation sites
            %                 ctrs=DataIn.Coord_tps(1:nbvec_sub,:,isub);%(=initial points) ctrs
            nbval(ind_sel)=nbval(ind_sel)+1;% records the number of values for eacn interpolation point (in case of subdomain overlap)
            if check_val
                EM = tps_eval(Coord_interp(ind_sel,:),DataIn.Coord_tps(1:nbvec_sub,:,isub));%kernels for calculating the velocity from tps 'sources'
            end
            if check_der
                [EMDX,EMDY] = tps_eval_dxy(Coord_interp(ind_sel,:),DataIn.Coord_tps(1:nbvec_sub,:,isub));%kernels for calculating the spatial derivatives from tps 'sources'
            end
            for ilist=1:length(FieldList)
                switch FieldList{ilist}
                    case 'velocity'
                        ListFields={'U', 'V'};
                        VarAttributes{1}.Role='vector_x';
                        VarAttributes{2}.Role='vector_y';
                        DataOut.U(ind_sel)=DataOut.U(ind_sel)+EM *DataIn.U_tps(1:nbvec_sub+3,isub);
                        DataOut.V(ind_sel)=DataOut.V(ind_sel)+EM *DataIn.V_tps(1:nbvec_sub+3,isub);
                    case 'u'
                        ListFields={'U'};
                        VarAttributes{1}.Role='scalar';
                        DataOut.U(ind_sel)=DataOut.U(ind_sel)+EM *DataIn.U_tps(1:nbvec_sub+3,isub);
                    case 'v'
                        ListFields={'V'};
                        VarAttributes{1}.Role='scalar';
                        DataOut.V(ind_sel)=DataOut.V(ind_sel)+EM *DataIn.V_tps(1:nbvec_sub+3,isub);
                    case 'vort'
                        ListFields={'vort'};
                        VarAttributes{1}.Role='scalar';
                        DataOut.vort(ind_sel)=DataOut.vort(ind_sel)+EMDY *DataIn.U_tps(1:nbvec_sub+3,isub)-EMDX *DataIn.V_tps(1:nbvec_sub+3,isub);
                    case 'div'
                        ListFields={'div'};
                        VarAttributes{1}.Role='scalar';
                        DataOut.div(ind_sel)=DataOut.div(ind_sel)+EMDX*DataIn.U_tps(1:nbvec_sub+3,isub)+EMDY *DataIn.V_tps(1:nbvec_sub+3,isub);
                    case 'strain'
                        ListFields={'strain'};
                        VarAttributes{1}.Role='scalar';
                        DataOut.strain(ind_sel)=DataOut.strain(ind_sel)+EMDY*DataIn.U_tps(1:nbvec_sub+3,isub)+EMDX *DataIn.V_tps(1:nbvec_sub+3,isub);
                end
            end
            DataOut.FF=nbval==0; %put errorflag to 1 for points outside the interpolation rang
%            DataOut.FF=reshape(DataOut.FF,numel(yI),numel(xI));
            nbval(nbval==0)=1;
%             switch FieldList{1}
%                 case {'velocity','u','v'}
%                     DataOut.U=reshape(DataOut.U./nbval,numel(yI),numel(xI));
%                     DataOut.V=reshape(DataOut.V./nbval,numel(yI),numel(xI));
%                 case 'vort'
%                     DataOut.vort=reshape(DataOut.vort,numel(yI),numel(xI));
%                 case 'div'
%                     DataOut.div=reshape(DataOut.div,numel(yI),numel(xI));
%                 case 'strain'
%                     DataOut.strain=reshape(DataOut.strain,numel(yI),numel(xI));
%             end
            DataOut.ListVarName=[DataOut.ListVarName ListFields];
            for ilist=3:numel(DataOut.ListVarName)
                DataOut.VarDimName{ilist}={'coord_y','coord_x'};
            end
            DataOut.VarAttribute={[],[]};
            DataOut.VarAttribute{3}.Role='errorflag';
            DataOut.VarAttribute=[DataOut.VarAttribute VarAttributes];
        end
    else
        
        %% civx data
        DataOut=DataIn;
        for ilist=1:length(FieldList)
            if ~isempty(FieldList{ilist})
                [VarName,Value,Role,units]=feval(FieldList{ilist},DataIn);%calculate field with appropriate function named FieldList{ilist}
                ListVarName=[ListVarName VarName];
                ValueList=[ValueList Value];
                RoleList=[RoleList Role];
                units_cell=[units_cell units];
            end
        end
        %erase previous data (except coordinates)
        for ivar=nbcoord+1:length(DataOut.ListVarName)
            VarName=DataOut.ListVarName{ivar};
            DataOut=rmfield(DataOut,VarName);
        end
        DataOut.ListVarName=DataOut.ListVarName(1:nbcoord);
        if isfield(DataOut,'VarDimName')
            DataOut.VarDimName=DataOut.VarDimName(1:nbcoord);
        else
            errormsg='element .VarDimName missing in input data';
            return
        end
        DataOut.VarAttribute=DataOut.VarAttribute(1:nbcoord);
        %append new data
        DataOut.ListVarName=[DataOut.ListVarName ListVarName];
        for ivar=1:length(ListVarName)
            DataOut.VarDimName{nbcoord+ivar}=DataOut.VarDimName{1};
            DataOut.VarAttribute{nbcoord+ivar}.Role=RoleList{ivar};
            DataOut.VarAttribute{nbcoord+ivar}.units=units_cell{ivar};
            DataOut.(ListVarName{ivar})=ValueList{ivar};
        end
    end
end


%%%%%%%%%%%%% velocity fieldn%%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units_cell]=velocity(DataIn)
VarName={};
ValCell={};
Role={};
units_cell={};
if isfield(DataIn,'CoordUnit') && isfield(DataIn,'TimeUnit')
    units=[DataIn.CoordUnit '/' DataIn.TimeUnit];
else
    units='pixel';
end
if isfield(DataIn,'U')
    VarName=[VarName {'U'}];
    ValCell=[ValCell {DataIn.U}];
    Role=[Role {'vector_x'}];
    units_cell=[units_cell {units}];
end
if isfield(DataIn,'V')
    VarName=[VarName {'V'}];
    ValCell=[ValCell {DataIn.V}];
    Role=[Role {'vector_y'}];
    units_cell=[units_cell {units}];
end
if isfield(DataIn,'W')
    VarName=[VarName {'W'}];
    ValCell=[ValCell {DataIn.W}];
    Role=[Role {'vector_z'}];
    units_cell=[units_cell {units}];
end
if isfield(DataIn,'F')
    VarName=[VarName {'F'}];
    ValCell=[ValCell {DataIn.F}];
    Role=[Role {'warnflag'}];
    units_cell=[units_cell {[]}];
end
if isfield(DataIn,'FF')
    VarName=[VarName,{'FF'}];
    ValCell=[ValCell {DataIn.FF}];
    Role=[Role {'errorflag'}];
    units_cell=[units_cell {[]}];
end

%%%%%%%%%%%%% ima cor%%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=ima_cor(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'C')
    VarName{1}='C';
    ValCell{1}=DataIn.C;
    Role={'ancillary'};
    units={[]};
end

%%%%%%%%%%%%% norm_vec %%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=norm_vel(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'U') && isfield(DataIn,'V')
    VarName{1}='norm_vel';
    ValCell{1}=DataIn.U.*DataIn.U+ DataIn.V.*DataIn.V;
    if isfield(DataIn,'W') && isequal(size(DataIn.W),size(DataIn.U))
        ValCell{1}=ValCell{1}+DataIn.W.*DataIn.W;
    end
    ValCell{1}=sqrt(ValCell{1});
    Role{1}='scalar';
    if isfield(DataIn,'CoordUnit') && isfield(DataIn,'TimeUnit')
        units={[DataIn.CoordUnit '/' DataIn.TimeUnit]};
    else
        units={'pixel'};
    end
end



%%%%%%%%%%%%% vorticity%%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=vort(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'DjUi')
    VarName{1}='vort';
    ValCell{1}=DataIn.DjUi(:,1,2)-DataIn.DjUi(:,2,1);  %vorticity
    siz=size(ValCell{1});
    ValCell{1}=reshape(ValCell{1},siz(1),1);
    Role{1}='scalar';
    if isfield(DataIn,'TimeUnit')
        units={[DataIn.TimeUnit '-1']};
    else
        units={[]};
    end
end

%%%%%%%%%%%%% divergence%%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=div(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'DjUi')
    VarName{1}='div';
    ValCell{1}=DataIn.DjUi(:,1,1)+DataIn.DjUi(:,2,2); %DUDX+DVDY
    siz=size(ValCell{1});
    ValCell{1}=reshape(ValCell{1},siz(1),1);
    Role{1}='scalar';
    if isfield(DataIn,'TimeUnit')
        units={[DataIn.TimeUnit '-1']};
    else
        units={[]};
    end
end

%%%%%%%%%%%%% strain %%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=strain(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'DjUi')
    VarName{1}='strain';
    ValCell{1}=DataIn.DjUi(:,1,2)+DataIn.DjUi(:,2,1);%DVDX+DUDY
    siz=size(ValCell{1});
    ValCell{1}=reshape(ValCell{1},siz(1),1);
    Role{1}='scalar';
    if isfield(DataIn,'TimeUnit')
        units={[DataIn.TimeUnit '-1']};
    else
        units={[]};
    end
end

%%%%%%%%%%%%% u %%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=u(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'U')
    VarName{1}='U';
    ValCell{1}=DataIn.U;
    Role{1}='scalar';
    if isfield(DataIn,'CoordUnit') && isfield(DataIn,'TimeUnit')
        units={[DataIn.CoordUnit '/' DataIn.TimeUnit]};
    else
        units={'pixel'};
    end
end

%%%%%%%%%%%%% v %%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=v(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'V')
    VarName{1}='V';
    ValCell{1}=DataIn.V;
    Role{1}='scalar';
    if isfield(DataIn,'CoordUnit') && isfield(DataIn,'TimeUnit')
        units={[DataIn.CoordUnit '/' DataIn.TimeUnit]};
    else
        units={'pixel'};
    end
end

%%%%%%%%%%%%% w %%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=w(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'W')
    VarName{1}='W';
    ValCell{1}=DataIn.W;
    Role{1}='scalar';%will remain unchanged by projection
    if isfield(DataIn,'CoordUnit') && isfield(DataIn,'TimeUnit')
        units={[DataIn.CoordUnit '/' DataIn.TimeUnit]};
    else
        units={'pixel'};
    end
end

%%%%%%%%%%%%% w_normal %%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=w_normal(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'W')
    VarName{1}='W';
    ValCell{1}=DataIn.W;
    Role{1}='vector_z';%will behave like a vector component  by projection
    if isfield(DataIn,'CoordUnit') && isfield(DataIn,'TimeUnit')
        units={[DataIn.CoordUnit '/' DataIn.TimeUnit]};
    else
        units={'pixel'};
    end
end

%%%%%%%%%%%%% error %%%%%%%%%%%%%%%%%%%%
function [VarName,ValCell,Role,units]=error(DataIn)
VarName={};
ValCell={};
Role={};
units={};
if isfield(DataIn,'E')
    VarName{1}='E';
    ValCell{1}=DataIn.E;
    Role{1}='ancillary'; %TODO CHECK units in actual fields
    if isfield(DataIn,'CoordUnit') && isfield(DataIn,'TimeUnit')
        units={[DataIn.CoordUnit '/' DataIn.TimeUnit]};
    else
        units={'pixel'};
    end
end

