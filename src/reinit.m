%'reinit': delete the personal parameter file 'uvmat_perso.mat' 
%
function reinit
dir_perso=prefdir;
profil_perso=fullfile(dir_perso,'uvmat_perso.mat')
if exist(profil_perso,'file')
    delete(profil_perso)
end
display('deleted')        