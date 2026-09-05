function cfg = public_validation_config(mode,rootDir)
%PUBLIC_VALIDATION_CONFIG Configuration for the independent public-data workflow.
if nargin < 1 || isempty(mode), mode = 'quick'; end
if nargin < 2 || isempty(rootDir), rootDir = fileparts(fileparts(mfilename('fullpath'))); end
mode = lower(char(mode));
if ~ismember(mode,{'quick','full','selftest'})
    error('public_validation_config:InvalidMode','Mode must be quick, full, or selftest.');
end

cfg = struct();
cfg.version = '2.2.0';
cfg.mode = mode;
cfg.rootDir = rootDir;
cfg.matlabDir = fullfile(rootDir,'matlab');
cfg.rawDir = fullfile(rootDir,'data','raw','ngs');
cfg.fixtureFile = fullfile(rootDir,'data','example','offline_fixture_observations.csv');
cfg.projectManifest = fullfile(rootDir,'data','config','ngs_projects.csv');
cfg.runsDir = fullfile(rootDir,'runs');
cfg.auditDir = fullfile(rootDir,'audit');
cfg.randomSeed = 20260904;

cfg.data = struct();
cfg.data.requirePublic = strcmp(mode,'full');
cfg.data.allowFixtureFallback = strcmp(mode,'quick') || strcmp(mode,'selftest');
cfg.data.forceFixture = strcmp(mode,'selftest');
cfg.data.acceptExtensions = {'.csv','.txt','.json','.geojson','.xlsx','.xls','.zip'};
cfg.data.heightOutputUnit = 'm';
cfg.data.lengthOutputUnit = 'km';
cfg.data.defaultHeightUnit = 'm';
cfg.data.defaultLengthUnit = 'km';
cfg.data.minPositiveLengthKm = 1e-6;
cfg.data.collapseParallelPhysicalEdges = true;

cfg.route = struct();
cfg.route.minimumCandidateRoutes = 3;
cfg.route.totalDisjointPaths = 4; % 3 candidate routes + 1 reference route
cfg.route.preferNodeDisjoint = true;
cfg.route.allowEdgeDisjointFallback = true;
cfg.route.maximumPathStretch = 5.0;
cfg.route.maximumPathEdges = 80;
cfg.route.maximumCandidatePairs = 500;
cfg.route.maximumCases = 40;
cfg.route.minimumUsableCases = 8;
cfg.route.minimumPublicCasesForManuscript = 20;
cfg.route.minimumPublicTestCasesForManuscript = 10;
cfg.route.referenceRule = 'shortest-of-disjoint-paths';
cfg.route.candidateNodeDegreeMin = 3;

cfg.split = struct();
cfg.split.trainingFraction = 0.65;
cfg.split.preventTrainTestEdgeSharing = true;
cfg.split.minimumTrainingCases = 4;
cfg.split.minimumTestCases = 3;

cfg.model = struct();
cfg.model.gammaFixed = 1.0;
cfg.model.huberConstant = 1.345;
cfg.model.irlsMaxIterations = 50;
cfg.model.irlsTolerance = 1e-10;
cfg.model.minimumVariance = 1e-16;
cfg.model.referenceVarianceRule = 'rectangular-upper';
cfg.model.commonFloor = 0.0; % not identifiable from one archival network snapshot

cfg.validation = struct();
cfg.validation.zCritical = 1.95996398454005;
cfg.validation.scaleMultipliers = logspace(-1,1,21);
cfg.validation.bootstrapReplicates = 250;
cfg.validation.calibrationBootstrapReplicates = 200;

cfg.plot = struct();
cfg.plot.enabled = true;
cfg.plot.pngDpi = 300;
cfg.plot.tiffDpi = 600;
cfg.plot.fontSize = 10;
cfg.plot.lineWidth = 1.5;
cfg.plot.markerSize = 6;
cfg.plot.visible = 'off';

if strcmp(mode,'quick')
    cfg.route.maximumCandidatePairs = 120;
    cfg.route.maximumCases = 16;
    cfg.validation.bootstrapReplicates = 100;
    cfg.validation.calibrationBootstrapReplicates = 80;
elseif strcmp(mode,'full')
    cfg.route.maximumCandidatePairs = 4000;
    cfg.route.maximumCases = 150;
    cfg.validation.bootstrapReplicates = 5000;
    cfg.validation.calibrationBootstrapReplicates = 2000;
elseif strcmp(mode,'selftest')
    cfg.route.maximumCandidatePairs = 100;
    cfg.route.maximumCases = 12;
    cfg.validation.bootstrapReplicates = 50;
    cfg.validation.calibrationBootstrapReplicates = 40;
end
end
