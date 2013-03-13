%'tps_coeff_field': calculate the thin plate spline (tps) coefficients with subdomains for a field structure
%---------------------------------------------------------------------
% DataOut=tps_coeff_field(DataIn,checkall) 
%
% OUTPUT:
% DataOut: output field structure
%
% INPUT:
% DataIn: intput field structure
% checkall:=1 if tps is needed for all fields (a projection mode interp_tps is needed), =0 otherwise 
%
% called functions:
% 'find_field_cells': analyse the input field structure, grouping the variables  into 'fields' with common coordinates
% 'set_subdomains': sort a set of points defined by scattered coordinates in subdomains, as needed for tps interpolation
% 'tps_coeff': calculate the thin plate spline (tps) coefficients for a single domain.

function [DataOut,errormsg]=tps_coeff_field(DataIn,checkall)     
DataOut=DataIn;%default
SubDomainNbPoint=1000; %default, estimated nbre of data source points in a subdomain used for tps
if isfield(DataIn,'SubDomain')
    SubDomainNbPoint=DataIn.SubDomain;%old convention
end
if isfield(DataIn,'SubDomainNbPoint')
    SubDomainNbPoint=DataIn.SubDomainNbPoint;%
end
[CellInfo,NbDimArray,errormsg]=find_field_cells(DataIn);
if ~isempty(errormsg)
    errormsg=['tps_coeff_field/find_field_cells/' errormsg];
    return
end
nbtps=0;% indicate the number of tps coordinate sets in the field structure (in general =1)

for icell=1:numel(CellInfo);
    if NbDimArray(icell)>=2 && strcmp(CellInfo{icell}.CoordType,'scattered')% %if the coordinates are scattered
        NbCoord=NbDimArray(icell);% dimension of space
        nbtps=nbtps+1;% indicate the number of tps coordinate sets in the field structure (in general =1)
        X=DataIn.(DataIn.ListVarName{CellInfo{icell}.CoordIndex(end)});% value of x coordinate
        Y=DataIn.(DataIn.ListVarName{CellInfo{icell}.CoordIndex(end-1)});% value of x coordinate
        check_interp_tps=false(numel(CellInfo{icell}.VarIndex),1);
        %for ivar=1:numel(CellInfo{icell}.VarIndex)
        Index_interp=[];
        if isfield(CellInfo{icell},'VarIndex_scalar')
            Index_interp=[Index_interp CellInfo{icell}.VarIndex_scalar];
        end
        if isfield(CellInfo{icell},'VarIndex_vector_x')
            Index_interp=[Index_interp CellInfo{icell}.VarIndex_vector_x];
        end
        if isfield(CellInfo{icell},'VarIndex_vector_y')
            Index_interp=[Index_interp CellInfo{icell}.VarIndex_vector_y];
        end
        for ivar=Index_interp
            Attr=DataIn.VarAttribute{CellInfo{icell}.VarIndex(ivar)};
            if ~isfield(Attr,'VarIndex_tps')&& (checkall || (isfield(Attr,'ProjModeRequest')&&strcmp(Attr.ProjModeRequest,'interp_tps')))
                check_interp_tps(ivar)=1;
            end
        end
        VarIndexInterp=CellInfo{icell}.VarIndex(check_interp_tps);% indices of variables to interpolate through tps
        if ~isempty(VarIndexInterp)
            ListVarInterp=DataIn.ListVarName(VarIndexInterp);
            % exclude data points marked 'false' for interpolation
            if isfield(CellInfo{icell},'VarIndex_errorflag')
                FF=DataIn.(DataIn.ListVarName{CellInfo{icell}.VarIndex_errorflag});% error flag
                X=X(FF==0);
                Y=Y(FF==0);
                for ilist=1:numel(VarIndexInterp)
                    DataIn.(ListVarInterp{ilist})=DataIn.(ListVarInterp{ilist})(FF==0);
                end
            end
            term='';
            if nbtps>1
                term=['_' num2str(nbtps-1)];
            end
            ListNewVar=cell(1,numel(VarIndexInterp)+3);
            ListNewVar(1:3)={['SubRange' term],['NbCentres' term],['Coord_tps' term]};
            for ilist=1:numel(VarIndexInterp)
                ListNewVar{ilist+3}=[ListVarInterp{ilist} '_tps' term];
            end
            nbvar=numel(DataIn.ListVarName);
            DataOut.ListVarName=[DataIn.ListVarName ListNewVar];
            %ListNewDim={['nb_tps' term],['nb_subdomain' term]};
            DataOut.VarDimName=[DataIn.VarDimName {{'nb_coord','nb_bounds',['nb_subdomain' term]}} {['nb_subdomain' term]} ...
                {{['nb_tps' term],'nb_coord',['nb_subdomain' term]}}];
            DataOut.VarAttribute{nbvar+3}.Role='coord_tps';
            [SubRange,NbCentres,IndSelSubDomain] =set_subdomains([X Y],SubDomainNbPoint);% create subdomains for tps
            for isub=1:size(SubRange,3)
                ind_sel=IndSelSubDomain(1:NbCentres(isub),isub);% array indices selected for the subdomain
                Coord_tps=[X(ind_sel) Y(ind_sel)];
                fill=zeros(NbCoord+1,NbCoord,size(SubRange,3)); %matrix of zeros to complement the matrix Data.Civ1_Coord_tps (conveninent for file storage)
                Coord_tps=cat(1,Coord_tps,fill);
            end         
            for ivar=1:numel(VarIndexInterp)
                DataOut.VarDimName{nbvar+3+ivar}={['nb_tps' term],['nb_subdomain' term]};
                DataOut.VarAttribute{nbvar+3+ivar}=DataIn.VarAttribute{CellInfo{icell}.VarIndex_vector_x};%reproduce attributes of velocity
                if ~isfield(DataIn.VarAttribute{VarIndexInterp(ivar)},'Role')
                    DataOut.VarAttribute{nbvar+3+ivar}.Role='scalar_tps';
                else
                    DataOut.VarAttribute{nbvar+3+ivar}.Role=[DataIn.VarAttribute{VarIndexInterp(ivar)}.Role '_tps'];
                end
                DataOut.VarAttribute{VarIndexInterp(ivar)}.VarIndex_tps=nbvar+3+ivar;% indicate the tps correspondance in the source data
            end
            if isfield(DataOut,'ListDimName')%cleaning'
                DataOut=rmfield(DataOut,'ListDimName');
            end
            if isfield(DataOut,'DimValue')%cleaning
                DataOut=rmfield(DataOut,'DimValue');
            end
            DataOut.(['SubRange' term])=SubRange;
            DataOut.(['NbCentres' term])=NbCentres;
            DataOut.(['Coord_tps' term])=Coord_tps;
            for ilist=1:numel(VarIndexInterp)
                for isub=1:size(SubRange,3)
                    Var_tps=zeros(size(IndSelSubDomain)+[NbCoord+1 0]);%default spline
                    [tild,Var_tps(:,isub)]=tps_coeff([X(ind_sel) Y(ind_sel)],DataIn.(ListVarInterp{ilist}),0);%calculate the tps coeff in the subdomain
                end
                DataOut.(ListNewVar{ilist+3})=Var_tps;
            end
        end
    end
end