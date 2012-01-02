% 'xml2struct': read an xml file as a Matlab structure, converts numeric character strings into numbers 
%-----------------------------------------------------------------------
% function s=xml2struct(filename)
%
% OUTPUT:
% s= Matlab structure corresponding to the input xml file
%
% INPUT:
% filename: name of the xml file

function s=xml2struct(filename)
t=xmltree(filename);
ss=convert(t);
s=convert_string(ss);


function out=convert_string(s)
info=whos('s');
switch info.class
    case 'struct'
        names = fieldnames(s);
        for k=1:length(names)
            out.(names{k})=convert_string(s.(names{k}));
        end
    case 'char'
        if isempty(regexp(s,'\<\d+\>'))
            out=s;
        else
            out=str2num(s);
        end
    otherwise
        out=s;
end

    