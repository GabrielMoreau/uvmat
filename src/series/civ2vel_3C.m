%'civ2vel_3C': combine velocity fields from two cameras to get three velocity components
%------------------------------------------------------------------------
% function ParamOut=civ2vel_3C(Param)
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
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%              .Coord_y: name of y coordinate variable
%              .Coord_x: name of x coordinate variable'

%=======================================================================
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function ParamOut=civ2vel_3C(Param)

%% set the input elements needed on the GUI series when the function is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%use the phys  transform function without choice
    %ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.ProjObject='on';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.vel3C';%set the output dir extension
    ParamOut.OutputSubDirMode='two'; % the two first input lines are used to define the output subfolder
    ParamOut.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    %check the input files
    first_j=[];
    if size(Param.InputTable,1)<2
        msgbox_uvmat('WARNING',['two or three input file series are needed'])
    end
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('WARNING',['the first input file ' FirstFileName ' does not exist'])
    elseif isequal(size(Param.InputTable,1),1) && ~isfield(Param,'ProjObject')
        msgbox_uvmat('WARNING','You may need a projection object of type plane for merge_proj')
    end
    return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
ParamOut=[]; %default output
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
hdisp=disp_uvmat('WAITING...','checking the file series',checkrun);
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
if ~isempty(hdisp),delete(hdisp),end;
%%%%%%%%%%%%
% The cell array filecell is the list of input file names, while
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series,
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%%
NbView=numel(i1_series);%number of input file series (lines in InputTable)
NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%% define the directory for result file (with path=RootPath{1})
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files
%
% if ~isfield(Param,'InputFields')
%     Param.InputFields.FieldName='';
% end

%% calibration data and timing: read the ImaDoc files
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
if size(time,1)>1
    diff_time=max(max(diff(time)));
    if diff_time>0
        disp_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time) ': the mean time is chosen in result'],checkrun)
    end
end
if ~isempty(errormsg)
    disp_uvmat('WARNING',errormsg,checkrun)
end
time=mean(time,1); %averaged time taken for the merged field
if isfield(XmlData{1},'GeometryCalib')
    tsaiA=XmlData{1}.GeometryCalib;
else
    disp_uvmat('ERROR','no geometric calibration available for image A',checkrun)
    return
end
if isfield(XmlData{2},'GeometryCalib')
    tsaiB=XmlData{2}.GeometryCalib;
else
    disp_uvmat('ERROR','no geometric calibration available for image B',checkrun)
    return
end
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);

%% grid of physical positions (given by projection plane)
if ~Param.CheckObject
    disp_uvmat('ERROR','a projection plane with interpolation is needed',checkrun)
    return
end
ObjectData=Param.ProjObject;
xI=ObjectData.RangeX(1):ObjectData.DX:ObjectData.RangeX(2);
yI=ObjectData.RangeY(1):ObjectData.DY:ObjectData.RangeY(2);
[XI,YI]=meshgrid(xI,yI);
U=zeros(size(XI,1),size(XI,2));
V=zeros(size(XI,1),size(XI,2));
W=zeros(size(XI,1),size(XI,2));

%% MAIN LOOP ON FIELDS
warning off
for index=1:NbField
    update_waitbar(WaitbarHandle,index/NbField)
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    
    %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
    Data=cell(1,NbView);%initiate the set Data
    timeread=zeros(1,NbView);
    [Data{3},tild,errormsg] = nc2struct(filecell{3,index});
    ZI=griddata(Data{3}.Xphys,Data{3}.Yphys,Data{3}.Zphys,XI,YI);
    [Xa,Ya]=px_XYZ(XmlData{1}.GeometryCalib,XI,YI,ZI);% set of image coordinates on view a
    [Xb,Yb]=px_XYZ(XmlData{2}.GeometryCalib,XI,YI,ZI);% set of image coordinates on view b
    
    %trouver z
    % trouver les coordonnées px sur chaque image.
    %A=
    for iview=1:2
        %% reading input file(s)
        [Data{iview},tild,errormsg]=read_civdata(filecell{iview,index},{'vec(U,V)'},'*');
        if ~isempty(errormsg)
            disp_uvmat('ERROR',['ERROR in civ2vel_3C/read_field/' errormsg],checkrun)
            return
        end
        % get the time defined in the current file if not already defined from the xml file
        if isfield(Data{iview},'Time')&& isequal(Data{iview}.Time,Data{1}.Time)
            Time=Data{iview}.Time;
        else
            disp_uvmat('ERROR','Time undefined or not synchronous',checkrun)
            return
        end
        if isfield(Data{iview},'Dt')&& isequal(Data{iview}.Dt,Data{1}.Dt)
            Dt=Data{iview}.Dt;
        else
            disp_uvmat('ERROR','Dt undefined or not synchronous',checkrun)
            return
        end
    end
    Ua=griddata(Data{1}.X,Data{1}.Y,Data{1}.U,Xa,Ya);
    Va=griddata(Data{1}.X,Data{1}.Y,Data{1}.V,Xa,Ya);
    A=get_coeff(XmlData{1}.GeometryCalib,Xa,Ya,YI,YI,ZI);
    
    Ub=griddata(Data{2}.X,Data{2}.Y,Data{1}.U,Xb,Yb);
    Vb=griddata(Data{2}.X,Data{2}.Y,Data{2}.V,Xb,Yb);
    B=get_coeff(XmlData{2}.GeometryCalib,Xb,Yb,YI,YI,ZI);
    S=ones(size(XI,1),size(XI,2),3);
    D=ones(size(XI,1),size(XI,2),3,3);
    S(:,:,1)=A(:,:,1,1).*Ua+A(:,:,2,1).*Va+B(:,:,1,1).*Ub+B(:,:,2,1).*Vb;
    S(:,:,2)=A(:,:,1,2).*Ua+A(:,:,2,2).*Va+B(:,:,1,2).*Ub+B(:,:,2,2).*Vb;
    S(:,:,3)=A(:,:,1,3).*Ua+A(:,:,2,3).*Va+B(:,:,1,3).*Ub+B(:,:,2,3).*Vb;
    D(:,:,1,1)=A(:,:,1,1).*A(:,:,1,1)+A(:,:,2,1).*A(:,:,2,1)+B(:,:,1,1).*B(:,:,1,1)+B(:,:,2,1).*B(:,:,2,1);
    D(:,:,1,2)=A(:,:,1,1).*A(:,:,1,2)+A(:,:,2,1).*A(:,:,2,2)+B(:,:,1,1).*B(:,:,1,2)+B(:,:,2,1).*B(:,:,2,2);
    D(:,:,1,3)=A(:,:,1,1).*A(:,:,1,3)+A(:,:,2,1).*A(:,:,2,3)+B(:,:,1,1).*B(:,:,1,3)+B(:,:,2,1).*B(:,:,2,3);
    D(:,:,2,1)=A(:,:,1,2).*A(:,:,1,1)+A(:,:,2,2).*A(:,:,2,1)+B(:,:,1,2).*B(:,:,1,1)+B(:,:,2,2).*B(:,:,2,1);
    D(:,:,2,2)=A(:,:,1,2).*A(:,:,1,2)+A(:,:,2,2).*A(:,:,2,2)+B(:,:,1,2).*B(:,:,1,2)+B(:,:,2,2).*B(:,:,2,2);
    D(:,:,2,3)=A(:,:,1,2).*A(:,:,1,3)+A(:,:,2,2).*A(:,:,2,3)+B(:,:,1,2).*B(:,:,1,3)+B(:,:,2,2).*B(:,:,2,3);
    D(:,:,3,1)=A(:,:,1,3).*A(:,:,1,1)+A(:,:,2,3).*A(:,:,2,1)+B(:,:,1,3).*B(:,:,1,1)+B(:,:,2,3).*B(:,:,2,1);
    D(:,:,3,2)=A(:,:,1,3).*A(:,:,1,2)+A(:,:,2,3).*A(:,:,2,2)+B(:,:,1,3).*B(:,:,1,2)+B(:,:,2,3).*B(:,:,2,2);
    D(:,:,3,3)=A(:,:,1,3).*A(:,:,1,3)+A(:,:,2,3).*A(:,:,2,3)+B(:,:,1,3).*B(:,:,1,3)+B(:,:,2,3).*B(:,:,2,3);
    for indj=1:size(XI,1)
        for indi=1:size(XI,2)
            dxyz=squeeze(S(indj,indi,:))\squeeze(D(indj,indi,:,:));
            U(indj,indi)=dxyz(1);
            V(indj,indi)=dxyz(2);
            W(indj,indi)=dxyz(3);
        end
    end   
    Error=zeros(size(XI,1),size(XI,2),4);
    Error(:,:,1)=A(:,:,1,1).*U+A(:,:,1,2).*V+A(:,:,1,3).*W-Ua;
    Error(:,:,2)=A(:,:,2,1).*U+A(:,:,2,2).*V+A(:,:,2,3).*W-Va;
    Error(:,:,3)=B(:,:,1,1).*U+B(:,:,1,2).*V+B(:,:,1,3).*W-Ub;
    Error(:,:,4)=B(:,:,2,1).*U+B(:,:,2,2).*V+B(:,:,2,3).*W-Vb;
    
    %% generating the name of the merged field
    i1=i1_series{1}(index);
    if ~isempty(i2_series{end})
        i2=i2_series{end}(index);
    else
        i2=i1;
    end
    j1=1;
    j2=1;
    if ~isempty(j1_series{1})
        j1=j1_series{1}(index);
        if ~isempty(j2_series{end})
            j2=j2_series{end}(index);
        else
            j2=j1;
        end
    end
    OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},'.nc','_1-2',i1,i2,j1,j2);
    
    %% recording the merged field
    if index==1% initiate the structure at first index
        MergeData.ListGlobalAttribute={'Conventions','Time','Dt'};
        MergeData.Conventions='uvmat';
        MergeData.Time=Time;
        MergeData.Dt=Dt;
        MergeData.ListVarName={'coord_x','coord_y','Z','U','V','W','Error'};
        MergeData.VarDimName={'coord_x','coord_y',{'coord_y','coord_x'},{'coord_y','coord_x'}...
                {'coord_y','coord_x'},{'coord_y','coord_x'},{'coord_y','coord_x'}};
        MergeData.coord_x=xI;
        MergeData.coord_y=yI;
        MergeData.Z=ZI;
    end
    MergeData.U=U/Dt;
    MergeData.V=V/Dt;
    MergeData.W=W/Dt;
    MergeData.Error=sqrt(sum(Error.*Error,3));
    errormsg=struct2nc(OutputFile,MergeData);%save result file
    if isempty(errormsg)
        disp(['output file ' OutputFile ' written'])
    else
        disp(errormsg)
    end
end


function A=get_coeff(Calib,X,Y,x,y,z)
R=(Calib.R)';%rotation matrix
T_z=Calib.Tx_Ty_Tz(3);
T=R(7)*x+R(8)*y+R(9)*z+T_z;
A(:,:,1,1)=(R(1)-R(7)*X)./T;
A(:,:,1,2)=(R(2)-R(8)*X)./T;
A(:,:,1,3)=(R(3)-R(9)*X)./T;
A(:,:,2,1)=(R(4)-R(7)*Y)./T;
A(:,:,2,2)=(R(5)-R(8)*Y)./T;
A(:,:,2,3)=(R(6)-R(9)*Y)./T;







