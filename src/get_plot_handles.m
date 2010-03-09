%'get_plot_handles': list the  handles of elements setting the plotting parameters in the uvmat interface
%--------------------------------------------------------
%function [PlotHandles]=get_plot_handles(handles)
%
% OUTPUT:
% PlotHandles: structure containing the  used to set plotting parameters
% INPUT:
% handles: structure of the handles of the graphic elements in the uvmat interface
%            -- TODO: needs to be replaced by a cell listing the element tags --

function PlotHandles=get_plot_handles(handles)
PlotHandles.auto_xy=handles.auto_xy;
%For scalar field representation
PlotHandles.MaxA=handles.MaxA;
PlotHandles.MinA=handles.MinA;
PlotHandles.AutoScal=handles.AutoScal;
PlotHandles.BW=handles.BW;
PlotHandles.Contours=handles.Contours;
PlotHandles.IncrA=handles.IncrA;
PlotHandles.SCALAR_title=handles.SCALAR_title;
PlotHandles.min_title=handles.min_title;
PlotHandles.max_title=handles.max_title;
PlotHandles.frame_scal=handles.frame_scal;
PlotHandles.npx=handles.npx;
PlotHandles.npy=handles.npy;
PlotHandles.npx_title=handles.npx_title;
PlotHandles.npy_title=handles.npy_title;

%For vector field representation
PlotHandles.frame_vect=handles.frame_vect;
PlotHandles.VECT_title=handles.VECT_title;
PlotHandles.VecScale=handles.VecScale;
PlotHandles.AutoVec=handles.AutoVec;
PlotHandles.HideFalse=handles.HideFalse;
PlotHandles.HideWarning=handles.HideWarning;
PlotHandles.record=handles.record;
PlotHandles.col_vec=handles.col_vec;
PlotHandles.Color_title=handles.Color_title;
PlotHandles.color_code=handles.color_code;
PlotHandles.colcode1=handles.colcode1;
PlotHandles.colcode2=handles.colcode2;
PlotHandles.vec_col_bar=handles.vec_col_bar;
PlotHandles.slider1=handles.slider1;
PlotHandles.slider2=handles.slider2;
PlotHandles.max_vec=handles.max_vec;
PlotHandles.min_vec=handles.min_vec;
PlotHandles.scale_title=handles.scale_title;
PlotHandles.AutoVecColor=handles.AutoVecColor;
PlotHandles.decimate4=handles.decimate4;
PlotHandles.min_C_title=handles.min_C_title;
PlotHandles.max_C_title=handles.max_C_title;
%PlotHandles.MenuVectors=handles.MenuVectors;
PlotHandles.MenuEditVectors=handles.MenuEditVectors;
PlotHandles.edit_vect=handles.edit_vect;
%menu for the choice of the current plotting axes
%PlotHandles.MenuAxes=handles.MenuAxes;

%handles for move_mouse
PlotHandles.mouse_coord=handles.mouse_coord;
% PlotHandles.POINTS=handles.POINTS;
% PlotHandles.LINE=handles.LINE;
% PlotHandles.PLANE=handles.PLANE;
% PlotHandles.PATCH=handles.PATCH;
PlotHandles.cal=handles.cal;
%PlotHandles.makemask=handles.makemask;
PlotHandles.edit=handles.edit;
PlotHandles.text_display_1=handles.text_display_1;
PlotHandles.text_display_2=handles.text_display_2;
PlotHandles.text_display_3=handles.text_display_3;
PlotHandles.text_display_4=handles.text_display_4;

%handles for mouse_up
PlotHandles.zoom=handles.zoom;