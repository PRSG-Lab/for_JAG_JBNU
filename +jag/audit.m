function report = audit(cfg)
%AUDIT Run source hashes, original public-module checks, and adapter regression checks.
report=struct('PackageVersion','1.0.0','MatlabVersion',version);
report.SourceIntegrity=jag.verify_sources(cfg.packageRoot);
if ~report.SourceIntegrity.Passed,error('JAG:IntegrityFailed','Distributed source/input files changed. See manifest.');end
runDir=jag.new_run(cfg.outputDir,'audit');
moduleRoot=fullfile(cfg.packageRoot,'modules','public_validation');
snapshot=fullfile(runDir,'public_module_snapshot');
copyfile(moduleRoot,snapshot);
report.PublicModule=package_integrity_audit(snapshot,true);
addpath(fullfile(cfg.packageRoot,'tests'),'-begin');
report.Integration=integration_tests(cfg);
report.Passed=report.SourceIntegrity.Passed&&report.PublicModule.Passed&&report.Integration.Passed;
report.ReportDirectory=runDir;
jag.write_json(fullfile(runDir,'audit_report.json'),report);
fprintf('\nUnified audit passed: %d. Report: %s\n',report.Passed,runDir);
if ~report.Passed,error('JAG:AuditFailed','Integration checks failed.');end
end
