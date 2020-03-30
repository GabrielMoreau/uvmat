% add an index to a name, or increment an existing index, if the proposed Name (char string) already exists in the list ListName (cell)
function NewName = rename_indexing(Name,ListName)

detectname=1;
NewName=Name;
while ~isempty(detectname)
    detectname=find(strcmp(NewName,ListName),1);%test the existence of the proposed name in the list
    if detectname% if the name already exist
        rr=regexp(NewName,'(\d+)$'); %look for numerical indexing at the end of NewName
        if isempty(rr)
            NewName=[NewName '_1'];%add the index 1
        else
            newindex=str2num(NewName(rr:end))+1; %increment the index by 1
            NewName=[NewName(1:rr-1) num2str(newindex)];
        end
    end
end