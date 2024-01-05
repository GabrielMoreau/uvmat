% 'read_GUI':read a GUI and provide the data as a Matlab structure
%----------------------------------------------------------------------
% function struct=read_GUI(handle)
%
% OUTPUT:
% struct: matlab structure containing the information displayed in the GUI
% The content of a panel with tag 'tag' is displayed as a substructure struct.(tag) (recursive use of read_GUI)
% Output of a GUI element with tag 'tag':
%     -case 'checkbox','radiobutton','togglebutton': struct.(tag)=value
%     -case'edit': struct.(tag)=string,  
%         or, if the tag is in the form by 'num_tag',
%         struct.(tag)=str2double(string). If the result is empty the  'UserData' is taken as the default input.
%     -case 'listbox','popupmenu': struct.(tag)=selected string, or, if the tag is in the form by 'num_tag', struct.(tag)=str2double(string)
%     -case 'table': struct.(tag)=data of the table

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function struct=read_GUI(handle)
%------------------------------------------------------------------------
struct=[];%default
hchild=get(handle,'children');
hchild=flipdim(hchild,1);% reverse the order to respect the tab order in the GUI
for ichild=1:numel(hchild)
    if strcmp(get(hchild(ichild),'Visible'),'on')
        object_type=get(hchild(ichild),'Type');
        tag=get(hchild(ichild),'tag');
        switch object_type
            case 'uipanel'
                eval(['struct.' tag '=read_GUI(hchild(ichild));'])
            case 'uicontrol'
                object_style=get(hchild(ichild),'Style');
                check_input=1;%default
                index=0;
                switch object_style
                    case {'checkbox','radiobutton','togglebutton'}
                        input=get(hchild(ichild),'Value');
                    case 'edit'
                        separator=regexp(tag,'^num_','once');%look for the prefix 'num_'
                        if isempty(separator)
                            input=get(hchild(ichild),'String');
                        else  %transform into numeric if the edit box begins by the prefix 'num_'                                            
                            input=str2double(get(hchild(ichild),'String'));                        
                            tag=regexprep(tag,'^num_','');
                            % detect tag name ending by an index: then interpret the input as array(index)
                            r=regexp(tag,'_(?<index>\d+)$','names');% detect tag name ending by an index
                            if ~isempty(r)
                                tag=regexprep(tag,['_' r.index '$'],'');
                                index=str2double(r.index);
                            end
                            %deal with undefined input: retrieve the default value stored as UserData
                            if isnan(input)
                                input=get(hchild(ichild),'UserData');
                                set(hchild(ichild),'String',num2str(input))
                            end
                        end                        
                    case {'listbox','popupmenu'}
                        listinput=get(hchild(ichild),'String');
                        value=get(hchild(ichild),'Value');
                        if ~isempty(listinput)
                            if numel(value)==1% single selection
                                if ischar(listinput)
                                    input=listinput;
                                else
                                    input=listinput{value};
                                end
                            else % multiple selection
                                input=listinput(value);
                            end
                        else
                            check_input=0;
                        end
                        separator=regexp(tag,'^num_','once');
                        if ~isempty(separator)
                            input=str2double(input);% transform to numerical values if the uicontrol tag begins with 'num_'
                            tag=regexprep(tag,'^num_','');
                        end
                    otherwise
                        check_input=0;
                end
                if check_input && ~isempty(tag)% 
                    if index==0
                       struct.(tag)=input;
                    elseif ~isempty(input)
                       struct.(tag)(index)=input;
                    end
                end
            case 'uitable'
                struct.(tag)=get(hchild(ichild),'Data');
        end
    end
end
% read UserData if relevant
UserData=get(handle,'UserData');
if isstruct(UserData)
    List=fields(UserData);
    for ilist=1:numel(List)
        if isstruct(UserData.(List{ilist}))% look for edit box with the tag UserData.(List{ilist})
            heditbox=findobj(handle,'Tag',List{ilist},'Style','edit','Visible','on');
            if isequal(numel(heditbox),1)
                struct.(List{ilist})=UserData.(List{ilist});
            else% look for pushbutton with the tag UserData.(List{ilist})
                hpushbutton=findobj(handle,'Tag',List{ilist},'Style','pushbutton','Visible','on');
                if isequal(numel(hpushbutton),1)
                    struct.(List{ilist})=UserData.(List{ilist});
                end
            end
        end
    end
end
