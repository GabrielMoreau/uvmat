% commands to 

mcc -m -R -nojvm -R -nodisplay civ_matlab.m
system('mv civ_matlab bin/');
system('sed -e ''s#/civ_matlab#/bin/civ_matlab#'' run_civ_matlab.sh > run_civ_matlab.sh.correct'); 
system('mv -f run_civ_matlab.sh.correct  run_civ_matlab.sh');


