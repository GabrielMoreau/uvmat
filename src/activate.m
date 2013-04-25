% 'activate': emulate the mouse selection of a GUI element, for demo
%-----------------------------------------------------------------------
% function activate(FigTag,PanelTag,ObjectTag,Value)
%
% INPUT:
% FigTag: tag name of the GUI figure (e.g; 'uvmat')
% PanelTag: tag name of a uipanel containing the element, =[] if no panel
% ObjectTag: tag name of the element
% Value: value set to the element, for instance string to select on a menu

function activate(FigTag,PanelTag,ObjectTag,Value)
hFig=findobj(allchild(0),'tag',FigTag);
set(0,'CurrentFigure',hFig)
handles=guidata(hFig);
unit_0=get(0,'Unit');
unit=get(hFig,'Unit');
set(hFig,'Unit',unit_0)
FramePos=get(hFig,'Position');
set(hFig,'Unit',unit)
if isempty(PanelTag)
    hPanel=hFig;
    hObject=handles.(ObjectTag);
else
    hPanel=findobj(hFig,'tag',PanelTag);
    unit=get(hPanel,'Unit');
    set(hPanel,'Unit',unit_0)
    FramePos=FramePos+get(hPanel,'Position');
    set(hPanel,'Unit',unit)
end
hObject=handles.(ObjectTag);
if isempty(hObject)
    disp(['Object' ObjectTag ' not found'])
else
    if exist('Value','var')
        if isempty(PanelTag)
            Param.(ObjectTag)=Value;
        else
            Param.(PanelTag).(ObjectTag)=Value;
        end
        errormsg=fill_GUI(Param,hFig);
    end
    unit=get(hObject,'Unit');
    set(hObject,'Unit',unit_0);
    Pos=get(hObject,'Position');
    set(hObject,'Unit',unit)
    set(0,'PointerLocation',FramePos(1:2)+Pos(1:2))
    BackgroundColor=get(hObject,'BackgroundColor');
    set(hObject,'BackgroundColor',[1 1 0])
    for ipos=1:10
        set(0,'PointerLocation',FramePos(1:2)+Pos(1:2)+0.5*(ipos/10)*Pos(3:4))
        pause(0.2)
    end
    feval(FigTag,[ObjectTag '_Callback'],hObject,[],handles);
    set(hObject,'BackgroundColor',BackgroundColor)
end
