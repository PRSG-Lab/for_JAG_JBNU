function cfg = gsvs_options(cfg,options,stage)
%GSVS_OPTIONS Override input/output paths only; reject plot/numerical overrides.
if strcmp(stage,'calibration'), allowed={'dataDir','outDir'};
elseif strcmp(stage,'addendum'), allowed={'matFile','outDir'};
else, error('JAG:InvalidStage','Unknown GSVS17 stage.'); end
if ~isstruct(options)||~isscalar(options)||~isempty(setdiff(fieldnames(options),allowed))
    error('JAG:InvalidGSVSOptions','Only %s may be overridden.',strjoin(allowed,', '));
end
names=fieldnames(options);
for i=1:numel(names)
    k=names{i}; v=options.(k);
    if ~((ischar(v)&&isrow(v))||(isstring(v)&&isscalar(v)))||strlength(string(v))==0
        error('JAG:InvalidPath','%s must be a nonempty path.',k);
    end
    cfg.(k)=jag.absolute_path(v);
end
end
