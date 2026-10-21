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
fields=fieldnames(Param);%list of fields in the input structure Param
%if isa(app,'matlab.ui.control.internal.model.ComponentModel')% case of panel sub-elements
if  isa(app, 'matlab.ui.container.Panel')
    hchildren=get(app,'children');
else
    ListElements=properties(app);
    hchildren=get(app.(ListElements{1}),'children');
end
ListTag=cell(numel(hchildren),1);
for ilist=1:numel(hchildren)
        ListTag{ilist}=get(hchildren(ilist),'Tag');%list of element tags in the app
end
% ListPanel=ListElements(CheckPanel);
% ListTag=ListTag(~CheckPanel)

% else
%     ListTag={};


%--------------------------------------------------------------------------------------
%----------------- loop on the elements of the input structure Param ------------------
%--------------------------------------------------------------------------------------
for ifield=1:numel(fields)% fields = names of the elements of the input structure
    if isstruct(Param.(fields{ifield}))% case of a input sub-structure
        %% case of a sub-structure
        % if a panel in the GUI has the name fields{ifield}, fill it with the sub-structure content
       % if isprop(app,fields{ifield})
       ObjIndex=find(strcmp(fields{ifield},ListTag), 1);
       if ~isempty(ObjIndex)
           set(hchildren(ObjIndex),'Visible','on');
        %    set(app.(fields{ifield}),'Visible','on')
            errormsg=fill_app(Param.(fields{ifield}),hchildren(ObjIndex));% recursively apply the function to the substructure
        end
    else
        %% case of an element
        input_data=Param.(fields{ifield});% input value correponding to the input field fields{ifield} 
        check_done=0;
        % detect GUI element with a name equal to the key name in the element of Param
       
        hh_index=find(strcmp(fields{ifield},ListTag));% the name fields{ifield} of the current input element is sought among the app Tags
        hh={};
        if ~isempty(hh_index)% a corresponding app Tag is found
            hh{1}=hchildren(hh_index); % handle of the corresponding  app Tag
%         elseif isprop(app,fields{ifield})
%             hh{1}=app.(fields{ifield});
        end
        if ~isempty(hh)% fill the app element found
            if strcmp(get(hh{1},'Type'),'uitable')% case of a table
                set(hh{1},'Visible','on')% make it visible
                if ischar(input_data)
                    input_data={input_data};% transform string to a single cell if needed
                end
                set(hh{1},'Data',input_data)% fill the app element with table input_data
                check_done=1;
            end
            % for numeric input element, detect GUI element(s) with the same tag name preceded by 'num_'
        elseif isnumeric(input_data)% numeric input
            if numel(input_data)>1 % deals with array displayed in multiple boxes labeled by an index
                hh=cell(numel(input_data),1);
                for ibox=1:numel(input_data)
                    hh_index=find(strcmp(['num_' fields{ifield} '_' num2str(ibox)],ListTag));% seerch app element with tag beginning by 'num_'
                    if ~isempty(hh_index)
                        hh{ibox}=hchildren(hh_index);
%                     elseif isprop(app,['num_' fields{ifield} '_' num2str(ibox)])
%                         hh{ibox}=app.(['num_' fields{ifield} '_' num2str(ibox)]);
                    end
                end
            else % single box (usual case)
                hh_index=find(strcmp(['num_' fields{ifield}],ListTag));
                if ~isempty(hh_index)
                    hh={hchildren(hh_index)};
%                 elseif isprop(app,['num_' fields{ifield}])
%                     hh{1}=app.(['num_' fields{ifield}]);
                end
            end
        end
        % fill the detected GUI element(s) and make them visible
        for ibox=1:numel(hh)
            % finalise the update of GUI uicontrol filled by the input element
            if ~isempty(hh{ibox})&& ~check_done && ~isequal(hh{ibox},0)
                set(hh{ibox},'Visible','on')% make the filled GUI element visible
                if isfield(get(hh{ibox}),'Type')
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
                        case {'uilistbox','uidropdown'}
                            if isnumeric(input_data)
                                input_data=num2str(input_data,4);
                            end
                            menu=get(hh{ibox},'Items');
                            if ischar(input_data)
                                input_data={input_data};
                            end
                            values=zeros(size(input_data));
                            for idata=1:numel(input_data)
                                iline=find(strcmp(input_data{idata},menu));
                                if ~isempty(iline)
%                                     values(idata)=1;
%                                     menu=[input_data(idata);menu];
%                                 else
                                    values(idata)=iline(1);
                                    set(hh{ibox},'Value',menu{iline(1)})
                                end
                            end
 %                           set(hh{ibox},'Items',menu)
%                             set(hh{ibox},'Value',menu{values(idata)})
%                         otherwise
%                             disp([get(hh{ibox},'Type') ' not handled'])
                    end
                end
            end
        end
    end
end
