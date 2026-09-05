function safe_mkdir(pathName)
%SAFE_MKDIR Create a directory if it does not exist.
if ~exist(pathName,'dir')
    [ok,msg] = mkdir(pathName);
    if ~ok, error('safe_mkdir:CreateFailed','Cannot create %s: %s',pathName,msg); end
end
end
