function ADD = gsvs17_addendum(options)
%GSVS17_ADDENDUM  Robustness analysis and corrected figures for the GSVS17
%                 minimum-viable validation.
%
%   Run AFTER gsvs17_min_validation.m.  Loads the saved results, adds the
%   robustness checks a referee will demand, and regenerates the three figures
%   that were defective in the first run.
%
%   Why this file exists
%   --------------------
%   1  FIGURE 1 was unreadable.  One forward/backward pair has d = 0.000 mm
%      exactly (the LVL records are quantised to 0.01 mm), so d^2/2 = 6e-24 and
%      the logarithmic y-axis was forced to span 10^-25 to 10^5.  All real
%      structure was compressed into the top tenth of the panel.
%
%   2  THE BINNING was degenerate.  The section lengths are strongly
%      concentrated (5th percentile 0.44 km; 163 of 274 pairs above 1.35 km),
%      so log-spaced bins left three bins with 0, 1 and 2 pairs (plotted as
%      NaN) while the last bin held 60 % of the data.  Equal-count bins are
%      used here instead.
%
%   3  FIGURE 4b WAS MEANINGLESS.  With a(L) = (sd2 + ss2*rho)L and
%      b(L) = tau2*L^2, the ordering quantity
%           q(L) = a(L)/sqrt(b(L)) = (sd2 + ss2*rho)/tau_r
%      is CONSTANT in L.  The panel plotted 14 digits of floating-point noise.
%      It is replaced by the coherent variance share b/(a+b), which is the
%      quantity that actually varies and that the manuscript needs.
%      This is also a substantive finding - see the note at the end.
%
%   4  ROBUSTNESS was untested.  The evidence for the L^2 term could have come
%      entirely from the three sub-100 m sections.  Subset refits and a
%      model-free power-law exponent settle that.
%
%   Outputs
%     <outDir>/GSVS17_addendum_results.mat
%     <outDir>/fig1_variance_vs_length.(fig|png)     regenerated
%     <outDir>/fig3_model_diagnostics.(fig|png)      regenerated
%     <outDir>/fig4_variance_decomposition.(fig|png) regenerated
%     <outDir>/fig6_powerlaw_exponent.(fig|png)      new
%
%   Base MATLAB only.

% Unified adapter: isolate workspace and preserve existing open figures.
if nargin < 1, options = struct(); end

%% ---------------------------- configuration ----------------------------
CFG          = struct();
CFG.outDir   = fullfile(pwd, 'results');
CFG.matFile  = fullfile(CFG.outDir, 'GSVS17_calibration_results.mat');
CFG.fontSize = 20;
CFG.nBins    = 8;                       % equal-count bins
CFG.gamGrid  = linspace(0.20, 3.00, 281);
CFG.subsets  = [0 0.10 0.30 0.50 0.80]; % minimum length (km) for subset refits
CFG.paperTau = 0.60;                    % mm/km, manuscript assumption
CFG.paperSd  = 0.40;                    % mm/sqrt(km)
CFG.paperSs  = 0.04;                    % mm/set-up
CFG.figFmt   = '-dpng';
CFG.figDPI   = '-r300';

CFG = jag.gsvs_options(CFG, options, 'addendum');
if ~exist(CFG.outDir, 'dir'), mkdir(CFG.outDir); end

assert(exist(CFG.matFile, 'file') == 2, ...
    'Run gsvs17_min_validation.m first: %s not found.', CFG.matFile);

R  = load(CFG.matFile);
ST = statlib_local();

d   = R.data.d_mm(:);
L   = R.data.L_km(:);
n   = R.data.nSetups(:);
rho = R.derived.setupDensity;
M0  = R.M0;
M1  = R.M1;

fprintf('\n===============================================\n');
fprintf(' GSVS17 addendum: robustness and corrected figures\n');
fprintf('===============================================\n\n');
fprintf('Loaded %d pairs.  M1: sigma_d = %.4f, tau_r = %.4f\n\n', ...
        numel(d), M1.sigma_d, M1.tau_r);


%% ------------------- 1.  SUBSET REFITS (robustness) ---------------------
% Is the L^2 term driven by the handful of very short sections?

fprintf('--- Subset refits: is the coherent term robust? ---\n');
fprintf('%-16s %5s %10s %9s %8s %11s\n', ...
        'subset', 'N', 'sigma_d', 'tau_r', 'LR', 'p');

SUB = struct('minL', [], 'N', [], 'sigma_d', [], 'tau_r', [], 'LR', [], 'p', []);
for k = 1:numel(CFG.subsets)
    m  = L >= CFG.subsets(k);
    F0 = fit_variance_ml(d(m), L(m), n(m), false);
    F1 = fit_variance_ml(d(m), L(m), n(m), true);
    LR = 2 * (F0.nll - F1.nll);
    p  = 0.5 * ST.chi2sf(max(LR, 0), 1);

    SUB.minL(k,1)    = CFG.subsets(k);
    SUB.N(k,1)       = sum(m);
    SUB.sigma_d(k,1) = F1.sigma_d;
    SUB.tau_r(k,1)   = F1.tau_r;
    SUB.LR(k,1)      = LR;
    SUB.p(k,1)       = p;

    if CFG.subsets(k) == 0
        lbl = 'all pairs';
    else
        lbl = sprintf('L >= %.2f km', CFG.subsets(k));
    end
    fprintf('%-16s %5d %10.4f %9.4f %8.3f %11.4g\n', ...
            lbl, sum(m), F1.sigma_d, F1.tau_r, LR, p);
end
fprintf('\n');


%% ------------------- 2.  MODEL-FREE POWER-LAW EXPONENT ------------------
% Fit  v(L) = 2 * c * L^gamma  by maximum likelihood and profile gamma.
% gamma = 1 is pure random accumulation; gamma = 2 is pure route-coherent.
% This statement needs no a/b decomposition and is the cleanest single result.

fprintf('--- Model-free power law  v ~ L^gamma ---\n');
PL = struct('minL', [], 'N', [], 'gamma', [], 'ci', [], 'grid', CFG.gamGrid(:), 'dev', []);
for k = 1:3
    minL = CFG.subsets(min(k, numel(CFG.subsets)));
    if k == 1, minL = 0; elseif k == 2, minL = 0.30; else, minL = 0.50; end
    m = L >= minL;
    [gHat, gCI, dev] = fit_powerlaw(d(m), L(m), CFG.gamGrid);

    PL.minL(k,1)  = minL;
    PL.N(k,1)     = sum(m);
    PL.gamma(k,1) = gHat;
    PL.ci(k,:)    = gCI;
    PL.dev(:,k)   = dev(:);

    fprintf('  L >= %.2f km (N = %3d):  gamma = %.3f   95%% CI [%.2f, %.2f]\n', ...
            minL, sum(m), gHat, gCI(1), gCI(2));
end
fprintf('\n');


%% ------------------- 3.  IDENTIFIABILITY OF THE SPLIT -------------------
% sigma_d and tau_r trade off against each other: the TOTAL variance is well
% determined but its decomposition into a and b is not.

fprintf('--- How well is the a / b split determined? ---\n');
bsd = R.bootstrap.sigma_d(:);
bt  = R.bootstrap.tau_r(:);
ID  = struct();
ID.corr_sd_tau = corrLocal(bsd, bt);
Lq             = 1.5;                                  % representative length
vTot           = bsd.^2 * Lq + bt.^2 * Lq^2;
ID.Lq          = Lq;
ID.vTot_med    = ST.prctile(vTot, 50);
ID.vTot_ci     = ST.prctile(vTot, [2.5 97.5]);
bShare         = (bt.^2 * Lq^2) ./ vTot;
ID.bShare_med  = ST.prctile(bShare, 50);
ID.bShare_ci   = ST.prctile(bShare, [2.5 97.5]);
ID.sd_ci       = ST.prctile(bsd, [2.5 97.5]);

fprintf('  corr(sigma_d, tau_r) across bootstrap = %+.3f\n', ID.corr_sd_tau);
fprintf('  total variance at %.1f km : %.3f mm^2, 95%% CI [%.3f, %.3f]  (+/- %.0f %%)\n', ...
        Lq, ID.vTot_med, ID.vTot_ci(1), ID.vTot_ci(2), ...
        100 * (ID.vTot_ci(2) - ID.vTot_ci(1)) / 2 / ID.vTot_med);
fprintf('  coherent share b/(a+b)   : %.3f, 95%% CI [%.3f, %.3f]\n', ...
        ID.bShare_med, ID.bShare_ci(1), ID.bShare_ci(2));
fprintf('  sigma_d alone            : 95%% CI [%.3f, %.3f]  <- poorly determined\n\n', ...
        ID.sd_ci(1), ID.sd_ci(2));


%% ------------------- 4.  EQUAL-COUNT BINS -------------------------------
% Replace the log-spaced bins (which left three bins nearly empty) by bins of
% equal count, so every plotted point rests on a comparable sample.

nb   = CFG.nBins;
[Ls, ord] = sort(L);
ds   = d(ord);
edgeIdx = round(linspace(0, numel(L), nb + 1));
BIN = struct('Lmid', nan(nb,1), 'vHat', nan(nb,1), 'lo', nan(nb,1), ...
             'hi', nan(nb,1), 'k', nan(nb,1), 'Llo', nan(nb,1), 'Lhi', nan(nb,1));
for j = 1:nb
    ii = (edgeIdx(j) + 1):edgeIdx(j + 1);
    k  = numel(ii);
    if k < 3, continue, end
    vHat = mean(ds(ii).^2) / 2;
    BIN.Lmid(j) = exp(mean(log(Ls(ii))));
    BIN.Llo(j)  = min(Ls(ii));
    BIN.Lhi(j)  = max(Ls(ii));
    BIN.vHat(j) = vHat;
    BIN.lo(j)   = k * vHat / ST.chi2inv(0.975, k);
    BIN.hi(j)   = k * vHat / ST.chi2inv(0.025, k);
    BIN.k(j)    = k;
end
fprintf('--- Equal-count bins (%d pairs each) ---\n', round(numel(L)/nb));
for j = 1:nb
    if isfinite(BIN.Lmid(j))
        fprintf('  %5.3f - %5.3f km  (k = %3d):  v = %.4f  [%.4f, %.4f] mm^2\n', ...
                BIN.Llo(j), BIN.Lhi(j), BIN.k(j), BIN.vHat(j), BIN.lo(j), BIN.hi(j));
    end
end
fprintf('\n');


%% ------------------- 5.  SAVE ------------------------------------------
ADD = struct('createdOn', datestr(now, 'yyyy-mm-dd HH:MM:SS'), ...  %#ok<TNOW1,DATST>
             'config', CFG, 'subsets', SUB, 'powerlaw', PL, ...
             'identifiability', ID, 'binnedEqualCount', BIN);
addFile = fullfile(CFG.outDir, 'GSVS17_addendum_results.mat');
save(addFile, '-struct', 'ADD', '-v7.3');
fprintf('--- Addendum results written to %s ---\n\n', addFile);


%% ------------------- 6.  CORRECTED FIGURES ------------------------------
FS  = CFG.fontSize;
LW  = 2.0;
MS  = 9;
col = struct('data',  [0.62 0.65 0.70], 'M0', [0.20 0.45 0.80], ...
             'M1',    [0.85 0.32 0.20], 'paper', [0.25 0.60 0.35], ...
             'band',  [0.85 0.32 0.20]);

Lgrid = logspace(log10(min(L) * 0.9), log10(max(L) * 1.1), 400)';
a0    = M0.sd2 * Lgrid + M0.ss2 * rho * Lgrid;
a1    = M1.sd2 * Lgrid + M1.ss2 * rho * Lgrid;
b1    = M1.tau2 * Lgrid.^2;
aP    = CFG.paperSd^2 * Lgrid + CFG.paperSs^2 * rho * Lgrid;
bP    = CFG.paperTau^2 * Lgrid.^2;

% ------------------------------------------------------------- FIGURE 1
% Y-limits are now set from the data quantiles, not from the single
% zero-discrepancy pair.  That pair is annotated instead of silently
% controlling the axis.
y = d.^2 / 2;
yLo = max(ST.prctile(y(y > 0), 1) / 3, 1e-4);
yHi = max(y) * 4;
nBelow = sum(y < yLo);

f1 = figure('Name', 'Variance vs length (corrected)', 'Color', 'w', ...
            'Position', [80 80 980 760]);
ax = axes('Parent', f1); hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');

h0 = plot(ax, L, y, 'o', 'MarkerSize', 5, 'MarkerEdgeColor', col.data);
ok = isfinite(BIN.Lmid);
h1 = errorbar(ax, BIN.Lmid(ok), BIN.vHat(ok), ...
              BIN.vHat(ok) - BIN.lo(ok), BIN.hi(ok) - BIN.vHat(ok), ...
              'ks', 'MarkerSize', MS, 'MarkerFaceColor', 'k', ...
              'LineWidth', LW, 'LineStyle', 'none', 'CapSize', 10);
h2 = plot(ax, Lgrid, a0,      '-',  'Color', col.M0,    'LineWidth', LW);
h3 = plot(ax, Lgrid, a1 + b1, '-',  'Color', col.M1,    'LineWidth', LW + 1);
h4 = plot(ax, Lgrid, a1,      '--', 'Color', col.M1,    'LineWidth', LW);
h5 = plot(ax, Lgrid, b1,      ':',  'Color', col.M1,    'LineWidth', LW);
h6 = plot(ax, Lgrid, aP + bP, '-.', 'Color', col.paper, 'LineWidth', LW);

set(ax, 'XScale', 'log', 'YScale', 'log');
ylim(ax, [yLo yHi]);
xlim(ax, [min(Lgrid) max(Lgrid)]);
xlabel(ax, 'Section length  L  (km)');
ylabel(ax, 'Single-run variance  d^2/2  (mm^2)');
title(ax, 'GSVS17: route-total variance versus length');
lg = legend(ax, [h0 h1 h2 h3 h4 h5 h6], ...
    {'individual F/B pairs', 'equal-count bin (95% CI)', ...
     'M0: a(L) only', 'M1: a(L)+b(L)', 'M1: a(L)', 'M1: b(L)', ...
     'manuscript assumption'}, 'Location', 'southeast', 'Box', 'on');
if nBelow > 0
    text(ax, min(Lgrid) * 1.15, yLo * 1.6, ...
         sprintf('%d pair(s) below axis (|d| \\leq 0.01 mm)', nBelow), ...
         'VerticalAlignment', 'bottom');
end
apply_font_size(f1, FS);
savefig(f1, fullfile(CFG.outDir, 'fig1_variance_vs_length.fig'));
print(f1, fullfile(CFG.outDir, 'fig1_variance_vs_length'), CFG.figFmt, CFG.figDPI);

% ------------------------------------------------------------- FIGURE 3
% Same diagnostics, but on equal-count bins so that every point is comparable.
f3 = figure('Name', 'Model diagnostics (corrected)', 'Color', 'w', ...
            'Position', [110 110 1450 640]);

z0 = M0.z(:); z1 = M1.z(:);
Nz = numel(z1);
pp = ((1:Nz)' - 0.5) / Nz;
qn = ST.norminv(pp);

axA = subplot(1, 2, 1); hold(axA, 'on'); box(axA, 'on'); grid(axA, 'on');
plot(axA, qn, sort(z0), 'o', 'MarkerSize', 5, 'Color', col.M0, 'LineWidth', 1.2);
plot(axA, qn, sort(z1), 's', 'MarkerSize', 5, 'Color', col.M1, 'LineWidth', 1.2);
lim = [-3.2 3.2];
plot(axA, lim, lim, 'k-', 'LineWidth', LW);
xlim(axA, lim); ylim(axA, lim);
xlabel(axA, 'standard normal quantile');
ylabel(axA, 'ordered  z = d / \sigma^{fit}');
title(axA, 'Normalised residuals');
legend(axA, {'M0', 'M1', '1:1'}, 'Location', 'northwest', 'Box', 'on');

axB = subplot(1, 2, 2); hold(axB, 'on'); box(axB, 'on'); grid(axB, 'on');
v0b = nan(nb,1); v1b = nan(nb,1); lo0 = nan(nb,1); hi0 = nan(nb,1);
z0s = z0(ord); z1s = z1(ord);
for j = 1:nb
    ii = (edgeIdx(j) + 1):edgeIdx(j + 1);
    if numel(ii) < 3, continue, end
    k = numel(ii);
    v0b(j) = mean(z0s(ii).^2);
    v1b(j) = mean(z1s(ii).^2);
    lo0(j) = k / ST.chi2inv(0.975, k);
    hi0(j) = k / ST.chi2inv(0.025, k);
end
ok = isfinite(BIN.Lmid);
fill(axB, [BIN.Lmid(ok); flipud(BIN.Lmid(ok))], [lo0(ok); flipud(hi0(ok))], ...
     [0.88 0.88 0.90], 'EdgeColor', 'none', 'FaceAlpha', 0.8);
plot(axB, BIN.Lmid(ok), v0b(ok), 'o-', 'Color', col.M0, 'LineWidth', LW, ...
     'MarkerSize', MS, 'MarkerFaceColor', col.M0);
plot(axB, BIN.Lmid(ok), v1b(ok), 's-', 'Color', col.M1, 'LineWidth', LW, ...
     'MarkerSize', MS, 'MarkerFaceColor', col.M1);
plot(axB, [min(BIN.Lmid(ok)) max(BIN.Lmid(ok))], [1 1], 'k--', 'LineWidth', LW);
set(axB, 'XScale', 'log');
xlabel(axB, 'Section length  L  (km)');
ylabel(axB, 'mean  z^2  in bin');
title(axB, 'Variance-model adequacy by length');
legend(axB, {'95% band', 'M0', 'M1', 'target = 1'}, ...
       'Location', 'northwest', 'Box', 'on');
apply_font_size(f3, FS);
savefig(f3, fullfile(CFG.outDir, 'fig3_model_diagnostics.fig'));
print(f3, fullfile(CFG.outDir, 'fig3_model_diagnostics'), CFG.figFmt, CFG.figDPI);

% ------------------------------------------------------------- FIGURE 4
% Panel (b) now shows the coherent share b/(a+b), which varies with L, with a
% bootstrap band.  The old q(L) panel is removed: q(L) is constant whenever
% a is linear and b is quadratic in L (see the closing note).
f4 = figure('Name', 'Variance decomposition (corrected)', 'Color', 'w', ...
            'Position', [140 140 1450 640]);

axA = subplot(1, 2, 1); hold(axA, 'on'); box(axA, 'on'); grid(axA, 'on');
plot(axA, Lgrid, a1,      '-',  'Color', col.M0, 'LineWidth', LW + 0.5);
plot(axA, Lgrid, b1,      '-',  'Color', col.M1, 'LineWidth', LW + 0.5);
plot(axA, Lgrid, a1 + b1, 'k-', 'LineWidth', LW);
Lc = R.derived.L_cross;
if isfinite(Lc) && Lc > min(Lgrid) && Lc < max(Lgrid)
    yc = M1.sd2 * Lc + M1.ss2 * rho * Lc;
    plot(axA, Lc, yc, 'kp', 'MarkerSize', 22, 'MarkerFaceColor', [1 0.85 0.2], ...
         'LineWidth', 1.5);
    text(axA, Lc * 1.15, yc * 0.45, sprintf('L^* = %.2f km', Lc), ...
         'HorizontalAlignment', 'left');
end
set(axA, 'XScale', 'log', 'YScale', 'log');
xlim(axA, [min(Lgrid) max(Lgrid)]);
xlabel(axA, 'Route length  L  (km)');
ylabel(axA, 'Variance  (mm^2)');
title(axA, 'Random versus route-coherent component');
legend(axA, {'a(L) random', 'b(L) coherent', 'a(L)+b(L)'}, ...
       'Location', 'northwest', 'Box', 'on');

axB = subplot(1, 2, 2); hold(axB, 'on'); box(axB, 'on'); grid(axB, 'on');
shareML = b1 ./ (a1 + b1);
shB = zeros(numel(Lgrid), numel(bsd));
for j = 1:numel(bsd)
    aj = bsd(j)^2 * Lgrid;
    bj = bt(j)^2  * Lgrid.^2;
    shB(:, j) = bj ./ (aj + bj);
end
shLo = zeros(size(Lgrid)); shHi = zeros(size(Lgrid));
for i = 1:numel(Lgrid)
    q = ST.prctile(shB(i, :), [2.5 97.5]);
    shLo(i) = q(1); shHi(i) = q(2);
end
fill(axB, [Lgrid; flipud(Lgrid)], [shLo; flipud(shHi)], col.band, ...
     'EdgeColor', 'none', 'FaceAlpha', 0.20);
plot(axB, Lgrid, shareML, '-', 'Color', col.M1, 'LineWidth', LW + 1);
plot(axB, Lgrid, bP ./ (aP + bP), '-.', 'Color', col.paper, 'LineWidth', LW);
plot(axB, [min(Lgrid) max(Lgrid)], [0.5 0.5], 'k--', 'LineWidth', LW);
set(axB, 'XScale', 'log');
xlim(axB, [min(Lgrid) max(Lgrid)]); ylim(axB, [0 1]);
xlabel(axB, 'Route length  L  (km)');
ylabel(axB, 'coherent share  b / (a+b)');
title(axB, 'Where the coherent mode dominates');
legend(axB, {'95% bootstrap band', 'ML estimate', 'manuscript', 'half'}, ...
       'Location', 'southeast', 'Box', 'on');
apply_font_size(f4, FS);
savefig(f4, fullfile(CFG.outDir, 'fig4_variance_decomposition.fig'));
print(f4, fullfile(CFG.outDir, 'fig4_variance_decomposition'), CFG.figFmt, CFG.figDPI);

% ------------------------------------------------------------- FIGURE 6
% Model-free power-law exponent.  gamma = 1 random, gamma = 2 fully coherent.
f6 = figure('Name', 'Power-law exponent', 'Color', 'w', ...
            'Position', [170 170 980 760]);
ax = axes('Parent', f6); hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');
styles = {'-', '--', ':'};
hh = gobjects(0); ll = {};
for k = 1:size(PL.dev, 2)
    hh(end+1) = plot(ax, PL.grid, PL.dev(:, k), styles{k}, ...
                     'Color', col.M1, 'LineWidth', LW + 0.5);  %#ok<SAGROW>
    ll{end+1} = sprintf('L \\geq %.2f km  (N = %d)', PL.minL(k), PL.N(k)); %#ok<SAGROW>
end
hh(end+1) = plot(ax, [min(PL.grid) max(PL.grid)], [3.8415 3.8415], 'k--', ...
                 'LineWidth', LW);
ll{end+1} = '\chi^2_1 95% level';
yl = [0 25];
hh(end+1) = plot(ax, [1 1], yl, '-',  'Color', col.M0, 'LineWidth', LW + 0.5);
ll{end+1} = '\gamma = 1  (pure random)';
hh(end+1) = plot(ax, [2 2], yl, '-',  'Color', [0.35 0.35 0.35], 'LineWidth', LW + 0.5);
ll{end+1} = '\gamma = 2  (fully coherent)';
ylim(ax, yl); xlim(ax, [min(PL.grid) max(PL.grid)]);
xlabel(ax, 'power-law exponent  \gamma   in   v \propto L^{\gamma}');
ylabel(ax, '2\Delta(-log L)');
title(ax, sprintf('Model-free exponent: \\gamma = %.2f  [%.2f, %.2f]', ...
                  PL.gamma(1), PL.ci(1,1), PL.ci(1,2)));
legend(ax, hh, ll, 'Location', 'north', 'Box', 'on');
apply_font_size(f6, FS);
savefig(f6, fullfile(CFG.outDir, 'fig6_powerlaw_exponent.fig'));
print(f6, fullfile(CFG.outDir, 'fig6_powerlaw_exponent'), CFG.figFmt, CFG.figDPI);

fprintf('--- 4 corrected/new figure(s) written to %s ---\n\n', CFG.outDir);


%% ------------------- 7.  CLOSING NOTE ----------------------------------
fprintf('===============================================\n');
fprintf(' NOTE FOR THE MANUSCRIPT\n');
fprintf('===============================================\n');
fprintf([' With a(L) linear and b(L) quadratic in L, the ordering quantity\n' ...
         '   q_p = a_p / sqrt(b_p) = (sigma_d^2 + sigma_s^2 rho) / tau_r\n' ...
         ' is the SAME for every route regardless of length.  All routes are\n' ...
         ' therefore tied, and the phase structure of Theorem 1 degenerates.\n' ...
         ' In configurations C2 and C3 the heterogeneity of q_p comes ENTIRELY\n' ...
         ' from the assumed susceptibility factors chi_p, which these data\n' ...
         ' cannot identify.  The GSVS17 analysis validates the SCALES of a_p\n' ...
         ' and b_p; it does not validate the route-to-route heterogeneity on\n' ...
         ' which the method depends.  State this explicitly.\n']);
fprintf('===============================================\n\n');


end % end of the callable workflow

%% ------------------------- local functions -----------------------------

function [gHat, gCI, dev] = fit_powerlaw(d, L, grid)
%FIT_POWERLAW  ML fit of  d ~ N(0, 2*c*L^gamma)  with profile CI on gamma.
d = d(:); L = L(:);
nllFun = @(t) 0.5 * sum(log(2 * exp(t(1)) * L.^t(2)) + ...
                        d.^2 ./ (2 * exp(t(1)) * L.^t(2)));
o  = optimset('MaxIter', 4e4, 'MaxFunEvals', 4e4, 'TolX', 1e-11, ...
              'TolFun', 1e-11, 'Display', 'off');
x  = fminsearch(nllFun, [log(mean(d.^2) / 2), 1.0], o);
x  = fminsearch(nllFun, x, o);
f0 = nllFun(x);
gHat = x(2);

dev = nan(numel(grid), 1);
c0  = x(1);
for i = 1:numel(grid)
    g = grid(i);
    pf = @(t) 0.5 * sum(log(2 * exp(t) * L.^g) + d.^2 ./ (2 * exp(t) * L.^g));
    ci = fminsearch(pf, c0, o);
    dev(i) = 2 * (pf(ci) - f0);
end
inCI = dev <= 3.841458820694124;
if any(inCI)
    gCI = [min(grid(inCI)), max(grid(inCI))];
else
    gCI = [NaN NaN];
end
end

function r = corrLocal(x, y)
x = x(:) - mean(x); y = y(:) - mean(y);
r = (x' * y) / sqrt((x' * x) * (y' * y));
end
