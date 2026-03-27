function [ListPath, ListSubdir]=read_browsdata (hbrowse)

BrowseData=guidata(hbrowse);
SourceDir=get(BrowseData.SourceDir,'String');
ListExp=get(BrowseData.ListExperiments,'String');
ExpIndices=get(BrowseData.ListExperiments,'Value');
ListExp=ListExp(ExpIndices);
ListDevices=get(BrowseData.ListDevices,'String');
DeviceIndices=get(BrowseData.ListDevices,'Value');
ListDevices=ListDevices(DeviceIndices);
ListDataSeries=get(BrowseData.DataSeries,'String');
DataSeriesIndices=get(BrowseData.DataSeries,'Value');
ListDataSeries=ListDataSeries(DataSeriesIndices);
NbExp=0; % counter of the number of experiments set by the GUI browse_data
for iexp=1:numel(ListExp)
    if ~isempty(regexp(ListExp{iexp},'^\+/', 'once'))% if it is a folder
        for idevice=1:numel(ListDevices)
            if ~isempty(regexp(ListDevices{idevice},'^\+/', 'once'))% if it is a folder
                for isubdir=1:numel(ListDataSeries)
                    if ~isempty(regexp(ListDataSeries{isubdir},'^\+/', 'once'))% if it is a folder
                        lpath= fullfile(SourceDir,regexprep(ListExp{iexp},'^\+/',''),...
                            regexprep(ListDevices{idevice},'^\+/',''));
                        ldir= regexprep(ListDataSeries{isubdir},'^\+/','');
                        if exist(fullfile(lpath,ldir),'dir')
                            NbExp=NbExp+1;
                            ListPath{NbExp}=lpath;
                            ListSubdir{NbExp}=ldir;
                            ExpIndex{NbExp}=iexp;
                        end
                    end
                end
            end
        end
    end
end