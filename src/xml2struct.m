% 'xml2struct': read an xml file as a Matlab structure, converts numeric character strings into numbers 
%-----------------------------------------------------------------------
% function [s,RootTag,errormsg]=xml2struct(filename,varargin)
%
% OUTPUT:
% s= Matlab structure corresponding to the input xml file
% RootTag= name of the root tag in the xml file
% errormsg: errormessage, ='' by default
%
% INPUT:
% filename: name of the xml file
% varargin: optional list of strings to restrict the reading to a selection of subtrees, for instance 'GeometryCalib' (save reading time) 

function [s,RootTag,errormsg]=xml2struct(filename,varargin)
s=[];
RootTag='';
errormsg='';
try
    t=xmltree(filename);
catch ME
    errormsg=ME.message;
    if regexp(ME.message,'Undefined function')
        errormsg=[errormsg ': package xmltree not correctly installed, reload it from www.artefact.tk/software/matlab/xml'];
    end
    return
end
iline=0;

while isempty(RootTag)
    iline=iline+1;
    if strcmp(get(t,iline,'type'),'element')
        RootTag=get(t,iline,'name');
    end
end
if nargin>1
    for isub=1:nargin-1
        uid_sub=find(t,['/' RootTag '/' varargin{isub}]);
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
        % try to convert to number if the char does not correspond to a function (otherwise str2num calls this function as it uses 'eval')
        if ~isempty(regexp(ss,'^(-*\d+\.*\d*\ *)+$')) || ~isempty(regexp(ss,'\d+e(-|+)\d+')) % if the string corresponds to a set of numbers (with possible sign and decimal, or scientific notation) separated by blanks
            out=str2num(ss);
        else
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

    