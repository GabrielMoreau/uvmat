%'update_obj': update the object graph representation and its projection field, record it in the uvmat interface
%-------------------------------------------------------------------
%Object_out=update_obj(UvData,IndexObj_1,IndexObj_2);

%OUTPUT:
% Object_out= cell array of structures containing the properties of the existing objects     .
%
%INPUT:
%UvData: structure stored as 'Userdata' on the uvmat interface, it contains:
%    .Object{1},{2}... description of all the projection objects 
%    .Field , the current input field to be projected on the object
%    .Object{IndexObj}.DisplayHandle_uvmat: handles of the object plot on uvmat, =[] if it does not exist
%    .Object{IndexObj}.DisplayHandle_view_field: handles of the object plot on view_field, =[] if it does not exist
%IndexObj_1: index of  the object whose projection is plotted in the GUI uvmat 
%IndexObj_2: index of  the object whose projection is plotted in te GUI view_field 
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
    Object_out{iobj}.DisplayHandle_uvmat=plot_object(Object_out{iobj},Object_out{IndexObj_1},hobject,'m');%update the object representation of Object_out{iobj} on Object_out{IndexObj_1}
end
% plot view_field
if ~isempty(IndexObj_2)
    for iobj=1:length(Object_out) %change the view of all existing objects on the updated  object #IndexObj_2
        hobject=[];
        if isfield(Object_out{iobj},'DisplayHandle_view_field') &&  ~isempty(Object_out{iobj}.DisplayHandle_view_field) && ishandle(Object_out{iobj}.DisplayHandle_view_field)
            hobject=Object_out{iobj}.DisplayHandle_view_field;%graphic handle of object #iobj in the view_field plot
        end
        Object_out{iobj}.DisplayHandle_view_field=plot_object(Object_out{iobj},Object_out{IndexObj_2},hobject,'m');%update the object representation
    end
end





