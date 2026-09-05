function report = public_validation_unit_tests(rootDir)
%PUBLIC_VALIDATION_UNIT_TESTS Deterministic tests independent of public downloads.
if nargin<1||isempty(rootDir),rootDir=fileparts(fileparts(mfilename('fullpath')));end
cfg=public_validation_config('selftest',rootDir);cfg.validation.bootstrapReplicates=10;cfg.validation.calibrationBootstrapReplicates=10;
tmpRoot=fullfile(tempdir,['SurveyReviewPublicValidation_' timestamp_string()]);safe_mkdir(tmpRoot);
cleanup=onCleanup(@()cleanup_temp(tmpRoot)); %#ok<NASGU>
runDir=fullfile(tmpRoot,'run');for d={'01_source','02_cases','03_calibration','04_validation'},safe_mkdir(fullfile(runDir,d{1}));end
logFile=fullfile(runDir,'unit_test.log');tests=struct();messages=strings(0,1);
try
    % Closed-form reference and Gamma-b invariance.
    a=[0.1408;0.1792;0.2176];b=[0.0576;0.36;1.1664];
    expected=[0.616438356164384;0.246575342465753;0.136986301369863];
    [w,info]=minimax_route_weights(a,b,1);tests.C2WeightError=max(abs(w-expected));
    [w1,~]=minimax_route_weights(a,b,0.4);[w2,~]=minimax_route_weights(a,0.4*b,1);
    tests.GammaBWeightInvariance=max(abs(w1-w2));
    tests.GammaBObjectiveInvariance=abs((sum(a.*w1.^2)+0.4*max(b.*w1.^2))-(sum(a.*w2.^2)+max((0.4*b).*w2.^2)));
    tests.WeightSumError=abs(sum(w)-1);tests.C2Phase=info.Phase;

    % Exact two-parameter nonnegative robust fit.
    X=[1 0;0 1;1 1;2 1;1 2];betaTrue=[2;0.5];y=X*betaTrue;
    fit=robust_nnls2(X,y,ones(size(y)),cfg);tests.NNLSParameterError=max(abs(fit.beta-betaTrue));

    % Declaration-parser and unit-conversion regressions.
    manifest=required_package_files();declarationMatches=true;
    for j=1:numel(manifest.EntryPoints)
        p=fullfile(rootDir,manifest.EntryPoints{j});
        declarationMatches=declarationMatches && read_primary_function_name(p)==string(erase(manifest.EntryPoints{j},'.m'));
    end
    for j=1:numel(manifest.FunctionFiles)
        p=fullfile(rootDir,'matlab',manifest.FunctionFiles{j});
        declarationMatches=declarationMatches && read_primary_function_name(p)==string(erase(manifest.FunctionFiles{j},'.m'));
    end
    tests.DeclarationParserAllFiles=declarationMatches;
    % Field aliases must retain letters before case-insensitive matching.
    tests.NormalizedUpperCase=strcmp(normalize_field_name('FROM_SSN'),'fromssn');
    tests.NormalizedMixedCase=strcmp(normalize_field_name('FromSSN'),'fromssn');
    [aliasValue,aliasFound,aliasField]=get_alias_value(struct('FROM_SSN','A001'),{'fromssn'});
    tests.UpperCaseAliasLookup=aliasFound && strcmp(value_to_string(aliasValue),"A001") && strcmp(aliasField,'FROM_SSN');
    [aliasValue,aliasFound]=get_alias_value(struct('FromSSN','A002'),{'FROM_SSN'});
    tests.MixedCaseAliasLookup=aliasFound && strcmp(value_to_string(aliasValue),"A002");
    tests.HeightMillimetreConversionError=abs(convert_height_to_m(1000,'millimetres')-1);
    tests.HeightCentimeterConversionError=abs(convert_height_to_m(100,'centimeters')-1);
    tests.LengthMetreConversionError=abs(convert_length_to_km(1000,'meters')-1);
    tests.LengthMillimetreConversionError=abs(convert_length_to_km(1e6,'millimeters')-1);
    try
        minimax_route_weights([1;1],[1;NaN],1);tests.RejectsNonfiniteExposure=false;
    catch ME
        tests.RejectsNonfiniteExposure=strcmp(ME.identifier,'minimax_route_weights:InvalidInput');
    end

    % Fixture parsing and graph/case extraction.
    [raw,rowsRead]=parse_tabular_observations(cfg.fixtureFile,cfg);tests.FixtureRowsRead=rowsRead;
    [E,cleanReport]=clean_and_collapse_observations(raw,cfg);tests.FixturePhysicalEdges=height(E);tests.FixtureRemovedInvalid=cleanReport.RemovedInvalid;
    net=build_network(E);tests.GraphEdgeCount=numedges(net.G);tests.GraphNodeCount=numnodes(net.G);
    [cases,~,~]=find_public_validation_cases(E,cfg,runDir,logFile);tests.FixtureCases=numel(cases);
    [trainCases,testCases,splitReport]=split_public_cases(cases,cfg,runDir,logFile);tests.TrainingCases=numel(trainCases);tests.TestCases=numel(testCases);tests.SharedEdges=splitReport.SharedEdges;
    calibration=calibrate_public_covariance(trainCases,cfg,runDir,logFile);tests.CalibrationFinite=all(isfinite([calibration.sigma2 calibration.kappa]));
    validation=evaluate_public_methods(testCases,calibration,cfg,runDir,logFile);tests.ValidationRows=height(validation.casewise);tests.MethodCount=height(validation.summary);

    % JSON serialization with a table field.
    jsonPath=fullfile(tmpRoot,'table_test.json');write_json_file(jsonPath,struct('Table',validation.summary));tests.JSONWritten=exist(jsonPath,'file')==2;
catch ME
    messages(end+1)=string(ME.identifier)+": "+string(ME.message); %#ok<AGROW>
end
thresholds=struct('C2WeightError',1e-12,'GammaBWeightInvariance',1e-12, ...
    'GammaBObjectiveInvariance',1e-12,'WeightSumError',1e-12,'NNLSParameterError',1e-10, ...
    'HeightMillimetreConversionError',1e-12,'HeightCentimeterConversionError',1e-12, ...
    'LengthMetreConversionError',1e-12,'LengthMillimetreConversionError',1e-12);
checks=true(0,1);checkNames=strings(0,1);names=fieldnames(thresholds);
for i=1:numel(names)
    checkNames(end+1,1)=string(names{i}); %#ok<AGROW>
    if isfield(tests,names{i}),checks(end+1,1)=tests.(names{i})<=thresholds.(names{i});else,checks(end+1,1)=false;end %#ok<AGROW>
end
requiredLogical={'DeclarationParserAllFiles','NormalizedUpperCase','NormalizedMixedCase', ...
    'UpperCaseAliasLookup','MixedCaseAliasLookup','RejectsNonfiniteExposure','CalibrationFinite','JSONWritten'};
for i=1:numel(requiredLogical),checkNames(end+1,1)=string(requiredLogical{i});checks(end+1,1)=isfield(tests,requiredLogical{i})&&logical(tests.(requiredLogical{i}));end %#ok<AGROW>
requiredNumeric={{'FixtureRowsRead',288},{'FixturePhysicalEdges',288},{'GraphEdgeCount',288},{'SharedEdges',0}};
for i=1:numel(requiredNumeric),nm=requiredNumeric{i}{1};val=requiredNumeric{i}{2};checkNames(end+1,1)=string(nm);checks(end+1,1)=isfield(tests,nm)&&tests.(nm)==val;end %#ok<AGROW>
checkNames(end+1,1)="FixtureCasesMinimum";checks(end+1,1)=isfield(tests,'FixtureCases')&&tests.FixtureCases>=cfg.split.minimumTrainingCases+cfg.split.minimumTestCases;
checkNames(end+1,1)="ValidationRowsPositive";checks(end+1,1)=isfield(tests,'ValidationRows')&&tests.ValidationRows>0;
report=struct('Passed',isempty(messages)&&all(checks),'Tests',tests,'Messages',messages,'Thresholds',thresholds, ...
    'FailedChecks',checkNames(~checks), ...
    'FixtureIsPublicData',false,'Note','The fixture validates code flow only and is not manuscript evidence.');
end
function cleanup_temp(pathName)
if exist(pathName,'dir'),try,rmdir(pathName,'s');catch,end,end
end
