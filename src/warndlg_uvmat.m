%'warndlg_uvmat': display warning message (error, warning, confirmation) in a given figure 
%---------------------------------------------------------------------
% hwarn=warndlg_uvmat(warntext,title) 
%---------------------------------------------------------------------
% OUTPUT:
% hwarn: string representing the file name (including path)
%
% INPUT:
% warntext: text to display
% title:  string indicating the type of message box:
%          title= 'ERROR', 'WARNING', 'CONFIRMATION' . 

function hwarn=warndlg_uvmat(warntext,title)
hwarn=msgbox_uvmat(title,warntext);
%if isequal(title,'ERROR')||isequal(title,'WARNING')
    %delete(hwarn)
%end

