Project='/.fsnet/project/meige/2023/23ADDUP'
ProjectPNG=fullfile(Project,'PNG');
%% calibration images
%calib_file='B368_cal.im7';
% calib_file='B382_cal.im7';
% calib_file='B388_cal.im7';
% InputFile=fullfile(ProjectPNG,'0_REF_FILES',calib_file);
%  Input=readimx(InputFile);
%                A=Input.Frames{1}.Components{1}.Planes{1}';
% OutputFile_1=fullfile(ProjectPNG,'0_REF_FILES',regexprep(calib_file,'im7','png'));
%                imwrite(A,OutputFile_1,'png');
            
%% data series       

%Series='PIV_AddUp_2023_10_plan_dessus_buses_max_hauteur_plateau415mm';%mauvais
     % Exp='11_Cam_Date=231019_Time=161858_dt10000micros';
%Series='PIV_AddUp_2023_10_plan_dessus_buses_hauteur_plateau388mm';
      % Exp='14_Cam_Date=231020_Time=093149_dt2500micros'
Series='/PIV_AddUp_2023_10_plan_buses_hauteur_plateau382mm';
       %Exp='10_Cam_Date=231019_Time=151513_2500micros';
       %Exp='3_Cam_Date=231018_Time=143914_ens_avec_argon_dt2500micros';
       %Exp='2_Cam_Date=231018_Time=113731_tuyau_int_inj_avec_argon_dt2500micros'
      % Exp='5_Cam_Date=231018_Time=163728'
       Exp='7_Cam_Date=231019_Time=111953_dt2000micros'
      % Exp='1_Cam_Date=231018_Time=101459'
       
       
%Series='PIV_AddUp_2023_10_plan_dessous_buses_hauteur_plateau368mm';%meilleur
       %Exp='Cam_Date=231020_Time=112942';

       Davies=fullfile(Project,Series,Exp);
       if ~exist(Davies,'dir')
           'Davies does not exist'
       else
           PNG=regexprep(fullfile(ProjectPNG,Series),'=','');
           if ~exist(PNG,'dir')
               succes=mkdir(ProjectPNG,Series)
           end
           DataDir=fullfile(Project,Series,Exp);
           PNGDataDir=regexprep(fullfile(ProjectPNG,Series,Exp),'=','');%remove '='
           if ~exist(PNGDataDir,'dir')
               succes=mkdir(fullfile(ProjectPNG,Series),regexprep(Exp,'=',''));
           end
           for ilist=1870:2000%4000
               ilist
               InputFile=fullfile(DataDir,['B' num2str(ilist,'%05d') '.im7']);
               Input=readimx(InputFile);
               A=Input.Frames{1}.Components{1}.Planes{1}';
               B=Input.Frames{2}.Components{1}.Planes{1}';
               OutputFile_1=fullfile(PNGDataDir,['B' num2str(ilist,'%05d') 'a.png']);
               imwrite(A,OutputFile_1,'png');
               OutputFile_2=fullfile(PNGDataDir,['B' num2str(ilist,'%05d') 'b.png']);
               imwrite(B,OutputFile_2,'png');
           end
       end