function TimeMatrix=xmlburst2time(BurstTiming,FirstFrameIndexI)
if ~exist('FirstFrameIndexI','var')
    FirstFrameIndexI=1;
end
if ~iscell(BurstTiming)
    BurstTiming={BurstTiming};
end
TimeMatrix=[];
for k=1:length(BurstTiming)
    Frequency=1;
    if isfield(BurstTiming{k},'FrameFrequency')
        Frequency=BurstTiming{k}.FrameFrequency;
    end
    if ~isfield(BurstTiming{k},'Time')
        BurstTiming{k}.Time=0;%time origin set to zero by default
    end
    Dtj=[];
    if isfield(BurstTiming{k},'Dtj')
        Dtj=BurstTiming{k}.Dtj/Frequency;%Dtj converted from frame unit to TimeUnit (e.g. 's');
    end
    NbDtj=1;
    if isfield(BurstTiming{k},'NbDtj')&&~isempty(BurstTiming{k}.NbDtj)
        NbDtj=BurstTiming{k}.NbDtj;
    end
    Dti=[];
    if isfield(BurstTiming{k},'Dti')
        Dti=BurstTiming{k}.Dti/Frequency;%Dti converted from frame unit to TimeUnit (e.g. 's');
    end
    NbDti=1;
    if isfield(BurstTiming{k},'NbDti')&&~isempty(BurstTiming{k}.NbDti)
        NbDti=BurstTiming{k}.NbDti;
    end
    Time_val=BurstTiming{k}.Time;%time in TimeUnit
    if ~isempty(Dti)
        Dti=reshape(Dti'*ones(1,NbDti),NbDti*numel(Dti),1); %concatene Dti vector NbDti times
        Time_val=[Time_val;Time_val(end)+cumsum(Dti)];%append the times defined by the intervals  Dti
    end
    if ~isempty(Dtj)
        Dtj=reshape(Dtj'*ones(1,NbDtj),1,NbDtj*numel(Dtj)); %concatene Dtj vector NbDtj times
        Dtj=[0 Dtj];
        Time_val=Time_val*ones(1,numel(Dtj))+ones(numel(Time_val),1)*cumsum(Dtj);% produce a time matrix with Dtj
    end
    % reading Dtk
    Dtk=[];%default
    NbDtk=1;%default
    if isfield(BurstTiming{k},'Dtk')
        Dtk=BurstTiming{k}.Dtk;
    end
    if isfield(BurstTiming{k},'NbDtk')&&~isempty(BurstTiming{k}.NbDtk)
        NbDtk=BurstTiming{k}.NbDtk;
    end
    if isempty(Dtk)
        TimeMatrix=[TimeMatrix;Time_val];
    else
        for kblock=1:NbDtk+1
            Time_val_k=Time_val+(kblock-1)*Dtk;
            TimeMatrix=[TimeMatrix;Time_val_k];
        end
    end
end
TimeMatrix=[zeros(size(TimeMatrix,1),1) TimeMatrix]; %insert a vertical line of zeros (to deal with zero file indices)
if FirstFrameIndexI~=0
    TimeMatrix=[zeros(FirstFrameIndexI,size(TimeMatrix,2)); TimeMatrix]; %insert a horizontal line of zeros
end
TimeMatrix=TimeMatrix';