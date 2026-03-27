--------------------------------------------------
Steps for installing uvmat:
--------------------------------------------------
- Install Matlab, release R 13 or more recent. 
- Download the package appropriate to your system from http://servforge.legi.grenoble-inp.fr/projects/soft-uvmat,
or use the SVN server, see below.
- unzip the package to a convenient location. Path name must not contain blanks.
- Add this folder /uvmat to your matlab paths (option 'add folder without sub-folders'). Use the Matlab function addpath or the menu bar. 
-For reading compressed avi movies, a codec must be available on your computer. 
-uvmat uses the toolbox xmltree. In case of problem for reading xml files (problem with xml_findstr.mexglx) type the command >> mex -O xml_findstr.c or reload the package xmltree from the web.

--------------------------------------------------
Updating uvmat with the SVN server(to fill):
--------------------------------------------------

--------------------------------------------------
civx software for PIV (local version):
--------------------------------------------------
- Install uvmat as above, civ should be ready to run. 
- Binary files are provides with the package in the subdirectory /bin. They depend on the operating system, unlike the Matlab functions. 
- There are 4 separate binaries:
civ1.exe: simple correlation imaging velocimetry
civ2.exe: hierarchical algorithm for correlation imaging velocimetry
fix_flag.exe: program for removing false vectors (only needed for batch option)
patch.exe: program for thin shell spline interpolation
- These binaries can be put at a different location, then the corresponding path must be defined in the file PARAM.xml.

--------------------------------------------------
civx software for PIV:case of Mac OS
--------------------------------------------------
libpng s'installe sans problème apparemment (voir sur site), pas plus de probleme que sous linux
Pour netcdf, il faut installer macports :
http://www.macports.org/
Puis dans le dossier /opt/local/bin
sudo ./port install netcdf +g95
A ce niveau la les executables civ, patch etc .. fonctionnent dans un terminal mais pas encore
dans le shell de matlab (il manque une bibliothèque).
dans le dossier
/opt/local/lib/
cp libnetcdf.4.dylib /Applications/MATLAB_R2009b.app/bin/maci64/MATLAB.app/Content/MacOS/
ou l'on remplacera allégrement le chemin suivant la version de Matlab concernée.

--------------------------------------------------
Netcdf library needed for old versions of Matlab (if the builtin function netcdf.create does not exist):
--------------------------------------------------
- Install the (free) toolbox for reading and writing netcf files for the velocity fields: download from http://sourceforge.net/projects/mexcdf/. You must download both mexnc and netcdf_toolbox packages and 
 copy them under the folder 'toolbox' in your Matlab directory. 
- download netcdf.dll (also provided in this directory, but you may already have in bin/win32 in your Matlab directory)
(http://www.unidata.ucar.edu/software/netcdf/docs/netcdf-install/Getting-Prebuilt-DLL.html#Getting-Prebuilt-DLL)
- To check whether this installation is successful, type 'ncbrowser' on the Matlab prompt: 
 you should get a browser allowing to scan netcdf files.

--------------------------------------------------
 xml schemas
-------------------------------------------------
- Copy the schemas at a convenient location
- Document the path under the key <SchemaPath in the file 'PARAM.xml' or 'PARAM.xml'

--------------------------------------------------
Note for Linux_x86_64 systems
--------------------------------------------------
- copy the file libfftw3.so.3 in the CIVX directory (ex : ~/CIVX/bin) 
- add this entry to the .bashrc file in your home directory

export LD_LIBRARY_PATH=./CIVX/bin:$LD_LIBRARY_PATH

where "./CIVX/bin" should start from the directory you start matlab
(ex:  if you start matlab from your home "user@host~$ matlab -desktop &"
and your CIVX/bin is located in ~/CIVX/bin)

--------------------------------------------------
Note for compiling the civx software on Linux system:
-------------------------------------------------
The binaries are compiled with Intel Fortran v7 and gcc3.3; the following libraries need to be present on your sstem :
libpng: http://www.libpng.org/pub/png
intel fortran libraries, please download it here : http://www.civproject.org/files/civx/libIntel.tgz
extract them, and add the folder to you /etc/ld.so.conf file.
