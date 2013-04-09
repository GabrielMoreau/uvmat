%'get_index_range': gives the file index ranges from the input structure obtained by GUI reading 
% to use in Action fcts activated by 'series'
%------------------------------------------------------------------------
% [first_i,incr_i,last_i,first_j,incr_j,last_j,errormsg]=get_index_range(IndexRange)
%
% OUTPUT:
% first_i,incr_i,last_i,first_j,incr_j,last_j: values of first index,increment and last index for i and j, =1 by default
% errorms: error message if the input is not in good order
%
% INPUT:
% IndexRange: structure with possible fields first_i,incr_i,last_i,first_j,incr_j,last_j

function [first_i,incr_i,last_i,first_j,incr_j,last_j,errormsg]=get_index_range(IndexRange)
first_i=1;
last_i=1;
incr_i=1;
first_j=1;
last_j=1;
incr_j=1;
errormsg='';
if isfield(IndexRange,'first_i')
    first_i=IndexRange.first_i;
    incr_i=IndexRange.incr_i;
    last_i=IndexRange.last_i;
end
if isfield(IndexRange,'first_j')
    first_j=IndexRange.first_j;
    last_j=IndexRange.last_j;
    incr_j=IndexRange.incr_j;
end
if last_i < first_i || last_j < first_j 
   errormsg='last field index must be larger or equal to the first one';
end