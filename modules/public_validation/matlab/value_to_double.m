function x = value_to_double(v)
%VALUE_TO_DOUBLE Convert a scalar value to double, returning NaN on failure.
if isempty(v), x = NaN; return; end
if iscell(v), v = v{1}; end
if isnumeric(v) || islogical(v), x = double(v(1)); return; end
s = strtrim(char(string(v)));
s = regexprep(s,',','');
tok = regexp(s,'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?','match','once');
if isempty(tok), x = NaN; else, x = str2double(tok); end
end
