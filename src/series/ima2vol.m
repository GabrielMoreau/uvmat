%'ima2vol': concatene  image series to form a 'volume' image, make vertical cuts along x and y
%------------------------------------------------------------------------
% function GUI_input=ima2vol(num_i1,num_i2,num_j1,num_j2,Series)
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
%num_i1: series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2:  series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1:  series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2:  series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%Series: Matlab structure containing information set by the series interface
%
%----------------------------------------------------------------------

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function ParamOut=ima2vol(Param)

%% set the input elements needed on the GUI series when the function is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='one';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'on';%can use a transform function
    ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.ProjObject='on';%can use projection object(option 'off'/'on',
    ParamOut.Mask='on';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.vol';%set the output dir extension
    ParamOut.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
      %check the input files
    ParamOut.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default=1)
    first_j=[];
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
%% read input parameters from an xml file if input is a file name (batch mode)
ParamOut=[];
RUNHandle=[];
WaitbarHandle=[];
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
else% interactive mode in Matlab
    hseries=findobj(allchild(0),'Tag','series');
    RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
    WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series
end

%% subdirectory for output files
SubdirOut=[Param.OutputSubDir Param.OutputDirExt];

%% root input file names and nomenclature type (cell arrays with one element)
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);


%% get the set of input file names (cell array filecell), and file indices
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
% filecell{iview,fileindex}: cell array representing the list of file names
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields
[FileInfo{1},VideoObject{1}]=get_file_info(filecell{1,1});% type of input file
FileType{1}=FileInfo{1}.FileType;

%% calibration data and timing: read the ImaDoc files
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
if ~isempty(errormsg)
    disp_uvmat('WARNING',errormsg,checkrun)
end

%% coordinate transform or other user defined transform
transform_fct='';%default fct handle
if isfield(Param,'FieldTransform')&&~isempty(Param.FieldTransform.TransformName)
        currentdir=pwd;
        cd(Param.FieldTransform.TransformPath)
        transform_fct=str2func(Param.FieldTransform.TransformName);
        cd (currentdir)      
end

%% main loop
for ifile=1:nbfield_i
    update_waitbar(WaitbarHandle,ifile/nbfield)
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    for jfile=1:nbfield_j
        if ~isempty(j1_series)&&~isequal(j1_series,{[]})
            j1=j1_series{1}(jfile,ifile);
        end
        filename=fullfile_uvmat(RootPath{1},SubDir{1},RootFile{1},FileExt{1},NomType{1},i1_series{1}(jfile,ifile),[],j1)
        [Data,tild,errormsg] = read_field(filename,'image');
        % transform the input field (e.g; phys) if requested (no transform involving two input fields)
        if ~isempty(transform_fct)
            Data.ZIndex=jfile;
            Data=transform_fct(Data,XmlData{1});
        end
        if jfile==1
            VolData.A=zeros(nbfield_j,size(Data.A,1),size(Data.A,2));
            VolData.Coord_z=1:nbfield_j;%default Z values
        end
        VolData.A(jfile,:,:)=Data.A;%concacene along y
        VolData.Coord_z(jfile)=XmlData{1}.GeometryCalib.SliceCoord(jfile,3);
    end
%         npx=size(Data.A,2);
%         npy=size(Data.A,1);
%         npz=256;
%         ind_x=round(npx/2)-10:round(npx/2)+10;%image index at the mid x position
%         ind_y=round(npy/2)-10:round(npy/2)+10;%image index at the mid y position
%         ind_y=ind_y-100;% shift to avoid the injector
%         %write xml calibration file, using the first file
%             Rangx=Data.Coord_x;
%             Rangy=Data.Coord_y;
%             Rangz=[Z(end) Z(1)];
%     
%         GeometryCal.CalibrationType='rescale';
%         GeometryCal.CoordUnit=Data.CoordUnit;
%         GeometryCal.focal=1;
%         %scaling along x, y and z
%         pxcmx=(npx-1)/(Rangx(2)-Rangx(1));
%         pxcmy=(npy-1)/(Rangy(1)-Rangy(2));
%         pxcmz=(npz-1)/(Rangz(2)-Rangz(1));
%         T_x=-pxcmx*Rangx(1)+0.5;
%         T_y=-pxcmy*Rangy(2)+0.5;
%         T_z=-pxcmz*Rangz(2)+0.5;
%         % xml file for x cut
%         GeometryCal.R=[pxcmx,0,0;0,pxcmz,0;0,0,1];
%         GeometryCal.Tx_Ty_Tz=[T_x T_z 1];
%         ImaDoc.GeometryCalib=GeometryCal;
%         t=struct2xml(ImaDoc);
%         t=set(t,1,'name','ImaDoc');
%         save(t,fullfile(RootPath{1},SubdirOut,'cut_x.xml'))
%                    % xml file for y cut
%         GeometryCal.R=[pxcmy,0,0;0,pxcmz,0;0,0,1];
%         GeometryCal.Tx_Ty_Tz=[T_y T_z 1];
%         ImaDoc.GeometryCalib=GeometryCal;
%         t=struct2xml(ImaDoc);
%         t=set(t,1,'name','ImaDoc');
%         save(t,fullfile(RootPath{1},SubdirOut,'cut_y.xml')) 
%     end
    
    filename=fullfile_uvmat(RootPath{1},SubdirOut,RootFile{1},'.nc','_1',i1_series{1}(jfile,ifile),[],j1);
    VolData.ListVarName={'Coord_z','Coord_y','Coord_x','A'};
    VolData.VarDimName={'Coord_z','Coord_y','Coord_x',{'Coord_z','Coord_y','Coord_x'}};
    VolData.Coord_x=Data.Coord_x;
    VolData.Coord_y=Data.Coord_y;
    struct2nc(filename,VolData)
    disp([filename ' written'])
end



