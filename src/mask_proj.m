%'mask_proj': restrict input fields to a mask region, set to 0 outside 
%--------------------------------------------------------------------------
%  function [ProjData,errormsg]=mask_proj(FieldData,MaskData)
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This file is part of the toolbox UVMAT.
% 
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

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
DX=(MaskData.AX(2)-MaskData.AX(1))/(Npx-1);
DY=(MaskData.AY(2)-MaskData.AY(1))/(Npy-1);
for icell=1:numel(CellInfo)
    if NbDimArray(icell)==2
        switch CellInfo{icell}.CoordType;
            case  'scattered'
                XName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(1)};
                YName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(2)};
                mask_ind_i=round(0.5+(FieldData.(XName)-MaskData.AX(1))/DX);%nbpoint terms
                mask_ind_j=round(0.5+(FieldData.(YName)-MaskData.AY(1))/DY);%nbpoint terms
                checkin=mask_ind_j+Npy*(mask_ind_i-1);%array  of mask indices for the nbpoints
                checkin=checkin(mask_ind_i>=1 & mask_ind_i<=Npx & mask_ind_j>=1 & mask_ind_j<=Npy);%reduced array  of mask indices (inside the image)
                checkfalse=true(size(FieldData.(XName)));
                MaskData.A=reshape(MaskData.A,1,[]);
                checkfalse(MaskData.A(checkin)>200)=0;
                if ~isfield(FieldData,'FF')
                    FieldData.FF=zeros(size(FieldData.(XName)));
                    FieldData.ListVarName=[FieldData.ListVarName {'FF'}];
                    FieldData.VarDimName=[FieldData.VarDimName FieldData.VarDimName(CellInfo{icell}.CoordIndex(1))];
                    FieldData.VarAttribute{numel(FieldData.VarDimName)}.Role='errorflag';
                end
                for ivar=1:numel(CellInfo{icell}.VarIndex)
                    VarName=FieldData.ListVarName{CellInfo{icell}.VarIndex(ivar)};
                    FieldData.(VarName)(checkfalse)=0;
                    FieldData.FF(checkfalse)=1;
                end
            case  'grid'
                XName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(1)};
                YName=FieldData.ListVarName{CellInfo{icell}.CoordIndex(2)};
                Var1Name=FieldData.ListVarName{CellInfo{icell}.VarIndex(1)};
                [Npy_field,Npx_field]=size(FieldData.(Var1Name));
                DX_field=(FieldData.(XName)(end)-FieldData.(XName)(1))/(Npx_field-1);
                DY_field=(FieldData.(YName)(end)-FieldData.(YName)(1))/(Npy_field-1);
                XArray=FieldData.(XName)(1):DX_field:FieldData.(XName)(end);
                YArray=FieldData.(YName)(1):DY_field:FieldData.(YName)(end);
                XMask=MaskData.AX(1):DX:MaskData.AX(end);
                YMask=MaskData.AY(end):-DY:MaskData.AY(1);
                [XMask,YMask]=meshgrid(XMask,YMask);
                Mask = interp2(XMask,YMask,MaskData.A,XArray,YArray','nearest');
%                 figure(1)
%                 image(MaskData.A)
                Mask=Mask>200;
                if ~isfield(FieldData,'FF')
                    FieldData.FF=zeros(size(FieldData.(XName)));
                    FieldData.ListVarName=[FieldData.ListVarName {'FF'}];
                    FieldData.VarDimName=[FieldData.VarDimName FieldData.VarDimName(CellInfo{icell}.CoordIndex(1))];
                    FieldData.VarAttribute{numel(FieldData.VarDimName)}.Role='errorflag';
                end
                for ivar=1:numel(CellInfo{icell}.VarIndex)
                    VarName=FieldData.ListVarName{CellInfo{icell}.VarIndex(ivar)};
                    FieldData.(VarName)=FieldData.(VarName).*Mask;
                    FieldData.FF=~Mask;
                end
        end
    end
end
        

