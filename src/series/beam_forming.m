function ParamOut=beam_forming(Param)

%% set the input elements needed on the GUI series when the function is selected in the menu ActionName or InputTable refreshed
if isstruct(Param) && isequal(Param.Action.RUN,0)
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='on';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    %ParamOut.TransformPath=fullfile(fileparts(which('uvmat')),'transform_field');% path to transform functions (needed for compilation only)
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    index=msgbox_uvmat('INPUT_TXT','index of the series to process (1 to 5)');%choose the i index of the dat files
    ParamOut.OutputDirExt=['.p_formed_' index];%set the output dir extension
    hseries=findobj(allchild(0),'Tag','series');
    hhseries=guidata(hseries);
    set(hhseries.num_last_i,'String',index)
    set(hhseries.num_first_i,'String',index)
    ParamOut.OutputFileMode='NbInput';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
      %check the input files
    first_j=[];
    if isfield(Param.IndexRange,'first_j'); first_j=Param.IndexRange.first_j; end
    PairString='';
    if isfield(Param.IndexRange,'PairString'); PairString=Param.IndexRange.PairString; end
    [i1,i2,j1,j2] = get_file_index(Param.IndexRange.first_i,first_j,PairString);
    FirstFileName=fullfile_uvmat(Param.InputTable{1,1},Param.InputTable{1,2},Param.InputTable{1,3},...
        Param.InputTable{1,5},Param.InputTable{1,4},i1,i2,j1,j2);
    if ~exist(FirstFileName,'file')
        msgbox_uvmat('WARNING',['the first input file ' FirstFileName ' does not exist'])
    end
    return
end

ParamOut=[]; %default output
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% define the directory for result file (with path=RootPath{1})
OutputDir=[Param.OutputSubDir Param.OutputDirExt];% subdirectory for output files
if ~isfield(Param,'InputFields')
    Param.InputFields.FieldName='';
end

%% root input file type
RootPath=Param.InputTable{1,1};
RootFile=Param.InputTable{1,3};
SubDir=Param.InputTable{1,2};
NomType=Param.InputTable{1,4};
FileExt=Param.InputTable{1,5};
[filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param);
%%%%%%%%%%%%
% The cell array filecell is the list of input file names, while
% filecell{iview,fileindex}:
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series(iview,ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series(iview,fileindex) expresses the same indices as a 1D array in file indices
%%%%%%%%%%%%
% NbSlice=1;%default
% if isfield(Param.IndexRange,'NbSlice')&&~isempty(Param.IndexRange.NbSlice)
%     NbSlice=Param.IndexRange.NbSlice;
% end
NbView=numel(i1_series);%number of input file series (lines in InputTable)
NbField_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
NbField_i=size(i1_series{1},2); %nb of fields for the i index
NbField=NbField_j*NbField_i; %total number of fields

%% determine the file type on each line from the first input file 
ImageTypeOptions={'image','multimage','mmreader','video'};
NcTypeOptions={'netcdf','civx','civdata'};
for iview=1:NbView
    if ~exist(filecell{iview,1}','file')
        disp_uvmat('ERROR',['the first input file ' filecell{iview,1} ' does not exist'],checkrun)
        return
    end
    [FileInfo{iview},MovieObject{iview}]=get_file_type(filecell{iview,1});
    FileType{iview}=FileInfo{iview}.FileType;
    CheckImage{iview}=~isempty(find(strcmp(FileType{iview},ImageTypeOptions)));% =1 for images
    CheckNc{iview}=~isempty(find(strcmp(FileType{iview},NcTypeOptions)));% =1 for netcdf files
    if ~isempty(j1_series{iview})
        frame_index{iview}=j1_series{iview};
    else
        frame_index{iview}=i1_series{iview};
    end
end

% clear all
% close all
% read_data=1;
affichage=0;
% soustraction=0;

%%%%%% Prepare output 
load (fullfile(RootPath,SubDir,[RootFile '.mat']))
Data.ListGlobalAttribute={'CoordUnit'}; %%TODO: add also time, how to get it  ?????
Data.CoordUnit='pixel';
Data.ListVarName={'Coord_x','Coord_y','A'};
Data.VarDimName={'Coord_x','Coord_y',{'Coord_y','Coord_x'}};
%Data.Coord_x=5*(nbvoie_reception-0.5)/numel(nbvoie_reception); % totql length of e
Data.Coord_x=1:65;
%Data.Coord_z=(1:A)/133 ;% to check from input parameter ....
Data.Coord_y=1:332;
%%%%%%
%
% while test_fin_fichier>0
%     if read_data==1
%directory='manip_lgit';%%%%%%%%%%%%%%%%%
%name='test';%%%%%%%%%%%%%%%%%
%         number=2;
number=str2num(Param.OutputDirExt(11:end));%extract the subsequence index (from 1 to 5) 
numero_tir_fin_old=1%%%%%%% =0 ?????
pas_fichier=20;%  %20;% nbre of successive shots to read (to account for computer memory limit)
Nmoy=800;  %%%%% value 20  FOR TEST : to shift to VALUE 8000 set by the .mat file

test_fin_fichier=1;% test to stop input file reading
while test_fin_fichier>0
    numero_tir_debut=1;
    numero_tir_fin=numero_tir_fin_old+pas_fichier-1;
    
    %  eval(['load ' directory '\' name '.mat'])
    matrice_finale=zeros(A,length(nbvoie_reception),numero_tir_fin);%A=nbre of times (coord z)=2650, numero_tir_fin=time index
    time=(b/rsf+[0:A-1]/rsf); %b=250, rsf=10,
    freq1=0.5;freq2=1.5;
    [BB AA]=butter(4,[freq1 freq2]/rsf*2);

    for ii=1:length(nbvoie_reception)%=64
        %eval(['fid=fopen(''E:\ManipLGITLecoeur\' directory '\' name '_' num2str(number) '_' num2str(nbvoie_reception(ii)) '.dat'',''r'');']);
        filename=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,number,[],ii); % input file name
        fid=fopen(filename);
        toto=zeros(Nsequence*A*numero_tir_fin+31,1);% Nsequence=1
        toto=fread(fid,numero_tir_fin*A*Nsequence+31,'int16','ieee-le') ;% why shift by 31 ?????
        toto=double(bitxor(uint16(toto),uint16(2048)));
        toto(1:31)=[];toto(numero_tir_fin*A*Nsequence)=mean(toto);
        fclose(fid);
        
        tata=reshape(toto-2048,A,numero_tir_fin);
        matrice_finale(:,ii,:)=reshape(tata,[A,1,numero_tir_fin]);
        clear toto tata
    end
    
   % matrice_finale(:,:,numero_tir_debut:numero_tir_fin_old)=[];%%%%%%% first field removed (when numero_tir_fin_old=1) ?????
     matrice_finale(:,:,numero_tir_debut:numero_tir_fin_old-1)=[];%%%%%%% 
  %  numero_tir_fin=numero_tir_fin-1;  ?????
    matrice_finale=reshape(filtfilt(BB,AA,matrice_finale(:,:)),size(matrice_finale));% low pass filtered input signal,along first (time) index? 
    
    % if soustraction==1
    %     eval(['load moyenne_' name '_' num2str(number) '.mat matrice_finale_moy'])
    %     for kk=1:size(matrice_finale,3)
    %         matrice_finale(:,:,kk)=matrice_finale(:,:,kk)-matrice_finale_moy;
    %     end
    % end
    %eval(['save matrice_finale_' num2str(numero_tir_fin_old) '_' num2str(numero_tir_fin) '.mat'])
    
    %%%%%%%%%%%%%%Imagerie
    fe=rsf*1e6;% sampling frequency for receptor (in Hz)
    cc=1475;%speed of sound
    hanning_window=25;
    hanning_vect=hanning(2*hanning_window+1);
    interval=[1:size(matrice_finale,1)];
    freq=0:fe/length(interval):fe*(1-1/length(interval));
    
    pas_reseau_z=0.75e-3;%0.75e-3
    pas_reseau_r=0;
    voie_mean=length(nbvoie_reception)/2;%32;
    reseau_z=[0:length(nbvoie_reception)-1]*pas_reseau_z;
    reseau_z=reseau_z-reseau_z(voie_mean);
    reseau_r=[0:length(nbvoie_reception)-1]*pas_reseau_r;
    reseau_r=reseau_r-reseau_r(voie_mean);
    
    debut_r=(time(1)+20)*1e-6*cc/2;
    fin_r=(time(end)-20)*1e-6*cc/2;
    
    image_r=debut_r:.5e-3:fin_r;
    image_z=-24e-3:.75e-3:24e-3;
    
    image_fin=zeros(length(image_r),length(image_z),size(matrice_finale,3));%size=(332,65,pas_fichier)
    %image_fin_bis=zeros(length(image_r),length(image_z),size(matrice_finale,3));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for kk=1:size(matrice_finale,3)
        disp(kk)
        signal=squeeze(matrice_finale(interval,:,kk));
        tata_fft=fft(signal,[],1);%FFT of the time signal size=(2650,64)     
        if kk==1           
            matrice_freq_mean=mean(abs(fft(signal,[],1)),2);
            X=[freq1*1e6 freq2*1e6];
            [I J]=find(freq>=X(1) & freq<=X(2));
            int_freq=find(matrice_freq_mean(round(1:length(freq)/2))>max(matrice_freq_mean(round(1:length(freq)/2)))/2);
            bandwidth=freq(int_freq(end)-int_freq(1));
            %clear matrice_freq_mean
        end
        
        for ii=1:length(image_r)
            for jj=1:length(image_z)
                
                delay=zeros(length(nbvoie_reception),1);
                delay=1/cc*sqrt((reseau_z-image_z(jj)).^2+(reseau_r-image_r(ii)).^2);
                
                [ind centre_z]=min(abs((reseau_z-image_z(jj))));
                interval_utile=round(((delay(centre_z)+1/cc*abs(image_r(ii)))*fe)-(b+interval(1)-1)+round(length(motifbase)/2)+[-fe/bandwidth/2:fe/bandwidth/2]);
                delay=delay-delay(centre_z);
                
                hanning_vecteur=zeros(1,length(nbvoie_reception));
                if centre_z>hanning_window & centre_z<(length(nbvoie_reception)-hanning_window)
                    hanning_vecteur(centre_z+[-hanning_window:hanning_window])=hanning_vect;
                elseif centre_z<=hanning_window
                    test=hanning_vect((centre_z+[-hanning_window:hanning_window])>=1);
                    hanning_vecteur(1:length(test))=test;
                elseif centre_z>=(length(nbvoie_reception)-hanning_window)
                    test=hanning_vect((centre_z+[-hanning_window:hanning_window])<=length(nbvoie_reception));
                    hanning_vecteur(length(nbvoie_reception)+[-length(test)+1:0])=test;
                end
                hanning_vecteur=hanning_vecteur/norm(hanning_vecteur);
                clear test;
                
                amplitude_weight=ones(size(signal,1),1)*hanning_vecteur;
                signal_new_rec=zeros(size(signal,1),length(nbvoie_reception));
                
                tata=zeros(size(signal,1),size(signal,2));
                tata(J,:)=tata_fft(J,:).*exp(1i*2*pi*(freq(J)'*delay));
                signal_new_rec=2*real(ifft(tata,[],1)).*amplitude_weight;
                index_interval_utile=find(interval_utile>0 & interval_utile<size(signal,1));
                toto=zeros(length(index_interval_utile),1);
                toto=mean(signal_new_rec(interval_utile(index_interval_utile),:),2);
                image_fin(ii,jj,kk)=sqrt(mean(toto.^2));
                clear signal_bis interval_utile index_interval_utile hanning_vecteur
            end
        end
    end
    
    clear signal_new_em signal_new_rec m delay toto toto_bis tata tata_fft
    
    if affichage==1
        for kk=1:size(image_fin,3)
            
            figure(1)
            imagesc(image_r*1e2,image_z*1e2,image_fin(:,:,kk)'/max(max(image_fin(:,:,kk)))');
            title(['avec beamforming - energie max = ' num2str(max(max(image_fin(:,:,kk))))])
            colorbar;
            xlabel('r (cm)');ylabel('z (cm)');
            drawnow
            pause(.2);
        end
    end
    
    clear matrice_finale
    
    %%%%%%% TO ADAPT
    for iii=1:size(image_fin,3)
        Data.A=image_fin(:,:,iii);% time lapse decreasesas z coordinate increases.
        FileIndex=numero_tir_fin - pas_fichier+iii;%%%%%%TO CHECK!!!!!
        %%%%%%%%%%
        %eval(['save analyse_' name '_' num2str(number) '_' num2str(numero_tir_fin_old) '_' num2str(numero_tir_fin) '.mat'])
        OutputFile=fullfile_uvmat(RootPath,OutputDir,'signal','.nc','_00001',FileIndex);
        error=struct2nc(OutputFile,Data);%save result file
        if isempty(error)
            disp(['output file ' OutputFile ' written'])
        else
            disp(error)
        end
    end
    numero_tir_fin_old=numero_tir_fin+1% first index for next bloc reading
     if (numero_tir_fin_old+pas_fichier-1)>Nmoy 
    test_fin_fichier=-1;
    end
end


