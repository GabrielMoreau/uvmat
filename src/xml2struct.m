function s=xml2struct(filename)
% structure parser, converts numeric character strings into numbers

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

    