% --------------------------------------------------------------------
% --- read a GUI with handle 'handle' producing a structure 'struct'
function struct=read_GUI(handle)
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
                    case 'edit'
                        separator=regexp(tag,'_');
                        if isempty(separator)
                            input=get(hchild(ichild),'Value');
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
                    case 'checkbox'
                        input=get(hchild(ichild),'Value');
                        %                         key=tag(7:end);
                    otherwise
                        check_input=0;
                end
                if check_input
                    struct.(tag)=input;
                  %  eval(['struct.' tag '=input;'])
                end
        end
    end
end
