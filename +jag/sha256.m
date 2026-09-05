function hash = sha256(file)
%SHA256 Compute SHA-256 for a local file using the MATLAB JVM.
[fid,msg]=fopen(file,'rb');if fid<0,error('JAG:ReadFile','%s',msg);end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
engine=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    bytes=fread(fid,1024*1024,'*uint8');engine.update(bytes);
end
digest=typecast(engine.digest(),'uint8');
hash=lower(reshape(dec2hex(digest,2).',1,[]));
end
