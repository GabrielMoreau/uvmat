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
%   nom_type='_i': series of files with a single index i preceded by '_'(e.g. 'aa_45.png').
%   nom_type='#', series of indexed images wich is not series_i [filebase index ext], e.g. 'aa045.jpg' or 'aa45.tif'
%   nom_type='_i_j': matrix of files with two indices i and j separated by '_'(e.g. 'aa_45_2.png')
%   nom_type='_i1-i2': from pairs from a single index (e.g. 'aa_45-47.nc') 
%   nom_type='_i_j1-j2': pairs of j indices (e.g. 'aa_45_2-3.nc')
%   nom_type='_i1-i2_j': pairs of i indices (e.g. 'aa_45-46_2.nc')
%   nom_type='#a','#A", with a numerical index and an index letter(e.g.'aa045b.png') (lower or upper case)
%   nom_type='raw_SMD', same as '#' but with no extension ext='', OBSOLETE
%   nom_type='#_ab', from pairs of '#' images (e.g. 'aa045bc.nc'), ext='.nc', OBSOLETE (replaced by '_i_j1-j2')
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
filerawascii=double(RootFile);%ascci code
val=(48>filerawascii)|(filerawascii>57); % test for the non-numerical characters
indsel=find(val);% character indices of non numerical characters
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
if strcmpi(ext,'.avi')
     nom_type='*';
      %case of old image nomenclature
elseif (strcmp(ext,'.png') || strcmp(ext,'')) &&  penult >= 48 && penult <= 57 && (last < 48 || last > 57)
    % if the penultimate character is a number and the last a letter
    % search the appendix a,b,c,
    str_a=last_str; %put appendix a,b,c....
    indcur=indcur-1;
    if strcmp(ext,'.png'), nom_type='#a'; end
    if strcmp(ext,''), nom_type='raw_SMD'; end      
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
            field_count=RootFile(indcur+1:indcur+count);% set the selected field number
    end
elseif  penult >= 48 && penult <= 57  && (last <= 66 && last >= 65)% PCO camera Toulouse, end with A or B (NEW)
    % if the penultimate character is a number and the last a letter
    % search the appendix a,b,c,
    str_a=last_str; %put appendix a,b,c....
    indcur=indcur-1;
    nom_type='#A';   
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
            field_count=RootFile(indcur+1:indcur+count);% set the selected field number
    end   
    indcur=indcur-1;
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
    nom_type='_i_j';
elseif strcmp(filelit(end),'_')
    indcur=separ3-1;
%     field_count=num3;
    str2='';
    str_a='';
    %detect zeros before the number
%     count=0; % extract the numerical appendix
    if strcmp('0',RootFile(separ3+1)); % select the non-numerical characters
        nom_type=['_%0' num2str(length(RootFile(separ3+1:end))) 'd'];
    else
        nom_type='_i';
    end  
    field_count=RootFile(separ3+1:end);% set the selected field number'%03d' 
elseif RootFile(indcur-2)=='_'% search appendix a,b,c,d
    last=RootFile(indcur-1:indcur);
    if isequal(length(last),2) && double(last(1)) >= 97 && double(last(1)) <= 122 ...% = 1 for letters
            && double(last(2)) >= 97 && double(last(2)) <= 122
          str_a=last(1);%put appendix a,b,c, ou d
          str_b=last(2);%put appendix a,b,c, ou d
%           indcur=indcur-3;
          separ0=indsel(end-3);
        num0=RootFile(separ0+1:separ1-1);
        field_count=num0;
        indcur=separ0;
        nom_type='#_ab';
        testsub=1;
    end
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
                if isequal(field_count(1),'0')
                    nbfigures=length(field_count);
                    nom_type=['%0' num2str(nbfigures) 'd'];
                else
                    nom_type='#';
                end
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
