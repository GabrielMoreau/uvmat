function f=polyval_n(xy_scale,coeff,coord_x,coord_y)
f=NaN;%default
% xCenter = mean(coord_x); yCenter = mean(coord_y);
% xScale = std(coord_x,1); yScale = std(coord_y,1);
xCenter=xy_scale(1);yCenter=xy_scale(2);xScale=xy_scale(3);yScale=xy_scale(4);
U = (coord_x-xCenter)/xScale;
V = (coord_y-yCenter)/yScale;
switch(numel(coeff))
    case 3
        degree=1;
    case 4 % case of a polynom y=fct(x), compatibility with the bottom correction of 2024/PLUME
        f=polyval(coeff,Xphys);
        return
    case 6
        degree=2;
    case 10
        degree=3;
    case 15
        degree=4;
    otherwise
        disp('input coeff array not valid')
        return
end
% fct PolyTerm of Eletta:
A = zeros(numel(U),(degree+1)*(degree+2)/2);
k = 0;
for total = 0:degree
    for i = total:-1:0
        j = total-i;
        k = k+1;
        [i j]
        A(:,k) = U.^i .* V.^j;
    end
end

f=A*coeff;
  

