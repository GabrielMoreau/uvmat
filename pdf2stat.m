%'pdf2stat': calculate statistics from pdf
%
%OUTPUT:
% VarVal(13,nb_component):statistics for each of the input components
% line 1: 'SampleNbre': nbe of samples (sum of pdf_val)
% line 2: 'BinSize'
% line 3: 'Mean': mean value
% line 4: 'RMS': root mean square deviation from mean
% line 5: 'Skewness': third order moment normalized by (rms)^3
% line 6: 'Kurtosis': : fourth order moment normalized by (rms)^4 (= 3 for a Gaussian)
% line 7: 'Min': min value
%  statistics for the centered variable (x-mean)
% line 8: 'FirstCentile': first centile 
% line 9: 'FirstDecile'
% line 10: 'Median'
% line 11: 'LastDecile'
% line 12: 'LastCentile'
% line 13: 'Max'
%
% INPUT:
% x(nb_bin): column vector representing the set of variable values for each bin of the histogram
% pdf_val(nb_bin,nb_component): values of the histogram at each bin x,
%              possibly with different components (e.g. rgb color image)
% 

function VarVal=pdf2stat(x,pdf_val)
if ~exist('x','var')% list the stat names
    VarVal={'SampleNbre';'BinSize';'Mean';'RMS';'Skewness';'Kurtosis';...
        'Min';'FirstCentile';'FirstDecile';'Median';'LastDecile';'LastCentile';'Max'};
else
    nbvar=size(pdf_val,2);
    VarVal=zeros(13,nbvar);
    for ivar=1:nbvar
    VarVal(1,ivar)=sum(pdf_val(:,ivar));% total sample number
    VarVal(7,ivar)=min(x);
    VarVal(13,ivar)=max(x);
    VarVal(2,ivar)=(VarVal(13,ivar)-VarVal(7,ivar))/(numel(x)-1);%bin size
    pdf_val(:,ivar)=pdf_val(:,ivar)/VarVal(1,ivar);% normalised pdf
    VarVal(3,ivar)=sum(x.*pdf_val(:,ivar));%Mean
    x=x-VarVal(3,ivar); %centered variable
    Variance=sum(x.*x.*pdf_val(:,ivar));
    VarVal(4,ivar)=sqrt(Variance);
    VarVal(5,ivar)=(sum(x.*x.*x.*pdf_val(:,ivar)))/(Variance*VarVal(4,ivar));%skewness
    VarVal(6,ivar)=(sum(x.*x.*x.*x.*pdf_val(:,ivar)))/(Variance*Variance);%kurtosis
    cumpdf=cumsum(pdf_val(:,ivar));% sum of pdf
    ind_centile=find(cumpdf>=0.01,1);% first index with cumsum >=0.01
    VarVal(8,ivar)=x(ind_centile)+VarVal(2,ivar)/2;%
    if ind_centile>1
        VarVal(8,ivar)=(cumpdf(ind_centile)-0.01)*x(ind_centile-1)+(0.01-cumpdf(ind_centile-1))*x(ind_centile);
        VarVal(8,ivar)=VarVal(8,ivar)/(cumpdf(ind_centile)-cumpdf(ind_centile-1))+VarVal(2,ivar)/2;%linear interpolation near ind_centile
    end
    ind_decile=find(cumpdf>=0.1,1);
    if ind_decile>1
        VarVal(9,ivar)=x(ind_decile)+VarVal(2,ivar)/2;%
        VarVal(9,ivar)=(cumpdf(ind_decile)-0.1)*x(ind_decile-1)+(0.1-cumpdf(ind_decile-1))*x(ind_decile);
        VarVal(9,ivar)=VarVal(9,ivar)/(cumpdf(ind_decile)-cumpdf(ind_decile-1))+VarVal(2,ivar)/2;%linear interpolation near ind_decile;
    end
    ind_median=find(cumpdf>= 0.5,1);
    if ind_median<=1 % not enough data
        return
    end
    VarVal(10,ivar)=(cumpdf(ind_median)-0.5)*x(ind_median-1)+(0.5-cumpdf(ind_median-1))*x(ind_median);
    VarVal(10,ivar)=VarVal(10,ivar)/(cumpdf(ind_median)-cumpdf(ind_median-1))+VarVal(2,ivar)/2;%linear interpolation near ind_median;
    %     VarVal(9)=x(ind_median);
    ind_decile=find(cumpdf>=0.9,1);
    VarVal(11,ivar)=(cumpdf(ind_decile)-0.9)*x(ind_decile-1)+(0.9-cumpdf(ind_decile-1))*x(ind_decile);
    VarVal(11,ivar)=VarVal(11,ivar)/(cumpdf(ind_decile)-cumpdf(ind_decile-1))+VarVal(2,ivar)/2;%linear interpolation near ind_median;
    ind_centile=find(cumpdf>=0.99,1);
    VarVal(12,ivar)=(cumpdf(ind_centile)-0.99)*x(ind_centile-1)+(0.99-cumpdf(ind_centile-1))*x(ind_centile);
    VarVal(12,ivar)=VarVal(12,ivar)/(cumpdf(ind_centile)-cumpdf(ind_centile-1))+VarVal(2,ivar)/2;%linear interpolation near ind_centile;
    end
end
