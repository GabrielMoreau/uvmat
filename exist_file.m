% CheckExist=exist_file(FileName): check the existence of the input file, or  web source OpenDap
function CheckExist=exist_file(FileName)
CheckExist=~isempty(regexp(FileName,'(^http://)|(^https://)', 'once'))|| exist(FileName,'file')==2;