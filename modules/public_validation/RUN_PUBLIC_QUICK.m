function PublicValidationRunInfo = RUN_PUBLIC_QUICK()
%RUN_PUBLIC_QUICK Reduced end-to-end validation.
% If no public files are present, the bundled fixture is used and the run is
% labelled SELFTEST_ONLY. Use RUN_PUBLIC_FULL for public-data-only execution.
rootDir=fileparts(mfilename('fullpath'));addpath(fullfile(rootDir,'matlab'));
package_integrity_audit(rootDir,true);
PublicValidationRunInfo=run_public_validation('quick',rootDir);
if nargout==0,assignin('base','PublicValidationRunInfo',PublicValidationRunInfo);end
end
