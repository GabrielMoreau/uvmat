%pyenv('Version', '/usr/bin/python3')
system('pip install rawpy')
pyrun('import rawpy')
pyrun('print ("python loaded")')
%pyrun('importlib.import_module(''rawpy'')')
pyrun('filename=''/fsnet/project/coriolis/2026/26STAIRWAY/0_DATA/EXP28/GLOBAL/IXM150/cap-19106.IIQ''')
img =double(pyrun('img= rawpy.imread(filename).postprocess()','img'));
size(img)