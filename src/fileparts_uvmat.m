%'name2display': extracts the root name and field numbers from an input filename 
%--------------------------------------------------------------------
%[RootPath,RootFile,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fileinput)
%
%OUTPUT:
%filebasesub: filename without appendix
%field_count: string for the first number i
%str2: string for the second number i (only for .nc files)
%str_a: string for the first number j
%str_b:string for the second number j (only for .nc files)
%ext: file extension
%nom_type: char chain characterizing the file nomenclature: with values
%   nom_type='': constant name [filebase ext] (default output if 'nom_type' is undefined)
%   nom_type='*':constant name for a file representing a series (e.g. avi movie)
%   nom_type='1','01',or '001'...': series of files with a single index i without separator(e.g. 'aa045.png').
%   nom_type='_1','_01','_001'...':  series of files with a single index i with separator '_'(e.g. 'aa_045.png').
%   nom_type='1a','1A','01a','01A',... with a numerical index and an index letter(e.g.'aa45b.png') (lower or upper case)
%   nom_type='_1a','_1A','_01a','_01A',...: idem, with a separator '_' before the index
%   nom_type='_1_1','_01_1',...: matrix of files with two indices i and j separated by '_'(e.g. 'aa_45_2.png')
%   nom_type='1_1','01_1',...: matrix of files with two indices i and j separated by '_'(e.g. 'aa45_2.png')
%   nom_type='_i1-i2': from pairs from a single index (e.g. 'aa_45-47.nc')
%   nom_type='_i_j1-j2': pairs of j indices (e.g. 'aa_45_2-3.nc')
%   nom_type='_i1-i2_j': pairs of i indices (e.g. 'aa_45-46_2.nc')
%   nom_type='_1_ab','1_ab','01_ab'..., from pairs of '#' images (e.g.'aa045bc.nc'), ext='.nc'
%subdir: name of the subdirectory for netcdf files
%
%INPUT:
%fileinput: complete name of the file, including path

function [RootPath,RootFile,i1,i2,j1,j2,ext,nom_type,subdir]=name2display2(fileinput)
% siz=length(fileinput);
% indcur=siz;
% default values:
% test_=0;
i1=[];%character string
i2=[];
j1=[];
j2=[];
nom_type='';
subdir='';
RootFile='';

%select file extension
[RootPath,filename,ext]=fileparts(fileinput);

% \D not a digit
% \d digit


%% recursive test on filename stqrting from the end

% test whether filename ends with a number or not
r=regexp(filename,'.*\D(?<num1>\d+)\>','names');

if ~isempty(r)% filename end matches num1
    num1=r.num1;
    r=regexp(filename,['.*\D(?<num2>\d+)(?<delim1>[-_])' num1 '\>'],'names');
    if ~isempty(r)% filename end matches num2+delim1+num1
        delim1=r.delim1;
        num2=r.num2;
        r=regexp(filename,['.*\D(?<num3>\d+)(?<delim2>[-_])' num2 delim1 num1 '\>'],'names');
        if ~isempty(r) % filename end matches delim2 num2 delim1 num1
            delim2=r.delim2;
            num3=r.num3;
            switch delim1
                case '_'
                    j1=str2num(num1);
                    switch delim2
                        case '-'
                            i1=str2num(num3);
                            i2=str2num(num2);
                    end
                case '-'
                    j1=str2num(num2);
                    j2=str2num(num1);
                    switch delim2
                        case '_'
                            i1=str2num(num3);
                    end
            end
            nom_type=[get_type(num3) delim2 get_type(num2) delim1 get_type(num1)];
            RootFile=regexprep(filename,[num3 delim2 num2 delim1 num1],'');
        else
            switch delim1
                case '_'
                    i1=str2num(num2);
                    j1=str2num(num1);
                case '-'
                    i1=str2num(num2);
                    i2=str2num(num1);
            end
            nom_type=[get_type(num2) delim1 get_type(num1)];
            RootFile=regexprep(filename,[num2 delim1 num1],'');
        end
    else% only one number at the end
        i1=str2num(num1);
        nom_type=get_type(num1);
        RootFile=regexprep(filename,num1,'');
    end
else% filename ends with a letter
    r=regexp(filename,'.*[^a^b^A^B](?<end_string>ab|AB|[abAB])\>','names');
    if ~isempty(r)
        end_string=r.end_string;
        r=regexp(filename,['.+(?<delim1>[_-])' end_string '\>'],'names');
        if ~isempty(r)
            delim1=r.delim1;
            r=regexp(filename,['.*\D(?<num1>\d+)' delim1 end_string '\>'],'names');
            if ~isempty(r)
                num1=r.num1;
                nom_type=[get_type(num1) delim1 get_type(end_string)];
                i1=str2num(num1);
                [j1,j2]=get_value(end_string);
                RootFile=regexprep(filename,[num1 delim1 end_string],'');
                
            else
                nom_type=get_type(end_string);
                [j1,j2]=get_value(end_string);
                RootFile=regexprep(filename,[end_string],'');

            end
        else
            r=regexp(filename,['.*\D(?<num1>\d+)' end_string '\>'],'names');
            if ~isempty(r)
                num1=r.num1;
                %                 r=regexp(filename,['.+(?<delim1>[-_])' num1 end_string '\>'],'names');
                %                 if ~isempty(r)
                %                     delim1=r.delim1;
                %                     i1=num1;
                %                     str_a=end_string;
                %                     nom_type=[delim1 get_type(num1) get_type(end_string)];
                %                     RootFile=regexprep(filename,[delim1 num1 end_string],'');
                %                 else
                i1=str2num(num1);
                [j1,j2]=get_value(end_string);
                nom_type=[get_type(num1) get_type(end_string)];
                RootFile=regexprep(filename,[num1 end_string],'');
                %                 end
            else
            end
            
            
   
        end                
    else
    end
end






function type=get_type(s)
% returns the type of a label string:
%   for numbers, whether filled with 0 or not.
%   for letters, either a, A or ab, AB.

switch s
    case {'a','b'}
        type='a';
    case {'A','B'}
        type='A';
    case 'ab'
        type='ab';
    case 'AB'
        type='AB';
    otherwise        
        if ~isempty(regexp(s,'\<\d+\>','ONCE'))
            switch s(1)
                case '0'
                    type=num2str(1,['%0' num2str(length(s)) 'd']);
                otherwise
                    type='1';
            end
        else
            type='';
            return
        end
end


function [j1,j2]=get_value(s)
% returns the type of a label string:
%   for numbers, whether filled with 0 or not.
%   for letters, either a, A or ab, AB.
j1=[];
j2=[];

switch lower(s)
    case {'a'}
        j1=1;
    case {'b','B'}
        j1=2;
    case 'ab'
        j1=1;j2=2;
    otherwise        
            return
end


