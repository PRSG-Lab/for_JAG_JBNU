function name = read_primary_function_name(filePath)
%READ_PRIMARY_FUNCTION_NAME Read the primary function name from an M-file.
% Supports no-output, single-output, multiple-output, and continued
% function declarations without relying on a bracket-sensitive regexp.
txt = fileread(filePath);
lines = regexp(txt,'\r\n|\n|\r','split');
signature = '';
name = "";
for i = 1:numel(lines)
    line = strtrim(strrep(lines{i},char(65279),'')); % remove a possible UTF-8 BOM
    if isempty(line) || startsWith(line,'%')
        continue;
    end
    if ~startsWith(line,'function')
        return;
    end
    signature = line;
    while endsWith(strtrim(signature),'...') && i < numel(lines)
        signature = regexprep(signature,'\.\.\.\s*$','');
        i = i + 1;
        nextLine = regexprep(lines{i},'%.*$','');
        signature = [signature ' ' strtrim(nextLine)]; %#ok<AGROW>
    end
    break;
end
if isempty(signature)
    return;
end
signature = regexprep(signature,'%.*$','');
body = strtrim(signature(numel('function')+1:end));
equalsAt = find(body=='=',1,'first');
if ~isempty(equalsAt)
    body = strtrim(body(equalsAt+1:end));
end
token = regexp(body,'^[A-Za-z]\w*','match','once');
if ~isempty(token)
    name = string(token);
end
end
