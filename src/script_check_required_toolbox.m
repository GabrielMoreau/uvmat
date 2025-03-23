%% check list of fcts in main folder
[~,~,~,list_fct]=check_files;
for ilist=1:numel(list_fct)
    [~, pList] = matlab.codetools.requiredFilesAndProducts(list_fct{ilist});
    disp([list_fct{ilist} ': ' {pList.Name}])
end

str=which('UVMAT');
path_uvmat=fileparts(str)

%% check list of fcts in transform_field
dir_fct=fullfile(path_uvmat,'transform_field');
list_fct=dir(dir_fct);
for ilist=1:numel(list_fct)
    if ~isempty(regexp(list_fct(ilist).name,'.m$', 'once'))
    [~, pList] = matlab.codetools.requiredFilesAndProducts(fullfile(dir_fct,list_fct(ilist).name));
    disp([list_fct(ilist).name ': ' {pList.Name}])
    end
end

%% check list of fcts in series
dir_fct=fullfile(path_uvmat,'series');
list_fct=dir(dir_fct);
for ilist=1:numel(list_fct)
    if ~isempty(regexp(list_fct(ilist).name,'.m$', 'once'))
    [~, pList] = matlab.codetools.requiredFilesAndProducts(fullfile(dir_fct,list_fct(ilist).name));
    disp([list_fct(ilist).name ': ' {pList.Name}])
    end
end

'END SCRIPT'