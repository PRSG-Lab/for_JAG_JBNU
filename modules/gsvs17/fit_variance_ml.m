function F = fit_variance_ml(d, L, n, useTau, fixed, opt)
%FIT_VARIANCE_ML  Maximum-likelihood fit of the route-total variance model.
%
%   F = FIT_VARIANCE_ML(D, L, N, USETAU) fits, by maximum likelihood,
%
%       d_i ~ N( 0 , v_i ),      v_i = 2 * ( sd2*L_i + ss2*n_i + tau2*L_i^2 )
%
%   where the factor 2 accounts for d being the difference of two independent
%   runs.  The single-run route-total variance implied by the fit is
%
%       a_i = sd2*L_i + ss2*n_i          (baseline, accumulates linearly)
%       b_i = tau2*L_i^2                 (route-coherent, accumulates as L^2)
%
%   matching the manuscript's a_p = sigma_d^2 L_p + sigma_s^2 n_p and
%   b_p = (tau_r L_p chi_p)^2 with chi_p = 1.
%
%   USETAU = false fits the pure random-accumulation model (tau2 = 0, "M0").
%   USETAU = true  fits the model with the coherent L^2 term      ("M1").
%
%   F = FIT_VARIANCE_ML(D, L, N, USETAU, FIXED) holds parameters fixed for
%   profile-likelihood work.  FIXED is a struct with any of the optional
%   fields .sd2, .ss2, .tau2 (variance units, not standard deviations).
%
%   F = FIT_VARIANCE_ML(D, L, N, USETAU, FIXED, OPT) controls the optimiser:
%       OPT.nStarts   number of multi-start initialisations (default 5)
%       OPT.theta0    warm start in log-variance space for the FREE parameters
%       OPT.polish    run a second FMINSEARCH from each optimum (default true)
%   A warm start with OPT.nStarts = 1 makes profile and bootstrap loops much
%   faster and is safe once the full-sample optimum is known.
%
%   Estimation uses FMINSEARCH on the log of each free variance component,
%   which enforces non-negativity without an optimisation toolbox.
%
%   Output struct F
%     sd2, ss2, tau2   fitted variance components
%     sigma_d          sqrt(sd2)   [mm / sqrt(km)]
%     sigma_s          sqrt(ss2)   [mm / set-up]
%     tau_r            sqrt(tau2)  [mm / km]
%     theta            log-parameter vector at the optimum (free parameters)
%     nll              negative log-likelihood at the optimum (up to a constant)
%     v                fitted variance of d_i         (mm^2)
%     vRun             fitted single-run variance v/2 (mm^2) = a_i + b_i
%     z                normalised residuals d_i ./ sqrt(v_i)
%     nObs, nPar       sample size and number of free parameters
%     aic, bic         information criteria (same additive constant as nll)
%     converged        logical
%
%   Part of the GSVS17 minimum-viable validation package.

if nargin < 4 || isempty(useTau), useTau = true;      end
if nargin < 5,                    fixed  = struct();  end
if nargin < 6,                    opt    = struct();  end
if isempty(fixed), fixed = struct(); end
if ~isfield(opt, 'nStarts') || isempty(opt.nStarts), opt.nStarts = 5;    end
if ~isfield(opt, 'theta0'),                          opt.theta0  = [];   end
if ~isfield(opt, 'polish')  || isempty(opt.polish),  opt.polish  = true; end

d = d(:); L = L(:); n = n(:);
N = numel(d);
assert(N > 3, 'fit_variance_ml:tooFew', 'Need more than 3 observations.');

% ---- decide which parameters are free ------------------------------------
hasFix = @(f) isfield(fixed, f) && ~isempty(fixed.(f)) && isfinite(fixed.(f));

freeSd  = ~hasFix('sd2');
freeSs  = ~hasFix('ss2');
freeTau = useTau && ~hasFix('tau2');

fixSd  = 0; if hasFix('sd2'),  fixSd  = fixed.sd2;  end
fixSs  = 0; if hasFix('ss2'),  fixSs  = fixed.ss2;  end
fixTau = 0; if hasFix('tau2'), fixTau = fixed.tau2; end
if ~useTau, fixTau = 0; end

% Floor keeps log-parameterised components strictly positive and stops
% FMINSEARCH from wandering to -Inf when a component sits on the boundary.
FLOOR = 1e-12;
cols  = logical([freeSd freeSs freeTau]);
nFree = sum(cols);

if nFree == 0
    thetaHat = [];
    fval     = objective(thetaHat);
    flag     = 1;
else
    % ---- starting points -------------------------------------------------
    v0 = mean(d.^2) / 2;
    s0 = log(max(v0 / max(mean(L), eps), 1e-6));

    startBank = [ s0      s0-6      s0-1    ; ...
                  s0-1    s0-3      s0-2    ; ...
                  s0+1    s0-8      s0      ; ...
                  s0-2    s0-10     s0-3    ; ...
                  0       log(1e-4) log(0.1) ];
    startBank = startBank(1:min(opt.nStarts, size(startBank, 1)), :);

    starts = startBank(:, cols);
    if ~isempty(opt.theta0)
        t0 = opt.theta0(:)';
        if numel(t0) == nFree
            starts = [t0; starts];
        end
    end

    optsFmin = optimset('MaxIter', 2e4, 'MaxFunEvals', 2e4, ...
                        'TolX', 1e-11, 'TolFun', 1e-11, 'Display', 'off');

    fval = Inf; thetaHat = starts(1, :); flag = 0;
    for s = 1:size(starts, 1)
        [x, f, fl] = fminsearch(@objective, starts(s, :), optsFmin);
        if opt.polish
            [x, f, fl] = fminsearch(@objective, x, optsFmin);
        end
        if f < fval
            fval = f; thetaHat = x; flag = fl;
        end
    end
end

[sd2, ss2, tau2] = unpack(thetaHat);

% ---- assemble output ------------------------------------------------------
sd2  = max(sd2  - FLOOR, 0);
ss2  = max(ss2  - FLOOR, 0);
tau2 = max(tau2 - FLOOR, 0);

v = 2 * (sd2 * L + ss2 * n + tau2 * L.^2);

F           = struct();
F.sd2       = sd2;
F.ss2       = ss2;
F.tau2      = tau2;
F.sigma_d   = sqrt(sd2);
F.sigma_s   = sqrt(ss2);
F.tau_r     = sqrt(tau2);
F.theta     = thetaHat;
F.nll       = fval;
F.v         = v;
F.vRun      = v / 2;
F.z         = d ./ sqrt(v);
F.nObs      = N;
F.nPar      = nFree;
F.aic       = 2 * fval + 2 * nFree;
F.bic       = 2 * fval + nFree * log(N);
F.useTau    = useTau;
F.fixed     = fixed;
F.converged = flag > 0;


% ================= nested functions (share the parent workspace) ==========

    function nll = objective(theta)
        [sd2_, ss2_, tau2_] = unpack(theta);
        v_ = 2 * (sd2_ * L + ss2_ * n + tau2_ * L.^2);
        if any(v_ <= 0) || any(~isfinite(v_))
            nll = 1e12;
            return
        end
        nll = 0.5 * sum(log(v_) + (d.^2) ./ v_);
    end

    function [sd2_, ss2_, tau2_] = unpack(theta)
        k = 0;
        if freeSd,  k = k + 1; sd2_  = exp(theta(k)) + FLOOR; else, sd2_  = fixSd;  end
        if freeSs,  k = k + 1; ss2_  = exp(theta(k)) + FLOOR; else, ss2_  = fixSs;  end
        if freeTau, k = k + 1; tau2_ = exp(theta(k)) + FLOOR; else, tau2_ = fixTau; end
    end

end

