%'bed_scan': get the bed shape from laser impact
% firts line input files = active images
% second line, reference images for the initial bed

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
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function ParamOut=bed_scan_init (Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.NbViewMax=1;% max nbre of input file series (default , no limitation)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='on';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice=1; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.bed';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% ='=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
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
RootPath=Param.InputTable{1,1};


%% directory for output files
DirOut=fullfile(RootPath,[Param.OutputSubDir Param.OutputDirExt]);

%% get the set of input file names (cell array filecell), and file indices
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% filecell{iview,fileindex}: cell array representing the list of file names
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series,
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index

%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%fullfile(
% EDIT FROM HERE

%% set of y positions

nb_scan=400;% nbre of planes for a scan
if nbfield_i<400
    nb_scan=nbfield_i;
end
%ycalib=[-51 -1 49];% calibration planes
y_scan=-51+0.25*(1:nb_scan);% transverse position given by the translating system: first view at y=-51, view 400 at y=+49
coord_x=0.25:0.25:450;%% coord x in phys coordinates for final projection
%%%%%%%% A GENERALISER pour plusieurs scans
Mfiltre=ones(2,10)/20;%filter matrix for imnages

%% calibration data and timing: read the ImaDoc files
[RootRoot,CamName]=fileparts(RootPath);
RootRoot=fileparts(RootRoot);
CalibFolder=fullfile(RootRoot,'EXP_INIT',CamName);
XmlData_A=xml2struct(fullfile(CalibFolder,'planeA.xml'));
XmlData_B=xml2struct(fullfile(CalibFolder,'planeB.xml'));
XmlData_C=xml2struct(fullfile(CalibFolder,'planeC.xml'));
ycalib=[-51 -1 49];% the three y positions for calibration=
fx(1)=XmlData_C.GeometryCalib.fx_fy(1);
fx(2)=XmlData_B.GeometryCalib.fx_fy(1);
fx(3)=XmlData_A.GeometryCalib.fx_fy(1);
fy(1)=XmlData_C.GeometryCalib.fx_fy(2);
fy(2)=XmlData_B.GeometryCalib.fx_fy(2);
fy(3)=XmlData_A.GeometryCalib.fx_fy(2);
Tx(1)=XmlData_C.GeometryCalib.Tx_Ty_Tz(1);
Tx(2)=XmlData_B.GeometryCalib.Tx_Ty_Tz(1);
Tx(3)=XmlData_A.GeometryCalib.Tx_Ty_Tz(1);
Ty(1)=XmlData_C.GeometryCalib.Tx_Ty_Tz(2);
Ty(2)=XmlData_B.GeometryCalib.Tx_Ty_Tz(2);
Ty(3)=XmlData_A.GeometryCalib.Tx_Ty_Tz(2);
R11(1)=XmlData_C.GeometryCalib.R(1,1);
R11(2)=XmlData_B.GeometryCalib.R(1,1);
R11(3)=XmlData_A.GeometryCalib.R(1,1);
R12(1)=XmlData_C.GeometryCalib.R(1,2);
R12(2)=XmlData_B.GeometryCalib.R(1,2);
R12(3)=XmlData_A.GeometryCalib.R(1,2);
R21(1)=XmlData_C.GeometryCalib.R(2,1);
R21(2)=XmlData_B.GeometryCalib.R(2,1);
R21(3)=XmlData_A.GeometryCalib.R(2,1);
R22(1)=XmlData_C.GeometryCalib.R(2,2);
R22(2)=XmlData_B.GeometryCalib.R(2,2);
R22(3)=XmlData_A.GeometryCalib.R(2,2);
pfx=polyfit(ycalib,fx,1);%get thfield_ie linear interpolation of each parameter of the three calibrations
pfy=polyfit(ycalib,fy,1);
pTx=polyfit(ycalib,Tx,1);
pTy=polyfit(ycalib,Ty,1);
p11=polyfit(ycalib,R11,1);
p12=polyfit(ycalib,R12,1);
p21=polyfit(ycalib,R21,1);
p22=polyfit(ycalib,R22,1);
%get the calibration parameters at each position y by interpolation of the 3 calibration parameters
for img=1:nb_scan
    Calib(img).fx_fy(1)=pfx(1)*y_scan(img)+pfx(2);
    Calib(img).fx_fy(2)=pfy(1)*y_scan(img)+pfy(2);
    Calib(img).Tx_Ty_Tz(1)=pTx(1)*y_scan(img)+pTx(2);
    Calib(img).Tx_Ty_Tz(2)=pTy(1)*y_scan(img)+pTy(2);
    Calib(img).Tx_Ty_Tz(3)=1;
    Calib(img).R=zeros(3,3);
    Calib(img).R(3,3)=-1;
    Calib(img).R(1,2)=p12(1)*y_scan(img)+p12(2);
    Calib(img).R(1,1)=p11(1)*y_scan(img)+p11(2);
    Calib(img).R(1,2)=p12(1)*y_scan(img)+p12(2);
    Calib(img).R(2,1)=p21(1)*y_scan(img)+p21(2);
    Calib(img).R(2,2)=p22(1)*y_scan(img)+p22(2);
end

%% check coincdence in time for several input file series
%not relevant for this function

%% coordinate transform or other user defined transform
%not relevant for this function



%% Load the init bed scan
tic

%for img=1:nbfield_i
for img=1:nb_scan%nbfield_i
    img
    a=flipud(imread(filecell{1,img+400}));%image of the initial bed  [X_b_new(img,:),Z_b_new(img,:)]=phys_XYZ(Calib(img),[],x,Z_sb(img,:))
    if img==1
        [nby,nbx]=size(a);
        x_ima=1:nbx;%image absissa in pixel coordinates
        % X_new=zeros(nb_scan,size(a,2));% initialise the x po400sitions in phys coordinates
        % Z_s=zeros(nb_scan,size(a,2));% initialise the image index of max luminosity (dependning on x) for the reference scan

        X_phys=zeros(nb_scan,nbx);
        Z_phys=zeros(nb_scan,nbx);
    end
    % filtering
    amean=mean(a,2);
     [~,ind_max]=max(amean);% get the max of the image averaged along x, to restrict the search region
    ind_range=max(1,ind_max-30):min(nby,ind_max+30);% search band to find the line
    a=filter2(Mfiltre,a);%smoothed image
   % [~,iy]=max(a);% find the max along the first coordinate     Z_s_new=zeros(nb_scan,size(Z_s,2)); y, max values imax and the corresponding  y index iy along the first coordinate y

   z_ima=get_max(a(ind_range,:))+ind_range(1)-1;% get the max in the search band and shift to express it in indices of the original image
   % z_ima=iy';
    z_ima=smooth(z_ima,20,'rloess');%smooth Z, the image index of max luminosity (dependning on x)
    [X_phys(img,:),Z_phys(img,:)]=phys_XYZ(Calib(mod(img-1,nb_scan)+1),[],x_ima,z_ima');
end

%% interpolate on a regular grid
%coord_x=X_phys(end,1):0.1:X_phys(end,end);%% coord x in phys coordinates based in the last view plane (the last)
%y_scan_2=y_scan(1:400);
[X_m,Y_m]=meshgrid(coord_x,y_scan);
Y=y_scan'*ones(1,nbx);%initialisation of X, Y final topography map
Data.Z_init=griddata(X_phys,Y,Z_phys,X_m,Y_m);% dZ interpolated on the regular ph1ys grid X_m,Y_m

%Data.Z_init=0.5*(Data.Z_init(1:nb_scan,:)+Data.Z_init(nb_scan+1:2*nb_scan,:));
toc

% save netcdf
Data.ListVarName={'coord_x','y_scan','Z_init'};
Data.VarDimName={'coord_x','y_scan',{'y_scan','coord_x'}};
Data.VarAttribute{1}.Role='coord_x';
Data.VarAttribute{1}.unit='cm';
Data.VarAttribute{2}.Role='coord_y';
Data.VarAttribute{2}.unit='cm';
Data.VarAttribute{3}.Role='scalar';
Data.VarAttribute{3}.unit='cm';
Data.coord_x=coord_x;
Data.y_scan=y_scan;
struct2nc(fullfile(DirOut,'Z_init.nc'),Data)

%%%%%
function iy=get_max(a)% get the max with sub picel resolution
[a_max,iy]=max(a);
[Nby,Nbx]=size(a);
for ind_x=1:Nbx
    if iy(ind_x)>1 && iy(ind_x)<Nby
        a_plus=a(iy(ind_x)+1,ind_x);
        a_min=a(iy(ind_x)-1,ind_x);
        denom=2*a_max(ind_x)-a_plus-a_min;
        if denom >0
            iy(ind_x)=iy(ind_x)+0.5*(a_plus-a_min)/denom;%adjust the position of the max with a quadratic fit of the three points around the max
        end
    end
end
