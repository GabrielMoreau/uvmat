%'update_obj': update the object graph representation and its projection field, record it in the uvmat interface
%-------------------------------------------------------------------
%Object=update_obj(UvData,IndexObj,ObjectData,PlotHandles);
%
%OUTPUT:
%UvData: data to be stored as 'Userdata' on the uvmat interface
%IndexObj: object index for a new object added to the list in UvData
%   the function updates UvData.Object{IndexObj}, and possibly adds a new plot (UvData.Plane or Line) in the list atached to the interface
%
%INPUT:
%UvIn: structure stored as 'Userdata' on the uvmat interface
%IndexObjIn: object index for an existing objects stored in UvData
%ObjectData: structure containing the input object properties
%PlotHandles: structure containing the handles of the plotting parameter buttons on the uvmat interface (obtained by get_plot_handles.m)
%-------------------------------------

function Object_out=update_obj(UvData,IndexObj,ObjectData,PlotHandles)

%default input and output
Object_out=ObjectData;%default
if  isfield(UvData,'Object') 
    Object_set=UvData.Object;
else
    Object_set={};%create the object
end

% object representation in the different projected field plots
for iview=1:length(Object_set) %loop on projection planes iview
      if isfield(Object_set{iview},'plotaxes')
         haxes=Object_set{iview}.plotaxes% axes for the field plot
         if ishandle(haxes) & isequal(get(haxes,'Type'),'axes')% update the representation of the object IndexObj on this axes if it exists
             testupdate=0;
             HandlesDisplay=[];%default
             if length(Object_set)>= IndexObj && isfield(Object_set{IndexObj},'HandlesDisplay')
                 HandlesDisplay=Object_set{IndexObj}.HandlesDisplay;%list of handles of object representations
             end
             hplot_list=findobj(haxes,'Tag','proj_object');
             for ih=1:length(HandlesDisplay)
                 plot_detect=find(hplot_list==HandlesDisplay(ih));
                 if ~isempty(plot_detect)
                     Object_out.HandlesDisplay(ih)=plot_object(ObjectData,Object_set{iview},HandlesDisplay(ih),'m');%update the the object representation
                     testupdate=1;
                     break
                 end
             end
             if ~testupdate% draw new object plot
                hh=plot_object(ObjectData,Object_set{iview},haxes,'m');%draw the object with the new object data
                Object_out.HandlesDisplay=[Object_out.HandlesDisplay hh];
                PlotData=get(hh,'UserData');
                PlotData.IndexObj=IndexObj;
                set(hh,'UserData',PlotData); %record the object index in the graph
             end
         end
      end
end
% plot the field projected on the object
if ~isempty(PlotHandles) %&& ~testmask
    ProjData= proj_field(UvData.Field,ObjectData,IndexObj);%project the current interface field on ObjectData
    if ~isempty(ProjData)   
        plotaxes=[];%default
        if length(Object_set)>= IndexObj && isfield(Object_set{IndexObj},'plotaxes')
            plotaxes=Object_set{IndexObj}.plotaxes;
            [PlotType,Object_out.PlotParam,plotaxes]=plot_field(ProjData,plotaxes,PlotHandles);
        else
             [plotaxes]=view_field(ProjData);
        end
%         [PlotType,Object_out.PlotParam,plotaxes]=plot_field(ProjData,plotaxes,PlotHandles);
        Object_out.plotaxes=plotaxes;
        plotfig=get(plotaxes,'parent');
        name_str=get(plotfig,'Name');
        if ~isequal(name_str,'uvmat')
            set(plotfig,'Name',['Projection on' num2str(IndexObj) '-' ObjectData.Style]);
        end
    end
end


