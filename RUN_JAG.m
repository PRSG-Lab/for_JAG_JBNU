function info = RUN_JAG(action, cfg)
%RUN_JAG Single entry point: help, audit, selftest, gsvs17, public-quick, public-full, all.
%   RUN_JAG('gsvs17') runs the original 2000-bootstrap GSVS17 analyses.
%   RUN_JAG('public-full',cfg) requires public observations in cfg.publicDataDir.
%   Only input/output paths are configurable; figure and analysis settings are unchanged.
if nargin < 1 || isempty(action), action = 'help'; end
if nargin < 2 || isempty(cfg), cfg = JAG_CONFIG(); end
action = lower(char(string(action)));
if strcmp(action,'help')
    fprintf(['JAG unified levelling package v1.0.0\n' ...
        'RUN_JAG(''audit'')        package checks and public-module unit tests\n' ...
        'RUN_JAG(''selftest'')     synthetic public workflow + GSVS17 numerical smoke test\n' ...
        'RUN_JAG(''gsvs17'')       calibration + addendum; separate and final figures\n' ...
        'RUN_JAG(''public-quick'') quick public workflow; labelled fixture fallback\n' ...
        'RUN_JAG(''public-full'')  full public workflow; no fixture fallback\n' ...
        'RUN_JAG(''all'')          GSVS17 + public-quick (may use fixture)\n' ...
        'cfg = JAG_CONFIG(); cfg.outputDir = ...; RUN_JAG(action,cfg);\n']);
    info = cfg; return
end
if ~ismember(action,{'audit','selftest','gsvs17','public-quick','public-full','all'})
    error('JAG:UnknownAction','Unknown action: %s. Run RUN_JAG(''help'').',action);
end
state = struct('path',path,'folder',pwd,'rng',rng);
cleanup = onCleanup(@() jag.restore_environment(state)); %#ok<NASGU>
root = fileparts(mfilename('fullpath'));
cfg = jag.validate_config(cfg,root);
addpath(fullfile(root,'modules','public_validation','matlab'),'-begin');
addpath(fullfile(root,'modules','gsvs17'),'-begin');
switch action
    case 'audit'
        info = jag.audit(cfg);
    case 'selftest'
        info = jag.selftest(cfg);
    case 'gsvs17'
        info = jag.run_gsvs17(cfg);
    case 'public-quick'
        info = jag.run_public(cfg,'quick');
    case 'public-full'
        info = jag.run_public(cfg,'full');
    case 'all'
        info = struct();
        info.gsvs17 = jag.run_gsvs17(cfg);
        info.public = jag.run_public(cfg,'quick');
end
end
