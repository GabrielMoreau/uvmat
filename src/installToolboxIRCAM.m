function installToolbox
% configure MATLAB paths for the Telops Toolbox.
%   installToolbox
%
%   Drop this file into MATLAB command line window. It will configure the 
%   required paths to run with the Telops Toolbox.

% moveright Telops 2009
% $Revision: 9106 $
% $Author: ssavary $
% $LastChangedDate: 2014-11-03 14:16:48 -0500 (lun., 03 nov. 2014) $
if ~exist('readIRCam.p','file')
    if ~exist('Library_IRCAM','dir')
        unzip('Library_IRCAM.zip')
        disp('Library_IRCAM created')
    end
    root = fileparts(mfilename('fullpath'));
    
    D = [{root}; extractSubTree(root)];
    
    v2007_exceptions = {'GUILayout'};
    exceptions = {'Documentation', 'ReleasePackages'};
    
    disp('installToolbox: Installing Toolbox...')
    disp('installToolbox: Adding directories to the MATLAB path:')
    
    V = ver('matlab');
    for ii=1:length(D)
        if ~isempty(V) && (str2double(V.Version(1)) == 7 && str2double(V.Version(3:end)) < 10) && ...
                any(arrayfun(@(x)~isempty(strfind(D{ii},x{1})), v2007_exceptions)) || ...
                any(arrayfun(@(x)~isempty(strfind(D{ii},x{1})), exceptions)) || ...
                any(D{ii} == '+')
        else
            disp(['path ' D{ii} ' added'])
            addpath(D{ii})
        end
    end
    
    disp('installToolbox: Installation complete.')
end


function D = extractSubTree(root)
% Recursively build the list of subdirectories under 'root'.
%   extractSubTree
%

DD = dir(root);

idx = find([DD.isdir]);
D = [];
for ii=idx
    if  strncmp(DD(ii).name,'.',1)==0 && isempty(strfind(DD(ii).name,'@')) &&  isempty(strfind(DD(ii).name,'private'))
        % skip '.', '..', and invisible folders
        subdir = fullfile(root, DD(ii).name);
        D = [D; {subdir}; extractSubTree(subdir)]; %#ok<AGROW>
    end
end