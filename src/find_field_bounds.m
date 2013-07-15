%'find_field_bounds': % find the boounds and typical meshs of coordinates
%-----------------------------------------------------------------------
%function  FieldOut=find_field_bounds(Field)
%-----------------------------------------------------------------------
%OUTPUT
%FieldOut copy of the input Field with the additional items:
%  .XMin,.XMax,.YMin,.YMax,bounds for x and y
%  .CoordMesh: typical mesh needed for automatic grids

%INPUT
% Field

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
if isfield(Field,'NbDim')
    NbDim=double(Field.NbDim);% deal with plane fields containing z coordinates
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
        XName=Field.ListVarName{CellInfo{imax(ind)}.CoordIndex(end)};
        YName=Field.ListVarName{CellInfo{imax(ind)}.CoordIndex(end-1)};
        CoordMax(ind,NbDim)=max(max(Field.(XName)));
        CoordMin(ind,NbDim)=min(min(Field.(XName)));
        CoordMax(ind,NbDim-1)=max(max(Field.(YName)));
        CoordMin(ind,NbDim-1)=min(min(Field.(YName)));
        %         test_x=1;%test for unstructured coordinates
        if NbDim==3
            ZName=Field.ListVarName{CellInfo{imax(ind)}.CoordIndex(1)};
            CoordMax(imax(ind),1)=max(max(Field.(ZName)));
            CoordMin(ind,1)=min(min(Field.(ZName)));
        end
    end
    switch CellInfo{imax(ind)}.CoordType
        
        case {'scattered','tps'} %unstructured coordinates
            NbPoints=CellInfo{imax(ind)}.CoordSize;% total nbre of points
            Mesh(ind)=(prod(CoordMax(ind,:)-CoordMin(ind,:))/NbPoints)^(1/NbDim); %(volume or area per point)^(1/NbDim)
        case 'grid'%structured coordinate
            NbPoints=CellInfo{imax(ind)}.CoordSize;% nbre of points in each direction
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
    FieldOut.ZMin=max(CoordMin(ind,1));
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