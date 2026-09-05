> **원본 모듈의 역사적 문서 / Archived module documentation.** 통합 실행법과 현재 해석 범위는 패키지 최상위 README.md를 따릅니다. 아래 내용에는 원본 당시의 경로·강한 해석·과거 검증 상태가 포함됩니다.

# GSVS17 Minimum-Viable Validation — MATLAB package

논문 *"Conditional covariance-robust combination of redundant spirit-levelling routes"* 의
심사 지적 **M5(실측 자료 부재)** 를 해소하기 위한 코드입니다.

NGS GSVS17 (Colorado, 2017) 1등 2급 정밀수준측량 원시 자료로부터
논문 식 (31)의 계수를 **실측 추정**하고, 결맞음 성분 `b_p ∝ L²` 의 존재를 통계적으로 검정합니다.

권장 실행안의 **1~3단계만** 구현합니다 (4·5단계 제외).

---

## 1. 파일 구성

| 파일 | 역할 |
|---|---|
| `gsvs17_min_validation.m` | **메인 스크립트.** 1~3단계 실행 → `.mat` 저장 → figure 5개 생성 |
| `parse_gsvs17_lvl.m` | `*.lvl` 아카이브 파서 (구간 단위 추출) |
| `build_fb_pairs.m` | 왕복(forward/backward) 쌍 구성 및 폐합차 계산 |
| `fit_variance_ml.m` | 분산모형 최대우도 추정 (warm start·프로파일·부트스트랩 지원) |
| `statlib_local.m` | χ², 정규분포, 백분위수 — **툴박스 없이** 동작하는 헬퍼 |
| `apply_font_size.m` | 그림 내 모든 글자를 정확히 20 pt로 강제 |

**요구사항: base MATLAB만 필요합니다.** Statistics / Optimization / Curve Fitting 툴박스 불필요.
(`LabelFontSizeMultiplier`, `TitleFontSizeMultiplier`를 1로 되돌리므로 라벨·제목도 정확히 20 pt입니다.)

---

## 2. 실행 방법

```matlab
% 1) GSVS17_Leveling_LVLs-Corrected.zip 을 풀어서 ./GSVS17_LVL 에 둡니다
%    (*.lvl 파일 125개, *.err 파일은 사용하지 않습니다)

% 2) 경로 확인 후 실행
edit gsvs17_min_validation      % CFG.dataDir 을 필요하면 수정
gsvs17_min_validation
```

주요 설정은 스크립트 상단 `CFG` 블록에 모여 있습니다.

```matlab
CFG.dataDir  = fullfile(pwd,'GSVS17_LVL');   % *.lvl 위치
CFG.outDir   = fullfile(pwd,'results');
CFG.fontSize = 20;                            % 모든 figure 글꼴
CFG.nBoot    = 2000;                          % 부트스트랩 반복수
CFG.rngSeed  = 20260904;
```

소요시간 기준(참고): 파싱 수 초, 프로파일 우도 281점 + 부트스트랩 2000회 합쳐 수 분 정도입니다.
빠르게 확인하려면 `CFG.nBoot = 200` 으로 낮추십시오.

---

## 3. 방법론

### 3.1 자료 (1단계)

각 `*.lvl` 파일의 `B`(구간 시작) / `S`(기계설치) / `E`(구간 종료) 레코드를 파싱합니다.

- 구간 고저차 `dH = Σ(후시) − Σ(전시)`
- 누적 시준거리 `L = Σ(후시거리 + 전시거리)`
- 기계설치수 `n = S 레코드 개수`

**`E` 레코드에 적힌 값을 읽지 않고 `S` 레코드에서 재계산합니다.** 일부 `E` 레코드에 추가 필드가
붙어 고정 인덱싱이 깨지기 때문이며, 재계산값은 파싱 가능한 모든 구간에서 `E` 레코드와
1e-14 m 이내로 일치함을 확인했습니다.

같은 수준점 쌍을 양방향으로 관측한 경우 폐합차를 만듭니다.

```
d = (dH_forward + dH_backward) × 1000   [mm],    E[d] = 0
Var(d) = 2 · v(L, n)
```

### 3.2 분산모형 (2·3단계)

```
d_i ~ N(0, v_i),   v_i = 2·( σ_d²·L_i + σ_s²·n_i + τ_r²·L_i² )
                          └──────── a_i ────────┘  └─ b_i ─┘
```

논문의 `a_p = σ_d²L_p + σ_s²n_p`, `b_p = (τ_r L_p χ_p)²` (χ_p = 1) 과 동일한 구조입니다.

- **M0**: `τ_r² = 0` — 순수 랜덤 누적(분산이 L에 비례)
- **M1**: `τ_r² > 0` — 결맞음 노선 모드 추가(분산이 L²에 비례)

최대우도 추정은 각 분산성분의 **로그**에 대해 `fminsearch`로 수행합니다(비음수 자동 보장, 툴박스 불요).

검정·구간추정:

- `τ_r² = 0` 은 모수공간 **경계**이므로 우도비의 귀무분포는 `0.5·χ²₀ + 0.5·χ²₁` (Self & Liang 1987)
  → `p = 0.5·P(χ²₁ > LR)`
- τ_r의 95% 구간: **프로파일 우도**(deviance ≤ 3.8415) 및 **비모수 부트스트랩**(2000회)
- σ_s는 L과 n의 공선성 때문에 보통 식별되지 않으므로 **점추정 대신 95% 상한**을 보고합니다

### 3.3 반드시 함께 보고해야 할 해석상 한계

**왕복차는 두 관측에서 동일하게 재현되는 계통효과를 상쇄합니다.**
따라서 여기서 얻은 τ_r은 참 결맞음 성분의 **하한(lower bound)** 입니다.
논문의 b_p는 *상한* 척도로 정의되어 있으므로, 이 값은
"경험적으로 보증되는 최소 크기"로 인용해야 하며 b_p의 캘리브레이션 값으로 제시하면 안 됩니다.

또한 M1 추정치는 `Γ = 1` 정규화 하의 값입니다. 심사 지적 M1(Γ–b 혼입)대로
식별되는 것은 Γ가 아니라 **λ = Γ·κ_b** 이므로, 본문에도 그렇게 기술하십시오.

---

## 4. 출력물

### 4.1 `results/GSVS17_calibration_results.mat` (`-v7.3`)

`save(...,'-struct',...)` 로 저장되므로 `load` 시 아래가 **최상위 변수**로 들어옵니다.

| 변수 | 내용 |
|---|---|
| `config` | 실행 설정 전체(경로, 시드, 논문 가정계수 포함) |
| `sections` | 파싱된 전 구간 (562개) — 파일, 날짜, SSN, L, n, dH, 시준 불균형 |
| `pairs` | 왕복 쌍 (274개) — d, L, n, 동일일자 여부, 일수 간격 |
| `data` | 회귀에 쓰인 벡터 `d_mm`, `L_km`, `nSetups`, `sameDay`, `gapDays` |
| `descriptives` | 기술통계 (총연장, rms 폐합차, 설치밀도, corr(L,n) 등) |
| `M0`, `M1` | 두 모형의 적합 결과 (분산성분, nll, 적합분산, 정규화잔차 z, AIC/BIC) |
| `LRT` | 우도비 통계량, 경계 p값, ΔAIC, ΔBIC |
| `profile` | τ_r·σ_s 프로파일 격자, deviance, 95% 구간 |
| `bootstrap` | 2000회 복원추출 결과와 백분위 구간 |
| `derived` | a(1km), b(1km), b/a, **교차길이 L\***, 논문 가정과의 비율, q(L) 곡선 |
| `commonMode` | 동일일자 대 상이일자 분산비 F 검정 (등부하 성분 ν 진단) |
| `binned` | 길이 구간별 경험분산과 χ² 신뢰구간 (그림 1 원자료) |

### 4.2 그림 (`.fig` + 300 dpi `.png`, 모든 글꼴 20 pt)

| 파일 | 내용 |
|---|---|
| `fig1_variance_vs_length` | **핵심 그림.** log–log 축에서 단일관측 분산 `d²/2` 대 L. 개별 쌍 + 구간평균(95% CI) + M0/M1 적합선 + 논문 가정선. 순수 랜덤이면 기울기 1의 직선이어야 함 |
| `fig2_tau_inference` | τ_r 프로파일 우도(좌) 및 부트스트랩 분포(우), 논문 가정 0.60 mm/km 표시 |
| `fig3_model_diagnostics` | 정규화잔차 QQ 플롯(좌), 길이구간별 `mean(z²)`(우) — M0의 길이 의존 편향과 M1의 개선 |
| `fig4_variance_decomposition` | a(L)·b(L) 분해와 **교차길이 L\***(좌), 논문의 정렬량 `q(L)=a/√b`(우) |
| `fig5_common_mode_check` | 동일일자/상이일자 \|z\| 경험 CDF — 등부하 공통성분 ν의 존재 진단 |

---

## 5. 기대 출력값 (검증용)

첨부하신 `GSVS17_Leveling_LVLsCorrected.zip` 으로 **동일 알고리즘을 Python으로 독립 구현해
미리 돌려본 결과**입니다. MATLAB 실행 결과가 아래와 (수치 최적화 오차 범위에서) 일치해야 합니다.

```
sections = 562,  usable F/B pairs = 274,  total single-run length = 370.19 km
set-up density = 12.34 /km,  corr(L, n) = 0.500
rms closure discrepancy = 1.9205 mm  (1.5795 mm/sqrt(km))

M0 :  sigma_d = 1.1168 mm/sqrt(km)   sigma_s = 0.0000     -logL = 286.4648
M1 :  sigma_d = 0.5915 mm/sqrt(km)   sigma_s = 0.0000
      tau_r   = 0.8166 mm/km                              -logL = 280.5925

LR = 11.7447,  p (boundary) = 3.05e-04,  AIC(M0)-AIC(M1) = +9.74
profile 95% CI  tau_r   : [0.568, 0.991] mm/km
profile 95% CI  sigma_s : [0.000, 0.090] mm/set-up        (상한만 유효)
bootstrap (B=2000) tau_r: median 0.815, CI [0.539, 1.024] mm/km
                          tau_r ~ 0 인 복제 비율 0.1 %

a(1 km) = 0.3499 mm^2     b(1 km) = 0.6668 mm^2     b/a = 1.91
crossover length L* = 0.525 km
  (논문 가정계수로는 a=0.1798, b=0.3600, L* = 0.499 km)

common-mode : var(z) same-day 0.9359 (n=185) vs different-day 0.9420 (n=89)
              F = 1.0065,  p = 0.955
```

부트스트랩은 시드와 난수 생성기가 언어별로 다르므로 MATLAB에서는 중앙값·구간이
소수 셋째 자리 수준에서 달라질 수 있습니다. ML 추정치·LR 통계량·프로파일 구간은 일치해야 합니다.

---

## 6. 결과가 논문에 의미하는 것

1. **결맞음 L² 성분은 데이터가 요구합니다.** LR = 11.74, p = 3.1e-4.
   저차원 노선 모드 가정이 "모형 선택"이 아니라 **실측으로 뒷받침되는 구조**가 됩니다 (M5 해소).

2. **논문이 가정한 τ_r = 0.60 mm/km 는 경험적 95% 구간 [0.57, 0.99] 안에 있습니다.**
   즉 Table 3의 b_p 값은 자의적이지 않으며, 오히려 **보수적**입니다(실측 0.82 mm/km).

3. **σ_s는 식별되지 않습니다.** 95% 상한 0.090 mm/set-up.
   논문의 0.04 mm/set-up 은 이 상한과 모순되지 않지만, "추정된 값"으로 서술해서는 안 됩니다.

4. **교차길이 L\* ≈ 0.52 km.** 이보다 긴 노선에서 결맞음 성분이 랜덤 성분을 넘어섭니다.
   심사 지적 **M6("이 방법이 유용한 조건이 무엇인가")** 에 대한 정량적 답이 됩니다:
   *0.5 km 이상, 특히 수 km 급 험준지형 노선에서 이 방법의 전제가 성립한다.*

5. **등부하 공통성분 ν의 증거는 없습니다** (F = 1.01, p = 0.96).
   정직한 부정 결과이며, 논문에서 ν 관련 서술을 압축하라는 세부지적 5번과도 맞습니다.

6. σ_d 실측 0.59 mm/√km 는 논문 가정 0.40 보다 약 1.5배 큽니다.
   험준지형(Colorado) 특성이므로, Table 3을 실측값으로 교체하면서 이 점을 명시하십시오.

---

## 7. 자료 출처 및 라이선스

- **GSVS17 raw levelling**: <https://www.ngs.noaa.gov/GEOID/GSVS17/raw-field-data.shtml>
  (`GSVS17_Leveling_LVLs-Corrected.zip`) — 미국 연방정부 저작물, **퍼블릭 도메인**
- 조사 개요: <https://geodesy.noaa.gov/GEOID/GSVS/>
- 동반 논문: van Westrum, D., et al. (2021). *A Geoid Slope Validation Survey (2017)
  in the rugged terrain of Colorado, USA.* Journal of Geodesy, 95, 9.
  <https://doi.org/10.1007/s00190-020-01463-8>

인용 예시(논문 Data availability 절):

> The levelling observations used for the stochastic calibration are the raw digital
> levelling records of the NGS Geoid Slope Validation Survey 2017 (GSVS17), Colorado, USA,
> distributed by the U.S. National Geodetic Survey in the public domain
> (GSVS17_Leveling_LVLs-Corrected.zip; van Westrum et al. 2021).

---

## 8. 알려진 제한

- 왕복차 기반이므로 τ_r은 하한입니다 (§3.3).
- GSVS17은 **단일 노선**이므로 중복 노선(P ≥ 2)의 실제 결합 시연은 불가능합니다.
  그 단계는 NGS Leveling Projects의 재측 자료 또는 환 분할이 필요하며, 이 패키지 범위 밖입니다.
- 3개 쌍은 관측이 3~4회 존재하나, 현재는 첫 번째 정·역 조합만 사용합니다
  (`pairs.nRunsTotal` 에 총 관측수가 기록되어 있으니 필요하면 확장하십시오).
- 코드는 Octave 설치가 불가능한 환경에서 작성되어 **MATLAB에서 직접 실행 검증되지 않았습니다.**
  대신 동일 알고리즘을 Python으로 구현해 이 데이터로 전 과정을 검증했고(§5),
  결과가 다르면 알려 주시면 바로 수정하겠습니다.
