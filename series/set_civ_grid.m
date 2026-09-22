%'set_civ_grid': detect the lower fluid boundary (assumed straight)by the laser impact 
% with a series of input images and provide a polynomial fit of the mean. 
% Create a PIV grid file with increased resolution near the boundary
% To use in interactive mode only

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
%             
%    .IndexRange: set the file or frame indices on which the action must be performed

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

function ParamOut=bed_position(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.NbViewMax=1;% max nbre of input file series (default , no limitation)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.grid';%set the output dir extension
    ParamOut.OutputFileMode='NbInput_i';% ='=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice   
    return
end

%%%%%%%%%%%% STANDARD PART  %%%%%%%%%%%%
%% read input parameters from an xml file if input is a file name (batch mode)
if ischar(Param)
    disp('TO USE ONLY IN INTERACTIVE MODE')
    return
end

%% root input file names and nomenclature type (cell arrays with one element)
RootPath=Param.InputTable{1,1};
SubDir=Param.InputTable{1,2};
RootFile=Param.InputTable{1,3};
NomType=Param.InputTable{1,4};
FileExt=Param.InputTable{1,5};
i_series=Param.IndexRange.first_i:Param.IndexRange.incr_i:Param.IndexRange.last_i;

%% List of input indices i and j
i_indices=Param.IndexRange.first_i:Param.IndexRange.incr_i:Param.IndexRange.last_i;
if isfield(Param.IndexRange,'first_j')
    j_indices=Param.IndexRange.first_j:Param.IndexRange.incr_j:Param.IndexRange.last_j;
    NomTypeOut='_1_1'; %i and j indices for outdput
else
    j_indices=1;
    NomTypeOut='_1';% Only i indices for output
end

%% check for index relabeling
CheckRelabel=isfield(Param.IndexRange,'Relabel' )&& Param.IndexRange.Relabel;%=true for index relabeling (PCO);

%% get xml file
XmlFileName=find_imadoc(RootPath,SubDir);
if ~isempty(XmlFileName)
    XmlData=imadoc2struct(XmlFileName);%read the time from XmlFileName
    if isfield(XmlData,'Time')
        Time=XmlData.Time;
        TimeSource='xml';
    end
end

%% get file info
if CheckRelabel
    [FileName,frame_index]=index2filename(XmlData.FileSeries,Param.IndexRange.first_i,j_indices(1),Param.IndexRange.last_j);
    FirstFileName=fullfile(RootPath,SubDir,FileName);
    FileInfo=get_file_info(FirstFileName);
else
    FirstFileName=fullfile_indices(fullfile(RootPath,SubDir,RootFile),FileExt,NomType,Param.IndexRange.first_i,[],j_indices(1));%get first file name
    FileInfo=get_file_info(FirstFileName);
    if isfield(FileInfo,'NumberOfFrames') && FileInfo.NumberOfFrames >1
        if isempty(regexp(NomType,'1$', 'once'))% no file indexing
            frame_index=ones(numel(j_indices),1)*i_indices;% the index i denotes the frame number in a movie, no index j
        else
            frame_index=j_indices'*ones(1,numel(i_indices));% the index j denotes the frame number in a movie
        end
    else
        frame_index=ones(numel(j_indices),numel(i_indices));
    end
end
if ~strcmp(FileInfo.FieldType,'image')
    msgbox_uvmat('ERROR', 'images need to be introduced as input')
    return
end

%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%fullfile(
% EDIT FROM HERE

%% prepare output netcdf file
Data.ListVarName={'Grid','CorrBoxSize'};
Data.VarDimName={{'NbVec','NbDim'},{'NbVec','NbDim'}};
Data.ListGlobalAttribute={'Conventions','CoordUnit'};
Data.Conventions='uvmat';
Data.CoordUnit='pixel';

%% main loop
Npy=FileInfo.Height;
Npx=FileInfo.Width;
Mfiltre=ones(2,10)/20;%filter matrix for imnages
NbFile=numel(i_indices)*numel(j_indices);
PosWall=zeros(1,Npx);% initialise y position of the wall in px coordinates
PosWall2=zeros(1,Npx);% initialise variance of y position of the wall in px coordinates
for index_i=1:numel(i_indices)
    for index_j=1:numel(j_indices)
        if CheckRelabel
            [ImageName,FrameIndex]=index2filename(XmlData{1}.FileSeries,i_indices(index_i),j_indices(index_j),Param.IndexRange.last_j);
            ImageName=fullfile(RootPath{1},SubDir{1},ImageName);% include path
        else
            ImageName=fullfile_indices(fullfile(RootPath,SubDir,RootFile),FileExt,NomType,i_indices(index_i),[],j_indices(index_j));
            FrameIndex=frame_index(index_j,index_i);
        end
        A=flipud(read_image(ImageName,'image'));
        A=filter2(Mfiltre,A);%smoothed image
        Amean=mean(A,2);
        [~,ind_max]=max(Amean);% get the max of the image averaged along x, to restrict the search region
        ind_range=max(1,ind_max-10):min(Npy,ind_max+10);% search band to find the line
        y_ima=get_max(A(ind_range,:))+ind_range(1)-1;% get the max in the search band and shift to express it in indices of the original image
        y_ima=(smooth(y_ima,100,'rloess'))';%smooth the image index of max luminosity (dependning on x)
        PosWall=PosWall+y_ima;
        PosWall2=PosWall2+y_ima.*y_ima;

    end
end
PosMean=PosWall/NbFile;% mean y position of the laser impact
PosWall2=PosWall2/NbFile;% mean  position variance of the laser impact
PosStd=sqrt(PosWall2-PosMean.*PosMean); % standard deviation of the laser impact

%% PIV grid

Dy=[2:10 repmat(10,1,100)];% set of y intervals between correlation boxes
ycentr=cumsum(Dy);% set of y positions for the box centres with respect to the laser impact
corr_box_area=500+(30/Npy)*(30/Npy)*ycentr.*ycentr;% area of the correlation boxes in pixel^2, increasing with distance to the wall
corr_box_y=2*Dy-1+floor((15/Npy)*ycentr);% correlation box size along y 
%corr_box_area=corr_box_area*ones(size(corr_box_y));% corr_box area repeated as a vector array
corr_box_x=round(corr_box_area./corr_box_y);% size along x of the correlation boxes
Dx=10;
nbinterv_x=floor((Npx-1)/Dx);%expected number of intervals Dx
gridlength_x=nbinterv_x*Dx;
minix=ceil((Npx-gridlength_x)/2);
x_ctre=minix+1:Dx:Npx;% ctres of the corrbox along x
GridY=ycentr'*ones(1,numel(x_ctre))+ones(numel(Dy),1)*PosMean(x_ctre);% position in y of the box centres
GridX=ones(numel(Dy),1)*x_ctre;
GridX=reshape(GridX,[],1);
GridY=reshape(GridY,[],1);
Data.Grid=[GridX GridY];
corr_box_y=reshape(corr_box_y'*ones(1,numel(x_ctre)),[],1);
corr_box_x=reshape(corr_box_x'*ones(1,numel(x_ctre)),[],1);
Data.CorrBoxSize=[corr_box_x corr_box_y];
OutputRoot=fullfile(Param.OutputPath,Param.Experiment,Param.Device,[Param.OutputSubDir Param.OutputDirExt],'grid');
OutputFile=fullfile_indices(OutputRoot,'$.nc','_1-2',i_indices(1),i_indices(end));
error=struct2nc(OutputFile,Data);%save result file
if isempty(error)
    disp(['output file ' OutputFile ' written'])
else
    disp(error)
end

figure(1)
plot(1:Npx,PosMean,1:Npx,PosMean+PosStd,1:Npx,PosMean-PosStd)% plot mean position versus x with error bar estiamted from the variance
P= polyfit(1:Npx,PosMean,3)
hold on
f=polyval(P,1:Npx);
plot(1:Npx,f,'r')
figure(2)
plot(1:Npx,PosMean,1:Npx,PosMean+PosStd,1:Npx,PosMean-PosStd)% plot mean position versus x with error bar estiamted from the variance
hold on
plot(Data.Grid(:,1),Data.Grid(:,2),'.','MarkerSize',2)
xlabel('x(pixel)')
ylabel('y(pixel)')
axis equal
figure(3)
plot(Data.CorrBoxSize(:,1),Data.Grid(:,2),'.')
ylabel('y (pixels)')
xlabel('CorrBoxSize along x (pixels)')
figure(4)
plot(Data.CorrBoxSize(:,2),Data.Grid(:,2),'.')
ylabel('y (pixels)')
xlabel('CorrBoxSize along y (pixels)')
figure(5)
plot(Data.CorrBoxSize(:,2)./Data.CorrBoxSize(:,1),Data.Grid(:,2),'.')
ylabel('y (pixels)')
xlabel('aspect ratio corr box')
%% make the calibration correction
XmlFileName=find_imadoc(Param.InputTable{1,1},Param.InputTable{1,2});
if ~isempty(XmlFileName)
    [XmlData,errormsg]=imadoc2struct(XmlFileName);%read the time from XmlFileName
    if ~isempty(errormsg)
        disp(errormsg)
        return
    end
end
[Xphys,Yphys]=phys_XYZ(XmlData.GeometryCalib,XmlData.Slice,1:Npx,PosMean);
figure(6)
plot(Xphys,Yphys)
P= polyfit(Xphys,Yphys,3);
hold on
f=polyval(P,Xphys);
plot(Xphys,f,'r')
fprintf('%.5e\n',P)% to transfer to the xml file as XmlData.GeometryCalib.Polyfit


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iy=get_max(a)% get the max with sub pixel resolution
a_max=max(a);
[Nby,Nbx]=size(a);
iy=zeros(1,Nbx);
for ind_x=1:Nbx
    iy_range=find(a(:,ind_x)==a_max(ind_x));
    iy(ind_x)=0.5*(iy_range(1)+iy_range(end));
    iy_min=iy_range(1)-1;
    iy_plus=iy_range(end)+1;
    if iy_min>=1 && iy_plus<=Nby
        a_plus=a(iy_plus,ind_x);
        a_min=a(iy_min,ind_x);
        denom=2*a_max(ind_x)-a_plus-a_min;
        if denom >0
            iy(ind_x)=iy(ind_x)+0.5*(a_plus-a_min)/denom;%adjust the position of the max with a quadratic fit of the three points around the max
        end
    end
end
