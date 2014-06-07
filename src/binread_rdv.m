function [imgs,timestamps,nb_frames]=binread_rdv(filename,frame_idx)
% BINREAD_RDV Permet de lire les fichiers bin générés par Hiris à partir du
% fichier seq associé.
%   [IMGS,TIMESTAMPS,NB_FRAMES] = BINREAD_RDV(FILENAME,FRAME_IDX) lit
%   l'image d'indice FRAME_IDX de la séquence FILENAME.
%
%   Entrées
%   -------
%   FILENAME  : Nom du fichier séquence (.seq).
%   FRAME_IDX : Indice de l'image à lire. Si FRAME_IDX vaut -1 alors la
%   séquence est entièrement lue. Si FRAME_IDX est un tableau d'indices
%   alors toutes les images d'incides correspondant sont lues. Si FRAME_IDX
%   est un tableau vide alors aucune image n'est lue mais le nombre
%   d'images et tous les timestamps sont renvoyés. Les indices commencent à
%   1 et se termines à NB_FRAMES.
%
%   Sorties
%   -------
%   IMGS        : Images de sortie.
%   TIMESTAMPS  : Timestaps des images lues.
%   NB_FRAMES   : Nombres d'images dans la séquence.



if nargin<2
   frame_idx=-1;
end

s=ini2struct(filename);

w=str2double(s.sequenceSettings.width);
h=str2double(s.sequenceSettings.height);
bpp=str2double(s.sequenceSettings.bytesperpixel);
bin_file=s.sequenceSettings.binfile;
nb_frames=str2double(s.sequenceSettings.numberoffiles);

[p,f]=fileparts(filename);

%bin_dir=s.sequenceSettings.bindirectory;
%if isempty(bin_dir)
   bin_dir=p;
%end

sqb_file=fullfile(p,[f '.sqb']);
m = memmapfile(sqb_file,'Format', { 'uint32' [1 1] 'offset'; ...
   'uint32' [1 1] 'garbage1';...
   'double' [1 1] 'timestamp';...
   'uint32' [1 1] 'file_idx';...
   'uint32' [1 1] 'garbage2' },'Repeat',nb_frames);

data=m.Data;
off=[data.offset];
timestamps=[data.timestamp];
file_idx=[data.file_idx];

if frame_idx==-1
   frame_idx=1:nb_frames;
end

classname=sprintf('uint%d',bpp*8);
imgs=zeros([h,w,length(frame_idx)],classname);

classname=['*' classname];

for i=1:length(frame_idx)
   ii=frame_idx(i);
   f=fullfile(bin_dir,sprintf('%s%.5d.bin',bin_file,file_idx(ii)));
   fid=fopen(f,'rb');
   fseek(fid,off(ii),-1);   
   imgs(:,:,i)=reshape(fread(fid,w*h,classname),w,h)';
   fclose(fid);
end

if ~isempty(frame_idx)
   timestamps=timestamps(frame_idx);
end