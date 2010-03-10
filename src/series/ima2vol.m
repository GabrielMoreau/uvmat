% relabel_i_j: relabel an image series with two indices, according to the time matrix given by ImaDoc
%----------------------------------------------------------------------
function GUI_input=ima2vol(num_i1,num_i2,num_j1,num_j2,Series)
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
curdir=pwd;
cd(path);
mkdir([subdir_ima '_ij']);
cd(curdir);
basename_new=fullfile(path,[subdir_ima '_ij'],namebase);

% read imadoc
[XmlData,warntext]=imadoc2struct([basename '.xml']);
nbfield1=size(XmlData.Time,1)
nbfield2=size(XmlData.Time,2)

answer=msgbox_uvmat('INPUT_Y-N','apply image rescaling function levels.m')
test_level=isequal(answer,'Yes')

%copy the xml file
if exist([basename '.xml'],'file')
    copyfile([basename '.xml'],[basename_new '.xml']);% copy the .civ file
    t=xmltree([basename_new '.xml']);
    
    %update information on the first image name in the series
    uid_Heading=find(t,'ImaDoc/Heading');
    if isempty(uid_Heading)
        [t,uid_Heading]=add(t,1,'element','Heading');
    end   
    uid_ImageName=find(t,'ImaDoc/Heading/ImageName');
    ImageName=name_generator(basename_new,num_i1(1),num_j1(1),'.png','_i_j');
    [pth,ImageName]=fileparts(ImageName);
    ImageName=[ImageName '.png']
    if isempty(uid_ImageName)
       [t,uid_ImageName]=add(t,uid_Heading,'element','ImageName');
    end
    uid_value=children(t,uid_ImageName);
    if isempty(uid_value)
        t=add(t,uid_ImageName,'chardata',ImageName)%indicate  name of the first image, with ;png extension
    else
        t=set(t,uid_value(1),'value',ImageName)%indicate  name of the first image, with ;png extension
    end  

%     %add information about image transform
%     [t,new_uid]=add(t,1,'element','ImageTransform');
%     [t,NameFunction_uid]=add(t,new_uid,'element','NameFunction');
%     [t]=add(t,NameFunction_uid,'chardata','sub_background');      
%     [t,NbSlice_uid]=add(t,new_uid,'element','NbSlice');
%     [t]=add(t,new_uid,'chardata',num2str(nbslice_i));
%     [t,NbSlidingImages_uid]=add(t,new_uid,'element','NbSlidingImages');
%     [t]=add(t,NbSlidingImages_uid,'chardata',num2str(nbaver));
%     [t,LuminosityRank_uid]=add(t,new_uid,'element','RankBackground');
%     [t]=add(t,LuminosityRank_uid,'chardata',num2str(rank));% luminosity rank almong the nbaver sliding images 
    save(t,[basename_new '.xml'])
end

%main loop
 vol=[];
for ifile=1:nbfield1*nbfield2
    update_waitbar(hseries.waitbar,WaitbarPos,ifile/(nbfield1*nbfield2))
    filename=name_generator(basename,ifile-1,1,Series.FileExt,Series.NomType);
    num_j=mod(ifile-1,nbfield2)+1;
    num_i=floor((ifile-1)/nbfield2)+1;
    A=imread(filename);
    if test_level
         A=levels(A);
    end 
    vol=[vol;A];%concacene along y
    if num_j==nbfield2
         filename_new=name_generator(basename_new,num_i,1,'.vol','_i');
         imwrite(vol,filename_new,'png')
         vol=[];
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

C=filter2(ones(windowsize)/windowsize^2,B);
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
