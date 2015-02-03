%'calc_field_interp': calculate fields (velocity, vort, div...) using linear interpolation if requested
%---------------------------------------------------------------------
% [VarVal,ListVarName,VarAttribute,errormsg]=calc_field_interp(Coord,Data,FieldName,XI,YI)
%
% OUTPUT:
% VarVal: array giving the values of the calculated field
% ListVarName: corresponding list of variable names
% VarAttribute: corresponding list of variable attributes, each term #ilist is of the form VarAttribute{ilist}.tag=value
%
% INPUT:
% Coord(nbpoints,2): matrix of x,y coordinates of the input data points
% Data: inputfield structure
% FieldName: string representing the field to calculate, or cell array of fields (as displayed in uvmat/FieldName)
% XI, YI: set of x and y coordinates where the fields need to be linearly interpolated, 
%        if XI, YI are missing, there is no interpolation (case of colors in vector plots)

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

function [VarVal,ListVarName,VarAttribute,errormsg]=calc_field_interp(Coord,Data,FieldName,XI,YI)

%% initialization
VarVal={};
ListVarName={};
VarAttribute={};
errormsg='';
InputVarList={};
if ischar(FieldName),FieldName={FieldName};end
check_skipped=zeros(size(FieldName));% default, =1 to mark the variables which can be calculated
check_interp=ones(size(FieldName));% default, =1 to mark the variables which can be interpolated (not ancillary)
Operator=cell(size(FieldName));

%% analyse the list of input fields: needed variables and requested operations
for ilist=1:numel(FieldName)
    Operator{ilist}='';%default empty operator (vec, norm,...)
    r=regexp(FieldName{ilist},'(?<Operator>(^vec|^norm|^curl|^div|^strain))\((?<UName>.+),(?<VName>.+)\)$','names');% analyse the field name
    if isempty(r) % no operator: the field name is a variable itself
        ivar=find(strcmp(FieldName{ilist},Data.ListVarName));
        if isempty(ivar)% the requested variable does not exist
            check_skipped(ilist)=1; %variable not found
        elseif isempty(find(strcmp(FieldName{ilist},InputVarList), 1));% the variable exists and has not been already selected
            if isfield(Data.VarAttribute{ivar},'Role') &&...
                    (strcmp(Data.VarAttribute{ivar}.Role,'ancillary')||strcmp(Data.VarAttribute{ivar}.Role,'warnflag')||strcmp(Data.VarAttribute{ivar}.Role,'errorflag'))
                check_interp(ilist)=0; % ancillary variable, not interpolated ?????
                check_skipped(ilist)=1; %variable not used
            else
                InputVarList=[InputVarList FieldName{ilist}];% the variable is added to the list of input variables
            end
        end
    else
        if ~isfield(Data,r.UName)||~isfield(Data,r.VName)%needed input variable not found
            check_skipped(ilist)=1;
        elseif strcmp(r.Operator,'curl')||strcmp(r.Operator,'div')||strcmp(r.Operator,'strain')
            Operator{ilist}=r.Operator;
            switch r.Operator
                case 'curl'% case of CivX data format
                    if ~isfield(Data,'DjUi'), errormsg='field DjUi needed to get curl through linear interp: use ProjMode=interp_tps'; return; end
                    UName{ilist}='vort';
                    Data.vort=Data.DjUi(:,1,2)-Data.DjUi(:,2,1);
                case 'div'
                    if ~isfield(Data,'DjUi'), errormsg='field DjUi needed to get div through linear interp: use ProjMode=interp_tps'; return; end
                    UName{ilist}='div';
                    Data.div=Data.DjUi(:,1,1)+Data.DjUi(:,2,2);
                case 'strain'
                    if ~isfield(Data,'DjUi'), errormsg='field DjUi needed to get strain through linear interp: use ProjMode=interp_tps'; return; end
                    UName{ilist}='strain';
                    Data.strain=Data.DjUi(:,1,2)+Data.DjUi(:,2,1);
            end
            InputVarList=[InputVarList UName{ilist}]; %the variable is added to the list if it is not already in the list
        else % case  'norm' for instance
            UName{ilist}=r.UName;
            VName{ilist}=r.VName;
            if isempty(find(strcmp(r.UName,InputVarList)));
                InputVarList=[InputVarList UName{ilist}]; %the variable is added to the list if it is not already in the list
            end
            if isempty(find(strcmp(r.VName,InputVarList), 1));
                InputVarList=[InputVarList VName{ilist}]; %the variable is added to the list if it is not already in the list
            end
            Operator{ilist}=r.Operator;
        end
    end
end

%% create interpolator for each variable to interpolate
if exist('XI','var')
    for ilist=1:numel(InputVarList)
        F.(InputVarList{ilist})=TriScatteredInterp(Coord,Data.(InputVarList{ilist}),'linear');
    end
end

%% perform the linear interpolation for the requested variables
for ilist=1:numel(FieldName)
    if ~check_skipped(ilist)
        nbvar=numel(ListVarName);
        switch Operator{ilist}
            case 'vec'
                if exist('XI','var')
                    if check_interp(ilist)
                    VarVal{nbvar+1}=F.(UName{ilist})(XI,YI);
                    VarVal{nbvar+2}=F.(VName{ilist})(XI,YI);
                    end
                else
                    VarVal{nbvar+1}=Data.(UName{ilist});
                    VarVal{nbvar+2}=Data.(VName{ilist});
                end
                ListVarName{nbvar+1}=UName{ilist};
                ListVarName{nbvar+2}=VName{ilist};
                VarAttribute{nbvar+1}.Role='vector_x';
                VarAttribute{nbvar+2}.Role='vector_y';
            case 'norm'
                if exist('XI','var')
                    if check_interp(ilist)
                    U2=F.(UName{ilist})(XI,YI).*F.(UName{ilist})(XI,YI);
                    V2=F.(VName{ilist})(XI,YI).*F.(VName{ilist})(XI,YI);
                    end
                else
                    U2=Data.(UName{ilist}).*Data.(UName{ilist});
                    V2=Data.(VName{ilist}).*Data.(VName{ilist});
                end
                VarVal{nbvar+1}=sqrt(U2+V2);
                ListVarName{nbvar+1}='norm';
                VarAttribute{nbvar+1}.Role='scalar';
            case {'curl','div','strain'}
                if exist('XI','var')
                    if check_interp(ilist)
                    VarVal{nbvar+1}=F.(UName{ilist})(XI,YI);
                    end
                else
                    VarVal{nbvar+1}=Data.(UName{ilist});
                end
                ListVarName{nbvar+1}=UName{ilist};
                VarAttribute{nbvar+1}.Role='scalar';
            otherwise
                if ~isempty(FieldName{ilist})
                    if exist('XI','var')
                        if check_interp(ilist)
                        VarVal{nbvar+1}=F.(FieldName{ilist})(XI,YI);
                        end
                    else
                        VarVal{nbvar+1}= Data.(FieldName{ilist});
                    end
                    ListVarName{nbvar+1}=FieldName{ilist};
                    VarAttribute{nbvar+1}.Role='scalar';
                end
        end
    end
end

%% put an error flag to indicate NaN data
% if exist('XI','var')&&~isempty(VarVal)
%     nbvar=numel(VarVal);
%     ListVarName{nbvar+1}='FF';
%     VarVal{nbvar+1}=isnan(VarVal{nbvar});
%     VarAttribute{nbvar+1}.Role='errorflag';
% end





