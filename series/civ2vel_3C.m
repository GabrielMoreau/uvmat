%'civ2vel_3C': combine the civ velocity fields from two cameras to get three velocity components
%------------------------------------------------------------------------
% function GUIParam=civ2vel_3C(Param)
%
%OUTPUT
% GUIParam: sets options in the GUI series.fig needed for the function
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

function GUIParam=civ2vel_3C(Param)

%% set the input elements needed on the GUI series when the function is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    GUIParam.NbSlice='off'; %nbre of slices ('off' by default) !!VERIFIER
    GUIParam.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)!!VERIFIER
    GUIParam.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    GUIParam.ProjObject='on';%can use projection object(option 'off'/'on',
    GUIParam.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)!!VERIFIER
    GUIParam.OutputDirExt='.vel3C';%set the output dir extension
    GUIParam.OutputSubDirMode='two'; % the two first input lines are used to define the output subfolder
    GUIParam.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    %check the input files
    GUIParam.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default=1)
    first_j=[];
    if size(Param.InputTable,1)<2
        msgbox_uvmat('ERROR','two or three input file series are needed')
        return
    end
    if  ~(isfield(Param,'CheckObject')&& Param.CheckObject)
        msgbox_uvmat('ERROR','You  need a projection object of type plane')
        return
    end
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if exist(FirstFileName,'file')
        FileInfo=get_file_info(FirstFileName);
        if ~strcmp(FileInfo.FieldType,'civdata')
            msgbox_uvmat('ERROR','civ data are needed as input')
            return
        end
    else
        msgbox_uvmat('ERROR',['the first input file ' FirstFileName ' does not exist'])
        return
    end
    VelocityRange=[];%default
    if isfield(Param,'ActionInput') && isfield(Param.ActionInput,'VelocityRange')
        VelocityRange= Param.ActionInput.VelocityRange;
    end

    prompt = {'velocity range (max modulus) for 16 bit integer records (32 bit reals if empty)'};
    dlg_title = 'set scale_factor for result writing as 16 bit integer (instead of 32 bit reals by default)';
    num_lines= 1;
    def     = { num2str(VelocityRange)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        return
    end
    GUIParam.ActionInput.VelocityRange=str2double(answer{1});
    return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
GUIParam=[]; %default output
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series


%% root input file(s) name, type and index series
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);
hdisp=disp_uvmat('WAITING...','checking the file series',checkrun);
%[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
NbView=size(Param.InputTable,1);
for iview=1:NbView
    XmlFileName=find_imadoc(Param.InputTable{iview,1},Param.InputTable{iview,2});
    if ~isempty(XmlFileName)
        [XmlData{iview},errormsg]=imadoc2struct(XmlFileName);%read the time from XmlFileName
        if ~isempty(errormsg)
            disp(errormsg)
            return
        end
    end
    FullRootFile=fullfile(Param.InputTable{iview,1},Param.InputTable{iview,2},Param.InputTable{iview,3});
    if isfield(Param.IndexRange,'PairString')
        PairString{iview}=Param.IndexRange.PairString;
    end
    first_j=1;
    if isfield(Param.IndexRange,'first_j')
        first_j=Param.IndexRange.first_j;
    end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString{iview});
    FirstFileName=fullfile_indices(FullRootFile,Param.InputTable{iview,5},Param.InputTable{iview,4},i1,i2,j1,j2);%get first file name
    FileInfo{iview}=get_file_info(FirstFileName);
    FileType{iview}=FileInfo{iview}.FileType;
end
if ~isempty(hdisp),delete(hdisp),end

%% calibration data and timing: read the ImaDoc files
if ~isfield(XmlData{1},'GeometryCalib')
    disp_uvmat('ERROR','no geometric calibration available for image A',checkrun)
    return
end
if ~isfield(XmlData{2},'GeometryCalib')
    disp_uvmat('ERROR','no geometric calibration available for image B',checkrun)
    return
end

Plane_A=XmlData{1}.Slice.SliceCoord;
Plane_B=XmlData{2}.Slice.SliceCoord;
if ~isequal(Plane_A,Plane_B)
    disp_uvmat('ERROR','the two views are not in the same reference plane',checkrun)
    return
end
Zref=Plane_A(3); % reference z position (no tilt assumed)

%% grid of physical positions (given by projection plane)
if ~Param.CheckObject
    disp_uvmat('ERROR','a projection plane with interpolation is needed',checkrun)
    return
end
ObjectData=Param.ProjObject;
xI=ObjectData.RangeX(1):ObjectData.DX:ObjectData.RangeX(2);
yI=ObjectData.RangeY(1):ObjectData.DY:ObjectData.RangeY(2);
[XI,YI]=meshgrid(xI,yI);
[Npy,Npx]=size(XI);
XI=reshape(XI,[],1);
YI=reshape(YI,[],1);
U=zeros(size(XI,1),size(XI,2));
V=zeros(size(XI,1),size(XI,2));
W=zeros(size(XI,1),size(XI,2));
CheckZ=(NbView>2);% check the existence of a Z field 

%% define the directory for result file (with path=RootPath{1})
OutputPath=fullfile(Param.OutputPath,num2str(Param.Experiment),num2str(Param.Device));
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files
RootFileOut='field';
if ~(isfield(Param.IndexRange,'MaxIndex_j') && (Param.IndexRange.MaxIndex_j-Param.IndexRange.MinIndex_j>0))
    NomTypeOut='_1';
else
    NomTypeOut='_1_1';
end

%% Prepare the output field structure
MergeData.ListGlobalAttribute={'Conventions','Time','Dt','CoordUnit'};
MergeData.Conventions='uvmat';
if isfield (XmlData{1}.GeometryCalib,'CoordUnit') && isfield (XmlData{2}.GeometryCalib,'CoordUnit') && strcmp(XmlData{1}.GeometryCalib.CoordUnit, XmlData{2}.GeometryCalib.CoordUnit)
    MergeData.CoordUnit=XmlData{1}.GeometryCalib.CoordUnit;
else
    disp_uvmat('ERROR','inconsistent coord units in the two input velocity series',checkrun)
    return
end
MergeData.ListVarName={'coord_x','coord_y','U','V','W','Error'};
MergeData.VarDimName={'coord_x','coord_y',{'coord_y','coord_x'},{'coord_y','coord_x'}...
    {'coord_y','coord_x'},{'coord_y','coord_x'}};
MergeData.VarAttribute{1}.Role='coord_x';
MergeData.VarAttribute{2}.Role='coord_y';
MergeData.VarAttribute{3}.Role='vector_x';
MergeData.VarAttribute{4}.Role='vector_y';
MergeData.VarAttribute{5}.Role='vector_z';
MergeData.VarAttribute{6}.Role='ancillary';
MergeData.VarAttribute{6}.units='pixel'; %error estimate expressed in pixel
MergeData.VarAttribute{6}.scale_factor=1/1000;% value multiplied by 10000 to get an integer
if CheckZ
    nbvar=numel(MergeData.ListVarName);
    MergeData.ListVarName=[MergeData.ListVarName {'Z'}];
    MergeData.VarDimName{nbvar+1}={'coord_y','coord_x'};
end
MergeData.coord_x=xI;
MergeData.coord_y=yI;



%% Parameters for input and output
warning off
CheckOverwrite=true;%default
if isfield(Param,'CheckOverwrite')
    CheckOverwrite=Param.CheckOverwrite;
end
VelType='*';%latest field filter2 opened by default
if isfield(Param.InputFields,'VelType')
    VelType=Param.InputFields.VelType;%imposed civ or filter
end

%% define a range of values to store results as integers for projection of PIV data
scale_factor_inv_uv=[];
if isfield(Param.ActionInput,'VelocityRange') && ~isempty(Param.ActionInput.VelocityRange)
    scale_factor_inv_uv=floor(32767/Param.ActionInput.VelocityRange);
end

Index_i_series=Param.IndexRange.first_i:Param.IndexRange.incr_i:Param.IndexRange.last_i;
if isfield(Param.IndexRange,'last_j')
    Index_j_series=Param.IndexRange.first_j:Param.IndexRange.incr_j:Param.IndexRange.last_j;
else
    Index_j_series=1;
end

%%%%%%--------------------MAIN LOOP ON FIELD SERIES -------------%%%%%%
for index_i=Index_i_series
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    for index_j=Index_j_series
        %% generating the name of the merged field
        OutputFile=fullfile_indices(fullfile(OutputPath,OutputDir,RootFileOut),'.nc',NomTypeOut,index_i,[],index_j);
        % OutputFile=fullfile_uvmat(OutputPath,OutputDir,RootFileOut,'.nc',NomTypeOut,index_i,[],index_j);
        if ~CheckOverwrite && exist(OutputFile,'file')
            disp(['existing output file ' OutputFile ' already exists, skip to next field'])
            continue% skip iteration if the mode overwrite is desactivated and the result file already exists
        end

        %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
        Data=cell(1,NbView);%initiate the set Data

        for iview=1:2
            %% reading input file(s)
            % generating the name of the input field
            [i1,i2,j1,j2] = get_file_index(index_i,index_j,PairString{iview});

            NomType=Param.InputTable{iview,4};
            FullRootFile=fullfile(Param.InputTable{iview,1},Param.InputTable{iview,2},Param.InputTable{iview,3});
            FullInputFile=fullfile_indices(FullRootFile,Param.InputTable{iview,5},NomType,i1,i2,j1,j2);

            [Data{iview},~,errormsg]=read_civdata(FullInputFile,{'vec(U,V)'},VelType);
            if isempty(errormsg)
                disp([FullInputFile ' read'])
            else
                disp_uvmat('ERROR',['ERROR in civ2vel_3C/read_field/' errormsg],checkrun)
                return
            end
            % get the time defined in the current file if not already defined from the xml file
            if isfield(Data{iview},'Time')&& (Data{iview}.Time-Data{1}.Time)<0.0001
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

        %get Xphys,Yphys,Zphys from 1 or 2 stereo folders. Positions are taken
        %at the middle between to time step

        ZI=Zref*ones(size(XI,1),size(XI,2));



        %% get the Zshift field from stereo_piv (to check and update)

        if NbView==3 % if there is only 1 stereo folder, extract directly Xphys,Yphys and Zphys
            iview=3;
            [i1,i2,j1,j2] = get_file_index(index_i,index_j,PairString{iview});
            FullRootFile=fullfile(Param.InputTable{iview,1},Param.InputTable{iview,2},Param.InputTable{iview,3});
            NomType=Param.InputTable{iview,4};
            FullInputFile=fullfile_indices(FullRootFile,Param.InputTable{iview,5},NomType,i1,i2,j1,j2);
            [Data{3},~,errormsg] = nc2struct(FullInputFile);
            if ~isempty(errormsg)
                disp([FullInputFile ' read'])
            else
                disp(errormsg)
            end
           
            ind_good=find(~isnan(Data{3}.Zshift));
            Zshift=Data{3}.Zshift(ind_good);
            Yphys=Data{3}.Yphys(ind_good);
            Xphys=Data{3}.Xphys(ind_good);
            Xshift=Data{3}.Xshift(ind_good);
            Yshift=Data{3}.Yshift(ind_good);
            
            Xshift=griddata(Xphys,Yphys,Xshift,XI,YI);
            Yshift=griddata(Xphys,Yphys,Yshift,XI,YI);
            XIa=XI-0.5*Xshift;% uncorrected phys coordinates in view a corresponding to XI
            XIb=XI+0.5*Xshift;% uncorrected phys coordinates in view b corresponding to XI
            YIa=YI-0.5*Yshift; % uncorrected phys coordinates in view a corresponding to YI
            YIb=YI+0.5*Yshift;% uncorrected phys coordinates in view b corresponding to YI
            ZI=ZI+griddata(Xphys,Yphys,Zshift,XI,YI);% Z position at points XI, YI
            [Xa,Ya]=px_XYZ(XmlData{1}.GeometryCalib,[],XIa,YIa,ZI);% set of image coordinates on view a
            [Xb,Yb]=px_XYZ(XmlData{2}.GeometryCalib,[],XIb,YIb,ZI);% set of image coordinates on view b
        else
            [Xa,Ya]=px_XYZ(XmlData{1}.GeometryCalib,[],XI,YI,ZI);% set of image coordinates on view a
            [Xb,Yb]=px_XYZ(XmlData{2}.GeometryCalib,[],XI,YI,ZI);% set of image coordinates on view b
        end
        MergeData.Z=ZI;

        %remove wrong vector
        if isfield(Data{1},'FF') % FF is present, remove wrong vector
                ind_good=find(Data{1}.FF==0);
            else
                ind_good=1:numel(Data{1}.X);
        end
            X1=Data{1}.X(ind_good);
            Y1=Data{1}.Y(ind_good);
            U1=Data{1}.U(ind_good);
            V1=Data{1}.V(ind_good);
        
        Ua=griddata(X1,Y1,U1,Xa,Ya);% interpolate PIV data positions to the common grid Xa,Ya
        Va=griddata(X1,Y1,V1,Xa,Ya);
        [Ua,Va,Xa,Ya]=Ud2U(XmlData{1}.GeometryCalib,Xa,Ya,Ua,Va); % convert Xd data to X
        [A]=get_coeff(XmlData{1}.GeometryCalib,Xa,Ya,XI,YI,ZI); %get coef A~

        %remove wrong vector
        if isfield(Data{2},'FF') % FF is present, remove wrong vector
                ind_good=find(Data{2}.FF==0);
            else
                ind_good=1:numel(Data{2}.X);
        end
            X2=Data{2}.X(ind_good);
            Y2=Data{2}.Y(ind_good);
            U2=Data{2}.U(ind_good);
            V2=Data{2}.V(ind_good);
     
        Ub=griddata(X2,Y2,U2,Xb,Yb);
        Vb=griddata(X2,Y2,V2,Xb,Yb);
        [Ub,Vb,Xb,Yb]=Ud2U(XmlData{2}.GeometryCalib,Xb,Yb,Ub,Vb); % convert Xd data to X

        [B]=get_coeff(XmlData{2}.GeometryCalib,Xb,Yb,XI,YI,ZI); %get coef B~

        % System to solve
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
                dxyz=(squeeze(D(indj,indi,:,:))*1000)\(squeeze(S(indj,indi,:))*1000); % solving...
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


        %% recording the merged field
       
        MergeData.Time=Time;
        MergeData.Dt=Dt;
        MergeData.U=U/Dt;
        MergeData.V=V/Dt;
        MergeData.W=W/Dt;
        if ~isempty(scale_factor_inv_uv)
            MergeData.U=int16(scale_factor_inv_uv*MergeData.U);
            MergeData.V=int16(scale_factor_inv_uv*MergeData.V);
            MergeData.W=int16(scale_factor_inv_uv*MergeData.W);
            MergeData.VarAttribute{3}.scale_factor=1/scale_factor_inv_uv;
            MergeData.VarAttribute{4}.scale_factor=1/scale_factor_inv_uv;
            MergeData.VarAttribute{5}.scale_factor=1/scale_factor_inv_uv;
        end

        mfx=(XmlData{1}.GeometryCalib.fx_fy(1)+XmlData{2}.GeometryCalib.fx_fy(1))/2;
        mfy=(XmlData{1}.GeometryCalib.fx_fy(2)+XmlData{2}.GeometryCalib.fx_fy(2))/2;
        MergeData.Error=0.25*(mfx+mfy)*sqrt(sum(Error.^2,3));
        MergeData.U(MergeData.Error>1)=NaN;%suppress vectors which are not with reasonable error range estimated as 1 pixel
        MergeData.V(MergeData.Error>1)=NaN;
        MergeData.W(MergeData.Error>1)=NaN;
      MergeData.Error=reshape(MergeData.Error,Npy,Npx);
      MergeData.U=reshape(MergeData.U,Npy,Npx);
      MergeData.V=reshape(MergeData.V,Npy,Npx);
      MergeData.W=reshape(MergeData.W,Npy,Npx);
      MergeData.Z=reshape(MergeData.Z,Npy,Npx);
        MergeData.Error=uint16(1000*MergeData.Error);% transform to integers
        errormsg=struct2nc(OutputFile,MergeData);%save result file
        if isempty(errormsg)
            disp(['output file ' OutputFile ' written'])
        else
            disp(errormsg)
        end
    end
end

function [A]=get_coeff(Calib,X,Y,x,y,z) % compute A~ coefficients
R=(Calib.R)';%rotation matrix
T_z=Calib.Tx_Ty_Tz(3);
T=R(7)*x+R(8)*y+R(9)*z+T_z;

A(:,:,1,1)=(R(1)-R(7)*X)./T;
A(:,:,1,2)=(R(2)-R(8)*X)./T;
A(:,:,1,3)=(R(3)-R(9)*X)./T;
A(:,:,2,1)=(R(4)-R(7)*Y)./T;
A(:,:,2,2)=(R(5)-R(8)*Y)./T;
A(:,:,2,3)=(R(6)-R(9)*Y)./T;

function [U,V,X,Y]=Ud2U(Calib,Xd,Yd,Ud,Vd) % convert Xd to X  and Ud to U

X1d=Xd-Ud/2;
X2d=Xd+Ud/2;
Y1d=Yd-Vd/2;
Y2d=Yd+Vd/2;

X1=(X1d-Calib.Cx_Cy(1))./Calib.fx_fy(1).*(1 + Calib.kc.*Calib.fx_fy(1).^(-2).*(X1d-Calib.Cx_Cy(1)).^2 + Calib.kc.*Calib.fx_fy(2).^(-2).*(Y1d-Calib.Cx_Cy(2)).^2 ).^(-1);
X2=(X2d-Calib.Cx_Cy(1))./Calib.fx_fy(1).*(1 + Calib.kc.*Calib.fx_fy(1).^(-2).*(X2d-Calib.Cx_Cy(1)).^2 + Calib.kc.*Calib.fx_fy(2).^(-2).*(Y2d-Calib.Cx_Cy(2)).^2 ).^(-1);
Y1=(Y1d-Calib.Cx_Cy(2))./Calib.fx_fy(2).*(1 + Calib.kc.*Calib.fx_fy(1).^(-2).*(X1d-Calib.Cx_Cy(1)).^2 + Calib.kc.*Calib.fx_fy(2).^(-2).*(Y1d-Calib.Cx_Cy(2)).^2 ).^(-1);
Y2=(Y2d-Calib.Cx_Cy(2))./Calib.fx_fy(2).*(1 + Calib.kc.*Calib.fx_fy(1).^(-2).*(X2d-Calib.Cx_Cy(1)).^2 + Calib.kc.*Calib.fx_fy(2).^(-2).*(Y2d-Calib.Cx_Cy(2)).^2 ).^(-1);

U=X2-X1;
V=Y2-Y1;
X=X1+U/2;
Y=Y1+V/2;








