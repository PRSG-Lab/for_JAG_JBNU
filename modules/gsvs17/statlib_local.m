function fh = statlib_local()
%STATLIB_LOCAL  Toolbox-free statistical helpers used by the GSVS17 package.
%
%   H = STATLIB_LOCAL() returns a struct of function handles so that the
%   package runs on base MATLAB alone (no Statistics and Machine Learning
%   Toolbox required).
%
%     H.chi2sf(x, k)      upper tail  P(chi2_k > x)
%     H.chi2inv(p, k)     inverse cdf of chi2_k
%     H.norminv(p)        inverse cdf of the standard normal
%     H.prctile(x, p)     percentiles of a vector (linear interpolation)
%
%   Part of the GSVS17 minimum-viable validation package.

fh = struct( ...
    'chi2sf',  @chi2sf, ...
    'chi2inv', @chi2inv, ...
    'norminv', @norminvL, ...
    'prctile', @prctileL);
end


% ------------------------------------------------------------------------
function p = chi2sf(x, k)
% Upper-tail probability of the chi-square distribution (base MATLAB gammainc).
x = max(x, 0);
p = gammainc(x ./ 2, k ./ 2, 'upper');
end


% ------------------------------------------------------------------------
function x = chi2inv(p, k)
% Inverse chi-square cdf by robust bisection on the regularised gamma function.
p = p(:);
x = zeros(size(p));
for i = 1:numel(p)
    pi_ = p(i);
    if pi_ <= 0, x(i) = 0;   continue, end
    if pi_ >= 1, x(i) = Inf; continue, end
    lo = 0;
    hi = max(10 * k, 10);
    while gammainc(hi / 2, k / 2, 'lower') < pi_
        hi = hi * 2;
        if hi > 1e12, break, end
    end
    for it = 1:200                       %#ok<NASGU>
        mid = 0.5 * (lo + hi);
        if gammainc(mid / 2, k / 2, 'lower') < pi_
            lo = mid;
        else
            hi = mid;
        end
        if hi - lo < 1e-12 * max(1, hi), break, end
    end
    x(i) = 0.5 * (lo + hi);
end
end


% ------------------------------------------------------------------------
function z = norminvL(p)
% Inverse standard normal cdf via the base-MATLAB error function.
z = sqrt(2) * erfinv(2 * p - 1);
end


% ------------------------------------------------------------------------
function q = prctileL(x, p)
% Percentiles of a vector by linear interpolation of the empirical cdf.
x = sort(x(:));
x = x(isfinite(x));
n = numel(x);
if n == 0
    q = nan(size(p));
    return
end
pos = (p(:) / 100) * n + 0.5;
pos = min(max(pos, 1), n);
lo  = floor(pos);
hi  = ceil(pos);
w   = pos - lo;
q   = (1 - w) .* x(lo) + w .* x(hi);
q   = reshape(q, size(p));
end
