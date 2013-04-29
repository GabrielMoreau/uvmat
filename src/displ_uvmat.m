%'displ_uvmat': display a message using  msgbox_uvmat or on the log file in batch mode
%--------------------------------------------------------------------------
%  function displ_uvmat(title,display_str,Position)
%
function displ_uvmat(title,display_str,Position)
if isequal(Position,0)
    disp([title ': ' display_str])
else
    msgbox_uvmat(title,display_str,'',Position)
end
    