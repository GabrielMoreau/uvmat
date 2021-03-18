% read_lvm: read data from the output files of labview (file extension .lvm) 

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function Data=read_lvm(filename)
Data.ListGlobalAttribute={'FileName','Experiment','DateTime'};
[Path,Data.FileName] = fileparts(filename);% record the file name
[tild,Data.Experiment]=fileparts(Path);% record the experient name

%% read the full text of the file as a char string txt
txt = fileread(filename);

%% get time string (date and time of the experiment)

Date_pos=regexp(txt,'Date\s','once');%find the char string 'Date' followed by a blank
txt(1:Date_pos+length('Date'))=[]; %remove the header until 'Date';
DateString=txt(1:regexp(txt,'\n','once')-1);% read char until the next line break
r1=regexp(DateString,'(?<DateDat>\S+)','names');% keep the non blank string
Time_pos=regexp(txt,'Time\s','once');%find the char string 'Time' followed by a blank
txt(1:Time_pos+length('Time'))=[]; %remove the header until 'Time';
TimeString=txt(1:regexp(txt,'\n','once')-1);% read char until the next line break
r2=regexp(TimeString,'(?<TimeDat>\S+)','names');% keep the non blank string
TimeString=regexprep(r2.TimeDat,',','.');% replace ',' by '.'
Dot_pos=regexp(TimeString,'\.');
TimeString=TimeString(1:Dot_pos+2); % round to 1/100 s
r1.DateDat=regexprep(r1.DateDat,'/','-');%replace '/' by '-' (to get standard date representation recognized by Matlab)
Data.DateTime=[r1.DateDat ' ' TimeString];%insert date to the time string (separated by a blank)

%% remove header text
Header_pos=regexp(txt,'***End_of_Header***','once');%find the first '***End_of_Header***'
txt(1:Header_pos+length('***End_of_Header***')+1)=[];%remove header
Header_pos=regexp(txt,'***End_of_Header***','once');%find the second '***End_of_Header***'
txt(1:Header_pos+length('***End_of_Header***')+1)=[];%remove header
title_pos=regexp(txt,'\S','once');% find the next non blank char
txt(1:title_pos-1)=[];% remove the  blank char at the beginning

%% get the list of channel names
Break_pos=regexp(txt,'\n','once');%find the line break
VarNameCell=textscan(txt(1:Break_pos-2),'%s');% read list of variable names (until next line break)
Data.ListVarName=VarNameCell{1};
Data.ListVarName(end)=[]; %remove last name (Comment)
Data.ListVarName{1}='Time'; %replace first name ('X_Value') by 'Time')
NbChannel=numel(Data.ListVarName);
for ivar=1:NbChannel
    Data.VarDimName{ivar}='nb_sample';
end

%% get the data
txt(1:Break_pos-1)=[];%removes line of channel names
txt=regexprep(txt,',','.');%replace comma by dots (French to English notation)
txt=textscan(txt,'%s');% transform txt in a cell of strings 
txt=reshape(txt{1},NbChannel,[]);
txt=cellfun(@str2double,txt);% transform char to a matrix of numbers
txt=txt'; %transpose matrix
for ivar=1:NbChannel
    Data.(Data.ListVarName{ivar})=txt(:,ivar);
end

%% calculate position in case of a non-zero motor signal
% To plot profiles(e;g.for C5):  plot(Data.Position(Data.Speed<0),Data.C5(Data.Speed<0))
SpeedDown=-1; %motot speed 1 cm/s
SpeedUp=1; %motot speed 1 cm/s
if isfield(Data,'Motor_profile')% Motor_profile signal =0 (no motion), -5 (down), +5(up)
    Data.ListVarName=[Data.ListVarName' {'Position','Speed'}];
    Data.VarDimName=[Data.VarDimName {'nb_sample','nb_sample'}];
    Speed=zeros(size(Data.Motor_profile));
    if ~isempty(find(Data.Motor_profile>2.5|Data.Motor_profile<-2.5))
        Speed(Data.Motor_profile>2.5)=SpeedDown;% threshold at 2.5 to avoid noise effects
        Speed(Data.Motor_profile<-2.5)=SpeedUp;
        Data.Speed=Speed;
        Speed(end)=[];
        Data.Position=[0; cumsum(Speed.*diff(Data.Time))];
        Data.Position=Data.Position-min(Data.Position);% set minimum to 0
    end
end
    
