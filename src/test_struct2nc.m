% program to test struct2nc for creating netcdf files
Data.ListVarName={'A'};
Data.VarDimName={{'ny','nx'}};
[x,y] = meshgrid([-2:.2:2]);
Data.A = x.*exp(-x.^2-y.^2);
%
err=struct2nc('test.nc',Data)
if isempty(err)
    display('test.nc written')
end