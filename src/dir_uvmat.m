function [ ListFiles ] = dir_uvmat( DirName)
if regexp(DirName,'^http://')
    catalog=[DirName,'/catalog.xml'];
    str=urlread(catalog);
    ListFiles=(regexp(str,'xlink:title="(?<name>[^"]+)"','names'))';
    NumDir=numel(ListFiles);
    ListFiles=[ListFiles;(regexp(str,'dataset name="(?<name>[^"]+)"','names'))'];
    for ilist=1:numel(ListFiles)
        ListFiles(ilist).date=0;
        ListFiles(ilist).bytes=0;
        ListFiles(ilist).isdir=false;
        ListFiles(ilist).datenum=0;
    end
    for ilist=1:NumDir
        ListFiles(ilist).isdir=true;
    end
else
    ListFiles=dir(DirName);
end

