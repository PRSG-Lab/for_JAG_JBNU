function out = make_json_compatible(value)
%MAKE_JSON_COMPATIBLE Convert MATLAB values to jsonencode-friendly values.
if istable(value)
    out = make_json_compatible(table2struct(value));
elseif isstruct(value)
    out = value;
    fields = fieldnames(value);
    for i = 1:numel(value)
        for j = 1:numel(fields)
            out(i).(fields{j}) = make_json_compatible(value(i).(fields{j}));
        end
    end
elseif iscell(value)
    out = cell(size(value));
    for i = 1:numel(value)
        out{i} = make_json_compatible(value{i});
    end
elseif isstring(value)
    if isscalar(value)
        if ismissing(value), out = ''; else, out = char(value); end
    else
        out = cellstr(value);
    end
elseif isdatetime(value)
    out = cellstr(string(value));
elseif iscategorical(value)
    out = cellstr(string(value));
elseif isa(value,'function_handle')
    out = func2str(value);
else
    out = value;
end
end
