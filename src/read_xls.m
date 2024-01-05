%'read_xls': function for reading and displaying Excel files  
%------------------------------------------------------------------------
% function [hfig_xls]=read_xls(fileinput,hfig)
% 
% OUTPUT:
%  hfig_xls: figure handle for display
%
% INPUT:
% fileinput: name of the input file (char string)
% hfig: handle of the display figure (a new display figure hfig_xls is created if hfig undefined)

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.frread_xls.m
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function [hfig_xls]=read_xls(fileinput,hfig)
[Tabnum,Tabtext]=xlsread(fileinput);
    [textnx,textny]=size(Tabtext);
    [numnx,numny]=size(Tabnum);
    ilastxt=textnx-numnx;%index of last text row
    jlastxt=textny-numny;%index of last text column
    for jtab=1:textny%read line
        for itab=1:textnx% read column
            textlu=cell2mat(Tabtext(itab,jtab));
            if isequal(textlu,[])& itab > ilastxt & jtab > jlastxt %replace txt by number
                textlu=num2str(Tabnum(itab-ilastxt,jtab-jlastxt));
            end
            Tabdisplay(itab,jtab)={textlu};
            lengthtext(itab)=length(textlu);
        end
        widthcolumn(jtab)=max(lengthtext);
    end
    Tabchar={};%default
    for itab=1:textnx    %justify table
        charchain=[];         
        for jtab=1:textny% read line
            textlu=Tabdisplay{itab,jtab};
            if widthcolumn(jtab)>length(textlu)
                blankstr=char(46*ones(1,widthcolumn(jtab)-length(textlu)));
                textlu=[textlu blankstr ];
            end
            charchain=[charchain textlu char(9) ' | '];
        end
        Tabchar(itab)={charchain};
    end 
    if exist('hfig','var') & ishandle(hfig)
        figure(hfig);
        hfig_xls=hfig;
    else
        hfig_xls=figure;
    end
    set(hfig_xls,'Name',fileinput)
    set(hfig_xls,'MenuBar','none')
    hpos=get(hfig_xls,'Pos');
    ExpName.cell=Tabtext([2:textnx],1);%first column (dir name)
    ExpName.Num=Tabnum;
%     ExpName.Units=Tabtext(2,[2:textny]);%look for the units line (needs to be the second line)
    iparam=0;
    for icol=2:textny
%         Tabtext(2,icol)
        if ~isempty(Tabtext{2,icol})&~isequal(Tabtext{2,icol},'')
            iparam=iparam+1;
            ExpName.Param{iparam}=Tabtext{1,icol};
            ExpName.Units{iparam}=Tabtext{2,icol};
            ExpName.Column(iparam)=icol;
        end
    end
 
    ExpName.path=fileparts(fileinput);
    h=uicontrol('Style','listbox', 'Position', [5 5 0.9*hpos(3) 0.9*hpos(4)], 'String', Tabchar, ...
        'FontName','Monospaced','Callback',@link2file,'UserData',ExpName,'Tag','listbox');  
%     hh=uicontrol('Style','Pushbutton', 'Position', [0.93*hpos(1) 0.93*hpos(2) 0.05*hpos(3) 0.05*hpos(4)], 'String', 'Update','Callback',@project_update);
%      set(h,'HorizontalAlignment','left')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%called by xlsdisplay to navigate from  a .xls file or create the
% the experiment directories
function link2file(obj,event,fileinput)
global t
bla=get(gcbo,'String');
ind=get(gcbo,'Value')
if (ind==1|ind==2),return,end; %no action on the first line
ExpNameStruct=get(gcbo,'UserData')
ExpName=ExpNameStruct.cell{ind-1}
ProjectFullName=ExpNameStruct.path;%full name of the project (including path)
[Pth,ProjectName]=fileparts(ProjectFullName);
ExpPath=fullfile(ProjectFullName,ExpName);% full name of the experiment directory
ExpDocName=fullfile(ExpPath,[ExpName '.xml']);% full name of the .xml file ExpDoc
if exist(ExpDocName,'file')
    hh=editxml({ExpDocName});   
else
    answer=questdlg({['ExpDoc file ' ExpDocName ' does not exist, create the experiment?'];''})
    if isequal(answer,'Yes')
        if exist(ExpPath,'dir')~=7 %create a directory if it does not exist
            dircur=pwd; %current working directory
            cd(ProjectFullName);
            [m1,m2,m3]=mkdir(ExpName);
            cd(pwd);%come back to the initial working dir
        end
%         %copy exp parameters
        ParamNames=ExpNameStruct.Param;
        ParamValues=ExpNameStruct.Num(ind-1,ExpNameStruct.Column-1);
        ParamUnits=ExpNameStruct.Units;
        t=xmltree;%new xmltree
        t=set(t,1,'name','ExpDoc');
        t=attributes(t,'add',1,'xmlns:xsi','none');
        [t,ExpElement]=add(t,1,'element','Exp');
        [t]=add(t,ExpElement,'chardata',ExpName);
        for iparam=1:length(ParamNames)
            [t,ParamElement]=add(t,1,'element',ParamNames{iparam});
            t=add(t,ParamElement,'chardata',num2str(ParamValues(iparam)));
            t=attributes(t,'add',ParamElement,'unit',ParamUnits{iparam}); %ADD UNIT ATTRIBUTE
        end
        list_dir=dir(ExpPath);%list of the Exp directory,  detect sub-directories,.xml and image files
        nbdir_exp=0;
        %scan the Exp directory
        for idir_exp=3:length(list_dir)
            %detect subdirectories  
            if list_dir(idir_exp).isdir% 'device' subdirectories
                nbdir_exp=nbdir_exp+1;
                ExpData.Device{nbdir_exp}=list_dir(idir_exp).name;
                [t,DeviceElement]=add(t,1,'element',list_dir(idir_exp).name);
                t=attributes(t,'add',DeviceElement,'type','DEVICE_DIR');
                t=attributes(t,'add',DeviceElement,'source','dir');
                list_subdir=dir(fullfile(ExpPath,list_dir(idir_exp).name));
                nbsubdir=0;
                testrecord=1;
                RootIma='';
                RootNc='';
                nbfile=0;
%                 nbfile={};
                %scan the Device subdirectory
                for isubdir=3:length(list_subdir)
                    if list_subdir(isubdir).isdir
                        nbsubdir=nbsubdir+1;
                        Device.Record{nbsubdir}=list_subdir(isubdir).name;
                    else
                        nbfile=nbfile+1;
                        fname{nbfile}=list_subdir(isubdir).name;
                    end
                end
                if isunix%sort by root names and indices , change the separator '_' so that 1_1 come as the first name
                    fname_mod=regexprep(fname,'_','/');
                    fname_mod=sort(fname_mod);     %sort by name
                    fname=regexprep(fname_mod,'/','_');
                end
                for ifile=1:nbfile;
                    [Path,Name,Ext]=fileparts(fname{ifile});
                    if isequal(Ext,'.xml')
                       [t,ImaDocElement]=add(t,DeviceElement,'element','ImaDoc');
                       t=add(t,ImaDocElement,'chardata',fname{ifile});
                       t=attributes(t,'add',ImaDocElement,'source','file');
                       testrecord=0;%we have an image series without 'record' subdir
                    elseif isequal(Ext,'.png')
                       %[Path,Root,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fname{ifile});
                       [~,~,Root]=fileparts_uvmat(fname{ifile});
                       if ~isequal(Root,RootIma)%only one image recorded for each root name
                           [t,ImaDocElement]=add(t,DeviceElement,'element','Image');
                           t=add(t,ImaDocElement,'chardata',fname{ifile});
                           t=attributes(t,'add',ImaDocElement,'source','file');
                           RootIma=Root;
                       end
                       testrecord=0;%we have an image series without 'record' subdir
                    elseif isequal(Ext,'.nc')
                       %[Path,Root,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fname{ifile});
                       [~,~,Root]=fileparts_uvmat(fname{ifile});
                       if ~isequal(Root,RootNc)%only one image recorded for each root name
                           [t,ImaDocElement]=add(t,DeviceElement,'element','Ncdata');
                           t=add(t,ImaDocElement,'chardata',fname{ifile});
                           t=attributes(t,'add',ImaDocElement,'source','file');
                           RootNc=Root;
                       end
                       testrecord=0;%we have an image series without 'record' subdir
                    end
                end
                if testrecord
                    %the subdevice directory is 'record' (no images detected at this level)
                    for idir_s=1:nbsubdir
                        [t,RecordElement]=add(t,DeviceElement,'element',Device.Record{idir_s});
                        t=attributes(t,'add',RecordElement,'type','RECORD_DIR');
                        t=attributes(t,'add',RecordElement,'source','dir');
                        list_subdir=dir(fullfile(ExpPath,list_dir(idir_exp).name,Device.Record{idir_s}));
                        nbsubdir=0;
                        RootIma='';
                        RootNc='';
                        nbfile=0;
                        fname={};
                        for isubdir=3:length(list_subdir)
                            if list_subdir(isubdir).isdir
                                nbsubdir=nbsubdir+1;
                                [t,RecordElement]=add(t,DeviceElement,'element',Device.Record{idir_exp});
                                t=attributes(t,'add',RecordElement,'type','RECORD_DIR');
                                t=attributes(t,'add',RecordElement,'source','dir');
                                %VOIR les .netcdf a l'interieur
                            else
                                nbfile=nbfile+1;
                                fname{nbfile}=list_subdir(isubdir).name;
                            end
                        end
                        if isunix
                            fname_mod=regexprep(fname,'_','/');
                            fname_mod=sort(fname_mod);     %sort by name
                            fname=regexprep(fname_mod,'/','_');
                        end
                        for ifile=1:nbfile;           
                            [Path,Name,Ext]=fileparts(fname{ifile});
                            if isequal(Ext,'.xml')
                               [t,ImaDocElement]=add(t,DeviceElement,'element','ImaDoc');
                               t=add(t,ImaDocElement,'chardata',fname{ifile});
                               t=attributes(t,'add',ImaDocElement,'source','file');
                            elseif isequal(Ext,'.png')
                              % [Path,Root,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fname{ifile});
                                [~,~,Root]=fileparts_uvmat(fname{ifile});
                               if ~isequal(Root,RootIma)
                                   [t,ImaDocElement]=add(t,DeviceElement,'element','Image');
                                   t=add(t,ImaDocElement,'chardata',fname{ifile});
                                   t=attributes(t,'add',ImaDocElement,'source','file');
                                   RootIma=Root;
                               end
                            elseif isequal(Ext,'.nc')
                               %[Path,Root,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fname{ifile});
                               [~,~,Root]=fileparts_uvmat(fname{ifile});
                               if ~isequal(Root,RootNc)%only one image recorded for each root name
                                  [t,ImaDocElement]=add(t,DeviceElement,'element','Ncdata');
                                  t=add(t,ImaDocElement,'chardata',fname{ifile});
                                  t=attributes(t,'add',ImaDocElement,'source','file');
                                  RootNc=Root;
                               end
                            end
                        end
                    end
                else%the subdevice directory is a civ directory (coexist with images)
                     for idir_s=1:nbsubdir
                        [t,RecordElement]=add(t,DeviceElement,'element',Device.Record{idir_s});
                        t=attributes(t,'add',RecordElement,'type','CIV_DIR');
                        t=attributes(t,'add',RecordElement,'source','dir');
                        %list files under the civ directory
                        list_subdir=dir(fullfile(ExpPath,list_dir(idir_exp).name,Device.Record{idir_s}));
                                        
                        nbsubdir=0;
                        nbfile=0;
                        RootXml='';
                        RootNc='';       
                        fname={};
                        for isubdir=3:length(list_subdir)
                            if list_subdir(isubdir).isdir
                                nbsubdir=nbsubdir+1;
                                [t,SubElement]=add(t,RecordElement,'element',list_subdir(isubdir).name);
                                t=attributes(t,'add',SubElement,'type','UNKNOWN_DIR');
                                t=attributes(t,'add',SubElement,'source','dir');
                            else
                                nbfile=nbfile+1;
                                fname{nbfile}=list_subdir(isubdir).name;
                            end
                        end
                        if isunix
                            fname_mod=regexprep(fname,'_','/');
                            fname_mod=sort(fname_mod);     %sort by name
                            fname=regexprep(fname_mod,'/','_');
                        end
                        for ifile=1:nbfile;
                            [Path,Name,Ext]=fileparts(fname{ifile});
                            if isequal(Ext,'.xml')
                               %[Path,Root,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fname{ifile});
                               [~,~,Root]=fileparts_uvmat(fname{ifile});
                               if ~isequal(Root,RootXml)%only one image recorded for each root name
                                   [t,ImaDocElement]=add(t,RecordElement,'element','CivDoc');
                                   t=add(t,ImaDocElement,'chardata',fname{ifile});
                                   t=attributes(t,'add',ImaDocElement,'source','file');
                                   RootXml=Root;
                               end
                            elseif isequal(Ext,'.nc')
                               %[Path,Root,field_count,str2,str_a,str_b,ext,nom_type,subdir]=name2display(fname{ifile});
                               [~,~,Root]=fileparts_uvmat(fname{ifile});
                               if ~isequal(Root,RootNc)%only one image recorded for each root name
                                  [t,ImaDocElement]=add(t,RecordElement,'element','Ncdata');
                                  t=add(t,ImaDocElement,'chardata',fname{ifile});
                                  t=attributes(t,'add',ImaDocElement,'source','file');
                                  RootNc=Root;
                               end
                            end
                        end
                    end
                end
            end
        end
        save(t);%display xml file on the screen
        save(t,ExpDocName);
    end
end
% [erread,message]=fileattrib('./DATA');
% if ~isempty(message) & ~isequal(message.UserWrite,1)
%      errordlg(['Need writting access to ' message.Name])
%      return
% end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function project_update(obj,event,fileinput)
    hchild=get(gcbf,'children');
    h=findobj(gcbf,'Tag','listbox')
    
