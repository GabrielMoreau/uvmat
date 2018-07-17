
%%% extract a series of image folders from RDvision
% to run on the cluster, edit the file extract.sh in the folder TOP_view or SCANSIDE, 
% Then oarsub -l "walltime=20:00:00" /fsnet/project/coriolis/2018/18ADDUCE/TOP_View/extract.sh
function batch_extract_rdvision(RootDir)

RootFolder=fullfile('/fsnet/project/coriolis/2018/18ADDUCE',RootDir);
ParamFile=fullfile(RootFolder,'extract_param.xml');
XmlFile=fullfile(RootFolder,'im.xml');
Param=xml2struct(ParamFile);
switch RootDir
    case 'TOP_View'
        XmlFile='';
        Param.OutputRootFile='Falcon';
    case 'SCANSIDE'
        XmlFile='im.xml';
        Param.OutputRootFile='im';
end
ListStruct=dir(RootFolder); % get structure of the Root directory
ListCells=struct2cell(ListStruct);% transform dir struct to a cell arrray
ListNames=ListCells(1,:);%list of file names
index_dir=find(strcmp('isdir',fieldnames(ListStruct)));%detect folders
check_dir=cell2mat(ListCells(index_dir,:));% =1 for directories, =0 for files
ListDir=ListNames(check_dir);
ind_bad=[find(strcmp('.',ListDir)) find(strcmp('..',ListDir))];
ListDir(ind_bad)=[];

%NbFolders=1%5; %totql number of folders to process
% first=9;% #3 is the first folder in the list (#1='.', #2='..')
% disp('first folder')
% dd(first).name
% last=15;%19;
% disp('last folder')
% dd(last).name

%for ilist=first:first+NbFolders-1
for ilist=1:numel(ListDir)
    disp([ListDir{ilist} ' opened'])
    ddd=dir(fullfile(RootFolder,ListDir{ilist}));
    dddCells=struct2cell(ddd);% transform dir struct to a cell arrray
    dddNames=dddCells(1,:);%list of file names
    checkdone=false;
    checkrdvision=0;
    for iname=1:numel(dddNames)
        checkdone=~isempty(regexp(dddNames{iname},'.extract$'));
        if checkdone
            disp('already extracted')
            break
        end
        checkrdvision=checkrdvision+isequal(regexp(dddNames{iname},'^2018-'),1)
    end
    if ~checkdone
        if checkrdvision==0
            disp('no rdvision folder')
        elseif checkrdvision>1
            disp('multiple rdvision folders, no extraction')
        else
            Param.InputTable{1}=fullfile(RootFolder,ListDir{ilist});%folder exp
            Param.InputTable{2}=ddd(3).name;
            DataFolder=fullfile(Param.InputTable{1},Param.InputTable{2});
            ExtractFolder=fullfile(Param.InputTable{1},[Param.InputTable{2} '.extract']);
            mkdir(ExtractFolder)
            if ~isempty(XmlFile)
                copyfile(XmlFile,fullfile(DataFolder,[Param.OutputRootFile '.xml']));
            end
            seqname=fullfile(DataFolder,[Param.InputTable{3} Param.InputTable{5}]);
            [A,FileInfo,timestamps,errormsg]=read_rdvision(seqname,[]);
            Param.IndexRange.last_i=str2num(FileInfo.numberoffiles);
            Param.OutputSubDir=Param.InputTable{2};
            Param.ActionInput.LogPath= DataFolder;
            extract_rdvision(Param)% apply the function used in series
            disp([ListDir{ilist} ' extracted'])
        end
    end
end
'PROGRAM END'
%%%%% COMMAND CLUSTER
%oarsub -l "walltime=10:00:00" /fsnet/project/coriolis/2018/18ADDUCE/SCANSIDE/extract.sh -E /fsnet/project/coriolis/2018/18ADDUCE/SCANSIDE/error -O /fsnet/project/coriolis/2018/18ADDUCE/SCANSIDE/stdout
