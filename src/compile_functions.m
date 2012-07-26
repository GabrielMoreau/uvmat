% check 
if isempty(which('mcc')
    msgbox_uvmat('no Matlab compiler toolbox mcc installed')
    return
end
display('compiling civ_matlab...')
% commands to compile civ_matlab and eventually other functions
mcc -m -R -nojvm -R -nodisplay civ_matlab.m
system('mv -f civ_matlab bin/');
system('sed -e ''s#/civ_matlab#/bin/civ_matlab#'' run_civ_matlab.sh > civ_matlab.sh'); 
system('rm run_civ_matlab.sh');
system('chmod +x civ_matlab.sh');
display('** END **')



