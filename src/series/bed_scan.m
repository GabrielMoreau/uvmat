%'bed_scan': get the bed shape from laser ipact

%------------------------------------------------------------------------
% function GUI_input=bed_scan(Param)
%
%------------------------------------------------------------------------
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%OUTPUT
% ParamOut: sets options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% when Param.Action.RUN=0 (as activated when the current Action is selected
% in series), the function ouput paramOut set the activation of the needed GUI elements
%
% Param contains the elements:(use the menu bar command 'export/GUI config' in series to 
% see the current structure Param)
%    .InputTable: cell of input file names, (several lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDirExt: directory extension for data outputs
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%             .ActionExt: fct extension ('.m', Matlab fct, '.sh', compiled   Matlab fct
%             .RUN =0 for GUI input, =1 for function activation
%             .RunMode='local','background', 'cluster': type of function  use
%             
%    .IndexRange: set the file or frame indices on which the action must be performed
%    .FieldTransform: .TransformName: name of the selected transform function
%                     .TransformPath:   path  of the selected transform function
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%              .Coord_y: name of y coordinate variable
%              .Coord_x: name of x coordinate variable
%    .ProjObject: %sub structure describing a projection object (read from ancillary GUI set_object)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%=======================================================================
% Copyright 2008-2022, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function ParamOut=bed_scan (Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.NbViewMax=1;% max nbre of input file series (default , no limitation)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice=1; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.bed';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% ='=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    %check the type of the existence and type of the first input file:
    Param.IndexRange.last_i=Param.IndexRange.first_i;%keep only the first index in the series
    if isfield(Param.IndexRange,'first_j')
    Param.IndexRange.last_j=Param.IndexRange.first_j;
    end
    filecell=get_file_series(Param);
    if ~exist(filecell{1,1},'file')
        msgbox_uvmat('WARNING','the first input file does not exist')
    else
        FileInfo=get_file_info(filecell{1,1});
        FileType=FileInfo.FileType;
        if isempty(find(strcmp(FileType,{'image','multimage','mmreader','video'})));% =1 for images
            msgbox_uvmat('ERROR',['bad input file type for ' mfilename ': an image is needed'])
        end
    end
return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
%% read input parameters from an xml file if input is a file name (batch mode)
ParamOut=[];
RUNHandle=[];
WaitbarHandle=[];
checkrun=1;
if ischar(Param)% case of batch: Param is the name of the xml file containing the input parameters
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
else% interactive mode in Matlab
    hseries=findobj(allchild(0),'Tag','series');
    RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
    WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
end

%% root input file names and nomenclature type (cell arrays with one element)
RootPath=Param.InputTable{2,1};
% RootFile=Param.InputTable(:,3);
% SubDir=Param.InputTable(:,2);
% NomType=Param.InputTable(:,4);
% FileExt=Param.InputTable(:,5);

%% directory for output files
DirOut=fullfile(RootPath,[Param.OutputSubDir Param.OutputDirExt]);

%% get the set of input file names (cell array filecell), and file indices
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% filecell{iview,fileindex}: cell array representing the list of file names
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index

%% frame index for movie or multimage file input  

%% calibration data and timing: read the ImaDoc files
%not relevant for this function

%% check coincidence in time for several input file series
%not relevant for this function

%% coordinate transform or other user defined transform
%not relevant for this function

%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE

 %% Extension and indexing nomenclature for output file

% name=('EXP18OS_bed_init/im/');
% name2=('EXP18OS_end/im/');
% path_proj=['/.fsnet/project/coriolis/2018/18ADDUCE/SEDIM_SCANSIDE/'];  

%nimages=1800;

%% Load the init bed scan

y=90.05-0.05*i1_series{1};
Mfiltre=ones(2,10)/20;%filter matrix for imnages
tic
% y=zeros(1,nimages);
% X_new=zeros(4096,nimages);
x=1:4096;
% img=1;
%filecell{1,img}= list of the images _init
%filecell{2,img}= list of the images _end
for img=1:nbfield_i
     img
    image=flipud(imread(filecell{2,img}));
    a=image(700:1900,:);
    % filtering
    a=filter2(Mfiltre,a);
    [imax,iy]=max(a);
    Z=squeeze(iy);
    iy(imax<50)=NaN;
    Z_s(:,img)=smooth(Z,40,'rloess');
%     y(img)=y0-(0.05.*step);
%     y0=y(img);
    X_new(:,img)=phys_scan(x,y(img));
end

toc

nimages2=size(Z_s,2);
%%
y_y=1:size(a,1);

% [Xx,Yy]=meshgrid(x,y_y);
[X,Y]=meshgrid(x,y);

% index=1;
% [imax,iy]=max(a);
% 
% Z=squeeze(iy);

%%  smooth bed init
% for i=2:dim(2)
% if iy(i)<300
%     imax(i)=imax(i-1);
% end
% end

% for i=1:nimages2
% Z_s(:,i)=smooth(Z(:,i),50,'rloess');
% % Z_s_new(:,i)=phys_scanz(x,Z_s(:,i)',y(i));
% 
% end

%% Load the transit bed scan
for img=1:nbfield_i
    img
     image=flipud(imread(filecell{1,img}));
    b=image(700:1900,:);
        % filtering
    b=filter2(Mfiltre,b);
    [imaxb,iyb]=max(b);
    Zb=squeeze(iyb);
    iyb(imaxb<50)=NaN;
    Z_sb(:,img)=smooth(Zb,20,'rloess');
end


%% bed change
dZ=Z_s-Z_sb;
dZ_new=zeros(4096,nimages2);
for img=1:nimages2  
    dZ_new(:,img)=phys_scanz(dZ(:,img),y(img));
end


%% PLOTS
coord_x=X_new(1,end):0.1:X_new(end,end);
[Y_m,X_m]=meshgrid(y(1,:),coord_x);
Y_new=Y';
dZ_mesh=griddata(X_new,Y_new,dZ_new,X_m,Y_m);

if checkrun
    figure(1)
    hold on
    plot(x,Z_s+700)
    xlim([0 4096])
    ylim([0 3000])
    
    figure(2)
    hold on
    plot(x,Z_sb+700)
    xlim([0 4096])
    ylim([0 3000])
    
    figure(3)
    surfc(X_m,Y_m,dZ_mesh)
    shading interp;
    colorbar;
    caxis([0 3]);
    
    figure
    pcolor(X_m,Y_m,dZ_mesh);
    colormap;
    set(gca,'Xdir','reverse');
    caxis([0 3]);
    shading flat
    hold on
    colorbar
    title('Dz')
end

save(fullfile(DirOut,'18OS_f.mat'),'dZ','dZ_new','X','Y','Z_s','Z_sb','y')

% save netcdf
Data.ListVarName={'coord_x','coord_y','dZ'};
Data.VarDimName={'coord_x','coord_y',{'coord_y','coord_x'}};
Data.VarAttribute{1}.Role='coord_x';
Data.VarAttribute{1}.unit='cm';
Data.VarAttribute{2}.Role='coord_y';
Data.VarAttribute{2}.unit='cm';
Data.VarAttribute{3}.Role='scalar';
Data.VarAttribute{3}.unit='cm';
Data.coord_x=[coord_x(1) coord_x(end)];
Data.coord_y=[y(1) y(end)];
Data.dZ=dZ_mesh';
struct2nc(fullfile(DirOut,'dZ.nc'),Data)

function F=phys_scan(X,y)
F=(9.4*10^(-7)*y.^2-3.09*10^(-4)*y+0.07).*X +(-0.001023*y.^2+0.469*y+186.9);

function Fz=phys_scanz(Z,y)
Fz=(-1.4587*10^(-5)*y.^2 + 0.001072*y+0.0833).*Z; %+(-2.1*10^(-6)*x.^2+5.1*10^(-4)*x+0.0735).*Z;

 

