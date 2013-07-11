% 'xml2struct': read an xml file as a Matlab structure, converts numeric character strings into numbers 
%-----------------------------------------------------------------------
% function s=xml2struct(filename)
%
% OUTPUT:
% s= Matlab structure corresponding to the input xml file
%
% INPUT:
% filename: name of the xml file
% varargin: optional list of strings to restrict the reading to a selection of subtrees, for instance 'GeometryCalib' (save time) 

function [s,Heading]=xml2struct(filename,varargin)
t=xmltree(filename);
iline=0;
Heading='';
while isempty(Heading)
    iline=iline+1;
    if strcmp(get(t,iline,'type'),'element')
        Heading=get(t,iline,'name');
    end
end
if nargin>1
    for isub=1:nargin-1
        uid_sub=find(t,['/' Heading '/' varargin{isub}]);
        if isempty(uid_sub)
            s.(varargin{isub})=[];
        else
        tsub=branch(t,uid_sub);
        ss=convert(tsub);
        s.(varargin{isub})=convert_string(ss);
        end
    end
else
    ss=convert(t);
    s=convert_string(ss);
end


function out=convert_string(ss)
info=whos('ss');
switch info.class
    case 'struct'
        out=[];%default
        names = fieldnames(ss);
        for k=1:length(names)
            out.(names{k})=convert_string(ss.(names{k}));
        end
    case 'char' 
        out=ss; %reproduce the input string
        if ~strcmp(ss,'image')% bug with Matlab str2num('image')-> child face
            out=str2num(ss);
            %if isempty(regexp(ss,'^(-*\d+\.*\d*\ *)+$'))% if the string does not contain a set of numbers (with possible sign and decimal) separated by blanks
            if isempty(out)
                sep_ind=regexp(ss,'\s&\s');% check for separator ' & ' which indicates column separation in tables
                if ~isempty(sep_ind)
                    sep_ind=[-2 sep_ind length(ss)+1];
                    for icolumn=1:length(sep_ind)-1
                        out{1,icolumn}=ss(sep_ind(icolumn)+3:sep_ind(icolumn+1)-1);
                    end
                else
                    out=ss; %reproduce the input string
                end
            end
        end
    case 'cell'
        out=[];%default
        check_numeric=zeros(size(ss));
        for ilist=1:numel(ss)
            if ~strcmp(ss{ilist},'image') && ~isempty(str2num(ss{ilist}))
                out{ilist,1}=str2num(ss{ilist});
                check_numeric(ilist)=1;
            else
                sep_ind=regexp(ss{ilist},'\s&\s');% check for separator ' & ' which indicates column separation in tables
                if ~isempty(sep_ind)
                    sep_ind=[-2 sep_ind length(ss{ilist})+1];
                    for icolumn=1:length(sep_ind)-1
                        out{ilist,icolumn}=ss{ilist}(sep_ind(icolumn)+3:sep_ind(icolumn+1)-1);
                    end
                else
                    out{ilist,1}=ss{ilist}; %reproduce the input string
                end
            end
        end
        if isequal(check_numeric,ones(size(ss)))
            out=cell2mat(out);
        end
    otherwise
        out=ss;
end

    