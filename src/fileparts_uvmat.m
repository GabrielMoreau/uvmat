%'fileparts_uvmat': Splits a file name and recognize file naming convention
%--------------------------------------------------------------------
%[RootPath,SubDir,RootFile,i1,i2,j1,j2,Ext,NomType]=fileparts_uvmat(FileInput)
%
%OUTPUT:
%RootPath: path to the base file
%SubDir: name of the SubDirectory for netcdf files (NomTypes with index pairs 1-2 or ab )
%RootFile: FileName without appendix
%i1: first number i
%i2: second number i (only for .nc files)
%j1: first number j
%j2: second number j (only for .nc files)
%FileExt: file Extension
%NomType: char chain characterizing the file nomenclature: with values
%   NomType='': constant name [filebase FileExt] (default output if 'NomType' is undefined)
%   NomType='*':constant name for a file representing a series (e.g. avi movie)
%   NomType='1','01',or '001'...': series of files with a single index i without separator(e.g. 'aa045.png').
%   NomType='1a','1A','01a','01A','1_a','01_A',... with a numerical index and an index letter(e.g.'aa45b.png') (lower or upper case)
%   NomType='1_1','01_1',...: matrix of files with two indices i and j separated by '_'(e.g. 'aa45_2.png')
%   NomType='1-1': from pairs from a single index (e.g. 'aa_45-47.nc')
%   NomType='1_1-2': pairs of j indices (e.g. 'aa_45_2-3.nc')
%   NomType='1-2_1': pairs of i indices (e.g. 'aa_45-46_2.nc')
%   NomType='1_ab','01_ab','01ab'..., from pairs of '#' images (e.g.'aa045bc.nc'), FileExt='.nc'
%SubDir: name of the SubDirectory for netcdf files
%
%INPUT:
%FileInput: complete name of the file, including path

function [RootPath,SubDir,RootFile,i1,i2,j1,j2,FileExt,NomType]=fileparts_uvmat(FileInput)
RootPath='';
SubDir='';
RootFile='';
i1=[];
i2=[];
j1=[];
j2=[];
FileExt='';
NomType='';

%% display help and test function in the absence of input arument
if ~exist('FileInput','var')
    help fileparts_uvmat;
    test();
    return
end

%% default root name output
[RootPath,FileName,FileExt]=fileparts(FileInput);
RootFile=FileName;

%% case of input file name which is a pure number
if ~isnan(str2double(FileName))
    RootFile='';
    i1=str2double(FileName);
    return
end

%% recursive test on FileName starting from the end
% test whether FileName ends with a number or not
r=regexp(FileName,'.*\D(?<num1>\d+)$','names');% \D = not a digit, \d =digit

if ~isempty(r)% FileName end matches num1
    num1=r.num1;
    r=regexp(FileName,['.*\D(?<num2>\d+)(?<delim1>[-_])' num1 '$'],'names');
    if ~isempty(r)% FileName end matches num2+delim1+num1
        delim1=r.delim1;
        num2=r.num2;
        switch delim1
            case '_'
                delim2_to_match='-';
            case '-'
                delim2_to_match='_';     
        end        
        r=regexp(FileName,['.*\D(?<num3>\d+)(?<delim2>' delim2_to_match ')' num2 delim1 num1 '$'],'names');
        if ~isempty(r) % FileName end matches num3 delim2 num2 delim1 num1
            delim2=r.delim2;
            num3=r.num3;
            switch delim1
                case '_'
                    j1=str2double(num1);
                    switch delim2
                        case '-'
                            i1=str2double(num3);
                            i2=str2double(num2);
                    end
                case '-'
                    j1=str2double(num2);
                    j2=str2double(num1);
                    switch delim2
                        case '_'
                            i1=str2double(num3);
                    end
            end
            NomType=[get_type(num3) delim2 get_type(num2) delim1 get_type(num1)];
            RootFile=regexprep(FileName,[num3 delim2 num2 delim1 num1 '$'],'');
        else
            switch delim1
                case '_'
                    i1=str2double(num2);
                    j1=str2double(num1);
                case '-'
                    i1=str2double(num2);
                    i2=str2double(num1);
            end
            NomType=[get_type(num2) delim1 get_type(num1)];
            RootFile=regexprep(FileName,[num2 delim1 num1 '$'],'');
        end
        NomType=regexprep(NomType,'-1','-2'); %set 1-2 instead of 1-1
    else% only one number at the end
        i1=str2double(num1);
        NomType=get_type(num1);
        RootFile=regexprep(FileName,[num1 '$'],'');
    end
else% FileName ends with a letter
    %r=regexp(FileName,'.*[^a^b^A^B](?<end_string>ab|AB|[abAB])\>','names');
    NomType='';
    r=regexp(RootFile,'\D*(?<num1>\d+)(?<end_string>[a-z]|[A-Z]|[a-z][a-z]|[A-Z][A-Z])$','names');
    if ~isempty(r)
        NomType=get_type(r.end_string);
        RootFile=regexprep(RootFile,[r.num1 r.end_string '$'],'');
    else % case with separator '_'
        r=regexp(RootFile,'\D(?<num1>\d+)_(?<end_string>[a-z]|[A-Z]|[a-z][a-z]|[A-Z][A-Z])$','names');
        if ~isempty(r)
            NomType=['_' get_type(r.end_string)];
            RootFile=regexprep(RootFile,[r.num1 '_' r.end_string '$'],'');
        end
    end
    if ~isempty(NomType)
        [j1,j2]=get_value(r.end_string);
        i1=str2double(r.num1);
        NomType=[get_type(r.num1) NomType];
    end
end

%% suppress '_' at the end of RootFile, put it on NomType
% if strcmp(RootFile(end),'_')
%     RootFile(end)=[];
detect=regexp(RootFile,'_$'); %detect '_' at the end of RootFILE
if ~isempty(detect)
    RootFile=regexprep(RootFile,'_$','');
    NomType=['_' NomType];
end

%% extract subdirectory for pairs i1-i2 or j1-j2 (or ab, AB)
% if ~isempty(i2) || ~isempty(j2)
    r=regexp(RootPath,'\<(?<newrootpath>.+)(\\|/)(?<subdir>[^\\^/]+)(\\|/)*\>','names');
    if ~isempty(r)
        SubDir=r.subdir;
        RootPath=r.newrootpath;
    end
% end



function type=get_type(s)
% returns the type of a label string:
%   for numbers, whether filled with 0 or not.
type='';%default

if ~isempty(regexp(s,'\<\d+\>','ONCE'))
    type=num2str(1,['%0' num2str(length(s)) 'd']);
else
    code=double(s); % ascii code of the input string
    if code >= 65 & code <= 90 % test on ascii code for capital letters
        if length(s)==1
            type='A';
        elseif length(s)==2
            type='AB';
        end
    elseif  code >= 97 & code <= 122 % test on ascii code for small letters
        if length(s)==1
            type='a';
        elseif length(s)==2
            type='ab';
        end
    end
end



function [j1,j2]=get_value(s)
% returns the value of a label string:
%   for numbers, whether filled with 0 or not.
%   for letters, either a, A or ab, AB.
j1=[];
j2=[];
code=double(s); % ascii code of the input string
if code >= 65 & code <= 90 % test on ascii code for capital letters
    index=double(s)-64; %change capital letters to corresponding number in the alphabet
elseif code >= 97 & code <= 122 % test on ascii code for small letters 
    index=double(s)-96; %change small letters to corresponding number in the alphabet
else
    index=str2num(s);
end
if ~isempty(index)
    j1=index(1);
    if length(index)==2
        j2=index(2);
    end
end


function test(name)
fprintf([...
    '######################################################\n'...
    '               Test for fileparts_uvmat                  \n'...
    '######################################################\n'...
    ]);

if exist('name','var')
    FileName_list={name};
else
    FileName_list={...
        'Image1a.png'...
        'toto'...
        'B011_1.png'...
        'B001.png'...
        'B55a.tif'...
        'B002B.tiff'...
        'B_001.png'...
        'B_3331AB.png'...
        'aa45_2.png'...
        'B005.png'...
        'Image_3.jpg'...
        'Image_3-4.jpg'...
        'Image_3-4_2.jpg'...
        'Image_5_3-4.jpg'...
        'Image_3_ab.jpg'...
        'Image005AD.jpg'...
        'Image_3_ac.jpg'...
        'Image_3a-b.jpg'...
        'Image3_a.jpg'...
        'movie57.avi'...
        'merged_20_12_1.png'...
        };
end

for FileName=FileName_list
%     [RootPath,RootFile,i1,i2,str_a,str_b,FileExt,NomType,SubDir]=name2display(FileName{1});
    [tild,SubDir,RootFile,i1,i2,j1,j2,tild,NomType]=...
        fileparts_uvmat(FileName{1});
    fprintf([...
        'File name  : ' FileName{1}  '\n'...
        '  NomType  : '    NomType '\n'...
        '  RootFile : '    RootFile '\n'...
        '  i1 / i2     : '     num2str(i1) ' / ' num2str(i2) '\n'...
        '  j1 / j2      : '    num2str(j1) ' / ' num2str(j2) '\n'...
        ]);
end


