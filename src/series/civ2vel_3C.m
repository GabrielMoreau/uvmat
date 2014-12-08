%'civ2vel_3C': combine velocity fields from two camerasto get three velocity components
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
    ParamOut.AllowInputSort='on';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='one';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%use the phys  transform function without choice
    %ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.vel3C';%set the output dir extension
    ParamOut.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
      %check the input files
    first_j=[];
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
     msgbox_uvmat('ERROR','no geometric calibration available for image A')
     return
 end
 if isfield(XmlData{2},'GeometryCalib')
     tsaiB=XmlData{2}.GeometryCalib;
 else
     msgbox_uvmat('ERROR','no geometric calibration available for image B')
     return
 end
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);

 %% MAIN LOOP ON FIELDS
for index=1:NbField
        update_waitbar(WaitbarHandle,index/NbField)
    if ~isempty(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
        disp('program stopped by user')
        return
    end
    
    %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
    Data=cell(1,NbView);%initiate the set Data
    timeread=zeros(1,NbView);
    for iview=1:NbView
        %% reading input file(s)
        [Data{iview},tild,errormsg] = read_field(filecell{iview,index},FileType{iview},Param.InputFields,frame_index{iview}(index));
        if ~isempty(errormsg)
            disp_uvmat('ERROR',['ERROR in civ2vel_3C/read_field/' errormsg],checkrun)
            return
        end
        % get the time defined in the current file if not already defined from the xml file
        if ~isempty(time) && isfield(Data{iview},'Time')
            timeread(iview)=Data{iview}.Time;
        end
        if ~isempty(NbSlice_calib)
            Data{iview}.ZIndex=mod(i1_series{iview}(index)-1,NbSlice_calib{iview})+1;%Zindex for phys transform
        end
        
        %% transform the input field (e.g; phys) if requested (no transform involving two input fields)
        Data{iview}=phys(Data{iview},XmlData{iview});
        
        %% projection on object (gridded plane)
%         if Param.CheckObject
            [Data{iview},errormsg]=proj_field(Data{iview},Param.ProjObject);
            if ~isempty(errormsg)
                disp_uvmat('ERROR',['ERROR in merge_proge/proj_field: ' errormsg],checkrun)
                return
            end

    end
    %%%%%%%%%%%%%%%% END LOOP ON VIEWS %%%%%%%%%%%%%%%%

    %% merge the NbView fields
    [MergeData,errormsg]=merge_field(Data);
    if ~isempty(errormsg)
        disp_uvmat('ERROR',errormsg,checkrun);
        return
    end

    %% time of the merged field: take the average of the different views
    if ~isempty(time)
        timeread=time(index);   
    elseif ~isempty(find(timeread))% time defined from ImaDoc
        timeread=mean(timeread(timeread~=0));% take average over times form the files (when defined)
    else
        timeread=index;% take time=file index 
    end

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
    OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFileOut,FileExtOut,NomType{1},i1,i2,j1,j2);

    %% recording the merged field
    
        MergeData.ListGlobalAttribute={'Conventions','Project','InputFile_1','InputFile_end','nb_coord','nb_dim'};
        MergeData.Conventions='uvmat';
        MergeData.nb_coord=2;
        MergeData.nb_dim=2;
        dt=[];
        if isfield(Data{1},'dt')&& isnumeric(Data{1}.dt)
            dt=Data{1}.dt;
        end
        for iview =2:numel(Data)
            if ~(isfield(Data{iview},'dt')&& isequal(Data{iview}.dt,dt))
                dt=[];%dt not the same for all fields
            end
        end
        if ~isempty(timeread)
            MergeData.ListGlobalAttribute=[MergeData.ListGlobalAttribute {'Time'}];
            MergeData.Time=timeread;
        end
        if ~isempty(dt)
            MergeData.ListGlobalAttribute=[MergeData.ListGlobalAttribute {'dt'}];
            MergeData.dt=dt;
        end
        error=struct2nc(OutputFile,MergeData);%save result file
        if isempty(error)
            disp(['output file ' OutputFile ' written'])
        else
            disp(error)
        end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %read the velocity fields
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%read field A
[Field,VelTypeOut]=read_civxdata(file_A,[],vel_type);
%removes false vectors
if isfield(Field,'FF')
    Field.X=Field.X(find(Field.FF==0));
    Field.Y=Field.Y(find(Field.FF==0));
    Field.U=Field.U(find(Field.FF==0));
    Field.V=Field.V(find(Field.FF==0));
end
%interpolate on the grid common to both images in phys coordinates
dXa= griddata_uvmat(Field.X,Field.Y,Field.U,XimaA,YimaA);
dYa= griddata_uvmat(Field.X,Field.Y,Field.V,XimaA,YimaA);
dt=Field.dt;
time=Field.Time;

%read field B
[Field,VelTypeOut]=read_civxdata(file_B,[],vel_type);
if ~isequal(Field.dt,dt)
    msgbox_uvmat('ERROR','different time intervals for the two velocity fields ')
     return
end
if ~isequal(Field.Time,time)
    msgbox_uvmat('ERROR','different times for the two velocity fields ')
     return
end
%removes false vectors
if isfield(Field,'FF')
Field.X=Field.X(find(Field.FF==0));
Field.Y=Field.Y(find(Field.FF==0));
Field.U=Field.U(find(Field.FF==0));
Field.V=Field.V(find(Field.FF==0));
end
%interpolate on XimaB
dXb=griddata_uvmat(Field.X,Field.Y,Field.U,XimaB,YimaB);
dYb=griddata_uvmat(Field.X,Field.Y,Field.V,XimaB,YimaB);
%eliminate Not-a-Number 
ind_Nan=find(and(~isnan(dXa),~isnan(dXb)));
dXa=dXa(ind_Nan);
dYa=dYa(ind_Nan);
dXb=dXb(ind_Nan);
dYb=dYb(ind_Nan); 
grid_phys1(:,1)=grid_real_x(ind_Nan);
grid_phys1(:,2)=grid_real_y(ind_Nan);
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%compute the differential coefficients of the geometric calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[A11,A12,A13,A21,A22,A23]=pxcm_tsai(tsaiA,grid_phys1);
[B11,B12,B13,B21,B22,B23]=pxcm_tsai(tsaiB,grid_phys1);

C1=A11.*A22-A12.*A21;
C2=A13.*A22-A12.*A23;
C3=A13.*A21-A11.*A23;
D1=B11.*B22-B12.*B21;
D2=B13.*B22-B12.*B23;
D3=B13.*B21-B11.*B23;
A1=(A22.*D1.*(C1.*D3-C3.*D1)+A21.*D1.*(C2.*D1-C1.*D2));
A2=(A12.*D1.*(C3.*D1-C1.*D3)+A11.*D1.*(C1.*D2-C2.*D1));
B1=(B22.*C1.*(C3.*D1-C1.*D3)+B21.*C1.*(C1.*D2-C2.*D1));
B2=(B12.*C1.*(C1.*D3-C3.*D1)+B11.*C1.*(C2.*D1-C1.*D2));
Lambda=(A1.*dXa+A2.*dYa+B1.*dXb+B2.*dYb)./(A1.*A1+A2.*A2+B1.*B1+B2.*B2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Projection for compatible displacements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ua=dXa-Lambda.*A1;
Va=dYa-Lambda.*A2;
Ub=dXb-Lambda.*B1;
Vb=dYb-Lambda.*B2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculations of displacements and error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
U=(A22.*D2.*Ua-A12.*D2.*Va-B22.*C2.*Ub+B12.*C2.*Vb)./(C1.*D2-C2.*D1);
V=(A21.*D3.*Ua-A11.*D3.*Va-B21.*C3.*Ub+B11.*C3.*Vb)./(C3.*D1-C1.*D3);
W=(A22.*D1.*Ua-A12.*D1.*Va-B22.*C1.*Ub+B12.*C1.*Vb)./(C2.*D1-C1.*D2);
W1=(-A21.*D1.*Ua+A11.*D1.*Va+B21.*C1.*Ub-B11.*C1.*Vb)./(C1.*D3-C3.*D1);

error=sqrt((A1.*dXa+A2.*dYa+B1.*dXb+B2.*dYb).*(A1.*dXa+A2.*dYa+B1.*dXb+B2.*dYb)./(A1.*A1+A2.*A2+B1.*B1+B2.*B2));

ind_error=(find(error<thresh_patch));
U=U(ind_error);
V=V(ind_error);
W=W(ind_error);%correction for water interface
error=error(ind_error);

%create nc grid file
Result.ListGlobalAttribute={'nb_coord','nb_dim','constant_pixcm','absolut_time_T0','hart','dt','civ'};
Result.nb_coord=3;%grid file, no velocity
Result.nb_dim=2;
Result.constant_pixcm=0;%no linear correspondance with images
Result.absolut_time_T0=time;%absolute time of the field
Result.hart=0;
Result.dt=dt;%time interval for image correlation (put  by default)
% cte.title='grid';
Result.civ=0;%not a civ file (no direct correspondance with an image)
% Result.ListDimName={'nb_vectors'}
% Result.DimValue=length(U);
Result.ListVarName={'vec_X','vec_Y','vec_U','vec_V','vec_W','vec_E'};
Result.VarDimName={'nb_vectors','nb_vectors','nb_vectors','nb_vectors','nb_vectors','nb_vectors'}
Result.vec_X= grid_phys1(ind_error,1);
Result.vec_Y= grid_phys1(ind_error,2);
Result.vec_U=U/dt;
Result.vec_V=V/dt;
Result.vec_W=W/dt;
Result.vec_E=error; 
% error=write_netcdf(file_st,cte,fieldlabels,grid_phys);
error=struct2nc(file_st,Result);
display([file_st ' written'])



%'pxcm_tsai': find differentials of the Tsai calibration
function [A11,A12,A13,A21,A22,A23]=pxcm_tsai(a,var_phys)
R=(a.R)';

x=var_phys(:,1);
y=var_phys(:,2);

if isfield(a,'PlanePos')
    prompt={'Plane 1 Index','Plane 2 Index'};
    Rep=inputdlg(prompt,'Target displacement test');
    Z1=str2double(Rep(1));
    Z2=str2double(Rep(2));
    z=(a.PlanePos(Z2,3)+a.PlanePos(Z1,3))/2
else
    z=0;
end

%transform coeff for differentiels
a.C11=R(1)*R(8)-R(2)*R(7);
a.C12=R(2)*R(7)-R(1)*R(8);
a.C21=R(4)*R(8)-R(5)*R(7);
a.C22=R(5)*R(7)-R(4)*R(8);
a.C1x=R(3)*R(7)-R(9)*R(1);
a.C1y=R(3)*R(8)-R(9)*R(2);
a.C2x=R(6)*R(7)-R(9)*R(4);
a.C2y=R(6)*R(8)-R(9)*R(5);

% %dependence in x,y
% denom=(R(7)*x+R(8)*y+R(9)*z+a.Tz).*(R(7)*x+R(8)*y+R(9)*z+a.Tz);
% A11=(a.f*a.sx*(a.C11*y-a.C1x*z+R(1)*a.Tz-R(7)*a.Tx)./denom)/a.dpx;
% A12=(a.f*a.sx*(a.C12*x-a.C1y*z+R(2)*a.Tz-R(8)*a.Tx)./denom)/a.dpx;
% A21=(a.f*a.sx*(a.C21*y-a.C2x*z+R(4)*a.Tz-R(7)*a.Ty)./denom)/a.dpy;
% A22=(a.f*(a.C22*x-a.C2y*z+R(5)*a.Tz-R(8)*a.Ty)./denom)/a.dpy;
% A13=(a.f*(a.C1x*x+a.C1y*y+R(3)*a.Tz-R(9)*a.Tx)./denom)/a.dpx;
% A23=(a.f*(a.C2x*x+a.C2y*y+R(6)*a.Tz-R(9)*a.Ty)./denom)/a.dpy;

%dependence in x,y
denom=(R(7)*x+R(8)*y+R(9)*z+a.Tx_Ty_Tz(3)).*(R(7)*x+R(8)*y+R(9)*z+a.Tx_Ty_Tz(3));
A11=(a.fx_fy(1)*(a.C11*y-a.C1x*z+R(1)*a.Tx_Ty_Tz(3)-R(7)*a.Tx_Ty_Tz(1))./denom);
A12=(a.fx_fy(1)*(a.C12*x-a.C1y*z+R(2)*a.Tx_Ty_Tz(3)-R(8)*a.Tx_Ty_Tz(1))./denom);
A21=(a.fx_fy(1)*(a.C21*y-a.C2x*z+R(4)*a.Tx_Ty_Tz(3)-R(7)*a.Tx_Ty_Tz(2))./denom);
A22=(a.fx_fy(2)*(a.C22*x-a.C2y*z+R(5)*a.Tx_Ty_Tz(3)-R(8)*a.Tx_Ty_Tz(2))./denom);
A13=(a.fx_fy(2)*(a.C1x*x+a.C1y*y+R(3)*a.Tx_Ty_Tz(3)-R(9)*a.Tx_Ty_Tz(1))./denom);
A23=(a.fx_fy(2)*(a.C2x*x+a.C2y*y+R(6)*a.Tx_Ty_Tz(3)-R(9)*a.Tx_Ty_Tz(2))./denom);








