function [coeff,xy_scale]=polyfit_n(coord_x,coord_y,f,degree)

xCenter = mean(coord_x); yCenter = mean(coord_y);
xScale = std(coord_x,1); yScale = std(coord_y,1);
xy_scale(1)=xCenter;xy_scale(2)=yCenter;xy_scale(3)=xScale;xy_scale(4)=yScale;
U = (coord_x-xCenter)/xScale;
V = (coord_y-yCenter)/yScale;

%fct polyTerm of Eletta
A = zeros(numel(U),(degree+1)*(degree+2)/2);
k = 0;
for total = 0:degree
    for i = total:-1:0
        j = total-i;
        k = k+1;
        A(:,k) = U.^i .* V.^j;
    end
end

coeff = A\f;% solve the equation A*coeff=physical
coeff=coeff';

  

