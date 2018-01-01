% 'lumin_cali': check the luminosity of the camera lens versus distance to image center
%----------------------------------------------------------------------

%=======================================================================
% Copyright 2008-2018, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function input_list=lumin_calib (num_i1,num_i2,num_j1,num_j2,Series)

%display  request  of input parameters in the series interface (activated directly by the selection in the menu ACTION)
input_list={'NbSlice';...%nbre of slices 
    'RootPath';... %path to the input root file
    'RootFile';... %root input file name
    'FileExt';... %input file extension
    'NomType';...%type of file indexing
    'SubDir';...% subdirectory of derived files (PIV fields)
    };

if ~exist('num_i1','var')
    return %  used to display the right input data from input_list when the function is selected
end
for ilist=1:length(input_list)
    eval([input_list{ilist} '= Series.' input_list{ilist} ';'])
end

%-----------------------------------------------------------------

hRUN=findobj(Series.hseries,'Tag','RUN');
hwaitbar=findobj(Series.hseries,'Tag','waitbar');
waitbarpos(1)=Series.WaitbarPos(1);%x position of the waitbar
waitbarpos(3)=Series.WaitbarPos(3);% width of the waitbar
siz=size(num_i1);


xpos(1:10)=[297 297 297 314 316 310 310 310 312 325];
ypos(1:10)=[818 818 818 817 822 820 820 820 813 799];
xpos(11:30)=[364 403 448 479 522 586 613 630 626 581 514 470 380 328 292 292 292 292 292 299];
ypos(11:30)=[733 673 604 558 504 405 357 339 337 409 509 570 701 789 845 845 845 845 845 836];
xpos(31:49)=[353 273 269 269 269 269 269 270 270 270 270 270 270 270 270 268 268 264 216 ];
ypos(31:49)=[748 875 883 883 883 883 883 888 888 888 888 888 888 888 888 888 888 885 959];
radius=50;
Abackground=58.6;

filebase=fullfile(Series.RootPath{1},Series.RootFile{1});
dir_images=Series.RootPath{1};
nom_type=Series.NomType{1};
% filebad=zeros(size(num_i1));
indbad=[21 22 30];%bad image
file_index= 1:length(num_i1);
ifile=0;
for ifile= 1:length(num_i1)
               [filename,idetect]=...
                       name_generator(filebase,num_i1(ifile),num_j1(ifile),Series.FileExt{1},Series.NomType{1});
                 
               A=imread(filename); 
               A=flipdim(A,1);
               ind_x=[xpos(ifile)-radius:xpos(ifile)+radius];
               ind_y=[ypos(ifile)-radius:ypos(ifile)+radius];
               A=double(A(ind_y,ind_x))-Abackground;
               [Xi,Yi]=meshgrid([-radius:+radius],[-radius:+radius]);
%                distX=(Xi+radius+1);
%                distY=(Yi+radius+1);
               testin=(Xi.*Xi+Yi.*Yi)<=radius*radius;
               testin=double(testin);
               A=(A>0).*A.*double(testin);
               Amean(ifile)=sum(sum(A))/sum(sum(testin));
               
end
dist=((xpos-512).*(xpos-512))+((ypos-512).*(ypos-512));
dist=dist/(512*512);
file_index(indbad)=[];
Amean(indbad)=[];
dist(indbad)=[];
figure(1)    
plot(file_index,Amean,'+')   
figure(2)
haxes=axes;
h=plot(dist,Amean,'+') 
xlabel('distance to image center (pixels)')
ylabel('luminosity of reference  input dye solution')
set(haxes,'YLim',[0 2850])
