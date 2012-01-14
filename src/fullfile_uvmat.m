%'fullfile_uvmat': creates a file name from a root name and indices. 
%------------------------------------------------------------------------
% filename=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i1,i2,j1,j2)
%------------------------------------------------------------------------           
% In the absence of input argument this function tests itself on a set of
% examples
%------------------------------------------------------------------------
% OUTPUT:
% filename: string representing the full file name (including path)
%------------------------------------------------------------------------
% INPUT:
%RootPath: path to the base file
%SubDir: name of the SubDirectory for netcdf files (relevant for NomTypes with index pairs 1-2 or ab )
%RootFile: FileName without appendix
%FileExt: file extension
%NomType: char chain characterizing the file nomenclature, made as
%   nom_type='': constant name [filebase ext] (default output if 'nom_type' is undefined)
%   nom_type='*':constant name for a file representing a series (e.g. avi movie)
%   nom_type='1','01',or '001'...': series of files with a single index i without separator(e.g. 'aa045.png').
%   nom_type='_1','_01','_001'...':  series of files with a single index i with separator '_'(e.g. 'aa_045.png').
%   nom_type='1a','1A','01a','01A',... with a numerical index and an index letter(e.g.'aa45b.png') (lower or upper case)
%   nom_type='_1a','_1A','_01a','_01A',...: idem, with a separator '_' before the index
%   nom_type='_1_1','_01_1',...: matrix of files with two indices i and j separated by '_'(e.g. 'aa_45_2.png')
%   nom_type='_1-2': from pairs from a single index (e.g. 'aa_45-47.nc')
%   nom_type='_1_1-2': pairs of j indices (e.g. 'aa_45_2-3.nc')
%   nom_type='_1-2_1': pairs of i indices (e.g. 'aa_45-46_2.nc')
%   nom_type='_1_ab','1_ab','01_ab'..., from pairs of '#' images
%   (e.g.'aa045bc.nc'), ext='.nc'
%i1: first number i
%i2: second number i (only for .nc files)
%j1: first number j
%j2: second number j (only for .nc files)
%------------------------------------------------------------------------
%related functions:
% fileparts_uvmat, num2stra, stra2num.

function filename=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i1,i2,j1,j2)
    
%% display help and test function in the absence of input arument
if ~exist('RootPath','var')
    help fullfile_uvmat;
    test;
    return
end

%% default input
if ~exist('j2','var') 
    j2=[];
end
if isequal(j1,j2)
    j2=[];% suppress the secodn index if equal to the first
end
if ~exist('j1','var') 
    j1=1;
end
if ~exist('i2','var') 
    i2=[];
end
if isequal(i1,i2)
    i2=[];% suppress the secodn index if equal to the first
end
if ~exist('i1','var') 
    i1=1;
end

%% default output
sep1='';
i1_str='';
sep2='';
i2_str='';
sep3='';
j1_str='';
sep4='';
j2_str='';

%% look for NomType with pairs (separator '-' or terminasion ab or AB
if ~isempty(regexp(NomType,'^_\d'))
    sep1='_';
    NomType(1)=[];%remove '_' from the beginning of NomType
end
r=regexp(NomType,'^(?<num1>\d+)','names');%look for a number at the beginning of NomType
if ~isempty(r)
    i1_str=num2str(i1,['%0' num2str(length(r.num1)) 'd']);
    NomType=regexprep(NomType,['^' r.num1],'');   
    r=regexp(NomType,'^-(?<num2>\d+)','names');%look for a pair i1-i2
    if ~isempty(r)
         if ~isempty(i2)
        sep2='-';
         i2_str=num2str(i2,['%0' num2str(length(r.num2)) 'd']);
         end
         NomType=regexprep(NomType,['^-' r.num2],'');
    end
    if ~isempty(regexp(NomType,'^_'));
        sep3='_';
        NomType(1)=[];%remove '_' from the beginning of NomType
    end
    if ~isempty(regexp(NomType,'^[a|A]'));
        j1_str=num2stra(j1,NomType);
        if ~isempty(regexp(NomType,'[b|B]$'))&& ~isempty(j2);
            j2_str=num2stra(j2,NomType);
        end
    else
        r=regexp(NomType,'^(?<num3>\d+)','names');
        if ~isempty(r)
            j1_str=num2str(j1,['%0' num2str(length(r.num3)) 'd']);
            NomType=regexprep(NomType,['^' r.num3],'');
        end
        if ~isempty(j2) 
        r=regexp(NomType,'-(?<num4>\d+)','names');
        if ~isempty(r)
            sep4='-';
            j2_str=num2str(j2,['%0' num2str(length(r.num4)) 'd']);
        end
        end
    end
end
% if ~isempty(i2_str)||~isempty(j2_str)
    filename=fullfile(RootPath,SubDir,RootFile);
% else
%     filename=fullfile(RootPath,RootFile);
% end
filename=[filename sep1 i1_str sep2 i2_str sep3 j1_str sep4 j2_str FileExt];



function test
fprintf([...
    '######################################################\n'...
    '               Test for fullfile_uvmat                  \n'...
    '######################################################\n'...
    ]);

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
size(FileName_list)
for ilist=1:numel(FileName_list)
    [RootPath,SubDir,RootFile,i1,i2,j1,j2,FileExt,NomType]=...
        fileparts_uvmat(FileName_list{1,ilist});
    FileName_list{2,ilist}=['NomType=' NomType];
    FileName_list{3,ilist}=['i+1,j+1->' fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i1+1,i2+1,j1+1,j2+1)];
%     fprintf(['File name  : ' FileName{1} '\n FileName_rebuilt  : '    FileName_rebuilt '\n']) 
end
  Tabchar=cell2tab(FileName_list',' ');
  display(Tabchar)
 % fprintf(Tabchar);



