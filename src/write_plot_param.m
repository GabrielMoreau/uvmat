%'write_plot_param': update the plotting parameters on the uvmat interface after a plotting operation
function write_plot_param(handles,PlotParam)
%coordinates
if isfield(PlotParam,'FixEqual')
    if PlotParam.FixEqual
        set(handles.CheckFixEqual,'Value',1)
        set(handles.CheckFixEqual,'BackgroundColor',[1 1 0])
    else
        set(handles.CheckFixEqual,'Value',0)
        set(handles.CheckFixEqual,'BackgroundColor',[0.7 0.7 0.7])
    end
end
if isfield(PlotParam,'MinX')
    set(handles.num_MinX,'String',num2str(PlotParam.MinX,4));
    set(handles.num_MaxX,'String',num2str(PlotParam.MaxX,4));
    set(handles.num_MinY,'String',num2str(PlotParam.MinY,4));
    set(handles.num_MaxY,'String',num2str(PlotParam.MaxY,4));
else
    set(handles.num_MinX,'String','');
    set(handles.num_MaxX,'String','');
    set(handles.num_MinY,'String','');
    set(handles.num_MaxY,'String','');
end

%scalar or image parameters
if isfield(PlotParam,'Scalar')
    set_scal_display(handles,'on')
    if isfield(PlotParam.Scalar,'MaxA')
        set(handles.num_MaxA,'String',num2str(PlotParam.Scalar.MaxA,3));
    end
    if isfield(PlotParam.Scalar,'MinA')
        set(handles.num_MinA,'String',num2str(PlotParam.Scalar.MinA,3));
    end

    if isfield(PlotParam.Scalar,'IncrA')
        set(handles.num_IncrA,'String',num2str(PlotParam.Scalar.IncrA,3))
    end
else
    set_scal_display(handles,'off')
end

% parameter for vector field
if isfield(PlotParam,'Vectors')
    set_vect_display(handles,'on')
    if isfield(PlotParam.Vectors,'VecScale')
        set(handles.num_VecScale,'String',num2str(PlotParam.Vectors.VecScale,3))
    end
    if isfield(PlotParam.Vectors,'MinC')&& isfield(PlotParam.Vectors,'MaxC')
        MinC=PlotParam.Vectors.MinC;
        MaxC=PlotParam.Vectors.MaxC;
        set(handles.min_vec,'String', num2str(MinC,3));
        set(handles.max_vec,'String',num2str(MaxC,3));
        list=get(handles.color_code,'String');
        ichoice=get(handles.color_code,'Value');
    	color_option=list{ichoice};
        test3color=strcmp(color_option,'rgb')||strcmp(color_option,'bgr');
        if test3color% need to update color thresholds
            set(handles.colcode1,'Visible','on')
            set(handles.colcode2,'Visible','on')
            set(handles.slider1,'Visible','on')
            set(handles.slider2,'Visible','on')
%             slider1=get(handles.slider1,'Value');
%             slider2=get(handles.slider2,'Value');
             colcode1=MinC+(MaxC-MinC)*PlotParam.Vectors.colcode1;
             colcode2=MinC+(MaxC-MinC)*PlotParam.Vectors.colcode2;
            set(handles.colcode1,'String',num2str(colcode1,3))
            set(handles.colcode2,'String',num2str(colcode2,3))
            set(handles.slider1,'Value',PlotParam.Vectors.colcode1)
            set(handles.slider2,'Value',PlotParam.Vectors.colcode2)
        else
            set(handles.colcode1,'Visible','off')
            set(handles.colcode2,'Visible','off')
            set(handles.slider1,'Visible','off')
            set(handles.slider2,'Visible','off')
        end
    end
else
    set_vect_display(handles,'off')
    if isfield(handles,'edit_vect')
        set(handles.edit_vect,'Visible','off')
        set(handles.record,'Visible','off')
    end
end

%------------------------------------------------------------------
%prepare interface for scalar display: state ='on' or 'off'
function set_scal_display(handles,state)
%------------------------------------------------------------------
set(handles.Scalar,'Visible',state)
% set(handles.num_MaxA,'Visible',state)
% set(handles.num_MinA,'Visible',state)
% %set(handles.IncrA,'Visible',state)
% set(handles.CheckFixScalar,'Visible',state)
% set(handles.CheckBW,'Visible',state)
% set(handles.ListContour,'Visible',state)
% set(handles.TitleMinA,'Visible',state)
% set(handles.TitleMaxA,'Visible',state)
% set(handles.num_Npx,'Visible',state)
% set(handles.num_Npy,'Visible',state)
% set(handles.TitleNpx,'Visible',state)
% set(handles.TitleNpy,'Visible',state)

%---------------------------------------------
%prepare interface for vector display: state ='on' or 'off'
function set_vect_display(handles,state)
%------------------------------------------------------------------
set(handles.Vectors,'Visible',state)
% set(handles.VECT_title,'Visible',state)
% set(handles.num_VecScale,'Visible',state)
% set(handles.FixVec,'Visible',state)
% set(handles.HideFalse,'Visible',state)
% set(handles.HideWarning,'Visible',state)
% % if isfield(handles,'record')
% %     set(handles.record,'Visible',state)
% % end
% set(handles.num_ColCode1,'Visible',state)
% set(handles.num_ColCode2,'Visible',state)
% set(handles.num_MinVec,'Visible',state)
% set(handles.num_MaxVec,'Visible',state)
% set(handles.scale_title,'Visible',state)
% set(handles.slider1,'Visible',state)
% set(handles.slider2,'Visible',state)
% set(handles.col_vec,'Visible',state)
% set(handles.Color_title,'Visible',state)
% set(handles.color_code,'Visible',state)
% set(handles.vec_col_bar,'Visible',state)
% % set(handles.record,'Visible',state)
% set(handles.AutoVecColor,'Visible',state)
% set(handles.decimate4,'Visible',state)
% set(handles.min_C_title,'Visible',state)
% set(handles.max_C_title,'Visible',state)
% if isfield(handles,'MenuEditVectors')
%     set(handles.MenuEditVectors,'Enable',state)
% end
