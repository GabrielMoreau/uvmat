%'RUN_FIX': function for fixing velocity fields:
%-----------------------------------------------
% RUN_FIX(filename,field,flagindex,thresh_vecC,thresh_vel,iter,flag_mask,maskname,fileref,fieldref)
%
%filename: name of the netcdf file (used as input and output)
%field: structure specifying the names of the fields to fix (depending on civ1 or civ2)
    %.vel_type='civ1' or 'civ2';
    %.nb=name of the dimension common to the field to fix ('nb_vectors' for civ1);
    %.fixflag=name of fix flag variable ('vec_FixFlag' for civ1)
%flagindex: flag specifying which values of vec_f are removed: 
        % if flagindex(1)=1: vec_f=-2 vectors are removed
        % if flagindex(2)=1: vec_f=3 vectors are removed
        % if flagindex(3)=1: vec_f=2 vectors are removed (if iter=1) or vec_f=4 vectors are removed (if iter=2)
%iter=1 for civ1 fields and iter=2 for civ2 fields
%thresh_vecC: threshold in the image correlation vec_C
%flag_mask: =1 mask used to remove vectors (0 else)
%maskname: name of the mask image file for fix
%thresh_vel: threshold on velocity, or on the difference with the reference file fileref if exists
%inf_sup=1: remove values smaller than threshold thresh_vel, =2, larger than threshold
%fileref: .nc file name for a reference velocity (='': refrence 0 used)
%fieldref: 'civ1','filter1'...feld used in fileref

function error=RUN_FIX(filename,field,flagindex,iter,thresh_vecC,flag_mask,maskname,thresh_vel,inf_sup,fileref,fieldref)
error=[]; %default
vel_type{1}=field.vel_type;
%check writing access
[errorread,message]=fileattrib(filename);
if ischar(message) 
    msgbox_uvmat('ERROR',[filename ':' message]);
    return
end
if ~isequal(message.UserWrite,1)
     msgbox_uvmat('ERROR',['no writting access to ' filename ' (RUN_FIX.m)']);
    return
end
Field=read_civxdata(filename,'ima_cor',field.vel_type);
if isfield(Field,'Txt')
    error=Field.Txt; %error in reading
    return
end

if ~isfield(Field,'X') || ~isfield(Field,'Y') || ~isfield(Field,'U') || ~isfield(Field,'V')
    error=['input file ' filename ' does not contain vectors in RUN_FIX.m']; %bad input file
    return
end
if ~isfield(Field,'C')
    Field.C=ones(size(Field.X));%correlation=1 by default
end
if ~isfield(Field,'F')
    Field.F=ones(size(Field.X));%warning flag=1 by default
end
if ~isfield(Field,'FF')
    Field.FF=zeros(size(Field.X));%fixflag=0 by default
end

vec_f_unit=abs(Field.F)-10*double(uint16(abs(Field.F)/10)); %unityterm of vec_F in abs value
vec_f_sign=sign(Field.F).*vec_f_unit;% gives the unity digit of vec_f with correct sign
flag1=(flagindex(1)==1)&(vec_f_sign==-2);%removed vectors vec_f=-2
flag2=(flagindex(2)==1)&(vec_f_sign==3);%removed vectors vec_f=3
if iter==1
        flag3=(flagindex(3)==1)&(vec_f_sign==2); % Hart vectors
elseif iter==2
        flag3=(flagindex(3)==1)&(vec_f_sign==4); % 
end
flag4=(Field.C < thresh_vecC)&(flag1~=1)&(flag2~=1)&(flag3~=1); % =1 for low vec_C vectors not previously removed

% criterium on velocity values
delta_u=Field.U;%default without ref file
delta_v=Field.V;
if exist('fileref','var') && ~isempty(fileref)
    if ~exist(fileref,'file')
        error='reference file not found in RUN_FIX.m';
        display(error);
        return
    end
    FieldRef=read_civxdata(fileref,[],fieldref);   
    if isfield(FieldRef,'FF')
        index_true=find(FieldRef.FF==0);
        FieldRef.X=FieldRef.X(index_true);
        FieldRef.Y=FieldRef.Y(index_true);
        FieldRef.U=FieldRef.U(index_true);
        FieldRef.V=FieldRef.V(index_true);
    end
    if ~isfield(FieldRef,'X') || ~isfield(FieldRef,'Y') || ~isfield(FieldRef,'U') || ~isfield(FieldRef,'V')
        error='reference file is not a velocity field in RUN_FIX.m '; %bad input file
        return
    end
    if length(FieldRef.X)<=1
        errordlg('reference field with one vector or less in RUN_FIX.m')
        return
    end
    vec_U_ref=griddata_uvmat(FieldRef.X,FieldRef.Y,FieldRef.U,Field.X,Field.Y);  %interpolate vectors in the ref field
    vec_V_ref=griddata_uvmat(FieldRef.X,FieldRef.Y,FieldRef.V,Field.X,Field.Y);  %interpolate vectors in the ref field to the positions  of the main field     
    delta_u=Field.U-vec_U_ref;%take the difference with the interpolated ref field
    delta_v=Field.V-vec_V_ref;
end
thresh_vel_x=thresh_vel; 
thresh_vel_y=thresh_vel; 
if isequal(inf_sup,1)
    flag5=abs(delta_u)<thresh_vel_x & abs(delta_v)<thresh_vel_y &(flag1~=1)&(flag2~=1)&(flag3~=1)&(flag4~=1);
elseif isequal(inf_sup,2)
    flag5=(abs(delta_u)>thresh_vel_x | abs(delta_v)>thresh_vel_y) &(flag1~=1)&(flag2~=1)&(flag3~=1)&(flag4~=1);
end

            % flag7 introduce a grey mask, matrix M
if isequal (flag_mask,1)
   M=imread(maskname);
   nxy=size(M);
   M=reshape(M,1,nxy(1)*nxy(2));
   rangx0=[0.5 nxy(2)-0.5];
   rangy0=[0.5 nxy(1)-0.5];
   vec_x1=Field.X-Field.U/2;%beginning points
   vec_x2=Field.X+Field.U/2;%end points of vectors
   vec_y1=Field.Y-Field.V/2;%beginning points
   vec_y2=Field.Y+Field.V/2;%end points of vectors
   indx=1+round((nxy(2)-1)*(vec_x1-rangx0(1))/(rangx0(2)-rangx0(1)));% image index x at abcissa vec_x
   indy=1+round((nxy(1)-1)*(vec_y1-rangy0(1))/(rangy0(2)-rangy0(1)));% image index y at ordinate vec_y   
   test_in=~(indx < 1 |indy < 1 | indx > nxy(2) |indy > nxy(1)); %=0 out of the mask image, 1 inside
   indx=indx.*test_in+(1-test_in); %replace indx by 1 out of the mask range
   indy=indy.*test_in+(1-test_in); %replace indy by 1 out of the mask range
   ICOMB=((indx-1)*nxy(1)+(nxy(1)+1-indy));%determine the indices in the image reshaped in a Matlab vector
   Mvalues=M(ICOMB);
   flag7b=((20 < Mvalues) & (Mvalues < 200))| ~test_in';
   indx=1+round((nxy(2)-1)*(vec_x2-rangx0(1))/(rangx0(2)-rangx0(1)));% image index x at abcissa Field.X
   indy=1+round((nxy(1)-1)*(vec_y2-rangy0(1))/(rangy0(2)-rangy0(1)));% image index y at ordinate vec_y
   test_in=~(indx < 1 |indy < 1 | indx > nxy(2) |indy > nxy(1)); %=0 out of the mask image, 1 inside
   indx=indx.*test_in+(1-test_in); %replace indx by 1 out of the mask range
   indy=indy.*test_in+(1-test_in); %replace indy by 1 out of the mask range
   ICOMB=((indx-1)*nxy(1)+(nxy(1)+1-indy));%determine the indices in the image reshaped in a Matlab vector
   Mvalues=M(ICOMB);
   flag7e=((Mvalues > 20) & (Mvalues < 200))| ~test_in';
   flag7=(flag7b|flag7e)';
else
   flag7=0;
end   
flagmagenta=flag1|flag2|flag3|flag4|flag5|flag7;
fixflag_unit=Field.FF-10*floor(Field.FF/10); %unity term of fix_flag

%write fix flags in the netcdf file
hhh=which('netcdf.open');% look for built-in matlab netcdf library
if ~isequal(hhh,'')% case of new builtin Matlab netcdf library
    nc=netcdf.open(filename,'NC_WRITE'); 
    netcdf.reDef(nc)
    if iter==1
        netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),'fix1',1)
    elseif iter==2
        netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),'fix2',1)
    end
    dimid = netcdf.inqDimID(nc,field.nb); 
    try
        varid = netcdf.inqVarID(nc,field.fixflag);% look for already existing fixflag variable
    catch
        varid=netcdf.defVar(nc,field.fixflag,'double',dimid);%create fixflag variable if it does not exist
    end
    netcdf.endDef(nc)
    netcdf.putVar(nc,varid,fixflag_unit+10*flagmagenta);
    netcdf.close(nc)
else %old netcdf library
    netcdf_toolbox(filename,Field,flagmagenta,iter,field)
end

function netcdf_toolbox(filename,Field,flagmagenta,iter,field)
nc=netcdf(filename,'write'); %open netcdf file for writing
result=redef(nc);
if isempty(result), msgbox_uvmat('ERROR','##Bad redef operation.'),end  
if iter==1
    nc.fix=1;
elseif iter==2
    nc.fix2=1;
end
nc{field.fixflag}=ncfloat(field.nb);
fixflag_unit=Field.FF-10*floor(Field.FF/10); %unity term of fix_flag
nc{field.fixflag}(:)=fixflag_unit+10*flagmagenta;
close(nc);
