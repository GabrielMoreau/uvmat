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
function GUI_input=ima_levels(Param)
%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('Param','var')
    GUI_input={'OutputDirExt';'.lev'};
    return %exit the function 
end

%% input parameters
% read the xml file for batch case
if ischar(Param) && ~isempty(find(regexp('Param','.xml$')))
    Param=xml2struct(Param);
    checkrun=0;
else %  RUN case: parameters introduced as the input structure Param
    hseries=guidata(Param.hseries);%handles of the GUI series
    WaitbarPos=get(hseries.waitbar_frame,'Position');
    checkrun=1;
end
%filebase=fullfile(Param.InputTable{1,1},Param.InputTable{1,3});
RootPath=Param.InputTable{1,1};
Subdir=Param.InputTable{1,2};
RootFile=Param.InputTable{1,3};
NomType=Param.InputTable{1,4};
FileExt=Param.InputTable{1,5};
[filecell,i1_series,i2_series,j1_series]=get_file_series(Param);% list of input files and indices
if size(filecell,1)>1
    msgbox_uvmat('WARNING','This function uses only the first input image series')
    return
end

%% determine input image type
[FileType,FileInfo,MovieObject]=get_file_type(filecell{1,1});
ListTypes={'image','multimage','mmreader','video'};

if isempty(strcmp(FileType,ListTypes))% if the detected FileType is not in the list for images
    msgbox_uvmat('ERROR',['invalid file extension ' FileExt ': this function only accepts image or movie input'])
    return
end

%% create dir of the new images
SubdirResult=[Param.InputTable{1,2} '.lev'];% add the suffix '.lev' to the name of the image folder
try
    mkdir(fullfile(Param.InputTable{1,1},SubdirResult));
catch ME
    msgbox_uvmat('ERROR',['error in creating result directory: ' ME.message]);%display error msg for directory creation if fails
    return
end
[xx,msg2] = fileattrib(fullfile(Param.InputTable{1,1},SubdirResult),'+w','g'); %yield writing access (+w) to user group (g)
if ~strcmp(msg2,'')
    msgbox_uvmat('ERROR',['pb of permission for ' fullfile(Param.InputTable{1,1},SubdirResult) ': ' msg2])%error message for directory creation
    return
end
msgbox_uvmat('CONFIRMATION','apply image rescaling function levels.m ');

%copy the xml file
% if exist([basename '.xml'],'file')
%     copyfile([basename '.xml'],[basename_new '.xml']);% copy the .civ file
% end

%% main loop
nbfield=size(i1_series{1},2);
nbfield2=size(i1_series{1},1);
for ifile=1:nbfield
    if checkrun
%         update_waitbar(hseries.waitbar,WaitbarPos,ifile/nbfield)
        update_waitbar(hseries.waitbar_frame,WaitbarPos,ifile/nbfield)
        stopstate=get(hseries.RUN,'BusyAction');
    else
        stopstate='queue';
    end
    if isequal(stopstate,'queue') % enable STOP command
        for jfile=1:nbfield2
            %filename=name_generator(basename,num_i1(jfile,ifile),num_j1(jfile,ifile),Series.FileExt,Series.NomType);
            %filename_new=name_generator(basename_new,num_i1(jfile,ifile),num_j1(jfile,ifile),'.png',Series.NomType);
            filename=fullfile_uvmat(RootPath,Subdir,RootFile,FileExt,NomType,i1_series{1}(jfile,ifile),[],j1_series{1}(jfile,ifile));
            switch FileType
                case {'video','mmreader'}
                    A=read(MovieObject,i1_series{1}(jfile,ifile));
                    if strcmp(NomType,'*')
                        A=read(MovieObject,i1_series{1}(jfile,ifile));
                        NomType_out='_1';
                    else
                        A=imread(filename,j1_series{1}(jfile,ifile));
                        NomType_out='_1_1';
                    end
                case {'vol','image'}
                    A=imread(filename);
                    NomType_out='_1';
                case 'multimage'
                    if strcmp(NomType,'*')
                        A=imread(filename,i1_series{1}(jfile,ifile));
                        NomType_out='_1';
                    else
                        A=imread(filename,j1_series{1}(jfile,ifile));
                        NomType_out='_1_1';
                    end
            end
            C=levels(A);
            filename_new=fullfile_uvmat(RootPath,SubdirResult,RootFile,'.png',NomType_out,i1_series{1}(jfile,ifile),[],j1_series{1}(jfile,ifile));
            imwrite(C,filename_new)
            display([filename_new ' written'])
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
