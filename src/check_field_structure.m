%'check_field_structure': check the validity of the field struture representation consitant with the netcdf format
%----------------------------------------------------------------------
% function [DataOut,errormsg]=check_field_structure(Data)
%
% OUTPUT:
%  Data: structure reproducing the input structure Data, with the additional elements:
%           with fields:
%
%            .ListDimName: cell listing the names of the array dimensions
%             .DimValue: array dimension values (Matlab vector with the same length as .ListDimName
%            .VarDimIndex: cell containing the set of dimension indices (in list .ListDimName) for each variable of .ListVarName
%            .VarDimName: cell containing a cell of dimension names (in list .ListDimName) for each variable of .ListVarName
% errormsg: error message which is not empty when the input structure does not have the right form
%
%INPUT:
% Data:   structure containing 
%         (optional) .ListGlobalAttribute: cell listing the names of the global attributes
%                    .Att_1,Att_2... : values of the global attributes
%         (requested)  .ListVarName: list of variable names to select (cell array of  char strings {'VarName1', 'VarName2',...} ) 
%         (requested)  .VarDimName: list of dimension names for each element of .ListVarName (cell array of string cells)                         
%         (requested) .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName


function [DataOut,errormsg]=check_field_structure(Data)
DataOut=[]; %default
errormsg=[];
if ~isstruct(Data)
    errormsg='input field is not a structure';
    return
end
if isfield(Data,'ListVarName') && iscell(Data.ListVarName)
    nbfield=numel(Data.ListVarName); 
else
    errormsg='input field does not contain the list of variables .ListVarNames';
    return
end
%check dimension names
% definition by VarDimIndex (obsolete)
% if ~isfield(Data,'VarDimName') && isfield(Data,'VarDimIndex') && isfield(Data,'ListDimName')%old convention
%     for ivar=1:nbfield
%         DimCell=Data.VarDimIndex{ivar};
%         if isnumeric(DimCell)
%             if DimCell <= numel(Data.ListDimName)
%                 Data.VarDimName{ivar}=Data.ListDimName(DimCell);
%             else                      
%                 errormsg='dimension names not defined';
%                 return 
%             end
%         else 
%             errormsg='unrecognized format for .VarDimIndex';
%         end
%     end
% end
if ~(isfield(Data,'VarDimName') && iscell(Data.VarDimName))
    errormsg='input field does not contain the list of dimensions .VarDimName';
    return
end
if isfield(Data,'DimValue')
    Data=rmfield(Data,'DimValue');
end
if isfield(Data,'VarDimName') && iscell(Data.VarDimName)
    nbdim=0;
    if numel(Data.VarDimName)==nbfield
        for ivar=1:nbfield
            VarName=Data.ListVarName{ivar};
            if ~isfield(Data,VarName)
                errormsg=['the listed variable ' VarName ' is not found'];
                return
            else             
                eval(['sizvar=size(Data.' VarName ');'])% sizvar = dimension of variable
                DimCell=Data.VarDimName{ivar};
                if ischar(DimCell)
                    DimCell={DimCell};
                elseif ~iscell(DimCell)
                    errormsg=['wrong format for .VarDimName{' num2str(ivar) ' (must be the cell of dimension names of the variable ' VarName];
                    return
                end
                nbcoord=numel(sizvar);
                if numel(DimCell)==0
                    errormsg=['empty declared dimension .VarDimName{' num2str(ivar) '} for ' VarName];
                    return
                elseif numel(DimCell)==1% one dimension declared
                    if nbcoord==2 
                        if sizvar(1)==1 
                            nbcoord=1;
                            sizvar(1)=sizvar(2);
                        elseif sizvar(2)==1
                            nbcoord=1;
                        else
                            errormsg=['1 dimension declared in .VarDimName{' num2str(ivar) '} inconsistent with the nbre of dimensions =2 of the variable ' VarName];
                            return
                        end
                    else
                          errormsg=['1 dimension declared in .VarDimName{' num2str(ivar) '} inconsistent with the nbre of dimensions =' num2str(nbcoord) ' of the variable ' VarName];
                          return      
                    end  
                else
                    if numel(DimCell)>nbcoord
                        DimCell=DimCell(end-nbcoord+1:end);%first singleton diemnsions omitted, 
                    elseif nbcoord > numel(DimCell)
                        errormsg=['nbre of declared dimensions in .VarDimName{' num2str(ivar) '} smaller than the nbre of dimensions =' num2str(nbcoord) ' of the variable ' VarName];
                        return
                    end
                end
                DimIndex=[];
                for idim=1:nbcoord %loop on the coordinates of variable #ivar   
                    DimName=DimCell{idim};
                    testprev=0;
                    for iprev=1:nbdim %check previously listed dimension names
                        if strcmp(Data.ListDimName{iprev},DimName)
                           if ~isequal(Data.DimValue(iprev),sizvar(idim))
                               if isequal(Data.DimValue(iprev),0)  % the dimension has been already detected as a range [min max]
                                   Data.DimValue(idim)=sizvar(idim); %update with actual value 
                               elseif sizvar(idim)==2 && strcmp(DimName,VarName)
                                    %case of a regularly spaced coordinate defined by the first and last values: dimension will be determined later                          
                               else
                                   errormsg=['dimension declaration inconsistent with the size =[' num2str(sizvar) '] for ' VarName];
                                   return 
                               end
                           end
                           DimIndex=[DimIndex iprev];
                           testprev=1;
                           break
                        end
                    end
                    if ~testprev % a new dimension is appended to the list
                        nbdim=nbdim+1;
                        if sizvar(idim)==2 && strcmp(DimName,VarName)
                            Data.DimValue(nbdim)=0; %to be updated for a later variable
%                             Data.VarType{ivar}='range';
                        else
                            Data.DimValue(nbdim)=sizvar(idim);
                        end
                        Data.ListDimName{nbdim}=DimName;
                        DimIndex=[DimIndex nbdim];
                    end
                end
                Data.VarDimIndex{ivar}=DimIndex;
            end
        end                               
    else
        errormsg=' .ListVarNames and .VarDimName have different lengths';
        return
    end
else
    errormsg='input field does not contain the cell of dimension names .VarDimName for variables';
    return
end
DataOut=Data;
    
   