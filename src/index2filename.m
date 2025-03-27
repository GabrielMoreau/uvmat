% get the file name and frame index from a set of multimage files (e.g. from PCO camera)
%------------------------------------------------------------------------
% [RootFile,FileIndexString,FrameIndex]=index2filename(FileSeries,i1,j1,NbField_j)
%
% OUTPUT:
% RootFile, FileIndexString: name of the multimage file = [RootFile FileIndexString FileExt]
% FrameIndex: index in the multimage file     
%
% INPUT:
% FileSeries: structure read from the xml file, defining the the multifile organisation of images  
% i1: global frame index i, or  single concatenated index vector (then no further input j1 and NbField_j
% j1: j index
% NbField_j: nbre of j indices in the index matrix

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
    [~,~,RootFile,i1,~,~,~,FileExt,NomType]=fileparts_uvmat(FileSeries.FileName{end});
    FileIndex=floor((i_vector-1)/FileSeries.NbFramePerFile)+1;
    if FileIndex>numel(FileSeries.FileName)
        FileIndex=FileIndex-numel(FileSeries.FileName)+i1;
        FileName=fullfile_uvmat('','',RootFile,FileExt,NomType,FileIndex);
    else
        FileName=FileSeries.FileName{FileIndex};
    end

    % switch FileSeries.Convention
    %     case 'PCO'
    %         RootFile=FileSeries.RootName;
    %         FileIndex=floor(i_vector/FileSeries.NbFramePerFile);
    %         if FileIndex>0
    %             RootFile=[RootFile '@'];
    %            FileIndexString=num2str(FileIndex,'%04d');
    %         end
    FrameIndex=mod(i_vector-1,FileSeries.NbFramePerFile)+1;
end



