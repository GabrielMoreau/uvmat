--------------------------------------------------
Steps for installing uvmat:
--------------------------------------------------
- Install Matlab, release R 13 or more recent. 
 
- Copy the whole UVMAT directory at a convenient location. Be careful on Windows machines:
 names of files and directories used must not contain blanks.
- Add the full path of this UVMAT directory, as well as the ones of the mexnc, netcdf_toolbox and bin (or bin/win32) folder, 
to the current matlab function paths (using 'File/SetPath...' in the matlab menu bar), so that 
function names are recognized from the Matlab prompt.
-For reading avi movies, a codec must be available on the computer. This is the case for instance if a 
fire wire port has been installed. See the documentation of Matlab for more details. 

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
Installing the civx software with the matlab interface (local version):
--------------------------------------------------
- Install uvmat as above.
- Copy at a convenient location the executable binary civ (still under tests) and netcdf.dll (vrsion 3.4). 
-Document the path to these binaries by editing the corresponding xml text files 'PARAM_WIN.xml' (for windows systems) and/or 'PARAM_LINUX.xml' (for Linux), which must stay in the UVMAT directory.
-Alternatively, use the older versions involving 4 separate binaries:
civ1.exe: simple correlation imaging velocimetry
civ2.exe: hierarchical algorithm for correlation imaging velocimetry
fix_flag.exe: program for removing false vectors (only needed for batch option)
patch.exe: program for thin shell spline interpolation

--------------------------------------------------
Note for compiling the civx software on Linux system:
-------------------------------------------------
The binaries are compiled with Intel Fortran v7 and gcc3.3; the following libraries need to be present on your sstem :
libpng: http://www.libpng.org/pub/png
intel fortran libraries, please download it here : http://www.civproject.org/files/civx/libIntel.tgz
extract them, and add the folder to you /etc/ld.so.conf file.

--------------------------------------------------
Installation of advanced geometric callibration (Tsai method)
-------------------------------------------------
- Copy at a convenient location the executable binary ccal_fo. 
- Document the path under the key <GeometryCalib_exe> in the file 'PARAM_WIN.xml' or 'PARAM_LINUX.xml'

--------------------------------------------------
Installation of xml schemas
-------------------------------------------------
- Copy the schemas at a convenient location
- Document the path under the key <SchemaPath in the file 'PARAM_WIN.xml' or 'PARAM_LINUX.xml'

-------------------------------------------------
Changes: uvmat2.1 -> 2.2:
-------------------------------------------------
- reading avi movies using mmreader (for version 2009 of matalb)
- rationalisation of netcdf reading and writing functions, using functions UVMAT/nc2struct and UVMAT/struct2nc. Use of builtin netcdf Matlab function when available (version 2009)
- replacement of all functions using image processing toolbox.
- improvement of vector color representation
- improvement of the get_field interface to scan and plot fields from general netcdf files 