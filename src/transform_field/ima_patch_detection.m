% 'ima_edge_detection': find edges 

%------------------------------------------------------------------------
%%%%  Use the general syntax for transform fields with a single input and parameters %%%%
% OUTPUT: 
% DataOut:   output field structure 
%
%INPUT:
% DataIn:  input field structure
% Param: matlab structure whose field Param.TransformInput contains the filter parameters
%-----------------------------------

%=======================================================================
% Copyright 2008-2024, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) univ-grenoble-alpes.fr
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

function DataOut=ima_patch_detection(DataIn,Param)

%% request input parameters
if isfield(DataIn,'Action') && isfield(DataIn.Action,'RUN') && isequal(DataIn.Action.RUN,0)
    prompt = {'npx';'npy';'threshold'};
    dlg_title = 'get the filter size in x and y';
    num_lines= 3;
    def     = { '50';'50';'0.3'};
    if isfield(Param,'TransformInput')&&isfield(Param.TransformInput,'FilterBoxSize_x')&&...
            isfield(Param.TransformInput,'FilterBoxSize_y')&&isfield(Param.TransformInput,'LumThreshold')
        def={num2str(Param.TransformInput.FilterBoxSize_x);num2str(Param.TransformInput.FilterBoxSize_y);num2str(Param.TransformInput.LumThreshold)};
    end
    
    
    
    %% create the GUI set_threshold
    set(0,'Units','points')
    ScreenSize=get(0,'ScreenSize');% get the size of the screen, to put the fig on the upper right
    Width=350;% fig width in points (1/72 inch)
    Height=min(0.8*ScreenSize(4),300);
    Left=ScreenSize(3)- Width-40; %right edge close to the right, with margin=40
    Bottom=ScreenSize(4)-Height-40; %put fig at top right
    hfig=findobj(allchild(0),'Tag','set_threshold');
    if isempty(hfig)
        hfig=figure('name','set_threshold','tag','set_threshold','MenuBar','none','NumberTitle','off','Units',...
            'pixels','Position',[Left,Bottom,Width,Height],'DeleteFcn',@closefcn)%);
    else
        figure(hfig)
    end
    BackgroundColor=get(hfig,'Color');
    hh=0.14; % box height (relative)
    ii=0.01; % gap between uicontrols
    
    ww=(1-5*ii)/4; % box width (relative)
    % first raw of the GUI
    %Amask=imread('/fsnet/project/coriolis/2015/15MINI_MEDDY/0_REF_FILES/mask_patch.png');
    uicontrol('Style','text','Units','normalized', 'Position', [ii 0.95-2*ii-0.75*hh ww hh/2],'BackgroundColor',BackgroundColor,...
        'String','Threshold','FontUnits','points','FontSize',12,'FontWeight','bold','ForegroundColor','blue','HorizontalAlignment','right');%title
    % uicontrol('Style','edit','Units','normalized', 'Position', [2*ii+ww 0.95-2*ii-hh ww hh],'tag','num_Z_1','BackgroundColor',[1 1 1],...
    %     'String',num2str(SliceCoord(1,3)),'FontUnits','points','FontSize',12,'FontWeight','bold','TooltipString','''num_Z_1'': z position of first slice');%edit box
    hThreshold=uicontrol('Style','edit','Units','normalized', 'Position', [3*ii+2*ww 0.95-2*ii-hh ww hh],'tag','Threshold','BackgroundColor',[1 1 1],...
        'FontUnits','points','FontSize',12,'FontWeight','bold');%edit box
    uicontrol('Style','slider','Units','normalized', 'Position', [0.1 0.1 0.8 0.1],'tag','SetThreshold','BackgroundColor',[1 1 1],...
        'FontUnits','points','FontSize',12,'FontWeight','bold','Callback',@(hObject,eventdata)SetThreshold_Callback(hObject,eventdata));%edit box
  %  uiwait(hfig);
    %
    %
    %     DataOut.TransformInput.FilterBoxSize_x=str2num(answer{1}); %size of the filtering window
    %     DataOut.TransformInput.FilterBoxSize_y=str2num(answer{2}); %size of the filtering window
    DataOut.TransformInput.LumThreshold=str2num(get(hThreshold,'String')) %size of the filtering window
    
 
    
    return
end

DataOut=DataIn; %default
%Amask=imread('/fsnet/project/coriolis/2015/15MINI_MEDDY/0_REF_FILES/mask_patch.png');
hfig=findobj(allchild(0),'Tag','set_threshold');
hThreshold=findobj(hfig,'Tag','Threshold');
Threshold=str2num(get(hThreshold,'String'));
plot_mask(DataIn.A,Threshold)
% Athreshold=Param.TransformInput.LumThreshold;
% %
% %     DataOut.A=zeros(size(DataIn.A,1),size(DataIn.A,2),3);
% DataOut.A=(DataIn.A>Athreshold);%transform to the initial image format
% %     DataOut.A(:,:,1)=DataIn.A;%transform to the initial image format, red
% STATS = regionprops(DataOut.A, 'FilledArea','MinorAxisLength','MajorAxisLength','PixelIdxList');
% Area=zeros(size(STATS));
% for iobj=1:numel(STATS)
%     Area(iobj)=STATS(iobj).FilledArea;
% end
% [Area, main_obj]=max(Area);
% MajorAxisLength=STATS(main_obj).MajorAxisLength
% MinorAxisLength=STATS(main_obj).MinorAxisLength
% for iobj=1:numel(STATS)
%     if iobj~=main_obj
%         DataOut.A(STATS(iobj).PixelIdxList)=0;
%     end
% end
% 
% DataOut.A=Amax*DataOut.A;


%------------------------------------------------------------------------
% function called by selecting CheckRefraction in the GUI set_slices
function SetThreshold_Callback(hObject,eventdata)
%------------------------------------------------------------------------
hfig=get(hObject,'parent');
hThreshold=findobj(hfig,'Tag','Threshold');
Threshold=get(hObject,'Value');

huvmat=findobj(allchild(0),'Tag','uvmat');
hhuvmat=guidata(huvmat);
UvData=get(huvmat,'UserData');
Amax=max(max(UvData.Field.A));
Amin=min(min(UvData.Field.A));
Threshold=Amin+(Amax-Amin)*Threshold;
set(hThreshold,'String',num2str(Threshold))

plot_mask(UvData.Field.A,Threshold)

UvData.XmlData{1}.TransformInput.LumThreshold=Threshold;
set(huvmat,'UserData',UvData)






% h_refraction(1)=findobj(hset_slice,'String','surface');
% h_refraction(2)=findobj(hset_slice,'Tag','num_H');
% h_refraction(3)=findobj(hset_slice,'String','index');
% h_refraction(4)=findobj(hset_slice,'Tag','num_RefractionIndex');
% if isequal(get(hObject,'Value'),1)
%     set(h_refraction,'Visible','on')
% else
%     set(h_refraction,'Visible','off')
% end

function plot_mask(A,Threshold)
    
A=(A>Threshold) ;%& Amask>100;%transform to binary image format
try
    STATS = regionprops(A, 'FilledArea','MinorAxisLength','MajorAxisLength','PixelIdxList');
    Area=zeros(size(STATS));
    for iobj=1:numel(STATS)
        Area(iobj)=STATS(iobj).FilledArea;
    end
    [Area, main_obj]=max(Area);
    MajorAxisLength=STATS(main_obj).MajorAxisLength;
    MinorAxisLength=STATS(main_obj).MinorAxisLength;
    for iobj=1:numel(STATS)
        if iobj~=main_obj
            A(STATS(iobj).PixelIdxList)=0;
        end
    end
catch ME
    disp('image toolbox not available, skipped')
end
[npy,npx]=size(A);
A=cat(3,A,zeros(npy,npx,2));% make a color image

huvmat=findobj(allchild(0),'Tag','uvmat');
hhuvmat=guidata(huvmat);
hmask=findobj(hhuvmat.PlotAxes,'Tag','MaskFig')
if isempty(hmask)
    axes(hhuvmat.PlotAxes)
    hold on
    imagesc([0.5 npx],[npy-0.5 0.5],A,'AlphaData',0.2,'Tag','MaskFig')
else
    set(hmask,'CData',A)
    set(hmask,'AlphaData',0.2)
end


function closefcn(hObject,eventdata)

huvmat=findobj(allchild(0),'Tag','uvmat');
hhuvmat=guidata(huvmat);
hmask=findobj(hhuvmat.PlotAxes,'Tag','MaskFig')
if ~isempty(hmask)
   delete(hmask)
end