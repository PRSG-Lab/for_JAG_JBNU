function projectID = infer_project_id(filePath,properties)
%INFER_PROJECT_ID Infer NGS project identifier from properties or filename.
projectID = "";
if nargin >= 2 && isstruct(properties)
    [v,f] = get_alias_value(properties,{'projectid','hgz','accession','project','projectnumber'});
    if f, projectID = value_to_string(v); end
end
if strlength(projectID)==0
    [~,name,~] = fileparts(filePath);
    tok = regexp(upper(name),'L\d+(?:[_-]\d+)?','match','once');
    if isempty(tok), projectID = string(name); else, projectID = string(tok); end
end
projectID = replace(projectID,'/','_');
end
