%'write_plot_param': update the plotting parameters on the uvmat interface after a plotting operation
function write_plot_param(handles,PlotParam)
%% coordinates
if isfield(PlotParam,'Coordinates')
    Coordinates=PlotParam.Coordinates;
    if isfield(Coordinates,'CheckFixEqual')
        if Coordinates.CheckFixEqual
            set(handles.CheckFixEqual,'Value',1)
            set(handles.CheckFixEqual,'BackgroundColor',[1 1 0])
        else
            set(handles.CheckFixEqual,'Value',0)
            set(handles.CheckFixEqual,'BackgroundColor',[0.7 0.7 0.7])
        end
    end
    if isfield(Coordinates,'MinX')
        set(handles.num_MinX,'String',num2str(Coordinates.MinX,4));
        set(handles.num_MaxX,'String',num2str(Coordinates.MaxX,4));
        set(handles.num_MinY,'String',num2str(Coordinates.MinY,4));
        set(handles.num_MaxY,'String',num2str(Coordinates.MaxY,4));
    else
        set(handles.num_MinX,'String','');
        set(handles.num_MaxX,'String','');
        set(handles.num_MinY,'String','');
        set(handles.num_MaxY,'String','');
    end
end

%% scalar or image parameters
if isfield(PlotParam,'Scalar')
    set(handles.Scalar,'Visible','on')
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
    set(handles.Scalar,'Visible','off')
end

%% parameter for vector field
if isfield(PlotParam,'Vectors')
    set(handles.Vectors,'Visible','on')
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
    set(handles.Vectors,'Visible','off')
    if isfield(handles,'edit_vect')
        set(handles.edit_vect,'Visible','off')
        set(handles.record,'Visible','off')
    end
end
