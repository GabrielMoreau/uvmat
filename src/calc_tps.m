function DataOut=calc_tps(DataIn)     
DataOut=DataIn;%default
SubDomain=1000; %default, estimated nbre of vectors in a subdomain used for tps
if isfield(DataIn,'SubDomain')
    SubDomain=DataIn.SubDomain;%
end
[DataOut.SubRange,DataOut.NbSites,DataOut.Coord_tps,DataOut.U_tps,DataOut.V_tps] =...
    filter_tps([DataIn.X(DataIn.FF==0) DataIn.Y(DataIn.FF==0)],DataIn.U(DataIn.FF==0),DataIn.V(DataIn.FF==0),[],SubDomain,0);
nbvar=numel(DataIn.ListVarName);
DataOut.ListVarName=[DataIn.ListVarName {'SubRange','NbSites','Coord_tps','U_tps','V_tps'}];
DataOut.VarDimName=[DataIn.VarDimName {{'nb_coord','nb_bounds','nb_subdomain'},{'nb_subdomain'},...
    {'nb_tps','nb_coord','nb_subdomain'},{'nb_tps','nb_subdomain'},{'nb_tps','nb_subdomain'}}];
DataOut.VarAttribute{nbvar+3}.Role='coord_tps';
DataOut.VarAttribute{nbvar+4}.Role='vector_x';
DataOut.VarAttribute{nbvar+5}.Role='vector_y';
if isfield(DataOut,'ListDimName')%cleaning
    DataOut=rmfield(DataOut,'ListDimName');
end
if isfield(DataOut,'DimValue')%cleaning
    DataOut=rmfield(DataOut,'DimValue');
end