%'plot_text': function for displaying the content of a Matlab structure in a figure
%------------------------------------------------------------------------
% function hdisplay=plot_text(FieldData,hdisplay_in)
%
% OUTPUT:
% hdisplay: handle of the display edit box
%
%  INPUT: 
% FieldData: input Matlab structure
% hdisplay_in: handles of the display box, if it is not defined create a new figure
%
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%  Copyright Joel Sommeria, 2008, LEGI / CNRS-UJF-INPG, sommeria@coriolis-legi.org.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
%     This file is part of the toolbox UVMAT.
% 
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (file UVMAT/COPYING.txt) for more details.
%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

function hdisplay=plot_text(FieldData,hdisplay_in)

if exist('hdisplay_in','var') & ishandle(hdisplay_in) & isequal(get(hdisplay_in,'Type'),'uicontrol')
    hdisplay=hdisplay_in;
else
    figure;%create new figure
    hdisplay=uicontrol('Style','edit', 'Units','normalized','Position', [0 0 1 1],'Max',2,'FontName','monospaced');
end
    
ff=fields(FieldData);%list of field names
vv=struct2cell(FieldData);%list of field values

for icell=1:length(vv)
    Tabcell{icell,1}=ff{icell};
    ss=vv{icell};
    sizss=size(ss);
    if isnumeric(ss)
        if sizss(1)<=1 & length(ss)<5
            displ{icell}=num2str(ss);
        else
            displ{icell}=[class(ss) ', size ' num2str(size(ss))];
        end
    elseif ischar(ss)
        displ{icell}=ss;
    elseif iscell(ss)
        sizcell=size(ss);
        if sizcell(1)==1 & length(sizcell)==2 %line cell
           ssline='{''';
           for icolumn=1:sizcell(2)
               if isnumeric(ss{icolumn})
                   if size(ss{icolumn},1)<=1 & length(ss{icolumn})<5
                      sscolumn=num2str(ss{icolumn});%line vector
                   else
                      sscolumn=[class(ss{icolumn}) ', size ' num2str(size(ss{icolumn}))];
                   end
               elseif ischar(ss{icolumn})
                   sscolumn=ss{icolumn};
               else
                   sscolumn=class(ss{icolumn});
               end
               if icolumn==1
                   ssline=[ssline sscolumn];
               else
                   ssline=[ssline ''',''' sscolumn];
               end
           end
           displ{icell}=[ssline '''}'];
        else
           displ{icell}=[class(ss) ', size ' num2str(sizcell)];
        end
    else
        displ{icell}=class(ss);
    end
    Tabcell{icell,2}=displ{icell};
end 
Tabchar=cell2tab(Tabcell,': '); 
set(hdisplay,'String', Tabchar)


