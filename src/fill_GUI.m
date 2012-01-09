% -----------------------------------------------------------------------
% --- read a GUI with handle 'handle' producing a structure 'struct'
function errormsg=fill_GUI(Param,handles)
%------------------------------------------------------------------------
errormsg='';
fields=fieldnames(Param);
for ifield=1:numel(fields)
    if isstruct(Param.(fields{ifield}))
        fields{ifield}
        if isfield(handles,fields{ifield})
        errormsg=fill_GUI(Param.(fields{ifield}),get(handles.(fields{ifield}),'children'));
        end
    else
        fields{ifield}
        num2str(Param.(fields{ifield}))
        if isnumeric(Param.(fields{ifield}))
            if isfield(handles,['num_' fields{ifield}])
            set(handles.(['num_' fields{ifield}]),'String',num2str(Param.(fields{ifield})))
            end
        else
            if isfield(handles,fields{ifield})
            set(handles.(fields{ifield}),'String',num2str(Param.(fields{ifield})))
            end
        end
    end
end
 