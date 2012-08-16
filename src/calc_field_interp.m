
%'calc_field': defines fields (velocity, vort, div...) from civx data and calculate them
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

function [VarVal,ListVarName,VarAttribute,errormsg]=calc_field_interp(Coord,FieldVar,Operation,XI,YI)

VarVal=[];
ListVarName={};
VarAttribute={};
errormsg='';
check_u=0;
check_v=0;
for ilist=1:length(Operation)
    switch Operation{ilist}
        case {'U'}
           check_u=1;
        case {'V'}
            check_v=1;
          case {'vec(U,V)','norm(U,V)'}  
             check_u=1;
             check_v=1;
    end
end
if check_u
    F_u = TriScatteredInterp(Coord,FieldVar(:,1),'linear');
end
if check_v
    F_v = TriScatteredInterp(Coord,FieldVar(:,2),'linear');
end
for ilist=1:length(Operation)
    nbvar=numel(ListVarName);
    switch Operation{ilist}
        case 'vec(U,V)'
            VarVal{nbvar+1}=F_u(XI,YI);
            VarVal{nbvar+2}=F_v(XI,YI);
            ListVarName{nbvar+1}='U';
            ListVarName{nbvar+2}='V';
            VarAttribute{nbvar+1}.Role='vector_x';
            VarAttribute{nbvar+2}.Role='vector_y';
        case 'U'
            VarVal{nbvar+1}=F_u(XI,YI);
            ListVarName{nbvar+1}='U';
            VarAttribute{nbvar+1}.Role='scalar';
        case 'V'
            VarVal{nbvar+1}=F_v(XI,YI);
            ListVarName{nbvar+1}='V';
            VarAttribute{nbvar+1}.Role='scalar';
        case 'norm(U,V)'
            VarVal{nbvar+1}=sqrt(F_u(XI,YI).*F_u(XI,YI)+F_v(XI,YI).*F_v(XI,YI));
            ListVarName{nbvar+1}='norm(U,V)';
            VarAttribute{nbvar+1}.Role='scalar';
    end
end
nbvar=numel(ListVarName);
ListVarName{nbvar+1}='FF';
VarVal{nbvar+1}=isnan(VarVal{nbvar});
VarAttribute{nbvar+1}.Role='errorflag';

% Attr_FF.Role='errorflag';
% VarAttribute=[VarAttribute {Attr_FF}];





