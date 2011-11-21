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
%   nom_type='_i1-i2': from pairs from a single index (e.g. 'aa_45-47.nc')
%   nom_type='_i_j1-j2': pairs of j indices (e.g. 'aa_45_2-3.nc')
%   nom_type='_i1-i2_j': pairs of i indices (e.g. 'aa_45-46_2.nc')
%   nom_type='_1_ab','1_ab','01_ab'..., from pairs of '#' images (e.g.'aa045bc.nc'), ext='.nc'
%subdir: name of the subdirectory for netcdf files
%
%INPUT:
%fileinput: complete name of the file, including path

function [RootPath,RootFile,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fileinput)
% siz=length(fileinput);
% indcur=siz;
% default values:
% test_=0;
field_count='';%character string
str2='';
str_a='';
str_b='';
% ext='';
nom_type='';
subdir='';
        %select file extension
[RootPath,RootFile,ext]=fileparts(fileinput);
indcur=length(RootFile);% nbre of characters in fileraw

        %recognize the name form
% filerawascii=double(RootFile);%ascci code
% val=(48>filerawascii)|(filerawascii>57); % test for the non-numerical characters
indsel=regexp(RootFile,'\D');% character indices of non numerical characters
filelit=RootFile(indsel);% fileraw name with numbers removed
nbchar=length(indsel);
if nbchar<4% put '*' before the name (remove at the end)
   prefilelit(1:4-nbchar)='*';%insert 3_nbchar '*' in the file name
   filelit=[prefilelit filelit];
   indsel=[1:4-nbchar indsel+4-nbchar];
   RootFile=[prefilelit RootFile];
   indcur=indcur+4-nbchar;
end
separ3=indsel(end);% index of last non numerical character in fileraw
separ2=indsel(end-1);% index of previous non numerical character
separ1=indsel(end-2);
separ0=indsel(end-3);
num1='';num2='';num3='';
if separ1>=separ0+1,num0=RootFile(separ0+1:separ1-1);end
if separ2>=separ1+1,num1=RootFile(separ1+1:separ2-1);end
if separ3>=separ2+1,num2=RootFile(separ2+1:separ3-1);end
if indcur>=separ3+1,num3=RootFile(separ3+1:indcur);end
last_str=RootFile(indcur);%last character in fileraw
last=double(last_str);%corresponding ascii code
penult=double(RootFile(indcur-1));%ascii code of the penultimate character
testsub=0; %default 
% case of an indexed series in a single file
if strcmpi(ext,'.avi')
     nom_type='*';
%case of a numerical index follewed by a lower case letter (e.g. a,b,c):
%the penultimate character is a number and the last one a letter (lower case: last >= 97 && last <= 122
%                                                                 capital
%                                                                 letter:  last >= 65 && last <= 90)  
elseif  penult >= 48 && penult <= 57 && ((last >= 65 && last <= 90)||(last >= 97 && last <= 122))
    str_a=last_str; %extract appendix a,b,c... or A,B,C... as output.
    ind_end=indcur-1; %current index just before the suffix letter
    indices_root=regexp(RootFile(1:indcur-1),'\D');%detect non digit characters
    indcur=max(indices_root);
    field_count=RootFile(indcur+1:ind_end);
    charstring=['%0' num2str(length(field_count)) 'd'];
    nom_type=num2str(1,charstring);
    if strcmp(RootFile(indcur),'_')
       nom_type=['_' nom_type];
       indcur=indcur-1;
    end
    if (last >= 65 && last <= 90)
        nom_type=[nom_type 'A'];
    else
        nom_type=[nom_type 'a'];
    end   
elseif strcmp(filelit(end-2:end),'-_-_')%new  nomenclature appendix num1-num2_num_a-num_b
    field_count=num0;
    str2=num1;
    str_a=num2;
    str_b=num3;
    nom_type='_i1-i2_j1-j2';
    testsub=1;
    indcur=separ0-1;
elseif strcmp(filelit(end-2:end),'_-_')%new  nomenclature appendix num1-num2_num_a
    field_count=num1;
    str2=num2;
    str_a=num3;
    nom_type='_i1-i2_j';
    testsub=1;
    indcur=separ1-1;
elseif strcmp(filelit(end-2:end),'__-')%new  nomenclature appendix num1_num2-num2 
    indcur=separ1-1;
    field_count=num1;
    str_a=num2;
    str_b=num3;
    nom_type='_i_j1-j2';
    testsub=1;
elseif strcmp(filelit(end-1:end),'_-')
    indcur=separ2-1;
    field_count=num2;
    str2=num3;
    str_a='';
    nom_type='_i1-i2';
    testsub=1;
elseif strcmp(filelit(end-1:end),'__')
    indcur=separ2-1;
    field_count=num2;
    str2='';
    str_a=num3;
    nom_type='_1_1';
elseif strcmp(filelit(end),'_')
    indcur=separ3-1;
    str2='';
    str_a='';
    %detect zeros before the number
    field_count=RootFile(separ3+1:end);% set the selected field number'%03d'
    charstring=['%0' num2str(length(field_count)) 'd'];
    nom_type=['_' num2str(1,charstring)];
elseif RootFile(indcur-2)=='_'% search appendix a,b,c,d
    lasts=RootFile(indcur-1:indcur);
%     if isequal(length(last),2) 
        str_a=lasts(1);%put appendix a,b,c, ou d
        str_b=lasts(2);%put appendix a,b,c, ou d
        separ0=indsel(end-3);
        field_count=RootFile(separ0+1:separ1-1);
        indcur=separ0;
        if double(lasts) >= 97 & double(lasts)<= 122 
            nom_type='_ab';
            testsub=1;
        elseif double(lasts) >= 65 & double(lasts) <= 90 
            nom_type='_AB';
            testsub=1;
        end
        charstring=['%0' num2str(length(field_count)) 'd'];
        nom_type=[num2str(1,charstring) nom_type];
%     end
%search for other names with counter
else
    if length(ext)>1     
            num=1;count=0; % extract the numerical appendix
            while num==1;
                filascii=double(RootFile(indcur));
                if (48>filascii)||(filascii>57); % select the non-numerical characters
                    num=0; 
                else
                    indcur=indcur-1; count=count+1;
                end
            end
            if count~=0   
                field_count=RootFile(indcur+1:indcur+count);% set the selected field number'%03d'
                charstring=['%0' num2str(length(field_count)) 'd'];
                nom_type=num2str(1,charstring);
            end
    end
end
            %select the root name in the file_input window
RootFile=RootFile(1:indcur);
if nbchar<4% put '*' before the name (remove at the end)
   RootFile(1:4-nbchar)=[];
end
if testsub
    [RootPath,subdir,extdir]=fileparts(RootPath);
    subdir=[subdir extdir];
end

%resolve ambigous nomenclature types when the number of 0 is unknown (type %0...):
ind_zero=findstr('0',nom_type);
nb_zero=numel(ind_zero);
if ~isempty(ind_zero)
    for itest=0:nb_zero-1
        filename=name_generator(fullfile(RootPath,RootFile),1,1,ext,nom_type,1,1,1,subdir);
        if exist(filename,'file')
            break
        else
            nom_type(ind_zero(1))=[]; % remove a zero in nom_type
        end
    end
end
