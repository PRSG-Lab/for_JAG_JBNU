# JAG Unified Levelling MATLAB Package v1.0.0

The analysis procedures of the two supplied packages have been combined into a single runner and folder structure. **Figure fonts, colours, lines, markers, axes, legends, sizes, resolutions and binning settings are unchanged from the originals.** The initial GSVS17 analysis figures and the addendum figures are preserved separately, and the six final figures are also collected in one folder.

This package is a unified build of the two supplied MATLAB codebases. It does not replace the full reproducibility package covering the theoretical experiments of the complete current manuscript, nor the extended mean-structure, sight-geometry and spatial-resampling analyses. Those extensions belong to the separate scope of the existing `JAG_reproducibility_v3.zip`.

## 1. Quick start

Unzip the archive and set the MATLAB Current Folder to **the folder containing RUN_JAG.m**. There is no need to register every subfolder at once with `genpath`.

```matlab
RUN_JAG('help')
A = RUN_JAG('audit');       % integrity, existing unit tests, integration regression tests
S = RUN_JAG('selftest');    % synthetic public-network run + GSVS17 parsing/ML check
G = RUN_JAG('gsvs17');      % field GSVS17: full baseline + addendum run
```

`gsvs17` uses 2,000 bootstrap replicates and the full profile grid, as in the original. It runs without any separate download because the 125 `.lvl` files are included.

| Task | MATLAB command | Data and results |
|---|---|---|
| Usage | `RUN_JAG('help')` | Available actions and path-configuration guidance |
| Code audit | `RUN_JAG('audit')` | File hashes, public-module integrity, unit tests, integration regression tests |
| Code-flow check | `RUN_JAG('selftest')` | Full run of the public-network synthetic fixture and its six figures; GSVS17 parsing and M0/M1 fitting |
| Full GSVS17 analysis | `RUN_JAG('gsvs17')` | Field section-pair analysis, two MAT files, five baseline figures, four addendum figures, six final figures |
| Reduced public-network analysis | `RUN_JAG('public-quick')` | Falls back to the synthetic fixture only when the field public-network files are absent, and flags `OFFLINE_FIXTURE` |
| Full public-network analysis | `RUN_JAG('public-full')` | Requires the field public-network files. No synthetic substitution |
| Both modules in sequence | `RUN_JAG('all')` | Full GSVS17 analysis followed by **public-quick**. The public-network part may be a fixture |

The public-network results from `selftest` are not empirical evidence. The raw public-network data are not included in either code ZIP. Place the NOAA NGS observation and benchmark files in `data/raw/ngs/` and then run `public-full`.

## 2. Environment and path configuration

**Verified execution environment:** MATLAB R2026a Update 4, macOS arm64. The package runs on base MATLAB and does not require the Statistics, Optimization or Mapping Toolbox. Because it uses Java-based hashing and path handling, run it in a normal MATLAB session with the JVM enabled, or under `-batch`. The original public module recommends R2021b or later; earlier versions and GNU Octave were not verified in this round.

```matlab
cfg = JAG_CONFIG();
cfg.outputDir = fullfile(pwd, 'my_results');
cfg.publicDataDir = fullfile(pwd, 'my_ngs_files');
cfg.gsvsDataDir = fullfile(pwd, 'my_lvl_files');
G = RUN_JAG('gsvs17', cfg);
```

| Setting | Meaning |
|---|---|
| `packageRoot` | Code location. Set automatically; do not modify |
| `outputDir` | Parent folder for all unified run outputs. Default `runs/` |
| `publicDataDir` | Folder holding the raw public NGS observation and benchmark data. Default `data/raw/ngs/` |
| `gsvsDataDir` | Folder that directly contains the `.lvl` files. Default `data/raw/gsvs17/` |

Relative paths are resolved against the MATLAB current folder. The unified runner accepts path options only. Figure and analysis defaults are retained from each original module, and the differing styles of the two modules are not harmonised. On normal termination or on error, the search path, current folder and random-number state are restored. The `clear; close all; clc;` statements in the GSVS17 scripts were removed when converting them to functions, so caller variables and previously open figures are not cleared. New GSVS17 figures open with the original settings.

## 3. Folder structure

```text
JAG_leveling_unified_v1/
  README.md                         Usage and descriptions of every function
  RUN_JAG.m                         Single entry point
  JAG_CONFIG.m                      Path configuration
  +jag/                             Execution, path and verification management functions
  modules/
    public_validation/              Existing 5 entry points + matlab/45 functions
    gsvs17/                         2 functionised analyses + 5 supporting functions
  data/raw/
    gsvs17/                         125 verified raw .lvl files
    ngs/                            Location for public-network input (guidance file only)
  docs/                             Detailed function specifications, review notes, interpretation guidance
  tests/                            Integration regression tests
  provenance/                       The two original ZIPs, data sources, source-change and hash records
  verification/                     Evidence from this round's MATLAB comparison runs and figure preservation
  runs/                             Created automatically at run time
```

The synthetic fixture and project list of the public module are kept in `modules/public_validation/data/` so that the original audit structure is preserved. Similar statistical helpers from the two modules were not merged, because their percentile conventions and fitting purposes differ and a naive merge could change the numerical results.

## 4. Reading the outputs

### GSVS17

```text
runs/GSVS17_<timestamp>_<unique>/
  run_manifest.json
  baseline/
    GSVS17_calibration_results.mat
    fig1 ... fig5                   FIG/PNG from the original first stage
  addendum/
    GSVS17_addendum_results.mat
    fig1, fig3, fig4, fig6           FIG/PNG from the original additional analysis
  figures/
    fig1 ... fig6                   Final collection: addendum 1, 3, 4, 6 + baseline 2, 5
    figure_index.json
```

The final collection copies the generated files as they are. Nothing is redrawn and no resolution is changed. The initial versions of figures 1, 3 and 4, which the original addendum replaced, also remain under `baseline`.

```matlab
G = RUN_JAG('gsvs17');
R = load(G.CalibrationMAT);
R.M1                              % fit results
R.bootstrap                       % results of the 2,000 bootstrap replicates
D = load(G.AddendumMAT);
D.powerlaw                        % exponent profile of the power-law model
openfig(fullfile(G.FinalFigureDirectory, 'fig1_variance_vs_length.fig'))
```

The MAT files store the fields of the result structure as top-level variables. Access them as `R.M1`, `R.data` and so on, not as `R.RESULTS`.

### Public-network validation

A ZIP named like `runs/public_validation/PublicLeveling_<mode>_<timestamp>/` is produced. The main files are `KEY_RESULTS_SUMMARY.txt`, `04_validation/method_summary.csv`, `04_validation/casewise_results.csv`, `05_figures/`, `all_public_validation_results.mat` and `unified_run_manifest.json`. The original stage folders and the FIG/PNG/PDF/TIF outputs of the six figures are retained. `selftest` records explicitly in the run manifest that the data are synthetic.

Audits are performed on the copy in `runs/audit_<...>/public_module_snapshot/`. The reports and test files used by the existing public-module auditor are also written inside this copy, so running through the unified entry point does not modify the distributed code folder. If you invoke the module's legacy `RUN_PUBLIC_*` entry points directly, they use the module-internal data/runs/audit paths as in the original.

## 5. Figure preservation and actual verification

| Item | Settings retained / verification performed |
|---|---|
| GSVS17 | All fonts 20 pt; lines, markers, colours, Figure Position, axis limits, binning and legends; PNG at 300 dpi plus `.fig` saving |
| Public network | font 10, line width 1.5, marker size 6, PNG 300 dpi, TIFF 600 dpi, and the original per-figure settings |
| Source comparison | The two GSVS17 plot blocks, all original CFG assignment statements, the font helper, and the public-network config / figure-generation / saving / readability-audit files are identical |
| Numerical comparison | 11 GSVS17 baseline, 4 addendum and 8 public fixture result field groups are identical between original and unified builds under `isequaln` |
| Rendering comparison | **All 15 PNGs are pixel-identical** between original and unified builds: 5+4 for GSVS17, 6 for the public fixture |
| Execution verification | Public fixture with 288 observations and 12 cases (8 training / 4 test); GSVS17 with 125 files, 562 sections, 274 forward/backward pairs and 2,000 bootstrap replicates |

The comparisons above refer to default-setting runs of the original and unified builds in the same R2026a environment. `public-full` on the field public network could not be verified as a successful run because the raw data are unavailable; it was confirmed that it returns an error rather than substituting synthetic data when the input is missing. Detailed JSON is in `verification/`.

## 6. Changes and data interpretation

**Functional fix:** In the public module, `normalize_field_name` was deleting uppercase characters before lower-casing. This was corrected so that mixed-case fields are also matched by alias, and four regression checks were added. The computations and figures for the existing synthetic fixture are identical before and after the fix. Only raw/runs path-selection arguments were added to the public run functions.

**Functionisation:** The two GSVS17 scripts were converted into functions of the same name that accept input and output paths through `options` and return results. The numerical algorithms and plot blocks were retained. A diff against the originals is given in the [source change log](provenance/SOURCE_CHANGES.md).

**Bundled data:** Neither code ZIP contained field raw data. The 125 GSVS17 LVL files included in `JAG_reproducibility_v3.zip` from the current manuscript work are bundled here byte-for-byte. They were confirmed to match the official NGS raw-data ZIP of that reproducibility package. Provenance and hashes are recorded in the [data manifest](provenance/data_manifest.json).

**Scope of interpretation:** The GSVS17 module analyses the repeatability of section forward/backward differences. Those results alone do not establish route-wide coherence, route-specific variance upper bounds, or the joint covariance scenario set. `Consistency95` for the public network is not coverage relative to an error-free truth; it is an agreement rate against a separate reference route. Some of the stronger interpretations in the original module READMEs, console output and figures are preserved source material and are not a basis for direct citation in the present manuscript. Please read the [data and interpretation guidance](docs/DATA_AND_INTERPRETATION.md) together with the per-module review documents.

## 7. Troubleshooting

| Situation | What to check |
|---|---|
| `RUN_JAG` not found | Set the Current Folder to the folder inside the ZIP that contains RUN_JAG.m |
| Source integrity check fails | Compare modified or missing files against the manifest. Extract the original ZIP into a new folder and diff |
| GSVS17 `.lvl` files not found | Confirm that the `.lvl` files sit directly under cfg.gsvsDataDir (the search is not recursive) |
| No input for public-full | Add the NGS observation and benchmark raw data to data/raw/ngs, or specify the path |
| Too few path cases or test cases | Check the non-shared path structure and sample size of the input network. This condition is separate from the GSVS17 forward/backward pair analysis |
| Axis range of baseline Figure 1 is large | A characteristic of the original initial figure. The corrected addendum version is included in figures/ |
| Reproduced results differ from the manuscript's interpretation | Distinguish the scope of the two original modules from that of the subsequent manuscript reanalysis. For full reproduction of the current manuscript, see the separate package |

## 8. Description of every function

The following describes 15 unified functions, 82 public-module functions (including local functions) and 21 GSVS17 functions (including local functions). There are 72 MATLAB files in total. Detailed specifications of input/output structures, units and options are given in the [public-module function specification](docs/FUNCTIONS_PUBLIC.md) and the [GSVS17 function specification](docs/FUNCTIONS_GSVS17.md).

### 8.1 Unified execution and verification functions

| File | Call form | Description |
|---|---|---|
| `RUN_JAG.m` | `info = RUN_JAG(action,cfg)` | Takes an action name and optional path settings, runs the corresponding module, and returns the result locations. Restores the path, current folder and RNG on exit or error. |
| `JAG_CONFIG.m` | `cfg = JAG_CONFIG()` | Builds the four default input and output paths relative to the current package location. |
| `+jag/validate_config.m` | `cfg = jag.validate_config(cfg,root)` | Accepts only the four path fields and checks package-root consistency and path format. |
| `+jag/absolute_path.m` | `value = jag.absolute_path(value)` | Converts a relative path to an absolute path relative to the MATLAB current folder. |
| `+jag/restore_environment.m` | `jag.restore_environment(state)` | Restores the saved working folder, random-number state and search path. Need not be called directly. |
| `+jag/gsvs_options.m` | `cfg = jag.gsvs_options(cfg,options,stage)` | Overrides only the per-stage GSVS17 input and output paths and rejects changes to analysis or figure settings. |
| `+jag/new_run.m` | `runDir = jag.new_run(outputDir,kind)` | Creates a result folder whose name combines a timestamp with a temporary unique token so it cannot collide with existing results. |
| `+jag/write_json.m` | `jag.write_json(file,value)` | Saves a structure or similar value as a UTF-8 JSON file and closes the file handle. |
| `+jag/run_gsvs17.m` | `info = jag.run_gsvs17(cfg)` | Runs the GSVS17 baseline and addendum in sequence and retains the two MAT files, the original figure sets and the final figure collection. |
| `+jag/run_public.m` | `info = jag.run_public(cfg,mode)` | Passes the shared raw/runs paths to the public-validation module. Adds the unified manifest and then refreshes the result ZIP. |
| `+jag/sha256.m` | `hash = jag.sha256(file)` | Computes the SHA-256 of a local file via the JVM. Large files are read in chunks. |
| `+jag/verify_sources.m` | `report = jag.verify_sources(root)` | Compares the MATLAB and input file hashes in the distribution manifest and returns modified or missing files. |
| `+jag/audit.m` | `report = jag.audit(cfg)` | Performs source-integrity checking, the public module's existing checks, and the integration regression tests. Audits a copy of the module so the distributed source is not modified. |
| `+jag/selftest.m` | `info = jag.selftest(cfg)` | Checks a full run of the public synthetic fixture and GSVS17 parsing, forward/backward pairing and M0/M1 fitting. The full GSVS17 profile and bootstrap are a separate run. |
| `tests/integration_tests.m` | `report = integration_tests(cfg)` | Regression-checks mixed-case field-name handling, relative paths, preservation of figure defaults, and rejection of disallowed settings. |

### 8.2 All functions of the public levelling module

File paths are relative to `modules/public_validation/`. Local and nested functions are used inside their owning file and are not APIs to be called directly.

| File / kind | Function | Description |
|---|---|---|
| `RUN_OFFLINE_SELFTEST.m` (entry point) | `RUN_OFFLINE_SELFTEST` | Runs the integrity audit and then executes the whole procedure on the synthetic fixture. This is a code-flow check, not an empirical result on public data. |
| `RUN_OPEN_NGS_PROJECT_PAGES.m` (entry point) | `RUN_OPEN_NGS_PROJECT_PAGES` | Opens the NOAA NGS web pages listed in the project manifest in the default browser. It does not download observation files automatically. |
| `RUN_PACKAGE_AUDIT.m` (entry point) | `RUN_PACKAGE_AUDIT` | Checks the file inventory, function-name and path resolution, the MATLAB Code Analyzer, and the offline unit tests. |
| `RUN_PUBLIC_FULL.m` (entry point) | `RUN_PUBLIC_FULL` | After the audit, runs the full validation using public NGS data only. Aborts if the raw data are absent. |
| `RUN_PUBLIC_QUICK.m` (entry point) | `RUN_PUBLIC_QUICK` | After the audit, runs a reduced-scale validation. Falls back to the fixture only when public input is absent, and marks the run as OFFLINE_FIXTURE. |
| `matlab/build_network.m` (main function) | `build_network` | Builds an undirected graph from the cleaned observations E with length as edge weight, linking original rows and node coordinates. |
| `matlab/calibrate_public_covariance.m` (main function) | `calibrate_public_covariance` | Fits nominal and effective coherent scales from the squared discrepancies of training paths by non-negative Huber IRLS, and produces case-level bootstrap results and CSV output. |
| `matlab/calibrate_public_covariance.m` (local function) | `calibration_rows` | Squares the differences between candidate and reference paths to build the two-column design matrix X, the response y, within-case weights w, and caseID. |
| `matlab/canonicalize_station_pairs.m` (main function) | `canonicalize_station_pairs` | Sorts the two endpoint IDs lexicographically and returns a sign indicating whether the direction was reversed. |
| `matlab/clean_and_collapse_observations.m` (main function) | `clean_and_collapse_observations` | Removes invalid observations, merges identical physical sections into a common direction, and computes mean height difference, representative length and repeat-observation statistics. |
| `matlab/clean_and_collapse_observations.m` (local function) | `first_nonempty` | Returns the first non-empty entry of a string vector. |
| `matlab/clean_and_collapse_observations.m` (local function) | `coords_for_node` | Finds valid latitude and longitude for a given node from the selected observation rows. |
| `matlab/compute_path_statistics.m` (main function) | `compute_path_statistics` | Computes the direction-aware height difference Y, the length-sum-based A, the coherent-exposure proxy B, and the associated original row, node and project information. |
| `matlab/convert_height_to_m.m` (main function) | `convert_height_to_m` | Converts height units to m (mm, cm, m, ft). Unknown units raise a warning and are treated as m. |
| `matlab/convert_length_to_km.m` (main function) | `convert_length_to_km` | Converts length units to km (mm, cm, m, km, mi, ft). Unknown units raise a warning and are treated as km. |
| `matlab/evaluate_public_methods.m` (main function) | `evaluate_public_methods` | For the validation cases, computes the estimates, reference-path discrepancies, reported variances and agreement rates of six path-combination rules, and stores bootstrap and sensitivity results. |
| `matlab/figure_readability_audit.m` (main function) | `figure_readability_audit` | Inspects axis fonts, labels, number of lines and number of legend entries and writes a report. It does not modify figure properties. |
| `matlab/find_disjoint_paths.m` (main function) | `find_disjoint_paths` | Finds k node- or edge-disjoint paths by repeatedly selecting and removing the shortest positive-length path connecting the two endpoints. This is a greedy method, not an exhaustive search. |
| `matlab/find_public_validation_cases.m` (main function) | `find_public_validation_cases` | Finds four paths from endpoints satisfying connectivity and node-degree conditions, taking the shortest as reference and the remaining three as candidates. |
| `matlab/find_public_validation_cases.m` (local function) | `sample_pairs` | Uses all endpoint pairs when their number is below the limit, and otherwise draws a random sample without replacement. |
| `matlab/find_public_validation_cases.m` (local function) | `cases_to_tables` | Expands the case structure into a case summary table S and a per-path detail table R. |
| `matlab/find_public_validation_cases.m` (local function) | `route_row` | Turns the statistics of a single candidate or reference path into a one-row structure for export. |
| `matlab/generate_public_figures.m` (main function) | `generate_public_figures` | Generates the six figures — network, calibration diagnostics, method performance, agreement rate/width, per-case trade-off, and scale sensitivity — using the existing settings. |
| `matlab/generate_public_figures.m` (local function) | `short_method_name` | Converts method names to the original short display names used in figure annotations. |
| `matlab/get_alias_value.m` (main function) | `get_alias_value` | Looks up a structure field by normalised alias and returns the value, a found flag and the actual field name. A single partial match is also accepted. |
| `matlab/hash_file_sha256.m` (main function) | `hash_file_sha256` | Reads a file with Java MessageDigest and produces a SHA-256 hexadecimal string. |
| `matlab/infer_project_id.m` (main function) | `infer_project_id` | Extracts the project ID from an attribute project field or from the file name and replaces / with _. |
| `matlab/log_message.m` (main function) | `log_message` | Builds a message from a format string and variable arguments and writes it, with a timestamp, to the console and the log file. |
| `matlab/make_json_compatible.m` (main function) | `make_json_compatible` | Recursively converts table, struct, cell, string, datetime, categorical and function-handle values into JSON-serialisable values. |
| `matlab/method_coefficients_public.m` (main function) | `method_coefficients_public` | Builds the weights, formal variances, reported variances and information sets of the six methods from a, b and Gamma. |
| `matlab/method_coefficients_public.m` (nested function) | `add` | Nested function that appends one method to the parent function's methods structure array. |
| `matlab/minimax_route_weights.m` (main function) | `minimax_route_weights` | Computes the piecewise closed-form minimax weights and the active-set/objective information for a diagonal simplex uncertainty set with a>0, b>=0, Gamma>=0. |
| `matlab/normalize_field_name.m` (main function) | `normalize_field_name` | Lower-cases a field name for alias comparison and then strips punctuation. The unified build fixes the original uppercase-loss bug. |
| `matlab/open_ngs_project_pages.m` (main function) | `open_ngs_project_pages` | Reads rootDir/data/config/ngs_projects.csv and opens the project pages. |
| `matlab/package_integrity_audit.m` (main function) | `package_integrity_audit` | Checks the module's exact file inventory and the actual MATLAB function resolution paths, and records unit-test and Code Analyzer results as JSON/TXT/CSV. |
| `matlab/package_integrity_audit.m` (local function) | `manifest_consistency` | Compares the module root and matlab folder files against the manifest to find unregistered .m files and duplicate declarations. |
| `matlab/package_integrity_audit.m` (local function) | `mismatch_text` | Combines the file name and the detected function name into an audit error description. |
| `matlab/package_integrity_audit.m` (local function) | `same_path` | Obtains the Java canonical path where possible and compares whether two paths are the same. |
| `matlab/package_integrity_audit.m` (local function) | `run_code_analyzer` | Runs checkcode on every .m file in the manifest and collects the messages and the number of fatal syntax errors. |
| `matlab/package_integrity_audit.m` (local function) | `is_fatal_analyzer_message` | Determines whether a diagnostic ID or message is a parse or syntax error. |
| `matlab/package_integrity_audit.m` (local function) | `write_function_inventory` | Writes existence, declared function name and `which` resolution location to the function inventory CSV. |
| `matlab/package_integrity_audit.m` (local function) | `format_report` | Turns the structured audit results into a human-readable text report. |
| `matlab/paired_method_bootstrap.m` (main function) | `paired_method_bootstrap` | Summarises per-case differences in squared error, absolute error and interval width against the centroid using a paired bootstrap. |
| `matlab/paired_method_bootstrap.m` (local function) | `paired_case_diff` | Returns the metric differences between the comparison method and the centroid for a specified case ordering (including bootstrap duplicates). |
| `matlab/parse_leveling_files.m` (main function) | `parse_leveling_files` | Integrates ZIP extraction, benchmark pre-parsing, tabular and GeoJSON observation parsing, cleaning, and generation of the traceability report. |
| `matlab/parse_leveling_files.m` (local function) | `empty_observation_table` | Creates an empty table with the standard 15 observation columns. |
| `matlab/parse_ngs_benchmark_geojson.m` (main function) | `parse_ngs_benchmark_geojson` | Reads project, SSN, PID, latitude and longitude from an NGS benchmark GeoJSON. |
| `matlab/parse_ngs_observation_geojson.m` (main function) | `parse_ngs_observation_geojson` | Converts an NGS observation GeoJSON into the standard observation table and handles SSN/PID mapping, units and coordinates. |
| `matlab/parse_ngs_observation_geojson.m` (local function) | `empty_table` | Creates the standard empty 15-column observation table used by the GeoJSON parser. |
| `matlab/parse_ngs_observation_geojson.m` (local function) | `numeric_column` | Converts a cell or numeric column into a double column vector. |
| `matlab/parse_ngs_observation_geojson.m` (local function) | `map_ssn_to_pid` | Looks up the PID from the benchmark projectID+SSN and falls back to projectID:SSN when absent. |
| `matlab/parse_ngs_observation_geojson.m` (local function) | `lookup_coords` | Retrieves the benchmark latitude and longitude corresponding to a project ID and SSN. |
| `matlab/parse_ngs_observation_geojson.m` (local function) | `line_endpoints` | Returns the latitude and longitude of the first and last points of a GeoJSON coordinate array, together with a parse-success flag. |
| `matlab/parse_tabular_observations.m` (main function) | `parse_tabular_observations` | Finds column aliases in CSV/TXT/XLSX/XLS tables and returns an observation table with standardised height-difference and length units, plus the original row count. |
| `matlab/parse_tabular_observations.m` (local function) | `find_alias_column` | Normalises column names and permitted aliases and finds the index of the first matching column. |
| `matlab/parse_tabular_observations.m` (local function) | `table_scalar` | Safely reads a single cell value from a table and unwraps single-cell packaging. |
| `matlab/parse_tabular_observations.m` (local function) | `get_string_column` | Reads an aliased column as a string vector, filling with empty strings when absent. |
| `matlab/parse_tabular_observations.m` (local function) | `get_numeric_column` | Reads an aliased column as a numeric vector, filling with NaN when absent. |
| `matlab/public_scale_sensitivity.m` (main function) | `public_scale_sensitivity` | Varies the coherent scale multiplier and evaluates the empirical errors, same-set variance gain and weight differences of the minimax and centroid rules. |
| `matlab/public_validation_config.m` (main function) | `public_validation_config` | Configures the paths, standard units, path extraction, splitting, model, bootstrap and existing figure settings for quick/full/selftest. |
| `matlab/public_validation_unit_tests.m` (main function) | `public_validation_unit_tests` | Checks, in a temporary directory, the closed-form solution, Gamma-b equivalence, NNLS, the declaration parser, uppercase and mixed-case field aliases, unit conversion, fixture graph/split/evaluation, and JSON output. |
| `matlab/public_validation_unit_tests.m` (local function) | `cleanup_temp` | Cleans up the test-only temporary directory. |
| `matlab/read_primary_function_name.m` (main function) | `read_primary_function_name` | Reads the first function name in a .m file, accounting for single/multiple outputs and line-continued declarations. |
| `matlab/required_package_files.m` (main function) | `required_package_files` | Returns the required manifest consisting of 5 entry points, 45 supporting functions and 3 data files. |
| `matlab/resolve_input_files.m` (main function) | `resolve_input_files` | Searches the raw folder for input, decides between public-input and fixture mode, and records a SHA-256 manifest of the source files. |
| `matlab/robust_nnls2.m` (main function) | `robust_nnls2` | Iterates a weighted least-squares fit of two non-negative coefficients inside a Huber IRLS loop and returns the scale coefficients with the residual, weight and convergence history. |
| `matlab/robust_nnls2.m` (local function) | `nnls2_weighted` | Solves the inner two-variable non-negative least-squares problem by comparing the interior solution, the two boundary solutions and the zero solution as candidates. |
| `matlab/run_public_validation.m` (main function) | `run_public_validation` | Orchestrates the full run from input to parsing, path cases, training/test split, calibration/evaluation and figure/MAT/ZIP saving. The optional pathOptions accepts rawDir/runsDir only and does not change the existing model or figure settings. |
| `matlab/run_public_validation.m` (local function) | `write_failure_report` | Records the identifier, message and call stack of a failure exception in the run folder. |
| `matlab/run_public_validation.m` (local function) | `write_key_results_summary` | Summarises the run scale, estimated coefficients and per-method metrics, and states the evidential limitations explicitly when a fixture is used. |
| `matlab/safe_mkdir.m` (main function) | `safe_mkdir` | Creates a directory if it does not exist and raises an error on failure. |
| `matlab/save_figure_bundle.m` (main function) | `save_figure_bundle` | Saves PNG/PDF/TIFF/FIG and a readability report using the existing colour, resolution and vector settings, then closes the figure. |
| `matlab/simple_percentile.m` (main function) | `simple_percentile` | Sorts finite values only and computes percentiles by linear interpolation. Does not use the Statistics Toolbox. |
| `matlab/split_public_cases.m` (main function) | `split_public_cases` | Splits cases with a fixed seed and prevents shared physical edges between training and test sets and within each set. |
| `matlab/split_public_cases.m` (local function) | `collect_case_rows` | Gathers all original edge row numbers of the cases and removes duplicates. |
| `matlab/split_public_cases.m` (local function) | `local_case_tables` | Summarises the IDs, endpoints, path non-sharing type and edge counts of the split cases (R is an empty table). |
| `matlab/summarize_method_table.m` (main function) | `summarize_method_table` | Aggregates per-method RMSE, MAE, median and 95% absolute error, agreement rate, and mean interval width and reported variance from the casewise results. |
| `matlab/timestamp_string.m` (main function) | `timestamp_string` | Builds a UTC millisecond timestamp string for use in output folder names (falls back to datestr if datetime fails). |
| `matlab/value_to_double.m` (main function) | `value_to_double` | Converts the first numeric representation of a single value to double and returns NaN on failure. |
| `matlab/value_to_string.m` (main function) | `value_to_string` | Converts a single JSON or table value to a string and maps missing values to an empty string. |
| `matlab/write_json_file.m` (main function) | `write_json_file` | Converts data to a JSON-friendly form and writes a UTF-8 file, pretty-printed where possible. |
| `matlab/write_text_file.m` (main function) | `write_text_file` | Saves a string as a UTF-8 text file. |

### 8.3 Top-level GSVS17 functions

| File / call form | Input | Output and side effects | Role |
|---|---|---|---|
| `RESULTS = gsvs17_min_validation(options)` | Optional structure `options.dataDir` (`.lvl` folder) and `options.outDir` (save folder). When omitted, the original defaults `pwd/GSVS17_LVL` and `pwd/results` are used | Result structure `RESULTS`; `GSVS17_calibration_results.mat`; `.fig` and `.png` for figures 1–5; console summary | Organises the raw observations into sections and forward/backward pairs and computes the M0/M1 variance models, the boundary likelihood ratio, profiles, bootstrap and same-day diagnostics. The `clear; close all; clc;` of the original script was removed in the function adapter. The RNG is set with the original seed. |
| `ADD = gsvs17_addendum(options)` | Optional structure `options.matFile` (the preceding validation MAT) and `options.outDir` (save folder). The original default is `results` under the current folder | Result structure `ADD`; `GSVS17_addendum_results.mat`; `.fig` and `.png` for the revised figures 1, 3, 4 and the new figure 6 | Provides refits under different section-length lower limits, the exponent profile of the power-law variance model, variance-component identifiability, and equal-count bin figures. The unified runner links the baseline MAT with a separate output folder, so the earlier-stage figures are preserved. |
| `S = parse_gsvs17_lvl(dataDir)` | A folder directly containing the `.lvl` files. If omitted or empty, `pwd` | Section structure array `S`; printed counts of processed files and sections | Reads the B/S/E records of each file. From the S records it sums the backsight and foresight readings and distances to recompute the section height difference, length, number of set-ups and sight imbalance. Subfolders are not searched recursively. |
| `P = build_fb_pairs(S)` | A parsed, non-empty section structure array | Forward/backward pair structure array `P`; printed pair count, length and RMS | Groups the two SSNs without ordering and selects the first observation of that group and the first reciprocal observation. Computes `d_mm = 1000*(dH_f+dH_b)`. |
| `F = fit_variance_ml(d, L, n, useTau, fixed, opt)` | Forward/backward difference `d` [mm], mean section length `L` [km], mean number of set-ups `n`; `useTau` defaults to true; fixed variance-component structure `fixed`; optimiser options `opt` | Fit structure `F` | Fits the zero-mean Gaussian model `Var(d_i)=2*(sd2*L_i+ss2*n_i+tau2*L_i^2)` with `fminsearch` in log-variance coordinates. If `useTau=false`, then `tau2=0`. At least 4 samples are required. |
| `H = statlib_local()` | None | Structure with the function handles `chi2sf`, `chi2inv`, `norminv`, `prctile` | Returns local statistical helpers that do not require the Statistics Toolbox. Actual use is e.g. `H=statlib_local(); H.chi2sf(x,k)`. |
| `apply_font_size(figHandle, fs)` | Target figure handle and font size `fs` [pt]; 20 if omitted or empty | No return value. Changes the font size and the axis-label and title scaling of that figure | Sets all text elements — axes, ticks, labels, titles, legends, colorbars, annotations — to the same size. This is an existing presentation setting called for every figure in the original and was not changed during unification. |

#### Main structures and settings

`S` contains `file`, `dateStr`, `dateNum`, `runCode`, `obs`, `fromSSN`, `toSSN`, `fromDes`, `toDes`, `nSetups`, `distKm`, `dH_m`, `imb_m` together with cumulative reading, distance and standard-deviation fields. `sumB` and `sumF` are reading sums; `sumBd` and `sumFd` are sight-distance sums. File names are interpreted in the form `YYMMDD<run letter>...`.

`P` contains `ssnA`, `ssnB`, `desA`, `desB`, `d_mm`, `L_km`, `nSetups`, `sameDay`, `gapDays`, `imbSum_m`, `nRunsTotal`, `idxF` and `idxB`. Length and number of set-ups are the means of the two observations. `nRunsTotal` is the original number of observations for that section, and `idxF` and `idxB` are indices into `S`. `ssnA` and `ssnB` are sorted identifiers, but the original `desA` and `desB` follow the direction order of the selected first observation, so take care when matching names.

The available fields of `fixed` are `sd2`, `ss2` and `tau2`, and they are in **variance units**, not standard deviations. The default of `opt.nStarts` is 5 and the start-point bank holds at most 5 entries. `opt.theta0` is an additional start point in the log-variance of the free parameters and is used only when the dimensions match. The default of `opt.polish` is true. Even with `nStarts=1`, the original implementation computes two start points when `theta0` is supplied.

`F` contains `sd2`, `ss2`, `tau2`, `sigma_d`, `sigma_s`, `tau_r`, `theta`, `nll`, `v`, `vRun`, `z`, `nObs`, `nPar`, `aic`, `bic`, `useTau`, `fixed` and `converged`. Here `v` is the variance of the forward/backward difference, and `vRun=v/2` is the single-observation variance under the assumption of independent and identically distributed directions. The data-common normalising constant is omitted from `nll`, AIC and BIC.

The original defaults are `nBoot=2000`, `rngSeed=20260904`, `nBinsFig1=8`, `tauGrid=linspace(0.02,2.00,160)` and `ssGrid=linspace(0.00,0.40,121)`. The addendum defaults are `nBins=8`, `gamGrid=linspace(0.20,3.00,281)` and `subsets=[0,0.10,0.30,0.50,0.80]`. The power-law refit separately uses the three lower limits 0, 0.30 and 0.50 km.

### 8.4 All internal GSVS17 functions

| Owning file | Function form | Input → output | Role |
|---|---|---|---|
| `parse_gsvs17_lvl.m` | `s = emptySection()` | None → empty section structure | Defines the fields and initial values used by the parser. |
| `parse_gsvs17_lvl.m` | `[dateStr, runCode] = nameParts(fname)` | File name → date string and direction character | If the name has at least 7 characters, takes the first 6 as the date and the 7th as the run code. Returns empty strings if shorter. |
| `parse_gsvs17_lvl.m` | `dn = str2dateNum(dateStr)` | YYMMDD string → MATLAB serial date | Converts the date assuming the 2000s. Returns NaN if the length or digit check fails. This is not a function that strictly validates calendar ranges. |
| `build_fb_pairs.m` | `p = emptyPair()` | None → empty pair structure | Defines the fields and default values of the pair result. |
| `fit_variance_ml.m` | `nll = objective(theta)` — nested function | Log vector of free parameters → negative log-likelihood | Uses the parent function's observations and fixed values. Returns the penalty `1e12` for non-positive or non-finite fitted variances. |
| `fit_variance_ml.m` | `[sd2_, ss2_, tau2_] = unpack(theta)` — nested function | Log vector → the three variance components | Applies `exp(theta)+1e-12` to free parameters and the specified values to fixed parameters. |
| `statlib_local.m` | `p = chi2sf(x, k)` | Test value and degrees of freedom → upper-tail probability | Uses the upper tail of `gammainc`. Negative test values are set to 0. |
| `statlib_local.m` | `x = chi2inv(p, k)` | Probability vector and scalar degrees of freedom → quantile column vector | Inverts `gammainc` by bisection in at most 200 iterations. Returns 0 for `p<=0` and Inf for `p>=1`. The original row/column shape of the input probabilities is not preserved. |
| `statlib_local.m` | `z = norminvL(p)` | Normal cumulative probability → standard normal quantile | Computes `sqrt(2)*erfinv(2*p-1)`. The public handle name is `H.norminv`. |
| `statlib_local.m` | `q = prctileL(x, p)` | Data vector and percentile (0–100) → quantile | Removes non-finite data and interpolates linearly at rank `p*n/100+0.5`. Returns NaN if there are no data. The result has the same shape as `p`. The public handle name is `H.prctile`. |
| `gsvs17_min_validation.m` | `r = corrLocal(x, y)` | Two vectors → Pearson correlation coefficient | Normalises the mean-removed inner product. There is no separate handling of missing values or constant vectors. |
| `gsvs17_min_validation.m` | `s = ternary(cond, a, b)` | Logical value and two candidates → the selected value | Selects the conditional string for the console summary. |
| `gsvs17_addendum.m` | `[gHat, gCI, dev] = fit_powerlaw(d, L, grid)` | Forward/backward difference, positive lengths and exponent grid → exponent MLE, 95% profile interval, grid deviance | Fits `d~N(0,2*c*L^gamma)`. This model assumes normality, zero mean and independence; it is not a non-parametric test. The interval is the range of grid points with deviance ≤ 3.841458820694124. |
| `gsvs17_addendum.m` | `r = corrLocal(x, y)` | Two vectors → Pearson correlation coefficient | Computes the correlation between the bootstrap estimates of `sigma_d` and `tau_r`. This is the same internal implementation as in the minimum validation script. |
