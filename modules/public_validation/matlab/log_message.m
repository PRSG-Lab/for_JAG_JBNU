function log_message(logFile,fmt,varargin)
%LOG_MESSAGE Write a timestamped message to console and a log file.
try
    stamp = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd HH:mm:ss.SSS'));
catch
    stamp = datestr(now,'yyyy-mm-dd HH:MM:SS.FFF');
end
msg = sprintf(fmt,varargin{:});
fprintf('[%s] %s\n',stamp,msg);
if nargin >= 1 && ~isempty(logFile)
    fid = fopen(logFile,'a');
    if fid >= 0
        fprintf(fid,'[%s] %s\n',stamp,msg);
        fclose(fid);
    end
end
end
