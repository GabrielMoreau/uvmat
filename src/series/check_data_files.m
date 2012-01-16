%'check_files': check the existence and status of the files selected by series.fig
%------------------------------------------------------------------------
% function GUI_input=check_data_files(num_i1,num_i2,num_j1,num_j2,Series)
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
%num_i1: series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2: series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1: series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2: series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%Series: Matlab structure containing information set by the series interface
%
function GUI_input=check_data_files(Param) %(filecell,filecell_1,num_i,num_j,vel_type,field,param);
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
if ~exist('Param','var')
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

%% input parameters
% read the xml file for batch case
if ischar(Param) && ~isempty(find(regexp('Param','.xml$')))
    Param=xml2struct(Param);
else %  RUN case: parameters introduced as the input structure Param
    hseries=guidata(Param.hseries);%handles of the GUI series
    WaitbarPos=get(hseries.waitbar_frame,'Position');
end
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);


%%%%%%%%%%%%%%%%%%%%%%%%

% number of slices
NbSlice=Param.NbSlice;
if isempty(NbSlice),NbSlice=1; end; %default

%% root input file and type
    RootPath=Param.InputTable(:,1);
    RootFile=Param.InputTable(:,3);
    SubDir=Param.InputTable(:,2);
    NomType=Param.InputTable(:,4);
    FileExt=Param.InputTable(:,5);
% number of views
count=0;  
nbview=numel(RootFile);

for iview=1:nbview
    filebase=fullfile(RootPath{iview},RootFile{iview});%root file name
%     if testcell
%         num_i1=num_i1_cell{iview}; num_i2=num_i2_cell{iview}; num_j1=num_j1_cell{iview}; num_j2=num_j2_cell{iview};
%     else
%         num_i1=num_i1_cell; num_i2=num_i2_cell; num_j1=num_j1_cell; num_j2=num_j2_cell;
%     end
%     siz=size(num_i1);
    nbfield=size(i1_series{iview},1);
    nbfield2=size(i1_series{iview},2); %nb of consecutive fields at each level(burst
    nbfield=numel(i1_series{iview});
    nbfield=floor(nbfield/(nbfield2*NbSlice));%total number of i indexes (adjusted to an integer number of slices)
    if isequal(lower(FileExt{iview}),'.avi')
        info=aviinfo([filebase FileExt{iview}]);
        message{1}=info.Filename;
        message{2}=info.FileModDate;
        message{3}=[num2str(info.FramesPerSecond) ' frames/s '];
        message{4}=info.ImageType;
        message{5}=['  compression' info.VideoCompression];
        message{6}=[ 'quality ' num2str(info.Quality)];   
        Tabchar=message;
    else
        datnum=zeros(1,nbfield);
        Tabchar={};
        %LOOP ON SLICES
        for i_slice=1:NbSlice
            for ifield=1:nbfield
                indselect(:,ifield)=((ifield-1)*NbSlice+(i_slice-1))*nbfield2+[1:nbfield2]';%selected indices on the list of files of a slice
            end 
            filefound={};
            for index=1:nbfield*nbfield2
                stopstate=get(hseries.RUN,'BusyAction');
                if isequal(stopstate,'queue')% enable STOP command
                    update_waitbar(hseries.waitbar_frame,WaitbarPos,index/(nbfield*nbfield2))
                    ifile=indselect(index);               
%                     file=...
%                        name_generator(filebase,num_i1(ifile),num_j1(ifile),FileExt{iview},NomType{iview},1,num_i2(ifile),num_j2(ifile),SubDir{iview});                
                    file=filecell{iview,ifile};
                    [Path,Name,ext]=fileparts(file);
                    detect=exist(file,'file'); % check the existence of the file
                    if detect==0
                        count=count+1;
                        lastfield='not found';
                    else
                        datfile=dir(file);
                        if isfield(datfile,'datenum')
                            datnum(ifile)=datfile.datenum;
                        end
                        filefound(ifile)={datfile.name};
                        lastfield='';
                        [FileType,FileInfo,Object]=get_file_type(file);
                        if strcmp(FileType,'civx')||strcmp(FileType,'civdata')
                            if isfield(FileInfo,'CivStage')
                            liststage={'civ1','fix1','patch1','civ2','fix2','patch2'};
                            lastfield=liststage{FileInfo.CivStage};
                            end
                        end
                        lastfield=[FileType ', ' lastfield];                   
                    end
                    Tabchar(1,i_slice)={['slice #' num2str(i_slice)]};
                    Tabchar(index+1,i_slice)={[file '...' lastfield]};
                end
            end
        end
%         if isempty(datnum)||isempty(filefound)
        if isempty(filefound)
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
   
    h=uicontrol('Style','listbox', 'Position', [20 20 500 300], 'String', Tabchar, 'Callback', {'open_uvmat'});
    hh=uicontrol('Style','listbox', 'Position', [20 340 500 40], 'String', message);
end
