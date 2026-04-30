% translate logical indices i1, j1, into file name and frame index in a set of multimage files (e.g. from PCO camera)
%------------------------------------------------------------------------
% [RootFile,FrameIndex]=index2filename(FileSeries,i1,j1,NbField_j)
%
% OUTPUT:
% FileName: name of the multimage file = [RootFile FileIndexString FileExt]
% FrameIndex: index in the multimage file FileName    
%
% INPUT:
% FileSeries: structure read from the xml file, defining the  multifile organisation of images  
% i1: global frame index i, or  single concatenated index vector (then no  input j1 and NbField_j
% j1: j index
% NbField_j: nbre of j indices in the index matrix

%=======================================================================
% Copyright 2008-2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [FileName,FrameIndex]=index2filename(FileSeries,i1,j1,NbField_j)
FileName='';
% FileIndexString='';
FrameIndex=1;
if isfield(FileSeries,'FileName')
    if exist('j1','var')&&~isnan(NbField_j)
        if isempty(j1)
            j1=1;
        end
        i_vector=(i1-1)*NbField_j+j1;%frames labeld with two indices i and j
    else
        i_vector=i1;% frames labelled with a single concatenated index vector
    end
    if ischar(FileSeries.FileName)
        FileSeries.FileName={FileSeries.FileName};
    end
    %[~,~,RootFile,i1,~,~,~,FileExt,NomType]=fileparts_uvmat(FileSeries.FileName{end});
    [~,~,FileExt]=fileparts(FileSeries.FileName{end});
[rr,index_rank]=regexp(FileSeries.FileName{end},['(?<i1>\d+)' FileExt '$'],'names');
i1=str2double(rr.i1);
RootFile=FileSeries.FileName{end}(1:index_rank-1);
nbdigit=numel(rr.i1);
numstring=['%0' num2str(nbdigit) 'd'];
    FileIndex=floor((i_vector-1)/FileSeries.NbFramePerFile)+1;
    if FileIndex>numel(FileSeries.FileName)
        FileIndex=FileIndex-numel(FileSeries.FileName)+i1;
        FileName=[RootFile num2str(FileIndex,numstring) FileExt];
       % FileName=fullfile_indices(RootFile,FileExt,NomType,FileIndex);
    else
        FileName=FileSeries.FileName{FileIndex};
    end
    FrameIndex=mod(i_vector-1,FileSeries.NbFramePerFile)+1;
end



