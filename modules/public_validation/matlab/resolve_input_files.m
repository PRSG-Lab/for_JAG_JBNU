function source = resolve_input_files(cfg,runDir,logFile)
%RESOLVE_INPUT_FILES Locate public files or the bundled offline fixture.
sourceDir=fullfile(runDir,'01_source');safe_mkdir(sourceDir);
files=dir(fullfile(cfg.rawDir,'**','*'));paths=strings(0,1);
for i=1:numel(files)
    if files(i).isdir,continue;end
    if strcmpi(files(i).name,'README.txt')||startsWith(files(i).name,'.'),continue;end
    [~,~,ext]=fileparts(files(i).name);
    if any(strcmpi(ext,cfg.data.acceptExtensions))
        paths(end+1,1)=string(fullfile(files(i).folder,files(i).name)); %#ok<AGROW>
    end
end
if cfg.data.forceFixture
    paths=string(cfg.fixtureFile);mode='OFFLINE_FIXTURE';
elseif isempty(paths)
    if cfg.data.allowFixtureFallback
        warning('SurveyReview:FixtureFallback', ...
            'No public NGS files were found. The bundled offline fixture will be used and clearly labelled.');
        paths=string(cfg.fixtureFile);mode='OFFLINE_FIXTURE';
    else
        error('resolve_input_files:NoPublicData', ...
            'No public files were found under %s. Download NGS observation and benchmark files first.',cfg.rawDir);
    end
else
    mode='PUBLIC_NGS_FILES';
end
manifest=table(paths,'VariableNames',{'FilePath'});
manifest.FileName=strings(numel(paths),1);manifest.Extension=strings(numel(paths),1);
manifest.SHA256=strings(numel(paths),1);manifest.Bytes=zeros(numel(paths),1);
for i=1:numel(paths)
    [~,name,ext]=fileparts(char(paths(i)));manifest.FileName(i)=string([name ext]);manifest.Extension(i)=lower(string(ext));
    info=dir(char(paths(i)));manifest.Bytes(i)=info.bytes;manifest.SHA256(i)=string(hash_file_sha256(char(paths(i))));
end
writetable(manifest,fullfile(sourceDir,'source_file_manifest.csv'));
source=struct('mode',mode,'files',manifest,'isPublic',strcmp(mode,'PUBLIC_NGS_FILES'));
jsonSource=source;jsonSource.files=table2struct(manifest);
write_json_file(fullfile(sourceDir,'source_mode.json'),jsonSource);
log_message(logFile,'Input mode: %s; input files: %d',mode,height(manifest));
if ~source.isPublic
    write_text_file(fullfile(runDir,'SELFTEST_ONLY.txt'),sprintf([ ...
        'This run used the bundled synthetic fixture, not public observations.\n' ...
        'Do not use these numerical results as manuscript evidence.\n']));
end
end
