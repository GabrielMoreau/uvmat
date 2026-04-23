% check if a particular field 'field' has value 'value' in a structure ss
%used as cellfun in a structure cell: cellfun(@(x) check_field(x,field,value),ss)
function check = check_field(ss,field,value)
check=false;
if isfield(ss,field) && isequal(ss.(field),value)
    check=true;
end
