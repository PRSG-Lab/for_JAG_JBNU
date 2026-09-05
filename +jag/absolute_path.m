function value = absolute_path(value)
%ABSOLUTE_PATH Resolve relative paths against MATLAB pwd, not the JVM startup directory.
value=char(value);
file=java.io.File(value);
if ~file.isAbsolute(),file=java.io.File(fullfile(pwd,value));end
value=char(file.getCanonicalPath());
end
