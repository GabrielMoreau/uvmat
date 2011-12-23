% -----------------------------------------------------------------------
% --- read a GUI with handle 'handle' producing a structure 'struct'
function struct=read_GUI(handle)
%------------------------------------------------------------------------
struct=[];%default
hchild=get(handle,'children');
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
                switch object_style
                    case {'checkbox','pushbutton','radiobutton','togglebutton'}
                        input=get(hchild(ichild),'Value');
                    case 'edit'
                        separator=regexp(tag,'_');
                        if isempty(separator)
                            input=get(hchild(ichild),'String');
                        else
                            switch(tag(1:separator))
                                case 'num_'
                                    input=str2double(get(hchild(ichild),'String'));
                                    tag=tag(separator+1:end);
                                    %deal with undefined input: retrieve the default value stored as UserData
                                    if isnan(input)
                                        input=get(hchild(ichild),'UserData');
                                        set(hchild(ichild),'String',num2str(input))
                                    end
                                case 'txt_'
                                    input=get(hchild(ichild),'String');
                                    tag=tag(separator+1:end);
                                otherwise
                                    input=get(hchild(ichild),'String');
                            end
                        end

                        %                         key=tag(7:end);
                    case{'Listbox','popupmenu'}
                        listinput=get(hchild(ichild),'String');
                        value=get(hchild(ichild),'Value');
                        if ~isempty(listinput)
                        input=listinput(value);
                        end
                        separator=regexp(tag,'_');
                        if strcmp(tag(1:separator),'num_')
                            input=str2double(input);% transform to numerical values if the uicontrol tag begins with 'num_'
                            tag=tag(separator+1:end);
                        end
                    otherwise
                        check_input=0;
                end
                if check_input
                    struct.(tag)=input;
                  %  eval(['struct.' tag '=input;'])
                end
            case 'uitable'
                 struct.(tag)=get(hchild(ichild),'Data');
        end
    end
end
