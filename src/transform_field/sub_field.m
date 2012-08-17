%'sub_field': combines two input fields
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
% Field_1:matlab structure representing the second field

function SubData=sub_field(Field,XmlData,Field_1)
if exist('Field_1','var')
SubData=sub_field(Field,XmlData,Field_1);
else
    SubData=[];
end
