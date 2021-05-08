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
% PlotType: type of plot: 'text','line'(curve plot),'plane':2D view,'volume', or errormsg
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
%     .Axes: coordinate parameters:
%           .CheckFixLimits:=0 (default) adjust axes limit to the X,Y data, =1: preserves the previous axes limits
%     .Axes.CheckFixAspectRatio: =0 (default):automatic adjustment of the graph, keep 1 to 1 aspect ratio for x and y scales. 
%     .Axes.AspectRatio: imposed aspect ratio y/x of axis unit plots
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

%=======================================================================
% Copyright 2008-2021, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
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

function [PlotType,PlotParamOut,haxes]= plot_field(Data,haxes,PlotParam)

%% default input and output
if ~exist('PlotParam','var'),PlotParam=[];end
PlotType='text'; %default
if ~isfield(PlotParam,'Axes')
    PlotParam.Axes=[];
    if isfield(Data,'CoordUnit')
        PlotParam.Axes.CheckFixAspectRatio=1;
        PlotParam.Axes.AspectRatio=1; %set axes equal by default if CoordUnit is defined
    end
end
PlotParamOut=PlotParam;%default

%% check input structure
[CellInfo,NbDimArray,errormsg]=find_field_cells(Data);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['input of plot_field/find_field_cells: ' errormsg]);
    return
end
index_0D=find(NbDimArray==0);
index_1D=find(NbDimArray==1);
index_2D=find(NbDimArray==2);%find 2D fields
index_3D=find(NbDimArray>2,1);
if ~isempty(index_3D)
    msgbox_uvmat('ERROR','volume plot not implemented yet');
    return
end

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
if isfield(PlotParamOut.Axes,'CheckFixLimits') && isequal(PlotParamOut.Axes.CheckFixLimits,1)  %adjust the graph limits
    set(haxes,'XLimMode', 'manual')
    set(haxes,'YLimMode', 'manual')
else
    set(haxes,'XLimMode', 'auto')
    set(haxes,'YLimMode', 'auto')
end

if isfield(PlotParamOut.Axes,'CheckFixAspectRatio') && isequal(PlotParamOut.Axes.CheckFixAspectRatio,1)&&isfield(PlotParamOut.Axes,'AspectRatio')
    set(haxes,'DataAspectRatioMode','manual')
    set(haxes,'DataAspectRatio',[PlotParamOut.Axes.AspectRatio 1 1])
else
    set(haxes,'DataAspectRatioMode','auto')%automatic aspect ratio
end

errormsg='';
AxeData=get(haxes,'UserData');

%% 2D plots 
if isempty(index_2D)
    plot_plane([],[],haxes,[]);%removes images or vector plots in the absence of 2D field plot
else  %plot 2D field
%     if ~exist('PosColorbar','var'),PosColorbar=[];end;
    [tild,PlotParamOut,PlotType,errormsg]=plot_plane(Data,CellInfo(index_2D),haxes,PlotParamOut);
    AxeData.NbDim=2;
    if testzoomaxes && isempty(errormsg)
        [zoomaxes,PlotParamOut,tild,errormsg]=plot_plane(Data,CellInfo(index_2D),zoomaxes,PlotParamOut);
        AxeData.ZoomAxes=zoomaxes;
    end
end

%% 1D plot (usual graph y vs x)
if isempty(index_1D)|| ~isempty(index_2D)
    if ~isempty(haxes)
        plot_profile([],[],haxes);%removes usual praphs y vs x in the absence of 1D field plot
    end
else %plot 1D field (usual graph y vs x)
    CheckHold=0;
    if isfield(PlotParam,'CheckHold') 
        CheckHold= PlotParam.CheckHold;
    end       
    PlotParamOut=plot_profile(Data,CellInfo(index_1D),haxes,PlotParamOut,CheckHold);%
    if isempty(index_2D)
        if isfield(PlotParamOut,'Vectors')
            PlotParamOut=rmfield(PlotParamOut,'Vectors');
        end
        if isfield(PlotParamOut,'Scalar')
            PlotParamOut=rmfield(PlotParamOut,'Scalar');
        end
    end
    if testzoomaxes
        [zoomaxes,PlotParamOut.Axes]=plot_profile(Data,CellInfo(index_1D),zoomaxes,PlotParamOut.Axes,CheckHold);
        AxeData.ZoomAxes=zoomaxes;
    end
    PlotType='line';
end

%% aspect ratio
AspectRatio=get(haxes,'DataAspectRatio');
PlotParamOut.Axes.AspectRatio=AspectRatio(1)/AspectRatio(2);

%% text display
if ~(isfield(PlotParamOut,'Axes')&&isfield(PlotParamOut.Axes,'TextDisplay')&&(PlotParamOut.Axes.TextDisplay)) % if text is not already given as statistics
    htext=findobj(hfig,'Tag','TableDisplay');
    if ~isempty(htext)%&&~isempty(hchecktable)
        if isempty(index_0D)
        else
            errormsg=plot_text(Data,CellInfo(index_0D),htext);
            set(htext,'visible','on')
        end
        set(hfig,'Unit','pixels');
        set(htext,'Unit','pixels')
        PosFig=get(hfig,'Position');
        % case of no plot with view_field: only text display
        if strcmp(get(hfig,'Tag'),'view_field')
            if isempty(index_1D) && isempty(index_2D)% case of no plot: only text display
                set(haxes,'Visible','off')
                PosTable=get(htext,'Position');
                set(hfig,'Position',[PosFig(1) PosFig(2)  PosTable(3) PosTable(4)])
            else
                set(haxes,'Visible','on')
                set(hfig,'Position',[PosFig(1) PosFig(2)  877 677])%default size for view_field
            end
        end
    end
end
%% display error message
if ~isempty(errormsg)
    PlotType=errormsg;
    msgbox_uvmat('ERROR', errormsg)
end

%% update the parameters stored in AxeData
if ishandle(haxes)&&( ~isempty(index_2D)|| ~isempty(index_1D))
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
        if ~isempty(get(haxes,'tag'))
        FigData.(get(haxes,'tag'))=Data;
        end
        set(hfig,'UserData',FigData)
    end
end

%-------------------------------------------------------------------
% --- plot 0D fields: display data values without plot
%------------------------------------------------------------------
function errormsg=plot_text(FieldData,CellInfo,htext)

errormsg='';
txt_cell={};
Data={};
VarIndex=[];
for icell=1:length(CellInfo)
    
    % select types of  variables to be projected
    ListProj={'VarIndex_scalar','VarIndex_image','VarIndex_color','VarIndex_vector_x','VarIndex_vector_y'};
    check_proj=false(size(FieldData.ListVarName));
    for ilist=1:numel(ListProj)
        if isfield(CellInfo{icell},ListProj{ilist})
            check_proj(CellInfo{icell}.(ListProj{ilist}))=1;
        end
    end
    VarIndex=[VarIndex find(check_proj)];
end

% data need to be displayed in a table
% if strcmp(get(htext,'Type'),'uitable')% display data in a table
%     VarNameCell=cell(1,numel(VarIndex));% prepare list of variable names to display (titles of columns)
%     VarLength=zeros(1,numel(VarIndex));  % default number of values for each variable
%     for ivar=1:numel(VarIndex)
%         VarNameCell{ivar}=FieldData.ListVarName{VarIndex(ivar)};
%         VarLength(ivar)=numel(FieldData.(VarNameCell{ivar}));
%     end
%     set(htext,'ColumnName',VarNameCell)
%     Data=cell(max(VarLength),numel(VarIndex));% prepare the table of data display
%     
%     for ivar=1:numel(VarIndex)
%         VarValue=FieldData.(VarNameCell{ivar});
%         VarValue=reshape(VarValue,[],1);% reshape values array in a column
%         Data(1:numel(VarValue),ivar)=num2cell(VarValue);
%     end
%     set(htext,'Data',Data)
% end
%         if numel(VarValue)>1 && numel(VarValue)<10 % case of a variable with several values 
%             for ind=1:numel(VarValue)
%                 VarNameCell{1,ind}=[VarName '_' num2str(ind)];% indicate each value by an index
%             end
%         else
%             VarNameCell={VarName};
%         end
%         if numel(VarValue)<10
%             if isempty(VarValue)
%                 VarValueCell={'[]'};
%             else
%                 VarValueCell=num2cell(VarValue);
%             end
%             if isempty(Data)
%                 Data =[VarNameCell VarValueCell];
%             else
%                 Data =[Data [VarNameCell VarValueCell]];
%             end
%         else
%             if isempty(Data)
%                 Data =[VarNameCell; num2cell(VarValue)];
%             else
%                 Data =[Data [VarNameCell; {['size ' num2str(size(VarValue))]}]];
%             end
%         end
%         if size(VarValue,1)==1
%             txt=[VarName '=' num2str(VarValue)];
%             txt_cell=[txt_cell;{txt}];
%         end
%     end
% end
% if strcmp(get(htext,'Type'),'uitable')% display data in a table
% 
%  
%     set(htext,'Data',Data(2:end,:))
% else  % display in a text edit box
%     set(htext,'String',txt_cell)
%     set(htext,'UserData',txt_cell)% for temporary storage when the edit box is used for mouse display
% end


%-------------------------------------------------------------------
% --- plot 1D fields (usual x,y plots)
%-------------------------------------------------------------------
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
%    the values:
%       Role = 'coord_x' or 'histo' to label the x coordinate
%            ='coord_y' or 'discrete' to label the y coordinate, variables labelled as 'discrete'
%           will be plotted as isolated points while variables labelled as 'coord_y' will be plotted as continuous lines
%    other variables will not be taken into account for plot_profile

function PlotParamOut=plot_profile(Data,CellInfo,haxes,PlotParam,CheckHold)

%% initialization
if ~(exist('PlotParam','var')&&~isempty(PlotParam.Axes))
    Coordinates=[];
    PlotParamOut.Axes=Coordinates;
else
    Coordinates=PlotParam.Axes;
    PlotParamOut=PlotParam;
end
hfig=get(haxes,'parent');
legend_str={};

%% suppress existing plot if empty Data
if isempty(Data)
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
ColorOrder=[1 0 0;0 1 0;0 0 1;0 0.75 0.75;0.75 0 0.75;0.75 0.75 0;0.25 0.25 0.25];
set(hfig,'DefaultAxesColorOrder',ColorOrder)
if CheckHold
    set(haxes,'NextPlot','add')
else
    set(haxes,'NextPlot','replace')
end

%% prepare the string for plot command
plotstr='hhh=plot(';
xtitle='';
ytitle='';
test_newplot=~CheckHold;
MinX=[];
MaxX=[];
MinY_cell=[];
MaxY_cell=[];
testplot=ones(size(Data.ListVarName));%default test for plotted variables
%loop on input  fields
for icell=1:numel(CellInfo)
    VarIndex=[CellInfo{icell}.YIndex CellInfo{icell}.YIndex_discrete];%  indices of the selected variables in the list Data.ListVarName
    coord_x_index=CellInfo{icell}.XIndex;
    coord_x_name{icell}=Data.ListVarName{coord_x_index};
    coord_x{icell}=Data.(Data.ListVarName{coord_x_index});%coordinate variable set as coord_x
    if isempty(find(strcmp(coord_x_name{icell},coord_x_name(1:end-1)), 1)) %xtitle not already selected
        xtitle=[xtitle coord_x_name{icell}];
        if isfield(Data,'VarAttribute')&& numel(Data.VarAttribute)>=coord_x_index && isfield(Data.VarAttribute{coord_x_index},'units')
            xtitle=[xtitle '(' Data.VarAttribute{coord_x_index}.units '), '];
        else
            xtitle=[xtitle ', '];
        end
    end
    if ~isempty(coord_x{icell})
        MinX(icell)=min(coord_x{icell});
        MaxX(icell)=max(coord_x{icell});
        testplot(coord_x_index)=0;
        if isfield(CellInfo{icell},'VarIndex_ancillary')
            testplot(CellInfo{icell}.VarIndex_ancillary)=0;
        end
        if isfield(CellInfo{icell},'VarIndex_warnflag')
            testplot(CellInfo{icell}.VarIndex_warnflag)=0;
        end
        if isfield(Data,'VarAttribute')
            VarAttribute=Data.VarAttribute;
            for ivar=1:length(VarIndex)
                if length(VarAttribute)>=VarIndex(ivar) && isfield(VarAttribute{VarIndex(ivar)},'long_name')
                    plotname{VarIndex(ivar)}=VarAttribute{VarIndex(ivar)}.long_name;
                else
                    plotname{VarIndex(ivar)}=Data.ListVarName{VarIndex(ivar)};%name for display in plot A METTRE
                end
            end
        end
        if isfield(CellInfo{icell},'YIndex_discrete')&& ~isempty(CellInfo{icell}.YIndex_discrete)
            charplot_0='''+''';
        else
            charplot_0='''-''';
        end
        MinY=[];
        MaxY=[];%default
        
        nbplot=0;
        for ivar=1:length(VarIndex)
            if testplot(VarIndex(ivar))
                VarName=Data.ListVarName{VarIndex(ivar)};
                nbplot=nbplot+1;
                ytitle=[ytitle VarName];
                if isfield(Data,'VarAttribute')&& numel(Data.VarAttribute)>=VarIndex(ivar) && isfield(Data.VarAttribute{VarIndex(ivar)},'units')
                    ytitle=[ytitle '(' Data.VarAttribute{VarIndex(ivar)}.units '), '];
                else
                    ytitle=[ytitle ', '];
                end
                eval(['Data.' VarName '=squeeze(Data.' VarName ');'])
                MinY(ivar)=min(min(Data.(VarName)));
                MaxY(ivar)=max(max(Data.(VarName)));
                plotstr=[plotstr 'coord_x{' num2str(icell) '},Data.' VarName ',' charplot_0 ','];
                eval(['nbcomponent2=size(Data.' VarName ',2);']);
                eval(['nbcomponent1=size(Data.' VarName ',1);']);
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
end

%% activate the plot
if  ~isequal(plotstr,'hhh=plot(')  
    set(hfig,'CurrentAxes',haxes)
    tag=get(haxes,'tag');    
    %%%
    plotstr=[plotstr '''tag'',''plot_line'');'];   
    eval(plotstr)                  %execute plot (instruction  plotstr)
    %%%
    set(haxes,'tag',tag)% restitute the axes tag (removed by the command plot)
    set(haxes,'ColorOrder',ColorOrder)% restitute the plot color order (to get red green blue for histograms or cuts of color images)
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
    if isfield(Data,'filename')
       [Path, title_str, ext]=fileparts(Data.filename);
       title_str=[title_str ext];
    end
    if isfield(Data,'Action')&&isfield(Data.Action,'ActionName')
        if ~isequal(title_str,'')
            title_str=[title_str ', '];
        end
        title_str=[title_str Data.Action.ActionName];
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
            Coordinates.MinX=min(min(MinX),Coordinates.MinX);
            Coordinates.MaxX=max(max(MaxX),Coordinates.MaxX);
        else
            Coordinates.MinX=min(MinX);
            Coordinates.MaxX=max(MaxX);
        end
    end
    if ~isempty(MinY_cell)
        if check_lim
            Coordinates.MinY=min(min(MinY_cell),Coordinates.MinY);
            Coordinates.MaxY=max(max(MaxY_cell),Coordinates.MaxY);
        else
            Coordinates.MinY=min(MinY_cell);
            Coordinates.MaxY=max(MaxY_cell);
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
    Coordinates.AspectRatio=AspectRatio(1)/AspectRatio(2);
end
PlotParamOut.Axes= Coordinates;

%% give statistics for pdf
%ind_var=find(testplot);
TableData={'Variable';'SampleNbr';'bin size';'Mean';'RMS';'Skewness';'Kurtosis';...
    'Min';'FirstCentile';'FirstDecile';'Median';'LastDecile';'LastCentile';'Max'};

TextDisplay=0;
for icell=1:numel(CellInfo)
    if isfield(CellInfo{icell},'VarIndex_histo')% case of histogram plot
        TextDisplay=1;
        VarName=Data.ListVarName{CellInfo{icell}.CoordIndex};
        pdf_val=Data.(Data.ListVarName{CellInfo{icell}.VarIndex_histo});
        x=coord_x{icell};
        if isrow(x)
            x=x';
        end
        if ~isequal(size(x,1),size(pdf_val,1))
            pdf_val=pdf_val';
        end
        Val=pdf2stat(x,pdf_val);
        Column=mat2cell(Val,ones(13,1),ones(1,size(Val,2)));
        if size(Val,2)==1%single component
            TitleBar={VarName};
        else
            TitleBar=cell(1,size(Val,2));
            for icomp=1:size(Val,2)
                TitleBar{icomp}=[VarName '_' num2str(icomp)];
            end
        end
        Column=[TitleBar;Column];
        TableData=[TableData Column];
    end
end
if TextDisplay
    disp(TableData);
    PlotParamOut.TableDisplay=TableData;
else
    if isfield(PlotParamOut,'TableDisplay')
        PlotParamOut=rmfield(PlotParamOut,'TableDisplay');
    end
end
    
%-------------------------------------------------------------------
function [haxes,PlotParamOut,PlotType,errormsg]=plot_plane(Data,CellInfo,haxes,PlotParam)
%-------------------------------------------------------------------
PlotType='plane';
grid(haxes, 'off')% remove grid (possibly remaining from other graphs)

%default plotting parameters
if ~isfield(PlotParam,'Scalar')
    PlotParam.Scalar=[];
end
if ~isfield(PlotParam,'Vectors')
    PlotParam.Vectors=[];
end
PlotParamOut=PlotParam;%default
errormsg='';%default

hfig=get(haxes,'parent');%handle of the figure containing the plot axes
PosColorbar=[];
FigData=get(hfig,'UserData');
if isfield(FigData,'PosColorbar')
    PosColorbar=FigData.PosColorbar;
end
hcol=findobj(hfig,'Tag','Colorbar'); %look for colorbar axes
hima=findobj(haxes,'Tag','ima');% search existing image in the current axes
test_ima=0; %default: test for image or map plot
test_vec=0; %default: test for vector plots
test_black=0;
test_false=0;
test_C=0;
XName='';
x_units='';
YName='';
y_units='';

% loop on the input field cells
for icell=1:numel(CellInfo)
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
    ivar_FF_vec=[];
    if isfield(CellInfo{icell},'VarIndex_vector_x')&&isfield(CellInfo{icell},'VarIndex_vector_y') % vector components detected
        if test_vec% a vector field has been already detected
            errormsg='error in plot_field: attempt to plot two vector fields: to get the difference project on a plane with ProjMode= interp_lin or interp_tps';
            return
        else
            if numel(CellInfo{icell}.VarIndex_vector_x)>1
                errormsg='error in plot_field: attempt to plot two vector fields';
                return
            end
            test_vec=1;
            if isfield(CellInfo{icell},'VarIndex_errorflag')
                ivar_FF_vec=CellInfo{icell}.VarIndex_errorflag; %defines index (unique) for error flag variable
            end
            vec_U=Data.(Data.ListVarName{CellInfo{icell}.VarIndex_vector_x});
            vec_V=Data.(Data.ListVarName{CellInfo{icell}.VarIndex_vector_y});
            XName=Data.ListVarName{CellInfo{icell}.CoordIndex(end)};
            YName=Data.ListVarName{CellInfo{icell}.CoordIndex(end-1)};
            if strcmp(CellInfo{icell}.CoordType,'scattered')%2D field with unstructured coordinates
                vec_X=reshape(Data.(XName),[],1); %transform vectors in column matlab vectors
                vec_Y=reshape(Data.(YName),[],1);
            elseif strcmp(CellInfo{icell}.CoordType,'grid')%2D field with structured coordinates
                y=Data.(YName);
                x=Data.(XName);
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
                vec_F=Data.(Data.ListVarName{ivar_F}); % warning flags for  dubious vectors
                if  ~(isfield(PlotParam.Vectors,'CheckHideWarning') && isequal(PlotParam.Vectors.CheckHideWarning,1))
                    test_black=1;
                end
            end
            if ~isempty(ivar_FF_vec) %&& ~test_false
                vec_FF=Data.(Data.ListVarName{ivar_FF_vec}); % flags for false vectors
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
            Coord_x=reshape(Data.(XName),1,[]);
            Coord_y=reshape(Data.(YName),1,[]);
            [A,Coord_x,Coord_y]=proj_grid(Coord_x',Coord_y',A',[],[],'np>256');  % interpolate on a grid
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
            XName=Data.ListVarName{CellInfo{icell}.CoordIndex(end)};
            Coord_y=Data.(YName);
            Coord_x=Data.(XName);
            test_interp_X=0; %default, regularly meshed X coordinate
            test_interp_Y=0; %default, regularly meshed Y coordinate
%             if isfield(Data,'VarAttribute')
%                 if numel(Data.VarAttribute)>=CellInfo{icell}.CoordIndex(end) && isfield(Data.VarAttribute{CellInfo{icell}.CoordIndex(end)},'units')
%                     x_units=Data.VarAttribute{CellInfo{icell}.CoordIndex(end)}.units;
%                 end
%                 if numel(Data.VarAttribute)>=CellInfo{icell}.CoordIndex(end-1) && isfield(Data.VarAttribute{CellInfo{icell}.CoordIndex(end-1)},'units')
%                     y_units=Data.VarAttribute{CellInfo{icell}.CoordIndex(end-1)}.units;
%                 end
%             end
            if numel(Coord_y)>2
                DCoord_y=diff(Coord_y);
                DCoord_y_min=min(DCoord_y);
                DCoord_y_max=max(DCoord_y);
                if sign(DCoord_y_min)~=sign(DCoord_y_max);% =1 for increasing values, 0 otherwise
                    errormsg=['errror in plot_field.m: non monotonic dimension variable ' YName ];
                    return
                end
                test_interp_Y=(DCoord_y_max-DCoord_y_min)> 0.0001*abs(DCoord_y_max);
            end
            if numel(Coord_x)>2
                DCoord_x=diff(Coord_x);
                DCoord_x_min=min(DCoord_x);
                DCoord_x_max=max(DCoord_x);
                if sign(DCoord_x_min)~=sign(DCoord_x_max)% =1 for increasing values, 0 otherwise
                    errormsg=['errror in plot_field.m: non monotonic dimension variable ' Data.ListVarName{VarRole.coord(2)} ];
                    return
                end
                test_interp_X=(DCoord_x_max-DCoord_x_min)> 0.0001*abs(DCoord_x_max);
            end
            if test_interp_Y
                npxy(1)=max([256 floor((Coord_y(end)-Coord_y(1))/DCoord_y_min) floor((Coord_y(end)-Coord_y(1))/DCoord_y_max)]);
                yI=linspace(Coord_y(1),Coord_y(end),npxy(1));
                if ~test_interp_X
                    xI=linspace(Coord_x(1),Coord_x(end),size(A,2));%default
                    Coord_x=xI;
                end
            end
            if test_interp_X
                npxy(2)=max([256 floor((Coord_x(end)-Coord_x(1))/DCoord_x_min) floor((Coord_x(end)-Coord_x(1))/DCoord_x_max)]);
                xI=linspace(Coord_x(1),Coord_x(end),npxy(2));
                if ~test_interp_Y
                    yI=linspace(Coord_y(1),Coord_y(end),size(A,1));
                    Coord_y=yI;
                end
            end
            if test_interp_X || test_interp_Y
                [Coord_x2D,Coord_y2D]=meshgrid(Coord_x,Coord_y);
                A=interp2(Coord_x2D,Coord_y2D,double(A),xI,yI');
            end
            Coord_x=[Coord_x(1) Coord_x(end)];% keep only the lower and upper bounds for image represnetation
            Coord_y=[Coord_y(1) Coord_y(end)];
        end
    end
    %define coordinates as CoordUnits, if not defined as attribute for each variable
%     if isfield(Data,'VarAttribute')&& numel(Data.VarAttribute)>=1 && isfield(Data.VarAttribute{1},'unit')
%         y_units=Data.VarAttribute{1}.unit;
%     end
    if isfield(Data,'CoordUnit')
        if isempty(x_units)
            x_units=Data.CoordUnit;
        end
        if isempty(y_units)
            y_units=Data.CoordUnit;
        end
    elseif isfield(Data,'VarAttribute')
        if numel(Data.VarAttribute)>=CellInfo{icell}.CoordIndex(end) && isfield(Data.VarAttribute{CellInfo{icell}.CoordIndex(end)},'units')
            x_units=Data.VarAttribute{CellInfo{icell}.CoordIndex(end)}.units;
        end
        if numel(Data.VarAttribute)>=CellInfo{icell}.CoordIndex(end-1) && isfield(Data.VarAttribute{CellInfo{icell}.CoordIndex(end-1)},'units')
            y_units=Data.VarAttribute{CellInfo{icell}.CoordIndex(end-1)}.units;
        end
    end
end

PlotParamOut=PlotParam; % output plot parameters equal to input by default

%%   image or scalar plot %%%%%%%%%%%%%%%%%%%%%%%%%%
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
    
    %set for grey scale setting
    ColorMap='default';
    if isfield(PlotParam.Scalar,'CheckBW') && ~isempty(PlotParam.Scalar.CheckBW)
        ColorMap=PlotParam.Scalar.CheckBW; %BW=0 color imposed, else gray scale imposed.
    elseif ((siz==2) && (isa(A,'uint8')|| isa(A,'uint16')))% non color images represented in gray scale by default
        ColorMap='grayscale';
    end
    PlotParamOut.Scalar.CheckBW=ColorMap;
    % determine the plot option 'image' or 'contours'
    CheckContour=0; %default
    if isfield(PlotParam.Scalar,'ListContour')
        CheckContour=strcmp(PlotParam.Scalar.ListContour,'contours');% =1 for contour plot option
    end
    
    %case of grey level images or contour plot
    if ~isfield(PlotParam.Scalar,'CheckFixScalar')
        PlotParam.Scalar.CheckFixScalar=0;% free scalar threshold value scale (from min to max) by default
    end
    if ~isfield(PlotParam.Scalar,'MinA')
        PlotParam.Scalar.MinA=[];%no min scalar threshold value set
    end
    if ~isfield(PlotParam.Scalar,'MaxA')
        PlotParam.Scalar.MaxA=[];%no max scalar threshold value set
    end
    
    % determine the min scalar value
    if PlotParam.Scalar.CheckFixScalar && ~isempty(PlotParam.Scalar.MinA) && isnumeric(PlotParam.Scalar.MinA)
        MinA=double(PlotParam.Scalar.MinA); % min value set as input
    else
        MinA=double(min(min(min(A)))); % min value set as min of non NaN scalar values
    end
    
    % error if the input scalar is NaN everywhere
    if isnan(MinA)
        errormsg='NaN input scalar or image in plot_field';
        return
    end
    
    % determine the max scalar value
    CheckFixScalar=0;
    if PlotParam.Scalar.CheckFixScalar && ~isempty(PlotParam.Scalar.MaxA) && isnumeric(PlotParam.Scalar.MaxA)
        MaxA=double(PlotParam.Scalar.MaxA); % max value set as input
        CheckFixScalar=1; 
    else
        MaxA=double(max(max(max(A)))); % max value set as min of non NaN scalar values
    end
    
    PlotParamOut.Scalar.MinA=MinA;
    PlotParamOut.Scalar.MaxA=MaxA;
    PlotParamOut.Scalar.Npx=size(A,2);
    PlotParamOut.Scalar.Npy=size(A,1);
    
    % case of contour plot
    if CheckContour
        if ~isempty(hima) && ishandle(hima)
            delete(hima) % delete existing image
        end
        
        % set the contour values
        if ~isfield(PlotParam.Scalar,'IncrA')
            PlotParam.Scalar.IncrA=[];% automatic contour interval
        end
        if ~isempty(PlotParam.Scalar.IncrA) && isnumeric(PlotParam.Scalar.IncrA)
            interval=PlotParam.Scalar.IncrA;
        else % automatic contour interval
            cont=colbartick(MinA,MaxA);
            interval=cont(2)-cont(1);%default
            PlotParamOut.Scalar.IncrA=interval;% set the interval as output for display on the GUI
        end
        abscontmin=interval*floor(MinA/interval);
        abscontmax=interval*ceil(MaxA/interval);
        contmin=interval*floor(min(min(A))/interval);
        contmax=interval*ceil(max(max(A))/interval);
        cont_pos_plus=0:interval:contmax;% zero and positive contour values (plotted as solid lines)
        cont_pos_min=double(contmin):interval:-interval;% negative contour values (plotted as dashed lines)
        cont_pos=[cont_pos_min cont_pos_plus];% set of all contour values
        
        sizpx=(Coord_x(end)-Coord_x(1))/(np(2)-1);
        sizpy=(Coord_y(1)-Coord_y(end))/(np(1)-1);
        x_cont=Coord_x(1):sizpx:Coord_x(end); % pixel x coordinates for image display
        y_cont=Coord_y(1):-sizpy:Coord_y(end); % pixel x coordinates for image display
        
        tag_axes=get(haxes,'Tag');% axes tag
        Opacity=1;
        if isfield(PlotParam.Scalar,'Opacity')&&~isempty(PlotParam.Scalar.Opacity)
            Opacity=PlotParam.Scalar.Opacity;
        end
        % fill the space between contours if opacity is undefined or =1
        if isequal(Opacity,1)
            [var,hcontour]=contour(haxes,x_cont,y_cont,A,cont_pos);% determine all contours
            set(hcontour,'Fill','on')% fill the space between contours
            set(hcontour,'LineStyle','none')
            hold on
        end
        [var_p,hcontour_p]=contour(haxes,x_cont,y_cont,A,cont_pos_plus,'k-');% draw the contours for positive values as solid lines
        hold on
        [var_m,hcontour_m]=contour(haxes,x_cont,y_cont,A,cont_pos_min,'--');% draw the contours for negative values as dashed lines
        if isequal(Opacity,1)
            set(hcontour_m,'LineColor',[1 1 1])% draw negative contours in white (better visibility in dark background)
        end
        set(haxes,'Tag',tag_axes);% restore axes tag (removed by the matlab fct contour !)
        hold off
        
        %determine the color scale and map
        caxis([abscontmin abscontmax])
        if strcmp(ColorMap,'grayscale')
            vec=linspace(0,1,(abscontmax-abscontmin)/interval);%define a greyscale colormap with steps interval
            map=[vec' vec' vec'];
            colormap(map);
        elseif strcmp(ColorMap,'BuYlRd')
            hh=load('BuYlRd.mat');
            colormap(hh.BuYlRd);
        else
            colormap(ColorMap); 
        end
    else %usual images (no contour)
        % set  colormap for  image display
        if strcmp(ColorMap,'grayscale')
            vec=linspace(0,1,255);%define a linear greyscale colormap
            map=[vec' vec' vec'];
            colormap(map);  %grey scale color map
            if siz==3% true color images visualized in BW
                A=uint16(sum(A,3));%sum the three color components for color images displayed with BW option
            end
        elseif strcmp(ColorMap,'BuYlRd')
            hh=load('BuYlRd.mat');
            colormap(hh.BuYlRd);
        else
            if siz==3 && CheckFixScalar % true color images rescaled by MaxA
                  A=uint8(255*double(A)/double(MaxA));
            end
            colormap(ColorMap); % standard false colors for div, vort , scalar fields
        end
        
        % interpolate field to increase resolution of image display
        test_interp=0;
        if size(A,3)==1 % scalar or B/W image
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
        end
        if test_interp%if we interpolate
            x=linspace(Coord_x(1),Coord_x(2),np(2));
            y=linspace(Coord_y(1),Coord_y(2),np(1));
            [X,Y]=meshgrid(x,y);
            xi=linspace(Coord_x(1),Coord_x(2),npxy(2));
            yi=linspace(Coord_y(1),Coord_y(2),npxy(1));
            A = interp2(X,Y,double(A),xi,yi');
        end
        % create new image if no image handle is found
        if isempty(hima)
            tag=get(haxes,'Tag');
            if MinA<MaxA
                hima=imagesc(Coord_x,Coord_y,A,[MinA MaxA]);
            else % to deal with uniform field
                hima=imagesc(Coord_x,Coord_y,A,[MaxA-1 MaxA]);
            end
            % the function imagesc reset the axes 'DataAspectRatioMode'='auto', change if .CheckFixAspectRatio is
            % requested:
            set(hima,'Tag','ima')
            set(hima,'HitTest','off')
            set(haxes,'Tag',tag);%preserve the axes tag (removed by image fct !!!)
            uistack(hima, 'bottom')
            % update an existing image
        else
            set(hima,'CData',A);
            if MinA<MaxA
                set(haxes,'CLim',[MinA MaxA])
            else
                set(haxes,'CLim',[MinA MaxA+1])
            end
            set(hima,'XData',Coord_x);
            set(hima,'YData',Coord_y);
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
    if isfield(PlotParam.Axes,'CheckFixAspectRatio') && isequal(PlotParam.Axes.CheckFixAspectRatio,1)
        set(haxes,'DataAspectRatioMode','manual')
        if isfield(PlotParam.Axes,'AspectRatio')
            set(haxes,'DataAspectRatio',[PlotParam.Axes.AspectRatio 1 1])
        else
            set(haxes,'DataAspectRatio',[1 1 1])
        end
    end
    test_ima=1;
    
    %display the colorbar code for B/W images if Poscolorbar not empty
    if ~isempty(PosColorbar)
        if size(A,3)==1 && exist('PosColorbar','var')
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
    if size(vec_U,1)==numel(vec_Y) && size(vec_U,2)==numel(vec_X) % x, y  coordinate variables
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
        if ~isempty(ivar_FF_vec)
           vec_FF=vec_FF(ind_sel);
        end
    end
    
    %get main level color code
    [colorlist,col_vec,PlotParamOut.Vectors]=set_col_vec(PlotParam.Vectors,vec_C);
    
    % take flags into account: add flag colors to the list of colors
    nbcolor=size(colorlist,1);
    if test_black 
       nbcolor=nbcolor+1;
       colorlist(nbcolor,:)=[0 0 0]; %add black to the list of colors
       if ~isempty(ivar_FF_vec)
            col_vec(vec_F~=1 & vec_F~=0 & vec_FF==0)=nbcolor;
       else
            col_vec(vec_F~=1 & vec_F~=0)=nbcolor;
       end
    end
    nbcolor=nbcolor+1;
    if ~isempty(ivar_FF_vec)
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

%store the coordinate extrema occupied by the field
if ~isempty(Data)
    MinX=[];
    MaxX=[];
    MinY=[];
    MaxY=[];
    fix_lim=isfield(PlotParam.Axes,'CheckFixLimits') && PlotParam.Axes.CheckFixLimits;
    if fix_lim
        if isfield(PlotParam.Axes,'MinX')&&isfield(PlotParam.Axes,'MaxX')&&isfield(PlotParam.Axes,'MinY')&&isfield(PlotParam.Axes,'MaxY')
            MinX=PlotParam.Axes.MinX;
            MaxX=PlotParam.Axes.MaxX;
            MinY=PlotParam.Axes.MinY;
            MaxY=PlotParam.Axes.MaxY;
        end  %else PlotParamOut.MinX =PlotParam.MinX...
    else
        if test_ima %both background image and vectors coexist, take the wider bound
            MinX=min(Coord_x);
            MaxX=max(Coord_x);
            MinY=min(Coord_y);
            MaxY=max(Coord_y);
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
    PlotParamOut.Axes.MinX=MinX;
    PlotParamOut.Axes.MaxX=MaxX;
    PlotParamOut.Axes.MinY=MinY;
    PlotParamOut.Axes.MaxY=MaxY;
    if MaxX>MinX
        set(haxes,'XLim',[MinX MaxX]);% set x limits of frame in axes coordinates
    end
    if MaxY>MinY
        set(haxes,'YLim',[MinY MaxY]);% set x limits of frame in axes coordinates
    end
    set(haxes,'YDir','normal')
    set(get(haxes,'XLabel'),'String',[XName ' (' x_units ')']);
    set(get(haxes,'YLabel'),'String',[YName ' (' y_units ')']);
    PlotParamOut.Axes.x_units=x_units;
    PlotParamOut.Axes.y_units=y_units;
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
set(haxes,'NextPlot','replacechildren');

%create lines (if no lines) or modify them
if ~isequal(size(col_vec),size(x))
    col_vec=ones(size(x));% case of error in col_vec input
end
nbcolor=size(colorlist,1);

for icolor=1:nbcolor
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
%            set(h(2*icolor-1),'EraseMode','xor');
            set(h(2*icolor),'Xdata',matxar,'Ydata',matyar);
            set(h(2*icolor),'Color',colorlist(icolor,:));
            %set(h(2*icolor),'EraseMode','xor');
        end
    end
end
if sizh(1) > 2*nbcolor
    for icolor=nbcolor+1 : sizh(1)/2 %delete additional objects
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
    xi=rangx(1):dxy(2):rangx(2);
    yi=rangy(1):dxy(1):rangy(2);
    A=griddata(vec_X,vec_Y,vec_A,xi,yi'); 
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
