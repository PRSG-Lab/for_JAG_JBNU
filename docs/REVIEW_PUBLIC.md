# 공개 수준측량 검증 패키지 검토

검토 대상은 제공된 `SurveyReview_public_leveling_validation_v2_2`이며, 외부 기억이나 다른 연구 버전의 결론을 사용하지 않았다. 아래는 소스·동봉 자료 정적 검토 결과다. MATLAB 실행의 최종 통과 여부는 통합 패키지의 실행 검증 보고서를 따른다.

## 구조와 실행 경로

- 원본은 MATLAB `.m` 50개: 루트 진입점 5개, `matlab/` 지원 파일 45개이며 로컬·중첩 함수를 합하면 함수 선언은 82개다.
- `public_validation_config` → `resolve_input_files` → `parse_leveling_files` → `find_public_validation_cases` → `split_public_cases` → `calibrate_public_covariance` → `evaluate_public_methods` → `generate_public_figures` 순으로 실행한다.
- `RUN_PACKAGE_AUDIT` 및 각 원본 진입점은 모듈 루트의 정확한 5개 진입점과 `matlab/`의 정확한 45개 파일을 요구한다. 이 폴더에 새 래퍼를 추가하면 미등록 MATLAB 파일로 감사에 실패한다. 상위 통합 폴더에 새 진입점을 두고 모듈 구조를 유지하는 방식이 적합하다.
- 원본 함수는 `mfilename('fullpath')`로 모듈 루트를 찾아 절대경로 의존성을 피한다. `cfg.matlabDir`은 설정 이후 실행 계산에 사용되지 않는다. 원본 `package_integrity_audit`는 모듈 루트 기준으로 호출해야 한다.
- 통합판 선택 인수 `run_public_validation(mode,rootDir,pathOptions)`는 `rawDir`과 `runsDir`만 덮어쓴다. fixture, project manifest, 소스 코드는 모듈 루트에 두고 원자료와 결과 폴더만 분리할 수 있다. plot 및 분석 기본값은 그대로다.
- 원본 진입점과 감사 함수의 `addpath`는 MATLAB path를 바꾼다. 통합 래퍼는 호출 전 path를 저장하고 종료 시 복원하는 것이 적절하다.

## 동봉 데이터와 실행 모드

| 항목 | 실제 상태와 의미 |
|---|---|
| `data/example/offline_fixture_observations.csv` | 288행의 합성 fixture. 공개 실측 증거로 사용할 수 없다. |
| `data/raw/ngs/` | 안내 README만 있으며 공개 관측·benchmark 원자료가 없다. |
| `data/config/ngs_projects.csv` | NOAA 프로젝트 페이지 5개와 권장 파일명 목록. 관측·benchmark 직접 다운로드 URL 필드는 비어 있다. |
| `quick` | 공개 입력이 있으면 축소 규모로 실행. 입력이 없을 때만 fixture로 fallback한다. |
| `selftest` | 공개 파일 존재 여부와 관계없이 fixture를 강제 사용한다. |
| `full` | 공개 입력 없으면 실패한다. 원자료가 있더라도 4개 비공유 경로와 충분한 훈련/시험 사례를 찾지 못하면 실패할 수 있다. |
| 출처 판정 | `isPublic=true`는 raw 폴더에 허용 확장자 파일이 있었다는 뜻이며 NOAA 출처를 인증하는 검증은 아니다. 공급자가 출처와 다운로드 기록을 보존해야 한다. |

공개 원자료는 최소한 관측의 시작점·종료점·고저차·길이를 제공해야 한다. NGS GeoJSON은 관측 파일과 benchmark 파일을 함께 두어 SSN을 프로젝트 간 공통 PID로 연결하는 편이 적절하다. 고저차 기본값은 m, 길이 기본값은 km다. 단위 메타데이터를 확인하고 누락 시 명시적으로 표준화해야 한다.

## 보존한 figure 설정

`public_validation_config.m`, `generate_public_figures.m`, `save_figure_bundle.m`, `figure_readability_audit.m`의 원본을 그대로 사용한다. 기본값은 PNG 300 dpi, TIFF 600 dpi, font size 10, line width 1.5, marker size 6, invisible figure이며, figure별 창 크기·색·축·범례·마커·선·표현식도 유지한다. 출력은 그림당 PNG/PDF/TIF/FIG와 가독성 보고서다. 통합 래퍼는 figure 스타일을 통일하거나 재설정하면 안 된다.

## 적용한 최소 수정

| 파일 | 근거 | 통합판 변경 |
|---|---|---|
| `normalize_field_name.m` | 원본은 `[^a-z0-9]` 정규식으로 대문자를 지운 후 소문자화하여 `FROM_SSN`이 빈 문자열, `FromSSN`이 `rom`이 된다. 같은 대소문자 표준 fixture는 통과할 수 있어 숨어 있던 결함이다. | 소문자화한 뒤 구두점을 제거한다. 분석 모형과 figure는 변경하지 않는다. |
| `public_validation_unit_tests.m` | 원본 시험은 표준 fixture와 단위 변환은 확인하지만 필드명 case 변형을 확인하지 않는다. | uppercase/mixedcase 정규화·별칭 lookup 4개 회귀검사를 추가한다. |
| `run_public_validation.m` | 통합 패키지에서 자료/결과를 공통 구조에 배치하려면 경로 선택이 필요하다. | 선택적인 `pathOptions`를 추가한다. 허용 필드는 `rawDir`,`runsDir`뿐이며 모형·plot 설정은 허용하지 않는다. 기존 1·2인수 호출은 유지된다. |

## 변경하지 않은 분석상 한계와 사용 시 확인 사항

1. **경로 탐색은 greedy이다.** 순차 최단경로 제거 방식이므로 비공유 경로가 실제로 존재하더라도 찾지 못할 수 있다. “사례 없음”은 경로 존재에 대한 수학적 불가능성 증명이 아니다.
2. **간선 비공유와 통계적 독립은 다르다.** 훈련/시험 및 각 집합 내 사례의 물리 간선 중복을 제거하지만, 동일 장비·프로젝트·시기·지역 공통 오차가 남을 수 있다. “independent”를 간선 비공유 설계의 의미로 제한해야 한다.
3. **참조 경로는 참값이 아니다.** 출력 RMSE/MAE는 별도 기준 경로와의 불일치다. `Consistency95`는 기준 경로와의 일치율이며 알려진 참값에 대한 coverage로 바꾸어 해석하지 않는다.
4. **보고 구간은 적합 계수의 플러그인 결과다.** 보정 bootstrap은 계수 불확실성을 요약하지만 해당 불확실성을 각 검증 구간에 추가 전파하지 않는다. 보정 규모를 추정했다는 사실만으로 엄밀한 95% coverage가 보장되지 않는다.
5. **최소 실증 사례 수 설정이 자동 집행되지는 않는다.** `minimumPublicCasesForManuscript=20`, `minimumPublicTestCasesForManuscript=10`, `minimumUsableCases=8`는 설정에 존재하지만 실행 중 검사에 사용되지 않는다. 실제 강제 조건은 훈련 4개·시험 3개 및 간선 비공유다. 실행 완료만으로 논문용 표본 규모를 충족했다고 해석하면 안 된다.
6. **허용되지 않는 비표준 설정이 있다.** `collapseParallelPhysicalEdges=false`이면 정제 함수의 조기 반환 결과에 `BaseVarianceProxy`가 생성되지 않아 후속 경로 통계가 실패할 수 있다. 기본값 true를 유지한다. 통합 경로 옵션은 이 값을 바꾸지 않는다.
7. **단위의 자동 추정은 보수적이지 않다.** 모르는 높이/거리 단위에 경고한 뒤 m/km를 가정한다. 입력 단위를 직접 확인한다. `convert_height_to_m`의 일반 문자열 매칭은 임의 단위를 모두 구분하는 파서가 아니다.
8. **동일 물리 구간의 반복값은 평균으로 합쳐진다.** 길이 기반 분산 대용값은 반복수만큼 자동 축소되지 않는다. 혼합 프로젝트 자료의 반복관측을 별도 관측으로 활용하는 일반 망 조정기가 아니다.
9. **미세한 수치 규모에서는 노출의 영 판정에 주의한다.** `minimax_route_weights`는 `b<=eps(max(1,max(b)))`를 영 노출로 취급한다. 현재 연구의 단위를 유지하고 극단적으로 작은 다른 단위로 변환하여 쓰지 않는 편이 좋다.
10. **공통 바닥 분산은 이 자료로 추정하지 않는다.** `commonFloor` 기본 0은 한 번의 archival network snapshot으로 식별되지 않는다는 가정이며, 경로 coherence나 covariance hull 자체를 경험적으로 증명하는 절차가 아니다.

## 의존성과 검증 범위

- 기본 MATLAB의 `table`, `string`, `graph`, `readtable`, `jsonencode/jsondecode`, `exportgraphics` 또는 `print`, `savefig`를 사용한다. Java 기반 SHA-256 때문에 `-nojvm` 실행은 지원하지 않는다.
- 공개 모듈은 Statistics and Machine Learning Toolbox의 `prctile`, Optimization Toolbox의 `lsqnonneg`, Mapping Toolbox에 의존하지 않도록 자체 백분위수·2변수 NNLS를 제공한다.
- `VariableNamingRule` 및 현대 figure export API를 사용하므로 통합 README의 검증된 MATLAB 버전을 우선한다. 모든 MATLAB 버전에 대한 호환성을 주장하지 않는다. GNU Octave의 table/graph/string 호환성을 검증하지 않았다.
- 기존 `audit/V2_1_RUNTIME_FAILURE_REPORT.*`는 v2.1의 함수 선언 파서 오탐 이력이다. `RUNTIME_AUDIT_STATUS.txt`는 v2.2가 당시 빌드 환경에서 MATLAB으로 실행되지 않았음을 명시한다. 원본 정적 보고서와 통합판의 새 runtime 증거를 구별한다.

개별 함수의 시그니처·입력·출력·역할은 `PUBLIC_FUNCTIONS_KO.md`의 82개 항목을 참조한다.
