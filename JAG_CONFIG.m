function cfg = JAG_CONFIG()
%JAG_CONFIG Return portable input/output paths; original analysis/plot defaults stay in modules.
root = fileparts(mfilename('fullpath'));
cfg = struct('packageRoot',root, 'outputDir',fullfile(root,'runs'), ...
    'publicDataDir',fullfile(root,'data','raw','ngs'), ...
    'gsvsDataDir',fullfile(root,'data','raw','gsvs17'));
end
