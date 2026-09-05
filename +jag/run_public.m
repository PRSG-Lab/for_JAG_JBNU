function info = run_public(cfg,mode)
%RUN_PUBLIC Use the public module with central data/output paths and original mode defaults.
moduleRoot=fullfile(cfg.packageRoot,'modules','public_validation');
paths=struct('rawDir',cfg.publicDataDir,'runsDir',fullfile(cfg.outputDir,'public_validation'));
info=run_public_validation(mode,moduleRoot,paths);
info.UnifiedPackageVersion='1.0.0';
jag.write_json(fullfile(info.RunDirectory,'unified_run_manifest.json'),info);
if isfile(info.ResultArchive)
    zip(info.ResultArchive,'*',info.RunDirectory);
end
if ~info.IsPublicData
    fprintf('\nDATA MODE: OFFLINE_FIXTURE - synthetic code validation, not field evidence.\n');
end
end
