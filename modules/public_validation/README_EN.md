> **원본 모듈의 역사적 문서 / Archived module documentation.** 통합 실행법과 현재 해석 범위는 패키지 최상위 README.md를 따릅니다. 아래 내용에는 원본 당시의 경로·강한 해석·과거 검증 상태가 포함됩니다.

# Survey Review public-leveling validation package v2.2.0

The v2.1 runtime audit incorrectly rejected nine valid multiple-output function declarations. This release fixes that parser, adds regression checks, and contains five callable root entry points, 45 supporting functions, an offline fixture, unit tests, and separate quick/full public-data workflows.

## Run order

```matlab
clear functions
rehash
RUN_PACKAGE_AUDIT
RUN_OFFLINE_SELFTEST
```

After placing NOAA NGS observation and benchmark files in `data/raw/ngs/`:

```matlab
RUN_PUBLIC_QUICK
RUN_PUBLIC_FULL
```

`RUN_PUBLIC_QUICK.m` is a callable function at the package root. The quick mode uses the fixture only when no public files are found and labels the run `OFFLINE_FIXTURE`. The full mode never falls back.
