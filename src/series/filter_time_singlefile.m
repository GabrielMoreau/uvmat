%'filter_time_single': apply a a sliding filter in a time series, put the time series in a single netcdf file (problematic...) 
%------------------------------------------------------------------------
% function ParamOut=filter_time(Param)
%
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
%    .InputTable: cell of input file names, (several5.804 lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDirExt: directory extension for data outputs
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%             .ActionExt: fct extension ('.m', Matlab fct, '.sh', compiled   Matlab fct
%             .RUN =0 for GUI input, =1 for function activation
%             .RunMode='local','background', 'cluster': type of function  use
%    .IndexRange: set the file or frame indices on which the action must be performseriesed
%    .FieldTransform: .TransformName: name of the select39ed transform function
%                     .TransformPath:   path  of the selected transform function
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%             uvmat .Coord_y: name of y coordinate variable
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

function ParamOut=filter_time_singlefile(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to mseriesax (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice=1; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object39(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.tfilter';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice'; % '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    
    %% check the first input file in the series
    first_j=[];%
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if exist(FirstFileName,'file')
        FileInfo=get_file_info(FirstFileName);
        if ~(isfield(FileInfo,'FileType')&& strcmp(FileInfo.FileType,'netcdf'))
            msgbox_uvmat('ERROR','this fct works only on netcdf files (fields projected on a grid, notraw civ data)')
            return
        end
    else
        msgbox_uvmat('ERROR',['the input file ' FirstFileName ' does not exist'])
        return
    end
    
    %% setting the fltering window length
    answer = msgbox_uvmat('INPUT_TXT','set the filering window length','3');
    ParamOut.ActionInput.WindowLength=str2double(answer);
    return
end

%%%%%%%%%%%%  STANDARD PART  %%%%%%%%%%%%
ParamOut=[];%default output
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end

hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series


%% root input file(s) name, type and index series
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
%%%%%%%%%%%%
% The cell array filecell is the list of input file names, while
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%% NbView=1 : a single input series

NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%% define the output file (unique for the whole series)
OutputPath=fullfile(Param.OutputPath,Param.Experiment,Param.Device);
OutputDir=[Param.OutputSubDir Param.OutputDirExt];
first_j=[];last_j=[];% %% check the first input file in the series
if isfield(Param.IndexRange,'first_j')
    first_j=Param.IndexRange.first_j;last_j=Param.IndexRange.last_j;NomTypeNc='_1-1_1-1';
else
    NomTypeNc='_1-1';
end
PairString='';
if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
[i1,~,j1,~] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
[i2,~,j2,~] = get_file_index(Param.IndexRange.last_i,last_j,PairString);
ncfile_out=fullfile_uvmat(OutputPath,OutputDir,Param.InputTable{1,3},'.nc',NomTypeNc,i1,i2,j1,j2);

% OutputPath=fullfile(Param.OutputPath,num2str(Param.Experiment),num2str(Param.Device));
% RootFileOut=RootFile{1};
% NomTypeOut='_1';

%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
disp('loop for filtering started')
tstart = tic;
 telapsed(zeros,1,NbField)       
for index=1:NbField
    index
    
    Field= read_field(filecell{1,index},'netcdf',Param.InputFields);
    
    %%%%%%%%%%% MAIN RUNNING OPERATIONS  %%%%%%%%%%%%
    if index==1 %first field, initialisation output data
        DataOut.ListGlobalAttribute= {'Conventions'};
        DataOut.Conventions='uvmat';
        DataOut.ListVarName={'Time','coord_y','coord_x','Ufilter','Vfilter'};
        DataOut.VarDimName={'Time','coord_y','coord_x',{'Time','coord_y','coord_x'},{'Time','coord_y','coord_x'}};
        npy=numel(Field.coord_y);
        npx=numel(Field.coord_x);
        ListDimName={'Time','coord_y','coord_x'};
        DimValue=[NbField npy npx];
        VarDimIndex={1,2,3,[1 2 3],[1 2 3]};
        DataOut.coord_x=Field.coord_x;
        DataOut.coord_y=Field.coord_y;
        DataOut.Time=0;
        DataOut.Ufilter=0;
        DataOut.Vfilter=0;
        [errormsg,ncid]=struct2nc(ncfile_out,DataOut,'keep_open',ListDimName,DimValue,VarDimIndex);
        netcdf.putVar(ncid,0,0,1,0)
        netcdf.putVar(ncid,1,0,npy,Field.coord_y)
        netcdf.putVar(ncid,2,0,npx,Field.coord_x)
        Uvarid=3;
        Vvarid=4;
        TimeBlock=zeros(Param.ActionInput.WindowLength,1);
        Ublock=zeros(Param.ActionInput.WindowLength,npy,npx);
        Vblock=zeros(Param.ActionInput.WindowLength,npy,npx);
    end
    TimeBlock=circshift(TimeBlock,[-1 0 ]);
    Ublock=circshift(Ublock,[-1 0 0]); %shift U by ishift along the first index
    Vblock=circshift(Vblock,[-1 0 0]); %shift U by ishift along the first index
    TimeBlock(end)=Field.Time;
    Ublock(end,:,:)=Field.U;
    Vblock(end,:,:)=Field.V;
    sumindex=min(index,Param.ActionInput.WindowLength)-1;
    Timefilter=mean(TimeBlock(end-sumindex:end,:,:));%mid time
    Ufilter=squeeze(mean(Ublock(end-sumindex:end,:,:),1,'omitnan'));
    Vfilter=squeeze(mean(Vblock(end-sumindex:end,:,:),1,'omitnan'));
    %updating output the netcdf file
    netcdf.putVar(ncid,0,(index-1),Timefilter)
    netcdf.putVar(ncid,Uvarid,[(index-1) 0 0],[1 npy npx],Ufilter)
    netcdf.putVar(ncid,Vvarid,[(index-1) 0 0],[1 npy npx],Vfilter)

 telapsed(index) = toc(tstart);
    % writing the result file as netcdf file
    %     i1=i1_series{1}(index)-ceil(NpTime/2);
    %     OutputFile=fullfile_uvmat(OutputPath,OutputDir,RootFileOut,'.nc',NomTypeOut,i1);
    %     errormsg=struct2nc(OutputFile, DataOut);
    %     if isempty(errormsg)
    %         disp([OutputFile ' written'])
    %     else
    %         disp(errormsg)
    %     end
end
netcdf.close(ncid)
figure
plot(telapsed)
'END'
