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
ichoice=find(strcmp(strinput,menu_str),1);
if isempty(ichoice)%the input string does not exist in the menu
    ichoice= length(menu_str);
    menu_str=[menu_str(1:end-1);{strinput};menu_str(end)];
    set(handle,'String',menu_str)
end
set(handle,'Value',ichoice)
