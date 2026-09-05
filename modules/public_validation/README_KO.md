> **원본 모듈의 역사적 문서 / Archived module documentation.** 통합 실행법과 현재 해석 범위는 패키지 최상위 README.md를 따릅니다. 아래 내용에는 원본 당시의 경로·강한 해석·과거 검증 상태가 포함됩니다.

# Survey Review 공개 수준측량 자료 검증 패키지 v2.2.0

## 중요 수정

이전 v1 ZIP은 문서만 들어 있고 MATLAB `.m` 파일이 포함되지 않은 불완전한 패키지였습니다. v2.1.0의 런타임 감사기는 다중 출력 함수 선언을 잘못 해석하여 정상 함수 9개를 함수명 불일치로 오판했습니다. v2.2.0은 이 결함을 수정하고 회귀시험을 추가했습니다.

- 루트 실행 함수 5개
- 지원 함수 45개
- 288개 관측 edge를 갖는 오프라인 fixture
- 패키지 무결성 검사와 단위시험
- 공개자료 전용 Full 실행과 fixture 대체가 가능한 Quick 실행
- 실행별 timestamp 결과 폴더와 ZIP 자동 생성

## 실행 순서

MATLAB의 Current Folder를 이 패키지 최상위 폴더로 설정합니다.

```matlab
clear functions
rehash
A = RUN_PACKAGE_AUDIT();
```

무결성 검사가 통과하면 전체 코드 흐름을 fixture로 확인합니다.

```matlab
RUN_OFFLINE_SELFTEST
```

공개 NOAA NGS 파일을 `data/raw/ngs/`에 넣은 후 다음을 실행합니다.

```matlab
RUN_PUBLIC_QUICK
```

Quick 결과를 확인한 뒤 본 분석을 수행합니다.

```matlab
RUN_PUBLIC_FULL
```

## 실행 함수

| 함수 | 역할 |
|---|---|
| `RUN_PACKAGE_AUDIT` | 파일 존재, 함수명, 경로 shadowing, Code Analyzer, 단위시험 검사 |
| `RUN_OFFLINE_SELFTEST` | 포함된 synthetic fixture로 end-to-end 실행 |
| `RUN_PUBLIC_QUICK` | 축소 실행; 공개파일이 없으면 fixture로 대체하고 명시적으로 표시 |
| `RUN_PUBLIC_FULL` | 공개파일만 허용하는 본 실행 |
| `RUN_OPEN_NGS_PROJECT_PAGES` | manifest에 수록된 공식 NGS project page 열기 |

감사 결과에서 `Function-name mismatches: 0`, `Unexpected MATLAB files: 0`, `Unit tests passed: 1`, `OVERALL PASS: 1`을 확인하십시오.

`RUN_PUBLIC_QUICK.m`은 패키지 루트에 있는 실제 MATLAB 함수입니다. MATLAB에서 아래 명령으로 위치를 확인할 수 있습니다.

```matlab
which RUN_PUBLIC_QUICK -all
```

## 공개자료 입력

NOAA NGS Leveling Projects Page에서 각 프로젝트의 다음 두 파일을 내려받습니다.

1. Download Observations (`.geojson`)
2. Download Bench Marks (`.geojson`)

파일은 `data/raw/ngs/`에 저장합니다. 여러 프로젝트를 함께 넣을 수 있습니다. `README.txt`는 입력자료에서 자동 제외됩니다.

## 결과

각 실행은 기존 결과를 덮어쓰지 않고 다음을 생성합니다.

```text
runs/PublicLeveling_<mode>_<timestamp>/
runs/PublicLeveling_<mode>_<timestamp>.zip
```

우선 확인할 파일:

```text
KEY_RESULTS_SUMMARY.txt
RUN_COMPLETED.txt
04_validation/method_summary.csv
04_validation/casewise_results.csv
05_figures/
```

## 해석상 제한

오프라인 fixture 결과는 코드 검증용이며 실증결과가 아닙니다. 공개자료 분석도 독립 reference route와의 일관성을 평가하며, reference route를 오차 없는 ground truth로 간주하지 않습니다.
