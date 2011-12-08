%'fileparts_uvmat': Splits a file name and recognize file naming convention
%--------------------------------------------------------------------
%[RootPath,SubDir,RootFile,i1,i2,j1,j2,Ext,NomType]=fileparts_uvmat(FileInput)
%
%OUTPUT:
%RootFile: FileName without appendix
%i1: first number i
%i2: second number i (only for .nc files)
%j1: first number j
%j2: second number j (only for .nc files)
%Ext: file Extension
%NomType: char chain characterizing the file nomenclature: with values
%   NomType='': constant name [filebase Ext] (default output if 'NomType' is undefined)
%   NomType='*':constant name for a file representing a series (e.g. avi movie)
%   NomType='1','01',or '001'...': series of files with a single index i without separator(e.g. 'aa045.png').
%   NomType='1a','1A','01a','01A','1_a','01_A',... with a numerical index and an index letter(e.g.'aa45b.png') (lower or upper case)
%   NomType='1_1','01_1',...: matrix of files with two indices i and j separated by '_'(e.g. 'aa45_2.png')
%   NomType='1-1': from pairs from a single index (e.g. 'aa_45-47.nc')
%   NomType='1_1-1': pairs of j indices (e.g. 'aa_45_2-3.nc')
%   NomType='1-1_1': pairs of i indices (e.g. 'aa_45-46_2.nc')
%   NomType='1_ab','01_ab','01_a-b'..., from pairs of '#' images (e.g.'aa045bc.nc'), Ext='.nc'
%SubDir: name of the SubDirectory for netcdf files

%   OLD TYPES, not supported anymore
%   NomType='_1','_01','_001'...':  series of files with a single index i with separator '_'(e.g. 'aa_045.png').
%   NomType='_1a','_1A','_01a','_01A',...: idem, with a separator '_' before the index
%   NomType='_1_1','_01_1',...: matrix of files with two indices i and j separated by '_'(e.g. 'aa_45_2.png')
%   NomType='_i1-i2': from pairs from a single index (e.g. 'aa_45-47.nc')
%   NomType='_i_j1-j2': pairs of j indices (e.g. 'aa_45_2-3.nc')
%   NomType='_i1-i2_j': pairs of i indices (e.g. 'aa_45-46_2.nc')
%   NomType='_1_ab','1_ab','01_ab'..., from pairs of '#' images (e.g.'aa045bc.nc'), Ext='.nc'

%
%INPUT:
%FileInput: complete name of the file, including path

function [RootPath,SubDir,RootFile,i1,i2,j1,j2,Ext,NomType]=fileparts_uvmat(FileInput)

i1=[];
i2=[];
j1=[];
j2=[];
NomType='';
SubDir='';
RootFile='';

if ~exist('FileInput','var')
    help fileparts_uvmat;
    test();
    return
end


[RootPath,FileName,Ext]=fileparts(FileInput);

switch Ext
    case '.avi'
        NomType='*';
        return
    case {'.tif','.tiff'}
        if exist(FileInput,'file')
            info=iminfo(FileInput);
            if length(info)>1
                NomType='*';
                return
            end
        end 
end

% \D not a digit
% \d digit


%% recursive test on FileName stqrting from the end

% test whether FileName ends with a number or not
r=regexp(FileName,'.*\D(?<num1>\d+)\>','names');

if ~isempty(r)% FileName end matches num1
    num1=r.num1;
    r=regexp(FileName,['.*\D(?<num2>\d+)(?<delim1>[-_])' num1 '\>'],'names');
    if ~isempty(r)% FileName end matches num2+delim1+num1
        delim1=r.delim1;
        num2=r.num2;
        r=regexp(FileName,['.*\D(?<num3>\d+)(?<delim2>[-_])' num2 delim1 num1 '\>'],'names');
        if ~isempty(r) % FileName end matches delim2 num2 delim1 num1
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
            RootFile=regexprep(FileName,[num3 delim2 num2 delim1 num1],'');
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
            RootFile=regexprep(FileName,[num2 delim1 num1],'');
        end
    else% only one number at the end
        i1=str2double(num1);
        NomType=get_type(num1);
        RootFile=regexprep(FileName,num1,'');
    end
else% FileName ends with a letter
    r=regexp(FileName,'.*[^a^b^A^B](?<end_string>ab|AB|[abAB])\>','names');
    if ~isempty(r)
        end_string=r.end_string;
        r=regexp(FileName,['.+(?<delim1>[_-])' end_string '\>'],'names');
        if ~isempty(r)
            delim1=r.delim1;
            r=regexp(FileName,['.*\D(?<num1>\d+)' delim1 end_string '\>'],'names');
            if ~isempty(r)
                num1=r.num1;
                NomType=[get_type(num1) delim1 get_type(end_string)];
                i1=str2double(num1);
                [j1,j2]=get_value(end_string);
                RootFile=regexprep(FileName,[num1 delim1 end_string],'');
                
            else
                NomType=get_type(end_string);
                [j1,j2]=get_value(end_string);
                RootFile=regexprep(FileName,end_string,'');

            end
        else
            r=regexp(FileName,['.*\D(?<num1>\d+)' end_string '\>'],'names');
            if ~isempty(r)
                num1=r.num1;
                %                 r=regexp(FileName,['.+(?<delim1>[-_])' num1 end_string '\>'],'names');
                %                 if ~isempty(r)
                %                     delim1=r.delim1;
                %                     i1=num1;
                %                     str_a=end_string;
                %                     NomType=[delim1 get_type(num1) get_type(end_string)];
                %                     RootFile=regexprep(FileName,[delim1 num1 end_string],'');
                %                 else
                i1=str2double(num1);
                [j1,j2]=get_value(end_string);
                NomType=[get_type(num1) get_type(end_string)];
                RootFile=regexprep(FileName,[num1 end_string],'');
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
%             switch s(1)
%                 case '0'
                    type=num2str(1,['%0' num2str(length(s)) 'd']);
%                 otherwise
%                     type='1';
%             end
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
        'Image005AB.jpg'...
        'Image_3_ab.jpg'...
        'Image_3a-b.jpg'...
        'Image3_a.jpg'...
        'movie57.avi'...
        };
end

for FileName=FileName_list
%     [RootPath,RootFile,i1,i2,str_a,str_b,Ext,NomType,SubDir]=name2display(FileName{1});
    [~,RootFile_bis,i1_bis,i2_bis,j1_bis,j2_bis,~,NomType_bis,SubDir_bis]=...
        fileparts_uvmat(FileName{1});
    fprintf([...
        'File name  : ' FileName{1}  '\n'...
        '  NomType  : '    NomType_bis '\n'...
        '  RootFile : '    RootFile_bis '\n'...
        '  i1 / i2     : '     num2str(i1_bis) ' / ' num2str(i2_bis) '\n'...
        '  j1 / j2      : '    num2str(j1_bis) ' / ' num2str(j2_bis) '\n'...
        ]);
end


