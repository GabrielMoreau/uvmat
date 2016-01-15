%'find_field_bounds': % find the bounds and typical meshs of coordinates
%-----------------------------------------------------------------------
%function  FieldOut=find_field_bounds(Field)
%-----------------------------------------------------------------------
%OUTPUT
%FieldOut copy of the input Field with the additional items:
%  .XMin,.XMax,.YMin,.YMax,bounds for x and y
%  .CoordMesh: typical mesh needed for automatic grids
%
%INPUT
% Field: Matlab structure describing the input field
%
%=======================================================================
% Copyright 2008-2016, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function FieldOut=find_field_bounds(Field)

FieldOut=Field;%default
%% analyse input field
[CellInfo,NbDimArray,errormsg]=find_field_cells(Field);% analyse  the input field structure
if ~isempty(errormsg)
    errormsg=['uvmat /refresh_field / find_field_cells / ' errormsg];% display error
    return
end

NbDim=max(NbDimArray);% spatial dimension of the input field
imax=find(NbDimArray==NbDim);% indices of field cells to consider
Check4D=0;
if NbDim>3
    NbDim=3;
    Check4D=1;
end
FieldOut.NbDim=NbDim;
if  NbDim<=1; return; end% stop here for 1D fields
 
%% get bounds and mesh (needed  to propose default options for projection objects)
% if NbDim>1
CoordMax=zeros(numel(imax),NbDim);
CoordMin=zeros(numel(imax),NbDim);
Mesh=zeros(1,numel(imax));
for ind=1:numel(imax)
    if strcmp(CellInfo{imax(ind)}.CoordType,'tps')
        CoordName=Field.ListVarName{CellInfo{imax(ind)}.CoordIndex};% X,Y coordinates in a single variable
        CoordMax(ind,NbDim)=max(max(Field.(CoordName)(1:end-3,1,:),[],1),[],3);% max of x component (2D case)
        CoordMax(ind,NbDim-1)=max(max(Field.(CoordName)(1:end-3,2,:),[],1),[],3);% max of y component (2D case)
        CoordMin(ind,NbDim)=min(min(Field.(CoordName)(1:end-3,1,:),[],1),[],3);
        CoordMin(ind,NbDim-1)=min(min(Field.(CoordName)(1:end-3,2,:),[],1),[],3);% min of y component (2D case)
    else
        if Check4D
            CellInfo{imax(ind)}.CoordIndex(4:end)=[];
        end
        XName=Field.ListVarName{CellInfo{imax(ind)}.CoordIndex(end)};
        YName=Field.ListVarName{CellInfo{imax(ind)}.CoordIndex(end-1)};
        CoordMax(ind,NbDim)=max(max(Field.(XName)));
        CoordMin(ind,NbDim)=min(min(Field.(XName)));
        CoordMax(ind,NbDim-1)=max(max(Field.(YName)));
        CoordMin(ind,NbDim-1)=min(min(Field.(YName)));
        %         test_x=1;%test for unstructured coordinates
        if NbDim==3
            ZName=Field.ListVarName{CellInfo{imax(ind)}.CoordIndex(1)};
            CoordMax(ind,NbDim-2)=max(max(Field.(ZName)));
            CoordMin(ind,NbDim-2)=min(min(Field.(ZName)));
        end
    end
    switch CellInfo{imax(ind)}.CoordType
        
        case {'scattered','tps'} %unstructured coordinates
            NbPoints=CellInfo{imax(ind)}.CoordSize;% total nbre of points
            Mesh(ind)=(prod(CoordMax(ind,:)-CoordMin(ind,:))/NbPoints)^(1/NbDim); %(volume or area per point)^(1/NbDim)
        case 'grid'%structured coordinate
            NbPoints=CellInfo{imax(ind)}.CoordSize;% nbre of points in each direction
            if Check4D
               NbPoints=NbPoints(1:3);
            end
            Mesh(ind)=min((CoordMax(ind,:)-CoordMin(ind,:))./(NbPoints-1));
    end
end
Mesh=min(Mesh);
FieldOut.XMax=max(CoordMax(:,end));
FieldOut.XMin=min(CoordMin(:,end));
FieldOut.YMax=max(CoordMax(:,end-1));
FieldOut.YMin=min(CoordMin(:,end-1));
if NbDim==3
    FieldOut.ZMax=max(CoordMax(ind,1));
    FieldOut.ZMin=min(CoordMin(ind,1));
end
% adjust the mesh to a value 1, 2 , 5 *10^n
ord=10^(floor(log10(Mesh)));%order of magnitude
if Mesh/ord>=5
    FieldOut.CoordMesh=5*ord;
elseif Mesh/ord>=2
    FieldOut.CoordMesh=2*ord;
else
    FieldOut.CoordMesh=ord;
end
