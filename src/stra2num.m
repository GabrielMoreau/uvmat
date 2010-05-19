%'stra2num': transform letters (a, b, c) or numerical strings ('1','2'..) to the corresponding numbers
%--------------------------------------------
%  function numres=stra2num(str)
%
% OUTPUT: 
% numres: number (double)
%
% INPUT:
% str: string corresponding to a number or a letter 'a' 'b',.., otherwise the output is empty
%
% see also num2stra, name_generator, name2display

function numres=stra2num(str)
numres=NaN; %default
if double(str) >= 48 & double(str) <= 57 % = test for number strings
    numres=str2double(str);
elseif double(str) >= 65 & double(str) <= 90 % test on ascii code for capital letters
    numres=double(str)-64; %change capital letters to corresponding number in the alphabet
elseif double(str) >= 97 & double(str) <= 122 % test on ascii code for small letters 
    numres=double(str)-96; %change small letters to corresponding number in the alphabet
end
