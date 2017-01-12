function [CineFileHeader, BitmapInfoHeader, CameraSetup, imageLocations,  annotationSize] = readCineHeader(filePath)

fid = fopen(filePath);

CineFileHeader.Type = fread(fid, 1, 'uint16');
CineFileHeader.Headersize = fread(fid, 1, 'uint16');
CineFileHeader.Compression = fread(fid, 1, 'uint16');
CineFileHeader.Version = fread(fid, 1, 'uint16');
CineFileHeader.FirstMovieImage = fread(fid, 1, 'int32');
CineFileHeader.TotalImageCount = fread(fid, 1, 'uint32');
CineFileHeader.FirstImageNo = fread(fid, 1, 'int32');
CineFileHeader.ImageCount = fread(fid, 1, 'uint32');
CineFileHeader.OffImageHeader = fread(fid, 1, 'uint32');
CineFileHeader.OffSetup = fread(fid, 1, 'uint32');
CineFileHeader.OffImageOffsets = fread(fid, 1, 'uint32');
CineFileHeader.TriggerTime = fread(fid, 1, 'uint64')/2^32; % Epoch time (secs since jan 1, 1970)
%CineFileHeader.TriggerTime2 = fread(fid, 1, 'uint32');

BitmapInfoHeader.biSize = fread(fid, 1, 'int32');
BitmapInfoHeader.biWidth = fread(fid, 1, 'int32');
BitmapInfoHeader.biHeight = fread(fid, 1, 'int32');
BitmapInfoHeader.biPlanes = fread(fid, 1, 'uint16');
BitmapInfoHeader.biBitCount = fread(fid, 1, 'uint16');
BitmapInfoHeader.biCompression = fread(fid, 1, 'uint32');
BitmapInfoHeader.biSizeImage = fread(fid, 1, 'uint32');
BitmapInfoHeader.biXPelsPerMeter= fread(fid, 1, 'uint32');
BitmapInfoHeader.biYPelsPerMeter= fread(fid, 1, 'int32');
BitmapInfoHeader.biClrUsed = fread(fid, 1, 'uint32');
BitmapInfoHeader.biClrImportant = fread(fid, 1, 'uint32');

fseek(fid, hex2dec('0354'), 'bof');
CameraSetup.FrameRate = fread(fid, 1, 'uint32');

fseek(fid, hex2dec('0360'), 'bof');
CameraSetup.PostTrigger = fread(fid, 1, 'uint32');

fseek(fid, hex2dec('03D4'), 'bof');
CameraSetup.RealBPP = fread(fid, 1, 'uint32');

fseek(fid, hex2dec('16B8'), 'bof');
CameraSetup.BlackLevel = fread(fid, 1, 'uint32');

fseek(fid, hex2dec('16BC'), 'bof');
CameraSetup.WhiteLevel = fread(fid, 1, 'uint32');

fseek(fid, hex2dec('1B48'), 'bof');
CameraSetup.fGain16_8 = fread(fid, 1, 'float32');

fseek(fid, hex2dec('17CC'), 'bof');
CameraSetup.fOffset = fread(fid, 1, 'float32');

fseek(fid, hex2dec('17D0'), 'bof');
CameraSetup.fGain = fread(fid, 1, 'float32');

fseek(fid, hex2dec('17DC'), 'bof');
CameraSetup.fGamma = fread(fid, 1, 'float32');

fseek(fid, hex2dec('27D4'), 'bof');
CameraSetup.RecBPP = fread(fid, 1, 'uint32');


fseek(fid, CineFileHeader.OffImageOffsets, 'bof');
imageBlockLocations = fread(fid, CineFileHeader.ImageCount, 'int64');


fseek(fid, imageBlockLocations(1), 'bof');
annotationSize = fread(fid, 1, 'uint32');


imageLocations = imageBlockLocations + annotationSize;

fclose(fid);