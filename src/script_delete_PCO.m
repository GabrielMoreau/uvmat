
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
    check_PCOA(ilist)=0;
    check_PCOB(ilist)=0;
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
            % look for raw PCO folder (no extension .png)
            if ~isempty(regexp(ListNamesSubSub{isubsub},'^PCO', 'once'))&& isempty(regexp(ListNamesSubSub{isubsub},'.png', 'once'))
                ListNamesSubSub{isubsub};%raw PCO folder
                TifFolder=fullfile(RootFolder,ListNames{ilist},ListNamesSub{isub},ListNamesSubSub{isubsub});
                DirPCORaw=dir(TifFolder);
                DirPCORawCells=struct2cell(DirPCORaw);
                CheckTif=regexp(DirPCORAwCells(1,:),'.tif$');
                IndexTif=find(~cellfun('isempty',CheckTif));
                ListTif=DirPCORAwCells(1,IndexTif);
                try
                Info=imfinfo(fullfile(TifFolder,ListTif{1}));
                RecordLength=numel(Info);%Number of frames in fullfile(TifFolder,FileName)
                Info=imfinfo(fullfile(TifFolder,ListTif{end}));
                NumberOfFrames=numel(Info)+(numel(ListTif)-1)*RecordLength%Number of frames in fullfile(TifFolder,FileName)
                catch ME
                    disp(ME.message)
                    List2check=[List2check;TifFolder];
                end
                ind_png=find(strcmp([ListNamesSubSub{isubsub} '.png'],ListNamesSubSub)); %index of the .png folder corresponding to the raw PCO folder
                PngFolder=fullfile(RootFolder,ListNames{ilist},ListNamesSub{isub},ListNamesSubSub{ind_png})
                if exist(PngFolder,'dir')
                    DirPng=dir(PngFolder);
                    if numel(DirPng)==NumberOfFrames+6
                        PngCells=struct2cell(DirPng(7:end));
                        mm=cell2mat(PngCells(4,:));% check the sizes of extracted images
                        sizemax=max(mm)
                        sizemin=min(mm(3:end))
                        disp(['max size(Mbytes)=' num2str(sizemax/1000000)]);
                        if min(mm(3:end))<0.9*sizemax
                            status=['WARNING' 'min size(Mbytes)=' num2str(sizemin/1000000)];
                            List2check=[List2check;PngFolder];
                        else
                            List2delete=[List2delete;PngFolder];% approve deletion of the source multitif files
                        end
                    else
                        status=['extraction not finished,' num2str(numel(DirPng)-6) ' images extracted'];
                        List2check=[List2check;PngFolder];
                    end
                else
                    List2extract=[List2extract;TifFolder];
                end
            end
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
'END'