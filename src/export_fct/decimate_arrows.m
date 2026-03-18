%'decimate_arrows': plot 2D arrays of vector fields with color according to vector modulus, and save figures 
%------------------------------------------------------------------------

%INPUT:
% handles: Matlab structure containing all the information displayed in the GUI uvmat

function decimate_arrows(handles)
%------------------------------------------------------------------------

%% get input data
Data_uvmat=get(handles.uvmat,'UserData');
Data=Data_uvmat.Field; %get the current plotted field
requested=isfield(Data,'coord_x')&&isfield(Data,'coord_y')&&isfield(Data,'U')&&isfield(Data,'V')&&isfield(Data,'norm');
if ~requested
    msgbox_uvmat('ERROR','unappropriate data: need vectors U, V on a regular grid')
    return
end
RootPath=get(handles.RootPath,'String');
RootFile=get(handles.RootFile,'String');
FileIndex=get(handles.FileIndex,'String');

%% Calibration:
% plot parameters
nBits = 64;
scale = 0.05;
decimation = 8;
% filtering procedure
method = 'gaussian';
window = 24;

%% get colormap
load('BuYlRd.mat','BuYlRd')
BuYlRd = BuYlRd(1:floor(size(BuYlRd,1)/nBits):end,:);

%% reduce the number of arrows
x = Data.coord_x(1:decimation:end);
y = Data.coord_y(1:decimation:end);
[X,Y] = meshgrid(x,y);
X=reshape(X,1,[]);
Y=reshape(Y,1,[]);
% Filtering data to take away spurious subsampling issues (see Shannon Theorem)
filtU = smoothdata(Data.U,method,window,'omitnan');
filtV = smoothdata(Data.V,method,window,'omitnan');

U = reshape(filtU(1:decimation:end,1:decimation:end),1,[]);
V = reshape(filtV(1:decimation:end,1:decimation:end),1,[]);
S = sqrt(U.*U+V.*V);
zmin = min(S);
zmax = max(S);
bins = linspace(zmin,zmax,nBits);
plot_scale=sqrt((x(2)-x(1))*(y(2))-y(1));% typical distance between arrows
scale_factor=plot_scale/zmax; % set the maximum arrow length to the typical distance between arrows
U=scale_factor*U;
V=scale_factor*V;

%% plot size and position in the figure
width = 6.75;     % Width in inches 
height = 6;    % Height in inches 
fsz = 12;      % Fontsize 
lw = 1.25;      % LineWidth  

%% make the plot  
figure(1)
clf
ax2 = axes('Visible','off','HandleVisibility','off');
pos = get(1, 'Position');
set(1, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
set(ax2, 'FontSize', fsz, 'LineWidth', lw); %<- Set properties
set(1, 'defaultTextInterpreter','latex');
for i = 1:nBits-1
    ii=find((S - bins(i+1) <= 0).*(S - bins(i) > 0));
    quiver(X(ii),Y(ii),U(ii),V(ii),'off','Color',BuYlRd(i,:),'LineWidth',1.2,'MaxHeadSize',scale_factor*bins(i))
    hold on
end
%quiver(X,Y,U,V)
cc=colorbar;
set(cc,'TickLabelInterpreter','latex')
cc.Label.String='cm/s';
clim([zmin zmax])
axis equal
xlim([Data.coord_x(1),Data.coord_x(end)])
ylim([Data.coord_y(1),Data.coord_y(end)])
hold off
xlabel('$x(cm)$')
ylabel('$y(cm)$')

%% Set the figure size 
set(1,'InvertHardcopy','on');
set(1,'PaperUnits', 'centimeters');
papersize = get(1, 'PaperSize');
left = (papersize(1)- width)/2;
bottom = (papersize(2)- height)/2;
myfiguresize = [left, bottom, width, height];
set(1,'PaperPosition', myfiguresize);

%% Save the figure as a pdf file in the appropriate figure folder
[pp,camera]=fileparts(RootPath);
[ppp,exp]=fileparts(pp);
FigPath=fullfile(fileparts(ppp),'0_FIG')
if ~exist(FigPath,'dir')
    [s,msg]=mkdir(FigPath); %create the folder if it does not exist
    if s
        disp([FigPath ' created'])
    else
        msgbox_uvmat('ERROR',msg)
        return
    end
end
exppath = fullfile(FigPath,exp);
if ~exist(exppath,'dir')
    [s,msg]=mkdir(exppath);%create the folder if it does not exist
    if s
        disp([exppath ' created'])
    else
        msgbox_uvmat('ERROR',msg)
        return
    end
end
camerapath=fullfile(exppath,camera);
if ~exist(camerapath,'dir')
    [s,msg]=mkdir(camerapath);%create the folder if it does not exist
    if s
        disp([camerapath ' created'])
    else
        msgbox_uvmat('ERROR',msg)
        return
    end
end

outputname=fullfile(camerapath,[RootFile FileIndex '.pdf']);
print(1,outputname,'-dpdf')
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


