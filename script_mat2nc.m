% script to transform .mat files into netcdf
DataFolder=pwd; %=current working directory: to replace by path to data
fileinput=uigetfile_uvmat('pick an input .mat file',DataFolder,'.mat');% pick a .mat file by the browser
ncfile=regexprep(fileinput,'.mat$','.nc');% replace extension .mat by .nc
Data=load(fileinput)% load data from .mat file contains all variables
ListFields=fieldnames(Data);% list of  all variable names

% Example of variable selection: look for the variable with higher dimensions
Npy=zeros(1,numel(ListFields));
Npx=zeros(1,numel(ListFields));
for ilist =1:numel(ListFields)
    [Npy(ilist),Npx(ilist)]=size(Data.(ListFields{ilist}));
end
[tild,ilist]=max(Npy.*Npx);
Data.coord_x=1:Npx(ilist);% coordinate variable
Data.coord_y=1:Npy(ilist);
Data.ListVarName={'coord_x','coord_y',ListFields{ilist}};
Data.VarDimName={'coord_x','coord_y',{'coord_y','coord_x'}};

errormsg=struct2nc(ncfile,Data); % write the netcdf file
if isempty(errormsg)
    disp([ncfile ' written'])
else
    disp(errormsg)
end
Dataread=nc2struct(ncfile)% check the netcdf file

