% 'FFT': calculate and display spectrum of the field selected in the GUI  get_field 
%  GUI_input=FFT(hget_field)
%
% OUTPUT: 
% GUI_input: option for display in the GUI get_field
%
%INPUT:
% hget_field: handles of the GUI get_field

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

function DataOut=signal_FFT(DataIn)
% global spec x_vec
% %requests for the visibility of input windows in the GUI series  (activated directly by the selection in the menu ACTION)
% if ~exist('hget_field','var')
%     GUI_input={'check_1Dplot'};
%     return %exit the function 
% end
% GUI_input=[];
% %initiation
% hhget_field=guidata(hget_field);
% abscissa_list=get(hhget_field.abscissa,'String');
% val=get(hhget_field.abscissa,'Value');
% val=val(1);
% abscissa_name=abscissa_list{val};
% ordinate_list=get(hhget_field.ordinate,'String');
% val=get(hhget_field.ordinate,'Value');
% val=val(1); %take only the first variable in the list
DataOut=DataIn;
ordinate_name=DataIn.ListVarName{2};
abscissa_name=DataIn.ListVarName{1};

% get variable
Var= DataIn.(ordinate_name);
Coord_x= DataIn.(abscissa_name);
np=size(Var);
np_freq=floor(np(1)/2);
dx=1;%default
dfreq=1/np(1);%default frequency interval (abscissa= array index)
sum_data=sum(Var,2);

ind_select=find(~isinf(Coord_x)&~isnan(sum_data));%detect infinite values
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
freq_max=1/(2*dx);
Var=Var-ones(np(1),1)*mean(Var,1); %substract mean value
fourier=fft(Var);%take fft (complex)
spec=abs(fourier).*abs(fourier);% take square of the modulus
spec=spec(1:np_freq,:);%keep only the first half (the other is symmetric)

%plot
figure(2);
x_vec=linspace(dfreq,freq_max,np_freq);
plot(x_vec',spec)
xlabel('frequency (Hz)')
ylabel('spectral intensity')
grid on

