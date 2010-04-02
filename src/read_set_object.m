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
if isfield(handles,'ObjectStyle')%case of the set_object interface
	menu=get(handles.ObjectStyle,'String');
	value=get(handles.ObjectStyle,'Value');
	data.Style=menu{value};
	menu=get(handles.ProjMode,'String');
	value=get(handles.ProjMode,'Value');
	data.ProjMode=menu{value};
	menu=get(handles.MenuCoord,'String');
	value=get(handles.MenuCoord,'Value');
	data.CoordType=menu{value};
    testcalib=0;
else %default
    data.Style='points';
    testcalib=1;
end

%Euler angles and projection ranges
if ~testcalib
	if isequal(get(handles.Phi,'Visible'),'on')
        data.Phi=str2num(get(handles.Phi,'String'));
	end
	if isequal(get(handles.Theta,'Visible'),'on')
        data.Theta=str2num(get(handles.Theta,'String'));
	end
	if isequal(get(handles.Psi,'Visible'),'on')
        data.Psi=str2num(get(handles.Psi,'String'));
    end	
	if isequal(get(handles.DX,'Visible'),'on')
        data.DX=str2num(get(handles.DX,'String'));
	end
	if isequal(get(handles.DY,'Visible'),'on')
        data.DY=str2num(get(handles.DY,'String'));
	end
	if isequal(get(handles.DZ,'Visible'),'on')
        data.DZ=str2num(get(handles.DZ,'String'));
    end
    dimrange=[1 1];%default
    if isequal(get(handles.ZMin,'Visible'),'on')
        ZMin=str2num(get(handles.ZMin,'String'));
        if ~isempty(ZMin)
           data.RangeZ(1)=ZMin;
           dimrange=[2 3];
        end
    end
	if isequal(get(handles.ZMax,'Visible'),'on')
        ZMax=str2num(get(handles.ZMax,'String'));
        if isempty(ZMax)
            if dimrange(1)>1
%                 set(handles.ZMax,'String',get(handles.ZMin,'String'))
                data.RangeZ(1)=ZMax;
            end
        else 
           data.RangeZ(2)=ZMax;
           dimrange=[dimrange(1) 3];
        end
    end
    if isequal(get(handles.YMin,'Visible'),'on')
        YMin=str2num(get(handles.YMin,'String'));
        if isempty(YMin) 
%             if dimrange(2)>2
% %                 set(handles.YMin,'String','0')
%                 data.RangeY(2)=0;
%             end
        else
            data.RangeY(2)=YMin;
            dimrange=[2 max(dimrange(2),2)];
        end
    end
    if isequal(get(handles.YMax,'Visible'),'on')
%         data.YMax=str2num(get(handles.YMax,'String'));
        YMax=str2num(get(handles.YMax,'String'));
        if isempty(YMax) 
%             if dimrange(1)>1
% %                 set(handles.YMax,'String',get(handles.YMin,'String'))
%                 if ~isempty(YMin)
%                 data.RangeY(1)=YMin;
%                 end
%             elseif dimrange(2)>2
% %                 set(handles.YMax,'String',get(handles.ZMin,'String'))
%                 data.RangeY(2)=ZMin;
%             end
        else
            data.RangeY(1)=YMax;
            dimrange=[dimrange(1) max(dimrange(2),2)];
        end
    end
    if isequal(get(handles.XMin,'Visible'),'on')
        XMin=str2num(get(handles.XMin,'String'));
        if isempty(XMin) 
%             if ~isempty(YMin)
%                 if dimrange(2)>1
% %                     set(handles.XMin,'String',get(handles.YMin,'String'))
%                     data.RangeX(2)=YMin;
%                     XMin=YMin;
%                 end
%             end
        else
            data.RangeX(2)=XMin;
            %dimrange=[2 max(dimrange(2),1)];
        end
	end
	if isequal(get(handles.XMax,'Visible'),'on')
         XMax=str2num(get(handles.XMax,'String'));
         if isempty(XMax) 
%             if dimrange(1)>1
% %                 set(handles.XMax,'String',get(handles.XMin,'String'))
%                 if ~isempty(XMin)
%                 data.RangeX(2)=XMin;
%                 end
%             elseif dimrange(2)>1
% %                 set(handles.XMax,'String',get(handles.YMax,'String'))
%                 data.RangeX(1)=YMax;
%             end
        else
            data.RangeX(1)=XMax;
         end
    end
end


%positions x,y,z
Xcolumn=get(handles.XObject,'String');
Ycolumn=get(handles.YObject,'String');
if ischar(Xcolumn)
    sizchar=size(Xcolumn);
    for icol=1:sizchar(1)
        Xcolumn_cell{icol}=Xcolumn(icol,:);
    end
    Xcolumn=Xcolumn_cell;
end
if ischar(Ycolumn)
    sizchar=size(Ycolumn);
    for icol=1:sizchar(1)
        Ycolumn_cell{icol}=Ycolumn(icol,:);
    end
    Ycolumn=Ycolumn_cell;
end
Zcolumn={};%default
if isequal(get(handles.ZObject,'Visible'),'on')
    data.NbDim=3; %test 3D object
    Zcolumn=get(handles.ZObject,'String');
    if ischar(Zcolumn)
        Zcolumn={Zcolumn};
    end
end
nb_points=min(length(Xcolumn),length(Ycolumn));%number of point positions needed to define the object position
if isequal (data.Style,'line');
    nb_defining_points=2;
elseif isequal(data.Style,'plane')|isequal(data.Style,'rectangle')|isequal(data.Style,'ellipse')
    nb_defining_points=1;
else
    nb_defining_points=nb_points;
end
data_XObject=[];
data_YObject=[];
data_ZObject=[];
for i=1:nb_points
    Xnumber=str2num(Xcolumn{i});
    Ynumber=str2num(Ycolumn{i});
    if isempty(Xnumber)|isempty(Ynumber)
        break
    else
        data_XObject=[data_XObject; Xnumber(1)];
        data_YObject=[data_YObject; Ynumber(1)];
    end
    if length(Zcolumn)<i | isempty(str2num(Zcolumn{i}))
        data_ZObject=[data_ZObject; 0];
    else
        data_ZObject=[data_ZObject; str2num(Zcolumn{i})];
    end
end
if nb_defining_points > nb_points
    for i=nb_points+1:nb_defining_points
        data_XObject=[0;data_XObject];
        data_YObject=[0;data_YObject];
        data_ZObject=[0;data_ZObject];
    end
end
if isempty(data_XObject)
    data_XObject=0;
end
if isempty(data_YObject)
    data_YObject=0;
end
if isempty(data_ZObject)
    data_ZObject=0;
end
data.Coord=[data_XObject data_YObject data_ZObject];

set(handles.XObject,'String',mat2cell(data_XObject,length(data_XObject)))%correct the interface display
set(handles.YObject,'String',mat2cell(data_YObject,length(data_XObject)))
set(handles.ZObject,'String',mat2cell(data_ZObject,length(data_XObject)))


