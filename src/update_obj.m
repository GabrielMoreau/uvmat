%'update_obj': update the object graph representation and its projection field, record it in the uvmat interface
%-------------------------------------------------------------------
%Object_out=update_obj(UvData,IndexObj,ObjectData,PlotHandles);

%OUTPUT:
% Object_out= cell array of structures containing the properties of the existing objects     .
%
%INPUT:
%UvData: structure stored as 'Userdata' on the uvmat interface, it contains:
%    .Object{1},{2}... description of all the projection objects 
%    .Field , the current input field to be projected on the object
%    .Object{IndexObj}.DisplayHandle_uvmat: handles of the object plot on uvmat, =[] if it does not exist
%    .Object{IndexObj}.DisplayHandle_view_field: handles of the object plot on view_field, =[] if it does not exist
%IndexObj: object index of  UvData.Object correspopnding to the updated object
%ObjectData: structure containing the input object properties to be attributed to the object #IndexObj
%       .Style: style of the object: 'line', 'rectangle'...
%PlotHandles: structure containing the handles of the plotting parameter buttons on the uvmat or view_field interface 
%-------------------------------------

function Object_out=update_obj(UvData,IndexObj_1,IndexObj_2)

%% default input and output
% Object_out{IndexObj}=ObjectData;%default
% if  isfield(UvData,'Object') 
%     Object_set=UvData.Object;
% else
%     Object_set={};%create the object
% end
Object_out=UvData.Object;

%% plot the field projected on the object
% ProjData= proj_field(UvData.Field,ObjectData,IndexObj);%project the current interface field on ObjectData
% if ~isempty(ProjData)   
%     plotaxes=[];%default
%     if length(Object_set)>= IndexObj && isfield(Object_set{IndexObj},'plotaxes')
%         plotaxes=Object_set{IndexObj}.plotaxes;
%         [PlotType,Object_out{IndexObj}.PlotParam,plotaxes]=plot_field(ProjData,plotaxes,PlotHandles);%update an existing field plot
%         plotfig=get(plotaxes,'parent');
%         ViewData=get(plotfig,'UserData');
%         eval(
%     else
%         hview_field=view_field(ProjData);%create a new field plot with view_field
%         hhview_field=guidata(hview_field);
%         plotaxes=hhview_field.axes3;
%     end
%     Object_out{IndexObj}.plotaxes=plotaxes;
% end

%%  representation of the different objects in the plots uvmat and view_field
%hfig=get(plotaxes,'parent');
%tagfig=get(hfig,'tag');
% if length(Object_set)<IndexObj
    %Object_set{IndexObj}=ObjectData;
% end
% plot the updated object in uvmat
%  hobject=[];
% if isfield(Object_set{IndexObj},'DisplayHandle_uvmat') && ~isempty(Object_set{IndexObj}.DisplayHandle_uvmat) && ishandle(Object_set{IndexObj}.DisplayHandle_uvmat)
%     hobject=Object_set{IndexObj}.DisplayHandle_uvmat;
% % else
% %     hobject=plotaxes;
% end
% Object_out{IndexObj}.DisplayHandle_uvmat=plot_object(Object_set{IndexObj},Object_set{1},hobject,'m');%update the object representation

% if strcmp(tagfig,'uvmat')%plot uvmat
    for iobj=1:length(Object_out) %change the view of all existing objects on the updated current object #IndexObj_1
         hobject=[];
        if isfield(Object_out{iobj},'DisplayHandle_uvmat') && ~isempty(Object_out{iobj}.DisplayHandle_uvmat) && ishandle(Object_out{iobj}.DisplayHandle_uvmat)
            hobject=Object_out{iobj}.DisplayHandle_uvmat;
%         else 
%             hobject=plotaxes;
        end
        Object_out{iobj}.DisplayHandle_uvmat=plot_object(Object_out{iobj},Object_out{IndexObj_1},hobject,'m');%update the object representation
    end
% else%plot view_field
    for iobj=1:length(Object_out) %change the view of all existing objects on the updated current object #IndexObj_2
        hobject=[];
        if isfield(Object_out{iobj},'DisplayHandle_view_field') &&  ~isempty(Object_out{iobj}.DisplayHandle_view_field) && ishandle(Object_out{iobj}.DisplayHandle_view_field)
            hobject=Object_out{iobj}.DisplayHandle_view_field;
%         else 
%             hobject=plotaxes;
        end
        Object_out{iobj}.DisplayHandle_view_field=plot_object(Object_out{iobj},Object_out{IndexObj_2},hobject,'m');%update the object representation
    end
%  end

%     if isfield(Object_set{iobj},'plotaxes')
%         haxes=Object_set{iobj}.plotaxes;% axes for the field plot
%         if ishandle(haxes) && isequal(get(haxes,'Type'),'axes')% update the representation of the object IndexObj on this axes if it exists
%             testupdate=0;
%             HandlesDisplay=[];%default
%             if length(Object_set)>= IndexObj && isfield(Object_set{IndexObj},'HandlesDisplay')
%                 HandlesDisplay=Object_set{IndexObj}.HandlesDisplay;%list of handles of object representations
%             end
%             hplot_list=findobj(haxes,'Tag','proj_object');%list of projection objects on the axes
%             for ih=1:length(HandlesDisplay)
%                 plot_detect=find(hplot_list==HandlesDisplay(ih));
%                 if ~isempty(plot_detect)
%                     Object_out.HandlesDisplay(ih)=plot_object(ObjectData,Object_set{iobj},HandlesDisplay(ih),'m');%update the the object representation
%                     testupdate=1;
%                     break
%                 end
%             end
%             if ~testupdate% draw new object plot
%                 hh=plot_object(ObjectData,Object_set{iobj},haxes,'m');%draw the object with the new object data
%                 if isfield(Object_out,'HandlesDisplay')
%                     Object_out.HandlesDisplay=[Object_out.HandlesDisplay hh];
%                 else
%                     Object_out.HandlesDisplay=hh;
%                 end
%                 PlotData=get(hh,'UserData');
%                 PlotData.IndexObj=IndexObj;
%                 set(hh,'UserData',PlotData); %record the object index in the graph
%             end
%         end
%     end
% end




