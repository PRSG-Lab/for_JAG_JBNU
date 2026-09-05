function [value,found,fieldUsed] = get_alias_value(S,aliases)
%GET_ALIAS_VALUE Retrieve a struct field using normalized aliases.
value=[];found=false;fieldUsed='';if isempty(S)||~isstruct(S),return;end
fn=fieldnames(S);normFn=cellfun(@normalize_field_name,fn,'UniformOutput',false);
for a=1:numel(aliases)
    key=normalize_field_name(aliases{a});idx=find(strcmp(normFn,key),1);
    if ~isempty(idx),value=S.(fn{idx});found=true;fieldUsed=fn{idx};return;end
end
for a=1:numel(aliases)
    key=normalize_field_name(aliases{a});idx=[];
    for j=1:numel(normFn)
        if contains(normFn{j},key)||contains(key,normFn{j}),idx(end+1)=j;end %#ok<AGROW>
    end
    if numel(idx)==1,value=S.(fn{idx});found=true;fieldUsed=fn{idx};return;end
end
end
