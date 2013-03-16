% 'check_peaklocking': estimte peaklocking error in a civ field series TODO: UPDATE
%------------------------------------------------------------------------
% function ParamOut=check_peaklocking(Param)
%
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
function  ParamOut=check_peaklocking(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if ~exist('Param','var') % case with no input parameter 
    ParamOut={'AllowInputSort';'off';...% allow alphabetic sorting of the list of input files (options 'off'/'on', 'off' by default)
        'WholeIndexRange';'off';...% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelType';'two';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
        'FieldName';'off';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'FieldTransform'; 'off';...%can use a transform function
        'ProjObject';'on';...%can use projection object(option 'off'/'on',
        'Mask';'off';...%can use mask option   (option 'off'/'on', 'off' by default)
        'OutputDirExt';'.pklock';...%set the output dir extension
               ''};
        return
end

%%%%%%%%%%%% STANDARD PART  %%%%%%%%%%%%
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
OutputDir=[Param.OutputSubDir Param.OutputDirExt];

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
nbview=1;%number of input file series (lines in InputTable)
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
%none

%% coordinate transform or other user defined transform
% none

%%%%%%%%%%%% END STANDARD PART  %%%%%%%%%%%%
 % EDIT FROM HERE

%% check the validity of  ctinput file types
%none

%% Set field names and velocity types
InputFields{1}=[];%default (case of images)
if isfield(Param,'InputFields')
    InputFields{1}=Param.InputFields;
end
% only one input fieldseries

%% Initiate output fields
%initiate the output structure as a copy of the first input one (reproduce fields)
[DataOut,tild,errormsg] = read_field(filecell{1,1},FileType{1},InputFields{1},1);
if ~isempty(errormsg)
    displ_uvmat('ERROR',['error reading ' filecell{1,1} ': ' errormsg],checkrun)
    return
end
time_1=[];
if isfield(DataOut,'Time')
    time_1=DataOut.Time(1);
end
if CheckNc{iview}
    if isempty(strcmp('Conventions',DataOut.ListGlobalAttribute))
        DataOut.ListGlobalAttribute=['Conventions' DataOut.ListGlobalAttribute];
    end
    DataOut.Conventions='uvmat';
    DataOut.ListGlobalAttribute=[DataOut.ListGlobalAttribute {Param.Action}];
    ActionKey='Action';
    while isfield(DataOut,ActionKey)
        ActionKey=[ActionKey '_1'];
    end
    DataOut.(ActionKey)=Param.Action;
    DataOut.ListGlobalAttribute=[DataOut.ListGlobalAttribute {ActionKey}];
    if isfield(DataOut,'Time')
        DataOut.ListGlobalAttribute=[DataOut.ListGlobalAttribute {'Time','Time_end'}];
    end
end

%%%%%%%%%%%%%%%% loop on field indices %%%%%%%%%%%%%%%%
index_slice=1:nbfield;% select the file indices
for index=index_slice
    if checkrun
        update_waitbar(hseries.Waitbar,index/(nbfield))
        stopstate=get(hseries.RUN,'BusyAction');
    else
        stopstate='queue';
    end
    if isequal(stopstate,'queue')% enable STOP command
        Data=cell(1,nbview);%initiate the set Data;
        nbtime=0;
        dt=[];
        %%%%%%%%%%%%%%%% loop on views (input lines) %%%%%%%%%%%%%%%%
        for iview=1:nbview
            % reading input file(s)
            [Data{iview},tild,errormsg] = read_field(filecell{iview,index},FileType{iview},InputFields{iview},frame_index{iview}(index));
            if ~isempty(errormsg)
                errormsg=['time_series / read_field / ' errormsg];
                display(errormsg)
                break
            end
            if ~isempty(NbSlice_calib)
                Data{iview}.ZIndex=mod(i1_series{iview}(index)-1,NbSlice_calib{iview})+1;%Zindex for phys transform
            end
        end
        if isempty(errormsg)
            Field=Data{1}; % default input field structure
            % coordinate transform (or other user defined transform)
            % none
            
            %field projection on an object
            if Param.CheckObject
                [Field,errormsg]=proj_field(Field,Param.ProjObject);
                if ~isempty(errormsg)
                    msgbox_uvmat('ERROR',['time_series / proj_field / ' errormsg])
                    return
                end
            end
            nbfile=nbfile+1;
            
            % initiate the time series at the first iteration
            if nbfile==1
                % stop program if the first field reading is in error
                if ~isempty(errormsg)
                    displ_uvmat('ERROR',['time_series / sub_field / ' errormsg],checkrun)
                    return
                end
                DataOut=Field;%default
                DataOut.NbDim=Field.NbDim+1; %add the time dimension for plots
                nbvar=length(Field.ListVarName);
                if nbvar==0
                    displ_uvmat('ERROR','no input variable selected',checkrun)
                    return
                end
                testsum=2*ones(1,nbvar);%initiate flag for action on each variable
                if isfield(Field,'VarAttribute') % look for coordinate and flag variables
                    for ivar=1:nbvar
                        if length(Field.VarAttribute)>=ivar && isfield(Field.VarAttribute{ivar},'Role')
                            var_role=Field.VarAttribute{ivar}.Role;%'role' of the variable
                            if isequal(var_role,'errorflag')
                                displ_uvmat('ERROR','do not handle error flags in time series',checkrun)
                                return
                            end
                            if isequal(var_role,'warnflag')
                                testsum(ivar)=0;  % not recorded variable
                                eval(['DataOut=rmfield(DataOut,''' Field.ListVarName{ivar} ''');']);%remove variable
                            end
                            if isequal(var_role,'coord_x')| isequal(var_role,'coord_y')|...
                                    isequal(var_role,'coord_z')|isequal(var_role,'coord')
                                testsum(ivar)=1; %constant coordinates, record without time evolution
                            end
                        end
                        % check whether the variable ivar is a dimension variable
                        DimCell=Field.VarDimName{ivar};
                        if ischar(DimCell)
                            DimCell={DimCell};
                        end
                        if numel(DimCell)==1 && isequal(Field.ListVarName{ivar},DimCell{1})%detect dimension variables
                            testsum(ivar)=1;
                        end
                    end
                end
                for ivar=1:nbvar
                    if testsum(ivar)==2
                        eval(['DataOut.' Field.ListVarName{ivar} '=[];'])
                    end
                end
                DataOut.ListVarName=[{'Time'} DataOut.ListVarName];
            end
            
            % add data to the current field
            for ivar=1:length(Field.ListVarName)
                VarName=Field.ListVarName{ivar};
                VarVal=Field.(VarName);
                if testsum(ivar)==2% test for recorded variable
                    if isempty(errormsg)
                        if isequal(Param.ProjObject.ProjMode,'inside')% take the average in the domain for 'inside' mode
                            if isempty(VarVal)
                                displ_uvmat('ERROR',['empty result at frame index ' num2str(i1_series{iview}(index))],checkrun)
                                return
                            end
                            VarVal=mean(VarVal,1);
                        end
                        VarVal=shiftdim(VarVal,-1); %shift dimension
                        DataOut.(VarName)=cat(1,DataOut.(VarName),VarVal);%concanete the current field to the time series
                    else
                        DataOut.(VarName)=cat(1,DataOut.(VarName),0);% put each variable to 0 in case of input reading error
                    end
                elseif testsum(ivar)==1% variable representing fixed coordinates
                    VarInit=DataOut.(VarName);
                    if isempty(errormsg) && ~isequal(VarVal,VarInit)
                        displ_uvmat('ERROR',['time series requires constant coordinates ' VarName],checkrun)
                        return
                    end
                end
            end
            
            % record the time:
            if isempty(time)% time not set by xml filer(s)
                if isfield(Data{1},'Time')
                    DataOut.Time(nbfile,1)=Field.Time;
                else
                    DataOut.Time(nbfile,1)=index;%default
                end
            else % time from ImaDoc prevails  TODO: correct
                DataOut.Time(nbfile,1)=time(index);%
            end
            
            % record the number of missing input fields
            if ~isempty(errormsg)
                nbmissing=nbmissing+1;
                display(['index=' num2str(index) ':' errormsg])
            end
        end
    end
end
%%%%%%% END OF LOOP WITHIN A SLICE

%remove time for global attributes if exists
Time_index=find(strcmp('Time',DataOut.ListGlobalAttribute));
if ~isempty(Time_index)
    DataOut.ListGlobalAttribute(Time_index)=[];
end
DataOut.Conventions='uvmat';
for ivar=1:numel(DataOut.ListVarName)
    VarName=DataOut.ListVarName{ivar};
    eval(['DataOut.' VarName '=squeeze(DataOut.' VarName ');']) %remove singletons
end

% add time dimension
for ivar=1:length(Field.ListVarName)
    DimCell=Field.VarDimName(ivar);
    if testsum(ivar)==2%variable used as time series
        DataOut.VarDimName{ivar}=[{'Time'} DimCell];
    elseif testsum(ivar)==1
        DataOut.VarDimName{ivar}=DimCell;
    end
end
indexremove=find(~testsum);
if ~isempty(indexremove)
    DataOut.ListVarName(1+indexremove)=[];
    DataOut.VarDimName(indexremove)=[];
    if isfield(DataOut,'Role') && ~isempty(DataOut.Role{1})%generaliser aus autres attributs
        DataOut.Role(1+indexremove)=[];
    end
end

%shift variable attributes
if isfield(DataOut,'VarAttribute')
    DataOut.VarAttribute=[{[]} DataOut.VarAttribute];
end
DataOut.VarDimName=[{'Time'} DataOut.VarDimName];
DataOut.Action=Param.Action;%name of the processing programme
test_time=diff(DataOut.Time)>0;% test that the readed time is increasing (not constant)
if ~test_time
    DataOut.Time=1:filecounter;
end

% display nbmissing
if ~isequal(nbmissing,0)
    displ_uvmat('WARNING',[num2str(nbmissing) ' files skipped: missing files or bad input, see command window display'],checkrun)
end

%name of result file
OutputFile=fullfile_uvmat(RootPath{1},OutputDir,RootFile{1},FileExtOut,NomTypeOut,i1_series{1}(1),i1_series{1}(end),i_slice,[]);
errormsg=struct2nc(OutputFile,DataOut); %save result file
if isempty(errormsg)
    display([OutputFile ' written'])
else
    displ_uvmat('ERROR',['error in Series/struct2nc: ' errormsg],checkrun)
end

return

%%%%%%%%%%%%%%%%%%  END%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%evaluation of peacklocking errors
%use splinhist: give spline coeff cc for a smooth histo (call spline4)
%use histsmooth(x,cc): calculate the smooth histo for any value x
%use histder(x,cc): calculate the derivative of the smooth histo
global hfig1 hfig2 hfig3
global nbb Uval Vval Uhist Vhist % nbb resolution of the histogram nbb=10: 10 values in unity interval
global xval xerror yval yerror

set(handles.vector_y,'Value',1)% trigger the option Uhist on the interface
set(handles.Vhist_input,'Value',1)
set(handles.cm_switch,'Value',0) % put the switch to 'pixel'

%adjust the extremal values of the histogram in U with respect to integer
%values
minimU=round(min(Uval)-0.5)+0.5; %first value of the histogram with integer bins 
maximU=round(max(Uval)-0.5)+0.5;
minim_fin=(minimU-0.5+1/(2*nbb)); % first bin valueat the beginning of an integer interval
maxim_fin=(maximU+0.5-1/(2*nbb)); % last integer value
nb_bin_min= round(-(minim_fin - min(Uval))*nbb); % nbre of bins added below
nb_bin_max=round((maxim_fin -max(Uval))*nbb); %nbre of bins added above
Uval=[minim_fin:(1/nbb):maxim_fin];
histu_min=zeros(nb_bin_min,1);
histu_max=zeros(nb_bin_max,1);
Uhist=[histu_min; Uhist ;histu_max]; % column vector

%adjust the extremal values of the histogram in V
minimV=round(min(Vval-0.5)+0.5);
maximV=round(max(Vval-0.5)+0.5);
minim_fin=minimV-0.5+1/(2*nbb); % first bin valueat the beginning of an integer interval
maxim_fin=maximV+0.5-1/(2*nbb); % last integer value
nb_bin_min=round((min(Vval) - minim_fin)*nbb); % nbre of bins added below
nb_bin_max=round((maxim_fin -max(Vval))*nbb);
Vval=[minim_fin:(1/nbb):maxim_fin];
histu_min=zeros(nb_bin_min,1);
histu_max=zeros(nb_bin_max,1);
Vhist=[histu_min; Vhist ;histu_max]; % column vector

% RUN_histo_Callback(hObject, eventdata, handles)
% %adjust the histogram to integer values:

%histoU and V
[Uhistinter,xval,xerror]=peaklock(nbb,minimU,maximU,Uhist);
[Vhistinter,yval,yerror]=peaklock(nbb,minimV,maximV,Vhist);

% selection of value ranges such that histo>=10 (enough statistics)
Uval_ind=find(Uhist>=10);
ind_min=min(Uval_ind);
ind_max=max(Uval_ind);
U_min=Uval(ind_min);% minimum allowed value 
U_max=Uval(ind_max);%maximum allowed value

% selection of value ranges such that histo>=10 (enough statistics)
Vval_ind=find(Vhist>=10);
ind_min=min(Vval_ind);
ind_max=max(Vval_ind);
V_min=Vval(ind_min);% minimum allowed value 
V_max=Vval(ind_max);%maximum allowed value

figure(4)% plot U histogram with smoothed one
plot(Uval,Uhist,'b')
grid on
hold on
plot(Uval,Uhistinter,'r');
hold off

figure(5)% plot V histogram with smoothed one
plot(Vval,Vhist,'b')
grid on
hold on
plot(Vval,Vhistinter,'r');
hold off

figure(6)% plot pixel error in two subplots
hfig4=subplot(2,1,1);
hfig5=subplot(2,1,2);
axes(hfig4)
plot(xval,xerror)
axis([U_min U_max -0.4 0.4])
xlabel('velocity u (pix)')
ylabel('peaklocking error (pix)')
grid on
axes(hfig5)
plot(yval,yerror)
axis([V_min V_max -0.4 0.4]);
xlabel('velocity v (pix)')
ylabel('peaklocking error (pix)')
grid on









%'peaklock': determines peacklocking errors from velocity histograms.
%-------------------------------------------------------
%first smooth the input histogram 'histu' in such a way that the integral over
%n-n+1 is preserved, then deduce the peaklocking 'error' function of the pixcel displacement 'x'.
%
% [histinter,x,error]=peaklock(nbb,minim,maxim,histu)
%OUTPUT:
%histinter: smoothed interpolated histogram
% x: vector of displacement values.
% error: vector of estimated errors corresponding to x
%INPUT:
%histu=vector representing the values of histogram  of measured velocity ;
%minim, maxim: extremal values of the measured velocity (absica for histu)
%nbb: number of bins inside each integer interval for the histograms
%SUBROUTINES INCLUDED:
%spline4.m% spline interpolation at 4th order
%splinhist.m: give spline coeff cc for a smooth histo (call spline4)
%histsmooth.m(x,cc): calculate the smooth histo for any value x
%histder.m(x,cc): calculate the derivative of the smooth histo
function [histinter,x,error]=peaklock(nbb,minim,maxim,histu)

nint=maxim-minim+1
xfin=[minim-0.5+1/(2*nbb):(1/nbb):maxim+0.5-(1/(2*nbb))];
histo=(reshape(histu,nbb,nint));%extract values with x between integer -1/2 integer +1/2
Integ=sum(histo)/nbb; %integral of the pdf on each integer bin
[histinter,cc]=splinhist(Integ,minim,nbb);
histx=reshape(histinter,nbb,nint);
xint=[minim:1:maxim];
x=zeros(nbb,nint);
%determination of the displacement x(j,:)
%j=1
delx=histo(1,:)./histsmooth(-0.5*ones(1,nint),cc)/nbb;
%del(1,:)=delx;
x(1,:)=-0.5+delx-(delx.*delx/2).*histder(-0.5*ones(1,nint),cc);
%histx(1,:)=histsmooth(x(j-1,:),cc);
for j=2:nbb
    delx=histo(j,:)./histsmooth(x(j-1,:),cc)/nbb;
    %delx=delx.*(delx<3*ones(1,nint)/nbb)+3*ones(1,nint)/nbb.*~(delx <3*ones(1,nint)/nbb)
    x(j,:)=x(j-1,:)+delx-(delx.*delx/2).*histder(x(j-1,:),cc);
end
%reshape
xint=ones(nbb,1)*xint;
x=x+xint;
x=reshape(x,1,nbb*nint);
error=xfin+1/(2*nbb)-x;

%-------------------------------------------------------
% --- determine the spline coefficients cc for the interpolated histogram.
%-------------------------------------------------
function [histsmooth,cc]= splinhist(Integ,mini,nbb)
% provides a smooth histogramm histmooth, which remains always positive,
% and is such that its sum over each integer bin [i-1/2 i+1/2] is equal to
% Integ(i). The function determines histmooth as the exponential of a 4th
% order spline function and adjust the cefficients by a Newton method to
% fit the integral conditions Integ
% histmooth is determined at the abscissa
% xfin=[mini-0.5+1/(2*n):(1/n):maxi+0.5-(1/(2*n))] (maxi=mini+size(aa)-1)
%cc(1-5,i) provides the spline coefficients

% order 0
siz=size(Integ);
nint=siz(2);
izero=find(Integ==0); %indices of zero elements
inonzero=find(Integ);
Integ(izero)=min(Integ(inonzero));
aa=log(Integ);%initial guess for a coeff
spli=spline4(aa,mini,nbb);  %appel à la fonction spline4
histsmooth=exp(spli);

S=(sum(reshape(histsmooth,nbb,nint)))/nbb;% integral of the fit histsmooth on ]i-1/2 i+1/2[
epsilon=max(abs(Integ-S));
iter=0;
while epsilon > 0.000001 & iter<10
ident=eye(nint);
dSda=ones(nint);
for j=1:nint% determination of the jacobian matrix dSda
dhistda=spline4(ident(j,:),mini,nbb);
expdhistda=dhistda.*histsmooth;
dSda(j,:)=(sum(reshape(expdhistda,nbb,nint)))/nbb;
end
aa=aa+(Integ-S)*inv(dSda);%new estimate of coefficients aa by linear interpolation
[spli,bb]=spline4(aa,mini,nbb);% new fit histsmooth
histsmooth=exp(spli);
S=(sum(reshape(histsmooth,nbb,nint)))/nbb;% integral of the fit histsmooth on ]i-1/2 i+1/2[
epsilon=max(abs(Integ-S));
iter=iter+1;
end
if iter==10, errordlg('splinhist did not converge after 10 iterations'),end
cc(1,:)=aa;
cc(2,:)=bb(1,:);
cc(3,:)=bb(2,:);
cc(4,:)=bb(3,:);
cc(5,:)=bb(4,:);

%-------------------------------------------------------
% --- determine the 4th order spline coefficients from the function values aa.
%-------------------------------------------------
function [histsmooth,bb]= spline4(aa,mini,n)
% spline interpolation at 4th order
%aa=vector of values of a function at integer abscissa, starting at mini
%n=number of subdivisions for the interpolated function
% histmooth =interpolated values at absissa
% xfin=[mini-0.5+1/(2*n):(1/n):maxi+0.5-(1/(2*n))] (maxi=mini+size(aa)-1)
%bb=[b(i);c(i);d(i); e(i)] matrix of spline coeff
L1=[1/2 1/4 1/8 1/16;1 1 3/4 1/2;0 2 3 3;0 0 6 12];
L2=[-1/2 1/4 -1/8 1/16;1 -1 3/4 -1/2;0 2 -3 3;0 0 6 -12];
M=inv(L2)*L1;
[V,D]=eig(M);
F=-inv(V)*inv(L2)*[1 ;0 ;0;0];
a1rev=[1 -1/D(1,1)];
b1rev=[F(1)/D(1,1)];
a2rev=[1 -1/D(2,2)];
b2rev=[F(2)/D(2,2)];
a3=[1 -D(3,3)];
b3=[F(3)];
a4=[1 -D(4,4)];
b4=[F(4)];

%data
% n=10;% résolution de la pdf: nbre de points par unite de u
% mini=-10.0;%general mini=uint16(min(values)-1 CHOOSE maxi-mini+1 EVEN
% maxi=9.0; % general maxi=uint16(max(values))+1
%nint=double(maxi-mini+1); % nombre d'intervals entiers EVEN!
siz=size(aa);
nint=siz(2);
maxi=mini+nint-1;
npdf=nint*n;% nbre total d'intervals à introduire dans la pdf: hist(u,npdf)
%simulation de pdf
xfin=[mini-0.5+1/(2*n):(1/n):maxi+0.5-(1/(2*n))];% valeurs d'interpolation: we take n values in each integer interval
%histolin=exp(-(xfin-1).*(xfin-1)).*(2+cos(10*(xfin-1)));% simulation d'une pdf
%histo=log(histolin);
%histo=sin(2*pi*xfin);
%histextract=(reshape(histo,n,nint));
%aa=sum(histextract)/n %integral of the pdf on each integer bin
IP=[0 diff(aa)];
Irev=zeros(size(aa));
for i=1:nint
    Irev(i)=aa(end-i+1);
end
IPrev=[0 diff(Irev)];

%get the spline coelfficients a_d, using filter on the eigen vectors A,B,C
Arev=filter(b1rev,a1rev,IPrev);
Brev=filter(b2rev,a2rev,IPrev);
C=filter(b3,a3,IP);
D=filter(b4,a4,IP);
A=zeros(size(Arev));
B=zeros(size(Brev));
for i=1:nint
    A(i)=Arev(end-i+1);
    B(i)=Brev(end-i+1);
end
%Matr=V*[A;B;C;D];
bb=V*[A;B;C;D];
%b=Matr(1,:);
%c=Matr(2,:);
%d=Matr(3,:);
%e=Matr(4,:);
%a=aa;

%calculate the interpolation using the spline coefficients a-d
%xextract=(reshape(xfin,n,nint));% 
chi=xfin+1/(2*n)-min(xfin)-double(int16(xfin+(1/(2*n))-min(xfin)))-0.5;% decimal part
chi2=chi.*chi;
chi3=chi2.*chi;
chi4=chi3.*chi;
avec=reshape(ones(n,1)*aa,1,n*nint);
bvec=reshape(ones(n,1)*bb(1,:),1,n*nint);
cvec=reshape(ones(n,1)*bb(2,:),1,n*nint);
dvec=reshape(ones(n,1)*bb(3,:),1,n*nint);
evec=reshape(ones(n,1)*bb(4,:),1,n*nint);
histsmooth=avec+bvec.*chi+cvec.*chi2+dvec.*chi3+evec.*chi4;

%-------------------------------------------------------
% --- determine the interpolated histogram at points chi from the spline ceff cc.
%-------------------------------------------------
function histx= histsmooth(chi,cc)
% provides the value of the interpolated histogram at values chi=x-i
%(difference with the mnearest integer)
% cc(5,size(chi)) is the set of spline coefficients obtained by splinhist
chi2=chi.*chi;
chi3=chi2.*chi;
chi4=chi3.*chi;
histx=exp(cc(1,:)+cc(2,:).*chi+cc(3,:).*chi2+cc(4,:).*chi3+cc(5,:).*chi4);

%-------------------------------------------------------
% --- determine the derivative p'/p of the interpolated histogram at points chi from the spline ceff cc.
%-------------------------------------------------
function histder= histder(chi,cc)
% provides the logarithmique derivative p'/p of the interpolated histogram
%at values chi=x-i
%(difference with the nearest integer)
% cc(5,size(chi)) is the set of spline coefficients obtained by splinhist
chi2=chi.*chi;
chi3=chi2.*chi;
chi4=chi3.*chi;
histder=cc(2,:)+2*cc(3,:).*chi+3*cc(4,:).*chi2+4*cc(5,:).*chi3;