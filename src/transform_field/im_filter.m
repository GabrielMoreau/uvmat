function DataOut=im_filter(DataIn,Calib)
np=20 %size ofthe filtering window
%definition of the cos shape matrix filter
ix=[1/2-np/2:-1/2+np/2];%
del=np/3;
%fct=exp(-(ix/del).^2);
fct2=cos(ix/((np-1)/2)*pi/2);
%Mfiltre=(ones(5,5)/5^2);
Mfiltre=fct2'*fct2;
Mfiltre=Mfiltre/(sum(sum(Mfiltre)));%normalize filter

DataOut=DataIn; %default

Atype=class(DataIn.A)% detect integer 8 or 16 bits
DataOut.A=filter2(Mfiltre,DataIn.A); 
DataOut.A=feval(Atype,DataOut.A);
 