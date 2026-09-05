function write_json(file,value)
%WRITE_JSON Write readable UTF-8 JSON with safe file closure.
[fid,msg]=fopen(file,'w','n','UTF-8');
if fid<0,error('JAG:WriteFile','%s',msg);end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
