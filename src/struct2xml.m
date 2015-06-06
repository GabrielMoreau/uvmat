%'struct2xml': transform a matlab structure to a xml tree.
%--------------------------------------------------------------
% each field with char string or num vector is transformed into a corresponding  xml element
% each field with a matrix containing n lines is transformed into a xml element repeated n times 
% WARNING: PROBLEM WITH HIERARCHICAL structures
%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT:
% t: xmltree reproducing the structure of Object
% type 'save(t)' to visualize the xml text and save(filename,t) to save it in a file
%
% INPUT:
%  Object: matlab structure, possibly hierarchical
%  t: optional input xml tree in which a new branch needs to be appended
%  root_uid: optional uid of the xml element under which the new subtree must be appended

%=======================================================================
% Copyright 2008-2015, LEGI UMR 5519 / CNRS UJF G-INP, Grenoble, France
%   http://www.legi.grenoble-inp.fr
%   Joel.Sommeria - Joel.Sommeria (A) legi.cnrs.fr
%
%     This file is part of the toolbox UVMAT.
%
%     UVMAT is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published
%     by the Free Software Foundation; either version 2 of the license,
%     or (at your option) any later version.
%
%     UVMAT is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License (see LICENSE.txt) for more details.
%=======================================================================

function t=struct2xml(Object,t,root_uid)

if ~exist('t','var')
    t=xmltree;
end
if ~exist('root_uid','var')
    root_uid=1;
end
fieldnames=fields(Object);
for ilist=1:length(fieldnames)
   val=Object.(fieldnames{ilist});
   if isstruct(val)
      [t,branch_uid]=add(t,root_uid,'element',fieldnames{ilist});
       t=struct2xml(val,t,branch_uid);
      
%       fieldnames_sub=fields(val)
%       for ilist_sub=1:length(fieldnames_sub)
%           if isstruct(fieldnames_sub{ilist_sub})
%                 t=struct2xml(fieldnames_sub{ilist_sub},t,uid);
% %                 save(t)
%           else
%               val_sub=val.(fieldnames_sub{ilist_sub});
%               t=add_element(t,uid,fieldnames_sub{ilist_sub},val_sub);
%           end
%       end
   else
       t=add_element(t,root_uid,fieldnames{ilist},val);
   end
end

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function t=add_element(t,uid,key,val)
 if ischar(val)
     [t,new_uid]=add(t,uid,'element',key);
     val=regexprep(val,'\','\\');
     [t]=add(t,new_uid,'chardata',val);
 elseif isnumeric(val)||islogical(val)
       siz=size(val);
       if length(siz)<=2 %do not translate matrices with more than 2 indices
           for iline=1:siz(1)
                val_str=num2str(val(iline,:),'%g\t');
                [t,new_uid]=add(t,uid,'element',key);
                if siz(1)>1
                    t = attributes(t,'add',new_uid,'i',num2str(iline));
                end
                [t]=add(t,new_uid,'chardata',val_str);
           end
       end
 elseif iscell(val)
      siz=size(val);
      if length(siz)<=2 %do not translate cell matrices with more than 2 indices
          separator='   '; %mark the separation of columns
          for iline=1:siz(1)
                val_str=cell2mat(cell2tab(val(iline,:),' & ')); % produce a line string with column separator ' & '
                [t,new_uid]=add(t,uid,'element',key);
                if siz(1)>1
                    t = attributes(t,'add',new_uid,'i',num2str(iline));
                end
                [t]=add(t,new_uid,'chardata',val_str);
          end
      end
 end   
