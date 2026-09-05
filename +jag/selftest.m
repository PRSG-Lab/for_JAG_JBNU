function info = selftest(cfg)
%SELFTEST Run synthetic public end-to-end validation and GSVS17 parsing/fit smoke tests.
info=struct();
info.Public=jag.run_public(cfg,'selftest');
sections=parse_gsvs17_lvl(cfg.gsvsDataDir);
pairs=build_fb_pairs(sections);
assert(numel(pairs)>=4,'JAG:TooFewPairs','GSVS17 smoke test needs at least four F/B pairs.');
d=[pairs.d_mm]';L=[pairs.L_km]';n=[pairs.nSetups]';
M0=fit_variance_ml(d,L,n,false);M1=fit_variance_ml(d,L,n,true);
assert(all(isfinite([M0.nll M1.nll])),'JAG:InvalidFit','Non-finite likelihood in smoke test.');
info.GSVS17=struct('Sections',numel(sections),'Pairs',numel(pairs),'M0_nll',M0.nll,'M1_nll',M1.nll, ...
    'Scope','Parser and two ML fits only; no profile/bootstrap/GSVS17 figures in selftest.');
info.Passed=strcmp(info.Public.Status,'COMPLETED');
jag.write_json(fullfile(info.Public.RunDirectory,'unified_selftest.json'),info);
fprintf('\nSelftest completed: public fixture + GSVS17 numerical smoke test.\n');
end
