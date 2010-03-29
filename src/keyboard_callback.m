%'keyboard_callback:' function activated when a key is pressed on the keyboard
%-----------------------------------
function keyboard_callback(hObject,eventdata,handleshaxes)
xx=double(get(hObject,'CurrentCharacter')); %get the keyboard character
cur_axes=get(gcbf,'CurrentAxes');
if ~isempty(cur_axes)
    xlimit=get(cur_axes,'XLim');
    ylimit=get(cur_axes,'Ylim');
    dx=(xlimit(2)-xlimit(1))/10;
    dy=(ylimit(2)-ylimit(1))/10;
   
    if isequal(xx,29)%move arrow right
        xlimit=xlimit+dx;
    elseif isequal(xx,28)%move arrow left
        xlimit=xlimit-dx;
    elseif isequal(xx,30)%move arrow up
        ylimit=ylimit+dy;
    elseif isequal(xx,31)%move arrow down
        ylimit=ylimit-dy;
    end
    set(cur_axes,'XLim',xlimit)
    set(cur_axes,'YLim',ylimit)
end
if ismember(xx,[8 127]) %if the delete or suppr key is pressed, delete the current object 
    currentobject=gco;
    huvmat=findobj(allchild(0),'tag','uvmat');
%     UvData=get(huvmat,'UserData');%Data associated to the current uvmat interface
    hlist_object=findobj(huvmat,'Tag','list_object_1');
    ObjIndex=get(hlist_object,'Value')
    if ObjIndex>1 
        delete_object(ObjIndex)
    end
    if ishandle(currentobject)
        tag=get(currentobject,'Tag');%tag of the current selected object
        if isequal(tag,'proj_object')
            delete_object(currentobject)
        end
    end
elseif isequal(xx,112)%  key 'p'
    uvmat('runplus_Callback',hObject,eventdata,handleshaxes)
elseif isequal(xx,109)%  key 'm'
    uvmat('runmin_Callback',hObject,eventdata,handleshaxes)
end

AxeData=get(cur_axes,'UserData');
if isfield(AxeData,'ParentRect')% update the position of the parent rectangle represneting the field
    hparentrect=AxeData.ParentRect;
    rect([1 2])=[xlimit(1) ylimit(1)];
    rect([3 4])=[xlimit(2)-xlimit(1) ylimit(2)-ylimit(1)];
    set(hparentrect,'Position',rect)
end