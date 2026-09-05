function report = integration_tests(cfg)
%INTEGRATION_TESTS Regression tests for aliases, restricted overrides, and original defaults.
checks=struct('Name',{},'Passed',{});
checks(end+1)=struct('Name','Relative paths use MATLAB current folder','Passed',strcmp(jag.absolute_path('jag_relative_path_probe'),fullfile(pwd,'jag_relative_path_probe')));
checks(end+1)=struct('Name','Uppercase field normalization','Passed',strcmp(normalize_field_name('FROM_PID'),'frompid'));
checks(end+1)=struct('Name','Mixed-case field normalization','Passed',strcmp(normalize_field_name('Height_Difference'),'heightdifference'));
original=public_validation_config('quick',fullfile(cfg.packageRoot,'modules','public_validation'));
expected=struct('enabled',true,'pngDpi',300,'tiffDpi',600,'fontSize',10,'lineWidth',1.5,'markerSize',6,'visible','off');
checks(end+1)=struct('Name','Public figure defaults preserved','Passed',isequal(original.plot,expected));
C=struct('fontSize',20,'figDPI','-r300','outDir','unused','nBoot',2000);
D=jag.gsvs_options(C,struct('outDir',tempdir),'calibration');
checks(end+1)=struct('Name','GSVS plot and bootstrap defaults untouched','Passed',D.fontSize==20&&strcmp(D.figDPI,'-r300')&&D.nBoot==2000);
rejected=false;try,jag.gsvs_options(C,struct('fontSize',8),'calibration');catch ME,rejected=strcmp(ME.identifier,'JAG:InvalidGSVSOptions');end
checks(end+1)=struct('Name','GSVS plot overrides rejected','Passed',rejected);
rejected=false;try,run_public_validation('quick',cfg.packageRoot,struct('plot',struct()));catch ME,rejected=contains(ME.identifier,'InvalidPathOptions')||contains(ME.identifier,'UnknownPathOption');end
checks(end+1)=struct('Name','Public plot overrides rejected','Passed',rejected);
bad=cfg;bad.fontSize=8;rejected=false;try,jag.validate_config(bad,cfg.packageRoot);catch ME,rejected=strcmp(ME.identifier,'JAG:InvalidConfig');end
checks(end+1)=struct('Name','Top-level nonpath overrides rejected','Passed',rejected);
report=struct('Checks',checks,'Passed',all([checks.Passed]));
end
