%'nomtype2pair': creates nomencalture for index pairs knowing the image nomenclature
%---------------------------------------------------------------------
% [nom_type_pair]=nomtype2pair(nom_type,Dti,Dtj);
%---------------------------------------------------------------------           

% OUTPUT:
%nom_type_nc

%---------------------------------------------------------------------
% INPUT:
% 'nom_type': string defining the kind of nomenclature used:
     %nom_type='': constant name [filebase ext] (default output if 'nom_type' is undefined)
     %nom_type='*': the same  file [filebase ext] contains successive fields (ex avi movies)
     %nom_type='_i': series of files with a single index i preceded by '_'(e.g. 'aa_45.png').
     %nom_type='#' series of indexed images wich is not series_i [filebase index ext], e.g. 'aa045.jpg' or 'aa45.tif'
     %nom_type='_i_j' matrix of files with two indices i and j separated by '_'(e.g. 'aa_45_2.png')
     %nom_type='_i1-i2' from pairs from a single index (e.g. 'aa_45-47.nc') 
     %nom_type='_i_j1-j2'pairs of j indices (e.g. 'aa_45_2-3.nc')
     %nom_type='_i1-i2_j' pairs of i indices (e.g. 'aa_45-46_2.nc')
     %nom_type='#a','#A', with a numerical index and an index letter(e.g.'aa045b.png'), OBSOLETE (replaced by 'series_i_j')
     %nom_type='%03d' or '%04d', series of indexed images with numbers completed with zeros to 3 or 4 digits, e.g.'aa045.tif'
     %nom_type='_%03d', '_%04d', or '_%05d', series of indexed images with _ and numbers completed with zeros to 3, 4 or 5 digits, e.g.'aa_045.tif'
     %nom_type='raw_SMD', same as '#a' but with no extension ext='', OBSOLETE
     %nom_type='#_ab' from pairs of '#a' images (e.g. 'aa045bc.nc'), ext='.nc', OBSOLETE (replaced by 'netc_2D')
     %nom_type='%3dab' from pairs of '%3da' images (e.g. 'aa045bc.nc'), ext='.nc', OBSOLETE (replaced by 'netc_2D')
% Dti: ~=0 if i index pairs are used
% Dtj: ~=0 if i index pairs are used

function [nom_type_pair]=nomtype2pair(nom_type,Dti,Dtj)

%determine nom_type_nc:
nom_type_pair=[];%default
switch nom_type
    case {'_i_j'}
        if Dtj>0 || Dtj<0
            nom_type_pair='_i_j1-j2';
            if Dti>0 || Dti<0
                nom_type_pair='_i1-i2_j1-j2';
            end
            elseif Dti>0 || Dti<0
            nom_type_pair='_i1-i21_j';   
        else
             nom_type_pair='_i_j';
        end
    case {'_i1-i2_j'}
        if Dtj>0 || Dtj<0
           nom_type_pair='_i1-i2_j1-j2';
        else
            nom_type_pair='_i1-i2_j';
        end
    case {'i_j1-j2'}
        if Dti>0 || Dti<0
           nom_type_pair='_i1-i2_j1-j2';
        else
            nom_type_pair='_i1-i2_j';
        end
    case {'i1-i2_j1-j2'}
         nom_type_pair='_i1-i2_j1-j2';
    case '#a'
        if Dtj>0 || Dtj<0
            nom_type_pair='#_ab';
        end
    otherwise
        if Dti>0 || Dti<0
           nom_type_pair='_i1-i2'; 
        end
end
