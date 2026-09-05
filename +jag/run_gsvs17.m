function info = run_gsvs17(cfg)
%RUN_GSVS17 Run both original analyses, retaining baseline/addendum and final figure sets.
inputs=dir(fullfile(cfg.gsvsDataDir,'*.lvl'));
if isempty(inputs)
    error('JAG:MissingLVL','No *.lvl files in %s. Set cfg.gsvsDataDir.',cfg.gsvsDataDir);
end
runDir=jag.new_run(cfg.outputDir,'GSVS17');
baseDir=fullfile(runDir,'baseline'); addDir=fullfile(runDir,'addendum'); figDir=fullfile(runDir,'figures');
mkdir(baseDir);mkdir(addDir);mkdir(figDir);
info=struct('Status','RUNNING','Workflow','GSVS17','DataMode','GSVS17_LVL', ...
    'RunDirectory',runDir,'InputDirectory',cfg.gsvsDataDir,'InputLVLFiles',numel(inputs), ...
    'BaselineDirectory',baseDir,'AddendumDirectory',addDir,'FinalFigureDirectory',figDir, ...
    'MatlabVersion',version,'PackageVersion','1.0.0');
jag.write_json(fullfile(runDir,'run_manifest.json'),info);
try
    R=gsvs17_min_validation(struct('dataDir',cfg.gsvsDataDir,'outDir',baseDir));
    A=gsvs17_addendum(struct('matFile',fullfile(baseDir,'GSVS17_calibration_results.mat'),'outDir',addDir)); %#ok<NASGU>
    names={'fig1_variance_vs_length','fig2_tau_inference','fig3_model_diagnostics', ...
        'fig4_variance_decomposition','fig5_common_mode_check','fig6_powerlaw_exponent'};
    index=struct('Figure',{},'SourceStage',{},'FIG',{},'PNG',{});
    for i=1:numel(names)
        if ismember(i,[2 5]),sourceDir=baseDir;stage='baseline';else,sourceDir=addDir;stage='addendum';end
        for ext={'.fig','.png'}
            source=fullfile(sourceDir,[names{i} ext{1}]);
            if ~isfile(source),error('JAG:MissingFigure','Expected figure was not generated: %s',source);end
            copyfile(source,figDir);
        end
        index(end+1)=struct('Figure',i,'SourceStage',stage,'FIG',[names{i} '.fig'],'PNG',[names{i} '.png']); %#ok<AGROW>
    end
    jag.write_json(fullfile(figDir,'figure_index.json'),index);
    info.Status='COMPLETED';info.Sections=numel(R.sections);info.Pairs=numel(R.pairs);
    info.BootstrapReplicates=R.config.nBoot;
    info.CalibrationMAT=fullfile(baseDir,'GSVS17_calibration_results.mat');
    info.AddendumMAT=fullfile(addDir,'GSVS17_addendum_results.mat');
    jag.write_json(fullfile(runDir,'run_manifest.json'),info);
    fprintf('\nGSVS17 complete: %s\n',runDir);
catch ME
    info.Status='FAILED';info.ErrorIdentifier=ME.identifier;info.ErrorMessage=ME.message;
    jag.write_json(fullfile(runDir,'run_manifest.json'),info);rethrow(ME)
end
end
