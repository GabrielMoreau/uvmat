% vel2vol:interpolate 2D velocity fields to volumes with structured coordinates in phys space 
% (specific to RDvision system)
%----------------------------------------------------------------------

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

function GUI_input=vel2vol(num_i1,num_i2,num_j1,num_j2,Series)
%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
        GUI_input={'RootPath';'one';...%nbre of possible input series (options 'on'/'two'/'many', default:'one')
        'SubDir';'on';... % subdirectory of derived files (PIV fields), ('on' by default)
        'RootFile';'on';... %root input file name ('on' by default)
        'FileExt';'on';... %input file extension ('on' by default)
        'NomType';'on';...%type of file indexing ('on' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        'VelTypeMenu';'one';...% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
        'FieldMenu';'one';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        'CoordType'; 'on';...%can use a transform function
        'GetObject';'on';...%can use projection object(option 'off'/'one'/'two',
               ''}
    return %exit the function 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%enable waitbar
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PARAMETERS
listfield=get(hseries.FieldMenu,'String');
testfield=get(hseries.FieldMenu,'Value');
FieldName=listfield{testfield}
listfield=get(hseries.VelTypeMenu,'String');
testfield=get(hseries.VelTypeMenu,'Value');
VelType=listfield{testfield}
transform_fct=Series.transform_fct;%handles of phys transform function


%% projection object (volume)
test_object=get(hseries.GetObject,'Value');
if test_object%isfield(Series,'sethandles')
    hset_object=findobj(allchild(0),'tag','set_object');
%     ProjObject=read_set_object(guidata(hset_object));
    ProjObject=read_GUI(hset_object);
    if ~strcmp(ProjObject.Style,'volume')&&~strcmp(ProjObject.ProjMode,'interp')
        msgbox_uvmat('ERROR',['a volume with projection mode interp must be defined']);
        return
    end
    answer=msgbox_uvmat('CONFIRMATION',['fields will be interpolated at the grid points of the volume']);
else
     answer=msgbox_uvmat('CONFIRMATION',['fields will be concatenated without interpolation']);
end

%% create dir of the volume velocity fields
basename=fullfile(Series.RootPath,Series.RootFile) ;
% [dir_ima,namebase]=fileparts(basename);
% [path,subdir_ima]=fileparts(dir_ima);
SubDirNew=[Series.SubDir '_vol'];
newdir=fullfile(Series.RootPath,SubDirNew);
mkdir(newdir);
[xx,msg2] = fileattrib(newdir,'+w','g'); %yield writing access (+w) to user group (g)
if ~strcmp(msg2,'')
    msgbox_uvmat('ERROR',['pb of permission for ' subdir_vel ': ' msg2])%error message for directory creation
    return
end
display(['volume fields in the directory ' newdir])
% basename_new=fullfile(newdir,Series.RootFile);


%% read imadoc
[XmlData,warntext]=imadoc2struct([basename '.xml']);
nbfield1=size(num_i1,1);
nbfield2=size(XmlData.Time,2);% use the whole set of j indices
% set(hseries.first_i,'String',num2str(first_label))% display the first image in the process
set(hseries.last_j,'String',num2str(nbfield2))% display the last image in the process

%% main loop
for ifile=1:nbfield1
    update_waitbar(hseries.waitbar,WaitbarPos,ifile/nbfield1)
    for jfile=1:nbfield2
        filename=name_generator(basename,num_i1(ifile,jfile),num_j1(ifile,jfile),Series.FileExt,Series.NomType,1,num_i2(ifile,jfile),num_j2(ifile,jfile),Series.SubDir);
        [Field,VelTypeOut]=read_civxdata(filename,FieldName,VelType);
        if isfield(Field,'Txt')
            msgbox_uvmat('ERROR',Field.Txt)
            return
        end
        Field.ZIndex=jfile;
        % coordinate transform
        Field=transform_fct(Field,XmlData);
        % concatene slices
        if jfile==1
            %             if isempty(Field.absolut_time_T0) || isequal(Field.civ,0)
            %                 msgbox_uvmat('ERROR','the input file is not civx data')
            %                 return
            %             end
            FieldVol=Field;
            FieldVol.NbDim=3;
        else
            FieldVol.X=[FieldVol.X; Field.X];
            FieldVol.Y=[FieldVol.Y; Field.Y];
            FieldVol.Z=[FieldVol.Z; Field.Z];
            FieldVol.U=[FieldVol.U; Field.U];
            FieldVol.V=[FieldVol.V; Field.V];
            if isfield( Field,'F')
                FieldVol.F=[FieldVol.F; Field.F];
            end
        end
    end
    if test_object
        [FieldVol,errormsg]=proj_field(FieldVol,ProjObject);
        if ~isempty(errormsg)
            msgbox_uvmat('ERROR',['error in vel2vol/proj_field:' errormsg])
            return
        end
    end
    filename_new=name_generator(basename,num_i1(ifile,jfile),[],'.nc','_1',1,num_i2(ifile,jfile),[],SubDirNew);
    errormsg=struct2nc(filename_new,FieldVol);
    if isempty(errormsg)
        display([filename_new ' written'])
    else
        msgbox_uvmat('ERROR',['error in vel2vol/struct2nc:' errormsg])
        return
    end
end

