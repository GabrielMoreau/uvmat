%'test_civ': test the civ fct on a simple shear produced by defomation of the input image
% use Matlab signal processing toolbox
%------------------------------------------------------------------------
% Method: 
    %open a netcdf file with civ results. 
    
% function ParamOut=test_patch_tps (Param)
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%OUTPUT
% ParamOut: sets input parameters when the function is selected, not activated(input Param.Action.RUN=0),=[] when the function is running
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
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type

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

function ParamOut=test_civ (Param)

%%%%%%%%%%%%%%%%%    INPUT PREPARATION MODE (no RUN)    %%%%%%%%%%%%%%%%%
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='one';% prescribes the file index ranges from min to max (options 'off'/'on'/'one' (single input index), 'off' by default)
    ParamOut.NbSlice='off'; % edit box nbre of slices made active
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%cannot use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.test_subpixel';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    
    %% root input file(s) and type
    % check the existence of the first file in the series
     first_j=[];% note that the function will propose to cover the whole range of indices
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('ERROR',['the input file ' FirstFileName ' does not exist'])
        return
    end

    %% check the validity of  input file types
    Data=nc2struct(FirstFileName,[]);
    if isfield(Data,'CivStage')
        switch Data.CivStage
            case {1,2,3}
                CivStage='civ1';
               
            otherwise
                CivStage='civ2';
        end
    else
        msgbox_uvmat('ERROR','invalid file type input: test_filter_tps proceeds raw civ data')
        return
    end

    %% numbers of fields
    incr_j=1;%default
    if isfield(Param.IndexRange,'incr_j')&&~isempty(Param.IndexRange.incr_j)
        incr_j=Param.IndexRange.incr_j;
    end
%     if isempty(first_j)||isempty(last_j)
%         nbfield_j=1;
%     else
%         nbfield_j=numel(first_j:incr_j:last_j);%nb of fields for the j index (bursts or volume slices)
%     end
    first_i=1;last_i=1;incr_i=1;%default
    if isfield(Param.IndexRange,'MinIndex_i'); first_i=Param.IndexRange.MinIndex_i; end   
    if isfield(Param.IndexRange,'MaxIndex_i'); last_i=Param.IndexRange.MaxIndex_i; end
    if isfield(Param.IndexRange,'incr_i')&&~isempty(Param.IndexRange.incr_i)
        incr_i=Param.IndexRange.incr_i;
    end
    nbfield_i=numel(first_i:incr_i:last_i);%nb of fields for the i index (bursts or volume slices)
%     nbfield=nbfield_j*nbfield_i; %total number of fields
    
    %% setting of intput parameters 
    ListParam={'CivStage';'CorrSmooth';'Civ1_CorrBoxSize'};
    DefaultValue={CivStage;1;[31 31]};
    if isfield(Param,'ActionInput')
        ParamIn=Param.ActionInput;
    else
        ParamIn=[];
    end
        [ParamOut.ActionInput,errormsg] = set_param_input(ListParam,DefaultValue,ParamIn);
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',errormsg)
        end
    return
end
%%%%%%%%%%%%%%%%%    STOP HERE FOR PAMETER INPUT MODE   %%%%%%%%%%%%%%%%% 

%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
RUNHandle=[];
WaitbarHandle=[];
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
else
    hseries=findobj(allchild(0),'Tag','series');
    RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
    WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
end

%% input preparation
RootPath=Param.InputTable{:,1};
RootFile=Param.InputTable{:,3};
NomType=Param.InputTable{:,4};
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% if ~isempty(hdisp),delete(hdisp),end;
%%%%%%%%%%%%
% The cell array filecell is the list of input file names, while
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series,
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%%

%% output path

OutputPath=fullfile(Param.OutputPath,Param.Experiment,Param.Device);


%% Prepare the structure of output netcdf file
DataOut.ListGlobalAttribute={'Conventions','Program','CivStage'};
DataOut.Conventions='uvmat/civdata';% states the conventions used for the description of field variables and attributes
if isfield(Param,'UvmatRevision')
    DataOut.Program=['test_subpixel, uvmat r' Param.UvmatRevision];
else
    DataOut.Program='test_subpixel';
end
DataOut.CivStage=1;
DataOut.CoordUnit='pixel';
DataOut.ListVarName={'Civ1_X','Civ1_Y','Civ1_U','Civ1_V','Civ1_C','Civ1_FF'};
DataOut.VarDimName={'nb_vec','nb_vec','nb_vec','nb_vec','nb_vec','nb_vec'};
DataOut.VarAttribute{1}.Role='coord_x';
DataOut.VarAttribute{2}.Role='coord_y';
DataOut.VarAttribute{3}.Role='vector_x';
DataOut.VarAttribute{4}.Role='vector_y';
DataOut.VarAttribute{5}.Role='ancillary';
DataOut.VarAttribute{6}.Role='errorflag';

%% MAIN LOOP

Data=read_field(filecell{1,1},'civdata',Param.InputFields);

%% create shifted input image

A=read_image(Data.Civ1_ImageA);
[npy,npx]=size(A);
B=zeros(npy,npx);
for iline=1:npy
    Ashift=interp(double(A(iline,:)),10);
    Ashift=circshift(Ashift,round(200*(iline-(npy/2))/npy)+10);
    Ashift(1:round(200*(iline-(npy/2))/npy)+10)=0;
    B(iline,:)=decimate(Ashift,10);
end
B=B+(rand(npy,npx)-0.5).*B;
par_civ.ImageA=A;
if isa(A,'uint8')
    par_civ.ImageB=uint8(B);
    BitDepth=8;
else
    par_civ.ImageB=uint16(B);
    BitDepth=16;
end
y=linspace (0.5,npy-0.5,npy);

%% Run civ_series
%Param.ActionInput.ListCompareMode='PIV';
par_civ.CorrBoxSize=Param.ActionInput.Civ1_CorrBoxSize;
par_civ.SearchRange=[15 5];
par_civ.SearchBoxShift=[0 0];
par_civ.Dx=Data.Civ1_Dx;
par_civ.Dy=Data.Civ1_Dy;
par_civ.Dy=Data.Civ1_Dy;
par_civ.CorrSmooth=Param.ActionInput.CorrSmooth;
% par_civ.MinCorr=0;
%    path_series=fileparts(which('series'));
% addpath(fullfile(path_series,'series'))
%     [DataOut,errormsg,result_conv]= civ_series(Param)

% par_civ: structure of input parameters, with fields:
%  .ImageA: first image for correlation (matrix)
%  .ImageB: second image for correlation(matrix)
%  .CorrBoxSize: 1,2 vector giving the size of the correlation box in x and y
%  .SearchBoxSize:  1,2 vector giving the size of the search box in x and y
%  .SearchBoxShift: 1,2 vector or 2 column matrix (for civ2) giving the shift of the search box in x and y
%  .CorrSmooth: =1 or 2 determines the choice of the sub-pixel determination of the correlation max
%  .ImageWidth: nb of pixels of the image in x
%  .Dx, Dy: mesh for the PIV calculation
%  .Grid: grid giving the PIV calculation points (alternative to .Dx .Dy): centres of the correlation boxes in Image A
%  .Mask: name of a mask file or mask image matrix itself
%  .MinIma: thresholds for image luminosity
%  .MaxIma
%  .CheckDeformation=1 for subpixel interpolation and image deformation (linear transform)
%  .DUDX: matrix of deformation obtained from patch at each grid point
%  .DUDY
%  .DVDX:
%  .DVDY

[DataOut.Civ1_X,DataOut.Civ1_Y,DataOut.Civ1_U,DataOut.Civ1_V,DataOut.Civ1_C,DataOut.Civ1_FF,result_conv,errormsg] = civ (par_civ);

if ~isempty(errormsg)
    disp_uvmat('ERROR',errormsg,checkrun)
    return
end

Uref=-10*(2*DataOut.Civ1_Y/npy)+10.1;
Udiff=DataOut.Civ1_U-Uref;
figure(1)
clf
h=histogram(DataOut.Civ1_U,200,'BinLimits',[-10 10])
xlabel('U(pixels)')
grid on
figure(2)
clf
h=histogram(Udiff,'BinLimits',[-1 1])
xlabel('Udiff (pixels)')
grid on
figure(3)
clf
h=histogram(DataOut.Civ1_V,'BinLimits',[-1 1])
xlabel('V (pixels)')
grid on
OutputFile=fullfile(OutputPath,[Param.OutputSubDir Param.OutputDirExt],[RootFile '_' num2str(Param.IndexRange.first_i) '.nc']) 
errormsg=struct2nc(OutputFile,DataOut)

OutputImageA=fullfile(OutputPath,[Param.OutputSubDir Param.OutputDirExt],[RootFile '_' num2str(Param.IndexRange.first_i) 'a.png']) 

OutputImageB=fullfile(OutputPath,[Param.OutputSubDir Param.OutputDirExt],[RootFile '_' num2str(Param.IndexRange.first_i) 'b.png']) 
imwrite(par_civ.ImageA,OutputImageA,'BitDepth',BitDepth);% save the new image
imwrite(par_civ.ImageB,OutputImageB,'BitDepth',BitDepth);
% %plot rms difference and proportion of excluded vectors
% figure(2)
% clf
% if CivStage==3% civ1
%     ref=0.2; %recommanded value for diff rms
%     txt='civ1';
% else
%     ref=0.1;
%     txt='civ2';
% end
% semilogx(FieldSmooth,DataOut.Diff_rms,'b+-',FieldSmooth,DataOut.NbExclude,'m+-',FieldSmooth,ref*ones(size(FieldSmooth)),'b--')
% grid on
% title( [filecell{1,1} ':' txt])
% legend({'rms vel. diff. ' ;' ratio excluded vectors';['recommended diff for' txt]},'Location','northwest')
% xlabel('smoothing parameter')
% ylabel('rms (pixels) and proportion of excluded vectors')
% OutputFig=fullfile(OutputPath,OutputDir,'plot_rms_diff.png');
% saveas(2,OutputFig)




  

  
