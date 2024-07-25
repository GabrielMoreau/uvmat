Project='/.fsnet/project/coriolis/2024/24PLUME/0_REF_FILES';
npx_ima=2560;npy_ima=2160;
Dx=10;
nbinterv_x=floor((npx_ima-1)/Dx);
gridlength_x=nbinterv_x*Dx;
minix=ceil((npx_ima-gridlength_x)/2);
xpos=minix:Dx:npx_ima-1;
ypos=[120:2:130 135:5:400 410:10:npy_ima];
ydiff=diff(ypos);
corrbox_y=2*[ydiff ydiff(end)];
[GridX,GridY]=meshgrid(xpos,ypos);
[~,CorrBoxY]=meshgrid(ones(size(xpos)),corrbox_y);
CorrBoxX=400./CorrBoxY+1;
max(max(CorrBoxX))

figure
plot(GridX,GridY,'+')
Data.ListVarName={'Grid','CorrBox'};
Data.VarDimName={{'nbvec','NbDim'},{'nbvec','NbDim'}};
Data.Grid=zeros(numel(CorrBoxX),2);
Data.Grid(:,1)=reshape(GridX,[],1);
Data.Grid(:,2)=reshape(GridY,[],1);% increases with array index
Data.CorrBoxSize=zeros(numel(CorrBoxX),2);
Data.CorrBoxSize(:,1)=reshape(CorrBoxX,[],1);
Data.CorrBoxSize(:,2)=reshape(CorrBoxY,[],1);% increases with array index

struct2nc(fullfile(Project,'grid.nc'),Data)