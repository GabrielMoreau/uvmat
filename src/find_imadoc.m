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
SubDirBase=regexprep(SubDir,'\..*','');%take the root part of SubDir, before the first dot '.'
XmlFileName=[fullfile(RootPath,SubDirBase) '.xml'];%new convention: xml at the level of the image folder
if ~exist(XmlFileName,'file')
    if strcmp(FileExt,'.nc')
        basexml=fullfile(RootPath,RootFile) ; % old convention: xml inside the image folder, case of civ files
    else
        basexml=fullfile(RootPath,SubDir,RootFile) ; % old convention: xml inside the image folder, case of images
    end
    XmlFileName=[basexml '.xml'];
    if ~exist(XmlFileName,'file')
        XmlFileName=[basexml '.civ']; % very old convention: .civ file
        if ~exist(XmlFileName,'file')
            XmlFileName='';
        end
    end
end