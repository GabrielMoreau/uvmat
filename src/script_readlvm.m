%% get the input file
fileinput=uigetfile_uvmat('pick an input file','/fsnet/project/coriolis/2016/16MILESTONE/Data');
[Path,Name,Ext]=fileparts(fileinput);

%% read the input file
FileType='';
if strcmp(Ext,'.lvm')
    disp(['reading ' fileinput '...'])
Data=read_lvm(fileinput)
elseif strcmp(Ext,'.nc')
    disp(['reading ' fileinput '...'])
    Data=nc2struct(fileinput) 
else
    disp('invalid input file extension')
end

%% save as netcdf file if it has been opened as .lvm
if strcmp(Ext,'.lvm')
    OutputFile=fullfile(Path,[Name '.nc']);
    errormsg=struct2nc(OutputFile,Data);% copy the data in a netcdf file
    if isempty(errormsg)
        disp([OutputFile ' written'])
    else
        disp(errormsg)
    end
    [success,msg] = fileattrib(OutputFile,'+w','g')% allow writing access for the group of users
end

%% use calibration data stored in an xml file
ProbeDoc=[];
XmlFile=fullfile(Path,[Name '.xml']);
if exist(XmlFile,'file')
    ProbeDoc=xml2struct(XmlFile);
end
% if isfield(Data,'Position'), C2,C4,C6
%     Min=1;
%     Data.Position=Data.Position+PositionMin;
% end
% a5=-2.134088,b5=1010.1611,
% Data.C2=Data.C2;
% Data.C5=a5*Data.C5+b5;
% Data.C6=Data.C2;
% ylabelstring='density drho (kg/m3)';

%% treqnsform conductivity probe signals: calibration + filter at 10 Hz
ylabelstring='conductivity signal (volts)';
clist=0;% counter of conductivity probes
for ilist=1:numel(Data.ListVarName)
    if isequal(Data.ListVarName{ilist}(1),'C');% if the var name begins by 'C'
        clist=clist+1;
        CName{clist}=Data.ListVarName{ilist};
        if isfield(ProbeDoc,CName{clist})&& ~isempty(ProbeDoc.(CName{clist}))
            a=ProbeDoc.(CName{clist}).a;
            b=ProbeDoc.(CName{clist}).b;
            Data.(CName{clist})=a*Data.(CName{clist})+b;% transform volt signal into density
            Data.(CName{clist})=filter(ones(1,20)/20,1,Data.(CName{clist})); % filter the signal to 10 Hz
            ylabelstring='density drho (g/cm3)';
        end
    end
end

%% plot conductivity probe signals
figure(1)
set(1,'name','conductivity')
plot_string='plot(';
for clist=1:numel(CName)
    plot_string=[plot_string 'Data.Time,Data.' CName{clist} ','];
end
plot_string(end)=')';
eval(plot_string)
legend(CName')
htitle=title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', conductivity probes']);
set(htitle,'Interpreter','none')% desable tex interpreter
xlabel('Time(s)')
ylabel(ylabelstring)
grid on

if isfield(Data,'Position')
    %% plot  motor position
    figure(2)
    set(2,'name','position')
    plot(Data.Time,Data.Position)
    htitle=title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', probe position ']);
    set(htitle,'Interpreter','none')% desable tex interpreter
    xlabel('Time(s)')
    ylabel('Z (cm)')
    grid on
    hold on
    plot(Data.Time,Data.Speed)
    
    %%plot first profile
    figure(4)
    index1=find(Data.Speed<0,1); %start of descent
    Speed=Data.Speed(index1:end);
    index2=index1-1+find(Speed>0,1); %end of descent
    plot(Data.Position(index1:index2),Data.C1(index1:index2))
    
    %% plot conductivity probe profiles (limited to downward motion, Data.Speed<0)
    if ~isempty(ProbeDoc)
        figure(3)
        set(3,'name','profiles')
        Zmotor=Data.Position(Data.Speed<0);
        Z=Zmotor*ones(1,numel(CName));%motor position transformed in a matrix with a columnfor each probe
        Zmax=max(Zmotor);
        plot_string='plot(';
        for clist=1:numel(CName)
            if isfield(ProbeDoc,CName{clist})&& ~isempty(ProbeDoc.(CName{clist})) && size(ProbeDoc.(CName{clist}).Position,2)>=2 % if at least two positions are defined to indicate that the probe moves
               Zprobe=Zmotor-Zmax+ProbeDoc.(CName{clist}).Position(2,3);%upper position of the probe
               Zprobe(Zprobe<ProbeDoc.(CName{clist}).Position(1,3))=ProbeDoc.(CName{clist}).Position(1,3);
                Z(:,clist)=Zprobe;% add to z the first z position of the chosen probe (given in the xml file)
                plot_string=[plot_string 'Z(:,' num2str(clist) '),Data.' CName{clist} '(Data.Speed<0),'];
            end
        end
        plot_string(end)=')';
        eval(plot_string)
        legend(CName')
        htitle=title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', conductivity probes']);
        set(htitle,'Interpreter','none')% desable tex interpreter
        xlabel('Z(cm)')
        ylabel(ylabelstring)
        grid on
    end
    %     plot(Z,Data.C2(Data.Speed<0),Z,Data.C3(Data.Speed<0),Z,Data.C4(Data.Speed<0),Z,Data.C5(Data.Speed<0))
    %     legend({'C2';'C3';'C4';'C5'})
    %     title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', profiles conductivity probes'])
    %     xlabel('Z(cm)')
    %     %ylabel('signal (Volt)')
    %     ylabel(ylabelstring)
    %     grid on
    
    
    %     set(3,'name','profiles')
    %     PositionMin=1; %position of probes at the bottom (Z=1 cm)
    %     Data.Position=Data.Position-min(Data.Position)+PositionMin;
    %     Z=Data.Position(Data.Speed<0);
    %     plot(Z,Data.C2(Data.Speed<0),Z,Data.C5(Data.Speed<0),Z,Data.C6(Data.Speed<0))
    %     legend({'C2';'C5';'C6'})
    %     title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', profiles conductivity probes'])
    %     xlabel('Z(cm)')
    %     %ylabel('signal (Volt)')
    %     ylabel(ylabelstring)
    %     grid on
    
end




%% plot temperature signals
% figure(4)
% set(4,'name','temperature')
% plot(Data.Time,Data.T2,Data.Time,Data.T5,Data.Time,Data.T6)
% legend({'T2';'T5';'T6'})
% title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', signal conductivity probes'])
% xlabel('Time(s)')
% ylabel('signal (Volt)')
% grid on

%% plot velocity (ADV) signals
% figure(5)
% set(5,'name','velocity')
% plot(Data.Time,Data.ADV_X,Data.Time,Data.ADV_Y,Data.Time,Data.ADV_Z1,Data.Time,Data.ADV_Z2)
% legend({'ADV_X';'ADV_Y';'ADV_Z1';'ADV_Z2'})
% title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', signal velocity'])
% xlabel('Time(s)')
% ylabel('signal (Volt)')
% grid on

%% plot velocity interface signals
% figure(6)
% set(6,'name','interface')
% plot(Data.Time,Data.I1,Data.Time,Data.I2,Data.Time,Data.I3,Data.Time,Data.I4)
% legend({'I1';'I2';'I3';'I4'})
% title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', signal interface (ultrasound)'])
% xlabel('Time(s)')
% ylabel('signal (Volt)')
% grid on


