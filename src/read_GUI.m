% -----------------------------------------------------------------------
% --- read a GUI with handle 'handle' producing a structure 'struct'
function struct=read_GUI(handle)
%------------------------------------------------------------------------
struct=[];%default
hchild=get(handle,'children');
hchild=flipdim(hchild,1);% reverse the order to respect the tab order in the GUI
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
                index=0;
                switch object_style
                    case {'checkbox','radiobutton','togglebutton'}
                        input=get(hchild(ichild),'Value');
                    case 'edit'
                        separator=regexp(tag,'^num_','once');%look for the prefix 'num_'
                        if isempty(separator)
                            input=get(hchild(ichild),'String');
                        else  %transform into numeric if the edit box begins by the prefix 'num_'                                            
                            input=str2double(get(hchild(ichild),'String'));                        
                            tag=regexprep(tag,'^num_','');
                            % detect tag name ending by an index: then interpret the input as array(index)
                            r=regexp(tag,'_(?<index>\d+)$','names');% detect tag name ending by an index
                            if ~isempty(r)
                                tag=regexprep(tag,['_' r.index '$'],'');
                                index=str2double(r.index);
                            end
                            %deal with undefined input: retrieve the default value stored as UserData
                            if isnan(input)
                                input=get(hchild(ichild),'UserData');
                                set(hchild(ichild),'String',num2str(input))
                            end
                        end                        
                    case{'listbox','popupmenu'}
                        listinput=get(hchild(ichild),'String');
                        value=get(hchild(ichild),'Value');
                        if ~isempty(listinput)
                            input=listinput{value};
                        else
                            check_input=0;
                        end
                        separator=regexp(tag,'^num_','once');
                        if ~isempty(separator)
                            input=str2double(input);% transform to numerical values if the uicontrol tag begins with 'num_'
                            tag=regexprep(tag,'^num_','');
                        end
                    otherwise
                        check_input=0;
                end
                if check_input
                    if index==0
                       struct.(tag)=input;
                    else
                       struct.(tag)(index)=input;
                    end
                end
            case 'uitable'
                struct.(tag)=get(hchild(ichild),'Data');
        end
    end
end
