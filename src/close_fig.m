%'close_fig': function  activated when a figure is closed
%----------------------------------------------------------------
% function close_fig(ggg,eventdata,hparent,type)
% activated by the command:
%set(hObject,'DeleteFcn',{@close_fig,hparent,type})
% where hObject is the handle of the figure
%

function close_fig(ggg,eventdata,hparent,type)
if isequal(type,'zoom')
    delete(hparent)  % delete the rectangle showing the zoom graph in the parent fig
end