%'griddata_uvmat': function griddata_uvmat(vec2_X,vec2_Y,vec2_U,vec_X,vec_Y,'linear')
%adapt the input of the matlab function griddata to the appropriate version of Matlab
function ZI = griddata_uvmat(X,Y,Z,XI,YI)
% if ~exist('rho','var')|| isequal(rho,0)
    txt=ver('MATLAB');
    Release=txt.Release;
    relnumb=str2num(Release(3:4));
    if relnumb >= 20
        ZI=griddata(double(X),double(Y),double(Z),double(XI),double(YI),'linear',{'QJ'});
    elseif relnumb >=14
        ZI=griddata(X,Y,Z,XI,YI,'linear',{'QJ'});
    else
        ZI=griddata(X,Y,Z,XI,YI,'linear');
    end
% else %smooth with thin plate spline
%     [ZI,Z_diff]=patch_uvmat(X,Y,Z,XI,YI,rho);
%     diff_norm=mean(Z_diff.*Z_diff)
%     ind_good=find(abs(Z_diff)<5*diff_norm);
%     nb_remove=numel(Z_diff)-numel(ind_good)
%     if nb_remove>0
%     X=X(ind_good);
%     Y=Y(ind_good);
%     Z=Z(ind_good);
%     [ZI,Z_diff]=patch_uvmat(X,Y,Z,XI,YI,rho);
%     diff_norm_new=mean(Z_diff.*Z_diff)
%     end
% end