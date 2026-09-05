function s = timestamp_string()
%TIMESTAMP_STRING Portable timestamp suitable for folder names.
try
    s = char(datetime('now','TimeZone','UTC','Format','yyyyMMdd_HHmmss_SSS'));
catch
    s = datestr(now,'yyyymmdd_HHMMSS_FFF');
end
end
