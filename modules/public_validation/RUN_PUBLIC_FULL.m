function PublicValidationRunInfo = RUN_PUBLIC_FULL()
%RUN_PUBLIC_FULL Full validation using public files in data/raw/ngs.
% The full entry point never falls back to the bundled fixture.
rootDir=fileparts(mfilename('fullpath'));addpath(fullfile(rootDir,'matlab'));
package_integrity_audit(rootDir,true);
PublicValidationRunInfo=run_public_validation('full',rootDir);
if nargout==0,assignin('base','PublicValidationRunInfo',PublicValidationRunInfo);end
end
