%'fill_GUI': fill a GUI with a set of parameters from a Matlab structure 
% -----------------------------------------------------------------------
% function errormsg=fill_GUI(Param,GUI_handle)
% OUPUT:
% errormsg: error message, ='' by default
%
% INPUT:
% Param: matlab structure containing the information to display in the GUI
% GUI_handle: handle of the GUI to be filled 
%
% see also the reverse function read_GUI.m
%
function errormsg=fill_GUI(Param,GUI_handle)
%------------------------------------------------------------------------
errormsg='';
if ~isstruct(Param)
    errormsg='first input parmaeter of fill_GUI must be a structure';
    return
end
children=get(GUI_handle,'children');
handles=[];
for ichild=1:numel(children)
    handles.(get(children(ichild),'tag'))=children(ichild);
end
UserData=get(GUI_handle,'UserData');
fields=fieldnames(Param);%list of fields in Param

%--------------------------------------------------------------------------------------
%----------------- loop on the elements of the input structure Param ------------------
%--------------------------------------------------------------------------------------
for ifield=1:numel(fields)
    if isstruct(Param.(fields{ifield}))% case of a sub-structure
    %% case of a sub-structure --> fill a panel
        if isfield(handles,fields{ifield})
            set(handles.(fields{ifield}),'Visible','on')
            errormsg=fill_GUI(Param.(fields{ifield}),handles.(fields{ifield}));% recursively apply the function to the substructure
        elseif isfield(UserData,fields{ifield})&& isfield(handles,fields{ifield})&&isfield(Param.(fields{ifield}),'Name')
            UserData.(fields{ifield})=Param.(fields{ifield});
            set(handles.(fields{ifield}),'String',Param.(fields{ifield}).Name)
        end
    else
    %% case of an element
        hh=[];
        input_data=Param.(fields{ifield});
        check_done=0;
        if isfield(handles,fields{ifield})
        % a GUI element has a tag name equal to the key name in the element of Param
            hh=handles.(fields{ifield});
            if strcmp(get(hh,'Type'),'uitable')
            % case of a table
                set(hh,'Visible','on')
                if ischar(input_data)
                    input_data={input_data};% transform string to a single cell if needed
                end
                set(hh,'Data',input_data)
                check_done=1;
            end
        elseif isnumeric(input_data)
        % for numeric input element, look for a GUI element with the same tag name preceded by 'num_'
            if numel(input_data)>1 % deals with array displayed in multiple boxes labeled by an index
                for ibox=1:numel(input_data)
                    if isfield(handles,['num_' fields{ifield} '_' num2str(ibox)])
                        hh(ibox)=handles.(['num_' fields{ifield} '_' num2str(ibox)]);
                    end
                end
            else % single box (usual case)
                if isfield(handles,['num_' fields{ifield}])
                    hh=handles.(['num_' fields{ifield}]);
                end
            end
        end
        for ibox=1:numel(hh)
        % finalise the update of GUI uicontrol filled by the input element
            if ~isempty(hh(ibox))&& ~check_done
                set(hh(ibox),'Visible','on')% make the filled GUI element visible
                if isfield(get(hh(ibox)),'Style')
                    switch get(hh(ibox),'Style')
                        case {'checkbox','radiobutton','togglebutton'}
                            if isnumeric(input_data)
                                set(hh(ibox),'Value',input_data(ibox))
                            end
                        case 'edit'
                            input_string='';
                            if isnumeric(input_data)
                                if numel(input_data)>0
                                    input_string=num2str(input_data(ibox));
                                end
                            else
                                input_string=input_data;
                            end
                            set(hh(ibox),'String',input_string)
                        case{'listbox','popupmenu'}
                            if isnumeric(input_data)
                                input_data=num2str(input_data);
                            end
                            menu=get(hh(ibox),'String');
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
                            set(hh(ibox),'String',menu)
                            set(hh(ibox),'Value',values)
                    end
                end
            end
        end
    end
end
