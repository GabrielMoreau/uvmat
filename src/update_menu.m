%'update_menu': find an input string in a menu, add it to the menu at the penultimate position if it does not exist
%-----------------------------------------------
% function menu_str=update_menu(handle,strinput)
%
% OUTPUT:
% menu_str: new menu; cell of strings
%
% INPUT:
% handle: handle of the menu to modify (listbox uicontrol)
% strinput: char string to detect or add in the menu

function menu_str=update_menu(handle,strinput)
menu_str=get(handle,'String');
nbmenu=length(menu_str);
ichoice=find(strcmp(strinput,menu_str),1);
if isempty(ichoice)%the input string does not exist in the menu
    menu_str{nbmenu+1}=menu_str{nbmenu};%shift  the last item ('more...')
    menu_str{nbmenu}=strinput;
    set(handle,'String',menu_str)
    ichoice=nbmenu;
end
set(handle,'Value',ichoice)
