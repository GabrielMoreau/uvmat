% 'uvmat_demo': script for demonstration, TEST STAGE

%%%% Demo 1%%%%
% brigtness
huvmat=findobj(allchild(0),'Tag','uvmat');
uistack(huvmat,'top')
activate('uvmat','Scalar','num_MaxA',[],100)
activate('uvmat','Scalar','CheckFixScalar',[],0)
activate('uvmat','Coordinates','CheckZoom',[],1)
activate('uvmat',[],'PlotAxes',[0.2 0.6])
%activate('uvmat',[],'movie_pair',[],1)
%activate('uvmat',[],'STOP',[],1)
activate('uvmat',[],'i1',[],'2')
