%'ima_ratio': take the ratio of two input images with same size
%
% the two fields are subtstracted when of the same nature (scalar or
% vector), if the coordinates do not coincide, the second field is
% interpolated on the cooridintes of the first one
%
% when scalar and vectors are combined, the fields are just merged in a single matlab structure for common visualisation
%-----------------------------------------------------------------------
% function SubData=sub_field(Field,XmlData,Field_1)
%
% OUPUT: 
% SubData: structure representing the resulting field
%
% INPUT: 
% Field: matlab structure representing the first field
% XmlData: input calibration parameter, not used
% Field_1:matlab structure representing the second field

function DataOut=ima_ratio(DataIn,XmlData,DataIn_1)

%% option to introduce input parameters when function is selected, skipped here
DataOut=DataIn;
if ~isstruct(DataOut)
%     if ~isfield(DataIn,'A')
%         msgbox_uvmat('ERROR','ima_ratio requires two images of the same size as input')
    return
    end


%% actual calculation
if exist('DataIn_1','var')
    DataIn_1.A(DataIn_1.A==0)=1;
    DataOut.A=double(DataIn.A)./double(DataIn_1.A);
end
