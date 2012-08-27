function DataOut=calc_tps(DataIn,checkall)     
DataOut=DataIn;%default
SubDomain=1000; %default, estimated nbre of vectors in a subdomain used for tps
if isfield(DataIn,'SubDomain')
    SubDomain=DataIn.SubDomain;%
end
%[CellVarIndex,NbDimVec,VarTypeCell,errormsg]=find_field_cells(DataIn);
[CellInfo,NbDimArray,errormsg]=find_field_cells(DataIn);
nbtps=0;
for icell=1:numel(CellInfo);
    %VarType=VarTypeCell{icell};
    if NbDimArray(icell)>=2 && strcmp(CellInfo{icell}.CoordType,'scattered')%'&& ~isempty(VarType.coord_x)
        nbtps=nbtps+1;
        X=DataIn.(DataIn.ListVarName{CellInfo{icell}.CoordIndex(end)});
        Y=DataIn.(DataIn.ListVarName{CellInfo{icell}.CoordIndex(end-1)});
        if isfield(CellInfo{icell},'VarIndex_vector_x')&&isfield(CellInfo{icell},'VarIndex_vector_y')
            Attr=DataIn.VarAttribute{CellInfo{icell}.VarIndex_vector_x};
            if ~isfield(Attr,'VarIndex_tps')&& (checkall || (isfield(Attr,'FieldRequest')&&strcmp(Attr.FieldRequest,'interp_tps')))               
                U=DataIn.(DataIn.ListVarName{CellInfo{icell}.VarIndex_vector_x});
                V=DataIn.(DataIn.ListVarName{CellInfo{icell}.VarIndex_vector_y});
            else
                continue
            end
        end
        if isfield(CellInfo{icell},'VarIndex_errorflag')
            FF=DataIn.(DataIn.ListVarName{CellInfo{icell}.VarIndex_errorflag});
            X=X(FF==0);
            Y=Y(FF==0);
            U=U(FF==0);
            V=V(FF==0);
        end
        if nbtps==1
            ListNewVar={'SubRange','NbSites','Coord_tps','U_tps','V_tps'};
            ListNewDim={'nb_tps','nb_subdomain'};
            DataOut.VarDimName=[DataIn.VarDimName {{'nb_coord','nb_bounds','nb_subdomain'},{'nb_subdomain'},...
                {'nb_tps','nb_coord','nb_subdomain'},{'nb_tps','nb_subdomain'},{'nb_tps','nb_subdomain'}}];
        else
            ListNewVar={['SubRange_' num2str(nbtps-1)],['NbSites_' num2str(nbtps-1)],['Coord_tps_' num2str(nbtps-1)],['U_tps_' num2str(nbtps-1)] ,['V_tps_' num2str(nbtps-1)]};
            ListNewDim={['nb_tps_' num2str(nbtps-1)],['nb_subdomain_' num2str(nbtps-1)]};
            DataOut.VarDimName=[DataIn.VarDimName {{'nb_coord','nb_bounds',ListNewDim{2}},ListNewDim(2),...
                {ListNewDim{1},'nb_coord',ListNewDim{2}},ListNewDim,ListNewDim}];
        end
        DataOut.ListVarName=[DataIn.ListVarName ListNewVar];
        
        [DataOut.(ListNewVar{1}),DataOut.(ListNewVar{2}),DataOut.(ListNewVar{3}),DataOut.(ListNewVar{4}),DataOut.(ListNewVar{5})] =...
            filter_tps([X Y],U,V,[],SubDomain,0);
        nbvar=numel(DataIn.ListVarName);
        
        DataOut.VarAttribute{nbvar+3}.Role='coord_tps';
        DataOut.VarAttribute{nbvar+4}=DataIn.VarAttribute{CellInfo{icell}.VarIndex_vector_x};%reproduce attributes of velocity
         DataOut.VarAttribute{nbvar+4}.Role='vector_x_tps';
         DataIn.VarAttribute{CellInfo{icell}.VarIndex_vector_x}.VarIndex_tps=nbvar+4;% indicte the correspondance with initial data
        DataOut.VarAttribute{nbvar+5}=DataIn.VarAttribute{CellInfo{icell}.VarIndex_vector_y};%reproduce attributes of velocity 
         DataOut.VarAttribute{nbvar+5}.Role='vector_y_tps';
        if isfield(DataOut,'ListDimName')%cleaning'
            DataOut=rmfield(DataOut,'ListDimName');
        end
        if isfield(DataOut,'DimValue')%cleaning
            DataOut=rmfield(DataOut,'DimValue');
        end
    end
end