%'name_generator': creates a file name from a root name and indices. 
%---------------------------------------------------------------------
% [filename,idetect,num_i1_out,num_j1_out,num_i2_out,num_j2_out,subdir_out]=...
%        name_generator(filebase,num_i1,num_j1,ext,nom_type,comp_input,num_i2,num_j2,subdir);
%---------------------------------------------------------------------           
% This function detects the existence the constructed file name and it can
% find indices according to file existence if they are not specified
% rmq: this function is related to the reverse functions display2name and name2diplay 
%---------------------------------------------------------------------
% OUTPUT:
% filename: string representing the file name (including path)
% idetect: =1 if the file is detected, 0 otherwise
% num_i1_out,num_j1_out,num_i2_out,num_j2_out,subdir_out: index numbers and subdirectory detected 
%            for free input (= to the corresponding input indices when comp_input=1)
%---------------------------------------------------------------------
% INPUT:
% 'filebase': the root name, 
% 'num_i1: first labelling index i 
% 'num_j1', first labelling index j
% 'ext': file name extension (e.g. '.png' or '.nc')
% 'nom_type': string defining the kind of nomenclature used:
%       nom_type='': constant name [filebase ext] (default output if 'nom_type' is undefined)
%       nom_type='*': the same  file [filebase ext] contains successive fields (ex avi movies)
%       nom_type='_i': series of files with a single index i preceded by '_'(e.g. 'aa_45.png').
%       nom_type='#' series of indexed images wich is not series_i [filebase index ext], e.g. 'aa045.jpg' or 'aa45.tif'
%       nom_type='_i_j' matrix of files with two indices i and j separated by '_'(e.g. 'aa_45_2.png')
%       nom_type='_i1-i2' from pairs from a single index (e.g. 'aa_45-47.nc') 
%       nom_type='_i_j1-j2'pairs of j indices (e.g. 'aa_45_2-3.nc')
%       nom_type='_i1-i2_j' pairs of i indices (e.g. 'aa_45-46_2.nc')
%       nom_type='#a','#A' with a numerical index and an index letter(e.g.'aa045b.png'), OBSOLETE (replaced by 'series_i_j')
%       nom_type='%03d' or '%04d', series of indexed images with numbers completed with zeros to 3 or 4 digits, e.g.'aa045.tif'
%       nom_type='_%03d', '_%04d', or '_%05d', series of indexed images with _ and numbers completed with zeros to 3, 4 or 5 digits, e.g.'aa_045.tif'
%       nom_type='raw_SMD', same as '#a' but with no extension ext='', OBSOLETE
%       nom_type='#_ab' from pairs of '#a' images (e.g. 'aa045bc.nc'), ext='.nc', OBSOLETE (replaced by 'netc_2D')
%       nom_type='%3dab' from pairs of '%3da' images (e.g. 'aa045bc.nc'), ext='.nc', OBSOLETE (replaced by 'netc_2D')
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
           name_generator(filebase,num_i1,num_j1,ext,nom_type,comp_input,num_i2,num_j2,subdir);
sizf=size(filebase);
if (~ischar(filebase)||~isequal(sizf(1),1)),filebase='';end
if ~ischar(ext),ext='';end
% filename=[filebase ext];%default
idetect=0;
if ~exist('num_i1','var') || isequal(num_i1,[]) 
    num_i1=1; %default
end
if ~exist('num_j1','var') || isequal(num_j1,[]) 
    num_j1=1; %default
end
if ~exist('num_i2','var') || isequal(num_i2,[]) 
    num_i2=num_i1; %default
end
if ~exist('num_j2','var') || isequal(num_i2,[]) 
    num_j2=num_j1; %default
end
if ~exist('subdir','var')|| isempty(subdir) 
    subdir='' ; %default
end
num_i1_out=num_i1;%default output
num_j1_out=num_j1;%default output
num_i2_out=num_i2;%default output
num_j2_out=num_j2;%default output

test_pairs=isequal(nom_type,'netc_old')| isequal(nom_type,'netc_2D') | isequal(nom_type,'netc_3D')| isequal(nom_type,'_i1-i2_j1-j2')| ...
  isequal(nom_type,'netc_series')| isequal(nom_type,'#_ab')| isequal(nom_type,'_i_j1-j2')| isequal(nom_type,'_i1-i2_j')| isequal(nom_type,'_i1-i2');
test_2D= isequal(nom_type,'netc_old') |isequal(nom_type,'netc_2D')|isequal(nom_type,'#_ab') |isequal(nom_type,'_i_j1-j2');
test_3D=isequal(nom_type,'netc_3D') |isequal(nom_type,'netc_series')| isequal(nom_type,'_i1-i2_j')| isequal(nom_type,'_i1-i2');
if isequal(nom_type,'series_i')| isequal(nom_type,'_i');
        filename=[filebase '_' num2str(num_i1) ext];
        num_i2_out=num_i1;
        num_j1_out=[];
        num_j2_out=[]; 
elseif length(nom_type)==5 && isequal(nom_type(1:3),'_%0')&& isequal(nom_type(5),'d');
        filename=[filebase '_' num2str(num_i1,nom_type(2:5)) ext];
        num_i2_out=num_i1;
        num_j2_out=num_j1;
elseif isequal(nom_type,'series_i_j')| isequal(nom_type,'_i_j')
        filename=[filebase '_' num2str(num_i1) '_' num2str(num_j1) ext];
        num_i2_out=num_i1;
        num_j2_out=num_j1;
elseif isequal(nom_type,'png_old')| isequal(nom_type,'#a')| isequal(nom_type,'#A')
        filename=[filebase num2str(num_i1,'%03d') num2stra(num_j1,nom_type) ext];
        num_i2_out=num_i1;
        num_j2_out=num_j1;
elseif  length(nom_type)>=5 & isequal(nom_type(2:3),'%0') & isequal(nom_type(5),'d')  %isequal(nom_type,'_%04dA') %camera PCO Toulouse
        filename=[filebase nom_type(1) num2str(num_i1,nom_type(2:4)) num2stra(num_j1,nom_type) ext];
        num_i2_out=num_i1;
        num_j2_out=num_j1;   
elseif isequal(nom_type,'raw_SMD') %suffix a, b, c without extension
        filename=[filebase num2str(num_i1,'%03d') num2stra(num_j1,nom_type)];
        num_i2_out=num_i1;
        num_j2_out=num_j1;
elseif isequal(nom_type,'ima_num')| isequal(nom_type,'#')
        filename=[filebase num2str(num_i1) ext];
        num_i2_out=num_i1;
        num_j1_out=[];
        num_j2_out=[];
elseif length(nom_type)>=4 & isequal(nom_type(1:2),'%0') & isequal(nom_type(end),'d')
        filename=[filebase num2str(num_i1,nom_type) ext]; %test number with a 0 before
        num_i2_out=num_i1;
        num_j1_out=[];
        num_j2_out=[];

%case of derived file indexing (e.g. netcdf files)
elseif test_pairs
    filebasesub=filebase;
    % get the root name filebasesub for the netcdf files
    if  ~isequal(subdir,'') && ~isequal(subdir,'?') 
            [Path,Name]=fileparts(filebase);
            filebasesub=fullfile(Path,subdir,Name);
    end
     %inexistant pair if num_i2=0 or num_j2=0
%     if isequal(num_i2,0)
%         filename=[filebasesub '*-*_' num2str(num_i1) ext];
%         return
%     end
%     if isequal(num_j2,0)
%         filename=[filebasesub '_' num2str(num_i1) '_*-*' ext];
%         return
%     end
    % case of an imposed image pair (comp_input=1)
    if  (exist('comp_input','var') & isequal(comp_input,1)) 
            if isequal(nom_type,'netc_old')|isequal(nom_type,'#_ab')
                if isequal(num2str(num_j1),num2str(num_j2))% case of displacements at the same time
                    filename=[filebasesub num2str(num_i1,'%03d') '_' num2stra(num_j1,nom_type) ext];
                else
                    filename=[filebasesub num2str(num_i1,'%03d') '_' num2stra(num_j1,nom_type) num2stra(num_j2,nom_type) ext];
                end
                num_i2_out=num_i1;
            elseif isequal(nom_type,'netc_2D')|isequal(nom_type,'_i_j1-j2')
                if isequal(num2str(num_j1),num2str(num_j2))% case of displacements at the same time
                    filename=[filebasesub '_' num2str(num_i1) '_' num2str(num_j1) ext];
                else
                    filename=[filebasesub '_' num2str(num_i1) '_' num2str(num_j1) '-' num2str(num_j2) ext];
                end
                num_i2_out=num_i1;
            elseif isequal(nom_type,'netc_3D') || isequal(nom_type,'_i1-i2_j')
                if isequal(num2str(num_i1),num2str(num_i2))% case of displacements at the same time
                      filename=[filebasesub '_' num2str(num_i1) '_' num2str(num_j1) ext];
                else
                    filename=[filebasesub '_' num2str(num_i1) '-' num2str(num_i2) '_' num2str(num_j1) ext];
                end
                num_j2_out=num_j1;
            elseif isequal(nom_type,'netc_series') || isequal(nom_type,'_i1-i2')
                if isequal(num2str(num_i1),num2str(num_i2))% case of displacements at the same time
                     filename=[filebasesub '_' num2str(num_i1) ext];
                else
                    filename=[filebasesub '_' num2str(num_i1) '-' num2str(num_i2) ext];
                end
                num_j2_out=num_j1;
            elseif isequal(nom_type,'_i1-i2_j1-j2')
                if isequal(num2str(num_i1),num2str(num_i2))% case of displacements at the same time
                    app1= [num2str(num_i1)];
                else
                    app1= [num2str(num_i1) '-' num2str(num_i2)];
                end
                if isequal(num2str(num_j1),num2str(num_j2))% case of displacements at the same time
                    app2= [num2str(num_j1)];
                else
                    app2= [num2str(num_j1) '-' num2str(num_j2)];
                end     
                filename=[filebasesub '_' app1 '_' app2 ext];
            end
            idetect=1;
           % idetect=(exist(filename,'file')==2);
     % case of an image pair to determine (comp_input=0)
    else
            [filename,num_i1_out,num_j1_out,num_i2_out,num_j2_out,idetect]=search_pair(filebasesub,num_i1,num_j1,num_i2,nom_type);
    end
    
     %look for sub-directories containing netcdf files
    if idetect==0 && isequal(subdir,'?')
        [pathfile,name]=fileparts(filebase);
        direct=dir(pathfile);%directory containing filebase
        datedir=[];%default
        idir=0;
        indir=find(cell2mat({direct.isdir}));% find indices of subdirectories
        direct=direct(indir([3:end]));% keep only the subdirectories,eliminating the two first terms '.' and '..'
        lengthdir=length(direct);
        if lengthdir==0
            subdir='';% no subdirectory found
        else
            for idir=1:lengthdir
                date_str=direct(idir).date;%string of the date of last modification
                datedir(idir)=0;%default
                char_code=double(date_str);% code of the date characters
                special_char=(char_code>127); %non standard Ascii character (e.g. date in french)
                if isempty(find(special_char))% standard Ascii character 
                    datedir(idir)=datenum(date_str);
                end                            
%                 datedir(idir)=datenum(direct(idir).date); %absolute date of last directory modification
            end
            [mostrec,indrec]=max(datedir);% most recently modified subdir chosen by default
            subdir=direct(indrec).name; %chosen directory
        end
        filebasesub=fullfile(pathfile,subdir,name);
        %if the image pair is imposed
        if (exist('comp_input','var') & isequal(comp_input,1)) 
            if isequal(nom_type,'netc_old')|isequal(nom_type,'#_ab')
                filename=[filebasesub num2str(num_i1,'%03d') '_' num2stra(num_j1,nom_type) num2stra(num_j2,nom_type) ext];
            elseif isequal(nom_type,'netc_2D')|isequal(nom_type,'_i1_j1-j2')
                filename=[filebasesub '_' num2str(num_i1) '_' num2str(num_j1) '-' num2str(num_i2) ext];
            elseif isequal(nom_type,'netc_3D')|isequal(nom_type,'_i1-i2_j')
                filename=[filebasesub '_' num2str(num_i1) '-' num2str(num_i2) '_' num2str(num_j1) ext];
            elseif isequal(nom_type,'netc_series')|isequal(nom_type,'_i1-i2')
                filename=[filebasesub '_' num2str(num_i1) '-' num2str(num_i2) ext];
            end
            idetect=(exist(filename,'file')==2);
        else
            [filename,num_i1_out,num_j1_out,num_i2_out,num_j2_out,idetect]=search_pair(filebasesub,num_i1,num_j1,num_i2,nom_type);             
        end
    end
% elseif isequal(nom_type,'none')|isequal(nom_type,'')|isequal(nom_type,'*')
else
    filebasesub=filebase;
    if ~isequal(subdir,'') && ~isequal(subdir,'?') 
            [Path,Name]=fileparts(filebase);
            filebasesub=fullfile(Path,subdir,Name);
    end
    filename=[filebasesub ext];
    idetect=(exist(filename,'file')==2);  
end
if ~isequal(subdir,'?'), subdir_out=subdir; else, subdir_out='';end;

%---------------------------------------------------------------
% search the appropriate image pair (netcdf file) corresponding to a given
% image number
%-------------------------------------------------------------------
function [filename,num_i1,num_j1,num_i2,num_j2,idetect]=search_pair(filebasesub,num_i1,num_j1,num_i2,nom_type)
% for nom_type=netc_2D or netc_old, it searches all the pairs corresponding
% to num_i1, and chooses the most recent file.
%for nom_type=netc_3D or netc_series, it searches all the pairs (num_i1
%num_i2), with num_i1 as the first  index, and chooses the most recent file.

filename=[];num_j2=[];idetect=0;%default values
if isequal(nom_type,'netc_old')|isequal(nom_type,'#_ab')
    dirpair=dir([filebasesub num2str(num_i1,'%03d') '_*.nc']);
elseif isequal(nom_type,'netc_2D')|isequal(nom_type,'_i_j1-j2')
    dirpair=dir([filebasesub '_' num2str(num_i1) '_*-*.nc']);
elseif isequal(nom_type,'netc_3D')|isequal(nom_type,'_i1-i2_j')
    dirpair=dir([filebasesub '_' num2str(num_i1) '-*_' num2str(num_j1) '.nc']);
elseif isequal(nom_type,'netc_series')|isequal(nom_type,'_i1-i2')
    dirpair=dir([filebasesub '_' num2str(num_i1) '-*.nc']);
    if isempty(dirpair)
        dirpair=dir([filebasesub '_*-' num2str(num_i2) '.nc']);
    end
end
nbpair=length(dirpair);
if nbpair >= 1 %choose the most recent file if several are found
    idetect=1; %detected pair
    for ipair=1:nbpair
         date_str=dirpair(ipair).date;%string of the date of last modification
         datepair(ipair)=0;%default
         char_code=double(date_str);% code of the date characters
         special_char=(char_code>127); %non standard Ascii character (e.g. date in french)
         if isempty(find(special_char))% standard Ascii character 
             datepair(ipair)=datenum(date_str);
         end    
      %  datepair(ipair)=datenum(dirpair(ipair).date);
    end
    [choice,indpair]=max(datepair);
%     [filebase,field_count,str2,str_a,str_b,ext,nom_type]=name2display(dirpair(indpair).name);
    [pathname,file,field_count,str2,str_a,str_b,ext,nom_type]=name2display(dirpair(indpair).name);
    num_i1=str2num(field_count);
    num_i2=str2num(str2);
    num_j1=stra2num(str_a);
    num_j2=stra2num(str_b);
     pathname=fileparts(filebasesub);% CORRIGE LE 6 JUIN (ETAIT DESACTIVE)
    filename=fullfile(pathname,dirpair(indpair).name);
end


