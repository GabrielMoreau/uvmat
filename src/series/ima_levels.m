%'ima_levels': rescale the image intensity to reduce strong luminosity peaks
%------------------------------------------------------------------------
% function GUI_input=ima_levels(num_i1,num_i2,num_j1,num_j2,Series)
%
%OUTPUT
% GUI_input=list of options in the GUI series.fig needed for the function
%
%INPUT:
%num_i1: series of first indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_i2:  series of second indices i (given from the series interface as first_i:incr_i:last_i, mode and list_pair_civ)
%num_j1:  series of first indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ )
%num_j2:  series of second indices j (given from the series interface as first_j:incr_j:last_j, mode and list_pair_civ)
%Series: Matlab structure containing information set by the series interface% relabel_i_j: relabel an image series with two indices, according to the time matrix given by ImaDoc
%----------------------------------------------------------------------
function GUI_input=ima_levels(num_i1,num_i2,num_j1,num_j2,Series)
%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('num_i1','var')
    GUI_input={};
    return %exit the function 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%enable waitbar
hseries=guidata(Series.hseries);%handles of the GUI series
WaitbarPos=get(hseries.waitbar_frame,'Position');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

basename=fullfile(Series.RootPath,Series.RootFile) ;

%create dir of the new images
[dir_images,namebase]=fileparts(basename);
[path,subdir_ima]=fileparts(dir_images);
dircur=pwd;
cd(path);
mkdir([subdir_ima '_levels']);
  [xx,msg2] = fileattrib([subdir_ima '_levels'],'+w','g') %yield writing access (+w) to user group (g)
if ~strcmp(msg2,'')
    msgbox_uvmat('ERROR',['pb of permission for ' subdir_ima ': ' msg2])%error message for directory creation
    cd(dircur)
    return
end
cd(dircur);
basename_new=fullfile(path,[subdir_ima '_levels'],namebase);

% read imadoc
%[XmlData,warntext]=imadoc2struct([basename '.xml']);
% nbfield1=size(XmlData.Time,1);
% nbfield2=size(XmlData.Time,2);

msgbox_uvmat('CONFIRMATION','apply image rescaling function levels.m ');

%copy the xml file
if exist([basename '.xml'],'file')
    copyfile([basename '.xml'],[basename_new '.xml']);% copy the .civ file
end

%main loop
nbfield=size(num_i1,2);
nbfield2=size(num_i1,1);
for ifile=1:nbfield
    update_waitbar(hseries.waitbar,WaitbarPos,ifile/nbfield)
    stopstate=get(hseries.RUN,'BusyAction');
    if isequal(stopstate,'queue') % enable STOP command
        for jfile=1:nbfield2
            filename=name_generator(basename,num_i1(jfile,ifile),num_j1(jfile,ifile),Series.FileExt,Series.NomType);
            filename_new=name_generator(basename_new,num_i1(jfile,ifile),num_j1(jfile,ifile),'.png',Series.NomType);
            A=imread(filename);
            C=levels(A);
            imwrite(C,filename_new)
        end
    end
end



function C=levels(A)
%whos A;
B=double(A(:,:,1));
windowsize=round(min(size(B,1),size(B,2))/20);
windowsize=floor(windowsize/2)*2+1;
ix=[1/2-windowsize/2:-1/2+windowsize/2];%
%del=np/3;
%fct=exp(-(ix/del).^2);
fct2=cos(ix/(windowsize-1)/2*pi/2);
%Mfiltre=(ones(5,5)/5^2);
%Mfiltre=fct2';
Mfiltre=fct2'*fct2;
Mfiltre=Mfiltre/(sum(sum(Mfiltre)));

C=filter2(Mfiltre,B);
C(:,1:windowsize)=C(:,windowsize)*ones(1,windowsize);
C(:,end-windowsize+1:end)=C(:,end-windowsize+1)*ones(1,windowsize);
C(1:windowsize,:)=ones(windowsize,1)*C(windowsize,:);
C(end-windowsize+1:end,:)=ones(windowsize,1)*C(end-windowsize,:);
C=tanh(B./(2*C));
[n,c]=hist(reshape(C,1,[]),100);
% figure;plot(c,n);

[m,i]=max(n);
c_max=c(i);
[dummy,index]=sort(abs(c-c(i)));
n=n(index);
c=c(index);
i_select = find(cumsum(n)<0.95*sum(n));
if isempty(i_select)
    i_select = 1:length(c);
end
c_select=c(i_select);
n_select=n(i_select);
cmin=min(c_select);
cmax=max(c_select);
C=(C-cmin)/(cmax-cmin)*256;
C=uint8(C);
