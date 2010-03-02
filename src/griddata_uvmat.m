%'griddata_uvmat': function griddata_uvmat(vec2_X,vec2_Y,vec2_U,vec_X,vec_Y,'linear')
%adapt the input of the matlab function griddata to the appropriate version of Matlab
function ZI = griddata_uvmat(X,Y,Z,XI,YI)
txt=ver;
Release=txt(1).Release;
relnumb=str2num(Release(3:4));
if relnumb >= 14
    ZI=griddata(X,Y,Z,XI,YI,'linear',{'QJ'});
else
    ZI=griddata(X,Y,Z,XI,YI,'linear');
end

