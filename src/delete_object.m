%'delete_object': delete a projection object, defined by its index in the Uvmat list or by its graphic handle
%------------------------------------------------------------------------
% function delete_object(hObject)
%
% INPUT:
% hObject: object index (if integer) or handle of the graphic object. If
%          hObject is a subobject, the parent object is detected and deleted. 

function delete_object(hObject)

huvmat=findobj('tag','uvmat');%handles of the uvmat interface
UvData=get(huvmat,'UserData');
hlist_object=findobj(huvmat,'Tag','ListObject');%handles of the object list in the uvmat interface
list_str=get(hlist_object,'String');%objet list
if isequal(floor(hObject),hObject) %case of an index
    if  ~isempty(UvData) && isfield(UvData, 'Object') && length(UvData.Object)>=hObject 
        if isfield(UvData.Object{hObject},'DisplayHandle') && isfield(UvData.Object{hObject}.DisplayHandle,'uvmat')
            hdisplay=UvData.Object{hObject}.DisplayHandle.uvmat;
            for iview=1:length(hdisplay)
                if ishandle(hdisplay(iview)) && ~isequal(hdisplay(iview),0)
                    ObjectData=get(hdisplay(iview),'UserData');
                    if isfield(ObjectData,'SubObject') & ishandle(ObjectData.SubObject)
                        delete(ObjectData.SubObject);
                    end
                    if isfield(ObjectData,'DeformPoint') & ishandle(ObjectData.DeformPoint)
                        delete(ObjectData.DeformPoint);
                    end
                    delete(hdisplay(iview))
                end
                ishandle(hdisplay(iview))
            end
            for iobj=hObject+1:length(UvData.Object)
                hdisplay=UvData.Object{iobj}.DisplayHandle.uvmat;
                for iview=1:length(hdisplay)
                    if ishandle(hdisplay(iview)) && ~isequal(hdisplay(iview),0)
                        PlotData=get(hdisplay(iview),'UserData');
                        PlotData.IndexObj=iobj-1;
                        set(hdisplay(iview),'UserData',PlotData);
                    end
                end
            end
        end
        UvData.Object(hObject)=[];  
        if ~isempty(list_str)
            list_str(hObject)=[];
        end
    end
elseif ishandle(hObject)%object handle
    userdata=get(hObject,'UserData');
    if ishandle(userdata)%the selected line depends on a parent line
        hdisplay=userdata;% the parent object becomes the current one
    else
        hdisplay=hObject;% the selected object becomes the current one
    end
    PlotData=get(hdisplay,'UserData');
    if isfield(PlotData,'SubObject') & ishandle(PlotData.SubObject)
            delete(PlotData.SubObject);
    end
    if isfield(PlotData,'DeformPoint') & ishandle(PlotData.DeformPoint)
           delete(PlotData.DeformPoint);
    end
    delete(hdisplay);
    if isfield(PlotData,'IndexObj')
        IndexObj=PlotData.IndexObj;
        if  isequal(round(IndexObj),IndexObj) & IndexObj>=1 & length(list_str) > IndexObj
            if isfield(UvData,'Object')& length(UvData.Object) > IndexObj
               UvData.Object(IndexObj)=[];
            end
            list_str(IndexObj)=[];
        end
    end
end
set(huvmat,'UserData',UvData);
set(hlist_object,'String',list_str)
set(hlist_object,'Value',length(list_str))
hlist_object_1=findobj(huvmat,'Tag','ListObject_1');%handles of the first object list in the uvmat interface
old_index=get(hlist_object_1,'Value');
set(hlist_object_1,'String',list_str)
if hObject<=old_index
    set(hlist_object_1,'Value',old_index-1)
end
% hlist_object=findobj(huvmat,'Tag','list_object_2');%handles of the object li�st in the uvmat interface
% set(hlist_object,'String',[list_str;{'...'}])
% set(hlist_object,'Value',length(list_str)+1)
