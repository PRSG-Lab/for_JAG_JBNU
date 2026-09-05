function PublicValidationRunInfo = RUN_OFFLINE_SELFTEST()
%RUN_OFFLINE_SELFTEST End-to-end test using the bundled synthetic fixture.
% The resulting values are not public-data evidence.
rootDir=fileparts(mfilename('fullpath'));addpath(fullfile(rootDir,'matlab'));
package_integrity_audit(rootDir,true);
PublicValidationRunInfo=run_public_validation('selftest',rootDir);
if nargout==0,assignin('base','PublicValidationRunInfo',PublicValidationRunInfo);end
end
