function report = verify_sources(root)
%VERIFY_SOURCES Compare distributed MATLAB and input files against the packaged hash manifest.
manifest=readtable(fullfile(root,'provenance','source_file_manifest.csv'),'TextType','string');
failed=strings(0,1);
for i=1:height(manifest)
    file=fullfile(root,char(manifest.RelativePath(i)));
    if ~isfile(file)||~strcmp(jag.sha256(file),manifest.PackagedSHA256(i))
        failed(end+1)=manifest.RelativePath(i); %#ok<AGROW>
    end
end
report=struct('CheckedFiles',height(manifest),'FailedFiles',failed,'Passed',isempty(failed));
end
