function write_json_file(filePath,value)
%WRITE_JSON_FILE Serialize a MATLAB value to UTF-8 JSON.
value = make_json_compatible(value);
try
    txt = jsonencode(value,'PrettyPrint',true);
catch
    txt = jsonencode(value);
end
write_text_file(filePath,txt);
end
