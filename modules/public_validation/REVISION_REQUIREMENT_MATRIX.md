# Reviewer requirement–analysis matrix

| Reviewer issue | Package response | Output used after execution |
|---|---|---|
| M1: Gamma and b are not separately identifiable | Fix `GammaFixed = 1` and estimate an effective coherent scale `kappa`; do not claim separate empirical identification | `03_calibration/calibration_parameters.csv`, `04_validation/scale_sensitivity.csv` |
| M2: worst-case objective is not actual empirical performance | Report held-out route-reference discrepancies, RMSE, MAE, casewise squared error, interval width and paired bootstrap in addition to same-set risk | `04_validation/method_summary.csv`, `casewise_results.csv`, `paired_bootstrap.csv` |
| M5: no field/public data | Use official NOAA NGS project observations and benchmarks, with source hashes and edge-independent reference routes | `01_source/source_file_manifest.csv`, `02_cases/*.csv` |
| Need fair operational comparators | Include unweighted, baseline formal, baseline same-set, simplex-centroid GLS, aggregate minimax and rectangular upper GLS | `04_validation/method_summary.csv` |
| Need independent validation | Split route cases before calibration and prohibit physical-edge overlap between training and test sets | `02_cases/split_report.json` |
| Need reproducibility | Record configuration, seed, file hashes, standardized observations, case definitions, bootstrap outputs and figures | all run folders |

The workflow cannot turn a noisy reference route into error-free truth. Results must be described as held-out reference-route consistency rather than absolute accuracy.
