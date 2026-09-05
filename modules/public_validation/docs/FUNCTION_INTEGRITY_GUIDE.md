# Function-integrity guide

## Verify the entry point

From the package root in MATLAB:

```matlab
clear functions
rehash
which RUN_PUBLIC_QUICK -all
```

The first result must be `<package root>/RUN_PUBLIC_QUICK.m`. If another file appears first, remove the conflicting path or start a clean MATLAB session.

## Run the packaged audit

```matlab
A = RUN_PACKAGE_AUDIT();
```

The audit writes:

```text
audit/PACKAGE_INTEGRITY_REPORT.txt
audit/PACKAGE_INTEGRITY_REPORT.json
audit/FUNCTION_INVENTORY.csv
```

A valid audit has:

```text
Missing files: 0
Function-name mismatches: 0
Resolution errors: 0
Unexpected MATLAB files: 0
Duplicate manifest entries: 0
Code Analyzer fatal messages: 0
Unit tests passed: 1
OVERALL PASS: 1
```

Code Analyzer may report style or performance messages without failing the audit. Parse or syntax errors are fatal.

The v2.1 failure report and inventory are retained under `audit/V2_1_RUNTIME_*` for traceability. They are historical records, not the v2.2 audit result. Running `RUN_PACKAGE_AUDIT` creates the current `PACKAGE_INTEGRITY_REPORT.*` and `FUNCTION_INVENTORY.csv` files.
