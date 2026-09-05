function [obs,parseReport] = parse_leveling_files(source,cfg,runDir,logFile)
%PARSE_LEVELING_FILES Parse tabular or NGS-style GeoJSON observation files.
stageDir = fullfile(runDir,'01_source'); unpackDir = fullfile(stageDir,'unpacked'); safe_mkdir(unpackDir);
inputPaths = string(source.files.FilePath); expanded = strings(0,1);
for i=1:numel(inputPaths)
    [~,~,ext]=fileparts(char(inputPaths(i)));
    if strcmpi(ext,'.zip')
        dest=fullfile(unpackDir,sprintf('zip_%03d',i)); safe_mkdir(dest); unzip(char(inputPaths(i)),dest);
        dd=dir(fullfile(dest,'**','*'));
        for j=1:numel(dd)
            if dd(j).isdir,continue;end
            [~,~,e2]=fileparts(dd(j).name);
            if any(strcmpi(e2,cfg.data.acceptExtensions)) && ~strcmpi(e2,'.zip')
                expanded(end+1,1)=string(fullfile(dd(j).folder,dd(j).name)); %#ok<AGROW>
            end
        end
    else
        expanded(end+1,1)=inputPaths(i); %#ok<AGROW>
    end
end
expanded=unique(expanded,'stable');
if isempty(expanded),error('parse_leveling_files:NoReadableFiles','No readable files were found after expansion.');end

bench=table(strings(0,1),strings(0,1),strings(0,1),zeros(0,1),zeros(0,1), ...
    'VariableNames',{'ProjectID','SSN','PID','Lat','Lon'});
for i=1:numel(expanded)
    [~,~,ext]=fileparts(char(expanded(i)));
    if any(strcmpi(ext,{'.json','.geojson'}))
        try
            b=parse_ngs_benchmark_geojson(char(expanded(i)));
            if ~isempty(b),bench=[bench;b];end %#ok<AGROW>
        catch ME
            log_message(logFile,'Benchmark parse skipped for %s: %s',char(expanded(i)),ME.message);
        end
    end
end
if ~isempty(bench)
    key=bench.ProjectID+"|"+bench.SSN; [~,ia]=unique(key,'stable'); bench=bench(ia,:);
    writetable(bench,fullfile(stageDir,'parsed_benchmarks.csv'));
end

obs=empty_observation_table();
fileReports=struct('File',{},'Type',{},'RowsRead',{},'RowsAccepted',{},'Message',{});
for i=1:numel(expanded)
    p=char(expanded(i)); [~,~,ext]=fileparts(p); t=empty_observation_table(); typ=''; msg=''; rowsRead=0;
    try
        if any(strcmpi(ext,{'.csv','.txt','.xlsx','.xls'}))
            [t,rowsRead]=parse_tabular_observations(p,cfg); typ='tabular';
        elseif any(strcmpi(ext,{'.json','.geojson'}))
            [t,rowsRead]=parse_ngs_observation_geojson(p,bench,cfg); typ='geojson';
        else
            msg='unsupported extension';
        end
    catch ME
        msg=ME.message; log_message(logFile,'Observation parse failed for %s: %s',p,ME.message);
    end
    if ~isempty(t),obs=[obs;t];end %#ok<AGROW>
    fileReports(end+1)=struct('File',p,'Type',typ,'RowsRead',rowsRead, ...
        'RowsAccepted',height(t),'Message',msg); %#ok<AGROW>
end
if isempty(obs),error('parse_leveling_files:NoObservations','No observation records were parsed from the selected files.');end
[obs,cleanReport]=clean_and_collapse_observations(obs,cfg);
if isempty(obs)
    error('parse_leveling_files:NoValidObservations','All parsed observation records were removed during validation.');
end
writetable(obs,fullfile(stageDir,'standardized_observations.csv'));
parseReport=struct('files',fileReports,'cleaning',cleanReport, ...
    'observationCount',height(obs),'benchmarkCount',height(bench));
write_json_file(fullfile(stageDir,'parse_report.json'),parseReport);
log_message(logFile,'Parsed and standardized physical edges: %d',height(obs));
end

function T=empty_observation_table()
T=table(strings(0,1),strings(0,1),strings(0,1),strings(0,1), ...
    zeros(0,1),zeros(0,1),strings(0,1),strings(0,1),zeros(0,1),strings(0,1), ...
    nan(0,1),nan(0,1),nan(0,1),nan(0,1),strings(0,1), ...
    'VariableNames',{'ProjectID','ObservationID','FromID','ToID','DeltaH_m','Length_km', ...
    'Order','Class','SetupCount','Date','FromLat','FromLon','ToLat','ToLon','SourceFile'});
end
