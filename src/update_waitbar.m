%'update_waitbar': update the waitbar display, used for ACTION functions in the GUI 'series'
%------------------------------------------------------------------
%INPUT:
% hwaitbar:  handles of the waitbar to update
% advance_ratio: number between 0 and 1 representing the advancement of the calculation (loop index relative to the total length)

function update_waitbar(hwaitbar,advance_ratio)
if ishandle(hwaitbar)
set(hwaitbar,'Units','pixels')
pos=get(hwaitbar,'Position');%read waitbar position in pixels
set(hwaitbar,'Units','normalized')%set back to normalize(the waitbar scales with the GUI)
CData=ones(floor(pos(4)),floor(pos(3)),3);
CData(:,:,3)=0 ;% initial color yellow (rgb=[1 1 0])
CData(:,1:floor(advance_ratio*size(CData,2)),2)=0; % advancement part in red (suppress the second color component green)
set(hwaitbar,'CData',CData)
drawnow
end