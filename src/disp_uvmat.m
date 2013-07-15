%'disp_uvmat': display a message using  msgbox_uvmat or on the log file in batch mode
%--------------------------------------------------------------------------
%
%  displ_uvmat(title,display_str,checkrun)
%
%  INPUT:
%  title: ='ERROR' or 'WARNING', as requested as input of  msgbox_uvmat.m
%  display_str: message string to display
%  checkrun: =1: run mode, use of msgbox_uvmat window
%  checkrun: =0: batch mode: text display on log file

function disp_uvmat(title,display_str,checkrun)
if checkrun
    msgbox_uvmat(title,display_str,'')
else
    disp([title ': ' display_str])
end
    