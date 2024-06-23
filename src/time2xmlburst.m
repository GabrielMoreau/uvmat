function BurstTiming=time2xmlburst(timestamps,BurstSize)

if BurstSize==1 % simple series
    BurstTiming.Dti=(timestamps(end)-timestamps(1))/(numel(timestamps)-1);
    BurstTiming.NbDti=(numel(timestamps)-1);
else
    timestamps=reshape(timestamps,BurstSize,[]);
    DtBurst=diff(timestamps,1,1);
    dtj=round(1000*mean(DtBurst,2));% dt in integer number rounded to ms
    Dtmin=min(dtj);
    Dtmax=max(dtj);
    if Dtmax==Dtmin
        BurstTiming.Dtj=Dtmin/1000;% simple series
        BurstTiming.NbDtj=size(timestamps,1)-1;
    else
        BurstTiming.Dtj=dtj/1000;%burst mode
        BurstTiming.NbDtj=1;
    end
    DtSeries=diff(timestamps,1,2);
    dti=mean(DtSeries,1);% dt in integer number rounded to ms
    Dtmin=round(1000*mean(dti(1:2:end)));
    Dtmax=round(1000*mean(dti(2:2:end)));
    if Dtmax==Dtmin
        BurstTiming.Dti=Dtmin/1000;% simple burst series
        BurstTiming.NbDti=size(timestamps,2)-1;
    else
        BurstTiming.Dti=Dtmin/1000;%burst mode
        BurstTiming.NbDti=1;
        BurstTiming.Dtk=(Dtmin+Dtmax)/1000;%burst mode
        BurstTiming.NbDtk=size(timestamps,2)/2-1;
    end
end

