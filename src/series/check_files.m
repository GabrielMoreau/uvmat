function GUI_input=check_files(num_i1_cell,num_i2_cell,num_j1_cell,num_j2_cell,Series) %(filecell,filecell_1,num_i,num_j,vel_type,field,param);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %detect the chosen series of files and check their date of modification:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%INPUT: 
%num_i1: series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2: series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1: series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2: series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%OTHER INPUTS given by the structure Series

%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1_cell','var')
    GUI_input={'RootPath';'many';...%nbre of possible input series (options 'on'/'two'/'many', default:'one')
        'SubDir';'on';... % subdirectory of derived files (PIV fields), ('on' by default)
        'RootFile';'on';... %root input file name ('on' by default)
        'FileExt';'on';... %input file extension ('on' by default)
        'NomType';'on';...%type of file indexing ('on' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        %'VelTypeMenu';'on';...% menu for selecting the velocity type (civ1,..) 'off' by default)
        %'FieldMenu';'on';...% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
        %'CoordType';'on'...%can use a transform function 'off' by default
        %'GetObject';'on'...%can use projection object ,'off' by default
        %'GetMask';'on'...%can use mask option   ,'off' by default
        %'PARAMETER'; options: name of the user defined parameter',repeat a line for each parameter 
               ''};
    return %exit the function 
end

%standard parameters for waitbar and STOP action (do not modify)
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position');

%%%%%%%%%%%%%%%%%%%%%%%%

% number of slices
NbSlice=str2num(get(hseries.NbSlice,'String'));
if isempty(NbSlice)
    NbSlice=1;
end
NbSlice_name=num2str(NbSlice);
if isequal(NbSlice,[]),NbSlice=1; end; %default

% number of views
count=0; 
testcell=iscell(Series.RootFile);
if ~testcell
    Series.RootPath={Series.RootPath};
    Series.RootFile={Series.RootFile};
    Series.SubDir={Series.SubDir};
    Series.FileExt={Series.FileExt};
    Series.NomType={Series.NomType};
end    
nbview=length(Series.RootFile);
for iview=1:nbview
    filebase=fullfile(Series.RootPath{iview},Series.RootFile{iview});%root file name
    if testcell
        num_i1=num_i1_cell{iview}; num_i2=num_i2_cell{iview}; num_j1=num_j1_cell{iview}; num_j2=num_j2_cell{iview};
    else
        num_i1=num_i1_cell; num_i2=num_i2_cell; num_j1=num_j1_cell; num_j2=num_j2_cell;
    end
    siz=size(num_i1);
    nbfield2=siz(1); %nb of consecutive fields at each level(burst
    nbfield=siz(1)*siz(2);
    nbfield=floor(nbfield/(nbfield2*NbSlice));%total number of i indexes (adjusted to an integer number of slices)
    if isequal(lower(Series.FileExt{iview}),'.avi')
        info=aviinfo([filebase Series.FileExt{iview}]);
        message{1}=info.Filename;
        message{2}=info.FileModDate;
        message{3}=[num2str(info.FramesPerSecond) ' frames/s '];
        message{4}=info.ImageType;
        message{5}=['  compression' info.VideoCompression];
        message{6}=[ 'quality ' num2str(info.Quality)];   
        Tabchar=message;
    else
        datnum=[];
        Tabchar={};
        %LOOP ON SLICES
        for i_slice=1:NbSlice
            for ifield=1:nbfield
                indselect(:,ifield)=((ifield-1)*NbSlice+(i_slice-1))*nbfield2+[1:nbfield2]';%selected indices on the list of files of a slice
            end 
            for index=1:nbfield*nbfield2
                stopstate=get(hseries.RUN,'BusyAction');
                if isequal(stopstate,'queue')% enable STOP command
                    update_waitbar(hseries.waitbar,WaitbarPos,index/(nbfield*nbfield2))
                    ifile=indselect(index);               
                    file=...
                       name_generator(filebase,num_i1(ifile),num_j1(ifile),Series.FileExt{iview},Series.NomType{iview},1,num_i2(ifile),num_j2(ifile),Series.SubDir{iview});                
                    [Path,Name,ext]=fileparts(file);
                    detect=exist(file,'file'); % check the existence of the file
                    if detect==0
                        count=count+1;
                        lastfield='not found';
                    else
                        datfile=dir(file);
                        datnum(ifile)=datenum(datfile.date);
                        filefound(ifile)={datfile.name};
                        lastfield='';
                        if isequal(Series.FileExt{iview},'.nc') || isequal(Series.FileExt{iview},'.cdf')
                            % check the content  netcdf file
                            Data=nc2struct(file,'ListGlobalAttribute','patch2','fix2','civ2','patch','fix','absolut_time_T0','hart');
                            if ~isempty(Data.patch2) && isequal(Data.patch2,1) 
                                lastfield='patch2';
                            elseif ~isempty(Data.fix2) && isequal(Data.fix2,1)
                                lastfield='fix2';
                            elseif ~isempty(Data.civ2) && isequal(Data.civ2,1);
                                lastfield='civ2';
                            elseif ~isempty(Data.patch) && isequal(Data.patch,1);
                                lastfield='patch1';
                            elseif ~isempty(Data.fix) && isequal(Data.fix,1);
                                lastfield='fix1';
                            elseif ~isempty(Data.absolut_time_T0) && ~isempty(Data.hart)
                                lastfield='civ1'; 
                            end                          
                        end 
                    end
                    Tabchar(1,i_slice)={['slice #' num2str(i_slice)]};
                    Tabchar(index+1,i_slice)={[file '   ' lastfield]};
                end
            end
        end
        if isempty(datnum)
            if NbSlice>1
                message=['no set of ' num2str(NbSlice) ' (NbSlices) files found'];
            else
                 message='no file found';
            end
        else
            datnum=datnum(find(datnum));%keep the non zero values corresponding to existing files
            [first,ind]=min(datnum);
            [last,indlast]=max(datnum);
            message={['oldest modification:  ' cell2mat(filefound(ind)) ' : ' datestr(first)];...
                ['latest modification:  ' cell2mat(filefound(indlast)) ' : ' datestr(last)]};
        end 
        if ~isempty(Tabchar)
          Tabchar=reshape(Tabchar,NbSlice*(nbfield*nbfield2+1),1);
        end
    end
    hfig=figure(iview);
    clf
    if iview>1
        pos=get(iview-1,'Position');
        pos(1)=pos(1)+(iview-1)*pos(1)/nbview;
        set(hfig,'Position',pos)
    end
    set(hfig,'name',['view= ' num2str(iview)])
   
    h=uicontrol('Style','listbox', 'Position', [20 20 500 300], 'String', Tabchar, 'Callback', @ncbrowser_uvmat);
    hh=uicontrol('Style','listbox', 'Position', [20 340 500 40], 'String', message);
end
