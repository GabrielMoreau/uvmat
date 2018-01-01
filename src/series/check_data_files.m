%%'check_data_files': check the existence, type and status of the files selected by series.fig
%------------------------------------------------------------------------
% function GUI_input=check_data_files(Param)
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%    .OutputDir: directory for data outputs, including path
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

function ParamOut=check_data_files(Param)

ParamOut=[];
%% input preparation mode (no RUN)
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='on';%nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputSubDirMode='none'; %(options 'none'/'custom'/'auto'/'first'/'last','auto' by default)
    %                      'none' =no output files
    return
end
%%%%%%%%%%%%  STANDARD PART  %%%%%%%%%%%%

%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% root input file(s) and type
RootPath=Param.InputTable(:,1);
RootFile=Param.InputTable(:,3);
SubDir=Param.InputTable(:,2);
NomType=Param.InputTable(:,4);
FileExt=Param.InputTable(:,5);
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
if isempty(i1_series)
    return
end
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
ImageTypeOptions={'image','multimage','mmreader','video','cine_phantom'};
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:nbview
    [FileInfo{iview},Object{iview}]=get_file_info(filecell{iview,1});
    FileType{iview}=FileInfo{iview}.FileType;
    CheckImage{iview}=~isempty(find(strcmp(FileType{iview},ImageTypeOptions)));% =1 for images
    CheckNc{iview}=~isempty(find(strcmp(FileType{iview},NcTypeOptions)));% =1 for netcdf files
end

%% MAIN LOOP ON VIEWS (INPUT LINES)
for iview=1:nbview
    if isequal(FileType{iview},'mmreader')||isequal(FileType{iview},'video')||isequal(FileType{iview},'multimage')
        [FileInfo]=get_file_info(filecell{iview,1});
        Tabchar{1}=filecell{iview,1};%info.Filename;
        Tabchar{2}='';
        Tabchar{3}=[num2str(FileInfo.FrameRate) ' frames/s '];
        message='';
    else
        Tabchar={};
        %LOOP ON SLICES
        for i_slice=1:NbSlice
            index_slice=i_slice:NbSlice:nbfield;
            filefound={};
            datnum=zeros(1,nbfield_j);
            for ifile=1:nbfield_i
                update_waitbar(WaitbarHandle,ifile/nbfield_i)
                if ishandle(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
                    disp('program stopped by user')
                    break
                end
                file=filecell{iview,index_slice(ifile)};
                [Path,Name,ext]=fileparts(file);
                detect=exist(file,'file'); % check the existence of the file
                if detect==0
                    lastfield='not found';
                else
                    datfile=dir(file);
                    if isfield(datfile,'datenum')
                        datnum(ifile)=datfile.datenum;
                        filefound(ifile)={datfile.name};
                    end
                    lastfield='';
                    [FileInfo,Object]=get_file_info(file);
                    FileType{iview}=FileInfo.FileType;
                    if strcmp(FileType{iview},'civx')||strcmp(FileType{iview},'civdata')
                        if isfield(FileInfo,'CivStage')
                            liststage={'civ','fix','patch'};
                            stagechoice=1+mod(FileInfo.CivStage-1,3);
                            iter=1+floor((FileInfo.CivStage-1)/3);
                            lastfield=[liststage{stagechoice} num2str(iter)];
                            %liststage={'civ1','fix1','patch1','civ2','fix2','patch2'};                        
                            %lastfield=liststage{FileInfo.CivStage};                           
                        end
                    end
                    lastfield=[FileType{iview} ', ' lastfield];
                end
                Tabchar(1,i_slice)={['slice #' num2str(i_slice)]};
                Tabchar(ifile+1,i_slice)={[file '...' lastfield]};
            end
        end
        if isempty(filefound)
            if NbSlice>1
                message=['no set of ' num2str(NbSlice) ' (NbSlices) files found'];
            else
                message='no file found';
            end
        else
            datnum=datnum(find(datnum));%keep the non zero values corresponding to existing files
            filefound=filefound(find(datnum));
            [first,ind]=min(datnum);
            [last,indlast]=max(datnum);
            message={['oldest modification:  ' filefound{ind} ' : ' datestr(first)];...
                ['latest modification:  ' filefound{indlast} ' : ' datestr(last)]};
        end
        if ~isempty(Tabchar)
            Tabchar=reshape(Tabchar,NbSlice*(nbfield_i+1),1);
        end
    end
    hfig=figure(iview);
    clf
    if iview>1
        pos=get(iview-1,'Position');
        pos(1)=pos(1)+(iview-1)*pos(1)/nbview;
        set(hfig,'Position',pos)
    end
    set(hfig,'name',['check_data_files:view= ' num2str(iview)])
    set(hfig,'MenuBar','none')% suppress the menu bar
    set(hfig,'NumberTitle','off')%suppress the fig number in the title
    h=uicontrol('Style','listbox', 'Position', [20 20 500 300], 'String', Tabchar, 'Callback', {'open_uvmat'});
    hh=uicontrol('Style','listbox', 'Position', [20 340 500 40], 'String', message);
end

% 'open_uvmat': open with uvmat the  field selected in the list of 'series/check_data_files'
%------------------------------------------------------------------------
%function open_uvmat(hObject, eventdata)
%
% INPUT: 
% hObject: handle of uicontrol object containing the list 
% eventdata: not used
function open_uvmat(hObject, eventdata)
%------------------------------------------------------------------------
list=get(hObject,'String');
index=get(hObject,'Value');
rootroot=get(hObject,'UserData');
filename=list{index};
ind_dot=strfind(filename,'...');
if ~isempty(ind_dot)
filename=filename(1:ind_dot-1);
end
filename=fullfile(rootroot,filename);
if exist(filename,'file')%visualise the vel field if it exists
    uvmat(filename)
    set(gcbo,'Value',1)
end
