function [i1,i2,j1,j2]=str2num_uvmat(ss)
i1=str2double(ss.('i1'));
i2=str2double(ss.('i2'));
j1=str2double(ss.('j1')(2:end));
j2=str2double(ss.('j2')(2:end));