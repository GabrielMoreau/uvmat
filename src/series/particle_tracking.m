% function ParamOut=particle_tracking(Param)
%
% Method: 
   
% Organization of image indices:
    
%INPUT:
% num_i1: matrix of image indices i
% num_j1: matrix of image indices j, must be the same size as num_i1
% num_i2 and num_j2: not used for a function acting on images
% Series: matlab structure containing parameters, as defined by the interface UVMAT/series
%       Series.RootPath{1}: path to the image series
%       Series.RootFile{1}: root file name
%       Series.FileExt{1}: image file extension 
%       Series.NomType{1}: nomenclature type for file in
%
% Method: 
%       Series.NbSlice: %number of slices defined on the interface
% global A rangx0 rangy0 minA maxA; % make current image A accessible in workspace
% global hfig1 hfig2 scalar
% global Abackg nbpart lum diam
%%%%%%%%%%%%%%�
%
%%%%%%%%%%% GENERAL TO ALL SERIES ACTION FCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%OUTPUT
% ParamOut: sets options in the GUI series.fig needed for the function
%
%INPUT:
% In run mode, the input parameters are given as a Matlab structure Param copied from the GUI series.
% In batch mode, Param is the name of the corresponding xml file containing the same information
% when Param.Action.RUN=0 (as activated when the current Action is selected
% in series), the function ouput paramOut set the activation of the needed GUI elements
%
% Param contains the elements:(use the menu bar command 'export/GUI config' in series to 
% see the current structure Param)
%    .InputTable: cell of input file names, (several lines for multiple input)
%                      each line decomposed as {RootPath,SubDir,Rootfile,NomType,Extension}
%    .OutputSubDir: name of the subdirectory for data outputs
%    .OutputDirExt: directory extension for data outputs
%    .Action: .ActionName: name of the current activated function
%             .ActionPath:   path of the current activated function
%             .ActionExt: fct extension ('.m', Matlab fct, '.sh', compiled   Matlab fct
%             .RUN =0 for GUI input, =1 for function activation
%             .RunMode='local','background', 'cluster': type of function  use
%             
%    .IndexRange: set the file or frame indices on which the action must be performed
%    .FieldTransform: .TransformName: name of the selected transform function
%                     .TransformPath:   path  of the selected transform function
%    .InputFields: sub structure describing the input fields withfields
%              .FieldName: name(s) of the field
%              .VelType: velocity type
%              .FieldName_1: name of the second field in case of two input series
%              .VelType_1: velocity type of the second field in case of two input series
%              .Coord_y: name of y coordinate variable
%              .Coord_x: name of x coordinate variable
%    .ProjObject: %sub structure describing a projection object (read from ancillary GUI set_object)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function ParamOut=particle_tracking(Param)

%% set the input elements needed on the GUI series when the action is selected in the menu ActionName
if isstruct(Param) && isequal(Param.Action.RUN,0)
    % general settings of the GUI:
    ParamOut.AllowInputSort='off';% allow alphabetic sorting of the list of input file SubDir (options 'off'/'on', 'off' by default)
    ParamOut.WholeIndexRange='off';% prescribes the file index ranges from min to max (options 'off'/'on', 'off' by default)
    ParamOut.NbSlice='off'; %nbre of slices ('off' by default)
    ParamOut.VelType='off';% menu for selecting the velocity type (options 'off'/'one'/'two',  'off' by default)
    ParamOut.FieldName='off';% menu for selecting the field (s) in the input file(options 'off'/'one'/'two', 'off' by default)
    ParamOut.FieldTransform = 'off';%can use a transform function
    ParamOut.ProjObject='off';%can use projection object(option 'off'/'on',
    ParamOut.Mask='off';%can use mask option   (option 'off'/'on', 'off' by default)
    ParamOut.OutputDirExt='.track';%set the output dir extension
    ParamOut.OutputFileMode='NbSlice';% '=NbInput': 1 output file per input file index, '=NbInput_i': 1 file per input file index i, '=NbSlice': 1 file per slice
    filecell=get_file_series(Param);%check existence of the first input file
    if ~exist(filecell{1,1},'file')
        msgbox_uvmat('WARNING','the first input file does not exist') 
    end
    % parameters specific to the function 'particle_tracking'
    Par.Nblock=10;%size of image subblocks for background determination, =[]: no sublock
    Par.ThreshLum=70;% luminosity threshold for particle detection, < 0 for black particles, >0 for white particles
  ParamOut.ActionInput=Par;
    return
end

%%%%%%%%%%%%  STANDARD RUN PART  %%%%%%%%%%%%
ParamOut=[];
%% read input parameters from an xml file if input is a file name (batch mode)
checkrun=1;
if ischar(Param)
    Param=xml2struct(Param);% read Param as input file (batch case)
    checkrun=0;
end
hseries=findobj(allchild(0),'Tag','series');
RUNHandle=findobj(hseries,'Tag','RUN');%handle of RUN button in GUI series
WaitbarHandle=findobj(hseries,'Tag','Waitbar');%handle of waitbar in GUI series

%% define the directory for result file
OutputDir=[Param.OutputSubDir Param.OutputDirExt];

%% root input file(s) name, type and index series
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
nbview=numel(i1_series);%number of input file series (lines in InputTable)
nbfield_j=size(i1_series{1},1); %nb of fields for the j index (bursts or volume slices)
nbfield_i=size(i1_series{1},2); %nb of fields for the i index
nbfield=nbfield_j*nbfield_i; %total number of fields

%% frame index for movie or multimage file input  
if ~isempty(j1_series{1})
    frame_index=j1_series{1};
else
    frame_index=i1_series{1};
end

%% check the input file type  
[FileInfo,VideoObject]=get_file_info(filecell{1,1});
FileType=FileInfo.FileType;
ImageTypeOptions={'image','multimage','mmreader','video','cine_phantom'};
if isempty(find(strcmp(FileType,ImageTypeOptions)))
    disp('input file not images')
    return
end

%% calibration data and timing: read the ImaDoc files
[XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series);

%%%%%%%%%%%%   SPECIFIC PART (to edit) %%%%%%%%%%%%
%filter for particle center of mass(luminosity)
Nblock=Param.ActionInput.Nblock;
ThreshLum=Param.ActionInput.ThreshLum;% luminosity threshold for particle detection, < 0 for black particles, >0 for white particles
%AbsThreshold=30; %threshold below which a pixel is considered belonging to a float
%
hh=ones(5,5);
hh(1,1)=0;
hh(1,5)=0;% sum luminosity on the 5x5 domain without corners
hh(5,1)=0;
hh(5,5)=0;
hdx=[-2:1:2];
hdy=[-2:1:2];
[hdX,hdY]=meshgrid(hdx,hdy);
hdX(1,1)=0;
hdX(1,5)=0;% sum luminosity on the 5x5 domain -corners
hdX(5,1)=0;
hdX(5,5)=0;
hdY(1,1)=0;
hdY(1,5)=0;% sum luminosity on the 5x5 domain -corners
hdY(5,1)=0;
hdY(5,5)=0;

%%  mask to reduce the  working area (optional)
CheckMask=0;
if isfield(Param,'CheckMask') && isequal(Param.CheckMask,1)
    [maskname,TestMask]=name_generator([filebase '_1mask'],1,1,'.png','_i');
	MaskIma=imread(maskname);
	Mask=MaskIma>=200;%=1 for good points, 0 for bad
    CheckMask=1;
end

%%%%%% MAIN LOOP ON FRAMES %%%%%%
for ifile=1:nbfield
    if checkrun
        update_waitbar(WaitbarHandle,ifile/nbfield)
        if ~isempty(RUNHandle) &&ishandle(RUNHandle) && ~strcmp(get(RUNHandle,'BusyAction'),'queue')
            disp('program stopped by user')
            return
        end
    end
    j1=1;
    if ~isempty(j1_series)&&~isequal(j1_series,{[]})
        j1=j1_series{1}(ifile);
    end
    filename=fullfile_uvmat(RootPath,SubDir,RootFile,FileExt,NomType,i1_series{1}(ifile),[],j1);
    A=read_image(filename,FileType,VideoObject,frame_index(ifile));% read the current frame
    if ndims(A)==3;%color images
        A=sum(double(A),3);% take the sum of color components
    end
    if ThreshLum<0
        A=max(max(A))-A;%take the negative
    end
    if CheckMask
        A=A.*Mask;
    end
    if isempty(Nblock)
        A=A-min(min(A));%substract absolute mean
    else
        Aflagmin=sparse(imregionalmin(A));%Amin=1 for local image minima
        Amin=A.*Aflagmin;%values of A at local minima
        % local background: find all the local minima in image subblocks
        sumblock= inline('sum(sum(x(:)))');
        Backgi=blkproc(Amin,[Nblock Nblock],sumblock);% take the sum in  blocks
        Bmin=blkproc(Aflagmin,[Nblock Nblock],sumblock);% find the number of minima in blocks
        Backgi=Backgi./Bmin; % find the average of minima in blocks
        % Backg=Backg+Backgi;
        Backg=Backgi;
        A=A-imresize(Backg/nburst(1),size(A),'bilinear');% interpolate to the initial size image and substract
    end
    Aflagmax=sparse(imregionalmax(A));%find local maxima
    Plum=imfilter(A,hh);% sum A on 5x% domains
    Plum=Aflagmax.*Plum;% Plum gives the particle luminosity at each particle location, 0 elsewhere
    %make statistics on particles,restricted to a subdomain Sub
    [Js,Is,lum]=find(Plum);%particle luminosity
    Plum=(Plum>ThreshLum).*Plum;% introduce a threshold for particle luminosity
    Aflagmax=Aflagmax.*(Plum>ThreshLum);
    [Js,Is,lum]=find(Plum);%particle luminosity
    nbtotal=size(Is)
    nbtotal=nbtotal(1);
    %particle size
    Parea=Aflagmax.*(Plum./A); %particle luminosity/max luminosity=area
    Pdiam=sqrt(Parea);
    [Js,Is,diam]=find(Pdiam);%particle location
    
    %%%%%%%%%%%%%%%%%%%%%
    
    %nbre of particles per block
%     nbpart=blkproc(Aflagmax,[Nblock Nblock],sumblock);%
%     npb=size(nbpart);
%     rangxb=[0.5 (npb(2)-0.5)]*Nblock; % pixel x coordinates for image display
%     rangyb=[(npb(1)-0.5) 0.5]*Nblock; % pixel y coordinates for image display
%     image(rangxb,rangyb,nbpart);
    
    % get the particle centre of mass
    dx=imfilter(A,hdX);
    dy=imfilter(A,-hdY);
    dx=Aflagmax.*(dx./Plum);
    dy=Aflagmax.*(dy./Plum);
    dx=dx/pxcm;
    dy=dy/pycm;
    I=([1:npxy(2)]-0.5)/pxcm; %x pos
    J=([npxy(1):-1:1]-0.5)/pycm; %y pos
    [Ipos,Jpos]=meshgrid(I,J);
    Ipos=reshape(Ipos,1,npxy(2)*npxy(1));
    Jpos=reshape(Jpos,1,npxy(2)*npxy(1));
    dx=reshape(dx,1,npxy(2)*npxy(1));
    dy=reshape(dy,1,npxy(2)*npxy(1));
    Aflag=reshape(Aflagmax,1,npxy(2)*npxy(1));
    ind=find(Aflag);% select particle positions
    XPart{ifile}=Ipos(ind)+dx(ind);
    YPart{ifile}=Jpos(ind)+dy(ind);      
end
hold off

size(XPart{1})

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Trajectoires
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ifile=1:nbfield
    
    [XPart{ifile},YPart{ifile}]=phys_XYZ(Calib,XPart{ifile},YPart{ifile});

end

if nbfield>2
    figpart=figure
    hold on
    plot(XPart{1}(:),YPart{1}(:),'r+')
    plot(XPart{2}(:),YPart{2}(:),'b+')
    plot(XPart{3}(:),YPart{3}(:),'y+')
    legend('particules image 1','particules image 2','particules image 3');
    xlabel('x (cm)');
    ylabel('y (cm)');
    title('Position des particules')
else
   figpart=figure
    hold on
    plot(XPart{1}(:),YPart{1}(:),'r+')
    plot(XPart{2}(:),YPart{2}(:),'b+')
    legend('particules image 1','particules image 2');
    xlabel('x (cm)');
    ylabel('y (cm)');
    title('Position des particules')
end    

%     prompt={'Ymin (cm)','Ymax( cm)','Xmin (cm)','Xmax (cm)'};
%     Rep=inputdlg(prompt,'Experiment');
%     Ymin=str2double(Rep(1));
%     Ymax=str2double(Rep(2));
%     Xmin=str2double(Rep(3));
%     Xmax=str2double(Rep(4));
    
    Ymin=6;
    Ymax=14;
    Xmin=15;
    Xmax=35;
    
    plot(Xmin,Ymin,'g+')
    plot(Xmin,Ymax,'g+')
    plot(Xmax,Ymin,'g+')
    plot(Xmax,Ymax,'g+')

    
 for ima=2:nbfield   
    t{1}=0*ones(size(XPart{1},2),1);
    burst(1)=0;
    burst(2)=0.018;
    burst(3)=0.036;
%     nburst=strcat('burst',num2str(ima-1),'-',num2str(ima),' (s)');
%     prompt={'burst (s)'};
%     Rep=inputdlg(prompt,nburst);
%     burst(ima)=str2double(Rep(1));
    t{ima}=(burst(ima)+burst(ima-1))*ones(size(XPart{ima},2),1);
 end


 
 for ima=1:nbfield

    IndY{ima}=find(YPart{ima}>Ymin & YPart{ima}<Ymax & XPart{ima}>Xmin & XPart{ima}<Xmax);
    XPart{ima}=XPart{ima}(IndY{ima});
    YPart{ima}=YPart{ima}(IndY{ima});
    
        
end



%%%%%%%%%%%%%%%%%%%%%%%
% Calcul de v1
%%%%%%%%%%%%%%%%%%%%%%%

for i=1:size(XPart{1},2)
    MatPos{1}(i,1)=XPart{1}(i);
    MatPos{1}(i,2)=YPart{1}(i);
    MatPos{1}(i,3)=t{1}(i);
    %MatPos{1}(i,4)=i;
end

for j=1:size(XPart{2},2)-1
    MatPos{1}(j+size(XPart{1},2),1)=XPart{2}(j);
    MatPos{1}(j+size(XPart{1},2),2)=YPart{2}(j);
    MatPos{1}(j+size(XPart{1},2),3)=t{2}(j);
    %MatPos{1}(j,4)=j+size(XPart{1},2);
end
  
% Dmax=inputdlg('Entrer la distance maximum (0.25 cm)','dmax (cm)',1)
% dmax=str2num(Dmax{1});
dmax=0.23;

result{1}=track(MatPos{1},dmax);

izero=1;
for itest=1:1:size(result{1},1)-1
    if  result{1}(itest+1,4)==result{1}(itest,4)
        vitu{1}(izero,1)=(result{1}(itest+1,1)-result{1}(itest,1))/burst(2);
        vitu{1}(izero,2)=result{1}(itest,4);
        vitv{1}(izero,1)=(result{1}(itest+1,2)-result{1}(itest,2))/burst(2);
        vitv{1}(izero,2)=result{1}(itest,4);
        MatPos{2}(izero,1)=result{1}(itest,1);
        MatPos{2}(izero,2)=result{1}(itest,2);
        izero=izero+1;
    end
end


vitfu{1}=vitu{1};
vitfv{1}=vitv{1};


%%%%%%%%%%%%%%%%%%%%%%%
% Calcul de vi
%%%%%%%%%%%%%%%%%%%%%%%


if nbfield>2
    for ima=2:nbfield-1
       
       for i=1:size(MatPos{ima},1)
        MatPos{ima+1}(i,1)=MatPos{ima}(i,1)+(burst(ima+1)*vitfu{ima-1}(i));
        MatPos{ima+1}(i,2)=MatPos{ima}(i,2)+(burst(ima+1)*vitfv{ima-1}(i));
        MatPos{ima+1}(i,3)=t{ima}(i);
      end

      for j=1:size(XPart{ima+1},2)-1
          MatPos{ima+1}(j+size(MatPos{ima},1),1)=XPart{ima+1}(j);
          MatPos{ima+1}(j+size(MatPos{ima},1),2)=YPart{ima+1}(j);
          MatPos{ima+1}(j+size(MatPos{ima},1),3)=t{ima+1}(j);
      end
        
      
    result{ima}=track(MatPos{ima+1},0.15);
        
        izero=1;
        for itest=1:1:size(result{ima},1)-1
            if  result{ima}(itest+1,4)==result{ima}(itest,4)
                vitu{ima}(izero,1)=(result{ima}(itest+1,1)-result{ima}(itest,1))/burst(ima+1);
                vitu{ima}(izero,2)=result{ima}(itest,4);
                vitv{ima}(izero,1)=(result{ima}(itest+1,2)-result{ima}(itest,2))/burst(ima+1);
                vitv{ima}(izero,2)=result{ima}(itest,4);
                MatPos{ima+2}(izero,1)=result{ima}(itest,1);
                MatPos{ima+2}(izero,2)=result{ima}(itest,2);
                izero=izero+1;
            end   
        end

            i=vitu{ima}(1,2):1:vitu{ima}(end,2)
            
              vitfu{ima}(:,1)=vitfu{ima-1}(i,1)+vitu{ima}(:,1);
              vitfv{ima}(:,1)=vitfv{ima-1}(i,1)+vitv{ima}(:,1);
              vitfu{ima}(:,2)=vitu{ima}(:,2);
              vitfv{ima}(:,2)=vitv{ima}(:,2);

            vitfu{ima-1}=vitfu{ima-1}(i,1);
            vitfu{ima-1}(:,2)=i;
            vitfv{ima-1}=vitfv{ima-1}(i,1);
            vitfv{ima-1}(:,2)=i;
            i=1:1:size(vitfu{ima-1},1)
            xpos=MatPos{2}(i,1)
            ypos=MatPos{2}(i,2)
      end
    end



    figure
    hold on
    plot(MatPos{1}(:,1),MatPos{1}(:,2),'r+')
    plot(MatPos{2}(:,1),MatPos{2}(:,2),'b+')
    plot(MatPos{4}(:,1),MatPos{4}(:,2),'y+')
    quiver(xpos(:),ypos(:),vitfu{1}(:,1),vitfv{1}(:,1),'g')
    quiver(MatPos{4}(:,1),MatPos{4}(:,2),vitfu{2}(:,1),vitfv{2}(:,1),'k')
    legend('particules image 1','particules image 2', 'particules image 3','vitesse 1-2 (cm/s)','vitesse 2-3 (cm/s)');
    xlabel('x (cm)');
    ylabel('y (cm)');
    title('Position et vitesse (cm/s) des particules')
    

    for i=1:size(vitfu{end},1)
     vitfuadd(i)=0;
     vitfvadd(i)=0;
    end

   
   
         for i=1:1:size(vitfu{end}(:,1))
            
                for j=1:nbfield-1
                    vitfuadd(i)= vitfuadd(i)+vitfu{j}(i,1);
                    vitfvadd(i)= vitfvadd(i)+vitfv{j}(i,1);
                    xpos1(i)=MatPos{1}(i,1);
                    ypos1(i)=MatPos{1}(i,2);
                    xpos2(i)=MatPos{2}(i,1);
                    ypos2(i)=MatPos{2}(i,2);
                    
                end
            end
            sizexpos1=size(xpos1)

    vitfumoy=vitfuadd./(nbfield-1)
    vitfvmoy=vitfvadd./(nbfield-1)

    testresult1=result{1}
    testresult2=result{2}
    
if nbfield>2    
    figure
    hold on
    plot(MatPos{1}(:,1),MatPos{1}(:,2),'r+')
    plot(MatPos{2}(:,1),MatPos{2}(:,2),'b+')
    quiver(xpos2(:),ypos2(:),vitfumoy(:),vitfvmoy(:),'g')
    legend('particules image 1','particules image 2', 'vitesse moyenne (cm/s)');
    xlabel('x (cm)');
    ylabel('y (cm)');
    title('Position et vitesse (cm/s) des particules')
    
else

    figure 
    hold on
    plot(MatPos{1}(:,1),MatPos{1}(:,2),'r+')
    plot(MatPos{2}(:,1),MatPos{2}(:,2),'b+')
    quiver(MatPos{2}(:,1),MatPos{2}(:,2),vitfu{1}(:),vitfv{1}(:),'g')
    legend('particules image 1','particules image 2','vitesse 1-2 (cm/s)');
    xlabel('x (cm)');
    ylabel('y (cm)');
    title('Position et vitesse (cm/s) des particules')
    
    vitfumoy=vitfu{1};
    vitfvmoy=vitfv{1};

end

VitData.NbDim=2;
VitData.NbCoord=2;
VitData.CoordType='phys';
VitData.dt=0.0185;
VitData.CoordUnit='cm';
VitData.Z=0;
VitData.ListDimName={'nb_vectors'};
VitData.DimValue=size(vitfumoy,2);
VitData.ListVarName={'X'  'Y'  'U'  'V'  'F'};
VitData.VarDimIndex={[1]  [1]  [1]  [1]  [1]};
VitData.ListVarAttribute={'Role'};
VitData.Role={'coord_x'  'coord_y'  'vector_x'  'vector_y'  'warnflag'};

if nbfield>2
    VitData.X=size(MatPos{4},1);
    VitData.Y=size(MatPos{4},2);
else
    VitData.X=size(MatPos{2},1);
    VitData.Y=size(MatPos{2},2);
end

VitData.U=size(vitfumoy,2);
VitData.V=size(vitfvmoy,2);
VitData.Style='plane';
VitData.Time=[198.5203 198.5203];
VitData.Action=Series.Action;

if nbfield>2
    VitData.X=MatPos{4}(:,1)';
    VitData.Y=MatPos{4}(:,2)';
else
    VitData.X=MatPos{2}(:,1)';
    VitData.Y=MatPos{2}(:,2)';
end

VitData.U=vitfumoy(:)';
VitData.V=vitfvmoy(:)';

if length(VitData.ListVarName) >= 4 & isequal(VitData.ListVarName(1:4), {'X'  'Y'  'U'  'V'})
       VitData.ListAttribute={'nb_coord','nb_dim','dt','pixcmx','pixcmy','hart','civ','fix'};
       VitData.nb_coord=2;
       VitData.nb_dim=2;
       VitData.dt=0.018;
       VitData.absolut_time_T0=0;
       VitData.pixcmx=1; %pix per cm (1 by default)
       VitData.pixcmy=1; %pix per cm (1 by default)
       VitData.hart=0;
           if isequal(VitData.CoordType,'px')
             VitData.civ=1;
           else
             VitData.civ=0;
           end
        VitData.fix=0;
        VitData.ListVarName(1:4)={'vec_X'  'vec_Y'  'vec_U'  'vec_V'};
        VitData.vec_X=VitData.X;
        VitData.vec_Y=VitData.Y;
        VitData.vec_U=VitData.U;
        VitData.vec_V=VitData.V;
end
currentdir=pwd;%store the current working directory
[Path_ima,Name]=fileparts(filebase);%Path of the image files (.civ)
cd(Path_ima);%move to the directory of the images: needed to create the result dir by 'mkdir'
dircur=pwd; %current working directory
[m1,m2,m3]=mkdir('TRACK_test')
cd(currentdir)
[filename_nc,idetect]=name_generator(filebase,num_i1(1),num_j1(1),'.nc','_i_j1-j2',1,num_i1(1),num_j1(2),'TRACK_test')
error=struct2nc(filename_nc,VitData); %save result file
if isequal(error,0)
    [filename_nc ' written']
else
    warndlg_uvmat(error,'ERROR')
end

