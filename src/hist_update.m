%'hist_update': update of a current global histogram by inclusion of a new field
%------------------------------------------------------------------------
%[val,HIST]=hist_update(val,HIST,C,dC)
%
% OUTPUT:
% val: vector of field values at which the histogram is determined (middle of bins)
% HIST(:,icolor): nbre of occurence of the field value in the bins whose middle is given by val
%           can be a column vector, same size as val, or a matrix with three columns, for color images
%
% INPUT:
% val: existing field values from the current histogram, =[] if there is no current histogram
% HIST(:,icolor): current histogram,  =[] if there is none
%       can be a column vector (icolor=1), same size as val, or a matrix with three columns, for color images      
% C(:,icolor): vector representing the current field values
%       can be a column vector (icolor=1), or a matrix with three columns, for color images 
% dC: width of the new bins extending val to account for the new field.

%=======================================================================
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function [val,HIST]=hist_update(val,HIST,C,dC)

valplus=[];valminus=[];
HISTplus=[];HISTminus=[];
if isempty(HIST)
    HIST=0;
end
siz=size(C);nbfields=siz(2);
C=double(C);
valmin=min(val); 
valmax=max(val);
Cmin=min(min(C)); Cmax=max(max(C));
if isempty(val)%no current histogram
    val=[Cmin-dC/2:dC:Cmax+dC/2];
else %extending the current histogram beyond its maximum value
    if Cmax>=valmax+dC/2;
        valplus=[valmax+dC:dC:Cmax+dC/2];% we extend the values val
        HISTplus=zeros(length(valplus),nbfields);% we put histogram to zero at these values
    end
    %extending the current histogram below its minimum value
    if Cmin<=valmin-dC/2;
        valminus=[valmin-dC:-dC:Cmin-dC/2];% we extend the values val
        valminus=sort(valminus);% we reverse the order
        HISTminus=zeros(length(valminus),nbfields);% we put histogram to zero at these values
    end
    val=[valminus val valplus];
end
HIST=[HISTminus;HIST;HISTplus];
if nbfields==1
    histC=(hist(C,val))';% initiate the global histogram 
elseif nbfields==3
    HIST1=(hist(C(:,1),val))';
    HIST2=(hist(C(:,2),val))';
    HIST3=(hist(C(:,3),val))';
    histC=[HIST1 HIST2 HIST3];
end
HIST=HIST+histC;
