function [A,FileInfo,timestamps,errormsg]=read_rdvision(filename,frame_idx)
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

errormsg='';
if nargin<2% no frame indices specified
   frame_idx=-1;% all the images in the series are read
end
A=[];
timestamps=[];
[PathDir,RootFile,Ext]=fileparts(filename);
RootPath=fileparts(PathDir);
switch Ext
    case '.seq'
        filename_seq=filename;
        filename_sqb=fullfile(PathDir,[RootFile '.sqb']);
    case '.sqb'
        filename_seq=fullfile(PathDir,[RootFile '.seq']);
        filename_sqb=filename;
    otherwise
        errormsg='input file extension must be .seq or .sqb';
end
if ~exist(filename_seq,'file')
    errormsg=[filename_seq ' does not exist'];
    return
end
s=ini2struct(filename_seq);
FileInfo=s.sequenceSettings;
if isfield(s.sequenceSettings,'numberoffiles')
    FileInfo.NumberOfFrames=str2double(s.sequenceSettings.numberoffiles);
    FileInfo.FrameRate=str2double(s.sequenceSettings.framepersecond);
    FileInfo.ColorType='grayscale';
else
    FileInfo.FileType='';
    return
end
FileInfo.FileType='rdvision'; % file used to store info from image acquisition systems of rdvision
nbfield=numel(fieldnames(FileInfo));
FileInfo=orderfields(FileInfo,[nbfield nbfield-1 nbfield-2 (1:nbfield-3)]); %reorder the fields of fileInfo for clarity

% read the images the input frame_idxis not empty
if ~isempty(frame_idx)
    w=str2double(FileInfo.width);
    h=str2double(FileInfo.height);
    bpp=str2double(FileInfo.bytesperpixel);
    bin_file=FileInfo.binfile;
    nb_frames=str2double(FileInfo.numberoffiles);
    m = memmapfile(filename_sqb,'Format', { 'uint32' [1 1] 'offset'; ...
        'uint32' [1 1] 'garbage1';...
        'double' [1 1] 'timestamp';...
        'uint32' [1 1] 'file_idx';...
        'uint32' [1 1] 'garbage2' },'Repeat',nb_frames);
    
    data=m.Data;
    timestamps=[data.timestamp];
    
    if frame_idx==-1
        frame_idx=1:nb_frames;
    end
    
    classname=sprintf('uint%d',bpp*8);
    A=zeros([h,w,length(frame_idx)],classname);
    
    classname=['*' classname];
    
    for i=1:length(frame_idx)
        ii=frame_idx(i);
        if ~isempty(FileInfo.binrepertoire)
            binrepertoire=FileInfo.binrepertoire;
        else %used when binrepertoire empty, strange feature of rdvision
            binrepertoire=regexprep(FileInfo.bindirectory,'\\$','');%tranform Windows notation to Linux
            binrepertoire=regexprep(binrepertoire,'\','/');
            [tild,binrepertoire,DirExt]=fileparts(binrepertoire);
            binrepertoire=[binrepertoire DirExt];
        end 
        binfile=fullfile(RootPath,binrepertoire,sprintf('%s%.5d.bin',bin_file,data(ii).file_idx));
        fid=fopen(binfile,'rb');
        fseek(fid,data(ii).offset,-1);
        A(:,:,i)=reshape(fread(fid,w*h,classname),w,h)';
        fclose(fid);
    end
    
    if ~isempty(frame_idx)
        timestamps=timestamps(frame_idx);
    end
end

function Result = ini2struct(FileName)
%==========================================================================
%  Author: Andriy Nych ( nych.andriy@gmail.com )
% Version:        733341.4155741782200
%==========================================================================
% 
% INI = ini2struct(FileName)
% 
% This function parses INI file FileName and returns it as a structure with
% section names and keys as fields.
% 
% Sections from INI file are returned as fields of INI structure.
% Each fiels (section of INI file) in turn is structure.
% It's fields are variables from the corresponding section of the INI file.
% 
% If INI file contains "oprhan" variables at the beginning, they will be
% added as fields to INI structure.
% 
% Lines starting with ';' and '#' are ignored (comments).
% 
% See example below for more information.
% 
% Usually, INI files allow to put spaces and numbers in section names
% without restrictions as long as section name is between '[' and ']'.
% It makes people crazy to convert them to valid Matlab variables.
% For this purpose Matlab provides GENVARNAME function, which does
%  "Construct a valid MATLAB variable name from a given candidate".
% See 'help genvarname' for more information.
% 
% The INI2STRUCT function uses the GENVARNAME to convert strange INI
% file string into valid Matlab field names.
% 
% [ test.ini ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
%     SectionlessVar1=Oops
%     SectionlessVar2=I did it again ;o)
%     [Application]
%     Title = Cool program
%     LastDir = c:\Far\Far\Away
%     NumberOFSections = 2
%     [1st section]
%     param1 = val1
%     Param 2 = Val 2
%     [Section #2]
%     param1 = val1
%     Param 2 = Val 2
% 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
% The function converts this INI file it to the following structure:
% 
% [ MatLab session (R2006b) ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%  >> INI = ini2struct('test.ini');
%  >> disp(INI)
%         sectionlessvar1: 'Oops'
%         sectionlessvar2: 'I did it again ;o)'
%             application: [1x1 struct]
%             x1stSection: [1x1 struct]
%            section0x232: [1x1 struct]
% 
%  >> disp(INI.application)
%                    title: 'Cool program'
%                  lastdir: 'c:\Far\Far\Away'
%         numberofsections: '2'
% 
%  >> disp(INI.x1stSection)
%         param1: 'val1'
%         param2: 'Val 2'
% 
%  >> disp(INI.section0x232)
%         param1: 'val1'
%         param2: 'Val 2'
% 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
% NOTE.
% WhatToDoWithMyVeryCoolSectionAndVariableNamesInIniFileMyVeryCoolProgramWrites?
% GENVARNAME also does the following:
%   "Any string that exceeds NAMELENGTHMAX is truncated". (doc genvarname)
% Period.
% 
% =========================================================================
Result = [];                            % we have to return something
CurrMainField = '';                     % it will be used later
f = fopen(FileName,'r');                % open file
while ~feof(f)                          % and read until it ends
    s = strtrim(fgetl(f));              % Remove any leading/trailing spaces
    if isempty(s)
        continue;
    end;
    if (s(1)==';')                      % ';' start comment lines
        continue;
    end;
    if (s(1)=='#')                      % '#' start comment lines
        continue;
    end;
    if ( s(1)=='[' ) && (s(end)==']' )
        % We found section
        CurrMainField = genvarname(lower(s(2:end-1)));
        Result.(CurrMainField) = [];    % Create field in Result
    else
        % ??? This is not a section start
        [par,val] = strtok(s, '=');
        val = CleanValue(val);
        if ~isempty(CurrMainField)
            % But we found section before and have to fill it
            Result.(CurrMainField).(lower(genvarname(par))) = val;
        else
            % No sections found before. Orphan value
            Result.(lower(genvarname(par))) = val;
        end
    end
end
fclose(f);
return;

function res = CleanValue(s)
res = strtrim(s);
if strcmpi(res(1),'=')
    res(1)=[];
end
res = strtrim(res);
return;
