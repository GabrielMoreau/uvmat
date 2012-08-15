%'fill_GUI': fill a GUI with a set of parameters from a Matlab structure 
% -----------------------------------------------------------------------
% function errormsg=fill_GUI(Param,handles)
% OUPUT:
% errormsg: error message, ='' by default
%
% INPUT:
% Param: matlab structure containing the information to display in the GUI
% handles: Matlab structure containing the handles of the GUI elements
%
% see also the reverse function read_GUI.m
%
function errormsg=fill_GUI(Param,handles)
%------------------------------------------------------------------------
errormsg='';
fields=fieldnames(Param);%list of fields in Param
% loop on the elements of the input structure Param
for ifield=1:numel(fields)
    % case of a sub-structure --> fill a panel
    if isstruct(Param.(fields{ifield}))% case of a sub-structure
        if isfield(handles,fields{ifield})
            set(handles.(fields{ifield}),'Visible','on')
            children=get(handles.(fields{ifield}),'children');
            for ichild=1:numel(children)
                hchild.(get(children(ichild),'tag'))=children(ichild);
            end
            errormsg=fill_GUI(Param.(fields{ifield}),hchild);% apply the function to the substructure
        end
    % case of an element
    else
        hh=[];
        input_data=Param.(fields{ifield});
%                     display(fields{ifield})
%                     display(input_data)
        check_done=0;
        if isfield(handles,fields{ifield})
            hh=handles.(fields{ifield});
            if strcmp(get(hh,'Type'),'uitable')
                set(hh,'Visible','on')
                if ischar(input_data)
                    input_data={input_data};% transform string to a single cell if needed
                end
                set(hh,'Data',input_data)
                check_done=1;
            end
        elseif isnumeric(input_data) 
            if numel(input_data)>1 
                %deals with array displayed in multiple boxes labeled by an index
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
        if ~isempty(hh(ibox))&& ~check_done
            set(hh(ibox),'Visible','on')
%             input_data
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
 