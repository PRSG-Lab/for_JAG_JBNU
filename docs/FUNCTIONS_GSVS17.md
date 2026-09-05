# GSVS17 모듈 함수 설명

이 문서는 제공된 `gsvs17_matlab.zip`의 소스 코드와 통합 어댑터 설계에 근거한다. 원본의 실행 스크립트 두 개는 통합 모듈에서 설정을 전달받고 결과를 반환하는 함수로 바뀌었다. MATLAB 파일 7개에 최상위 함수 7개와 파일 내부 함수 14개가 있다. 내부 함수는 해당 파일에서만 사용하는 구현 요소다. 원본 ZIP은 provenance 자료로 보존된다.

## 실행 흐름

`*.lvl → parse_gsvs17_lvl → build_fb_pairs → gsvs17_min_validation → GSVS17_calibration_results.mat → gsvs17_addendum → GSVS17_addendum_results.mat`

두 분석 단계는 `fit_variance_ml`, `statlib_local`, `apply_font_size`를 공통으로 사용한다. 최소 검증 단계에서 그림 5개를 만들고, addendum 단계에서 그림 1·3·4를 재생성하며 그림 6을 추가한다. 통합 실행기는 baseline과 addendum 결과를 별도 폴더에 보존한다. 최종 그림 모음은 addendum의 1·3·4·6번과 baseline의 2·5번으로 구성된다.

## 외부에서 실행하는 파일

| 파일 / 호출 형식 | 입력 | 출력·부수 효과 | 역할 |
|---|---|---|---|
| `RESULTS = gsvs17_min_validation(options)` | 선택적 구조체 `options.dataDir` (`.lvl` 폴더), `options.outDir` (저장 폴더). 생략 시 원본의 `pwd/GSVS17_LVL`, `pwd/results` 기본값 | 결과 구조체 `RESULTS`; `GSVS17_calibration_results.mat`; 그림 1–5의 `.fig`·`.png`; 콘솔 요약 | 원시 관측을 구간·왕복쌍으로 구성하고 M0/M1 분산모형, 경계 우도비, 프로파일, 부트스트랩, 동일일자 진단을 계산한다. 기존 스크립트의 `clear; close all; clc;`는 함수 어댑터에서 제거되었다. RNG는 원본 seed로 설정한다. |
| `ADD = gsvs17_addendum(options)` | 선택적 구조체 `options.matFile` (선행 검증 MAT), `options.outDir` (저장 폴더). 원본 기본값은 현재 폴더 아래 `results` | 결과 구조체 `ADD`; `GSVS17_addendum_results.mat`; 수정 버전 그림 1·3·4와 새 그림 6의 `.fig`·`.png` | 구간 길이 하한을 달리한 재적합, 거듭제곱 분산모형의 지수 프로파일, 분산성분 식별성 및 동일 표본수 구간 그림을 제공한다. 통합 실행기는 baseline MAT와 별도 출력 폴더를 연결하므로 앞 단계 그림을 보존한다. |
| `S = parse_gsvs17_lvl(dataDir)` | `.lvl` 파일을 직접 포함하는 폴더. 생략·빈 값이면 `pwd` | 구간 구조체 배열 `S`; 처리 파일·구간 수 출력 | 각 파일의 B/S/E 레코드를 읽는다. S 레코드에서 후시·전시 독취와 거리를 합산하여 구간 높이차, 길이, 설치 수, 시준거리 불균형을 다시 계산한다. 하위 폴더는 재귀 탐색하지 않는다. |
| `P = build_fb_pairs(S)` | 파싱된 비어 있지 않은 구간 구조체 배열 | 왕복쌍 구조체 배열 `P`; 쌍 수·길이·RMS 출력 | SSN 두 개를 순서 없이 묶고, 해당 묶음의 첫 관측과 첫 역방향 관측을 선택한다. `d_mm = 1000*(dH_f+dH_b)`를 계산한다. |
| `F = fit_variance_ml(d, L, n, useTau, fixed, opt)` | 왕복차 `d` [mm], 평균 구간 길이 `L` [km], 평균 설치 수 `n`; `useTau` 기본 true; 고정 분산성분 구조체 `fixed`; 최적화 옵션 `opt` | 적합 구조체 `F` | 평균 0인 정규모형의 `Var(d_i)=2*(sd2*L_i+ss2*n_i+tau2*L_i^2)`를 로그 분산 좌표에서 `fminsearch`로 적합한다. `useTau=false`이면 `tau2=0`. 표본은 4개 이상 필요하다. |
| `H = statlib_local()` | 없음 | `chi2sf`, `chi2inv`, `norminv`, `prctile` 함수 핸들을 가진 구조체 | Statistics Toolbox를 요구하지 않는 국소 통계 헬퍼를 반환한다. 실제 사용은 `H=statlib_local(); H.chi2sf(x,k)`와 같다. |
| `apply_font_size(figHandle, fs)` | 대상 Figure 핸들, 글꼴 크기 `fs` [pt]; 생략·빈 값이면 20 | 반환값 없음. 해당 그림의 글꼴 크기와 축 라벨·제목 배율 변경 | 축·눈금·라벨·제목·범례·colorbar·주석 등 글자 요소를 같은 크기로 맞춘다. 원본에서 모든 그림에 호출되는 기존 표현 설정이며 통합 과정에서 변경하지 않는다. |

### 주요 구조체와 설정

`S`는 `file`, `dateStr`, `dateNum`, `runCode`, `obs`, `fromSSN`, `toSSN`, `fromDes`, `toDes`, `nSetups`, `distKm`, `dH_m`, `imb_m`과 누적 독취·거리·표준편차 필드를 포함한다. `sumB`, `sumF`는 독취 합, `sumBd`, `sumFd`는 시준거리 합이다. 파일명을 `YYMMDD<run letter>...` 형식으로 해석한다.

`P`는 `ssnA`, `ssnB`, `desA`, `desB`, `d_mm`, `L_km`, `nSetups`, `sameDay`, `gapDays`, `imbSum_m`, `nRunsTotal`, `idxF`, `idxB`를 포함한다. 길이와 설치 수는 두 관측의 평균이다. `nRunsTotal`은 해당 구간의 원래 관측 수이고, `idxF`·`idxB`는 `S`의 인덱스다. `ssnA`·`ssnB`는 정렬된 식별자이지만 원본의 `desA`·`desB`는 선택한 첫 관측의 방향 순서이므로 이름 대응에 주의한다.

`fixed`의 사용 가능한 필드는 `sd2`, `ss2`, `tau2`이며 표준편차가 아닌 **분산 단위**다. `opt.nStarts`의 기본값은 5이고 시작점 은행은 최대 5개다. `opt.theta0`는 자유모수의 로그 분산에 대한 추가 시작점이며 차원이 일치할 때만 사용한다. `opt.polish`의 기본값은 true이다. `nStarts=1`이더라도 `theta0`가 있으면 원본 구현에서는 두 시작점을 계산한다.

`F`는 `sd2`, `ss2`, `tau2`, `sigma_d`, `sigma_s`, `tau_r`, `theta`, `nll`, `v`, `vRun`, `z`, `nObs`, `nPar`, `aic`, `bic`, `useTau`, `fixed`, `converged`를 포함한다. `v`는 왕복차의 분산, `vRun=v/2`는 두 방향 독립·동일 분산 가정 아래 단일 관측 분산이다. `nll`·AIC·BIC에는 자료 공통 정규화 상수가 생략되어 있다.

원본 기본값은 `nBoot=2000`, `rngSeed=20260904`, `nBinsFig1=8`, `tauGrid=linspace(0.02,2.00,160)`, `ssGrid=linspace(0.00,0.40,121)`이다. addendum의 기본값은 `nBins=8`, `gamGrid=linspace(0.20,3.00,281)`, `subsets=[0,0.10,0.30,0.50,0.80]`이다. 거듭제곱 재적합은 별도로 0·0.30·0.50 km 세 하한을 사용한다.

## 파일 내부 함수 전체

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

## 저장 결과 읽기

두 MAT 파일은 `save(...,'-struct',...,'-v7.3')`로 저장되므로 `R=load(matFile)` 후 `R.M1`, `R.data`처럼 접근한다. 별도의 `R.RESULTS` 또는 `R.ADD` 계층이 생기지 않는다.

통합 함수의 반환 구조체 `RESULTS`·`ADD`에는 저장 파일과 같은 분석 필드가 들어 있다. 경로 주입과 호출 방식만 바뀌었으며, 수치 계산·기본 설정·그림 블록 및 헬퍼 구현은 유지된다.

최소 검증 결과의 최상위 변수는 `createdOn`, `matlabVersion`, `config`, `sections`, `pairs`, `data`, `descriptives`, `M0`, `M1`, `LRT`, `profile`, `bootstrap`, `derived`, `commonMode`, `binned`이다. addendum 결과에는 `createdOn`, `config`, `subsets`, `powerlaw`, `identifiability`, `binnedEqualCount`가 저장된다.

## 해석 범위

이 모듈은 GSVS17 **구간 왕복차의 반복성**을 분석한다. 평균 0·정규성·방향 간 독립 등의 가정에 따른 길이 의존 분산모형 적합을 route-wide coherence, 경로별 상한 또는 결합 공분산 시나리오 집합의 직접 검증으로 해석하지 않는다. 기존 README와 콘솔의 일부 강한 문장은 원본 분석 당시의 설명이며, 현재 논문에 그대로 인용할 근거로 보아서는 안 된다.
