function GUI_input=FFT(hget_field)
global spec x_vec
%requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
if ~exist('hget_field','var')
    GUI_input={'check_1Dplot'};
    return %exit the function 
end

%initiation
hhget_field=guidata(hget_field);
% testinterp=0;
abscissa_list=get(hhget_field.abscissa,'String');
val=get(hhget_field.abscissa,'Value');
val=val(1);
abscissa_name=abscissa_list{val};
ordinate_list=get(hhget_field.ordinate,'String');
val=get(hhget_field.ordinate,'Value');
val=val(1); %take only the first variable in the list

%ordinate_name=Field.ListVarName{val};
ordinate_name=ordinate_list{val};

[Field,errormsg]=read_get_field(hget_field);
if ~isempty(errormsg)
    msgbox_uvmat('ERROR',['error in get_field/FFT input:' errormsg])
    return
end

% get variable
eval(['Var= Field.' ordinate_name ';']);
np=size(Var);
np_freq=floor(np(1)/2);
dx=1;%default
dfreq=1/np(1);%default frequency interval (abscissa= array index)
if ~isequal(abscissa_name,'')
    eval(['Coord_x= Field.' abscissa_name ';']);
    ind_select=find(~isinf(Coord_x));%detect infinite values
    Coord_x=Coord_x(ind_select);
    Var=Var(ind_select,:);
    diff_x=diff(Coord_x);
    dx=min(diff_x);
    %interpolate on a regular abscissa interval if needed
    if (max(diff_x)-dx)> 0.001*dx || numel(ind_select)<np(1)
        xequ=Coord_x(1):dx:Coord_x(end);%equal time spacingdx=
        Var=interp1(Coord_x,Var,xequ); %interpolated func
        np=size(Var);
    end
 %   funcinterp=interp1(time,func,timeq); %interpolated func
    dfreq=1/(Coord_x(end)-Coord_x(1));%frequency interval
end
freq_max=1/(2*dx);
Var=Var-ones(np(1),1)*mean(Var,1); %substract mean value
fourier=fft(Var);%take fft (complex)
spec=abs(fourier).*abs(fourier);% take square of the modulus
spec=spec(1:np_freq,:);%keep only the first half (the other is symmetric)

%plot
list_fig=get(hhget_field.list_fig,'String');
val=get(hhget_field.list_fig,'Value');
hfig=str2num(list_fig{val})% chosen figure number from tyhe GUI
if isempty(hfig)
    hfig=figure;
else
    figure(hfig);
end
haxes=findobj(hfig,'Type','axes');
if ~isempty(haxes)
    axes(haxes)
end
x_vec=linspace(dfreq,freq_max,np_freq);
plot(x_vec',spec)
xlabel('frequency (Hz)')
ylabel('spectral intensity')
grid on

% 
% 
% np=length(funcinterp);
% funcinterp=funcinterp-sum(funcinterp)/np; %substract mean
% fourier=fft(funcinterp);%take fft (complex)
% spec=abs(fourier).*abs(fourier);% take sqare of the modulus
% spec=spec([1:floor(np/2)]);%keep only the first half (the other is symmetric)
% eval(['Field.' varname '=spec;'])
% Field
% % dfreq=1/(time(end)-time(1));%frequency interval
% % freq=[0:dfreq:(floor(np/2)-1)*dfreq];
% % figure(1)
% % hold on
% % plot(freq,spec)
% % xlabel('frequency (Hz)')
% % ylabel('spectral intensity')
% % title(['spectrum of' fields]);
% % grid on
%  