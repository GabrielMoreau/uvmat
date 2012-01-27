%'read_set_object': read the data on the 'set_object' interface
%--------------------------------------------------------
% data=read_set_object(handles)
%--------------------------------------------------------
%OUTPUT
%data: structure of data read on the set_object interface
%    .Style : style of projection object
%    .Coord(nbpos,3): set of coordinates defining the object position;
%    .ProjMode=type of projection ;
%    .Phi=angle of projection;
%    .DX,.DY,.DZ=increments;
%    .YMax,YMin: min and max Y
%INPUT:
% handles: structure describing the tags of the edit boxes and menus
function data=read_set_object(handles)
%menus 
data=read_GUI(handles);

% %Euler angles and projection ranges
% if isfield(data,'Angle_x')
%     data.Angle(1)=data.Angle_x;
%     data=rmfield(data,'Angle_x');
% end
% if isfield(data,'Angle_y')
%     data.Angle(2)=data.Angle_y;
%     data=rmfield(data,'Angle_y');
% end
% if isfield(data,'Angle_z')
%     data.Angle(3)=data.Angle_z;
%     data=rmfield(data,'Angle_z');
% end
% % ranges of projection
% data.RangeZ=[];
% data.RangeY=[];
% data.RangeX=[];
% if isfield(data,'ZMin')&& ~isempty(data.ZMin)
%     data.RangeZ=data.ZMin;
%     data=rmfield(data,'ZMin');
% end
% if isfield(data,'ZMax')&& ~isempty(data.ZMax)
%     data.RangeZ=[data.RangeZ data.ZMax];
%     data=rmfield(data,'ZMax');
% end
% if isfield(data,'YMin')&& ~isempty(data.YMin)
%     data.RangeY=data.YMin;
%     data=rmfield(data,'YMin');
% end
% if isfield(data,'YMax')&& ~isempty(data.YMax)
%     data.RangeY=[data.RangeY data.YMax];
%     data=rmfield(data,'YMax');
% end
% if isfield(data,'XMin')&& ~isempty(data.XMin)
%     data.RangeX=data.XMin;
%     data=rmfield(data,'XMin');
% end
% if isfield(data,'XMax')&& ~isempty(data.XMax)
%     data.RangeX=[data.RangeX data.XMax];
%     data=rmfield(data,'XMax');
% end
% 
% 
% 
% 
