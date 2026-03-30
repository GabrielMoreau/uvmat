% get_background_name: determine the name of the background file for frame indices i_index and j_index
%
% backgroundname=get_background_name(BkgndRootName,i_index,j_index,NbSlice,CheckVolumeScan,IndexPeriod)
% OUTPUT: 
% 'backgroundname': name of the mask or background file
% INPUT:
% BkgndRootName: root name of the mask
% i_index: i index of the field to mask
% j_index: j_index of the field to mask
% NbSlice: number of slices 
% CheckVolumeScan =false for multi-level mode (the i index gives the plane
% position modulo NbSlice)
% =true: the j index gives the plane position
% IndexPeriod: period of the i_index for which a background has been determined
%------------------------------------------------------------------------
function backgroundname=get_background_name(BkgndRootName,i_index,j_index,NbSlice,CheckVolumeScan,IndexPeriod)
[RootPath_bkgnd,SubDir_bkgnd,RootFile_bkgnd]=fileparts_uvmat(BkgndRootName);
i_bkgnd=[];j_bkgnd=[]; % default
if isempty(IndexPeriod)% bkgnd depends only on level
    NomTypeBkgnd='_1';
    if CheckVolumeScan
        i_bkgnd=j_index;% volume scan mode
    elseif NbSlice~=1 % multilevel mode
        i_bkgnd=mod(i_index,NbSlice)+1;% multi-level mode
    else
        NomTypeBkgnd='*';%unique bkgnd, no indexing
    end
else %apply for background with periodicity IndexPeriod
     NomTypeBkgnd='_1_1';
    if CheckVolumeScan% volume scan, j index for the level
        i_bkgnd=floor((i_index-1)/IndexPeriod)*IndexPeriod+1;
        j_bkgnd=j_index;
    elseif NbSlice~=1 % multilevel mode, j index for the level
        IndexPeriod=IndexPeriod*NbSlice;
        i_bkgnd=floor((i_index-1)/IndexPeriod)*IndexPeriod+1;
        j_bkgnd=mod(i_index,NbSlice)+1;
    else % no scan, only i index
        i_bkgnd=floor((i_index-1)/IndexPeriod)*IndexPeriod+1;
        NomTypeBkgnd='_1';
    end
end
backgroundname=fullfile_uvmat(RootPath_bkgnd,SubDir_bkgnd,RootFile_bkgnd,'.png',NomTypeBkgnd,i_bkgnd,j_bkgnd);
    