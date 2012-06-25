%'fill_GUI': fill a GUI with handles 'handles' from input data Param 
% -----------------------------------------------------------------------
function errormsg=fill_GUI(Param,handles)
%------------------------------------------------------------------------
errormsg='';
fields=fieldnames(Param);%list of fields in Param
% loop on the elements of the input structure Param
for ifield=1:numel(fields)
    if isstruct(Param.(fields{ifield}))% case of sa sub-structure
        if isfield(handles,fields{ifield})
            set(handles.(fields{ifield}),'Visible','on')
            children=get(handles.(fields{ifield}),'children');
            for ichild=1:numel(children)
                hchild.(get(children(ichild),'tag'))=children(ichild);
            end
            errormsg=fill_GUI(Param.(fields{ifield}),hchild);% apply the function to the substructure
        end
    else
        hh=[];
        input_data=Param.(fields{ifield})
        check_done=0;
        if isfield(handles,fields{ifield})
            hh=handles.(fields{ifield})
            if strcmp(get(hh,'Type'),'uitable')
                set(hh,'Visible','on')
                if ischar(input_data)
                    input_data={input_data};% transform string to a single cell if needed
                end
                set(hh,'Data',input_data)
                check_done=1;
            end
        elseif isnumeric(input_data) && isfield(handles,['num_' fields{ifield}])
            hh=handles.(['num_' fields{ifield}]);
        end
        if ~isempty(hh)&& ~check_done
            set(hh,'Visible','on')
%             input_data
            switch get(hh,'Style')
                case {'checkbox','radiobutton','togglebutton'}
                    if isnumeric(input_data)
                        set(hh,'Value',input_data)
                    end
                case 'edit'
                    if isnumeric(input_data)
                        input_data=num2str(input_data);
                    end
                    set(hh,'String',input_data)
                case{'listbox','popupmenu'}
                    if isnumeric(input_data)
                        input_data=num2str(input_data);
                    end
                    menu=get(hh,'String');
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
                    set(hh,'String',menu)
                    set(hh,'Value',values)
            end
        end
    end
end
 