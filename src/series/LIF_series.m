%----------------------------------------------------------------------
% -process LIF images
%----------------------------------------------------------------------

%=======================================================================
% Copyright 2008-2018, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function GUI_input=LIF_series(num_i1,num_i2,num_j1,num_j2,Series);

%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
    GUI_input={'RootPath';'two';...%nbre of possible input series (options 'on'/'two'/'many', default:'one')
        'SubDir';'on';... % subdirectory of derived files (PIV fields), ('on' by default)
        'RootFile';'on';... %root input file name ('on' by default)
        'FileExt';'on';... %input file extension ('on' by default)
        'NomType';'on';...%type of file indexing ('on' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelTypeMenu';'one';...% menu for selecting the velocity type (civ1,..) options 'off'/'one'/'two', 'off' by default)
        'FieldMenu';'one';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'CoordType';'on';...%can use a transform function 'off' by default
        'GetObject';'on';...%can use projection object ,'off' by default
        %'GetMask';'on'...%can use mask option   ,'off' by default
        %'PARAMETER'; options: name of the user defined parameter',repeat a line for each parameter 
               ''};
    return %exit the function 
end

%-------------------------------------------------
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position'); %positiopn of waitbar frame
%-------------------------------------------------
addpath '/fsnet/project/coriolis/2006/06ICEBOX/0_MATLAB_WORK/LIF'% define path for concentration.m
% cpath=which('series');

%mode=''; %default
time=[];
nbviews=numel(Series.RootPath);
if nbviews<2
    msgbox_uvmat('ERROR','enter both LIF and PIV series')% we introduce PIV series to improve the filtering (remove particle image)
    return
end
[PD,LIFdir]=fileparts(Series.RootPath{1});

fulldir=fullfile(PD,'Concentration');
if ~exist(fulldir,'dir')
    try
     mkdir(fulldir)
     [xx,msg2] = fileattrib(fulldir,'+w','g'); %yield writing access (+w) to user group (g)
    catch ME
    msgbox_uvmat('ERROR',ME.message)
    return
    end
end

filebase_LIF=fullfile(fulldir,'LIF');%root name for the merged files
RootPath=Series.RootPath{1};
filebase=fullfile(Series.RootPath{1},Series.RootFile{1});%root file name 
filebase_1=fullfile(Series.RootPath{2},Series.RootFile{2});%root file name for PIV (background correction)
nbfield=numel(num_i1{1});%number of fields in the series
[XmlData,error]=imadoc2struct([filebase '.xml']);% calibration data for LIF
%[error,Heading,nom_type_read,ext_ima_read,tt,TimeUnit,mode,NbSlice,npx,npy,Calib{2}]
[XmlData_1,error]=imadoc2struct([filebase_1 '.xml']);% calibration data for PIV
if isfield(XmlData,'Time')
    time=XmlData.Time;
    if isfield(XmlData_1,'Time')
        time_1=XmlData_1.Time;
        if ~isequal(size(time),size(time_1))
            msgbox_uvmat('WARNING','inconsistent time array lengths in ImaDoc fields')
        end
    end
end
%check coincidence in time
if size(time,1)>1
    diff_time=max(max(abs(time-time_1)))
    if diff_time>0
        msgbox_uvmat(['times of series differ by more than ' num2str(diff_time)],'WARNING')
    end   
end


hRUN=findobj(Series.hseries,'Tag','RUN');%handles the the uicontrol 'RUN'
itime=0;
%%%%%%
%LOOP ON FILES
        RootPath=fullfile(RootPath,'LIF_REF');
for ifile=1:nbfield 
    stopstate=get(hRUN,'BusyAction');%enable stop button
    if isequal(stopstate,'queue')% enable STOP command
        update_waitbar(hseries.waitbar,WaitbarPos,ifile/nbfield)
        %name of the current LIF input file 
        [inputfile,idetect]=name_generator(filebase,num_i1{1}(ifile),num_j1{1}(ifile),Series.FileExt{1},Series.NomType{1},1,num_i1{1}(ifile),num_j2{1}(ifile));
        if ~idetect
            msgbox_uvmat('ERROR',[inputfile ' not found'])
            return
        end
        [Data,ParamOut,errormsg] = read_field(inputfile,'image',[]);
        Data.ZIndex=num_i1{1}(ifile)-Series.NbSlice*(floor((num_i1{1}(ifile)-1)/Series.NbSlice));%second field index
        
    
    file_ref=fullfile(RootPath,['lif_ref_' num2str(Data.ZIndex) '.nc']);
    Ref=nc2struct(file_ref);%reference file
        [inputfile_1,idetect]=name_generator(filebase_1,num_i1{2}(ifile),num_j1{2}(ifile),Series.FileExt{2},Series.NomType{2},1,num_i2{2}(ifile),num_j2{2}(ifile));
        if ~idetect
            msgbox_uvmat('ERROR',[inputfile_1 ' not found'])
            return
        end
        Data_1=read_field(inputfile_1,'image',{[]});% read the image
        Data_1.ZIndex=Data.ZIndex;
        %%% transform image to concentration
        [DataOut,dd,DataMask]=concentration(Data,XmlData,Data_1,XmlData_1,Ref);
        % output file name (netcdf)
        outputfile=name_generator(filebase_LIF,num_i1{1}(ifile),num_j1{1}(ifile),'.nc',Series.NomType{2},1,num_i2{1}(ifile),num_j2{1}(ifile));
        % create a structure to prepare the result file
        Resu.ListGlobalAttribute={'Project','InputFile_1','InputFile_2','Action','Time','ZIndex','z'};
        [PP,Resu.Project]=fileparts(Series.PathProject);
        Resu.InputFile_1=inputfile;
        Resu.InputFile_2=inputfile_1;
        Resu.Action=Series.Action;
        if isempty(time)
            Resu.Time=0;
        else
            Resu.Time=time(num_i1{1}(ifile),num_j1{1}(ifile));
        end
        Resu.ZIndex=Data.ZIndex;
        Resu.z=XmlData.GeometryCalib.SliceCoord(Data.ZIndex,3);
        Resu.ListVarName={'Coord_y' ,'Coord_x' ,'c','mask'};
        Resu.VarDimName={'Coord_y','Coord_x',{'Coord_y','Coord_x'},{'Coord_y','Coord_x'}};        
        Resu.Coord_y=[DataOut.Coord_y(1), DataOut.Coord_y(end)];
        Resu.Coord_x=[DataOut.Coord_x(1), DataOut.Coord_x(end)];
        Resu.c=DataOut.A;
        Resu.mask=DataMask.A;%to chnge to  cartesian coordinates (polar2phys)
        error=struct2nc(outputfile,Resu); %save result file
        if isempty(error)
            display(['output file ' outputfile ' written'])
        else
           display( error)
        end
    end
end
     
