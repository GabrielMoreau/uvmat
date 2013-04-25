% 'uvmat_demo': script for demonstration, TEST STAGE

%%%% Demo 1%%%%
pause on
% brigtness
activate('uvmat','Scalar','num_MaxA',100)
pause
activate('uvmat','Scalar','CheckFixScalar',0)
pause
activate('uvmat','Scalar','CheckZoom',1)
pause
activate('uvmat',[],'movie_pair',1)
pause
activate('uvmat',[],'STOP',1)
activate('uvmat',[],'i1','2')
