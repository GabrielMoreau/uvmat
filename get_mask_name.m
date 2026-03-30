% get_mask_name: determine the name of the mask file for frame indices i_index and j_index
%
% maskname=get_mask_name(MaskRootName,i_index,j_index,IndexPeriod,NbSlice,CheckVolumeScan)
% OUTPUT: 
% 'maskname': name of the mask or background file
% INPUT:
% MaskRootName: root name of the mask
% i_index: i index of the field to mask
% j_index: j_index of the field to mask
% IndexPeriod: period of the i_index for which a background has been determined
% NbSlice: number of slices 
% CheckVolumeScan =false for multi-level mode (the i index gives the plane
% position modulo NbSlice)
% =true: the j index gives the plane position
%------------------------------------------------------------------------
function maskname=get_mask_name(MaskRootName,i_index,j_index,NbSlice,CheckVolumeScan)
[RootPath_mask,SubDir_mask,RootFile_mask]=fileparts_uvmat(MaskRootName);
i_mask=[];j_mask=[]; % default

NomTypeMask='_1';
if CheckVolumeScan
    i_mask=j_index;% volume scan mode
elseif NbSlice~=1 % multilevel mode
    i_mask=mod(i_index,NbSlice)+1;% multi-level mode
else
    NomTypeMask='*';%unique mask, no indexing
end

maskname=fullfile_uvmat(RootPath_mask,SubDir_mask,RootFile_mask,'.png',NomTypeMask,i_mask,j_mask);
    