%'turb_correlation_x': calculate the x wise correlation function at each point
%------------------------------------------------------------------------
% function ParamOut=turb_correlation_x(Param)
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

function ParamOut=turb_correlation_x(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice=1;%nbre of slices, 1 prevents splitting in several processes, ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.corr_x';%set the output dir extension
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
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% define the directory for result file (with path=RootPath{1})
OutputDir=[Param.OutputSubDir Param.OutputDirExt];
    
%% root input file(s) name, type and index series
RootPath=Param.InputTable{:,1};
RootFile=Param.InputTable{:,3};
%SubDir=Param.InputTable(:,2);
NomType=Param.InputTable{1,4};
%FileExt=Param.InputTable(:,5);
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
%%%%%%%%%%%%
% The cell array filecell is the list of input file names, while
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%% NbView=1 : a single input series
%NbView=numel(i1_series);%number of input file series (lines in InputTable)
NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%% determine the file type on each line from the first input file

[FileInfo,MovieObject]=get_file_info(filecell{1,1});
FileType=FileInfo.FileType;

if ~isempty(j1_series{1})
    frame_index=j1_series{1};
else
    frame_index=i1_series{1};
end

%% settings for the output file
FileExtOut='.nc';% write result as .nc files for netcdf inputs
NomTypeOut=nomtype2pair(NomType);% determine the index nomenclature type for the output file
first_i=i1_series{1}(1);
last_i=i1_series{1}(end);
if isempty(j1_series{1})% if there is no second index j
    first_j=1;last_j=1;
else
    first_j=j1_series{1}(1);
    last_j=j1_series{1}(end);
end

%% Set field names and velocity types
InputFields{1}=[];%default (case of images)
%%%%%%%%%%%%%%%%%%%%%
if isfield(Param.IndexRange,'TimeSource') && find(regexp(Param.IndexRange.TimeSource,'^var:'))==1
    Param.InputFields.TimeVarName=regexprep(Param.IndexRange.TimeSource,'^var:','');
end
%%%%%%%%%%%%%%%%%%%%
% if isfield(Param,'InputFields')
%     InputFields{1}=Param.InputFields;
% end
Param.InputFields.FieldName={'Uprime','Vprime'};
nbfiles=0;
nbmissing=0;

%initialisation
DataOut.ListGlobalAttribute= {'Conventions'};
DataOut.Conventions= 'uvmat';
DataOut.ListVarName={'delta_x','coord_y','coord_x','UUCorr' , 'VVCorr','UVCorr','Counter'};
DataOut.VarDimName={'delta_x','coord_y','coord_x',...
    {'delta_x','coord_y','coord_x'},{'delta_x','coord_y','coord_x'},{'delta_x','coord_y','coord_x'},{'delta_x','coord_y','coord_x'}};
DataOut.UUCorr=0;
DataOut.Counter=0;

%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
% First get mean values %
disp('loop for mean started')
for index=1:NbField
    %     if ~isempty(RUNHandle)&& ~strcmp(get(RUNHandle,'BusyAction'),'queue')
    %         disp('program stopped by user')
    %         break
    %     end
    [Field,~,errormsg] = read_field(filecell{1,index},FileType,Param.InputFields,frame_index(index));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Field.U=Field.Uprime;
    Field.V=Field.Vprime;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if index==1 %first field
        if ~isfield(Field,'U')||~isfield(Field,'V')
            disp_uvmat('ERROR','this function requires the velocity components U and V as input',checkrun)
            return
        end
        
        [npy,npx]=size(Field.U);
        UMean=zeros(npy,npx);
        VMean=zeros(npy,npx);
        Counter=zeros(npy,npx);
        % transcripts the global attributes
        if isfield(Field,'ListGlobalAttribute')
            DataOut.ListGlobalAttribute= Field.ListGlobalAttribute;
            for ilist=1:numel(Field.ListGlobalAttribute)
                AttrName=Field.ListGlobalAttribute{ilist};
                DataOut.(AttrName)=Field.(AttrName);
            end
        end
    end
    FF=isnan(Field.U);%|Field.U<-60|Field.U>30;% threshold on U
    Field.U(FF)=0;% set to 0 the nan values,
    Field.V(FF)=0;
    UMean=UMean+Field.U;
    VMean=VMean+Field.V;
    Counter=Counter+~FF;
end
Counter(Counter==0)=1;
UMean=UMean./Counter;
VMean=VMean./Counter;


%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
disp('loop for correlation started')
for index=1:NbField
    if ~isempty(RUNHandle)&& ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        break
    end
    [Field,~,errormsg] = read_field(filecell{1,index},FileType,Param.InputFields,frame_index(index));
    Field.U=Field.Uprime;
    Field.V=Field.Vprime;
    %%%%%%%%%%%% MAIN RUNNING OPERATIONS  %%%%%%%%%%%%
    if index==1 %first field
        [npy,npx]=size(Field.U);
        npcorr=floor(npx/4); %nbre of points for the correlation fct on each side of 0
        dx=(Field.coord_x(end)-Field.coord_x(1))/(numel(Field.coord_x)-1);
        DataOut.delta_x=(-dx*npcorr:dx:dx*npcorr)';
        DataOut.coord_x=Field.coord_x;
        DataOut.coord_y=Field.coord_y;
        DataOut.UUCorr=zeros(2*npcorr+1,npy,npx);
        DataOut.VVCorr=zeros(2*npcorr+1,npy,npx);
        DataOut.UVCorr=zeros(2*npcorr+1,npy,npx);
        DataOut.Counter=zeros(2*npcorr+1,npy,npx);
    end
    FF=isnan(Field.U);%|Field.U<-60|Field.U>30;% threshold on U
    Field.U(FF)=0;% set to 0 the nan values,'delta_x'
    Field.V(FF)=0;
    Field.U=Field.U-UMean;
    Field.V=Field.V-VMean;
    UUCorr=zeros(2*npcorr+1,npy,npx);
    VVCorr=zeros(2*npcorr+1,npy,npx);
    UVCorr=zeros(2*npcorr+1,npy,npx);
    FFCorr=false(2*npcorr+1,npy,npx);
    for ishift=-npcorr:npcorr% calculate the field U shifted
        U_shift=circshift(Field.U,[0 -ishift]); %shift U by ishift along the index x
        V_shift=circshift(Field.V,[0 -ishift]); %shift U by ishift along the index x
        FF_shift=circshift(FF,[0 -ishift]); %shift U by ishift along the index x
        if ishift<0
            U_shift(:,1:-ishift)=0;
            V_shift(:,1:-ishift)=0;
            FF_shift(:,1:-ishift)=1;
        elseif ishift>0
            U_shift(:,end-ishift:end)=0;
            V_shift(:,end-ishift:end)=0;
            FF_shift(:,end-ishift:end)=1;
        end
        UUCorr(ishift+npcorr+1,:,:)=Field.U.*U_shift;
        VVCorr(ishift+npcorr+1,:,:)=Field.V.*V_shift;
        UVCorr(ishift+npcorr+1,:,:)=Field.U.*V_shift;
        FFCorr(ishift+npcorr+1,:,:)=FF | FF_shift;
    end
    DataOut.UUCorr=DataOut.UUCorr+UUCorr;
    DataOut.VVCorr=DataOut.VVCorr+VVCorr;
    DataOut.UVCorr=DataOut.UVCorr+UVCorr;
    DataOut.Counter=DataOut.Counter+~FFCorr;
end
%%%%%%%%%%%%%%%% end loop on field indices %%%%%%%%%%%%%%%%
DataOut.Counter(DataOut.Counter==0)=1;
size(DataOut.UUCorr)
size(DataOut.VVCorr)
size(DataOut.Counter)
DataOut.UUCorr=DataOut.UUCorr./DataOut.Counter;
DataOut.VVCorr=DataOut.VVCorr./DataOut.Counter;
DataOut.UVCorr=DataOut.UVCorr./DataOut.Counter;
%DataOut.Counter(DataOut.Counter==0)=1;% put counter to 1 when it is zero
% DataOut.UMean=DataOut.UMean./DataOut.Counter; % normalize the mean
% DataOut.VMean=DataOut.VMean./DataOut.Counter; % normalize the mean
% U2Mean=U2Mean./DataOut.Counter; % normalize the mean
% V2Mean=V2Mean./DataOut.Counter; % normalize the mean
% UVMean=UVMean./DataOut.Counter; % normalize the mean
% U2Mean_1=U2Mean_1./Counter_1; % normalize the mean
% V2Mean_1=V2Mean_1./Counter_1; % normalize the mean
% DataOut.u2Mean=U2Mean-DataOut.UMean.*DataOut.UMean; % normalize the meanFFCorr
% DataOut.v2Mean=V2Mean-DataOut.VMean.*DataOut.VMean; % normalize the mean
% DataOut.uvMean=UVMean-DataOut.UMean.*DataOut.VMean; % normalize the mean \
% DataOut.u2Mean_1=U2Mean_1-DataOut.UMean.*DataOut.UMean; % normalize the mean
% DataOut.v2Mean_1=V2Mean_1-DataOut.VMean.*DataOut.VMean; % normalize the mean


%% calculate the profiles
% npx=numel(DataOut.coord_x);
% band=ceil(npx/5) :floor(4*npx/5);% keep only the central band
% for ivar=3:numel(DataOut.ListVarName)-1
%     VarName=DataOut.ListVarName{ivar};% name of the variable
%     DataOut.ListVarName=[DataOut.ListVarName {[VarName 'Profile']}];%append the name of the profile variable
%     DataOut.VarDimName=[DataOut.VarDimName {'coord_y'}];
%    DataOut.([VarName 'Profile'])=mean(DataOut.(VarName)(:,band),2); %take the mean profile of U, excluding the edges
% end

%% writing the result file as netcdf file
OutputFile=fullfile_uvmat(RootPath,OutputDir,RootFile,FileExtOut,NomTypeOut,first_i,last_i,first_j,last_j);
 %case of netcdf input file , determine global attributes
 errormsg=struct2nc(OutputFile,DataOut); %save result file
 if isempty(errormsg)
     disp([OutputFile ' written']);
 else
     disp(['error in writting result file: ' errormsg])
 end

