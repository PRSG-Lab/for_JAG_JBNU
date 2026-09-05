# JAG 통합 수준측량 MATLAB 패키지 v1.0.0

두 제공 패키지의 분석 절차를 하나의 실행기와 폴더 구조로 묶었습니다. **그림의 글꼴·색상·선·마커·축·범례·크기·해상도·구간화 설정은 원본 그대로입니다.** GSVS17의 초기 분석 그림과 addendum 그림을 별도로 보존하며, 최종 그림 6개도 한 폴더에 모읍니다.

이 패키지는 제공된 두 MATLAB 코드의 통합본입니다. 최신 논문 전체의 이론 실험, 평균구조·시준기하·공간 재표집 확장 분석까지 포함한 전체 재현 패키지를 대체하지는 않습니다. 해당 확장은 기존 `JAG_reproducibility_v3.zip`의 별도 범위입니다.

## 1. 바로 실행하기

ZIP을 풀고 MATLAB의 Current Folder를 **RUN_JAG.m이 있는 폴더**로 설정합니다. `genpath`로 모든 하위 폴더를 한꺼번에 등록할 필요는 없습니다.

```matlab
RUN_JAG('help')
A = RUN_JAG('audit');       % 무결성·기존 단위시험·통합 회귀시험
S = RUN_JAG('selftest');    % 합성 공개망 실행 + GSVS17 파싱/ML 점검
G = RUN_JAG('gsvs17');      % 실측 GSVS17: baseline + addendum 전체 실행
```

`gsvs17`은 원본과 같이 부트스트랩 2,000회와 전체 프로파일 격자를 사용합니다. 동봉한 125개 `.lvl` 파일로 별도 다운로드 없이 실행할 수 있습니다.

| 작업 | MATLAB 명령 | 데이터와 결과 |
|---|---|---|
| 사용법 | `RUN_JAG('help')` | 실행 작업과 경로 설정 안내 |
| 코드 감사 | `RUN_JAG('audit')` | 파일 해시·공개 모듈 무결성·단위시험·통합 회귀시험 |
| 코드 흐름 확인 | `RUN_JAG('selftest')` | 공개망 합성 fixture 전체 실행·그림 6개, GSVS17 파싱과 M0/M1 적합 |
| GSVS17 전체 분석 | `RUN_JAG('gsvs17')` | 실측 구간쌍 분석, 두 MAT 파일, baseline 그림 5개, addendum 그림 4개, 최종 그림 6개 |
| 공개망 축소 분석 | `RUN_JAG('public-quick')` | 실측 공개망 파일이 없을 때만 합성 fixture로 대체하고 `OFFLINE_FIXTURE` 표시 |
| 공개망 본 분석 | `RUN_JAG('public-full')` | 실측 공개망 파일 필요. 합성자료 대체 없음 |
| 두 모듈 연속 실행 | `RUN_JAG('all')` | GSVS17 전체 분석 후 **public-quick** 실행. 공개망 부분은 fixture일 수 있음 |

`selftest`의 공개망 결과는 실증 자료가 아닙니다. 공개망 원자료는 두 코드 ZIP에 포함되어 있지 않습니다. NOAA NGS의 관측·benchmark 파일을 `data/raw/ngs/`에 넣은 뒤 `public-full`을 실행하십시오.

## 2. 환경과 경로 설정

**실행 검증 환경:** MATLAB R2026a Update 4, macOS arm64. 기본 MATLAB 기능으로 실행하며 Statistics/Optimization/Mapping Toolbox를 요구하지 않습니다. Java 기반 해시와 경로 처리를 사용하므로 JVM이 켜진 일반 MATLAB 또는 `-batch` 실행을 사용합니다. 원본 공개 모듈의 권장 기준은 R2021b 이상이며, 이전 버전과 GNU Octave는 이번에 실행 검증하지 않았습니다.

```matlab
cfg = JAG_CONFIG();
cfg.outputDir = fullfile(pwd, 'my_results');
cfg.publicDataDir = fullfile(pwd, 'my_ngs_files');
cfg.gsvsDataDir = fullfile(pwd, 'my_lvl_files');
G = RUN_JAG('gsvs17', cfg);
```

| 설정 | 의미 |
|---|---|
| `packageRoot` | 코드 위치. 자동 설정되며 변경하지 않음 |
| `outputDir` | 모든 통합 실행 결과의 상위 폴더. 기본 `runs/` |
| `publicDataDir` | 공개 NGS 관측·benchmark 원자료 폴더. 기본 `data/raw/ngs/` |
| `gsvsDataDir` | `.lvl` 파일이 직접 들어 있는 폴더. 기본 `data/raw/gsvs17/` |

상대 경로는 MATLAB의 현재 폴더를 기준으로 해석합니다. 통합 실행기는 경로 옵션만 허용합니다. Figure와 분석 기본값은 각 원본 모듈에서 유지하며, 두 모듈의 서로 다른 스타일을 통일하지 않습니다. 일반 실행 종료나 오류 발생 시 검색 경로·현재 폴더·난수 상태를 복원합니다. GSVS17 스크립트의 `clear; close all; clc;`를 함수 전환 시 제거했으므로 호출자의 변수와 기존 열린 그림을 지우지 않습니다. 새 GSVS17 그림은 원본 설정대로 열립니다.

## 3. 폴더 구조

```text
JAG_leveling_unified_v1/
  README.md                         사용법과 모든 함수 설명
  RUN_JAG.m                         단일 실행 진입점
  JAG_CONFIG.m                      경로 설정
  +jag/                             실행·경로·검증 관리 함수
  modules/
    public_validation/              기존 5개 진입점 + matlab/45개 함수
    gsvs17/                         함수화한 분석 2개 + 지원 함수 5개
  data/raw/
    gsvs17/                         검증된 원시 .lvl 125개
    ngs/                            공개망 입력 위치(안내 파일만 동봉)
  docs/                             상세 함수 명세·검토·해석 안내
  tests/                            통합 회귀시험
  provenance/                       원본 ZIP 2개·데이터 출처·소스 변경/해시 기록
  verification/                     이번 MATLAB 비교 실행과 그림 보존 증거
  runs/                             실행 시 자동 생성
```

공개 모듈의 합성 fixture와 프로젝트 목록은 원본 감사 구조를 유지하기 위해 `modules/public_validation/data/`에 둡니다. 두 모듈의 비슷한 통계 헬퍼를 합치지 않았습니다. 백분위수 규약과 적합 목적이 달라 단순 통합하면 수치 결과가 달라질 수 있기 때문입니다.

## 4. 출력물 읽기

### GSVS17

```text
runs/GSVS17_<시각>_<고유값>/
  run_manifest.json
  baseline/
    GSVS17_calibration_results.mat
    fig1 ... fig5                   원래 첫 단계의 FIG/PNG
  addendum/
    GSVS17_addendum_results.mat
    fig1, fig3, fig4, fig6           원래 추가 분석의 FIG/PNG
  figures/
    fig1 ... fig6                   최종 모음: addendum 1·3·4·6 + baseline 2·5
    figure_index.json
```

최종 모음은 생성 파일을 그대로 복사합니다. 다시 그리거나 해상도를 바꾸지 않습니다. 원본 addendum이 교체하던 그림 1·3·4의 초기 버전도 baseline에 남습니다.

```matlab
G = RUN_JAG('gsvs17');
R = load(G.CalibrationMAT);
R.M1                              % 적합 결과
R.bootstrap                       % 2,000회 부트스트랩 결과
D = load(G.AddendumMAT);
D.powerlaw                        % 거듭제곱 모형 지수 프로파일
openfig(fullfile(G.FinalFigureDirectory, 'fig1_variance_vs_length.fig'))
```

MAT 파일에는 결과 구조체의 필드가 최상위 변수로 저장됩니다. `R.RESULTS`가 아니라 `R.M1`, `R.data` 등으로 접근합니다.

### 공개망 검증

`runs/public_validation/PublicLeveling_<mode>_<timestamp>/`와 같은 이름의 ZIP이 생깁니다. 주요 파일은 `KEY_RESULTS_SUMMARY.txt`, `04_validation/method_summary.csv`, `04_validation/casewise_results.csv`, `05_figures/`, `all_public_validation_results.mat`, `unified_run_manifest.json`입니다. 원본 단계 폴더와 그림 6개의 FIG/PNG/PDF/TIF 출력은 유지합니다. `selftest`는 실행 manifest에 합성자료임을 명시합니다.

감사는 `runs/audit_<...>/public_module_snapshot/`의 사본에서 수행합니다. 기존 공개 모듈 감사기가 쓰는 보고서와 시험 파일도 이 사본 안에 저장하므로 통합 진입점으로 실행할 때 배포 코드 폴더를 수정하지 않습니다. 모듈 내부의 옛 `RUN_PUBLIC_*` 진입점을 직접 사용하면 원본처럼 모듈 내부의 data/runs/audit 경로를 사용합니다.

## 5. 그림 보존과 실제 검증

| 항목 | 유지한 설정/검증 |
|---|---|
| GSVS17 | 모든 글꼴 20 pt, 선·마커·색·Figure Position·축 범위·구간화·범례·PNG 300 dpi 및 `.fig` 저장 |
| 공개망 | font 10, line width 1.5, marker size 6, PNG 300 dpi, TIFF 600 dpi, 원본의 개별 Figure 설정 |
| 소스 비교 | 두 GSVS17 plot 블록·모든 원래 CFG 대입문, font helper, 공개망 config/그림 생성/저장/가독성 검사 파일 동일 |
| 실제 수치 비교 | 원본과 통합본의 GSVS17 baseline 11개·addendum 4개·공개 fixture 8개 결과 필드 그룹이 `isequaln`으로 동일 |
| 렌더링 비교 | 원본과 통합본의 PNG **15개 모두 픽셀 단위 동일**: GSVS17 5+4개, 공개 fixture 6개 |
| 실행 검증 | 공개 fixture 288개 관측·12사례(훈련 8/시험 4), GSVS17 125파일·562구간·274왕복쌍·2,000회 bootstrap |

위 비교는 같은 R2026a 환경의 원본·통합본 기본 설정 실행에 대한 결과입니다. 공개 실측망의 `public-full`은 원자료가 없어 성공 실행을 검증하지 못했으며, 자료 누락 시 합성자료로 대체하지 않고 오류를 반환함을 확인했습니다. 상세 JSON은 `verification/`에 있습니다.

## 6. 변경 내용과 데이터 해석

**기능 수정:** 공개 모듈의 `normalize_field_name`이 대문자를 삭제한 후 소문자화하던 문제를 수정했습니다. 대소문자 혼합 필드도 별칭으로 찾도록 하고 회귀검사 4개를 추가했습니다. 기존 합성 fixture의 계산과 그림은 수정 전후 동일합니다. 공개 실행 함수에는 raw/runs 경로 선택 인수만 추가했습니다.

**함수화:** GSVS17의 두 스크립트를 같은 이름의 함수로 바꿔 `options`로 입력·출력 경로를 받고 결과를 반환하도록 했습니다. 수치 알고리즘과 plot 블록은 유지했습니다. [소스 변경 내역](provenance/SOURCE_CHANGES.md)에 원본 대비 diff가 있습니다.

**동봉 데이터:** 두 코드 ZIP에는 실측 원자료가 없었습니다. 현재 논문 작업의 `JAG_reproducibility_v3.zip`에 포함되어 있던 GSVS17 LVL 125개를 원본 바이트 그대로 포함했습니다. 해당 재현 패키지의 공식 NGS 원자료 ZIP과도 일치함을 확인했습니다. 출처·해시는 [데이터 manifest](provenance/data_manifest.json)에 기록했습니다.

**해석 범위:** GSVS17 모듈은 구간 왕복차의 반복성을 분석합니다. 그 결과만으로 경로 전체 coherence, 경로별 분산 상한, 공동 공분산 시나리오 집합이 검증되었다고 볼 수 없습니다. 공개망의 `Consistency95`는 오차 없는 참값에 대한 coverage가 아니라 별도 기준 경로와의 일치율입니다. 기존 모듈 README·콘솔·그림의 일부 강한 해석은 원본 보존 자료이며, 현재 논문에 그대로 인용할 근거가 아닙니다. [데이터·해석 안내](docs/DATA_AND_INTERPRETATION.md)와 모듈별 검토 문서를 함께 확인하십시오.

## 7. 문제 해결

| 상황 | 확인할 내용 |
|---|---|
| `RUN_JAG`를 찾지 못함 | Current Folder를 ZIP 내부의 RUN_JAG.m이 있는 폴더로 설정 |
| 소스 무결성 검사 실패 | 수정·누락 파일을 manifest와 대조. 원본 ZIP에서 새 폴더로 풀어 비교 |
| GSVS17 `.lvl` 없음 | cfg.gsvsDataDir 바로 아래에 `.lvl`이 있는지 확인(재귀 탐색 아님) |
| public-full 입력 없음 | NGS 관측·benchmark 원자료를 data/raw/ngs에 추가하거나 경로 지정 |
| 경로 사례·시험 사례 부족 | 입력망에서 비공유 경로 구성 및 표본 규모 확인. GSVS17 왕복쌍 분석과 별개의 조건임 |
| Figure 1 baseline의 축 범위가 큼 | 기존 초기 Figure의 특성. addendum의 보정 버전은 figures/에 포함됨 |
| 재현 결과의 본문 해석이 다름 | 원래 두 모듈과 후속 논문 재분석의 범위를 구분. 최신 논문 전체 재현은 별도 패키지 참조 |

## 8. 모든 함수 설명

아래에는 통합 함수 15개, 공개 모듈 함수 82개(로컬 포함), GSVS17 함수 21개(로컬 포함)를 설명합니다. MATLAB 파일은 총 72개입니다. 입출력 구조·단위·옵션의 상세 명세는 [공개 모듈 함수 명세](docs/FUNCTIONS_PUBLIC.md)와 [GSVS17 함수 명세](docs/FUNCTIONS_GSVS17.md)에 있습니다.

### 8.1 통합 실행·검증 함수

| 파일 | 호출 형식 | 설명 |
|---|---|---|
| `RUN_JAG.m` | `info = RUN_JAG(action,cfg)` | 작업명과 선택 경로 설정을 받아 모듈을 실행하고 결과 위치를 반환한다. 종료·오류 시 path, 현재 폴더, RNG를 복원한다. |
| `JAG_CONFIG.m` | `cfg = JAG_CONFIG()` | 현재 패키지 위치를 기준으로 입력·출력 기본 경로 네 개를 만든다. |
| `+jag/validate_config.m` | `cfg = jag.validate_config(cfg,root)` | 네 경로 필드만 허용하고 패키지 루트 일치 및 경로 형식을 확인한다. |
| `+jag/absolute_path.m` | `value = jag.absolute_path(value)` | 상대 경로를 MATLAB의 현재 폴더를 기준으로 절대 경로로 바꾼다. |
| `+jag/restore_environment.m` | `jag.restore_environment(state)` | 저장된 작업 폴더·난수 상태·검색 경로를 복구한다. 직접 실행할 필요가 없다. |
| `+jag/gsvs_options.m` | `cfg = jag.gsvs_options(cfg,options,stage)` | GSVS17 단계별 입력·출력 경로만 덮어쓰고 분석·그림 설정 변경은 거부한다. |
| `+jag/new_run.m` | `runDir = jag.new_run(outputDir,kind)` | 기존 결과와 충돌하지 않도록 시각과 임시 고유 이름을 조합한 결과 폴더를 만든다. |
| `+jag/write_json.m` | `jag.write_json(file,value)` | 구조체 등을 UTF-8 JSON 파일로 저장하고 파일 핸들을 닫는다. |
| `+jag/run_gsvs17.m` | `info = jag.run_gsvs17(cfg)` | GSVS17 baseline과 addendum을 차례로 실행하고 두 MAT·원래 그림 세트·최종 그림 모음을 보관한다. |
| `+jag/run_public.m` | `info = jag.run_public(cfg,mode)` | 공개검증 모듈에 공통 raw/runs 경로를 전달한다. 통합 manifest를 추가한 뒤 결과 ZIP도 갱신한다. |
| `+jag/sha256.m` | `hash = jag.sha256(file)` | 로컬 파일의 SHA-256을 JVM으로 계산한다. 대용량 파일은 나누어 읽는다. |
| `+jag/verify_sources.m` | `report = jag.verify_sources(root)` | 배포 manifest의 MATLAB·입력 파일 해시를 대조하고 변경·누락 파일을 반환한다. |
| `+jag/audit.m` | `report = jag.audit(cfg)` | 소스 무결성, 공개 모듈의 기존 검사와 통합 회귀시험을 수행한다. 모듈 사본에서 감사해 배포 소스를 수정하지 않는다. |
| `+jag/selftest.m` | `info = jag.selftest(cfg)` | 공개 합성 fixture의 전체 실행과 GSVS17 파싱·왕복쌍·M0/M1 적합을 검사한다. GSVS17 전체 프로파일/부트스트랩은 별도 실행이다. |
| `tests/integration_tests.m` | `report = integration_tests(cfg)` | 대소문자 필드명 처리, 상대 경로, 그림 기본값 보존, 허용되지 않은 설정 거부를 회귀검사한다. |

### 8.2 공개 수준측량 모듈의 모든 함수

파일 경로는 `modules/public_validation/` 기준입니다. 로컬·중첩 함수는 해당 소유 파일 안에서 사용하며 직접 호출하는 API가 아닙니다.

| 파일·종류 | 함수 | 설명 |
|---|---|---|
| `RUN_OFFLINE_SELFTEST.m` (진입점) | `RUN_OFFLINE_SELFTEST` | 무결성 감사를 거쳐 합성 fixture로 전체 절차를 실행한다. 공개자료 실증 결과가 아닌 코드 흐름 점검이다. |
| `RUN_OPEN_NGS_PROJECT_PAGES.m` (진입점) | `RUN_OPEN_NGS_PROJECT_PAGES` | 프로젝트 manifest의 NOAA NGS 웹페이지를 기본 브라우저로 연다. 관측 파일을 자동 다운로드하지 않는다. |
| `RUN_PACKAGE_AUDIT.m` (진입점) | `RUN_PACKAGE_AUDIT` | 파일 구성, 함수명·경로 해석, MATLAB Code Analyzer, 오프라인 단위시험을 검사한다. |
| `RUN_PUBLIC_FULL.m` (진입점) | `RUN_PUBLIC_FULL` | 감사 후 공개 NGS 자료만으로 전체 검증을 실행한다. 원자료가 없으면 중단한다. |
| `RUN_PUBLIC_QUICK.m` (진입점) | `RUN_PUBLIC_QUICK` | 감사 후 축소 규모 검증을 실행한다. 공개 입력이 없을 때만 fixture로 대체하고 OFFLINE_FIXTURE로 표시한다. |
| `matlab/build_network.m` (주 함수) | `build_network` | 정제 관측 E로 길이를 가중치로 하는 무방향 graph를 만들고 원본 행과 노드 좌표를 연결한다. |
| `matlab/calibrate_public_covariance.m` (주 함수) | `calibrate_public_covariance` | 훈련 경로의 제곱 불일치로 명목·유효 coherent 규모를 비음수 Huber IRLS로 적합하고 사례 단위 bootstrap 및 CSV를 생성한다. |
| `matlab/calibrate_public_covariance.m` (로컬 함수) | `calibration_rows` | 후보 경로와 기준 경로의 차이를 제곱해 2열 설계행렬 X, 반응 y, 사례 내 가중치 w, caseID를 만든다. |
| `matlab/canonicalize_station_pairs.m` (주 함수) | `canonicalize_station_pairs` | 양 끝점 ID를 사전 순서로 정렬하고 방향이 뒤집혔는지 나타내는 부호를 반환한다. |
| `matlab/clean_and_collapse_observations.m` (주 함수) | `clean_and_collapse_observations` | 잘못된 관측을 제거하고 동일 물리 구간을 공통 방향으로 합쳐 평균 고저차, 대표 길이, 반복관측 통계를 계산한다. |
| `matlab/clean_and_collapse_observations.m` (로컬 함수) | `first_nonempty` | 문자열 벡터에서 첫 번째 비어 있지 않은 항목을 반환한다. |
| `matlab/clean_and_collapse_observations.m` (로컬 함수) | `coords_for_node` | 선택된 관측 행에서 지정 노드의 유효 위도·경도를 찾는다. |
| `matlab/compute_path_statistics.m` (주 함수) | `compute_path_statistics` | 경로 방향을 반영한 고저차 Y, 길이 합 기반 A, coherent 노출 대용값 B, 원본 행·노드·프로젝트 정보를 계산한다. |
| `matlab/convert_height_to_m.m` (주 함수) | `convert_height_to_m` | 높이 단위를 m로 변환한다(mm, cm, m, ft). 알 수 없는 단위에는 경고하고 m로 간주한다. |
| `matlab/convert_length_to_km.m` (주 함수) | `convert_length_to_km` | 길이 단위를 km로 변환한다(mm, cm, m, km, mi, ft). 알 수 없는 단위에는 경고하고 km로 간주한다. |
| `matlab/evaluate_public_methods.m` (주 함수) | `evaluate_public_methods` | 검증 사례에서 여섯 경로 결합 규칙의 추정치·기준경로 불일치·보고분산·일치율을 계산하고 bootstrap/민감도 결과를 저장한다. |
| `matlab/figure_readability_audit.m` (주 함수) | `figure_readability_audit` | 축 글꼴, 레이블, 선 개수, 범례 개수를 검사해 보고서를 기록한다. figure 속성은 수정하지 않는다. |
| `matlab/find_disjoint_paths.m` (주 함수) | `find_disjoint_paths` | 양 끝점을 연결하는 양의 길이 최단경로를 순차 선택·제거하여 노드 또는 간선 비공유 경로 k개를 찾는다. 완전탐색이 아닌 greedy 방법이다. |
| `matlab/find_public_validation_cases.m` (주 함수) | `find_public_validation_cases` | 연결성·노드 차수 조건을 만족하는 끝점에서 4개 경로를 찾고 가장 짧은 경로를 기준, 나머지 3개를 후보로 구성한다. |
| `matlab/find_public_validation_cases.m` (로컬 함수) | `sample_pairs` | 가능한 끝점 쌍이 제한 이하이면 전부, 초과하면 중복 없이 난수 표집한다. |
| `matlab/find_public_validation_cases.m` (로컬 함수) | `cases_to_tables` | 사례 구조체를 사례 요약표 S와 경로별 상세표 R로 펼친다. |
| `matlab/find_public_validation_cases.m` (로컬 함수) | `route_row` | 단일 후보/기준 경로의 통계량을 내보내기용 한 행 구조체로 만든다. |
| `matlab/generate_public_figures.m` (주 함수) | `generate_public_figures` | 기존 설정으로 네트워크·보정진단·방법 성능·일치율/폭·사례별 trade-off·규모 민감도의 6개 figure를 생성한다. |
| `matlab/generate_public_figures.m` (로컬 함수) | `short_method_name` | figure 주석에 사용할 방법명을 원본의 짧은 표시명으로 변환한다. |
| `matlab/get_alias_value.m` (주 함수) | `get_alias_value` | 정규화한 별칭으로 구조체 필드를 찾고 값, 발견 여부, 실제 필드명을 반환한다. 단일 부분 일치도 허용한다. |
| `matlab/hash_file_sha256.m` (주 함수) | `hash_file_sha256` | Java MessageDigest로 파일을 읽어 SHA-256 16진 문자열을 만든다. |
| `matlab/infer_project_id.m` (주 함수) | `infer_project_id` | 속성의 프로젝트 필드 또는 파일명에서 프로젝트 ID를 추출하고 /를 _로 바꾼다. |
| `matlab/log_message.m` (주 함수) | `log_message` | 형식 문자열과 가변 인수로 메시지를 만들어 시각과 함께 콘솔 및 로그 파일에 기록한다. |
| `matlab/make_json_compatible.m` (주 함수) | `make_json_compatible` | table·struct·cell·string·datetime·categorical·함수 핸들을 재귀적으로 JSON 직렬화 가능한 값으로 변환한다. |
| `matlab/method_coefficients_public.m` (주 함수) | `method_coefficients_public` | a, b, Gamma에서 6개 방법의 가중치·형식분산·보고분산·정보집합을 구성한다. |
| `matlab/method_coefficients_public.m` (중첩 함수) | `add` | 부모 함수의 methods 구조체 배열에 방법 한 개를 추가하는 중첩 함수다. |
| `matlab/minimax_route_weights.m` (주 함수) | `minimax_route_weights` | a>0, b>=0, Gamma>=0인 대각 simplex 불확실성 집합의 구간별 닫힌형 minimax 가중치와 활성구간/목적함수 정보를 계산한다. |
| `matlab/normalize_field_name.m` (주 함수) | `normalize_field_name` | 별칭 비교용 필드명을 소문자화한 뒤 구두점을 제거한다. 통합판에서 원본의 대문자 손실 버그를 수정했다. |
| `matlab/open_ngs_project_pages.m` (주 함수) | `open_ngs_project_pages` | rootDir/data/config/ngs_projects.csv를 읽어 프로젝트 페이지를 연다. |
| `matlab/package_integrity_audit.m` (주 함수) | `package_integrity_audit` | 모듈의 정확한 파일 목록과 실제 MATLAB 함수 해석 경로를 검사하고 단위시험·Code Analyzer 결과를 JSON/TXT/CSV로 기록한다. |
| `matlab/package_integrity_audit.m` (로컬 함수) | `manifest_consistency` | 모듈 루트·matlab 폴더 파일을 manifest와 비교해 미등록 .m 파일과 중복 선언을 찾는다. |
| `matlab/package_integrity_audit.m` (로컬 함수) | `mismatch_text` | 파일명과 탐지한 함수명을 감사용 오류 설명으로 조합한다. |
| `matlab/package_integrity_audit.m` (로컬 함수) | `same_path` | 가능하면 Java canonical path를 얻어 두 경로가 같은지 비교한다. |
| `matlab/package_integrity_audit.m` (로컬 함수) | `run_code_analyzer` | manifest의 모든 .m 파일에 checkcode를 실행해 메시지와 치명적 구문 오류 수를 수집한다. |
| `matlab/package_integrity_audit.m` (로컬 함수) | `is_fatal_analyzer_message` | 진단 ID/메시지가 parse 또는 syntax 오류인지 판별한다. |
| `matlab/package_integrity_audit.m` (로컬 함수) | `write_function_inventory` | 존재 여부, 선언 함수명, which 해석 위치를 함수 inventory CSV로 쓴다. |
| `matlab/package_integrity_audit.m` (로컬 함수) | `format_report` | 구조화된 감사 결과를 사람이 읽는 텍스트 보고서로 만든다. |
| `matlab/paired_method_bootstrap.m` (주 함수) | `paired_method_bootstrap` | 사례별 centroid 대비 제곱오차·절대오차·구간폭 차이를 paired bootstrap으로 요약한다. |
| `matlab/paired_method_bootstrap.m` (로컬 함수) | `paired_case_diff` | 지정 사례 순서(bootstrap 중복 포함)에 맞춰 비교 방법과 centroid의 지표 차이를 반환한다. |
| `matlab/parse_leveling_files.m` (주 함수) | `parse_leveling_files` | ZIP 확장, benchmark 선행 파싱, 표·GeoJSON 관측 파싱, 정제 및 추적 보고서 생성을 통합한다. |
| `matlab/parse_leveling_files.m` (로컬 함수) | `empty_observation_table` | 표준 15개 관측 열을 가진 빈 table을 만든다. |
| `matlab/parse_ngs_benchmark_geojson.m` (주 함수) | `parse_ngs_benchmark_geojson` | NGS benchmark GeoJSON에서 프로젝트, SSN, PID, 위도·경도를 읽는다. |
| `matlab/parse_ngs_observation_geojson.m` (주 함수) | `parse_ngs_observation_geojson` | NGS 관측 GeoJSON을 표준 관측표로 바꾸고 SSN/PID 매핑과 단위·좌표를 처리한다. |
| `matlab/parse_ngs_observation_geojson.m` (로컬 함수) | `empty_table` | GeoJSON 파서에서 사용할 표준 15열 빈 관측 table을 만든다. |
| `matlab/parse_ngs_observation_geojson.m` (로컬 함수) | `numeric_column` | cell 또는 수치 열을 double 열벡터로 변환한다. |
| `matlab/parse_ngs_observation_geojson.m` (로컬 함수) | `map_ssn_to_pid` | benchmark의 projectID+SSN으로 PID를 찾고 없으면 projectID:SSN을 사용한다. |
| `matlab/parse_ngs_observation_geojson.m` (로컬 함수) | `lookup_coords` | 프로젝트 ID와 SSN에 대응하는 benchmark의 위도·경도를 조회한다. |
| `matlab/parse_ngs_observation_geojson.m` (로컬 함수) | `line_endpoints` | GeoJSON 좌표 배열에서 첫 점·마지막 점의 위경도와 해석 성공 여부를 반환한다. |
| `matlab/parse_tabular_observations.m` (주 함수) | `parse_tabular_observations` | CSV/TXT/XLSX/XLS 표의 열 별칭을 찾아 고저차·길이 단위를 표준화한 관측 table과 원행 수를 반환한다. |
| `matlab/parse_tabular_observations.m` (로컬 함수) | `find_alias_column` | 열 이름과 허용 별칭을 정규화해 첫 일치 열 인덱스를 찾는다. |
| `matlab/parse_tabular_observations.m` (로컬 함수) | `table_scalar` | table의 한 셀 값을 안전하게 읽고 단일 cell 포장을 해제한다. |
| `matlab/parse_tabular_observations.m` (로컬 함수) | `get_string_column` | 허용 별칭 열을 문자열 벡터로 읽고 없으면 빈 문자열로 채운다. |
| `matlab/parse_tabular_observations.m` (로컬 함수) | `get_numeric_column` | 허용 별칭 열을 수치 벡터로 읽고 없으면 NaN으로 채운다. |
| `matlab/public_scale_sensitivity.m` (주 함수) | `public_scale_sensitivity` | coherent 규모 배수를 바꾸며 minimax와 centroid의 경험적 오차·같은 집합 분산이득·가중치 차이를 평가한다. |
| `matlab/public_validation_config.m` (주 함수) | `public_validation_config` | quick/full/selftest의 경로, 표준단위, 경로추출, 분할, 모형, bootstrap, 기존 figure 설정을 구성한다. |
| `matlab/public_validation_unit_tests.m` (주 함수) | `public_validation_unit_tests` | 닫힌형 해, Gamma-b 등가성, NNLS, 선언 파서, 대문자·혼합 대소문자 필드 별칭, 단위변환, fixture 그래프/분할/평가 및 JSON 출력을 임시 디렉터리에서 검사한다. |
| `matlab/public_validation_unit_tests.m` (로컬 함수) | `cleanup_temp` | 시험 전용 임시 디렉터리를 정리한다. |
| `matlab/read_primary_function_name.m` (주 함수) | `read_primary_function_name` | 단일/다중 출력과 줄 연속 선언을 고려해 .m 파일의 첫 함수명을 읽는다. |
| `matlab/required_package_files.m` (주 함수) | `required_package_files` | 5개 진입점, 45개 지원 함수, 3개 자료 파일로 구성된 필수 manifest를 반환한다. |
| `matlab/resolve_input_files.m` (주 함수) | `resolve_input_files` | raw 폴더의 입력을 탐색하고 공개 입력/fixture 모드를 결정하며 원파일 SHA-256 manifest를 기록한다. |
| `matlab/robust_nnls2.m` (주 함수) | `robust_nnls2` | 두 비음수 계수의 가중 최소제곱을 Huber IRLS 안에서 반복해 규모 계수와 잔차·가중치·수렴 이력을 반환한다. |
| `matlab/robust_nnls2.m` (로컬 함수) | `nnls2_weighted` | 내부 2변수 비음수 최소제곱을 내부해·두 경계해·영해 후보 비교로 푼다. |
| `matlab/run_public_validation.m` (주 함수) | `run_public_validation` | 입력→파싱→경로 사례→훈련/시험 분할→보정/평가→figure·MAT·ZIP 저장의 전체 실행을 조정한다. 선택적인 pathOptions는 rawDir/runsDir만 허용하며 기존 모형·figure 설정을 바꾸지 않는다. |
| `matlab/run_public_validation.m` (로컬 함수) | `write_failure_report` | 실패 예외의 식별자, 메시지, 호출 스택을 실행 폴더에 기록한다. |
| `matlab/run_public_validation.m` (로컬 함수) | `write_key_results_summary` | 실행 규모, 추정 계수, 방법별 지표를 요약하고 fixture 사용 시 근거 제한을 명시한다. |
| `matlab/safe_mkdir.m` (주 함수) | `safe_mkdir` | 디렉터리가 없으면 생성하고 실패하면 오류를 발생시킨다. |
| `matlab/save_figure_bundle.m` (주 함수) | `save_figure_bundle` | 기존 색·해상도·벡터 설정으로 PNG/PDF/TIFF/FIG와 가독성 보고서를 저장한 뒤 해당 figure를 닫는다. |
| `matlab/simple_percentile.m` (주 함수) | `simple_percentile` | 유한 수치만 정렬하고 선형 보간으로 백분위수를 계산한다. Statistics Toolbox를 사용하지 않는다. |
| `matlab/split_public_cases.m` (주 함수) | `split_public_cases` | 고정 seed로 사례를 나누고 훈련/시험 및 각 집합 내 물리 간선 공유를 방지한다. |
| `matlab/split_public_cases.m` (로컬 함수) | `collect_case_rows` | 사례들의 전체 원본 간선 행 번호를 모아 중복을 제거한다. |
| `matlab/split_public_cases.m` (로컬 함수) | `local_case_tables` | 분할된 사례의 ID, 끝점, 경로 비공유 유형, 간선 수를 요약한다(R은 빈 table). |
| `matlab/summarize_method_table.m` (주 함수) | `summarize_method_table` | casewise 결과에서 방법별 RMSE, MAE, 중앙/95% 절대오차, 일치율, 평균 구간폭·보고분산을 집계한다. |
| `matlab/timestamp_string.m` (주 함수) | `timestamp_string` | 출력 폴더명에 사용할 UTC 밀리초 시각 문자열을 만든다(datetime 실패 시 datestr 사용). |
| `matlab/value_to_double.m` (주 함수) | `value_to_double` | 단일 값에서 첫 수치 표현을 double로 변환하고 실패 시 NaN을 반환한다. |
| `matlab/value_to_string.m` (주 함수) | `value_to_string` | JSON/table의 단일 값을 string으로 바꾸고 누락값을 빈 문자열로 처리한다. |
| `matlab/write_json_file.m` (주 함수) | `write_json_file` | 자료를 JSON 친화형으로 바꾼 뒤 가능하면 pretty-print로 UTF-8 파일을 쓴다. |
| `matlab/write_text_file.m` (주 함수) | `write_text_file` | 문자열을 UTF-8 텍스트 파일로 저장한다. |

### 8.3 GSVS17의 최상위 함수

| 파일 / 호출 형식 | 입력 | 출력·부수 효과 | 역할 |
|---|---|---|---|
| `RESULTS = gsvs17_min_validation(options)` | 선택적 구조체 `options.dataDir` (`.lvl` 폴더), `options.outDir` (저장 폴더). 생략 시 원본의 `pwd/GSVS17_LVL`, `pwd/results` 기본값 | 결과 구조체 `RESULTS`; `GSVS17_calibration_results.mat`; 그림 1–5의 `.fig`·`.png`; 콘솔 요약 | 원시 관측을 구간·왕복쌍으로 구성하고 M0/M1 분산모형, 경계 우도비, 프로파일, 부트스트랩, 동일일자 진단을 계산한다. 기존 스크립트의 `clear; close all; clc;`는 함수 어댑터에서 제거되었다. RNG는 원본 seed로 설정한다. |
| `ADD = gsvs17_addendum(options)` | 선택적 구조체 `options.matFile` (선행 검증 MAT), `options.outDir` (저장 폴더). 원본 기본값은 현재 폴더 아래 `results` | 결과 구조체 `ADD`; `GSVS17_addendum_results.mat`; 수정 버전 그림 1·3·4와 새 그림 6의 `.fig`·`.png` | 구간 길이 하한을 달리한 재적합, 거듭제곱 분산모형의 지수 프로파일, 분산성분 식별성 및 동일 표본수 구간 그림을 제공한다. 통합 실행기는 baseline MAT와 별도 출력 폴더를 연결하므로 앞 단계 그림을 보존한다. |
| `S = parse_gsvs17_lvl(dataDir)` | `.lvl` 파일을 직접 포함하는 폴더. 생략·빈 값이면 `pwd` | 구간 구조체 배열 `S`; 처리 파일·구간 수 출력 | 각 파일의 B/S/E 레코드를 읽는다. S 레코드에서 후시·전시 독취와 거리를 합산하여 구간 높이차, 길이, 설치 수, 시준거리 불균형을 다시 계산한다. 하위 폴더는 재귀 탐색하지 않는다. |
| `P = build_fb_pairs(S)` | 파싱된 비어 있지 않은 구간 구조체 배열 | 왕복쌍 구조체 배열 `P`; 쌍 수·길이·RMS 출력 | SSN 두 개를 순서 없이 묶고, 해당 묶음의 첫 관측과 첫 역방향 관측을 선택한다. `d_mm = 1000*(dH_f+dH_b)`를 계산한다. |
| `F = fit_variance_ml(d, L, n, useTau, fixed, opt)` | 왕복차 `d` [mm], 평균 구간 길이 `L` [km], 평균 설치 수 `n`; `useTau` 기본 true; 고정 분산성분 구조체 `fixed`; 최적화 옵션 `opt` | 적합 구조체 `F` | 평균 0인 정규모형의 `Var(d_i)=2*(sd2*L_i+ss2*n_i+tau2*L_i^2)`를 로그 분산 좌표에서 `fminsearch`로 적합한다. `useTau=false`이면 `tau2=0`. 표본은 4개 이상 필요하다. |
| `H = statlib_local()` | 없음 | `chi2sf`, `chi2inv`, `norminv`, `prctile` 함수 핸들을 가진 구조체 | Statistics Toolbox를 요구하지 않는 국소 통계 헬퍼를 반환한다. 실제 사용은 `H=statlib_local(); H.chi2sf(x,k)`와 같다. |
| `apply_font_size(figHandle, fs)` | 대상 Figure 핸들, 글꼴 크기 `fs` [pt]; 생략·빈 값이면 20 | 반환값 없음. 해당 그림의 글꼴 크기와 축 라벨·제목 배율 변경 | 축·눈금·라벨·제목·범례·colorbar·주석 등 글자 요소를 같은 크기로 맞춘다. 원본에서 모든 그림에 호출되는 기존 표현 설정이며 통합 과정에서 변경하지 않는다. |

#### 주요 구조체와 설정

`S`는 `file`, `dateStr`, `dateNum`, `runCode`, `obs`, `fromSSN`, `toSSN`, `fromDes`, `toDes`, `nSetups`, `distKm`, `dH_m`, `imb_m`과 누적 독취·거리·표준편차 필드를 포함한다. `sumB`, `sumF`는 독취 합, `sumBd`, `sumFd`는 시준거리 합이다. 파일명을 `YYMMDD<run letter>...` 형식으로 해석한다.

`P`는 `ssnA`, `ssnB`, `desA`, `desB`, `d_mm`, `L_km`, `nSetups`, `sameDay`, `gapDays`, `imbSum_m`, `nRunsTotal`, `idxF`, `idxB`를 포함한다. 길이와 설치 수는 두 관측의 평균이다. `nRunsTotal`은 해당 구간의 원래 관측 수이고, `idxF`·`idxB`는 `S`의 인덱스다. `ssnA`·`ssnB`는 정렬된 식별자이지만 원본의 `desA`·`desB`는 선택한 첫 관측의 방향 순서이므로 이름 대응에 주의한다.

`fixed`의 사용 가능한 필드는 `sd2`, `ss2`, `tau2`이며 표준편차가 아닌 **분산 단위**다. `opt.nStarts`의 기본값은 5이고 시작점 은행은 최대 5개다. `opt.theta0`는 자유모수의 로그 분산에 대한 추가 시작점이며 차원이 일치할 때만 사용한다. `opt.polish`의 기본값은 true이다. `nStarts=1`이더라도 `theta0`가 있으면 원본 구현에서는 두 시작점을 계산한다.

`F`는 `sd2`, `ss2`, `tau2`, `sigma_d`, `sigma_s`, `tau_r`, `theta`, `nll`, `v`, `vRun`, `z`, `nObs`, `nPar`, `aic`, `bic`, `useTau`, `fixed`, `converged`를 포함한다. `v`는 왕복차의 분산, `vRun=v/2`는 두 방향 독립·동일 분산 가정 아래 단일 관측 분산이다. `nll`·AIC·BIC에는 자료 공통 정규화 상수가 생략되어 있다.

원본 기본값은 `nBoot=2000`, `rngSeed=20260904`, `nBinsFig1=8`, `tauGrid=linspace(0.02,2.00,160)`, `ssGrid=linspace(0.00,0.40,121)`이다. addendum의 기본값은 `nBins=8`, `gamGrid=linspace(0.20,3.00,281)`, `subsets=[0,0.10,0.30,0.50,0.80]`이다. 거듭제곱 재적합은 별도로 0·0.30·0.50 km 세 하한을 사용한다.

### 8.4 GSVS17의 모든 내부 함수

| 소속 파일 | 함수 형식 | 입력 → 출력 | 역할 |
|---|---|---|---|
| `parse_gsvs17_lvl.m` | `s = emptySection()` | 없음 → 빈 구간 구조체 | 파서가 사용할 필드와 초기값을 정의한다. |
| `parse_gsvs17_lvl.m` | `[dateStr, runCode] = nameParts(fname)` | 파일명 → 날짜 문자열·방향 문자 | 7자 이상이면 처음 6자를 날짜, 7번째 문자를 run code로 가져온다. 짧으면 빈 문자열을 반환한다. |
| `parse_gsvs17_lvl.m` | `dn = str2dateNum(dateStr)` | YYMMDD 문자열 → MATLAB 일련 날짜 | 2000년대를 가정해 날짜를 변환한다. 길이·숫자 검사에 실패하면 NaN이다. 달력 범위를 엄격히 검증하는 함수는 아니다. |
| `build_fb_pairs.m` | `p = emptyPair()` | 없음 → 빈 왕복쌍 구조체 | 쌍 결과의 필드와 기본값을 정의한다. |
| `fit_variance_ml.m` | `nll = objective(theta)` — 중첩 함수 | 자유모수 로그 벡터 → 음의 로그우도 | 부모 함수의 관측·고정값을 사용한다. 비양수·비유한 적합분산이면 벌점 `1e12`를 반환한다. |
| `fit_variance_ml.m` | `[sd2_, ss2_, tau2_] = unpack(theta)` — 중첩 함수 | 로그 벡터 → 세 분산성분 | 자유모수에는 `exp(theta)+1e-12`, 고정모수에는 지정값을 적용한다. |
| `statlib_local.m` | `p = chi2sf(x, k)` | 검정값·자유도 → 상측 확률 | `gammainc`의 upper tail을 이용한다. 음수 검정값은 0으로 바꾼다. |
| `statlib_local.m` | `x = chi2inv(p, k)` | 확률 벡터·스칼라 자유도 → 분위수 열벡터 | `gammainc`를 200회 이내 이분법으로 역산한다. `p<=0`이면 0, `p>=1`이면 Inf이다. 입력 확률의 원래 행/열 모양은 보존하지 않는다. |
| `statlib_local.m` | `z = norminvL(p)` | 정규누적확률 → 표준정규 분위수 | `sqrt(2)*erfinv(2*p-1)`를 계산한다. 핸들 공개명은 `H.norminv`이다. |
| `statlib_local.m` | `q = prctileL(x, p)` | 자료 벡터·백분위수(0–100) → 분위수 | 비유한 자료 제거 후 순위 `p*n/100+0.5`에서 선형 보간한다. 자료가 없으면 NaN이다. 결과 모양은 `p`와 같다. 핸들 공개명은 `H.prctile`이다. |
| `gsvs17_min_validation.m` | `r = corrLocal(x, y)` | 두 벡터 → Pearson 상관계수 | 평균을 뺀 내적을 정규화한다. 결측값 제외나 상수 벡터에 대한 별도 처리는 없다. |
| `gsvs17_min_validation.m` | `s = ternary(cond, a, b)` | 논리값·두 후보 → 선택된 값 | 콘솔 요약의 조건부 문자열을 선택한다. |
| `gsvs17_addendum.m` | `[gHat, gCI, dev] = fit_powerlaw(d, L, grid)` | 왕복차·양수 길이·지수 격자 → 지수 MLE·95% 프로파일 구간·격자 deviance | `d~N(0,2*c*L^gamma)`를 적합한다. 정규성·평균 0·독립성 가정이 있는 모형이며 비모수 검정은 아니다. 구간은 격자 범위에서 deviance≤3.841458820694124인 점의 범위다. |
| `gsvs17_addendum.m` | `r = corrLocal(x, y)` | 두 벡터 → Pearson 상관계수 | 부트스트랩의 `sigma_d`와 `tau_r` 추정치 간 상관을 계산한다. 최소 검증 스크립트와 동일한 내부 구현이다. |

