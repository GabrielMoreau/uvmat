%'set_col_vec': % sets the color code for vectors depending on a scalar and input parameters (used for plot_field)
%-----------------------------------------------------------------------
%function [colorlist,col_vec,minC,ColCode1,ColCode2,maxC]=colvec(colcode,vec_C)
%-----------------------------------------------------------------------
%OUTPUT
%colorlist(nb,3); %list of nb colors
%col_vec, size=[length(vec_C),3)];%list of color indices corresponding to vec_C
%minC, maxC: min and max of vec_C
%ColCode1, ColCode2: absolute threshold in vec_C corresponding to colcode.ColCode1 and colcode.ColCode2
%INPUT
% colcode: struture setting the colorcode for vectors
            % colcode.CName: 'ima_cor','black','white',...
            % colcode.ListColorCode ='black', 'white', 'rgb','brg', '64 colors'
            % colcode.CheckFixVecColor =0; thresholds scaling relative to min and max, =1 fixed thresholds
            % colcode.MinVec; min 
            % colcode.MaxVec; max
            % colcode.ColCode1: first threshold for rgb, relative to min (0) and max (1)
            % colcode.ColCode2: second threshold for rgb, relative to min (0) and max (1), 
            % rmq: we need min <= ColCode1 <= ColCode2 <= max, otherwise
            % ColCode1 and ColCode2 are adjusted to the bounds
% vec_C: matlab vector representing the scalar setting the color
function [colorlist,col_vec,colcode_out]=set_col_vec(colcode,vec_C)
col_vec=[]; 
colcode_out=colcode;%default
if isempty(vec_C) || ~isnumeric(vec_C)
    colorlist=[0 0 1]; %blue  
    col_vec=ones(size(vec_C));
    return
end
if (isfield(colcode,'CheckFixVecColor') && isequal(colcode.CheckFixVecColor,1))
    minC=colcode.MinVec;
    maxC=colcode.MaxVec;
else
    minC=min(vec_C);
    maxC=max(vec_C);
end

%default input parameters
if ~isstruct(colcode),colcode=[];end;
if ~isfield(colcode,'ListColorCode') || isempty(colcode.ListColorCode)
    colorlist=[0 0 1]; %blue  
    col_vec=ones(size(vec_C));
    return
end
if  isfield(colcode,'ColCode1')
    ColCode1=minC+colcode.ColCode1*(maxC-minC);
else
    ColCode1=minC+(maxC-minC)/3;%default
end
if isfield(colcode,'ColCode2')
    ColCode2=minC+colcode.ColCode2*(maxC-minC);
else
    ColCode2=minC+2*(maxC-minC)/3;%default
end
colcode_out.MinC=minC;
colcode_out.MaxC=maxC;
if strcmp(colcode.ListColorCode,'black')
    colorlist(1,:)=[0 0 0];%black
    col_vec=ones(size(vec_C));%all vectors at color#1
elseif strcmp(colcode.ListColorCode,'white')
    colorlist(1,:)=[1 1 1];%white
    col_vec=ones(size(vec_C));%all vectors at color#1
elseif strcmp(colcode.ListColorCode,'rgb')|| strcmp(colcode.ListColorCode,'bgr')% 3 color representation
%    ind1=find(vec_C < ColCode1); % =1 for red vectors
    ind_green=find((vec_C >= ColCode1) & (vec_C < ColCode2));% =1 for green vectors
%     ind3=find(vec_C >= ColCode2);% =1 for blue vectors
    colorlist(2,:)=[0 1 0];%green
    col_vec(vec_C < ColCode1)=1;
    col_vec(ind_green)=2;
    col_vec(vec_C >= ColCode2)=3;
    if strcmp(colcode.ListColorCode,'rgb')
        colorlist(1,:)=[1 0 0];%red
        colorlist(3,:)=[0 0 1];%blue
    else
        colorlist(1,:)=[0 0 1];%blue
        colorlist(3,:)=[1 0 0];%red
    end
else
    colorjet=jet;% ususal colormap from blue to red
    sizlist=size(colorjet);
    indsel=ceil((sizlist(1)/64)*(1:64));
    colorlist(:,1)=colorjet(indsel,1);
    colorlist(:,2)=colorjet(indsel,2);
    colorlist(:,3)=colorjet(indsel,3);
    sizlist=size(colorlist);
    nblevel=sizlist(1);
    col2_1=maxC-minC;
    col_vec=1+floor(nblevel*(vec_C-minC)/col2_1);
    col_vec=col_vec.*(col_vec<= nblevel)+nblevel*(col_vec >nblevel);% take color #nblevel at saturation
    col_vec=col_vec.*(col_vec>= 1)+  (col_vec <1);% take color #1 for values below 1
end
