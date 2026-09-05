# Changelog

## v2.2.0

- Fixed the runtime audit parser that returned an empty function name for valid declarations with multiple outputs such as `[A,B] = function_name(...)`.
- Added `read_primary_function_name.m`, covering no-output, single-output, multiple-output, continued, commented, and UTF-8-BOM-prefixed declarations.
- Added a declaration-name regression over every packaged entry point and supporting function.
- Expanded the runtime inventory with detected names, existence flags, resolved paths, and match flags.
- Added checks for unexpected `.m` files, duplicate manifest entries, localized Code Analyzer parse/syntax errors, and named unit-test failures.
- Fixed long-form millimetre/millimeter and centimetre/centimeter conversion, which could previously match the generic metre/meter branch first.
- Added conversion regression tests and validation for nonfinite or negative covariance-exposure input.
- Rejects a parsed dataset when every observation is removed during cleaning, and validates the disjoint-path mode before graph traversal.

## v2.1.0

- Restored the missing callable `RUN_PUBLIC_QUICK.m` entry point and four other root entry points.
- Added 44 supporting MATLAB functions.
- Added `RUN_PACKAGE_AUDIT` and deterministic unit tests.
- Added an offline end-to-end self-test with 288 physical edges and 24 four-path cases.
- Fixed accidental treatment of `data/raw/ngs/README.txt` as a public observation file.
- Fixed lexical station orientation, graph-edge/source-row mapping, string-matrix sizing, train/test edge collection, coefficient serialization, and JSON table serialization.
- Replaced the unsafe all-pairs `nchoosek` construction for large graph components with capped pair sampling.
- Added separate route-only/held-out evaluation outputs, paired bootstrap fields with explicit sign definitions, figure QA, progress logging, and timestamped result archives.
- Added robust parsing for tabular input and nested/cell GeoJSON coordinates.

## v1

Incomplete archive: documentation was present but MATLAB source files were absent. Do not use.
