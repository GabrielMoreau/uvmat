%'get_file_series': determine the list of file names and file indices for functions called by 'series'. 
%------------------------------------------------------------------------
% [filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param)
%
% OUTPUT:
% filecell{i,j}: cell array with the two reference indices i and j representing the list of file names
% i1_series,i2_series,j1_series,j2_series: corresponding arrays of indices i1,i2,j1,j2.
%
% INPUT:
% Param: structure of input parameters as read from the GUI series (by the function read_GUI)

function [filecell,i1_series,i2_series,j1_series,j2_series]=get_file_series(Param)

filecell={};
InputTable=Param.InputTable;
first_i=Param.IndexRange.first_i;
incr_i=Param.IndexRange.incr_i;
last_i=Param.IndexRange.last_i;
ref_i=first_i:incr_i:last_i;
ref_j=[];
if isfield(Param.IndexRange,'first_j')
    first_j=Param.IndexRange.first_j;
    incr_j=Param.IndexRange.incr_j;
    last_j=Param.IndexRange.last_j;
    ref_j=first_j:incr_j:last_j;
end
% Pairs=Param.Pairs;


%% determine the list of input file names
nbmissing=0;

for iview=1:size(InputTable,1)
    r.mode='';
    if isfield (Param.IndexRange,'PairString')
        r=regexp(Param.IndexRange.PairString{iview,1},'(?<mode>(Di=)|(Dj=)) -*(?<num1>\d+)\|(?<num2>\d+)','names');
        if isempty(r)
            r=regexp(Param.IndexRange.PairString{iview,1},'(?<num1>\d+)(?<mode>-)(?<num2>\d+)','names');
        end        
        % TODO case of free pairs:
        %r=regexp(pair_string,'.*\D(?<num1>[\d+|*])(?<delim>[-||])(?<num2>[\d+|*])','names');
    end
    if isempty(r)||isempty(r.mode)
        r(1).num1='';
        r(1).num2='';
        r(1).mode='';
    end
    [i1_series{iview},i2_series{iview},j1_series{iview},j2_series{iview}]=find_file_indices(ref_i,ref_j,str2num(r.num1),str2num(r.num2),r.mode);
    %case of pairs (.nc files)
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
        filecell{iview,ifile}=fullfile_uvmat(InputTable{iview,1},InputTable{iview,2},InputTable{iview,3},InputTable{iview,5},InputTable{iview,4}...
            ,i1,i2,j1,j2);
    end
end


function [i1_series,i2_series,j1_series,j2_series]=find_file_indices(ref_i,ref_j,num1,num2,mode)
i1_series=ref_i;%default
j1_series=[];
if ~isempty(ref_j)
%      i1_series=meshgrid(ref_i,ones(size(ref_j)));
% %     j1_series=meshgrid(ref_i,ones(size(ref_j)));
%     j1_series=meshgrid(ones(size(ref_i)),ref_j);
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