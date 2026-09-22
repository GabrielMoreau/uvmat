%'aver_stat': calculate Reynolds stress components over time series
%------------------------------------------------------------------------
% function ParamOut=turb_stat(Param)
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
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function ParamOut=turb_stat(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on'; %nbre of slices ('on' if needed as input, fixed value e.g. 1, 'off' by default)
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.staturb';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
%     filecell=get_file_series(Param);%check existence of the first input file
%     if ~exist(filecell{1,1},'file')
%         msgbox_uvmat('WARNING','the first input file does not exist')
%     end
    return
end

%%%%%%%%%%%%  STANDARD PART  %%%%%%%%%%%%
ParamOut=[];%default output
%% read input parameters from an xml file if input is a file name (batch mode)
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=false;
else
    checkrun=true;
    RUNHandle=gcbo; %handle of the button RUN in the GUI series
end

%% get info on the input file series
FullRootFile=fullfile(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3});
PairString='';
if isfield(Param.IndexRange,'PairString')
            PairString=Param.IndexRange.PairString{1};
        end
[i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,Param.IndexRange.first_j,PairString);
FirstFileName=fullfile_indices(FullRootFile,Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);%get first file name
Field_first=nc2struct(FirstFileName);
    
%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE

%% settings for the output file
OutputPath=fullfile(Param.OutputPath,Param.Experiment,Param.Device);
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files
OutputRoot=fullfile(OutputPath,OutputDir,Param.InputTable{1,3});
NomTypeOut=nomtype2pair(Param.InputTable{1,4});% determine the index nomenclature type for the output file
OutputFile=fullfile_indices(OutputRoot,'$.nc',NomTypeOut,Param.IndexRange.first_i,Param.IndexRange.last_i,Param.IndexRange.first_j,Param.IndexRange.last_j);

%% Set field names and velocity types

%% output file initialisation
DataOut.ListGlobalAttribute= {'Conventions'};
DataOut.Conventions= 'uvmat';
YName='coord_y'; XName='coord_x';
coord_cell{1}={YName,XName};
DataOut.ListVarName={YName,XName,'UMean' ,'VMean','WMean','u2Mean','v2Mean','w2Mean','uvMean','uwMean','vwMean','Counter'};
DataOut.VarDimName=[YName,XName,repmat(coord_cell,1,numel(DataOut.ListVarName)-2)];

if Param.IndexRange.NbSlice==1
    interval=Param.IndexRange.incr_i% statistics is done taking into account the input index increment
else
    interval=Param.IndexRange.NbSlice;% statistics is done slice by slice without taking into account the input index increment
end

%% stat initialisation
DataOut.(XName)=Field_first.(XName);
DataOut.(YName)=Field_first.(YName);
Npx=numel(Field_first.(XName));
Npy=numel(Field_first.(YName));
for ivar=3:numel(DataOut.ListVarName)
    DataOut.(DataOut.ListVarName{ivar})=zeros(Npy,Npx);
end
U2Mean=zeros(Npy,Npx);
V2Mean=zeros(Npy,Npx);
W2Mean=zeros(Npy,Npx);
UVMean=zeros(Npy,Npx);
UWMean=zeros(Npy,Npx);
VWMean=zeros(Npy,Npx);

%% List of field indices
Index_i_series=Param.IndexRange.first_i:Param.IndexRange.incr_i:Param.IndexRange.last_i;
if isfield(Param.IndexRange,'last_j')
    Index_j_series=Param.IndexRange.first_j:Param.IndexRange.incr_j:Param.IndexRange.last_j;
else
    Index_j_series=1;
end

%% MAIN LOOP ON FIELDS INDICES
for index_i=Index_i_series
    if checkrun && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    for index_j=Index_j_series
        [i1,i2,j1,j2] = get_file_index(index_i,index_j,PairString);
        FullInputFile=fullfile_indices(FullRootFile,Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);

        [Field,~,errormsg] = nc2struct(FullInputFile);

        %%%%%%%%%%%% MAIN RUNNING OPERATIONS  %%%%%%%%%%%%

      
        FF=isnan(Field.U);%|Field.U<-60|Field.U>30;% threshold on U
        DataOut.Counter=DataOut.Counter+ ~FF;% add 1 to the couter for non NaN point
        Field.U(FF)=0;% set to 0 the nan values
        Field.V(FF)=0;
        Field.W(FF)=0;
        DataOut.UMean=DataOut.UMean+Field.U; %increment the sum
        DataOut.VMean=DataOut.VMean+Field.V; %increment the sum
        DataOut.WMean=DataOut.WMean+Field.W; %increment the sum
        U2Mean=U2Mean+(Field.U).*(Field.U); %increment the U squared sum
        V2Mean=V2Mean+(Field.V).*(Field.V); %increment the V squared sum
        W2Mean=W2Mean+(Field.W).*(Field.W); %increment the V squared sum
        UVMean=UVMean+(Field.U).*(Field.V); %increment the sum
        UWMean=UWMean+(Field.U).*(Field.W); %increment the sum
        VWMean=VWMean+(Field.V).*(Field.W); %increment the sum
    end
end

%%%%%%%%%%%%%%%% end loop on field indices %%%%%%%%%%%%%%%%

DataOut.Counter(DataOut.Counter==0)=1;% put counter to 1 when it is zero
DataOut.UMean=DataOut.UMean./DataOut.Counter; % normalize the mean
DataOut.VMean=DataOut.VMean./DataOut.Counter; % normalize the mean
DataOut.WMean=DataOut.WMean./DataOut.Counter; % normalize the mean
U2Mean=U2Mean./DataOut.Counter; % normalize the mean
V2Mean=V2Mean./DataOut.Counter; % normalize the mean
W2Mean=W2Mean./DataOut.Counter; % normalize the mean
UVMean=UVMean./DataOut.Counter; % normalize the mean
UWMean=UWMean./DataOut.Counter; % normalize the mean
VWMean=VWMean./DataOut.Counter; % normalize the mean
DataOut.u2Mean=U2Mean-DataOut.UMean.*DataOut.UMean; % normalize the mean
DataOut.v2Mean=V2Mean-DataOut.VMean.*DataOut.VMean; % normalize the mean
DataOut.w2Mean=W2Mean-DataOut.WMean.*DataOut.WMean; % normalize the mean
DataOut.uvMean=UVMean-DataOut.UMean.*DataOut.VMean; % normalize the mean \
DataOut.uwMean=UWMean-DataOut.UMean.*DataOut.WMean; % normalize the mean \
DataOut.vwMean=VWMean-DataOut.VMean.*DataOut.WMean; % normalize the mean \

%% writing the result file as netcdf file
errormsg=struct2nc(OutputFile,DataOut); %save result file
if isempty(errormsg)
    disp([OutputFile ' written']);
else
    disp(['error in writting result file: ' errormsg])
end


%% open the result file with uvmat (in RUN mode)
if checkrun && isequal(Param.IndexRange.NbSlice,1)
    uvmat(OutputFile)% open the last result file with uvmat
end
