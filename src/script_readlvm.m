%% get the input file
project='/fsnet/project/coriolis/2024/24PLUME';
fileinput=uigetfile_uvmat('pick an input file',project);
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

%% save netcdf file as .lvm
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

%% use calibration stored in a specified xml file; always use the same file
ProbeDoc=[]; 
%XmlFile=fullfile(Path,[Name '.xml']);
XmlFile=fullfile(Path,'calib.xml');  
if exist(XmlFile,'file')
    ProbeDoc=xml2struct(XmlFile)
else
    disp('no calibration file .xml detected')
end

% if isfield(Data,'Position'), C2,C4,C6
%     Min=1; Data.Position=Data.Position+PositionMin;
% end
% a5=-2.134088,b5=1010.1611, Data.C2=Data.C2; Data.C5=a5*Data.C5+b5; Data.C6=Data.C2;
% ylabelstring='density drho (kg/m3)';


%% transform temperature probe signals 
if isfield(ProbeDoc,'T5')&& ~isempty(ProbeDoc.T5)  % if temperature calibration exists; see calibT.m
    
    Data.T5=exp((Data.T5 - ProbeDoc.T5.a)./ProbeDoc.T5.b);% transform volt signal into temperature 
    Data.T5=filter(ones(1,60)/60,1,Data.T5); % filter the signal to 4 Hz 
    figure(6); set(6,'name','temperature'); plot(Data.Time,Data.T5);
    %plot(Data.Time,Data.T5,Data.Time,20+Data.Position/100)
    title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', temperature'])
    xlabel('Time(s)'); ylabel('temperature (degree C)'); %ylim([20 37])
    grid on
end

%% check camera signal
ind_start=find(Data.Trig_cam>3.5,1,'first')
disp(['camera starts at time ' num2str(Data.Time(ind_start))])
%% transform and filter conductivity probe signals into [temperature-corrected] density
ylabelstring='conductivity signal (volts)'; clist=0;% counter of conductivity probes
for ilist=1:numel(Data.ListVarName)
    if isequal(Data.ListVarName{ilist}(1),'C');% if the var name begins by 'C'
        clist=clist+1;
        CName{clist}=Data.ListVarName{ilist};
        if isfield(ProbeDoc,CName{clist})&& ~isempty(ProbeDoc.(CName{clist}))
        
            a=ProbeDoc.(CName{clist}).a; b=ProbeDoc.(CName{clist}).b;
            % Data.(CName{clist})=a*Data.(CName{clist})+b;% volts STRAIGHT into density (if const T)
            
            %% BUT now need to modify conductivity, density due to temperature effect
            %% first put into conductivity - using just C5 conductivity calibration for now (22/7/15)
            ac1 = 0.5766e4; bc1 = 2.9129e4; %% this was found later, w/ different gain. Use the one below instead
            %% ac1 = 0.4845e4; bc1 = 2.064e4; %% this was w/ the gain when we did the experiments; but it doesn't work?
            Data.(CName{clist})=ac1*Data.(CName{clist})+bc1; %% voltage translated into conductivity via calibration
             
            %% read in temperature... 
            refT = 23; T = Data.T5;
            Hewitt_fit = [2.2794885e-11 -6.2634979e-9 1.5439826e-7 7.8601061e-5 2.1179818e-2]; 
            bfit = reshape(polyval(Hewitt_fit,T(:)),size(T)); bref = reshape(polyval(Hewitt_fit,refT(:)),size(refT));
            sigTsig18 = (1+bfit.*(T-18)); sigREFsig18 = (1+bref.*(refT-18)); 
            modfactor = sigTsig18./sigREFsig18;
            modfactor = 1./modfactor;  %% now in sigREF/sigT, which (* sigT) below to get sigREF, which can convert to rho
            Data.(CName{clist})=Data.(CName{clist}).*modfactor %% = temp corrected conductivity (= as if at reference temp)
            
            %% now we need to put the modified conductivity back into a (modified) voltage, then estimate density directly. 
            ac2 = 1.7343e-4; bc2 = -5.0048;
            Data.(CName{clist})=ac2*Data.(CName{clist})+bc2; % temp-corrected voltage
            Data.(CName{clist})=a*Data.(CName{clist})+b; % now finally voltage into density
            Data.(CName{clist})=filter(ones(1,20)/20,1,Data.(CName{clist})); % filter the signal to 10 Hz
            ylabelstring='density drho (g/cm3)';
                  
        end
    end
end

%% plot conductivity signals
figure(1); set(1,'name','conductivity')
bandwidth2=60; % corresponds to 0.25 cm (1 cm/s with 240 pts/s), removes 4 Hertz
plot_string='plot(';
for clist=1:numel(CName)
    Data.(CName{clist})=filter(ones(1,bandwidth2)/bandwidth2,1,Data.(CName{clist}));%low pass filter
    plot_string=[plot_string 'Data.Time,Data.' CName{clist} ','];
end
plot_string(end)=')';
eval(plot_string)
legend(CName')
htitle=title([Data.Experiment ', '  Data.FileName ', Time=' Data.DateTime ', conductivity probes']);
set(htitle,'Interpreter','none')% desable tex interpreter
xlabel('Time(s)')
ylabel(ylabelstring)
        ylim([1 1.02])
grid on

if isfield(Data,'Position')
    %% plot motor position
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
        ylim([1 1.02])
        grid on
    end
        
end

%%%%
figure(4)
bandwidth1=480; % corresponds to 2 cm (1 cm/s with 240 pts/s)
bandwidth2=60; % corresponds to 0.25 cm (1 cm/s with 240 pts/s), removes 4 Hertz
C5_filter_low=filter(ones(1,bandwidth2)/bandwidth2,1,Data.C5);%low pass filter
C5_filter=filter(ones(1,bandwidth1)/bandwidth1,1,C5_filter_low);%low pass filter
C5_filter=C5_filter_low-C5_filter;% high pass filter
C5_filter(Data.Speed>-0.1)=NaN;
plot(Data.Time,C5_filter)
ylim([-0.001 0.001])
hold on
plot(Data.Time,Data.Position/100000)
grid on
hold off
title('C5 filtered')

%%%%
figure(5)
bandwidth1=480; % corresponds to 2 cm (1 cm/s with 240 pts/s)
bandwidth2=60; % corresponds to 0.25 cm (1 cm/s with 240 pts/s), removes 4 Hertz
C3_filter_low=filter(ones(1,bandwidth2)/bandwidth2,1,Data.C3);%low pass filter
C3_filter=filter(ones(1,bandwidth1)/bandwidth1,1,C3_filter_low);%low pass filter
C3_filter=C3_filter_low-C3_filter;% high pass filter
C3_filter(Data.Speed>-0.1)=NaN;
plot(Data.Time,C3_filter)
ylim([-0.001 0.001])
hold on
plot(Data.Time,Data.Position/100000)
grid on
hold off
title('C3 filtered')

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



