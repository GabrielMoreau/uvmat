function [CineFileHeader, BitmapInfoHeader, CameraSetup, TimeOnlyBlock, ExposureOnlyBlock, TimeCodeBlock, imageLocations,  annotationSize] = readCineHeader(filePath)

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

fseek(fid, hex2dec('00E2'), 'bof');
CameraSetup.Length = fread(fid, 1, 'uint16');

fseek(fid, hex2dec('0370'), 'bof');
CameraSetup.FirmwareVersion = fread(fid, 1, 'uint32');

fseek(fid, hex2dec('0374'), 'bof');
CameraSetup.SoftwareVersion = fread(fid, 1, 'uint32');

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


%% Tagged Information Blocks
% AnalogDigitalSignals (ADS) -> not contained in MIRO cine-files
% ImageTimeTaggedBlock (ITTB) -> not contained in MIRO cine-files

% TimeOnlyBlock (TOB) -> Type should be 1002
PositionTOB = CineFileHeader.OffSetup + CameraSetup.Length;
fseek(fid, PositionTOB , 'bof');
TimeOnlyBlock.Length = fread(fid, 1, 'uint32');
TimeOnlyBlock.Type = fread(fid, 1, 'uint16');
TimeOnlyBlock.Reserved = fread(fid, 1, 'uint16');
TimeOnlyBlock.Data = transpose([1:CineFileHeader.ImageCount ; fread(fid,[2,CineFileHeader.ImageCount], 'uint32')]); % Framenumber combined with Data contained in TOB
TimeOnlyBlock.TimestampsDatetime = datetime(TimeOnlyBlock.Data(:,3), 'ConvertFrom', 'posixtime');  % Timestamp as Datetime
% TimeOnlyBlock.TimestampsDatestr = datestr(TimeOnlyBlock.TimestampsDatetime);  % Timestamp as String
TimeOnlyBlock.TimestampsMillisec = TimeOnlyBlock.Data(:,2)./(2^32);    % Milliseconds of the Timestamp
TimeOnlyBlock.ExposureTimeDelays = [0 ; TimeOnlyBlock.TimestampsMillisec(2:end)-TimeOnlyBlock.TimestampsMillisec(1:end-1)]; % Timedifference between two frames. First frame is set to have no timedifference

% ExposureOnlyBlock (EOB) -> Type should be 1003
PositionEOB = PositionTOB + TimeOnlyBlock.Length;
fseek(fid, PositionEOB , 'bof');
ExposureOnlyBlock.Length = fread(fid, 1, 'uint32');
ExposureOnlyBlock.Type = fread(fid, 1, 'uint16');
ExposureOnlyBlock.Reserved = fread(fid, 1, 'uint16');
ExposureOnlyBlock.Data = fread(fid,CineFileHeader.ImageCount, 'uint32');
ExposureOnlyBlock.ExposureTimesMillisec = ExposureOnlyBlock.Data ./(2^32) .*1000;
ExposureOnlyBlock.test1 = fread(fid, 1, 'uint32');
ExposureOnlyBlock.test2 = fread(fid, 1, 'uint16');
ExposureOnlyBlock.test3 = fread(fid, 1, 'uint16');

% RangeDataBlock (RDB) -> not contained in MIRO cine-files
% BinSigBlock (BSB) -> not contained in MIRO cine-files
% AnaSigBlock (ASB) -> not contained in MIRO cine-files

% TimeCodeBlock (TCB)  -> Type should be 1007
PositionTCB = PositionEOB + ExposureOnlyBlock.Length;
fseek(fid, PositionTCB , 'bof');
TimeCodeBlock.Length = fread(fid, 1, 'uint32');
TimeCodeBlock.Type = fread(fid, 1, 'uint16');
TimeCodeBlock.Reserved = fread(fid, 1, 'uint16');
TimeCodeBlock.Data = fread(fid, 1, 'uint8');


%% Image Locations and their Annotations
fseek(fid, CineFileHeader.OffImageOffsets, 'bof');
imageBlockLocations = fread(fid, CineFileHeader.ImageCount, 'int64');

fseek(fid, imageBlockLocations(1), 'bof');
annotationSize = fread(fid, 1, 'uint32');

imageLocations = imageBlockLocations + annotationSize;


%%
fclose(fid);