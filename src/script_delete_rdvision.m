
%%% extract a series of image folders from RDvision
% to run on the cluster, edit the file extract.sh in the folder TOP_view or SCANSIDE,
% Then oarsub -l "walltime=20:00:00" /fsnet/project/coriolis/2018/18ADDUCE/TOP_View/extract.sh
%%%%%%%%%%%%%%  CHOOSE THE ROOT FOLDER %%%%%%%%%%

RootDir='1_DATA'
%RootFolder=fullfile('/fsnet/project/coriolis/2018/18JEVERB',RootDir);
%RootFolder=fullfile('/fsnet/project/edt/2021/21CORIOFARM',RootDir)
RootFolder=fullfile('/fsnet/project/coriolis/2024/24PLUME',RootDir)
%ParamFile=fullfile(RootFolder,'extract_param.xml');
%Param=xml2struct(ParamFile);

ListStruct=dir(RootFolder); % get structure of the Root directory
index_dir=find(strcmp('isdir',fieldnames(ListStruct)));%detect folder info in structure ListStruct
ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
check_dir=cell2mat(ListCells(index_dir,:));% =1 for directories, =0 for files
ListCells=ListCells(:,check_dir);
ListCells(:,1:2)=[];
ListNames=ListCells(1,:);
List2extract={};
List2delete={};
List2check={};

%% loop on experiments
for ilist=1:numel(ListNames)%loop on experiments
    ListNames{ilist}
    SubFolder=fullfile(RootFolder,ListNames{ilist});
    ListStructSub=dir(SubFolder); % get structure of the Root directory
    index_dir=find(strcmp('isdir',fieldnames(ListStructSub)));%detect folder info in structure ListStruct
    ListCellsSub=struct2cell(ListStructSub);% transform dir struct to a cell arrray
    check_dir=cell2mat(ListCellsSub(index_dir,:));% =1 for directories, =0 for files
    ListCellsSub=ListCellsSub(:,check_dir);
    ListCellsSub(:,1:2)=[];
    ListNamesSub=ListCellsSub(1,:);
    ind_rdvision=[];
    for isub=1:numel(ListNamesSub)% loop on data folders of the current experiment
        ListStructSubSub=dir(fullfile(RootFolder,ListNames{ilist},ListNamesSub{isub})); % get structure of the Root directory
        index_dir=find(strcmp('isdir',fieldnames(ListStructSubSub)));%detect folder info in structure ListStruct
        ListCellsSubSub=struct2cell(ListStructSubSub);% transform dir struct to a cell arrray
        check_dir=cell2mat(ListCellsSubSub(index_dir,:));% =1 for directories, =0 for files
        ListCellsSubSub=ListCellsSubSub(:,check_dir);
        ListCellsSubSub(:,1:2)=[];
        ListNamesSubSub=ListCellsSubSub(1,:);
        ind_rdvision=[];
        for isubsub=1:numel(ListNamesSubSub)
            if ~isempty(regexp(ListNamesSubSub{isubsub},'^2024-'))
                ind_rdvision=[ind_rdvision isubsub];%detect rdvision folders
            end
        end

        %% extract the rdvision image series if it was not done
        if numel(ind_rdvision)==1%
            DataFolder=fullfile(RootFolder,ListNames{ilist},ListNamesSub{isub},ListNamesSubSub{ind_rdvision});
            if isempty(regexp(DataFolder,'.extract$'))% if the detected folder is not .extract
                %     ExtractFolder=fullfile(Param.InputTable{1},[Param.InputTable{2} '.extract']);
                %     mkdir(ExtractFolder)
                % %     if ~isempty(XmlFile)
                % %     copyfile(fullfile(RootFolder,XmlFile),fullfile(DataFolder,[Param.OutputRootFile '.xml']));
                % %     end
                %     seqname=fullfile(DataFolder,[Param.InputTable{3} Param.InputTable{5}]);
                %     [A,FileInfo,timestamps,errormsg]=read_rdvision(seqname,[]);
                %     Param.IndexRange.last_i=str2num(FileInfo.numberoffiles);
                %     Param.OutputSubDir=Param.InputTable{2};
                %     Param.ActionInput.LogPath= DataFolder;
                %     extract_rdvision(Param)% apply the function used in series
                %     [ListNames{ilist} ' extracted']
                List2extract=[List2extract;DataFolder];
            end
        end

        %% delete the rdvision source if the extraction has been done
        Checkdelete=0;
        ExtractFolder=fullfile(RootFolder,ListNames{ilist},ListNamesSub{isub});
        status='';
        if numel(ind_rdvision)==2
            for irdvision=1:2
                CheckExtract(irdvision)=isempty(regexp(fullfile(RootFolder,ListNames{ilist},ListNamesSub{isub},ListNamesSubSub{irdvision}), '.extract$'));
            end
            status='extract missing';
            if numel(find(CheckExtract))==1
                ExtractFolder=fullfile(RootFolder,ListNames{ilist},ListNamesSub{isub},ListNamesSubSub{find(CheckExtract)});
                PngFolder=fullfile(RootFolder,ListNames{ilist},ListNamesSub{isub},'im');
                status='image folder not created';
                if exist(ExtractFolder,'dir') && exist(PngFolder,'dir')
                    filename_seq=fullfile(ExtractFolder,'im.seq');
                    try
                    s=ini2struct(filename_seq);
                    FileInfo=s.sequenceSettings;
                    if isfield(s.sequenceSettings,'numberoffiles')
                        NumberOfFrames=str2double(s.sequenceSettings.numberoffiles);
                    else
                        status='bad seq file';
                    end
                    catch ME
                        disp(['error in ' filename_seq])
                    end
                    DirPng=dir(PngFolder);
                    if numel(DirPng)==NumberOfFrames+2
                        Checkdelete=1;
                    else
                        status=['extraction not finished,' num2str(numel(DirPng)-2) ' images extracted'];
                    end
                end
            end
            %
            %
            %     Param.InputTable{1}=fullfile(RootFolder,ListDir{ilist});%folder exp
            %     ddd=dir(Param.InputTable{1});
            %     Param.InputTable{2}=ddd(3).name;
            %     DataFolder=fullfile(Param.InputTable{1},Param.InputTable{2});
            %     ExtractFolder=fullfile(Param.InputTable{1},[Param.InputTable{2} '.extract']);
            %     mkdir(ExtractFolder)
            %     if ~isempty(XmlFile)
            %     copyfile(fullfile(RootFolder,XmlFile),fullfile(DataFolder,[Param.OutputRootFile '.xml']));
            %     end
            %     seqname=fullfile(DataFolder,[Param.InputTable{3} Param.InputTable{5}]);
            %     [A,FileInfo,timestamps,errormsg]=read_rdvision(seqname,[]);
            %     Param.IndexRange.last_i=str2num(FileInfo.numberoffiles);
            %     Param.OutputSubDir=Param.InputTable{2};
            %     Param.ActionInput.LogPath= DataFolder;
            %     extract_rdvision(Param)% apply the function used in series
        end
        if Checkdelete
            List2delete=[List2delete;ExtractFolder];
            %rmdir(ExtractFolder,'s')
        elseif ~isempty(status)
            List2check=[List2check;[ExtractFolder ' ' status]];
        end
    end
end
List2extract
List2check
List2delete
if ~isempty(List2delete)
    Answer = questdlg('delete listed folders(Y/N)');
    if strcmp(Answer,'Yes')
        for ifolder=1:numel(List2delete)
            rmdir(List2delete{ifolder},'s')
        end
    end
end