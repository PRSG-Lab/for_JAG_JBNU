function AuditReport = RUN_PACKAGE_AUDIT()
%RUN_PACKAGE_AUDIT Check entry points, function resolution, and unit tests.
rootDir=fileparts(mfilename('fullpath'));addpath(fullfile(rootDir,'matlab'));
AuditReport=package_integrity_audit(rootDir,true);
if nargout==0,assignin('base','AuditReport',AuditReport);disp(AuditReport);end
end
