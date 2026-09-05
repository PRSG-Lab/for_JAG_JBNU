# 공개 수준측량 검증 모듈 함수 설명

v2.2.0에 통합판의 입출력 경로 확장 및 필드명 파서 수정을 적용한 MATLAB 파일 50개, 함수 선언 82개를 모두 포함합니다. 루트 5개 진입점과 `matlab/`의 45개 주 함수가 있으며, 나머지는 소유 파일 안에서만 호출되는 로컬·중첩 함수입니다.

통합 패키지에서 이 문서의 파일 경로는 공개검증 모듈 내부를 기준으로 합니다. `cfg`는 `public_validation_config`가 만드는 설정 구조체, `runDir`은 한 실행의 저장 폴더, `logFile`은 로그 경로입니다. `E/T`는 table, `cases/trainCases/testCases`는 경로 사례 struct 배열이며 `calibration/validation`은 해당 단계의 결과 구조체입니다. 함수별 정확한 인수/반환 이름은 아래 시그니처에 표시했습니다. `~` 없이 출력이 없는 함수는 저장·로그·화면 동작을 수행합니다.

공개검증 실행에서 고저차 단위는 m, 길이는 km, 분산은 m²입니다. 계수 계산 함수는 일관된 분산 단위를 사용해야 합니다.

## `RUN_OFFLINE_SELFTEST.m`

### `RUN_OFFLINE_SELFTEST` — 진입점

```matlab
PublicValidationRunInfo = RUN_OFFLINE_SELFTEST()
```

무결성 감사를 거쳐 합성 fixture로 전체 절차를 실행한다. 공개자료 실증 결과가 아닌 코드 흐름 점검이다.

- 입력: `없음`
- 출력: `PublicValidationRunInfo`

## `RUN_OPEN_NGS_PROJECT_PAGES.m`

### `RUN_OPEN_NGS_PROJECT_PAGES` — 진입점

```matlab
RUN_OPEN_NGS_PROJECT_PAGES()
```

프로젝트 manifest의 NOAA NGS 웹페이지를 기본 브라우저로 연다. 관측 파일을 자동 다운로드하지 않는다.

- 입력: `없음`
- 출력: `없음`

## `RUN_PACKAGE_AUDIT.m`

### `RUN_PACKAGE_AUDIT` — 진입점

```matlab
AuditReport = RUN_PACKAGE_AUDIT()
```

파일 구성, 함수명·경로 해석, MATLAB Code Analyzer, 오프라인 단위시험을 검사한다.

- 입력: `없음`
- 출력: `AuditReport`

## `RUN_PUBLIC_FULL.m`

### `RUN_PUBLIC_FULL` — 진입점

```matlab
PublicValidationRunInfo = RUN_PUBLIC_FULL()
```

감사 후 공개 NGS 자료만으로 전체 검증을 실행한다. 원자료가 없으면 중단한다.

- 입력: `없음`
- 출력: `PublicValidationRunInfo`

## `RUN_PUBLIC_QUICK.m`

### `RUN_PUBLIC_QUICK` — 진입점

```matlab
PublicValidationRunInfo = RUN_PUBLIC_QUICK()
```

감사 후 축소 규모 검증을 실행한다. 공개 입력이 없을 때만 fixture로 대체하고 OFFLINE_FIXTURE로 표시한다.

- 입력: `없음`
- 출력: `PublicValidationRunInfo`

## `matlab/build_network.m`

### `build_network` — 주 함수

```matlab
net = build_network(E)
```

정제 관측 E로 길이를 가중치로 하는 무방향 graph를 만들고 원본 행과 노드 좌표를 연결한다.

- 입력: `E`
- 출력: `net`

## `matlab/calibrate_public_covariance.m`

### `calibrate_public_covariance` — 주 함수

```matlab
calibration = calibrate_public_covariance(trainCases,cfg,runDir,logFile)
```

훈련 경로의 제곱 불일치로 명목·유효 coherent 규모를 비음수 Huber IRLS로 적합하고 사례 단위 bootstrap 및 CSV를 생성한다.

- 입력: `trainCases,cfg,runDir,logFile`
- 출력: `calibration`

### `calibration_rows` — 로컬 함수

```matlab
[X,y,w,caseID]=calibration_rows(cases)
```

후보 경로와 기준 경로의 차이를 제곱해 2열 설계행렬 X, 반응 y, 사례 내 가중치 w, caseID를 만든다.

- 입력: `cases`
- 출력: `[X,y,w,caseID]`

## `matlab/canonicalize_station_pairs.m`

### `canonicalize_station_pairs` — 주 함수

```matlab
[node1,node2,signMultiplier] = canonicalize_station_pairs(fromID,toID)
```

양 끝점 ID를 사전 순서로 정렬하고 방향이 뒤집혔는지 나타내는 부호를 반환한다.

- 입력: `fromID,toID`
- 출력: `[node1,node2,signMultiplier]`

## `matlab/clean_and_collapse_observations.m`

### `clean_and_collapse_observations` — 주 함수

```matlab
[E,report] = clean_and_collapse_observations(T,cfg)
```

잘못된 관측을 제거하고 동일 물리 구간을 공통 방향으로 합쳐 평균 고저차, 대표 길이, 반복관측 통계를 계산한다.

- 입력: `T,cfg`
- 출력: `[E,report]`

### `first_nonempty` — 로컬 함수

```matlab
s=first_nonempty(x)
```

문자열 벡터에서 첫 번째 비어 있지 않은 항목을 반환한다.

- 입력: `x`
- 출력: `s`

### `coords_for_node` — 로컬 함수

```matlab
[lat,lon]=coords_for_node(T,idx,node)
```

선택된 관측 행에서 지정 노드의 유효 위도·경도를 찾는다.

- 입력: `T,idx,node`
- 출력: `[lat,lon]`

## `matlab/compute_path_statistics.m`

### `compute_path_statistics` — 주 함수

```matlab
st = compute_path_statistics(net,path)
```

경로 방향을 반영한 고저차 Y, 길이 합 기반 A, coherent 노출 대용값 B, 원본 행·노드·프로젝트 정보를 계산한다.

- 입력: `net,path`
- 출력: `st`

## `matlab/convert_height_to_m.m`

### `convert_height_to_m` — 주 함수

```matlab
x = convert_height_to_m(value,unit)
```

높이 단위를 m로 변환한다(mm, cm, m, ft). 알 수 없는 단위에는 경고하고 m로 간주한다.

- 입력: `value,unit`
- 출력: `x`

## `matlab/convert_length_to_km.m`

### `convert_length_to_km` — 주 함수

```matlab
x = convert_length_to_km(value,unit)
```

길이 단위를 km로 변환한다(mm, cm, m, km, mi, ft). 알 수 없는 단위에는 경고하고 km로 간주한다.

- 입력: `value,unit`
- 출력: `x`

## `matlab/evaluate_public_methods.m`

### `evaluate_public_methods` — 주 함수

```matlab
validation = evaluate_public_methods(testCases,calibration,cfg,runDir,logFile)
```

검증 사례에서 여섯 경로 결합 규칙의 추정치·기준경로 불일치·보고분산·일치율을 계산하고 bootstrap/민감도 결과를 저장한다.

- 입력: `testCases,calibration,cfg,runDir,logFile`
- 출력: `validation`

## `matlab/figure_readability_audit.m`

### `figure_readability_audit` — 주 함수

```matlab
report = figure_readability_audit(fig,filePath,cfg)
```

축 글꼴, 레이블, 선 개수, 범례 개수를 검사해 보고서를 기록한다. figure 속성은 수정하지 않는다.

- 입력: `fig,filePath,cfg`
- 출력: `report`

## `matlab/find_disjoint_paths.m`

### `find_disjoint_paths` — 주 함수

```matlab
paths = find_disjoint_paths(net,terminalA,terminalB,k,mode,maxPathEdges)
```

양 끝점을 연결하는 양의 길이 최단경로를 순차 선택·제거하여 노드 또는 간선 비공유 경로 k개를 찾는다. 완전탐색이 아닌 greedy 방법이다.

- 입력: `net,terminalA,terminalB,k,mode,maxPathEdges`
- 출력: `paths`

## `matlab/find_public_validation_cases.m`

### `find_public_validation_cases` — 주 함수

```matlab
[cases,caseSummary,routeDetails] = find_public_validation_cases(E,cfg,runDir,logFile)
```

연결성·노드 차수 조건을 만족하는 끝점에서 4개 경로를 찾고 가장 짧은 경로를 기준, 나머지 3개를 후보로 구성한다.

- 입력: `E,cfg,runDir,logFile`
- 출력: `[cases,caseSummary,routeDetails]`

### `sample_pairs` — 로컬 함수

```matlab
pc=sample_pairs(idx,maxPairs)
```

가능한 끝점 쌍이 제한 이하이면 전부, 초과하면 중복 없이 난수 표집한다.

- 입력: `idx,maxPairs`
- 출력: `pc`

### `cases_to_tables` — 로컬 함수

```matlab
[S,R]=cases_to_tables(cases)
```

사례 구조체를 사례 요약표 S와 경로별 상세표 R로 펼친다.

- 입력: `cases`
- 출력: `[S,R]`

### `route_row` — 로컬 함수

```matlab
r=route_row(caseID,role,j,s)
```

단일 후보/기준 경로의 통계량을 내보내기용 한 행 구조체로 만든다.

- 입력: `caseID,role,j,s`
- 출력: `r`

## `matlab/generate_public_figures.m`

### `generate_public_figures` — 주 함수

```matlab
figIndex = generate_public_figures(E,cases,trainCases,testCases,calibration,validation,cfg,runDir,logFile)
```

기존 설정으로 네트워크·보정진단·방법 성능·일치율/폭·사례별 trade-off·규모 민감도의 6개 figure를 생성한다.

- 입력: `E,cases,trainCases,testCases,calibration,validation,cfg,runDir,logFile`
- 출력: `figIndex`

### `short_method_name` — 로컬 함수

```matlab
s=short_method_name(x)
```

figure 주석에 사용할 방법명을 원본의 짧은 표시명으로 변환한다.

- 입력: `x`
- 출력: `s`

## `matlab/get_alias_value.m`

### `get_alias_value` — 주 함수

```matlab
[value,found,fieldUsed] = get_alias_value(S,aliases)
```

정규화한 별칭으로 구조체 필드를 찾고 값, 발견 여부, 실제 필드명을 반환한다. 단일 부분 일치도 허용한다.

- 입력: `S,aliases`
- 출력: `[value,found,fieldUsed]`

## `matlab/hash_file_sha256.m`

### `hash_file_sha256` — 주 함수

```matlab
hex = hash_file_sha256(filePath)
```

Java MessageDigest로 파일을 읽어 SHA-256 16진 문자열을 만든다.

- 입력: `filePath`
- 출력: `hex`

## `matlab/infer_project_id.m`

### `infer_project_id` — 주 함수

```matlab
projectID = infer_project_id(filePath,properties)
```

속성의 프로젝트 필드 또는 파일명에서 프로젝트 ID를 추출하고 /를 _로 바꾼다.

- 입력: `filePath,properties`
- 출력: `projectID`

## `matlab/log_message.m`

### `log_message` — 주 함수

```matlab
log_message(logFile,fmt,varargin)
```

형식 문자열과 가변 인수로 메시지를 만들어 시각과 함께 콘솔 및 로그 파일에 기록한다.

- 입력: `logFile,fmt,varargin`
- 출력: `없음`

## `matlab/make_json_compatible.m`

### `make_json_compatible` — 주 함수

```matlab
out = make_json_compatible(value)
```

table·struct·cell·string·datetime·categorical·함수 핸들을 재귀적으로 JSON 직렬화 가능한 값으로 변환한다.

- 입력: `value`
- 출력: `out`

## `matlab/method_coefficients_public.m`

### `method_coefficients_public` — 주 함수

```matlab
methods = method_coefficients_public(a,b,Gamma)
```

a, b, Gamma에서 6개 방법의 가중치·형식분산·보고분산·정보집합을 구성한다.

- 입력: `a,b,Gamma`
- 출력: `methods`

### `add` — 중첩 함수

```matlab
add(name,w,formal,robust,info)
```

부모 함수의 methods 구조체 배열에 방법 한 개를 추가하는 중첩 함수다.

- 입력: `name,w,formal,robust,info`
- 출력: `없음`

## `matlab/minimax_route_weights.m`

### `minimax_route_weights` — 주 함수

```matlab
[w,info] = minimax_route_weights(a,b,Gamma)
```

a>0, b>=0, Gamma>=0인 대각 simplex 불확실성 집합의 구간별 닫힌형 minimax 가중치와 활성구간/목적함수 정보를 계산한다.

- 입력: `a,b,Gamma`
- 출력: `[w,info]`

## `matlab/normalize_field_name.m`

### `normalize_field_name` — 주 함수

```matlab
s = normalize_field_name(value)
```

별칭 비교용 필드명을 소문자화한 뒤 구두점을 제거한다. 통합판에서 원본의 대문자 손실 버그를 수정했다.

- 입력: `value`
- 출력: `s`

## `matlab/open_ngs_project_pages.m`

### `open_ngs_project_pages` — 주 함수

```matlab
open_ngs_project_pages(rootDir)
```

rootDir/data/config/ngs_projects.csv를 읽어 프로젝트 페이지를 연다.

- 입력: `rootDir`
- 출력: `없음`

## `matlab/package_integrity_audit.m`

### `package_integrity_audit` — 주 함수

```matlab
report = package_integrity_audit(rootDir,throwOnFailure)
```

모듈의 정확한 파일 목록과 실제 MATLAB 함수 해석 경로를 검사하고 단위시험·Code Analyzer 결과를 JSON/TXT/CSV로 기록한다.

- 입력: `rootDir,throwOnFailure`
- 출력: `report`

### `manifest_consistency` — 로컬 함수

```matlab
[unexpected,duplicates]=manifest_consistency(rootDir,matlabDir,manifest)
```

모듈 루트·matlab 폴더 파일을 manifest와 비교해 미등록 .m 파일과 중복 선언을 찾는다.

- 입력: `rootDir,matlabDir,manifest`
- 출력: `[unexpected,duplicates]`

### `mismatch_text` — 로컬 함수

```matlab
text=mismatch_text(fileName,actual)
```

파일명과 탐지한 함수명을 감사용 오류 설명으로 조합한다.

- 입력: `fileName,actual`
- 출력: `text`

### `same_path` — 로컬 함수

```matlab
tf=same_path(a,b)
```

가능하면 Java canonical path를 얻어 두 경로가 같은지 비교한다.

- 입력: `a,b`
- 출력: `tf`

### `run_code_analyzer` — 로컬 함수

```matlab
analyzer=run_code_analyzer(rootDir,manifest)
```

manifest의 모든 .m 파일에 checkcode를 실행해 메시지와 치명적 구문 오류 수를 수집한다.

- 입력: `rootDir,manifest`
- 출력: `analyzer`

### `is_fatal_analyzer_message` — 로컬 함수

```matlab
tf=is_fatal_analyzer_message(identifier,message)
```

진단 ID/메시지가 parse 또는 syntax 오류인지 판별한다.

- 입력: `identifier,message`
- 출력: `tf`

### `write_function_inventory` — 로컬 함수

```matlab
write_function_inventory(rootDir,manifest)
```

존재 여부, 선언 함수명, which 해석 위치를 함수 inventory CSV로 쓴다.

- 입력: `rootDir,manifest`
- 출력: `없음`

### `format_report` — 로컬 함수

```matlab
txt=format_report(r)
```

구조화된 감사 결과를 사람이 읽는 텍스트 보고서로 만든다.

- 입력: `r`
- 출력: `txt`

## `matlab/paired_method_bootstrap.m`

### `paired_method_bootstrap` — 주 함수

```matlab
Btab = paired_method_bootstrap(T,cfg)
```

사례별 centroid 대비 제곱오차·절대오차·구간폭 차이를 paired bootstrap으로 요약한다.

- 입력: `T,cfg`
- 출력: `Btab`

### `paired_case_diff` — 로컬 함수

```matlab
d=paired_case_diff(T,caseIDs,method,base,metric)
```

지정 사례 순서(bootstrap 중복 포함)에 맞춰 비교 방법과 centroid의 지표 차이를 반환한다.

- 입력: `T,caseIDs,method,base,metric`
- 출력: `d`

## `matlab/parse_leveling_files.m`

### `parse_leveling_files` — 주 함수

```matlab
[obs,parseReport] = parse_leveling_files(source,cfg,runDir,logFile)
```

ZIP 확장, benchmark 선행 파싱, 표·GeoJSON 관측 파싱, 정제 및 추적 보고서 생성을 통합한다.

- 입력: `source,cfg,runDir,logFile`
- 출력: `[obs,parseReport]`

### `empty_observation_table` — 로컬 함수

```matlab
T=empty_observation_table()
```

표준 15개 관측 열을 가진 빈 table을 만든다.

- 입력: `없음`
- 출력: `T`

## `matlab/parse_ngs_benchmark_geojson.m`

### `parse_ngs_benchmark_geojson` — 주 함수

```matlab
T = parse_ngs_benchmark_geojson(filePath)
```

NGS benchmark GeoJSON에서 프로젝트, SSN, PID, 위도·경도를 읽는다.

- 입력: `filePath`
- 출력: `T`

## `matlab/parse_ngs_observation_geojson.m`

### `parse_ngs_observation_geojson` — 주 함수

```matlab
[T,rowsRead] = parse_ngs_observation_geojson(filePath,bench,cfg)
```

NGS 관측 GeoJSON을 표준 관측표로 바꾸고 SSN/PID 매핑과 단위·좌표를 처리한다.

- 입력: `filePath,bench,cfg`
- 출력: `[T,rowsRead]`

### `empty_table` — 로컬 함수

```matlab
T=empty_table()
```

GeoJSON 파서에서 사용할 표준 15열 빈 관측 table을 만든다.

- 입력: `없음`
- 출력: `T`

### `numeric_column` — 로컬 함수

```matlab
x=numeric_column(v)
```

cell 또는 수치 열을 double 열벡터로 변환한다.

- 입력: `v`
- 출력: `x`

### `map_ssn_to_pid` — 로컬 함수

```matlab
id=map_ssn_to_pid(projectID,ssn,bench)
```

benchmark의 projectID+SSN으로 PID를 찾고 없으면 projectID:SSN을 사용한다.

- 입력: `projectID,ssn,bench`
- 출력: `id`

### `lookup_coords` — 로컬 함수

```matlab
[lat,lon]=lookup_coords(projectID,ssn,bench)
```

프로젝트 ID와 SSN에 대응하는 benchmark의 위도·경도를 조회한다.

- 입력: `projectID,ssn,bench`
- 출력: `[lat,lon]`

### `line_endpoints` — 로컬 함수

```matlab
[lat1,lon1,lat2,lon2,ok]=line_endpoints(c)
```

GeoJSON 좌표 배열에서 첫 점·마지막 점의 위경도와 해석 성공 여부를 반환한다.

- 입력: `c`
- 출력: `[lat1,lon1,lat2,lon2,ok]`

## `matlab/parse_tabular_observations.m`

### `parse_tabular_observations` — 주 함수

```matlab
[T,rowsRead] = parse_tabular_observations(filePath,cfg)
```

CSV/TXT/XLSX/XLS 표의 열 별칭을 찾아 고저차·길이 단위를 표준화한 관측 table과 원행 수를 반환한다.

- 입력: `filePath,cfg`
- 출력: `[T,rowsRead]`

### `find_alias_column` — 로컬 함수

```matlab
idx=find_alias_column(names,aliases)
```

열 이름과 허용 별칭을 정규화해 첫 일치 열 인덱스를 찾는다.

- 입력: `names,aliases`
- 출력: `idx`

### `table_scalar` — 로컬 함수

```matlab
v=table_scalar(R,r,c)
```

table의 한 셀 값을 안전하게 읽고 단일 cell 포장을 해제한다.

- 입력: `R,r,c`
- 출력: `v`

### `get_string_column` — 로컬 함수

```matlab
s=get_string_column(R,names,aliases,n)
```

허용 별칭 열을 문자열 벡터로 읽고 없으면 빈 문자열로 채운다.

- 입력: `R,names,aliases,n`
- 출력: `s`

### `get_numeric_column` — 로컬 함수

```matlab
x=get_numeric_column(R,names,aliases,n)
```

허용 별칭 열을 수치 벡터로 읽고 없으면 NaN으로 채운다.

- 입력: `R,names,aliases,n`
- 출력: `x`

## `matlab/public_scale_sensitivity.m`

### `public_scale_sensitivity` — 주 함수

```matlab
S = public_scale_sensitivity(cases,calibration,cfg)
```

coherent 규모 배수를 바꾸며 minimax와 centroid의 경험적 오차·같은 집합 분산이득·가중치 차이를 평가한다.

- 입력: `cases,calibration,cfg`
- 출력: `S`

## `matlab/public_validation_config.m`

### `public_validation_config` — 주 함수

```matlab
cfg = public_validation_config(mode,rootDir)
```

quick/full/selftest의 경로, 표준단위, 경로추출, 분할, 모형, bootstrap, 기존 figure 설정을 구성한다.

- 입력: `mode,rootDir`
- 출력: `cfg`

## `matlab/public_validation_unit_tests.m`

### `public_validation_unit_tests` — 주 함수

```matlab
report = public_validation_unit_tests(rootDir)
```

닫힌형 해, Gamma-b 등가성, NNLS, 선언 파서, 대문자·혼합 대소문자 필드 별칭, 단위변환, fixture 그래프/분할/평가 및 JSON 출력을 임시 디렉터리에서 검사한다.

- 입력: `rootDir`
- 출력: `report`

### `cleanup_temp` — 로컬 함수

```matlab
cleanup_temp(pathName)
```

시험 전용 임시 디렉터리를 정리한다.

- 입력: `pathName`
- 출력: `없음`

## `matlab/read_primary_function_name.m`

### `read_primary_function_name` — 주 함수

```matlab
name = read_primary_function_name(filePath)
```

단일/다중 출력과 줄 연속 선언을 고려해 .m 파일의 첫 함수명을 읽는다.

- 입력: `filePath`
- 출력: `name`

## `matlab/required_package_files.m`

### `required_package_files` — 주 함수

```matlab
manifest = required_package_files()
```

5개 진입점, 45개 지원 함수, 3개 자료 파일로 구성된 필수 manifest를 반환한다.

- 입력: `없음`
- 출력: `manifest`

## `matlab/resolve_input_files.m`

### `resolve_input_files` — 주 함수

```matlab
source = resolve_input_files(cfg,runDir,logFile)
```

raw 폴더의 입력을 탐색하고 공개 입력/fixture 모드를 결정하며 원파일 SHA-256 manifest를 기록한다.

- 입력: `cfg,runDir,logFile`
- 출력: `source`

## `matlab/robust_nnls2.m`

### `robust_nnls2` — 주 함수

```matlab
fit = robust_nnls2(X,y,baseWeights,cfg)
```

두 비음수 계수의 가중 최소제곱을 Huber IRLS 안에서 반복해 규모 계수와 잔차·가중치·수렴 이력을 반환한다.

- 입력: `X,y,baseWeights,cfg`
- 출력: `fit`

### `nnls2_weighted` — 로컬 함수

```matlab
beta=nnls2_weighted(X,y,w)
```

내부 2변수 비음수 최소제곱을 내부해·두 경계해·영해 후보 비교로 푼다.

- 입력: `X,y,w`
- 출력: `beta`

## `matlab/run_public_validation.m`

### `run_public_validation` — 주 함수

```matlab
runInfo = run_public_validation(mode,rootDir,pathOptions)
```

입력→파싱→경로 사례→훈련/시험 분할→보정/평가→figure·MAT·ZIP 저장의 전체 실행을 조정한다. 선택적인 pathOptions는 rawDir/runsDir만 허용하며 기존 모형·figure 설정을 바꾸지 않는다.

- 입력: `mode,rootDir,pathOptions`
- 출력: `runInfo`

### `write_failure_report` — 로컬 함수

```matlab
write_failure_report(runDir,ME)
```

실패 예외의 식별자, 메시지, 호출 스택을 실행 폴더에 기록한다.

- 입력: `runDir,ME`
- 출력: `없음`

### `write_key_results_summary` — 로컬 함수

```matlab
write_key_results_summary(runDir,runInfo,validation,calibration,cfg)
```

실행 규모, 추정 계수, 방법별 지표를 요약하고 fixture 사용 시 근거 제한을 명시한다.

- 입력: `runDir,runInfo,validation,calibration,cfg`
- 출력: `없음`

## `matlab/safe_mkdir.m`

### `safe_mkdir` — 주 함수

```matlab
safe_mkdir(pathName)
```

디렉터리가 없으면 생성하고 실패하면 오류를 발생시킨다.

- 입력: `pathName`
- 출력: `없음`

## `matlab/save_figure_bundle.m`

### `save_figure_bundle` — 주 함수

```matlab
save_figure_bundle(fig,basePath,cfg)
```

기존 색·해상도·벡터 설정으로 PNG/PDF/TIFF/FIG와 가독성 보고서를 저장한 뒤 해당 figure를 닫는다.

- 입력: `fig,basePath,cfg`
- 출력: `없음`

## `matlab/simple_percentile.m`

### `simple_percentile` — 주 함수

```matlab
q = simple_percentile(x,p)
```

유한 수치만 정렬하고 선형 보간으로 백분위수를 계산한다. Statistics Toolbox를 사용하지 않는다.

- 입력: `x,p`
- 출력: `q`

## `matlab/split_public_cases.m`

### `split_public_cases` — 주 함수

```matlab
[trainCases,testCases,splitReport] = split_public_cases(cases,cfg,runDir,logFile)
```

고정 seed로 사례를 나누고 훈련/시험 및 각 집합 내 물리 간선 공유를 방지한다.

- 입력: `cases,cfg,runDir,logFile`
- 출력: `[trainCases,testCases,splitReport]`

### `collect_case_rows` — 로컬 함수

```matlab
rows=collect_case_rows(cases)
```

사례들의 전체 원본 간선 행 번호를 모아 중복을 제거한다.

- 입력: `cases`
- 출력: `rows`

### `local_case_tables` — 로컬 함수

```matlab
[S,R]=local_case_tables(cases)
```

분할된 사례의 ID, 끝점, 경로 비공유 유형, 간선 수를 요약한다(R은 빈 table).

- 입력: `cases`
- 출력: `[S,R]`

## `matlab/summarize_method_table.m`

### `summarize_method_table` — 주 함수

```matlab
S = summarize_method_table(T)
```

casewise 결과에서 방법별 RMSE, MAE, 중앙/95% 절대오차, 일치율, 평균 구간폭·보고분산을 집계한다.

- 입력: `T`
- 출력: `S`

## `matlab/timestamp_string.m`

### `timestamp_string` — 주 함수

```matlab
s = timestamp_string()
```

출력 폴더명에 사용할 UTC 밀리초 시각 문자열을 만든다(datetime 실패 시 datestr 사용).

- 입력: `없음`
- 출력: `s`

## `matlab/value_to_double.m`

### `value_to_double` — 주 함수

```matlab
x = value_to_double(v)
```

단일 값에서 첫 수치 표현을 double로 변환하고 실패 시 NaN을 반환한다.

- 입력: `v`
- 출력: `x`

## `matlab/value_to_string.m`

### `value_to_string` — 주 함수

```matlab
s = value_to_string(v)
```

JSON/table의 단일 값을 string으로 바꾸고 누락값을 빈 문자열로 처리한다.

- 입력: `v`
- 출력: `s`

## `matlab/write_json_file.m`

### `write_json_file` — 주 함수

```matlab
write_json_file(filePath,value)
```

자료를 JSON 친화형으로 바꾼 뒤 가능하면 pretty-print로 UTF-8 파일을 쓴다.

- 입력: `filePath,value`
- 출력: `없음`

## `matlab/write_text_file.m`

### `write_text_file` — 주 함수

```matlab
write_text_file(filePath,textValue)
```

문자열을 UTF-8 텍스트 파일로 저장한다.

- 입력: `filePath,textValue`
- 출력: `없음`
