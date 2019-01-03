%'get_file_series': determine the list of input file names and file indices for functions called by 'series'. 
%------------------------------------------------------------------------
% [filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param)
%
% OUTPUT:
% filecell{iview,fileindex}: cell array representing the list of file names
%        iview: line in the table corresponding to a given file series
%        fileindex: file index within  the file series, 
% i1_series{iview}(ref_j,ref_i)... are the corresponding arrays of indices i1,i2,j1,j2, depending on the input line iview and the two reference indices ref_i,ref_j 
% i1_series{iview}(fileindex) expresses the same indices as a 1D array in file indices
%
% INPUT:
% Param: structure of input parameters as read from the GUI series (by the function read_GUI)

%=======================================================================
% Copyright 2008-2019, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
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

function [filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param)

filecell={};
InputTable=Param.InputTable;
first_i=Param.IndexRange.first_i;
incr_i=Param.IndexRange.incr_i;
last_i=Param.IndexRange.last_i;
first_j=[];last_j=[];incr_j=1;%default
if isfield(Param.IndexRange,'first_j')&& isfield(Param.IndexRange,'last_j')
    first_j=Param.IndexRange.first_j;
    last_j=Param.IndexRange.last_j;
end
if isfield(Param.IndexRange,'incr_j')
    incr_j=Param.IndexRange.incr_j;
end

%% determine the list of input file names
% nbmissing=0;
NbView=size(InputTable,1);
i1_series=cell(NbView,1);% initiate index series with empty cells
i2_series=cell(NbView,1);
j1_series=cell(NbView,1);
j2_series=cell(NbView,1);
for iview=1:NbView
    r.mode='';
    if isfield (Param.IndexRange,'PairString')
        if ischar(Param.IndexRange.PairString)
            Param.IndexRange.PairString={Param.IndexRange.PairString};
        end
        if size(Param.IndexRange.PairString,1)>=iview && ~isempty(Param.IndexRange.PairString{iview,1})
            r=regexp(Param.IndexRange.PairString{iview,1},'(?<mode>(Di=)|(Dj=)) -*(?<num1>\d+)\|(?<num2>\d+)','names');%look for mode=Dj or Di
            if isempty(r)
                r=regexp(Param.IndexRange.PairString{iview,1},'(?<num1>\d+)(?<mode>-)(?<num2>\d+)','names');%look for burst pairs
            end
        end
        % TODO case of free pairs:
        %r=regexp(pair_string,'.*\D(?<num1>[\d+|*])(?<delim>[-||])(?<num2>[\d+|*])','names');
    end
    if isempty(r)||isempty(r.mode)
        r(1).num1='';
        r(1).num2='';
        if isfield (Param.IndexRange,'PairString') && size(Param.IndexRange.PairString,1)>=iview &&...
                                                           strcmp(Param.IndexRange.PairString{iview,1},'j=*-*')
            r(1).mode='*-*';
        else
            r(1).mode='';
        end
    end
    
    if isempty(incr_i) || isempty(incr_j) || isequal(r(1).mode,'*-*')|| isequal(r(1).mode,'*|*')% free pairs or increment
        FilePath=fullfile(InputTable{iview,1},InputTable{iview,2});
        fileinput=[InputTable{iview,3} InputTable{iview,4} InputTable{iview,5}];
        [tild,tild,tild,i1_series{iview},i2_series{iview},j1_series{iview},j2_series{iview},NomType,FileInfo,MovieObject,...
            i1_input,i2_input,j1_input,j2_input]=find_file_series(FilePath,fileinput);
        i1_series{iview}=squeeze(i1_series{iview}(1,:,:)); %select first  pair index as ordered by find_file_series
        i2_series{iview}=squeeze(i2_series{iview}(1,:,:)); %select first  pair index as ordered by find_file_series
        j1_series{iview}=squeeze(j1_series{iview}(1,:,:)); %first  pair index
        j2_series{iview}=squeeze(j2_series{iview}(1,:,:)); %second  pair index
        if isempty(incr_i)
            if isempty(first_j) || isempty(incr_j) % no j index or no defined increment for j
                ref_j=find(max(i1_series{iview},[],2));
                ref_i=find(max(i1_series{iview},[],1));
                ref_i=ref_i-1;
                ref_j=ref_j-1;
                ref_i=ref_i(ref_i>=first_i & ref_i<=last_i);
                ref_j=ref_j(ref_j>=first_j & ref_j<=last_j);
            else
                ref_j=first_j:incr_j:last_j;
                ref_i=find(max(i1_series{iview}(:,ref_j),[],1));
                ref_i=ref_i-1;
                ref_i=ref_i(ref_i>=first_i & ref_i<=last_i);
            end
        else
            ref_i=first_i:incr_i:last_i;%default
            if isempty(first_j) ||isempty(incr_j)% no j index or no defined increment for j
                ref_j=find(max(i1_series{iview},[],2));
                ref_j=ref_j-1;
                ref_j=ref_j(ref_j>=first_j & ref_j<=last_j);
            else
                ref_j=first_j:incr_j:last_j;
            end
        end
        if isempty(ref_j)
            i1_series{iview}=i1_series{iview}(2,ref_i+1);
            if ~isempty(i2_series{iview})
                i2_series{iview}=i2_series{iview}(2,ref_i+1);
            end
        else
            i1_series{iview}=i1_series{iview}(ref_j+1,ref_i+1);
            if ~isempty(i2_series{iview})
                i2_series{iview}=i2_series{iview}(ref_j+1,ref_i+1);
            end
        end
        if ~isempty(j1_series{iview})
            j1_series{iview}=j1_series{iview}(ref_j+1,ref_i+1);
            if ~isempty(j2_series{iview})
                j2_series{iview}=j2_series{iview}(ref_j+1,ref_i+1);
            end
        end
    else
        ref_i=first_i:incr_i:last_i;%default
        ref_j=first_j:incr_j:last_j;%default
        [i1_series{iview},i2_series{iview},j1_series{iview},j2_series{iview}]=find_file_indices(ref_i,ref_j,str2num(r.num1),str2num(r.num2),r.mode);
    end
    %     if ~isequal(r(1).mode,'*-*')% imposed pairs or single i and/or j index
    %         [i1_series{iview},i2_series{iview},j1_series{iview},j2_series{iview}]=find_file_indices(ref_i,ref_j,str2num(r.num1),str2num(r.num2),r.mode);
    %     end
    
    %list of files
    i2=[];j1=[];j2=[];
    for ifile=1:numel(i1_series{iview})
        i1=i1_series{iview}(ifile);
        if ~isempty(i2_series{iview})
            i2=i2_series{iview}(ifile);
        end
        if ~isempty(j1_series{iview})
            j1=j1_series{iview}(ifile);
        end
        if ~isempty(j2_series{iview})
            j2=j2_series{iview}(ifile);
        end
        filecell{iview,ifile}=fullfile_uvmat(InputTable{iview,1},InputTable{iview,2},InputTable{iview,3},InputTable{iview,5},InputTable{iview,4},i1,i2,j1,j2);
    end
end


function [i1_series,i2_series,j1_series,j2_series]=find_file_indices(ref_i,ref_j,num1,num2,mode)
i1_series=ref_i;%default
j1_series=[];
if ~isempty(ref_j)
    [i1_series,j1_series]=meshgrid(ref_i,ref_j);
end
i2_series=i1_series;
j2_series=j1_series;

switch mode
    case 'Di='  %  case 'series(Di)')
        i1_series=i1_series-num1;
        i2_series=i2_series+num2;
    case 'Dj='  %  case 'series(Dj)'
        j1_series=j1_series-num1;
        j2_series=j2_series+num2;
    case '-'  % case 'bursts'
        j1_series=num1*ones(size(i1_series));
        j2_series=num2*ones(size(i1_series));
end
