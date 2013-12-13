% 'find_imadoc': find the ImaDoc xml file associated with a given input file
% take into account the old conventions
%-----------------------------------------------------------------------
% function XmlFileName=find_imadoc(RootPath,SubDir,RootFile,FileExt)
%
% OUTPUT:
% XmlFileName: name of the xml file, ='' if none is found
%
% INPUT:
% RootPath,SubDir,RootFile,FileExt, as given from the input file name by fileparts_uvmat
function XmlFileName=find_imadoc(RootPath,SubDir,RootFile,FileExt)
SubDirBase=SubDir;
XmlFileName=fullfile(RootPath,[SubDir '.xml']);
if ~exist (XmlFileName,'file')
    dotchar=regexp(SubDir,'\.');
    for idot=1:numel(dotchar)
        XmlFileName=fullfile(RootPath,[SubDir(1:dotchar(end-idot+1)-1) '.xml']);
        if exist(XmlFileName,'file')
            SubDirBase=fullfile(RootPath,SubDir(1:dotchar(end-idot+1)-1));
            break
        end
    end   
end
% SubDirBase=regexprep(SubDir,'\..*','');%take the root part of SubDir, before the first dot '.'
% XmlFileName=[fullfile(RootPath,SubDirBase) '.xml'];%new convention: xml at the level of the image folder
if ~exist(XmlFileName,'file')
    XmlFileName=[fullfile(RootPath,SubDirBase,RootFile) '.xml']; % old convention: xml inside the image folder, case of images or new civ files
    if ~exist(XmlFileName,'file')
        XmlFileName=[fullfile(RootPath,SubDirBase,RootFile) '.civ']; % very old convention: .civ file
        if ~exist(XmlFileName,'file') && strcmp(FileExt,'.nc')
            XmlFileName=[fullfile(RootPath,RootFile) '.xml'] ; % old convention: xml inside the image folder, old civ file opened
            if ~exist(XmlFileName,'file')
                XmlFileName=[fullfile(RootPath,RootFile) '.civ']; % very old convention: .civ file
            end
        end
    end
end
if ~exist(XmlFileName,'file')
    XmlFileName='';
end