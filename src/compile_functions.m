% commands to compile civ_matlab and eventually other functions

mcc -m -R -nojvm -R -nodisplay civ_matlab.m
system('mv -f civ_matlab bin/');
system('sed -e ''s#/civ_matlab#/bin/civ_matlab#'' run_civ_matlab.sh > civ_matlab.sh'); 
system('rm run_civ_matlab.sh');
system('chmod +x civ_matlab.sh');




