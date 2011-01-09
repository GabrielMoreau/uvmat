%'sub_field': combines two input fields
%
% the two fields are subtstracted when of the same nature (scalar or
% vector), if the coordinates do not coincide, the second field is
% interpolated on the cooridintes of the first one
%
% when scalar and vectors are combined, the fields are just merged in a single matlab structure for common visualisation
%-----------------------------------------------------------------------
% function SubData=sub_field(Field,Field_1)
%
% OUPUT: 
% SubData: structure representing the resulting field
%
% INPUT: 
% Field: matlab structure representing the first field
% Field_1:matlab structure representing the second field

function [SubData,errormsg]=sub_field(Field,Field_1)
test_attr=0;
if isfield(Field,'ListGlobalAttribute')
    SubData.ListGlobalAttribute=Field.ListGlobalAttribute;
    for ilist=1:numel(Field.ListGlobalAttribute)
        AttrName=Field.ListGlobalAttribute{ilist};
        eval(['SubData.' AttrName '=Field.' AttrName ';'])
    end
    test_attr=1;
end
if isfield(Field_1,'ListGlobalAttribute')
    for ilist=1:numel(Field_1.ListGlobalAttribute)
        test_1=1;
        AttrName=Field_1.ListGlobalAttribute{ilist};
        if test_attr
            for i_prev=1:numel(Field.ListGlobalAttribute)
                if isequal(Field.ListGlobalAttribute{i_prev},AttrName)
                    test_1=0; %attribute already written
                    eval(['Val=Field.' AttrName ';'])                  
                    eval(['Val_1=Field_1.' AttrName ';'])
                    if isequal(Val,Val_1)           
                        break% data already written
                    else
                        eval(['SubData.' AttrName '_1=Field_1.' AttrName ';']) 
                    end
                end 
            end
        end
        if test_1
            eval(['SubData.' AttrName '=Field_1.' AttrName ';']) 
        end
    end
end
SubData.ListVarName=Field.ListVarName;
SubData.VarDimName=Field.VarDimName;
if isfield(Field,'VarAttribute')
    SubData.VarAttribute=Field.VarAttribute;
end
%reproduce Field by default
for ivar=1:numel(Field.ListVarName)
   VarName=Field.ListVarName{ivar};
   eval(['SubData.' VarName '=Field.' VarName ';']) 
end

%fields     
[CellVarIndex,NbDim,VarTypeCell,errormsg]=find_field_indices(Field);
if ~isempty(errormsg)
    errormsg=['invalid  first input to sub_field:' errormsg];
    return
end
[CellVarIndex_1,NbDim_1,VarTypeCell_1,errormsg]=find_field_indices(Field_1);
if ~isempty(errormsg)
    errormsg=['invalid second input to sub_field:' errormsg];
    return
end
iselect=find(NbDim==2);
if ~isequal(numel(iselect),1)
    errormsg='invalid  first input to sub_field: it must  contain a single 2D field cell';
    return
end
iselect_1=find(NbDim_1==2);
if ~isequal(numel(iselect_1),1)
    errormsg='invalid  second input to sub_field: it must  contain a single 2D field cell';
    return
end
VarType=VarTypeCell{iselect};
VarType_1=VarTypeCell_1{iselect_1};
testX=~isempty(VarType.coord_x)&& ~isempty(VarType.coord_y);%unstructured coordiantes
testX_1=~isempty(VarType_1.coord_x)&& ~isempty(VarType_1.coord_y);%unstructured coordiantes
testU=~isempty(VarType.vector_x)&& ~isempty(VarType.vector_y);%vector field
testU_1=~isempty(VarType_1.vector_x)&& ~isempty(VarType_1.vector_y);%vector field
testfalse_1=~isempty(VarType_1.errorflag);
ivar_C=[VarType.scalar VarType.image VarType.color VarType.ancillary]; %defines index (indices) for the scalar or ancillary fields
if numel(ivar_C)>1
    errormsg='too many scalar fields in the first input of sub_field.m';
    return
end
ivar_C_1=[VarType_1.scalar VarType_1.image VarType_1.color VarType_1.ancillary]; %defines index (indices) for the scalar or ancillary fields
if numel(ivar_C_1)>1
    errormsg='too many scalar fields in the second input of sub_field.m';
    return
end

%substract two vector fields or two scalars
if (testU && testU_1) || (~testU && ~testU_1)
   %check coincidence in positions
   %unstructured coordinates for the first field
   if testX  
       XName=Field.ListVarName{VarType.coord_x};
       YName=Field.ListVarName{VarType.coord_y};
       eval(['vec_X=Field.' XName ';']) 
       eval(['vec_Y=Field.' YName ';'])
       nbpoints=numel(vec_X);
       vec_X=reshape(vec_X,nbpoints,1);
       vec_Y=reshape(vec_Y,nbpoints,1);
       if testX_1 %unstructured coordinates for the second field
            X_1_Name=Field_1.ListVarName{VarType_1.coord_x};
            Y_1_Name=Field_1.ListVarName{VarType_1.coord_y};
            eval(['vec_X_1=Field_1.' X_1_Name ';']) 
            eval(['vec_Y_1=Field_1.' Y_1_Name ';'])

       else   %structured coordinates for the second field
           y_1_Name=Field_1.ListVarName{VarType_1.coord(1)};
           x_1_Name=Field_1.ListVarName{VarType_1.coord(2)};
           eval(['y_1=Field_1.' y_1_Name ';']) 
           eval(['x_1=Field_1.' x_1_Name ';'])
           if isequal(numel(x_1),2)  
               x_1=linspace(x_1(1),x_1(2),nbpoints_x_1);
           end
           if isequal(numel(y_1),2)  
               y_1=linspace(y_1(1),y_1(2),nbpoints_y_1);
           end
           [vec_X_1,vec_Y_1]=meshgrid(x_1,y_1);
       end
       vec_X_1=reshape(vec_X_1,[],1);
       vec_Y_1=reshape(vec_Y_1,[],1);
       if testfalse_1
           FFName_1=Field_1.ListVarName{VarType_1.errorflag};          
           eval(['vec_FF_1=Field_1.' FFName_1 ';']) 
           vec_FF_1=reshape(vec_FF_1,[],1);
           indsel=find(~vec_FF_1);
           vec_X_1=vec_X_1(indsel);
           vec_Y_1=vec_Y_1(indsel);
       end
       if testU % vector fields
            U_1_Name=Field_1.ListVarName{VarType_1.vector_x};
            V_1_Name=Field_1.ListVarName{VarType_1.vector_y};
            eval(['vec_U_1=Field_1.' U_1_Name ';']) 
            eval(['vec_V_1=Field_1.' V_1_Name ';'])
            nbpoints_x_1=size(vec_U_1,2);
            nbpoints_y_1=size(vec_U_1,1);
            vec_U_1=reshape(vec_U_1,nbpoints_x_1*nbpoints_y_1,1);
            vec_V_1=reshape(vec_V_1,nbpoints_x_1*nbpoints_y_1,1);
            if testfalse_1
                vec_U_1=vec_U_1(indsel);
                vec_V_1=vec_V_1(indsel);
            end            
       else %(~testU && ~testU_1)
           A_1_Name=Field_1.ListVarName{ivar_C_1};
           eval(['vec_A_1=Field_1.' A_1_Name ';'])   
           nbpoints_x_1=size(vec_A_1,2);
           nbpoints_y_1=size(vec_A_1,1);%TODO: use a faster interpolation method for a regular grid (size(x)=2)
           vec_A_1=reshape(vec_A_1,nbpoints_x_1*nbpoints_y_1,1);
           if testfalse_1
                vec_A_1=vec_A_1(indsel);
           end
       end

       if ~isequal(vec_X_1,vec_X) && ~isequal(vec_Y_1,vec_Y) % if the unstructured positions are not the same
           if testU
               vec_U_1=griddata_uvmat(vec_X_1,vec_Y_1,vec_U_1,vec_X,vec_Y);  %interpolate vectors in the second field
               vec_V_1=griddata_uvmat(vec_X_1,vec_Y_1,vec_V_1,vec_X,vec_Y);  %interpolate vectors in the second field   
           else
               vec_A_1=griddata_uvmat(vec_X_1,vec_Y_1,double(vec_A_1),vec_X,vec_Y);  %interpolate vectors in the second field
           end
       end 
       if testU
           UName=Field.ListVarName{VarType.vector_x};
           VName=Field.ListVarName{VarType.vector_y};  
           eval(['vec_U=Field.' UName ';']) 
           eval(['vec_V=Field.' VName ';'])       
           vec_U=reshape(vec_U,numel(vec_U),1);
           vec_V=reshape(vec_V,numel(vec_V),1);
           eval(['SubData.' UName '=vec_U-vec_U_1;'])
           eval(['SubData.' VName '=vec_V-vec_V_1;'])
       else
           AName=Field.ListVarName{ivar_C};
          % size(Field.vort)
           eval(['SubData.' AName '=Field.' AName '-vec_A_1;'])
       end
   else  %structured coordiantes
       XName=Field.ListVarName{VarType.coord(2)};
       YName=Field.ListVarName{VarType.coord(1)};
       eval(['x=Field.' XName ';']) 
       eval(['y=Field.' YName ';'])
       if testX_1 %unstructured coordinates for the second field
           errormsg='the second input scalar is not on a regular grid: comparison option not implemented';
           return
       else
           XName_1=Field.ListVarName{VarType_1.coord(2)};
           YName_1=Field.ListVarName{VarType_1.coord(1)};
           eval(['x_1=Field_1.' XName_1 ';']) 
           eval(['y_1=Field_1.' YName_1 ';'])
       end
       if testU % vector fields
           UName=Field.ListVarName{VarType.vector_x};
           VName=Field.ListVarName{VarType.vector_y};
           U_1_Name=Field_1.ListVarName{VarType_1.vector_x};
           V_1_Name=Field_1.ListVarName{VarType_1.vector_y};
           eval(['U_1=Field_1.' U_1_Name ';']) 
           eval(['V_1=Field_1.' V_1_Name ';'])
           if ~isequal(x_1,x)||~isequal(y_1,y)
                [X_1,Y_1]=meshgrid(x_1,y_1);
                U_1 =interp2(X_1,Y_1,U_1,x,y');
                V_1 =interp2(X_1,Y_1,V_1,x,y');
           end
           eval(['SubData.' UName '=Field.' UName '-U_1;'])
           eval(['SubData.' VName '=Field.' VName '-V_1;'])
       else
           AName=Field.ListVarName{ivar_C};
           A_1_Name=Field_1.ListVarName{ivar_C_1};
           eval(['A_1=double(Field_1.' A_1_Name ');'])
           if ~isequal(x_1,x)||~isequal(y_1,y)
                [X_1,Y_1]=meshgrid(x_1,y_1);
                A_1 =interp2(X_1,Y_1,A_1,x,y');
           end
           eval(['SubData.' AName '=double(Field.' AName ')-A_1;'])
       end
   end
end

% merge a vector field and a scalar as second input
if testU && ~testU_1
    AName_1=Field_1.ListVarName{ivar_C_1};
    if isfield(Field_1,'VarAttribute') & numel(Field_1.VarAttribute)>=ivar_C_1
        AAttr=Field_1.VarAttribute{ivar_C_1} ;
    else
        AAttr=[];
    end
    if testX_1 %unstructured coordinate
       XName_1=Field_1.ListVarName{VarType_1.coord_x};
       YName_1=Field_1.ListVarName{VarType_1.coord_y};
       DimCell=Field_1.VarDimName([VarType_1.coord_x VarType_1.coord_y ]);
       if isfield(Field_1,'VarAttribute') 
           if numel(Field_1.VarAttribute)>=VarType_1.coord_x
                XAttr=Field_1.VarAttribute{VarType_1.coord_x}; 
           else
                XAttr=[];
           end
           if numel(Field_1.VarAttribute)>=VarType_1.coord_y
               YAttr=Field_1.VarAttribute{VarType_1.coord_y}; 
           else
               YAttr=[];
           end
           SubData.VarAttribute=[SubData.VarAttribute {XAttr} {YAttr}];
       end
    else
       XName_1=Field_1.ListVarName{VarType_1.coord(2)};
       YName_1=Field_1.ListVarName{VarType_1.coord(1)};
%        DimCell=[{YName_1} {XName_1}];
       if isfield(Field_1,'VarAttribute') 
           if numel(Field_1.VarAttribute)>=VarType_1.coord(2)
                XAttr=Field_1.VarAttribute{VarType_1.coord(2)} ;
           else
                XAttr=[];
           end
           if numel(Field_1.VarAttribute)>=VarType_1.coord(1)
               YAttr=Field_1.VarAttribute{VarType_1.coord(1)} ;
           else
               YAttr=[];
           end
           SubData.VarAttribute=[SubData.VarAttribute {YAttr} {XAttr}];
       end
    end  
    %look for previously used variable names
    XName_1_1=XName_1;%default
    YName_1_1=YName_1;%default
    AName_1_1=AName_1;%default
    for iprev=1:numel(SubData.ListVarName)
        switch SubData.ListVarName{iprev}
            case XName_1
                XName_1_1=[XName_1 '_1'];
            case YName_1
                YName_1_1=[YName_1 '_1'];
            case AName_1
                AName_1_1=[AName_1 '_1']; 
        end
    end     
    if ~testX_1
          DimCell=[{XName_1_1} {YName_1_1}];
    end
    SubData.ListVarName=[SubData.ListVarName {XName_1_1} {YName_1_1} {AName_1_1}];
    DimCell=[DimCell Field_1.VarDimName(ivar_C_1)]; %(TODO: check for dimension names)
    SubData.VarDimName=[SubData.VarDimName DimCell];
    if isfield(Field_1,'VarAttribute')
        SubData.VarAttribute=[SubData.VarAttribute {AAttr}];
    end
    eval(['SubData.' XName_1_1 '=Field_1.' XName_1 ';'])
    eval(['SubData.' YName_1_1 '=Field_1.' YName_1 ';'])
    eval(['SubData.' AName_1_1 '=Field_1.' AName_1 ';'])
end

%merge a scalar as the first input and a vector field as second input
if ~testU && testU_1
    UName_1=Field_1.ListVarName{VarType_1.vector_x};
    VName_1=Field_1.ListVarName{VarType_1.vector_y};
    UAttr=Field_1.VarAttribute{VarType_1.vector_x};
    VAttr=Field_1.VarAttribute{VarType_1.vector_y};
    if testX_1 %unstructured coordinate for the second field
       XName_1=Field_1.ListVarName{VarType_1.coord_x};
       YName_1=Field_1.ListVarName{VarType_1.coord_y};
       
       XAttr=Field_1.VarAttribute{VarType_1.coord_x};
       YAttr=Field_1.VarAttribute{VarType_1.coord_y};
%        SubData.ListVarName=[SubData.ListVarName {XName_1} {YName_1}];
       DimCell=Field_1.VarDimName([VarType_1.coord_x VarType_1.coord_y ]);
    else
       XName_1=Field_1.ListVarName{VarType_1.coord(2)};
       YName_1=Field_1.ListVarName{VarType_1.coord(1)};
       if numel(Field_1.VarAttribute)>=VarType_1.coord(2)
           XAttr=Field_1.VarAttribute{VarType_1.coord(2)};
       else
           XAttr=[];
       end
       if numel(Field_1.VarAttribute)>=VarType_1.coord(1)
           YAttr=Field_1.VarAttribute{VarType_1.coord(1)};
       else
           YAttr=[];
       end     
    end  
    %check for the existence of the same  variable name
    XName_1_1=XName_1; %default
    YName_1_1=YName_1; %default
    UName_1_1=UName_1; %default
    VName_1_1=VName_1; %default
    for iprev=1:numel(SubData.ListVarName)
        switch SubData.ListVarName{iprev}
            case XName_1
                XName_1_1=[XName_1 '_1'];
            case YName_1
                YName_1_1=[YName_1 '_1'];
            case UName_1
                UName_1_1=[UName_1 '_1'];
            case VName_1
                VName_1_1=[VName_1 '_1']; 
        end
    end     
    if ~testX_1
          DimCell=[{XName_1_1} {YName_1_1}];
    end
    SubData.ListVarName=[SubData.ListVarName {XName_1_1} {YName_1_1} {UName_1_1} {VName_1_1}];
    DimCell=[DimCell Field_1.VarDimName([VarType_1.vector_x VarType_1.vector_y ])];
    SubData.VarDimName=[SubData.VarDimName DimCell];
    if isfield(SubData,'VarAttribute')
        if ~(numel(SubData.VarAttribute)==numel(SubData.ListVarName))
            for ivar=numel(SubData.VarAttribute)+1:numel(SubData.ListVarName)-4
                SubData.VarAttribute{ivar}=[];
            end
        end
        SubData.VarAttribute=[SubData.VarAttribute {XAttr} {YAttr} {UAttr} {VAttr}];
    end
    eval(['SubData.' XName_1_1 '=Field_1.' XName_1 ';'])
    eval(['SubData.' YName_1_1 '=Field_1.' YName_1 ';'])
    eval(['SubData.' UName_1_1 '=Field_1.' UName_1 ';'])
    eval(['SubData.' VName_1_1 '=Field_1.' VName_1 ';'])  
end
  
