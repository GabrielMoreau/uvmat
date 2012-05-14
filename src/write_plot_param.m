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
    set(handles.CheckBW,'Value',PlotParam.Scalar.CheckBW)
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
        set(handles.num_MinVec,'String', num2str(MinC,3));
        set(handles.num_MaxVec,'String',num2str(MaxC,3));
        list=get(handles.ColorCode,'String');
        ichoice=get(handles.ColorCode,'Value');
        color_option=list{ichoice};
        test3color=strcmp(color_option,'rgb')||strcmp(color_option,'bgr');
        if test3color% need to update color thresholds
            set(handles.num_ColCode1,'Visible','on')
            set(handles.num_ColCode2,'Visible','on')
            set(handles.Slider1,'Visible','on')
            set(handles.Slider2,'Visible','on')
            %ColCode1=MinC+(MaxC-MinC)*PlotParam.Vectors.ColCode1;
            %ColCode2=MinC+(MaxC-MinC)*PlotParam.Vectors.ColCode2;
%             ColCode1=MinC+(MaxC-MinC)*PlotParam.Vectors.ColCode1;
            %ColCode2=MinC+(MaxC-MinC)*PlotParam.Vectors.ColCode2;
            set(handles.num_ColCode1,'String',num2str(PlotParam.Vectors.ColCode1,3))
            set(handles.num_ColCode2,'String',num2str(PlotParam.Vectors.ColCode2,3))
            set(handles.Slider1,'Value',(PlotParam.Vectors.ColCode1-MinC)/(MaxC-MinC))
            set(handles.Slider2,'Value',(PlotParam.Vectors.ColCode2-MinC)/(MaxC-MinC))
        else
            set(handles.num_ColCode1,'Visible','off')
            set(handles.num_ColCode2,'Visible','off')
            set(handles.Slider1,'Visible','off')
            set(handles.Slider2,'Visible','off')
        end
    end
else
    set(handles.Vectors,'Visible','off')
    if isfield(handles,'edit_vect')
        set(handles.edit_vect,'Visible','off')
        set(handles.record,'Visible','off')
    end
end
