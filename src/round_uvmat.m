% provide a simple round value of Val of the form  1, 2 , 5 *10^n
function RoundVal= round_uvmat(Val)

ord=10^(floor(log10(Val)));%order of magnitude
if Val/ord >= 5
    RoundVal=5*ord;
elseif Val/ord>=2
    RoundVal=2*ord;
else
    RoundVal=ord;
end

