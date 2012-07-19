%'merge_proj': project and concatene fields
% can be used as a template for applying an operation (here projection and concatenation) on each field of an input series
%------------------------------------------------------------------------
% function ParamOut=merge_proj(Param)
%------------------------------------------------------------------------

%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function is used in four modes by the GUI series:
%           1) config GUI: with no input argument, the function determine the suitable GUI configuration
%           2) interactive input: the function is used to interactively introduce input parameters, and then stops
%           3) RUN: the function itself runs, when an appropriate input  structure Param has been introduced. 
%           4) BATCH: the function itself proceeds in BATCH mode, using an xml file 'Param' as input.
%
% This function is used in four modes by the GUI series:
%           1) config GUI: with no input argument, the function determine the suitable GUI configuration
%           2) interactive input: the function is used to interactively introduce input parameters, and then stops
%           3) RUN: the function itself runs, when an appropriate input  structure Param has been introduced. 
%           4) BATCH: the function itself proceeds in BATCH mode, using an xml file 'Param' as input.
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% In the absence of input (as activated when the current Action is selected
% in series), the function ouput GUI_input set the activation of the needed GUI elements
%
% Param contains the elements:(use the menu bar command 'export/GUI config' in series to see the current structure Param)
%    .InputTable: cell of input file names, (several lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDirExt: directory extension for data outputs
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%    .IndexRange: set the file or frame indices on which the action must be performed
%    .FieldTransform: .TransformName: name of the selected transform function
%                     .TransformPath:   path  of the selected transform function
%                     .TransformHandle: corresponding function handle
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%    .ProjObject: %sub structure describing a projection object (read from ancillary GUI set_object)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ParamOut=merge_proj(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if ~exist('Param','var') % case with no input parameter 
    ParamOut={'AllowInputSort';'off';...% allow alphabetic sorting of the list of input files (options 'off'/'on', 'off' by default)
        'WholeIndexRange';'off';...% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelType';'one';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
        'FieldName';'one';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'FieldTransform'; 'on';...%can use a transform function
        'ProjObject';'on';...%can use projection object(option 'off'/'on',
        'Mask';'off';...%can use mask option   (option 'off'/'on', 'off' by default)
        'OutputDirExt';'.mproj';...%set the output dir extension
               ''};
        return
end

%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
%% select different modes,  RUN, parameter input, BATCH
% BATCH  case: read the xml file for batch case
if ischar(Param)
        Param=xml2struct(Param);
        checkrun=0;
% RUN case: parameters introduced as the input structure Param
else
    hseries=guidata(Param.hseries);%handles of the GUI series
    if isfield(Param,'Specific')&& strcmp(Param.Specific,'?')
        checkrun=1;% will only search interactive input parameters (preparation of BATCH mode)
    else
        checkrun=2; % indicate the RUN option is used
    end
end
ParamOut=Param; %default output
OutputSubDir=[Param.OutputSubDir Param.OutputDirExt];

%% root input file(s) and type
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
%%%%%%%%%%%%
NbSlice=1;%default
if isfield(Param.IndexRange,'NbSlice')&&~isempty(Param.IndexRange.NbSlice)
    NbSlice=Param.IndexRange.NbSlice;
end
nbview=numel(i1_series);%number of input file series (lines in InputTable)
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields
nbfield_i=floor(nbfield/NbSlice);%total number of  indexes in a slice (adjusted to an integer number of slices) 
nbfield=nbfield_i*NbSlice; %total number of fields after adjustement

%determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video'};
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:nbview
    if ~exist(filecell{iview,1}','file')
        displ_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'],checkrun)
        return
    end
    [FileType{iview},FileInfo{iview},MovieObject{iview}]=get_file_type(filecell{iview,1});
    CheckImage{iview}=~isempty(find(strcmp(FileType{iview},ImageTypeOptions)));% =1 for images
    CheckNc{iview}=~isempty(find(strcmp(FileType{iview},NcTypeOptions)));% =1 for netcdf files
    if ~isempty(j1_series{iview})
        frame_index{iview}=j1_series{iview};
    else
        frame_index{iview}=i1_series{iview};
    end
end


%% calibration data and timing: read the ImaDoc files
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);
if size(time,1)>1
    diff_time=max(max(diff(time)));
    if diff_time>0 
        displ_uvmat('WARNING',['times of series differ by (max) ' num2str(diff_time)],checkrun)
    end   
end

%% coordinate transform or other user defined transform
transform_fct='';%default
if isfield(Param,'FieldTransform')&&~isempty(Param.FieldTransform.TransformName)
    addpath(Param.FieldTransform.TransformPath)
    transform_fct=str2func(Param.FieldTransform.TransformName);
    rmpath(Param.FieldTransform.TransformPath)
end

%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE

%% check the validity of  input file types
if CheckImage{1}
    FileExtOut='.png'; % write result as .png images for image inputs
elseif CheckNc{1}
    FileExtOut='.nc';% write result as .nc files for netcdf inputs
else
    displ_uvmat('ERROR',['invalid file type input ' FileType{1}],checkrun)
    return
end
for iview=1:nbview
	if ~isequal(CheckImage{iview},CheckImage{1})||~isequal(CheckNc{iview},CheckNc{1})
        displ_uvmat('ERROR','input set of input series: need  either netcdf either image series',checkrun)
    return
    end
end
NomTypeOut=NomType;% output file index will indicate the first and last ref index in the series
if checkrun==1
    ParamOut.Specific=[];%no specific parameter
    return %stop here for interactive input (option Param.Specific='?')
end

%% Set field names and velocity types
%use Param.InputFields for all views

%% MAIN LOOP ON SLICES
%%%%%%%%%%%%% STANDARD PART (DO NOT EDIT) %%%%%%%%%%%%
for i_slice=1:NbSlice
    index_slice=i_slice:NbSlice:nbfield;% select file indices of the slice
    nbfiles=0;
    nbmissing=0;

    %%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
    for index=index_slice
  
        if checkrun
            update_waitbar(hseries.Waitbar,index/(nbfield))
            stopstate=get(hseries.RUN,'BusyAction');
        else
            stopstate='queue';
        end
        
        %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
        Data=cell(1,nbview);%initiate the set Data
        nbtime=0;
        for iview=1:nbview
            % reading input file(s)
            filecell{iview,index}
            [Data{iview},tild,errormsg] = read_field(filecell{iview,index},FileType{iview},Param.InputFields,frame_index{iview}(index));
            if ~isempty(errormsg)
                errormsg=['merge_proj/read_field/' errormsg];
                display(errormsg)
                break
            end
            timeread(iview)=0;
            if isfield(Data{iview},'Time')
                    timeread(iview)=Data{iview}.Time;
                    nbtime=nbtime+1;
                end
            if ~isempty(NbSlice_calib)
                Data{iview}.ZIndex=mod(i1_series{iview}(index)-1,NbSlice_calib{iview})+1;%Zindex for phys transform
            end
            
            %transform the input field (e.g; phys) if requested
            if ~isempty(transform_fct)
                Data{iview}=transform_fct(Data{iview},XmlData{iview});  %transform to phys if requested
            end
            
            %% check whether tps is needed, then calculate tps coefficients if needed
            check_tps=0;
            if ischar(Param.InputFields.FieldName)
                Param.InputFields.FieldName={Param.InputFields.FieldName};
            end
            for ilist=1:numel(Param.InputFields.FieldName)
                switch Param.InputFields.FieldName{ilist}
                    case {'vort','div','strain'}
                        check_tps=1;
                end
            end
            if strcmp(Param.ProjObject.ProjMode,'filter')
                check_tps=1;
            end
            if check_tps
                SubDomain=1500; %default, estimated nbre of vectors in a subdomain used for tps
                if isfield(Data{iview},'SubDomain')
                    SubDomain=Data{iview}.SubDomain;%
                end
                [Data{iview}.SubRange,Data{iview}.NbSites,Data{iview}.Coord_tps,Data{iview}.U_tps,Data{iview}.V_tps,tild,U_smooth,V_smooth,W_smooth,FF] =...
                    filter_tps([Data{iview}.X(Data{iview}.FF==0) Data{iview}.Y(Data{iview}.FF==0)],Data{iview}.U(Data{iview}.FF==0),Data{iview}.V(Data{iview}.FF==0),[],SubDomain,0);
                nbvar=numel(Data{iview}.ListVarName);
                Data{iview}.ListVarName=[Data{iview}.ListVarName {'SubRange','NbSites','Coord_tps','U_tps','V_tps'}];
                Data{iview}.VarDimName=[Data{iview}.VarDimName {{'nb_coord','nb_bounds','nb_subdomain'},{'nb_subdomain'},...
                    {'nb_tps','nb_coord','nb_subdomain'},{'nb_tps','nb_subdomain'},{'nb_tps','nb_subdomain'}}];
                Data{iview}.VarAttribute{nbvar+3}.Role='coord_tps';
                Data{iview}.VarAttribute{nbvar+4}.Role='vector_x';
                Data{iview}.VarAttribute{nbvar+5}.Role='vector_y';
                if isfield(Data{iview},'ListDimName')%cleaning
                    Data{iview}=rmfield(Data{iview},'ListDimName');
                end
                if isfield(Data{iview},'DimValue')%cleaning
                    Data{iview}=rmfield(Data{iview},'DimValue');
                end
            end
                 
            % field calculation (vort, div...)    
            if strcmp(FileType{iview},'civx')||strcmp(FileType{iview},'civdata')
                if isfield(Data{iview},'Coord_tps')
                    Data{iview}.FieldList=Param.InputFields.FieldName;
                else
                    Data{iview}=calc_field(Param.InputFields.FieldName,Data{iview});%calculate field (vort..)
                end
            end
            
            %projection on object (gridded plane)
            if Param.CheckObject
                [Data{iview},errormsg]=proj_field(Data{iview},Param.ProjObject);
                if ~isempty(errormsg)
                    displ_uvmat('ERROR',['error in merge_proge/proj_field: ' errormsg],checkrun)
                    return
                end
            end
        end
        %----------END LOOP ON VIEWS----------------------
        
        %% merge the nbview fields
        MergeData=merge_field(Data);
        if isfield(MergeData,'Txt')
            displ_uvmat('ERROR',MergeData.Txt,checkrun)
            return
        end
        
        % time of the merged field:
        if ~isempty(time)% time defined from ImaDoc
            timeread=time(:,index);
        end
        timeread=mean(timeread);
        
        % generating the name of the merged field
        i1=i1_series{iview}(index);
        if ~isempty(i2_series{iview})
            i2=i2_series{iview}(index);
        else
            i2=i1;
        end
        j1=1;
        j2=1;
        if ~isempty(j1_series{iview})
            j1=j1_series{iview}(index);
            if ~isempty(j2_series{iview})
                j2=j2_series{iview}(index);
            else
                j2=j1;
            end
        end
        OutputFile=fullfile_uvmat(RootPath{1},OutputSubDir,RootFile{1},FileExtOut,NomType{1},i1,i2,j1,j2);
        
        % recording the merged field
        if CheckImage{1}    %in case of input images an image is produced
            if isa(MergeData.A,'uint8')
                bitdepth=8;
            elseif isa(MergeData.A,'uint16')
                bitdepth=16;
            end
            imwrite(MergeData.A,OutputFile,'BitDepth',bitdepth);
            %write xml calibration file
            siz=size(MergeData.A);
            npy=siz(1);
            npx=siz(2);
            if isfield(MergeData,'VarAttribute')&&isfield(MergeData.VarAttribute{1},'Coord_2')&&isfield(MergeData.VarAttribute{1},'Coord_1')
                Rangx=MergeData.VarAttribute{1}.Coord_2;
                Rangy=MergeData.VarAttribute{1}.Coord_1;
            elseif isfield(MergeData,'AX')&& isfield(MergeData,'AY')
                Rangx=[MergeData.AX(1) MergeData.AX(end)];
                Rangy=[MergeData.AY(1) MergeData.AY(end)];
            else
                Rangx=[0.5 npx-0.5];
                Rangy=[npy-0.5 0.5];%default
            end
            pxcmx=(npx-1)/(Rangx(2)-Rangx(1));
            pxcmy=(npy-1)/(Rangy(1)-Rangy(2));
            T_x=-pxcmx*Rangx(1)+0.5;
            T_y=-pxcmy*Rangy(2)+0.5;
            GeometryCal.focal=1;
            GeometryCal.R=[pxcmx,0,0;0,pxcmy,0;0,0,1];
            GeometryCal.Tx_Ty_Tz=[T_x T_y 1];
            ImaDoc.GeometryCalib=GeometryCal;
            t=struct2xml(ImaDoc);
            t=set(t,1,'name','ImaDoc');
            save(t,[filebase_merge '.xml'])
            display([filebase_merge '.xml saved'])
        else
            MergeData.ListGlobalAttribute={'Conventions','Project','InputFile_1','InputFile_end','nb_coord','nb_dim','dt','Time','civ'};
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
            if isempty(dt)
                MergeData.ListGlobalAttribute(6)=[];
            else
                MergeData.dt=dt;
            end
            MergeData.Time=timeread;
            error=struct2nc(OutputFile,MergeData);%save result file
            if isempty(error)
                display(['output file ' OutputFile ' written'])
            else
                display(error)
            end
        end
    end
end

%'merge_field': concatene fields
%------------------------------------------------------------------------
function MergeData=merge_field(Data)
%% default output
if isempty(Data)||~iscell(Data)
    MergeData=[];
    return
end
MergeData=Data{1};%default
error=0;
nbview=length(Data);
if nbview==1
    return
end

%% group the variables (fields of 'FieldData') in cells of variables with the same dimensions
[CellVarIndex,NbDim,VarTypeCell]=find_field_indices(Data{1});
%LOOP ON GROUPS OF VARIABLES SHARING THE SAME DIMENSIONS
% CellVarIndex=cells of variable index arrays
ivar_new=0; % index of the current variable in the projected field
for icell=1:length(CellVarIndex)
    if NbDim(icell)==1
        continue
    end
    VarIndex=CellVarIndex{icell};%  indices of the selected variables in the list FieldData.ListVarName
    VarType=VarTypeCell{icell};
    ivar_X=VarType.coord_x;
    ivar_Y=VarType.coord_y;
    ivar_FF=VarType.errorflag;
    if isempty(ivar_X)
        test_grid=1;%test for input data on regular grid (e.g. image)coordinates
    else
        if length(ivar_Y)~=1
                displ_uvmat('ERROR','y coordinate missing in proj_field.m',checkrun)
                return
        end
        test_grid=0;
    end
    %case of input fields with unstructured coordinates
    if ~test_grid
        for ivar=VarIndex
            VarName=MergeData.ListVarName{ivar};
            for iview=1:nbview
                eval(['MergeData.' VarName '=[MergeData.' VarName '; Data{iview}.' VarName '];'])
            end
        end
    %case of fields defined on a structured  grid 
    else  
        testFF=0;
        for iview=2:nbview
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                if isfield(MergeData,'VarAttribute')
                    if length(MergeData.VarAttribute)>=ivar && isfield(MergeData.VarAttribute{ivar},'Role') && isequal(MergeData.VarAttribute{ivar}.Role,'errorflag')
                        testFF=1;
                    end
                end
                eval(['MergeData.' VarName '=MergeData.' VarName '+ Data{iview}.' VarName ';'])
            end
        end
        if testFF
            nbaver=nbview-MergeData.FF;
            indgood=find(nbaver>0);
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                eval(['MergeData.' VarName '(indgood)=double(MergeData.' VarName '(indgood))./nbaver(indgood);'])
            end 
        else
            for ivar=VarIndex
                VarName=MergeData.ListVarName{ivar};
                eval(['MergeData.' VarName '=double(MergeData.' VarName ')./nbview;'])
            end    
        end
    end
end

    