function runInfo = run_public_validation(mode,rootDir,pathOptions)
%RUN_PUBLIC_VALIDATION End-to-end public or fixture validation workflow.
% Optional pathOptions accepts only rawDir and runsDir; analytical and plot
% settings are inherited unchanged from public_validation_config.
if nargin<1||isempty(mode),mode='quick';end
if nargin<2||isempty(rootDir),rootDir=fileparts(fileparts(mfilename('fullpath')));end
if nargin<3||isempty(pathOptions),pathOptions=struct();end
if ~isstruct(pathOptions)||~isscalar(pathOptions)
    error('run_public_validation:InvalidPathOptions','pathOptions must be a scalar struct.');
end
cfg=public_validation_config(mode,rootDir);
optionNames=fieldnames(pathOptions);
for optionIndex=1:numel(optionNames)
    optionName=optionNames{optionIndex};
    if ~ismember(optionName,{'rawDir','runsDir'})
        error('run_public_validation:UnknownPathOption','Unsupported path option: %s. Only rawDir and runsDir are allowed.',optionName);
    end
    optionValue=pathOptions.(optionName);
    validChar=ischar(optionValue)&&isrow(optionValue)&&~isempty(strtrim(optionValue));
    validString=isstring(optionValue)&&isscalar(optionValue)&&~ismissing(optionValue)&&strlength(strtrim(optionValue))>0;
    if ~(validChar||validString)
        error('run_public_validation:InvalidPathValue','Path option %s must be a nonempty character row or string scalar.',optionName);
    end
    cfg.(optionName)=char(optionValue);
end
safe_mkdir(cfg.runsDir);
runName=sprintf('PublicLeveling_%s_%s',lower(mode),timestamp_string());runDir=fullfile(cfg.runsDir,runName);archivePath=[runDir '.zip'];safe_mkdir(runDir);
for d={'00_manifest','00_logs','01_source','02_cases','03_calibration','04_validation','05_figures'},safe_mkdir(fullfile(runDir,d{1}));end
logFile=fullfile(runDir,'00_logs','console_output.txt');rng(cfg.randomSeed,'twister');
log_message(logFile,'Starting public validation package v%s in %s mode.',cfg.version,mode);
write_json_file(fullfile(runDir,'00_manifest','configuration.json'),cfg);status='FAILED';
try
    log_message(logFile,'[1/6] Resolving source files.');source=resolve_input_files(cfg,runDir,logFile);
    log_message(logFile,'[2/6] Parsing and standardizing observations.');[E,parseReport]=parse_leveling_files(source,cfg,runDir,logFile);
    log_message(logFile,'[3/6] Extracting disjoint route cases.');[cases,caseSummary,routeDetails]=find_public_validation_cases(E,cfg,runDir,logFile); %#ok<ASGLU>
    log_message(logFile,'[4/6] Splitting calibration and held-out cases.');[trainCases,testCases,splitReport]=split_public_cases(cases,cfg,runDir,logFile);
    log_message(logFile,'[5/6] Calibrating effective covariance scales and evaluating methods.');calibration=calibrate_public_covariance(trainCases,cfg,runDir,logFile);validation=evaluate_public_methods(testCases,calibration,cfg,runDir,logFile);
    log_message(logFile,'[6/6] Generating figures and archiving results.');figIndex=generate_public_figures(E,cases,trainCases,testCases,calibration,validation,cfg,runDir,logFile); %#ok<NASGU>
    status='COMPLETED';
    runInfo=struct('Status',status,'Mode',mode,'RunDirectory',runDir,'DataMode',source.mode, ...
      'IsPublicData',source.isPublic,'PhysicalEdges',height(E),'Cases',numel(cases), ...
      'TrainingCases',numel(trainCases),'TestCases',numel(testCases), ...
      'CalibrationSigma2',calibration.sigma2,'CalibrationKappa',calibration.kappa,'Version',cfg.version,'ResultArchive',archivePath);
    try
        save(fullfile(runDir,'all_public_validation_results.mat'),'runInfo','cfg','source','parseReport','E','cases', ...
          'caseSummary','routeDetails','trainCases','testCases','splitReport','calibration','validation','-v7.3');
    catch
        save(fullfile(runDir,'all_public_validation_results.mat'),'runInfo','cfg','source','parseReport','E','cases', ...
          'caseSummary','routeDetails','trainCases','testCases','splitReport','calibration','validation');
    end
    write_json_file(fullfile(runDir,'00_manifest','run_info.json'),runInfo);write_key_results_summary(runDir,runInfo,validation,calibration,cfg);
    write_text_file(fullfile(runDir,'RUN_COMPLETED.txt'),sprintf('STATUS: COMPLETED\nDATA_MODE: %s\nRUN_DIR: %s\n',source.mode,runDir));
    write_text_file(fullfile(cfg.runsDir,'LATEST_RUN.txt'),runDir);
    try
        zip(archivePath,'*',runDir);write_text_file(fullfile(cfg.runsDir,'LATEST_RESULT_ZIP.txt'),archivePath);
    catch archiveError
        log_message(logFile,'Result archive creation failed but the run directory is complete: %s',archiveError.message);
    end
    log_message(logFile,'Run completed: %s',runDir);log_message(logFile,'Result archive: %s',archivePath);
catch ME
    runInfo=struct('Status',status,'Mode',mode,'RunDirectory',runDir,'Version',cfg.version, ...
      'ErrorIdentifier',ME.identifier,'ErrorMessage',ME.message);write_failure_report(runDir,ME);
    log_message(logFile,'Run failed: %s -- %s',ME.identifier,ME.message);rethrow(ME);
end
end
function write_failure_report(runDir,ME)
lines=sprintf('STATUS: FAILED\nIDENTIFIER: %s\nMESSAGE: %s\n',ME.identifier,ME.message);
for i=1:numel(ME.stack),lines=[lines sprintf('STACK %d: %s line %d\n',i,ME.stack(i).name,ME.stack(i).line)];end %#ok<AGROW>
write_text_file(fullfile(runDir,'failure_report.txt'),lines);
end
function write_key_results_summary(runDir,runInfo,validation,calibration,cfg)
S=validation.summary;txt=sprintf(['Survey Review public-leveling validation\nStatus: %s\nData mode: %s\n' ...
 'Physical edges: %d\nCases: %d (training %d, test %d)\nFitted nominal scale sigma2: %.10g\n' ...
 'Fitted coherent scale kappa: %.10g\nGamma convention: %.3f\n\nMethod summary\n'], ...
 runInfo.Status,runInfo.DataMode,runInfo.PhysicalEdges,runInfo.Cases,runInfo.TrainingCases,runInfo.TestCases, ...
 calibration.sigma2,calibration.kappa,cfg.model.gammaFixed);
for i=1:height(S)
    txt=[txt sprintf('%s: RMSE=%.6g m, MAE=%.6g m, consistency=%.4f, mean width=%.6g m\n', ...
      S.Method(i),S.RMSE_m(i),S.MAE_m(i),S.Consistency95(i),S.MeanIntervalWidth_m(i))]; %#ok<AGROW>
end
if ~runInfo.IsPublicData,txt=[txt sprintf('\nWARNING: OFFLINE FIXTURE ONLY. These values are not public-data evidence.\n')];end
write_text_file(fullfile(runDir,'KEY_RESULTS_SUMMARY.txt'),txt);
end
