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
        if isfield(handles,fields{ifield})
            hh=handles.(fields{ifield});
            if strcmp(get(hh,'Type'),'uitable')
                set(hh,'Data',input)
                break
            end
        elseif isnumeric(input) && isfield(handles,['num_' fields{ifield}])
            hh=handles.(['num_' fields{ifield}]);
        end
        if ~isempty(hh)
            set(hh,'Visible','on')
            switch get(hh,'style')
                case {'checkbox','pushbutton','radiobutton','togglebutton'}
                    if isnumeric(input)
                        set(hh,'Value',input)
                    end
                case 'edit'
                    if isnumeric(input)
                        input=num2str(input);
                    end
                    set(hh,'String',input)
                case{'Listbox','popupmenu'}
                    if isnumeric(input)
                        input=num2str(input);
                    end
                    menu=get(hh,'String');
                    iline=find(strcmp(input,menu));
                    if isempty(iline)
                        iline=numel(menu)+1;
                        set(hh,'String',[menu;{input}])
                    end
                    set(hh,'Value',iline)
            end
        end
    end
end
 