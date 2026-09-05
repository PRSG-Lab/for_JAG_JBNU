# 원본 대비 소스 변경

원본 ZIP 두 개는 `original_archives/`에 보존했다. 기존 MATLAB 파일 57개 중 52개는 바이트 단위로 동일하고, 아래 5개만 수정했다. 그 외 15개 MATLAB 파일은 통합 실행·검증 계층이다.

## modules/public_validation/matlab/normalize_field_name.m

```diff
--- original/normalize_field_name.m
+++ modules/public_validation/matlab/normalize_field_name.m
@@ -1,4 +1,4 @@
 function s = normalize_field_name(value)
 %NORMALIZE_FIELD_NAME Lowercase and remove punctuation for alias matching.
-s = lower(regexprep(char(string(value)),'[^a-z0-9]',''));
+s = regexprep(lower(char(string(value))),'[^a-z0-9]','');
 end
```

## modules/public_validation/matlab/public_validation_unit_tests.m

```diff
--- original/public_validation_unit_tests.m
+++ modules/public_validation/matlab/public_validation_unit_tests.m
@@ -31,6 +31,13 @@
         declarationMatches=declarationMatches && read_primary_function_name(p)==string(erase(manifest.FunctionFiles{j},'.m'));
     end
     tests.DeclarationParserAllFiles=declarationMatches;
+    % Field aliases must retain letters before case-insensitive matching.
+    tests.NormalizedUpperCase=strcmp(normalize_field_name('FROM_SSN'),'fromssn');
+    tests.NormalizedMixedCase=strcmp(normalize_field_name('FromSSN'),'fromssn');
+    [aliasValue,aliasFound,aliasField]=get_alias_value(struct('FROM_SSN','A001'),{'fromssn'});
+    tests.UpperCaseAliasLookup=aliasFound && strcmp(value_to_string(aliasValue),"A001") && strcmp(aliasField,'FROM_SSN');
+    [aliasValue,aliasFound]=get_alias_value(struct('FromSSN','A002'),{'FROM_SSN'});
+    tests.MixedCaseAliasLookup=aliasFound && strcmp(value_to_string(aliasValue),"A002");
     tests.HeightMillimetreConversionError=abs(convert_height_to_m(1000,'millimetres')-1);
     tests.HeightCentimeterConversionError=abs(convert_height_to_m(100,'centimeters')-1);
     tests.LengthMetreConversionError=abs(convert_length_to_km(1000,'meters')-1);
@@ -64,7 +71,8 @@
     checkNames(end+1,1)=string(names{i}); %#ok<AGROW>
     if isfield(tests,names{i}),checks(end+1,1)=tests.(names{i})<=thresholds.(names{i});else,checks(end+1,1)=false;end %#ok<AGROW>
 end
-requiredLogical={'DeclarationParserAllFiles','RejectsNonfiniteExposure','CalibrationFinite','JSONWritten'};
+requiredLogical={'DeclarationParserAllFiles','NormalizedUpperCase','NormalizedMixedCase', ...
+    'UpperCaseAliasLookup','MixedCaseAliasLookup','RejectsNonfiniteExposure','CalibrationFinite','JSONWritten'};
 for i=1:numel(requiredLogical),checkNames(end+1,1)=string(requiredLogical{i});checks(end+1,1)=isfield(tests,requiredLogical{i})&&logical(tests.(requiredLogical{i}));end %#ok<AGROW>
 requiredNumeric={{'FixtureRowsRead',288},{'FixturePhysicalEdges',288},{'GraphEdgeCount',288},{'SharedEdges',0}};
 for i=1:numel(requiredNumeric),nm=requiredNumeric{i}{1};val=requiredNumeric{i}{2};checkNames(end+1,1)=string(nm);checks(end+1,1)=isfield(tests,nm)&&tests.(nm)==val;end %#ok<AGROW>
```

## modules/public_validation/matlab/run_public_validation.m

```diff
--- original/run_public_validation.m
+++ modules/public_validation/matlab/run_public_validation.m
@@ -1,8 +1,29 @@
-function runInfo = run_public_validation(mode,rootDir)
+function runInfo = run_public_validation(mode,rootDir,pathOptions)
 %RUN_PUBLIC_VALIDATION End-to-end public or fixture validation workflow.
+% Optional pathOptions accepts only rawDir and runsDir; analytical and plot
+% settings are inherited unchanged from public_validation_config.
 if nargin<1||isempty(mode),mode='quick';end
 if nargin<2||isempty(rootDir),rootDir=fileparts(fileparts(mfilename('fullpath')));end
-cfg=public_validation_config(mode,rootDir);safe_mkdir(cfg.runsDir);
+if nargin<3||isempty(pathOptions),pathOptions=struct();end
+if ~isstruct(pathOptions)||~isscalar(pathOptions)
+    error('run_public_validation:InvalidPathOptions','pathOptions must be a scalar struct.');
+end
+cfg=public_validation_config(mode,rootDir);
+optionNames=fieldnames(pathOptions);
+for optionIndex=1:numel(optionNames)
+    optionName=optionNames{optionIndex};
+    if ~ismember(optionName,{'rawDir','runsDir'})
+        error('run_public_validation:UnknownPathOption','Unsupported path option: %s. Only rawDir and runsDir are allowed.',optionName);
+    end
+    optionValue=pathOptions.(optionName);
+    validChar=ischar(optionValue)&&isrow(optionValue)&&~isempty(strtrim(optionValue));
+    validString=isstring(optionValue)&&isscalar(optionValue)&&~ismissing(optionValue)&&strlength(strtrim(optionValue))>0;
+    if ~(validChar||validString)
+        error('run_public_validation:InvalidPathValue','Path option %s must be a nonempty character row or string scalar.',optionName);
+    end
+    cfg.(optionName)=char(optionValue);
+end
+safe_mkdir(cfg.runsDir);
 runName=sprintf('PublicLeveling_%s_%s',lower(mode),timestamp_string());runDir=fullfile(cfg.runsDir,runName);archivePath=[runDir '.zip'];safe_mkdir(runDir);
 for d={'00_manifest','00_logs','01_source','02_cases','03_calibration','04_validation','05_figures'},safe_mkdir(fullfile(runDir,d{1}));end
 logFile=fullfile(runDir,'00_logs','console_output.txt');rng(cfg.randomSeed,'twister');
```

## modules/gsvs17/gsvs17_min_validation.m

```diff
--- original/gsvs17_min_validation.m
+++ modules/gsvs17/gsvs17_min_validation.m
@@ -1,3 +1,4 @@
+function RESULTS = gsvs17_min_validation(options)
 %GSVS17_MIN_VALIDATION  Minimum-viable empirical validation of the route-total
 %                       variance model using NGS GSVS17 levelling data.
 %
@@ -46,7 +47,8 @@
 %
 %   ---------------------------------------------------------------------
 
-clear; close all; clc;
+% Unified adapter: isolate workspace and preserve existing open figures.
+if nargin < 1, options = struct(); end
 
 %% ======================= 0.  CONFIGURATION ============================
 
@@ -66,6 +68,8 @@
 CFG.paper = struct('sigma_d', 0.40, ...   % mm / sqrt(km)
                    'sigma_s', 0.04, ...   % mm / set-up
                    'tau_r',   0.60);      % mm / km
+
+CFG = jag.gsvs_options(CFG, options, 'calibration');
 
 if ~exist(CFG.outDir, 'dir'), mkdir(CFG.outDir); end
 rng(CFG.rngSeed);
@@ -639,6 +643,8 @@
 fprintf('=====================================================\n\n');
 
 
+end % end of the callable workflow
+
 %% ======================= local helpers ================================
 
 function r = corrLocal(x, y)
```

## modules/gsvs17/gsvs17_addendum.m

```diff
--- original/gsvs17_addendum.m
+++ modules/gsvs17/gsvs17_addendum.m
@@ -1,3 +1,4 @@
+function ADD = gsvs17_addendum(options)
 %GSVS17_ADDENDUM  Robustness analysis and corrected figures for the GSVS17
 %                 minimum-viable validation.
 %
@@ -39,7 +40,8 @@
 %
 %   Base MATLAB only.
 
-clear; close all; clc;
+% Unified adapter: isolate workspace and preserve existing open figures.
+if nargin < 1, options = struct(); end
 
 %% ---------------------------- configuration ----------------------------
 CFG          = struct();
@@ -54,6 +56,9 @@
 CFG.paperSs  = 0.04;                    % mm/set-up
 CFG.figFmt   = '-dpng';
 CFG.figDPI   = '-r300';
+
+CFG = jag.gsvs_options(CFG, options, 'addendum');
+if ~exist(CFG.outDir, 'dir'), mkdir(CFG.outDir); end
 
 assert(exist(CFG.matFile, 'file') == 2, ...
     'Run gsvs17_min_validation.m first: %s not found.', CFG.matFile);
@@ -419,6 +424,8 @@
 fprintf('===============================================\n\n');
 
 
+end % end of the callable workflow
+
 %% ------------------------- local functions -----------------------------
 
 function [gHat, gCI, dev] = fit_powerlaw(d, L, grid)
```

