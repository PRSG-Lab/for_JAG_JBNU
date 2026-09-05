function write_text_file(filePath,textValue)
%WRITE_TEXT_FILE Write text as UTF-8 where supported.
fid = fopen(filePath,'w','n','UTF-8');
if fid < 0, fid = fopen(filePath,'w'); end
if fid < 0, error('write_text_file:OpenFailed','Cannot open %s',filePath); end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',char(textValue));
end
