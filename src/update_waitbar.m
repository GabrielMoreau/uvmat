%'update_waitbar': update the waitbar display, used for ACTION functions in the GUI 'series'
%------------------------------------------------------------------
%INPUT:
% hwaitbar:  handles of the waitbar to update
% bar_size: vector with 4 elements, representing the abscissa, ordinate, width, height of the waitbar relative to the GUI  
% advance_ratio: number between 0 and 1 representing the advancement of the calculation (loop index relative to the total length)

function update_waitbar(hwaitbar,bar_size,advance_ratio)
% waitbarpos(1)=bar_size(1);
% waitbarpos(3)=bar_size(3);
% waitbarpos(4)=advance_ratio*bar_size(4);
% waitbarpos(2)=bar_size(4)+bar_size(2)-waitbarpos(4);
% set(hwaitbar,'Position',waitbarpos)
set(hwaitbar,'Units','pixels')
pos=get(hwaitbar,'Position');
CData=zeros([floor(pos(4)) floor(pos(3)) 3]);
set(hwaitbar,'Units','normalized')
CData(:,1:floor(advance_ratio*size(CData,2)),1:2)=1;
set(hwaitbar,'CData',CData)
drawnow