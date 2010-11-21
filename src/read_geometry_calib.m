%'read_geometry_calib': read data on the GUI geometry_calib
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data=read_geometry_calib(Coord_cell)
nb_defining_points=length(Coord_cell);
iline=0;
data.Coord=[];%default
for i=1:nb_defining_points
    coord_str=Coord_cell{i};%character string of line number i
    k=findstr('|',coord_str);%find separators '|'
    if length(k)>=4 % test for separators '|'
        data1=str2double(coord_str(1:k(1)-2));
        data2=str2double(coord_str(k(1)+2:k(2)-2));
        data3=str2double(coord_str(k(2)+2:k(3)-2));
        data4=str2double(coord_str(k(3)+2:k(4)-2));
        data5=str2double(coord_str(k(4)+2:end));
        if ~isnan(data1)||~isnan(data2)||~isnan(data3)||~isnan(data4)||~isnan(data5)
            iline=iline+1;
            if ~isnan(data1)
                data.Coord(iline,1)=data1;
            end    
            if ~isnan(data2)
                data.Coord(iline,2)=data2;
            end
            if ~isnan(data3)
                data.Coord(iline,3)=data3;
            end
            if ~isnan(data4)
                data.Coord(iline,4)=data4;
            end
            if isnan(data5)
                data.Coord(iline,5)=0;
            else
                data.Coord(iline,5)=data5;
            end
        end
    end
end
data.Style='points';