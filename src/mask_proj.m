%'mask_proj': restrict input fields to a mask region, set to 0 outside 
%--------------------------------------------------------------------------
%  function [ProjData,errormsg]=mask_proj(FieldData,MaskData)

%=======================================================================
% Copyright 2008-2017, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [ProjData,errormsg]=mask_proj(FieldData,MaskData)
errormsg='';%default
ProjData=FieldData;


%% group the variables (fields of 'FieldData') in cells of variables with the same dimensions
[CellInfo,NbDimArray,errormsg]=find_field_cells(FieldData);
if ~isempty(errormsg)
    errormsg=['error in proj_field/proj_plane:' errormsg];
    return
end
[Npy,Npx]=size(MaskData.A);

for icell=1:numel(CellInfo)
    if NbDimArray(icell)==2
        if isfield(CellInfo{icell},'VarIndex_errorflag')
            FFName=FieldData.ListVarName{CellInfo{icell}.VarIndex_errorflag};
            check_new_error_flag=0;
        else
            FFName='FF';%default error (mask) flag name (if not already used)
            if isfield(FieldData,'FF')
                ind=1;
                while isfield(FieldData,['FF_' num2str(ind)])
                    ind=ind+1;
                end
                FFName=['FF_' num2str(ind)];% append an index to the name of error flag, FF_1,FF_2...
            end
            ProjData.ListVarName=[FieldData.ListVarName {FFName}];
            ProjData.VarAttribute{numel(ProjData.ListVarName)}.Role='errorflag';
            check_new_error_flag=1;
        end
        switch CellInfo{icell}.CoordType;
            case  'scattered'   
                XName=FieldData.ListVarName{CellInfo{icell}.Coord_x};
                YName=FieldData.ListVarName{CellInfo{icell}.Coord_y};
                DX=(MaskData.Coord_x(2)-MaskData.Coord_x(1))/(Npx-1);
                DY=(MaskData.Coord_y(2)-MaskData.Coord_y(1))/(Npy-1);
                mask_ind_i=round(0.5+(FieldData.(XName)-MaskData.Coord_x(1))/DX);%nbpoint terms
                mask_ind_j=round(0.5+(FieldData.(YName)-MaskData.Coord_y(1))/DY);%nbpoint terms
                checkin=mask_ind_j+Npy*(mask_ind_i-1);%array  of mask indices for the nbpoints
                checkin=checkin(mask_ind_i>=1 & mask_ind_i<=Npx & mask_ind_j>=1 & mask_ind_j<=Npy);%reduced array  of mask indices (inside the image)
                checkfalse=true(size(FieldData.(XName)));
                MaskData.A=reshape(MaskData.A,1,[]);
                checkfalse(MaskData.A(checkin)>200)=0;
                for ivar=1:numel(CellInfo{icell}.VarIndex)
                    VarName=FieldData.ListVarName{CellInfo{icell}.VarIndex(ivar)};
                    ProjData.(VarName)(checkfalse)=0;
                end
                if check_new_error_flag% an error flag needs to be created in the current cell
                    ProjData.(FFName)=zeros(size(ProjData.(VarName)));
                    ProjData.VarDimName=[FieldData.VarDimName FieldData.VarDimName(CellInfo{icell}.VarIndex(1))];
                end
                ProjData.(FFName)(checkfalse)=1;% update the existing error flag             
            case  'grid'
                XName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(2)};
                YName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(1)};
                Var1Name=FieldData.ListVarName{CellInfo{icell}.VarIndex(1)};
                [Npy_field,Npx_field]=size(FieldData.(Var1Name));
                XArray=linspace(FieldData.(XName)(1),FieldData.(XName)(end),Npx_field);
                YArray=linspace(FieldData.(YName)(1),FieldData.(YName)(end),Npy_field);
                XMask=linspace(MaskData.Coord_x(1),MaskData.Coord_x(end),Npx);
                YMask=linspace(MaskData.Coord_y(1),MaskData.Coord_y(end),Npy);
                [XMask,YMask]=meshgrid(XMask,YMask);
                Mask = interp2(XMask,YMask,MaskData.A,XArray,YArray','nearest');
                Mask=Mask>200;                
                for ivar=1:numel(CellInfo{icell}.VarIndex)
                    VarName=FieldData.ListVarName{CellInfo{icell}.VarIndex(ivar)};
                    if ~strcmp(VarName,FFName)
                        ProjData.(VarName)=FieldData.(VarName).*Mask;
                    end
                end
                if check_new_error_flag% an error flag needs to be created in the current cell
                    ProjData.(FFName)= ~Mask;
                    ProjData.VarDimName=[FieldData.VarDimName FieldData.VarDimName(CellInfo{icell}.VarIndex(1))];
                else
                    ProjData.(FFName)=FieldData.(FFName) | ~Mask;
                end
        end
    end
end


