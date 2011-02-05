%'update_imadoc': update an xml file with geometric calibration parameters
%--------------------------------------------------------------------------
%  function update_imadoc(GeometryCalib,outputfile)
%
%INPUT:
% GeometryCalib: structure containing the calibration parameters
% outputfile: xml file to modify
%-------------------------------------------------------------
function errormsg=update_imadoc(GeometryCalib,outputfile)
errormsg='';
testappend=0;
if exist(outputfile,'file');%=1 if the output file already exists, 0 else  
    testappend=1;
    t=xmltree(outputfile); %read the file
    backupfile=outputfile;
    testexist=2;
    while testexist==2
       backupfile=[backupfile '~'];
       testexist=exist(backupfile,'file');
    end
    [success,message]=copyfile(outputfile,backupfile);%make backup
    if success==0
        errormsg=message;
    end
    uid=find(t,'ImaDoc');
    if ~isequal(uid,1)
        return
    end       
    %if the xml file is  ImaDoc
    uid_calib=find(t,'ImaDoc/GeometryCalib');
    if isempty(uid_calib)  %if GeometryCalib does not already exists, create it
        [t,uid_calib]=add(t,1,'element','GeometryCalib');
    else %if GeometryCalib already exists, delete its content
        if isequal(success,1)
            delete(outputfile)
        else
            return
        end
        uid_child=children(t,uid_calib);
        t=delete(t,uid_child);
    end
end
%create a new xml file
if ~testappend
    t=xmltree;
    t=set(t,1,'name','ImaDoc');
    % in case of movie (avi file), copy timing info in the new xml file
    [pp,outputroot]=fileparts(outputfile);
    info=[];
    if exist(fullfile(pp,[outputroot '.avi']),'file')
        info=aviinfo(fullfile(pp,[outputroot '.avi']));
    elseif exist(fullfile(pp,[outputroot '.AVI']),'file')
        info=fullfile(pp,[outputroot '.AVI']);
    end 
    if ~isempty(info)
        [t,uid_camera]=add(t,1,'element','Camera');
        Camera.TimeUnit='s';
        Camera.BurstTiming.Time=0;
        Camera.BurstTiming.Dti=1/info.FramesPerSecond;
        Camera.BurstTiming.NbDti=info.NumFrames-1;
        t=struct2xml(Camera,t,uid_camera);
    end
   [t,uid_calib]=add(t,1,'element','GeometryCalib');
end
'TESTupdate'
GeometryCalib
t=struct2xml(GeometryCalib,t,uid_calib); 
save(t,outputfile);
