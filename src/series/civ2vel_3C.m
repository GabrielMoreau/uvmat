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

function ParamOut=civ2vel_3C(Param)
disp('test')
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
    ParamOut.CheckOverwriteVisible='on'; % manage the overwrite of existing files (default=1)
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

CheckOverwrite=1;%default
if isfield(Param,'CheckOverwrite')
    CheckOverwrite=Param.CheckOverwrite;
end
for index=1:NbField
    
    update_waitbar(WaitbarHandle,index/NbField)
    
    
    
    
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
    
    %%
    
   
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    
     if (~CheckOverwrite && exist(OutputFile,'file'))  
            disp('existing output file already exists, skip to next field')
            continue% skip iteration if the mode overwrite is desactivated and the result file already exists
     end   
     
    %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
    Data=cell(1,NbView);%initiate the set Data
    timeread=zeros(1,NbView);
    
    %get Xphys,Yphys,Zphys from 1 or 2 stereo folders. Positions are taken
    %at the middle between to time step
   clear ZItemp
   ZItemp=zeros(size(XI,1),size(XI,2),2);
   
   if index==1
        first_img=i1_series{1,1}(1,1); %id of the first image of the series
   end
     
     idtemp=0;
 for indextemp=index:index+1; 
     idtemp=idtemp+1;
    if NbView==3 % if there is only 1 stereo folder, extract directly Xphys,Yphys and Zphys
      
        
        
        [Data{3},tild,errormsg] = nc2struct([Param.InputTable{3,1},'/',Param.InputTable{3,2},'/',Param.InputTable{3,3},'_',int2str(first_img+indextemp-1),'.nc']); 
       
        if  exist('Data{3}.Civ3_FF','var') % FF is present, remove wrong vector
            temp=find(Data{3}.Civ3_FF==0);
            Zphys=Data{3}.Zphys(temp);
            Yphys=Data{3}.Yphys(temp);
            Xphys=Data{3}.Xphys(temp);
        else 
            Zphys=Data{3}.Zphys;
            Yphys=Data{3}.Yphys;
            Xphys=Data{3}.Xphys;
        end
        
        
        
    elseif NbView==4 % is there is 2 stereo folders, get global U and V and compute Zphys
        
        
        %test if the seconde camera is the same for both folder
        for i=3:4
        indpt(i)=strfind(Param.InputTable{i,2},'.'); % indice of the "." is the folder name 1
        indline(i)=strfind(Param.InputTable{i,2},'-'); % indice of the "-" is the folder name1
        camname{i}=Param.InputTable{i,2}(indline(i)+1:indpt(i)-1);% extract the second camera name 
        end
        
        if strcmp(camname{3},camname{4})==0 
            disp_uvmat('ERROR','The 2 stereo folders should have the same camera for the second position',checkrun)
            return
        end
        
   
        
        [Data{3},tild,errormsg] = nc2struct([Param.InputTable{3,1},'/',Param.InputTable{3,2},'/',Param.InputTable{3,3},'_',int2str(first_img+indextemp-1),'.nc']); 
    
        if exist('Data{3}.Civ3_FF','var') % if FF is present, remove wrong vector
            temp=find(Data{3}.Civ3_FF==0);
            Xmid3=Data{3}.Xmid(temp);
            Ymid3=Data{3}.Ymid(temp);
            U3=Data{3}.Uphys(temp);
            V3=Data{3}.Vphys(temp);
        else 
            Xmid3=Data{3}.Xmid;
            Ymid3=Data{3}.Ymid;
            U3=Data{3}.Uphys;
            V3=Data{3}.Vphys;
        end
        %temporary gridd of merging the 2 stereos datas
        [xq,yq] = meshgrid(min(Xmid3+(U3)/2):(max(Xmid3+(U3)/2)-min(Xmid3+(U3)/2))/128:max(Xmid3+(U3)/2),min(Ymid3+(V3)/2):(max(Ymid3+(V3)/2)-min(Ymid3+(V3)/2))/128:max(Ymid3+(V3)/2));
        
        %1st folder : interpolate the first camera (Dalsa1) points on the second (common) camera
        %(Dalsa 3)
        x3Q=griddata(Xmid3+(U3)/2,Ymid3+(V3)/2,Xmid3-(U3)/2,xq,yq);
        y3Q=griddata(Xmid3+(U3)/2,Ymid3+(V3)/2,Ymid3-(V3)/2,xq,yq);
        
        

         [Data{4},tild,errormsg] = nc2struct([Param.InputTable{4,1},'/',Param.InputTable{4,2},'/',Param.InputTable{4,3},'_',int2str(first_img+indextemp-1),'.nc']); 
        if exist('Data{4}.Civ3_FF','var') % if FF is present, remove wrong vector
            temp=find(Data{4}.Civ3_FF==0);
            Xmid4=Data{4}.Xmid(temp);
            Ymid4=Data{4}.Ymid(temp);
            U4=Data{4}.Uphys(temp);
            V4=Data{4}.Vphys(temp);
        else 
            Xmid4=Data{4}.Xmid;
            Ymid4=Data{4}.Ymid;
            U4=Data{4}.Uphys;
            V4=Data{4}.Vphys;
        end
        
        %2nd folder :interpolate the first camera (Dalsa2) points on the second (common) camera
        %(Dalsa 3)
        x4Q=griddata(Xmid4+(U4)/2,Ymid4+(V4)/2,Xmid4-(U4)/2,xq,yq);
        y4Q=griddata(Xmid4+(U4)/2,Ymid4+(V4)/2,Ymid4-(V4)/2,xq,yq);
        
        xmid=reshape((x4Q+x3Q)/2,length(xq(:,1)).*length(xq(1,:)),1);
        ymid=reshape((y4Q+y3Q)/2,length(yq(:,1)).*length(yq(1,:)),1);
        u=reshape(x4Q-x3Q,length(xq(:,1)).*length(xq(1,:)),1);
        v=reshape(y4Q-y3Q,length(yq(:,1)).*length(yq(1,:)),1);
        
        
        [Zphys,Xphys,Yphys,error]=shift2z(xmid, ymid, u, v,XmlData); %get Xphy,Yphy and Zphys
        %remove NaN 
        tempNaN=isnan(Zphys);tempind=find(tempNaN==1);
        Zphys(tempind)=[];
        Xphys(tempind)=[];
        Yphys(tempind)=[];
        error(tempind)=[];
         
    end
    
            if NbView>2   
       ZItemp(:,:,idtemp)=griddata(Xphys,Yphys,Zphys,XI,YI); %interpolation on the choosen gridd
            end
    
end
    ZI=mean(ZItemp,3); %mean between two the two time step
    Vtest=ZItemp(:,:,2)-ZItemp(:,:,1);
    
    [Xa,Ya]=px_XYZ(XmlData{1}.GeometryCalib,XI,YI,ZI);% set of image coordinates on view a
    [Xb,Yb]=px_XYZ(XmlData{2}.GeometryCalib,XI,YI,ZI);% set of image coordinates on view b
    
   
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
    %remove wrong vector  
    if isfield(Data{1},'FF')
        temp=find(Data{1}.FF==0);
        X1=Data{1}.X(temp);
        Y1=Data{1}.Y(temp);
        U1=Data{1}.U(temp);
        V1=Data{1}.V(temp);
    else
        X1=Data{1}.X;
        Y1=Data{1}.Y;
        U1=Data{1}.U;
        V1=Data{1}.V;
    end
    Ua=griddata(X1,Y1,U1,Xa,Ya);
    Va=griddata(X1,Y1,V1,Xa,Ya);
    [Ua,Va,Xa,Ya]=Ud2U(XmlData{1}.GeometryCalib,Xa,Ya,Ua,Va); % convert Xd data to X
    [A]=get_coeff(XmlData{1}.GeometryCalib,Xa,Ya,XI,YI,ZI); %get coef A~
    
    %remove wrong vector  
    if isfield(Data{1},'FF')
        temp=find(Data{2}.FF==0);
        X2=Data{2}.X(temp);
        Y2=Data{2}.Y(temp);
        U2=Data{2}.U(temp);
        V2=Data{2}.V(temp);
    else
        X2=Data{2}.X;
        Y2=Data{2}.Y;
        U2=Data{2}.U;
        V2=Data{2}.V;
    end
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
    end
    MergeData.U=U/Dt;
    MergeData.V=V/Dt;
    MergeData.W=W/Dt;
    MergeData.Z=ZI;
    
%     mfx=(XmlData{1}.GeometryCalib.fx_fy(1)+XmlData{2}.GeometryCalib.fx_fy(1))/2;
%     mfy=(XmlData{1}.GeometryCalib.fx_fy(2)+XmlData{2}.GeometryCalib.fx_fy(2))/2;
    MergeData.Error=0.5*sqrt(sum(Error.^2,3));
    errormsg=struct2nc(OutputFile,MergeData);%save result file
    if isempty(errormsg)
        disp(['output file ' OutputFile ' written'])
    else
        disp(errormsg)
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



function [z,Xphy,Yphy,error]=shift2z(xmid, ymid, u, v,XmlData) % get H from stereo data
z=0;
error=0;


%% first image
Calib_A=XmlData{1}.GeometryCalib;
R=(Calib_A.R)';
x_a=xmid- u/2;
y_a=ymid- v/2; 
z_a=R(7)*x_a+R(8)*y_a+Calib_A.Tx_Ty_Tz(1,3);
Xa=(R(1)*x_a+R(2)*y_a+Calib_A.Tx_Ty_Tz(1,1))./z_a;
Ya=(R(4)*x_a+R(5)*y_a+Calib_A.Tx_Ty_Tz(1,2))./z_a;

A_1_1=R(1)-R(7)*Xa;
A_1_2=R(2)-R(8)*Xa;
A_1_3=R(3)-R(9)*Xa;
A_2_1=R(4)-R(7)*Ya;
A_2_2=R(5)-R(8)*Ya;
A_2_3=R(6)-R(9)*Ya;
Det=A_1_1.*A_2_2-A_1_2.*A_2_1;
Dxa=(A_1_2.*A_2_3-A_2_2.*A_1_3)./Det;
Dya=(A_2_1.*A_1_3-A_1_1.*A_2_3)./Det;

%% second image
%loading shift angle

Calib_B=XmlData{2}.GeometryCalib;
R=(Calib_B.R)';


x_b=xmid+ u/2;
y_b=ymid+ v/2;
z_b=R(7)*x_b+R(8)*y_b+Calib_B.Tx_Ty_Tz(1,3);
Xb=(R(1)*x_b+R(2)*y_b+Calib_B.Tx_Ty_Tz(1,1))./z_b;
Yb=(R(4)*x_b+R(5)*y_b+Calib_B.Tx_Ty_Tz(1,2))./z_b;
B_1_1=R(1)-R(7)*Xb;
B_1_2=R(2)-R(8)*Xb;
B_1_3=R(3)-R(9)*Xb;
B_2_1=R(4)-R(7)*Yb;
B_2_2=R(5)-R(8)*Yb;
B_2_3=R(6)-R(9)*Yb;
Det=B_1_1.*B_2_2-B_1_2.*B_2_1;
Dxb=(B_1_2.*B_2_3-B_2_2.*B_1_3)./Det;
Dyb=(B_2_1.*B_1_3-B_1_1.*B_2_3)./Det;

%% result
Den=(Dxb-Dxa).*(Dxb-Dxa)+(Dyb-Dya).*(Dyb-Dya);
error=abs(((Dyb-Dya).*(-u)-(Dxb-Dxa).*(-v)))./Den;
% ex=-error.*(Dyb-Dya);
% ey=-error.*(Dxb-Dxa);

% z1=-u./(Dxb-Dxa);
% z2=-v./(Dyb-Dya);
z=((Dxb-Dxa).*(-u)+(Dyb-Dya).*(-v))./Den;

xnew(1,:)=Dxa.*z+x_a;
xnew(2,:)=Dxb.*z+x_b;
ynew(1,:)=Dya.*z+y_a;
ynew(2,:)=Dyb.*z+y_b;
Xphy=mean(xnew,1);
Yphy=mean(ynew,1); 




