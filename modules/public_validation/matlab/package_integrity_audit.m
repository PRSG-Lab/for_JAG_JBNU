function report = package_integrity_audit(rootDir,throwOnFailure)
%PACKAGE_INTEGRITY_AUDIT Verify package completeness, resolution, and unit tests.
if nargin<1||isempty(rootDir),rootDir=fileparts(fileparts(mfilename('fullpath')));end
if nargin<2,throwOnFailure=true;end
matlabDir=fullfile(rootDir,'matlab');addpath(rootDir,'-begin');addpath(matlabDir,'-begin');safe_mkdir(fullfile(rootDir,'audit'));
manifest=required_package_files();missing=strings(0,1);wrongFunctionName=strings(0,1);resolutionErrors=strings(0,1);
[unexpectedMatlabFiles,duplicateManifestEntries]=manifest_consistency(rootDir,matlabDir,manifest);
for i=1:numel(manifest.EntryPoints)
    p=fullfile(rootDir,manifest.EntryPoints{i});if exist(p,'file')~=2,missing(end+1)=string(p);end %#ok<AGROW>
end
for i=1:numel(manifest.FunctionFiles)
    p=fullfile(matlabDir,manifest.FunctionFiles{i});if exist(p,'file')~=2,missing(end+1)=string(p);continue;end %#ok<AGROW>
    expected=erase(manifest.FunctionFiles{i},'.m');actual=read_primary_function_name(p);
    if strlength(actual)==0||actual~=string(expected),wrongFunctionName(end+1)=mismatch_text(manifest.FunctionFiles{i},actual);end %#ok<AGROW>
    located=which(expected);if isempty(located)||~same_path(located,p),resolutionErrors(end+1)=string(expected)+" -> "+string(located);end %#ok<AGROW>
end
for i=1:numel(manifest.EntryPoints)
    p=fullfile(rootDir,manifest.EntryPoints{i});if exist(p,'file')~=2,continue;end
    expected=erase(manifest.EntryPoints{i},'.m');actual=read_primary_function_name(p);
    if strlength(actual)==0||actual~=string(expected),wrongFunctionName(end+1)=mismatch_text(manifest.EntryPoints{i},actual);end %#ok<AGROW>
    located=which(expected);if isempty(located)||~same_path(located,p),resolutionErrors(end+1)=string(expected)+" -> "+string(located);end %#ok<AGROW>
end
for i=1:numel(manifest.DataFiles)
    p=fullfile(rootDir,manifest.DataFiles{i});if exist(p,'file')~=2,missing(end+1)=string(p);end %#ok<AGROW>
end
analyzer=run_code_analyzer(rootDir,manifest);unit=public_validation_unit_tests(rootDir);
report=struct();report.Version='2.2.0';report.Timestamp=timestamp_string();report.RootDirectory=rootDir;
report.RequiredEntryPointCount=numel(manifest.EntryPoints);report.RequiredFunctionCount=numel(manifest.FunctionFiles);
report.MissingFiles=missing;report.FunctionNameMismatches=wrongFunctionName;report.ResolutionErrors=resolutionErrors;
report.UnexpectedMatlabFiles=unexpectedMatlabFiles;report.DuplicateManifestEntries=duplicateManifestEntries;
report.CodeAnalyzer=analyzer;report.UnitTests=unit;
report.Passed=isempty(missing)&&isempty(wrongFunctionName)&&isempty(resolutionErrors)&& ...
    isempty(unexpectedMatlabFiles)&&isempty(duplicateManifestEntries)&&analyzer.FatalCount==0&&unit.Passed;
write_json_file(fullfile(rootDir,'audit','PACKAGE_INTEGRITY_REPORT.json'),report);
write_text_file(fullfile(rootDir,'audit','PACKAGE_INTEGRITY_REPORT.txt'),format_report(report));
write_function_inventory(rootDir,manifest);
fprintf('Package audit: required entry points=%d, MATLAB functions=%d, passed=%d\n', ...
    report.RequiredEntryPointCount,report.RequiredFunctionCount,report.Passed);
if throwOnFailure&&~report.Passed
    error('package_integrity_audit:Failed','Package integrity audit failed. See audit/PACKAGE_INTEGRITY_REPORT.txt.');
end
end
function [unexpected,duplicates]=manifest_consistency(rootDir,matlabDir,manifest)
expectedRoot=string(manifest.EntryPoints(:));expectedFunctions=string(manifest.FunctionFiles(:));
rootListing=dir(fullfile(rootDir,'*.m'));functionListing=dir(fullfile(matlabDir,'*.m'));
actualRoot=string({rootListing.name})';actualFunctions=string({functionListing.name})';
unexpected=["root/"+setdiff(actualRoot,expectedRoot);"matlab/"+setdiff(actualFunctions,expectedFunctions)];
declared=[erase(expectedRoot,'.m');erase(expectedFunctions,'.m')];
[names,~,groups]=unique(declared);counts=accumarray(groups,1);duplicates=names(counts>1);
end
function text=mismatch_text(fileName,actual)
if strlength(actual)==0,actual="<not detected>";end
text=string(fileName)+" -> "+actual;
end
function tf=same_path(a,b)
try,a=char(java.io.File(a).getCanonicalPath());b=char(java.io.File(b).getCanonicalPath());catch,a=char(a);b=char(b);end
tf=strcmpi(a,b);
end
function analyzer=run_code_analyzer(rootDir,manifest)
messages=struct('File',{},'Line',{},'Column',{},'Identifier',{},'Message',{});fatal=0;
if exist('checkcode','file')~=2,analyzer=struct('Available',false,'MessageCount',0,'FatalCount',0,'Messages',messages);return;end
paths=[cellfun(@(x)fullfile(rootDir,x),manifest.EntryPoints,'UniformOutput',false); ...
       cellfun(@(x)fullfile(rootDir,'matlab',x),manifest.FunctionFiles,'UniformOutput',false)];
for i=1:numel(paths)
    try
        m=checkcode(paths{i},'-id');
        for j=1:numel(m)
            id='';if isfield(m,'id'),id=m(j).id;end
            line=NaN;if isfield(m,'line'),line=m(j).line;end
            col=NaN;if isfield(m,'column'),col=m(j).column;end
            messages(end+1)=struct('File',paths{i},'Line',line,'Column',col,'Identifier',id,'Message',m(j).message); %#ok<AGROW>
            if is_fatal_analyzer_message(id,m(j).message),fatal=fatal+1;end
        end
    catch ME
        messages(end+1)=struct('File',paths{i},'Line',NaN,'Column',NaN,'Identifier',ME.identifier,'Message',ME.message); %#ok<AGROW>
        if is_fatal_analyzer_message(ME.identifier,ME.message),fatal=fatal+1;end
    end
end
analyzer=struct('Available',true,'MessageCount',numel(messages),'FatalCount',fatal,'Messages',messages);
end
function tf=is_fatal_analyzer_message(identifier,message)
id=upper(string(identifier));msg=lower(string(message));
tf=contains(id,'PARS')||contains(id,'SYNTAX')||contains(msg,'parse error')|| ...
    contains(msg,'syntax error')||contains(msg,'구문 오류')||contains(msg,'구문 분석 오류');
end
function write_function_inventory(rootDir,manifest)
kind=[repmat("Entry point",numel(manifest.EntryPoints),1);repmat("Function",numel(manifest.FunctionFiles),1)];
file=[string(manifest.EntryPoints);string(manifest.FunctionFiles)];expected=erase(file,'.m');n=numel(file);
declared=strings(n,1);resolved=strings(n,1);existsFlag=false(n,1);nameMatches=false(n,1);resolutionMatches=false(n,1);
for i=1:n
    if kind(i)=="Entry point",p=fullfile(rootDir,file(i));else,p=fullfile(rootDir,'matlab',file(i));end
    existsFlag(i)=exist(p,'file')==2;
    if existsFlag(i),declared(i)=read_primary_function_name(p);nameMatches(i)=declared(i)==expected(i);end
    located=which(char(expected(i)));resolved(i)=string(located);
    if ~isempty(located)&&existsFlag(i),resolutionMatches(i)=same_path(located,p);end
end
T=table(kind,file,expected,declared,existsFlag,nameMatches,resolved,resolutionMatches, ...
    'VariableNames',{'Kind','File','ExpectedName','DeclaredName','Exists','NameMatches','ResolvedPath','ResolutionMatches'});
writetable(T,fullfile(rootDir,'audit','FUNCTION_INVENTORY.csv'));
end
function txt=format_report(r)
txt=sprintf(['Survey Review public-leveling validation package integrity report\n' ...
 'Version: %s\nTimestamp: %s\nRoot: %s\nEntry points required: %d\nFunctions required: %d\n' ...
 'Missing files: %d\nFunction-name mismatches: %d\nResolution errors: %d\nUnexpected MATLAB files: %d\n' ...
 'Duplicate manifest entries: %d\nCode Analyzer available: %d\n' ...
 'Code Analyzer messages: %d\nCode Analyzer fatal messages: %d\nUnit tests passed: %d\nOVERALL PASS: %d\n'], ...
 r.Version,r.Timestamp,r.RootDirectory,r.RequiredEntryPointCount,r.RequiredFunctionCount,numel(r.MissingFiles), ...
 numel(r.FunctionNameMismatches),numel(r.ResolutionErrors),numel(r.UnexpectedMatlabFiles), ...
 numel(r.DuplicateManifestEntries),r.CodeAnalyzer.Available,r.CodeAnalyzer.MessageCount, ...
 r.CodeAnalyzer.FatalCount,r.UnitTests.Passed,r.Passed);
if ~isempty(r.MissingFiles),txt=[txt sprintf('\nMissing files:\n%s\n',strjoin(r.MissingFiles,newline))];end
if ~isempty(r.FunctionNameMismatches),txt=[txt sprintf('\nFunction-name mismatches:\n%s\n',strjoin(r.FunctionNameMismatches,newline))];end
if ~isempty(r.ResolutionErrors),txt=[txt sprintf('\nResolution errors:\n%s\n',strjoin(r.ResolutionErrors,newline))];end
if ~isempty(r.UnexpectedMatlabFiles),txt=[txt sprintf('\nUnexpected MATLAB files:\n%s\n',strjoin(r.UnexpectedMatlabFiles,newline))];end
if ~isempty(r.DuplicateManifestEntries),txt=[txt sprintf('\nDuplicate manifest entries:\n%s\n',strjoin(r.DuplicateManifestEntries,newline))];end
if ~isempty(r.UnitTests.Messages),txt=[txt sprintf('\nUnit-test messages:\n%s\n',strjoin(r.UnitTests.Messages,newline))];end
if isfield(r.UnitTests,'FailedChecks')&&~isempty(r.UnitTests.FailedChecks)
    txt=[txt sprintf('\nFailed unit-test checks:\n%s\n',strjoin(r.UnitTests.FailedChecks,newline))];
end
end
