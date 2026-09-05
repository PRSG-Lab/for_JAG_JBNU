function s = value_to_string(v)
%VALUE_TO_STRING Convert a scalar JSON/table value to string.
if isempty(v), s = ""; return; end
if iscell(v), v = v{1}; end
if isstring(v), s = v(1); if ismissing(s),s="";end; return; end
if ischar(v), s = string(v); return; end
if isnumeric(v) || islogical(v), s = string(v(1)); return; end
try, s = string(v); if ~isscalar(s),s=s(1);end; if ismissing(s),s="";end; catch, s = ""; end
end
