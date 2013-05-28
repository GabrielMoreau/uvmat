%'plot_field': plot any field with the structure defined in the uvmat package
%------------------------------------------------------------------------
%
%  This function is used by uvmat to plot fields. It automatically chooses the representation 
% appropriate to the input field structure: 
%     2D vector fields are represented by arrows, 2D scalar fields by grey scale images or contour plots, 1D fields are represented by usual plot with (abscissa, ordinate).
%  The input field structure is first tested by check_field_structure.m,
%  then split into blocks of related variables  by find_field_cells.m.
%  The dimensionality of each block is obtained  by this function
%  considering the presence of variables with the attribute .Role='coord_x'
%  and/or coord_y and/or coord_z (case of unstructured coordinates), or
%  dimension variables (case of matrices). 
%
% function [PlotType,PlotParamOut,haxes]= plot_field(Data,haxes,PlotParam,PosColorbar)
%
% OUPUT:
% PlotType: type of plot: 'text','line'(curve plot),'plane':2D view,'volume'
% PlotParamOut: structure, representing the updated  plotting parameters, in case of automatic scaling
% haxes: handle of the plotting axis, when a new figure is created.
%
%INPUT
%    Data:   structure describing the field to plot 
%         (optional) .ListGlobalAttribute: cell listing the names of the global attributes
%                    .Att_1,Att_2... : values of the global attributes
%         (requested)  .ListVarName: list of variable names to select (cell array of  char strings {'VarName1', 'VarName2',...} ) 
%         (requested)  .VarDimName: list of dimension names for each element of .ListVarName (cell array of string cells)
%                      .VarAttribute: cell of attributes for each element of .ListVarName (cell array of structures of the form VarAtt.key=value)
%         (requested) .Var1, .Var2....: variables (Matlab arrays) with names listed in .ListVarName
%  
%            Variable attribute .Role :
%    The only variable attribute used for plotting purpose is .Role which can take
%    the values
%       Role = 'scalar':  (default) represents a scalar field
%            = 'coord_x', 'coord_y',  'coord_z': represents a separate set of
%                        unstructured coordinate x, y  or z
%            = 'vector': represents a vector field whose number of components
%                is given by the last dimension (called 'nb_dim')
%            = 'vector_x', 'vector_y', 'vector_z'  :represents the x, y or z  component of a vector  
%            = 'warnflag' : provides a warning flag about the quality of data in a 'Field', default=0, no warning
%            = 'errorflag': provides an error flag marking false data,
%                   default=0, no error. Different non zero values can represent different criteria of elimination.
%
%   haxes: handle of the plotting axes to update with the new plot. If this input is absent or not a valid axes handle, a new figure is created.
%
%   PlotParam: structure containing the parameters for plotting, as read on the uvmat or view_field GUI (by function 'read_GUI.m').
%      Contains three substructures:
%     .Coordinates: coordinate parameters:
%           .CheckFixLimits:=0 (default) adjust axes limit to the X,Y data, =1: preserves the previous axes limits
%     .Coordinates.CheckFixAspectRatio: =0 (default):automatic adjustment of the graph, keep 1 to 1 aspect ratio for x and y scales. 
%     .Coordinates.AspectRatio: imposed aspect ratio y/x of axis unit plots
%            --scalars--
%    .Scalar.MaxA: upper bound (saturation color) for the scalar representation, max(field) by default
%    .Scalar.MinA: lower bound (saturation) for the scalar representation, min(field) by default
%    .Scalar.CheckFixScal: =0 (default) lower and upper bounds of the scalar representation set to the min and max of the field
%               =1 lower and upper bound imposed by .AMax and .MinA
%    .Scalar.CheckBW= 1: black and white representation imposed, =0 color imposed (color scale or rgb),
%                   =[]: automatic (B/W for integer positive scalars, color  else)
%    .Scalar.CheckContours= 1: represent scalars by contour plots (Matlab function 'contour'); =0 by default
%    .IncrA : contour interval
%            -- vectors--
%    .Vectors.VecScale: scale for the vector representation
%    .Vectors.CheckFixVec: =0 (default) automatic length for vector representation, =1: length set by .VecScale
%    .Vectors.CheckHideFalse= 0 (default) false vectors represented in magenta, =1: false vectors not represented;
%    .Vectors.CheckHideWarning= 0 (default) vectors marked by warnflag~=0 marked in black, 1: no warning representation;
%    .Vectors.CheckDecimate4 = 0 (default) all vectors reprtesented, =1: half of  the vectors represented along each coordinate
%         -- vector color--
%    .Vectors.ColorCode= 'black','white': imposed color  (default ='blue')
%                        'rgb', : three colors red, blue, green depending
%                        on thresholds .colcode1 and .colcode2 on the input  scalar value (C)
%                        'brg': like rgb but reversed color order (blue, green, red)
%                        '64 colors': continuous color from blue to red (multijet)
%    .Vectors.colcode1 : first threshold for rgb, first value for'continuous' 
%    .Vectors.colcode2 : second threshold for rgb, last value (saturation) for 'continuous' 
%    .Vectors.CheckFixedCbounds;  =0 (default): the bounds on C representation are min and max, =1: they are fixed by .Minc and .MaxC
%    .Vectors.MinC = imposed minimum of the scalar field used for vector color;
%    .Vectors.MaxC = imposed maximum of the scalar field used for vector color;
%
% PosColorbar: % if absent, no action on colorbar
%              % if empty, suppress any existing colorbar
%              % if not empty, display a colorbar for B&W images at position PosColorbar
%                expressed in figure relative unit (ex [0.821 0.471 0.019 0.445])

%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function [PlotType,PlotParamOut,haxes]= plot_field(Data,haxes,PlotParam,PosColorbar)

%% default input and output
if ~exist('PlotParam','var'),PlotParam=[];end;
PlotType='text'; %default
if ~isfield(PlotParam,'Coordinates')
    PlotParam.Coordinates=[];
    if isfield(Data,'CoordUnit')
        PlotParam.Coordinates.CheckFixAspectRatio=1;
        PlotParam.Coordinates.AspectRatio=1; %set axes equal by default if CoordUnit is defined
    end
end
PlotParamOut=PlotParam;%default

%% check input structure
index_2D=[];
index_1D=[];
index_0D=[];
% check the cells of fields :
[CellInfo,NbDimArray,errormsg]=find_field_cells(Data);
%[CellVarIndex,NbDim,CoordType,VarRole,errormsg]=find_field_cells(Data);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['input of plot_field/find_field_cells: ' errormsg]);
    return
end

index_3D=find(NbDimArray>2,1);
if ~isempty(index_3D)
    msgbox_uvmat('ERROR','volume plot not implemented yet');
    return
end
index_2D=find(NbDimArray==2);%find 2D fields
index_1D=find(NbDimArray==1);
index_0D=find(NbDimArray==0);

%% test axes and figure
testnewfig=1;%test to create a new figure (default)
testzoomaxes=0;%test for the existence of a zoom secondary figure attached to the plotting axes
if exist('haxes','var')
    if ishandle(haxes)
        if isequal(get(haxes,'Type'),'axes')
            testnewfig=0;
            AxeData=get(haxes,'UserData');
            if isfield(AxeData,'ZoomAxes')&& ishandle(AxeData.ZoomAxes)
                if isequal(get(AxeData.ZoomAxes,'Type'),'axes')
                    testzoomaxes=1;
                    zoomaxes=AxeData.ZoomAxes;
                end
            end
        end
    end
end

%% create a new figure and axes if the plotting axes does not exist
if testnewfig
    hfig=figure;
    set(hfig,'Units','normalized')
    haxes=axes;
    set(haxes,'position',[0.13,0.2,0.775,0.73])
    PlotParamOut.NextPlot='add'; %parameter for plot_profile 
else
    hfig=get(haxes,'parent');
    set(0,'CurrentFigure',hfig)% the parent of haxes becomes the current figure
    set(hfig,'CurrentAxes',haxes)%  haxes becomes the current axes of the parent figure
end

%% set axes properties
if isfield(PlotParamOut.Coordinates,'CheckFixLimits') && isequal(PlotParamOut.Coordinates.CheckFixLimits,1)  %adjust the graph limits
    set(haxes,'XLimMode', 'manual')
    set(haxes,'YLimMode', 'manual')
else
    set(haxes,'XLimMode', 'auto')
    set(haxes,'YLimMode', 'auto')
end
% if ~isfield(PlotParam.Coordinates,'CheckFixAspectRatio')&& isfield(Data,'CoordUnit')
%     PlotParam.Coordinates.CheckFixAspectRatio=1;% if CoordUnit is defined, the two coordiantes should be plotted with equal scale by default
% end
errormsg='';
%PlotParamOut.Coordinates=[]; %default output 
AxeData=get(haxes,'UserData');

%% 2D plots 
if isempty(index_2D)
    plot_plane([],[],haxes,[],[]);%removes images or vector plots in the absence of 2D field plot
else  %plot 2D field
    if ~exist('PosColorbar','var'),PosColorbar=[];end;
    [tild,PlotParamOut,PlotType,errormsg]=plot_plane(Data,CellInfo(index_2D),haxes,PlotParamOut,PosColorbar);
    AxeData.NbDim=2;
    if testzoomaxes && isempty(errormsg)
        [zoomaxes,PlotParamOut,tild,errormsg]=plot_plane(Data,CellInfo(index_2D),zoomaxes,PlotParamOut,PosColorbar);
        AxeData.ZoomAxes=zoomaxes;
    end
end

%% 1D plot (usual graph y vs x)
if isempty(index_1D)
    if ~isempty(haxes)
        plot_profile([],[],haxes);%removes usual praphs y vs x in the absence of 1D field plot
    end
else %plot 1D field (usual graph y vs x)
    CheckHold=0;
    if isfield(PlotParam,'CheckHold') 
        CheckHold= PlotParam.CheckHold;
    end       
    PlotParamOut.Coordinates=plot_profile(Data,CellInfo(index_1D),haxes,PlotParamOut.Coordinates,CheckHold);%
    if testzoomaxes
        [zoomaxes,PlotParamOut.Coordinates]=plot_profile(Data,CellInfo(index_1D),zoomaxes,PlotParamOut.Coordinates,CheckHold);
        AxeData.ZoomAxes=zoomaxes;
    end
    PlotType='line';
end

%% text display
if isempty(index_2D) && isempty(index_1D)%text display alone
    htext=findobj(hfig,'Tag','TableDisplay');
else  %text display added to plot
    htext=findobj(hfig,'Tag','text_display');
end
if ~isempty(htext)
    if isempty(index_0D)
        if strcmp(get(htext,'Type'),'uitable')
            set(htext,'Data',{})
        else
            set(htext,'String',{''})
        end
    else
        [errormsg]=plot_text(Data,CellInfo(index_0D),htext);
    end
end

%% display error message
if ~isempty(errormsg)
    msgbox_uvmat('ERROR', errormsg)
end

%% update the parameters stored in AxeData
if ishandle(haxes)&&( ~isempty(index_2D)|| ~isempty(index_1D))
%     AxeData=[];
    if isfield(PlotParamOut,'MinX')
        AxeData.RangeX=[PlotParamOut.MinX PlotParamOut.MaxX];
        AxeData.RangeY=[PlotParamOut.MinY PlotParamOut.MaxY];
    end
    set(haxes,'UserData',AxeData)
end

%% update the plotted field stored in parent figure
if ~isempty(index_2D)|| ~isempty(index_1D)
    FigData=get(hfig,'UserData');
    if strcmp(get(hfig,'tag'),'view_field')||strcmp(get(hfig,'tag'),'uvmat')
        FigData.(get(haxes,'tag'))=Data;
        set(hfig,'UserData',FigData)
    end
end

%-------------------------------------------------------------------
function errormsg=plot_text(FieldData,CellInfo,htext)
%-------------------------------------------------------------------
errormsg='';
txt_cell={};
Data={};
for icell=1:length(CellInfo)
    
    % select types of  variables to be projected
    ListProj={'VarIndex_scalar','VarIndex_image','VarIndex_color','VarIndex_vector_x','VarIndex_vector_y'};
    check_proj=false(size(FieldData.ListVarName));
    for ilist=1:numel(ListProj)
        if isfield(CellInfo{icell},ListProj{ilist})
            check_proj(CellInfo{icell}.(ListProj{ilist}))=1;
        end
    end
    VarIndex=find(check_proj);
    %
    %     VarIndex=CellInfo{icell}.VarIndex;%  indices of the selected variables in the list data.ListVarName
    %     for ivar=1:length(VarIndex)
    %         checkancillary=0;
    %         if length(FieldData.VarAttribute)>=VarIndex(ivar)
    %             VarAttribute=FieldData.VarAttribute{VarIndex(ivar)};
    %             if isfield(VarAttribute,'Role')&&(strcmp(VarAttribute.Role,'ancillary')||strcmp(VarAttribute.Role,'coord_tps')...
    %                     ||strcmp(VarAttribute.Role,'vector_x_tps')||strcmp(VarAttribute.Role,'vector_y_tps'))
    %                 checkancillary=1;
    %             end
    %         end
    %         if ~checkancillary% does not display variables with attribute '.Role=ancillary'
    for ivar=1:length(VarIndex)
    VarName=FieldData.ListVarName{VarIndex(ivar)};
    VarValue=FieldData.(VarName);
    if isvector(VarValue')
        VarValue=VarValue';% put the different values on a line
    end
    if numel(VarValue)>1 && numel(VarValue)<10
        for ind=1:numel(VarValue)
            VarNameCell{1,ind}=[VarName '_' num2str(ilist)];
        end
    else
        VarNameCell={VarName};
    end
    if numel(VarValue)<10
        if isempty(VarValue)
            VarValueCell={'[]'};
        else
            VarValueCell=num2cell(VarValue);
        end
        if isempty(Data)
            Data =[VarNameCell; VarValueCell];
        else
            Data =[Data [VarNameCell; VarValueCell]];
        end
    else
        if isempty(Data)
            Data =[VarNameCell; num2cell(VarValue)];
        else
        Data =[Data [VarNameCell; {['size ' num2str(size(VarValue))]}]];
        end
    end
    if size(VarValue,1)==1
        txt=[VarName '=' num2str(VarValue)];
        txt_cell=[txt_cell;{txt}];
    end
    end
end
if strcmp(get(htext,'Type'),'uitable')
    get(htext,'ColumnName')
    set(htext,'ColumnName',Data(1,:))
    set(htext,'Data',Data(2:end,:))
else
    set(htext,'String',txt_cell)
    set(htext,'UserData',txt_cell)% for storage during mouse display
end


%-------------------------------------------------------------------
function CoordinatesOut=plot_profile(data,CellInfo,haxes,Coordinates,CheckHold)
%-------------------------------------------------------------------

%% initialization
if ~exist('Coordinates','var')
    Coordinates=[];
end
CoordinatesOut=Coordinates; %default
hfig=get(haxes,'parent');
legend_str={};

%% suppress existing plot if empty data
if isempty(data)
    hplot=findobj(haxes,'tag','plot_line');
    if ~isempty(hplot)
        delete(hplot)
    end
    hlegend=findobj(hfig,'tag','legend');
    if ~isempty(hlegend)
        delete(hlegend)
    end
    return
end

%% set the colors of the successive plots (designed to produce rgb for the three components of color images)
ColorOrder=[1 0 0;0 0.5 0;0 0 1;0 0.75 0.75;0.75 0 0.75;0.75 0.75 0;0.25 0.25 0.25];
set(haxes,'ColorOrder',ColorOrder)
% if isfield(Coordinates,'NextPlot')
%     set(haxes,'NextPlot',Coordinates.NextPlot)
% end
if CheckHold
     set(haxes,'NextPlot','add')
else
    set(haxes,'NextPlot','replace')
end

%% prepare the string for plot command
plotstr='hhh=plot(';
% coord_x_index=[];
xtitle='';
ytitle='';
test_newplot=~CheckHold;
MinX=[];
MaxX=[];
MinY_cell=[];
MaxY_cell=[];
%loop on input  fields
for icell=1:numel(CellInfo)
    VarIndex=CellInfo{icell}.VarIndex;%  indices of the selected variables in the list data.ListVarName
    coord_x_index=CellInfo{icell}.CoordIndex;
    testplot=ones(size(data.ListVarName));%default test for plotted variables
    coord_x_name{icell}=data.ListVarName{coord_x_index};
    coord_x{icell}=data.(data.ListVarName{coord_x_index});%coordinate variable set as coord_x
    if isempty(find(strcmp(coord_x_name{icell},coord_x_name(1:end-1)), 1)) %xtitle not already selected
        xtitle=[xtitle coord_x_name{icell}];
        if isfield(data,'VarAttribute')&& numel(data.VarAttribute)>=coord_x_index && isfield(data.VarAttribute{coord_x_index},'units')
            xtitle=[xtitle '(' data.VarAttribute{coord_x_index}.units '), '];
        else
            xtitle=[xtitle ', '];
        end
    end
    MinX(icell)=min(coord_x{icell});
    MaxX(icell)=max(coord_x{icell});
    testplot(coord_x_index)=0;
    if isfield(CellInfo{icell},'VarIndex_ancillary')
        testplot(CellInfo{icell}.VarIndex_ancillary)=0;
    end
    if isfield(CellInfo{icell},'VarIndex_warnflag')
        testplot(CellInfo{icell}.VarIndex_warnflag)=0;
    end
    if isfield(data,'VarAttribute')
        VarAttribute=data.VarAttribute;
        for ivar=1:length(VarIndex)
            if length(VarAttribute)>=VarIndex(ivar) && isfield(VarAttribute{VarIndex(ivar)},'long_name')
                plotname{VarIndex(ivar)}=VarAttribute{VarIndex(ivar)}.long_name;
            else
                plotname{VarIndex(ivar)}=data.ListVarName{VarIndex(ivar)};%name for display in plot A METTRE
            end
        end
    end
    if isfield(CellInfo{icell},'VarIndex_discrete')
        charplot_0='''+''';
    else
        charplot_0='''-''';
    end
    MinY=[];
    MaxY=[];%default
    
    nbplot=0;
    for ivar=1:length(VarIndex)
        if testplot(VarIndex(ivar))
            VarName=data.ListVarName{VarIndex(ivar)};
            nbplot=nbplot+1;
            ytitle=[ytitle VarName];
            if isfield(data,'VarAttribute')&& numel(data.VarAttribute)>=VarIndex(ivar) && isfield(data.VarAttribute{VarIndex(ivar)},'units')
                ytitle=[ytitle '(' data.VarAttribute{VarIndex(ivar)}.units '), '];
            else
                ytitle=[ytitle ', '];
            end
            eval(['data.' VarName '=squeeze(data.' VarName ');'])
            MinY(ivar)=min(min(data.(VarName)));
            MaxY(ivar)=max(max(data.(VarName)));
            plotstr=[plotstr 'coord_x{' num2str(icell) '},data.' VarName ',' charplot_0 ','];
            eval(['nbcomponent2=size(data.' VarName ',2);']);
            eval(['nbcomponent1=size(data.' VarName ',1);']);
            if numel(coord_x{icell})==2
                coord_x{icell}=linspace(coord_x{icell}(1),coord_x{icell}(2),nbcomponent1);
            end
            if nbcomponent1==1|| nbcomponent2==1
                legend_str=[legend_str {VarName}]; %variable with one component
            else  %variable with severals  components
                for ic=1:min(nbcomponent1,nbcomponent2)
                    legend_str=[legend_str [VarName '_' num2str(ic)]]; %variable with severals  components
                end                                                   % labeled by their index (e.g. color component)
            end
        end
    end
    if ~isempty(MinY)
    MinY_cell(icell)=min(MinY);
    MaxY_cell(icell)=max(MaxY);
    end
end

%% activate the plot
if  ~isequal(plotstr,'hhh=plot(')  
    set(hfig,'CurrentAxes',haxes)
    tag=get(haxes,'tag');    
    %%%
    plotstr=[plotstr '''tag'',''plot_line'');'];   
    eval(plotstr)                  %execute plot (instruction  plotstr)
    %%%
    set(haxes,'tag',tag)
    grid(haxes, 'on')
    hxlabel=xlabel(xtitle(1:end-2));% xlabel (removes ', ' at the end)
    set(hxlabel,'Interpreter','none')% desable tex interpreter
    if length(legend_str)>=1
        hylabel=ylabel(ytitle(1:end-2));% ylabel (removes ', ' at the end)
        set(hylabel,'Interpreter','none')% desable tex interpreter
    end
    if ~isempty(legend_str)
        hlegend=findobj(hfig,'Tag','legend');
        if isempty(hlegend)
            hlegend=legend(legend_str);
            txt=ver('MATLAB');
            Release=txt.Release;
            relnumb=str2double(Release(3:4));% should be changed to Version for better compatibility
            if relnumb >= 14
                set(hlegend,'Interpreter','none')% desable tex interpreter
            end
        else
            legend_old=get(hlegend,'String');
            if isequal(size(legend_old,1),size(legend_str,1))&&~isequal(legend_old,legend_str)
                set(hlegend,'String',[legend_old legend_str]);
            end
        end 
    end
    title_str='';
    if isfield(data,'filename')
       [Path, title_str, ext]=fileparts(data.filename);
       title_str=[title_str ext];
    end
    if isfield(data,'Action')&&isfield(data.Action,'ActionName')
        if ~isequal(title_str,'')
            title_str=[title_str ', '];
        end
        title_str=[title_str data.Action.ActionName];
    end
    htitle=title(title_str);
    set(htitle,'Interpreter','none')% desable tex interpreter
end

%% determine axes bounds
fix_lim=isfield(Coordinates,'CheckFixLimits') && Coordinates.CheckFixLimits;
check_lim=isfield(Coordinates,'MinX')&&isfield(Coordinates,'MaxX')&&isfield(Coordinates,'MinY')&&isfield(Coordinates,'MaxY');
if fix_lim
    if ~check_lim
        fix_lim=0; %free limits if limits are not set,
    end 
end
if fix_lim
    set(haxes,'XLim',[Coordinates.MinX Coordinates.MaxX])
    set(haxes,'YLim',[Coordinates.MinY Coordinates.MaxY])
else
    if ~isempty(MinX)
        if check_lim
            CoordinatesOut.MinX=min(min(MinX),CoordinatesOut.MinX);
            CoordinatesOut.MaxX=max(max(MaxX),CoordinatesOut.MaxX);
        else
            CoordinatesOut.MinX=min(MinX);
            CoordinatesOut.MaxX=max(MaxX);
        end
    end
    if ~isempty(MinY_cell)
        if check_lim
            CoordinatesOut.MinY=min(min(MinY_cell),CoordinatesOut.MinY);
            CoordinatesOut.MaxY=max(max(MaxY_cell),CoordinatesOut.MaxY);
        else
            CoordinatesOut.MinY=min(MinY_cell);
            CoordinatesOut.MaxY=max(MaxY_cell);
        end
    end
end

%% determine plot aspect ratio
if isfield(Coordinates,'CheckFixAspectRatio') && isequal(Coordinates.CheckFixAspectRatio,1)&&isfield(Coordinates,'AspectRatio')
    set(haxes,'DataAspectRatioMode','manual')
    set(haxes,'DataAspectRatio',[Coordinates.AspectRatio 1 1])
else
    set(haxes,'DataAspectRatioMode','auto')%automatic aspect ratio
    AspectRatio=get(haxes,'DataAspectRatio');
    CoordinatesOut.AspectRatio=AspectRatio(1)/AspectRatio(2);
end

%-------------------------------------------------------------------
function [haxes,PlotParamOut,PlotType,errormsg]=plot_plane(Data,CellInfo,haxes,PlotParam,PosColorbar)
%-------------------------------------------------------------------

grid(haxes, 'off')% remove grid (possibly remaining from other graphs)
%default plotting parameters
PlotType='plane';%default
% if ~exist('PlotParam','var')
%     PlotParam=[];
% end

if ~isfield(PlotParam,'Scalar')
    PlotParam.Scalar=[];
end
if ~isfield(PlotParam,'Vectors')
    PlotParam.Vectors=[];
end

PlotParamOut=PlotParam;%default
hfig=get(haxes,'parent');
hcol=findobj(hfig,'Tag','Colorbar'); %look for colorbar axes
hima=findobj(haxes,'Tag','ima');% search existing image in the current axes
errormsg='';%default
test_ima=0; %default: test for image or map plot
test_vec=0; %default: test for vector plots
test_black=0;
test_false=0;
test_C=0;
XName='';
x_units='';
YName='';
y_units='';
for icell=1:numel(CellInfo) % length(CellVarIndex) =1 or 2 (from the calling function)
%     VarRole=CellInfo{icell};
    if strcmp(CellInfo{icell}.CoordType,'tps') %do not plot directly tps data (used for projection only)
        continue
    end
    ivar_X=CellInfo{icell}.CoordIndex(end); % defines (unique) index for the variable representing unstructured x coordinate (default =[])
    ivar_Y=CellInfo{icell}.CoordIndex(end-1); % defines (unique)index for the variable representing unstructured y coordinate (default =[])
    ivar_C=[];
    if isfield(CellInfo{icell},'VarIndex_scalar')
        ivar_C=[ivar_C CellInfo{icell}.VarIndex_scalar];
    end
    if isfield(CellInfo{icell},'VarIndex_image')
        ivar_C=[ivar_C CellInfo{icell}.VarIndex_image];
    end
    if isfield(CellInfo{icell},'VarIndex_color')
        ivar_C=[ivar_C CellInfo{icell}.VarIndex_color];
    end
    if isfield(CellInfo{icell},'VarIndex_ancillary')
        ivar_C=[ivar_C CellInfo{icell}.VarIndex_ancillary];
    end
    if numel(ivar_C)>1
        errormsg= 'error in plot_field: too many scalar inputs';
        return
    end
    ivar_F=[];
    if isfield(CellInfo{icell},'VarIndex_warnflag')
    ivar_F=CellInfo{icell}.VarIndex_warnflag; %defines index (unique) for warning flag variable
    end
    ivar_FF=[];
    if isfield(CellInfo{icell},'VarIndex_errorflag')
    ivar_FF=CellInfo{icell}.VarIndex_errorflag; %defines index (unique) for error flag variable
    end
    if isfield(CellInfo{icell},'VarIndex_vector_x')&&isfield(CellInfo{icell},'VarIndex_vector_y') % vector components detected
        if test_vec
            errormsg='error in plot_field: attempt to plot two vector fields: to get the difference project on a plane with mode interp';
            return
        else
            test_vec=1;
            vec_U=Data.(Data.ListVarName{CellInfo{icell}.VarIndex_vector_x}); 
            vec_V=Data.(Data.ListVarName{CellInfo{icell}.VarIndex_vector_y});
            if strcmp(CellInfo{icell}.CoordType,'scattered')%2D field with unstructured coordinates 
                XName=Data.ListVarName{CellInfo{icell}.CoordIndex(end)};
                YName=Data.ListVarName{CellInfo{icell}.CoordIndex(end-1)};
                vec_X=reshape(Data.(XName),[],1); %transform vectors in column matlab vectors
                vec_Y=reshape(Data.(YName),[],1);
            elseif strcmp(CellInfo{icell}.CoordType,'grid')%2D field with structured coordinates 
                y=Data.(Data.ListVarName{CellInfo{icell}.CoordIndex(end-1)});
                x=Data.(Data.ListVarName{CellInfo{icell}.CoordIndex(end)});
                if numel(y)==2 % y defined by first and last values on aregular mesh
                    y=linspace(y(1),y(2),size(vec_U,1));
                end
                if numel(x)==2 % y defined by first and last values on aregular mesh
                    x=linspace(x(1),x(2),size(vec_U,2));
                end
                [vec_X,vec_Y]=meshgrid(x,y);  
            end
            if isfield(PlotParam.Vectors,'ColorScalar') && ~isempty(PlotParam.Vectors.ColorScalar)
                [VarVal,ListVarName,VarAttribute,errormsg]=calc_field_interp([],Data,PlotParam.Vectors.ColorScalar);
                if ~isempty(VarVal)
                    vec_C=reshape(VarVal{1},1,numel(VarVal{1}));
                    test_C=1;
                end
            end
            if ~isempty(ivar_F)%~(isfield(PlotParam.Vectors,'HideWarning')&& isequal(PlotParam.Vectors.HideWarning,1)) 
                if test_vec 
                    vec_F=Data.(Data.ListVarName{ivar_F}); % warning flags for  dubious vectors
                    if  ~(isfield(PlotParam.Vectors,'CheckHideWarning') && isequal(PlotParam.Vectors.CheckHideWarning,1)) 
                        test_black=1;
                    end
                end
            end
            if ~isempty(ivar_FF) %&& ~test_false
                if test_vec% TODO: deal with FF for structured coordinates
                    vec_FF=Data.(Data.ListVarName{ivar_FF}); % flags for false vectors
                end
            end
        end
    elseif ~isempty(ivar_C) %scalar or image
        if test_ima
             errormsg='attempt to plot two scalar fields or images';
            return
        end
        A=squeeze(Data.(Data.ListVarName{ivar_C}));% scalar represented as color image
        test_ima=1;
        if strcmp(CellInfo{icell}.CoordType,'scattered')%2D field with unstructured coordinates 
            A=reshape(A,1,[]);
            XName=Data.ListVarName{ivar_X};
            YName=Data.ListVarName{ivar_Y};
            eval(['AX=reshape(Data.' XName ',1,[]);']) 
            eval(['AY=reshape(Data.' YName ',1,[]);'])
            [A,AX,AY]=proj_grid(AX',AY',A',[],[],'np>256');  % interpolate on a grid  
            if isfield(Data,'VarAttribute')
                if numel(Data.VarAttribute)>=ivar_X && isfield(Data.VarAttribute{ivar_X},'units')
                    x_units=[' (' Data.VarAttribute{ivar_X}.units ')'];
                end
                if numel(Data.VarAttribute)>=ivar_Y && isfield(Data.VarAttribute{ivar_Y},'units')
                    y_units=[' (' Data.VarAttribute{ivar_Y}.units ')'];
                end
            end        
        elseif strcmp(CellInfo{icell}.CoordType,'grid')%2D field with structured coordinates 
            YName=Data.ListVarName{CellInfo{icell}.CoordIndex(end-1)};
            AY=Data.(YName); 
            AX=Data.(Data.ListVarName{CellInfo{icell}.CoordIndex(end)});
            test_interp_X=0; %default, regularly meshed X coordinate
            test_interp_Y=0; %default, regularly meshed Y coordinate
            if isfield(Data,'VarAttribute')
                if numel(Data.VarAttribute)>=CellInfo{icell}.CoordIndex(end) && isfield(Data.VarAttribute{CellInfo{icell}.CoordIndex(end)},'units')
                    x_units=Data.VarAttribute{CellInfo{icell}.CoordIndex(end)}.units;
                end
                if numel(Data.VarAttribute)>=CellInfo{icell}.CoordIndex(end-1) && isfield(Data.VarAttribute{CellInfo{icell}.CoordIndex(end-1)},'units')
                    y_units=Data.VarAttribute{CellInfo{icell}.CoordIndex(end-1)}.units;
                end
            end  
            if numel(AY)>2
                DAY=diff(AY);
                DAY_min=min(DAY);
                DAY_max=max(DAY);
                if sign(DAY_min)~=sign(DAY_max);% =1 for increasing values, 0 otherwise
                     errormsg=['errror in plot_field.m: non monotonic dimension variable ' Data.ListVarName{VarRole.coord(1)} ];
                      return
                end 
                test_interp_Y=(DAY_max-DAY_min)> 0.0001*abs(DAY_max);
            end
            if numel(AX)>2
                DAX=diff(AX);
                DAX_min=min(DAX);
                DAX_max=max(DAX);
                if sign(DAX_min)~=sign(DAX_max);% =1 for increasing values, 0 otherwise
                     errormsg=['errror in plot_field.m: non monotonic dimension variable ' Data.ListVarName{VarRole.coord(2)} ];
                      return
                end 
                test_interp_X=(DAX_max-DAX_min)> 0.0001*abs(DAX_max);
            end  
            if test_interp_Y          
                npxy(1)=max([256 floor((AY(end)-AY(1))/DAY_min) floor((AY(end)-AY(1))/DAY_max)]);
                yI=linspace(AY(1),AY(end),npxy(1));
                if ~test_interp_X
                    xI=linspace(AX(1),AX(end),size(A,2));%default 
                    AX=xI;
                end
            end
            if test_interp_X  
                npxy(2)=max([256 floor((AX(end)-AX(1))/DAX_min) floor((AX(end)-AX(1))/DAX_max)]);
                xI=linspace(AX(1),AX(end),npxy(2));   
                if ~test_interp_Y
                   yI=linspace(AY(1),AY(end),size(A,1)); 
                   AY=yI;
                end
            end
            if test_interp_X || test_interp_Y               
                [AX2D,AY2D]=meshgrid(AX,AY);
                A=interp2(AX2D,AY2D,double(A),xI,yI');
            end
            AX=[AX(1) AX(end)];% keep only the lower and upper bounds for image represnetation 
            AY=[AY(1) AY(end)];
%         else
%             errormsg='error in plot_field: invalid coordinate definition ';
%             return
        end
    end
    %define coordinates as CoordUnits, if not defined as attribute for each variable
    if isfield(Data,'CoordUnit')
        if isempty(x_units)
            x_units=Data.CoordUnit;
        end
        if isempty(y_units)
            y_units=Data.CoordUnit;
        end
    end
        
end 

%%   image or scalar plot %%%%%%%%%%%%%%%%%%%%%%%%%%

if isfield(PlotParam.Scalar,'ListContour')
    CheckContour=strcmp(PlotParam.Scalar.ListContour,'contours');
else
    CheckContour=0; %default
end
PlotParamOut=PlotParam; %default
if test_ima
    % distinguish B/W and color images
    np=size(A);%size of image
    siz=numel(np);
    if siz>3
        errormsg=['unrecognized scalar type: ' num2str(siz) ' dimensions'];
        return
    end
    if siz==3
        if np(3)==1
            siz=2;%B W image
        elseif np(3)==3
            siz=3;%color image
        else
            errormsg=['unrecognized scalar type in plot_field: considered as 2D field with ' num2str(np(3)) ' color components'];
            return
        end
    end
    
    %set the color map
    if isfield(PlotParam.Scalar,'CheckBW') && ~isempty(PlotParam.Scalar.CheckBW)
        BW=PlotParam.Scalar.CheckBW; %BW=0 color imposed, else gray scale imposed.
    else % BW imposed automatically chosen
        BW=(siz==2) && (isa(A,'uint8')|| isa(A,'uint16'));% non color images represented in gray scale by default
        PlotParamOut.Scalar.CheckBW=BW;
    end
    %case of grey level images or contour plot
    if siz==2
        if ~isfield(PlotParam.Scalar,'CheckFixScalar')
            PlotParam.Scalar.CheckFixScalar=0;%default
        end
        if ~isfield(PlotParam.Scalar,'MinA')
            PlotParam.Scalar.MinA=[];%default
        end
        if ~isfield(PlotParam.Scalar,'MaxA')
            PlotParam.Scalar.MaxA=[];%default
        end
        Aline=[];
        if ~PlotParam.Scalar.CheckFixScalar ||isempty(PlotParam.Scalar.MinA)||~isa(PlotParam.Scalar.MinA,'double')  %correct if there is no numerical data in edit box
            Aline=reshape(A,1,[]);
            Aline=Aline(~isnan(A));
            if isempty(Aline)
                errormsg='NaN input scalar or image in plot_field';
                return
            end
            MinA=double(min(Aline));
        else
            MinA=PlotParam.Scalar.MinA;
        end;
        if ~PlotParam.Scalar.CheckFixScalar||isempty(PlotParam.Scalar.MaxA)||~isa(PlotParam.Scalar.MaxA,'double') %correct if there is no numerical data in edit box
            if isempty(Aline)
                Aline=reshape(A,1,[]);
                Aline=Aline(~isnan(A));
                if isempty(Aline)
                    errormsg='NaN input scalar or image in plot_field';
                    return
                end
            end
            MaxA=double(max(Aline));
        else
            MaxA=PlotParam.Scalar.MaxA;
        end;
        PlotParamOut.Scalar.MinA=MinA;
        PlotParamOut.Scalar.MaxA=MaxA;
        PlotParamOut.Scalar.Npx=size(A,2);
        PlotParamOut.Scalar.Npy=size(A,1);
        % case of contour plot
        if CheckContour
            if ~isempty(hima) && ishandle(hima)
                delete(hima)
            end
            if ~isfield(PlotParam.Scalar,'IncrA')
                PlotParam.Scalar.IncrA=NaN;
            end
            if isempty(PlotParam.Scalar.IncrA)|| isnan(PlotParam.Scalar.IncrA)% | PlotParam.Scalar.AutoScal==0
                cont=colbartick(MinA,MaxA);
                intercont=cont(2)-cont(1);%default
                PlotParamOut.Scalar.IncrA=intercont;
            else
                intercont=PlotParam.Scalar.IncrA;
            end
            B=A;
            abscontmin=intercont*floor(MinA/intercont);
            abscontmax=intercont*ceil(MaxA/intercont);
            contmin=intercont*floor(min(min(B))/intercont);
            contmax=intercont*ceil(max(max(B))/intercont);
            cont_pos_plus=0:intercont:contmax;
            cont_pos_min=double(contmin):intercont:-intercont;
            cont_pos=[cont_pos_min cont_pos_plus];
            sizpx=(AX(end)-AX(1))/(np(2)-1);
            sizpy=(AY(1)-AY(end))/(np(1)-1);
            x_cont=AX(1):sizpx:AX(end); % pixel x coordinates for image display
            y_cont=AY(1):-sizpy:AY(end); % pixel x coordinates for image display
            % axes(haxes)% set the input axes handle as current axis
            txt=ver('MATLAB');
            Release=txt.Release;
            relnumb=str2double(Release(3:4));
            if relnumb >= 14
                vec=linspace(0,1,(abscontmax-abscontmin)/intercont);%define a greyscale colormap with steps intercont
                map=[vec' vec' vec'];
                colormap(map);
                [var,hcontour]=contour(x_cont,y_cont,B,cont_pos);
                set(hcontour,'Fill','on')
                set(hcontour,'LineStyle','none')
                hold on
            end
            [var_p,hcontour_p]=contour(x_cont,y_cont,B,cont_pos_plus,'k-');
            hold on
            [var_m,hcontour_m]=contour(x_cont,y_cont,B,cont_pos_min,':');
            set(hcontour_m,'LineColor',[1 1 1])
            hold off
            caxis([abscontmin abscontmax])
            colormap(map);
            if isfield(PlotParam.Coordinates,'CheckFixAspectRatio') && isequal(PlotParam.Coordinates.CheckFixAspectRatio,1)
                set(haxes,'DataAspectRatioMode','manual')
                if isfield(PlotParam.Coordinates,'AspectRatio')
                    set(haxes,'DataAspectRatio',[PlotParam.Coordinates.AspectRatio 1 1])
                else
                    set(haxes,'DataAspectRatio',[1 1 1])
                end
            end
        end
        
        % set  colormap for  image display
        if ~CheckContour
            % rescale the grey levels with min and max, put a grey scale colorbar
            B=A;
            if BW
                vec=linspace(0,1,255);%define a linear greyscale colormap
                map=[vec' vec' vec'];
                colormap(map);  %grey scale color map
            else
                colormap('default'); % standard faulse colors for div, vort , scalar fields
            end
        end
        
        % case of color images
    else
        if BW
            B=uint16(sum(A,3));
        else
            B=uint8(A);
        end
        MinA=0;
        MaxA=255;
    end
    
    % display usual image
    if ~CheckContour
        % interpolate field to increase resolution of image display
        test_interp=1;
        if max(np) <= 64
            npxy=8*np;% increase the resolution 8 times
        elseif max(np) <= 128
            npxy=4*np;% increase the resolution 4 times
        elseif max(np) <= 256
            npxy=2*np;% increase the resolution 2 times
        else
            npxy=np;
            test_interp=0; % no interpolation done
        end
        if test_interp==1%if we interpolate
            x=linspace(AX(1),AX(2),np(2));
            y=linspace(AY(1),AY(2),np(1));
            [X,Y]=meshgrid(x,y);
            xi=linspace(AX(1),AX(2),npxy(2));
            yi=linspace(AY(1),AY(2),npxy(1));
            B = interp2(X,Y,double(B),xi,yi');
        end
        % create new image if there  no image handle is found
        if isempty(hima)
            tag=get(haxes,'Tag');
            if MinA<MaxA
                hima=imagesc(AX,AY,B,[MinA MaxA]);
            else % to deal with uniform field
                hima=imagesc(AX,AY,B,[MaxA-1 MaxA]);
            end
            % the function imagesc reset the axes 'DataAspectRatioMode'='auto', change if .CheckFixAspectRatio is
            % requested:
            set(hima,'Tag','ima')
            set(hima,'HitTest','off')
            set(haxes,'Tag',tag);%preserve the axes tag (removed by image fct !!!)
            uistack(hima, 'bottom')
            % update an existing image
        else
            set(hima,'CData',B);
            if MinA<MaxA
                set(haxes,'CLim',[MinA MaxA])
            else
                set(haxes,'CLim',[MinA MaxA+1])
            end
            set(hima,'XData',AX);
            set(hima,'YData',AY);
        end
        
        % set the transparency to 0.5 if vectors are also plotted
        if isfield(PlotParam.Scalar,'Opacity')&& ~isempty(PlotParam.Scalar.Opacity)
            set(hima,'AlphaData',PlotParam.Scalar.Opacity)
        else
            if test_vec
                set(hima,'AlphaData',0.5)%set opacity to 0.5 by default in the presence of vectors
                PlotParamOut.Scalar.Opacity=0.5;
            else
                set(hima,'AlphaData',1)% full opacity (no transparency) by default
            end
        end
    end
    test_ima=1;
    
    %display the colorbar code for B/W images if Poscolorbar not empty
    if ~isempty(PosColorbar)
        if siz==2 && exist('PosColorbar','var')
            if isempty(hcol)||~ishandle(hcol)
                hcol=colorbar;%create new colorbar
            end
            if length(PosColorbar)==4
                set(hcol,'Position',PosColorbar)
            end
            %YTick=0;%default
            if MaxA>MinA
                if CheckContour
                    colbarlim=get(hcol,'YLim');
                    scale_bar=(colbarlim(2)-colbarlim(1))/(abscontmax-abscontmin);
                    YTick=cont_pos(2:end-1);
                    YTick_scaled=colbarlim(1)+scale_bar*(YTick-abscontmin);
                    set(hcol,'YTick',YTick_scaled);
                elseif (isfield(PlotParam.Scalar,'CheckBW') && isequal(PlotParam.Scalar.CheckBW,1))||isa(A,'uint8')|| isa(A,'uint16')%images
                    hi=get(hcol,'children');
                    if iscell(hi)%multiple images in colorbar
                        hi=hi{1};
                    end
                    set(hi,'YData',[MinA MaxA])
                    set(hi,'CData',(1:256)')
                    set(hcol,'YLim',[MinA MaxA])
                    YTick=colbartick(MinA,MaxA);
                    set(hcol,'YTick',YTick)
                else
                    hi=get(hcol,'children');
                    if iscell(hi)%multiple images in colorbar
                        hi=hi{1};
                    end
                    set(hi,'YData',[MinA MaxA])
                    set(hi,'CData',(1:64)')
                    YTick=colbartick(MinA,MaxA);
                    set(hcol,'YLim',[MinA MaxA])
                    set(hcol,'YTick',YTick)
                end
                set(hcol,'Yticklabel',num2str(YTick'));
            end
        elseif ishandle(hcol)
            delete(hcol); %erase existing colorbar if not needed
        end
    end
else%no scalar plot
    if ~isempty(hima) && ishandle(hima)
        delete(hima)
    end
    if ~isempty(PosColorbar) && ~isempty(hcol)&& ishandle(hcol)
        delete(hcol)
    end
    PlotParamOut=rmfield(PlotParamOut,'Scalar');
end

%%   vector plot %%%%%%%%%%%%%%%%%%%%%%%%%%
if test_vec
   %vector scale representation
    if size(vec_U,1)==numel(vec_Y) && size(vec_U,2)==numel(vec_X); % x, y  coordinate variables
        [vec_X,vec_Y]=meshgrid(vec_X,vec_Y);
    end   
    vec_X=reshape(vec_X,1,numel(vec_X));%reshape in matlab vectors
    vec_Y=reshape(vec_Y,1,numel(vec_Y));
    vec_U=reshape(vec_U,1,numel(vec_U));
    vec_V=reshape(vec_V,1,numel(vec_V));
     MinMaxX=max(vec_X)-min(vec_X);
    if  isfield(PlotParam.Vectors,'CheckFixVectors') && isequal(PlotParam.Vectors.CheckFixVectors,1)&& isfield(PlotParam.Vectors,'VecScale')...
               &&~isempty(PlotParam.Vectors.VecScale) && isa(PlotParam.Vectors.VecScale,'double') %fixed vector scale
        scale=PlotParam.Vectors.VecScale;  %impose the length of vector representation
    else
        if ~test_false %remove false vectors    
            indsel=1:numel(vec_X);%
        end
        if isempty(vec_U)
            scale=1;
        else
            if isempty(indsel)
                MaxU=max(abs(vec_U));
                MaxV=max(abs(vec_V));
            else
                MaxU=max(abs(vec_U(indsel)));
                MaxV=max(abs(vec_V(indsel)));
            end
            scale=MinMaxX/(max(MaxU,MaxV)*50);
            PlotParam.Vectors.VecScale=scale;%update the 'scale' display
        end
    end
    
    %record vectors on the plotting axes
    if test_C==0
        vec_C=ones(1,numel(vec_X));
    end
    
    %decimate by a factor 2 in vector mesh(4 in nbre of vectors)
    check_decimate=0;
    if isfield(PlotParam.Vectors,'CheckDecimate4') && PlotParam.Vectors.CheckDecimate4
        check_decimate=1;
        diffy=diff(vec_Y); %difference dy=vec_Y(i+1)-vec_Y(i)
        dy_thresh=max(abs(diffy))/2; 
        ind_jump=find(abs(diffy) > dy_thresh); %indices with diff(vec_Y)> max/2, detect change of line
        ind_sel=1:ind_jump(1);%select the first line
        for i=2:2:length(ind_jump)-1
            ind_sel=[ind_sel (ind_jump(i)+1:ind_jump(i+1))];% select the odd lines
        end
        nb_sel=length(ind_sel);
        ind_sel=ind_sel(1:2:nb_sel);% take half the points on a line
    elseif isfield(PlotParam.Vectors,'CheckDecimate16') && PlotParam.Vectors.CheckDecimate16
        check_decimate=1;
        diffy=diff(vec_Y); %difference dy=vec_Y(i+1)-vec_Y(i)
        dy_thresh=max(abs(diffy))/2; 
        ind_jump=find(abs(diffy) > dy_thresh); %indices with diff(vec_Y)> max/2, detect change of line
        ind_sel=1:ind_jump(1);%select the first line
        for i=2:4:length(ind_jump)-1
            ind_sel=[ind_sel (ind_jump(i)+1:ind_jump(i+1))];% select the odd lines
        end
        nb_sel=length(ind_sel);
        ind_sel=ind_sel(1:4:nb_sel);% take half the points on a line
    end
    if check_decimate
        vec_X=vec_X(ind_sel);
        vec_Y=vec_Y(ind_sel);
        vec_U=vec_U(ind_sel);
        vec_V=vec_V(ind_sel);
        vec_C=vec_C(ind_sel);
        if ~isempty(ivar_F)
           vec_F=vec_F(ind_sel);
        end
        if ~isempty(ivar_FF)
           vec_FF=vec_FF(ind_sel);
        end
    end
    
    %get main level color code
    [colorlist,col_vec,PlotParamOut.Vectors]=set_col_vec(PlotParam.Vectors,vec_C);
    
    % take flags into account: add flag colors to the list of colors
    sizlist=size(colorlist);
    nbcolor=sizlist(1);
    if test_black 
       nbcolor=nbcolor+1;
       colorlist(nbcolor,:)=[0 0 0]; %add black to the list of colors
       if ~isempty(ivar_FF)
          %  ind_flag=find(vec_F~=1 & vec_F~=0 & vec_FF==0);  %flag warning but not false
            col_vec(vec_F~=1 & vec_F~=0 & vec_FF==0)=nbcolor;
       else
            col_vec(vec_F~=1 & vec_F~=0)=nbcolor;
       end
    end
    nbcolor=nbcolor+1;
    if ~isempty(ivar_FF)
        if isfield(PlotParam.Vectors,'CheckHideFalse') && PlotParam.Vectors.CheckHideFalse==1
            colorlist(nbcolor,:)=[NaN NaN NaN];% no plot of false vectors
        else
            colorlist(nbcolor,:)=[1 0 1];% magenta color
        end
        col_vec(vec_FF~=0)=nbcolor;
    end
    %plot vectors:
    quiresetn(haxes,vec_X,vec_Y,vec_U,vec_V,scale,colorlist,col_vec);   

else
    hvec=findobj(haxes,'Tag','vel');
    if ~isempty(hvec)
        delete(hvec);
    end
    PlotParamOut=rmfield(PlotParamOut,'Vectors');
end
% nbvar=0;

%store the coordinate extrema occupied by the field
if ~isempty(Data)
    MinX=[];
    MaxX=[];
    MinY=[];
    MaxY=[];
    fix_lim=isfield(PlotParam.Coordinates,'CheckFixLimits') && PlotParam.Coordinates.CheckFixLimits;
    if fix_lim
        if isfield(PlotParam.Coordinates,'MinX')&&isfield(PlotParam.Coordinates,'MaxX')&&isfield(PlotParam.Coordinates,'MinY')&&isfield(PlotParam.Coordinates,'MaxY')
            MinX=PlotParam.Coordinates.MinX;
            MaxX=PlotParam.Coordinates.MaxX;
            MinY=PlotParam.Coordinates.MinY;
            MaxY=PlotParam.Coordinates.MaxY;
        end  %else PlotParamOut.MinX =PlotParam.MinX...
    else
        if test_ima %both background image and vectors coexist, take the wider bound
            MinX=min(AX);
            MaxX=max(AX);
            MinY=min(AY);
            MaxY=max(AY);
            if test_vec
                MinX=min(MinX,min(vec_X));
                MaxX=max(MaxX,max(vec_X));
                MinY=min(MinY,min(vec_Y));
                MaxY=max(MaxY,max(vec_Y));
            end
        elseif test_vec
            MinX=min(vec_X);
            MaxX=max(vec_X);
            MinY=min(vec_Y);
            MaxY=max(vec_Y);
        end
    end
    PlotParamOut.Coordinates.MinX=MinX;
    PlotParamOut.Coordinates.MaxX=MaxX;
    PlotParamOut.Coordinates.MinY=MinY;
    PlotParamOut.Coordinates.MaxY=MaxY;
    if MaxX>MinX
        set(haxes,'XLim',[MinX MaxX]);% set x limits of frame in axes coordinates
    end
    if MaxY>MinY
        set(haxes,'YLim',[MinY MaxY]);% set x limits of frame in axes coordinates
    end
    set(haxes,'YDir','normal')
    set(get(haxes,'XLabel'),'String',[XName ' (' x_units ')']);
    set(get(haxes,'YLabel'),'String',[YName ' (' y_units ')']);
    PlotParamOut.Coordinates.x_units=x_units;
    PlotParamOut.Coordinates.y_units=y_units;
end
if isfield(PlotParam,'Coordinates') && isfield(PlotParam.Coordinates,'CheckFixAspectRatio') && isequal(PlotParam.Coordinates.CheckFixAspectRatio,1)
    set(haxes,'DataAspectRatioMode','manual')
    if isfield(PlotParam.Coordinates,'AspectRatio')
        set(haxes,'DataAspectRatio',[PlotParam.Coordinates.AspectRatio 1 1])
    end
else
    set(haxes,'DataAspectRatioMode','auto')
end
%-------------------------------------------------------------------
% --- function for plotting vectors
%INPUT:
% haxes: handles of the plotting axes
% x,y,u,v: vectors coordinates and vector components to plot, arrays withb the same dimension
% scale: scaling factor for vector length representation
% colorlist(icolor,:): list of vector colors, dim (nbcolor,3), depending on color #i
% col_vec: matlab vector setting the color number #i for each velocity vector
function quiresetn(haxes,x,y,u,v,scale,colorlist,col_vec)
%-------------------------------------------------------------------
%define arrows
theta=0.5 ;%angle arrow
alpha=0.3 ;%length arrow
rot=alpha*[cos(theta) -sin(theta); sin(theta) cos(theta)]';
%find the existing lines
h=findobj(haxes,'Tag','vel');% search existing lines in the current axes
sizh=size(h);
set(h,'EraseMode','xor');
set(haxes,'NextPlot','replacechildren');

%drawnow
%create lines (if no lines) or modify them
if ~isequal(size(col_vec),size(x))
    col_vec=ones(size(x));% case of error in col_vec input
end
sizlist=size(colorlist);
ncolor=sizlist(1);

for icolor=1:ncolor
    %determine the line positions for each color icolor
    ind=find(col_vec==icolor);
    xc=x(ind);
    yc=y(ind);
    uc=u(ind)*scale;
    vc=v(ind)*scale;
    n=size(xc);
    xN=NaN*ones(size(xc));
    matx=[xc(:)-uc(:)/2 xc(:)+uc(:)/2 xN(:)]';
    matx=reshape(matx,1,3*n(2));
    maty=[yc(:)-vc(:)/2 yc(:)+vc(:)/2 xN(:)]';
    maty=reshape(maty,1,3*n(2));
    
    %determine arrow heads
    arrowplus=rot*[uc;vc];
    arrowmoins=rot'*[uc;vc];
    x1=xc+uc/2-arrowplus(1,:);
    x2=xc+uc/2;
    x3=xc+uc/2-arrowmoins(1,:);
    y1=yc+vc/2-arrowplus(2,:);
    y2=yc+vc/2;
    y3=yc+vc/2-arrowmoins(2,:);
    matxar=[x1(:) x2(:) x3(:) xN(:)]';
    matxar=reshape(matxar,1,4*n(2));
    matyar=[y1(:) y2(:) y3(:) xN(:)]';
    matyar=reshape(matyar,1,4*n(2));
    %draw the line or modify the existing ones
%     tri=reshape(1:3*length(uc),3,[])';   
    isn=isnan(colorlist(icolor,:));%test if color NaN
    if 2*icolor > sizh(1) %if icolor exceeds the number of existing ones
        if ~isn(1) %if the vectors are visible color not nan
            if n(2)>0
                hold on
                line(matx,maty,'Color',colorlist(icolor,:),'Tag','vel');% plot new lines
                line(matxar,matyar,'Color',colorlist(icolor,:),'Tag','vel');% plot arrows
            end
        end
    else
        if isn(1)
            delete(h(2*icolor-1))
            delete(h(2*icolor))
        else
            set(h(2*icolor-1),'Xdata',matx,'Ydata',maty);
            set(h(2*icolor-1),'Color',colorlist(icolor,:));
            set(h(2*icolor-1),'EraseMode','xor');
            set(h(2*icolor),'Xdata',matxar,'Ydata',matyar);
            set(h(2*icolor),'Color',colorlist(icolor,:));
            set(h(2*icolor),'EraseMode','xor');
        end
    end
end
if sizh(1) > 2*ncolor
    for icolor=ncolor+1 : sizh(1)/2%delete additional objects
        delete(h(2*icolor-1))
        delete(h(2*icolor))
    end
end

%-------------------------------------------------------------------
% ---- determine tick positions for colorbar
function YTick=colbartick(MinA,MaxA)
%-------------------------------------------------------------------
%determine tick positions with "simple" values between MinA and MaxA
YTick=0;%default
maxabs=max([abs(MinA) abs(MaxA)]);
if maxabs>0 
ord=10^(floor(log10(maxabs)));%order of magnitude
div=1;
siz2=1;
while siz2<2
    values=-10:div:10;
    ind=find((ord*values-MaxA)<0 & (ord*values-MinA)>0);%indices of 'values' such that MinA<ord*values<MaxA
    siz=size(ind);
    if siz(2)<4%if there are less than 4 selected values (4 levels)
        values=-9:0.5*div:9;
        ind=find((ord*values-MaxA)<0 & (ord*values-MinA)>0);
    end
    siz2=size(ind,2);
    div=div/10;
end
YTick=ord*values(ind);
end

% -------------------------------------------------------------------------
% --- 'proj_grid': project  fields with unstructured coordinantes on a regular grid
function [A,rangx,rangy]=proj_grid(vec_X,vec_Y,vec_A,rgx_in,rgy_in,npxy_in)
% -------------------------------------------------------------------------
if length(vec_Y)<2
    msgbox_uvmat('ERROR','less than 2 points in proj_grid.m');
    return; 
end
diffy=diff(vec_Y); %difference dy=vec_Y(i+1)-vec_Y(i)
index=find(diffy);% find the indices of vec_Y after wich a change of horizontal line occurs(diffy non zero)
if isempty(index); msgbox_uvmat('ERROR','points aligned along abscissa in proj_grid.m'); return; end;%points aligned% A FAIRE: switch to line plot.
diff2=diff(diffy(index));% diff2 = fluctuations of the detected vertical grid mesh dy 
if max(abs(diff2))>0.001*abs(diffy(index(1))) % if max(diff2) is larger than 1/1000 of the first mesh dy
    % the data are not regularly spaced and must be interpolated  on a regular grid
    if exist('rgx_in','var') & ~isempty (rgx_in) & isnumeric(rgx_in) & length(rgx_in)==2%  positions imposed from input
        rangx=rgx_in; % first and last positions
        rangy=rgy_in;
        dxy(1)=1/(npxy_in(1)-1);%grid mesh in y
        dxy(2)=1/(npxy_in(2)-1);%grid mesh in x
        dxy(1)=(rangy(2)-rangy(1))/(npxy_in(1)-1);%grid mesh in y
        dxy(2)=(rangx(2)-rangx(1))/(npxy_in(2)-1);%grid mesh in x
    else % interpolation grid automatically determined
        rangx(1)=min(vec_X);
        rangx(2)=max(vec_X);
        rangy(2)=min(vec_Y);
        rangy(1)=max(vec_Y);
        dxymod=sqrt((rangx(2)-rangx(1))*(rangy(1)-rangy(2))/length(vec_X));
        dxy=[-dxymod/4 dxymod/4];% increase the resolution 4 times
    end
    xi=[rangx(1):dxy(2):rangx(2)];
    yi=[rangy(1):dxy(1):rangy(2)];
    A=griddata_uvmat(vec_X,vec_Y,vec_A,xi,yi'); 
    A=reshape(A,length(yi),length(xi));
else
    x=vec_X(1:index(1));% the set of abscissa (obtained on the first line)
    indexend=index(end);% last vector index of line change
    ymax=vec_Y(indexend+1);% y coordinate AFTER line change
    ymin=vec_Y(index(1));
    y=vec_Y(index);
    y(length(y)+1)=ymax;
    nx=length(x);   %number of grid points in x
    ny=length(y);   % number of grid points in y
    B=(reshape(vec_A,nx,ny))'; %vec_A reshaped as a rectangular matrix
    [X,Y]=meshgrid(x,y);% positions X and Y also reshaped as matrix 

    %linear interpolation to improve the image resolution and/or adjust
    %to prescribed positions 
    test_interp=1;
    if exist('rgx_in','var') & ~isempty (rgx_in) & isnumeric(rgx_in) & length(rgx_in)==2%  positions imposed from input
        rangx=rgx_in; % first and last positions
        rangy=rgy_in;
        npxy=npxy_in;
    else        
        rangx=[vec_X(1) vec_X(nx)];% first and last position found for x
          rangy=[max(ymax,ymin) min(ymax,ymin)];
        if max(nx,ny) <= 64 & isequal(npxy_in,'np>256')
            npxy=[8*ny 8*nx];% increase the resolution 8 times
        elseif max(nx,ny) <= 128 & isequal(npxy_in,'np>256')
            npxy=[4*ny 4*nx];% increase the resolution 4 times
        elseif max(nx,ny) <= 256 & isequal(npxy_in,'np>256')
            npxy=[2*ny 2*nx];% increase the resolution 2 times
        else
            npxy=[ny nx];
            test_interp=0; % no interpolation done
        end
    end
    if test_interp==1%if we interpolate
        xi=[rangx(1):(rangx(2)-rangx(1))/(npxy(2)-1):rangx(2)];
        yi=[rangy(1):(rangy(2)-rangy(1))/(npxy(1)-1):rangy(2)];
        [XI,YI]=meshgrid(xi,yi);
        A = interp2(X,Y,B,XI,YI);
    else %no interpolation for a resolution higher than 256
        A=B;
    end
end