%'editxml': function for editing xml files using a xml schema (associated with the GUI editxml.fig)
%------------------------------------------------------------------------
% function heditxml=editxml(inputfile)
%
%OUTPUT: heditxml: graphic handle of the GUI 
%
%INPUT: inputfile:  name of an xml file

%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This file is part of the toolbox UVMAT.
% 
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function varargout = editxml(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @editxml_OpeningFcn, ...
                   'gui_OutputFcn',  @editxml_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ~isempty(regexp(varargin{1},'_Callback','once'))
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before editxml is made visible.
function editxml_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to editxml (see VARARGIN)

% set(handles.replicate,'String',['copy';'<---'])
if nargin
    CurrentFile=varargin{1};
else
    CurrentFile=[];
end
% if exist('varargin') & length(varargin)>=1
%     CurrentFile=cell2mat(varargin{1});
% else
%     CurrentFile=[];
% end
% Choose default command line output for editxml
handles.output = hObject;
% set(hObject,'Units','pixel')
if exist(CurrentFile,'file')
    [PathName,Nme,FileExt]=fileparts(CurrentFile);
    if isequal(FileExt,'.xls')
        DataIn.hfig_xls=read_xls(CurrentFile);% DataIn.hfig_xls=handle of the Excel display figure
        DataIn.CurrentUid=1;
        figpos=get(hObject,'Position');%position of the editxml interface
        figposunit=get(hObject,'Units');%unity used to indicate position
        newfigpos=[figpos(1)-0.5*figpos(3) figpos(2) figpos(3) figpos(4)];
        set(DataIn.hfig_xls,'Units',figposunit)
        set(DataIn.hfig_xls,'Position',newfigpos); %set position of the Excel display figure 
        set(hObject,'UserData',DataIn)
    else
        set(handles.CurrentFile,'String',CurrentFile)
        CurrentFile_Callback(hObject, eventdata, handles)
    end
end
% Update handles structure
guidata(hObject, handles);

%----------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = editxml_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in list_element.
function list_element_Callback(hObject, eventdata, handles)
global t xs t_ref
CurrentFile=get(handles.CurrentFile,'String');
bla=get(hObject,'String');
ind=get(hObject,'Value');
list=get(hObject,'UserData');
NewRootUid=list.uid(ind);
heditxml=get(hObject,'Parent');
DataIn=get(heditxml,'UserData');
if ~isempty(xs)
	xs_node=list.xs_uid(ind);%xs_node of the subelement #ind
	[nodeup,path,xs_element,xs_subelem]=scan_schema(xs,xs_node);
	[element,subelem]=get_xml(t,path,xs_element,NewRootUid,xs_subelem);
	update_list(handles,path,xs_element,element,NewRootUid,xs_subelem,subelem);
	if xs_element.subtest     
        DataIn.CurrentUid=[DataIn.CurrentUid NewRootUid];%record new current uid
        DataIn.xs_CurrentUid=[DataIn.xs_CurrentUid xs_node];%record the new curent schema uid
	end
    
%     %update the import file display
%     if isfield(DataIn,'h_ref')&ishandle(DataIn.h_ref)
%         tag0_ref=find(t_ref,['/' path '/' xs_element.key]);
%         node_ref=list.index(ind);
%         if length(tag0_ref)<node_ref
%             node_ref=length(tag0_ref);
%         end
%         [ref_element,ref_subelem]=get_xml(t_ref,path,xs_element,node_ref,xs_subelem);
%         update_ref_list(DataIn.h_ref,xs_element,ref_element,node_ref,xs_subelem,ref_subelem);
%     end  
set(get(hObject,'Parent'),'UserData',DataIn);
else%no schema
    [DataIn,testsimple]=displ_xml(handles,t,NewRootUid,DataIn,get(hObject,'parent'));
    if ~testsimple
        DataIn.CurrentUid=[DataIn.CurrentUid NewRootUid];%record new current uid
        set(get(hObject,'Parent'),'UserData',DataIn);
    end
end

%-------------------------------------------------
% --- Executes on button press in move_up.
function move_up_Callback(hObject, eventdata, handles)
global t xs t_ref
set(handles.export_list,'Value',1);%
set(handles.export_list,'String','');% empty the export list
CurrentFile=get(handles.CurrentFile,'String');
CurrentElement=get(handles.CurrentElement,'String');
heditxml=get(handles.move_up,'parent');
test_root=0;
DataIn=get(heditxml,'UserData');
if isfield(DataIn,'CurrentUid')&length(DataIn.CurrentUid)>1
    nodeup=DataIn.CurrentUid(end-1);
    DataIn.CurrentUid(end)=[];
else
    nodeup=[]; 
end
if isempty(xs)   
    if isempty(nodeup)
        test_root=1;
    else
        DataIn=displ_xml(handles,t,nodeup,DataIn,heditxml);
    end
else
    xs_nodeup=[];
%     if isfield(DataIn,'xs_UpUid')
    if isfield(DataIn,'xs_CurrentUid')&length(DataIn.xs_CurrentUid)>1
%         xs_nodeup=DataIn.xs_UpUid
        xs_nodeup=DataIn.xs_CurrentUid(end-1);
        DataIn.xs_CurrentUid(end)=[];%uid of the root element in the schema
    end
    if isempty(xs_nodeup)
        test_root=1;
    else
        [xs_nodeup,path,xs_element,xs_subelem]=scan_schema(xs,xs_nodeup);
		[element,subelem]=get_xml(t,path,xs_element,nodeup,xs_subelem);
		update_list(handles,path,xs_element,element,nodeup,xs_subelem,subelem);
        %update the import file display
        if isfield(DataIn,'h_ref')&ishandle(DataIn.h_ref)
            [ref_element,ref_subelem]=get_xml(t_ref,path,xs_element,nodeup,xs_subelem);
            update_ref_list(DataIn.h_ref,xs_element,ref_element,nodeup,xs_subelem,ref_subelem);
        end
    end
    set(get(hObject,'parent'),'UserData',DataIn);
end
if test_root% we are a the root, 
    testupfile=0;
    DataIn=get(get(hObject,'parent'),'UserData');
    if isfield(DataIn,'UpFile')&&~isempty(DataIn.UpFile)
        [UpPath,UpName,UpExt]=fileparts(DataIn.UpFile{1});
        if isequal(UpExt,'.xml')
            set(handles.CurrentFile,'String',DataIn.UpFile{1})
            CurrentFile_Callback(handles.CurrentFile,[],handles)
            testupfile=1;
            DataIn.UpFile{1}={};
        end
    end
    if ~testupfile  %open the browser
        RootPath=fileparts(CurrentFile);
            [FileName, PathName]=uigetfile( ...
               {'*.xml', '(*.xml)';
                '*.xml',  '.xml files '; ...
                '*.*',  'All Files (*.*)'}, ...
                'Pick a file',RootPath); %file browser
            fileinput_new=fullfile(PathName,FileName);
            set(handles.CurrentFile,'String',fileinput_new)
            CurrentFile_Callback(handles.CurrentFile,[],handles)
     end
end
set(heditxml,'UserData',DataIn);
%---------------------------------------------------------
%edit element value
function element_value_Callback(hObject, eventdata, handles)
%----------------------------------------------------------
global t xs
if isequal(get(handles.element_value,'ForegroundColor'),[0.7 0.7 0.7])
    return% edit element desactivated (grey display)
end
list_enum=get(handles.element_value,'String');
list_index=get(handles.element_value,'Value');
if iscell(list_enum)
    value=list_enum{list_index};
else
    value=list_enum;
end
heditxml=get(handles.element_value,'Parent');
DataIn=get(heditxml,'UserData');
%create the current root element if needed
LengthElement=length(DataIn.CurrentUid);
FilledUid=find(DataIn.CurrentUid~=0);
LengthFilled=FilledUid(end);
for irank=LengthFilled+1:LengthElement
    attrib=attributes(xs,'get',DataIn.xs_CurrentUid(irank),1);
    [t,DataIn.CurrentUid(irank)]=add(t,DataIn.CurrentUid(irank-1),'element',attrib.val);
end
node_element=get(handles.element_value,'UserData');
element_key=get(handles.element_key,'String');
t=set_element(t,DataIn.CurrentUid(end),node_element,element_key,value);
 
set(heditxml,'UserData',DataIn)
%update the current listing 
[nodeup,path,xs_element,xs_subelem]=scan_schema(xs,DataIn.xs_CurrentUid(end));
[element,subelem]=get_xml(t,path,xs_element,DataIn.CurrentUid(end),xs_subelem);
element_index=get(handles.list_element,'Value');
update_list(handles,path,xs_element,element,DataIn.CurrentUid(end),xs_subelem,subelem);
set(handles.list_element,'Value',element_index);

% 
% % --- Executes on button press in inport_file.
% function inport_file_Callback(hObject, eventdata, handles)
% CurrentFile=get(handles.RefFile,'String');
% if isempty(CurrentFile)|isequal(CurrentFile,'')
%     CurrentFile=get(handles.CurrentFile,'String')
% end
% [FileName, PathName]=uigetfile( ...
%        {'*.xml', '(*.xml)';
%         '*.xml',  '.xml files '; ...
%         '*.*',  'All Files (*.*)'}, ...
%         'Pick a file',CurrentFile); %file browser
% fileinput=fullfile(PathName,FileName);
% sizf=size(fileinput);
% if (~ischar(fileinput)|~isequal(sizf(1),1)),return;end% keep only character strings as input file name
% if exist(fileinput,'file')
%    set(handles.RefFile,'Visible','on')
%    set(handles.replicate,'Visible','on')
%    set(handles.RefFile,'String',fileinput)
%    RefFile_Callback(handles.RefFile, eventdata, handles)
% end


%------------------------------------------------------
% --- Executes on button press in browser.
function browser_Callback(hObject, eventdata, handles)
%-------------------------------------------------------
heditxml=get(hObject,'parent');%handle of the interface figure
DataIn=get(heditxml,'UserData');%get the current input xml file
CurrentFile=get(handles.CurrentFile,'String');
DataIn.Schema=[];%schema input file put to [] by default
[FileName, PathName]=uigetfile( ...
       {'*.xml;*.xls','(*.xml,*.xls)';
        '*.xml',  '.xml files '; ...
        '*.xls',  '.xls files '; ...
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file',CurrentFile); %file browser
CurrentFile=fullfile(PathName,FileName);
sizf=size(CurrentFile);
if (~ischar(CurrentFile)||~isequal(sizf(1),1)),return;end% keep only character strings as input file name
if exist(CurrentFile,'file')
%     set(handles.CurrentAttributes,'UserDataIn',PathName); %store the path to the xml file
    [CurPath,CurName,CurExt]=fileparts(CurrentFile);
    if isequal(CurExt,'.xls')    
        if isfield(DataIn,'hfig_xls') && ishandle(DataIn.hfig_xls)
            [hfig_xls]=read_xls(CurrentFile,DataIn.hfig_xls);
        else
            [hfig_xls]=read_xls(CurrentFile);
        end
        figpos=get(heditxml,'Position');
        newfigpos=[figpos(1)-0.25*figpos(3) figpos(2) 0.5*figpos(3) 0.5*figpos(4)];
        set(hfig_xls,'Position',newfigpos)
    else
        set(handles.CurrentFile,'String',CurrentFile)
        CurrentFile_Callback(hObject, eventdata, handles)
     end
end

%------------------------------------
function CurrentFile_Callback(hObject, eventdata, handles)
global t xs
CurrentFile=get(handles.CurrentFile,'String');
heditxml=get(handles.CurrentFile,'parent');%handles of the inteface
DataIn=get(heditxml,'UserData');
t=xmltree(CurrentFile);%open the xml file 
head_element=get(t,1);
if ~isfield(head_element,'name') || ~isfield(head_element,'attributes')
    msgbox_uvmat('ERROR','root element of the .xml file not in correct format')
end
head_name=head_element.name;
head_attr=head_element.attributes;% attribute of root gives the name of the associated schema
xstest=0;
for iattr=1:length(head_attr)
    if isequal(head_attr{iattr}.key,'xmlns:xsi')&& isequal(head_attr{iattr}.val,'none')%no schema to read
         xs=[];
%          xstest=1;
    end
    if isequal(head_attr{iattr}.key,'xsi:noNamespaceSchemaLocation') && exist(head_attr{iattr}.val,'file')
        DataIn.Schema=head_attr{iattr}.val;
        xs=xmltree(DataIn.Schema);%open the associated schema file
        xstest=1;
    end
end
if xstest==0  %look for the corresponding schema in the directory PARAM_LINUX.xml or PARAM_WIN.xml
    head_name=get(t,1,'name');
    %Path to shemas:
    path_uvmat=fileparts(which('editxml'));% check the path detected for source file uvmat
    % path_UVMAT=fileparts(path_uvmat); %path to UVMAT
    %     xmlparam=fullfile(path_UVMAT,'PARAM.xml');
    %     xmlparam='PARAM.xml'; %will find PARAM.xml whose path is set in priority
    %     if exist(xmlparam,'file')
    %         tparam=xmltree(xmlparam);
    %         sparam=convert(tparam);
    %         if isfield(sparam,'SchemaPath')
    schemafile=[fullfile(path_uvmat,'xml_shemas',head_name) '.xsd'];
    if ~exist(schemafile,'file')
        schemafile=fullfile(path_UVMAT,schemafile);%look for relative path definition
    end
    if exist(schemafile,'file')
        xs=xmltree(schemafile);
    else
        msgbox_uvmat('ERROR',['The needed xml schema  ' sparam.SchemaPath ' is not found, check the file PARAM.xml'])
        [FileName, PathName]=uigetfile( ...
            {'*.xsd', '(*.xsd)';
            '*.xsd',  '.xsd files '; ...
            '*.*',  'All Files (*.*)'}, ...
            'Pick a .xsd schema' ,schemafile); %file browser
        if ischar(PathName) && ischar(FileName) && exist(fullfile(PathName,FileName),'file')
            DataIn.Schema=fullfile(PathName,FileName);
            xs=xmltree(DataIn.Schema);%open the associated schema file
        else
            xs=[];
        end
    end
    %         end
    %     end
end
DataIn.CurrentUid=1;
if isempty(xs)
    displ_xml(handles,t,1,DataIn,get(hObject,'parent'));%no associated schema, default  display of the xml file
else
    DataIn.xs_CurrentUid=find(xs,'/xs:schema/xs:element');%uid of the root element in the schema
	[nodeup,path,xs_element,xs_subelem]=scan_schema(xs,DataIn.xs_CurrentUid);%scan the schema at the root level
	[element,subelem]=get_xml(t,path,xs_element,1,xs_subelem);% read the corresponding xml data
	update_list(handles,path,xs_element,element,1,xs_subelem,subelem);%update the display of information on the interface
end
set(heditxml,'UserData',DataIn);%store the new input xml file name

%-------------------------------------------------------
%  function scan_schema: read the xml schema xs
%--------------------------------------------------------
%OUTPUT:
%nodeup: parent node of nodeinput
%path: path to nodeinput in the tree
%xs_element: element corresponding to nodeinput
    %xs_element.uid, =tag of the element in the schema (=nodeinput)
    %xs_element.key: key label of nodeinput
    %xs_element.type: type of data contained in the element
    %xs_element.annot: annotation of nodeinput 
    %xs_element.attrib: list of accepted attributes keys for xs_element
    %xs_element.enum: enumeration, list of accepted values for nodeinput
    %xs_element.subtest: =1 if the element contains subelements in the schema, 0 else
  
%xs_subelement(k): subelement #k of xs_element
    %xs_subelem(k).node: node number in the schema
    %xs_subelem(k).key: key name of the element
    %xs_subelem(k).testsub: =1 if element contains subelements, 0 else
    %xs_subelem(k).minOccurs: =0 for a non mandatory element, =1 else
    %xs_subelem(k).maxOccurs
%
%INPUT:
%xs: schema xml tree
%nodeinput: tag of the current root element in the schema
function [nodeup,path,xs_element,xs_subelem]=scan_schema(xs,nodeinput)
nodeup=[];
path=[];
xs_element.key=[];
xs_element.type=[];
xs_element.annot=[];
xs_element.attrib=[];
xs_element.subtest=0;
xs_element.enum={};
xs_subelem=[];%default
% get default nodeinput (root of the file) if not defined
if ~exist('nodeinput') | isempty(nodeinput)% we start at the root
    node=find(xs,'/xs:schema/xs:element');%description of the root element
else
    node=nodeinput;
end
xs_element.uid=node;
%get the key name and element_type of the element
node_content=get(xs,node);
if isempty(node_content),return,end;
if ~isempty(node_content) & isfield(node_content,'attributes')
    attrib=node_content.attributes;
    for iattr=1:length(attrib)
        struct=attrib{iattr};
        if isequal(struct.key,'name')
            xs_element.key=struct.val; % read element key name
        elseif isequal(struct.key,'type')
            xs_element.type=struct.val; % read element key name
        end
    end
end

%get the parent node of nodeinput
if ~isempty(node_content)
    nodeup=get(xs,node,'parent');%move up to the parent in the tree
    if ~isempty(nodeup)
        nodeup=get(xs,nodeup(1),'parent');%move up to the parent in the tree
        if isequal(nodeup,[])
            %OUVRIR FICHIER AMONT
            up=0;
        else
            nodeup=get(xs,nodeup(1),'parent');%move up to the parent in the tree
        end
    end
end
%get the path to 'nodeinput' in the schema
up=1;
path=[];
if ~isempty(nodeup)
    attrib=attributes(xs,'get',nodeup,1);
    path=attrib.val;
    nodeup2=nodeup;
    while up==1;
        nodeup2=get(xs,nodeup2(1),'parent');%move up to the parent in the tree
        nodeup2=get(xs,nodeup2(1),'parent');%move up to the parent in the tree
        if isempty(nodeup2)
            up=0;
        else
            nodeup2=get(xs,nodeup2(1),'parent');%move up to the parent in the tree
            if isempty(nodeup2)
                up=0;
            else
                attrib=attributes(xs,'get',nodeup2,1);
                path=[attrib.val '/' path];
            end
        end
    end
end   

%explore the subtree in the schema file
node1=children(xs,node); %find the children of the root element
test_sub=0; %no subtree in the .xml file by default
comment='';
element={};
minOccurs={};
maxOccurs={};
testsub={};
list_menu={};
text={};
if ~isempty(node1)  
  for i=1:length(node1)
    nodename1=get(xs,node1(i),'name');
    node2=children(xs,node1(i));
    if isequal(nodename1,'xs:annotation')
         for j=1:length(node2)
            nodename2=get(xs,node2(j),'name');
            if isequal(nodename2,'xs:documentation')
                node3=children(xs,node2(j));
                xs_element.annot=get(xs,node3,'value');%read annotation
            end
        end
    % pour les elements
    elseif isequal(nodename1,'xs:simpleType')
        for j=1:length(node2)
            nodename2=get(xs,node2(j),'name');
            if isequal(nodename2,'xs:restriction')
                node3=children(xs,node2(j));
                for k=1:length(node3)
                    nodename3=get(xs,node3(k),'name');
                    if isequal(nodename3,'xs:enumeration')
                        node3_content=get(xs,node3(k));
                        attr=node3_content.attributes;
                        for m=1:length(attr)
                            struct=attr{m};
                            if isequal(struct.key,'value')
                                xs_element.enum{k}=struct.val; % read enumeration
                            end
                        end   
                   end
               end
            end
        end
     elseif isequal(nodename1,'xs:complexType')
         for j=1:length(node2)
             nodename2=get(xs,node2(j),'name');
             if isequal(nodename2,'xs:attribute')
                 node_content=get(xs,node2(j));
                 attr=node_content.attributes;
                 for k=1:length(attr)
                    struct=attr{k};%read attributes
                    if isequal(struct.key,'name')
                        xs_element.attrib=struct.val; %read attributes of main node
                    end
                 end   
             elseif isequal(nodename2,'xs:sequence')
                 xs_element.subtest=1;
                 node3=children(xs,node2(j));%nodes of the sequence
                 for k=1:length(node3)
                     xs_subelem(k).node=node3(k);
                     xs_subelem(k).testsub=0;%default
                     node_content=get(xs,node3(k));
                     xs_subelem(k).minOccurs=1; %default
                     xs_subelem(k).maxOccurs=1; %default
%                      pref{k}=[]; %default
                     if isequal(node_content.name,'xs:element')
                        attr=node_content.attributes;
%                         attr{:}.key
                        for l=1:length(attr)
                            if isequal(attr{l}.key,'name')
                                xs_subelem(k).key=attr{l}.val;%name of the element
                            elseif isequal(attr{l}.key, 'minOccurs')
                                xs_subelem(k).minOccurs=attr{l}.val;
                            elseif isequal(attr{l}.key, 'maxOccurs')
                                xs_subelem(k).maxOccurs=attr{l}.val;
                            end
                        end
                     end
                     node4=children(xs,node3(k));
                     for l=1:length(node4)
                        res=get(xs,node4(l),'name');
                        if isequal(res,'xs:complexType')%look whether the element k contains a subtree
                           node5=children(xs,node4(l));
                           for m=1:length(node5)
                               res2=get(xs,node5(m),'name');
                               if isequal(res2,'xs:sequence')
                                    xs_subelem(k).testsub=1; %flag for the existence of a subtree
                               end
                           end
                        end
                     end
                 end            

             end
         end     
     end   
  end
end
% look for predefined types
if length(xs_element.type)>=3 & (xs_element.type([1:3])~='xs:')
    node_type=find(xs,'/xs:schema/xs:simpleType')
    for i=1:length(node_type)
        content=get(xs,node_type(i));
        nodeattr=content.attributes;
        if ~isempty(nodeattr) & isequal(nodeattr{1}.key,'name') & isequal(nodeattr{1}.val,xs_element.type)
            node1=children(xs,node_type(i));
            node2=find(xs,node1,'name','xs:restriction');
%             nodename1=find(xs,
            node3=children(xs,node2);
            node4=find(xs,node3,'name','xs:enumeration');
            for ienum=1:length(node4)
                struct2=get(xs,node4(ienum));
                enumval=struct2.attributes;
                xs_element.enum{ienum}=enumval{1}.val;
            end
        end       
     end
end

%--------------------------------------------------------
%OUTPUT:
%element.val: value of the current element, =[] in the absence of chardata value
%node: node (iud) of the element in t
%element.attr_key{iattr}: attribute key #iattr of the current element
%element.attr_val{iattr}: attribute value #iattr of the current element
%element.attrup: %structure containing the attributes of the element, including the ones unheritated from parent nodes
%subelem(iline).val : value of subelement # iline, concatenated with corresponding attributes
%subelem(iline).xsindex: index k of the subelement #iline in the list xs_subelem of the schema
%subelem(iline).index: index of the subelement #iline inside its xs_subelement, =0 when the xs_subelement is absent in t

%INPUT:
%t: xml tree
%path: path to the current element in the schema
%xs_element: current element in the schema
    %xs_element.key: key label  
    %xs_element.type: type of data contained in the element
    %xs_element.annot: annotation of nodeinput 
    %xs_element.attrib: list of accepted attributes keys for xs_element
    %xs_element.enum: enumeration, list of accepted values 
    %xs_element.subtest: =1 if the element contains subelements in the schema, 0 else
%index: index of the element, =1 in case of single occurence in xs_element,=0 in case of missing element
%xs_subelem(k): subelement #k of the current element in the schema
    %xs_subelem(k).node: node iud of the 
    %xs_subelem(k).key: key name of the subelement #k in the schema
    %xs_subelem(k).testsub: =1 if element contains subelements, 0 else
    %xs_subelem(k).minOccurs
    %xs_subelem(k).maxOccurs

function [element,subelem]=get_xml(t,path,xs_element,node,xs_subelem)
element.attr_key='';%default
element.attr_val='';%default
element.val='';
% element.type='';
% element.testmanual=testmanual %inheritates the input manual editing flag by default
subelem=[]; %default
attrup=[];
% node=[];

% %find the element properties in the xml file
if node >= 1
    elem_struct=get(t,node);
    if ~xs_element.subtest
        elem_contents=get(t,elem_struct.contents);
        if isempty(elem_contents)
            element.val=[];
        else
            element.val=elem_contents.value
        end
    end
    if isfield(elem_struct,'attributes')
        elem_attr=elem_struct.attributes;
        for iattr=1:length(elem_attr)
            element.attr_key{iattr}=elem_attr{iattr}.key ;
            element.attr_val{iattr}=elem_attr{iattr}.val;
%             attrup=setfield(attrup,elem_attr{iattr}.key,elem_attr{iattr}.val);
           breakdetect=find(elem_attr{iattr}.key=='/'| elem_attr{iattr}.key==':'| elem_attr{iattr}.key=='.');% find '/'
           if isempty(breakdetect)
%                 comline=['attrup.' elem_attr{iattr}.key '=' elem_attr{iattr}.val ';']
                eval(['attrup.' elem_attr{iattr}.key '=''' elem_attr{iattr}.val ''';'])
           end
        end
    end
end
%get the parent node attributes 
up=1;
if node>0
	nodeup=node;
	while up==1; 
        nodeup=get(t,nodeup,'parent');%move up to the parent in the tree
        if isempty(nodeup)
            up=0;
        else
            nodeup_content=get(t,nodeup);
            attrib=nodeup_content.attributes;
            for iattr=1:length(attrib)
                key=attrib{iattr}.key;
                breakdetect=find(key=='/'| key==':'| key=='.');% find '/'
                if ~isfield(attrup,key) & isempty(breakdetect)
                   eval(['attrup.' key '=''' attrib{iattr}.val ''';'])
                end
            end
        end
	end
	element.attrup=attrup;
end
%find the subelement properties in the xml file
if xs_element.subtest
   iline=0;
   for k=1:length(xs_subelem)%node2: list of subelements in the sub-sequence
%     attr=attributes(xs,'get',node2(i),1);% 
%     element=attr.val;%name of the element 
     tag=find(t,['/' path '/' xs_element.key '/' xs_subelem(k).key]);%look for the corresponding element node in the .xml tree
     struct_element=get(t,tag);%get the content of the element
     if isempty(struct_element) 
         iline=iline+1;
         subelem(iline).uid=0;
         subelem(iline).xsindex=k;
         subelem(iline).index=0;
%          subelem(iline).testmanual=element.testmanual;% inheritates the manual editing flag by default
         if isequal(xs_subelem(k).minOccurs,'0')
             subelem(iline).val='[]';%element value not mandatory in the schema
         else
             subelem(iline).val='[MISSING]';%element value mandatory in the schema
         end
%          subelem(iline).attrup=attrup; %inheritated attributes
     elseif isequal(length(struct_element),1)
         contents=get(t,struct_element.contents);
         iline=iline+1;
         subelem(iline).uid=tag;
         subelem(iline).xsindex=k;
         subelem(iline).index=1;
%          subelem(iline).testmanual=element.testmanual;%
         if isfield(contents,'value') & ~isempty(contents.value)
             subelem(iline).val=contents.value;
         elseif xs_subelem(k).testsub
             subelem(iline).val='';
         elseif isequal(xs_subelem(k).minOccurs,0) 
             subelem(iline).val='[]';%element value not mandatory in the schema
         else
             subelem(iline).val='[MISSING]';%element value mandatory in the schema
         end
%          subelem(iline).attrup=attrup; %inheritated attributes
         if isfield(struct_element,'attributes')
            element_attr=struct_element.attributes;
            attr_display=[];
            for iattr=1:length(element_attr)
%                 attr_display{iline}=[attr_display ' , ' element_attr{iattr}.key '  =  ' element_attr{iattr}.val];
                subelem(iline).val=[subelem(iline).val attr_display ' , ' element_attr{iattr}.key '  =  ' element_attr{iattr}.val];
%                 subelem(iline).attrup=setfield(subelem(iline).attrup,element_attr{iattr}.key,element_attr{iattr}.val);
            end
         end
     else%case of a multiple element
         for subindex=1:length(struct_element)
             contents=get(t,struct_element{subindex}.contents);
             iline=iline+1;
             subelem(iline).index=subindex;%index of the element
             subelem(iline).xsindex=k;
%              subelem(iline).testmanual=element.testmanual;%
             if isfield(contents,'value')& ~isempty(contents.value)
                 subelem(iline).val=contents.value;
             elseif xs_subelem(k).testsub
                 subelem(iline).val='';
             else
                 subelem(iline).val='[]';
             end
%              subelem(iline).attrup=attrup; %inheritated attributes
             if isfield(struct_element{subindex},'attributes')
                element_attr=struct_element{subindex}.attributes;
                attr_display=[];
                for iattr=1:length(element_attr)
%                     attr_display{iline}=[attr_display ' , ' element_attr{iattr}.key '  =  ' element_attr{iattr}.val];
                    subelem(iline).val=[subelem(iline).val attr_display ' , ' element_attr{iattr}.key '  =  ' element_attr{iattr}.val];
%                     subelem(iline).attrup=setfield(subelem(iline).attrup,element_attr{iattr}.key,element_attr{iattr}.val);
                end
            end
        end
     end
  end
end

%-------------------------------------
%updates the interface
function update_list(handles,path,xs_element,element,node,xs_subelem,subelem)
%-----------------------------
if xs_element.subtest% we list the sub-elements of root
    set(handles.export_list,'Value',1)
    set(handles.export_list,'String','')%flush the export list
    set(handles.CurrentElement,'String',[path '/' xs_element.key])
%     title_element.key=[path '/' xs_element.key];
%     if ~isempty(path)
%         xsnode_index=get(handles.list_element,'UserDataIn');
%         ind=get(handles.list_element,'Value');
%         title_element.index=xsnode_index(2,ind);
%     else
%         title_element.index=1;
%     end
%     title_element.xsnode=xs_element.uid;
%     title_element.node=node;
%     set(handles.CurrentFile,'UserDataIn',title_element)%element corresponding to the title
    set(handles.CurrentAnnotation,'String',xs_element.annot)
    attr_col=[];
    testedit=0;% cannot edit elements by default
    for iattr=1:length(element.attr_key)
%          if isequal(element.attr_key{iattr},'source') & isequal(element.attr_val{iattr},'manual')
%             testedit=1;
%         end
        attr_col=strvcat(attr_col,[element.attr_key{iattr} ' = ' element.attr_val{iattr}]);
    end
    set(handles.CurrentAttributes,'String',attr_col)
    pref_col='';
    key_col='';
    equal_sign='';
    val_col='';
    for iline=1:length(subelem)
        xsindex=subelem(iline).xsindex;
        index(iline)=subelem(iline).index;
        subuid=subelem(iline).uid;
        if isempty(subuid)
            list.uid(iline)=0;
        else
            list.uid(iline)=subuid;
        end
        node(iline)=xs_subelem(xsindex).node;
%         testmanual(iline)=subelem(iline).testmanual;
        ikey=xs_subelem(xsindex).key;
        if xs_subelem(xsindex).testsub
            ival=[' + ' subelem(iline).val];
        else
            ival=[' = ' subelem(iline).val];
        end
        key_col=strvcat(key_col,ikey);
        val_col=strvcat(val_col,ival);
    end
    list_element=[key_col val_col];
    set(handles.list_element,'String',list_element)
    set(handles.list_element,'Value',1)
    list.xs_uid=node;
    list.index=index;
    set(handles.list_element,'UserData',list)
    set(handles.element_attrib,'Visible','off')
    set(handles.element_key,'Visible','off')
    set(handles.element_value,'Visible','off')
else % we edit an element

    export_list=get(handles.export_list,'String');%export list
    testadd=1;
    for ilist=1:length(export_list) 
        if isequal(xs_element.key,export_list{ilist})
            testadd=0;        
            break
        end
    end
    if testadd
        export_list=[export_list;{xs_element.key}];
        ilist=length(export_list);
    end
    set(handles.export_list,'String',export_list)
    if iscell(element.val)
        element_val=element.val{1};
    else
        element_val=element.val;
    end
    set(handles.element_value,'String',element_val)
    export_val=get(handles.export_list,'UserData');
    export_val{ilist}=element_val;
    set(handles.export_list,'UserData',export_val);
    set(handles.element_annot,'String',xs_element.annot)
    set(handles.element_type,'String',['type:  ' xs_element.type])
    attr_col=[];
    testedit=0;% cannot edit element by default
    for iattr=1:length(element.attr_key)
%         if isequal(element.attr_key{iattr},'source') & isequal(element.attr_val{iattr},'manual')
%             testedit=1;
%         end
        attr_col=strvcat(attr_col,[element.attr_key{iattr} ' = ' element.attr_val{iattr}]);
    end
    set(handles.element_attrib,'String',attr_col)
    set(handles.element_key,'String',xs_element.key)

 
    if isempty(xs_element.enum)
        set(handles.element_value,'Value',1)
        set(handles.element_value,'Style','edit')
    else % case of an enumeration of possible values
         list_enum=[];
         list_val=[];
         for ienum=1:length(xs_element.enum)
             list_enum{ienum,1}=xs_element.enum{ienum};
             if isequal(xs_element.enum{ienum},element_val)
                 list_val=ienum;
             end
         end 
         if isempty(list_val) 
             list_enum{length(xs_element.enum)+1,1}=['[' element_val ']'];%show the non-valid element between brackets
             list_val=length(xs_element.enum)+1;
         end
         set(handles.element_value,'Style','popupmenu')
         set(handles.element_value,'String',list_enum)
         set(handles.element_value,'Value',list_val)
     end
     if isempty(element.val)
         testedit=1;%allow element editing if value is missing
     end     
     set(handles.element_attrib,'Visible','On')
     set(handles.element_key,'Visible','On')
     set(handles.element_value,'Visible','On')
end
set(handles.element_value,'UserData',node)
if ~testedit && isfield(element,'attrup') && isfield(element.attrup,'source')&& ~isequal(element.attrup.source,'manual')
     set(handles.element_value,'Enable','inactive')
else
    set(handles.element_value,'Enable','on')
end


% --- Executes on button press in SAVE.
function SAVE_Callback(hObject, eventdata, handles)
global t
DataIn=get(get(handles.SAVE,'parent'),'UserData');
CurrentFile=get(handles.CurrentFile,'String');
if isfield(DataIn,'Schema')
if ~isempty(DataIn.Schema)% update ref to schema 
    attrxsd=attributes(t,'get',1);
    setest=0;
    for iattr=1:length(attrxsd)
        if isequal(attrxsd{iattr}.key,'xsi:noNamespaceSchemaLocation')
            t= attributes(t,'set',1,iattr,'xsi:noNamespaceSchemaLocation',DataIn.Schema);
            setest=1;
        end
    end
    if setest==0;
        t=attributes(t,'add',1,'xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance'); 
        t= attributes(t,'add',1,'xsi:noNamespaceSchemaLocation',DataIn.Schema);
    end
end
end
copyfile(CurrentFile,[CurrentFile '.bak']);
save(t,CurrentFile);

%-------------------------------------
% creates and/or set values to an element in t
%t: xml tree 
%RootUid: uid of t under which we introduce an element
%node: uid of the element that we correct, if =0, a new element is created
%key: key name of the element 
%value: new value of the element
function t=set_element(t,RootUid,node,key,value)
%create the subelement if needed
if isequal(node,0)    
   [t,node]= add(t,RootUid,'element',key);
end
node_chardata=children(t,node); %corresponding data node
if isempty(node_chardata)%if the data does not exist in t, create it
    t=add(t,node,'chardata',value);
elseif isequal(length(node_chardata),1)&isequal(get(t,node_chardata,'type'),'chardata')% update only a simple element with 'chardata'
    t=set(t,node_chardata,'value',value);%modify existing data
end 
attr=attributes(t,'get',node);
if isempty(attr)
    t=attributes(t,'add',node,'source','manual');%indicate a manual eidting
end

% --- Executes on selection change in element_attr_val.
function element_attr_val_Callback(hObject, eventdata, handles)
% hObject    handle to element_attr_val (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns element_attr_val contents as cell array
%        contents{get(hObject,'Value')} returns selected item from element_attr_val


% --- Executes on button press in ADD.
function ADD_Callback(hObject, eventdata, handles)
% hObject    handle to ADD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%----------------------------------------
%read an xml file without schema
function [Data,testsimple]=displ_xml(handles,t,root_uid,DataIn,heditxml)
Data=DataIn;%default
if ~isfield(Data,'CurrentUid')
    Data.CurrentUid=[];
end
CurrentFile=get(handles.CurrentFile,'String');

%display the current element
root_element=get(t,root_uid);
uidparent=root_uid;
if isfield(root_element,'name')
    CurrentElement=root_element.name;
    while ~isequal(uidparent,1)%while the first level has not been reached
        uidparent=parent(t,uidparent);
        dirdat=get(t,uidparent);
        if isfield(dirdat,'name')                        
            CurrentElement=[dirdat.name '/' CurrentElement];
        end
    end
    set(handles.CurrentElement,'String',CurrentElement)
end
list_uid=children(t,root_uid);
%case of a single element
testsimple=0;
filedat=[];
if ~isempty(list_uid)
    filedat=get(t,list_uid(1))
    if isfield(filedat,'type') & isequal(filedat.type,'chardata') &isfield(filedat,'value')
        testsimple=1;%simple element
    end
end

%attributes of the current element
nbattrib= attributes(t,'length',root_uid);
testopen=0;
attr_col=[];
for iattr=1:nbattrib
    attr= attributes(t,'get',root_uid,iattr);
    if isequal(attr.key,'source')% look for 'source' attribute
        if isequal(attr.val,'file')%if the source is 'file', look for the path and open it
           if isfield(filedat,'type') & isequal(filedat.type,'chardata') &isfield(filedat,'value')
               cur_file=filedat.value;
               uidparent=root_uid;%initialization
               while ~isequal(uidparent,1)%while the first level has not been reached
                    uidparent=parent(t,uidparent);
                    dirdat=get(t,uidparent);
                    if isfield(dirdat,'type') & isequal(dirdat.type,'element') & isfield(dirdat,'name')
                        nbattrib_up= attributes(t,'length',uidparent);
                        for iattr_up=1:nbattrib_up
                            attr= attributes(t,'get',uidparent,iattr_up);
%                             if isequal(attr.key,'source')&isequal(attr.val,'directory')% look for 'source' attribute
                              if isequal(attr.key,'DirName')
                                 cur_file=fullfile(attr.val,cur_file);
                             end
                        end
                    end
               end
               RootPath=fileparts(CurrentFile);%path to the current .xml file
               cur_file=fullfile(RootPath,cur_file)
               set(handles.CurrentAttributes,'UserData',cur_file)%will be searched by uvmat
               [path,fil,ext]=fileparts(cur_file);
               if ~exist(cur_file,'file')
                   msgbox_uvmat('ERROR',['non-existent link file' cur_file]) % A FAIRE: propose to updtate the .xml file
                   return
               elseif isequal(ext,'.xml')
                   if ~isfield(Data,'UpFile')
                       Data.UpFile={CurrentFile};
                   else
                       Data.UpFile=[{CurrentFile};Data.UpFile];
                   end
                   set(heditxml,'UserData',Data)
                   set(handles.CurrentFile,'String',cur_file)
                   CurrentFile_Callback(handles.CurrentFile, [], handles)
               else
                   if isequal(get(heditxml,'Tag'),'browser'); %if editxml has been called as a browser
                       set(heditxml,'Tag','idle')% signal for uvmat browser
                   else
                       uvmat({cur_file}); %open the link fiel with uvmat
                   end
                   return
               end
           end
       %elseif isequal(attr.val,'dir') A FAIRE : check directory
       %else A FAIRE: edit the element
        end 
    end
    attr_col=strvcat(attr_col,[attr.key ' = ' attr.val]);
end
set(handles.CurrentAttributes,'String',attr_col)

%list subtree
if ~testsimple
    list_element=[];
%      Data.CurrentUid=[Data.CurrentUid root_uid]%record new current uid
	for iline=1:length(list_uid)
        element=get(t,list_uid(iline));
        if isfield(element,'type')&isequal(element.type,'element')
             list_element{iline,2}=element.name;
             child_uid=children(t,list_uid(iline));
             subelem=get(t,child_uid);
             if isfield(subelem,'type')& isfield(subelem,'value') & isequal(subelem.type,'chardata')
                data_read=subelem.value;
                list_element{iline,3}=['= ' data_read];
            end
            if iscell(subelem)|(isfield(subelem,'type')&isequal(subelem.type,'element'))
                list_element{iline,1}='+ ';%sign for subtree existence
            else
                list_element{iline,1}='  ';
            end
            nbattr=attributes(t,'length',list_uid(iline));
            if nbattr==1
                attr=attributes(t,'get',list_uid(iline));
                list_element{iline,4}=[attr.key '='];
                list_element{iline,5}=attr.val;
            elseif nbattr>1
                for iattr=1:nbattr
                    attr=attributes(t,'get',list_uid(iline),iattr);
                    list_element{iline,2+2*iattr}=[attr.key '='];
                    list_element{iline,3+2*iattr}=attr.val;
                end
            end
        end
	end
    set(handles.list_element,'Value',1)%select the first line of list_element by default
	set(handles.list_element,'String',cell2tab(list_element,' ') )
    list.uid=list_uid;
	set(handles.list_element,'UserData',list)
end
%---------------------------------------------------------
%-------------------------------------
%updates the interface
function update_ref_list(hh,xs_element,element,node,xs_subelem,subelem)
%-----------------------------
pref_col='';
key_col='';
equal_sign='';
val_col='';
for iline=1:length(subelem)
    xsindex=subelem(iline).xsindex;
    indexcur=subelem(iline).index;
    subuid=subelem(iline).uid;
        if isempty(subuid)
             RefDataIn.uid(iline)=0;
        else
             RefDataIn.uid(iline)=subuid;
        end
    index(iline)=indexcur;
    node(iline)=xs_subelem(xsindex).node;
%         testmanual(iline)=subelem(iline).testmanual;
    ikey=xs_subelem(xsindex).key;
    if xs_subelem(xsindex).testsub
        ival=[' + ' subelem(iline).val];
    else
        ival=[' = ' subelem(iline).val];
    end
    key_col=strvcat(key_col,ikey);
    val_col=strvcat(val_col,ival);
end
RefDataIn.xs_uid=node;
list_element=[key_col val_col];
siztext=size(list_element);
set(hh,'Value',[1:siztext(1)])
set(hh,'String',list_element)
set(hh,'UserData',RefDataIn)

% 
% function RefFile_Callback(hObject, eventdata, handles)
% global t_ref xs
% t_ref=xmltree(get(hObject,'String'));%open the xml file fileinput
% heditxml=get(hObject,'parent');
% DataIn=get(get(hObject,'parent'),'UserData');
% % set(heditxml,'Units','pixel')
% figpos=get(heditxml,'Position')
% % title_element=get(handles.element_cur,'UserDataIn');
% % xs_node=xsnode_index(1,ind);
% % index_chosen=xsnode_index(2,ind);
% if isfield(DataIn,'fig_ref')&ishandle(DataIn.fig_ref)
%     figure(DataIn.fig_ref);
% else
%     DataIn.fig_ref=figure;
% end
% set(DataIn.fig_ref,'Name',get(hObject,'String'))
% set(DataIn.fig_ref,'MenuBar','none')
% newfigpos=[figpos(1)+figpos(3) figpos(2)+0.4*figpos(4) 0.5*figpos(3) 0.3*figpos(4)];
% set(DataIn.fig_ref,'Units','normalized')
% set(DataIn.fig_ref,'Position',newfigpos)
% DataIn.h_ref=uicontrol('Style','listbox', 'Max',2,'Units','pixel','Position', [0 0 newfigpos(3) newfigpos(4)], ...
%         'FontName','FixedWidth','Tag','listbox'); 
% if isfield(DataIn,'xs_CurrentUid');
%     xs_CurrentUid=DataIn.xs_CurrentUid(end);
% else
%     DataIn.xs_CurrentUid=find(xs,'/xs:schema/xs:element');%uid of the root element in the schema
% end
% [nodeup,path,xs_element,xs_subelem]=scan_schema(xs,xs_CurrentUid(end));
% xs_element.key
% tag0=find(t_ref,['/' path '/' xs_element.key]);
% if length(tag0)>=1
%     CurrentRefNode=tag0(1);%chose the first occurence of the element
% else
%     CurrentRefNode=0;
% end
% [ref_element,ref_subelem]=get_xml(t_ref,path,xs_element,CurrentRefNode,xs_subelem);
% update_ref_list(DataIn.h_ref,xs_element,ref_element,CurrentRefNode,xs_subelem,ref_subelem);
% siztext=size(get(DataIn.h_ref,'String'));
% set(DataIn.h_ref,'Value',[1:siztext(1)]); %select the whole list by default
% set(heditxml,'UserData',DataIn)
% set(handles.ref_data,'Value',siztext(1)); %select the whole list by default
% 'TESTimport'
% title_element=get(handles.element_cur,'UserDataIn')
% xs_node=title_element.xsnode;%uid of the element in the schema
% node=title_element.node;
% t=flush(t,node);%removes the corresponding subtree in t
% [nodeup,path,xs_element,xs_subelem]=scan_schema(xs,xs_node);%scan the schema
% tag0=find(t_import,['/' path '/' xs_element.key])
% if isempty(tag)
%     errordlg(['element /' path '/' xs_element.key ' not found in' fileinput])
%     return
% end
% % [element_import,node_import]=get_xml(t_import,path,xs_element,1,xs_subelem);% read the corresponding xml data
% node2_import=children(t_import,tag0);
% % t_import=branch(t_import,node_import);% extract branch of the new file
% % %removes the corresponding subtree in t
% for inode=1:length(node2_import)
%     struct=get(t_import,node2_import(inode))
%     if isfield(struct,'type') & isfield(struct,'name')%if the node is an elmeent type
%         node3_import=children(t_import,node2_import(inode))
%        [t,newuid]=add(t,node,struct.type,struct.name);
%        for inode2=1:length(node3_import)
%            struct2=get(t_import,node3_import(inode2))
%            if isequal(struct2.type,'chardata')
%                 t=add(t,newuid,'chardata',struct2.value);
%             end
%         end
%     end
% end
% --- Executes on button press in replicate.
function replicate_Callback(hObject, eventdata, handles)
global xs  t

export_list=get(handles.export_list,'String');
export_val=get(handles.export_list,'UserData');
heditxml=get(handles.replicate,'parent');
Data=get(heditxml,'UserData')

hdataview=findobj(allchild(0),'Name','dataview')
if isempty(hdataview)
    hdataview=dataview;
    return
end
hhdataview=guidata(hdataview);
CurrentPath=get(hhdataview.CurrentFile,'String');
ListExperiments=get(hhdataview.ListExperiments,'String');
Value=get(hhdataview.ListExperiments,'Value');
if ~isequal(Value,1)
    ListExperiments=ListExperiments(Value);
end
ListDevices=get(hhdataview.ListDevices,'String');
Value=get(hhdataview.ListDevices,'Value');
if ~isequal(Value,1)
    ListDevices=ListDevices(Value);
end
ListRecords=get(hhdataview.ListRecords,'String');
Value=get(hhdataview.ListRecords,'Value');
if ~isequal(Value,1)
    ListRecords=ListRecords(Value);
end
% uvmat('runplus_Callback',hObject,eventdata,handleshaxes)
[ListDevices,ListRecords,ListXml,List]=ListDir(CurrentPath,ListExperiments,ListDevices,ListRecords);
ListXml=get(hhdataview.ListXml,'String');
Value=get(hhdataview.ListXml,'Value');
if isequal(Value,1)
    msgbox_uvmat('ERROR','you need to select the xml files to edit')
    return
end
ListXml=ListXml(Value);%list of 
for iexp=1:length(List.Experiment)
    ExpName=List.Experiment{iexp}.name;
    if isfield(List.Experiment{iexp},'Device')
        for idevice=1:length(List.Experiment{iexp}.Device)
            DeviceName=List.Experiment{iexp}.Device{idevice}.name;       
            if isfield(List.Experiment{iexp}.Device{idevice},'xmlfile')
                for ixml=1:length(List.Experiment{iexp}.Device{idevice}.xmlfile)
                    FileName=List.Experiment{iexp}.Device{idevice}.xmlfile{ixml};
                    for ilistxml=1:length(ListXml)
                        if isequal(FileName,ListXml{ilistxml})
                            xmlfullname=fullfile(CurrentPath,ExpName,DeviceName,FileName);
                            t_export=xmltree(xmlfullname);
                            rootelement=get(t_export,1,'name');
                            uidlist=Data.CurrentUid;
                            if isequal(rootelement,get(t,1,'name'))
                                backupfile=xmlfullname;
                                testexist=2;
                                while testexist==2
                                   backupfile=[backupfile '~'];
                                   testexist=exist(backupfile,'file');
                                end
                                [success,message]=copyfile(xmlfullname,backupfile);%make backup
                                if ~isequal(success,1)
                                    msgbox_uvmat('ERROR',['Error in the backup of ' xmlfullname])
                                    return
                                end
                                findstr=['/' rootelement];
                                uid_export(1)=1;
                                % fill the root elements if absent
                                for index=2:length(uidlist)
                                    name_t=get(t,uidlist(index),'name')
                                    findstr=[findstr '/' name_t]
                                    uid=find(t_export,findstr)
                                    if isempty(uid)
                                        [t_export,uid_export(index)]=add(t_export,uid_export(index-1),'element',name_t);
                                    else
                                        uid_export(index)=uid;
                                    end                           
                                end
                                % chardata......
                            end
                            break
                        end
                    end
%                     [Title,test]=check_heading(Currentpath,Campaign,ExpName,DeviceName,[],FileName,SubCampaignTest);
%                     if test
%                         [List.Experiment{iexp}.Device{idevice}.xmlfile{ixml} ' , Heading updated']
%                     end
                end
             elseif isfield(List.Experiment{iexp}.Device{idevice},'Record')
                for irecord=1:length(List.Experiment{iexp}.Device{idevice}.Record)
                    RecordName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.name;
                    if isfield(List.Experiment{iexp}.Device{idevice}.Record{irecord},'xmlfile')
                        for ixml=1:length(List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile)
                            FileName=List.Experiment{iexp}.Device{idevice}.Record{irecord}.xmlfile{ixml};
                            for ilistxml=1:length(ListXml)
                                if isequal(FileName,ListXml{ilistxml})
                                    xmlfullname=fullfile(CurrentPath,ExpName,DeviceName,RecordName,FileName)
                                    break
                                end
                            end
%                             [Title,test]=check_heading(Currentpath,Campaign,ExpName,DeviceName,RecordName,FileName,SubCampaignTest);
%                             if test
%                                 [FileName ' , Heading updated']
%                             end
                        end
                    end
                end
            end
        end
    end
end
return
%%%%%%%%%%% A REVOIR
% Copier la liste des elements selectionnés dans dataview
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ANCIEN:
heditxml=get(hObject,'parent');
DataIn=get(heditxml,'UserData');
if ~isfield(DataIn,'h_ref')
    DataIn.h_ref=[];
end
if ~ishandle(DataIn.h_ref)
    errordlg('no source file opened for import')
    return
end
%create the current root element if needed
LengthElement=length(DataIn.CurrentUid);
FilledUid=find(DataIn.CurrentUid~=0);
LengthFilled=FilledUid(end);
for irank=LengthFilled+1:LengthElement
    attrib=attributes(xs,'get',DataIn.xs_CurrentUid(irank),1);
    [t,DataIn.CurrentUid(irank)]=add(t,DataIn.CurrentUid(irank-1),'element',attrib.val);
end

%copy list of subelements
RefDataIn=get(DataIn.h_ref,'UserData');
list=get(handles.list_element,'UserData');%=,[node;index]
for ilist=get(DataIn.h_ref,'Value')
    node_content=get(xs,RefDataIn.xs_uid(ilist));
    if ~isempty(node_content) & isfield(node_content,'attributes')
        attrib=node_content.attributes;
        for iattr=1:length(attrib)
            struct=attrib{iattr};
            if isequal(struct.key,'name')
                key=struct.val; % read element key name
            end
        end
    end
    value='';
    if ~isequal(RefDataIn.uid(ilist),0)
        child_uid=children(t_ref,RefDataIn.uid(ilist));     
        if isequal(length(child_uid),1)
            content=get(t_ref,child_uid);
            if isfield(content,'type') &isfield(content,'value')& isequal(content.type,'chardata')
                value=content.value;
            end
        end
    end
    t=set_element(t,DataIn.CurrentUid(end),list.uid(ilist),key,value);
end
set(heditxml,'UserData',DataIn)
%update the current listing 
[nodeup,path,xs_element,xs_subelem]=scan_schema(xs,DataIn.xs_CurrentUid(end));
[element,subelem]=get_xml(t,path,xs_element,DataIn.CurrentUid(end),xs_subelem);
update_list(handles,path,xs_element,element,DataIn.CurrentUid(end),xs_subelem,subelem);
% t=set_xml(t,xs_DataIn,subelem)
%edit list of subelments:   

%A REVOIR
% xsnode_index=get(handles.list_element,'UserDataIn')
% xs_node=xsnode_index(1,ind);
% RefDataIn=get(handles.ref_data,'UserDataIn');
% subelem=RefDataIn.subelem;
% xsnode_index=get(handles.list_element,'UserDataIn');%data on the xs_nodes of the subelements
% ref_list=get(handles.ref_data,'Value');%selected indices in the list of reference subelements
% xs_node=xsnode_index(1,ref_list);%xs_nodes of the selected subelements
% % index_chosen=xsnode_index(2,ref_list);% indices in the list of occurence for a subelement
% % for ilist=ref_list
% ilist=1;
% while icontinue
%     'TESTCOPY'
%     [nodeup,path,xs_element,xs_subelem]=scan_schema(xs,xs_node(ilist))
%     xs_subelem.key
%     tsub=subelem(ilist).tsub
%     xsnode_index(2,ilist)
%     [ref_elem,ref_node,ref_subelem]=get_xml(tsub,'',xs_element,1,xs_subelem)
%     ref_subelem.val
%     testedit= ~isfield(element.attrup,'source') | isequal(element.attrup.source,'manual') %| element vide
%     
%     
%     icontinue=0
% end
% function [element,node,subelem]=get_xml(t,path,xs_element,node,xs_subelem)
% element.attr_key='';%default
% element.attr_val='';%default
% element.val='';
% % element.type='';
% % element.testmanual=testmanual %inheritates the input manual editing flag by default
% subelem=[]; %default
% attrup=[];
% % node=[];
% 
% % %find the element properties in the xml file
% if node >= 1
%     elem_struct=get(t,node);
%     if ~xs_element.subtest
%         elem_contents=get(t,elem_struct.contents);
%         if isempty(elem_contents)
%             element.val=[];
%         else
%             element.val=elem_contents.value
%         end
%     end
%     if isfield(elem_struct,'attributes')
%         elem_attr=elem_struct.attributes;
%         for iattr=1:length(elem_attr)
%             element.attr_key{iattr}=elem_attr{iattr}.key ;
%             element.attr_val{iattr}=elem_attr{iattr}.val;
% %             attrup=setfield(attrup,elem_attr{iattr}.key,elem_attr{iattr}.val);
%            breakdetect=find(elem_attr{iattr}.key=='/'| elem_attr{iattr}.key==':'| elem_attr{iattr}.key=='.');% find '/'
%            if isempty(breakdetect)
% %                 comline=['attrup.' elem_attr{iattr}.key '=' elem_attr{iattr}.val ';']
%                 eval(['attrup.' elem_attr{iattr}.key '=''' elem_attr{iattr}.val ''';'])
%            end
%         end
%     end
% end
% %get the parent node attributes 
% up=1
% if node>0
% 	nodeup=node;
% 	while up==1; 
%         nodeup=get(t,nodeup,'parent');%move up to the parent in the tree
%         if isempty(nodeup)
%             up=0;
%         else
%             nodeup_content=get(t,nodeup);
%             attrib=nodeup_content.attributes;
%             for iattr=1:length(attrib)
%                 key=attrib{iattr}.key;
%                 breakdetect=find(key=='/'| key==':'| key=='.');% find '/'
%                 if ~isfield(attrup,key) & isempty(breakdetect)
%                    eval(['attrup.' key '=''' attrib{iattr}.val ''';'])
%                 end
%             end
%         end
% 	end
% 	element.attrup=attrup;
% end
% %find the subelement properties in the xml file
% if xs_element.subtest
%    iline=0;
%    for k=1:length(xs_subelem)%node2: list of subelements in the sub-sequence
% %     attr=attributes(xs,'get',node2(i),1);% 
% %     element=attr.val;%name of the element 
%      tag=find(t,['/' path '/' xs_element.key '/' xs_subelem(k).key]);%look for the corresponding element node in the .xml tree
%      struct_element=get(t,tag);%get the content of the element
%      if isempty(struct_element) 
%          iline=iline+1;
%          subelem(iline).xsindex=k;
%          subelem(iline).index=0;
% %          subelem(iline).testmanual=element.testmanual;% inheritates the manual editing flag by default
%          if isequal(xs_subelem(k).minOccurs,0)
%              subelem(iline).val='[]';%element value not mandatory in the schema
%          else
%              subelem(iline).val='[MISSING]';%element value mandatory in the schema
%          end
% %          subelem(iline).attrup=attrup; %inheritated attributes
%      elseif isequal(length(struct_element),1)
%          contents=get(t,struct_element.contents);
%          iline=iline+1;
%          subelem(iline).xsindex=k;
%          subelem(iline).index=1;
% %          subelem(iline).testmanual=element.testmanual;%
%          if isfield(contents,'value') & ~isempty(contents.value)
%              subelem(iline).val=contents.value;
%          elseif xs_subelem(k).testsub
%              subelem(iline).val='';
%          elseif isequal(xs_subelem(k).minOccurs,0) 
%              subelem(iline).val='[]';%element value not mandatory in the schema
%          else
%              subelem(iline).val='[MISSING]';%element value mandatory in the schema
%          end
% %          subelem(iline).attrup=attrup; %inheritated attributes
%          if isfield(struct_element,'attributes')
%             element_attr=struct_element.attributes;
%             attr_display=[];
%             for iattr=1:length(element_attr)
% %                 attr_display{iline}=[attr_display ' , ' element_attr{iattr}.key '  =  ' element_attr{iattr}.val];
%                 subelem(iline).val=[subelem(iline).val attr_display ' , ' element_attr{iattr}.key '  =  ' element_attr{iattr}.val];
% %                 subelem(iline).attrup=setfield(subelem(iline).attrup,element_attr{iattr}.key,element_attr{iattr}.val);
%             end
%          end
%      else%case of a multiple element
%          for subindex=1:length(struct_element)
%              contents=get(t,struct_element{subindex}.contents);
%              iline=iline+1;
%              subelem(iline).index=subindex;%index of the element
%              subelem(iline).xsindex=k;
% %              subelem(iline).testmanual=element.testmanual;%
%              if isfield(contents,'value')& ~isempty(contents.value)
%                  subelem(iline).val=contents.value;
%              elseif xs_subelem(k).testsub
%                  subelem(iline).val='';
%              else
%                  subelem(iline).val='[]';
%              end
% %              subelem(iline).attrup=attrup; %inheritated attributes
%              if isfield(struct_element{subindex},'attributes')
%                 element_attr=struct_element{subindex}.attributes;
%                 attr_display=[];
%                 for iattr=1:length(element_attr)
% %                     attr_display{iline}=[attr_display ' , ' element_attr{iattr}.key '  =  ' element_attr{iattr}.val];
%                     subelem(iline).val=[subelem(iline).val attr_display ' , ' element_attr{iattr}.key '  =  ' element_attr{iattr}.val];
% %                     subelem(iline).attrup=setfield(subelem(iline).attrup,element_attr{iattr}.key,element_attr{iattr}.val);
%                 end
%             end
%         end
%      end
%   end
% end


% --- Executes on button press in HELP.
function HELP_Callback(hObject, eventdata, handles)
path_to_uvmat=which ('uvmat')% check the path of uvmat
pathelp=fileparts(path_to_uvmat);
helpfile=fullfile(pathelp,'UVMAT_DOC','uvmat_doc.html');
if isempty(dir(helpfile)), errordlg('Please put the help file uvmat_doc.html in the directory UVMAT/UVMAT_DOC')
else
web([helpfile '#editxml'])    
end


% --- Executes on button press in Export.
function Export_Callback(hObject, eventdata, handles)
val=get(handles.Export,'Value');
if val
    set(handles.Export,'BackgroundColor',[0 1 0])
    set(handles.export_list,'Visible','on')
    set(handles.replicate,'Visible','on')
    h_dataview=findobj(allchild(0),'name',dataview');
    if isempty(h_dataview)
       % CurrentFile=get(handles.CurrentFile,'String');
        dataview;
    end
else
     set(handles.Export,'BackgroundColor',[0.7 0.7 0.7])
    set(handles.export_list,'Visible','off')
    set(handles.replicate,'Visible','off')
end


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


