%'update_imadoc': update an xml file with geometric calibration parameters
%--------------------------------------------------------------------------
%  function update_imadoc(GeometryCalib,outputfile)
%
%INPUT:
% GeometryCalib: structure containing the calibration parameters
% outputfile: xml file to modify
%-------------------------------------------------------------
function update_imadoc(GeometryCalib,outputfile)
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
if ~testappend
    t=xmltree;
    t=set(t,1,'name','ImaDoc');
    [t,uid_calib]=add(t,1,'element','GeometryCalib');
end
t=struct2xml(GeometryCalib,t,uid_calib); 
save(t,outputfile);
