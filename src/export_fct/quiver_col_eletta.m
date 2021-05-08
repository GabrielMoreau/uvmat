%'quiver_col_eletta': plot vector fields and save figures for project Coriolis/2019/TUBE
%------------------------------------------------------------------------

%INPUT:
% handles: Matlab structure containing all the information displyed in the GUI uvmat


function quiver_col_eletta(handles)
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
SubDir=get(handles.SubDir,'String');
RootFile=get(handles.RootFile,'String');
FileIndex=get(handles.FileIndex,'String');

%% Calibration:
% plot parameters
nBits = 64;
scale = 0.15;
decimation = 16;
% filtering procedure
method = 'gaussian';
window = 24;

%% get colormap
load('BuYlRd.mat')
BuYlRd = BuYlRd(1:floor(size(BuYlRd)/nBits):end,:);

%% reduce the number of arrows
x = Data.coord_x(1:decimation:end,1:decimation:end);
y = flipud(Data.coord_y(1:decimation:end,1:decimation:end));
[X,Y] = meshgrid(x,y);
% Filtering data to take away spurious subsampling issues (see Shannon Theorem)
filtU = smoothdata(flipud(Data.U   ),method,window);
filtV = smoothdata(flipud(Data.V   ),method,window);
filtS = smoothdata(flipud(Data.norm),method,window);

U = filtU(1:decimation:end,1:decimation:end);
V = filtV(1:decimation:end,1:decimation:end);
S = filtS(1:decimation:end,1:decimation:end);
zmin = min(min(S));
zmax = max(max(S));
bins = linspace(zmin,zmax,nBits);

%% plot size and position in the figure
width = 6.75;     % Width in inches 
height = 6;    % Height in inches 
alw = 0.75;    % AxesLineWidth 
fsz = 12;      % Fontsize 
lw = 1.25;      % LineWidth 
msz = 8;       % MarkerSize 

%% make the plot  
figure(1)
ax2 = axes('Visible','off','HandleVisibility','off');
pos = get(1, 'Position');
set(1, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
set(ax2, 'FontSize', fsz, 'LineWidth', lw); %<- Set properties
set(1, 'defaultTextInterpreter','latex');
for i = 1:nBits-1
    ii=find((S - bins(i+1) < 0).*(S - bins(i) > 0));
    quiver(X(ii),Y(ii),U(ii),V(ii), scale,'Color',BuYlRd(i,:), 'LineWidth',1.2)
    hold on
end
cc=colorbar;
set(cc,'TickLabelInterpreter','latex')
cc.Label.String='cm/s';
caxis([zmin zmax])
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


