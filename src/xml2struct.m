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


function out=convert_string(ss)
info=whos('ss');
switch info.class
    case 'struct'
        names = fieldnames(ss);
        for k=1:length(names)
            out.(names{k})=convert_string(ss.(names{k}));
        end
    case 'char'   
        if isempty(regexp(ss,'^(-*\d+\.*\d*\ *)+$'))% if the string does not contains a set of numbers (with possible sign and decimal) separated by blanks
            sep_ind=regexp(ss,'\s&\s');% check for separator ' & ' which indicates column separation in tables
            if ~isempty(sep_ind)
                sep_ind=[-2 sep_ind length(ss)+1];
                for icolumn=1:length(sep_ind)-1
                    out{1,icolumn}=ss(sep_ind(icolumn)+3:sep_ind(icolumn+1)-1);
                end
            else
                out=ss; %reproduce the input string
            end
        else
            out=str2num(ss);
        end
    case 'cell'
        for ilist=1:numel(ss)
            if ~isempty(str2num(ss{ilist}))
            out(ilist,:)=str2num(ss{ilist});
            end
        end
    otherwise
        out=ss;
end

    