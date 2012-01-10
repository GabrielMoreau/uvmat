% -----------------------------------------------------------------------
% --- read a GUI with handle 'handle' producing a structure 'struct'
function errormsg=fill_GUI(Param,handles)
%------------------------------------------------------------------------
errormsg='';
fields=fieldnames(Param);
for ifield=1:numel(fields)
    if isstruct(Param.(fields{ifield}))
        if isfield(handles,fields{ifield})
            set(handles.(fields{ifield}),'Visible','on')
            children=get(handles.(fields{ifield}),'children');
            for ichild=1:numel(children)
                hchild.(get(children(ichild),'tag'))=children(ichild);
            end
            errormsg=fill_GUI(Param.(fields{ifield}),hchild);
        end
    else
        hh=[];
        input_data=Param.(fields{ifield});
        if isfield(handles,fields{ifield})
            hh=handles.(fields{ifield});
            if strcmp(get(hh,'Type'),'uitable')
                set(hh,'Data',input_data)
                break
            end
        elseif isnumeric(input_data) && isfield(handles,['num_' fields{ifield}])
            hh=handles.(['num_' fields{ifield}]);
        end
        if ~isempty(hh)
            set(hh,'Visible','on')
            get(hh,'style')
            input_data
            switch get(hh,'style')
                case {'checkbox','radiobutton','togglebutton'}
                    if isnumeric(input_data)
                        set(hh,'Value',input_data)
                    end
                case 'edit'
                    if isnumeric(input_data)
                        input_data=num2str(input_data);
                    end
                    set(hh,'String',input_data)
                case{'Listbox','popupmenu'}
                    if isnumeric(input_data)
                        input_data=num2str(input_data);
                    end
                    menu=get(hh,'String');
                    iline=find(strcmp(input_data,menu));
                    if isempty(iline)
                        iline=numel(menu)+1;
                        set(hh,'String',[menu;{input_data}])
                    end
                    set(hh,'Value',iline)
            end
        end
    end
end
 