%'read_get_field': read the list of selected variables from the GUI get_field 

% OUTPUT:
% SubField: structure with fields 
   %  .ListVarName: list of selected variables
   %  .VarDimName: cells with the  corresponding dimension names
   %  .Field1, 2...: if an input file has been opened by get_field
% errormsg: error message (=[] when no error)

% INPUT: 
% hget_field: handles of the GUI get_field

function [SubField,errormsg]=read_get_field(hget_field)
%---------------------------------------------------------
SubField=[];%default
errormsg=[]; %default
handles=guidata(hget_field);%handles of GUI elements in get_field
Field=get(hget_field,'UserData');% read the current field Structure in the get_field interface
if isfield(Field,'VarAttribute')
    VarAttribute=Field.VarAttribute;
else
    VarAttribute={};
end

% select the indices of field variables for 2D plots
test_1Dplot=get(handles.check_1Dplot,'Value');
test_scalar=get(handles.check_scalar,'Value');
test_vector=get(handles.check_vector,'Value');

nbvar=0;
empty_coord_x=0;
empty_coord_y=0;
%dimname_y={};
ListVarName={};
VarDimName={};
SubVarAttribute={};
%dim_x=0;
%dim_y=0;
dim_z=0;
%dim_vec_x=0;
%dim_vec_y=0;
%dim_vec_z=0;
%c_index=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ordinary (1D) plot
if test_1Dplot
    % select ordinate variable(s)
    inputlist=get(handles.ordinate,'String'); 
    val=get(handles.ordinate,'Value');% selection(s) for ordinate
    VarNameCell=inputlist(val); %names of the variable(s) in the list
    VarIndex_y=[];
    dim_ordinate={};
    testpermute=[];
    subvarindex=[];
    for ilist=1:length(VarNameCell)
        VarIndex_y(ilist)=name2index(VarNameCell{ilist},Field.ListVarName);%index of the variable in ListVarName
        dim_ordinate{ilist}=Field.VarDimName{VarIndex_y(ilist)};% name of the corresponding dimension
        testpermute(ilist)=0;%default
        nbvar=nbvar+1;
        ListVarName{nbvar}=Field.ListVarName{VarIndex_y(ilist)};
        VarDimName{nbvar}=Field.VarDimName{VarIndex_y(ilist)};
        subvarindex(ilist)=nbvar;
        if numel(VarAttribute)>=VarIndex_y(ilist)
            SubVarAttribute{nbvar}=VarAttribute{VarIndex_y(ilist)};
        end
        SubVarAttribute{nbvar}.Role='scalar';           
    end
    
    % select abscissa variable
    inputlist=get(handles.abscissa,'String'); 
    val=get(handles.abscissa,'Value');% a single selection is expected for abscissa
    VarName=inputlist{val}; %name of the variable in the list
    VarIndex=name2index(VarName,Field.ListVarName);%index of the variable in ListVarName
    if isempty(VarIndex)% default abscissa = matrix index
        coord_x_name=dim_ordinate{1};% name of the x coordinate = dimension of the plotted quantity
        if iscell(coord_x_name)
            coord_x_name=coord_x_name{1};
        end
        empty_coord_x=1;
    else
        dimname_x=Field.VarDimName{VarIndex};
        if numel(dimname_x)~=1
            errormsg='abscissa must be a one-dimensional variable';
            return
        end
        nbvar=nbvar+1; 
        ListVarName{nbvar}=Field.ListVarName{VarIndex};
        VarDimName{nbvar}=Field.VarDimName{VarIndex};
        if numel(VarAttribute)>=VarIndex
            SubVarAttribute{nbvar}=VarAttribute{VarIndex};
        end
        SubVarAttribute{nbvar}.Role='coord_x';
         %check consistency of ordinate dimensions
        for ilist=1:length(VarNameCell)
            if iscell(dim_ordinate{ilist})
                if ~strcmp(dim_ordinate{ilist}{1},dimname_x)
                    if strcmp(dim_ordinate{ilist}{2},dimname_x)
                        testpermute(ilist)=1;
                    else
                        errormsg='inconsistent dimensions for ordinate and abscissa';
                        return
                    end
                end
            end
        end
    end
end
test3D=strcmp(get(handles.coord_z_scalar,'Visible'),'on')||strcmp(get(handles.coord_z_vectors,'Visible'),'on');
VarSubIndexA=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%scalar field
test_xdimvar=0;%default
test_ydimvar=0;%default
test_zdimvar=0;%defaul
dimname_x=[];
dimname_y=[];
dimname_z=[];
if test_scalar
    inputlist=get(handles.scalar,'String');
    if isempty(inputlist)
        errormsg='empty input field';
        return
    end
    val=get(handles.scalar,'Value');%selected indices in the ordinate listbox
    VarNameScalar=inputlist{val}; %name of the variable in the list
    VarIndexA=name2index(VarNameScalar,Field.ListVarName);%index of the variable in ListVarName
    dimname_A=Field.VarDimName{VarIndexA};
    nbvar=nbvar+1;
    ListVarName{nbvar}=Field.ListVarName{VarIndexA};
    VarSubIndexA=nbvar;
    VarDimName{nbvar}=dimname_A;
    if numel(VarAttribute)>=VarIndexA
        SubVarAttribute{nbvar}=VarAttribute{VarIndexA};
    end
    SubVarAttribute{nbvar}.Role='scalar';
    field_var_index=VarIndexA; %store the last variable index to determine the absissa dimension if not defiend

     % select x variable 
    inputlist=get(handles.coord_x_scalar,'String'); 
    val=get(handles.coord_x_scalar,'Value');% a single selection is expected for abscissa
    VarName=inputlist{val}; %name of the variable in the list
    VarIndex=name2index(VarName,Field.ListVarName);%index of the variable in ListVarName
    if isempty(VarIndex)% default abscissa = matrix index
        empty_coord_x=1;
    else
        dimname_x=Field.VarDimName{VarIndex};
        nbvar=nbvar+1;
        ListVarName{nbvar}=Field.ListVarName{VarIndex};
        VarDimName{nbvar}=dimname_x;
        if numel(VarAttribute)>=VarIndex
            SubVarAttribute{nbvar}=VarAttribute{VarIndex};
        end
         %check consistency of dimensions
        if ~isequal(dimname_x,dimname_A)% case of dimension variables
            if iscell(dimname_x)
                if numel(dimname_x)==1
                    dimname_x=dimname_x{1};%transform to char chain
                else
                    errormsg='invalid x coordinate selection in get_field';
                    return
                end
            end
            test_xdimvar=1;
            SubVarAttribute{nbvar}.Role='dimvar';% dimension variable
        else
            SubVarAttribute{nbvar}.Role='coord_x';%abcissa with unstructured coordinates
        end
    end
    
    % select y variable
    inputlist=get(handles.coord_y_scalar,'String'); 
    val=get(handles.coord_y_scalar,'Value');% a single selection is expected for abscissa
    VarName=inputlist{val}; %name of the variable in the list    
    VarIndex=name2index(VarName,Field.ListVarName);%index of the variable in ListVarName
    if isempty(VarIndex)% default abscissa = matrix index
        empty_coord_y=1;
    else
        dimname_y=Field.VarDimName{VarIndex};
         %check consistency of dimensions
        nbvar=nbvar+1;
        ListVarName{nbvar}=Field.ListVarName{VarIndex};
        VarDimName{nbvar}=dimname_y;
        if numel(VarAttribute)>=VarIndex
            SubVarAttribute{nbvar}=VarAttribute{VarIndex};
        end
         %check consistency of dimensions
        if ~isequal(dimname_y,dimname_A)% case of dimension variables
             if iscell(dimname_y)
                if numel(dimname_y)==1
                    dimname_y=dimname_y{1};%transform to char chain
                else
                    errormsg='invalid y coordinate selection in get_field';
                    return
                end
             end
            test_ydimvar=1;
            SubVarAttribute{nbvar}.Role='dimvar';% dimension variable
        else
            SubVarAttribute{nbvar}.Role='coord_y';%abcissa with unstructured coordinates
        end
        if isequal(dimname_y,dimname_x)
            errormsg='identical x and y coordinates selected in get_field';
            return
        end
    end

        % select z variable
   if test3D % TODO: Lire z comme x et y
        inputlist=get(handles.coord_z_scalar,'String'); 
        val=get(handles.coord_z_scalar,'Value');% a single selection is expected for abscissa
        VarName=inputlist{val}; %name of the variable in the list    
        VarIndex=name2index(VarName,Field.ListVarName);%index of the variable in ListVarName
        if isempty(VarIndex)% default abscissa = matrix index
%             coord_z_name=dimname_A{1};% name of the x coordinate = dimension of the plotted quantity
%            empty_coord_z=1;
        else
            dimname_z=Field.VarDimName{VarIndex};
             %check consistency of dimensions
            if ~isequal(dimname_z,dimname_A)
                for icoord=1:numel(dimname_A)
                    if strcmp(dimname_z,dimname_A{icoord})%  a dimension variable
                         dim_z=icoord;
                        break
                    end
                end
                if ~dim_z
                    errormsg='inconsistent dimensions for coordinate z';
                    return
                end
            end
            nbvar=nbvar+1;
            ListVarName{nbvar}=Field.ListVarName{VarIndex};
            VarDimName{nbvar}=dimname_z;
            if numel(VarAttribute)>=VarIndex
                SubVarAttribute{nbvar}=VarAttribute{VarIndex};
            end
            if dim_z
                SubVarAttribute{nbvar}.Role='dimvar';% dimension variable
            else
                SubVarAttribute{nbvar}.Role='coord_z';%z coordinate with unstructured coordinates
            end
        end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vectors
% test_vec_x_dimvar=0;%default
% test_vec_y_dimvar=0;%default
% test_vec_z_dimvar=0;%defaul
dimname_vec_x=[];
dimname_vec_y=[];
dimname_vec_z=[];
if test_vector 
    %select u variable
    inputlist=get(handles.vector_x,'String');
    if isempty(inputlist)
        errormsg='empty input field';
        return
    end
    val=get(handles.vector_x,'Value');%selected indices in the ordinate listbox
    VarNameU=inputlist{val}; %name of the variable in the list
    VarIndexU=name2index(VarNameU,Field.ListVarName);%index of the variable in ListVarName
    nbvar=nbvar+1;
    VarSubIndexU=nbvar;
    ListVarName{nbvar}=Field.ListVarName{VarIndexU};
    dimname_u=Field.VarDimName{VarIndexU};
    VarDimName{nbvar}=dimname_u;
    if numel(VarAttribute)>=VarIndexU
        SubVarAttribute{nbvar}=VarAttribute{VarIndexU};
    end
    SubVarAttribute{nbvar}.Role='vector_x';
    field_var_index=VarIndexU; %store the last variable index to determine the absissa dimension if not defiend
    
    %scalar v variable
    inputlist=get(handles.vector_y,'String');
    val=get(handles.vector_y,'Value');%selected indices in the ordinate listbox
    VarNameV=inputlist{val}; %name of the variable in the list
    VarIndexV=name2index(VarNameV,Field.ListVarName);%index of the variable in ListVarName 
     %check consistency of dimensions with u
    dimname_v=Field.VarDimName{VarIndexV};
    if ~isequal(dimname_v,dimname_u)
       errormsg='inconsistent dimensions for u and v';
        return
    end
    nbvar=nbvar+1;
    VarSubIndexV=nbvar;
    ListVarName{nbvar}=Field.ListVarName{VarIndexV};
    VarDimName{nbvar}=dimname_u;
    if numel(VarAttribute)>=VarIndexV
        SubVarAttribute{nbvar}=VarAttribute{VarIndexV};
    end
    SubVarAttribute{nbvar}.Role='vector_y';    
 
    % select x variable for vector
    inputlist=get(handles.coord_x_vectors,'String'); 
    val=get(handles.coord_x_vectors,'Value');% a single selection is expected for abscissa
    VarName=inputlist{val}; %name of the variable in the list
    VarIndex=name2index(VarName,Field.ListVarName);%index of the variable in ListVarName
    if isempty(VarIndex)% default abscissa = matrix indexTODO like scalar
        empty_coord_vec_x=1;
    else
        empty_coord_vec_x=0;
        dimname_vec_x=Field.VarDimName{VarIndex};
        nbvar=nbvar+1;
        ListVarName{nbvar}=Field.ListVarName{VarIndex};
        VarDimName{nbvar}=dimname_vec_x;
        if numel(VarAttribute)>=VarIndex
            SubVarAttribute{nbvar}=VarAttribute{VarIndex};
        end
         %check consistency of dimensions
        if ~isequal(dimname_vec_x,dimname_u)% case of dimension variables
            if iscell(dimname_vec_x)
                if numel(dimname_vec_x)==1
                    dimname_vec_x=dimname_vec_x{1};%transform to char chain
                else
                    errormsg='invalid x coordinate selection in get_field';
                    return
                end
            end
%             test_vec_x_dimvar=1;
            SubVarAttribute{nbvar}.Role='dimvar';% dimension variable
        else
            SubVarAttribute{nbvar}.Role='coord_x';%abcissa with unstructured coordinates
        end
    end
        
     % select y variable for vector
    inputlist=get(handles.coord_y_vectors,'String'); 
    val=get(handles.coord_y_vectors,'Value');% a single selection is expected for abscissa
    VarName=inputlist{val}; %name of the variable in the list
    VarIndex=name2index(VarName,Field.ListVarName);%index of the variable in ListVarName
    if isempty(VarIndex)% default abscissa = matrix indexTODO like scalar
        empty_coord_vec_y=1;
    else
        empty_coord_vec_y=0;
        dimname_vec_y=Field.VarDimName{VarIndex};
        nbvar=nbvar+1;
        ListVarName{nbvar}=Field.ListVarName{VarIndex};
        VarDimName{nbvar}=dimname_vec_y;
        if numel(VarAttribute)>=VarIndex
            SubVarAttribute{nbvar}=VarAttribute{VarIndex};
        end
         %check consistency of dimensions
        if ~isequal(dimname_vec_y,dimname_u)% case of dimension variables
            if iscell(dimname_vec_y)
                if numel(dimname_vec_y)==1
                    dimname_vec_y=dimname_vec_y{1};%transform to char chain
                else
                    errormsg='invalid y coordinate selection in get_field';
                    return
                end
            end
%             test_vec_y_dimvar=1;
            SubVarAttribute{nbvar}.Role='dimvar';% dimension variable
        else
            SubVarAttribute{nbvar}.Role='coord_y';%abcissa with unstructured coordinates
        end
    end    
        
     % select z variable for vector
    if test3D
        inputlist=get(handles.coord_z_vectors,'String'); 
        val=get(handles.coord_z_vectors,'Value');% a single selection is expected for abscissa
        VarName=inputlist{val}; %name of the variable in the list
        VarIndex=name2index(VarName,Field.ListVarName);%index of the variable in ListVarName
        if isempty(VarIndex)% default abscissa = matrix indexTODO like scalar
    %         coord_x_name=dimname_u{2};% name of the x coordinate = dimension of the plotted quantity
%             empty_coord_vec_z=1;
        else
            dimname_vec_z=Field.VarDimName{VarIndex};
            nbvar=nbvar+1;
            ListVarName{nbvar}=Field.ListVarName{VarIndex};
            VarDimName{nbvar}=dimname_vec_z;
            if numel(VarAttribute)>=VarIndex
                SubVarAttribute{nbvar}=VarAttribute{VarIndex};
            end
             %check consistency of dimensions
            if ~isequal(dimname_vec_z,dimname_u)% case of dimension variables
                if iscell(dimname_vec_z)
                    if numel(dimname_vec_z)==1
                        dimname_vec_z=dimname_vec_y{1};%transform to char chain
                    else
                        errormsg='invalid y coordinate selection in get_field';
                        return
                    end
                end
%                 test_vec_z_dimvar=1;
                SubVarAttribute{nbvar}.Role='dimvar';% dimension variable
            else
                SubVarAttribute{nbvar}.Role='coord_z';%abcissa with unstructured coordinates
            end
        end        
    end   
            
    if test3D %  (a revoir)  
         %scalar w variable
        inputlist=get(handles.vector_z,'String');
        val=get(handles.vector_z,'Value');%selected indices in the ordinate listbox
        VarNameW=inputlist{val}; %name of the variable in the list
        VarIndex=name2index(VarNameW,Field.ListVarName);%index of the variable in ListVarName 
         %check consistency of dimensions with u
        dimname_w=Field.VarDimName{VarIndex};
        if ~isequal(dimname_w,dimname_u)
           errormsg='inconsistent dimensions for u and v';
            return
        end
        nbvar=nbvar+1;
%         w_index=nbvar;
        ListVarName{nbvar}=Field.ListVarName{VarIndex};
        VarDimName{nbvar}=dimname_u;
        if numel(VarAttribute)>=VarIndex
            SubVarAttribute{nbvar}=VarAttribute{VarIndex};
        end
        SubVarAttribute{nbvar}.Role='vector_z';
    end  
    
    % select color variable
    inputlist=get(handles.vec_color,'String'); 
    val=get(handles.vec_color,'Value');% a single selection is expected for abscissa
    VarNameC=inputlist{val}; %name of the variable in the list
    VarIndex=name2index(VarNameC,Field.ListVarName);%index of the variable in ListVarName
       %check consistency of dimensions with u
    if ~isempty(VarIndex)
        if ~isequal(Field.VarDimName{VarIndex},dimname_u)
            errormsg='inconsistent dimensions for u and v';
            return
        end
        nbvar=nbvar+1;
%         c_index=nbvar;
        ListVarName{nbvar}=Field.ListVarName{VarIndex};
        VarDimName{nbvar}=Field.VarDimName{VarIndex};
        if numel(VarAttribute)>=VarIndex
            SubVarAttribute{nbvar}=VarAttribute{VarIndex};
        end
        SubVarAttribute{nbvar}.Role='scalar';
    end
end 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the input field
inputfield=get(handles.inputfile,'String');
if exist(inputfield,'file')% read the input data corresponding to the list of selected varaibles
    SubField=nc2struct(inputfield,ListVarName);
else  % subfield stored in memory
    SubField.ListGlobalAttribute={};
    SubField.ListVarName=ListVarName;
    SubField.VarDimName=VarDimName;
end
SubField.ListGlobalAttribute=['InputFile' SubField.ListGlobalAttribute];
SubField.InputFile=get(handles.inputfile,'String');
SubField.VarAttribute=SubVarAttribute;

%permute indices if coord_y is not the first matrix index: scalar case
if test_scalar
    VarNameA=Field.ListVarName{VarIndexA};
    DimCellA=Field.VarDimName{VarIndexA};   
    eval(['npxy=size(SubField.' VarNameA ')'])
    SingleCellA={};
    if numel(npxy) < numel(DimCellA)
        SingleCellA=DimCellA(1:end-numel(npxy));
        DimCellA=DimCellA(end-numel(npxy)+1:end); %suppress the first singletons) dimensions
    end
    ind_single=find(npxy==1);
    SingleCellA=[SingleCellA DimCellA(ind_single)];
    ind_select=find(npxy~=1);%look for non singleton dimensions
    DimCellA=DimCellA(ind_select);
    npxy=npxy(ind_select);
    dimA=[];
    if test_zdimvar%dim_x && dim_y && ~isempty(VarSubIndexA)
        for icoord=1:numel(SingleCellA)% look for coincidence of dimension with one of the dimensions of the scalar 
            if strcmp(dimname_z,SingleCellA{icoord})% a singleton dimension
                errormsg=['the singleton dimension ' dimname_z ' has been selected for z'];
                return
            end
        end
        for icoord=1:numel(DimCellA)% look for coincidence of dimension with one of the dimensions of the scalar 
             if strcmp(dimname_z,DimCellA{icoord})% a dimension variable
                 dimA=[dimA icoord];
                 break
             end
        end
    end
    if test_ydimvar%dim_x && dim_y && ~isempty(VarSubIndexA)
        for icoord=1:numel(SingleCellA)% look for coincidence of dimension with one of the dimensions of the scalar 
            if strcmp(dimname_y,SingleCellA{icoord})% a singleton dimension
                errormsg=['the singleton dimension ' dimname_y ' has been selected for ordiante'];
                return
            end
        end
        for icoord=1:numel(DimCellA)% look for coincidence of dimension with one of the dimensions of the scalar 
             if strcmp(dimname_y,DimCellA{icoord})% a dimension variable
                 dimA=[dimA icoord];
                 break
             end
        end
    end
    if test_xdimvar%dim_x && dim_y && ~isempty(VarSubIndexA)
        for icoord=1:numel(SingleCellA)% look for coincidence of dimension with one of the dimensions of the scalar
            if strcmp(dimname_x,SingleCellA{icoord})% a singleton dimension
                errormsg=['the singleton dimension ' dimname_x ' has been selected for abscissa'];
                return
            end
        end
        for icoord=1:numel(DimCellA)% look for coincidence of dimension with one of the dimensions of the scalar 
             if strcmp(dimname_x,DimCellA{icoord})% a dimension variable
                 dimA=[dimA icoord];
                 break
             end
        end
    end
    dimextra=(1:numel(DimCellA));
    dimextra(dimA)=[]; %list of unselected dimension indices
    DimCellA=DimCellA([dimA dimextra]);
    eval(['SubField.' VarNameA '=permute(squeeze(SubField.' VarNameA '),[dimA dimextra]);'])
    SubField.VarDimName{VarSubIndexA}=DimCellA;  
    %add default coord_x and/or coord_y if empty
    if empty_coord_x || empty_coord_y
        VarName=Field.ListVarName{field_var_index};
        DimCell=Field.VarDimName{field_var_index};    
        eval(['npxy=size(SubField.' VarName ')'])
        if numel(npxy) < numel(DimCell)
            DimCell=DimCell(end-numel(npxy)+1:end); %suppress the first singletons) dimensions 
        end
        ind_select=find(npxy~=1) ;%look for non singleton dimensions
        DimCell=DimCell(ind_select);
        npxy=npxy(ind_select);
        testold=0;
    %old convention; use of coord_1 and Coord_2
        if isfield(Field,'VarAttribute') && numel(Field.VarAttribute)>=field_var_index
            if isfield(Field.VarAttribute{field_var_index},'Coord_2')&& isfield(Field.VarAttribute{field_var_index},'Coord_1')
%                 Coord_2=Field.VarAttribute{field_var_index}.Coord_2;
%                 Coord_1=Field.VarAttribute{field_var_index}.Coord_1;
                testold=1;
            end
        end
        if empty_coord_x        
                coord_x_name=DimCell{2};
                SubField.ListVarName=[{coord_x_name} SubField.ListVarName];
                SubField.VarDimName=[{coord_x_name} SubField.VarDimName];  
                if testold
                    eval(['SubField.' coord_x_name '=linspace(Coord_2(1),Coord_2(end),npxy(2));'])
                else
                    eval(['SubField.' coord_x_name '=[0.5 npxy(2)-0.5];'])
                end
            
            if ~testold
                coord_x_attr.units='index';
            else
                coord_x_attr.units='cm';
            end
            SubField.VarAttribute=[{coord_x_attr} SubField.VarAttribute];  
        end
        if empty_coord_y 
            coord_y_name=DimCell{1};
            SubField.ListVarName=[{coord_y_name} SubField.ListVarName];
            SubField.VarDimName=[{coord_y_name} SubField.VarDimName];
            if testold
                eval(['SubField.' coord_y_name '=linspace(Coord_1(1),Coord_1(end),npxy(1));']) 
            else
                eval(['SubField.' coord_y_name '=[npxy(1)-0.5 0.5];'])
            end
            if ~testold
                coord_y_attr.units='index';
            else
                coord_y_attr.units='cm';
            end
            SubField.VarAttribute=[{coord_y_attr} SubField.VarAttribute];       
        end
    end
end

%permute indices if coord_y is not the first matrix index: vector case
if test_vector
    VarNameU=Field.ListVarName{VarIndexU}; % name of u component variable
    DimCellU=Field.VarDimName{VarIndexU}; % list of dimensions for u component  
    eval(['npxy=size(SubField.' VarNameU ')']) % npxy= dimension values for the u component
    SingleCellU={};
    if numel(npxy) < numel(DimCellU)
        SingleCellU=DimCellU(1:end-numel(npxy));
        DimCellU=DimCellU(end-numel(npxy)+1:end); %suppress the first singletons) dimensions
    end
    ind_single=find(npxy==1);%indices of singleton dimensions
    if ind_single<=numel(DimCellU)
        SingleCellU=[SingleCellU DimCellU(ind_single)];
    end
    ind_select=find(npxy~=1);%look for non singleton dimensions
    DimCellU=DimCellU(ind_select);
    npxy=npxy(ind_select);
    dimU=[];
    if test_zdimvar%dim_x && dim_y && ~isempty(VarSubIndexA)
        for icoord=1:numel(SingleCellU)% look for coincidence of dimension with one of the dimensions of the scalar 
            if strcmp(dimname_vec_z,SingleCellU{icoord})% a singleton dimension
                errormsg=['the singleton dimension ' dimname_vec_z ' has been selected for z'];
                return
            end
        end
        for icoord=1:numel(DimCellU)% look for coincidence of dimension with one of the dimensions of the scalar 
             if strcmp(dimname_vec_z,DimCellU{icoord})% a dimension variable
                 dimU=[dimU icoord];
                 break
             end
        end
    end
    if test_ydimvar%dim_x && dim_y && ~isempty(VarSubIndexA)
        for icoord=1:numel(SingleCellU)% look for coincidence of dimension with one of the dimensions of the scalar 
            if strcmp(dimname_vec_y,SingleCellU{icoord})% a singleton dimension
                errormsg=['the singleton dimension ' dimname_vec_y ' has been selected for ordinate'];
                return
            end
        end
        for icoord=1:numel(DimCellU)% look for coincidence of dimension with one of the dimensions of the scalar 
             if strcmp(dimname_vec_y,DimCellU{icoord})% a dimension variable
                 dimU=[dimU icoord];
                 break
             end
        end
    end
    if test_xdimvar
        for icoord=1:numel(SingleCellU)% look for coincidence of dimension with one of the dimensions of the scalar
            if strcmp(dimname_x,SingleCellU{icoord})% a singleton dimension
                errormsg=['the singleton dimension ' dimname_vec_x ' has been selected for abscissa'];
                return
            end
        end
        for icoord=1:numel(DimCellA)% look for coincidence of dimension with one of the dimensions of the scalar 
             if strcmp(dimname_vec_x,DimCellU{icoord})% a dimension variable
                 dimU=[dimU icoord];
                 break
             end
        end
    end
    if numel(DimCellU)>1
        dimextra=(1:numel(DimCellU));
        dimextra(dimU)=[]; %list of unselected dimension indices
        DimCellU=DimCellU([dimU dimextra]);
        eval(['SubField.' VarNameU '=permute(squeeze(SubField.' VarNameU '),[dimU dimextra]);'])
        eval(['SubField.' VarNameV '=permute(squeeze(SubField.' VarNameV '),[dimU dimextra]);'])
        SubField.VarDimName{VarSubIndexU}=DimCellU;
        SubField.VarDimName{VarSubIndexV}=DimCellU;
    end
    %add default coord_x and/or coord_y if empty
    if empty_coord_vec_x || empty_coord_vec_y
        VarName=Field.ListVarName{field_var_index};
        DimCell=Field.VarDimName{field_var_index};    
        eval(['npxy=size(SubField.' VarName ')'])
        if numel(npxy) < numel(DimCell)
            DimCell=DimCell(end-numel(npxy)+1:end); %suppress the first singletons) dimensions 
        end
        ind_select=find(npxy~=1) ;%look for non singleton dimensions
        DimCell=DimCell(ind_select);
        npxy=npxy(ind_select);
        testold=0;
    %old convention; use of coord_1 and Coord_2
        if isfield(Field,'VarAttribute') && numel(Field.VarAttribute)>=field_var_index
            if isfield(Field.VarAttribute{field_var_index},'Coord_2')&& isfield(Field.VarAttribute{field_var_index},'Coord_1')
%                 Coord_2=Field.VarAttribute{field_var_index}.Coord_2;
%                 Coord_1=Field.VarAttribute{field_var_index}.Coord_1;
                testold=1;
            end
        end
        if empty_coord_vec_x        
                coord_x_name=DimCell{2};
                SubField.ListVarName=[{coord_x_name} SubField.ListVarName];
                SubField.VarDimName=[{coord_x_name} SubField.VarDimName];  
                if testold
                    eval(['SubField.' coord_x_name '=linspace(Coord_2(1),Coord_2(end),npxy(2));'])
                else
                    eval(['SubField.' coord_x_name '=[0.5 npxy(2)-0.5];'])
                end
            
            if ~testold
                coord_x_attr.units='index';
            else
                coord_x_attr.units='cm';
            end
            SubField.VarAttribute=[{coord_x_attr} SubField.VarAttribute];  
        end
        if empty_coord_vec_y 
            coord_y_name=DimCell{1};
            SubField.ListVarName=[{coord_y_name} SubField.ListVarName];
            SubField.VarDimName=[{coord_y_name} SubField.VarDimName];
            if testold
                eval(['SubField.' coord_y_name '=linspace(Coord_1(1),Coord_1(end),npxy(1));']) 
            else
                eval(['SubField.' coord_y_name '=[npxy(1)-0.5 0.5];'])
            end
            if ~testold
                coord_y_attr.units='index';
            else
                coord_y_attr.units='cm';
            end
            SubField.VarAttribute=[{coord_y_attr} SubField.VarAttribute];       
        end
    end
end
if test_1Dplot 
    for ilist=1:numel(VarIndex_y)
        VarName=Field.ListVarName{VarIndex_y(ilist)};
        eval(['npxy=size(SubField.' VarName ');'])
        ind_select=find(npxy~=1);
        SubField.VarDimName{subvarindex(ilist)}=SubField.VarDimName{subvarindex(ilist)}(ind_select);
        eval(['SubField.' VarName '=squeeze(SubField.' VarName ');'])%remove singleton dimensions
        if testpermute(ilist)
            eval(['SubField.' VarName '=permute(SubField.' VarName ',[2 1]);'])
            subvarindex(ilist)
            SubField.VarDimName{subvarindex(ilist)}
            SubField.VarDimName{subvarindex(ilist)}=SubField.VarDimName{subvarindex(ilist)}([2 1]);
        end
    end
    if empty_coord_x
        SubField.ListVarName=[{[coord_x_name '_index']} SubField.ListVarName];
        SubField.VarDimName=[{coord_x_name } SubField.VarDimName];
        VarName=Field.ListVarName{VarIndex_y(1)};
        DimCell=Field.VarDimName{VarIndex_y(1)};    
        eval(['npxy=size(SubField.' VarName ')'])
        if numel(npxy) < numel(DimCell)
%             DimCell=DimCell(end-numel(npxy)+1:end); %suppress the first singletons) dimensions 
        end
%         ind_select=find(npxy~=1) ;%look for non singleton dimensions
%         DimCell=DimCell(ind_select);
%         npxy=npxy(ind_select);
        if isfield(Field,'VarAttribute') && numel(Field.VarAttribute)>=VarIndex_y(1) ...
                             && isfield(Field.VarAttribute{VarIndex_y(1)},'Coord_1')
%              Coord_1=Field.VarAttribute{VarIndex_y(1)}.Coord_1;%old convention; use of coord_1 
             eval(['SubField.' coord_x_name '_index=linspace(Coord_1(1),Coord_1(end),npxy(1));']) 
        else
            eval(['SubField.' coord_x_name '_index=linspace(0.5,npxy(1)-0.5,npxy(1));']) 
        end
        struct.Role='coord_x';
        SubField.VarAttribute=[{struct} SubField.VarAttribute];
    end
end

%-------------------------------------------------
% give index numbers of the strings str in the list ListvarName
function VarIndex_y=name2index(cell_str,ListVarName)
VarIndex_y=[];
if ischar(cell_str)
    for ivar=1:length(ListVarName)
        varlist=ListVarName{ivar};
        if isequal(varlist,cell_str)
            VarIndex_y= ivar;
            break
        end
    end
elseif iscell(cell_str)
    for isel=1:length(cell_str)
        varsel=cell_str{isel};
        for ivar=1:length(ListVarName)
            varlist=ListVarName{ivar};
            if isequal(varlist,varsel)
                VarIndex_y=[VarIndex_y ivar];
            end
        end
    end
end