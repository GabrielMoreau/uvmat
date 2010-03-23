%'read_plot_param':  read plotting parameters from the interface uvmat
%------------------------------------------
% function PlotParam=read_plot_param(handles)
%
% OUTPUT:
% PlotParam: structure containing the values of all the relevant plotting parameters 
%
% INPUT: 
% handles: structure containing the handles of the relevant uicontrols in the uvmat interface 
%
%      -- TODO:   get the handles using get_plot_handles and findobj as  default input --

function PlotParam=read_plot_param(handles)

PlotParam.Auto_xy=get(handles.auto_xy,'Value');
PlotParam.FixedLimits=get(handles.FixedLimits,'Value');

% scalars
Scalar.MaxA=str2double(get(handles.MaxA,'String'));
Scalar.MinA=str2double(get(handles.MinA,'String'));
Scalar.AutoScal=get(handles.AutoScal,'Value');
Scalar.BW=get(handles.BW,'Value');
Scalar.Contours=get(handles.Contours,'Value')==2;
Scalar.IncrA=str2double(get(handles.IncrA,'String'));
PlotParam.Scalar=Scalar;

%vectors
Vectors.VecScale=str2double(get(handles.VecScale,'String'));
Vectors.AutoVec=get(handles.AutoVec,'Value');%automatic vector length
Vectors.HideFalse=get(handles.HideFalse,'Value');
Vectors.HideWarning=get(handles.HideWarning,'Value');
Vectors.decimate4=get(handles.decimate4,'Value');% =1; for reducing the nbre of vectors

%vector color
code_list=get(handles.color_code,'String');
val=get(handles.color_code,'Value');
% menu_col=get(handles.col_vec,'String');
% menu_val=get(handles.col_vec,'Value');
colcode1=str2double(get(handles.colcode1,'String'));% first threshold for rgb, first value for'continuous' 
colcode2=str2double(get(handles.colcode2,'String'));% second threshold for rgb, last value (saturation) for 'continuous' 

Vectors.ColorCode=code_list{val}; % option of color code for vectors
Vectors.FixedCbounds=get(handles.AutoVecColor,'Value');% =1; fixed scale for color vector, =0 otherwise (default)
Vectors.MinC=str2num(get(handles.min_vec,'String')); % imposed min of C, (needed if .FixedCbounds=1)
Vectors.MaxC=str2num(get(handles.max_vec,'String')); % imposed max of C, needed if .FixedCbounds=1
if Vectors.MaxC <= Vectors.MinC
    Vectors.ColorCode='black';
else
    Vectors.colcode1=Vectors.MinC+(colcode1-Vectors.MinC)/(Vectors.MaxC-Vectors.MinC);% relative thresholds
    Vectors.colcode2=Vectors.MinC+(colcode2-Vectors.MinC)/(Vectors.MaxC-Vectors.MinC);
end
PlotParam.Vectors=Vectors;

