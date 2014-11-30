%'read_multimadoc': read a set of Imadoc files for different file series and compare their timing 
%------------------------------------------------------------------------
% [XmlData,NbSlice_calib,time,warnmsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series)
%
% OUTPUT:
% XmlData(iview): cell array of structures representing the contents of the xml files, iview =index of the input file series
% NbSlice_calib: nbre of slices detected in the geometric calibration data
% Time(iview,i,j): matrix of times, iview =index of the series, i,j=file indices within the series
%                if the time is not consistent in all series, the time from the first series is chosen
% warnmsg: warning message, ='' if  OK
%
% INPUT:
% RootPath,SubDir,RootFile,FileExt: cell arrays characterizing the input file series
% i1_series,i2_series,j1_series,j2_series: cell arrays of file index arrays, as given by the fct uvmat/get_file_series

%=======================================================================
% Copyright 2008-2014, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
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

function [XmlData,NbSlice_calib,Time,warnmsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series)
warnmsg='';
if ischar(RootPath)
    RootPath={RootPath};SubDir={SubDir};RootFile={RootFile};FileExt={FileExt};
end
nbview=numel(RootPath);
XmlData=cell(1,nbview);%initiate the structures containing the data from the xml file (calibration and timing)
NbSlice_calib=cell(1,nbview);
timecell=cell(1,nbview);
for iview=1:nbview%Loop on views
    XmlFileName=find_imadoc(RootPath{iview},SubDir{iview},RootFile{iview},FileExt{iview});
    if ~isempty(XmlFileName)
        [XmlData{iview},warnmsg]=imadoc2struct(XmlFileName);% read the ImaDoc xml file
    end
    if isfield(XmlData{iview},'Time')
        timecell{iview}=XmlData{iview}.Time;
    end
    if isfield(XmlData{iview},'GeometryCalib') && isfield(XmlData{iview}.GeometryCalib,'SliceCoord')
        NbSlice_calib{iview}=size(XmlData{iview}.GeometryCalib.SliceCoord,1);%nbre of slices for Zindex in phys transform
        if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
            warnmsg='inconsistent number of Z indices in field series';
        end
    end
end

%% check coincidence in time for several input file series
if isempty(timecell)
    Time=[];
else
    Time=get_time(timecell{1},i1_series{1},i2_series{1},j1_series{1},j2_series{1});
end
if nbview>1
    Time=shiftdim(Time,-1); % add a singleton dimension for nbview
    for icell=2:nbview
        if isequal(size(timecell{icell}),size(timecell{1}))
            time_line=get_time(timecell{icell},i1_series{icell},i2_series{icell},j1_series{icell},j2_series{icell});
            Time=cat(1,Time,shiftdim(time_line,-1));
        else
            warnmsg='inconsistent time array dimensions in ImaDoc fields, the time for the first series is used';
            Time=cat(1,Time,Time(1,:,:));% copy times of the first line
            break
        end
    end
end

function time=get_time(timeimadoc,i1_series,i2_series,j1_series,j2_series)
 time=[];
 if ~ (isempty(i2_series)||size(timeimadoc,1) < i2_series(end) ||( ~isempty(j2_series) && size(timeimadoc,2) < j2_series(end)))% time array absent or too short in ImaDoc xml file'
     if isempty(j1_series)
         j1_series=1;
     end
     time=timeimadoc(i1_series+1,j1_series+1);
     if ~isempty(j2_series)
         time=[time timeimadoc(i1_series+1,j2_series+1)];
     end
     if ~isempty(i2_series)
         time=[time timeimadoc(i2_series+1,j1_series+1)];
         if ~isempty(j2_series)
             time=[time timeimadoc(i2_series+1,j2_series+1)];
         end
     end
    time=mean(time,2);
     time=time';
 end
