%'script_check_required_toolbox': checks the Matlab toolboxes required for
%each function of the package UVMAT

%% check list of fcts in main folder
disp('%%%%%%%%%%%% fcts in the master folder UVMAT %%%%%%%%%%%%')
[~,~,~,list_fct]=check_files;
for ilist=1:numel(list_fct)
    [~, pList] = matlab.codetools.requiredFilesAndProducts(list_fct{ilist});
    Name_str='';
    for iname=1:numel(pList)
        Name_str=[Name_str ' ' pList(iname).Name];
    end
    disp([list_fct{ilist} ': ' Name_str])
end

str=which('UVMAT');
path_uvmat=fileparts(str);

%% check list of fcts in transform_field
disp('%%%%%%%%%%%% fcts in UVMAT/transform_field %%%%%%%%%%%%')
dir_fct=fullfile(path_uvmat,'transform_field');
list_fct=dir(dir_fct);
for ilist=1:numel(list_fct)
    if ~isempty(regexp(list_fct(ilist).name,'.m$', 'once'))
        [~, pList] = matlab.codetools.requiredFilesAndProducts(fullfile(dir_fct,list_fct(ilist).name));
        Name_str='';
        for iname=1:numel(pList)
            Name_str=[Name_str ' ' pList(iname).Name];
        end
        disp([list_fct(ilist).name ': ' Name_str])
    end
end

%% check list of fcts in series
disp('%%%%%%%%%%%% fcts in UVMAT/series %%%%%%%%%%%%')
dir_fct=fullfile(path_uvmat,'series');
list_fct=dir(dir_fct);
for ilist=1:numel(list_fct)
    if ~isempty(regexp(list_fct(ilist).name,'.m$', 'once'))
        [~, pList] = matlab.codetools.requiredFilesAndProducts(fullfile(dir_fct,list_fct(ilist).name));
        Name_str='';
        for iname=1:numel(pList)
            Name_str=[Name_str ' ' pList(iname).Name];
        end
        disp([list_fct(ilist).name ':' Name_str])
    end
end

'END SCRIPT'