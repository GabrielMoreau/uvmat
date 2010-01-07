%'set_title': defines the 'TITLE' of a projection object
%-----------------------------------------------------------
% function TITLE=set_title(Style,ProjMode)
% OUTPUT:
%    TITLE: char string defining the title
%
% INPUT:
%    Style: char string defining the style of the projection opbject
%    ProjMode:  char string defining the projection mode 
%------------------------------------------------
function TITLE=set_title(Style,ProjMode)
%------------------------------------------------
TITLE=[]; %default
if isequal(Style,'points')
    TITLE='POINTS';
elseif isequal(Style,'line')|isequal(Style,'polyline')
    TITLE='LINE';
elseif isequal(Style,'plane')
    TITLE='PLANE';
elseif isequal(Style,'volume')
    TITLE='VOLUME';
elseif isequal(Style,'polygon')|isequal(Style,'rectangle')|isequal(Style,'ellipse')
    if isequal(ProjMode,'inside')|isequal(ProjMode,'outside')
        TITLE='PATCH';
    elseif isequal(ProjMode,'mask_inside')|isequal(ProjMode,'mask_outside')
        TITLE='MASK';
    else
        TITLE='LINE';
    end
end