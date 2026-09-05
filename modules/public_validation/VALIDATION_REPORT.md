# Validation report — v2.2.0

## v2.1 runtime-audit failure diagnosis

The submitted MATLAB report showed zero missing files, zero resolution errors, zero fatal Code Analyzer messages, and passing unit tests. The only failing category was nine function-name mismatches. Every affected file had a valid multiple-output declaration. The v2.1 regular expression failed to extract the callable name after a bracketed output list and returned an empty string. This was an audit false negative, not a failure of the route-validation calculation.

v2.2 replaces the bracket-sensitive expression with a declaration reader and tests that reader against every packaged M-file. The historical v2.1 report is retained in `audit/V2_1_RUNTIME_FAILURE_REPORT.*`.

## Defect found in the previous archive

The previous v1 archive contained zero MATLAB `.m` files. Its statement that zero checked files constituted a pass was invalid. v1 must not be used.

## Completeness of this archive

- Root callable entry points: 5
- Supporting MATLAB function files: 45
- Missing required files in the build audit: 0
- Function declaration/file-name mismatches: 0
- Known package-internal call edges resolved: recorded in `audit/STATIC_INTERNAL_CALL_GRAPH.csv`

The callable root entry points are:

```text
RUN_PACKAGE_AUDIT.m
RUN_OFFLINE_SELFTEST.m
RUN_PUBLIC_QUICK.m
RUN_PUBLIC_FULL.m
RUN_OPEN_NGS_PROJECT_PAGES.m
```

## Independent numerical checks executed in the build environment

A Python implementation independent of the MATLAB source was used to check the bundled fixture and the closed-form minimax rule.

- Fixture observations: 288
- Unique physical edges: 288
- Graph nodes: 240
- Terminal pairs with four node-disjoint paths: 24
- C2 minimax coefficient maximum error: `4.441e-16`
- Gamma–b reparameterisation coefficient error: `5.551e-17`
- Status: PASS

Detailed machine-readable records are in `audit/`.

## MATLAB-runtime limitation

MATLAB and GNU Octave are not installed in the package-build environment. Consequently, this report does **not** claim that MATLAB Code Analyzer or the MATLAB unit tests were executed here.

The package contains a runtime audit that performs the following on the user's MATLAB installation:

1. verifies every required file;
2. verifies function-name/file-name agreement;
3. verifies path resolution with `which` and records the resolved path;
4. runs MATLAB Code Analyzer when available;
5. parses the fixture;
6. builds the graph and extracts four-path cases;
7. checks train/test edge independence;
8. runs covariance calibration and held-out method evaluation;
9. checks closed-form C2 coefficients and Gamma–b invariance;
10. checks JSON/table output;
11. tests every primary function declaration, including bracketed multiple outputs;
12. checks long-form metric unit conversion and invalid covariance-exposure rejection.

Run:

```matlab
RUN_PACKAGE_AUDIT
```

Only after it reports `OVERALL PASS: 1` should `RUN_PUBLIC_QUICK` or `RUN_PUBLIC_FULL` be used.
