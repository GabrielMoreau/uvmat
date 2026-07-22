%'fill_GUI': fill a GUI with a set of parameters from a Matlab structure 
% -----------------------------------------------------------------------
% function errormsg=fill_app(Param,app)
% OUTPUT:
% errormsg: error message, ='' by default
%
% INPUT:
% Param: matlab structure containing the information to display in the GUI
% GUI_handle: handle of the GUI to be filled 
%
% see also the reverse function read_GUI.m

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

function errormsg=fill_app(Param,app)
%------------------------------------------------------------------------
errormsg='';
if ~isstruct(Param)
    errormsg='first input parameter of fill_app must be a structure';
    return
end
fields=fieldnames(Param);%list of fields in Param
if isa(app,'matlab.ui.control.internal.model.ComponentModel')% case of panel sub-elements
    ListTag=cell(numel(app),1);
    for ilist=1:numel(ListTag)
        ListTag{ilist}=app(ilist).Tag;
    end
else
    ListTag={};
end

%--------------------------------------------------------------------------------------
%----------------- loop on the elements of the input structure Param ------------------
%--------------------------------------------------------------------------------------
for ifield=1:numel(fields)
    if isstruct(Param.(fields{ifield}))% case of a sub-structure
        %% case of a sub-structure
        % if a panel in the GUI has the tag fields{ifield}, fill it with the sub-structure content
        if isprop(app,fields{ifield})
            set(app.(fields{ifield}),'Visible','on')
            errormsg=fill_app(Param.(fields{ifield}),get(app.(fields{ifield}),'children'));% recursively apply the function to the substructure
        end
    else
        %% case of an element
        input_data=Param.(fields{ifield});
        check_done=0;
        % detect GUI element with a tag name equal to the key name in the element of Param
        hh={};
        hh_index=find(strcmp(fields{ifield},ListTag));
        if ~isempty(hh_index)
            hh{1}=app(hh_index);
        elseif isprop(app,fields{ifield})
            hh{1}=app.(fields{ifield});
        end
        if ~isempty(hh)
            if strcmp(get(hh{1},'Type'),'uitable')
                % case of a table
                set(hh{1},'Visible','on')
                if ischar(input_data)
                    input_data={input_data};% transform string to a single cell if needed
                end
                set(hh{1},'Data',input_data)
                check_done=1;
            end
            % for numeric input element, detect GUI element(s) with the same tag name preceded by 'num_'
        elseif isnumeric(input_data)
            if numel(input_data)>1 % deals with array displayed in multiple boxes labeled by an index
                hh=cell(numel(input_data),1);
                for ibox=1:numel(input_data)
                    hh_index=find(strcmp(['num_' fields{ifield} '_' num2str(ibox)],ListTag));
                    if ~isempty(hh_index)
                        hh{ibox}=app(hh_index);
                    elseif isprop(app,['num_' fields{ifield} '_' num2str(ibox)])
                        hh{ibox}=app.(['num_' fields{ifield} '_' num2str(ibox)]);
                    end
                end
            else % single box (usual case)
                hh_index=find(strcmp(['num_' fields{ifield}],ListTag));
                if ~isempty(hh_index)
                    hh{1}=app(hh_index);
                elseif isprop(app,['num_' fields{ifield}])
                    hh{1}=app.(['num_' fields{ifield}]);
                end
            end
        end
        % fill the detected GUI element(s) and make them visible
        for ibox=1:numel(hh)
            % finalise the update of GUI uicontrol filled by the input element
            if ~isempty(hh{ibox})&& ~check_done && ~isequal(hh{ibox},0)
                set(hh{ibox},'Visible','on')% make the filled GUI element visible
                if isfield(get(hh{ibox}),'Type')
                    % get(hh{ibox},'Type')
                    switch get(hh{ibox},'Type')
                        case {'uicheckbox','uiradiobutton','uitogglebutton'}
                            if isnumeric(input_data)||islogical(input_data)
                                set(hh{ibox},'Value',input_data(ibox))
                            end
                        case 'uieditfield'
                            input_string='';
                            if isnumeric(input_data)
                                if numel(input_data)>0
                                    if floor(input_data(ibox))==input_data(ibox)
                                        input_string=num2str(input_data(ibox)); % case of integers, write in full
                                    else
                                        input_string=num2str(input_data(ibox),4);%case of floating point:nbre_digit=4;
                                    end
                                end
                            elseif ischar(input_data)
                                input_string=input_data;
                            end
                            set(hh{ibox},'Value',input_string)
                        case {'listbox','popupmenu'}
                            if isnumeric(input_data)
                                input_data=num2str(input_data,4);
                            end
                            menu=get(hh{ibox},'String');
                            if ischar(input_data)
                                input_data={input_data};
                            end
                            values=zeros(size(input_data));
                            for idata=1:numel(input_data)
                                iline=find(strcmp(input_data{idata},menu));
                                if isempty(iline)
                                    values(idata)=1;
                                    menu=[input_data(idata);menu];
                                else
                                    values(idata)=iline(1);
                                end
                            end
                            set(hh{ibox},'String',menu)
                            set(hh{ibox},'Value',values)
                    end
                end
            end
        end
    end
end
