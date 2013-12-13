% 'ima_green': take the gree component of a color image

%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input %%%%
% OUTPUT: 
% DataOut:   output field structure 

%INPUT:
% DataIn:  first input field structure
%------------------------------------------------------------------------
function DataOut=ima_green(DataIn)

DataOut=DataIn; %default
if ndims(DataOut.A)==3
    DataOut.A=DataOut.A(:,:,2);
end
 