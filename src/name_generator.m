%'name_generator': creates a file name from a root name and indices. 
%------------------------------------------------------------------------
% [filename,num_i1_out,num_j1_out,num_i2_out,num_j2_out,subdir_out]=...
%        name_generator(filebase,num_i1,num_j1,ext,nom_type,comp_input,num_i2,num_j2,subdir);
%------------------------------------------------------------------------           
% This function detects the existence the constructed file name and it can
% find indices according to file existence if they are not specified
% rmq: this function is related to the reverse functions display2name and name2diplay 
%------------------------------------------------------------------------
% OUTPUT:
% filename: string representing the file name (including path)
% num_i1_out,num_j1_out,num_i2_out,num_j2_out,subdir_out: index numbers and subdirectory detected 
%            for free input (= to the corresponding input indices when comp_input=1)
%------------------------------------------------------------------------
% INPUT:
% 'filebase': the root name, 
% 'num_i1: first labelling index i 
% 'num_j1', first labelling index j
% 'ext': file name extension (e.g. '.png' or '.nc')
%nom_type: char chain characterizing the file nomenclature: with values
%   nom_type='': constant name [filebase ext] (default output if 'nom_type' is undefined)
%   nom_type='*':constant name for a file representing a series (e.g. avi movie)
%   nom_type='1','01',or '001'...': series of files with a single index i without separator(e.g. 'aa045.png').
%   nom_type='_1','_01','_001'...':  series of files with a single index i with separator '_'(e.g. 'aa_045.png').
%   nom_type='1a','1A','01a','01A',... with a numerical index and an index letter(e.g.'aa45b.png') (lower or upper case)
%   nom_type='_1a','_1A','_01a','_01A',...: idem, with a separator '_' before the index
%   nom_type='_1_1','_01_1',...: matrix of files with two indices i and j separated by '_'(e.g. 'aa_45_2.png')
%   nom_type='_i1-i2': from pairs from a single index (e.g. 'aa_45-47.nc')
%   nom_type='_i_j1-j2': pairs of j indices (e.g. 'aa_45_2-3.nc')
%   nom_type='_i1-i2_j': pairs of i indices (e.g. 'aa_45-46_2.nc')
%   nom_type='_1_ab','1_ab','01_ab'..., from pairs of '#' images (e.g.'aa045bc.nc'), ext='.nc'
%'comp_input' (for nom_type involving index pairs (e.g. netc))
%       comp_input=1: the index pair is imposed, 
%       comp_input=0: the index pair is automatically searched, choosing the most recent  file in case of multiple choice
% 'num_i2': second index i (for nom_type involving index pairs (e.g. netc))
% 'num_j2': second index j (for nom_type involving index pairs (e.g. netc))
% 'subdir': (used for nom_type=netc...) string representing the name of the subdirectory 'subdir' containing file. 
%       subdir='': no subdirectory, 
%       subdir='?', the file is first searched with no subdirectory, then in the most recently modified subdirectory if not detected.

% A FAIRE: si comp_inpu=0, si _i_j n'existe pas, chercher _i, 
function [filename,num_i1_out,num_j1_out,num_i2_out,num_j2_out,subdir_out]=...
           name_generator(filebase,num_i1,num_j1,ext,nom_type,comp_input,num_i2,num_j2,subdir)
sizf=size(filebase);
if (~ischar(filebase)||~isequal(sizf(1),1)),filebase='';end
if ~exist('ext','var')
    ext='';
end
if ~exist('nom_type','var')
    nom_type='';
end
if ~ischar(ext),ext='';end
% idetect=0;
if ~exist('num_i1','var') || isempty(num_i1) || isnan(num_i1)
    num_i1=1; %default
end
if ~exist('num_j1','var') ||  isempty(num_j1) || isnan(num_j1)
    num_j1=1; %default
end
if ~exist('num_i2','var') ||  isempty(num_i2) || isnan(num_i2)
    num_i2=num_i1; %default
end
if ~exist('num_j2','var') || isempty(num_j2) || isnan(num_j2)
    num_j2=num_j1; %default
end
if ~exist('subdir','var')|| isempty(subdir) 
    subdir='' ; %default
end
num_i1_out=num_i1;%default output
num_j1_out=num_j1;%default output
num_i2_out=num_i2;%default output
num_j2_out=num_j2;%default output
test_pairs=numel(nom_type)>=2 &&(strcmp(nom_type,'_i1-i2_j1-j2')|| strcmp(nom_type(end-1:end),'ab')|| strcmp(nom_type(end-1:end),'AB')||...
                strcmp(nom_type,'_i_j1-j2')|| strcmp(nom_type,'_i1-i2_j')||strcmp(nom_type,'_i1-i2'));
%test_2D= strcmp(nom_type(end-1:end),'ab')|| strcmp(nom_type(end-1:end),'AB') ||strcmp(nom_type,'_i_j1-j2');
%test_3D=strcmp(nom_type,'_i1-i2_j')|| strcmp(nom_type,'_i1-i2');
if ~isequal(subdir,'') && ~isequal(subdir,'?') 
      [Path,Name]=fileparts(filebase);
      filename=fullfile(Path,subdir,Name);
else
    filename=filebase;%default
end 
if ~test_pairs%case of a single index i, and possibly j
%     numlength=numel(nom_type);
    nom_type_mod=nom_type;
    num_j_str='';
    if strcmp(nom_type,'1')
        filename=[filename num2str(num_i1) ext];
    elseif length(nom_type)<=1%fixed name , no indexing, for instance '*'
        filename=[filename ext];
    else
        nom_type_mod=nom_type;
        if strcmp(nom_type(1),'_')
            filename=[filename '_'];
            nom_type_mod(1)=[];
        end
        if strcmp(nom_type_mod(end),'a')
            nom_type_mod(end)=[];
            num_j_str=char(num_j1+96);% lower letter corresponding to the index
        elseif strcmp(nom_type_mod(end),'A')
            nom_type(end)=[];
            num_j_str=char(num_j1+64);% lower letter corresponding to the index
        elseif isequal(numel(regexp(nom_type_mod,'_')),1)%if a second separator '_' exists in nom_type
            num_j_str=['_' num2str(num_j1)];
            nom_type_mod(regexp(nom_type_mod,'_'):end)=[];
        else
            num_j1_out=[];%no index j
        end
        if ~isnan(str2double(nom_type_mod))    
            numtype=['%0' num2str(length(nom_type_mod)) 'd'];%indicate the number of digits (0 before the number)
            filename=[filename num2str(num_i1,numtype) num_j_str ext];
            num_i2_out=num_i1_out;
            num_j2_out=num_j1_out;
        else %fixed name 
            filename=[filename ext];
        end
    end

%case of derived file indexing (e.g. netcdf files)
else
    % case of an imposed image pair (comp_input=1)
    if  (exist('comp_input','var') && isequal(comp_input,1))
            if strcmp(nom_type(1),'_')
                filename=[filename '_'];
                nom_type(1)=[];
            end
            if strcmp(nom_type(end-1:end),'AB')||strcmp(nom_type(end-1:end),'ab')
                if strcmp(nom_type(end-1:end),'AB')
                    nchar=64;
                else
                    nchar=96;
                end
                if isequal(num_j1,num_j2)% case of displacements at the same time
                    num_j_str=char(num_j1+nchar);
                else
                    num_j_str=[char(num_j1+nchar) char(num_j2+nchar)];
                end
                if strcmp(nom_type(end-2),'_')
                    numstr=['%0' num2str(numel(nom_type)-3) 'd'];
                    num_j_str=['_' num_j_str];
                else
                    numstr=['%0' num2str(numel(nom_type)-2) 'd'];
                end
                filename=[filename num2str(num_i1,numstr) num_j_str ext];
                num_i2_out=num_i1;
            elseif isequal(nom_type,'i_j1-j2')
                if isequal(num2str(num_j1),num2str(num_j2))% case of displacements at the same time
                    filename=[filename num2str(num_i1) '_' num2str(num_j1) ext];
                else
                    filename=[filename num2str(num_i1) '_' num2str(num_j1) '-' num2str(num_j2) ext];
                end
                num_i2_out=num_i1;
            elseif  isequal(nom_type,'i1-i2_j')
                if isequal(num2str(num_i1),num2str(num_i2))% case of displacements at the same time
                      filename=[filename num2str(num_i1) '_' num2str(num_j1) ext];
                else
                    filename=[filename num2str(num_i1) '-' num2str(num_i2) '_' num2str(num_j1) ext];
                end
                num_j2_out=num_j1;
            elseif  isequal(nom_type,'i1-i2')
                if isequal(num2str(num_i1),num2str(num_i2))% case of displacements at the same time
                     filename=[filename num2str(num_i1) ext];
                else
                    filename=[filename num2str(num_i1) '-' num2str(num_i2) ext];
                end
                num_j2_out=num_j1;
            elseif isequal(nom_type,'i1-i2_j1-j2')
                if isequal(num2str(num_i1),num2str(num_i2))% case of displacements at the same time
                    app1= num2str(num_i1);
                else
                    app1= [num2str(num_i1) '-' num2str(num_i2)];
                end
                if isequal(num2str(num_j1),num2str(num_j2))% case of displacements at the same time
                    app2= num2str(num_j1);
                else
                    app2= [num2str(num_j1) '-' num2str(num_j2)];
                end     
                filename=[filename app1 '_' app2 ext];
            end
            idetect=1;
           % idetect=(exist(filename,'file')==2);
     % case of an image pair to determine (comp_input=0)
    else
          [filename,num_i1_out,num_j1_out,num_i2_out,num_j2_out,idetect]=search_pair(filename,num_i1,num_j1,num_i2,nom_type);
    end
    
     %look for sub-directories containing netcdf files
    if idetect==0 && isequal(subdir,'?')
        [pathfile,name]=fileparts(filebase);
        direct=dir(pathfile);%directory containing filebase
        datedir=[];%default
%         idir=0;
        indir=find(cell2mat({direct.isdir}));% find indices of subdirectories
        direct=direct(indir(3:end));% keep only the subdirectories,eliminating the two first terms '.' and '..'
        lengthdir=length(direct);
        if lengthdir==0
            subdir='';% no subdirectory found
        else
            for idir=1:lengthdir
                date_str=direct(idir).date;%string of the date of last modification
                datedir(idir)=0;%default
                char_code=double(date_str);% code of the date characters
                special_char=(char_code>127); %non standard Ascii character (e.g. date in french)
                if isempty(find(special_char,1))% standard Ascii character 
                    datedir(idir)=datenum(date_str);
                end                            
%                 datedir(idir)=datenum(direct(idir).date); %absolute date of last directory modification
            end
            [mostrec,indrec]=max(datedir);% most recently modified subdir chosen by default
            subdir=direct(indrec).name; %chosen directory
        end
        filebasesub=fullfile(pathfile,subdir,name);
        %if the image pair is imposed
        if (exist('comp_input','var') && isequal(comp_input,1)) 
            if isequal(nom_type,'#_ab')
                filename=[filebasesub num2str(num_i1,'%03d') '_' num2stra(num_j1,nom_type) num2stra(num_j2,nom_type) ext];
            elseif isequal(nom_type,'_i1_j1-j2')
                filename=[filebasesub '_' num2str(num_i1) '_' num2str(num_j1) '-' num2str(num_i2) ext];
            elseif isequal(nom_type,'_i1-i2_j')
                filename=[filebasesub '_' num2str(num_i1) '-' num2str(num_i2) '_' num2str(num_j1) ext];
            elseif isequal(nom_type,'_i1-i2')
                filename=[filebasesub '_' num2str(num_i1) '-' num2str(num_i2) ext];
            end
%             idetect=(exist(filename,'file')==2);
        else
            [filename,num_i1_out,num_j1_out,num_i2_out,num_j2_out]=search_pair(filebasesub,num_i1,num_j1,num_i2,nom_type);             
        end
    end
end
if ~strcmp(subdir,'?')
    subdir_out=subdir;
else
    subdir_out='';
end

%------------------------------------------------------------------------
% --- search the appropriate image pair (netcdf file) corresponding to a given image number
function [filename,num_i1,num_j1,num_i2,num_j2,idetect]=search_pair(filebasesub,num_i1,num_j1,num_i2,nom_type)
%------------------------------------------------------------------------
% for nom_type=netc_2D or netc_old, it searches all the pairs corresponding
% to num_i1, and chooses the most recent file.
%for nom_type=netc_3D or netc_series, it searches all the pairs (num_i1
%num_i2), with num_i1 as the first  index, and chooses the most recent file.

filename=[];num_j2=[];idetect=0;%default values
if isequal(nom_type,'#_ab')
    dirpair=dir([filebasesub num2str(num_i1,'%03d') '_*.nc']);
elseif isequal(nom_type,'_i_j1-j2')
    dirpair=dir([filebasesub '_' num2str(num_i1) '_*-*.nc']);
elseif isequal(nom_type,'_i1-i2_j')
    dirpair=dir([filebasesub '_' num2str(num_i1) '-*_' num2str(num_j1) '.nc']);
elseif isequal(nom_type,'_i1-i2')
    dirpair=dir([filebasesub '_' num2str(num_i1) '-*.nc']);
    if isempty(dirpair)
        dirpair=dir([filebasesub '_*-' num2str(num_i2) '.nc']);
    end
end
nbpair=length(dirpair);
if nbpair >= 1 %choose the most recent file if several are found
    idetect=1; %detected pair
    datepair=zeros(1,nbpair);%default
    for ipair=1:nbpair
         date_str=dirpair(ipair).date;%string of the date of last modification
         char_code=double(date_str);% code of the date characters
         special_char=(char_code>127); %non standard Ascii character (e.g. date in french)
         if isempty(find(special_char))% standard Ascii character 
             datepair(ipair)=datenum(date_str);
         end    
    end
    [choice,indpair]=max(datepair);
    [pathname,file,field_count,str2,str_a,str_b]=name2display(dirpair(indpair).name);
    num_i1=str2double(field_count);
    num_i2=str2double(str2);
    if isnan(num_i2)
        num_i2=num_i1;
    end
    num_j1=stra2num(str_a);
    num_j2=stra2num(str_b);
     pathname=fileparts(filebasesub);% CORRIGE LE 6 JUIN (ETAIT DESACTIVE)
    filename=fullfile(pathname,dirpair(indpair).name);
end


