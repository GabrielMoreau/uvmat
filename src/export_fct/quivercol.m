%'quiver_export': plot vector fields and save figures for project 
%------------------------------------------------------------------------

function quiver_export(handles)
%------------------------------------------------------------------------

%% get input data
Data_uvmat=get(handles.uvmat,'UserData');
Data=Data_uvmat.Field; %get the current plotted field



