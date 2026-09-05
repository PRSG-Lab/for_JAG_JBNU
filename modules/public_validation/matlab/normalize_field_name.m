function s = normalize_field_name(value)
%NORMALIZE_FIELD_NAME Lowercase and remove punctuation for alias matching.
s = regexprep(lower(char(string(value))),'[^a-z0-9]','');
end
