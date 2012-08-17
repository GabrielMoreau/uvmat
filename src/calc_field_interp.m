
%'calc_field': defines fields (velocity, vort, div...) from civ data and calculate them
%---------------------------------------------------------------------
% [DataOut,VarAttribute,errormsg]=calc_field_interp(Coord_tps,NbSites,SubRange,FieldVar,Operation,Coord_interp)
%
% OUTPUT:
% DataOut: structure representing the output fields
%
% INPUT:
% Coord_tps:
% NbSites
% SubRange
% FieldVar
% Operation: cell array representing the list of operations (eg div, rot..)
% Coord_interp: coordiantes of sites on which the fields need to be calculated

function [VarVal,ListVarName,VarAttribute,errormsg]=calc_field_interp(Coord,Data,Operation,XI,YI)

VarVal=[];
ListVarName={};
VarAttribute={};
errormsg='';
InputVarList={};
if ischar(Operation),Operation={Operation};end
for ilist=1:numel(Operation)
    r=regexp(Operation{ilist},'(?<Operator>(^vec|^norm))\((?<UName>.+),(?<VName>.+)\)$','names');
    if isempty(r) % the operation is the variable
        if isempty(find(strcmp(Operation{ilist},InputVarList)));
            InputVarList=[InputVarList Operation{ilist}];
        end
        Operator{ilist}='';
    else
        UName{ilist}=r.UName;
        VName{ilist}=r.VName;
        if isempty(find(strcmp(r.UName,InputVarList)));
            InputVarList=[InputVarList UName{ilist}];
        end
        if isempty(find(strcmp(r.VName,InputVarList)));
            InputVarList=[InputVarList VName{ilist}];
        end
        Operator{ilist}=r.Operator;
    end
end
%create interpolator for linear interpolation
if exist('XI','var')
    for ilist=1:numel(InputVarList)
        F.(InputVarList{ilist})=TriScatteredInterp(Coord,Data.(InputVarList{ilist}),'linear');
    end
end
for ilist=1:numel(Operation)
    nbvar=numel(ListVarName);
    switch Operator{ilist}
        case 'vec'
            if exist('XI','var')
                VarVal{nbvar+1}=F.(UName{ilist})(XI,YI);
                VarVal{nbvar+2}=F.(VName{ilist})(XI,YI);
            else
                VarVal{nbvar+1}=Data.(UName{ilist});
                VarVal{nbvar+2}=Data.(VName{ilist});
            end
            ListVarName{nbvar+1}=UName{ilist};
            ListVarName{nbvar+2}=VName{ilist};
            VarAttribute{nbvar+1}.Role='vector_x';
            VarAttribute{nbvar+2}.Role='vector_y';
            %         case 'U'
            %             VarVal{nbvar+1}=F_u(XI,YI);
            %             ListVarName{nbvar+1}='U';
            %             VarAttribute{nbvar+1}.Role='scalar';
            %         case 'V'
            %             VarVal{nbvar+1}=F_v(XI,YI);
            %             ListVarName{nbvar+1}='V';
            %             VarAttribute{nbvar+1}.Role='scalar';
        case 'norm'
            if exist('XI','var')
                U2=F.(UName{ilist})(XI,YI).*F.(UName{ilist})(XI,YI);
                V2=F.(VName{ilist})(XI,YI).*F.(VName{ilist})(XI,YI);
            else
                U2=Data.(UName{ilist}).*Data.(UName{ilist});
                V2=Data.(VName{ilist}).*Data.(VName{ilist});
            end
            VarVal{nbvar+1}=sqrt(U2+V2);
            ListVarName{nbvar+1}='norm';
            VarAttribute{nbvar+1}.Role='scalar';
        otherwise
            if ~isempty(Operation{ilist})
                if exist('XI','var')
                    VarVal{nbvar+1}=F.(Operation{ilist})(XI,YI);
                else
                    VarVal{nbvar+1}= Data.(Operation{ilist});
                end
                ListVarName{nbvar+1}=Operation{ilist};
                VarAttribute{nbvar+1}.Role='scalar';
            end
    end
end
% put an error flag to indicate NaN data
if exist('XI','var')
nbvar=numel(ListVarName);
ListVarName{nbvar+1}='FF';
VarVal{nbvar+1}=isnan(VarVal{nbvar});
VarAttribute{nbvar+1}.Role='errorflag';
end

% Attr_FF.Role='errorflag';
% VarAttribute=[VarAttribute {Attr_FF}];





