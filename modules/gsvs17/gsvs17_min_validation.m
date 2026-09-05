function RESULTS = gsvs17_min_validation(options)
%GSVS17_MIN_VALIDATION  Minimum-viable empirical validation of the route-total
%                       variance model using NGS GSVS17 levelling data.
%
%   Purpose
%   -------
%   The manuscript "Conditional covariance-robust combination of redundant
%   spirit-levelling routes" assumes a route-total variance of the form
%
%       Var(route total)  =  a_p  +  b_p * xi_p ,
%       a_p = sigma_d^2 * L_p + sigma_s^2 * n_p          (random accumulation)
%       b_p = ( tau_r * L_p * chi_p )^2                  (route-coherent mode)
%
%   with the illustrative coefficients sigma_d = 0.40 mm/sqrt(km),
%   sigma_s = 0.04 mm/set-up and tau_r = 0.60 mm/km.  Those values were chosen
%   as order-of-magnitude illustrations, not estimated from data.  This script
%   estimates them from real first-order levelling and tests whether the
%   coherent L^2 term is required at all.
%
%   Steps implemented (steps 1-3 of the minimum-viable validation)
%     1  Parse the GSVS17 *.lvl archive into sections; extract for each section
%        the accumulated distance L, the number of set-ups n and the observed
%        height difference dH.  Form forward/backward pairs and their closure
%        discrepancies d.
%     2  Estimate sigma_d^2 and sigma_s^2 by maximum likelihood under the pure
%        random-accumulation model (M0).
%     3  Add the coherent term tau_r^2 * L^2 (M1), test tau_r^2 = 0 by a
%        boundary likelihood-ratio test, and bound tau_r by profile likelihood
%        and by a nonparametric bootstrap.  This yields the empirical scale of
%        b_p that the manuscript currently assumes without evidence.
%
%   Outputs
%     <outDir>/GSVS17_calibration_results.mat   every intermediate and result
%     <outDir>/fig1_variance_vs_length.(fig|png)
%     <outDir>/fig2_tau_inference.(fig|png)
%     <outDir>/fig3_model_diagnostics.(fig|png)
%     <outDir>/fig4_variance_decomposition.(fig|png)
%     <outDir>/fig5_common_mode_check.(fig|png)
%
%   Requirements
%     Base MATLAB only.  No Statistics, Optimization or Curve Fitting toolbox.
%
%   Data
%     GSVS17_Leveling_LVLs-Corrected.zip, unzipped into DATADIR.
%     https://www.ngs.noaa.gov/GEOID/GSVS17/raw-field-data.shtml
%     US Federal Government work - public domain.
%
%   ---------------------------------------------------------------------

% Unified adapter: isolate workspace and preserve existing open figures.
if nargin < 1, options = struct(); end

%% ======================= 0.  CONFIGURATION ============================

CFG = struct();
CFG.dataDir   = fullfile(pwd, 'GSVS17_LVL');   % folder holding the *.lvl files
CFG.outDir    = fullfile(pwd, 'results');
CFG.fontSize  = 20;                            % <-- every figure font is 20 pt
CFG.nBoot     = 2000;                          % bootstrap replications
CFG.rngSeed   = 20260904;
CFG.nBinsFig1 = 8;                             % length bins for figure 1
CFG.tauGrid   = linspace(0.02, 2.00, 160);     % mm/km, profile grid for tau_r
CFG.ssGrid    = linspace(0.00, 0.40, 121);     % mm/set-up, profile grid
CFG.figFormat = '-dpng';
CFG.figDPI    = '-r300';

% Coefficients assumed in the manuscript (Section 4.1), for comparison only.
CFG.paper = struct('sigma_d', 0.40, ...   % mm / sqrt(km)
                   'sigma_s', 0.04, ...   % mm / set-up
                   'tau_r',   0.60);      % mm / km

CFG = jag.gsvs_options(CFG, options, 'calibration');

if ~exist(CFG.outDir, 'dir'), mkdir(CFG.outDir); end
rng(CFG.rngSeed);
ST = statlib_local();

fprintf('\n=====================================================\n');
fprintf(' GSVS17 minimum-viable validation\n');
fprintf('=====================================================\n\n');


%% ======================= 1.  PARSE AND PAIR ===========================

fprintf('--- Step 1: parse sections and form forward/backward pairs ---\n');

sections = parse_gsvs17_lvl(CFG.dataDir);
pairs    = build_fb_pairs(sections);

d = [pairs.d_mm]';        % closure discrepancy            [mm]
L = [pairs.L_km]';        % mean accumulated distance      [km]
n = [pairs.nSetups]';     % mean number of set-ups         [-]
sameDay = [pairs.sameDay]';
gapDays = [pairs.gapDays]';

DESC = struct();
DESC.nSections    = numel(sections);
DESC.nPairs       = numel(pairs);
DESC.totalLength  = sum(L);
DESC.L_min        = min(L);
DESC.L_med        = median(L);
DESC.L_max        = max(L);
DESC.n_min        = min(n);
DESC.n_med        = median(n);
DESC.n_max        = max(n);
DESC.rms_d        = sqrt(mean(d.^2));
DESC.max_abs_d    = max(abs(d));
DESC.rms_d_norm   = sqrt(mean(d.^2 ./ L));    % mm / sqrt(km)
DESC.setupDensity = median(n ./ L);           % set-ups per km
DESC.corr_L_n     = corrLocal(L, n);
DESC.nSameDay     = sum(sameDay);
DESC.nDiffDay     = sum(~sameDay);

fprintf('  sections                 : %d\n',            DESC.nSections);
fprintf('  usable F/B pairs         : %d\n',            DESC.nPairs);
fprintf('  single-run length        : %.2f km total, %.4f - %.3f km\n', ...
        DESC.totalLength, DESC.L_min, DESC.L_max);
fprintf('  set-ups per section      : %g - %g (median %g)\n', ...
        DESC.n_min, DESC.n_max, DESC.n_med);
fprintf('  set-up density           : %.2f per km\n',   DESC.setupDensity);
fprintf('  corr(L, n)               : %.4f\n',          DESC.corr_L_n);
fprintf('  rms closure discrepancy  : %.4f mm  (%.4f mm/sqrt(km))\n', ...
        DESC.rms_d, DESC.rms_d_norm);
fprintf('  max |discrepancy|        : %.4f mm\n',       DESC.max_abs_d);
fprintf('  same-day / different-day : %d / %d\n\n',     DESC.nSameDay, DESC.nDiffDay);


%% =============== 2.  M0 - RANDOM ACCUMULATION ONLY ====================

fprintf('--- Step 2: ML fit of the random-accumulation model (M0) ---\n');

M0 = fit_variance_ml(d, L, n, false);

fprintf('  sigma_d = %.4f mm/sqrt(km)   (manuscript assumes %.2f)\n', ...
        M0.sigma_d, CFG.paper.sigma_d);
fprintf('  sigma_s = %.4f mm/set-up     (manuscript assumes %.2f)\n', ...
        M0.sigma_s, CFG.paper.sigma_s);
fprintf('  -logL   = %.4f\n\n', M0.nll);


%% =============== 3.  M1 - ADD THE COHERENT L^2 TERM ===================

fprintf('--- Step 3: ML fit with the route-coherent term (M1) ---\n');

M1 = fit_variance_ml(d, L, n, true);

fprintf('  sigma_d = %.4f mm/sqrt(km)\n', M1.sigma_d);
fprintf('  sigma_s = %.4f mm/set-up\n',   M1.sigma_s);
fprintf('  tau_r   = %.4f mm/km          (manuscript assumes %.2f)\n', ...
        M1.tau_r, CFG.paper.tau_r);
fprintf('  -logL   = %.4f\n', M1.nll);

% ---- 3a  boundary likelihood-ratio test for tau_r^2 = 0 -----------------
% Under H0 the parameter lies on the boundary of the parameter space, so the
% asymptotic null distribution is the 50:50 mixture 0.5*chi2_0 + 0.5*chi2_1
% (Self & Liang 1987), giving p = 0.5 * P(chi2_1 > LR).
LRT       = struct();
LRT.stat  = 2 * (M0.nll - M1.nll);
LRT.pBoundary = 0.5 * ST.chi2sf(max(LRT.stat, 0), 1);
LRT.pNaive    =       ST.chi2sf(max(LRT.stat, 0), 1);
LRT.dAIC      = M0.aic - M1.aic;
LRT.dBIC      = M0.bic - M1.bic;

fprintf('  LR statistic  = %.4f\n', LRT.stat);
fprintf('  p (boundary)  = %.3e   [reject tau_r = 0 if small]\n', LRT.pBoundary);
fprintf('  AIC(M0)-AIC(M1) = %+.2f,  BIC(M0)-BIC(M1) = %+.2f\n\n', ...
        LRT.dAIC, LRT.dBIC);

% ---- 3b  profile likelihood for tau_r -----------------------------------
fprintf('  profiling tau_r over %d grid points ...\n', numel(CFG.tauGrid));
warmOpt = struct('nStarts', 2, 'polish', true);
PROF = struct();
PROF.tauGrid = CFG.tauGrid(:);
PROF.tauNll  = nan(size(PROF.tauGrid));
theta_warm   = [];
for k = 1:numel(PROF.tauGrid)
    wo = warmOpt; wo.theta0 = theta_warm;
    Fk = fit_variance_ml(d, L, n, true, struct('tau2', PROF.tauGrid(k)^2), wo);
    PROF.tauNll(k) = Fk.nll;
    theta_warm     = Fk.theta;      % warm start the next grid point
end
PROF.tauDev = 2 * (PROF.tauNll - M1.nll);
inCI        = PROF.tauDev <= 3.841458820694124;      % chi2_1, 95 %
if any(inCI)
    PROF.tauCI = [min(PROF.tauGrid(inCI)), max(PROF.tauGrid(inCI))];
else
    PROF.tauCI = [NaN NaN];
end
fprintf('  profile 95%% CI for tau_r : [%.4f, %.4f] mm/km\n', PROF.tauCI);

% ---- 3c  profile likelihood for sigma_s (weakly identified) -------------
% L and n are strongly collinear in a levelling archive, so sigma_s is
% typically not resolvable; report an upper confidence bound instead of a
% point estimate.
fprintf('  profiling sigma_s over %d grid points ...\n', numel(CFG.ssGrid));
PROF.ssGrid = CFG.ssGrid(:);
PROF.ssNll  = nan(size(PROF.ssGrid));
theta_warm  = [];
for k = 1:numel(PROF.ssGrid)
    wo = warmOpt; wo.theta0 = theta_warm;
    Fk = fit_variance_ml(d, L, n, true, struct('ss2', PROF.ssGrid(k)^2), wo);
    PROF.ssNll(k) = Fk.nll;
    theta_warm    = Fk.theta;
end
PROF.ssDev = 2 * (PROF.ssNll - min(PROF.ssNll));
inCIs      = PROF.ssDev <= 3.841458820694124;
if any(inCIs)
    PROF.ssCI = [min(PROF.ssGrid(inCIs)), max(PROF.ssGrid(inCIs))];
else
    PROF.ssCI = [NaN NaN];
end
fprintf('  profile 95%% CI for sigma_s: [%.4f, %.4f] mm/set-up\n\n', PROF.ssCI);

% ---- 3d  nonparametric bootstrap ----------------------------------------
fprintf('  bootstrap with %d replications ...\n', CFG.nBoot);
BOOT = struct();
BOOT.nBoot   = CFG.nBoot;
BOOT.sigma_d = nan(CFG.nBoot, 1);
BOOT.sigma_s = nan(CFG.nBoot, 1);
BOOT.tau_r   = nan(CFG.nBoot, 1);
N = numel(d);
rng(CFG.rngSeed);                       % bootstrap is reproducible on its own
bootOpt = struct('nStarts', 1, 'polish', true, 'theta0', M1.theta);
tic
for b = 1:CFG.nBoot
    idx = randi(N, N, 1);
    Fb  = fit_variance_ml(d(idx), L(idx), n(idx), true, struct(), bootOpt);
    BOOT.sigma_d(b) = Fb.sigma_d;
    BOOT.sigma_s(b) = Fb.sigma_s;
    BOOT.tau_r(b)   = Fb.tau_r;
    if mod(b, max(1, round(CFG.nBoot / 10))) == 0
        fprintf('    %5.0f %% (%.0f s)\n', 100 * b / CFG.nBoot, toc);
    end
end
BOOT.tauCI     = ST.prctile(BOOT.tau_r,   [2.5 97.5]);
BOOT.tauMedian = ST.prctile(BOOT.tau_r,   50);
BOOT.sdCI      = ST.prctile(BOOT.sigma_d, [2.5 97.5]);
BOOT.sdMedian  = ST.prctile(BOOT.sigma_d, 50);
BOOT.tauFracZero = mean(BOOT.tau_r < 1e-4);

fprintf('  bootstrap tau_r  : median %.4f, 95%% CI [%.4f, %.4f] mm/km\n', ...
        BOOT.tauMedian, BOOT.tauCI(1), BOOT.tauCI(2));
fprintf('  bootstrap sigma_d: median %.4f, 95%% CI [%.4f, %.4f] mm/sqrt(km)\n', ...
        BOOT.sdMedian, BOOT.sdCI(1), BOOT.sdCI(2));
fprintf('  replications with tau_r ~ 0: %.1f %%\n\n', 100 * BOOT.tauFracZero);


%% =============== 4.  DERIVED QUANTITIES FOR THE MANUSCRIPT ============

fprintf('--- Derived quantities ---\n');

DER = struct();
rho             = DESC.setupDensity;           % set-ups per km
DER.setupDensity = rho;

% single-run variance components at a reference length
Lref            = 1.0;                                    % km
DER.Lref        = Lref;
DER.a_at_Lref   = M1.sd2 * Lref + M1.ss2 * rho * Lref;    % mm^2
DER.b_at_Lref   = M1.tau2 * Lref^2;                       % mm^2 (chi = 1)
DER.bOverA_Lref = DER.b_at_Lref / DER.a_at_Lref;

% crossover length: the route length at which the coherent component equals
% the random component, i.e. the length beyond which the manuscript's b_p term
% dominates a_p and the proposed minimax rule can matter at all.
if M1.tau2 > 0
    DER.L_cross = (M1.sd2 + M1.ss2 * rho) / M1.tau2;      % km
else
    DER.L_cross = Inf;
end

% same quantities under the coefficients assumed in the manuscript
DER.paper_a_at_Lref = CFG.paper.sigma_d^2 * Lref + CFG.paper.sigma_s^2 * rho * Lref;
DER.paper_b_at_Lref = CFG.paper.tau_r^2 * Lref^2;
DER.paper_L_cross   = (CFG.paper.sigma_d^2 + CFG.paper.sigma_s^2 * rho) / CFG.paper.tau_r^2;

% ratio of empirical to assumed coefficients
DER.ratio_sigma_d = M1.sigma_d / CFG.paper.sigma_d;
DER.ratio_tau_r   = M1.tau_r   / CFG.paper.tau_r;

% is the manuscript's assumed tau_r inside the empirical confidence interval?
DER.paperTauInProfileCI = CFG.paper.tau_r >= PROF.tauCI(1) && ...
                          CFG.paper.tau_r <= PROF.tauCI(2);
DER.paperTauInBootCI    = CFG.paper.tau_r >= BOOT.tauCI(1) && ...
                          CFG.paper.tau_r <= BOOT.tauCI(2);

% the manuscript's ordering quantity q_p = a_p / sqrt(b_p), tabulated over L
DER.qCurve_L  = logspace(log10(max(min(L), 1e-3)), log10(max(L)), 200)';
DER.qCurve_q  = (M1.sd2 * DER.qCurve_L + M1.ss2 * rho * DER.qCurve_L) ./ ...
                sqrt(max(M1.tau2 * DER.qCurve_L.^2, eps));

fprintf('  set-up density        : %.2f per km\n', rho);
fprintf('  a(1 km)               : %.4f mm^2  (manuscript %.4f)\n', ...
        DER.a_at_Lref, DER.paper_a_at_Lref);
fprintf('  b(1 km), chi = 1      : %.4f mm^2  (manuscript %.4f)\n', ...
        DER.b_at_Lref, DER.paper_b_at_Lref);
fprintf('  b/a at 1 km           : %.3f\n', DER.bOverA_Lref);
fprintf('  crossover length L*   : %.4f km  (manuscript %.4f km)\n', ...
        DER.L_cross, DER.paper_L_cross);
fprintf('  assumed tau_r inside profile CI : %d ; inside bootstrap CI : %d\n\n', ...
        DER.paperTauInProfileCI, DER.paperTauInBootCI);


%% =============== 5.  COMMON-MODE (SAME-DAY) DIAGNOSTIC ================
% The manuscript also carries an equal-loading common component nu (the term
% nu*1*1'), which would arise from an effect shared by routes observed under
% the same conditions.  If such an effect exists, forward/backward pairs run on
% DIFFERENT days should show larger normalised discrepancies than pairs run on
% the same day.  This is a direct, cheap test of that assumption.

fprintf('--- Common-mode (same-day vs different-day) diagnostic ---\n');

CM = struct();
z          = M1.z;                    % normalised residuals under M1
CM.z       = z;
CM.varAll  = var(z, 0);
CM.varSame = var(z(sameDay),  0);
CM.varDiff = var(z(~sameDay), 0);
CM.nSame   = sum(sameDay);
CM.nDiff   = sum(~sameDay);
CM.Fstat   = CM.varDiff / CM.varSame;
% two-sided F test on the variance ratio
if isfinite(CM.Fstat) && CM.Fstat > 0
    df1 = CM.nDiff - 1;
    df2 = CM.nSame - 1;
    pUp = betainc(df2 / (df2 + df1 * CM.Fstat), df2 / 2, df1 / 2);
    CM.pValue = 2 * min(pUp, 1 - pUp);
else
    CM.pValue = NaN;
end

fprintf('  var(z) same-day (n=%d)      : %.4f\n', CM.nSame, CM.varSame);
fprintf('  var(z) different-day (n=%d) : %.4f\n', CM.nDiff, CM.varDiff);
fprintf('  variance ratio F            : %.4f  (p = %.4f)\n', CM.Fstat, CM.pValue);
if CM.pValue > 0.05
    fprintf('  -> no detectable day-to-day common-mode inflation.\n\n');
else
    fprintf('  -> day-to-day common-mode inflation is detectable.\n\n');
end


%% =============== 6.  BINNED EMPIRICAL VARIANCE (for figure 1) =========
% Bin the pairs by length and form the empirical single-run variance
% mean(d^2)/2 in each bin, with an exact chi-square confidence interval:
% if d_i ~ N(0, v) then sum(d_i^2)/v ~ chi2_k.

edges = exp(linspace(log(min(L) * 0.999), log(max(L) * 1.001), CFG.nBinsFig1 + 1));
BIN = struct('edges', edges, 'Lmid', [], 'vHat', [], 'lo', [], 'hi', [], 'k', []);
for j = 1:CFG.nBinsFig1
    m = L >= edges(j) & L < edges(j + 1);
    if j == CFG.nBinsFig1, m = m | (L == edges(end)); end
    k = sum(m);
    if k < 3
        BIN.Lmid(j,1) = NaN; BIN.vHat(j,1) = NaN;
        BIN.lo(j,1)   = NaN; BIN.hi(j,1)   = NaN; BIN.k(j,1) = k;
        continue
    end
    vHat = mean(d(m).^2) / 2;                      % single-run variance
    BIN.Lmid(j,1) = exp(mean(log(L(m))));
    BIN.vHat(j,1) = vHat;
    BIN.lo(j,1)   = k * vHat / ST.chi2inv(0.975, k);
    BIN.hi(j,1)   = k * vHat / ST.chi2inv(0.025, k);
    BIN.k(j,1)    = k;
end


%% =============== 7.  SAVE EVERYTHING TO A .MAT FILE ===================

RESULTS               = struct();
RESULTS.createdOn     = datestr(now, 'yyyy-mm-dd HH:MM:SS');       %#ok<TNOW1,DATST>
RESULTS.matlabVersion = version;
RESULTS.config        = CFG;
RESULTS.sections      = sections;
RESULTS.pairs         = pairs;
RESULTS.data          = struct('d_mm', d, 'L_km', L, 'nSetups', n, ...
                               'sameDay', sameDay, 'gapDays', gapDays);
RESULTS.descriptives  = DESC;
RESULTS.M0            = M0;
RESULTS.M1            = M1;
RESULTS.LRT           = LRT;
RESULTS.profile       = PROF;
RESULTS.bootstrap     = BOOT;
RESULTS.derived       = DER;
RESULTS.commonMode    = CM;
RESULTS.binned        = BIN;

matFile = fullfile(CFG.outDir, 'GSVS17_calibration_results.mat');
save(matFile, '-struct', 'RESULTS', '-v7.3');
fprintf('--- Results written to %s ---\n\n', matFile);


%% =============== 8.  FIGURES  (all fonts = CFG.fontSize) ==============

FS  = CFG.fontSize;
LW  = 2.0;
MS  = 9;
col = struct('data',   [0.60 0.63 0.68], ...
             'M0',     [0.20 0.45 0.80], ...
             'M1',     [0.85 0.32 0.20], ...
             'paper',  [0.25 0.60 0.35], ...
             'ci',     [0.90 0.90 0.92]);

Lgrid = logspace(log10(min(L) * 0.9), log10(max(L) * 1.1), 400)';
a0    = M0.sd2 * Lgrid + M0.ss2 * rho * Lgrid;
a1    = M1.sd2 * Lgrid + M1.ss2 * rho * Lgrid;
b1    = M1.tau2 * Lgrid.^2;

% ---------------------------------------------------------------- FIGURE 1
% Empirical single-run variance against section length, with both fitted
% models.  This is the core evidence figure: if the pure random model held,
% the points would follow a straight line of slope 1 on log-log axes.
f1 = figure('Name', 'Variance vs length', 'Color', 'w', ...
            'Position', [80 80 900 700]);
ax = axes('Parent', f1); hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');

h0 = plot(ax, L, d.^2 / 2, 'o', 'MarkerSize', 5, ...
          'MarkerEdgeColor', col.data, 'MarkerFaceColor', 'none');
ok = isfinite(BIN.Lmid);
h1 = errorbar(ax, BIN.Lmid(ok), BIN.vHat(ok), ...
              BIN.vHat(ok) - BIN.lo(ok), BIN.hi(ok) - BIN.vHat(ok), ...
              'ks', 'MarkerSize', MS, 'MarkerFaceColor', 'k', ...
              'LineWidth', LW, 'LineStyle', 'none', 'CapSize', 10);
h2 = plot(ax, Lgrid, a0,       '-',  'Color', col.M0,    'LineWidth', LW);
h3 = plot(ax, Lgrid, a1 + b1,  '-',  'Color', col.M1,    'LineWidth', LW + 0.5);
h4 = plot(ax, Lgrid, a1,       '--', 'Color', col.M1,    'LineWidth', LW);
h5 = plot(ax, Lgrid, b1,       ':',  'Color', col.M1,    'LineWidth', LW);
h6 = plot(ax, Lgrid, ...
          CFG.paper.sigma_d^2 * Lgrid + CFG.paper.sigma_s^2 * rho * Lgrid + ...
          CFG.paper.tau_r^2 * Lgrid.^2, ...
          '-.', 'Color', col.paper, 'LineWidth', LW);

set(ax, 'XScale', 'log', 'YScale', 'log');
xlabel(ax, 'Section length  L  (km)');
ylabel(ax, 'Single-run variance  d^2/2  (mm^2)');
title(ax, 'GSVS17: route-total variance versus length');
legend(ax, [h0 h1 h2 h3 h4 h5 h6], ...
    {'individual F/B pairs', 'binned mean (95% CI)', ...
     'M0: a(L) only', 'M1: a(L)+b(L)', 'M1: a(L)', 'M1: b(L)', ...
     'manuscript assumption'}, ...
    'Location', 'northwest', 'Box', 'on');
apply_font_size(f1, FS);
savefig(f1, fullfile(CFG.outDir, 'fig1_variance_vs_length.fig'));
print(f1, fullfile(CFG.outDir, 'fig1_variance_vs_length'), CFG.figFormat, CFG.figDPI);

% ---------------------------------------------------------------- FIGURE 2
% Inference on tau_r: profile likelihood and bootstrap distribution.
f2 = figure('Name', 'Inference on tau_r', 'Color', 'w', ...
            'Position', [100 100 1400 620]);

axA = subplot(1, 2, 1); hold(axA, 'on'); box(axA, 'on'); grid(axA, 'on');
hA = gobjects(0); lA = {};
hA(end+1) = plot(axA, PROF.tauGrid, PROF.tauDev, '-', ...
                 'Color', col.M1, 'LineWidth', LW + 0.5);
lA{end+1} = 'profile deviance';
ytop = max(PROF.tauDev(isfinite(PROF.tauDev)));
if ~isfinite(ytop) || ytop <= 0, ytop = 10; end
yl = [0, min(ytop, 30)];
hA(end+1) = plot(axA, [min(PROF.tauGrid) max(PROF.tauGrid)], ...
                 [3.8415 3.8415], 'k--', 'LineWidth', LW);
lA{end+1} = '\chi^2_1 95% level';
if all(isfinite(PROF.tauCI))
    hA(end+1) = plot(axA, [PROF.tauCI(1) PROF.tauCI(1)], yl, 'k:', 'LineWidth', LW);
    lA{end+1} = '95% CI bounds';
    plot(axA, [PROF.tauCI(2) PROF.tauCI(2)], yl, 'k:', 'LineWidth', LW);
end
hA(end+1) = plot(axA, [M1.tau_r M1.tau_r], yl, '-', 'Color', col.M1, 'LineWidth', LW);
lA{end+1} = sprintf('ML estimate %.2f', M1.tau_r);
hA(end+1) = plot(axA, [CFG.paper.tau_r CFG.paper.tau_r], yl, '-', ...
                 'Color', col.paper, 'LineWidth', LW + 0.5);
lA{end+1} = sprintf('manuscript %.2f', CFG.paper.tau_r);
ylim(axA, yl);
xlabel(axA, '\tau_r  (mm km^{-1})');
ylabel(axA, '2\Delta(-log L)');
title(axA, sprintf('Profile likelihood   (95%% CI [%.2f, %.2f])', PROF.tauCI));
legend(axA, hA, lA, 'Location', 'north', 'Box', 'on');

axB = subplot(1, 2, 2); hold(axB, 'on'); box(axB, 'on'); grid(axB, 'on');
hB = gobjects(0); lB = {};
hB(end+1) = histogram(axB, BOOT.tau_r, 40, 'FaceColor', col.M1, ...
                      'EdgeColor', 'w', 'FaceAlpha', 0.75, 'Normalization', 'pdf');
lB{end+1} = 'bootstrap replicates';
yl2 = ylim(axB);
hB(end+1) = plot(axB, [BOOT.tauCI(1) BOOT.tauCI(1)], yl2, 'k:', 'LineWidth', LW);
lB{end+1} = '2.5 / 97.5 %';
plot(axB, [BOOT.tauCI(2) BOOT.tauCI(2)], yl2, 'k:', 'LineWidth', LW);
hB(end+1) = plot(axB, [M1.tau_r M1.tau_r], yl2, 'k-', 'LineWidth', LW);
lB{end+1} = sprintf('ML estimate %.2f', M1.tau_r);
hB(end+1) = plot(axB, [CFG.paper.tau_r CFG.paper.tau_r], yl2, '-', ...
                 'Color', col.paper, 'LineWidth', LW + 0.5);
lB{end+1} = sprintf('manuscript %.2f', CFG.paper.tau_r);
ylim(axB, yl2);
xlabel(axB, '\tau_r  (mm km^{-1})');
ylabel(axB, 'bootstrap density');
title(axB, sprintf('Bootstrap  (B = %d)', CFG.nBoot));
legend(axB, hB, lB, 'Location', 'northeast', 'Box', 'on');

apply_font_size(f2, FS);
savefig(f2, fullfile(CFG.outDir, 'fig2_tau_inference.fig'));
print(f2, fullfile(CFG.outDir, 'fig2_tau_inference'), CFG.figFormat, CFG.figDPI);

% ---------------------------------------------------------------- FIGURE 3
% Model adequacy: normal QQ plot of the normalised residuals, and the running
% variance of the normalised residuals against length.  Under a correct
% variance model, var(z) = 1 at every length.
f3 = figure('Name', 'Model diagnostics', 'Color', 'w', ...
            'Position', [120 120 1400 620]);

z0 = M0.z; z1 = M1.z;
Nz = numel(z1);
pp = ((1:Nz)' - 0.5) / Nz;
q  = ST.norminv(pp);

axA = subplot(1, 2, 1); hold(axA, 'on'); box(axA, 'on'); grid(axA, 'on');
plot(axA, q, sort(z0), 'o', 'MarkerSize', 5, 'Color', col.M0, 'LineWidth', 1.2);
plot(axA, q, sort(z1), 's', 'MarkerSize', 5, 'Color', col.M1, 'LineWidth', 1.2);
lim = [min(q) max(q)] * 1.05;
plot(axA, lim, lim, 'k-', 'LineWidth', LW);
xlim(axA, lim); ylim(axA, lim);
xlabel(axA, 'standard normal quantile');
ylabel(axA, 'ordered  z = d / \sigma_d^{fit}');
title(axA, 'Normalised residuals');
legend(axA, {'M0', 'M1', '1:1'}, 'Location', 'northwest', 'Box', 'on');

axB = subplot(1, 2, 2); hold(axB, 'on'); box(axB, 'on'); grid(axB, 'on');
nb   = CFG.nBinsFig1;
ed   = exp(linspace(log(min(L) * 0.999), log(max(L) * 1.001), nb + 1));
Lm   = nan(nb, 1); v0b = nan(nb, 1); v1b = nan(nb, 1);
for j = 1:nb
    m = L >= ed(j) & L < ed(j + 1);
    if j == nb, m = m | (L == ed(end)); end
    if sum(m) < 3, continue, end
    Lm(j)  = exp(mean(log(L(m))));
    v0b(j) = mean(z0(m).^2);
    v1b(j) = mean(z1(m).^2);
end
ok = isfinite(Lm);
plot(axB, Lm(ok), v0b(ok), 'o-', 'Color', col.M0, 'LineWidth', LW, ...
     'MarkerSize', MS, 'MarkerFaceColor', col.M0);
plot(axB, Lm(ok), v1b(ok), 's-', 'Color', col.M1, 'LineWidth', LW, ...
     'MarkerSize', MS, 'MarkerFaceColor', col.M1);
plot(axB, xlim(axB), [1 1], 'k--', 'LineWidth', LW);
set(axB, 'XScale', 'log');
xlabel(axB, 'Section length  L  (km)');
ylabel(axB, 'mean  z^2  in bin');
title(axB, 'Variance-model adequacy by length');
legend(axB, {'M0', 'M1', 'target = 1'}, 'Location', 'northwest', 'Box', 'on');

apply_font_size(f3, FS);
savefig(f3, fullfile(CFG.outDir, 'fig3_model_diagnostics.fig'));
print(f3, fullfile(CFG.outDir, 'fig3_model_diagnostics'), CFG.figFormat, CFG.figDPI);

% ---------------------------------------------------------------- FIGURE 4
% Decomposition into a(L) and b(L), the crossover length, and the manuscript's
% ordering quantity q(L) = a(L)/sqrt(b(L)).
f4 = figure('Name', 'Variance decomposition', 'Color', 'w', ...
            'Position', [140 140 1400 620]);

axA = subplot(1, 2, 1); hold(axA, 'on'); box(axA, 'on'); grid(axA, 'on');
plot(axA, Lgrid, a1,      '-',  'Color', col.M0, 'LineWidth', LW + 0.5);
plot(axA, Lgrid, b1,      '-',  'Color', col.M1, 'LineWidth', LW + 0.5);
plot(axA, Lgrid, a1 + b1, 'k-', 'LineWidth', LW);
if isfinite(DER.L_cross) && DER.L_cross > min(Lgrid) && DER.L_cross < max(Lgrid)
    yc = M1.sd2 * DER.L_cross + M1.ss2 * rho * DER.L_cross;
    plot(axA, DER.L_cross, yc, 'kp', 'MarkerSize', 20, 'MarkerFaceColor', 'y', ...
         'LineWidth', 1.5);
    text(axA, DER.L_cross, yc, sprintf('  L^* = %.2f km', DER.L_cross), ...
         'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
end
set(axA, 'XScale', 'log', 'YScale', 'log');
xlabel(axA, 'Route length  L  (km)');
ylabel(axA, 'Variance  (mm^2)');
title(axA, 'Random versus route-coherent component');
legend(axA, {'a(L) random', 'b(L) coherent', 'a(L)+b(L)'}, ...
       'Location', 'northwest', 'Box', 'on');

axB = subplot(1, 2, 2); hold(axB, 'on'); box(axB, 'on'); grid(axB, 'on');
qL = (M1.sd2 * Lgrid + M1.ss2 * rho * Lgrid) ./ sqrt(max(b1, eps));
plot(axB, Lgrid, qL, '-', 'Color', col.M1, 'LineWidth', LW + 0.5);
set(axB, 'XScale', 'log', 'YScale', 'log');
xlabel(axB, 'Route length  L  (km)');
ylabel(axB, 'q(L) = a(L) / b(L)^{1/2}   (mm)');
title(axB, 'Active-set ordering quantity');
apply_font_size(f4, FS);
savefig(f4, fullfile(CFG.outDir, 'fig4_variance_decomposition.fig'));
print(f4, fullfile(CFG.outDir, 'fig4_variance_decomposition'), CFG.figFormat, CFG.figDPI);

% ---------------------------------------------------------------- FIGURE 5
% Common-mode check: empirical distribution of the normalised residuals for
% same-day and different-day forward/backward pairs.
f5 = figure('Name', 'Common-mode check', 'Color', 'w', ...
            'Position', [160 160 900 700]);
ax = axes(f5); hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');

zs = sort(abs(z1(sameDay)));
zd = sort(abs(z1(~sameDay)));
plot(ax, zs, (1:numel(zs))' / numel(zs), '-', 'Color', col.M0, 'LineWidth', LW + 0.5);
plot(ax, zd, (1:numel(zd))' / numel(zd), '-', 'Color', col.M1, 'LineWidth', LW + 0.5);
xg = linspace(0, max([zs; zd]) * 1.02, 300)';
plot(ax, xg, erf(xg / sqrt(2)), 'k--', 'LineWidth', LW);
xlabel(ax, '|z| = |d| / \sigma_d^{fit}');
ylabel(ax, 'empirical CDF');
title(ax, sprintf('Common-mode check:  F = %.3f,  p = %.3f', CM.Fstat, CM.pValue));
legend(ax, {sprintf('same day (n = %d)', CM.nSame), ...
            sprintf('different day (n = %d)', CM.nDiff), ...
            'half-normal reference'}, ...
       'Location', 'southeast', 'Box', 'on');
apply_font_size(f5, FS);
savefig(f5, fullfile(CFG.outDir, 'fig5_common_mode_check.fig'));
print(f5, fullfile(CFG.outDir, 'fig5_common_mode_check'), CFG.figFormat, CFG.figDPI);

fprintf('--- 5 figure(s) written to %s ---\n\n', CFG.outDir);


%% =============== 9.  SUMMARY FOR THE MANUSCRIPT =======================

fprintf('=====================================================\n');
fprintf(' SUMMARY  (paste-ready numbers)\n');
fprintf('=====================================================\n');
fprintf(' Data      : GSVS17, %d sections, %d forward/backward pairs,\n', ...
        DESC.nSections, DESC.nPairs);
fprintf('             %.1f km of first-order class II levelling.\n', DESC.totalLength);
fprintf(' M0        : sigma_d = %.3f mm/sqrt(km)\n', M0.sigma_d);
fprintf(' M1        : sigma_d = %.3f mm/sqrt(km), tau_r = %.3f mm/km\n', ...
        M1.sigma_d, M1.tau_r);
fprintf('             sigma_s <= %.3f mm/set-up (95%% profile bound)\n', PROF.ssCI(2));
fprintf(' Test      : LR = %.2f, p = %.1e -> the coherent L^2 term is\n', ...
        LRT.stat, LRT.pBoundary);
if LRT.pBoundary < 0.05
    fprintf('             REQUIRED by the data.\n');
else
    fprintf('             NOT required by the data.\n');
end
fprintf(' tau_r CI  : profile [%.3f, %.3f], bootstrap [%.3f, %.3f] mm/km\n', ...
        PROF.tauCI(1), PROF.tauCI(2), BOOT.tauCI(1), BOOT.tauCI(2));
fprintf(' Manuscript: tau_r = %.2f mm/km is %s the empirical 95%% CI.\n', ...
        CFG.paper.tau_r, ternary(DER.paperTauInProfileCI, 'INSIDE', 'OUTSIDE'));
fprintf(' b/a at 1 km : %.2f ; crossover length L* = %.2f km\n', ...
        DER.bOverA_Lref, DER.L_cross);
fprintf(' Common mode : var ratio %.3f (p = %.3f) -> %s\n', ...
        CM.Fstat, CM.pValue, ...
        ternary(CM.pValue > 0.05, 'no day-to-day inflation detected', ...
                                  'day-to-day inflation detected'));
fprintf('=====================================================\n\n');


end % end of the callable workflow

%% ======================= local helpers ================================

function r = corrLocal(x, y)
x = x(:) - mean(x); y = y(:) - mean(y);
r = (x' * y) / sqrt((x' * x) * (y' * y));
end

function s = ternary(cond, a, b)
if cond, s = a; else, s = b; end
end
