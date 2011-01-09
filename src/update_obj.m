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
Object_out=UvData.Object;


%%  representation of the different objects in the plots uvmat and view_field
%plot uvmat
    for iobj=1:length(Object_out) %change the view of all existing objects on the updated current object #IndexObj_1
         hobject=[];
        if isfield(Object_out{iobj},'DisplayHandle_uvmat') && ~isempty(Object_out{iobj}.DisplayHandle_uvmat) && ishandle(Object_out{iobj}.DisplayHandle_uvmat)
            hobject=Object_out{iobj}.DisplayHandle_uvmat;%graphic handle of object #iobj in the uvmat plot
        end
        Object_out{iobj}.DisplayHandle_uvmat=plot_object(Object_out{iobj},Object_out{IndexObj_1},hobject,'m');%update the object representation
    end
% plot view_field
if ~isempty(IndexObj_2)
    for iobj=1:length(Object_out) %change the view of all existing objects on the updated current object #IndexObj_2
        hobject=[];
        if isfield(Object_out{iobj},'DisplayHandle_view_field') &&  ~isempty(Object_out{iobj}.DisplayHandle_view_field) && ishandle(Object_out{iobj}.DisplayHandle_view_field)
            hobject=Object_out{iobj}.DisplayHandle_view_field;%graphic handle of object #iobj in the view_field plot
        end
        Object_out{iobj}.DisplayHandle_view_field=plot_object(Object_out{iobj},Object_out{IndexObj_2},hobject,'m');%update the object representation
    end
end





