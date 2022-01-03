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
%     by the Free Software Foundation; either version 2 of the license,series
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function ParamOut=sub_background_special (Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.NbViewMax=1;% max nbre of input file series (default , no limitation)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='on';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on'; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.sback';%set the output dir extension
    ParamOut.OutputFileMode='NbInput';% ='=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    %check the type of the existence and type of the first input file:
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
%% estimate the position of bottom and mask for each Z Index
NbSlice=Param.IndexRange.NbSlice;
switch NbSlice
    case 11
        BottomIndex=[1900 1800 1700 1650 1650 1600 1600 1600 1600 1600 1600];
    case 4
        BottomIndex=[1950 1850 1740 1700];
end
MaxIndex=BottomIndex+100;
MinIndex=BottomIndex-100;

maskindex=[665 1080];% range of x index perturbed by shadows 
Bfilter=ones(1,20)/20;
%% root input file names and nomenclature type (cell arrays with one element)
OutputDir=[Param.OutputSubDir Param.OutputDirExt];4
nbj=numel(Param.IndexRange.first_i:Param.IndexRange.last_i);
for i_ind=Param.IndexRange.first_i:Param.IndexRange.last_i
    ZIndex=mod(i_ind-1,NbSlice)+1; 
    for j_ind=Param.IndexRange.first_j:Param.IndexRange.last_j
        % read the current image
        InputFile=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},Param.InputTable{1,5},Param.InputTable{1,4},i_ind,i_ind,j_ind);
        A=imread(InputFile);
        % get the bottom as the max of luminosity along vertical lines    
        IndexMax=ones(1,size(A,2));%initiate the index position of the bottom
        if j_ind==Param.IndexRange.first_j
            indexMax_j=ones(nbj,size(A,2));%initiate the matrix of index position of the bottom
        end
        for icolumn=1:maskindex(1)
            [M,IndexMax(icolumn)] = max(A(MinIndex(ZIndex)+1:MaxIndex(ZIndex),icolumn),[],1);
        end
        [M,IndexMax(maskindex(2))] = max(A(MinIndex(ZIndex)+1:MaxIndex(ZIndex),maskindex(2)),[],1);
        for icolumn=maskindex(1)+1:maskindex(2)-1 % linear interpolation in the masked region
            IndexMax(icolumn)= IndexMax(maskindex(1))*(maskindex(2)-icolumn)+IndexMax(maskindex(2))*(icolumn-maskindex(1));
            IndexMax(icolumn)=IndexMax(icolumn)/(maskindex(2)-maskindex(1));
        end
        for icolumn=maskindex(2)+1:size(A,2)
            [M,IndexMax(icolumn)] = max(A(MinIndex(ZIndex)+1:MaxIndex(ZIndex),icolumn),[],1);
        end
        IndexFilt=filter(Bfilter,1,IndexMax);% smoothed IndexMax
        peakdetect=find(abs(IndexFilt-IndexMax)>5);% detect strong departures from the filtered values
        IndexMax(peakdetect)=IndexFilt(peakdetect);%replace the peaks by the filtered values
        IndexMax_j(j_ind,:)=round(filter(Bfilter,1,IndexMax));%filter again and take the closest integer
        % get the background image as the min at each point in the j series 
        if j_ind==Param.IndexRange.first_j
            Amin=A;
        else
            Amin=min(Amin,A);
        end
    end
    
    for j_ind=Param.IndexRange.first_j:Param.IndexRange.last_j
        InputFile=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},Param.InputTable{1,5},Param.InputTable{1,4},i_ind,i_ind,j_ind);
        A=imread(InputFile);
        A=A-Amin;
        for icolumn=1:size(A,2)
            A(MinIndex(ZIndex)+IndexMax_j(j_ind,icolumn):end,icolumn)=0;
        end
        OutputFile=fullfile_uvmat(Param.InputTable{1,1},OutputDir,Param.InputTable{1,3},Param.InputTable{1,5},Param.InputTable{1,4},i_ind,i_ind,j_ind);
        imwrite(A,OutputFile)
        disp([OutputFile ' written'])
    end
end






 

