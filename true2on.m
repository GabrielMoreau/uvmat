%'true2on': transform true/false to 'on'/'off'
%--------------------------------------------
function str=true2on(value)
if value
    str='on';
else
    str='off';
end
