# Output structure

Each run creates a new directory and a sibling ZIP archive under `runs/`.

```text
PublicLeveling_<mode>_<timestamp>/
  00_manifest/
  00_logs/
  01_source/
  02_cases/
  03_calibration/
  04_validation/
  05_figures/
  all_public_validation_results.mat
  KEY_RESULTS_SUMMARY.txt
  RUN_COMPLETED.txt
```

The source manifest records file names, byte sizes and SHA-256 checksums. A fixture run also contains `SELFTEST_ONLY.txt`.
