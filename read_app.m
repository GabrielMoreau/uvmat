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
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function Data=read_app(AppData)
%------------------------------------------------------------------------
Data=[];%default
ListProperties=properties(AppData);
for ilist=1:numel(ListProperties)
    UIType=get(AppData.(ListProperties{ilist}),'Type');
    if ~isempty(UIType) && strcmp(AppData.(ListProperties{ilist}).Visible,'on')% scan the visible GUI elements
        UITag=get(AppData.(ListProperties{ilist}),'Tag');
        if (strcmp(UIType,'uieditfield')||strcmp(UIType,'uinumericeditfield')||strcmp(UIType,'uicheckbox'))...
                && ~isempty(UITag)
            UIValue=get(AppData.(ListProperties{ilist}),'Value');% input string
             num_index=[];
            if ~isempty(regexp(UITag,'^num_', 'once'))% numerical input
                UIValue=str2double(UIValue);
                UITag=regexprep(UITag,'^num_','');%remove the prefix 'num_'
                % detect tag name ending by an index: then interpret the input as array(index)      
                r=regexp(UITag,'_(?<index>\d+)$','names');% detect tag name ending by an index
                if ~isempty(r)
                    UITag=regexprep(UITag,['_' r.index '$'],'');
                    num_index=str2double(r.index);
                end
            end
            parent_object=get(AppData.(ListProperties{ilist}),'Parent');
            if strcmp(get( parent_object,'Type'),'uipanel')
                if strcmp(get(parent_object,'Visible'),'on')
                    PanelTag=get(parent_object,'Tag');
                    if isempty(num_index)
                        Data.(PanelTag).(UITag)=UIValue;
                    else
                        Data.(PanelTag).(UITag)(num_index)=UIValue;
                    end
                end
            else
                if isempty(num_index)
                    Data.(UITag)=UIValue;
                else
                    Data.(UITag)(num_index)=UIValue;
                end
            end
        end
    end
end

