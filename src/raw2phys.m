%'raw2phys': transform raw signal to physical values using different calibrations laws
%
function FieldPhys=raw2phys(Field)

% do not transform if Field already in phys coordinates
FieldPhys=Field;%default
if isfield(Field,'CoordType') & isequal(Field.CoordType,'phys')
    return %no transform if the data are already physical
else
    FieldPhys.CoordType='phys';
end

%Filtering of the initial data
nbfilter=51;
nbhalf=floor(nbfilter/2);
for ivar=1:length(FieldPhys.ListVarName)
    VarName=FieldPhys.ListVarName{ivar};
    if ~isequal(VarName,'time')
        eval(['FirstVal=FieldPhys.' VarName '(1);'])
        eval(['LastVal=FieldPhys.' VarName '(end);'])
        FirstVal=ones(nbhalf,1)*FirstVal;
        LastVal=ones(nbhalf,1)*LastVal;    
        eval(['FieldPhys.' VarName '=[FirstVal;FieldPhys.' VarName ';LastVal];'])
        eval(['FieldPhys.' VarName '=conv(ones(1,nbfilter)/nbfilter,FieldPhys.' VarName ');']);
         eval(['FieldPhys.' VarName '([1:nbfilter-1])=[];']);
         eval(['FieldPhys.' VarName '([end-nbfilter+2:end])=[];']);
    end
end



ScanRate=240; %data points per second
VelTranslation=1; % 1 cm/s A VERIFIER
test_Offset=0;
test_Thermistance_B=0;
test_Thermistance_M=0;
if isfield(Field,'ListVarAttribute')
    for ilist=1:length(Field.ListVarAttribute)
        attr_name=Field.ListVarAttribute{ilist}
        if isequal(attr_name,'PhysUnits')
            FieldPhys.units =Field.PhysUnits;
        end
        if isequal(attr_name,'Offset')
            test_Offset=1;
        end
        if isequal(attr_name,'ThermistanceCalib_B')
            test_Thermistance_B=1;
        end  
        if isequal(attr_name,'ThermistanceCalib_M')
            test_Thermistance_M=1;
        end
    end
end



% substract offset
if test_Offset
    for ivar=1:length(Field.ListVarName)
        Val_Offset=Field.Offset{ivar};
        if isnumeric(Val_Offset)&~isempty(Val_Offset)
            VarName=Field.ListVarName{ivar};
            eval(['FieldPhys.' VarName '=FieldPhys.' VarName '-Val_Offset;'])
        end
    end
end

%thermistance calibration
if test_Thermistance_M & test_Thermistance_B
    for ivar=1:length(Field.ListVarName)
        Val_B=Field.ThermistanceCalib_B{ivar};
        Val_M=Field.ThermistanceCalib_M{ivar};
        if isnumeric(Val_B) & ~isempty(Val_B) & isnumeric(Val_M) & ~isempty(Val_M)
            VarName=Field.ListVarName{ivar};
            eval(['FieldPhys.' VarName '=(Val_M ./ (log( FieldPhys.' VarName ')-Val_B)) -273.15;'])
        end
    end
end
return

%NON USED
%density profile
Density=(Conductivity-B)/A;%calibration
Density=Density(find(Motor>1));%restrict the record to the time motor on
Density=flipdim(Density,2)';
%detect free surface
[dmax,imax]=max(diff(Density));
nbpoints=length(Density);
Pos=linspace(0,nbpoints*VelTranslation/ScanRate,nbpoints);
Pos=Pos-imax*VelTranslation/ScanRate;

%[dmax,jmax]=max(diff(Conductivity))
napoints=length(Conductivity);
Pos1=linspace(0,napoints*VelTranslation/ScanRate,napoints);
%Pos1=Pos1-jmax*VelTranslation/ScanRate;

figure(2);
clf
plot(Pos1,Conductivity)
grid on
figure(3);
size(Pos)
size(Density)
plot(Pos,Density)
hold on
grid on
%determination of N
PosCentr=Pos([floor(nbpoints/4):floor(3*nbpoints/4)]);
DensityCentr=Density([floor(nbpoints/4):floor(3*nbpoints/4)]);
p=polyfit(PosCentr,DensityCentr,1);
LinDens=polyval(p,PosCentr);
plot(PosCentr,LinDens,'r')
grad=p(1)
%find(Motor>1)

% data.conductivity=flipdim(Conductivity(find(Motor>5)),1)';
% data.deplacement=[100/size(data.conductivity,2):100/size(data.conductivity,2):100];
% 
% figure;plot(data.deplacement,data.conductivity);hold on;

%data.density=flipdim(Conductivity(find(Motor>1)),1)'*3.4764+15.1367;
%data.density=flipdim(Conductivity(find(Motor>1)),2)'*5+14.6090;
%data.density=flipdim(Conductivity(find(Motor>1)),2)'*4.1525+19.50;
% data.density=flipdim(Conductivity(find(Motor>1)),2)'
% data.deplacement=[92/size(data.density,2):92/size(data.density,2):92];
% figure(101)
% plot(data.deplacement,data.density);hold on;

% t=data.deplacement(find(data.deplacement>20&data.deplacement<80));
%t=data.deplacement(find(data.deplacement>0&data.deplacement<90));
% X=[ones(size(t,2),1)';t];
% Y=data.density(find(data.deplacement>20&data.deplacement<80));
% %Y=data.density(find(data.deplacement>0&data.deplacement<90));
% coeff=Y/X;

% plot(data.deplacement,data.deplacement*coeff(2)+coeff(1),'r');

% grad=abs(coeff(2)*100)
Tbv=2*pi/sqrt(981*0.001*grad)
N=2*pi/Tbv
title(strcat('',name,''))
xpos=get(gca,'XLim')
ypos=get(gca,'YLim')
%xtext=xpos(1)+(xpos(2)-xpos(1))*3/4
xtext=xpos(1)+(xpos(2)-xpos(1))/2
ytext=ypos(1)+(ypos(2)-ypos(1))/4
TabText={strcat('Tbv : ',num2str(Tbv),'s'); strcat('Stratification : ',num2str(grad)); strcat('N : ',num2str(2*pi/Tbv),'rad.s-1')}
text(xtext,ytext,TabText)
% text(xtext,13,strcat('Tbv : ',num2str(Tbv),'s'));
% text(55,10,strcat('Stratification : ',num2str(grad)));
% text(55,16,strcat('N : ',num2str(2*pi/Tbv),'rad.s-1'));
