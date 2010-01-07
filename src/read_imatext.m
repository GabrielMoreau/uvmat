%'read_imatext': reads the .civ file for image documentation (obsolete)
% fileinput: name of the documentation file 
% time: matrix of times for the set of images
%pxcmx: scale along x in pixels/cm
%pxcmy: scale along y in pixels/cm
function [error,time,TimeUnit,mode,npx,npy,pxcmx,pxcmy]=read_imatext(fileinput);
error=0;%default
time=[]; %default
TimeUnit='s';
mode='pairs';
npx=[]; %default
npy=[]; %default
pxcmx=1;%default
pxcmy=1;%default
if exist(fileinput,'file')~=2, error=2, return;end;%input file does not exist
dotciv=textread(fileinput);
sizdot=size(dotciv);
if ~isequal(sizdot(1)-8,dotciv(1,1));
    error=1; %inconsistent number of bursts
end
nbfield=sizdot(1)-8;
npx=(dotciv(2,1));
npy=(dotciv(2,2));
pxcmx=(dotciv(6,1));% pixels/cm in the .civ file 
pxcmy=(dotciv(6,2));
% nburst=dotciv(3,1); % nbre of bursts
abs_time1=dotciv([9:nbfield+8],2);
dtime=dotciv(5,1)*(dotciv([9:nbfield+8],[3:end-1])+1);
timeshift=[abs_time1 dtime];
time=cumsum(timeshift,2);