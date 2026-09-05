function cfg = validate_config(cfg,root)
%VALIDATE_CONFIG Accept only path fields and resolve relative paths before execution.
required = {'packageRoot','outputDir','publicDataDir','gsvsDataDir'};
if ~isstruct(cfg) || ~isscalar(cfg) || ~isempty(setdiff(fieldnames(cfg),required)) || ...
        ~all(isfield(cfg,required))
    error('JAG:InvalidConfig','Use JAG_CONFIG(); only its four path fields are accepted.');
end
for i=1:numel(required)
    k=required{i}; v=cfg.(k);
    if ~((ischar(v)&&isrow(v))||(isstring(v)&&isscalar(v))) || strlength(string(v))==0
        error('JAG:InvalidPath','%s must be a nonempty text path.',k);
    end
    cfg.(k)=jag.absolute_path(v);
end
root=jag.absolute_path(root);
if ~strcmp(cfg.packageRoot,root)
    error('JAG:PackageRoot','Do not change cfg.packageRoot; call the copy of RUN_JAG you intend to use.');
end
end
