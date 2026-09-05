function hex = hash_file_sha256(filePath)
%HASH_FILE_SHA256 Compute a SHA-256 checksum using Java in MATLAB.
fid=fopen(filePath,'rb');if fid<0,error('hash_file_sha256:OpenFailed','Cannot open %s',filePath);end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
md=java.security.MessageDigest.getInstance('SHA-256');
while true
    bytes=fread(fid,1024*1024,'*uint8');if isempty(bytes),break;end
    md.update(bytes);
end
raw=typecast(md.digest(),'uint8');hex=lower(reshape(dec2hex(raw,2).',1,[]));
end
