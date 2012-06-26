%'read_multimadoc': read a set of Imadoc files and compare their timing of different file series
%------------------------------------------------------------------------
% [XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series)
%
% OUTPUT:
% 
%
% INPUT:
% 
function [XmlData,NbSlice_calib,time,errormsg]=read_multimadoc(RootPath,SubDir,RootFile,FileExt,i1_series,i2_series,j1_series,j2_series)
errormsg='';
nbview=numel(RootPath);
XmlData=cell(1,nbview);%initiate the structures containing the data from the xml file (calibration and timing)
NbSlice_calib=cell(1,nbview);
timecell=cell(1,nbview);
for iview=1:nbview%Loop on views
    XmlFileName=find_imadoc(RootPath{iview},SubDir{iview},RootFile{iview},FileExt{iview});
    if ~isempty(XmlFileName)
        [XmlData{iview},errormsg]=imadoc2struct(XmlFileName);% read the ImaDoc xml file
        if ~isempty(errormsg)
            return
        end
    end
    if isfield(XmlData{iview},'Time')
        timecell{iview}=XmlData{iview}.Time;
    end
    if isfield(XmlData{iview},'GeometryCalib') && isfield(XmlData{iview}.GeometryCalib,'SliceCoord')
        NbSlice_calib{iview}=size(XmlData{iview}.GeometryCalib.SliceCoord,1);%nbre of slices for Zindex in phys transform
        if ~isequal(NbSlice_calib{iview},NbSlice_calib{1})
            msgbox_uvmat('WARNING','inconsistent number of Z indices for the two field series');
        end
    end
end

%% check coincidence in time for several input file series
if isempty(timecell)
    time=[];
else
    time=get_time(timecell{1},i1_series{1},i2_series{1},j1_series{1},j2_series{1});
end
if nbview>1
    time=shiftdim(time,-1); % add a singleton dimension for nbview
    for icell=2:nbview
        if isequal(size(timecell{icell}),size(timecell{1}))
            time_line=get_time(timecell{icell},i1_series{icell},i2_series{icell},j1_series{icell},j2_series{icell});
            time=cat(1,time,shiftdim(time_line,-1));
        else
            msgbox_uvmat('WARNING','inconsistent time array dimensions in ImaDoc fields, the time for the first series is used')
            time=cat(1,time,time(icell-1,:,:));
            break
        end
    end
end

function time=get_time(timeimadoc,i1_series,i2_series,j1_series,j2_series)
if size(timeimadoc,1) < i2_series(end) ||( ~isempty(j2_series) && size(timeimadoc,2) < j2_series(end))% time array absent or too short in ImaDoc xml file'
    time=[];
else
    timevect=timeimadoc';
    if ~isempty(j1_series)
        vect_index=reshape(j1_series+(i1_series-1)*size(timevect,1),1,[]);
        time=timevect(vect_index);
        if ~isempty(j2_series)
            vect_index=reshape(j2_series+(i1_series-1)*size(timevect,1),1,[]);
            time=(time+timevect(vect_index))/2;
        end
    else
        time=timevect(i1_series);
        if ~isempty(i2_series)
            time=(time+timevect(i2_series))/2;
        end
    end
end
