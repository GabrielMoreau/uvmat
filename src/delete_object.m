%'delete_object': delete a projection object, defined by its index in the Uvmat list or by its graphic handle
%
%INPUT:
% hObject: object index (if integer) or handle of the graphic object. If
% hObject is a subobject, the parent object is detected and deleted. 

function delete_object(hObject)

huvmat=findobj('tag','uvmat');%handles of the uvmat interface
UvData=get(huvmat,'UserData');
hlist_object=findobj(huvmat,'Tag','list_object_1');%handles of the object liçst in the uvmat interface
list_str=get(hlist_object,'String');%objet list
ObjectData=[];%default
hdisplay=[];
if isequal(floor(hObject),hObject) %case of an index
    if  ~isempty(UvData) & isfield(UvData, 'Object') & length(UvData.Object)>=hObject 
        if isfield(UvData.Object{hObject},'HandlesDisplay') 
            hdisplay=UvData.Object{hObject}.HandlesDisplay;
            for iview=1:length(hdisplay)
                if ishandle(hdisplay(iview)) & ~isequal(hdisplay(iview),0)
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
        end   
        for iobj=hObject+1:length(UvData.Object)
            hdisplay=UvData.Object{iobj}.HandlesDisplay;
            for iview=1:length(hdisplay)
                if ishandle(hdisplay(iview)) && ~isequal(hdisplay(iview),0)
                    PlotData=get(hdisplay(iview),'UserData');
                    PlotData.IndexObj=iobj-1;
                    set(hdisplay(iview),'UserData',PlotData);
                end
            end
        end
        UvData.Object(hObject)=[];  
        list_str(hObject)=[];
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
hlist_object=findobj(huvmat,'Tag','list_object_2');%handles of the object liçst in the uvmat interface
set(hlist_object,'String',[list_str {'...'}])
set(hlist_object,'Value',length(list_str)+1)
