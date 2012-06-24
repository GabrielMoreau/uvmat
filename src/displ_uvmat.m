function displ_uvmat(title,display_str,Position)
if isequal(Position,0)
    display([title ': ' display_str])
else
    msgbox_uvmat(title,display_str,'',Position)
end
    