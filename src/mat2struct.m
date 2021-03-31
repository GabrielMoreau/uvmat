%'mat2struct': read a matlab file .mat as a structure similar to the output
%of nc2struct
%----------------------------------------------------------------------
function Field=mat2struct(filename,ListFieldName)

Field=load(filename);%case of .mat data file
if ~exist('ListFieldName','var')
    ListFieldName=fieldnames(Field);
end
ivar=0;
Field.DimValue=[];
Field.ListGlobalAttribute={};
Field.ListVarName={};
ndim=0;
for ilist=1:numel(ListFieldName)
    if isnumeric(Field.(ListFieldName{ilist})) && numel(Field.(ListFieldName{ilist}))>=2
        ivar=ivar+1;
        Field.ListVarName=[Field.ListVarName ListFieldName{ilist}];
        ndim_var=0;
        for idim=1:ndims(Field.(ListFieldName{ilist}))
            sizevar=size(Field.(ListFieldName{ilist}),idim);
            if sizevar>1% avoid singleton dimensions
                ndim_var=ndim_var+1;
                prevdim_index=find(Field.DimValue==sizevar);%look for the same value of dimension
                if isempty(prevdim_index)% new dimension detected
                    ndim=ndim+1;
                    Field.DimValue(ndim)=sizevar;
                    Field.ListDimName{ndim}=num2str(sizevar);
                    Field.VarDimName{ivar}{ndim_var}=Field.ListDimName{ndim};
                else
                    Field.VarDimName{ivar}{ndim_var}=Field.ListDimName{prevdim_index};
                end
            end
        end
        Field.VarType(ivar)=5;%for double variable
    else
        Field.ListGlobalAttribute=[Field.ListGlobalAttribute ListFieldName{ilist}];
    end
end