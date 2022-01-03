%'sub_background': substract background to an image series, used with series.fig
%------------------------------------------------------------------------
% function GUI_input=aver_stat(num_i1,num_i2,num_j1,num_j2,Series)
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
%num_i1: series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2: series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1: series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2: series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%Series: Matlab structure containing information set by the series interface
%       .RootPath: path to the image series
%       .RootFile: root file name
%       .FileExt: image file extension 
%       .NomType: nomenclature type for file indexing
%       .NbSlice: %number of slices defined on the interface
%----------------------------------------------------------------------
% Method: 
%    calculate the background image by sorting the luminosity of each point
%     over a sliding sub-sequence of 'nbaver_ima' images.
%     The luminosity value of rank 'rank' is selected as the
%     'background'. rank=nbimages/2 gives the median value.  Smaller values are appropriate
%     for a dense set of particles. The extrem value rank=1 gives the true minimum
%     luminosity, but it can be polluted by noise.
% Organization of image indices:
%     The program is working on a series of images, labelled by two indices i and j, given
%     by the input matlab vectors num_i1 and num_j1 respectively. In the list, j is the fastest increasing index.
%     The processing can be done in slices (number nbslice), with bursts of
%     nbfield2 successive images for a given slice (mode 'multilevel')
%     In the mode 'volume', nbfield2=1 (1 image at each level)

%=======================================================================
% Copyright 2008-2022, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function GUI_input=calc_background (num_i1,num_i2,num_j1,num_j2,Series)

%------------------------------------------------------------------------
%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
    GUI_input={'RootPath';'on';...
        'SubDir';'off';... % subdirectory of derived files (PIV fields), ('on' by default)
        'RootFile';'on';... %root input file name ('on' by default)
        'FileExt';'on';... %inputf file extension ('on' by default)
        'NomType';'on';...%type of file indexing ('on' by default)
        'NbSlice';'on'; ...%nbre of slices ('off' by default)
        %'VelTypeMenu';'on';...% menu for selecting the velocity type (civ1,..)('off' by default)
        %'FieldMenu';'on';...% menu for selecting the velocity field (s) in the input file ('off' by default)
        %'VelTypeMenu_1';'on';...% menu for selecting the velocity type (civ1,..)('off' by default)
        %'FieldMenu_1';'on';...% menu for selecting the velocity field (s) in the input file ('off' by default)
        %'CoordType';...%can use a transform function
        %'GetObject';...;%can use projection object
        %'GetMask';...;%can use mask option  
        %'PARAMETER';'NbSliding';...
        %'PARAMETER';'VolumeScan';...
        %'PARAMETER';'RankBrightness';...
               ''};
    return %exit the function 
end

%----------------------------------------------------------------
%% initiate the waitbar
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position');
%-----------------------------------------------------------------
if iscell(Series.RootPath)
    msgbox_uvmat('ERROR','This function use only one input image series')
    return
end

%% determine input image type
FileType=[];%default
MovieObject=[];
FileExt=Series.FileExt;

if isequal(lower(FileExt),'.avi')
    hhh=which('mmreader');
    if ~isequal(hhh,'')&& mmreader.isPlatformSupported()
        MovieObject=mmreader(fullfile(RootPath,[RootFile FileExt]));
        FileType='movie';
    else
        FileType='avi';
    end
elseif isequal(lower(FileExt),'.vol')
    FileType='vol';
else 
   form=imformats(FileExt(2:end));
   if ~isempty(form)% if the extension corresponds to an image format recognized by Matlab
       if isequal(Series.NomType,'*');
           FileType='multimage';
       else
           FileType='image';
       end
   end
end
if isempty(FileType)
    msgbox_uvmat('ERROR',['invalid file extension ' FileExt ': this function only accepts image or movie input'])
    return
end

nbslice_i=Series.NbSlice; %number of slices 
siz=size(num_i1);
nbaver_init=23;%approximate number of images used for the sliding background: to be adjusted later to include an integer number of bursts

filebase=fullfile(Series.RootPath,Series.RootFile);
dir_images=Series.RootPath;
nom_type=Series.NomType;

%% create dir of the new image
% [dir_images,namebase]=fileparts(filebase);
term='_background';

[pp,subdir_ima]=fileparts(Series.RootPath);
try
    mkdir([dir_images term]);
catch ME
            msgbox_uvmat('ERROR',ME.message);
            return
end
[xx,msg2] = fileattrib([dir_images term],'+w','g'); %yield writing access (+w) to user group (g)
if ~strcmp(msg2,'')
    msgbox_uvmat('ERROR',['pb of permission for ' subdir_ima term ': ' msg2])%error message for directory creation
    return
end
filebase_b=fullfile([dir_images term],Series.RootFile);

%% set processing parameters
prompt = {'The number of positions (laser slices)';'volume scan mode (Yes/No)';...
        'the luminosity rank chosen to define the background (0.1=for dense particle seeding, 0.5 (median) for sparse particles'};
dlg_title = ['get (slice by slice) a  background , result in subdir ' subdir_ima term];
num_lines= 3;
def     = {'1';'No';'0.1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
vol_test=answer{2};
if isequal(vol_test,'Yes')
    nbfield2=1;%case of volume: no consecutive series at a given level
    nbslice_i=siz(1);%number of slices 
else
    nbfield2=siz(1); %nb of consecutive images at each level(burst)
%     if siz(2)>1
%        nbslice_i=str2num(answer{1})/(num_i1(1,2)-num_i1(1,1));% number of slices
%     else
        nbslice_i=1;
%     end
%     if ~isequal(floor(nbslice_i),nbslice_i)
%         msgbox_uvmat('ERROR','the number of slices must be a multiple of the i increment')
%         return
%     end
end
lengthtot=siz(1)*siz(2);
nbfield=floor(lengthtot/(nbfield2*nbslice_i));%total number of i indexes (adjusted to an integer number of slices)
nbfield_slice=nbfield*nbfield2;% number of fields per slic
rank=floor(str2num(answer{3})*nbfield_slice);
if rank==0
    rank=1;%rank selected in the sorted image series
end

%% prealocate memory for the background
first_image=name_generator(filebase,num_i1(1),num_j1(1),Series.FileExt,Series.NomType);
Afirst=read_image(first_image,FileType,num_i1(1),MovieObject);
[npy,npx]=size(Afirst);
try
    Ak=zeros(npy,npx,nbfield_slice,'uint16'); %prealocate memory
catch ME
    msgbox_uvmat('ERROR',ME.message)
    return
end


%MAIN LOOP ON SLICES
% 
% nbfield_slice
% nbslice_i
% for islice=1:nbslice_i
%     %% select the series of image indices at the level islice
%     for ifield=1:nbfield
%         for iburst=1:nbfield2
%             indselect(iburst,ifield)=((ifield-1)*nbslice_i+(islice-1))*nbfield2+iburst;
%         end
%     end
%     
    %% read the first series of nbaver_ima images and sort by luminosity at each pixel
    for ifile = 1:nbfield_slice
%         ifile=indselect(ifield);
        filename=name_generator(filebase,num_i1(ifile),num_j1(ifile),Series.FileExt,Series.NomType)
        try
            Aread=read_image(filename,FileType,num_i1(ifile),MovieObject);
        catch ME
            msgbox_uvmat('ERROR',ME.message)
            return
        end
        Ak(:,:,ifile)=Aread;
            %finish the waitbar
        update_waitbar(hseries.waitbar,WaitbarPos,1)
    end
    Ak=sort(Ak,3);
    C=Ak(:,:,rank);
    [newname]=...
        name_generator(filebase_b,num_i1(1),num_j1(1),'.png','none') % makes the new file name  
    imwrite(C,newname,'BitDepth',16); % save the new image
% end   
    



%------------------------------------------------------------------------
%--read images and convert them to the uint16 format used for PIV
function A=read_image(filename,type_ima,num,MovieObject)
%------------------------------------------------------------------------
%num is the view number needed for an avi movie
switch type_ima
    case 'movie'
        A=read(MovieObject,num);
    case 'avi'
        mov=aviread(filename,num);
        A=frame2im(mov(1));
    case 'multimage'
        A=imread(filename,num);
    case 'image'    
        A=imread(filename);
end
siz=size(A);
if length(siz)==3;%color images
    A=sum(double(A),3);
end
    
